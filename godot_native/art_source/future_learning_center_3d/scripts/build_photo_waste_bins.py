"""Photographed paired waste-bin candidates. Blender 4.3.2, metric, CPU previews.

Only the user-supplied photograph informs this model. No image pixels are baked
into materials. Dimensions are an approximate visual interpretation, not a
measurement, product identity or capacity. Closed static lids; no internal
mechanism is asserted. The tiny category pictograms are omitted as unreadable.

Run: blender -b --factory-startup -t 4 --python scripts/build_photo_waste_bins.py
Optional: -- --skip-render / --render-only / --asset=waste_bin_blue
"""
import ast, bpy, math, json, hashlib, sys, struct, bmesh
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'sources/models/photo_living'
REVIEW = ROOT / 'review/photo_living'
REVIEW.mkdir(parents=True, exist_ok=True)
# Reuse the existing approved primitive/material helpers, without executing its
# original asset build loop, altering the file, or rebuilding any original asset.
HELPER = Path(__file__).with_name('build_photo_desktop.py')
parsed = ast.parse(HELPER.read_text())
helper_nodes = [node for node in parsed.body if isinstance(node, (ast.Import, ast.ImportFrom, ast.FunctionDef))]
H = {'__file__': str(HELPER), 'LOD': 0}
exec(compile(ast.Module(body=helper_nodes, type_ignores=[]), str(HELPER), 'exec'), H)
material, finish, box, cyl = (H[key] for key in ('material', 'finish', 'box', 'cyl'))
LOD = 0
CJK_FONT = Path('/usr/share/fonts/opentype/noto/NotoSansCJK-Bold.ttc')
EN_FONT = Path('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf')
REFERENCE = Path('reference-not-distributed')
REFERENCE_SHA256 = '9cfaad191fdc2ef00dd2ff277fe461a67378d5b32dafd36c5d63d88d5166f38a'  # Original private reference is not distributed.


def make_mesh(name, verts, faces, mat, smooth=True):
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    finish(obj, name, mat)
    for p in mesh.polygons:
        p.use_smooth = smooth
    return obj


def apply_bevel(obj, width, segments=None):
    """Cap all bevels by the smallest current object dimension."""
    bpy.context.view_layer.update()
    cap = min(float(v) for v in obj.dimensions) * .45
    modifier = obj.modifiers.new('Small molded edge fillet', 'BEVEL')
    modifier.width = min(width, cap)
    modifier.segments = segments or [3, 2, 1][LOD]
    modifier.limit_method = 'ANGLE'
    modifier.angle_limit = math.radians(25)
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.modifier_apply(modifier=modifier.name)
    return obj


def weighted_normals(obj):
    bpy.context.view_layer.objects.active = obj
    modifier = obj.modifiers.new('Molded planar face normals', 'WEIGHTED_NORMAL')
    modifier.keep_sharp = True
    modifier.weight = 50
    bpy.ops.object.modifier_apply(modifier=modifier.name)
    return obj


def rounded_rect(hw, hd, radius, count=None):
    n = count or [10, 6, 3][LOD]
    points = []
    for cx, cy, start in [(hw-radius, hd-radius, 0), (-hw+radius, hd-radius, 90),
                          (-hw+radius, -hd+radius, 180), (hw-radius, -hd+radius, 270)]:
        for i in range(n+1):
            a = math.radians(start + 90*i/n)
            points.append((cx + radius*math.cos(a), cy + radius*math.sin(a)))
    return points


def loft_rect(name, profiles, mat):
    rings = [rounded_rect(hw, hd, rad) for z, hw, hd, rad in profiles]
    n = len(rings[0])
    vertices = [(x, y, profile[0]) for ring, profile in zip(rings, profiles) for x, y in ring]
    faces = [tuple(range(n-1, -1, -1))]
    for j in range(len(rings)-1):
        for i in range(n):
            a, b = j*n+i, j*n+(i+1)%n
            faces.append((a, b, b+n, a+n))
    faces.append(tuple(range((len(rings)-1)*n, len(rings)*n)))
    return make_mesh(name, vertices, faces, mat)


