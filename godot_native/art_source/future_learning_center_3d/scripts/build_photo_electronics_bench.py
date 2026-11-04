"""Photo 6 electronics bench. Actual Blender sources; no photograph pixels baked.
blender -b --factory-startup -t 4 --python scripts/build_photo_electronics_bench.py
Optional --skip-render, --render-only. Dimensions are photo estimates.
"""
import bpy, math, json, hashlib, sys, types
import numpy as np
from pathlib import Path
from mathutils import Vector, Matrix
ROOT=Path(__file__).resolve().parents[1]
# Reuse established mesh construction and validation without executing its build entrypoint.
w=types.ModuleType('workshop_helpers');w.__file__=str(ROOT/'scripts/build_photo_workshop.py')
exec(Path(w.__file__).read_text().split('selected=[a for a in sys.argv')[0],w.__dict__)
OUT=ROOT/'sources/models/photo_electronics'; REVIEW=ROOT/'review/photo_electronics'
OUT.mkdir(parents=True,exist_ok=True);REVIEW.mkdir(parents=True,exist_ok=True)
box=w.box; cyl=w.cylinder

def palette(folder):
    global grey,dark,steel,ivory,screen,wood,green,button
    grey=w.material('Graphite grey enamel',(.115,.145,.148),.45,.43)
    dark=w.material('Dark polymer',(.014,.019,.021),0,.58)
    steel=w.material('Satin metal pulls',(.51,.53,.50),.8,.27)
    ivory=w.material('Neutral warm grey instrument housing',(.63,.64,.59),.08,.48)
    screen=w.material('Blank dark glass no display content',(.008,.014,.018),.12,.2)
    wood=w.material('Synthetic warm wood',(.51,.30,.12),0,.45)
    green=w.material('Green cutting mat',(.017,.19,.145),0,.82)
    button=w.material('Neutral button polymer',(.25,.28,.27),0,.5)
    n=128; yy,xx=np.mgrid[0:n,0:n]; rng=np.random.default_rng(63)
    grain=.9+.06*np.sin(yy*.35+np.sin(xx*.045))+.03*rng.random((n,n))
    for mat,name,pix in [(wood,'synthetic_wood_tile',np.stack([grain*.62,grain*.39,grain*.19],-1)),(green,'synthetic_grid_tile',np.where(((xx%16<1)|(yy%16<1))[:,:,None],np.array([.21,.45,.37]),np.array([.027,.25,.18]))+np.zeros((n,n,3)))]:
        im=bpy.data.images.new(name,width=n,height=n,alpha=True); rgba=np.ones((n,n,4),np.float32);rgba[:,:,:3]=pix
        im.pixels.foreach_set(rgba.ravel());im.filepath_raw=str(folder/(name+'.png'));im.file_format='PNG';im.save();im.pack()
        t=mat.node_tree.nodes.new('ShaderNodeTexImage');t.image=im;t.extension='REPEAT'
        mat.node_tree.links.new(t.outputs['Color'],mat.node_tree.nodes.get('Principled BSDF').inputs['Base Color'])
        mat['provenance']='Authored repeating 128-square tile, no photo pixels or text.'

def bench():
    box('Thick wood top',(0,0,.778),(1.65,.76,.048),wood,.009, .38)
    for x in [-.731,.731]:
        for y in [-.29,.29]:
            box('Square steel leg',(x,y,.372),(.064,.064,.744),grey,.003)
            box('Dark foot cap',(x,y,.014),(.068,.068,.028),dark,.003)
        box('Lower side stretcher',(x,0,.19),(.045,.59,.055),grey,.002)
    box('Rear apron',(0,.29,.68),(1.46,.045,.15),grey,.003)
    box('Rear low stretcher',(0,.29,.19),(1.46,.045,.055),grey,.002)
    for x in [-.365,.365]:
        box('Closed drawer cabinet',(x,0,.675),(.711,.595,.153),grey,.004)
        box('Drawer reveal',(x,-.304,.671),(.687,.009,.132),dark,.002)
        box('Drawer front',(x,-.312,.671),(.674,.018,.122),grey,.003)
        box('Recessed pull dark well',(x,-.324,.677),(.132,.006,.040),dark,.004)
        for dx in [-.071,.071]:box('Pull side',(x+dx,-.329,.677),(.01,.012,.05),steel,.002)
        for dz in [-.023,.023]:box('Pull lip',(x,-.329,.677+dz),(.143,.012,.008),steel,.002)
        cyl('Small lock',(x,-.327,.717),.008,.006,steel,'Y')
        if w.LOD<2:box('Lock slot',(x,-.331,.717),(.0017,.001,.007),dark)

