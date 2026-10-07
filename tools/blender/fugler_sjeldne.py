import math
import rbxlib as R
from fuglebygg import Fugl, S, OYE, SOT_OYE, bein, fot, Voksler, farge_trio, langs

from mathutils import Vector

# Rare- og Epic-fuglene i Steal a Bird (blokkstil): SecretaryBird, Hoatzin, Cassowary, Peacock,
# HarpyEagle, SnowyOwl, Lyrebird og Quetzal. Lastes automatisk av fugler.py.
# Samme konvensjoner som der: +Z opp, fuglen ser mot +Y, høyre side er +X, føttene står på z = 0.
# Alle fargene her har prefikset b_ (de andre fuglegruppene har egne prefikser).

# ------------------------------------------------------------------ farger
_TRIO = dict(
    # felles for gruppa
    b_sort='#24242c', b_hvit='#f4f6f9', b_gramork='#555b66', b_horn='#d8cdb4',
    # Secretary Bird
    b_sekgra='#b3bac4', b_seklys='#d8dce2', b_sekmork='#7f8996', b_sekansikt='#ff7a1f', b_sekbein='#eea07a',
    b_seknebb='#5a616d',
    # Hoatzin
    b_hoabrun='#8c4a2a', b_hoamork='#55301f', b_hoakrem='#f0d79c', b_hoakam='#d0692c', b_hoaoransje='#f59a3c',
    b_hoabla='#39a5ff',
    # Cassowary
    b_kassort='#1f1e24', b_kashaar='#3c3843', b_kasbla='#2f8cff', b_kasrod='#e8262d', b_kashjelm='#a8825a',
    b_kashjelm2='#6e4f33', b_kasbein='#8c919c',
    # Peacock
    b_pfbla='#1d63d8', b_pfturkis='#2bc2d4', b_pfgronn='#2f9e57', b_pfgronnmork='#1d6e3f', b_pfgull='#e0aa36',
    b_pfoyemork='#1b2a6e', b_pfvinge='#c9a46d', b_pfrust='#b8582a',
    # Harpy Eagle
    b_hgra='#9ba1aa', b_hgralys='#c9cdd3', b_hmork='#3b3f48', b_hgul='#ffc928',
    # Snowy Owl
    b_uglegra='#cdd3dc',
    # Lyrebird
    b_lyrbrun='#7d5c44', b_lyrmork='#4f3a2a', b_lyrrust='#c4602b', b_lyroransje='#ee8f3c', b_solv='#e3ebf4',
    # Quetzal
    b_qgronn='#1fae58', b_qskimmer='#20c4b4', b_qgull='#9ad83a', b_qrod='#e0203a', b_qnebb='#ffd22a',
)
for _n, _h in _TRIO.items():
    farge_trio(_n, _h)


# ------------------------------------------------------------------ hjelpefunksjoner

def _fargefunk(farge):
    """str, liste (overgang etter t fra 0 til 1) eller funksjon(p, t) -> str."""
    if callable(farge):
        return farge
    if isinstance(farge, (list, tuple)):
        liste = list(farge)
        return lambda p, t: liste[min(len(liste) - 1, max(0, int(t * len(liste))))]
    return lambda p, t: farge


def _sett(v, c, farge, modus='fyll'):
    if modus == 'fjern':
        v.celler.pop(c, None)
    elif modus == 'mal':
        if c in v.celler:
            v.celler[c] = farge
    else:
        v.celler[c] = farge


def _speil(c):
    return (-1 - c[0], c[1], c[2])


def _tilfeldig(i, j, k, fro=0):
    """Fast «tilfeldig» tall 0..1 per kube — likt på begge sider, så fuglen blir symmetrisk."""
    i = i if i >= 0 else -1 - i
    n = ((i * 73856093) ^ (j * 19349663) ^ (k * 83492791) ^ (fro * 2654435761)) & 0xffffffff
    n = ((n ^ (n >> 15)) * 2246822519) & 0xffffffff
    n ^= n >> 13
    return (n & 0xffff) / 0xffff


def _kurve(pts, n=10):
    """Glatt Catmull-Rom-kurve gjennom punktene -> tett punktliste."""
    P = [Vector(p) for p in pts]
    if len(P) == 2:
        return [P[0].lerp(P[1], i / n) for i in range(n + 1)]
    P = [2 * P[0] - P[1]] + P + [2 * P[-1] - P[-2]]
    ut = []
    for i in range(1, len(P) - 2):
        p0, p1, p2, p3 = P[i - 1], P[i], P[i + 1], P[i + 2]
        for m in range(n):
            t = m / n
            ut.append(0.5 * (2 * p1 + (p2 - p0) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * (t * t)
                             + (3 * p1 - p0 - 3 * p2 + p3) * (t * t * t)))
    ut.append(P[-2])
    return ut