def rounded_outline(points, radius, count=None):
    """Round both convex and concave outline corners by quadratic arcs."""
    result = []
    n = count or [5, 3, 2][LOD]
    for i, p in enumerate(points):
        p, before, after = Vector(p), Vector(points[i-1]), Vector(points[(i+1)%len(points)])
        d = min(radius, (before-p).length*.35, (after-p).length*.35)
        start = p+(before-p).normalized()*d
        end = p+(after-p).normalized()*d
        for j in range(n+1):
            t = j/n
            q = (1-t)**2*start + 2*(1-t)*t*p + t*t*end
            result.append(tuple(q))
    return result


def extrude_xz(name, coords, y_front, y_back, mat):
    n = len(coords)
    vs = [(x, y, z) for y in (y_front, y_back) for x, z in coords]
    # CCW XZ is facing toward -Y.
    fs = [tuple(range(n)), tuple(range(2*n-1, n-1, -1))]
    fs += [(i, i+n, (i+1)%n+n, (i+1)%n) for i in range(n)]
    return make_mesh(name, vs, fs, mat, False)


def make_palette(variant):
    global plastic, lid_plastic, pedal_plastic, bag, ink
    rgb = (.035, .043, .046) if variant == 'grey' else (.012, .080, .220)
    plastic = material(variant+' molded bin plastic', rgb, 0, .29)
    lid_plastic = material(variant+' lid molded plastic', tuple(v*1.08 for v in rgb), 0, .25)
    pedal_plastic = material(variant+' foot pedal plastic', tuple(v*.68 for v in rgb), 0, .38)
    bag = material('Black folded liner plastic', (.008, .009, .010), 0, .38)
    ink = material('Warm white category print', (.78, .81, .73), 0, .65)
    for mat in (plastic, lid_plastic, bag):
        p = mat.node_tree.nodes.get('Principled BSDF')
        p.inputs['Coat Weight'].default_value = .14 if mat == bag else .10
        p.inputs['Coat Roughness'].default_value = .33


def body_shell():
    body = loft_rect('Continuous tapered rounded bin shell', [
        (.000, .169, .193, .031),
        (.028, .172, .196, .033),
        (.130, .179, .205, .034),
        (.560, .205, .235, .036),
        (.705, .220, .250, .038),
        (.735, .223, .253, .039),
    ], plastic)
    # Visible front arch only. It is a backed recess, not an invented linkage.
    contour = [(-.085,-.012), (.085,-.012), (.085,.087), (.081,.108),
               (.067,.126), (.040,.137), (0,.141), (-.040,.137),
               (-.067,.126), (-.081,.108), (-.085,.087)]
    cutter = extrude_xz('Temporary pedal opening cutter', contour, -.34, -.124, plastic)
    bpy.context.view_layer.objects.active = body
    mod = body.modifiers.new('Arched pedal recess', 'BOOLEAN')
    mod.operation = 'DIFFERENCE'
    mod.solver = 'EXACT'
    mod.object = cutter
    bpy.ops.object.modifier_apply(modifier=mod.name)
    bpy.data.objects.remove(cutter, do_unlink=True)
    apply_bevel(body, .0026)
    weighted_normals(body)
    body['photoFeature'] = 'Tapered body with softly rounded corners and front foot recess'
    # The broad flange under the liner and lid is part of the molded silhouette.
    flange = loft_rect('Molded collar below the folded liner', [
        (.707, .224, .255, .038), (.713, .235, .268, .040),
        (.737, .236, .269, .040), (.744, .231, .264, .039)
    ], plastic)
    weighted_normals(flange)