def frame():
    # Local base is bench top. Square-hole board geometry is a separate reused source.
    for x in [-.809,.809]:box('Back upright',(x,.335,.635),(.04,.048,1.27),grey,.002)
    for z in [.57,1.27]:
        box('Rear shelf',(0,.20,z),(1.65,.32,.025),grey,.003)
        box('Shelf front folded lip',(0,.044,z+.015),(1.65,.022,.050),grey,.002)
        for x in [-.81,.81]:box('Shelf side rim',(x,.20,z+.038),(.025,.32,.06),grey,.002)
    box('Top rear rail',(0,.345,1.27),(1.65,.035,.045),grey,.002)

def instrument(tall=False):
    W,H,D=(.39,.285,.21) if tall else (.34,.153,.27)
    box('Neutral enclosed instrument shell',(0,.018,H/2),(W,D,H),ivory,.008)
    box('Front dark gasket',(0,-D/2+.006,H/2),(W-.016,.012,H-.016),dark,.006)
    box('Front panel',(0,-D/2-.002,H/2),(W-.024,.009,H-.024),ivory,.004)
    sx=-W*.12; sw=W*.60; sh=H*.77 if tall else H*.67
    box('Dark screen bezel',(sx,-D/2-.009,H*.54),(sw,.012,sh),dark,.005)
    box('Unlit blank glass',(sx,-D/2-.016,H*.54),(sw-.014,.003,sh-.014),screen,.003)
    for col in range(2):
        for row in range(7 if tall else 4):
            box('Unlabelled rectangular key',(W*.245+col*.025,-D/2-.013,H*.80-row*(.024 if tall else .021)),(.016,.008,.010),button,.002)
    for z in ([.055,.106] if tall else [.041]):cyl('Neutral control dial',(W*.31,-D/2-.020,z),.016,.018,button,'Y')
    if w.LOD<2:
        for x in [-W*.32,W*.32]:
            for y in [-D*.28,D*.32]:box('Rubber foot',(x,y,.004),(.035,.038,.008),dark,.002)
        for z in [H*.35+i*.012 for i in range(5)]:box('Side ventilation recess',(W/2+.0005,.045,z),(.001,.095,.003),dark)
    # No inferred connectors, cable functions, logos, brands or screen readings.

def mat():box('Rounded green cutting mat',(0,0,.002),(.60,.40,.004),green,.0018,.20)

def bin():
    box('Open bin floor',(0,0,.007),(.19,.12,.014),dark,.004)
    for x in [-.092,.092]:box('Open bin side wall',(x,0,.037),(.009,.12,.074),dark,.003)
    box('Open bin rear wall',(0,.055,.045),(.19,.01,.09),dark,.003)
    box('Low front retaining lip',(0,-.055,.023),(.19,.01,.046),dark,.003)
    if w.LOD<2:
        for x in [-.061,.061]:box('Moulded underside runner',(x,0,.004),(.007,.105,.007),dark,.002)

ASSETS=[('photo_electronics_drawer_bench',bench),('photo_electronics_back_shelf_frame',frame),('photo_electronics_wide_instrument_shell',lambda:instrument(False)),('photo_electronics_tall_instrument_shell',lambda:instrument(True)),('photo_electronics_green_cutting_mat',mat),('photo_electronics_open_bin',bin)]

def render(name,composition=False):
    objs,bb=w.bounds();lo,hi=map(Vector,bb);center=(lo+hi)/2;extent=max(hi-lo)
    box('REVIEW floor',(0,0,lo.z-.025),(100,100,.04),w.material('Review floor',(.32,.34,.33),0,.8))
    target=Vector((0,0,1.02)) if composition else center
    pos=Vector((2.65,-4.9,2.7)) if composition else center+Vector((1.05,-1.8,.95))*extent*1.12
    bpy.ops.object.camera_add(location=pos);cam=bpy.context.object;cam.data.lens=43 if composition else 53
    cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();s=bpy.context.scene;s.camera=cam
    for p,power in [((-1.5,-2,3),400),((2,-.5,2),280),((0,2,3),300)]:
        bpy.ops.object.light_add(type='AREA',location=center+Vector(p)*extent);o=bpy.context.object;o.data.energy=power*extent**2;o.data.shape='DISK';o.data.size=2*extent;o.rotation_euler=(target-o.location).to_track_quat('-Z','Y').to_euler()
    s.world=bpy.data.worlds.new('Review world');s.world.use_nodes=True;s.world.node_tree.nodes.get('Background').inputs['Strength'].default_value=.35
    s.render.engine='CYCLES';s.cycles.device='CPU';s.cycles.samples=40 if composition else 24;s.cycles.use_denoising=False
    s.render.resolution_x=1500 if composition else 900;s.render.resolution_y=1000 if composition else 700;s.render.resolution_percentage=100
    s.view_settings.view_transform='AgX';s.view_settings.exposure=-.7;s.render.filepath=str(REVIEW/(name+'.png'));s.render.image_settings.file_format='PNG';bpy.ops.render.render(write_still=True)

