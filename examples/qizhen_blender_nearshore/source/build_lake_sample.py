"""Deterministic Qizhen teaching-dock sample. No external Blender add-ons.
World XY = source game pixels / 40; Blender Z = height. GLB converts Y-up.
This is a documented game adaptation, NOT a surveyed reconstruction.
"""
import bpy, math, json, random
from pathlib import Path
from mathutils import Vector
BASE=Path(__file__).resolve().parents[1];OUT=BASE/'preview/assets/blender';OUT.mkdir(parents=True,exist_ok=True)
REF=json.loads((BASE/'preview/docs/REFERENCE_GEOMETRY.json').read_text()); RNG=random.Random(75520261018)
S=40.; ORIGIN=(6000,2850)
def P(p,z=0):return Vector(((p[0]-ORIGIN[0])/S,-(p[1]-ORIGIN[1])/S,z))
def gp(p):return ((p[0]-690)*50,(p[1]-290)*50)
# Exact runtime contour has one clipped side arm. Read executable coordinates.
import re
src=(BASE/'preview/scripts/games/lake_geometry.gd').read_text()
LAKE=[gp(p) for p in json.loads(re.search(r'lake_cache=polygon\((\[.*?\])\)',src).group(1))]
ISLAND=[gp(p) for p in REF['island']]
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
for d in [bpy.data.materials,bpy.data.meshes,bpy.data.images,bpy.data.curves]:
 for b in list(d):
  if b.users==0:d.remove(b)
def linear(v):return ((v+.055)/1.055)**2.4 if v>.04045 else v/12.92
M={}
def material(name,col,rough=.86,metal=0,texture=False):
 m=bpy.data.materials.new(name);m.use_nodes=True;p=m.node_tree.nodes.get('Principled BSDF');c=[int(col[i:i+2],16)/255*.83 for i in (0,2,4)]
 p.inputs['Base Color'].default_value=tuple(linear(a) for a in c)+(1,);p.inputs['Roughness'].default_value=rough;p.inputs['Metallic'].default_value=metal
 if texture:
  im=bpy.data.images.new(name+'_paint',width=128,height=128);pix=[]
  for y in range(128):
   for x in range(128):
    # Deliberate brush bands, low contrast, no white speckle/noise.
    q=1+.006*math.sin(x*.045+math.sin(y*.03))+.004*math.cos(y*.07)
    if name=='grass':q=1+.040*math.sin(math.tau*x/128)+.025*math.cos(math.tau*y*2/128)+.018*math.sin(math.tau*(x+y)*3/128)+.008*math.sin(math.tau*x*17/128)*math.cos(math.tau*y*13/128)
    if name=='stone':q=1+.055*math.sin(x*.07+math.sin(y*.04))+.022*math.cos(y*.13)
    pix.extend([max(0,min(1,a*q)) for a in c]+[1])
  im.pixels=pix;im.filepath_raw=str(OUT/(name+'.png'));im.file_format='PNG';im.save();im.pack()
  t=m.node_tree.nodes.new('ShaderNodeTexImage');t.image=im;t.interpolation='Linear' if name=='grass' else 'Closest';m.node_tree.links.new(t.outputs['Color'],p.inputs['Base Color'])
 M[name]=m;return m
for a in [('grass','778b56'),('grass_lit','839761'),('grass_dark','6e8353'),('earth','5b6645'),('stone','a5aa91'),('stone_warm','b5b39a'),('stone_dark','788777'),('coping','c5c2a6'),('mortar','626f64'),('path','c9bda0'),('path_alt','bcb399'),('path_edge','a4a68e'),('blue','3489ad'),('blue_lit','54a4c2'),('blue_dark','246681'),('blue_ridge','65b4ca'),('rubber','334d50'),('metal','707e77'),('rope','c4b788'),('wood','8e714a'),('leaf','647d4b'),('leaf_lit','7b8c54'),('leaf_dark','536b46'),('reed','9aa269'),('reed_dark','738653'),('trunk','6c6045'),('orange','dc7835'),('orange_lit','e9a047'),('orange_dark','894a2b'),('black','364342'),('glass','819c93'),('wall','c1c4ab'),('roof','829389'),('yellow','dcbd64')]:material(a[0],a[1],texture=a[0] in ['grass','stone','path','blue','wood','orange'])
parts=[]; group=None

