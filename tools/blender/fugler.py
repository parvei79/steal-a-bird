"""
Fuglene i Steal a Bird, i blokkstil (voksler). Hver fugl blir 3–4 modeller:

    <Navn>           kropp med hode, nebb, bein og hale
    <Navn>_VingeH    høyre vinge (+x)  — leddet i `hengselH`, flakser rundt fuglens fremover-akse
    <Navn>_VingeV    venstre vinge (speilbilde)
    <Navn>_Ekstra    (valgfri) del som svever og roterer rundt `ekstra` (planetring, glorie ...)

Alle delene bygges rundt samme origo (bakken under fuglen), med forsiden mot +Y. Vingene bygges i
hvilestillingen sin; koden i spillet roterer dem rundt hengselet for å flakse.
Punkter i ModelInfo (relativt til origo): hengselH, hengselV, hode, hale, topp, (ekstra).

Fargene registreres når modulen importeres (før palett_materiale), så importer den tidlig.
"""
import math

import rbxlib as R
from fuglebygg import Fugl, S, OYE, SOT_OYE, bein, fot  # noqa: F401
from voksel import Voksler, farge_trio, langs

# ------------------------------------------------------------------ farger
_TRIO = dict(
    # Due
    due='#8f9bab', duevinge='#7a8697', duehals='#3fa38a', duelilla='#8a5cb0', duesvart='#3c414b',
    duefot='#e07f86',
    # Tukan
    tukansvart='#2a2a33', tukanvinge='#33333f', tukanbryst='#fff0ad', tukangul='#ffcc22',
    tukanoransje='#ff8a1f', tukanrod='#e5352b', tukangronn='#7ccf3a', tukanbla='#46b8ff', tukanfot='#6f8fda',
    # Skonebbstork
    skogra='#7f91a6', skogramork='#5d6d83', skonebb='#d3c486', skonebbflekk='#a39570', skonebbkrok='#857452',
    skofot='#424a58', ojeblek='#f4efbd',
    # Dodo
    dodogra='#8e9aae', dodolys='#cbd2de', dodohud='#e6d9b3', dodonebb='#d1c45c', dodokrok='#998c33',
    dodofot='#e6c53e', dodohale='#f6f3ea',
    # Arkeopteryks
    arkkropp='#2e9f7e', arkbuk='#a2e2c9', arkvinge='#2f80d2', arktupp='#1c2635', arksnute='#ea987b',
    arkfot='#6d4b30',
    # Terrorfugl
    terrorbrun='#5f4b40', terrorlys='#ad8d6c', terrornebb='#ecdba2', terrorkrok='#2b2420', terrorkam='#2f2622',
    terrorfot='#b49a5e',
    # Fønix
    fgull='#ffc21a', fgullys='#ffe680', foransje='#ff8a1f', frod='#ea3a2a', fmorkrod='#aa2020',
    fnebb='#ff9d2e', ffot='#ff7b2e',
    # Cosmic Shoebill
    kosmos='#352a85', kosmosmork='#1f1752', nebula1='#7c46ea', nebula2='#ff4fb0', nebula3='#36d8ff',
    kosmosnebb='#8a78ee', kosmosring='#ffd54d', kosmosring2='#ff9de0',
)
for _n, _h in _TRIO.items():
    farge_trio(_n, _h)


# ------------------------------------------------------------------ fuglene

