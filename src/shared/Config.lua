-- Alle tall som styrer hvordan Steal a Bird føles. Juster her, ikke rundt i koden.
local Config = {}

-- ---------------------------------------------------------------- kroken (fra GRAPPLER)
Config.KROK = {
	REKKEVIDDE = 150,        -- hvor langt kroken når uten oppgradering (studs)
	KROKFART = 900,          -- hvor fort kroken flyr ut (studs/s)
	INNTREKK = 24,           -- hvor fort tauet kortes inn mens du henger (studs/s)
	MAKS_INNTREKK = 50,      -- høyeste fart tauet kan dra deg innover med (studs/s)
	MIN_LENGDE = 7,          -- korteste tau
	TREKK = 40,              -- jevnt drag mot festet (studs/s²)
	TREKK_EKSTRA = 110,      -- ekstra drag mens du holder SPACE
	SVING_KRAFT = 46,        -- hvor mye WASD pumper svingen (studs/s²)
	MAKS_FART = 180,
	SLIPP_BOOST = 1.08,      -- litt ekstra fart når du slipper
	SLIPP_OPP = 8,           -- og et lite løft
	LUFTSTYRING = 34,        -- styring i lufta etter slipp (studs/s²)
	LUFTMOTSTAND = 0.12,     -- andel fart som forsvinner per sekund i lufta
	STARTHOPP = 26,          -- løft når kroken drar deg fra bakken
	VENTETID = 0.18,         -- minste tid mellom to skudd
	TRIKS_BOOST = 1.12,      -- farten ganges med dette når du gjør et triks i lufta (én gang per svev)
	SALTO_FART = 75,         -- slipper du i minst denne farten, tar figuren en salto av seg selv
}

-- ---------------------------------------------------------------- slåssing
Config.KAMP = {
	RYKK_KRAFT = 58,         -- fart motstanderen rykkes mot deg med
	RYKK_OPP = 28,
	SPARK_MIN_FART = 62,     -- så fort må du fly for å gi flyspark
	SPARK_AVSTAND = 6.5,
	STUN = 0.8,              -- sekunder uten krok etter å ha blitt truffet
	RAGDOLL = 1.5,           -- sekunder som slapp filledukke
	SVIMMEL = 2.6,           -- sekunder med stjerner rundt hodet
	SIST_TRUFFET = 8,        -- sekunder: den som traff sist får æren når du faller
}

-- ---------------------------------------------------------------- bæring, stjeling og baser
Config.BAER = {
	FART = 0.65,             -- gangfart mens du bærer (andel), Carry Speed-oppgraderingen øker den
	TAU = 0.6,               -- kroken når kortere mens du bærer (andel)
	TA_AVSTAND = 14,         -- hvor nær du må være for å kjøpe, stjele eller snappe (studs)
	SLUPPET_TID = 8,         -- så lenge et mistet egg svever før det flyr hjem
	STJEL_HOLD = 0.6,        -- sekunder du må holde E for å stjele
	-- Hvor tungt det er å bære (0–1): jo sjeldnere, jo kortere når kroken, jo tregere trekkes du inn og
	-- jo saktere går du. Kroken: rekkevidde x (1 - 0.7·vekt), inntrekk x (1 - vekt).
	VEKT = { Common = 0.05, Uncommon = 0.1, Rare = 0.2, Epic = 0.3, Legendary = 0.4, Mythic = 0.5, Secret = 0.6,
		Golden = 0.25, Spooky = 0.3, Meteor = 0.45 },
}

-- Kast opp på kanten: når tauet har dratt deg helt inn mot siden eller undersiden av en øy, blir du kastet i en
-- bue opp og inn på toppen (så du ikke blir hengende under øya).
Config.KANTKAST = {
	AVSTAND = 18,            -- så nær festet du må være
	OVER = 7,                -- toppen av buen er så høyt over øya
	INN = 4,                 -- du lander så langt inn fra kanten
}

Config.BASE = {
	SOKLER_START = 6,
	SOKLER_MAKS = 20,             -- 16 med oppgraderinger + 4 med Extra Slots-passet
	LAAS_TID = 40,           -- sekunder låsen varer (Lock Time-oppgraderingen øker den)
	NYBEGYNNER = 180,        -- sekunder ingen kan stjele fra en ny spiller
	SAMLE_AVSTAND = 4.5,     -- hvor nær pengeplaten du må stå
	STARTPENGER = 100,
	SALG = 0.5,              -- du får denne andelen av eggprisen når du selger (ganger mutasjonen)
}

-- ---------------------------------------------------------------- reiret og eggebåndet
Config.BELTE = {
	INTERVALL = 3.2,         -- sekunder mellom hvert nye egg
	RUNDETID = 80,           -- sekunder egget bruker på én runde rundt reiret
	MAKS_EGG = 30,
}

