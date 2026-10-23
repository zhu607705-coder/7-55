extends RefCounted
## Continuous lamp → prop → gauze projection. No story or save authority.
const PUZZLE_ID := "theater_shadow_rehearsal"
const VERSION := 1
const MAX_ACTIONS := 2048
const SCREEN_DEPTH := 10.0
const FAN_RADIUS := 0.45
const CENTER_TOLERANCE := 0.16
const RADIUS_TOLERANCE := 0.075
const MAX_MOVE := 0.55
const LEVELS := [
	{"id":"first_shadow","title":"一叶入幕","objects":[{"id":"left_fan","kind":"fan","x":-2.0,"depth":5.0,"side":-1,"depthMovable":false}],"targets":[{"side":-1,"center":0.0,"radius":0.9}]},
	{"id":"near_and_far","title":"一程相送","objects":[{"id":"left_fan","kind":"fan","x":0.0,"depth":3.0,"side":-1,"depthMovable":true}],"targets":[{"side":-1,"center":0.0,"radius":0.75}]},
	{"id":"two_wings","title":"双翼合幕","objects":[{"id":"left_fan","kind":"fan","x":-1.8,"depth":4.0,"radius":0.36,"side":-1,"depthMovable":true},{"id":"right_fan","kind":"fan","x":1.8,"depth":4.0,"radius":0.54,"side":1,"depthMovable":true},{"id":"side_screen","kind":"screen","x":0.0,"depth":8.0,"width":3.0,"depthMovable":false}],"targets":[{"side":-1,"center":0.0,"radius":0.9},{"side":1,"center":0.0,"radius":0.9}]}
]
var state: Dictionary = {}
var actions: Array = []
var history: Array = []

func _init() -> void:
	state={"round":0,"screen":"playing","completedRounds":0,"attempts":0,"failure":"","hintTier":0,"objects":[]}
	_load_round()

static func layout_digest() -> String:
	return JSON.stringify({"version":VERSION,"levels":LEVELS,"screenDepth":SCREEN_DEPTH,"fanRadius":FAN_RADIUS,"centerTolerance":CENTER_TOLERANCE,"radiusTolerance":RADIUS_TOLERANCE,"maxMove":MAX_MOVE}).sha256_text()

func _load_round() -> void:
	state.objects=LEVELS[int(state.round)].objects.duplicate(true)
	state.screen="playing";state.failure="";state.hintTier=0;state.attempts=0
	history.clear()

static func project(object: Dictionary) -> Dictionary:
	var magnification: float=SCREEN_DEPTH/float(object.depth)
	return {"id":object.id,"kind":object.kind,"side":int(object.get("side",0)),"center":float(object.x)*magnification,"radius":float(object.get("radius",FAN_RADIUS))*magnification if object.kind=="fan" else float(object.width)*magnification/2.0,"magnification":magnification}

func projections() -> Array:
	var result: Array=[]
	for object: Dictionary in state.objects:result.append(project(object))
	return result

func _mismatch() -> String:
	var projected: Array=projections()
	for target: Dictionary in LEVELS[int(state.round)].targets:
		var found: Dictionary={}
		for shadow: Dictionary in projected:
			if shadow.kind=="fan" and shadow.side==target.side:found=shadow;break
		if found.is_empty():return "missing_wing"
		for obstruction: Dictionary in projected:
			if obstruction.kind=="screen" and absf(float(found.center)-float(obstruction.center))<float(found.radius)+float(obstruction.radius):return "blocked_light"
		if absf(float(found.radius)-float(target.radius))>RADIUS_TOLERANCE:return "shadow_size"
		if absf(float(found.center)-float(target.center))>CENTER_TOLERANCE:return "shadow_position"
	return ""

func snapshot() -> Dictionary:
	var result: Dictionary=state.duplicate(true)
	result.puzzleId=PUZZLE_ID;result.layoutDigest=layout_digest()
	result.title=LEVELS[int(state.round)].title
	result.targets=LEVELS[int(state.round)].targets.duplicate(true)
	result.projections=projections();result.undoAvailable=not history.is_empty()
	result.actionCount=actions.size()
	return result

func _find(id: String) -> int:
	for index in state.objects.size():
		if state.objects[index].id==id:return index
	return -1

