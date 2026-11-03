"""Photo 6 contents and nonfunctional review composition. No photo pixels used."""
import bpy,bmesh,math,json,hashlib,sys,types
from pathlib import Path
from mathutils import Vector,Matrix
ROOT=Path(__file__).resolve().parents[1]
w=types.ModuleType('helpers');w.__file__=str(ROOT/'scripts/build_photo_workshop.py')
exec(Path(w.__file__).read_text().split('selected=[a for a in sys.argv')[0],w.__dict__)
OUT=ROOT/'sources/models/photo_bench_contents';REVIEW=ROOT/'review/photo_bench_contents'
OUT.mkdir(parents=True,exist_ok=True);REVIEW.mkdir(parents=True,exist_ok=True)
box=w.box;cyl=w.cylinder;bar=w.bar_between

def palette(folder):
 global black,steel,red,blue,grey,ivory,yellow,glass,foam
 w.CURRENT_FOLDER=folder;w.palette();black=w.rubber;steel=w.steel;red=w.red;blue=w.blue;grey=w.grey;foam=w.mat_rubber
 ivory=w.material('Unbranded pale instrument face',(.66,.66,.61),.05,.46)
 yellow=w.material('Yellow polymer and sponge',(.8,.43,.025),0,.7)
 glass=w.material('Unlit black display',(.009,.02,.024),.1,.2)

def tube(name,pts,r,mat):
 cu=bpy.data.curves.new(name,'CURVE');cu.dimensions='3D';cu.resolution_u=[8,5,3][w.LOD];cu.bevel_depth=r;cu.bevel_resolution=[3,2,1][w.LOD];cu.use_fill_caps=True
 sp=cu.splines.new('BEZIER');sp.bezier_points.add(len(pts)-1)
 for b,p in zip(sp.bezier_points,pts):b.co=p;b.handle_left_type='AUTO';b.handle_right_type='AUTO'
 o=bpy.data.objects.new(name,cu);bpy.context.collection.objects.link(o);o.data.materials.append(mat);w.active(o);bpy.ops.object.convert(target='MESH');o=bpy.context.object
 bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.remove_doubles(bm,verts=bm.verts,dist=1e-7);bmesh.ops.recalc_face_normals(bm,faces=bm.faces);bm.to_mesh(o.data);bm.free();w.planar_uv(o);return o

def quad():
 # Visual estimate: diagonal motor spacing about .46 m, not a product claim.
 for y in [-.135,.135]:
  bar('Long black landing skid',(-.23,y,.013),(.23,y,.013),.012,black)
  for x in [-.19,.19]:
   cyl('Red skid end band',(x,y,.013),.0125,.035,red,'X')
  for x in [-.10,.10]:bar('Tall silver landing strut',(x,y,.025),(x*.8,y*.5,.235),.008,steel)
 for z in [.235,.264]:box('Central dark layered flight plate',(0,0,z),(.19,.14,.005),black,.002)
 for x in [-.073,.073]:
  for y in [-.048,.048]:cyl('Plate standoff',(x,y,.25),.0035,.027,steel)
 for i,(x,y) in enumerate([(-.164,-.164),(.164,-.164),(.164,.164),(-.164,.164)]):
  o=box('Red or black rigid arm',(x/2,y/2,.247),(math.hypot(x,y),.026,.018),red if i<2 else black,.003);o.rotation_euler.z=math.atan2(y,x)
  cyl('Motor mounting foot',(x,y,.255),.024,.013,red)
  cyl('Blue motor bell',(x,y,.282),.018,.031,blue)
  cyl('Silver motor band',(x,y,.283),.0184,.016,steel)
  cyl('Blue motor top',(x,y,.304),.014,.008,blue)
  cyl('Propeller hub',(x,y,.314),.012,.008,black)
  # Slim opposed tapered blade silhouettes, not a rotating-function model.
  a=[.12,-.1,.28,-.3][i]
  for side in [-1,1]:
   poly=[(.008,-.006),(.045,-.014),(.107,-.010),(.119,-.002),(.114,.003),(.043,.006)]
   vs=[]
   for z in [.313,.316]:
    for px,py in poly:
     px*=side;py*=side;vs.append((x+px*math.cos(a)-py*math.sin(a),y+px*math.sin(a)+py*math.cos(a),z))
   n=len(poly);fs=[tuple(reversed(range(n))),tuple(range(n,2*n))]+[(j,(j+1)%n,(j+1)%n+n,j+n) for j in range(n)]
   o=w.mesh('Black static propeller blade',vs,fs,black);bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.remove_doubles(bm,verts=bm.verts,dist=1e-7);bmesh.ops.recalc_face_normals(bm,faces=bm.faces);bm.to_mesh(o.data);bm.free();w.planar_uv(o)
  if w.LOD<2:tube('Loose visible motor wire',[(x,y,.27),(x*.7,y*.7,.28),(.04*(1 if x>0 else -1),.02,.285)],.002,red if i%2 else black)
 box('Centre electronic module',(0,0,.279),(.062,.049,.023),black,.003)
 for dx,mat in [(-.014,red),(.014,black)]:tube('Centre loose wiring',[(dx,-.02,.288),(dx+.03,.02,.315),(dx-.015,.06,.282)],.0025,mat)

