"""Source-sized closed lift and sliding platform modules for stair_b.
Run after build_refined_upper_stair.py; the --template blend supplies the exact
approved lower-v3 PBR materials. No gameplay, collision or route changes.
"""
import argparse, json, math, pathlib, sys
import bpy, bmesh
from mathutils import Vector, Matrix
p=argparse.ArgumentParser();p.add_argument('--output',required=True);p.add_argument('--template',required=True);p.add_argument('--render',action='store_true')
a=p.parse_args(sys.argv[sys.argv.index('--')+1:]);out=pathlib.Path(a.output).resolve();out.mkdir(parents=True,exist_ok=True)
root=pathlib.Path(__file__).resolve().parent;sys.path.insert(0,str(root));from pixel_materials import metric_uv
D=json.loads((root/'stair_b_snapshot.json').read_text());L=D['level']
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
S=bpy.context.scene;S.render.engine='CYCLES';S.cycles.device='CPU';S.cycles.samples=16;S.cycles.use_denoising=False;S.cycles.max_bounces=1
S.render.threads_mode='FIXED';S.render.threads=1;S.render.resolution_x=1024;S.render.resolution_y=1024;S.render.resolution_percentage=100
S.render.image_settings.file_format='PNG';S.render.image_settings.color_mode='RGBA';S.render.film_transparent=True
S.view_settings.view_transform='Standard';S.view_settings.look='Medium High Contrast';S.world.use_nodes=True
S.world.node_tree.nodes['Background'].inputs['Color'].default_value=(.12,.14,.16,1);S.world.node_tree.nodes['Background'].inputs['Strength'].default_value=.7
names=['Campus grey terrazzo','Blue grey painted iron','Iron joint collars','Recessed anti slip channels','Recessed steel fixings','Stone worn edges']
with bpy.data.libraries.load(str(pathlib.Path(a.template).resolve()),link=False) as (src,dst):
 assert all(n in src.materials for n in names);dst.materials=names.copy()
M=[bpy.data.materials[n] for n in names]
for m in M:
 for n in m.node_tree.nodes:
  if n.type=='TEX_IMAGE':
   assert n.interpolation=='Closest';n.image.pack();n.image.filepath_raw=str(out/'terrazzo_pixel_albedo.png');n.image.file_format='PNG';n.image.save()
def v(p):return Vector((p[0],-p[2],p[1]))
def closed_mesh(platform,owner):
 # One manifold mesh, exact source bounds. Surface strips are mesh faces at the
 # original walking height, never overlaid planes or raised collision edges.
 c=Vector(platform['center']);w,h,d=platform['size'];top=c.y+h/2;bottom=c.y-h/2;band=bottom+.14
 xs=[-w/2,-w/2+.07,w/2-.07,w/2]
 zs=[-d/2,d/2]
 for sign in (-1,1):
  for i in range(3):
   t=d/2-.055-i*.02;zs.extend([sign*(t-.0035),sign*(t+.0035)])
 zs=sorted(zs);verts=[];faces=[];mats=[];lookup={}
 def vertex(x,y,z):
  key=(round(x,8),round(y,8),round(z,8))
  if key not in lookup:lookup[key]=len(verts);verts.append(tuple(v(c+Vector((x,y-c.y,z)))))
  return lookup[key]
 def face(coords,mat):faces.append(tuple(vertex(*p) for p in coords));mats.append(mat)
 for i in range(len(xs)-1):
  for j in range(len(zs)-1):
   x0,x1=xs[i:i+2];z0,z1=zs[j:j+2];zmid=(z0+z1)/2
   groove=i==1 and any(abs(abs(zmid)-(d/2-.055-k*.02))<.0036 for k in range(3))
   face([(x0,top,z0),(x1,top,z0),(x1,top,z1),(x0,top,z1)],3 if groove else 0)
 # Matching perimeter segments ensure all top grid boundary edges are manifold.
 perimeter=[(x,-d/2) for x in xs]+[(w/2,z) for z in zs[1:]]+[(x,d/2) for x in xs[-2::-1]]+[(-w/2,z) for z in zs[-2:0:-1]]
 for i,(x0,z0) in enumerate(perimeter):
  x1,z1=perimeter[(i+1)%len(perimeter)]
  for y0,y1,mat in [(bottom,band,1),(band,top,0)]:
   face([(x0,y0,z0),(x1,y0,z1),(x1,y1,z1),(x0,y1,z0)],mat)
 face([(x,bottom,z) for x,z in reversed(perimeter)],1)
 mesh=bpy.data.meshes.new(platform['id']+'_closed');mesh.from_pydata(verts,[],faces);mesh.update()
 for m in M:mesh.materials.append(m)
 for f,mat in zip(mesh.polygons,mats):f.material_index=mat
 bm=bmesh.new();bm.from_mesh(mesh);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(mesh);bm.free();mesh.update()
 ob=bpy.data.objects.new(platform['id'],mesh);S.collection.objects.link(ob);ob.parent=owner;metric_uv(ob)
 ob['source_owner_id']=platform['ownerId'];ob['render_only']=True;ob['source_bounds_preserved']=True
 incidence={}
 for f in mesh.polygons:
  for edge in f.edge_keys:incidence[tuple(sorted(edge))]=incidence.get(tuple(sorted(edge)),0)+1
 assert all(n==2 for n in incidence.values()),'platform must be fully closed'
 bpy.context.view_layer.update()
 lo=Vector(tuple(min(co[i] for co in verts) for i in range(3)));hi=Vector(tuple(max(co[i] for co in verts) for i in range(3)))
 assert (lo-v((c.x-w/2,c.y-h/2,c.z+d/2))).length<1e-5
 assert (hi-v((c.x+w/2,c.y+h/2,c.z-d/2))).length<1e-5
 return ob,{'closed_edge_incidence':2,'bounds_blender_min':list(lo),'bounds_blender_max':list(hi),'faces':len(mesh.polygons),'vertices':len(mesh.vertices)}
