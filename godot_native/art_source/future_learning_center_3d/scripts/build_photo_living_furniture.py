"""Photo living furniture, independent Blender 4.3.2 sources. Units: estimated metres.

The source photograph is visual reference only. Its pixels are never used as textures.
Wood maps below are deterministic synthetic grain, with factor-based metallic/roughness.
Run: blender -b --factory-startup -t 4 --python scripts/build_photo_living_furniture.py
Optional: --skip-render, --render-only, --asset=photo_living_capsule_table, --composition-only
"""
import bpy, math, json, hashlib, random, sys, collections
import numpy as np
from pathlib import Path
from mathutils import Vector, Matrix

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'sources/models/photo_living'
REVIEW = ROOT / 'review/photo_living'
OUT.mkdir(parents=True, exist_ok=True)
REVIEW.mkdir(parents=True, exist_ok=True)
LOD = 0
CURRENT_FOLDER = OUT
records = []

def material(name, color, metal=0., rough=.5):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    m.diffuse_color = (*color, 1)
    p = m.node_tree.nodes.get('Principled BSDF')
    p.inputs['Base Color'].default_value = (*color, 1)
    p.inputs['Metallic'].default_value = metal
    p.inputs['Roughness'].default_value = rough
    return m

def grain_material(name, low, high, rough=.48):
    m = material(name, tuple((a+b)*.5 for a,b in zip(low,high)), 0, rough)
    n = [768,384,192][LOD]
    u,v = np.meshgrid(np.linspace(0,1,n), np.linspace(0,1,n))
    warp = u + .010*np.sin(v*13+u*9) + .003*np.sin(v*37+u*14)
    grain = .5 + .07*np.sin(warp*185) + .11*np.sin(warp*687+v*4) + .10*np.sin(warp*1801+v*13)
    grain += .04*np.random.default_rng(612).normal(size=(n,n))
    grain = np.clip(grain,0,1)
    # Blender image pixels are linear light; exporter embeds a normal sRGB PNG.
    pixels = np.ones((n,n,4),dtype=np.float32)
    for k in range(3): pixels[:,:,k] = low[k] + grain*(high[k]-low[k])
    im = bpy.data.images.new(name+' synthetic grain',width=n,height=n,alpha=True)
    im.pixels.foreach_set(pixels.ravel())
    im.filepath_raw = str(CURRENT_FOLDER / (name.lower().replace(' ','_') + f'_lod{LOD}.png'))
    im.file_format = 'PNG'; im.save(); im.pack()
    node = m.node_tree.nodes.new('ShaderNodeTexImage'); node.image = im
    m.node_tree.links.new(node.outputs['Color'],m.node_tree.nodes.get('Principled BSDF').inputs['Base Color'])
    if name == 'Charcoal wood':
        # Synthetic shallow wood-fibre relief. A standard tangent normal texture exports to glTF.
        dv,du=np.gradient(grain)
        normals=np.stack((-du*n*.0018,-dv*n*.0018,np.ones_like(grain)),axis=-1)
        normals/=np.linalg.norm(normals,axis=-1,keepdims=True)
        pixels[:,:,:3]=normals*.5+.5
        normal=bpy.data.images.new(name+' synthetic tangent normal',width=n,height=n,alpha=True)
        normal.colorspace_settings.name='Non-Color';normal.pixels.foreach_set(pixels.ravel())
        normal.filepath_raw=str(CURRENT_FOLDER/('charcoal_wood_normal_lod'+str(LOD)+'.png'))
        normal.file_format='PNG';normal.save();normal.pack()
        tex=m.node_tree.nodes.new('ShaderNodeTexImage');tex.image=normal
        nm=m.node_tree.nodes.new('ShaderNodeNormalMap');nm.inputs['Strength'].default_value=.42
        m.node_tree.links.new(tex.outputs['Color'],nm.inputs['Color'])
        m.node_tree.links.new(nm.outputs['Normal'],m.node_tree.nodes.get('Principled BSDF').inputs['Normal'])
    m['textureProvenance'] = 'Locally authored deterministic synthetic grain. No source photograph pixels.'
    return m

