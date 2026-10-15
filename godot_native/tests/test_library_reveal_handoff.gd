extends SceneTree
## Controller-earned Library fixture plus emulated native viewport input.
## No checkpoint, fabricated shelf fact, direct _drop_data or button callback is
## used for acquisition. The near-shelf position is an explicit spatial fixture;
## this is deterministic integration coverage, not a CUA/physical-device run.
const Chapter=preload("res://scripts/chapters/chapter1_2.gd")
const Layer=preload("res://scripts/ui/library_world_layers.gd")
const CUE="library_archived_rule_reveal_completed"
var state: Node
var shell: Control
var before_shelf: Dictionary
var checks: int=0
var failures: int=0
var case_name: String=""
var outcomes: Array=[]
var samples: Array=[]
var actions: Array=[]
var reader_openings: int=0
var action_start: int=0
var emulation_baseline: bool=false
var manual_phase: String=""

func capture_manual_phase() -> void:
	var directory: String=OS.get_environment("LIBRARY_REVEAL_CAPTURE_DIR")
	if directory.is_empty() or not is_instance_valid(shell): return
	var phase: String="reader" if shell.phone.is_visible_in_tree() and state.d.native.page=="library_rule" else str(shell.world.library_layers.shelf_phase)
	if phase==manual_phase: return
	manual_phase=phase
	print("LIBRARY_REVEAL_MANUAL_PHASE ",JSON.stringify({"phase":phase,"shelf_ms":shell.world.library_layers.shelf_ms,"world_visible":shell.world_frame.is_visible_in_tree(),"phone_visible":shell.phone.is_visible_in_tree(),"call_number":state.d.items.callNumber755,"rule":state.d.items.archivedLeaveRule}))
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(directory)
	root.get_texture().get_image().save_png(directory+"/"+phase+".png")
var manual_mode: bool=false

func _initialize() -> void: run.call_deferred()
func frames(count: int=3) -> void:
	for i in range(count): await process_frame
func check(ok: bool,message: String) -> void:
	checks+=1
	outcomes.append({"case":case_name,"check":message,"passed":ok})
	if not ok: failures+=1; push_error("LIBRARY REVEAL: "+case_name+" / "+message)
func screen_rect(control: Control) -> Rect2:
	var transform: Transform2D=control.get_global_transform_with_canvas()
	return Rect2(transform.origin,control.size*transform.get_scale())
func event(input: InputEvent) -> void:
	Input.parse_input_event(input); Input.flush_buffered_events()
func mouse(point: Vector2,pressed: bool) -> void:
	var input:=InputEventMouseButton.new()
	input.position=point; input.global_position=point; input.button_index=MOUSE_BUTTON_LEFT; input.pressed=pressed
	event(input)
func motion(point: Vector2,relative: Vector2=Vector2.ZERO,mask: int=0) -> void:
	var input:=InputEventMouseMotion.new()
	input.position=point; input.global_position=point; input.relative=relative; input.button_mask=mask
	event(input)
func key(code: Key,pressed: bool) -> void:
	var input:=InputEventKey.new(); input.keycode=code; input.physical_keycode=code; input.pressed=pressed; event(input)
func press(code: Key) -> void:
	key(code,true); await frames(1); key(code,false); await frames()
func click(control: Control) -> void:
	check(control!=null and control.is_visible_in_tree(),"navigation control is visible before emulated pointer input")
	if control==null: return
	var point: Vector2=screen_rect(control).get_center()
	motion(point); mouse(point,true); mouse(point,false); await frames()
func record_action(id: String,previous: Dictionary,current: Dictionary,result: Dictionary) -> void:
	actions.append({"id":id,"acquired":not previous.ui.libraryFinalsPuzzle.archivedRuleCollected and current.ui.libraryFinalsPuzzle.archivedRuleCollected,"snapshot_is_owner":is_same(current,state.d),"result":result.duplicate(true)})
	if manual_mode and id=="lib_shelf":
		print("LIBRARY_REVEAL_MANUAL_ACQUISITION ",JSON.stringify({"page":state.d.native.page,"world_visible":shell.world_frame.is_visible_in_tree(),"phone_visible":shell.phone.is_visible_in_tree(),"collected":state.d.ui.libraryFinalsPuzzle.archivedRuleCollected,"read":state.d.ui.libraryFinalsPuzzle.archivedRuleRead,"pending":not shell.pending_library_reveal.is_empty(),"serial":shell.world.library_layers.reveal_serial}))
