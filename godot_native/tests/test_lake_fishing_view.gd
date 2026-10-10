extends SceneTree
## Layout/input fixtures only. They do not grant a story catch or prove manual play.
var checks := 0
var failures := 0
var host: Control

func _initialize() -> void: run.call_deferred()
func frames(count: int=3) -> void:
	for i in range(count): await process_frame
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1;push_error("LAKE VIEW: "+label)
func mouse(point: Vector2,pressed: bool) -> void:
	var event:=InputEventMouseButton.new()
	event.position=point;event.global_position=point;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed
	root.push_input(event,true);await frames()
func touch(point: Vector2,pressed: bool,canceled: bool=false,index: int=4) -> void:
	var event:=InputEventScreenTouch.new()
	event.index=index;event.position=point;event.pressed=pressed;event.canceled=canceled
	root.push_input(event,true);await frames()
func model_snapshot() -> String:
	return JSON.stringify({"elapsed":host.model.elapsed,"tick":host.model.physics_tick,"inputs":host.model.inputs,"controls":host.model.controls,"notes":host.model.notes,"stage":host.model.stage,"phase":host.model.phase,"tension":host.model.tension,"line":host.model.line_x})

func run() -> void:
	var state: Node=root.get_node("State")
	state.developer_mode=true
	for dimensions: Vector2i in [Vector2i(390,844),Vector2i(430,860),Vector2i(1180,812),Vector2i(844,390)]:
		root.size=dimensions
		host=load("res://scripts/ui/minigame_host.gd").new()
		host.size=Vector2(960,540)
		root.add_child(host);await frames()
		check(not is_instance_valid(host.fishing_view),"unconfigured activities do not allocate unrelated fishing artwork")
		host.setup({"type":"rhythm","chartId":"locker_key","spotId":"locker_key","title":"锈蚀钥匙","session_id":"view-fixture","control_scheme":"touch"})
		host.configure_activity_layout(Vector2(dimensions),dimensions.x<1100)
		host.set_process(false);await frames()
		check(host.uses_activity_layout() and host.scale==Vector2.ONE,"rhythm owns one unscaled activity surface")
		check(host.fishing_view.visible and host.fishing_view.background!=null and host.fishing_view.angler!=null,"cleanplate and independent angler textures load")
		check(host.fishing_view.actor_textures.size()==3,"three independent actor textures are owned by the view")
		for actor_key: String in ["fish","swan","creature"]:
			var texture: Texture2D=host.fishing_view.actor_textures[actor_key]
			check(texture!=null and texture.get_width()>0,"approved actor texture loads: "+actor_key)
			check(Rect2(Vector2.ZERO,texture.get_size()).encloses(host.fishing_view.ACTOR_REGIONS[actor_key]),"alpha-bound crop fits the original PNG: "+actor_key)
		check(host.fishing_view.size.y>=dimensions.y*.60,"field uses useful height instead of whole-host letterbox")
		check(not host.headline.visible and not host.hint.visible,"one readable label owner replaces old scaled labels")
		for key in ["target","phase","instruction","beat_action","next_beat","count_in"]:
			check(host.fishing_view.labels[key].get_theme_constant("outline_size")>=1 and host.fishing_view.labels[key].get_theme_color("font_outline_color")==host.fishing_view.INK,"compact source-ink cue edge remains defined: "+key)
		for button: Button in [host.start_button,host.pause_button,host.retry_button,host.exit_button]:
			check(button.size.x>=44 and button.size.y>=44,"toolbar/start has physical44px target")
			check(Rect2(Vector2.ZERO,Vector2(dimensions)).encloses(button.get_rect()),"toolbar/start remains in viewport")
		if dimensions.y<420:
			check(not host.fishing_view.labels.modal_body.get_rect().intersects(host.start_button.get_rect()),"short-landscape ready instruction stays above Start")
		check(not is_instance_valid(host.fishing_controls_button) or not host.fishing_controls_button.visible,"removed touch-toggle stays absent")
		check(is_equal_approx(host.fishing_view.size.y,float(dimensions.y)-50),"both schemes reserve only the essential 50px footer")
		for i in range(4):check(host.fishing_view.labels.has("beat"+str(i)),"original four rhythm labels remain code-owned")
		check(not host.fishing_view.labels.has("beat4"),"no fifth rhythm node is introduced")
		var before:=model_snapshot()
		for i in range(12):host.fishing_view.advance_view(.016)
		check(model_snapshot()==before,"view updates never advance or mutate model")
		host.begin();await frames()
		for button: Button in host.control_buttons.values():
			check(not button.visible,"direct-water mode has no simulated action row")
		var point: Vector2=host.fishing_view.size*Vector2(.7,.5)
		await mouse(point,true)
		check(host.model.controls.has("hook") and host.fishing_pointer=="field_mouse","real field press holds hook once")
		check(host.model.controls.has("right"),"field position drives original right-control input")
		var attempts: int=host.model.cast_attempts
		host._process(.1);host._process(.1);host._process(.1);host._process(.1)
		await mouse(Vector2(-20,-20),false)
		check(host.fishing_pointer.is_empty() and host.model.controls.is_empty(),"release outside releases both field owners")
		check(host.model.cast_attempts==attempts+1,"one field release creates only one cast attempt")
		host.restart();host.begin();await frames()
		await touch(point,true)
		check(host.model.controls.has("hook"),"touch field press holds hook")
		await touch(point,false,true)
		check(host.model.cast_attempts==0 and host.model.controls.is_empty(),"touch cancel is neutral, never a scored release")
		await touch(point,true)
		host.toggle_pause();await frames()
		var paused_snapshot:=model_snapshot()
		var visual_time: float=host.fishing_view.visual_time
		host._process(.5)
		check(host.model.controls.is_empty() and host.fishing_pointer.is_empty(),"pause clears pointer/control ownership")
		check(model_snapshot()==paused_snapshot and host.fishing_view.visual_time==visual_time,"pause freezes game and presentation clocks")
		host.restart();await frames()
		check(not host.paused and not host.running and host.model.cast_attempts==0,"Retry returns a fresh ready attempt")
		host.begin();await touch(point,true)
		host.configure_activity_layout(Vector2(dimensions)+Vector2(1,0),dimensions.x<1100)
		check(host.model.controls.is_empty() and host.fishing_pointer.is_empty() and host.model.cast_attempts==0,"resize neutralizes held pointer without committing a cast")
		host.fishing_view.reduced_motion=true
		before=model_snapshot();host.fishing_view.advance_view(.5)
		check(model_snapshot()==before,"reduced motion has no gameplay authority")
		host.model.phase="completed";host.model.final_result={"passed":false,"notes_hit":0};host.running=false
		host.fishing_view.advance_view(0)
		check(host.fishing_view.labels.result.text=="这次，湖把你钓走了" and "0 / 8" in host.fishing_view.labels.result_body.text,"failed chart keeps correct terminal outcome and count")
		if dimensions.y<420:
			check(not host.fishing_view.labels.result_body.get_rect().intersects(host.start_button.get_rect()),"short-landscape result body stays above Retry")
		host.sent=true;host.fishing_view.advance_view(0)
		check(host.fishing_view.labels.result.text=="这一口，湖认输了","success presentation has distinct source title")
		host.queue_free();await frames()
	print("LAKE_FISHING_VIEW: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