def band(v, pts, r1, r2, farge, normal=None, bredde_akse=None, tykk=S, speil=False, modus='fyll'):
    """Bøyd fjær/hale/kam langs en glatt kurve gjennom pts. Radius går fra r1 til r2 langs kurven
    (t = 0..1), eller r1 kan være en funksjon r(t).
      normal=None og bredde_akse=None: rundt tverrsnitt.
      normal=n:       flatt bånd, `tykk` tykt langs n (f.eks. en lyrefjær som vender forover).
      bredde_akse=b:  flatt bånd som er 2r bredt langs b og `tykk` tykt på tvers (f.eks. halestrømmere).
    farge: navn, liste (overgang langs kurven) eller funksjon(p, t). speil=True: også speilbildet (x -> -x)."""
    K = _kurve(pts)
    lengder = [0.0]
    for a, b in zip(K, K[1:]):
        lengder.append(lengder[-1] + (b - a).length)
    L = lengder[-1] or 1.0
    rf = r1 if callable(r1) else (lambda t: r1 + (r2 - r1) * t)
    ff = _fargefunk(farge)
    n = Vector(normal).normalized() if normal else None
    ba = Vector(bredde_akse).normalized() if bredde_akse else None
    rm = max(rf(i / 20) for i in range(21)) + tykk + S
    s = v.s
    lo = [int(math.floor((min(p[i] for p in K) - rm) / s)) for i in range(3)]
    hi = [int(math.floor((max(p[i] for p in K) + rm) / s)) for i in range(3)]
    segs = []
    for a, b, la, lb in zip(K, K[1:], lengder, lengder[1:]):
        segs.append((a, b - a, max((b - a).length_squared, 1e-12), la, lb,
                     [min(a[i], b[i]) - rm for i in range(3)], [max(a[i], b[i]) + rm for i in range(3)]))
    for i in range(lo[0], hi[0] + 1):
        for j in range(lo[1], hi[1] + 1):
            for k in range(lo[2], hi[2] + 1):
                p = Vector(((i + 0.5) * s, (j + 0.5) * s, (k + 0.5) * s))
                best = None
                for a, d, l2, la, lb, blo, bhi in segs:
                    if not (blo[0] <= p[0] <= bhi[0] and blo[1] <= p[1] <= bhi[1] and blo[2] <= p[2] <= bhi[2]):
                        continue
                    u = max(0.0, min(1.0, (p - a).dot(d) / l2))
                    q = a + d * u
                    d2 = (p - q).length_squared
                    if best is None or d2 < best[0]:
                        best = (d2, q, (la + (lb - la) * u) / L)
                if best is None:
                    continue
                _, q, t = best
                r = rf(t)
                dv = p - q
                if n is not None:
                    h = dv.dot(n)
                    ok = abs(h) <= tykk / 2 and (dv - n * h).length <= r
                elif ba is not None:
                    h = dv.dot(ba)
                    ok = abs(h) <= r and (dv - ba * h).length <= tykk / 2
                else:
                    ok = dv.length <= r
                if not ok:
                    continue
                f = ff(p, t)
                if f:
                    _sett(v, (i, j, k), f, modus)
                    if speil:
                        _sett(v, _speil((i, j, k)), f, modus)


def linje(v, pts, farge, speil=False):
    """Tynn strek, én kube tykk og sammenhengende side mot side, langs en glatt kurve gjennom pts.
    Ligger den på x = 0 blir den usymmetrisk — bruk x på et kubesentrum og speil=True.
    Returnerer cellene (fra start til slutt)."""
    K = _kurve(pts, 16)
    ff = _fargefunk(farge)
    s = v.s
    celler = []
    for a, b in zip(K, K[1:]):
        steg = max(1, int((b - a).length / (s * 0.2)) + 1)
        for m in range(steg + 1):
            p = a.lerp(b, m / steg)
            c = tuple(int(math.floor(p[i] / s)) for i in range(3))
            if celler and c == celler[-1][0]:
                continue
            if celler:
                forrige = list(celler[-1][0])
                for akse in (2, 1, 0):                 # ett steg om gangen, så kubene henger sammen
                    if forrige[akse] != c[akse] and sum(forrige[x] != c[x] for x in range(3)) > 1:
                        forrige[akse] = c[akse]
                        celler.append((tuple(forrige), p))
            celler.append((c, p))
    for nr, (c, p) in enumerate(celler):
        f = ff(p, nr / max(1, len(celler) - 1))
        v.celler[c] = f
        if speil:
            v.celler[_speil(c)] = f
    return [c for c, _ in celler]


def fotkart(v, x, y, s, lag, farger, ankel):
    """Fot tegnet som kart, lag for lag fra bakken (z = 0.15) og opp. Hvert lag er rader forfra og bakover,
    kolonnene går fra innerst (mot midten av fuglen) til ytterst. ankel = (kolonne, rad) for ankelen.
    s = +1 for høyre fot, -1 for venstre (blir speilvendt)."""
    i0, j0 = int(math.floor(x / S)), int(math.floor(y / S))
    kol, rad = ankel
    for kk, rader in enumerate(lag):
        for r, tekst in enumerate(rader):
            for c, tegn in enumerate(tekst):
                if tegn in '. ':
                    continue
                v.celler[(i0 + s * (c - kol), j0 + (rad - r), kk)] = farger[tegn]


