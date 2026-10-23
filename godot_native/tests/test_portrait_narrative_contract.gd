extends "res://tests/test_portrait_exploration.gd"
const DisplayFixture=preload("res://tests/zh_text_fixture.gd")
## Source-phase fixtures through real State/Main/host and projected touch.
class SourceLine extends RefCounted:
	var line: String=""
	func snapshot() -> Dictionary: return {"rawText":line,"text":line,"speaker":"阿姨"}
func configure(dimensions: Vector2i,scene: String="canteen_interior") -> void:
	shell._close_modal(); state.d=state.initial()
	state.d.native.chapter=3; state.d.native.scene=scene; state.d.native.page="c3_canteen" if scene=="canteen_interior" else "c3_theater"
	state.d.rpgScene=scene; state.d.runtimeMode="rpg"
	state.d.actOne.movementEnabled=true; state.d.actOne.phase="complete"; state.d.actOne.inventoryRecovered=true; state.d.items.gamepad=true
	state.d.canteenHunt.active=true; state.d.canteenHunt.phase="tray_search"; state.d.canteenHunt.entryPaperEscaped=true
	if scene=="theater_interior":
		state.d.theaterHunt.active=true; state.d.theaterHunt.phase="reversal"; state.d.theaterHunt.spotlightRound=3; state.d.theaterHunt.admitted=true
	root.size=dimensions; shell.size=Vector2(dimensions); shell.mobile_world=true; shell.compact_inventory_open=false
	state.story_reset.emit(); state.changed.emit(); shell._layout(); await frames()
	shell.world.set_process(false); shell.c3_narrative_host.set_process(false); shell.c3_scene_host.set_process(false)
func subtitle_bounds(label: String) -> void:
	var view: Control=shell.c3_narrative_host.view
	var panel: Rect2=view.panel.get_global_rect()
	var bounds:Rect2=shell.world_view.get_global_rect()
	var controls: Dictionary=shell.world.mobile_control_metrics()
	check(bounds.encloses(panel),"subtitle stays in exploration: "+label)
	check(is_equal_approx(panel.end.y,(view.get_global_transform_with_canvas()*view.exploration_rect.end).y),"subtitle rests on the current bottom safe edge: "+label)
	check(panel.position.y>=world_screen(Vector2(0,shell.world.hud_metrics("").header_height)).y,"subtitle clears world header: "+label)
	var mode:=Rect2(world_screen(controls.mode.position),world_screen(controls.mode.end)-world_screen(controls.mode.position))
	var gestures:=Rect2(world_screen(controls.gestureArea.position),world_screen(controls.gestureArea.end)-world_screen(controls.gestureArea.position))
	check(not panel.intersects(mode) and gestures.size.y>=44 and bounds.encloses(gestures),"subtitle clears mode control and preserves a usable direct-touch map: "+label)
	# Selected prose is pointer-transparent; the real floor-tap progression
	# below verifies movement, rather than reserving a removed virtual D-pad.
	var actual:Vector2=view.body.get_theme_font("font").get_multiline_string_size(view.body.text,HORIZONTAL_ALIGNMENT_LEFT,view.body.size.x,view.body.get_theme_font_size("font_size"))
	check(actual.y<=view.body.size.y+.5 and view.body.get_theme_font_size("font_size")>=14,"full subtitle stays readable without clipping: "+label)
func advance_to(ms: float) -> void:
	var host: Control=shell.c3_narrative_host
	while host.current!=null and host.current.elapsed_ms<ms and host.current.status!="inspecting":
		host.tick(minf(100,ms-host.current.elapsed_ms),true)
