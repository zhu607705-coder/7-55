extends SceneTree
## Full main.tscn → real SubViewport input → world → State → live controller.
var state: Node
var shell: Control
var checks: int=0
var failures: int=0
func _initialize() -> void: call_deferred("run")
func check(value: bool,label: String) -> void:
	checks+=1
	if not value: failures+=1; push_error("LIVE LAKE SHELL: "+label)
func key(code: Key) -> void:
	var event: InputEventKey=InputEventKey.new()
	event.keycode=code; event.physical_keycode=code; event.pressed=true
	shell.world_viewport.push_input(event,true)
	event=event.duplicate(); event.pressed=false; shell.world_viewport.push_input(event,true)
func click(source: Vector2) -> void:
	var point: Vector2=shell.world.size/2+(source-shell.world.camera)*shell.world.zoom
	var event: InputEventMouseButton=InputEventMouseButton.new()
	event.position=point; event.global_position=point; event.button_index=MOUSE_BUTTON_LEFT; event.pressed=true
	shell.world_viewport.push_input(event,true)
	event=event.duplicate(); event.pressed=false; shell.world_viewport.push_input(event,true)
func swipe(side: String,reverse: bool=false) -> void:
	var start: Vector2=Vector2(180 if side=="left" else 780,420)
	var event: InputEventScreenTouch=InputEventScreenTouch.new()
	event.index=0; event.position=start; event.pressed=true; shell.world_viewport.push_input(event,true)
	event=event.duplicate(); event.pressed=false; event.position=start+Vector2(0,60 if reverse else -60); shell.world_viewport.push_input(event,true)
func flush() -> void:
	await process_frame; await process_frame
	shell.world.set_process(false)
func run() -> void:
	if not OS.get_user_data_dir().begins_with("/tmp/"): push_error("Isolated /tmp HOME required"); quit(1); return
	state=root.get_node("State"); state.developer_mode=false; state.d=state.initial()
	root.size=Vector2i(1440,900)
	var s: Dictionary=state.d
	s.native.chapter=3; s.native.scene="qizhen_lake"; s.native.page="c3_lake"; s.native.mode="light"; s.runtimeMode="rpg"; s.rpgScene="qizhen_lake"
	s.qizhenLake.merge({"active":true,"phase":"boarding_tutorial","zone":"dock","vehicle":"on_foot","rainSafetyCleared":true,"kayakEquipped":true,"leftPaddleEquipped":true,"rightPaddleEquipped":true},true)
	shell=load("res://scenes/main.tscn").instantiate(); root.add_child(shell)
	await flush()
	check(shell.world_frame.is_visible_in_tree(),"main shell exposes real lake viewport")
	check(not is_instance_valid(shell.active_game),"no standalone kayak minigame")
	# Only place the initial fixture on the authored boarding stand; all actions go through UI.
	shell.world.player=Vector2(650,690); shell.world._sync_player(); shell.world._process(0)
	click(Vector2(710,650)); await flush()
	check(s.qizhenLake.vehicle=="kayak" and shell.world.kayak!=null,"physical boarding click rebuilds world with kayak")
	check(shell.world.lake_session!=null,"world binds controller-issued runtime proof")
	shell.world.grab_focus()
	key(KEY_A); key(KEY_D)
	check(s.qizhenLake.boardingStrokeCount==2,"real A/D events advance source tutorial")
	swipe("left",true)
	check(s.qizhenLake.boardingStrokeCount==2 and s.qizhenLake.boardingLastSide=="right","downward swipe reverses without changing source tutorial")
	swipe("left"); key(KEY_RIGHT); await flush()
	check(s.qizhenLake.boardingTutorialCompleted and s.qizhenLake.zone=="open_water","keyboard/touch fourth alternation crosses to source open water")
	check(shell.world.last_zone=="open_water" and shell.world.player.distance_to(Vector2(560,790))<25,"new source world and entry spawn are displayed")
	check(not is_instance_valid(shell.active_game),"source tutorial never opened generic overlay")
	# Visit a physical open-water gate via actual Space interaction.
	shell.world.player=Vector2(620,160); shell.world.kayak.position=shell.world.player; shell.world._sync_player()
	# Fixture relocation invalidates its old session; rebuild the same real world for this route test.
	shell.world.world_key=""; shell.world.refresh_world(); shell.world._process(0)
	shell.world.grab_focus(); key(KEY_SPACE); await flush()
	check(s.qizhenLake.zone=="channel" and shell.world.last_zone=="channel","Space at source gate immediately changes map")
	check(shell.world.player.distance_to(Vector2(840,755))<30,"portal uses original from-zone entry spawn")
	# Fresh source chase fixture. All onward travel uses real keyboard strokes and world collision.
	s.qizhenLake.merge({"phase":"swan_chase","zone":"channel","vehicle":"kayak","paperCaptured":true,"swanReleased":true,"chaseAttempts":1,"chaseDistance":0,"safeSpawnId":"channel_chase"},true)
	s.items.magneticFishingRod=true; s.native.positions={}; shell.world.world_key=""; shell.world.scene_id=""; shell.world.refresh_world(); state.changed.emit(); await flush()
	shell.world.grab_focus()
	check(shell.world.player==Vector2(1280,680),"chase source spawn and heading are selected")
	for frame: int in range(600):
		if frame%8==0: key(KEY_A if (frame/8)%2==0 else KEY_D)
		shell.world._process(1.0/60)
		if s.qizhenLake.phase=="complete": break
	await flush()
	check(s.qizhenLake.phase=="complete" and s.runtimeMode=="phone","real shell paddle route completes original westbound chase")
	check(s.qizhenLake.chaseDistance==1000 and s.qizhenLake.magneticAttachmentBroken and not s.items.magneticFishingRod,"controller-owned source finish facts and item consumption")
	check(s.native.page=="c35_recovery" and s.chapterThreeInterlude.phase=="reboot","same main shell presents interlude handoff")
	check(not is_instance_valid(shell.active_game),"full route has no fabricated travel/chase game")
	await shell.shutdown(); shell.queue_free(); await process_frame
	print("Live lake main-shell input: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
