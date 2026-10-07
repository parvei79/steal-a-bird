-- Game passes og Developer Products (Robux). ID-ene står i Config.ROBUX — 0 betyr «ikke laget ennå».
--   VIP          x2 penger + VIP-merke
--   AutoCollect  pengene går rett til deg
--   ExtraSlots   +4 sokler
--   RainbowRope  regnbuetau
--   ServerLuck   (produkt) 15 min med dobbel flaks for hele serveren
--   Cash         (produkt) 10 minutter av inntekten din
-- Kjøp av produkter lagres med kvitterings-ID, så ingenting gis to ganger (Roblox kan sende samme kjøp flere ganger).
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Fugler = require(Shared:WaitForChild("Fugler"))

local Robux = {}

local Fjern, Spillere, Baser, Reiret, Ting
local luckTil = 0

local function naa()
	return workspace:GetServerTimeNow()
end

local PASS_ETTER_ID, PRODUKT_ETTER_ID = {}, {}
for _, p in Config.ROBUX.PASS do
	if p.passId > 0 then
		PASS_ETTER_ID[p.passId] = p
	end
end
for _, p in Config.ROBUX.PRODUKT do
	if p.produktId > 0 then
		PRODUKT_ETTER_ID[p.produktId] = p
	end
end

-- Sjekk hvilke passes spilleren eier (kalles når spilleren kommer inn).
function Robux.sjekkPass(spiller)
	for _, p in Config.ROBUX.PASS do
		if p.passId > 0 then
			local ok, eier = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(spiller.UserId, p.passId)
			end)
			if ok and eier then
				Spillere.settPass(spiller, p.id)
				if p.id == "ExtraSlots" and Baser.til(spiller) then
					Baser.oppdaterSokler(Baser.til(spiller))
				end
			end
		end
	end
end

local function serverLuck(kjoper)
	luckTil = math.max(luckTil, naa()) + Config.ROBUX.LUCK_TID
	Reiret.grunnFlaks = 2
	Reiret.flaks = math.max(Reiret.flaks, 2)
	workspace:SetAttribute("LuckTil", luckTil)
	Fjern.Hendelse:FireAllClients("serverLuck", kjoper, luckTil)
	task.delay(luckTil - naa() + 0.5, function()
		if naa() >= luckTil then
			Reiret.grunnFlaks = 1
			if not Reiret.kosmisk then
				Reiret.flaks = 1
			end
			workspace:SetAttribute("LuckTil", nil)
		end
	end)
end

local function gi(spiller, produkt)
	if produkt.id == "ServerLuck" then
		serverLuck(spiller)
	elseif produkt.id == "Cash" then
		local belop = math.max(1000, Ting.inntektFor(spiller) * 600)
		Spillere.giPenger(spiller, belop)
		Fjern.Hendelse:FireClient(spiller, "melding", "+" .. Fugler.penger(belop) .. " cash pack! 💰", Color3.fromRGB(120, 255, 140))
	end
end

local function behandleKvittering(info)
	local spiller = Players:GetPlayerByUserId(info.PlayerId)
	local produkt = PRODUKT_ETTER_ID[info.ProductId]
	local p = spiller and Spillere.profil(spiller)
	if not p or not produkt then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local kv = p.data.kvitteringer or {}
	p.data.kvitteringer = kv
	for _, id in kv do
		if id == info.PurchaseId then
			return Enum.ProductPurchaseDecision.PurchaseGranted -- allerede gitt
		end
	end
	local ok, feil = pcall(gi, spiller, produkt)
	if not ok then
		warn("[STEAL A BIRD] Kunne ikke gi produkt: " .. tostring(feil))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	table.insert(kv, info.PurchaseId)
	while #kv > 30 do
		table.remove(kv, 1)
	end
	-- lagre med en gang, så kjøpet ikke kan gis på nytt etter et serverkrasj
	if p.lagres and not Spillere.lagre(spiller, false) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function Robux.init(remotes, spillere, baser, reiret, ting)
	Fjern, Spillere, Baser, Reiret, Ting = remotes, spillere, baser, reiret, ting
	MarketplaceService.ProcessReceipt = behandleKvittering
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(spiller, passId, kjopt)
		local p = PASS_ETTER_ID[passId]
		if kjopt and p then
			Spillere.settPass(spiller, p.id)
			if p.id == "ExtraSlots" and Baser.til(spiller) then
				Baser.oppdaterSokler(Baser.til(spiller))
			end
			Fjern.Hendelse:FireAllClients("melding", spiller.DisplayName .. " got " .. p.navn .. "! ⭐", Color3.fromRGB(255, 220, 90))
		end
	end)
end

return Robux
