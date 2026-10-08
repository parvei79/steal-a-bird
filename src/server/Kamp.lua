-- Krokpistolen til alle, videresending av kroker (så alle ser alle tau), rykk og flyspark mot andre
-- spillere (de ragdoller, blir svimle og mister det de bærer), og hva som skjer når noen faller ned.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Kart = require(Shared:WaitForChild("Kart"))

local Kamp = {}

local Modeller, Fjern, Spillere, Baser, Ting
local sistTruffet = {} -- [figur] = { av = navn, tid }
local sistSkudd = {}   -- [spiller] = tid
local sistSpark = {}   -- [nøkkel] = tid
local K, KK = Config.KAMP, Config.KROK

local function naa()
	return workspace:GetServerTimeNow()
end

-- ---------------------------------------------------------------- krokpistolen

local function lagPistol()
	local verktoy = Instance.new("Tool")
	verktoy.Name = "Hook"
	verktoy.CanBeDropped = false
	verktoy.RequiresHandle = true
	local handle = Modeller.hent("KrokPistol", 1)
	local munning
	if handle then
		handle.Name = "Handle"
		local info = Modeller.info("KrokPistol")
		verktoy.Grip = CFrame.new(info.grep)
		munning = info.munning - info.midt
	else
		handle = Instance.new("Part")
		handle.Name = "Handle"
		handle.Size = Vector3.new(0.6, 0.8, 3)
		handle.Color = Color3.fromRGB(230, 57, 70)
		handle.CanCollide = false
		handle.Massless = true
		verktoy.Grip = CFrame.new(0, -0.2, 0.8)
		munning = Vector3.new(0, 0.1, -1.6)
	end
	local a = Instance.new("Attachment")
	a.Name = "Munning"
	a.Position = munning
	a.Parent = handle
	handle.Parent = verktoy
	return verktoy
end

Kamp.vedFigur = nil -- funksjon(spiller) når en ny figur er klar (taufarge, VIP-merke)

local function figurInn(spiller, figur)
	local hum = figur:WaitForChild("Humanoid")
	hum.BreakJointsOnDeath = false
	figur:SetAttribute("Ragdoll", 0)
	figur:SetAttribute("Svimmel", 0)
	if Kamp.vedFigur then
		Kamp.vedFigur(spiller)
	end
	task.defer(function()
		local verktoy = lagPistol()
		verktoy.Parent = spiller:WaitForChild("Backpack")
		hum:EquipTool(verktoy)
		-- hjem til basen
		local i = Baser.til(spiller)
		if i then
			figur:PivotTo(Kart.spawn(i))
		end
	end)
	hum.Died:Connect(function()
		Ting.mistet(spiller, "dod")
	end)
end

-- ---------------------------------------------------------------- treff

-- Returnerer figur, rotdel, spiller for en del av en annen spiller (eller nil).
local function maalFra(inst)
	if typeof(inst) ~= "Instance" then
		return nil
	end
	local m = inst
	while m and m ~= workspace do
		if m:IsA("Model") then
			local spiller = Players:GetPlayerFromCharacter(m)
			if spiller then
				return m, m:FindFirstChild("HumanoidRootPart"), spiller
			end
		end
		m = m.Parent
	end
	return nil
end

local function knuff(figur, rot, offer, hastighet, angriper, grunn)
	local t = naa()
	figur:SetAttribute("Ragdoll", t + K.RAGDOLL)
	figur:SetAttribute("Svimmel", t + K.RAGDOLL + K.SVIMMEL)
	Fjern.Knuff:FireClient(offer, hastighet, K.STUN, true)
	if angriper then
		sistTruffet[figur] = { av = angriper.DisplayName, tid = t }
	end
	if Ting.baeres(offer) then
		Ting.mistet(offer, grunn)
		if angriper then
			Fjern.Hendelse:FireAllClients("reddet", angriper, offer, rot.Position)
		end
	end
end

-- Slag fra omgivelsene (lyn, meteor): ragdoll, svimmel, og du mister det du bærer.
function Kamp.slag(offer, hastighet, grunn)
	local figur = offer.Character
	local rot = figur and figur:FindFirstChild("HumanoidRootPart")
	local hum = figur and figur:FindFirstChildOfClass("Humanoid")
	if not rot or not hum or hum.Health <= 0 then
		return
	end
	knuff(figur, rot, offer, hastighet, nil, grunn)
end

