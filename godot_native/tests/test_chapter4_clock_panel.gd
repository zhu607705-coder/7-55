extends SceneTree
const Chapter=preload("res://scripts/chapters/chapter4.gd")
const Effect=preload("res://scripts/ui/chapter4_world_handoff.gd")
var checks:=0
var failures:=0
func _initialize():run.call_deferred()
func frames():
	for i in 6:await process_frame
func check(ok:bool,label:String):
	checks+=1
	if not ok:failures+=1;push_error(label)
func run():
	var state=root.get_node("State");state.developer_mode=true
	var source=Chapter.new()
	for view in [Vector2i(390,844),Vector2i(430,860),Vector2i(1180,812)]:
		root.size=view;state.d=state.initial();state.d.native.chapter=4;state.d.native.scene="duan_yongping_temporal_maze";state.d.native.page="c4_device";state.d.native.c4_context="clock";state.d.runtimeMode="rpg"
		var c=state.d.chapter4;c.prologueSeen=true;c.phase="hall_clock_inspection";c.timeState="2245_opening";c.factIds=["external_time_rejected","hall_clock_inspected"];c.floor="A1";c.mode="light"
		var shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames()
		check(shell._open_chapter4_clock(state.d),"source eligible clock opens")
		await frames();var panel=shell.modal
		if not is_instance_valid(panel):await shell.shutdown();shell.queue_free();await frames();continue
		check(panel.required_time=="1225_bakery" and panel.buttons[0].text.contains("刻痕清晰"),"original available-mark clue restored")
		check(panel.selected==0 and panel.face.clock_text=="12:25","original fallback selection and analog face")
		var area=Rect2(Vector2.ZERO,Vector2(view));check(area.encloses(panel.frame.get_rect()),"clock frame inside screen: %s %s"%[view,panel.frame.get_rect()])
		for b in panel.buttons:check(area.encloses(b.get_global_rect()) and b.size.y>=44,"all source options visible: %s %s"%[view,b.get_global_rect()])
		panel.close_requested.emit();await frames()
		check(shell.world.has_focus(),"closing clock restores the existing world viewport focus")
		check(shell._open_chapter4_clock(state.d),"clock can reopen without state change");await frames();panel=shell.modal
		panel.choose(1);panel.submit();await frames()
		check(panel.feedback_label.text=="这处刻度仍会回弹。" and state.d.chapter4.timeState=="2245_opening","wrong choice retains panel and original feedback, no state transition")
		var key=InputEventKey.new();key.pressed=true;key.keycode=KEY_RIGHT;root.push_input(key,true);await frames()
		check(panel.selected==2,"right arrow selects next source option")
		root.push_input(key,true);await frames();check(panel.selected==0,"selection wraps")
		key.keycode=KEY_ENTER;root.push_input(key,true);await frames()
		check(state.d.chapter4.phase=="bakery_hour_hand" and state.d.chapter4.timeState=="1225_bakery","Enter submits unchanged controller time rules")
		check(not is_instance_valid(shell.modal) and shell.world_frame.visible,"accepted setting returns to same world")
		await shell.shutdown();shell.queue_free();await frames()
		var e=Effect.new();e.kind="paper_pickup";e.size=Vector2(view)-Vector2(20,140)
		var metrics=e.paper_layout()
		if view.x<660:
			check(e.uses_responsive_exploration() and metrics.portrait,"paper retains responsive world")
			check(328*metrics.scale>view.x*.65 and 328*metrics.scale<view.x,"source paper silhouette remains legible inside portrait")
		else:check(not metrics.portrait,"desktop paper keeps original composition")
		e.free()
	print("CHAPTER4_CLOCK_PANEL ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
