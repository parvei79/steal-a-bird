-- Hendelsene, rebirth og Robux i etterligningen: Golden Egg Rain (gullegg faller, snappes, bæres hjem og
-- klekker med minst Gold), Cosmic Night (natt og Secret-egg på båndet), rebirth (fuglene og pengene borte,
-- inntekten opp) og at et Robux-kjøp bare gis én gang selv om Roblox sender det to ganger.
-- Kjør: python3 tools/test_luau.py test/hendelser.test.lua --mock
local Kart = krev("shared/Kart")
local Fugler = krev("shared/Fugler")
local Config = krev("shared/Config")

Mock.terrengHoyde = function(x, z)
	return Kart.toppHoyde(x, z) or -1000
end
-- et testprodukt (Server Luck) med ID, før serveren starter
Config.ROBUX.PRODUKT[1].produktId = 4242

local feil = 0
local function sjekk(ok, tekst)
	if ok then
		print("  ok   " .. tekst)
	else
		feil += 1
		print("  FEIL " .. tekst)
	end
end

local function steg(sek, dt)
	dt = dt or 1 / 30
	for _ = 1, math.max(1, math.floor(sek / dt + 0.5)) do
		Mock.steg(dt)
	end
end

local lastet = false
task.spawn(function()
	krev("server/Main")
	lastet = true
end)
while not lastet and #Mock.feil == 0 and Mock.tid() < 60 do
	Mock.steg(1 / 30)
end
assert(lastet, "Main ble ikke ferdig")

local Ting = krev("server/Ting")
local Baser = krev("server/Baser")
local Spillere = krev("server/Spillere")
local Reiret = krev("server/Reiret")
local Hendelser = krev("server/Hendelser")
local Handling = game.ReplicatedStorage.Remotes.Handling
local Lighting = game:GetService("Lighting")

local A = Mock.leggTilSpiller("Pål", 1001)
steg(0.5)
local iA = Baser.til(A)
local function flytt(spiller, pos)
	spiller.Character:PivotTo(CFrame.new(pos))
end

-- ---------------------------------------------------------------- Golden Egg Rain
sjekk(workspace:GetAttribute("NesteHendelse") == "GoldenRain", "neste hendelse vises: " .. tostring(workspace:GetAttribute("NesteHendelse")))
sjekk(Hendelser.start("GoldenRain"), "Golden Egg Rain startet")
sjekk(workspace:GetAttribute("Hendelse") == "GoldenRain", "hendelsen står på workspace")
steg(Config.HENDELSER.GULLREGN_INTERVALL * 2 + 0.5, 1 / 10)
local gull = {}
for _, t in Ting.alle() do
	if t.sj == "Golden" and t.tilstand == "sluppet" then
		table.insert(gull, t)
	end
