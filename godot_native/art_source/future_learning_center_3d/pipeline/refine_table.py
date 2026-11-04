"""Local manufacturing cleanup of one approved Hi3D prototype; no provider call.
Blender --background --factory-startup --python pipeline/refine_table.py
Keeps generated caster/frame geometry. Replaces the wavy AI tabletop with a
flat rounded manufactured board. Moves end assemblies rigidly for width variants.
"""
import bpy,bmesh,hashlib,json,math
from pathlib import Path
root=Path(__file__).resolve().parents[1]
source=root/'web/assets/models/hi3d/mobile_exhibition_table/lod0.glb'
out=root/'sources/models/hi3d/mobile_exhibition_table/local_edits';out.mkdir(exist_ok=True)
receipt={'source':str(source.relative_to(root)),'sourceSha256':hashlib.sha256(source.read_bytes()).hexdigest(),'operations':['bisect generated tabletop at0.95m','flat rounded board with1.5mm bevel; top1.00m','satin metal material on support faces above0.17m','rigid end-assembly shifts for width variants; caster size unchanged'],'variants':[]}
for code,width,depth in [('150',1.50,.65),('135',1.35,.60),('125',1.25,.60),('120',1.20,.60)]:
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
 bpy.ops.import_scene.gltf(filepath=str(source))
 objects=[o for o in bpy.context.scene.objects if o.type=='MESH']
 steel=bpy.data.materials.new('Satin steel supports');steel.diffuse_color=(.48,.52,.54,1);steel.use_nodes=True
 bs=steel.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=(.48,.52,.54,1);bs.inputs['Metallic'].default_value=.88;bs.inputs['Roughness'].default_value=.34
 for ob in objects:
  bpy.ops.object.select_all(action='DESELECT');ob.select_set(True);bpy.context.view_layer.objects.active=ob;bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
  bm=bmesh.new();bm.from_mesh(ob.data);bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),plane_co=(0,0,.95),plane_no=(0,0,1),clear_outer=True,clear_inner=False)
  idx=len(ob.data.materials);ob.data.materials.append(steel)
  for f in bm.faces:
   if f.calc_center_median().z>.17:f.material_index=idx
  for v in bm.verts:
   x=v.co.x;v.co.x+=math.copysign(1,x)*(width-1.533610564)/2*min(1,abs(x)/.35)
  bm.to_mesh(ob.data);bm.free();ob.data.update()
 # Rounded rectangle slab, top at1m and underside at0.945m.
 radius=.13;n=12;loop=[]
 for cx,cy,start in [(width/2-radius,depth/2-radius,0),(-width/2+radius,depth/2-radius,90),(-width/2+radius,-depth/2+radius,180),(width/2-radius,-depth/2+radius,270)]:
  for k in range(n+1):
   a=math.radians(start+90*k/n);loop.append((cx+radius*math.cos(a),cy+radius*math.sin(a)))
 count=len(loop);verts=[(x,y,z) for z in [.945,1.] for x,y in loop]
 faces=[tuple(reversed(range(count))),tuple(range(count,count*2))]+[(i,(i+1)%count,(i+1)%count+count,i+count) for i in range(count)]
 mesh=bpy.data.meshes.new('Manufactured flat ash board');mesh.from_pydata(verts,[],faces);mesh.update();ob=bpy.data.objects.new('Rounded flat tabletop',mesh);bpy.context.scene.collection.objects.link(ob)
 wood=bpy.data.materials.new('Pale ash tabletop');wood.diffuse_color=(.67,.58,.40,1);wood.use_nodes=True;bs=wood.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=(.67,.58,.40,1);bs.inputs['Roughness'].default_value=.54;ob.data.materials.append(wood)
 bpy.context.view_layer.objects.active=ob;ob.select_set(True);bevel=ob.modifiers.new('Manufactured edge radius1.5mm','BEVEL');bevel.width=.0015;bevel.segments=3;bpy.ops.object.modifier_apply(modifier=bevel.name)
 bpy.ops.object.select_all(action='SELECT')
 dest=out/f'table_{code}.glb';bpy.ops.export_scene.gltf(filepath=str(dest),export_format='GLB',export_extras=True,export_yup=True)
 receipt['variants'].append({'widthCode':code,'widthM':width,'tabletopDepthM':depth,'file':str(dest.relative_to(root)),'sha256':hashlib.sha256(dest.read_bytes()).hexdigest(),'bytes':dest.stat().st_size})
(out/'edit_receipt.json').write_text(json.dumps(receipt,indent=2)+'\n')
