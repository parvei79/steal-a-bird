-- Sesonger. I oktober (og første uka i november) er det Halloween:
--   * Spooky Eggs dukker opp på eggebåndet og klekker Halloween-fugler (bare i sesongen!)
--   * gresskar med lysende ansikt rundt på Reiret og i basene, og flaggermus som flyr i ring over Reiret
-- Config.SESONG = "auto" (etter datoen), "Halloween" (tving) eller nil (av).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Fugler = require(Shared:WaitForChild("Fugler"))
local Kart = require(Shared:WaitForChild("Kart"))

local Sesong = {}

function Sesong.aktiv(dato)
	local s = Config.SESONG
	if s ~= "auto" then
		return s
	end
	local d = dato or os.date("!*t")
	if d.month == 10 or (d.month == 11 and d.day <= 7) then
		return "Halloween"
	end
	return nil
end

local function gresskar(Modeller, Verden, cf, skala, forelder)
	local g = Modeller.plasser("Gresskar", cf, skala, forelder)
	local lysPunkt
	if g then
		g.CanCollide = true
		local p = Modeller.punkt("Gresskar", "lys", skala)
		lysPunkt = p and (cf * p) or g.Position
	else
		g = Verden.del({ Name = "Gresskar", Shape = Enum.PartType.Ball, Size = Vector3.new(3, 2.4, 3) * skala,
			CFrame = cf * CFrame.new(0, 1.2 * skala, 0), Color = Color3.fromRGB(255, 130, 20) }, forelder)
		lysPunkt = g.Position
	end
	local a = Instance.new("Attachment")
	a.Name = "Lys"
	a.WorldPosition = lysPunkt
	a.Parent = g
	local l = Instance.new("PointLight")
	l.Color = Color3.fromRGB(255, 150, 40)
	l.Range = 14
	l.Brightness = 1.6
	l.Parent = a
	return g
end

function Sesong.init(Modeller, Verden, Reiret)
	local s = Sesong.aktiv()
	workspace:SetAttribute("Sesong", s)
	if s ~= "Halloween" then
		return
	end
	-- Spooky Eggs på båndet (bare hvis noen Halloween-fugler er laget)
	if Fugler.trekkSesong(Random.new(1), "Halloween", Reiret.tillat) then
		Reiret.spooky = Config.SPOOKY_SJANSE
	end
	-- skumring: oransje-lilla himmel, lilla tåke, mørkere skygger (hendelsene tar vare på dette og setter det tilbake)
	local Lighting = game:GetService("Lighting")
	Lighting.ClockTime = 18.3
	Lighting.Brightness = 1.7
	Lighting.Ambient = Color3.fromRGB(80, 60, 100)
	Lighting.OutdoorAmbient = Color3.fromRGB(120, 90, 140)
	local atm = Lighting:FindFirstChildOfClass("Atmosphere")
	if atm then
		atm.Color = Color3.fromRGB(150, 95, 170)
		atm.Decay = Color3.fromRGB(90, 40, 110)
		atm.Density = 0.38
		atm.Haze = 1.6
	end
	local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
	if cc then
		cc.TintColor = Color3.fromRGB(255, 220, 235)
		cc.Saturation = 0.1
		cc.Contrast = 0.15
	end
	local skyer = workspace.Terrain:FindFirstChildOfClass("Clouds")
	if skyer then
		skyer.Color = Color3.fromRGB(120, 100, 140)
	end
	local mappe = Instance.new("Folder")
	mappe.Name = "Halloween"
	mappe.Parent = Verden.mappe
	local rng = Random.new(31)
	local R = Kart.REIR
	-- gresskar rundt kanten av Reiret
	for n = 1, 12 do
		local a = (n + 0.5) / 12 * math.pi * 2
		local r = rng:NextNumber(36, 43)
		local x, z = R.x + math.cos(a) * r, R.z + math.sin(a) * r
		local topp = Kart.toppHoyde(x, z)
		if topp then
			local cf = CFrame.lookAt(Vector3.new(x, topp, z), Vector3.new(R.x, topp, R.z))
			gresskar(Modeller, Verden, cf, rng:NextNumber(0.9, 1.4), mappe)
		end
	end
	-- to gresskar ved skiltet i hver base
	for i = 1, Kart.ANTALL_BASER do
		for _, side in { -1, 1 } do
			gresskar(Modeller, Verden, Kart.baseCF(i) * CFrame.new(side * 7, 0, 24), 1.1, mappe)
		end
	end
	-- gresskar på svevesteinene
	for _, st in Kart.STEINER do
		gresskar(Modeller, Verden, CFrame.new(st.x + 1.5, st.topp, st.z) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0),
			rng:NextNumber(0.8, 1.2), mappe)
	end
	-- flaggermus som flyr i ring over Reiret (klienten flytter dem)
	for n = 1, 18 do
		local senter = Vector3.new(R.x, R.topp + rng:NextNumber(20, 40), R.z)
		local radius = rng:NextNumber(14, 40)
		local f = Modeller.plasser("Flaggermus", CFrame.new(senter + Vector3.new(radius, 0, 0)), rng:NextNumber(1, 1.6), mappe)
		if not f then
			f = Verden.del({ Name = "Flaggermus", Size = Vector3.new(2, 0.4, 0.8), CFrame = CFrame.new(senter),
				Color = Color3.fromRGB(40, 30, 50), CanCollide = false }, mappe)
		end
		f.CanCollide = false
		f.CanQuery = false
		f:SetAttribute("Senter", senter)
		f:SetAttribute("Radius", radius)
		f:SetAttribute("Fart", rng:NextNumber(0.25, 0.6) * (rng:NextNumber() < 0.5 and -1 or 1))
		f:SetAttribute("Fase", rng:NextNumber(0, math.pi * 2))
		CollectionService:AddTag(f, "Flaggermus")
	end
end

return Sesong
