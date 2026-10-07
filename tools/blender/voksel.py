"""
voksel — blokkfigurer (som i bildet Sander viste): en figur beskrives som enkle former
(ellipsoider, bokser, kjegler, ringer) som «males» inn i et 3D-rutenett av kuber. Bare de synlige
sidene blir mesh, og like nabosider slås sammen (grådig meshing), så selv store figurer holder seg på
noen tusen trekanter. Hver kube får en litt tilfeldig nyanse av fargen sin, så blokkene synes — det gir
den chunky «kube-stilen».

Bruk (etter at fargene er registrert med farge_trio):

    v = Voksler(storrelse=0.3)
    v.ellipsoide((0, 0, 3), (1.6, 2.0, 1.8), 'gul', rot=(-15, 0, 0), p=2.3)
    v.kjegle((0, 2, 3.2), (0, 3.2, 3.0), 0.5, 0.1, ['gul', 'oransje', 'rod'])   # fargeovergang langs kjeglen
    v.ellipsoide((0, 1, 2.5), (1, 0.6, 1), 'lys', modus='mal')                  # mal om eksisterende kuber
    v.stempel_par((0.8, 1.2, 3.4), ['wk', 'kk'], {'w': 'hvit', 'k': 'svart'})   # øyne på begge sider
    v.lag()            # legger mesh-delen inn i modellen som bygges (R.ny_modell / R.ferdig_modell)

Rutenettet er symmetrisk om x = 0 (kube i og -1-i er speilbilder), så former med sentrum på x = 0 blir
symmetriske. Kubesentrene ligger på (n + 0.5) * storrelse — tenk i dem når du plasserer tynne ting:
med 0.3 er sentrene ±0.15, ±0.45, ±0.75 ... Et bein på x = 0.45 blir nøyaktig én kube tykt.

Farger: en farge «navn» med nyanser må finnes som navn_1, navn_2, navn_3 i paletten (lys, middels, mørk).
Bruk farge_trio() for å registrere dem. Farger uten nyanser (registrert med R.farge) brukes som de er.
"""
import math

import bmesh
import bpy
from mathutils import Euler, Vector

import rbxlib as R

# (akse, fortegn) for overflatenormalen, og (U, V) = mønsterets kolonne- og radretning sett utenfra.
# På sidene (±x) peker kolonnene alltid forover (+y), så samme mønster blir speilvendt på venstre side.
_NORMAL = {'+x': (0, 1), '-x': (0, -1), '+y': (1, 1), '-y': (1, -1), '+z': (2, 1), '-z': (2, -1)}
_UV = {'+x': ((0, 1, 0), (0, 0, 1)), '-x': ((0, 1, 0), (0, 0, 1)),
       '+y': ((-1, 0, 0), (0, 0, 1)), '-y': ((1, 0, 0), (0, 0, 1)),
       '+z': ((1, 0, 0), (0, 1, 0)), '-z': ((1, 0, 0), (0, 1, 0))}


def farge_trio(navn, hexkode, spenn=0.12):
    """Registrer navn_1 (lys), navn_2 (som gitt), navn_3 (mørk)."""
    h = hexkode.lstrip('#')
    r, g, b = [int(h[i:i + 2], 16) for i in (0, 2, 4)]

    def skaler(f):
        return '#%02x%02x%02x' % tuple(max(0, min(255, int(round(c * f)))) for c in (r, g, b))
    R.farge(navn + '_1', skaler(1 + spenn))
    R.farge(navn + '_2', hexkode)
    R.farge(navn + '_3', skaler(1 - spenn))


def _hash(i, j, k, fro=0):
    n = (i * 73856093) ^ (j * 19349663) ^ (k * 83492791) ^ (fro * 2654435761)
    n &= 0xffffffff
    n ^= n >> 15
    n = (n * 2246822519) & 0xffffffff
    n ^= n >> 13
    n = (n * 3266489917) & 0xffffffff
    n ^= n >> 16
    return (n & 0xffffff) / 0xffffff


