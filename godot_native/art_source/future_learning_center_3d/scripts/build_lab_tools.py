"""Independent equipment samples. Blender4.3+, metres, no source/main blend load.
blender -b --factory-startup -t 2 --python scripts/build_lab_tools.py
Use -- --skip-render or -- --render-only for separated build/photography.
"""
import bpy, math, json, hashlib, sys
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'sources/models/lab_tools';REVIEW=ROOT/'review/lab_tools'
OUT.mkdir(parents=True,exist_ok=True);REVIEW.mkdir(parents=True,exist_ok=True)
LOD=0

def mat(name,color,metal=0,rough=.4,trans=0):
 m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True;p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=rough
 if trans:p.inputs['Transmission Weight'].default_value=trans;p.inputs['IOR'].default_value=1.45
 return m

def finish(o,name,m):
 o.name=name;o['part']=name;o.data.materials.append(m)
 for p in o.data.polygons:p.use_smooth=True
 return o

def box(name,pos,size,m,bevel=0):
 bpy.ops.mesh.primitive_cube_add(size=1,location=pos);o=bpy.context.object;o.dimensions=size;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 if bevel:
  mod=o.modifiers.new('Edge radius','BEVEL');mod.width=min(bevel,min(size)*.45);mod.segments=[4,2,1][LOD];bpy.ops.object.modifier_apply(modifier=mod.name)
 finish(o,name,m);mod=o.modifiers.new('Weighted normals','WEIGHTED_NORMAL');mod.keep_sharp=True;bpy.ops.object.modifier_apply(modifier=mod.name);return o

def cyl(name,pos,r,h,m,axis='Z'):
 bpy.ops.mesh.primitive_cylinder_add(vertices=[48,24,12][LOD],radius=r,depth=h,location=pos);o=bpy.context.object
 if axis=='X':o.rotation_euler.y=math.pi/2
 if axis=='Y':o.rotation_euler.x=math.pi/2
 return finish(o,name,m)

def rod(name,a,b,r,m):
 a,b=Vector(a),Vector(b);o=cyl(name,(a+b)/2,r,(b-a).length,m);o.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler();return o

def screw(pos,axis='Y'):
 if LOD==2:return
 cyl('Recessed assembly screw',pos,.003,.0012,steel,axis)
 x,y,z=pos
 if axis=='Y':box('Screw slot',(x,y-.0007,z),(.004,.0003,.0006),black)
 else:box('Screw slot',(x,y,z+.0007),(.004,.0006,.0003),black)

def ring(name,pos,major,minor,m,axis='Z'):
 bpy.ops.mesh.primitive_torus_add(major_segments=[48,24,12][LOD],minor_segments=[8,6,4][LOD],location=pos,major_radius=major,minor_radius=minor);o=bpy.context.object
 if axis=='Y':o.rotation_euler.x=math.pi/2
 if axis=='X':o.rotation_euler.y=math.pi/2
 return finish(o,name,m)

