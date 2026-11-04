"""Photo-derived workshop props. Blender 4.3.2; metres are visual estimates.
Run: blender -b --factory-startup -t 4 --python scripts/build_photo_workshop.py
Flags: --skip-render, --render-only, --composition-only, --asset=<id>.
Source photographs are reference only, never texture inputs. No main-scene changes.
"""
import bpy, bmesh, math, json, hashlib, sys, collections
import numpy as np
from pathlib import Path
from mathutils import Vector, Matrix

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'sources/models/photo_workshop'
REVIEW=ROOT/'review/photo_workshop'
OUT.mkdir(parents=True,exist_ok=True);REVIEW.mkdir(parents=True,exist_ok=True)
LOD=0;CURRENT_FOLDER=OUT;records=[]


def material(name,color,metal=0,rough=.5):
    m=bpy.data.materials.new(name);m.use_nodes=True;m.diffuse_color=(*color,1)
    p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1)
    p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=rough
    return m


def palette():
    global green,black,steel,grey,rubber,red,blue,iron,mat_rubber
    green=material('Deep green powder coated steel',(.008,.115,.074),.35,.37)
    black=material('Black powder coated sheet steel',(.013,.017,.018),.25,.48)
    steel=material('Brushed silver metal',(.52,.56,.57),.88,.25)
    grey=material('Grey caster hubs',(.20,.23,.23),.65,.32)
    rubber=material('Dark moulded polymer',(.009,.012,.012),0,.69)
    red=material('Red moulded tool case and latches',(.53,.024,.031),0,.46)
    blue=material('Blue anodised driver grips',(.012,.31,.44),.65,.31)
    iron=material('Dark cast iron vise',(.032,.035,.035),.65,.62)
    mat_rubber=material('Small tiled rubber work mat',(.019,.022,.022),0,.82)
    # One tiny, packed, repeating normal tile. No reference-image pixels or text.
    n=128;v,u=np.meshgrid(np.arange(n)/n,np.arange(n)/n,indexing='ij')
    h=np.cos(2*math.pi*u)*np.cos(2*math.pi*v)
    dx=-2*math.pi*np.sin(2*math.pi*u)*np.cos(2*math.pi*v)*.19
    dy=-2*math.pi*np.cos(2*math.pi*u)*np.sin(2*math.pi*v)*.19
    normal=np.stack((-dx,-dy,np.ones_like(h)),axis=-1);normal/=np.linalg.norm(normal,axis=-1,keepdims=True)
    pixels=np.ones((n,n,4),np.float32);pixels[:,:,:3]=normal*.5+.5
    im=bpy.data.images.new('Synthetic repeating rubber stipple',width=n,height=n,alpha=True)
    im.colorspace_settings.name='Non-Color';im.pixels.foreach_set(pixels.ravel())
    im.filepath_raw=str(CURRENT_FOLDER/'synthetic_rubber_tile.png');im.file_format='PNG';im.save();im.pack()
    tex=mat_rubber.node_tree.nodes.new('ShaderNodeTexImage');tex.image=im;tex.extension='REPEAT'
    nm=mat_rubber.node_tree.nodes.new('ShaderNodeNormalMap');nm.inputs['Strength'].default_value=.28
    mat_rubber.node_tree.links.new(tex.outputs['Color'],nm.inputs['Color'])
    mat_rubber.node_tree.links.new(nm.outputs['Normal'],mat_rubber.node_tree.nodes.get('Principled BSDF').inputs['Normal'])
    mat_rubber['textureProvenance']='Authored 128-pixel tile, no photograph pixels.'


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


