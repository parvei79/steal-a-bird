# STEAL A BIRD — plan

*Spillet er på engelsk. Planen og koden er på norsk.*

**Pitch (slik den står i Roblox):**
> 🪝🐦 Swing between floating islands with your grappling hook, buy weird eggs, hatch rare birds — and STEAL
> the best birds from other players' bases! Yank thieves out of the sky before they get away with YOUR Phoenix.

## 1. Kjerneløkka

1. **Reiret i midten:** egg ruller rundt et stort reir på et transportbånd. Hvert egg viser sjeldenhet og pris.
   Sjeldne egg dukker sjelden opp, og hele serveren får beskjed: *«A MYTHIC EGG appeared!»*
2. **Kjøp egget** med E eller ved å trykke. Du bærer det over hodet hjem til basen din.
3. **Rømm hjem.** Mens du bærer, er tauet kortere og du er tregere. Andre kan rykke deg med kroken eller gi deg
   flyspark. Da mister du egget, det svever i 8 sekunder, og **hvem som helst kan snappe det**. Ellers flyr det hjem
   til deg.
4. **Egget klekkes** på en sokkel i basen og blir en fugl. Fuglen tjener penger hvert sekund.
5. **Hent pengene** på COLLECT-platen og kjøp sjeldnere egg og oppgraderinger.
6. **Stjel!** Gå eller sving inn i andres baser, hold E på en fugl og løp hjem med den.
   - Treffer eieren deg med kroken, flyr fuglen tilbake.
   - Kommer du hjem, er den din.

## 2. Verden (én server = 8 spillere)

- **Reiret:** en stor blokk-øy i midten med et kjempereir og eggebåndet rundt.
- **8 baser:** svevende blokk-øyer i en ring rundt reiret, ca. 165 studs fra midten. Hver base har:
  - hengebro inn til Reiret
  - 16 sokler (6 åpne fra start)
  - LOCK-knapp, COLLECT-plate og et skilt med navnet ditt
- **Svevesteiner** mellom øyene til å svinge seg i, og skyhav under.
- **Faller du,** dukker du opp igjen i basen din.
- **Stilen er blokker:**
  - Øyene er bygget av store kuber.
  - Fuglene er bygget av små kuber med litt ulike nyanser, slik som i bildet Sander viste, men ikke en kopi.
  - Alt lages med kode i Blender (`tools/blender/voksel.py`).

## 3. Fuglene (31 stk, 7 sjeldenheter)

| Sjeldenhet | Sjanse på båndet | Eggpris | Penger/s | Klekketid | Fugler |
|---|---|---|---|---|---|
| Common | 45 % | $40 | 2–4 | 8 s | Pigeon, Sparrow, Seagull, Chicken, Duck, Crow |
| Uncommon | 28 % | $500 | 15–22 | 15 s | Puffin, Toucan, Flamingo, Penguin, Kiwi |
| Rare | 15 % | $6K | 90–130 | 30 s | Shoebill, Secretary Bird, Hoatzin, Cassowary, Peacock |
| Epic | 8 % | $75K | 550–750 | 45 s | Harpy Eagle, Snowy Owl, Lyrebird, Quetzal, Dodo |
| Legendary | 3,3 % | $1M | 3,6K–4,8K | 60 s | Archaeopteryx, Terror Bird, Haast's Eagle, Moa, Pterodactyl |
| Mythic | 0,7 % | $15M | 28K–36K | 90 s | Phoenix, Ice Phoenix, Roc, Thunderbird |
| **Secret** | bare i hendelser | — | 200K | 120 s | **Cosmic Shoebill** (Claude sitt valg) |

*Tallene står i `src/shared/Fugler.lua` og `Config.lua`. Det er lett å justere dem etter testing.
Bare fugler som er laget i Blender, dukker opp på båndet. Foreløpig er 8 av 31 laget.*

