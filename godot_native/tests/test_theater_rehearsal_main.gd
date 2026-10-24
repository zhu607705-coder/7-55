extends SceneTree
## Explicit, validated c3-theater-program checkpoint and source stand placement.
## This exercises real Main/input/controllers, not earned ticket/story traversal.
## All completion traces below come from real keys/finger events in the view.
const Chapter=preload("res://scripts/chapters/chapter3.gd")
const Model=preload("res://scripts/games/theater_shadow_rehearsal_model.gd")
var state: Node
var shell: Control
var checks:=0
var failures:=0
var starts:=0
var changes:=0
var accepted_results: Array=[]

func _initialize() -> void:run.call_deferred()
func check(ok: bool,label: String) -> bool:
	checks+=1
	if not ok:failures+=1;push_error("THEATER_REHEARSAL_MAIN: "+label)
	return ok
func frames(count: int=3) -> void:
	for i in count:await process_frame
func tap_key(code: int,world_input: bool=false) -> void:
	for pressed: bool in [true,false]:
		var event=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=pressed
		if world_input:shell.world_viewport.push_input(event,true)
		else:root.push_input(event,true)
		await frames(1)
func repeat_key(code: int,count: int) -> void:
	for i in count:await tap_key(code)
func click(button: Button) -> void:
	var rect=Rect2(button.get_global_transform_with_canvas().origin,button.size*button.get_global_transform_with_canvas().get_scale())
	if not check(button.is_visible_in_tree() and not button.disabled and Rect2(Vector2.ZERO,Vector2(root.size)).encloses(rect),"Actual action is visible in native viewport: "+button.name):
		print("REHEARSAL_BUTTON_DIAGNOSTIC ",button.name," rect=",rect," root=",root.size," parent=",button.get_parent().size," game=",shell.active_game.size," panel=",shell.active_game.help_panel.size)
		return
	for pressed: bool in [true,false]:
		var event=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.position=rect.get_center();event.global_position=event.position;event.pressed=pressed
		root.push_input(event,true);await frames(2)
func touch(index: int,position: Vector2,pressed: bool) -> void:
	var event=InputEventScreenTouch.new();event.index=index;event.position=position;event.pressed=pressed;root.push_input(event,true);await frames(1)
func touch_button(button: Button) -> void:
	var rect:=button.get_global_rect()
	if not check(button.is_visible_in_tree() and not button.disabled and Rect2(Vector2.ZERO,Vector2(root.size)).encloses(rect),"Actual paper action is reachable by finger: "+button.name):return
	await touch(8,rect.get_center(),true);await touch(8,rect.get_center(),false);await frames(2)
func lamp(game: Control,use_touch:bool=true) -> void:
	var local: Vector2=game.field.position+game.lamp_rect().get_center()/game.LOGICAL*game.field.size
	var point: Vector2=game.get_global_transform_with_canvas()*local
	await pointer(point,true,use_touch);await pointer(point,false,use_touch);await frames(2)
func trial(game: Control,use_touch: bool) -> void:
	await lamp(game,use_touch)
func next_stage(game: Control,use_touch: bool) -> void:
	await lamp(game,use_touch)
func pointer(point:Vector2,down:bool,use_touch:bool)->void:
	if use_touch:await touch(8,point,down);return
	var input:=InputEventMouseButton.new();input.button_index=MOUSE_BUTTON_LEFT;input.position=point;input.global_position=point;input.pressed=down;root.push_input(input,true);await frames(1)
func pointer_motion(point:Vector2,use_touch:bool)->void:
	if use_touch:await finger_motion(8,point);return
	var input:=InputEventMouseMotion.new();input.position=point;input.global_position=point;input.button_mask=MOUSE_BUTTON_MASK_LEFT;root.push_input(input,true);await frames(1)
