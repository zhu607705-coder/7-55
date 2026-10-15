extends SceneTree
const Presenter=preload("res://scripts/presentation/chase_transition_3d_presenter.gd")
var errors: Array=[]
var completions: Array=[]
var cancellations: Array=[]
func _initialize() -> void:run.call_deferred()
func check(value: bool,label: String) -> void:
	print("PASS " if value else "FAIL ",label)
	if not value:errors.append(label)
func run() -> void:
	var state: Node=root.get_node("State")
	state.developer_mode=true
	var before: String=JSON.stringify(state.d)
	var view=Presenter.new();view.manual_clock=true;root.add_child(view);view.size=Vector2(960,676)
	view.completed.connect(func(stage,skipped):completions.append([stage,skipped]))
	view.cancelled.connect(func(stage):cancellations.append(stage))
	view.play("start");view.advance(.1)
	check(view.frame==2,"start clock follows source24fps")
	check(view.pose_at("start",18).pose=="grip" and view.pose_at("start",29).pose=="leg_over","source grip then mount ordering")
	check(view.pose_at("start",60).segment=="pedal" and view.pose_at("start",90).segment=="handoff","source pedal insert then live handoff")
	var elapsed: float=view.elapsed;view.set_paused(true);view.advance(30)
	check(view.elapsed==elapsed,"pause excludes elapsed/background catch-up")
	view.set_paused(false);view.advance(30)
	check(absf(view.elapsed-elapsed-.25)<.00001,"source overlay catches up at most250ms")
	view._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	check(view.paused,"window focus loss freezes transition")
	view.configure_activity_layout(Vector2(390,844),true)
	check(view.size==Vector2(390,844) and view.scale==Vector2.ONE,"full-scene sizing keeps physical controls")
	check(absf(view.film_rect().size.x/view.film_rect().size.y-960.0/540)<.00001,"portrait resize preserves uniform16:9")
	check(Rect2(Vector2.ZERO,view.size).encloses(view.skip_button.get_rect()) and view.skip_button.size.y>=44,"skip target remains inside portrait viewport")
	view.skip();view.skip();view.advance(.1)
	check(completions==[["start",true]],"skip emits once even while paused")
	view.play("finish")
	check(view.pose_at("finish",22).pose=="brake" and view.pose_at("finish",60).pose=="left_foot_down","arrival brakes then plants foot")
	check(view.pose_at("finish",75).pose=="dismount_leg_over" and view.pose_at("finish",100).pose=="push_bike","source dismount then parking")
	check(view.pose_at("finish",125).door>0,"source paper exit and final door cover")
	view.cancel();view.skip();view.advance(3)
	check(cancellations==["finish"] and completions.size()==1,"cancel cannot commit or later complete")
	view.play("start",true);view.play("finish")
	await process_frame
	check(completions.size()==1 and view.stage=="finish" and view.status=="playing","new owner invalidates deferred retry callback")
	view.cancel();view.play("start",true)
	await process_frame
	check(completions.back()==["start",true],"retry departure takes short path")
	view.play("finish",false,true)
	await process_frame
	check(completions.back()==["finish",false] and view.frame==132,"reduced motion uses authored ending endpoint")
	var count: int=completions.size()
	view.play("start",true);view.dispose()
	await process_frame
	check(completions.size()==count,"dispose invalidates all pending callbacks")
	view.set_process(true);view.play("finish");view.manual_clock=true
	for i: int in range(56):view.advance(.1)
	check(view.frame==132 and completions.size()==count+1,"normal ending completes once at source5.5seconds")
	check(JSON.stringify(state.d)==before,"presentation never changes state wallet inventory proof or saves")
	view.queue_free();await process_frame
	print("TRANSITION_TEST failures=",errors.size());quit(0 if errors.is_empty() else 1)
