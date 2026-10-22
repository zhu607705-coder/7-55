extends SceneTree
const View=preload("res://scripts/presentation/chase3d/source_chase_3d.gd")
const Model=preload("res://scripts/games/chase_stunt_model.gd")
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(value: bool,label: String) -> void:
	checks+=1
	if not value:failures+=1;push_error(label)
func run() -> void:
	for tier: Dictionary in [{"ms":34.0,"name":"high","far":150.0,"width":960},{"ms":65.0,"name":"balanced","far":115.0,"width":960},{"ms":66.0,"name":"light","far":92.0,"width":749}]:
		var view:=View.new();view.configure({"asset_directory":"res://assets/native_755/ride/","live_shadows":true});root.add_child(view)
		var model:=Model.new();var before: int=model.tick
		for i in range(10):view.update_view(model,.016,false,false)
		check(view.animation_seconds==0 and model.tick==before,"ready camera settles without running simulation or ride animation")
		check(view.camera.position.x>0 and view.camera.fov>51,"source ready-state camera easing is retained")
		view.observe_frame_time(0);view.observe_frame_time(1001)
		check(view.measured_frames==0,"source excludes invalid/over-one-second timing samples")
		for i in range(23):view.observe_frame_time(tier.ms)
		check(view.quality=="high","quality cannot change before source24-frame measurement")
		view.observe_frame_time(tier.ms)
		check(view.quality==tier.name and is_equal_approx(view.camera.far,tier.far),"exact original quality threshold and clipping distance")
		check(view.viewport_resolution.x==tier.width,"exact source pixel ratio for native1x CSS dimensions")
		check(view.sun.shadow_enabled==(tier.name=="high"),"source slow-frame tiers disable only authored live-shadow path")
		view.fit_resolution(Vector2(370,208.125))
		check(view.viewport_resolution.x==(374 if tier.name=="light" else 480),"mobile applies source480 minimum before quality pixel ratio")
		check(model.tick==before,"quality adaptation never mutates game clock or difficulty")
		view.dispose();await process_frame
	print("NATIVE_CHASE_QUALITY: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
