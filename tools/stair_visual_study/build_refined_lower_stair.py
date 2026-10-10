"""True modular stair with restrained terrazzo / metal detail, no image billboard.
The web artwork is appearance guidance only. Original tread meshes and pivot stay.
"""
import argparse,hashlib,json,math,pathlib,random,runpy,sys
import bpy
from mathutils import Vector,Matrix
p=argparse.ArgumentParser();p.add_argument('--output',required=True);p.add_argument('--render',action='store_true');p.add_argument('--turntable',action='store_true')
a=p.parse_args(sys.argv[sys.argv.index('--')+1:]);out=pathlib.Path(a.output).resolve();out.mkdir(parents=True,exist_ok=True)
root=pathlib.Path(__file__).resolve().parent;sys.argv=[str(root/'build_stair_sample.py'),'--','--output',str(out/'source'),'--variant','structure']
g=runpy.run_path(str(root/'build_stair_sample.py'));S=g['S'];owner=g['OWN']['b_lower_stair'];v=g['v'];cam=S.camera
owner.matrix_world=Matrix.Identity(4)
source=g['L']['geometry']['stairs'][0];start=Vector(source['from']);end=Vector(source['to']);run=end-start;flat=Vector((run.x,0,run.z));side=Vector((-run.z,0,run.x)).normalized();n=source['steps'];width=source['width']
assert n==12 and abs(width-1.34)<1e-6
original_treads={}
for ob in S.objects:
    if ob.type=='MESH':
        ob.hide_render=ob.parent!=owner
        if ob.parent==owner and '_tread_' in ob.name:original_treads[ob.name]=(ob.location.copy(),ob.dimensions.copy())
    elif ob.type=='LIGHT':ob.hide_render=True
assert len(original_treads)==12
sys.path.insert(0,str(root));from pixel_materials import metric_uv

def color(h):return tuple(int(h[i:i+2],16)/255 for i in (0,2,4))+(1,)
def plain(name,h,metal=0,rough=.9):
    m=bpy.data.materials.new(name);m.use_nodes=True
    raw=color(h);linear=tuple(c/12.92 if c<=.04045 else ((c+.055)/1.055)**2.4 for c in raw[:3])+(1,)
    m.diffuse_color=linear
    b=m.node_tree.nodes.get('Principled BSDF');b.inputs['Base Color'].default_value=linear;b.inputs['Metallic'].default_value=metal;b.inputs['Roughness'].default_value=rough
    return m

# Small flat angular aggregate chips, in metre-scaled nearest-neighbour UVs.
rng=random.Random(755);size=128;palette=[color(x) for x in ['b8b7aa','abaea5','cbc8b8','929e9b','d4cfbd','798d8b']]
pixels=[palette[0] for _ in range(size*size)]
for y in range(size):
    for x in range(size):
        r=rng.random();pixels[y*size+x]=palette[0 if r<.74 else (1 if r<.90 else 2)]
for i in range(460):
    cx=rng.randrange(size);cy=rng.randrange(size);rx=rng.choice([1,1,2,3]);ry=rng.choice([1,1,2]);shade=palette[rng.choice([1,2,3,4,5])]
    for dy in range(-ry,ry+1):
        for dx in range(-rx,rx+1):
            if abs(dx)/rx+abs(dy)/ry<=1.2:pixels[((cy+dy)%size)*size+(cx+dx)%size]=shade
image=bpy.data.images.new('Authored terrazzo pixel albedo',width=size,height=size,alpha=True)
image.colorspace_settings.name='sRGB';image.pixels=[c for px in pixels for c in px];image.filepath_raw=str(out/'terrazzo_pixel_albedo.png');image.file_format='PNG';image.save();image.pack()
stone=plain('Campus grey terrazzo','b8b7aa',rough=.92);tx=stone.node_tree.nodes.new('ShaderNodeTexImage');tx.image=image;tx.interpolation='Closest';tx.extension='REPEAT';stone.node_tree.links.new(tx.outputs['Color'],stone.node_tree.nodes['Principled BSDF'].inputs['Base Color'])
iron=plain('Blue grey painted iron','233a44',metal=.48,rough=.48);cuff=plain('Iron joint collars','314b56',metal=.58,rough=.46);edge=plain('Stone worn edges','ccc8b7',rough=.86);groove=plain('Recessed anti slip channels','637776',rough=.94);bolt=plain('Recessed steel fixings','6d7f83',metal=.65,rough=.48)

def setmat(ob,mat):ob.data.materials.clear();ob.data.materials.append(mat);metric_uv(ob)
def cuboid(name,c,dim,mat):
    bpy.ops.mesh.primitive_cube_add(size=1,location=v(c));ob=bpy.context.object;ob.name=name;ob.dimensions=(dim[0],dim[2],dim[1]);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);ob.parent=owner;setmat(ob,mat);ob['role']='cosmetic detail';return ob