def stempel_forfra(v, x_ytre, z_topp, monster, farger):
    """Mal et mønster rett forfra (+y) på begge sider av midten, speilvendt (ugleøyne).
    Kolonne 0 er ytterst (størst x på høyre side), rad 0 er øverst."""
    i0, k0 = int(math.floor(x_ytre / S)), int(math.floor(z_topp / S))
    forrest = {}
    for (i, j, k) in v.celler:
        if j > forrest.get((i, k), -10 ** 6):
            forrest[(i, k)] = j
    for r, rad in enumerate(monster):
        for c, tegn in enumerate(rad):
            if tegn in '. ':
                continue
            for i in (i0 - c, -1 - (i0 - c)):
                if (i, k0 - r) in forrest:
                    v.celler[(i, forrest[(i, k0 - r)], k0 - r)] = farger[tegn]


def frynser(v, farge, z_min, hvor, lengde=3, fro=0):
    """Lodne frynser: kuber nederst på en flate (med fargen `farge`) får «tjafser» av ulik lengde nedover.
    hvor(x, y, z) -> True der det skal være frynser."""
    bunn = [c for c, f in v.celler.items() if f == farge and (c[0], c[1], c[2] - 1) not in v.celler]
    for (i, j, kk) in bunn:
        if not hvor((i + 0.5) * S, (j + 0.5) * S, (kk + 0.5) * S):
            continue
        for d in range(1, int(_tilfeldig(i, j, kk, fro) * (lengde + 1)) + 1):
            if (kk - d + 0.5) * S < z_min:
                break
            v.celler[(i, j, kk - d)] = farge


# ------------------------------------------------------------------ fuglene

def sekretaer():
    """SecretaryBird (Rare): slangejeger på stylter — svarte «bukser», oransje ansikt og penner bak øret."""
    f = Fugl()
    k = f.kropp
    for s in (-1, 1):
        x = s * 0.75
        bein(k, x, (-0.1, 2.7), (0.0, 0.3), 'b_sekbein')
        fot(k, x, 0.0, 'b_sekbein', form='T', klo='klo')
        k.ellipsoide((x, -0.2, 3.05), (0.42, 0.48, 0.62), 'b_sort')                 # svarte «bukser»
    k.ellipsoide((0, -0.3, 3.85), (0.95, 1.4, 0.75), 'b_sekgra', rot=(10, 0, 0), p=2.2)
    k.ellipsoide((0, 0.7, 3.8), (0.8, 0.55, 0.55), 'b_seklys', modus='mal')
    k.kjegle((0, 0.7, 4.1), (0, 0.9, 4.75), 0.42, 0.36, 'b_seklys')
    # «penner bak øret» (før hodet, så hodet dekker roten): tynne svarte fjær som stritter bakover
    # fra nakken, med brede tupper
    nakke = Vector((0.45, 0.45, 5.05))
    for vinkel, lengde, ut in ((36, 1.3, 0.0), (10, 1.7, 0.3), (-16, 1.55, 0.6)):
        a = math.radians(vinkel)
        ende = nakke + Vector((ut, -math.cos(a) * lengde, math.sin(a) * lengde))
        celler = linje(k, [nakke, ende], ['b_sekmork', 'b_sort', 'b_sort'], speil=True)
        i, j, kk = celler[-1]
        k.celler[(i + 1, j, kk)] = k.celler[_speil((i + 1, j, kk))] = 'b_sort'
    k.ellipsoide((0, 1.0, 5.05), (0.58, 0.68, 0.55), 'b_sekgra', p=2.3)
    k.ellipsoide((0, 1.2, 5.1), (0.65, 0.62, 0.42), 'b_sekansikt', modus='mal')     # oransje bar hud
    k.stempel_par((0.6, 0.95, 5.25), SOT_OYE, OYE)
    band(k, [(0, 1.5, 5.05), (0, 1.95, 5.0), (0, 2.2, 4.85), (0, 2.25, 4.6)], 0.3, 0.17,
         ['b_sekansikt', 'b_seknebb', 'b_seknebb', 'b_sort'])                       # krokete nebb
    band(k, [(0, -1.4, 3.7), (0, -2.3, 3.15), (0, -3.0, 2.4), (0, -3.35, 1.65)], 0.5, 0.38,
         lambda p, t: 'b_hvit' if t > 0.9 else ('b_sort' if 0.62 < t < 0.8 else 'b_sekmork'),
         bredde_akse=(1, 0, 0), tykk=0.6)
    w = f.vinge
    w.ellipsoide((1.0, -0.45, 3.9), (0.3, 1.25, 0.65), 'b_sekmork', rot=(10, 0, 0))
    w.ellipsoide((1.0, -1.25, 3.55), (0.5, 0.9, 0.5), 'b_sort', modus='mal')         # svarte vingefjær
    f.hengsel = (0.92, 0.2, 4.15)
    f.punkter = dict(hode=(0, 1.0, 5.05), hale=(0, -3.35, 1.65), topp=(0, 0.0, 5.95))
    return f


