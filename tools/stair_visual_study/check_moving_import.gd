extends SceneTree
var checks:int=0
var failures:int=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:
  failures+=1
  push_error(label)
func vec(a:Array)->Vector3:return Vector3(a[0],a[1],a[2])
func expected_point(point:Vector3,mechanism:Dictionary,state:float)->Vector3:
 if mechanism.kind=="rotate":
  var pivot:Vector3=vec(mechanism.pivot)
  return pivot+Basis(Vector3.UP,state*PI/2)*(point-pivot)
 var offset:Vector3=Vector3.ZERO
 offset[{"x":0,"y":1,"z":2}[mechanism.axis]]=float(mechanism.stepSize)*state
 return point+offset
func state_transform(mechanism:Dictionary,state:float)->Transform3D:
 var result:Transform3D=Transform3D.IDENTITY
 if mechanism.kind=="rotate":
  var pivot:Vector3=vec(mechanism.pivot)
  result.basis=Basis(Vector3.UP,state*PI/2)
  result.origin=pivot-result.basis*pivot
 else:result.origin[{"x":0,"y":1,"z":2}[mechanism.axis]]=float(mechanism.stepSize)*state
 return result
func _initialize()->void:
 var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://stair_b_snapshot.json"))
 var expected_albedo:Image=Image.load_from_file(ProjectSettings.globalize_path("res://terrazzo_pixel_albedo.png"))
 check(expected_albedo!=null,"authored texture readable")
 expected_albedo.convert(Image.FORMAT_RGBA8)
 var specs:Array=[{"owner":"b_upper_stair","file":"upper_rotating_stair","mesh_count":172},{"owner":"b_mid_lift","file":"mid_lift_platform","mesh_count":1},{"owner":"b_exit_slide","file":"exit_slide_platform","mesh_count":1}]
 for spec in specs:
  var resource:PackedScene=load("res://%s.glb"%spec.file)
  check(resource!=null,"import %s"%spec.file)
  if resource==null:continue
  var instance:Node3D=resource.instantiate();root.add_child(instance)
  await process_frame
  var owner:Node3D=instance.find_child(spec.owner,true,false)
  check(owner!=null,"source owner %s"%spec.owner)
  if owner==null:instance.queue_free();continue
  check(owner.transform.is_equal_approx(Transform3D.IDENTITY),"owner identity before runtime mechanism")
  var mechanism:Dictionary={}
  for m in data.level.mechanisms:
   if m.id==spec.owner:mechanism=m
  var witnesses:Array=[]
  if spec.owner=="b_upper_stair":
   var stair:Dictionary=data.level.geometry.stairs[1]
   var start:Vector3=vec(stair.from);var finish:Vector3=vec(stair.to)
   var direction:Vector3=finish-start
   var source_basis:Basis=Basis(Vector3.UP,-atan2(direction.z,direction.x))
   for i in range(stair.steps):
    var mesh:MeshInstance3D=instance.find_child("b_upper_stair_span_tread_%02d"%i,true,false)
    check(mesh!=null,"upper source tread %d"%i)
    if mesh==null:continue
    var expected:Vector3=start.lerp(finish,(i+.5)/stair.steps)-Vector3(0,.13,0)
    check(mesh.global_position.distance_to(expected)<.00001,"upper world center %d"%i)
    var size:Vector3=mesh.mesh.get_aabb().size
    check(size.distance_to(Vector3(Vector2(direction.x,direction.z).length()/stair.steps+.07,.26,stair.width))<.00001,"upper all three source dimensions %d"%i)
    check(mesh.global_basis.is_equal_approx(source_basis),"upper source tread orientation %d"%i)
    witnesses.append({"mesh":mesh,"local":Vector3.ZERO,"source":expected})
  else:
   var platform:Dictionary={}
   for plat in data.level.geometry.platforms:
    if plat.ownerId==spec.owner:platform=plat
   var mesh:MeshInstance3D=instance.find_child(platform.id,true,false)
   check(mesh!=null,"platform source identity")
   if mesh!=null:
    var points:PackedVector3Array=PackedVector3Array()
    for surface in range(mesh.mesh.get_surface_count()):points.append_array(mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX])
    var bounds:AABB=AABB(points[0],Vector3.ZERO)
    for point in points:bounds=bounds.expand(point)
    # Render culling AABBs pad zero-height strip surfaces by 1e-5; inspect actual vertices instead.
    check(bounds.size.distance_to(vec(platform.size))<.00001,"exact source platform dimensions")
    check((mesh.global_transform*bounds.get_center()).distance_to(vec(platform.center))<.00001,"exact source platform center")
    check(absf(bounds.end.y-(platform.center[1]+platform.size[1]/2))<.00001,"exact source walking plane")
    witnesses.append({"mesh":mesh,"local":bounds.get_center(),"source":vec(platform.center)})
  var test_states:Array=range(int(mechanism.stateCount))
  test_states.append_array([0.25,0.5,1.5])
  for state in test_states:
   owner.transform=state_transform(mechanism,state)
   for w in witnesses:
    check((w.mesh.global_transform*w.local).distance_to(expected_point(w.source,mechanism,state))<.00003,"%s source transform state %.2f"%[spec.owner,state])
  owner.transform=Transform3D.IDENTITY
  var queue:Array=[instance];var mesh_count:int=0;var colliders:int=0;var textured:int=0
  while not queue.is_empty():
   var node:Node=queue.pop_front();queue.append_array(node.get_children())
   if node is CollisionObject3D:colliders+=1
   if node is MeshInstance3D:
    mesh_count+=1
    var mi:MeshInstance3D=node
    for surface in range(mi.mesh.get_surface_count()):
     var mat:Material=mi.get_active_material(surface)
     check(mat is StandardMaterial3D,"standard PBR material")
     if mat is StandardMaterial3D and mat.albedo_texture!=null:
      textured+=1
      check(mat.texture_filter in [BaseMaterial3D.TEXTURE_FILTER_NEAREST,BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS],"nearest texture filter")
      var imported:Image=mat.albedo_texture.get_image()
      if imported.is_compressed():imported.decompress()
      imported.convert(Image.FORMAT_RGBA8);imported.clear_mipmaps()
      check(imported.get_size()==Vector2i(128,128),"128 square albedo")
      check(imported.get_data()==expected_albedo.get_data(),"exact approved texture pixels")
      check(absf(mat.roughness-.92)<.00001 and mat.metallic==0,"approved stone PBR values")
  check(colliders==0,"no collision changes")
  check(mesh_count==spec.mesh_count,"only selected module geometry")
  check(textured>0,"textured surfaces imported")
  print("MODULE_OK ",spec.owner," meshes=",mesh_count," textured=",textured," states=",mechanism.stateCount)
  instance.queue_free();await process_frame
 print("MOVING_IMPORT checks=",checks," failures=",failures)
 quit(1 if failures else 0)