def palette():
    global charcoal, oak, pale, caramel, orange, black, rubber, soil, bark, leafmats
    charcoal = grain_material('Charcoal wood',(.12,.135,.13),(.22,.24,.23),.78)
    oak = grain_material('Natural oak plywood',(.55,.43,.29),(.66,.53,.37),.55)
    pale = grain_material('Pale ash shell',(.66,.59,.45),(.77,.70,.55),.53)
    caramel = material('Caramel upholstered seat',(.20,.085,.035),0,.68)
    orange = material('Burnt orange woven seat',(.45,.08,.014),0,.88)
    black = material('Black powder coated tubular frame',(.008,.011,.010),.05,.53)
    rubber = material('Black matte rubber and polymer',(.017,.020,.019),0,.73)
    soil = material('Dark potting soil',(.037,.026,.015),0,.98)
    bark = material('Brown branching stems',(.115,.078,.035),0,.92)
    leafmats = [material('Plant leaf '+str(i),c,0,.74) for i,c in enumerate([(.024,.090,.009),(.045,.145,.018),(.072,.205,.032),(.016,.063,.006)])]

def finish(o,name,mat,smooth=True):
    o.name = name
    if mat: o.data.materials.append(mat)
    o['part'] = name
    for p in o.data.polygons: p.use_smooth=smooth
    return o

def mesh(name,verts,faces,mat,uvs=None,smooth=True):
    me=bpy.data.meshes.new(name);me.from_pydata(verts,[],faces);me.update()
    o=bpy.data.objects.new(name,me);bpy.context.collection.objects.link(o)
    if uvs is not None:
        uv=me.uv_layers.new(name='UVMap')
        for p in me.polygons:
            for li in p.loop_indices: uv.data[li].uv=uvs[me.loops[li].vertex_index]
    return finish(o,name,mat,smooth)

def active(o):
    bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o

def bevel(o,width,segments=None):
    bpy.context.view_layer.update()
    active(o);m=o.modifiers.new('Rounded manufactured edges','BEVEL')
    m.width=min(width,.45*min(o.dimensions));m.segments=segments or [4,2,1][LOD]
    bpy.ops.object.modifier_apply(modifier=m.name)
    n=o.modifiers.new('Weighted face normals','WEIGHTED_NORMAL');n.keep_sharp=True
    bpy.ops.object.modifier_apply(modifier=n.name)

def planar_uv(o):
    uv=o.data.uv_layers.new(name='UVMap')
    bb=[v.co for v in o.data.vertices]
    mn=Vector([min(v[i] for v in bb) for i in range(3)])
    ext=Vector([max(v[i] for v in bb) for i in range(3)])-mn
    for p in o.data.polygons:
        normal=p.normal
        axes=(0,1) if abs(normal.z)>.5 else ((0,2) if abs(normal.y)>.5 else (1,2))
        for li in p.loop_indices:
            c=o.data.vertices[o.data.loops[li].vertex_index].co
            uv.data[li].uv=tuple((c[i]-mn[i])/max(ext[i],.00001) for i in axes)

def box(name,loc,size,mat,radius=0):
    bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.dimensions=size
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    finish(o,name,mat)
    if radius: bevel(o,radius)
    planar_uv(o);return o

def cylinder(name,loc,r,depth,mat,axis='Z',r2=None):
    bpy.ops.mesh.primitive_cone_add(vertices=[48,24,12][LOD],radius1=r,radius2=r if r2 is None else r2,depth=depth,location=loc)
    o=bpy.context.object
    if axis=='X':o.rotation_euler.y=math.pi/2
    if axis=='Y':o.rotation_euler.x=math.pi/2
    return finish(o,name,mat)

