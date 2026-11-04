"""Photo 3 laboratory contents. Blender 4.3.2, estimated metres, no reference image pixels.
Run with optional -- --skip-render, --render-only or --composition-only.
Independent source files and review assembly only; no game or original-source edits.
"""
import bpy, bmesh, math, json, hashlib, sys, collections
import numpy as np
from pathlib import Path
from mathutils import Vector, Matrix

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'sources/models/photo_lab_contents'
REVIEW=ROOT/'review/photo_lab_contents'
OUT.mkdir(parents=True,exist_ok=True);REVIEW.mkdir(parents=True,exist_ok=True)
LOD=0;CURRENT_FOLDER=OUT;records=[]


def material(name,color,metal=0,rough=.5):
    m=bpy.data.materials.new(name);m.use_nodes=True;m.diffuse_color=(*color,1)
    p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1)
    p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=rough
    return m


def palette():
    global wood,black,rubber,board,paper
    black=material('Charcoal powder coated steel',(.035,.041,.043),.3,.5)
    rubber=material('Black chair and case polymer',(.012,.015,.017),0,.72)
    board=material('Warm neutral plywood liner',(.34,.25,.16),0,.67)
    paper=material('Unmarked warm grey storage box',(.58,.55,.48),0,.86)
    wood=material('Pale wood laminate',(.58,.47,.32),0,.58)
    n=128;v,u=np.meshgrid(np.arange(n)/n,np.arange(n)/n,indexing='ij')
    grain=.5+.16*np.sin(u*151+np.sin(v*8)*.8)+.10*np.sin(u*501+v*4)
    pixels=np.ones((n,n,4),np.float32)
    for k,(a,b) in enumerate(zip((.48,.37,.24),(.65,.55,.39))):pixels[:,:,k]=a+grain*(b-a)
    im=bpy.data.images.new('Synthetic pale laminate grain',width=n,height=n,alpha=True)
    im.pixels.foreach_set(pixels.ravel());im.filepath_raw=str(CURRENT_FOLDER/'synthetic_wood.png');im.file_format='PNG';im.save();im.pack()
    tex=wood.node_tree.nodes.new('ShaderNodeTexImage');tex.image=im
    wood.node_tree.links.new(tex.outputs['Color'],wood.node_tree.nodes.get('Principled BSDF').inputs['Base Color'])
    wood['textureProvenance']='Authored mathematical 128px grain, no photo pixels. Metallic and roughness factors.'

def finish(o,name,mat,smooth=False):
    o.name=name;o['part']=name
    if mat:o.data.materials.append(mat)
    for p in o.data.polygons:p.use_smooth=smooth
    return o


def mesh(name,verts,faces,mat,smooth=False):
    me=bpy.data.meshes.new(name);me.from_pydata(verts,[],faces);me.update()
    o=bpy.data.objects.new(name,me);bpy.context.collection.objects.link(o)
    return finish(o,name,mat,smooth)


def active(o):
    bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o


def bevel(o,width,segments=None):
    bpy.context.view_layer.update();active(o)
    m=o.modifiers.new('Manufactured rounded edge','BEVEL');m.width=min(width,.45*min(o.dimensions))
    m.segments=segments or [3,2,1][LOD]
    bpy.ops.object.modifier_apply(modifier=m.name)
    n=o.modifiers.new('Weighted surface normals','WEIGHTED_NORMAL');n.keep_sharp=True
    bpy.ops.object.modifier_apply(modifier=n.name)


def planar_uv(o,repeat=None):
    uv=o.data.uv_layers.new(name='UVMap');pts=[v.co for v in o.data.vertices]
    mn=Vector([min(v[i] for v in pts) for i in range(3)]);ext=Vector([max(v[i] for v in pts) for i in range(3)])-mn
    for p in o.data.polygons:
        axes=(0,1) if abs(p.normal.z)>.5 else ((0,2) if abs(p.normal.y)>.5 else (1,2))
        for li in p.loop_indices:
            c=o.data.vertices[o.data.loops[li].vertex_index].co
            uv.data[li].uv=tuple((c[i]-mn[i])/(repeat or max(ext[i],.000001)) for i in axes)


def box(name,loc,size,mat,edge=0,repeat=None):
    bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.dimensions=size
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);finish(o,name,mat)
    if edge:bevel(o,edge)
    planar_uv(o,repeat);return o


