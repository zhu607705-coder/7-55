extends SceneTree
## Real Main controls with emulated mouse/touch input. This is not a
## physical-phone test. All persistence uses an isolated temporary profile.
const Opening=preload("res://scripts/ui/native_opening_presentation.gd")
var shell: Control
var state: Node
var checks:=0
var failures:=0
var actions: Array=[]
var motion_samples: Array=[]
var capture_dir: String=""
var touch_point:=Vector2.ZERO

func _initialize() -> void: run.call_deferred()
func frames(count: int=3) -> void:
	for i in count: await process_frame
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error("WAKE FLASH: "+message)
func named(id: String) -> Control: return shell.page_body.find_child(id,true,false)
func rect(node: Control) -> Rect2:
	var transform:=node.get_global_transform_with_canvas()
	return Rect2(transform.origin,node.size*transform.get_scale())
func press(point: Vector2,down: bool,touch: bool=false) -> void:
	if touch:
		if not down and point!=touch_point:
			var drag:=InputEventScreenDrag.new(); drag.index=0; drag.position=point; drag.relative=point-touch_point
			Input.parse_input_event(drag); Input.flush_buffered_events(); await process_frame
		var event:=InputEventScreenTouch.new(); event.index=0; event.position=point; event.pressed=down
		Input.parse_input_event(event)
		touch_point=point
	else:
		var motion:=InputEventMouseMotion.new(); motion.position=point; motion.global_position=point; Input.parse_input_event(motion)
		var event:=InputEventMouseButton.new(); event.position=point; event.global_position=point; event.button_index=MOUSE_BUTTON_LEFT; event.pressed=down
		Input.parse_input_event(event)
	Input.flush_buffered_events(); await process_frame
func click(node: Control,touch: bool=false) -> void:
	check(is_instance_valid(node),"actual opening control exists")
	if not is_instance_valid(node): return
	var point:=rect(node).get_center()
	await press(point,true,touch); await press(point,false,touch); await frames()
func key(code: Key) -> void:
	for down in [true,false]:
		var event:=InputEventKey.new(); event.keycode=code; event.physical_keycode=code; event.pressed=down
		root.push_input(event,true); await process_frame
	await frames()
func fixture(dimensions: Vector2i,reduced: bool=false) -> void:
	state.developer_mode=true; state.d=state.initial(); state.d.native.settings.reduced_motion=reduced
	state.d.native.settings.music=false; state.d.native.settings.effects=false
	root.size=dimensions; shell.size=Vector2(dimensions)
	shell._refresh(); shell._layout(); await frames(4); actions.clear()
func open_warning(touch: bool=false) -> void:
	await click(named("OpeningAction_c1_start_alarm"),touch)
	await click(named("OpeningAction_c1_dismiss_alarm"),touch)
	check(named("WakeFlash")==null,"warning art is absent before the actual sleep choice")
	await click(named("OpeningAction_c1_wake"),touch)
	check(state.d.native.page=="desktop" and state.d.native.wake_warned,"actual choice earns the existing warning flag")
	check(actions.count("c1_wake")==1,"one pointer gesture produces one warning action")
	check(named("WakeNarration")==null and named("WakeFlash")!=null,"warning replaces scene narration")
func capture(id: String) -> void:
	if capture_dir.is_empty() or DisplayServer.get_name()=="headless": return
	await RenderingServer.frame_post_draw
	var result:=root.get_texture().get_image().save_png(capture_dir.path_join(id+".png"))
	check(result==OK,"graphical frame writes "+id)
func verify_motion(dimensions: Vector2i) -> void:
	var flash: Control=named("WakeFlash"); flash.set_process(false)
	var state_before: String=JSON.stringify(state.d)
	var button_rect:=rect(named("OpeningAction_c1_enter_home"))
	var center: Vector2=flash.position+flash.pivot_offset
	for milliseconds: int in [0,52,104,106,158,209,210,260,314,316,419,421,840]:
		flash.elapsed=0; flash._process(milliseconds/1000.0)
		var expected: Vector2=Opening.WakeFlash.sample_at(milliseconds/1000.0)
		check(is_equal_approx(flash.modulate.a,expected.x) and flash.scale.is_equal_approx(Vector2.ONE*expected.y),"source stepped opacity/scale at "+str(milliseconds)+"ms")
		check((flash.position+flash.pivot_offset).is_equal_approx(center),"scale preserves warning center")
		check(rect(named("OpeningAction_c1_enter_home"))==button_rect,"warning does not move the continuation hit area")
		check(not rect(flash).intersects(button_rect),"warning never covers continuation")
		check(rect(shell.phone).encloses(rect(flash)),"warning remains in the canonical phone")
		if milliseconds in [0,106,210,316]:
			motion_samples.append({"viewport":[dimensions.x,dimensions.y],"ms":milliseconds,"alpha":flash.modulate.a,"scale":flash.scale.x,"font_size":flash.logical_font_size})
			await capture("wake-%dx%d-%dms" % [dimensions.x,dimensions.y,milliseconds])
	check(JSON.stringify(state.d)==state_before,"presentation clocks never change story, inventory or save state")
	check(flash.mouse_filter==Control.MOUSE_FILTER_IGNORE,"decorative flash cannot capture taps")
	check(flash.text=="起床蠢货\n！！！","authored two-line warning is unchanged")
	check(flash.SHADOW_OFFSET==Vector2(4,4) and flash.MARK_SPACING==8 and flash.MARK_SHIFT==10,"source pixel shadow and punctuation layout")
	check(is_equal_approx(flash.logical_font_size,Opening.WakeFlash.font_size_at(dimensions.x)),"font uses original viewport clamp")
	for width: int in [280,320,390,430,1440]:
		root.size=Vector2i(width,dimensions.y); shell.size=Vector2(width,dimensions.y); await frames(2)
		check(is_equal_approx(flash.logical_font_size,clampf(width*.15,36.4,59.8)),"existing warning responds to resize "+str(width))
	root.size=dimensions; shell.size=Vector2(dimensions); await frames()
	var old: WeakRef=weakref(flash)
	await click(named("OpeningAction_c1_enter_home"))
	check(state.d.native.page=="phone_home" and old.get_ref()==null,"real continue releases the warning and its clock")
	check(named("WakeFlash")==null,"no cross-page flash remains")
	state.open_page("desktop"); await frames()
	check(named("WakeFlash")!=null and named("WakeFlash")!=old.get_ref(),"ordinary reentry recreates a single scene-owned display")
	var count: int=shell.page_body.find_children("WakeFlash","",true,false).size()
	shell._refresh(); await frames()
	check(count==1 and shell.page_body.find_children("WakeFlash","",true,false).size()==1,"same-page rebuild never duplicates flash owners")
