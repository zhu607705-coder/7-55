extends RefCounted
## Continuous lamp → prop → gauze projection. No story or save authority.
const PUZZLE_ID := "theater_shadow_rehearsal"
const VERSION := 3
const MAX_ACTIONS := 2048
const SCREEN_DEPTH := 10.0
const FAN_RADIUS := 0.45
const CENTER_TOLERANCE := 0.16
const RADIUS_TOLERANCE := 0.075
const MAX_MOVE := 0.55
const SPREAD_TOLERANCE := 0.065
const MAX_SPREAD_CHANGE := 0.2
const LAMP_LIMIT := 1.25
const LAMP_DEPTH_MIN := -0.5
const LAMP_DEPTH_MAX := 1.5
const WITNESS_SCALE_TOLERANCE := 0.1
const WITNESS := {"id":"light_pin","kind":"pin","x":2.0,"depth":5.0}
const LEVELS := [
	{"id":"first_shadow","title":"展扇入幕","lampX":0.0,"lampDepth":0.0,"objects":[{"id":"left_fan","kind":"fan","x":-2.0,"depth":5.0,"spread":0.35,"side":-1,"depthMovable":false}],"targets":[{"side":-1,"center":0.0,"radius":0.9,"spread":1.0}]},
	{"id":"near_and_far","title":"远近与开合","lampX":0.0,"lampDepth":0.0,"objects":[{"id":"left_fan","kind":"fan","x":0.0,"depth":3.0,"spread":1.0,"side":-1,"depthMovable":true}],"targets":[{"side":-1,"center":0.0,"radius":0.75,"spread":0.65}]},
	{"id":"two_wings","title":"借光合蝶","lampX":-0.6,"lampDepth":1.2,"witnessCenter":3.4,"objects":[{"id":"left_fan","kind":"fan","x":-1.8,"depth":4.0,"radius":0.36,"spread":0.45,"side":-1,"depthMovable":true},{"id":"right_fan","kind":"fan","x":1.8,"depth":4.0,"radius":0.54,"spread":0.45,"side":1,"depthMovable":true},{"id":"side_screen","kind":"screen","x":0.0,"depth":8.0,"width":3.0,"depthMovable":false}],"targets":[{"side":-1,"center":0.0,"radius":0.9,"spread":1.0},{"side":1,"center":0.0,"radius":0.9,"spread":0.7}]}
]
var state: Dictionary = {}
var actions: Array = []
var history: Array = []

func _init() -> void:
	state={"round":0,"screen":"playing","completedRounds":0,"attempts":0,"failure":"","hintTier":0,"objects":[]}
	_load_round()

static func layout_digest() -> String:
	return JSON.stringify({"version":VERSION,"levels":LEVELS,"screenDepth":SCREEN_DEPTH,"fanRadius":FAN_RADIUS,"centerTolerance":CENTER_TOLERANCE,"radiusTolerance":RADIUS_TOLERANCE,"maxMove":MAX_MOVE,"spreadTolerance":SPREAD_TOLERANCE,"maxSpreadChange":MAX_SPREAD_CHANGE,"lampLimit":LAMP_LIMIT,"lampDepthMin":LAMP_DEPTH_MIN,"lampDepthMax":LAMP_DEPTH_MAX,"witnessScaleTolerance":WITNESS_SCALE_TOLERANCE,"witness":WITNESS}).sha256_text()

func _load_round() -> void:
	state.objects=LEVELS[int(state.round)].objects.duplicate(true)
	state.lampX=LEVELS[int(state.round)].lampX
	state.lampDepth=LEVELS[int(state.round)].lampDepth
	state.screen="playing";state.failure="";state.hintTier=0;state.attempts=0
	history.clear()

static func project(object: Dictionary,lamp_x:float=0.0,lamp_depth:float=0.0) -> Dictionary:
	var magnification: float=(SCREEN_DEPTH-lamp_depth)/(float(object.depth)-lamp_depth)
	return {"id":object.id,"kind":object.kind,"side":int(object.get("side",0)),"center":lamp_x+(float(object.x)-lamp_x)*magnification,"radius":float(object.get("radius",FAN_RADIUS))*magnification if object.kind=="fan" else float(object.get("width",0.04))*magnification/2.0,"spread":float(object.get("spread",1.0)),"magnification":magnification}

func projections() -> Array:
	var result: Array=[]
	for object: Dictionary in state.objects:result.append(project(object,float(state.lampX),float(state.lampDepth)))
	return result

