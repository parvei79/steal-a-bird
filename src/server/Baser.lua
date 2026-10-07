-- De 8 basene: hvem som eier hvilken, sokler, låseknappen (skjold), pengeplaten (hent pengene),
-- skiltet med navnet, nybegynnerskjoldet, og at andre blir dyttet ut når basen er låst.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Kart = require(Shared:WaitForChild("Kart"))
local Fugler = require(Shared:WaitForChild("Fugler"))

local Baser = {}

local Modeller, Fjern, Spillere, Verden
local eiere = {}       -- [i] = Player
local baseTil = {}     -- [Player] = i
local laastTil = {}    -- [i] = servertid
local skjoldTil = {}   -- [i] = servertid (nybegynnerskjold)
local pott = {}        -- [i] = penger som ligger på pengeplaten
local sistDytt = {}    -- [Player] = tid
local deler = {}       -- [i] = { modell, sokler = {}, skiltTekst, kuppel, laasTekst, pottTekst }
Baser.vedSamling = nil -- funksjon(spiller, belop) for effekter (settes av Main)

local function naa()
	return workspace:GetServerTimeNow()
end

function Baser.eier(i)
	return eiere[i]
end

function Baser.til(spiller)
	return baseTil[spiller]
end

function Baser.laast(i)
	return (laastTil[i] or 0) > naa()
end

function Baser.skjermet(i)
	return (skjoldTil[i] or 0) > naa()
end

-- Hvor mange sokler eieren har låst opp.
function Baser.sokler(i)
	local e = eiere[i]
	if not e then
		return 0
	end
	return Spillere.verdi(e, "sokler")
end

function Baser.pott(i)
	return pott[i] or 0
end

function Baser.leggIPott(i, n)
	pott[i] = (pott[i] or 0) + n
end

function Baser.modell(i)
	return deler[i] and deler[i].modell
end

-- ---------------------------------------------------------------- bygging (én gang)

local function tekstGui(del, side, tekst, farge)
	local gui = Instance.new("SurfaceGui")
	gui.Face = side
	gui.LightInfluence = 0
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.FredokaOne
	t.TextScaled = true
	t.Text = tekst
	t.TextColor3 = farge or Color3.new(1, 1, 1)
	t.TextStrokeTransparency = 0.3
	t.Parent = gui
	gui.Parent = del
	return t
end

local function billboard(del, tekst, hoyde, farge, str)
	local gui = Instance.new("BillboardGui")
	gui.Size = str or UDim2.fromOffset(200, 40)
	gui.StudsOffset = Vector3.new(0, hoyde, 0)
	gui.MaxDistance = 120
	gui.LightInfluence = 0
	gui.Adornee = del
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.FredokaOne
	t.TextScaled = true
	t.Text = tekst
	t.TextColor3 = farge or Color3.new(1, 1, 1)
	t.TextStrokeTransparency = 0.1
	t.Parent = gui
	gui.Parent = del
	return t, gui
end

