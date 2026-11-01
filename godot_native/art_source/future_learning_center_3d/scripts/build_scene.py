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
ROOMS={2:[('seminar',(256,97,553,254),'south','研讨室'),('formula',(109,325,326,534),'east','方程式工作室'),('team',(109,545,326,769),'east','团队工作室'),('robotics',(109,777,326,965),'east','ASABE 机器人室'),('mechatronics',(625,434,791,1055),'west','机电开放实验室'),('koala',(350,1070,790,1210),'north','考拉空间')],3:[('seminar',(219,49,321,128),'south','开放讨论区'),('studio_1',(98,164,179,219),'east','团队工作室 1'),('studio_2',(98,219,179,276),'east','团队工作室 2'),('studio_3',(98,276,179,333),'east','团队工作室 3'),('studio_4',(98,333,179,389),'east','团队工作室 4'),('recording',(98,397,179,489),'east','录播室'),('pantry',(219,541,321,620),'north','茶水与休息区'),('xlab',(344,222,437,620),'west','X-Lab')],4:[('storage',(195,61,261,175),'south','储物间'),('seminar_1',(74,239,210,424),'east','研讨室 1'),('seminar_2',(74,427,210,610),'east','研讨室 2'),('seminar_3',(74,615,210,770),'east','研讨室 3'),('focus',(492,336,633,606),'west','专注孵化区 A'),('collab',(492,614,633,835),'west','协作共创区 B'),('flex',(446,849,633,969),'north','流动工位区 C（可选）')]}
VOIDS={2:[],3:[[(222,168),(321,168),(321,504),(234,489)]],4:[[(270,61),(439,61),(439,174),(280,169)],[(270,248),(439,248),(439,793),(288,770)],[(270,859),(439,859),(439,968),(289,964)]]}
def point(f,x,z):
 a,b,c,d=BOUNDS[f];return [(x-a)/(c-a)*WIDTH,(z-b)/(d-b)*LENGTH]
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
scene=bpy.context.scene;scene.unit_settings.system='METRIC';scene.unit_settings.scale_length=1
scene['status']='Metric review, restored tracing evidence; not surveyed site geometry'
scene['unit']='meter'
parent=None; current_floor=0; root_floor=None
meta={'schema':1,'units':'m','width':WIDTH,'length':LENGTH,'rise':RISE,'eyeHeight':1.65,'radius':.24,'speed':1.5,'floors':{},'requirements_sources':['https://zju-xlab.feishu.cn/wiki/NKVGwp4KxikWgSktPoucZzsvnUf','https://zju-xlab.feishu.cn/wiki/GFwiw2ayEitbstk0ylzcWTIOnDF'],'missing_verified_geometry':['4F southwest formal conference room outline; source caption says spatial mapping is incorrect'],'scope':'2F/3F/4F restored source-pixel traces. 1F plan unavailable. Exact openings, heights and furniture inventory remain provisional.'}
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
def bank(cx,cz,columns=2):
 for dx in [1.42*(i-(columns-1)/2) for i in range(columns)]:
  workstation(cx+dx,cz-.31,0)
  workstation(cx+dx,cz+.31,math.pi)
 box('Shared gray divider',cx,1.0,cz,columns*1.4,.48,.035,meshmat)
def cupboard(x,z,width=1.2,north=False):
 box('Oak cabinet',x,.9,z,width,1.8,.40,wood,.012);solid('Cabinet',x,z,width,.40)
 for dx in [-width/4,width/4]:
  box('Cabinet front',x+dx,.9,z+(.21 if north else -.21),width/2-.015,1.72,.025,paper,.008)
  box('Cabinet pull',x+dx,.97,z+(.235 if north else -.235),.015,.15,.02,metal)
def table(x,z,w=2.4,d=1.0):
 box('Communal tabletop',x,.74,z,w,.06,d,wood,.02);solid('Table',x,z,w,d)
 for dx in [-w/2+.18,w/2-.18]:box('Table support',x+dx,.36,z,.08,.7,d-.15,black)
