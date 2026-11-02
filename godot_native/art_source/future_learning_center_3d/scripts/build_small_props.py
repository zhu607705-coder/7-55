"""Deterministic isolated static review props. Blender 4.3+, metres. No main blend edits.
blender -b --factory-startup -t 2 --python scripts/build_small_props.py
"""
import bpy, math, json, hashlib, sys
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1]; OUT=ROOT/'sources/models/small_props'; REVIEW=ROOT/'review/small_props'
OUT.mkdir(parents=True,exist_ok=True);REVIEW.mkdir(parents=True,exist_ok=True)
records=[]
def material(name,c,metal=0,rough=.4):
 m=bpy.data.materials.new(name);m.diffuse_color=(*c,1);m.use_nodes=True;p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*c,1);p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=rough;return m
def finish(o,name,mat):
 o.name=name;o.data.materials.append(mat);o['part']=name
 for p in o.data.polygons:p.use_smooth=True
 return o
def box(name,loc,size,mat,bevel=0):
 bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.dimensions=size;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 if bevel:
  m=o.modifiers.new('Manufactured edge radius','BEVEL');m.width=bevel;m.segments=3 if LOD==0 else 2 if LOD==1 else 1
  bpy.ops.object.modifier_apply(modifier=m.name)
 finish(o,name,mat)
 m=o.modifiers.new('Weighted flat-face normals','WEIGHTED_NORMAL');m.keep_sharp=True;bpy.ops.object.modifier_apply(modifier=m.name)
 return o
def cyl(name,loc,r,depth,mat,axis='Z'):
 bpy.ops.mesh.primitive_cylinder_add(vertices=48 if LOD==0 else 24 if LOD==1 else 12,radius=r,depth=depth,location=loc);o=bpy.context.object
 if axis=='X':o.rotation_euler.y=math.pi/2
 if axis=='Y':o.rotation_euler.x=math.pi/2
 return finish(o,name,mat)
def polygon(name,coords,thick,mat,z=0):
 n=len(coords);v=[(x,y,z+t) for t in [0,thick] for x,y in coords];f=[tuple(range(n-1,-1,-1)),tuple(range(n,2*n))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)];me=bpy.data.meshes.new(name);me.from_pydata(v,[],f);me.update();o=bpy.data.objects.new(name,me);bpy.context.collection.objects.link(o);return finish(o,name,mat)
def text_obj(body,loc,size,mat):
 bpy.ops.object.text_add(location=loc);o=bpy.context.object;o.name='Laser marked '+body;o.data.body=body;o.data.size=size;o.data.extrude=.000015;o.data.materials.append(mat);bpy.ops.object.convert(target='MESH');return o
def caliper():
 box('233 mm stainless beam',(.1165,0,.002),(.233,.016,.004),steel,.00025)
 polygon('Fixed outer measuring jaw',[(0,0),(.012,0),(.012,.018),(.008,.04),(.005,.04),(0,.018)],.0035,steel)
 polygon('Moving outer measuring jaw',[(.067,0),(.079,0),(.079,.018),(.074,.04),(.071,.04),(.067,.018)],.0035,steel)
 polygon('Fixed inside jaw',[(.003,0),(.010,0),(.010,-.026),(.007,-.029),(.003,-.012)],.0035,steel)
 polygon('Moving inside jaw',[(.069,0),(.077,0),(.077,-.012),(.073,-.029),(.069,-.026)],.0035,steel)
 box('Slider housing',(.060,0,.010),(.050,.026,.016),graphite,.002)
 box('Recessed display bezel',(.059,-.002,.0181),(.034,.015,.001),black,.001)
 box('Blank LCD no measurement claim',(.059,-.002,.0187),(.029,.010,.0003),lcd,.0005)
 for i,c in enumerate([red,blue,graphite]):cyl('Control button '+str(i),(.045+i*.012,.009,.019),.0024,.002,c)
 cyl('Thumb roller',(.077,.022,.0055),.005,.004,steel,'Y')
 if LOD<2:
  for i in range(24 if LOD==0 else 12):
   a=i*math.tau/(24 if LOD==0 else 12);box('Roller knurl',(.077+.005*math.cos(a),.022,.0055+.005*math.sin(a)),(.00045,.004,.00045),steel)
 cyl('Slider lock screw',(.074,-.017,.008),.0026,.004,steel)
 box('Lock screw slot',(.074,-.017,.0101),(.0035,.00055,.0001),black)
 for i in range(0,151,1 if LOD==0 else 5 if LOD==1 else 10):
  x=.081+i*.001;box('Etched beam graduation',(x,-.005,.00405),(.00012,.004 if i%10==0 else .0025 if i%5==0 else .0013,.00006),black)
 if LOD==0:
  for i in range(0,151,10):text_obj(str(i),(.079+i*.001,.001,.00412),.0024,black)
 # Static review pose only. No tool function, controller, or measured readout.
