"""Photo-informed pantry components. Blender 4.3.2, metres, no photo textures.
Run: blender -b --factory-startup -t 4 --python scripts/build_photo_pantry.py
Optional arguments follow Blender separator: -- --skip-render or -- --render-only.
Dimensions are proportional estimates, not a measured survey or product specification.
"""
import bpy, math, json, hashlib, sys
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'sources/models/photo_living'; REVIEW=ROOT/'review/photo_living'
OUT.mkdir(parents=True,exist_ok=True); REVIEW.mkdir(parents=True,exist_ok=True)
LOD=0
records=[]
def mat(name,c,metal=0,rough=.4,alpha=1):
 m=bpy.data.materials.new(name);m.diffuse_color=(*c,alpha);m.use_nodes=True;p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*c,alpha);p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=rough;p.inputs['Alpha'].default_value=alpha
 if alpha<1: m.surface_render_method='DITHERED'
 return m
def palette():
 global white,wood,woodline,green,grout,black,grey,dark,silver,steel,glass,light,ventblack,socketmat
 white=mat('Warm white solid surface and appliance enamel',(.79,.80,.76),0,.31)
 wood=mat('Pale neutral oak cabinetry estimated',(.53,.43,.32),0,.56)
 woodline=mat('Subtle vertical oak tone',(.49,.40,.30),0,.6)
 green=mat('Muted olive green vertical tile',(.11,.13,.080),0,.32)
 grout=mat('Warm light tile grout',(.72,.72,.65),0,.68)
 black=mat('Satin black sink and faucet',(.015,.019,.021),.18,.34)
 socketmat=mat('Matte black circular power sockets',(.012,.014,.015),0,.68)
 grey=mat('Graphite grey round front appliance',(.22,.24,.25),.5,.35)
 dark=mat('Dark inset panel and door glazing',(.034,.041,.043),.22,.18)
 silver=mat('Silver white refrigerator finish',(.60,.66,.67),.55,.31)
 steel=mat('Brushed silver hardware',(.45,.49,.49),.85,.25)
 glass=mat('Smoky translucent clear lid',(.18,.23,.24),.15,.13,.58)
 light=mat('Warm shelf diffuser',(.95,.86,.65),0,.3)
 p=light.node_tree.nodes.get('Principled BSDF');p.inputs['Emission Color'].default_value=(1,.82,.51,1);p.inputs['Emission Strength'].default_value=2
 ventblack=mat('Dark vent openings',(.055,.06,.06),0,.65)
def finish(o,name,m,smooth=True):
 o.name=name;o.data.materials.append(m);o['part']=name
 if smooth:
  for f in o.data.polygons:f.use_smooth=True
 return o
def box(name,loc,size,m,bevel=0):
 assert min(size)>0, (name,size)
 bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.dimensions=size;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 if bevel:
  b=o.modifiers.new('Manufactured edge radius capped at 45 percent','BEVEL');b.width=min(bevel,.45*min(size));b.segments=[3,2,1][LOD];b.affect='EDGES';bpy.ops.object.modifier_apply(modifier=b.name)
 finish(o,name,m)
 n=o.modifiers.new('Weighted manufactured face normals','WEIGHTED_NORMAL');n.keep_sharp=True;bpy.ops.object.modifier_apply(modifier=n.name)
 return o
def cylinder(name,loc,r,depth,m,axis='Z',verts=None):
 bpy.ops.mesh.primitive_cylinder_add(vertices=verts or [40,24,12][LOD],radius=r,depth=depth,location=loc);o=bpy.context.object
 if axis=='Y':o.rotation_euler.x=math.pi/2
 if axis=='X':o.rotation_euler.y=math.pi/2
 finish(o,name,m)
 for f in o.data.polygons:
  if len(f.vertices)>4:f.use_smooth=False
 return o