func record_phone() -> void:
	if shell.phone.is_visible_in_tree() and str(state.d.native.page)=="library_rule":
		reader_openings+=1
		if manual_mode: manual_reader_log.call_deferred()
func manual_reader_log() -> void:
	print("LIBRARY_REVEAL_MANUAL_READER ",JSON.stringify({"page":state.d.native.page,"world_visible":shell.world_frame.is_visible_in_tree(),"phone_visible":shell.phone.is_visible_in_tree(),"reader_openings":reader_openings,"read":state.d.ui.libraryFinalsPuzzle.archivedRuleRead,"pending":not shell.pending_library_reveal.is_empty(),"shelf_offset":shell.world.library_layers.shelf_offset,"shelf_ms":shell.world.library_layers.shelf_ms}))
func action_count(id: String) -> int:
	return actions.slice(action_start).filter(func(row: Dictionary): return row.id==id).size()
func grant_count() -> int:
	return actions.slice(action_start).filter(func(row: Dictionary): return row.id=="lib_shelf" and row.acquired).size()
func acknowledge(controller: RefCounted,s: Dictionary) -> void:
	var session=controller.library.story_session(s)
	while session!=null:
		session.attach(s,self)
		for line in session.lines: session.advance(s,self)
		controller.dispatch(s,"lib_story_complete",session)
		session=controller.library.story_session(s)
func earned_shelf() -> Dictionary:
	# Same source-controller route as test_library_rule_action.gd. Only the
	# completed Chapter1/eligible Chapter2 boundary is supplied as a fixture.
	var s: Dictionary=state.initial()
	s.native.chapter=2; s.native.page="library_app"; s.native.scene="campus_bootstrap"
	s.actOne.phase="complete"; s.actOne.cc98Login.authenticated=true; s.networkMode="campus_wifi"
	s.ui.libraryFinalsPhase="library_route_unlocked"
	var controller=Chapter.new()
	controller.dispatch(s,"lib_enter"); acknowledge(controller,s)
	controller.dispatch(s,"lib_record"); controller.dispatch(s,"lib_backpack"); acknowledge(controller,s)
	controller.dispatch(s,"lib_note"); controller.dispatch(s,"lib_investigate","occupancyNote"); acknowledge(controller,s)
	controller.dispatch(s,"lib_catalog_terminal"); controller.dispatch(s,"lib_catalog_search","三分钟离座法")
	controller.dispatch(s,"lib_catalog_select","three-minute-leave-method"); acknowledge(controller,s)
	check(s.items.callNumber755 and s.ui.libraryFinalsPuzzle.callNumberCollected,"ordinary source actions earn the call number")
	check(not s.ui.libraryFinalsPuzzle.archivedRuleCollected and not s.ui.libraryFinalsPuzzle.archivedRuleRead,"earned fixture has neither acquired nor read the rule")
	check(controller.library.story_session(s)==null,"all prerequisite authored dialogue is acknowledged through its controller")
	return s
func refresh() -> void:
	shell._refresh(); await frames()
	if state.get_phone_entry_session().phase=="loading":
		state.advance_phone_entry(1500); shell._refresh(); await frames()
	shell.world.set_process(false)
