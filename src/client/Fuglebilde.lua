-- 3D-bilder av fuglene i skjermbildet (samleboka, bytte): setter sammen kropp og vinger fra
-- ReplicatedStorage.KlientModeller i en ViewportFrame. Ikke funnet = svart silhuett.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Fugler = require(Shared:WaitForChild("Fugler"))
local ModelInfo = require(Shared:WaitForChild("ModelInfo"))

local Fuglebilde = {}

local function modeller()
	return ReplicatedStorage:FindFirstChild("KlientModeller")
end

-- Bygg en modell av fuglen (uten ledd) med origo i CFrame.new(). Returnerer Model eller nil.
function Fuglebilde.modell(art)
	local a = Fugler.ART[art]
	local mappe = modeller()
	if not a or not mappe then
		return nil
	end
	local m = Instance.new("Model")
	local funnet = false
	for _, del in { "", "_VingeH", "_VingeV", "_Ekstra" } do
		local navn = a.modell .. del
		local kilde = mappe:FindFirstChild(navn)
		local info = ModelInfo[navn]
		if kilde and info then
			local d = kilde:Clone()
			d.Anchored = true
			d.CFrame = CFrame.new(info.midt)
			d.Parent = m
			funnet = true
		end
	end
	if not funnet then
		m:Destroy()
		return nil
	end
	return m
end

-- Lag (eller oppdater) en ViewportFrame med fuglen. silhuett = true for fugler som ikke er funnet.
function Fuglebilde.vis(vpf, art, silhuett)
	if vpf:GetAttribute("Art") ~= art then
		vpf:ClearAllChildren()
		vpf:SetAttribute("Art", art)
		local m = Fuglebilde.modell(art)
		if m then
			m.Parent = vpf
			local info = ModelInfo[Fugler.ART[art].modell]
			local str = info and info.str or Vector3.new(4, 5, 4)
			local hoyde = math.max(str.Y, str.X * 0.8, 3)
			local kam = Instance.new("Camera")
			kam.FieldOfView = 30
			local midt = Vector3.new(0, hoyde * 0.5, 0)
			local avstand = hoyde * 2.4
			kam.CFrame = CFrame.lookAt(midt + Vector3.new(avstand * 0.55, avstand * 0.25, -avstand * 0.85), midt)
			kam.Parent = vpf
			vpf.CurrentCamera = kam
		end
	end
	vpf.Ambient = Color3.fromRGB(190, 190, 200)
	vpf.LightColor = Color3.fromRGB(255, 255, 245)
	vpf.LightDirection = Vector3.new(-1, -1.4, 0.6)
	vpf.ImageColor3 = silhuett and Color3.new(0, 0, 0) or Color3.new(1, 1, 1)
	vpf.ImageTransparency = silhuett and 0.25 or 0
end

return Fuglebilde