def due():
    """Pigeon (Common): grå, skimrende hals, oransje øye, rosa føtter."""
    f = Fugl()
    k = f.kropp
    for s in (-1, 1):
        bein(k, s * 0.75, (-0.15, 1.1), (-0.1, 0.3), 'duefot')
        fot(k, s * 0.75, -0.1, 'duefot', form='T')
    k.ellipsoide((0, -0.2, 1.8), (1.05, 1.35, 0.95), 'due', rot=(-14, 0, 0), p=2.3)
    k.ellipsoide((0, 0.45, 2.6), (0.78, 0.62, 0.75), 'duehals')
    k.prikker([('duelilla', 0.45)], bare=['duehals'])
    k.ellipsoide((0, 0.62, 3.1), (0.64, 0.66, 0.62), 'due', p=2.2)
    k.kjegle((0, 1.15, 3.05), (0, 1.75, 2.9), 0.22, 0.16, 'duesvart')
    k.boks((-0.2, 1.2, 3.1), (0.2, 1.4, 3.3), 'hvit')                      # den hvite nesevorten
    k.stempel_par((0.62, 0.75, 3.2), ['oo', 'ok'], {'o': 'ojeoransje', 'k': 'svart'})
    k.kjegle((0, -1.3, 1.6), (0, -2.25, 1.2), 0.42, 0.48, 'due', bredde=1.5, hoyde=0.55)
    k.boks((-1.2, -2.6, 0.6), (1.2, -1.95, 1.8), 'duesvart', modus='mal')
    w = f.vinge
    w.ellipsoide((1.02, -0.45, 1.95), (0.3, 1.05, 0.68), 'duevinge', rot=(-14, 0, 0))
    for y in (-0.85, -0.25):
        w.boks((0.6, y - 0.12, 1.4), (1.5, y + 0.12, 2.5), 'duesvart', modus='mal')
    f.hengsel = (0.95, 0.15, 2.4)
    f.punkter = dict(hode=(0, 0.62, 3.1), hale=(0, -2.2, 1.2), topp=(0, 0.6, 3.75))
    return f


def tukan():
    """Toucan (Uncommon): svart, gul hake, kjempenebb i regnbuefarger."""
    f = Fugl()
    k = f.kropp
    for s in (-1, 1):
        bein(k, s * 0.45, (-0.2, 1.0), (-0.1, 0.3), 'tukanfot')
        fot(k, s * 0.45, -0.1, 'tukanfot', form='stump')
    k.ellipsoide((0, -0.25, 1.95), (1.05, 1.15, 1.2), 'tukansvart', rot=(-16, 0, 0), p=2.3)
    k.ellipsoide((0, 0.35, 3.2), (0.84, 0.86, 0.8), 'tukansvart', p=2.2)
    k.ellipsoide((0, 0.8, 2.55), (0.95, 0.6, 0.9), 'tukanbryst', modus='mal')
    k.ellipsoide((0, 1.0, 3.0), (0.75, 0.45, 0.45), 'tukanbryst', modus='mal')
    k.ellipsoide((0, -0.95, 1.0), (0.65, 0.5, 0.4), 'tukanrod', modus='mal')
    # nebbet: høyt og smalt, grønt -> gult -> oransje -> rød spiss
    nebb = ['tukangronn', 'tukangul', 'tukangul', 'tukanoransje', 'tukanoransje', 'tukanrod']
    k.ellipsoide((0, 2.0, 3.2), (0.46, 1.4, 0.62), langs((0, 0.8, 0), (0, 3.4, 0), nebb), p=2.4)
    k.kjegle((0, 3.05, 3.35), (0, 3.5, 2.85), 0.36, 0.12, 'tukanrod')
    k.boks((-0.6, 0.7, 3.0), (0.6, 3.6, 3.08), 'tukansvart', modus='mal')          # munnlinje
    k.stempel_par((0.82, 0.55, 3.35), ['bbb', 'bkb', 'bbb'], {'b': 'tukanbla', 'k': 'svart'})
    k.kjegle((0, -1.15, 1.5), (0, -2.3, 0.7), 0.42, 0.4, 'tukansvart', bredde=1.4, hoyde=0.55)
    w = f.vinge
    w.ellipsoide((1.02, -0.45, 2.05), (0.3, 1.0, 0.85), 'tukanvinge', rot=(-16, 0, 0))
    f.hengsel = (0.95, 0.2, 2.65)
    f.punkter = dict(hode=(0, 0.35, 3.2), hale=(0, -2.3, 0.7), topp=(0, 0.4, 4.1))
    return f