# Document-driven shared details. Dimensions of cabinetry/benches remain review choices.
def lab_bench(x,z,w=2.6,d=.8):
 box('ESD bench top',x,.855,z,w,.05,d,esd,.012);solid('Lab bench',x,z,w,d)
 for dx in [-w/2+.10,w/2-.10]:
  for dz in [-d/2+.08,d/2-.08]:box('Bench steel leg',x+dx,.42,z+dz,.055,.84,.055,metal)
 box('Bench lower shelf',x,.20,z,w-.15,.035,d-.12,paper)
 box('Bench socket rail',x,1.04,z+d/2-.045,w-.12,.10,.045,white)
 for i in range(max(2,int(w/.35))):
  px=x-w/2+.22+i*.35
  for dx in [-.018,.018]:box('Socket opening',px+dx,1.04,z+d/2-.071,.007,.026,.006,black)

def rack(x,z,w=1.4,d=.45):
 for dx in [-w/2,w/2]:
  for dz in [-d/2,d/2]:box('Rack upright',x+dx,1.0,z+dz,.035,2,.035,metal)
 for y in [.12,.55,1.0,1.45,1.9]:box('Rack shelf',x,y,z,w,.03,d,metal)
 for i in range(4):box('Parts bin',x-w/2+.18+i*(w-.35)/3,.69,z,.24,.22,.33,blue,.008)
 solid('Parts rack',x,z,w+.05,d+.05)

def printer(w,d,h):
 # Exterior dimensions from Bambu Lab H2C official specs; interior detail is illustrative.
 box('Printer base',0,.035,0,w,.07,d,black,.015)
 for x in [-w/2+.025,w/2-.025]:
  for z in [-d/2+.025,d/2-.025]:box('Printer corner',x,h/2,z,.045,h,.045,black,.008)
 box('Printer roof',0,h-.025,0,w,.05,d,black,.012)
 box('Printer left panel',-w/2+.01,h/2,0,.02,h-.10,d-.05,paper)
 box('Printer back',0,h/2,d/2-.01,w-.06,h-.10,.02,paper)
 box('Printer door glass',0,h/2,-d/2+.014,w-.065,h-.095,.012,smoke)
 box('Printer door pull',w*.34,h*.48,-d/2+.015,.015,.10,.025,metal,.004)
 box('Build plate',0,.19,0,min(.33,w-.08),.012,min(.32,d-.08),metal)
 for x in [-w*.36,w*.36]:bar('Z guide',(x,.10,d*.30),(x,h-.08,d*.30),.006,metal)
 bar('Gantry',(-w*.36,h*.72,0),(w*.36,h*.72,0),.008,metal)
 box('Print head',0,h*.67,0,.075,.075,.075,black,.008)
 cyl('Nozzle',0,h*.61,0,.004,.018,metal)
 box('Printer touchscreen',w*.18,h-.060,-d/2+.012,.12,.065,.014,blue,.004)

def laser_p2s():
 w,d,h=1.0,.639,.268
 box('P2S chassis',0,(h-.035)/2,0,w,h-.035,d,black,.024)
 box('P2S lid glass',-.07,h-.012,0,.69,.012,.46,smoke,.015)
 for z in [-.23,.23]:box('P2S lid rim',-.07,h-.009,z,.73,.018,.018,metal)
 box('P2S lid handle',-.07,h-.012,-.245,.27,.022,.024,paper,.006)
 box('P2S control',.39,h-.013,-.17,.11,.025,.10,blue,.004)
 for i in range(12):box('Rear vent',-.39+i*.07,.18,d/2-.008,.025,.06,.007,metal)

esd=material('ESD gray green',(.28,.39,.36));smoke=material('Smoked equipment glass',(.13,.20,.19),.15,.25,.48)
prototype('printer_h2c',lambda:printer(.492,.514,.626));prototype('laser_p2s',laser_p2s)

def place_equipment(asset,x,z,y=.88):
 ob=instance(asset,x,z);ob.location.z=y;ob['inspectable']=True
 meta['floors'][str(current_floor)]['tools'].append({'assetId':asset,'position':[x,y,z]})