def driver():
 # Handle spans exactly x=0..104mm, shaft/tip extends to204mm.
 n=48 if LOD==0 else 24 if LOD==1 else 12
 rings=[(0,.005),(.004,.0085),(.016,.0115),(.064,.0115),(.089,.009),(.100,.007),(.104,.006)]
 verts=[(x,r*(.96 if j in [2,3] and a%(n//6)<n//12 else 1)*math.cos(a*math.tau/n),.0115+r*(.96 if j in [2,3] and a%(n//6)<n//12 else 1)*math.sin(a*math.tau/n)) for j,(x,r) in enumerate(rings) for a in range(n)]
 faces=[tuple(range(n-1,-1,-1)),tuple((len(rings)-1)*n+i for i in range(n))]
 for j in range(len(rings)-1):
  for i in range(n):faces.append((j*n+i,j*n+(i+1)%n,(j+1)*n+(i+1)%n,(j+1)*n+i))
 me=bpy.data.meshes.new('Contoured handle');me.from_pydata(verts,[],faces);me.update();o=bpy.data.objects.new('23 mm contoured polymer handle',me);bpy.context.collection.objects.link(o);finish(o,o.name,red)
 o.data.materials.append(rubber)
 for i in range(n):
  if i%(n//6)<n//12:o.data.polygons[2+2*n+i].material_index=1
 cyl('Handle end cap',(.003,0,.0115),.006,.004,black,'X')
 cyl('Collar',(.101,0,.0115),.0062,.006,yellow,'X')
 cyl('Shaft',(.150,0,.0115),.0015,.092,steel,'X')
 # Taper from3mm round shaft to3x0.5mm flat tip; true length204mm.
 polygon('Forged flat blade',[(.196,-.0015),(.204,-.0015),(.204,.0015),(.196,.0015)],.0005,steel,.01125)
def tray():
 # Existing source footprint420x320x40mm, not manufacturer or site measurement.
 w,d,h=.42,.32,.04;rad=.018;t=.002
 # Rounded rectangular hollow pan, four rings with connected inner/outer faces.
 def ring(w,d,r,z):
  pts=[];steps=12 if LOD==0 else 6 if LOD==1 else 3
  for cx,cy,start in [(w/2-r,d/2-r,0),(-w/2+r,d/2-r,90),(-w/2+r,-d/2+r,180),(w/2-r,-d/2+r,270)]:
   for j in range(steps+1):a=math.radians(start+j*90/steps);pts.append((cx+r*math.cos(a),cy+r*math.sin(a),z))
  return pts
 rings=[ring(w,d,rad,0),ring(w,d,rad,h),ring(w-2*t,d-2*t,rad-t,h),ring(w-2*t,d-2*t,rad-t,t)]
 n=len(rings[0]);vs=sum(rings,[]);faces=[]
 for k in range(3):
  for i in range(n):faces.append((k*n+i,k*n+(i+1)%n,(k+1)*n+(i+1)%n,(k+1)*n+i))
 faces+=[tuple(range(n-1,-1,-1)),tuple(range(3*n,4*n))]
 me=bpy.data.meshes.new('Folded tray shell');me.from_pydata(vs,[],faces);me.update();o=bpy.data.objects.new('420x320x40 mm hollow display tray',me);bpy.context.collection.objects.link(o);finish(o,o.name,steel)
 box('Removable matte protective liner',(0,0,.003),(.400,.300,.002),rubber,.006)
 for x in [-.155,.155]:
  for y in [-.105,.105]:box('Recessed underside foot',(x,y,.001),(.022,.022,.002),rubber,.003)
def render(asset):
 bpy.context.scene.render.engine='CYCLES';bpy.context.scene.cycles.device='CPU';bpy.context.scene.cycles.samples=64;bpy.context.scene.cycles.use_denoising=False
 objs=[o for o in bpy.context.scene.objects if o.type=='MESH'];pts=[o.matrix_world@Vector(c) for o in objs for c in o.bound_box];mn=Vector(tuple(min(p[i] for p in pts) for i in range(3)));mx=Vector(tuple(max(p[i] for p in pts) for i in range(3)));center=(mn+mx)/2;size=max(mx-mn)
 floor=box('Render-only neutral stage',(center.x,center.y,-.003),(2,2,.005),stage,.001)
 bpy.ops.object.camera_add(location=center+Vector((.35,-.65,.85))*size*2.3);cam=bpy.context.object;cam.rotation_euler=(center-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=size*1.35;bpy.context.scene.camera=cam
 for name,pos,power,radius in [('Key',(-.3,-.4,.8),65,.6),('Fill',(.5,.1,.4),28,.5),('Rim',(-.3,.5,.5),45,.4)]:
  bpy.ops.object.light_add(type='AREA',location=center+Vector(pos));o=bpy.context.object;o.name=name;o.data.energy=power;o.data.shape='DISK';o.data.size=radius;o.rotation_euler=(center-o.location).to_track_quat('-Z','Y').to_euler()
 sc=bpy.context.scene;sc.world=bpy.data.worlds.new('Studio world');sc.world.color=(.23,.23,.23);sc.render.resolution_x=1100;sc.render.resolution_y=850;sc.render.resolution_percentage=100;sc.render.image_settings.file_format='PNG';sc.render.filepath=str(REVIEW/(asset+'.png'));sc.view_settings.view_transform='AgX';sc.view_settings.exposure=-2.5;bpy.ops.render.render(write_still=True)
if '--render-only' in sys.argv:
 LOD=0
 for asset in ['caliper_150','screwdriver_3x100','display_tray']:
  if any(a.startswith('--asset=') for a in sys.argv) and '--asset='+asset not in sys.argv:continue
  bpy.ops.wm.open_mainfile(filepath=str(OUT/asset/(asset+'.blend')))
  stage=material('Neutral presentation stage',(.55,.58,.61),0,.8)
  render(asset)
 raise SystemExit(0)
for asset,build in [('caliper_150',caliper),('screwdriver_3x100',driver),('display_tray',tray)]:
 for LOD in range(3):
  bpy.ops.wm.read_factory_settings(use_empty=True);bpy.context.preferences.filepaths.save_version=0;bpy.context.scene.unit_settings.system='METRIC';bpy.context.scene.unit_settings.scale_length=1
  steel=material('Satin stainless steel',(.40,.44,.48),1,.29);graphite=material('Graphite molded polymer',(.028,.037,.044),0,.38);black=material('Dark recess / etched marks',(.009,.012,.015),0,.5);lcd=material('Blank LCD glass',(.18,.25,.23),0,.23);red=material('Red molded polymer',(.48,.022,.012),0,.36);yellow=material('Collar safety-color approximation',(.72,.31,.018),0,.4);blue=material('Blue control polymer',(.02,.22,.42),0,.4);rubber=material('Matte elastomer',(.018,.022,.024),0,.84);stage=material('Neutral presentation stage',(.55,.58,.61),0,.8)
  build();bpy.context.view_layer.update();objs=[o for o in bpy.context.scene.objects if o.type=='MESH'];points=[o.matrix_world@Vector(c) for o in objs for c in o.bound_box];bounds=[[min(p[i] for p in points) for i in range(3)],[max(p[i] for p in points) for i in range(3)]]
  tris=sum(len(p.vertices)-2 for o in objs for p in o.data.polygons);folder=OUT/asset;folder.mkdir(exist_ok=True);p=folder/f'lod{LOD}_source.glb'
  bpy.ops.export_scene.gltf(filepath=str(p),export_format='GLB',export_extras=True,export_yup=True)
  records.append({'asset':asset,'level':LOD,'triangles':tris,'boundsBlenderXYZ':bounds,'sizeBlenderXYZ':[bounds[1][i]-bounds[0][i] for i in range(3)],'meshParts':len(objs),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
  if LOD==0:
   bpy.ops.wm.save_as_mainfile(filepath=str(folder/(asset+'.blend')))
   if '--skip-render' not in sys.argv:render(asset)
(REVIEW/'build_report.json').write_text(json.dumps({'blender':bpy.app.version_string,'units':'m','scope':'Independent static review samples; dimension-driven local mesh, no external AI 3D generation; no gameplay behavior','records':records},indent=2))
