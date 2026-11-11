extends RefCounted
## The native investigation extends the original interlude without creating source evidence.
const KEY := "c35_investigation"
const STEPS := ["inbox","notice","assignment","camera","files","file","attached","file_error","receipt","album_trace","journal","group","seen","private","map","entrance","arrival","confirmed"]
const CAMPUS_SIZE := Vector2(4516,3420)
# Footprint of the active north_teaching_V3 layer, in north-up source pixels.
const NORTH_TEACHING_AREA := Rect2(1499,694,398,414)
# Older saves record entrance-sized pins on their respective maps.
const WEST_APPROACH := Rect2(1567,841,104,56)
const LEGACY_WEST_APPROACH := Rect2(1100,1010,145,130)
const FILE_ID := "calculus_week10_scan"
const PHOTO_ID := "calculus_week10_photo"
const EARLIER_FILE_ID := "calculus_week09"
const LEGACY_FILE_ID := "calculus_week10_draft"
const FILE_NAMES := {
	FILE_ID:"第十周作业.pdf",PHOTO_ID:"作业原图.jpg",EARLIER_FILE_ID:"第九周作业.pdf",LEGACY_FILE_ID:"第十周作业.pdf（旧副本）",
}
const REPLIES := {
	"identity":"助教您好，我是林星宇，学号 3250100755。这是我的第十周作业，麻烦您查收。",
	"bare":"这是我补交的作业。",
}
const GROUP_REPLIES := {"route":"我从启真湖回来后断网了一阵。22:40 左右，有人看到我在北教附近吗？","photo":"有没有人收到过我离开湖边时发的位置？"}
const RECORDS := [
	["record_north_east","22:38:12","东门外围","14 秒","室外弱覆盖。接入期间在两个室外节点间漫游。","22:37:05 才在湖边拴好船。不到一分十秒就到北教东门，和这段步行距离对不上。"],
	["record_north_court","22:42:18","中庭绿地","45 秒","室外移动状态。最后一次收到数据是 22:43:03。","位置共享刚在东门外断开。这段是室外漫游，比玻璃门后的广播早了将近三分钟。"],
	["record_north_hall_long","22:44:52","A 区大厅","21 秒","广播开始后仍持续连接，于 22:45:13 断开。","录音里广播一响，连接就中断了。这条在 22:45:00 之后还持续了 13 秒。"],
	["record_0755","22:44:57","A 区大厅","3 秒","短接入记录，于 22:45:00 断开。",""],
]

static func begin(snapshot: Dictionary) -> void:
	snapshot.native[KEY]={"step":"inbox","pin":[]}

static func step(snapshot: Dictionary) -> String:
	return str(snapshot.native.get(KEY,{}).get("step",""))

static func has_route(snapshot: Dictionary) -> bool:
	return not step(snapshot).is_empty()

static func point(value: Variant) -> Vector2:
	if not value is Array or value.size()!=2: return Vector2.INF
	for axis: Variant in value:
		if not (axis is int or axis is float) or not is_finite(float(axis)): return Vector2.INF
	return Vector2(float(value[0]),float(value[1]))

static func valid(snapshot: Dictionary) -> bool:
	if not snapshot.native.has(KEY): return true
	var route: Variant=snapshot.native[KEY]
	if not route is Dictionary or not route.get("pin") is Array: return false
	var index := STEPS.find(route.get("step",""))
	if index<0 or snapshot.qizhenLake.phase!="complete": return false
	if not route.get("captured",false) is bool or not route.get("pdf",false) is bool: return false
	if route.get("pdf",false) and not route.get("captured",false): return false
	if route.has("reply") and route.reply not in ["attachment","missing"] and not REPLIES.has(route.reply): return false
	if not route.get("identity_requested",false) is bool or not route.get("broadcast_heard",false) is bool: return false
	if route.get("album_return","") not in ["","files","receipt"]: return false
	if route.get("album_photo","") not in ["","lake","dock"] or not route.get("album_seen",false) is bool: return false
	if route.get("entry_side","") not in ["","west"]: return false
	if (route.has("entry_side") or route.get("broadcast_heard",false)) and index<STEPS.find("arrival"): return false
	if route.has("group_reply") and not GROUP_REPLIES.has(route.group_reply): return false
	for field: String in ["preview_file","attachment"]:
		if route.has(field) and not file_available(route,route[field]): return false
	if route.get("attachment","") == EARLIER_FILE_ID: return false
	if index>=STEPS.find("receipt") and route.has("attachment") and (route.attachment!=FILE_ID or not route.has("reply")): return false
	var map_version: Variant=route.get("map","")
	if map_version not in ["","layered","layered_district"]: return false
	var interlude: Dictionary=snapshot.chapterThreeInterlude
	if index>0 and not interlude.recoveryOpened: return false
	if index>=STEPS.find("group") and not interlude.evidenceIds.has("journal_start"): return false
	if index<STEPS.find("entrance"): return map_version=="" and route.pin.is_empty() and not interlude.replayUnlocked
	var bounds := LEGACY_WEST_APPROACH
	match map_version:
		"layered": bounds=WEST_APPROACH
		"layered_district": bounds=NORTH_TEACHING_AREA
	if not bounds.has_point(point(route.pin)): return false
	if route.step=="confirmed":
		return interlude.destinationId=="duan_yongping_a1" and interlude.networkRecordRead and interlude.networkRecordId=="record_0755"
	return not interlude.replayUnlocked

static func can_replay(snapshot: Dictionary) -> bool:
	return step(snapshot)=="confirmed" and valid(snapshot)

static func file_available(route: Dictionary, id: Variant) -> bool:
	if not id is String: return false
	match id:
		FILE_ID: return route.get("pdf",false)
		PHOTO_ID: return route.get("captured",false)
		EARLIER_FILE_ID: return true
	return false

