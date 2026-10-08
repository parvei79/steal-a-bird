-- Hendelsene som får alle til å komme tilbake (én om gangen, på hver sin klokke):
--   Golden Egg Rain  gullegg faller ned på øyene i 90 sekunder. Hvem som helst kan snappe dem og bære dem
--                    hjem (og rykke dem fra hverandre). Et gullegg klekker en fugl med ekstra flaks og minst Gold.
--   Cosmic Night     natt i 3 minutter. Sjeldne egg dukker oftere opp, og noen få er Secret-egg (Cosmic Shoebill).
--   Storm            mørkt og regn i 100 sekunder. Vinden dytter alle som er i lufta, lynet slår ned (en lysende
--                    ring varsler først) og slenger folk av gårde, og Thunderbirds tjener x3.
--   Meteor Egg       «METEOR INCOMING!» — etter 12 sekunder styrter et brennende egg ned på en øy (Epic, Legendary
--                    eller Mythic). Alle løper dit, og den som står for nær nedslaget, blir slengt vekk.
-- Hvilken hendelse som går og hva som kommer, står som attributter på workspace (HUD viser nedtelling).
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Fugler = require(Shared:WaitForChild("Fugler"))
local Kart = require(Shared:WaitForChild("Kart"))

local Hendelser = {}

local Fjern, Ting, Reiret, Kamp
local H = Config.HENDELSER
local rng = Random.new()
local aktiv = nil
local stormTil = 0
Hendelser.NAVN = { GoldenRain = "Golden Egg Rain", CosmicNight = "Cosmic Night", Storm = "Storm", Meteor = "Meteor Egg" }

-- Planen: { navn, første gang (s etter start), hvor ofte, hvor lenge }
local PLAN = {
	{ navn = "GoldenRain", forst = H.GULLREGN_FORST, hvert = H.GULLREGN_HVERT, varer = H.GULLREGN_VARER },
	{ navn = "Storm", forst = H.STORM_FORST, hvert = H.STORM_HVERT, varer = H.STORM_VARER },
	{ navn = "CosmicNight", forst = H.KOSMISK_FORST, hvert = H.KOSMISK_HVERT, varer = H.KOSMISK_VARER },
	{ navn = "Meteor", forst = H.METEOR_FORST, hvert = H.METEOR_HVERT, varer = H.METEOR_VARSEL + 2 },
}
local VARER = {}
for _, p in PLAN do
	VARER[p.navn] = p.varer
end

local function naa()
	return workspace:GetServerTimeNow()
end

function Hendelser.aktiv()
	return aktiv
end

