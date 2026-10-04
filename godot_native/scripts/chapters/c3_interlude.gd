extends "res://scripts/chapters/c3_base.gd"
const VoiceSession = preload("res://scripts/media/c3_voice_session.gd")
var voice_session: RefCounted

const EVIDENCE: Array=["journal_start","photo_direction","network_destination","broadcast_end"]
const PHOTOS: Array=["paper_left","paper_middle","paper_right"]
const VOICES: Array=["lake","stone","lobby","broadcast"]
const REASONS: Dictionary={"canteen_0755":"number_not_time","theater_0832":"earlier_independent_event","status_clock_075523":"frozen_local_clock"}
const FRAMES: Array=[
	{"id":"lake_memory_a","label":"FRM 3A","image":"lake_memory_a"},
	{"id":"paper_middle","label":"FRM 91","image":"paper_middle"},
	{"id":"mirrored_a","label":"FRM D7","image":"paper_right","mirror":true},
	{"id":"paper_right","label":"FRM 4C","image":"paper_right"},
	{"id":"lake_memory_b","label":"FRM 0F","image":"lake_memory_b"},
	{"id":"paper_left","label":"FRM B2","image":"paper_left"},
	{"id":"mirrored_b","label":"FRM E8","image":"paper_left","mirror":true}
]
const MESSAGES: Array=[
	{"id":"computer_left_on","author":"林昊","text":"203 还开着吗？我电脑没关。"},
	{"id":"guard_east","author":"陈嘉","text":"刚看见保安从东边过去。"},
	{"id":"east_closed","author":"周琪","text":"东边入口已经封了，别再往那边走。"},
	{"id":"west_cleaner","author":"室友","text":"我在西侧看见保洁推车，大厅主入口应该还能进。"},
	{"id":"withdrawn","author":"陈嘉","text":"陈嘉撤回了一条消息"}
]
const RECORDS: Array=[
	{"id":"record_0755","label":"22:44:57 · 北教学区 A 区","detail":"AP-DYP-A1-03 · 3 秒 · 未知设备 · 身份来源待核验"},
	{"id":"record_theater_hall","label":"22:44:31 · 剧场前厅","detail":"AP-THEATER-HALL-01 · 18 秒 · 已认证设备"},
	{"id":"record_library_south","label":"22:43:11 · 基础图书馆南侧","detail":"AP-LIB-SOUTH-05 · 3 秒 · 未知设备"},
	{"id":"record_qizhen_dock","label":"22:44:12 · 启真湖小码头","detail":"AP-QZL-DOCK-02 · 3 秒 · 未知设备"}
]
const DESTINATIONS: Array=[{"id":"qizhen_lake_dock","label":"启真湖小码头"},{"id":"theater_lobby","label":"剧场前厅"},{"id":"basic_library_south","label":"基础图书馆南侧"},{"id":"duan_yongping_a1","label":"段永平教学楼 A 楼一层"}]

func pages(s: Dictionary) -> Array:
	if s.qizhenLake.phase!="complete" or s.chapterThreeInterlude.completed: return []
	var list: Array=[{"id":"c35_recovery","label":"记录恢复"}]
	if s.chapterThreeInterlude.recoveryOpened: list.append({"id":"c35_journal","label":"CC98 · 离湖记录"})
	if s.chapterThreeInterlude.evidenceIds.has("journal_start"):
		list.append_array([{"id":"c35_photos","label":"照片 · 恢复项目"},{"id":"c35_voice","label":"录音"},{"id":"c35_official","label":"微信 · 楼宇通知"},{"id":"c35_messages","label":"微信 · 夜间自习群"},{"id":"c35_network","label":"浙大钉 · 网络记录"}])
	return list