def capsule(name,width,length,z,height,mat,edge=0):
    # True straight-sided stadium plan, not an ellipse and not a beveled cuboid.
    n=[32,16,8][LOD];r=width/2;shift=(length-width)/2
    xy=[]
    for cy,offset in [(shift,0),(-shift,math.pi)]:
        for i in range(n+1):
            a=offset+math.pi*i/n;xy.append((r*math.cos(a),cy+r*math.sin(a)))
    N=len(xy);vs=[(x,y,h) for h in [z,z+height] for x,y in xy]
    fs=[tuple(reversed(range(N))),tuple(range(N,2*N))]+[(i,(i+1)%N,(i+1)%N+N,i+N) for i in range(N)]
    o=mesh(name,vs,fs,mat)
    if edge:bevel(o,edge)
    planar_uv(o);return o

def catmull(points,steps):
    p=[Vector(points[0])]+[Vector(v) for v in points]+[Vector(points[-1])]
    out=[]
    for i in range(1,len(p)-2):
        for j in range(steps):
            t=j/steps;a,b,c,d=p[i-1:i+3]
            out.append(.5*((2*b)+(-a+c)*t+(2*a-5*b+4*c-d)*t*t+(-a+3*b-3*c+d)*t*t*t))
    out.append(Vector(points[-1]));return out

def tube(name,points,r,mat,smoothpath=True,radial=None,endr=None):
    pts=catmull(points,[7,4,2][LOD]) if smoothpath else [Vector(p) for p in points]
    n=radial or [12,8,6][LOD];vs=[];uv=[];prev=None
    for j,p in enumerate(pts):
        t=(pts[min(j+1,len(pts)-1)]-pts[max(j-1,0)]).normalized()
        if prev is None:
            ref=Vector((0,0,1)) if abs(t.z)<.95 else Vector((0,1,0))
            e=t.cross(ref).normalized()
        else:
            e=prev-t*prev.dot(t)
            if e.length<1e-7:e=t.cross(Vector((1,0,0)) if abs(t.x)<.9 else Vector((0,1,0)))
            e.normalize()
        f=t.cross(e).normalized();prev=e.copy()
        rr=r if endr is None else r+(endr-r)*j/(len(pts)-1)
        for i in range(n):
            a=math.tau*i/n;vs.append(p+rr*(math.cos(a)*e+math.sin(a)*f));uv.append((i/n,j/(len(pts)-1)))
    fs=[]
    for j in range(len(pts)-1):
        for i in range(n):
            a=j*n+i;b=j*n+(i+1)%n;fs.append((a,b,b+n,a+n))
    fs += [tuple(reversed(range(n))),tuple(range((len(pts)-1)*n,len(pts)*n))]
    return mesh(name,vs,fs,mat,uv)

def solid_shell(name,vs,fs,uv,mat,thickness):
    o=mesh(name,vs,fs,mat,uv)
    active(o);m=o.modifiers.new('Plywood shell thickness','SOLIDIFY');m.thickness=thickness;m.offset=-.5
    bpy.ops.object.modifier_apply(modifier=m.name)
    return o

def cushion(name,w,d,z,thick,mat):
    # Rounded square upholstered form with a slightly crowned seating face.
    n=[64,36,20][LOD];rings= [(.89,-.5),(1.,-.32),(1.,.22),(.94,.43),(.68,.51),(.30,.55)]
    vs=[];uv=[]
    for sc,h in rings:
        for i in range(n):
            a=math.tau*i/n;c=math.cos(a);s=math.sin(a)
            x=w/2*math.copysign(abs(c)**.58,c)*sc;y=d/2*math.copysign(abs(s)**.58,s)*sc
            vs.append((x,y,z+h*thick));uv.append((x/w+.5,y/d+.5))
    fs=[tuple(reversed(range(n)))]
    for j in range(len(rings)-1):
        for i in range(n):a=j*n+i;b=j*n+(i+1)%n;fs.append((a,b,b+n,a+n))
    fs.append(tuple(range((len(rings)-1)*n,len(rings)*n)))
    return mesh(name,vs,fs,mat,uv)