def skonebbstork(p=None):
    """Shoebill (Rare): høy og grå, kjempestort skonebb, og et stirrende blikk."""
    p = p or dict(kropp='skogra', mork='skogramork', nebb='skonebb', flekk='skonebbflekk', krok='skonebbkrok',
                  fot='skofot', oye='ojeblek', pupill='svart')
    f = Fugl()
    k = f.kropp
    for s in (-1, 1):
        bein(k, s * 0.75, (-0.25, 2.5), (-0.15, 0.3), p['fot'])
        fot(k, s * 0.75, -0.15, p['fot'], form='T', lengde=4)
    k.ellipsoide((0, -0.35, 3.4), (1.1, 1.15, 1.45), p['kropp'], rot=(-22, 0, 0), p=2.3)
    k.ellipsoide((0, 0.3, 4.6), (0.78, 0.72, 0.8), p['kropp'])
    k.ellipsoide((0, 0.5, 5.4), (0.86, 0.86, 0.86), p['kropp'], p=2.4)
    k.kjegle((0, -0.15, 5.9), (0, -0.8, 6.35), 0.32, 0.12, p['kropp'])          # dusk bak på hodet
    # skonebbet: langt, bredt og flatt som en tresko, med kjøl på toppen og krok ytterst
    k.kjegle((0, 1.0, 5.3), (0, 3.45, 5.2), 0.74, 0.5, p['nebb'], hoyde=0.55)
    k.kjegle((0, 1.1, 5.62), (0, 3.35, 5.45), 0.2, 0.16, p['nebb'])
    if p.get('flekk'):
        k.prikker([(p['flekk'], 0.28)], bare=[p['nebb']])
    k.kjegle((0, 3.35, 5.4), (0, 3.8, 4.75), 0.32, 0.12, p['krok'])
    k.stempel_par((0.86, 0.7, 5.55), ['mmm', 'ooo', 'oko', 'ooo'],
                  {'m': p['mork'], 'o': p['oye'], 'k': p['pupill']})
    k.kjegle((0, -1.5, 2.65), (0, -2.05, 1.95), 0.45, 0.35, p['mork'], bredde=1.35, hoyde=0.6)
    w = f.vinge
    w.ellipsoide((1.06, -0.55, 3.45), (0.3, 1.15, 1.15), p['mork'], rot=(-22, 0, 0))
    f.hengsel = (0.98, 0.15, 4.25)
    f.punkter = dict(hode=(0, 0.5, 5.4), hale=(0, -2.0, 2.0), topp=(0, 0.4, 6.4))
    return f


def kosmisk_skonebb():
    """Cosmic Shoebill (Secret): en skonebbstork laget av verdensrommet, med planetring."""
    p = dict(kropp='kosmos', mork='kosmosmork', nebb='kosmosnebb', flekk=None, krok='kosmosring',
             fot='kosmosmork', oye='ojecyan', pupill='hvit')
    f = skonebbstork(p)
    k, w = f.kropp, f.vinge
    k.ellipsoide((0, -0.9, 3.9), (1.2, 0.9, 0.8), 'nebula1', modus='mal')
    k.ellipsoide((0, 0.0, 6.0), (0.9, 0.8, 0.45), 'nebula2', modus='mal')
    k.ellipsoide((0, 0.9, 2.6), (0.9, 0.6, 0.7), 'nebula3', modus='mal')
    w.ellipsoide((1.2, -1.0, 3.0), (0.6, 0.8, 0.7), 'nebula2', modus='mal')
    w.ellipsoide((1.2, 0.0, 3.9), (0.6, 0.6, 0.5), 'nebula1', modus='mal')
    for v in (k, w):
        v.prikker([('stjerne', 0.07), ('stjernegul', 0.04)],
                  bare=['kosmos', 'kosmosmork', 'kosmosnebb', 'nebula1', 'nebula2', 'nebula3'], fro=11)
    e = Voksler(S)
    e.ring((0, -0.3, 3.5), (0.35, 0.15, 1.0), 2.55, 0.42, 0.3,
           lambda q, t: 'kosmosring2' if (t * 16) % 4 < 1 else 'kosmosring')
    f.ekstra = e
    f.punkter['ekstra'] = (0, -0.3, 3.5)
    return f


