"""Whole stair_b source-rule alignment demonstration, never a collision claim.
All view-joining states must come from the verified original Godot model trace.
Free interpolation is an inspection transition, with seam indicators disabled.
"""
import argparse,json,math,pathlib,runpy,sys
import bpy
from mathutils import Vector,Matrix
p=argparse.ArgumentParser();p.add_argument('--output',required=True);p.add_argument('--trace',required=True);p.add_argument('--render',action='store_true')
a=p.parse_args(sys.argv[sys.argv.index('--')+1:]);out=pathlib.Path(a.output).resolve();out.mkdir(parents=True,exist_ok=True)
trace=json.loads(pathlib.Path(a.trace).read_text());assert trace['level']=='stair_b' and not trace['failed']
root=pathlib.Path(__file__).resolve().parent;sys.argv=[str(root/'build_stair_sample.py'),'--','--output',str(out/'build'),'--variant','structure']
g=runpy.run_path(str(root/'build_stair_sample.py'));S=g['S'];L=g['L'];C=g['C'];owners=g['OWN'];v=g['v'];cam=S.camera
S.render.resolution_x=640;S.render.resolution_y=360;S.render.fps=12;S.cycles.samples=8;S.cycles.max_bounces=1
# Remove only fixed scenery from this exploded inspection rig. The source-rule
# oracle still includes its authored wall for all canonical visibility checks.
for ob in S.objects:
    if ob.type=='MESH' and ('backdrop_wall' in ob.name or 'b_deco_' in ob.name and 'fire_door' not in ob.name):ob.hide_render=True
for mat in g['M'].values():
    bs=mat.node_tree.nodes.get('Principled BSDF');bs.inputs['Emission Color'].default_value=mat.diffuse_color;bs.inputs['Emission Strength'].default_value=.25
S.world.node_tree.nodes['Background'].inputs['Color'].default_value=(.017,.025,.04,1)
S.world.node_tree.nodes['Background'].inputs['Strength'].default_value=.5
# Explicit source oracle witnesses. No manual "looks aligned" classification.
low=next(t for t in trace['trace'] if t['action'].get('value')=='south_west')
upper=next(t for t in trace['trace'] if t['action'].get('value')=='top_oblique')
assert any(e['id']=='b_link_lower_stair_lift' for e in low['edges'])
assert any(e['id']=='b_link_upper_stair_island' for e in upper['edges'])
checks=2
m_by_id={m['id']:m for m in L['mechanisms']}

def set_mechanisms(values):
    for id,value in values.items():
        m=m_by_id[id];o=owners[id]
        if m['kind']=='rotate':
            pivot=v(m['pivot']);o.matrix_world=Matrix.Translation(pivot)@Matrix.Rotation(value*math.pi/2,4,'Z')@Matrix.Translation(-pivot)
        else:
            offset=[0,0,0];offset[{'x':0,'y':1,'z':2}[m['axis']]]=m['stepSize']*value;o.matrix_world=Matrix.Translation(v(offset))

def ease(t):
    t=max(0,min(1,t));return t*t*(3-2*t)

marker_mat=bpy.data.materials.new('Source validated view join');marker_mat.use_nodes=True
nd=marker_mat.node_tree.nodes;bs=nd.get('Principled BSDF');bs.inputs['Base Color'].default_value=(.12,.8,.45,1);bs.inputs['Emission Color'].default_value=(.12,.8,.45,1);bs.inputs['Emission Strength'].default_value=1
markers=[]
for i in range(2):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=12,ring_count=6,radius=.12)
    o=bpy.context.object;o.name='Validated endpoint '+str(i);o.data.materials.append(marker_mat);markers.append(o)
caption_mat=bpy.data.materials.new('Inspection caption');caption_mat.use_nodes=True
b=caption_mat.node_tree.nodes.get('Principled BSDF');b.inputs['Emission Color'].default_value=(.8,.88,.92,1);b.inputs['Emission Strength'].default_value=1
font=bpy.data.curves.new('Source mechanism demonstration','FONT');font.size=.30
caption=bpy.data.objects.new('Source mechanism demonstration',font);S.collection.objects.link(caption);caption.parent=cam;caption.location=(-9.25,4.65,-1);caption.data.materials.append(caption_mat)
report={'level':'stair_b','frames':96,'fps':12,'kind':'Blender visual replay of source-rule witnesses','collision_test':False,
'new_gameplay_camera':False,'source_trace_sha256':__import__('hashlib').sha256(pathlib.Path(a.trace).read_bytes()).hexdigest(),
'keyframes':{},'source_checks':trace['checks']}
frames=out/'frames';frames.mkdir(exist_ok=True)
for frame in range(96):
    t=frame/12;values={'b_lower_stair':1.,'b_mid_lift':0.,'b_upper_stair':0.,'b_exit_slide':0.}
    # Source lower rotation 1 -> 0 -> 3 (the continuous angle -1 equals source state 3).
    values['b_lower_stair']=1-2*ease(t/.95)
    values['b_mid_lift']=2*ease((t-2.7)/.85)
    values['b_upper_stair']=ease((t-3.65)/.7)
    values['b_exit_slide']=2*ease((t-6.5)/.8)
    set_mechanisms(values)
    se=v(C['views']['south_east']['position']);sw=v(C['views']['south_west']['position']);top=v(C['views']['top_oblique']['position'])
    if t<3.7:origin=se.lerp(sw,ease((t-1)/1.0))
    else:origin=sw.lerp(top,ease((t-4.4)/1.0))
    cam.location=origin;cam.rotation_euler=(v(C['center'])-origin).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=C['halfHeight']*2*640/360
    for m in markers:m.hide_render=True
    phase='INSPECTION - original rotating stair'
    witness=None;pair=None
    if 2.0<=t<2.7:
        phase='SOUTH-WEST - source view join active';witness=low;pair=('B_LOWER_HIGH','B_MID_LIFT_LOW')
    elif 2.7<=t<3.7:phase='LIFT MOVING - lower view join is inactive'
    elif 3.7<=t<5.4:phase='INSPECTION - upper stair and camera turn'
    elif 5.4<=t<6.5:
        phase='TOP OBLIQUE - source view join active';witness=upper;pair=('B_UPPER_HIGH','B_HIGH_ISLAND')
    elif t>=6.5:phase='EXIT SLIDE - original mechanism state 2'
    if witness:
        for marker,node in zip(markers,pair):marker.location=v(witness['positions'][node]);marker.hide_render=False
        # Canonical source camera only. No active indicator during interpolated inspection.
        expected=v(C['views'][witness['state']['view']]['position']);assert (cam.location-expected).length<1e-5
        for key,value in witness['state']['values'].items():
            if key in ('b_lower_stair','b_upper_stair'):assert abs((values[key]-value)%4)<1e-4 or abs((values[key]-value)%4-4)<1e-4
        checks+=1
    font.body=phase
    if frame in (0,24,31,48,66,76,95):report['keyframes'][str(frame)]={'phase':phase,'values':values,'view_join':witness['state']['view'] if witness else None}
    S.render.filepath=str(frames/('%04d.png'%frame))
    if a.render:bpy.ops.render.render(write_still=True)
report['checks']=checks;(out/'alignment.json').write_text(json.dumps(report,indent=2)+'\n')
bpy.ops.wm.save_as_mainfile(filepath=str(out/'source_alignment.blend'))
print('SOURCE_ALIGNMENT_OK',checks)
