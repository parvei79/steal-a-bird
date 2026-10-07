-- Setter sammen fugler og egg av delene fra Blender:
--   Rot     usynlig og forankret, på bakken under fuglen (origo). Flyttes når fuglen bæres eller flyttes.
--   Kropp   hengt i Rot med Motor6D «Kropp», så klienten kan la fuglen vippe og hoppe (Transform).
--   VingeH/VingeV  hengt i kroppen med Motor6D «VingeH»/«VingeV» i skuldrene, så de kan flakse.
--   Ekstra  (noen fugler) planetring o.l., Motor6D «Ekstra», roterer på klienten.
-- Mangler modellene, lages en enkel kloss-fugl, så spillet virker før import.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Fugler = require(Shared:WaitForChild("Fugler"))

local Fuglemodell = {}
local Modeller

function Fuglemodell.init(m)
	Modeller = m
end

local function delEgenskaper(p)
	p.Anchored = false
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
end

local function lagRot(cf)
	local r = Instance.new("Part")
	r.Name = "Rot"
	r.Size = Vector3.new(1, 0.2, 1)
	r.Transparency = 1
	r.Anchored = true
	r.CanCollide = false
	r.CanQuery = false
	r.CanTouch = false
	r.Massless = true
	r.CFrame = cf
	return r
end

local function motor(navn, p0, p1, ledd)
	local m = Instance.new("Motor6D")
	m.Name = navn
	m.Part0 = p0
	m.Part1 = p1
	m.C0 = p0.CFrame:Inverse() * ledd
	m.C1 = p1.CFrame:Inverse() * ledd
	m.Parent = p1
	return m
end

local function klossDel(navn, str, farge, form)
	local p = Instance.new("Part")
	p.Name = navn
	p.Size = str
	p.Color = farge
	p.Material = Enum.Material.SmoothPlastic
	if form then
		p.Shape = form
	end
	return p
end

-- Gi en del mutasjonens utseende (tar bort teksturen så fargen synes).
local function mutasjonsUtseende(del, mut)
	local m = Fugler.MUT[mut]
	if not m then
		return
	end
	for _, b in del:GetChildren() do
		if b:IsA("SurfaceAppearance") then
			b:Destroy()
		end
	end
	if del:IsA("MeshPart") then
		pcall(function()
			del.TextureID = ""
		end)
	end
	del.Color = m.farge
	if mut == "Gold" then
		del.Material = Enum.Material.Foil
		del.Reflectance = 0.25
	elseif mut == "Diamond" then
		del.Material = Enum.Material.Glass
		del.Transparency = 0.12
		del.Reflectance = 0.35
	elseif mut == "Rainbow" then
		del.Material = Enum.Material.SmoothPlastic
	elseif mut == "Galaxy" then
		del.Material = Enum.Material.ForceField
	end
end

