extends RefCounted
## Native chapter-one and movement-prelude authority. Presentation never grants facts.
const Utilities = preload("res://scripts/chapters/phone_utilities.gd")
var utilities = Utilities.new()
const Library022 = preload("res://scripts/chapters/library022.gd")
const MOVEMENT_PHASES = ["movement_required", "reservation_briefing_required", "reservation_required", "movement_ready"]
var library = Library022.new()
var cache: Dictionary = {}
const PhoneEntry=preload("res://scripts/chapters/phone_entry_session.gd")
var entry_session=PhoneEntry.new()

func phone_entry_session(s: Dictionary) -> RefCounted:
	var replacing:=not is_same(entry_session.owner,s)
	var leaving_friend: bool=entry_session.family=="wechat" and str(s.native.page) not in ["wechat","control_center"]
	if replacing or leaving_friend: s.native.friend_scatter_pending=false
	entry_session.route(s)
	return entry_session

func _tiyi_entry_allowed(s: Dictionary) -> bool:
	return entry_session.entry_allowed if is_same(entry_session.owner,s) and entry_session.family=="tiyi" else s.networkMode=="cellular"


func _content(name: String) -> Dictionary:
	if not cache.has(name):
		var path = "res://data/source/" + name
		cache[name] = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else {}
	return cache[name] if cache[name] is Dictionary else {}

func _ok(message: String, extra: Dictionary = {}) -> Dictionary:
	var result = {"handled": true, "message": message}
	result.merge(extra, true)
	return result

func _page(s: Dictionary, page: String, message: String = "") -> Dictionary:
	s.native.page = page
	s.currentScene = page
	return _ok(message, {"page": page})

func _scene(s: Dictionary, scene: String, message: String = "") -> Dictionary:
	s.native.scene = scene
	s.rpgScene = scene
	s.runtimeMode = "rpg"
	return _ok(message, {"scene": scene, "open_world": true})

func _action(id: String, label: String, input: String = "", options: Array = []) -> Dictionary:
	var a = {"id": id, "label": label}
	if not input.is_empty(): a.input = input
	if not options.is_empty(): a.options = options
	return a

func _prologue(s: Dictionary) -> bool:
	return s.actOne.phase == "prologue"

func _movement(s: Dictionary) -> bool:
	return MOVEMENT_PHASES.has(s.actOne.phase)

func pages(s: Dictionary) -> Array:
	if int(s.native.get("chapter", 1)) > 2: return [{"id":"control_center","label":"控制中心"}]
	if s.native.get("page", "alarm") == "alarm": return [{"id":"alarm","label":"闹钟"}]
	if s.native.get("page", "") == "desktop": return [{"id":"desktop","label":"07:55"}]
	if _prologue(s) and s.flags.checkinDone: return [{"id":"ending","label":"经度与纬度不存在"}]
	var result: Array = [{"id":"phone_home","label":"手机主页"}, {"id":"wechat","label":"微信"}, {"id":"zjuding","label":"浙大钉"}, {"id":"tiyi","label":"浙大体艺"}, {"id":"control_center","label":"控制中心"}]
	if _prologue(s):
		result.append({"id":"checkin","label":"学在浙大"})
		result.append({"id":"bonsai","label":"盆栽"})
	else:
		result.append({"id":"settings","label":"设置"})
		result.append({"id":"cc98","label":"CC98"})
		result.append({"id":"weather","label":"天气"})
		result.append({"id":"directory","label":"部门黄页"})
		if s.items.campusCard: result.append({"id":"campus_card","label":"校园卡"})
		result.append_array(library.pages(s))
	return result

