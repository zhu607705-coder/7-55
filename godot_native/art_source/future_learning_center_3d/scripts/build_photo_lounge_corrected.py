"""Corrected photo-2 lounge sources, Blender 4.3.2.
Run blender -b -t 4 --python scripts/build_photo_lounge_corrected.py [-- --skip-render].
Optional --render-only or --asset=lounge_double_corrected.
Photo pixels are observed, never used as maps. All metric dimensions are estimates.
"""
import bpy, math, json, hashlib, sys, collections
import numpy as np
from pathlib import Path
from mathutils import Vector, Matrix
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'sources/models/photo_lounge_corrected';REVIEW=ROOT/'review/photo_lounge_corrected'
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
 orange=synthetic('Terracotta woven upholstery',(.54,.125,.060),'weave') if 'lounge' in asset else None
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
 sc.render.engine='CYCLES';sc.cycles.device='CPU';sc.cycles.samples=48;sc.cycles.use_denoising=False;sc.render.resolution_x=1500 if composition else 1050;sc.render.resolution_y=1000 if composition else 880;sc.render.resolution_percentage=100;sc.view_settings.view_transform='AgX';sc.view_settings.exposure=-.58
 sc.render.image_settings.file_format='PNG';sc.render.filepath=str(REVIEW/(name+'.png'));bpy.ops.render.render(write_still=True)


# All numerical dimensions below are visual estimates, not measured furniture specs.
def path_at(u,w,double):
 a=math.radians(-43+266*u);c=math.cos(a);s=math.sin(a)
 # The double has a broad flatter back panel rather than a stretched circular bowl.
 xp=.51 if double else .77
 p=Vector((w*.5*math.copysign(abs(c)**xp,c),.025+.338*math.copysign(abs(s)**.70,s),0))
 top=.443+.407*max(0,s)**.67
 return p,top

def path_normal(u,w,double):
 pa,_=path_at(max(0,u-.0001),w,double);pb,_=path_at(min(1,u+.0001),w,double)
 t=(pb-pa).normalized();return Vector((t.y,-t.x,0))

def padded_back(w,double):
 ns=[88,52,28][LOD];nc=[24,16,10][LOD];vs=[];uv=[]
 for i in range(ns+1):
  u=i/ns;p,top=path_at(u,w,double);n=path_normal(u,w,double)
  bottom=.389+.014*math.sin(math.pi*u);mid=(top+bottom)/2;h=(top-bottom)/2
  # Upholstery is a thick closed volume with a modest face bulge and soft rolled edge.
  for j in range(nc):
   a=math.tau*j/nc;c=math.cos(a);s=math.sin(a)
   off=-.026+.061*math.copysign(abs(c)**.64,c)
   z=mid+h*math.copysign(abs(s)**.65,s)
   if double and c<0:
    # Recess the center seam into the padded face, not a painted dark stripe.
    off+=.008*math.exp(-((u-.5)/.012)**2)*max(0,1-(abs(z-mid)/(h+.001))**4)
   v=p+n*off;v.z=z;vs.append(v);uv.append((u*(2*w+.5)*9,(z-.38)*9))
 fs=[tuple(reversed(range(nc))),tuple(range(ns*nc,(ns+1)*nc))]
 for i in range(ns):
  for j in range(nc):a=i*nc+j;b=i*nc+(j+1)%nc;fs.append((a,b,b+nc,a+nc))
 mesh('Thick upholstered back and descending side wings',vs,fs,orange,uv)
 # Outer backing, tapering beneath the seat and overlapping the concealed underside.
 nq=[12,8,5][LOD];vs=[];uv=[];fs=[]
 for k in range(nq+1):
  t=k/nq
  for i in range(ns+1):
   u=i/ns;p,top=path_at(u,w,double);n=path_normal(u,w,double)
   z=.329+(top-.349)*t**1.7
   # Contract only below the padded back. Above its lower edge the shell must envelop it.
   f=max(0,min(1,(z-.329)/.050));f=f*f*(3-2*f);fac=.72+.28*f
   v=Vector((p.x*fac,.025+(p.y-.025)*fac,z))+n*.043
   vs.append(v);uv.append((u*3,t))
 for k in range(nq):
  for i in range(ns):a=k*(ns+1)+i;fs.append((a,a+1,a+ns+2,a+ns+1))
 shell_solid('Charcoal outer backing with rolled front ends',vs,fs,uv,shell,.013)
 rounded_cushion('Concealed upholstered shell underside',w*.82,.60,.332,.038,shell,y=.015,power=.73)
 if LOD<2:
  pts=[]
  for i in range(ns+1):
   u=i/ns;p,top=path_at(u,w,double);n=path_normal(u,w,double);p+=n*(-.026);p.z=top+.0005;pts.append(p)
  tube('Fine top edge upholstery welt',pts,.0017,seam,6)
  if double:
   p,top=path_at(.5,w,double);n=path_normal(.5,w,double)
   pts=[]
   for j in range(24):
    z=.432+(top-.030-.432)*j/23;mid=(top+.403)/2;h=(top-.403)/2
    sz=max(-1,min(1,(z-mid)/h));ss=math.copysign(abs(sz)**(1/.65),sz);cc=-math.sqrt(max(0,1-ss*ss));off=-.026+.061*math.copysign(abs(cc)**.64,cc)+.006
    q=p+n*off;q.z=z;pts.append(q)
   tube('Recessed central back upholstery seam',pts,.0014,seam,6)

