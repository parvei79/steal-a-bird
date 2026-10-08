-- Hvor alt ligger: Reiret i midten med eggebåndet, de 8 basene i en ring med sokler, låseknapp,
-- pengeplate og skilt, hengebroene og svevesteinene. Øyene er bygget av kuber på 4 studs.
-- Ren matematikk, delt mellom server og klient og testbar med luau.
local Kart = {}

Kart.BLOKK = 4
Kart.HOYDE = 40                      -- toppen av Reiret og basene (Y)

Kart.REIR = { navn = "Nest", x = 0, z = 0, topp = 40, r = 46, dybde = 36, fro = 1 }
Kart.BELTE = { radius = 31, topp = 40.6, bredde = 7 }

Kart.ANTALL_BASER = 8
Kart.BASE_AVSTAND = 165
Kart.BASE_R = 28

Kart.BASER = {}
for i = 1, Kart.ANTALL_BASER do
	local a = (i - 1) / Kart.ANTALL_BASER * 2 * math.pi
	Kart.BASER[i] = {
		nr = i, navn = "Base " .. i, vinkel = a,
		x = math.cos(a) * Kart.BASE_AVSTAND, z = math.sin(a) * Kart.BASE_AVSTAND,
		topp = Kart.HOYDE, r = Kart.BASE_R, dybde = 28, fro = 10 + i,
	}
end

-- Svevesteiner å svinge seg i: en indre ring mellom broene, en ytre ring mellom basene,
-- og noen høye over Reiret.
Kart.STEINER = {}
for i = 1, Kart.ANTALL_BASER do
	local a = (i - 0.5) / Kart.ANTALL_BASER * 2 * math.pi
	table.insert(Kart.STEINER, { x = math.cos(a) * 100, z = math.sin(a) * 100, topp = 64 + (i % 3) * 6, r = 6,
		dybde = 10, fro = 30 + i })
	table.insert(Kart.STEINER, { x = math.cos(a) * 178, z = math.sin(a) * 178, topp = 70 + (i % 2) * 8, r = 7,
		dybde = 12, fro = 40 + i })
end
-- Trappesteiner (det er ingen broer): én høy stein midt på linjen mellom hver base og Reiret.
for i = 1, Kart.ANTALL_BASER do
	local a = (i - 1) / Kart.ANTALL_BASER * 2 * math.pi
	table.insert(Kart.STEINER, { x = math.cos(a) * 92, z = math.sin(a) * 92, topp = 58, r = 6, dybde = 10, fro = 60 + i })
end
for i = 1, 4 do
	local a = (i - 1) / 4 * 2 * math.pi + math.pi / 4
	table.insert(Kart.STEINER, { x = math.cos(a) * 58, z = math.sin(a) * 58, topp = 96, r = 5, dybde = 8, fro = 50 + i })
end

-- ---------------------------------------------------------------- øyformer

local function hash(x, z, fro)
	local n = math.sin(x * 12.9898 + z * 78.233 + fro * 37.719) * 43758.5453
	return n - math.floor(n)
end

-- Kolonnen med sentrum (cx, cz) på øya `oy`: returnerer topp, bunn (Y) eller nil hvis den er utenfor.
function Kart.kolonne(oy, cx, cz)
	local dx, dz = cx - oy.x, cz - oy.z
	local d = math.sqrt(dx * dx + dz * dz)
	local kant = oy.r + hash(cx, cz, oy.fro) * 2.5
	if d > kant then
		return nil
	end
	local andel = math.clamp(d / oy.r, 0, 1)
	local dyp = oy.dybde * (1 - andel ^ 1.6) + hash(cz, cx, oy.fro + 7) * 6
	local lag = math.max(1, math.floor(dyp / Kart.BLOKK + 0.5))
	return oy.topp, oy.topp - Kart.BLOKK * (1 + lag)
end

-- Alle kolonnene på en øy: { { x, z, topp, bunn }, ... } (x, z = midten av kolonnen)
function Kart.kolonner(oy)
	local B = Kart.BLOKK
	local ut = {}
	local r = oy.r + 2
	for ix = math.floor((oy.x - r) / B), math.ceil((oy.x + r) / B) do
		for iz = math.floor((oy.z - r) / B), math.ceil((oy.z + r) / B) do
			local cx, cz = (ix + 0.5) * B, (iz + 0.5) * B
			local topp, bunn = Kart.kolonne(oy, cx, cz)
			if topp then
				table.insert(ut, { x = cx, z = cz, ix = ix, iz = iz, topp = topp, bunn = bunn })
			end
		end
	end
	return ut