func run() -> void:
	if not OS.get_user_data_dir().begins_with("/tmp/"):
		push_error("Refusing wake-flash save tests outside isolated /tmp profile"); quit(2); return
	create_timer(80).timeout.connect(func(): push_error("Wake flash watchdog"); quit(2))
	capture_dir=OS.get_environment("WAKE_CAPTURE_DIR")
	if not capture_dir.is_empty(): DirAccess.make_dir_recursive_absolute(capture_dir)
	check(is_equal_approx(Opening.WakeFlash.CYCLE_SECONDS,.42),"source cycle remains420ms")
	check(Opening.WakeFlash.sample_at(0).is_equal_approx(Vector2(1,1)),"source0% keyframe")
	check(Opening.WakeFlash.sample_at(.1051).is_equal_approx(Vector2(.62,1.03)),"steps2 reaches half interpolation at105ms")
	check(Opening.WakeFlash.sample_at(.2101).is_equal_approx(Vector2(.24,1.06)),"source50% keyframe")
	check(Opening.WakeFlash.sample_at(.3151).is_equal_approx(Vector2(.62,1.03)),"return half interpolation at315ms")
	check(Opening.WakeFlash.sample_at(.4201).is_equal_approx(Vector2(1,1)),"source100% loops cleanly")
	state=root.get_node("State"); state.developer_mode=true; state.d=state.initial()
	shell=load("res://scenes/main.tscn").instantiate(); root.add_child(shell); await frames(5)
	state.action_completed.connect(func(id: String,_before: Dictionary,_after: Dictionary,_result: Dictionary): actions.append(id))
	var touch_emulation: bool=Input.emulate_mouse_from_touch
	Input.emulate_mouse_from_touch=true
	for dimensions: Vector2i in [Vector2i(390,844),Vector2i(430,860),Vector2i(1180,812)]:
		await fixture(dimensions); await open_warning(); await verify_motion(dimensions)
		await fixture(dimensions); await open_warning(true)
		check(shell.phone.size==Vector2(430,860),"synthetic touch keeps canonical phone frame")
		var button: Control=named("OpeningAction_c1_enter_home")
		await press(rect(button).get_center(),true,true); await press(Vector2.ZERO,false,true); await frames()
		check(state.d.native.page=="desktop","touch released away from action cancels continuation")
		await key(KEY_F10)
		check(is_instance_valid(shell.modal),"settings modal opens over warning")
		await click(named("OpeningAction_c1_enter_home"))
		check(state.d.native.page=="desktop","modal blocks hidden continuation target")
		await key(KEY_ESCAPE); await click(named("OpeningAction_c1_enter_home"),true)
		check(state.d.native.page=="phone_home" and named("WakeFlash")==null,"touch continuation works after dismissing modal")
	await fixture(Vector2i(430,860),true); await open_warning()
	var flash: Control=named("WakeFlash"); flash.set_process(false)
	var snapshot: String=JSON.stringify(state.d)
	for seconds: float in [0,.105,.21,.42,4.2]:
		flash._process(seconds)
		check(flash.modulate.a==1 and flash.scale==Vector2.ONE and flash.elapsed==0,"reduced motion stays legible and static")
	check(JSON.stringify(state.d)==snapshot,"reduced-motion display also has no state writes")
	await capture("wake-430x860-reduced-motion")
	state.developer_mode=false
	check(state.save_game(),"warning checkpoint saves through existing writer")
	state.d=state.initial(); check(state.load_game(),"ordinary save reload works")
	shell._refresh(); await frames()
	check(state.d.native.wake_warned and named("WakeFlash")!=null and named("WakeFlash").reduced_motion,"reload preserves choice and reduced-motion preference")
	await click(named("OpeningAction_c1_enter_home"),true)
	check(state.save_game(),"continued phone state saves")
	state.d=state.initial(); check(state.load_game(),"continued phone state reloads")
	shell._refresh(); await frames()
	check(state.d.native.page=="phone_home" and named("WakeFlash")==null,"reload after continuation never restores old warning art")
	Input.emulate_mouse_from_touch=touch_emulation
	state.developer_mode=true
	await shell.shutdown(); shell.queue_free(); await frames()
	var report: String=OS.get_environment("WAKE_FLASH_REPORT")
	if not report.is_empty(): FileAccess.open(report,FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"motion_samples":motion_samples,"actual_cua":false,"physical_phone":false,"input":"native Main emulated mouse and ScreenTouch with engine mouse emulation","graphical":DisplayServer.get_name()!="headless"},"  "))
	print("WAKE_FLASH_SOURCE: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
