-- «Trykk E»-knappene (ProximityPrompt) — laget her på klienten, så hver spiller får riktig tekst:
--   egg på båndet     BUY  (viser prisen, og hvor mye du mangler)
--   fugler hos andre  STEAL (hold litt) — skjules når basen er låst eller har nybegynnerskjold
--   dine egne fugler  SELL (hold lenge)
--   mistede egg       GRAB!
--   din låseknapp     LOCK BASE
-- Serveren sjekker alt på nytt, så knappene er bare en hjelp.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Fugler = require(Shared:WaitForChild("Fugler"))
local Klientdata = require(script.Parent:WaitForChild("Klientdata"))

local Prompter = {}

local spiller = Players.LocalPlayer
local remotes
local knapper = {} -- [Model eller Part] = ProximityPrompt

local function lagKnapp(forelder, e)
	local p = Instance.new("ProximityPrompt")
	p.RequiresLineOfSight = false
	p.MaxActivationDistance = Config.BAER.TA_AVSTAND - 2
	p.KeyboardKeyCode = Enum.KeyCode.E
	p.GamepadKeyCode = Enum.KeyCode.ButtonY
	p.Style = Enum.ProximityPromptStyle.Default
	for k, v in e do
		p[k] = v
	end
	p.Parent = forelder
	return p
end

local function baseLaast(i)
	local b = workspace:FindFirstChild("Verden") and workspace.Verden:FindFirstChild("Base" .. tostring(i))
	if not b then
		return false, false
	end
	local t = workspace:GetServerTimeNow()
	return (b:GetAttribute("LaastTil") or 0) > t, (b:GetAttribute("SkjoldTil") or 0) > t
end

local function navnPaa(m)
	if m:GetAttribute("Egg") then
		return (m:GetAttribute("Sj") or "?") .. " Egg"
	end
	return Fugler.fulltNavn(m:GetAttribute("Art"), m:GetAttribute("Mut"))
end

-- Oppdater teksten og om knappen vises. Kalles ofte (billig).
local function oppdater(m, p)
	local figur = spiller.Character
	local baerer = figur and figur:GetAttribute("Baerer") ~= nil
	local st = Klientdata.status
	if CollectionService:HasTag(m, "BelteEgg") then
		local pris = m:GetAttribute("Pris") or 0
		local penger = st.penger or 0
		p.ObjectText = (m:GetAttribute("Sj") or "") .. " Egg"
		if penger >= pris then
			p.ActionText = "Buy " .. Fugler.penger(pris)
		else
			p.ActionText = "Need " .. Fugler.penger(pris - penger) .. " more"
		end
		p.Enabled = not baerer
		return
	end
	local tilstand = m:GetAttribute("Tilstand")
	local eier = m:GetAttribute("Eier")
	p.ObjectText = navnPaa(m)
	if tilstand == "sluppet" then
		p.ActionText = "GRAB!"
		p.HoldDuration = 0
		p.Enabled = not baerer
	elseif tilstand == "plass" and eier == spiller.UserId then
		local pris
		if m:GetAttribute("Egg") then
			pris = math.floor(Fugler.SJ[m:GetAttribute("Sj")].pris * Config.BASE.SALG)
		else
			pris = Fugler.salgspris(m:GetAttribute("Art"), m:GetAttribute("Mut"), Config.BASE.SALG)
		end
		p.ActionText = "Sell " .. Fugler.penger(pris)
		p.HoldDuration = 1.2
		p.Enabled = not baerer and not m:GetAttribute("Klekker")
	elseif tilstand == "plass" then
		local laast, skjold = baseLaast(m:GetAttribute("Base"))
		p.ActionText = "STEAL"
		p.HoldDuration = Config.BAER.STJEL_HOLD
		p.Enabled = not baerer and not laast and not skjold and not m:GetAttribute("Klekker")
	else
		p.Enabled = false
	end
end

local function registrer(m)
	if knapper[m] then
		return
	end
	local rot = m:WaitForChild("Rot", 5)
	if not rot or not m.Parent then
		return
	end
	local p = lagKnapp(rot, { Name = "Knapp", UIOffset = Vector2.new(0, 40) })
	knapper[m] = p
	p.Triggered:Connect(function()
		if CollectionService:HasTag(m, "BelteEgg") then
			remotes.Handling:FireServer("kjop", m:GetAttribute("BelteId"))
			return
		end
		local id = m:GetAttribute("Id")
		if m:GetAttribute("Tilstand") == "plass" and m:GetAttribute("Eier") == spiller.UserId then
			remotes.Handling:FireServer("selg", id)
		else
			remotes.Handling:FireServer("ta", id)
		end
	end)
	oppdater(m, p)
	m.AncestryChanged:Connect(function()
		if not m:IsDescendantOf(workspace) then
			knapper[m] = nil
		end
	end)
end

local function laasKnapp(d)
	if knapper[d] then
		return
	end
	local p = lagKnapp(d, { Name = "LaasKnapp", ActionText = "LOCK BASE", ObjectText = "Shield",
		MaxActivationDistance = Config.BAER.TA_AVSTAND, HoldDuration = 0 })
	knapper[d] = p
	p.Triggered:Connect(function()
		remotes.Handling:FireServer("laas")
	end)
end

function Prompter.start(rem)
	remotes = rem
	for _, tag in { "Fugl", "Egg" } do
		for _, m in CollectionService:GetTagged(tag) do
			task.spawn(registrer, m)
		end
		CollectionService:GetInstanceAddedSignal(tag):Connect(function(m)
			task.spawn(registrer, m)
		end)
	end
	-- låseknappene i basene (bare din egen virker)
	task.spawn(function()
		local verden = workspace:WaitForChild("Verden")
		while true do
			for _, b in verden:GetChildren() do
				local d = b:IsA("Model") and b:FindFirstChild("LaaseKnapp")
				if d then
					laasKnapp(d)
					local p = knapper[d]
					p.Enabled = b:GetAttribute("Eier") == spiller.UserId
				end
			end
			task.wait(1)
		end
	end)
	local akk = 0
	RunService.Heartbeat:Connect(function(dt)
		akk += dt
		if akk < 0.2 then
			return
		end
		akk = 0
		for m, p in knapper do
			if m:IsA("Model") then
				oppdater(m, p)
			end
		end
	end)
end

return Prompter