func apply(action: Variant) -> bool:
	if not action is Dictionary or actions.size()>=MAX_ACTIONS or state.screen=="complete":return false
	var kind: String=str(action.get("kind",""))
	if kind=="continue":
		if action.size()!=1 or state.screen!="round_complete":return false
		state.round=int(state.round)+1;_load_round()
	elif kind=="move":
		if state.screen!="playing" or action.size()!=4 or not action.get("id") is String or not _number(action.get("x")) or not _number(action.get("depth")):return false
		var index: int=_find(action.id)
		if index<0:return false
		var object: Dictionary=state.objects[index]
		var next_x: float=float(action.x);var next_depth: float=float(action.depth)
		if next_x < -4.5 or next_x > 4.5 or next_depth<3.0 or next_depth>7.0 and object.kind=="fan":return false
		if not object.depthMovable and not is_equal_approx(next_depth,float(object.depth)):return false
		if Vector2(next_x-float(object.x),next_depth-float(object.depth)).length()>MAX_MOVE+0.00001:return false
		if is_equal_approx(next_x,float(object.x)) and is_equal_approx(next_depth,float(object.depth)):return false
		history.append(state.objects.duplicate(true))
		object.x=next_x;object.depth=next_depth;state.failure=""
	elif kind=="undo":
		if action.size()!=1 or state.screen!="playing" or history.is_empty():return false
		state.objects=history.pop_back();state.failure=""
	elif kind=="restart":
		if action.size()!=1 or state.screen!="playing":return false
		history.append(state.objects.duplicate(true));state.objects=LEVELS[int(state.round)].objects.duplicate(true);state.failure=""
	elif kind=="try":
		if action.size()!=1 or state.screen!="playing":return false
		state.failure=_mismatch()
		if str(state.failure).is_empty():
			state.completedRounds=int(state.completedRounds)+1
			state.screen="complete" if int(state.round)==LEVELS.size()-1 else "round_complete"
		else:state.attempts=int(state.attempts)+1
	elif kind=="hint":
		if action.size()!=1 or state.screen!="playing":return false
		state.hintTier=mini(3,int(state.hintTier)+1)
	else:return false
	actions.append(action.duplicate(true))
	return true

static func _number(value: Variant) -> bool:
	return (value is float or value is int) and is_finite(float(value))

func proof(session: Dictionary={}) -> Dictionary:
	if state.screen!="complete":return {}
	return {"puzzleId":PUZZLE_ID,"layoutDigest":layout_digest(),"actions":actions.duplicate(true),"session":session.duplicate(true)}

static func replay(value: Variant) -> Dictionary:
	if not value is Dictionary or value.get("puzzleId")!=PUZZLE_ID or value.get("layoutDigest")!=layout_digest() or not value.get("actions") is Array:return {}
	if value.actions.is_empty() or value.actions.size()>MAX_ACTIONS:return {}
	var model=load("res://scripts/games/theater_shadow_rehearsal_model.gd").new()
	for action: Variant in value.actions:
		if not model.apply(action):return {}
	var result: Dictionary=model.snapshot()
	return result if result.screen=="complete" and int(result.completedRounds)==3 else {}

static func hint(round_index: int, tier: int) -> String:
	var text: Array=[
		["扇子和幕上的深色轮廓一起移动。","光从灯经过扇子，才落到后面的幕上。","留意扇面外沿与幕上留白的边缘。"],
		["轮廓的位置相近，大小却还不同。","同一把扇子离灯远近不同，幕上的影子也会变化。","比较扇子向灯和向幕各移动一点后的轮廓。"],
		["两片扇影之间还夹着一块宽影。","每一个会挡住灯光的实体，都会留在同一块幕上。","先分辨宽影来自哪一件道具，再看双翼各自的边缘。"]
	]
	return text[clampi(round_index,0,2)][clampi(tier-1,0,2)]

static func failure_text(category: String) -> String:
	return {"blocked_light":"幕上多了一片宽影。","shadow_size":"扇影的大小还没有对上留白。","shadow_position":"扇影和留白还没有贴合。","missing_wing":"另一侧的扇影还没有出现。"}.get(category,"")
