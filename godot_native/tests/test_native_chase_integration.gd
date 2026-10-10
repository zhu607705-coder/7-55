extends SceneTree
## Integrated native owners with replay-validated fixture proof, not earned play.
const Chase=preload("res://scripts/games/chase_stunt_model.gd")
var checks:=0
var failures:=0
var state: Node
var shell: Control
func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error(message)
func frames(count: int=3) -> void:
	for i: int in range(count):await process_frame
func view_count() -> int:
	return root.find_children("NativeSourceChase3D","SubViewport",true,false).size()+root.find_children("OriginalTransitionViewport","SubViewport",true,false).size()
func fixture() -> Dictionary:
	var d: Dictionary=state.initial()
	d.native.chapter=3;d.native.scene="campus_bootstrap";d.native.page="c3_canteen";d.runtimeMode="rpg";d.rpgScene="campus_bootstrap";d.rpgCheckpoint="campus_canteen_bike"
	d.canteenHunt.active=true;d.canteenHunt.phase="chase_ready";d.canteenHunt.bikePaid=true;d.canteenHunt.bikeLockCleaned=true
	return d
func run() -> void:
	state=root.get_node("State");state.developer_mode=true;state.d=fixture()
	root.size=Vector2i(430,860)
	shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames()
	shell.set_process(false);shell.world.set_process(false)
	var cancelled_result: Dictionary=state.act("c3_chase")
	var loading: Control=shell.active_game
	check(loading.name=="ChaseLoading" and loading.heading.is_visible_in_tree() and view_count()==0,"loading acknowledgement is visible before original3D allocation")
	check(loading.heading.get_theme_color("font_color")==Color("eff4e8"),"loading text retains its readable light role under the phone theme")
	check(not shell.phone.visible and not shell.world_frame.visible,"loading owns the visible scene and blocks the previous Tasks surface")
	var escape:=InputEventKey.new();escape.keycode=KEY_ESCAPE;escape.pressed=true;root.push_input(escape);await frames(4)
	check(not is_instance_valid(shell.active_game) and view_count()==0 and state.d.canteenHunt.phase=="chase_ready","cancelling pending departure cannot reopen or advance it")
	check(shell.world.has_focus() and root.gui_get_focus_owner()==null,"loading cancellation releases root focus and restores the world")
	state.act("c3_chase");var queued_loading: Control=shell.active_game
	await frames(2)
	check(shell.active_game!=queued_loading and queued_loading.is_inside_tree() and shell.active_game.process_mode==Node.PROCESS_MODE_DISABLED,"newly allocated scene cannot consume input queued during loading")
	var pending_view: Control=shell.active_game
	var point: Vector2=queued_loading.leave.get_global_rect().get_center()
	for down: bool in [true,false]:
		var touch:=InputEventScreenTouch.new();touch.index=9;touch.position=point;touch.pressed=down;root.push_input(touch)
	await frames(5)
	check(not is_instance_valid(shell.active_game) and not is_instance_valid(pending_view) and view_count()==0,"queued Return touch cancels loaded scene instead of activating its Start")
	var result: Dictionary=state.act("c3_chase")
	await frames(6)
	var first: Control=shell.active_game;first.manual_clock=true
	check(result.game.departure and state.d.canteenHunt.phase=="chase_ready","departure preserves paid-ready state until completion")
	check(first.ready3d and first.source_nodes.size()>0 and first.source_bones.size()>0,"original transition assets, nodes and skin bindings are loaded")
	check(first.stage=="start" and view_count()==1,"exactly one source departure viewport owns the screen")
	check(not shell.phone.visible and not shell.world_frame.visible,"departure suppresses underlying phone/world input surfaces")
	check(not is_instance_valid(shell.audio_director.music) or not str(shell.audio_director.music.name).begins_with("Music_"),"departure does not start chase music before source handoff")
	first.set_paused(true);var frame: int=first.frame;first.advance(.25)
	check(first.frame==frame,"departure pause freezes authored frame")
	first.cancel();await frames()
	check(shell.world.has_focus() and root.gui_get_focus_owner()==null,"departure Exit restores world keyboard focus")
	check(not is_instance_valid(shell.active_game) and state.d.canteenHunt.phase=="chase_ready","deliberate departure exit retains ready bike without auto-open")
	state.act("c3_chase");await frames(6);var departure: Control=shell.active_game;departure.manual_clock=true
	departure.skip();await frames(8)
	var game: Control=shell.active_game;game.set_process(false)
	check(state.d.canteenHunt.phase=="chasing" and game.get_script().resource_path.ends_with("minigame_host.gd"),"skip hands off once to unchanged ready chase")
	check(not is_instance_valid(departure) and view_count()==1,"departure resources are gone before single ride world is admitted")
	check(is_instance_valid(game.native_chase_view) and game.native_chase_view.ready3d,"host loads original source 3D rider/world")
	check(game.background==null and game.rider==null,"production ride does not use legacy atlas fallback")
	var music: AudioStreamPlayer=shell.audio_director.music
	check(is_instance_valid(music) and music.playing and not music.stream_paused,"source handoff starts the chase music")
	for dims: Vector2i in [Vector2i(390,844),Vector2i(430,860),Vector2i(844,390),Vector2i(1280,800)]:
		root.size=dims;shell.size=Vector2(dims);shell._layout();await frames()
		var screen:=Rect2(Vector2.ZERO,Vector2(dims))
		check(game.size==Vector2(dims) and game.scale==Vector2.ONE,"all chase layouts use physical input coordinates")
		check(game.native_chase_view.size==game.chase_view.size and game.native_chase_view.position==game.chase_view.position,"source film and overlay share one field")
		var resolution: Vector2i=game.native_chase_view.viewport_resolution
		check(resolution.x>=480 and resolution.x<=960 and absf(float(resolution.x)/resolution.y-16.0/9.0)<.005,"source resize limits and camera aspect survive orientation")
		game.begin()
		for button: Button in game.control_buttons.values():
			check(screen.encloses(button.get_global_rect()) and button.size.x>=44 and button.size.y>=44,"readable reachable native control: "+button.text)
			check(not button.get_rect().intersects(game.chase_view.get_rect()),"controls cannot cover source obstacle field")
		game.press_action("jump","test");game._process(.1)
		game.configure_activity_layout(Vector2(dims.y,dims.x),true)
		check(game.model.held.is_empty() and game.model.charge==0,"rotation clears held input without a release jump")
		game.restart()
	game.begin();var reference:=Chase.new();reference.update(.2);game._process(.2)
	check(game.model.tick==reference.tick and is_equal_approx(game.model.distance,reference.distance),"long frame uses the source250ms cap rather than native100ms slowdown")
	var rendered: Control=game.native_chase_view;var tick: int=game.model.tick
	game.toggle_pause();game._process(.25)
	check(game.model.tick==tick and rendered.view_paused,"pause freezes model and presentation with same owner")
	game.restart()
	check(game.native_chase_view==rendered and game.model.tick==0 and not game.running,"Retry resets view and model without duplicate scene")
	game.begin();check(shell.audio_director.music==music and not music.stream_paused,"Retry preserves resumed source music owner")
	game.cancel_game();await frames()
	check(view_count()==0 and not is_instance_valid(shell.active_game),"Exit frees every ride viewport")
	state.act("c3_chase");loading=shell.active_game
	check(loading.name=="ChaseLoading","saved chase reentry first acknowledges its loading state")
	loading.cancelled.emit();await frames()
	check(not is_instance_valid(shell.active_game) and view_count()==0,"cancelling ride admission retires its pending viewport")
	check(not is_instance_valid(shell.audio_director.music),"cancelled ride admission also retires the queued chase audio owner")
	state.act("c3_chase");await frames(6);game=shell.active_game;game.set_process(false)
	check(game.get_script().resource_path.ends_with("minigame_host.gd") and view_count()==1,"saved chasing reentry skips departure and admits one ready owner")
	# The controller validates this checked-in source replay; presenter cannot grant.
	state.developer_mode=false
	check(state.save_game(),"normal save writer is enabled for this integration test")
	var pre_win=JSON.parse_string(FileAccess.get_file_as_string(state.SAVE_PATH))
	check(not pre_win.state.canteenHunt.chaseCompleted and pre_win.state.canteenHunt.phase=="chasing","fresh disk baseline is demonstrably not the expected win")
	var proof: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/chase.json"))
	game.finished.emit(proof)
	check(shell.toast.text.is_empty() and not shell.toast.visible,"accepted success notice is owned by the film caption only")
	check(state.d.canteenHunt.chaseCompleted and state.d.native.positions["campus_bootstrap:"].x==3300.0,"accepted proof saves authored arrival synchronously before film")
	var saved=JSON.parse_string(FileAccess.get_file_as_string(state.SAVE_PATH))
	check(saved.state.canteenHunt.chaseCompleted and saved.state.native.positions["campus_bootstrap:"].y==1360.0,"disk save contains accepted win and source arrival before optional ending")
	game.finished.emit(proof);await frames(8)
	var ending: Control=shell.active_game;ending.manual_clock=true
	check(ending.ready3d and ending.source_nodes.size()>0,"ending loads original scene rather than empty clock")
	check(ending.stage=="finish" and view_count()==1 and not is_instance_valid(game),"validated proof creates one finish film after releasing ride")
	check(state.d.canteenHunt.chaseAttemptCount==1,"duplicate owner callback does not submit proof twice")
	var before: Dictionary=state.d.duplicate(true)
	ending.set_paused(true);ending.skip();await frames()
	check(not is_instance_valid(shell.active_game) and view_count()==0,"paused Skip closes optional ending and restores world")
	check(shell.world.has_focus() and root.gui_get_focus_owner()==null,"arrival Skip restores world keyboard focus")
	check(state.d==before and shell.mobile_world,"film completion never mutates domain state or redirects to phone")
	check(state.load_game() and state.d.native.positions["campus_bootstrap:"].y==1360.0,"ordinary reload retains theater approach")
	await shell.shutdown();shell.queue_free();await frames()
	print("NATIVE_CHASE_INTEGRATION: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
