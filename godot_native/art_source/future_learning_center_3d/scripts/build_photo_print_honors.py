"""Photo print / honors candidates. Blender 4.3.2, estimated metres.

Reference photos are inspected, never embedded or sampled as textures.
All visible content panels are deliberately neutral, replaceable blanks.
Run: blender -b --factory-startup -t 4 --python scripts/build_photo_print_honors.py
Flags: --skip-render, --render-only, --asset=<id>, --composition-only.
"""
import bpy, bmesh, math, json, hashlib, collections, sys
import numpy as np
from pathlib import Path
from mathutils import Vector, Matrix

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'sources/models/photo_print_honors'
REVIEW = ROOT / 'review/photo_print_honors'
OUT.mkdir(parents=True, exist_ok=True)
REVIEW.mkdir(parents=True, exist_ok=True)
LOD = 0
CURRENT_FOLDER = OUT
records = []

def material(name, color, metal=0., rough=.5):
    m = bpy.data.materials.new(name); m.use_nodes = True
    m.diffuse_color = (*color, 1)
    p = m.node_tree.nodes.get('Principled BSDF')
    p.inputs['Base Color'].default_value = (*color, 1)
    p.inputs['Metallic'].default_value = metal
    p.inputs['Roughness'].default_value = rough
    return m

def grain_material(name, low, high):
    m = material(name, tuple((a+b)/2 for a,b in zip(low,high)), 0, .55)
    n = [384,192,96][LOD]
    u,v = np.meshgrid(np.linspace(0,1,n), np.linspace(0,1,n))
    warp = u + .005*np.sin(v*18+u*12) + .002*np.cos(v*31)
    g = np.clip(.5 + .13*np.sin(warp*300) + .09*np.sin(warp*1050+v*9) + .025*np.random.default_rng(2116).normal(size=(n,n)), 0, 1)
    pixels = np.ones((n,n,4), dtype=np.float32)
    for k in range(3): pixels[:,:,k] = low[k] + g*(high[k]-low[k])
    im = bpy.data.images.new(name+' synthetic grain', width=n, height=n, alpha=True)
    im.pixels.foreach_set(pixels.ravel()); im.filepath_raw = str(CURRENT_FOLDER / ('synthetic_oak_lod'+str(LOD)+'.png'))
    im.file_format='PNG'; im.save(); im.pack()
    tex=m.node_tree.nodes.new('ShaderNodeTexImage'); tex.image=im
    m.node_tree.links.new(tex.outputs['Color'], m.node_tree.nodes.get('Principled BSDF').inputs['Base Color'])
    m['textureProvenance']='Deterministic synthetic wood grain. No source photograph pixels.'
    return m

def palette(wood=False):
    global white, plastic, dark, rubber, screen, silver, gold, oak, content, tint, charcoal, warm
    white=material('Warm white printer housing',(.68,.70,.67),0,.34)
    plastic=material('Charcoal printer polymer',(.039,.047,.049),0,.48)
    dark=material('Recess interior matte',(.009,.012,.014),0,.73)
    rubber=material('Rubber buttons and feet',(.018,.023,.025),0,.65)
    screen=material('Inactive blue grey LCD',(.13,.21,.24),.08,.28)
    silver=material('Satin aluminium',(.52,.56,.56),.82,.3)
    gold=material('Satin brass silhouette',(.55,.34,.10),.83,.32)
    oak=grain_material('Light oak',(.49,.36,.23),(.64,.50,.34)) if wood else material('Light oak',(.57,.43,.28),0,.55)
    content=material('REPLACEABLE neutral blank content',(.72,.73,.70),0,.80)
    tint=material('REPLACEABLE blue grey blank panel',(.22,.32,.34),0,.68)
    charcoal=material('Black plinth',(.014,.018,.018),.08,.42)
    warm=material('Warm white solid surface',(.77,.76,.70),0,.38)

def active(o):
    bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o