def table():
    capsule('Long charcoal capsule tabletop',1.16,3.35,.733,.032,charcoal,.006)
    capsule('Broad charcoal capsule pedestal',.49,1.86,.025,.708,charcoal,.012)
    capsule('Pedestal recessed floor plinth',.445,1.815,.004,.027,rubber,.004)
    # Upper structural reveal is visible beneath the top, hidden support hardware omitted.
    capsule('Subtle inset under tabletop',1.08,3.27,.718,.019,charcoal,.003)

def caramel_chair():
    cushion('Caramel upholstered rounded seat',.47,.445,.465,.070,caramel)
    if LOD<2:
        # Real piping follows the edge. It is not a texture floating above the cushion.
        pts=[]
        for i in range(49):
            a=math.tau*i/48;c=math.cos(a);s=math.sin(a)
            pts.append((.231*math.copysign(abs(c)**.58,c),.219*math.copysign(abs(s)**.58,s),.478))
        tube('Seat edge stitched piping',pts,.0018,caramel,False,6)
    nx,nq=[(26,16),(14,8),(8,5)][LOD];vs=[];uv=[];fs=[]
    for j in range(nq+1):
        q=j/nq
        # Rounded upper/lower corners, and a real transverse concavity.
        half=.225*(.91+.09*math.sin(math.pi*q)**.45)
        for i in range(nx+1):
            u=-1+2*i/nx;x=half*u
            y=.183+.075*q-.055*u*u
            z=.525+.328*q-.012*u*u
            vs.append((x,y,z));uv.append((i/nx,q))
    for j in range(nq):
        for i in range(nx):a=j*(nx+1)+i;fs.append((a,a+1,a+nx+2,a+nx+1))
    solid_shell('Curved natural wood backrest',vs,fs,uv,oak,.014)
    for s in [-1,1]:
        # Two independent splayed legs on each side, joined to the actual seat support.
        tube('Front leg '+str(s),[(s*.267,-.242,.016),(s*.226,-.177,.403),(s*.207,-.131,.441)],.0115,black)
        tube('Rear leg '+str(s),[(s*.260,.270,.016),(s*.224,.170,.429),(s*.222,.185,.565)],.0115,black)
        tube('Continuous tubular arm loop '+str(s),[(s*.205,.182,.762),(s*.253,.158,.650),(s*.276,.025,.637),(s*.277,-.184,.626),(s*.260,-.218,.587),(s*.249,-.195,.453),(s*.211,-.109,.437)],.012,black)
        pad=box('Natural wood arm pad '+str(s),(s*.276,-.075,.648),(.073,.239,.021),oak,.010)
        pad.rotation_euler.x=.035
        for y in [-.242,.270]:
            cylinder('Leg floor glide',(s*(.267 if y<0 else .260),y,.010),.014,.014,rubber)
    tube('Seat frame front crossbar',[(-.209,-.168,.431),(.209,-.168,.431)],.012,black,False)
    tube('Seat frame back crossbar',[(-.209,.157,.431),(.209,.157,.431)],.012,black,False)