def printer():
 w,d,h=.492,.514,.626
 box('Lower enclosure',(0,0,.042),(w,d,.084),graphite,.014)
 box('Upper enclosure',(0,.008,h-.027),(w,d-.016,.054),graphite,.014)
 for x in [-w/2+.022,w/2-.022]:
  for y in [-d/2+.022,d/2-.022]:box('Corner upright',(x,y,h/2),(.044,.044,h-.10),graphite,.007)
 # Separate shell panels, not a solid opaque box.
 box('Left alloy side',(-w/2+.007,0,.327),(.014,d-.07,.50),paint,.006)
 box('Right alloy side',(w/2-.007,0,.327),(.014,d-.07,.50),paint,.006)
 box('Rear shell',(0,d/2-.008,.327),(w-.07,.016,.50),paint,.005)
 box('Closed front glazing',(0,-d/2+.014,.327),(w-.09,.010,.48),glass,.008)
 for x in [-.195,.195]:box('Door perimeter upright',(x,-d/2+.007,.327),(.011,.012,.49),black,.003)
 for z in [.082,.572]:box('Door perimeter cross member',(0,-d/2+.007,z),(.40,.012,.011),black,.003)
 # Handle stays inside the492x514x626mm envelope.
 for z in [.275,.375]:box('Door handle stand-off',(.175,-.246,z),(.014,.016,.014),steel,.002)
 box('Door handle',(.175,-.251,.325),(.012,.010,.11),steel,.004)
 for z in [.20,.46]:cyl('Door hinge',(-.211,-.237,z),.008,.055,steel)
 box('Build bed plate',(0,0,.205),(.33,.32,.010),steel,.003)
 box('Removable print surface',(0,0,.211),(.322,.312,.002),graphite,.001)
 for x in [-.177,.177]:
  rod('Z linear guide',(x,.155,.09),(x,.155,.57),.005,steel)
  box('Gantry carrier',(x,0,.455),(.025,.36,.024),graphite,.004)
 rod('X gantry shaft',(-.18,0,.455),(.18,0,.455),.0045,steel)
 box('Carriage head',(0,-.006,.416),(.078,.075,.078),graphite,.007)
 box('Head shroud face',(0,-.047,.416),(.066,.008,.058),paint,.003)
 cyl('Nozzle body',(0,-.006,.368),.006,.016,steel)
 cyl('Nozzle tip',(0,-.006,.358),.002,.004,steel)
 box('Touchscreen mounting recess',(.105,-.245,.591),(.128,.012,.046),black,.004)
 box('Blank recessed touchscreen',(.105,-.252,.591),(.118,.002,.042),screen,.002)
 if LOD<2:
  for x in [-.205,.205]:
   for z in [.066,.58]:screw((x,-.252,z))
  for i in range(18 if LOD==0 else 9):box('Side vent inset',(.239,-.17+i*(.34/(17 if LOD==0 else 8)),.12),(.001,.008,.035),black,.001)
 for x in [-.19,.19]:
  for y in [-.20,.20]:box('Rubber foot',(x,y,.006),(.055,.055,.012),rubber,.005)

def laser():
 w,d,h=1,.639,.268
 box('Bottom chassis',(0,0,.025),(w,d,.05),graphite,.018)
 for x in [-.484,.484]:box('Long side shell',(x,0,.139),(.032,d,.228),paint,.012)
 for y in [-.3035,.3035]:box('Front rear shell',(0,y,.139),(.95,.032,.228),paint,.010)
 # Closed top cover with actual interior well, frame and tinted insert.
 for x in [-.43,.29]:box('Lid side rim',(x,0,.256),(.026,.50,.024),graphite,.006)
 for y in [-.237,.237]:box('Lid front rear rim',(-.07,y,.256),(.746,.026,.024),graphite,.006)
 box('Closed tinted lid glass',(-.07,0,.259),(.696,.448,.012),glass,.006)
 box('Control-side deck',(.397,0,.253),(.174,.57,.018),paint,.010)
 box('Blank control display',(.395,-.17,.268-.003),(.112,.09,.006),screen,.006)
 for x in [-.18,.04]:box('Lid pull mount',(x,-.267,.240),(.025,.025,.018),graphite,.004)
 box('Lid front pull',(-.07,-.276,.245),(.28,.020,.020),steel,.005)
 for x in [-.31,.17]:cyl('Rear lid hinge',(x,.259,.25),.009,.055,steel,'X')
 box('Internal bed',(-.07,0,.073),(.70,.43,.014),graphite,.003)
 # A shallow gridded support is illustrative, not an exact optical safety assembly.
 spacing=.028 if LOD==0 else .056 if LOD==1 else .112
 for i in range(int(.64/spacing)+1):box('Bed support rib',(-.39+i*spacing,0,.084),(.002,.40,.008),steel)
 for j in range(int(.40/spacing)+1):box('Bed cross rib',(-.07,-.20+j*spacing,.084),(.66,.002,.008),steel)
 for y in [-.20,.20]:rod('Internal guide',(-.40,y,.155),(.26,y,.155),.004,steel)
 box('Laser carriage rail',(-.20,0,.175),(.022,.41,.024),graphite,.003)
 box('Illustrative optical carriage',(-.20,-.02,.154),(.058,.062,.06),graphite,.006)
 box('Front service panel',(0,-.319,.115),(.66,.001,.12),graphite,.005)
 if LOD<2:
  for i in range(22 if LOD==0 else 11):box('Rear ventilation slit',(-.42+i*(.84/(21 if LOD==0 else 10)),.319,.125),(.018,.001,.05),black,.003)
  for x in [-.40,.40]:
   for z in [.065,.20]:screw((x,-.3185,z))
 for x in [-.42,.42]:
  for y in [-.25,.25]:box('Isolating foot',(x,y,.006),(.055,.055,.012),rubber,.005)

