"""
Ikonene til game passes og developer products i Steal a Bird (512x512 PNG), rendret i Blender med de
ekte blokkmodellene (Sokkel, Mynt, Krok, egg og fugler) pluss noen nye voksel-figurer (krone, magnet,
firkløver, pengesekk, myntstabler og regnbuetauet):

    VIP          gullkrone med edelsteiner og mynter rundt        «VIP» + rødt «x2»-merke
    AutoCollect  hesteskomagnet som trekker til seg mynter        «AUTO»
    ExtraSlots   fire sokler med fugler og egg                    «+4»
    RainbowRope  gripekroken med et tvunnet regnbuetau i en bue   «RAINBOW» (én farge per bokstav)
    ServerLuck   firkløver og to skinnende egg                    «LUCK» + rødt «x2»-merke
    CashPack     pengesekk med $ og en haug mynter                «CASH»

    /Applications/Blender.app/Contents/MacOS/Blender -b --factory-startup -P tools/blender/robux_ikoner.py
    ... -- VIP CashPack                bare noen av ikonene
    ... -- --ark /private/tmp/ark.png  kontrollark med sirkelen Roblox klipper game pass-ikonene til

Skriver assets/robux/<Navn>.png (last dem opp på create.roblox.com -> spillet -> Monetization).
Figurene rendres med gjennomsiktig bakgrunn, og bildet settes sammen med numpy: fargerik bakgrunn med
stråler og blokkmønster, mørkt omriss og skygge rundt figurene, glimt, og tekst (Arial Rounded Bold) med
3D-kant og omriss. Roblox viser game pass-ikonene som en sirkel, så alt viktig ligger innenfor en
sentrert sirkel på 85 % av bredden. Alt rendres i 1024x1024 og skaleres ned (glatte kanter).
"""
import math
import os
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bpy  # noqa: E402
import numpy as np  # noqa: E402
from bpy_extras.object_utils import world_to_camera_view  # noqa: E402
from mathutils import Matrix, Vector  # noqa: E402

import rbxlib as R  # noqa: E402

R.tom_scene()
import fugler  # noqa: E402  (registrerer fargene)
import rekvisitter  # noqa: E402
from voksel import Voksler, farge_trio  # noqa: E402

ROT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
UT = os.path.join(ROT, 'assets', 'robux')
TMP = os.path.join('/private/tmp' if os.path.isdir('/private/tmp') else tempfile.gettempdir(), 'robux_ikoner')
FONT = '/System/Library/Fonts/Supplemental/Arial Rounded Bold.ttf'
ARGS = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []

ENDELIG = 512           # ferdig størrelse
ST = 1024               # rendres i dobbel størrelse og skaleres ned
K = ST / ENDELIG        # koordinatene i oppsettene er i 512-piksler; K gjør dem om til render-piksler

# Egne farger (prefiks ik_). Paletten er nesten full, så maks 15 farge_trio-er.
for _n, _h in dict(
        ik_solv='#eef3f8',            # polene på magneten
        ik_magnet='#e8202b',          # magneten (dypere rød enn låseknappen)
        ik_klover='#3fd052',          # firkløveret
        ik_kloverlys='#a6f58c',
        ik_klovermork='#168a39',
        ik_sekkmork='#26894d',        # flekker på pengesekken
        ik_snor='#b9772e',            # snora rundt halsen på sekken
).items():
    farge_trio(_n, _h)
R.palett_materiale()


# ------------------------------------------------------------------ nye voksel-figurer

def krone():
    """Gullkrone som i emojien: et buet bånd med fem trekantede takker, gullkuler på tuppene og edelsteiner.
    Bare den fremre delen av ringen bygges (bakerste takker ville rotet til omrisset). Origo på bakken,
    forsiden mot +Y."""
    v = Voksler(0.25)
    r0, tykk, vmax = 4.2, 0.75, math.radians(62)           # radius, tykkelse og hvor langt båndet går rundt
    takker = [(0.0, 4.5), (-1.95, 3.85), (1.95, 3.85), (-3.75, 3.2), (3.75, 3.2)]  # (posisjon langs båndet, topp)
    bunn = 1.45                                             # der takkene begynner (hakkene mellom dem)

    def sylinder(p):
        """(radius, buelengde fra midten foran) rundt aksen som går loddrett gjennom (0, -r0)."""
        return math.hypot(p.x, p.y + r0), r0 * math.atan2(p.x, p.y + r0)

    def form(p):
        r, s = sylinder(p)
        if not (r0 - tykk <= r <= r0) or abs(s) > r0 * vmax:
            return None
        if p.z <= bunn:
            return 0.0
        for sc, zt in takker:
            if p.z <= zt and abs(s - sc) <= 0.98 * (zt - p.z) / (zt - bunn):
                return 0.0
        return None
    v._fyll(Vector((-4.8, -3.4, 0)), Vector((4.8, 0.6, 4.7)), form, 'mynt')
    v.boks((-5, -4, 0.3), (5, 1, 5), lambda p, _t: 'myntmork' if sylinder(p)[0] < r0 - tykk + 0.3 else None,
           modus='mal')                                     # innsiden litt mørkere

    def kant(z0, z1):
        def test(p):
            r, s = sylinder(p)
            return 0.0 if z0 <= p.z <= z1 and r0 - tykk <= r <= r0 + 0.25 and abs(s) <= r0 * vmax else None
        v._fyll(Vector((-4.8, -3.4, z0)), Vector((4.8, 0.6, z1)), test, 'myntmork')
    kant(0.0, 0.35)
    kant(1.15, 1.5)

    def paa_baandet(s, z, r):
        a = s / r0
        return (r * math.sin(a), r * math.cos(a) - r0, z)
    for sc, zt in takker:
        v.ellipsoide(paa_baandet(sc, zt + 0.1, r0 - tykk / 2), (0.6, 0.6, 0.6), 'egggul')      # kule på tuppen
    for sc, r, farge in ((0.0, 0.62, 'eggrod'), (-1.95, 0.5, 'eggregnbla'), (1.95, 0.5, 'eggregnbla'),
                         (-3.7, 0.44, 'eggregngronn'), (3.7, 0.44, 'eggregngronn')):
        v.ellipsoide(paa_baandet(sc, 0.75, r0 + 0.05), (r, r, r), farge)
    v.prikker([('r_gull_lys', 0.04)], bare=['mynt'], fro=5)
    R.ny_modell()
    v.lag()
    return R.ferdig_modell('Krone', punkter={'stein': paa_baandet(0.0, 0.75, r0 + 0.6),
                                             'topp': paa_baandet(-0.3, 5.0, r0)})


