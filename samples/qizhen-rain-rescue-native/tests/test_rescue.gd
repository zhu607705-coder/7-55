extends SceneTree
const Timeline=preload("res://scripts/rescue_timeline.gd")
var checks: int=0
var failures: int=0
func _initialize() -> void:run.call_deferred()
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func run() -> void:
	var model: RefCounted=Timeline.new()
	var seen: Dictionary={}
	var old_player: Vector2=Timeline.point_at(0)
	var old_teacher: Vector2=Timeline.teacher_at(0)
	var old_officer: Vector2=Timeline.officer_at(0)
	var old_ring: Vector2=Timeline.ring_at(0)
	for i: int in range(901):
		var t: float=i/60.0
		var player: Vector2=Timeline.point_at(t)
		var teacher: Vector2=Timeline.teacher_at(t)
		var officer: Vector2=Timeline.officer_at(t)
		var ring: Vector2=Timeline.ring_at(t)
		seen[Timeline.phase_at(t)]=true
		check(player.is_finite() and teacher.is_finite() and officer.is_finite() and ring.is_finite(),"all visible anchors are finite")
		check(player.distance_to(old_player)<3.0,"player does not teleport")
		check(teacher.distance_to(old_teacher)<3.0,"teacher does not teleport")
		check(officer.distance_to(old_officer)<3.0,"safety officer does not teleport")
		check(ring.distance_to(old_ring)<5.5,"throw/catch/release share one ring anchor")
		if t>=Timeline.DOCK and t<Timeline.LANDED:
			check((teacher+Vector2(34,-7)).distance_to(player+Vector2(-22,-1))<.001,"teacher hand and player wrist use one contact")
			check((officer+Timeline.Geometry.OFFICER_HAND_OFFSET).distance_to(ring+Timeline.Geometry.RING_CONTACT_OFFSET)<.001,"measured officer palms stay on the near ring rim")
			check(teacher.x+20<=749 and teacher.x-16>=653,"teacher feet stay on measured deck")
			check(officer.x+Timeline.Geometry.OFFICER_FOOT_MAX_X<=749 and officer.x+Timeline.Geometry.OFFICER_FOOT_MIN_X>=653,"safety officer feet stay on measured deck")
		if t>=Timeline.SPLASH and t<Timeline.LIFT:check(player.y-24<576,"head remains above water")
		old_player=player;old_teacher=teacher;old_officer=officer;old_ring=ring
	check(seen.size()==11,"all eleven sequence states represented")
	check(not model.advance(-1) and model.elapsed==0,"negative delta ignored")
	model.advance(2);model.paused=true
	var saved: Dictionary=model.pose()
	model.advance(100);check(model.pose()==saved,"pause freezes all timeline poses")
	model.paused=false;check(model.advance(100),"natural completion is emitted")
	check(model.terminal_count==1 and model.finished and model.elapsed==15,"terminal exactly once")
	for i: int in range(10):check(not model.advance(1) and not model.skip(),"repeat completion cannot re-emit")
	model.reset();check(model.elapsed==0 and not model.finished and model.terminal_count==0,"replay clears presentation-only state")
	check(model.skip() and model.pose().landed and model.pose().wet,"skip ends safely on shore while wet")
	check(model.outcome=="skipped_preview","skip is explicitly not a story success")
	var shell: Control=load("res://scenes/rain_rescue_preview.tscn").instantiate()
	root.add_child(shell)
	var view: Control=shell.get_node("Presentation")
	view.capture_mode=true
	view.skip();view.skip();view._report_preview()
	check(view.callback_count==1,"view filters repeated local callbacks")
	view.footprint_side=-1;view.replay();check(view.footprint_side==1,"replay resets footprint alternation");view.skip();check(view.callback_count==2,"replay gets a fresh local run identity")
	shell.set_anchors_preset(Control.PRESET_TOP_LEFT)
	for dimensions: Vector2i in [Vector2i(1280,720),Vector2i(390,844),Vector2i(960,600),Vector2i(1920,1080),Vector2i(320,568),Vector2i(280,600)]:
		shell.size=dimensions;shell._layout()
		var rendered: Vector2=view.size*view.scale
		check(absf(rendered.x/rendered.y-16.0/9)<.0001,"every viewport preserves 16:9")
		check(view.position.x>=-.1 and view.position.y>=-.1,"letterboxed content is visible")
		if dimensions.x<=390:
			check(shell.mobile_controls.visible and shell.mobile_controls.size.y>=48,"portrait provides 48px touch targets")
			check(shell.mobile_controls.position.y+shell.mobile_controls.size.y<=dimensions.y,"portrait controls stay in bounds")
			check(shell.mobile_controls.position.x+shell.mobile_controls.size.x<=dimensions.x,"portrait controls fit narrow width")
			for button: Button in shell.mobile_controls.get_children():check(button.focus_mode==Control.FOCUS_NONE,"mobile button never captures Space replay")
		for rect: Rect2 in view.BUTTONS:check(Rect2(Vector2.ZERO,view.size).encloses(rect),"all touch hitboxes remain in visible view")
	check(view._logical_point(Vector2(740,500))==Vector2(740,500),"local pointer transforms are not applied twice")
	var source: String=FileAccess.get_file_as_string("res://scripts/rain_rescue_preview.gd")
	check(not source.contains("VideoStreamPlayer") and not source.contains("State."),"sample has no video or progression authority")
	print("QIZHEN_RAIN_RESCUE: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