def _rot(rot):
    """Rotasjon i grader (x, y, z) -> 3x3-matrise (eller None)."""
    if not rot or not any(rot):
        return None
    return Euler([math.radians(a) for a in rot], 'XYZ').to_matrix()


def _fargefunk(farge):
    """str, liste (overgang etter t fra 0 til 1) eller funksjon(p, t) -> str."""
    if callable(farge):
        return farge
    if isinstance(farge, (list, tuple)):
        liste = list(farge)
        return lambda p, t: liste[min(len(liste) - 1, max(0, int(t * len(liste))))]
    return lambda p, t: farge


def langs(fra, til, farger):
    """Fargeovergang langs en retning (fra -> til), uavhengig av formen. Brukes som farge=langs(...)."""
    a, b = Vector(fra), Vector(til)
    d = b - a
    l2 = max(d.length_squared, 1e-9)
    liste = list(farger)

    def f(p, _t):
        t = (p - a).dot(d) / l2
        return liste[min(len(liste) - 1, max(0, int(t * len(liste))))]
    return f


class Voksler:
    def __init__(self, storrelse=0.3, monster=True):
        self.s = storrelse
        self.celler = {}       # (i, j, k) -> farge
        self.monster = monster

    # ------------------------------------------------------------ rutenett

    def _celle(self, p):
        return tuple(int(math.floor(c / self.s + 1e-9)) for c in p)

    def _midt(self, c):
        return Vector(((c[0] + 0.5) * self.s, (c[1] + 0.5) * self.s, (c[2] + 0.5) * self.s))

    def _fyll(self, lo, hi, test, farge, modus='fyll'):
        """test(p) -> None (utenfor) eller t (tall, brukes til fargeoverganger).
        modus: 'fyll' (legg til), 'mal' (bare farg kuber som finnes), 'fjern' (ta bort kuber)."""
        ff = _fargefunk(farge)
        a, b = self._celle(lo), self._celle(hi)
        for i in range(a[0] - 1, b[0] + 2):
            for j in range(a[1] - 1, b[1] + 2):
                for k in range(a[2] - 1, b[2] + 2):
                    p = self._midt((i, j, k))
                    t = test(p)
                    if t is None:
                        continue
                    c = (i, j, k)
                    if modus == 'fjern':
                        self.celler.pop(c, None)
                        continue
                    if modus == 'mal' and c not in self.celler:
                        continue
                    f = ff(p, t)
                    if f:
                        self.celler[c] = f

    # ------------------------------------------------------------ former

    def ellipsoide(self, sentrum, radier, farge, rot=None, p=2.0, modus='fyll'):
        """p > 2 gir en «firkantet ball» (superellipsoide) — fyldigere og mer blokkete."""
        c, r = Vector(sentrum), Vector(radier)
        M = _rot(rot)
        Mi = M.transposed() if M else None
        if M:
            rm = max(r)
            lo, hi = c - Vector((rm, rm, rm)), c + Vector((rm, rm, rm))
        else:
            lo, hi = c - r, c + r

        def test(q):
            d = q - c
            if Mi:
                d = Mi @ d
            v = sum(abs(d[n] / r[n]) ** p for n in range(3))
            return v ** (1 / p) if v <= 1 else None
        self._fyll(lo, hi, test, farge, modus)

    def boks(self, lo, hi, farge, modus='fyll'):
        lo, hi = Vector(lo), Vector(hi)
        self._fyll(lo, hi, lambda q: 0.0 if all(lo[n] <= q[n] <= hi[n] for n in range(3)) else None, farge, modus)

    def kjegle(self, a, b, r1, r2, farge, modus='fyll', bredde=1.0, hoyde=1.0):
        """Avkortet kjegle fra a (radius r1) til b (radius r2) — nebb, bein, haler, fjær, flammer.
        bredde/hoyde skalerer tverrsnittet sideveis/oppover (f.eks. et høyt, smalt nebb).
        En fargeliste gir overgang fra a til b."""
        a, b = Vector(a), Vector(b)
        d = b - a
        l2 = d.length_squared
        w = d.normalized()
        u = w.cross(Vector((0, 0, 1)))
        u = u.normalized() if u.length > 1e-6 else Vector((1, 0, 0))
        v = u.cross(w)
        rm = max(r1, r2) * max(bredde, hoyde, 1.0)
        lo = Vector([min(a[n], b[n]) - rm for n in range(3)])
        hi = Vector([max(a[n], b[n]) + rm for n in range(3)])

        def test(p):
            q = p - a
            t = q.dot(d) / l2
            if t < 0 or t > 1:
                return None
            r = r1 + (r2 - r1) * t
            rad = q - d * t
            if (rad.dot(u) / bredde) ** 2 + (rad.dot(v) / hoyde) ** 2 <= r * r:
                return t
            return None
        self._fyll(lo, hi, test, farge, modus)

    def plate(self, sentrum, normal, radius, tykkelse, farge, modus='fyll'):
        """Flat skive (kammer, fjærvifter)."""
        c, n = Vector(sentrum), Vector(normal).normalized()
        r = Vector((radius, radius, radius))

        def test(p):
            v = p - c
            avst = v.dot(n)
            rad = (v - n * avst).length
            return rad / radius if abs(avst) <= tykkelse / 2 and rad <= radius else None
        self._fyll(c - r, c + r, test, farge, modus)

    def ring(self, sentrum, normal, radius, bredde, tykkelse, farge, modus='fyll'):
        """Flat ring (planetring, glorie). t = vinkelen rundt ringen (0..1), for mønstre."""
        c, n = Vector(sentrum), Vector(normal).normalized()
        u = n.cross(Vector((0, 0, 1)) if abs(n.z) < 0.9 else Vector((1, 0, 0))).normalized()
        v = n.cross(u)
        rr = radius + bredde
        lo, hi = c - Vector((rr, rr, rr)), c + Vector((rr, rr, rr))

        def test(p):
            d = p - c
            h = d.dot(n)
            pl = d - n * h
            if abs(h) <= tykkelse / 2 and abs(pl.length - radius) <= bredde / 2:
                return (math.atan2(pl.dot(v), pl.dot(u)) / (2 * math.pi)) % 1.0
            return None
        self._fyll(lo, hi, test, farge, modus)

    # ------------------------------------------------------------ maling

    def stempel(self, punkt, normal, monster, farger, dybde=1):
        """Mal et lite pikselmønster (øyne, flekker) rett på overflaten, sett fra retningen `normal`
        ('+x', '-x', '+y', ...). Mønsteret er en liste med rader (øverst først); '.' hoppes over.
        Hvert tegn finner den ytterste kuben i sin kolonne og farges med farger[tegn]."""
        akse, fortegn = _NORMAL[normal]
        U, V = _UV[normal]
        base = self._celle(punkt)
        rader = len(monster)
        kol = max(len(r) for r in monster)
        for r, rad in enumerate(monster):
            for c, tegn in enumerate(rad):
                if tegn in '. ':
                    continue
                du, dv = c - (kol - 1) // 2, (rader - 1) // 2 - r
                celle = [base[m] + U[m] * du + V[m] * dv for m in range(3)]
                celle[akse] += fortegn * 12          # start godt utenfor figuren
                funnet = 0
                for _ in range(40):
                    t = tuple(celle)
                    if t in self.celler:
                        self.celler[t] = farger[tegn]
                        funnet += 1
                        if funnet >= dybde:
                            break
                    elif funnet:
                        break
                    celle[akse] -= fortegn

    def stempel_par(self, punkt_hoyre, monster, farger, dybde=1):
        """Samme mønster på høyre (+x) og venstre (-x) side, speilvendt — typisk øynene."""
        x, y, z = punkt_hoyre
        self.stempel((x, y, z), '+x', monster, farger, dybde)
        self.stempel((-x, y, z), '-x', monster, farger, dybde)

    def prikker(self, farger, bare=None, fro=7):
        """Bytt fargen på tilfeldige kuber. farger: [(farge, andel), ...]. bare: bare kuber med disse fargene."""
        for c, f in list(self.celler.items()):
            if bare is not None and f not in bare:
                continue
            h = _hash(*c, fro=fro)
            acc = 0.0
            for farge, andel in farger:
                acc += andel
                if h < acc:
                    self.celler[c] = farge
                    break

    def speilet(self):
        """Speilbilde om x = 0 (venstre vinge fra høyre)."""
        v = Voksler(self.s, self.monster)
        v.celler = {(-1 - i, j, k): f for (i, j, k), f in self.celler.items()}
        return v

    def antall(self):
        return len(self.celler)

    # ------------------------------------------------------------ mesh

    def _variant(self, c, f):
        if self.monster and (f + '_2') in R.PALETT:
            h = _hash(*c)
            return f + ('_1' if h < 0.3 else ('_3' if h > 0.75 else '_2'))
        return f if f in R.PALETT else f + '_2'

    def lag(self, gradig=True):
        """Bygg mesh med bare de synlige sidene, og legg den til i modellen som bygges.
        gradig: slå sammen like nabosider til større rektangler (færre trekanter)."""
        if not self.celler:
            raise RuntimeError('voksel: ingen kuber')
        s = self.s
        variant = {c: self._variant(c, f) for c, f in self.celler.items()}
        # synlige sider gruppert per (akse, fortegn, plan): {(u, v): variant}
        sjikt = {}
        for c, var in variant.items():
            for a in range(3):
                for sg in (1, -1):
                    nb = list(c)
                    nb[a] += sg
                    if tuple(nb) in self.celler:
                        continue
                    b_, c_ = (a + 1) % 3, (a + 2) % 3
                    sjikt.setdefault((a, sg, c[a] + (1 if sg > 0 else 0)), {})[(c[b_], c[c_])] = var
        bm = bmesh.new()
        uvl = bm.loops.layers.uv.verify()
        punkter = {}

        def punkt(p):
            p = tuple(p)
            v = punkter.get(p)
            if v is None:
                v = bm.verts.new((p[0] * s, p[1] * s, p[2] * s))
                punkter[p] = v
            return v
        for (a, sg, plan), flater in sjikt.items():
            b_, c_ = (a + 1) % 3, (a + 2) % 3
            brukt = set()
            for (u0, v0) in sorted(flater, key=lambda t: (t[1], t[0])):
                if (u0, v0) in brukt:
                    continue
                var = flater[(u0, v0)]
                w = h = 1
                if gradig:
                    while (u0 + w, v0) in flater and (u0 + w, v0) not in brukt and flater[(u0 + w, v0)] == var:
                        w += 1
                    while all((u0 + x, v0 + h) in flater and (u0 + x, v0 + h) not in brukt
                              and flater[(u0 + x, v0 + h)] == var for x in range(w)):
                        h += 1
                for x in range(w):
                    for y in range(h):
                        brukt.add((u0 + x, v0 + y))
                hj = [(u0, v0), (u0 + w, v0), (u0 + w, v0 + h), (u0, v0 + h)]
                if sg < 0:
                    hj.reverse()
                vs = []
                for ub, uc in hj:
                    p = [0, 0, 0]
                    p[a], p[b_], p[c_] = plan, ub, uc
                    vs.append(punkt(p))
                f = bm.faces.new(vs)
                uv = R._uv(var)
                for lp in f.loops:
                    lp[uvl].uv = uv
        me = bpy.data.meshes.new('voksel')
        bm.to_mesh(me)
        bm.free()
        ob = bpy.data.objects.new('voksel', me)
        bpy.context.scene.collection.objects.link(ob)
        me.materials.append(R.palett_materiale())
        R._DELER.append(ob)
        return ob