-- ---------------------------------------------------------------- oppgraderinger (5 nivåer hver)
Config.OPPGRADERINGER = {
	{ id = "tau", navn = "Rope Length", tekst = "Your hook reaches further",
		verdier = { 150, 170, 190, 210, 230, 250 }, enhet = " studs", priser = { 200, 2000, 20000, 200000, 2000000 } },
	{ id = "trekk", navn = "Reel Power", tekst = "Swing faster and higher",
		verdier = { 1.0, 1.1, 1.2, 1.3, 1.4, 1.5 }, enhet = "x", priser = { 300, 3000, 30000, 300000, 3000000 } },
	{ id = "baer", navn = "Carry Speed", tekst = "Run faster with loot",
		verdier = { 0.65, 0.7, 0.75, 0.8, 0.85, 0.9 }, prosent = true, priser = { 250, 2500, 25000, 250000, 2500000 } },
	{ id = "sokler", navn = "Base Slots", tekst = "More birds in your base",
		verdier = { 6, 8, 10, 12, 14, 16 }, enhet = " slots", priser = { 500, 5000, 50000, 500000, 5000000 } },
	{ id = "laas", navn = "Lock Time", tekst = "Your shield lasts longer",
		verdier = { 40, 50, 60, 70, 80, 90 }, enhet = " s", priser = { 300, 3000, 30000, 300000, 3000000 } },
}

-- ---------------------------------------------------------------- hendelser
Config.HENDELSER = {
	GULLREGN_FORST = 360,    -- sekunder etter serverstart til første Golden Egg Rain
	GULLREGN_HVERT = 720,    -- og så hvert 12. minutt
	GULLREGN_VARER = 90,
	GULLREGN_INTERVALL = 2.5, -- sekunder mellom hvert gullegg som faller
	GULLEGG_LIGGER = 30,     -- så lenge et gullegg ligger før det forsvinner
	GULLEGG_FLAKS = 4,       -- flaks når arten til et gullegg trekkes
	KOSMISK_FORST = 900,     -- Cosmic Night etter 15 minutter
	KOSMISK_HVERT = 1500,    -- og så hvert 25. minutt
	KOSMISK_VARER = 180,
	KOSMISK_SJANSE = 0.04,   -- sjanse for at et nytt egg på båndet er et Secret-egg (Cosmic Shoebill)
	KOSMISK_FLAKS = 3,
	STORM_FORST = 600,       -- Storm etter 10 minutter
	STORM_HVERT = 1080,      -- og så hvert 18. minutt
	STORM_VARER = 100,
	STORM_VIND = 26,         -- hvor hardt vinden dytter deg i lufta (studs/s²)
	LYN_INTERVALL = 3.5,     -- sekunder mellom lynnedslagene
	LYN_VARSEL = 1.6,        -- så lenge den lysende ringen varsler før lynet slår ned
	LYN_RADIUS = 9,
	THUNDERBIRD_BONUS = 3,   -- Thunderbird (og andre lyn-fugler) tjener x3 i stormen
	METEOR_FORST = 1200,     -- Meteor Egg etter 20 minutter
	METEOR_HVERT = 900,      -- og så hvert 15. minutt
	METEOR_VARSEL = 12,      -- sekunder fra «METEOR INCOMING» til nedslaget
	METEOR_RADIUS = 13,      -- spillere så nær nedslaget blir slengt vekk
	METEOR_LIGGER = 60,      -- så lenge meteoregget ligger før det forsvinner
}

-- ---------------------------------------------------------------- sesonger
-- "auto" = Halloween i oktober (og første uka i november). Sett "Halloween" eller nil for å tvinge.
Config.SESONG = "auto"
Config.SPOOKY_SJANSE = 0.08      -- sjansen for at et nytt egg på båndet er et Spooky Egg i Halloween-sesongen

-- ---------------------------------------------------------------- rebirth
Config.REBIRTH = {
	PRIS = 25000000,         -- første rebirth koster $25M, så ganges prisen med FAKTOR
	FAKTOR = 8,
	BONUS = 0.5,             -- +50 % inntekt for hver rebirth
	TAU = { "Gold", "Lava", "Ice", "Galaxy" }, -- tau-farger du låser opp (rebirth 1, 2, 3, 4+)
}

