"""
Rekvisittene i Steal a Bird, i samme blokkstil som fuglene: eggene (én per sjeldenhet + gulleegget),
sokkelen fuglene står på, låseknappen, pengeplaten, kjempereiret i midten, trær og steiner,
skiltet, mynten, skallbiter og krokpistolen med kroken.

Konvensjoner som i rbxlib: 1 enhet = 1 stud, +Z opp, forsiden mot +Y, origo på bakken midt under.
Fargene registreres når modulen importeres (før palett_materiale).
"""
import math

import rbxlib as R
from voksel import Voksler, farge_trio

_TRIO = dict(
    # egg
    eggkrem='#f3ead2', eggbrun='#9c7a55', egggronn='#8fe08a', egggronnmork='#3fa864', eggbla='#7cc8ff',
    eggblamork='#2f7fd6', egglilla='#b07ef2', eggrosa='#ff8fd8', egggull='#ffcf33', eggoransje='#ff8a2a',
    eggrod='#ff4d4d', egggul='#ffe94d', eggregngronn='#4ddc6a', eggregnbla='#4d9dff', eggregnlilla='#a65cff',
    eggkosmos='#2e2575', eggskinn='#fff6c9',
    # sokkel og base
    stein='#9aa0a8', steinmork='#6c727c', halm='#e3c06a', halmmork='#b68c3c', tre='#9a6a3e', treMork='#6e4826',
    knapprod='#ff3b3b', fare='#ffd21f', faresvart='#2a2a2e', pengegronn='#38c172', pengegull='#ffd43b',
    # reiret
    kvist='#a47447', kvistmork='#74502e', kvistlys='#caa070', dun='#f7f2e6',
    # natur
    palmestamme='#b5874f', palmeblad='#4fbf4a', palmebladmork='#2f8f3a', kokos='#6b4a2b', bladgronn='#5ccf5a',
    bladmork='#3a9a44', blomstrosa='#ff7eb6', blomstgul='#ffe14d', blomsthvit='#ffffff', grastopp='#6fd35c',
    # krok
    pistolrod='#e63946', metall='#a7b0ba', metallmork='#4a515c', gummi='#2b2c31', kobber='#d4823c',
    mynt='#ffcf33', myntmork='#e0a21a',
)
for _n, _h in _TRIO.items():
    farge_trio(_n, _h)
R.farger(r_svart='#16161c', r_hvit='#ffffff', r_lys='#fff6a8', r_gull_lys='#fff2a0')

EGG_STR = 0.3   # kubestørrelse for egg

# ------------------------------------------------------------------ egg


def _eggform(v, farge, hoyde=2.5):
    """Eggform: bred nede, smalere oppe. Origo på bakken."""
    r = hoyde * 0.4
    v.ellipsoide((0, 0, hoyde * 0.42), (r, r, hoyde * 0.42), farge)
    v.ellipsoide((0, 0, hoyde * 0.55), (r * 0.86, r * 0.86, hoyde * 0.45), farge)