-- Et tilfeldig sted på en øy (ikke midt på eggebåndet). nær = prøv nær dette punktet først.
local function landingsplass(naer)
	for forsok = 1, 40 do
		local x, z
		if naer and forsok <= 10 then
			local a, r = rng:NextNumber(0, math.pi * 2), rng:NextNumber(0, 10)
			x, z = naer.X + math.cos(a) * r, naer.Z + math.sin(a) * r
		else
			local oyer = Kart.alleOyer()
			local oy = oyer[rng:NextInteger(1, #oyer)]
			local a = rng:NextNumber(0, math.pi * 2)
			local r = rng:NextNumber(0, math.max(oy.r - 4, 1))
			x, z = oy.x + math.cos(a) * r, oy.z + math.sin(a) * r
		end
		local topp = Kart.toppHoyde(x, z)
		local dr = math.sqrt((x - Kart.REIR.x) ^ 2 + (z - Kart.REIR.z) ^ 2)
		local paaBelte = math.abs(dr - Kart.BELTE.radius) < Kart.BELTE.bredde
		if topp and not paaBelte then
			return Vector3.new(x, topp, z)
		end
	end
	return Vector3.new(Kart.REIR.x + 15, Kart.REIR.topp, Kart.REIR.z + 15)
end
Hendelser.landingsplass = landingsplass

-- Slå alle spillere nær `pos` vekk (ragdoll + mister det de bærer).
local function sjokk(pos, radius, kraft, grunn)
	for _, s in Players:GetPlayers() do
		local rot = s.Character and s.Character:FindFirstChild("HumanoidRootPart")
		if rot then
			local d = rot.Position - pos
			if d.Magnitude < radius then
				local ut = Vector3.new(d.X, 0, d.Z)
				ut = ut.Magnitude > 0.1 and ut.Unit or Vector3.new(1, 0, 0)
				Kamp.slag(s, ut * kraft + Vector3.new(0, kraft * 0.7, 0), grunn)
			end
		end
	end
end

-- ---------------------------------------------------------------- lys (natt og storm)

local dagLys = nil
local function lys(modus)
	local atm = Lighting:FindFirstChildOfClass("Atmosphere")
	local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
	if modus and not dagLys then
		dagLys = {
			ClockTime = Lighting.ClockTime, Brightness = Lighting.Brightness, Ambient = Lighting.Ambient,
			OutdoorAmbient = Lighting.OutdoorAmbient,
			atm = atm and { Color = atm.Color, Decay = atm.Decay, Density = atm.Density, Haze = atm.Haze },
			cc = cc and { TintColor = cc.TintColor, Saturation = cc.Saturation, Brightness = cc.Brightness },
		}
	end
	if modus == "natt" then
		Lighting.ClockTime = 0
		Lighting.Brightness = 2
		Lighting.Ambient = Color3.fromRGB(80, 60, 130)
		Lighting.OutdoorAmbient = Color3.fromRGB(110, 90, 170)
		if atm then
			atm.Color = Color3.fromRGB(120, 80, 200)
			atm.Decay = Color3.fromRGB(60, 30, 120)
			atm.Density = 0.32
		end
		if cc then
			cc.TintColor = Color3.fromRGB(215, 200, 255)
			cc.Saturation = 0.35
		end
	elseif modus == "storm" then
		Lighting.ClockTime = 16.5
		Lighting.Brightness = 1.2
		Lighting.Ambient = Color3.fromRGB(70, 75, 90)
		Lighting.OutdoorAmbient = Color3.fromRGB(100, 105, 120)
		if atm then
			atm.Color = Color3.fromRGB(110, 115, 130)
			atm.Decay = Color3.fromRGB(60, 65, 80)
			atm.Density = 0.45
			atm.Haze = 2.5
		end
		if cc then
			cc.TintColor = Color3.fromRGB(205, 215, 235)
			cc.Saturation = -0.25
			cc.Brightness = -0.04
		end
	elseif not modus and dagLys then
		Lighting.ClockTime = dagLys.ClockTime
		Lighting.Brightness = dagLys.Brightness
		Lighting.Ambient = dagLys.Ambient
		Lighting.OutdoorAmbient = dagLys.OutdoorAmbient
		if atm and dagLys.atm then
			for k, v in dagLys.atm do
				atm[k] = v
			end
		end
		if cc and dagLys.cc then
			for k, v in dagLys.cc do
				cc[k] = v
			end
		end
		dagLys = nil
	end
end

-- ---------------------------------------------------------------- de enkelte hendelsene

local function gullregn(slutt)
	while aktiv == "GoldenRain" and naa() < slutt do
		local sj = Fugler.trekkSjeldenhet(rng, H.GULLEGG_FLAKS, Reiret.tillat)
		local art = Fugler.trekkArt(rng, sj, Reiret.tillat)
		if art then
			Ting.friEgg("Golden", art, landingsplass(), H.GULLEGG_LIGGER, 1.6)
		end
		task.wait(H.GULLREGN_INTERVALL)
	end
end

local function storm(slutt)
	lys("storm")
	stormTil = slutt
	local vinkel = rng:NextNumber(0, math.pi * 2)
	task.spawn(function()
		-- vinden snur seg sakte
		while aktiv == "Storm" and naa() < slutt do
			vinkel += rng:NextNumber(-0.6, 0.6)
			workspace:SetAttribute("Vind", Vector3.new(math.cos(vinkel), 0, math.sin(vinkel)) * H.STORM_VIND)
			task.wait(5)
		end
		workspace:SetAttribute("Vind", nil)
	end)
	while aktiv == "Storm" and naa() < slutt - H.LYN_VARSEL do
		-- lynet: oftest nær en tilfeldig spiller, ellers et tilfeldig sted
		local spillere = Players:GetPlayers()
		local naer = nil
		if #spillere > 0 and rng:NextNumber() < 0.5 then
			local s = spillere[rng:NextInteger(1, #spillere)]
			local rot = s.Character and s.Character:FindFirstChild("HumanoidRootPart")
			naer = rot and rot.Position
		end
		local pos = landingsplass(naer)
		local treff = naa() + H.LYN_VARSEL
		Fjern.Hendelse:FireAllClients("lynVarsel", pos, treff)
		task.delay(H.LYN_VARSEL, function()
			Fjern.Hendelse:FireAllClients("lynNedslag", pos)
			sjokk(pos, H.LYN_RADIUS, 60, "lyn")
		end)
		task.wait(H.LYN_INTERVALL * rng:NextNumber(0.6, 1.4))
	end
end

local function meteor(slutt)
	local maal = landingsplass()
	local treff = naa() + H.METEOR_VARSEL
	workspace:SetAttribute("MeteorMaal", maal)
	workspace:SetAttribute("MeteorTid", treff)
	Fjern.Hendelse:FireAllClients("meteorVarsel", maal, treff)
	task.wait(H.METEOR_VARSEL)
	if aktiv ~= "Meteor" then
		return
	end
	Fjern.Hendelse:FireAllClients("meteorNedslag", maal)
	sjokk(maal, H.METEOR_RADIUS, 85, "meteor")
	local art = Fugler.trekkMeteor(rng, Reiret.tillat)
	if art then
		Ting.friEgg("Meteor", art, maal, H.METEOR_LIGGER, 0)
	end
	workspace:SetAttribute("MeteorMaal", nil)
	workspace:SetAttribute("MeteorTid", nil)
	task.wait(math.max(0, slutt - naa()))
end

-- ---------------------------------------------------------------- start og slutt

local function settNeste(navn, tid)
	workspace:SetAttribute("NesteHendelse", navn)
	workspace:SetAttribute("NesteHendelseTid", tid)
end

function Hendelser.start(navn)
	if aktiv or not VARER[navn] then
		return false
	end
	aktiv = navn
	local slutt = naa() + VARER[navn]
	workspace:SetAttribute("Hendelse", navn)
	workspace:SetAttribute("HendelseSlutt", slutt)
	Fjern.Hendelse:FireAllClients("hendelse", navn, true, slutt)
	if navn == "CosmicNight" then
		lys("natt")
		Reiret.kosmisk = H.KOSMISK_SJANSE
		Reiret.flaks = math.max(Reiret.flaks, H.KOSMISK_FLAKS)
	elseif navn == "GoldenRain" then
		task.spawn(gullregn, slutt)
	elseif navn == "Storm" then
		task.spawn(storm, slutt)
	elseif navn == "Meteor" then
		task.spawn(meteor, slutt)
	end
	task.delay(VARER[navn], function()
		if aktiv == navn then
			Hendelser.slutt()
		end
	end)
	return true
end

function Hendelser.slutt()
	local navn = aktiv
	if not navn then
		return
	end
	aktiv = nil
	if navn == "CosmicNight" then
		Reiret.kosmisk = nil
		Reiret.flaks = Reiret.grunnFlaks or 1
	end
	if navn == "CosmicNight" or navn == "Storm" then
		lys(nil)
	end
	stormTil = 0
	workspace:SetAttribute("Vind", nil)
	workspace:SetAttribute("Hendelse", nil)
	workspace:SetAttribute("HendelseSlutt", nil)
	Fjern.Hendelse:FireAllClients("hendelse", navn, false)
end

function Hendelser.init(remotes, ting, reiret, kamp)
	Fjern, Ting, Reiret, Kamp = remotes, ting, reiret, kamp
	-- Thunderbird (og andre lyn-fugler) tjener ekstra i stormen
	Ting.bonus = function(t)
		if naa() < stormTil then
			local a = Fugler.ART[t.art]
			if a and a.effekt == "lyn" then
				return H.THUNDERBIRD_BONUS
			end
		end
		return 1
	end
	local start = naa()
	local neste = {}
	for _, p in PLAN do
		neste[p.navn] = start + p.forst
	end
	task.spawn(function()
		while true do
			local t = naa()
			-- den som er nærmest for tur
			local navn, tid = nil, math.huge
			for _, p in PLAN do
				if neste[p.navn] < tid then
					navn, tid = p.navn, neste[p.navn]
				end
			end
			settNeste(navn, tid)
			if t >= tid then
				if not aktiv then
					Hendelser.start(navn)
					for _, p in PLAN do
						if p.navn == navn then
							neste[navn] = t + p.hvert
						end
					end
				else
					neste[navn] = t + 30 -- en annen hendelse går: vent litt
				end
			end
			task.wait(1)
		end
	end)
end

return Hendelser
