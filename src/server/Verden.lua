-- Den faste verdenen: lys og himmel, blokk-øyene (Reiret, basene og svevesteinene) bygget av kuber,
-- eggebåndet rundt Reiret, kjempereiret, hengebroene, skyene og pynten.
-- Basenes egne ting (sokler, lås, pengeplate, skilt) lages i Baser.lua.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Kart = require(Shared:WaitForChild("Kart"))

local Verden = {}

local Modeller
local mappe

-- Hver base har sin farge (kanten av øya, flagget og skiltet).
Verden.BASEFARGER = {
	Color3.fromRGB(240, 70, 70), Color3.fromRGB(255, 150, 50), Color3.fromRGB(255, 215, 60), Color3.fromRGB(90, 210, 90),
	Color3.fromRGB(60, 210, 220), Color3.fromRGB(70, 130, 255), Color3.fromRGB(165, 95, 255), Color3.fromRGB(255, 110, 200),
}

local function del(e, forelder)
	local p = Instance.new(e.Klasse or "Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for k, v in e do
		if k ~= "Klasse" then
			p[k] = v
		end
	end
	p.Parent = forelder or mappe
	return p
end
Verden.del = del

-- ---------------------------------------------------------------- lys og himmel

function Verden.lys()
	Lighting.ClockTime = 14
	Lighting.GeographicLatitude = 25
	Lighting.Brightness = 3
	Lighting.Ambient = Color3.fromRGB(110, 115, 135)
	Lighting.OutdoorAmbient = Color3.fromRGB(170, 175, 200)
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = 0.6
	Lighting.GlobalShadows = true
	local function effekt(klasse, e)
		local x = Instance.new(klasse)
		for k, v in e do
			x[k] = v
		end
		x.Parent = Lighting
	end
	effekt("Atmosphere", { Density = 0.25, Offset = 0.1, Color = Color3.fromRGB(205, 228, 255),
		Decay = Color3.fromRGB(140, 175, 230), Glare = 0.3, Haze = 1 })
	effekt("Sky", { SunAngularSize = 16, MoonAngularSize = 8 })
	effekt("BloomEffect", { Intensity = 0.45, Size = 22, Threshold = 1.4 })
	effekt("SunRaysEffect", { Intensity = 0.05, Spread = 0.7 })
	effekt("ColorCorrectionEffect", { Saturation = 0.22, Contrast = 0.08, Brightness = 0.02 })
	local skyer = Instance.new("Clouds")
	skyer.Cover = 0.5
	skyer.Density = 0.45
	skyer.Parent = workspace.Terrain
end

-- ---------------------------------------------------------------- blokk-øyene

local GRESS = { Color3.fromRGB(104, 200, 80), Color3.fromRGB(92, 186, 72), Color3.fromRGB(118, 210, 92) }
local JORD = { Color3.fromRGB(140, 98, 62), Color3.fromRGB(126, 88, 56) }
local STEIN = { Color3.fromRGB(128, 128, 136), Color3.fromRGB(112, 112, 122) }

local function hash(a, b, c)
	local n = math.sin(a * 127.1 + b * 311.7 + c * 74.7) * 43758.5453
	return n - math.floor(n)
end

-- Slå sammen like naboruter til store rektangler (færre deler). celler[ix][iz] = nøkkel.
local function gradig(celler, lag)
	local brukt = {}
	local ut = {}
	local function hent(ix, iz)
		local r = celler[ix]
		return r and r[iz]
	end
	local nokler = {}
	for ix, rad in celler do
		for iz in rad do
			table.insert(nokler, { ix, iz })
		end
	end
	table.sort(nokler, function(a, b)
		return a[2] < b[2] or (a[2] == b[2] and a[1] < b[1])
	end)
	for _, k in nokler do
		local ix, iz = k[1], k[2]
		local id = ix .. "," .. iz
		if not brukt[id] then
			local nokkel = hent(ix, iz)
			local w, h = 1, 1
			while hent(ix + w, iz) == nokkel and not brukt[(ix + w) .. "," .. iz] do
				w += 1
			end
			local fortsett = true
			while fortsett do
				for x = 0, w - 1 do
					if hent(ix + x, iz + h) ~= nokkel or brukt[(ix + x) .. "," .. (iz + h)] then
						fortsett = false
						break
					end
				end
				if fortsett then
					h += 1
				end
			end
			for x = 0, w - 1 do
				for z = 0, h - 1 do
					brukt[(ix + x) .. "," .. (iz + z)] = true
				end
			end
			table.insert(ut, { ix = ix, iz = iz, w = w, h = h, nokkel = nokkel, lag = lag })
		end
	end
	return ut
end

-- Bygg én øy av kuber. kantfarge = farge på den ytterste ringen av toppen (basene).
function Verden.oy(oy, forelder, kantfarge)
	local B = Kart.BLOKK
	local kolonner = Kart.kolonner(oy)
	local lagListe = {} -- [lag] = { [ix] = { [iz] = nøkkel } }  lag 0 = toppen
	local maksLag = 0
	for _, k in kolonner do
		local antall = math.floor((k.topp - k.bunn) / B + 0.5)
		local d = math.sqrt((k.x - oy.x) ^ 2 + (k.z - oy.z) ^ 2)
		for lag = 0, antall - 1 do
			local nokkel
			if lag == 0 then
				if kantfarge and d > oy.r - 5 then
					nokkel = "kant"
				else
					nokkel = "g" .. (math.floor(hash(math.floor(k.ix / 2), math.floor(k.iz / 2), oy.fro) * 3) + 1)
				end
			elseif lag <= 2 then
				nokkel = "j" .. lag
			else
				nokkel = "s" .. (lag % 2 + 1)
			end
			lagListe[lag] = lagListe[lag] or {}
			lagListe[lag][k.ix] = lagListe[lag][k.ix] or {}
			lagListe[lag][k.ix][k.iz] = nokkel
			maksLag = math.max(maksLag, lag)
		end
	end
	local antallDeler = 0
	for lag = 0, maksLag do
		if lagListe[lag] then
			for _, r in gradig(lagListe[lag], lag) do
				local farge
				local n = r.nokkel
				if n == "kant" then
					farge = kantfarge
				elseif string.sub(n, 1, 1) == "g" then
					farge = GRESS[tonumber(string.sub(n, 2))]
				elseif string.sub(n, 1, 1) == "j" then
					farge = JORD[tonumber(string.sub(n, 2))]
				else
					farge = STEIN[tonumber(string.sub(n, 2))]
				end
				local x0, z0 = r.ix * B, r.iz * B
				local y1 = oy.topp - lag * B
				del({ Name = lag == 0 and "Gress" or "Blokk", Size = Vector3.new(r.w * B, B, r.h * B),
					CFrame = CFrame.new(x0 + r.w * B / 2, y1 - B / 2, z0 + r.h * B / 2), Color = farge,
					Material = lag == 0 and Enum.Material.Grass or Enum.Material.SmoothPlastic }, forelder)
				antallDeler += 1
			end
		end
	end
	return antallDeler
end

-- ---------------------------------------------------------------- Reiret og eggebåndet

local function reiret()
	local R = Kart.REIR
	local m = Instance.new("Model")
	m.Name = "Reiret"
	m.Parent = mappe
	Verden.oy(R, m)
	-- kjempereiret i midten
	local reir = Modeller.plasser("Kjempereir", CFrame.new(R.x, R.topp, R.z), 1, m)
	if reir then
		reir.CanCollide = true
		reir.CanQuery = true
	else
		for n = 0, 15 do
			local a = n / 16 * math.pi * 2
			del({ Name = "Reirkvist", Size = Vector3.new(4, 5, 7),
				CFrame = CFrame.new(R.x + math.cos(a) * 11, R.topp + 2.5, R.z + math.sin(a) * 11) * CFrame.Angles(0, -a, 0),
				Color = Color3.fromRGB(150, 110, 70), Material = Enum.Material.Wood }, m)
		end
	end
	-- eggebåndet: en ring av mørke segmenter med gule kanter
	local B = Kart.BELTE
	local antall = 64
	for n = 0, antall - 1 do
		local a0 = n / antall * math.pi * 2
		local a1 = (n + 1) / antall * math.pi * 2
		local p0 = Vector3.new(R.x + math.cos(a0) * B.radius, B.topp - 0.3, R.z + math.sin(a0) * B.radius)
		local p1 = Vector3.new(R.x + math.cos(a1) * B.radius, B.topp - 0.3, R.z + math.sin(a1) * B.radius)
		local midt = (p0 + p1) / 2
		local lengde = (p1 - p0).Magnitude + 0.15
		del({ Name = "Belte", Size = Vector3.new(B.bredde, 0.6, lengde), CFrame = CFrame.lookAt(midt, p1),
			Color = n % 2 == 0 and Color3.fromRGB(58, 60, 70) or Color3.fromRGB(48, 50, 60) }, m)
		for _, side in { -1, 1 } do
			local r = B.radius + side * (B.bredde / 2 + 0.3)
			local q0 = Vector3.new(R.x + math.cos(a0) * r, B.topp + 0.1, R.z + math.sin(a0) * r)
			local q1 = Vector3.new(R.x + math.cos(a1) * r, B.topp + 0.1, R.z + math.sin(a1) * r)
			del({ Name = "Beltekant", Size = Vector3.new(0.6, 1.2, (q1 - q0).Magnitude + 0.1),
				CFrame = CFrame.lookAt((q0 + q1) / 2, q1), Color = n % 4 < 2 and Color3.fromRGB(255, 205, 40)
					or Color3.fromRGB(40, 40, 46) }, m)
		end
	end
	-- skilt over båndet
	local tavle = del({ Name = "EggTavle", Size = Vector3.new(16, 4, 0.6), CFrame = CFrame.new(R.x, R.topp + 18, R.z),
		Color = Color3.fromRGB(255, 210, 60), CanCollide = false }, m)
	for _, side in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local gui = Instance.new("SurfaceGui")
		gui.Face = side
		gui.LightInfluence = 0
		local t = Instance.new("TextLabel")
		t.Size = UDim2.fromScale(1, 1)
		t.BackgroundTransparency = 1
		t.Font = Enum.Font.FredokaOne
		t.TextScaled = true
		t.Text = "🥚 EGG SHOP 🥚"
		t.TextColor3 = Color3.fromRGB(90, 50, 20)
		t.Parent = gui
		gui.Parent = tavle
	end
	-- «Like»-skilt ved kanten av Reiret
	local likePos = Vector3.new(R.x + math.cos(math.rad(112)) * 41, R.topp, R.z + math.sin(math.rad(112)) * 41)
	local likeCf = CFrame.lookAt(likePos + Vector3.new(0, 6, 0), Vector3.new(R.x, R.topp + 6, R.z))
	local like = del({ Name = "LikeSkilt", Size = Vector3.new(12, 6, 0.6), CFrame = likeCf,
		Color = Color3.fromRGB(70, 150, 255) }, m)
	del({ Name = "LikeStolpe", Size = Vector3.new(0.8, 3, 0.8), CFrame = CFrame.new(likePos + Vector3.new(0, 1.5, 0)),
		Color = Color3.fromRGB(110, 78, 48) }, m)
	do
		local gui = Instance.new("SurfaceGui")
		gui.Face = Enum.NormalId.Front
		gui.LightInfluence = 0
		local t = Instance.new("TextLabel")
		t.Size = UDim2.fromScale(1, 1)
		t.BackgroundTransparency = 1
		t.Font = Enum.Font.FredokaOne
		t.TextScaled = true
		t.Text = "👍 LIKE + ⭐ FAVORITE\nfor NEW BIRDS every week!"
		t.TextColor3 = Color3.new(1, 1, 1)
		t.TextStrokeTransparency = 0.2
		t.Parent = gui
		gui.Parent = like
	end
	-- en reserve-startplass midt på Reiret (spillerne flyttes til basen sin med en gang)
	del({ Klasse = "SpawnLocation", Name = "Start", Size = Vector3.new(6, 1, 6),
		CFrame = CFrame.new(R.x + 20, R.topp + 0.5, R.z + 20), Transparency = 1, CanCollide = false, Neutral = true,
		Duration = 0 }, m)
end

-- ---------------------------------------------------------------- hengebroer

local function _bro(a, b, farge) -- ikke i bruk: spillet har ingen broer (du må svinge deg over)
	local lengde = (b - a).Magnitude
	local frem = (b - a).Unit
	local hoyre = frem:Cross(Vector3.new(0, 1, 0)).Unit
	local heng = lengde * 0.05
	local antall = math.floor(lengde / 2.4)
	local forrige = {}
	local BREDDE = 7
	local function punkt(t)
		return a:Lerp(b, t) - Vector3.new(0, heng * 4 * t * (1 - t), 0)
	end
	for i = 0, antall do
		local t = i / antall
		local p = punkt(t)
		local q = punkt(math.min(1, t + 1 / antall))
		local retning = (q - p).Magnitude > 0.01 and (q - p).Unit or frem
		if i < antall then
			del({ Name = "Broplanke", Size = Vector3.new(BREDDE, 0.5, 2.1),
				CFrame = CFrame.lookAt(p, p + retning) * CFrame.new(0, -0.25, -1.1),
				Material = Enum.Material.WoodPlanks,
				Color = i % 2 == 0 and Color3.fromRGB(160, 112, 66) or Color3.fromRGB(138, 94, 54) })
		end
		for _, side in { -1, 1 } do
			local topp = p + hoyre * side * (BREDDE / 2 + 0.2) + Vector3.new(0, 3, 0)
			if forrige[side] then
				local m = (forrige[side] + topp) / 2
				del({ Name = "Brotau", Size = Vector3.new(0.3, 0.3, (topp - forrige[side]).Magnitude), CFrame = CFrame.lookAt(m, topp),
					CanCollide = false, Material = Enum.Material.Fabric, Color = farge or Color3.fromRGB(70, 52, 36) })
			end
			if i % 4 == 0 then
				del({ Name = "Brostolpe", Size = Vector3.new(0.4, 3, 0.4), CFrame = CFrame.new(topp - Vector3.new(0, 1.5, 0)),
					CanCollide = false, Material = Enum.Material.Wood, Color = Color3.fromRGB(96, 68, 42) })
			end
			forrige[side] = topp
		end
	end
end

-- ---------------------------------------------------------------- skyer (blokk-skyer)

local function sky(senter, storrelse, rng, forelder)
	for _ = 1, rng:NextInteger(3, 6) do
		local s = Vector3.new(rng:NextNumber(0.6, 1.2), rng:NextNumber(0.25, 0.45), rng:NextNumber(0.6, 1.2)) * storrelse
		del({ Name = "Sky", Size = s, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false,
			Color = Color3.fromRGB(255, 255, 255), Transparency = 0.05,
			CFrame = CFrame.new(senter + Vector3.new(rng:NextNumber(-0.6, 0.6) * storrelse, rng:NextNumber(-0.15, 0.15) * storrelse,
				rng:NextNumber(-0.6, 0.6) * storrelse)) }, forelder)
	end
end

local function skyer()
	local m = Instance.new("Folder")
	m.Name = "Skyer"
	m.Parent = mappe
	local rng = Random.new(77)
	for _ = 1, 60 do
		local a, r = rng:NextNumber(0, math.pi * 2), rng:NextNumber(0, 420)
		sky(Vector3.new(math.cos(a) * r, rng:NextNumber(-25, -8), math.sin(a) * r), rng:NextNumber(30, 60), rng, m)
	end
	for _ = 1, 16 do
		local a, r = rng:NextNumber(0, math.pi * 2), rng:NextNumber(120, 380)
		sky(Vector3.new(math.cos(a) * r, rng:NextNumber(130, 210), math.sin(a) * r), rng:NextNumber(18, 34), rng, m)
	end
end

-- ---------------------------------------------------------------- pynt

local function settNed(navn, cf, skala, kollisjon, forelder)
	local p = Modeller.plasser(navn, cf, skala, forelder or mappe)
	if p then
		p.CanCollide = kollisjon
		p.CanQuery = true
	end
	return p
end
Verden.settNed = settNed

local function pynt()
	local rng = Random.new(2027)
	local R = Kart.REIR
	-- Reiret: palmer og busker utenfor båndet
	for n = 1, 10 do
		local a = n / 10 * math.pi * 2 + 0.2
		local r = rng:NextNumber(38, 42)
		local pos = Vector3.new(R.x + math.cos(a) * r, R.topp, R.z + math.sin(a) * r)
		-- ikke der broene kommer inn
		local fri = true
		for i = 1, Kart.ANTALL_BASER do
			local _, til = Kart.bro(i)
			if (Vector3.new(til.X, 0, til.Z) - Vector3.new(pos.X, 0, pos.Z)).Magnitude < 10 then
				fri = false
			end
		end
		if fri then
			local navn = n % 3 == 0 and "Busk" or (n % 2 == 0 and "PalmeBoy" or "Palme")
			settNed(navn, CFrame.new(pos) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0), rng:NextNumber(0.9, 1.2),
				navn ~= "Busk")
		end
	end
	-- svevesteinene får en busk eller blomster
	for i, s in Kart.STEINER do
		local navn = i % 3 == 0 and "Blomster" or (i % 3 == 1 and "Busk" or "Steinblokk")
		settNed(navn, CFrame.new(s.x, s.topp, s.z) * CFrame.Angles(0, i, 0), 1, navn == "Steinblokk")
	end
end

-- ---------------------------------------------------------------- alt

function Verden.bygg(modeller)
	Modeller = modeller
	mappe = Instance.new("Folder")
	mappe.Name = "Verden"
	mappe.Parent = workspace
	Verden.mappe = mappe
	Verden.lys()
	local start = os.clock()
	reiret()
	task.wait()
	for i, b in Kart.BASER do
		local m = Instance.new("Model")
		m.Name = "BaseOy" .. i
		m.Parent = mappe
		Verden.oy(b, m, Verden.BASEFARGER[i])
		task.wait()
	end
	local steiner = Instance.new("Model")
	steiner.Name = "Svevesteiner"
	steiner.Parent = mappe
	for _, s in Kart.STEINER do
		Verden.oy(s, steiner)
	end
	skyer()
	pynt()
	print(string.format("[STEAL A BIRD] Verden bygget på %.1f s (%d deler)", os.clock() - start, #mappe:GetDescendants()))
end

return Verden