def tool_cart():
    # Cabinet body is closed; photographed partly opened lower drawer is represented closed.
    box('Green enclosed cabinet body',(0,0,.502),(.78,.46,.754),green,.006)
    box('Black recessed drawer surround',(0,-.234,.492),(.704,.012,.659),black,.003)
    for i,z in enumerate([.795,.706,.617,.528,.439]):
        box('Shallow black drawer %02d'%(i+1),(0,-.247,z),(.670,.025,.078),rubber,.004)
        box('Aluminium full width pull %02d'%(i+1),(0,-.268,z+.027),(.665,.019,.020),steel,.004)
        if LOD<2:box('Pull underside shadow %02d'%(i+1),(0,-.275,z+.019),(.645,.004,.005),black,.001)
    box('Deep lower black drawer',(0,-.247,.270),(.670,.025,.238),rubber,.005)
    box('Deep lower drawer aluminium pull',(0,-.268,.375),(.665,.019,.020),steel,.004)
    # Empty manufacturer panel is intentionally omitted rather than inventing brand lettering.
    cylinder('Small silver lock',(0,-.239,.858),.010,.007,steel,'Y')
    if LOD<2:box('Lock key slot',(0,-.244,.858),(.0018,.001,.006),black)
    box('Rubber top work mat',(0,0,.885),(.737,.425,.013),mat_rubber,.003,.007)
    for x in [-.379,.379]:box('Raised side rim '+str(x),(x,0,.891),(.020,.46,.034),green,.003)
    box('Raised back top rim',(0,.220,.891),(.756,.020,.034),green,.003)
    box('Front top rim',(0,-.220,.887),(.756,.020,.025),green,.003)
    for x in [-.305,.305]:
        for y in [-.158,.158]:
            cylinder('Caster rubber tyre',(x,y,.056),.052,.031,rubber,'X')
            cylinder('Caster grey outer hub',(x-.018,y,.056),.038,.004,grey,'X')
            cylinder('Caster axle cap',(x-.022,y,.056),.008,.005,steel,'X')
            for side in [-1,1]:box('Caster fork plate',(x+side*.021,y,.090),(.008,.037,.065),grey,.004)
            box('Caster swivel bracket',(x,y,.125),(.057,.056,.014),grey,.004)
            if LOD<2:cylinder('Caster swivel bearing',(x,y,.137),.024,.014,steel)
    # Left accessory tray is visible in both supplied close views.
    box('Left side tray floor',(-.479,0,.664),(.180,.390,.013),green,.003)
    box('Left side tray outer wall',(-.563,0,.713),(.012,.390,.105),green,.003)
    for y in [-.188,.188]:box('Left side tray end wall',(-.479,y,.707),(.180,.013,.092),green,.003)
    for y in [-.135,.135]:box('Left tray mount',(-.400,y,.719),(.023,.031,.102),green,.004)
    # Narrow push handle visible on the right cabinet edge.
    cylinder('Silver right push handle',(.430,0,.810),.014,.344,steel,'Y')
    for y in [-.156,.156]:bar_between('Push handle bracket',(.382,y,.810),(.430,y,.810),.010,green)
    if LOD==0:
        for x in [-.359,.359]:
            for z in [.165,.845]:cylinder('Front frame fastener',(x,-.235,z),.004,.003,steel,'Y',n=12)


def perforated_board():
    # Mesh is one continuous watertight plate with true 24 x 18 square through-holes.
    nx,nz=24,18;pitch=.030;hole=.0095;w=.77;h=.635;t=.003
    xs=[-w/2]
    for j in range(nx):c=(j-(nx-1)/2)*pitch;xs.extend([c-hole/2,c+hole/2])
    xs.append(w/2);zs=[0]
    for j in range(nz):c=.047+(j+.5)*pitch;zs.extend([c-hole/2,c+hole/2])
    zs.append(h);W=len(xs);H=len(zs);vs=[(x,y,z) for y in [-t/2,t/2] for z in zs for x in xs]
    def ix(i,j,side):return side*W*H+j*W+i
    solid={(i,j) for i in range(W-1) for j in range(H-1) if not(i%2==1 and j%2==1)};fs=[]
    for i,j in solid:
        a,b,c,d=ix(i,j,0),ix(i+1,j,0),ix(i+1,j+1,0),ix(i,j+1,0)
        A,B,C,D=[k+W*H for k in [a,b,c,d]]
        fs.extend([(a,b,c,d),(D,C,B,A)])
        if (i-1,j) not in solid:fs.append((a,d,D,A))
        if (i+1,j) not in solid:fs.append((c,b,B,C))
        if (i,j-1) not in solid:fs.append((b,a,A,B))
        if (i,j+1) not in solid:fs.append((d,c,C,D))
    o=mesh('432 actual square holes in black sheet steel',vs,fs,black)
    # Fix all component orientation coherently; manifold checker runs after final construction.
    bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.recalc_face_normals(bm,faces=bm.faces);bm.to_mesh(o.data);bm.free()
    if LOD<2:bevel(o,.00035,2 if LOD==0 else 1)
    planar_uv(o)
    for x in [-.386,.386]:box('Folded vertical edge stiffener',(x,.006,h/2),(.016,.023,h),black,.001)
    box('Top folded edge',(0,.006,h),(.785,.023,.015),black,.001)
    box('Bottom mounting rail',(0,.011,.008),(.785,.028,.021),black,.002)
    for x in [-.365,.365]:
        for z in ([.065,.32,.585] if LOD<2 else [.065,.585]):
            cylinder('Silver mounting bolt',(x,-.004,z),.005,.004,steel,'Y',n=[24,12,8][LOD])
    o['squareHoleCount']=432;o['holeGeometry']='True watertight perforations at every LOD'