func view(page: String, s: Dictionary) -> Dictionary:
	var c: Dictionary=s.chapterThreeInterlude
	match page:
		"c35_recovery":
			var body: String="检测到 7 分 55 秒未同步记录\n启真湖的离开记录仍在，后面的去向没有写入。手机时钟与带来源的记录不一致，不能直接采用。\n林星宇：我离开湖边以后，去了哪里？\n系统：照片、录音、消息都存了，就是没记清你去了哪。先看还能读出的。"
			if c.recoveryOpened:
				body="待核验时间窗：%s — %s\n已恢复 %d / 4 类证据" % ["22:37:05" if c.evidenceIds.has("journal_start") else "待恢复","22:45:00" if c.voiceSequenceSolved else "待恢复",c.evidenceIds.size()]
				if c.evidenceIds.size()==4: body+="\n食堂 0755 · 剧场 08:32 · 状态栏 07:55:23\n这些数字分别记的是什么？"
			return {"title":"未同步的七分五十五秒","body":body}
		"c35_journal": return {"title":"CC98 划船记录","body":"启真湖划船记录｜风景很好，返程提前了\n从小码头下水。湖面比岸边安静，风从剧场方向过来。最后一张照片没同步上来，我先回岸上整理。\n启真湖 · 22:37:05\n2楼：晚上水面反光挺亮，靠岸别太快。\n3楼：最后一张图像是朝东边拍的。"}
		"c35_photos":
			var selected: String=str(s.native.get("c35_frame","paper_middle"))
			var frame: Dictionary=FRAMES[1]
			for entry: Dictionary in FRAMES:
				if entry.id==selected: frame=entry
			return {"title":"恢复的项目 · 7 张","body":str(frame.label)+" · 07:55:23\n帧顺序损坏。观察照片中的位置变化，排除不连续或镜像的残片。","art":"res://assets/ui/photo-evidence/chapter35_live_"+str(frame.image)+".webp","mirror_art":frame.get("mirror",false)}
		"c35_voice":
			var body: String="录音时间索引异常。选择属于同一段路的录音，再排出连续顺序。"
			for recording: Dictionary in content("chapter3-interlude-voice-memos.audio.content").recordings:
				body+="\n"+str(recording.code)
				if voice_reviewed(s,str(recording.id)): body+=" · "+str(recording.time)+"\n"+str(recording.revealZh)
			return {"title":"录音","body":body,"media_session":voice_session}
		"c35_official": return {"title":"紫金港楼宇服务 · 22:40","body":"校园楼宇运行通知\n夜间闭楼与入口调整\n22:45 起，北教学区一处楼宇进入夜间清楼。A 楼一层东侧入口暂停通行，人员请从大厅主入口进入。\n主电梯保留运行，楼层开放情况以现场提示为准。"}
		"c35_messages":
			var body: String="群聊 · 18人"
			for entry: Dictionary in MESSAGES: body+="\n"+entry.author+"："+entry.text
			return {"title":"麦斯威夜间自习群","body":body}
		"c35_network":
			var body: String="夜间短会话 · 保存候选记录后，再与其他来源核对。"
			for entry: Dictionary in RECORDS: body+="\n"+entry.label+"\n"+entry.detail
			if c.networkRecordId!=null: body+="\n已保存："+str(c.networkRecordId)
			return {"title":"校园网络接入记录","body":body}
	return {}

func actions(page: String, s: Dictionary) -> Array:
	var c: Dictionary=s.chapterThreeInterlude
	if s.qizhenLake.phase!="complete" or c.completed: return []
	var list: Array=[]
	match page:
		"c35_recovery":
			if not c.recoveryOpened: return [command("c35_begin","打开恢复工具")]
			if c.evidenceIds.size()==4:
				for decoy: String in REASONS:
					if c.rejectedDecoyIds.has(decoy): continue
					list.append(field("c35_reject:"+decoy,{"canteen_0755":"食堂 0755：选择排除理由","theater_0832":"剧场 08:32：选择排除理由","status_clock_075523":"状态栏 07:55:23：选择排除理由"}[decoy],[option("number_not_time","这是编号，不是本段记录的时间"),option("earlier_independent_event","这是更早的独立事件"),option("frozen_local_clock","这是本机冻结值，不能代表实际时间")]))
				if exclusions_ready(c) and c.destinationId==null: list.append(field("c35_destination","选择最终地点",DESTINATIONS))
				if c.destinationId=="duan_yongping_a1": list.append(command("c35_replay","开始恢复回放"))
		"c35_journal":
			if c.recoveryOpened and not c.evidenceIds.has("journal_start"): list.append(field("c35_journal","保存最后一条离湖回复",[option("safe_return","安全返航"),option("details_withheld","细节暂不公开")]))
		"c35_photos":
			var opts: Array=[]
			for frame: Dictionary in FRAMES: opts.append(option(frame.id,frame.label))
			list.append(field("c35_frame","查看照片",opts))
			list.append(order_action("c35_photos","确认照片顺序",3,opts))
		"c35_voice":
			var opts: Array=[]
			for recording: Dictionary in content("chapter3-interlude-voice-memos.audio.content").recordings: opts.append(option(recording.id,recording.code))
			list.append(field("c35_listen","播放录音",opts))
			list.append(order_action("c35_voice","确认录音顺序",4,opts))
		"c35_official": list.append(command("c35_official","保存通知"))
		"c35_messages":
			var opts: Array=[]
			for entry: Dictionary in MESSAGES: opts.append(option(entry.id,entry.author+"："+entry.text))
			list.append(order_action("c35_route","保存路线截图",2,opts))
		"c35_network": list.append(field("c35_network","保存候选接入记录",RECORDS))
	return list

