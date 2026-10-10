extends RefCounted
## Pure rules for the lamp/curtain game. No State access, saves or fact writes.
const VERSION:=1
const HATS=["entrance","stairs","honor_wall"]
const INITIAL_HATS=["stairs","honor_wall","entrance"]
const AXES=["xOffset","yOffset","rotationQuarterTurns"]
static var _source:Dictionary={}
static func source()->Dictionary:
	if _source.is_empty():_source=JSON.parse_string(FileAccess.get_file_as_string("res://data/native/chapter4-device-source.json"))
	return _source
static func initial()->Dictionary:
	return {"version":VERSION,"hats":INITIAL_HATS.duplicate(),"alignment":source().defaults.mediaAlignment.duplicate()}
static func _integer(value:Variant)->bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value)==floor(float(value))
static func valid(value:Variant)->bool:
	if not value is Dictionary or value.size()!=3:return false
	if not value.has("version") or not _integer(value.version) or int(value.version)!=VERSION:return false
	if not value.get("hats") is Array or value.hats.size()!=3:return false
	var seen:Dictionary={}
	for id:Variant in value.hats:
		if not id is String or id not in HATS or seen.has(id):return false
		seen[id]=true
	if not value.get("alignment") is Dictionary or value.alignment.size()!=3:return false
	for axis:String in AXES:
		if not value.alignment.has(axis) or not _integer(value.alignment[axis]):return false
		var number:int=int(value.alignment[axis])
		var limits:Array=source().ranges.media_alignment[axis]
		if number<int(limits[0]) or number>int(limits[1]):return false
	return true
static func canonical(value:Dictionary)->Dictionary:
	if not valid(value):return {}
	var result:Dictionary=value.duplicate(true);result.version=VERSION
	for axis:String in AXES:result.alignment[axis]=int(value.alignment[axis])
	return result
static func hats_ready(value:Dictionary)->bool:return valid(value) and value.hats==HATS
static func ready_to_record(value:Dictionary)->bool:
	if not hats_ready(value):return false
	for axis:String in AXES:
		if int(value.alignment[axis])!=int(source().registration.media[axis]):return false
	return true
static func stage(value:Dictionary,already_recorded:=false)->String:
	return "recorded" if already_recorded else ("curtain" if hats_ready(value) else "wardrobe")
static func transition(value:Dictionary,event:Dictionary)->Dictionary:
	var out:Dictionary={"accepted":false,"checkpoint":value.duplicate(true),"message":"","motion":""}
	if not valid(value):out.message="影棚还没准备好。";return out
	var next:Dictionary=value.duplicate(true)
	match str(event.get("kind","")):
		"swap":
			if hats_ready(value):out.message="灯罩已经各就各位，轮到幕布了。";return out
			if not _integer(event.get("a")) or not _integer(event.get("b")):return out
			var a:int=int(event.a);var b:int=int(event.b)
			if a<0 or b<0 or a>2 or b>2 or a==b:return out
			var hat:String=next.hats[a];next.hats[a]=next.hats[b];next.hats[b]=hat
			out.motion="swap"
			out.message="帽子换了，影子也跟着换了。" if not hats_ready(next) else "三顶帽子终于承认了自己的岗位。幕布却把影子卷走了。"
		"step":
			if not hats_ready(value):out.message="先让三个影子各回岗位。";return out
			var axis:String=str(event.get("axis",""))
			if axis not in AXES or not _integer(event.get("delta")) or abs(int(event.delta))!=1:return out
			var number:int=int(next.alignment[axis])+int(event.delta)
			if axis=="rotationQuarterTurns":number=posmod(number,4)
			elif number<int(source().ranges.media_alignment[axis][0]) or number>int(source().ranges.media_alignment[axis][1]):out.message="幕布的绳子到头了，往回拉一点。";return out
			next.alignment[axis]=number;out.motion="turn" if axis=="rotationQuarterTurns" else "pull"
		"reset_alignment":
			if not hats_ready(value):return out
			next.alignment=initial().alignment;out.motion="unroll";out.message="幕布重新铺平了，灯罩都还在原位。"
		"inspect":
			out.accepted=true
			out.message="三处影子都对上了，可以收进胶片。" if ready_to_record(value) else ("幕布打了个嗝，又把这套影子原样吐了回来。" if hats_ready(value) else "楼梯还在替门上班。看看灯罩缺口和幕布上的虚线。")
			out.motion="hiccup" if hats_ready(value) and not ready_to_record(value) else "inspect"
			return out
		_:return out
	out.accepted=true;out.checkpoint=next
	return out