def driver_rack():
    # Eight visible representative blue drivers, without claiming a complete tool inventory.
    width=.314
    box('Black rack base',(0,0,.008),(width,.100,.016),black,.004)
    for x in [-.152,.152]:box('Rack upright',(x,.013,.084),(.010,.076,.160),black,.002)
    for z in [.062,.142]:
        for y in [-.028,.028]:box('Rack horizontal holder rail',(0,y,z),(width,.009,.010),black,.002)
        for x in [-.145+i*.0363 for i in range(9)]:box('Rack slot divider',(x,0,z),(.005,.052,.009),black,.001)
    for i in range(8):
        x=(i-3.5)*.0363;yy=.003;shaft_top=.148;top=.280+(i%3)*.005
        cylinder('Driver %02d polished shaft'%i,(x,yy,.086),.0027,.136,steel)
        if LOD<2:
            tip=box('Driver %02d short flat tip'%i,(x,yy,.014),(.0045,.0017,.011),grey,.0003)
        rings=[(shaft_top,.0095),(shaft_top+.005,.013),(shaft_top+.018,.0125),(top-.026,.0125),(top-.021,.013),(top-.005,.013),(top,.0106)]
        if LOD==2:rings=[rings[j] for j in [0,1,3,4,6]]
        lathe('Blue anodised grip %02d'%i,x,yy,rings,blue,flutes=.032 if LOD==0 else 0)
        for k in range(3 if LOD<2 else 1):
            cylinder('Silver grip collar %02d %d'%(i,k),(x,yy,top-.009-k*.0045),.0133,.0024,steel)
        cylinder('Blue rotating end cap %02d'%i,(x,yy,top+.003),.0135,.006,blue)
        if LOD==0:
            # Explicit shallow grip ribs do not rely on a painted-on cylindrical silhouette.
            for z in [shaft_top+.022+j*.006 for j in range(12)]:
                cylinder('Grip fine annular rib %02d'%i,(x,yy,z),.01285,.0010,blue,n=24)
    for x in [-.147,.147]:cylinder('Rack assembly screw',(x,-.027,.149),.0032,.004,steel)


def rib(name,a,b,width,z,height,mat):
    mid=(Vector(a)+Vector(b))/2;o=box(name,(mid.x,mid.y,z),((Vector(b)-Vector(a)).length,width,height),mat,min(width,height)/3)
    d=Vector(b)-Vector(a);o.rotation_euler.z=math.atan2(d.y,d.x);return o


def red_case():
    box('Red shallow lower shell',(0,0,.018),(.420,.200,.036),red,.009)
    box('Dark red case split seam',(0,0,.036),(.409,.191,.0035),rubber,.003)
    box('Red fitted shallow lid',(0,0,.044),(.420,.200,.016),red,.006)
    # Raised zig-zag stiffening ribs match the lid's visible motif, not invented lettering.
    for i,(a,b) in enumerate([((-.172,-.060),(-.086,.051)),((-.086,.051),(.006,-.060)),((.006,-.060),(.096,.051)),((.096,.051),(.177,-.044))]):
        rib('Moulded diagonal lid rib '+str(i),a,b,.006,.053,.004,red)
    for x in [-.145,.145]:
        box('Small red front closure',(x,-.101,.031),(.044,.007,.022),red,.003)
        if LOD<2:box('Red closure thumb ledge',(x,-.107,.028),(.028,.005,.005),red,.001)
        cylinder('Red rear hinge',(x,.099,.035),.006,.054,red,'X')
    if LOD==0:
        for y in [-.077,.077]:box('Fine lid edge raised rib',(0,y,.053),(.370,.002,.002),red,.0005)