def shell_chair():
    # Continuous seat-to-back shell, not separate flat seat/back boxes.
    profile=[(-.250,.452),(-.190,.451),(-.075,.447),(.072,.449),(.143,.470),(.188,.523),(.212,.612),(.247,.746),(.279,.852)]
    p=catmull([(y,z,0) for y,z in profile],[7,4,2][LOD])
    nx=[28,16,8][LOD];vs=[];uv=[];fs=[]
    for j,pr in enumerate(p):
        q=j/(len(p)-1);y,z=pr.x,pr.y
        half=.235*(.89+.11*math.sin(math.pi*q)**.4)
        for i in range(nx+1):
            u=-1+2*i/nx
            # Sides roll up at the seat, and sweep forward around the upper back.
            influence=max(0,min(1,(z-.49)/.24))
            xx=half*u;yy=y-.052*u*u*influence;zz=z+.022*u*u*(1-influence)-.012*u*u*influence
            vs.append((xx,yy,zz));uv.append((i/nx,q))
    for j in range(len(p)-1):
        for i in range(nx):a=j*(nx+1)+i;fs.append((a,a+1,a+nx+2,a+nx+1))
    solid_shell('Pale continuous scooped plywood seat and back',vs,fs,uv,pale,.016)
    for s in [-1,1]:
        tube('Pale front splayed leg '+str(s),[(s*.275,-.290,.016),(s*.171,-.123,.416)],.017,pale,False,endr=.025)
        tube('Pale rear splayed leg '+str(s),[(s*.259,.281,.016),(s*.173,.110,.420)],.017,pale,False,endr=.025)
        tube('Underseat wood side stretcher '+str(s),[(s*.170,-.132,.418),(s*.170,.123,.418)],.023,pale,False)
        for y,x in [(-.290,.275),(.281,.259)]:
            cylinder('Small pale chair floor glide',(s*x,y,.009),.017,.010,rubber)
    tube('Underseat front wood crosspiece',[(-.179,-.121,.414),(.179,-.121,.414)],.024,pale,False)
    tube('Underseat rear wood crosspiece',[(-.179,.106,.414),(.179,.106,.414)],.024,pale,False)

def office_chair():
    cushion('Orange upholstered office seat',.50,.48,.465,.080,orange)
    # Black shell is visible from the photograph camera. Orange appears on the seat only.
    nx,nq=[(24,20),(14,12),(8,6)][LOD];vs=[];uv=[];fs=[]
    for j in range(nq+1):
        q=j/nq;half=.210+.045*math.sin(math.pi*q*.87)
        if q>.86:half*=1-.06*((q-.86)/.14)
        for i in range(nx+1):
            u=-1+2*i/nx
            vs.append((half*u,.183+.145*q-.045*u*u,.505+.468*q-.025*u*u));uv.append((i/nx,q))
    for j in range(nq):
        for i in range(nx):a=j*(nx+1)+i;fs.append((a,a+1,a+nx+2,a+nx+1))
    solid_shell('Black contoured office chair back shell',vs,fs,uv,rubber,.027)
    # Outer perimeter is a heavier dark molded rim with a central rear support.
    rim=[]
    for j in range(nq+1):rim.append(vs[j*(nx+1)])
    for i in range(1,nx+1):rim.append(vs[nq*(nx+1)+i])
    for j in range(nq-1,-1,-1):rim.append(vs[j*(nx+1)+nx])
    tube('Molded outer back rim',rim,.014,black,False)
    tube('Rear upright office support',[(0,.015,.395),(0,.140,.400),(0,.250,.53),(0,.318,.80)],.031,black)
    for s in [-1,1]:
        tube('Office arm support '+str(s),[(s*.213,.095,.434),(s*.287,.034,.530),(s*.289,-.073,.655)],.019,black)
        pad=box('Wide office armrest '+str(s),(s*.284,-.070,.668),(.065,.305,.028),rubber,.012)
        pad.rotation_euler.x=.08
    cylinder('Office central gas lift',(0,0,.280),.027,.255,black)
    cylinder('Office lower column cover',(0,0,.174),.044,.142,rubber)
    cylinder('Office seat mechanism housing',(0,.015,.403),.089,.052,black)
    for i in range(5):
        a=math.tau*i/5+.20;co,si=math.cos(a),math.sin(a)
        tube('Office five star base spoke '+str(i),[(.025*co,.025*si,.185),(.170*co,.170*si,.130),(.310*co,.310*si,.075)],.022,black)
        center=Vector((.310*co,.310*si,.046))
        for s in [-1,1]:
            w=cylinder('Twin caster wheel '+str(i)+' '+str(s),center+Vector((-.014*s*si,.014*s*co,0)),.033,.019,rubber,'X')
            w.rotation_euler=Vector((-si,co,0)).to_track_quat('Z','Y').to_euler()