def cylinder(name,loc,r,depth,mat,axis='Z',r2=None,n=None):
    bpy.ops.mesh.primitive_cone_add(vertices=n or [40,20,10][LOD],radius1=r,radius2=r if r2 is None else r2,depth=depth,location=loc)
    o=bpy.context.object
    if axis=='X':o.rotation_euler.y=math.pi/2
    if axis=='Y':o.rotation_euler.x=math.pi/2
    finish(o,name,mat,True)
    # Preserve flat caps while smooth-shading the curved side.
    for p in o.data.polygons:
        if len(p.vertices)>4:p.use_smooth=False
    return o


def bar_between(name,a,b,r,mat,n=None):
    a,b=Vector(a),Vector(b);o=cylinder(name,(a+b)/2,r,(b-a).length,mat,n=n)
    o.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler();return o


def lathe(name,x,y,rings,mat,n=None,flutes=0):
    n=n or [48,24,12][LOD];vs=[]
    for z,r in rings:
        for i in range(n):
            a=math.tau*i/n;rr=r*(1+flutes*math.cos(a*12));vs.append((x+rr*math.cos(a),y+rr*math.sin(a),z))
    fs=[tuple(reversed(range(n))),tuple(range((len(rings)-1)*n,len(rings)*n))]
    for j in range(len(rings)-1):
        for i in range(n):a=j*n+i;b=j*n+(i+1)%n;fs.append((a,b,b+n,a+n))
    return mesh(name,vs,fs,mat,True)


def table():
    box('Thin rectangular pale laminate top',(0,0,.735),(2.2,1.0,.03),wood,.003)
    for x in [-1.035,1.035]:
        for y in [-.435,.435]:
            box('Square steel leg',(x,y,.36),(.055,.055,.72),black,.0018)
            box('Black floor glide',(x,y,.005),(.052,.052,.01),rubber,.001)
    for y in [-.425,.425]:box('Inset under top long rail',(0,y,.695),(2.08,.033,.05),black,.001)
    for x in [-1.025,1.025]:box('Inset under top short rail',(x,0,.695),(.033,.84,.05),black,.001)

def chair():
    box('Broad rounded seat',(0,-.015,.445),(.49,.46,.065),rubber,.027)
    # Solid bent back panel, low broad silhouette, no headrest or guessed mesh holes.
    n=[20,12,6][LOD];vs=[]
    for layer in [0,.026]:
        for j in range(n+1):
            z=.48+j/n*.43
            for i in range(n+1):
                t=i/n;w=.45+.045*j/n
                vs.append(((t-.5)*w,.19+.055*j/n-.022*math.sin(math.pi*t)+layer,z))
    N=(n+1)**2;fs=[]
    for j in range(n):
        for i in range(n):
            a=j*(n+1)+i;fs.extend([(a,a+1,a+n+2,a+n+1),(a+N,a+n+1+N,a+n+2+N,a+1+N)])
    perimeter=list(range(n+1))+[j*(n+1)+n for j in range(1,n+1)]+[n*(n+1)+i for i in range(n-1,-1,-1)]+[j*(n+1) for j in range(n-1,0,-1)]
    for a,b in zip(perimeter,perimeter[1:]+perimeter[:1]):fs.append((a,a+N,b+N,b))
    o=mesh('Broad gently curved closed back',vs,fs,rubber,True)
    active(o);bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.mesh.normals_make_consistent(inside=False);bpy.ops.object.mode_set(mode='OBJECT');planar_uv(o)
    for x in [-.265,.265]:
        box('Arm pad',(x,-.015,.635),(.055,.31,.038),rubber,.016)
        box('Rear arm upright',(x,.115,.535),(.035,.035,.18),rubber,.008)
        box('Arm lower join',(x*.83,.13,.452),(.12,.035,.035),rubber,.007)
    cylinder('Seat post',(0,0,.26),.028,.30,black)
    for i in range(5):
        a=math.tau*i/5;end=Vector((.30*math.cos(a),.30*math.sin(a),.075))
        bar_between('Five star leg',(0,0,.14),end,.022,rubber)
        cylinder('Caster swivel',end,.014,.055,black)
        for side in [-1,1]:cylinder('Twin caster',(end.x+side*.018,end.y,.032),.032,.021,rubber,'X')

