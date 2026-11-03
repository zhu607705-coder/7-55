"""Six independent evidence-bounded sources representing seven photo-6 instruments.
Blender 4.3.2, metres. No photograph textures, brand labels or fabricated readouts.
Run blender -b -t 4 --python this_file.py [-- --skip-render | --render-only]
"""
import bpy, math, json, hashlib, sys, types
import numpy as np
from pathlib import Path
from mathutils import Vector, Matrix
ROOT=Path(__file__).resolve().parents[1]
w=types.ModuleType('mesh_helpers');w.__file__=str(ROOT/'scripts/build_photo_workshop.py')
exec(Path(w.__file__).read_text().split('selected=[a for a in sys.argv')[0],w.__dict__)
OUT=ROOT/'sources/models/photo_instruments'; REVIEW=ROOT/'review/photo_instruments'
OUT.mkdir(parents=True,exist_ok=True); REVIEW.mkdir(parents=True,exist_ok=True)
box=w.box; cyl=w.cylinder

def palette(folder):
    global ivory,grey,dark,glass,steel,key,red,green,yellow
    ivory=w.material('Warm light moulded fascia',(.66,.65,.59),0,.46)
    grey=w.material('Charcoal impact guard',(.16,.17,.17),0,.64)
    dark=w.material('Dark face polymer',(.045,.05,.05),0,.58)
    glass=w.material('Neutral unlit glass no content',(.009,.014,.018),.15,.19)
    steel=w.material('Satin connector metal',(.44,.47,.46),.82,.3)
    key=w.material('Light neutral keys',(.45,.46,.43),0,.54)
    red=w.material('Red terminal insulator',(.58,.025,.021),0,.45)
    green=w.material('Green channel and earth',(.035,.36,.20),0,.45)
    yellow=w.material('Yellow channel and socket ring',(.75,.55,.025),0,.44)
    n=32;rng=np.random.default_rng(800);a=np.ones((n,n,4),np.float32);a[:,:,:3]=(.50+rng.random((n,n,1))*.12)
    im=bpy.data.images.new('Authored polymer roughness tile',width=n,height=n,alpha=True)
    im.colorspace_settings.name='Non-Color';im.pixels.foreach_set(a.ravel());im.filepath_raw=str(folder/'synthetic_roughness.png');im.file_format='PNG';im.save();im.pack()
    for m in [ivory,grey,dark]:
        t=m.node_tree.nodes.new('ShaderNodeTexImage');t.image=im;t.extension='REPEAT'
        m.node_tree.links.new(t.outputs['Color'],m.node_tree.nodes.get('Principled BSDF').inputs['Roughness'])

def button(name,x,z,sx=.008,sz=.006,mat=None,y=-.004):
    return box(name,(x,y,z),(sx,.004,sz),mat or key,.001)

def dial(name,x,z,r=.010,mat=None,depth=.010,y=-.006):
    cyl(name+' collar',(x,y+.003,z),r*1.12,.003,dark,'Y')
    cyl(name+' raised knob',(x,y-.002,z),r,depth,mat or key,'Y')
    if w.LOD==0:
        for j in range(16):
            a=math.tau*j/16;cyl(name+' grip scallop',(x+math.cos(a)*r*.96,y-.003,z+math.sin(a)*r*.96),r*.05,depth*.78,mat or key,'Y',n=6)

def port(name,x,z,r=.0055,mat=None):
    cyl(name+' mounting collar',(x,-.003,z),r*1.3,.004,steel,'Y')
    cyl(name+' outer ring',(x,-.006,z),r,.006,mat or steel,'Y')
    cyl(name+' dark opening',(x,-.0092,z),r*.64,.0005,dark,'Y')
    # Inset dark disc is a closed cavity surrogate, not a fabricated invisible connector.

def screen(x,z,sx,sz):
    box('Screen recessed surround',(x,-.001,z),(sx+.008,.006,sz+.008),dark,.003)
    box('Blank unlit screen',(x,-.0045,z),(sx,.002,sz),glass,.0015)

def chassis(W,H,D,face,guard=True):
    box('Closed metal long chassis',(0,D/2,H/2),(W-.012,D-.014,H-.014),ivory,.006)
    box('Front gasket',(0,.005,H/2),(W-.007,.012,H-.007),grey,.005)
    box('Distinct front fascia',(0,-.0002,H/2),(W-.018,.005,H-.018),face,.004)
    if guard:
        for x in [-1,1]:
            for z in [.014,H-.014]:
                for y in [.014,D-.014]:box('Rounded protective corner',(x*(W/2-.014),y,z),(.028,.028,.028),grey,.007)
    for x in [-W*.32,W*.32]:
        for y in [D*.18,D*.82]:box('Rubber foot',(x,y,.004),(.024,.028,.008),dark,.002)

