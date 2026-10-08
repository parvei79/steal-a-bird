-- Skjermbildet:
--   * siktet midt på skjermen (grønt når kroken når fram, rødt mot spillere)
--   * pengene øverst (teller opp) og inntekt per sekund
--   * knapper: SHOP, INDEX, TRADE og DANCE (og tastene F, G, T, B)
--   * meldinger, røde feilmeldinger og store bannere (sjeldne egg, klekking, tyverier)
--   * ALARM når noen stjeler fra deg: rød skjermkant, sirene og en pil mot tyven
--   * mens du bærer noe: en grønn pil hjem til basen
--   * status for basen: låst, nybegynnerskjold
--   * musikk og fuglesang i bakgrunnen
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local Debris = game:GetService("Debris")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Fugler = require(Shared:WaitForChild("Fugler"))
local Kart = require(Shared:WaitForChild("Kart"))
local UI = require(script.Parent:WaitForChild("UI"))
local Klientdata = require(script.Parent:WaitForChild("Klientdata"))

local HUD = {}

local spiller = Players.LocalPlayer
local Grappler, Kamera
local F = UI.FARGER
local mobil = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local skjerm = UI.ny("ScreenGui", { Name = "FuglHUD", ResetOnSpawn = false, IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling })
HUD.skjerm = skjerm

-- ---------------------------------------------------------------- siktet
local sikte = UI.ny("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(34, 34), BackgroundTransparency = 1 }, skjerm)
local ringRamme = UI.rund(UI.ny("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, sikte), 100)
local ring = UI.ny("UIStroke", { Thickness = 2.5, Color = F.hvit }, ringRamme)
local prikk = UI.rund(UI.ny("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(6, 6), BackgroundColor3 = F.hvit, BorderSizePixel = 0 }, sikte), 100)
local avstand = UI.tekst({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.5, 24),
	Size = UDim2.fromOffset(120, 20), Text = "" }, skjerm)

-- ---------------------------------------------------------------- penger
local pengePanel = UI.panel({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 10),
	Size = UDim2.fromOffset(250, 78), BackgroundColor3 = Color3.fromRGB(24, 28, 44), BackgroundTransparency = 0.15 }, skjerm)
local pengeTekst = UI.tekst({ Size = UDim2.new(1, -16, 0, 46), Position = UDim2.fromOffset(8, 4), Text = "$0",
	TextColor3 = F.penger }, pengePanel)
local inntektTekst = UI.tekst({ Size = UDim2.new(1, -16, 0, 22), Position = UDim2.fromOffset(8, 50), Text = "+$0/s",
	TextColor3 = Color3.fromRGB(200, 255, 210) }, pengePanel)
local pengeSkala = UI.ny("UIScale", {}, pengePanel)
local visPenger = 0

-- ---------------------------------------------------------------- basestatus og hjelp
local baseTekst = UI.tekst({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 92),
	Size = UDim2.fromOffset(420, 24), Text = "", TextColor3 = Color3.fromRGB(150, 230, 255) }, skjerm)
local hendelseTekst = UI.tekst({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 12),
	Size = UDim2.fromOffset(330, 26), Text = "", TextXAlignment = Enum.TextXAlignment.Right,
	TextColor3 = Color3.fromRGB(255, 230, 140) }, skjerm)
local luckTekst = UI.tekst({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 40),
	Size = UDim2.fromOffset(330, 24), Text = "", TextXAlignment = Enum.TextXAlignment.Right,
	TextColor3 = Color3.fromRGB(120, 255, 140) }, skjerm)
local HENDELSE_NAVN = { GoldenRain = "🥚 Golden Egg Rain", CosmicNight = "🌙 Cosmic Night", Storm = "⛈️ Storm",
	Meteor = "☄️ Meteor Egg" }
local sesongTekst = UI.tekst({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 66),
	Size = UDim2.fromOffset(330, 22), Text = "", TextXAlignment = Enum.TextXAlignment.Right,
	TextColor3 = Color3.fromRGB(255, 150, 40) }, skjerm)
local function klokke(sek)
	sek = math.max(0, math.ceil(sek))
	return string.format("%d:%02d", math.floor(sek / 60), sek % 60)
end
local hjelp = UI.tekst({ AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -10),
	Size = UDim2.fromOffset(980, 22), TextTransparency = 0.1,
	Text = "HOLD LEFT MOUSE: hook  •  RELEASE: fly  •  WASD: swing  •  SPACE: reel  •  Q: trick  •  E: buy / steal  •  ALT: cursor" }, skjerm)
