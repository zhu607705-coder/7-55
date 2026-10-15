extends SceneTree
## Exercise the actual State → main → world hooks, not a mock controller shell.
var checks: int=0
var errors: int=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: errors+=1; push_error(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var state: Node=root.get_node("State")
	check(ProjectSettings.globalize_path("user://").begins_with("/tmp/"),"shell tests isolate production save writes")
	if errors: quit(1); return
	root.size=Vector2i(1280,720)
	state.developer_mode=false; state.d=state.initial()
	state.d.native.chapter=3; state.d.native.scene="canteen_interior"; state.d.native.page="c3_canteen"
	state.d.canteenHunt.active=true; state.d.canteenHunt.phase="tray_search"; state.d.canteenHunt.entryPaperEscaped=true
	state.d.actOne.movementEnabled=true; state.d.actOne.phase="complete"; state.d.runtimeMode="rpg"; state.d.rpgScene="canteen_interior"
	var main: Control=load("res://scenes/main.tscn").instantiate(); root.add_child(main)
	await process_frame; await process_frame
	var world: Control=main.world
	var host: Control=main.c3_narrative_host
	host.set_process(false)
	world.player=world._find_safe(Vector2(1466,608)); world._sync_player()
	state.act("c3_target:auntie"); host.tick(0,true)
	check(host.current!=null and host.current.sequence_id=="canteen_tray_intro","real main attaches controller-issued auntie dialogue")
	check(host.blocks_input() and not host.blocks_movement(),"ordinary queue distinguishes source interaction from movement lock")
	check(world._interaction_presentation_blocks() and not world._scene_presentation_blocks(),"production world consumes separate lock types")
	check(host.view.visible and host.view.body.text=="同学，桌上有三只脏盘，能不能帮我送回来？","real native subtitle shows only first source line")
	var starting: Vector2=world.player
	for axis: Vector2 in [Vector2.RIGHT,Vector2.LEFT,Vector2.UP,Vector2.DOWN]:
		if world.can_stand(starting+axis*8.25): world.touch_axis=axis; break
	world._process(.05); world.touch_axis=Vector2.ZERO
	check(world.player.distance_to(starting)>0,"actual collision-aware touch movement continues during ordinary source dialogue")
	world._try_interact({"id":"auntie","label":"阿姨","action":"c3_target:auntie","position":[world.player.x,world.player.y],"radius":200})
	check(not state.d.canteenHunt.trayTaskStarted,"real world interaction cannot acknowledge queue")
	var old_network: String=state.d.networkMode
	state.act("c3_network","cellular" if old_network!="cellular" else "offline")
	check(state.d.networkMode==old_network,"State prevents underlying controller actions while pending")
	check(not world._can_drop_data(Vector2(800,500),{"kind":"inventory_item","id":"greaseTissue"}),"item/drop interaction remains locked")
	var old_mode: String=state.d.native.mode
	state.toggle_mode()
	check(state.d.native.mode==old_mode,"shared toolbar mode button cannot bypass queued dialogue")
	var old_page: String=state.d.native.page
	state.open_page("phone_home"); state.open_scene("campus_bootstrap")
	check(state.d.native.page==old_page and state.d.native.scene=="canteen_interior","direct shell navigation cannot cancel acknowledgement")
	var session: RefCounted=host.current
	host.tick(100,false)
	check(session.elapsed_ms==0,"actual host focus pause does not consume line time")
	for _i in range(74): host.tick(100,true)
	check(not state.d.canteenHunt.trayTaskStarted,"actual State callback waits for final source beat")
	host.tick(100,true)
	check(state.d.canteenHunt.trayTaskStarted and host.current==null,"production host terminal acknowledgement advances tray task")
	check(state.save_game(),"acknowledged production snapshot persists through native guard")
	# Move the actual world to the source approach checkpoint, preserving runtime ownership.
	state.d.native.scene="campus_qizhen_loop"; state.d.rpgScene="campus_qizhen_loop"; state.d.rpgCheckpoint="campus_theater_junction"
	state.d.native.positions={}; state.d.qizhenLake.active=true; state.d.qizhenLake.phase="location_search"; state.d.qizhenLake.locationBriefingSeen=false
	state.changed.emit(); await process_frame
	host.tick(0,true)
	check(host.current!=null and host.current.sequence_id=="qizhen_approach","real main attaches approach on world entry")
	check(world.player==Vector2(7730,840) and host.blocks_movement(),"real world receives source start and cinematic lock")
	starting=world.player; world.touch_axis=Vector2.RIGHT; world._process(.05); world.touch_axis=Vector2.ZERO
	check(world.player==starting,"actual world movement cannot overwrite authored approach")
	for _i in range(60): host.tick(100,true)
	check(world.player==Vector2(9040,930) and not state.d.qizhenLake.locationBriefingSeen,"real player follows all five original waypoints before remaining dialogue")
	check(host.effects.session!=null and host.effects.get_parent()==world,"native paper/trail renderer mounted in actual world")
	var stale: RefCounted=host.current
	state.story_reset.emit(); state.changed.emit(); await process_frame
	host.set_process(false); host.tick(0,true)
	check(stale.status=="cancelled" and host.current!=stale and world.player==Vector2(7730,840),"real reset cancels old voice owner and reopens incomplete approach at start")
	for _i in range(210): host.tick(100,true)
	check(state.d.qizhenLake.locationBriefingSeen and state.d.rpgCheckpoint=="campus_qizhen_transition_stop","actual host terminal action commits source checkpoint")
	check(host.current==null and not world._interaction_presentation_blocks(),"production input returns only after consumed completion")
	check(state.save_game(),"real approach snapshot is persistable")
	state.act("c3_story_complete",stale)
	check(state.d.qizhenLake.locationBriefingSeen,"stale host completion cannot replay or regress acknowledged approach")
	await main.shutdown()
	main.queue_free(); await process_frame
	print("Chapter 3 narrative shell: %d checks, %d failures" % [checks,errors]); quit(0 if errors==0 else 1)
