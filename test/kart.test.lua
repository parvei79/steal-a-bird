-- Sjekker kartet: alt i basene står på bakken, broene går fra base til Reiret, svevesteinene er fri
-- for broene, eggebåndet ligger på Reiret. Skriver DATA-linjer som tools/vis_kart.py tegner.
-- Kjør: python3 tools/test_luau.py test/kart.test.lua --data /tmp/kart.json
local Kart = krev("shared/Kart")

local feil = 0
local function sjekk(ok, tekst)
	if not ok then
		feil += 1
		print("  FEIL " .. tekst)
	end
end

local function data(t)
	local deler = {}
	for k, v in t do
		table.insert(deler, string.format("%q:%s", k, type(v) == "string" and string.format("%q", v) or tostring(v)))
	end
	print("DATA:{" .. table.concat(deler, ",") .. "}")
end

-- øyene
for _, oy in Kart.alleOyer() do
	for _, k in Kart.kolonner(oy) do
		data({ k = "c", x = k.x, z = k.z, t = k.topp, b = k.bunn, r = oy.r })
	end
end

local function paaBakken(pos, tekst, hoyde)
	local t = Kart.toppHoyde(pos.X, pos.Z)
	sjekk(t ~= nil and math.abs(t - (hoyde or Kart.HOYDE)) < 0.01, tekst .. string.format(" (%.0f, %.0f) står ikke på bakken", pos.X, pos.Z))
end

for i = 1, Kart.ANTALL_BASER do
	for n = 1, Kart.ANTALL_SOKLER do
		local p = Kart.sokkel(i, n).Position
		-- hele sokkelen (radius 2) må stå på øya
		for _, d in { Vector3.new(2, 0, 0), Vector3.new(-2, 0, 0), Vector3.new(0, 0, 2), Vector3.new(0, 0, -2) } do
			paaBakken(p + d, "base " .. i .. " sokkel " .. n)
		end
		data({ k = "s", x = p.X, z = p.Z })
	end
	for navn, cf in { laas = Kart.laas(i), plate = Kart.pengeplate(i), skilt = Kart.skilt(i) } do
		paaBakken(cf.Position, "base " .. i .. " " .. navn)
		data({ k = navn, x = cf.Position.X, z = cf.Position.Z })
	end
	paaBakken(Kart.spawn(i).Position, "base " .. i .. " spawn")
end
-- eggebåndet ligger på Reiret
for n = 0, 31 do
	local p = Kart.beltePos(n / 32).Position
	paaBakken(p, "eggebåndet")
	data({ k = "belte", x = p.X, z = p.Z })
end
-- basene overlapper ikke
for i = 1, Kart.ANTALL_BASER do
	local a = Kart.BASER[i]
	local b = Kart.BASER[i % Kart.ANTALL_BASER + 1]
	local d = math.sqrt((a.x - b.x) ^ 2 + (a.z - b.z) ^ 2)
	sjekk(d > a.r + b.r + 30, string.format("base %d og %d er for nær hverandre (%.0f)", i, i % 8 + 1, d))
end
print(feil == 0 and "INGEN FEIL" or ("FEIL: " .. feil))
