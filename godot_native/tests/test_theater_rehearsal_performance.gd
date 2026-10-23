extends SceneTree
const View=preload("res://scripts/games/theater_shadow_rehearsal.gd")
const Proof=preload("res://tests/helpers/theater_rehearsal_proof.gd")
var checks:=0
var failures:=0
var state:Node
var results:Array[Dictionary]=[]
var cancellations:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error("REHEARSAL_PERFORMANCE: "+label)
func frames(count:int=3)->void:
	for i in count:await process_frame
func texture(size2:Vector2i,color:Color)->Texture2D:
	var image:=Image.create(size2.x,size2.y,false,Image.FORMAT_RGBA8);image.fill(color);return ImageTexture.create_from_image(image)
func durable()->Dictionary:
	return {"primary":FileAccess.get_file_as_string(state.SAVE_PATH) if FileAccess.file_exists(state.SAVE_PATH) else "","backup":FileAccess.get_file_as_string(state.BACKUP_PATH) if FileAccess.file_exists(state.BACKUP_PATH) else ""}
func click(button:Button)->void:
	check(button.is_visible_in_tree() and not button.disabled and Rect2(Vector2.ZERO,Vector2(root.size)).encloses(button.get_global_rect()),"Real visible action is inside the viewport: "+button.name)
	var point:Vector2=button.get_global_rect().get_center()
	for down:bool in [true,false]:
		var input:=InputEventMouseButton.new();input.button_index=MOUSE_BUTTON_LEFT;input.position=point;input.global_position=point;input.pressed=down;root.push_input(input,true);await frames(2)
func touch_button(button:Button)->void:
	check(button.is_visible_in_tree() and button.size.y>=44 and Rect2(Vector2.ZERO,Vector2(root.size)).encloses(button.get_global_rect()),"Real finger action is visible and has44px target: "+button.name)
	var point:Vector2=button.get_global_rect().get_center()
	for down:bool in [true,false]:
		var input:=InputEventScreenTouch.new();input.index=7;input.position=point;input.pressed=down;root.push_input(input,true);await frames(2)
func key(code:Key)->void:
	for down:bool in [true,false]:
		var input:=InputEventKey.new();input.keycode=code;input.physical_keycode=code;input.pressed=down;root.push_input(input,true);await frames(1)
func game_config()->Dictionary:
	state.developer_mode=true;check(state.begin_checkpoint("c3-theater-program"),"Original post-admission checkpoint is available");state.developer_mode=false
	state.d.runtimeMode="rpg";state.d.native.player={"scene":"theater_interior","x":560,"y":206};state.d.native.mode="light";state.d.theaterHunt.mode="light";state.d.ui.controlCenterOpen=false
	var response:Dictionary=state.act("c3_rehearsal_begin")
	check(response.has("game") and response.game.has("session"),"Existing controller issues the unchanged rehearsal capability")
	var config:Dictionary=response.get("game",{});config.performance_assets={"stage":texture(Vector2i(1200,675),Color("70503B")),"actors":texture(Vector2i(480,320),Color("385B79")),"table":texture(Vector2i(160,100),Color("70503B")),"chair_left":texture(Vector2i(60,120),Color("70503B")),"chair_right":texture(Vector2i(60,120),Color("70503B"))}
	return config
