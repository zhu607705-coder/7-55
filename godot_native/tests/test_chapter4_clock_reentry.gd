extends SceneTree
const Chapter=preload("res://scripts/chapters/chapter4.gd")
var checks:=0
var failures:=0
func _initialize():run.call_deferred()
func check(ok:bool,label:String):
	checks+=1
	if not ok:failures+=1;push_error(label)
func frames():
	for i in range(5):await process_frame
func checkpoint(phase:String,time:String,fact:String) -> Dictionary:
	var s:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/initial_state.json"))
	s.native={"chapter":4,"page":"c4_notes","scene":"duan_yongping_temporal_maze","player":{},"settings":{},"mode":"light","log":[],"completed":[]}
	s.chapter4.prologueSeen=true;s.chapter4.phase=phase;s.chapter4.timeState=time;s.chapter4.factIds=[fact];s.chapter4.floor="A1";s.chapter4.mode="light"
	return s
func run():
	create_timer(25).timeout.connect(func():push_error("Clock admission watchdog");quit(2))
	for row in [["hall_clock_inspection","2245_opening","hall_clock_inspected","1225_bakery"],["room204_restore","1225_bakery","hour_hand_installed","1850_evening"],["maintenance_repair","1850_evening","positioning_plate_installed","2245_maintenance"]]:
		var chapter=Chapter.new();var s:Dictionary=checkpoint(row[0],row[1],row[2]);var before:Dictionary=s.chapter4.duplicate(true)
		var targets:Array=chapter.targets("duan_yongping_temporal_maze",s)
		check(targets.size()==1 and targets[0].action=="c4_clock","Required-time target is the source clock: "+row[0])
		var result:Dictionary=chapter.dispatch(s,"c4_clock")
		check(result.get("page","")=="c4_device" and s.native.get("c4_context","")=="clock","Ordinary clock admission opens required adjustment: "+row[0])
		check(s.chapter4==before,"Opening the control does not change time or story")
		chapter.dispatch(s,"c4_clock_set",{"time":row[1]});check(s.chapter4==before,"Wrong/current setting remains rejected")
		var locked:Dictionary=chapter.dispatch(s,"c4_elevator_ride");check(not locked.has("world_effect") and s.chapter4==before,"Other scene actions cannot bypass time alignment")
		for mutation in [{"floor":"A2"},{"mode":"dark"}]:
			var invalid:Dictionary=checkpoint(row[0],row[1],row[2]);invalid.chapter4.merge(mutation,true)
			check(not chapter.dispatch(invalid,"c4_clock").has("page"),"Original floor/mode guard still applies")
		chapter.dispatch(s,"c4_clock_set",{"time":row[3]});check(s.chapter4.timeState==row[3],"Original exact required setting is accepted")
	var state=root.get_node("State");state.developer_mode=true;state.d=state.initial();state.d.native.chapter=4;state.d.native.scene="duan_yongping_temporal_maze";state.d.native.page="c4_notes";state.d.native.mode="light"
	state.d.chapter4=checkpoint("room204_restore","1225_bakery","hour_hand_installed").chapter4
	root.size=Vector2i(430,860)
	var shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames();shell._show_world_mobile();await frames()
	state.act("c4_clock");await frames()
	check(is_instance_valid(shell.modal),"Actual native State-to-Main route opens the clock after installation")
	if is_instance_valid(shell.modal):
		var panel=shell.modal
		check(panel.required_time=="1850_evening" and panel.buttons[1].text.contains("刻痕清晰"),"Restored18:50 source clue appears in actual control")
		panel.close_requested.emit();await frames();check(shell.world.has_focus(),"Cancel restores world focus without changing time")
		state.act("c4_clock");await frames();check(is_instance_valid(shell.modal),"Reopen after cancel uses the same required-time gate")
		panel=shell.modal;panel.choose(0);panel.submit();await frames();check(state.d.chapter4.timeState=="1225_bakery" and is_instance_valid(shell.modal),"Wrong selection keeps normal panel and state")
		panel.choose(1);panel.submit();await frames();check(state.d.chapter4.timeState=="1850_evening" and not is_instance_valid(shell.modal) and shell.world_frame.visible,"Correct choice returns to original world with required time")
	await shell.shutdown();shell.queue_free();await frames()
	print("C4_CLOCK_REENTRY ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