func fold(game:Control,id:String,value:float,use_touch:bool)->void:
	var object:Dictionary={}
	for candidate:Dictionary in game.state.objects:
		if candidate.id==id:object=candidate.duplicate(true)
	var start:Vector2=game.FanView.grip(game.prop_foot(object),object);object.spread=value
	var end:Vector2=game.FanView.grip(game.prop_foot(object),object)
	var transform:Transform2D=game.get_global_transform_with_canvas()
	await pointer(transform*(game.field.position+start/game.LOGICAL*game.field.size),true,use_touch)
	for i:int in range(1,9):await pointer_motion(transform*(game.field.position+start.lerp(end,float(i)/8)/game.LOGICAL*game.field.size),use_touch)
	await pointer(transform*(game.field.position+end/game.LOGICAL*game.field.size),false,use_touch)
	for candidate:Dictionary in game.state.objects:
		if candidate.id==id:check(absf(float(candidate.spread)-value)<.02,"Physical copper grip opens the actual fan: "+id)
func move_lamp(game:Control,value:float,use_touch:bool)->void:
	var start:Vector2=game.field.position+game.lamp_rect().get_center()/game.LOGICAL*game.field.size
	var end:Vector2=start+Vector2((value-float(game.state.lampX))*56,0)/game.LOGICAL*game.field.size
	var transform:Transform2D=game.get_global_transform_with_canvas()
	await pointer(transform*start,true,use_touch)
	for i:int in range(1,9):await pointer_motion(transform*start.lerp(end,float(i)/8),use_touch)
	await pointer(transform*end,false,use_touch)
	check(absf(float(game.state.lampX)-value)<.02,"Real lamp drag moves the shared source without submitting a trial")
func object_point(game: Control,id: String="left_fan") -> Vector2:
	for object:Dictionary in game.state.objects:
		if object.id==id:return game.get_global_transform_with_canvas()*(game.field.position+game.prop_rect(object).get_center()/game.LOGICAL*game.field.size)
	return Vector2.ZERO
func finger_motion(index: int,position: Vector2) -> void:
	var event=InputEventScreenDrag.new();event.index=index;event.position=position;root.push_input(event,true);await frames(1)
func menu_gesture(game: Control) -> void:
	var first:Vector2=game.get_global_transform_with_canvas()*(game.field.position+Vector2(20,20))
	await touch(1,first,true);await touch(2,first+Vector2(50,0),true);await create_timer(.68).timeout
	await touch(1,first,false);await touch(2,first+Vector2(50,0),false);await frames(2)
