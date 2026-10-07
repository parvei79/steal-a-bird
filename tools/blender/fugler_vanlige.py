import math
import rbxlib as R
from fuglebygg import Fugl, S, OYE, SOT_OYE, bein, fot, Voksler, farge_trio, langs

# Vanlige fugler (Common og Uncommon) i blokkstil: Sparrow, Seagull, Chicken, Duck, Crow,
# Puffin, Flamingo, Penguin og Kiwi. Samme byggeklosser og regler som fugler.py:
# +Y er forover, +Z opp, høyre side er +X, origo = bakken midt under fuglen.
# Alle fargene her har prefikset a_ (de andre fuglegruppene bruker egne prefikser).

# ------------------------------------------------------------------ farger
_TRIO = dict(
    # felles for gruppen
    a_hvit='#f7f5ef', a_svart='#2a2932', a_oransje='#ff8f2e', a_gul='#ffd23c', a_rod='#e83b33',
    # Spurv
    a_spurvbrun='#a0703f', a_spurvmork='#5b3b24', a_spurvlys='#d9b98a', a_spurvbuk='#d9d5cb',
    a_spurvhette='#8e949e', a_spurvkastanje='#8f4a26', a_spurvnebb='#cfa766', a_spurvfot='#d8a083',
    # Måke
    a_maakegra='#a3b0c0', a_maakefot='#f3a3a6', a_frites='#fbe08c', a_fritesbrun='#e6a23c',
    # Høne
    a_honekrem='#dcd8cf',
    # And (stokkand)
    a_andgronn='#1f8a52', a_andglans='#2b9f86', a_andbryst='#7d4a33', a_andgra='#b4b6b9',
    a_andvinge='#8c8580', a_andspeil='#3f55d6',
    # Kråke
    a_krasvart='#23222c', a_kraglans='#2c3566', a_kralilla='#3a2d5c', a_kranebb='#3d3d48',
    # Lunde
    a_lunneansikt='#e4e4e6', a_lunnegra='#7d8a9a', a_lunneoransje='#f2652a',
    # Flamingo
    a_flamingo='#f490b4', a_flamingolys='#ffc6d9', a_flamingomork='#e65a8f',
    # Pingvin
    a_pingvinsvart='#262b38', a_pingvingul='#ffaa22', a_pingvinlys='#ffe7a0',
    # Kiwi
    a_kiwibrun='#8b6542', a_kiwilys='#b08a5c', a_kiwimork='#644630', a_kiwinebb='#e9d5a9',
)
for _n, _h in _TRIO.items():
    farge_trio(_n, _h)


# ------------------------------------------------------------------ hjelpere

def _k(v, x, y, z, farge):
    """Én kube: den som inneholder punktet. Gi kubesentre (±0.15, ±0.45 ...)."""
    v.celler[v._celle((x, y, z))] = farge


def _profil(v, xs, y0, z0, rader, farger):
    """Tegn en form sett fra siden som pikselkunst, og trekk den ut på tvers.
    rader: øverste rad først; kolonnene går forover (+y) fra kubesenteret y0. z0 = senteret i nederste rad.
    xs: kubesentrene i x (f.eks. (-0.15, 0.15) for et nebb som er to kuber bredt). '.' = hopp over."""
    n = len(rader)
    for r, rad in enumerate(rader):
        z = z0 + (n - 1 - r) * S
        for c, tegn in enumerate(rad):
            if tegn in '. ':
                continue
            for x in xs:
                _k(v, x, y0 + c * S, z, farger[tegn])


def _svommefot(v, x, y, farge, bredde=1, lengde=2):
    """Svømmefot på bakken: hæl og ankel i (x, y), så en vifte forover som er 2*bredde+1 kuber bred."""
    i0, j0, k0 = v._celle((x, y, 0.15))
    v.celler[(i0, j0 - 1, k0)] = farge
    v.celler[(i0, j0, k0)] = farge
    for dj in range(1, lengde + 1):
        for di in range(-bredde, bredde + 1):
            v.celler[(i0 + di, j0 + dj, k0)] = farge


