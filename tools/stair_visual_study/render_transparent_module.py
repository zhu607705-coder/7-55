"""Transparent object-only source for web art direction, not final game art."""
import argparse,json,pathlib,runpy,sys
import bpy
from mathutils import Vector,Matrix
p=argparse.ArgumentParser();p.add_argument('--output',required=True)
a=p.parse_args(sys.argv[sys.argv.index('--')+1:]);out=pathlib.Path(a.output).resolve();out.mkdir(parents=True,exist_ok=True)
root=pathlib.Path(__file__).resolve().parent
sys.argv=[str(root/'build_stair_sample.py'),'--','--output',str(out/'build'),'--variant','structure']
g=runpy.run_path(str(root/'build_stair_sample.py'));S=g['S'];owner=g['OWN']['b_lower_stair'];cam=S.camera
owner.matrix_world=Matrix.Identity(4);keep=[]
for ob in S.objects:
    if ob.type=='MESH':
        ob.hide_render=ob.parent!=owner
        if not ob.hide_render:keep.append(ob)
    elif ob.type=='LIGHT':ob.hide_render=True
bpy.context.view_layer.update()
points=[ob.matrix_world@Vector(c) for ob in keep for c in ob.bound_box]
low=Vector(tuple(min(p[i] for p in points) for i in range(3)));high=Vector(tuple(max(p[i] for p in points) for i in range(3)));center=(low+high)/2
cam.location=center+Vector((-7,-9,7));cam.rotation_euler=(center-cam.location).to_track_quat('-Z','Y').to_euler()
rot=cam.rotation_euler.to_matrix();inv=rot.transposed();pp=[inv@(p-center) for p in points]
span_x=max(p.x for p in pp)-min(p.x for p in pp);span_y=max(p.y for p in pp)-min(p.y for p in pp)
cam.data.ortho_scale=max(span_x,span_y)*1.20
S.render.resolution_x=1024;S.render.resolution_y=1024;S.render.film_transparent=True
S.render.image_settings.file_format='PNG';S.render.image_settings.color_mode='RGBA';S.cycles.samples=4;S.cycles.max_bounces=1;S.cycles.use_denoising=False
for mat in g['M'].values():
    b=mat.node_tree.nodes.get('Principled BSDF');b.inputs['Emission Color'].default_value=mat.diffuse_color;b.inputs['Emission Strength'].default_value=.2
ld=bpy.data.lights.new('Object inspection key','AREA');o=bpy.data.objects.new('Object inspection key',ld);S.collection.objects.link(o);o.location=center+Vector((-3,-5,9));o.rotation_euler=(center-o.location).to_track_quat('-Z','Y').to_euler();ld.energy=1300;ld.size=6
bpy.context.view_layer.update()
report={'module':'b_lower_stair','source_state':0,'source_pivot_godot':g['L']['mechanisms'][0]['pivot'],'source_units':'metres','source_geometry_unchanged':True,'output':'lower_stair_threequarter_whitebox_rgba.png','camera_blender_world':[list(r) for r in cam.matrix_world],'ortho_scale':cam.data.ortho_scale,'resolution':[1024,1024],'film_transparent':True,'color_mode':'RGBA','rendered_meshes':len(keep),'purpose':'geometry source only; pending web art generation'}
(out/'transparent_source.json').write_text(json.dumps(report,indent=2)+'\n')
S.render.filepath=str(out/report['output']);bpy.ops.render.render(write_still=True)
bpy.ops.wm.save_as_mainfile(filepath=str(out/'lower_stair_transparent_source.blend'))
print('TRANSPARENT_MODULE_OK')