func view(page: String, s: Dictionary) -> Dictionary:
	if page == "settings": return {"title":"设置","body":"PHONE SYSTEM"}
	if page == "control_center":
		return {"title":"控制中心", "body":"07:55\n网络：%s\n亮度：%s%%\n自动旋转：%s\n音乐：%s" % [s.networkMode, s.ui.brightness, "开启" if s.ui.autoRotate else "关闭", "播放中" if s.ui.musicPlaying else "暂停"]}
	if int(s.native.get("chapter", 1)) > 2: return {}
	var lib_view: Dictionary = library.view(page, s)
	if not lib_view.is_empty(): return lib_view
	match page:
		"alarm": return {"title":"07:55", "body":"闹钟\n起床"}
		"desktop": return {"title":"07:55", "body":"……再睡5分钟……"}
		"phone_home":
			var body = "7月9日　星期四\n07:55　小雨\n微信　浙大体艺　浙大钉"
			if _prologue(s):
				body += "\n设置齿轮看起来很想转转。钟楼大门紧锁，锁孔的形状有点奇怪。\n盆栽：它绝对不会开花。"
				if s.flags.gearFallen and not s.flags.gearNineTaken: body += "\n齿轮掉下来了，背面朝外。"
			elif s.actOne.exerciseStarted and not s.actOne.pushTriangleTaken: body += "\n新通知：方向校准　▶\n头像边缘有一个三角形。"
			return {"title":"手机主页", "body":body}
		"wechat":
			var body = "朋友　07:55\n快快老师在点名，学在浙大\n\n室友　07:21\n晚上一起去食堂吃饭呀~\n\n导师　07:18\n请把实验报告的初稿发我一下。"
			if _prologue(s) and s.flags.codeScattered: body += "\n\n朋友：这是签到码 ▓▓▓▓\n头像上有一条斜线。"
			if s.actOne.phase == "friend_message_required": body = "朋友：成功了吗\n玩家：没有，但我正试着威胁系统\n朋友：？"
			if _movement(s) and not s.actOne.mentorLineReleased: body += "\n导师头像：两枚卡扣封住了一条竖线，胶缝里似乎缺一点能流动的东西。"
			return {"title":"微信", "body":body}
		"system_chat":
			var body = "系统：哦，该死。你赢了，孩子。\n玩家：拜托了，帮我改一下签到记录\n系统：行。把你的道具栏拿出来。\n系统：等等，你的道具栏呢？你总不能指望我空手干活！\n系统：去。找。到。它。"
			if s.actOne.phase == "system_return_required": body = "系统：你找到了，那就太好了，我们出发吧！\n玩家：？\n系统：我得说实话了，我没有修改记录权限。\n系统：但我有一个朋友她或许能做到。\n系统：如果我们还想要平时分，就得去图书馆找她。\n系统：明白了？那就快行动吧！"
			if s.actOne.phase == "reservation_briefing_required": body = "系统：别打扰我……哦，你已经完事了，速度还挺快的\n系统：我以为你要在寝室“就再睡一会儿”呢\n系统：你知道的，去图书馆要先完成座位预约。\n系统：基础馆一层书库022，记住了。"
			return {"title":"系统", "body":body}
		"checkin": return {"title":"学在浙大 · 校务签到", "body":"本周缺勤 0 次\n请输入四位签到码\n签到需使用校园网"}
		"ending": return {"title":"经度与纬度不存在", "body":"坐标系统无法确认你的到场记录。"}
		"tiyi":
			if not _tiyi_entry_allowed(s): return {"title":"浙大体艺", "body":"正在连接……\n校园网已经尽力了，你也是。", "art":"ui/tiyi_loading.png"}
			return {"title":"浙大体艺", "body":"课外锻炼　47\n运动记录\n" + ("10:00 / 3.00km / 03′20″" if s.actOne.exerciseStarted else "尚无有效课外锻炼记录"), "art":"ui/tiyi_main.png"}
		"bonsai": return {"title":"盆栽", "body":"开花了？！" if s.flags.flowerBloomed else "它绝对不会开花。\n水分、光照、养分各缺不得。", "art":"ui/bonsai_bloom.png" if s.flags.flowerBloomed else "ui/bonsai_bud.png"}
		"zjuding": return {"title":"浙大钉", "body":"应用服务\n学在浙大　电子校园卡　部门黄页　图书馆　校园地图\n" + ("校园地图暂未开放。" if not s.actOne.dormHubUnlocked else "寝室　基础馆")}
		"campus_card": return {"title":"电子校园卡", "body":"浙江大学\n林星宇\n学号　3250100755\n账户余额　¥ %.2f" % (float(s.wallet.campusCardCents) / 100.0)}
		"directory": return {"title":"部门黄页", "body":"校园服务台　87950000\n游戏联络台　3250100755\n体艺值班台　87951234\n\n游戏联络台：请核对你的姓名和学号。"}
		"weather": return {"title":"杭州 · 天气", "body":"小雨　22°C\n雨滴沿着屏幕边缘落下。"}
		"cc98":
			if s.networkMode != "campus_wifi": return {"title":"CC98", "body":"当前网络无法打开 CC98，请先恢复可访问的网络环境。"}
			if not s.actOne.cc98Login.authenticated:
				var hints = ["取浙江大学英文名的三个大写字母。", "接上求是书院创办的四位年份。", "保留认证公告最后的感叹号。"]
				var body = "浙江大学统一身份认证\n学号只从随身校园卡读取。\n认证公告：请输入校名、年份和标点！"
				for i in range(int(s.actOne.cc98Login.revealedHintCount)): body += "\n" + hints[i]
				return {"title":"统一身份认证", "body":body}
			var c: Dictionary = _content("act-one-bootstrap.content.json").get("cc98ExchangePost", {})
			return {"title":"CC98 · 二手市场", "body":str(c.get("title", "6块出游戏手柄，寝室自提")) + "\n" + str(c.get("body", "方向键、摇杆和一个不太灵的 A 键都在。只收 6 元，不议价，也不接受 0.06 元分期。"))}
	return {}

