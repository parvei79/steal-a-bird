"""
Bygg og se på noen fugler raskt (uten å eksportere):

    /Applications/Blender.app/Contents/MacOS/Blender -b --factory-startup -P tools/blender/stiltest.py -- Navn Navn ...
    ... -- --ut _minegruppe.png Navn ...     (eget kontrollark, så flere kan jobbe samtidig)

Uten navn bygges alle fuglene. Bildene havner i assets/previews/ (<Navn>.png og kontrollarket).
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import rbxlib as R  # noqa: E402

R.tom_scene()
import fugler  # noqa: E402  (registrerer fargene, også fuglegruppene)

ROT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
ARGS = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
ut = '_stiltest.png'
if '--ut' in ARGS:
    i = ARGS.index('--ut')
    ut = ARGS[i + 1]
    ARGS = ARGS[:i] + ARGS[i + 2:]
R.palett_materiale()

navn = ARGS or list(fugler.FUGLER)
ukjente = [n for n in navn if n not in fugler.FUGLER]
if ukjente:
    raise SystemExit(f'Ukjente fugler: {ukjente}. Finnes: {list(fugler.FUGLER)}')
fugler.bygg(navn)
fugler.render(os.path.join(ROT, 'assets', 'previews'), navn, filnavn=ut, kolonner=4, retning=(1.0, 1.05, 0.7))
print(f'Ferdig. Palett: {len(R.PALETT)} av {R.RUTER * R.RUTER} farger brukt.')
