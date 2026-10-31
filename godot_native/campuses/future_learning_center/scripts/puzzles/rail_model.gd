extends RefCounted
## Grid track occupancy includes the tail and the swept cells of every step.
var positions: Array[int] = [0,8]
var lengths: Array[int] = [1,1]
var siding := false
var extension_trial_armed := false
var extension := false
var completed := false
var extension_completed := false
var running := false
var paused := false
var cart := -1
var destination := -1
var elapsed := 0.0
var blocked := -1
var history: Array[Dictionary] = []
# A resting cart may be between two nodes; never teleport it on mouse release.
var edge_to:Array[int]=[-1,-1]
var edge_fraction:Array[float]=[0.0,0.0]
var drag_cart:=-1
var drag_snapshot:Dictionary={}
var auto_return:=false
static func point(cell:int)->Vector2:return Vector2(480,174) if cell==9 else Vector2(160+cell*80,310)
func pose(id:int)->Vector2:
	return point(positions[id]).lerp(point(edge_to[id]),edge_fraction[id]) if edge_to[id]>=0 else point(positions[id])
func tail_pose(id:int)->Vector2:
	var at:=point(occupied(id)[1])
	return at.lerp(point(occupied(id,edge_to[id])[1]),edge_fraction[id]) if edge_to[id]>=0 else at
func snapshot()->Dictionary:return {"positions":positions.duplicate(),"siding":siding,"edge_to":edge_to.duplicate(),"edge_fraction":edge_fraction.duplicate()}
func restore(old:Dictionary)->void:
	positions.assign(old.positions);siding=old.siding;edge_to.assign(old.get("edge_to",[-1,-1]));edge_fraction.assign(old.get("edge_fraction",[0.0,0.0]))
func occupied_swept(id:int)->Array[int]:
	var cells:=occupied(id)
	if edge_to[id]>=0:
		for cell:int in occupied(id,edge_to[id]):
			if cell not in cells:cells.append(cell)
	return cells
func begin_drag(id:int)->bool:
	if id<0 or id>1 or running or drag_cart>=0:return false
	drag_cart=id;drag_snapshot=snapshot();blocked=-1;return true
func drag_to(at:Vector2)->void:
	if drag_cart<0 or not at.is_finite():return
	var id:=drag_cart
	for _iteration:int in 24:
		var anchor:int=positions[id]
		if edge_to[id]>=0:
			var segment:=point(edge_to[id])-point(anchor)
			var fraction:=clampf((at-point(anchor)).dot(segment)/segment.length_squared(),0,1)
			edge_fraction[id]=fraction
			if fraction>0 and fraction<1:return
			if fraction>=1:positions[id]=edge_to[id]
			edge_to[id]=-1;edge_fraction[id]=0
			if fraction<=0 and at.distance_to(point(anchor))<.01:return
			continue
		var goal:=anchor
		if anchor==9:goal=4 if at.y>174.01 else 9
		elif absf(at.x-480)<40 and at.y<309.99:goal=9
		elif at.x>point(anchor).x+.01:goal=clampi(ceili((at.x-160)/80),0,8)
		elif at.x<point(anchor).x-.01:goal=clampi(floori((at.x-160)/80),0,8)
		if goal==anchor:return
		var next:=next_cell(anchor,goal)
		if not can_move(id,next):blocked=next;return
		edge_to[id]=next
func end_drag()->void:
	if drag_cart<0:return
	var id:=drag_cart
	if edge_to[id]>=0:
		var length:=point(positions[id]).distance_to(point(edge_to[id]))
		if edge_fraction[id]*length<=10:edge_to[id]=-1;edge_fraction[id]=0
		elif (1-edge_fraction[id])*length<=10:positions[id]=edge_to[id];edge_to[id]=-1;edge_fraction[id]=0
	if snapshot()!=drag_snapshot:history.append(drag_snapshot)
	drag_cart=-1;drag_snapshot={};_check_completion()
