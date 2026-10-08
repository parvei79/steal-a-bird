"""
Hendelsesrekvisittene i Steal a Bird, i samme blokkstil som fuglene (voksler):

    EggSpooky    Halloween-egg: oransje gresskar-egg med svarte riller, stilk og et lite, lysende ansikt
    EggMeteor    meteoregg: mørk, ujevn basaltstein med et nett av glødende lavasprekker
    Gresskar     utskåret gresskar (jack-o'-lantern) med lysende ansikt; spillet setter et lys i `lys`
    Flaggermus   liten, søt flaggermus i glideflukt, til pynt som flyr rundt (origo midt i kroppen)

Konvensjoner som i rekvisitter.py: 1 enhet = 1 stud, +Z opp, forsiden mot +Y, origo på bakken midt under.
Eggene har nøyaktig samme form og størrelse som de andre eggene (rekvisitter._eggform).
Fargene (prefiks r2_) registreres når modulen importeres (før palett_materiale); ellers gjenbrukes
fargene fra rekvisitter.py (egggul, faresvart, bladmork, bladgronn, r_hvit).
"""
import math

from mathutils import Vector

import rbxlib as R
from voksel import Voksler, farge_trio
from rekvisitter import EGG_STR, _eggform

_TRIO = dict(
    r2_gresskar='#f06c14', r2_fure='#b8500f',            # gresskar og furene i det
    r2_basalt='#3b3a42', r2_basaltmork='#26252b',        # meteorstein
    r2_lava='#ff6a14', r2_lavarod='#d8301a',             # glødende sprekker
    r2_flaggermus='#3b2f4c', r2_vinge='#6a56a0', r2_rosa='#ff9ec0',
)
for _n, _h in _TRIO.items():
    farge_trio(_n, _h)


# ------------------------------------------------------------------ hjelpere

def _tilf(*tall):
    """Fast «tilfeldig» tall 0..1 ut fra heltall (likt hver gang modellen bygges)."""
    n = 2166136261
    for t in tall:
        n = ((n ^ (int(t) & 0xffffffff)) * 16777619) & 0xffffffff
    n ^= n >> 15
    n = (n * 2246822519) & 0xffffffff
    n ^= n >> 13
    return (n & 0xffffff) / 0xffffff


def _forrest(v):
    """(i, k) -> den fremste kuben (største j) i hver kolonne sett forfra."""
    forrest = {}
    for (i, j, k) in v.celler:
        if j > forrest.get((i, k), -10 ** 6):
            forrest[(i, k)] = j
    return forrest


def _ansikt(v, z_topp, monster, farger):
    """Mal et mønster på forsiden (sett forfra, +y), symmetrisk om x = 0 (partall kolonner, midten
    mellom de to midterste). Rad 0 er øverst, i laget som inneholder z_topp."""
    n = max(len(r) for r in monster)
    k0 = int(math.floor(z_topp / v.s))
    forrest = _forrest(v)
    for r, rad in enumerate(monster):
        for c, tegn in enumerate(rad):
            if tegn in '. ':
                continue
            i, k = c - n // 2, k0 - r
            if (i, k) in forrest:
                v.celler[(i, forrest[(i, k)], k)] = farger[tegn]


def _riller(v, vinkler, farge, sentrum=(0.0, 0.0)):
    """Loddrette riller: i hvert lag males den ytterste kuben nærmest hver vinkel (grader, 0 = rett
    forover, +90 = mot +x). Gir sammenhengende striper som er nøyaktig én kube brede."""
    cx, cy = sentrum
    lag = {}
    for (i, j, k) in v.celler:
        if all((i + a, j + b, k) in v.celler for a, b in ((1, 0), (-1, 0), (0, 1), (0, -1))):
            continue                                       # ikke på overflaten
        lag.setdefault(k, []).append((i, j))
    for k, celler in lag.items():
        for vinkel in vinkler:
            a = math.radians(vinkel)
            ux, uy = math.sin(a), math.cos(a)

            def avvik(c):
                x, y = (c[0] + 0.5) * v.s - cx, (c[1] + 0.5) * v.s - cy
                lengde = math.hypot(x, y) or 1.0
                return -(x * ux + y * uy) / lengde - 0.01 * lengde
            beste = min(celler, key=avvik)
            v.celler[(beste[0], beste[1], k)] = farge


