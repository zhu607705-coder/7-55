"""Local depth calibration of an approved Hi3D sofa; no provider submission.
Uses a nonlinear coordinate edit: front/back extremities move rigidly, while
seat span changes. Runtime placement stays uniformly scaled at1.
"""
import bpy,json,hashlib,math
from pathlib import Path
root=Path(__file__).resolve().parents[1];source=root/'web/assets/models/hi3d/rest_sofa/lod0.glb';out=root/'sources/models/hi3d/rest_sofa/local_edits';out.mkdir(exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False);bpy.ops.import_scene.gltf(filepath=str(source))
objects=[o for o in bpy.context.scene.objects if o.type=='MESH']
for o in objects:
 bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o;bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
# Provider metallic response made fabric read as foil. Preserve its color map,
# but author a dielectric, matte textile material; keep originals untouched.
for material in {m for o in objects for m in o.data.materials if m}:
 if material.use_nodes:
  bs=material.node_tree.nodes.get('Principled BSDF')
  for channel,value in [('Metallic',0),('Roughness',.88)]:
   for link in list(bs.inputs[channel].links):material.node_tree.links.remove(link)
   bs.inputs[channel].default_value=value
points=[v.co for o in objects for v in o.data.vertices];xmin=min(v.x for v in points);xmax=max(v.x for v in points);ymin=min(v.y for v in points);ymax=max(v.y for v in points)
xc=(xmin+xmax)/2;yc=(ymin+ymax)/2;dx=(1.8-(xmax-xmin))/2;dy=(.82-(ymax-ymin))/2
for o in objects:
 for v in o.data.vertices:
  x=v.co.x-xc;y=v.co.y-yc
  v.co.x=x+math.copysign(1,x)*dx*min(1,abs(x)/.55)
  v.co.y=y+math.copysign(1,y)*dy*min(1,abs(y)/.28)

 for face in o.data.polygons:face.use_smooth=True
 o.data.update()
bpy.ops.object.select_all(action='SELECT');dest=out/'sofa_metric.glb';bpy.ops.export_scene.gltf(filepath=str(dest),export_format='GLB',export_yup=True)
(out/'edit_receipt.json').write_text(json.dumps({'source':str(source.relative_to(root)),'sourceSha256':hashlib.sha256(source.read_bytes()).hexdigest(),'originalWidthDepthM':[xmax-xmin,ymax-ymin],'targetWidthDepthM':[1.8,.82],'materialCorrection':'Keep base-color texture; replace unreliable provider metallic/roughness response with dielectric matte fabric (metallic0,roughness0.88).', 'operations':'Front/back exterior bands translate rigidly; seat span is shortened; arm/leg outer cross-sections retained. End bands set1.8m width. No unequal runtime scale.','file':str(dest.relative_to(root)),'sha256':hashlib.sha256(dest.read_bytes()).hexdigest()},indent=2)+'\n')