def vents(W,D,H,rows=4):
    if w.LOD<2:
        for side in [-1,1]:
            for iz in range(rows):
                for j in range(12 if w.LOD==0 else 8):
                    y=D*.27+j*D*.041;z=H*.29+iz*.010
                    box('Visible side ventilation dark recess',(side*(W/2-.0055),y,z),(.001,.009,.003),dark,.0004)

def dp800():
    W,H,D=.239,.157,.418;chassis(W,H,D,ivory)
    # 239 x 157 x 418 mm envelope; front controls extend to 429.5 total depth.
    screen(-.065,.092,.073,.067)
    for i in range(5):button('Five screen softkeys',-.097+i*.016,.050,.012,.006,grey)
    for i,m in enumerate([yellow,green,green]):
        button('Three coloured channel keys',-.019+i*.012,.118,.008,.010,m)
        button('Channel select keys',-.019+i*.012,.103,.008,.008)
    for row in range(2):
        for col in range(3):button('Central utility keys',-.013+col*.014,.063-row*.012,.010,.008)
    cx,cz=.069,.091
    dial('Main circular control',cx,cz,.018,ivory,depth=.010,y=-.0045)
    for i in range(10):
        a=math.tau*i/10
        o=button('Radial unlabelled numeric key',cx+math.cos(a)*.027,cz+math.sin(a)*.027,.010,.009,grey)
        o.rotation_euler.y=-a
    for a in [0,math.pi/2,math.pi,math.pi*1.5]:
        o=button('Outer navigation key',cx+math.cos(a)*.039,cz+math.sin(a)*.039,.012,.009,grey);o.rotation_euler.y=-a
    for i,m in enumerate([red,dark,green,red,dark,red,dark]):port('Lower binding post',-.055+i*.022,.024,.0058,m)
    box('Lower power switch recess',(-.095,-.002,.024),(.017,.006,.025),dark,.002)
    button('Rocker power switch',-.095,.024,.013,.020,ivory)
    for side in [-1,1]:
        for y in [.104,.314]:box('Side handle mounting block',(side*.115,y,.078),(.009,.019,.023),grey,.002)
        box('Long side carry handle',(side*.115,.209,.078),(.009,.210,.014),grey,.003)
        for row in [0,1]:
            for iz in range(4 if w.LOD<2 else 2):
                for j in range(19 if w.LOD==0 else 10):
                    y=.095+j*(.012 if w.LOD==0 else .024);z=.027+row*.073+iz*.006
                    # Polygonal dark recess surrogates retain explicit closed geometry.
                    cyl('Side perforation recess',(side*.114,y,z),.002,.001,dark,'X',n=[8,6,4][w.LOD])

def l1():
    W,H,D=.270,.106,.310;chassis(W,H,D,dark)
    screen(-.057,.059,.113,.063)
    for i in range(6):button('L1 horizontal screen softkeys',-.107+i*.020,.019,.012,.005)
    for row in range(5):
        for col in range(3):button('L1 compact right keypad',.019+col*.017,.083-row*.012,.010,.006)
    dial('L1 upper right rotary',.095,.081,.013)
    for z in [.054,.041]:button('L1 two right function keys',.095,z,.018,.006)
    port('L1 single visible lower round socket',.096,.020,.006)
    vents(W,D,H,4)

def l2():
    W,H,D=.282,.112,.325;chassis(W,H,D,ivory)
    screen(-.070,.063,.111,.060)
    for i in range(5):button('L2 screen bottom keys',-.117+i*.022,.023,.014,.005)
    # Circular control cluster directly alongside the screen, separate from right matrix.
    for z,r in [(.083,.010),(.058,.008)]:dial('L2 near-screen circular control',.014,z,r)
    for row in range(4):
        for col in range(4):button('L2 right matrix',.047+col*.019,.086-row*.014,.011,.006)
    for x in [.011,.041,.074,.106]:port('L2 lower visible round element',x,.020,.005)
    button('L2 visible red lower-left point',-.123,.016,.005,.005,red)
    vents(W,D,H,5)

def r1():
    W,H,D=.259,.114,.292;chassis(W,H,D,dark)
    screen(-.046,.062,.127,.073)
    # R1 is visibly a wider display with denser, narrower right keypad than L1.
    for row in range(6):
        for col in range(4):button('R1 dense rectangular matrix',.033+col*.014,.089-row*.010,.008,.0045)
    dial('R1 upper corner control',.100,.089,.010)
    port('R1 lower silver round socket',.078,.022,.007)
    port('R1 lower yellow-ringed socket',.105,.022,.007,yellow)
    for z in [.035,.054,.073,.092]:button('R1 left slim keys',-.116,z,.005,.009)
    vents(W,D,H,3)