def planter():
    # The source has a wood cylinder, an exposed soil opening and multiple slim branches.
    n=[64,32,16][LOD];r=.202;h=.348;t=.013
    vs=[];uv=[]
    for rr,z in [(r,0),(r,h),(r-t,h),(r-t,h-.052)]:
        for i in range(n):
            a=math.tau*i/n;vs.append((rr*math.cos(a),rr*math.sin(a),z));uv.append((i/n,z/h))
    fs=[]
    for ring in range(3):
        for i in range(n):a=ring*n+i;b=ring*n+(i+1)%n;fs.append((a,b,b+n,a+n))
    fs.append(tuple(reversed(range(n))))
    fs.append(tuple(range(3*n,4*n)))  # Closed recessed interior floor below the soil.
    mesh('Cylindrical oak planter with open rim',vs,fs,oak,uv)
    cylinder('Visible dark soil',(0,0,h-.030),r-t,.013,soil)
    rng=random.Random(4109)
    # Every LOD keeps the same trunk network; leaf density and tessellation change.
    tips=[]
    for k in range(4):
        a=.4+k*1.9;base=Vector((.035*math.cos(a),.035*math.sin(a),h-.023))
        mid=Vector((.095*math.cos(a),.095*math.sin(a),.72+.05*(k%2)))
        tip=Vector((.240*math.cos(a+.18),.240*math.sin(a+.18),1.24+.085*(k%3)))
        tube('Main woody stem '+str(k),[base,mid,tip],.012,bark,endr=.004)
        for j in range(5):
            q=.28+j*.145;start=mid.lerp(tip,q)
            theta=a+(-1 if j%2 else 1)*(.65+j*.23)
            end=start+Vector((.19*math.cos(theta),.19*math.sin(theta),.16-.025*(j%2)))
            elbow=start.lerp(end,.55)+Vector((0,0,.018))
            tube('Secondary branch '+str(k)+' '+str(j),[start,elbow,end],.0045,bark,endr=.0014)
            tips.append((elbow,end,theta))
    leafvs=[];leaffs=[];leafuv=[];leafindices=[]
    for ti,(start,end,a) in enumerate(tips):
        count=24
        keep={round(k*23/([24,14,7][LOD]-1)) for k in range([24,14,7][LOD])}
        for j in range(count):
            along=(j+1)/(count+1);center=start.lerp(end,along)
            side=(-1 if j%2 else 1);theta=a+side*(.75+rng.random()*.7)
            center+=Vector((.038*math.cos(theta),.038*math.sin(theta),rng.uniform(-.045,.065)))
            direction=Vector((math.cos(theta),math.sin(theta),rng.uniform(-.55,.75))).normalized()
            across=direction.cross(Vector((0,0,1))).normalized()
            across=Matrix.Rotation(rng.uniform(-.70,.70),4,direction)@across
            length=rng.uniform(.040,.071);width=length*.25
            if j not in keep:continue
            off=len(leafvs)
            edgecount=[10,8,6][LOD]
            leafnormal=direction.cross(across).normalized()
            for e in range(edgecount):
                angle=math.tau*e/edgecount
                leafvs.append(center+direction*(length*.5*math.cos(angle))+across*(width*math.sin(angle)))
                leafuv.append((.5+.5*math.cos(angle),.5+.5*math.sin(angle)))
            leafvs.append(center+leafnormal*.004);leafuv.append((.5,.5))
            for e in range(edgecount):
                leaffs.append((off+e,off+(e+1)%edgecount,off+edgecount));leafindices.append((j+ti)%4)
    o=mesh('Individual small leaves, species unspecified',leafvs,leaffs,None,leafuv,False)
    for m in leafmats:o.data.materials.append(m)
    for p,i in zip(o.data.polygons,leafindices):p.material_index=i

ASSETS=[('photo_living_capsule_table',table),('photo_living_caramel_armchair',caramel_chair),('photo_living_pale_shell_chair',shell_chair),('photo_living_orange_office_chair',office_chair),('photo_living_wood_planter',planter)]