def magnet():
    """Hesteskomagnet: rød bue med sølvpoler. Åpningen peker opp (+Z), forsiden mot +Y."""
    v = Voksler(0.3)
    rm, b, t = 2.1, 1.6, 1.6                # radius til midten av buen, bredde og tykkelse
    v.ring((0, 0, 0), (0, 1, 0), rm, b, t, 'ik_magnet')
    v.boks((-5, -2, 0.0), (5, 2, 5), 'ik_magnet', modus='fjern')
    for s in (-1, 1):
        x0, x1 = sorted((s * (rm - b / 2), s * (rm + b / 2)))
        v.boks((x0, -t / 2, 0), (x1, t / 2, 2.1), 'ik_magnet')
        v.boks((x0, -t / 2, 2.1), (x1, t / 2, 3.2), 'ik_solv')
    R.ny_modell()
    v.lag()
    return R.ferdig_modell('Magnet', punkter={'apning': (0, 0, 3.2)})


def klover():
    """Firkløver: fire hjerteformede blader i XZ-planet (forsiden mot +Y), med mørk kant og lys midtstripe,
    og en stilk som bøyer seg ned. Origo midt i kløveret."""
    v = Voksler(0.2)
    tykk = 0.6
    vinkler = [math.radians(45 + 90 * n) for n in range(4)]

    def blad(p):
        if abs(p.y) > tykk / 2:
            return None
        for a in vinkler:
            ux, uz = math.cos(a), math.sin(a)
            s = p.x * ux + p.z * uz              # utover langs bladet
            q = -p.x * uz + p.z * ux             # på tvers
            x, y = q / 1.08, (s - 0.12) / 1.08 - 1.0
            if (x * x + y * y - 1) ** 3 - x * x * y ** 3 <= 0:     # hjerte med spissen inn mot midten
                return 0.0
        return None
    v._fyll(Vector((-3, -1, -3)), Vector((3, 1, 3)), blad, 'ik_klover')
    # mørk kant: kuber som mangler en nabo i planet
    kant = [c for c in v.celler if any((c[0] + dx, c[1], c[2] + dz) not in v.celler
                                       for dx, dz in ((1, 0), (-1, 0), (0, 1), (0, -1)))]
    for c in kant:
        v.celler[c] = 'ik_klovermork'

    def stripe(p, _t):
        for a in vinkler:
            ux, uz = math.cos(a), math.sin(a)
            s = p.x * ux + p.z * uz
            q = -p.x * uz + p.z * ux
            if 0.45 < s < 1.75 and abs(q) < 0.12:
                return 'ik_kloverlys'
        return None
    v.boks((-3, -1, -3), (3, 1, 3), stripe, modus='mal')
    v.ellipsoide((0, 0, 0), (0.45, 0.42, 0.45), 'ik_klovermork')
    forrige = Vector((0, 0, 0))
    for n in range(1, 7):                    # stilken
        t = n / 6
        p = Vector((-0.9 * t * t, 0.05, -2.9 * t))
        v.kjegle(forrige, p, 0.24, 0.22, 'ik_klovermork')
        forrige = p
    R.ny_modell()
    v.lag()
    return R.ferdig_modell('Klover')


DOLLAR = [
    '....#....',
    '.#######.',
    '##..#..##',
    '##..#....',
    '.######..',
    '..######.',
    '....#..##',
    '##..#..##',
    '.#######.',
    '....#....',
]


def pengesekk():
    """Grønn pengesekk med en stor gul $ på forsiden og snor rundt halsen. Origo på bakken."""
    v = Voksler(0.25)
    v.ellipsoide((0, 0, 1.8), (2.25, 1.95, 2.05), 'pengegronn', p=2.2)
    v.boks((-3, -3, -1), (3, 3, 0.0), 'pengegronn', modus='fjern')
    v.kjegle((0, 0, 3.4), (0, 0, 4.4), 1.15, 0.75, 'pengegronn')                  # halsen
    v.ellipsoide((0, 0, 4.75), (0.8, 0.8, 0.45), 'pengegronn')
    for n in range(6):                                                           # stoffet som stritter
        a = n / 6 * 2 * math.pi + 0.3
        v.kjegle((0, 0, 4.4), (math.cos(a) * 1.35, math.sin(a) * 1.35, 5.25 + 0.25 * (n % 2)), 0.5, 0.2,
                 'pengegronn')
    v.prikker([('ik_sekkmork', 0.14)], bare=['pengegronn'], fro=3)
    v.kjegle((0, 0, 3.95), (0, 0, 4.45), 1.0, 1.0, 'ik_snor')                     # snora
    v.stempel((0, 2.0, 1.85), '+y', DOLLAR, {'#': 'pengegull'})
    R.ny_modell()
    v.lag()
    return R.ferdig_modell('Pengesekk')


def myntstabel(navn, antall):
    """En stabel mynter (stripete kant), litt skjeve. Origo på bakken."""
    v = Voksler(0.2)
    for i in range(antall):
        z = i * 0.4
        dx, dy = 0.12 * math.sin(i * 1.7), 0.12 * math.cos(i * 2.3)
        v.kjegle((dx, dy, z), (dx, dy, z + 0.4), 0.9, 0.9, 'mynt')
        v.kjegle((dx, dy, z), (dx, dy, z + 0.2), 0.95, 0.95, 'myntmork', modus='mal')
    v.ring((0, 0, antall * 0.4 - 0.1), (0, 0, 1), 0.6, 0.2, 0.2, 'myntmork', modus='mal')
    R.ny_modell()
    v.lag()
    return R.ferdig_modell(navn)


