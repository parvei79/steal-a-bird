import math
import rbxlib as R
from fuglebygg import Fugl, S, OYE, SOT_OYE, bein, fot, Voksler, farge_trio, langs

from mathutils import Vector

# Halloween-fuglene i Steal a Bird (blokkstil, voksler) — skumle, men søte:
#
#     PumpkinCrow    (Rare)       svart kråke med gresskarhode: utskåret, lysende ansikt og grønn stilk
#     VampireFinch   (Epic)       liten fink kledd som Dracula: blekt ansikt, hårspiss, kappe (vingene!), høy krage
#     WitchOwl       (Epic)       lilla ugle med heksehatt og gullspenne, som sitter på en kost
#     SkeletonRaven  (Legendary)  ravn av hvite knokler: ribbein, hodeskalle og grønne lysende øyne
#     GhostDove      (Mythic)     spøkelsesdue som svever: lakenhale, store øyne, «Boo»-munn og små
#                                 spøkelser som jager hverandre rundt den (Ekstra)
#
# Samme konvensjoner som fugler.py: +Z opp, fuglen ser mot +Y, høyre side er +X, origo = bakken midt under.
# Alle fargene her har prefikset h_ (de andre fuglegruppene har egne prefikser).

# ------------------------------------------------------------------ farger
_TRIO = dict(
    # Gresskarkråka (kroppen bruker kråkefargene fra fugler_vanlige, ansiktet lyser i ojegul)
    h_gresskar='#ff8a1c', h_gresskarmork='#c9560f', h_stilk='#4e8a2c', h_blad='#7cc943',
    # Vampyrfinken
    h_vamp='#4d4560', h_blek='#dcd5ea', h_kapperod='#c4122e',
    # Hekseugla
    h_ugle='#7c66aa', h_uglelys='#cdc2e4', h_uglemork='#4b3a70', h_hatt='#2a2236',
    # Skjelettravnen (knoklene har mindre nyanseforskjell, så de ser rene ut)
    h_benmork='#a99a7a', h_gronnlys='#9cff63', h_gronn='#2fc24a',
    # Spøkelsesduen
    h_spok='#eef9ff', h_spokcyan='#bfeeff', h_spokbla='#86cdee', h_spokmork='#33406e',
)
for _n, _h in _TRIO.items():
    farge_trio(_n, _h)
farge_trio('h_ben', '#ece3cc', spenn=0.06)


# ------------------------------------------------------------------ hjelpere

def _k(v, x, y, z, farge):
    """Én kube: den som inneholder punktet (gi kubesentre: ±0.15, ±0.45 ...)."""
    v.celler[v._celle((x, y, z))] = farge


def _k2(v, x, y, z, farge):
    """Én kube på høyre side og speilbildet på venstre."""
    i, j, k = v._celle((x, y, z))
    v.celler[(i, j, k)] = farge
    v.celler[(-1 - i, j, k)] = farge


def _profil(v, xs, y0, z0, rader, farger):
    """Form sett fra siden som pikselkunst, trukket ut på tvers. Øverste rad først; kolonnene går forover
    (+y) fra kubesenteret y0, z0 = senteret i nederste rad. xs = kubesentrene i x. '.' = hopp over."""
    n = len(rader)
    for r, rad in enumerate(rader):
        z = z0 + (n - 1 - r) * S
        for c, tegn in enumerate(rad):
            if tegn in '. ':
                continue
            for x in xs:
                _k(v, x, y0 + c * S, z, farger[tegn])


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


def flate(v, poly, farge, akser='xz', dybde=0.0, tykk=S, modus='fyll'):
    """Plan (eller bølgete) plate utspent av et polygon — kapper, lakenvinger, krager.
    akser='xz': polygonet er (x, z)-punkter sett forfra; dybde = y-koordinaten midt i plata, som tall
    eller funksjon(u, w). tykk = tykkelsen langs dybdeaksen (0.3 = én kube)."""
    ia, ib = 'xyz'.index(akser[0]), 'xyz'.index(akser[1])
    ic = 3 - ia - ib
    df = dybde if callable(dybde) else (lambda u, w: dybde)
    us = [p[0] for p in poly]
    ws = [p[1] for p in poly]
    cs = [df(u, w) for u in (min(us), max(us)) for w in (min(ws), max(ws))]
    lo, hi = [0.0] * 3, [0.0] * 3
    lo[ia], hi[ia] = min(us), max(us)
    lo[ib], hi[ib] = min(ws), max(ws)
    lo[ic], hi[ic] = min(cs) - tykk - 0.6, max(cs) + tykk + 0.6

    def test(q):
        u, w = q[ia], q[ib]
        d = q[ic] - df(u, w)
        if d <= -tykk / 2 + 1e-7 or d > tykk / 2 + 1e-7:
            return None
        return 0.5 if _inne(poly, u, w) else None
    v._fyll(Vector(lo), Vector(hi), test, farge, modus)


