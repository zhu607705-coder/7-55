extends SceneTree
var checks:int=0
var failures:int=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:
  failures+=1
  push_error(label)
func _initialize()->void:
 var resource:PackedScene=load("res://lower_rotating_stair.glb")
 check(resource!=null,"GLB imports as PackedScene")
 if resource==null:quit(1);return
 var instance:Node=resource.instantiate();root.add_child(instance)
 await process_frame
 var owner:Node3D=instance.find_child("b_lower_stair",true,false)
 check(owner!=null,"original mechanism owner retained")
 var input:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://stair_b_snapshot.json"))
 var stair:Dictionary=input.level.geometry.stairs[0]
 var start:Vector3=Vector3(stair.from[0],stair.from[1],stair.from[2])
 var finish:Vector3=Vector3(stair.to[0],stair.to[1],stair.to[2])
 for i in range(12):
  var mesh:MeshInstance3D=instance.find_child("b_lower_stair_span_tread_%02d"%i,true,false)
  check(mesh!=null,"source tread survives GLB %d"%i)
  if mesh==null:continue
  var expected:Vector3=start.lerp(finish,(i+.5)/12)-Vector3(0,.13,0)
  check(mesh.global_position.distance_to(expected)<0.00001,"Godot world coordinate roundtrip %d"%i)
  var bounds:AABB=mesh.mesh.get_aabb()
  var expected_run:float=Vector2(finish.x-start.x,finish.z-start.z).length()/12+.07
  check(absf(bounds.size.x-expected_run)<.00001 and absf(bounds.size.y-.26)<.00001 and absf(bounds.size.z-1.34)<.00001 and mesh.global_basis.is_equal_approx(Basis.IDENTITY),"source walking dimensions and lower-stair orientation unchanged %d"%i)
 var queue:Array=[instance]
 var colliders:int=0
 var mesh_count:int=0
 var textured:int=0
 var expected_albedo:Image=Image.load_from_file("res://terrazzo_pixel_albedo.png")
 check(expected_albedo!=null,"authored PNG available for exact import comparison")
 if expected_albedo!=null:expected_albedo.convert(Image.FORMAT_RGBA8)
 while not queue.is_empty():
  var node:Node=queue.pop_front()
  queue.append_array(node.get_children())
  if node is CollisionObject3D:colliders+=1
  if node is MeshInstance3D:
   mesh_count+=1
   var mi:MeshInstance3D=node
   for surface in range(mi.mesh.get_surface_count()):
    var mat:Material=mi.get_active_material(surface)
    if mat is StandardMaterial3D and mat.albedo_texture!=null:
     textured+=1
     check(mat.texture_filter in [BaseMaterial3D.TEXTURE_FILTER_NEAREST,BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS],"pixel sampling retained on import")
     var imported:Image=mat.albedo_texture.get_image()
     if imported.is_compressed():imported.decompress()
     imported.convert(Image.FORMAT_RGBA8)
     # Image.get_data includes lower mip levels; compare the original base level.
     imported.clear_mipmaps()
     check(imported.get_size()==Vector2i(128,128),"embedded 128 square albedo retained")
     check(expected_albedo!=null and imported.get_data()==expected_albedo.get_data(),"all embedded albedo pixels survive Godot import exactly")
     check(absf(mat.roughness-.92)<.00001 and mat.metallic==0,"terrazzo PBR factors retained")
 check(colliders==0,"asset introduces no game collision authority")
 check(mesh_count==177,"only selected visible geometry exported")
 check(textured>=12,"stone material survives GLB import")
 print("REFINED_IMPORT checks=",checks," failures=",failures," meshes=",mesh_count," textured=",textured," colliders=",colliders)
 quit(1 if failures else 0)
