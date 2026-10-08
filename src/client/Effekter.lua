-- Lyd og effekter for alt som skjer:
--   kroken       «thwip», klank når den biter seg fast, vinsj, vind etter fart, sus når du slipper
--   triks        sus, og salto/skru på figuren (Positurer)
--   landing      superhelt-landing: tungt dunk, støvsky, sjokkbølge og kamerarist
--   treff        «YOINK!» og «KICK!», slide-fløyte og svimmel kvitring for den som blir truffet
--   egg/fugler   kassaapparat når du kjøper, eggknekk og skallbiter når det klekker, lyssøyle i
--                sjeldenhetsfargen og konfetti for Epic og bedre, magisk klang når noe leveres hjemme
--   penger       mynter som flyr fra pengeplaten til deg og inn i pengetelleren
--   tyveri       rødt «THIEF!»-merke og rød omriss rundt tyven, «STOLEN!» og «SAVED!»
--   lås          skjoldlyd og en bølge som går over basen
--   fart         fartsstreker på skjermen
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Fugler = require(Shared:WaitForChild("Fugler"))
local Kart = require(Shared:WaitForChild("Kart"))
local UI = require(script.Parent:WaitForChild("UI"))

local Effekter = {}

local spiller = Players.LocalPlayer
local Grappler, Kamera, HUD, Positurer
local L = Config.LYD
local mappe

local function del(e)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.SmoothPlastic
	for k, v in e do
		p[k] = v
	end
	p.Parent = mappe
	return p
end

local function lyd(id, pos, volum, tonehoyde, rekkevidde)
	local p = del({ Transparency = 1, Size = Vector3.one, Position = pos })
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = volum or 0.7
	s.PlaybackSpeed = tonehoyde or 1
	s.RollOffMaxDistance = rekkevidde or 250
	s.RollOffMinDistance = 10
	s.Parent = p
	s:Play()
	Debris:AddItem(p, 8)
	return s
end
Effekter.lyd = lyd

local function lyd2D(id, volum, tonehoyde, varighet)
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = volum or 0.6
	s.PlaybackSpeed = tonehoyde or 1
	s.Parent = workspace.CurrentCamera
	s:Play()
	Debris:AddItem(s, varighet or 8)
	return s
end
Effekter.lyd2D = lyd2D

local function burst(pos, farge, antall, fart, storrelse, tekstur)
	local p = del({ Transparency = 1, Size = Vector3.one, Position = pos })
	local e = Instance.new("ParticleEmitter")
	e.Rate = 0
	e.Speed = NumberRange.new(fart * 0.5, fart)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Lifetime = NumberRange.new(0.3, 0.7)
	e.Drag = 4
	e.LightEmission = 0.5
	e.Size = NumberSequence.new(storrelse, 0)
	if typeof(farge) == "Color3" then
		e.Color = ColorSequence.new(farge)
	else
		e.Color = farge
	end
	if tekstur then
		e.Texture = tekstur
	end
	e.Parent = p
	e:Emit(antall)
	Debris:AddItem(p, 1.6)
end
Effekter.burst = burst

-- Tegneserietekst som spretter opp og forsvinner («YOINK!», «STOLEN!» ...)
local function smell(pos, tekst, farge, str)
	local p = del({ Transparency = 1, Size = Vector3.one, Position = pos + Vector3.new(0, 3, 0) })
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromScale(str or 8, (str or 8) * 0.34)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.Parent = p
	local t = UI.tekst({ Size = UDim2.fromScale(1, 1), Text = tekst, TextColor3 = farge, TextStrokeTransparency = 0,
		Rotation = math.random(-12, 12) }, gui)
	local skala = UI.ny("UIScale", { Scale = 0.2 }, t)
	TweenService:Create(skala, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	TweenService:Create(gui, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ StudsOffsetWorldSpace = Vector3.new(0, 2.5, 0) }):Play()
	task.delay(0.7, function()
		TweenService:Create(t, TweenInfo.new(0.3), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	end)
	Debris:AddItem(p, 1.1)
end
Effekter.smell = smell

-- Sjokkbølge: en flat ring som vokser og blir borte.
local function sjokkbolge(pos, storrelse, farge)
	local r = del({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 2, 2),
		CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Neon,
		Color = farge or Color3.fromRGB(255, 245, 220), Transparency = 0.35 })
	TweenService:Create(r, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = Vector3.new(0.15, storrelse, storrelse), Transparency = 1 }):Play()
	Debris:AddItem(r, 0.5)
end
Effekter.sjokkbolge = sjokkbolge

-- Lyssøyle i sjeldenhetsfargen (klekking).
local function lyssoyle(pos, farge, hoyde)
	local s = del({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(hoyde, 3, 3),
		CFrame = CFrame.new(pos + Vector3.new(0, hoyde / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Material = Enum.Material.Neon, Color = farge, Transparency = 0.25 })
	TweenService:Create(s, TweenInfo.new(1.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Size = Vector3.new(hoyde, 0.2, 0.2), Transparency = 1 }):Play()
	Debris:AddItem(s, 1.7)
end

local REGNBUE = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 80)), ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 220, 60)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80, 230, 110)), ColorSequenceKeypoint.new(0.75, Color3.fromRGB(80, 160, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 100, 255)),
})