def parent(name):
 global group
 group=bpy.data.objects.new(name,None);bpy.context.collection.objects.link(group);return group

def mesh(name,verts,faces,mat,bevel=0):
 me=bpy.data.meshes.new(name);me.from_pydata([tuple(v) for v in verts],[],faces);me.update();o=bpy.data.objects.new(name,me);bpy.context.collection.objects.link(o);o.parent=group;o.data.materials.append(M[mat]);parts.append(o)
 uv=me.uv_layers.new(name='UVMap')
 for poly in me.polygons:
  axis=max(range(3),key=lambda i:abs(poly.normal[i]));axes=[i for i in range(3) if i!=axis]
  for li in poly.loop_indices:
   co=me.vertices[me.loops[li].vertex_index].co;uv.data[li].uv=(co[axes[0]]*(.08 if mat=='grass' else .6),co[axes[1]]*(.08 if mat=='grass' else .6))
 if bevel:
  mod=o.modifiers.new('Soft manufactured edges','BEVEL');mod.width=bevel;mod.segments=1
 return o

def box(name,point,size,mat,bevel=.015,z=0):
 c=P(point,z);a,b,h=size[0]/S/2,size[1]/S/2,size[2]/2
 vs=[c+Vector((sx*a,sy*b,sz*h)) for sx,sy,sz in [(-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),(-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1)]]
 return mesh(name,vs,[(3,2,1,0),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],mat,bevel)

def rod(name,a,b,r,mat,verts=7):
 d=Vector(b)-Vector(a);bpy.ops.mesh.primitive_cylinder_add(vertices=verts,radius=r,depth=d.length,location=(Vector(a)+Vector(b))/2);o=bpy.context.object;o.name=name;o.rotation_mode='QUATERNION';o.rotation_quaternion=d.to_track_quat('Z','Y');o.parent=group;o.data.materials.append(M[mat]);parts.append(o);return o

def ico(name,p,r,mat,sub=1,stretch=(1,1,1)):
 bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=sub,radius=r,location=p);o=bpy.context.object;o.name=name;o.scale=stretch;o.parent=group;o.data.materials.append(M[mat]);parts.append(o)
 for poly in o.data.polygons:poly.use_smooth=mat.startswith('leaf')
 return o

def inside(p,poly):
 result=False
 for a,b in zip(poly,poly[1:]+poly[:1]):
  if ((a[1]>p[1])!=(b[1]>p[1])) and p[0]<(b[0]-a[0])*(p[1]-a[1])/(b[1]-a[1])+a[0]:result=not result
 return result

def strip(name,a,b,offset,width,z,mat):
 A=Vector(a);B=Vector(b);d=(B-A).normalized();n=Vector((d.y,-d.x));v=[P(A+n*offset,z),P(B+n*offset,z),P(B+n*(offset+width),z),P(A+n*(offset+width),z)]
 return mesh(name,v,[(0,1,2,3)],mat)

parent('Geography_Exact_Runtime_Shore')
# Scanline slabs complement the lake, preserving every shore vertex without holes.
ys=sorted(set([0,16000]+[p[1] for p in LAKE]));verts=[];faces=[]
for ya,yb in zip(ys,ys[1:]):
 mid=(ya+yb)/2;edges=[]
 for a,b in zip(LAKE,LAKE[1:]+LAKE[:1]):
  if min(a[1],b[1])<mid<max(a[1],b[1]):
   def xx(y):return a[0]+(b[0]-a[0])*(y-a[1])/(b[1]-a[1])
   edges.append((xx(mid),xx(ya),xx(yb)))
 edges.sort();bounds=[(0,0,0)]+edges+[(9000,9000,9000)]
 for i in range(0,len(bounds)-1,2):
  l,r=bounds[i],bounds[i+1];start=len(verts);verts += [P((l[1],ya),.55),P((r[1],ya),.55),P((r[2],yb),.55),P((l[2],yb),.55)];faces.append((start,start+3,start+2,start+1))
