-- Kode-animasjoner for ALLE figurer (din egen og de andres). Positurene legges oppå Roblox sine vanlige
-- animasjoner ved å sette leddene (Motor6D.Transform) i RunService.Stepped — da er Roblox ferdig med
-- sine, så våre vinner. Hver positur har en vekt som glir mellom 0 og 1, så alt blander mykt.
--
--   sving     krok-armen strekker seg mot festet, beina henger etter, kroppen lener seg mot tauet
--   fly       strømlinjeformet når du suser fram, armene ut som en fallskjermhopper når du faller
--   salto/skru  triks i lufta
--   landing   superhelt-landing: ett kne i bakken og knyttneven ned
--   ragdoll   slapp filledukke som slenger med armer og bein (fysikken tumler kroppen)
--   svimmel   hodet går i ring, stjerner rundt hodet
--   baer      begge armene opp med tingen over hodet (og et snapp når du tar den)
--   emoter    ChickenDance, Wave, Flex, Victory
-- I tillegg: lysspor fra hendene i høy fart.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Positurer = {}

local spiller = Players.LocalPlayer
local Grappler, Tau
local remotes
local figurer = {} -- [Model] = tilstand

local NED = Vector3.new(0, -1, 0)
local FREM = Vector3.new(0, 0, -1)
local rad = math.rad

-- ---------------------------------------------------------------- matte

local function A(x, y, z)
	return CFrame.Angles(rad(x), rad(y or 0), rad(z or 0))
end

-- Rotasjonen som dreier enhetsvektoren `fra` til `til`.
local function rotTil(fra, til)
	local d = fra:Dot(til)
	if d > 0.99999 then
		return CFrame.new()
	end
	if d < -0.99999 then
		local akse = math.abs(fra.X) < 0.9 and fra:Cross(Vector3.new(1, 0, 0)) or fra:Cross(Vector3.new(0, 0, 1))
		return CFrame.fromAxisAngle(akse.Unit, math.pi)
	end
	return CFrame.fromAxisAngle(fra:Cross(til).Unit, math.acos(math.clamp(d, -1, 1)))
end
Positurer.rotTil = rotTil

local function v(x, y, z)
	return Vector3.new(x, y, z).Unit
end

-- Et lem (arm eller bein) beskrevet med retninger i foreldrerommet (overkropp/underkropp):
-- `over` = retningen overarmen/låret peker, `under` = retningen underarmen/leggen peker.
-- Returnerer rotasjonene for skulder/hofte og albue/kne.
local function lem(over, under)
	local rs = rotTil(NED, over.Unit)
	local ru = rotTil(NED, (rs:Inverse() * under).Unit)
	return rs, ru
end
Positurer.lem = lem

-- Arm-par: settes inn i positur-tabellen p. side = 1 for høyre, -1 for venstre (x speiles).
local function armer(p, side, over, under)
	local rs, ru = lem(Vector3.new(over.X * side, over.Y, over.Z), Vector3.new(under.X * side, under.Y, under.Z))
	if side > 0 then
		p.RShoulder, p.RElbow = rs, ru
	else
		p.LShoulder, p.LElbow = rs, ru
	end
end

local function bein(p, side, over, under)
	local rs, ru = lem(Vector3.new(over.X * side, over.Y, over.Z), Vector3.new(under.X * side, under.Y, under.Z))
	if side > 0 then
		p.RHip, p.RKnee = rs, ru
	else
		p.LHip, p.LKnee = rs, ru
	end
end

local function myk(t)
	t = math.clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end

local function naerme(a, b, rate, dt)
	return a + (b - a) * (1 - math.exp(-rate * dt))
end

-- ---------------------------------------------------------------- leddene

-- nøkkel -> { R15 del, R15 motor, R6 del, R6 motor }
local LEDD = {
	Root = { "LowerTorso", "Root", "HumanoidRootPart", "RootJoint" },
	Waist = { "UpperTorso", "Waist" },
	Neck = { "Head", "Neck", "Torso", "Neck" },
	RShoulder = { "RightUpperArm", "RightShoulder", "Torso", "Right Shoulder" },
	RElbow = { "RightLowerArm", "RightElbow" },
	LShoulder = { "LeftUpperArm", "LeftShoulder", "Torso", "Left Shoulder" },
	LElbow = { "LeftLowerArm", "LeftElbow" },
	RHip = { "RightUpperLeg", "RightHip", "Torso", "Right Hip" },
	RKnee = { "RightLowerLeg", "RightKnee" },
	LHip = { "LeftUpperLeg", "LeftHip", "Torso", "Left Hip" },
	LKnee = { "LeftLowerLeg", "LeftKnee" },
}

