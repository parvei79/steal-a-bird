"""
Alle 3D-modellene i Steal a Bird, bygget med kode (blokkstil).

    /Applications/Blender.app/Contents/MacOS/Blender -b --factory-startup -P tools/blender/bygg_modeller.py
    ... -- --uten-bilder        (raskere: ingen forhåndsvisninger)

Skriver:
    assets/FuglModeller.glb      importeres i Studio (Import 3D), blir mappen «FuglModeller»
    assets/previews/_fugler.png  alle fuglene satt sammen (kropp + vinger)
    assets/previews/_ark.png     alle rekvisittene
    src/shared/ModelInfo.lua     størrelser og punkter (generert)
Konvensjoner (se rbxlib.py): 1 enhet = 1 stud, +Z opp, forsiden mot +Y (= LookVector i Roblox).
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import rbxlib as R  # noqa: E402

R.tom_scene()
import fugler  # noqa: E402  (registrerer fargene)
import rekvisitter  # noqa: E402

ROT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
ARGS = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
R.palett_materiale(lagre_png=os.path.join(ROT, 'assets', 'palett.png'))

fugler.bygg()
rekvisitter.bygg_alle()

R.skriv_modelinfo(os.path.join(ROT, 'src', 'shared', 'ModelInfo.lua'), 'tools/blender/bygg_modeller.py')
R.eksporter_glb(os.path.join(ROT, 'assets', 'FuglModeller.glb'), 'FuglModeller')
print(f'Eksporterte {len(R.MODELLER)} modeller til assets/FuglModeller.glb')

if '--uten-bilder' not in ARGS:
    mappe = os.path.join(ROT, 'assets', 'previews')
    fugler.render(mappe, list(fugler.FUGLER), filnavn='_fugler.png', kolonner=4, retning=(1.0, 1.05, 0.7))
    rekv = [n for n in R.MODELLER if not any(n == f or n.startswith(f + '_') for f in fugler.FUGLER)]
    R.render_forhandsvisning(mappe, bare=rekv, filnavn='_ark.png')
print('Ferdig.')
