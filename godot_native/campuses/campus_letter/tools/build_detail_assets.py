"""Editable, metric Blender assets for the campus-letter first-person samples.
Run with Blender 5.2.2. Geometry and material authorship are local; hands reuse
campus_student_rigged.glb. No labels or text are authored on these objects.
"""
import bpy, math, pathlib, json, bmesh
from mathutils import Vector, Matrix
ROOT=pathlib.Path(__file__).resolve().parents[1]
OUT=ROOT/'assets3d'/'detail';OUT.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
scene=bpy.context.scene
scene.unit_settings.system='METRIC'

def mat(name,c,metal=0,rough=.5):
 m=bpy.data.materials.new(name);m.diffuse_color=(*c,1);m.use_nodes=True
 p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*c,1);p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=rough
 return m
metal=mat('Satin graphite enamel',(.055,.11,.115),.55,.39)
silver=mat('Brushed stainless',(.42,.48,.49),.82,.29)
bronze=mat('Aged bronze',(.34,.23,.11),.72,.34)
rubber=mat('Soft black rubber',(.022,.03,.028),0,.9)
fabric=mat('Woven sage fabric',(.22,.29,.25),0,.9)
paper=mat('Ivory paper',(.77,.72,.59),0,.83)
glass=mat('Frosted optic',(.68,.78,.73),.18,.20)
wood=mat('Satin ash wood',(.42,.29,.17),0,.49)
# Reference-sourced CC0 PBR channels remain in the editable Blender source.
# Runtime uses shared Godot textures; GLB exports preserve material slot names.
PBR=ROOT/'assets3d'/'pbr'
def pbr(m,asset,use_color=True,normal_strength=.3):
 nodes=m.node_tree.nodes;links=m.node_tree.links;bsdf=nodes.get('Principled BSDF')
 for suffix,target in [('Color','Base Color'),('Roughness','Roughness')]:
  path=PBR/(asset+'_1K-JPG_'+suffix+'.jpg')
  if not path.exists() or (suffix=='Color' and not use_color):continue
  tex=nodes.new('ShaderNodeTexImage');tex.image=bpy.data.images.load(str(path),check_existing=True)
  if suffix!='Color':tex.image.colorspace_settings.name='Non-Color'
  links.new(tex.outputs['Color'],bsdf.inputs[target])
 path=PBR/(asset+'_1K-JPG_NormalGL.jpg')
 tex=nodes.new('ShaderNodeTexImage');tex.image=bpy.data.images.load(str(path),check_existing=True);tex.image.colorspace_settings.name='Non-Color'
 normal=nodes.new('ShaderNodeNormalMap');normal.inputs['Strength'].default_value=normal_strength;links.new(tex.outputs['Color'],normal.inputs['Color']);links.new(normal.outputs['Normal'],bsdf.inputs['Normal'])
pbr(wood,'Wood051',normal_strength=.22)
pbr(silver,'Metal032',False,.12)
pbr(bronze,'Metal032',False,.10)
pbr(metal,'Metal032',False,.08)
pbr(fabric,'Fabric041',False,.38)
COL=None

def begin(name):
 global COL
 COL=bpy.data.collections.new(name);scene.collection.children.link(COL)
 return COL

def assign(o,name,m):
 o.name=name;o.data.materials.clear();o.data.materials.append(m)
 for c in list(o.users_collection):c.objects.unlink(o)
 COL.objects.link(o)
 if o.type=='MESH':
  for f in o.data.polygons:f.use_smooth=True
 return o

def bevel(o,width=.008,segments=6):
 b=o.modifiers.new('Manufactured edge radius','BEVEL');b.width=width;b.segments=segments
 n=o.modifiers.new('Weighted face normals','WEIGHTED_NORMAL');n.keep_sharp=True
 return o

def cube(name,p,size,m,r=.008):
 bpy.ops.mesh.primitive_cube_add(size=1,location=p);o=bpy.context.object;o.dimensions=size;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);assign(o,name,m);bevel(o,r,6);return o