local function finnLedd(modell)
	local ledd, cr = {}, {}
	for navn, def in LEDD do
		local del = modell:FindFirstChild(def[1])
		local m = del and del:FindFirstChild(def[2])
		if not m and def[3] then
			del = modell:FindFirstChild(def[3])
			m = del and del:FindFirstChild(def[4])
		end
		if m and m:IsA("Motor6D") then
			ledd[navn] = m
			cr[navn] = m.C0.Rotation
		end
	end
	return ledd, cr
end

-- Sett et ledd mot en positur (rotasjon/forflytning i foreldrens rom), blandet med vekt w.
local function sett(st, navn, maal, w)
	local m = st.ledd[navn]
	if not m or not maal or w <= 0.002 then
		return
	end
	local cr = st.cr[navn]
	local onsket = cr:Inverse() * maal * cr
	if w >= 0.998 then
		m.Transform = onsket
	else
		m.Transform = m.Transform:Lerp(onsket, w)
	end
end

local function leggTil(st, navn, ekstra)
	local m = st.ledd[navn]
	if not m then
		return
	end
	local cr = st.cr[navn]
	m.Transform = m.Transform * (cr:Inverse() * ekstra * cr)
end

local function brukPositur(st, p, w)
	if w <= 0.002 then
		return
	end
	for navn, maal in p do
		sett(st, navn, maal, w)
	end
end

-- ---------------------------------------------------------------- positurene

local function svingPositur(st, anker, fart, t)
	local p = {}
	local ut = st.ledd.RShoulder and st.ledd.RShoulder.Part0
	local rot = st.rot
	if not ut or not rot then
		return p
	end
	-- krok-armen (høyre) peker mot festet, venstre holder tauet litt lavere
	for side = -1, 1, 2 do
		local ledd = side > 0 and st.ledd.RShoulder or st.ledd.LShoulder
		if ledd then
			local skulder = ut.CFrame * ledd.C0.Position
			local d = ut.CFrame:VectorToObjectSpace((anker - skulder).Unit)
			if side < 0 then
				d = (d + Vector3.new(0.25, -0.35, 0)).Unit
			end
			local rs = rotTil(NED, d)
			if side > 0 then
				p.RShoulder, p.RElbow = rs, A(8, 0, 0)
			else
				p.LShoulder, p.LElbow = rs, A(28, 0, 0)
			end
		end
	end
	-- kroppen henger mot festet (men ikke helt)
	local r = rot.CFrame:VectorToObjectSpace((anker - rot.Position).Unit)
	local mot = rotTil(Vector3.new(0, 1, 0), r)
	p.Root = CFrame.new():Lerp(mot, 0.55)
	-- beina henger etter farten og sparker litt
	local vl = rot.CFrame:VectorToObjectSpace(fart)
	local bak = vl.Magnitude > 1 and -vl.Unit or Vector3.zero
	local retn = (NED + bak * 0.55)
	local kick = math.sin(t * 3)
	bein(p, 1, retn + Vector3.new(0.08, 0, 0.1 * kick), retn + Vector3.new(0, 0, 0.5 + 0.2 * kick))
	bein(p, -1, retn + Vector3.new(0.08, 0, -0.1 * kick), retn + Vector3.new(0, 0, 0.9 - 0.2 * kick))
	-- hodet ser litt mot festet
	local hode = ut.CFrame:VectorToObjectSpace((anker - ut.Position).Unit)
	p.Neck = CFrame.new():Lerp(rotTil(FREM, (FREM + hode).Unit), 0.5)
	return p
end