def dodo():
    """Dodo (Epic): rund og blid, bar ansiktshud og et stort krokete nebb."""
    f = Fugl()
    k = f.kropp
    for s in (-1, 1):
        bein(k, s * 0.75, (-0.1, 1.2), (-0.1, 0.3), 'dodofot', r=0.3)
        fot(k, s * 0.75, -0.1, 'dodofot', form='T', klo='klo')
    k.ellipsoide((0, -0.1, 2.35), (1.6, 1.75, 1.5), 'dodogra', p=2.3)
    k.ellipsoide((0, 0.8, 1.95), (1.25, 1.0, 1.1), 'dodolys', modus='mal')
    k.ellipsoide((0, 1.2, 3.8), (0.88, 0.92, 0.88), 'dodogra', p=2.2)
    k.ellipsoide((0, 1.85, 3.75), (0.8, 0.45, 0.62), 'dodohud', modus='mal')
    k.ellipsoide((0, 2.45, 3.62), (0.46, 1.0, 0.45), 'dodonebb', p=2.4)
    k.ellipsoide((0, 2.35, 3.25), (0.38, 0.8, 0.26), 'dodonebb')
    k.kjegle((0, 3.25, 3.85), (0, 3.62, 3.2), 0.36, 0.12, 'dodokrok')
    k.stempel_par((0.85, 1.4, 3.95), SOT_OYE, OYE)
    k.ellipsoide((0, -1.85, 2.95), (0.55, 0.45, 0.6), 'dodohale')
    k.ellipsoide((0, -2.0, 3.5), (0.36, 0.36, 0.42), 'dodohale')
    k.kjegle((0, -1.95, 3.7), (0, -1.6, 4.1), 0.25, 0.12, 'dodohale')
    w = f.vinge
    w.ellipsoide((1.6, -0.2, 2.5), (0.3, 0.68, 0.52), 'dodolys', rot=(-20, 0, 0))
    f.hengsel = (1.5, 0.15, 2.85)
    f.punkter = dict(hode=(0, 1.2, 3.8), hale=(0, -2.0, 3.4), topp=(0, 1.1, 4.7))
    return f


def arkeopteryks():
    """Archaeopteryx (Legendary): urfugl med tenner, klør på vingene og fjærkledd øglehale."""
    f = Fugl()
    k = f.kropp
    for s in (-1, 1):
        x = s * 0.45
        k.kjegle((x, -0.3, 2.0), (x, 0.05, 1.15), 0.32, 0.24, 'arkkropp')
        bein(k, x, (0.05, 1.15), (-0.15, 0.3), 'arkfot')
        fot(k, x, -0.1, 'arkfot', form='stump', klo='klo')
    k.ellipsoide((0, -0.15, 2.4), (0.95, 1.35, 0.95), 'arkkropp', rot=(10, 0, 0), p=2.2)
    k.ellipsoide((0, 0.4, 2.05), (0.78, 0.95, 0.7), 'arkbuk', modus='mal')
    k.kjegle((0, 0.85, 2.75), (0, 1.2, 3.15), 0.45, 0.4, 'arkkropp')
    k.ellipsoide((0, 1.35, 3.35), (0.6, 0.72, 0.58), 'arkkropp', p=2.2)
    k.kjegle((0, 1.8, 3.25), (0, 2.8, 3.1), 0.36, 0.22, 'arksnute', bredde=0.95, hoyde=0.8)
    for n in range(4):
        y = 1.95 + n * 0.6
        k.boks((-0.4, y, 2.85), (0.4, y + 0.25, 3.0), 'tann', modus='mal')
    k.stempel_par((0.57, 1.45, 3.5), ['yk', 'yy'], {'y': 'ojegul', 'k': 'svart'})
    for n in range(3):
        k.kjegle((0, 1.05 - n * 0.32, 3.75 - n * 0.1), (0, 0.8 - n * 0.4, 4.2 - n * 0.14), 0.24, 0.1, 'arkvinge')
    k.kjegle((0, -1.2, 2.3), (0, -4.25, 2.0), 0.26, 0.15, 'arkkropp')
    for n in range(8):
        y = -1.5 - n * 0.36
        for s in (-1, 1):
            k.kjegle((0, y, 2.2), (s * (0.6 + n * 0.05), y - 0.4, 2.12), 0.2, 0.12,
                     ['arkvinge', 'arkvinge', 'arktupp'])
    w = f.vinge
    w.kjegle((0.85, 0.2, 2.85), (2.85, 0.25, 2.75), 0.26, 0.18, 'arkvinge')
    w.ellipsoide((1.4, -0.25, 2.8), (0.65, 0.55, 0.22), 'arkvinge')
    for n in range(6):
        x0 = 1.05 + n * 0.33
        lengde = 0.95 + n * 0.16
        w.kjegle((x0, 0.2, 2.8), (x0 + n * 0.12, 0.2 - lengde, 2.72), 0.24, 0.16,
                 ['arkvinge', 'arkvinge', 'arktupp'])
    for n in range(3):
        w.kjegle((2.0 + n * 0.28, 0.35, 2.85), (2.08 + n * 0.32, 0.8, 2.75), 0.18, 0.1, 'klo')
    f.hengsel = (0.85, 0.15, 2.85)
    f.punkter = dict(hode=(0, 1.35, 3.35), hale=(0, -4.2, 2.0), topp=(0, 1.0, 4.3))
    return f