def _forrest(v):
    """(i, k) -> den fremste kuben (største j) i hver kolonne sett forfra."""
    forrest = {}
    for (i, j, k) in v.celler:
        if j > forrest.get((i, k), -10 ** 6):
            forrest[(i, k)] = j
    return forrest


def skjaer_ut(v, z_topp, monster, farger, dybde=1):
    """Skjær et mønster inn i forsiden (sett forfra, +y): de fremste kubene fjernes `dybde` kuber inn,
    og bunnen males med farger[tegn] (et lysende, utskåret ansikt). Mønsteret dekker hele bredden og
    bør ha et partall kolonner — midten ligger mellom de to midterste (x = 0). dybde=0 maler bare."""
    n = max(len(r) for r in monster)
    k0 = int(math.floor(z_topp / S))
    forrest = _forrest(v)
    for r, rad in enumerate(monster):
        for c, tegn in enumerate(rad):
            if tegn in '. ':
                continue
            i, k = c - n // 2, k0 - r
            j = forrest.get((i, k))
            if j is None:
                continue
            for d in range(dybde):
                v.celler.pop((i, j - d, k), None)
            v.celler[(i, j - dybde, k)] = farger[tegn]


def paa_forsiden(v, z_topp, monster, farger, ut=1):
    """Legg kuber `ut` kuber foran den fremste kuben i hver kolonne (spenner som stikker ut).
    Mønsteret dekker hele bredden symmetrisk om x = 0, som i skjaer_ut."""
    n = max(len(r) for r in monster)
    k0 = int(math.floor(z_topp / S))
    forrest = _forrest(v)
    for r, rad in enumerate(monster):
        for c, tegn in enumerate(rad):
            if tegn in '. ':
                continue
            i, k = c - n // 2, k0 - r
            if (i, k) in forrest:
                v.celler[(i, forrest[(i, k)] + ut, k)] = farger[tegn]


def skjaer_side(v, punkt_hoyre, monster, farger, dybde=1):
    """Som stempel_par (samme mønster på begge sider, kolonnene går forover), men de ytterste kubene
    fjernes `dybde` kuber inn og bunnen males — øyehuler."""
    x, y, z = punkt_hoyre
    rader = len(monster)
    kol = max(len(r) for r in monster)
    for side in (1, -1):
        base = v._celle((side * x, y, z))
        for r, rad in enumerate(monster):
            for c, tegn in enumerate(rad):
                if tegn in '. ':
                    continue
                j = base[1] + c - (kol - 1) // 2
                k = base[2] + (rader - 1) // 2 - r
                xs = [i for (i, jj, kk) in v.celler if jj == j and kk == k]
                if not xs:
                    continue
                i = max(xs) if side > 0 else min(xs)
                for d in range(dybde):
                    v.celler.pop((i - side * d, j, k), None)
                v.celler[(i - side * dybde, j, k)] = farger[tegn]


def stempel_forfra(v, x_ytre, z_topp, monster, farger):
    """Mal et mønster rett forfra (+y) på begge sider av midten, speilvendt (ugleøyne, store spøkelsesøyne).
    Kolonne 0 er ytterst (x_ytre på høyre side), rad 0 er øverst."""
    i0, k0 = int(math.floor(x_ytre / S)), int(math.floor(z_topp / S))
    forrest = _forrest(v)
    for r, rad in enumerate(monster):
        for c, tegn in enumerate(rad):
            if tegn in '. ':
                continue
            for i in (i0 - c, -1 - (i0 - c)):
                if (i, k0 - r) in forrest:
                    v.celler[(i, forrest[(i, k0 - r)], k0 - r)] = farger[tegn]


def mal_forfra(v, farge, bare=None):
    """Mal den fremste kuben i hver kolonne sett forfra: farge(x, z) -> fargenavn eller None.
    bare = liste med farger som kan males over (None = alle)."""
    for (i, k), j in _forrest(v).items():
        if bare is not None and v.celler[(i, j, k)] not in bare:
            continue
        f = farge((i + 0.5) * S, (k + 0.5) * S)
        if f:
            v.celler[(i, j, k)] = f


