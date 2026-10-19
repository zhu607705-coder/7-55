extends SceneTree
## Real asynchronous Main handoffs. Presenters run on the engine's clock; this
## test never skips them, edits their clocks, or manually calls their _process.+## The default headless seam changes only OS focus. --graphical-real-focus uses
## untouched Main and requires an actual focused graphical window.
const RainModel=preload("res://scripts/media/c3_rain_rescue_model.gd")
const Solver=preload("res://tests/campaign_fishing_solver.gd")
const Fishing=preload("res://scripts/games/rhythm_fishing_model.gd")
var state: Node
var shell: Control
var checks:=0
var failures:=0
var graphical:=false

func _initialize() -> void: run.call_deferred()
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error("LAKE MAIN HANDOFF: "+label)
func frames(count: int=3) -> void:
	for i in count: await process_frame
func key(code: Key) -> void:
	var input:=InputEventKey.new(); input.keycode=code; input.physical_keycode=code; input.pressed=true
	shell.world_viewport.push_input(input,true)
	input=input.duplicate(); input.pressed=false; shell.world_viewport.push_input(input,true)
func held_key(code: Key,pressed: bool) -> void:
	var input:=InputEventKey.new(); input.keycode=code; input.physical_keycode=code; input.pressed=pressed
	Input.parse_input_event(input)
func make_shell() -> void:
	shell=load("res://scenes/main.tscn").instantiate()
	if not graphical: shell.set_script(load("res://tests/fixtures/rain_rescue_focus_shell.gd"))
	root.add_child(shell); root.grab_focus()
	await frames()
	shell._show_world_mobile(); await frames()
	check(shell.world_frame.is_visible_in_tree(),"production shell exposes the fixture's current world")
	if graphical: check(shell.get_window().has_focus(),"untouched Main has actual graphical OS focus")
func close_shell() -> void:
	held_key(KEY_W,false)
	await shell.shutdown(); shell.queue_free(); await frames()
func lake_fixture(phase: String,zone: String,vehicle: String) -> void:
	state.new_game()
	state.developer_mode=false
	var s: Dictionary=state.d
	s.native.merge({"chapter":3,"scene":"qizhen_lake","page":"c3_lake","mode":"light","positions":{}},true)
	s.native.settings.reduced_motion=false
	s.runtimeMode="rpg"; s.rpgScene="qizhen_lake"; s.currentScene="phone_home"
	s.rpgCheckpoint="qizhen_swan_cove" if zone=="swan_cove" else "qizhen_dock"
	# Chapter 3 begins after the real Chapter 2 movement installation. These
	# earlier facts are fixture prerequisites, never earned by the presentation.
	s.actOne.merge({"controlsInstalled":true,"movementEnabled":true,"manualControlTested":true},true)
	s.qizhenLake.merge({"active":true,"phase":phase,"zone":zone,"vehicle":vehicle,"kayakEquipped":true,"leftPaddleEquipped":true,"rightPaddleEquipped":true},true)
	s.ui.controlCenterOpen=false; s.ui.inventoryOpen=false; s.ui.selectedItem=null
func wait_rain_phase(receipt: RefCounted,phase: String,timeout_ms: int) -> bool:
	var deadline:=Time.get_ticks_msec()+timeout_ms
	while receipt.phase()!=phase and Time.get_ticks_msec()<deadline: await create_timer(.02).timeout
	return receipt.phase()==phase

