extends SceneTree
## Real Main -> replay-validated paper catch -> non-authoritative PR144 shot
## -> original channel kayak proof -> original return. Isolated test saves only.
const Solver = preload("res://tests/campaign_fishing_solver.gd")
const Fishing = preload("res://scripts/games/rhythm_fishing_model.gd")
var state: Node
var shell: Control
var solved: RefCounted
var checks: int = 0
var failures: int = 0
var dismissals: Array[String] = []
var domain_events: Array = []

func _initialize() -> void: run.call_deferred()
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error("SWAN SHELL: "+label)
func frames(count: int=2) -> void:
	for i in range(count): await process_frame
func key(code: Key) -> void:
	var e := InputEventKey.new()
	e.keycode=code; e.physical_keycode=code; e.pressed=true
	shell.world_viewport.push_input(e,true)
	e=e.duplicate(); e.pressed=false; shell.world_viewport.push_input(e,true)
func touch(point: Vector2,pressed: bool,id: int=7,cancelled: bool=false) -> void:
	var e := InputEventScreenTouch.new()
	e.position=point; e.pressed=pressed; e.index=id; e.canceled=cancelled
	shell.world_viewport.push_input(e,true)
func mouse(point: Vector2,pressed: bool,device: int=0) -> void:
	var e := InputEventMouseButton.new()
	e.position=point; e.global_position=point; e.button_index=MOUSE_BUTTON_LEFT; e.pressed=pressed; e.device=device
	shell.world_viewport.push_input(e,true)
func fixture(reduced: bool=false) -> void:
	if is_instance_valid(shell.world_effect): shell._cancel_world_effect(); await frames()
	state.d=state.initial()
	var s: Dictionary=state.d
	s.native.chapter=3; s.native.scene="qizhen_lake"; s.native.page="c3_lake"; s.native.mode="light"
	s.runtimeMode="rpg"; s.rpgScene="qizhen_lake"; s.rpgCheckpoint="qizhen_swan_cove"
	s.native.settings.reduced_motion=reduced
	s.qizhenLake.merge({"active":true,"phase":"paper_capture","zone":"swan_cove","vehicle":"kayak","boardingTutorialCompleted":true,"rainSafetyCleared":true,"kayakEquipped":true,"leftPaddleEquipped":true,"rightPaddleEquipped":true,"swanFed":true,"magneticRodCombined":true,"safeSpawnId":"swan_cove_entry"},true)
	s.items.magneticFishingRod=true
	s.native.positions={"qizhen_lake:swan_cove:kayak":{"x":760,"y":500}}
	shell.world.world_key=""; shell.world.scene_id=""; shell.world.refresh_world()
	state.changed.emit(); shell._show_world_mobile(); shell._layout(); await frames()
	shell.world.set_process(false)
	dismissals.clear(); domain_events.clear()
	check(shell.world.lake_session.valid(s,shell.world),"cove fixture uses the actual live world proof")

func capture() -> Dictionary:
	var source: Vector2=shell.world.player
	var result: Dictionary=state.act("c3_lake_target:qizhen_final_paper_cast")
	check(result.has("game") and is_instance_valid(shell.active_game),"physical paper cast opens actual fishing shell")
	if not is_instance_valid(shell.active_game): return {}
	var game: Control=shell.active_game
	game.set_process(false); game.begin(); game.model=solved; game._check_terminal(); game._process(.91)
	check(not is_instance_valid(shell.active_game) and is_instance_valid(shell.world_effect),"fishing terminal closes once and mounts actual world effect")
	if not is_instance_valid(shell.world_effect): return {}
	var effect: Control=shell.world_effect
	effect.set_process(false)
	# Headless windows have no OS focus; exercise the same host visibility flags.
	effect.read_state=func() -> Dictionary:
		var snapshot: Dictionary=shell._read_runtime_state()
		snapshot.native.host.focused=true
		return snapshot
	effect.dismissed.connect(func(reason: String):dismissals.append(reason))
	effect.event.connect(func(action: String,value: Variant):domain_events.append([action,value]))
	check(effect.session.source_pose.position==source,"shot freezes the real captured cove actor, not the preview model")
	check(is_instance_valid(effect.kayak_rig) and effect.kayak_rig.scene_file_path=="res://scenes/objects/kayak_rig.tscn","formal entrance owns the current native kayak scene")
	check(effect.kayak_rig.get_index()<effect.foreground.get_index() and effect.foreground.get_index()<effect.caption.get_index(),"paper and HUD stay above the native rig")
	check(effect.kayak_rig.position.is_equal_approx(effect._screen(source)) and is_equal_approx(effect.kayak_rig.rotation,float(effect.session.source_pose.heading)+PI/2),"formal native rig samples frozen source position and heading")
	return state.last_result.get("world_effect",{})