def hoatzin():
    """Hoatzin (Rare): punkefugl med piggete kam, blått ansikt, røde øyne og lang hale."""
    f = Fugl()
    k = f.kropp
    for s in (-1, 1):
        x = s * 0.45
        bein(k, x, (-0.15, 1.2), (0.0, 0.3), 'b_gramork')
        fot(k, x, 0.0, 'b_gramork', form='T', klo='klo')
    k.ellipsoide((0, -0.25, 2.25), (1.0, 1.25, 1.0), 'b_hoabrun', rot=(-20, 0, 0), p=2.2)
    k.ellipsoide((0, -0.85, 2.9), (1.05, 0.9, 0.7), 'b_hoamork', modus='mal')
    k.ellipsoide((0, 0.75, 2.85), (0.75, 0.5, 0.7), 'b_hoakrem', modus='mal')
    k.kjegle((0, 0.45, 2.9), (0, 0.7, 3.65), 0.45, 0.38, 'b_hoakrem')
    k.ellipsoide((0, 0.2, 3.35), (0.5, 0.3, 0.45), 'b_hoabrun', modus='mal')
    # punkekammen (før hodet, så hodet dekker roten): en vifte av oransje pigger opp og bakover
    kam = ['b_hoakam', 'b_hoakam', 'b_hoaoransje', 'b_hoaoransje']
    for vinkel, lengde in ((28, 1.0), (2, 1.35), (-24, 1.5), (-50, 1.45), (-76, 1.2)):
        a = math.radians(vinkel)
        bunn = Vector((0, 0.75, 4.2))
        band(k, [bunn, bunn + Vector((0, math.sin(a), math.cos(a))) * lengde], 0.32, 0.27, kam)
    k.ellipsoide((0, 0.8, 3.95), (0.55, 0.62, 0.52), 'b_hoabrun', p=2.3)
    k.ellipsoide((0, 0.95, 3.95), (0.62, 0.55, 0.5), 'b_hoabla', modus='mal')       # blå bar hud
    k.stempel_par((0.55, 0.7, 4.05), ['rr', 'rk'], {'r': 'ojerod', 'k': 'svart'})
    k.kjegle((0, 1.3, 3.9), (0, 1.7, 3.8), 0.26, 0.17, 'b_gramork')
    band(k, [(0, -1.3, 2.3), (0, -2.1, 1.75), (0, -2.8, 0.95), (0, -3.1, 0.45)], 0.42, 0.55,
         lambda p, t: 'b_hoakrem' if t > 0.8 else 'b_hoamork', bredde_akse=(1, 0, 0), tykk=0.6)
    w = f.vinge
    w.ellipsoide((1.0, -0.4, 2.45), (0.3, 1.1, 0.8), 'b_hoamork', rot=(-20, 0, 0))
    w.ellipsoide((1.0, -1.25, 2.0), (0.5, 0.6, 0.55), 'b_hoabrun', modus='mal')
    band(w, [(1.2, 0.55, 2.95), (1.2, -1.0, 2.55)], 0.25, 0.25, 'b_hoakrem', modus='mal')
    f.hengsel = (0.92, 0.15, 2.8)
    f.punkter = dict(hode=(0, 0.8, 3.95), hale=(0, -3.1, 0.45), topp=(0, 0.4, 5.7))
    return f


KASUAR_FOT = (
    # bakken: tre tær forover, den innerste med en lang dolkeklo
    ['k...',
     'k...',
     'kg..',
     'gg.k',
     '.ggg',
     '.gg.',
     '.g..'],
    ['....',
     '....',
     '....',
     '....',
     '.g..',
     '.gg.',
     '.g..'],
)


def kasuar():
    """Cassowary (Rare): svart lodden kjempe med blå hals, røde hakelapper, høy hjelm og dolkeklør."""
    f = Fugl()
    k = f.kropp
    for s in (-1, 1):
        x = s * 0.75
        bein(k, x, (-0.1, 2.3), (0.05, 0.45), 'b_kasbein', r=0.3)
        fotkart(k, x, 0.05, s, KASUAR_FOT, {'g': 'b_kasbein', 'k': 'klo'}, ankel=(1, 5))
    k.ellipsoide((0, -0.4, 3.0), (1.35, 1.65, 1.15), 'b_kassort', rot=(12, 0, 0), p=2.0)
    frynser(k, 'b_kassort', 1.2, lambda x, y, z: (x / 1.35) ** 2 + ((y + 0.4) / 1.65) ** 2 > 0.4, lengde=3)
    k.prikker([('b_kashaar', 0.25)], bare=['b_kassort'], fro=3)
    k.kjegle((0, 0.85, 3.45), (0, 1.3, 4.35), 0.48, 0.4, 'b_kasbla')
    k.ellipsoide((0, 0.75, 4.05), (0.5, 0.3, 0.6), 'b_kasrod', modus='mal')            # rød nakke
    k.ellipsoide((0, 1.6, 3.7), (0.3, 0.28, 0.5), 'b_kasrod')                          # hakelapper
    band(k, [(0, 1.6, 4.75), (0, 1.5, 5.35), (0, 1.25, 5.8)], 0.45, 0.22,
         ['b_kashjelm', 'b_kashjelm', 'b_kashjelm2'], normal=(1, 0, 0), tykk=0.6)          # hjelmen
    k.ellipsoide((0, 1.45, 4.5), (0.52, 0.62, 0.5), 'b_kasbla', p=2.2)
    k.kjegle((0, 1.95, 4.45), (0, 2.5, 4.3), 0.24, 0.16, 'b_sort')
    k.stempel_par((0.52, 1.25, 4.7), ['k.', 'ok'], {'o': 'ojeoransje', 'k': 'svart'})
    w = f.vinge
    w.ellipsoide((1.38, 0.2, 3.3), (0.3, 0.45, 0.32), 'b_kassort')
    for dz in (0.0, -0.25):
        w.kjegle((1.5, 0.0, 3.25 + dz), (1.6, -0.55, 3.0 + dz), 0.15, 0.12, 'b_sort')
    f.hengsel = (1.25, 0.3, 3.4)
    f.punkter = dict(hode=(0, 1.45, 4.5), hale=(0, -2.0, 2.6), topp=(0, 1.3, 6.0))
    return f


