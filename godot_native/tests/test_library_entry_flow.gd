extends SceneTree
## Routed Main regression: issued library entry, focus return, and in-page record action.
var state: Node
var shell: Control
var checks: Array=[]
var prefix: String
func _initialize() -> void: run.call_deferred()
func frames(count: int=3) -> void:
	for i in count: await process_frame
func check(ok: bool,id: String,detail: Variant=null) -> void:
	checks.append({"id":prefix+id,"passed":ok,"detail":detail})
	if not ok: push_error(prefix+id+": "+str(detail))
func key(code: int,pressed: bool=true) -> void:
	var event:=InputEventKey.new(); event.keycode=code; event.physical_keycode=code; event.pressed=pressed; Input.parse_input_event(event)
	await process_frame
func press(code: int) -> void:
	await key(code); await key(code,false); await frames()
func click(at: Vector2) -> void:
	var motion:=InputEventMouseMotion.new(); motion.position=at; motion.global_position=at; Input.parse_input_event(motion)
	for down in [true,false]:
		var event:=InputEventMouseButton.new(); event.position=at; event.global_position=at; event.button_index=MOUSE_BUTTON_LEFT; event.pressed=down; Input.parse_input_event(event); await process_frame
	await frames()
func focus_path(viewport: Viewport) -> String:
	var focus=viewport.gui_get_focus_owner()
	return str(focus.get_path()) if focus else "none"
func buttons(parent: Node,text: String) -> Array:
	var result: Array=[]
	for child in parent.get_children():
		if child is Button and child.text==text: result.append(child)
		result.append_array(buttons(child,text))
	return result
func label_matches(parent: Node,text: String) -> bool:
	for child in parent.get_children():
		if child is Label and child.text==text: return true
		if label_matches(child,text): return true
	return false