def terrorfugl():
    """Terror Bird (Legendary): stor, sint, flyger ikke — men har et nebb som en øks."""
    f = Fugl()
    k = f.kropp
    for s in (-1, 1):
        x = s * 1.05
        k.kjegle((x, -0.7, 3.0), (x, -0.25, 1.6), 0.5, 0.38, 'terrorbrun')
        bein(k, x, (-0.25, 1.6), (-0.4, 0.3), 'terrorfot', r=0.26)
        fot(k, x, -0.4, 'terrorfot', form='gaffel', klo='klo')
    k.ellipsoide((0, -0.65, 3.3), (1.2, 1.75, 1.15), 'terrorbrun', rot=(6, 0, 0), p=2.3)
    k.ellipsoide((0, 0.3, 2.85), (0.95, 1.0, 0.75), 'terrorlys', modus='mal')
    k.kjegle((0, 0.6, 3.7), (0, 1.35, 4.95), 0.68, 0.56, 'terrorbrun')
    k.ellipsoide((0, 1.6, 5.35), (0.82, 1.0, 0.85), 'terrorbrun', p=2.3)
    # øksenebbet: høyt, kraftig og krokete
    k.ellipsoide((0, 2.95, 5.2), (0.52, 1.3, 0.78), 'terrornebb', p=2.6)
    k.kjegle((0, 2.0, 5.85), (0, 3.9, 5.75), 0.24, 0.2, 'terrornebb')
    k.kjegle((0, 3.95, 5.7), (0, 4.45, 4.7), 0.45, 0.14, 'terrorkrok')
    k.boks((-0.8, 2.0, 4.9), (0.8, 4.2, 5.0), 'terrorkrok', modus='mal')       # munnlinje
    # bust: mørke pigger bakover langs hodet og nakken
    for n in range(5):
        k.kjegle((0, 1.25 - n * 0.4, 5.95 - n * 0.3), (0, 0.6 - n * 0.5, 6.45 - n * 0.4), 0.28, 0.1,
                 ['terrorbrun', 'terrorkam'])
    k.stempel_par((0.82, 1.9, 5.55), ['mm..', '.mmm', '.yk.'], {'m': 'svart', 'y': 'ojegul', 'k': 'svart'})
    for n in (-1, 0, 1):
        k.kjegle((0, -2.1, 3.55), (n * 0.7, -3.3, 3.35 + abs(n) * 0.2), 0.36, 0.2, ['terrorbrun', 'terrorkam'])
    w = f.vinge
    w.ellipsoide((1.22, -0.55, 3.5), (0.3, 0.8, 0.55), 'terrorlys', rot=(15, 0, 0))
    f.hengsel = (1.12, -0.05, 3.85)
    f.punkter = dict(hode=(0, 1.6, 5.35), hale=(0, -3.2, 3.3), topp=(0, 1.2, 6.6))
    return f


