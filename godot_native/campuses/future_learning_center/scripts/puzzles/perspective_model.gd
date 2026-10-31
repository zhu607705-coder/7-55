extends RefCounted
## Fixed world coordinates; observer and loose-paper rotations never move pieces.
const TURNS:=[0,2,1]
const CONSTRAINTS:=[{0:0,3:3},{1:2,2:1},{0:2,3:1}]
var slots:Array[int]=[0,2,1,3]
var paper_turns:Array[int]=[0,0,0]
var observer:=0
var extension:=false
var revision:=0
var receipts:Dictionary={}
var history:Array[Array]=[]
var completed:=false
var extension_completed:=false
var running:=false
var paused:=false
var elapsed:=0.0
var trial_revision:=-1
var trial_observer:=0
var outcome:=""
static func rotated_slot(slot:int,turns:int)->int:
	var x:int=slot%2;var y:int=slot/2
	for i:int in posmod(turns,4):
		var previous:=x;x=1-y;y=previous
	return y*2+x
func observed(view:int)->Array[int]:
	var result:Array[int]=[-1,-1,-1,-1]
	for slot:int in 4:result[rotated_slot(slot,TURNS[view])]=slots[slot]
	return result
func matches(view:int)->bool:
	var image:=observed(view)
	for slot:int in CONSTRAINTS[view]:
		if image[slot]!=CONSTRAINTS[view][slot]:return false
	return true
func place(piece:int,slot:int)->bool:
	if piece<0 or piece>3 or slot<0 or slot>3:return false
	var old:int=slots.find(piece)
	if old==slot:return true
	history.append(slots.duplicate());slots[old]=slots[slot];slots[slot]=piece;_invalidate();return true
func _invalidate()->void:revision+=1;receipts.clear();cancel();outcome=""
func undo()->bool:
	if history.is_empty():return false
	slots.assign(history.pop_back());_invalidate();return true
func rotate_paper(photo:int)->bool:
	if photo<0 or photo>2 or (photo==2 and not extension):return false
	paper_turns[photo]=(paper_turns[photo]+1)%4;return true
func observe(view:int)->bool:
	if view<0 or view>2 or (view==2 and not extension):return false
	cancel();observer=view;return true
func set_extension(value:bool)->void:
	if extension==value:return
	extension=value;cancel();receipts.erase(2)
	if not value and observer==2:observer=0
func start()->bool:
	if running:return false
	running=true;paused=false;elapsed=0;trial_revision=revision;trial_observer=observer;outcome="";return true
func cancel()->void:running=false;paused=false;elapsed=0
func pause()->void:paused=true
func resume()->void:paused=false
func step(dt:float)->void:
	if not running or paused or not is_finite(dt) or dt<=0:return
	elapsed+=minf(dt,.1)
	if elapsed<.55:return
	running=false
	if trial_revision!=revision:return
	var passed:=matches(trial_observer)
	receipts[trial_observer]={"revision":revision,"passed":passed};outcome="可见模型与照片一致" if passed else "照片里的位置不同"
	if current_passed(false):completed=true
	if extension and current_passed(true):extension_completed=true
func current_passed(include_extension:bool=false)->bool:
	for view:int in (3 if include_extension else 2):
		var receipt:Dictionary=receipts.get(view,{})
		if receipt.is_empty() or receipt.revision!=revision or not receipt.passed:return false
	return true