local function konfetti(pos, antall)
	local p = del({ Transparency = 1, Size = Vector3.one, Position = pos })
	local e = Instance.new("ParticleEmitter")
	e.Rate = 0
	e.Speed = NumberRange.new(18, 32)
	e.SpreadAngle = Vector2.new(40, 40)
	e.EmissionDirection = Enum.NormalId.Top
	e.Acceleration = Vector3.new(0, -30, 0)
	e.Lifetime = NumberRange.new(1.2, 2)
	e.Drag = 1.5
	e.RotSpeed = NumberRange.new(-300, 300)
	e.Rotation = NumberRange.new(0, 360)
	e.Size = NumberSequence.new(0.45, 0.3)
	e.Color = REGNBUE
	e.Parent = p
	e:Emit(antall)
	Debris:AddItem(p, 2.5)
end

-- Skallbiter som spruter ut når egget klekkes (fysikk lokalt).
local function skallbiter(pos, farge)
	local mal = ReplicatedStorage:FindFirstChild("KlientModeller") and ReplicatedStorage.KlientModeller:FindFirstChild("Skallbit")
	for _ = 1, 7 do
		local b
		if mal then
			b = mal:Clone()
		else
			b = Instance.new("Part")
			b.Size = Vector3.new(0.6, 0.15, 0.6)
			b.Color = farge
		end
		b.Anchored = false
		b.CanCollide = true
		b.CanQuery = false
		b.CanTouch = false
		b.Massless = false
		b.CFrame = CFrame.new(pos + Vector3.new(0, 1.2, 0)) * CFrame.Angles(math.random() * 6, math.random() * 6, 0)
		b.Parent = mappe
		b.AssemblyLinearVelocity = Vector3.new(math.random(-14, 14), math.random(18, 30), math.random(-14, 14))
		b.AssemblyAngularVelocity = Vector3.new(math.random(-12, 12), math.random(-12, 12), math.random(-12, 12))
		task.delay(1.4, function()
			if b.Parent then
				TweenService:Create(b, TweenInfo.new(0.5), { Transparency = 1 }):Play()
			end
		end)
		Debris:AddItem(b, 2)
	end
end

-- Mynter som flyr fra pengeplaten til figuren din.
local function myntregn(fra, til, antall)
	local mal = ReplicatedStorage:FindFirstChild("KlientModeller") and ReplicatedStorage.KlientModeller:FindFirstChild("Mynt")
	for n = 1, antall do
		task.delay(n * 0.04, function()
			local m
			if mal then
				m = mal:Clone()
				m.Anchored = true
				m.CanCollide = false
			else
				m = Instance.new("Part")
				m.Shape = Enum.PartType.Cylinder
				m.Size = Vector3.new(0.3, 1.4, 1.4)
				m.Color = Color3.fromRGB(255, 205, 50)
				m.Material = Enum.Material.Neon
				m.Anchored = true
				m.CanCollide = false
			end
			m.CanQuery = false
			m.Parent = mappe
			local start = fra + Vector3.new(math.random(-2, 2), 1, math.random(-2, 2))
			local topp = (start + til) / 2 + Vector3.new(0, 6 + math.random() * 3, 0)
			local t0 = os.clock()
			local forb
			forb = RunService.RenderStepped:Connect(function()
				local k = math.clamp((os.clock() - t0) / 0.55, 0, 1)
				local mal2 = (spiller.Character and spiller.Character:FindFirstChild("HumanoidRootPart"))
				local slutt = mal2 and mal2.Position or til
				local a = start:Lerp(topp, k)
				local b = topp:Lerp(slutt, k)
				m.CFrame = CFrame.new(a:Lerp(b, k)) * CFrame.Angles(0, k * 12, 0)
				if k >= 1 then
					forb:Disconnect()
					m:Destroy()
				end
			end)
		end)
	end
end

-- Mynter som flyr over skjermen og inn i pengetelleren (fra et punkt i verden).
local function skjermMynter(fra, antall)
	local kam = workspace.CurrentCamera
	local sp = kam:WorldToViewportPoint(fra)
	local start = Vector2.new(sp.X, sp.Y)
	if sp.Z < 0 then
		start = kam.ViewportSize / 2
	end
	local maal = HUD.pengePos and HUD.pengePos()
	if not maal then
		return
	end
	for n = 1, antall do
		task.delay(n * 0.05, function()
			local m = UI.tekst({ AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(34, 34), Text = "🪙",
				Position = UDim2.fromOffset(start.X + math.random(-40, 40), start.Y + math.random(-30, 30)) }, HUD.skjerm)
			local tw = TweenService:Create(m, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{ Position = UDim2.fromOffset(maal.X, maal.Y), Size = UDim2.fromOffset(20, 20) })
			tw:Play()
			task.delay(0.55, function()
				m:Destroy()
				HUD.pengerSprett()
			end)
		end)
	end
end

