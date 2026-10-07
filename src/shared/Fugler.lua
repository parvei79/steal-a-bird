-- Fuglene, sjeldenhetene og mutasjonene, pluss regnestykkene for penger. Ren data og matematikk,
-- delt mellom server og klient og testbar med luau. All tekst spillerne ser er på engelsk.
local Fugler = {}

-- ---------------------------------------------------------------- sjeldenheter
-- vekt = sjanse på eggebåndet, pris = eggpris, inntekt = penger/s (laveste og høyeste i nivået),
-- klekk = sekunder før egget klekkes.
Fugler.SJELDENHETER = {
	{ id = "Common", farge = Color3.fromRGB(205, 210, 220), vekt = 45, pris = 40, inntekt = { 2, 4 }, klekk = 8 },
	{ id = "Uncommon", farge = Color3.fromRGB(90, 225, 110), vekt = 28, pris = 500, inntekt = { 15, 22 }, klekk = 15 },
	{ id = "Rare", farge = Color3.fromRGB(70, 160, 255), vekt = 15, pris = 6000, inntekt = { 90, 130 }, klekk = 30 },
	{ id = "Epic", farge = Color3.fromRGB(185, 100, 255), vekt = 8, pris = 75000, inntekt = { 550, 750 }, klekk = 45 },
	{ id = "Legendary", farge = Color3.fromRGB(255, 200, 40), vekt = 3.3, pris = 1000000, inntekt = { 3600, 4800 }, klekk = 60 },
	{ id = "Mythic", farge = Color3.fromRGB(255, 70, 90), vekt = 0.7, pris = 15000000, inntekt = { 28000, 36000 }, klekk = 90 },
	{ id = "Secret", farge = Color3.fromRGB(80, 255, 240), vekt = 0, pris = 25000000, inntekt = { 200000, 200000 }, klekk = 120 },
}
Fugler.SJ = {}
for i, s in Fugler.SJELDENHETER do
	s.nr = i
	Fugler.SJ[s.id] = s
end
-- Gullegget (Golden Egg Rain) er ikke en egen sjeldenhet for fugler, men et egg-slag: det klekker en fugl
-- med ekstra flaks og minst Gold-mutasjon.
Fugler.SJ.Golden = { id = "Golden", nr = 0, farge = Color3.fromRGB(255, 215, 60), vekt = 0, pris = 20000,
	inntekt = { 0, 0 }, klekk = 20 }

