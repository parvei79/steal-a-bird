-- STEAL A BIRD — serveren starter her.
-- Bygger verden og basene, starter eggebåndet, og kobler sammen spillere, fugler, stjeling og kamp.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Data = require(script.Parent.Data)
local Spillere = require(script.Parent.Spillere)
local Modeller = require(script.Parent.Modeller)
local Fuglemodell = require(script.Parent.Fuglemodell)
local Verden = require(script.Parent.Verden)
local Baser = require(script.Parent.Baser)
local Ting = require(script.Parent.Ting)
local Reiret = require(script.Parent.Reiret)
local Kamp = require(script.Parent.Kamp)
local Handel = require(script.Parent.Handel)
local Hendelser = require(script.Parent.Hendelser)
local Robux = require(script.Parent.Robux)
local Ledertavle = require(script.Parent.Ledertavle)
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))
local Fugler = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Fugler"))

-- remotes først, så klientene finner dem med en gang
local remotes = {}
local remoteMappe = Instance.new("Folder")
remoteMappe.Name = "Remotes"
for _, navn in { "Krok", "Rykk", "Spark", "Knuff", "Hendelse", "Handling", "Status", "Handel" } do
	local r = Instance.new("RemoteEvent")
	r.Name = navn
	r.Parent = remoteMappe
	remotes[navn] = r
end
remoteMappe.Parent = ReplicatedStorage

Data.init()
Modeller.init()
-- klientene får kopier av kroken, mynten, skallbitene og alle fuglene (til samleboka og effekter)
do
	local ModelInfo = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("ModelInfo"))
	local navn = { "Krok", "Mynt", "Skallbit" }
	for _, a in Fugler.ARTER do
		for _, del in { "", "_VingeH", "_VingeV", "_Ekstra" } do
			if ModelInfo[a.modell .. del] then
				table.insert(navn, a.modell .. del)
			end
		end
	end
	Modeller.delMedKlient(navn)
end
Fuglemodell.init(Modeller)
Spillere.init(remotes)
Verden.bygg(Modeller)
Baser.init(Modeller, remotes, Spillere, Verden)
Ting.init(Modeller, remotes, Spillere, Baser, Fuglemodell)
Reiret.init(remotes, Spillere, Ting, Fuglemodell)
Kamp.init(Modeller, remotes, Spillere, Baser, Ting)
Handel.init(remotes, Spillere, Baser, Ting)
Hendelser.init(remotes, Ting, Reiret)
Robux.init(remotes, Spillere, Baser, Reiret, Ting)
Ledertavle.init(Spillere, Ting, Verden)
Ting.faktor = Spillere.faktor
Kamp.vedFigur = Spillere.oppdaterFigur

-- ---------------------------------------------------------------- spillere inn og ut

local function spillerInn(spiller)
	local p = Spillere.inn(spiller)
	if not p then
		return
	end
	local i = Baser.tildel(spiller)
	if i then
		Ting.lastInn(spiller, p.data.fugler)
	else
		remotes.Hendelse:FireClient(spiller, "melding", "All bases are taken! Try another server.")
	end
	Kamp.spillerInn(spiller)
	task.spawn(Robux.sjekkPass, spiller)
	Spillere.sendStatus(spiller)
	if not p.lagres and Data.advarsel then
		remotes.Hendelse:FireClient(spiller, "feil", Data.advarsel)
	end
end

Players.PlayerAdded:Connect(spillerInn)
for _, s in Players:GetPlayers() do
	task.spawn(spillerInn, s)
end

Players.PlayerRemoving:Connect(function(spiller)
	Handel.avbryt(spiller, "left the game")
	Ting.spillerUt(spiller)
	local fugler = Ting.fuglerFor(spiller)
	Ting.fjernAlle(spiller)
	Baser.frigjor(spiller)
	Spillere.ut(spiller, fugler)
end)

-- ---------------------------------------------------------------- forespørsler fra klientene

local EMOTER = { ChickenDance = true, Wave = true, Flex = true, Victory = true }
local TRIKS = { salto = true, skru = true }
local grense = {} -- [spiller] = { start, antall }

remotes.Handling.OnServerEvent:Connect(function(spiller, type_, a, b)
	local g = grense[spiller]
	local t = os.clock()
	if not g or t - g.start > 1 then
		g = { start = t, antall = 0 }
		grense[spiller] = g
	end
	g.antall += 1
	if g.antall > 30 or type(type_) ~= "string" then
		return
	end
	if not Spillere.profil(spiller) then
		return
	end
	local figur = spiller.Character
	if type_ == "status" then
		Spillere.sendStatus(spiller)
	elseif type_ == "kjop" and type(a) == "number" then
		Reiret.kjop(spiller, a)
	elseif type_ == "ta" and type(a) == "number" then
		Ting.ta(spiller, a)
	elseif type_ == "selg" and type(a) == "number" then
		Ting.selg(spiller, a)
	elseif type_ == "laas" then
		local ok, feil = Baser.laas(spiller)
		if not ok and feil then
			remotes.Hendelse:FireClient(spiller, "feil", feil)
		end
	elseif type_ == "oppgrader" and type(a) == "string" then
		local ok, feil = Spillere.oppgrader(spiller, a)
		if ok then
			if a == "sokler" and Baser.til(spiller) then
				Baser.oppdaterSokler(Baser.til(spiller))
			end
			remotes.Hendelse:FireClient(spiller, "oppgradert", a, Spillere.nivaa(spiller, a))
		elseif feil then
			remotes.Hendelse:FireClient(spiller, "feil", feil)
		end
	elseif type_ == "emote" and figur then
		if type(a) == "string" and EMOTER[a] and not Ting.baeres(spiller) then
			figur:SetAttribute("Emote", a)
			figur:SetAttribute("EmoteTid", workspace:GetServerTimeNow())
		else
			figur:SetAttribute("Emote", nil)
		end
	elseif type_ == "rebirth" then
		local pris = Spillere.rebirthPris(spiller)
		local feil
		if Ting.baeres(spiller) then
			feil = "Put down what you're carrying first"
		elseif Handel.aktiv(spiller) then
			feil = "Finish your trade first"
		elseif Spillere.penger(spiller) < pris then
			feil = "You need " .. Fugler.penger(pris) .. " to rebirth"
		end
		if feil then
			remotes.Hendelse:FireClient(spiller, "feil", feil)
			return
		end
		local p = Spillere.profil(spiller)
		Ting.nullstill(spiller)
		Baser.tomPott(spiller)
		p.data.rebirths = (p.data.rebirths or 0) + 1
		p.data.penger = Config.BASE.STARTPENGER
		Spillere.giPenger(spiller, 0)
		Spillere.oppdaterFigur(spiller)
		Spillere.sendStatus(spiller)
		remotes.Hendelse:FireAllClients("rebirth", spiller, p.data.rebirths)
		task.spawn(Spillere.lagre, spiller, false)
	elseif type_ == "triks" and TRIKS[a] then
		for _, annen in Players:GetPlayers() do
			if annen ~= spiller then
				remotes.Hendelse:FireClient(annen, "triks", spiller, a)
			end
		end
	elseif type_ == "landing" and type(a) == "number" then
		for _, annen in Players:GetPlayers() do
			if annen ~= spiller then
				remotes.Hendelse:FireClient(annen, "landing", spiller, math.clamp(a :: number, 0, 1))
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(spiller)
	grense[spiller] = nil
end)

print("[STEAL A BIRD] Klar! Eggene ruller.")
