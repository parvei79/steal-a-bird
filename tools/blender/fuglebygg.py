"""
Byggeklosser for blokkfuglene, delt av fugler.py og fuglegruppene (fugler_*.py):
    Fugl      kropp + høyre vinge (+ valgfri «ekstra» del) -> 3–4 modeller med hengsel-punkter
    fot, bein kubebaserte føtter og bein
    S         kubestørrelsen (lik for alle fugler)
    OYE, SOT_OYE  standard pikseløyne
Felles farger (svart, hvit, tann, klo, øyefarger) registreres her. Fargene til hver fugl registreres
i modulen fuglen står i (med eget prefiks i fuglegruppene, så navnene ikke kolliderer).
"""
import rbxlib as R
from voksel import Voksler, farge_trio, langs  # noqa: F401  (gjenbrukes av fuglemodulene)

S = 0.3   # kubestørrelse — lik for alle fugler, så stilen blir lik

R.farger(svart='#16161c', hvit='#ffffff', tann='#fbfbf5', klo='#1d1d22', stjerne='#ffffff', stjernegul='#ffe783',
         ojegul='#ffe45c', ojeoransje='#ff9a1f', ojerod='#ff4a2a', ojecyan='#8ff8ff')

OYE = {'w': 'hvit', 'k': 'svart'}
SOT_OYE = ['wk', 'kk']                    # søtt øye: svart 2x2 med hvitt glimt


# ------------------------------------------------------------------ byggeklosser

class Fugl:
    def __init__(self):
        self.kropp = Voksler(S)
        self.vinge = Voksler(S)       # HØYRE vinge (+x); venstre lages ved speiling
        self.ekstra = None
        self.hengsel = (1.0, 0.0, 2.5)
        self.punkter = {}

    def ferdig(self, navn):
        hx, hy, hz = self.hengsel
        punkter = dict(self.punkter)
        punkter['hengselH'] = (hx, hy, hz)
        punkter['hengselV'] = (-hx, hy, hz)
        R.ny_modell()
        self.kropp.lag()
        R.ferdig_modell(navn, punkter=punkter)
        R.ny_modell()
        self.vinge.lag()
        R.ferdig_modell(navn + '_VingeH')
        R.ny_modell()
        self.vinge.speilet().lag()
        R.ferdig_modell(navn + '_VingeV')
        if self.ekstra is not None:
            R.ny_modell()
            self.ekstra.lag()
            R.ferdig_modell(navn + '_Ekstra')


def fot(v, x, y, farge, form='T', klo=None, lengde=3):
    """Fot på bakken, bygget kube for kube så tærne holder seg adskilt. (x, y) = ankelen.
    form: 'stump' (én tå forover), 'T' (pluss to korte sidetær), 'gaffel' (store fuglefotspor —
    trenger minst 6 kubers avstand mellom beina, dvs. x = ±1.05)."""
    i0, j0, k0 = v._celle((x, y, 0.15))

    def sett(di, dj, f):
        v.celler[(i0 + di, j0 + dj, k0)] = f
    for dj in range(-1, lengde):
        sett(0, dj, farge)
    tupper = [(0, lengde)]
    if form == 'T':
        for s_ in (-1, 1):
            sett(s_, 1, farge)
        tupper += [(-1, 2), (1, 2)]
    elif form == 'gaffel':
        for s_ in (-1, 1):
            sett(s_, 1, farge)
            sett(2 * s_, 2, farge)
            sett(2 * s_, 3, farge)
        tupper += [(-2, 4), (2, 4)]
    if klo:
        for di, dj in tupper:
            sett(di, dj, klo)


def bein(v, x, hofte, ankel, farge, r=0.2):
    v.kjegle((x, hofte[0], hofte[1]), (x, ankel[0], ankel[1]), r, r, farge)


