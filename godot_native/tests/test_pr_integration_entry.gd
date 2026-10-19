extends SceneTree
## Actual entry button + saved source checkpoint + production rescue -> phone.
## Checkpoint placement is test setup, not a manual/full-campaign playthrough.
var state: Node
var checks: int=0
var failures: int=0
func _initialize() -> void: run.call_deferred()
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error("PR ENTRY: "+label)
func frames(count: int=3) -> void:
	for i in range(count): await process_frame
func click(button: Control,touch: bool=false) -> void:
	var point: Vector2=button.get_global_transform_with_canvas()*(button.size/2)
	for down in [true,false]:
		if touch:
			var event:=InputEventScreenTouch.new(); event.position=point; event.index=9; event.pressed=down; Input.parse_input_event(event); Input.flush_buffered_events()
		else:
			var event:=InputEventMouseButton.new(); event.position=point; event.button_index=MOUSE_BUTTON_LEFT; event.pressed=down; root.push_input(event)
	await frames(8)
func interact(shell: Control,action: String) -> void:
	# Explicit source-coordinate fixture; exercise the real world interaction
	# proximity and Space routing instead of submitting a rescue result.
	var found: Dictionary={}
	for target: Dictionary in state.get_targets("qizhen_lake"):
		if str(target.get("action",""))==action: found=target; break
	check(not found.is_empty(),"real world exposes target "+action)
	if found.is_empty(): return
	shell.world.player=Vector2(found.position[0],found.position[1]); shell.world._sync_player(); shell.world.nearby=found
	shell.world.grab_focus()
	for down in [true,false]:
		var event:=InputEventKey.new(); event.keycode=KEY_SPACE; event.physical_keycode=KEY_SPACE; event.pressed=down; shell.world_viewport.push_input(event,true)
	await frames(4)