def shelf():
    # Truncated three-bay observed segment, not an invented full room-width shelf.
    for x in [-.915,-.305,.305,.915]:
        for y in [-.20,.20]:box('Thin square vertical frame',(x,y,1.10),(.025,.025,2.20),black,.001)
    for z in [.04,.48,.94,1.42,1.91,2.19]:
        box('Thin grey shelf tray',(0,0,z),(1.84,.425,.022),black,.001)
    for x in [-.61,0,.61]:
        for z in [.71,1.66]:
            box('Wood cubby back',(x,.194,z),(.585,.018,.445),board,.001)
            for dx in [-.288,.288]:box('Wood cubby side',(x+dx,0,z),(.016,.385,.445),board,.001)

def storage():
    box('Unmarked storage box',(0,0,.105),(.35,.26,.21),paper,.004)
    box('Separate shallow lid',(0,0,.211),(.36,.27,.022),paper,.003)

def case():
    box('Tall transport case body',(0,0,.19),(.62,.40,.36),rubber,.027)
    box('Wide lid',(0,0,.39),(.635,.415,.075),rubber,.023)
    box('Lid perimeter joint',(0,0,.352),(.64,.42,.014),black,.005)
    for x in [-.19,.19]:
        box('Front latch',(x,-.218,.345),(.049,.018,.075),black,.006)
    for x in [-.09,.09]:box('Handle mount',(x,-.221,.245),(.027,.027,.06),black,.005)
    box('Carry grip',(0,-.24,.26),(.20,.028,.028),rubber,.009)
    if LOD<2:
        for x in [-.235,.235]:box('Protective raised vertical rib',(x,-.205,.19),(.025,.014,.25),rubber,.006)

def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True);bpy.context.preferences.filepaths.save_version=0
    bpy.context.scene.unit_settings.system='METRIC'


def bounds():
    bpy.context.view_layer.update();objs=[o for o in bpy.context.scene.objects if o.type=='MESH']
    pts=[o.matrix_world@v.co for o in objs for v in o.data.vertices]
    bb=[[min(v[i] for v in pts) for i in range(3)],[max(v[i] for v in pts) for i in range(3)]]
    return objs,bb


def validate_meshes(objs):
    stats={'nonFiniteVertices':0,'degenerateFaces':0,'nonManifoldEdges':0,'inconsistentEdgeWinding':0,'inwardSolids':0,'unappliedModifiers':0}
    for o in objs:
        me=o.data;me.update()
        stats['nonFiniteVertices']+=sum(not all(math.isfinite(v) for v in p.co) for p in me.vertices)
        stats['degenerateFaces']+=sum(p.area<=1e-13 for p in me.polygons)
        edge_count=collections.Counter(tuple(sorted(e)) for p in me.polygons for e in p.edge_keys)
        edge_signs=collections.defaultdict(list)
        for p in me.polygons:
            verts=list(p.vertices)
            for a,b in zip(verts,verts[1:]+verts[:1]):edge_signs[tuple(sorted((a,b)))].append(a<b)
        stats['nonManifoldEdges']+=sum(n!=2 for n in edge_count.values())
        stats['inconsistentEdgeWinding']+=sum(len(v)!=2 or v[0]==v[1] for v in edge_signs.values())
        bm=bmesh.new();bm.from_mesh(me);vol=bm.calc_volume(signed=True);bm.free()
        stats['inwardSolids']+=int(vol<=0);stats['unappliedModifiers']+=len(o.modifiers)
        assert all(v==0 for v in stats.values()),(o.name,stats,vol)
    return stats


