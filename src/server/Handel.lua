-- Bytte fugler mellom spillere (trading). Alt sjekkes på serveren:
--   1. A ber B om å bytte, og B må godta.
--   2. Begge legger fugler fra basen sin i byttet (maks 8 hver). Endrer noen tilbudet, mister begge «klar».
--   3. Begge trykker READY. Så går det en nedtelling på 5 sekunder.
--   4. Før byttet sjekkes det at begge fortsatt eier fuglene, at ingen bærer noe, og at det er plass.
-- Fugler som er med i et bytte, kan ikke stjeles eller selges før byttet er ferdig eller avbrutt.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Handel = {}

local Fjern, Spillere, Ting
local handler = {}       -- [Player] = handel (samme tabell for begge)
local foresporsler = {}  -- [mottaker] = { [avsender] = tid }
local sistBedt = {}      -- [avsender] = tid
local NEDTELLING = 5
local MAKS = 8

local function naa()
	return workspace:GetServerTimeNow()
end

local function feil(spiller, tekst)
	Fjern.Hendelse:FireClient(spiller, "feil", tekst)
end

local function annen(h, spiller)
	return h.a == spiller and h.b or h.a
end

-- Er tingen med i et pågående bytte?
function Handel.laast(id)
	for _, h in handler do
		for _, liste in h.tilbud do
			if liste[id] then
				return true
			end
		end
	end
	return false
end

local function info(liste)
	local ut = {}
	for id in liste do
		local t = Ting.hent(id)
		if t then
			table.insert(ut, { id = id, art = t.art, mut = t.mut or "", sj = t.sj })
		end
	end
	return ut
end

local function send(h)
	for _, s in { h.a, h.b } do
		local o = annen(h, s)
		Fjern.Handel:FireClient(s, "tilstand", {
			mine = info(h.tilbud[s]), deres = info(h.tilbud[o]),
			minKlar = h.klar[s] == true, deresKlar = h.klar[o] == true,
			slutt = h.slutt or 0, andre = o.UserId,
		})
	end
end

function Handel.avbryt(spiller, grunn)
	local h = handler[spiller]
	foresporsler[spiller] = nil
	if not h then
		return
	end
	handler[h.a] = nil
	handler[h.b] = nil
	for _, s in { h.a, h.b } do
		if s.Parent then
			Fjern.Handel:FireClient(s, "slutt", false, s == spiller and "Trade cancelled"
				or (spiller.DisplayName .. " " .. (grunn or "cancelled the trade")))
		end
	end
end

local function nullstillKlar(h)
	h.klar[h.a] = false
	h.klar[h.b] = false
	h.slutt = nil
end

-- Sjekk at byttet fortsatt går an. Returnerer true eller false, melding.
local function gyldig(h)
	for _, s in { h.a, h.b } do
		if not s.Parent or not Spillere.profil(s) then
			return false, "A player left"
		end
		if Ting.baeres(s) then
			return false, s.DisplayName .. " is carrying something"
		end
		for id in h.tilbud[s] do
			local t = Ting.hent(id)
			if not t or t.eier ~= s or t.tilstand ~= "plass" or t.egg then
				return false, "A bird in the trade is gone"
			end
		end
	end
	local function antall(liste)
		local n = 0
		for _ in liste do
			n += 1
		end
		return n
	end
	local na, nb = antall(h.tilbud[h.a]), antall(h.tilbud[h.b])
	if Ting.antallLedige(h.a) + na < nb then
		return false, h.a.DisplayName .. "'s base is too full"
	end
	if Ting.antallLedige(h.b) + nb < na then
		return false, h.b.DisplayName .. "'s base is too full"
	end
	if na == 0 and nb == 0 then
		return false, "The trade is empty"
	end
	return true
end

local function utfor(h)
	local ok, melding = gyldig(h)
	if not ok then
		for _, s in { h.a, h.b } do
			Fjern.Handel:FireClient(s, "slutt", false, melding)
		end
		handler[h.a] = nil
		handler[h.b] = nil
		return
	end
	-- ta alle tingene ut av soklene først, så plassen regnes riktig, og gi dem så til den andre
	local flytt = {}
	for _, s in { h.a, h.b } do
		for id in h.tilbud[s] do
			local t = Ting.hent(id)
			t.tilstand = "handel"
			table.insert(flytt, { t, annen(h, s) })
		end
	end
	handler[h.a] = nil
	handler[h.b] = nil
	for _, par in flytt do
		Ting.giTil(par[1], par[2])
	end
	for _, s in { h.a, h.b } do
		Fjern.Handel:FireClient(s, "slutt", true, "Trade complete! 🤝")
		Spillere.sendStatus(s)
		task.spawn(Spillere.lagre, s, false)
	end
	Fjern.Hendelse:FireAllClients("byttet", h.a, h.b)
