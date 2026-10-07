-- Vinduene: SHOP (oppgraderinger), INDEX (samleboka med alle fuglene) og DANCE (feiringer).
-- Tastene F, G og B (og knappene til venstre) åpner dem. Mens et vindu er åpent, er musepekeren fri
-- og kroken skyter ikke.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Fugler = require(Shared:WaitForChild("Fugler"))
local ModelInfo = require(Shared:WaitForChild("ModelInfo"))
local MarketplaceService = game:GetService("MarketplaceService")
local UI = require(script.Parent:WaitForChild("UI"))
local Klientdata = require(script.Parent:WaitForChild("Klientdata"))
local Fuglebilde = require(script.Parent:WaitForChild("Fuglebilde"))

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

local function verdiTekst(o, n)
	local x = o.verdier[n + 1]
	if o.prosent then
		return math.floor(x * 100 + 0.5) .. "%"
	end
	return tostring(x) .. (o.enhet or "")
end

-- Sjansene for hver sjeldenhet på eggebåndet (vist i butikken, slik Roblox krever for betalt flaks).
local function sjanser(flaks)
	local sum, liste = 0, {}
	for _, sj in Fugler.SJELDENHETER do
		if sj.vekt > 0 and #Fugler.tilgjengelige(sj.id, function(a)
			return ModelInfo[a.modell] ~= nil
		end) > 0 then
			local v = sj.vekt * (sj.nr >= 3 and flaks or 1)
			sum += v
			table.insert(liste, { sj, v })
		end
	end
	local deler = {}
	for _, par in liste do
		table.insert(deler, string.format("%s %.1f%%", par[1].id, par[2] / sum * 100))
	end
	return table.concat(deler, "  •  ")
end

local function rad(forelder, nr, hoyde, farge)
	return UI.rund(UI.ny("Frame", { Size = UDim2.new(1, -8, 0, hoyde), BackgroundColor3 = farge or F.panel2, LayoutOrder = nr,
		BorderSizePixel = 0 }, forelder), 12)
end