def render(name,composition=False):
    objs,bb=bounds();lo,hi=map(Vector,bb);center=(lo+hi)/2;size=max(hi-lo)
    floor=material('REVIEW ONLY neutral floor',(.35,.37,.37),0,.85)
    box('REVIEW ONLY floor',(0,0,lo.z-.023),(100,100,.04),floor)
    if composition:target=Vector((.35,.30,1.03));cam_pos=Vector((.12,-4.3,1.87));lens=30
    elif name=='photo_workshop_square_hole_board':target=center;cam_pos=center+Vector((.90,-1.80,.55))*size;lens=53
    else:target=center;cam_pos=center+Vector((1.15,-1.90,1.20))*size*1.12;lens=53
    bpy.ops.object.camera_add(location=cam_pos);cam=bpy.context.object;cam.data.lens=lens
    cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();bpy.context.scene.camera=cam
    extent=max(size,.40)
    for pos,power,rad in [((-1.6,-1.6,2.6),440,2.0),((1.8,.3,2.2),340,1.8),((-.5,2.3,1.5),360,1.4)]:
        bpy.ops.object.light_add(type='AREA',location=center+Vector(pos)*extent);o=bpy.context.object
        o.data.energy=power*extent*extent;o.data.shape='DISK';o.data.size=rad*extent
        o.rotation_euler=(target-o.location).to_track_quat('-Z','Y').to_euler()
    sc=bpy.context.scene;sc.world=bpy.data.worlds.new('Review soft world');sc.world.use_nodes=True
    sc.world.node_tree.nodes.get('Background').inputs['Color'].default_value=(.32,.36,.40,1)
    sc.world.node_tree.nodes.get('Background').inputs['Strength'].default_value=.40
    sc.render.engine='CYCLES';sc.cycles.device='CPU';sc.cycles.samples=40 if composition else 24;sc.cycles.use_denoising=False
    sc.render.resolution_x=1440 if composition else 900;sc.render.resolution_y=1000 if composition else 720
    sc.render.resolution_percentage=100;sc.view_settings.view_transform='AgX';sc.view_settings.exposure=-.6;sc.view_settings.exposure=-.6
    sc.render.image_settings.file_format='PNG';sc.render.filepath=str(REVIEW/(name+'.png'));bpy.ops.render.render(write_still=True)



# Content additions use authored solids only. The original photograph is not loaded.
def colors():
    global white,screen,red,green,card,silver
    palette()
    white=material('Warm white enclosure polymer',(.78,.79,.75),0,.42)
    screen=material('Inactive neutral dark display',(.012,.026,.032),.15,.22)
    red=material('Muted wire insulation red',(.30,.055,.025),0,.6)
    green=material('Unmarked dark circuit substrate',(.035,.09,.065),0,.7)
    card=material('Unprinted cardboard',(.37,.25,.13),0,.85)
    silver=material('Dull chassis metal',(.30,.32,.33),.7,.4)
    # Small deterministic packed material, not a photograph or brand texture.
    for m in [rubber,white,card]:
        tex=m.node_tree.nodes.new('ShaderNodeTexImage');tex.image=bpy.data.images.get('Synthetic pale laminate grain')
        # Texture is used only to subtly modulate roughness, retaining authored base color.
        m.node_tree.links.new(tex.outputs['Color'],m.node_tree.nodes.get('Principled BSDF').inputs['Roughness'])

def wire(name,pts,mat= None,r=.002):
    cu=bpy.data.curves.new(name,'CURVE');cu.dimensions='3D';cu.resolution_u=[10,6,3][LOD]
    cu.bevel_depth=r;cu.bevel_resolution=[2,1,0][LOD];cu.use_fill_caps=True
    sp=cu.splines.new('BEZIER');sp.bezier_points.add(len(pts)-1)
    for p,v in zip(sp.bezier_points,pts):p.co=v;p.handle_left_type='AUTO';p.handle_right_type='AUTO'
    o=bpy.data.objects.new(name,cu);bpy.context.collection.objects.link(o);active(o);bpy.ops.object.convert(target='MESH');finish(o,name,mat or rubber,True)
    bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=1e-6);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(o.data);bm.free()

def thin():
    box('Closed lower chassis',(0,0,.006),(.35,.24,.012),rubber,.004)
    box('Closed lid distinct seam',(0,.001,.015),(.346,.236,.006),black,.002)
    cylinder('Rear hinge',(0,.112,.011),.004,.29,black,'X')
    for x in [-.12,.12]:box('Underside foot',(x,-.075,.001),(.025,.012,.002),rubber,.0007)

def monitor():
    box('Wide low base',(0,0,.009),(.29,.21,.018),black,.009)
    box('Taper approximation support',(0,.035,.15),(.054,.042,.28),black,.009)
    box('Central mounting boss',(0,.035,.31),(.11,.07,.10),rubber,.008)
    box('Landscape rear shell',(0,0,.35),(.57,.035,.335),black,.008)
    box('Lower stepped rear housing',(0,.028,.28),(.48,.035,.18),rubber,.006)
    box('Upper rear horizontal inset',(-.18,.020,.455),(.10,.002,.018),black,.001)
    box('Front narrow bezel',(0,-.021,.35),(.563,.009,.328),rubber,.004)
    box('Inactive screen',(0,-.026,.355),(.537,.002,.293),screen,.001)
    wire('Stand cable descending',[(.10,.05,.26),(.07,.08,.18),(.03,.10,.05),(.18,.15,.004),(.31,.20,.003)])

