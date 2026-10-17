extends SceneTree
## Manual CUA route. F6 selects the next source checkpoint/layout only.
## The source collectible must be clicked normally; no reward action is injected.
var shell: Control
var state: Node
var output: String
var case_index: int=-1
var cases: Array=[]
var records: Array=[]
var capture_busy:=false
var accepted_at: int=-1
var capture_until: int=-1
var frame_index:=0
var preparing:=false
var case_key: String=""
var last_capture:=0
class Driver extends Node:
	var host: SceneTree
	func _input(event: InputEvent) -> void:
		if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_F6:
			host.next_case.call_deferred(); get_viewport().set_input_as_handled()
func _initialize() -> void: run.call_deferred()
func frames(count: int=3) -> void:
	for i in count: await process_frame
func run() -> void:
	if not OS.get_user_data_dir().begins_with("/tmp/"):
		push_error("Refusing manual source-fixture capture outside isolated /tmp profile");quit(2);return
	if DisplayServer.get_name()=="headless": print("Manual graphical capture needs cloud desktop");quit(0);return
	output=OS.get_environment("PHONE_ANCHORS_CAPTURE_DIR")
	if output.is_empty(): output="user://phone-anchors-manual"
	DirAccess.make_dir_recursive_absolute(output)
	state=root.get_node("State");state.developer_mode=true;state.d=state.initial()
	shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames(5)
	var driver:=Driver.new();driver.host=self;root.add_child(driver)
	var anchors: Array=["01","02"] if OS.get_environment("PHONE_ANCHORS_DIGITS_ONLY")=="1" else ["01","02","03"]
	for dimensions: Vector2i in [Vector2i(1180,812),Vector2i(430,860),Vector2i(390,844)]:
		for anchor: String in anchors:cases.append({"anchor":anchor,"size":dimensions})
	state.action_completed.connect(on_action)
	await next_case()
func next_case() -> void:
	if preparing or capture_busy:return
	preparing=true
	if case_index>=0 and accepted_at>=0: await capture("after-settled")
	capture_until=-1;accepted_at=-1;case_index+=1
	if case_index>=cases.size():
		write_records();print("PHONE_ANCHORS_MANUAL_DONE ",JSON.stringify({"cases":case_index,"records":records.size(),"fixture":"original source checkpoint; actual root controls; no result injection"}))
		await shell.shutdown();quit();return
	var entry: Dictionary=cases[case_index];var dimensions: Vector2i=entry.size
	case_key="anchor%s-%dx%d"%[entry.anchor,dimensions.x,dimensions.y];frame_index=0
	root.title="7:55 phone "+case_key+" | F6 next fixture"
	shell.audio_director.reset();shell._close_modal();state.begin_checkpoint("c1-code-hunt")
	state.d.native.settings.reduced_motion=false
	state.d.native.settings.music=false;state.d.native.settings.effects=true
	shell.phone_chrome.set_inventory_top(240)
	if entry.anchor=="02":state.act("c1_network","cellular")
	state.open_page({"01":"checkin","02":"tiyi","03":"phone_home"}[entry.anchor])
	DisplayServer.window_set_size(dimensions);root.size=dimensions;shell.size=Vector2(dimensions)
	DisplayServer.window_set_position(Vector2i(24,45));shell._refresh();shell._layout();await frames(6)
	if entry.anchor=="02":await create_timer(1.6).timeout
	# The profile is /tmp-isolated; normal subsequent actions use the ordinary
	# save writer so the accepted result exists on disk immediately.
	state.developer_mode=false
	preparing=false
	await capture("before")
	print("PHONE_ANCHOR_READY ",case_key," original source checkpoint; click the visible object; then F6")
func on_action(action: String,_before: Dictionary,after: Dictionary,_result: Dictionary) -> void:
	if preparing or action not in ["c1_absence","c1_tiyi_digit","c1_rain_drop"]:return
	accepted_at=Time.get_ticks_msec();capture_until=accepted_at+900
	var accepted: Dictionary={"case":case_key,"kind":"actual_action","action":action,"at_ms":accepted_at,"flag0":after.flags.cardZeroTaken,"flag7":after.flags.tiyiCountTaken,"water":after.items.waterDrop,"digit0":after.digits.d1,"digit7":after.digits.d2}
	records.append(accepted);print("PHONE_ANCHOR_ACTUAL_ACTION ",JSON.stringify(accepted));write_records()
func _process(_delta: float) -> bool:
	if not preparing and not capture_busy and capture_until>Time.get_ticks_msec() and Time.get_ticks_msec()-last_capture>=40:
		capture.call_deferred("actual-frame")
	return false
func capture(label: String) -> void:
	if capture_busy:return
	capture_busy=true
	await RenderingServer.frame_post_draw
	var now:=Time.get_ticks_msec();var path:=case_key+"-"+label+"-%04d-%dms.png"%[frame_index,now]
	var image: Image=root.get_texture().get_image();image.save_png(output.path_join(path))
	var pickup: Control=shell.phone_object_pickup
	var observation: Dictionary={"case":case_key,"kind":"frame","file":path,"wall_ms":now,"after_action_ms":now-accepted_at if accepted_at>=0 else -1,"actual_cua":true,"physical_phone":false,"pose_observation":"host state read after frame_post_draw; not an exact rendered-phase certification","active":not pickup.current.is_empty(),"host_elapsed_ms":pickup.elapsed_ms}
	if not pickup.current.is_empty():
		var pose: Dictionary=pickup.sample_at(pickup.elapsed_ms)
		observation.sample={"center":[pose.center.x,pose.center.y],"scale":[pose.scale.x,pose.scale.y],"rotation":pose.get("rotation",0),"alpha":pose.get("alpha",1)}
	records.append(observation);frame_index+=1;last_capture=now;write_records();capture_busy=false
func write_records() -> void:
	FileAccess.open(output.path_join("actual-input-and-frames.json"),FileAccess.WRITE).store_string(JSON.stringify({"fixture":"original c1-code-hunt source checkpoint; normal controller action and autosave; input performed through CUA","records":records,"physical_phone":false,"audio":"Dummy driver; no hearing claim"},"  "))
