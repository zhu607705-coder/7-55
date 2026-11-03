"""GPX proportion shell and photo keyboard island revision; original unrelated models preserved."""
from pathlib import Path
helper=Path(__file__).with_name('build_photo_desktop.py')
exec(compile(helper.read_text().split("assets=[('photo_monitor_stand'")[0],str(helper),'exec'))
# Reuse the photo keycaps, correct the main/right navigation clearance to 6 mm.
old_keyboard=keyboard
keyboard_code=helper.read_text().split('def keyboard():',1)[1].split('def mouse():',1)[0]
keyboard_code=keyboard_code.replace('pitch=.0215','pitch=.022').replace("for j in range(16):key('function %02d'%j,left+j*.0215,y,.017,mint if j==0 else yellow if j==14 else coral if j==15 else keywhite)","for j in range(14):key('function %02d'%j,left+j*.022,y,.017,mint if j==0 else keywhite)\n   key('separated yellow',.143,y,.017,yellow);key('separated coral',.166,y,.017,coral)")
keyboard_code=keyboard_code.replace("box('Keyboard recessed dark deck',(0,.001,.023),(.355,.132,.004),black,.005)","box('Main recessed deck',(-.012,.001,.023),(.334,.132,.004),black,.003)\n box('Separated right navigation deck',(.166,.001,.023),(.022,.132,.004),black,.002)\n box('Six mm navigation separator',(.154,.001,.024),(.006,.132,.004),ivory,.001)")
exec(compile('def keyboard():'+keyboard_code,str(helper),'exec'))

def mesh(name,vs,fs,mat):
 me=bpy.data.meshes.new(name);me.from_pydata(vs,[],fs);me.update();o=bpy.data.objects.new(name,me);bpy.context.collection.objects.link(o);finish(o,name,mat);return o
# Cross-sections independently estimated from official top and side photographs.
profile=[(-.0625,.022,.019),(-.060,.026,.020),(-.055,.029,.023),(-.045,.030,.028),(-.030,.031,.034),(-.010,.030,.039),(.008,.0305,.040),(.025,.03175,.0375),(.040,.030,.031),(.052,.024,.020),(.059,.014,.010),(.0625,.001,.006)]
def interp(y,col):
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
  y=-.0625+.125*j/ny;w=interp(y,1)
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
  n=[40,26,16][LOD];m=[22,14,10][LOD];ps=[];faces=[]
  for j in range(n+1):
   y=-.0625+.0545*j/n;w=interp(y,1)*.92
   for i in range(m+1):
    center=.00065
    # Smooth rounded wheel slot, independently visible from top and side.
    if -.050<y<-.026:
     q=min((y+.050)/.003,(-.026-y)/.003,1);center+=.0042*math.sin(max(0,q)*math.pi/2)
    x=side*(center+(max(w,center+.0002)-center)*i/m);ps.append((x,y,surface(x,y)+.0009))
  for j in range(n):
   for i in range(m):a=j*(m+1)+i;faces.append((a,a+1,a+m+2,a+m+1) if side>0 else (a,a+m+1,a+m+2,a+1))
  mesh(label+' panel',ps,faces,ivory)
  # Only side/back/center boundaries are black; nose remains a continuous cap.
  for suffix,ids in [('outer', [j*(m+1)+m for j in range(5,n+1)]),('rear',[n*(m+1)+i for i in range(m+1)]),('center',[j*(m+1) for j in range(n+1)])]:
   seam(label+' '+suffix+' seam',[(ps[k][0],ps[k][1],ps[k][2]+.00015) for k in ids])
 # Visible recessed seam under the front button lips; no guessed charging socket.
 front=[]
 for j in range(33 if LOD==0 else 17):
  x=-.019+.038*j/(32 if LOD==0 else 16);front.append((x,-.06215,surface(x,-.0625)-.0018))
 seam('Front recessed button separation',front)
 cyl('Scroll wheel',(0,-.038,.028),.009,.006,rubber,'X')
 if LOD<2:
  for j in range(32 if LOD==0 else 16):
   a=math.tau*j/(32 if LOD==0 else 16);o=box('Fine wheel tread',(0,-.038+.009*math.sin(a),.028+.009*math.cos(a)),(.006,.0005,.0005),rubber,.00015)
 for y in [-.015,.006]:
  x=interp(y,1)-.0003;o=box('Side button left only',(x,y,.024),(.0017,.016,.0047),coral,.0013)
 # Thin flat inset base, not a tall oval pedestal.
 ps=[]
 for j in range(ny+1):
  y=-.061+.122*j/ny;ps.append((-interp(y,1)*.95,y))
 ps+= [(interp(.061-.122*j/ny,1)*.95,.061-.122*j/ny) for j in range(ny+1)]
 polygon('Thin inset black base',ps,.0025,rubber,0)