func _mismatch() -> String:
	var projected: Array=projections()
	if LEVELS[int(state.round)].has("witnessCenter"):
		var witness:Dictionary=project(WITNESS,float(state.lampX),float(state.lampDepth))
		if absf(float(witness.center)-float(LEVELS[int(state.round)].witnessCenter))>CENTER_TOLERANCE or absf(float(witness.magnification)-2.0)>WITNESS_SCALE_TOLERANCE:return "light_axis"
	for target: Dictionary in LEVELS[int(state.round)].targets:
		var found: Dictionary={}
		for shadow: Dictionary in projected:
			if shadow.kind=="fan" and shadow.side==target.side:found=shadow;break
		if found.is_empty():return "missing_wing"
		for obstruction: Dictionary in projected:
			if obstruction.kind=="screen" and absf(float(found.center)-float(obstruction.center))<float(found.radius)+float(obstruction.radius):return "blocked_light"
		if absf(float(found.radius)-float(target.radius))>RADIUS_TOLERANCE:return "shadow_size"
		if absf(float(found.center)-float(target.center))>CENTER_TOLERANCE:return "shadow_position"
		if absf(float(found.spread)-float(target.spread))>SPREAD_TOLERANCE:return "fan_opening"
	return ""

func snapshot() -> Dictionary:
	var result: Dictionary=state.duplicate(true)
	result.puzzleId=PUZZLE_ID;result.layoutDigest=layout_digest()
	result.title=LEVELS[int(state.round)].title
	result.targets=LEVELS[int(state.round)].targets.duplicate(true)
	result.projections=projections();result.undoAvailable=not history.is_empty()
	result.lampMovable=true
	result.witness=project(WITNESS,float(state.lampX),float(state.lampDepth)) if LEVELS[int(state.round)].has("witnessCenter") else {}
	result.witnessTarget=LEVELS[int(state.round)].get("witnessCenter",0.0)
	result.actionCount=actions.size()
	return result

func _find(id: String) -> int:
	for index in state.objects.size():
		if state.objects[index].id==id:return index
	return -1

func _remember() -> void:
	history.append({"objects":state.objects.duplicate(true),"lampX":state.lampX,"lampDepth":state.lampDepth})

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
		_remember()
		object.x=next_x;object.depth=next_depth;state.failure=""
	elif kind=="spread":
		if state.screen!="playing" or action.size()!=3 or not action.get("id") is String or not _number(action.get("value")):return false
		var index:int=_find(action.id)
		if index<0 or state.objects[index].kind!="fan":return false
		var object:Dictionary=state.objects[index];var value:float=float(action.value)
		if value<0.25 or value>1.0 or absf(value-float(object.spread))>MAX_SPREAD_CHANGE+0.00001 or is_equal_approx(value,float(object.spread)):return false
		_remember();object.spread=value;state.failure=""
	elif kind=="lamp":
		if state.screen!="playing" or action.size()!=3 or not _number(action.get("x")) or not _number(action.get("depth")):return false
		var value:=Vector2(float(action.x),float(action.depth))
		var previous:=Vector2(float(state.lampX),float(state.lampDepth))
		if absf(value.x)>LAMP_LIMIT or value.y<LAMP_DEPTH_MIN or value.y>LAMP_DEPTH_MAX or value.distance_to(previous)>MAX_MOVE+0.00001 or value.is_equal_approx(previous):return false
		_remember();state.lampX=value.x;state.lampDepth=value.y;state.failure=""
	elif kind=="undo":
		if action.size()!=1 or state.screen!="playing" or history.is_empty():return false
		var previous:Dictionary=history.pop_back();state.objects=previous.objects;state.lampX=previous.lampX;state.lampDepth=previous.lampDepth;state.failure=""
	elif kind=="restart":
		if action.size()!=1 or state.screen!="playing":return false
		_remember();state.objects=LEVELS[int(state.round)].objects.duplicate(true);state.lampX=LEVELS[int(state.round)].lampX;state.lampDepth=LEVELS[int(state.round)].lampDepth;state.failure=""
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
		["窄影跟着扇骨走，扇子还没有展开。","扇骨外沿的铜扣可以绕着扇轴拉开。","先移动底座对齐位置，再展开扇骨比较翼缘。"],
		["只把影子缩小，翼缘仍然太宽。","前后移动同时改变高和宽，收扇只改变翼面的张开。","先比上下边缘决定远近，再用扇骨铜扣调整开合。"],
		["右侧固定木钉的影子，还没同时贴住两端的刻线。","左右移灯，所有影子横移；把灯推近道具，所有影子放大。","先借木钉的长短与位置校灯并移开挡光侧幕，再分别调整两把大小不同的扇子。"]
	]
	return text[clampi(round_index,0,2)][clampi(tier-1,0,2)]

static func failure_text(category: String) -> String:
	return {"blocked_light":"幕上多了一片宽影。","shadow_size":"扇影的上下边缘还没有合上。","shadow_position":"扇影和留白还没有贴合。","fan_opening":"翼缘还没有展开到留白边缘。","light_axis":"木钉的影子偏离了刻线。","missing_wing":"另一侧的扇影还没有出现。"}.get(category,"")
