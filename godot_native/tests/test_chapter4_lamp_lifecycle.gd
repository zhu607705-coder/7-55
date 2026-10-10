extends SceneTree
const Activity=preload("res://scripts/games/chapter4_activity.gd")
var checks:=0
var failures:=0
func _initialize()->void:call_deferred("run")
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func advance(view:Control,ms:float)->void:
	while ms>0:
		var dt:=minf(100,ms);view.advance(dt);ms-=dt
func run()->void:
	var owner:=root.get_node("State")
	check(owner.begin_checkpoint("c4-755-closure"),"Source closure checkpoint available")
	var controller:RefCounted
	for module in owner.modules:
		if str(module.get_script().resource_path)=="res://scripts/chapters/chapter4.gd":controller=module
	var issued:Dictionary=controller.dispatch(owner.d,"c4_lamp_start")
	var activity:=Activity.new();root.add_child(activity);activity.setup(issued.game);activity.set_process(false)
	var view:Control=activity.lamp_view
	advance(view,1150);view.choose("purpose","seek_truth");advance(view,980);advance(view,1150);view.choose("person","clear_minded");advance(view,980)
	check(view.stage=="saved" and owner.d.chapter4.factIds.has("zhu_two_questions_answered"),"Source answer request is controller-accepted")
	var saved:Dictionary=owner.d.duplicate(true)
	activity.queue_free();await process_frame;await process_frame
	check(not owner.d.chapter4.completed,"Exit during saved confirmation cannot complete chapter")
	owner.d=saved
	issued=controller.dispatch(owner.d,"c4_lamp_start")
	activity=Activity.new();root.add_child(activity);activity.setup(issued.game);activity.set_process(false);view=activity.lamp_view
	activity.completed.connect(func(proof):owner.act("c4_closure_done",proof))
	check(view.stage=="saved" and view.answers==saved.chapter4.zhuQuestionAnswers,"Reentry keeps original saved answers, no repeated question submission")
	advance(view,1100);check(view.stage=="playback","Reentry retains saved confirmation then replays presentation")
	advance(view,5750);check(view.stage=="playback" and not owner.d.chapter4.completed,"5750ms cannot finish ordinary playback")
	advance(view,50);check(view.stage=="final" and not owner.d.chapter4.completed,"5800ms waits for acknowledgement")
	var event:=InputEventKey.new();event.keycode=KEY_ENTER;event.pressed=true
	view._gui_input(event)
	check(owner.d.chapter4.completed,"Keyboard final acknowledgement reaches sole controller")
	check(owner.last_result.message=="外面亮了一下。\n这次真的结束了？\n结束了，签到记录已归档。","Original three-line ending exchange survives")
	activity.queue_free();await process_frame;await process_frame
	print("CHAPTER4_LAMP_LIFECYCLE_TESTS ",checks," checks; ",failures," failures");quit(1 if failures else 0)