# påfuglhalens øyne: (avstand fra midten, vinkler fra loddrett, størrelse) — ytre rad forskjøvet
_VIFTE_OYNE = [(1.85, (-90, -60, -30, 0, 30, 60, 90), 0.42),
               (2.75, (-105, -75, -45, -15, 15, 45, 75, 105), 0.54)]


def _vifte_farge(x, z, zc):
    """Påfuglhalen forfra: grønn med «øyne» (mørkeblå kjerne, turkis, gull)."""
    for ro, vinkler, rr in _VIFTE_OYNE:
        for a in vinkler:
            ar = math.radians(a)
            ex, ez = ro * math.sin(ar), zc + ro * math.cos(ar)
            dx, dz = x - ex, z - ez
            radial = dx * math.sin(ar) + dz * math.cos(ar)
            tang = dx * math.cos(ar) - dz * math.sin(ar)
            d = math.hypot(tang, radial * 0.8)                    # litt avlange øyne, utover
            if d < rr * 0.4:
                return 'b_pfoyemork'
            if d < rr * 0.7:
                return 'b_pfturkis'
            if d < rr * 0.93:
                return 'b_pfgull'
            if d < rr * 1.12:
                return 'b_pfgronnmork'
    return 'b_pfgronn'


def _paafugl_vifte(v, yc, zc, radius):
    s = v.s
    imax = int(radius / s) + 2
    for i in range(-imax, imax):
        x = (i + 0.5) * s
        for kk in range(0, int((zc + radius) / s) + 2):
            z = (kk + 0.5) * s
            dz = z - zc
            r = math.hypot(x, dz)
            th = math.degrees(math.atan2(x, dz))           # 0 = rett opp, ±90 = ut til sidene
            if abs(th) > 118:
                continue
            if r > radius + 0.2 * math.cos(math.radians(th) * 14):
                continue
            y = yc - 0.28 * dz + 0.055 * r * r            # lener bakover og buer seg mot oss
            j = int(math.floor(y / s))
            v.celler[(i, j, kk)] = _vifte_farge(x, z, zc)
            v.celler[(i, j - 1, kk)] = 'b_pfgronnmork'


def paafugl():
    """Peacock (Rare): blå hals og kropp, liten krone og en enorm reist halevifte med øyne."""
    f = Fugl()
    k = f.kropp
    _paafugl_vifte(k, -1.55, 2.7, 3.25)
    for s in (-1, 1):
        x = s * 0.45
        bein(k, x, (-0.1, 1.5), (0.0, 0.3), 'b_gramork')
        fot(k, x, 0.0, 'b_gramork', form='T', klo='klo')
    k.ellipsoide((0, -0.15, 2.3), (0.95, 1.2, 0.95), 'b_pfbla', rot=(-12, 0, 0), p=2.2)
    k.kjegle((0, 0.45, 2.9), (0, 0.7, 4.0), 0.46, 0.36, 'b_pfbla')
    # krona (før hodet, så hodet dekker roten): tynne stilker med blå dusker i toppen
    for dy, vinkel in ((-0.3, -38), (0.0, 0), (0.3, 38)):
        a = math.radians(vinkel)
        bunn = (0.15, 0.8 + dy, 4.75)
        celler = linje(k, [bunn, (0.15, bunn[1] + 0.8 * math.sin(a), 4.75 + 0.8 * math.cos(a))],
                       'b_pfoyemork', speil=True)
        i, j, kk = celler[-1]
        for c in ((i, j, kk), (i, j, kk + 1)):
            k.celler[c] = k.celler[_speil(c)] = 'b_pfturkis'
    k.ellipsoide((0, 0.8, 4.35), (0.55, 0.62, 0.55), 'b_pfbla', p=2.2)
    k.stempel_par((0.55, 0.8, 4.4), ['hhh', '.kk', '.h.'], {'h': 'b_hvit', 'k': 'svart'})
    k.kjegle((0, 1.3, 4.25), (0, 1.7, 4.15), 0.22, 0.16, 'b_horn')
    w = f.vinge
    w.ellipsoide((0.98, -0.35, 2.4), (0.3, 1.0, 0.72), 'b_pfvinge', rot=(-12, 0, 0))
    for y in (-0.6, 0.0):
        w.boks((0.6, y - 0.12, 1.6), (1.4, y + 0.12, 3.3), 'b_sort', modus='mal')
    w.ellipsoide((1.0, -1.1, 2.0), (0.5, 0.5, 0.6), 'b_pfrust', modus='mal')
    f.hengsel = (0.9, 0.15, 2.75)
    f.punkter = dict(hode=(0, 0.8, 4.35), hale=(0, -1.8, 4.2), topp=(0, -1.0, 6.0))
    return f