def gresskar(v, c, r, farge, fure, lober=8, bulk=0.14, p=2.2, furebredde=0.17):
    """Gresskar: avflatet ball med loddrette furer mellom `lober` lober (en lobe midt foran).
    Furene er litt innsunket og får fargen `fure`."""
    cx, cy, cz = c
    rx, ry, rz = r

    def furedel(q):
        dx, dy = q.x - cx, q.y - cy
        fase = math.atan2(dx, dy) / (2 * math.pi) * lober            # lobemidter på heltall
        avst = abs((fase % 1.0) - 0.5)                                 # 0 midt i en fure
        return avst, avst * 2 * math.pi / lober * math.hypot(dx, dy)   # (andel, avstand langs overflaten)

    def test(q):
        avst, _ = furedel(q)
        g = max(0.0, 1.0 - avst / 0.2)
        k = 1.0 - bulk * g
        d = abs((q.x - cx) / (rx * k)) ** p + abs((q.y - cy) / (ry * k)) ** p + abs((q.z - cz) / rz) ** p
        return 0.0 if d <= 1 else None

    def fargen(q, _t):
        return fure if furedel(q)[1] < furebredde else farge
    v._fyll(Vector((cx - rx, cy - ry, cz - rz)), Vector((cx + rx, cy + ry, cz + rz)), test, fargen)


def mal_punkt(v, start, retning, farge, steg=40):
    """Gå fra `start` i `retning` til første kube, og farg den."""
    p, d = Vector(start), Vector(retning).normalized() * (S * 0.5)
    for _ in range(steg):
        c = v._celle(p)
        if c in v.celler:
            v.celler[c] = farge
            return c
        p += d
    return None


def linje(v, a, b, farge, speil=False):
    """Tynn strek av kuber fra a til b, én kube tykk og sammenhengende side mot side (knokler, pinner).
    farge kan være en liste (overgang fra a til b). speil=True: også speilbildet (x -> -x)."""
    a, b = Vector(a), Vector(b)
    n = max(1, int((b - a).length / (S * 0.2)))
    celler = []
    for m in range(n + 1):
        c = v._celle(a.lerp(b, m / n))
        if celler and c == celler[-1]:
            continue
        if celler:
            cur = list(celler[-1])
            for akse in (2, 1, 0):                     # ett steg om gangen, så kubene henger sammen
                if cur[akse] != c[akse]:
                    cur[akse] = c[akse]
                    if tuple(cur) != c:
                        celler.append(tuple(cur))
        celler.append(c)
    for nr, c in enumerate(celler):
        t = nr / max(1, len(celler) - 1)
        f = farge if isinstance(farge, str) else farge[min(len(farge) - 1, int(t * len(farge)))]
        v.celler[c] = f
        if speil:
            v.celler[(-1 - c[0], c[1], c[2])] = f
    return celler


# ------------------------------------------------------------------ PumpkinCrow

# Det utskårne ansiktet sett forfra (rad 0 øverst ved z = 4.65), 10 kuber bredt: trekantøyne og et
# stort, tannete glis — med marg rundt, så det leses som et ansikt. Kråkenebbet stikker ut der nesa er.
GRESSKARANSIKT = [
    '..g....g..',
    '.ggg..ggg.',
    '..........',
    'g........g',
    'gg.gggg.gg',
    '.gggggggg.',
]


def gresskarkraake():
    """PumpkinCrow (Rare): svart kråke der hodet er et stort gresskar med utskåret, lysende ansikt —
    kråkenebbet stikker ut der nesa skulle vært — og en grønn stilk med en krøllete ranke på toppen."""
    SV, OR = 'a_krasvart', 'h_gresskar'
    f = Fugl()
    k = f.kropp
    for s in (-1, 1):
        x = s * 0.75
        bein(k, x, (-0.2, 1.25), (-0.1, 0.3), 'a_kranebb')
        fot(k, x, -0.1, 'a_kranebb', form='T', klo='klo')
    k.ellipsoide((0, -0.35, 2.0), (1.15, 1.4, 1.05), SV, rot=(-14, 0, 0), p=2.3)
    k.kjegle((0, -1.4, 1.8), (0, -2.6, 1.35), 0.42, 0.58, SV, bredde=1.45, hoyde=0.45)
    k.prikker([('a_kraglans', 0.16), ('a_kralilla', 0.08)], bare=[SV], fro=5)
    # gresskarhodet: furete, med flat front (uten furer) til ansiktet, og en grop rundt stilken
    hc = (0, 0.5, 3.85)
    gresskar(k, hc, (1.8, 1.4, 1.25), OR, 'h_gresskarmork')
    k.boks((-2, 1.5, 2.5), (2, 2.5, 5.4), OR, modus='fjern')
    k.boks((-1.6, 1.2, 2.9), (1.6, 1.5, 4.9), OR, modus='mal')
    k.ellipsoide((0, 0.5, 5.05), (0.6, 0.6, 0.2), OR, modus='fjern')
    skjaer_ut(k, 4.65, GRESSKARANSIKT, {'g': 'ojegul'}, dybde=0)                    # flatt: leses best
    _profil(k, (-0.15, 0.15), 1.35, 4.05, ['bbb'], {'b': 'a_kranebb'})
    # stilken (bøyd bakover i toppen) og en krøllete ranke
    for x in (-0.15, 0.15):
        for y in (0.45, 0.75):
            for z in (4.95, 5.25):
                _k(k, x, y, z, 'h_stilk')
        _k(k, x, 0.15, 5.25, 'h_stilk')
    for (x, y, z) in ((0.45, 1.05, 4.95), (0.75, 1.05, 4.95), (1.05, 1.05, 4.95), (1.05, 1.35, 4.95),
                      (1.05, 1.35, 5.25), (0.75, 1.35, 5.25)):
        _k(k, x, y, z, 'h_blad')
    w = f.vinge
    w.ellipsoide((1.12, -0.55, 2.05), (0.3, 1.25, 0.72), SV, rot=(-14, 0, 0))
    w.kjegle((0.85, -1.55, 1.95), (0.85, -2.45, 1.55), 0.36, 0.16, SV, bredde=0.6)
    w.prikker([('a_kraglans', 0.18), ('a_kralilla', 0.08)], bare=[SV], fro=5)
    f.hengsel = (1.05, 0.25, 2.6)
    f.punkter = dict(hode=hc, hale=(0, -2.6, 1.35), topp=(0, 0.5, 5.4))
    return f