func fixture(dimensions: Vector2i,reduced: bool=false) -> void:
	key(KEY_D,false)
	state.story_reset.emit(); state.developer_mode=true; state.d=before_shelf.duplicate(true)
	state.d.native.settings.reduced_motion=reduced
	root.size=dimensions; shell.size=Vector2(dimensions)
	shell.phone_builder.native_library.reset(); shell.inventory_gestures.reset()
	shell.mobile_world=true; shell.compact_inventory_open=false; shell.world_page_origin_scene=""
	await refresh()
	# Spatial setup only: progress and item ownership above are controller-earned.
	shell.world.player=Vector2(563,275); shell.world.move_target=Vector2.INF
	shell.world.touch_axis=Vector2.ZERO; shell.world.pan_offset=Vector2.ZERO
	shell.world._sync_player(); shell.world._update_camera(); shell.world.queue_redraw(); await frames()
	check(shell.world.can_stand(shell.world.player),"near-shelf spatial fixture is collision-safe")
	check(shell.world_frame.is_visible_in_tree() and not shell.phone.is_visible_in_tree(),"earned fixture begins on the live Library world")
	check(shell.world.library_layers.shelf_offset==0 and not shell.world.library_layers.blocks_movement(),"unacquired shelf starts idle at its source position")
	check(shell.pending_library_reveal.is_empty(),"new earned fixture has no inherited reveal owner")
	await click(shell.inventory_handle)
	check(shell.inventory_dock.is_visible_in_tree(),"visible inventory handle opens the world item source")
	check(not screen_rect(shell.inventory_dock).intersects(screen_rect(shell.world_frame)),"inventory and shelf world remain separate at the requested viewport")
	reader_openings=0; action_start=actions.size()
func world_screen(point: Vector2) -> Vector2:
	var local: Vector2=(point-shell.world.camera)*shell.world.zoom+shell.world.size/2
	return shell.world_view.get_global_transform_with_canvas()*(local*shell.world_view.size/Vector2(shell.world_viewport.size))
func shelf_screen() -> Vector2:
	# Pick the actual rendered source cabinet polygon, not the legacy target
	# radius or a target chosen because it accepts this particular item.
	for y in range(145,215,5):
		for x in range(525,605,5):
			var source_point:=Vector2(x,y)
			var point: Vector2=world_screen(source_point)
			if screen_rect(shell.world_view).has_point(point) and shell.world.object_picker.pick(source_point,shell.world.targets,true).get("id","")=="library_shelf_755": return point
	return Vector2.INF
func acquire_by_drag() -> bool:
	var item: Control=shell.inventory_buttons.get_node_or_null("WorldItem_callNumber755")
	check(item!=null,"controller-earned call number exists in world inventory")
	if item==null: return false
	shell.inventory_scroll.ensure_control_visible(item); await frames()
	check(item.is_visible_in_tree() and not item.disabled,"call number has an enabled visible native drag source")
	var end: Vector2=shelf_screen()
	check(end.is_finite(),"actual rendered library_shelf_755 is pickable inside the world viewport")
	if not end.is_finite(): return false
	var start: Vector2=screen_rect(item).get_center()
	motion(start); mouse(start,true)
	var previous: Vector2=start-Vector2(0,18)
	motion(previous,Vector2(0,-18),MOUSE_BUTTON_MASK_LEFT); await frames(2)
	check(root.gui_is_dragging(),"emulated root pointer starts Godot's native inventory drag")
	for i in range(1,6):
		var point: Vector2=(start-Vector2(0,18)).lerp(end,float(i)/5)
		motion(point,point-previous,MOUSE_BUTTON_MASK_LEFT); previous=point; await frames(1)
	mouse(end,false); await frames()
	check(not root.gui_is_dragging(),"pointer release retires the native drag")
	check(action_count("lib_shelf")==1 and grant_count()==1,"real viewport drop reaches the original lib_shelf acquisition exactly once")
	check(state.d.items.archivedLeaveRule and not state.d.items.callNumber755,"controller grants the rule and consumes the earned call number")
	var expected_items: Dictionary=before_shelf.items.duplicate(true)
	expected_items.callNumber755=false; expected_items.archivedLeaveRule=true
	check(state.d.items==expected_items,"shelf acquisition changes exactly its two source-owned inventory entries")
	check(state.d.ui.libraryFinalsPuzzle.archivedRuleCollected and not state.d.ui.libraryFinalsPuzzle.archivedRuleRead,"acquisition preserves the separate read gate")
	check(shell.world_frame.is_visible_in_tree() and not shell.phone.is_visible_in_tree() and reader_openings==0,"successful drop keeps the entire source reveal visible in the world")
	check(not shell.pending_library_reveal.is_empty(),"successful acquisition owns one pending presentation handoff")
	if shell.pending_library_reveal.is_empty(): return false
	var pending: Dictionary=shell.pending_library_reveal
	check(is_same(pending.owner,state.d),"pending owner is the actual live State.d reference")
	check(pending.layer==shell.world.library_layers and int(pending.serial)==shell.world.library_layers.reveal_serial,"pending owner retains the actual layer and its current serial")
	check(not actions.back().snapshot_is_owner,"action-completed snapshot is not misused as live state identity")
	check(shell.world.library_layers.blocks_movement() and shell.world._scene_presentation_blocks(),"source shelf reveal owns the ordinary world movement gate")
	check(is_equal_approx(shell.world.library_layers.shelf_ms,0),"deterministic test freezes automatic processing before acquisition")
	check(action_count("lib_read_rule")==0 and state.get_library_story_session()==null,"reveal never dispatches lib_read_rule or starts reading dialogue")
	samples.append({"case":case_name,"drag_start":str(start),"drag_end":str(end),"viewport":str(root.size),"serial":pending.serial})
	return true
