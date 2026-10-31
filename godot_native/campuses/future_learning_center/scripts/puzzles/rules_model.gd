extends RefCounted
## Stable hidden relation; tile experiments are observable model facts.
const TILE_COUNT := 6
var slots: Array[int] = [-1,-1,-1,-1]
var true_rule := 0 # shape; 1 selects fill for a separately seeded session.
var running := false
var paused := false
var elapsed := 0.0
var station := 0
var revision := 0
var trial_revision := -1
var informative := false
var evidence: Array[Dictionary] = []
var completed := false
var outcome := ""
var undo_stack: Array[Array] = []
func shape(tile: int) -> int: return tile / 2
func fill(tile: int) -> int: return tile % 2
func predictions(a: int,b: int) -> Array[bool]:
	if a < 0 or b < 0 or a >= TILE_COUNT or b >= TILE_COUNT or a == b: return [false,false]
	return [shape(a)==shape(b),fill(a)==fill(b)]
func informative_pair(a: int,b: int) -> bool:
	if a < 0 or b < 0 or a == b:return false
	var result := predictions(a,b)
	return result[0] != result[1]
func place(tile: int,slot: int) -> bool:
	if tile < 0 or tile >= TILE_COUNT or slot < -1 or slot >= 4: return false
	if slot >= 0 and slots[slot] == tile:return true
	undo_stack.append(slots.duplicate())
	for i: int in 4:
		if slots[i] == tile:slots[i] = -1
	if slot >= 0:slots[slot] = tile
	revision += 1;cancel();outcome=""
	return true
func undo() -> bool:
	if undo_stack.is_empty():return false
	slots.assign(undo_stack.pop_back());revision+=1;cancel();outcome="";return true
func start(target: int) -> bool:
	if target not in [0,1] or running:return false
	station=target;running=true;paused=false;elapsed=0;trial_revision=revision;outcome="";return true
func pause()->void:
	if running:paused=true
func resume()->bool:
	if not running or not paused:return false
	paused=false;return true
func cancel()->void:running=false;paused=false;elapsed=0;trial_revision=-1
func step(dt: float)->void:
	if not running or paused or not is_finite(dt) or dt<=0:return
	elapsed=minf(elapsed+dt,1.0)
	if elapsed<1:return
	running=false
	if trial_revision!=revision:return
	var a:int=slots[station*2];var b:int=slots[station*2+1]
	if a<0 or b<0:outcome="empty";return
	var predicted:=predictions(a,b)
	var accepted:bool=predicted[true_rule]
	var discriminates:=informative_pair(a,b)
	var prior_pair:=false
	for row:Dictionary in evidence:
		if row.station==0 and ((row.a==a and row.b==b) or (row.a==b and row.b==a)):prior_pair=true
	if station==0:
		informative=informative or discriminates
		outcome="accepted" if accepted else "rejected"
	else:
		if informative and accepted and discriminates and not prior_pair:completed=true;outcome="verified"
		elif prior_pair:outcome="repeated"
		elif not informative:outcome="no_contrast"
		else:outcome="accepted" if accepted else "rejected"
	evidence.append({"a":a,"b":b,"station":station,"accepted":accepted,"discriminates":discriminates,"revision":revision})