HARPY_FOT = (
    ['k.k.k',
     'g.g.g',
     'g.g.g',
     '.ggg.',
     '..g..',
     '..g..',
     '..k..'],
    ['.....',
     'k.k.k',
     '.....',
     '.ggg.',
     '..g..',
     '..k..',
     '.....'],
)


def harpy():
    """HarpyEagle (Epic): grått hode med todelt fjærtopp, svart brystbånd og enorme gule klør."""
    f = Fugl()
    k = f.kropp

    def bukse(p, t):
        return 'b_hmork' if int(math.floor(p.z / S)) % 3 == 0 else 'b_hvit'
    for s in (-1, 1):
        x = s * 1.05
        k.ellipsoide((s * 0.95, -0.05, 2.15), (0.5, 0.55, 0.75), bukse)              # stripete «bukser»
        bein(k, x, (0.05, 1.6), (0.15, 0.45), 'b_hgul', r=0.3)
        fotkart(k, x, 0.15, s, HARPY_FOT, {'g': 'b_hgul', 'k': 'klo'}, ankel=(2, 4))
    k.ellipsoide((0, -0.2, 3.2), (1.25, 1.15, 1.5), 'b_hmork', rot=(-10, 0, 0), p=2.2)
    k.ellipsoide((0, 0.65, 2.75), (1.05, 0.6, 1.05), 'b_hvit', modus='mal')
    k.kjegle((0, 0.15, 3.9), (0, 0.4, 4.45), 0.78, 0.72, 'b_hgra')
    k.ellipsoide((0, 0.6, 3.45), (1.25, 0.8, 0.25), 'b_sort', modus='mal')            # svart brystbånd
    # den todelte fjærtoppen: en vifte av mørke fjær bak hodet, delt på midten — som en krone
    for s in (-1, 1):
        for vinkel, lengde in ((20, 1.2), (44, 1.25), (68, 1.15), (90, 0.95)):
            a = math.radians(vinkel)
            bunn = Vector((s * 0.3, 0.1, 5.05))
            band(k, [bunn, bunn + Vector((s * math.sin(a), -0.3, math.cos(a))) * lengde], 0.26, 0.2,
                 ['b_hgra', 'b_hmork', 'b_hmork', 'b_sort'])
    k.ellipsoide((0, 0.45, 4.75), (0.95, 0.88, 0.82), 'b_hgra', p=2.2)
    k.ellipsoide((0, 1.0, 4.65), (0.88, 0.45, 0.68), 'b_hgralys', modus='mal')         # lys ansiktsskive
    k.stempel_par((0.95, 0.75, 5.05), ['mm.', '.mm', '.ok', '.oo'],                  # sint, ravgult øye
                  {'m': 'b_hmork', 'o': 'ojeoransje', 'k': 'svart'})
    k.kjegle((0, 1.1, 4.85), (0, 1.35, 4.82), 0.3, 0.3, 'b_hmork')
    band(k, [(0, 1.15, 4.7), (0, 1.6, 4.68), (0, 1.88, 4.45), (0, 1.92, 4.15)], 0.33, 0.26, 'b_sort')
    k.kjegle((0, -1.25, 2.3), (0, -2.1, 1.0), 0.45, 0.5,
             langs((0, -1.25, 2.3), (0, -2.1, 1.0), ['b_hmork', 'b_hgra', 'b_hmork', 'b_hgra', 'b_hmork']),
             bredde=1.5, hoyde=0.5)
    w = f.vinge
    w.ellipsoide((1.28, -0.4, 3.15), (0.32, 1.2, 1.2), 'b_hmork', rot=(-10, 0, 0))
    w.kjegle((1.28, -0.9, 2.5), (1.25, -1.95, 1.35), 0.45, 0.24, 'b_hmork', bredde=0.7)   # lange svingfjær
    w.prikker([('b_hgra', 0.18)], bare=['b_hmork'], fro=4)                                 # lyse fjærkanter
    w.boks((1.25, -2.2, 2.25), (1.8, 1.2, 2.37), 'b_hgra', modus='mal')
    w.kjegle((1.28, -1.5, 1.85), (1.25, -1.95, 1.35), 0.4, 0.24, 'b_sort', bredde=0.8, modus='mal')
    f.hengsel = (1.2, 0.2, 3.7)
    f.punkter = dict(hode=(0, 0.45, 4.75), hale=(0, -2.1, 1.0), topp=(0, 0.2, 6.3))
    return f