mesh('Grass_Exact_Land_Complement',verts,faces,'grass')
mesh('Long_Island_Exact_Outline',[P(p,.55) for p in ISLAND],[tuple(reversed(range(len(ISLAND))))],'grass')
# Coherent dark foundation and cap around every shoreline. Fine blockwork only north sample.
for poly,label in [(LAKE,'Main'),(ISLAND,'Island')]:
 for j,(a,b) in enumerate(zip(poly,poly[1:]+poly[:1])):
  A=Vector(a);B=Vector(b);d=B-A
  mesh(label+'_Bank_Face_%03d'%j,[P(a,-.18),P(b,-.18),P(b,.55),P(a,.55)],[(0,1,2,3)],'stone_dark')
  # lake polygon follows clockwise in screen coordinates; exterior lies to its left
  n=Vector((d.y,-d.x)).normalized()
  if label=='Island':n=-n
  mesh(label+'_Cap_%03d'%j,[P(A-n*3,.58),P(B-n*3,.58),P(B+n*17,.58),P(A+n*17,.58)],[(0,3,2,1)],'coping')
  if min(a[1],b[1])>4700 or max(a[1],b[1])<2000 or max(a[0],b[0])<5500:continue
  count=max(1,int(d.length/28));
  for k in range(count):
   t0=k/count;t1=(k+1)/count;u=A+d*t0;v=A+d*t1;center=(u+v)/2+n*4
   # offset staggered blocks, individual bevel, material tonal variation
   for row in range(2):
    aa=u+d.normalized()*1.1-n*.8;bb=v-d.normalized()*1.1-n*.8
    mesh('Stone_Block_%s_%d_%d_%d'%(label,j,k,row),[P(aa,-.10+row*.29),P(bb,-.10+row*.29),P(bb,.16+row*.29),P(aa,.16+row*.29)],[(0,1,2,3)],['stone','stone_warm','stone_dark'][(k+row)%3])
   # Separate cap joints and grass transition w/ broader vegetation patches
   if k%2==0:
    strip('Grass_Edge_%d_%d'%(j,k),u,v,20,20+RNG.random()*22,.56,'grass')
  # Shared miter vertices prevent overlapping slab faces / z-fighting at every turn.
  def joined(index,offset):
   v=Vector(poly[index%len(poly)]);prev=(v-Vector(poly[(index-1)%len(poly)])).normalized();nxt=(Vector(poly[(index+1)%len(poly)])-v).normalized()
   n0=Vector((prev.y,-prev.x));n1=Vector((nxt.y,-nxt.x));bis=(n0+n1).normalized();factor=max(.35,bis.dot(n1))
   if label=='Island':bis=-bis
   return v+bis*(offset/factor)
  def path_quad(name,offset,width,z,mat,t0=0,t1=1,gap=0):
   l0,l1=joined(j,offset),joined(j+1,offset);r0,r1=joined(j,offset+width),joined(j+1,offset+width)
   a0=l0.lerp(l1,t0)+d.normalized()*gap;a1=l0.lerp(l1,t1)-d.normalized()*gap;b0=r0.lerp(r1,t0)+d.normalized()*gap;b1=r0.lerp(r1,t1)-d.normalized()*gap
   mesh(name,[P(a0,z),P(a1,z),P(b1,z),P(b0,z)],[(0,1,2,3)],mat)
  count=max(1,int(d.length/52))
  for k in range(count):path_quad('Promenade_Slab_%d_%d'%(j,k),55,63,.575,'path' if k%3 else 'path_alt',k/count,(k+1)/count,1.1)
  path_quad('Promenade_Edge_%d'%j,51,4,.61,'path_edge');path_quad('Promenade_Edge2_%d'%j,118,4,.61,'path_edge')

# Carefully restrained vegetation on land. Canopies are separate low-poly painted layers.
parent('North_Bank_Detail_Art_Adaptation')
def tree(x,y,r=1.3):
 base=P((x,y),.55);rod('Tree_Trunk',base,base+Vector((.06,0,2.5)),.10,'trunk')
 # Off-centre, differently-sized leaf masses. No concentric rings or repeated tiers.
 turn=(x*.013+y*.007)%math.tau
 clusters=[(0,0,2.60,.73,'leaf_dark'),(-.66,.10,2.66,.42,'leaf'),(.53,-.11,2.88,.60,'leaf'),(.05,.56,2.77,.51,'leaf'),(-.31,-.48,3.02,.53,'leaf'),(-.24,.18,3.45,.54,'leaf_lit'),(.38,.15,3.27,.34,'leaf'),(-.18,.42,3.66,.27,'leaf_lit')]
 for q,(xx,yy,zz,rr,mat) in enumerate(clusters):
  xx,yy=(xx*math.cos(turn)-yy*math.sin(turn)),(xx*math.sin(turn)+yy*math.cos(turn))
  off=Vector((xx*r,yy*r,zz+.08*math.sin(q+turn)))
  ico('Irregular_Painted_Leaf_Mass',base+off,r*rr,mat,2,(1,.85+.08*math.sin(turn+q),.82))
