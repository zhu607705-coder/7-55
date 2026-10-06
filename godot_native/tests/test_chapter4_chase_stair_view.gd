extends SceneTree
const Activity=preload("res://scripts/games/chapter4_activity.gd")
const Metrics=preload("res://scripts/player_metrics.gd")
var checks:=0
var failures:=0
func _initialize():run.call_deferred()
func check(ok:bool,label:String):
	checks+=1
	if not ok:failures+=1;push_error(label)
func frames(count:=3):
	for i in count:await process_frame
func mouse(point:Vector2,down:bool,device:=0)->InputEventMouseButton:
	var e:=InputEventMouseButton.new();e.position=point;e.global_position=point;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=down;e.device=device;return e
func touch(point:Vector2,down:bool,index:int)->InputEventScreenTouch:
	var e:=InputEventScreenTouch.new();e.position=point;e.pressed=down;e.index=index;return e
func run():
	var game:Control=Activity.new();root.add_child(game);game.setup({"kind":"chase_stairwell","title":"楼梯间","session":"fixture","expectedAttempt":4});game.set_process(false);await frames()
	check(game.uses_activity_layout(),"Full activity opt-in")
	check(game.controls.get_child_count()==2,"No duplicate initial Return")
	game.configure_activity_layout(Vector2(390,844),true);await frames()
	var return_before:Button=game.controls.get_child(1)
	game._chase_input(touch(return_before.global_position+return_before.size/2,true,3))
	check(is_instance_valid(return_before) and return_before.get_parent()==game.controls,"First toolbar touch keeps its actual button owner")
	game._chase_input(touch(return_before.global_position+return_before.size/2,false,3))
	for dimensions:Vector2 in [Vector2(390,844),Vector2(430,860),Vector2(844,390),Vector2(1180,812)]:
		root.size=Vector2i(dimensions);game.configure_activity_layout(dimensions,dimensions.x<1100);await frames()
		check(game.size==dimensions and game.scale==Vector2.ONE,"No shrunken activity shell")
		check(game.title.get_theme_font_size("font_size")==22 and game.body.get_theme_font_size("font_size")==16,"Readable physical typography")
		for control:Control in [game.title,game.body,game.controls,game.chase_view,game.chase_status]:
			check(Rect2(Vector2.ZERO,dimensions).encloses(Rect2(control.position,control.size)),"Visible control within available area "+str(dimensions))
		for button:Button in game.controls.get_children():check(button.size.y>=44,"Physical44px action target")
		var view:Control=game.chase_view
		check(is_equal_approx(view.field.size.x/view.field.size.y,960.0/540),"Source follow viewport aspect")
		check(view.player_sprite.texture.resource_path.contains("assets/rpg/player/player_"),"Original player frame")
		check(view.guard_sprite.texture.resource_path.contains("assets/rpg/npcs/finale/guard_walk"),"Original guard frame")
		check(view.player_sprite.position.is_equal_approx(game.player-Metrics.FOOT_CENTER_OFFSET),"Source foot-to-sprite registration")
		var center:Vector2=view.position+view.field.get_center()
		check(game._chase_pointer_begin(center,-2)and game.pointer_target.is_equal_approx(view.camera),"Physical field maps to camera center")
		game._chase_input(mouse(Vector2(-20,-20),false));check(not game.pointer_moving and game.chase_pointer_owner.is_empty(),"Outside release retires pointer")
		check(not game._chase_pointer_begin(Vector2(5,5),-2),"Header cannot move player")
		game._chase_pointer_begin(center,-2);game.configure_activity_layout(dimensions+Vector2(1,0),true)
		check(not game.pointer_moving and game.chase_finger==-1,"Resize cancels held input")
		game.configure_activity_layout(dimensions,true);game.chase_touch_enabled=true;game._chase_buttons();game._layout_chase();await frames()
		check(Rect2(Vector2.ZERO,dimensions).encloses(game.chase_pad),"Joystick target inside viewport")
		check(not Rect2(game.chase_view.position,game.chase_view.size).intersects(game.chase_pad),"Joystick outside playable field")
		var pad:Vector2=game.chase_pad.get_center()+Vector2(50,0)
		check(game._chase_input(touch(pad,true,7)),"Real touch owns joystick")
		check(game.chase_touch_axis.x>0 and game.chase_finger==7,"Joystick sends original direction")
		check(not game._chase_input(mouse(pad,true,-1))and game.chase_finger==7,"Emulated mouse cannot duplicate touch")
		check(not game._chase_input(touch(center,true,8))and game.chase_finger==7,"Second finger cannot steal owner")
		game._chase_input(touch(Vector2(-50,-50),false,7));check(game.chase_touch_axis==Vector2.ZERO and game.chase_finger==-1,"Outside touch release is neutral")
		game._chase_pointer_begin(pad,-2);game._reset_chase();check(game.chase_touch_axis==Vector2.ZERO and game.chase_pointer_owner.is_empty(),"Retry releases controls")
		check(game.controls.get_child_count()==2,"Repeated Retry has one Return")
	# Rendering may inspect but cannot mutate proof/timing/geometry.
	var before:Dictionary={"player":game.player,"guard":game.guard,"trail":game.trail.duplicate(true),"landing":game.landing,"elapsed":game.elapsed}
	for i in 12:game._present_chase()
	check(before=={"player":game.player,"guard":game.guard,"trail":game.trail,"landing":game.landing,"elapsed":game.elapsed},"Two views never advance gameplay")
	game.running=false;var camera:Vector2=game.chase_view.camera
	game._present_chase();check(camera==game.chase_view.camera,"Stopped activity freezes camera")
	game.running=true;game.player+=Vector2(10,0);game._present_chase();check(game.chase_view.player_facing=="side","Source directional player animation restored")
	game.guard+=Vector2(0,10);game._present_chase();check(game.chase_view.guard_facing=="down","Source directional guard animation restored")
	game.chase_view.present(game.player,game.guard,2110,false,game.landing)
	check(game.chase_view.guard_sprite.frame==2,"Original manifest guard cadence is9fps, independent of player110ms frames")
	game.stage="capture";game.running=false;game._chase_buttons();await frames();check(game.controls.get_child_count()==2,"Source capture keeps Return and input fallback, with no local retry bypass")
	var exits:=[0];game.cancelled.connect(func():exits[0]+=1);game._leave_chase();check(exits[0]==1 and game.chase_pointer_owner.is_empty(),"Return emits only cancellation")
	game.queue_free();await frames()
	# Controlled controller admission: this does not claim an earned route.
	var state:Node=root.get_node("State");state.developer_mode=true;state.begin_checkpoint("c4-755-chase")
	root.size=Vector2i(390,844)
	var shell:Control=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames(5)
	var result:Dictionary=state.act("c4_chase");await frames(5)
	check(result.has("game") and is_instance_valid(shell.active_game),"Existing controller admits one activity")
	check(shell._activity_owns_scene() and not shell.world_frame.is_visible_in_tree(),"Underlying world and stale hint hidden")
	check(shell.active_game.size==Vector2(390,844) and shell.active_game.scale==Vector2.ONE,"Actual Main gives whole physical surface")
	var count_before:int=state.d.chapter4.chaseAttempt
	shell.active_game._leave_chase();await frames(5)
	check(not is_instance_valid(shell.active_game) and shell.world_frame.is_visible_in_tree(),"Return restores original world")
	check(state.d.chapter4.chaseAttempt==count_before and state.d.chapter4.chaseStairwellStage=="inside","Presentation cancellation does not complete or score")
	await shell.shutdown();shell.queue_free();await frames()
	print("CHAPTER4_CHASE_STAIR_VIEW ",checks," checks; ",failures," failures");quit(1 if failures else 0)