def bounds():
    bpy.context.view_layer.update()
    objs=[o for o in bpy.context.scene.objects if o.type=='MESH']
    pts=[o.matrix_world@v.co for o in objs for v in o.data.vertices]
    bb=[[min(v[i] for v in pts) for i in range(3)],[max(v[i] for v in pts) for i in range(3)]]
    return objs,bb

def validate_meshes(objs):
    for o in objs:
        assert all(math.isfinite(v) for vertex in o.data.vertices for v in vertex.co), o.name
        assert all(p.area > 1e-13 for p in o.data.polygons), 'Degenerate face: '+o.name
        if 'Individual small leaves' not in o.name:
            edges=collections.Counter(tuple(sorted(e)) for p in o.data.polygons for e in p.edge_keys)
            assert all(count==2 for count in edges.values()), 'Open solid: '+o.name
        assert not o.modifiers, 'Unapplied modifier: '+o.name

def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.preferences.filepaths.save_version=0
    bpy.context.scene.unit_settings.system='METRIC'

def render(name,composition=False):
    global LOD
    LOD=0;objs,bb=bounds();lo,hi=map(Vector,bb);center=(lo+hi)/2;size=max(hi-lo)
    floor=material('Review only warm grey floor',(.40,.395,.367),0,.79)
    box('RENDER ONLY studio floor',(0,0,-.025),(200,200,.045),floor)
    if composition:
        target=Vector((0,.11,.76));camera=Vector((3.27,-4.50,2.46));lens=40
    elif name=='photo_living_capsule_table':
        target=Vector((0,0,.37));camera=Vector((3.0,-4.5,2.35));lens=47
    elif name=='photo_living_wood_planter':
        target=center;camera=center+Vector((1.32,-2.00,1.00))*size;lens=54
    elif name.endswith('_back'):
        target=center;camera=center+Vector((1.30,1.80,1.0))*size*1.16;lens=52
    else:
        target=center;camera=center+Vector((1.28,-1.90,1.10))*size*1.16;lens=52
    bpy.ops.object.camera_add(location=camera);cam=bpy.context.object
    cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.lens=lens;bpy.context.scene.camera=cam
    extent=max(size,1.)
    for pos,power,rad in [((-1.6,-1.0,2.3),420,2.5),((1.5,.6,1.8),270,2),((-.3,1.9,1.2),330,1.7)]:
        bpy.ops.object.light_add(type='AREA',location=center+Vector(pos)*extent);o=bpy.context.object
        o.data.energy=power*extent*extent;o.data.shape='DISK';o.data.size=rad*extent
        o.rotation_euler=(target-o.location).to_track_quat('-Z','Y').to_euler()
    sc=bpy.context.scene;sc.world=bpy.data.worlds.new('Neutral review environment');sc.world.use_nodes=True
    sc.world.node_tree.nodes.get('Background').inputs['Color'].default_value=(.30,.33,.35,1)
    sc.world.node_tree.nodes.get('Background').inputs['Strength'].default_value=.45
    sc.render.engine='CYCLES';sc.cycles.device='CPU';sc.cycles.samples=64;sc.cycles.use_denoising=False
    sc.render.resolution_x=1440 if composition else 1200;sc.render.resolution_y=1000 if composition else 920
    sc.render.resolution_percentage=100;sc.view_settings.view_transform='AgX';sc.view_settings.exposure=-1.15 if name=='photo_living_capsule_table' else -.6
    sc.render.image_settings.file_format='PNG';sc.render.filepath=str(REVIEW/(name+'.png'))
    bpy.ops.render.render(write_still=True)

def instance(asset,loc,yaw=0):
    path=OUT/asset/(asset+'.blend')
    with bpy.data.libraries.load(str(path),link=False) as (src,dst):dst.objects=src.objects
    m=Matrix.Translation(Vector(loc))@Matrix.Rotation(yaw,4,'Z')
    imported=[o for o in dst.objects if o]
    for o in imported:bpy.context.collection.objects.link(o)
    # Linked objects must be evaluated before matrix_world is read. Otherwise their
    # saved object locations/rotations can be lost while vertex-authored parts stay put.
    bpy.context.view_layer.update()
    transforms=[(o,o.matrix_world.copy()) for o in imported]
    for o,original in transforms:o.matrix_world=m@original
    bpy.context.view_layer.update()

