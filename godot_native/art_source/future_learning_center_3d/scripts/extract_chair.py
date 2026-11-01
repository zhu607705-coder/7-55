"""Export the existing authored chair as a reusable, grounded metric source.
No generation or edits to the building master. Blender --background --python ...
"""
import bpy
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
bpy.ops.wm.open_mainfile(filepath=str(ROOT / 'flc_walkthrough.blend'))
root = next(o for o in bpy.data.objects if o.get('assetId') == 'office_chair')
bpy.ops.object.select_all(action='DESELECT')
root.parent = None
root.location = (0, 0, 0)
root.rotation_euler = (0, 0, 0)
root.scale = (1, 1, 1)
for ob in [root, *root.children_recursive]:
    ob.select_set(True)
bpy.context.view_layer.objects.active = root
path = ROOT / 'sources/models/authored_ergonomic_chair.glb'
path.parent.mkdir(parents=True, exist_ok=True)
bpy.ops.export_scene.gltf(filepath=str(path), export_format='GLB',
    use_selection=True, export_extras=True, export_yup=True)
print('EXTRACTED', path)
