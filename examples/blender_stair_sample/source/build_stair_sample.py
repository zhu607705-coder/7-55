"""Rebuild the editable Blender source + runtime GLB for a two-flight Godot sample.
Run: blender -b --python source/build_stair_sample.py
All authored coordinates use Godot Y-up; export conversion is explicit.
No external assets or add-ons required. Player/guard sprites remain Godot assets.
"""
import bpy, math, json, random
from pathlib import Path
from mathutils import Vector
BASE=Path(__file__).resolve().parents[1]
(BASE/'outputs').mkdir(parents=True,exist_ok=True)
OUT=BASE/'preview/assets/blender'; OUT.mkdir(parents=True,exist_ok=True)
DATA=json.loads((BASE/'preview/data/native/chapter4-endless-stair-b3.json').read_text())
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
for datablocks in [bpy.data.meshes,bpy.data.materials,bpy.data.curves,bpy.data.images]:
 for b in list(datablocks):
  if b.users==0: datablocks.remove(b)
def B(v): return Vector((v[0],-v[2],v[1]))
def linear(c): return ((c+.055)/1.055)**2.4 if c>.04045 else c/12.92
def mat(name,hexcolor,rough=.9,metal=0,texture=False):
 m=bpy.data.materials.new(name);m.use_nodes=True
 p=m.node_tree.nodes.get('Principled BSDF');c=[int(hexcolor[i:i+2],16)/255 for i in (0,2,4)]
 p.inputs['Base Color'].default_value=tuple(linear(x) for x in c)+(1,); p.inputs['Roughness'].default_value=rough;p.inputs['Metallic'].default_value=metal
 if texture:
  # Slow, low-amplitude tonal variation: no random high-contrast pixel speckles.
  im=bpy.data.images.new(name+'_albedo',width=128,height=128)
  pix=[]
  for y in range(128):
   for x in range(128):
    t=1+.006*math.sin(x*.11)*math.cos(y*.09)+.004*math.sin(x*.031+1.4)*math.cos(y*.041)
    pix.extend([min(1,a*t) for a in c]+[1])
  im.pixels=pix;im.filepath_raw=str(OUT/(name+'.png'));im.file_format='PNG';im.save();im.pack()
  t=m.node_tree.nodes.new('ShaderNodeTexImage');t.image=im;t.interpolation='Linear';m.node_tree.links.new(t.outputs['Color'],p.inputs['Base Color'])
 return m
M={k:mat(k,c,r,met,tex) for k,c,r,met,tex in [
 ('plaster','9ca8a2',.94,0,True),('dado','455d5b',.86,0,True),('concrete','84918e',.92,0,True),
 ('nosing','a0aca2',.88,0,False),('joint','4c5c59',.94,0,False),('metal','334749',.76,.18,False),
 ('handle','7c8982',.55,.36,False),('door','3d5352',.83,0,True),('glass','243a40',.42,.05,False),
 ('sign','3e5755',.87,0,False),('letter','c2c7b6',.9,0,False),('warn','927c53',.94,0,False)]}
GROUP=None;parts=[];proxies=[]
def parent(name):
 global GROUP
 GROUP=bpy.data.objects.new(name,None);bpy.context.collection.objects.link(GROUP);GROUP['godot_route']=name
 return GROUP
def mesh(name,verts,faces,material,bevel=0):
 me=bpy.data.meshes.new(name);me.from_pydata([B(v) for v in verts],[],faces);me.update()
 ob=bpy.data.objects.new(name,me);bpy.context.collection.objects.link(ob);ob.parent=GROUP;ob.data.materials.append(M[material]);parts.append(ob)
 # Deterministic cube-style UV projection. No proprietary textures.
 uv=me.uv_layers.new(name='UVMap')
 for poly in me.polygons:
  normal=poly.normal;axis=max(range(3),key=lambda i:abs(normal[i]));axes=[i for i in range(3) if i!=axis]
  for li in poly.loop_indices:
   co=me.vertices[me.loops[li].vertex_index].co;uv.data[li].uv=(co[axes[0]]*.4,co[axes[1]]*.4)
 if bevel:
  mod=ob.modifiers.new('Small manufactured edge radii','BEVEL');mod.width=bevel;mod.segments=1
  bpy.context.view_layer.objects.active=ob;ob.select_set(True);bpy.ops.object.modifier_apply(modifier=mod.name);ob.select_set(False)
 return ob
