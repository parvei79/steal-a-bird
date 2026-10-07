-- Eggene og fuglene («ting»): hvor de er (på en sokkel, båret eller sluppet), klekking, penger per
-- sekund, kjøp, stjeling, levering hjem, salg, og hva som skjer når en bærer blir truffet eller faller.
--
-- En ting har:  id, art, mut, egg (bool), sj (sjeldenhet), klekk (sekunder igjen), eier (Player),
--   plass (sokkel-nr) | nil, tilstand = "plass" | "baeres" | "sluppet", baerer (Player),
--   fra = { eier, plass } når den er stjålet og på vei, fersk = kjøpt på båndet og ikke levert ennå.
-- Arten til et egg er bestemt når egget kjøpes, men sendes ikke til klientene før det klekkes.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Fugler = require(Shared:WaitForChild("Fugler"))
local Kart = require(Shared:WaitForChild("Kart"))

local Ting = {}

local Fjern, Spillere, Baser, Fuglemodell
local alle = {}       -- [id] = ting
local baeres = {}     -- [Player] = ting
local nesteId = 0
local mappe
local rng = Random.new()
Ting.laastAvHandel = nil -- funksjon(id) -> bool (settes av Handel)

local SOKKEL_TOPP = 1.4

local function naa()
	return workspace:GetServerTimeNow()
end

function Ting.hent(id)
	return alle[id]
end

function Ting.alle()
	return alle
end

function Ting.baeres(spiller)
	return baeres[spiller]
end

local function rotTil(spiller)
	local f = spiller and spiller.Character
	return f and f:FindFirstChild("HumanoidRootPart")
end

local function melding(spiller, tekst)
	Fjern.Hendelse:FireClient(spiller, "feil", tekst)
end

-- ---------------------------------------------------------------- modell og merke

local function oppdaterMerke(t)
	local m = t.modell
	if not m then
		return
	end
	local sj = Fugler.SJ[t.sj]
	if t.egg then
		Fuglemodell.merke(m, {
			{ t.sj .. " Egg", sj.farge, "Navn" },
			{ "Hatching...", Color3.fromRGB(255, 255, 255), "Tid" },
		})
	else
		local linjer = { { Fugler.fulltNavn(t.art, t.mut), sj.farge, "Navn" } }
		if t.mut then
			table.insert(linjer, { "✨ " .. t.mut .. " x" .. Fugler.MUT[t.mut].faktor, Fugler.MUT[t.mut].farge, "Mut" })
		end
		table.insert(linjer, { t.sj, sj.farge, "Sj" })
		table.insert(linjer, { Fugler.penger(Fugler.inntekt(t.art, t.mut)) .. "/s", Color3.fromRGB(120, 255, 140), "Inntekt" })
		Fuglemodell.merke(m, linjer)
	end
end

local function settAttributter(t)
	local m = t.modell
	if not m then
		return
	end
	m:SetAttribute("Id", t.id)
	m:SetAttribute("Egg", t.egg)
	m:SetAttribute("Sj", t.sj)
	m:SetAttribute("Art", (not t.egg) and t.art or nil)
	m:SetAttribute("Mut", (not t.egg) and t.mut or nil)
	m:SetAttribute("Inntekt", (not t.egg) and Fugler.inntekt(t.art, t.mut) or 0)
	m:SetAttribute("Eier", t.eier and t.eier.UserId or 0)
	m:SetAttribute("Base", t.eier and Baser.til(t.eier) or 0)
	m:SetAttribute("Plass", t.plass or 0)
	m:SetAttribute("Tilstand", t.tilstand)
	m:SetAttribute("Baerer", t.baerer and t.baerer.UserId or 0)
	m:SetAttribute("KlarTid", (t.egg and t.tilstand == "plass") and (naa() + t.klekk) or 0)
	m:SetAttribute("SluppetTil", t.sluppetTil or 0)
	m:SetAttribute("Fersk", t.fersk == true)
end

local function lagModell(t, cf)
	if t.modell then
		t.modell:Destroy()
	end
	local m
	if t.egg then
		m = Fuglemodell.egg(t.sj, cf)
	else
		m = Fuglemodell.fugl(t.art, t.mut, cf)
	end
	t.modell = m
	settAttributter(t)
	oppdaterMerke(t)
	m.Parent = mappe
	return m
end

-- ---------------------------------------------------------------- sokler

local function sokkelCF(spiller, n)
	local i = Baser.til(spiller)
	return Kart.sokkel(i, n) * CFrame.new(0, SOKKEL_TOPP, 0)
