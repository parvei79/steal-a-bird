"""
Ikon (512x512) og bilde til spillsiden (1920x1080) for Steal a Bird, rendret i Blender med de ekte
blokkmodellene: en klassisk «noob»-figur som stikker av med en Phoenix over hodet, mens eieren skyter kroken
etter ham. Tittel med Arial Rounded Bold (ligner FredokaOne i spillet).

    /Applications/Blender.app/Contents/MacOS/Blender -b --factory-startup -P tools/blender/ikon.py

Skriver assets/ikon.png og assets/thumbnail.png (last dem opp på create.roblox.com → spillet → Places/Thumbnails).
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bpy  # noqa: E402
from mathutils import Matrix, Vector  # noqa: E402

import rbxlib as R  # noqa: E402

R.tom_scene()
import fugler  # noqa: E402
import rekvisitter  # noqa: E402
from voksel import Voksler, farge_trio  # noqa: E402

ROT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
FONT = '/System/Library/Fonts/Supplemental/Arial Rounded Bold.ttf'

for navn, h in (('i_hode', '#f5cd30'), ('i_torso', '#1f74c4'), ('i_bein', '#4ba347'),
                ('i_jord', '#8c6239'), ('i_stein', '#8a8a96'), ('i_sint', '#e8533f')):
    farge_trio(navn, h)
farge_trio('i_gress', '#6fcf55', spenn=0.05)
R.palett_materiale()

BILDE_FUGLER = ['Phoenix', 'Toucan', 'Dodo', 'CosmicShoebill', 'Shoebill', 'Pigeon']
fugler.bygg([n for n in BILDE_FUGLER if n in fugler.FUGLER])
for f in ('Roc', 'Thunderbird', 'IcePhoenix', 'Flamingo', 'Penguin', 'Peacock'):
    if f in fugler.FUGLER:
        fugler.bygg([f])
rekvisitter.egg('EggLegendary', 'legendary')
rekvisitter.egg('EggGolden', 'golden')
rekvisitter.sokkel()
rekvisitter.mynt()
rekvisitter.krokpistol()


# ------------------------------------------------------------------ hjelpere

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
    return ny


def sett(ob, origo_matrise, lokal):
    ob.matrix_world = origo_matrise @ lokal


def plasser_fugl(navn, pos, vinkel_z=0.0, skala=1.0, vinge=0.0, tilt=(0, 0, 0)):
    """Plasser en hel fugl (kropp + vinger) med origo i pos. vinge = grader ut/opp."""
    origo = (Matrix.Translation(pos) @ Matrix.Rotation(math.radians(vinkel_z), 4, 'Z')
             @ Matrix.Rotation(math.radians(tilt[0]), 4, 'X') @ Matrix.Rotation(math.radians(tilt[1]), 4, 'Y')
             @ Matrix.Scale(skala, 4))
    obs = []
    kropp = kopi(navn)
    sett(kropp, origo, Matrix.Translation(blender_midt(navn)))
    obs.append(kropp)
    for side, del_ in ((1, '_VingeH'), (-1, '_VingeV')):
        if navn + del_ not in R.MODELLER:
            continue
        v = kopi(navn + del_)
        h = punkt(navn, 'hengselH' if side > 0 else 'hengselV')
        rot = Matrix.Rotation(math.radians(-vinge * side), 4, 'Y')
        sett(v, origo, Matrix.Translation(h) @ rot @ Matrix.Translation(-h) @ Matrix.Translation(blender_midt(navn + del_)))
        obs.append(v)
    if navn + '_Ekstra' in R.MODELLER:
        e = kopi(navn + '_Ekstra')
        sett(e, origo, Matrix.Translation(blender_midt(navn + '_Ekstra')))
        obs.append(e)
    return obs


def plasser(navn, pos, vinkel_z=0.0, skala=1.0, rot=(0, 0, 0)):
    ob = kopi(navn)
    origo = (Matrix.Translation(pos) @ Matrix.Rotation(math.radians(vinkel_z), 4, 'Z')
             @ Matrix.Rotation(math.radians(rot[0]), 4, 'X') @ Matrix.Rotation(math.radians(rot[1]), 4, 'Y')
             @ Matrix.Scale(skala, 4))
    sett(ob, origo, Matrix.Translation(blender_midt(navn)))
    return ob


def noob(navn, sint=False):
    """Klassisk Roblox-noob i blokker (gult hode og armer, blå overkropp, grønne bein), armene rett opp.
    Bygges stående med origo på bakken; poses via plasser()."""
    v = Voksler(0.25)
    for s in (-1, 1):
        v.boks((s * 0.5 - 0.5, -0.5, 0), (s * 0.5 + 0.5, 0.5, 2.0), 'i_bein')         # bein
        v.boks((s * 1.5 - 0.5, -0.5, 3.2), (s * 1.5 + 0.5, 0.5, 5.6), 'i_hode')       # armer rett opp
    v.boks((-1.0, -0.5, 2.0), (1.0, 0.5, 4.0), 'i_torso')
    v.boks((-0.62, -0.62, 4.0), (0.62, 0.62, 5.25), 'i_hode')                          # hode
    # ansikt (mot +Y): øyne og munn
    v.stempel((0.0, 0.62, 4.75), '+y', ['k.k', '...'], {'k': 'svart'})
    if sint:
        v.stempel((0.0, 0.62, 4.85), '+y', ['k...k'], {'k': 'svart'})
        v.stempel((0.0, 0.62, 4.35), '+y', ['kkk'], {'k': 'i_sint'})
    else:
        v.stempel((0.0, 0.62, 4.35), '+y', ['k...k', '.kkk.'], {'k': 'svart'})
    R.ny_modell()
    v.lag()
    return R.ferdig_modell(navn)


noob('Noob')
noob('Eier', sint=True)


def oy(navn, radius, hoyde=2.0):
    v = Voksler(1.0)
    v.ellipsoide((0, 0, -hoyde), (radius, radius, hoyde + 4), 'i_jord', p=2.5)
    v.boks((-radius - 1, -radius - 1, 0), (radius + 1, radius + 1, 10), 'i_jord', modus='fjern')
    v.boks((-radius - 1, -radius - 1, -1.0), (radius + 1, radius + 1, 0), 'i_gress', modus='mal')
    v.prikker([('i_stein', 0.25)], bare=['i_jord'], fro=3)
    R.ny_modell()
    v.lag()
    return R.ferdig_modell(navn)


oy('Oy', 24)

# skjul originalene (vi bruker kopier)
for info in R.MODELLER.values():
    info['obj'].hide_render = True


# ------------------------------------------------------------------ tittel med omriss

def tittel(tekst, pos, storrelse, rot_x=90, farge=(1.0, 0.72, 0.02)):
    kurve = bpy.data.curves.new('tittel', 'FONT')
    kurve.body = tekst
    if os.path.exists(FONT):
        kurve.font = bpy.data.fonts.load(FONT)
    kurve.align_x = 'CENTER'
    kurve.align_y = 'CENTER'
    kurve.size = storrelse
    kurve.extrude = storrelse * 0.08
    kurve.bevel_depth = storrelse * 0.004
    ob = bpy.data.objects.new('tittel', kurve)
    bpy.context.scene.collection.objects.link(ob)
    ob.location = pos
    ob.rotation_euler = (math.radians(rot_x), 0, math.radians(180))  # står oppreist og leses mot kameraet (+Y)
    bpy.context.view_layer.objects.active = ob
    ob.select_set(True)
    bpy.ops.object.convert(target='MESH')
    gul = bpy.data.materials.new('tittelgul')
    gul.use_nodes = True
    p = gul.node_tree.nodes['Principled BSDF']
    p.inputs['Base Color'].default_value = (*farge, 1)
    p.inputs['Roughness'].default_value = 0.35
    try:
        p.inputs['Emission Color'].default_value = (*farge, 1)
        p.inputs['Emission Strength'].default_value = 0.6
    except KeyError:
        pass
    svart = bpy.data.materials.new('omriss')
    svart.use_nodes = True
    svart.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value = (0.05, 0.03, 0.08, 1)
    svart.use_backface_culling = True
    ob.data.materials.append(gul)
    ob.data.materials.append(svart)
    mod = ob.modifiers.new('omriss', 'SOLIDIFY')
    mod.thickness = storrelse * 0.05
    mod.offset = 1
    mod.use_flip_normals = True
    mod.material_offset = 1
    ob.select_set(False)
    return ob


# ------------------------------------------------------------------ lys og bakgrunn

sc, cam = R._scene_for_render(512)
sc.render.engine = 'BLENDER_EEVEE'
cam.data.type = 'PERSP'
cam.data.lens = 32
w = sc.world
w.node_tree.nodes['Background'].inputs['Color'].default_value = (0.38, 0.66, 1.0, 1)
w.node_tree.nodes['Background'].inputs['Strength'].default_value = 1.0


def bakgrunn(navn, pos, rot, str_, topp, bunn):
    bpy.ops.mesh.primitive_plane_add(size=1, location=pos, rotation=rot)
    pl = bpy.context.active_object
    pl.name = navn
    pl.scale = (str_[0], str_[1], 1)
    m = bpy.data.materials.new(navn)
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
    rampe.color_ramp.elements[0].color = (*bunn, 1)
    rampe.color_ramp.elements[1].color = (*topp, 1)
    nt.links.new(rampe.outputs['Color'], em.inputs['Color'])
    em.inputs['Strength'].default_value = 1.0
    nt.links.new(em.outputs['Emission'], ut.inputs['Surface'])
    pl.data.materials.append(m)
    return pl


def kamera(pos, mal, lens):
    cam.location = pos
    retning = Vector(mal) - Vector(pos)
    cam.rotation_euler = retning.to_track_quat('-Z', 'Y').to_euler()
    cam.data.lens = lens


def render(sti, b, h):
    sc.render.resolution_x = b
    sc.render.resolution_y = h
    sc.render.filepath = sti
    bpy.ops.render.render(write_still=True)
    print('Skrev', sti)


def tom():
    for ob in list(bpy.data.objects):
        if ob.name not in ('kamera', 'sol') and not any(ob is i['obj'] for i in R.MODELLER.values()):
            bpy.data.objects.remove(ob, do_unlink=True)


# ------------------------------------------------------------------ ikonet (512x512)
# Kameraet står på +Y og ser mot -Y (fuglene ser mot +Y). NB: da er verdens -X til HØYRE i bildet.
# Noob-tyven løper mot kameraet med Phoenix over hodet; mynter og gullegg rundt; tittel øverst.
def tyv(pos, vinkel, skala, fugl='Phoenix', fugl_skala=1.0, vinge=12):
    plasser('Noob', pos, vinkel_z=vinkel, skala=skala)
    plasser_fugl(fugl, pos + Vector((0, 0, 5.65 * skala)), vinkel_z=vinkel, skala=fugl_skala, vinge=vinge)


plasser('Oy', Vector((0, 0, 0)))
tyv(Vector((0, 2.5, 0)), -10, 1.35, fugl_skala=1.3)
plasser('Sokkel', Vector((-7.5, -3, 0)))
plasser_fugl('CosmicShoebill' if 'CosmicShoebill' in R.MODELLER else 'Shoebill', Vector((-7.5, -3, 1.4)), vinkel_z=25)
plasser('Sokkel', Vector((7.5, -2.5, 0)))
plasser_fugl('Toucan', Vector((7.5, -2.5, 1.4)), vinkel_z=-30)
plasser('EggGolden', Vector((4.5, 6.5, 0)), vinkel_z=20)
for i, (x, z) in enumerate(((-5.5, 9.5), (5.6, 10.6), (-6.5, 4.6), (4.4, 6.0), (6.6, 14.5), (-6.2, 14.0))):
    plasser('Mynt', Vector((x, 3.0, z)), vinkel_z=30 * i, rot=(10 * i, 20, 0))
tittel('STEAL A\nBIRD!', Vector((0, 1.0, 20.2)), 3.3)
bakgrunn('himmel', Vector((0, -30, 10)), (math.radians(90), 0, 0), (100, 70), (0.22, 0.52, 1.0), (1.0, 0.68, 0.28))
kamera(Vector((0.4, 25, 10)), (0, 0, 11.2), 28)
render(os.path.join(ROT, 'assets', 'ikon.png'), 512, 512)

# ------------------------------------------------------------------ bildet til spillsiden (1920x1080)
# Tittel til venstre (verdens +X), tyven med Phoenix og fuglene på soklene til høyre.
tom()
plasser('Oy', Vector((0, 0, 0)), skala=1.7)
fugler_bak = [f for f in ('Roc', 'Peacock', 'Dodo', 'Shoebill', 'Thunderbird', 'Flamingo', 'Toucan', 'Pigeon')
              if f in R.MODELLER][:5]
for i, fugl in enumerate(fugler_bak):
    x = -2 - i * 6.5
    plasser('Sokkel', Vector((x, -9, 0)))
    plasser_fugl(fugl, Vector((x, -9, 1.4)), vinkel_z=10 - 6 * i)
tyv(Vector((-9, 5, 0)), -25, 1.45, fugl_skala=1.35, vinge=18)
plasser('EggLegendary', Vector((-20, 4, 0)), vinkel_z=10)
plasser('EggGolden', Vector((-2.5, 8, 0)), vinkel_z=-20)
for i, (x, z) in enumerate(((-4, 10), (-15, 12), (-7, 17), (-13, 6), (-18, 15), (-2, 15))):
    plasser('Mynt', Vector((x, 4.0, z)), vinkel_z=40 * i, rot=(10 * i, 25, 0))
tittel('STEAL A\nBIRD!', Vector((11.5, 3, 12.5)), 5.2)
bakgrunn('himmel', Vector((0, -45, 10)), (math.radians(90), 0, 0), (180, 100), (0.22, 0.52, 1.0), (1.0, 0.68, 0.28))
kamera(Vector((0, 40, 13)), (0, 0, 8.5), 30)
render(os.path.join(ROT, 'assets', 'thumbnail.png'), 1920, 1080)
print('Ferdig.')
