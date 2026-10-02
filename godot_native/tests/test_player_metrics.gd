extends SceneTree
const Metrics = preload("res://scripts/player_metrics.gd")
var failures := 0
func _initialize() -> void:
	for ms in [0.0,109.0,110.0,219.0,770.0,879.0,880.0,1760.0]:
		if Metrics.frame_at(ms) != int(floor(ms/110))%8: failures+=1
	for scale in [.325,.65,1.2]:
		var rect: Rect2=Metrics.visual_rect(Vector2(800,500),scale)
		if not is_equal_approx(rect.end.y,541.6): failures+=1
		if not is_equal_approx(rect.size.x/rect.size.y,96.0/128.0): failures+=1
	var foot: Rect2=Metrics.foot_rect(Vector2(800,500))
	if foot.size!=Vector2(19.5,14.625) or foot.get_center()!=Vector2(800,531.6875): failures+=1
	if Metrics.scale_at("campus_bootstrap",500)!=.325: failures+=1
	if Metrics.scale_at("library_interior",500)!=.65: failures+=1
	print("Source player metrics: ","PASS" if failures==0 else "FAIL")
	quit(0 if failures==0 else 1)
