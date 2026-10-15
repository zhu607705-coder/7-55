extends SceneTree
## Regression for the previously delivered straight-tower reference geometry.
## Rendering only: game input, completion timing and rewards stay in existing
## test_phone_mechanism_feedback and test_phone_effects coverage.
const Art=preload("res://scripts/ui/phone_home_art.gd")
var checks=0
var failures=0
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		push_error(message)
func _initialize() -> void:
	for rect in [Art.TOWER_TOP,Art.TOWER_CAP,Art.TOWER_BODY,Art.TOWER_PORTAL,Art.TOWER_LANDING,Art.TOWER_PLINTH]:
		check(is_equal_approx(rect.get_center().x,325),"Tower structural pieces share reference axis x325")
	check(Art.TOWER_BODY==Rect2(303,176,44,268),"Shaft and clock/key anchor retain source geometry")
	check(Art.TOWER_PORTAL==Rect2(301,400,48,78),"Reference portal is under shaft, not right-offset")
	check(Art.TOWER_PORTAL.position.y<Art.TOWER_BODY.end.y,"Portal overlaps and covers the shaft footing")
	check(Art.TOWER_LANDING.position.y<=Art.TOWER_PORTAL.end.y,"Portal is supported by landing")
	var previous: Rect2=Art.TOWER_LANDING
	for i in range(6):
		var step: Rect2=Art.tower_step(i)
		check(step==Rect2(290-i*5,485+i*18,70+i*10,18),"Reference frontal step dimensions "+str(i))
		check(is_equal_approx(step.get_center().x,325),"Steps remain aligned to tower")
		check(step.position.y<=previous.end.y,"Adjacent stair risers do not expose background")
		check(step.size.x>previous.size.x,"Stair widens toward foreground")
		previous=step
	var source=FileAccess.get_file_as_string("res://scripts/ui/phone_home_art.gd")
	var shaft=source.find("\n\t_draw_tower()")
	var portal=source.find("\n\tbox(TOWER_PORTAL")
	var tree=source.find("\n\tbox(Rect2(385,502,14,100)")
	check(shaft>=0 and portal>shaft and tree>portal,"Paint order is shaft then full portal then foreground tree")
	check(source.contains("draw_circle(Vector2(325,224),8"),"Original keyhole input anchor is unchanged")
	for scale in [1.0,390.0/430.0,812.0/860.0]:
		check(is_equal_approx(Art.TOWER_PORTAL.get_center().x*scale,Art.TOWER_BODY.get_center().x*scale),"Uniform viewport scaling cannot separate shaft and footing")
	print("PHONE_TOWER_ALIGNMENT: ",checks," checks; ",failures," failures")
	quit(0 if failures==0 else 1)
