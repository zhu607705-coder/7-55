extends SceneTree
const Entrance=preload("res://scripts/games/qizhen_swan_entrance.gd")
var checks: int=0
var failures: int=0
func _initialize() -> void: run.call_deferred()
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1;push_error(label)
func run() -> void:
	root.size=Vector2i(1280,720)
	var timeline: RefCounted=Entrance.new()
	var last: Vector2=timeline.pose().position
	for i: int in range(431):
		check(not timeline.advance(1.0/60.0),"not complete before 7.2 seconds")
		var p: Dictionary=timeline.pose()
		check(p.position.distance_to(last)<4.0,"continuous swan movement")
		check(p.frame>=0 and p.frame<8 and p.next_frame>=0 and p.next_frame<8,"bounded full-body atlas poses")
		last=p.position
	timeline.advance(0.02)
	check(timeline.completed and timeline.completion_count==1,"one completion at 7.2 seconds")
	check(timeline.pose().position==Entrance.SWAN_HANDOFF,"last cinematic position is the handoff position")
	check(not timeline.skip() and not timeline.advance(10) and timeline.completion_count==1,"completion is idempotent")
	timeline.reset();timeline.paused=true;timeline.advance(1)
	check(timeline.elapsed==0 and not timeline.completed,"pause freezes presentation")
	timeline.paused=false;timeline.advance(2.7)
	check(timeline.skip() and timeline.elapsed==Entrance.DURATION,"skip goes to same final state")
	timeline.reset();check(timeline.elapsed==0 and timeline.completion_count==0,"retry resets clock and handoff")
	var view: Control=load("res://scenes/qizhen_swan_entrance_preview.tscn").instantiate()
	root.add_child(view)
	view.set_process(false)
	var native_rig: Node2D=view.kayak_rig
	check(is_instance_valid(native_rig) and native_rig.scene_file_path=="res://scenes/objects/kayak_rig.tscn","isolated entrance owns the current native kayak scene")
	check(native_rig.get_index()<view.foreground.get_index(),"isolated paper and HUD render above the rig")
	await process_frame
	await process_frame
	check(view.sound_players.size()==2,"original source sound assets loaded")
	check(view.swan.spawn_valid and view.swan.position==Entrance.SWAN_HANDOFF,"handoff is valid water without relocation")
	check(view.boat_valid(view.kayak.position,view.kayak.heading),"original kayak hull starts in valid water")
	var before: Vector2=view.kayak.position
	view.stroke("left")
	check(view.kayak.inputs.is_empty() and view.kayak.position==before,"cinematic ignores gameplay input")
	view.skip_intro();view.skip_intro()
	check(view.handed_back==1 and view.stage=="play" and view.swan.elapsed==0,"skip restores controls once with full grace")
	view.stroke("left");view._process(0.05)
	check(view.kayak.inputs.size()==1 and view.kayak.position!=before,"same visible boat moves after actual paddle intent")
	check(native_rig.position.is_equal_approx(view._screen(view.kayak.position)) and native_rig.sampled_pose.left.phase=="entry","native child follows real boat and sampled paddle phase")
	await process_frame
	view.paused=true
	var frozen: float=view.play_time
	view._process(0.05)
	check(view.play_time==frozen,"pause freezes chase clock")
	view.restart()
	check(view.stage=="intro" and view.handed_back==0 and view.kayak.inputs.is_empty() and view.trail.is_empty(),"retry clears input particles and handoff")
	check(view.kayak_rig==native_rig,"replay reuses one native rig without orphaning children")
	view.skip_intro()
	for i: int in range(69):view._process(0.05)
	check(view.stage=="play" and not view.swan.caught,"idle player cannot be caught during handoff protection")
	view.restart();view.skip_intro()
	view.controls={"left":Rect2(0,0,120,120)}
	view._pointer(Vector2(60,50),true,3);view._pointer(Vector2(60,100),false,3)
	check(view.kayak.last_direction=="reverse" and view.kayak.last_side=="left","touch swipe down routes to the same reverse paddle")
	view.restart();view.skip_intro()
	view.controls={"right":Rect2(0,0,120,120)}
	view._pointer(Vector2(60,90),true,4);view._pointer(Vector2(60,30),false,4)
	check(view.kayak.last_direction=="forward" and view.kayak.last_side=="right","touch swipe up routes to the same forward paddle")
	view.restart();view.skip_intro();view.paused=true
	view.stroke("left")
	check(view.kayak.inputs.is_empty(),"paused input cannot queue a surprise stroke")
	view.restart();view.skip_intro()
	view.kayak.position=Vector2(100,850)
	check(not view.reached_exit() and not view.boat_valid(view.kayak.position,view.kayak.heading),"southwest black area is not navigable or an exit")
	view.kayak.position=Vector2(360,814)
	view.kayak.heading=PI/2
	check(view.reached_exit(),"actual narrow south water passage accepts the full hull")
	view.swan.caught=true
	view._process(0.01)
	check(view.stage=="escaped","waterway arrival wins over a same-frame catch")
	view.restart();view.skip_intro()
	view.kayak.position=Vector2(445,850)
	check(not view.boat_valid(view.kayak.position,PI/2),"south passage right stone wall blocks full hull")
	view.restart();view.skip_intro()
	view.controls={"left":Rect2(20,20,120,120),"pause":Rect2(160,20,120,120)}
	var emulated:=InputEventMouseButton.new()
	emulated.device=-1
	emulated.button_index=MOUSE_BUTTON_LEFT
	emulated.position=Vector2(60,50)
	emulated.pressed=true
	view._gui_input(emulated)
	emulated.pressed=false
	view._gui_input(emulated)
	check(view.kayak.inputs.is_empty(),"touch-generated mouse cannot double-paddle")
	var touch:=InputEventScreenTouch.new()
	touch.index=0
	touch.position=Vector2(60,50)
	touch.pressed=true
	Input.parse_input_event(touch)
	touch=InputEventScreenTouch.new()
	touch.index=0
	touch.position=Vector2(60,90)
	touch.pressed=false
	Input.parse_input_event(touch)
	Input.flush_buffered_events()
	check(view.kayak.inputs.size()==1 and view.kayak.last_direction=="reverse","viewport touch dispatch creates exactly one reverse paddle")
	touch=InputEventScreenTouch.new()
	touch.index=0
	touch.position=Vector2(200,50)
	touch.pressed=true
	Input.parse_input_event(touch)
	Input.flush_buffered_events()
	check(view.paused,"touch pause activates once")
	emulated.position=Vector2(200,50)
	emulated.pressed=true
	view._gui_input(emulated)
	check(view.paused,"emulated mouse cannot cancel the touch pause")
	view.restart();view.skip_intro()
	view.controls={"left":Rect2(0,0,120,120)}
	var cancelled_touch:=InputEventScreenTouch.new()
	cancelled_touch.index=9;cancelled_touch.position=Vector2(60,50);cancelled_touch.pressed=true
	view._gui_input(cancelled_touch)
	cancelled_touch=InputEventScreenTouch.new()
	cancelled_touch.index=9;cancelled_touch.position=Vector2(60,90);cancelled_touch.canceled=true
	view._gui_input(cancelled_touch)
	check(view.kayak.inputs.is_empty() and not view.touch_starts.has(9),"cancelled touch discards the paddle gesture without an intent")
	cancelled_touch.canceled=false;view._gui_input(cancelled_touch)
	check(view.kayak.inputs.is_empty(),"a late release after touch cancellation cannot paddle")
	view.restart();view.skip_intro();view.capture_demo=true
	for i: int in range(120):
		view._process(1.0/30.0)
		check(view.boat_valid(view.kayak.position,view.kayak.heading),"input-only capture route keeps full hull in water")
	check(view.stage=="escaped" and view.capture_input_count==18 and view.handed_back==1,"capture route reaches real south mouth using eighteen paddle intents")
	view.free()
	check(not is_instance_valid(native_rig),"isolated preview exit frees its entire native rig")
	print("QIZHEN_SWAN_ENTRANCE: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