func advance(ms: float) -> void:
	var left: float=ms
	while left>0:
		var step: float=minf(left,10); shell.world._process(step/1000); left-=step
func settled(layer: RefCounted) -> bool:
	return layer.shelf_offset==16 and layer.shelf_phase=="complete" and not layer.blocks_movement() and not layer.paper_pose().visible
func assert_proof(items: Dictionary,puzzle: Dictionary) -> void:
	check(state.d.items==items and state.d.ui.libraryFinalsPuzzle==puzzle,"presentation leaves all acquired inventory and puzzle facts unchanged")
	check(not state.d.ui.libraryFinalsPuzzle.archivedRuleRead and action_count("lib_read_rule")==0 and state.get_library_story_session()==null,"only the existing explicit read action may acknowledge this rule")
func payload(serial: int) -> Dictionary: return {"itemId":"archivedLeaveRule","revealSerial":serial}
func inject(cue: String,data: Dictionary,layer: RefCounted) -> void:
	# Deliberately adversarial bridge input, separate from ordinary acquisition.
	shell._library_world_presentation(cue,data,layer)
func timeline_case(dimensions: Vector2i,reduced: bool) -> void:
	case_name="%dx%d/%s-timeline"%[dimensions.x,dimensions.y,"reduced" if reduced else "normal"]
	await fixture(dimensions,reduced)
	if not await acquire_by_drag(): return
	var layer: RefCounted=shell.world.library_layers
	var serial: int=layer.reveal_serial
	var items: Dictionary=state.d.items.duplicate(true)
	var puzzle: Dictionary=state.d.ui.libraryFinalsPuzzle.duplicate(true)
	var player: Vector2=shell.world.player
	var phone_bounds: Rect2=screen_rect(shell.phone)
	check(layer.paper_start_ms()==(140 if reduced else 2215) and layer.shelf_total_ms()==(380 if reduced else 2895),"source paper start and full reveal durations remain exact")
	for i in range(3): state.act("lib_shelf")
	await frames()
	check(grant_count()==1 and layer.reveal_serial==serial and layer.shelf_ms==0,"repeated source dispatch neither regrants, reconsumes nor restarts the active reveal")
	assert_proof(items,puzzle)
	shell.world.grab_focus(); key(KEY_D,true)
	if reduced:
		advance(139)
		check(layer.shelf_offset==0 and layer.shelf_phase!="paper","reduced source motion has not begun at139ms")
		advance(1)
	else:
		for row: Dictionary in layer.source.shelf.frames:
			advance(float(row.durationMs)-1)
			check(shell.world_frame.is_visible_in_tree() and not shell.phone.is_visible_in_tree(),"world stays visible before each authored cabinet frame")
			advance(1)
			check(layer.shelf_offset==int(row.offsetPx) and layer.shelf_phase==str(row.phase),"real world applies each authored delayed cabinet frame")
		advance(109)
		check(layer.shelf_phase=="sliding" and is_equal_approx(layer.shelf_ms,2214),"last source slide holds until the2215ms paper reveal")
		advance(1)
	check(layer.shelf_phase=="paper" and layer.paper_pose().visible and layer.shelf_offset==16,"paper phase starts at the exact source boundary with the final16px cabinet offset")
	check(shell.world_frame.is_visible_in_tree() and reader_openings==0,"paper transfer remains on the live world surface")
	advance((380 if reduced else 2895)-(140 if reduced else 2215)-1)
	check(layer.blocks_movement() and shell.world.player==player,"ordinary held D input cannot move during any source animation phase")
	check(shell.world_frame.is_visible_in_tree() and not shell.phone.is_visible_in_tree() and reader_openings==0,"reader stays hidden until the final source millisecond")
	key(KEY_D,false)
	advance(1); await frames()
	check(settled(layer),"natural completion settles the original shelf and removes the paper overlay")
	check(shell.phone.is_visible_in_tree() and not shell.world_frame.is_visible_in_tree() and state.d.native.page=="library_rule","completion automatically reveals the existing library_rule phone page")
	check(reader_openings==1 and shell.pending_library_reveal.is_empty(),"natural completion opens the reader once and retires the pending owner")
	check(screen_rect(shell.phone)==phone_bounds,"handoff preserves the canonical phone geometry")
	check(shell.world_page_origin_scene=="library_interior" and not shell.phone_world_return.disabled,"reader keeps its enabled return to the same Library world")
	assert_proof(items,puzzle)
	inject(CUE,payload(serial),layer); inject(CUE,payload(serial),layer); await frames()
	check(reader_openings==1,"duplicate completion never opens a second reader")
	await click(shell.phone_world_return)
	check(shell.world_frame.is_visible_in_tree() and settled(layer),"actual reader Return restores the acquired16px shelf without replay")
	inject(CUE,payload(serial),layer); advance(3100); await frames()
	check(shell.world_frame.is_visible_in_tree() and not shell.phone.is_visible_in_tree() and reader_openings==1,"late duplicate completion cannot reopen a reader after explicit Return")
	assert_proof(items,puzzle)