def solder():
 # Controller uses candidate dimensions, identity remains unknown.
 box('Controller black enclosure',(0,0,.046),(.124,.152,.092),black,.006)
 box('Pale controller fascia',(0,-.077,.046),(.115,.007,.082),ivory,.003)
 box('Unlit red display window',(0,-.082,.063),(.039,.004,.017),red,.001)
 for x in [-.024,0,.024]:box('Small controller key',(x,-.083,.038),(.012,.004,.006),grey,.001)
 cyl('Lower socket outer ring',(.027,-.082,.019),.008,.004,black,'Y')
 # Stand separate component behind and to left, sponge in shallow tray.
 box('Independent iron stand base',(-.113,.01,.006),(.073,.14,.012),grey,.004)
 box('Sponge recess',(-.113,-.023,.014),(.060,.055,.009),black,.002)
 box('Yellow cleaning sponge',(-.113,-.023,.019),(.053,.049,.007),yellow,.003)
 bar('Stand angled stem',(-.113,.045,.014),(-.113,.07,.07),.009,grey)
 bar('Iron holder sleeve',(-.113,.05,.067),(-.113,.095,.09),.012,black)
 bar('Iron metal shaft',(-.113,.04,.058),(-.113,.098,.091),.003,steel)
 bar('Iron dark handle',(-.113,.098,.091),(-.113,.154,.12),.009,black)
 tube('Unconnected resting iron cable',[(-.113,.155,.12),(-.19,.17,.05),(-.20,.07,.006),(-.18,-.08,.006),(-.06,-.12,.006)],.0025,black)

def charger():
 box('Blue flat charger body',(0,0,.018),(.144,.135,.036),blue,.004)
 box('Black top panel',(0,0,.037),(.121,.102,.003),black,.002)
 box('Unlit top screen',(0,.022,.039),(.071,.026,.0015),glass,.001)
 for x in [-.04,-.014,.014,.04]:box('Unlabelled top key',(x,-.028,.04),(.015,.012,.003),grey,.002)
 for y in [-.026,0,.026]:box('Side dark opening',(-.073,y,.017),(.001,.013,.010),black,.001)
 for x in [-.054,.054]:
  for y in [-.046,.046]:box('Short rubber foot',(x,y,.002),(.017,.02,.004),black,.001)
 if w.LOD<2:
  for y in [-.05+i*.01 for i in range(11)]:box('Side cooling rib',(.073,y,.018),(.002,.003,.025),blue,.001)

def spool():
 cyl('Dark wire winding',(0,0,.018),.021,.023,grey)
 for z in [.004,.032]:cyl('Pale spool flange',(0,0,z),.032,.006,ivory)
 cyl('Spool centre dark opening',(0,0,.0355),.006,.001,black)
 if w.LOD<2:
  for z in [.009+i*.003 for i in range(7)]:
   tube('Visible winding course',[(.021*math.cos(t),.021*math.sin(t),z) for t in [i*math.tau/12 for i in range(13)]],.0008,steel)

def leads():
 for i,mat in enumerate([red,black,red,black]):
  dx=i*.016
  pts=[(-.12+dx,-.04,.007+i*.003),(-.10+dx,.042,.009+i*.003),(.05+dx,.065,.011+i*.003),(.13+dx,.012,.009+i*.003),(.035+dx,-.055,.007+i*.003),(-.08+dx,-.018,.012+i*.003),(-.05+dx,.018,.012+i*.003)]
  tube('Loose unconnected test lead',pts,.0023,mat)
  bar('Insulated resting probe',pts[0],(-.17+dx,-.065,.007+i*.003),.005,mat)
  bar('Probe metal point',(-.17+dx,-.065,.007+i*.003),(-.19+dx,-.075,.007+i*.003),.0014,steel)
  cyl('Disconnected plug',pts[-1],.004,.014,mat,'Y')

