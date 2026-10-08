-- Liv i fuglene og eggene (bare på klienten, så serveren slipper å sende bevegelser):
--   fugler   vipper og puster, ser seg rundt, flakser innimellom, hopper med «+$» når de tjener penger,
--            flakser vilt når en tyv bærer dem, og spretter ut av egget med en snurr når de klekkes
--   egg      vugger på sokkelen (mer og mer jo nærmere klekking), rister når de klekker, svever når de er
--            mistet, og ruller rundt på eggebåndet
--   spesielt planetringen går rundt, Phoenix brenner, Rainbow skifter farge, Galaxy og Diamond glitrer
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Fugler = require(Shared:WaitForChild("Fugler"))
local Kart = require(Shared:WaitForChild("Kart"))

local Fugleliv = {}

local alle = {} -- [Model] = tilstand
Fugleliv.vedLanding = nil -- funksjon(pos) når et gullegg lander (effekter)
local rad = math.rad

local function A(x, y, z)
	return CFrame.Angles(rad(x), rad(y or 0), rad(z or 0))
end

local function myk(t)
	t = math.clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end

local function motor(m, del)
	local d = m:FindFirstChild(del)
	return d and d:FindFirstChild(del)
end

-- ---------------------------------------------------------------- effekter på fuglene

local function partikler(del, e)
	local p = Instance.new("ParticleEmitter")
	for k, v in e do
		p[k] = v
	end
	p.Parent = del
	return p
end

