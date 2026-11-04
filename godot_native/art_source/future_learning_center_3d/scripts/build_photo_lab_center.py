"""Photo 3 central laboratory furniture. Blender 4.3.2; metres are visual estimates.
Run: blender -b --factory-startup -t 4 --python scripts/build_photo_lab_center.py
Flags: --skip-render, --render-only, --composition-only, --asset=<id>.
Source photographs are reference only, never texture inputs. No main-scene changes.
"""
import bpy, bmesh, math, json, hashlib, sys, collections
import numpy as np
from pathlib import Path
from mathutils import Vector, Matrix

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'sources/models/photo_lab_center'
REVIEW=ROOT/'review/photo_lab_center'
OUT.mkdir(parents=True,exist_ok=True);REVIEW.mkdir(parents=True,exist_ok=True)
LOD=0;CURRENT_FOLDER=OUT;records=[]


def material(name,color,metal=0,rough=.5):
    m=bpy.data.materials.new(name);m.use_nodes=True;m.diffuse_color=(*color,1)
    p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1)
    p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=rough
    return m


def palette():
    global wood,black,rubber,board,paper
    black=material('Charcoal powder coated steel',(.035,.041,.043),.3,.5)
    rubber=material('Black chair and case polymer',(.012,.015,.017),0,.72)
    board=material('Warm neutral plywood liner',(.34,.25,.16),0,.67)
    paper=material('Unmarked warm grey storage box',(.58,.55,.48),0,.86)
    wood=material('Pale wood laminate',(.58,.47,.32),0,.58)
    n=128;v,u=np.meshgrid(np.arange(n)/n,np.arange(n)/n,indexing='ij')
    grain=.5+.16*np.sin(u*151+np.sin(v*8)*.8)+.10*np.sin(u*501+v*4)
    pixels=np.ones((n,n,4),np.float32)
    for k,(a,b) in enumerate(zip((.48,.37,.24),(.65,.55,.39))):pixels[:,:,k]=a+grain*(b-a)
    im=bpy.data.images.new('Synthetic pale laminate grain',width=n,height=n,alpha=True)
    im.pixels.foreach_set(pixels.ravel());im.filepath_raw=str(CURRENT_FOLDER/'synthetic_wood.png');im.file_format='PNG';im.save();im.pack()
    tex=wood.node_tree.nodes.new('ShaderNodeTexImage');tex.image=im
    wood.node_tree.links.new(tex.outputs['Color'],wood.node_tree.nodes.get('Principled BSDF').inputs['Base Color'])
    wood['textureProvenance']='Authored mathematical 128px grain, no photo pixels. Metallic and roughness factors.'

def finish(o,name,mat,smooth=False):
    o.name=name;o['part']=name
    if mat:o.data.materials.append(mat)
    for p in o.data.polygons:p.use_smooth=smooth
    return o


def mesh(name,verts,faces,mat,smooth=False):
    me=bpy.data.meshes.new(name);me.from_pydata(verts,[],faces);me.update()
    o=bpy.data.objects.new(name,me);bpy.context.collection.objects.link(o)
    return finish(o,name,mat,smooth)


def active(o):
    bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o


def bevel(o,width,segments=None):
    bpy.context.view_layer.update();active(o)
    m=o.modifiers.new('Manufactured rounded edge','BEVEL');m.width=min(width,.45*min(o.dimensions))
    m.segments=segments or [3,2,1][LOD]
    bpy.ops.object.modifier_apply(modifier=m.name)
    n=o.modifiers.new('Weighted surface normals','WEIGHTED_NORMAL');n.keep_sharp=True
    bpy.ops.object.modifier_apply(modifier=n.name)


def planar_uv(o,repeat=None):
    uv=o.data.uv_layers.new(name='UVMap');pts=[v.co for v in o.data.vertices]
    mn=Vector([min(v[i] for v in pts) for i in range(3)]);ext=Vector([max(v[i] for v in pts) for i in range(3)])-mn
    for p in o.data.polygons:
        axes=(0,1) if abs(p.normal.z)>.5 else ((0,2) if abs(p.normal.y)>.5 else (1,2))
        for li in p.loop_indices:
            c=o.data.vertices[o.data.loops[li].vertex_index].co
            uv.data[li].uv=tuple((c[i]-mn[i])/(repeat or max(ext[i],.000001)) for i in axes)


