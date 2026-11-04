"""Photo 2 lounge family. Independent Blender 4.3.2, metres, CPU review only.
Reference pixels are viewed but never used as textures. All dimensions are estimates.
Run blender -b --factory-startup -t 4 --python scripts/build_photo_lounge.py -- --skip-render
Then --render-only, optionally --asset=photo_lounge_orange_single, --composition-only.
"""
import bpy, math, json, hashlib, sys, collections
import numpy as np
from pathlib import Path
from mathutils import Vector, Matrix
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'sources/models/photo_lounge';REVIEW=ROOT/'review/photo_lounge'
OUT.mkdir(parents=True,exist_ok=True);REVIEW.mkdir(parents=True,exist_ok=True)
LOD=0;CURRENT_FOLDER=OUT;records=[]

def material(name,color,metal=0.,rough=.5):
 m=bpy.data.materials.new(name);m.use_nodes=True;m.diffuse_color=(*color,1)
 p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=rough
 return m

def synthetic(name,base,kind):
 m=material(name,base,0,.86 if kind=='weave' else .54);n=128
 u,v=np.meshgrid(np.arange(n)/n,np.arange(n)/n)
 rng=np.random.default_rng(2711)
 if kind=='weave':
  warp=np.cos(u*math.tau*16);weft=np.cos(v*math.tau*16)
  height=.60*warp+.40*weft+.15*np.sin((u+v)*math.tau*8)
  variation=1+.055*height+.015*rng.normal(size=(n,n))
 else:
  height=.3*np.sin(u*math.tau*12+.45*np.sin(v*math.tau))+.16*np.sin(u*math.tau*41+.2*np.sin(v*math.tau*2))
  variation=1+.10*height
 pixels=np.ones((n,n,4),np.float32)
 for k in range(3):pixels[:,:,k]=base[k]*variation
 im=bpy.data.images.new(name+' synthetic tile',width=n,height=n,alpha=True);im.pixels.foreach_set(pixels.ravel());im.filepath_raw=str(CURRENT_FOLDER/(name.lower().replace(' ','_')+'_base.png'));im.file_format='PNG';im.save();im.pack()
 tex=m.node_tree.nodes.new('ShaderNodeTexImage');tex.image=im;m.node_tree.links.new(tex.outputs['Color'],m.node_tree.nodes.get('Principled BSDF').inputs['Base Color'])
 if kind=='weave':
  dv,du=np.gradient(height);norm=np.stack((-du*.34,-dv*.34,np.ones_like(height)),axis=-1);norm/=np.linalg.norm(norm,axis=-1,keepdims=True);pixels[:,:,:3]=norm*.5+.5
  im=bpy.data.images.new(name+' synthetic normal tile',width=n,height=n,alpha=True);im.colorspace_settings.name='Non-Color';im.pixels.foreach_set(pixels.ravel());im.filepath_raw=str(CURRENT_FOLDER/(name.lower().replace(' ','_')+'_normal.png'));im.file_format='PNG';im.save();im.pack()
  tex=m.node_tree.nodes.new('ShaderNodeTexImage');tex.image=im;nm=m.node_tree.nodes.new('ShaderNodeNormalMap');nm.inputs['Strength'].default_value=.35;m.node_tree.links.new(tex.outputs['Color'],nm.inputs['Color']);m.node_tree.links.new(nm.outputs['Normal'],m.node_tree.nodes.get('Principled BSDF').inputs['Normal'])
 m['textureProvenance']='Deterministic locally synthesized 128 px periodic tile. No photograph pixels.'
 return m

def palette(asset):
 global orange,seam,black,shell,rubber,ivory,grey,blue,green,wood
 orange=synthetic('Terracotta woven upholstery',(.54,.125,.060),'weave') if 'orange' in asset else None
 seam=material('Terracotta welt',(.39,.072,.034),0,.86)
 black=material('Black powder coated steel',(.008,.011,.012),.12,.51)
 shell=material('Thin charcoal molded outer shell',(.005,.008,.010),0,.46)
 rubber=material('Black foot glides',(.012,.014,.015),0,.78)
 ivory=material('Warm white round tabletop',(.84,.84,.79),0,.36)
 grey=material('Grey molded bar chair shell',(.045,.048,.050),0,.55)
 blue=material('Blue grey painted high stool',(.022,.047,.068),0,.48)
 green=material('Muted teal stool variant',(.014,.110,.085),0,.48)
 wood=synthetic('Pale wood bar counter',(.63,.52,.37),'grain') if 'counter' in asset else None