local function rykk(spiller, mal)
	local figur = spiller.Character
	local minRot = figur and figur:FindFirstChild("HumanoidRootPart")
	local modell, rot, offer = maalFra(mal)
	if not minRot or not modell or not rot or modell == figur or not offer then
		return
	end
	local avstand = (rot.Position - minRot.Position).Magnitude
	if avstand > Spillere.verdi(spiller, "tau") + 30 then
		return
	end
	local mot = (minRot.Position - rot.Position)
	local retning = Vector3.new(mot.X, 0, mot.Z)
	retning = retning.Magnitude > 0.1 and retning.Unit or Vector3.new(0, 0, 1)
	local fart = K.RYKK_KRAFT + math.min(avstand * 0.25, 40)
	knuff(modell, rot, offer, retning * fart + Vector3.new(0, K.RYKK_OPP, 0), spiller, "rykk")
	Fjern.Hendelse:FireAllClients("rykk", rot.Position, spiller, offer)
end

local function spark(spiller, mal, minFart)
	local figur = spiller.Character
	local minRot = figur and figur:FindFirstChild("HumanoidRootPart")
	local modell, rot, offer = maalFra(mal)
	if not minRot or not modell or not rot or modell == figur or not offer or typeof(minFart) ~= "Vector3" then
		return
	end
	local nokkel = spiller.UserId .. ":" .. offer.UserId
	if sistSpark[nokkel] and naa() - sistSpark[nokkel] < 0.5 then
		return
	end
	if (rot.Position - minRot.Position).Magnitude > K.SPARK_AVSTAND + 8 then
		return
	end
	local fart = math.min(minFart.Magnitude, KK.MAKS_FART)
	if fart < K.SPARK_MIN_FART * 0.8 then
		return
	end
	sistSpark[nokkel] = naa()
	knuff(modell, rot, offer, minFart.Unit * (fart * 0.75) + Vector3.new(0, 30, 0), spiller, "spark")
	Fjern.Hendelse:FireAllClients("spark", rot.Position, spiller, offer)
end

-- ---------------------------------------------------------------- fall

local function sjekkFall()
	for _, spiller in Players:GetPlayers() do
		local figur = spiller.Character
		local hum = figur and figur:FindFirstChildOfClass("Humanoid")
		local rot = figur and figur:FindFirstChild("HumanoidRootPart")
		if hum and rot and hum.Health > 0 and rot.Position.Y < Config.FALL_GRENSE then
			Ting.mistet(spiller, "fall")
			local sist = sistTruffet[figur]
			if sist and naa() - sist.tid < K.SIST_TRUFFET then
				Fjern.Hendelse:FireAllClients("melding", string.format("%s was yanked into the clouds by %s! ☁️",
					spiller.DisplayName, sist.av))
			end
			sistTruffet[figur] = nil
			hum.Health = 0
		end
	end
end

function Kamp.init(modeller, remotes, spillere, baser, ting)
	Modeller, Fjern, Spillere, Baser, Ting = modeller, remotes, spillere, baser, ting
	Players.RespawnTime = Config.RESPAWN_TID

	-- kroken: videresend til alle andre, så de ser tauet
	Fjern.Krok.OnServerEvent:Connect(function(spiller, type_, mal, del, lokal)
		if type_ == "skyt" then
			if typeof(mal) ~= "Vector3" then
				return
			end
			local t = naa()
			if sistSkudd[spiller] and t - sistSkudd[spiller] < KK.VENTETID * 0.7 then
				return
			end
			sistSkudd[spiller] = t
			local figur = spiller.Character
			local rot = figur and figur:FindFirstChild("HumanoidRootPart")
			if not rot or (mal - rot.Position).Magnitude > Spillere.verdi(spiller, "tau") + 30 then
				return
			end
			if del ~= nil and typeof(del) ~= "Instance" then
				del = nil
			end
			if typeof(lokal) ~= "Vector3" then
				lokal = nil
			end
			for _, annen in Players:GetPlayers() do
				if annen ~= spiller then
					Fjern.Hendelse:FireClient(annen, "krok", spiller, "skyt", mal, del, lokal)
				end
			end
		elseif type_ == "slipp" then
			for _, annen in Players:GetPlayers() do
				if annen ~= spiller then
					Fjern.Hendelse:FireClient(annen, "krok", spiller, "slipp")
				end
			end
		end
	end)
	Fjern.Rykk.OnServerEvent:Connect(rykk)
	Fjern.Spark.OnServerEvent:Connect(spark)

	local function spillerInn(spiller)
		spiller.CharacterAdded:Connect(function(figur)
			figurInn(spiller, figur)
		end)
		if spiller.Character then
			task.spawn(figurInn, spiller, spiller.Character)
		end
	end
	Kamp.spillerInn = spillerInn
	Players.PlayerRemoving:Connect(function(spiller)
		sistSkudd[spiller] = nil
	end)

	local akk = 0
	RunService.Heartbeat:Connect(function(dt)
		akk += dt
		if akk >= 0.2 then
			akk = 0
			sjekkFall()
		end
	end)
end

return Kamp