-- ---------------------------------------------------------------- artene
-- modell = navnet på 3D-modellen (fra Blender). vinge = "folda" (flakser ut fra siden) eller
-- "spredt" (står ute, vipper opp og ned). inntekt = andel mellom laveste og høyeste i nivået.
Fugler.ARTER = {
	-- Common
	{ id = "Pigeon", navn = "Pigeon", sj = "Common", t = 0.0, tekst = "Has seen things. Mostly bread." },
	{ id = "Sparrow", navn = "Sparrow", sj = "Common", t = 0.2, tekst = "Small. Loud. Fearless." },
	{ id = "Seagull", navn = "Seagull", sj = "Common", t = 0.5, tekst = "Will steal your fries. And your base." },
	{ id = "Chicken", navn = "Chicken", sj = "Common", t = 0.6, tekst = "Can't fly. Doesn't care." },
	{ id = "Duck", navn = "Duck", sj = "Common", t = 0.8, tekst = "Quack is the only word it knows." },
	{ id = "Crow", navn = "Crow", sj = "Common", t = 1.0, tekst = "Remembers every face. Including yours." },
	-- Uncommon
	{ id = "Puffin", navn = "Puffin", sj = "Uncommon", t = 0.0, tekst = "Tuxedo, clown nose, zero worries." },
	{ id = "Toucan", navn = "Toucan", sj = "Uncommon", t = 0.3, tekst = "90% beak. 10% bird." },
	{ id = "Flamingo", navn = "Flamingo", sj = "Uncommon", t = 0.5, tekst = "Stands on one leg out of pure confidence." },
	{ id = "Penguin", navn = "Penguin", sj = "Uncommon", t = 0.7, effekt = "sno",
		tekst = "Swims like a fish, walks like a toddler." },
	{ id = "Kiwi", navn = "Kiwi", sj = "Uncommon", t = 1.0, tekst = "No wings to speak of. Speaks anyway." },
	-- Rare
	{ id = "Shoebill", navn = "Shoebill", sj = "Rare", t = 0.0, tekst = "The stare. You know the stare." },
	{ id = "SecretaryBird", navn = "Secretary Bird", sj = "Rare", t = 0.3, tekst = "Kicks snakes. Files paperwork." },
	{ id = "Hoatzin", navn = "Hoatzin", sj = "Rare", t = 0.5, effekt = "stink", tekst = "Smells like a cow. Proud of it." },
	{ id = "Cassowary", navn = "Cassowary", sj = "Rare", t = 0.8, tekst = "The world's most dangerous chicken." },
	{ id = "Peacock", navn = "Peacock", sj = "Rare", t = 1.0, effekt = "glitter", tekst = "Main character energy." },
	-- Epic
	{ id = "HarpyEagle", navn = "Harpy Eagle", sj = "Epic", t = 0.0, tekst = "Biggest talons in the jungle." },
	{ id = "SnowyOwl", navn = "Snowy Owl", sj = "Epic", t = 0.3, effekt = "sno", tekst = "Silent, fluffy, judging you." },
	{ id = "Lyrebird", navn = "Lyrebird", sj = "Epic", t = 0.5, effekt = "noter", tekst = "Can copy any sound. Even your mom." },
	{ id = "Quetzal", navn = "Quetzal", sj = "Epic", t = 0.7, effekt = "glitter", tekst = "Tail longer than your excuses." },
	{ id = "Dodo", navn = "Dodo", sj = "Epic", t = 1.0, tekst = "Not extinct. Just hiding." },
	-- Legendary
	{ id = "Archaeopteryx", navn = "Archaeopteryx", sj = "Legendary", t = 0.0, vinge = "spredt",
		tekst = "Half dinosaur. Half bird. All attitude." },
	{ id = "TerrorBird", navn = "Terror Bird", sj = "Legendary", t = 0.4, tekst = "Ran down horses for breakfast." },
	{ id = "HaastsEagle", navn = "Haast's Eagle", sj = "Legendary", t = 0.6, vinge = "spredt",
		tekst = "Hunted giants. Now hunts you." },
	{ id = "Moa", navn = "Moa", sj = "Legendary", t = 0.8, tekst = "Twelve feet tall. Zero wings." },
	{ id = "Pterodactyl", navn = "Pterodactyl", sj = "Legendary", t = 1.0, vinge = "spredt",
		tekst = "Technically not a bird. Don't tell it." },
	-- Mythic
	{ id = "Phoenix", navn = "Phoenix", sj = "Mythic", t = 0.0, vinge = "spredt", effekt = "ild",
		tekst = "Rises from its own ashes. Twice on Sundays." },
	{ id = "IcePhoenix", navn = "Ice Phoenix", sj = "Mythic", t = 0.4, vinge = "spredt", effekt = "is",
		tekst = "Born in a blizzard. Chills everything." },
	{ id = "Roc", navn = "Roc", sj = "Mythic", t = 0.7, vinge = "spredt", effekt = "gull",
		tekst = "Carries elephants like snacks." },
	{ id = "Thunderbird", navn = "Thunderbird", sj = "Mythic", t = 1.0, vinge = "spredt", effekt = "lyn",
		tekst = "Every flap is a thunderclap." },
	-- Secret
	{ id = "CosmicShoebill", navn = "Cosmic Shoebill", sj = "Secret", t = 0.0, effekt = "kosmos",
		tekst = "Stared into the void. The void blinked." },
}
Fugler.ART = {}
for i, a in Fugler.ARTER do
	a.nr = i
	a.modell = a.modell or a.id
	a.vinge = a.vinge or "folda"
	Fugler.ART[a.id] = a
end

-- ---------------------------------------------------------------- mutasjoner
Fugler.MUTASJONER = {
	{ id = "Gold", navn = "Gold", faktor = 2, sjanse = 0.05, farge = Color3.fromRGB(255, 205, 60) },
	{ id = "Diamond", navn = "Diamond", faktor = 3, sjanse = 0.02, farge = Color3.fromRGB(150, 230, 255) },
	{ id = "Rainbow", navn = "Rainbow", faktor = 5, sjanse = 0.008, farge = Color3.fromRGB(255, 120, 220) },
	{ id = "Galaxy", navn = "Galaxy", faktor = 10, sjanse = 0.002, farge = Color3.fromRGB(150, 90, 255) },
}
Fugler.MUT = {}
for _, m in Fugler.MUTASJONER do
	Fugler.MUT[m.id] = m
