extends SceneTree
const View=preload("res://scripts/presentation/chase3d/source_chase_3d.gd")
const Model=preload("res://scripts/games/chase_stunt_model.gd")
var checks:=0
var failures:=0
func _initialize() -> void:run.call_deferred()
func check(value: bool,label: String) -> void:
	checks+=1
	if not value:failures+=1;push_error(label)
func triangles(node: Node) -> int:
	var result:=0
	for mesh: MeshInstance3D in node.find_children("*","MeshInstance3D",true,false):
		for surface in range(mesh.mesh.get_surface_count()):
			var arrays:=mesh.mesh.surface_get_arrays(surface)
			result+=int((arrays[Mesh.ARRAY_INDEX].size() if arrays[Mesh.ARRAY_INDEX]!=null else arrays[Mesh.ARRAY_VERTEX].size())/3)
	return result
func run() -> void:
	var view:=View.new();view.asset_directory="res://assets/native_755/ride/";root.add_child(view);await process_frame
	check(view.ready3d,"sourceFX resource load")
	check(triangles(view.bell)==96,"original RingGeometry .93/1/48,96 triangles")
	check(triangles(view.shield)==640,"original TorusGeometry1.25/.05/8/40,640 triangles")
	var model:=Model.new();model.distance=35;model.tick=1;model.lane=.5;model.bell_pulse=.8;model.shield=true
	view.update_view(model,1.0/60,false)
	check(view.bell.visible and view.shield.visible,"modelFX visible")
	check(view.bell.position.distance_to(Vector3(-1.675,.14,-39.75))<.00001,"bell ring source ground contact")
	check(view.bell.scale.distance_to(Vector3.ONE*3)<.00001,"bell ring original pulse expansion")
	check(absf(view.bell_material.albedo_color.a-.576)<.00001,"source pulse opacity .72")
	check(view.shield.position.distance_to(view.hero.position+Vector3(0,1.3,0))<.00001,"source shield follows airborne bicycle")
	model.bell_pulse=0;model.shield=false;view.update_view(model,1.0/60,false)
	check(not view.bell.visible and not view.shield.visible,"sourceFX retire when model timers end")
	view.dispose();await process_frame
	print("SOURCE_EFFECTS checks=",checks," failures=",failures);quit(1 if failures else 0)
