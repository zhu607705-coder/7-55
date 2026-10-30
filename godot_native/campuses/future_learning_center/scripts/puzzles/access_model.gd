extends RefCounted
## Axis coordinate x; lid motion is evaluated in the perpendicular (depth,height) plane.
const HOLES := [365.0,505.0]
const SHAFT_LENGTH := 160.0
const SHAFT_START := 170.0
const MAX_INSERTION := 185.0
const ENTRY_LIP := Rect2(330,-9,10,18)
const BODY_SECTION := Rect2(0,-80,180,70)
var supports: Array[bool] = [true,true]
var insertion := 0.0
var cover := true
var angle := 0.0
var loose := false
var side := 0
var revision := 0
var opened_revision := -1
var completed := false
var extension_completed := false
var contact := Vector2.INF
var contact_kind := ""
var outcome := ""
var history: Array[Dictionary] = []
var _gesture: Dictionary = {}
func screen_x(x:float)->float:return x if side==0 else 880-x
func shaft_rect(at:float=-1)->Rect2:
	return Rect2(SHAFT_START+(insertion if at<0 else at),-4,SHAFT_LENGTH,8)
func through_hole(i:int)->bool:
	var rect:=shaft_rect()
	return supports[i] and rect.position.x<=HOLES[i]-5 and rect.end.x>=HOLES[i]+5
func connected()->bool:return through_hole(0) and through_hole(1)
func snapshot()->Dictionary:return {"supports":supports.duplicate(),"insertion":insertion,"cover":cover,"angle":angle,"side":side,"loose":loose}
func begin_gesture()->void:
	if _gesture.is_empty():_gesture=snapshot()
func end_gesture()->void:
	if not _gesture.is_empty() and _gesture!=snapshot():
		history.append(_gesture)
		if history.size()>40:history.pop_front()
	_gesture={}
func cancel_pointer()->void:end_gesture()
func _changed()->void:revision+=1;opened_revision=-1;loose=false;outcome=""
func set_support(i:int,value:bool)->bool:
	if i not in [0,1]:return false
	if supports[i]==value:return true
	var r:=shaft_rect()
	if r.position.x<HOLES[i]+12 and r.end.x>HOLES[i]-12:
		contact=Vector2(HOLES[i],0);contact_kind="support";outcome="轴仍穿在支撑孔内";return false
	begin_gesture();supports[i]=value;_changed();end_gesture();return true
func set_cover(value:bool)->bool:
	if cover==value:return true
	if value and shaft_rect().intersects(ENTRY_LIP):
		contact=ENTRY_LIP.get_center();contact_kind="entry";outcome="盖侧唇碰到轴";return false
	begin_gesture();cover=value;angle=0;_changed();end_gesture();return true
func set_side(value:int)->bool:
	if value not in [0,1] or cover or insertion>.01:return false
	if value==side:return true
	begin_gesture();side=value;_changed();end_gesture();return true
func slide_to(target:float)->bool:
	if not is_finite(target):return false
	var delta:=clampf(target,0,MAX_INSERTION)-insertion
	var steps:=ceili(absf(delta)/.5)
	if steps==0:return false
	contact=Vector2.INF;contact_kind=""
	var increment:=delta/steps
	var moved:=false
	for i:int in steps:
		var next:=insertion+increment
		var rect:=shaft_rect(next)
		if cover and rect.intersects(ENTRY_LIP):
			contact=Vector2(ENTRY_LIP.position.x,0);contact_kind="entry";outcome="侧安装口被盖住";break
		insertion=next;moved=true
	if moved:_changed()
	return moved
func lid_section(at:float=-1)->Vector2:
	var a:=angle if at<0 else at
	return Vector2(cos(a),sin(a))*180
func cover_clear(at:float)->bool:
	# The shell bottom and back wall are actual section rectangles, not angle-stage rules.
	var end:=lid_section(at)
	for rect:Rect2 in [BODY_SECTION,Rect2(-22,-80,12,200)]:
		var expanded:=rect.grow(2)
		var corners:=[expanded.position,Vector2(expanded.end.x,expanded.position.y),expanded.end,Vector2(expanded.position.x,expanded.end.y)]
		for i:int in 4:
			if Geometry2D.segment_intersects_segment(Vector2.ZERO,end,corners[i],corners[(i+1)%4])!=null:return false
	return true
func swing_to(target:float)->bool:
	if not is_finite(target) or not cover:return false
	if not connected():
		loose=true;angle=clampf(target,0,.14);opened_revision=-1;outcome="盖片歪斜：轴未贯穿双孔";return false
	loose=false
	var delta:=clampf(target,0,PI/2)-angle
	var steps:=ceili(absf(delta)/.003)
	if steps==0:return false
	var increment:=delta/steps
	var moved:=false
	for i:int in steps:
		var next:=angle+increment
		if not cover_clear(next):contact=lid_section(next);contact_kind="shell";break
		angle=next;moved=true
		if angle>=PI/2-.012:opened_revision=revision
		if angle<=.008 and opened_revision==revision:
			completed=true
			if side==1:extension_completed=true
			outcome="双孔连接有效，已实际开合"
	return moved
func undo()->bool:
	end_gesture()
	if history.is_empty():return false
	var old:Dictionary=history.pop_back()
	supports.assign(old.supports);insertion=old.insertion;cover=old.cover;angle=old.angle;side=old.side
	_changed();loose=old.loose;contact=Vector2.INF;contact_kind="";return true
