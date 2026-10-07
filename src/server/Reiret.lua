-- Eggebåndet rundt Reiret: nye egg ruller ut hvert par sekund, går én runde og forsvinner.
-- Klientene flytter eggene selv (ut fra starttiden), så serveren slipper å sende posisjoner hele tiden;
-- serveren regner ut hvor egget er når noen vil kjøpe det.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Fugler = require(Shared:WaitForChild("Fugler"))
local Kart = require(Shared:WaitForChild("Kart"))
local ModelInfo = require(Shared:WaitForChild("ModelInfo"))

local Reiret = {}

local Fjern, Spillere, Ting, Fuglemodell
local egg = {}       -- [id] = { id, sj, art, start, modell }
local nesteId = 0
local mappe
local rng = Random.new()
Reiret.grunnFlaks = 1 -- 2 når noen har kjøpt Server Luck
Reiret.flaks = 1      -- grunnFlaks, eller mer under Cosmic Night
Reiret.kosmisk = nil  -- sjanse for Secret-egg (bare under Cosmic Night)

local function naa()
	return workspace:GetServerTimeNow()
end

-- Bare arter som er laget i Blender (finnes i ModelInfo) kan dukke opp.
local function tillat(a)
	return ModelInfo[a.modell] ~= nil
end
Reiret.tillat = tillat

local function andel(e)
	return (naa() - e.start) / Config.BELTE.RUNDETID
end

function Reiret.pos(e)
	return Kart.beltePos(math.clamp(andel(e), 0, 1))
end

function Reiret.egg()
	return egg
end

-- Legg et nytt egg på båndet. sj/art kan bestemmes (hendelser), ellers trekkes de.
function Reiret.nyttEgg(sj, art)
	if not sj and Reiret.kosmisk and rng:NextNumber() < Reiret.kosmisk and #Fugler.tilgjengelige("Secret", tillat) > 0 then
		sj = "Secret"
	end
	sj = sj or Fugler.trekkSjeldenhet(rng, Reiret.flaks, tillat)
	art = art or Fugler.trekkArt(rng, sj, tillat)
	if not art then
		return nil
	end
	nesteId += 1
	local e = { id = nesteId, sj = sj, art = art, start = naa() }
	local m = Fuglemodell.egg(sj, Kart.beltePos(0))
	m.Name = "BelteEgg"
	m:SetAttribute("BelteId", e.id)
	m:SetAttribute("Sj", sj)
	m:SetAttribute("Pris", Fugler.SJ[sj].pris)
	m:SetAttribute("Start", e.start)
	m:SetAttribute("Rundetid", Config.BELTE.RUNDETID)
	CollectionService:AddTag(m, "BelteEgg")
	Fuglemodell.merke(m, {
		{ sj .. " Egg", Fugler.SJ[sj].farge, "Navn" },
		{ Fugler.penger(Fugler.SJ[sj].pris), Color3.fromRGB(120, 255, 140), "Pris" },
	}, 2.5, 70)
	m.Parent = mappe
	e.modell = m
	egg[e.id] = e
	if Fugler.SJ[sj].nr >= 5 then
		Fjern.Hendelse:FireAllClients("sjeldentEgg", sj)
	end
	return e
end

function Reiret.kjop(spiller, id)
	local e = egg[id]
	if not e then
		return
	end
	local a = andel(e)
	if a >= 1 then
		return
	end
	if Ting.baeres(spiller) then
		Fjern.Hendelse:FireClient(spiller, "feil", "You're already carrying something!")
		return
	end
	local rot = spiller.Character and spiller.Character:FindFirstChild("HumanoidRootPart")
	local pos = Kart.beltePos(a).Position
	if not rot or (rot.Position - pos).Magnitude > Config.BAER.TA_AVSTAND + 8 then
		return
	end
	if not Ting.ledigSokkel(spiller) then
		Fjern.Hendelse:FireClient(spiller, "feil", "Your base is full! Sell a bird or buy Base Slots.")
		return
	end
	if not Spillere.betal(spiller, Fugler.SJ[e.sj].pris) then
		Fjern.Hendelse:FireClient(spiller, "feil", "Not enough cash!")
		return
	end
	egg[id] = nil
	e.modell:Destroy()
	Ting.kjopt(spiller, e.sj, e.art)
	local p = Spillere.profil(spiller)
	if p then
		p.data.kjopt = (p.data.kjopt or 0) + 1
	end
	Spillere.maal(spiller, "kjop")
	Fjern.Hendelse:FireAllClients("kjopt", spiller, e.sj, pos)
end

function Reiret.init(remotes, spillere, ting, fuglemodell)
	Fjern, Spillere, Ting, Fuglemodell = remotes, spillere, ting, fuglemodell
	mappe = Instance.new("Folder")
	mappe.Name = "Eggebaand"
	mappe.Parent = workspace
	-- fyll båndet litt med en gang, så det ikke er tomt når serveren starter
	local antall = math.floor(Config.BELTE.RUNDETID / Config.BELTE.INTERVALL * 0.5)
	for n = 1, antall do
		local e = Reiret.nyttEgg()
		if e then
			e.start -= n * Config.BELTE.INTERVALL
			e.modell:SetAttribute("Start", e.start)
			e.modell:PivotTo(Reiret.pos(e))
		end
	end
	task.spawn(function()
		while true do
			task.wait(Config.BELTE.INTERVALL)
			local teller = 0
			for id, e in egg do
				if andel(e) >= 1 then
					egg[id] = nil
					if e.modell then
						e.modell:Destroy()
					end
				else
					teller += 1
				end
			end
			if teller < Config.BELTE.MAKS_EGG then
				Reiret.nyttEgg()
			end
		end
	end)
end

return Reiret