end

-- Er sokkel n hos spilleren opptatt (av en fugl der, eller av en som er stjålet og på vei)?
local function opptatt(spiller, n)
	for _, t in alle do
		if t.eier == spiller and t.plass == n and t.tilstand == "plass" then
			return true
		end
		if t.fra and t.fra.eier == spiller and t.fra.plass == n then
			return true
		end
	end
	return false
end

function Ting.ledigSokkel(spiller)
	local i = Baser.til(spiller)
	if not i then
		return nil
	end
	for n = 1, Baser.sokler(i) do
		if not opptatt(spiller, n) then
			return n
		end
	end
	return nil
end

function Ting.antallLedige(spiller)
	local i = Baser.til(spiller)
	if not i then
		return 0
	end
	local ledige = 0
	for n = 1, Baser.sokler(i) do
		if not opptatt(spiller, n) then
			ledige += 1
		end
	end
	return ledige
end

local function settPaaSokkel(t, eier, n)
	t.eier = eier
	t.plass = n
	t.tilstand = "plass"
	t.baerer = nil
	t.fra = nil
	t.fersk = false
	t.sluppetTil = nil
	local cf = sokkelCF(eier, n)
	local m = t.modell
	if not m or not m.Parent then
		lagModell(t, cf)
	else
		local rot = m:FindFirstChild("Rot")
		for _, b in rot:GetChildren() do
			if b:IsA("WeldConstraint") then
				b:Destroy()
			end
		end
		rot.Anchored = true
		m:PivotTo(cf)
		rot.CFrame = cf
	end
	settAttributter(t)
end

-- ---------------------------------------------------------------- bære

local function baer(t, spiller)
	local rot = rotTil(spiller)
	local m = t.modell
	t.tilstand = "baeres"
	t.baerer = spiller
	t.plass = nil
	baeres[spiller] = t
	if rot and m then
		local r = m:FindFirstChild("Rot")
		r.Anchored = true
		local cf = rot.CFrame * CFrame.new(0, 3.1, 0)
		m:PivotTo(cf)
		r.CFrame = cf
		local w = Instance.new("WeldConstraint")
		w.Part0 = r
		w.Part1 = rot
		w.Parent = r
		r.Anchored = false
	end
	local f = spiller.Character
	local hum = f and f:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.WalkSpeed = 16 * Spillere.verdi(spiller, "baer")
	end
	if f then
		f:SetAttribute("Baerer", t.id)
		f:SetAttribute("BaererTid", naa())
		f:SetAttribute("Tyv", t.fra ~= nil)
	end
	settAttributter(t)
end

-- Slutt å bære (vekten og farten tilbake). Tingen blir liggende der den er til noen flytter den.
local function slippFra(spiller)
	local t = baeres[spiller]
	baeres[spiller] = nil
	local f = spiller.Character
	local hum = f and f:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.WalkSpeed = 16
	end
	if f then
		f:SetAttribute("Baerer", nil)
		f:SetAttribute("Tyv", false)
	end
	if t and t.modell then
		local r = t.modell:FindFirstChild("Rot")
		if r then
			for _, b in r:GetChildren() do
				if b:IsA("WeldConstraint") then
					b:Destroy()
				end
			end
			r.Anchored = true
		end
	end
	return t
end

-- ---------------------------------------------------------------- kjøp, stjel, snapp

-- Nytt egg kjøpt på båndet (Reiret har sjekket pris og avstand). Kjøperen bærer det hjem.
function Ting.kjopt(spiller, sj, art)
	nesteId += 1
	local t = { id = nesteId, art = art, mut = nil, egg = true, sj = sj, klekk = Fugler.SJ[sj].klekk,
		eier = spiller, fersk = true, tilstand = "baeres" }
	alle[t.id] = t
	local rot = rotTil(spiller)
	lagModell(t, rot and rot.CFrame or CFrame.new())
	baer(t, spiller)
	return t
end

-- Kan spilleren ta noe nå? (felles sjekker)
local function kanTa(spiller, t)
	if baeres[spiller] then
		return false, "You're already carrying something!"
	end
	local rot = rotTil(spiller)
	local hum = spiller.Character and spiller.Character:FindFirstChildOfClass("Humanoid")
	if not rot or not hum or hum.Health <= 0 then
		return false, nil
	end
	if not t.modell or not t.modell.PrimaryPart then
		return false, nil
	end
	if (t.modell.PrimaryPart.Position - rot.Position).Magnitude > Config.BAER.TA_AVSTAND + 4 then
		return false, "Get closer!"
	end
	if not Baser.til(spiller) then
		return false, "You need a base first"
	end
	return true