def closed_lid():
    base = loft_rect('Shaped lid lip and sloping outer shoulder', [
        (.750, .231, .264, .043), (.753, .239, .272, .044),
        (.762, .241, .274, .044), (.771, .235, .268, .042),
        (.783, .226, .258, .039), (.791, .216, .247, .035),
        (.794, .211, .242, .032),
    ], lid_plastic)
    weighted_normals(base)
    # Photo-visible raised front deck and narrower stepped rear tongue.
    outline = rounded_outline([
        (-.186,-.223), (.186,-.223), (.192,-.201), (.192,.048),
        (.158,.091), (.158,.220), (-.158,.220), (-.158,.091),
        (-.192,.048), (-.192,-.201)
    ], .014)
    n = len(outline)
    vertices = []
    for z, scale in [(.788, 1.03), (.808, 1.00), (.820, .97)]:
        for x, y in outline:
            vertices.append((x*scale, y*scale, z + .004*(y+.223)/.443))
    faces = [tuple(range(n-1,-1,-1))]
    for row in range(2):
        for i in range(n):
            a, b = row*n+i, row*n+(i+1)%n
            faces.append((a,b,b+n,a+n))
    faces.append(tuple(range(2*n,3*n)))
    deck = make_mesh('Lid raised deck with stepped rear shoulders', vertices, faces, lid_plastic)
    apply_bevel(deck, .0025)
    weighted_normals(deck)
    for x in (-.174, .174):
        barrel = cyl('Visible rear lid hinge barrel', (x,.253,.793), .012, .041, plastic, 'X')
        apply_bevel(barrel, .001)
        weighted_normals(barrel)
    # An unobtrusive seam separates the lid and liner; no opening animation.
    base['staticClosedLid'] = True


def sample_outline(points, samples):
    distances = [(Vector(points[(i+1)%len(points)])-Vector(p)).length for i,p in enumerate(points)]
    total = sum(distances)
    result = []
    for j in range(samples):
        wanted = total*j/samples
        acc = 0
        for i,d in enumerate(distances):
            if acc+d >= wanted-1e-9:
                p = Vector(points[i]).lerp(Vector(points[(i+1)%len(points)]), (wanted-acc)/max(d,1e-9))
                result.append(p)
                break
            acc += d
    return result


def liner():
    samples = [240, 128, 64][LOD]
    rows = [9, 6, 4][LOD]
    outline = sample_outline(rounded_rect(.245,.278,.044,12), samples)
    vertices = []
    for row in range(rows):
        t = row/(rows-1)
        for i,p in enumerate(outline):
            a = math.tau*i/samples
            low = .697 + .0040*math.sin(7*a+.7) + .0024*math.sin(19*a+1.1)
            high = .754 + .0014*math.sin(11*a)
            z = (1-t)*low + t*high
            # Several incommensurate folds give an irregular draped band, not
            # a perfectly straight black ring or a regular toothed ribbon.
            radial = (.0010 + .0032*math.sin(17*a+3*t)
                      + .0020*math.sin(37*a-5*t) + .0008*math.sin(61*a+7*t))
            radial *= .45 + .55*math.sin(math.pi*t)
            s = 1 + radial/max(abs(p.x),abs(p.y))
            z += .0024*math.sin(13*a+7*t)*math.sin(math.pi*t)
            vertices.append((p.x*s,p.y*s,z))
    faces=[]
    for row in range(rows-1):
        for i in range(samples):
            a,b=row*samples+i,row*samples+(i+1)%samples
            faces.append((a,b,b+samples,a+samples))
    obj=make_mesh('Irregular black liner folded over the upper rim',vertices,faces,bag)
    sol=obj.modifiers.new('Thin folded liner thickness','SOLIDIFY')
    sol.thickness=.0007
    sol.offset=0
    bpy.context.view_layer.objects.active=obj
    bpy.ops.object.modifier_apply(modifier=sol.name)
    # Crumpled lower fold: another narrow strip with its own soft profile.
    pts=[]
    for row in range(3):
        for i,p in enumerate(outline):
            a=math.tau*i/samples
            z=.700 + .004*math.sin(7*a+.7)+.0024*math.sin(19*a+1.1)+row*.0032
            bump=(.001,.003,.001)[row] + .0012*math.sin(29*a)
            d=p.normalized()*bump
            pts.append((p.x+d.x,p.y+d.y,z))
    fs=[]
    for row in range(2):
        for i in range(samples):
            a,b=row*samples+i,row*samples+(i+1)%samples
            fs.append((a,b,b+samples,a+samples))
    lip=make_mesh('Soft folded lower edge of the liner',pts,fs,bag)
    sol=lip.modifiers.new('Fold thickness','SOLIDIFY');sol.thickness=.0006
    bpy.context.view_layer.objects.active=lip;bpy.ops.object.modifier_apply(modifier=sol.name)


