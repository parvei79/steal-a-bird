-- Ny import av modellene: en gammel «FuglModeller» (med færre modeller) ligger i ServerStorage, og en ny
-- import ligger i Workspace. Serveren skal bruke den nye og fjerne den gamle.
-- Kjør: python3 tools/test_luau.py test/reimport.test.lua --mock
local ModelInfo = krev("shared/ModelInfo")
local Kart = krev("shared/Kart")
Mock.terrengHoyde = function(x, z)
	return Kart.toppHoyde(x, z) or -1000
end
krev("shared/Config").SESONG = nil

local function lag(navn, forelder, bare)
	local mappe = Instance.new("Model")
	mappe.Name = navn
	local n = 0
	for m, info in ModelInfo do
		n += 1
		if not bare or n <= bare then
			local node = Instance.new("Model")
			node.Name = m .. "_Node"
			node.Parent = mappe
			local d = Instance.new("MeshPart")
			d.Name = m
			d.Size = info.str
			d.Parent = node
		end
	end
	mappe.Parent = forelder
	return mappe
end
local gammel = lag("FuglModeller", game:GetService("ServerStorage"), 20)
local ny = lag("FuglModeller", workspace)

local lastet = false
task.spawn(function()
	krev("server/Main")
	lastet = true
end)
while not lastet and #Mock.feil == 0 and Mock.tid() < 60 do
	Mock.steg(1 / 30)
end
local feil = 0
local function sjekk(ok, tekst)
	print((ok and "  ok   " or "  FEIL ") .. tekst)
	if not ok then
		feil += 1
	end
end
local ss = game:GetService("ServerStorage")
local antall = 0
for _, b in ss:GetChildren() do
	if b.Name == "FuglModeller" then
		antall += 1
	end
end
sjekk(antall == 1, "bare én FuglModeller i ServerStorage")
sjekk(ss:FindFirstChild("FuglModeller") == ny, "den nye importen brukes")
sjekk(gammel.Parent == nil, "den gamle er fjernet")
sjekk(workspace:FindFirstChild("FuglModeller") == nil, "ingenting igjen i Workspace")
print((#Mock.feil == 0 and feil == 0) and "INGEN FEIL" or ("FEIL: " .. (#Mock.feil + feil)))