camdata=bpy.data.cameras.new('Asset inspection');cam=bpy.data.objects.new('Asset inspection',camdata);S.collection.objects.link(cam);camdata.type='ORTHO';camdata.ortho_scale=3.8;S.camera=cam
lights=[]
for name,offset,energy,col in [('Soft key',(-3,-5,7),1000,(1,.97,.90)),('Cool fill',(6,3,5),600,(.80,.90,1))]:
 ld=bpy.data.lights.new(name,'AREA');ob=bpy.data.objects.new(name,ld);S.collection.objects.link(ob);ld.energy=energy;ld.size=5;ld.color=col;lights.append((ob,Vector(offset)))
reports=[]
for ownerid,asset in [('b_mid_lift','mid_lift_platform'),('b_exit_slide','exit_slide_platform')]:
 for o in S.objects:
  if o.type=='MESH':o.hide_render=True
 owner=bpy.data.objects.new(ownerid,None);S.collection.objects.link(owner);owner['source_owner_id']=ownerid;owner['gameplay_collision']='not_generated'
 source=next(p for p in L['geometry']['platforms'] if p['ownerId']==ownerid);mech=next(m for m in L['mechanisms'] if m['id']==ownerid)
 ob,geometry=closed_mesh(source,owner);center=v(source['center']);report={'module':ownerid,'source_state':0,'source_platform':source,'mechanism':mech,'source_snapshot_sha256':D['source_sha256'],'geometry':geometry,'world_coordinates_preserved':True,'owner_identity':True,'source_rules_changed':False,'collision_generated':False,'materials_reference':'approved lower stair v3 exact linked PBR','render_views':{}}
 for lamp,offset in lights:lamp.location=center+offset;lamp.rotation_euler=(center-lamp.location).to_track_quat('-Z','Y').to_euler()
 for name,direction in [('threequarter',Vector((-7,-9,7))),('reverse',Vector((7,9,7))),('bottom',Vector((0,0,-15)))]:
  cam.location=center+direction
  cam.rotation_euler=(0,math.pi,0) if name=='bottom' else (center-cam.location).to_track_quat('-Z','Y').to_euler()
  bpy.context.view_layer.update();report['render_views'][name]={'camera_blender':[list(r) for r in cam.matrix_world],'ortho_scale':cam.data.ortho_scale}
  S.render.filepath=str(out/(asset+'_'+name+'_rgba.png'))
  if a.render:bpy.ops.render.render(write_still=True)
 bpy.ops.object.select_all(action='DESELECT');owner.select_set(True);ob.select_set(True)
 bpy.ops.export_scene.gltf(filepath=str(out/(asset+'.glb')),export_format='GLB',use_selection=True,export_animations=False,export_extras=True)
 (out/(asset+'_manifest.json')).write_text(json.dumps(report,indent=2)+'\n');reports.append(report)
 bpy.ops.wm.save_as_mainfile(filepath=str(out/(asset+'.blend')))
(out/'platform_manifest.json').write_text(json.dumps(reports,indent=2)+'\n')
print('MOVING_PLATFORMS_OK',len(reports))
