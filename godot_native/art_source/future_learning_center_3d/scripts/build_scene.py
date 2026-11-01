"""Meter-scale authoring model, recovered from preserved source-pixel traces.
Run: Blender --background --factory-startup --python scripts/build_scene.py
No generated/provider geometry is claimed. Shared dimension-driven assets are linked.
"""
import bpy, math, json, hashlib
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1]; WEB=ROOT/'web'
WIDTH,LENGTH,RISE=26.1,42.4,4.05
BOUNDS={2:(103,91,796,1217),3:(94,46,440,621),4:(70,52,640,975)}
ROOMS={2:[('seminar',(256,97,553,254),'south','研讨室'),('formula',(109,325,326,534),'east','方程式工作室'),('team',(109,545,326,769),'east','团队工作室'),('robotics',(109,777,326,965),'east','ASABE 机器人室'),('mechatronics',(625,434,791,1055),'west','机电实验区'),('koala',(350,1070,790,1210),'north','考拉空间')],3:[('seminar',(219,49,321,128),'south','研讨室'),('studio_1',(98,164,179,219),'east','团队工作室 1'),('studio_2',(98,219,179,276),'east','团队工作室 2'),('studio_3',(98,276,179,333),'east','团队工作室 3'),('studio_4',(98,333,179,389),'east','团队工作室 4'),('recording',(98,397,179,489),'east','录播室'),('pantry',(219,541,321,620),'north','茶水与休息区'),('xlab',(344,222,437,620),'west','X-Lab')],4:[('storage',(195,61,261,175),'south','储物间'),('seminar_1',(74,239,210,424),'east','研讨室 1'),('seminar_2',(74,427,210,610),'east','研讨室 2'),('seminar_3',(74,615,210,770),'east','研讨室 3'),('focus',(492,336,633,606),'west','专注学习区'),('collab',(492,614,633,835),'west','协作学习区'),('flex',(446,849,633,969),'north','灵活学习区')]}
VOIDS={2:[],3:[[(222,168),(321,168),(321,504),(234,489)]],4:[[(270,61),(439,61),(439,174),(280,169)],[(270,248),(439,248),(439,793),(288,770)],[(270,859),(439,859),(439,968),(289,964)]]}
def point(f,x,z):
 a,b,c,d=BOUNDS[f];return [(x-a)/(c-a)*WIDTH,(z-b)/(d-b)*LENGTH]
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
scene=bpy.context.scene;scene.unit_settings.system='METRIC';scene.unit_settings.scale_length=1
scene['status']='Metric review, restored tracing evidence; not surveyed site geometry'
scene['unit']='meter'
parent=None; current_floor=0; root_floor=None
meta={'schema':1,'units':'m','width':WIDTH,'length':LENGTH,'rise':RISE,'eyeHeight':1.65,'radius':.24,'speed':1.5,'floors':{},'scope':'2F/3F/4F restored source-pixel traces. 1F plan unavailable. Exact openings, heights and furniture inventory remain provisional.'}
def material(name,color,metal=0,rough=.65,alpha=1):
 m=bpy.data.materials.new(name);m.use_nodes=True;m.diffuse_color=(*color,alpha)
 b=m.node_tree.nodes.get('Principled BSDF');b.inputs['Base Color'].default_value=(*color,alpha);b.inputs['Metallic'].default_value=metal;b.inputs['Roughness'].default_value=rough;b.inputs['Alpha'].default_value=alpha
 if alpha<1:m.surface_render_method='DITHERED'
 return m
white=material('Plaster',(.81,.83,.80));gray=material('Terrazzo gray',(.46,.49,.48));wood=material('Oak',(.58,.39,.20));paper=material('Warm desk',(.81,.81,.76));metal=material('Steel',(.45,.50,.53),.8,.28);black=material('Charcoal',(.055,.066,.070));meshmat=material('Chair mesh',(.12,.15,.15));blue=material('Blue reference',(.035,.22,.48));glass=material('Window glass',(.41,.66,.70),.1,.15,.23);rubber=material('Dark rubber',(.018,.025,.029));red=material('Tool handle',(.56,.065,.027));yellow=material('Tool insulation',(.91,.64,.09));display=material('LCD',(.27,.34,.27));leaf=material('Foliage',(.14,.25,.17));soil=material('Soil',(.17,.12,.07))
def empty(name,x=0,y=0,z=0):
 ob=bpy.data.objects.new(name,None);scene.collection.objects.link(ob);ob.location=(x,-z,y)
 if parent:ob.parent=parent
 return ob
