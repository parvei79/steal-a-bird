-- Vinduene: SHOP (oppgraderinger), INDEX (samleboka med alle fuglene) og DANCE (feiringer).
-- Tastene F, G og B (og knappene til venstre) åpner dem. Mens et vindu er åpent, er musepekeren fri
-- og kroken skyter ikke.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Fugler = require(Shared:WaitForChild("Fugler"))
local UI = require(script.Parent:WaitForChild("UI"))
local Klientdata = require(script.Parent:WaitForChild("Klientdata"))

local Menyer = {}

local F = UI.FARGER
local HUD, Kamera, Grappler, remotes
local vinduer = {}  -- [navn] = Frame
local aapent = nil
Menyer.vedApning = {} -- [navn] = funksjon (oppdater innholdet når vinduet åpnes)

local function oppdaterMus()
	Kamera.fri = aapent ~= nil or HUD.markor == true
	Grappler.laast = aapent ~= nil
end

function Menyer.lukk()
	if aapent and vinduer[aapent] then
		vinduer[aapent].Visible = false
	end
	aapent = nil
	oppdaterMus()
end

function Menyer.aapne(navn)
	if aapent == navn then
		Menyer.lukk()
		return
	end
	Menyer.lukk()
	local v = vinduer[navn]
	if not v then
		return
	end
	aapent = navn
	if Menyer.vedApning[navn] then
		Menyer.vedApning[navn]()
	end
	v.Visible = true
	UI.sprett(v)
	oppdaterMus()
end

function Menyer.registrer(navn, vindu)
	vinduer[navn] = vindu
end

function Menyer.aapent()
	return aapent
end

-- ---------------------------------------------------------------- SHOP