func actions(page: String, s: Dictionary) -> Array:
	if page == "control_center":
		var out = [_action("c1_network", "切换网络", "choice", ["校园网", "移动数据", "离线"]), _action("c1_brightness", "调整屏幕亮度", "number"), _action("c1_auto_rotate", "开关自动旋转"), _action("c1_music", "播放 / 暂停音乐")]
		if _prologue(s) and not s.flags.headphoneFallen: out.append(_action("c1_headphone", "触碰挂着的耳机"))
		return out
	if int(s.native.get("chapter", 1)) > 2: return []
	var lib_actions: Array = library.actions(page, s)
	if not lib_actions.is_empty(): return lib_actions
	match page:
		"alarm": return [_action("c1_dismiss_alarm", "关闭闹钟")] if s.native.get("alarm_ringing",false) else [_action("c1_start_alarm", "开始游戏")]
		"desktop": return [_action("c1_enter_home", "进入手机主界面")] if s.native.get("wake_warned",false) else [_action("c1_wake", "……再睡5分钟……")]
		"ending": return [_action("c1_resume_ending", "继续拦住旁白")]
		"phone_home":
			var out: Array = []
			if _prologue(s) and not s.flags.checkinDone:
				out.append(_action("c1_gear", "查看设置齿轮"))
				if s.flags.gearFallen and not s.flags.gearNineTaken: out.append(_action("c1_collect_gear", "拾起掉落齿轮"))
				if s.flags.codeScattered and not s.flags.waterDropTaken: out.append(_action("c1_rain_drop", "接住屏幕上的雨滴"))
				out.append(_action("c1_tower", "将道具放进钟楼锁孔", "choice", _owned(s)))
			if _movement(s) and s.actOne.exerciseStarted and not s.actOne.pushTriangleTaken: out.append(_action("c2_triangle", "触碰推送头像的三角形"))
			out.append(_form("c1_combine", "组合两件道具", [{"id":"a","label":"第一件道具","type":"choice","options":_owned(s)},{"id":"b","label":"第二件道具","type":"choice","options":_owned(s)}]))
			return out
		"wechat":
			if _prologue(s):
				if not s.flags.codeScattered: return [_action("c1_friend", "打开朋友的新消息")]
				return [_action("c1_avatar", "触碰朋友头像的斜线")]
			if s.actOne.phase == "friend_message_required": return [_action("c2_friend_exchange", "回复朋友")]
			var out: Array = []
			if _movement(s) and not s.actOne.mentorLineReleased: out.append(_action("c2_mentor", "对导师头像使用道具", "choice", _owned(s)))
			return out
		"system_chat":
			if s.actOne.phase == "system_required": return [_action("c2_confront_system", "询问道具栏")]
			if s.actOne.phase == "system_return_required": return [_action("c2_movement_quest", "听完系统的说明")]
			if s.actOne.phase == "reservation_briefing_required": return [_action("c2_reservation_briefing", "记下预约要求")]
			return []
		"checkin":
			if not _prologue(s) or s.flags.checkinDone: return []
			return [_action("c1_absence", "查看本周缺勤记录"), _action("c1_checkin", "提交签到码", "text")]
		"tiyi":
			if not _tiyi_entry_allowed(s): return [_action("c1_tiyi_load", "等待加载")]
			if _prologue(s): return [_action("c1_tiyi_digit", "查看黄色锻炼次数")]
			if _movement(s) and not s.actOne.exerciseStarted: return [_action("c2_exercise", "开始虚拟定位跑步")]
			return []
		"bonsai":
			return [_action("c1_plant", "对盆栽使用道具", "choice", _owned(s)), _action("c1_plant_light", "让屏幕照亮盆栽"), _action("c1_collect_flower", "拾起花心数字") if s.native.get("flower_eight_visible",false) else _action("c1_flower", "查看花心")]
		"zjuding":
			var out: Array = []
			if s.actOne.phase in ["system_required","inventory_required","system_return_required","reservation_briefing_required"]: out.append(_action("c2_open_system", "查看求是印章"))
			if s.actOne.dormHubUnlocked: out.append(_action("c2_enter_dorm", "校园地图 · 进入寝室"))
			if s.actOne.phase == "complete": out.append(_action("c2_enter_campus", "校园地图 · 返回校园"))
			return out
		"campus_card":
			return [_action("c2_card_identity", "读取卡面身份"), _action("c2_balance", "对余额使用道具", "choice", _owned(s))]
		"directory": return [_form("c2_identify", "联络游戏联络台", [{"id":"name","label":"姓名","type":"text"},{"id":"student_id","label":"学号","type":"text"}])]
		"weather": return [_action("c2_weather_drop", "收集天气雨滴")] if _movement(s) else []
		"cc98":
			if s.networkMode != "campus_wifi": return []
			if not s.actOne.cc98Login.authenticated: return [_action("c2_login_hint", "查看下一段密码提示"), _form("c2_login", "提交学号和密码", [{"id":"student_id","label":"校园卡学号","type":"text"},{"id":"password","label":"剧情认证密码","type":"text"}])]
			return [_action("c2_purchase_gamepad", "支付 ¥6.00 购买手柄")] if _movement(s) and not s.actOne.gamepadPurchased else []
	return []

func _form(id: String, label: String, inputs: Array) -> Dictionary:
	return {"id":id,"label":label,"inputs":inputs}

func _owned(s: Dictionary) -> Array:
	var values: Array = []
	var metadata: Dictionary = {}
	var path = "res://data/source/items.config.json"
	if FileAccess.file_exists(path):
		var data = JSON.parse_string(FileAccess.get_file_as_string(path))
		if data is Array:
			for item in data: metadata[str(item.id)] = str(item.name)
	for item in s.items:
		if s.items[item]: values.append({"id":item,"label":metadata.get(item,item)})
	return values

func dispatch(s: Dictionary, action: String, value: Variant = null) -> Dictionary:
	phone_entry_session(s)
	var utility_result = utilities.dispatch(s,action,value)
	if not utility_result.is_empty(): return utility_result
	var lib_result: Dictionary = library.dispatch(s, action, value)
	if not lib_result.is_empty(): return lib_result
	if not action.begins_with("c1_") and not action.begins_with("c2_"): return {}
	if action in ["c1_network", "c1_brightness", "c1_music", "c1_auto_rotate"]: return _control(s, action, value)
	if action.begins_with("c1_"): return _chapter_one(s, action, value)
	return _movement_dispatch(s, action, value)