-- ---------------------------------------------------------------- Robux (game passes og produkter)
-- Lag dem på create.roblox.com → spillet → Monetization (Passes / Developer Products) etter at spillet er
-- publisert, og lim inn ID-ene her. ID = 0 betyr «ikke laget ennå» (knappen viser «Soon»).
Config.ROBUX = {
	PASS = {
		{ id = "VIP", passId = 0, navn = "VIP", tekst = "x2 cash from all your birds + a golden VIP tag", robux = 199 },
		{ id = "AutoCollect", passId = 0, navn = "Auto Collect", tekst = "Your cash flies straight to you — no walking to the pad", robux = 99 },
		{ id = "ExtraSlots", passId = 0, navn = "+4 Base Slots", tekst = "Room for 4 more birds in your base", robux = 149 },
		{ id = "RainbowRope", passId = 0, navn = "Rainbow Rope", tekst = "Your grappling rope shines in all colors", robux = 49 },
	},
	PRODUKT = {
		{ id = "ServerLuck", produktId = 0, navn = "Server Luck x2", tekst = "15 minutes: rare eggs twice as common for EVERYONE", robux = 49 },
		{ id = "Cash", produktId = 0, navn = "Cash Pack", tekst = "10 minutes of your income (at least $1K)", robux = 25 },
	},
	LUCK_TID = 900,           -- sekunder Server Luck varer
}

Config.FALL_GRENSE = -30       -- under denne Y er du falt ned i skyene
Config.RESPAWN_TID = 2
Config.LAGRE_HVERT = 60        -- sekunder mellom hver lagring

-- ---------------------------------------------------------------- lyd (gratis lyder fra Roblox sitt bibliotek)
local function id(n)
	return "rbxassetid://" .. n
end
Config.LYD = {
	skudd = id(9120629100),       -- Web Shoot Short Juicy Launch 1
	fest = id(9119072660),        -- Shield Clang As Hit Metal
	festStein = id(9116677587),   -- Metal Impact Railroad Hammer
	vinsj = id(9116908667),       -- Metal Winch Gears 1 (løkke)
	slipp = id(9126229255),       -- Whoosh By Fast
	vind = id(9125742262),        -- Plasma Trails Constant Airy Whooshing Windy (løkke)
	tausvisj = id(9125419776),    -- Cable Swish
	rykk = id(9113510797),        -- Body Hit Slap 3
	spark = id(9119061631),       -- Sharp Punch 8
	bom = id(9120704978),         -- Whooshes Fast Wipes (kroken bommer)
	fall = "rbxasset://sounds/oof.ogg",
	landing = "rbxasset://sounds/action_jump_land.mp3",
	vindsus = id(9114057104),     -- Desert Wind Whistley Light Gusts 1 (bakgrunn)
	-- Steal a Bird
	kjop = id(9113728042),        -- Cash Register 1
	mynter = id(9113704038),      -- Candy Machine Coin Drops Insert Vending 4
	knekk = id(9113959343),       -- Crack Egg Crunchy 11
	pop = id(9117841338),         -- Pop Airy 1
	magi = id(9116394545),        -- Magic Glows Soft Clusters Of Chiming Hits 1
	forvandling = id(9116421342), -- Magic Transformation 5 (klekking av sjeldne)
	skjold = id(9116421639),      -- Magic Transformation 8 (låsen)
	alarm = id(9118781307),       -- Sci- Fi Siren Constant Varied Alarms 1
	kvitring = id(9114891754),    -- Jungle Bird 1
	svimmel = id(9113844972),     -- Cockatiel Bird Interior Whistling Chirps 1
	jubel = id(9112766176),       -- Crowd Cheer And Applause 1
	triks = id(9119226670),       -- Slow Whoosh Airy Rumble Slicing Spinning 1
	tungLanding = id(9118617342), -- Rock Impact Large Hit Scrape 1
	floyte = id(9119198140),      -- Slide Whistle 4 (når du blir rykket)
	fuglesang = id(9118752742),   -- Rural Daytime Ext Birds Tweeting Chirping 1 (bakgrunn)
	torden = id(9120018172),      -- Thunder Distant Boom Thud Rapid Hits 20
	lyn = id(9116282875),         -- Lightning Strike Sharp Hissing Crack 5
	regn = id(9112853287),        -- Rain Heavy 1 (løkke)
	ildkule = id(9114428537),     -- Fireball 1 (meteoren faller)
	smell = id(9117876706),       -- Power Explosions Big Heavy Searing Boom 2 (nedslaget)
	spokelse = id(9119464660),    -- Spirit Fly Bys Spooky Windy Airy Pass Bys 7
	spokevind = id(9114625745),   -- Gods Wind Spooky Eerie 2 (bakgrunn i Halloween-sesongen)
}
Config.MUSIKK = {
	id(1839885740), -- Flying So High (APM)
	id(1842755603), -- High Flying (APM)
	id(9047876673), -- Happy Adventure (APM)
}

return Config
