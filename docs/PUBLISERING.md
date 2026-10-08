# Publisere Steal a Bird — steg for steg

Spillet virker i Studio uten publisering, men **lagring, topplister og Robux-kjøp virker bare når spillet er
publisert**. Følg stegene i rekkefølge. Alt som står i «sitat» kan kopieres rett inn.

## 1. Publiser fra Studio
1. Åpne `build/StealABird.rbxlx` i Studio (Cmd+O) og sjekk at `FuglModeller` er importert (Play → fuglene er
   blokkfugler, ikke kuler). Cmd+S.
2. **File → Publish to Roblox As…** → *Create new experience*.
3. Navn: **Steal a Bird 🐦** — Beskrivelse: se punkt 5. Genre: *Simulation* (eller *All*). Enheter: kryss av for
   Computer, Phone, Tablet (og Console hvis dere vil).
4. Trykk **Create**. Studio jobber nå mot det publiserte spillet (lagre med Cmd+S, publiser endringer med Alt+P).

## 2. Game Settings (Home → Game Settings)
- **Security:** slå på **Enable Studio Access to API Services** (lagring og topplister, også i Studio).
- **Avatar:** Avatar Type = **R15** (animasjonene er laget for R15).
- **Places → (stedet) → Configure Place:** Server Size = **8** (det er 8 baser).
- **Permissions:** la spillet være **Private** til dere har testet med venner. Gjør det **Public** til slutt.

## 3. Test med venner (før det blir offentlig)
- Sett **Playability** til **Friends** (Game Settings → Permissions, eller create.roblox.com → spillet →
  Settings). Da kan alle som er venner med kontoen som eier spillet, bli med. Collaborators gir redigeringstilgang,
  ikke bare spilletilgang, så bruk det ikke til venner.
- Fyll ut **Experience Questionnaire** (punkt 5) før dere inviterer andre, ellers kan noen bli stoppet av
  aldersgrensene.
- Venner finner spillet på profilen din under **Creations**, eller du deler lenken (create.roblox.com → spillet →
  View on Roblox).
- **Oppdatere senere:** når Claude har bygget en ny `StealABird.rbxlx`, åpner du den og velger **File → Publish to
  Roblox As… → det eksisterende spillet** (ikke *Create new*), så **Overwrite**. Ellers får du to spill.
- Test sammen: stjele fra hverandre, rykke tyver med kroken, låse basen, bytte fugler (TRADE), og vent på en
  hendelse (Golden Egg Rain etter 6 min, Storm etter 10, Cosmic Night etter 15, Meteor etter 20).
- I Studio kan dere også teste flere spillere alene: **Test → Clients and Servers → 2 spillere → Start**.

## 4. Robux: game passes og produkter
Ikonene ligger i `assets/robux/` (512×512).

**Game passes** (create.roblox.com → spillet → Monetization → Passes → Create a Pass):

| Navn | Ikon | Forslag pris | Beskrivelse (engelsk) |
|---|---|---|---|
| VIP | VIP.png | 199 | x2 cash from all your birds + a golden VIP tag! |
| Auto Collect | AutoCollect.png | 99 | Your cash flies straight to you — no more walking to the pad. |
| +4 Base Slots | ExtraSlots.png | 149 | Room for 4 more birds in your base. |
| Rainbow Rope | RainbowRope.png | 49 | Your grappling rope shines in all colors. |

Etter at et pass er laget: åpne det, slå på **Item for Sale**, sett prisen, og kopier **ID**-en (tallet i
nettadressen).

**Developer Products** (Monetization → Developer Products → Create):

| Navn | Ikon | Forslag pris | Beskrivelse |
|---|---|---|---|
| Server Luck x2 | ServerLuck.png | 49 | 15 minutes: rare eggs twice as common for EVERYONE in the server! |
| Cash Pack | CashPack.png | 25 | 10 minutes of your income (at least $1K). |

**Lim inn ID-ene** i `src/shared/Config.lua` → `Config.ROBUX` (`passId` / `produktId`), så be Claude bygge
place-fila på nytt (eller kjør `python3 tools/bygg_place.py`), åpne den på nytt og publiser (Alt+P).
Butikken viser «Soon» så lenge ID-en er 0.

## 5. Spillsiden (create.roblox.com → spillet → Overview / Places)
**Ikon:** `assets/ikon.png`. **Thumbnail/bilde:** `assets/thumbnail.png` (gjerne flere skjermbilder fra spillet).

**Beskrivelse** (lim inn):
> 🐦 STEAL A BIRD! 🐦
> Swing between floating islands with your GRAPPLING HOOK, buy weird eggs, hatch rare birds — and STEAL the
> best birds from other players' bases!
>
> 🥚 36 birds to collect: pigeons, toucans, shoebills, dodos, dinosaur birds, the PHOENIX… and a SECRET one 👀
> 🪝 Yank thieves out of the sky with your hook before they run off with YOUR Phoenix!
> 🔒 Lock your base, 💰 collect cash, ⬆️ upgrade, 🌟 rebirth for more cash forever
> 🤝 Trade birds with friends
> ⛈️ Events: Golden Egg Rain, Storm, Cosmic Night and METEOR EGGS!
> 🎃 HALLOWEEN: Spooky Eggs with limited Halloween birds — only in October!
>
> 👍 LIKE + ⭐ FAVORITE for new birds every week!

**Maturity/innholdsspørsmål** (Experience Questionnaire): svar ærlig — «mild cartoon violence» (krok/rykk)
er det eneste som er relevant. Ingen chat-endringer, ingen ekte penger utenom Robux-kjøpene.

## 6. Når spillet er ute
- Se på **Analytics** etter et par dager (hvor lenge folk spiller, hvor mange som kommer tilbake).
- **Oppdater ofte** de første ukene — nye fugler, nye hendelser. Roblox løfter fram spill som oppdateres.
- Skriv **[UPDATE]** eller **🎃** i navnet når det kommer noe nytt (f.eks. «🎃 Steal a Bird [HALLOWEEN]»).
- Sander kan lage korte klipp: «I stole a MYTHIC Phoenix with a grappling hook!»