local function lagButikk(skjerm)
	local v = UI.vindu("Shop", "🛒 SHOP", UDim2.fromOffset(620, 540), skjerm, Menyer.lukk)
	local sider = {}
	local faner = {}
	local function visSide(navn)
		for n, side in sider do
			side.Visible = n == navn
			faner[n].BackgroundColor3 = n == navn and F.gul or F.gra
		end
	end
	for i, f in { { "Upgrades", "⬆️ UPGRADES" }, { "Robux", "⭐ ROBUX" } } do
		faner[f[1]] = UI.knapp({ Position = UDim2.fromOffset(150 + (i - 1) * 170, 10), Size = UDim2.fromOffset(160, 42),
			Text = f[2] }, v, function()
			visSide(f[1])
		end)
		local side = UI.ny("ScrollingFrame", { Position = UDim2.fromOffset(14, 64), Size = UDim2.new(1, -28, 1, -78),
			BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 8, AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.new() }, v)
		UI.ny("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, side)
		sider[f[1]] = side
	end
	-- oppgraderinger
	local rader = {}
	for i, o in Config.OPPGRADERINGER do
		local r = rad(sider.Upgrades, i, 72)
		local navn = UI.tekst({ Position = UDim2.fromOffset(12, 6), Size = UDim2.new(0.62, 0, 0, 30), Text = o.navn,
			TextXAlignment = Enum.TextXAlignment.Left }, r)
		local info = UI.tekst({ Position = UDim2.fromOffset(12, 38), Size = UDim2.new(0.62, 0, 0, 24), Text = o.tekst,
			TextColor3 = Color3.fromRGB(190, 200, 225), TextXAlignment = Enum.TextXAlignment.Left }, r)
		local kjop = UI.knapp({ AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0),
			Size = UDim2.fromOffset(160, 52), Text = "" }, r, function()
			remotes.Handling:FireServer("oppgrader", o.id)
		end)
		rader[o.id] = { navn = navn, info = info, kjop = kjop, o = o }
	end
	-- rebirth (med «er du sikker?»)
	local rr = rad(sider.Upgrades, 100, 96, Color3.fromRGB(90, 70, 20))
	UI.tekst({ Position = UDim2.fromOffset(12, 6), Size = UDim2.new(0.62, 0, 0, 32), Text = "🌟 REBIRTH",
		TextColor3 = F.gul, TextXAlignment = Enum.TextXAlignment.Left }, rr)
	local rInfo = UI.tekst({ Position = UDim2.fromOffset(12, 40), Size = UDim2.new(0.64, 0, 0, 48), Text = "",
		TextColor3 = Color3.fromRGB(255, 240, 200), TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true }, rr)
	local sporsmaal
	local rKnapp = UI.knapp({ AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(160, 56), Text = "REBIRTH", BackgroundColor3 = F.gul }, rr, function()
		sporsmaal.Visible = true
		UI.sprett(sporsmaal)
	end)
	sporsmaal = UI.panel({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(440, 230),
		Visible = false, ZIndex = 5, BackgroundColor3 = Color3.fromRGB(60, 45, 20) }, v)
	UI.tekst({ Position = UDim2.fromOffset(14, 10), Size = UDim2.new(1, -28, 0, 130), TextWrapped = true, ZIndex = 5,
		Text = "Are you sure? You LOSE all your birds and cash.\nYou KEEP your upgrades and your Index.\nYour birds earn +50% more FOREVER!" }, sporsmaal)
	UI.knapp({ Position = UDim2.new(0, 14, 1, -62), Size = UDim2.fromOffset(200, 50), Text = "YES, REBIRTH!", ZIndex = 5,
		BackgroundColor3 = F.gul }, sporsmaal, function()
		sporsmaal.Visible = false
		remotes.Handling:FireServer("rebirth")
	end)
	UI.knapp({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 1, -62), Size = UDim2.fromOffset(170, 50), Text = "NO",
		ZIndex = 5, BackgroundColor3 = F.rod }, sporsmaal, function()
		sporsmaal.Visible = false
	end)
	-- Robux
	local robuxRader = {}
	local nr = 0
	local function robuxRad(e, erPass)
		nr += 1
		local r = rad(sider.Robux, nr, 72, erPass and F.panel2 or Color3.fromRGB(40, 70, 60))
		UI.tekst({ Position = UDim2.fromOffset(12, 6), Size = UDim2.new(0.62, 0, 0, 30), Text = (erPass and "⭐ " or "⚡ ") .. e.navn,
			TextXAlignment = Enum.TextXAlignment.Left }, r)
		UI.tekst({ Position = UDim2.fromOffset(12, 38), Size = UDim2.new(0.66, 0, 0, 26), Text = e.tekst, TextWrapped = true,
			TextColor3 = Color3.fromRGB(190, 200, 225), TextXAlignment = Enum.TextXAlignment.Left }, r)
		local id = erPass and e.passId or e.produktId
		local knapp = UI.knapp({ AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0),
			Size = UDim2.fromOffset(150, 52), Text = id > 0 and ("R$ " .. e.robux) or "Soon",
			BackgroundColor3 = id > 0 and Color3.fromRGB(40, 180, 90) or F.gra }, r, function()
			if id <= 0 then
				HUD.feil("Not for sale yet")
				return
			end
			local spiller = game:GetService("Players").LocalPlayer
			if erPass then
				MarketplaceService:PromptGamePassPurchase(spiller, id)
			else
				MarketplaceService:PromptProductPurchase(spiller, id)
			end
		end)
		robuxRader[e.id] = { knapp = knapp, erPass = erPass, id = id }
	end
	for _, e in Config.ROBUX.PASS do
		robuxRad(e, true)
	end
	for _, e in Config.ROBUX.PRODUKT do
		robuxRad(e, false)
	end
	nr += 1
	local odds = rad(sider.Robux, nr, 96, Color3.fromRGB(30, 34, 52))
	UI.tekst({ Position = UDim2.fromOffset(12, 4), Size = UDim2.new(1, -24, 0, 24), Text = "🥚 Egg odds on the conveyor",
		TextXAlignment = Enum.TextXAlignment.Left }, odds)
	local oddsTekst = UI.tekst({ Position = UDim2.fromOffset(12, 30), Size = UDim2.new(1, -24, 0, 60), TextWrapped = true,
		TextColor3 = Color3.fromRGB(200, 210, 235), TextXAlignment = Enum.TextXAlignment.Left, Text = "" }, odds)
	local function oppdater(st)
		for id, r in rader do
			local n = (st.oppgr or {})[id] or 0
			local o = r.o
			r.navn.Text = string.format("%s  %s", o.navn, string.rep("●", n) .. string.rep("○", #o.priser - n))
			if n >= #o.priser then
				r.info.Text = "MAX: " .. verdiTekst(o, n)
				r.kjop.Text = "MAXED"
				r.kjop.BackgroundColor3 = F.gra
			else
				r.info.Text = verdiTekst(o, n) .. "  ➜  " .. verdiTekst(o, n + 1)
				local pris = o.priser[n + 1]
				r.kjop.Text = Fugler.penger(pris)
				r.kjop.BackgroundColor3 = (st.penger or 0) >= pris and F.gronn or F.gra
			end
		end
		local reb = st.rebirths or 0
		local pris = st.rebirthPris or Config.REBIRTH.PRIS
		rInfo.Text = string.format("Rebirths: %d  •  Income x%.1f  ➜  x%.1f\nCosts %s", reb, 1 + Config.REBIRTH.BONUS * reb,
			1 + Config.REBIRTH.BONUS * (reb + 1), Fugler.penger(pris))
		rKnapp.BackgroundColor3 = (st.penger or 0) >= pris and F.gul or F.gra
		for id, r in robuxRader do
			if r.erPass and (st.pass or {})[id] then
				r.knapp.Text = "OWNED ✓"
				r.knapp.BackgroundColor3 = F.gra
			end
		end
		oddsTekst.Text = "Normal: " .. sjanser(1) .. "\nWith Server Luck: " .. sjanser(2)
	end
	Klientdata.lytt(oppdater)
	visSide("Upgrades")
	Menyer.registrer("Shop", v)
end

-- ---------------------------------------------------------------- INDEX

local function lagIndex(skjerm)
	local v = UI.vindu("Index", "📖 BIRD INDEX", UDim2.fromOffset(800, 560), skjerm, Menyer.lukk)
	local teller = UI.tekst({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -70, 0, 14), Size = UDim2.fromOffset(220, 32),
		Text = "", TextColor3 = F.gul, TextXAlignment = Enum.TextXAlignment.Right }, v)
	local rulle = UI.ny("ScrollingFrame", { Position = UDim2.fromOffset(14, 62), Size = UDim2.new(1, -28, 1, -76),
		BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 8, AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new() }, v)
	UI.ny("UIGridLayout", { CellSize = UDim2.fromOffset(176, 168), CellPadding = UDim2.fromOffset(8, 8),
		SortOrder = Enum.SortOrder.LayoutOrder }, rulle)
	local kort = {}
	for i, a in Fugler.ARTER do
		local sj = Fugler.SJ[a.sj]
		local k = UI.rund(UI.ny("Frame", { BackgroundColor3 = F.panel2, LayoutOrder = i, BorderSizePixel = 0 }, rulle), 12)
		UI.ny("UIStroke", { Thickness = 3, Color = sj.farge }, k)
		local bilde = UI.ny("ViewportFrame", { Position = UDim2.fromOffset(6, 4), Size = UDim2.new(1, -12, 0, 96),
			BackgroundTransparency = 1 }, k)
		local navn = UI.tekst({ Position = UDim2.fromOffset(6, 100), Size = UDim2.new(1, -12, 0, 24), Text = "???" }, k)
		local sjT = UI.tekst({ Position = UDim2.fromOffset(6, 124), Size = UDim2.new(1, -12, 0, 18), Text = a.sj,
			TextColor3 = sj.farge }, k)
		local mut = UI.tekst({ Position = UDim2.fromOffset(6, 142), Size = UDim2.new(1, -12, 0, 22), Text = "" }, k)
		kort[a.id] = { navn = navn, sj = sjT, mut = mut, a = a, k = k, bilde = bilde }
	end
	local function oppdater(st)
		local idx = st.index or {}
		local funnet = 0
		for id, k in kort do
			local side = idx[id]
			pcall(Fuglebilde.vis, k.bilde, id, not side)
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