def tau(navn, punkter, radius, farger, stigning):
    """Tau gjennom punktene (Blender-koordinater) med skrå fargestriper som snor seg rundt, som et tvunnet
    tau. stigning = hvor langt (studs) det er før samme farge kommer igjen langs tauet."""
    v = Voksler(0.25)
    s = 0.0
    n = len(farger)
    for a, b in zip(punkter, punkter[1:]):
        d = b - a
        w = d.normalized()
        u = w.cross(Vector((0, 1, 0)))
        u = u.normalized() if u.length > 1e-6 else Vector((1, 0, 0))
        vv = w.cross(u)

        def stripe(p, t, a=a, d=d, s0=s, u=u, vv=vv):
            rel = p - (a + d * t)
            rundt = math.atan2(rel.dot(vv), rel.dot(u)) / (2 * math.pi)
            return farger[int(math.floor(((s0 + t * d.length) / stigning + rundt) * n)) % n]
        v.kjegle(a, b, radius, radius, stripe)
        s += d.length
    R.ny_modell()
    v.lag()
    return R.ferdig_modell(navn)


# ------------------------------------------------------------------ modellene vi trenger

FUGL_2 = next(n for n in ('Flamingo', 'Puffin', 'Pigeon') if n in fugler.FUGLER)   # fugl nr. 2 i ExtraSlots
fugler.bygg(['Toucan', FUGL_2])
rekvisitter.sokkel()
rekvisitter.mynt()
rekvisitter.krok()
rekvisitter.egg('EggGolden', 'golden')
rekvisitter.egg('EggMythic', 'mythic')
rekvisitter.egg('EggEpic', 'epic')
krone()
magnet()
klover()
pengesekk()
myntstabel('Stabel3', 3)
myntstabel('Stabel5', 5)
myntstabel('Stabel7', 7)


# ------------------------------------------------------------------ plassering (som i ikon.py)

AKTIVE = []             # kopiene i ikonet som lages nå
TEKSTER = []


def B(h, z, d=0.0):
    """Bildekoordinater -> Blender. Kameraet står på +Y og ser mot -Y (modellene har forsiden mot +Y),
    så verdens -X er til HØYRE i bildet. h = mot høyre, z = opp, d = mot kameraet."""
    return Vector((-h, d, z))


def blender_midt(navn):
    m = R.MODELLER[navn]['midt']          # Roblox (x, y, z) -> Blender (x, -z, y)
    return Vector((m[0], -m[2], m[1]))


def punkt(navn, p):
    q = R.MODELLER[navn][p]
    return Vector((q[0], -q[2], q[1]))


def kopi(navn):
    ob = R.MODELLER[navn]['obj']
    ny = ob.copy()
    ny.data = ob.data
    ny.hide_render = False
    bpy.context.scene.collection.objects.link(ny)
    AKTIVE.append(ny)
    return ny


def rotasjon(snu=0.0, vipp=0.0, rull=0.0):
    """snu: om Z (positiv = forsiden mot høyre i bildet), vipp: om X, rull: i bildeplanet (mot klokka)."""
    return (Matrix.Rotation(math.radians(snu), 4, 'Z') @ Matrix.Rotation(math.radians(vipp), 4, 'X')
            @ Matrix.Rotation(math.radians(rull), 4, 'Y'))


def ramme(fram, opp=(0, 0, 1)):
    """Rotasjon (4x4) som snur modellens +Y mot `fram`, med +Z så nær `opp` som mulig."""
    f = Vector(fram).normalized()
    u = Vector(opp)
    u = (u - f * u.dot(f)).normalized()
    return Matrix((f.cross(u), f, u)).transposed().to_4x4()


def plasser(navn, pos, snu=0.0, vipp=0.0, rull=0.0, skala=1.0, rot=None):
    ob = kopi(navn)
    rot = rot if rot is not None else rotasjon(snu, vipp, rull)
    ob.matrix_world = (Matrix.Translation(pos) @ rot @ Matrix.Scale(skala, 4)
                       @ Matrix.Translation(blender_midt(navn)))
    return ob


def plasser_fugl(navn, pos, snu=0.0, skala=1.0, vinge=0.0):
    """Hel fugl (kropp + vinger + ekstra) med origo i pos. vinge = grader ut/opp."""
    origo = Matrix.Translation(pos) @ rotasjon(snu) @ Matrix.Scale(skala, 4)
    kopi(navn).matrix_world = origo @ Matrix.Translation(blender_midt(navn))
    for side, del_ in ((1, '_VingeH'), (-1, '_VingeV')):
        if navn + del_ in R.MODELLER:
            h = punkt(navn, 'hengselH' if side > 0 else 'hengselV')
            vr = Matrix.Rotation(math.radians(-vinge * side), 4, 'Y')
            kopi(navn + del_).matrix_world = (origo @ Matrix.Translation(h) @ vr @ Matrix.Translation(-h)
                                              @ Matrix.Translation(blender_midt(navn + del_)))
    if navn + '_Ekstra' in R.MODELLER:
        kopi(navn + '_Ekstra').matrix_world = origo @ Matrix.Translation(blender_midt(navn + '_Ekstra'))


def mynt(pos, skala=1.3, snu=0.0, vipp=0.0, rull=0.0):
    """Mynt som roterer rundt sin egen midte (Mynt-modellen har origo på bakken under mynten)."""
    rot = rotasjon(snu, vipp, rull)
    midt = Vector((0, 0, 0.8 * skala))
    return plasser('Mynt', Vector(pos) - rot.to_3x3() @ midt, skala=skala, rot=rot)


# ------------------------------------------------------------------ scene, lys og kameraer