def egg(navn, monster):
    v = Voksler(EGG_STR)
    hoyde = 2.5
    if monster == 'common':
        _eggform(v, 'eggkrem', hoyde)
        v.prikker([('eggbrun', 0.12)], bare=['eggkrem'], fro=3)
    elif monster == 'uncommon':
        _eggform(v, 'egggronn', hoyde)
        for (x, y, z, r) in ((0.9, 0.2, 1.0, 0.45), (-0.5, 0.7, 1.7, 0.4), (0.2, -0.9, 1.5, 0.45),
                             (-0.8, -0.4, 0.7, 0.4), (0.4, 0.6, 2.2, 0.3)):
            v.ellipsoide((x, y, z), (r, r, r), 'egggronnmork', modus='mal')
    elif monster == 'rare':
        _eggform(v, 'eggbla', hoyde)

        def sikksakk(p, _t):
            vinkel = math.atan2(p.y, p.x)
            return 'eggblamork' if abs(p.z - (1.25 + 0.22 * math.sin(vinkel * 6))) < 0.2 else None
        v.ellipsoide((0, 0, 1.25), (1.2, 1.2, 0.6), sikksakk, modus='mal')
    elif monster == 'epic':
        _eggform(v, 'egglilla', hoyde)
        v.prikker([('eggrosa', 0.16)], bare=['egglilla'], fro=5)
        for (x, y, z) in ((0.8, 0.4, 1.4), (-0.7, -0.5, 1.1), (0.0, 0.85, 0.8)):
            v.ellipsoide((x, y, z), (0.35, 0.35, 0.35), 'eggrosa', modus='mal')
    elif monster == 'legendary':
        _eggform(v, 'egggull', hoyde)
        v.boks((-2, -2, 0.55), (2, 2, 0.8), 'eggoransje', modus='mal')
        v.boks((-2, -2, 1.2), (2, 2, 1.45), 'eggoransje', modus='mal')
        v.boks((-2, -2, 1.85), (2, 2, 2.05), 'eggoransje', modus='mal')
        v.prikker([('r_gull_lys', 0.05)], bare=['egggull'], fro=9)
    elif monster == 'mythic':
        _eggform(v, 'eggrod', hoyde)
        regnbue = ['eggrod', 'eggoransje', 'egggul', 'eggregngronn', 'eggregnbla', 'eggregnlilla']

        def bander(p, _t):
            return regnbue[min(5, max(0, int(p.z / hoyde * 6)))]
        v.ellipsoide((0, 0, 1.25), (2, 2, 1.4), bander, modus='mal')
    elif monster == 'secret':
        _eggform(v, 'eggkosmos', hoyde)
        v.prikker([('r_hvit', 0.08), ('egggul', 0.04), ('eggrosa', 0.03)], bare=['eggkosmos'], fro=13)
    elif monster == 'golden':
        _eggform(v, 'egggull', hoyde)
        v.prikker([('r_hvit', 0.06), ('r_gull_lys', 0.12)], bare=['egggull'], fro=17)
    R.ny_modell()
    v.lag()
    return R.ferdig_modell(navn, punkter={'topp': (0, 0, hoyde)})


# ------------------------------------------------------------------ base


def sokkel():
    """Steinsokkel med et halmreir på toppen. Fuglen står på `topp`."""
    v = Voksler(0.4)
    v.ellipsoide((0, 0, 0.6), (1.75, 1.75, 0.8), 'stein', p=3.5)
    v.boks((-2, -2, -1), (2, 2, 0.0), 'stein', modus='fjern')
    v.ring((0, 0, 0.2), (0, 0, 1), 1.75, 0.4, 0.4, 'steinmork')
    v.ellipsoide((0, 0, 1.45), (1.6, 1.6, 0.45), 'halm', p=2.5)
    v.ellipsoide((0, 0, 1.75), (1.15, 1.15, 0.45), 'halm', modus='fjern')
    v.prikker([('halmmork', 0.3)], bare=['halm'], fro=21)
    R.ny_modell()
    v.lag()
    return R.ferdig_modell('Sokkel', punkter={'topp': (0, 0, 1.4)})


def laaseknapp():
    """Stor rød knapp på en søyle med fare-striper. `knapp` = toppen av knappen."""
    v = Voksler(0.3)
    v.boks((-1.0, -1.0, 0), (1.0, 1.0, 2.4), 'faresvart')

    def striper(p, _t):
        return 'fare' if int((p.x + p.y + p.z * 1.2) / 0.6) % 2 == 0 else 'faresvart'
    v.boks((-1.1, -1.1, 0), (1.1, 1.1, 0.7), striper, modus='mal')
    v.boks((-1.1, -1.1, 1.8), (1.1, 1.1, 2.4), striper, modus='mal')
    v.boks((-1.3, -1.3, 2.4), (1.3, 1.3, 2.8), 'metallmork')
    v.ellipsoide((0, 0, 2.85), (0.95, 0.95, 0.65), 'knapprod', p=2.4)
    R.ny_modell()
    v.lag()
    return R.ferdig_modell('LaaseKnapp', punkter={'knapp': (0, 0, 3.4)})