func cancel_drag()->void:
	if drag_cart>=0:restore(drag_snapshot)
	drag_cart=-1;drag_snapshot={};blocked=-1
func _check_completion()->void:
	if positions==[8,0] and edge_to==[-1,-1]:
		completed=true
		if extension and extension_trial_armed:extension_completed=true
func occupied(id:int, at:int=-1)->Array[int]:
	if at<0:at=positions[id]
	if lengths[id]==1:return [at]
	if at==9:return [9,4]
	return [at,at-1]
func set_extension(value:bool)->void:
	cancel_drag();cancel();edge_to.assign([-1,-1]);edge_fraction.assign([0.0,0.0]);extension=value;extension_trial_armed=value;lengths.assign([2,1] if value else [1,1]);positions.assign([1,8] if value else [0,8]);siding=false;history.clear();blocked=-1
func couple_trailer(attach:bool)->bool:
	if running or drag_cart>=0 or edge_to[0]>=0 or attach==extension:return false
	if attach:
		var tail:=4 if positions[0]==9 else positions[0]-1
		if tail<0 or tail in occupied_swept(1):return false
	lengths[0]=2 if attach else 1
	extension=attach;extension_trial_armed=attach and positions==[1,8];history.clear();blocked=-1
	return true
func toggle_switch()->void:
	# Do not move a switch blade through a vehicle straddling its joint.
	for id:int in 2:
		if edge_to[id]>=0 and (positions[id] in [4,9] or edge_to[id] in [4,9]):return
	cancel_drag();cancel();siding=not siding;blocked=-1
func dispatch(id:int,target:int)->bool:
	if id<0 or id>1 or target<0 or target>9 or running or drag_cart>=0:return false
	if target==positions[id] and edge_to[id]<0:return false
	cart=id;destination=target;running=true;paused=false;elapsed=0;blocked=-1;auto_return=false
	if edge_to[id]>=0:
		auto_return=target==positions[id] or next_cell(positions[id],target)!=edge_to[id]
		elapsed=(1-edge_fraction[id] if auto_return else edge_fraction[id])*.3
	return true
func next_cell(at:int,target:int)->int:
	if at==9:return 4
	if target==9:return 9 if at==4 else at+int(sign(4-at))
	return at+int(sign(target-at))
func can_move(id:int,next:int)->bool:
	if id<0 or id>1 or next<0 or next>9:return false
	var at:int=positions[id]
	if at==9 or next==9:
		if not siding or (at!=4 and next!=4):return false
	elif absi(next-at)!=1 or (siding and (at==4 or next==4)):return false
	var cells:=occupied(id,next)
	for cell:int in cells:
		if cell<0 or cell>9:return false
	# A two-unit load still occupies the junction while parked in the one-unit siding.
	var swept:=occupied(id)
	for cell:int in cells:
		if cell not in swept:swept.append(cell)
	for cell:int in occupied_swept(1-id):
		if cell in swept:return false
	return true
func advance()->bool:
	if not running or paused:return false
	if auto_return:
		history.append(snapshot());edge_to[cart]=-1;edge_fraction[cart]=0;auto_return=false
		if positions[cart]==destination:cancel()
		return true
	var next:=next_cell(positions[cart],destination)
	if not can_move(cart,next):blocked=next;cancel();return false
	history.append(snapshot())
	positions[cart]=next;edge_to[cart]=-1;edge_fraction[cart]=0
	_check_completion()
	if positions[cart]==destination:cancel()
	return true
func step(dt:float)->void:
	if not running or paused or drag_cart>=0 or not is_finite(dt) or dt<=0:return
	elapsed+=dt
	while elapsed>=0.3 and running:
		elapsed-=0.3;advance()
func pause()->void:
	if running:paused=true
func resume()->bool:
	if not running or not paused:return false
	paused=false;return true
func cancel()->void:running=false;paused=false;elapsed=0
func undo()->bool:
	cancel_drag();cancel()
	if history.is_empty():return false
	var old:Dictionary=history.pop_back();restore(old);blocked=-1;return true