local function pynt(st)
	local m = st.modell
	local kropp = m:FindFirstChild("Kropp")
	if not kropp then
		return
	end
	local art = Fugler.ART[m:GetAttribute("Art") or ""]
	local effekt = art and art.effekt
	if effekt == "ild" then
		partikler(kropp, { Texture = "rbxasset://textures/particles/fire_main.dds", Rate = 14, Lifetime = NumberRange.new(0.4, 0.8),
			Speed = NumberRange.new(1.5, 3), SpreadAngle = Vector2.new(25, 25), LightEmission = 1,
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.1), NumberSequenceKeypoint.new(1, 0) }),
			Color = ColorSequence.new(Color3.fromRGB(255, 220, 90), Color3.fromRGB(255, 70, 20)),
			Acceleration = Vector3.new(0, 4, 0) })
		local lys = Instance.new("PointLight")
		lys.Color = Color3.fromRGB(255, 160, 60)
		lys.Range = 12
		lys.Brightness = 1.6
		lys.Parent = kropp
	elseif effekt == "is" then
		partikler(kropp, { Texture = "rbxasset://textures/particles/sparkles_main.dds", Rate = 10,
			Lifetime = NumberRange.new(0.6, 1.2), Speed = NumberRange.new(0.5, 1.5), SpreadAngle = Vector2.new(180, 180),
			LightEmission = 0.8, Size = NumberSequence.new(0.5, 0), Color = ColorSequence.new(Color3.fromRGB(170, 235, 255)) })
	elseif effekt == "lyn" then
		partikler(kropp, { Texture = "rbxasset://textures/particles/sparkles_main.dds", Rate = 6,
			Lifetime = NumberRange.new(0.15, 0.3), Speed = NumberRange.new(4, 8), SpreadAngle = Vector2.new(180, 180),
			LightEmission = 1, Size = NumberSequence.new(0.6, 0), Color = ColorSequence.new(Color3.fromRGB(255, 250, 140)) })
	elseif effekt == "sno" then
		partikler(kropp, { Texture = "rbxasset://textures/particles/sparkles_main.dds", Rate = 5,
			Lifetime = NumberRange.new(1.2, 2), Speed = NumberRange.new(0.3, 0.8), SpreadAngle = Vector2.new(40, 40),
			EmissionDirection = Enum.NormalId.Top, Acceleration = Vector3.new(0, -1.5, 0), LightEmission = 0.4,
			Size = NumberSequence.new(0.35, 0.2), Color = ColorSequence.new(Color3.fromRGB(255, 255, 255)) })
	elseif effekt == "stink" then
		partikler(kropp, { Texture = "rbxasset://textures/particles/smoke_main.dds", Rate = 2,
			Lifetime = NumberRange.new(1.5, 2.5), Speed = NumberRange.new(0.5, 1.2), SpreadAngle = Vector2.new(30, 30),
			EmissionDirection = Enum.NormalId.Top, Transparency = NumberSequence.new(0.6, 1),
			Size = NumberSequence.new(0.8, 2.2), Color = ColorSequence.new(Color3.fromRGB(150, 170, 80)) })
	elseif effekt == "glitter" then
		partikler(kropp, { Texture = "rbxasset://textures/particles/sparkles_main.dds", Rate = 7,
			Lifetime = NumberRange.new(0.5, 1), Speed = NumberRange.new(0.3, 1), SpreadAngle = Vector2.new(180, 180),
			LightEmission = 1, Size = NumberSequence.new(0.5, 0),
			Color = ColorSequence.new(Color3.fromRGB(80, 230, 220), Color3.fromRGB(255, 220, 90)) })
	elseif effekt == "gresskar" then
		local lys = Instance.new("PointLight")
		lys.Color = Color3.fromRGB(255, 160, 40)
		lys.Range = 10
		lys.Brightness = 1.8
		lys.Parent = kropp
	elseif effekt == "spokelys" then
		local lys = Instance.new("PointLight")
		lys.Color = Color3.fromRGB(120, 255, 140)
		lys.Range = 10
		lys.Brightness = 1.5
		lys.Parent = kropp
		partikler(kropp, { Texture = "rbxasset://textures/particles/sparkles_main.dds", Rate = 4,
			Lifetime = NumberRange.new(0.8, 1.4), Speed = NumberRange.new(0.3, 0.8), SpreadAngle = Vector2.new(180, 180),
			LightEmission = 1, Size = NumberSequence.new(0.4, 0), Color = ColorSequence.new(Color3.fromRGB(140, 255, 160)) })
	elseif effekt == "spokelse" then
		-- spøkelset er halvt gjennomsiktig og glitrer svakt
		for _, navn in { "Kropp", "VingeH", "VingeV" } do
			local d = m:FindFirstChild(navn)
			if d then
				d.LocalTransparencyModifier = 0.35
			end
		end
		partikler(kropp, { Texture = "rbxasset://textures/particles/sparkles_main.dds", Rate = 6,
			Lifetime = NumberRange.new(1, 1.8), Speed = NumberRange.new(0.2, 0.6), SpreadAngle = Vector2.new(180, 180),
			LightEmission = 1, Size = NumberSequence.new(0.5, 0), Color = ColorSequence.new(Color3.fromRGB(220, 250, 255)) })
	elseif effekt == "magi" then
		partikler(kropp, { Texture = "rbxasset://textures/particles/sparkles_main.dds", Rate = 7,
			Lifetime = NumberRange.new(0.6, 1.2), Speed = NumberRange.new(0.4, 1.2), SpreadAngle = Vector2.new(180, 180),
			LightEmission = 1, Size = NumberSequence.new(0.5, 0),
			Color = ColorSequence.new(Color3.fromRGB(180, 110, 255), Color3.fromRGB(120, 255, 140)) })
	elseif effekt == "gull" then
		partikler(kropp, { Texture = "rbxasset://textures/particles/sparkles_main.dds", Rate = 9,
			Lifetime = NumberRange.new(0.6, 1.2), Speed = NumberRange.new(0.5, 1.5), SpreadAngle = Vector2.new(180, 180),
			LightEmission = 1, Size = NumberSequence.new(0.6, 0),
			Color = ColorSequence.new(Color3.fromRGB(255, 225, 90), Color3.fromRGB(255, 255, 220)) })
	elseif effekt == "kosmos" then
		partikler(kropp, { Texture = "rbxasset://textures/particles/sparkles_main.dds", Rate = 8,
			Lifetime = NumberRange.new(0.8, 1.6), Speed = NumberRange.new(0.3, 1), SpreadAngle = Vector2.new(180, 180),
			LightEmission = 1, Size = NumberSequence.new(0.45, 0),
			Color = ColorSequence.new(Color3.fromRGB(140, 255, 250), Color3.fromRGB(255, 140, 240)) })
	end
	local mut = m:GetAttribute("Mut")
	if mut == "Galaxy" or mut == "Diamond" or mut == "Gold" then
		local farge = Fugler.MUT[mut].farge
		partikler(kropp, { Texture = "rbxasset://textures/particles/sparkles_main.dds", Rate = mut == "Galaxy" and 10 or 4,
			Lifetime = NumberRange.new(0.5, 1), Speed = NumberRange.new(0.2, 0.8), SpreadAngle = Vector2.new(180, 180),
			LightEmission = 1, Size = NumberSequence.new(0.5, 0), Color = ColorSequence.new(farge, Color3.new(1, 1, 1)) })
	end