local function flyPositur(st, fart, t)
	local p = {}
	local rot = st.rot
	local vl = rot.CFrame:VectorToObjectSpace(fart)
	local faller = fart.Y < -35
	if faller then
		-- fallskjermhopper: armer og bein ut, flagrer i vinden
		local f = math.sin(t * 22) * 0.08
		armer(p, 1, Vector3.new(1, 0.25 + f, 0.1), Vector3.new(1, 0.55, -0.1))
		armer(p, -1, Vector3.new(1, 0.25 - f, 0.1), Vector3.new(1, 0.55, -0.1))
		bein(p, 1, Vector3.new(0.35, -1, 0.35), Vector3.new(0.2, -0.6, 0.9))
		bein(p, -1, Vector3.new(0.35, -1, 0.35), Vector3.new(0.2, -0.6, 0.9))
		p.Root = A(-25, 0, 0)
	else
		-- strømlinje: lener seg i farten, armene bakover, beina samlet
		local frem = Vector3.new(vl.X, math.max(vl.Y, -10), vl.Z)
		local lean = frem.Magnitude > 1 and rotTil(Vector3.new(0, 1, 0), (Vector3.new(0, 1, 0) + frem.Unit * 1.3).Unit)
			or CFrame.new()
		p.Root = CFrame.new():Lerp(lean, 0.7)
		local f = math.sin(t * 18) * 0.05
		armer(p, 1, Vector3.new(0.25, -0.8, 0.6 + f), Vector3.new(0.15, -0.6, 0.8))
		armer(p, -1, Vector3.new(0.25, -0.8, 0.6 - f), Vector3.new(0.15, -0.6, 0.8))
		bein(p, 1, Vector3.new(0.05, -1, 0.25), Vector3.new(0, -0.8, 0.6))
		bein(p, -1, Vector3.new(0.05, -1, 0.4), Vector3.new(0, -0.6, 0.9))
		p.Neck = A(18, 0, 0)
	end
	return p
end

local function saltoTuck(e)
	local p = {}
	local k = math.sin(e * math.pi)
	bein(p, 1, (NED + Vector3.new(0.15, 0, -1.6) * k).Unit, (NED + Vector3.new(0, 0, 1.3) * k).Unit)
	bein(p, -1, (NED + Vector3.new(0.15, 0, -1.6) * k).Unit, (NED + Vector3.new(0, 0, 1.3) * k).Unit)
	armer(p, 1, (NED + Vector3.new(0.3, 0, -1.2) * k).Unit, (NED + Vector3.new(-0.4, 0.6, -0.8) * k).Unit)
	armer(p, -1, (NED + Vector3.new(0.3, 0, -1.2) * k).Unit, (NED + Vector3.new(-0.4, 0.6, -0.8) * k).Unit)
	return p
end

local function skruPositur(e)
	local p = {}
	local k = math.sin(e * math.pi)
	armer(p, 1, (NED + Vector3.new(2.2, 0.6, 0) * k).Unit, (NED + Vector3.new(2.4, 1.0, 0) * k).Unit)
	armer(p, -1, (NED + Vector3.new(2.2, 0.6, 0) * k).Unit, (NED + Vector3.new(2.4, 1.0, 0) * k).Unit)
	bein(p, 1, v(-0.05, -1, 0), v(0, -1, 0.1))
	bein(p, -1, v(-0.05, -1, 0), v(0, -1, 0.1))
	return p
end

-- Superhelt-landing. k = hvor hard landingen var (0..1), opp = hodet løftes mot slutten (0..1).
local function landingPositur(k, opp)
	local p = {}
	local ned = 1.1 + 0.5 * k
	p.Root = CFrame.new(0, -ned, -0.2) * A(-14, 0, 0)
	p.Waist = A(-26 + 10 * opp, 0, 0)
	p.Neck = A(-18 + 34 * opp, 0, 0)
	-- høyre kne i bakken, venstre fot fram
	bein(p, 1, v(0.12, -1, 0.05), v(0, -0.15, 1))
	bein(p, -1, v(-0.05, -0.05, -1), v(0, -1, 0.05))
	-- høyre knyttneve i bakken, venstre arm ut bak
	armer(p, 1, v(0.25, -1, -0.35), v(0.1, -1, -0.15))
	armer(p, -1, v(0.75, -0.55, 0.6), v(0.6, -0.2, 0.75))
	return p
end