-- Et lysende spor som flyr fra der en ting ble mistet og hjem til sokkelen.
local function hjemflukt(fra, til, farge)
	if not fra or not til then
		return
	end
	local kule = del({ Shape = Enum.PartType.Ball, Size = Vector3.one * 1.6, Position = fra, Material = Enum.Material.Neon,
		Color = farge or Color3.fromRGB(255, 240, 150) })
	local a0 = Instance.new("Attachment", kule)
	a0.Position = Vector3.new(0, 0.6, 0)
	local a1 = Instance.new("Attachment", kule)
	a1.Position = Vector3.new(0, -0.6, 0)
	local tr = Instance.new("Trail")
	tr.Attachment0, tr.Attachment1 = a0, a1
	tr.Lifetime = 0.4
	tr.LightEmission = 1
	tr.Color = ColorSequence.new(kule.Color)
	tr.Transparency = NumberSequence.new(0.2, 1)
	tr.Parent = kule
	local topp = (fra + til) / 2 + Vector3.new(0, 20, 0)
	local t0 = os.clock()
	local forb
	forb = RunService.RenderStepped:Connect(function()
		local k = math.clamp((os.clock() - t0) / 0.8, 0, 1)
		local a = fra:Lerp(topp, k)
		local b = topp:Lerp(til, k)
		kule.Position = a:Lerp(b, k)
		if k >= 1 then
			forb:Disconnect()
			burst(til, kule.Color, 14, 14, 0.6)
			kule:Destroy()
		end
	end)
end

local function finnTing(id)
	for _, m in workspace:WaitForChild("Ting"):GetChildren() do
		if m:GetAttribute("Id") == id then
			return m
		end
	end
	return nil
end

local function erMeg(p)
	return p == spiller
end

-- ---------------------------------------------------------------- din egen krok og figur

function Effekter.egen(liste)
	local figur = Grappler.figur()
	local rot = figur and figur:FindFirstChild("HumanoidRootPart")
	for _, h in liste do
		local navn = h[1]
		if navn == "skudd" then
			lyd2D(L.skudd, 0.7, 0.95 + math.random() * 0.15)
		elseif navn == "fest" then
			local pos, delen = h[2], h[3]
			local stein = delen and delen:IsA("BasePart") and delen.Material ~= Enum.Material.Grass
			lyd(stein and L.festStein or L.fest, pos, 0.8, 0.9 + math.random() * 0.2)
			burst(pos, Color3.fromRGB(255, 220, 140), 10, 22, 0.5)
			burst(pos, Color3.fromRGB(170, 160, 150), 8, 10, 1.2)
			Kamera.rist(0.15)
		elseif navn == "rykk" then
			lyd2D(L.tausvisj, 0.7, 1.1)
		elseif navn == "slipp" then
			lyd2D(L.slipp, 0.45, 0.9 + math.random() * 0.2)
		elseif navn == "bom" then
			lyd2D(L.bom, 0.35, 1.3)
		elseif (navn == "triks" or navn == "salto") and figur then
			Positurer.triks(figur, h[2])
			lyd2D(L.triks, 0.6, 1.1 + math.random() * 0.2)
			if navn == "triks" and rot then
				smell(rot.Position, h[2] == "skru" and "SPIN!" or "FLIP!", Color3.fromRGB(120, 230, 255), 6)
			end
		elseif navn == "landing" and rot then
			local styrke = h[2] or 0
			if styrke > 0.42 then
				Positurer.landing(figur, styrke)
				Effekter.landing(rot.Position - Vector3.new(0, 2.8, 0), styrke, true)
			elseif styrke > 0.25 then
				lyd(L.landing, rot.Position, 0.5 + styrke * 0.5, 0.9)
				burst(rot.Position - Vector3.new(0, 2.5, 0), Color3.fromRGB(200, 190, 170), 10, 12, 1.2)
			end
		elseif navn == "spark" then
			Kamera.rist(0.5)
		elseif navn == "truffet" then
			Kamera.rist(0.9)
			if h[3] then
				lyd2D(L.floyte, 0.6, 1)
				task.delay(0.9, function()
					lyd2D(L.svimmel, 0.5, 1.15, 4)
				end)
			end
		end
	end
end

-- ---------------------------------------------------------------- storm og meteor

