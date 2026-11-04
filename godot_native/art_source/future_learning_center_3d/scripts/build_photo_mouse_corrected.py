"""Photo-referenced candidates. Blender 4.3.2, metres, no image textures/private pixels.
Run blender -b --factory-startup -t 4 --python scripts/build_photo_desktop.py
"""
import bpy, math, json, hashlib, sys
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'sources/models/photo_desktop_corrected'; REVIEW=ROOT/'review/photo_desktop_corrected'
OUT.mkdir(parents=True,exist_ok=True); REVIEW.mkdir(parents=True,exist_ok=True)
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
  m=o.modifiers.new('Manufactured edge radius','BEVEL');m.width=min(bevel,min(size)*.45);m.segments=3 if LOD==0 else 2 if LOD==1 else 1
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
def palette():
 global black, screen, silver, ivory, keywhite, mint, yellow, coral, rubber
 black=material('Charcoal matte bezel',(.013,.017,.021),0,.32)
 screen=material('Neutral blank screen no private content',(.028,.065,.084),0,.24)
 silver=material('Satin silver stand',(.48,.51,.52),.8,.32)
 ivory=material('Warm ivory molded shell',(.70,.71,.66),0,.38)
 keywhite=material('Ivory PBT keycaps',(.84,.84,.77),0,.48)
 mint=material('Mint accent key',(.04,.60,.43),0,.44)
 yellow=material('Warm yellow accent key',(.95,.51,.018),0,.44)
 coral=material('Coral accent polymer',(.93,.14,.11),0,.43)
 rubber=material('Dark underside elastomer',(.025,.029,.030),0,.76)
def monitor():
 box('Monitor bezel', (0,.028,.305),(.614,.025,.355),black,.0035)
 box('Neutral screen', (0,.0148,.308),(.598,.0018,.3364),screen,.0012)
 box('Stand base',(0,.025,.007),(.235,.180,.014),silver,.005)
 box('Stand neck',(0,.052,.135),(.034,.034,.255),silver,.005)
 box('Plain rear hinge inferred',(0,.048,.270),(.062,.022,.050),black,.005)
 if LOD<2:
  box('Stand foot dark underside',(0,.025,.002),(.218,.163,.004),rubber,.004)
  box('Lower bezel fine reveal',(0,.013,.136),(.575,.0005,.0006),rubber)
 # Intentionally no guessed ports, brand, camera or personal screen texture.
def key(name,x,y,w,mat):
 # Actual individual cap gaps, a recessed mounting deck and a softened upper rim.
 z=.023+.013*(y+.0725)/.145
 box('Keycap '+name,(x,y,z),(w,.0156,.009),mat,.0016)
 if LOD==0:
  box('Keycap top '+name,(x,y,z+.00445),(w-.003,.0124,.0005),mat,.0009)
def keyboard():
 box('Keyboard shell',(0,0,.012),(.370,.145,.024),ivory,.008)
 box('Keyboard recessed dark deck',(0,.001,.023),(.355,.132,.004),black,.005)
 # Compact candidate, photo crop prevents reliable full-layout recovery.
 pitch=.0215;left=-.166
 for row in range(6):
  y=.057-row*.022
  if row==0:
   for j in range(16):key('function %02d'%j,left+j*.0215,y,.017,mint if j==0 else yellow if j==14 else coral if j==15 else keywhite)
  elif row in [1,2,3]:
   widths=([1]*13+[2] if row==1 else [1.5]+[1]*12+[1.5] if row==2 else [1.75]+[1]*11+[2.25])
   x=-.178
   for j,u in enumerate(widths):
    w=u*pitch-.002;key('row%d-%02d'%(row,j),x+u*pitch/2,y,w,keywhite);x+=u*pitch
   key('navigation '+str(row),.166,y,.017,keywhite)
  elif row==4:
   widths=[2.25]+[1]*10+[2.75];x=-.178
   for j,u in enumerate(widths):key('shift row %02d'%j,x+u*pitch/2,y,u*pitch-.002,keywhite);x+=u*pitch
   key('arrow up',.166,y,.017,keywhite)
  else:
   widths=[1.25,1.25,1.25,6.25,1,1,1,1,1];x=-.178
   for j,u in enumerate(widths):key('bottom %02d'%j,x+u*pitch/2,y,u*pitch-.002,keywhite);x+=u*pitch
   key('arrow right',.166,y,.017,keywhite)
 if LOD<2:
  for x in [-.145,.145]:
   for y in [-.05,.05]:box('Keyboard foot',(x,y,.001),(.025,.013,.002),rubber,.003)
 # No unreadable/misleading copied legends: unprinted candidate keycaps.