def box(name,loc,size,mat,edge=0,repeat=None):
    bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.dimensions=size
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);finish(o,name,mat)
    if edge:bevel(o,edge)
    planar_uv(o,repeat);return o


def cylinder(name,loc,r,depth,mat,axis='Z',r2=None,n=None):
    bpy.ops.mesh.primitive_cone_add(vertices=n or [40,20,10][LOD],radius1=r,radius2=r if r2 is None else r2,depth=depth,location=loc)
    o=bpy.context.object
    if axis=='X':o.rotation_euler.y=math.pi/2
    if axis=='Y':o.rotation_euler.x=math.pi/2
    finish(o,name,mat,True)
    # Preserve flat caps while smooth-shading the curved side.
    for p in o.data.polygons:
        if len(p.vertices)>4:p.use_smooth=False
    return o


def bar_between(name,a,b,r,mat,n=None):
    a,b=Vector(a),Vector(b);o=cylinder(name,(a+b)/2,r,(b-a).length,mat,n=n)
    o.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler();return o


def lathe(name,x,y,rings,mat,n=None,flutes=0):
    n=n or [48,24,12][LOD];vs=[]
    for z,r in rings:
        for i in range(n):
            a=math.tau*i/n;rr=r*(1+flutes*math.cos(a*12));vs.append((x+rr*math.cos(a),y+rr*math.sin(a),z))
    fs=[tuple(reversed(range(n))),tuple(range((len(rings)-1)*n,len(rings)*n))]
    for j in range(len(rings)-1):
        for i in range(n):a=j*n+i;b=j*n+(i+1)%n;fs.append((a,b,b+n,a+n))
    return mesh(name,vs,fs,mat,True)


def table():
    box('Thin rectangular pale laminate top',(0,0,.735),(2.2,1.0,.03),wood,.003)
    for x in [-1.035,1.035]:
        for y in [-.435,.435]:
            box('Square steel leg',(x,y,.36),(.055,.055,.72),black,.0018)
            box('Black floor glide',(x,y,.005),(.052,.052,.01),rubber,.001)
    for y in [-.425,.425]:box('Inset under top long rail',(0,y,.695),(2.08,.033,.05),black,.001)
    for x in [-1.025,1.025]:box('Inset under top short rail',(x,0,.695),(.033,.84,.05),black,.001)

def chair():
    box('Broad rounded seat',(0,-.015,.445),(.49,.46,.065),rubber,.027)
    # Solid bent back panel, low broad silhouette, no headrest or guessed mesh holes.
    n=[20,12,6][LOD];vs=[]
    for layer in [0,.026]:
        for j in range(n+1):
            z=.48+j/n*.43
            for i in range(n+1):
                t=i/n;w=.45+.045*j/n
                vs.append(((t-.5)*w,.19+.055*j/n-.022*math.sin(math.pi*t)+layer,z))
    N=(n+1)**2;fs=[]
    for j in range(n):
        for i in range(n):
            a=j*(n+1)+i;fs.extend([(a,a+1,a+n+2,a+n+1),(a+N,a+n+1+N,a+n+2+N,a+1+N)])
    perimeter=list(range(n+1))+[j*(n+1)+n for j in range(1,n+1)]+[n*(n+1)+i for i in range(n-1,-1,-1)]+[j*(n+1) for j in range(n-1,0,-1)]
    for a,b in zip(perimeter,perimeter[1:]+perimeter[:1]):fs.append((a,a+N,b+N,b))
    o=mesh('Broad gently curved closed back',vs,fs,rubber,True)
    active(o);bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.mesh.normals_make_consistent(inside=False);bpy.ops.object.mode_set(mode='OBJECT');planar_uv(o)
    for x in [-.265,.265]:
        box('Arm pad',(x,-.015,.635),(.055,.31,.038),rubber,.016)
        box('Rear arm upright',(x,.115,.535),(.035,.035,.18),rubber,.008)
        box('Arm lower join',(x*.83,.13,.452),(.12,.035,.035),rubber,.007)
    cylinder('Seat post',(0,0,.26),.028,.30,black)
    for i in range(5):
        a=math.tau*i/5;end=Vector((.30*math.cos(a),.30*math.sin(a),.075))
        bar_between('Five star leg',(0,0,.14),end,.022,rubber)
        cylinder('Caster swivel',end,.014,.055,black)
        for side in [-1,1]:cylinder('Twin caster',(end.x+side*.018,end.y,.032),.032,.021,rubber,'X')