-- En lysende ring på bakken som varsler et nedslag (lyn eller meteor). Krymper mot tidspunktet.
local function varselRing(pos, treff, radius, farge)
	local ring = del({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, radius * 2, radius * 2),
		CFrame = CFrame.new(pos + Vector3.new(0, 0.25, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Neon,
		Color = farge, Transparency = 0.55 })
	local forb
	forb = RunService.RenderStepped:Connect(function()
		local igjen = treff - workspace:GetServerTimeNow()
		if igjen <= 0 or not ring.Parent then
			forb:Disconnect()
			ring:Destroy()
			return
		end
		ring.Transparency = 0.35 + 0.35 * math.abs(math.sin(os.clock() * (8 + 10 / math.max(igjen, 0.3))))
	end)
	return ring
end

-- Et lyn: sikksakk av lysende biter fra himmelen og ned, blits, smell og torden.
local blits
local function lynNedslag(pos)
	local topp = pos + Vector3.new(math.random(-8, 8), 160, math.random(-8, 8))
	local forrige = topp
	for n = 1, 8 do
		local t = n / 8
		local p = topp:Lerp(pos, t) + (n < 8 and Vector3.new(math.random(-5, 5), 0, math.random(-5, 5)) or Vector3.zero)
		local lengde = (p - forrige).Magnitude
		local d = del({ Size = Vector3.new(0.6, 0.6, lengde), CFrame = CFrame.lookAt((p + forrige) / 2, p),
			Material = Enum.Material.Neon, Color = Color3.fromRGB(220, 235, 255) })
		TweenService:Create(d, TweenInfo.new(0.35), { Transparency = 1 }):Play()
		Debris:AddItem(d, 0.4)
		forrige = p
	end
	burst(pos + Vector3.new(0, 1, 0), Color3.fromRGB(200, 230, 255), 26, 30, 0.8, "rbxasset://textures/particles/sparkles_main.dds")
	sjokkbolge(pos + Vector3.new(0, 0.3, 0), 22, Color3.fromRGB(200, 230, 255))
	lyd(L.lyn, pos, 1, 1, 400)
	task.delay(0.35, function()
		lyd2D(L.torden, 0.5, 0.9 + math.random() * 0.2, 6)
	end)
	if blits then
		blits.Brightness = 0.45
		TweenService:Create(blits, TweenInfo.new(0.25), { Brightness = 0 }):Play()
	end
	local rot = spiller.Character and spiller.Character:FindFirstChild("HumanoidRootPart")
	if rot and (rot.Position - pos).Magnitude < 40 then
		Kamera.rist(0.6)
	end
end

-- Meteoren: en ildkule som faller fra himmelen de siste sekundene før nedslaget.
local function meteorFall(maal, treff)
	local start = maal + Vector3.new(-120, 220, 80)
	local kule = del({ Shape = Enum.PartType.Ball, Size = Vector3.one * 6, Position = start, Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 120, 30) })
	local ild = Instance.new("Fire")
	ild.Size = 18
	ild.Heat = 25
	ild.Color = Color3.fromRGB(255, 120, 30)
	ild.SecondaryColor = Color3.fromRGB(255, 40, 10)
	ild.Parent = kule
	local a0 = Instance.new("Attachment", kule)
	a0.Position = Vector3.new(0, 2.5, 0)
	local a1 = Instance.new("Attachment", kule)
	a1.Position = Vector3.new(0, -2.5, 0)
	local tr = Instance.new("Trail")
	tr.Attachment0, tr.Attachment1 = a0, a1
	tr.Lifetime = 0.8
	tr.LightEmission = 1
	tr.Color = ColorSequence.new(Color3.fromRGB(255, 200, 80), Color3.fromRGB(255, 60, 20))
	tr.Transparency = NumberSequence.new(0.1, 1)
	tr.Parent = kule
	local fallTid = 3
	local forb
	forb = RunService.RenderStepped:Connect(function()
		local k = 1 - (treff - workspace:GetServerTimeNow()) / fallTid
		if k >= 1 or not kule.Parent then
			forb:Disconnect()
			kule:Destroy()
			return
		end
		kule.Position = start:Lerp(maal, math.clamp(k, 0, 1) ^ 1.6)
	end)
	lyd(L.ildkule, maal, 1, 0.9, 500)
end

local function meteorNedslag(pos)
	lyd(L.smell, pos, 1.3, 0.9, 600)
	lyd2D(L.torden, 0.4, 0.7, 6)
	burst(pos + Vector3.new(0, 2, 0), Color3.fromRGB(255, 140, 40), 40, 45, 2.2, "rbxasset://textures/particles/fire_main.dds")
	burst(pos + Vector3.new(0, 1, 0), Color3.fromRGB(120, 110, 100), 30, 30, 3)
	sjokkbolge(pos + Vector3.new(0, 0.3, 0), 50, Color3.fromRGB(255, 160, 60))
	local rot = spiller.Character and spiller.Character:FindFirstChild("HumanoidRootPart")
	if rot then
		local d = (rot.Position - pos).Magnitude
		Kamera.rist(math.clamp(1.4 - d / 120, 0.2, 1.4))
	end
end

-- Et gullegg har landet (Golden Egg Rain).
function Effekter.landetEgg(pos)
	burst(pos + Vector3.new(0, 1, 0), Color3.fromRGB(255, 215, 60), 20, 18, 0.7, "rbxasset://textures/particles/sparkles_main.dds")
	sjokkbolge(pos + Vector3.new(0, 0.3, 0), 10, Color3.fromRGB(255, 220, 90))
	lyd(L.tungLanding, pos, 0.5, 1.3)
end

-- Superhelt-landing: dunk, støv og sjokkbølge (for alle som ser det).
function Effekter.landing(pos, styrke, egen)
	lyd(L.tungLanding, pos, 0.6 + 0.5 * styrke, 0.85 + math.random() * 0.1)
	burst(pos, Color3.fromRGB(215, 200, 175), math.floor(16 + 18 * styrke), 18 + 10 * styrke, 1.8)
	sjokkbolge(pos + Vector3.new(0, 0.3, 0), 10 + 16 * styrke)
	if egen then
		Kamera.rist(0.35 + 0.5 * styrke)
	end
end

-- ---------------------------------------------------------------- hendelser fra serveren