local function ragdollPositur(st, t, styrke)
	local p = {}
	local f = st.fase
	local a = 0.4 + 0.6 * styrke
	for side = -1, 1, 2 do
		local o = side > 0 and 0 or 1.7
		armer(p, side,
			Vector3.new(0.6 + 0.5 * math.sin(t * 5.3 + f + o), 0.6 * math.sin(t * 7.1 + f * 2 + o) * a, 0.7 * math.cos(t * 6.2 + o) * a),
			Vector3.new(0.5 + 0.4 * math.sin(t * 8.3 + o), 0.8 * math.sin(t * 9.1 + f + o) * a, 0.6 * math.cos(t * 7.7 + f) * a))
		bein(p, side,
			Vector3.new(0.25 + 0.2 * math.sin(t * 4.1 + o), -1, 0.8 * math.sin(t * 6.3 + f + o) * a),
			Vector3.new(0.1, -1, 0.3 + 0.9 * (0.5 + 0.5 * math.sin(t * 8.7 + o)) * a))
	end
	p.Neck = A(25 * math.sin(t * 5.1 + f) * a, 25 * math.sin(t * 3.7) * a, 15 * math.cos(t * 4.4) * a)
	p.Waist = A(18 * math.sin(t * 4.2 + f) * a, 10 * math.sin(t * 2.9) * a, 14 * math.cos(t * 3.3) * a)
	return p
end

local function baerPositur(t, gaar)
	local p = {}
	local bob = gaar and math.sin(t * 9) * 0.05 or 0
	armer(p, 1, v(0.28, 1, -0.12 + bob), v(-0.3, 1, -0.05))
	armer(p, -1, v(0.28, 1, -0.12 - bob), v(-0.3, 1, -0.05))
	p.Waist = A(6, 0, 0)
	return p
end

local function snappPositur()
	local p = {}
	armer(p, 1, v(0.15, -0.15, -1), v(0.05, -0.05, -1))
	armer(p, -1, v(0.15, -0.15, -1), v(0.05, -0.05, -1))
	p.Waist = A(-12, 0, 0)
	return p
end

local EMOTER = {}
function EMOTER.ChickenDance(t)
	local p = {}
	local flaks = 0.5 + 0.5 * math.sin(t * 14)
	local b = 0.5 + 0.5 * math.sin(t * 7)
	armer(p, 1, Vector3.new(0.75, -0.55 + 0.6 * flaks, 0.15), Vector3.new(-0.8, 0.55, 0.15))
	armer(p, -1, Vector3.new(0.75, -0.55 + 0.6 * flaks, 0.15), Vector3.new(-0.8, 0.55, 0.15))
	bein(p, 1, v(0.08, -1, -0.25 * b), v(0, -1, 0.5 * b))
	bein(p, -1, v(0.08, -1, -0.25 * b), v(0, -1, 0.5 * b))
	local hakk = math.max(0, math.sin(t * 7))
	p.Neck = CFrame.new(0, 0, -0.3 * hakk) * A(-14 * hakk, 0, 0)
	p.Root = CFrame.new(0, -0.3 * b, 0) * A(0, 10 * math.sin(t * 3.5), 6 * math.sin(t * 7))
	p.Waist = A(-10, 0, 0)
	return p
end
function EMOTER.Wave(t)
	local p = {}
	local s = math.sin(t * 10)
	armer(p, 1, v(0.45, 0.85, -0.1), Vector3.new(0.2 + 0.55 * s, 1, -0.15))
	armer(p, -1, v(0.12, -1, 0.05), v(0.1, -1, -0.15))
	p.Neck = A(4, 0, 9 * math.sin(t * 2.2))
	p.Waist = A(0, 8, 3 * math.sin(t * 2.2))
	return p
end
function EMOTER.Flex(t)
	local p = {}
	local pump = 0.5 + 0.5 * math.sin(t * 6)
	armer(p, 1, v(1, 0.08, 0), Vector3.new(0.1 + 0.35 * pump, 1, 0))
	armer(p, -1, v(1, 0.08, 0), Vector3.new(0.1 + 0.35 * pump, 1, 0))
	p.Waist = A(9, 0, 0)
	p.Neck = A(10, 0, 0)
	p.Root = CFrame.new(0, -0.12 * pump, 0)
	bein(p, 1, v(0.25, -1, 0), v(0.25, -1, 0))
	bein(p, -1, v(0.25, -1, 0), v(0.25, -1, 0))
	return p