def electronics_lab(room):
 x0,z0,x1,z1=room['bounds'];w=x1-x0;d=z1-z0;cx=(x0+x1)/2
 split=z0+d*(78.11/(78.11+61.98))
 room['source']='https://zju-xlab.feishu.cn/wiki/GFwiw2ayEitbstk0ylzcWTIOnDF'
 room['layout_variant']='electrical_and_machining';room['source_zone_areas_m2']={'electrical':78.11,'machining':61.98}
 room['partition_z']=split;room['detail_status']='source-led layout; representative H2C/P2S geometry, remaining equipment inventory not yet fully modeled'
 box('Electrical ESD floor',cx,-.009,(z0+split)/2,w-.15,.018,split-z0-.10,esd,kind='finish')
 # Door sits at the west side of the acoustic partition, following the source drawing.
 doorx=x0+.90
 for a,b in [([x0,split],[doorx-.60,split]),([doorx+.60,split],[x1,split])]:
  wall('Double glazing acoustic partition',a,b,mat=glass)
  wall('Second acoustic glass pane',[a[0],a[1]+.07],[b[0],b[1]+.07],mat=glass,block=False)
  bar('Acoustic frame',(a[0],2.85,a[1]),(b[0],2.85,b[1]),.025,metal)
 for x in [doorx-.60,doorx+.60]:box('Acoustic door jamb',x,1.15,split,.06,2.3,.12,metal,kind='wall')
 # The wall benches and central teaching/electrical work surfaces come from the supplied plan.
 lab_bench(cx,z0+1.05,2.8,.75)
 for dx in [-.9,0,.9]:instance('office_chair',cx+dx,z0+1.85);solid('Office chair',cx+dx,z0+1.85,.71,.71)
 lab_bench(x0+.55,z0+4.2,.75,3.2)
 lab_bench(cx+.45,z0+4.2,2.7,1.15)
 for dx in [-.75,.75]:instance('office_chair',cx+.45+dx,z0+5.15);solid('Electrical chair',cx+.45+dx,z0+5.15,.71,.71)
 lab_bench(cx+.35,split-2.4,2.7,1.1)
 for side in [-1,1]:
  for dx in [-.75,.75]:instance('office_chair',cx+.35+dx,split-2.4+side*.95,0 if side==1 else math.pi);solid('Training chair',cx+.35+dx,split-2.4+side*.95,.71,.71)
 rack(x0+.55,split-2.3,.65,1.4);rack(x1-1.0,split-4.0,1.5,.45)
 # Actual manufacturer dimension envelopes, with separate printer internals and laser lid.
 place_equipment('printer_h2c',cx-.55,z0+1.05);place_equipment('printer_h2c',cx+.60,z0+1.05)
 lab_bench(x1-.55,z0+7.2,.8,2.7)
 place_equipment('laser_p2s',cx+.25,split-2.4)
 # Electrical test accessories: separate meter, iron stand, holder and small parts tray.
 box('Bench power supply',cx+.3,1.02,z0+4.2,.30,.28,.25,paper,.012)
 box('Power supply display',cx+.3,1.04,z0+4.06,.20,.08,.012,blue)
 box('Soldering base',cx-.5,.92,z0+4.2,.16,.08,.14,black,.008)
 bar('Soldering iron',(cx-.48,1.02,z0+4.16),(cx-.43,1.15,z0+4.20),.008,metal)
 for dx in [-.35,.25]:
  tool='caliper_150' if dx<0 else 'screwdriver_3x100';place_equipment(tool,cx+dx,split-2.65)
 # Machine room: separate working benches, open parts racks and peripheral service route.
 lab_bench(cx+.2,split+1.1,2.8,.8)
 for dx in [-.8,.8]:instance('office_chair',cx+.2+dx,split+1.9);solid('Machine bench chair',cx+.2+dx,split+1.9,.71,.71)
 lab_bench(x1-.5,split+3.5,.75,2.6)
 rack(cx+.45,split+4.4,2.8,.5)
 lab_bench(cx+.2,z1-2.2,2.8,1.1)
 for side in [-1,1]:
  for dx in [-.8,.8]:instance('office_chair',cx+.2+dx,z1-2.2+side*.95,0 if side==1 else math.pi);solid('Machine table chair',cx+.2+dx,z1-2.2+side*.95,.71,.71)
 cupboard(x0+.45,split+4.3,.65)
 # Visible service routing expresses the requirements, not an engineering-certified installation.
 for start,end in [(z0+.5,split-.5),(split+.5,z1-.5)]:
  bar('Extract duct',(x1-.30,2.7,start),(x1-.30,2.7,end),.075,metal)
  box('Extract grille',x1-.18,2.68,start,.16,.24,.32,metal)
 box('Electrical branch board',x0+.12,1.7,z0+2.4,.15,.65,.45,paper)
 box('Machine branch board',x0+.12,1.7,split+2.8,.15,.65,.45,paper)