func run() -> void:
	if not load("res://tests/native_test_isolation.gd").is_isolated_save(): push_error("Isolated /tmp HOME required"); quit(2); return
	state=root.get_node("State"); state.developer_mode=false; state.d=state.initial()
	root.size=Vector2i(1440,900)
	shell=load("res://scenes/main.tscn").instantiate(); root.add_child(shell); await frames()
	shell.set_process(false); shell.world.set_process(false)
	solved=Solver.new().solve_fishing("paper")
	check(Fishing.validate_result(solved.final_result,"paper"),"paper terminal is an unchanged replay-valid input trace")
	await fixture()
	var config: Dictionary=capture()
	if config.is_empty(): await shell.shutdown(); shell.queue_free(); quit(1); return
	var effect: Control=shell.world_effect
	var completed_rig: Node2D=effect.kayak_rig
	var lease: RefCounted=config.session
	var actor: RefCounted=shell.world.kayak
	var proof: RefCounted=shell.world.lake_session
	var spawn: Vector2=shell.world.player
	var camera: Vector2=shell.world.camera
	var zoom: float=shell.world.zoom
	check(state.d.qizhenLake.paperCaptured and state.d.qizhenLake.swanReleased and state.d.qizhenLake.phase=="swan_chase" and state.d.qizhenLake.chaseAttempts==1,"existing atomic capture facts precede presentation")
	check(shell.world.last_zone=="channel" and spawn==Vector2(1280,680),"formal channel is already at its authored chase checkpoint")
	check(not state.d.qizhenLake.transitionReady and state.d.items.magneticFishingRod,"presentation start has not earned the escape or consumed the rod")
	await frames()
	check(shell.world_viewport.gui_get_focus_owner()==effect,"effect owns actual world viewport focus")
	key(KEY_A); key(KEY_D)
	touch(Vector2(120,400),true); touch(Vector2(120,450),false)
	for i in range(143): effect._process(.05); shell.world._process(.05)
	check(not effect.reported and proof.elapsed==0 and actor.inputs.is_empty() and shell.world.player==spawn,"7.15s shot blocks physical chase time and all paddle inputs")
	check(shell.world.camera==camera and shell.world.zoom==zoom and shell.world.kayak==actor and shell.world.lake_session==proof,"cinematic never replaces or moves formal actor/camera/proof")
	check(shell.world.transition_alpha==0,"underlying channel visual fade finishes while its simulation remains frozen")
	effect._process(.05); effect._process(.05); effect.skip_intro(); effect.cancel()
	check(dismissals==["completed"] and domain_events.is_empty() and lease.status=="dismissed","normal end and repeated callbacks dismiss once without any domain event")
	await frames(3)
	check(not is_instance_valid(completed_rig),"normal presentation completion frees its entire native rig")
	check(not is_instance_valid(shell.world_effect) and shell.world_viewport.gui_get_focus_owner()==shell.world,"one tree exit returns world keyboard focus")
	check(actor.inputs.is_empty() and not shell.world.direct_gestures.has_active() and shell.world.touch_axis==Vector2.ZERO and shell.world.kayak_mouse_gesture.is_empty(),"no held input transfers to the channel")
	for frame in range(600):
		if frame%8==0: key(KEY_A if (frame/8)%2==0 else KEY_D)
		shell.world._process(1.0/60)
		if state.d.qizhenLake.phase=="complete": break
	await frames()
	check(state.d.qizhenLake.phase=="complete" and state.d.runtimeMode=="phone" and state.d.native.page=="c35_recovery","same actual channel strokes still earn original return/interlude")
	check(state.d.qizhenLake.chaseDistance==1000 and state.d.qizhenLake.magneticAttachmentBroken and not state.d.items.magneticFishingRod,"only the formal escape consumes the rod and settles progression")

	# Native skip activates on release; emulated mouse and cancelled touch do not.
	await fixture(); config=capture(); effect=shell.world_effect; lease=config.session
	await frames(); var skip: Vector2=effect.skip_rect().get_center()
	mouse(skip,true,-1); mouse(skip,false,-1)
	check(not effect.reported,"touch-synthesized mouse cannot skip twice")
	touch(skip,true); touch(skip,false,7,true)
	check(not effect.reported,"cancelled finger cannot complete skip")
	touch(skip,true); touch(skip,false)
	check(dismissals==["skipped"] and domain_events.is_empty(),"real viewport touch dismisses presentation exactly once")
	await frames(3); touch(skip,false)
	check(shell.world.kayak.inputs.is_empty() and state.d.qizhenLake.chaseAttempts==1,"skip release and duplicate release cannot paddle or spend an attempt")
	shell._open_world_effect(config); await frames()
	check(not is_instance_valid(shell.world_effect) and lease.status=="dismissed","a consumed presentation lease cannot replay")

	await fixture(true); config=capture(); effect=shell.world_effect
	var reduced_camera: Vector2=effect.camera
	for i in range(25): effect._process(.05)
	check(dismissals==["completed"] and effect.camera==reduced_camera,"reduced motion shows static final pose then dismisses once")
	await frames()
	check(state.d.qizhenLake.phase=="swan_chase" and state.d.qizhenLake.chaseDistance==0,"reduced motion never completes gameplay")

	await fixture(); config=capture(); effect=shell.world_effect
	effect._process(.05)
	var paused_at: float=effect.timeline.elapsed
	touch(effect.skip_rect().get_center(),true)
	effect._notification(Control.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	for i in range(180): effect._process(.05); shell.world._process(.05)
	effect.skip_intro()
	check(dismissals.is_empty() and effect.timeline.elapsed==paused_at and shell.world.lake_session.elapsed==0 and effect.get_meta("blocks_input",false),"focus loss freezes presentation and formal chase/grace while retaining the blocker")
	check(effect.pointer_owners.is_empty() and not shell.world.direct_gestures.has_active() and shell.world.touch_axis==Vector2.ZERO and shell.world.kayak_mouse_gesture.is_empty(),"focus suspension discards all world and presentation gestures")
	effect._notification(Control.NOTIFICATION_WM_WINDOW_FOCUS_IN)
	var focused_reader: Callable=effect.read_state
	effect.read_state=func() -> Dictionary:
		var snapshot: Dictionary=focused_reader.call(); snapshot.native.host.focused=false; return snapshot
	effect._process(.05); shell.world._process(.05)
	check(effect.timeline.elapsed==paused_at and shell.world.lake_session.elapsed==0,"host focused=false also freezes both clocks without an OS notification")
	effect.read_state=focused_reader; effect._process(.05)
	check(effect.timeline.elapsed>paused_at and config.session.status=="playing","focus return resumes same shot and lease")
	touch(effect.skip_rect().get_center(),false)
	check(not effect.reported,"old pre-focus pointer release cannot skip")
	key(KEY_SPACE); await frames()
	check(dismissals==["skipped"] and state.d.qizhenLake.phase=="swan_chase" and shell.world.kayak.inputs.is_empty(),"resumed shot skips once without reverting capture or stale paddle")

	await fixture(); config=capture(); effect=shell.world_effect
	var cancelled_rig: Node2D=effect.kayak_rig
	state.d.qizhenLake.chaseAttempts+=1; effect._process(.05); await frames()
	check(config.session.status=="cancelled" and dismissals==["cancelled"] and state.d.qizhenLake.chaseAttempts==2,"old attempt cannot continue or mutate a newer chase")
	check(not is_instance_valid(cancelled_rig),"cancelled presentation frees its entire native rig")

	await fixture(); config=capture(); effect=shell.world_effect
	state.d=state.d.duplicate(true); effect._process(.05); await frames()
	check(config.session.status=="cancelled" and dismissals==["cancelled"],"equal-valued replacement state invalidates the exact identity lease")

	await fixture(); config=capture(); effect=shell.world_effect
	state.d.qizhenLake.phase="complete"; effect._process(.05); await frames()
	check(config.session.status=="cancelled" and state.d.qizhenLake.phase=="complete","phase changes cancel without overwriting newer progress")

	await fixture(); config=capture(); effect=shell.world_effect
	shell.world.world_key=""; shell.world.refresh_world(); effect._process(.05); await frames()
	check(config.session.status=="cancelled" and shell.world.lake_session.status=="running","world/model rebuild invalidates old presentation without damaging new proof")

	for dimensions: Vector2i in [Vector2i(390,844),Vector2i(844,390),Vector2i(1180,812)]:
		root.size=dimensions
		await fixture(); config=capture(); effect=shell.world_effect; await frames()
		check(shell.world_frame.is_visible_in_tree() and effect.size==shell.world.size and effect.size==Vector2(960,540),"actual compact/landscape shell keeps one 960x540 shot "+str(dimensions))
		check(Rect2(Vector2.ZERO,effect.size).encloses(effect.skip_rect()) and Rect2(Vector2.ZERO,effect.size).encloses(effect.caption.get_rect()),"caption and skip remain inside the shared logical viewport "+str(dimensions))
		check(effect.caption.get_rect().end.x<effect.skip_rect().position.x,"caption does not collide with skip target "+str(dimensions))
		var display_scale: float=float(shell._read_runtime_state().native.host.world_display_scale)
		check(effect.skip_rect().size.y*display_scale>=43 and effect.caption.get_theme_font_size("font_size")*display_scale>=13.5,"compact physical touch target and font remain readable "+str(dimensions))
		key(KEY_SPACE); await frames(3)
		check(dismissals==["skipped"] and shell.world_viewport.gui_get_focus_owner()==shell.world,"keyboard skip returns actual compact/landscape focus "+str(dimensions))
		check(shell.world.kayak.inputs.is_empty(),"keyboard skip never becomes a stale paddle "+str(dimensions))

	# Save occurs at atomic capture, not on animation completion. Reload resumes
	# the original channel checkpoint without resurrecting an unpersisted shot.
	await fixture(); config=capture(); effect=shell.world_effect
	check(state.save_game(),"actual captured state saves before presentation dismissal")
	check(state.load_game(),"actual capture save reloads")
	effect._process(.05); await frames(); shell._refresh(); await frames()
	check(config.session.status=="cancelled" and not is_instance_valid(shell.world_effect),"ordinary reload cancels old lease and never reissues the entrance")
	check(state.d.qizhenLake.phase=="swan_chase" and state.d.qizhenLake.paperCaptured and state.d.qizhenLake.chaseAttempts==1,"reload preserves captured paper and original attempt")
	check(shell.world.last_zone=="channel" and not is_instance_valid(shell.active_game),"reload returns directly to the actual channel")
	var replay: Dictionary=solved.final_result.duplicate(true)
	replay.session_id=state.lake_module().session_counter; replay.spotId="paper"
	state.act("c3_fishing_result",replay); await frames()
	check(not is_instance_valid(shell.world_effect) and state.d.qizhenLake.chaseAttempts==1,"duplicate fishing terminal cannot replay entrance or increment attempt")
	await shell.shutdown(); shell.queue_free(); await frames()
	print("C3_SWAN_ENTRANCE_SHELL: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