def _strek(v, xs, punkter, farge):
    """Tynn strek gjennom punktene (y, z), én kube tykk i høyden — lange nebb, bøyde bein, halser.
    Kubene henger alltid sammen side mot side (ingen diagonale hopp). farge kan være en liste
    (overgang langs streken)."""
    if isinstance(farge, (list, tuple)):
        liste = list(farge)

        def ff(t):
            return liste[min(len(liste) - 1, int(t * len(liste)))]
    else:
        def ff(t):
            return farge
    lengder = [math.hypot(b[0] - a[0], b[1] - a[1]) for a, b in zip(punkter, punkter[1:])]
    total = sum(lengder) or 1.0
    gatt = 0.0
    forrige = None
    for (a, b), lg in zip(zip(punkter, punkter[1:]), lengder):
        n = max(1, int(lg / 0.04))
        for i in range(n + 1):
            t = i / n
            y, z = a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t
            _, j, kk = v._celle((0, y, z))
            celler = [(j, kk)]
            if forrige and forrige[0] != j and forrige[1] != kk:
                celler.insert(0, (j, forrige[1]))          # fyll hjørnet
            for (jj, kz) in celler:
                for x in xs:
                    v.celler[(v._celle((x, 0, 0))[0], jj, kz)] = ff((gatt + lg * t) / total)
            forrige = (j, kk)
        gatt += lg


def _hash(i, j, k, fro):
    n = (i * 73856093) ^ (j * 19349663) ^ (k * 83492791) ^ (fro * 2654435761)
    n &= 0xffffffff
    n ^= n >> 15
    n = (n * 2246822519) & 0xffffffff
    n ^= n >> 13
    n = (n * 3266489917) & 0xffffffff
    n ^= n >> 16
    return (n & 0xffffff) / 0xffffff