local function serverHendelse(type_, a, b, c, d, e)
	if type_ == "rykk" then
		lyd(L.rykk, a, 1, 0.9 + math.random() * 0.2)
		burst(a, Color3.fromRGB(255, 240, 200), 14, 25, 0.6)
		smell(a, "YOINK!", Color3.fromRGB(255, 214, 10))
	elseif type_ == "spark" then
		lyd(L.spark, a, 1.1, 0.9 + math.random() * 0.2)
		burst(a, Color3.fromRGB(255, 200, 120), 22, 35, 0.8)
		smell(a, "KICK!", Color3.fromRGB(255, 90, 60))
	elseif type_ == "krok" and a ~= spiller then
		local rot = a and a.Character and a.Character:FindFirstChild("HumanoidRootPart")
		if b == "skyt" and rot then
			lyd(L.skudd, rot.Position, 0.6, 1)
		end
	elseif type_ == "triks" and a and a.Character then
		local rot = a.Character:FindFirstChild("HumanoidRootPart")
		if rot then
			lyd(L.triks, rot.Position, 0.5, 1.1)
		end
	elseif type_ == "landing" and a and a.Character then
		local rot = a.Character:FindFirstChild("HumanoidRootPart")
		if rot and (b or 0) > 0.42 then
			Effekter.landing(rot.Position - Vector3.new(0, 2.8, 0), b, false)
		end
	elseif type_ == "kjopt" then
		lyd(L.kjop, c, erMeg(a) and 1 or 0.5, 1)
		burst(c + Vector3.new(0, 1.5, 0), Color3.fromRGB(255, 220, 60), 16, 16, 0.6)
		if erMeg(a) then
			HUD.melding("You bought a " .. b .. " Egg! Bring it home! 🏠", Fugler.SJ[b].farge)
		end
	elseif type_ == "klekker" then
		local m = finnTing(a)
		if b then
			lyd(L.knekk, b, 0.9, 1)
			task.delay(0.8, function()
				lyd(L.knekk, b, 0.9, 1.15)
			end)
		end
		if m and m:GetAttribute("Eier") == spiller.UserId then
			HUD.melding("Your egg is hatching! 🥚", Color3.fromRGB(255, 240, 160))
		end
	elseif type_ == "klekket" then
		-- a = id, b = eier, c = art, d = mut, e = ny i samleboka
		local m = finnTing(a)
		local rot = m and m:FindFirstChild("Rot")
		local art = Fugler.ART[c]
		local sj = art and Fugler.SJ[art.sj]
		if rot and sj then
			local pos = rot.Position
			lyd(L.pop, pos, 1, 1)
			lyd(L.kvitring, pos, 0.6, 1 + math.random() * 0.2)
			skallbiter(pos, sj.farge)
			burst(pos + Vector3.new(0, 2, 0), sj.farge, 24, 18, 0.8, "rbxasset://textures/particles/sparkles_main.dds")
			lyssoyle(pos, sj.farge, 8 + sj.nr * 6)
			if sj.nr >= 4 or d then
				konfetti(pos + Vector3.new(0, 2, 0), 40 + sj.nr * 10)
				lyd(L.forvandling, pos, 0.8, 1)
			end
			smell(pos + Vector3.new(0, 2, 0), string.upper(art.sj) .. "!", sj.farge, 7 + sj.nr)
		end
		local navn = Fugler.fulltNavn(c, d)
		if erMeg(b) then
			HUD.banner("🐣 You hatched a " .. navn .. "!" .. (e and "  📖 NEW!" or ""), sj and sj.farge, 3.5)
			if sj and sj.nr >= 5 then
				lyd2D(L.jubel, 0.5, 1, 4)
			end
		elseif sj and (sj.nr >= 5 or d) and b then
			HUD.melding(string.format("%s hatched a %s %s!", b.DisplayName, string.upper(art.sj), navn), sj.farge, 6)
		end
	elseif type_ == "samlet" then
		-- a = spiller, b = beløp, c = pos
		if erMeg(a) then
			lyd2D(L.mynter, 0.8, 1)
			local rot = spiller.Character and spiller.Character:FindFirstChild("HumanoidRootPart")
			myntregn(c, rot and rot.Position or c, math.clamp(math.floor(math.log10(math.max(b, 1)) * 3), 4, 16))
			task.delay(0.5, skjermMynter, rot and rot.Position or c, 8)
			HUD.melding("+" .. Fugler.penger(b) .. " collected! 💰", Color3.fromRGB(120, 255, 140), 2.5)
		else
			burst(c + Vector3.new(0, 1, 0), Color3.fromRGB(255, 215, 60), 10, 12, 0.5)
		end
	elseif type_ == "solgt" then
		lyd(L.kjop, c, erMeg(a) and 0.9 or 0.4, 1.1)
		burst(c + Vector3.new(0, 2, 0), Color3.fromRGB(255, 220, 60), 18, 18, 0.6)
		if erMeg(a) then
			HUD.melding("Sold for " .. Fugler.penger(b) .. "! 💸", Color3.fromRGB(120, 255, 140), 3)
		end
	elseif type_ == "levert" then
		local m = finnTing(b)
		local rot = m and m:FindFirstChild("Rot")
		if rot then
			lyd(L.magi, rot.Position, 0.8, 1)
			burst(rot.Position + Vector3.new(0, 2, 0), Color3.fromRGB(255, 250, 200), 20, 14, 0.6,
				"rbxasset://textures/particles/sparkles_main.dds")
		end
	elseif type_ == "stjeler" then
		-- a = tyv, b = offer, c = navn
		if not erMeg(b) and not erMeg(a) then
			HUD.melding(string.format("🚨 %s is stealing %s's %s!", a.DisplayName, b.DisplayName, c), Color3.fromRGB(255, 140, 120))
		end
		if erMeg(a) then
			HUD.banner("😈 YOU GRABBED " .. string.upper(c) .. "! RUN HOME!", Color3.fromRGB(255, 200, 60), 2.5)
		end
	elseif type_ == "alarm" then
		lyd2D(L.alarm, 0.55, 1, 3.5)
	elseif type_ == "stjalet" then
		-- a = tyv, b = offer, c = navn
		local rot = a and a.Character and a.Character:FindFirstChild("HumanoidRootPart")
		if rot then
			smell(rot.Position + Vector3.new(0, 2, 0), "STOLEN!", Color3.fromRGB(255, 70, 70), 9)
		end
		if erMeg(a) then
			HUD.banner("💰 YOU STOLE " .. string.upper(c) .. "!", Color3.fromRGB(120, 255, 140), 3)
			lyd2D(L.jubel, 0.45, 1.1, 3)
		elseif erMeg(b) then
			HUD.banner("😭 " .. a.DisplayName .. " stole your " .. c .. "!", Color3.fromRGB(255, 90, 90), 3.5)
		else
			HUD.melding(string.format("%s stole %s from %s!", a.DisplayName, c, b and b.DisplayName or "?"), Color3.fromRGB(255, 170, 120))
		end
	elseif type_ == "reddet" then
		-- a = forsvarer, b = tyven, c = pos
		smell(c + Vector3.new(0, 2, 0), "SAVED!", Color3.fromRGB(90, 255, 140), 8)
		if erMeg(a) then
			HUD.banner("🛡️ YOU STOPPED " .. string.upper(b.DisplayName) .. "!", Color3.fromRGB(90, 255, 140), 2.5)
		end
	elseif type_ == "tilbake" then
		-- a = id, b = fra-posisjon
		local m = finnTing(a)
		local rot = m and m:FindFirstChild("Rot")
		if rot and b then
			hjemflukt(b, rot.Position + Vector3.new(0, 2, 0))
		end
	elseif type_ == "sluppet" then
		lyd(L.pop, b, 0.8, 0.8)
		smell(b, "DROPPED!", Color3.fromRGB(255, 220, 80), 6)
	elseif type_ == "snappet" then
		local rot = a and a.Character and a.Character:FindFirstChild("HumanoidRootPart")
		if rot then
			smell(rot.Position, "SNATCHED!", Color3.fromRGB(255, 170, 60), 7)
		end
		if b == spiller then
			HUD.melding(a.DisplayName .. " snatched your egg! Get it back! 😤", Color3.fromRGB(255, 140, 120))
		end
	elseif type_ == "laast" then
		local i = a
		local senter = Kart.lokal(i, 0, 0, 2)
		lyd(L.skjold, senter, 1, 1, 300)
		local kule = del({ Shape = Enum.PartType.Ball, Size = Vector3.one * 4, Position = senter,
			Material = Enum.Material.ForceField, Color = Color3.fromRGB(120, 220, 255), Transparency = 0.2 })
		TweenService:Create(kule, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = Vector3.one * (Kart.BASE_R * 2 + 8), Transparency = 0.9 }):Play()
		Debris:AddItem(kule, 0.9)
	elseif type_ == "sjeldentEgg" then
		local sj = Fugler.SJ[a]
		if a == "Spooky" then
			-- Spooky Eggs kommer ganske ofte i oktober: en liten melding, ikke et stort banner
			HUD.melding("🎃 A Spooky Egg is on the conveyor!", sj and sj.farge, 4)
			return
		end
		HUD.banner(string.format("✨ A %s EGG is on the conveyor! ✨", string.upper(tostring(a))), sj and sj.farge, 4)
		lyd2D(L.forvandling, 0.6, 0.9, 3)
	elseif type_ == "byttet" then
		HUD.melding(string.format("%s and %s traded birds! 🤝", a.DisplayName, b.DisplayName), Color3.fromRGB(255, 230, 140))
	elseif type_ == "oppgradert" then
		lyd2D(L.magi, 0.7, 1.2)
	elseif type_ == "hendelse" then
		-- a = navn, b = start (true) / slutt (false)
		if a == "GoldenRain" then
			if b then
				HUD.banner("🥚✨ GOLDEN EGG RAIN! Grab the golden eggs! ✨🥚", Color3.fromRGB(255, 215, 60), 5)
				lyd2D(L.forvandling, 0.8, 1.1, 3)
				lyd2D(L.jubel, 0.35, 1, 4)
			else
				HUD.melding("The Golden Egg Rain is over", Color3.fromRGB(255, 225, 140))
			end
		elseif a == "Storm" then
			if b then
				HUD.banner("⛈️ STORM! Watch out for lightning! Thunderbirds earn x3! ⛈️", Color3.fromRGB(190, 215, 255), 5)
				lyd2D(L.torden, 0.7, 0.8, 6)
			else
				HUD.melding("The storm is over 🌤️", Color3.fromRGB(200, 230, 255))
			end
		elseif a == "CosmicNight" then
			if b then
				HUD.banner("🌙✨ COSMIC NIGHT! Look for Secret eggs on the conveyor! ✨🌙", Color3.fromRGB(150, 230, 255), 5)
				lyd2D(L.forvandling, 0.8, 0.7, 3)
			else
				HUD.melding("The sun rises. Cosmic Night is over ☀️", Color3.fromRGB(200, 220, 255))
			end
		end
	elseif type_ == "lynVarsel" then
		varselRing(a, b, Config.HENDELSER.LYN_RADIUS, Color3.fromRGB(190, 225, 255))
	elseif type_ == "lynNedslag" then
		lynNedslag(a)
	elseif type_ == "meteorVarsel" then
		varselRing(a, b, Config.HENDELSER.METEOR_RADIUS, Color3.fromRGB(255, 90, 40))
		HUD.banner("☄️ METEOR INCOMING! Grab the Meteor Egg when it lands! ☄️", Color3.fromRGB(255, 140, 60), 4)
		lyd2D(L.forvandling, 0.6, 0.6, 3)
		task.delay(math.max(0, b - workspace:GetServerTimeNow() - 3), meteorFall, a, b)
	elseif type_ == "meteorNedslag" then
		meteorNedslag(a)
	elseif type_ == "rebirth" then
		-- a = spiller, b = antall rebirths
		local rot = a and a.Character and a.Character:FindFirstChild("HumanoidRootPart")
		if rot then
			konfetti(rot.Position, 80)
			lyssoyle(rot.Position - Vector3.new(0, 3, 0), Color3.fromRGB(255, 215, 60), 30)
			lyd(L.forvandling, rot.Position, 1, 0.8)
		end
		if erMeg(a) then
			HUD.banner(string.format("🌟 REBIRTH %d! Your birds now earn x%.1f! 🌟", b, 1 + Config.REBIRTH.BONUS * b),
				Color3.fromRGB(255, 215, 60), 5)
			lyd2D(L.jubel, 0.6, 1, 4)
		else
			HUD.melding(string.format("%s did REBIRTH %d! 🌟", a.DisplayName, b), Color3.fromRGB(255, 215, 60))
		end
	elseif type_ == "serverLuck" then
		HUD.banner("🍀 " .. a.DisplayName .. " bought SERVER LUCK! Rare eggs x2 for everyone! 🍀",
			Color3.fromRGB(120, 255, 140), 4)
		lyd2D(L.magi, 0.8, 1)
	end
