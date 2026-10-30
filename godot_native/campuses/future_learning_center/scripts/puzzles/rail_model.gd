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
func occupied(id:int, at:int=-1)->Array[int]:
	if at<0:at=positions[id]
	if lengths[id]==1:return [at]
	if at==9:return [9,4]
	return [at,at-1]
func set_extension(value:bool)->void:
	cancel();extension=value;extension_trial_armed=value;lengths.assign([2,1] if value else [1,1]);positions.assign([1,8] if value else [0,8]);siding=false;history.clear();blocked=-1
func couple_trailer(attach:bool)->bool:
	if running or attach==extension:return false
	if attach:
		var tail:=4 if positions[0]==9 else positions[0]-1
		if tail<0 or tail in occupied(1):return false
	lengths[0]=2 if attach else 1
	extension=attach;extension_trial_armed=attach and positions==[1,8];history.clear();blocked=-1
	return true
func toggle_switch()->void:cancel();siding=not siding;blocked=-1
func dispatch(id:int,target:int)->bool:
	if id<0 or id>1 or target<0 or target>9 or running:return false
	if target==positions[id]:return false
	cart=id;destination=target;running=true;paused=false;elapsed=0;blocked=-1;return true
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
	for cell:int in occupied(1-id):
		if cell in swept:return false
	return true
func advance()->bool:
	if not running or paused:return false
	var next:=next_cell(positions[cart],destination)
	if not can_move(cart,next):blocked=next;cancel();return false
	history.append({"positions":positions.duplicate(),"siding":siding})
	positions[cart]=next
	if positions==[8,0]:
		completed=true
		if extension and extension_trial_armed:extension_completed=true
	if positions[cart]==destination:cancel()
	return true
func step(dt:float)->void:
	if not running or paused or not is_finite(dt) or dt<=0:return
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
	cancel()
	if history.is_empty():return false
	var old:Dictionary=history.pop_back();positions.assign(old.positions);siding=old.siding;blocked=-1;return true