def cyl(name,p,r,h,m,axis=None):
 bpy.ops.mesh.primitive_cylinder_add(vertices=96,radius=r,depth=h,location=p);o=assign(bpy.context.object,name,m)
 if axis:o.rotation_mode='QUATERNION';o.rotation_quaternion=Vector((0,0,1)).rotation_difference(Vector(axis))
 bevel(o,min(.006,r*.12),6);return o

def tube(name,a,b,r,m):
 a,b=Vector(a),Vector(b);return cyl(name,(a+b)/2,r,(b-a).length,m,b-a)

def sphere(name,p,scale,m):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=64,ring_count=40,radius=1,location=p);o=assign(bpy.context.object,name,m);o.scale=scale;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);return o

def torus(name,p,major,minor,m,rot=(0,0,0)):
 bpy.ops.mesh.primitive_torus_add(major_segments=96,minor_segments=20,location=p,major_radius=major,minor_radius=minor,rotation=rot);return assign(bpy.context.object,name,m)

def curve(name,points,r,m):
 data=bpy.data.curves.new(name,'CURVE');data.dimensions='3D';data.resolution_u=24;data.bevel_depth=r;data.bevel_resolution=6
 s=data.splines.new('BEZIER');s.bezier_points.add(len(points)-1)
 for b,p in zip(s.bezier_points,points):b.co=p;b.handle_left_type='AUTO';b.handle_right_type='AUTO'
 o=bpy.data.objects.new(name,data);COL.objects.link(o);data.materials.append(m);return o

def screw(p,axis=(0,0,1),r=.012):
 o=cyl('Recessed screw',p,r,.008,silver,axis)
 # Recess as a separate dark inset, no graphic decal or text.
 p=Vector(p)+Vector(axis)*.005
 slot=cube('Screw head slot',p,(r*1.35,.002,.002),rubber,.0005)
 if abs(axis[1])>.5:slot.rotation_euler.x=math.pi/2
 return o

def shell(name,nu,nv,point,m,thickness=.024):
 verts=[point(u/nu,v/nv) for v in range(nv+1) for u in range(nu+1)];faces=[]
 for v in range(nv):
  for u in range(nu):
   i=v*(nu+1)+u;faces.append((i,i+1,i+nu+2,i+nu+1))
 data=bpy.data.meshes.new(name);data.from_pydata(verts,[],faces);data.update();o=bpy.data.objects.new(name,data);COL.objects.link(o);data.materials.append(m)
 uv=data.uv_layers.new(name='UVMap')
 for loop in data.loops:
  i=loop.vertex_index;uv.data[loop.index].uv=(i%(nu+1)/nu,i//(nu+1)/nv)
 for f in data.polygons:f.use_smooth=True
 solid=o.modifiers.new('Real shell thickness','SOLIDIFY');solid.thickness=thickness;bevel(o,.008,3);return o

def export(name):
 bpy.ops.object.select_all(action='DESELECT')
 for o in COL.objects:o.select_set(True)
 bpy.context.view_layer.objects.active=next(iter(COL.objects))
 # Applied copies keep the authoring source editable and guarantee valid glTF normals.
 # The engine shares one PBR texture set per material across every asset.
 held=[]
 for m in bpy.data.materials:
  if not m.use_nodes:continue
  bsdf=m.node_tree.nodes.get('Principled BSDF')
  if not bsdf:continue
  for socket in bsdf.inputs:
   for link in list(socket.links):held.append((m,link.from_socket,link.to_socket));m.node_tree.links.remove(link)
 bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),use_selection=True,export_apply=True,export_yup=True,export_materials='EXPORT',export_image_format='AUTO',export_cameras=False,export_lights=False)
 for m,a,b in held:m.node_tree.links.new(a,b)
 for o in COL.objects:o.hide_set(True)