def r2():
    W,H,D=.271,.118,.304;chassis(W,H,D,ivory)
    screen(-.066,.067,.113,.063)
    for i in range(5):button('R2 screen low softkeys',-.110+i*.021,.025,.012,.005)
    dial('R2 upper circular control',.015,.085,.012)
    dial('R2 central circular control',.018,.061,.0075)
    for row in range(4):
        for col in range(4):button('R2 tightly spaced right keys',.047+col*.017,.092-row*.013,.010,.005)
    for x,z,r in [(.017,.024,.005),(.047,.023,.005),(.079,.022,.006),(.108,.020,.006)]:port('R2 staggered lower round element',x,z,r)
    button('R2 lower-left red indicator',-.119,.021,.006,.005,red)
    # Photo shows more pronounced lower edge and asymmetrical right cheek.
    box('R2 lower fascia ledge',(0,-.001,.009),(.244,.013,.010),ivory,.002)
    box('R2 right sloped-cheek surrogate',(.123,.009,.045),(.014,.024,.052),grey,.005)
    vents(W,D,H,4)

def c1():
    W,H,D=.345,.243,.116;chassis(W,H,D,ivory,False)
    screen(-.040,.137,.237,.177)
    # Narrow pale control strip rather than a generic square-screen instrument.
    for z in [.214,.184]:
        for x in [.104,.135]:dial('C1 upper paired rotary',x,z,.008,ivory,depth=.006)
    for row in range(5):
        for col in range(2):button('C1 vertical key columns',.100+col*.018,.156-row*.015,.010,.006)
    for z in [.147,.112,.076]:dial('C1 right vertical rotary',.143,z,.0085,ivory,depth=.007)
    for x in [-.025,.025,.075,.125]:
        # Visible connection collars only; no invented labels/channel count claims.
        port('C1 visible lower connection silhouette',x,.026,.0065)
    button('C1 red power indicator',-.151,.026,.004,.006,red)
    for side in [-1,1]:
        box('C1 dark side grip',(side*.164,.054,.122),(.014,.065,.183),grey,.005)
    if w.LOD<2:
        for j in range(10):box('C1 top cooling slot',(-.10+j*.020,.064,.237),(.010,.040,.001),dark,.0003)

ASSETS=[('photo_instrument_dp800_series_candidate',dp800,'L3 + R3','Official DP800 family envelope; model suffix unconfirmed'),('photo_instrument_l1_dark_signal_candidate',l1,'L1','Estimated dimensions; signal/RF category candidate only'),('photo_instrument_l2_light_test_unknown',l2,'L2','Estimated dimensions; type and manufacturer unknown'),('photo_instrument_c1_wide_scope_candidate',c1,'C1','Estimated dimensions; oscilloscope category candidate only'),('photo_instrument_r1_dark_rf_candidate',r1,'R1','Estimated dimensions; RF category candidate only'),('photo_instrument_r2_light_test_unknown',r2,'R2','Estimated dimensions; independent from L2, same model unconfirmed')]

def render(name,group=False):
    objs,bb=w.bounds();lo,hi=map(Vector,bb);center=(lo+hi)/2;extent=max(hi-lo)
    box('Review ground',(0,0,-.015),(30,30,.02),w.material('Review ground material',(.25,.28,.30),0,.8))
    bpy.ops.object.camera_add(location=center+Vector((.64,-2.25,.77))*extent);cam=bpy.context.object;cam.data.type='ORTHO';cam.data.ortho_scale=extent*(1.22 if group else 1.46)
    cam.rotation_euler=(center-cam.location).to_track_quat('-Z','Y').to_euler();s=bpy.context.scene;s.camera=cam
    for v,p in [((-1.5,-2,3),500),((2,-1,2),350),((0,2,3),500)]:
        bpy.ops.object.light_add(type='AREA',location=center+Vector(v)*extent);o=bpy.context.object;o.data.energy=p*extent**2;o.data.size=extent*2;o.rotation_euler=(center-o.location).to_track_quat('-Z','Y').to_euler()
    s.world=bpy.data.worlds.new('Review world');s.world.use_nodes=True;s.world.node_tree.nodes['Background'].inputs['Strength'].default_value=.4
    s.render.engine='CYCLES';s.cycles.device='CPU';s.cycles.samples=32;s.cycles.use_denoising=False
    s.render.resolution_x=1800 if group else 1100;s.render.resolution_y=1000 if group else 900;s.render.resolution_percentage=100
    s.render.image_settings.file_format='PNG';s.view_settings.view_transform='AgX';s.view_settings.exposure=-.75;s.render.filepath=str(REVIEW/(name+'.png'));bpy.ops.render.render(write_still=True)

