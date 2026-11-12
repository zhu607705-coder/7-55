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
	for tier: Dictionary in [{"ms":17.0,"name":"high","far":150.0,"scale":1.0},{"ms":33.0,"name":"balanced","far":115.0,"scale":.82},{"ms":52.0,"name":"light","far":92.0,"scale":.66}]:
		var view:=View.new();view.configure({"asset_directory":"res://assets/native_755/ride/","live_shadows":true});root.add_child(view)
		var model:=Model.new();var before: int=model.tick
		for i in range(10):view.update_view(model,.016,false,false)
		check(view.animation_seconds==0 and model.tick==before,"ready camera settles without running simulation or ride animation")
		check(absf(view.camera.position.x)<.001 and view.camera.fov>51,"ready camera lines up with the road")
		view.fit_resolution(Vector2(844,390),3.0,true)
		var full_resolution: Vector2i=view.viewport_resolution
		check(full_resolution.x>1400 and full_resolution.y>650,"mobile DPR increases detail within the compact budget")
		view.observe_frame_time(0);view.observe_frame_time(1001)
		check(view.measured_frames==0,"quality excludes invalid and suspended frames")
		for i in range(47):view.observe_frame_time(tier.ms)
		check(view.quality=="high","quality does not react to isolated slow frames")
		view.observe_frame_time(tier.ms)
		check(view.quality==tier.name and is_equal_approx(view.camera.far,tier.far),"steady frame time selects the expected render tier")
		check(absi(view.viewport_resolution.x-roundi(full_resolution.x*tier.scale))<=1,"tier changes raster size, not projection")
		check(view.sun.shadow_enabled==(tier.name=="high"),"reduced quality also retires expensive live shadows")
		view.fit_resolution(Vector2(1440,900),2.0,false)
		check(absf(Vector2(view.viewport_resolution).aspect()-1.6)<.005,"different desktop aspect stays proportional")
		check(model.tick==before,"quality adaptation never mutates game clock or difficulty")
		view.dispose();await process_frame
	print("NATIVE_CHASE_QUALITY: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
