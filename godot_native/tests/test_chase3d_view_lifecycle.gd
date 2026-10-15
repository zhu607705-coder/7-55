extends SceneTree
const View=preload("res://scripts/presentation/chase3d/source_chase_3d.gd")
const Model=preload("res://scripts/games/chase_stunt_model.gd")
var checks:=0
var failures:=0
func _initialize() -> void:run.call_deferred()
func check(value: bool,message: String) -> void:
	checks+=1
	if not value:failures+=1;push_error(message)
func snapshot(model: RefCounted) -> String:
	var value: Dictionary={}
	for property: Dictionary in model.get_property_list():
		if property.usage&PROPERTY_USAGE_SCRIPT_VARIABLE:value[property.name]=model.get(property.name)
	return JSON.stringify(value)
func pose_snapshot(view: Control) -> String:
	var value: Array=[view.animation_seconds,view.pedal_phase,view.wheel_phase,view.camera.transform,view.camera.fov,view.hero.transform]
	for entry: Dictionary in view.hero.bones.values():value.append(entry.skeleton.get_bone_global_pose(entry.bone))
	return var_to_str(value)
func run() -> void:
	var view:=View.new();view.asset_directory="res://assets/native_755/ride/"
	check(view.configure({"render_width":960,"live_shadows":false}),"configure before enter-tree")
	view.size=Vector2(430,500);root.add_child(view);await process_frame
	check(view.ready3d and view.failure_reason.is_empty(),"all source resources loaded")
	check(not view.configure({}),"configure cannot rebuild an active world")
	check(view.viewport3d.size==Vector2i(960,540),"source camera retains16:9 internal film")
	check(view.surface.stretch_mode==TextureRect.STRETCH_KEEP_ASPECT_CENTERED,"portrait contains film without aspect distortion")
	check(view.camera.keep_aspect==Camera3D.KEEP_HEIGHT,"source verticalFOV retained")
	check(is_equal_approx(view.camera.near,.1) and is_equal_approx(view.camera.far,150),"source near/far .1/150")
	var model:=Model.new();var before:=snapshot(model)
	view.update_view(model,1.0/60,false)
	check(snapshot(model)==before,"initial update is read-only")
	check(view.viewport3d.own_world_3d,"renderer lighting/camera isolated from main game")
	var frozen:=pose_snapshot(view)
	for i in range(10):view.update_view(model,.25,true)
	check(pose_snapshot(view)==frozen,"pause freezes camera, body, all bones, pedal/wheel phase")
	check(snapshot(model)==before,"paused updates read-only")
	check(view.viewport3d.render_target_update_mode==SubViewport.UPDATE_DISABLED,"paused view requests no GPU frames")
	view.reset_view()
	check(snapshot(model)==before,"reset is read-only")
	check(not view.presented and not view.view_paused and view.pedal_phase==0,"reset clears presentation clock for retry")
	view.update_view(model,1.0/60,false)
	check(snapshot(model)==before,"resume is read-only")
	model.distance=35;model.tick=120;model.held.left=true;model.air_height=.5;model.charge=.4
	before=snapshot(model);view.update_view(model,1.0/60,false)
	check(snapshot(model)==before,"steering/jump render is read-only")
	var visible_hazards:=0
	for item: Dictionary in model.obstacles:
		var ahead: float=item.distance-model.distance
		if ahead>0 and ahead<=96:visible_hazards+=1
	check(view.obstacles.size()==visible_hazards,"full original96m obstacle horizon, no presentation collision authority")
	var z: float=-model.distance*1.05
	for item: Dictionary in view.manifest.world_chunks:
		if item.shared or (item.max_z>=z-115 and item.min_z<=z+20):check(view.chunks.has(item.asset),"full source high-quality115-unit road ahead and20 behind")
	view.reset_view();check(snapshot(model)==before,"retry presentation cannot clear held input or distance")
	view.dispose();check(snapshot(model)==before,"dispose cannot change model/proof/save")
	check(view.disposed and not view.ready3d,"dispose closes presentation admission")
	view.update_view(model,.25,false);check(snapshot(model)==before,"post-dispose update inert")
	view.dispose();await process_frame
	check(not is_instance_valid(view),"owned viewport/world freed after dispose")
	print("SOURCE_VIEW_LIFECYCLE checks=",checks," failures=",failures);quit(1 if failures else 0)