def _ugleflekker(v, sone, fro=0):
    """Svarte «streker» i rader (snøugle), bare på hvite kuber der sone(x, y, z) er sann."""
    for (i, j, kk), f in list(v.celler.items()):
        if f != 'b_hvit' or (kk + fro) % 3:
            continue
        if not sone((i + 0.5) * S, (j + 0.5) * S, (kk + 0.5) * S):
            continue
        ii = i if i >= 0 else -1 - i
        if (ii + j + 3 * (kk // 3)) % 5 in (0, 1):
            v.celler[(i, j, kk)] = 'b_sort'


def snougle():
    """SnowyOwl (Epic): rund, hvit og lodden, med svarte flekker og store gule øyne."""
    f = Fugl()
    k = f.kropp
    for s in (-1, 1):
        k.ellipsoide((s * 0.6, 0.3, 0.38), (0.5, 0.6, 0.4), 'b_hvit')                  # lodne «tøfler»
    k.ellipsoide((0, -0.05, 2.15), (1.62, 1.45, 1.6), 'b_hvit', p=2.0)
    k.ellipsoide((0, 0.35, 1.9), (1.35, 1.15, 1.2), 'b_hvit')                           # rund mage
    k.ellipsoide((0, 0.1, 4.3), (1.36, 1.35, 1.25), 'b_hvit', p=1.9)
    k.boks((-2.0, 1.2, 3.35), (2.0, 2.5, 5.8), 'b_hvit', modus='fjern')                 # flatt ansikt
    frynser(k, 'b_hvit', 0.3, lambda x, y, z: z < 1.2 and abs(x) > 0.3, lengde=1, fro=2)   # lodne kanter
    _ugleflekker(k, lambda x, y, z: y < -0.2 or (z < 2.4 and abs(x) > 0.5) or (z > 4.95 and y < 0.6))
    k.ellipsoide((0, 1.05, 4.3), (1.45, 0.3, 1.2), 'b_uglegra', modus='mal')
    k.ellipsoide((0, 1.05, 4.3), (1.15, 0.35, 0.95), 'b_hvit', modus='mal')
    stempel_forfra(k, 1.35, 4.95, ['.yy.', 'ywky', 'ykky', '.yy.'], {'y': 'ojegul', 'w': 'hvit', 'k': 'svart'})
    k.kjegle((0, 0.95, 3.85), (0, 1.45, 3.6), 0.24, 0.17, 'b_sort')
    # svarte klør som stikker fram foran de lodne føttene
    forrest = {}
    for (i, j, kk) in k.celler:
        if kk == 0 and j > forrest.get(i, -99):
            forrest[i] = j
    for i, j in forrest.items():
        k.celler[(i, j + 1, 0)] = 'klo'
    w = f.vinge
    w.ellipsoide((1.55, -0.25, 2.4), (0.32, 1.1, 1.3), 'b_hvit', rot=(-6, 0, 0))
    _ugleflekker(w, lambda x, y, z: y < 0.5, fro=1)
    f.hengsel = (1.45, 0.2, 3.2)
    f.punkter = dict(hode=(0, 0.1, 4.3), hale=(0, -1.5, 1.2), topp=(0, 0.1, 5.4))
    return f


def _lyrestriper(p, t):
    if t > 0.84:
        return 'b_lyrmork'
    return 'b_lyroransje' if int(t * 16) % 2 else 'b_lyrbrun'


def lyrefugl():
    """Lyrebird (Epic): brun fugl med en reist lyrehale — to stripete ytterfjær og hvite tråder imellom."""
    f = Fugl()
    k = f.kropp
    for s in (-1, 1):
        x = s * 0.45
        bein(k, x, (0.0, 1.5), (0.1, 0.3), 'b_gramork')
        fot(k, x, 0.1, 'b_gramork', form='T', klo='klo')
    k.ellipsoide((0, 0.05, 2.3), (0.9, 1.3, 0.85), 'b_lyrbrun', rot=(-10, 0, 0), p=2.2)
    k.kjegle((0, 0.75, 2.7), (0, 1.05, 3.35), 0.42, 0.36, 'b_lyrbrun')
    k.ellipsoide((0, 1.15, 3.6), (0.52, 0.6, 0.5), 'b_lyrbrun', p=2.3)
    k.ellipsoide((0, 1.25, 3.05), (0.5, 0.42, 0.42), 'b_lyrrust', modus='mal')
    k.kjegle((0, 1.65, 3.55), (0, 2.05, 3.45), 0.2, 0.16, 'b_sort')
    k.stempel_par((0.52, 1.25, 3.75), SOT_OYE, OYE)

    def rlyre(t):                       # smal ved roten, bred på midten, smalere i tuppen
        return 0.27 + 0.22 * math.sin(math.pi * min(1.0, t * 1.1))
    for s in (-1, 1):
        band(k, [(s * 0.3, -1.15, 2.5), (s * 1.15, -1.35, 3.0), (s * 1.75, -1.5, 3.85), (s * 1.75, -1.6, 4.75),
                 (s * 1.3, -1.65, 5.4), (s * 1.05, -1.65, 5.78), (s * 1.25, -1.65, 6.02), (s * 1.65, -1.6, 5.98),
                 (s * 1.8, -1.6, 5.7)], rlyre, None, _lyrestriper, normal=(0, 1, 0))
    # ... og fine, hvite tråder imellom (i to lag, så de ikke smelter sammen)
    for punkter in ([(0.15, -1.25, 2.7), (0.15, -1.45, 4.2), (0.15, -1.55, 5.75), (0.45, -1.6, 6.1)],
                    [(0.15, -1.3, 2.9), (0.6, -1.65, 4.0), (0.75, -1.75, 5.2), (1.05, -1.75, 5.65)]):
        linje(k, punkter, 'b_solv', speil=True)
    w = f.vinge
    w.ellipsoide((0.95, -0.2, 2.35), (0.3, 0.95, 0.68), 'b_lyrmork', rot=(-10, 0, 0))
    f.hengsel = (0.88, 0.2, 2.7)
    f.punkter = dict(hode=(0, 1.15, 3.6), hale=(0, -1.6, 5.0), topp=(0, -1.6, 6.3))
    return f


def quetzal():
    """Quetzal (Epic): smaragdgrønn med skimmer, rød mage, lodden kam og superlange halestrømmere."""
    f = Fugl()
    k = f.kropp
    for s in (-1, 1):
        x = s * 0.45
        bein(k, x, (0.0, 1.2), (0.05, 0.3), 'b_gramork')
        fot(k, x, 0.05, 'b_gramork', form='T', klo='klo')
    k.ellipsoide((0, 0.0, 2.5), (1.05, 1.1, 1.35), 'b_qgronn', rot=(-15, 0, 0), p=2.2)
    k.ellipsoide((0, 0.6, 1.95), (1.0, 0.75, 0.9), 'b_qrod', modus='mal')
    k.ellipsoide((0, 0.45, 4.1), (0.8, 0.8, 0.75), 'b_qgronn', p=2.2)
    # lodden kam: en halvsirkel av børster fra nebbet til nakken
    for vinkel in range(-90, 90, 20):
        a = math.radians(vinkel)
        bunn = Vector((0, 0.4, 4.4))
        band(k, [bunn, bunn + Vector((0, math.sin(a), math.cos(a))) * 1.1], 0.3, 0.27,
             ['b_qgronn'] * 5 + ['b_qgull'])
    k.kjegle((0, 1.15, 4.0), (0, 1.55, 3.85), 0.24, 0.17, 'b_qnebb')
    k.stempel_par((0.8, 0.55, 4.2), SOT_OYE, OYE)
    # halestrømmerne: to superlange og to kortere, flate og brede
    for s in (-1, 1):
        band(k, [(s * 0.3, -0.85, 2.85), (s * 0.3, -1.6, 1.7), (s * 0.35, -2.35, 0.75), (s * 0.45, -3.3, 0.4),
                 (s * 0.6, -4.3, 0.4), (s * 0.8, -5.0, 0.75)], 0.5, 0.26,
             lambda p, t: 'b_qskimmer' if t > 0.9 else 'b_qgronn', bredde_akse=(1, 0, 0), tykk=0.6)
        band(k, [(s * 0.3, -0.9, 2.6), (s * 0.7, -1.6, 1.5), (s * 0.95, -2.3, 0.75), (s * 1.1, -3.1, 0.55)],
             0.42, 0.22, 'b_qgronn', bredde_akse=(1, 0, 0), tykk=0.6)
    k.kjegle((0, -0.9, 1.9), (0, -1.6, 1.3), 0.35, 0.3, 'b_hvit', bredde=1.3, hoyde=0.6)
    k.prikker([('b_qskimmer', 0.14), ('b_qgull', 0.05)], bare=['b_qgronn'], fro=5)
    w = f.vinge
    w.ellipsoide((1.05, -0.3, 2.6), (0.3, 1.05, 1.0), 'b_qgronn', rot=(-15, 0, 0))
    w.ellipsoide((1.05, -1.05, 1.95), (0.5, 0.65, 0.65), 'b_sort', modus='mal')
    w.prikker([('b_qskimmer', 0.14), ('b_qgull', 0.05)], bare=['b_qgronn'], fro=5)
    f.hengsel = (0.95, 0.15, 3.05)
    f.punkter = dict(hode=(0, 0.45, 4.1), hale=(0, -5.0, 0.75), topp=(0, 0.4, 5.7))
    return f


# ------------------------------------------------------------------ katalog
FUGLER = {
    'SecretaryBird': sekretaer,
    'Hoatzin': hoatzin,
    'Cassowary': kasuar,
    'Peacock': paafugl,
    'HarpyEagle': harpy,
    'SnowyOwl': snougle,
    'Lyrebird': lyrefugl,
    'Quetzal': quetzal,
}