sc, cam = R._scene_for_render(ST)
sc.render.engine = 'BLENDER_EEVEE'
sc.render.film_transparent = True
sc.render.image_settings.file_format = 'PNG'
sc.render.image_settings.color_mode = 'RGBA'
sc.eevee.taa_render_samples = 64
sc.eevee.shadow_cascade_size = '2048'
sc.eevee.use_shadow_high_bitdepth = True
cam.data.type = 'PERSP'
cam.data.sensor_fit = 'HORIZONTAL'
cam.data.sensor_width = 36
cam.data.clip_end = 500

sol = bpy.data.objects['sol']
sol.data.energy = 3.0
sol.data.shadow_cascade_max_distance = 80
sol.rotation_euler = (-B(-1.0, 1.4, 1.1)).to_track_quat('-Z', 'Y').to_euler()   # fra oppe til venstre, forfra
kant_lys = bpy.data.objects.new('kantlys', bpy.data.lights.new('kantlys', 'SUN'))
kant_lys.data.energy = 1.6
kant_lys.data.use_shadow = False
kant_lys.rotation_euler = (-B(1.0, 0.8, -1.0)).to_track_quat('-Z', 'Y').to_euler()  # bakfra, oppe til høyre
sc.collection.objects.link(kant_lys)

TX = 5000.0             # teksten lages langt unna, med et eget ortografisk kamera (1 enhet = 1 piksel)
_tk = bpy.data.cameras.new('tekstkamera')
_tk.type = 'ORTHO'
_tk.ortho_scale = ENDELIG
_tk.clip_start, _tk.clip_end = 1, 500
tkam = bpy.data.objects.new('tekstkamera', _tk)
tkam.location = (TX, 0, 100)
sc.collection.objects.link(tkam)


def kamera(pos, mal, bredde):
    """Perspektivkamera i pos som ser mot mal; `bredde` = hvor mange studs bildet er bredt ved mal."""
    cam.location = pos
    retning = Vector(mal) - Vector(pos)
    cam.rotation_euler = retning.to_track_quat('-Z', 'Y').to_euler()
    cam.data.lens = 36 * retning.length / bredde


def til_bilde(p):
    """Verdenspunkt -> (x, y) i 512-piksler (y nedover)."""
    bpy.context.view_layer.update()
    co = world_to_camera_view(sc, cam, Vector(p))
    return co.x * ENDELIG, (1 - co.y) * ENDELIG


def omgivelse(hexkode, styrke=0.7):
    bg = sc.world.node_tree.nodes['Background']
    bg.inputs['Color'].default_value = (*lin(hexkode), 1)
    bg.inputs['Strength'].default_value = styrke


# ------------------------------------------------------------------ tekst

def srgb(hexkode):
    h = hexkode.lstrip('#')
    return [int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)]


def lin(hexkode):
    return [c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4 for c in srgb(hexkode)]


def tekstmateriale(topp, bunn):
    """Selvlysende (upåvirket av lyset), med fargeovergang ovenfra og ned."""
    m = bpy.data.materials.new('tekst')
    m.use_nodes = True
    nt = m.node_tree
    for n in list(nt.nodes):
        nt.nodes.remove(n)
    ut = nt.nodes.new('ShaderNodeOutputMaterial')
    em = nt.nodes.new('ShaderNodeEmission')
    rampe = nt.nodes.new('ShaderNodeValToRGB')
    tk = nt.nodes.new('ShaderNodeTexCoord')
    sep = nt.nodes.new('ShaderNodeSeparateXYZ')
    nt.links.new(tk.outputs['Generated'], sep.inputs['Vector'])
    nt.links.new(sep.outputs['Y'], rampe.inputs['Fac'])
    rampe.color_ramp.elements[0].position = 0.2
    rampe.color_ramp.elements[0].color = (*lin(bunn), 1)
    rampe.color_ramp.elements[1].position = 0.8
    rampe.color_ramp.elements[1].color = (*lin(topp), 1)
    nt.links.new(rampe.outputs['Color'], em.inputs['Color'])
    em.inputs['Strength'].default_value = 1.0
    nt.links.new(em.outputs['Emission'], ut.inputs['Surface'])
    return m


GUL = ('#fffbc2', '#ffc21a')            # tekstfarge: lys gul øverst, gull nederst
HVIT = ('#ffffff', '#dfe9ff')
REGNBUE = [('#ff8a8a', '#ff2e2e'), ('#ffc27a', '#ff8a1a'), ('#fff7a0', '#ffd21a'),
           ('#9ff5a8', '#2fc94a'), ('#9ad0ff', '#2f86ff'), ('#d6a8ff', '#9a4dff')]


def lag_tekst(t):
    """t: dict(tekst, x, y, str, rot=0, farger=[(topp, bunn), ...], avstand=1.0)."""
    kurve = bpy.data.curves.new('tekst', 'FONT')
    kurve.body = t['tekst']
    if os.path.exists(FONT):
        kurve.font = bpy.data.fonts.load(FONT, check_existing=True)
    kurve.align_x = 'CENTER'
    kurve.align_y = 'CENTER'
    kurve.size = t['str']
    kurve.space_character = t.get('avstand', 1.0)
    ob = bpy.data.objects.new('tekst', kurve)
    sc.collection.objects.link(ob)
    ob.location = (TX + t['x'] - ENDELIG / 2, ENDELIG / 2 - t['y'], 0)
    ob.rotation_euler = (0, 0, math.radians(t.get('rot', 0)))
    farger = t.get('farger', [GUL])
    for topp, bunn in farger:
        kurve.materials.append(tekstmateriale(topp, bunn))
    if len(farger) > 1:                      # én farge per bokstav
        i = 0
        for n, tegn in enumerate(t['tekst']):
            if tegn.strip():
                kurve.body_format[n].material_index = i % len(farger)
                i += 1
    TEKSTER.append(ob)
    return ob


# ------------------------------------------------------------------ bildebehandling (numpy, 0..1 sRGB)

