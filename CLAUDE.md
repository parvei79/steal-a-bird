# STEAL A BIRD — notater for Claude

Roblox-spill for Pål og Sander (12): kjøp egg, klekk fugler, stjel fra hverandre, med gripekroken fra GRAPPLER.
Norsk i kode, kommentarer, commits og svar — men ALL spilltekst er på engelsk. Les `docs/ROBLOX-OPPSKRIFT.md`
og `PLAN.md` før du endrer noe.

## Før du sier «ferdig»
1. `tools/sjekk.sh`
2. `python3 tools/test_luau.py test/server.test.lua --mock`, `test/klient.test.lua --mock` og
   `test/hendelser.test.lua --mock` — «INGEN FEIL».
3. Endret kartet? `test/kart.test.lua` + `tools/vis_kart.py`, og se på bildet.
4. Endret modeller/fugler? Bygg i Blender og SE på `assets/previews/_fugler.png` og `_ark.png`.
Etterligningen har ingen ekte fysikk eller grafikk — animasjonene må Pål se i Studio.

## Arkitektur
- **Serveren eier alt** (penger, eierskap, avstand, tidtakere). Klienten ber med remoten `Handling`
  («kjop», «ta», «selg», «laas», «oppgrader», «emote», «triks», «landing», «status») og får `Status` tilbake.
  Hendelser til alle går på `Hendelse`.
- `server/Ting.lua` er hjertet: egg og fugler («ting») på sokler, båret, sluppet; klekking, inntekt, stjeling,
  levering, salg, lagringsliste. `Reiret.lua` = eggebåndet (klientene flytter eggene selv ut fra `Start`).
  `Baser.lua` = eierskap, lås, nybegynnerskjold, pengeplate. `Handel.lua` = trading. `Data.lua` = DataStore med
  session lock (spiller uten lagring hvis det ikke går). `Kamp.lua` = krokpistol, rykk, spark, fall.
  `Hendelser.lua` = Golden Egg Rain og Cosmic Night. `Robux.lua` = game passes/produkter (ID-er i Config.ROBUX,
  kvitteringer lagres så ingenting gis to ganger). `Ledertavle.lua` = globale topplister (OrderedDataStore).
  Rebirth håndteres i `Main.server.lua` (`Ting.nullstill`), inntektsfaktor i `Spillere.faktor`.
- **Fuglemodeller** (`server/Fuglemodell.lua`): usynlig forankret `Rot` → Motor6D «Kropp» → kroppen, og
  Motor6D «VingeH/VingeV» i skuldrene. Klienten (`client/Fugleliv.lua`) animerer `Transform` lokalt.
- **Figur-animasjoner** (`client/Positurer.lua`): settes på Motor6D.Transform i Stepped for ALLE figurer, ut fra
  attributter som serveren setter (Baerer, Emote, Ragdoll, Svimmel, Tyv) og videresendte triks/landinger.
- E-knappene er ProximityPrompts laget på klienten (`client/Prompter.lua`), så teksten blir riktig per spiller.
- Kartet (`shared/Kart.lua`) er ren matematikk; øyene bygges av kuber på 4 studs (`server/Verden.lua`).
- Blokkfuglene: `tools/blender/voksel.py` (voksel-mesher) + `fuglebygg.py` (Fugl, fot, bein) + `fugler.py`
  (de første 8) + `fugler_vanlige/sjeldne/legender.py` (resten, med fargeprefiks a_/b_/c_) + `rekvisitter.py`
  (egg, sokkel, reir, krok ...). ModelInfo genereres. `stiltest.py -- --ut _x.png Navn ...` for raske bilder.
  Ikon og bilde til spillsiden: `ikon.py`.

## Det Pål må gjøre selv
Import av `assets/FuglModeller.glb` (én gang per modellsett), Play, publisering, og i Game Settings:
Avatar = R15, maks 8 spillere, «Enable Studio Access to API Services» (lagring). Etter en ny bygging:
lukk fanen i Studio UTEN å lagre og åpne `build/StealABird.rbxlx` på nytt.