def pc():
    # Opening faces -Y. All panels and rails individually closed, no fake solid cavity.
    for z in [.015,.435]:box('Top bottom chassis',(0,0,z),(.21,.42,.025),black,.004)
    box('Closed far side',(0,.202,.225),(.205,.012,.42),black,.003)
    for x in [-.098,.098]:
        for y in [-.195,.195]:box('Corner chassis rail',(x,y,.225),(.014,.018,.42),silver,.002)
    box('Front fascia',(0,-.202,.225),(.21,.018,.41),black,.004)
    # Actual open side lies X positive, visible from front-right camera.
    box('Mainboard tray',(-.09,0,.235),(.012,.35,.34),silver,.002)
    box('Unmarked board',(-.077,.02,.26),(.008,.28,.25),green,.001)
    box('Supply enclosure',(-.005,.10,.085),(.16,.17,.11),black,.004)
    for y in [-.10,-.065,-.03]:box('Expansion slot bracket',(.0,y,.20),(.16,.013,.024),silver,.002)
    for j in range(4):wire('Visible insulated harness '+str(j),[(.06,.12,.13),(.075,.05,.09),(.08,-.08,.10+j*.006),(.07,-.12,.30+j*.01)], [rubber,red,card,black][j],.002)
    for y in [-.13,.13]:box('Chassis foot',(0,y,.004),(.16,.035,.008),rubber,.002)

def whitecase():
    box('Unknown rounded white equipment body',(0,0,.27),(.32,.29,.51),white,.035)
    box('Dark bottom plinth',(0,0,.018),(.30,.27,.036),black,.01)
    box('Plain rear label silhouette',(0,-.147,.095),(.09,.001,.04),paper,.001)
    box('Small muted label silhouette',(.07,-.147,.08),(.025,.001,.013),red,.001)
    wire('Loose white equipment cable',[(.10,-.15,.30),(.15,-.18,.08),(.20,-.23,.006),(.32,-.30,.006),(.27,-.42,.006),(.12,-.39,.012)],white,.0025)

def desktop():
    # Tabletop coordinate group. Separately named, removable props, not a connected manufactured product.
    box('Unprinted dark instrument carton',(.40,.16,.065),(.30,.19,.13),rubber,.003)
    box('Cardboard exposed edge',(.40,.16,.131),(.299,.188,.003),card,.001)
    box('Stacked blank papers',(.39,.17,.138),(.29,.205,.008),paper,.001)
    box('Small white stand base',(-.45,.12,.005),(.085,.095,.01),white,.006)
    o=box('Small white stand back',(-.45,.15,.067),(.073,.009,.12),white,.004);o.rotation_euler.x=-.14
    box('Stand bottom retaining lip',(-.45,.10,.018),(.07,.014,.018),white,.003)
    box('White long electrical strip',(.12,.20,.015),(.23,.055,.03),white,.006)
    for x in [.05,.11,.17]:box('Recess visible no specific socket standard',(x,.20,.030),(.021,.019,.001),black,.001)
    box('White cuboid adapter',(.12,-.16,.02),(.033,.033,.04),white,.003)
    box('Flat cyan sign substrate',(.50,-.17,.004),(.42,.21,.008),material('Pale blue blank sign',(.26,.57,.65),0,.5),.004)
    for j in range(3):wire('Loose desktop cable '+str(j),[(-.38+j*.07,.10,.009),(-.18,.17+j*.02,.012),(.02,.06+j*.02,.012),(.21,.12-j*.04,.012),(.15,-.10,.009)],rubber,.002)

def transport():
    case()
    for x in [-.29,.29]:
        for y in [-.18,.18]:box('Impact corner protector',(x,y,.22),(.05,.05,.31),black,.011)

