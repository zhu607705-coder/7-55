extends SceneTree
const Activity=preload("res://scripts/games/chapter4_activity.gd")
var checks: int=0
var failures: int=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error(label)
func drain() -> void: await process_frame; await process_frame
func run() -> void:
	var owner: Node=root.get_node("State")
	check(owner.begin_checkpoint("c4-755-closure"),"Source closure DEV checkpoint is usable")
	var request: Dictionary={}
	for module in owner.modules:
		if str(module.get_script().resource_path)=="res://scripts/chapters/chapter4.gd": request=module.dispatch(owner.d,"c4_lamp_start"); break
	check(request.has("game"),"Controller issues real closure nonce")
	if not request.has("game"): quit(1); return
	var activity: Control=Activity.new(); root.add_child(activity); activity.set_process(false); activity.setup(request.game)
	activity.completed.connect(func(proof): owner.act("c4_closure_done",proof))
	check(activity.stage=="questions" and activity.question_index==0,"Actual scene starts at first question")
	check(activity.title.get_theme_color("font_color")==Color("edf4dc") and activity.body.get_theme_color("font_color")==Color("edf4dc"),"Question/title labels are legible on native dark background")
	for rect in [Rect2(350,-120,260,800),Rect2(350,0,260,540),Rect2(350,30,260,800),Rect2(350,-900,260,800)]:
		var region: Dictionary=activity._lamp_visible_region(rect,Vector2(512,2048))
		if not rect.intersects(Rect2(0,0,960,540)): check(region.is_empty(),"Entirely offscreen artwork does not draw")
		else:
			check(Rect2(0,0,960,540).encloses(region.destination),"Camera-rise artwork is clipped within actual activity viewport")
			check(Rect2(0,0,512,2048).encloses(region.source),"Clipped crop remains within original source artwork")
			check((region.destination.size/region.source.size).distance_to(rect.size/Vector2(512,2048))<0.0001,"Clipping preserves original art scaling on both axes")
	activity._answer("purpose","seek_truth"); await drain()
	check(activity.stage=="questions" and activity.question_index==1 and not owner.d.chapter4.factIds.has("zhu_two_questions_answered"),"First answer shows second question without premature saved completion")
	activity._answer("person","clear_minded"); await drain()
	check(activity.stage=="playback" and activity.running and owner.d.chapter4.factIds.has("zhu_two_questions_answered"),"Second answer callback validates and saves answers before real playback")
	check(activity.controls.get_child_count()==0 and activity.body.text.is_empty(),"Question controls/text are removed through normal lifecycle")
	for i in 115: activity._process(0.05)
	check(activity.stage=="playback" and not owner.d.chapter4.completed,"5750ms playback cannot complete chapter")
	activity._process(0.05); await drain()
	check(activity.stage=="final" and not owner.d.chapter4.completed,"5800ms normal process shows final acknowledgement without story completion")
	check(activity.controls.get_child_count()==1 and activity.controls.get_child(0).text=="我记住了","Final controls contain source acknowledgement only")
	activity.controls.get_child(0).pressed.emit(); check(owner.d.chapter4.completed,"Actual acknowledgement completes valid controller-owned closure")
	check(owner.last_result.message=="外面亮了一下。\n这次真的结束了？\n结束了，签到记录已归档。","Ending retains original three-line exterior exchange after acknowledgement")
	activity.queue_free(); await drain()
	print("CHAPTER4_LAMP_LIFECYCLE_TESTS ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