def mouse():
 # Smooth closed parametric body. Front is negative Y; back fullness inferred.
 nx=[40,24,12][LOD];ny=[16,10,6][LOD]
 # Upper shell closes onto an oval base, not an egg or a square pedestal.
 verts=[(0,0,.040)]
 for j in range(1,ny+1):
  t=(math.pi/2)*j/ny
  for i in range(nx):
   a=math.tau*i/nx;verts.append((.0325*math.sin(t)*math.cos(a),.0625*math.sin(t)*math.sin(a),.008+.032*math.cos(t)))
 faces=[(0,1+i,1+(i+1)%nx) for i in range(nx)]
 for j in range(ny-1):
  for i in range(nx):a=1+j*nx+i;b=1+j*nx+(i+1)%nx;faces.append((a,a+nx,b+nx,b))
 faces.append(tuple(range(1+(ny-1)*nx,1+ny*nx))[::-1])
 me=bpy.data.meshes.new('Mouse rounded closed shell');me.from_pydata(verts,[],faces);me.update();o=bpy.data.objects.new('Mouse body',me);bpy.context.collection.objects.link(o)
 gradient=material('Smooth ivory coral vertex-color polymer',(1,1,1),0,.40)
 attr=me.color_attributes.new(name='PhotoCandidateColor',type='FLOAT_COLOR',domain='POINT')
 for i,v in enumerate(me.vertices):
  f=max(0,min(1,(v.co.y+.035)/.080));f=f*f*(3-2*f)
  attr.data[i].color=tuple((1-f)*a+f*b for a,b in zip((.84,.84,.77),(.95,.12,.08)))+(1,)
 node=gradient.node_tree.nodes.new('ShaderNodeVertexColor');node.layer_name=attr.name;gradient.node_tree.links.new(node.outputs['Color'],gradient.node_tree.nodes.get('Principled BSDF').inputs['Base Color']);finish(o,o.name,gradient)
 # Separate shell-following click surfaces conform to shell above its front hemisphere.
 for side,label in [(-1,'Left click'),(1,'Right click')]:
  vs=[];fs=[];n=[10,6,3][LOD]
  for j in range(n+1):
   y=-.058+j*.050/n
   for i in range(n+1):
    edge=.0325*math.sqrt(max(0,1-(y/.0625)**2))*.92
    x=side*(.002+i*(edge-.002)/n);v=max(0,1-(x/.0325)**2-(y/.0625)**2);z=.008+.032*math.sqrt(v)
    vs.append((x,y,z+.0003))
  for j in range(n):
   for i in range(n):a=j*(n+1)+i;fs.append((a,a+1,a+n+2,a+n+1) if side==1 else (a,a+n+1,a+n+2,a+1))
  me=bpy.data.meshes.new(label);me.from_pydata(vs,[],fs);me.update();o=bpy.data.objects.new(label,me);bpy.context.collection.objects.link(o);finish(o,label,ivory)
 cyl('Scroll wheel',(0,-.025,.040),.006,.006,rubber,'X')
 if LOD<2:
  for j in range(12 if LOD==0 else 6):
   a=math.tau*j/(12 if LOD==0 else 6);box('Scroll wheel tread',(0,-.025+.006*math.sin(a),.040+.006*math.cos(a)),(.006,.0006,.0006),rubber)
 for y in [-.014,.010]:box('Side button',(-.031,y,.023),(.003,.017,.005),coral,.0015)
 o=cyl('Mouse underside plain inferred',(0,0,.004),1,.008,rubber);o.scale.x=.0315;o.scale.y=.0615;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)

def bounds():
 objs=[o for o in bpy.context.scene.objects if o.type=='MESH'];points=[o.matrix_world@Vector(c) for o in objs for c in o.bound_box];return objs,[[min(p[i] for p in points) for i in range(3)],[max(p[i] for p in points) for i in range(3)]]