end

-- ---------------------------------------------------------------- tyvemerket og fartsstrekene

local vipMerker = {} -- [figur] = BillboardGui
local function oppdaterVip()
	for _, p in Players:GetPlayers() do
		local f = p.Character
		if f and f:GetAttribute("VIP") and not vipMerker[f] then
			local hode = f:FindFirstChild("Head")
			if hode then
				local gui = UI.ny("BillboardGui", { Name = "VipMerke", Size = UDim2.fromOffset(120, 30),
					StudsOffset = Vector3.new(0, 3.4, 0), LightInfluence = 0, MaxDistance = 120, Adornee = hode }, hode)
				UI.tekst({ Size = UDim2.fromScale(1, 1), Text = "👑 VIP", TextColor3 = Color3.fromRGB(255, 215, 60),
					TextStrokeTransparency = 0 }, gui)
				vipMerker[f] = gui
			end
		end
	end
	for f, g in vipMerker do
		if not f.Parent or not f:GetAttribute("VIP") then
			g:Destroy()
			vipMerker[f] = nil
		end
	end
end

local merker = {} -- [figur] = { gui, highlight }
local function oppdaterTyver()
	for _, p in Players:GetPlayers() do
		local f = p.Character
		if f then
			local tyv = f:GetAttribute("Tyv") == true
			local m = merker[f]
			if tyv and not m then
				local hode = f:FindFirstChild("Head")
				if hode then
					local gui = UI.ny("BillboardGui", { Name = "TyvMerke", Size = UDim2.fromOffset(140, 40),
						StudsOffset = Vector3.new(0, 6.5, 0), AlwaysOnTop = true, LightInfluence = 0, Adornee = hode }, hode)
					UI.tekst({ Size = UDim2.fromScale(1, 1), Text = "🚨 THIEF!", TextColor3 = Color3.fromRGB(255, 60, 60),
						TextStrokeTransparency = 0 }, gui)
					local hl = UI.ny("Highlight", { FillTransparency = 1, OutlineColor = Color3.fromRGB(255, 50, 50),
						OutlineTransparency = 0, DepthMode = Enum.HighlightDepthMode.AlwaysOnTop }, f)
					merker[f] = { gui = gui, hl = hl }
				end
			elseif not tyv and m then
				m.gui:Destroy()
				m.hl:Destroy()
				merker[f] = nil
			end
		end
	end
	for f, m in merker do
		if not f.Parent then
			m.gui:Destroy()
			merker[f] = nil
		end
	end