func _control(s: Dictionary, action: String, value: Variant) -> Dictionary:
	match action:
		"c1_network":
			var modes = {"校园网":"campus_wifi", "移动数据":"cellular", "离线":"offline", "campus_wifi":"campus_wifi", "cellular":"cellular", "offline":"offline"}
			if not modes.has(str(value)): return _ok("请选择有效网络。")
			if s.networkMode != modes[str(value)]:
				s.networkMode = modes[str(value)]
				s.phoneBattery.percent = maxi(1, int(s.phoneBattery.percent) - 1)
			return _ok("网络已切换。")
		"c1_brightness":
			if not str(value).is_valid_float(): return _ok("请输入 0 至 100 的亮度。")
			s.ui.brightness = clampf(float(value), 0, 45 if s.phoneBattery.lowPowerMode else 100)
			return _ok("屏幕亮度已调整。")
		"c1_music":
			if s.phoneBattery.lowPowerMode and not s.ui.musicPlaying: return _ok("低电量模式下音乐已暂停。")
			s.ui.musicPlaying = not s.ui.musicPlaying
			return _ok("音乐播放状态已切换。")
		"c1_auto_rotate":
			s.ui.autoRotate = not s.ui.autoRotate
			return _ok("自动旋转已开启。" if s.ui.autoRotate else "自动旋转已关闭。")
	return {}