local function byggBase(i)
	local farge = Verden.BASEFARGER[i]
	local m = Instance.new("Model")
	m.Name = "Base" .. i
	m:SetAttribute("Nr", i)
	m.Parent = Verden.mappe
	local d = { modell = m, sokler = {} }
	deler[i] = d
	-- sokler
	for n = 1, Config.BASE.SOKLER_MAKS do
		local cf = Kart.sokkel(i, n)
		local s = Modeller.plasser("Sokkel", cf, 1, m)
		if not s then
			s = Verden.del({ Name = "Sokkel", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.4, 3.6, 3.6),
				CFrame = cf * CFrame.new(0, 0.7, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(150, 150, 160) }, m)
		end
		s.Name = "Sokkel" .. n
		s.CanCollide = true
		s:SetAttribute("Nr", n)
		d.sokler[n] = s
	end
	-- låseknapp
	local laas = Modeller.plasser("LaaseKnapp", Kart.laas(i), 1, m)
	if not laas then
		laas = Verden.del({ Name = "LaaseKnapp", Size = Vector3.new(2.4, 3, 2.4), CFrame = Kart.laas(i) * CFrame.new(0, 1.5, 0),
			Color = Color3.fromRGB(255, 60, 60) }, m)
	end
	laas.Name = "LaaseKnapp"
	laas.CanCollide = true
	laas:SetAttribute("Base", i)
	d.laas = laas
	d.laasTekst = billboard(laas, "LOCK", 3.4, Color3.fromRGB(255, 90, 90))
	-- pengeplate
	local plate = Modeller.plasser("PengePlate", Kart.pengeplate(i), 1, m)
	if not plate then
		plate = Verden.del({ Name = "PengePlate", Size = Vector3.new(6, 0.6, 6), CFrame = Kart.pengeplate(i) * CFrame.new(0, 0.3, 0),
			Color = Color3.fromRGB(56, 193, 114) }, m)
	end
	plate.Name = "PengePlate"
	plate.CanCollide = true
	d.plate = plate
	d.pottTekst = billboard(plate, "$0", 3, Color3.fromRGB(120, 255, 140), UDim2.fromOffset(220, 46))
	-- skilt med navnet
	local skilt = Modeller.plasser("Skilt", Kart.skilt(i), 1.4, m)
	local tavleCf = Kart.skilt(i) * CFrame.new(0, 3.9 * 1.4, -0.35 * 1.4)
	if not skilt then
		Verden.del({ Name = "Skilt", Size = Vector3.new(9, 3.6, 0.6), CFrame = tavleCf * CFrame.new(0, 0, 0.35),
			Color = Color3.fromRGB(150, 105, 60) }, m)
	end
	local tavle = Verden.del({ Name = "Tavle", Size = Vector3.new(8.4, 3.2, 0.1), CFrame = tavleCf, Transparency = 1,
		CanCollide = false, CanQuery = false }, m)
	d.skiltTekst = tekstGui(tavle, Enum.NormalId.Front, "Empty Base", farge)
	-- flaggstang i basens farge
	local stang = Verden.del({ Name = "Flaggstang", Size = Vector3.new(0.6, 16, 0.6),
		CFrame = Kart.baseCF(i) * CFrame.new(-16, 8, 21), Color = Color3.fromRGB(230, 230, 235) }, m)
	Verden.del({ Name = "Flagg", Size = Vector3.new(5, 3.2, 0.3), CFrame = stang.CFrame * CFrame.new(2.8, 6, 0),
		Color = farge, CanCollide = false }, m)
	-- kuppelen (skjoldet) — usynlig til basen låses
	local kuppel = Verden.del({ Name = "Skjold", Shape = Enum.PartType.Ball, Size = Vector3.one * (Kart.BASE_R * 2 + 6),
		CFrame = Kart.baseCF(i) * CFrame.new(0, 2, 0), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false,
		CastShadow = false, Material = Enum.Material.ForceField, Color = farge }, m)
	d.kuppel = kuppel
	-- pynt bak i basen
	Verden.settNed("Palme", Kart.baseCF(i) * CFrame.new(18, 0, 18), 1.1, true, m)
	Verden.settNed("PalmeBoy", Kart.baseCF(i) * CFrame.new(-22, 0, 10) * CFrame.Angles(0, 2.5, 0), 1, true, m)
	Verden.settNed("Busk", Kart.baseCF(i) * CFrame.new(22, 0, -6), 1, false, m)
	Verden.settNed("Blomster", Kart.baseCF(i) * CFrame.new(-21, 0, -8), 1, false, m)
end

-- Vis hvilke sokler som er låst opp (låste er grå og halvgjennomsiktige).
function Baser.oppdaterSokler(i)
	local d = deler[i]
	if not d then
		return
	end
	local antall = Baser.sokler(i)
	for n, s in d.sokler do
		local aapen = eiere[i] ~= nil and n <= antall
		s.Transparency = aapen and 0 or 0.6
		s:SetAttribute("Aapen", aapen)
	end
end

local function oppdaterSkilt(i)
	local d = deler[i]
	local e = eiere[i]
	d.skiltTekst.Text = e and (e.DisplayName .. "'s Base") or "Empty Base"
	d.modell:SetAttribute("Eier", e and e.UserId or 0)
end

-- ---------------------------------------------------------------- eierskap

function Baser.tildel(spiller)
	if baseTil[spiller] then
		return baseTil[spiller]
	end
	for i = 1, Kart.ANTALL_BASER do
		if not eiere[i] then
			eiere[i] = spiller
			baseTil[spiller] = i
			pott[i] = 0
			laastTil[i] = 0
			skjoldTil[i] = naa() + Config.BASE.NYBEGYNNER
			spiller:SetAttribute("Base", i)
			oppdaterSkilt(i)
			Baser.oppdaterSokler(i)
			return i
		end
	end
	return nil
end

-- Spilleren går: pengene på platen går til spilleren, basen blir ledig.
function Baser.frigjor(spiller)
	local i = baseTil[spiller]
	if not i then
		return
	end
	if (pott[i] or 0) > 0 then
		Spillere.giPenger(spiller, pott[i])
	end
	eiere[i] = nil
	baseTil[spiller] = nil
	pott[i] = 0
	laastTil[i] = 0
	skjoldTil[i] = 0
	oppdaterSkilt(i)
	Baser.oppdaterSokler(i)
	deler[i].kuppel.Transparency = 1
end

-- ---------------------------------------------------------------- lås