- **Fuglene er en blanding:**
  - rare ekte fugler: skonebbstork, hoatzin, kasuar
  - utdødde: dodo, moa, Haast's eagle, terrorfugl, arkeopteryks, pterodaktyl
  - mytiske: Phoenix, Roc, Thunderbird
- **Cosmic Shoebill:**
  - en skonebbstork laget av verdensrommet
  - stjerner i fjærene, lysende øyne og en planetring som går rundt den
  - finnes bare i hendelser
- **Mutasjoner** ved klekking: Gold ×2 (5 %), Diamond ×3 (2 %), Rainbow ×5 (0,8 %), Galaxy ×10 (0,2 %). Fuglen får glans, gnister eller regnbuefarger.
- **Index (samleboka)** viser alle fugler og mutasjoner du har funnet.
- **Selg** en fugl (hold E på din egen) for å få plass til bedre fugler.

## 4. Stjeling — reglene

- Du må ha en ledig sokkel hjemme for å stjele.
- **Lås:** LOCK-knappen gir et skjold over basen. Det varer 40 sekunder, og du kan oppgradere det til 90.
  - Andre blir dyttet ut og kan ikke stjele.
  - Du må være hjemme for å låse igjen.
- **Nybegynnerskjold:** ingen kan stjele fra deg de første 3 minuttene.
- **Tyven får et rødt «THIEF!»-merke.** Eieren får alarm og en pil som peker mot tyven.
- **Rykk eller flyspark mot tyven:** tyven ragdoller og blir svimmel, og fuglen flyr hjem igjen.
- **Serveren bestemmer alt:** penger, avstand, eierskap og tidtakere. Klienten ber bare om ting.

## 5. Bytte fugler (trading)

- Trykk TRADE og velg en spiller. Den andre må godta.
- I byttevinduet legger begge inn fugler fra basen sin.
- Begge trykker READY, og så kommer en nedtelling på 5 sekunder. Endrer noen noe, starter den på nytt.
- **Serveren sjekker** at begge fortsatt eier fuglene, at ingen av dem blir båret, og at det er plass. Så byttes de.
- Man kan ikke bytte mens man bærer noe. Antall forespørsler er begrenset, så ingen kan spamme.

## 6. Animasjoner (kode, ikke Roblox-animasjoner)

Alle figurer animeres med kode i `Positurer.lua`, og alle spillere ser hverandres animasjoner.

**Spilleren:**
- **Svingepositur:** krok-armen strekker seg mot festet, beina henger etter, og kroppen lener seg i farten.
- **Salto og skru:** salto når du slipper i høy fart. Trykk Q i lufta for et triks, som gir litt ekstra fart én gang per svev.
- **Superhelt-landing:** høyt fall gir landing på ett kne med knyttneven i bakken, en støvsky, en sjokkbølge og kamerarist.
- **Ragdoll:** når du blir rykket eller sparket, slenger armer og bein slapt rundt mens du tumler. Så reiser du deg.
- **Svimmel:** stjerner går i ring rundt hodet etter et rykk.
- **Bærepositur:** begge armene opp med egget eller fuglen over hodet, og tunge steg.
- **Snappe:** når du tar noe, går armene ut og så opp.
- **Feiring på knapper:** Chicken Dance (vinger med armene), Wave, Flex og Victory.
- **Effekter:**
  - lysspor fra hendene i høy fart
  - fartsstreker på skjermen
  - sjokkbølge ved landing
  - «YOINK!» og «STOLEN!» som tegneserietekst

**Fuglene:**
- vipper og puster når de står stille
- flakser med vingene innimellom
- hopper når de tjener penger, med «+$12» over seg
- flakser vilt når de blir båret av en tyv

**Klekking:**
- Egget vugger mer og mer og sprekker, og skallbiter spruter ut.
- Fuglen spretter opp og snurrer, flakser og lander på sokkelen.
- Sjeldenhetsfargen lyser som en søyle, og Epic eller sjeldnere gir konfetti.

