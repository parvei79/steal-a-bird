-- Serveren i Steal a Bird i Roblox-etterligningen: to spillere kjøper egg, bærer dem hjem, klekker,
-- tjener og henter penger, stjeler fra hverandre, rykker tyven, låser basen, oppgraderer, selger,
-- bytter fugler — og alt lagres og lastes inn igjen.
-- Kjør: python3 tools/test_luau.py test/server.test.lua --mock
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
	local n = math.max(1, math.floor(sek / dt + 0.5))
	for _ = 1, n do
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
print(string.format("Server klar: %d instanser", Mock.instanser()))

local Ting = krev("server/Ting")
local Baser = krev("server/Baser")
local Spillere = krev("server/Spillere")
local Reiret = krev("server/Reiret")
local Handling = game.ReplicatedStorage.Remotes.Handling
local Rykk = game.ReplicatedStorage.Remotes.Rykk
local HandelR = game.ReplicatedStorage.Remotes.Handel

local function hendelser(navn, til)
	local ut = {}
	for _, h in Mock.hendelser do
		if h.remote == "Hendelse" and h.args[1] == navn and (not til or h.til == til) then
			table.insert(ut, h)
		end
	end
	return ut
end

local function flytt(spiller, pos)
	spiller.Character:PivotTo(CFrame.new(pos))
end

local function minsteEgg()
	local best
	for _, e in Reiret.egg() do
		if not best or Fugler.SJ[e.sj].pris < Fugler.SJ[best.sj].pris then
			best = e
		end
	end
	return best
end

-- ---------------------------------------------------------------- spiller A kommer
local A = Mock.leggTilSpiller("Pål", 1001)
steg(0.5)
local iA = Baser.til(A)
sjekk(iA == 1, "A fikk base 1")
sjekk(Spillere.penger(A) == Config.BASE.STARTPENGER, "A har startpenger $" .. Spillere.penger(A))
sjekk((A.Character.HumanoidRootPart.Position - Kart.spawn(iA).Position).Magnitude < 1, "A står i basen sin")
sjekk(A.Character:FindFirstChildOfClass("Tool") ~= nil, "A har krokpistolen")

-- kjøp det billigste egget
local e = minsteEgg()
sjekk(e ~= nil, "det ligger egg på båndet")
local pris = Fugler.SJ[e.sj].pris
-- gi A nok penger til egget uansett sjeldenhet
if Spillere.penger(A) < pris then
	Spillere.giPenger(A, pris)