def meeting_chair(x,z,angle=0):
 instance('office_chair',x,z,angle);solid('Meeting chair',x,z,.71,.71)
def sofa(x,z,width=1.8):
 box('Sofa lower',x,.28,z,width,.42,.80,meshmat,.06);box('Sofa back',x,.67,z+.34,width,.55,.15,meshmat,.04)
 for dx in [-width/2+.08,width/2-.08]:box('Sofa arm',x+dx,.53,z,.16,.35,.80,meshmat,.04)
 for i in range(3):box('Sofa cushion',x-width/3+i*width/3,.52,z-.025,width/3-.025,.12,.65,meshmat,.04)
 solid('Sofa',x,z,width,.85)
def electronic_board(cx,z,width=2.0):
 box('Electronic board frame',cx,1.55,z,width,1.12,.075,black,.012)
 box('Electronic writing panel',cx,1.55,z-.045,width-.09,1.02,.015,paper)
 box('Pen ledge',cx,1.0,z-.06,width-.12,.035,.06,metal)

def seminar_variant(room):
 x0,z0,x1,z1=room['bounds'];cx=(x0+x1)/2;cz=(z0+z1)/2;name=room['id']
 if name=='seminar_1':
  room['layout_variant']='modular_co_creation';radius=1.35
  for i in range(6):
   a=i*math.tau/6;poly=[[cx,cz],[cx+math.cos(a)*radius,cz+math.sin(a)*radius],[cx+math.cos(a+math.tau/6)*radius,cz+math.sin(a+math.tau/6)*radius]]
   prism('Movable polygon table module',poly,.72,.05,wood)
   cyl('Module support',cx+math.cos(a+math.pi/6)*.75,.36,cz+math.sin(a+math.pi/6)*.75,.035,.72,metal)
  solid('Modular table',cx,cz,2.7,2.7)
  for i in range(8):
   a=i*math.tau/8;meeting_chair(cx+math.cos(a)*2.0,cz+math.sin(a)*2.0,math.pi/2-a)
  for x in [x0+.08,x1-.08]:box('Writable wall',x,1.55,cz,.035,1.25,min(3.2,z1-z0-1),paper)
 elif name=='seminar_2':
  room['layout_variant']='conference';table(cx,cz,2.8,1.2)
  for dx in [-.9,0,.9]:
   for side in [-1,1]:meeting_chair(cx+dx,cz+side*1.05,0 if side==1 else math.pi)
  for side in [-1,1]:meeting_chair(cx+side*1.90,cz,math.pi/2 if side>0 else -math.pi/2)
  electronic_board(cx,z0+.12)
 else:
  room['layout_variant']='interview';sofa(cx,cz+.9,1.8);table(cx,cz-.2,1.0,.60)
  for dx in [-.9,.9]:meeting_chair(cx+dx,cz-1.1,math.pi+(-.2 if dx<0 else .2))
  electronic_board(cx,z0+.12,1.8)