def _furet(c, r, lober=8, bulk=0.12, p=2.2):
    """Gresskarform: avflatet ball med loddrette furer mellom `lober` lober (en lobe midt foran).
    Returnerer (test, furedel) til Voksler._fyll: test(q) sier om q er inni, og furedel(q) gir
    (andel av lobebredden fra fura, avstand fra fura langs overflaten) — til å farge furene."""
    cx, cy, cz = c
    rx, ry, rz = r

    def furedel(q):
        dx, dy = q.x - cx, q.y - cy
        fase = math.atan2(dx, dy) / (2 * math.pi) * lober
        avst = abs((fase % 1.0) - 0.5)
        return avst, avst * 2 * math.pi / lober * math.hypot(dx, dy)

    def test(q):
        g = max(0.0, 1.0 - furedel(q)[0] / 0.2)
        k = 1.0 - bulk * g
        d = abs((q.x - cx) / (rx * k)) ** p + abs((q.y - cy) / (ry * k)) ** p + abs((q.z - cz) / rz) ** p
        return 0.0 if d <= 1 else None
    return test, furedel


# ------------------------------------------------------------------ eggene

def egg_spooky():
    """Halloween-egget: oransje gresskar-egg med svarte riller, en liten stilk og et lysende glis."""
    v = Voksler(EGG_STR)
    hoyde = 2.5
    _eggform(v, 'r2_gresskar', hoyde)
    _riller(v, (-90, -135, 90, 135, 180), 'faresvart')                              # bred lobe foran til ansiktet
    _ansikt(v, 1.65, ['.g..g.',
                      'gg..gg',
                      '......',
                      'g....g',
                      '.gggg.'], {'g': 'egggul'})
    for x in (-0.15, 0.15):
        v.celler[v._celle((x, 0.15, 2.55))] = 'bladmork'
    v.celler[v._celle((0.15, -0.15, 2.55))] = 'bladmork'
    R.ny_modell()
    v.lag()
    return R.ferdig_modell('EggSpooky', punkter={'topp': (0, 0, hoyde)})


def egg_meteor(antall_flak=8):
    """Meteoregget: mørk, ujevn basaltstein delt i store flak av glødende lavasprekker (én kube brede),
    gule og hvitglødende der flakene møtes, og med et rødt skjær her og der."""
    v = Voksler(EGG_STR)
    hoyde = 2.5
    _eggform(v, 'r2_basalt', hoyde)
    v.prikker([('r2_basaltmork', 0.35)], bare=['r2_basalt'], fro=8)
    cz = 1.15
    # flakene: faste retninger spredt jevnt over egget (Fibonacci-kule), litt forskjøvet
    retn = []
    for n in range(antall_flak):
        z = 1 - 2 * (n + 0.5) / antall_flak
        a = n * 2.39996 + 0.5
        rr = math.sqrt(max(0.0, 1 - z * z))
        retn.append((rr * math.cos(a), rr * math.sin(a), z))

    def flak(c):
        x, y, z = (c[0] + 0.5) * v.s, (c[1] + 0.5) * v.s, (c[2] + 0.5) * v.s - cz
        return max(range(len(retn)), key=lambda n: x * retn[n][0] + y * retn[n][1] + z * retn[n][2])
    nabo = ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1))
    overflate = [c for c in v.celler if any((c[0] + a, c[1] + b, c[2] + d) not in v.celler for a, b, d in nabo)]
    hvilket = {c: flak(c) for c in v.celler}
    sprekk = {}
    for c in overflate:
        andre = {hvilket[n] for n in ((c[0] + a, c[1] + b, c[2] + d) for a, b, d in nabo) if n in hvilket}
        andre.discard(hvilket[c])
        if andre and hvilket[c] < max(andre):
            sprekk[c] = len(andre)
    for c, n in sprekk.items():
        v.celler[c] = 'egggul' if n >= 2 or _tilf(*c, 5) < 0.12 else 'r2_lava'
    for (i, j, k) in sprekk:
        for a, b, d in nabo:
            c = (i + a, j + b, k + d)
            if c in v.celler and c not in sprekk and _tilf(*c, 6) < 0.12:
                v.celler[c] = 'r2_lavarod'
    # ujevn stein: noen kuber stikker ut, andre mangler (men ikke i sprekkene, toppen eller bunnen)
    ktopp = max(k for (_, _, k) in v.celler)
    for c, f in list(v.celler.items()):
        if f not in ('r2_basalt', 'r2_basaltmork') or not 1 <= c[2] <= ktopp - 2:
            continue
        frie = [(a, b) for a, b in ((1, 0), (-1, 0), (0, 1), (0, -1)) if (c[0] + a, c[1] + b, c[2]) not in v.celler]
        if not frie:
            continue
        h = _tilf(*c, 9)
        if h < 0.06:
            a, b = frie[int(_tilf(*c, 10) * len(frie)) % len(frie)]
            v.celler[(c[0] + a, c[1] + b, c[2])] = 'r2_basaltmork'
        elif h < 0.11:
            del v.celler[c]
    R.ny_modell()
    v.lag()
    return R.ferdig_modell('EggMeteor', punkter={'topp': (0, 0, hoyde)})