def pipe(name,points,r,m,closed=False):
 curve=bpy.data.curves.new(name,'CURVE');curve.dimensions='3D';curve.resolution_u=1;curve.bevel_depth=r;curve.bevel_resolution=[3,2,1][LOD];curve.resolution_u=1;curve.use_fill_caps=True
 s=curve.splines.new('POLY');s.points.add(len(points)-1)
 for p,co in zip(s.points,points):p.co=(*co,1)
 s.use_cyclic_u=closed;o=bpy.data.objects.new(name,curve);bpy.context.collection.objects.link(o);bpy.context.view_layer.objects.active=o;o.select_set(True);bpy.ops.object.convert(target='MESH');o=bpy.context.object;finish(o,name,m);o.select_set(False);return o
def torus(name,loc,major,minor,m,rot=(0,0,0)):
 bpy.ops.mesh.primitive_torus_add(major_segments=[48,24,12][LOD],minor_segments=[10,8,6][LOD],location=loc,major_radius=major,minor_radius=minor,rotation=rot);return finish(bpy.context.object,name,m)
def woodpanel(name,loc,size):
 o=box(name,loc,size,wood,.0013)
 if LOD==0 and size[0]>.15 and size[2]>.15:
  # Explicit mesh tones survive glTF. No private reference pixels or procedural texture dependency.
  for i in range(max(2,int(size[0]/.045))):
   x=loc[0]-size[0]/2+.023+i*.045
   if x<loc[0]+size[0]/2-.01:box(name+' subtle grain', (x,loc[1]-size[1]/2-.0001,loc[2]),(.00065,.00022,size[2]-.012),woodline)
 return o
def counter():
 # A true cutout: four counter sections surround the separate basin, never a slab over the sink.
 W,D,H=2.40,.66,.90; hole=(-.36,.30,-.245,.235)
 box('Cabinet dark recessed plinth',(0,.025,.055),(2.34,.58,.11),dark,.003)
 box('Cabinet bottom',(0,.025,.135),(2.36,.59,.03),wood,.003)
 box('Cabinet back',(0,.307,.477),(2.36,.026,.71),wood,.003)
 for x in [-1.17,1.17]:box('Cabinet side wall',(x,.025,.477),(.026,.59,.71),wood,.003)
 for x in [-.69,.69]:box('Cabinet internal upright clear of basin',(x,.025,.477),(.024,.56,.71),wood,.003)
 for i in range(5):
  x=-.956+i*.478;woodpanel('Base cabinet door %d'%i,(x,-.286,.475),(.473,.022,.75))
  box('Finger reveal beneath worktop %d'%i,(x,-.293,.863),(.471,.019,.018),dark,.001)
 x0,x1,y0,y1=hole
 box('White worktop left',((-1.2+x0)/2,0,.883),(x0+1.2,D,.034),white,.003)
 box('White worktop right',((x1+1.2)/2,0,.883),(1.2-x1,D,.034),white,.003)
 box('White worktop front',((x0+x1)/2,(-D/2+y0)/2,.883),(x1-x0,y0+D/2,.034),white,.003)
 box('White worktop behind basin',((x0+x1)/2,(y1+D/2)/2,.883),(x1-x0,D/2-y1,.034),white,.003)
 box('Short white rear upstand',(0,.322,.925),(W,.018,.05),white,.003)
 box('Short white left return upstand',(-1.19,0,.925),(.018,.64,.05),white,.003)
 # cabinet below basin is closed; the basin itself is recessed to 0.69 m.