begin('reading_chair')
for x in [-.22,.22]:
 for y in [-.22,.22]:
  tube('Tapered steel leg',(x*1.12,y*1.12,.035),(x,y,.46),.018,metal);cyl('Quiet floor glide',(x*1.12,y*1.12,.025),.023,.028,rubber)
for y in [-.20,.20]:tube('Underseat stretcher',(-.22,y,.39),(.22,y,.39),.014,metal)
shell('Sculpted plywood seat',32,32,lambda u,v:((u-.5)*.51,(v-.5)*.48,.47+.035*(abs(u-.5)*2)**3+.022*(v-.5)**2),wood,.026)
shell('Soft upholstered seat',32,32,lambda u,v:((u-.5)*.46,(v-.5)*.42,.50+.018*math.sin(u*math.pi)*math.sin(v*math.pi)),fabric,.026)
shell('Curved plywood back',40,28,lambda u,v:((u-.5)*.5,-.24-.10*v+.07*(u-.5)**2,.60+v*.43),wood,.025)
shell('Back fabric inset',40,28,lambda u,v:((u-.5)*.44,-.219-.10*v+.07*(u-.5)**2,.63+v*.36),fabric,.018)
for x in [-.23,.23]:
 curve('Back support',[(x,-.18,.40),(x,-.25,.67),(x,-.30,.89)],.014,metal)
 curve('Arm rest tube',[(x,.19,.45),(x,.15,.67),(x,-.22,.69)],.013,metal)
 cube('Rounded timber arm pad',(x,-.02,.69),(.065,.29,.036),wood,.016)
 screw((x,-.346,.89),(0,-1,0))
for y in [-.20,.20]:
 curve('Upholstery piping',[(-.21,y,.506),(-.10,y,.515),(.10,y,.515),(.21,y,.506)],.0024,fabric)
export('reading_chair')

begin('study_desk')
cube('Solid rounded ash top',(0,0,.83),(1.9,1.28,.075),wood,.035)
cube('Inset underframe',(0,0,.735),(1.61,.98,.08),metal,.015)
for x in [-.76,.76]:
 for y in [-.43,.43]:
  tube('Round steel leg',(x,y,.04),(x*.97,y*.94,.78),.027,metal);cyl('Rubber leveler',(x,y,.026),.033,.04,rubber);screw((x,y,.87),r=.007)
# Cable grommet is a modeled inset with a split lid.
cyl('Cable grommet',(.68,.44,.872),.055,.012,metal);cube('Cable slot',(.68,.44,.88),(.085,.008,.003),rubber,.002)
export('study_desk')

begin('worktable')
cube('Rounded workshop top',(0,0,2.025),(3.9,2.1,.13),wood,.055)
for x in [-1.55,1.55]:
 for y in [-.77,.77]:
  tube('Worktable leg',(x,y,.10),(x,y,1.96),.057,metal);cyl('Adjustable foot',(x,y,.07),.08,.12,rubber)
for y in [-.77,.77]:tube('Long underframe',(-1.6,y,1.8),(1.6,y,1.8),.047,metal)
for x in [-1.55,1.55]:
 tube('End underframe',(x,-.8,1.8),(x,.8,1.8),.047,metal);tube('Foot stretcher',(x,-.77,.42),(x,.77,.42),.04,metal)
for x in [-1.55,1.55]:
 for y in [-.77,.77]:screw((x,y,2.093),r=.012)
export('worktable')

begin('bridge_support')
cube('Laminated ash support',(0,0,.23),(.24,.85,.46),wood,.021)
cube('Replaceable rubber saddle',(0,0,.477),(.265,.86,.035),rubber,.009)
for y in [-.22,.22]:screw((0,y,.5),r=.009)
cyl('Lead screw shaft',(0,-.48,.22),.025,.18,silver,(0,1,0))
cyl('Knurled adjustment wheel',(0,-.58,.22),.09,.07,metal,(0,1,0))
for i in range(32):
 a=i*math.tau/32;cyl('Knurled rim',(math.cos(a)*.087,-.58,.22+math.sin(a)*.087),.006,.065,bronze,(0,1,0))