# ------------------------------------------------------------------ VampireFinch

def vampyrfink():
    """VampireFinch (Epic): liten, rund fink (den ekte vampyrfinken drikker blod!) kledd som Dracula:
    blekt ansikt med bakoverstrøket svart hår og spiss i panna, røde øyne, hoggtenner, lys skjortefront —
    og vingene er en kappe, svart utenpå og rød inni, som slår ut når den flakser. Bak hodet står en høy
    krage (rød foran, svart bak) med spisser som peker utover."""
    V, VL, SV, RD = 'h_vamp', 'h_blek', 'a_krasvart', 'h_kapperod'
    f = Fugl()
    k = f.kropp
    for s in (-1, 1):
        x = s * 0.45
        bein(k, x, (-0.05, 0.85), (0.05, 0.3), 'a_kranebb')
        fot(k, x, 0.05, 'a_kranebb', form='T', klo='klo')
    k.ellipsoide((0, -0.05, 1.65), (0.92, 0.92, 0.9), V, p=2.1)
    k.ellipsoide((0, 0.55, 1.55), (0.68, 0.5, 0.75), VL, modus='mal')                  # hvit skjortefront
    # kragen: står bak hodet og bøyer seg fram på sidene, med spisser som peker utover i ørehøyde
    def krage_y(x, z):
        return -0.6 + 0.28 * x * x - 0.4 * (z - 2.5)
    hoyre = [(0.0, 2.4), (0.8, 2.4), (1.4, 2.65), (1.8, 3.05), (2.0, 3.55), (1.98, 4.1), (1.6, 3.9), (1.2, 3.8),
             (0.6, 3.75), (0.0, 3.75)]
    krage = hoyre + [(-x, z) for (x, z) in reversed(hoyre[1:-1])]
    flate(k, krage, SV, dybde=lambda x, z: krage_y(x, z) - 0.15, tykk=0.3)
    flate(k, krage, RD, dybde=lambda x, z: krage_y(x, z) + 0.15, tykk=0.3)
    # hodet: stort og rundt — blekt ansikt foran, svart hår over med en spiss ned i panna
    k.ellipsoide((0, 0.3, 3.3), (1.08, 1.0, 1.05), V, p=2.0)
    k.ellipsoide((0, 0.95, 3.15), (1.0, 0.75, 0.75), VL, modus='mal')

    def haar(p, _t):
        spiss = 3.6 + 0.6 * min(1.0, abs(p.x) / 0.75)                                 # V-en i panna
        return SV if p.z > (spiss if p.y > 0.6 else 3.75 - 0.3 * max(0.0, 0.6 - p.y)) else None
    k.ellipsoide((0, 0.3, 3.3), (1.2, 1.2, 1.2), haar, modus='mal')
    k.stempel_par((1.05, 0.75, 3.55), ['wr', 'rr'], {'w': 'hvit', 'r': 'b_kasrod'})
    k.kjegle((0, 1.1, 3.0), (0, 1.7, 2.9), 0.3, 0.1, SV)
    for z in (2.85, 2.55):
        _k2(k, 0.45, 1.05, z, 'tann')
    # kappen (vingen): et klokkeformet skall fra skulderen og ned, åpent foran, med flaggermus-søm
    w = f.vinge
    yb, ztopp, zbunn = -0.1, 2.55, 0.5

    def kappe(q):
        if q.x < 0 or q.z > ztopp or q.z < zbunn:
            return None
        t = (ztopp - q.z) / (ztopp - zbunn)
        a = 0.62 + 0.88 * t
        dy = q.y - yb
        th = math.degrees(math.atan2(dy, q.x))                   # 0 = ut til siden, +90 = forover
        if th > 48:
            return None
        fase = ((th + 90) / 138 * 2.5) % 1.0
        if q.z < zbunn + 0.55 * (1 - (2 * fase - 1) ** 2):
            return None
        r = math.hypot(q.x, dy / 1.08)
        if r > a or r < a - 0.62:
            return None
        if th > 30:
            return 0.0                                            # rødt slag langs forkanten
        return 0.99 if r > a - 0.3 else 0.0
    w._fyll(Vector((0, -1.9, zbunn)), Vector((1.7, 1.0, ztopp)), kappe, [RD, SV])
    f.hengsel = (0.8, -0.1, 2.5)
    f.punkter = dict(hode=(0, 0.3, 3.3), hale=(0, -1.4, 0.9), topp=(0, 0.3, 4.3))
    return f