def sink_faucets():
 # Local z=0 is countertop surface. Basin opening remains open and roll rack spans left half.
 W,D=.68,.50;cx=-.03
 for x in [-W/2,W/2]:box('Sink black narrow side rim',(cx+x,0,.003),(.025,D+.025,.014),black,.004)
 for y in [-D/2,D/2]:box('Sink black front back rim',(cx,y,.003),(W-.025,.025,.014),black,.004)
 box('Sink bowl bottom',(cx,0,-.185),(W-.046,D-.046,.018),black,.025)
 for x in [-.319,.319]:box('Sink deep side wall',(cx+x,0,-.09),(.018,D-.035,.19),black,.007)
 for y in [-.230,.230]:box('Sink deep front back wall',(cx,y,-.09),(W-.045,.018,.19),black,.007)
 cylinder('Sink drain silver collar',(cx+.10,-.06,-.174),.044,.004,steel)
 cylinder('Sink drain dark strainer',(cx+.10,-.06,-.171),.035,.003,dark)
 if LOD<2:
  for k in range(8):
   a=math.tau*k/8;cylinder('Drain perforation',(cx+.10+.022*math.cos(a),-.06+.022*math.sin(a),-.169),.003,.0006,black,verts=8)
 # Roll-up drying rack: parallel thin rods, black end strips, no solid lid.
 for i in range([13,10,6][LOD]):
  x=cx-.29+i*.28/([13,10,6][LOD]-1);cylinder('Roll rack metal rod',(x,0,.021),.005,.465,steel,'Y')
 for y in [-.221,.221]:box('Roll rack flexible black support',(cx-.15,y,.02),(.316,.020,.019),black,.004)
 # Tall black curved faucet at back edge, full gooseneck visible from front.
 fx,fy=.07,.297
 cylinder('Black faucet foot',(fx,fy,.012),.030,.024,black)
 cylinder('Black faucet body',(fx,fy,.07),.021,.13,black)
 pts=[(fx,fy,.07),(fx,fy,.29)]
 n=[24,14,8][LOD]
 for i in range(n+1):
  a=math.pi*i/n;pts.append((fx,fy-.09+.09*math.cos(a),.29+.09*math.sin(a)))
 pts.append((fx,fy-.18,.263));pipe('Tall black curved faucet spout',pts,.0145,black)
 cylinder('Black spout underside aerator',(fx,fy-.18,.260),.011,.007,dark)
 # Side lever uses actual spatial separation from main stem.
 cylinder('Black faucet side mixing pivot',(fx+.023,fy,.073),.018,.035,black,'X')
 lever=box('Black faucet broad mixing lever',(fx+.045,fy-.023,.097),(.012,.033,.056),black,.005);lever.rotation_euler.x=.45
 # Small silver second tap has a narrow angular neck and separate conical-looking base.
 sx,sy=.32,.283
 cylinder('Small silver tap base',(sx,sy,.033),.023,.066,steel)
 cylinder('Small silver tap narrow stem',(sx,sy,.16),.008,.26,steel)
 pts=[(sx,sy,.18),(sx,sy,.30),(sx,sy-.012,.315),(sx,sy-.113,.315),(sx,sy-.13,.30),(sx,sy-.15,.262)]
 pipe('Small silver drinking faucet neck',pts,.0075,steel)
 o=box('Small silver tap dark handle',(sx,sy-.018,.079),(.022,.029,.014),dark,.003);o.rotation_euler.x=.3

