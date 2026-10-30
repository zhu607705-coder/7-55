extends "res://campuses/future_learning_center/scripts/puzzles/collab_model.gd"
## The same optics rig gains a physical accessory support across its feed path.
var bracket_x:=0.0
var bracket_attached:=true
func bracket_rect()->Rect2:return Rect2(bracket_x-14,45,28,45)
func set_bracket(x:float,attached:=true)->bool:
	if not is_finite(x) or x< -138 or x>138:return false
	if is_equal_approx(x,bracket_x) and attached==bracket_attached:return true
	bracket_x=x;bracket_attached=attached;configuration_revision+=1;_invalidate();return true
func feed_clear()->bool:
	if not super.feed_clear():return false
	# The full 36-unit carriage sweeps the actual support footprint.
	return not bracket_attached or not bracket_rect().intersects(Rect2(-18,0,36,210))
func light_blocked(side:int)->bool:
	# Removing the accessory clears the rail but also removes its baffle support.
	return bracket_attached and super.light_blocked(side)
func _finish(kind:String,passed:bool)->void:
	super._finish(kind,passed)
	if kind=="feed" and not passed and bracket_attached and bracket_rect().intersects(Rect2(-18,0,36,210)):outcome="送料件碰到附件支架"

func feed_stop_fraction()->float:
	var stop:=1.0
	if not super.feed_clear():stop=super.feed_stop_fraction()
	if bracket_attached and bracket_rect().intersects(Rect2(-18,0,36,210)):stop=minf(stop,(210.0-bracket_rect().end.y-18.0)/210.0)
	return stop