end
function EMOTER.Victory(t)
	local p = {}
	local hopp = math.abs(math.sin(t * 5))
	local pump = 0.5 + 0.5 * math.sin(t * 10)
	armer(p, 1, v(0.55, 0.85, 0), Vector3.new(0.45, 1, -0.4 * pump))
	armer(p, -1, v(0.55, 0.85, 0), Vector3.new(0.45, 1, -0.4 * (1 - pump)))
	p.Root = CFrame.new(0, 0.4 * hopp, 0)
	bein(p, 1, v(0.12, -1, -0.2 * (1 - hopp)), v(0, -1, 0.4 * (1 - hopp)))
	bein(p, -1, v(0.12, -1, -0.2 * (1 - hopp)), v(0, -1, 0.4 * (1 - hopp)))
	p.Neck = A(14, 0, 0)
	return p
end
Positurer.EMOTER = EMOTER

-- ---------------------------------------------------------------- effekter rundt figuren

local function lagSpor(st)
	for _, navn in { "RightHand", "LeftHand", "Right Arm", "Left Arm" } do
		local h = st.modell:FindFirstChild(navn)
		if h and h:IsA("BasePart") then
			local a0 = Instance.new("Attachment")
			a0.Name = "SporA"
			a0.Position = Vector3.new(0, 0.25, 0)
			a0.Parent = h
			local a1 = Instance.new("Attachment")
			a1.Name = "SporB"
			a1.Position = Vector3.new(0, -0.25, 0)
			a1.Parent = h
			local tr = Instance.new("Trail")
			tr.Name = "Lysspor"
			tr.Attachment0 = a0
			tr.Attachment1 = a1
			tr.Lifetime = 0.28
			tr.LightEmission = 1
			tr.FaceCamera = true
			tr.Color = ColorSequence.new(Color3.fromRGB(150, 235, 255), Color3.fromRGB(255, 255, 255))
			tr.Transparency = NumberSequence.new(0.15, 1)
			tr.WidthScale = NumberSequence.new(1, 0.1)
			tr.Enabled = false
			tr.Parent = h
			table.insert(st.spor, tr)
		end
	end
end

local function stjerner(st, paa)
	if paa and not st.stjerner then
		local hode = st.modell:FindFirstChild("Head")
		if not hode then
			return
		end
		st.stjerner = {}
		for n = 1, 3 do
			local gui = Instance.new("BillboardGui")
			gui.Name = "SvimmelStjerne"
			gui.Size = UDim2.fromOffset(28, 28)
			gui.AlwaysOnTop = false
			gui.LightInfluence = 0
			gui.Adornee = hode
			local t = Instance.new("TextLabel")
			t.Size = UDim2.fromScale(1, 1)
			t.BackgroundTransparency = 1
			t.TextScaled = true
			t.Text = n == 2 and "💫" or "⭐"
			t.Parent = gui
			gui.Parent = hode
			st.stjerner[n] = gui
		end
	elseif not paa and st.stjerner then
		for _, g in st.stjerner do
			g:Destroy()
		end
		st.stjerner = nil
	end
end

-- ---------------------------------------------------------------- per figur

local function registrer(modell, p)
	local hum = modell:WaitForChild("Humanoid", 10)
	local rot = modell:WaitForChild("HumanoidRootPart", 10)
	if not hum or not rot then
		return
	end
	local ledd, cr = finnLedd(modell)
	local st = {
		modell = modell, hum = hum, rot = rot, ledd = ledd, cr = cr, spiller = p, egen = p == spiller,
		vekt = { sving = 0, fly = 0, baer = 0, emote = 0, ragdoll = 0 },
		fase = math.random() * 6.28, spor = {}, luft = false, sjekket = 0,
		sistBaererTid = modell:GetAttribute("BaererTid"),
	}
	lagSpor(st)
	figurer[modell] = st
	modell.AncestryChanged:Connect(function()
		if not modell:IsDescendantOf(workspace) then
			stjerner(st, false)
			figurer[modell] = nil
		end
	end)
end

local strale = RaycastParams.new()
strale.FilterType = Enum.RaycastFilterType.Exclude