def open_work_zone(room):
 x0,z0,x1,z1=room['bounds'];cx=(x0+x1)/2;cz=(z0+z1)/2;name=room['id']
 room['layout_variant']='open_'+name
 if name=='focus':
  room['seats']=18
  for i in range(3):bank(cx,z0+2.0+i*4.2,columns=3)
 elif name=='collab':
  room['seats']=12
  for i in range(2):
   z=z0+2.2+i*4.8;table(cx,z,2.8,1.2)
   for dx in [-.9,0,.9]:
    for side in [-1,1]:meeting_chair(cx+dx,z+side*1.0,0 if side==1 else math.pi)
   electronic_board(x1-1.2,z-1.15,1.7)
 else:
  room['seats']=10;room['optional']=True
  table(x0+2.4,cz,3.0,.8)
  for dx in [-.95,0,.95]:
   for side in [-1,1]:meeting_chair(x0+2.4+dx,cz+side*.85,0 if side==1 else math.pi)
  box('Window standing counter',x1-.4,1.05,cz,.55,.06,4.2,wood,.015);solid('Window counter',x1-.4,cz,.55,4.2)
  for i in range(4):
   z=z0+.8+i*1.05;cyl('Bar stool seat',x1-1.05,.74,z,.20,.07,black);cyl('Bar stool stem',x1-1.05,.38,z,.025,.70,metal);cyl('Bar stool foot',x1-1.05,.04,z,.19,.045,metal);solid('Bar stool',x1-1.05,z,.42,.42)

def locker_bank():
 # Eight banks of 2x5 doors: requested personal-storage capacity, provisional wall placement.
 for unit in range(8):
  x=18.3+unit*.85;z=.40
  box('Personal locker cabinet',x,1.0,z,.80,2.0,.45,paper,.012);solid('Personal lockers',x,z,.80,.45)
  for col in range(2):
   for row in range(5):
    xx=x+(col-.5)*.39;y=.21+row*.39
    box('Personal locker door',xx,y,z+.24,.365,.365,.025,wood,.006)
    box('Card or QR reader',xx+.11,y,z+.26,.055,.07,.012,black,.004)
    box('Locker pull',xx+.07,y,z+.28,.014,.08,.018,metal)
 meta['floors']['4']['personal_lockers']=80

def discussion_area(room):
 x0,z0,x1,z1=room['bounds'];cx=(x0+x1)/2
 room['layout_variant']='open_discussion';room['enclosure']='open'
 for x in [x0+1.65,x1-1.65]:
  table(x,z0+2.0,1.8,1.0)
  for dx in [-.55,.55]:
   for side in [-1,1]:meeting_chair(x+dx,z0+2.0+side*.90,0 if side==1 else math.pi)
 box('Standing discussion tabletop',cx,1.06,z1-1.7,1.4,.06,.65,wood,.015);solid('Standing table',cx,z1-1.7,1.4,.65)
 for dx in [-.5,.5]:box('Standing table leg',cx+dx,.52,z1-1.7,.05,1.04,.50,metal)
 for x in [x0+.65,x1-.65]:
  box('Public copier cabinet',x,.48,z0+.60,.65,.96,.70,paper,.018);box('Copier scanner',x,1.01,z0+.60,.65,.10,.70,black,.015)
  box('Copier paper output',x,.70,z0+.23,.46,.08,.04,black);solid('Public copier',x,z0+.60,.65,.70)
 electronic_board(cx,z0+.18,1.5)
 for dx in [-.6,.6]:
  bar('Mobile board leg',(cx+dx,.08,z0+.18),(cx+dx,1.0,z0+.18),.02,metal)
  bar('Mobile board foot',(cx+dx,.08,z0-.07),(cx+dx,.08,z0+.43),.02,metal)