def supply():
 # Original scene design envelope300x250x280mm, no brand or output specification.
 box('Folded instrument enclosure',(0,.010,.14775),(.2995,.23,.2635),paint,.010)
 box('Front recessed fascia',(0,-.106,.150),(.276,.008,.236),graphite,.006)
 box('Blank display bezel',(-.027,-.112,.219),(.19,.008,.075),black,.004)
 box('Blank LCD no voltage/current readout',(-.027,-.117,.219),(.174,.002,.059),screen,.003)
 for z in [.163,.122]:
  cyl('Adjustment dial',(.100,-.116,z),.014,.018,black,'Y')
  cyl('Dial center',(.100,-.125+.001,z),.008,.002,steel,'Y')
  if LOD==0:
   for k in range(24):
    a=k*math.tau/24;rod('Dial knurl',(.100+.014*math.cos(a),-.122,z+.014*math.sin(a)),(.100+.014*math.cos(a),-.110,z+.014*math.sin(a)),.0005,graphite)
 # Inert terminal geometry; colors are illustrative, no electrical functionality.
 for x,m in [(-.075,red),(-.035,black),(.005,green)]:
  cyl('Insulated terminal collar',(x,-.116,.076),.009,.015,m,'Y');ring('Terminal lip',(x,-.1235,.076),.004,.0015,steel,'Y');cyl('Terminal dark recess',(x,-.1245,.076),.0026,.0005,black,'Y')
 box('Inert rocker switch',(.088,-.117,.062),(.026,.015,.021),black,.003)
 for x in [-.112,.112]:
  for y in [-.084,.085]:box('Rubber support',(x,y,.008),(.044,.040,.016),rubber,.004)
 if LOD<2:
  for x in [-.12,.12]:
   for z in [.044,.254]:screw((x,-.111,z))
  for i in range(15 if LOD==0 else 8):box('Side cooling louver',(.1497,-.075+i*(.15/(14 if LOD==0 else 7)),.17),(.0005,.005,.070),black,.001)
  for i in range(11 if LOD==0 else 6):box('Top cooling louver',(-.10+i*(.20/(10 if LOD==0 else 5)),.045,.2797),(.004,.08,.0004),black,.001)

 if LOD==2:
  # Retain end louvers so far-LOD envelope/pivot does not shift when details drop.
  for y in [-.075,.075]:box('Far cooling louver',(.1497,y,.17),(.0005,.005,.070),black)
  for x in [-.10,.10]:box('Far top louver',(x,.045,.2797),(.004,.08,.0004),black)

