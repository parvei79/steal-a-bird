# STEAL A BIRD 🪝🐦

Sving deg mellom svevende øyer med gripekrok, kjøp rare egg, klekk sjeldne fugler — og STJEL de beste
fuglene fra de andres baser! Rykk tyvene ned fra himmelen før de stikker av med din Phoenix.

- **Reiret i midten:** egg ruller rundt på et transportbånd. Kjøp med E og bær egget hjem over hodet.
- **8 baser** på svevende blokk-øyer med hengebroer inn til Reiret. Eggene klekkes på soklene og blir fugler
  som tjener penger hvert sekund. Hent pengene på COLLECT-platen.
- **Stjel:** hold E på en fugl i en annen base og løp hjem med den. Eieren får alarm og kan rykke deg med kroken.
  Da ragdoller du, blir svimmel, og fuglen flyr hjem igjen.
- **LOCK-knappen** gir et skjold over basen en stund. Nye spillere har 3 minutter nybegynnerskjold.
- **31 fugler** i 7 sjeldenheter (Common → Secret) + 5 Halloween-fugler (36 i alt), med mutasjoner (Gold,
  Diamond, Rainbow, Galaxy) og samlebok med 3D-bilder.
- **Butikk** med oppgraderinger, **trading** mellom spillere, og **dans** (Chicken Dance, Wave, Flex, Victory).
- Kode-animasjoner på figurene: svingepositur i tauet, salto og skru, superhelt-landing, ragdoll, svimmel,
  bærepositur, lysspor og fartsstreker.
- Alt er blokkstil: øyene er bygget av kuber, og fuglene er voksel-figurer laget med kode i Blender.
- **Hendelser** (én om gangen):
  - **Golden Egg Rain** (hvert 12. minutt): gullegg faller ned på øyene, og alle kjemper om dem.
  - **Storm** (hvert 18. minutt): vind, regn og lyn som slenger folk. Thunderbirds tjener x3.
  - **Cosmic Night** (hvert 25. minutt): natt, mer flaks, og Secret-egg med Cosmic Shoebill på båndet.
  - **Meteor Egg** (hvert 15. minutt): et brennende egg styrter ned (Epic eller bedre), og alle løper dit.
- **Halloween** (automatisk i oktober): Spooky Eggs med fem Halloween-fugler, gresskar og flaggermus.
- **Rebirth:** du starter på nytt, og fuglene tjener +50 % for alltid. Du får også nye taufarger.
- **Globale topplister** på Reiret, og en **veiledning** med fire mål for nye spillere.
- **Robux:**
  - game passes: VIP, Auto Collect, +4 Base Slots og Rainbow Rope
  - produkter: Server Luck og Cash Pack

Spillteksten er på engelsk. Planen står i `PLAN.md`.

## Kom i gang

```bash
/Applications/Blender.app/Contents/MacOS/Blender -b --factory-startup -P tools/blender/bygg_modeller.py
tools/sjekk.sh
python3 tools/test_luau.py test/server.test.lua --mock
python3 tools/test_luau.py test/klient.test.lua --mock
python3 tools/bygg_place.py
```

Åpne `build/StealABird.rbxlx` i Studio (Cmd+O). Første gang: **Import 3D** → `assets/FuglModeller.glb` →
**Import** → Cmd+S. Trykk **Play**. Uten import virker spillet med enkle kloss-fugler.

## Styring

| | Mus og tastatur | Mobil |
|---|---|---|
| Skyt kroken / hold deg fast | Hold venstre musknapp | Hold HOOK |
| Slipp og fly videre | Slipp knappen | Slipp HOOK |
| Triks i lufta (litt ekstra fart) | Q | TRICK |
| Sving / styr i lufta | WASD | Styrespak |
| Kjøp / stjel / selg / lås | E (hold for å stjele) | Trykk på knappen |
| Butikk, samlebok, trading, dans | F, G, T, B (dans direkte: 1–4) | Knappene til venstre |
| Fri musepeker (for å klikke) | ALT | – |

## Publisering

Se **`docs/PUBLISERING.md`** — steg for steg: publisere, Game Settings, teste med venner, game passes og
produkter (ikoner i `assets/robux/`), tekst til spillsiden.

## Robux (når spillet er publisert)

1. På create.roblox.com → spillet → **Monetization** → **Passes**: lag VIP, Auto Collect, +4 Base Slots og
   Rainbow Rope (bilde + pris). Under **Developer Products**: lag Server Luck og Cash Pack.
2. Kopier ID-ene inn i `Config.ROBUX` i `src/shared/Config.lua` (`passId`/`produktId`), og bygg place-fila på nytt.
   Så lenge ID-en er 0, viser butikken «Soon».

Ikon og bilde til spillsiden: `assets/ikon.png` og `assets/thumbnail.png` (lages med `tools/blender/ikon.py`).

## Tester

```bash
python3 tools/test_luau.py test/kart.test.lua --data /tmp/kart.json && python3 tools/vis_kart.py /tmp/kart.json -o assets/previews/_kart.png
python3 tools/test_luau.py test/server.test.lua --mock   # kjøp, klekk, penger, stjel, rykk, lås, salg, bytte, lagring
python3 tools/test_luau.py test/klient.test.lua --mock   # hele spillet med den ekte klientkoden og animasjonene
python3 tools/test_luau.py test/hendelser.test.lua --mock # gullregn, Cosmic Night, rebirth og Robux-kjøp
```

Juster følelsen og økonomien i `src/shared/Config.lua` og `src/shared/Fugler.lua`, og kartet i `src/shared/Kart.lua`.
Nye fugler lages i `tools/blender/fugler.py` (blir med i spillet automatisk når de er bygget).
