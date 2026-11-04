"""Apply the shared floor material catalog to the live Blender scene or an existing source file."""
import bpy,json,hashlib
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]

def apply_floor_materials(root=ROOT):
 catalog=json.loads((root/'web/assets/floor_material_catalog.json').read_text());materials={}
 for id,profile in catalog['profiles'].items():
  name='FLC floor '+id;mat=bpy.data.materials.get(name) or bpy.data.materials.new(name);mat.use_nodes=True;mat.use_fake_user=True;mat.node_tree.nodes.clear()
  nodes=mat.node_tree.nodes;links=mat.node_tree.links;bsdf=nodes.new('ShaderNodeBsdfPrincipled');out=nodes.new('ShaderNodeOutputMaterial');links.new(bsdf.outputs['BSDF'],out.inputs['Surface'])
  uv=nodes.new('ShaderNodeTexCoord');mapping=nodes.new('ShaderNodeMapping');ratio=catalog['uv_period_m']/profile['repeat_m'];mapping.inputs['Scale'].default_value=(ratio,ratio,1);links.new(uv.outputs['UV'],mapping.inputs['Vector'])
  images={}
  for role,info in profile['maps'].items():
   tex=nodes.new('ShaderNodeTexImage');tex.image=bpy.data.images.load(str(root/'web/assets'/info['file']),check_existing=False);tex.image.colorspace_settings.name='sRGB' if role=='color' else 'Non-Color';tex.extension='REPEAT';tex.label=role;tex.image.pack();links.new(mapping.outputs['Vector'],tex.inputs['Vector']);images[role]=tex
  links.new(images['color'].outputs['Color'],bsdf.inputs['Base Color']);separate=nodes.new('ShaderNodeSeparateColor');links.new(images['orm'].outputs['Color'],separate.inputs['Color']);links.new(separate.outputs['Green'],bsdf.inputs['Roughness']);bsdf.inputs['Metallic'].default_value=0
  normal=nodes.new('ShaderNodeNormalMap');normal.inputs['Strength'].default_value=profile['normal_strength'];links.new(images['normal'].outputs['Color'],normal.inputs['Color']);links.new(normal.outputs['Normal'],bsdf.inputs['Normal'])
  mat['floorProfile']=id;mat['appearanceStatus']=profile['status'];mat.diffuse_color=(*[v/255 for v in profile['base']],1);materials[id]=mat
 assigned=[]
 for ob in bpy.context.scene.objects:
  if ob.type!='MESH':continue
  profile=None
  if ob.get('kind')=='floor':profile='warm_gray_fine'
  elif ob.name.startswith('Electrical ESD floor'):profile='esd_gray_green'
  elif ob.name.startswith('Dark studio floor'):profile='studio_charcoal'
  if not profile:continue
  ob.data.materials.clear();ob.data.materials.append(materials[profile]);ob['floorProfile']=profile
  uv=ob.data.uv_layers.active or ob.data.uv_layers.new(name='FloorMeters')
  for loop in ob.data.loops:
   p=ob.matrix_local@ob.data.vertices[loop.vertex_index].co;uv.data[loop.index].uv=(p.x/catalog['uv_period_m'],-p.y/catalog['uv_period_m'])
  for face in ob.data.polygons:face.material_index=0
  assigned.append({'object':ob.name,'floor':ob.get('floor'),'profile':profile})
 for image in list(bpy.data.images):
  if image.users==0 and any(image.name.startswith(id+'_') for id in catalog['profiles']):bpy.data.images.remove(image)
 bpy.context.scene['floorMaterialEvidence']='3F north photo appearance baseline; other common floors provisional; material product/category unknown. Corridor tile remains a comparison.'
 (root/'review/floor_material_assignment.json').write_text(json.dumps({'assigned':assigned,'uv_period_m':catalog['uv_period_m'],'profile_count':len(materials)},ensure_ascii=False,indent=2))
 return assigned

if __name__=='__main__':
 bpy.ops.wm.open_mainfile(filepath=str(ROOT/'flc_walkthrough.blend'));rows=apply_floor_materials()
 bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'flc_walkthrough.blend'))
 bpy.ops.export_scene.gltf(filepath=str(ROOT/'web/assets/building.glb'),export_format='GLB',export_extras=True,export_yup=True)
 p=ROOT/'build_validation.json';data=json.loads(p.read_text());data['glb_sha256']=hashlib.sha256((ROOT/'web/assets/building.glb').read_bytes()).hexdigest();data['floor_material_revision']='photo_baseline_20261101';p.write_text(json.dumps(data,indent=2))
 print('FLOOR_MATERIALS_APPLIED',len(rows))