def pouch():
 box('Rounded black storage pouch',(0,0,.034),(.19,.115,.068),foam,.023)
 box('Zipper seam',(0,0,.034),(.191,.116,.003),black,.001)
 box('Small zipper pull',(.089,-.052,.035),(.018,.007,.004),grey,.002)

def handheld():
 box('Wide yellow handheld head',(-.048,0,.044),(.09,.103,.082),yellow,.014)
 box('Broad black head back',(-.049,-.052,.045),(.075,.008,.064),black,.008)
 box('Unknown dark head face',(-.049,-.057,.045),(.056,.002,.045),glass,.004)
 box('Long yellow grip',(.049,0,.032),(.13,.035,.041),yellow,.011)
 box('Black grip end',(.105,0,.032),(.012,.036,.041),black,.003)

ASSETS=[('photo_quadrotor_unknown',quad),('photo_solder_station_set',solder),('photo_blue_rc_charger_unknown',charger),('photo_wire_spool',spool),('photo_loose_test_leads',leads),('photo_black_pouch',pouch),('photo_yellow_black_handheld_shell',handheld)]

def render(name,composition=False,detail=False):
 objs,bb=w.bounds();lo,hi=map(Vector,bb);center=(lo+hi)/2;size=max(hi-lo)
 box('REVIEW floor',(0,0,lo.z-.025),(100,100,.04),w.material('Review ground',(.24,.26,.27),0,.8))
 target=Vector((.05,0,1.13)) if composition else center
 pos=Vector((2.65,-4.9,2.9)) if composition else center+Vector((1.1,-1.8,1.3))*max(size,.16)*1.12
 if detail:target=Vector((.78,-.02,1.06));pos=Vector((2.05,-2.2,2.1))
 bpy.ops.object.camera_add(location=pos);cam=bpy.context.object;cam.data.lens=48 if composition else 54;cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();sc=bpy.context.scene;sc.camera=cam
 for p,power in [((-1.6,-1.7,2.7),380),((1.8,-.2,2.3),250),((0,2,3),320)]:
  bpy.ops.object.light_add(type='AREA',location=center+Vector(p)*max(size,.4));o=bpy.context.object;o.data.energy=power*max(size,.4)**2;o.data.size=2*max(size,.4);o.rotation_euler=(target-o.location).to_track_quat('-Z','Y').to_euler()
 sc.world=bpy.data.worlds.new('Soft world');sc.world.use_nodes=True;sc.world.node_tree.nodes.get('Background').inputs['Strength'].default_value=.35
 sc.render.engine='CYCLES';sc.cycles.device='CPU';sc.cycles.samples=32;sc.cycles.use_denoising=False;sc.render.resolution_x=1700 if composition else 1000;sc.render.resolution_y=1100 if composition else 800;sc.render.resolution_percentage=100;sc.view_settings.view_transform='AgX';sc.view_settings.exposure=-.7;sc.render.filepath=str(REVIEW/(name+'.png'));bpy.ops.render.render(write_still=True)

instances=[]
def instance(group,asset,loc,yaw=0):
 path=ROOT/'sources/models'/group/asset/(asset+'.blend')
 with bpy.data.libraries.load(str(path),link=False) as(src,dst):dst.objects=src.objects
 objs=[o for o in dst.objects if o and o.type=='MESH']
 for o in objs:bpy.context.collection.objects.link(o)
 bpy.context.view_layer.update();m=Matrix.Translation(Vector(loc))@Matrix.Rotation(yaw,4,'Z')
 originals=[(o,o.matrix_world.copy()) for o in objs]
 for o,original in originals:o.matrix_world=m@original
 if asset=='photo_workshop_square_hole_board':
  for o in objs:
   for j,mat in enumerate(o.data.materials):
    if mat and 'Black powder' in mat.name:o.data.materials[j]=grey
 pts=[o.matrix_world@v.co for o in objs for v in o.data.vertices];bb=[[min(v[i] for v in pts) for i in range(3)],[max(v[i] for v in pts) for i in range(3)]]
 instances.append({'instanceId':f'{asset}_{len(instances):02d}','boundsBlenderXYZ':bb,'assetId':asset,'sourcePath':str(path.relative_to(ROOT)),'sourceSha256':hashlib.sha256(path.read_bytes()).hexdigest(),'position':loc,'rotationEuler':[0,0,yaw],'scale':[1,1,1]})
 if asset=='photo_workshop_square_hole_board':instances[-1]['materialOverrides']={'Black powder coated sheet steel':'Grey caster hubs'}
 return instances[-1]

