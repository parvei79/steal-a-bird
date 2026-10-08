-- Hele Steal a Bird i Roblox-etterligningen, med den ekte klientkoden: en robotspiller kjøper et egg
-- med E-knappen, bærer det hjem, klekker det, henter penger, kjøper en oppgradering i butikken, danser,
-- svinger seg med kroken (salto og landing), og rykker en tyv som stjeler fuglen. Alle animasjoner,
-- effekter og vinduer kjøres hvert bilde.
-- Kjør: python3 tools/test_luau.py test/klient.test.lua --mock
local Kart = krev("shared/Kart")
local Fugler = krev("shared/Fugler")
local Config = krev("shared/Config")

Mock.terrengHoyde = function(x, z, y)
	return Kart.toppHoyde(x, z, y) or -1000
end
krev("shared/Config").SESONG = nil -- testen skal ikke avhenge av hvilken måned det er

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
		if #Mock.feil > 0 then
			return
		end
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

MODULER["mock/PlayerModule"] = function()
	return { GetControls = function()
		return { GetMoveVector = function()
			return Mock.flytt or Vector3.zero
		end }
	end }
end

local spiller = Mock.leggTilSpiller("Pål", 1001)
Mock.blilokal(spiller, "mock/PlayerModule")
steg(0.3)
local klar = false
task.spawn(function()
	krev("client/Klient")
	klar = true
end)
steg(1)
assert(klar, "klienten ble ikke ferdig")
sjekk(#Mock.feil == 0, "klienten startet uten feil")

local Ting = krev("server/Ting")
local Reiret = krev("server/Reiret")
local Spillere = krev("server/Spillere")
local Baser = krev("server/Baser")
local Klientdata = krev("client/Klientdata")
local Menyer = krev("client/Menyer")
local Positurer = krev("client/Positurer")
local Grappler = krev("client/Grappler")
local Kamera = krev("client/Kamera")
local figur = spiller.Character
local rot = figur.HumanoidRootPart
local hum = figur:FindFirstChildOfClass("Humanoid")
local i = Baser.til(spiller)
sjekk(Klientdata.status.base == i and Klientdata.status.penger == Config.BASE.STARTPENGER, "klienten fikk status fra serveren")
local hudSkjerm = spiller.PlayerGui:FindFirstChild("FuglHUD")
sjekk(hudSkjerm ~= nil, "skjermbildet finnes")

-- ---------------------------------------------------------------- kjøp med E-knappen
local e
for _, x in Reiret.egg() do
	if not e or Fugler.SJ[x.sj].pris < Fugler.SJ[e.sj].pris then
		e = x
	end
end
Spillere.giPenger(spiller, Fugler.SJ[e.sj].pris)
steg(0.4)
local knapp = e.modell.Rot:FindFirstChildOfClass("ProximityPrompt")
sjekk(knapp ~= nil and string.find(knapp.ActionText, "Buy") ~= nil, "egget har en Buy-knapp: " .. tostring(knapp and knapp.ActionText))
figur:PivotTo(CFrame.new(Reiret.pos(e).Position + Vector3.new(0, 3, 4)))
knapp.Triggered:Fire(spiller)
steg(0.6)
local t = Ting.baeres(spiller)
sjekk(t ~= nil, "kjøpte egget med E")
local pst = Positurer.tilstand(figur)
sjekk(pst and pst.vekt.baer > 0.5, "bærepositur (armene opp)")
local ledd = figur.RightUpperArm.RightShoulder
local arm = (ledd.Transform * Vector3.new(0, -1, 0))
sjekk(arm.Y > 0.6, string.format("høyre arm peker opp mens du bærer (y=%.2f)", arm.Y))

-- hjem
figur:PivotTo(CFrame.new(Kart.lokal(i, 0, 0, 3)))
steg(0.4)
sjekk(Ting.baeres(spiller) == nil and t.tilstand == "plass", "levert hjemme")
steg(Fugler.SJ[t.sj].klekk + 3, 1 / 15)
sjekk(not t.egg, "egget klekket (" .. tostring(t.art) .. ")")
local bannerFunnet = false
for _, d in hudSkjerm:GetDescendants() do
	if d:IsA("TextLabel") and string.find(d.Text, "You hatched") then
		bannerFunnet = true
	end
end
sjekk(bannerFunnet, "banner: «You hatched a ...»")
-- fuglen lever: vingene flakser og kroppen vipper
local fugl = t.modell
local vingeFor = fugl.VingeH.VingeH.Transform
steg(6, 1 / 30)
local beveget = false
for _ = 1, 60 do
	Mock.steg(1 / 30)
	if fugl.Kropp.Kropp.Transform ~= vingeFor then
		beveget = true
	end
end
sjekk(beveget, "fuglen beveger seg (Fugleliv)")

-- penger
steg(4)
figur:PivotTo(Kart.pengeplate(i) * CFrame.new(0, 3, 0))
steg(0.5)
sjekk(Klientdata.status.penger > 0, "pengene hentet og vist: $" .. Klientdata.status.penger)
sjekk(Klientdata.status.veiledning == 4, "veiledningen er på mål 4 (stjel) etter kjøp, hjem og innhenting")

-- ---------------------------------------------------------------- butikk
Spillere.giPenger(spiller, 1000)
steg(0.3)
Menyer.aapne("Shop")
steg(0.1)
sjekk(Kamera.fri == true and Grappler.laast == true, "butikken gir fri musepeker og stopper kroken")
local kjopt = false
for _, d in hudSkjerm.Shop:GetDescendants() do
	if d:IsA("TextButton") and d.Text == "$200" then
		d.MouseButton1Click:Fire()
		kjopt = true
		break
	end
end
steg(0.4)
sjekk(kjopt and (Klientdata.status.oppgr.tau or 0) == 1, "kjøpte Rope Length i butikken")
Menyer.lukk()
steg(0.1)
sjekk(Grappler.tilstand().rekkevidde == 170, "kroken når lenger nå: " .. Grappler.tilstand().rekkevidde)
Menyer.aapne("Index")
steg(0.1)
local funnet = false
for _, d in hudSkjerm.Index:GetDescendants() do
	if d:IsA("TextLabel") and d.Text == Fugler.ART[t.art].navn then
		funnet = true
	end
end
sjekk(funnet, "samleboka viser " .. Fugler.ART[t.art].navn)
Menyer.lukk()

-- ---------------------------------------------------------------- dans
Menyer.dans("ChickenDance")
steg(0.6)
sjekk(figur:GetAttribute("Emote") == "ChickenDance" and pst.vekt.emote > 0.8, "Chicken Dance")
local nakke = figur.Head.Neck.Transform
steg(0.1)
sjekk(figur.Head.Neck.Transform ~= nakke, "hodet hakker i takt")
hum.MoveDirection = Vector3.new(1, 0, 0)
steg(0.5)
sjekk(figur:GetAttribute("Emote") == nil, "dansen stopper når du går")
hum.MoveDirection = Vector3.zero

-- ---------------------------------------------------------------- sving, salto og landing
Mock.fysiske = function()
	return { rot }
end
local function bakke()
	local p = rot.Position
	local h = Kart.toppHoyde(p.X, p.Z, p.Y) or -1000
	hum.FloorMaterial = (p.Y - 3 <= h + 0.3) and Enum.Material.Grass or Enum.Material.Air
end
figur:PivotTo(CFrame.new(Kart.lokal(i, 0, -20, 3)))
steg(0.3)
local mal = Kart.lokal(i, 0, -60, -3) -- under kanten av øya: svinger ut over kanten
local stein
for _, s in Kart.STEINER do
	local p = Vector3.new(s.x, s.topp, s.z)
	if not stein or (p - rot.Position).Magnitude < (stein - rot.Position).Magnitude then
		stein = p
	end
end
mal = stein - Vector3.new(0, 2, 0)
local sving, salto, landing = 0, false, false
local gammelHendelser = Grappler.hendelser
Grappler.hendelser = function(liste)
	for _, h in liste do
		if h[1] == "salto" or h[1] == "triks" then
			salto = true
		elseif h[1] == "landing" then
			landing = true
		end
	end
	gammelHendelser(liste)
end
for _ = 1, 3 do
	Kamera.settRetning((mal - workspace.CurrentCamera.CFrame.Position).Unit)
	bakke()
	Mock.steg(1 / 60)
end
Grappler.skyt()
local maksSving = 0
local treff, maalinger = 0, 0
for _ = 1, 240 do
	bakke()
	-- mål armen med posisjonene animasjonen ser (før fysikksteget)
	local s = Grappler.tilstand()
	local skulder = figur.UpperTorso.CFrame * figur.RightUpperArm.RightShoulder.C0.Position
	local anker = s.krok == "fest" and s.anker
	Mock.steg(1 / 60)
	maksSving = math.max(maksSving, pst.vekt.sving)
	if anker and pst.vekt.sving > 0.95 and (anker - skulder).Magnitude > 15 then
		local onsket = figur.UpperTorso.CFrame:VectorToObjectSpace((anker - skulder).Unit)
		local faktisk = figur.RightUpperArm.RightShoulder.Transform * Vector3.new(0, -1, 0)
		maalinger += 1
		if faktisk:Dot(onsket) > 0.9 then
			treff += 1
		end
	end
	if s.krok == "fest" and rot.AssemblyLinearVelocity.Magnitude > 50 then
		sving += 1
	end
	if s.krok == "fest" and s.anker and (s.anker - rot.Position).Magnitude < 12 then
		break
	end
end
sjekk(maksSving > 0.5, string.format("svingepositur i tauet (vekt %.2f)", maksSving))
sjekk(maalinger > 5 and treff == maalinger, string.format("krok-armen peker mot festet (%d av %d bilder)", treff, maalinger))
rot.AssemblyLinearVelocity = Vector3.new(0, 40, -90)
Grappler.slipp()
for _ = 1, 30 do
	bakke()
	Mock.steg(1 / 60)
end
Grappler.triks()
for _ = 1, 400 do
	bakke()
	Mock.steg(1 / 60)
	if hum.Health <= 0 then
		break
	end
	if landing then
		break
	end
end
sjekk(salto, "salto/skru i lufta")
Mock.fysiske = function()
	return {}
end
-- kast opp på kanten: heng mot siden av en base-øy, bli dratt inn og kastet opp på toppen
do
	local b = Kart.BASER[i]
	Mock.fysiske = function()
		return { rot }
	end
	figur:PivotTo(CFrame.new(Kart.lokal(i, 0, -(b.r + 22), -8)))
	rot.AssemblyLinearVelocity = Vector3.zero
	local side = Kart.lokal(i, 0, -(b.r - 1), -3)
	for _ = 1, 12 do
		bakke()
		Kamera.settRetning((side - workspace.CurrentCamera.CFrame.Position).Unit)
		Mock.steg(1 / 60)
	end
	local kastet = false
	local forrige = Grappler.hendelser
	Grappler.hendelser = function(liste)
		for _, h in liste do
			if h[1] == "salto" then
				kastet = true
			end
		end
		forrige(liste)
	end
	Grappler.skyt()
	local paaToppen = false
	for _ = 1, 300 do
		bakke()
		Mock.steg(1 / 60)
		local p = rot.Position
		if Kart.iBase(i, p) and p.Y > b.topp + 1 and p.Y < b.topp + 5 and rot.AssemblyLinearVelocity.Y <= 0
			and Vector3.new(p.X - b.x, 0, p.Z - b.z).Magnitude < b.r then
			paaToppen = true
			break
		end
	end
	Grappler.hendelser = forrige
	sjekk(kastet and paaToppen, "kastet opp på kanten av øya (" .. tostring(rot.Position) .. ")")
	-- land ordentlig før resten av testen
	for _ = 1, 120 do
		bakke()
		Mock.steg(1 / 60)
		if Grappler.tilstand().bevegelse == "bakke" then
			break
		end
	end
	rot.AssemblyLinearVelocity = Vector3.zero
	Mock.fysiske = function()
		return {}
	end
end
-- superhelt-landing direkte (styrke 1)
Positurer.landing(figur, 1)
for _ = 1, 10 do
	Mock.steg(1 / 60)
end
local root = figur.LowerTorso.Root.Transform
sjekk(root.Position.Y < -0.8, string.format("superhelt-landing: kroppen går ned (y=%.2f)", root.Position.Y))

-- ---------------------------------------------------------------- en tyv stjeler, og vi rykker ham
if hum.Health <= 0 then
	hum.Health = 100
end
figur:PivotTo(CFrame.new(Kart.lokal(i, 0, -10, 3)))
local tyv = Mock.leggTilSpiller("Tyv", 2002)
steg(0.5)
steg(Config.BASE.NYBEGYNNER + 1, 1 / 4)
tyv.Character:PivotTo(fugl.Rot.CFrame * CFrame.new(3, 2, 0))
game.ReplicatedStorage.Remotes.Handling.OnServerEvent:Fire(tyv, "ta", t.id)
steg(0.3)
sjekk(Ting.baeres(tyv) == t, "tyven tok fuglen")
local alarm = false
for _, d in hudSkjerm:GetDescendants() do
	if d:IsA("TextLabel") and string.find(d.Text, "STEALING YOUR") then
		alarm = true
	end
end
sjekk(alarm, "ALARM på skjermen")
sjekk(tyv.Character.Head:FindFirstChild("TyvMerke") ~= nil, "tyven har THIEF!-merke")
-- sikt på tyven og skyt kroken
tyv.Character:PivotTo(CFrame.new(rot.Position + Vector3.new(0, 1, -35)))
Mock.spesialdeler = { tyv.Character.HumanoidRootPart }
steg(0.1)
for _ = 1, 12 do
	Kamera.settRetning((tyv.Character.HumanoidRootPart.Position - workspace.CurrentCamera.CFrame.Position).Unit)
	Mock.steg(1 / 60)
end
Grappler.skyt()
steg(0.5, 1 / 60)
sjekk(t.eier == spiller and t.tilstand == "plass", "rykket tyven: fuglen fløy hjem")
local tyvSt = Positurer.tilstand(tyv.Character)
steg(0.2, 1 / 60)
sjekk(tyvSt and tyvSt.vekt.ragdoll > 0.5, "tyven er en filledukke")
steg(1.6, 1 / 30)
sjekk(tyvSt and tyvSt.stjerner ~= nil, "stjerner rundt hodet på tyven")

-- ---------------------------------------------------------------- gullregn og rebirth via knappene
local Hendelser = krev("server/Hendelser")
Hendelser.start("GoldenRain")
steg(Config.HENDELSER.GULLREGN_INTERVALL + 2.5, 1 / 30)
local hendelseVist = false
for _, d in hudSkjerm:GetDescendants() do
	if d:IsA("TextLabel") and string.find(d.Text, "GOLDEN EGG RAIN") then
		hendelseVist = true
	end
end
sjekk(hendelseVist, "Golden Egg Rain vises på skjermen")
Hendelser.slutt()
Spillere.giPenger(spiller, Config.REBIRTH.PRIS)
steg(0.3)
Menyer.aapne("Shop")
steg(0.1)
local function trykk(tekst)
	for _, d in hudSkjerm.Shop:GetDescendants() do
		if d:IsA("TextButton") and d.Text == tekst then
			d.MouseButton1Click:Fire()
			return true
		end
	end
	return false
end
sjekk(trykk("⭐ ROBUX"), "Robux-fanen finnes")
trykk("⬆️ UPGRADES")
sjekk(trykk("REBIRTH") and trykk("YES, REBIRTH!"), "trykket REBIRTH og YES")
steg(0.4)
sjekk(Klientdata.status.rebirths == 1, "rebirth gjennomført via knappene")
Menyer.lukk()

-- testpanelet (Studio): Meteor-knappen starter meteoren
local testKnapp = nil
for _, d in hudSkjerm:GetDescendants() do
	if d:IsA("TextButton") and d.Text == "☄️ Meteor" then
		testKnapp = d
	end
end
sjekk(testKnapp ~= nil, "testpanelet finnes i Studio")
if testKnapp then
	testKnapp.MouseButton1Click:Fire()
	steg(0.3)
	sjekk(workspace:GetAttribute("Hendelse") == "Meteor", "testknappen startet meteoren")
	krev("server/Hendelser").slutt()
end

print(string.format("Simulerte %.0f s.", Mock.tid()))
print((#Mock.feil == 0 and feil == 0) and "INGEN FEIL" or ("FEIL: " .. (#Mock.feil + feil)))