func order_action(id: String, label: String, count: int, opts: Array) -> Dictionary:
	var inputs: Array=[]
	for index: int in range(count): inputs.append({"id":"slot"+str(index),"label":"第 %d 位" % (index+1),"type":"choice","options":opts})
	return {"id":id,"label":label,"inputs":inputs}

func order_value(value: Variant, count: int) -> Array:
	if not value is Dictionary: return parse_order(value)
	var result: Array=[]
	for i: int in range(count): result.append(value.get("slot"+str(i),""))
	return result

func evidence(c: Dictionary, id: String) -> void:
	unique(c.evidenceIds,id)
	if c.evidenceIds.size()==4 and c.phase not in ["destination_verified","replay_ready"]: c.phase="timeline_assembly"

func network_ready(c: Dictionary) -> void:
	if c.officialNoticeSaved and c.routeScreenshotSaved and c.networkRecordRead: evidence(c,"network_destination")

func exclusions_ready(c: Dictionary) -> bool:
	return c.evidenceIds.size()==4 and c.rejectedDecoyIds.size()==3 and c.statusClockMarkedUntrusted

func dispatch(s: Dictionary, action: String, value: Variant = null) -> Dictionary:
	if not action.begins_with("c35_"): return {}
	var c: Dictionary=s.chapterThreeInterlude
	if s.qizhenLake.phase!="complete" or c.completed: return locked()
	if action=="c35_begin":
		c.recoveryOpened=true
		c.rebootSeen=true
		if c.phase in ["inactive","reboot"]: c.phase="journal_closeout"
		s.runtimeMode="phone"
		s.currentScene="timeline_recovery"
		return {"handled":true,"page":"c35_recovery","message":"恢复工具已打开。"}
	if not c.recoveryOpened: return locked("恢复工具尚未打开。")
	if action=="c35_summary_select":
		if value not in ["safe_return","details_withheld"]: return locked()
		s.native.c35_summary_choice=value
		return response()
	if action=="c35_journal":
		# Source completeJournalCloseout is idempotent. A stale submit must not
		# replace the published wording or send later evidence back a phase.
		if c.evidenceIds.has("journal_start"): return response("离湖回复已保存。")
		if value not in ["safe_return","details_withheld"]: return locked()
		s.qizhenLake.journal.summaryChoice=value
		s.qizhenLake.journal.summaryPublished=true
		s.qizhenLake.journal.memoryCardUnlocked=true
		s.qizhenLake.journal.status="archived"
		evidence(c,"journal_start")
		c.phase="evidence_collection"
		return response("已保存离湖回复：22:37:05。")
	if not c.evidenceIds.has("journal_start"): return locked("先在记录恢复中确认划船帖的离湖时间。")
	if action=="c35_photo_reset":
		# Source P18's Reorder clears only the local selection, never earned evidence.
		s.native.c35_photo_selection=[]
		return response()
	if action=="c35_media_event":
		if value != voice_session or not value is VoiceSession: return locked("录音播放回执已失效。")
		return accept_voice_receipt(s)
	if action=="c35_voice_clear":
		s.native.c35_voice_selection=[]
		s.native.c35_voice_stage="selection"
		return response()
	if action=="c35_voice_exit":
		var result: Dictionary=response()
		result.page="c35_recovery"
		if voice_session!=null: result.media=media_command("stop")
		return result
	if action=="c35_voice_stage":
		if value=="ordering" and s.native.get("c35_voice_selection",[]).size()!=4: return locked("先留下四段录音。")
		if value not in ["selection","ordering"]: return locked()
		s.native.c35_voice_stage=value
		return response()
	if action=="c35_voice_move":
		if not value is Dictionary or s.native.get("c35_voice_stage")!="ordering": return locked()
		var order: Array=s.native.get("c35_voice_selection",[]).duplicate()
		var index: int=order.find(str(value.get("id","")))
		var shift: int=int(value.get("shift",0))
		if index<0 or shift not in [-1,1] or index+shift<0 or index+shift>=order.size(): return locked()
		var swap: Variant=order[index+shift]
		order[index+shift]=order[index]
		order[index]=swap
		s.native.c35_voice_selection=order
		return response()
	if action in ["c35_select_photo","c35_select_voice","c35_select_route"]:
		if action=="c35_select_voice" and not voice_reviewed(s,str(value)): return locked("先试听这段录音，再决定是否保留。")
		var key: String={"c35_select_photo":"c35_photo_selection","c35_select_voice":"c35_voice_selection","c35_select_route":"c35_route_selection"}[action]
		var maximum: int=3 if action=="c35_select_photo" else 4 if action=="c35_select_voice" else 2
		var permitted: Array=[]
		if action=="c35_select_photo":
			for frame: Dictionary in FRAMES: permitted.append(frame.id)
		elif action=="c35_select_voice":
			for recording: Dictionary in content("chapter3-interlude-voice-memos.audio.content").recordings: permitted.append(recording.id)
		else:
			for message: Dictionary in MESSAGES: permitted.append(message.id)
		if str(value) not in permitted: return locked()
		var selection: Array=s.native.get(key,[]).duplicate()
		if selection.has(value): selection.erase(value)
		elif selection.size()<maximum: selection.append(value)
		else: return response("选择已满，先移除其中一项。")
		s.native[key]=selection
		return response()
	if action=="c35_filter":
		if not value is Dictionary: return locked()
		var options: Dictionary={"time":["all","missing_475","last_minute"],"session":["all","unknown_short","authenticated"],"area":["all","north_a","other"]}
		if not options.has(str(value.get("key"))) or str(value.get("value")) not in options[str(value.key)]: return locked()
		if not s.native.has("c35_network_filters"): s.native.c35_network_filters={"time":"all","session":"all","area":"all"}
		s.native.c35_network_filters[str(value.key)]=str(value.value)
		return response()
	match action:
		"c35_frame":
			for frame: Dictionary in FRAMES:
				if frame.id==str(value): s.native.c35_frame=str(value); return response()
			return locked()
		"c35_photos":
			# Keep the accepted evidence immutable on repeated/wrong submissions,
			# matching source submitPhotoSequence's already_complete boundary.
			if c.photoSequenceSolved: return response("连续帧已恢复。")
			var order: Array=order_value(value,3)
			c.photoFrameIds=order.filter(func(id: Variant) -> bool: return id in PHOTOS)
			if order!=PHOTOS: return response("照片中的移动不连续。再核对纸条位置、岸边参照和镜像方向。")
			c.photoSequenceSolved=true
			evidence(c,"photo_direction")
			return response("连续帧已恢复。")
		"c35_listen":
			var recording: Dictionary=voice_recording(str(value))
			if recording.is_empty(): return locked()
			if voice_session!=null and voice_session.clip_id==str(value) and voice_session.phase in ["playing","paused"]:
				return {"handled":true,"media":media_command("pause" if voice_session.phase=="playing" else "resume")}
			return start_voice(s,recording)
		"c35_excerpt":
			if not value is Dictionary: return locked()
			var recording: Dictionary=voice_recording(str(value.get("id","")))
			var index: int=int(value.get("index",-1))
			if recording.is_empty() or not voice_reviewed(s,str(recording.id)) or index<0 or index>=recording.get("soundEvents",[]).size(): return locked("先试听这段录音。")
			return start_voice(s,recording,index)
		"c35_voice":
			if c.voiceSequenceSolved: return response("录音已恢复，记录终点：22:45:00。")
			var order: Array=order_value(value,4)
			if order!=VOICES: return response("录音未形成连续路径。核对水声、硬岸、室内环境与末段广播。")
			for id: String in order:
				if not voice_reviewed(s,id): return locked("先试听这段录音，再决定是否保留。")
			c.voiceClipOrder=VOICES.duplicate()
			c.voiceSequenceSolved=true
			evidence(c,"broadcast_end")
			return response("录音已恢复，记录终点：22:45:00。")
		"c35_official":
			c.officialNoticeSaved=true
			network_ready(c)
			return response("公众号通知已保存。")
		"c35_route":
			var order: Array=order_value(value,2)
			if order.size()!=2 or not order.has("east_closed") or not order.has("west_cleaner"): return response("这两条消息还不能拼出可通行入口。需要同时确认封闭方向和可进入方向。")
			c.routeScreenshotSaved=true
			network_ready(c)
			return response("入口变化已截图：东侧关闭，西侧主入口可通行。")
		"c35_network":
			if not RECORDS.any(func(entry: Dictionary) -> bool: return entry.id==str(value)): return locked()
			c.networkRecordRead=true
			c.networkRecordId=str(value)
			network_ready(c)
			return response("候选接入记录已保存。")
		"c35_destination":
			if not exclusions_ready(c): return locked("先完成四类证据与旧时间核验。")
			if c.networkRecordId!="record_0755": return response("保存的接入记录对不上这个地点，再看一遍网络记录。")
			if str(value)!="duan_yongping_a1": return response({"qizhen_lake_dock":"录音末段出现室内广播和断电声，湖面环境无法解释这组声音。","theater_lobby":"末段短会话的接入点编号与剧场网络记录不一致。","basic_library_south":"闭楼通知和入口截图指向另一组楼宇入口规则。"}.get(str(value),"当前证据还不足以确认这个地点。"))
			c.destinationId="duan_yongping_a1"
			c.timelineOrder=EVIDENCE.duplicate()
			c.phase="destination_verified"
			return response("地点与四项证据一致，恢复结果已确认。")
		"c35_replay":
			if c.destinationId!="duan_yongping_a1" or not exclusions_ready(c): return locked()
			c.replayUnlocked=true
			c.phase="replay_ready"
			return {"handled":true,"page":"c4_notes","message":"时间与地点已经完成交叉核验。"}
	if action.begins_with("c35_reject:"):
		var id: String=action.trim_prefix("c35_reject:")
		if c.evidenceIds.size()!=4: return locked("四项证据还没收齐。")
		if REASONS.get(id)!=value: return response("这条理由与记录来源不匹配。")
		unique(c.rejectedDecoyIds,id)
		if id=="status_clock_075523": c.statusClockMarkedUntrusted=true
		if exclusions_ready(c): c.timelineOrder=EVIDENCE.duplicate()
		return response({"canteen_0755":"0755 是取餐编号，不能作为夜间时间。","theater_0832":"08:32 来自更早的独立抢票记录。","status_clock_075523":"07:55:23 是未同步的本机时钟值。"}[id])
	return locked()