func run() -> void:
	state=root.get_node("State"); state.developer_mode=true
	for dimensions in [Vector2i(1440,900),Vector2i(390,844),Vector2i(430,860)]: await entry(dimensions)
	var report_path=OS.get_environment("UI_QA_REPORT")
	if report_path.is_empty(): report_path="user://library-entry-flow.json"
	var report=FileAccess.open(report_path,FileAccess.WRITE); report.store_string(JSON.stringify({"kind":"routed-Main-input-and-layout","graphical_acceptance":false,"checks":checks},"\t")); report.close()
	var failures=checks.filter(func(row):return not row.passed)
	print("LIBRARY_ENTRY_FLOW: ",checks.size()," checks; ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
func entry(dimensions: Vector2i) -> void:
	prefix="%dx%d/"%[dimensions.x,dimensions.y]
	state.d=state.initial()
	# Eligible campus fixture only; introduction and every record fact below
	# are earned through the same controller and viewport input as Main.
	state.d.native.chapter=2; state.d.native.scene="campus_bootstrap"; state.d.native.page="library_app"
	state.d.rpgScene="campus_bootstrap"; state.d.runtimeMode="rpg"
	state.d.actOne.phase="complete"; state.d.ui.libraryFinalsPhase="library_route_unlocked"; state.d.networkMode="campus_wifi"
	root.size=dimensions
	shell=load("res://scenes/main.tscn").instantiate(); root.add_child(shell); await frames(5)
	await create_timer(1.6).timeout; await frames()
	shell._show_world_mobile(); shell.world.grab_focus(); shell.world.set_process(false)
	state.act("lib_enter"); await frames(5)
	var host: Control=shell.library_story_host
	host.set_process(false)
	check(host.current!=null and host.current.sequence_id=="library_entered","issued-library-entry-dialogue")
	var authored_lines: int=host.current.lines.size()
	for i in authored_lines: await press(KEY_SPACE)
	check(host.current==null and not shell.world._scene_presentation_blocks(),"issued-dialogue-completes",authored_lines)
	check(state.d.native.page=="library_app" and not state.d.ui.libraryFinalsPuzzle.entranceRecordRead,"last-dialogue-key-does-not-interact-through-overlay")
	check(shell.world.has_focus(),"world-focus-restored",{"root":focus_path(root),"world":focus_path(shell.world_viewport)})
	var before: Vector2=shell.world.player
	await key(KEY_W)
	for i in 6: shell.world._process(.05)
	await key(KEY_W,false); shell.world._process(0)
	check(shell.world.player.distance_to(before)>1,"routed-W-movement-works",[before,shell.world.player])
	check(str(shell.world.nearby.get("id",""))=="entrance_record","actual-entry-record-is-nearest",shell.world.nearby)
	await press(KEY_SPACE)
	check(state.d.native.page=="library_record","routed-Space-opens-record-without-pointer",{"page":state.d.native.page,"root_focus":focus_path(root),"world_focus":focus_path(shell.world_viewport)})
	if state.d.native.page!="library_record":
		shell.world.grab_focus(); await press(KEY_SPACE)
		check(state.d.native.page=="library_record","focused-world-control-opens-record")
	var actions=state.get_actions("library_record")
	var record_buttons=buttons(shell.page_body,"记下入馆记录")
	check(actions.size()==1 and record_buttons.size()==1,"exactly-one-controller-record-action",record_buttons.size())
	check(label_matches(shell.page_body,str(state.get_view("library_record").body)),"record-evidence-text-unchanged")
	check(not state.d.ui.libraryFinalsPuzzle.entranceRecordRead,"rendering-record-does-not-acknowledge")
	if record_buttons.size()==1:
		var button: Button=record_buttons[0]
		check(button.name=="LibraryRecordAction" and shell.phone_scroll.get_global_rect().encloses(button.get_global_rect()) and shell.phone_scroll.scroll_vertical==0,"record-action-visible-at-initial-scroll",{"button":button.get_global_rect(),"visible_scroll":shell.phone_scroll.get_global_rect()})
		await click(button.get_global_rect().get_center())
		check(state.d.ui.libraryFinalsPuzzle.entranceRecordRead and state.d.ui.libraryFinalsPuzzle.clueIds.has("arrival_7_minutes"),"routed-record-click-earns-existing-clue")
		check(not state.d.ui.libraryFinalsPuzzle.backpackInspected and state.d.ui.libraryFinalsPhase=="library_entered","record-preserves-next-story-gate")
		check(buttons(shell.page_body,"记下入馆记录").is_empty(),"acknowledged-record-action-removed")
		state.act("lib_open_record"); await frames()
		check(buttons(shell.page_body,"记下入馆记录").is_empty() and state.d.ui.libraryFinalsPuzzle.clueIds.count("arrival_7_minutes")==1,"record-reopen-does-not-duplicate-clue-or-action")
	await bag_dialogue()
	# A deferred handoff must never steal focus from a new modal or hidden RPG.
	shell._modal_base("Focus regression"); await frames(); var modal_focus=root.gui_get_focus_owner()
	if shell.has_method("_focus_library_story"): shell._focus_library_story()
	check(root.gui_get_focus_owner()==modal_focus,"new-modal-keeps-focus")
	shell._close_modal(); await frames()
	if dimensions.x<1100:
		shell.world.release_focus(); shell.mobile_world=false; shell._layout()
		if shell.has_method("_focus_library_story"): shell._focus_library_story()
		check(not shell.world.has_focus(),"hidden-world-does-not-claim-focus")
	await shell.shutdown(); shell.queue_free(); await frames()

func walk_to_bag() -> bool:
	# Compute a collision-checked route, then walk it using routed W/A/S/D.
	# No player teleport or progress mutation is used to reach the backpack.
	var start: Vector2=shell.world.player
	var goal:=Vector2(1237,470)
	var step:=16.5
	var pending: Array[Vector2i]=[Vector2i.ZERO]
	var visited: Dictionary={Vector2i.ZERO:Vector2i.ZERO}
	var scores: Dictionary={Vector2i.ZERO:0.0}
	var reached:=Vector2i(99999,99999)
	while not pending.is_empty() and visited.size()<30000:
		var best:=0
		for i in range(1,pending.size()):
			if scores[pending[i]]+(start+Vector2(pending[i])*step).distance_to(goal)<scores[pending[best]]+(start+Vector2(pending[best])*step).distance_to(goal): best=i
		var cell: Vector2i=pending[best]; pending.remove_at(best)
		var point:=start+Vector2(cell)*step
		if point.distance_to(goal)<22: reached=cell; break
		for direction: Vector2i in [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]:
			var next:=cell+direction
			if visited.has(next) or not shell.world.can_stand(point+Vector2(direction)*step/2) or not shell.world.can_stand(point+Vector2(direction)*step): continue
			visited[next]=cell; scores[next]=scores[cell]+step; pending.append(next)
	if reached.x==99999: return false
	var route: Array[Vector2i]=[]
	while reached!=Vector2i.ZERO:
		route.push_front(reached-visited[reached]); reached=visited[reached]
	for direction: Vector2i in route:
		var code: int=KEY_W if direction==Vector2i.UP else KEY_D if direction==Vector2i.RIGHT else KEY_S if direction==Vector2i.DOWN else KEY_A
		await key(code)
		for i in 2: shell.world._process(.05)
		await key(code,false)
	shell.world._process(0)
	return true

func bag_dialogue() -> void:
	shell._show_world_mobile(); shell.world.grab_focus()
	var walked: bool=await walk_to_bag()
	check(walked and str(shell.world.nearby.get("id",""))=="backpack","routed-walk-reaches-backpack",{"position":shell.world.player,"nearby":shell.world.nearby})
	if not walked: return
	await press(KEY_SPACE)
	shell.world.release_focus()
	if shell.has_method("_focus_library_story"): shell._focus_library_story()
	check(not shell.world.has_focus() and state.get_library_story_session()!=null,"pending-issued-queue-does-not-return-world-focus")
	shell.library_story_host.tick(0); await frames()
	var host: Control=shell.library_story_host
	check(host.current!=null and host.current.sequence_id=="library_occupied_seat_found","routed-Space-issues-bag-dialogue")
	if host.current==null: return
	var dialogue_focus=root.gui_get_focus_owner()
	if shell.has_method("_focus_library_story"): shell._focus_library_story()
	check(root.gui_get_focus_owner()==dialogue_focus and dialogue_focus==host.view,"active-dialogue-keeps-focus")
	var lines: int=host.current.lines.size()
	for i in lines: await press(KEY_SPACE)
	shell.world._process(0)
	check(host.current==null and state.d.ui.libraryFinalsPuzzle.backpackInspected,"genuine-bag-dialogue-completes",lines)
	check(not state.d.ui.libraryFinalsPuzzle.occupancyNoteCollected,"bag-final-key-does-not-collect-note")
	check(shell.world.has_focus(),"bag-completion-restores-world-focus",{"root":focus_path(root),"world":focus_path(shell.world_viewport)})
	check(str(shell.world.nearby.get("id",""))=="occupancy_note","actual-note-is-nearest-after-bag",shell.world.nearby)
	await press(KEY_SPACE)
	check(state.d.ui.libraryFinalsPuzzle.occupancyNoteCollected and state.d.items.occupancyNote,"routed-Space-collects-note-without-refocus")