def recording_studio(room):
 x0,z0,x1,z1=room['bounds'];cx=(x0+x1)/2;cz=(z0+z1)/2
 room['layout_variant']='recording_and_photography';room['detail_status']='requirements-based generic equipment; final interior design not supplied'
 box('Dark studio floor',cx,-.008,cz,x1-x0-.15,.018,z1-z0-.15,black,kind='finish')
 for x in [x0+.08,x1-.08]:box('Black acoustic curtain',x,1.4,cz,.035,2.8,z1-z0-.3,black)
 for i,mat in enumerate([paper,gray,leaf]):
  z=z0+.30+i*.15;bar('Three axis backdrop roll',(x0+.5,2.65,z),(x1-.5,2.65,z),.055,mat)
 box('Green screen drop',cx,1.45,z0+.63,x1-x0-1.0,2.35,.025,leaf)
 for x,z in [(x0+1.0,cz-.3),(x1-1.0,cz-.3),(cx,cz+1.1)]:
  for i in range(3):
   a=i*math.tau/3;bar('Tripod leg',(x,.55,z),(x+math.cos(a)*.35,.05,z+math.sin(a)*.35),.015,metal)
  bar('Tripod column',(x,.30,z),(x,1.65,z),.018,metal);solid('Studio tripod',x,z,.60,.60)
  if abs(x-cx)<.1:
   box('Video camera',x,1.75,z,.24,.18,.25,black,.012);cyl('Camera lens',x,1.76,z-.18,.05,.12,metal)
   box('Teleprompter hood',x,1.86,z-.26,.40,.28,.10,black,.012)
  else:
   box('Softbox housing',x,1.95,z,.65,.55,.24,black,.03);box('Softbox diffuser',x,1.95,z-.135,.57,.47,.015,paper)
 lab_bench(cx,z1-.6,2.8,.70)
 for dx in [-.7,.7]:
  box('Editing monitor',cx+dx,1.23,z1-.6,.60,.37,.05,black,.008);bar('Editing monitor stand',(cx+dx,.9,z1-.6),(cx+dx,1.23,z1-.6),.02,metal)
 box('Mixer panel',cx,.94,z1-.7,.38,.10,.24,metal,.008)
 for i in range(6):box('Mixer fader',cx-.14+i*.055,1.0,z1-.7,.016,.012,.11,black)
 box('Audio microphone',x0+.65,1.35,cz+.8,.06,.2,.06,black);bar('Microphone stand',(x0+.65,.05,cz+.8),(x0+.65,1.28,cz+.8),.015,metal)
 cupboard(x1-.55,z1-1.7,.8)


def pantry_areas(room):
 x0,z0,x1,z1=room['bounds'];cx=(x0+x1)/2;cz=(z0+z1)/2
 room['layout_variant']='pantry_standing_conversation_rest';room['detail_status']='four use areas; combined conversation/rest option chosen for current footprint'
 # Wall bar and independently editable service appliances.
 box('Pantry base cabinets',cx,.43,z1-.42,4.8,.86,.70,paper,.012);solid('Pantry cabinets',cx,z1-.42,4.8,.70)
 box('Pantry countertop',cx,.89,z1-.42,4.9,.06,.74,wood,.012)
 box('Sink rim',cx+.7,.928,z1-.42,.55,.018,.42,metal,.01);box('Sink recess',cx+.7,.94,z1-.42,.43,.015,.30,black,.02)
 bar('Sink tap',(cx+.7,.93,z1-.15),(cx+.7,1.17,z1-.15),.015,metal);bar('Tap spout',(cx+.7,1.17,z1-.15),(cx+.7,1.17,z1-.35),.015,metal)
 for y in [1.45,1.90]:box('Pantry wall shelf',cx,y,z1-.16,4.6,.04,.28,wood,.008)
 box('Coffee machine',cx-.8,1.08,z1-.42,.30,.33,.34,black,.012);box('Coffee cup niche',cx-.8,1.03,z1-.61,.18,.17,.015,metal)
 box('Microwave',cx-1.65,1.08,z1-.42,.50,.30,.36,paper,.01);box('Microwave door',cx-1.68,1.08,z1-.61,.36,.22,.014,black)
 box('Vending machine',x0+.65,.95,z1-1.75,.85,1.9,.75,black,.02);solid('Vending machine',x0+.65,z1-1.75,.85,.75)
 box('Vending products glass',x0+.65,1.13,z1-2.14,.65,1.2,.02,smoke)
 for i in range(3):box('Vending product shelf',x0+.65,.65+i*.3,z1-1.85,.63,.02,.40,paper)
 # Six-person standing zone leaves a central route from the north entry.
 tx=x0+1.85;tz=z0+2.1;box('Six-person standing table',tx,1.05,tz,2.35,.06,.72,wood,.012);solid('Standing table',tx,tz,2.35,.72)
 for dx in [-.9,.9]:box('High table support',tx+dx,.52,tz,.06,1.04,.58,metal)
 for dx in [-.75,0,.75]:
  for side in [-1,1]:
   x=tx+dx;z=tz+side*.78;cyl('High stool seat',x,.74,z,.20,.07,black);cyl('High stool leg',x,.38,z,.025,.70,metal);solid('High stool',x,z,.42,.42)
 # Two small conversation groups and one shared rest sofa.
 for z in [z0+1.5,z0+3.5]:
  table(x1-1.55,z,.70,.55)
  for dx in [-.70,.70]:meeting_chair(x1-1.55+dx,z,math.pi/2 if dx>0 else -math.pi/2)
 sofa(cx+.45,z1-1.9,1.8)
 for x,z in [(x0+.30,z0+.60),(cx+.4,z1-.43)]:
  cyl('Pantry plant pot',x,.40 if x<x0+.5 else 1.02,z,.16,.28,wood);cyl('Pantry plant leaves',x,.8 if x<x0+.5 else 1.35,z,.26,.40,leaf)
 # User's established far-right fridge placement stays visible and separate.
 box('Pantry refrigerator',x1-.50,1.0,z1-.50,.75,2.0,.70,paper,.018);solid('Refrigerator',x1-.50,z1-.50,.75,.70)
 for y in [.80,1.65]:box('Fridge handle',x1-.76,y,z1-.87,.025,.25,.035,metal)