-- Lag en fugl med origo (bakken under den) i `cf`. Returnerer Model.
function Fuglemodell.fugl(art, mut, cf, skala)
	skala = skala or 1
	local a = Fugler.ART[art]
	local modell = Instance.new("Model")
	modell.Name = "Fugl"
	local rot = lagRot(cf)
	rot.Parent = modell
	local navn = a and a.modell or art
	local kropp = Modeller and Modeller.hent(navn, skala)
	local vingeH, vingeV, ekstra
	if kropp then
		kropp.Name = "Kropp"
		kropp.CFrame = cf * CFrame.new(Modeller.info(navn).midt * skala)
		vingeH = Modeller.hent(navn .. "_VingeH", skala)
		vingeV = Modeller.hent(navn .. "_VingeV", skala)
		ekstra = Modeller.hent(navn .. "_Ekstra", skala)
		for _, par in { { vingeH, "_VingeH" }, { vingeV, "_VingeV" }, { ekstra, "_Ekstra" } } do
			if par[1] then
				par[1].CFrame = cf * CFrame.new(Modeller.info(navn .. par[2]).midt * skala)
			end
		end
	else
		-- reserve: kloss-fugl i sjeldenhetsfargen
		local sj = a and Fugler.SJ[a.sj]
		local farge = sj and sj.farge or Color3.fromRGB(220, 220, 220)
		kropp = klossDel("Kropp", Vector3.new(2.2, 2.2, 2.6) * skala, farge, Enum.PartType.Ball)
		kropp.CFrame = cf * CFrame.new(0, 2.0 * skala, 0)
		local hode = klossDel("Hode", Vector3.new(1.4, 1.4, 1.4) * skala, farge, Enum.PartType.Ball)
		hode.CFrame = cf * CFrame.new(0, 3.3 * skala, -0.7 * skala)
		local nebb = klossDel("Nebb", Vector3.new(0.4, 0.4, 0.9) * skala, Color3.fromRGB(255, 170, 40))
		nebb.CFrame = cf * CFrame.new(0, 3.2 * skala, -1.6 * skala)
		for _, p in { hode, nebb } do
			delEgenskaper(p)
			local w = Instance.new("WeldConstraint")
			w.Part0 = kropp
			w.Part1 = p
			w.Parent = p
			p.Parent = modell
		end
		vingeH = klossDel("VingeH", Vector3.new(0.3, 1.2, 1.8) * skala, farge)
		vingeH.CFrame = cf * CFrame.new(1.2 * skala, 1.9 * skala, 0.2 * skala)
		vingeV = klossDel("VingeV", Vector3.new(0.3, 1.2, 1.8) * skala, farge)
		vingeV.CFrame = cf * CFrame.new(-1.2 * skala, 1.9 * skala, 0.2 * skala)
	end
	delEgenskaper(kropp)
	kropp.Parent = modell
	motor("Kropp", rot, kropp, cf)
	local hengselH = Modeller and Modeller.punkt(navn, "hengselH", skala) or Vector3.new(1.1, 2.4, 0) * skala
	local hengselV = Modeller and Modeller.punkt(navn, "hengselV", skala) or Vector3.new(-1.1, 2.4, 0) * skala
	if vingeH then
		vingeH.Name = "VingeH"
		delEgenskaper(vingeH)
		vingeH.Parent = modell
		motor("VingeH", kropp, vingeH, cf * CFrame.new(hengselH))
	end
	if vingeV then
		vingeV.Name = "VingeV"
		delEgenskaper(vingeV)
		vingeV.Parent = modell
		motor("VingeV", kropp, vingeV, cf * CFrame.new(hengselV))
	end
	if ekstra then
		ekstra.Name = "Ekstra"
		delEgenskaper(ekstra)
		ekstra.Parent = modell
		local p = Modeller.punkt(navn, "ekstra", skala) or Vector3.zero
		motor("Ekstra", kropp, ekstra, cf * CFrame.new(p))
	end
	if mut then
		for _, d in { kropp, vingeH, vingeV } do
			if d then
				mutasjonsUtseende(d, mut)
			end
		end
	end
	local topp = Modeller and Modeller.punkt(navn, "topp", skala)
	modell:SetAttribute("Topp", topp and topp.Y or 4 * skala)
	modell.PrimaryPart = rot
	CollectionService:AddTag(modell, "Fugl")
	return modell
end

-- Lag et egg (sjeldenhet sj, eller «Golden») med origo i `cf`.
function Fuglemodell.egg(sj, cf, skala)
	skala = skala or 1
	local modell = Instance.new("Model")
	modell.Name = "Egg"
	local rot = lagRot(cf)
	rot.Parent = modell
	local navn = "Egg" .. sj
	local kropp = Modeller and Modeller.hent(navn, skala)
	if kropp then
		kropp.CFrame = cf * CFrame.new(Modeller.info(navn).midt * skala)
	else
		local s = Fugler.SJ[sj]
		kropp = klossDel("Kropp", Vector3.new(1.8, 2.4, 1.8) * skala, s and s.farge or Color3.fromRGB(255, 210, 60),
			Enum.PartType.Ball)
		kropp.CFrame = cf * CFrame.new(0, 1.2 * skala, 0)
	end
	kropp.Name = "Kropp"
	delEgenskaper(kropp)
	kropp.Parent = modell
	motor("Kropp", rot, kropp, cf)
	modell:SetAttribute("Topp", 2.5 * skala)
	modell.PrimaryPart = rot
	CollectionService:AddTag(modell, "Egg")
	return modell
end

-- Navneskilt over fuglen/egget. linjer = { { tekst, farge }, ... } øverst først.
function Fuglemodell.merke(modell, linjer, hoyde, rekkevidde)
	local gammel = modell:FindFirstChild("Merke")
	if gammel then
		gammel:Destroy()
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "Merke"
	gui.Size = UDim2.fromOffset(170, 22 * #linjer + 6)
	gui.StudsOffsetWorldSpace = Vector3.new(0, (hoyde or modell:GetAttribute("Topp") or 4) + 1.6, 0)
	gui.MaxDistance = rekkevidde or 55
	gui.LightInfluence = 0
	gui.Adornee = modell:FindFirstChild("Rot")
	local liste = Instance.new("UIListLayout")
	liste.SortOrder = Enum.SortOrder.LayoutOrder
	liste.HorizontalAlignment = Enum.HorizontalAlignment.Center
	liste.Parent = gui
	for i, l in linjer do
		local t = Instance.new("TextLabel")
		t.Name = l[3] or ("Linje" .. i)
		t.LayoutOrder = i
		t.Size = UDim2.new(1, 0, 0, i == 1 and 24 or 20)
		t.BackgroundTransparency = 1
		t.Font = Enum.Font.FredokaOne
		t.TextScaled = true
		t.Text = l[1]
		t.TextColor3 = l[2] or Color3.new(1, 1, 1)
		t.TextStrokeTransparency = 0.15
		t.Parent = gui
	end
	gui.Parent = modell
	return gui
end

return Fuglemodell
