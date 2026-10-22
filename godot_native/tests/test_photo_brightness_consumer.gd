extends SceneTree
## Real Main/Control Center input in isolated fixtures. Automated, not manual acceptance.
const Session=preload("res://scripts/ui/photo_brightness_session.gd")
var shell: Control
var state: Node
var checks:=0
var failures:=0
var actions: Array=[]
func _initialize() -> void: run.call_deferred()
func frames(count:=4) -> void:
	for i in range(count): await process_frame
func check(ok: bool, why: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error("PHOTO CONSUMER: "+why)
func named(id: String) -> Control: return shell.find_child(id,true,false)
func by_text(node: Node,value: String) -> Button:
	if node is Button and node.text==value: return node
	for child in node.get_children():
		var found:=by_text(child,value)
		if found:return found
	return null
func thumbnail(node: Node,caption: String) -> Button:
	if node is Button:
		for child in node.get_children():
			if child is Label and child.text==caption:return node
	for child in node.get_children():
		var found:=thumbnail(child,caption)
		if found:return found
	return null
func click(control: Control) -> void:
	check(control!=null,"Visible pointer target exists")
	if not control:return
	shell.phone_scroll.ensure_control_visible(control);await frames()
	var point=control.get_global_rect().get_center()
	var motion=InputEventMouseMotion.new();motion.position=point;root.push_input(motion,true)
	for pressed in [true,false]:
		var event=InputEventMouseButton.new();event.position=point;event.global_position=point;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed;root.push_input(event,true);await process_frame
	await frames()
func fixture(captured: bool,brightness: float,page: String="photos") -> void:
	state.d=state.initial();state.developer_mode=true;state.d.actOne.phase="complete"
	state.d.native.chapter=2;state.d.native.page=page;state.d.native.scene="library_interior"
	state.d.ui.libraryFinalsPhase="evidence_gathering"
	state.d.ui.libraryFinalsPuzzle.backpackInspected=true
	state.d.ui.libraryFinalsPuzzle.investigationOpened=true
	state.d.ui.libraryFinalsPuzzle.photoCaptured=captured
	state.d.ui.brightness=brightness
	shell.mobile_world=false;shell._reset_runtime_presentations();shell._refresh();await frames();actions.clear()
func brightness(value: float) -> void:
	if not state.d.ui.controlCenterOpen:shell._on_phone_page("control_center");await frames()
	var slider:Control=named("ControlBrightness")
	check(slider!=null,"Actual Main Control Center slider exists")
	if not slider:return
	var point=slider.get_global_transform_with_canvas()*Vector2(slider.size.x*.5,104*(1-value/100))
	var motion=InputEventMouseMotion.new();motion.position=point;root.push_input(motion,true)
	for pressed in [true,false]:
		var e=InputEventMouseButton.new();e.position=point;e.global_position=point;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=pressed;root.push_input(e,true);await process_frame
	await frames(7)
	check(is_equal_approx(float(state.d.ui.brightness),value),"Real brightness input reaches %s"%value)
func close_control() -> void:
	shell._on_phone_action("native_control_center_close",null);await frames()
func clue_visible() -> bool:return named("PhotoClueLine6")!=null
func run() -> void:
	# Compare the native lifecycle consumer with executed active React hook traces.
	var trace_path=OS.get_environment("PHOTO_CONSUMER_FIXTURE")
	if trace_path.is_empty():trace_path="res://tests/photo_consumer_cases.json"
	check(FileAccess.file_exists(trace_path),"Executable source oracle fixture exists")
	if FileAccess.file_exists(trace_path):
		var cases=JSON.parse_string(FileAccess.get_file_as_string(trace_path))
		for trace in cases:
			var consumer=Session.new()
			for step in trace.steps:
				if step.get("reset",false):consumer.reset()
				var ui={"brightness":step.brightness,"libraryFinalsPuzzle":{"photoCaptured":step.captured,"photoDimmed":step.dimmed}}
				check(consumer.observe(step.page,ui)==step.expected,"React lifecycle trace %s: %s"%[trace.name,step.label])
	state=root.get_node("State");state.developer_mode=true;state.d=state.initial()
	shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames()
	state.action_completed.connect(func(id,_before,_after,_result):actions.append(id))
	for dimensions in [Vector2i(390,844),Vector2i(430,860),Vector2i(1440,900)]:
		root.size=dimensions;shell.size=Vector2(dimensions)
		await fixture(false,75)
		await brightness(20)
		check(not state.d.ui.libraryFinalsPuzzle.photoDimmed and not clue_visible(),"Pre-capture dimming cannot reveal")
		await close_control()
		shell._on_phone_action("lib_photo",null);await frames()
		check(state.d.ui.libraryFinalsPuzzle.photoCaptured,"Main dispatches the authoritative capture action")
		check(not state.d.ui.libraryFinalsPuzzle.photoDimmed and not clue_visible(),"Capture at20 is not a brightness change")
		await brightness(20)
		check(not state.d.ui.libraryFinalsPuzzle.photoDimmed,"Same value does not reveal")
		await brightness(30);await brightness(20)
		check(not state.d.ui.libraryFinalsPuzzle.photoDimmed,"Return to capture baseline20 does not reveal")
		await brightness(19)
		check(state.d.ui.libraryFinalsPuzzle.photoDimmed and clue_visible(),"Qualifying post-capture change reveals behind Control Center")
		check(actions.count("lib_dim_photo")==1,"Only one authoritative reveal action")
		check(not state.d.items.itemRecognitionReport and not state.d.ui.libraryFinalsPuzzle.itemReportGenerated,"Reveal does not grant report")
		await brightness(75)
		check(state.d.ui.libraryFinalsPuzzle.photoDimmed and not clue_visible(),"Raised brightness hides text but preserves source flag")
		await brightness(20)
		check(clue_visible() and actions.count("lib_dim_photo")==1,"Lowering again restores text without duplicate reveal")
		await close_control();state.open_page("phone_home");await frames();state.open_page("photos");await frames()
		check(clue_visible() and actions.count("lib_dim_photo")==1,"Completed reveal persists on reentry without replay")
		# Wrong old-photo selection and cancel do not grant the report.
		await click(thumbnail(shell.page_body,"0033"))
		check(state.d.native.get("lib_selected_photo","")=="takeout_soy","Real wrong thumbnail opens selected photo")
		check(not state.d.items.itemRecognitionReport,"Wrong photo never grants a report")
		state.act("lib_item_report");await frames()
		check(not state.d.items.itemRecognitionReport,"Wrong selection fails authoritative report gate")
		await click(by_text(shell.page_body,"返回相册"))
		check(state.d.native.get("lib_selected_photo","").is_empty(),"Real cancel returns to album")
		check(not state.d.ui.libraryFinalsPuzzle.itemReportGenerated,"Cancel preserves ungenerated report")
		await click(by_text(shell.page_body,"查看 022 旧照"))
		await click(by_text(shell.page_body,"用旧照补全物品报告"))
		check(state.d.items.itemRecognitionReport and state.d.ui.libraryFinalsPuzzle.itemReportGenerated,"Correct existing report control grants once")
		var before=state.d.items.duplicate(true);state.act("lib_item_report");await frames()
		check(state.d.items==before,"Repeat report cannot duplicate inventory")
		await fixture(true,75)
		await brightness(21);check(not state.d.ui.libraryFinalsPuzzle.photoDimmed and not clue_visible(),"21 stays locked")
		await brightness(20);check(state.d.ui.libraryFinalsPuzzle.photoDimmed and clue_visible(),"Exact20 reveals automatically")
		await fixture(true,20)
		check(not state.d.ui.libraryFinalsPuzzle.photoDimmed,"Mount at20 is locked")
		await brightness(30);await close_control();state.open_page("phone_home");await frames()
		await brightness(20);await close_control()
		check(not state.d.ui.libraryFinalsPuzzle.photoDimmed,"Brightness outside Photos does not unlock")
		state.open_page("photos");await frames()
		check(not state.d.ui.libraryFinalsPuzzle.photoDimmed,"Reentry at20 creates fresh baseline")
		await brightness(30);await brightness(20)
		check(not state.d.ui.libraryFinalsPuzzle.photoDimmed,"Reentry baseline20 remains excluded")
		await brightness(19);check(state.d.ui.libraryFinalsPuzzle.photoDimmed,"New reentry change19 qualifies")
		await fixture(true,75)
		shell._show_world_mobile();await frames()
		state.act("c1_brightness",20);await frames()
		check(not shell.phone.visible and not state.d.ui.libraryFinalsPuzzle.photoDimmed,"Hidden RPG phone cannot run Photos effect")
		shell._on_phone_action("lib_photo",null);await frames()
		check(shell.phone.visible and not state.d.ui.libraryFinalsPuzzle.photoDimmed,"Native world photo action remounts at current brightness without reveal")
		await brightness(30);await brightness(20)
		check(not state.d.ui.libraryFinalsPuzzle.photoDimmed,"Remounted baseline20 is excluded")
		await brightness(19);check(state.d.ui.libraryFinalsPuzzle.photoDimmed,"Remount permits a new qualifying change")
		await fixture(true,75)
		state.d.ui.libraryFinalsPuzzle.backpackInspected=false;shell._refresh();await frames();await brightness(20)
		check(state.d.ui.libraryFinalsPuzzle.photoDimmed and not clue_visible(),"Source dimPhoto flag semantics preserved; missing inspection never displays text")
		await fixture(true,75)
		state.d.ui.libraryFinalsPhase="completed";await brightness(20)
		check(not state.d.ui.libraryFinalsPuzzle.photoDimmed and not clue_visible(),"Controller rejects incorrect phase")
	await shell.shutdown();shell.queue_free();await frames()
	print("PHOTO_BRIGHTNESS_CONSUMER: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