def pedal():
    platform=loft_rect('Recessed rounded front foot pedal',[
        (.029,.066,.036,.011),(.037,.073,.040,.012),(.050,.071,.038,.012)
    ],pedal_plastic)
    platform.location.y=-.184
    weighted_normals(platform)
    if LOD<2:
        for j in range(5):
            box('Molded pedal grip rib %02d'%j,(0,-.211+j*.012,.051),(.111,.003,.002),pedal_plastic,.0007)
    else:
        for j in range(3):
            box('Molded pedal grip rib %02d'%j,(0,-.208+j*.023,.051),(.109,.003,.002),pedal_plastic,.0006)


def front_y(z):
    # Both printed labels and arrow geometry conform to the main front plane.
    if z <= .56:
        return -.205-(z-.13)*(.030/.430)
    return -.235-(z-.56)*(.015/.145)


def front_polygon(name, coords, centerz):
    n=len(coords)
    vertices=[]
    for d in (0,.00025):
        for x,z in coords:
            zz=z+centerz
            vertices.append((x,front_y(zz)-.0006-d,zz))
    faces=[tuple(range(n)),tuple(range(2*n-1,n-1,-1))]
    faces += [(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
    return make_mesh(name,vertices,faces,ink,False)


def category_mark():
    # Generic three-arrow mark, rebuilt as vector geometry from visible form.
    corners=[Vector((-.064,-.031)),Vector((.064,-.031)),Vector((0,.080))]
    for i,p in enumerate(corners):
        q=corners[(i+1)%3]
        d=(q-p).normalized();normal=Vector((-d.y,d.x))
        start=p+d*.013;tip=q-d*.009;neck=tip-d*.023
        poly=[start+normal*.0045,neck+normal*.0045,neck+normal*.012,
              tip,neck-normal*.012,neck-normal*.0045,start-normal*.0045]
        front_polygon('White triangular arrow %d'%(i+1),[tuple(v) for v in poly],.554)


def label(text,z,size,font_path,name):
    bpy.ops.object.text_add(location=(0,front_y(z)-.0007,z))
    obj=bpy.context.object;obj.name=name
    obj.data.body=text;obj.data.align_x='CENTER';obj.data.align_y='BOTTOM_BASELINE'
    obj.data.size=size;obj.data.resolution_u=[4,2,1][LOD]
    obj.data.extrude=0  # Flat printed lettering, not raised molded text.
    if font_path.is_file():obj.data.font=bpy.data.fonts.load(str(font_path))
    obj.data.materials.append(ink)
    obj.rotation_euler.x=math.pi/2+math.atan(.030/.430)
    bpy.ops.object.convert(target='MESH')
    # Scale by actual converted glyph width. CJK font em metrics differ from
    # Latin fonts; nominal point size alone made the first proof too small.
    xs=[v.co.x for v in obj.data.vertices]
    target_width=.136 if font_path==CJK_FONT else .129
    factor=target_width/(max(xs)-min(xs))
    center=(min(xs)+max(xs))/2
    for v in obj.data.vertices:
        v.co.x=(v.co.x-center)*factor
        v.co.y*=factor
    # Remove genuine zero-area glyph triangles before export. This is applied
    # to the mesh, not a relaxed downstream validator tolerance.
    bm=bmesh.new();bm.from_mesh(obj.data)
    bmesh.ops.triangulate(bm,faces=list(bm.faces))
    invalid=[]
    for f in bm.faces:
        a,b,c=(v.co for v in f.verts)
        if (b-a).cross(c-a).length < 1e-12:invalid.append(f)
    bmesh.ops.delete(bm,geom=invalid,context='FACES')
    loose_edges=[e for e in bm.edges if not e.link_faces]
    if loose_edges:bmesh.ops.delete(bm,geom=loose_edges,context='EDGES')
    loose_verts=[v for v in bm.verts if not v.link_edges]
    if loose_verts:bmesh.ops.delete(bm,geom=loose_verts,context='VERTS')
    bm.to_mesh(obj.data);bm.free();obj.data.update()
    obj['removedDegenerateGlyphTriangles']=len(invalid)
    obj['photoText']=text
    return obj


def build(variant):
    H['LOD']=LOD
    make_palette(variant)
    body_shell();closed_lid();liner();pedal();category_mark()
    label('其他垃圾' if variant=='grey' else '可回收物',.460,.030,CJK_FONT,'Visible Chinese category print')
    label('Other waste' if variant=='grey' else 'Recyclable',.434,.019,EN_FONT,'Visible English category print')
    for obj in bpy.context.scene.objects:
        if obj.type=='MESH':
            obj['assetId']='waste_bin_'+variant
            obj['source']='User photograph; visible features reconstructed, dimensions approximate'
            obj['staticReusableProp']=True
    bpy.context.view_layer.update()


def mesh_bounds():
    objects=[o for o in bpy.context.scene.objects if o.type=='MESH' and not o.get('renderOnly')]
    points=[o.matrix_world@v.co for o in objects for v in o.data.vertices]
    bb=[[min(p[i] for p in points) for i in range(3)],[max(p[i] for p in points) for i in range(3)]]
    return objects,bb


def record(asset,level,path):
    objs,bb=mesh_bounds()
    return {'asset':asset,'level':level,'triangles':sum(len(p.vertices)-2 for o in objs for p in o.data.polygons),
            'boundsBlenderXYZ':bb,'sizeBlenderXYZ':[bb[1][i]-bb[0][i] for i in range(3)],
            'meshParts':len(objs),'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),
            'sourceGLB':str(path.relative_to(ROOT))}


def render(name,pair=False):
    H['LOD']=0
    bpy.context.view_layer.update();_,bb=mesh_bounds()
    center=Vector(((bb[0][0]+bb[1][0])*.5,(bb[0][1]+bb[1][1])*.5,.42))
    stage=material('Preview only warm grey floor',(.33,.31,.27),0,.81)
    ground=box('Preview only studio ground',(0,0,-.014),(200,200,.026),stage,.001)
    ground['renderOnly']=True
    bpy.ops.object.camera_add(location=center+Vector((1.1,-2.05,1.35) if pair else (.95,-1.85,1.17)))
    cam=bpy.context.object;cam.rotation_euler=(center-cam.location).to_track_quat('-Z','Y').to_euler()
    cam.data.type='PERSP';cam.data.lens=58 if pair else 72
    bpy.context.scene.camera=cam
    for offset,power,size in [((-2.0,-2.5,4.2),420,3.1),((3.0,-.8,2.7),260,2.5),((-.6,2.0,2.8),300,2.0)]:
        bpy.ops.object.light_add(type='AREA',location=center+Vector(offset));lamp=bpy.context.object
        lamp.data.energy=power;lamp.data.shape='DISK';lamp.data.size=size
        lamp.rotation_euler=(center-lamp.location).to_track_quat('-Z','Y').to_euler()
    scene=bpy.context.scene
    scene.world=bpy.data.worlds.new('Soft neutral preview world');scene.world.use_nodes=True
    scene.world.node_tree.nodes['Background'].inputs['Color'].default_value=(.28,.30,.33,1)
    scene.world.node_tree.nodes['Background'].inputs['Strength'].default_value=.4
    scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=96
    scene.cycles.use_denoising=False
    scene.render.resolution_x=1400 if pair else 1100;scene.render.resolution_y=1100
    scene.render.resolution_percentage=100
    scene.view_settings.view_transform='AgX';scene.view_settings.exposure=0
    scene.render.image_settings.file_format='PNG';scene.render.filepath=str(REVIEW/(name+'.png'))
    bpy.ops.render.render(write_still=True)


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.preferences.filepaths.save_version=0
    bpy.context.scene.unit_settings.system='METRIC'
    bpy.context.scene.unit_settings.scale_length=1


def validate_outputs():
    report_file=REVIEW/'waste_bins_build_report.json'
    report=json.loads(report_file.read_text())
    rows=[]
    def check(ok,label,detail=None):
     rows.append({'pass':bool(ok),'label':label,'detail':detail})
     if not ok:print('FAILED:',label,detail)
    for rec in report['records']:
     path=ROOT/rec['sourceGLB'];data=path.read_bytes()
     check(hashlib.sha256(data).hexdigest()==rec['sha256'],str(path.name)+' '+rec['asset']+' recorded hash')
     json_len=struct.unpack_from('<I',data,12)[0];doc=json.loads(data[20:20+json_len])
     key=f"{rec['asset']} LOD{rec['level']}"
     check(not doc.get('images') and not doc.get('textures'),key+' has no baked photograph or other image textures')
     check(not doc.get('animations') and not doc.get('skins'),key+' is static and unrigged')
     triangles=sum(doc['accessors'][p['indices']]['count']//3 for mesh in doc['meshes'] for p in mesh['primitives'])
     check(triangles==rec['triangles'],key+' exported triangle count equals receipt',{'exported':triangles,'recorded':rec['triangles']})
     bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.gltf(filepath=str(path));bpy.context.view_layer.update()
     objs=[o for o in bpy.context.scene.objects if o.type=='MESH']
     points=[o.matrix_world@v.co for o in objs for v in o.data.vertices]
     bb=[[min(v[i] for v in points) for i in range(3)],[max(v[i] for v in points) for i in range(3)]]
     delta=max(abs(bb[j][i]-rec['boundsBlenderXYZ'][j][i]) for j in range(2) for i in range(3))
     check(delta<.000002,key+' reimported actual vertex bounds match receipt',delta)
     check(all(math.isfinite(c) for v in points for c in v),key+' vertices are finite')
     degenerate=0
     for obj in objs:
      obj.data.calc_loop_triangles()
      for triangle in obj.data.loop_triangles:
       a,b,c=[obj.matrix_world@obj.data.vertices[index].co for index in triangle.vertices]
       if (b-a).cross(c-a).length < 1e-12:degenerate+=1
     check(degenerate==0,key+' no triangles below cross-product norm 1e-12 square metres',degenerate)
     check(abs(bb[0][2])<.000002,key+' grounded origin')
     check(all(o.type not in ['CAMERA','LIGHT','ARMATURE'] for o in bpy.context.scene.objects),key+' asset has no preview camera, light or rig')
     body=next(o for o in objs if o.name.startswith('Continuous tapered rounded bin shell'))
     bm=bmesh.new();bm.from_mesh(body.data);volume=bm.calc_volume(signed=True);nonmanifold=sum(not e.is_manifold for e in bm.edges);bm.free()
     check(volume>0,key+' main shell outward winding',volume)
     # glTF may split normals into vertices at hard edges, so weld a copy for the topology test.
     bm=bmesh.new();bm.from_mesh(body.data);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=1e-6)
     nonmanifold=sum(not e.is_manifold for e in bm.edges);bm.free()
     check(nonmanifold==0,key+' main shell closed after exported-vertex welding',nonmanifold)
     vertices=[body.matrix_world@v.co for v in body.data.vertices];polys=[tuple(p.vertices) for p in body.data.polygons]
     tree=BVHTree.FromPolygons(vertices,polys)
     center=tree.ray_cast(Vector((0,-.5,.10)),Vector((0,1,0)))[0]
     side=tree.ray_cast(Vector((.12,-.5,.10)),Vector((0,1,0)))[0]
     recess=center.y-side.y if center and side else None
     check(recess is not None and recess>.06,key+' geometric front pedal recess depth',recess)
    for asset in sorted({r['asset'] for r in report['records']}):
     levels=[r['triangles'] for r in report['records'] if r['asset']==asset]
     check(levels[0]>levels[1]>levels[2],asset+' three strictly decreasing LOD counts',levels)
    report['validation']={'checks':len(rows),'failures':sum(not x['pass'] for x in rows),'rows':rows}
    report_file.write_text(json.dumps(report,indent=2,ensure_ascii=False)+'\n')
    print('WASTE_BIN_VALIDATION',json.dumps({'checks':len(rows),'failures':sum(not x['pass'] for x in rows)}))
    if any(not x['pass'] for x in rows):raise RuntimeError('Waste-bin output validation failed')


def main():
    global LOD
    if '--validate-only' in sys.argv:
        validate_outputs()
        return
    assets=[('waste_bin_grey','grey'),('waste_bin_blue','blue')]
    selected=[a for a in assets if not any(v.startswith('--asset=') for v in sys.argv) or '--asset='+a[0] in sys.argv]
    records=[]
    if '--render-only' not in sys.argv:
        for asset,variant in selected:
            folder=OUT/asset;folder.mkdir(parents=True,exist_ok=True)
            for LOD in range(3):
                reset();build(variant)
                path=folder/f'lod{LOD}_source.glb'
                bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',export_extras=True,export_yup=True,export_animations=False)
                records.append(record(asset,LOD,path))
                if LOD==0:
                    bpy.context.scene['assetId']=asset
                    bpy.context.scene['sourceImageId']='src_ref_e87f09491a0bf10060c8c575d9c03672'
                    bpy.context.scene['dimensionsStatus']='Approximate visual proportions only, not measured or manufacturer verified'
                    bpy.ops.wm.save_as_mainfile(filepath=str(folder/(asset+'.blend')))
        report={'blender':bpy.app.version_string,'units':'m','frontAxisBlender':'-Y','upAxisBlender':'+Z',
                'scope':'Two static reusable photo-referenced waste-bin variants. No changes to the original five assets or runtime integration.',
                'reference':{'library_file_id':'src_ref_e87f09491a0bf10060c8c575d9c03672',
                             'sha256':REFERENCE_SHA256,
                             'pixelsInspected':True},
                'assumptions':['Approximate scale and proportions; no ruler, brand, capacity or manufacturer identification.',
                               'Only visible front and top features are reconstructed. Closed-lid props do not assert hidden operating mechanics.',
                               'Small disposal pictograms are not legible enough to reproduce reliably and are omitted.',
                               'Grey and blue share construction with separate material variants. Chinese and English category text is mesh geometry.'],
                'textures':{'photographBaked':False,'imageTextureCount':0},
                'render':{'engine':'Cycles','device':'CPU','visualInspection':'Pending visual inspection'},
                'records':records}
        (REVIEW/'waste_bins_build_report.json').write_text(json.dumps(report,indent=2,ensure_ascii=False)+'\n')
        validate_outputs()
    if '--skip-render' not in sys.argv:
        for asset,variant in selected:
            bpy.ops.wm.open_mainfile(filepath=str(OUT/asset/(asset+'.blend')))
            render(asset)
        if len(selected)==2:
            reset();LOD=0
            for asset,variant,offset in [('waste_bin_grey','grey',(-.254,.045,0)),('waste_bin_blue','blue',(.254,-.045,0))]:
                before=set(bpy.context.scene.objects);build(variant)
                for obj in set(bpy.context.scene.objects)-before:obj.location+=Vector(offset)
            render('waste_bins_pair',True)

if __name__=='__main__':main()