func touch_lifecycle(game: Control) -> void:
	var initial:float=float(game.state.objects[0].x)
	await finger_drag(game,"left_fan",Vector2(-1.1,5))
	var first:Vector2=game.get_global_transform_with_canvas()*(game.field.position+Vector2(20,20))
	await touch(1,first,true);await touch(2,first+Vector2(50,0),true);await touch(1,first,false);await touch(2,first+Vector2(50,0),false)
	check(is_equal_approx(float(game.state.objects[0].x),initial),"Real two-finger tap restores one complete prop drag")
	var point:Vector2=object_point(game)
	await touch(6,point,true);await create_timer(.68).timeout;await touch(6,point,false)
	check(game.help_open and game.state.hintTier==1,"Real prop hold requests one observation layer without moving it")
	await touch_button(game.help_close)
	await menu_gesture(game)
	check(game.menu_open and game.menu_panel.is_visible_in_tree(),"Real two-finger hold exposes the paper rehearsal menu")
	var before:Dictionary=game.model.snapshot();point=object_point(game)
	await touch(6,point,true);await finger_motion(6,Vector2(12,30));await touch(6,Vector2(12,30),false)
	check(game.model.snapshot()==before and game.menu_open,"Paper menu occludes the real prop drag beneath it")
	await touch_button(game.menu_controls.RehearsalMenuPause)
	check(game.paused and game.menu_open,"Real paper Pause freezes the activity")
	await touch_button(game.menu_controls.RehearsalMenuClose)
	check(not game.paused and not game.menu_open,"Real paper Return explicitly resumes the stage")
	point=object_point(game);await touch(6,point,true);await finger_motion(6,point+Vector2(20,0));before=game.model.snapshot()
	root.size=Vector2i(900,430);await frames(6);await finger_motion(6,point+Vector2(60,0));await touch(6,point+Vector2(60,0),false)
	check(game.model.snapshot()==before and game.fingers.is_empty() and game.drag_id.is_empty(),"Actual Main resize cancels the previous physical touch owner")
	root.size=Vector2i(844,390);await frames(6)
	point=object_point(game);await touch(6,point,true);await finger_motion(6,point+Vector2(20,0));before=game.model.snapshot()
	var cancel:=InputEventScreenTouch.new();cancel.index=6;cancel.position=point+Vector2(20,0);cancel.pressed=false;cancel.canceled=true;root.push_input(cancel,true);await frames(2)
	await finger_motion(6,point+Vector2(70,0));check(game.model.snapshot()==before and game.fingers.is_empty(),"Native touch cancellation preserves pose and rejects stale continuation")
	point=object_point(game);await touch(6,point,true);before=game.model.snapshot();root.focus_exited.emit();await frames(2)
	await finger_motion(6,point+Vector2(40,0));await touch(6,point+Vector2(40,0),false)
	check(game.paused and game.menu_open and game.model.snapshot()==before and game.fingers.is_empty(),"Window focus loss freezes the real Main activity and exposes explicit resume")
	await touch_button(game.menu_controls.RehearsalMenuClose)
func touch_orientation(game: Control) -> void:
	await touch(9,Vector2(2,2),true);await touch(9,Vector2(2,2),false);await frames(3)
	await touch_button(game.help_close)
	check(game.geometry_snapshot().rotationRequired and game.rotation_label.visible and game.controls.RehearsalExit.visible,"Portrait phone keeps a discoverable rotate message and Return action")
	check(not game.help_open and game.model.actions.is_empty(),"Real touch introduction starts without answer or progression actions")
	var before:Dictionary=game.model.snapshot();var point:Vector2=object_point(game)
	await touch(6,point,true);await finger_motion(6,point+Vector2(25,0));await touch(6,point+Vector2(25,0),false)
	check(game.model.snapshot()==before,"Portrait fallback does not run tiny off-axis prop controls")
	root.size=Vector2i(844,390);await frames(7)
	check(game.touch_landscape() and game.field.size.x>640 and absf(game.field.size.x/game.field.size.y-16.0/9)<.001,"Main rotation preserves one wide uniform Godot stage")
	check(game.controls.values().all(func(button:Button)->bool:return not button.visible),"Mobile landscape shows no permanent controller buttons")
func finger_drag(game: Control,id: String,destination: Vector2) -> void:
	var object: Dictionary={}
	for candidate: Dictionary in game.state.objects:
		if candidate.id==id:object=candidate;break
	if not check(not object.is_empty(),"Real stage contains draggable "+id):return
	var start_local: Vector2=game.field.position+game.prop_rect(object).get_center()/game.LOGICAL*game.field.size
	var delta_world=Vector2((destination.x-float(object.x))*56,-(destination.y-float(object.depth))*22)
	var end_local: Vector2=start_local+delta_world/game.LOGICAL*game.field.size
	var transform: Transform2D=game.get_global_transform_with_canvas()
	var start: Vector2=transform*start_local;var end: Vector2=transform*end_local
	await touch(6,start,true)
	for i in range(1,9):
		var event=InputEventScreenDrag.new();event.index=6;event.position=start.lerp(end,float(i)/8);root.push_input(event,true);await frames(1)
	await touch(6,end,false)
	var after: Dictionary={}
	for candidate: Dictionary in game.state.objects:
		if candidate.id==id:after=candidate;break
	check(not after.is_empty() and Vector2(float(after.x),float(after.depth)).distance_to(destination)<.01,"Real finger positions "+id+" through the same continuous projection")