def _lodden(v, andel, farger, bare, fro=3):
    """Dun som stritter: legg en kube utenpå noen av overflatekubene (likt på begge sider).
    farger: liste med farger som velges tilfeldig for dunet. bare: fargene dunet kan vokse fra."""
    retninger = [(1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (1, 0, 0)]       # utover til siden teller dobbelt
    nye = {}
    for (i, j, k), f in list(v.celler.items()):
        if f not in bare or i < 0:
            continue
        if _hash(i, j, k, fro) >= andel:
            continue
        d = retninger[int(_hash(i, j, k, fro + 1) * len(retninger)) % len(retninger)]
        c = (i + d[0], j + d[1], k + d[2])
        if c in v.celler or c in nye:
            continue
        nye[c] = farger[int(_hash(i, j, k, fro + 2) * len(farger)) % len(farger)]
    for (i, j, k), f in nye.items():
        v.celler[(i, j, k)] = f
        v.celler[(-1 - i, j, k)] = f


def _uten_flimmer(f):
    """Kroppen og vingene blir egne deler i Roblox. Ligger en vingekube i samme kube som kroppen, og begge viser
    en flate i samme plan med ulik farge, flimrer det (z-fighting). Slike vingekuber tas bort (sjekkes på begge
    sider, for prikkene på kroppen er ikke speilsymmetriske)."""
    k, w = f.kropp.celler, f.vinge.celler
    nabo = [(1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1)]

    def konflikt(c, farge, vinge):
        fk = k.get(c)
        if fk is None or fk == farge:
            return False
        return any((c[0] + d[0], c[1] + d[1], c[2] + d[2]) not in vinge and
                   (c[0] + d[0], c[1] + d[1], c[2] + d[2]) not in k for d in nabo)
    while True:
        speil = {(-1 - i, j, kk) for (i, j, kk) in w}
        bort = [c for c, fw in w.items()
                if konflikt(c, fw, w) or konflikt((-1 - c[0], c[1], c[2]), fw, speil)]
        if not bort:
            return f
        for c in bort:
            del w[c]


# ------------------------------------------------------------------ fuglene

def spurv():
    """Sparrow (Common): liten og rund, brun stripete rygg, grå hette, svart smekke, kjeglenebb."""
    f = Fugl()
    k = f.kropp
    for s in (-1, 1):
        bein(k, s * 0.75, (-0.15, 1.0), (-0.1, 0.3), 'a_spurvfot')
        fot(k, s * 0.75, -0.1, 'a_spurvfot', form='T')
    k.ellipsoide((0, -0.2, 1.45), (0.92, 1.05, 0.8), 'a_spurvbrun', rot=(-10, 0, 0), p=2.3)
    k.ellipsoide((0, 0.45, 1.15), (0.8, 0.6, 0.62), 'a_spurvbuk', modus='mal')         # lys buk
    for x, farge in ((0.45, 'a_spurvmork'), (0.15, 'a_spurvlys')):                   # stripete rygg
        for xx in (x, -x):
            k.boks((xx - 0.1, -1.3, 1.9), (xx + 0.1, 0.2, 2.6), farge, modus='mal')
    # stort rundt hode: lyse kinn, grå hette og et kastanjebrunt bånd bak øyet
    k.ellipsoide((0, 0.4, 2.5), (0.86, 0.82, 0.78), 'a_spurvbuk', p=2.2)
    k.ellipsoide((0, 0.25, 3.1), (0.78, 0.8, 0.42), 'a_spurvhette', modus='mal')
    k.ellipsoide((0, -0.1, 2.65), (1.4, 0.55, 0.4), 'a_spurvkastanje', modus='mal')
    k.ellipsoide((0, 0.95, 1.8), (0.52, 0.48, 0.44), 'a_svart', modus='mal')           # svart smekke
    _profil(k, (-0.15, 0.15), 1.35, 2.25, ['n.', 'nn'], {'n': 'a_spurvnebb'})        # kort kjeglenebb
    k.stempel_par((0.75, 0.45, 2.85), SOT_OYE, OYE)
    k.kjegle((0, -1.0, 1.55), (0, -1.85, 2.05), 0.38, 0.42, 'a_spurvmork', bredde=1.3, hoyde=0.5)
    w = f.vinge
    w.ellipsoide((0.98, -0.35, 1.5), (0.3, 0.88, 0.58), 'a_spurvbrun', rot=(-10, 0, 0))
    w.boks((0.6, -1.4, 0.8), (1.5, -0.6, 1.55), 'a_spurvmork', modus='mal')            # mørke svingfjær
    w.boks((0.6, -0.55, 1.6), (1.5, 0.25, 1.7), 'a_hvit', modus='mal')                  # hvitt vingebånd
    f.hengsel = (0.88, 0.15, 1.95)
    f.punkter = dict(hode=(0, 0.4, 2.5), hale=(0, -1.85, 2.05), topp=(0, 0.4, 3.3))
    return _uten_flimmer(f)


def maake():
    """Seagull (Common): hvit, grå vinger med svarte tupper, gult nebb med rød flekk — og en pommes frites."""
    f = Fugl()
    k = f.kropp
    for s in (-1, 1):
        x = s * 0.75
        bein(k, x, (-0.2, 1.3), (-0.15, 0.3), 'a_maakefot')
        _svommefot(k, x, -0.15, 'a_maakefot')
    k.ellipsoide((0, -0.3, 1.95), (1.0, 1.35, 0.95), 'a_hvit', rot=(-10, 0, 0), p=2.3)
    k.ellipsoide((0, -0.65, 2.7), (0.8, 0.95, 0.3), 'a_maakegra', modus='mal')        # grå rygg
    k.ellipsoide((0, 0.5, 2.6), (0.72, 0.62, 0.62), 'a_hvit')                         # hals
    k.ellipsoide((0, 0.75, 3.25), (0.88, 0.82, 0.76), 'a_hvit', p=2.2)               # hode
    _profil(k, (-0.15, 0.15), 1.65, 2.85, ['gggg', 'ggfr'], {'g': 'a_gul', 'r': 'a_rod', 'f': 'a_frites'})
    for x in (-0.75, -0.45, -0.15, 0.15, 0.45, 0.75, 1.05, 1.35, 1.65):              # pommes frites
        _k(k, x, 2.25, 2.85, 'a_frites')
    for x in (-0.75, 1.65):
        _k(k, x, 2.25, 2.85, 'a_fritesbrun')
    # frekt blikk: skrått, grått bryn over et gult øye
    k.stempel_par((0.75, 0.75, 3.45), ['m..', '.mm', '.yk', '.yy'],
                  {'m': 'a_spurvhette', 'y': 'ojegul', 'k': 'svart'})
    k.kjegle((0, -1.35, 2.05), (0, -2.35, 1.9), 0.42, 0.4, 'a_hvit', bredde=1.4, hoyde=0.5)
    w = f.vinge
    w.ellipsoide((1.0, -0.55, 2.2), (0.3, 1.2, 0.58), 'a_maakegra', rot=(-10, 0, 0))
    w.boks((0.6, -1.8, 1.5), (1.5, 0.7, 1.7), 'a_hvit', modus='mal')                  # hvit bakkant
    w.kjegle((0.75, -1.45, 2.3), (0.75, -2.75, 2.1), 0.42, 0.18, 'a_svart', bredde=0.6)
    for (y, z) in ((-1.95, 2.25), (-2.55, 2.25)):                                       # hvite prikker
        _k(w, 0.75, y, z, 'a_hvit')
    f.hengsel = (0.9, 0.3, 2.55)
    f.punkter = dict(hode=(0, 0.75, 3.25), hale=(0, -2.35, 1.9), topp=(0, 0.7, 3.9))
    return _uten_flimmer(f)


def hone():
    """Chicken (Common): lubben og hvit, stor rød kam og hakelapp, gult nebb, oransje bein."""
    f = Fugl()
    k = f.kropp
    for s in (-1, 1):
        x = s * 0.75
        bein(k, x, (-0.15, 1.0), (-0.1, 0.3), 'a_oransje')
        fot(k, x, -0.1, 'a_oransje', form='T')
    k.ellipsoide((0, -0.25, 1.65), (1.2, 1.3, 1.05), 'a_hvit', rot=(-10, 0, 0), p=2.4)
    k.ellipsoide((0, 0.45, 1.6), (1.05, 0.9, 0.95), 'a_hvit', p=2.2)                  # fyldig bryst
    k.ellipsoide((0, 0.6, 2.85), (0.82, 0.8, 0.76), 'a_hvit', p=2.2)                  # hode
    k.prikker([('a_honekrem', 0.12)], bare=['a_hvit'], fro=9)                           # litt fjærtekstur
    rod = {'r': 'a_rod', 'y': 'a_gul'}
    _profil(k, (-0.15, 0.15), 0.15, 3.45, ['.r.r.', 'rrrrr', 'rrrrr', 'r...r'], rod)  # kam
    _profil(k, (-0.15, 0.15), 1.65, 1.95, ['yy', 'y.', 'r.', 'r.'], rod)             # nebb og hakelapp
    k.stempel_par((0.75, 0.75, 3.15), SOT_OYE, OYE)
    for (x, y, z) in ((0.0, -1.75, 3.35), (0.6, -1.6, 3.05), (-0.6, -1.6, 3.05)):     # halefjær
        k.kjegle((x * 0.3, -1.15, 2.4), (x, y, z), 0.4, 0.2, ['a_hvit', 'a_hvit', 'a_honekrem', 'a_honekrem'])
    w = f.vinge
    w.ellipsoide((1.12, -0.35, 1.75), (0.3, 0.9, 0.68), 'a_hvit', rot=(-10, 0, 0))
    w.boks((0.7, -1.4, 0.9), (1.6, -0.75, 1.8), 'a_honekrem', modus='mal')
    f.hengsel = (1.05, 0.15, 2.25)
    f.punkter = dict(hode=(0, 0.6, 2.85), hale=(0, -1.75, 3.35), topp=(0, 0.75, 4.5))
    return _uten_flimmer(f)


def and_():
    """Duck (Common): stokkand — grønt hode, hvit halsring, brunt bryst, grå kropp, krøll på halen."""
    f = Fugl()
    k = f.kropp
    for s in (-1, 1):
        x = s * 0.75
        bein(k, x, (-0.15, 0.9), (-0.1, 0.3), 'a_oransje')
        _svommefot(k, x, -0.1, 'a_oransje')
    k.ellipsoide((0, -0.3, 1.6), (1.1, 1.55, 0.88), 'a_andgra', rot=(-5, 0, 0), p=2.3)
    k.ellipsoide((0, 0.85, 1.75), (1.05, 0.65, 0.85), 'a_andbryst', modus='mal')      # brunt bryst
    k.ellipsoide((0, -1.65, 1.75), (1.05, 0.5, 0.8), 'a_svart', modus='mal')          # svart bakpart
    k.kjegle((0, -1.6, 1.9), (0, -2.3, 2.05), 0.36, 0.3, 'a_hvit', bredde=1.4, hoyde=0.5)
    _profil(k, (-0.15, 0.15), -1.65, 2.25, ['kk', 'k.', 'k.'], {'k': 'a_svart'})     # krøllen
    k.ellipsoide((0, 0.75, 2.5), (0.62, 0.55, 0.55), 'a_andgronn')                    # hals
    k.ellipsoide((0, 0.9, 3.15), (0.82, 0.82, 0.74), 'a_andgronn', p=2.2)             # hode
    k.prikker([('a_andglans', 0.3)], bare=['a_andgronn'])
    k.ellipsoide((0, 0.8, 2.55), (0.8, 0.65, 0.12), 'a_hvit', modus='mal')            # hvit halsring
    nebb = {'n': 'a_gul', 'k': 'a_svart'}
    _profil(k, (-0.15, 0.15), 1.95, 2.85, ['n...', 'nnnk'], nebb)                    # flatt, bredt nebb
    _profil(k, (-0.45, 0.45), 1.95, 2.85, ['n..', 'nnn'], nebb)
    k.stempel_par((0.75, 1.05, 3.45), SOT_OYE, OYE)
    w = f.vinge
    w.ellipsoide((1.22, -0.5, 1.85), (0.3, 1.15, 0.6), 'a_andvinge', rot=(-5, 0, 0))
    w.boks((0.6, -0.8, 1.3), (1.5, -0.4, 1.7), 'a_andspeil', modus='mal')             # blått speil
    for y in (-1.05, -0.15):
        w.boks((0.6, y - 0.05, 1.3), (1.5, y + 0.05, 1.7), 'a_hvit', modus='mal')
    f.hengsel = (1.05, 0.3, 2.25)
    f.punkter = dict(hode=(0, 0.9, 3.15), hale=(0, -2.3, 2.05), topp=(0, 0.9, 3.9))
    return _uten_flimmer(f)


def kraake():
    """Crow (Common): svart med blålilla glans, kraftig nebb og et lurt blikk."""
    f = Fugl()
    k = f.kropp
    for s in (-1, 1):
        x = s * 0.75
        bein(k, x, (-0.2, 1.2), (-0.1, 0.3), 'a_kranebb')
        fot(k, x, -0.1, 'a_kranebb', form='T', klo='klo')
    k.ellipsoide((0, -0.3, 1.95), (1.0, 1.3, 0.95), 'a_krasvart', rot=(-14, 0, 0), p=2.3)
    k.ellipsoide((0, 0.6, 3.15), (0.9, 0.85, 0.78), 'a_krasvart', p=2.2)               # hode
    k.kjegle((0, -1.3, 1.75), (0, -2.45, 1.3), 0.38, 0.52, 'a_krasvart', bredde=1.45, hoyde=0.45)
    k.prikker([('a_kraglans', 0.16), ('a_kralilla', 0.08)], bare=['a_krasvart'], fro=5)
    _profil(k, (-0.15, 0.15), 1.65, 2.85, ['bbb.', 'bbbb'], {'b': 'a_kranebb'})
    k.stempel_par((0.75, 0.75, 3.45), ['yk', 'yy'], {'y': 'ojegul', 'k': 'svart'})     # lurt, gyllent øye
    w = f.vinge
    w.ellipsoide((1.0, -0.55, 2.0), (0.3, 1.2, 0.68), 'a_krasvart', rot=(-14, 0, 0))
    w.kjegle((0.75, -1.5, 1.9), (0.75, -2.4, 1.5), 0.36, 0.16, 'a_krasvart', bredde=0.6)
    w.prikker([('a_kraglans', 0.18), ('a_kralilla', 0.08)], bare=['a_krasvart'], fro=5)
    f.hengsel = (0.92, 0.25, 2.55)
    f.punkter = dict(hode=(0, 0.6, 3.15), hale=(0, -2.45, 1.3), topp=(0, 0.6, 3.9))
    return _uten_flimmer(f)


def lunde():
    """Puffin (Uncommon): smoking (svart rygg, hvitt bryst), hvitt ansikt og et kjempenebb med striper."""
    f = Fugl()
    k = f.kropp
    for s in (-1, 1):
        x = s * 0.75
        bein(k, x, (-0.1, 1.0), (0.0, 0.3), 'a_oransje')
        _svommefot(k, x, 0.0, 'a_oransje')
    k.ellipsoide((0, -0.15, 1.95), (1.1, 1.05, 1.3), 'a_svart', rot=(-8, 0, 0), p=2.3)
    k.ellipsoide((0, 0.55, 1.75), (0.95, 0.62, 1.05), 'a_hvit', modus='mal')          # hvitt bryst
    k.ellipsoide((0, 0.3, 3.4), (0.92, 0.9, 0.85), 'a_svart', p=2.0)                 # hode
    k.ellipsoide((0, 0.4, 3.35), (1.6, 0.9, 0.62), 'a_lunneansikt', modus='mal')     # hvitt ansikt
    nebb = {'g': 'a_lunnegra', 'y': 'a_gul', 'o': 'a_lunneoransje', 'r': 'a_rod'}
    _profil(k, (-0.15, 0.15), 1.35, 2.85, ['gyo..', 'gyoo.', 'gyoor', 'gyor.'], nebb)
    k.stempel_par((0.75, 0.15, 3.45), ['.g', 'wk', 'kk'], {'g': 'a_lunnegra', 'w': 'hvit', 'k': 'svart'})
    k.kjegle((0, -1.0, 1.25), (0, -1.55, 0.9), 0.35, 0.3, 'a_svart', bredde=1.4, hoyde=0.5)
    w = f.vinge
    w.ellipsoide((1.1, -0.35, 2.0), (0.3, 0.85, 0.75), 'a_svart', rot=(-8, 0, 0))
    f.hengsel = (1.0, 0.15, 2.65)
    f.punkter = dict(hode=(0, 0.3, 3.4), hale=(0, -1.55, 0.9), topp=(0, 0.3, 4.2))
    return _uten_flimmer(f)


def flamingo():
    """Flamingo (Uncommon): rosa, lang S-hals, står på ett bein, bøyd nebb med svart tupp."""
    f = Fugl()
    k = f.kropp
    B = 'a_flamingomork'
    for z in (0.45, 0.75, 1.05, 1.35, 1.65, 1.95):                                     # ståbeinet
        _k(k, 0.15, -0.15, z, B)
    _svommefot(k, 0.15, -0.15, B)
    # det andre beinet er bøyd opp som et «4»-tall: ned til kneet foran, så bakover med foten
    _profil(k, (-0.45,), -1.05, 1.05, ['.....b', '.....b', 'bbbbbb', 'b.....'], {'b': B})
    k.ellipsoide((0, -0.25, 2.55), (0.95, 1.25, 0.68), 'a_flamingo', rot=(-6, 0, 0), p=2.3)
    k.ellipsoide((0, 0.1, 2.3), (1.2, 0.95, 0.22), 'a_flamingolys', modus='mal')       # lys buk
    k.kjegle((0, -1.25, 2.75), (0, -1.9, 2.65), 0.35, 0.15, 'a_flamingomork', bredde=1.4, hoyde=0.6)
    # S-hals: fram nederst, bakover på midten, fram igjen inn i hodet
    _profil(k, (-0.15, 0.15), 0.45, 3.15, ['pp..', 'p...', 'pp..', '.ppp', '..pp'], {'p': 'a_flamingo'})
    k.ellipsoide((0, 1.05, 4.95), (0.66, 0.64, 0.52), 'a_flamingo', p=2.2)            # hode
    _profil(k, (-0.15, 0.15), 1.65, 4.05, ['pppk', 'pp.k', '...k'], {'p': 'a_flamingolys', 'k': 'a_svart'})
    k.stempel_par((0.45, 0.75, 4.95), SOT_OYE, OYE)
    w = f.vinge
    w.ellipsoide((0.92, -0.4, 2.6), (0.3, 1.0, 0.58), 'a_flamingo', rot=(-6, 0, 0))
    w.ellipsoide((0.92, -0.1, 2.85), (0.35, 0.65, 0.3), 'a_flamingomork', modus='mal')
    w.boks((0.5, -1.6, 1.9), (1.5, -0.95, 2.4), 'a_svart', modus='mal')
    f.hengsel = (0.85, 0.25, 3.0)
    f.punkter = dict(hode=(0, 1.05, 4.95), hale=(0, -1.9, 2.65), topp=(0, 1.0, 5.4))
    return _uten_flimmer(f)


def pingvin():
    """Penguin (Uncommon): keiserpingvin — svart rygg, hvit mage, gul halsflekk, luffer og svømmeføtter."""
    f = Fugl()
    k = f.kropp
    P = 'a_pingvinsvart'
    for s in (-1, 1):
        _svommefot(k, s * 0.75, 0.45, 'a_kranebb')
    k.ellipsoide((0, 0.0, 1.65), (1.3, 1.15, 1.4), P, p=2.2)                          # nedre kropp
    k.ellipsoide((0, 0.05, 2.8), (1.02, 0.95, 1.0), P, p=2.2)                         # skuldre
    k.ellipsoide((0, 0.15, 3.75), (0.9, 0.88, 0.8), P, p=2.2)                         # hode
    k.ellipsoide((0, 0.8, 1.95), (1.05, 0.6, 1.5), 'a_hvit', modus='mal')             # hvit mage
    k.ellipsoide((0, 0.95, 2.95), (0.72, 0.45, 0.45), 'a_pingvinlys', modus='mal')    # lysegult bryst
    k.ellipsoide((0, 0.2, 3.1), (1.6, 0.55, 0.38), 'a_pingvingul', modus='mal')       # gule øreflekker
    _profil(k, (-0.15, 0.15), 1.05, 3.45, ['kkk', 'oo.'], {'k': P, 'o': 'a_oransje'})
    k.stempel_par((0.75, 0.15, 3.75), ['www', 'wkk', 'wkk'], OYE)                      # hvitt øye på svart hode
    k.kjegle((0, -0.85, 0.75), (0, -1.45, 0.45), 0.35, 0.25, P, bredde=1.3, hoyde=0.6)
    w = f.vinge
    w.ellipsoide((1.35, 0.0, 2.35), (0.2, 0.5, 1.0), P)                               # luffe
    f.hengsel = (1.25, 0.0, 3.15)
    f.punkter = dict(hode=(0, 0.15, 3.75), hale=(0, -1.45, 0.45), topp=(0, 0.15, 4.5))
    return _uten_flimmer(f)


def kiwi():
    """Kiwi (Uncommon): rund brun dunball, bitte små vingestumper og et kjempelangt tynt nebb."""
    f = Fugl()
    k = f.kropp
    for s in (-1, 1):
        bein(k, s * 0.6, (-0.3, 1.2), (-0.3, 0.3), 'a_kiwinebb', r=0.3)
        fot(k, s * 0.75, -0.15, 'a_kiwinebb', form='T', klo='klo')
    k.ellipsoide((0, -0.25, 2.45), (1.55, 1.7, 1.6), 'a_kiwibrun', p=2.1)
    k.ellipsoide((0, 1.15, 3.3), (0.82, 0.82, 0.8), 'a_kiwibrun', p=2.1)             # hode
    k.prikker([('a_kiwilys', 0.25), ('a_kiwimork', 0.22)], bare=['a_kiwibrun'])
    _lodden(k, 0.07, ['a_kiwibrun', 'a_kiwilys', 'a_kiwimork'], ['a_kiwibrun', 'a_kiwilys', 'a_kiwimork'])
    k.ellipsoide((0, 1.7, 3.1), (0.7, 0.35, 0.45), 'a_kiwilys', modus='mal')          # lysere ansikt
    _strek(k, (-0.15, 0.15), [(1.95, 3.1), (2.4, 2.8), (2.75, 2.05), (2.95, 1.25), (3.05, 0.75)],
           'a_kiwinebb')
    for (x, y, z) in ((0.45, 1.95, 3.15), (0.75, 2.25, 3.15), (0.45, 1.95, 2.85), (0.75, 2.25, 2.85)):
        _k(k, x, y, z, 'a_kiwimork')                                                    # værhår
        _k(k, -x, y, z, 'a_kiwimork')
    k.stempel_par((0.75, 1.35, 3.45), SOT_OYE, OYE)
    w = f.vinge
    w.ellipsoide((1.62, 0.15, 2.45), (0.2, 0.35, 0.3), 'a_kiwimork')
    f.hengsel = (1.5, 0.15, 2.6)
    f.punkter = dict(hode=(0, 1.15, 3.3), hale=(0, -1.95, 2.45), topp=(0, 0.6, 4.2))
    return _uten_flimmer(f)


# ------------------------------------------------------------------ katalog
FUGLER = {
    'Sparrow': spurv,
    'Seagull': maake,
    'Chicken': hone,
    'Duck': and_,
    'Crow': kraake,
    'Puffin': lunde,
    'Flamingo': flamingo,
    'Penguin': pingvin,
    'Kiwi': kiwi,
}