def les_png(sti):
    img = bpy.data.images.load(sti)
    b, h = img.size
    px = np.empty(b * h * 4, dtype=np.float32)
    img.pixels.foreach_get(px)
    bpy.data.images.remove(img)
    return px.reshape(h, b, 4)[::-1].copy()          # rad 0 = øverst


def lagre_png(sti, rgb):
    h, b = rgb.shape[:2]
    px = np.ones((h, b, 4), dtype=np.float32)
    px[..., :3] = np.clip(rgb, 0, 1)
    img = bpy.data.images.new('ut', b, h, alpha=False)
    img.pixels.foreach_set(px[::-1].ravel())
    img.filepath_raw = sti
    img.file_format = 'PNG'
    img.save()
    bpy.data.images.remove(img)


def forskyv(a, dy, dx):
    """Flytt et bilde dy piksler ned og dx mot høyre (det som kommer inn er 0)."""
    ut = np.zeros_like(a)
    h, b = a.shape[:2]
    ut[max(dy, 0):h + min(dy, 0), max(dx, 0):b + min(dx, 0)] = \
        a[max(-dy, 0):h + min(-dy, 0), max(-dx, 0):b + min(-dx, 0)]
    return ut


def utvid(a, r):
    """Maks-filter med rund kjerne (radius r): gjør en maske r piksler tykkere — omrisset."""
    h, b = a.shape
    ut = a.copy()
    for dy in range(-r, r + 1):
        for dx in range(-r, r + 1):
            if (dx or dy) and dx * dx + dy * dy <= r * r + r:
                mal = ut[max(dy, 0):h + min(dy, 0), max(dx, 0):b + min(dx, 0)]
                np.maximum(mal, a[max(-dy, 0):h + min(-dy, 0), max(-dx, 0):b + min(-dx, 0)], out=mal)
    return ut


def blur(a, r):
    """Tre runder boksfilter (nesten gaussisk) på en 2D-maske."""
    for _ in range(3):
        for akse in (0, 1):
            p = np.pad(a, [(r + 1, r) if i == akse else (0, 0) for i in range(2)], mode='edge')
            c = np.cumsum(p, axis=akse)
            n = a.shape[akse]
            if akse == 0:
                a = (c[2 * r + 1:2 * r + 1 + n] - c[:n]) / (2 * r + 1)
            else:
                a = (c[:, 2 * r + 1:2 * r + 1 + n] - c[:, :n]) / (2 * r + 1)
    return a


def bland(bilde, farge, alfa):
    return bilde * (1 - alfa[..., None]) + np.asarray(farge) * alfa[..., None]


def bakgrunn(b):
    """Fargeovergang fra lys midte til mørk kant, stråler ut fra midten, svakt blokkmønster og mørke hjørner."""
    indre, ytre = np.array(srgb(b['indre'])), np.array(srgb(b['ytre']))
    cx, cy = b.get('midt', (0.5, 0.45))
    y, x = (np.mgrid[0:ST, 0:ST].astype(np.float32) + 0.5) / ST
    dx, dy = x - cx, y - cy
    d = np.sqrt(dx * dx + dy * dy)
    t = np.clip(d / b.get('radius', 0.62), 0, 1)
    t = t * t * (3 - 2 * t)
    farge = bland(np.broadcast_to(indre, (ST, ST, 3)), ytre, t)
    n = b.get('straaler', 12)
    if n:
        v = np.arctan2(dy, dx) + math.radians(b.get('vri', 8))
        s = np.clip(np.cos(v * n) * 2.5, -1, 1) * 0.5 + 0.5
        styrke = b.get('straalestyrke', 0.12) * np.clip(1.2 - d / 0.7, 0, 1)
        farge = farge + (1 - farge) * (s * styrke)[..., None]
    rute = ST // 16
    i = np.arange(ST) // rute
    bi, bj = np.meshgrid(i, i, indexing='ij')
    h = np.sin(bi * 12.9898 + bj * 78.233) * 43758.5453
    h = (h - np.floor(h)) * 2 - 1
    farge = farge * (1 + b.get('blokk', 0.03) * h)[..., None]
    farge = farge * (1 - 0.35 * np.clip((d - 0.45) / 0.3, 0, 1) ** 1.5)[..., None]
    return np.clip(farge, 0, 1)


def gnist(bilde, x, y, r, farge='#ffffff', glod=0.5):
    """Glimt: firkantet stjerne med glød rundt (i render-piksler)."""
    h, b = bilde.shape[:2]
    rr = int(r * 1.8) + 2
    x0, x1, y0, y1 = max(0, int(x - rr)), min(b, int(x + rr) + 1), max(0, int(y - rr)), min(h, int(y + rr) + 1)
    if x0 >= x1 or y0 >= y1:
        return
    yy, xx = np.mgrid[y0:y1, x0:x1].astype(np.float32) + 0.5
    ax, ay = np.abs(xx - x) / r, np.abs(yy - y) / r
    stjerne = np.clip((1 - (np.sqrt(ax) + np.sqrt(ay))) * r * 0.6, 0, 1)
    g = np.exp(-(ax * ax + ay * ay) * 5) * glod
    a = np.maximum(stjerne, g)
    bilde[y0:y1, x0:x1] = bland(bilde[y0:y1, x0:x1], srgb(farge), a)


def fartsstrek(bilde, x0, y0, x1, y1, bredde, farge='#ffffff', alfa=0.9):
    """Fartsstrek fra (x0, y0) (tykk og tydelig) til (x1, y1) (smal og borte), i render-piksler."""
    h, b = bilde.shape[:2]
    m = bredde + 2
    bx0, bx1 = max(0, int(min(x0, x1) - m)), min(b, int(max(x0, x1) + m) + 1)
    by0, by1 = max(0, int(min(y0, y1) - m)), min(h, int(max(y0, y1) + m) + 1)
    if bx0 >= bx1 or by0 >= by1:
        return
    yy, xx = np.mgrid[by0:by1, bx0:bx1].astype(np.float32) + 0.5
    dx, dy = x1 - x0, y1 - y0
    t = np.clip(((xx - x0) * dx + (yy - y0) * dy) / max(dx * dx + dy * dy, 1e-6), 0, 1)
    d = np.sqrt((xx - x0 - t * dx) ** 2 + (yy - y0 - t * dy) ** 2)
    halv = bredde / 2 * (1 - 0.6 * t)
    a = np.clip(halv - d + 0.5, 0, 1) * alfa * (1 - t ** 1.5)
    bilde[by0:by1, bx0:bx1] = bland(bilde[by0:by1, bx0:bx1], srgb(farge), a)


