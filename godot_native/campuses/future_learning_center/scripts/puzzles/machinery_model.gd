extends RefCounted
## Enclosed foam demonstration, no machine-control or story-material authority.
const FRAME:=Rect2(300,180,360,200)
const PART_START:=Vector2(420,250)
const PART_SIZE:=Vector2(120,80)
const TRAY:=Rect2(100,230,760,125)
const CLAMPS:=[Rect2(650,240,30,100),Rect2(280,240,30,100),Rect2(455,170,50,38)]
const PATHS:=[ [Vector2(455,270),Vector2(490,270),Vector2(490,290)], [Vector2(525,250),Vector2(525,275),Vector2(540,275)], [Vector2(540,276),Vector2(540,304)] ]
var variant:=0
var clamp_slot:=0
var displacement:=Vector2.ZERO
var progress:Array[float]=[0.0,0.0,0.0]
var kerfs:Array=[PackedVector2Array(),PackedVector2Array(),PackedVector2Array()]
var running:=false
var active_cut:=-1
var cutter:=Vector2.INF
var completed:=false
var extension_completed:=false
var outcome:=""
var contact:=Vector2.INF
var contact_kind:=""
var history:Array[Dictionary]=[]
var _gesture:Dictionary={}
func mirrored(p:Vector2)->Vector2:return p if variant==0 else Vector2(960-p.x,p.y)
func mirrored_rect(r:Rect2)->Rect2:return r if variant==0 else Rect2(960-r.end.x,r.position.y,r.size.x,r.size.y)
func part_rect(at:Vector2=Vector2.INF)->Rect2:return Rect2(PART_START+(displacement if not at.is_finite() else at),PART_SIZE)
func clamp_rect()->Rect2:return Rect2() if clamp_slot<0 else mirrored_rect(CLAMPS[clamp_slot])
func bridge_intact()->bool:return progress[2]<1
func path(index:int)->PackedVector2Array:
	var result:=PackedVector2Array()
	for p:Vector2 in PATHS[index]:result.append(mirrored(p))
	return result
func path_length(line:PackedVector2Array)->float:
	var result:=0.0
	for i:int in range(1,line.size()):result+=line[i-1].distance_to(line[i])
	return result
func path_point(line:PackedVector2Array,fraction:float)->Vector2:
	var remaining:=path_length(line)*clampf(fraction,0,1)
	for i:int in range(1,line.size()):
		var length:=line[i-1].distance_to(line[i])
		if remaining<=length:return line[i-1].lerp(line[i],remaining/maxf(.001,length))
		remaining-=length
	return line[-1]
func supported()->bool:return TRAY.encloses(part_rect())
func frame_held()->bool:return clamp_slot>=0 and clamp_rect().intersects(FRAME)
func snapshot()->Dictionary:return {"variant":variant,"clamp":clamp_slot,"displacement":displacement,"progress":progress.duplicate(),"kerfs":kerfs.duplicate(true),"active_cut":active_cut,"cutter":cutter}
func begin_gesture()->void:
	if _gesture.is_empty():_gesture=snapshot()
func end_gesture()->void:
	if not _gesture.is_empty() and _gesture!=snapshot():
		history.append(_gesture)
		if history.size()>40:history.pop_front()
	_gesture={}
func cancel()->void:running=false;end_gesture()
func reset(next_variant:int=-1)->void:
	cancel()
	if next_variant in [0,1]:variant=next_variant
	clamp_slot=0;displacement=Vector2.ZERO;progress=[0.0,0.0,0.0];kerfs=[PackedVector2Array(),PackedVector2Array(),PackedVector2Array()]
	active_cut=-1;cutter=Vector2.INF;outcome="";contact=Vector2.INF;contact_kind="";history.clear()
func place_clamp(slot:int)->bool:
	if slot not in [-1,0,1,2] or running:return false
	if slot==clamp_slot:return true
	var target:Rect2=Rect2() if slot<0 else mirrored_rect(CLAMPS[slot])
	if target.has_area() and target.intersects(part_rect()):contact=target.intersection(part_rect()).get_center();contact_kind="clamp";return false
	begin_gesture();clamp_slot=slot;outcome="";end_gesture();return true