def flat_seat(w):
 n=[96,56,28][LOD];profiles=[(.92,-.40),(1,-.24),(1,.08),(.985,.28),(.93,.39),(.72,.43),(.33,.44)]
 vs=[];uv=[];width=w*.91;depth=.713;zc=.426;th=.089
 for sc,h in profiles:
  for i in range(n):
   a=math.tau*i/n;c,s=math.cos(a),math.sin(a);x=width/2*math.copysign(abs(c)**.61,c)*sc*(1-.09*max(0,s));y=depth/2*math.copysign(abs(s)**.61,s)*sc-.060
   vs.append((x,y,zc+h*th-.008*max(0,s)));uv.append((x*9,y*9))
 fs=[tuple(reversed(range(n)))]
 for k in range(len(profiles)-1):
  for i in range(n):a=k*n+i;b=k*n+(i+1)%n;fs.append((a,b,b+n,a+n))
 fs.append(tuple(range((len(profiles)-1)*n,len(profiles)*n)))
 mesh('Independent flatter seat cushion with thin front edge',vs,fs,orange,uv)
 if LOD<2:
  pts=[]
  for i in range(n+1):
   a=math.tau*i/n;c,s=math.cos(a),math.sin(a)
   pts.append((width/2*math.copysign(abs(c)**.61,c)*(1-.09*max(0,s)),depth/2*math.copysign(abs(s)**.61,s)-.060,zc-.006-.008*max(0,s)))
  # Closed curve represented as solid segments with duplicate final ring; overlap is deliberate at weld join.
  tube('Seat perimeter fine fabric welt',pts,.0017,seam,6)

def star_base(double):
 cylinder('Concealed central seat support',(0,.025,.259),.035,.145,black)
 for sx in [-1,1]:
  for sy in [-1,1]:
   end=Vector((sx*(.57 if double else .345),sy*.305+.025,.019));start=Vector((0,.025,.175));direction=Vector((end.x,end.y-.025,0)).normalized();side=Vector((-direction.y,direction.x,0));verts=[]
   for p,width,height in [(start,.046,.051),(end,.018,.017)]:
    for dz in [-height/2,height/2]:
     for sign in [-1,1]:verts.append(p+side*width*.5*sign+Vector((0,0,dz)))
   faces=[(0,2,3,1),(4,5,7,6),(0,1,5,4),(2,6,7,3),(0,4,6,2),(1,3,7,5)]
   o=mesh('Tapered central four star blade %d %d'%(sx,sy),verts,faces,black,smooth=False)
   if LOD<2:bevel(o,.002)
   cylinder('Small dark floor glide %d %d'%(sx,sy),(end.x,end.y,.004),.012,.008,rubber)

def corrected_lounge(double=False):
 w=1.43 if double else .875;padded_back(w,double);flat_seat(w);star_base(double)