def realbounds():
 objs=[o for o in bpy.context.scene.objects if o.type=='MESH'];pts=[o.matrix_world@v.co for o in objs for v in o.data.vertices];return objs,[[min(p[i] for p in pts) for i in range(3)],[max(p[i] for p in pts) for i in range(3)]]
# Mouse nose points toward -Y, so anatomical left is +X when viewed from behind.
render_input_source=helper.read_text().split('def render(name,arrangement=False):',1)[1].split("assets=[('photo_monitor_stand'",1)[0]
exec(compile('def render_input(name,arrangement=False):'+render_input_source.replace("-.48 if name=='photo_mouse' else .48",".48"),str(helper),'exec'))
records=[]
if '--render-only' not in sys.argv:
 for asset,build in [('photo_keyboard',keyboard),('photo_mouse',mouse)]:
  if '--asset=photo_mouse' in sys.argv and asset!='photo_mouse':continue
  for LOD in range(3):
   bpy.ops.wm.read_factory_settings(use_empty=True);bpy.context.preferences.filepaths.save_version=0;bpy.context.scene.unit_settings.system='METRIC';palette();build();bpy.context.view_layer.update();objs,bb=realbounds();folder=OUT/asset;p=folder/f'lod{LOD}_source.glb'
   bpy.ops.export_scene.gltf(filepath=str(p),export_format='GLB',export_extras=True,export_yup=True)
   records.append({'asset':asset,'level':LOD,'triangles':sum(len(p.vertices)-2 for o in objs for p in o.data.polygons),'boundsBlenderXYZ':bb,'sizeBlenderXYZ':[bb[1][i]-bb[0][i] for i in range(3)],'meshParts':len(objs),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
   if LOD==0:bpy.ops.wm.save_as_mainfile(filepath=str(folder/(asset+'.blend')))
 old=json.loads((REVIEW/'build_report.json').read_text());old['records']=[r for r in old['records'] if r['asset'] not in {x['asset'] for x in records}]+records;old['revision']='2026-11-03 GPX photo-profile shell and separated keyboard right island';(REVIEW/'build_report.json').write_text(json.dumps(old,indent=2))
if '--skip-render' not in sys.argv:
 for asset in ['photo_keyboard','photo_mouse']:
  if '--asset=photo_mouse' in sys.argv and asset!='photo_mouse':continue
  bpy.ops.wm.open_mainfile(filepath=str(OUT/asset/(asset+'.blend')));render_input(asset)
 # Dedicated orthographic side/top evidence is rendered, not a screenshot edit.
 for name,pos in ([] if '--skip-ortho' in sys.argv else [('photo_mouse_profile',(.25,0,.025)),('photo_mouse_top',(0,0,.28))]):
  bpy.ops.wm.open_mainfile(filepath=str(OUT/'photo_mouse/photo_mouse.blend'));LOD=0
  stage=material('Neutral stage',(.45,.45,.45),0,.8);box('Stage',(0,0,-.005),(.5,.5,.01),stage)
  bpy.ops.object.camera_add(location=pos);cam=bpy.context.object;cam.rotation_euler=(Vector((0,0,.020))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=.20;bpy.context.scene.camera=cam
  if name=='photo_mouse_top':cam.rotation_euler.z+=math.pi
  bpy.ops.object.light_add(type='AREA',location=(-.1,-.1,.3));bpy.context.object.data.energy=8;bpy.context.object.data.size=.3
  sc=bpy.context.scene;sc.render.engine='CYCLES';sc.cycles.samples=64;sc.cycles.use_denoising=False;sc.world=bpy.data.worlds.new('World');sc.world.color=(.3,.3,.3);sc.render.resolution_x=1100;sc.render.resolution_y=800;sc.render.resolution_percentage=100;sc.view_settings.view_transform='AgX';sc.render.filepath=str(REVIEW/(name+'.png'));bpy.ops.render.render(write_still=True)