for x,y,r in [(6380,2350,1.2),(6510,2580,1.6),(6350,3000,1.35),(6260,3220,1.6),(6110,3500,1.3),(6160,3800,1.5),(6360,4010,1.4),(6440,4280,1.6),(6260,2520,1.0),(6480,3580,1.4)]:
 if not inside((x,y),LAKE):tree(x,y,r)
# grass tuft ribbons, no bright random flecks
for a,b in zip(LAKE,LAKE[1:]+LAKE[:1]):
 A=Vector(a);B=Vector(b);d=B-A
 if min(a[1],b[1])>4400 or max(a[1],b[1])<2100 or min(a[0],b[0])<5700:continue
 n=Vector((d.y,-d.x)).normalized()
 for k in range(max(1,int(d.length/25))):
  c=A+d*(k/max(1,int(d.length/25)))+n*RNG.uniform(23,46)
  if 5900<c.x<6300 and 2650<c.y<2880:continue
  for q in range(3):
   p=P(c+Vector((q*2,0)),.56);h=RNG.uniform(.23,.55)
   mesh('Shore_Grass_Blade',[p,p+Vector((.045,0,0)),p+Vector((.045,.06,h))],[(0,1,2)],'reed' if q==1 else 'reed_dark')
# Broken reed clumps and shallow moss follow the actual edge, never a straight green stripe.
for y in [2940,2970,3190,3220,3250,3470,3500,3770,3800,4070]:
 for a,b in zip(LAKE,LAKE[1:]+LAKE[:1]):
  if a[1]<=y<b[1] and min(a[0],b[0])>5700:
   t=(y-a[1])/(b[1]-a[1]);x=a[0]+(b[0]-a[0])*t
   for q in range(9):
    xx=x+RNG.uniform(-5,18);yy=y+RNG.uniform(-20,20);z=.55 if xx>x else .03
    base=P((xx,yy),z);h=RNG.uniform(.32,.8)
    rod('Bank_Reed_Stem',base,base+Vector((RNG.uniform(-.05,.06),.05,h)),.012,'reed_dark',5)
    mesh('Bank_Reed_Leaf',[base+Vector((0,0,h*.3)),base+Vector((.04,0,h*.75)),base+Vector((.17,.02,h*.86))],[(0,1,2)],'reed')
# Low shrubs soften the grass transition with broad readable shapes.
for x,y in [(6320,2960),(6180,3270),(6100,3580),(6250,4020)]:
 for q in range(4):
  ico('Low_Bank_Shrub',P((x+q*16,y+RNG.uniform(-10,10)),.85),RNG.uniform(.3,.48),'leaf' if q%2 else 'leaf_lit',1,(1,.7,.65))

# A real thickness module deck. Each float has a recessed tread, seam and bolt.
parent('Blue_Teaching_Float_Approximate_Not_Surveyed')
for ix in range(8):
 for iy in range(3):
  x=5998+ix*28;y=2726+iy*28
  box('Blue_Float_Body_%d_%d'%(ix,iy),(x,y),(27.1,27.1,.31),'blue_dark',.045,z=.07)
  box('Blue_Float_Tread_%d_%d'%(ix,iy),(x,y),(26.4,26.4,.09),'blue' if (ix+iy)%3 else 'blue_lit',.035,z=.265)
  for l in range(4):box('Non_Slip_Ridge',(x-8+l*5.2,y),(1.3,18,.015),'blue_ridge',.003,z=.318)
  for dx,dy in [(-10,-10),(10,10)]:box('Module_Pin',(x+dx,y+dy),(2.5,2.5,.025),'blue_lit',.007,z=.33)