func rain_handoff() -> void:
	lake_fixture("boarding_tutorial","dock","on_foot")
	state.d.qizhenLake.merge({"rainWarningSeen":true,"rainSafetyCleared":false,"rainRescueCompleted":false},true)
	await make_shell()
	shell.world.player=Vector2(690,620); shell.world._sync_player()
	var before_count: int=state.d.qizhenLake.capsizeCount
	var result: Dictionary=state.act("c3_lake_target:qizhen_dock_board")
	check(result.has("world_effect") and is_instance_valid(shell.world_effect),"actual dock intent opens the registered rain presenter")
	if not result.has("world_effect") or not is_instance_valid(shell.world_effect): await close_shell(); return
	var cancelled: RefCounted=result.world_effect.session
	var first: Control=shell.world_effect
	var camera: Vector2=first.old_camera
	var zoom: float=first.old_zoom
	var actor: Vector2=shell.world.player
	await create_timer(1.4).timeout
	key(KEY_D)
	check(cancelled.phase()=="route" and shell.world.player==actor,"natural launch blocks ordinary live-world movement")
	check(shell.world.camera!=camera and shell.world.presentation_actor_hidden,"authored launch actually owns the camera and actor before cancellation")
	shell._cancel_world_effect()
	check(shell.world.camera==camera and shell.world.zoom==zoom and not shell.world.presentation_actor_hidden,"Main cancellation synchronously restores the captured camera, zoom and actor")
	await frames()
	check(cancelled.phase()=="cancelled" and not is_instance_valid(first) and not is_instance_valid(shell.world_effect),"deferred cancellation removes the effect and its native rig")
	check(shell.world_viewport.gui_get_focus_owner()==shell.world and not shell.world._shell_input_blocked(),"cancel returns actual viewport focus and unblocks the world")
	check(not state.d.qizhenLake.rainRescueCompleted and state.d.qizhenLake.capsizeCount==before_count,"cancel leaves rain progression and capsize count unchanged")
	result=state.act("c3_lake_target:qizhen_dock_board")
	check(result.has("world_effect") and is_instance_valid(shell.world_effect),"same board target can immediately re-enter through Main after cancellation")
	if not result.has("world_effect") or not is_instance_valid(shell.world_effect): await close_shell(); return
	var receipt: RefCounted=result.world_effect.session
	var presenter: Control=shell.world_effect
	var rain_rig: Node2D=presenter.visual
	check(receipt!=cancelled and receipt.phase()=="route","re-entry gets a new controller receipt")
	state.act("c3_rain_rescue_result",cancelled)
	check(shell.world_effect==presenter and receipt.phase()=="route" and not state.d.qizhenLake.rainRescueCompleted,"late cancelled receipt cannot dismiss or finish the new run")
	var started:=Time.get_ticks_msec()
	var deadline:=started+28500
	var saw_cinematic:=false
	var saw_hold:=false
	var early_progress:=false
	while Time.get_ticks_msec()<deadline and receipt.phase()!="consumed":
		var phase: String=receipt.phase()
		saw_cinematic=saw_cinematic or phase=="cinematic"
		saw_hold=saw_hold or phase=="rescued"
		if phase not in ["consumed","complete"] and state.d.qizhenLake.rainRescueCompleted: early_progress=true
		await create_timer(.03).timeout
	var elapsed:=Time.get_ticks_msec()-started
	var minimum: float=RainModel.pre_cinematic_ms(false)+RainModel.NATIVE_CINEMATIC_DURATION_MS+RainModel.timing(false).rescueHoldMs
	check(receipt.phase()=="consumed" and receipt.snapshot().outcome=="native" and saw_cinematic and saw_hold,"full natural rain route, native continuation and dock hold settle through the controller without skip")
	check(elapsed>=minimum-80 and not early_progress,"real monotonic duration and dock hold precede progression")
	await frames(5)
	check(state.d.native.scene=="dorm_hub" and state.d.rpgScene=="dorm_hub" and state.d.currentScene=="phone_home" and state.d.native.page=="phone_home","controller returns to the original dorm and phone-home destination")
	check(state.d.qizhenLake.phase=="rain_recovery" and state.d.qizhenLake.weatherAdjustmentRequested and state.d.qizhenLake.capsizeCount==before_count+1,"natural return settles one capsize and the existing weather handoff")
	check(not is_instance_valid(presenter) and not is_instance_valid(rain_rig) and not is_instance_valid(shell.world_effect),"completed rain presenter and native rig leave the real scene tree")
	check(shell.phone.is_visible_in_tree() and not shell.world_frame.is_visible_in_tree() and not shell.mobile_world and shell.world_viewport.gui_disable_input,"Main exposes the intended phone instead of a hidden or still-active lake surface")
	var focus: Control=shell.get_viewport().gui_get_focus_owner()
	check(shell.world_viewport.gui_get_focus_owner()!=shell.world and (focus==null or focus.is_visible_in_tree()),"phone handoff has no keyboard focus trapped on a hidden world/control")
	check(shell.world.scene_id=="dorm_hub" and not shell.world.presentation_actor_hidden and shell.world.can_stand(shell.world.player),"dorm world and visible actor are restored at a legal position")
	check(shell.world.camera.is_finite() and is_equal_approx(shell.world.zoom,1.15),"next scene uses its own camera/zoom after rain cleanup")
	# The PR's 24-second recording includes this stable post-handoff window; the
	# authored natural sequence itself remains 19.600s, never stretched by tests.
	while Time.get_ticks_msec()-started<24000: await create_timer(.05).timeout
	check(shell.phone.is_visible_in_tree() and shell.world.scene_id=="dorm_hub" and not shell.world.presentation_actor_hidden and state.d.qizhenLake.capsizeCount==before_count+1,"late cleanup cannot alter the real dorm/phone state through the complete 24-second observation")
	check(shell.phone_world_return.is_visible_in_tree() and not shell.phone_world_return.disabled,"restored phone offers its ordinary return-to-scene control")
	shell.phone_world_return.pressed.emit(); await frames()
	check(shell.world_frame.is_visible_in_tree() and shell.world_viewport.gui_get_focus_owner()==shell.world,"actual return control restores world visibility and keyboard focus")
	var stand: Vector2=shell.world.player
	held_key(KEY_W,true); await create_timer(.16).timeout; held_key(KEY_W,false); await frames()
	check(shell.world.player.distance_to(stand)>1 and not shell.world.presentation_actor_hidden,"first real held movement input works after the natural return")
	print("RAIN_NATURAL_HANDOFF_MS ",elapsed," observation_ms ",Time.get_ticks_msec()-started)
	await close_shell()