end

function Kart.alleOyer()
	local liste = { Kart.REIR }
	for _, b in Kart.BASER do
		table.insert(liste, b)
	end
	for _, s in Kart.STEINER do
		table.insert(liste, s)
	end
	return liste
end

-- Høyeste bakke (toppen av en øy) rett over/under (x, z), eller nil. Broene teller ikke med.
function Kart.toppHoyde(x, z)
	local B = Kart.BLOKK
	local cx, cz = (math.floor(x / B) + 0.5) * B, (math.floor(z / B) + 0.5) * B
	local best = nil
	for _, oy in Kart.alleOyer() do
		if math.abs(cx - oy.x) <= oy.r + 3 and math.abs(cz - oy.z) <= oy.r + 3 then
			local topp = Kart.kolonne(oy, cx, cz)
			if topp and (not best or topp > best) then
				best = topp
			end
		end
	end
	return best
end

-- ---------------------------------------------------------------- basene

-- Basens koordinatsystem: origo midt på toppen, -Z (LookVector) peker mot Reiret, +X til høyre.
function Kart.baseCF(i)
	local b = Kart.BASER[i]
	return CFrame.lookAt(Vector3.new(b.x, b.topp, b.z), Vector3.new(Kart.REIR.x, b.topp, Kart.REIR.z))
end

-- Punkt i basen: lx til høyre, lz bakover (bort fra Reiret), ly opp.
function Kart.lokal(i, lx, lz, ly)
	return Kart.baseCF(i) * Vector3.new(lx, ly or 0, lz)
end

-- 20 sokler: 4 rader à 5. Rekkefølgen er midten først, så de første fuglene står fint.
local SOKKEL_X = { 0, -9, 9, -18, 18 }
local SOKKEL_Z = { -11, -2, 7, 16 }
Kart.ANTALL_SOKLER = 20

-- Sokkel nr. n (1–20) i base i: CFrame på bakken, fuglen ser mot inngangen.
function Kart.sokkel(i, n)
	local rad = math.floor((n - 1) / 5) + 1
	local kol = (n - 1) % 5 + 1
	return Kart.baseCF(i) * CFrame.new(SOKKEL_X[kol], 0, SOKKEL_Z[rad])
end

function Kart.laas(i)
	return Kart.baseCF(i) * CFrame.new(-9, 0, -20)
end

function Kart.pengeplate(i)
	return Kart.baseCF(i) * CFrame.new(9, 0, -20)
end

function Kart.skilt(i)
	return Kart.baseCF(i) * CFrame.new(0, 0, 25)
end

function Kart.spawn(i)
	return Kart.baseCF(i) * CFrame.new(0, 3, 21.5)
end

-- Inngangen (der broen kommer inn) og broens andre ende ved Reiret.
function Kart.bro(i)
	local b = Kart.BASER[i]
	local ut = Vector3.new(b.x - Kart.REIR.x, 0, b.z - Kart.REIR.z).Unit
	local fra = Vector3.new(b.x, b.topp, b.z) - ut * (b.r - 1)
	local til = Vector3.new(Kart.REIR.x, Kart.REIR.topp, Kart.REIR.z) + ut * (Kart.REIR.r - 2)
	return fra, til
end

-- Er pos inne i base i? (litt romslig, og bare nær toppen)
function Kart.iBase(i, pos, ekstra)
	local b = Kart.BASER[i]
	local dx, dz = pos.X - b.x, pos.Z - b.z
	return dx * dx + dz * dz <= (b.r + (ekstra or 1)) ^ 2 and pos.Y > b.topp - 6 and pos.Y < b.topp + 45
end

-- Hvilken base er pos i (nil = ingen)?
function Kart.hvilkenBase(pos)
	for i = 1, Kart.ANTALL_BASER do
		if Kart.iBase(i, pos) then
			return i
		end
	end
	return nil
end

-- ---------------------------------------------------------------- eggebåndet

-- Posisjonen til et egg som har gått `andel` (0..1) av runden. Egget står oppreist på båndet.
function Kart.beltePos(andel)
	local a = andel * 2 * math.pi
	local R = Kart.BELTE.radius
	local p = Vector3.new(Kart.REIR.x + math.cos(a) * R, Kart.BELTE.topp, Kart.REIR.z + math.sin(a) * R)
	-- egget ser i fartsretningen
	local frem = Vector3.new(-math.sin(a), 0, math.cos(a))
	return CFrame.lookAt(p, p + frem)
end

return Kart