def pengeplate():
    """Flat grønn plate med en gul $ på toppen."""
    v = Voksler(0.4)
    v.boks((-3.0, -3.0, 0), (3.0, 3.0, 0.4), 'pengegronn')
    v.boks((-3.0, -3.0, 0), (3.0, 3.0, 0.4), lambda p, _t: 'pengegull' if max(abs(p.x), abs(p.y)) > 2.5 else None,
           modus='mal')
    dollar = [
        '..###..',
        '.#####.',
        '##.#...',
        '.####..',
        '...####',
        '...#.##',
        '.#####.',
        '..###..',
    ]
    for r, rad in enumerate(dollar):
        for c, tegn in enumerate(rad):
            if tegn == '#':
                x = (c - 3) * 0.4 + 0.2
                y = (3.5 - r) * 0.4
                v.boks((x - 0.1, y - 0.1, 0.45), (x + 0.1, y + 0.1, 0.75), 'pengegull')
    R.ny_modell()
    v.lag()
    return R.ferdig_modell('PengePlate')


def skilt():
    """Treskilt på to stolper. `tavle` = midten av forsiden av tavla (der navnet står)."""
    v = Voksler(0.3)
    for s in (-1, 1):
        v.boks((s * 2.4 - 0.2, -0.2, 0), (s * 2.4 + 0.2, 0.2, 3.0), 'treMork')
    v.boks((-3.2, -0.25, 2.6), (3.2, 0.25, 5.2), 'tre')
    v.boks((-3.2, -0.3, 2.6), (3.2, 0.3, 5.2), lambda p, _t: 'treMork' if (abs(p.x) > 2.95 or p.z < 2.85 or p.z > 4.95)
           else None, modus='mal')
    R.ny_modell()
    v.lag()
    return R.ferdig_modell('Skilt', punkter={'tavle': (0, 0.3, 3.9)})


def mynt():
    v = Voksler(0.2)
    v.plate((0, 0, 0.8), (0, 1, 0), 0.8, 0.25, 'mynt')
    v.ring((0, 0, 0.8), (0, 1, 0), 0.7, 0.2, 0.35, 'myntmork')
    v.boks((-0.1, -0.3, 0.45), (0.1, 0.3, 1.15), 'myntmork')
    R.ny_modell()
    v.lag()
    return R.ferdig_modell('Mynt')


def skallbit():
    v = Voksler(0.2)
    v.ellipsoide((0, 0, 0.3), (0.5, 0.4, 0.3), 'eggkrem')
    v.ellipsoide((0, 0, 0.45), (0.4, 0.3, 0.25), 'eggkrem', modus='fjern')
    R.ny_modell()
    v.lag()
    return R.ferdig_modell('Skallbit')


# ------------------------------------------------------------------ reiret og naturen


def kjempereir():
    """Det store reiret i midten: en skål av flettede kvister, med dun inni. Origo på bakken."""
    v = Voksler(0.75)
    v.ellipsoide((0, 0, 3.0), (13.0, 13.0, 4.6), 'kvist', p=2.6)
    v.boks((-14, -14, -3), (14, 14, 0), 'kvist', modus='fjern')
    v.ellipsoide((0, 0, 5.4), (10.2, 10.2, 4.2), 'kvist', modus='fjern')

    def flett(p, _t):
        vinkel = math.atan2(p.y, p.x)
        s = math.sin(vinkel * 18 + p.z * 1.7) + math.sin(vinkel * 11 - p.z * 2.3)
        return 'kvistmork' if s > 0.9 else ('kvistlys' if s < -1.2 else 'kvist')
    v.ellipsoide((0, 0, 3.0), (13.5, 13.5, 5.0), flett, modus='mal')
    # løse kvister som stikker ut av kanten
    for n in range(26):
        a = n / 26 * 2 * math.pi
        r0, r1 = 11.0, 14.8 + (n % 3) * 0.9
        z0 = 5.2 + (n % 4) * 0.35
        v.kjegle((math.cos(a) * r0, math.sin(a) * r0, z0),
                 (math.cos(a + 0.25) * r1, math.sin(a + 0.25) * r1, z0 + 1.2 - (n % 2) * 1.6), 0.5, 0.35, 'kvistmork')
    # dun i bunnen
    v.ellipsoide((0, 0, 2.2), (8.5, 8.5, 1.0), 'dun', p=2.2)
    R.ny_modell()
    v.lag()
    return R.ferdig_modell('Kjempereir', punkter={'bunn': (0, 0, 2.6)})


