extends RefCounted
const Posts = preload("res://scripts/data/cc98_store.gd")
const APP_IDS = ["wechat","tiyi","zjuding","settings","photos","timeline_recovery","voice_memos","cc98","control_center","clock"]
const LABELS = {"wechat":"微信","tiyi":"浙大体艺","zjuding":"浙大钉","settings":"设置","photos":"照片","timeline_recovery":"记录恢复","voice_memos":"录音","cc98":"CC98","control_center":"控制中心","clock":"时钟"}

static func app_available(s: Dictionary, id: String) -> bool:
	if id in ["wechat","tiyi","zjuding","settings","control_center"]: return true
	if id == "cc98": return s.actOne.phase != "prologue"
	var interlude = s.qizhenLake.phase == "complete" and not s.chapterThreeInterlude.completed
	if id in ["timeline_recovery","voice_memos"]: return interlude
	if id == "photos":
		var library_access=s.actOne.phase=="complete" or s.ui.libraryFinalsPhase in ["library_route_unlocked","library_entered","occupied_seat_found","evidence_gathering","bd_briefing","top_ten_rising","top_ten_reached","recovery_application","pass_ready","backpack_removed","seat_recovered","friend_contacted"]
		return interlude or (library_access and s.ui.libraryFinalsPuzzle.backpackInspected and s.ui.libraryFinalsPuzzle.investigationOpened)
	return false

static func can_remove(s: Dictionary, id: String) -> bool:
	return id == "tiyi" and s.actOne.exerciseStarted and s.ui.libraryFinalsPuzzle.presenceProofCollected

static func normalized_order(value: Variant) -> Array:
	var clean: Array = []
	if value is Array:
		for id in value:
			if id in APP_IDS and not clean.has(id): clean.append(id)
	for id in APP_IDS:
		if not clean.has(id): clean.append(id)
	return clean

static func editing_allowed(s: Dictionary) -> bool:
	return not str(s.native.get("checkpoint_id","")).is_empty()

static func _ok(message: String = "") -> Dictionary: return {"handled":true,"message":message}

func dispatch(s: Dictionary, id: String, value: Variant) -> Dictionary:
	if not id.begins_with("phone_"): return {}
	match id:
		"phone_refresh": return _ok()
		"phone_open_journal_closeout":
			if not s.chapterThreeInterlude.recoveryOpened or s.chapterThreeInterlude.evidenceIds.has("journal_start"): return _ok()
			s.native.page="c35_journal"
			return {"handled":true,"message":"","page":"c35_journal"}
		"phone_cc98_network_rejected":
			if s.networkMode=="campus_wifi": return _ok()
			s.native.page="phone_home"
			return {"handled":true,"message":"CC98 仅支持校园网。请切换后重新进入。","page":"phone_home"}
		"phone_cc98_search_reject":
			return _ok({"seat-022-old-source":"来源不匹配：这是今日新帖，纸条引用的是旧版公开记录。","seat-022-wrong-time":"时间不匹配：这条记录早于本次 022 占用事件。","seat-022-missing-attachment":"附件不匹配：这条帖子没有纸条对应的离座凭据。"}.get(str(value),"未找到对应记录。"))
		"phone_music_mute":
			s.ui.musicMuted = not s.ui.musicMuted
			return _ok()
		"phone_low_power":
			s.phoneBattery.lowPowerMode = not s.phoneBattery.lowPowerMode
			if s.phoneBattery.lowPowerMode:
				s.ui.brightness = minf(45,s.ui.brightness)
				s.ui.musicPlaying = false
			return _ok("低电量模式已开启：打开应用仅消耗 1%，亮度上限 45%，音乐已暂停。" if s.phoneBattery.lowPowerMode else "低电量模式已关闭：打开应用恢复消耗 2%。")
		"phone_settings_brightness":
			if str(value).is_valid_float(): s.ui.brightness = clampf(float(value),0,100)
			return _ok()
		"phone_app_move":
			if s.actOne.phase == "prologue" or not value is Dictionary: return _ok()
			var order = normalized_order(s.ui.homeAppOrder)
			var app = str(value.get("id",""))
			var index = order.find(app)
			var target = index + int(value.get("offset",0))
			if index<0 or target<0 or target>=order.size(): return _ok()
			if value.get("from_home",false) and (not app_available(s,app) or not app_available(s,order[target])): return _ok()
			order[index] = order[target]; order[target] = app
			s.ui.homeAppOrder = order
			return _ok(str(LABELS.get(app,app))+"已移动。")
		"phone_home_order":
			if s.actOne.phase == "prologue" or not value is Array: return _ok()
			var before = normalized_order(s.ui.homeAppOrder)
			if value.size()!=APP_IDS.size() or normalized_order(value)!=value: return _ok()
			for index in range(before.size()):
				if not app_available(s,before[index]) and value[index]!=before[index]: return _ok()
			s.ui.homeAppOrder = value.duplicate()
			return _ok()
		"phone_app_remove":
			if not can_remove(s,str(value)): return _ok("这个应用参与剧情，只能移动位置。")
			if str(value) not in s.ui.hiddenHomeAppIds: s.ui.hiddenHomeAppIds.append(str(value))
			return _ok("浙大体艺已从桌面移除，可在设置中恢复。")
		"phone_app_restore":
			s.ui.hiddenHomeAppIds.erase(str(value))
			return _ok(str(LABELS.get(str(value),str(value)))+"已回到桌面。")
		"phone_app_reset":
			s.ui.homeAppOrder = APP_IDS.duplicate()
			return _ok("桌面已恢复默认顺序。")
		"phone_cc98_save":
			if not editing_allowed(s) or not value is Dictionary: return _ok("当前未开放帖子维护。")
			return _ok("CC98 帖子已保存到本机。" if Posts.save_edits(value)==OK else "帖子保存失败，原有内容仍可读取。")
		"phone_cc98_reset":
			if not editing_allowed(s): return _ok("当前未开放帖子维护。")
			return _ok("CC98 帖子已恢复为默认内容。" if Posts.restore_defaults()==OK else "帖子恢复失败。")
	return {}
