-- Hendelsene, rebirth og Robux i etterligningen: Golden Egg Rain (gullegg faller, snappes, bæres hjem og
-- klekker med minst Gold), Cosmic Night (natt og Secret-egg på båndet), rebirth (fuglene og pengene borte,
-- inntekten opp) og at et Robux-kjøp bare gis én gang selv om Roblox sender det to ganger.
-- Kjør: python3 tools/test_luau.py test/hendelser.test.lua --mock
local Kart = krev("shared/Kart")
local Fugler = krev("shared/Fugler")
local Config = krev("shared/Config")

Mock.terrengHoyde = function(x, z, y)
	return Kart.toppHoyde(x, z, y) or -1000
end
-- et testprodukt (Server Luck) med ID, og Halloween-sesongen, før serveren starter
Config.ROBUX.PRODUKT[1].produktId = 4242
Config.SESONG = "Halloween"

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

-- ---------------------------------------------------------------- Storm
local Kamp = krev("server/Kamp")
Ting.lastInn(A, { { a = "Thunderbird", s = 2 } })
steg(0.1)
Hendelser.slutt() -- planen kan ha startet en hendelse mens testen spolte fram tiden
local foerStorm = Ting.inntektFor(A)
sjekk(Hendelser.start("Storm"), "Storm startet")
steg(6, 1 / 10)
sjekk(typeof(workspace:GetAttribute("Vind")) == "Vector3", "vinden blåser: " .. tostring(workspace:GetAttribute("Vind")))
sjekk(Lighting.Brightness < 2, "det ble mørkt")
local unDer = Ting.inntektFor(A)
sjekk(unDer > foerStorm, string.format("Thunderbird tjener mer i stormen (%d -> %d)", foerStorm, unDer))
local lyn = 0
for _, h in Mock.hendelser do
	if h.remote == "Hendelse" and h.args[1] == "lynNedslag" then
		lyn += 1
	end
end
sjekk(lyn >= 1, lyn .. " lynnedslag")
-- et lyn rett ved en spiller slår ham over ende
Kamp.slag(A, Vector3.new(40, 30, 0), "lyn")
steg(0.1)
sjekk((A.Character:GetAttribute("Ragdoll") or 0) > workspace:GetServerTimeNow(), "lynet slengte A som en filledukke")
Hendelser.slutt()
sjekk(workspace:GetAttribute("Vind") == nil and Lighting.ClockTime == klokke, "stormen er over, dagen er tilbake")
sjekk(Ting.inntektFor(A) == foerStorm, "Thunderbird tjener vanlig igjen")
steg(2)

-- ---------------------------------------------------------------- Meteor Egg
local B = Mock.leggTilSpiller("Sander", 1002)
steg(0.5)
Hendelser.slutt()
sjekk(Hendelser.start("Meteor"), "Meteor startet")
steg(0.2)
local maal = workspace:GetAttribute("MeteorMaal")
sjekk(typeof(maal) == "Vector3", "meteoren har et mål: " .. tostring(maal))
flytt(B, maal + Vector3.new(2, 3, 0))
steg(Config.HENDELSER.METEOR_VARSEL + 0.5, 1 / 10)
local meteor
for _, t in Ting.alle() do
	if t.sj == "Meteor" then
		meteor = t
	end
end
sjekk(meteor ~= nil and meteor.tilstand == "sluppet", "meteoregget ligger ved nedslaget")
sjekk(meteor and Fugler.SJ[Fugler.ART[meteor.art].sj].nr >= 4, "meteoregget har en Epic eller bedre: " .. tostring(meteor and meteor.art))
sjekk((B.Character:GetAttribute("Ragdoll") or 0) > workspace:GetServerTimeNow(), "B stod for nær og ble slengt vekk")
steg(2)
flytt(B, meteor.modell.PrimaryPart.Position + Vector3.new(2, 3, 0))
Handling.OnServerEvent:Fire(B, "ta", meteor.id)
steg(0.1)
sjekk(Ting.baeres(B) == meteor, "B tok meteoregget")
local lagringB = Ting.fuglerFor(B)
local harMeteor = false
for _, f in lagringB do
	if f.ek == "Meteor" then
		harMeteor = true
	end
end
sjekk(harMeteor, "meteoregget lagres som Meteor-egg")
steg(Config.HENDELSER.METEOR_VARSEL + 3, 1 / 5)

-- ---------------------------------------------------------------- Halloween
sjekk(workspace:GetAttribute("Sesong") == "Halloween", "Halloween-sesongen er på")
local harSesongfugler = Fugler.trekkSesong(Random.new(2), "Halloween", Reiret.tillat) ~= nil
if harSesongfugler then
	Reiret.spooky = 1
	local e2 = Reiret.nyttEgg()
	Reiret.spooky = Config.SPOOKY_SJANSE
	sjekk(e2 and e2.sj == "Spooky" and Fugler.ART[e2.art].sesong == "Halloween", "Spooky Egg på båndet: " .. tostring(e2 and e2.art))
else
	print("  (Halloween-fuglene er ikke laget ennå — hopper over Spooky Egg)")
end
local Sesong = krev("server/Sesong")
sjekk(Sesong.aktiv({ month = 10, day = 31 }) == "Halloween", "31. oktober er Halloween")
Config.SESONG = "auto"
sjekk(Sesong.aktiv({ month = 12, day = 1 }) == nil, "1. desember er ikke Halloween")
sjekk(Sesong.aktiv({ month = 10, day = 1 }) == "Halloween", "1. oktober er Halloween (auto)")

print(string.format("Simulerte %.0f s.", Mock.tid()))
print((#Mock.feil == 0 and feil == 0) and "INGEN FEIL" or ("FEIL: " .. (#Mock.feil + feil)))