func objective(s: Dictionary) -> String:
	var c: Dictionary=s.chapterThreeInterlude
	if s.qizhenLake.phase!="complete" or c.completed: return ""
	if not c.recoveryOpened: return "打开未同步记录"
	if not c.evidenceIds.has("journal_start"): return "查清离开湖边的时间"
	if c.evidenceIds.size()<4: return "查清离湖后去了哪里"
	if not exclusions_ready(c): return "排除旧时间记录"
	if c.destinationId==null: return "根据证据确认目的地"
	return "回看离湖后的那段路"

func filtered_records(s: Dictionary) -> Array:
	var filters: Dictionary=s.native.get("c35_network_filters",{"time":"all","session":"all","area":"all"})
	var groups: Dictionary={"record_0755":["missing_475","unknown_short","north_a"],"record_theater_hall":["missing_475","authenticated","north_a"],"record_library_south":["missing_475","unknown_short","other"],"record_qizhen_dock":["last_minute","unknown_short","north_a"]}
	var result: Array=[]
	for record: Dictionary in RECORDS:
		var match_filters: bool=true
		for index: int in range(3):
			var key: String=["time","session","area"][index]
			if filters.get(key,"all")!="all" and filters[key]!=groups[record.id][index]: match_filters=false
		if match_filters: result.append(record)
	return result