end

-- En tekst som stiger opp og forsvinner over fuglen («+$12», «♪»).
local function stigendeTekst(st, tekst, farge, hoyde)
	local rot = st.modell:FindFirstChild("Rot")
	if not rot then
		return
	end
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(110, 34)
	gui.StudsOffsetWorldSpace = Vector3.new((math.random() - 0.5) * 1.5, (st.modell:GetAttribute("Topp") or 4) + (hoyde or 0.5), 0)
	gui.LightInfluence = 0
	gui.MaxDistance = 60
	gui.Adornee = rot
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.FredokaOne
	t.TextScaled = true
	t.Text = tekst
	t.TextColor3 = farge
	t.TextStrokeTransparency = 0.2
	t.Parent = gui
	gui.Parent = st.modell
	TweenService:Create(gui, TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ StudsOffsetWorldSpace = gui.StudsOffsetWorldSpace + Vector3.new(0, 2.2, 0) }):Play()
	TweenService:Create(t, TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	Debris:AddItem(gui, 1.2)
end

-- «+$12» som spretter opp fra fuglen
local function pengeTekst(st, belop)
	local rot = st.modell:FindFirstChild("Rot")
	if not rot then
		return
	end
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(110, 34)
	gui.StudsOffsetWorldSpace = Vector3.new(0, (st.modell:GetAttribute("Topp") or 4) + 0.5, 0)
	gui.LightInfluence = 0
	gui.MaxDistance = 60
	gui.Adornee = rot
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.FredokaOne
	t.TextScaled = true
	t.Text = "+" .. Fugler.penger(belop)
	t.TextColor3 = Color3.fromRGB(110, 255, 130)
	t.TextStrokeTransparency = 0.2
	t.Parent = gui
	gui.Parent = st.modell
	TweenService:Create(gui, TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ StudsOffsetWorldSpace = gui.StudsOffsetWorldSpace + Vector3.new(0, 2.2, 0) }):Play()
	TweenService:Create(t, TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	Debris:AddItem(gui, 1.2)
end

-- ---------------------------------------------------------------- registrering

local function registrer(m)
	if alle[m] then
		return
	end
	local st = {
		modell = m,
		fase = math.random() * 100,
		kropp = motor(m, "Kropp"),
		vingeH = motor(m, "VingeH"),
		vingeV = motor(m, "VingeV"),
		ekstra = motor(m, "Ekstra"),
		nesteFlaks = os.clock() + 1 + math.random() * 5,
		nesteHopp = os.clock() + 2 + math.random() * 4,
		sistHopp = os.clock(),
		kikk = 0, kikkMaal = 0, nesteKikk = os.clock() + math.random() * 3,
		erFugl = CollectionService:HasTag(m, "Fugl"),
		belte = CollectionService:HasTag(m, "BelteEgg"),
	}
	local art = Fugler.ART[m:GetAttribute("Art") or ""]
	st.spredt = art and art.vinge == "spredt"
	local STIGENDE = {
		noter = { tegn = { "♪", "♫" }, farge = Color3.fromRGB(255, 230, 120), hvert = 1.2 },
		spokelse = { tegn = { "Boo!", "boo..." }, farge = Color3.fromRGB(220, 245, 255), hvert = 3 },
		vampyr = { tegn = { "🦇" }, farge = Color3.fromRGB(255, 255, 255), hvert = 2.5 },
	}
	st.tekst = art and STIGENDE[art.effekt or ""]
	st.svever = art and art.effekt == "spokelse"
	alle[m] = st
	if st.erFugl then
		task.defer(pynt, st)
	elseif m:GetAttribute("Sj") == "Meteor" or m:GetAttribute("Sj") == "Spooky" then
		local kropp = m:FindFirstChild("Kropp")
		if kropp then
			local meteor = m:GetAttribute("Sj") == "Meteor"
			local lys = Instance.new("PointLight")
			lys.Color = meteor and Color3.fromRGB(255, 110, 30) or Color3.fromRGB(255, 150, 40)
			lys.Range = meteor and 18 or 10
			lys.Brightness = meteor and 2.5 or 1.5
			lys.Parent = kropp
			if meteor then
				partikler(kropp, { Texture = "rbxasset://textures/particles/fire_main.dds", Rate = 16,
					Lifetime = NumberRange.new(0.4, 0.8), Speed = NumberRange.new(1.5, 3), SpreadAngle = Vector2.new(25, 25),
					LightEmission = 1, Acceleration = Vector3.new(0, 4, 0),
					Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 0) }),
					Color = ColorSequence.new(Color3.fromRGB(255, 200, 80), Color3.fromRGB(255, 50, 20)) })
				partikler(kropp, { Texture = "rbxasset://textures/particles/smoke_main.dds", Rate = 4,
					Lifetime = NumberRange.new(1.5, 2.5), Speed = NumberRange.new(1, 2), SpreadAngle = Vector2.new(20, 20),
					Transparency = NumberSequence.new(0.5, 1), Size = NumberSequence.new(1, 3),
					Color = ColorSequence.new(Color3.fromRGB(70, 65, 60)) })
			end
		end
	elseif m:GetAttribute("Sj") == "Golden" then
		-- gulleggene lyser og glitrer, så de synes på avstand
		local kropp = m:FindFirstChild("Kropp")
		if kropp then
			local lys = Instance.new("PointLight")
			lys.Color = Color3.fromRGB(255, 210, 80)
			lys.Range = 14
			lys.Brightness = 2
			lys.Parent = kropp
			partikler(kropp, { Texture = "rbxasset://textures/particles/sparkles_main.dds", Rate = 8,
				Lifetime = NumberRange.new(0.5, 1), Speed = NumberRange.new(0.5, 2), SpreadAngle = Vector2.new(180, 180),
				LightEmission = 1, Size = NumberSequence.new(0.6, 0), Color = ColorSequence.new(Color3.fromRGB(255, 230, 120)) })
		end
	end
	m.AncestryChanged:Connect(function()
		if not m:IsDescendantOf(workspace) then
			alle[m] = nil
		end
	end)