def palme(navn='Palme', boy=1.0):
    v = Voksler(0.4)
    topp = (0, 0, 0)
    forrige = (0, 0, 0)
    for n in range(10):
        t = (n + 1) / 10
        p = (boy * 1.6 * t * t, 0, 10.5 * t)
        v.kjegle(forrige, p, 0.75 - 0.25 * t, 0.7 - 0.25 * t, 'palmestamme' if n % 2 else 'treMork')
        forrige = p
    topp = forrige
    for n in range(7):
        a = n / 7 * 2 * math.pi + 0.3
        ut = (topp[0] + math.cos(a) * 4.6, topp[1] + math.sin(a) * 4.6, topp[2] - 1.6)
        mid = (topp[0] + math.cos(a) * 2.4, topp[1] + math.sin(a) * 2.4, topp[2] + 0.6)
        v.kjegle(topp, mid, 0.55, 0.5, 'palmeblad')
        v.kjegle(mid, ut, 0.5, 0.2, ['palmeblad', 'palmebladmork'])
    for n in range(3):
        a = n / 3 * 2 * math.pi
        v.ellipsoide((topp[0] + math.cos(a) * 0.6, topp[1] + math.sin(a) * 0.6, topp[2] - 0.6), (0.45, 0.45, 0.45),
                     'kokos')
    R.ny_modell()
    v.lag()
    return R.ferdig_modell(navn)


def tre():
    v = Voksler(0.5)
    v.kjegle((0, 0, 0), (0, 0, 5), 0.9, 0.7, 'tre')
    v.ellipsoide((0, 0, 6.5), (3.2, 3.2, 2.8), 'bladgronn', p=2.4)
    v.ellipsoide((1.6, 0.8, 5.3), (1.8, 1.8, 1.6), 'bladgronn', p=2.4)
    v.ellipsoide((-1.5, -1.0, 5.6), (1.7, 1.7, 1.5), 'bladgronn', p=2.4)
    v.prikker([('bladmork', 0.25)], bare=['bladgronn'], fro=4)
    R.ny_modell()
    v.lag()
    return R.ferdig_modell('Tre')


def busk():
    v = Voksler(0.4)
    v.ellipsoide((0, 0, 0.9), (1.8, 1.6, 1.2), 'bladgronn', p=2.4)
    v.prikker([('bladmork', 0.25), ('blomstrosa', 0.05), ('blomstgul', 0.04)], bare=['bladgronn'], fro=6)
    R.ny_modell()
    v.lag()
    return R.ferdig_modell('Busk')


def steinblokk():
    v = Voksler(0.5)
    v.ellipsoide((0, 0, 1.2), (2.2, 1.8, 1.6), 'stein', p=2.8)
    v.ellipsoide((1.2, 0.6, 0.9), (1.2, 1.1, 1.0), 'stein', p=2.8)
    v.prikker([('steinmork', 0.3)], bare=['stein'], fro=8)
    v.boks((-3, -3, -2), (3, 3, 0), 'stein', modus='fjern')
    R.ny_modell()
    v.lag()
    return R.ferdig_modell('Steinblokk')


