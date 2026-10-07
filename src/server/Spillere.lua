-- Spillerprofilene på serveren: penger, oppgraderinger, samlebok og hva klienten skal vise.
-- Serveren eier alle tall. Klienten får et «Status»-bilde når noe endrer seg.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Fugler = require(Shared:WaitForChild("Fugler"))
local Data = require(script.Parent.Data)

local Spillere = {}

local profiler = {} -- [Player] = profil
local Fjern
Spillere.inntektFor = nil -- funksjon(spiller) -> penger/s (settes av Ting)
Spillere.ekstraStatus = nil -- funksjon(spiller, status) (settes av Baser)

local OPPG = {}
for _, o in Config.OPPGRADERINGER do
	OPPG[o.id] = o
end
Spillere.OPPG = OPPG

function Spillere.profil(spiller)
	return profiler[spiller]
end

function Spillere.alle()
	return profiler
end

-- ---------------------------------------------------------------- penger

local function oppdaterLederstat(spiller, p)
	local ls = spiller:FindFirstChild("leaderstats")
	if ls then
		local c = ls:FindFirstChild("Cash")
		if c then
			c.Value = Fugler.penger(p.data.penger)
		end
		local s = ls:FindFirstChild("Steals")
		if s then
			s.Value = p.data.tyverier or 0
		end
		local r = ls:FindFirstChild("Rebirths")
		if r then
			r.Value = p.data.rebirths or 0
		end
	end
end

function Spillere.penger(spiller)
	local p = profiler[spiller]
	return p and p.data.penger or 0
end

function Spillere.giPenger(spiller, n)
	local p = profiler[spiller]
	if not p or n ~= n or n == math.huge then
		return
	end
	p.data.penger = math.max(0, math.floor(p.data.penger + n))
	oppdaterLederstat(spiller, p)
	Spillere.sendStatus(spiller)
end

-- Trekk penger hvis spilleren har nok. Returnerer true hvis det gikk.
function Spillere.betal(spiller, n)
	local p = profiler[spiller]
	if not p or n < 0 or p.data.penger < n then
		return false
	end
	p.data.penger -= n
	oppdaterLederstat(spiller, p)
	Spillere.sendStatus(spiller)
	return true
end

-- ---------------------------------------------------------------- game passes og rebirth

function Spillere.harPass(spiller, id)
	local p = profiler[spiller]
	return p ~= nil and p.pass[id] == true
end

function Spillere.settPass(spiller, id)
	local p = profiler[spiller]
	if p then
		p.pass[id] = true
		Spillere.oppdaterFigur(spiller)
		Spillere.sendStatus(spiller)
	end
end

function Spillere.rebirths(spiller)
	local p = profiler[spiller]
	return p and (p.data.rebirths or 0) or 0
end

function Spillere.rebirthPris(spiller)
	return Config.REBIRTH.PRIS * Config.REBIRTH.FAKTOR ^ Spillere.rebirths(spiller)
end

-- Inntektsfaktor: +50 % per rebirth, og x2 med VIP.
function Spillere.faktor(spiller)
	local f = 1 + Config.REBIRTH.BONUS * Spillere.rebirths(spiller)
	if Spillere.harPass(spiller, "VIP") then
		f *= 2
	end
	return f
end

