extends "res://tests/test_canteen_defense_resume.gd"
## Source-phase fixture, real Main and controller-validated sixty-second proof.
## This is native integration coverage, not a manually earned campaign run.
const Chapter=preload("res://scripts/chapters/chapter3.gd")
var oracle: Dictionary={}
var exploration_zoom: float=0

func open_victory(dimensions: Vector2i,reduced: bool) -> void:
	await close_main()
	# A fresh controller gives the checked-in seed-1 proof its ordinary admission.
	for index: int in range(state.modules.size()):
		if state.modules[index] is Chapter: state.modules[index]=Chapter.new()
	state.d=state.initial(); state.developer_mode=true
	state.d.native.chapter=3; state.d.native.page="phone_home"; state.d.native.scene="canteen_interior"
	state.d.native.settings.reduced_motion=reduced
	state.d.runtimeMode="rpg"; state.d.rpgScene="canteen_interior"
	state.d.canteenHunt.active=true; state.d.canteenHunt.phase="exit_blocking"
	state.d.actOne.movementEnabled=true; state.d.actOne.phase="complete"
	await new_main(dimensions)
	shell.c3_narrative_host.set_process(false); shell.c3_scene_host.set_process(false)
	if not is_instance_valid(shell.active_game): shell._show_world_mobile()
	check(is_instance_valid(shell.active_game),"ordinary Main admits the defense fixture")
	if not is_instance_valid(shell.active_game): return
	var game: Control=shell.active_game
	game.set_process(false)
	check(str(game.config.seed)=="1","fresh controller admits original fixture seed")
	var world: Control=shell.world
	check(world.transition_alpha==1.0,"hidden defense surface retains initial entry fade before handoff")
	var proof: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/canteen_defense.json"))
	proof.session_id=game.config.session_id
	game.finished.emit(proof)
	check(state.d.canteenHunt.phase=="chase_ready" and not is_instance_valid(shell.active_game),"real Main completion validates the entire proof and releases activity")
	exploration_zoom=world.zoom
	shell.c3_narrative_host.tick(0,true)
	check(shell.c3_narrative_host.current!=null and shell.c3_narrative_host.current.sequence_id=="canteen_escape","accepted proof attaches the actual victory owner")
	check(world.transition_alpha==0.0,"same-room victory clears only the hidden entry fade before its first pose")
	await frames(2)

func advance_to(at_ms: float) -> void:
	var host: Control=shell.c3_narrative_host
	while host.current!=null and host.current.elapsed_ms<at_ms:
		host.tick(minf(10,at_ms-host.current.elapsed_ms),true)

func check_camera(label: String) -> void:
	var host: Control=shell.c3_narrative_host
	var world: Control=shell.world
	check(world.size==Vector2(oracle.camera.viewport[0],oracle.camera.viewport[1]) and not world.mobile_exploration,"canonical source surface: "+label)
	check(host.owns_world_contract() and host._escape_camera_owned,"live accepted session owns camera: "+label)
	check(is_equal_approx(world.zoom,float(oracle.camera.zoom)) and world.camera.is_equal_approx(Vector2(oracle.camera.center[0],oracle.camera.center[1])),"executed source camera pose: "+label)
	var room: Rect2=Rect2(world.size/2-world.camera*world.zoom,world.world_size*world.zoom)
	var bounds:=Rect2(Vector2.ZERO,world.size)
	check(bounds.encloses(room),"complete source room remains visible: "+label)
	for point: Vector2 in [host.current.origin,Vector2(1380,852),host.current.paper_pose().point]:
		check(bounds.has_point((point-world.camera)*world.zoom+world.size/2),"start, destination and current flight point stay in view: "+label)
	check(world.transition_alpha==0,"world-entry overlay cannot cover flight: "+label)
	check(shell.world_frame.is_visible_in_tree() and not shell.phone.visible,"world remains visible: "+label)

func check_subtitle(label: String) -> void:
	var host: Control=shell.c3_narrative_host
	host.tick(0,true)
	check(host.view.is_visible_in_tree() and not host.view.body.text.is_empty(),"source line is visible: "+label)
	check(Rect2(Vector2.ZERO,shell.world.size).encloses(host.view.panel.get_rect()),"subtitle stays inside canonical surface: "+label)
	var body: Label=host.view.body
	var measured: Vector2=body.get_theme_font("font").get_multiline_string_size(body.text,HORIZONTAL_ALIGNMENT_LEFT,body.size.x,body.get_theme_font_size("font_size"))
	check(measured.y<=body.size.y+.5,"entire source line fits without clipping: "+label)
	check(body.get_theme_font_size("font_size")*host.view.display_scale>=15,"subtitle keeps readable physical font size: "+label)