if mobil then
	hjelp.Text = "Hold HOOK to swing • Release to fly • TRICK in the air • Drag right side to look"
end
local baereTekst = UI.tekst({ AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -110),
	Size = UDim2.fromOffset(560, 34), Text = "", TextColor3 = Color3.fromRGB(140, 255, 160), Visible = false }, skjerm)

-- ---------------------------------------------------------------- knapper til venstre
local knapper = UI.ny("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 12, 0.5, 0),
	Size = UDim2.fromOffset(120, 300), BackgroundTransparency = 1 }, skjerm)
UI.ny("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, knapper)
HUD.knappTrykk = nil -- funksjon(navn) settes av Menyer
local function hudKnapp(navn, tekst, farge, nr)
	return UI.knapp({ Name = navn, Size = UDim2.fromOffset(120, 56), Text = tekst, BackgroundColor3 = farge, LayoutOrder = nr },
		knapper, function()
			if HUD.knappTrykk then
				HUD.knappTrykk(navn)
			end
		end)
end
hudKnapp("Shop", mobil and "🛒 SHOP" or "🛒 SHOP [F]", F.gronn, 1)
hudKnapp("Index", mobil and "📖 INDEX" or "📖 INDEX [G]", F.bla, 2)
hudKnapp("Trade", mobil and "🤝 TRADE" or "🤝 TRADE [T]", F.gul, 3)
hudKnapp("Dance", mobil and "💃 DANCE" or "💃 DANCE [B]", F.lilla, 4)

-- Testpanel (bare i Studio): start hendelsene med en gang i stedet for å vente
if game:GetService("RunService"):IsStudio() then
	local panel = UI.panel({ AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(170, 330), BackgroundTransparency = 0.25 }, skjerm)
	UI.tekst({ Position = UDim2.fromOffset(8, 4), Size = UDim2.new(1, -16, 0, 24), Text = "🧪 TEST (Studio)" }, panel)
	local liste = UI.ny("Frame", { Position = UDim2.fromOffset(8, 32), Size = UDim2.new(1, -16, 1, -40),
		BackgroundTransparency = 1 }, panel)
	UI.ny("UIListLayout", { Padding = UDim.new(0, 5) }, liste)
	for _, k in { { "GoldenRain", "🥚 Golden Rain" }, { "Storm", "⛈️ Storm" }, { "CosmicNight", "🌙 Cosmic Night" },
		{ "Meteor", "☄️ Meteor" }, { "spooky", "🎃 Spooky Egg" }, { "secret", "✨ Secret Egg" }, { "penger", "💰 +$1M" } } do
		UI.knapp({ Size = UDim2.new(1, 0, 0, 36), Text = k[2], BackgroundColor3 = F.panel2 }, liste, function()
			game:GetService("ReplicatedStorage").Remotes.Handling:FireServer("test", k[1])
		end)
	end
end

-- ---------------------------------------------------------------- meldinger og bannere
local strom = UI.ny("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 122),
	Size = UDim2.fromOffset(700, 200), BackgroundTransparency = 1 }, skjerm)
UI.ny("UIListLayout", { HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder,
	Padding = UDim.new(0, 4) }, strom)
local nr = 0
function HUD.melding(t, farge, varighet)
	nr += 1
	local m = UI.tekst({ Size = UDim2.fromOffset(700, 26), Text = t, LayoutOrder = nr, TextColor3 = farge or F.hvit,
		TextStrokeTransparency = 0.1 }, strom)
	task.delay(varighet or 5, function()
		if m.Parent then
			TweenService:Create(m, TweenInfo.new(0.6), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
			Debris:AddItem(m, 0.7)
		end
	end)
	local barn = 0
	for _, b in strom:GetChildren() do
		if b:IsA("TextLabel") then
			barn += 1
		end
	end
	if barn > 6 then
		for _, b in strom:GetChildren() do
			if b:IsA("TextLabel") then
				b:Destroy()
				break
			end
		end
	end
end

function HUD.feil(t)
	HUD.melding("⚠️ " .. t, Color3.fromRGB(255, 110, 100), 3)
end

local banner = UI.tekst({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.3),
	Size = UDim2.fromOffset(900, 64), Text = "", Visible = false, TextStrokeTransparency = 0 }, skjerm)
