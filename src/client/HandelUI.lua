-- Byttevinduet (TRADE):
--   * uten bytte: liste over spillerne på serveren, med en TRADE-knapp hver
--   * forespørsel: «Sander wants to trade!» med ACCEPT og NO
--   * i et bytte: ditt tilbud til venstre, deres til høyre, fuglene dine nederst (trykk for å legge til
--     eller ta bort), READY og CANCEL. Når begge er klare, teller serveren ned fra 5.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Fugler = require(Shared:WaitForChild("Fugler"))
local UI = require(script.Parent:WaitForChild("UI"))

local HandelUI = {}

local spiller = Players.LocalPlayer
local F = UI.FARGER
local Menyer, HUD, remotes
local tilstand = nil  -- siste «tilstand» fra serveren, eller nil når vi ikke bytter
local andre = nil     -- Player vi bytter med

local vindu, spillerListe, byttePanel, mine, deres, egne, klarKnapp, nedtelling, tittel
local sporsmaal, sporsmaalTekst
local fra = nil       -- hvem som spurte oss

local function tom(f)
	for _, b in f:GetChildren() do
		if b:IsA("GuiObject") then
			b:Destroy()
		end
	end
end

local function fuglKort(forelder, info, valgt, trykk)
	local sj = Fugler.SJ[info.sj] or Fugler.SJ.Common
	local mut = info.mut ~= "" and info.mut or nil
	local b = UI.knapp({ Size = UDim2.new(1, -6, 0, 40), BackgroundColor3 = valgt and Color3.fromRGB(70, 110, 80) or F.panel2,
		Text = string.format("%s  •  %s/s", Fugler.fulltNavn(info.art, mut), Fugler.penger(Fugler.inntekt(info.art, mut))),
		TextColor3 = sj.farge }, forelder, trykk)
	return b
end

local function mineFugler()
	local ut = {}
	for _, m in workspace:WaitForChild("Ting"):GetChildren() do
		if m:GetAttribute("Eier") == spiller.UserId and m:GetAttribute("Tilstand") == "plass" and not m:GetAttribute("Egg") then
			table.insert(ut, { id = m:GetAttribute("Id"), art = m:GetAttribute("Art"), mut = m:GetAttribute("Mut") or "",
				sj = m:GetAttribute("Sj") })
		end
	end
	table.sort(ut, function(a, b)
		return Fugler.inntekt(a.art, a.mut ~= "" and a.mut or nil) > Fugler.inntekt(b.art, b.mut ~= "" and b.mut or nil)
	end)
	return ut
end

local function tegnSpillere()
	tom(spillerListe)
	local n = 0
	for _, p in Players:GetPlayers() do
		if p ~= spiller then
			n += 1
			local rad = UI.rund(UI.ny("Frame", { Size = UDim2.new(1, -6, 0, 52), BackgroundColor3 = F.panel2, BorderSizePixel = 0,
				LayoutOrder = n }, spillerListe), 10)
			UI.tekst({ Position = UDim2.fromOffset(12, 8), Size = UDim2.new(0.6, 0, 0, 36), Text = p.DisplayName,
				TextXAlignment = Enum.TextXAlignment.Left }, rad)
			UI.knapp({ AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(130, 40),
				Text = "TRADE", BackgroundColor3 = F.gul }, rad, function()
				remotes.Handel:FireServer("be", p.UserId)
			end)
		end
	end
	if n == 0 then
		UI.tekst({ Size = UDim2.new(1, 0, 0, 40), Text = "No other players here yet", TextColor3 = F.gra }, spillerListe)
	end
end

local function tegnBytte()
	if not tilstand then
		return
	end
	tittel.Text = "🤝 Trading with " .. (andre and andre.DisplayName or "?")
	tom(mine)
	tom(deres)
	tom(egne)
	local iTilbud = {}
	for _, info in tilstand.mine do
		iTilbud[info.id] = true
		fuglKort(mine, info, true, function()
			remotes.Handel:FireServer("legg", info.id)
		end)
	end
	for _, info in tilstand.deres do
		fuglKort(deres, info, true)
	end
	for _, info in mineFugler() do
		if not iTilbud[info.id] then
			fuglKort(egne, info, false, function()
				remotes.Handel:FireServer("legg", info.id)
			end)
		end
	end
	klarKnapp.Text = tilstand.minKlar and "✅ READY!" or "READY"
	klarKnapp.BackgroundColor3 = tilstand.minKlar and F.gronn or F.gra
end

local function visModus()
	local iBytte = tilstand ~= nil
	spillerListe.Parent.Visible = not iBytte
	byttePanel.Visible = iBytte
	if iBytte then
		tegnBytte()
	else
		tittel.Text = "🤝 TRADE — pick a player"
		tegnSpillere()
	end
end