func swan_handoff() -> void:
	lake_fixture("paper_capture","swan_cove","kayak")
	state.d.qizhenLake.merge({"boardingTutorialCompleted":true,"rainSafetyCleared":true,"swanFed":true,"magneticRodCombined":true,"safeSpawnId":"swan_cove_entry"},true)
	state.d.items.magneticFishingRod=true
	state.d.native.positions={"qizhen_lake:swan_cove:kayak":{"x":760,"y":500}}
	await make_shell()
	var solved: RefCounted=Solver.new().solve_fishing("paper")
	check(Fishing.validate_result(solved.final_result,"paper"),"paper-catch precondition uses an existing replay-validated input trace")
	var result: Dictionary=state.act("c3_lake_target:qizhen_final_paper_cast")
	check(result.has("game") and is_instance_valid(shell.active_game),"actual paper cast opens the real fishing host")
	if not is_instance_valid(shell.active_game): await close_shell(); return
	# Resolve only the precondition's verified chart. Its real terminal delay and
	# Main callback create the lease; no entrance/chase result is fabricated.
	var fishing: Control=shell.active_game
	fishing.set_process(false); fishing.begin(); fishing.model=solved; fishing._check_terminal(); fishing.set_process(true)
	var deadline:=Time.get_ticks_msec()+4000
	while not is_instance_valid(shell.world_effect) and Time.get_ticks_msec()<deadline: await create_timer(.02).timeout
	check(is_instance_valid(shell.world_effect) and not is_instance_valid(shell.active_game),"real fishing terminal asynchronously hands the captured paper to the swan presenter")
	if not is_instance_valid(shell.world_effect): await close_shell(); return
	var effect: Control=shell.world_effect
	var lease: RefCounted=effect.session
	var cinematic_rig: Node2D=effect.kayak_rig
	var model: RefCounted=shell.world.kayak
	var proof: RefCounted=shell.world.lake_session
	var spawn: Vector2=shell.world.player
	var camera: Vector2=shell.world.camera
	var zoom: float=shell.world.zoom
	var notices: Array=[]; var domain: Array=[]
	effect.dismissed.connect(func(reason): notices.append(reason))
	effect.event.connect(func(action,value): domain.append([action,value]))
	var started:=Time.get_ticks_msec()
	var entrance_started: float=effect.timeline.elapsed
	var simulation_moved:=false
	deadline=started+12000
	while is_instance_valid(effect) and Time.get_ticks_msec()<deadline:
		if not effect.reported:
			simulation_moved=simulation_moved or proof.elapsed>0 or not model.inputs.is_empty() or shell.world.player!=spawn or shell.world.camera!=camera or shell.world.zoom!=zoom
		await create_timer(.02).timeout
	var elapsed:=Time.get_ticks_msec()-started
	check(not is_instance_valid(effect) and lease.status=="dismissed" and notices==["completed"] and domain.is_empty(),"natural swan end dismisses its lease once without a progression event")
	check(elapsed+entrance_started*1000>=7150 and not simulation_moved,"complete 7.2-second engine-driven shot freezes real channel physics, grace and camera")
	await frames(3)
	check(not is_instance_valid(cinematic_rig) and shell.world.kayak==model and shell.world.lake_session==proof,"cinematic rig retires while the original channel model and proof remain")
	check(shell.world_frame.is_visible_in_tree() and shell.world_viewport.gui_get_focus_owner()==shell.world and not shell.world._shell_input_blocked(),"natural entrance returns Main's actual visible world and keyboard control")
	check(state.d.qizhenLake.phase=="swan_chase" and state.d.qizhenLake.zone=="channel" and state.d.qizhenLake.chaseAttempts==1 and not state.d.qizhenLake.transitionReady and state.d.items.magneticFishingRod,"presentation cannot spend an attempt, earn escape or consume the rod")
	check(shell.world.kayak_visual.active and is_instance_valid(shell.world.kayak_visual.rig) and shell.world.kayak_visual.rig.visible and not shell.world.presentation_actor_hidden,"formal channel kayak rig is visible after cinematic teardown")
	key(KEY_A); await create_timer(.14).timeout; key(KEY_D); await create_timer(.14).timeout
	check(model.inputs.size()==2 and model.inputs[0].side=="left" and model.inputs[1].side=="right" and shell.world.player.distance_to(spawn)>1,"first real A/D strokes move the same native channel actor after natural dismissal")
	check(proof.status=="running" and proof.valid(state.d,shell.world) and shell.world.can_stand(shell.world.player),"resumed channel motion retains the original controller proof and legal hull placement")
	print("SWAN_NATURAL_HANDOFF_MS ",elapsed," initial_timeline_ms ",entrance_started*1000)
	await close_shell()

func run() -> void:
	if not load("res://tests/native_test_isolation.gd").is_isolated_save(): push_error("Isolated native sandbox required"); quit(2); return
	graphical=OS.get_cmdline_user_args().has("--graphical-real-focus")
	if graphical and DisplayServer.get_name()=="headless": push_error("Graphical mode requires actual OS focus"); quit(2); return
	print("LAKE_MAIN_HANDOFF_TEST_SHA256 ",FileAccess.get_sha256("res://tests/test_lake_main_handoffs.gd"))
	state=root.get_node("State"); root.size=Vector2i(1440,900)
	await rain_handoff()
	await swan_handoff()
	print("Lake Main natural handoffs: ",checks," checks; ",failures," failures; mode=","graphical actual focus" if graphical else "headless OS-focus seam")
	quit(1 if failures else 0)