# physical contact: gangway reaches deck and shore, with end plates and handrails
for i in range(9):
 x=6212+i*9;z=.31+(i/8)*.24
 box('Gangway_Tread_%d'%i,(x,2740),(8.4,42,.11),'metal',.01,z=z)
for y in [2718,2762]:
 for x in [6215,6250,6285]:
  z=.31+(x-6212)/72*.24;rod('Gangway_Rail_Post',P((x,y),z),P((x,y),z+.64),.023,'metal')
 rod('Gangway_Continuous_Handrail',P((6212,y),.95),P((6292,y),1.21),.025,'metal')
for x,y in [(5996,2787),(6198,2787),(5996,2715),(6198,2715)]:
 box('Cleat_Base',(x,y),(9,6,.045),'metal',.008,z=.36);rod('Cleat_Horn',P((x-6,y),.42),P((x+6,y),.42),.028,'metal')
for x in [6002,6080,6186]:
 # cylindrical rubber fender touches float side and water
 rod('Rubber_Fender',P((x,2799),.14),P((x+12,2799),.14),.105,'rubber',10)
# Rope from the outer module to a shore ring, touching cleats
rope=[(6198,2715,.45),(6225,2696,.35),(6250,2690,.47),(6276,2690,.61)]
for a,b in zip(rope,rope[1:]):rod('Mooring_Line',P(a[:2],a[2]),P(b[:2],b[2]),.018,'rope')
# Small plausible campus furnishings, no invented plot props
parent('Campus_Furnishings_Art_Adaptation')
for x,y in [(6260,3080),(6092,3650)]:
 for k in range(4):box('Bench_Slat',(x+k*5,y),(3.8,45,.08),'wood',.01,z=.96)
 for dy in [-15,15]:
  rod('Bench_Leg',P((x+3,y+dy),.57),P((x+3,y+dy),.93),.045,'metal');rod('Bench_Leg',P((x+15,y+dy),.57),P((x+15,y+dy),.93),.045,'metal')
for x,y in [(6310,2880),(6170,3410),(6250,3920)]:
 rod('Path_Lamp_Post',P((x,y),.58),P((x,y),2.6),.046,'metal');box('Path_Lamp_Hood',(x,y),(15,15,.11),'metal',.02,z=2.66);box('Path_Lamp_Diffuser',(x,y),(10,10,.20),'coping',.01,z=2.51)
# Subtle library edge establishes the east-bank campus, not a featureless wall.
parent('Library_Edge_Stylized_Position_Only')
box('Library_Footing',(6800,2580),(330,720,.18),'path_edge',.025,z=.64)
box('Library_Volume',(6800,2580),(310,700,3.0),'wall',.035,z=2.16)
box('Library_Roof',(6800,2580),(326,716,.16),'roof',.02,z=3.74)
for y in range(2260,2910,44):
 box('Library_Glass_Bay',(6643,y),(3,35,1.85),'glass',.005,z=2.17)
 box('Library_Recessed_Fin',(6639,y+21),(13,4,2.6),'coping',.01,z=2.2)

# Kayak mesh authored around origin; rigid hull, open cockpit and deck seam.
parent('Player_Kayak_Rigid_Hull')
boat_group=group
# local Blender coordinates: positive Y is bow. Top length matches original 79px hull.
rings=[(-.98,.008),(-.83,.15),(-.54,.27),(0,.31),(.55,.25),(.85,.13),(.98,.008)]
vs=[]
for y,w in rings:vs.extend([Vector((-w,y,.025)),Vector((-w*.8,y,-.10)),Vector((w*.8,y,-.10)),Vector((w,y,.025))])
faces=[]
for i in range(len(rings)-1):
 for j in range(3):faces.append((i*4+j,i*4+j+1,(i+1)*4+j+1,(i+1)*4+j))
mesh('Kayak_Continuous_Hull',vs,faces,'orange_dark')
# Deck strips leave a real open cockpit rather than painted void.
for side in [-1,1]:
 for i in range(len(rings)-1):
  y,w=rings[i];Y,W=rings[i+1];inner=.13 if abs(y)<.57 else 0;Inner=.13 if abs(Y)<.57 else 0
  mesh('Kayak_Deck',[(side*w,y,.035),(side*W,Y,.035),(side*Inner,Y,.09),(side*inner,y,.09)],[(0,1,2,3)],'orange' if side<0 else 'orange_lit')