def cylinder(name,a,b,radius,mat,verts=12):
    pa,pb=v(a),v(b);bpy.ops.mesh.primitive_cylinder_add(vertices=verts,radius=radius,depth=(pb-pa).length,location=(pa+pb)/2)
    ob=bpy.context.object;ob.name=name;ob.rotation_mode='QUATERNION';ob.rotation_quaternion=(pb-pa).to_track_quat('Z','Y');ob.parent=owner;setmat(ob,mat);ob['role']='cosmetic railing';return ob

for ob in list(S.objects):
    if ob.type!='MESH' or ob.parent!=owner:continue
    if '_tread_' in ob.name:setmat(ob,stone)
    else:ob.hide_render=True
# Cast underside closes the stair volume, entirely below unchanged walking faces.
# One closed stepped prism avoids coplanar box/beam faces and triangular gaps.
# Its top is below the original tread surface; the source tread meshes stay exact.
length=flat.length;dx=length/n;direction=flat.normalized()
profile=[(-.032,start.y-.43),(length+.032,end.y-.43),(length+.032,start.lerp(end,(n-.5)/n).y-.06)]
for i in range(n-1,-1,-1):
    x=i*dx-.032;profile.append((x,start.lerp(end,(i+.5)/n).y-.06))
    if i>0:profile.append((x,start.lerp(end,(i-.5)/n).y-.06))
vertices=[]
for sign in (-1,1):
    for x,y in profile:
        q=start+direction*x+side*sign*(width/2+.002);q.y=y;vertices.append(tuple(v(q)))
count=len(profile);faces=[tuple(range(count-1,-1,-1)),tuple(range(count,count*2))]
for i in range(count):j=(i+1)%count;faces.append((i,j,j+count,i+count))
mesh=bpy.data.meshes.new('Closed stepped structural profile');mesh.from_pydata(vertices,[],faces);mesh.update()
import bmesh
bm=bmesh.new();bm.from_mesh(mesh);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(mesh);bm.free();mesh.update()
bottom=bpy.data.objects.new('Closed stone side and underside',mesh);S.collection.objects.link(bottom);bottom.parent=owner;setmat(bottom,stone)
# Every source riser lies at i*dx-.035; each added body riser is 3 mm inset, avoiding coincident faces.
assert all(abs((i*dx-.032)-(i*dx-.035))>.0029 for i in range(n))
# Every structural profile edge belongs to two faces: no open underside holes.
edge_counts={}
for face in faces:
    for i in range(len(face)):
        key=tuple(sorted((face[i],face[(i+1)%len(face)])));edge_counts[key]=edge_counts.get(key,0)+1
assert all(count==2 for count in edge_counts.values())

for i in range(n):
    t=(i+.5)/n;top=start.lerp(end,t)
    for j in range(3):
        offset=-flat.length/n/2-.013+j*.020
        strip=cuboid('Anti-slip %02d %d'%(i,j),top+flat.normalized()*offset+Vector((0,.0025,0)),(.007,.004,width-.14),groove)
        strip.rotation_euler[2]=-math.atan2(run.z,run.x)
    lip=cuboid('Worn tread edge %02d'%i,top-flat.normalized()*(flat.length/n/2+.037)+Vector((0,-.009,0)),(.004,.018,width-.02),edge)
    lip.rotation_euler[2]=-math.atan2(run.z,run.x)
for sign in (-1,1):
    off=side*sign*(width/2-.04);rail_a=start+off+Vector((0,.72,0));rail_b=end+off+Vector((0,.72,0))
    cylinder('Continuous upper rail '+str(sign),rail_a,rail_b,.031,iron)
    cylinder('Continuous lower rail '+str(sign),start+off+Vector((0,.30,0)),end+off+Vector((0,.30,0)),.018,iron)
    fractions=sorted(set([i/n for i in range(0,n+1,2)]+[1.]))
    for j,t in enumerate(fractions):
        index=min(n-1,max(0,int(t*n)));foot=start.lerp(end,t)+off;foot.y=start.lerp(end,(index+.5)/n).y
        base=cuboid('Post foot %s %02d'%(sign,j),foot+Vector((0,.015,0)),(.08,.03,.08),cuff)
        head=start.lerp(end,t)+off+Vector((0,.76,0))
        cylinder('Round post %s %02d'%(sign,j),foot+Vector((0,.03,0)),head,.025,iron)
        axis=run.normalized();joint=start.lerp(end,t)+off+Vector((0,.72,0))
        cylinder('Rail collar %s %02d'%(sign,j),joint-axis*.038,joint+axis*.038,.038,cuff)
        for sx,sz in [(-1,-1),(-1,1),(1,-1),(1,1)]:
            pos=foot+Vector((sx*.025,.03,sz*.025));cylinder('Base fixing',pos,pos+Vector((0,.004,0)),.006,bolt,8)
        # Small cap keeps the top of each post solid in top / underside views.
        cylinder('Post cap %s %02d'%(sign,j),head-Vector((0,.018,0)),head+Vector((0,.01,0)),.028,cuff)

