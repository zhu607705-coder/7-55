extends SceneTree
## Routed Main input plus the real original ChapterThree exit controller.
## Completed-theater fixtures are explicit, not a manually earned campaign.
var state:Node
var shell:Control
var exits:Array=[]
var checks:=0
var failures:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error("THEATER DEPARTURE MAIN: "+label)
func frames(count:int=4)->void:
	for i:int in range(count):await process_frame
func event(input:InputEvent)->void:
	Input.parse_input_event(input);Input.flush_buffered_events()
func key(down:bool)->void:
	var input:=InputEventKey.new();input.keycode=KEY_SPACE;input.physical_keycode=KEY_SPACE;input.pressed=down;event(input)
func touch(point:Vector2,down:bool)->void:
	var input:=InputEventScreenTouch.new();input.index=9;input.position=point;input.pressed=down;event(input)
func button(parent:Node,text:String)->Button:
	for child:Node in parent.get_children():
		if child is Button and child.text==text:return child
		var found:Button=button(child,text)
		if found!=null:return found
	return null
func click(control:Control)->void:
	var point:Vector2=control.get_global_rect().get_center()
	var motion:=InputEventMouseMotion.new();motion.position=point;motion.global_position=point;event(motion)
	for down:bool in [true,false]:
		var input:=InputEventMouseButton.new();input.position=point;input.global_position=point;input.button_index=MOUSE_BUTTON_LEFT;input.pressed=down;event(input);await process_frame
	await frames(2)
func source_facts()->String:
	return JSON.stringify({"theater":state.d.theaterHunt,"items":state.d.items,"wallet":state.d.wallet,"lake":state.d.qizhenLake})
func fixture()->void:
	state.begin_checkpoint("c3-theater-code")
	state.d.theaterHunt.admitted=true;state.d.theaterHunt.phase="complete"
	state.d.native.c3_reversal_pending=false
	state.d.native.player={"scene":"theater_interior","x":800.0,"y":820.0}
	state.d.native.positions={"theater_interior:":{"x":800.0,"y":820.0}}
func freeze()->void:
	shell.set_process(false);shell.world.set_process(false)
	for host:Control in [shell.c3_narrative_host,shell.library_story_host,shell.c3_scene_host]:host.set_process(false)
	if is_instance_valid(shell.audio_director):shell.audio_director.set_process(false)
func reset()->void:
	fixture();shell._refresh();shell._show_world_mobile();await frames()
	freeze();shell.world._process(0);shell._focus_world_surface();await frames(2)
func interact(using_touch:bool)->Control:
	check(shell.world.nearby.get("id","")=="theater_exit","original physical exit is the actual nearby target")
	if using_touch:
		var local:Vector2=(Vector2(836,842)-shell.world.camera)*shell.world.zoom+shell.world.size/2
		var point:Vector2=shell.world_view.get_global_transform_with_canvas()*(local*shell.world_view.size/Vector2(shell.world_viewport.size))
		touch(point,true);await process_frame;touch(point,false)
	else:
		key(true);await process_frame;key(false)
	await frames(2)
	var effect:Control=shell.world_effect
	check(is_instance_valid(effect) and effect.get_script().resource_path=="res://scripts/presentation/theater_departure.gd","routed input mounts the one physical departure owner")
	if is_instance_valid(effect):effect.set_process(false)
	return effect
func tick(effect:Control,count:int)->void:
	for i:int in range(count):
		if not is_instance_valid(effect) or effect.is_finished():return
		shell.world._process(.05);effect.tick(.05,true)
		if not effect.finished:check(shell.world.can_stand(shell.world.player),"Main departure movement stays collision-safe")