# ------------------------------------------------------------------ gresskaret

GRESSKARANSIKT = [
    '..g....g..',
    '.ggg..ggg.',
    '....gg....',
    'g........g',
    'gg.gggg.gg',
    '.gggggggg.',
]


def gresskar():
    """Utskåret gresskar (jack-o'-lantern) til pynt, ca. 3 studs bredt: furete, med lysende gult ansikt
    (trekantøyne, nese og et tannete glis) på en flat front, og grønn stilk med blad og ranke.
    `lys` = midt i gresskaret, der spillet setter et lys."""
    s = 0.25
    v = Voksler(s)
    c, r = (0.0, 0.0, 1.15), (1.5, 1.4, 1.2)
    test, furedel = _furet(c, r)

    def farge(q, _t):
        return 'r2_fure' if furedel(q)[1] < 0.14 else 'r2_gresskar'
    v._fyll(Vector((-1.6, -1.5, 0.0)), Vector((1.6, 1.5, 2.4)), test, farge)
    v.boks((-2, -2, -1), (2, 2, 0.0), 'r2_gresskar', modus='fjern')                 # flat bunn
    v.boks((-2, 1.25, 0), (2, 2, 3), 'r2_gresskar', modus='fjern')                  # flat front ...
    v.boks((-1.4, 1.0, 0.3), (1.4, 1.25, 2.0), 'r2_gresskar', modus='mal')          # ... uten furer
    v.ellipsoide((0, 0, 2.35), (0.55, 0.55, 0.15), 'r2_gresskar', modus='fjern')    # grop rundt stilken
    _ansikt(v, 1.875, GRESSKARANSIKT, {'g': 'egggul'})
    # stilk (bøyd bakover), blad og en krøllete ranke
    for x in (-0.125, 0.125):
        for y in (-0.125, 0.125):
            for z in (2.375, 2.625):
                v.celler[v._celle((x, y, z))] = 'bladmork'
        v.celler[v._celle((x, -0.375, 2.625))] = 'bladmork'
    for (x, y, z) in ((0.375, 0.125, 2.375), (0.625, 0.125, 2.375), (0.625, 0.375, 2.375),
                      (0.625, 0.375, 2.625), (0.375, 0.375, 2.625)):
        v.celler[v._celle((x, y, z))] = 'bladgronn'
    for (x, y) in ((-0.375, -0.125), (-0.625, -0.125), (-0.625, -0.375), (-0.875, -0.375)):
        v.celler[v._celle((x, y, 2.375))] = 'bladgronn'                               # blad
    R.ny_modell()
    v.lag()
    return R.ferdig_modell('Gresskar', punkter={'lys': (0, 0, 1.15)})


# ------------------------------------------------------------------ flaggermusa