func start_cut(index:int)->bool:
	if index not in [0,1,2] or running or progress[index]>=1:return false
	if not supported() or not frame_held():outcome="试件没有稳定承托或外框未夹住";return false
	if absf(displacement.x)>.1:outcome="试件已离开加工基准";return false
	var line:=path(index)
	for i:int in range(1,line.size()):
		var r:=clamp_rect().grow(4)
		if r.has_point(line[i-1]) or r.has_point(line[i]):contact=r.get_center();contact_kind="clamp";return false
		var corners:=[r.position,Vector2(r.end.x,r.position.y),r.end,Vector2(r.position.x,r.end.y)]
		for edge:int in 4:
			var hit=Geometry2D.segment_intersects_segment(line[i-1],line[i],corners[edge],corners[(edge+1)%4])
			if hit!=null:contact=hit;contact_kind="clamp";return false
	begin_gesture();active_cut=index;running=true;outcome="";contact=Vector2.INF;contact_kind=""
	if kerfs[index].is_empty():kerfs[index].append(path_point(line,progress[index])-part_rect().position)
	return true
func step(dt:float)->void:
	if not running or not is_finite(dt) or dt<=0:return
	var remaining:=dt
	while remaining>0 and running:
		var tick:=minf(.04,remaining);remaining-=tick
		progress[active_cut]=minf(1,progress[active_cut]+tick/1.0)
		# After the bridge is severed, cutter force displaces the unregistered sample on its tray.
		if active_cut!=2 and not bridge_intact():displacement.y=minf(14,displacement.y+tick*35)
		cutter=path_point(path(active_cut),progress[active_cut])
		kerfs[active_cut].append(cutter-part_rect().position)
		if progress[active_cut]>=1:
			running=false;outcome="本段已切完" if valid_cut(active_cut) else "试件移动，切口偏离轮廓片";end_gesture()
func valid_cut(index:int)->bool:
	if progress[index]<1 or kerfs[index].size()<2:return false
	var desired:=path(index)
	for point:Vector2 in kerfs[index]:
		var absolute:=point+PART_START
		var distance:=INF
		for j:int in range(1,desired.size()):distance=minf(distance,absolute.distance_to(Geometry2D.get_closest_point_to_segment(absolute,desired[j-1],desired[j])))
		if distance>1:return false
	return true
func geometry_matches()->bool:return valid_cut(0) and valid_cut(1) and valid_cut(2)
func extract_to(target_x:float)->bool:
	if not is_finite(target_x) or running:return false
	if bridge_intact():contact=path_point(path(2),.5);contact_kind="bridge";outcome="连接桥还连着外框";return false
	var delta:=target_x-part_rect().position.x
	var count:=ceili(absf(delta))
	if count==0:return false
	var increment:=delta/count
	contact=Vector2.INF;contact_kind=""
	var moved:=false
	for i:int in mini(count,1000):
		var candidate:=displacement+Vector2(increment,0);var rect:=part_rect(candidate)
		if not TRAY.encloses(rect):contact=rect.get_center();contact_kind="edge";break
		if clamp_slot>=0 and rect.intersects(clamp_rect()):contact=rect.intersection(clamp_rect()).get_center();contact_kind="clamp";break
		# Only the intended side is open. The opposite frame edge remains a solid wall.
		if (variant==0 and rect.position.x<FRAME.position.x) or (variant==1 and rect.end.x>FRAME.end.x):contact=rect.get_center();contact_kind="frame";break
		displacement=candidate;moved=true
	if geometry_matches() and supported() and ((variant==0 and part_rect().position.x>=FRAME.end.x+20) or (variant==1 and part_rect().end.x<=FRAME.position.x-20)):
		completed=true
		if variant==1:extension_completed=true
		outcome="完整样件已从通道取出"
	elif not contact_kind.is_empty():outcome="样件碰到夹具或边缘"
	return moved
func undo()->bool:
	cancel()
	if history.is_empty():return false
	var old:Dictionary=history.pop_back()
	variant=old.variant;clamp_slot=old.clamp;displacement=old.displacement;progress.assign(old.progress);kerfs=old.kerfs.duplicate(true);active_cut=old.active_cut;cutter=old.cutter
	contact=Vector2.INF;contact_kind="";outcome="";return true