func close_shell() -> void:
	if is_instance_valid(shell):await shell.shutdown();shell.queue_free();await frames(4)
func controller() -> RefCounted:
	for module: RefCounted in state.modules:
		if module.has_method("cancel_rehearsal_session"):return module
	return null
func bytes() -> Dictionary:
	return {"primary":FileAccess.get_file_as_string(state.SAVE_PATH),"backup":FileAccess.get_file_as_string(state.BACKUP_PATH) if FileAccess.file_exists(state.BACKUP_PATH) else ""}
func assert_unchanged(before: Dictionary,durable: Dictionary,label: String) -> void:
	check(state.d==before,label+" preserves every native/source game-state field")
	check(bytes()==durable,label+" preserves primary and previous-save bytes")
func mount(view: Vector2i) -> void:
	root.size=view;shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);shell._refresh();await frames(7)
	for i in 160:
		if shell.world.transition_alpha<=0:break
		await process_frame
	check(shell.world_frame.is_visible_in_tree() and state.d.runtimeMode=="rpg" and shell.world.scene_id=="theater_interior","Real production Main mounts the retained theater surface")
func place_at_rack() -> Dictionary:
	var target: Dictionary={}
	for entry: Dictionary in state.get_targets("theater_interior"):
		if entry.id==Model.PUZZLE_ID:target=entry;break
	if not check(not target.is_empty() and target.action=="c3_rehearsal_begin","Shared world target exposes ordinary side-wing rehearsal intent"):return {}
	var stand=Vector2(float(target.stand.x),float(target.stand.y))
	check(stand.is_equal_approx(Vector2(560,206)) and shell.world.can_stand(stand),"Explicit source stand has a real clear player foot box")
	shell.world.player=stand;shell.world._sync_player();shell.world._update_camera();shell.world.grab_focus();await frames(5)
	check(shell.world.nearby.get("id","")==Model.PUZZLE_ID and shell.world._distance(target)<=target.radius,"Actual nearest interactable and controller distance agree at the visible rack")
	return target
func prepare(view: Vector2i) -> Dictionary:
	await close_shell();state.developer_mode=true
	check(state.begin_checkpoint("c3-theater-program"),"Explicit original post-admission source checkpoint exists")
	state.d.runtimeMode="rpg";state.d.native.positions={};state.d.native.mode="light";state.d.theaterHunt.mode="light"
	state.d.ui.controlCenterOpen=false;state.d.ui.inventoryOpen=false;state.d.native.selected_item="";state.d.ui.selectedItem=null
	state.d.native.settings.music=false;state.d.native.settings.effects=false
	state.developer_mode=false
	await mount(view);var target: Dictionary=await place_at_rack()
	check(state.validate_snapshot(state.d) and state.save_game(),"Explicit source/position setup passes ordinary portable-save validation")
	var output: String=OS.get_environment("THEATER_REHEARSAL_CAPTURE_DIR")
	if not output.is_empty():
		DirAccess.make_dir_recursive_absolute(output)
		check(state.export_save(output.path_join("before_theater_rehearsal.json"))==OK,"Export ordinary validated source fixture before any rehearsal")
	return target
func open_rack() -> Control:
	var before: int=starts
	shell.world.grab_focus();await tap_key(KEY_SPACE,true);await frames(5)
	var game: Control=shell.active_game
	if not check(is_instance_valid(game) and game.config.get("kind","")==Model.PUZZLE_ID and starts==before+1,"Ordinary world Space opens exactly one controller-issued rehearsal"):return null
	check(shell.modal==null and shell.world_effect==null and game.help_open and game.help_close.text=="开始排练","Actual intro owns the activity; no old form or parallel overlay")
	return game
