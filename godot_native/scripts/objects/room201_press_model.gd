extends RefCounted
## Bounded physical press state. The chapter controller alone owns story facts.
const VERSION := 1
const AXES := ["horizontal", "vertical", "pressure"]
static var _source: Dictionary = {}
static func source() -> Dictionary:
	if _source.is_empty(): _source = JSON.parse_string(FileAccess.get_file_as_string("res://data/native/chapter4-device-source.json"))
	return _source
static func initial() -> Dictionary:
	return {"version":VERSION,"inserted":false,"calibration":source().defaults.calibration.duplicate(),"imprinted":false}
static func integer(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value)==floor(float(value))
static func valid(value: Variant) -> bool:
	if not value is Dictionary or value.size()!=4: return false
	if not integer(value.get("version")) or int(value.version)!=VERSION: return false
	if not value.get("inserted") is bool or not value.get("imprinted") is bool: return false
	if not value.get("calibration") is Dictionary or value.calibration.size()!=3: return false
	for axis: String in AXES:
		if not integer(value.calibration.get(axis)): return false
		var limits: Array = source().ranges.positioning_calibration[axis]
		if int(value.calibration[axis])<int(limits[0]) or int(value.calibration[axis])>int(limits[1]): return false
	if not value.inserted and (value.imprinted or value.calibration!=source().defaults.calibration): return false
	if value.imprinted and not matches_registration(value.calibration): return false
	return true
static func matches_registration(value: Variant) -> bool:
	if not value is Dictionary or value.size()!=3: return false
	for axis: String in AXES:
		if not integer(value.get(axis)) or int(value[axis])!=int(source().registration.calibration[axis]): return false
	return true
static func ready_to_press(value: Dictionary) -> bool:
	return valid(value) and value.inserted and matches_registration(value.calibration)
static func canonical(value: Dictionary) -> Dictionary:
	if not valid(value): return {}
	var result: Dictionary = value.duplicate(true)
	result.version=VERSION
	for axis: String in AXES: result.calibration[axis]=int(value.calibration[axis])
	return result
static func stage(value: Dictionary, completed: bool=false) -> String:
	return "calibrated" if completed else ("adjust" if value.get("inserted",false) else "insert")
static func transition(value: Dictionary, event: Dictionary) -> Dictionary:
	var result := {"accepted":false,"checkpoint":value.duplicate(true),"message":"","motion":""}
	if not valid(value) or value.imprinted: return result
	var next: Dictionary = canonical(value)
	match str(event.get("kind","")):
		"insert":
			if value.inserted: return result
			next.inserted=true; result.motion="insert"; result.message="定位片坐上夹具。三个触点还在各说各话。"
		"step":
			if not value.inserted: return result
			var axis: String = str(event.get("axis",""))
			if axis not in AXES or not integer(event.get("delta")) or abs(int(event.delta))!=1: return result
			var number: int = int(next.calibration[axis])+int(event.delta)
			var limits: Array = source().ranges.positioning_calibration[axis]
			if number<int(limits[0]) or number>int(limits[1]):
				result.message="到轨道尽头了，往回一点。"; return result
			next.calibration[axis]=number; result.motion="spring" if axis=="pressure" else "slide"
		"reset":
			if not value.inserted: return result
			next.calibration=source().defaults.calibration.duplicate(); result.motion="reset"; result.message="夹具回到起点，定位片还在这里。"
		_: return result
	result.accepted=true; result.checkpoint=next
	return result