def render(asset):
 sc=bpy.context.scene
 if '--cutaway' in sys.argv and asset=='printer_enclosure_study':
  bpy.data.objects['Closed front glazing'].hide_render=True
 sc.render.engine='CYCLES';sc.cycles.device='CPU';sc.cycles.samples=64;sc.cycles.use_denoising=False
 points=[o.matrix_world@Vector(c) for o in sc.objects if o.type=='MESH' for c in o.bound_box];mn=Vector([min(p[i] for p in points) for i in range(3)]);mx=Vector([max(p[i] for p in points) for i in range(3)]);center=(mn+mx)/2;s=max(mx-mn)
 stage=mat('Render-only neutral stage',(.35,.38,.42),0,.8);box('Render-only stage',(0,0,-.008),(6,6,.014),stage,.001)
 bpy.ops.object.camera_add(location=center+Vector((1,-1.5,1.1))*s*2);cam=bpy.context.object;cam.rotation_euler=(center-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=s*2.05;sc.camera=cam
 for name,offset,power in [('Key',(-.8,-.8,1.6),90),('Fill',(1,-.1,.8),45),('Rim',(-.5,1,1.2),75)]:
  bpy.ops.object.light_add(type='AREA',location=center+Vector(offset)*s);o=bpy.context.object;o.name=name;o.data.energy=power*s*s;o.data.shape='DISK';o.data.size=s*.9;o.rotation_euler=(center-o.location).to_track_quat('-Z','Y').to_euler()
 if '--cutaway' in sys.argv:
  bpy.ops.object.light_add(type='AREA',location=center+Vector((0,-1,.05))*s);o=bpy.context.object;o.name='Render-only cavity inspection fill';o.data.energy=35*s*s;o.data.size=s*.4;o.rotation_euler=(center-o.location).to_track_quat('-Z','Y').to_euler()
 sc.world=bpy.data.worlds.new('Studio');sc.world.color=(.18,.18,.18);sc.view_settings.view_transform='AgX';sc.view_settings.exposure=-.7
 sc.render.resolution_x=1200;sc.render.resolution_y=1000;sc.render.resolution_percentage=100;sc.render.image_settings.file_format='PNG';sc.render.filepath=str(REVIEW/(asset+('_cutaway' if '--cutaway' in sys.argv else '')+'.png'));bpy.ops.render.render(write_still=True)

BUILDERS={'printer_enclosure_study':printer,'laser_enclosure_study':laser,'bench_power_supply':supply}
if '--render-only' in sys.argv:
 for asset in BUILDERS:
  if any(a.startswith('--asset=') for a in sys.argv) and '--asset='+asset not in sys.argv:continue
  bpy.ops.wm.open_mainfile(filepath=str(OUT/asset/(asset+'.blend')));render(asset)
 raise SystemExit(0)
records=[]
for asset,build in BUILDERS.items():
 for LOD in range(3):
  bpy.ops.wm.read_factory_settings(use_empty=True);bpy.context.preferences.filepaths.save_version=0;bpy.context.scene.unit_settings.system='METRIC';bpy.context.scene.unit_settings.scale_length=1
  paint=mat('Powder-coated alloy',(.50,.54,.55),.15,.43);graphite=mat('Graphite structural polymer',(.025,.032,.038),0,.36);black=mat('Recess dark polymer',(.008,.011,.014),0,.50);steel=mat('Satin stainless fastener',(.42,.46,.49),1,.27);brass=mat('Nozzle brass',(.56,.31,.08),1,.32);rubber=mat('Isolation elastomer',(.014,.017,.019),0,.85);glass=mat('Tinted enclosure glazing',(.65,.78,.80),0,.10,.92);screen=mat('Inactive display glass',(.025,.060,.070),0,.24);red=mat('Red terminal polymer',(.5,.02,.012),0,.4);green=mat('Green terminal polymer',(.015,.25,.07),0,.4)
  build();bpy.context.view_layer.update();objs=[o for o in bpy.context.scene.objects if o.type=='MESH'];points=[o.matrix_world@Vector(c) for o in objs for c in o.bound_box];bounds=[[min(p[i] for p in points) for i in range(3)],[max(p[i] for p in points) for i in range(3)]];tris=sum(len(p.vertices)-2 for o in objs for p in o.data.polygons)
  folder=OUT/asset;folder.mkdir(exist_ok=True);dest=folder/f'lod{LOD}_source.glb';bpy.ops.export_scene.gltf(filepath=str(dest),export_format='GLB',export_extras=True,export_yup=True)
  records.append({'asset':asset,'level':LOD,'triangles':tris,'boundsBlenderXYZ':bounds,'sizeBlenderXYZ':[bounds[1][i]-bounds[0][i] for i in range(3)],'meshParts':len(objs),'sha256':hashlib.sha256(dest.read_bytes()).hexdigest()})
  if LOD==0:
   bpy.ops.wm.save_as_mainfile(filepath=str(folder/(asset+'.blend')))
   if '--skip-render' not in sys.argv:render(asset)
(REVIEW/'build_report.json').write_text(json.dumps({'blender':bpy.app.version_string,'units':'m','scope':'Independent static equipment samples; existing design dimensions, illustrative internal structures; no operational simulation','records':records},indent=2)+'\n')