end

-- ---------------------------------------------------------------- regnestykker

-- Penger per sekund for en fugl (art + mutasjon).
function Fugler.inntekt(art, mut)
	local a = Fugler.ART[art]
	if not a then
		return 0
	end
	local sj = Fugler.SJ[a.sj]
	local lo, hi = sj.inntekt[1], sj.inntekt[2]
	local v = math.floor(lo + (hi - lo) * a.t + 0.5)
	local m = mut and Fugler.MUT[mut]
	return v * (m and m.faktor or 1)
end

-- Hva du får for å selge fuglen.
function Fugler.salgspris(art, mut, andel)
	local a = Fugler.ART[art]
	if not a then
		return 0
	end
	local sj = Fugler.SJ[a.sj]
	local m = mut and Fugler.MUT[mut]
	local grunn = sj.pris > 0 and sj.pris or Fugler.inntekt(art, nil) * 60
	return math.floor(grunn * (andel or 0.5) * (m and m.faktor or 1))
end

-- Arter som faktisk kan dukke opp (har en 3D-modell, eller `tillat` sier ja).
function Fugler.tilgjengelige(sj, tillat)
	local ut = {}
	for _, a in Fugler.ARTER do
		if a.sj == sj and (not tillat or tillat(a)) then
			table.insert(ut, a.id)
		end
	end
	return ut
end

-- Trekk sjeldenhet for et nytt egg på båndet. flaks > 1 gjør de sjeldne mer sannsynlige.
function Fugler.trekkSjeldenhet(rng, flaks, tillat)
	flaks = flaks or 1
	local liste = {}
	local sum = 0
	for _, s in Fugler.SJELDENHETER do
		if s.vekt > 0 and #Fugler.tilgjengelige(s.id, tillat) > 0 then
			local v = s.vekt * (s.nr >= 3 and flaks or 1)
			sum += v
			table.insert(liste, { s.id, v })
		end
	end
	local r = rng:NextNumber() * sum
	for _, par in liste do
		r -= par[2]
		if r <= 0 then
			return par[1]
		end
	end
	return liste[#liste][1]
end

function Fugler.trekkArt(rng, sj, tillat)
	local liste = Fugler.tilgjengelige(sj, tillat)
	if #liste == 0 then
		return nil
	end
	return liste[rng:NextInteger(1, #liste)]
end

function Fugler.trekkMutasjon(rng, flaks)
	local r = rng:NextNumber()
	for i = #Fugler.MUTASJONER, 1, -1 do
		local m = Fugler.MUTASJONER[i]
		local sjanse = m.sjanse * (flaks or 1)
		if r < sjanse then
			return m.id
		end
		r -= sjanse
	end
	return nil
end

-- ---------------------------------------------------------------- tekst

-- 1234 -> "1.23K", 15000000 -> "15M"
function Fugler.kort(n)
	n = math.floor(n or 0)
	local neg = n < 0
	n = math.abs(n)
	local s
	if n < 1000 then
		s = tostring(n)
	else
		local enheter = { "K", "M", "B", "T", "Qd", "Qn" }
		local v = n
		local i = 0
		while v >= 1000 and i < #enheter do
			v /= 1000
			i += 1
		end
		if v >= 100 then
			s = string.format("%d%s", math.floor(v), enheter[i])
		elseif v >= 10 then
			s = string.format("%.1f%s", math.floor(v * 10) / 10, enheter[i])
		else
			s = string.format("%.2f%s", math.floor(v * 100) / 100, enheter[i])
		end
		s = string.gsub(s, "%.0+([A-Za-z]+)$", "%1")
		s = string.gsub(s, "(%.%d-)0+([A-Za-z]+)$", "%1%2")
	end
	return (neg and "-" or "") .. s
end

function Fugler.penger(n)
	return "$" .. Fugler.kort(n)
end

-- Hele navnet med mutasjon: "Gold Phoenix"
function Fugler.fulltNavn(art, mut)
	local a = Fugler.ART[art]
	local navn = a and a.navn or tostring(art)
	return mut and (mut .. " " .. navn) or navn
end

return Fugler