end

function Ting.ta(spiller, id)
	local t = alle[id]
	if not t then
		return
	end
	local ok, feil = kanTa(spiller, t)
	if not ok then
		if feil then
			melding(spiller, feil)
		end
		return
	end
	if t.tilstand == "sluppet" then
		-- et mistet egg: den som snapper det, eier det (kjøperen kan også ta det tilbake)
		if t.eier ~= spiller and not Ting.ledigSokkel(spiller) then
			melding(spiller, "Your base is full!")
			return
		end
		local forrige = t.eier
		t.eier = spiller
		t.fersk = true
		t.sluppetTil = nil
		baer(t, spiller)
		if forrige ~= spiller then
			Fjern.Hendelse:FireAllClients("snappet", spiller, forrige, t.sj)
		end
		return
	end
	if t.tilstand ~= "plass" or t.eier == spiller or t.klekker then
		return
	end
	local i = Baser.til(t.eier)
	if not i then
		return
	end
	if Baser.laast(i) then
		melding(spiller, "This base is locked! 🔒")
		return
	end
	if Baser.skjermet(i) then
		melding(spiller, "New player shield! 🛡️ Try again later.")
		return
	end
	if Ting.laastAvHandel and Ting.laastAvHandel(t.id) then
		melding(spiller, "That bird is in a trade right now")
		return
	end
	if not Ting.ledigSokkel(spiller) then
		melding(spiller, "Your base is full! Sell a bird first.")
		return
	end
	local offer = t.eier
	t.fra = { eier = offer, plass = t.plass }
	baer(t, spiller)
	local navn = t.egg and (t.sj .. " Egg") or Fugler.fulltNavn(t.art, t.mut)
	Fjern.Hendelse:FireClient(offer, "alarm", spiller, navn)
	Fjern.Hendelse:FireAllClients("stjeler", spiller, offer, navn)
end

-- Bæreren kom hjem til sin egen base: tingen settes på en ledig sokkel og blir hans/hennes.
local function lever(spiller)
	local t = baeres[spiller]
	if not t then
		return
	end
	local n = Ting.ledigSokkel(spiller)
	if not n then
		-- full base (kan bare skje med et mistet egg du snappet tilbake): pengene tilbake
		if t.fersk and t.egg and not t.fra then
			slippFra(spiller)
			Spillere.giPenger(spiller, Fugler.SJ[t.sj].pris)
			melding(spiller, "Your base is full, so the egg was refunded")
			Ting.fjern(t)
		end
		return
	end
	local stjaalet = t.fra and t.fra.eier ~= spiller
	local offer = t.fra and t.fra.eier
	slippFra(spiller)
	settPaaSokkel(t, spiller, n)
	if stjaalet then
		Spillere.tyveri(spiller)
		local navn = t.egg and (t.sj .. " Egg") or Fugler.fulltNavn(t.art, t.mut)
		Fjern.Hendelse:FireAllClients("stjalet", spiller, offer, navn)
	end
	if not t.egg then
		Spillere.funnet(spiller, t.art, t.mut)
	end
	Fjern.Hendelse:FireAllClients("levert", spiller, t.id)
	Spillere.sendStatus(spiller)
	if offer then
		Spillere.sendStatus(offer)
	end
end

-- Bæreren mistet tingen: grunn = "rykk" | "spark" | "fall" | "ut" | "dod".
function Ting.mistet(spiller, grunn)
	local t = baeres[spiller]
	if not t then
		return
	end
	local rot = rotTil(spiller)
	local pos = rot and rot.Position or (t.modell and t.modell.PrimaryPart and t.modell.PrimaryPart.Position) or Vector3.zero
	slippFra(spiller)
	if t.fra and t.fra.eier ~= spiller then
		-- stjålet: flyr hjem til eieren
		local offer, plass = t.fra.eier, t.fra.plass
		if offer.Parent and Baser.til(offer) then
			settPaaSokkel(t, offer, plass)
			Fjern.Hendelse:FireAllClients("tilbake", t.id, pos, spiller, offer)
			Spillere.sendStatus(offer)
		else
			Ting.fjern(t)
		end
		return
	end
	if t.fersk and (grunn == "rykk" or grunn == "spark") and pos.Y > Config.FALL_GRENSE + 20 then
		-- nykjøpt egg: svever der det ble mistet, og hvem som helst kan snappe det
		t.tilstand = "sluppet"
		t.baerer = nil
		t.sluppetTil = naa() + Config.BAER.SLUPPET_TID
		local cf = CFrame.new(pos + Vector3.new(0, 1.5, 0))
		t.modell:PivotTo(cf)
		t.modell.PrimaryPart.CFrame = cf
		settAttributter(t)
		Fjern.Hendelse:FireAllClients("sluppet", t.id, pos)
		return
	end
	-- ellers: hjem til eieren
	Ting.hjem(t)