def black_red_case():
    box('Black lower molded shell',(0,0,.019),(.330,.198,.038),rubber,.007)
    box('Black case split line',(0,0,.0385),(.331,.199,.003),black,.001)
    box('Black upper lid',(0,0,.052),(.330,.198,.026),rubber,.006)
    box('Recessed upper lid panel',(0,0,.065),(.288,.156,.004),black,.009)
    for y in [-.080,.080]:box('Moulded long top bumper',(0,y,.068),(.300,.008,.005),rubber,.002)
    for x in [-.124,.124]:
        box('Bright red clasp',(x,-.102,.040),(.033,.012,.038),red,.003)
        if LOD<2:
            box('Clasp inset grip',(x,-.109,.043),(.020,.003,.013),red,.001)
            box('Clasp lower catch',(x,-.109,.026),(.025,.004,.004),red,.001)
        cylinder('Rear case hinge',(x,.100,.038),.007,.036,black,'X')
    # Slim closed carry loop with genuine open center, manufactured from three solids.
    for x in [-.045,.045]:box('Carry handle root',(x,-.117,.039),(.012,.028,.014),rubber,.004)
    box('Carry handle crossbar',(0,-.130,.039),(.102,.012,.014),rubber,.004)
    if LOD==0:
        for x in [-.135,-.12,.12,.135]:box('Top anti-slip shell groove',(x,0,.068),(.0015,.132,.002),rubber,.0004)


def small_vise():
    cylinder('Cast iron swivel base',(0,.020,.016),.058,.032,iron)
    for x in [-.065,.065]:
        box('Vise mounting lug',(x,.023,.016),(.030,.043,.025),iron,.009)
        if LOD<2:cylinder('Mount bolt head',(x,.023,.032),.006,.008,steel,n=6)
    box('Low cast iron slide bed',(0,.002,.042),(.082,.133,.045),iron,.007)
    box('Vise polished sliding runner',(0,-.024,.067),(.045,.139,.020),grey,.003)
    box('Rear fixed jaw casting',(0,.052,.088),(.086,.040,.079),iron,.007)
    box('Front movable jaw casting',(0,-.021,.088),(.086,.038,.079),iron,.007)
    box('Fixed steel jaw plate',(0,.028,.116),(.086,.008,.025),steel,.0015)
    box('Moving steel jaw plate',(0,.002,.116),(.086,.008,.025),steel,.0015)
    cylinder('Vise screw shaft',(0,-.087,.065),.009,.107,steel,'Y')
    cylinder('Round handle boss',(0,-.146,.065),.015,.016,iron,'Y')
    cylinder('Sliding cross handle',(0,-.156,.065),.0035,.128,steel,'X')
    for x in [-.068,.068]:cylinder('Handle end stop',(x,-.156,.065),.0065,.007,steel,'X')
    if LOD<2:
        for y in [-.055-j*.008 for j in range(8)]:cylinder('Visible screw ridge',(0,y,.065),.0106,.0025,grey,'Y',n=20 if LOD==0 else 12)
    if LOD==0:
        for x in [-.028,.028]:
            for y in [.023,.007]:cylinder('Jaw plate screw',(x,y,.116),.0025,.0018,grey,'Y',n=12)


ASSETS=[('photo_workshop_green_tool_cart',tool_cart),('photo_workshop_square_hole_board',perforated_board),('photo_workshop_blue_driver_rack',driver_rack),('photo_workshop_red_flat_case',red_case),('photo_workshop_black_red_case',black_red_case),('photo_workshop_small_vise',small_vise)]


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


def instance(asset,loc,yaw=0):
    with bpy.data.libraries.load(str(OUT/asset/(asset+'.blend')),link=False) as(src,dst):dst.objects=src.objects
    imported=[o for o in dst.objects if o]
    for o in imported:bpy.context.collection.objects.link(o)
    bpy.context.view_layer.update();transforms=[(o,o.matrix_world.copy()) for o in imported]
    m=Matrix.Translation(Vector(loc))@Matrix.Rotation(yaw,4,'Z')
    for o,original in transforms:o.matrix_world=m@original
    bpy.context.view_layer.update()


def render(name,composition=False):
    objs,bb=bounds();lo,hi=map(Vector,bb);center=(lo+hi)/2;size=max(hi-lo)
    floor=material('REVIEW ONLY neutral floor',(.35,.37,.37),0,.85)
    box('REVIEW ONLY floor',(0,0,lo.z-.023),(100,100,.04),floor)
    if composition:target=Vector((.0,.0,.82));cam_pos=Vector((2.95,-4.35,2.75));lens=47
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
    sc.render.engine='CYCLES';sc.cycles.device='CPU';sc.cycles.samples=96 if composition else 32;sc.cycles.use_denoising=False
    sc.render.resolution_x=1440 if composition else 1000;sc.render.resolution_y=1080 if composition else 800
    sc.render.resolution_percentage=100;sc.view_settings.view_transform='AgX';sc.view_settings.exposure=-.6
    sc.render.image_settings.file_format='PNG';sc.render.filepath=str(REVIEW/(name+'.png'));bpy.ops.render.render(write_still=True)


