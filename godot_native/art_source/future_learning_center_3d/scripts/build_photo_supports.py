"""Additional photo candidates. Reuses original helper definitions, never rebuilds the first three assets."""
from pathlib import Path
helper=Path(__file__).with_name('build_photo_desktop.py')
exec(compile(helper.read_text().split("assets=[('photo_monitor_stand'")[0],str(helper),'exec'))
records=[]
def support_palette():
 global fabric,edge,armmetal,dark,cap
 fabric=material('Grey fabric approximate parameter PBR',(.25,.26,.25),0,.94)
 edge=material('Charcoal rounded divider border',(.075,.083,.081),0,.72)
 armmetal=material('Silver grey support shell',(.36,.40,.41),.65,.34)
 dark=material('Dark structural arm',(.023,.031,.033),.55,.32)
 cap=material('Matte joint covers',(.037,.043,.045),0,.55)
def divider():
 # Two visible planes only. Lengths are provisional, no invented cubicle/doors.
 box('Rear divider dark border',(0,.35,.21),(1.60,.026,.42),edge,.007)
 box('Rear divider grey fabric front',(0,.334,.21),(1.578,.007,.398),fabric,.004)
 box('Rear divider grey fabric reverse',(0,.366,.21),(1.578,.007,.398),fabric,.004)
 box('Right return divider dark border',(.80,.025,.21),(.026,.650,.420),edge,.007)
 box('Right return grey fabric inside',(.784,.025,.21),(.007,.628,.398),fabric,.004)
 box('Right return grey fabric outside',(.816,.025,.21),(.007,.628,.398),fabric,.004)
 # Base attachment is occluded: no guessed screw/clip pattern added.
def bar(name,a,b,w,d,mat):
 a,b=Vector(a),Vector(b);o=box(name,(a+b)/2,(w,d,(b-a).length),mat,.004);o.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler();return o
def arm():
 # Visible right-side diagonal linkage, neutral pose rather than manufacturer kinematics.
 # Clamp and head are simplified inferred interfaces because occluded in photograph.
 box('Inferred desk clamp upper pad',(0,.025,.036),(.080,.070,.012),dark,.004)
 box('Inferred desk clamp vertical web',(0,.061,.0),(.060,.012,.078),dark,.003)
 box('Inferred clamp lower pad',(0,.028,-.033),(.060,.065,.012),dark,.003)
 cyl('Inferred clamp screw',(0,.018,-.047),.005,.034,armmetal)
 box('Inferred clamp screw grip',(0,.018,-.065),(.040,.010,.008),cap,.003)
 cyl('Base swivel joint',(0,.025,.068),.027,.060,dark)
 a=(0,.025,.095);b=(.055,.045,.260);c=(.205,.055,.425)
 bar('Lower silver support segment',a,b,.045,.036,armmetal)
 bar('Lower dark insert',(0,.004,.100),(.055,.024,.252),.025,.009,dark)
 cyl('Visible elbow joint',b,.033,.048,dark,'Y')
 bar('Upper diagonal silver support segment',b,c,.050,.039,armmetal)
 bar('Upper diagonal dark insert',(.060,.022,.267),(.202,.033,.420),.029,.009,dark)
 cyl('Display tilt joint',c,.025,.047,dark,'Y')
 # Plain attachment plate: not labelled VESA and no invented hole spacing.
 box('Inferred plain display attachment',(.205,.022,.425),(.085,.014,.085),cap,.007)
 if LOD<2:
  for p in [b,c]:cyl('Joint round cover',(p[0],p[1]-.027,p[2]),.018,.004,cap,'Y')
 box('Visible underside cable guide simplified',(.12,.081,.335),(.025,.012,.050),cap,.003)

def bounds():
 objs=[o for o in bpy.context.scene.objects if o.type=='MESH'];points=[o.matrix_world@v.co for o in objs for v in o.data.vertices]
 return objs,[[min(p[i] for p in points) for i in range(3)],[max(p[i] for p in points) for i in range(3)]]
def ground_preview():
 bpy.context.view_layer.update();_,bb=bounds()
 for o in bpy.context.scene.objects:o.location.z-=bb[0][2]
 bpy.context.view_layer.update()

# Same studio renderer, with tighter group framing for the much wider divider.
# Kept local: original three source files and their preview renderer remain unchanged.
group_renderer_source=helper.read_text().split('def render(name,arrangement=False):',1)[1].split("assets=[('photo_monitor_stand'",1)[0]
exec(compile('def render_group(name,arrangement=False):'+group_renderer_source.replace('offset*size*1.45','offset*size*1.0'),str(helper),'exec'))

extra=[('photo_desk_divider',divider),('photo_monitor_arm',arm)]
if '--render-only' not in sys.argv:
 for asset,build in extra:
  for LOD in range(3):
   bpy.ops.wm.read_factory_settings(use_empty=True);bpy.context.preferences.filepaths.save_version=0;bpy.context.scene.unit_settings.system='METRIC';support_palette();build();bpy.context.view_layer.update();objs,bb=bounds();folder=OUT/asset;folder.mkdir(exist_ok=True)
   p=folder/f'lod{LOD}_source.glb';bpy.ops.export_scene.gltf(filepath=str(p),export_format='GLB',export_extras=True,export_yup=True)
   records.append({'asset':asset,'level':LOD,'triangles':sum(len(p.vertices)-2 for o in objs for p in o.data.polygons),'boundsBlenderXYZ':bb,'sizeBlenderXYZ':[bb[1][i]-bb[0][i] for i in range(3)],'meshParts':len(objs),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
   if LOD==0:bpy.ops.wm.save_as_mainfile(filepath=str(folder/(asset+'.blend')))
 (REVIEW/'supports_build_report.json').write_text(json.dumps({'blender':bpy.app.version_string,'units':'m','scope':'Two additional provisional photo candidates. Hidden clamp/head inferred, no manufacturer replica. Original three assets unchanged.','records':records},indent=2))
if '--skip-render' not in sys.argv:
 if '--assembly-only' not in sys.argv:
  for asset,build in extra:
   if '--arm-only' in sys.argv and asset!='photo_monitor_arm':continue
   bpy.ops.wm.open_mainfile(filepath=str(OUT/asset/(asset+'.blend')));ground_preview();render(asset)
  # Structural side angle for visible elbow and the explicitly inferred desk clamp.
  bpy.ops.wm.open_mainfile(filepath=str(OUT/'photo_monitor_arm/photo_monitor_arm.blend'))
  for o in list(bpy.context.scene.objects):o.rotation_euler.z+=math.pi/2;o.location=Vector((-o.location.y,o.location.x,o.location.z))
  ground_preview();render('photo_monitor_arm_structure')
 # Keep the central display on its original base. Arm is an independent adjacent sample.
 bpy.ops.wm.read_factory_settings(use_empty=True);LOD=0
 for asset,delta in [('photo_monitor_stand',(0,.10,0)),('photo_keyboard',(-.055,-.24,0)),('photo_mouse',(.23,-.25,0)),('photo_desk_divider',(0,.16,0)),('photo_monitor_arm',(.50,.14,-.032))]:
  file=OUT/asset/(asset+'.blend')
  with bpy.data.libraries.load(str(file),link=False) as (src,dst):dst.objects=src.objects
  for o in dst.objects:
   if o:bpy.context.collection.objects.link(o);o.location+=Vector(delta)
 bpy.context.view_layer.update();render_group('photo_arrangement',True)
