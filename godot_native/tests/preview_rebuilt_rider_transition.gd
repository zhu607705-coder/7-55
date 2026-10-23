extends SceneTree
## Production transition with isolated, repeating review playback. No State writes.
const Presenter=preload("res://scripts/presentation/chase_transition_3d_presenter.gd")
var film: Control
var review_side: bool=false
class InputBridge extends Node:
	var fixture: SceneTree
	func _input(event: InputEvent) -> void:fixture.handle_input(event)
	func _process(_delta: float) -> void:
		if fixture.film!=null:
			fixture.review_camera()
			fixture.film.caption.text="%s · F%03d · P 播放 · ←/→ 逐帧"%[fixture.film.stage,fixture.film.frame]
func _initialize() -> void:run.call_deferred()
func run() -> void:
	root.title="7:55 · 像素鹈鹕变身与骑行";root.size=Vector2i(1280,800)
	film=Presenter.new();root.add_child(film);film.size=Vector2(root.size)
	root.size_changed.connect(func():film.size=Vector2(root.size))
	film.completed.connect(func(stage: String,_skipped: bool):film.play.call_deferred("finish" if stage=="start" else "start"))
	film.cancelled.connect(func(_stage: String):quit())
	film.play("start")
	var bridge:=InputBridge.new();bridge.fixture=self;root.add_child(bridge)
func handle_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:return
	if event.keycode==KEY_V:review_side=not review_side;review_camera();return
	if event.keycode==KEY_P:film.manual_clock=false;film.set_paused(false);return
	if event.keycode in [KEY_LEFT,KEY_RIGHT]:
		film.manual_clock=true;film.frame=clampi(film.frame+(1 if event.keycode==KEY_RIGHT else -1),0,film.last_frame());film.elapsed=film.RiderActions.seconds_at(film.stage,film.frame);film._redraw();return
	var index: int=[KEY_1,KEY_2,KEY_3,KEY_4,KEY_5,KEY_6,KEY_7,KEY_8,KEY_9].find(event.keycode)
	if index<0:return
	film.manual_clock=true;film.play("start" if index<3 else "finish")
	film.frame=[0,20,55,40,70,100,77,90,114][index];film.elapsed=film.RiderActions.seconds_at(film.stage,film.frame)
	film._redraw()

func review_camera() -> void:
	if not review_side or film.campus_human==null:return
	var hip: Vector3=film.campus_human.joint_point("Hips")
	film.source_camera.position=hip+Basis(Vector3.UP,float(film.action_pose.get("body_yaw",0)))*Vector3(5.5,1,0)
	film.source_camera.look_at(hip+Vector3(0,.2,0),Vector3.UP);film.source_camera.fov=40
	film.view3d.render_target_update_mode=SubViewport.UPDATE_ONCE