def shelf():
    # Truncated three-bay observed segment, not an invented full room-width shelf.
    for x in [-.915,-.305,.305,.915]:
        for y in [-.20,.20]:box('Thin square vertical frame',(x,y,1.10),(.025,.025,2.20),black,.001)
    for z in [.04,.48,.94,1.42,1.91,2.19]:
        box('Thin grey shelf tray',(0,0,z),(1.84,.425,.022),black,.001)
    for x in [-.61,0,.61]:
        for z in [.71,1.66]:
            box('Wood cubby back',(x,.194,z),(.585,.018,.445),board,.001)
            for dx in [-.288,.288]:box('Wood cubby side',(x+dx,0,z),(.016,.385,.445),board,.001)

def storage():
    box('Unmarked storage box',(0,0,.105),(.35,.26,.21),paper,.004)
    box('Separate shallow lid',(0,0,.211),(.36,.27,.022),paper,.003)

def case():
    box('Tall transport case body',(0,0,.19),(.62,.40,.36),rubber,.027)
    box('Wide lid',(0,0,.39),(.635,.415,.075),rubber,.023)
    box('Lid perimeter joint',(0,0,.352),(.64,.42,.014),black,.005)
    for x in [-.19,.19]:
        box('Front latch',(x,-.218,.345),(.049,.018,.075),black,.006)
    for x in [-.09,.09]:box('Handle mount',(x,-.221,.245),(.027,.027,.06),black,.005)
    box('Carry grip',(0,-.24,.26),(.20,.028,.028),rubber,.009)
    if LOD<2:
        for x in [-.235,.235]:box('Protective raised vertical rib',(x,-.205,.19),(.025,.014,.25),rubber,.006)

def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True);bpy.context.preferences.filepaths.save_version=0
    bpy.context.scene.unit_settings.system='METRIC'


def bounds():
    bpy.context.view_layer.update();objs=[o for o in bpy.context.scene.objects if o.type=='MESH']
    pts=[o.matrix_world@v.co for o in objs for v in o.data.vertices]
    bb=[[min(v[i] for v in pts) for i in range(3)],[max(v[i] for v in pts) for i in range(3)]]
    return objs,bb


def validate_meshes(objs):
    stats={'nonFiniteVertices':0,'degenerateFaces':0,'nonManifoldEdges':0,'inconsistentEdgeWinding':0,'inwardSolids':0,'unappliedModifiers':0}
    for o in objs:
        me=o.data;me.update()
        stats['nonFiniteVertices']+=sum(not all(math.isfinite(v) for v in p.co) for p in me.vertices)
        stats['degenerateFaces']+=sum(p.area<=1e-13 for p in me.polygons)
        edge_count=collections.Counter(tuple(sorted(e)) for p in me.polygons for e in p.edge_keys)
        edge_signs=collections.defaultdict(list)
        for p in me.polygons:
            verts=list(p.vertices)
            for a,b in zip(verts,verts[1:]+verts[:1]):edge_signs[tuple(sorted((a,b)))].append(a<b)
        stats['nonManifoldEdges']+=sum(n!=2 for n in edge_count.values())
        stats['inconsistentEdgeWinding']+=sum(len(v)!=2 or v[0]==v[1] for v in edge_signs.values())
        bm=bmesh.new();bm.from_mesh(me);vol=bm.calc_volume(signed=True);bm.free()
        stats['inwardSolids']+=int(vol<=0);stats['unappliedModifiers']+=len(o.modifiers)
        assert all(v==0 for v in stats.values()),(o.name,stats,vol)
    return stats


