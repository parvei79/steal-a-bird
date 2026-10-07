import math
import rbxlib as R
from fuglebygg import Fugl, S, OYE, SOT_OYE, bein, fot, Voksler, farge_trio, langs
from mathutils import Vector

# Legendary- og Mythic-fuglene i Steal a Bird — de største og kuleste i spillet (blokkstil, voksler):
#
#     HaastsEagle   (Legendary)  kjempeørn: krokete kjempenebb, enorme klør, vingene halvveis ute
#     Moa           (Legendary)  høy, lodden høystakk på tykke bein — og bare to bitte små fjærdotter
#     Pterodactyl   (Legendary)  flygeøgle: lærvinger mellom lange fingerbein, lang kam, tenner i nebbet
#     IcePhoenix    (Mythic)     Phoenix-søsteren av is: kantete krystallvinger, istapper og iskrone
#     Roc           (Mythic)     gigantisk gull-ørn med løftede vinger og en bitteliten elefant i klørne
#     Thunderbird   (Mythic)     stormørn med lyn på vingene, lynkam og en tordensky-ring som svever rundt
#
# Alle fargenavnene her starter med c_ (de andre fuglegruppene har egne prefikser).

# ------------------------------------------------------------------ farger
_TRIO = dict(
    # Haast's Eagle
    c_hbrun='#4b3224', c_hmork='#2e1f17', c_hlys='#7b5536', c_hgull='#b4823f', c_hnebb='#f2d27e',
    c_hkrok='#4a4440', c_hfot='#f4bb2c',
    # Moa
    c_moabrun='#8c5b2e', c_moalys='#c99a55', c_moamork='#5d3a1f', c_moarod='#a0552b', c_moanebb='#e6d6a4',
    c_moafot='#8b8a72', c_moaklo='#3a3833', c_moastra='#ead18a',
    # Pterodactyl
    c_prust='#b84a2b', c_poransje='#ea7a2f', c_pbuk='#f3d19b', c_phud='#e8853a', c_phudmork='#b53b25',
    c_pben='#6e2a1c', c_pkam='#ffbf2e', c_pnebb='#f2a43b',
    # Ice Phoenix
    c_ishvit='#effbff', c_islys='#a3dff8', c_iscyan='#5fd9f3', c_isbla='#2f9ae6', c_isdyp='#1f5bc6',
    c_isnatt='#172d73', c_isnebb='#cfe7f5',
    # Roc
    c_rgull='#f6b62a', c_rgullys='#ffd966', c_rgullmork='#c98612', c_rhvit='#fffaf0', c_rnebb='#ff9a1f',
    c_rkrok='#b85a12', c_rfot='#ffc23a', c_elefant='#9aa2ad', c_elefmork='#79818d', c_elefrosa='#f0a3b4',
    # Thunderbird
    c_tindigo='#2e3088', c_tnatt='#1a1a50', c_tbla='#3d62e0', c_tlyn='#ffe03a', c_tlynlys='#fff7b0',
    c_tnebb='#ffc21a', c_tfot='#e9b62e', c_tsky='#575c6b', c_tskylys='#8e94a3',
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


def flate(v, poly, farge, akser='xz', plan=(0.0, 0.0, 0.0), tykk=S, modus='fyll'):
    """Plan plate utspent av et polygon — vingeflater, lærhud, kammer, lyn.
    akser='xz': polygonet er (x, z)-punkter (sett forfra), og dybden følger planet y = c0 + a*x + b*z
    der plan = (c0, a, b). Tilsvarende for 'yz' (sett fra siden) og 'xy' (ovenfra).
    tykk = tykkelsen langs dybdeaksen (0.3 = én kube)."""
    ia, ib = 'xyz'.index(akser[0]), 'xyz'.index(akser[1])
    ic = 3 - ia - ib
    c0, a, b = plan
    us = [p[0] for p in poly]
    ws = [p[1] for p in poly]
    cs = [c0 + a * u + b * w for u in (min(us), max(us)) for w in (min(ws), max(ws))]
    lo, hi = [0.0] * 3, [0.0] * 3
    lo[ia], hi[ia] = min(us), max(us)
    lo[ib], hi[ib] = min(ws), max(ws)
    lo[ic], hi[ic] = min(cs) - tykk, max(cs) + tykk

    def test(q):
        u, w = q[ia], q[ib]
        d = q[ic] - (c0 + a * u + b * w)
        if d <= -tykk / 2 + 1e-7 or d > tykk / 2 + 1e-7:
            return None
        return 0.5 if _inne(poly, u, w) else None
    v._fyll(Vector(lo), Vector(hi), test, farge, modus)


def fjaer(v, rot, tupp, bredde, farge, plan=(0.0, 0.0, 0.0), akser='xz', tykk=S, form='fjaer', modus='fyll',
          spiss=0.7):
    """Flat fjær fra rot til tupp (2D-punkter i `akser`, dybden som i flate()).
    form='fjaer': jevn bredde og spiss tupp. form='krystall': rombe/drage, bredest ved 35 %.
    En fargeliste gir overgang fra rot til tupp."""
    (u0, w0), (u1, w1) = rot, tupp
    du, dw = u1 - u0, w1 - w0
    lengde = math.hypot(du, dw)
    nu, nw = -dw / lengde * bredde, du / lengde * bredde
    if form == 'krystall':
        m = 0.35
        poly = [(u0, w0), (u0 + du * m + nu, w0 + dw * m + nw), (u1, w1), (u0 + du * m - nu, w0 + dw * m - nw)]
    else:
        m = spiss
        poly = [(u0 + nu, w0 + nw), (u0 + du * m + nu, w0 + dw * m + nw), (u1, w1),
                (u0 + du * m - nu, w0 + dw * m - nw), (u0 - nu, w0 - nw)]
    if isinstance(farge, (list, tuple)):
        ia, ib = 'xyz'.index(akser[0]), 'xyz'.index(akser[1])
        a3, b3 = [0.0] * 3, [0.0] * 3
        a3[ia], a3[ib], b3[ia], b3[ib] = u0, w0, u1, w1
        farge = langs(a3, b3, farge)
    flate(v, poly, farge, akser, plan, tykk, modus)


def strek(v, punkter, r, farge, r2=None, modus='fyll'):
    """Tykk strek gjennom flere punkter (kjegler etter hverandre), radius fra r til r2."""
    r2 = r if r2 is None else r2
    n = len(punkter) - 1
    for i in range(n):
        v.kjegle(punkter[i], punkter[i + 1], r + (r2 - r) * i / n, r + (r2 - r) * (i + 1) / n, farge, modus=modus)


def skaar(v, a, b, r, farge, topp=0.35, rmin=0.0, modus='fyll'):
    """Krystallskår: dobbel kjegle fra a til b — tykkest ved andelen `topp`, spiss i begge ender.
    En fargeliste gir overgang fra a til b."""
    a, b = Vector(a), Vector(b)
    d = b - a
    l2 = d.length_squared
    lo = Vector([min(a[n], b[n]) - r for n in range(3)])
    hi = Vector([max(a[n], b[n]) + r for n in range(3)])

    def test(p):
        q = p - a
        t = q.dot(d) / l2
        if t < 0 or t > 1:
            return None
        rr = max(rmin, r * (t / topp if t < topp else (1 - t) / (1 - topp)))
        return t if (q - d * t).length_squared <= rr * rr else None
    v._fyll(lo, hi, test, farge, modus)


def striper(senter, farger, antall=40, fro=11):
    """Fargefunksjon: loddrette striper rundt en loddrett akse gjennom senter (x, y) — lodden pels, høy."""
    cx, cy = senter

    def f(p, _t):
        s = int((math.atan2(p.y - cy, p.x - cx) + math.pi) / (2 * math.pi) * antall) % antall
        return farger[int(_tilf(s, fro) * len(farger)) % len(farger)]
    return f


def _kurve(punkter, x):
    """Lineær interpolasjon i en liste med (x, z)-punkter sortert på x."""
    if x <= punkter[0][0]:
        return punkter[0][1]
    for (x0, z0), (x1, z1) in zip(punkter, punkter[1:]):
        if x <= x1:
            return z0 + (z1 - z0) * (x - x0) / max(x1 - x0, 1e-9)
    return punkter[-1][1]


def mal_punkt(v, start, retning, farge, steg=40):
    """Gå fra `start` i `retning` til første kube, og farg den (øyne på små, skrå hoder)."""
    p, d = Vector(start), Vector(retning).normalized() * (S * 0.5)
    for _ in range(steg):
        c = v._celle(p)
        if c in v.celler:
            v.celler[c] = farge
            return
        p += d


def lag_midt(z):
    """Z-midten av kubelaget nærmest z (for tynne malestriper)."""
    return (math.floor(z / S) + 0.5) * S


def rovnebb(k, y0, z0, nebb, krok, voks=None, munn=None, s=1.0):
    """Krokete rovfuglnebb som starter i (0, y0, z0): voksehud, høyt overnebb, krok som går ned, undernebb."""
    if voks:
        k.ellipsoide((0, y0, z0), (0.66 * s, 0.4 * s, 0.62 * s), voks)
    k.ellipsoide((0, y0 + 0.7 * s, z0 + 0.05 * s), (0.56 * s, 0.95 * s, 0.62 * s), nebb, p=2.4)
    k.kjegle((0, y0 + 0.15 * s, z0 + 0.55 * s), (0, y0 + 1.4 * s, z0 + 0.35 * s), 0.3 * s, 0.3 * s, nebb)
    k.kjegle((0, y0 + 1.45 * s, z0 + 0.4 * s), (0, y0 + 1.9 * s, z0 - 0.7 * s), 0.45 * s, 0.12 * s,
             [nebb, krok, krok])
    k.ellipsoide((0, y0 + 0.6 * s, z0 - 0.55 * s), (0.42 * s, 0.75 * s, 0.26 * s), nebb)
    zm = lag_midt(z0 - 0.5 * s)
    k.boks((-0.8 * s, y0 + 0.15 * s, zm - 0.05), (0.8 * s, y0 + 1.5 * s, zm + 0.05), munn or krok, modus='mal')


def klofot(v, x, y, farge, klo='klo'):
    """Rovfuglfot med enorme, krokete klør: tre tær forover og én bakover, knokene hevet og klørne
    krummer ned i bakken. (x, y) = ankelen; foten er fem kuber bred."""
    i0, j0, _ = v._celle((x, y, 0.15))

    def sett(di, dj, dk, f):
        v.celler[(i0 + di, j0 + dj, dk)] = f
    sett(0, 0, 0, farge)
    for dj in (1, 2):
        sett(0, dj, 0, farge)
    sett(0, 2, 1, farge)
    sett(0, 3, 1, klo)
    sett(0, 4, 1, klo)
    sett(0, 4, 0, klo)
    for s in (-1, 1):
        sett(s, 1, 0, farge)
        sett(2 * s, 1, 0, farge)
        sett(2 * s, 1, 1, farge)
        sett(2 * s, 2, 1, klo)
        sett(2 * s, 3, 1, klo)
        sett(2 * s, 3, 0, klo)
    sett(0, -1, 0, farge)
    sett(0, -1, 1, farge)
    sett(0, -2, 1, klo)
    sett(0, -3, 1, klo)
    sett(0, -3, 0, klo)


LYN = [(-0.10, 0.50), (0.30, 0.50), (0.08, 0.08), (0.32, 0.08), (-0.18, -0.50), (-0.02, -0.06), (-0.26, -0.06)]


def lyn(sentrum, hoyde, vinkel=0.0, bredde=1.0):
    """Lyn-polygon (2D) til flate(): skalert til `hoyde`, dreid `vinkel` grader (0 = spissen ned)."""
    cu, cw = sentrum
    a = math.radians(vinkel)
    ca, sa = math.cos(a), math.sin(a)
    ut = []
    for (u, w) in LYN:
        u, w = u * hoyde * bredde, w * hoyde
        ut.append((cu + u * ca - w * sa, cw + u * sa + w * ca))
    return ut


# ------------------------------------------------------------------ Haast's Eagle

def haastorn():
    """Haast's Eagle (Legendary): utdødd kjempeørn fra New Zealand — mørkebrun, enormt krokete nebb,
    gigantiske klør og vingene halvveis ute som en truende kappe."""
    B, M, L, G = 'c_hbrun', 'c_hmork', 'c_hlys', 'c_hgull'
    f = Fugl()
    k = f.kropp
    for s in (-1, 1):
        k.ellipsoide((s * 0.9, 0.0, 2.05), (0.66, 0.72, 0.9), B, p=2.2)          # fjærbukser
        bein(k, s * 1.05, (0.15, 1.4), (0.25, 0.3), 'c_hfot', r=0.3)
        klofot(k, s * 1.05, 0.25, 'c_hfot')
    k.ellipsoide((0, -0.35, 3.55), (1.5, 1.35, 1.8), B, rot=(-14, 0, 0), p=2.3)
    k.ellipsoide((0, 0.6, 3.3), (1.1, 0.7, 1.25), L, modus='mal')
    k.prikker([(B, 0.18)], bare=[L], fro=3)
    # hodet: stort, gylden nakke og tunge, sinte bryn
    k.ellipsoide((0, 0.85, 5.5), (1.1, 1.1, 1.0), B, p=2.4)
    k.ellipsoide((0, 0.05, 5.85), (1.1, 0.85, 0.8), G, modus='mal')
    k.prikker([(B, 0.3)], bare=[G], fro=5)
    for s in (-1, 1):
        k.kjegle((s * 0.8, 0.65, 6.3), (s * 0.9, 1.8, 5.85), 0.24, 0.22, M)
    rovnebb(k, 1.9, 5.5, 'c_hnebb', 'c_hkrok', voks='c_hfot')
    k.stempel_par((1.1, 1.35, 5.6), ['yyk', '.yy'], {'y': 'ojegul', 'k': 'svart'})
    # halen: bred vifte bakover
    for n in (-2, -1, 0, 1, 2):
        k.kjegle((0, -1.4, 2.8), (n * 0.55, -2.95 + abs(n) * 0.15, 1.35 + abs(n) * 0.15), 0.42, 0.34,
                 [B, B, L, M], bredde=1.25, hoyde=0.45)
    # vingen (spredt): gyllenbrun forkant, brune dekkfjær, mørke svingfjær som henger ned og
    # svarte fingerfjær ut mot spissen
    w = f.vinge
    bak = (-0.5, -0.08, 0.0)                     # y = -0.5 - 0.08x: vingene sveiper litt bakover
    foran = (bak[0] + 0.3, bak[1], bak[2])
    for i in range(6):
        x = 1.2 + i * 0.4
        fjaer(w, (x, 4.6 + i * 0.15), (x + 0.3, 2.7 + (0.3 if i % 2 else 0.0)), 0.24,
              [B, B, M] if i % 2 else [B, B, B, M], plan=bak)
    for (r0, t0) in (((3.05, 6.0), (4.45, 5.55)), ((3.1, 5.7), (4.4, 4.75)), ((3.05, 5.4), (4.15, 3.95)),
                     ((2.95, 5.1), (3.75, 3.3)), ((2.8, 4.8), (3.35, 2.85))):
        fjaer(w, r0, t0, 0.22, [B, M, M], plan=bak)
    kant = [(1.0, 5.05), (1.9, 5.95), (2.85, 6.45), (3.4, 6.1)]
    dekk = kant + [(3.35, 5.2), (2.5, 4.75), (1.6, 4.45), (1.0, 4.5)]

    def dekkfarge(p, _t):
        d = _kurve(kant, p.x) - p.z
        return G if d < 0.5 else (L if d < 1.1 else B)
    flate(w, dekk, dekkfarge, plan=foran, tykk=0.6)
    f.hengsel = (1.15, -0.3, 4.6)
    f.punkter = dict(hode=(0, 0.85, 5.5), hale=(0, -2.9, 1.35), topp=(0, 0.8, 6.6))
    return f


# ------------------------------------------------------------------ Moa

def _stakklag(v, c, r0, r1, ztopp, zkant, frynse, farge, fro, p=2.2, sektorer=48):
    """Ett lag lodne frynser: henger ned fra ztopp til en ujevn kant (zkant + 0..frynse), og vider seg
    ut fra radiene r0 (øverst) til r1 (nederst)."""
    cx, cy = c

    def kant(q):
        s = int((math.atan2(q.y - cy, q.x - cx) + math.pi) / (2 * math.pi) * sektorer) % sektorer
        return zkant + frynse * _tilf(s, fro)

    def test(q):
        if q.z > ztopp or q.z < kant(q):
            return None
        t = (ztopp - q.z) / max(ztopp - zkant, 1e-6)
        rx, ry = r0[0] + (r1[0] - r0[0]) * t, r0[1] + (r1[1] - r0[1]) * t
        return 0.0 if abs(q.x - cx) ** p / rx ** p + abs(q.y - cy) ** p / ry ** p <= 1 else None
    rm = (max(r0[0], r1[0]), max(r0[1], r1[1]))
    v._fyll(Vector((cx - rm[0], cy - rm[1], zkant)), Vector((cx + rm[0], cy + rm[1], ztopp)), test, farge)


def moa():
    """Moa (Legendary): utdødd kjempefugl uten vinger — høy som en høystakk på stylter, lang hals,
    lite hode og tykke bein."""
    BR, LY, MK, RD = 'c_moabrun', 'c_moalys', 'c_moamork', 'c_moarod'
    hoy = [BR, BR, BR, LY, LY, MK, RD]
    f = Fugl()
    k = f.kropp
    for s in (-1, 1):
        x = s * 1.05
        k.kjegle((x, -0.4, 2.8), (x, -0.15, 1.2), 0.5, 0.44, 'c_moafot')
        k.kjegle((x, -0.15, 1.3), (x, 0.05, 0.3), 0.44, 0.4, 'c_moafot')
        fot(k, x, 0.05, 'c_moafot', form='gaffel', klo='c_moaklo', lengde=4)
    # høystakken: en lodden kuppel og tre lag med frynser som blir videre nedover
    c = (0, -0.45)
    k.ellipsoide((0, -0.45, 3.95), (1.4, 1.7, 0.75), striper(c, hoy, 48, 1), p=2.2)
    _stakklag(k, c, (1.4, 1.7), (1.6, 1.9), 4.05, 3.5, 0.45, striper(c, hoy, 48, 2), 4)
    _stakklag(k, c, (1.55, 1.85), (1.8, 2.1), 3.7, 2.7, 0.5, striper(c, hoy, 48, 3), 5)
    _stakklag(k, c, (1.75, 2.05), (1.95, 2.25), 2.95, 2.0, 0.55, striper(c, hoy, 48, 4), 6)
    for n in range(12):                                                    # høystrå som stikker ut
        vk = 2 * math.pi * (n + 0.6 * _tilf(n, 21)) / 12
        z = 2.7 + 1.7 * _tilf(n, 22)
        rx, ry = 1.9 - 0.35 * (z - 2.7) / 1.7, 2.2 - 0.4 * (z - 2.7) / 1.7
        x0, y0 = rx * 0.92 * math.cos(vk), ry * 0.92 * math.sin(vk)
        f_ = 1 + (0.3 + 0.25 * _tilf(n, 23)) / max(rx, ry)
        k.kjegle((x0, y0 - 0.45, z), (min(2.2, max(-2.2, x0 * f_)), y0 * f_ - 0.45, z - 0.15 - 0.3 * _tilf(n, 24)),
                 0.17, 0.15, 'c_moastra')
    # halsen: lang og lodden, i små lag foran på stakken
    k.kjegle((0, 0.95, 4.2), (0, 1.4, 6.8), 0.4, 0.36, BR)
    for n, (y, z, r) in enumerate(((0.95, 4.55, 0.58), (1.05, 5.05, 0.52), (1.15, 5.55, 0.48), (1.25, 6.05, 0.45),
                                   (1.33, 6.5, 0.42))):
        _stakklag(k, (0, y), (r - 0.1, r - 0.1), (r, r), z + 0.35, z - 0.3, 0.22,
                  striper((0, y), hoy, 16, 7 + n), 8 + n)
    # hodet: lite!
    k.ellipsoide((0, 1.55, 6.9), (0.62, 0.65, 0.55), BR, p=2.6)
    k.kjegle((0, 2.05, 6.9), (0, 2.65, 6.7), 0.24, 0.13, 'c_moanebb')
    k.kjegle((0, 2.6, 6.75), (0, 2.8, 6.5), 0.15, 0.1, 'c_moanebb')
    k.stempel_par((0.6, 1.8, 7.05), ['k'], OYE)
    for (y1, z1) in ((1.15, 7.5), (1.5, 7.5)):
        k.kjegle((0, 1.4, 7.3), (0, y1, z1), 0.16, 0.1, LY)                    # bustete hår
    # «vingene»: bitte små fjærdotter som knapt synes
    w = f.vinge
    w.ellipsoide((1.72, -0.45, 3.6), (0.2, 0.25, 0.25), LY)
    w.kjegle((1.75, -0.6, 3.45), (1.75, -0.8, 3.25), 0.15, 0.1, BR)
    f.hengsel = (1.55, -0.4, 3.7)
    f.punkter = dict(hode=(0, 1.55, 7.0), hale=(0, -2.5, 3.0), topp=(0, 1.4, 7.5))
    return f


# ------------------------------------------------------------------ Pterodactyl

def pterodaktyl():
    """Pterodactyl (Legendary): ingen fugl — en flygeøgle med lærvinger mellom lange fingerbein,
    lang kam bak på hodet og et langt nebb med små tenner. Rustrød og oransje."""
    RU, BU = 'c_prust', 'c_pbuk'
    f = Fugl()
    k = f.kropp
    for s in (-1, 1):
        x = s * 0.75
        k.ellipsoide((s * 0.6, -0.15, 2.0), (0.45, 0.55, 0.6), RU)
        bein(k, x, (-0.1, 1.6), (0.0, 0.3), 'c_pben', r=0.2)
        fot(k, x, 0.0, 'c_pben', form='T', klo='klo')
    k.ellipsoide((0, -0.2, 3.0), (0.95, 0.95, 1.25), RU, rot=(-12, 0, 0), p=2.2)
    k.ellipsoide((0, 0.45, 2.8), (0.7, 0.55, 0.95), BU, modus='mal')
    k.kjegle((0, -1.0, 2.3), (0, -2.0, 1.6), 0.3, 0.1, RU)
    # lang hals og stort hode
    k.kjegle((0, 0.05, 3.8), (0, 0.75, 5.0), 0.5, 0.42, RU)
    k.ellipsoide((0, 0.95, 5.25), (0.62, 0.85, 0.62), RU, p=2.2)
    # nebbet: langt og spisst, med en rad små tenner
    k.kjegle((0, 1.55, 5.4), (0, 4.2, 5.15), 0.44, 0.1, 'c_pnebb', bredde=0.9, hoyde=0.85)
    k.kjegle((0, 1.55, 4.85), (0, 3.75, 4.85), 0.3, 0.1, 'c_pnebb')
    zm = lag_midt(5.0)
    k.boks((-0.6, 1.65, zm - 0.05), (0.6, 4.0, zm + 0.05), 'c_pben', modus='mal')
    k.stempel_par((0.6, 2.85, zm), ['w.w.w.w.w'], {'w': 'tann'})
    # kammen: lang og høy trekant rett bakover — hodet blir som en hakke
    kam = [(1.0, 5.95), (0.2, 6.35), (-2.35, 6.7), (-2.05, 6.25), (-0.15, 5.1)]
    flate(k, kam, langs((0, 0.9, 0), (0, -2.4, 0), [RU, RU, 'c_phudmork', 'c_pkam']), akser='yz', tykk=0.6)
    k.stempel_par((0.6, 1.2, 5.4), ['mm.', 'yk.'], {'m': 'c_pben', 'y': 'ojegul', 'k': 'svart'})
    # vingen: lærhud mellom armen, den lange flygefingeren og kroppen
    w = f.vinge
    a = -0.25                                     # vingene sveiper bakover

    def p3(xz, dy=0.0):
        return (xz[0], -0.35 + a * (xz[0] - 0.75) + dy, xz[1])
    skulder, albue, handledd = (0.75, 3.95), (1.55, 4.75), (2.35, 5.4)
    fingermidt, spiss = (3.4, 5.15), (4.35, 4.45)
    hud = [skulder, albue, handledd, fingermidt, spiss, (3.55, 3.85), (2.75, 3.35), (2.05, 2.75), (1.45, 2.15),
           (0.85, 2.4)]
    flate(w, hud, langs((0, 0, 5.4), (0, 0, 2.2), ['c_phud', 'c_phud', 'c_poransje', 'c_phudmork']),
          plan=(-0.35 - a * 0.75, a, 0.0))
    for ende in ((3.3, 3.75), (2.4, 3.05), (1.6, 2.4)):
        w.kjegle(p3(handledd), p3(ende), 0.2, 0.2, 'c_phudmork', modus='mal')
    strek(w, [p3(skulder, 0.3), p3(albue, 0.3), p3(handledd, 0.3)], 0.26, 'c_pben')
    strek(w, [p3(handledd, 0.3), p3(fingermidt, 0.3), p3(spiss, 0.3)], 0.22, 'c_pben', r2=0.15)
    hx, hy, hz = p3(handledd, 0.3)
    for n in range(3):
        w.kjegle((hx, hy, hz), (hx - 0.2 + n * 0.25, hy + 0.55, hz + 0.3 - n * 0.15), 0.15, 0.1, 'klo')
    f.hengsel = (0.7, -0.3, 3.85)
    f.punkter = dict(hode=(0, 0.95, 5.25), hale=(0, -2.0, 1.6), topp=(0, -0.8, 6.6))
    return f


# ------------------------------------------------------------------ Ice Phoenix

def isfonix():
    """Ice Phoenix (Mythic): Phoenix-søsteren av is — kantete krystallfjær i hvitt, cyan og isblått,
    iskrone på hodet, istapper under vingene og en lang krystallhale."""
    H, LY, CY, BL, DY, NA = 'c_ishvit', 'c_islys', 'c_iscyan', 'c_isbla', 'c_isdyp', 'c_isnatt'
    f = Fugl()
    k = f.kropp
    for s in (-1, 1):
        x = s * 0.45
        bein(k, x, (-0.25, 2.0), (-0.1, 0.3), BL)
        fot(k, x, -0.1, BL, form='stump', klo=H)
    k.ellipsoide((0, -0.3, 3.3), (1.4, 1.45, 1.65), LY, rot=(-18, 0, 0), p=1.5)
    k.ellipsoide((0, 0.6, 3.0), (0.95, 0.65, 1.05), H, modus='mal')
    k.ellipsoide((0, 1.05, 3.25), (0.5, 0.35, 0.75), CY, p=1.0)                 # iskrystall på brystet
    k.boks((-0.2, 1.0, 3.4), (0.2, 1.5, 3.7), H, modus='mal')
    # hode
    k.ellipsoide((0, 0.7, 4.9), (0.85, 0.85, 0.8), LY, p=1.6)
    k.ellipsoide((0, 1.2, 4.8), (0.7, 0.5, 0.55), H, modus='mal')
    skaar(k, (0, 1.4, 4.9), (0, 2.3, 4.6), 0.34, ['c_isnebb', 'c_isnebb', BL], topp=0.15)
    k.stempel_par((0.85, 0.95, 5.0), ['.wk', 'ckk'], {'w': 'hvit', 'k': NA, 'c': CY})
    # iskrona: flate krystaller i vifte (synlig forfra) og to bakover (synlig fra siden)
    for vinkel, lengde in ((-58, 1.4), (-30, 2.0), (0, 2.6), (30, 2.0), (58, 1.4)):
        vk = math.radians(vinkel)
        fjaer(k, (0, 5.3), (lengde * math.sin(vk), 5.3 + lengde * math.cos(vk)), 0.42, [H, LY, CY, BL, DY],
              plan=(0.45 + 0.45 * 5.3, 0.0, -0.45), tykk=0.6, form='krystall')
    for tupp in ((-1.2, 7.05), (-1.65, 6.2)):
        fjaer(k, (0.55, 5.35), tupp, 0.36, [H, LY, CY, BL], akser='yz', tykk=0.6, form='krystall')
    # krystallhalen
    for n in (-2, -1, 0, 1, 2):
        slutt = (n * 0.85, -3.9 - (0.5 if n == 0 else 0) + abs(n) * 0.2, 0.9 + abs(n) * 0.35)
        skaar(k, (0, -1.2, 2.6), slutt, 0.6 - abs(n) * 0.06, [H, LY, CY, BL, DY], topp=0.3)
    # vingen (spredt): én stor, kantete isplate — rett forkant som en klinge opp mot en skarp spiss,
    # krystalltagger ut og istapper ned. Fargene ligger i skrå fasetter: hvitt langs forkanten,
    # så isblått, cyan og dypblått ut mot taggene (ikke flammer som Phoenix)
    w = f.vinge
    forkant = [(1.0, 4.9), (2.2, 6.0), (3.35, 6.9), (4.4, 7.45)]
    vinge = forkant + [(4.0, 6.35), (4.45, 5.85), (3.8, 5.35), (4.25, 4.55), (3.4, 4.5), (3.55, 3.45), (2.8, 3.9),
                       (2.65, 2.85), (2.15, 3.5), (1.75, 2.8), (1.45, 3.45), (1.0, 3.6)]
    fasetter = [H, LY, CY, BL, DY]

    def fasett(p, _t):
        return fasetter[min(len(fasetter) - 1, int((_kurve(forkant, p.x) - p.z) / 0.72))]
    flate(w, vinge, fasett, plan=(-0.35 + 0.15 * 1.0, -0.15, 0.0), tykk=0.6)
    for (x, z0, z1) in ((1.45, 3.55, 2.95), (2.15, 3.6, 2.75), (2.85, 3.95, 3.1)):              # istapper
        y = -0.2 - 0.15 * x
        w.kjegle((x, y, z0), (x, y, z1), 0.22, 0.1, [LY, CY, BL])
    f.hengsel = (0.9, -0.25, 4.3)
    f.punkter = dict(hode=(0, 0.7, 4.9), hale=(0, -4.3, 0.9), topp=(0, 0.3, 7.5))
    return f


# ------------------------------------------------------------------ Roc

def elefant(v, c, s=1.0, dreid=0.0):
    """Bitteliten grå elefant med kroppens sentrum i c, skala s, dreid `dreid` grader om loddaksen
    (0 = ser forover, +y). Snabelen er løftet — den trompeterer i panikk. Roc-ens matpakke."""
    G, M, RS = 'c_elefant', 'c_elefmork', 'c_elefrosa'
    cx, cy, cz = c
    a = math.radians(dreid)
    ca, sa = math.cos(a), math.sin(a)

    def P(dx, dy, dz):
        dx, dy, dz = dx * s, dy * s, dz * s
        return (cx + dx * ca - dy * sa, cy + dx * sa + dy * ca, cz + dz)
    rot = (0, 0, dreid)
    v.ellipsoide(P(0, -0.1, 0), (0.5 * s, 0.62 * s, 0.45 * s), G, rot=rot, p=2.2)
    v.ellipsoide(P(0, 0.55, 0.2), (0.42 * s, 0.36 * s, 0.42 * s), G, rot=rot, p=2.2)
    for sd in (-1, 1):
        v.ellipsoide(P(sd * 0.68, 0.4, 0.25), (0.13 * s, 0.45 * s, 0.6 * s), M, rot=rot)
        v.ellipsoide(P(sd * 0.68, 0.48, 0.22), (0.12 * s, 0.22 * s, 0.32 * s), RS, rot=rot, modus='mal')
        for dy in (-0.42, 0.2):
            v.kjegle(P(sd * 0.3, dy, -0.3), P(sd * 0.3, dy, -0.78), 0.15 * s, 0.15 * s, G)
        v.kjegle(P(sd * 0.25, 0.8, -0.05), P(sd * 0.3, 1.05, 0.1), 0.14 * s, 0.1 * s, 'tann')
    strek(v, [P(0, 0.8, 0.0), P(0, 1.2, 0.05), P(0, 1.45, 0.35), P(0, 1.5, 0.75), P(0, 1.35, 0.95)], 0.2 * s, G,
          r2=0.15 * s)
    for sd in (-1, 1):
        x0, y0, z0 = P(sd * 0.3, 0.7, 0.35)
        x1, y1, z1 = P(sd * 1.5, 0.7, 0.35)
        mal_punkt(v, (x1, y1, z1), (x0 - x1, y0 - y1, z0 - z1), 'svart')


def rokk():
    """Roc (Mythic): gigantisk mytisk ørn i gull og hvitt, med enorme løftede vinger —
    og en bitteliten elefant i klørne."""
    G, GL, GM, HV = 'c_rgull', 'c_rgullys', 'c_rgullmork', 'c_rhvit'
    f = Fugl()
    k = f.kropp
    # venstre bein står på bakken
    k.ellipsoide((-0.8, 0.0, 2.5), (0.72, 0.78, 0.9), G, p=2.2)
    bein(k, -0.75, (0.1, 1.7), (0.15, 0.3), 'c_rfot', r=0.3)
    klofot(k, -0.75, 0.15, 'c_rfot')
    # høyre bein er løftet og holder elefanten foran brystet
    k.ellipsoide((0.85, 0.5, 3.05), (0.72, 0.8, 0.85), G, p=2.2)
    E = (1.25, 2.25, 2.5)
    elefant(k, E, s=1.65, dreid=30)
    ankel = (1.1, 1.7, 3.55)
    strek(k, [(0.95, 0.85, 2.95), ankel], 0.3, 'c_rfot')
    for (x1, y1, z1) in ((1.35, 2.6, 3.3), (0.5, 2.25, 3.05), (1.9, 2.0, 3.1), (1.05, 1.35, 3.15)):
        k.kjegle(ankel, (x1, y1, z1), 0.2, 0.18, 'c_rfot')
        k.kjegle((x1, y1, z1), (x1, y1 + 0.1, z1 - 0.45), 0.17, 0.12, 'klo')
    # kroppen
    k.ellipsoide((0, -0.4, 4.1), (1.65, 1.5, 2.0), G, rot=(-12, 0, 0), p=2.3)
    k.ellipsoide((0, 0.6, 3.8), (1.2, 0.7, 1.4), GL, modus='mal')
    # hodet: hvitt som en havørn, med en krone av gullfjær
    k.ellipsoide((0, 0.9, 6.3), (1.1, 1.15, 1.0), HV, p=2.4)
    k.ellipsoide((0, 0.35, 5.65), (1.35, 1.1, 0.75), HV, modus='mal')
    for (x1, y1, z1) in ((0, -0.05, 8.4), (0, -0.95, 7.85), (0.7, -0.4, 8.0), (-0.7, -0.4, 8.0)):
        k.kjegle((x1 * 0.3, 0.45, 6.95), (x1, y1, z1), 0.34, 0.14, [G, G, GL, HV])     # gullkrone
    for s in (-1, 1):
        k.kjegle((s * 0.8, 0.7, 6.85), (s * 0.9, 1.85, 6.4), 0.22, 0.2, GM)       # bryn
    rovnebb(k, 2.0, 6.3, 'c_rfot', 'c_rnebb', munn='c_rkrok')
    k.stempel_par((1.1, 1.4, 6.4), ['ook', '.oo'], {'o': 'ojerod', 'k': 'svart'})
    # hale: hvit vifte
    for n in (-2, -1, 0, 1, 2):
        k.kjegle((0, -1.6, 3.0), (n * 0.6, -3.0, 1.4 + abs(n) * 0.3), 0.4, 0.3, [HV, HV, HV, GL],
                 bredde=1.2, hoyde=0.5)
    # vingen (spredt): løftet høyt som en ørn i et riksvåpen — gylne fjær med hvite tupper
    w = f.vinge
    bak, foran = (-0.65 + 0.12 * 1.2, -0.12, 0.0), (-0.35 + 0.12 * 1.2, -0.12, 0.0)
    for i in range(5):
        x = 1.25 + i * 0.42
        fjaer(w, (x, 5.6 + i * 0.3), (x + 0.15, 3.95 + (0.35 if i % 2 else 0.0)), 0.27,
              [G, G, G, HV] if i % 2 else [GL, G, G, HV], plan=bak)
    for i, (r0, t0) in enumerate((((2.6, 7.3), (2.85, 8.45)), ((2.8, 7.35), (3.35, 8.45)),
                                  ((2.95, 7.3), (3.8, 8.3)), ((3.05, 7.2), (4.15, 8.0)), ((3.1, 7.05), (4.4, 7.6)),
                                  ((3.1, 6.85), (4.45, 7.05)), ((3.05, 6.6), (4.3, 6.4)))):
        fjaer(w, r0, t0, 0.32, [G, G, G, HV, HV] if i % 2 else [GL, G, G, HV, HV], plan=bak, spiss=1.0)
    dekk = [(1.05, 6.05), (1.95, 6.95), (2.85, 7.6), (3.3, 7.25), (3.15, 6.2), (2.2, 5.55), (1.4, 5.2), (1.05, 5.25)]
    flate(w, dekk, langs((0, 0, 7.6), (0, 0, 5.2), [HV, GL, G, G, GM]), plan=foran, tykk=0.6)
    f.hengsel = (1.15, -0.4, 5.6)
    f.punkter = dict(hode=(0, 0.9, 6.3), hale=(0, -3.0, 1.4), topp=(0, 0.3, 8.4))
    return f


# ------------------------------------------------------------------ Thunderbird

def tordensky(e, x, y, z, storrelse=1.0):
    """Liten tegneseriesky: en stor klump i midten og mindre på sidene, mørk under og lysere på toppen."""
    s = storrelse
    for (dx, dy, dz, r) in ((0.0, 0.0, 0.15, 0.55), (-0.5, 0.1, -0.05, 0.4), (0.5, -0.1, -0.05, 0.4),
                            (0.15, 0.35, -0.1, 0.35), (-0.15, -0.35, -0.1, 0.35)):
        e.ellipsoide((x + dx * s, y + dy * s, z + dz * s), (r * s, r * s, r * s * 0.85), 'c_tsky')
    e.ellipsoide((x, y, z + 0.55 * s), (0.75 * s, 0.75 * s, 0.4 * s), 'c_tskylys', modus='mal')


def tordenfugl():
    """Thunderbird (Mythic): stormørn — mørk indigo med gule lyn på vingene, lysende øyne,
    lynformet kam og en tordensky-ring som svever rundt."""
    IN, NA, BL, LY, LL = 'c_tindigo', 'c_tnatt', 'c_tbla', 'c_tlyn', 'c_tlynlys'
    f = Fugl()
    k = f.kropp
    for s in (-1, 1):
        k.ellipsoide((s * 0.85, 0.0, 2.3), (0.62, 0.7, 0.85), IN, p=2.2)
        bein(k, s * 1.05, (0.1, 1.6), (0.2, 0.3), 'c_tfot', r=0.3)
        klofot(k, s * 1.05, 0.2, 'c_tfot')
    k.ellipsoide((0, -0.35, 3.8), (1.45, 1.4, 1.85), IN, rot=(-10, 0, 0), p=2.3)
    k.ellipsoide((0, 0.6, 3.55), (1.05, 0.65, 1.3), BL, modus='mal')
    flate(k, lyn((0.0, 3.6), 2.1), LY, plan=(1.0, 0.0, 0.0), tykk=1.2, modus='mal')
    # hodet med lynkam og lysende øyne
    k.ellipsoide((0, 0.75, 5.95), (1.0, 1.05, 0.95), IN, p=2.3)
    flate(k, lyn((-0.2, 7.35), 2.1, vinkel=-20), LY, akser='yz', tykk=0.6)
    for s in (-1, 1):
        k.kjegle((s * 0.75, 0.5, 6.5), (s * 1.35, 0.2, 7.2), 0.22, 0.12, [IN, LY])     # små lynhorn
    rovnebb(k, 1.85, 5.95, 'c_tnebb', LL, voks='c_tfot', munn=NA)
    k.stempel_par((1.0, 1.15, 6.1), ['.c.', 'cwc', '.c.'], {'c': 'ojecyan', 'w': 'hvit'})
    # hale
    for n in (-2, -1, 0, 1, 2):
        k.kjegle((0, -1.5, 2.9), (n * 0.6, -2.9, 1.3 + abs(n) * 0.3), 0.4, 0.3, [IN, IN, NA, LY],
                 bredde=1.2, hoyde=0.5)
    # vingen (spredt): bred og flat ut til siden, lange svingfjær med gule tupper, og et stort gult lyn
    # som stikker ut foran på vingen
    w = f.vinge
    bak, foran, lynplan = ((-0.6 + 0.12 * 1.1, -0.12, 0.0), (-0.3 + 0.12 * 1.1, -0.12, 0.0),
                           (0.0 + 0.12 * 1.1, -0.12, 0.0))
    for i in range(7):
        x = 1.3 + i * 0.48
        zr = 5.0 + i * 0.2
        tupp = (min(4.45, x + 0.3 + i * 0.06), zr - 1.35 - i * 0.05)
        fjaer(w, (x, zr), tupp, 0.24, [IN, NA, NA, LY] if i % 2 else [NA, IN, IN, LY], plan=bak)
    dekk = [(1.05, 5.55), (2.3, 6.15), (3.5, 6.55), (4.45, 6.8), (4.45, 6.15), (3.4, 5.6), (2.2, 5.05),
            (1.05, 4.8)]
    flate(w, dekk, IN, plan=foran, tykk=0.6)
    flate(w, lyn((2.85, 5.35), 3.4, vinkel=100, bredde=0.6), LY, plan=lynplan, tykk=0.3)
    # ekstra: en lynring som svever rundt fuglen — fire små tordenskyer bundet sammen av sikksakk-lyn
    e = Voksler(S)
    sentrum = (0.0, -0.3, 2.5)
    radius, takker = 2.6, 28
    punkter = []
    for n in range(takker + 1):
        vk = 2 * math.pi * n / takker
        dz = 0.32 if n % 2 else -0.32
        punkter.append((radius * math.cos(vk), sentrum[1] + radius * math.sin(vk), sentrum[2] + dz))
    for n in range(takker):
        e.kjegle(punkter[n], punkter[n + 1], 0.2, 0.2, LY)
    for n in range(4):
        vk = 2 * math.pi * n / 4 + math.pi / 4
        tordensky(e, radius * math.cos(vk), sentrum[1] + radius * math.sin(vk), sentrum[2] + 0.1, 1.15)
    f.ekstra = e
    f.punkter['ekstra'] = sentrum
    f.hengsel = (1.15, -0.4, 5.0)
    f.punkter.update(hode=(0, 0.75, 5.95), hale=(0, -2.9, 1.3), topp=(0, -0.2, 8.4))
    return f


# ------------------------------------------------------------------ katalog
FUGLER = {
    'HaastsEagle': haastorn,
    'Moa': moa,
    'Pterodactyl': pterodaktyl,
    'IcePhoenix': isfonix,
    'Roc': rokk,
    'Thunderbird': tordenfugl,
}