def flaggermus():
    """Liten, søt flaggermus (ca. 2 studs vingespenn) i glideflukt: hodet forover (+y) med store spisse
    ører, gule øyne og to bitte små hoggtenner, og vingene spredt ut til sidene i en svak V — så den
    typiske flaggermus-silhuetten (fingerknokler og buet bakkant) synes nedenfra når den flyr over deg.
    Origo midt i kroppen. Spillet setter CFrame.lookAt i fartsretningen og vugger den om lengdeaksen."""
    s = 0.12
    v = Voksler(s)
    K, W = 'r2_flaggermus', 'r2_vinge'
    v.ellipsoide((0, -0.08, 0), (0.27, 0.36, 0.24), K, p=2.2)                     # kropp
    v.ellipsoide((0, 0.3, 0.06), (0.3, 0.25, 0.26), K, p=2.2)                     # hode
    for x in (-1, 1):
        v.kjegle((x * 0.15, 0.27, 0.22), (x * 0.3, 0.2, 0.6), 0.13, 0.02, K)         # ører
    forrest = _forrest(v)
    for x, z, farge in ((0.18, 0.1, 'egggul'), (0.18, -0.14, 'r_hvit'), (0.3, 0.42, 'r2_rosa'),
                        (0.3, 0.3, 'r2_rosa')):
        for xx in (x, -x):
            i, k = v._celle((xx, 0, z))[0], v._celle((0, 0, z))[2]
            if (i, k) in forrest:
                v.celler[(i, forrest[(i, k)], k)] = farge
    # vingene (sett ovenfra: u = ut til siden, w = forover): forkant fram til håndleddet og ut til
    # spissen, så en buet bakkant mellom fingerspissene tilbake til kroppen
    ledd = (0.58, 0.32)
    tupper = [(1.05, 0.0), (0.82, -0.36), (0.52, -0.42), (0.22, -0.28)]
    kontur = [(0.2, 0.18), ledd]
    for (a, b) in zip(tupper, tupper[1:]):
        kontur.append(a)
        for t in (0.2, 0.4, 0.6, 0.8):
            mu, mw = a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t
            kontur.append((mu - 0.02 * math.sin(math.pi * t), mw + 0.14 * math.sin(math.pi * t)))
    kontur.append(tupper[-1])

    def hoyde(u):
        return 0.02 + 0.3 * (u - 0.2)                                             # svak V oppover
    for side in (-1, 1):
        def i_vinge(q, side=side):
            u, w = side * q.x, q.y
            if u < 0.15 or abs(q.z - hoyde(u)) > s * 0.55:
                return None
            return 0.5 if _inne(kontur, u, w) else None
        lo = Vector((-1.15, -0.55, -0.1)) if side < 0 else Vector((0.1, -0.55, -0.1))
        hi = Vector((-0.1, 0.45, 0.4)) if side < 0 else Vector((1.15, 0.45, 0.4))
        v._fyll(lo, hi, i_vinge, W)
        for (tu, tw) in [(0.2, 0.18)] + tupper[:3]:
            _strek(v, (side * ledd[0], ledd[1]), (side * tu, tw), K, lambda x, y: hoyde(abs(x)))
    R.ny_modell()
    v.lag()
    return R.ferdig_modell('Flaggermus')


def _inne(poly, u, w):
    """Ligger punktet (u, w) inni polygonet? (partallsregelen)"""
    inne = False
    j = len(poly) - 1
    for i in range(len(poly)):
        ui, wi = poly[i]
        uj, wj = poly[j]
        if (wi > w) != (wj > w) and u < ui + (w - wi) * (uj - ui) / (wj - wi):
            inne = not inne
        j = i
    return inne


def _strek(v, a, b, farge, hoyde):
    """Tynn strek (fingerknokkel) ovenfra sett i (x, y) fra a til b, med z = hoyde(x, y)."""
    n = 24
    for m in range(n + 1):
        t = m / n
        x, y = a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t
        v.celler[v._celle((x, y, hoyde(x, y)))] = farge


# ------------------------------------------------------------------ alle

def bygg_alle():
    egg_spooky()
    egg_meteor()
    gresskar()
    flaggermus()
