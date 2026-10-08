-- Steal a Bird med «importerte» modeller (falske MeshParts med riktige størrelser, slik Import 3D lager
-- dem), så kodeveiene for ekte modeller også kjøres: fugler med vinger og ledd i skuldrene, planetringen,
-- mutasjoner, egg, sokler, krokpistolen, og 3D-bildene i samleboka.
-- Kjør: python3 tools/test_luau.py test/modeller.test.lua --mock
local Kart = krev("shared/Kart")
local Fugler = krev("shared/Fugler")
local ModelInfo = krev("shared/ModelInfo")

Mock.terrengHoyde = function(x, z)
	return Kart.toppHoyde(x, z) or -1000
end
krev("shared/Config").SESONG = nil -- testen skal ikke avhenge av hvilken måned det er
MODULER["mock/PlayerModule"] = function()
	return { GetControls = function()
		return { GetMoveVector = function()
			return Vector3.zero
		end }
	end }
end

local feil = 0
local function sjekk(ok, tekst)
	if ok then
		print("  ok   " .. tekst)
	else
		feil += 1
		print("  FEIL " .. tekst)
	end
end
local function steg(sek, dt)
	dt = dt or 1 / 30
	for _ = 1, math.max(1, math.floor(sek / dt + 0.5)) do
		Mock.steg(dt)
	end
end

do -- falske importerte modeller i workspace, som etter Import 3D («Scene» med <Navn>_Node/<Navn>)
	local mappe = Instance.new("Model")
	mappe.Name = "Scene"
	local antall = 0
	for navn, info in ModelInfo do
		local node = Instance.new("Model")
		node.Name = navn .. "_Node"
		node.Parent = mappe
		local del = Instance.new("MeshPart")
		del.Name = navn
		del.Size = info.str
		del.TextureID = "rbxassetid://1"
		del.Parent = node
		antall += 1
	end
	mappe.Parent = workspace
	print("Falske modeller: " .. antall)
end

local lastet = false
task.spawn(function()
	krev("server/Main")
	lastet = true
end)
while not lastet and #Mock.feil == 0 and Mock.tid() < 60 do
	Mock.steg(1 / 30)
end
assert(lastet, "Main ble ikke ferdig")
sjekk(game.ServerStorage:FindFirstChild("FuglModeller") ~= nil, "modellmappa ble funnet (het «Scene») og flyttet til ServerStorage")

local Fuglemodell = krev("server/Fuglemodell")
local Ting = krev("server/Ting")
local Spillere = krev("server/Spillere")
local Baser = krev("server/Baser")

-- alle fuglene som er laget, settes sammen riktig
local laget = 0
for _, a in Fugler.ARTER do
	if ModelInfo[a.modell] then
		laget += 1
		local m = Fuglemodell.fugl(a.id, nil, CFrame.new(0, 50, 0))
		local kropp = m:FindFirstChild("Kropp")
		local vh, vv = m:FindFirstChild("VingeH"), m:FindFirstChild("VingeV")
		local ok = kropp and kropp:IsA("MeshPart") and vh and vv and vh:FindFirstChild("VingeH") and vv:FindFirstChild("VingeV")
			and kropp:FindFirstChild("Kropp")
		if ok then
			-- leddet i høyre skulder ligger der ModelInfo sier
			local motor = vh.VingeH
			local ledd = kropp.CFrame * motor.C0
			local onsket = CFrame.new(0, 50, 0) * CFrame.new(ModelInfo[a.modell].hengselH)
			ok = (ledd.Position - onsket.Position).Magnitude < 0.01
		end
		if ModelInfo[a.modell .. "_Ekstra"] then
			ok = ok and m:FindFirstChild("Ekstra") ~= nil
		end
		sjekk(ok, a.id .. ": kropp, vinger og ledd")
		m:Destroy()
	end
end
print(string.format("%d av %d fugler har modell", laget, #Fugler.ARTER))
-- mutasjon tar bort teksturen
local gull = Fuglemodell.fugl("Pigeon", "Gold", CFrame.new())
sjekk(gull.Kropp.TextureID == "" and gull.Kropp.Material == Enum.Material.Foil, "Gold-mutasjon: gull uten tekstur")
gull:Destroy()

-- en spiller med klient: kjøp, klekk, og samleboka viser 3D-fuglen
local spiller = Mock.leggTilSpiller("Pål", 1001)
Mock.blilokal(spiller, "mock/PlayerModule")
steg(0.3)
task.spawn(function()
	krev("client/Klient")
end)
steg(1)
sjekk(spiller.Character:FindFirstChildOfClass("Tool") and spiller.Character:FindFirstChildOfClass("Tool").Handle:IsA("MeshPart"),
	"krokpistolen er den ekte modellen")
local i = Baser.til(spiller)
local sokkel = workspace.Verden["Base" .. i]:FindFirstChild("Sokkel1")
sjekk(sokkel and sokkel:IsA("MeshPart"), "soklene er ekte modeller")
Ting.lastInn(spiller, { { a = "Phoenix", s = 1 } })
steg(0.5)
local fonix
for _, t in Ting.alle() do
	if t.art == "Phoenix" then
		fonix = t
	end
end
sjekk(fonix and fonix.modell.Kropp:FindFirstChildOfClass("ParticleEmitter") ~= nil, "Phoenix brenner (partikler på klienten)")
Spillere.funnet(spiller, "Phoenix", nil)
steg(0.3)
local Menyer = krev("client/Menyer")
Menyer.aapne("Index")
steg(0.2)
local vist = false
for _, d in spiller.PlayerGui.FuglHUD.Index:GetDescendants() do
	if d:IsA("ViewportFrame") and d:GetAttribute("Art") == "Phoenix" and d:FindFirstChildOfClass("Model") then
		vist = d.ImageColor3.R == 1 and d.ImageColor3.G == 1
	end
end
sjekk(vist, "samleboka viser Phoenix i 3D (i farger)")
Menyer.lukk()

print((#Mock.feil == 0 and feil == 0) and "INGEN FEIL" or ("FEIL: " .. (#Mock.feil + feil)))