def box(name,c,s,material,bevel=.008,proxy=False):
 x,y,z=c;a,b,d=[i*.5 for i in s]
 ob=mesh(name,[(x+sx*a,y+sy*b,z+sz*d) for sx,sy,sz in [(-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),(-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1)]],[(3,2,1,0),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],material,bevel)
 if proxy or (max(s)>.3 and min(s)>.015):proxies.append(dict(group=GROUP.name,center=c,size=s))
 return ob
def rod(name,a,b,r=.032,material='metal',segments=8):
 A,Bb=B(a),B(b);d=Bb-A
 bpy.ops.mesh.primitive_cylinder_add(vertices=segments,radius=r,depth=d.length,location=(A+Bb)/2)
 ob=bpy.context.object;ob.name=name;ob.rotation_mode='QUATERNION';ob.rotation_quaternion=d.to_track_quat('Z','Y');ob.parent=GROUP;ob.data.materials.append(M[material]);parts.append(ob)
 for p in ob.data.polygons:p.use_smooth=len(p.vertices)==4
 ob.select_set(False)
 if r>=.022 and d.length>.25:
  ga,gb=Vector(a),Vector(b);proxies.append(dict(group=GROUP.name,center=list((ga+gb)*.5),size=[r*2,d.length,r*2],axis=list((gb-ga).normalized())))
 return ob
def rail(name,points,r=.034):
 # Miter-free bent tubing with small swept corner radii, no floating rail ends.
 pts=[Vector(p) for p in points]; smooth=[pts[0]]
 for i in range(1,len(pts)-1):
  P,Q,R=pts[i-1],pts[i],pts[i+1];a=Q+(P-Q).normalized()*.12;b=Q+(R-Q).normalized()*.12
  smooth.append(a)
  for j in range(1,5):
   t=j/4;smooth.append(a*(1-t)**2+Q*2*t*(1-t)+b*t*t)
 smooth.append(pts[-1])
 for i,(a,b) in enumerate(zip(smooth,smooth[1:])):rod(name+'_%02d'%i,a,b,r)
def text(name,body,c,size=.3,material='letter'):
 cu=bpy.data.curves.new(name,'FONT');cu.body=body;cu.align_x='CENTER';cu.align_y='CENTER';cu.size=size;cu.extrude=.001
 ob=bpy.data.objects.new(name,cu);bpy.context.collection.objects.link(ob);ob.location=B(c);ob.rotation_euler=(math.pi/2,0,0);ob.parent=GROUP;ob.data.materials.append(M[material]);
 bpy.context.view_layer.objects.active=ob;ob.select_set(True);bpy.ops.object.convert(target='MESH');parts.append(bpy.context.object);ob.select_set(False)
def flight(section):
 n=section['flight']-1;start=section['fromXZ'];end=section['toXZ'];h=section['fromY'];direction=1 if end[0]>start[0] else -1;z=start[1]
 # A watertight concrete section: stepped upper boundary and inclined soffit.
 profile=[(0,-.32),(12,3.3-.32),(12,3.3)]
 for i in reversed(range(20)):
  top=(i+1)*.165;profile += [(i*.6,top)]
  if i>0:profile += [(i*.6,i*.165)]
 verts=[(start[0]+direction*x,h+y,z+side) for side in [-1,1] for x,y in profile];L=len(profile)
 faces=[tuple(range(L-1,-1,-1)),tuple(range(L,2*L))]+[(i,(i+1)%L,(i+1)%L+L,i+L) for i in range(L)]
 mesh('Flight_%02d_watertight_stepped_concrete'%n,verts,faces,'concrete',.006)
 for i in range(20):
  x=start[0]+direction*(i*.6+.04);y=h+(i+1)*.165
  # Narrow recessed anti-slip insert sits flush in the front of each tread.
  box('Recessed_tread_insert_%02d'%i,(x,y+.001,z),(.065,.006,1.86),'joint',.002)
  box('Secondary_grip_groove_%02d'%i,(x+direction*.095,y+.001,z),(.018,.004,1.86),'joint',0)
  box('Rounded_tread_nose_%02d'%i,(start[0]+direction*(i*.6+.012),y-.018,z),(.024,.035,1.99),'nosing',.005)
 for side in [-1,1]:
  inner=(side==-1 if n==0 else side==1)
  sx=start[0]+direction*.60 if inner and n==1 else start[0]
  ex=end[0]-direction*.60 if inner else end[0]
  a=(sx,h+.98,z+side*.96);b=(ex,h+3.3+.98,z+side*.96)
  rail('Continuous_hand_handrail',[a,b],.035)
  rail('Mid_safety_rail',[(a[0],a[1]-.47,a[2]),(b[0],b[1]-.47,b[2])],.022)
  for i in range(0,21,2):
   if inner and (i==20 or (n==1 and i==0)):continue
   x=start[0]+direction*i*.6;ground=h+i*.165
   rod('Welded_upright',(x,ground,z+side*.96),(x,ground+.98,z+side*.96),.026)
   box('Bolted_baseplate',(x,ground+.018,z+side*.96),(.14,.035,.13),'metal',.009)
   for dx in [-.045,.045]:box('Anchor_bolt',(x+dx,ground+.041,z+side*.96),(.018,.012,.018),'handle',0)