function Baser.laas(spiller)
	local i = baseTil[spiller]
	if not i then
		return false, "You don't have a base"
	end
	local rot = spiller.Character and spiller.Character:FindFirstChild("HumanoidRootPart")
	if not rot or (rot.Position - deler[i].laas.Position).Magnitude > Config.BAER.TA_AVSTAND + 4 then
		return false, "Stand next to your LOCK button"
	end
	if Baser.laast(i) then
		return false, "Already locked!"
	end
	laastTil[i] = naa() + Spillere.verdi(spiller, "laas")
	deler[i].modell:SetAttribute("LaastTil", laastTil[i])
	Fjern.Hendelse:FireAllClients("laast", i, laastTil[i])
	Spillere.sendStatus(spiller)
	return true
end

-- ---------------------------------------------------------------- løkka

local function dyttUt(i)
	local b = Kart.BASER[i]
	local senter = Vector3.new(b.x, b.topp, b.z)
	for _, annen in Players:GetPlayers() do
		if annen ~= eiere[i] then
			local rot = annen.Character and annen.Character:FindFirstChild("HumanoidRootPart")
			if rot and Kart.iBase(i, rot.Position, 3) then
				local t = os.clock()
				if not sistDytt[annen] or t - sistDytt[annen] > 0.4 then
					sistDytt[annen] = t
					local ut = Vector3.new(rot.Position.X - senter.X, 0, rot.Position.Z - senter.Z)
					ut = ut.Magnitude > 0.1 and ut.Unit or Vector3.new(1, 0, 0)
					Fjern.Knuff:FireClient(annen, ut * 70 + Vector3.new(0, 35, 0), 0.3, false)
				end
			end
		end
	end
end

local function samle(i)
	local e = eiere[i]
	local rot = e and e.Character and e.Character:FindFirstChild("HumanoidRootPart")
	if not rot or (pott[i] or 0) < 1 then
		return
	end
	local p = deler[i].plate.Position
	local flat = Vector3.new(rot.Position.X - p.X, 0, rot.Position.Z - p.Z).Magnitude
	if flat <= Config.BASE.SAMLE_AVSTAND and math.abs(rot.Position.Y - p.Y) < 7 then
		local belop = math.floor(pott[i])
		pott[i] -= belop
		Spillere.giPenger(e, belop)
		Fjern.Hendelse:FireAllClients("samlet", e, belop, p)
		if Baser.vedSamling then
			Baser.vedSamling(e, belop)
		end
	end
end

local akk, akk2 = 0, 0
local function steg(dt)
	akk += dt
	akk2 += dt
	if akk >= 0.1 then
		akk = 0
		for i = 1, Kart.ANTALL_BASER do
			if eiere[i] then
				if Baser.laast(i) then
					dyttUt(i)
				end
				samle(i)
			end
		end
	end
	if akk2 >= 0.5 then
		akk2 = 0
		local t = naa()
		for i = 1, Kart.ANTALL_BASER do
			local d = deler[i]
			if eiere[i] then
				local laast = Baser.laast(i)
				d.kuppel.Transparency = laast and 0.55 or 1
				if laast then
					d.laasTekst.Text = string.format("🔒 %ds", math.ceil(laastTil[i] - t))
					d.laasTekst.TextColor3 = Color3.fromRGB(120, 220, 255)
				elseif Baser.skjermet(i) then
					d.laasTekst.Text = string.format("🛡️ NEW PLAYER %ds", math.ceil(skjoldTil[i] - t))
					d.laasTekst.TextColor3 = Color3.fromRGB(150, 255, 160)
				else
					d.laasTekst.Text = "LOCK"
					d.laasTekst.TextColor3 = Color3.fromRGB(255, 90, 90)
				end
				d.pottTekst.Text = "COLLECT " .. Fugler.penger(pott[i] or 0)
			else
				d.laasTekst.Text = ""
				d.pottTekst.Text = ""
			end
			d.modell:SetAttribute("LaastTil", laastTil[i] or 0)
			d.modell:SetAttribute("SkjoldTil", skjoldTil[i] or 0)
		end
	end
end

function Baser.init(modeller, remotes, spillere, verden)
	Modeller, Fjern, Spillere, Verden = modeller, remotes, spillere, verden
	for i = 1, Kart.ANTALL_BASER do
		byggBase(i)
		oppdaterSkilt(i)
		Baser.oppdaterSokler(i)
	end
	Spillere.ekstraStatus = function(spiller, st)
		local i = baseTil[spiller]
		st.base = i
		st.sokler = i and Baser.sokler(i) or 0
		st.laastTil = i and laastTil[i] or 0
		st.skjoldTil = i and skjoldTil[i] or 0
	end
	RunService.Heartbeat:Connect(steg)
end

return Baser