local function iLufta(st, naa)
	if st.egen then
		local s = Grappler and Grappler.tilstand()
		if s and s.bevegelse ~= "bakke" then
			return true
		end
		return st.hum.FloorMaterial == Enum.Material.Air
	end
	if naa - st.sjekket > 0.12 then
		st.sjekket = naa
		strale.FilterDescendantsInstances = { st.modell }
		local res = workspace:Raycast(st.rot.Position, Vector3.new(0, -4.2, 0), strale)
		st.luft = res == nil
	end
	return st.luft
end

local function anker(st)
	if st.egen then
		local s = Grappler and Grappler.tilstand()
		if s and s.krok == "fest" and s.bevegelse == "hekta" then
			return s.anker
		end
		return nil
	end
	if Tau and Tau.krokFor then
		local tilstand, pos = Tau.krokFor(st.spiller)
		if tilstand == "fest" then
			return pos
		end
	end
	return nil
end

local function stegFigur(st, dt, naa, servertid)
	local rot = st.rot
	if not rot.Parent or st.hum.Health <= 0 then
		return
	end
	local m = st.modell
	local fart = rot.AssemblyLinearVelocity
	local luft = iLufta(st, naa)
	local fest = anker(st)
	local ragdollTil = m:GetAttribute("Ragdoll") or 0
	local svimmelTil = m:GetAttribute("Svimmel") or 0
	local emote = m:GetAttribute("Emote")
	local baerer = m:GetAttribute("Baerer") ~= nil
	local bt = m:GetAttribute("BaererTid")
	if bt ~= st.sistBaererTid then
		st.sistBaererTid = bt
		if baerer then
			st.snapp = naa
		end
	end
	local ragdoll = ragdollTil > servertid
	local V = st.vekt
	-- målvekter
	local mSving = (fest and luft and not ragdoll) and 1 or 0
	local mFly = (luft and not fest and not ragdoll) and math.clamp((fart.Magnitude - 25) / 45, 0, 1) or 0
	local mBaer = (baerer and not ragdoll) and 1 or 0
	local mEmote = (emote and not ragdoll and not luft) and 1 or 0
	local mRag = ragdoll and 1 or 0
	V.sving = naerme(V.sving, mSving, 12, dt)
	V.fly = naerme(V.fly, mFly * (1 - mSving), 6, dt)
	V.baer = naerme(V.baer, mBaer, 10, dt)
	V.emote = naerme(V.emote, mEmote, 8, dt)
	V.ragdoll = naerme(V.ragdoll, mRag, ragdoll and 25 or 4, dt)
	local t = naa + st.fase
	-- 1. fly og sving
	if V.fly > 0.01 then
		brukPositur(st, flyPositur(st, fart, t), V.fly)
	end
	if V.sving > 0.01 and fest then
		brukPositur(st, svingPositur(st, fest, fart, t), V.sving)
	end
	-- 2. bære (og snappet når du tar noe)
	if V.baer > 0.01 then
		local gaar = st.hum.MoveDirection.Magnitude > 0.1
		local p = baerPositur(t, gaar)
		if st.snapp and naa - st.snapp < 0.4 then
			local s = (naa - st.snapp) / 0.4
			brukPositur(st, p, V.baer)
			brukPositur(st, snappPositur(), 1 - myk(s))
		else
			-- under svinging holder krok-armen tauet, den andre holder lasten
			if V.sving > 0.5 then
				p.RShoulder, p.RElbow = nil, nil
			end
			brukPositur(st, p, V.baer)
		end
	end
	-- 3. emote
	if V.emote > 0.01 then
		local f = EMOTER[emote or st.sistEmote]
		if emote then
			st.sistEmote = emote
		end
		if f then
			brukPositur(st, f(servertid - (m:GetAttribute("EmoteTid") or servertid)), V.emote)
		end
		-- egen figur: begynner du å gå eller hoppe, stopper feiringen
		if st.egen and emote and (st.hum.MoveDirection.Magnitude > 0.1 or luft) and not st.stoppSendt then
			st.stoppSendt = true
			remotes.Handling:FireServer("emote", nil)
			task.delay(0.5, function()
				st.stoppSendt = false
			end)
		end
	end
	-- 4. superhelt-landing
	if st.landing then
		local lt = naa - st.landing.start
		local varighet = 0.95
		if lt > varighet then
			st.landing = nil
		elseif not luft then
			local w = lt < 0.06 and lt / 0.06 or (lt < 0.55 and 1 or 1 - myk((lt - 0.55) / 0.4))
			local opp = myk((lt - 0.3) / 0.4)
			brukPositur(st, landingPositur(st.landing.styrke, opp), w)
		end
	end
	-- 5. salto/skru
	if st.salto then
		local lt = naa - st.salto.start
		local varighet = 0.62
		if lt > varighet then
			st.salto = nil
		else
			local e = myk(lt / varighet)
			if st.salto.type == "skru" then
				brukPositur(st, skruPositur(e), 1)
				leggTil(st, "Root", A(0, -360 * e, 0))
			else
				brukPositur(st, saltoTuck(e), 1)
				leggTil(st, "Root", A(-360 * e, 0, 0))
			end
		end
	end
	-- 6. filledukke
	if V.ragdoll > 0.01 then
		local igjen = math.clamp((ragdollTil - servertid) / 1.5, 0, 1)
		brukPositur(st, ragdollPositur(st, t, igjen), V.ragdoll)
	end
	-- 7. svimmel: hodet går i ring + stjerner
	local svimmel = svimmelTil > servertid and not ragdoll
	if svimmel then
		local s = math.clamp(svimmelTil - servertid, 0, 1)
		leggTil(st, "Neck", A(12 * s * math.sin(t * 6), 0, 12 * s * math.cos(t * 6)))
		leggTil(st, "Waist", A(5 * s * math.sin(t * 3), 0, 6 * s * math.cos(t * 3)))
	end
	stjerner(st, svimmel or ragdoll)
	if st.stjerner then
		for n, g in st.stjerner do
			local a = t * 4 + n * (math.pi * 2 / 3)
			g.StudsOffsetWorldSpace = Vector3.new(math.cos(a) * 1.3, 1.4 + 0.2 * math.sin(t * 5 + n), math.sin(a) * 1.3)
		end
	end
	-- lysspor fra hendene i høy fart
	local fort = fart.Magnitude > 70
	for _, tr in st.spor do
		if tr.Enabled ~= fort then
			tr.Enabled = fort
		end
	end