func start_intro(game: Control) -> void:
	await click(game.help_close)
	check(not game.help_open and game.model.actions.is_empty(),"Actual intro button begins with clean local input trace")
func play(game: Control,use_touch: bool=false) -> Dictionary:
	if use_touch:await touch_orientation(game);await touch_lifecycle(game)
	else:await start_intro(game)
	await trial(game,use_touch)
	check(game.state.screen=="playing" and game.state.completedRounds==0 and game.state.failure=="shadow_position","Wrong trial retains the current physical scene for recovery")
	if use_touch:await finger_drag(game,"left_fan",Vector2(0,5))
	else:await repeat_key(KEY_RIGHT,17)
	await trial(game,use_touch);check(game.state.failure=="fan_opening","First fan requires observation of opening after its center is aligned")
	await fold(game,"left_fan",1.0,use_touch)
	await trial(game,use_touch)
	if not check(game.state.screen=="round_complete" and game.state.completedRounds==1,"Ordinary first-scene manipulation earns its actual shadow alignment"):return {}
	await next_stage(game,use_touch)
	if use_touch:await finger_drag(game,"left_fan",Vector2(0,6))
	else:await repeat_key(KEY_UP,25)
	await fold(game,"left_fan",.65,use_touch)
	await trial(game,use_touch)
	if not check(game.state.screen=="round_complete" and game.state.completedRounds==2,"Ordinary depth movement earns the second actual projection"):return {}
	await next_stage(game,use_touch)
	await move_lamp(game,.6,use_touch)
	if use_touch:
		await finger_drag(game,"side_screen",Vector2(4.4,8));await finger_drag(game,"left_fan",Vector2(.36,4));await finger_drag(game,"right_fan",Vector2(.24,6))
	else:
		await tap_key(KEY_TAB);await repeat_key(KEY_RIGHT,18);await tap_key(KEY_TAB);await repeat_key(KEY_LEFT,13);await repeat_key(KEY_UP,17);await tap_key(KEY_TAB);await repeat_key(KEY_RIGHT,37)
	await fold(game,"left_fan",1.0,use_touch);await fold(game,"right_fan",.7,use_touch)
	await trial(game,use_touch)
	if not check(game.state.screen=="complete" and game.state.completedRounds==3,"Ordinary prop input composes both wings and removes the physical obstruction"):return {}
	var proof: Dictionary=game.model.proof(game.config.session)
	check(not Model.replay(proof).is_empty(),"Only the view's fully played trace is used for lifecycle validation")
	return proof
func returned(point: Vector2) -> void:
	await frames(6)
	check(not is_instance_valid(shell.active_game) and shell.world_frame.is_visible_in_tree(),"Rehearsal returns to the actual theater at "+str(root.size))
	check(shell.world.player.is_equal_approx(point) and shell.world.can_stand(point),"Return retains the original legal source position")
	check(shell.world_viewport.gui_get_focus_owner()==shell.world and not shell.world._shell_input_blocked(),"Return restores ordinary world keyboard focus and input")
func exercise(view: Vector2i,use_touch: bool=false) -> Dictionary:
	if (await prepare(view)).is_empty():return {}
	var point: Vector2=shell.world.player;var before: Dictionary=state.d.duplicate(true);var durable: Dictionary=bytes();var change_count: int=changes
	var game: Control=await open_rack()
	if not is_instance_valid(game):return {}
	assert_unchanged(before,durable,"Physical rehearsal entry")
	var proof: Dictionary=await play(game,use_touch)
	if proof.is_empty():return {}
	check(state.d==before and bytes()==durable,"All actual three-scene inputs remain runtime-only before handoff")
	await trial(game,use_touch);await returned(point)
	check(not accepted_results.is_empty() and accepted_results[-1].get("rehearsalAccepted",false),"Actual final native button submits one accepted replay")
	assert_unchanged(before,durable,"Accepted optional rehearsal")
	check(changes==change_count,"Entry and successful optional result emit no persistence/state-changed event")
	game=await open_rack()
	if not is_instance_valid(game):return proof
	check(game.config.session!=proof.session,"Ordinary replay issues a new runtime nonce")
	var current: Dictionary=game.config.session.duplicate(true)
	var rejected: Dictionary=state.act("c3_rehearsal_result",proof)
	check(not rejected.get("rehearsalAccepted",false) and controller().rehearsal_session.token==current,"Previous actual completion cannot finish or retire the replay")
	if use_touch:
		await touch_button(game.help_close);await menu_gesture(game);await touch_button(game.menu_controls.RehearsalMenuExit)
	else:await click(game.controls.RehearsalExit)
	await returned(point)
	assert_unchanged(before,durable,"Replayed intro cancellation")
	check(changes==change_count,"Rejected old result and replay Exit remain ephemeral")
	await close_shell();return proof