func run() -> void:
	check(load("res://tests/native_test_isolation.gd").is_isolated_save(),"entry persistence uses isolated temporary user data")
	if failures: quit(1); return
	state=root.get_node("State")
	check(state.begin_checkpoint("c3-qizhen-rain-hold"),"load authored source checkpoint as explicit test fixture")
	state.developer_mode=false; state.formal_snapshot={}
	state.d.native.settings.reduced_motion=false
	check(state.save_game(),"write valid checkpoint through production save store")
	state.d=state.initial()
	check(state.load_game(),"actual save reload restores checkpoint before entry")
	var capsize_before: int=state.d.qizhenLake.capsizeCount
	root.set_meta("entry_arguments_consumed",true)
	root.size=Vector2i(1280,720)
	change_scene_to_file("res://scenes/entry.tscn"); await frames(8)
	check(current_scene.scene_file_path=="res://scenes/entry.tscn","real project entry is active")
	await click(current_scene.story_button)
	var shell: Control=current_scene
	check(shell.scene_file_path=="res://scenes/main.tscn" and state.d.native.scene=="qizhen_lake","real Continue button resumes saved lake chapter")
	check(shell.world_frame.is_visible_in_tree(),"desktop entry restores actual RPG surface")
	await interact(shell,"c3_lake_target:qizhen_dock_safety_officer")
	check(state.d.qizhenLake.rainWarningSeen,"native safety-officer interaction records rain warning")
	await interact(shell,"c3_lake_target:qizhen_dock_board")
	check(is_instance_valid(shell.world_effect),"real board interaction mounts production rescue adapter")
	if not is_instance_valid(shell.world_effect): await shell.shutdown(); quit(1); return
	var session: RefCounted=state.lake_module().rain_session
	var effect: Control=shell.world_effect
	if DisplayServer.get_name()=="headless":
		await create_timer(.15).timeout
		if not shell.get_window().has_focus():
			var before: int=int(session.snapshot().elapsedMs)
			await create_timer(.1).timeout
			check(int(session.snapshot().elapsedMs)==before,"real unfocused host freezes its monotonic session")
		check(not state.d.qizhenLake.rainRescueCompleted,"headless entry cannot create early rescue completion")
		shell._cancel_world_effect(); await frames()
		check(not state.d.qizhenLake.rainRescueCompleted and session.phase()=="cancelled","cancel leaves checkpoint incomplete and retryable")
	else:
		var deadline: int=Time.get_ticks_msec()+9000
		while session.phase()!="cinematic" and Time.get_ticks_msec()<deadline: await create_timer(.025).timeout
		check(session.phase()=="cinematic" and is_instance_valid(effect.native_renderer),"real focused entry reaches native rescue renderer")
		await frames(3)
		if is_instance_valid(effect.skip):
			# Traverse the actual root -> SubViewportContainer -> world viewport
			# route. A direct SubViewport injection skips container mouse-enter
			# ownership and is not an equivalent mouse test in a live window.
			var source: Vector2=effect.skip.get_global_transform_with_canvas()*(effect.skip.size/2)
			var container_point: Vector2=source*shell.world_view.size/Vector2(shell.world_viewport.size)
			var point: Vector2=shell.world_view.get_global_transform_with_canvas()*container_point
			var pointer_events: Array[String]=[]
			var pressed_events: Array[bool]=[]
			effect.skip.gui_input.connect(func(input: InputEvent):
				if input is InputEventMouseButton and input.button_index==MOUSE_BUTTON_LEFT: pointer_events.append("down" if input.pressed else "up"))
			effect.skip.pressed.connect(func(): pressed_events.append(true))
			var move:=InputEventMouseMotion.new(); move.position=point; move.global_position=point; root.push_input(move,true)
			await frames(2)
			check(shell.world_viewport.gui_get_hovered_control()==effect.skip,"root pointer hover reaches actual nested skip button")
			for down in [true,false]:
				var event:=InputEventMouseButton.new(); event.position=point; event.global_position=point; event.button_index=MOUSE_BUTTON_LEFT; event.pressed=down; root.push_input(event,true)
				await frames(2)
			print("PR_ENTRY_SKIP_ROUTE: root=",point," source=",source," received=",pointer_events," pressed=",pressed_events.size()," phase=",session.phase())
			check(pointer_events==["down","up"] and pressed_events.size()==1,"actual root press/release arrives once at native skip")
			check(session.phase()=="rescued","real pointer activates native skip button")
		deadline=Time.get_ticks_msec()+3000
		while not state.d.qizhenLake.rainRescueCompleted and Time.get_ticks_msec()<deadline: await create_timer(.025).timeout
		check(state.d.qizhenLake.rainRescueCompleted and state.d.qizhenLake.capsizeCount==capsize_before+1,"actual skip still waits for dock hold and consumes one controller session")
		check(state.d.native.scene=="dorm_hub" and state.d.currentScene=="phone_home","rescue returns to authored dorm/phone handoff")
		check(not state.d.qizhenLake.rainSafetyCleared,"rescue does not bypass hair-dryer/weather gate")
	var expected_phase: String=state.d.qizhenLake.phase
	var expected_capsizes: int=state.d.qizhenLake.capsizeCount
	check(state.save_game(),"post-effect story state is persisted")
	var before_reentry: Dictionary=state.d.qizhenLake.duplicate(true)
	await shell.shutdown()
	change_scene_to_file("res://scenes/entry.tscn"); await frames(6)
	state.d=state.initial(); check(state.load_game(),"reload persisted result before re-entering")
	root.size=Vector2i(390,844); await frames(6)
	await click(current_scene.story_button,true)
	shell=current_scene
	check(shell.scene_file_path=="res://scenes/main.tscn","native-touch Continue re-enters production shell")
	if shell.scene_file_path!="res://scenes/main.tscn": quit(1); return
	check(state.d.qizhenLake.phase==expected_phase and state.d.qizhenLake.capsizeCount==expected_capsizes,"re-entry preserves phase/capsize exactly without a second result")
	# JSON reloads numeric fields as floats. Compare all serialized values,
	# including every key, without mistaking int 0 -> float 0 for lost progress.
	for key in before_reentry:
		if typeof(state.d.qizhenLake.get(key))!=typeof(before_reentry[key]): print("PR_ENTRY_JSON_TYPE: ",key," before=",var_to_str(before_reentry[key])," after=",var_to_str(state.d.qizhenLake.get(key)))
	check(JSON.parse_string(JSON.stringify(state.d.qizhenLake))==JSON.parse_string(JSON.stringify(before_reentry)),"all saved lake facts survive actual entry JSON round trip")
	check(not is_instance_valid(shell.world_effect),"no transient presentation lease is reserialized or replayed after reload")
	check(not shell.world.presentation_actor_hidden,"re-entry has no leaked hidden player")
	await shell.shutdown(); shell.queue_free(); await frames()
	print("PR_ENTRY_FLOW: %d checks, %d failures; graphical=%s; explicit source checkpoint"%[checks,failures,str(DisplayServer.get_name()!="headless")])
	quit(1 if failures else 0)