end

local streker = {}
local strekGui
local function lagStreker()
	strekGui = UI.ny("ScreenGui", { Name = "Fartsstreker", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = -1 },
		spiller:WaitForChild("PlayerGui"))
	for n = 1, 26 do
		local f = UI.ny("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0, BackgroundTransparency = 1, Size = UDim2.fromOffset(3, 90) }, strekGui)
		streker[n] = { f = f, vinkel = math.random() * math.pi * 2, k = math.random(), fart = 1.5 + math.random() * 1.5 }
	end
end

local function oppdaterStreker(dt, fart)
	local styrke = math.clamp((fart - 80) / 80, 0, 1)
	local vp = workspace.CurrentCamera.ViewportSize
	for _, s in streker do
		s.k += dt * s.fart * (0.6 + styrke)
		if s.k > 1 then
			s.k = 0
			s.vinkel = math.random() * math.pi * 2
		end
		local r = (0.35 + 0.5 * s.k) * math.max(vp.X, vp.Y) * 0.6
		local x = vp.X / 2 + math.cos(s.vinkel) * r
		local y = vp.Y / 2 + math.sin(s.vinkel) * r
		s.f.Position = UDim2.fromOffset(x, y)
		s.f.Rotation = math.deg(s.vinkel) + 90
		s.f.Size = UDim2.fromOffset(2 + 2 * styrke, 40 + 120 * styrke)
		s.f.BackgroundTransparency = 1 - styrke * 0.55 * math.sin(s.k * math.pi)
	end
end

function Effekter.start(grappler, kamera, remotes, hud, positurer)
	Grappler, Kamera, HUD, Positurer = grappler, kamera, hud, positurer
	mappe = workspace:WaitForChild("KrokEffekter")
	remotes.Hendelse.OnClientEvent:Connect(serverHendelse)
	lagStreker()

	-- løkker: vinsj mens du henger, vind etter fart
	local vinsj = UI.ny("Sound", { SoundId = L.vinsj, Looped = true, Volume = 0 }, workspace.CurrentCamera)
	vinsj:Play()
	local vind = UI.ny("Sound", { SoundId = L.vind, Looped = true, Volume = 0 }, workspace.CurrentCamera)
	vind:Play()
	local bakgrunn = UI.ny("Sound", { SoundId = L.vindsus, Looped = true, Volume = 0.18 }, workspace.CurrentCamera)
	bakgrunn:Play()
	-- stormen: regn som følger kameraet, regnlyd og blits ved lynnedslag
	blits = UI.ny("ColorCorrectionEffect", { Name = "LynBlits", Brightness = 0 }, game:GetService("Lighting"))
	local regnSky = del({ Name = "RegnSky", Size = Vector3.new(140, 1, 140), Transparency = 1 })
	local regn = UI.ny("ParticleEmitter", { Enabled = false, Rate = 500, Lifetime = NumberRange.new(0.8, 1),
		Speed = NumberRange.new(90, 110), EmissionDirection = Enum.NormalId.Bottom, SpreadAngle = Vector2.new(3, 3),
		Size = NumberSequence.new(0.1), Squash = NumberSequence.new(4), LightEmission = 0.2,
		Transparency = NumberSequence.new(0.35), Color = ColorSequence.new(Color3.fromRGB(190, 210, 240)),
		Orientation = Enum.ParticleOrientation.VelocityParallel }, regnSky)
	local regnLyd = UI.ny("Sound", { SoundId = L.regn, Looped = true, Volume = 0 }, workspace.CurrentCamera)
	regnLyd:Play()

	local akk = 0
	RunService.RenderStepped:Connect(function(dt)
		local s = Grappler.tilstand()
		local figur = Grappler.figur()
		local rot = figur and figur:FindFirstChild("HumanoidRootPart")
		local fart = rot and rot.AssemblyLinearVelocity.Magnitude or 0
		local hekta = s.krok == "fest" and s.bevegelse == "hekta"
		vinsj.Volume += ((hekta and 0.35 or 0) - vinsj.Volume) * math.min(1, dt * 10)
		vinsj.PlaybackSpeed = 1 + math.clamp(fart / 200, 0, 0.6)
		local vindMal = math.clamp((fart - 30) / 150, 0, 1) * 0.8
		vind.Volume += (vindMal - vind.Volume) * math.min(1, dt * 4)
		vind.PlaybackSpeed = 0.8 + math.clamp(fart / 200, 0, 0.7)
		oppdaterStreker(dt, fart)
		local storm = workspace:GetAttribute("Hendelse") == "Storm"
		regn.Enabled = storm
		if storm then
			regnSky.Position = workspace.CurrentCamera.CFrame.Position + Vector3.new(0, 45, 0)
		end
		regnLyd.Volume += ((storm and 0.5 or 0) - regnLyd.Volume) * math.min(1, dt * 2)
		akk += dt
		if akk > 0.25 then
			akk = 0
			oppdaterTyver()
			oppdaterVip()
		end
	end)
end

return Effekter