# ------------------------------------------------------------------ WitchOwl

def _sperrer(v, farge, ny, sone, fro=0):
    """Små mørke sperrer i rader på brystet (bare på kuber med `farge` der sone(x, y, z) er sann)."""
    for (i, j, kk), f in list(v.celler.items()):
        if f != farge or (kk + fro) % 3:
            continue
        if not sone((i + 0.5) * S, (j + 0.5) * S, (kk + 0.5) * S):
            continue
        ii = i if i >= 0 else -1 - i
        if (ii + 2 * (kk // 3)) % 4 == 1:
            v.celler[(i, j, kk)] = ny
            if (i, j, kk + 1) in v.celler and v.celler[(i, j, kk + 1)] == farge and ii % 2 == 0:
                v.celler[(i, j, kk + 1)] = ny


def hekseugle():
    """WitchOwl (Epic): lilla ugle med høy, svart heksehatt (gullspenne og bøyd tupp), store oransje
    øyne og små øredusker under bremmen — og den sitter på en kost."""
    U, UL, UM, H = 'h_ugle', 'h_uglelys', 'h_uglemork', 'h_hatt'
    f = Fugl()
    k = f.kropp
    # kosten: skaftet forover, bustene bak
    k.kjegle((0, 2.3, 0.9), (0, -1.35, 0.45), 0.2, 0.2, 'b_lyrbrun')
    k.kjegle((0, -1.3, 0.45), (0, -2.9, 0.42), 0.35, 0.72, 'c_moastra')
    k.prikker([('c_moalys', 0.3)], bare=['c_moastra'], fro=4)
    k.kjegle((0, -1.45, 0.45), (0, -1.75, 0.45), 0.45, 0.45, UM)
    # ugla
    for s in (-1, 1):
        k.ellipsoide((s * 0.6, 0.3, 0.8), (0.38, 0.42, 0.32), UL)
        k.kjegle((s * 0.45, 0.6, 0.85), (s * 0.45, 0.75, 0.45), 0.15, 0.12, 'klo')
    k.ellipsoide((0, -0.1, 1.85), (1.35, 1.25, 1.2), U, p=2.0)
    k.ellipsoide((0, 0.35, 1.7), (1.05, 1.0, 0.95), UL, modus='mal')
    _sperrer(k, UL, UM, lambda x, y, z: y > 0.2 and z > 1.0)
    k.prikker([(UM, 0.12)], bare=[U], fro=6)
    for s in (-1, 1):                                                                 # øredusker
        k.kjegle((s * 0.95, 0.05, 3.95), (s * 1.75, -0.05, 4.4), 0.3, 0.12, U)
    k.ellipsoide((0, 0.1, 3.6), (1.45, 1.25, 1.05), U, p=1.9)
    k.boks((-2.0, 1.05, 2.6), (2.0, 2.5, 5.0), U, modus='fjern')                    # flatt ansikt

    def ansikt(x, z):
        if z < 2.7 or z > 4.45:
            return None
        d = math.hypot(abs(x) - 0.9, (z - 3.6) * 1.1)
        return UL if d < 0.85 else (UM if d < 1.1 else None)
    mal_forfra(k, ansikt, bare=[U])
    stempel_forfra(k, 1.35, 4.05, ['.oo.', 'owko', 'okko', '.oo.'], {'o': 'ojeoransje', 'w': 'hvit', 'k': 'svart'})
    k.kjegle((0, 0.85, 3.45), (0, 1.15, 3.05), 0.22, 0.12, 'b_horn')
    # heksehatten (trukket godt ned over hodet): bred brem, kjegle som bøyer bakover i tuppen,
    # grønt bånd og en gullspenne
    k.ellipsoide((0, 0.0, 4.35), (1.62, 1.52, 0.15), H)
    k.kjegle((0, -0.05, 4.35), (0, -0.15, 5.15), 0.95, 0.6, H)
    k.kjegle((0, -0.15, 5.15), (0, -0.35, 5.7), 0.6, 0.36, H)
    k.kjegle((0, -0.35, 5.7), (0, -0.8, 6.0), 0.36, 0.17, H)
    k.kjegle((0, -0.8, 6.0), (0, -1.15, 5.95), 0.17, 0.1, H)
    k.boks((-2, -2, 4.5), (2, 2, 4.8), 'h_blad', modus='mal')
    paa_forsiden(k, 4.95, ['gg', 'gg'], {'g': 'fgull'})
    w = f.vinge
    w.ellipsoide((1.37, -0.25, 2.1), (0.32, 1.0, 1.1), U, rot=(-6, 0, 0))
    for y in (-0.85, -0.25):
        w.boks((1.0, y - 0.12, 1.0), (1.9, y + 0.12, 3.0), UM, modus='mal')
    f.hengsel = (1.3, 0.2, 2.9)
    f.punkter = dict(hode=(0, 0.1, 3.6), hale=(0, -2.9, 0.45), topp=(0, -0.4, 6.3))
    return f


# ------------------------------------------------------------------ SkeletonRaven

def _knoke(v, x, y, z, farge):
    """Knute på et ledd: 2x2x2 kuber rundt kubehjørnet (x, y, z)."""
    v.boks((x - 0.3, y - 0.3, z - 0.3), (x + 0.3, y + 0.3, z + 0.3), farge)


def ribbeinskasse(v, c, rx, ry, rz, ben, hulrom, flamme, flammelys):
    """Brystkasse: ringer av ribbein (annethvert lag) rundt et mørkt hulrom, med brystben foran og en
    grønn sjeleflamme inni som lyser ut mellom ribbeina."""
    cx, cy, cz = c
    k0, k1 = int(math.floor((cz - rz) / S)), int(math.floor((cz + rz) / S))
    for kk in range(k0, k1 + 1):
        z = (kk + 0.5) * S
        f = 1 - ((z - cz) / rz) ** 2
        if f <= 0:
            continue
        ax, ay = rx * math.sqrt(f), ry * math.sqrt(f)
        ribbe = (kk - k0) % 2 == 1 or kk == k1
        for i in range(-int(ax / S) - 2, int(ax / S) + 2):
            for j in range(int(math.floor((cy - ay) / S)) - 1, int(math.floor((cy + ay) / S)) + 2):
                x, y = (i + 0.5) * S, (j + 0.5) * S
                d = math.hypot(x / ax, (y - cy) / ay)
                if d > 1:
                    continue
                inne = math.hypot(x / max(ax - 0.42, 0.05), (y - cy) / max(ay - 0.42, 0.05)) < 1
                if not inne and (ribbe or abs(x) < 0.3 or y < cy - ay * 0.6):
                    v.celler[(i, j, kk)] = ben
                elif inne or not ribbe:
                    # hulrommet (og bunnen av glippene): mørkt, med flammen foran i midten
                    h = (z - (cz - rz)) / (2 * rz)
                    bredde = 0.75 * (1 - h) + 0.2
                    if abs(x) < bredde and y > cy:
                        v.celler[(i, j, kk)] = flammelys if abs(x) < bredde * 0.5 else flamme
                    else:
                        v.celler[(i, j, kk)] = hulrom


def skjelettravn():
    """SkeletonRaven (Legendary): en ravn av hvite knokler — ribbein med en grønn sjeleflamme inni,
    stor hodeskalle med mørke øyehuler og grønne, lysende pupiller, og vinger av benete fjærrader."""
    B, BM, HU, GL, GR = 'h_ben', 'h_benmork', 'h_hatt', 'h_gronnlys', 'h_gronn'
    f = Fugl()
    k = f.kropp
    for s in (-1, 1):
        x = s * 0.75
        linje(k, (x, -0.55, 2.4), (x, 0.05, 1.5), B)
        _knoke(k, s * 0.6, 0.0, 1.5, BM)
        linje(k, (x, 0.0, 1.5), (x, -0.05, 0.45), B)
        _knoke(k, s * 0.6, 0.0, 0.6, BM)
        fot(k, x, -0.05, B, form='T', klo=BM)
    # bekken, ryggrad og brystkasse
    k.ellipsoide((0, -0.7, 2.35), (0.85, 0.6, 0.3), B, p=2.5)
    for n in range(7):
        k.boks((-0.3, -1.15 + n * 0.08, 2.4 + n * 0.3), (0.3, -0.9 + n * 0.08, 2.7 + n * 0.3), BM if n % 2 else B)
    ribbeinskasse(k, (0, 0.15, 3.3), 1.2, 1.05, 1.05, B, HU, GR, GL)
    # nakkevirvler og hodeskalle
    for n in range(2):
        k.boks((-0.3, 0.45 + n * 0.25, 4.35 + n * 0.3), (0.3, 0.75 + n * 0.25, 4.65 + n * 0.3), BM if n % 2 else B)
    k.ellipsoide((0, 1.0, 5.35), (1.05, 1.02, 0.95), B, p=2.3)
    k.kjegle((0, 1.75, 5.45), (0, 3.15, 5.1), 0.42, 0.14, B, hoyde=0.9)
    k.kjegle((0, 3.0, 5.2), (0, 3.3, 4.8), 0.2, 0.1, B)
    k.kjegle((0, 1.75, 5.0), (0, 2.85, 4.9), 0.27, 0.12, B)
    k.boks((-0.5, 1.95, 5.03), (0.5, 2.95, 5.13), HU, modus='mal')                  # munnlinje
    _k2(k, 0.15, 2.25, 5.55, HU)                                                     # nesebor
    skjaer_side(k, (1.05, 1.1, 5.5), ['.hh.', 'hlgh', 'hggh', '.hh.'], {'h': HU, 'g': GR, 'l': GL})
    # halen: en vifte av benpinner med mørke tupper
    for vinkel in (-40, -20, 0, 20, 40):
        a = math.radians(vinkel)
        x0 = 0.15 if vinkel >= 0 else -0.15
        ende = (x0 + 1.6 * math.sin(a), -1.05 - 1.6 * math.cos(a), 1.75 + abs(vinkel) / 100)
        linje(k, (x0, -1.0, 2.25), ende, [B, B, B, BM])
    # vingen (spredt): løftede armknokler med en kam av benete fjær som henger ned og vifter utover
    w = f.vinge
    arm = [(1.0, -0.35, 3.95), (1.9, -0.35, 4.8), (2.85, -0.35, 5.7), (3.75, -0.35, 6.25)]
    for a, b in zip(arm, arm[1:]):
        linje(w, a, b, B)
    _knoke(w, 1.8, -0.3, 4.8, BM)
    _knoke(w, 2.7, -0.3, 5.7, BM)

    def paa_armen(x):
        for a, b in zip(arm, arm[1:]):
            if x <= b[0]:
                return Vector(a).lerp(Vector(b), (x - a[0]) / (b[0] - a[0]))
        return Vector(arm[-1])
    for i, (x0, lengde) in enumerate(((1.95, 1.55), (2.45, 1.95), (2.95, 2.3), (3.4, 2.5), (3.75, 2.55))):
        a = paa_armen(x0)
        b = a + Vector((0.1 + 0.2 * i, 0.0, -lengde))
        linje(w, a, b, [B, B, B, B, BM])
        _k(w, b.x, b.y, b.z, BM)
    f.hengsel = (1.0, -0.35, 3.95)
    f.punkter = dict(hode=(0, 1.0, 5.35), hale=(0, -2.65, 1.75), topp=(0, 1.0, 6.35))
    return f


# ------------------------------------------------------------------ GhostDove

def laken(v, c, ztopp, zbunn, r_topp, r_bunn, farge, flikker=6, bolge=0.45, bak=0.4, kurve=1.0, p=2.2):
    """Lakenskjørt/-hale: henger ned fra ztopp og ender i en bølgete søm (runde flikker) ved zbunn.
    Radiene går fra r_topp til r_bunn, og sømmen flyter `bak` bakover (kurve > 1: mest nederst)."""
    cx, cy = c

    def test(q):
        if q.z > ztopp:
            return None
        t = (ztopp - q.z) / (ztopp - zbunn)
        rx = r_topp[0] + (r_bunn[0] - r_topp[0]) * t
        ry = r_topp[1] + (r_bunn[1] - r_topp[1]) * t
        dx, dy = q.x - cx, q.y - (cy - bak * t ** kurve)
        if abs(dx / rx) ** p + abs(dy / ry) ** p > 1:
            return None
        fase = (math.atan2(dx, dy) / (2 * math.pi) * flikker) % 1.0
        if q.z < zbunn + bolge * (2 * fase - 1) ** 2:
            return None
        return t
    rm = max(r_topp + r_bunn)
    v._fyll(Vector((cx - rm, cy - rm - bak, zbunn)), Vector((cx + rm, cy + rm, ztopp)), test, farge)


def _minispokelse(e, c, retning):
    """Lite lakenspøkelse til ringen rundt spøkelsesduen. retning = (dx, dy) langs x- eller y-aksen:
    dit det ser."""
    cx, cy, cz = c
    e.ellipsoide((cx, cy, cz + 0.3), (0.62, 0.62, 0.5), 'h_spok', p=2.2)
    laken(e, (cx, cy), cz + 0.2, cz - 0.65, (0.62, 0.62), (0.68, 0.68), 'h_spokcyan', flikker=4, bolge=0.3, bak=0)
    ut = Vector((retning[0], retning[1], 0))
    side = Vector((-ut.y, ut.x, 0))
    for s in (-1, 1):
        mal_punkt(e, Vector(c) + ut * 1.5 + side * (0.3 * s) + Vector((0, 0, 0.45)), -ut, 'svart')


def spokelsesdue():
    """GhostDove (Mythic): en spøkelsesdue i hvitt og blekt cyan som svever — ingen bein, kroppen ender i
    en bølgete lakenhale som nesten når bakken. Store runde øyne, rosa kinn, en liten «Boo»-munn og
    vinger som lakenflagg løftet i været. Rundt den svever små spøkelser."""
    SP, SC, SB, SM = 'h_spok', 'h_spokcyan', 'h_spokbla', 'h_spokmork'
    farge = langs((0, 0, 6.9), (0, 0, 0.3), [SP, SP, SP, SC, SC, SB])
    f = Fugl()
    k = f.kropp
    k.ellipsoide((0, -0.1, 4.2), (1.45, 1.35, 1.35), farge, p=2.2)
    k.ellipsoide((0, 0.5, 4.4), (1.15, 0.85, 1.0), farge, p=2.2)
    laken(k, (0, -0.1), 3.6, 0.3, (1.4, 1.3), (0.95, 0.9), farge, flikker=5, bolge=0.5, bak=1.1, kurve=1.6)
    for c, f_ in list(k.celler.items()):                                             # folder i lakenet
        x, y, z = (c[0] + 0.5) * S, (c[1] + 0.5) * S, (c[2] + 0.5) * S
        if z < 3.3 and f_ in (SP, SC) and math.sin(math.atan2(x, y + 0.6) * 5) > 0.8:
            k.celler[c] = SC if f_ == SP else SB
    k.ellipsoide((0, 0.45, 6.0), (0.98, 0.95, 0.88), farge, p=2.2)
    stempel_forfra(k, 0.75, 6.35, ['kw', 'kk', 'kk'], {'k': 'svart', 'w': 'hvit'})
    stempel_forfra(k, 1.05, 5.45, ['rr'], {'r': 'a_flamingo'})
    k.kjegle((0, 1.3, 5.85), (0, 1.7, 5.8), 0.2, 0.12, SB)
    stempel_forfra(k, 0.15, 5.45, ['k', 'k'], {'k': SM})
    # vingen (spredt): et lakenflagg løftet opp og ut — hvitt øverst, blått i den bølgete sømmen
    w = f.vinge
    topp = [(1.0, 5.0), (1.9, 5.9), (2.8, 6.5), (3.4, 6.75), (3.8, 6.45)]
    a, b = Vector((3.8, 5.85)), Vector((1.05, 3.6))
    som = []
    for n in range(25):
        t = n / 24
        q = a.lerp(b, t)
        som.append((q.x, q.y - 0.55 * abs(math.sin(math.pi * 3 * t)) ** 0.7))
    flate(w, topp + som, langs((1.6, 0, 5.5), (2.35, 0, 4.4), [SP, SP, SC, SB]),
          dybde=lambda u, w_: -0.3 - 0.1 * u + 0.12 * math.sin(u * 2.5), tykk=0.6)
    # ekstra: fire små spøkelser som jager hverandre rundt duen. Spillet roterer Ekstra mot klokka sett
    # ovenfra, så et spøkelse i (dx, dy) farer i retningen (-dy, dx) — dit ser det.
    e = Voksler(S)
    for (dx, dy) in ((1, 0), (0, 1), (-1, 0), (0, -1)):
        _minispokelse(e, (2.85 * dx, -0.15 + 2.85 * dy, 2.4), (-dy, dx))
    f.ekstra = e
    f.hengsel = (1.05, -0.3, 4.6)
    f.punkter = dict(hode=(0, 0.45, 6.0), hale=(0, -1.6, 0.5), topp=(0, 0.45, 6.9), ekstra=(0, -0.15, 2.4))
    return f


# ------------------------------------------------------------------ katalog
FUGLER = {
    'PumpkinCrow': gresskarkraake,
    'VampireFinch': vampyrfink,
    'WitchOwl': hekseugle,
    'SkeletonRaven': skjelettravn,
    'GhostDove': spokelsesdue,
}
