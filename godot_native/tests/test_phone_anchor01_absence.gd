extends SceneTree
## Design-book anchor01: one accepted acquisition, never a count of assertions.
## Source checkpoint fixtures plus actual Main mouse and synthetic touch input.
var shell: Control
var state: Node
var host: Control
var checks:=0
var failures:=0
var cues: Array=[]
var actions: Array=[]
var samples: Array=[]
const SOUND="11_p04_campus_card_balance_zero_click"
func _initialize() -> void: run.call_deferred()
func frames(count: int=3) -> void:
	for i in count: await process_frame
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error("ANCHOR01: "+message)
func named(id: String) -> Control: return shell.page_body.find_child(id,true,false)
func rect(node: Control) -> Rect2:
	var transform:=node.get_global_transform_with_canvas()
	return Rect2(transform.origin,node.size*transform.get_scale())
func click(node: Control,touch: bool=false) -> void:
	check(node!=null,"visible source control exists")
	if node==null: return
	var point:=rect(node).get_center()
	for down in [true,false]:
		if touch:
			var event:=InputEventScreenTouch.new(); event.position=point; event.pressed=down; event.index=0; Input.parse_input_event(event)
		else:
			var move:=InputEventMouseMotion.new(); move.position=point; move.global_position=point; Input.parse_input_event(move)
			var event:=InputEventMouseButton.new(); event.position=point; event.global_position=point; event.pressed=down; event.button_index=MOUSE_BUTTON_LEFT; Input.parse_input_event(event)
		Input.flush_buffered_events(); await process_frame
	await frames(2)
func fixture(dimensions: Vector2i,reduced: bool=false) -> void:
	shell._close_modal(); shell._close_phone_document(); shell.audio_director.reset()
	check(state.begin_checkpoint("c1-code-hunt"),"original scattered-code checkpoint loads")
	state.d.native.settings.reduced_motion=reduced
	state.open_page("checkin")
	root.size=dimensions; shell.size=Vector2(dimensions)
	shell._refresh(); shell._layout(); await frames(4)
	host.set_process(false); cues.clear(); actions.clear()
	check(not state.d.flags.cardZeroTaken and named("CheckinAbsenceZero")!=null,"unearned source zero is a live hotspot")
func collect(touch: bool=false) -> void:
	var before: int=host.started_count
	await click(named("CheckinAbsenceZero"),touch)
	check(state.d.flags.cardZeroTaken and state.d.digits.d1=="0","controller accepts zero before presentation ends")
	check(actions.count("c1_absence")==1,"one real gesture requests one original action")
	check(not host.current.is_empty() and host.current.spec.anchor=="01","exact accepted rising edge mounts anchor01")
	check(host.z_index==111 and host.z_index>shell.toast.z_index,"moving digit remains visible above ordinary successful toast")
	check(host.started_count==before+1,"one acquisition starts one presentation")
	check(named("CheckinAbsenceZero")==null and named("CheckinAbsenceImprint")!=null,"source hotspot retires to gray zero and empty imprint")
	check(cues.count(SOUND)==1,"original11_ collection sound is queued once")
func verify_poses(dimensions: Vector2i) -> void:
	if host.current.is_empty(): return
	var source: Rect2=host.current.source
	var target: Rect2=host.current.target
	var target_geometry: Dictionary=shell.phone_chrome.digit_clue_geometry("d1")
	check(target==target_geometry.rect,"landing is the currently visible first clue digit")
	var source_frame: Control=named("CheckinAbsenceImprint")
	var fixed:=rect(source_frame)
	var state_before: String=JSON.stringify(state.d)
	for milliseconds: int in [0,55,110,190,280,320,359]:
		var pose: Dictionary=host.sample_at(milliseconds)
		check(Rect2(Vector2.ZERO,host.size).has_point(pose.center),"sample remains within phone "+str(milliseconds))
		check(rect(source_frame)==fixed,"record frame and empty imprint never move")
		samples.append({"viewport":[dimensions.x,dimensions.y],"ms":milliseconds,"center":[pose.center.x,pose.center.y],"scale":[pose.scale.x,pose.scale.y],"rotation":pose.rotation})
	var first: Dictionary=host.sample_at(0)
	check(first.scale.is_equal_approx(Vector2(1.04,.94)),"K1 squashes only zero")
	check(first.anchor.is_equal_approx(source.position+Vector2(source.size.x/2,source.size.y)),"K1 uses old bottom edge as fixed contact pivot")
	var lift: Dictionary=host.sample_at(110)
	check(lift.scale==Vector2.ONE and is_equal_approx(lift.rotation,deg_to_rad(8)),"K2 preserves exact8-degree lifted glyph")
	check(is_equal_approx(lift.anchor.y-first.anchor.y,-6),"K2 lifts six logical pixels")
	var landing: Dictionary=host.sample_at(280)
	check(landing.center.is_equal_approx(target.get_center()) and landing.rotation==0,"K3 lands in the actual clue slot")
	var ratio: float=host.current.target_font_size/host.current.font_size
	check(landing.scale.is_equal_approx(Vector2(1.08,.90)*ratio),"K3 has authored landing squash at target font size")
	check(JSON.stringify(state.d)==state_before,"all sampled poses are read-only")
	host._process(.359); check(not host.current.is_empty(),"presentation remains before360ms")
	host._process(.0011); check(host.current.is_empty(),"terminal callback only clears at360ms")
	check(state.d.flags.cardZeroTaken and state.d.digits.d1=="0","clearing retains accepted reward")