def box(name,x,y,z,w,h,d,mat,bevel=0,kind='furniture'):
 bpy.ops.mesh.primitive_cube_add(size=1,location=(x,-z,y));ob=bpy.context.object;ob.name=name;ob.scale=(w,d,h);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 if mat:ob.data.materials.append(mat)
 if parent:ob.parent=parent
 ob['kind']=kind;ob['floor']=current_floor
 if bevel:
  m=ob.modifiers.new('Manufactured edge','BEVEL');m.width=bevel;m.segments=2
  bpy.context.view_layer.objects.active=ob;bpy.ops.object.modifier_apply(modifier=m.name)
 return ob
def cyl(name,x,y,z,r,h,mat):
 bpy.ops.mesh.primitive_cylinder_add(vertices=16,radius=r,depth=h,location=(x,-z,y));ob=bpy.context.object;ob.name=name;ob.data.materials.append(mat)
 if parent:ob.parent=parent
 ob['kind']='furniture';ob['floor']=current_floor
 return ob
def bar(name,a,b,r,mat):
 av=Vector((a[0],-a[2],a[1]));bv=Vector((b[0],-b[2],b[1]));mid=(av+bv)/2
 ob=cyl(name,mid.x,mid.z,-mid.y,r,(bv-av).length,mat);ob.rotation_euler=(bv-av).to_track_quat('Z','Y').to_euler();return ob
def solid(id,x,z,w,d,kind='furniture'):
 meta['floors'][str(current_floor)]['colliders'].append({'id':id,'kind':kind,'rect':[x-w/2,z-d/2,x+w/2,z+d/2]})
def wall(name,a,b,h=3.1,mat=white,block=True):
 dx,dz=b[0]-a[0],b[1]-a[1];length=math.hypot(dx,dz)
 ob=box(name,(a[0]+b[0])/2,h/2,(a[1]+b[1])/2,length,h,.10,mat,kind='wall');ob.rotation_euler.z=-math.atan2(dz,dx)
 if block:meta['floors'][str(current_floor)]['colliders'].append({'id':name,'kind':'wall','segment':[a,b],'width':.10})
 return ob
def prism(name,poly,y,height,mat):
 from mathutils.geometry import tessellate_polygon
 pts=[Vector((x,-z,0)) for x,z in poly]
 area=sum(pts[i].x*pts[(i+1)%len(pts)].y-pts[(i+1)%len(pts)].x*pts[i].y for i in range(len(pts)))
 if area<0:pts.reverse()
 n=len(pts);vertices=[(p.x,p.y,y) for p in pts]+[(p.x,p.y,y+height) for p in pts];faces=[]
 for t in tessellate_polygon([pts]):
  ids=[v if isinstance(v,int) else pts.index(v) for v in t];faces += [tuple(reversed(ids)),tuple(i+n for i in ids)]
 faces.extend((i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n))
 mesh=bpy.data.meshes.new(name);mesh.from_pydata(vertices,[],faces);mesh.update();ob=bpy.data.objects.new(name,mesh);scene.collection.objects.link(ob);ob.data.materials.append(mat)
 if parent:ob.parent=parent
 return ob
def slab(name,voids,y,mat):
 ob=box(name,WIDTH/2,y,LENGTH/2,WIDTH,.16,LENGTH,mat,kind='ceiling' if name=='Ceiling' else 'floor')
 for poly in voids:
  cutter=prism('void cutter',poly,y-.3,.6,gray);bpy.context.view_layer.objects.active=ob;m=ob.modifiers.new('Source atrium','BOOLEAN');m.operation='DIFFERENCE';m.object=cutter;bpy.ops.object.modifier_apply(modifier=m.name);bpy.data.objects.remove(cutter,do_unlink=True)
 return ob
# Shared reusable library. Geometry uses actual units; instances never resize by view.
LIB={}
def prototype(asset,fn):
 global parent,current_floor
 old=parent;parent=None;current_floor=0;group=empty('Library '+asset);parent=group;fn();parent=old;LIB[asset]=group
 return group
def instance(asset,x,z,angle=0):
 group=LIB[asset];root=empty(asset,x,0,z);root.rotation_euler.z=-angle;root['assetId']=asset;root['floor']=current_floor
 for original in group.children:
  ob=original.copy();ob.data=original.data;scene.collection.objects.link(ob);ob.parent=root;ob['floor']=current_floor
 return root