end

-- Send en ting hjem til eieren (ledig sokkel), eller gi pengene tilbake hvis basen er full.
function Ting.hjem(t)
	local eier = t.eier
	local n = eier and eier.Parent and Ting.ledigSokkel(eier)
	if n then
		local fra = t.modell and t.modell.PrimaryPart and t.modell.PrimaryPart.Position
		settPaaSokkel(t, eier, n)
		Fjern.Hendelse:FireAllClients("tilbake", t.id, fra, nil, eier)
	else
		if eier and eier.Parent and t.egg then
			Spillere.giPenger(eier, Fugler.SJ[t.sj].pris)
			melding(eier, "Your base was full, so the egg was refunded")
		end
		Ting.fjern(t)
	end
end

-- Gi tingen til en ny eier (bytte): settes på en ledig sokkel i den nye basen.
function Ting.giTil(t, nyEier)
	local n = Ting.ledigSokkel(nyEier)
	if not n then
		return false
	end
	settPaaSokkel(t, nyEier, n)
	if not t.egg then
		Spillere.funnet(nyEier, t.art, t.mut)
	end
	return true
end

function Ting.fjern(t)
	if t.baerer and baeres[t.baerer] == t then
		slippFra(t.baerer)
	end
	if t.modell then
		t.modell:Destroy()
		t.modell = nil
	end
	alle[t.id] = nil
end

function Ting.selg(spiller, id)
	local t = alle[id]
	if not t or t.eier ~= spiller or t.tilstand ~= "plass" or t.klekker then
		return
	end
	if Ting.laastAvHandel and Ting.laastAvHandel(t.id) then
		melding(spiller, "That bird is in a trade right now")
		return
	end
	local rot = rotTil(spiller)
	if not rot or not t.modell or (t.modell.PrimaryPart.Position - rot.Position).Magnitude > Config.BAER.TA_AVSTAND + 4 then
		return
	end
	local pris
	if t.egg then
		pris = math.floor(Fugler.SJ[t.sj].pris * Config.BASE.SALG)
	else
		pris = Fugler.salgspris(t.art, t.mut, Config.BASE.SALG)
	end
	local pos = t.modell.PrimaryPart.Position
	Ting.fjern(t)
	Spillere.giPenger(spiller, pris)
	Fjern.Hendelse:FireAllClients("solgt", spiller, pris, pos)
	Spillere.sendStatus(spiller)
end

-- ---------------------------------------------------------------- klekking og penger

local function klekk(t)
	t.klekker = true
	local pos = t.modell and t.modell.PrimaryPart and t.modell.PrimaryPart.Position
	t.modell:SetAttribute("Klekker", naa())
	Fjern.Hendelse:FireAllClients("klekker", t.id, pos)
	task.delay(1.6, function()
		if alle[t.id] ~= t then
			return
		end
		t.egg = false
		t.mut = Fugler.trekkMutasjon(rng)
		t.klekker = false
		local cf = t.modell.PrimaryPart.CFrame
		lagModell(t, cf)
		t.modell:SetAttribute("Klekket", naa())
		local ny = Spillere.funnet(t.eier, t.art, t.mut)
		Fjern.Hendelse:FireAllClients("klekket", t.id, t.eier, t.art, t.mut, ny)
		Spillere.sendStatus(t.eier)
	end)
end

function Ting.inntektFor(spiller)
	local sum = 0
	for _, t in alle do
		if t.eier == spiller and not t.egg and t.tilstand == "plass" then
			sum += Fugler.inntekt(t.art, t.mut)
		end
	end
	return sum
end

-- ---------------------------------------------------------------- lagring