mesh('Cockpit_Dark_Recess',[(-.13,-.56,-.02),(.13,-.56,-.02),(.13,.56,-.02),(-.13,.56,-.02)],[(0,1,2,3)],'black')
for side in [-1,1]:rod('Cockpit_Rim',Vector((side*.14,-.54,.08)),Vector((side*.14,.54,.08)),.024,'orange_lit')
for y in [-.55,.55]:rod('Cockpit_End_Rim',Vector((-.14,y,.08)),Vector((.14,y,.08)),.024,'orange_lit')
for y in [-.72,.70]:rod('Kayak_Deck_Grip',Vector((-.09,y,.065)),Vector((.09,y,.065)),.012,'black')
# Move separate kayak out of scenery export, then export independently.
for o in bpy.context.scene.objects:o.select_set(False)
boat_children=list(boat_group.children)
for o in boat_children+[boat_group]:o.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(OUT/'qizhen_kayak.glb'),export_format='GLB',use_selection=True,export_apply=True,export_yup=True)
boat_group.hide_render=True
for o in boat_children:o.hide_render=True
# Editable source keeps all named component meshes and generated materials.
bpy.ops.wm.save_as_mainfile(filepath=str(BASE/'source/qizhen_north_bank.blend'))
# Runtime-only batching: bake bevels, preserve UVs, one mesh per painted material.
# The saved .blend above stays fully editable; this reduces 1500 draw calls to ~30.
deps=bpy.context.evaluated_depsgraph_get();buckets={}
for o in parts:
 if o in boat_children or o.type!='MESH':continue
 ev=o.evaluated_get(deps);me=ev.to_mesh();key=o.data.materials[0].name
 bucket=buckets.setdefault(key,{'vertices':[],'faces':[],'uv':[],'smooth':[]});offset=len(bucket['vertices'])
 bucket['vertices'].extend([tuple(o.matrix_world@v.co) for v in me.vertices])
 for poly in me.polygons:
  bucket['faces'].append(tuple(offset+i for i in poly.vertices));bucket['smooth'].append(poly.use_smooth)
  bucket['uv'].append([tuple(me.uv_layers.active.data[i].uv) if me.uv_layers.active else (0,0) for i in poly.loop_indices])
 ev.to_mesh_clear()
for o in bpy.context.scene.objects:o.select_set(False)
for key,ba in buckets.items():
 me=bpy.data.meshes.new('Batch_'+key);me.from_pydata(ba['vertices'],[],ba['faces']);me.update();uv=me.uv_layers.new(name='UVMap')
 for poly,puv,smooth in zip(me.polygons,ba['uv'],ba['smooth']):
  poly.use_smooth=smooth
  for li,co in zip(poly.loop_indices,puv):uv.data[li].uv=co
 ob=bpy.data.objects.new('Batch_'+key,me);bpy.context.collection.objects.link(ob);ob.data.materials.append(M[key]);ob.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(OUT/'qizhen_north_bank.glb'),export_format='GLB',use_selection=True,export_apply=True,export_yup=True)
meta={'units':'game pixels / 40, NOT measured metres','origin_game_px':ORIGIN,'lake_polygon_exact':LAKE,'dock_collision_rect':[5984,2712,224,84],'dock_contact_point':[6000,2796],'sample_scope':'north/library-side teaching dock and short nearby recovery loop','artistic_adaptations':['modular dock dimensions and attachment','stone courses, vegetation, promenade and furnishings','library facade details'],'source_links':[REF['source_url'],REF['teaching_dock']['source_url']],'runtime_environment_draw_groups':len(buckets),'mesh_objects':len(parts),'vertices':sum(len(o.data.vertices) for o in parts if o.type=='MESH'),'triangles_estimate':sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in parts if o.type=='MESH')}
(BASE/'verification/model_manifest.json').write_text(json.dumps(meta,ensure_ascii=False,indent=2));(OUT/'scene_manifest.json').write_text(json.dumps(meta,ensure_ascii=False,indent=2))
print('LAKE_BUILD_OK',json.dumps({k:meta[k] for k in ['mesh_objects','vertices','triangles_estimate']}))