func _chapter_one(s: Dictionary, action: String, value: Variant) -> Dictionary:
	if action == "c1_combine": return _combine(s, value)
	if action in ["c1_tiyi_load","c1_tiyi_crash","c1_tiyi_exit"]:
		if entry_session.family!="tiyi" or entry_session.entry_allowed: return _ok("")
		if action=="c1_tiyi_crash":
			if entry_session.elapsed_ms<3000 or entry_session.crash_recorded: return _ok("")
			entry_session.crash_recorded=true
			s.flags.tiyiCrashCount+=1
			return _ok("",{"presentation":["native_tiyi_crash"]})
		if entry_session.elapsed_ms<3620 or not entry_session.crash_recorded: return _ok("")
		var result:=_page(s,"phone_home","「浙大体艺」已停止运行。" if s.flags.tiyiCrashCount==1 else "「浙大体艺」又双叒停止运行了。" if s.flags.tiyiCrashCount==2 else "")
		if s.flags.tiyiCrashCount>=3: result.presentation=["native_tiyi_crash_taunt"]
		return result
	if not _prologue(s): return _ok("这项操作已经不属于当前剧情阶段。")
	var f: Dictionary = s.flags
	var items: Dictionary = s.items
	match action:
		"c1_start_alarm":
			s.native.alarm_ringing = true
			return _ok("")
		"c1_dismiss_alarm":
			if not s.native.get("alarm_ringing",false): return _ok("先开始游戏。")
			return _page(s, "desktop")
		"c1_wake":
			s.native.wake_warned = true
			return _ok("起床蠢货！！！")
		"c1_enter_home":
			if not s.native.get("wake_warned",false): return _ok("你没有5分钟了，但你很有勇气。")
			return _page(s,"phone_home")
		"c1_friend":
			if f.codeScattered: return _ok("朋友的签到码已经被打散了。")
			entry_session.start_friend()
			s.native.friend_scatter_pending = true
			return _ok("")
		"c1_friend_cancel":
			entry_session.close_friend()
			s.native.friend_scatter_pending = false
			return _ok("")
		"c1_scatter_complete":
			if f.codeScattered or not s.native.get("friend_scatter_pending",false) or not value is Dictionary: return _ok("")
			var required_ms=9380 if value.get("skipped",false) else 19322
			if int(value.get("elapsedMs",0))<required_ms or int(value.get("phase",0))!=4: return _ok("")
			f.codeScattered=true
			s.native.friend_scatter_pending=false
			return _ok("任务更新：找回四位签到码")
		"c1_absence":
			if not f.codeScattered: return _ok("本周缺勤 0 次。")
			f.cardZeroTaken = true
			s.digits.d1 = "0"
			return _ok("已记下缺勤记录中的数字。")
		"c1_tiyi_digit":
			if not _tiyi_entry_allowed(s): return _ok("浙大体艺需要移动数据。")
			f.tiyiCountTaken = true
			s.digits.d2 = "7"
			return _ok("黄色次数的一部分被取下。")
		"c1_gear":
			if f.gearNineTaken: return _ok("设置图标只剩一个空位，风从里面吹过。")
			return _ok("它转起来了！" if s.ui.autoRotate else "它看起来很想转转。")
		"c1_gear_rotated":
			if not s.ui.autoRotate or f.gearFallen or not value is Dictionary or float(value.get("elapsedMs",0)) < 1500: return _ok("旋转还未完成。")
			f.gearFallen = true
			s.ui.autoRotate = false
			return _ok("哐当——齿轮转了半圈，掉下来了。背面朝外。")
		"c1_slash_rotated":
			if not s.ui.autoRotate or not f.codeScattered or f.slashHalfDropped or not value is Dictionary or float(value.get("elapsedMs",0)) < 1100: return _ok("斜线还没有断开。")
			f.slashHalfDropped = true
			s.ui.autoRotate = false
			return _ok("咔——斜线断了一截，挂在头像框上晃悠。")
		"c1_collect_gear":
			if not f.gearFallen or f.gearNineTaken: return _ok("这里没有新的掉落齿轮。")
			f.gearNineTaken = true
			s.digits.d3 = "9"
			items.reverseGear = true
			return _ok("获得反向齿轮，背面的数字已记下。")
		"c1_avatar":
			if not f.codeScattered: return _ok("朋友：快快老师在点名，学在浙大。")
			if f.slashTaken: return _ok("头像上的斜线已经取走。")
			if not f.slashHalfDropped: return _ok("斜线晃了晃，还没掉。" if s.ui.autoRotate else "头像上的斜线纹丝不动。或许可以再斜一点。")
			f.slashTapCount += 1
			if f.slashTapCount >= 3:
				f.slashTaken = true
				items.slashLine = true
				return _ok("检测到未经授权的友情支援。获得斜线。")
			return _ok("你戳了戳剩下的一端……")
		"c1_headphone":
			if not s.ui.musicPlaying: return _ok("耳机安静地挂着，不理你。")
			if f.headphoneFallen: return _ok("耳机已经掉下来了。")
			f.headphoneFallen = true
			items.headphone = true
			return _ok("耳机掉了下来，背面朝下。")
		"c1_rain_drop":
			if not f.codeScattered or f.waterDropTaken: return _ok("没有可收集的新雨滴。")
			f.waterDropTaken = true
			items.waterDrop = true
			return _ok("接住了一滴早八雨。")
		"c1_tower":
			if f.towerOpened: return _ok("钟楼已经把秘密交出去了。")
			if str(value) != "towerKey" or not items.towerKey: return _ok("塞不进去。锁孔的形状有点奇怪。")
			s.native.tower_key_pending=true
			return _ok("")
		"c1_tower_complete":
			if f.towerOpened or not items.towerKey or not s.native.get("tower_key_pending",false) or not value is Dictionary or int(value.get("elapsedMs",0))<1700: return _ok("")
			s.native.tower_key_pending=false
			items.towerKey = false
			items.fertilizer = true
			f.towerOpened = true
			s.native.selected_item=""
			s.ui.selectedItem=null
			return _ok("钥匙旋转 90°——咔哒。塔楼吐出[一袋肥料]。")
		"c1_plant":
			if str(value) == "wateredHeadphone" and items.wateredHeadphone and not f.plantWatered:
				f.plantWatered = true
				items.wateredHeadphone = false
			elif str(value) == "fertilizer" and items.fertilizer and not f.plantFertilized:
				f.plantFertilized = true
				items.fertilizer = false
			else: return _ok("没什么反应。需要合适的道具。")
			_bloom(s)
			return _ok("盆栽好像有点想开花。" if not f.flowerBloomed else "开花了？！")
		"c1_plant_light":
			if float(s.ui.brightness) < 80: return _ok("光线还不够。")
			f.plantLit = true
			_bloom(s)
			return _ok("已照光。")
		"c1_flower":
			if not f.flowerBloomed: return _ok("它绝对不会开花。")
			if f.flowerEightTaken: return _ok("花心空空的。")
			s.native.flower_eight_visible = true
			return _ok("")
		"c1_collect_flower":
			if not f.flowerBloomed or not s.native.get("flower_eight_visible",false) or f.flowerEightTaken: return _ok("花心里没有能取下的数字。")
			s.native.flower_eight_visible = false
			f.flowerEightTaken = true
			s.digits.d4 = "8"
			return _ok("花心里的数字已记下。")
		"c1_checkin":
			if f.checkinDone: return _ok("签到已经提交。")
			if s.networkMode != "campus_wifi": return _ok("请连接校园网。")
			if str(value).strip_edges() != "0798": return _ok("签到码错误。")
			f.checkinDone = true
			for item in ["waterDrop", "headphone", "wateredHeadphone"]: items[item] = false
			s.ui.inventoryOpen = false
			s.ui.selectedItem = null
			s.native.selected_item = ""
			s.native.page = "ending"
			return _ending_game(false)
		"c1_resume_ending":
			if not f.checkinDone: return _ok("签到尚未完成。")
			return _ending_game(true)
		"c1_intervention_result":
			if not f.checkinDone or not value is Dictionary: return _ok("没有有效的旁白拦截记录。")
			if value.get("failed", true) or int(value.get("interceptedCount", 0)) < 3 or float(value.get("lockHeldMs", 0)) < 1400 or int(value.get("dialogueCount", 0)) < 4 or not value.get("whiteoutCompleted", false): return _ok("必须拦截三次、持续锁定，并听完交涉。")
			s.actOne.phase = "friend_message_required"
			s.actOne.inventoryRecovered = false
			s.actOne.dormHubUnlocked = false
			s.native.chapter = 2
			s.native.scene = ""
			s.runtimeMode = "phone"
			return _page(s, "phone_home", "朋友发来了一条新消息。")
	return _ok("当前阶段没有这个操作。")

func _ending_game(resume: bool) -> Dictionary:
	return _ok("", {"game":{"script":"res://scripts/games/prologue_interception.gd", "type":"interception", "on_success":"c1_intervention_result", "title":"经度与纬度不存在", "resume":resume, "viewport":[430,820]}})