def finish(o,name,mat,smooth=False):
    o.name=name; o['part']=name
    if mat:o.data.materials.append(mat)
    for p in o.data.polygons:p.use_smooth=smooth
    return o

def bevel(o,width):
    bpy.context.view_layer.update();active(o)
    m=o.modifiers.new('Manufactured edge radius','BEVEL');m.width=min(width,.45*min(o.dimensions));m.segments=[4,2,1][LOD]
    bpy.ops.object.modifier_apply(modifier=m.name)
    m=o.modifiers.new('Weighted manufactured normals','WEIGHTED_NORMAL');m.keep_sharp=True
    bpy.ops.object.modifier_apply(modifier=m.name)

def planar_uv(o):
    uv=o.data.uv_layers.new(name='UVMap')
    mn=Vector([min(v.co[i] for v in o.data.vertices) for i in range(3)])
    ext=Vector([max(v.co[i] for v in o.data.vertices) for i in range(3)])-mn
    for p in o.data.polygons:
        n=p.normal;axes=(0,1) if abs(n.z)>.5 else ((0,2) if abs(n.y)>.5 else (1,2))
        for li in p.loop_indices:
            co=o.data.vertices[o.data.loops[li].vertex_index].co
            uv.data[li].uv=tuple((co[i]-mn[i])/max(ext[i],.00001) for i in axes)

def box(name,loc,size,mat,radius=0):
    bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.dimensions=size
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);finish(o,name,mat)
    if radius:bevel(o,radius)
    planar_uv(o);return o

def mesh(name,vs,fs,mat):
    me=bpy.data.meshes.new(name);me.from_pydata(vs,[],fs);me.update()
    bm=bmesh.new();bm.from_mesh(me);bmesh.ops.recalc_face_normals(bm,faces=bm.faces);bm.to_mesh(me);bm.free();me.update()
    o=bpy.data.objects.new(name,me);bpy.context.collection.objects.link(o);finish(o,name,mat);planar_uv(o);return o

def cylinder(name,loc,r,depth,mat,rotation=None,r2=None,vertices=None):
    bpy.ops.mesh.primitive_cone_add(vertices=vertices or [32,16,8][LOD],radius1=r,radius2=r if r2 is None else r2,depth=depth,location=loc)
    o=finish(bpy.context.object,name,mat,True)
    if rotation:o.rotation_euler=rotation
    return o

