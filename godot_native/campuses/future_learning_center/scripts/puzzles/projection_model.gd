extends RefCounted
## One voxel geometry drives both projections and the visible supported pieces.
const PIECES := [[Vector2i(0,0),Vector2i(0,1),Vector2i(0,2),Vector2i(1,2)], [Vector2i(1,0),Vector2i(2,0),Vector2i(2,1),Vector2i(2,2)]]
var depths:Array[int]=[0,0]
var heights:Array[int]=[0,0]
var geometry_revision:=0
var receipts:Dictionary={}
var history:Array[Dictionary]=[]
var extension:=false
var completed:=false
var extension_completed:=false
var view_side:=0
var angle:=0.0
var paused:=false
var running:=false
var elapsed:=0.0
var trial_revision:=-1
var trial_side:=0
var outcome:=""
func voxels(piece:int,ds:Array=[],hs:Array=[])->Array[Vector3i]:
	if ds.is_empty():ds=depths
	if hs.is_empty():hs=heights
	var result:Array[Vector3i]=[]
	for cell:Vector2i in PIECES[piece]:result.append(Vector3i(cell.x,ds[piece],cell.y+hs[piece]))
	return result
func projection(side:int,ds:Array=[],hs:Array=[])->Dictionary:
	var result:Dictionary={}
	for piece:int in 2:
		for cell:Vector3i in voxels(piece,ds,hs):result[Vector2i(cell.x if side==0 else cell.y,cell.z)]=true
	return result
func target(side:int)->Dictionary:return projection(side,[0,2],[1,0] if extension else [0,0])
func visible_cell(side:int,cell:Vector2i)->bool:return not (extension and side==0 and cell.y==3)
func matches(side:int)->bool:
	var actual:=projection(side);var wanted:=target(side)
	for x:int in 4:
		for z:int in 4:
			var cell:=Vector2i(x,z)
			if visible_cell(side,cell) and actual.has(cell)!=wanted.has(cell):return false
	return true
func legal()->bool:
	for i:int in 2:
		if depths[i]<0 or depths[i]>3 or heights[i]<0 or heights[i]>1:return false
	for cell:Vector3i in voxels(0):
		if cell in voxels(1):return false
	return true
func _invalidate()->void:geometry_revision+=1;receipts.clear();cancel();outcome=""
func place(piece:int,depth:int,height:int)->bool:
	if drag_piece>=0 or piece not in [0,1] or depth<0 or depth>3 or height<0 or height>1:return false
	if depths[piece]==depth and heights[piece]==height:return true
	history.append({"depths":depths.duplicate(),"heights":heights.duplicate()})
	depths[piece]=depth;heights[piece]=height;_invalidate();return true
func undo()->bool:
	if history.is_empty():return false
	var old:Dictionary=history.pop_back();depths.assign(old.depths);heights.assign(old.heights);_invalidate();return true
func set_extension(value:bool)->void:
	if value==extension:return
	extension=value;_invalidate()
func rotate_fixture()->void:
	if drag_piece>=0:return
	cancel();view_side=1-view_side;paused=false
func settled()->bool:return absf(angle-view_side*PI/2)<.001
func start()->bool:
	if running or drag_piece>=0 or not settled() or not legal():return false
	running=true;paused=false;elapsed=0;trial_revision=geometry_revision;trial_side=view_side;outcome="";return true
func pause()->void:paused=true
func resume()->void:paused=false
func cancel()->void:running=false;elapsed=0;paused=false
func step(dt:float)->void:
	if paused or not is_finite(dt) or dt<=0:return
	angle=move_toward(angle,view_side*PI/2,minf(dt,.1)*PI)
	if not running:return
	elapsed+=minf(dt,.1)
	if elapsed<.6:return
	running=false
	if trial_revision!=geometry_revision:return
	var passed:=matches(trial_side)
	receipts[trial_side]={"revision":geometry_revision,"passed":passed}
	outcome="轮廓吻合" if passed else "轮廓有差异"
	if current_passed():
		completed=true
		if extension:extension_completed=true
func current_passed()->bool:
	for side:int in 2:
		var r:Dictionary=receipts.get(side,{})
		if r.is_empty() or r.revision!=geometry_revision or not r.passed:return false
	return legal()

# Manipulation is a transient supported pose, committed once on release.
var drag_piece:=-1
var preview_depth:=0.0
var preview_height:=0.0
func begin_drag(piece:int)->bool:
	if piece not in [0,1] or drag_piece>=0 or not settled():return false
	cancel();drag_piece=piece;preview_depth=depths[piece];preview_height=heights[piece];return true
func update_drag(depth:float,height:float)->bool:
	if drag_piece<0 or not is_finite(depth) or not is_finite(height):return false
	preview_depth=clampf(depth,0,3);preview_height=clampf(height,0,1);return true
func cancel_drag()->void:drag_piece=-1
func displayed_pose(piece:int)->Vector2:
	return Vector2(preview_depth,preview_height) if piece==drag_piece else Vector2(depths[piece],heights[piece])
func displayed_voxels(piece:int)->Array[Vector3]:
	var result:Array[Vector3]=[];var pose:=displayed_pose(piece)
	for p:Vector2i in PIECES[piece]:result.append(Vector3(p.x,pose.x,p.y+pose.y))
	return result
func commit_drag()->bool:
	if drag_piece<0:return false
	var id:=drag_piece;var d:=roundi(preview_depth);var h:=roundi(preview_height)
	cancel_drag();return place(id,d,h)