end

local function behandle(spiller, type_, a, b)
	if type_ == "be" then
		local mottaker = typeof(a) == "number" and Players:GetPlayerByUserId(a)
		if not mottaker or mottaker == spiller then
			return
		end
		if handler[spiller] or handler[mottaker] then
			feil(spiller, handler[mottaker] and (mottaker.DisplayName .. " is already trading") or "You're already trading")
			return
		end
		local t = os.clock()
		if sistBedt[spiller] and t - sistBedt[spiller] < 3 then
			feil(spiller, "Wait a moment before asking again")
			return
		end
		sistBedt[spiller] = t
		foresporsler[mottaker] = foresporsler[mottaker] or {}
		foresporsler[mottaker][spiller] = t
		Fjern.Handel:FireClient(mottaker, "foresporsel", spiller)
		Fjern.Hendelse:FireClient(spiller, "melding", "Trade request sent to " .. mottaker.DisplayName)
	elseif type_ == "svar" then
		local avsender = typeof(a) == "number" and Players:GetPlayerByUserId(a)
		local liste = foresporsler[spiller]
		if not avsender or not liste or not liste[avsender] then
			return
		end
		liste[avsender] = nil
		if not b then
			Fjern.Hendelse:FireClient(avsender, "melding", spiller.DisplayName .. " said no to trading")
			return
		end
		if os.clock() - (sistBedt[avsender] or 0) > 60 then
			feil(spiller, "That request is too old")
			return
		end
		if handler[spiller] or handler[avsender] then
			feil(spiller, "One of you is already trading")
			return
		end
		local h = { a = avsender, b = spiller, tilbud = { [avsender] = {}, [spiller] = {} }, klar = {} }
		handler[avsender] = h
		handler[spiller] = h
		Fjern.Handel:FireClient(avsender, "start", spiller)
		Fjern.Handel:FireClient(spiller, "start", avsender)
		send(h)
	elseif type_ == "legg" then
		local h = handler[spiller]
		local t = typeof(a) == "number" and Ting.hent(a)
		if not h or not t then
			return
		end
		local liste = h.tilbud[spiller]
		if liste[a] then
			liste[a] = nil
		else
			if t.eier ~= spiller or t.tilstand ~= "plass" or t.egg or t.klekker then
				feil(spiller, "You can only trade hatched birds in your base")
				return
			end
			local n = 0
			for _ in liste do
				n += 1
			end
			if n >= MAKS then
				feil(spiller, "Max " .. MAKS .. " birds per trade")
				return
			end
			liste[a] = true
		end
		nullstillKlar(h)
		send(h)
	elseif type_ == "klar" then
		local h = handler[spiller]
		if not h then
			return
		end
		h.klar[spiller] = a == true
		if h.klar[h.a] and h.klar[h.b] then
			local ok, melding = gyldig(h)
			if ok then
				h.slutt = naa() + NEDTELLING
			else
				nullstillKlar(h)
				for _, s in { h.a, h.b } do
					feil(s, melding)
				end
			end
		else
			h.slutt = nil
		end
		send(h)
	elseif type_ == "avbryt" then
		Handel.avbryt(spiller)
	end
end

function Handel.init(remotes, spillere, _baser, ting)
	Fjern, Spillere, Ting = remotes, spillere, ting
	Ting.laastAvHandel = Handel.laast
	Fjern.Handel.OnServerEvent:Connect(function(spiller, type_, a, b)
		if type(type_) == "string" then
			behandle(spiller, type_, a, b)
		end
	end)
	RunService.Heartbeat:Connect(function()
		local t = naa()
		local ferdig = {}
		for _, h in handler do
			if h.slutt and t >= h.slutt then
				ferdig[h] = true
			end
		end
		for h in ferdig do
			utfor(h)
		end
	end)
	Players.PlayerRemoving:Connect(function(spiller)
		sistBedt[spiller] = nil
		foresporsler[spiller] = nil
	end)
end

return Handel