def make_chair():
 box('Seat cushion',0,.46,0,.46,.075,.49,black,.025)
 box('Back mesh',0,.82,.23,.45,.55,.034,meshmat,.014)
 for x in [-.235,.235]:bar('Back frame',(x,.50,.22),(x,1.10,.23),.013,black)
 bar('Back top',(-.235,1.10,.23),(.235,1.10,.23),.014,black)
 cyl('Gas lift',0,.255,0,.035,.35,metal)
 for i in range(5):
  a=i*math.tau/5;x,z=math.cos(a)*.32,math.sin(a)*.32
  bar('Star base',(0,.15,0),(x,.10,z),.019,black);cyl('Caster',x,.06,z,.035,.07,rubber)
 for x in [-.29,.29]:
  bar('Arm support',(x,.50,.12),(x,.66,.12),.017,black);box('Arm rest',x,.67,0,.055,.035,.28,black,.01)
def make_desk():
 box('Desk top',0,.71,0,1.4,.04,.60,paper,.012)
 for x in [-.62,.62]:
  for z in [-.235,.235]:cyl('Desk leg',x,.345,z,.025,.69,white)
 box('Monitor base',0,.755,.14,.24,.025,.15,black,.01);box('Monitor stand',0,.86,.18,.045,.21,.035,metal)
 box('Monitor frame',0,1.04,.18,.53,.32,.04,black,.012);box('Screen',0,1.04,.155,.485,.275,.006,blue)
 box('Keyboard',0,.747,-.12,.42,.022,.13,black,.008);box('Mouse',.34,.753,-.12,.055,.035,.09,black,.018)
 box('Paper stack',-.47,.747,-.03,.21,.015,.26,white)
def make_caliper():
 # Mitutoyo E12047 p.6/7: L233, H16, outside jaw40, inside21, jaw thickness3.5mm.
 box('Beam',.1165,.004,0,.233,.0035,.016,metal)
 box('Fixed jaw',.008,.004,.022,.012,.0035,.04,metal)
 box('Inside fixed',.008,.004,-.018,.006,.0035,.021,metal)
 box('Slider',.066,.012,0,.050,.018,.026,black,.0015)
 box('Display',.066,.022,-.001,.031,.001,.013,display)
 box('Moving jaw',.085,.004,.022,.012,.0035,.04,metal)
 box('Inside moving',.083,.004,-.018,.006,.0035,.021,metal)
 for x in [.052,.065,.078]:cyl('Button',x,.024,.010,.002,.002,blue)
 for i in range(0,151,5):box('Scale tick',.018+i/1000,.006,0,.00025,.0003,.007 if i%10==0 else .004,black)
 cyl('Thumb roller',.085,.007,.026,.006,.004,metal)
def make_driver():
 # Wiha 320N 00821: blade100mm, overall204mm, handle diameter23mm.
 ob=cyl('Handle',.052,.012,0,.0115,.104,red);ob.rotation_euler.y=math.pi/2
 ob=cyl('Insulated collar',.102,.012,0,.009,.015,yellow);ob.rotation_euler.y=math.pi/2
 ob=cyl('Shaft',.150,.012,0,.003,.092,metal);ob.rotation_euler.y=math.pi/2
 box('Slotted tip',.200,.012,0,.008,.0005,.003,metal)
 for i in range(5):box('Grip rib',.018+i*.016,.022,0,.006,.002,.014,rubber,.001)
prototype('office_chair',make_chair);prototype('office_desk',make_desk);prototype('caliper_150',make_caliper);prototype('screwdriver_3x100',make_driver)

def workstation(x,z,angle=0):
 instance('office_desk',x,z,angle);solid('Desk',x,z,1.4,.60)
 dz=-.62 if angle==0 else .62
 instance('office_chair',x,z+dz,angle+math.pi);solid('Chair',x,z+dz,.71,.71)
def bank(cx,cz):
 for dx in [-.71,.71]:
  workstation(cx+dx,cz-.31,0)
  workstation(cx+dx,cz+.31,math.pi)
 box('Shared gray divider',cx,1.0,cz,2.8,.48,.035,meshmat)
def cupboard(x,z,width=1.2,north=False):
 box('Oak cabinet',x,.9,z,width,1.8,.40,wood,.012);solid('Cabinet',x,z,width,.40)
 for dx in [-width/4,width/4]:
  box('Cabinet front',x+dx,.9,z+(.21 if north else -.21),width/2-.015,1.72,.025,paper,.008)
  box('Cabinet pull',x+dx,.97,z+(.235 if north else -.235),.015,.15,.02,metal)
def table(x,z,w=2.4,d=1.0):
 box('Communal tabletop',x,.74,z,w,.06,d,wood,.02);solid('Table',x,z,w,d)
 for dx in [-w/2+.18,w/2-.18]:box('Table support',x+dx,.36,z,.08,.7,d-.15,black)