def sirkel(bilde, x, y, r, farge, kant=0.0, kantfarge=None, topp=None):
    """Fylt sirkel (med glatt kant), valgfritt med omriss og fargeovergang (topp -> farge)."""
    h, b = bilde.shape[:2]
    yy, xx = np.mgrid[0:h, 0:b].astype(np.float32) + 0.5
    d = np.sqrt((xx - x) ** 2 + (yy - y) ** 2)
    if kant:
        bilde[:] = bland(bilde, srgb(kantfarge), np.clip(r + kant - d + 0.5, 0, 1))
    a = np.clip(r - d + 0.5, 0, 1)
    if topp:
        t = np.clip((yy - (y - r)) / (2 * r), 0, 1)[..., None]
        fyll = np.array(srgb(topp)) * (1 - t) + np.array(srgb(farge)) * t
        bilde[:] = bilde * (1 - a[..., None]) + fyll * a[..., None]
    else:
        bilde[:] = bland(bilde, srgb(farge), a)


def tekstlag(bilde, px, t, omriss):
    """Legg en rendret tekst oppå: skygge, omriss, 3D-kant (mørkere tekstfarge rett under) og selve teksten."""
    a = px[..., 3]
    c = px[..., :3]
    dybde = max(1, int(t.get('dybde', 0.07) * t['str'] * K))
    kant_a = np.zeros_like(a)
    kant_c = np.zeros_like(c)
    for dy in range(1, dybde + 1):
        sa = forskyv(a, dy, 0)
        ny = sa > kant_a
        kant_c[ny] = forskyv(c, dy, 0)[ny]
        kant_a = np.maximum(kant_a, sa)
    kant_c = kant_c * np.array(t.get('kantmork', (0.85, 0.5, 0.3)))
    hel = np.maximum(a, kant_a)
    o = utvid(hel, int(round(t.get('strek', 6.5) * K)))
    skygge = forskyv(blur(o, int(4 * K)), int(5 * K), int(1 * K))
    bilde[:] = bilde * (1 - 0.35 * skygge[..., None])
    bilde[:] = bland(bilde, srgb(omriss), o)
    bilde[:] = bland(bilde, kant_c, kant_a)
    bilde[:] = bland(bilde, c, a)


# ------------------------------------------------------------------ ett ikon

def rydd():
    for ob in AKTIVE + TEKSTER:
        bpy.data.objects.remove(ob, do_unlink=True)
    AKTIVE.clear()
    TEKSTER.clear()


def render(sti, kam):
    sc.camera = kam
    sc.render.filepath = sti
    bpy.context.view_layer.update()
    bpy.ops.render.render(write_still=True)


def lag_ikon(navn, scene, o):
    """scene() plasserer figurene og kameraet, og kan returnere dict(gnister=[...], streker=[...]) regnet ut
    fra 3D-posisjonene. o = oppsett: bak (bakgrunn), omriss (farge), strek (tykkelse på omrisset),
    gnister [(x, y, r)], merker [dict(x, y, r, farge, topp)], tekster [dict]. Koordinater i 512-piksler."""
    os.makedirs(TMP, exist_ok=True)
    for info in R.MODELLER.values():
        info['obj'].hide_render = True
    ekstra = scene() or {}
    omgivelse(o.get('lys', '#ffffff'), o.get('lysstyrke', 0.75))
    fg_sti = os.path.join(TMP, f'{navn}_figurer.png')
    render(fg_sti, cam)
    for ob in AKTIVE:
        ob.hide_render = True
    tekster = []
    for i, t in enumerate(o.get('tekster', [])):
        ob = lag_tekst(t)
        for andre in TEKSTER:
            andre.hide_render = andre is not ob
        sti = os.path.join(TMP, f'{navn}_tekst{i}.png')
        render(sti, tkam)
        tekster.append((t, les_png(sti)))
    rydd()

    fg = les_png(fg_sti)
    bilde = bakgrunn(o['bak'])
    for x0, y0, x1, y1, b in ekstra.get('streker', []):
        fartsstrek(bilde, x0 * K, y0 * K, x1 * K, y1 * K, b * K)
    a = fg[..., 3]
    if o.get('glod'):                       # farget glød bak figurene (regnbuetauet «skinner»)
        r = int(o.get('glodradius', 22) * K)
        glod = np.stack([blur(fg[..., i] * a, r) for i in range(3)], axis=-1) * o['glod']
        bilde = 1 - (1 - bilde) * (1 - np.clip(glod, 0, 1))
    omr = utvid(a, int(round(o.get('strek', 4.5) * K)))
    skygge = forskyv(blur(omr, int(5 * K)), int(6 * K), int(2 * K))
    bilde = bilde * (1 - 0.32 * skygge[..., None])
    bilde = bland(bilde, srgb(o['omriss']), omr)
    bilde = bland(bilde, fg[..., :3], a)
    for x, y, r in list(o.get('gnister', [])) + list(ekstra.get('gnister', [])):
        gnist(bilde, x * K, y * K, r * K)
    for m in o.get('merker', []):
        skive = np.zeros((ST, ST, 3), dtype=np.float32)
        sirkel(skive, m['x'] * K, m['y'] * K, (m['r'] + 5) * K, '#ffffff')
        skygge = forskyv(blur(skive[..., 0], int(4 * K)), int(5 * K), int(1 * K))
        bilde = bilde * (1 - 0.4 * skygge[..., None])
        sirkel(bilde, m['x'] * K, m['y'] * K, m['r'] * K, m['farge'], kant=5 * K, kantfarge=o['omriss'],
               topp=m.get('topp'))
    for t, px in tekster:
        tekstlag(bilde, px, t, o['omriss'])
    h = ST // 2
    bilde = bilde.reshape(h, 2, h, 2, 3).mean(axis=(1, 3))
    os.makedirs(UT, exist_ok=True)
    sti = os.path.join(UT, f'{navn}.png')
    lagre_png(sti, bilde)
    print('Skrev', sti)
    return sti


