extends SceneTree
## Actual Main pointer/key routing, with isolated source-eligible fixtures.
var state: Node
var shell: Control
var checks=0
var failures=0
var outcomes: Array=[]
var events: Array=[]
var case_name=""

func _initialize() -> void: run.call_deferred()
func frames(count: int=4) -> void:
	for i in range(count): await process_frame
func check(ok: bool,message: String) -> void:
	checks+=1
	outcomes.append({"case":case_name,"check":message,"passed":ok})
	if not ok: failures+=1; push_error("LIBRARY RETURN: "+case_name+" / "+message)
func find(id: String) -> Node: return shell.page_body.find_child(id,true,false)
func click(target: Control) -> void:
	check(target!=null,"pointer target exists")
	if target==null: return
	var point=target.get_global_transform_with_canvas()*(target.size/2)
	check(Rect2(Vector2.ZERO,Vector2(root.size)).has_point(point),"pointer target is onscreen")
	var motion=InputEventMouseMotion.new(); motion.position=point; root.push_input(motion,true)
	for down in [true,false]:
		var event=InputEventMouseButton.new(); event.position=point; event.button_index=MOUSE_BUTTON_LEFT; event.pressed=down; root.push_input(event,true)
		await frames(1)
	await frames()
func key(code: Key) -> void:
	for down in [true,false]:
		var event=InputEventKey.new(); event.keycode=code; event.physical_keycode=code; event.pressed=down; root.push_input(event,true)
		await frames(1)
	await frames()
func fixture(scene: String="library_interior",phase: String="library_entered") -> void:
	state.story_reset.emit()
	state.d=state.initial(); state.developer_mode=true
	state.d.native.chapter=2; state.d.native.scene=scene; state.d.native.page="library_app"
	state.d.runtimeMode="rpg"; state.d.rpgScene=scene; state.d.rpgCheckpoint="library_entrance"
	state.d.actOne.phase="complete"; state.d.networkMode="campus_wifi"
	state.d.ui.libraryFinalsPhase=phase; state.d.ui.libraryFinalsPuzzle.libraryVisitedPoints=["entrance"]
	state.d.native.positions={"library_interior:":{"x":715.0,"y":790.0}}
	shell.phone_builder.native_library.reset()
	shell.mobile_world=false; shell.world_page_origin_scene="library_interior"
	shell._refresh(); await frames()
	state.advance_phone_entry(1500); shell._refresh(); await frames()
	shell.world.set_process(false)
	check(find("LibraryApp_return")!=null,"source Library return tile is available")
func app_again() -> void:
	state.open_page("library_app"); shell.mobile_world=false; shell._refresh(); await frames()
	if state.get_phone_entry_session().phase=="loading": state.advance_phone_entry(1500); shell._refresh(); await frames()
func assert_layout(compact: bool) -> void:
	check(shell.world_frame.is_visible_in_tree(),"successful explicit return displays retained world")
	check(not shell.phone.is_visible_in_tree() if compact else shell.phone.is_visible_in_tree(),"compact switches surface; desktop preserves split phone")
	check(shell.mobile_back.is_visible_in_tree()==compact,"compact world exposes the ordinary phone return")
	check(shell.world.scene_id=="library_interior","returned surface is the controller-approved Library scene")
	check(shell.world.has_focus(),"world receives keyboard focus after explicit return")