func _bloom(s: Dictionary) -> void:
	s.flags.flowerBloomed = s.flags.plantWatered and s.flags.plantLit and s.flags.plantFertilized

func _combine(s: Dictionary, value: Variant) -> Dictionary:
	if value is Dictionary: value = [value.get("a",""),value.get("b","")]
	var parts: Array = value if value is Array else Array(str(value).replace("+", " ").replace("，", " ").replace(",", " ").split(" ", false))
	if parts.size() != 2: return _ok("请输入两件道具名称，以空格或 + 分开。")
	var aliases = {"斜线":"slashLine", "反向齿轮":"reverseGear", "水滴":"waterDrop", "耳机":"headphone", "三角形":"pushTriangle", "竖线":"mentorLine"}
	var a = str(aliases.get(str(parts[0]), str(parts[0])))
	var b = str(aliases.get(str(parts[1]), str(parts[1])))
	if a == b or not s.items.get(a, false) or not s.items.get(b, false): return _ok("两件道具都必须在道具栏里。")
	for recipe in [["slashLine","reverseGear","towerKey","钥匙"], ["waterDrop","headphone","wateredHeadphone","盛水的耳机"], ["pushTriangle","mentorLine","rightArrow","右移箭头"]]:
		if (recipe[0] == a and recipe[1] == b) or (recipe[0] == b and recipe[1] == a):
			s.items[a] = false
			s.items[b] = false
			s.items[recipe[2]] = true
			if recipe[2] == "rightArrow": s.actOne.rightArrowAssembled = true
			return _ok("获得" + recipe[3] + "。")
	return _ok("这两件道具无法组合。")