# ------------------------------------------------------------------ de seks ikonene

def verden(ob, navn, p):
    """Et punkt i modellens egne koordinater (relativt til origo) -> verden, for en plassert kopi."""
    return ob.matrix_world @ (Vector(p) - blender_midt(navn))


def streker_fra(punkt_fra, mynter, lengde=46, bredde=6):
    """Fartsstreker bak hver mynt, rett vekk fra `punkt_fra` (bildepiksler)."""
    ut = []
    fx, fy = punkt_fra
    for (x, y), r in mynter:
        dx, dy = x - fx, y - fy
        n = math.hypot(dx, dy) or 1
        dx, dy = dx / n, dy / n
        for side, l in ((-0.5, 0.8), (0.0, 1.0), (0.5, 0.75)):
            sx, sy = x + dx * r * 0.75 - dy * r * side, y + dy * r * 0.75 + dx * r * side
            ut.append((sx, sy, sx + dx * lengde * l, sy + dy * lengde * l, bredde))
    return ut


def vip():
    krone = plasser('Krone', B(0, 0.0, 0), snu=-6, rull=4)
    for h, z, d, sk, snu, rull in ((-3.9, 3.9, 0.0, 0.95, 35, 15), (-4.2, 0.25, 1.2, 1.2, 25, -20),
                                   (4.2, 0.6, 1.0, 1.15, -40, -10)):
        mynt(B(h, z, d), skala=sk, snu=snu, rull=rull)
    kamera(B(0, 1.2 + 5.0, 26), B(0, 1.2, 0), 14.0)
    return dict(gnister=[(*til_bilde(verden(krone, 'Krone', punkt('Krone', 'stein'))), 13),
                         (*til_bilde(verden(krone, 'Krone', punkt('Krone', 'topp'))), 10)])


def auto_collect():
    # magneten til venstre med åpningen mot høyre; myntene flyr inn mot den med fartsstreker bak seg
    m = plasser('Magnet', B(-2.85, 3.3, 0), rull=-115, skala=0.9)
    bredde = 16.0
    kamera(B(0, 4.5, 26), B(0, 1.5, 0), bredde)
    mynter = []
    for h, z, d, sk, snu, rull in ((1.35, 1.6, 0.5, 1.0, -35, 20), (3.4, 3.1, 1.0, 1.2, 30, -15),
                                   (3.5, 0.0, 1.0, 1.2, -25, 10), (4.95, 1.7, 1.5, 1.3, 20, 30)):
        mynt(B(h, z, d), skala=sk, snu=snu, rull=rull)
        mynter.append((til_bilde(B(h, z, d)), 0.8 * sk * ENDELIG / bredde))     # (midten, radius i piksler)
    apning = til_bilde(verden(m, 'Magnet', punkt('Magnet', 'apning')))
    return dict(streker=streker_fra(apning, mynter), gnister=[(apning[0] + 8, apning[1] - 30, 11)])


def extra_slots():
    ting = [  # (h, d, slag, navn, snu)
        (-2.0, -2.2, 'fugl', 'Toucan', 25),
        (2.0, -2.2, 'fugl', FUGL_2, -25),
        (-4.0, 2.3, 'egg', 'EggEpic', 15),
        (4.0, 2.3, 'egg', 'EggMythic', -15),
    ]
    for h, d, slag, navn, snu in ting:
        pos = B(h, 0, d)
        plasser('Sokkel', pos, snu=snu)
        if slag == 'fugl':
            plasser_fugl(navn, pos + Vector((0, 0, 1.4)), snu=snu, skala=1.12, vinge=12)
        else:
            plasser(navn, pos + Vector((0, 0, 1.4)), snu=snu, skala=1.25)
    kamera(B(0, 1.8 + 10.5, 26), B(0, 1.8, 0), 18.0)


def rainbow_rope():
    # tauet er en kastebane (parabel) som kommer inn nede til venstre, går over toppen og ender i kroken
    ha, za, he, ze = -1.9, 5.45, 2.4, 1.5             # toppunktet (h, z) og enden der kroken sitter
    a = (za - ze) / (he - ha) ** 2
    hs = -8.5
    pkt = [B(h, za - a * (h - ha) ** 2, 0.0) for h in (hs + (he - hs) * i / 120 for i in range(121))]
    navn = 'Regnbuetau'
    if navn in R.MODELLER:
        bpy.data.objects.remove(R.MODELLER.pop(navn)['obj'], do_unlink=True)
    tau(navn, pkt, 0.72, ['eggrod', 'eggoransje', 'egggul', 'eggregngronn', 'eggregnbla', 'eggregnlilla'], 3.2)
    R.MODELLER[navn]['obj'].hide_render = True
    plasser(navn, Vector((0, 0, 0)))
    s_h = 2.2
    h_fram = (pkt[-1] - pkt[-3]).normalized()
    h_rot = ramme(h_fram, opp=B(0, 0, 1))
    plasser('Krok', pkt[-1] - h_rot.to_3x3() @ (punkt('Krok', 'ring') * s_h), rot=h_rot, skala=s_h)
    kamera(B(0, 3.0, 26), B(0, 0.0, 0), 16.0)
    return dict(gnister=[(*til_bilde(pkt[i]), r) for i, r in ((40, 9), (66, 14), (90, 10))])


