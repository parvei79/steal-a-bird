"""
Stiltest: noen fugler i blokkstil, for å se om stilen treffer før vi lager alle.

    /Applications/Blender.app/Contents/MacOS/Blender -b --factory-startup -P tools/blender/stiltest.py [-- Navn ...]
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import rbxlib as R  # noqa: E402

R.tom_scene()
import fugler  # noqa: E402  (registrerer fargene)

ROT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
ARGS = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
R.palett_materiale()

navn = ARGS or list(fugler.FUGLER)
fugler.bygg(navn)
fugler.render(os.path.join(ROT, 'assets', 'previews'), navn, filnavn='_stiltest.png', kolonner=4,
              retning=(1.0, 1.05, 0.7))
print('Ferdig.')