def composition():
    reset()
    instance('photo_living_capsule_table',(0,0,0))
    # Mixed chairs follow the photo. Positions are a near-view arrangement, not surveyed inventory.
    for y in [-.65,.15,.92]:
        instance('photo_living_caramel_armchair',(-.84,y,0),math.pi/2)
        instance('photo_living_caramel_armchair',(.84,y+.10,0),-math.pi/2)
    instance('photo_living_pale_shell_chair',(.83,-1.26,0),-math.pi/2-.10)
    instance('photo_living_orange_office_chair',(-.18,-2.03,0),math.pi+.10)
    instance('photo_living_wood_planter',(0,.91,.765))
    if '--save-composition-source' in sys.argv:
        bpy.ops.wm.save_as_mainfile(filepath=str(REVIEW/'photo_living_furniture_composition.blend'))
    render('photo_living_furniture_near_view',True)

selected=[a for a in sys.argv if a.startswith('--asset=')]
if '--render-only' not in sys.argv:
    for asset,build in ASSETS:
        if selected and '--asset='+asset not in selected:continue
        CURRENT_FOLDER=OUT/asset;CURRENT_FOLDER.mkdir(parents=True,exist_ok=True)
        for LOD in range(3):
            reset();palette();build();objs,bb=bounds();validate_meshes(objs)
            for o in objs:o['scaleStatus']='Estimated from reference photograph, not measured';o['reference']='living photo supplied by user 2026-11-03';o['assetId']=asset
            p=CURRENT_FOLDER/f'lod{LOD}_source.glb'
            bpy.ops.export_scene.gltf(filepath=str(p),export_format='GLB',export_extras=True,export_yup=True)
            records.append({'asset':asset,'level':LOD,'triangles':sum(len(p.vertices)-2 for o in objs for p in o.data.polygons),'boundsBlenderXYZ':bb,'sizeBlenderXYZ':[bb[1][i]-bb[0][i] for i in range(3)],'meshParts':len(objs),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
            if LOD==0:bpy.ops.wm.save_as_mainfile(filepath=str(CURRENT_FOLDER/(asset+'.blend')))
    report={'blender':bpy.app.version_string,'units':'m','referenceLibraryId':'src_ref_553e32da74bbe8adeb78cfb9fbeb32e1','referencePixelsViewed':True,'dimensions':'All sizes are authoring estimates from a single photograph; no surveyed or manufacturer dimensions are claimed.','scope':'Five independent furniture and planter sources. No main scene, UI, Godot, collision or runtime integration.','materials':'Metallic-roughness PBR factors and synthetic wood base-color maps; the table also has a synthetic tangent-space normal map. No AO maps or photograph pixels.','render':'CPU Cycles studio renders, not browser captures.','omissions':['Rear orange lounge chairs and rear bar stools are not included in this furniture batch.','The raised black shelf behind the planter is omitted; its junction and support are obscured.','Kitchen counter and appliances are separate reusable assets in this package.'],'records':records}
    path=REVIEW/'furniture_build_report.json'
    if selected and path.exists():
        prior=json.loads(path.read_text());report['records']=[r for r in prior['records'] if '--asset='+r['asset'] not in selected]+records
    path.write_text(json.dumps(report,indent=2))
if '--skip-render' not in sys.argv:
    if '--composition-only' not in sys.argv:
        for asset,build in ASSETS:
            if selected and '--asset='+asset not in selected:continue
            bpy.ops.wm.open_mainfile(filepath=str(OUT/asset/(asset+'.blend')));render(asset)
            if asset=='photo_living_orange_office_chair':
                bpy.ops.wm.open_mainfile(filepath=str(OUT/asset/(asset+'.blend')));render(asset+'_back')
    if not selected or '--composition-only' in sys.argv:composition()