if '--render-only' not in sys.argv and '--composition-only' not in sys.argv:
    selection=next((a.split('=',1)[1] for a in sys.argv if a.startswith('--asset=')),None)
    records=json.loads((REVIEW/'build_report.json').read_text())['records'] if selection and (REVIEW/'build_report.json').exists() else []
    if selection:records=[r for r in records if r['asset']!=selection]
    for asset,build,photo,status in ASSETS:
        if selection and asset!=selection:continue
        folder=OUT/asset;folder.mkdir(exist_ok=True)
        for lod in range(3):
            w.reset();w.LOD=lod;palette(folder);build();objs,bb=w.bounds();checks=w.validate_meshes(objs)
            for o in objs:
                o['assetId']=asset;o['photoPosition']=photo;o['evidenceStatus']=status;o['dimensionsUnit']='m'
                if not o.data.uv_layers:w.planar_uv(o)
            p=folder/f'lod{lod}_source.glb';bpy.ops.export_scene.gltf(filepath=str(p),export_format='GLB',export_extras=True)
            records.append({'asset':asset,'photoPosition':photo,'evidenceStatus':status,'level':lod,'triangles':sum(len(f.vertices)-2 for o in objs for f in o.data.polygons),'meshParts':len(objs),'boundsBlenderXYZ':bb,'sizeBlenderXYZ':[bb[1][i]-bb[0][i] for i in range(3)],'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'validation':checks})
            if lod==0:bpy.ops.wm.save_as_mainfile(filepath=str(folder/(asset+'.blend')))
    for asset,*_ in ASSETS:
        counts=[r['triangles'] for r in records if r['asset']==asset];assert counts[0]>counts[1]>counts[2],(asset,counts)
    (REVIEW/'build_report.json').write_text(json.dumps({'blender':bpy.app.version_string,'units':'metres','referenceViewed':'Seven native photo crops, official DP800 drawing and distributor front image','sourceCount':6,'instanceCount':7,'materialPolicy':'Packed authored roughness tile; PBR factors. No photograph pixels.','scope':'Separate instruments only, no modification of legacy sources or main scene.','records':records},indent=2))
if '--skip-render' not in sys.argv:
    for asset,*_ in ASSETS:
        if '--composition-only' in sys.argv:break
        selection=next((a.split('=',1)[1] for a in sys.argv if a.startswith('--asset=')),None)
        if selection and asset!=selection:continue
        bpy.ops.wm.open_mainfile(filepath=str(OUT/asset/(asset+'.blend')));render(asset)
    w.reset();w.LOD=0
    instances=[]
    for tag,idx,pos,yaw in [('L3',0,(-.42,.025,0),-.025),('L2',2,(-.434,.041,.157),-.018),('L1',1,(-.426,.052,.269),-.031),('C1',3,(.016,-.025,0),.014),('R3',0,(.422,.002,0),.035),('R2',5,(.430,.024,.157),.016),('R1',4,(.442,.044,.275),.027)]:
        asset=ASSETS[idx][0];p=OUT/asset/(asset+'.blend')
        with bpy.data.libraries.load(str(p),link=False) as(src,dst):dst.objects=src.objects
        mat=Matrix.Translation(Vector(pos))@Matrix.Rotation(yaw,4,'Z')
        for o in dst.objects:
            if o:bpy.context.collection.objects.link(o)
        bpy.context.view_layer.update()
        transforms=[(o,o.matrix_world.copy()) for o in dst.objects if o]
        for o,original in transforms:o.matrix_world=mat@original
        bpy.context.view_layer.update()
        instances.append({'instanceId':tag,'assetId':asset,'position':pos,'rotationEuler':[0,0,yaw],'scale':[1,1,1],'sourceSha256':hashlib.sha256(p.read_bytes()).hexdigest()})
    (OUT/'comparison_instances.json').write_text(json.dumps({'purpose':'Seven-instrument photo-aligned review group, NOT final electronics bench layout','units':'m','dimensions':'DP800 family real envelope; remaining five photo-relative estimates','instances':instances},indent=2))
    bpy.ops.wm.save_as_mainfile(filepath=str(REVIEW/'seven_instrument_comparison.blend'));render('seven_instrument_comparison',True)