func _movement_dispatch(s: Dictionary, action: String, value: Variant) -> Dictionary:
	var a: Dictionary = s.actOne
	var items: Dictionary = s.items
	if _prologue(s): return _ok("序章尚未结束。")
	match action:
		"c2_friend_exchange":
			if a.phase != "friend_message_required": return _ok("朋友：？")
			a.phase = "system_required"
			return _ok("朋友：成功了吗\n玩家：没有，但我正试着威胁系统\n朋友：？")
		"c2_open_system": return _page(s, "system_chat")
		"c2_confront_system":
			if not ["system_required", "inventory_required", "system_return_required"].has(a.phase): return _ok("系统暂时没有新的要求。")
			a.phase = "system_return_required" if a.inventoryRecovered and items.campusCard else "inventory_required"
			a.dormHubUnlocked = true
			s.rpgCheckpoint = "dorm_spawn"
			return _ok("系统要求你找回道具栏。校园地图里的寝室已经开放。")
		"c2_enter_dorm":
			if not a.dormHubUnlocked: return _ok("寝室尚未开放。")
			return _scene(s, "dorm_hub", "蓝田六舍 · W12\n室友留言：你的校园卡压在右边书桌那摞纸旁边。")
		"c2_dorm_prop":
			if s.native.scene!="dorm_hub" or not a.dormHubUnlocked or str(value) not in ["cabinet_open","lamp_01_on","lamp_03_on"]:return _ok("")
			if not s.native.has("dorm_props"):s.native.dorm_props={"cabinet_open":false,"lamp_01_on":false,"lamp_03_on":false}
			s.native.dorm_props[str(value)]=not s.native.dorm_props[str(value)]
			return _ok("")
		"c2_recover_card":
			if a.phase != "inventory_required" or s.native.scene != "dorm_hub": return _ok("现在无法取回校园卡。")
			items.campusCard = true
			a.inventoryRecovered = true
			a.phase = "system_return_required"
			s.ui.inventoryOpen = true
			return _ok("在右侧个人书桌取回校园卡，道具栏恢复了。")
		"c2_movement_quest":
			if a.phase != "system_return_required" or not a.inventoryRecovered: return _ok("先把道具栏找回来。")
			a.phase = "movement_required"
			return _page(s, "phone_home", "系统的朋友在图书馆。得先找到移动的办法。")
		"c2_inspect_character":
			if not _movement(s): return _ok("小人站在寝室里。")
			a.characterPromptSeen = true
			return _ok("他听不到你说话。现在的他连一个能回应的名字都没有。" if not a.characterNamed else "他好像没什么动力走。" if not a.exerciseStarted else "他走起来了，但他不知道该往哪里走。")
		"c2_card_identity":
			if not a.inventoryRecovered or not items.campusCard: return _ok("需要随身校园卡。")
			a.cc98Login.studentIdDiscovered = true
			return _ok("林星宇　3250100755")
		"c2_identify":
			if not _movement(s) or not a.inventoryRecovered: return _ok("游戏联络台现在忙。")
			var parts = [str(value.get("name","")),str(value.get("student_id",""))] if value is Dictionary else _split(value)
			if parts.size() != 2 or _normal_text(str(parts[0])).replace(" ","") != "林星宇" or _student_id(str(parts[1])) != "3250100755": return _ok("姓名和学号不匹配。请核对校园卡。")
			a.characterNamed = true
			a.identityVerified = true
			return _ok("姓名和学号一致。很好，他现在知道自己是谁了。")
		"c2_exercise":
			if not _movement(s) or not a.characterNamed or not _tiyi_entry_allowed(s): return _ok("需要有效身份和移动数据连接。")
			if a.exerciseStarted: return _ok("锻炼记录已经同步。")
			return _ok("", {"game":{"script":"res://scripts/games/virtual_run.gd","on_success":"c2_exercise_result","title":"虚拟定位跑步","viewport":[430,820]}})
		"c2_exercise_result":
			if not _movement(s) or not a.characterNamed or not value is Dictionary: return _ok("本次锻炼无效。")
			if value.get("failed", true) or int(value.get("points", 0)) != 10 or int(value.get("distanceMeters", 0)) != 3000 or int(value.get("elapsedSeconds", 0)) != 600: return _ok("必须依次完成十个定位点。")
			a.exerciseStarted = true
			return _ok("10:00 / 3.00km / 03′20″\n锻炼记录已同步。")
		"c2_triangle":
			if not _movement(s) or not a.exerciseStarted: return _ok("这条推送现在只负责占位置。")
			if a.pushTriangleTaken: return _ok("三角形已经取下。")
			a.pushTriangleTapCount = mini(3, int(a.pushTriangleTapCount) + 1)
			if a.pushTriangleTapCount == 3:
				a.pushTriangleTaken = true
				items.pushTriangle = true
				return _ok("获得三角形。")
			return _ok("头像边缘松了一点，再点一次。" if a.pushTriangleTapCount == 1 else "三角形已经翘起，再点一次就能取下。")
		"c2_weather_drop":
			if not _movement(s) or not a.exerciseStarted: return _ok("目前没有能取下的天气水滴。")
			if not a.weatherWaterTaken:
				a.weatherWaterTaken = true
				items.weatherWater = true
			return _ok("获得天气水滴。")
		"c2_mentor":
			if not _movement(s) or str(value) != "weatherWater" or not items.weatherWater: return _ok("那条竖线粘住了。看来导师头像也有自己的排版要求。")
			items.weatherWater = false
			items.mentorLine = true
			a.mentorLineReleased = true
			return _ok("头像上的胶松开了，获得导师竖线。")
		"c2_balance":
			if not _movement(s) or str(value) != "rightArrow" or not items.rightArrow or not a.rightArrowAssembled: return _ok("小数点没有移动。")
			if a.balanceShifted: return _ok("小数点已经移动过了。")
			a.balanceShifted = true
			s.wallet.campusCardCents = 600
			return _ok("小数点向右移动了两位。六分钱暂时获得了六元钱的尊严。")
		"c2_login_hint":
			a.cc98Login.revealedHintCount = mini(3, int(a.cc98Login.revealedHintCount) + 1)
			return _ok("认证提示已展开。")
		"c2_login": return _login(s, value)
		"c2_purchase_gamepad":
			if not _movement(s) or s.networkMode != "campus_wifi" or not a.cc98Login.authenticated: return _ok("请先在校园网完成统一身份认证。")
			if a.gamepadPurchased: return _ok("手柄已经购买，不会重复扣款。")
			if not a.balanceShifted or int(s.wallet.campusCardCents) < 600: return _ok("你只有零点零六元。卖家拒绝了你分一百期付款的方案。")
			s.wallet.campusCardCents -= 600
			a.gamepadPurchased = true
			items.gamepad = true
			return _ok("手柄到货了。")
		"c2_use_gamepad":
			if a.controlsInstalled: return _ok("手柄已经连接。")
			if not _movement(s) or not items.gamepad or not a.characterNamed or not a.exerciseStarted or s.native.scene != "dorm_hub": return _ok("需要在寝室把手柄交给已有身份和锻炼记录的角色。")
			items.gamepad = false
			a.controlsInstalled = true
			a.movementEnabled = true
			return _ok("手柄已连接。现在用方向键或 WASD 移动。")
		"c2_manual_input":
			if not _movement(s) or not a.movementEnabled or not a.controlsInstalled or not value is Dictionary: return _ok("角色尚未获得手动控制。")
			if not value.get("moved", false) or float(value.get("distance", 0)) <= 0 or not ["keyboard", "touch"].has(str(value.get("input", ""))): return _ok("需要一次真实的手动移动。")
			if a.manualControlTested: return _ok("")
			a.manualControlTested = true
			a.canLeaveDorm = false
			a.phase = "reservation_briefing_required"
			return _ok("角色已经迈出你控制的第一步。系统发来了新消息。")
		"c2_reservation_briefing":
			if a.phase != "reservation_briefing_required" or not a.manualControlTested: return _ok("还没有新的预约说明。")
			a.phase = "reservation_required"
			return _ok("预约要求已记下。")
		"c2_reserve":
			if a.phase != "reservation_required" or not a.manualControlTested: return _ok("当前不能预约。")
			var parts = [str(value.get("library","")),str(value.get("room","")),str(value.get("seat",""))] if value is Dictionary else _split(value)
			if parts.size() != 3: return _ok("请填写馆舍、阅览室、座位号，以空格分隔。")
			if parts[0] != "基础馆": return _ok("馆舍不符。请核对系统的说明。")
			if parts[1] != "一层书库": return _ok("阅览室不符。请核对系统的说明。")
			if parts[2] != "022": return _ok("座位不符。请核对系统的说明。")
			a.phase = "movement_ready"
			a.canLeaveDorm = true
			s.ui.librarySelectedSeat = "022"
			s.ui.librarySeatReserved = true
			return _ok("预约成功。现在可以出门了。")
		"c2_dorm_exit":
			if a.phase != "movement_ready" or not a.canLeaveDorm or not a.manualControlTested: return _ok("寝室门还没有放行。")
			a.phase = "complete"
			s.ui.libraryFinalsPhase = "library_route_unlocked"
			s.rpgCheckpoint = "campus_spawn"
			return _scene(s, "campus_bootstrap", "寝室门打开了。")
		"c2_enter_campus":
			if a.phase != "complete": return _ok("先取得寝室出口的放行。")
			return _scene(s, "campus_bootstrap")
	return _ok("当前阶段没有这个操作。")

