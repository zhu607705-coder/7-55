extends RefCounted
## A supported tabletop cabinet model. Sweeps use actual box footprints.
const STARTS := [Vector2(250,258),Vector2(435,255),Vector2(535,255)]
const SIZES := [Vector2(180,64),Vector2(70,70),Vector2(70,70)]
const SUPPORT := [Rect2(220,230,400,120),Rect2(520,150,100,80),Rect2(620,230,230,120),Rect2(620,350,100,80)]
const HINGE := Vector2(620,230)
const DOOR_LENGTH := 120.0
var positions: Array[Vector2] = [STARTS[0],STARTS[1],STARTS[2]]
var door_angle := 0.0
var contact := Vector2.INF
var contact_kind := ""
var taken := false
var returned := false
var completed := false
var revision := 0
var history: Array[Dictionary] = []
var _gesture: Dictionary = {}

func box(index: int, at := Vector2.INF) -> Rect2:
	return Rect2(positions[index] if not at.is_finite() else at,SIZES[index])
func door_tip(angle := -1.0) -> Vector2:
	var a := door_angle if angle < 0 else angle
	return HINGE + Vector2(sin(a),cos(a))*DOOR_LENGTH
func snapshot() -> Dictionary:
	return {"positions":positions.duplicate(),"door_angle":door_angle}
func begin_gesture() -> void:
	if _gesture.is_empty(): _gesture = snapshot()
func end_gesture() -> void:
	if _gesture.is_empty(): return
	if _gesture.positions != positions or not is_equal_approx(_gesture.door_angle,door_angle):
		history.append(_gesture)
		if history.size()>32: history.pop_front()
	_gesture = {}
func cancel_gesture() -> void:
	# Loss of contact retains only already swept, legal positions. No teleport rollback.
	end_gesture()
func undo() -> bool:
	end_gesture()
	if history.is_empty(): return false
	var old: Dictionary = history.pop_back()
	positions.assign(old.positions); door_angle = old.door_angle
	revision += 1; contact=Vector2.INF; contact_kind=""
	return true
func reset() -> void:
	positions.assign(STARTS); door_angle=0; contact=Vector2.INF;contact_kind=""
	history.clear();_gesture={};revision+=1
	# Completed observations remain recorded, but a fresh take/return sequence restarts.
	taken=false; returned=false
func is_supported(rect: Rect2) -> bool:
	# Union coverage is exact for these rectilinear support tiles: test all induced cells.
	var xs: Array[float]=[rect.position.x,rect.end.x]
	var ys: Array[float]=[rect.position.y,rect.end.y]
	for area: Rect2 in SUPPORT:
		for x: float in [area.position.x,area.end.x]:
			if x>rect.position.x and x<rect.end.x: xs.append(x)
		for y: float in [area.position.y,area.end.y]:
			if y>rect.position.y and y<rect.end.y: ys.append(y)
	xs.sort();ys.sort()
	for xi: int in xs.size()-1:
		for yi: int in ys.size()-1:
			var p:=Vector2((xs[xi]+xs[xi+1])/2,(ys[yi]+ys[yi+1])/2)
			var supported:=false
			for area:Rect2 in SUPPORT:
				if area.has_point(p): supported=true;break
			if not supported:return false
	return true
func _door_hits(rect: Rect2, angle:float) -> bool:
	var expanded:=rect.grow(6)
	var tip:=door_tip(angle)
	if expanded.has_point(HINGE) or expanded.has_point(tip):return true
	var corners:=[expanded.position,Vector2(expanded.end.x,expanded.position.y),expanded.end,Vector2(expanded.position.x,expanded.end.y)]
	for i:int in 4:
		if Geometry2D.segment_intersects_segment(HINGE,tip,corners[i],corners[(i+1)%4])!=null:return true
	return false
func legal(index:int,at:Vector2)->bool:
	if index<0 or index>=3 or not at.is_finite():return false
	var rect:=box(index,at)
	if not is_supported(rect):contact=rect.get_center();contact_kind="support";return false
	for i:int in 3:
		if i!=index and rect.intersects(box(i)):
			contact=rect.intersection(box(i)).get_center();contact_kind="box";return false
	if _door_hits(rect,door_angle):contact=Geometry2D.get_closest_point_to_segment(rect.get_center(),HINGE,door_tip());contact_kind="door";return false
	return true
func move_box(index:int,target:Vector2)->bool:
	if index<0 or index>=3 or not target.is_finite():return false
	var delta:=target-positions[index]
	if delta.length_squared()<.0001:return false
	# Only one axis per input segment. Diagonal pointer jumps cannot cut corners.
	delta=Vector2(delta.x,0) if absf(delta.x)>=absf(delta.y) else Vector2(0,delta.y)
	var steps:=ceili(delta.length())
	var increment:=delta/maxi(1,steps)
	var moved:=false
	contact=Vector2.INF;contact_kind=""
	for _i:int in mini(steps,2000):
		var next:=positions[index]+increment
		if not legal(index,next):break
		positions[index]=next;moved=true
	if moved:
		revision+=1
		if box(0).position.x>626:taken=true;completed=true
		if taken and positions[0].distance_to(STARTS[0])<8:returned=true
	return moved
func swing_to(angle:float)->bool:
	if not is_finite(angle):return false
	var target:=clampf(angle,0,PI/2)
	var delta:=target-door_angle
	var count:=ceili(absf(delta)/.006)
	if count==0:return false
	var step:=delta/count
	contact=Vector2.INF;contact_kind=""
	var moved:=false
	for _i:int in count:
		var next:=door_angle+step
		var blocked:=false
		for i:int in 3:
			if _door_hits(box(i),next):contact=Geometry2D.get_closest_point_to_segment(box(i).get_center(),HINGE,door_tip(next));contact_kind="door";blocked=true;break
		if blocked:break
		door_angle=next;moved=true
	if moved:revision+=1
	return moved