def composition():
    reset()
    for x in [-.64,.64]:
        instance('photo_workshop_green_tool_cart',(x,0,0))
        instance('photo_workshop_square_hole_board',(x,.207,.912))
    # Same source instance on both carts; separate source case is used for each stack layer.
    for z in [.901,.970]:instance('photo_workshop_black_red_case',(-.64,.08,z),-.04)
    instance('photo_workshop_blue_driver_rack',(.415,.125,.901))
    instance('photo_workshop_small_vise',(.77,.117,.901),math.pi/2)
    for z in [.901,.958,1.015]:instance('photo_workshop_red_flat_case',(.775,-.112,z),-.06)
    bpy.context.view_layer.update();validate_meshes([o for o in bpy.context.scene.objects if o.type=='MESH'])
    bpy.ops.wm.save_as_mainfile(filepath=str(REVIEW/'photo_workshop_composition.blend'))
    render('photo_workshop_two_carts',True)


selected=[a for a in sys.argv if a.startswith('--asset=')]
if '--render-only' not in sys.argv:
    for asset,build in ASSETS:
        if selected and '--asset='+asset not in selected:continue
        CURRENT_FOLDER=OUT/asset;CURRENT_FOLDER.mkdir(parents=True,exist_ok=True)
        for LOD in range(3):
            reset();palette();build();objs,bb=bounds();validation=validate_meshes(objs)
            for o in objs:
                o['assetId']=asset;o['scaleStatus']='Photographic estimate, not surveyed';o['reference']='Workshop photos 4 and 5 supplied by user 2026-11-03'
            p=CURRENT_FOLDER/f'lod{LOD}_source.glb'
            bpy.ops.export_scene.gltf(filepath=str(p),export_format='GLB',export_extras=True,export_yup=True)
            record={'asset':asset,'level':LOD,'triangles':sum(len(p.vertices)-2 for o in objs for p in o.data.polygons),'boundsBlenderXYZ':bb,'sizeBlenderXYZ':[bb[1][i]-bb[0][i] for i in range(3)],'meshParts':len(objs),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'validation':validation}
            records.append(record)
            if LOD==0:bpy.ops.wm.save_as_mainfile(filepath=str(CURRENT_FOLDER/(asset+'.blend')))
    report={'blender':bpy.app.version_string,'units':'m','referenceLibraryIds':['src_ref_750145fd053312e5110b3b2e85b0f9f3','src_ref_e93491da63b7c6cd6a712c836ff473a8'],'referencePixelsViewed':True,'dimensions':'Photo-proportion estimates only. No claimed manufacturer measurements, brand, model or tool performance specifications.','scope':'Six separate workshop prop sources. Cabinet variants share one model. No old assets, main scene, UI, Godot, collision or runtime integration touched.','materials':'Metallic-roughness PBR factors; cabinet mat uses a packed, authored 128-square repeating normal tile. No photograph pixels, personal text, brands or labels.','render':'Actual CPU Cycles single assets and two-cart assembly.','simplifications':['Closed drawers and cases; no hidden slide mechanisms or inferred contents.','Eight representative blue drivers preserve the photographed cluster; full inventory and tip types are not asserted.','Square holes remain genuine continuous perforations at all three LODs.','Partially obscured goggles, electronics, calipers and suspended circular items are omitted.'],'records':records}
    path=REVIEW/'build_report.json'
    if selected and path.exists():
        prior=json.loads(path.read_text());report['records']=[r for r in prior['records'] if '--asset='+r['asset'] not in selected]+records
    for asset,build in ASSETS:
        rows=sorted([r for r in report['records'] if r['asset']==asset],key=lambda r:r['level'])
        if rows:assert rows[0]['triangles']>rows[1]['triangles']>rows[2]['triangles'],(asset,rows)
    path.write_text(json.dumps(report,indent=2))
if '--skip-render' not in sys.argv:
    if '--composition-only' not in sys.argv:
        for asset,build in ASSETS:
            if selected and '--asset='+asset not in selected:continue
            bpy.ops.wm.open_mainfile(filepath=str(OUT/asset/(asset+'.blend')));render(asset)
    if not selected or '--composition-only' in sys.argv:composition()