func run() -> void:
	check(load("res://tests/native_test_isolation.gd").is_isolated_save(),"isolated fixture profile")
	if failures: quit(1); return
	state=root.get_node("State"); state.developer_mode=false; state.d=state.initial()
	shell=load("res://scenes/main.tscn").instantiate(); root.add_child(shell); await frames()
	# Chapter-specific hosts are created by configure below, after admission.
	shell.world.set_process(false)
	var oracle:Dictionary=DisplayFixture.chapter3(JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/chapter3_narrative_source.json")))
	for dimensions in [Vector2i(390,844),Vector2i(430,860),Vector2i(844,390)]:
		await configure(dimensions)
		var world:Control=shell.world
		var host:Control=shell.c3_narrative_host
		world.player=world._find_safe(Vector2(1466,608)); world._sync_player(); world._update_camera()
		var extent:Vector2=world.size
		state.act("c3_target:auntie"); host.tick(0,true); await frames()
		var session:RefCounted=host.current
		check(session!=null and session.sequence_id=="canteen_tray_intro","controller issues auntie queue")
		check(world.mobile_exploration and world.size==extent and not shell._authored_world_contract(),"ordinary timed dialogue preserves exploration at "+str(dimensions))
		check(host.blocks_input() and not host.blocks_movement(),"ordinary dialogue retains source interaction/movement distinction")
		subtitle_bounds("auntie "+str(dimensions))
		print("NARRATIVE_MEASURE ",dimensions," world=",world.size," panel=",host.view.panel.get_rect()," gestures=",world.mobile_control_metrics().gestureArea," font=",host.view.body.get_theme_font_size("font_size"))
		# The dialogue was issued at the original auntie stand. This separate
		# movement fixture uses the same source aisle as the approach regression,
		# where both the player and visible empty floor have room for full feet.
		world.player=Vector2(1235.25,735);world._sync_player();world._update_camera()
		check(world.can_stand(world.player),"ordinary-dialogue movement fixture starts on the unchanged source aisle")
		var before:Vector2=world.player
		var direction:=Vector2.ZERO
		for axis:Vector2 in [Vector2.RIGHT,Vector2.LEFT,Vector2.UP,Vector2.DOWN]:
			if world.can_stand(before+axis*8.25): direction=axis; break
		var point:=floor_touch_point(direction)
		await tap_floor(point)
		check(not world._floor_route.is_empty(),"ordinary dialogue permits a real empty-floor path request while target interaction remains locked")
		world._process(.05);await cancel_floor_touch(point)
		check(world.player.distance_to(before)>0,"real projected touch keeps moving beneath ordinary dialogue")
		var at:float=session.elapsed_ms
		host.tick(100,false)
		check(session.elapsed_ms==at and world.mobile_exploration,"paused ordinary dialogue keeps exploration and source timing")
		# Every source line fits with the permanent inline inventory, including landscape.
		for bag_open in [false,true]:
			shell.compact_inventory_open=bag_open; shell._layout(); await frames(); host.tick(0,true)
			check(not shell.inventory_handle.visible and shell.inventory_dock.visible,"source lines use the permanent inline inventory without a bag switch")
			var source:=SourceLine.new(); host.view.session=source
			for group:String in oracle.groups:
				for line:Dictionary in oracle.groups[group].lines:
					source.line=line.text; host.view.tick(); subtitle_bounds(group+" "+str(dimensions))
			host.view.session=session
		advance_to(session.duration_ms-1)
		check(not state.d.canteenHunt.trayTaskStarted and world.mobile_exploration,"last millisecond keeps source receipt pending")
		host.tick(1,true); await frames()
		check(session.status=="consumed" and host.current==null and state.d.canteenHunt.trayTaskStarted and world.mobile_exploration,"terminal auntie receipt restores normal interaction without resizing world")
		var npcs:Array=world.targets.filter(func(target:Dictionary)->bool:return target.id=="initial-counter-npc")
		check(not npcs.is_empty(),"real ordinary talk target exists")
		if not npcs.is_empty():
			var npc:Dictionary=npcs[0]
			world.player=world._find_safe(world._target_point(npc)); world._sync_player(); world._update_camera()
			state.act(str(npc.action)); host.tick(0,true); await frames()
			check(host.current!=null and host.current.sequence_id=="canteen_npc_initial-counter-npc" and world.mobile_exploration,"ordinary NPC talk preserves current exploration viewport")
			if host.current!=null:
				subtitle_bounds("ordinary NPC "+str(dimensions)); advance_to(host.current.duration_ms); await frames()
		# A genuine camera sequence keeps canonical aspect despite allowing walking.
		await configure(dimensions)
		state.d.items.dailySpecialSparklingWater=true
		world.player=world._find_safe(Vector2(1232,285)); world._sync_player(); world._update_camera()
		state.act("c3_target:canteen-promo-board"); host.tick(0,true)
		check(host.current!=null and host.current.sequence_id=="canteen_promo" and not host.blocks_movement(),"source promo is an authored camera owner with walking allowed")
		check(world.size==Vector2(960,540) and not world.mobile_exploration and host.owns_world_contract(),"promo acquires canonical viewport synchronously")
		check(host.view.get_parent()==host and is_equal_approx(host.view.display_scale,1.0),"first cinematic tick paints selected typography in the native screen viewport")
		advance_to(host.current.duration_ms); await frames()
		check(world.mobile_exploration and host.current==null,"completed promo returns exploration")
		# Genuine theater reveal retains its contract through lines and inspector.
		await configure(dimensions,"theater_interior")
		state.d.theaterHunt.active=true; state.d.theaterHunt.phase="reversal"; state.d.theaterHunt.spotlightRound=3; state.d.theaterHunt.admitted=true
		state.act("c3_reversal"); host.tick(0,true); session=host.current
		check(session!=null and session.sequence_id=="theater_reversal" and world.size==Vector2(960,540),"theater reveal acquires authored viewport synchronously")
		advance_to(1320)
		check(not host.blocks_movement() and host.owns_world_contract() and world.size==Vector2(960,540),"reveal dialogue retains whole-session authored contract")
		advance_to(session.inspector_at_ms)
		check(session.status=="inspecting" and host.owns_world_contract() and is_instance_valid(shell.modal),"theater inspector pause retains canonical world")
		var before_state:String=JSON.stringify(state.d); at=session.elapsed_ms
		root.size=Vector2i(430,860); shell.size=Vector2(430,860); shell._layout(); host.tick(100,false)
		check(world.size==Vector2(960,540) and session.elapsed_ms==at and JSON.stringify(state.d)==before_state,"rotation/focus pause cannot crop reveal or alter progress")
		shell._close_modal(); advance_to(session.duration_ms); await frames()
		check(host.current==null and world.mobile_exploration,"completed reveal releases canonical aspect")
	await shell.shutdown(); shell.queue_free(); await frames()
	print("PORTRAIT_NARRATIVE_CONTRACT: %d checks; %d failures"%[checks,failures]); quit(1 if failures else 0)