def grey_appliance():
 # Revision 2026-11-03: retain estimated body size; correct photo-visible shape only.
 case=box('Grey round front appliance case',(0,0,.185),(.39,.435,.35),grey,.0035)
 # The right-side pressed panel is a real 1.3 mm recess, not stacked external plates.
 # A rounded YZ polygon is extruded only to cut the thin side relief.
 ry,rz,cy,cz,r=.337/2,.255/2,.019,.190,.020
 coords=[];steps=[8,5,3][LOD]
 for yy,zz,start in [(cy+ry-r,cz-rz+r,-90),(cy+ry-r,cz+rz-r,0),(cy-ry+r,cz+rz-r,90),(cy-ry+r,cz-rz+r,180)]:
  for k in range(steps+1):
   t=math.radians(start+90*k/steps);coords.append((yy+r*math.cos(t),zz+r*math.sin(t)))
 n=len(coords);vs=[(x,y,z) for x in [.1937,.205] for y,z in coords]
 fs=[tuple(range(n-1,-1,-1)),tuple(range(n,2*n))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
 me=bpy.data.meshes.new('Temporary pressed-panel relief cutter');me.from_pydata(vs,[],fs);me.update();cut=bpy.data.objects.new('Temporary pressed-panel relief cutter',me);bpy.context.collection.objects.link(cut)
 bpy.context.view_layer.objects.active=case;mod=case.modifiers.new('Shallow sheet-metal side impression','BOOLEAN');mod.operation='DIFFERENCE';mod.solver='EXACT';mod.object=cut;bpy.ops.object.modifier_apply(modifier=mod.name);bpy.data.objects.remove(cut,do_unlink=True)
 # Regenerate split normals after the topology edit; broad metal faces remain planar.
 mod=case.modifiers.new('Recomputed planar case normals','WEIGHTED_NORMAL');mod.keep_sharp=True;bpy.ops.object.modifier_apply(modifier=mod.name)
 case['side_impression_depth_m']=.0013
 box('Grey appliance dark underside',(0,0,.017),(.35,.395,.022),dark,.002)
 for x in [-.14,.14]:
  for y in [-.155,.155]:cylinder('Grey appliance foot',(x,y,.009),.017,.018,black)
 # Slim rectangular door frame carries a smaller, flat round viewing window.
 # The lower frame is intentionally visible; no unsupported projecting bottom handle.
 box('Microwave slim rectangular door frame',(0,-.223,.185),(.377,.012,.337),grey,.003)
 viewing=mat('Microwave flat smoked viewing glass',(.018,.025,.027),.08,.22)
 cylinder('Round front flat viewing glass',(-.029,-.230,.206),.147,.0016,viewing,'Y',verts=[64,32,16][LOD])
 torus('Thin silver viewing-window edge',(-.029,-.231,.206),.147,.0014,steel,(math.pi/2,0,0))
 box('Narrow flush control strip',(.165,-.231,.187),(.029,.003,.304),grey,.001)
 cylinder('Small front control knob',(.165,-.238,.142),.014,.012,steel,'Y')
 if LOD<2:
  for z in [.22,.246,.272,.298]:box('Unlabelled small front indicator',(.165,-.233,z),(.004,.001,.004),silver,.0009)
  for y in [-.17,.17]:cylinder('Side lower fastener',(.1955,y,.052),.0025,.001,steel,'X',verts=12)
 # The user identifies this object as a microwave; no unverified brand/model is added.

def white_appliance():
 box('White vented appliance body',(0,0,.183),(.34,.37,.346),white,.017)
 box('Appliance black lid rim',(0,0,.357),(.338,.369,.021),dark,.008)
 # Interior mass is beneath a visibly separate smoky clear lid.
 box('Dark interior beneath transparent top',(-.057,0,.359),(.217,.342,.018),dark,.007)
 box('Clear smoke top lid',(-.057,0,.378),(.224,.350,.023),glass,.005)
 for y in [-.176,.176]:box('Clear lid thin boundary',(-.057,y,.384),(.223,.005,.015),glass,.002)
 # White raised control ledge at right of the transparent lid.
 o=box('Right white top control housing',(.117,0,.38),(.098,.367,.043),white,.01)
 box('Black top control rectangle',(.123,-.054,.404),(.056,.133,.003),dark,.004)
 for j in range(4):
  cylinder('Unlabelled white top control',(.123,-.104+j*.03,.406),.0032,.001,white,verts=12)
 # Front split and large lower-right vent grid match observed shapes.
 box('Front vertical body seam',(-.055,-.186,.174),(.0017,.001,.308),grey)
 box('Front lower-right vent dark inset',(.059,-.190,.119),(.177,.006,.167),ventblack,.015)
 # Vents modeled as strips, including at LOD2 rather than unsupported image textures.
 count=[13,9,6][LOD]
 for j in range(count):box('White front grille horizontal slat',(.059,-.195,.041+j*.155/(count-1)),(.174,.009,.0057 if LOD==0 else .007),white,.002)
 for x in [-.025,.015,.055,.095,.143]:box('White grille upright',(x,-.198,.119),(.005,.009,.162),white,.002)
 cylinder('Small dark front inset',(.031,-.188,.300),.009,.003,black,'Y',verts=16)
 # Side lower vent is visible at an oblique angle.
 box('Right side vent inset',(.172,.012,.145),(.004,.195,.112),ventblack,.008)
 for i in range([9,6,4][LOD]):box('Side vent fin',(.176,-.072+i*.17/([9,6,4][LOD]-1),.145),(.008,.006,.108),white,.002)
 # Small white open scoop resting on lid. Hollow geometry, not a solid white cube.
 bx,by,bz=-.058,.010,.399
 box('Scoop bottom',(bx,by,bz+.004),(.080,.066,.008),white,.008)
 for x in [-.042,.042]:box('Scoop side',(bx+x,by,bz+.025),(.008,.066,.047),white,.004)
 for y in [-.031,.031]:box('Scoop curved end simplified',(bx,by+y,bz+.025),(.080,.008,.047),white,.004)
 o=box('Scoop short flat handle',(bx,by-.050,bz+.032),(.026,.045,.007),white,.003);o.rotation_euler.x=-.25
 for x in [-.12,.12]:
  for y in [-.135,.135]:cylinder('White appliance rubber foot',(x,y,.007),.014,.014,black)

def backsplash_shelves():
 # Local base height z=0; matches counter z=.9 in the assembly.
 box('Backsplash warm grout backing',(0,.346,.437),(2.4,.025,.875),grout)
 nx,ny=24,3
 for i in range(nx):
  for j in range(ny):
   box('Vertical olive tile %02d %d'%(i,j),(-1.15+i*.1,.328,.146+j*.2915),(.097,.010,.288),green,.0007)
 # Grey electrical track and visibly round black modules are separate geometry.
 box('Grey socket track',(0,.300,.436),(2.36,.045,.096),grey,.004)
 box('Track continuous dark center slot',(0,.274,.436),(2.33,.002,.005),dark)
 for i,x in enumerate([-.99,-.76,-.53,-.12,.28,.63,1.02]):
  cylinder('Round black socket module %d'%i,(x,.263,.436),.035,.024,socketmat,'Y')
  if LOD<2:
   for dx in [-.008,.008]:box('Socket vertical contact slot',(x+dx,.248,.444),(.002,.001,.008),ventblack)
   o=box('Socket diagonal contact slot',(x,.248,.426),(.002,.001,.008),ventblack);o.rotation_euler.y=.5
 # Shelves and side return in pale wood, with lower warm diffuser.
 woodpanel('Upper open shelf back',(0,.367,1.147),(2.4,.018,.54))
 woodpanel('Upper shelf lower plank',(0,.205,.895),(2.4,.33,.032))
 woodpanel('Upper shelf top plank',(0,.205,1.405),(2.4,.33,.03))
 for x in [-1.188,-.6,0,.6,1.188]:woodpanel('Upper open cubby divider',(x,.205,1.15),(.024,.33,.48))
 woodpanel('Left cabinet tall return',(-1.215,.12,.71),(.03,.48,1.42))
 box('Undershelf warm narrow light',(0,.094,.876),(2.30,.011,.008),light,.002)
 # A few anonymous containers visible in the reference shelf; no invented labels.
 cylinder('Plain white shelf bowl',(.20,.20,.985),.080,.14,white)
 cylinder('Small shelf container',(-.80,.22,.962),.031,.10,white)
 cylinder('Small shelf container green cap',(-.80,.22,1.018),.032,.012,green)
 # Wiring follows two observed plugged appliances; no decals or opaque photo imagery.
 for x,zend,m in [(-.53,.16,black),(.63,.08,white)]:
  box('Plain plugged connector',(x,.231,.436),(.033,.035,.043),m,.005)
  endx=x-.12 if m==black else x+.07
  pipe('Appliance power cord',[(x,.224,.414),(x,.205,.30),(x+.025,.18,.18),(endx,.16,zend)],.003,m)

def fridge():
 # Standalone appliance. Adjacent black dispenser belongs only to wood_surround().
 box('Refrigerator main carcass',(0,.027,.927),(.902,.644,1.782),grey,.012)
 box('Refrigerator low recessed plinth',(0,0,.044),(.845,.595,.058),dark,.007)
 # Unequal side-by-side leaves, with recessed central grip channels.
 for name,x,w in [('Left narrower door',-.237,.414),('Right wider door',.219,.444)]:
  # Door back plus stepped front panels create a genuine open inner-edge recess.
  # Every recess floor sits behind the front face by 20 mm; no external bar.
  side=1 if x<0 else -1;cw=.024
  box(name+' structural rear slab',(x,-.306,.947),(w,.044,1.744),silver,.005)
  box(name+' broad front face',(x-side*cw/2,-.340,.947),(w-cw,.022,1.744),silver,.004)
  edge=x+side*(w/2-cw/2)
  lo,hi=.607,1.227;bottom,top=.075,1.819
  box(name+' inner front below grip',(edge,-.340,(bottom+lo)/2),(cw,.022,lo-bottom),silver,.002)
  box(name+' inner front above grip',(edge,-.340,(hi+top)/2),(cw,.022,top-hi),silver,.002)
  box(name+' recessed dark handle floor',(edge,-.329,.917),(cw-.002,.001,.620),dark,.0004)
  box(name+' recessed silver grip floor',(edge,-.330,.917),(cw-.008,.001,.604),steel,.0004)
 # Central narrow reveal is visibly separate over full height.
 box('Central vertical door gasket',(-.016,-.314,.947),(.009,.009,1.71),dark,.002)
 if LOD<2:
  box('Subtle refrigerator top cap',(0,.014,1.822),(.884,.62,.014),silver,.004)
 # No unreadable energy label, QR, manufacturer logo, or assumed front dispenser.

def wood_surround():
 # Cabinet opening centres on separate fridge at origin. Surround is independent.
 woodpanel('Fridge left wood surround',(-.489,.031,1.365),(.030,.708,2.67))
 woodpanel('Fridge upper cupboard left',(-.249,.014,2.245),(.446,.68,.811))
 woodpanel('Fridge upper cupboard right',(.215,.014,2.245),(.469,.68,.811))
 # Right cabinet face has a true dispenser recess, not a black rectangle pasted on fridge.
 cx=.764;w=.58;yy=-.325
 box('Right cabinet rear carcass',(cx,.285,1.34),(w,.08,2.68),wood,.003)
 for x in [.483,1.045]:woodpanel('Right tall cabinet side',(x,.005,1.34),(.018,.64,2.68))
 woodpanel('Right upper cabinet',(cx,yy,2.125),(w,.025,1.10))
 woodpanel('Right mid cabinet header',(cx,yy,1.492),(w,.025,.155))
 woodpanel('Right low cabinet below recess',(cx,yy,.359),(w,.025,.698))
 # dispenser opening x .55..98, z .73..1.37; separate surround strips.
 for x in [.516,1.012]:woodpanel('Recess cabinet vertical edge',(x,yy,1.066),(.084,.025,.718))
 woodpanel('Right bottom horizontal door reveal',(cx,yy-.001,.714),(w,.026,.007))
 box('Cabinet dispenser black top',(cx,-.335,1.387),(.421,.035,.065),black,.004)
 box('Cabinet dispenser black bottom',(cx,-.335,.758),(.421,.038,.078),black,.004)
 for x in [cx-.196,cx+.196]:box('Cabinet dispenser black side',(x,-.335,1.066),(.029,.038,.574),black,.004)
 box('Dispenser recessed back',(cx,-.174,1.064),(.365,.025,.564),dark,.007)
 for x in [cx-.178,cx+.178]:box('Dispenser black inner recess side',(x,-.251,1.064),(.014,.165,.564),black,.004)
 box('Dispenser recess top underside',(cx,-.251,1.321),(.365,.165,.018),black,.005)
 box('Dispenser recess lower tray support',(cx,-.253,.807),(.365,.178,.026),black,.005)
 box('Dispenser silver drip tray',(cx,-.260,.824),(.321,.141,.006),steel,.004)
 for i in range([10,7,4][LOD]):box('Drip tray slot',(cx-.135+i*.27/([10,7,4][LOD]-1),-.262,.828),(.007,.109,.001),dark,.002)
 box('Dispenser upper outlet block',(cx,-.222,1.273),(.096,.076,.069),black,.006)
 cylinder('Dispenser short silver outlet',(cx,-.252,1.222),.012,.042,steel)
 # No brand text, lights or unsupported functionality implied.

def mesh_bounds():
 bpy.context.view_layer.update();objs=[o for o in bpy.context.scene.objects if o.type=='MESH'];pts=[o.matrix_world@v.co for o in objs for v in o.data.vertices]
 assert pts
 bb=[[min(p[i] for p in pts) for i in range(3)],[max(p[i] for p in pts) for i in range(3)]]
 return objs,bb

def assemble(kind):
 if kind=='pantry':
  for asset,build,delta in [('counter',counter,(0,0,0)),('sink',sink_faucets,(0,0,.90)),('grey',grey_appliance,(-.82,.04,.90)),('white',white_appliance,(.76,.04,.90)),('wall',backsplash_shelves,(0,0,.90))]:
   before=set(bpy.context.scene.objects);build()
   for o in set(bpy.context.scene.objects)-before:o.location+=Vector(delta);o['assembly_component']=asset
 else:
  fridge();wood_surround()

def render_scene(name,kind):
 global LOD
 bpy.ops.wm.read_factory_settings(use_empty=True);LOD=0;palette();assemble(kind);objs,bb=mesh_bounds()
 # These source scenes contain only actual asset meshes; stage/camera/lights are added afterward.
 bpy.context.scene.unit_settings.system='METRIC';bpy.context.preferences.filepaths.save_version=0
 if '--save-assembly' in sys.argv:
  folder=OUT/('photo_pantry_assembly' if kind=='pantry' else 'photo_fridge_assembly_recess_verified');folder.mkdir(exist_ok=True)
  bpy.ops.wm.save_as_mainfile(filepath=str(folder/(folder.name+'.blend')))
 floor=mat('Render stage warm neutral',(.35,.36,.34),0,.8);box('RENDER ONLY floor',(0,0,-.022),(200,200,.04),floor)
 if kind=='pantry':
  target=Vector((.0,.0,1.18));loc=Vector((2.48,-3.13,2.30));lens=47;res=(1400,1000)
  if name.startswith('photo_pantry_sink_close'):target=Vector((.00,.03,1.02));loc=Vector((1.10,-1.46,2.01));lens=52;res=(1250,950)
 else: target=Vector((.31,0,1.28));loc=Vector((-2.45,-4.10,2.55));lens=49;res=(1050,1300)
 bpy.ops.object.camera_add(location=loc);cam=bpy.context.object;cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='PERSP';cam.data.lens=lens;bpy.context.scene.camera=cam
 for pos,power,size in [((-2.8,-2,4.8),900,4),((2,-2,3.2),550,3),((0,1.7,4),500,2)]:
  bpy.ops.object.light_add(type='AREA',location=pos);o=bpy.context.object;o.data.energy=power;o.data.shape='DISK';o.data.size=size;o.rotation_euler=(target-o.location).to_track_quat('-Z','Y').to_euler()
 sc=bpy.context.scene;sc.world=bpy.data.worlds.new('Soft neutral daylight');sc.world.color=(.26,.26,.26);sc.render.engine='CYCLES';sc.cycles.device='CPU';sc.cycles.samples=80;sc.cycles.use_denoising=False;sc.render.resolution_x,sc.render.resolution_y=res;sc.render.resolution_percentage=100;sc.view_settings.view_transform='AgX';sc.view_settings.exposure=-1.0;sc.view_settings.look='AgX - Medium High Contrast';sc.render.image_settings.file_format='PNG';sc.render.filepath=str(REVIEW/(name+'.png'));bpy.ops.render.render(write_still=True)

assets=[('photo_pantry_counter',counter),('photo_pantry_sink_faucets',sink_faucets),('photo_pantry_grey_roundfront_appliance',grey_appliance),('photo_pantry_white_cleartop_appliance',white_appliance),('photo_pantry_backsplash_shelves',backsplash_shelves),('photo_side_by_side_fridge',fridge),('photo_fridge_wood_surround',wood_surround)]
if '--render-only' not in sys.argv:
 only=next((a.split('=',1)[1] for a in sys.argv if a.startswith('--asset=')),None)
 if only and (REVIEW/'pantry_build_report.json').exists():records=[r for r in json.loads((REVIEW/'pantry_build_report.json').read_text())['records'] if r['asset']!=only]
 for asset,build in assets:
  if only and asset!=only:continue
  for LOD in range(3):
   bpy.ops.wm.read_factory_settings(use_empty=True);bpy.context.preferences.filepaths.save_version=0;bpy.context.scene.unit_settings.system='METRIC';palette();build();objs,bb=mesh_bounds();folder=OUT/asset;folder.mkdir(exist_ok=True)
   for o in objs:o['source_kind']='Original mesh rebuilt from provided photograph';o['dimensions_status']='Proportional estimate, not site measurement'
   p=folder/f'lod{LOD}_source.glb';bpy.ops.export_scene.gltf(filepath=str(p),export_format='GLB',export_extras=True,export_yup=True)
   tris=sum(len(f.vertices)-2 for o in objs for f in o.data.polygons)
   records.append({'asset':asset,'level':LOD,'triangles':tris,'boundsBlenderXYZ':bb,'sizeBlenderXYZ':[bb[1][i]-bb[0][i] for i in range(3)],'meshParts':len(objs),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
   if LOD==0:bpy.ops.wm.save_as_mainfile(filepath=str(folder/(asset+'.blend')))
 report={'blender':bpy.app.version_string,'units':'m','scope':'Photo-informed separate reusable pantry and fridge meshes. CPU renders only. No browser or Godot integration.','records':records,'evidence':{'counter':'20cf5f2245e7838e162e09cd159d821e.jpg','fridge':'abcec3406673d164144a91b9aa23ce0d.jpg','imagesVisuallyInspected':True,'dimensions':'All dimensions are proportional estimates; cropped or hidden surfaces simplified.','privateTextures':False,'brandsLabelsQR':False,'unknownAppliances':'The user identifies the grey unit as a microwave. The white clear-top vented unit is identified by visible appearance only. Exact manufacturers and models are unverified.','fridgeDispenser':'The adjacent black dispenser recess is modeled only as part of the independent wood cabinet surround, not the fridge.'},'validation':{'boundsMethod':'Actual transformed mesh vertices, not object bounding boxes','bevelCap':'.45 * smallest component dimension','renderEngine':'Cycles CPU','browserTested':False,'runtimeIntegrated':False},'assemblyPlacementBlenderXYZ':{'photo_pantry_counter':[0,0,0],'photo_pantry_sink_faucets':[0,0,.90],'photo_pantry_grey_roundfront_appliance':[-.82,.04,.90],'photo_pantry_white_cleartop_appliance':[.76,.04,.90],'photo_pantry_backsplash_shelves':[0,0,.90],'photo_side_by_side_fridge':[0,0,0],'photo_fridge_wood_surround':[0,0,0]}}
 (REVIEW/'pantry_build_report.json').write_text(json.dumps(report,indent=2))
if '--skip-render' not in sys.argv:
 for name,kind in [('photo_pantry_counter_near_final','pantry'),('photo_pantry_sink_close_final','pantry'),('photo_fridge_recess_verified','fridge')]:
  if any(a.startswith('--render=') for a in sys.argv) and '--render='+name not in sys.argv:continue
  render_scene(name,kind)
print('PANTRY BUILD FINISHED')
