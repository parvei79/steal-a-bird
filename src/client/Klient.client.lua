-- STEAL A BIRD — klienten starter her og kobler sammen kamera, krok, tau, animasjoner, fugleliv,
-- knapper (E), effekter, skjermbildet og vinduene.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kamera = require(script.Parent:WaitForChild("Kamera"))
local Grappler = require(script.Parent:WaitForChild("Grappler"))
local Tau = require(script.Parent:WaitForChild("Tau"))
local Effekter = require(script.Parent:WaitForChild("Effekter"))
local HUD = require(script.Parent:WaitForChild("HUD"))
local Positurer = require(script.Parent:WaitForChild("Positurer"))
local Fugleliv = require(script.Parent:WaitForChild("Fugleliv"))
local Prompter = require(script.Parent:WaitForChild("Prompter"))
local Menyer = require(script.Parent:WaitForChild("Menyer"))
local HandelUI = require(script.Parent:WaitForChild("HandelUI"))
local Klientdata = require(script.Parent:WaitForChild("Klientdata"))

local remotes = ReplicatedStorage:WaitForChild("Remotes")

remotes.Status.OnClientEvent:Connect(function(st)
	Klientdata.sett(st)
	Grappler.status = st
end)

Grappler.hendelser = function(liste)
	Effekter.egen(liste)
end

Kamera.start()
Grappler.start()
Tau.start(Grappler, remotes)
HUD.start(Grappler, Kamera, remotes)
Effekter.start(Grappler, Kamera, remotes, HUD, Positurer)
Positurer.start(Grappler, Tau, remotes)
Fugleliv.vedLanding = Effekter.landetEgg
Fugleliv.start()
Prompter.start(remotes)
Menyer.start(HUD, Kamera, Grappler, remotes)
HandelUI.start(Menyer, HUD, remotes)
remotes.Handling:FireServer("status")
