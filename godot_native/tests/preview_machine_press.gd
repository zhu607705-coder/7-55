extends Control
## Isolated rendering fixture using the real panel and unchanged controller.
const Chapter=preload("res://scripts/chapters/chapter3.gd")
var d:Dictionary
var chapter=Chapter.new()
var panel:Control
func _ready()->void:
	theme=Theme.new();theme.default_font=load("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	d=JSON.parse_string(FileAccess.get_file_as_string("res://data/initial_state.json"))
	d.native={"chapter":3,"page":"c3_canteen","scene":"canteen_interior","mode":"light","settings":{},"player":{}}
	d.canteenHunt.active=true;d.canteenHunt.phase="tray_search";d.canteenHunt.entryPaperEscaped=true
	d.runtimeMode="rpg";d.rpgScene="canteen_interior"
	for id:String in chapter.RECIPE:d.items[id]=true
	var mixer:Dictionary=chapter.get_definition("canteen_interior","canteen-mixer",d)
	var point:Dictionary=mixer.get("stand",{"x":mixer.x,"y":mixer.y})
	d.native.player={"x":point.x,"y":point.y}
	panel=preload("res://scripts/ui/c3_mixer_panel.gd").new();add_child(panel)
	var rng:=RandomNumberGenerator.new();rng.seed=8
	panel.setup(func()->Dictionary:return d,func(action:String,value:Variant)->Dictionary:return chapter.dispatch(d,action,value),Callable(),rng)
	panel.set_process(false);panel.surface.motion.set_process(false)
	resized.connect(_layout);_layout()
	_capture.call_deferred()
func _layout()->void:
	if panel:panel.configure_layout(size,true)
func _capture()->void:
	for dims:Vector2i in [Vector2i(1100,800),Vector2i(390,844),Vector2i(844,390)]:
		get_window().size=dims
		await get_tree().process_frame
		_layout()
		if not d.items.sparklingWater:
			d.items.sparklingWater=true;d.canteenHunt.drinkMixSequence=[]
		panel.surface.cancel_presentation();panel.refresh()
		await RenderingServer.frame_post_draw
		_save("mixer-machine-idle")
		panel._pour(panel.session.button_order.find("sparklingWater"))
		panel.surface.motion.sample_pose(panel.surface.motion.duration_ms*.4);panel.surface._process(0)
		await RenderingServer.frame_post_draw
		_save("mixer-machine-flow")
		panel.surface.motion.sample_pose(panel.surface.motion.duration_ms*.78);panel.surface._process(0)
		await RenderingServer.frame_post_draw
		_save("mixer-machine-rebound")
	get_window().size=Vector2i(1100,800)
	await get_tree().process_frame
	_layout()
	panel.surface.motion.sample_pose(panel.surface.motion.duration_ms*.4);panel.surface._process(0)
func _save(label:String)->void:
	var dir:String=ProjectSettings.globalize_path("res://../../evidence")
	DirAccess.make_dir_recursive_absolute(dir)
	get_viewport().get_texture().get_image().save_png(dir+"/"+label+"-"+str(int(size.x))+"x"+str(int(size.y))+".png")