def render(name,composition=False):
    objs,bb=bounds();lo,hi=map(Vector,bb);center=(lo+hi)/2;size=max(hi-lo)
    floor=material('REVIEW ONLY neutral floor',(.35,.37,.37),0,.85)
    box('REVIEW ONLY floor',(0,0,lo.z-.023),(100,100,.04),floor)
    if composition:target=Vector((.35,.30,1.03));cam_pos=Vector((.12,-4.3,1.87));lens=30
    elif name=='photo_workshop_square_hole_board':target=center;cam_pos=center+Vector((.90,-1.80,.55))*size;lens=53
    else:target=center;cam_pos=center+Vector((1.15,-1.90,1.20))*size*1.12;lens=53
    bpy.ops.object.camera_add(location=cam_pos);cam=bpy.context.object;cam.data.lens=lens
    cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();bpy.context.scene.camera=cam
    extent=max(size,.40)
    for pos,power,rad in [((-1.6,-1.6,2.6),440,2.0),((1.8,.3,2.2),340,1.8),((-.5,2.3,1.5),360,1.4)]:
        bpy.ops.object.light_add(type='AREA',location=center+Vector(pos)*extent);o=bpy.context.object
        o.data.energy=power*extent*extent;o.data.shape='DISK';o.data.size=rad*extent
        o.rotation_euler=(target-o.location).to_track_quat('-Z','Y').to_euler()
    sc=bpy.context.scene;sc.world=bpy.data.worlds.new('Review soft world');sc.world.use_nodes=True
    sc.world.node_tree.nodes.get('Background').inputs['Color'].default_value=(.32,.36,.40,1)
    sc.world.node_tree.nodes.get('Background').inputs['Strength'].default_value=.40
    sc.render.engine='CYCLES';sc.cycles.device='CPU';sc.cycles.samples=40 if composition else 24;sc.cycles.use_denoising=False
    sc.render.resolution_x=1440 if composition else 900;sc.render.resolution_y=1000 if composition else 720
    sc.render.resolution_percentage=100;sc.view_settings.view_transform='AgX';sc.view_settings.exposure=-.6
    sc.render.image_settings.file_format='PNG';sc.render.filepath=str(REVIEW/(name+'.png'));bpy.ops.render.render(write_still=True)


ASSETS=[('photo_lab_center_four_leg_table',table),('photo_lab_center_black_task_chair',chair),('photo_lab_center_open_shelf',shelf),('photo_lab_center_plain_storage_box',storage),('photo_lab_center_black_transit_case',case)]

def instance(asset,loc,yaw=0,group='photo_lab_center',variant=None):
    path=ROOT/'sources/models'/group/asset/(asset+'.blend')
    with bpy.data.libraries.load(str(path),link=False) as(src,dst):dst.objects=src.objects
    imported=[o for o in dst.objects if o]
    for o in imported:bpy.context.collection.objects.link(o)
    bpy.context.view_layer.update()
    transforms=[(o,o.matrix_world.copy()) for o in imported]
    m=Matrix.Translation(Vector(loc))@Matrix.Rotation(yaw,4,'Z')
    for o,original in transforms:
        o.matrix_world=m@original
        o['instanceSource']=asset
        if variant and o.type=='MESH':
            o.data=o.data.copy()
            for i in range(len(o.data.materials)):o.data.materials[i]=rubber
    return {'assetId':asset,'sourcePath':str(path.relative_to(ROOT)),'position':loc,'rotationEuler':[0,0,yaw],'scale':[1,1,1],'materialOverrides':{'allSlots':'Black chair and case polymer'} if variant else {},'notes':variant or 'Photographic placement estimate','sourceSha256':hashlib.sha256(path.read_bytes()).hexdigest()}