func run()->void:
	check(load("res://tests/native_test_isolation.gd").is_isolated_save(),"isolated user storage")
	if failures:quit(1);return
	state=root.get_node("State");state.developer_mode=true
	var listener:Callable=func(action:String,previous:Dictionary,current:Dictionary,_result:Dictionary):
		if action=="c3_target:theater_exit":exits.append({"player":previous.native.player.duplicate(true),"from":previous.native.scene,"to":current.native.scene,"checkpoint":current.rpgCheckpoint})
	state.action_completed.connect(listener)
	for dimensions:Vector2i in [Vector2i(1280,720),Vector2i(390,844)]:
		root.size=dimensions;fixture();shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames(6)
		shell._show_world_mobile();await frames();freeze();shell.world._process(0);shell._focus_world_surface();await frames(2)
		var before_count:int=exits.size();var facts:String=source_facts()
		var effect:Control=await interact(dimensions.x<1100)
		if not is_instance_valid(effect):await shell.shutdown();shell.queue_free();await frames();continue
		check(exits.size()==before_count and state.d.native.scene=="theater_interior","input itself cannot request controller exit")
		tick(effect,3)
		check(exits.size()==before_count and source_facts()==facts,"opening/alignment do not write original story or item state")
		var paused_at:Vector2=shell.world.player;var elapsed:float=effect.elapsed_ms
		shell._on_phone_page("control_center");await frames(2)
		check(is_instance_valid(shell.control_center) and state.d.ui.controlCenterOpen and shell.world_effect==effect,"real control-center entry preserves the active traversal")
		tick(effect,20)
		check(shell.world.player==paused_at and effect.elapsed_ms==elapsed and exits.size()==before_count,"control-center panel pauses without spending active time or emitting exit")
		shell._on_phone_action("native_control_center_close",null);await frames(2)
		check(not state.d.ui.controlCenterOpen,"real close control resumes the same owner")
		var shortcut:=InputEventKey.new();shortcut.keycode=KEY_F10;shortcut.physical_keycode=KEY_F10;shortcut.pressed=true;event(shortcut);await process_frame
		shortcut=shortcut.duplicate();shortcut.pressed=false;event(shortcut);await frames(2)
		check(is_instance_valid(shell.modal) and shell.world_effect==effect,"real F10 settings modal preserves the departure owner")
		paused_at=shell.world.player;elapsed=effect.elapsed_ms;tick(effect,20)
		check(shell.world.player==paused_at and effect.elapsed_ms==elapsed and exits.size()==before_count,"F10 modal pauses physical traversal and active clock")
		var close:Button=button(shell.modal,"关闭") if is_instance_valid(shell.modal) else null
		check(close!=null,"F10 modal exposes its actual close control")
		if close!=null:await click(close)
		check(not is_instance_valid(shell.modal) and shell.world_effect==effect,"actual modal-close click resumes the same departure")
		tick(effect,100)
		check(effect.finished and exits.size()==before_count+1,"one original controller exit follows the completed collision walk")
		if exits.size()==before_count+1:
			var receipt:Dictionary=exits.back()
			check(receipt.player.x==836 and receipt.player.y==895 and receipt.from=="theater_interior" and receipt.to=="campus_qizhen_loop" and receipt.checkpoint=="campus_theater_junction","controller receives physical source endpoint before the existing lake-approach handoff")
		effect.completed.emit()
		check(exits.size()==before_count+1,"duplicate stale completion cannot request the original exit twice")
		await frames()
		for fault:String in ["explicit_cancel","state_identity","scene_change","hidden_world"]:
			await reset();before_count=exits.size();facts=source_facts();effect=await interact(dimensions.x<1100)
			if not is_instance_valid(effect):continue
			tick(effect,3)
			match fault:
				"explicit_cancel":shell._cancel_world_effect()
				"state_identity":state.d=state.d.duplicate(true)
				"scene_change":state.open_scene("library_interior")
				"hidden_world":shell.world_frame.hide()
			if is_instance_valid(effect) and not effect.is_finished():effect.tick(.05,true)
			check(effect.was_cancelled and not effect.finished and shell.world_effect==null,"Main cancels and retires owner on "+fault)
			check(exits.size()==before_count and source_facts()==facts,"Main "+fault+" cannot submit exit or change original items/mainline facts")
			effect.completed.emit()
			check(exits.size()==before_count,"cancelled owner has no usable late completion on "+fault)
			check(not shell.world.chapter3_layers.doors.departure_held and not shell.world.chapter3_layers.doors.departure_clock_owned,"cancelled Main owner always releases sensor and clock")
			await frames()
		await shell.shutdown();shell.queue_free();await frames()
	state.action_completed.disconnect(listener)
	print("THEATER_DEPARTURE_MAIN: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