func lifecycle() -> void:
	if (await prepare(Vector2i(1280,720))).is_empty():return
	var point: Vector2=shell.world.player
	var game: Control=await open_rack()
	if not is_instance_valid(game):return
	var shutdown_proof: Dictionary=await play(game)
	if shutdown_proof.is_empty():return
	var before: Dictionary=state.d.duplicate(true);var durable: Dictionary=bytes()
	await close_shell()
	var rejected: Dictionary=state.act("c3_rehearsal_result",shutdown_proof)
	check(not rejected.get("rehearsalAccepted",false),"Main shutdown permanently retires a fully played pending nonce")
	assert_unchanged(before,durable,"Shutdown and late actual replay")
	state.d=state.initial();check(state.load_game(),"Ordinary Continue loads the unchanged source checkpoint")
	await mount(Vector2i(1280,720));check(shell.active_game==null and shell.modal==null,"Continue contains no partial or completed runtime-only rehearsal")
	await place_at_rack();game=await open_rack()
	if not is_instance_valid(game):return
	var mode_proof: Dictionary=await play(game)
	if mode_proof.is_empty():return
	state.toggle_mode();state.toggle_mode();await frames(4)
	before=state.d.duplicate(true);durable=bytes()
	rejected=state.act("c3_rehearsal_result",mode_proof)
	check(not rejected.get("rehearsalAccepted",false),"Actual mode invalidation cannot revive a fully played old nonce after light returns")
	assert_unchanged(before,durable,"Late actual replay after mode boundary")
	await close_shell()
func replacement_and_story_lock() -> void:
	if (await prepare(Vector2i(1180,812))).is_empty():return
	var game: Control=await open_rack()
	if not is_instance_valid(game):return
	var old: Dictionary=game.config.session.duplicate(true)
	var before: Dictionary=state.d.duplicate(true);var durable: Dictionary=bytes()
	var issued: Dictionary=state.act("c3_rehearsal_begin");await frames(5)
	var next: Control=shell.active_game
	if not check(issued.has("game") and is_instance_valid(next) and next!=game,"A normal second intent issues a fresh nonce before old-view disposal"):return
	check(controller().rehearsal_session.token==issued.game.session and next.config.session==issued.game.session,"Old exact Main disposal preserves the already-issued fresh nonce")
	assert_unchanged(before,durable,"Main activity replacement")
	controller().tell_lines(state.d,"rehearsal-cancel-lock-fixture",["只读叙事锁测试。"])
	check(state.story_input_locked(),"A concurrent runtime-only narrative actually holds the ordinary intent lock")
	before=state.d.duplicate(true);durable=bytes()
	check(not state.cancel_progressive_activity("c3_rehearsal_cancel",{"session":old}),"Under story lock, stale exact cancellation cannot kill the fresh nonce")
	check(controller().rehearsal_session.token==issued.game.session,"The fresh nonce survives stale cleanup while interaction is locked")
	check(not state.cancel_progressive_activity("c3_rehearsal_result",{"session":issued.game.session}),"Cancellation API cannot dispatch a completion intent")
	await click(next.controls.RehearsalExit);await frames(4)
	check(shell.active_game==null and controller().rehearsal_session==null,"Actual Exit precisely cancels the live nonce during story lock")
	assert_unchanged(before,durable,"Exact cancellation under narrative lock")
	controller().story.cancel();controller().story=null;controller().story_request={};await frames(3)
	await close_shell()