def furnish(room):
 x0,z0,x1,z1=room['bounds'];cx=(x0+x1)/2;cz=(z0+z1)/2;name=room['id'];w=x1-x0;d=z1-z0
 if name.startswith('studio_') or name in ['focus','collab','team','xlab','koala']:
  count=1 if name.startswith('studio_') else max(1,int((d-1.4)/4.2))
  for i in range(count):bank(cx,z0+min(d/2,2.1)+i*4.2)
  if d>5:cupboard(x0+1.0,z1-.30,1.5)
 elif name=='pantry':
  table(cx,cz,3.8,1.3)
  for dx in [-1.2,0,1.2]:
   for side in [-1,1]:instance('office_chair',cx+dx,cz+side*1.0,0 if side==1 else math.pi);solid('Lounge chair',cx+dx,cz+side, .71,.71)
  box('Planter',cx,.88,cz,.65,.24,.55,wood,.02);cyl('Soil',cx,1.01,cz,.20,.02,soil);cyl('Tree trunk',cx,1.7,cz,.035,1.4,wood)
  for i in range(5):
   a=i*math.tau/5;ob=box('Tree canopy',cx+math.cos(a)*.3,2.25+math.sin(a)*.1,cz+math.sin(a)*.3,.65,.4,.55,leaf,.16)
  cupboard(x0+1.3,z1-.3,2.0)
  box('Sofa base',x1-1.2,.34,z1-.65,1.9,.45,.72,meshmat,.06);box('Sofa back',x1-1.2,.72,z1-.25,1.9,.5,.16,meshmat,.04);solid('Sofa',x1-1.2,z1-.65,1.9,.85)
 elif name=='storage':
  cupboard(cx,z0+.3,max(.8,w-.5),north=True)
 elif name in ['mechatronics','robotics','formula']:
  for i in range(max(1,int(d/4))):
   tz=z0+2+i*3.5;table(cx,tz,2.2,1.0)
   for asset,dx,dz in [('caliper_150',-.35,-.18),('screwdriver_3x100',.15,-.1)]:
    ob=instance(asset,cx+dx,tz+dz);ob.location.z=.78;ob['inspectable']=True
    meta['floors'][str(current_floor)]['tools'].append({'assetId':asset,'position':[cx+dx,.78,tz+dz]})
  cupboard(x0+1.2,z1-.3,1.8)
 else:
  table(cx,cz,min(3.3,w-1.5),min(1.4,d/3))
  for dx in [-.8,.8]:
   for side in [-1,1]:instance('office_chair',cx+dx,cz+side*1.1,0 if side==1 else math.pi);solid('Seminar chair',cx+dx,cz+side*1.1,.71,.71)
  box('Whiteboard',cx,1.6,z0+.09,min(2.4,w-.6),1.1,.05,paper)

def build_room(f,entry):
 name,rect,front,label=entry;a=point(f,rect[0],rect[1]);b=point(f,rect[2],rect[3]);x0,z0=a;x1,z1=b
 room={'id':name,'name':label,'bounds':[x0,z0,x1,z1],'area':round((x1-x0)*(z1-z0),2),'sourceRect':rect,'front':front}
 edges={'north':([x0,z0],[x1,z0]),'south':([x0,z1],[x1,z1]),'west':([x0,z0],[x0,z1]),'east':([x1,z0],[x1,z1])}
 for edge,(a,b) in edges.items():
  if edge!=front:
   exterior = (edge=='west' and x0<.45) or (edge=='east' and WIDTH-x1<.45)
   if exterior:
    wall(name+' window base',a,b,h=.90)
    wall(name+' window glazing',a,b,h=3.1,mat=glass,block=False)
    span=math.dist(a,b)
    for i in range(1,max(2,int(span/1.4))):
     t=i/max(2,int(span/1.4));box('Room window mullion',a[0]+(b[0]-a[0])*t,2,a[1]+(b[1]-a[1])*t,.055,2.2,.055,white,kind='wall')
   else:wall(name+' partition',a,b)
   continue
  # Restore prior plan-facing aperture at the quarter point. Door offsets remain approximate.
  length=math.dist(a,b);ux=(b[0]-a[0])/length;uz=(b[1]-a[1])/length;c=[a[0]+ux*length*.25,a[1]+uz*length*.25]
  left=[c[0]-ux*.58,c[1]-uz*.58];right=[c[0]+ux*.58,c[1]+uz*.58]
  wall(name+' glazed frontage',a,left,mat=glass);wall(name+' glazed frontage',right,b,mat=glass)
  for p in [left,right]:box('Door jamb',p[0],1.1,p[1],.06,2.2,.06,metal,kind='wall')
  room['door']=c;normal={'north':[0,1],'south':[0,-1],'west':[1,0],'east':[-1,0]}[front]
  room['spawn']=[c[0]+normal[0]*.65,c[1]+normal[1]*.65];room['heading']=math.atan2(-normal[0],-normal[1])
  # Visible header, above the observer. It never becomes a floor-level collider.
  ob=box('Door header',c[0],2.65,c[1],1.16,.9,.10,white,kind='wall');ob.rotation_euler.z=-math.atan2(uz,ux)
 furnish(room);meta['floors'][str(f)]['rooms'].append(room)