def server_luck():
    plasser('Klover', B(0, 3.3, 0), vipp=-15, rull=-12, skala=1.2)
    plasser('EggGolden', B(-3.25, -0.6, 1.0), snu=20, rull=10, skala=1.2)
    plasser('EggMythic', B(3.25, -0.6, 1.0), snu=-20, rull=-10, skala=1.2)
    kamera(B(0, 2.0 + 4.5, 26), B(0, 2.0, 0), 13.0)


def cash_pack():
    plasser('Pengesekk', B(0, 0, 0), snu=-8, skala=1.1)
    plasser('Stabel7', B(-3.6, 0, 1.0), snu=10)
    plasser('Stabel5', B(3.5, 0, 1.2), snu=-10)
    plasser('Stabel3', B(-1.9, 0, 3.0))
    for h, z, d, s, snu, vipp, rull in ((1.8, 0.35, 3.4, 1.1, 0, 80, 0), (-3.9, 6.0, -1.0, 1.0, 35, 0, 20),
                                        (4.1, 5.3, -1.0, 1.05, -30, 0, -15), (2.4, 0.9, 2.6, 1.0, -30, 20, 10)):
        mynt(B(h, z, d), skala=s, snu=snu, vipp=vipp, rull=rull)
    kamera(B(0, 6.0, 25), B(0, 2.4, 0), 15.0)


IKONER = {
    'VIP': (vip, dict(
        bak=dict(indre='#c35cff', ytre='#3a0d82', straaler=14), omriss='#1d0838', lys='#f2e6ff', lysstyrke=0.55,
        merker=[dict(x=364, y=150, r=46, farge='#ff2d55', topp='#ff8a9e')],
        tekster=[dict(tekst='VIP', x=256, y=386, str=132, rot=-4, farger=[GUL]),
                 dict(tekst='x2', x=366, y=148, str=58, rot=-8, farger=[HVIT], dybde=0.05, strek=5)],
        gnister=[(150, 105, 15)])),
    'AutoCollect': (auto_collect, dict(
        bak=dict(indre='#7fe6ff', ytre='#1438b8', straaler=12), omriss='#0a1a4a', lys='#e6f6ff',
        tekster=[dict(tekst='AUTO', x=256, y=387, str=100, rot=-4, farger=[GUL])])),
    'ExtraSlots': (extra_slots, dict(
        bak=dict(indre='#b5ffd9', ytre='#0d7a5f', straaler=12), omriss='#06301f', lys='#f0fff6',
        tekster=[dict(tekst='+4', x=256, y=380, str=135, rot=-4, farger=[GUL])])),
    'RainbowRope': (rainbow_rope, dict(
        bak=dict(indre='#7a6bff', ytre='#140a4f', straaler=14), omriss='#100828', lys='#efe8ff',
        glod=0.8, glodradius=26, gnister=[(205, 245, 13), (290, 300, 9), (150, 320, 8), (330, 200, 7)],
        tekster=[dict(tekst='RAINBOW', x=256, y=398, str=66, rot=-3, farger=REGNBUE, dybde=0.08, strek=5.5)])),
    'ServerLuck': (server_luck, dict(
        bak=dict(indre='#f2ff8f', ytre='#178a32', straaler=12), omriss='#08301c', lys='#f0fff0',
        merker=[dict(x=364, y=150, r=46, farge='#ff2d55', topp='#ff8a9e')],
        tekster=[dict(tekst='LUCK', x=256, y=386, str=104, rot=-4, farger=[GUL]),
                 dict(tekst='x2', x=366, y=148, str=58, rot=-8, farger=[HVIT], dybde=0.05, strek=5)],
        gnister=[(150, 250, 12), (330, 110, 10), (395, 285, 11)])),
    'CashPack': (cash_pack, dict(
        bak=dict(indre='#fff27a', ytre='#e86a00', straaler=14), omriss='#3a1a00', lys='#fff6e6',
        tekster=[dict(tekst='CASH', x=256, y=388, str=100, rot=-4, farger=[('#ffffff', '#c8ffb0')],
                      kantmork=(0.35, 0.6, 0.35))],
        gnister=[(170, 110, 14), (360, 150, 11)])),
}


def kontrollark(sti, filer):
    """Alle ikonene ved siden av hverandre, med sirkelen (85 %) som Roblox klipper game pass-ikonene til."""
    bilder = [les_png(f)[..., :3] for f in filer]
    kol = 3
    rader = (len(bilder) + kol - 1) // kol
    ark = np.full((rader * ENDELIG, kol * ENDELIG, 3), 0.15, dtype=np.float32)
    yy, xx = np.mgrid[0:ENDELIG, 0:ENDELIG].astype(np.float32) + 0.5
    d = np.sqrt((xx - ENDELIG / 2) ** 2 + (yy - ENDELIG / 2) ** 2)
    utenfor = (d > ENDELIG * 0.425)[..., None]
    ring = (np.abs(d - ENDELIG * 0.425) < 1.2)[..., None]
    for i, b in enumerate(bilder):
        b = np.where(utenfor, b * 0.45, b)
        b = np.where(ring, np.array([1.0, 1.0, 1.0]), b)
        r, k = i // kol, i % kol
        ark[r * ENDELIG:(r + 1) * ENDELIG, k * ENDELIG:(k + 1) * ENDELIG] = b
    lagre_png(sti, ark)
    print('Skrev', sti)


ark_sti = None
if '--ark' in ARGS:
    i = ARGS.index('--ark')
    ark_sti = ARGS[i + 1]
    ARGS = ARGS[:i] + ARGS[i + 2:]
valgte = ARGS or list(IKONER)
ukjente = [n for n in valgte if n not in IKONER]
if ukjente:
    raise SystemExit(f'Ukjente ikoner: {ukjente}. Finnes: {list(IKONER)}')
filer = [lag_ikon(n, *IKONER[n]) for n in valgte]
if ark_sti:
    kontrollark(ark_sti, filer)
print(f'Ferdig. Palett: {len(R.PALETT)} av {R.RUTER * R.RUTER} farger brukt.')
