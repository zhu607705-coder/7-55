extends "res://tests/test_canteen_defense_resume.gd"
## Source-phase fixture, real Main and controller-validated sixty-second proof.
## This is native integration coverage, not a manually earned campaign run.
const Chapter=preload("res://scripts/chapters/chapter3.gd")
const CanteenLayout=preload("res://scripts/space/canteen_layout.gd")
const Overlay=preload("res://scripts/ui/world_overlay_layout.gd")
const SelectedTheme=preload("res://scripts/ui/selected_ui_theme.gd")
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
	var exit: Dictionary=CanteenLayout.data().side_exit.paperExitPoint
	for point: Vector2 in [host.current.origin,Vector2(exit.x,exit.y),host.current.paper_pose().point]:
		check(bounds.has_point((point-world.camera)*world.zoom+world.size/2),"start, destination and current flight point stay in view: "+label)
	check(world.transition_alpha==0,"world-entry overlay cannot cover flight: "+label)
	check(shell.world_frame.is_visible_in_tree() and not shell.phone.visible,"world remains visible: "+label)

func check_subtitle(label: String) -> void:
	var host: Control=shell.c3_narrative_host
	host.tick(0,true)
	check(host.view.is_visible_in_tree() and not host.view.body.text.is_empty(),"source line is visible: "+label)
	if host.view.screen_rect.has_area():
		check(host.view.get_parent()==host and host.view.screen_rect.encloses(host.view.panel.get_rect()),"portrait subtitle uses the screen-space gap: "+label)
		check(not host.view.panel.get_global_rect().intersects(shell.world_view.get_global_rect()),"portrait subtitle does not cover source film: "+label)
	else:
		check(shell.world_view.get_global_rect().encloses(host.view.panel.get_global_rect()),"native-screen subtitle stays inside displayed canonical surface: "+label)
	var body: Label=host.view.body
	var measured: Vector2=body.get_theme_font("font").get_multiline_string_size(body.text,HORIZONTAL_ALIGNMENT_LEFT,body.size.x,body.get_theme_font_size("font_size"))
	check(measured.y<=body.size.y+.5,"entire source line fits without clipping: "+label)
	var body_size:=maxi(Overlay.BODY_PX,SelectedTheme.size("dialogue","body"))
	var expected_size:=ceili(body_size*state.d.native.settings.text_scale*Overlay.ui_scale(host.view.size))
	var font_size:=body.get_theme_font_size("font_size")
	# The chapter caption retains the selected font and scales up to a 14px
	# floor. Rounding the minimum source size can add one screen pixel.
	var readable_size:bool=font_size==expected_size if expected_size>=14 else font_size in [14,15]
	check(host.view.get_viewport()==root and body.get_theme_font("font")==SelectedTheme.font("dialogue","body") and readable_size,"subtitle uses legible selected screen-space typography: "+label)
	var caption:Rect2=host.view.panel.get_global_rect()
	var film:Rect2=shell.world_view.get_global_rect()
	if host.view.get_parent()==shell.world:caption=Rect2(film.position+caption.position*host.view.display_scale,caption.size*host.view.display_scale)
	var source: Rect2=shell.world.chapter3_layers.doors.opening
	var local:=Rect2((source.position-shell.world.camera)*shell.world.zoom+shell.world.size/2,source.size*shell.world.zoom)
	var film_scale:Vector2=film.size/shell.world.size
	var target:=Rect2(film.position+local.position*film_scale,local.size*film_scale)
	check(not caption.intersects(target),"right-wall doorway remains clear of dialogue: "+label)
	var exit: Dictionary=CanteenLayout.data().side_exit.paperExitPoint
	var arrival:Vector2=film.position+((Vector2(exit.x,exit.y)-shell.world.camera)*shell.world.zoom+shell.world.size/2)*film_scale
	check(not caption.grow(8).has_point(arrival),"paper's side exit remains clear of dialogue: "+label)

func run() -> void:
	check(load("res://tests/native_test_isolation.gd").is_isolated_save(),"isolated fixture save profile")
	if failures: quit(1); return
	state=root.get_node("State")
	oracle=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/canteen_victory_source.json"))
	for reduced: bool in [false,true]:
		for dimensions: Vector2i in [Vector2i(1440,900),Vector2i(960,720),Vector2i(390,844),Vector2i(844,390)]:
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
				if line==session.lines[0]:
					var clock_before:float=session.elapsed_ms
					state.d.native.settings.text_scale=3.0;host.tick(0,true);await frames(2)
					check_subtitle(str(dimensions)+" enlarged")
					check(session.elapsed_ms==clock_before,"enlarged subtitle does not advance source clock")
					state.d.native.settings.text_scale=1.0;host.tick(0,true)
				if host.view.screen_rect.has_area():
					var hidden_at:float=session.elapsed_ms
					shell.world_frame.hide();host.tick(0,false)
					check(not host.view.is_visible_in_tree() and session.elapsed_ms==hidden_at,"hidden SubViewport container hides external subtitle without advancing session")
					shell.world_frame.show();host.tick(0,true)
					check(host.view.is_visible_in_tree() and host.current==session,"world restoration reuses the same subtitle/session")
				check(not host.blocks_movement(),"source dialogue keeps walking available without following the player")
			var last: Dictionary=session.lines[-1]
			var exit_start: float=float(last.atMs)+float(last.durationMs)+120
			advance_to(exit_start+1)
			check(host.blocks_movement() and session.motion_origin!=Vector2.INF,"scripted exit takes movement ownership at original time")
			check_camera("scripted exit")
			var clear_frames:=true
			while session.elapsed_ms<session.duration_ms-1:
				var step:=minf(10,session.duration_ms-1-session.elapsed_ms)
				world._process(step/1000.0)
				host.tick(step,true)
				clear_frames=clear_frames and world.can_stand(world.player)
			check(clear_frames and session.exit_path.size()>2,"authored proof departs around the furniture through clear floor")
			world._update_camera(); check_camera("last exit millisecond")
			var exit: Dictionary=CanteenLayout.data().side_exit.exitPoint
			var exit_point:=Vector2(exit.x,exit.y)
			check(world.player.distance_to(exit_point)<8.0,"scripted player exit reaches the open side doorway")
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
	check(host.current!=null and host.current!=stale and host.current.elapsed_ms==0 and host.current.origin==stale.origin,"saved pending handoff creates a fresh victory owner from its validated receipt")
	check_camera("restored pending handoff")
	check(stale.status=="cancelled" and not stale.valid(state.d),"save replacement cannot reuse the old ephemeral capability")
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