cyl('Wheel fastener',(0,-.622,.22),.022,.012,silver,(0,1,0))
export('bridge_support')

begin('calibration_weight')
cyl('Weight base',(0,0,.035),.18,.07,silver)
cyl('Machined body',(0,0,.17),.168,.23,silver)
torus('Turned shoulder',(0,0,.28),.13,.026,silver)
cyl('Neck',(0,0,.31),.065,.07,silver)
cyl('Grip',(0,0,.357),.085,.04,bronze)
for z in [.08,.095,.11]:torus('Machining line',(0,0,z),.169,.0017,bronze)
export('calibration_weight')

begin('projection_lamp')
cyl('Weighted cast foot',(0,0,.075),.29,.15,metal)
for x in [-.18,.18]:
 for y in [-.12,.12]:cyl('Rail roller',(x,y,.045),.052,.04,rubber,(1,0,0))
cyl('Outer stand tube',(0,0,.42),.047,.60,metal);cyl('Telescopic chrome tube',(0,0,.86),.032,.44,silver)
cyl('Stand collar',(0,0,.68),.062,.09,metal);cyl('Collar thumbscrew',(.09,0,.68),.027,.10,bronze,(1,0,0))
curve('Tilting yoke',[(-.23,0,1.23),(-.23,0,1.0),(0,0,.97),(.23,0,1.0),(.23,0,1.23)],.018,metal)
cyl('Projector barrel',(0,0,1.18),.18,.42,metal,(0,1,0));cyl('Lens retaining ring',(0,.223,1.18),.18,.034,bronze,(0,1,0));cyl('Optical glass',(0,.245,1.18),.15,.015,glass,(0,1,0))
for side in [-1,1]:cyl('Yoke pivot',(side*.22,0,1.18),.046,.08,bronze,(1,0,0))
for z in [1.05,1.10,1.15,1.20,1.25,1.30]:cube('Cooling slot',(0,-.217,z),(.19,.014,.011),rubber,.004)
for i in range(8):
 a=i*math.tau/8;screw((math.cos(a)*.163,.245,1.18+math.sin(a)*.163),(0,1,0),.006)
curve('Carrying handle',[(-.12,-.12,1.35),(-.12,-.12,1.49),(.12,-.12,1.49),(.12,-.12,1.35)],.012,rubber)
curve('Power cable',[(.08,-.19,1.09),(.13,-.30,.86),(.11,-.18,.4),(.24,-.25,.08),(.38,-.17,.025)],.008,rubber)
export('projection_lamp')

begin('survey_wheel')
torus('Brass handwheel',(0,0,0),.25,.027,bronze,(math.pi/2,0,0))
cyl('Axle hub',(0,0,0),.07,.16,metal,(0,1,0))
for a in [0,math.tau/3,math.tau*2/3]:tube('Cast spoke',(0,0,0),(.23*math.cos(a),0,.23*math.sin(a)),.013,bronze)
cyl('Center nut',(0,-.093,0),.027,.018,silver,(0,1,0))
cyl('Rotation grip',(.19,-.075,.125),.025,.15,rubber,(0,1,0))
export('survey_wheel')

begin('reading_lamp')
cyl('Weighted base',(0,0,.018),.115,.036,metal)
torus('Base perimeter lip',(0,0,.031),.105,.004,silver)
a=Vector((0,0,.06));b=Vector((-.10,0,.28));c=Vector((.09,0,.47))
for shift in [-.014,.014]:
 tube('Lower parallel arm',a+Vector((0,shift,0)),b+Vector((0,shift,0)),.008,metal)
 tube('Upper parallel arm',b+Vector((0,shift,0)),c+Vector((0,shift,0)),.008,metal)