def composition():
 w.reset();palette(REVIEW);instances.clear();surfaces=[];contacts=[]
 def surf(id,z,x,y,owner=None):
  surfaces.append({'id':id,'z':z,'height':z,'boundsXY':[x,y],'ownerInstanceId':owner})
 def place(group,asset,loc,yaw=0,support=None,note=''):
  rec=instance(group,asset,loc,yaw);rec['supportSurfaceId']=support;rec['notes']=note
  return rec
 # Sources with base offsets are placed with explicit, measured bottom correction.
 def seat(group,asset,x,y,z,yaw=0,support=None,note=''):
  before=set(bpy.context.scene.objects);r=place(group,asset,(x,y,z),yaw,support,note);new=set(bpy.context.scene.objects)-before;dz=z-r['boundsBlenderXYZ'][0][2]
  for o in new:o.location.z+=dz;o['instanceId']=r['instanceId']
  r['position']=[x,y,z+dz]
  for b in r['boundsBlenderXYZ']:b[2]+=dz
  return r
 def on_top(r,id):
  b=r['boundsBlenderXYZ'];surf(id,b[1][2],[b[0][0],b[1][0]],[b[0][1],b[1][1]],r['instanceId']);return b[1][2]
 surf('ground',0,[-10,10],[-10,10])
 for k,x in enumerate([-.835,.835]):
  desk=seat('photo_electronics','photo_electronics_drawer_bench',x,0,0,support='ground');sid=f'desktop_{k}';surf(sid,.802,[x-.825,x+.825],[-.38,.38],desk['instanceId'])
  frame=place('photo_electronics','photo_electronics_back_shelf_frame',(x,0,.802),support=sid)
  surf(f'shelf_{k}',1.3845,[x-.80,x+.80],[.06,.35],frame['instanceId'])
  for dx in [-.40,.40]:
   for z in [.8045,1.450]:
    r=place('photo_workshop','photo_workshop_square_hole_board',(x+dx,.335,z),support=None,note='Mounted vertical rear board, not a tabletop object')
    contacts.append({'instances':[r['instanceId'],frame['instanceId']],'reason':'Rear panel mounted against upright frame'})
 for k,(x,y,a) in enumerate([(-.91,-.145,-.05),(-.30,-.12,.06),(1.25,-.09,-.09)]):
  r=seat('photo_electronics','photo_electronics_green_cutting_mat',x,y,.802,a,support='desktop_0' if x<0 else 'desktop_1');on_top(r,f'mat_{k}')
 # Left stack 3, centre 1, right stack 3. Cases have different dimensions.
 for side,x,ys,ids in [('left',-.81,[-.16,-.142,-.122],['photo_instrument_dp800_series_candidate','photo_instrument_l2_light_test_unknown','photo_instrument_l1_dark_signal_candidate']),('right',.46,[-.15,-.13,-.115],['photo_instrument_dp800_series_candidate','photo_instrument_r2_light_test_unknown','photo_instrument_r1_dark_rf_candidate'])]:
  z=.806 if side=='left' else .802;support='desktop_0' if side=='left' else 'desktop_1'
  for j,asset in enumerate(ids):
   r=seat('photo_instruments',asset,x+([0,.006,-.009][j]),ys[j],z,support=support,note='Stacked casing; four-mm mat allowance at base' if j==0 else 'Resting on case below; slightly offset')
   if j==0 and side=='left':r['supportToleranceM']=.004
   z=on_top(r,f'{side}_stack_{j}');support=f'{side}_stack_{j}'
 seat('photo_instruments','photo_instrument_c1_wide_scope_candidate',-.115,.082,.802,support='desktop_0',note='Back of centre mat; footprint crosses the gap between adjacent desks by design')
 seat('photo_desktop','photo_monitor_stand',-1.35,.10,.802,support='desktop_0')
 seat('photo_bench_contents','photo_solder_station_set',-.40,-.09,.806,-.045,support='mat_1',note='Controller, stand and resting lead are separate meshes; loose line overlaps mat')
 seat('photo_bench_contents','photo_blue_rc_charger_unknown',.85,-.17,.802,-.10,support='desktop_1')
 seat('photo_bench_contents','photo_quadrotor_unknown',1.285,-.025,.806,-.04,support='mat_2')
 seat('photo_bench_contents','photo_wire_spool',-.58,-.25,.802,support='desktop_0')
 for x,y,a,support in [(-.80,-.28,.05,'mat_0'),(.48,-.28,-.18,'desktop_1')]:seat('photo_bench_contents','photo_loose_test_leads',x,y,.806 if x<0 else .802,a,support=support,note='Loose disconnected probes and leads; no instrument-port connection')
 # Photo-supported shelf items and rows of bins, irregular small offsets not random clutter.
 for i,(x,z) in enumerate([(.34,1.3845),(.35,1.4525),(.36,1.5205),(-.34,1.3845)]):
  r=seat('photo_bench_contents','photo_black_pouch',x,.19,z,(-.04 if i%2 else .03),support='shelf_1' if x>0 else 'shelf_0',note='Pouches stacked; lower pouch provides support' if i in [1,2] else '')
  if i<3:
   if i>0:r['supportSurfaceId']=f'pouch_top_{i-1}'
   on_top(r,f'pouch_top_{i}')
 seat('photo_bench_contents','photo_yellow_black_handheld_shell',.74,.19,1.3845,.025,support='shelf_1')
 z=1.3845
 for i in range(3):
  r=seat('photo_workshop','photo_workshop_red_flat_case',1.26-i*.01,.18,z,.015*i,support='shelf_1' if i==0 else f'red_case_top_{i-1}');z=on_top(r,f'red_case_top_{i}')
 for i,x in enumerate([-.59,-.37,-.15,.90,1.11,1.32,1.51]):
  r=place('photo_electronics','photo_electronics_open_bin',(x,.26,1.18+(i%2)*.008),support=None,note='Rear-board wall-mounted bin; no tabletop support required')
  r['mountType']='backboard'
 # Save before adding review floor/cameras/lights.
 (OUT/'composition.json').write_text(json.dumps({'reference':'Photo 6, actually viewed','units':'metres','coordinateSystem':'Blender Z-up; fronts -Y','scope':'Nonfunctional contents preview, no main-scene edits','supportSurfaces':surfaces,'allowContacts':contacts,'instances':instances},indent=2))
 bpy.ops.wm.save_as_mainfile(filepath=str(REVIEW/'photo_bench_contents_composition.blend'))
 if '--skip-preview' in sys.argv:return
 render('photo_bench_contents_composition',True)
 bpy.ops.wm.open_mainfile(filepath=str(REVIEW/'photo_bench_contents_composition.blend'));render('photo_bench_contents_detail',True,True)


