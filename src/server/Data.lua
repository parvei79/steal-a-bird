-- Lagring av spillerdata i DataStore, med «session lock» så to servere aldri skriver samtidig
-- (ellers kan fugler bli kopiert eller forsvinne når du bytter server).
--
-- Virker bare når spillet er publisert og «Enable Studio Access to API Services» er på. Ellers spiller
-- vi uten lagring og sier ifra én gang — spillet skal aldri stoppe fordi lagringen ikke virker.
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Data = {}

local VERSJON = 1
local LAAS_GYLDIG = 1800     -- sekunder: en lås eldre enn dette er fra en server som krasjet
local store = nil
local virker = true          -- false når DataStore ikke er tilgjengelig (Studio uten API-tilgang)
local jobb = (game.JobId ~= nil and game.JobId ~= "") and game.JobId or ("studio-" .. tostring(math.random(1, 1e9)))
Data.advarsel = nil

function Data.standard()
	return {
		v = VERSJON,
		penger = Config.BASE.STARTPENGER,
		fugler = {},          -- { { a = art, m = mutasjon|nil, e = true hvis egg, k = sekunder igjen, s = sokkel } }
		oppgr = {},           -- { tau = nivå, ... }
		index = {},           -- { [art] = { Normal = true, Gold = true, ... } }
		tyverier = 0,
		kjopt = 0,
	}
end

local function kopi(t)
	if type(t) ~= "table" then
		return t
	end
	local ut = {}
	for k, v in t do
		ut[k] = kopi(v)
	end
	return ut
end
Data.kopi = kopi

-- Gamle lagringer får nye felt med standardverdier.
local function migrer(d)
	local s = Data.standard()
	for k, v in s do
		if d[k] == nil then
			d[k] = v
		end
	end
	d.laas = nil
	d.v = VERSJON
	return d
end

local function erIkkeTilgang(feil)
	feil = tostring(feil)
	return string.find(feil, "403") ~= nil or string.find(feil, "API") ~= nil or string.find(feil, "publish") ~= nil
		or string.find(feil, "Studio") ~= nil
end

function Data.init(navn)
	local ok, s = pcall(function()
		return DataStoreService:GetDataStore(navn or "StealABird_v1")
	end)
	if ok and s then
		store = s
	else
		virker = false
		Data.advarsel = "Saving is off (DataStore not available)."
		warn("[STEAL A BIRD] DataStore er ikke tilgjengelig: " .. tostring(s))
	end
end

function Data.virker()
	return virker and store ~= nil
end

-- Last data for en spiller (venter). Returnerer data, lagres (false = spill uten å lagre).
function Data.last(userId)
	if not store or not virker then
		return Data.standard(), false
	end
	local nokkel = "spiller_" .. tostring(userId)
	for forsok = 1, 6 do
		local laastAvAnnen = false
		local ok, res = pcall(function()
			return store:UpdateAsync(nokkel, function(gammel)
				gammel = gammel or Data.standard()
				local laas = gammel.laas
				if laas and laas.jobb ~= jobb and os.time() - (laas.tid or 0) < LAAS_GYLDIG then
					laastAvAnnen = true
					return nil -- avbryt skrivingen: en annen server har denne spilleren
				end
				gammel.laas = { jobb = jobb, tid = os.time() }
				return gammel
			end)
		end)
		if ok and res and not laastAvAnnen then
			return migrer(kopi(res)), true
		end
		if not ok and erIkkeTilgang(res) then
			virker = false
			Data.advarsel = "Saving is off in Studio. Publish the game and turn on API access to save."
			warn("[STEAL A BIRD] Lagring er av: " .. tostring(res))
			return Data.standard(), false
		end
		-- låst av en annen server (spilleren byttet nettopp server) eller en midlertidig feil: vent og prøv igjen
		task.wait(laastAvAnnen and 3 or 1.5 * forsok)
	end
	warn("[STEAL A BIRD] Fikk ikke lastet data for " .. tostring(userId) .. ". Spiller uten lagring.")
	return Data.standard(), false
end

-- Lagre. slipp = true når spilleren går ut (låsen fjernes, så neste server kan laste med en gang).
function Data.lagre(userId, data, slipp)
	if not store or not virker then
		return false
	end
	local nokkel = "spiller_" .. tostring(userId)
	local ny = kopi(data)
	ny.v = VERSJON
	for forsok = 1, 3 do
		local ok, feil = pcall(function()
			store:UpdateAsync(nokkel, function(gammel)
				if gammel and gammel.laas and gammel.laas.jobb ~= jobb then
					return nil -- en annen server har tatt over: ikke skriv over dens data
				end
				ny.laas = (not slipp) and { jobb = jobb, tid = os.time() } or nil
				return ny
			end)
		end)
		if ok then
			return true
		end
		warn("[STEAL A BIRD] Lagring feilet (" .. forsok .. "): " .. tostring(feil))
		task.wait(1.5 * forsok)
	end
	return false
end

return Data