def blomster():
    v = Voksler(0.25)
    for n, (x, y, f) in enumerate(((0, 0, 'blomstrosa'), (0.8, 0.5, 'blomstgul'), (-0.7, 0.6, 'blomsthvit'),
                                   (0.4, -0.8, 'blomstrosa'), (-0.6, -0.5, 'blomstgul'))):
        h = 0.8 + (n % 3) * 0.25
        v.kjegle((x, y, 0), (x, y, h), 0.13, 0.13, 'bladmork')
        v.ellipsoide((x, y, h + 0.1), (0.3, 0.3, 0.15), f)
        v.boks((x - 0.1, y - 0.1, h), (x + 0.1, y + 0.1, h + 0.3), 'blomstgul' if f != 'blomstgul' else 'r_hvit')
    R.ny_modell()
    v.lag()
    return R.ferdig_modell('Blomster')


# ------------------------------------------------------------------ krokpistolen og kroken


def krokpistol():
    """Løpet peker mot +Y, håndtaket ned. `grep` = der hånden holder, `munning` = der tauet kommer ut."""
    v = Voksler(0.15)
    v.boks((-0.25, -0.65, -1.4), (0.25, -0.05, 0.0), 'gummi')                      # håndtak
    v.boks((-0.38, -0.9, -0.05), (0.38, 1.4, 0.65), 'pistolrod')                   # kropp
    v.boks((-0.4, -0.9, 0.5), (0.4, 1.4, 0.62), 'fare')                            # stripe
    v.kjegle((0.0, 1.2, 0.3), (0.0, 2.55, 0.3), 0.28, 0.28, 'metallmork')          # løp
    v.kjegle((0.0, 2.35, 0.3), (0.0, 2.75, 0.3), 0.38, 0.38, 'metall')             # munning
    v.kjegle((0.38, -0.3, 0.3), (0.62, -0.3, 0.3), 0.48, 0.48, 'metall')           # tautrommel
    v.kjegle((0.4, -0.3, 0.3), (0.66, -0.3, 0.3), 0.32, 0.32, 'r_svart')
    v.boks((-0.1, 0.05, -0.55), (0.1, 0.25, -0.1), 'metallmork')                    # avtrekker
    R.ny_modell()
    v.lag()
    return R.ferdig_modell('KrokPistol', grep=(0, -0.35, -0.7), punkter={'munning': (0, 2.8, 0.3)})


def krok():
    """Klørne peker mot +Y. `ring` = der tauet er festet."""
    v = Voksler(0.15)
    v.kjegle((0, -0.8, 0), (0, 0.6, 0), 0.22, 0.22, 'metall')
    v.ring((0, -0.95, 0), (1, 0, 0), 0.28, 0.16, 0.18, 'metallmork')
    for n in range(3):
        a = n / 3 * 2 * math.pi
        rx, rz = math.cos(a), math.sin(a)
        v.kjegle((0, 0.4, 0), (rx * 0.75, 0.9, rz * 0.75), 0.17, 0.14, 'metall')
        v.kjegle((rx * 0.75, 0.9, rz * 0.75), (rx * 0.55, 1.35, rz * 0.55), 0.15, 0.08, 'metallmork')
    R.ny_modell()
    v.lag()
    return R.ferdig_modell('Krok', punkter={'ring': (0, -1.0, 0)})


EGG = {
    'Common': 'common', 'Uncommon': 'uncommon', 'Rare': 'rare', 'Epic': 'epic', 'Legendary': 'legendary',
    'Mythic': 'mythic', 'Secret': 'secret', 'Golden': 'golden',
}


def bygg_alle():
    for sj, m in EGG.items():
        egg('Egg' + sj, m)
    sokkel()
    laaseknapp()
    pengeplate()
    skilt()
    mynt()
    skallbit()
    kjempereir()
    palme('Palme', 1.0)
    palme('PalmeBoy', 2.2)
    tre()
    busk()
    steinblokk()
    blomster()
    krokpistol()
    krok()