func adversarial_case(dimensions: Vector2i) -> void:
	case_name="%dx%d/owner-and-skip"%[dimensions.x,dimensions.y]
	await fixture(dimensions)
	if not await acquire_by_drag(): return
	var layer: RefCounted=shell.world.library_layers
	var serial: int=layer.reveal_serial
	var items: Dictionary=state.d.items.duplicate(true)
	var puzzle: Dictionary=state.d.ui.libraryFinalsPuzzle.duplicate(true)
	var copy: Dictionary=state.d.duplicate(true)
	var stranger: RefCounted=Layer.new(); stranger.sync(state.d)
	inject("library_backpack_broadcast_line",{"text":"ownership regression","index":0,"revealSerial":serial},layer)
	inject(CUE,{"itemId":"callNumber755","revealSerial":serial},layer)
	inject(CUE,{"itemId":"archivedLeaveRule"},layer)
	inject(CUE,payload(serial+1),layer)
	inject(CUE,payload(serial-1),layer)
	inject(CUE,payload(serial),stranger)
	inject(CUE,payload(serial),layer)
	check(reader_openings==0 and not shell.pending_library_reveal.is_empty() and layer.blocks_movement(),"wrong cue, item, missing/stale serial, foreign layer and premature matching cue cannot open the reader")
	check(not layer.finish_shelf_reveal(copy,serial) and not layer.finish_shelf_reveal(state.d,serial+1),"skip rejects equal-content wrong state identity and a stale serial")
	layer.cancel_shelf_reveal(copy,serial); layer.cancel_shelf_reveal(state.d,serial+1)
	check(layer.blocks_movement() and layer.reveal_serial==serial,"wrong-owner cancellation cannot interfere with the live reveal")
	advance(400)
	check(layer.finish_shelf_reveal(state.d,serial),"owning presentation skip can finish the already-earned reveal")
	check(settled(layer) and reader_openings==0,"skip settles presentation before its queued completion is delivered")
	check(not layer.finish_shelf_reveal(state.d,serial),"repeated skip cannot enqueue a second completion")
	var queued: Array=layer.cue_queue.filter(func(row: Dictionary): return row.id==CUE)
	check(queued.size()==1 and queued[0].payload==payload(serial),"skip queues exactly the existing completion cue with item and serial ownership")
	shell.world._process(0); await frames()
	check(reader_openings==1 and shell.phone.is_visible_in_tree() and shell.pending_library_reveal.is_empty(),"ordinary world cue delivery performs the skip handoff exactly once")
	assert_proof(items,puzzle)
	await click(shell.phone_world_return)
	inject(CUE,payload(serial),stranger); inject(CUE,payload(serial),layer); await frames()
	check(reader_openings==1 and shell.world_frame.is_visible_in_tree(),"retired and foreign owners cannot steal the surface back")
	# Reuse the same layer for a genuinely new earned fixture; its old serial
	# must not become valid merely because the live state has matching values.
	await fixture(dimensions)
	if not await acquire_by_drag(): return
	check(layer==shell.world.library_layers and layer.reveal_serial!=serial,"new acquisition on the retained layer receives a different serial")
	inject(CUE,payload(serial),layer)
	check(reader_openings==0 and layer.blocks_movement(),"completion from the prior acquisition cannot finish the current owner")
	shell._cancel_library_reveal()