-- Fuglene som hører til spilleren, slik de lagres.
function Ting.fuglerFor(spiller)
	local ut = {}
	local brukt = {}
	local senere = {}
	for _, t in alle do
		local plass = nil
		if t.eier == spiller and t.tilstand == "plass" then
			plass = t.plass
		elseif t.fra and t.fra.eier == spiller then
			plass = t.fra.plass -- stjålet fra meg og på vei: fortsatt min
		elseif t.eier == spiller and t.fersk then
			table.insert(senere, t) -- nykjøpt egg på vei hjem
		end
		if plass then
			brukt[plass] = true
			table.insert(ut, { a = t.art, m = t.mut, e = t.egg, k = t.egg and math.ceil(t.klekk) or nil, s = plass })
		end
	end
	local n = 1
	for _, t in senere do
		while brukt[n] do
			n += 1
		end
		brukt[n] = true
		table.insert(ut, { a = t.art, m = t.mut, e = t.egg, k = math.ceil(t.klekk), s = n })
	end
	return ut
end

-- Lag fuglene fra lagringen på soklene i basen.
function Ting.lastInn(spiller, liste)
	local i = Baser.til(spiller)
	if not i then
		return
	end
	local maks = Baser.sokler(i)
	local brukt = {}
	local rest = {}
	for _, f in liste or {} do
		if Fugler.ART[f.a] then
			if type(f.s) == "number" and f.s >= 1 and f.s <= maks and not brukt[f.s] then
				brukt[f.s] = f
			else
				table.insert(rest, f)
			end
		end
	end
	for _, f in rest do
		for n = 1, maks do
			if not brukt[n] then
				brukt[n] = f
				break
			end
		end
	end
	for n, f in brukt do
		nesteId += 1
		local sj = Fugler.ART[f.a].sj
		local t = { id = nesteId, art = f.a, mut = f.m, egg = f.e == true, sj = sj,
			klekk = f.k or Fugler.SJ[sj].klekk, eier = spiller, tilstand = "plass", plass = n }
		alle[t.id] = t
		settPaaSokkel(t, spiller, n)
	end
end

-- Spilleren går: få alt som hører til spilleren hjem igjen, så det blir lagret riktig.
function Ting.spillerUt(spiller)
	if baeres[spiller] then
		Ting.mistet(spiller, "ut")
	end
	for _, t in alle do
		if t.fra and t.fra.eier == spiller and t.baerer then
			-- noen bærer en fugl de stjal fra meg: den går tilbake (og lagres hos meg)
			local tyv = t.baerer
			slippFra(tyv)
			settPaaSokkel(t, spiller, t.fra.plass)
			melding(tyv, "The owner left — the bird flew home")
		elseif t.eier == spiller and t.tilstand == "sluppet" then
			Ting.hjem(t)
		end
	end
end

-- Fjern alle modellene til spilleren (etter at lagringslisten er laget).
function Ting.fjernAlle(spiller)
	for _, t in alle do
		if t.eier == spiller and t.tilstand ~= "baeres" then
			Ting.fjern(t)
		end
	end
end

-- ---------------------------------------------------------------- løkka

local akkLever, akkPenger = 0, 0
local function steg(dt)
	-- klekking
	for _, t in alle do
		if t.egg and t.tilstand == "plass" and not t.klekker then
			t.klekk -= dt
			if t.klekk <= 0 then
				klekk(t)
			end
		end
	end
	akkLever += dt
	if akkLever >= 0.1 then
		akkLever = 0
		-- kom bæreren hjem?
		for spiller, t in baeres do
			local rot = rotTil(spiller)
			local i = Baser.til(spiller)
			if rot and i and Kart.iBase(i, rot.Position) then
				lever(spiller)
			elseif not spiller.Parent or not t.modell then
				baeres[spiller] = nil
			end
		end
		-- mistede egg som har svevd lenge nok, flyr hjem
		local t0 = naa()
		for _, t in alle do
			if t.tilstand == "sluppet" and t.sluppetTil and t0 >= t.sluppetTil then
				Ting.hjem(t)
			end
		end
	end
	akkPenger += dt
	if akkPenger >= 1 then
		akkPenger -= 1
		local sum = {}
		for _, t in alle do
			if not t.egg and t.tilstand == "plass" and t.eier then
				sum[t.eier] = (sum[t.eier] or 0) + Fugler.inntekt(t.art, t.mut)
			end
		end
		for spiller, n in sum do
			local i = Baser.til(spiller)
			if i then
				Baser.leggIPott(i, n)
			end
		end
	end
end

function Ting.init(_modeller, remotes, spillere, baser, fuglemodell)
	Fjern, Spillere, Baser, Fuglemodell = remotes, spillere, baser, fuglemodell
	mappe = Instance.new("Folder")
	mappe.Name = "Ting"
	mappe.Parent = workspace
	Spillere.inntektFor = Ting.inntektFor
	Spillere.fuglerFor = Ting.fuglerFor
	RunService.Heartbeat:Connect(steg)
end

return Ting