end

-- ---------------------------------------------------------------- animasjon

local function vinger(st, vinkel)
	-- vinkel i grader: positiv = ut/opp. Høyre vinge roterer om +Z (fremover-aksen), venstre motsatt.
	if st.vingeH then
		st.vingeH.Transform = A(0, 0, vinkel)
	end
	if st.vingeV then
		st.vingeV.Transform = A(0, 0, -vinkel)
	end
end

local function fugl(st, naa, servertid)
	local m = st.modell
	local t = naa + st.fase
	local tilstand = m:GetAttribute("Tilstand")
	local klekket = m:GetAttribute("Klekket")
	local kroppCF = CFrame.new()
	local vinkel = 0
	if tilstand == "baeres" then
		-- vill flaksing mens tyven bærer den
		vinkel = (st.spredt and 10 or 35) + 45 * math.sin(t * 24)
		kroppCF = A(10 * math.sin(t * 13), 15 * math.sin(t * 9), 12 * math.sin(t * 11))
	elseif klekket and servertid - klekket < 1.7 then
		-- akkurat klekket: spretter opp, snurrer og flakser, og lander
		local k = (servertid - klekket) / 1.7
		local hopp = math.sin(math.clamp(k / 0.8, 0, 1) * math.pi) * 3.2
		kroppCF = CFrame.new(0, hopp, 0) * A(0, 360 * myk(k / 0.75), 0)
		vinkel = (st.spredt and 15 or 50) + 40 * math.sin(t * 26) * (1 - k)
	else
		-- vanlig: pust, se seg rundt, hopp innimellom
		if naa > st.nesteKikk then
			st.nesteKikk = naa + 1.5 + math.random() * 3.5
			st.kikkMaal = (math.random() - 0.5) * 70
		end
		st.kikk += (st.kikkMaal - st.kikk) * 0.06
		local bob = math.sin(t * 2.3) * 0.06
		local hoppY = 0
		local inntekt = m:GetAttribute("Inntekt") or 0
		if inntekt > 0 and naa > st.nesteHopp then
			local intervall = naa - st.sistHopp
			st.sistHopp = naa
			st.nesteHopp = naa + 3 + math.random() * 3
			st.hoppStart = naa
			local kamera = workspace.CurrentCamera
			local rot = m:FindFirstChild("Rot")
			if rot and (rot.Position - kamera.CFrame.Position).Magnitude < 60 then
				pengeTekst(st, math.floor(inntekt * intervall))
			end
		end
		if st.tekst and naa > (st.nesteNote or 0) then
			st.nesteNote = naa + st.tekst.hvert + math.random() * st.tekst.hvert
			local kamera = workspace.CurrentCamera
			local rot = m:FindFirstChild("Rot")
			if rot and (rot.Position - kamera.CFrame.Position).Magnitude < 60 then
				local liste = st.tekst.tegn
				stigendeTekst(st, liste[math.random(1, #liste)], st.tekst.farge, 0.2)
			end
		end
		if st.hoppStart and naa - st.hoppStart < 0.38 then
			hoppY = math.sin((naa - st.hoppStart) / 0.38 * math.pi) * 0.75
		end
		if st.svever then
			bob = 0.35 + 0.3 * math.sin(t * 1.6)
		end
		kroppCF = CFrame.new(0, bob + hoppY, 0) * A(3 * math.sin(t * 1.1), st.kikk, 3 * math.sin(t * 0.7))
		-- flaksing innimellom (3–4 slag), ellers rolig pust med vingene
		if naa > st.nesteFlaks then
			st.flaksStart = naa
			st.nesteFlaks = naa + 4 + math.random() * 6
		end
		if st.flaksStart and naa - st.flaksStart < 0.55 then
			local f = (naa - st.flaksStart) / 0.55
			local slag = math.abs(math.sin(f * math.pi * 3.5))
			vinkel = st.spredt and (-18 + 40 * slag) or (75 * slag)
		elseif hoppY > 0 then
			vinkel = st.spredt and 12 or 35
		else
			vinkel = st.spredt and 4 * math.sin(t * 1.6) or 3 * (0.5 + 0.5 * math.sin(t * 2.3))
		end
	end
	if st.kropp then
		st.kropp.Transform = kroppCF
	end
	vinger(st, vinkel)
	if st.ekstra then
		st.ekstra.Transform = A(0, (t * 50) % 360, 0)
	end
	-- Rainbow-mutasjonen skifter farge
	if m:GetAttribute("Mut") == "Rainbow" then
		local farge = Color3.fromHSV((t * 0.25) % 1, 0.65, 1)
		for _, navn in { "Kropp", "VingeH", "VingeV" } do
			local d = m:FindFirstChild(navn)
			if d then
				d.Color = farge
			end
		end
	end
end

local function egg(st, naa, servertid)
	local m = st.modell
	local t = naa + st.fase
	local kroppCF = CFrame.new()
	local tilstand = m:GetAttribute("Tilstand")
	if st.belte then
		-- ruller rundt på båndet
		local start = m:GetAttribute("Start") or servertid
		local andel = (servertid - start) / (m:GetAttribute("Rundetid") or 80)
		local rot = m:FindFirstChild("Rot")
		if rot then
			if andel >= 1 then
				rot.CFrame = CFrame.new(0, -500, 0)
			else
				local cf = Kart.beltePos(math.max(andel, 0))
				m:PivotTo(cf)
			end
		end
		local alder = servertid - start
		local hopp = alder < 0.45 and math.sin(alder / 0.45 * math.pi) * 1.6 or 0
		kroppCF = CFrame.new(0, hopp, 0) * A(0, 0, 9 * math.sin(t * 5))
	elseif tilstand == "sluppet" and m:GetAttribute("Fall") and servertid - m:GetAttribute("Fall") < (m:GetAttribute("FallTid") or 0) then
		-- et gullegg som faller fra himmelen (raskere og raskere), og spinner
		local k = (servertid - m:GetAttribute("Fall")) / m:GetAttribute("FallTid")
		kroppCF = CFrame.new(0, 80 * (1 - k * k), 0) * A(0, (t * 400) % 360, 0)
		st.skalLande = true
	elseif tilstand == "sluppet" then
		if st.skalLande then
			st.skalLande = false
			local rot = m:FindFirstChild("Rot")
			if rot and Fugleliv.vedLanding then
				Fugleliv.vedLanding(rot.Position)
			end
		end
		kroppCF = CFrame.new(0, 0.5 + 0.4 * math.sin(t * 3), 0) * A(0, (t * 90) % 360, 15 * math.sin(t * 2))
		local igjen = (m:GetAttribute("SluppetTil") or 0) - servertid
		local merke = m:FindFirstChild("Merke")
		local tid = merke and merke:FindFirstChild("Tid")
		if tid then
			if m:GetAttribute("Eier") == 0 then
				tid.Text = string.format("FREE! GRAB IT! %ds", math.max(0, math.ceil(igjen)))
			else
				tid.Text = string.format("GRAB IT! %ds", math.max(0, math.ceil(igjen)))
			end
			tid.TextColor3 = Color3.fromRGB(255, 220, 80)
		end
	elseif tilstand == "baeres" then
		kroppCF = A(8 * math.sin(t * 7), 0, 8 * math.sin(t * 5))
	else
		local klar = m:GetAttribute("KlarTid") or 0
		local klekker = m:GetAttribute("Klekker")
		local igjen = klar - servertid
		if klekker then
			-- rister kraftigere og kraftigere til det sprekker
			local k = math.clamp((servertid - klekker) / 1.6, 0, 1)
			kroppCF = CFrame.new(0, 0.15 * k * math.abs(math.sin(t * 40)), 0)
				* A(18 * k * math.sin(t * 38), 0, 18 * k * math.sin(t * 31))
		else
			-- vugger innimellom, oftere jo nærmere klekking
			local hyppighet = igjen < 4 and 3 or 0.7
			local vugg = math.max(0, math.sin(t * hyppighet)) ^ 6
			local styrke = igjen < 4 and 14 or 7
			kroppCF = A(0, 0, styrke * vugg * math.sin(t * 22))
		end
		local merke = m:FindFirstChild("Merke")
		local tid = merke and merke:FindFirstChild("Tid")
		if tid and klar > 0 then
			tid.Text = igjen > 0 and string.format("Hatching in %ds", math.ceil(igjen)) or "Hatching!"
		end
	end
	if st.kropp then
		st.kropp.Transform = kroppCF
	end
end

-- Flaggermus (Halloween) flyr i ring rundt et senter og flakser opp og ned.
local flaggermus = {}
local function flaggermusSteg(naa)
	for f in flaggermus do
		if not f.Parent then
			flaggermus[f] = nil
			continue
		end
		local senter = f:GetAttribute("Senter")
		if typeof(senter) == "Vector3" then
			local a = naa * (f:GetAttribute("Fart") or 0.4) + (f:GetAttribute("Fase") or 0)
			local r = f:GetAttribute("Radius") or 20
			local p = senter + Vector3.new(math.cos(a) * r, math.sin(naa * 3 + a) * 1.5, math.sin(a) * r)
			local frem = Vector3.new(-math.sin(a), 0, math.cos(a)) * ((f:GetAttribute("Fart") or 1) > 0 and 1 or -1)
			f.CFrame = CFrame.lookAt(p, p + frem) * A(0, 0, 25 * math.sin(naa * 14 + a))
		end
	end
end

function Fugleliv.start()
	for _, f in CollectionService:GetTagged("Flaggermus") do
		flaggermus[f] = true
	end
	CollectionService:GetInstanceAddedSignal("Flaggermus"):Connect(function(f)
		flaggermus[f] = true
	end)
	for _, tag in { "Fugl", "Egg" } do
		for _, m in CollectionService:GetTagged(tag) do
			registrer(m)
		end
		CollectionService:GetInstanceAddedSignal(tag):Connect(registrer)
	end
	RunService.Stepped:Connect(function()
		local naa = os.clock()
		local servertid = workspace:GetServerTimeNow()
		flaggermusSteg(naa)
		local kamera = workspace.CurrentCamera.CFrame.Position
		for m, st in alle do
			local rot = m:FindFirstChild("Rot")
			if rot and (st.belte or (rot.Position - kamera).Magnitude < 220) then
				if st.erFugl then
					fugl(st, naa, servertid)
				else
					egg(st, naa, servertid)
				end
			end
		end
	end)
end

return Fugleliv