def loose_pillow():
 # Standalone optional cushion, local origin at bottom. Pose belongs to scene instance.
 n=[80,48,24][LOD];rings=[(.98,0),(.88,-.039),(.58,-.063),(.08,-.071),(.08,.071),(.58,.063),(.88,.039)]
 # Use two independently filled sides joined at a closed perimeter.
 vs=[];uv=[]
 for sc,y in rings:
  for i in range(n):
   a=math.tau*i/n;c,s=math.cos(a),math.sin(a);x=.184*math.copysign(abs(c)**.44,c)*sc;z=.184*math.copysign(abs(s)**.44,s)*sc
   yy=y;vs.append((x,yy,z+.181));uv.append((x*9,z*9))
 fs=[]
 # ordering rings follows front surface inward, jumps through central bridge to back, returns perimeter.
 for k in range(len(rings)-1):
  if k==3:continue
  for i in range(n):a=k*n+i;b=k*n+(i+1)%n;fs.append((a,b,b+n,a+n))
 fs.append(tuple(reversed(range(3*n,4*n))));fs.append(tuple(range(4*n,5*n)))
 for i in range(n):a=(len(rings)-1)*n+i;b=(len(rings)-1)*n+(i+1)%n;fs.append((a,b,(i+1)%n,i))
 mesh('Optional loose softly stuffed square cushion',vs,fs,orange,uv)
 if LOD<2:
  pts=[(*vs[i],) for i in range(n)]+[vs[0]];tube('Loose cushion sewn perimeter',pts,.0015,seam,6)
 # Exact floor origin for integration.
 objs,bb=bounds()
 for o in objs:
  for v in o.data.vertices:v.co.z-=bb[0][2]

BUILDERS=[('lounge_single_corrected',lambda:corrected_lounge(False)),('lounge_double_corrected',lambda:corrected_lounge(True)),('lounge_loose_cushion',loose_pillow)]

def normalize_validate():
 import bmesh
 freeze_origins();objs,bb=bounds();checks=[]
 for o in objs:
  bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.normal_update()
  if bm.calc_volume(signed=True)<0:bmesh.ops.reverse_faces(bm,faces=list(bm.faces));bm.normal_update()
  bad_edges=sum(not e.is_manifold for e in bm.edges);bad_faces=sum(f.calc_area()<1e-12 for f in bm.faces);bad_normals=sum(not all(math.isfinite(x) for x in f.normal) or f.normal.length<.99 for f in bm.faces)
  assert not (bad_edges or bad_faces or bad_normals),(o.name,bad_edges,bad_faces,bad_normals)
  volume=bm.calc_volume(signed=True);assert volume>1e-12,(o.name,volume)
  checks.append({'part':o.name,'boundaryOrNonManifoldEdges':bad_edges,'degenerateFaces':bad_faces,'invalidNormals':bad_normals,'signedVolume':volume})
  bm.to_mesh(o.data);bm.free();o.data.update()
 validate_meshes(objs);return objs,bb,checks

if __name__=='__main__':
 selected=[a.split('=',1)[1] for a in sys.argv if a.startswith('--asset=')]
 for asset,builder in BUILDERS:
  if selected and asset not in selected:continue
  CURRENT_FOLDER=OUT/asset;CURRENT_FOLDER.mkdir(parents=True,exist_ok=True)
  if '--render-only' not in sys.argv:
   for LOD in range(3):
    reset();palette(asset);builder();objs,bb,checks=normalize_validate()
    for o in objs:o['assetId']=asset;o['dimensions']='Photo-estimated metres, not surveyed';o['reference']='User lounge photo 2, 2026-11-03';o['part']=o.name
    sc=bpy.context.scene;sc['referenceToken']='photo_reference_lounge_02';sc['dimensionsAreEstimated']=True;sc['supersedesUnacceptedCandidate']=True
    p=CURRENT_FOLDER/f'lod{LOD}_source.glb';bpy.ops.export_scene.gltf(filepath=str(p),export_format='GLB',export_extras=True,export_yup=True)
    records.append({'asset':asset,'level':LOD,'boundsBlenderXYZ':bb,'sizeBlenderXYZ':[bb[1][i]-bb[0][i] for i in range(3)],'triangles':sum(len(p.vertices)-2 for o in objs for p in o.data.polygons),'meshParts':len(objs),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'validation':checks})
    if LOD==0:bpy.ops.wm.save_as_mainfile(filepath=str(CURRENT_FOLDER/(asset+'.blend')))
  if '--skip-render' not in sys.argv:
   bpy.ops.wm.open_mainfile(filepath=str(CURRENT_FOLDER/(asset+'.blend')));render(asset)
 report={'blender':bpy.app.version_string,'units':'m','coordinates':'Blender Z up, front -Y; glTF Y up, front +Z (export conversion maps Blender -Y to glTF +Z). Floor-centred identity objects.','dimensions':'Photo-estimated, not measured; no manufacturer identity claimed.','referenceToken':'photo_reference_lounge_02','scope':'Corrected source assets only. CPU images are modelling QA, not viewer acceptance.','records':records}
 if records:
  report_path=REVIEW/'build_report.json'
  if selected and report_path.exists():
   prior=json.loads(report_path.read_text());report['records']=[r for r in prior['records'] if r['asset'] not in selected]+records
  report_path.write_text(json.dumps(report,indent=2))