if __name__=='__main__':
 if '--render-only' not in sys.argv and '--composition-only' not in sys.argv:
  records=[]
  for asset,build in ASSETS:
   folder=OUT/asset;folder.mkdir(exist_ok=True)
   for lod in range(3):
    w.reset();w.LOD=lod;palette(folder);build();objs,bb=w.bounds();validation=w.validate_meshes(objs)
    for o in objs:o['assetId']=asset;o['scaleStatus']='Photo estimate, not exact identified product';o['reference']='Photo 6 visually inspected; no photo textures'
    p=folder/f'lod{lod}_source.glb';bpy.ops.export_scene.gltf(filepath=str(p),export_format='GLB',export_extras=True)
    records.append({'asset':asset,'level':lod,'triangles':sum(len(p.vertices)-2 for o in objs for p in o.data.polygons),'meshParts':len(objs),'boundsBlenderXYZ':bb,'sizeBlenderXYZ':[bb[1][i]-bb[0][i] for i in range(3)],'validation':validation,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
    if lod==0:bpy.ops.wm.save_as_mainfile(filepath=str(folder/(asset+'.blend')))
  for asset,_ in ASSETS:
   ts=[r['triangles'] for r in records if r['asset']==asset];assert ts[0]>ts[1]>ts[2],(asset,ts)
  (REVIEW/'build_report.json').write_text(json.dumps({'blender':bpy.app.version_string,'records':records,'texturePolicy':'Authored packed 128px rubber normal; metallic roughness PBR; no photo pixels','dimensionPolicy':'Photo estimates; solder controller candidate 124x152x92 mm; charger candidate 144x135x36 mm, not identification'},indent=2))
 if '--skip-render' not in sys.argv:
  if '--composition-only' not in sys.argv:
   for asset,_ in ASSETS:
    bpy.ops.wm.open_mainfile(filepath=str(OUT/asset/(asset+'.blend')));render(asset)
  if '--assets-only' not in sys.argv:composition()