for f in [2,3,4]:
 current_floor=f;parent=None;root_floor=empty('Floor '+str(f),0,(f-2)*RISE,0);root_floor['floorRoot']=f;parent=root_floor
 voids=[[point(f,*p) for p in poly] for poly in VOIDS[f]]
 meta['floors'][str(f)]={'floor':f,'elevation':(f-2)*RISE,'rooms':[],'colliders':[],'voids':voids,'tools':[],'spawn':[WIDTH/2,1.8]}
 slab('Floor slab',voids,-.10,gray);slab('Ceiling',voids,3.18,white)
 for a,b in [([0,0],[WIDTH,0]),([WIDTH,0],[WIDTH,LENGTH]),([WIDTH,LENGTH],[0,LENGTH]),([0,LENGTH],[0,0])]:
  wall('Perimeter parapet',a,b,h=.95);wall('Perimeter glazing',a,b,h=3.1,mat=glass,block=False)
 for poly in voids:
  for a,b in zip(poly,poly[1:]+poly[:1]):
   wall('Atrium guard',a,b,h=1.1,mat=glass)
   bar('Atrium handrail',(a[0],1.1,a[1]),(b[0],1.1,b[1]),.025,metal)
 for entry in ROOMS[f]:build_room(f,entry)
 # Windows: repeated structural mullions give eye-level scale and legible daylight.
 for z in range(1,42,3):
  for x in [.02,WIDTH-.02]:box('Window mullion',x,2,z,.065,2.2,.055,white,kind='wall')
 # Retain paired circulation indications. Exact stair flights are still provisional.
 for x,z in [(WIDTH-2,2.2),(2,LENGTH-2.2)]:
  for i in range(14):box('Stair tread',x,.10+i*.07,z+i*.15,1.35,.12,.16,white)
  solid('Stair flight',x,z+1.0,1.35,2.2)
# Export all linked instances; remove library masters from the building file.
for group in LIB.values():
 for ob in list(group.children):bpy.data.objects.remove(ob,do_unlink=True)
 bpy.data.objects.remove(group,do_unlink=True)
parent=None
scene.world.color=(.55,.55,.55)
scene['source_dimension_note']='Footprint calibrated from prior 66sqm seminar annotation, not survey. Furnishings reference public nominal product dimensions; placements are review proposals.'
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'flc_walkthrough.blend'))
bpy.ops.export_scene.gltf(filepath=str(WEB/'assets/building.glb'),export_format='GLB',export_extras=True,export_yup=True)
(WEB/'assets/layout.json').write_text(json.dumps(meta,ensure_ascii=False,indent=2))
(ROOT/'sources/plan_trace.json').write_text(json.dumps({'bounds':BOUNDS,'rooms':ROOMS,'voids':VOIDS,'dimensions_m':[WIDTH,LENGTH,RISE],'provenance':'Recovered exact numeric traces shown in preceding chat. Original source images and preceding standalone viewer unavailable in this filesystem. Native game-space JSON was NOT converted into survey dimensions.'},ensure_ascii=False,indent=2))
meshes=[o for o in scene.objects if o.type=='MESH']
(ROOT/'build_validation.json').write_text(json.dumps({'meshes':len(meshes),'floors':[2,3,4],'rooms':{f:len(meta['floors'][str(f)]['rooms']) for f in [2,3,4]},'units':'m','footprint_m':[WIDTH,LENGTH],'studio_1_area_m2':meta['floors']['3']['rooms'][1]['area'],'shared_meshes':len({o.data.name for o in meshes}),'tool_dimensions_m':{'caliper_length':.233,'screwdriver_length':.204},'glb_sha256':hashlib.sha256((WEB/'assets/building.glb').read_bytes()).hexdigest()},indent=2))
print('BUILD_COMPLETE',len(meshes),'meshes')