def landing(section):
 kind=section['kind'];h=section['fromY'];a=section['fromXZ'];b=section['toXZ'];
 if kind=='turn':
  # Full landing connects both flight widths with no disconnected corners.
  outward=1 if a[0]>0 else -1
  c=(a[0]+outward*.20,h-.19,(a[1]+b[1])/2);size=(1.6,.38,abs(a[1]-b[1])+2)
  box('Monolithic_return_landing',c,size,'concrete',.012,True)
  outward=1 if a[0]>0 else -1;x=a[0]+outward*.96;za=min(a[1],b[1])-.96;zb=max(a[1],b[1])+.96
  for height,r in [(.98,.035),(.51,.022)]:
   rail('Bent_platform_return',[(a[0]-outward*.26,h+height,zb),(x,h+height,zb),(x,h+height,za),(a[0]-outward*.26,h+height,za)],r)
  for zz in [za,za+1.3,za+2.6,zb]:
   rod('Landing_post',(x,h,zz),(x,h+.98,zz),.026);box('Landing_baseplate',(x,h+.018,zz),(.14,.035,.14),'metal',.008)
  ix=a[0]-outward*.60
  for height,r in [(.98,.035),(.51,.022)]:
   rail('Inner_return_around_void',[(ix,h+height,-.96),(ix,h+height,-2.34)],r)
  for zz in [-.96,-2.34]:
   rod('Inner_return_post',(ix,h,zz),(ix,h+.98,zz),.026)
  # Slab joints and edge band are material-controlled, not emitting stripes.
  for zz in [za+1.0,za+2.6,zb-.60]:
   box('Landing_expansion_joint',(a[0]+outward*.20,h+.001,zz),(1.55,.003,.018),'joint',0)
  box('Landing_fascia',(a[0]+outward*1.001,h-.19,(za+zb)/2),(.015,.29,zb-za),'dado',.003)
 else:
  x=(a[0]+b[0])/2;length=abs(a[0]-b[0]);box('Entry_or_exit_slab',(x,h-.18,a[1]),(length,.36,2),'concrete',.012,True)
  for z in [-.96,.96]:
   rail('Straight_platform_rail',[(a[0],h+.98,a[1]+z),(b[0],h+.98,a[1]+z)])
   for t in range(int(length)+1):
    xx=a[0]+(b[0]-a[0])*t/length;rod('Platform_post',(xx,h,a[1]+z),(xx,h+.98,a[1]+z),.026)
