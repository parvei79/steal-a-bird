-- Felles byggeklosser for skjermbildene: paneler, knapper som spretter når du trykker, tekst og ikoner.
-- Én stil overalt: runde hjørner, tykk kant, FredokaOne-skrift, sterke farger.
local TweenService = game:GetService("TweenService")

local UI = {}

UI.FARGER = {
	panel = Color3.fromRGB(34, 38, 58),
	panel2 = Color3.fromRGB(48, 54, 80),
	kant = Color3.fromRGB(16, 18, 30),
	gronn = Color3.fromRGB(70, 200, 100),
	gul = Color3.fromRGB(255, 200, 50),
	rod = Color3.fromRGB(235, 70, 70),
	bla = Color3.fromRGB(70, 150, 255),
	lilla = Color3.fromRGB(160, 100, 255),
	hvit = Color3.fromRGB(255, 255, 255),
	gra = Color3.fromRGB(120, 125, 145),
	penger = Color3.fromRGB(120, 255, 140),
}

function UI.ny(klasse, e, forelder)
	local x = Instance.new(klasse)
	for k, v in e or {} do
		x[k] = v
	end
	if forelder then
		x.Parent = forelder
	end
	return x
end

function UI.rund(f, r)
	UI.ny("UICorner", { CornerRadius = UDim.new(0, r or 12) }, f)
	return f
end

function UI.kant(f, tykk, farge)
	UI.ny("UIStroke", { Thickness = tykk or 3, Color = farge or UI.FARGER.kant,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, f)
	return f
end

function UI.panel(e, forelder)
	local f = UI.ny("Frame", { BackgroundColor3 = UI.FARGER.panel, BorderSizePixel = 0 }, nil)
	for k, v in e or {} do
		f[k] = v
	end
	UI.rund(f, 16)
	UI.kant(f, 3)
	f.Parent = forelder
	return f
end

function UI.tekst(e, forelder)
	local t = UI.ny("TextLabel", {
		BackgroundTransparency = 1, Font = Enum.Font.FredokaOne, TextColor3 = UI.FARGER.hvit, TextScaled = true,
		TextStrokeTransparency = 0.4,
	})
	for k, v in e or {} do
		t[k] = v
	end
	t.Parent = forelder
	return t
end

-- Knapp som krymper litt når du trykker og spretter tilbake.
function UI.knapp(e, forelder, trykk)
	local b = UI.ny("TextButton", {
		BackgroundColor3 = UI.FARGER.gronn, BorderSizePixel = 0, AutoButtonColor = true, Font = Enum.Font.FredokaOne,
		TextColor3 = UI.FARGER.hvit, TextScaled = true, TextStrokeTransparency = 0.5, Text = "",
	})
	for k, v in e or {} do
		b[k] = v
	end
	UI.rund(b, 12)
	UI.kant(b, 3)
	UI.ny("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), PaddingTop = UDim.new(0, 3),
		PaddingBottom = UDim.new(0, 3) }, b)
	local skala = UI.ny("UIScale", { Scale = 1 }, b)
	b.MouseButton1Click:Connect(function()
		skala.Scale = 0.88
		TweenService:Create(skala, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
		if trykk then
			trykk()
		end
	end)
	b.Parent = forelder
	return b
end

-- Liten «sprett» når noe dukker opp (vinduer, meldinger).
function UI.sprett(gui)
	local skala = gui:FindFirstChildOfClass("UIScale") or UI.ny("UIScale", {}, gui)
	skala.Scale = 0.6
	TweenService:Create(skala, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end

-- Tittel og lukkeknapp øverst i et vindu.
function UI.vindu(navn, tittel, str, forelder, lukk)
	local v = UI.panel({ Name = navn, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = str, Visible = false }, forelder)
	UI.tekst({ Size = UDim2.new(1, -70, 0, 44), Position = UDim2.fromOffset(16, 8), Text = tittel,
		TextXAlignment = Enum.TextXAlignment.Left }, v)
	UI.knapp({ Size = UDim2.fromOffset(44, 44), Position = UDim2.new(1, -54, 0, 8), Text = "X",
		BackgroundColor3 = UI.FARGER.rod }, v, lukk)
	return v
end

return UI