local function lagVindu(skjerm)
	vindu = UI.vindu("Trade", "🤝 TRADE", UDim2.fromOffset(720, 540), skjerm, function()
		if tilstand then
			remotes.Handel:FireServer("avbryt")
		end
		Menyer.lukk()
	end)
	tittel = vindu:FindFirstChildOfClass("TextLabel")
	-- spillerlisten
	local listeRamme = UI.ny("Frame", { Position = UDim2.fromOffset(14, 62), Size = UDim2.new(1, -28, 1, -76),
		BackgroundTransparency = 1 }, vindu)
	spillerListe = UI.ny("ScrollingFrame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 8, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new() }, listeRamme)
	UI.ny("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, spillerListe)
	-- byttet
	byttePanel = UI.ny("Frame", { Position = UDim2.fromOffset(14, 62), Size = UDim2.new(1, -28, 1, -76),
		BackgroundTransparency = 1, Visible = false }, vindu)
	local function kolonne(x, overskrift, farge)
		UI.tekst({ Position = UDim2.new(x, 0, 0, 0), Size = UDim2.new(0.48, 0, 0, 28), Text = overskrift, TextColor3 = farge },
			byttePanel)
		local s = UI.ny("ScrollingFrame", { Position = UDim2.new(x, 0, 0, 32), Size = UDim2.new(0.48, 0, 0, 170),
			BackgroundColor3 = Color3.fromRGB(26, 30, 46), BorderSizePixel = 0, ScrollBarThickness = 6,
			AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new() }, byttePanel)
		UI.rund(s, 10)
		UI.ny("UIListLayout", { Padding = UDim.new(0, 4) }, s)
		return s
	end
	mine = kolonne(0, "YOUR OFFER", F.gronn)
	deres = kolonne(0.52, "THEIR OFFER", F.gul)
	UI.tekst({ Position = UDim2.fromOffset(0, 210), Size = UDim2.new(1, 0, 0, 24), Text = "Your birds (click to add):",
		TextColor3 = Color3.fromRGB(190, 200, 225), TextXAlignment = Enum.TextXAlignment.Left }, byttePanel)
	egne = UI.ny("ScrollingFrame", { Position = UDim2.fromOffset(0, 238), Size = UDim2.new(1, 0, 0, 120),
		BackgroundColor3 = Color3.fromRGB(26, 30, 46), BorderSizePixel = 0, ScrollBarThickness = 6,
		AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new() }, byttePanel)
	UI.rund(egne, 10)
	UI.ny("UIGridLayout", { CellSize = UDim2.new(0.5, -6, 0, 40), CellPadding = UDim2.fromOffset(6, 4) }, egne)
	klarKnapp = UI.knapp({ Position = UDim2.new(0, 0, 1, -56), Size = UDim2.fromOffset(200, 52), Text = "READY",
		BackgroundColor3 = F.gra }, byttePanel, function()
		if tilstand then
			remotes.Handel:FireServer("klar", not tilstand.minKlar)
		end
	end)
	UI.knapp({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 1, -56), Size = UDim2.fromOffset(170, 52),
		Text = "CANCEL", BackgroundColor3 = F.rod }, byttePanel, function()
		remotes.Handel:FireServer("avbryt")
	end)
	nedtelling = UI.tekst({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 1, -56),
		Size = UDim2.fromOffset(220, 52), Text = "", TextColor3 = F.gul }, byttePanel)
	Menyer.registrer("Trade", vindu)
	Menyer.vedApning.Trade = visModus
	-- forespørsel
	sporsmaal = UI.panel({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 160), Size = UDim2.fromOffset(420, 130),
		Visible = false }, skjerm)
	sporsmaalTekst = UI.tekst({ Position = UDim2.fromOffset(10, 8), Size = UDim2.new(1, -20, 0, 50), Text = "" }, sporsmaal)
	UI.knapp({ Position = UDim2.new(0, 14, 1, -60), Size = UDim2.fromOffset(180, 48), Text = "ACCEPT",
		BackgroundColor3 = F.gronn }, sporsmaal, function()
		sporsmaal.Visible = false
		if fra then
			remotes.Handel:FireServer("svar", fra.UserId, true)
		end
	end)
	UI.knapp({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 1, -60), Size = UDim2.fromOffset(180, 48),
		Text = "NO", BackgroundColor3 = F.rod }, sporsmaal, function()
		sporsmaal.Visible = false
		if fra then
			remotes.Handel:FireServer("svar", fra.UserId, false)
		end
	end)
end

function HandelUI.start(menyer, hud, rem)
	Menyer, HUD, remotes = menyer, hud, rem
	lagVindu(HUD.skjerm)
	remotes.Handel.OnClientEvent:Connect(function(type_, a, b)
		if type_ == "foresporsel" then
			fra = a
			sporsmaalTekst.Text = "🤝 " .. a.DisplayName .. " wants to trade!\n(press ALT for the mouse)"
			sporsmaal.Visible = true
			UI.sprett(sporsmaal)
			task.delay(20, function()
				if fra == a then
					sporsmaal.Visible = false
				end
			end)
		elseif type_ == "start" then
			andre = a
			tilstand = { mine = {}, deres = {}, minKlar = false, deresKlar = false, slutt = 0 }
			if Menyer.aapent() ~= "Trade" then
				Menyer.aapne("Trade")
			else
				visModus()
			end
		elseif type_ == "tilstand" then
			tilstand = a
			if Menyer.aapent() == "Trade" then
				visModus()
			end
		elseif type_ == "slutt" then
			tilstand = nil
			andre = nil
			if a then
				HUD.banner(b or "Trade complete!", F.gronn, 2.5)
			else
				HUD.feil(b or "Trade cancelled")
			end
			if Menyer.aapent() == "Trade" then
				visModus()
			end
		end
	end)
	RunService.RenderStepped:Connect(function()
		if tilstand and tilstand.slutt and tilstand.slutt > 0 then
			local igjen = tilstand.slutt - workspace:GetServerTimeNow()
			nedtelling.Text = igjen > 0 and string.format("Trading in %d...", math.ceil(igjen)) or "Trading!"
		elseif tilstand then
			nedtelling.Text = tilstand.deresKlar and "They are READY" or "Waiting..."
		end
	end)
end

return HandelUI
