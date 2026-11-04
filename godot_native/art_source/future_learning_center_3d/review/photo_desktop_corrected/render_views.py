import bpy,math
from mathutils import Vector
from pathlib import Path
r=Path(__file__).resolve().parents[2];bpy.ops.wm.open_mainfile(filepath=str(r/'sources/models/photo_desktop_corrected/photo_mouse/photo_mouse.blend'))
sc=bpy.context.scene;sc.render.engine='CYCLES';sc.cycles.samples=24;sc.cycles.use_denoising=False;sc.world=bpy.data.worlds.new('Neutral');sc.world.color=(.3,.3,.3);sc.render.resolution_x=750;sc.render.resolution_y=550;sc.render.resolution_percentage=100
bpy.ops.object.light_add(type='AREA',location=(.05,-.10,.3));bpy.context.object.data.energy=8;bpy.context.object.data.size=.3
bpy.ops.object.camera_add();cam=bpy.context.object;sc.camera=cam;cam.data.type='ORTHO';cam.data.ortho_scale=.20
for name,pos in [('top',(0,0,.28)),('side',(.25,0,.025))]:
 cam.location=pos;cam.rotation_euler=(Vector((0,0,.020))-cam.location).to_track_quat('-Z','Y').to_euler()
 if name=='top':cam.rotation_euler.z+=math.pi
 sc.render.filepath=str(r/f'review/photo_desktop_corrected/mouse_{name}.png');bpy.ops.render.render(write_still=True)