func run()->void:
	root.size=Vector2i(1280,720);state=root.get_node("State")
	var config:Dictionary=game_config();var view=View.new();view.setup(config);root.add_child(view);view.configure_activity_layout(Vector2(root.size),false);await frames()
	view.completed.connect(func(proof:Dictionary):results.append(state.act("c3_rehearsal_result",proof)))
	view.cancelled.connect(func():cancellations+=1)
	await click(view.help_close);await key(KEY_RIGHT)
	var pose:Dictionary=view.model.snapshot();var before:Dictionary=state.d.duplicate(true);var saved:Dictionary=durable();var nonce:String=str(config.session.nonce)
	await click(view.controls.RehearsalWatch)
	check(is_instance_valid(view.performance) and view.performance.assets_ready,"Ordinary toolbar Watch opens a child of the same rehearsal owner")
	check(view._hud_nodes().all(func(node:Control)->bool:return not node.visible),"Watching actually hides every old rehearsal task, control and reading surface")
	var film:Control=view.performance;film.set_process(false)
	await key(KEY_RIGHT);await key(KEY_ENTER)
	check(view.model.snapshot()==pose and view.config.session.nonce==nonce,"Presentation input cannot move props, try a solution or replace the issued nonce")
	film.resume();film.tick(.1,true);await click(film.return_button);await frames()
	check(not is_instance_valid(view.performance) and view.model.snapshot()==pose and not view.paused,"Return restores the exact playable prop pose and round")
	check(view.stage_hud.visible and view.controls.RehearsalWatch.visible and not view.help_panel.visible,"Return restores the exact ordinary rehearsal HUD visibility")
	check(results.is_empty() and cancellations==0 and state.d==before and durable()==saved,"Watching and skipping submit no rehearsal proof or persistent fact")
	await key(KEY_V);check(is_instance_valid(view.performance),"KeyboardV opens the same optional viewer without a mouse")
	await key(KEY_ESCAPE);await frames();check(not is_instance_valid(view.performance) and view.model.snapshot()==pose,"ViewerEsc returns through the same no-proof boundary")
	view.coarse=true;view.touch_seen=true;view.configure_activity_layout(Vector2(390,844),true);root.size=Vector2i(390,844);await frames()
	pose=view.model.snapshot();await touch_button(view.controls.RehearsalWatch)
	check(is_instance_valid(view.performance) and absf(view.performance.field.size.x/view.performance.field.size.y-16.0/9)<.001,"Portrait finger Watch opens the complete uncut stage before rotating or solving")
	film=view.performance;film.set_process(false);await touch_button(film.return_button);await frames()
	check(not is_instance_valid(view.performance) and view.rotation_label.visible and view.model.snapshot()==pose and state.d==before and durable()==saved,"Portrait finger Return restores the exact pose and original rotation guidance without proof")
	view.configure_activity_layout(Vector2(844,390),false);root.size=Vector2i(844,390);await frames()
	view._open_menu();await frames();view._menu_pause();await frames();pose=view.model.snapshot()
	await touch_button(view.menu_controls.RehearsalMenuWatch)
	check(is_instance_valid(view.performance) and view.performance.return_button.size.y>=44,"Temporary mobile paper menu exposes the same optional Watch")
	film=view.performance;film.set_process(false);await click(film.return_button);await frames()
	check(view.paused and view.menu_open and view.menu_panel.visible and view.model.snapshot()==pose,"Return preserves the original paused paper menu rather than resuming it")
	check(results.is_empty() and state.d==before and durable()==saved,"Mobile Watch is also non-authoritative")
	view._close_menu();view.coarse=false;view.touch_seen=false;view.configure_activity_layout(Vector2(1280,720),false);root.size=Vector2i(1280,720);await frames()
	for beat in 3:
		check(Proof.solve_round(view.model),"Original puzzle still solves through its unchanged physical model")
		view._refresh()
		if beat<2:view._continue_stage()
	view._try_stage();check(results.size()==1 and results[0].get("rehearsalAccepted",false),"Only the original final action still submits one accepted controller replay")
	check(state.d==before and durable()==saved,"The accepted existing optional puzzle retains its original no-save semantics")
	view.queue_free();await frames();results.clear();config=game_config();view=View.new();view.setup(config);root.add_child(view);view.configure_activity_layout(Vector2(root.size),false);await frames();await click(view.help_close);await click(view.controls.RehearsalWatch)
	film=view.performance;film.set_process(false);view.dispose_presentation();await frames()
	check(not is_instance_valid(view.performance) and view.disposed and results.is_empty(),"Host shutdown disposes the child before any late presentation callback")
	view.queue_free();await frames()
	print("REHEARSAL_PERFORMANCE: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