end

-- ---------------------------------------------------------------- hendelser utenfra

local function finn(figur)
	return figur and figurer[figur]
end

function Positurer.triks(figur, type_)
	local st = finn(figur)
	if st then
		st.salto = { start = os.clock(), type = type_ == "skru" and "skru" or "salto" }
	end
end

function Positurer.landing(figur, styrke)
	local st = finn(figur)
	if st and styrke and styrke > 0.42 then
		st.landing = { start = os.clock(), styrke = math.clamp(styrke, 0, 1) }
	end
end

function Positurer.tilstand(figur)
	return finn(figur)
end

function Positurer.start(grappler, tau, rem)
	Grappler, Tau, remotes = grappler, tau, rem
	local function nyFigur(p, f)
		task.spawn(registrer, f, p)
	end
	local function spillerInn(p)
		p.CharacterAdded:Connect(function(f)
			nyFigur(p, f)
		end)
		if p.Character then
			nyFigur(p, p.Character)
		end
	end
	Players.PlayerAdded:Connect(spillerInn)
	for _, p in Players:GetPlayers() do
		spillerInn(p)
	end
	RunService.Stepped:Connect(function(_, dt)
		local naa = os.clock()
		local servertid = workspace:GetServerTimeNow()
		local kamera = workspace.CurrentCamera
		for _, st in figurer do
			-- bare figurer i nærheten (ytelse)
			if st.egen or (st.rot.Position - kamera.CFrame.Position).Magnitude < 260 then
				local ok, feil = pcall(stegFigur, st, dt, naa, servertid)
				if not ok and not st.feilVist then
					st.feilVist = true
					warn("[Positurer] " .. tostring(feil))
				end
			end
		end
	end)
	-- triks og landinger fra andre spillere (via serveren)
	ReplicatedStorage:WaitForChild("Remotes").Hendelse.OnClientEvent:Connect(function(type_, p, a)
		if type_ == "triks" and p and p.Character then
			Positurer.triks(p.Character, a)
		elseif type_ == "landing" and p and p.Character then
			Positurer.landing(p.Character, a)
		end
	end)
end

return Positurer