**Spesielle fugler:**
- Phoenix: flammer
- Cosmic Shoebill: ringen går rundt
- mutasjoner: glans

**Grensesnittet:** pengene teller opp, mynter flyr inn i telleren, knappene spretter, og skjermen blinker rødt ved alarm.

## 7. Oppgraderinger (SHOP)

| Oppgradering | Fra → til | Pris (5 nivåer) |
|---|---|---|
| Rope Length | 150 → 250 studs | $200 → $2M |
| Reel Power | ×1,0 → ×1,5 | $300 → $3M |
| Carry Speed | 65 % → 90 % fart med last | $250 → $2,5M |
| Base Slots | 6 → 16 sokler | $500 → $5M |
| Lock Time | 40 → 90 s | $300 → $3M |

Senere kommer **Rebirth**: du starter på nytt og får mer inntekt for alltid.

## 8. Lagring

- **Hva lagres:** penger, fugler (art, mutasjon, egg/klekket), oppgraderinger, samleboka og antall tyverier.
- **Hvor:** DataStore, med «session lock», så to servere ikke skriver samtidig.
- **Når:** hvert 60. sekund, når du går ut og når serveren stenges.
- I Studio uten API-tilgang spiller vi uten lagring og får en advarsel. Lagring virker først når spillet er publisert
  og «Enable Studio Access to API Services» er slått på.

## 9. Hendelser (steg 3)

- **Golden Egg Rain:** gratis gylne egg regner ned på øyene, og man kan snappe dem fra hverandre.
- **Cosmic Night:** 1 % sjanse for Cosmic Shoebill-egg på båndet.
- **Storm** ✅: vind, regn og lynnedslag (med varselring) som slenger folk; Thunderbirds tjener x3.
- **Meteor Egg** ✅: et brennende egg styrter ned på en øy etter 12 sekunders varsel (Epic/Legendary/Mythic).
- **Halloween** ✅ (oktober): Spooky Eggs med fem Halloween-fugler, gresskar og flaggermus.

## 10. Inntekter (steg 4, etter Roblox sine regler)

- **Game passes:** VIP (×2 penger), Auto Collect, Rainbow Rope og Extra Slots.
- **Produkter:** Server Luck i 15 minutter og pengepakker.
- Alle betalte tilfeldige ting viser sjansene.
- Spillet er gratis å spille, og ingenting er umulig uten Robux.

## 11. Steg

| Steg | Innhold |
|---|---|
| **0. Grunnmur** ✅ | Verktøy, tester og blokkfugler fra GRAPPLER |
| **1. MVP** ✅ | Reiret med eggebånd, 8 baser, kjøpe og bære, klekke, penger, stjele, rykke, låse, nybegynnerskjold, lagring, alle spiller-animasjonene, 8 fugler. Venter på test i Studio |
| **2. Fremgang** ✅ | Butikk, trading, samlebok, mutasjoner og alle 31 fuglene |
| **3. Liv** ✅ | Golden Egg Rain, Cosmic Night, globale topplister, veiledning for nye spillere, lyder og musikk |
| **4. Lansering** | Ikon og bilder ✅, game passes og produkter med ikoner ✅, publiseringsguide ✅ (`docs/PUBLISERING.md`). Gjenstår (Pål): test med venner, publisere, lage ID-ene |
| **5. Oppdateringer** | Rebirth ✅, Storm og Meteor ✅, Halloween-sesongen ✅. Senere: flere fugler, juleegg i desember |

## 12. Risiko

- **Tapt lagring er det verste.** Vi bruker session lock, prøver på nytt ved feil og tester med falsk DataStore.
- **Juksing:** serveren sjekker avstand, pris, eierskap og tidtakere.
- **Kroken kan være vanskelig for nybegynnere.** Hengebroene gjør at alle kan gå.
- **Vi trenger mange fugler.** Fuglebyggeren `tools/blender/fugler.py` gjør at en ny fugl tar ca. 20 linjer kode.