for q in [a,b,c]:
 cyl('Arm joint pin',q,.020,.06,silver,(0,1,0))
 for side in [-1,1]:screw(q+Vector((0,side*.034,0)),(0,side,0),.009)
# Closed, smoothly revolved double-wall bell shade; no raster fake.
verts=[];faces=[];steps=96
profile=[(.030,0),(.036,-.012),(.052,-.045),(.073,-.10),(.078,-.12),(.075,-.125),(.071,-.118),(.066,-.10),(.046,-.045),(.028,-.014)]
axis=Vector((.35,0,-.937));rotation=Vector((0,0,-1)).rotation_difference(axis)
for r,z in profile:
 for i in range(steps):
  q=rotation@Vector((r*math.cos(i*math.tau/steps),r*math.sin(i*math.tau/steps),z));verts.append(q+c)
for j in range(len(profile)-1):
 for i in range(steps):a0=j*steps+i; a1=j*steps+(i+1)%steps;faces.append((a0,a1,a1+steps,a0+steps))
d=bpy.data.meshes.new('BellShade');d.from_pydata(verts,[],faces);d.update();o=bpy.data.objects.new('Double wall aluminium shade',d);COL.objects.link(o);d.materials.append(metal)
for f in d.polygons:f.use_smooth=True
sphere('Frosted bulb',c+rotation@Vector((0,0,-.075)),(.029,.029,.042),glass)
curve('Braided power cable',[(0,-.025,.045),(-.07,-.05,.012),(-.19,-.14,.008),(-.25,-.24,.008)],.0035,rubber)
export('reading_lamp')

begin('campus_bench')
for x in [-.76,.76]:
 curve('Curved cast support',[(x,.25,.04),(x,.28,.40),(x,.20,.48),(x,-.25,.49),(x,-.32,.78),(x,-.36,1.03)],.028,metal)
 curve('Rear foot support',[(x,-.28,.47),(x,-.37,.06)],.026,metal)
 for y in [-.37,.25]:cyl('Quiet foot',(x,y,.025),.043,.025,rubber)
for y in [-.23,-.08,.07,.22]:
 cube('Rounded seat timber',(0,y,.49),(2,.13,.055),wood,.014)
 for x in [-.76,.76]:screw((x,y,.520),r=.007)
for z,y in [(.78,-.31),(.96,-.35)]:
 slat=cube('Rounded back timber',(0,y,z),(2,.055,.14),wood,.012);slat.rotation_euler.x=-.13
 for x in [-.76,.76]:screw((x,y+.033,z),(0,1,0),.007)
export('campus_bench')

begin('reading_book')
cube('Bound pages',(0,0,.020),(.365,.478,.033),paper,.007)
for z in [.002,.040]:cube('Cloth hardback cover',(0,0,z),(.386,.50,.008),fabric,.004)
cube('Curved cloth spine',(-.188,0,.022),(.012,.50,.037),fabric,.005)
for z in [.009,.015,.022,.028,.034]:
 cube('Layered paper edge',(.184,0,z),(.002,.467,.0012),paper,.0003)
curve('Woven bookmark',[(.10,.19,.042),(.10,.254,.038),(.10,.283,.008)],.003,bronze)
export('reading_book')

begin('letter_box')
cube('Cast base plate',(0,0,.035),(.50,.40,.07),metal,.025)
for x in [-.18,.18]:
 for y in [-.13,.13]:screw((x,y,.074),r=.012)
cyl('Tubular post',(0,0,.40),.055,.70,metal)
cyl('Post collar',(0,0,.70),.075,.09,silver)
cube('Curved rear cabinet',(0,.18,1.045),(.63,.07,.65),metal,.030)
for x in [-.30,.30]:cube('Rounded side shell',(x,0,1.045),(.065,.39,.65),metal,.026)
cube('Cabinet floor',(0,0,.755),(.63,.40,.065),metal,.025)
cube('Drip cap',(0,-.015,1.385),(.69,.47,.065),metal,.030)
cube('Lower access door',(0,-.205,.94),(.60,.045,.40),metal,.020)
cube('Upper slot lip',(0,-.205,1.31),(.60,.045,.15),metal,.019)
cube('Dark mail opening',(0,-.17,1.185),(.55,.012,.080),rubber,.012)
for x in [-.267,.267]:
 cyl('Door hinge',(x,-.236,.96),.012,.13,silver)
