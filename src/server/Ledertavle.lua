-- To store topplister på Reiret, for alle servere (OrderedDataStore):
--   TOP THIEVES   flest tyverier noensinne
--   BEST INCOME   høyeste inntekt per sekund noen har hatt
-- Virker bare når spillet er publisert (ellers står det hvordan man får dem i gang).
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Fugler = require(Shared:WaitForChild("Fugler"))
local Kart = require(Shared:WaitForChild("Kart"))

local Ledertavle = {}

local Spillere, Ting, Verden
local tavler = {} -- [nøkkel] = { store, linjer, tittel, format }
local navnCache = {}

local function navn(userId)
	if navnCache[userId] then
		return navnCache[userId]
	end
	local p = Players:GetPlayerByUserId(userId)
	if p then
		navnCache[userId] = p.DisplayName
		return p.DisplayName
	end
	local ok, n = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	navnCache[userId] = ok and n or ("Player " .. userId)
	return navnCache[userId]
end

local function lagTavle(nokkel, tittel, vinkel, farge, format)
	local R = Kart.REIR
	local pos = Vector3.new(R.x + math.cos(vinkel) * 40, R.topp, R.z + math.sin(vinkel) * 40)
	-- tavla står ved kanten av Reiret med teksten mot midten (baksiden av den snudde CFramen)
	local cf = CFrame.lookAt(pos + Vector3.new(0, 10, 0), Vector3.new(R.x, R.topp + 10, R.z)) * CFrame.Angles(0, math.pi, 0)
	local tavle = Verden.del({ Name = "Topplist" .. nokkel, Size = Vector3.new(14, 15, 1), CFrame = cf,
		Color = Color3.fromRGB(40, 44, 66) })
	for _, s in { -1, 1 } do
		Verden.del({ Name = "TavleBein", Size = Vector3.new(1, 3, 1), CFrame = CFrame.new(pos + cf.RightVector * 5 * s + Vector3.new(0, 1.5, 0)),
			Color = Color3.fromRGB(110, 78, 48) })
	end
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Back
	gui.LightInfluence = 0
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30
	local liste = Instance.new("UIListLayout")
	liste.SortOrder = Enum.SortOrder.LayoutOrder
	liste.Parent = gui
	local function linje(i, tekst, f, hoyde)
		local t = Instance.new("TextLabel")
		t.LayoutOrder = i
		t.Size = UDim2.new(1, 0, hoyde, 0)
		t.BackgroundTransparency = 1
		t.Font = Enum.Font.FredokaOne
		t.TextScaled = true
		t.Text = tekst
		t.TextColor3 = f or Color3.new(1, 1, 1)
		t.TextStrokeTransparency = 0.4
		t.Parent = gui
		return t
	end
	linje(0, tittel, farge, 0.14)
	local linjer = {}
	for i = 1, 10 do
		linjer[i] = linje(i, "", i <= 3 and Color3.fromRGB(255, 225, 120) or Color3.new(1, 1, 1), 0.086)
	end
	gui.Parent = tavle
	linjer[1].Text = "Loading..."
	local store = nil
	pcall(function()
		store = DataStoreService:GetOrderedDataStore("Topp_" .. nokkel)
	end)
	tavler[nokkel] = { store = store, linjer = linjer, format = format }
end

local function oppdater(nokkel, verdiFor)
	local t = tavler[nokkel]
	if not t.store then
		t.linjer[1].Text = "Publish the game to see the top 10!"
		return
	end
	for _, s in Players:GetPlayers() do
		local v = verdiFor(s)
		if v and v > 0 then
			pcall(function()
				t.store:SetAsync(tostring(s.UserId), math.floor(v))
			end)
		end
	end
	local ok, side = pcall(function()
		return t.store:GetSortedAsync(false, 10):GetCurrentPage()
	end)
	if not ok then
		t.linjer[1].Text = "Publish the game + turn on API access to see the top 10!"
		for i = 2, 10 do
			t.linjer[i].Text = ""
		end
		return
	end
	for i = 1, 10 do
		local rad = side[i]
		t.linjer[i].Text = rad and string.format("%d. %s  %s", i, navn(tonumber(rad.key)), t.format(rad.value)) or ""
	end
end

function Ledertavle.init(spillere, ting, verden)
	Spillere, Ting, Verden = spillere, ting, verden
	lagTavle("Tyverier", "🏆 TOP THIEVES", math.rad(22.5), Color3.fromRGB(255, 110, 100), function(v)
		return v .. " steals"
	end)
	lagTavle("Inntekt", "💰 BEST INCOME", math.rad(202.5), Color3.fromRGB(120, 255, 140), function(v)
		return Fugler.penger(v) .. "/s"
	end)
	task.spawn(function()
		task.wait(10)
		while true do
			pcall(oppdater, "Tyverier", function(s)
				local p = Spillere.profil(s)
				return p and p.data.tyverier
			end)
			pcall(oppdater, "Inntekt", function(s)
				local p = Spillere.profil(s)
				if not p then
					return nil
				end
				p.data.besteInntekt = math.max(p.data.besteInntekt or 0, Ting.inntektFor(s))
				return p.data.besteInntekt
			end)
			task.wait(90)
		end
	end)
end

return Ledertavle