-- Attributter på figuren som alle klientene bruker (taufarge, VIP-merke).
function Spillere.oppdaterFigur(spiller)
	local f = spiller.Character
	if not f then
		return
	end
	local farge = nil
	local n = Spillere.rebirths(spiller)
	if n > 0 then
		farge = Config.REBIRTH.TAU[math.min(n, #Config.REBIRTH.TAU)]
	end
	if Spillere.harPass(spiller, "RainbowRope") then
		farge = "Rainbow"
	end
	f:SetAttribute("TauFarge", farge)
	f:SetAttribute("VIP", Spillere.harPass(spiller, "VIP"))
	f:SetAttribute("Rebirths", n)
end

-- ---------------------------------------------------------------- veiledning for nye spillere
-- Mål 1–4: kjøp et egg, bær det hjem, hent pengene, stjel en fugl. 5 = ferdig.
Spillere.MAAL = { kjop = 1, hjem = 2, samle = 3, stjel = 4 }

function Spillere.maal(spiller, hva)
	local p = profiler[spiller]
	local n = Spillere.MAAL[hva]
	if p and n and (p.data.veiledning or 1) == n then
		p.data.veiledning = n + 1
		Spillere.sendStatus(spiller)
	end
end

function Spillere.tyveri(spiller)
	local p = profiler[spiller]
	if p then
		p.data.tyverier = (p.data.tyverier or 0) + 1
		oppdaterLederstat(spiller, p)
	end
end

-- ---------------------------------------------------------------- oppgraderinger

function Spillere.nivaa(spiller, id)
	local p = profiler[spiller]
	return p and (p.data.oppgr[id] or 0) or 0
end

-- Verdien oppgraderingen gir nå (f.eks. tau-lengden i studs).
function Spillere.verdi(spiller, id)
	local o = OPPG[id]
	return o.verdier[math.min(Spillere.nivaa(spiller, id), #o.priser) + 1]
end

function Spillere.oppgrader(spiller, id)
	local o = OPPG[id]
	local p = profiler[spiller]
	if not o or not p then
		return false, "Unknown upgrade"
	end
	local n = p.data.oppgr[id] or 0
	if n >= #o.priser then
		return false, "Already maxed out!"
	end
	if not Spillere.betal(spiller, o.priser[n + 1]) then
		return false, "Not enough cash!"
	end
	p.data.oppgr[id] = n + 1
	Spillere.sendStatus(spiller)
	return true
end

-- ---------------------------------------------------------------- samleboka

-- Merk en fugl som funnet. Returnerer true hvis den var ny.
function Spillere.funnet(spiller, art, mut)
	local p = profiler[spiller]
	if not p then
		return false
	end
	local side = p.data.index[art]
	if not side then
		side = {}
		p.data.index[art] = side
	end
	local n = mut or "Normal"
	if side[n] then
		return false
	end
	side[n] = true
	Spillere.sendStatus(spiller)
	return true
end

-- ---------------------------------------------------------------- status til klienten

function Spillere.status(spiller)
	local p = profiler[spiller]
	if not p then
		return nil
	end
	local st = {
		penger = p.data.penger,
		inntekt = Spillere.inntektFor and Spillere.inntektFor(spiller) or 0,
		oppgr = Data.kopi(p.data.oppgr),
		index = Data.kopi(p.data.index),
		tyverier = p.data.tyverier or 0,
		rebirths = p.data.rebirths or 0,
		rebirthPris = Spillere.rebirthPris(spiller),
		veiledning = p.data.veiledning or 1,
		faktor = Spillere.faktor(spiller),
		pass = Data.kopi(p.pass),
		lagres = p.lagres,
		advarsel = Data.advarsel,
	}
	if Spillere.ekstraStatus then
		Spillere.ekstraStatus(spiller, st)
	end
	return st
end

function Spillere.sendStatus(spiller)
	local p = profiler[spiller]
	if not p or p.statusPlanlagt then
		return
	end
	p.statusPlanlagt = true
	task.delay(0.1, function()
		p.statusPlanlagt = false
		if profiler[spiller] == p and spiller.Parent then
			local st = Spillere.status(spiller)
			if st then
				Fjern.Status:FireClient(spiller, st)
			end
		end
	end)
end

-- ---------------------------------------------------------------- inn og ut

-- Laster dataene (venter). Returnerer profilen, eller nil hvis spilleren gikk mens vi lastet.
function Spillere.inn(spiller)
	local data, lagres = Data.last(spiller.UserId)
	if not spiller.Parent then
		if lagres then
			Data.lagre(spiller.UserId, data, true) -- slipp låsen igjen
		end
		return nil
	end
	local p = { data = data, lagres = lagres, kom = workspace:GetServerTimeNow(), sistLagret = os.clock(), pass = {} }
	profiler[spiller] = p
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	local c = Instance.new("StringValue")
	c.Name = "Cash"
	c.Parent = ls
	local s = Instance.new("IntValue")
	s.Name = "Steals"
	s.Parent = ls
	local r = Instance.new("IntValue")
	r.Name = "Rebirths"
	r.Parent = ls
	ls.Parent = spiller
	oppdaterLederstat(spiller, p)
	return p
end

-- Lagre nå. fugler = listen fra Ting.fuglerFor (hentes selv hvis den mangler).
function Spillere.lagre(spiller, slipp, fugler)
	local p = profiler[spiller]
	if not p or not p.lagres then
		return false
	end
	if fugler then
		p.data.fugler = fugler
	elseif Spillere.fuglerFor then
		p.data.fugler = Spillere.fuglerFor(spiller)
	end
	p.sistLagret = os.clock()
	return Data.lagre(spiller.UserId, p.data, slipp)
end

-- Spilleren går: lagre (med fuglelisten som ble laget før modellene ble fjernet) og glem profilen.
function Spillere.ut(spiller, fugler)
	local p = profiler[spiller]
	if not p then
		return
	end
	Spillere.lagre(spiller, true, fugler)
	profiler[spiller] = nil
end

function Spillere.init(remotes)
	Fjern = remotes
	-- lagre jevnlig
	task.spawn(function()
		while true do
			task.wait(5)
			for spiller, p in profiler do
				if os.clock() - p.sistLagret >= Config.LAGRE_HVERT then
					task.spawn(Spillere.lagre, spiller, false)
				end
			end
		end
	end)
	game:BindToClose(function()
		for spiller in profiler do
			task.spawn(Spillere.ut, spiller)
		end
		task.wait(3)
	end)
end

return Spillere