cyl('Door lock',(0,-.239,.84),.018,.012,silver,(0,1,0))
cube('Key recess',(0,-.246,.84),(.003,.002,.018),rubber,.001)
hinge=bpy.data.objects.new('MailSlotFlap',None);COL.objects.link(hinge);hinge.location=(0,-.243,1.235)
flap=cube('Brushed slot flap',(0,0,0),(.55,.014,.072),bronze,.009);flap.parent=hinge;flap.location=(0,0,-.036)
export('letter_box')

# Preserve actual hand surface detail from the established campus character mesh.
for c in scene.collection.children:
 for o in c.objects:o.hide_set(True)
begin('sculpture_hands')
before=set(bpy.data.objects)
bpy.ops.import_scene.gltf(filepath=str(ROOT.parents[1]/'assets/native_755/ride/rodin/campus_student_rigged.glb'))
source=next(o for o in set(bpy.data.objects)-before if o.type=='MESH' and len(o.vertex_groups)>1)
for side,name in [(-1,'WristL'),(1,'WristR')]:
 group=source.vertex_groups[name].index
 selected={v.index for v in source.data.vertices if sum(g.weight for g in v.groups if g.group==group)>.12}
 faces=[list(p.vertices) for p in source.data.polygons if all(i in selected for i in p.vertices)]
 used=sorted({i for f in faces for i in f});ids={j:i for i,j in enumerate(used)}
 wrist=Vector((side*.62,0,1.42));rot=Matrix.Rotation(math.pi,4,'Y')
 verts=[]
 for i in used:
  p=(source.matrix_world@source.data.vertices[i].co)-wrist;p=rot@p;p*=2.8;p+=Vector((side*.31,0,.20));verts.append(p)
 data=bpy.data.meshes.new(name);data.from_pydata(verts,[],[[ids[i] for i in f] for f in faces]);data.update()
 o=bpy.data.objects.new('Detailed cast hand '+name,data);COL.objects.link(o);data.materials.append(silver)
 for f in data.polygons:f.use_smooth=True
 b=o.modifiers.new('Cast metal micro smoothing','SMOOTH');b.factor=.2;b.iterations=2
 sub=o.modifiers.new('Curved cast surface refinement','SUBSURF');sub.levels=1;sub.render_levels=1
 cyl('Wrist mounting sleeve',(side*.31,0,.13),.115,.26,silver)
for o in set(bpy.data.objects)-before:
 if o not in COL.objects.values():bpy.data.objects.remove(o,do_unlink=True)
export('sculpture_hands')
for c in scene.collection.children:
 for o in c.objects:o.hide_set(False)
SOURCE=ROOT/'authoring';SOURCE.mkdir(exist_ok=True);(SOURCE/'.gdignore').touch()
bpy.ops.file.pack_all()
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE/'campus_objects.blend'))
report={c.name:{'objects':len(c.objects),'vertices':sum(len(o.data.vertices) for o in c.objects if o.type=='MESH')} for c in scene.collection.children if len(c.objects)}
(OUT/'asset_manifest.json').write_text(json.dumps({'generator':'Blender 5.2.2','units':'metres','text_on_objects':False,'collections':report,'hand_source':'assets/native_755/ride/rodin/campus_student_rigged.glb','material_source':'ambientCG Wood051, Concrete034, Metal032, Fabric041; CC0-1.0; see assets3d/pbr/sources.json'},ensure_ascii=False,indent=2))
print('DETAIL_ASSETS_COMPLETE',report)
