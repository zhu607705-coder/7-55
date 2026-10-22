"""Render transparent inspection views from the exact exported asset scene."""
import argparse,json,pathlib,sys
import bpy
from mathutils import Matrix
p=argparse.ArgumentParser();p.add_argument('--blend',required=True);p.add_argument('--manifest',required=True);p.add_argument('--prefix',required=True)
a=p.parse_args(sys.argv[sys.argv.index('--')+1:]);bpy.ops.wm.open_mainfile(filepath=str(pathlib.Path(a.blend).resolve()))
S=bpy.context.scene;data=json.loads(pathlib.Path(a.manifest).read_text());S.render.threads_mode='FIXED';S.render.threads=1;S.cycles.samples=16;S.render.film_transparent=True;S.render.image_settings.color_mode='RGBA'
for name,view in data['render_views'].items():
 S.camera.matrix_world=Matrix(view['camera_blender']);S.camera.data.ortho_scale=view['ortho_scale'];S.render.filepath=str(pathlib.Path(a.prefix).resolve())+'_'+name+'_rgba.png';bpy.ops.render.render(write_still=True)
print('TRANSPARENT_VIEWS_OK',a.prefix)