def enclosure():
    # Unknown function. Only visible dark panel and rounded outer frame.
    box('Unknown enclosure rear envelope',(0,.02,.17),(.39,.24,.32),white,.025)
    box('Dark front inset',(0,-.108,.17),(.365,.018,.285),black,.016)
    glazing=material('Smoked front panel',(.045,.057,.058),.1,.17)
    p=glazing.node_tree.nodes.get('Principled BSDF');p.inputs['Transmission Weight'].default_value=.32
    box('Smoked closed front without invented internals',(0,-.120,.17),(.335,.008,.255),glazing,.011)
    for x in [-.13,.13]:box('Small foot',(x,0,.006),(.035,.10,.012),rubber,.004)
    wire('Visible front cable',[(0,-.13,.10),(.02,-.17,.03),(.02,-.23,.005),(.09,-.29,.004)],rubber,.002)

ASSETS=[('lab_closed_thin_device',thin),('lab_stepped_monitor',monitor),('lab_open_pc_chassis',pc),('lab_unknown_white_case',whitecase),('lab_desktop_small_items',desktop),('lab_hard_transport_case',transport),('lab_window_unknown_enclosure',enclosure)]

def instance(asset,loc,rot=(0,0,0),group='photo_lab_contents',scale=(1,1,1)):
    path=ROOT/'sources/models'/group/asset/(asset+'.blend')
    with bpy.data.libraries.load(str(path),link=False) as(src,dst):dst.objects=src.objects
    imported=[o for o in dst.objects if o]
    for o in imported:bpy.context.collection.objects.link(o)
    bpy.context.view_layer.update()
    from mathutils import Euler
    m=Matrix.Translation(Vector(loc))@Euler(rot).to_matrix().to_4x4()@Matrix.Diagonal(Vector((*scale,1)))
    for o in imported:o.matrix_world=m@o.matrix_world.copy();o['instanceSource']=asset
    return dict(assetId=asset,sourcePath=str(path.relative_to(ROOT)),sourceSha256=hashlib.sha256(path.read_bytes()).hexdigest(),position=loc,rotationEuler=rot,scale=scale,materialOverrides={})

def composition():
    reset();layout=[]
    def add(a,p,r=(0,0,0),g='photo_lab_contents',s=(1,1,1)):layout.append(instance(a,p,r,g,s))
    old='photo_lab_center'
    add('photo_lab_center_four_leg_table',(0,0,0),g=old)
    add('photo_lab_center_four_leg_table',(0,1.16,0),g=old,s=(1,.54,1))
    add('photo_lab_center_black_task_chair',(-.59,-.80,0),(0,0,math.pi+.12),old)
    add('photo_lab_center_open_shelf',(1.48,.65,0),(0,0,-math.pi/2),old)
    for z in [.052,.492]:add('photo_lab_center_plain_storage_box',(1.47,.04,z),g=old)
    add('lab_closed_thin_device',(-.31,-.30,.75),(0,0,.06))
    add('lab_closed_thin_device',(.11,.35,.75),(0,0,-.045),s=(1.10,.91,.90))
    add('lab_stepped_monitor',(-.60,0,.75),(0,0,math.pi-.08))
    add('lab_stepped_monitor',(-.32,.39,.75),(0,0,.06),s=(.72,.72,.72))
    # Rear tall display uses the same source with vertical panel rearranged only by whole-source pose? no: keep generic rear monitor landscape.
    add('lab_stepped_monitor',(-.20,1.20,.75),(0,0,-.06),s=(.50,.70,1.3))
    add('lab_window_unknown_enclosure',(.32,1.14,.75),(0,0,.04))
    add('lab_desktop_small_items',(.08,-.01,.75))
    add('lab_open_pc_chassis',(-.38,-.04,0),(0,0,-.65))
    add('lab_unknown_white_case',(.48,.23,.006),(0,0,-.05))
    add('lab_hard_transport_case',(1.65,-1.01,-.01),(0,0,-.15))
    add('lab_hard_transport_case',(1.28,-.51,.32),(0,math.pi/2,.04))
    add('photo_keyboard',(-.62,.33,.75),(0,0,math.pi),'photo_desktop')
    add('photo_mouse',(-.84,.29,.75),(0,0,math.pi),'photo_desktop')
    for i,row in enumerate(layout):
        row['instanceId']='lab_contents_%02d'%i
        row['supportSurfaceId']='rear_table' if i in [10,11] else ('main_table' if i in [6,7,8,9,12,17,18] else ('shelf_low' if i==4 else ('shelf_middle' if i==5 else 'ground')))
        row['placementNote']='Photo-estimated contact; cable segments may rest on surface. Corner rail/foot contacts are intentional.'
    (OUT/'composition.json').write_text(json.dumps(dict(units='metres',coordinateSystem='Blender Z-up',dimensions='All photograph estimates, not measured',supportSurfaces=[dict(id='ground',z=0,boundsXY=[[-10,-10],[10,10]]),dict(id='main_table',z=.75,boundsXY=[[-1.1,-.5],[1.1,.5]]),dict(id='rear_table',z=.75,boundsXY=[[-1.1,.89],[1.1,1.43]]),dict(id='shelf_low',z=.052,boundsXY=[[1.2675,-.2825],[1.6925,1.5825]]),dict(id='shelf_middle',z=.492,boundsXY=[[1.2675,-.2825],[1.6925,1.5825]])],instances=layout),indent=2))
    bpy.ops.wm.save_as_mainfile(filepath=str(REVIEW/'lab_contents_composition.blend'))