func run() -> void:
	state=root.get_node("State"); state.developer_mode=true; state.d=state.initial()
	shell=load("res://scenes/main.tscn").instantiate(); root.add_child(shell); await frames(); shell.set_process(false)
	state.action_completed.connect(func(id,_before,_after,result): events.append({"id":id,"result":result.duplicate(true)}))
	for viewport in [Vector2i(390,844),Vector2i(430,860),Vector2i(1440,900)]:
		case_name=str(viewport)
		root.size=viewport; shell.size=Vector2(viewport); await frames()
		var compact=viewport.x<1100
		await fixture()
		var retained: Vector2=shell.world.player
		var positions=state.d.native.positions.duplicate(true)
		var puzzle=state.d.ui.libraryFinalsPuzzle.duplicate(true)
		var items=state.d.items.duplicate(true)
		var scene=state.d.native.scene
		check(retained==Vector2(715,790) and shell.world.can_stand(retained),"fixture resumes valid saved location near the entrance record")
		var phone_rect=shell.phone.get_global_rect(); var world_rect=shell.world_frame.get_global_rect()
		for repeat in range(3):
			await click(find("LibraryApp_return"))
			check(events[-1].id=="lib_enter" and events[-1].result.get("scene")=="library_interior","real tile receives a successful controller result")
			assert_layout(compact)
			check(state.d.native.scene==scene and shell.world.player==retained and state.d.native.positions==positions,"return preserves retained scene, live actor and stored position")
			check(state.d.ui.libraryFinalsPuzzle==puzzle and state.d.items==items and state.d.ui.libraryFinalsPhase=="library_entered","return never advances existing story or inventory")
			if not compact: check(shell.phone.get_global_rect()==phone_rect and shell.world_frame.get_global_rect()==world_rect,"desktop split bounds stay unchanged")
			if repeat<2: await app_again()
		# The next source interaction works without finding another footer or refocusing.
		shell.world._process(0)
		await key(KEY_SPACE)
		check(state.d.native.page=="library_record","next Space opens the nearby record through normal world input")
		check(shell.phone.visible and (not shell.world_frame.visible if compact else shell.world_frame.visible),"real record intent still opens its phone surface")
		check(not state.d.ui.libraryFinalsPuzzle.entranceRecordRead,"opening the record does not acknowledge it")
		# The button remains visible in this source-ineligible fixture; controller owns refusal.
		await fixture(); state.d.actOne.phase="movement_required"
		await click(find("LibraryApp_return"))
		check(events[-1].id=="lib_enter" and not events[-1].result.has("scene"),"rejected lib_enter has no successful scene result")
		check(not shell.mobile_world and shell.phone.visible and (not shell.world_frame.visible if compact else shell.world_frame.visible),"rejected return never switches the visible surface")
		check(state.d.actOne.phase=="movement_required" and not state.d.ui.libraryFinalsPuzzle.entranceRecordRead,"rejection preserves source progression gates")
		# First entry still queues the authored dialogue; presentation does not consume it.
		await fixture("campus_bootstrap","library_route_unlocked")
		await click(find("LibraryApp_return"))
		check(shell.world_frame.visible and (not shell.phone.visible if compact else shell.phone.visible),"first accepted Library entry also displays the world")
		var session=state.get_library_story_session()
		check(state.d.ui.libraryFinalsPhase=="library_entered" and session!=null and session.sequence_id=="library_entered","first entry keeps its controller-owned source dialogue")
		check(not state.d.ui.libraryFinalsPuzzle.entranceRecordRead and not state.d.ui.libraryFinalsPuzzle.backpackInspected,"return never completes the dialogue or next evidence gates")
		check(not shell.world.has_focus(),"active source dialogue retains keyboard focus")
		# Unrelated/rejected result shapes cannot masquerade as the explicit presentation intent.
		shell.mobile_world=false; shell._layout()
		for result in [{"handled":true},{"handled":true,"scene":"campus_bootstrap"}]:
			shell._on_controller_page_intent("lib_enter",state.d,state.d,result)
			check(not shell.mobile_world,"missing or wrong successful scene cannot reveal the world")
		shell._on_controller_page_intent("phone_refresh",state.d,state.d,{"handled":true,"scene":"library_interior"})
		check(not shell.mobile_world,"unrelated action with a scene result remains unchanged")
	await shell.shutdown(); shell.queue_free(); await frames()
	var report_path=OS.get_environment("UI_QA_REPORT")
	if not report_path.is_empty():
		var report=FileAccess.open(report_path,FileAccess.WRITE); report.store_string(JSON.stringify({"checks":checks,"failures":failures,"graphical_acceptance":false,"cases":outcomes},"\t")); report.close()
	print("LIBRARY_RETURN_TO_SCENE: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
