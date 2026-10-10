extends SceneTree
const Activity=preload("res://scripts/games/chapter4_activity.gd")
var checks:=0
var failures:=0
var completed:=[]
var cancelled:=0
func _initialize():run.call_deferred()
func check(ok:bool,label:String):
	checks+=1
	if not ok:failures+=1;push_error(label)
func frames(count:int=3):
	for i in count:await process_frame
func key(activity:Node,value:int):
	var event:=InputEventKey.new();event.keycode=value;event.pressed=true;activity._input(event)
func run():
	create_timer(30).timeout.connect(func():push_error("Elevator source watchdog");quit(2))
	var content:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/source/chapter4-temporal-maze.content.json"))
	var t:Dictionary=content.elevator.timeline
	var game=Activity.new();game.setup({"kind":"elevator_alignment","timeline":t,"session":"source-panel-test"});root.add_child(game)
	game.completed.connect(func(result):completed.append(result));game.cancelled.connect(func():cancelled+=1)
	await frames();game.set_process(false)
	var panel=game.elevator_panel
	check(game.uses_activity_layout(),"Elevator uses the readable native available-area layout")
	for dimensions in [Vector2(390,744),Vector2(430,760),Vector2(844,290),Vector2(1180,712)]:
		game.configure_activity_layout(dimensions,dimensions.x<600);await frames()
		check(panel.size==dimensions and game.scale==Vector2.ONE,"No whole-panel font shrink at "+str(dimensions))
		var controls=[panel.heading,panel.instruction,panel.door_label,panel.passenger_label,panel.readout,panel.hint,panel.controls]
		for node in controls:
			check(Rect2(Vector2.ZERO,dimensions).encloses(Rect2(node.position,node.size)),"Visible content remains within panel: "+node.name+str(dimensions))
		for button in [panel.earlier,panel.later,panel.replay,panel.back]:
			check(button.size.y>=44 and button.size.x>=44,"Actual button has usable target")
		check(panel.instruction.get_theme_font_size("font_size")>=16 and panel.readout.get_theme_font_size("font_size")>=16,"Instructions and original record values remain readable")
	game.configure_activity_layout(Vector2(960,540),false);await frames()
	var baseline:Dictionary=panel.geometry()
	check(baseline.duration==float(t.timelineEndSeconds-t.timelineStartSeconds),"Full31second source timeline, not hardcoded16seconds")
	check(is_equal_approx(baseline.door.size.x/baseline.passenger.size.x,8.0/6.0),"Door and passenger durations are eight and six seconds")
	check(panel.readout.text.contains("22:43:27") and panel.readout.text.contains("22:43:31—22:43:37"),"Readout exposes the actual original track clocks")
	key(game,KEY_RIGHT);await frames();var shifted:Dictionary=panel.geometry()
	check(game.selection==int(t.selectableStartMinSeconds)+1,"Right changes selected door start by exactly one second")
	check(shifted.door.position.x>baseline.door.position.x and shifted.passenger==baseline.passenger,"Only blue door moves; yellow passenger window stays fixed")
	check(shifted.rise_x>baseline.rise_x,"White rise marker follows door start")
	for i in 20:key(game,KEY_LEFT)
	check(game.selection==int(t.selectableStartMinSeconds),"Earlier control clamps to original minimum")
	for i in 20:key(game,KEY_RIGHT)
	check(game.selection==int(t.selectableStartMaxSeconds),"Later control clamps to original maximum")
	key(game,KEY_ENTER);check(game.stage=="replay" and game.elapsed==0 and not game.boarded,"Enter begins the existing timed replay")
	key(game,KEY_LEFT);check(game.selection==int(t.selectableStartMaxSeconds),"Running replay cannot change its submitted start")
	key(game,KEY_SPACE);check(game.boarded,"Space retains ordinary boarding ownership")
	game.elapsed=5999;game._process(.002);await frames()
	check(game.stage=="select" and not game.running and completed.is_empty(),"Wrong exact start cannot earn completion")
	check(panel.readout.text.contains("校验结果") and panel.back.visible,"Wrong result retains explanation and Return")
	await frames(5);check(panel.readout.text.contains("校验结果"),"Failure remains visible across frames")
	key(game,KEY_ESCAPE);check(cancelled==1 and completed.is_empty(),"Escape exits failed selection without progress")
	game.selection=int(t.correctReplayStartSeconds);game.elevator_feedback="";game._elevator_controls();key(game,KEY_ENTER)
	game.elapsed=5999;game._process(.002);await frames()
	check(game.stage=="select" and panel.readout.text.contains("未在六秒") and completed.is_empty(),"Correct start without boarding fails distinctly")
	key(game,KEY_ENTER);key(game,KEY_SPACE);game.elapsed=5990;game._process(.001)
	check(completed.is_empty(),"Boarding cannot finish before six seconds")
	game._process(.009)
	check(completed.size()==1 and completed[0].startSeconds==int(t.correctReplayStartSeconds) and completed[0].boarded and completed[0].elapsedMs>=6000,"Exact source start plus boarding keeps original terminal proof")
	game._process(.05);key(game,KEY_ENTER);check(completed.size()==1,"Completion is emitted once")
	game.queue_free();await frames();print("C4_ELEVATOR_SOURCE ",checks," checks; ",failures," failures");quit(1 if failures else 0)