end
local foer = Spillere.penger(A)
flytt(A, Reiret.pos(e).Position + Vector3.new(0, 3, 4))
Handling.OnServerEvent:Fire(A, "kjop", e.id)
steg(0.1)
local t = Ting.baeres(A)
sjekk(t ~= nil and t.egg, "A bærer et " .. e.sj .. "-egg")
sjekk(Spillere.penger(A) == foer - pris, "pengene ble trukket")
sjekk(A.Character:GetAttribute("Baerer") == t.id, "figuren vet hva den bærer")
sjekk(A.Character.Humanoid.WalkSpeed < 16, "A går saktere med last")
-- bær det hjem
flytt(A, Kart.lokal(iA, 0, 0, 3))
steg(0.3)
sjekk(Ting.baeres(A) == nil and t.tilstand == "plass" and t.plass == 1, "egget ble levert på sokkel 1")
sjekk(A.Character.Humanoid.WalkSpeed == 16, "full fart igjen")
-- klekk
steg(Fugler.SJ[t.sj].klekk + 2.5, 1 / 10)
sjekk(not t.egg and t.modell and t.modell:GetAttribute("Art") == t.art, "egget klekket til en " .. tostring(t.art))
sjekk(#hendelser("klekket") == 1, "alle fikk beskjed om klekkingen")
sjekk(Spillere.profil(A).data.index[t.art] ~= nil, "fuglen står i samleboka")
-- penger på pengeplaten
steg(5.2, 1 / 10)
local pott = Baser.pott(iA)
sjekk(pott >= Fugler.inntekt(t.art, t.mut) * 4, string.format("pengeplaten har %d (inntekt %d/s)", pott, Fugler.inntekt(t.art, t.mut)))
local foerSamling = Spillere.penger(A)
flytt(A, Kart.pengeplate(iA).Position + Vector3.new(0, 3, 0))
steg(0.3)
sjekk(Spillere.penger(A) >= foerSamling + pott, "A hentet pengene (" .. Spillere.penger(A) - foerSamling .. ")")

-- ---------------------------------------------------------------- spiller B kommer og stjeler
local B = Mock.leggTilSpiller("Sander", 1002)
steg(0.5)
local iB = Baser.til(B)
sjekk(iB == 2, "B fikk base 2")
-- nybegynnerskjold: A kan ikke stjele fra B, og B kan ikke stjele fra A før A sitt skjold er borte
flytt(B, t.modell.PrimaryPart.Position + Vector3.new(3, 0, 0))
Handling.OnServerEvent:Fire(B, "ta", t.id)
steg(0.1)
sjekk(Ting.baeres(B) == nil and #hendelser("feil", "Sander") >= 1, "nybegynnerskjoldet stopper tyven")
steg(Config.BASE.NYBEGYNNER + 1, 1 / 5)
flytt(B, t.modell.PrimaryPart.Position + Vector3.new(3, 0, 0))
Handling.OnServerEvent:Fire(B, "ta", t.id)
steg(0.1)
sjekk(Ting.baeres(B) == t and t.fra and t.fra.eier == A, "B stjal fuglen")
sjekk(#hendelser("alarm", "Pål") == 1, "A fikk alarm")
sjekk(B.Character:GetAttribute("Tyv") == true, "B er merket som tyv")
-- A rykker B med kroken: fuglen flyr hjem igjen
flytt(B, Kart.lokal(iA, 0, -40, 4))
flytt(A, Kart.lokal(iA, 0, -10, 3))
Rykk.OnServerEvent:Fire(A, B.Character.HumanoidRootPart)
steg(0.1)
sjekk(Ting.baeres(B) == nil and t.eier == A and t.tilstand == "plass" and t.plass == 1, "rykket: fuglen flyr hjem til A")
sjekk((B.Character:GetAttribute("Ragdoll") or 0) > workspace:GetServerTimeNow(), "B ragdoller")
sjekk((B.Character:GetAttribute("Svimmel") or 0) > workspace:GetServerTimeNow(), "B er svimmel")
-- B stjeler igjen og kommer seg hjem
steg(1)
flytt(B, t.modell.PrimaryPart.Position + Vector3.new(3, 0, 0))
Handling.OnServerEvent:Fire(B, "ta", t.id)
steg(0.1)
flytt(B, Kart.lokal(iB, 0, 0, 3))
steg(0.3)
sjekk(t.eier == B and t.tilstand == "plass", "B kom hjem med fuglen, den er Bs nå")
sjekk(Spillere.profil(B).data.tyverier == 1, "B har 1 tyveri")
sjekk(#hendelser("stjalet") == 1, "alle fikk beskjed om tyveriet")

-- ---------------------------------------------------------------- lås
flytt(A, Kart.laas(iA).Position + Vector3.new(2, 2, 0))
Handling.OnServerEvent:Fire(A, "laas")
steg(0.2)
sjekk(Baser.laast(iA), "A låste basen")
-- A får en ny fugl (rett inn i basen), og B prøver å stjele den mens basen er låst
local e2 = minsteEgg()
Spillere.giPenger(A, Fugler.SJ[e2.sj].pris)
flytt(A, Reiret.pos(e2).Position + Vector3.new(0, 3, 4))
Handling.OnServerEvent:Fire(A, "kjop", e2.id)
steg(0.1)
local t2 = Ting.baeres(A)
flytt(A, Kart.lokal(iA, 0, 0, 3))
steg(0.3)
sjekk(t2 and t2.tilstand == "plass", "A sitt nye egg står i basen")
flytt(B, t2.modell.PrimaryPart.Position + Vector3.new(3, 0, 0))
Handling.OnServerEvent:Fire(B, "ta", t2.id)
steg(0.1)
sjekk(Ting.baeres(B) == nil, "B kan ikke stjele fra en låst base")
local dytt = 0
for _, h in Mock.hendelser do
	if h.remote == "Knuff" and h.til == "Sander" then
		dytt += 1
	end
end
sjekk(dytt >= 1, "B ble dyttet ut av den låste basen")
steg(Config.BASE.LAAS_TID + 1, 1 / 5)
sjekk(not Baser.laast(iA), "låsen gikk ut")

-- ---------------------------------------------------------------- oppgradering og salg
Spillere.giPenger(A, 1000)
local slots = Baser.sokler(iA)
Handling.OnServerEvent:Fire(A, "oppgrader", "sokler")
steg(0.1)
sjekk(Baser.sokler(iA) == slots + 2, "Base Slots-oppgraderingen ga 2 sokler til")
local foerSalg = Spillere.penger(A)
flytt(A, t2.modell.PrimaryPart.Position + Vector3.new(3, 0, 0))
Handling.OnServerEvent:Fire(A, "selg", t2.id)
steg(0.1)
sjekk(Ting.hent(t2.id) == nil and Spillere.penger(A) > foerSalg, "A solgte egget")

-- ---------------------------------------------------------------- mistet egg kan snappes
local e3 = minsteEgg()
Spillere.giPenger(A, Fugler.SJ[e3.sj].pris)
flytt(A, Reiret.pos(e3).Position + Vector3.new(0, 3, 4))
Handling.OnServerEvent:Fire(A, "kjop", e3.id)
steg(0.1)
local t3 = Ting.baeres(A)
flytt(B, Reiret.pos(e3).Position + Vector3.new(6, 3, 0))
Rykk.OnServerEvent:Fire(B, A.Character.HumanoidRootPart)
steg(0.1)
sjekk(t3 and t3.tilstand == "sluppet", "A ble rykket og mistet egget (det svever)")
Handling.OnServerEvent:Fire(B, "ta", t3.id)
steg(0.1)
sjekk(Ting.baeres(B) == t3 and t3.eier == B, "B snappet egget")
flytt(B, Kart.lokal(iB, 0, 0, 3))
steg(0.3)
sjekk(t3.eier == B and t3.tilstand == "plass", "B fikk egget hjem")

-- ---------------------------------------------------------------- bytte (trading)
-- A trenger en fugl å bytte med: gi A en klekket fugl direkte
steg(Fugler.SJ[t3.sj].klekk + 3, 1 / 10)
local fa = nil
for _, x in Ting.alle() do
	if x.eier == A and not x.egg then
		fa = x
	end
end
if not fa then
	Ting.lastInn(A, { { a = "Pigeon", s = 3 } })
	for _, x in Ting.alle() do
		if x.eier == A and not x.egg then
			fa = x
		end
	end
end
local fb = t3.egg and t or t3
sjekk(fa ~= nil and fb ~= nil and not fb.egg, "begge har en fugl å bytte")
HandelR.OnServerEvent:Fire(A, "be", B.UserId)
HandelR.OnServerEvent:Fire(B, "svar", A.UserId, true)
HandelR.OnServerEvent:Fire(A, "legg", fa.id)
HandelR.OnServerEvent:Fire(B, "legg", fb.id)
-- B kan ikke selge en fugl som er med i byttet
flytt(B, fb.modell.PrimaryPart.Position + Vector3.new(3, 0, 0))
Handling.OnServerEvent:Fire(B, "selg", fb.id)
steg(0.1)
sjekk(Ting.hent(fb.id) ~= nil, "en fugl i et bytte kan ikke selges")
HandelR.OnServerEvent:Fire(A, "klar", true)
HandelR.OnServerEvent:Fire(B, "klar", true)
steg(5.5, 1 / 10)
sjekk(fa.eier == B and fb.eier == A, "byttet ble gjennomført")

-- ---------------------------------------------------------------- lagring
local antallA = 0
for _, x in Ting.alle() do
	if x.eier == A then
		antallA += 1
	end
end
local pengerA = Spillere.penger(A) + Baser.pott(iA)
A.Parent = nil
for i, s in Mock.spillere do
	if s == A then
		table.remove(Mock.spillere, i)
	end
end
game.Players.PlayerRemoving:Fire(A)
steg(0.5)
local lagret = Mock.datastore["StealABird_v1"]["spiller_1001"]
sjekk(lagret ~= nil and #lagret.fugler == antallA, "A sine " .. antallA .. " fugler ble lagret")
sjekk(lagret and lagret.penger == pengerA, "pengene (med pengeplaten) ble lagret: " .. tostring(lagret and lagret.penger))
sjekk(lagret and lagret.laas == nil, "låsen ble sluppet da A gikk")
sjekk(Baser.eier(iA) == nil, "base 1 er ledig igjen")
local A2 = Mock.leggTilSpiller("Pål", 1001)
steg(0.5)
local antall2 = 0
for _, x in Ting.alle() do
	if x.eier == A2 then
		antall2 += 1
	end
end
sjekk(antall2 == antallA, "A fikk fuglene tilbake da han kom inn igjen")
sjekk(Spillere.penger(A2) == pengerA, "og pengene")

-- en annen server har låst dataene: spilleren venter, og spiller uten å lagre i stedet for å skrive over
Mock.datastore["StealABird_v1"]["spiller_1003"] = { v = 1, penger = 777, fugler = {}, oppgr = {}, index = {},
	laas = { jobb = "en-annen-server", tid = os.time() } }
local C = Mock.leggTilSpiller("Gjest", 1003)
steg(30, 1 / 5)
sjekk(Spillere.profil(C) and Spillere.profil(C).lagres == false, "låst av annen server: spiller uten lagring")
sjekk(Mock.datastore["StealABird_v1"]["spiller_1003"].penger == 777, "den andre serverens data er urørt")

print(string.format("Simulerte %.0f s. Remote-meldinger: %d", Mock.tid(), #Mock.hendelser))
print((#Mock.feil == 0 and feil == 0) and "INGEN FEIL" or ("FEIL: " .. (#Mock.feil + feil)))