end
sjekk(#gull >= 2, #gull .. " gullegg har falt ned")
local g = gull[1]
local pos = g.modell.PrimaryPart.Position
sjekk(Kart.toppHoyde(pos.X, pos.Z) ~= nil, "gullegget landet på en øy")
steg(2)
flytt(A, pos + Vector3.new(2, 3, 0))
Handling.OnServerEvent:Fire(A, "ta", g.id)
steg(0.1)
sjekk(Ting.baeres(A) == g and g.eier == A, "A snappet gullegget")
flytt(A, Kart.lokal(iA, 0, 0, 3))
steg(0.3)
sjekk(g.tilstand == "plass" and g.gull, "gullegget står i basen til A")
steg(Fugler.SJ.Golden.klekk + 3, 1 / 10)
sjekk(not g.egg and g.mut ~= nil, "gullegget klekket til en " .. Fugler.fulltNavn(g.art, g.mut) .. " (minst Gold)")
sjekk(g.sj == Fugler.ART[g.art].sj, "fuglen har artens sjeldenhet (" .. g.sj .. ")")
-- gullegg som ingen tar, forsvinner
local foer = #gull
steg(Config.HENDELSER.GULLREGN_VARER + Config.HENDELSER.GULLEGG_LIGGER + 5, 1 / 5)
local igjen = 0
for _, t in Ting.alle() do
	if t.sj == "Golden" and t.tilstand == "sluppet" then
		igjen += 1
	end
end
sjekk(igjen == 0 and foer > 0, "gullegg ingen tok, forsvant etterpå")
sjekk(workspace:GetAttribute("Hendelse") == nil, "regnet er over")

-- ---------------------------------------------------------------- Cosmic Night
local klokke = Lighting.ClockTime
sjekk(Hendelser.start("CosmicNight"), "Cosmic Night startet")
sjekk(Lighting.ClockTime == 0, "det ble natt")
Reiret.kosmisk = 1 -- testen tvinger fram et Secret-egg
local e = Reiret.nyttEgg()
sjekk(e and e.sj == "Secret" and e.art == "CosmicShoebill", "Secret-egg (Cosmic Shoebill) på båndet")
Hendelser.slutt()
sjekk(Lighting.ClockTime == klokke and Reiret.kosmisk == nil, "dagen kom tilbake")

-- ---------------------------------------------------------------- lagring av gullegg
local lagret = Ting.fuglerFor(A)
local harFugl = false
for _, f in lagret do
	if f.a == g.art and f.m == g.mut then
		harFugl = true
	end
end
sjekk(harFugl, "gull-fuglen lagres med mutasjonen")

-- ---------------------------------------------------------------- rebirth
Spillere.giPenger(A, Config.REBIRTH.PRIS)
local antallFoer = 0
for _, t in Ting.alle() do
	if t.eier == A then
		antallFoer += 1
	end
end
Handling.OnServerEvent:Fire(A, "rebirth")
steg(0.2)
local antallEtter = 0
for _, t in Ting.alle() do
	if t.eier == A then
		antallEtter += 1
	end
end
sjekk(antallFoer > 0 and antallEtter == 0, "rebirth: fuglene er borte")
sjekk(Spillere.penger(A) == Config.BASE.STARTPENGER, "rebirth: pengene er tilbake til start")
sjekk(Spillere.rebirths(A) == 1 and Spillere.faktor(A) == 1.5, "rebirth 1: inntekt x1.5")
sjekk(A.Character:GetAttribute("TauFarge") == "Gold", "gulltau etter første rebirth")
sjekk(Spillere.rebirthPris(A) == Config.REBIRTH.PRIS * Config.REBIRTH.FAKTOR, "neste rebirth koster mer")
-- inntekten gjelder med faktoren
Ting.lastInn(A, { { a = "Pigeon", s = 1 } })
steg(0.1)
sjekk(Ting.inntektFor(A) == math.floor(Fugler.inntekt("Pigeon") * 1.5), "Pigeon tjener x1.5: " .. Ting.inntektFor(A))
-- rebirth uten nok penger nektes
Handling.OnServerEvent:Fire(A, "rebirth")
steg(0.1)
sjekk(Spillere.rebirths(A) == 1, "rebirth uten nok penger nektes")

-- ---------------------------------------------------------------- Robux: Server Luck gis bare én gang
local Marked = game:GetService("MarketplaceService")
local behandle = Marked.ProcessReceipt
sjekk(type(behandle) == "function", "ProcessReceipt er koblet til")
local svar1 = behandle({ PlayerId = 1001, ProductId = 4242, PurchaseId = "kjop-1" })
sjekk(svar1 == Enum.ProductPurchaseDecision.PurchaseGranted, "Server Luck-kjøpet ble gitt")
sjekk(Reiret.grunnFlaks == 2 and (workspace:GetAttribute("LuckTil") or 0) > workspace:GetServerTimeNow(), "dobbel flaks for alle")
local luck1 = workspace:GetAttribute("LuckTil")
local svar2 = behandle({ PlayerId = 1001, ProductId = 4242, PurchaseId = "kjop-1" })
sjekk(svar2 == Enum.ProductPurchaseDecision.PurchaseGranted and workspace:GetAttribute("LuckTil") == luck1,
	"samme kjøp to ganger gir ikke flaks to ganger")
local svar3 = behandle({ PlayerId = 999, ProductId = 4242, PurchaseId = "kjop-2" })
sjekk(svar3 == Enum.ProductPurchaseDecision.NotProcessedYet, "kjøp fra en som ikke er her, venter")
steg(Config.ROBUX.LUCK_TID + 2, 1)
sjekk(Reiret.grunnFlaks == 1, "flaksen går over etter 15 minutter")

print(string.format("Simulerte %.0f s.", Mock.tid()))
print((#Mock.feil == 0 and feil == 0) and "INGEN FEIL" or ("FEIL: " .. (#Mock.feil + feil)))
