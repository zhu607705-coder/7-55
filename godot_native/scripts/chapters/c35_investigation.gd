extends RefCounted
## The native investigation extends the original interlude without creating source evidence.
const KEY := "c35_investigation"
const STEPS := ["inbox","notice","assignment","camera","files","file","attached","file_error","receipt","album_trace","journal","group","seen","private","map","arrival","confirmed"]
const CAMPUS_SIZE := Vector2(4516,3420)
# Source pixels of the active north_teaching_V3 layer and the adjacent path.
const WEST_APPROACH := Rect2(1567,841,104,56)
const EAST_APPROACH := Rect2(1731,841,117,56)
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
const GROUP_REPLIES := {"route":"刚才有人看见我往哪边走了吗？","photo":"有没有人收到过我离开湖边时发的位置？"}

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
	if not route.get("identity_requested",false) is bool: return false
	if route.has("group_reply") and not GROUP_REPLIES.has(route.group_reply): return false
	for field: String in ["preview_file","attachment"]:
		if route.has(field) and not file_available(route,route[field]): return false
	if route.get("attachment","") == EARLIER_FILE_ID: return false
	if index>=STEPS.find("receipt") and route.has("attachment") and (route.attachment!=FILE_ID or not route.has("reply")): return false
	var map_version: Variant=route.get("map","")
	if map_version not in ["","layered"]: return false
	var interlude: Dictionary=snapshot.chapterThreeInterlude
	if index>0 and not interlude.recoveryOpened: return false
	if index>=STEPS.find("group") and not interlude.evidenceIds.has("journal_start"): return false
	if index<STEPS.find("arrival"): return map_version=="" and route.pin.is_empty() and not interlude.replayUnlocked
	var bounds := WEST_APPROACH if map_version=="layered" else LEGACY_WEST_APPROACH
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
			route.step="file"
			route.preview_file=PHOTO_ID
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
		"open_album":["receipt","album_trace"],"journal":["album_trace","journal"],
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
		if action=="journal": return {"handled":true,"page":"c35_journal","message":""}
		return {"handled":true,"message":""}
	if action=="pin" and current=="map":
		var position := point(value)
		if not Rect2(Vector2.ZERO,CAMPUS_SIZE).has_point(position): return {"handled":true,"message":"请在校园地图上标一个位置。"}
		if EAST_APPROACH.has_point(position): return {"handled":true,"message":"这是东侧入口，清楼时已经锁了。沿中间的绿带找西侧大厅。"}
		if not WEST_APPROACH.has_point(position): return {"handled":true,"message":"这处和周琪说的教学楼入口对不上。可以换一处再落针。"}
		route.pin=value.duplicate()
		route.map="layered"
		route.step="arrival"
		return {"handled":true,"message":"匹配到北教 A 楼西侧大厅入口。"}
	if action=="compare" and current=="arrival":
		if value!="record_0755": return {"handled":true,"message":"这条记录的接入点或时刻与清楼广播对不上。"}
		interlude.networkRecordRead=true
		interlude.networkRecordId="record_0755"
		interlude.destinationId="duan_yongping_a1"
		interlude.phase="destination_verified"
		route.step="confirmed"
		return {"handled":true,"message":"接入发生在清楼广播前 3 秒。位置和时间对上了。"}
	return {"handled":true,"message":""}