func cancellation_case(dimensions: Vector2i,kind: String) -> void:
	case_name="%dx%d/cancel-%s"%[dimensions.x,dimensions.y,kind]
	await fixture(dimensions)
	if not await acquire_by_drag(): return
	var layer: RefCounted=shell.world.library_layers
	var serial: int=layer.reveal_serial
	var items: Dictionary=state.d.items.duplicate(true)
	var puzzle: Dictionary=state.d.ui.libraryFinalsPuzzle.duplicate(true)
	advance(700)
	match kind:
		"explicit": shell._cancel_library_reveal()
		"escape": await press(KEY_ESCAPE)
		"phone-key": await press(KEY_P)
		"phone-button": await click(shell.mobile_back)
		"page": state.open_page("library_app")
		"same-page": shell._on_phone_page("library_rule")
		"scene": state.open_scene("campus_bootstrap")
		"runtime-reset": state.story_reset.emit()
		"state-replacement": state.d=state.d.duplicate(true); state.changed.emit()
		"queued-then-cancel":
			check(layer.finish_shelf_reveal(state.d,serial),"finish may queue completion before navigation wins")
			await press(KEY_P)
	await refresh()
	check(shell.pending_library_reveal.is_empty(),"interruption automatically retires the pending reveal")
	check(not layer.blocks_movement() and layer.take_cues().filter(func(row: Dictionary): return row.id==CUE).is_empty(),"interruption unlocks movement and removes any queued completion")
	if kind in ["phone-key","phone-button","queued-then-cancel"]:
		check(shell.phone.is_visible_in_tree() and state.d.native.page=="phone_home","explicit phone navigation wins over the interrupted reveal")
	if kind=="escape": check(shell.world_frame.is_visible_in_tree(),"Escape cancels presentation while keeping the Library world visible")
	assert_proof(items,puzzle)
	var page: String=str(state.d.native.page)
	var world_visible: bool=shell.world_frame.is_visible_in_tree()
	var phone_visible: bool=shell.phone.is_visible_in_tree()
	inject(CUE,payload(serial),layer); advance(3100); await frames()
	check(str(state.d.native.page)==page and shell.world_frame.is_visible_in_tree()==world_visible and shell.phone.is_visible_in_tree()==phone_visible and reader_openings==0,"stale completion cannot undo the interruption or open the reader later")
	# Ordinary new state identity and scene re-entry restore the earned pose,
	# without synthesizing an action, pending owner, or replayed reveal.
	state.d=state.d.duplicate(true); state.open_scene("library_interior"); await refresh()
	shell._show_world_mobile(); await frames(); advance(3100)
	check(settled(layer) and shell.pending_library_reveal.is_empty() and shell.world_frame.is_visible_in_tree(),"cancelled/acquired reload and re-entry restore the final16px shelf without replay")
	check(grant_count()==1 and reader_openings==0,"restore neither reacquires the rule nor auto-opens its reader")
	assert_proof(items,puzzle)