def render_composition(angle):
    bpy.ops.wm.open_mainfile(filepath=str(REVIEW/'lab_contents_composition.blend'))
    floor=material('Review floor',(.32,.34,.35),0,.9);box('Review floor',(0,0,-.035),(200,200,.05),floor)
    target=Vector((.26,.25,1.00));pos=Vector((1.3,-5.4,2.70) if angle==1 else (-3.2,-4.6,2.9))
    bpy.ops.object.camera_add(location=pos);cam=bpy.context.object;cam.data.lens=44;cam.rotation_euler=(target-pos).to_track_quat('-Z','Y').to_euler();bpy.context.scene.camera=cam
    for p,power,size in [((-3,-4,6),1900,5),((4,1,5),1600,4),((0,4,4),1100,3)]:
        bpy.ops.object.light_add(type='AREA',location=p);o=bpy.context.object;o.data.energy=power;o.data.shape='DISK';o.data.size=size;o.rotation_euler=(target-o.location).to_track_quat('-Z','Y').to_euler()
    sc=bpy.context.scene;sc.world=bpy.data.worlds.new('Review world');sc.world.use_nodes=True;sc.world.node_tree.nodes['Background'].inputs[0].default_value=(.32,.36,.4,1);sc.world.node_tree.nodes['Background'].inputs[1].default_value=.35
    sc.render.engine='CYCLES';sc.cycles.device='CPU';sc.cycles.samples=32;sc.cycles.use_denoising=False;sc.render.resolution_x=1600;sc.render.resolution_y=1200;sc.render.resolution_percentage=100;sc.view_settings.view_transform='AgX';sc.view_settings.exposure=-.6
    sc.render.image_settings.file_format='PNG';sc.render.filepath=str(REVIEW/f'lab_contents_composition_{angle}.png');bpy.ops.render.render(write_still=True)

if '--composition-only' in sys.argv:
    composition()
    for a in [1,2]:render_composition(a)
    raise SystemExit
if '--render-only' not in sys.argv:
    for asset,build in ASSETS:
        CURRENT_FOLDER=OUT/asset;CURRENT_FOLDER.mkdir(parents=True,exist_ok=True)
        for LOD in range(3):
            reset();colors();build();objs,bb=bounds();v=validate_meshes(objs)
            for o in objs:o['assetId']=asset;o['scaleStatus']='Photograph estimate, not measured';o['reference']='Photo 3, original visually inspected; no photo pixels included'
            p=CURRENT_FOLDER/f'lod{LOD}_source.glb';bpy.ops.export_scene.gltf(filepath=str(p),export_format='GLB',export_extras=True,export_yup=True)
            records.append(dict(asset=asset,level=LOD,triangles=sum(len(p.vertices)-2 for o in objs for p in o.data.polygons),meshParts=len(objs),boundsBlenderXYZ=bb,validation=v,sha256=hashlib.sha256(p.read_bytes()).hexdigest()))
            if LOD==0:bpy.ops.wm.save_as_mainfile(filepath=str(CURRENT_FOLDER/(asset+'.blend')))
    for a,_ in ASSETS:
        t=[r['triangles'] for r in records if r['asset']==a];assert t[0]>t[1]>t[2],(a,t)
    (REVIEW/'build_report.json').write_text(json.dumps(dict(blender=bpy.app.version_string,records=records),indent=2))
    composition()
if '--skip-render' not in sys.argv:
    for a in [1,2]:render_composition(a)