def fonix(p=None):
    """Phoenix (Mythic): gullfugl med flammefjær i vingene, toppen og halen."""
    p = p or dict(gull='fgull', lys='fgullys', oransje='foransje', rod='frod', nebb='fnebb', fot='ffot')
    G, L, O, Rd = p['gull'], p['lys'], p['oransje'], p['rod']
    flamme = [G, G, O, O, Rd]
    f = Fugl()
    k = f.kropp
    for s in (-1, 1):
        x = s * 0.45
        bein(k, x, (-0.25, 1.75), (-0.1, 0.3), p['fot'])
        fot(k, x, -0.1, p['fot'], form='stump', klo='klo')
    k.ellipsoide((0, -0.25, 2.8), (1.1, 1.3, 1.3), G, rot=(-18, 0, 0), p=2.2)
    k.ellipsoide((0, 0.55, 2.55), (0.85, 0.6, 0.95), L, modus='mal')
    k.ellipsoide((0, 0.6, 4.2), (0.78, 0.82, 0.78), G, p=2.2)
    k.kjegle((0, 1.3, 4.2), (0, 2.0, 3.9), 0.32, 0.12, p['nebb'])
    k.kjegle((0, 1.9, 4.0), (0, 2.05, 3.65), 0.2, 0.1, p['nebb'])
    k.stempel_par((0.78, 0.85, 4.35), ['.wk', 'rkk'], {'w': 'hvit', 'k': 'svart', 'r': Rd})
    for (y1, z1) in ((0.35, 6.1), (-0.55, 5.85), (-1.15, 5.3)):
        k.kjegle((0, 0.45, 4.75), (0, y1, z1), 0.32, 0.1, [G, O, O, Rd])
    for n in (-2, -1, 0, 1, 2):
        slutt = (n * 0.62, -3.5 - (0.5 if n == 0 else 0), 1.15 + abs(n) * 0.28)
        k.kjegle((0, -1.3, 2.35), slutt, 0.34, 0.14, flamme)
    k.kjegle((0, -4.0, 1.15), (0, -4.6, 1.75), 0.18, 0.1, Rd)                  # krøll på midtfjæra
    w = f.vinge
    for n in range(6):
        a = math.radians(14 + n * 13)
        lengde = 2.5 + n * 0.22 - (0.45 if n == 5 else 0)
        w.kjegle((1.05, -0.15, 3.7), (1.05 + lengde * math.cos(a), -0.45 - n * 0.1, 3.7 + lengde * math.sin(a)),
                 0.34, 0.12, flamme)
    w.ellipsoide((1.55, -0.2, 4.05), (0.72, 0.32, 0.72), G)
    f.hengsel = (0.95, -0.1, 3.65)
    f.punkter = dict(hode=(0, 0.6, 4.2), hale=(0, -3.6, 1.2), topp=(0, 0.3, 6.2))
    return f


# ------------------------------------------------------------------ katalog
# navn (id i spillet) -> byggefunksjon
FUGLER = {
    'Pigeon': due,
    'Toucan': tukan,
    'Shoebill': skonebbstork,
    'Dodo': dodo,
    'Archaeopteryx': arkeopteryks,
    'TerrorBird': terrorfugl,
    'Phoenix': fonix,
    'CosmicShoebill': kosmisk_skonebb,
}

# Fuglegruppene (laget i egne moduler) legges til automatisk hvis de finnes.
for _modul in ('fugler_vanlige', 'fugler_sjeldne', 'fugler_legender'):
    try:
        _m = __import__(_modul)
    except ModuleNotFoundError as _feil:
        if _feil.name != _modul:
            raise
        continue
    FUGLER.update(_m.FUGLER)

DELER = ('', '_VingeH', '_VingeV', '_Ekstra')


def bygg(navn_liste=None):
    for navn in (navn_liste or FUGLER):
        FUGLER[navn]().ferdig(navn)


def render(mappe, navn_liste, filnavn='_fugler.png', oppl=512, kolonner=4, retning=(1.0, 1.6, 0.9)):
    """Ett bilde per fugl med alle delene på plass, og et kontrollark."""
    import os
    import bpy
    sc, cam = R._scene_for_render(oppl)
    os.makedirs(mappe, exist_ok=True)
    for info in R.MODELLER.values():
        info['obj'].hide_render = True
    for navn in navn_liste:
        obs = []
        for d in DELER:
            info = R.MODELLER.get(navn + d)
            if not info:
                continue
            m = info['midt']                       # Roblox (x, y, z) -> Blender (x, -z, y)
            info['obj'].location = (m[0], -m[2], m[1])
            info['obj'].hide_render = False
            obs.append(info['obj'])
        bpy.context.view_layer.update()
        lo, hi = R._bbox(obs)
        R._sikt(cam, lo, hi, retning)
        sc.render.filepath = os.path.join(mappe, f'{navn}.png')
        bpy.ops.render.render(write_still=True)
        for o in obs:
            o.hide_render = True
    R._kontrollark(mappe, list(navn_liste), oppl, kolonner=kolonner, filnavn=filnavn)
    for info in R.MODELLER.values():
        info['obj'].hide_render = False
