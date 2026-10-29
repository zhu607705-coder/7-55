extends RefCounted
## Local architecture review only; no chapter gates or persistence authority.
const Body=preload("res://scripts/player_metrics.gd")
const Space=preload("res://scripts/space/spatial_rules.gd")
const FLOORS:=[2,3,4]
static func nearby(data:Dictionary,anchor:Vector2)->Dictionary:
	var feet:Rect2=Body.foot_rect(anchor)
	for landing:Dictionary in data.get("transits",[]):
		if Space.rect(landing.zone).encloses(feet):return landing
	return {}
static func destination(data:Dictionary,anchor:Vector2,target:int)->Dictionary:
	if not FLOORS.has(target) or target==int(data.floor):return {}
	var from:=nearby(data,anchor)
	if from.is_empty():return {}
	if from.kind=="stairs" and absi(target-int(data.floor))!=1:return {}
	var path:="res://campuses/future_learning_center/data/floor_%d.json"%target
	if not FileAccess.file_exists(path):return {}
	var next:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path))
	for arrival:Dictionary in next.get("transits",[]):
		if arrival.id==from.id:return {"floor":target,"point":arrival.arrival,"via":from.id}
	return {}