local function lagButikk(skjerm)
	local v = UI.vindu("Shop", "🛒 SHOP — Upgrades", UDim2.fromOffset(560, 470), skjerm, Menyer.lukk)
	local liste = UI.ny("Frame", { Position = UDim2.fromOffset(14, 62), Size = UDim2.new(1, -28, 1, -76),
		BackgroundTransparency = 1 }, v)
	UI.ny("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, liste)
	local rader = {}
	for i, o in Config.OPPGRADERINGER do
		local rad = UI.rund(UI.ny("Frame", { Size = UDim2.new(1, 0, 0, 72), BackgroundColor3 = F.panel2, LayoutOrder = i,
			BorderSizePixel = 0 }, liste), 12)
		local navn = UI.tekst({ Position = UDim2.fromOffset(12, 6), Size = UDim2.new(0.6, 0, 0, 30), Text = o.navn,
			TextXAlignment = Enum.TextXAlignment.Left }, rad)
		local info = UI.tekst({ Position = UDim2.fromOffset(12, 38), Size = UDim2.new(0.62, 0, 0, 24), Text = o.tekst,
			TextColor3 = Color3.fromRGB(190, 200, 225), TextXAlignment = Enum.TextXAlignment.Left }, rad)
		local kjop = UI.knapp({ AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0),
			Size = UDim2.fromOffset(160, 52), Text = "" }, rad, function()
			remotes.Handling:FireServer("oppgrader", o.id)
		end)
		rader[o.id] = { navn = navn, info = info, kjop = kjop, o = o }
	end
	local function verdi(o, n)
		local x = o.verdier[n + 1]
		if o.prosent then
			return math.floor(x * 100 + 0.5) .. "%"
		end
		return tostring(x) .. (o.enhet or "")
	end
	local function oppdater(st)
		for id, r in rader do
			local n = (st.oppgr or {})[id] or 0
			local o = r.o
			r.navn.Text = string.format("%s  %s", o.navn, string.rep("●", n) .. string.rep("○", #o.priser - n))
			if n >= #o.priser then
				r.info.Text = "MAX: " .. verdi(o, n)
				r.kjop.Text = "MAXED"
				r.kjop.BackgroundColor3 = F.gra
			else
				r.info.Text = verdi(o, n) .. "  ➜  " .. verdi(o, n + 1)
				local pris = o.priser[n + 1]
				r.kjop.Text = Fugler.penger(pris)
				r.kjop.BackgroundColor3 = (st.penger or 0) >= pris and F.gronn or F.gra
			end
		end
	end
	Klientdata.lytt(oppdater)
	Menyer.registrer("Shop", v)
end

-- ---------------------------------------------------------------- INDEX

local function lagIndex(skjerm)
	local v = UI.vindu("Index", "📖 BIRD INDEX", UDim2.fromOffset(760, 520), skjerm, Menyer.lukk)
	local teller = UI.tekst({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -70, 0, 14), Size = UDim2.fromOffset(220, 32),
		Text = "", TextColor3 = F.gul, TextXAlignment = Enum.TextXAlignment.Right }, v)
	local rulle = UI.ny("ScrollingFrame", { Position = UDim2.fromOffset(14, 62), Size = UDim2.new(1, -28, 1, -76),
		BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 8, AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new() }, v)
	UI.ny("UIGridLayout", { CellSize = UDim2.fromOffset(170, 96), CellPadding = UDim2.fromOffset(10, 10),
		SortOrder = Enum.SortOrder.LayoutOrder }, rulle)
	local kort = {}
	for i, a in Fugler.ARTER do
		local sj = Fugler.SJ[a.sj]
		local k = UI.rund(UI.ny("Frame", { BackgroundColor3 = F.panel2, LayoutOrder = i, BorderSizePixel = 0 }, rulle), 12)
		UI.ny("UIStroke", { Thickness = 3, Color = sj.farge }, k)
		local navn = UI.tekst({ Position = UDim2.fromOffset(6, 6), Size = UDim2.new(1, -12, 0, 28), Text = "???" }, k)
		local sjT = UI.tekst({ Position = UDim2.fromOffset(6, 34), Size = UDim2.new(1, -12, 0, 20), Text = a.sj,
			TextColor3 = sj.farge }, k)
		local mut = UI.tekst({ Position = UDim2.fromOffset(6, 58), Size = UDim2.new(1, -12, 0, 30), Text = "" }, k)
		kort[a.id] = { navn = navn, sj = sjT, mut = mut, a = a, k = k }
	end
	local function oppdater(st)
		local idx = st.index or {}
		local funnet = 0
		for id, k in kort do
			local side = idx[id]
			if side then
				funnet += 1
				k.navn.Text = k.a.navn
				k.navn.TextColor3 = F.hvit
				local m = {}
				for _, mu in Fugler.MUTASJONER do
					table.insert(m, side[mu.id] and "✦" or "·")
				end
				k.mut.Text = table.concat(m, " ")
				k.mut.TextColor3 = F.gul
				k.k.BackgroundColor3 = F.panel2
			else
				k.navn.Text = k.a.sj == "Secret" and "??? (Secret)" or "???"
				k.navn.TextColor3 = F.gra
				k.mut.Text = ""
				k.k.BackgroundColor3 = Color3.fromRGB(30, 32, 44)
			end
		end
		teller.Text = string.format("Found %d / %d", funnet, #Fugler.ARTER)
	end
	Klientdata.lytt(oppdater)
	Menyer.registrer("Index", v)
end

-- ---------------------------------------------------------------- DANCE

local DANSER = {
	{ "ChickenDance", "🐔 Chicken Dance", F.gul },
	{ "Wave", "👋 Wave", F.bla },
	{ "Flex", "💪 Flex", F.rod },
	{ "Victory", "🏆 Victory", F.gronn },
}

local function dans(navn)
	remotes.Handling:FireServer("emote", navn)
	Menyer.lukk()
end
Menyer.dans = dans

local function lagDans(skjerm)
	local v = UI.vindu("Dance", "💃 DANCE", UDim2.fromOffset(380, 330), skjerm, Menyer.lukk)
	local liste = UI.ny("Frame", { Position = UDim2.fromOffset(14, 62), Size = UDim2.new(1, -28, 1, -76),
		BackgroundTransparency = 1 }, v)
	UI.ny("UIGridLayout", { CellSize = UDim2.fromOffset(170, 110), CellPadding = UDim2.fromOffset(10, 10) }, liste)
	for i, d in DANSER do
		UI.knapp({ Text = d[2] .. (UserInputService.KeyboardEnabled and ("\n[" .. i .. "]") or ""), BackgroundColor3 = d[3],
			LayoutOrder = i }, liste, function()
			dans(d[1])
		end)
	end
	Menyer.registrer("Dance", v)
end

function Menyer.start(hud, kamera, grappler, rem)
	HUD, Kamera, Grappler, remotes = hud, kamera, grappler, rem
	local skjerm = HUD.skjerm
	lagButikk(skjerm)
	lagIndex(skjerm)
	lagDans(skjerm)
	HUD.knappTrykk = function(navn)
		Menyer.aapne(navn)
	end
	local TASTER = { [Enum.KeyCode.F] = "Shop", [Enum.KeyCode.G] = "Index", [Enum.KeyCode.T] = "Trade",
		[Enum.KeyCode.B] = "Dance" }
	UserInputService.InputBegan:Connect(function(input, behandlet)
		if behandlet then
			return
		end
		local navn = TASTER[input.KeyCode]
		if navn then
			Menyer.aapne(navn)
		elseif input.KeyCode == Enum.KeyCode.Escape then
			Menyer.lukk()
		elseif input.KeyCode == Enum.KeyCode.LeftAlt or input.KeyCode == Enum.KeyCode.LeftControl then
			task.defer(oppdaterMus)
		else
			-- 1–4: dans direkte
			for i, d in DANSER do
				if input.KeyCode == Enum.KeyCode[({ "One", "Two", "Three", "Four" })[i]] then
					dans(d[1])
				end
			end
		end
	end)
	remotes.Hendelse.OnClientEvent:Connect(function(type_)
		if type_ == "oppgradert" and aapent == "Shop" then
			UI.sprett(vinduer.Shop)
		end
	end)
end

return Menyer