def storage_room(room):
 x0,z0,x1,z1=room['bounds'];cx=(x0+x1)/2
 room['layout_variant']='dry_storage_and_consumable_drawers'
 cupboard(cx,z0+.3,max(.8,x1-x0-.5),north=True)
 box('Dry cabinet',x0+.48,1.05,z0+1.9,.72,2.1,.60,black,.012);solid('Dry cabinet',x0+.48,z0+1.9,.72,.60)
 box('Dry cabinet glass',x0+.48,1.1,z0+2.22,.60,1.65,.025,smoke);box('Humidity display',x0+.60,1.9,z0+2.24,.14,.07,.02,blue)
 rack(x1-.45,z0+2.8,.60,2.0)
 for row in range(6):
  y=.2+row*.25;box('Consumable pullout drawer',x1-.45,y,z0+2.8,.56,.22,1.8,paper,.004)
  box('Drawer label',x1-.77,y,z0+2.8,.012,.07,.20,black)


def furnish(room):
 x0,z0,x1,z1=room['bounds'];cx=(x0+x1)/2;cz=(z0+z1)/2;name=room['id'];w=x1-x0;d=z1-z0
 if current_floor==2 and name=='mechatronics':electronics_lab(room);return
 if current_floor==3 and name=='seminar':discussion_area(room);return
 if current_floor==3 and name=='recording':recording_studio(room);return
 if name=='pantry':pantry_areas(room);return
 if current_floor==4 and name=='storage':storage_room(room);return
 if current_floor==4 and name.startswith('seminar_'):seminar_variant(room);return
 if current_floor==4 and name in ['focus','collab','flex']:open_work_zone(room);return
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
 if f==3 and name=='seminar':
  room['enclosure']='open';room['door']=[(x0+x1)/2,z1];room['spawn']=[(x0+x1)/2,z1-.65];room['heading']=0
  furnish(room);meta['floors'][str(f)]['rooms'].append(room);return
 if f==4 and name in ['focus','collab','flex']:
  room['enclosure']='open';room['door']=[x0,(z0+z1)/2];room['spawn']=[x0+.65,(z0+z1)/2];room['heading']=-math.pi/2
  furnish(room);meta['floors'][str(f)]['rooms'].append(room);return
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
 if f==4:locker_bank()
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