def finish(o,name,mat,smooth=True):
 o.name=name
 if mat:o.data.materials.append(mat)
 o['part']=name
 for p in o.data.polygons:p.use_smooth=smooth
 return o

def mesh(name,vs,fs,mat,uv=None,smooth=True):
 me=bpy.data.meshes.new(name);me.from_pydata(vs,[],fs);me.update();o=bpy.data.objects.new(name,me);bpy.context.collection.objects.link(o);finish(o,name,mat,smooth)
 if uv is not None:
  layer=me.uv_layers.new(name='UVMap')
  for p in me.polygons:
   for li in p.loop_indices:layer.data[li].uv=uv[me.loops[li].vertex_index]
 return o

def active(o):
 bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o

def bevel(o,r):
 active(o);m=o.modifiers.new('Rounded manufactured edges','BEVEL');m.width=r;m.segments=[4,2,1][LOD];bpy.ops.object.modifier_apply(modifier=m.name)
 n=o.modifiers.new('Weighted face normals','WEIGHTED_NORMAL');n.keep_sharp=True;bpy.ops.object.modifier_apply(modifier=n.name)

def uv_project(o,scale=1):
 layer=o.data.uv_layers.new(name='UVMap')
 for p in o.data.polygons:
  axes=(0,1) if abs(p.normal.z)>.5 else (0,2) if abs(p.normal.y)>.5 else (1,2)
  for li in p.loop_indices:
   co=o.data.vertices[o.data.loops[li].vertex_index].co;layer.data[li].uv=(co[axes[0]]*scale,co[axes[1]]*scale)

def box(name,loc,size,mat,r=0):
 bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.dimensions=size;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);finish(o,name,mat)
 if r:bevel(o,min(r,min(size)*.45))
 uv_project(o);return o

def cylinder(name,loc,r,depth,mat,axis='Z'):
 bpy.ops.mesh.primitive_cylinder_add(vertices=[48,24,12][LOD],radius=r,depth=depth,location=loc);o=bpy.context.object
 if axis=='Y':o.rotation_euler.x=math.pi/2
 if axis=='X':o.rotation_euler.y=math.pi/2
 return finish(o,name,mat)

def tube(name,pts,r,mat,radial=None):
 # Parallel transport: no Frenet-frame axis flips on almost straight bends.
 pts=[Vector(p) for p in pts];n=radial or [12,8,6][LOD];vs=[];uv=[];prev=None;length=0
 for j,p in enumerate(pts):
  tangent=(pts[min(j+1,len(pts)-1)]-pts[max(j-1,0)]).normalized()
  if prev is None:ref=Vector((0,0,1)) if abs(tangent.z)<.95 else Vector((0,1,0));e=tangent.cross(ref).normalized()
  else:
   e=prev-tangent*prev.dot(tangent)
   if e.length<1e-7:e=tangent.cross(Vector((1,0,0)) if abs(tangent.x)<.9 else Vector((0,1,0)))
   e.normalize()
  f=tangent.cross(e).normalized();prev=e.copy()
  if j:length+=(p-pts[j-1]).length
  for i in range(n):
   a=math.tau*i/n;vs.append(p+r*(math.cos(a)*e+math.sin(a)*f));uv.append((i/n,length*10))
 fs=[tuple(reversed(range(n))),tuple(range((len(pts)-1)*n,len(pts)*n))]
 for j in range(len(pts)-1):
  for i in range(n):a=j*n+i;b=j*n+(i+1)%n;fs.append((a,b,b+n,a+n))
 return mesh(name,vs,fs,mat,uv)

def shell_solid(name,vs,fs,uv,mat,thickness):
 o=mesh(name,vs,fs,mat,uv);active(o);m=o.modifiers.new('Actual thin shell wall','SOLIDIFY');m.thickness=thickness;m.offset=0;bpy.ops.object.modifier_apply(modifier=m.name);return o

