-- Hendelsene som får alle til å komme tilbake:
--   Golden Egg Rain  gullegg faller ned på øyene i 90 sekunder. Hvem som helst kan snappe dem og bære dem
--                    hjem (og rykke dem fra hverandre). Et gullegg klekker en fugl med ekstra flaks og
--                    minst Gold-mutasjon.
--   Cosmic Night     natt over øyene i 3 minutter. Sjeldne egg dukker oftere opp på båndet, og noen få er
--                    Secret-egg med Cosmic Shoebill.
-- Hvilken hendelse som går og hva som kommer, står som attributter på workspace (HUD viser nedtelling).
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Fugler = require(Shared:WaitForChild("Fugler"))
local Kart = require(Shared:WaitForChild("Kart"))

local Hendelser = {}

local Fjern, Ting, Reiret
local H = Config.HENDELSER
local rng = Random.new()
local aktiv = nil
Hendelser.NAVN = { GoldenRain = "Golden Egg Rain", CosmicNight = "Cosmic Night" }

local function naa()
	return workspace:GetServerTimeNow()
end

function Hendelser.aktiv()
	return aktiv
end

-- Et tilfeldig sted på en øy (ikke midt på eggebåndet), der et gullegg kan lande.
local function landingsplass()
	for _ = 1, 30 do
		local oyer = Kart.alleOyer()
		local oy = oyer[rng:NextInteger(1, #oyer)]
		local a = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(0, math.max(oy.r - 4, 1))
		local x, z = oy.x + math.cos(a) * r, oy.z + math.sin(a) * r
		local topp = Kart.toppHoyde(x, z)
		local paaBelte = oy == Kart.REIR and math.abs(r - Kart.BELTE.radius) < Kart.BELTE.bredde
		if topp and not paaBelte then
			return Vector3.new(x, topp, z)
		end
	end
	return Vector3.new(Kart.REIR.x + 15, Kart.REIR.topp, Kart.REIR.z + 15)
end

local function gullegg()
	local sj = Fugler.trekkSjeldenhet(rng, H.GULLEGG_FLAKS, Reiret.tillat)
	local art = Fugler.trekkArt(rng, sj, Reiret.tillat)
	if art then
		Ting.friEgg("Golden", art, landingsplass(), H.GULLEGG_LIGGER, 1.6)
	end
end

-- ---------------------------------------------------------------- natt-lys

local dagLys = nil
local function natt(paa)
	local atm = Lighting:FindFirstChildOfClass("Atmosphere")
	local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
	if paa then
		dagLys = {
			ClockTime = Lighting.ClockTime, Brightness = Lighting.Brightness, Ambient = Lighting.Ambient,
			OutdoorAmbient = Lighting.OutdoorAmbient,
			atm = atm and { Color = atm.Color, Decay = atm.Decay, Density = atm.Density },
			cc = cc and { TintColor = cc.TintColor, Saturation = cc.Saturation },
		}
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
	elseif dagLys then
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

-- ---------------------------------------------------------------- start og slutt

local function settNeste(navn, tid)
	workspace:SetAttribute("NesteHendelse", navn)
	workspace:SetAttribute("NesteHendelseTid", tid)
end

function Hendelser.start(navn)
	if aktiv then
		return false
	end
	aktiv = navn
	local varer = navn == "GoldenRain" and H.GULLREGN_VARER or H.KOSMISK_VARER
	local slutt = naa() + varer
	workspace:SetAttribute("Hendelse", navn)
	workspace:SetAttribute("HendelseSlutt", slutt)
	Fjern.Hendelse:FireAllClients("hendelse", navn, true, slutt)
	if navn == "GoldenRain" then
		task.spawn(function()
			while aktiv == "GoldenRain" and naa() < slutt do
				gullegg()
				task.wait(H.GULLREGN_INTERVALL)
			end
		end)
	elseif navn == "CosmicNight" then
		natt(true)
		Reiret.kosmisk = H.KOSMISK_SJANSE
		Reiret.flaks = math.max(Reiret.flaks, H.KOSMISK_FLAKS)
	end
	task.delay(varer, function()
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
		natt(false)
		Reiret.kosmisk = nil
		Reiret.flaks = Reiret.grunnFlaks or 1
	end
	workspace:SetAttribute("Hendelse", nil)
	workspace:SetAttribute("HendelseSlutt", nil)
	Fjern.Hendelse:FireAllClients("hendelse", navn, false)
end

function Hendelser.init(remotes, ting, reiret)
	Fjern, Ting, Reiret = remotes, ting, reiret
	-- planen: gullregn og kosmisk natt på hver sin klokke (venter på hverandre hvis de krasjer)
	local nesteGull = naa() + H.GULLREGN_FORST
	local nesteKosmisk = naa() + H.KOSMISK_FORST
	task.spawn(function()
		while true do
			local t = naa()
			local navn, tid
			if nesteGull <= nesteKosmisk then
				navn, tid = "GoldenRain", nesteGull
			else
				navn, tid = "CosmicNight", nesteKosmisk
			end
			settNeste(navn, tid)
			if t >= tid and not aktiv then
				Hendelser.start(navn)
				if navn == "GoldenRain" then
					nesteGull = t + H.GULLREGN_HVERT
				else
					nesteKosmisk = t + H.KOSMISK_HVERT
				end
			elseif t >= tid then
				-- en annen hendelse går: vent til den er ferdig
				if navn == "GoldenRain" then
					nesteGull = t + 30
				else
					nesteKosmisk = t + 30
				end
			end
			task.wait(1)
		end
	end)
end

return Hendelser