def slab(name,xy,z,h,mat,radius=0):
    n=len(xy);vs=[(x,y,zz) for zz in [z,z+h] for x,y in xy]
    fs=[tuple(reversed(range(n))),tuple(range(n,2*n))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
    o=mesh(name,vs,fs,mat)
    if radius:bevel(o,radius)
    return o

def rounded_outline(w,d,r,cx=0,cy=0):
    xy=[];n=[7,4,2][LOD]
    for x,y,start in [(w/2-r,d/2-r,0),(-w/2+r,d/2-r,90),(-w/2+r,-d/2+r,180),(w/2-r,-d/2+r,270)]:
        for k in range(n+1):
            a=math.radians(start+90*k/n);xy.append((cx+x+r*math.cos(a),cy+y+r*math.sin(a)))
    return xy

def yz_extrude(name,width,profile,mat,x=0,radius=0):
    n=len(profile);vs=[(xx,y,z) for xx in [x-width/2,x+width/2] for y,z in profile]
    fs=[tuple(reversed(range(n))),tuple(range(n,2*n))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
    o=mesh(name,vs,fs,mat)
    if radius:bevel(o,radius)
    return o

def transform_new(before,m):
    bpy.context.view_layer.update()
    pairs=[(o,o.matrix_world.copy()) for o in bpy.context.scene.objects if o not in before]
    for o,mw in pairs:o.matrix_world=m@mw
    bpy.context.view_layer.update()

def white_mfp():
    # Face is -Y. The asymmetric ADF, open feed cavity, control slope and tray
    # are separate closed pieces; they are not a generic cuboid approximation.
    box('Low rounded printer chassis',(0,.005,.135),(.43,.37,.263),white,.019)
    box('Bottom recessed base',(0,.009,.009),(.389,.335,.018),plastic,.004)
    for x in [-.16,.16]:
        for y in [-.13,.14]:box('Rubber foot',(x,y,.008),(.035,.033,.016),rubber,.003)
    box('Front access door',(0,-.184,.151),(.396,.015,.216),white,.012)
    box('Front door pull dark recess',(0,-.194,.219),(.111,.004,.027),plastic,.007)
    box('Front recessed pull inner',(0,-.197,.216),(.097,.006,.016),white,.005)
    box('Output opening behind extended lower tray',(0,-.194,.043),(.325,.009,.029),dark,.004)
    trayxy=[(-.167,-.198),(.167,-.198),(.166,-.338),(.150,-.358),(-.150,-.358),(-.166,-.338)]
    slab('Extended lower paper tray',trayxy,.029,.013,white,.003)
    slab('Extended tray graphite inset',[(-.153,-.202),(.153,-.202),(.150,-.337),(-.150,-.337)],.042,.003,plastic)
    box('Tray front lip',(0,-.354,.040),(.298,.012,.025),white,.003)
    box('Tray sliding grip',(0,-.363,.037),(.068,.016,.020),plastic,.003)
    # Black output band remains open at the front, with white scanner above.
    box('Output cavity dark back',(0,.135,.289),(.398,.043,.045),dark,.003)
    for x in [-.202,.202]:box('Output band side wall',(x,.006,.286),(.025,.32,.050),plastic,.005)
    box('Upper output channel floor',(0,-.004,.268),(.387,.344,.015),plastic,.004)
    box('Upper output cavity lip',(0,-.176,.273),(.375,.015,.016),plastic,.004)
    yz_extrude('Angled control fascia',.424,[(-.218,.296),(-.218,.322),(-.119,.363),(-.109,.335)],plastic,radius=.005)
    # Buttons and LCD share the control plane. Clear inactive controls, no logos.
    before=set(bpy.context.scene.objects)
    box('LCD bezel',(-.104,0,.001),(.106,.045,.006),dark,.004)
    box('Inactive LCD',(-.104,-.001,.0045),(.085,.029,.002),screen,.001)
    for i,(x,y,r) in enumerate([(-.179,0,.007),(-.028,.003,.011),(-.028,-.014,.004),(.153,.004,.008),(.179,.004,.008)]):
        cylinder('Control key '+str(i),(x,y,.004),r,.005,rubber)
    for row in range(3):
        for col in range(3):cylinder('Numeric button %s %s'%(row,col),(.025+col*.023,.014-row*.014,.004),.0044,.004,rubber)
    if LOD<2:
        for x in [.108,.127]:
            for y in [-.012,.009]:cylinder('Auxiliary function key',(x,y,.004),.0047,.004,rubber)
    # Keep the control cluster in front of the scanner's leading edge. Its
    # rearward position would otherwise hide the buttons under the scanner lip.
    transform_new(before,Matrix.Translation(Vector((0,-.202,.329)))@Matrix.Rotation(.394,4,'X'))
    slab('Rounded scanner lower shell',rounded_outline(.446,.367,.028,0,.006),.348,.034,white)
    slab('Scanner lid dark seam',rounded_outline(.420,.335,.025,0,.015),.382,.004,plastic)
    slab('Scanner lid rim',rounded_outline(.424,.339,.025,0,.015),.386,.016,white)
    # An open, asymmetric ADF feeder: thick left sweep, raised rear hinge roof.
    sideprofile=[(-.134,.402),(.178,.402),(.178,.472),(.128,.482),(-.030,.482),(-.073,.466),(-.111,.422)]
    yz_extrude('ADF white left sweeping housing',.087,sideprofile,white,x=-.169,radius=.009)
    yz_extrude('ADF rear hinged housing',.339,[(.104,.402),(.177,.402),(.177,.474),(.127,.480),(.104,.466)],white,x=.024,radius=.010)
    # Broad dark receiver slopes into the visible feed cavity.
    receiver=[(-.129,-.119),(.184,-.119),(.194,-.075),(.188,.072),(.160,.100),(-.127,.100)]
    slab('ADF black lower receiver',receiver,.414,.013,plastic,.004)
    feedxy=[(-.137,-.044),(.190,-.044),(.201,.008),(.200,.099),(.174,.127),(-.135,.127)]
    feed=slab('ADF raised feed tray',feedxy,.448,.009,plastic,.003)
    feed.rotation_euler.x=-.09
    box('ADF adjustable paper guide left',(-.083,.021,.462),(.009,.105,.018),plastic,.003)
    box('ADF adjustable paper guide right',(.137,.021,.462),(.009,.105,.018),plastic,.003)
    box('ADF white roof edge',(-.014,.150,.477),(.321,.025,.011),white,.004)
    for x in [-.149,.149]:box('Scanner rear hinge',(x,.178,.365),(.041,.025,.029),plastic,.004)
    # Each side vent is a shallow solid inset; no non-manifold cut planes.
    for i in range([12,8,5][LOD]):
        z=.107+i*(.125/max([12,8,5][LOD]-1,1))
        box('Right cooling vent '+str(i),(.2157,.048,z),(.0018,.133,.0028),plastic,.0004)
    if LOD<2:
        box('Rear cable access blank',(0,.192,.100),(.096,.008,.054),plastic,.003)
        for x in [-.165,.165]:cylinder('Rear hinge fastener',(x,.193,.234),.004,.003,silver,(math.pi/2,0,0))

def black_compact():
    box('Low wide charcoal printer body',(0,.008,.104),(.505,.350,.195),plastic,.012)
    box('Bottom shadow plinth',(0,.011,.015),(.466,.316,.026),dark,.004)
    for x in [-.197,.197]:
        for y in [-.12,.13]:box('Rubber foot',(x,y,.007),(.032,.032,.014),rubber,.003)
    slab('Scanner lid fine seam',rounded_outline(.499,.343,.015,0,.006),.199,.005,dark)
    slab('Low rounded scanner lid',rounded_outline(.500,.343,.018,0,.006),.204,.015,plastic)
    box('Front broad charcoal access door',(-.045,-.173,.116),(.395,.015,.150),plastic,.007)
    box('Horizontal paper exit slot',(-.046,-.184,.082),(.365,.006,.014),dark,.002)
    box('Output tray lower rail',(-.047,-.206,.044),(.371,.059,.013),dark,.003)
    box('Front top pull edge',(-.050,-.184,.184),(.117,.009,.011),dark,.002)
    # Distinct tall right ink/window compartment seen on the reference.
    box('Right tall ink compartment rim',(.208,-.177,.117),(.078,.022,.172),dark,.007)
    box('Muted blue grey ink window',(.208,-.190,.144),(.059,.004,.076),screen,.001)
    box('Ink window lower white glint',(.208,-.192,.111),(.056,.003,.011),white,.001)
    for i in range([6,5,4][LOD]):
        x=.178+i*.061/([6,5,4][LOD]-1)
        box('Ink tank vertical window rib '+str(i),(x,-.192,.065),(.005,.006,.056),plastic,.001)
    box('Small inactive status light',(-.057,-.184,.127),(.033,.003,.008),white,.002)
    cylinder('Top power key',(-.154,-.086,.222),.008,.003,rubber)
    if LOD<2:
        box('Top corner control strip',(-.194,-.098,.220),(.026,.083,.003),dark,.002)
        for i in range(3):cylinder('Small top control '+str(i),(-.194,-.076-i*.016,.223),.004,.002,screen)
    for i in range([9,6,4][LOD]):
        box('Right side cooling slot '+str(i),(.253,.037,.062+i*.010),(.002,.139,.003),dark,.0005)

def display_cabinet():
    # One combined upper/lower cabinet, not duplicate reconstructions of two photos.
    w=3.60;d=.49
    box('Recessed cabinet plinth',(0,.028,.040),(w-.12,d-.09,.080),charcoal,.003)
    box('Lower cabinet carcass',(0,.014,.445),(w-.028,d-.025,.744),oak,.004)
    box('Warm white counter slab',(0,-.004,.842),(w+.030,d+.036,.034),warm,.006)
    # Fine dark reveals behind six door fronts, no fake handles.
    box('Door reveal field',(0,-.239,.443),(w-.010,.010,.747),dark)
    for i in range(6):
        x=-w/2+(i+.5)*w/6
        box('Base cabinet wood door '+str(i),(x,-.250,.441),(w/6-.006,.022,.721),oak,.002)
        if LOD<2:box('Upper recessed finger pull '+str(i),(x,-.254,.806),(.17,.010,.011),charcoal,.001)
    # Solid white back is a cabinet panel, not a stage wall; it stops at the frame.
    box('White backing between display and shelf',(0,.235,1.317),(w-.035,.018,.918),warm)
    box('Upper cubby wood back',(0,.224,1.974),(w,.020,.486),oak)
    box('Upper shelf base',(0,.021,1.757),(w,.424,.030),oak,.002)
    box('Upper shelf roof',(0,.021,2.198),(w,.424,.030),oak,.002)
    for i in range(7):
        x=-w/2+.014+i*(w-.028)/6
        box('Upper cubby upright '+str(i),(x,.021,1.977),(.027,.424,.412),oak,.0015)
    box('Upper shallow fascia',(0,.025,2.270),(w,.416,.115),oak,.001)
    box('Under shelf diffuser housing',(0,-.189,1.740),(w-.045,.018,.018),silver,.003)
    box('Unlit continuous diffuser',(0,-.199,1.740),(w-.060,.003,.008),content,.001)

def wood_frame():
    # Horizontal master. Width/height are geometry parameters; depth must not be
    # non-uniformly scaled when producing a portrait format or alternate print size.
    w=.330;h=.252;t=.020;b=.022
    box('Frame closed hardboard rear',(0,.011,h/2),(w-.012,.008,h-.012),oak,.001)
    box('REPLACEABLE blank photo panel',(0,-.001,h/2),(w-2*b,.004,h-2*b),tint,.001)
    for x in [-1,1]:
        box('Light oak frame side '+str(x),(x*(w-b)/2,-.006,h/2),(b,t,h),oak,.002)
        if LOD<2:box('Inner wooden rebate '+str(x),(x*(w/2-b-.002),-.013,h/2),(.003,.003,h-2*b),oak,.0005)
    for z in [b/2,h-b/2]:box('Light oak frame horizontal rail',(0,-.006,z),(w-2*b,t,b),oak,.002)
    # Closed rear easel leg; stand footprint remains part of true asset bounds.
    leg=box('Rear easel support',(0,.069,.105),(.084,.010,.212),oak,.002);leg.rotation_euler.x=-.49
    box('Rear easel bottom foot',(0,.119,.012),(.093,.022,.016),oak,.002)
    if LOD<2:cylinder('Easel hinge',(0,.021,.205),.006,.088,silver,(0,math.pi/2,0))
    for o in bpy.context.scene.objects:
        if o.type=='MESH':o['contentStatus']='Neutral blank. No people, names or award claims.'

def certificate_stand():
    w=.228;h=.318
    box('Oak slotted certificate base',(0,.025,.012),(.260,.105,.024),oak,.005)
    # Metal-backed sleeve represents the visible certificate / metal display plates.
    # It is an opaque replaceable panel, not an approximation of original text.
    before=set(bpy.context.scene.objects)
    box('Satin metal closed backing',(0,.001,h/2+.019),(w,.006,h),silver,.002)
    box('REPLACEABLE neutral certificate face',(0,-.003,h/2+.019),(w-.012,.002,h-.012),content,.001)
    for x in [-1,1]:box('Clear sleeve edge substitute '+str(x),(x*(w/2-.003),-.005,h/2+.019),(.005,.003,h-.004),silver,.001)
    for z in [.022,h+.016]:box('Sleeve horizontal lip',(0,-.005,z),(w-.010,.003,.005),silver,.001)
    transform_new(before,Matrix.Rotation(math.radians(-7),4,'X'))
    # Plain brushed brass back plate is independently replaceable with content.
    # No logos, ribbons, medal symbols, seals, names or award words are generated.
    for o in bpy.context.scene.objects:
        if o.type=='MESH':o['contentStatus']='Neutral blank. No certificate text or award claims.'

def trophy_silhouette():
    box('Broad black trophy display plinth',(0,0,.023),(.260,.175,.046),charcoal,.003)
    box('Plain brass plinth band',(0,-.001,.041),(.256,.172,.022),gold,.001)
    box('Black plinth top',(0,0,.059),(.260,.175,.018),charcoal,.002)
    box('Slim black trophy pedestal',(0,.003,.121),(.075,.068,.119),charcoal,.002)
    box('Blank inset trophy plaque',(0,-.034,.116),(.055,.002,.042),silver,.001)
    # Faceted gold body and silver open head follow the visible stepped silhouette.
    cylinder('Faceted brass column foot',(0,.003,.190),.046,.027,gold,r2=.032,vertices=[12,8,6][LOD])
    cylinder('Faceted brass central column',(0,.003,.225),.030,.062,gold,r2=.038,vertices=[12,8,6][LOD])
    cylinder('Faceted brass shoulder',(0,.003,.266),.038,.021,gold,r2=.045,vertices=[12,8,6][LOD])
    box('Silver head lower sill',(0,.003,.285),(.088,.079,.014),silver,.002)
    box('Silver head upper sill',(0,.003,.361),(.088,.079,.014),silver,.002)
    for x in [-.037,.037]:
        for y in [-.029,.035]:box('Open trophy head corner',(x,y,.323),(.014,.014,.064),silver,.002)
    if LOD<2:
        # Abstract structural crossbar, not a logo or award emblem.
        bar=box('Gold head diagonal insert',(0,.006,.324),(.008,.008,.063),gold,.001);bar.rotation_euler.y=.49

ASSETS=[('photo_print_white_mfp',white_mfp),('photo_print_black_compact',black_compact),('photo_honors_display_cabinet',display_cabinet),('photo_honors_lightwood_frame',wood_frame),('photo_honors_certificate_stand',certificate_stand),('photo_honors_trophy_silhouette',trophy_silhouette)]

def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.preferences.filepaths.save_version=0
    bpy.context.scene.unit_settings.system='METRIC'

def bounds():
    bpy.context.view_layer.update()
    objs=[o for o in bpy.context.scene.objects if o.type=='MESH']
    pts=[o.matrix_world@v.co for o in objs for v in o.data.vertices]
    bb=[[min(v[i] for v in pts) for i in range(3)],[max(v[i] for v in pts) for i in range(3)]]
    return objs,bb

def validate_meshes(objs):
    for o in objs:
        assert all(math.isfinite(v) for p in o.data.vertices for v in p.co),o.name
        assert all(p.area>1e-13 for p in o.data.polygons),'Degenerate face: '+o.name
        counts=collections.Counter(tuple(sorted(e)) for p in o.data.polygons for e in p.edge_keys)
        assert all(n==2 for n in counts.values()),'Open or non-manifold solid: '+o.name
        assert not o.modifiers,'Unapplied modifier: '+o.name
        bm=bmesh.new();bm.from_mesh(o.data)
        assert abs(bm.calc_volume())>1e-13,'Zero volume: '+o.name
        bm.free()

def render(name,target,camera,res=(1440,1000),lens=50):
    global LOD
    selected_renders=[a for a in sys.argv if a.startswith('--render-target=')]
    if selected_renders and '--render-target='+name not in selected_renders:return
    LOD=0;objs,bb=bounds();lo,hi=map(Vector,bb);center=(lo+hi)*.5;size=max(hi-lo)
    floor=material('REVIEW ONLY studio floor',(.34,.36,.36),0,.80)
    box('REVIEW ONLY stage',(0,0,-.032),(100,100,.06),floor)
    bpy.ops.object.camera_add(location=camera);cam=bpy.context.object
    cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.lens=lens;bpy.context.scene.camera=cam
    for pos,power,r in [((-1.0,-1.6,2.2),450,2),((1.6,-.3,1.1),240,1.6),((-.3,1.3,1.6),300,1.8)]:
        bpy.ops.object.light_add(type='AREA',location=center+Vector(pos)*max(size,.7));o=bpy.context.object
        o.data.energy=power*max(size,.7)**2;o.data.shape='DISK';o.data.size=r*max(size,.7)
        o.rotation_euler=(Vector(target)-o.location).to_track_quat('-Z','Y').to_euler()
    sc=bpy.context.scene;sc.world=bpy.data.worlds.new('Neutral review environment');sc.world.use_nodes=True
    sc.world.node_tree.nodes.get('Background').inputs['Color'].default_value=(.30,.33,.35,1)
    sc.world.node_tree.nodes.get('Background').inputs['Strength'].default_value=.35
    sc.render.engine='CYCLES';sc.cycles.device='CPU';sc.cycles.samples=48;sc.cycles.use_denoising=False
    sc.render.resolution_x,sc.render.resolution_y=res;sc.render.resolution_percentage=100
    sc.view_settings.view_transform='AgX';sc.view_settings.exposure=-.65
    sc.render.image_settings.file_format='PNG';sc.render.filepath=str(REVIEW/(name+'.png'))
    bpy.ops.render.render(write_still=True)

def instance(asset,loc,yaw=0,size_xy=None):
    # Size variants operate on frame geometry X/Z only. The 20 mm rail depth and
    # easel footprint are unchanged, unlike uniform object scaling.
    path=OUT/asset/(asset+'.blend')
    with bpy.data.libraries.load(str(path),link=False) as (src,dst):dst.objects=src.objects
    imported=[o for o in dst.objects if o]
    for o in imported:bpy.context.collection.objects.link(o)
    bpy.context.view_layer.update()
    if size_xy is not None:
        sx,sz=size_xy
        for o in imported:
            if o.type!='MESH':continue
            # Apply existing transform before dimensions to avoid shrinking depth.
            mw=o.matrix_world.copy()
            o.data.transform(mw);o.matrix_world=Matrix.Identity(4)
            for v in o.data.vertices:v.co.x*=sx;v.co.z*=sz
        bpy.context.view_layer.update()
    m=Matrix.Translation(Vector(loc))@Matrix.Rotation(yaw,4,'Z')
    transforms=[(o,o.matrix_world.copy()) for o in imported]
    for o,original in transforms:o.matrix_world=m@original
    bpy.context.view_layer.update()

def compositions():
    global CURRENT_FOLDER
    CURRENT_FOLDER=REVIEW
    reset();palette(True)
    # Review-only counter is not part of either printer source.
    box('REVIEW ONLY neutral counter',(0,.026,.395),(1.75,.62,.79),oak,.006)
    box('REVIEW ONLY white counter surface',(0,0,.807),(1.78,.65,.034),warm,.005)
    instance('photo_print_black_compact',(-.57,.045,.824))
    instance('photo_print_white_mfp',(-.02,.045,.824))
    instance('photo_print_white_mfp',(.49,.045,.824))
    render('photo_print_counter_near_view',(0,-.02,1.02),(2.08,-3.18,2.13),(1600,1050),53)
    reset();instance('photo_honors_display_cabinet',(0,0,0))
    # Repeated assets are assembly instances. No photo content or identity data.
    for x,y,yaw,sz in [(-1.52,-.13,.04,(.95,.95)),(-1.10,-.13,-.04,(1.03,1.03)),(-.62,-.14,.02,(1.08,.95)),(.63,-.13,-.04,(1,1)),(1.25,-.14,.03,(1.08,.95))]:
        instance('photo_honors_lightwood_frame',(x,y,.859),yaw,sz)
    for x,y,yaw in [(-1.63,.082,.03),(-1.22,.079,-.02),(-.78,.08,.025),(.32,.075,-.03),(.80,.08,.02),(1.25,.09,-.04),(1.60,.08,-.05)]:
        instance('photo_honors_certificate_stand',(x,y,.859),yaw)
    instance('photo_honors_trophy_silhouette',(-.12,-.07,.859))
    for i in [0,1,3,4,5]:
        x=-1.8+(i+.5)*.60
        frame_size=(.68,1.31) if i==4 else (.92,.95)
        instance('photo_honors_lightwood_frame',(x,.02,1.772),-.025 if i%2 else .025,frame_size)
    render('photo_honors_cabinet_near_view',(0,-.01,1.19),(3.90,-6.00,3.05),(1700,1100),54)
    reset();instance('photo_print_white_mfp',(0,0,0))
    render('photo_print_white_mfp_close_view',(0,-.055,.244),(.86,-1.24,.87),(1280,1100),58)

selected=[a for a in sys.argv if a.startswith('--asset=')]
if '--render-only' not in sys.argv:
    for asset,build in ASSETS:
        if selected and '--asset='+asset not in selected:continue
        CURRENT_FOLDER=OUT/asset;CURRENT_FOLDER.mkdir(parents=True,exist_ok=True)
        for LOD in range(3):
            reset();palette('honors' in asset);build();objs,bb=bounds();validate_meshes(objs)
            for o in objs:
                o['scaleStatus']='Estimated from photos, not measured or manufacturer dimensions'
                o['reference']='User print and honors photos supplied 2026-11-03 02:16 UTC'
                o['assetId']=asset
            p=CURRENT_FOLDER/f'lod{LOD}_source.glb'
            bpy.ops.export_scene.gltf(filepath=str(p),export_format='GLB',export_extras=True,export_yup=True)
            rec={'asset':asset,'level':LOD,'triangles':sum(len(p.vertices)-2 for o in objs for p in o.data.polygons),'boundsBlenderXYZ':bb,'sizeBlenderXYZ':[bb[1][i]-bb[0][i] for i in range(3)],'meshParts':len(objs),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
            if LOD==0:
                blend=CURRENT_FOLDER/(asset+'.blend');bpy.ops.wm.save_as_mainfile(filepath=str(blend));rec['blendSha256']=hashlib.sha256(blend.read_bytes()).hexdigest()
            records.append(rec)
    report={'blender':bpy.app.version_string,'units':'m','referenceLibraryIds':['src_ref_2b3ca52f41b21d81c0bec42f5c59efdc','src_ref_f8318563838007cf69ccc6a8d3c77a47','src_ref_44e59b01a7ab2c5a0f13935519332fbd'],'referencePixelsViewed':True,'dimensions':'All dimensions are visual estimates. No surveyed or manufacturer dimensions claimed.','scope':'Six independent candidates only. Repeated white printers and two views of the honors cabinet share sources. No main-scene or runtime integration.','materials':'PBR factors; deterministic synthetic wood base-color map 384/192/96. No photo pixels, people, certificate text, names, logos, QR codes or fabricated award claims.','validation':'Each mesh checked for finite vertices, positive-area polygons, closed edge incidence, nonzero volume, and applied modifiers. Sources exclude review stages, cameras and lights.','render':'Cycles CPU review renders only, not browser or game acceptance.','records':records}
    path=REVIEW/'build_report.json'
    if selected and path.exists():
        old=json.loads(path.read_text());report['records']=[r for r in old['records'] if '--asset='+r['asset'] not in selected]+records
    path.write_text(json.dumps(report,indent=2))
if '--skip-render' not in sys.argv:compositions()