def composition():
    global CURRENT_FOLDER
    reset();CURRENT_FOLDER=OUT/ASSETS[0][0];palette();layout=[]
    layout.append(instance(ASSETS[0][0],(0,0,0)))
    layout.append(instance(ASSETS[1][0],(-.60,-.86,0),math.pi))
    layout.append(instance(ASSETS[2][0],(1.52,.69,0),-math.pi/2))
    for z in [.052,.492]:layout.append(instance(ASSETS[3][0],(1.48,.25,z)))
    layout.append(instance(ASSETS[3][0],(.73,.12,.75)))
    layout.append(instance(ASSETS[4][0],(1.43,-.57,0),-.1))
    layout.append(instance('photo_monitor_stand',(-.47,.16,.75),math.pi,'photo_desktop','Black shell and stand only in this composition'))
    layout.append(instance('photo_keyboard',(-.47,.38,.75),math.pi,'photo_desktop','Neutral black unprinted input device'))
    layout.append(instance('photo_mouse',(-.78,.39,.75),math.pi,'photo_desktop','Neutral black unprinted input device'))
    for i,row in enumerate(layout):row['instanceId']='lab_center_%02d'%i
    (OUT/'composition.json').write_text(json.dumps({'units':'metres','coordinateSystem':'Blender Z-up','scope':'Major visible furniture only. Obscured instruments and uncertain functions omitted. Not complete equipment reconstruction.','instances':layout},indent=2))
    bpy.context.view_layer.update();bpy.ops.wm.save_as_mainfile(filepath=str(REVIEW/'photo_lab_center_composition.blend'))
    render('photo_lab_center_composition',True)

if '--composition-render-only' in sys.argv:
    bpy.ops.wm.open_mainfile(filepath=str(REVIEW/'photo_lab_center_composition.blend'));render('photo_lab_center_composition',True);raise SystemExit
if '--composition-only' in sys.argv:composition();raise SystemExit
if '--render-only' not in sys.argv:
    for asset,build in ASSETS:
        CURRENT_FOLDER=OUT/asset;CURRENT_FOLDER.mkdir(parents=True,exist_ok=True)
        for LOD in range(3):
            reset();palette();build();objs,bb=bounds();validation=validate_meshes(objs)
            for o in objs:o['assetId']=asset;o['scaleStatus']='Photographic estimate, not measured';o['reference']='User photo 3, 2026-11-03, viewed original; no pixels copied'
            p=CURRENT_FOLDER/f'lod{LOD}_source.glb';bpy.ops.export_scene.gltf(filepath=str(p),export_format='GLB',export_extras=True,export_yup=True)
            records.append({'asset':asset,'level':LOD,'triangles':sum(len(p.vertices)-2 for o in objs for p in o.data.polygons),'meshParts':len(objs),'boundsBlenderXYZ':bb,'sizeBlenderXYZ':[bb[1][i]-bb[0][i] for i in range(3)],'validation':validation,'materials':sorted({m.name for o in objs for m in o.data.materials}),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
            if LOD==0:bpy.ops.wm.save_as_mainfile(filepath=str(CURRENT_FOLDER/(asset+'.blend')))
    for asset,_ in ASSETS:
        ts=[r['triangles'] for r in records if r['asset']==asset];assert ts[0]>ts[1]>ts[2],ts
    (REVIEW/'build_report.json').write_text(json.dumps({'blender':bpy.app.version_string,'units':'m','reference':'63e86027f06d235dc7ce8f8d4806b80c.jpg, visual reference only, not included','dimensions':'Estimated metres, no manufacturer or survey claim','scope':'Five independent furniture/prop sources; no scene or runtime edits','materials':'Packed 128px synthetic grain and PBR factors; no labels, brands or image pixels','meshValidation':'Each part is a closed outward solid. Part intersections at physical joints are permitted.','records':records},indent=2))
if '--skip-render' not in sys.argv:
    for asset,_ in ASSETS:
        bpy.ops.wm.open_mainfile(filepath=str(OUT/asset/(asset+'.blend')));render(asset)
    composition()