static func dispatch(snapshot: Dictionary, action: String, value: Variant) -> Dictionary:
	var current := step(snapshot)
	if current.is_empty(): return {"handled":true,"message":"这份调查还没有开始。"}
	var route: Dictionary=snapshot.native[KEY]
	var interlude: Dictionary=snapshot.chapterThreeInterlude
	var result := {"handled":true,"message":""}
	match action:
		"capture":
			if current!="camera": return result
			route.captured=true
			route.step="files"
			route.erase("preview_file")
			return result
		"preview":
			if current!="files" or not file_available(route,value): return result
			route.preview_file=value
			route.step="file"
			return result
		"convert":
			if current!="file" or route.get("preview_file")!=PHOTO_ID or not route.get("captured",false): return result
			route.pdf=true
			route.preview_file=FILE_ID
			return result
		"attach":
			if current!="file" or value!=route.get("preview_file",LEGACY_FILE_ID): return result
			if value==EARLIER_FILE_ID: return {"handled":true,"message":"这份是第九周的作业。请附上第十周的作业。"}
			if value!=LEGACY_FILE_ID and not file_available(route,value): return result
			route.erase("preview_file")
			if value!=LEGACY_FILE_ID: route.attachment=value
			route.step="attached"
			return result
		"reply":
			if current=="attached" and REPLIES.has(value): route.reply=value
			return result
		"submit":
			if current!="attached" or not REPLIES.has(route.get("reply","")): return result
			if route.reply=="bare":
				route.identity_requested=true
				route.erase("reply")
				return result
			route.erase("identity_requested")
			route.step="receipt" if route.get("attachment")==FILE_ID else "file_error"
			return result
		"repair":
			if current!="file_error": return result
			route.erase("attachment")
			if route.get("captured",false):
				route.step="file"
				route.preview_file=PHOTO_ID
			else: route.step="camera"
			return result
		"open_album":
			if current not in ["files","receipt"] or value not in ["lake","dock"]: return result
			route.album_return=current
			route.album_photo=value
			route.album_seen=true
			route.step="album_trace"
			return result
		"journal":
			if current!="album_trace" or route.get("album_photo","dock")!="dock": return result
			if not interlude.evidenceIds.has("journal_start"): route.step="journal"
			return {"handled":true,"page":"c35_journal","message":""}
		"close_album":
			if current!="album_trace": return result
			route.step=route.get("album_return","receipt")
			route.erase("album_return")
			route.erase("album_photo")
			return result
		"continue_group":
			if current=="receipt" and interlude.evidenceIds.has("journal_start"): route.step="group"
			return result
		"entrance":
			if current!="entrance": return result
			if value!="west": return {"handled":true,"message":"周琪记得东门的铁门拉不开。再对照残片，虚线从东门外绕向了哪一侧？"}
			route.entry_side="west"
			route.step="arrival"
			return result
		"broadcast":
			if current=="arrival": route.broadcast_heard=true
			return result
		"ask":
			if current!="group" or not GROUP_REPLIES.has(value): return result
			route.group_reply=value
			route.step="seen"
			return result
	var transitions := {
		"message":["inbox","notice"],"ta_private":["notice","assignment"],
		"camera":["assignment","camera"],"files":["assignment","files"],
		"cancel_camera":["camera","assignment"],"close_files":["files","assignment"],
		"close_preview":["file","files"],"replace_file":["attached","files"],
		"private":["seen","private"],"map":["private","map"],
	}
	if transitions.has(action):
		var pair: Array=transitions[action]
		if current!=pair[0]: return {"handled":true,"message":""}
		if action=="private" and value!="zhou_qi": return {"handled":true,"message":"这位同学没有收到过你的位置。再翻翻群里的上文。"}
		route.step=pair[1]
		if action=="close_preview": route.erase("preview_file")
		if action=="replace_file": route.erase("attachment")
		if action=="message":
			interlude.rebootSeen=true
			interlude.recoveryOpened=true
			interlude.phase="journal_closeout"
			snapshot.currentScene="timeline_recovery"
		return {"handled":true,"message":""}
	if action=="pin" and current=="map":
		var position := point(value)
		if not Rect2(Vector2.ZERO,CAMPUS_SIZE).has_point(position): return {"handled":true,"message":"请在校园地图上标一个位置。"}
		if not NORTH_TEACHING_AREA.has_point(position):
			return {"handled":true,"message":"这片楼群对不上。再看看红边球场隔街往南，找四组排成田字的院落。"}
		route.pin=value.duplicate()
		route.map="layered_district"
		route.step="entrance"
		return {"handled":true,"message":"已定位到北教学区。"}
	if action=="compare" and current=="arrival":
		if not route.get("broadcast_heard",false): return {"handled":true,"message":"先听清录音末尾的广播。"}
		var record := RECORDS.filter(func(row: Array) -> bool: return row[0]==value)
		if record.is_empty(): return result
		if value!="record_0755": return {"handled":true,"message":record[0][5]}
		interlude.networkRecordRead=true
		interlude.networkRecordId="record_0755"
		interlude.destinationId="duan_yongping_a1"
		interlude.phase="destination_verified"
		route.step="confirmed"
		return {"handled":true,"message":"22:44:57 进入大厅，3 秒后广播响起、连接断开。地点和时间都对上了。"}
	return {"handled":true,"message":""}

static func finish_journal(snapshot: Dictionary) -> void:
	if step(snapshot)!="journal": return
	var route: Dictionary=snapshot.native[KEY]
	route.step="files" if route.get("album_return","")=="files" else "group"
	route.erase("album_return")
	route.erase("album_photo")