def render(name,arrangement=False):
 global LOD
 LOD=0
 objs,bb=bounds();mn,mx=map(Vector,bb);center=(mn+mx)/2;size=max(mx-mn)
 stage=material('Render only warm neutral desk',(.38,.32,.23),0,.8)
 box('Render stage',(0,0,-.012),(3,3,.020),stage,.002)
 # Front slightly above: same side as the user's photograph, clutter omitted.
 offset=Vector((.15,-1.9,1.10)) if arrangement else Vector((-.48 if name=='photo_mouse' else .48,-1.3,.86))
 bpy.ops.object.camera_add(location=center+offset*size*1.45);cam=bpy.context.object;cam.rotation_euler=(center-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='PERSP';cam.data.lens=50;bpy.context.scene.camera=cam
 for pos,power,radius in [((-.65,-.8,1.5),140,1.1),((1,.3,1),90,1.0),((-.5,.8,.6),65,.7)]:
  bpy.ops.object.light_add(type='AREA',location=center+Vector(pos)*max(size,.3));o=bpy.context.object;o.data.energy=power*max(size,.3)**2;o.data.shape='DISK';o.data.size=radius*max(size,.3);o.rotation_euler=(center-o.location).to_track_quat('-Z','Y').to_euler()
 sc=bpy.context.scene;sc.world=bpy.data.worlds.new('Neutral studio');sc.world.color=(.20,.20,.20);sc.render.engine='CYCLES';sc.cycles.device='CPU';sc.cycles.samples=80;sc.cycles.use_denoising=False;sc.render.resolution_x=1100;sc.render.resolution_y=850;sc.render.resolution_percentage=100;sc.view_settings.view_transform='AgX';sc.view_settings.exposure=-1;sc.render.image_settings.file_format='PNG';sc.render.filepath=str(REVIEW/(name+'.png'));bpy.ops.render.render(write_still=True)

def mesh(name,vs,fs,mat):
 me=bpy.data.meshes.new(name);me.from_pydata(vs,[],fs);me.update();o=bpy.data.objects.new(name,me);bpy.context.collection.objects.link(o);finish(o,name,mat);return o
# Cross-sections independently estimated from official top and side photographs.
profile=[(-.0625,.022,.019),(-.060,.026,.020),(-.055,.029,.023),(-.045,.030,.028),(-.030,.031,.034),(-.010,.030,.039),(.008,.0305,.040),(.025,.03175,.0375),(.040,.030,.031),(.052,.024,.020),(.059,.014,.010),(.0625,.001,.006)]
def interp(y,col):
 if col==1 and y>.025:return max(.0001,.03175*math.sqrt(max(0,1-((y-.025)/.0375)**2)))
 if col==1 and y<-.045:return max(.0001,.030*math.sqrt(max(0,1-((y+.045)/.0175)**2)))
 slopes=[(profile[k+1][col]-profile[k][col])/(profile[k+1][0]-profile[k][0]) for k in range(len(profile)-1)]
 def tangent(k):
  if k==0:return slopes[0]
  if k==len(profile)-1:return slopes[-1]
  a,b=slopes[k-1],slopes[k]
  return 0 if a*b<=0 else 2*a*b/(a+b)
 for j in range(len(profile)-1):
  if y<=profile[j+1][0]:
   p0,p1=profile[j],profile[j+1];h=p1[0]-p0[0];t=max(0,min(1,(y-p0[0])/h))
   return (2*t**3-3*t*t+1)*p0[col]+(t**3-2*t*t+t)*h*tangent(j)+(-2*t**3+3*t*t)*p1[col]+(t**3-t*t)*h*tangent(j+1)
 return profile[-1][col]
def surface(x,y):
 w=interp(y,1);h=interp(y,2);q=min(1,abs(x)/max(w,1e-6));return .005+(h-.005)*(max(0,1-q*q)**.42)
def mouse():
 # GPX family silhouette. No logo or generation-specific charging port is guessed.
 ny=[72,42,24][LOD];nx=[40,24,14][LOD];vs=[];fs=[]
 for j in range(ny+1):
  y=-.0625+.125*(1-math.cos(math.pi*j/ny))/2;w=interp(y,1)
  for i in range(nx+1):
   t=-math.pi/2+math.pi*i/nx;x=w*math.sin(t);vs.append((x,y,surface(x,y)))
 for j in range(ny):
  for i in range(nx):a=j*(nx+1)+i;fs.append((a,a+1,a+nx+2,a+nx+1))
 # Close shell underneath, endcaps kept finite width to avoid pole degeneracy.
 edge=[j*(nx+1) for j in range(ny+1)]+[ny*(nx+1)+i for i in range(1,nx+1)]+[j*(nx+1)+nx for j in range(ny-1,-1,-1)]+[i for i in range(nx-1,0,-1)]
 lower=[]
 for ind in edge:lower.append(len(vs));x,y,z=vs[ind];vs.append((x*.96,y+.004*max(0,1-(y+.0625)/.008),.0025))
 for k,ind in enumerate(edge):fs.append((ind,lower[k],lower[(k+1)%len(edge)],edge[(k+1)%len(edge)]))
 fs.append(tuple(lower[::-1]));body=mesh('Mouse body GPX continuous rounded back',vs,fs,ivory)
 gradient=material('Photo coral rear gradient on GPX shaped shell',(1,1,1),0,.40);body.data.materials.clear();body.data.materials.append(gradient)
 attr=body.data.color_attributes.new(name='PhotoCandidateColor',type='FLOAT_COLOR',domain='POINT')
 for i,v in enumerate(body.data.vertices):
  f=max(0,min(1,(v.co.y+.008)/.065));f=f*f*(3-2*f);attr.data[i].color=tuple((1-f)*a+f*b for a,b in zip((.84,.84,.77),(.95,.12,.08)))+(1,)
 node=gradient.node_tree.nodes.new('ShaderNodeVertexColor');node.layer_name=attr.name;gradient.node_tree.links.new(node.outputs['Color'],gradient.node_tree.nodes.get('Principled BSDF').inputs['Base Color'])
 # Separate button skins and narrow molded seams; no intersecting underlay sheet.
 def seam(name,points):
  c=bpy.data.curves.new(name,'CURVE');c.dimensions='3D';c.bevel_depth=.00022;c.bevel_resolution=2 if LOD==0 else 1;c.resolution_u=1
  sp=c.splines.new('POLY');sp.points.add(len(points)-1)
  for p,co in zip(sp.points,points):p.co=(*co,1)
  o=bpy.data.objects.new(name,c);bpy.context.collection.objects.link(o);c.materials.append(black);bpy.context.view_layer.objects.active=o;o.select_set(True);bpy.ops.object.convert(target='MESH');o.select_set(False)
 for side,label in [(-1,'Left click'),(1,'Right click')]:
  n=[100,60,32][LOD];m=[26,16,10][LOD];ps=[];faces=[]
  for j in range(n+1):
   y=-.0625+.0545*j/n;w=interp(y,1)*.92
   for i in range(m+1):
    center=min(.00065,w*.20)
    # Smooth rounded wheel slot, independently visible from top and side.
    if -.050<y<-.026:
     d=abs(y+.038);q=max(0,(d-.008)/.004);center+=.0042*math.sqrt(max(0,1-q*q))
    x=side*(center+(max(w,center+.00001)-center)*i/m);ps.append((x,y,surface(x,y)+.0009))
  for j in range(n):
   for i in range(m):a=j*(m+1)+i;faces.append((a,a+1,a+m+2,a+m+1) if side>0 else (a,a+m+1,a+m+2,a+1))
  mesh(label+' panel',ps,faces,ivory)
  # Only side/back/center boundaries are black; nose remains a continuous cap.
  for suffix,ids in [('outer', [j*(m+1)+m for j in range(5,n+1)]),('rear',[n*(m+1)+i for i in range(m+1)]),('center',[j*(m+1) for j in range(n+1)])]:
   seam(label+' '+suffix+' seam',[(ps[k][0],ps[k][1],ps[k][2]+.00015) for k in ids])
 # Visible recessed seam under the front button lips; no guessed charging socket.
 front=[]
 for j in range(33 if LOD==0 else 17):
  x=-.019+.038*j/(32 if LOD==0 else 16);y=-.045-.0175*math.sqrt(max(0,1-(x/.030)**2))+.0005;front.append((x,y,surface(x,y)-.0018))
 seam('Front recessed button separation',front)
 cyl('Scroll wheel',(0,-.038,.028),.009,.006,rubber,'X')
 if LOD<2:
  for j in range(32 if LOD==0 else 16):
   a=math.tau*j/(32 if LOD==0 else 16);o=box('Fine wheel tread',(0,-.038+.009*math.sin(a),.028+.009*math.cos(a)),(.006,.0005,.0005),rubber,.00015)
 for y,slope in [(-.015,.15),(.006,-.06)]:
  count=[32,20,12][LOD];vs=[]
  for depth in [-.0005,.0015]:
   for j in range(count):
    a=math.tau*j/count;yy=y+(.0065 if math.cos(a)>=0 else -.0065)+.0025*math.cos(a);z=.024+.0025*math.sin(a)+slope*(yy-y)
    vs.append((interp(yy,1)+depth,yy,z))
  fs=[tuple(range(count-1,-1,-1)),tuple(range(count,2*count))]
  fs += [(j,(j+1)%count,(j+1)%count+count,j+count) for j in range(count)]
  mesh('Curved capsule left side button',vs,fs,coral)
 # Thin flat inset base, not a tall oval pedestal.
 ps=[]
 for j in range(ny+1):
  y=-.061+.122*j/ny;ps.append((-interp(y,1)*.95,y))
 ps+= [(interp(.061-.122*j/ny,1)*.95,.061-.122*j/ny) for j in range(ny+1)]
 polygon('Thin inset black base',ps,.0025,rubber,0)


# New independent revision: no frozen source is modified. Exact common envelope
# is maintained after the surface/detail changes, not normalized in the viewer.
def bounds():
 pts=[o.matrix_world@v.co for o in bpy.context.scene.objects if o.type=='MESH' for v in o.data.vertices]
 return [[min(v[i] for v in pts) for i in range(3)],[max(v[i] for v in pts) for i in range(3)]]
records=[]
for LOD in range(3):
 bpy.ops.wm.read_factory_settings(use_empty=True);bpy.context.preferences.filepaths.save_version=0;bpy.context.scene.unit_settings.system='METRIC';palette();mouse();bpy.context.view_layer.update()
 # Bake object matrices, normalize only sub-millimetre detail overshoot.
 for o in bpy.context.scene.objects:
  if o.type=='MESH':
   m=o.matrix_world.copy();o.data.transform(m);o.matrix_world.identity()
 lo,hi=bounds();target=(.0635,.125,.040)
 for o in bpy.context.scene.objects:
  if o.type=='MESH':
   for v in o.data.vertices:
    for i in range(3):v.co[i]=(v.co[i]-lo[i])/(hi[i]-lo[i])*target[i]-(target[i]/2 if i<2 else 0)
   # Panel skins intentionally remain surfaces; recalculate consistent winding.
   bpy.context.view_layer.objects.active=o;o.select_set(True);bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.mesh.normals_make_consistent(inside=False);bpy.ops.object.mode_set(mode='OBJECT');o.select_set(False)
 bpy.context.view_layer.update();folder=OUT/'photo_mouse';folder.mkdir(parents=True,exist_ok=True)
 path=folder/f'lod{LOD}_source.glb';bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',export_extras=True,export_yup=True)
 if LOD==0:bpy.ops.wm.save_as_mainfile(filepath=str(folder/'photo_mouse.blend'))
 objs=[o for o in bpy.context.scene.objects if o.type=='MESH'];lo,hi=bounds();records.append({'level':LOD,'sizeBlenderXYZ':[hi[i]-lo[i] for i in range(3)],'triangles':sum(len(p.vertices)-2 for o in objs for p in o.data.polygons),'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
(REVIEW/'build_report.json').write_text(json.dumps({'revision':'Rounded GPX-family nose/tail, rounded wheel slot, curved side buttons','units':'metres','frontBlender':'-Y','frontGltf':'+Z','records':records},indent=2))
if '--render' in sys.argv:
 bpy.ops.wm.open_mainfile(filepath=str(OUT/'photo_mouse/photo_mouse.blend'));LOD=0
 render('photo_mouse')