local bannerSkala = UI.ny("UIScale", {}, banner)
local bannerNr = 0
function HUD.banner(t, farge, varighet)
	bannerNr += 1
	local mitt = bannerNr
	banner.Text = t
	banner.TextColor3 = farge or F.gul
	banner.Visible = true
	banner.TextTransparency = 0
	banner.TextStrokeTransparency = 0
	bannerSkala.Scale = 0.3
	TweenService:Create(bannerSkala, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	task.delay(varighet or 3, function()
		if bannerNr == mitt then
			TweenService:Create(banner, TweenInfo.new(0.5), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		end
	end)
end

-- ---------------------------------------------------------------- alarm og piler
local kanter = {}
for i, e in { { UDim2.fromScale(0, 0), UDim2.new(1, 0, 0, 40) }, { UDim2.new(0, 0, 1, -40), UDim2.new(1, 0, 0, 40) },
	{ UDim2.fromScale(0, 0), UDim2.new(0, 40, 1, 0) }, { UDim2.new(1, -40, 0, 0), UDim2.new(0, 40, 1, 0) } } do
	kanter[i] = UI.ny("Frame", { Position = e[1], Size = e[2], BackgroundColor3 = Color3.fromRGB(255, 30, 30),
		BackgroundTransparency = 1, BorderSizePixel = 0 }, skjerm)
end
local alarmTil = 0
local tyv = nil

local function pil(farge)
	return UI.tekst({ AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(64, 64), Text = "➤", TextColor3 = farge,
		Visible = false, TextStrokeTransparency = 0 }, skjerm)
end
local tyvPil = pil(Color3.fromRGB(255, 60, 60))
local hjemPil = pil(Color3.fromRGB(90, 255, 120))
local maalPil = pil(Color3.fromRGB(255, 220, 60))
local meteorPil = pil(Color3.fromRGB(255, 110, 40))

-- veiledning for nye spillere (øverst til venstre)
local MAAL = {
	"🥚 Buy an egg at the Nest in the middle",
	"🏠 Carry the egg home to your base",
	"💰 Stand on COLLECT to get your cash",
	"😈 Steal a bird from another base (hold E)!",
}
local maalPanel = UI.panel({ Position = UDim2.fromOffset(12, 12), Size = UDim2.fromOffset(330, 74),
	BackgroundTransparency = 0.2, Visible = false }, skjerm)
local maalTittel = UI.tekst({ Position = UDim2.fromOffset(10, 4), Size = UDim2.new(1, -20, 0, 24), Text = "GOAL 1/4",
	TextColor3 = Color3.fromRGB(255, 220, 60), TextXAlignment = Enum.TextXAlignment.Left }, maalPanel)
local maalTekst = UI.tekst({ Position = UDim2.fromOffset(10, 30), Size = UDim2.new(1, -20, 0, 36), Text = "", TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left }, maalPanel)
local sistMaal = nil

-- Pil langs skjermkanten som peker mot et punkt i verden (skjules når punktet er midt på skjermen).
local function pekPaa(p, pos)
	if not pos then
		p.Visible = false
		return
	end
	local kam = workspace.CurrentCamera
	local vp = kam.ViewportSize
	local sp, foran = kam:WorldToViewportPoint(pos)
	local midt = Vector2.new(vp.X / 2, vp.Y / 2)
	local d = Vector2.new(sp.X, sp.Y) - midt
	if foran and sp.Z > 0 and math.abs(d.X) < vp.X * 0.38 and math.abs(d.Y) < vp.Y * 0.36 then
		p.Visible = false
		return
	end
	if sp.Z < 0 then
		d = -d
	end
	if d.Magnitude < 1 then
		d = Vector2.new(0, -1)
	end
	local r = Vector2.new(vp.X * 0.42, vp.Y * 0.38)
	local u = d.Unit
	local skala = math.min(r.X / math.max(math.abs(u.X), 1e-3), r.Y / math.max(math.abs(u.Y), 1e-3))
	local q = midt + u * skala
	p.Position = UDim2.fromOffset(q.X, q.Y)
	p.Rotation = math.deg(math.atan2(u.Y, u.X))
	p.Visible = true
end

function HUD.alarm(tyvSpiller, navn)
	alarmTil = os.clock() + 6
	tyv = tyvSpiller
	HUD.banner(string.format("🚨 %s IS STEALING YOUR %s! 🚨", string.upper(tyvSpiller.DisplayName), string.upper(navn)),
		Color3.fromRGB(255, 70, 60), 4)
end

-- ---------------------------------------------------------------- oppdatering

local GRONN = Color3.fromRGB(90, 255, 120)
local ROD = Color3.fromRGB(255, 70, 60)
local GRA = Color3.fromRGB(200, 200, 200)

local function oppdater(dt)
	-- sikte
	local sikt = Grappler.sikt()
	local s = Grappler.tilstand()
	local farge = GRA
	if sikt and sikt.treff and sikt.innenfor then
		farge = sikt.motstander and ROD or GRONN
	end
	ring.Color = farge
	prikk.BackgroundColor3 = farge
	sikte.Size = s.krok == "fest" and UDim2.fromOffset(24, 24) or UDim2.fromOffset(34, 34)
	sikte.Visible = not Kamera.fri
	if sikt and sikt.treff and not Kamera.fri then
		avstand.Text = sikt.innenfor and string.format("%d", math.floor(sikt.avstand)) or "too far"
		avstand.TextColor3 = farge
	else
		avstand.Text = ""
	end
	-- penger som teller opp
	local st = Klientdata.status
	local maal = st.penger or 0
	if math.abs(maal - visPenger) < 1 then
		visPenger = maal
	else
		visPenger += (maal - visPenger) * math.min(1, dt * 8)
	end
	pengeTekst.Text = Fugler.penger(visPenger)
	inntektTekst.Text = "+" .. Fugler.penger(st.inntekt or 0) .. "/s"
	-- basestatus
	local servertid = workspace:GetServerTimeNow()
	if (st.laastTil or 0) > servertid then
		baseTekst.Text = string.format("🔒 Your base is locked: %ds", math.ceil(st.laastTil - servertid))
	elseif (st.skjoldTil or 0) > servertid then
		local igjen = math.ceil(st.skjoldTil - servertid)
		baseTekst.Text = string.format("🛡️ New player shield: %d:%02d", math.floor(igjen / 60), igjen % 60)
	elseif st.base then
		baseTekst.Text = "🔓 Base unlocked — press LOCK at home to protect it"
	else
		baseTekst.Text = ""
	end
	-- hendelser og server luck
	local hendelse = workspace:GetAttribute("Hendelse")
	if hendelse then
		hendelseTekst.Text = string.format("%s NOW! %s", string.upper(HENDELSE_NAVN[hendelse] or hendelse),
			klokke((workspace:GetAttribute("HendelseSlutt") or servertid) - servertid))
		hendelseTekst.TextColor3 = hendelse == "CosmicNight" and Color3.fromRGB(160, 230, 255) or Color3.fromRGB(255, 215, 60)
	else
		local neste = workspace:GetAttribute("NesteHendelse")
		hendelseTekst.Text = neste and string.format("%s in %s", HENDELSE_NAVN[neste] or neste,
			klokke((workspace:GetAttribute("NesteHendelseTid") or servertid) - servertid)) or ""
		hendelseTekst.TextColor3 = Color3.fromRGB(255, 240, 200)
	end
	-- meteoren: nedtelling og pil mot nedslagsstedet
	local meteorTid = workspace:GetAttribute("MeteorTid")
	local meteorMaal = workspace:GetAttribute("MeteorMaal")
	if meteorTid and meteorTid > servertid and typeof(meteorMaal) == "Vector3" then
		hendelseTekst.Text = "☄️ METEOR LANDS IN " .. klokke(meteorTid - servertid)
		hendelseTekst.TextColor3 = Color3.fromRGB(255, 140, 60)
		pekPaa(meteorPil, meteorMaal)
	else
		meteorPil.Visible = false
	end
	sesongTekst.Text = workspace:GetAttribute("Sesong") == "Halloween" and "🎃 HALLOWEEN — Spooky Eggs on the conveyor!" or ""
	local luck = workspace:GetAttribute("LuckTil")
	luckTekst.Text = (luck and luck > servertid) and ("🍀 SERVER LUCK x2  " .. klokke(luck - servertid)) or ""
	-- veiledning: mål og gul pil
	local maal = st.veiledning or 5
	if st.base and maal <= #MAAL then
		maalPanel.Visible = true
		maalTittel.Text = string.format("GOAL %d/%d", maal, #MAAL)
		maalTekst.Text = MAAL[maal]
		if sistMaal and sistMaal ~= maal then
			UI.sprett(maalPanel)
		end
		local mal = nil
		local fig = spiller.Character
		if maal == 1 then
			mal = Vector3.new(Kart.REIR.x, Kart.REIR.topp + 2, Kart.REIR.z)
		elseif maal == 3 then
			mal = Kart.pengeplate(st.base).Position
		elseif maal == 4 and not (fig and fig:GetAttribute("Baerer")) then
			-- nærmeste base med en fugl som ikke er låst
			local rot = fig and fig:FindFirstChild("HumanoidRootPart")
			local best
			for _, m in workspace:WaitForChild("Ting"):GetChildren() do
				local b = m:GetAttribute("Base")
				if b and b ~= st.base and b > 0 and m:GetAttribute("Tilstand") == "plass" and rot then
					local p = m.PrimaryPart and m.PrimaryPart.Position
					if p and (not best or (p - rot.Position).Magnitude < (best - rot.Position).Magnitude) then
						best = p
					end
				end
			end
			mal = best
		end
		pekPaa(maalPil, mal)
	else
		maalPanel.Visible = false
		maalPil.Visible = false
		if sistMaal and sistMaal <= #MAAL and maal > #MAAL then
			HUD.banner("🏆 You know how it works! Now get RICH! 🏆", Color3.fromRGB(255, 220, 60), 3)
		end
	end
	sistMaal = maal
	-- bærer du noe? pil hjem
	local figur = spiller.Character
	local baerer = figur and figur:GetAttribute("Baerer")
	if baerer and st.base then
		baereTekst.Visible = true
		baereTekst.Text = figur:GetAttribute("Tyv") and "🏃 RUN HOME with your loot!" or "🏠 Bring it home to your base!"
		pekPaa(hjemPil, Kart.lokal(st.base, 0, 0, 4))
	else
		baereTekst.Visible = false
		hjemPil.Visible = false
	end
	-- alarm: blinkende rød kant og pil mot tyven
	local naa = os.clock()
	local alarm = naa < alarmTil
	local blink = alarm and (0.55 + 0.35 * math.sin(naa * 14)) or 1
	for _, k in kanter do
		k.BackgroundTransparency = blink
	end
	local tyvRot = alarm and tyv and tyv.Character and tyv.Character:FindFirstChild("HumanoidRootPart")
	if tyvRot and tyv.Character:GetAttribute("Tyv") then
		pekPaa(tyvPil, tyvRot.Position)
	else
		tyvPil.Visible = false
		if alarm and tyv and not (tyv.Character and tyv.Character:GetAttribute("Tyv")) then
			alarmTil = 0
		end
	end
end

function HUD.pengerSprett()
	pengeSkala.Scale = 1.18
	TweenService:Create(pengeSkala, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end

-- Hvor pengene står på skjermen (mynter flyr dit).
function HUD.pengePos()
	local p = pengePanel.AbsolutePosition
	local s = pengePanel.AbsoluteSize
	return Vector2.new(p.X + s.X / 2, p.Y + s.Y / 2)
end

function HUD.start(grappler, kamera, remotes)
	Grappler, Kamera = grappler, kamera
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
	end)
	skjerm.Parent = spiller:WaitForChild("PlayerGui")
	remotes.Hendelse.OnClientEvent:Connect(function(type_, a, b)
		if type_ == "melding" then
			HUD.melding(a, b)
		elseif type_ == "feil" then
			HUD.feil(a)
		elseif type_ == "alarm" then
			HUD.alarm(a, b)
		end
	end)
	-- ALT (eller Ctrl) gir fri musepeker, så du kan trykke på knappene
	UserInputService.InputBegan:Connect(function(input, behandlet)
		if behandlet then
			return
		end
		if input.KeyCode == Enum.KeyCode.LeftAlt or input.KeyCode == Enum.KeyCode.LeftControl then
			Kamera.fri = not Kamera.fri
			HUD.markor = Kamera.fri
		end
	end)
	task.delay(40, function()
		TweenService:Create(hjelp, TweenInfo.new(2), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	end)
	RunService.RenderStepped:Connect(oppdater)
	Klientdata.lytt(function(st, forrige)
		if forrige and (st.penger or 0) > (forrige.penger or 0) then
			HUD.pengerSprett()
		end
	end)

	-- musikk og fuglesang (🔊-knappen nede til venstre skrur musikken av og på)
	local musikk = UI.ny("Sound", { Volume = 0.18 }, workspace.CurrentCamera)
	local paa = true
	local lydKnapp
	lydKnapp = UI.knapp({ AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 12, 1, -12), Size = UDim2.fromOffset(56, 48),
		Text = "🔊", BackgroundColor3 = UI.FARGER.panel2 }, skjerm, function()
		paa = not paa
		musikk.Volume = paa and 0.18 or 0
		lydKnapp.Text = paa and "🔊" or "🔇"
	end)
	local n = 0
	local function neste()
		n = n % #Config.MUSIKK + 1
		musikk.SoundId = Config.MUSIKK[n]
		musikk.TimePosition = 0
		musikk:Play()
	end
	musikk.Ended:Connect(neste)
	neste()
	local sang = UI.ny("Sound", { SoundId = Config.LYD.fuglesang, Looped = true, Volume = 0.22 }, workspace.CurrentCamera)
	sang:Play()
end

return HUD