def rounded_cushion(name,w,d,z,thick,mat,y=0,power=.65):
 n=[80,48,24][LOD];profiles=[(.90,-.46),(1,-.25),(1,.10),(.965,.34),(.86,.49),(.63,.55),(.25,.56)]
 vs=[];uv=[]
 for sc,h in profiles:
  for i in range(n):
   a=math.tau*i/n;c,s=math.cos(a),math.sin(a)
   # Front wider, rear tucked into the curved backrest.
   x=w/2*math.copysign(abs(c)**power,c)*sc*(1-.09*max(0,s));yy=d/2*math.copysign(abs(s)**power,s)*sc
   vs.append((x,y+yy,z+h*thick-.018*max(0,s)));uv.append((x*10,yy*10))
 fs=[tuple(reversed(range(n)))]
 for j in range(len(profiles)-1):
  for i in range(n):a=j*n+i;b=j*n+(i+1)%n;fs.append((a,b,b+n,a+n))
 fs.append(tuple(range((len(profiles)-1)*n,len(profiles)*n)))
 return mesh(name,vs,fs,mat,uv)

def bowl_point(a,q,w,d):
 f=(math.sin(a)+1)*.5;top=.382+.472*f**.63
 # Bulged lower shell, near-vertical upper back, forward-dropped arm tips.
 radial=math.sin(q*math.pi*.5)
 return Vector((w*.5*math.cos(a)*radial,d*.5*math.sin(a)*radial+.025,.318+(top-.318)*q**4.5))

def bowl_qmax(a):
 t=max(0,min(1,(math.sin(a)+.75)/(.75-.438)));t=t*t*(3-2*t)
 return .45+.55*t

def lounge(w=.88,double=False):
 d=.80;n=[96,56,28][LOD];nr=[18,11,6][LOD];vs=[(0,.025,.318)];uv=[(.5,.5)];fs=[]
 for j in range(1,nr+1):
  q=j/nr
  for i in range(n):
   a=math.tau*i/n;p=bowl_point(a,q*bowl_qmax(a),w,d);vs.append(p);uv.append((i/n*8,q*4))
 for i in range(n):fs.append((0,1+(i+1)%n,1+i))
 for j in range(nr-1):
  for i in range(n):a=1+j*n+i;b=1+j*n+(i+1)%n;fs.append((a,b,b+n,a+n))
 shell_solid('Continuous thin charcoal outer bowl',vs,fs,uv,shell,.014)
 # Upholstered inner U follows the same bowl. No box backrest or separate conventional arms.
 na=[80,44,24][LOD];nq=[15,9,5][LOD];vs=[];uv=[];fs=[]
 for j in range(nq+1):
  t=j/nq
  for i in range(na+1):
   a=math.radians(-50+280*i/na);q=.34+(bowl_qmax(a)-.34)*t;p=bowl_point(a,q,w,d)
   inset=.021+.034*math.sin(t*math.pi)
   p.x-=inset*math.cos(a);p.y-=inset*math.sin(a);p.z+=.007+.007*math.sin(t*math.pi)
   vs.append(p);uv.append((i/na*(w+d)*6,t*4.8))
 for j in range(nq):
  for i in range(na):a=j*(na+1)+i;fs.append((a,a+1,a+na+2,a+na+1))
 shell_solid('Orange padded continuous back and arms',vs,fs,uv,orange,.033)
 seat=rounded_cushion('Separate rounded upholstered seat',w*.87,.700,.423,.097,orange,y=-.040,power=.69)
 # The rear/side cushion must sit above the shell floor, not protrude beneath it.
 for vert in seat.data.vertices:
  x,y,z=vert.co;theta=math.atan2((y-.025)/(d*.5),x/(w*.5))
  if math.sin(theta)<-.2:continue
  rr=math.sqrt((x/(w*.5))**2+((y-.025)/(d*.5))**2);qq=math.asin(min(rr,1))/(math.pi*.5)
  assert z-bowl_point(theta,qq,w,d).z>.005,'Cushion outside rear shell'
 if LOD<2:
  pts=[]
  for i in range(na+1):
   a=math.radians(-50+280*i/na);p=bowl_point(a,bowl_qmax(a),w,d);p.x-=.025*math.cos(a);p.y-=.025*math.sin(a);p.z+=.009;pts.append(p)
  tube('Fine upper upholstery welt',pts,.0020,seam,6)
  if double:
   # Visible divided upholstery treatment. No guessed brand or printed markings.
   pts=[]
   for j in range(20):
    t=j/19;q=.36+.625*t;p=bowl_point(math.pi/2,q,w,d);p.y-=.039+.034*math.sin(t*math.pi);p.z+=.012;pts.append(p)
   tube('Central shallow back upholstery seam',pts,.0009,seam,6)
 # Low four-star blade foot, visible in the reference; hidden swivel bracket simplified.
 cylinder('Central concealed seat support',(0,.025,.260),.037,.135,black)
 for sx in [-1,1]:
  for sy in [-1,1]:
   end=Vector((sx*(.57 if double else .345),sy*.305+.025,.019));start=Vector((0,.025,.175));direction=Vector((end.x,end.y-.025,0)).normalized();side=Vector((-direction.y,direction.x,0))
   verts=[]
   for p,width,height in [(start,.050,.055),(end,.020,.019)]:
    for dz in [-height/2,height/2]:
     for sign in [-1,1]:verts.append(p+side*width*.5*sign+Vector((0,0,dz)))
   faces=[(0,2,3,1),(4,5,7,6),(0,1,5,4),(2,6,7,3),(0,4,6,2),(1,3,7,5)]
   o=mesh('Tapered four star blade %d %d'%(sx,sy),verts,faces,black,smooth=False)
   if LOD<2:bevel(o,.002)
   cylinder('Small floor glide %d %d'%(sx,sy),(end.x,end.y,.004),.015,.008,rubber)