func _split(value: Variant) -> Array:
	if value is Array: return value
	return Array(str(value).strip_edges().replace("，", " ").replace(",", " ").replace("/", " ").split(" ", false))

func _login(s: Dictionary, value: Variant) -> Dictionary:
	var login: Dictionary = s.actOne.cc98Login
	if s.networkMode != "campus_wifi": return _ok("CC98 需要校园网。")
	if login.authenticated: return _ok("已经认证。")
	if not login.studentIdDiscovered: return _ok("请先从随身校园卡读取学号。")
	var now_ms = int(Time.get_unix_time_from_system() * 1000.0)
	if login.lockUntilMs != null and int(login.lockUntilMs) > now_ms: return _ok("认证暂时锁定，还需等待 %s 秒。" % int(ceil((int(login.lockUntilMs) - now_ms) / 1000.0)))
	var parts = [str(value.get("student_id","")),str(value.get("password",""))] if value is Dictionary else _split(value)
	if parts.size() == 2 and _student_id(str(parts[0])) == "3250100755" and _normal_text(str(parts[1])).strip_edges() == "ZJU1897!":
		login.authenticated = true
		login.lockUntilMs = null
		return _ok("统一身份认证成功。")
	login.failureCount += 1
	var duration = maxi(0, int(login.failureCount) - 2) * 30000
	login.lockUntilMs = now_ms + duration if duration > 0 else null
	return _ok("学号或密码不匹配。" + ("请稍后再试。" if duration > 0 else ""))

func objective(s: Dictionary) -> String:
	if int(s.native.get("chapter", 1)) > 2: return ""
	if _prologue(s):
		if s.flags.checkinDone: return "拦住旁白，与他交涉"
		if not s.flags.codeScattered: return "查看朋友的新消息"
		var digits: Array = []
		for key in ["d1", "d2", "d3", "d4"]: digits.append(str(s.digits[key]) if s.digits[key] != null else "□")
		return "找回签到码　" + " ".join(digits)
	var objectives = {"friend_message_required":"查看朋友的新消息", "system_required":"找到系统", "inventory_required":"在寝室找回校园卡与道具栏", "system_return_required":"带着道具栏回去找系统", "movement_required":"找到移动的办法", "reservation_briefing_required":"查看系统的新消息", "reservation_required":"按系统的说明预约图书馆座位", "movement_ready":"从寝室门出发"}
	return str(objectives.get(s.actOne.phase, library.objective(s)))

func targets(scene: String, s: Dictionary) -> Array:
	if scene != "dorm_hub": return library.targets(scene, s)
	var out: Array = []
	if not s.actOne.dormHubUnlocked: return out
	if s.actOne.phase == "inventory_required": out.append({"id":"desk_03", "label":"检查个人书桌", "position":[805,855], "bounds":[730,721,150,268], "radius":142.0, "action":"c2_recover_card", "mode":"light"})
	else:out.append({"id":"desk_03","label":"拨动个人书桌台灯","position":[805,855],"bounds":[730,721,150,268],"radius":142.0,"action":"c2_dorm_prop","value":"lamp_03_on","mode":"light"})
	var cabinet_open:bool=s.native.get("dorm_props",{}).get("cabinet_open",false)
	out.append({"id":"window_cabinet","label":"关上窗下柜" if cabinet_open else "打开窗下柜","position":[488,315],"bounds":[410,228,156,174],"radius":118.0,"action":"c2_dorm_prop","value":"cabinet_open","mode":"light"})
	out.append({"id":"desk_01","label":"拨动蓝色台灯","position":[805,316],"bounds":[730,182,150,268],"radius":142.0,"action":"c2_dorm_prop","value":"lamp_01_on","mode":"light"})
	if _movement(s):
		# Host interprets follow_player so the gamepad target remains on the actual actor.
		out.append({"id":"dorm_character", "label":"查看角色", "position":[470,1440], "radius":120.0, "action":"c2_inspect_character", "follow_player":true})
		if s.items.gamepad: out.append({"id":"dorm_gamepad", "label":"连接手柄", "position":[470,1440], "radius":120.0, "action":"c2_use_gamepad", "item":"gamepad", "mode":"light", "follow_player":true})
	out.append({"id":"exit_door", "label":"打开寝室门", "position":[470,1530], "bounds":[396,1471,148,118], "radius":116.0, "action":"c2_dorm_exit", "mode":"light"})
	return out

func _normal_text(value: String) -> String:
	var result = ""
	for i in range(value.length()):
		var code = value.unicode_at(i)
		if code == 0x3000: code = 32
		elif code >= 0xff01 and code <= 0xff5e: code -= 0xfee0
		result += String.chr(code)
	return result.replace("\t"," ").replace("\n"," ")

func _student_id(value: String) -> String:
	var result = ""
	for c in _normal_text(value):
		if c >= "0" and c <= "9": result += c
	return result