instances=[]
def instance(group,asset,loc,variant=None):
    path=ROOT/'sources/models'/group/asset/(asset+'.blend')
    with bpy.data.libraries.load(str(path),link=False) as(src,dst):dst.objects=src.objects
    for o in dst.objects:
        if o:
            bpy.context.collection.objects.link(o);o.location+=Vector(loc)
            if variant=='grey_board':
                for i,m in enumerate(o.data.materials):
                    if m and 'Black powder' in m.name:o.data.materials[i]=grey
    instances.append({'instanceId':f'{asset}_{len(instances):02d}','assetId':asset,'sourcePath':str(path.relative_to(ROOT)),'sourceSha256':hashlib.sha256(path.read_bytes()).hexdigest(),'position':loc,'rotationEuler':[0,0,0],'scale':[1,1,1],'materialOverrides':{'Black powder coated sheet steel':'Graphite grey enamel'} if variant=='grey_board' else {},'notes':variant or 'original'})

def composition():
    w.reset();palette(REVIEW);instances.clear()
    for x in [-.835,.835]:
        instance('photo_electronics',ASSETS[0][0],(x,0,0));instance('photo_electronics',ASSETS[1][0],(x,0,.802))
        for dx in [-.40,.40]:
            for z in [.802,1.437]:instance('photo_workshop','photo_workshop_square_hole_board',(x+dx,.335,z),'grey_board')
        instance('photo_electronics',ASSETS[4][0],(x,-.13,.802))
    for x in [-.25,.72]:
        for z in [.81,.971,1.132]:instance('photo_electronics',ASSETS[2][0],(x,.17,z))
    instance('photo_electronics',ASSETS[3][0],(.22,.18,.81))
    instance('photo_desktop','photo_monitor_stand',(-1.23,.18,.802))
    for x in [-1.15,-.94,.99,1.2,1.41]:instance('photo_electronics',ASSETS[5][0],(x,.22,1.386))
    instance('photo_workshop','photo_workshop_blue_driver_rack',(-.60,.20,1.386))
    for z in [1.386,1.446]:instance('photo_workshop','photo_workshop_red_flat_case',(.56,.20,z))
    (OUT/'composition.json').write_text(json.dumps({'reference':'Photo 6 viewed original 2048x1151','units':'metres','coordinateSystem':'Blender Z-up','note':'Estimated spacing; grey_board changes material only. No source geometry stretched. Repeated parts remain instances in this manifest.','instances':instances},indent=2))
    bpy.ops.wm.save_as_mainfile(filepath=str(REVIEW/'photo_electronics_composition.blend'));render('photo_electronics_bench_composition',True)

if '--render-only' not in sys.argv:
    records=[]
    for asset,build in ASSETS:
        folder=OUT/asset;folder.mkdir(exist_ok=True)
        for lod in range(3):
            w.reset();w.LOD=lod;palette(folder);build();objs,bb=w.bounds();validation=w.validate_meshes(objs)
            for o in objs:
                o['assetId']=asset;o['reference']='User photo 6, viewed 2026-11-03';o['scaleStatus']='Photo estimated metres, not surveyed'
                if o.data.uv_layers:
                    o.data.uv_layers.active_index=len(o.data.uv_layers)-1
                    o.data.uv_layers[-1].active_render=True
            # Each source contains mesh geometry only. Review camera/lights are added later.
            p=folder/f'lod{lod}_source.glb';bpy.ops.export_scene.gltf(filepath=str(p),export_format='GLB',export_extras=True)
            records.append({'asset':asset,'level':lod,'triangles':sum(len(f.vertices)-2 for o in objs for f in o.data.polygons),'meshParts':len(objs),'boundsBlenderXYZ':bb,'sizeBlenderXYZ':[bb[1][i]-bb[0][i] for i in range(3)],'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'validation':validation})
            if lod==0:bpy.ops.wm.save_as_mainfile(filepath=str(folder/(asset+'.blend')))
    for asset,_ in ASSETS:
        rr=[r['triangles'] for r in records if r['asset']==asset];assert rr[0]>rr[1]>rr[2],(asset,rr)
    (REVIEW/'build_report.json').write_text(json.dumps({'blender':bpy.app.version_string,'referencePixelsViewed':True,'referenceFile':'17bbf66f7667bc31e4894c87d6856da5.jpg','units':'m','dimensions':'Photographic estimates, not measured','materialPolicy':'Packed 128-square synthetic repeating wood and cutting-grid tiles; metallic roughness factors. No reference pixels or writing.','scope':'6 new asset sources only. Neutral instrument exterior approximations, not identified models or functional diagrams.','records':records},indent=2))
if '--skip-render' not in sys.argv:
    for asset,_ in ASSETS:
        bpy.ops.wm.open_mainfile(filepath=str(OUT/asset/(asset+'.blend')));render(asset)
    composition()