def architecture():
 # Actual door/window openings, surrounding wall pieces and deep reveals.
 for floor in range(3):
  h=floor*3.3; wx=.9; ww=2.30;wy=h+2.0;wh=1.55;dx=-6.45;dw=1.42;dh=2.55;z=-4.65
  intervals=[(-8.1,dx-dw/2),(dx+dw/2,wx-ww/2),(wx+ww/2,8.1)]
  for a,b in intervals:
   box('Plaster_pier',( (a+b)/2,h+1.65,z),(b-a,3.3,.32),'plaster',.006,True)
   box('Painted_lower_dado',((a+b)/2,h+.50,z+.172),(b-a,1,.024),'dado',.002)
   box('Dado_top_termination',((a+b)/2,h+1.015,z+.185),(b-a,.035,.035),'joint',.003)
  box('Window_wall_below',(wx,h+.60,z),(ww,1.2,.32),'plaster',.006,True)
  box('Window_dado',(wx,h+.50,z+.172),(ww,1,.024),'dado',.002)
  box('Window_wall_above',(wx,h+3.04,z),(ww,.52,.32),'plaster',.006,True)
  box('Door_lintel',(dx,h+2.925,z),(dw,.75,.32),'plaster',.006,True)
  # Recessed glazing: front framing + back glazing 18 cm behind it.
  box('Recessed_window_glass',(wx,wy,z-.08),(ww-.12,wh-.12,.025),'glass',.002)
  for xx in [wx-ww/2+.04,wx,wx+ww/2-.04]:box('Window_mullion',(xx,wy,z+.08),(.07,wh,.16),'metal',.006)
  for yy in [wy-wh/2+.035,wy,wy+wh/2-.035]:box('Window_frame',(wx,yy,z+.08),(ww,.07,.16),'metal',.006)
  box('Chamfered_window_sill',(wx,h+1.18,z+.14),(ww+.14,.12,.42),'concrete',.01)
  # The leaf is inset behind jambs and has a threshold, hinge barrels and handle.
  box('Recessed_door_leaf',(dx,h+1.245,z-.015),(dw-.15,2.49,.075),'door',.009,True)
  for xx in [dx-dw/2+.04,dx+dw/2-.04]:box('Deep_door_jamb',(xx,h+1.28,z+.08),(.09,2.56,.23),'metal',.006)
  box('Door_head_frame',(dx,h+2.55,z+.08),(dw,.09,.23),'metal',.006)
  box('Stone_door_threshold',(dx,h+.025,z+.10),(dw,.05,.38),'concrete',.008)
  box('Door_recessed_glass',(dx,h+1.86,z+.027),(.68,.56,.02),'glass',.003)
  for yy in [h+1.55,h+2.16]:box('Door_window_rebate',(dx,yy,z+.043),(.77,.036,.04),'metal',.004)
  for xx in [dx-.37,dx+.37]:box('Door_window_rebate',(xx,h+1.86,z+.043),(.036,.65,.04),'metal',.004)
  for yy in [h+.38,h+2.05]:rod('Door_hinge',(dx-dw/2+.09,yy-.08,z+.035),(dx-dw/2+.09,yy+.08,z+.035),.023,'handle')
  box('Door_latch_plate',(dx+.45,h+1.05,z+.045),(.09,.25,.025),'handle',.009)
  rod('Door_lever',(dx+.44,h+1.09,z+.09),(dx+.27,h+1.09,z+.09),.022,'handle')
  sx=-3.15 if floor%2==0 else 3.15
  box('Floor04_enamel_plaque',(sx,h+2.12,z+.195),(.83,.75,.045),'sign',.015)
  text('Floor04_raised_number','04',(sx,h+2.18,z+.224),.46)
  text('Floor04_caption','NORTH / UP',(sx,h+1.91,z+.224),.075)
  # Finite fasteners, not noisy wall ornaments.
  for xx in [sx-.34,sx+.34]:
   for yy in [h+1.82,h+2.42]:box('Plaque_fastener',(xx,yy,z+.226),(.013,.013,.008),'handle',.002)
  box('Floor_seam',(0,h+3.27,z+.17),(16.2,.045,.035),'joint',.003)
 # Wall paint follows the rear stair pitch. It reads at game distance and
 # preserves quiet large surfaces instead of adding speckled grunge.
 for base,dir in [(0,1),(3.3,-1)]:
  a,b=(-6,6) if dir==1 else (6,-6)
  # Split decorative paint at real door/window apertures. A paint plane must
  # never cover glazing or bridge an opening merely because it is thin.
  for lo,hi in [(-5.65,-.25),(2.05,6.0)]:
   ya=base+(lo-a)/(b-a)*3.3;yb=base+(hi-a)/(b-a)*3.3
   verts=[(lo,ya+.12,-4.473),(hi,yb+.12,-4.473),(hi,yb+1.0,-4.473),(lo,ya+1.0,-4.473)]
   mesh('Stair_pitch_painted_wall_skirt',verts,[(0,1,2,3)],'dado')
   rod('Skirt_capping_at_stair_pitch',(lo,ya+1.01,-4.447),(hi,yb+1.01,-4.447),.017,'nosing')
 for xx in [-7.78,7.75]:
  rod('Service_conduit',(xx,.1,-4.425),(xx,9.8,-4.425),.027)
  for h in [1,3.8,6.8,9.4]:box('Conduit_wall_clip',(xx,h,-4.40),(.12,.045,.045),'metal',.005)