func run() -> void:
	check(ProjectSettings.globalize_path("user://").begins_with("/tmp/"),"isolated fixture save profile")
	if failures: quit(1); return
	state=root.get_node("State")
	oracle=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/canteen_victory_source.json"))
	for reduced: bool in [false,true]:
		for dimensions: Vector2i in [Vector2i(1440,900),Vector2i(390,844),Vector2i(844,390)]:
			await open_victory(dimensions,reduced)
			var host: Control=shell.c3_narrative_host
			var world: Control=shell.world
			var session: RefCounted=host.current
			if session==null: continue
			var facts: String=JSON.stringify(state.d.canteenHunt)
			var items: String=JSON.stringify(state.d.items)
			var duration: float=160 if reduced else 760
			for at: float in [0.0,1.0,duration/4,duration/2,duration-1,duration,float(session.spec.delayMs)-1]:
				advance_to(at)
				# A normal camera update must reject a stale exploration transform.
				# The assertions below inspect its result; they never repair the camera.
				world.pan_offset=Vector2(90,-40); world.zoom=exploration_zoom; world.camera=world.player
				world._update_camera()
				check_camera("%s reduced=%s at=%s"%[dimensions,reduced,at])
				check(session.paper_pose().alpha==1,"source paper remains visible through full flight and hold")
			var paused_at: float=session.elapsed_ms
			var paused_pose: Dictionary=session.paper_pose()
			host.tick(100,false); world._update_camera()
			check(session.elapsed_ms==paused_at and session.paper_pose()==paused_pose,"focus pause freezes time and pose without releasing full-room camera")
			check_camera("paused")
			# Resize one live, paused owner through portrait, landscape and desktop.
			# Layout may update the world camera before the host's next process tick.
			for resized: Vector2i in [Vector2i(430,860),Vector2i(860,430),dimensions]:
				root.size=resized; shell.size=Vector2(resized); shell._layout()
				await frames(2)
				check(host.current==session and session.elapsed_ms==paused_at,"resize retains the same paused session and its exact clock")
				check_camera("live resize "+str(resized))
			for line: Dictionary in session.lines:
				advance_to(float(line.atMs))
				world._process(.05)
				check_camera("dialogue after normal world frame")
				check_subtitle(str(dimensions))
				check(not host.blocks_movement(),"source dialogue keeps walking available without following the player")
			var last: Dictionary=session.lines[-1]
			var exit_start: float=float(last.atMs)+float(last.durationMs)+120
			advance_to(exit_start+1)
			check(host.blocks_movement() and session.motion_origin!=Vector2.INF,"scripted exit takes movement ownership at original time")
			check_camera("scripted exit")
			advance_to(session.duration_ms-1)
			world._update_camera(); check_camera("last exit millisecond")
			check(JSON.stringify(state.d.canteenHunt)==facts and JSON.stringify(state.d.items)==items,"presentation cannot mutate facts or rewards")
			host.tick(1,true); shell._refresh()
			check(session.status=="consumed" and host.current==null and not host.apply_owned_camera(),"completed exit releases camera owner exactly once")
			check(world.scene_id=="campus_bootstrap" and is_equal_approx(world.zoom,1.1),"campus receives its own exploration camera")
			check(world.transition_alpha==1.0,"ordinary scene-change fade remains enabled")
			var campus_camera: Vector2=world.camera
			host.reset(); world._update_camera()
			check(world.camera==campus_camera and is_equal_approx(world.zoom,1.1),"stale victory reset cannot overwrite subsequent exploration")

	# Cancellation and reattachment retain the validated paper pose but release
	# the camera between owners. No proof, reward, duration or route is rewritten.
	await open_victory(Vector2i(390,844),false)
	var host: Control=shell.c3_narrative_host
	var world: Control=shell.world
	var cancelled: RefCounted=host.current
	advance_to(190); world.pan_offset=Vector2.ZERO
	host.reset(); shell._layout()
	check(cancelled.status=="cancelled" and not host.apply_owned_camera() and is_equal_approx(world.zoom,exploration_zoom),"cancel restores prior exploration zoom without reacquiring")
	check(world.mobile_exploration,"cancel releases canonical portrait viewport")
	host.tick(0,true)
	check(host.current!=cancelled and host.current.elapsed_ms==0 and host.current.origin==cancelled.origin,"retry reattaches validated paper origin with a fresh clock")
	check_camera("retry")
	# Replacing a save in the same scene must not inherit or restore stale zoom.
	var stale: RefCounted=host.current
	state.d=state.d.duplicate(true)
	state.story_reset.emit(); shell._refresh()
	check(stale.status=="cancelled" and host.current==null and not host.apply_owned_camera(),"same-scene reset releases old camera capability")
	check(is_equal_approx(world.zoom,.85) and world.transition_alpha==1.0,"same-scene reload establishes fresh exploration camera and entry fade")
	host.tick(0,true)
	check(host.current==null and not host.apply_owned_camera(),"save replacement cannot replay an old ephemeral victory")
	# A scene change before cancellation already owns its camera and its fade.
	await open_victory(Vector2i(1440,900),true)
	host=shell.c3_narrative_host; world=shell.world; stale=host.current
	state.d.native.scene="campus_bootstrap"; state.d.rpgScene="campus_bootstrap"
	world.refresh_world(); var zoom_after_switch: float=world.zoom
	host.tick(0,true)
	check(stale.status=="cancelled" and host.current==null and not host.apply_owned_camera(),"scene switch cancels the old narrative camera")
	check(is_equal_approx(world.zoom,zoom_after_switch) and is_equal_approx(world.zoom,1.1) and world.transition_alpha==1.0,"late cancellation leaves new scene camera and fade untouched")
	await close_main()
	print("CANTEEN_VICTORY_CAMERA: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
