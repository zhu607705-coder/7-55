extends Node2D
## The original four wake ellipses are independent native Line2D objects.
func apply_speed(speed: float) -> void:
	var forward:=clampf(maxf(0,speed)/360,0,1)
	var reverse:=clampf(maxf(0,-speed)/230,0,1)
	$SternOuter.scale=Vector2.ONE*(.68+forward*.9)
	$SternOuter.modulate.a=.3*forward*.44
	$SternInner.scale=Vector2.ONE*(.76+forward*.7)
	$SternInner.modulate.a=.46*forward*.66
	$BowOuter.scale=Vector2.ONE*(.62+reverse*.96)
	$BowOuter.modulate.a=.36*reverse*.5
	$BowInner.scale=Vector2.ONE*(.7+reverse*.82)
	$BowInner.modulate.a=.5*reverse*.72