func caption_owner() -> void:
	if (await prepare(Vector2i(1280,720))).is_empty():return
	var point:Vector2=shell.world.player
	var game:Control=await open_rack()
	if not is_instance_valid(game):return
	var before:Dictionary=state.d.duplicate(true);var durable:Dictionary=bytes()
	shell.story_caption_line.text="灯下仍留着上一句旁白。";shell.story_caption_line.speaker="旁白";shell.story_caption_time=10.0;shell.story_caption_surface="world"
	shell.world.subtitle=shell.story_caption_line.text;shell.world.subtitle_left=10.0
	var remaining:float=shell.story_caption_time;shell._layout_story_caption()
	check(not shell.story_caption.visible and shell.story_caption.session==null and shell.world.subtitle.is_empty(),"Active rehearsal retires only the matching old world/window subtitle")
	check(shell.story_caption_time==remaining and shell.story_caption_line.text=="灯下仍留着上一句旁白。","Exclusive stage ownership preserves the still-live original line and clock")
	await click(game.controls.RehearsalWatch)
	if not check(is_instance_valid(game.performance),"Actual Main optional performance opens within the rehearsal owner"):return
	game.performance.set_process(false);remaining=shell.story_caption_time;shell._layout_story_caption()
	check(not shell.story_caption.visible and shell.story_caption.session==null and shell.story_caption_time==remaining,"Performance subtitles never gain a parallel system-window caption")
	check(game._hud_nodes().all(func(node:Control)->bool:return not node.visible),"Actual Main performance hides original local task and control surfaces")
	await click(game.performance.return_button);await frames()
	check(game.help_open and game.help_panel.visible and game.stage_hud.visible,"Closing the child restores the exact original reading and stage HUD")
	await click(game.controls.RehearsalExit);await returned(point)
	shell._layout_story_caption()
	check(shell.story_caption_surface=="world" and shell.world.subtitle==shell.story_caption_line.text,"Ordinary world caption ownership resumes after the activity closes")
	shell.mobile_world=false;shell._layout();shell._layout_story_caption()
	check(shell.story_caption.visible and shell.story_caption.session==shell.story_caption_line,"Other phone/window caption owners remain usable outside this rehearsal")
	shell.story_caption_time=0;shell._layout_story_caption();shell.mobile_world=true;shell._layout()
	assert_unchanged(before,durable,"Caption-owner and optional-view handoffs")
	await close_shell()
func run() -> void:
	if not load("res://tests/native_test_isolation.gd").is_isolated_save():push_error("Rehearsal Main acceptance requires isolated saves");quit(2);return
	state=root.get_node("State")
	state.game_requested.connect(func(config: Dictionary):
		if config.get("kind","")==Model.PUZZLE_ID:starts+=1
	)
	state.changed.connect(func():changes+=1)
	state.action_completed.connect(func(action: String,_previous: Dictionary,_next: Dictionary,result: Dictionary):
		if action=="c3_rehearsal_result":accepted_results.append(result.duplicate(true))
	)
	create_timer(180).timeout.connect(func():push_error("Theater rehearsal Main acceptance watchdog");quit(2))
	if "--caption-only" in OS.get_cmdline_user_args():
		await caption_owner()
		print("THEATER_REHEARSAL_MAIN: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0);return
	await exercise(Vector2i(1440,900))
	await exercise(Vector2i(390,844),true)
	await caption_owner()
	await lifecycle()
	await replacement_and_story_lock()
	print("THEATER_REHEARSAL_MAIN: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