func run() -> void:
	if not OS.get_user_data_dir().begins_with("/tmp/"):
		push_error("Refusing anchor01 persistence outside isolated /tmp profile"); quit(2); return
	create_timer(70).timeout.connect(func(): push_error("Anchor01 watchdog"); quit(2))
	state=root.get_node("State"); state.developer_mode=true; state.d=state.initial()
	shell=load("res://scenes/main.tscn").instantiate(); root.add_child(shell); await frames(5); shell.set_process(false)
	host=shell.phone_object_pickup
	shell.audio_director.playback_started.connect(func(_channel: String,asset: String): cues.append(asset))
	state.action_completed.connect(func(id: String,_before: Dictionary,_after: Dictionary,_result: Dictionary): actions.append(id))
	var touch_before: bool=Input.emulate_mouse_from_touch; Input.emulate_mouse_from_touch=true
	for dimensions: Vector2i in [Vector2i(390,844),Vector2i(430,860),Vector2i(1180,812)]:
		await fixture(dimensions); await collect(); verify_poses(dimensions)
		var started: int=host.started_count
		state.act("c1_absence"); await frames()
		check(host.started_count==started and host.current.is_empty() and cues.count(SOUND)==1,"repeated original action cannot re-extract or replay sound")
		state.open_page("phone_home"); state.open_page("checkin"); await frames()
		check(named("CheckinAbsenceImprint")!=null and host.current.is_empty(),"return reads terminal state without replay")
		await fixture(dimensions); await collect(true)
		var before_code: String=shell.phone_builder.checkin_page.code
		await click(named("CheckinKey_1"),true)
		check(host.current.is_empty() and shell.phone_builder.checkin_page.code==before_code+"1","next keypad input immediately settles acquisition and still enters digit")
		check(cues.count(SOUND)==1 and state.d.digits.d1=="0","keypad pulse never re-awards the clue or collection sound")
		await fixture(dimensions,true); await collect()
		var a: Dictionary=host.sample_at(0); var b: Dictionary=host.sample_at(280)
		check(a.center==b.center and a.scale==b.scale and a.rotation==0 and a.center==host.current.target.get_center(),"reduced motion removes travel and rotation while showing acquired clue")
		host.reset("fixture-finished")
	for cancellation: String in ["page","rebuild","replacement","modal","control-center","document","reset","queued-page"]:
		await fixture(Vector2i(430,860)); await collect()
		match cancellation:
			"page": state.open_page("phone_home")
			"rebuild": shell._refresh()
			"replacement": state.d=state.d.duplicate(true); shell._refresh()
			"modal": shell._show_settings(); host._process(0)
			"control-center": shell._on_phone_page("control_center"); host._process(0)
			"document": shell._open_phone_document({"item_id":"waterDrop"}); host._process(0)
			"reset": state.story_reset.emit()
			"queued-page": host.reset(); host.capture_action("c1_absence",shell.page_body,state.d); state.open_page("phone_home")
		await frames()
		check(host.current.is_empty() and host.pending.is_empty(),"cancellation clears transient owner: "+cancellation)
		check(state.d.flags.cardZeroTaken and state.d.digits.d1=="0","cancellation preserves accepted fact: "+cancellation)
		if is_instance_valid(shell.modal): shell._close_modal()
		if state.d.ui.controlCenterOpen: shell._on_phone_action("native_control_center_close",null)
		if is_instance_valid(shell.phone_document): shell._close_phone_document()
	await fixture(Vector2i(430,860)); state.d.flags.codeScattered=false; shell._refresh(); await frames()
	check(named("CheckinAbsenceZero")==null,"locked original absence is not a target")
	shell._on_phone_action("c1_absence",null); await frames()
	check(not state.d.flags.cardZeroTaken and host.current.is_empty(),"rejected early input produces no collection")
	await fixture(Vector2i(430,860)); await collect()
	state.developer_mode=false
	check(state.save_game(),"accepted zero saves even before360ms presentation completes")
	var saved: String=FileAccess.get_file_as_string(state.SAVE_PATH)
	check(not saved.contains("PhoneObjectPickup") and not saved.contains("elapsed_ms") and not saved.contains("target_font_size"),"save contains no new transient presentation data")
	state.d=state.initial(); check(state.load_game(),"ordinary save reload succeeds")
	shell._refresh(); await frames()
	check(state.d.flags.cardZeroTaken and state.d.digits.d1=="0" and host.current.is_empty() and named("CheckinAbsenceImprint")!=null,"reload restores exact acquired terminal state without flight")
	check(shell.phone_chrome.digit_hint.text.contains("0"),"zero remains visible instead of falsey unknown placeholder")
	Input.emulate_mouse_from_touch=touch_before; state.developer_mode=true
	await shell.shutdown(); shell.queue_free(); await frames()
	var report: String=OS.get_environment("PHONE_ANCHOR_REPORT")
	if not report.is_empty(): FileAccess.open(report,FileAccess.WRITE).store_string(JSON.stringify({"anchor":"01","checks":checks,"failures":failures,"samples":samples,"fixture":"source c1-code-hunt checkpoint; not fresh campaign","actual_cua":false,"physical_phone":false},"  "))
	print("PHONE_ANCHOR01: ",checks," checks; ",failures," failures; one design anchor")
	quit(1 if failures else 0)