func voice_recording(id: String) -> Dictionary:
	for recording: Dictionary in content("chapter3-interlude-voice-memos.audio.content").recordings:
		if recording.id==id: return recording
	return {}

func voice_reviewed(s: Dictionary,id: String) -> bool:
	return s.native.get("c35_listened",[]).has(id) or s.native.get("c35_reviewed",[]).has(id)

func media_command(command_name: String) -> Dictionary:
	return {"command":command_name,"session":voice_session,"on_event":"c35_media_event"}

func accept_voice_receipt(s: Dictionary) -> Dictionary:
	if voice_session==null: return locked()
	if voice_session.heard_ready:
		if not s.native.has("c35_listened"): s.native.c35_listened=[]
		unique(s.native.c35_listened,voice_session.clip_id)
	if voice_session.reviewed_ready:
		if not s.native.has("c35_reviewed"): s.native.c35_reviewed=[]
		unique(s.native.c35_reviewed,voice_session.clip_id)
	return response()

func start_voice(s: Dictionary,recording: Dictionary,event_index: int=-1) -> Dictionary:
	if voice_session!=null:
		voice_session.sample()
		accept_voice_receipt(s)
	var generated: Dictionary=content("chapter3-interlude-voice-memos.audio.generated").assets.get(recording.asset,{})
	var duration: float=float(generated.get("durationMs",recording.targetDurationMs))
	var start: float=0.0
	var end: float=duration
	if event_index>=0:
		var part: Dictionary=recording.soundEvents[event_index]
		start=maxf(0,float(part.startMs)-180)
		end=minf(duration,float(part.endMs)+220)
	voice_session=VoiceSession.new(str(recording.id),"res://assets/audio/"+str(generated.get("path","")),duration,start,end,event_index<0)
	return {"handled":true,"media":media_command("play")}