def single():lounge(.88,False)
def double():lounge(1.44,True)

def round_table():
 o=cylinder('Thin warm white round top',(0,0,.513),.285,.022,ivory)
 if LOD<2:bevel(o,.003)
 cylinder('Black underside mounting plate',(0,0,.493),.095,.014,black)
 cylinder('Slender central black post',(0,0,.266),.022,.470,black)
 # One watertight plus outline, avoiding coplanar overlap of two boxes.
 h=.2325;b=.017;xy=[(-h,-b),(-b,-b),(-b,-h),(b,-h),(b,-b),(h,-b),(h,b),(b,b),(b,h),(-b,h),(-b,b),(-h,b)]
 n=len(xy);vs=[(x,y,z) for z in [.011,.033] for x,y in xy];fs=[tuple(reversed(range(n))),tuple(range(n,2*n))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
 foot=mesh('Single continuous rectangular cross foot',vs,fs,black,smooth=False)
 if LOD<2:bevel(foot,.002)
 for x,y in [(-.211,0),(.211,0),(0,-.211),(0,.211)]:box('Recessed foot glide',(x,y,.005),(.026,.026,.010),rubber,.002)

def rounded_back_panel():
 # Wide low rounded-square back, curved around sitter and leaning 9 degrees.
 n=[80,48,24][LOD];rings=[(.86,-.017),(1,-.006),(1,.010),(.92,.023),(.68,.029),(.28,.031)];vs=[];uv=[]
 for sc,offset in rings:
  for i in range(n):
   a=math.tau*i/n;c,s=math.cos(a),math.sin(a);x=.228*math.copysign(abs(c)**.61,c)*sc;zz=.133*math.copysign(abs(s)**.66,s)*sc
   vs.append((x,.172+.038*(1-(x/.228)**2)+zz*.16+offset,.895+zz));uv.append((x*3,zz*3))
 fs=[tuple(reversed(range(n)))]
 for j in range(len(rings)-1):
  for i in range(n):a=j*n+i;b=j*n+(i+1)%n;fs.append((a,b,b+n,a+n))
 fs.append(tuple(range((len(rings)-1)*n,len(rings)*n)))
 return mesh('Low rounded grey molded back',vs,fs,grey,uv)

def grey_bar_chair():
 # No arms, no pedestal. Four lean tubular legs and complete low rectangular footrest.
 rounded_cushion('Thin grey molded bar seat',.435,.425,.739,.034,grey,y=-.008,power=.62)
 rounded_back_panel()
 for sx in [-1,1]:
  for sy in [-1,1]:
   bottom=(sx*.229,sy*.232,.011);top=(sx*.175,sy*.153,.729)
   tube('Slender black splayed leg %d %d'%(sx,sy),[bottom,top],.010,black)
   cylinder('Bar chair foot cap',(bottom[0],bottom[1],.004),.012,.008,rubber)
  tube('Short backrest support '+str(sx),[(sx*.175,.153,.690),(sx*.176,.168,.788),(sx*.177,.184,.906)],.0095,black)
 z=.310;xx=.208;yy=.200
 tube('Front footrest',[(-xx,-yy,z),(xx,-yy,z)],.009,black)
 tube('Rear lower brace',[(-xx,yy,z),(xx,yy,z)],.008,black)
 for sx in [-1,1]:tube('Side footrest '+str(sx),[(sx*xx,-yy,z),(sx*xx,yy,z)],.008,black)

def square_stool():
 # One geometry, two named material swatches retained in the source and composition instances.
 box('Narrow rectangular top',(0,0,.738),(.345,.305,.030),blue,.009)
 for sx in [-1,1]:
  for sy in [-1,1]:
   p1=Vector((sx*.148,sy*.129,.018));p2=Vector((sx*.116,sy*.096,.722));mid=(p1+p2)/2
   o=box('Slim squared splayed leg %d %d'%(sx,sy),mid,(.026,.026,(p2-p1).length),blue,.002)
   o.rotation_euler=(p2-p1).to_track_quat('Z','Y').to_euler()
   box('Square stool glide',(p1.x,p1.y,.004),(.028,.028,.008),rubber,.001)
 for sy in [-1,1]:box('Front and rear straight foot rail',(0,sy*.118,.275),(.270,.023,.026),blue,.002)
 for sx in [-1,1]:box('Side straight foot rail',(sx*.135,0,.275),(.023,.235,.026),blue,.002)
 # Preserve swatch as custom data, avoiding unused fake duplicate geometry.
 bpy.context.scene['materialVariants']={'default':'Blue grey painted high stool','teal':'Muted teal stool variant','sameGeometry':True}
 green.use_fake_user=True

def counter():
 box('Narrow pale wood continuous counter',(0,0,1.069),(1.80,.405,.026),wood,.003)
 box('Long black under top rail',(0,0,1.032),(1.66,.045,.058),black,.002)
 for sx in [-1,1]:
  for sy in [-1,1]:
   p1=Vector((sx*.827,sy*.176,.012));p2=Vector((sx*.731,sy*.135,1.040));o=box('Black angled rectangular bar leg %d %d'%(sx,sy),(p1+p2)/2,(.042,.038,(p2-p1).length),black,.002);o.rotation_euler=(p2-p1).to_track_quat('Z','Y').to_euler()
   box('Counter leg floor pad',(p1.x,p1.y,.004),(.044,.041,.008),rubber,.001)
  box('Upper end frame rail '+str(sx),(sx*.741,0,1.024),(.040,.325,.046),black,.002)
 # Rear lower stiffener visible at the window; no speculative mounting to architecture.
 box('Long rear low brace',(0,.168,.175),(1.636,.030,.035),black,.002)

ASSETS=[('photo_lounge_orange_single',single),('photo_lounge_orange_double',double),('photo_lounge_round_table',round_table),('photo_lounge_grey_bar_chair',grey_bar_chair),('photo_lounge_square_stool',square_stool),('photo_lounge_window_counter',counter)]

def reset():
 bpy.ops.wm.read_factory_settings(use_empty=True);bpy.context.preferences.filepaths.save_version=0;bpy.context.scene.unit_settings.system='METRIC'

def bounds():
 bpy.context.view_layer.update();objs=[o for o in bpy.context.scene.objects if o.type=='MESH'];pts=[o.matrix_world@v.co for o in objs for v in o.data.vertices]
 return objs,[[min(p[i] for p in pts) for i in range(3)],[max(p[i] for p in pts) for i in range(3)]]

def freeze_origins():
 bpy.context.view_layer.update()
 for o in [o for o in bpy.context.scene.objects if o.type=='MESH']:
  o.data.transform(o.matrix_world);o.matrix_world=Matrix.Identity(4)
 bpy.context.view_layer.update()

def validate_meshes(objs):
 for o in objs:
  assert all(math.isfinite(v) for vert in o.data.vertices for v in vert.co),o.name
  assert all(p.area>1e-13 for p in o.data.polygons),'Degenerate face '+o.name
  edges=collections.Counter(tuple(sorted(e)) for p in o.data.polygons for e in p.edge_keys)
  assert all(v==2 for v in edges.values()),'Open solid '+o.name
  assert not o.modifiers,'Unapplied modifier '+o.name
  assert o.location.length<1e-8,'Origin not at asset floor '+o.name
  assert all(abs(o.scale[i]-1)<1e-8 for i in range(3))

def render(name,composition=False):
 global LOD
 LOD=0;objs,bb=bounds();lo,hi=map(Vector,bb);center=(lo+hi)/2;size=max(hi-lo)
 ground=material('Review only warm neutral floor',(.44,.44,.415),0,.85);box('RENDER ONLY studio floor',(0,0,-.025),(200,200,.045),ground)
 if composition:target=Vector((.45,.45,.61));camera=Vector((3.1,-5.3,2.75));lens=42
 elif name.endswith('_rear'):target=center;camera=center+Vector((1.38,1.9,.94))*size*1.11;lens=54
 else:target=center;camera=center+Vector((1.28,-1.9,1.04))*size*1.12;lens=54
 bpy.ops.object.camera_add(location=camera);cam=bpy.context.object;cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.lens=lens;bpy.context.scene.camera=cam
 extent=max(size,1)
 for pos,power,radius in [((-1.6,-1.3,2.4),400,2.4),((1.7,.5,1.8),250,2),((-.5,1.8,1.5),300,1.8)]:
  bpy.ops.object.light_add(type='AREA',location=center+Vector(pos)*extent);o=bpy.context.object;o.data.energy=power*extent*extent;o.data.shape='DISK';o.data.size=radius*extent;o.rotation_euler=(target-o.location).to_track_quat('-Z','Y').to_euler()
 sc=bpy.context.scene;sc.world=bpy.data.worlds.new('Neutral CPU review environment');sc.world.use_nodes=True;sc.world.node_tree.nodes.get('Background').inputs['Color'].default_value=(.30,.33,.35,1);sc.world.node_tree.nodes.get('Background').inputs['Strength'].default_value=.45
 sc.render.engine='CYCLES';sc.cycles.device='CPU';sc.cycles.samples=48 if composition else 32;sc.cycles.use_denoising=False;sc.render.resolution_x=1500 if composition else 1050;sc.render.resolution_y=1000 if composition else 880;sc.render.resolution_percentage=100;sc.view_settings.view_transform='AgX';sc.view_settings.exposure=-.58
 sc.render.image_settings.file_format='PNG';sc.render.filepath=str(REVIEW/(name+'.png'));bpy.ops.render.render(write_still=True)

def instance(asset,loc,yaw=0,teal=False):
 path=OUT/asset/(asset+'.blend')
 with bpy.data.libraries.load(str(path),link=False) as (src,dst):dst.objects=src.objects
 imported=[o for o in dst.objects if o]
 for o in imported:bpy.context.collection.objects.link(o)
 bpy.context.view_layer.update();original=[(o,o.matrix_world.copy()) for o in imported];transform=Matrix.Translation(Vector(loc))@Matrix.Rotation(yaw,4,'Z')
 for o,matrix in original:
  o.matrix_world=transform@matrix
  if teal:
   for slot in o.material_slots:
    if slot.material and slot.material.name.startswith('Blue grey painted high stool'):
     mat=bpy.data.materials.get('Composition teal shared stool material')
     if not mat:mat=material('Composition teal shared stool material',(.014,.110,.085),0,.48)
     slot.material=mat
 bpy.context.view_layer.update()

def composition():
 reset();instance('photo_lounge_orange_double',(-1.00,.05,0),.55)
 instance('photo_lounge_round_table',(-.15,-.17,0))
 instance('photo_lounge_orange_single',(.95,-.57,0),-1.15)
 instance('photo_lounge_orange_single',(.67,.78,0),-.45)
 instance('photo_lounge_square_stool',(.02,.65,0),.05)
 instance('photo_lounge_square_stool',(1.18,1.28,0),.05,True)
 instance('photo_lounge_window_counter',(1.80,1.82,0),-.05)
 instance('photo_lounge_grey_bar_chair',(1.47,1.42,0),math.pi-.05)
 instance('photo_lounge_grey_bar_chair',(2.08,1.39,0),math.pi-.05)
 # Source composition is an audit arrangement only, not an installed main scene.
 bpy.ops.wm.save_as_mainfile(filepath=str(REVIEW/'photo_lounge_composition.blend'))
 render('photo_lounge_near_view',True)

selected=[a for a in sys.argv if a.startswith('--asset=')]
if '--render-only' not in sys.argv:
 for asset,build in ASSETS:
  if selected and '--asset='+asset not in selected:continue
  CURRENT_FOLDER=OUT/asset;CURRENT_FOLDER.mkdir(parents=True,exist_ok=True)
  for LOD in range(3):
   reset();palette(asset);build();freeze_origins();objs,bb=bounds();validate_meshes(objs)
   for o in objs:o['scaleStatus']='Estimated from single photo, not measured';o['reference']='Lounge photo 2 supplied 2026-11-03';o['assetId']=asset
   bpy.context.scene['sourceReferenceLibraryId']='src_ref_d30e333223a04a49b35c06e5679ace9c';bpy.context.scene['dimensionsAreEstimated']=True
   p=CURRENT_FOLDER/f'lod{LOD}_source.glb';bpy.ops.export_scene.gltf(filepath=str(p),export_format='GLB',export_extras=True,export_yup=True)
   records.append({'asset':asset,'level':LOD,'triangles':sum(len(p.vertices)-2 for o in objs for p in o.data.polygons),'boundsBlenderXYZ':bb,'sizeBlenderXYZ':[bb[1][i]-bb[0][i] for i in range(3)],'meshParts':len(objs),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
   if LOD==0:bpy.ops.wm.save_as_mainfile(filepath=str(CURRENT_FOLDER/(asset+'.blend')))
 report={'blender':bpy.app.version_string,'units':'m','referenceLibraryId':'src_ref_d30e333223a04a49b35c06e5679ace9c','referencePixelsViewed':True,'dimensions':'All dimensions estimated from one photograph. No measured or manufacturer dimensions claimed.','scope':'Six independent reusable sources only. Existing 19 assets and main scene untouched.','coordinates':'Each mesh has asset-local XYZ coordinates and identity transform; common floor origin (0,0,0). Blender Z up, GLB Y up.','materials':'Metallic-roughness PBR factors. Orange cloth has 128px synthetic base-color and normal periodic tiles; wood counter has 128px synthetic grain. Maps packed in .blend and GLB. No photograph pixels, people or text.','materialVariants':{'photo_lounge_square_stool':['blue grey default','teal instance, same geometry']},'render':'CPU Cycles only. Studio and same-photo-direction composition; stages excluded from individual sources.','omissions':['Hidden swivel brackets, internal upholstery frames and underside fasteners simplified.','Window, wall, outlets, air conditioner and adjacent architecture excluded.','White table top is neutral warm white; faint photo marks cannot establish a true marble pattern.','Counter rear bracing and seat back supports are limited visible-structure estimates.','The loose throw pillow on the foreground chair is omitted from the fixed chair assets; upholstered seat cushions are included.'],'records':records}
 path=REVIEW/'build_report.json'
 if selected and path.exists():
  prior=json.loads(path.read_text());report['records']=[r for r in prior['records'] if '--asset='+r['asset'] not in selected]+records
 path.write_text(json.dumps(report,indent=2))
if '--skip-render' not in sys.argv:
 if '--composition-only' not in sys.argv:
  for asset,build in ASSETS:
   if selected and '--asset='+asset not in selected:continue
   bpy.ops.wm.open_mainfile(filepath=str(OUT/asset/(asset+'.blend')));render(asset)
   if asset=='photo_lounge_orange_single':
    bpy.ops.wm.open_mainfile(filepath=str(OUT/asset/(asset+'.blend')));render(asset+'_rear')
 if not selected or '--composition-only' in sys.argv:composition()