func persistence_case(dimensions: Vector2i) -> void:
	case_name="%dx%d/actual-save-reload"%[dimensions.x,dimensions.y]
	await fixture(dimensions)
	if not await acquire_by_drag(): return
	var layer: RefCounted=shell.world.library_layers
	var serial: int=layer.reveal_serial
	var owner: Dictionary=state.d
	var items: Dictionary=state.d.items.duplicate(true)
	var puzzle: Dictionary=state.d.ui.libraryFinalsPuzzle.duplicate(true)
	advance(700)
	state.developer_mode=false
	check(state.save_game(),"mid-reveal acquired rule passes the real native save validator and file writer")
	check(state.load_game(),"actual persisted mid-reveal save reloads through the native reader")
	check(not is_same(owner,state.d),"actual native load replaces the live state owner")
	state.developer_mode=true
	await refresh()
	check(shell.pending_library_reveal.is_empty() and settled(layer),"actual reload restores final16px cabinet without replaying presentation")
	inject(CUE,payload(serial),layer); advance(3100); await frames()
	check(shell.world_frame.is_visible_in_tree() and reader_openings==0,"pre-load completion cannot open the reader in the loaded owner")
	assert_proof(items,puzzle)
	check(grant_count()==1,"real save and reload do not reacquire or reconsume an item")

func reset_case(dimensions: Vector2i) -> void:
	case_name="%dx%d/new-game-reset"%[dimensions.x,dimensions.y]
	await fixture(dimensions)
	if not await acquire_by_drag(): return
	var layer: RefCounted=shell.world.library_layers
	var serial: int=layer.reveal_serial
	state.new_game(); await refresh()
	check(shell.pending_library_reveal.is_empty() and not layer.blocks_movement(),"actual new-game reset cancels the old presentation owner")
	var reset_state: Dictionary=state.d.duplicate(true)
	inject(CUE,payload(serial),layer); await frames()
	check(state.d==reset_state and state.d.native.page=="alarm" and not state.d.items.archivedLeaveRule,"old completion cannot grant proof or reopen a reader after a real reset")
	check(reader_openings==0,"real new-game reset never receives a late reader handoff")
	state.developer_mode=true
func run() -> void:
	state=root.get_node("State"); state.developer_mode=true; state.d=state.initial()
	case_name="fixture"
	check(ProjectSettings.globalize_path("user://").begins_with("/tmp/"),"test uses an isolated temporary profile for the actual reset case")
	if failures>0: quit(1); return
	emulation_baseline=Input.emulate_mouse_from_touch
	before_shelf=earned_shelf()
	shell=load("res://scenes/main.tscn").instantiate(); root.add_child(shell); await frames()
	shell.set_process(false); shell.world.set_process(false)
	state.action_completed.connect(record_action); shell.phone.visibility_changed.connect(record_phone)
	if OS.get_cmdline_user_args().has("--manual"):
		case_name="manual-source-eligible-spatial-fixture"
		await fixture(Vector2i(1180,812))
		process_frame.connect(capture_manual_phase)
		manual_mode=true; shell.set_process(true); shell.world.set_process(true)
		print("LIBRARY_REVEAL_MANUAL_READY: source-controller-earned QA fixture; player placed near shelf; no acquisition performed. Drag visible callNumber755 onto the cabinet. Normal shell/world processing remains active.")
		return
	for dimensions in [Vector2i(390,844),Vector2i(430,860),Vector2i(1440,900)]:
		await timeline_case(dimensions,false)
		await timeline_case(dimensions,true)
		await adversarial_case(dimensions)
		await persistence_case(dimensions)
		for kind: String in ["explicit","escape","phone-key","phone-button","page","same-page","scene","runtime-reset","state-replacement","queued-then-cancel"]:
			await cancellation_case(dimensions,kind)
		await reset_case(dimensions)
	key(KEY_D,false); Input.emulate_mouse_from_touch=emulation_baseline
	state.action_completed.disconnect(record_action)
	await shell.shutdown(); shell.queue_free(); await frames()
	var path: String=OS.get_environment("LIBRARY_REVEAL_REPORT")
	if not path.is_empty():
		var file:=FileAccess.open(path,FileAccess.WRITE)
		if file!=null:
			file.store_string(JSON.stringify({"checks":checks,"failures":failures,"graphical_acceptance":false,"actual_cua":false,"physical_device":false,"input":"emulated native root-viewport mouse/keyboard","fixture":"source-controller-earned library route; explicit near-shelf spatial placement","controlled_world_timeline":true,"samples":samples,"cases":outcomes},"\t")); file.close()
		else: check(false,"requested integration report can be written")
	print("LIBRARY_REVEAL_HANDOFF: ",checks," checks; ",failures," failures; native viewport input is emulated, not actual CUA")
	quit(1 if failures else 0)