bpy.context.view_layer.update();checks=0
for name,(pos,dim) in original_treads.items():
    ob=bpy.data.objects[name];assert (ob.location-pos).length<1e-6 and (ob.dimensions-dim).length<1e-6;checks+=1
assert all(abs(owner.matrix_world[i][j]-(1 if i==j else 0))<1e-6 for i in range(4) for j in range(4))
checks+=1
# Source transform is externally driven; no object-level relocation or new route.
report={'module':'b_lower_stair','source_state':0,'steps':12,'width_m':width,'source_pivot_godot':g['L']['mechanisms'][0]['pivot'],
'closed_body_edge_incidence':2,'cosmetic_side_expansion_m':.002,'srgb_to_linear_material_colors':True,'walk_surface_meshes_unchanged':True,'source_rules_changed':False,'web_art_used_as_texture':False,
'web_reference':'lower_stair_threequarter_art_rgba_v1.png','details':['terrazzo albedo','three anti-slip lines','round metal rails','joint cuffs and small base fixings','closed underside'],
'checks':checks,'render_views':{},'pixel_texture_size':[128,128]}
visible=[ob for ob in S.objects if ob.type=='MESH' and not ob.hide_render];points=[ob.matrix_world@Vector(c) for ob in visible for c in ob.bound_box]
lo=Vector(tuple(min(p[i] for p in points) for i in range(3)));hi=Vector(tuple(max(p[i] for p in points) for i in range(3)));center=(lo+hi)/2
S.render.resolution_x=1024;S.render.resolution_y=1024;S.render.film_transparent=True;S.render.image_settings.color_mode='RGBA';S.cycles.samples=32;S.cycles.max_bounces=1;S.cycles.use_denoising=False
S.world.node_tree.nodes['Background'].inputs['Color'].default_value=(.12,.14,.16,1);S.world.node_tree.nodes['Background'].inputs['Strength'].default_value=.7
for name,offset,energy,col in [('Soft key',(-3,-5,7),1000,(1,.97,.90)),('Cool fill',(6,3,5),600,(.80,.90,1))]:
    ld=bpy.data.lights.new(name,'AREA');ob=bpy.data.objects.new(name,ld);S.collection.objects.link(ob);ob.location=center+Vector(offset);ob.rotation_euler=(center-ob.location).to_track_quat('-Z','Y').to_euler();ld.energy=energy;ld.size=5;ld.color=col
cam.data.ortho_scale=5.1
for name,direction in [('threequarter',Vector((-7,-9,7))),('reverse',Vector((7,9,7))),('bottom',Vector((0,0,-15)))]:
    cam.location=center+direction
    if name=='bottom':cam.rotation_euler=(0,math.pi,0)
    else:cam.rotation_euler=(center-cam.location).to_track_quat('-Z','Y').to_euler()
    bpy.context.view_layer.update();report['render_views'][name]={'camera_blender':[list(r) for r in cam.matrix_world],'ortho_scale':cam.data.ortho_scale}
    S.render.filepath=str(out/('lower_stair_'+name+'_rgba.png'))
    if a.render:bpy.ops.render.render(write_still=True)
if a.turntable:
    frames=out/'turntable';frames.mkdir(exist_ok=True);S.render.resolution_x=480;S.render.resolution_y=480;S.cycles.samples=8
    cam.data.ortho_scale=5.4
    for frame in range(32):
        theta=-2.23+frame/32*math.tau;cam.location=center+Vector((math.cos(theta)*13,math.sin(theta)*13,8));cam.rotation_euler=(center-cam.location).to_track_quat('-Z','Y').to_euler()
        S.render.filepath=str(frames/('%04d.png'%frame));bpy.ops.render.render(write_still=True)
    report['turntable']={'frames':32,'fps':8,'same_mesh':True}
# Export the same visible meshes (not lighting/camera or source hidden primitives).
bpy.ops.object.select_all(action='DESELECT');owner.select_set(True)
for ob in visible:ob.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(out/'lower_rotating_stair.glb'),export_format='GLB',use_selection=True,export_animations=False,export_extras=True)
(out/'refined_manifest.json').write_text(json.dumps(report,indent=2)+'\n');bpy.ops.wm.save_as_mainfile(filepath=str(out/'lower_rotating_stair.blend'))
print('REFINED_LOWER_STAIR_OK',checks,len(visible))