# Build independently editable route modules; join by material after bevel application.
for section in DATA['routes']:
 parent(section['id'])
 if section['kind']=='flight':flight(section)
 else:landing(section)
parent('Architecture');architecture()
parent('JumpBarrier')
# Low folded school maintenance stand, clear flight silhouette and large open centre.
# Matches the existing 0.35 x 0.55 route obstacle exactly; no implied sideways bypass.
o=DATA['obstacles'][0]['rect']; prog=o[0]+o[2]/2;z=-3.3+(prog-31.3);x=-6;y=6.6
for xx in [x-.69,x+.69]:
 rod('Folded_stand_leg_A',(xx,y,z-.175),(xx,y+.53,z+.10),.027)
 rod('Folded_stand_leg_B',(xx,y,z+.175),(xx,y+.53,z-.10),.027)
 box('Rubber_foot',(xx,y+.018,z-.175),(.11,.036,.13),'joint',.01)
 box('Rubber_foot',(xx,y+.018,z+.175),(.11,.036,.13),'joint',.01)
box('Maintenance_stand_crossbar',(x,y+.50,z),(1.65,.10,.16),'warn',.012)
rod('Stand_lower_brace',(x-.69,y+.16,z),(x+.69,y+.16,z),.02)
for xx in [x-.60,x-.30,x,x+.30,x+.60]:box('Worn_bar_marking',(xx,y+.502,z+.082),(.09,.072,.003),'joint',.001)
# Join only within route + material: compact runtime draw calls, source remains organized.
for group in [o for o in list(bpy.data.objects) if o.type=='EMPTY']:
 for material in M.values():
  obs=[o for o in list(group.children) if o.type=='MESH' and o.data.materials and o.data.materials[0]==material]
  if not obs:continue
  bpy.ops.object.select_all(action='DESELECT')
  for ob in obs:ob.select_set(True)
  bpy.context.view_layer.objects.active=obs[0];bpy.ops.object.join();obs[0].name=group.name+'__'+material.name;obs[0]['runtime_module']=group.name
# Recompute consistent outward normals after Godot-to-Blender axis conversion.
for ob in [o for o in bpy.data.objects if o.type=='MESH']:
 bpy.context.view_layer.objects.active=ob;ob.select_set(True);bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.mesh.normals_make_consistent(inside=False);bpy.ops.object.mode_set(mode='OBJECT');ob.select_set(False)
scene=bpy.context.scene;scene.unit_settings.system='METRIC';scene.unit_settings.scale_length=1
scene['source_note']='Two-flight playable sample. Godot collision stays fixed-tick 1D route; no side bypass. Export is genuine GLB mesh geometry.'
bpy.ops.wm.save_as_mainfile(filepath=str(BASE/'source/stairwell_sample.blend'))
bpy.ops.export_scene.gltf(filepath=str(OUT/'stairwell_sample.glb'),export_format='GLB',export_yup=True,export_extras=True,export_cameras=False,export_lights=False)
summary={'mesh_objects':len([o for o in bpy.data.objects if o.type=='MESH']),'triangles':sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in bpy.data.objects if o.type=='MESH'),'materials':len(M),'glb_bytes':(OUT/'stairwell_sample.glb').stat().st_size,'route_modules':[s['id'] for s in DATA['routes']],'editable_source':'source/stairwell_sample.blend','coordinate_system':'Godot metres, Y-up; authored via explicit axis conversion','no_glow':True,'proxies':proxies}
(OUT/'stairwell_manifest.json').write_text(json.dumps(summary,indent=2));(BASE/'outputs/model_budget.json').write_text(json.dumps({k:v for k,v in summary.items() if k!='proxies'},indent=2));print('STAIR_MODEL_BUDGET',json.dumps({k:v for k,v in summary.items() if k!='proxies'}))
