extends "res://scripts/chapters/c3_base.gd"
const RainSession = preload("res://scripts/media/c3_rain_rescue_session.gd")
var rain_session: RefCounted
const Journal = preload("res://scripts/chapters/c3_journal.gd")
var journal: RefCounted=Journal.new()
const WorldSession = preload("res://scripts/chapters/c3_lake_world_session.gd")
var live_session: RefCounted
var pending_entry: Dictionary = {}
const Fishing = preload("res://scripts/games/rhythm_fishing_model.gd")
var fishing_session: Dictionary = {}
var session_counter: int = 0
const CLUES: Dictionary = {"bridge":"bridgeKeyword","reflection":"reflectionKeyword","lake":"lakeKeyword"}
const CATCH_ZONE: Dictionary = {"locker_key":"open_water","net_frame":"channel","fish":"open_water","paper":"swan_cove"}
const FINAL_PARTS: Array = ["nylonCord", "brokenNetFrame", "swanMagnet", "fishingRod"]
const CATCH_POINTS: Dictionary = {"locker_key":[1040,620],"net_frame":[640,575],"fish":[705,585],"paper":[760,450]}

func pages(s: Dictionary) -> Array:
	if not s.qizhenLake.active: return []
	var list: Array=[{"id":"c3_location","label":"浙大钉 · 地点核对"}]
	if s.qizhenLake.phase=="location_search":
		list.append_array([{"id":"c3_lake_cc98","label":"CC98 · 湿纸目击"},{"id":"c3_lake_catalog","label":"图书馆 · 夹页检索"},{"id":"c3_lake_wechat","label":"微信 · 地点消息"}])
	else: list.append({"id":"c3_lake","label":"启真湖"})
	if s.qizhenLake.phase=="rain_recovery": list.append({"id":"weather","label":"天气"})
	list.append_array(journal.pages(s))
	return list

func view(page: String, s: Dictionary) -> Dictionary:
	var journal_view: Dictionary=journal.view(page,s)
	if not journal_view.is_empty(): return journal_view
	var q: Dictionary=s.qizhenLake
	match page:
		"c3_location": return {"title":"地点核对","body":prose("chapter3-qizhen-lake.content","locationSearch.dialogue")+"\n已接入 %d / 3 条记录" % q.mapClueIds.size()}
		"c3_lake_cc98": return {"title":prose("chapter3-qizhen-lake.content","locationSearch.cc98.title"),"body":prose("chapter3-qizhen-lake.content","locationSearch.cc98.replies")}
		"c3_lake_catalog": return {"title":"馆藏检索","body":prose("chapter3-qizhen-lake.content","locationSearch.catalog.query")+"\n"+prose("chapter3-qizhen-lake.content","locationSearch.catalog.fields")}
		"c3_lake_wechat": return {"title":"朋友","body":prose("chapter3-qizhen-lake.content","locationSearch.wechat")}
		"c3_lake": return {"title":"启真湖 · "+{"dock":"小码头","open_water":"大湖","channel":"浮排河道","swan_cove":"黑天鹅围栏"}.get(q.zone,""),"body":prose("chapter3-qizhen-lake.content","dock.intro" if q.phase=="dock_outfitting" else "boarding.instruction")+"\n翻船次数：%d" % int(q.capsizeCount),"art":"res://assets/rpg/interiors/qizhen_lake_"+str(q.zone)+".png"}
		"c3_weather": return {"title":"天气 · 小雨","body":prose("chapter3-qizhen-lake.content","dock.afterRainProof")+"\n吹风机可以对三层云带施加方向控制。"}
	return {}

func actions(page: String, s: Dictionary) -> Array:
	if page in ["c3_journal","c3_journal_camera"]: return journal.actions(page,s)
	var q: Dictionary=s.qizhenLake
	match page:
		"c3_location":
			var list: Array=[]
			if q.phase=="location_search":
				for id: String in CLUES:
					if own(s,CLUES[id]): list.append(command("c3_map:"+id,"接入"+{"bridge":"桥边","reflection":"倒影","lake":"湖面"}[id]+"记录"))
				if q.mapClueIds.size()==3: list.append(command("c3_map_confirm",prose("chapter3-qizhen-lake.content","locationSearch.map.confirm")))
			elif q.phase!="complete": list.append(command("c3_lake_enter","前往湖区入口"))
			return list
		"c3_lake_cc98": return [command("c3_clue:bridge","用湿节目单核对目击记录")] if own(s,"wetProgram") else []
		"c3_lake_catalog": return [command("c3_clue:reflection","用湿节目单核对馆藏记录")] if own(s,"wetProgram") else []
		"c3_lake_wechat": return [command("c3_clue:lake","用湿节目单核对聊天记录")] if own(s,"wetProgram") else []
		"c3_weather": return [command("c3_weather_start","用吹风机调整云带")] if own(s,"hairDryer") else []
		"c3_lake":
			var list: Array=[]
			if own(s,"fishingRod") and own(s,"decoyPaper"): list.append(command("c3_bait","把假纸条固定到鱼钩上"))
			if own(s,"sealedFeedTin"): list.append(command("c3_tin_open","打开密封饲料罐"))
			if can_assemble(s): list.append(command("c3_lake_combine","组合四件材料 · 磁性钓鱼竿"))
			if q.phase=="swan_chase": list.append(command("c3_swan_chase","返回追逐中的河道"))
			return list
	return []

func dispatch(s: Dictionary, action: String, value: Variant = null) -> Dictionary:
	var journal_result: Dictionary=journal.dispatch(s,action,value)
	if not journal_result.is_empty(): return journal_result
	if not (action.begins_with("c3_lake") or action.begins_with("c3_clue:") or action.begins_with("c3_map") or action in ["c3_bait","c3_net_combine","c3_tin_open","c3_magnet_combine","c3_weather_inventory","c3_weather_start","c3_weather_result","c3_swan_chase","c3_kayak_result","c3_fishing_result","c3_rain_rescue_result"]): return {}
	var q: Dictionary=s.qizhenLake
	if not q.active: return locked()
	if action.begins_with("c3_lake_target:"): return physical(s,action.trim_prefix("c3_lake_target:"))
	if action.begins_with("c3_clue:"):
		var id: String=action.trim_prefix("c3_clue:")
		if q.phase!="location_search" or not own(s,"wetProgram") or not CLUES.has(id): return locked()
		if q[id+"ClueFound"]: return response()
		q[id+"ClueFound"]=true
		s.items[CLUES[id]]=true
		if q.bridgeClueFound and q.reflectionClueFound and q.lakeClueFound: consume(s,"wetProgram")
		return response("来源记录已保存。")
	if action.begins_with("c3_map:"):
		var id: String=action.trim_prefix("c3_map:")
		if q.phase!="location_search" or not CLUES.has(id) or not own(s,CLUES[id]): return locked()
		consume(s,CLUES[id])
		unique(q.mapClueIds,id)
		return response(prose("chapter3-qizhen-lake.content","locationSearch.map.ready" if q.mapClueIds.size()==3 else "locationSearch.map.one" if q.mapClueIds.size()==1 else "locationSearch.map.two"))
	match action:
		"c3_map_enter":
			if q.phase in ["inactive","location_search"]: return locked("启真湖入口还没有在大地图上开放。")
			s.ui.inventoryOpen=false; s.ui.selectedItem=null; s.ui.zjudingPage="hub"; s.native.selected_item=""
			var result: Dictionary=enter(s,"campus_qizhen_loop","zjuding","campus_qizhen_gate")
			result.open_world=true
			return result
		"c3_map_resume":
			var resolved: bool=q.phase not in ["inactive","location_search"]
			if not resolved or not ((s.rpgScene=="campus_qizhen_loop" and s.rpgCheckpoint=="campus_qizhen_gate") or (s.rpgScene=="qizhen_lake" and q.phase!="lake_unlocked")): return locked()
			s.runtimeMode="rpg"; s.native.scene=s.rpgScene; s.ui.inventoryOpen=false; s.ui.selectedItem=null; s.ui.zjudingPage="hub"; s.native.selected_item=""
			return {"handled":true,"scene":s.rpgScene,"open_world":true}
		"c3_map_confirm":
			if q.phase!="location_search" or not CLUES.keys().all(func(id: Variant) -> bool: return q.mapClueIds.has(id)): return locked()
			q.phase="lake_unlocked"
			return response(prose("chapter3-qizhen-lake.content","locationSearch.map.three"))
		"c3_lake_enter":
			if q.phase in ["inactive","location_search","complete"]: return locked()
			if q.phase=="rain_recovery" and not q.rainSafetyCleared: return locked(prose("chapter3-qizhen-lake.content","dock.rainReturnBlocked"))
			if q.phase=="lake_unlocked":
				q.phase="dock_outfitting"
				q.zone="dock"
				q.vehicle="on_foot"
				q.safeSpawnId="dock_entry"
			return enter(s,"qizhen_lake","c3_lake","qizhen_"+str(q.zone))
		"c3_bait":
			if q.phase not in ["lake_exploration","tool_chain"] or not light(s) or not own(s,"fishingRod") or not own(s,"decoyPaper") or q.decoyBaitAttached: return locked()
			consume(s,"decoyPaper")
			q.decoyBaitAttached=true
			q.phase="tool_chain"
			return response(prose("chapter3-qizhen-lake.content","lake.baitAttached"))
		"c3_net_combine":
			# Pairwise crafting was replaced in the active source by final four-part assembly.
			# Imported legacy nets/tins still work, but fresh materials stay independent.
			return combine_items(s,["nylonCord","brokenNetFrame"])
		"c3_tin_open":
			if not light(s) or not own(s,"sealedFeedTin") or not q.feedTinRetrieved or q.feedTinOpened: return locked()
			consume(s,"sealedFeedTin")
			s.items.fishFeedPellets=true
			q.feedTinOpened=true
			q.phase="tool_chain"
			return response("密封饲料罐已打开，获得鱼食颗粒。")
		"c3_lake_combine", "c3_magnet_combine":
			return combine_items(s,FINAL_PARTS if value==null else value)
		"c3_weather_inventory":
			if not weather_ready(s): return locked()
			return {"handled":true,"open_inventory":true}
		"c3_weather_start":
			if not weather_ready(s): return locked()
			q.weatherControlAttempts+=1
			s.ui.inventoryOpen=false; s.ui.selectedItem=null; s.native.selected_item=""
			return {"handled":true,"game":{"script":"res://scripts/games/c3_weather.gd","on_success":"c3_weather_result","title":"天气 · 三层云带"}}
		"c3_weather_result":
			if not weather_ready(s) or q.weatherControlAttempts<1 or not valid_weather(value): return locked("云带调整记录尚未稳定。")
			consume(s,"hairDryer")
			q.rainSafetyCleared=true
			q.phase="boarding_tutorial"
			q.weatherControlBestMoves=int(value.moves) if q.weatherControlBestMoves==0 else mini(int(q.weatherControlBestMoves),int(value.moves))
			return response(prose("chapter3-qizhen-lake.content","dock.safetyCleared"))
		"c3_rain_rescue_result": return rain_rescue_result(s,value)
		"c3_kayak_result": return kayak_result(s,value)
		"c3_fishing_result": return fishing_result(s,value)
		"c3_swan_chase":
			if q.phase!="swan_chase": return locked()
			return enter(s,"qizhen_lake","c3_lake","qizhen_chase")
	return locked()

# The source ChapterThreeQizhenLakeController.combineItems is authoritative.
# Validate the complete set before touching any item or selection; order is irrelevant.
func can_assemble(s: Dictionary) -> bool:
	return s.qizhenLake.active and s.qizhenLake.phase in ["tool_chain","swan_exchange","paper_capture"] and light(s) and not s.qizhenLake.magneticRodCombined and FINAL_PARTS.all(func(id: Variant) -> bool: return own(s,id))

func combine_items(s: Dictionary, item_ids: Variant) -> Dictionary:
	var q: Dictionary=s.qizhenLake
	if not q.active or q.phase not in ["tool_chain","swan_exchange","paper_capture"]: return branch_result("inactive")
	if not light(s): return branch_result("wrong_mode")
	if q.magneticRodCombined: return branch_result("already_complete")
	if not item_ids is Array or not FINAL_PARTS.all(func(id: Variant) -> bool: return item_ids.has(id) and own(s,id)): return branch_result("wrong_item","四件材料尚未集齐。")
	for id: String in FINAL_PARTS: consume(s,id)
	s.items.magneticFishingRod=true
	q.netCombined=true
	q.magneticRodCombined=true
	q.phase="paper_capture"
	return branch_result("accepted","尼龙绳、破损网框和磁性扣已装到钓鱼竿上，可以捕纸了。")

func complete_swan_branch(s: Dictionary) -> Dictionary:
	var q: Dictionary=s.qizhenLake
	if not q.active or q.phase!="tool_chain" or q.zone!="swan_cove": return branch_result("inactive")
	if not light(s): return branch_result("wrong_mode")
	if q.swanFed or own(s,"swanMagnet"): return branch_result("already_complete")
	s.items.swanMagnet=true
	q.feedTinRetrieved=true
	q.feedTinOpened=true
	q.fishCaught=true
	q.swanFed=true
	q.phase="tool_chain"
	return branch_result("accepted","浮排边的旧饲料盒被捞起并撬开。\n饲料撒入围栏，黑天鹅把一枚磁性扣推到船边。")

func branch_result(status: String, message: String="这里暂时没有要处理的事。") -> Dictionary:
	var result: Dictionary=response(message)
	result.status=status
	return result

func light(s: Dictionary) -> bool:
	return mode(s,"qizhenLake")=="light"

func weather_ready(s: Dictionary) -> bool:
	var q: Dictionary=s.qizhenLake
	return q.active and q.phase=="rain_recovery" and q.zone=="dock" and q.vehicle=="on_foot" and q.rainRescueCompleted and q.weatherAdjustmentRequested and not q.rainSafetyCleared and own(s,"hairDryer") and s.currentScene=="weather"

func valid_weather(v: Variant) -> bool:
	if not v is Dictionary: return false
	for key in ["moves","stableMs","elapsedMs"]:
		if typeof(v.get(key)) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(v[key])): return false
	if float(v.moves)!=floor(float(v.moves)): return false
	if not v is Dictionary or int(v.get("moves",0))<3 or float(v.get("stableMs",0))<1000 or float(v.get("elapsedMs",0))<float(v.get("stableMs",0)): return false
	var positions: Variant=v.get("cloudOffsets")
	var controlled: Variant=v.get("controlledBands")
	if not positions is Array or positions.size()!=3 or not controlled is Array or controlled.size()!=3: return false
	for i: int in range(3):
		if typeof(controlled[i])!=TYPE_BOOL or controlled[i]!=true or typeof(positions[i]) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(positions[i])) or absf(float(positions[i])-[34.0,52.0,70.0][i])>8: return false
	return true

func definitions() -> Array:
	var list: Array=source_targets("qizhen_lake").duplicate(true)
	# The source still accepts previously assembled nets from older saves.
	# Keep that compatibility interaction separate from the independent primary branches.
	list.append({"id":"qizhen_feed_tin","label":"围栏边的旧饲料盒","x":1165,"y":470,"width":200,"height":120,"proximity":180,"kind":"feed_tin","zone":"swan_cove","vehicle":"kayak"})
	return list

func physical(s: Dictionary, id: String) -> Dictionary:
	var q: Dictionary=s.qizhenLake
	if id=="hair_dryer":
		if q.phase!="rain_recovery" or not q.rainRescueCompleted or not near(s,"dorm_hub",[700,430],180): return locked()
		s.items.hairDryer=true
		return response("获得吹风机。")
	var selected: Dictionary={}
	for entry: Dictionary in definitions():
		if entry.id==id: selected=entry; break
	if selected.is_empty() or selected.zone!=q.zone or selected.get("vehicle",q.vehicle)!=q.vehicle or not near_source(s,"qizhen_lake",selected): return locked("先走近一点再操作。")
	var kind: String=selected.kind
	if kind=="reflection":
		if light(s): return response(prose("chapter3-qizhen-lake.content","reflection.lightWater"))
		unique(q.observedFishingSpotIds,selected.value)
		if selected.value=="paper": q.reflectionLocationObserved=true
		return response(prose("chapter3-qizhen-lake.content","reflection.correct"))
	if not light(s): return locked(prose("chapter3-qizhen-lake.content","lake.darkPrompt"))
	match kind:
		"outfit":
			if q.phase!="dock_outfitting": return locked()
			var key: String={"kayak":"kayakEquipped","left_paddle":"leftPaddleEquipped","right_paddle":"rightPaddleEquipped"}[selected.value]
			q[key]=true
			if q.kayakEquipped and q.leftPaddleEquipped and q.rightPaddleEquipped:
				q.phase="boarding_tutorial"
				q.safeSpawnId="dock_kayak"
				return response(prose("chapter3-qizhen-lake.content","dock.outfitComplete"))
			return response(prose("chapter3-qizhen-lake.content","dock."+{"kayak":"kayakCollected","left_paddle":"leftPaddleCollected","right_paddle":"rightPaddleCollected"}[selected.value]))
		"safety_officer":
			if not (q.kayakEquipped and q.leftPaddleEquipped and q.rightPaddleEquipped): return locked(prose("chapter3-qizhen-lake.content","dock.outfitPrompt"))
			if q.rainSafetyCleared: return response(prose("chapter3-qizhen-lake.content","dock.safetyCleared"))
			q.rainWarningSeen=true
			return response(prose("chapter3-qizhen-lake.content","dock.safetyRainBlock"))
		"board":
			if not (q.kayakEquipped and q.leftPaddleEquipped and q.rightPaddleEquipped): return locked()
			if not q.rainSafetyCleared:
				if not q.rainWarningSeen: return locked(prose("chapter3-qizhen-lake.content","dock.boardRainRejected"))
				return rain_rescue_request(s)
			if q.phase not in ["boarding_tutorial","lake_exploration","tool_chain","swan_exchange","paper_capture"]: return locked()
			q.vehicle="kayak"
			q.safeSpawnId="dock_kayak"
			if not q.boardingTutorialCompleted: q.boardingStrokeCount=0; q.boardingLastSide=null
			return _fishing_audio(response(prose("chapter3-qizhen-lake.content","boarding.instruction")),[{"cueId":"qizhen_kayak_boarded"}])
		"zone_portal":
			if not portal_visible(q,selected) or not q.boardingTutorialCompleted: return locked()
			return enter_zone(s,str(selected.targetZone))
		"fishing_spot":
			match str(selected.value):
				"fishing_rod":
					if q.phase not in ["lake_exploration","tool_chain"] or q.rodFound or own(s,"fishingRod") or own(s,"magneticFishingRod"): return locked()
					q.rodFound=true
					q.phase="tool_chain"
					s.items.fishingRod=true
					return response(prose("chapter3-qizhen-lake.content","lake.rodFound"))
				"item_1": return request_cast(s,"locker_key")
				"item_3": return request_cast(s,"net_frame")
				"fish": return request_cast(s,"fish")
		"paper":
			if not own(s,"magneticFishingRod") or selected.zone!="swan_cove":
				q.directPaperCastFailures+=1
				return response(prose("chapter3-qizhen-lake.content","lake.directPaperFailure"))
			return request_cast(s,"paper")
		"item_use":
			if id=="qizhen_use_item_1":
				if not own(s,"rustedLockerKey") or q.lockerOpened: return locked()
				consume(s,"rustedLockerKey")
				s.items.nylonCord=true
				q.lockerOpened=true
				q.phase="tool_chain"
				return response("储物柜打开，获得尼龙绳。")
			if id=="qizhen_open_workbench": return combine_items(s,FINAL_PARTS)
		"feed_tin":
			if not own(s,"improvisedDipNet") or not q.netCombined or q.feedTinRetrieved: return locked("需要能捞取饲料罐的工具。")
			consume(s,"improvisedDipNet")
			s.items.sealedFeedTin=true
			q.feedTinRetrieved=true
			q.phase="tool_chain"
			return response("临时抄网捞起密封饲料罐。")
		"swan":
			if q.phase=="tool_chain": return complete_swan_branch(s)
			if q.phase!="swan_exchange" or not own(s,"smallCarp"): return locked(prose("chapter3-qizhen-lake.content","swan.wrongItem"))
			consume(s,"smallCarp")
			s.items.swanMagnet=true
			q.swanFed=true
			q.phase="tool_chain"
			return response(prose("chapter3-qizhen-lake.content","swan.reward"))
		"escape":
			# Escape is completed only by the controller-issued live session at x <= 190.
			return locked(prose("chapter3-qizhen-lake.content","chase.instruction"))
		"exit":
			if q.vehicle!="on_foot" or q.zone!="dock": return locked(prose("chapter3-qizhen-lake.content","dock.leaveLocked"))
			return enter(s,"campus_qizhen_loop","c3_location","campus_qizhen_gate")
	return locked()

func precheck_cast(s: Dictionary, spot: String) -> bool:
	var q: Dictionary=s.qizhenLake
	if q.vehicle!="kayak" or not light(s) or not CATCH_ZONE.has(spot) or q.zone!=CATCH_ZONE[spot] or q.phase not in ["tool_chain","swan_exchange","paper_capture"]: return false
	match spot:
		"locker_key": return own(s,"fishingRod") and q.decoyBaitAttached and not own(s,"rustedLockerKey") and not q.lockerOpened
		"net_frame": return own(s,"fishingRod") and q.decoyBaitAttached and not own(s,"brokenNetFrame") and not q.netCombined
		"fish": return own(s,"fishingRod") and own(s,"fishFeedPellets") and not q.fishCaught and not own(s,"smallCarp")
		"paper": return own(s,"magneticFishingRod") and q.swanFed and q.magneticRodCombined and q.phase=="paper_capture"
	return false

func request_cast(s: Dictionary, spot: String) -> Dictionary:
	if not precheck_cast(s,spot): return locked("当前钓具或目标条件不匹配。")
	session_counter+=1
	fishing_session={"id":session_counter,"spotId":spot,"zone":s.qizhenLake.zone}
	return {"handled":true,"game":{"type":"rhythm","on_success":"c3_fishing_result","title":prose("chapter3-qizhen-lake.content","items."+{"locker_key":"rustedLockerKey","net_frame":"brokenNetFrame","fish":"smallCarp","paper":"magneticFishingRod"}[spot]),"spotId":spot,"chartId":spot,"session_id":session_counter,"chart":content("chapter3-qizhen-fishing.charts").charts[spot],"instructions":"按住并在节拍处松开；保持四拍收放。失败不会消耗道具。"}}

func fishing_result(s: Dictionary, value: Variant) -> Dictionary:
	if not value is Dictionary or fishing_session.is_empty(): return locked("没有进行中的抛竿记录。")
	var spot: String=fishing_session.spotId
	var audio_session_id: String=str(fishing_session.id)
	var valid: bool=value.get("session_id")==fishing_session.id and value.get("spotId")==spot and value.get("success")==true and Fishing.validate_result(value,spot)
	# Result is single-use even on cancellation or failure; story items remain intact.
	fishing_session={}
	if not valid: return _fishing_audio(locked("本次节奏记录未通过，道具保持原状。"), [{"cueId":"qizhen_fishing_failed","payload":{"sessionId":audio_session_id,"spotId":spot,"reason":"invalid_result"}}])
	if not precheck_cast(s,spot): return locked("本次节奏记录未通过，道具保持原状。")
	var audio_payload: Dictionary={"sessionId":audio_session_id,"spotId":spot,"grade":value.get("grade","C"),"accuracy":value.get("accuracy",0)}
	var audio_cues: Array=[{"cueId":"qizhen_fishing_completed","payload":audio_payload},{"cueId":"qizhen_fishing_paper_completed" if spot=="paper" else "qizhen_fishing_catch_completed","payload":audio_payload}]
	var q: Dictionary=s.qizhenLake
	match spot:
		"locker_key":
			s.items.rustedLockerKey=true
			q.phase="tool_chain"
		"net_frame":
			s.items.brokenNetFrame=true
			q.phase="tool_chain"
		"fish":
			consume(s,"fishFeedPellets")
			s.items.smallCarp=true
			q.fishCaught=true
			q.phase="swan_exchange"
		"paper":
			q.paperCaptured=true
			q.swanReleased=true
			pending_entry={"from":"swan_cove","to":"channel"}
			q.phase="swan_chase"
			q.zone="channel"
			q.vehicle="kayak"
			q.safeSpawnId="channel_chase"
			q.chaseDistance=0
			q.chaseAttempts+=1
			s.rpgCheckpoint="qizhen_chase"
			return _fishing_audio(response(prose("chapter3-qizhen-lake.content","swan.paperCapture")+"\n"+prose("chapter3-qizhen-lake.content","swan.gateRelease")), audio_cues)
	return _fishing_audio(response("钓获成功。"), audio_cues)

func rain_rescue_request(s: Dictionary) -> Dictionary:
	if not RainSession.eligible(s): return locked()
	if rain_session!=null and rain_session.phase() not in ["cancelled","consumed"]: return locked("救援演出正在进行。")
	rain_session=RainSession.new()
	var p: Dictionary=s.native.get("player",{})
	rain_session.configure(bool(s.native.get("settings",{}).get("reduced_motion",false)),Vector2(float(p.get("x",690)),float(p.get("y",620))),s)
	return {"handled":true,"world_effect":{"script":"res://scripts/media/c3_rain_rescue.gd","session":rain_session,"on_event":"c3_rain_rescue_result","blocks_input":true}}

func rain_rescue_result(s: Dictionary,value: Variant) -> Dictionary:
	if not value is RainSession or value!=rain_session: return locked("救援记录不匹配。")
	if value.phase()=="cancelled":
		rain_session=null
		return response("救援演出已中断。回到码头可以重新尝试。")
	if not value.consume(s): return locked("救援仍未完成。")
	var q: Dictionary=s.qizhenLake
	q.rainRescueCompleted=true; q.weatherAdjustmentRequested=true; q.capsizeCount+=1
	q.phase="rain_recovery"; q.vehicle="on_foot"; q.zone="dock"; q.safeSpawnId="dock_entry"
	q.boardingStrokeCount=0; q.boardingLastSide=null
	s.currentScene="phone_home"; s.ui.controlCenterOpen=false; s.ui.inventoryOpen=false; s.ui.selectedItem=null
	rain_session=null
	var result: Dictionary=enter(s,"dorm_hub","phone_home","dorm_spawn")
	result.message=prose("chapter3-qizhen-lake.content","dock.forcedRescue")
	return result

func kayak_result(_s: Dictionary, _value: Variant) -> Dictionary:
	return locked("划桨与返航需要在当前湖区完成。")

func portal_visible(q: Dictionary,entry: Dictionary) -> bool:
	match str(entry.id):
		"qizhen_dock_to_open": return bool(q.boardingTutorialCompleted)
		"qizhen_open_to_dock", "qizhen_open_to_swan", "qizhen_open_to_channel", "qizhen_channel_to_open": return q.phase!="swan_chase"
		"qizhen_swan_to_open": return q.phase!="swan_chase" and not q.paperCaptured
		"qizhen_swan_to_channel": return q.phase=="swan_chase" or q.swanReleased
		"qizhen_channel_from_swan": return false
	return true

func enter_zone(s: Dictionary,zone: String) -> Dictionary:
	var q: Dictionary=s.qizhenLake
	if q.vehicle!="kayak" or not q.boardingTutorialCompleted or zone not in ["dock","open_water","channel","swan_cove"]: return locked()
	if q.phase=="swan_chase" and zone not in ["channel","dock"]: return locked()
	pending_entry={"from":str(q.zone),"to":zone}
	q.zone=zone
	if zone=="dock": q.vehicle="on_foot"
	q.safeSpawnId="channel_chase" if q.phase=="swan_chase" and zone=="channel" else ("dock_entry" if zone=="dock" else zone+"_entry")
	var checkpoint: String="qizhen_chase" if q.phase=="swan_chase" and zone=="channel" else "qizhen_"+zone
	return _fishing_audio(enter(s,"qizhen_lake","c3_lake",checkpoint),[{"cueId":"qizhen_zone_entered","payload":{"zone":zone,"vehicle":q.vehicle}}])

func take_entry_spawn(s: Dictionary) -> Dictionary:
	# Consumed by world refresh only on an actual source-zone transition.
	if pending_entry.is_empty() or pending_entry.to!=s.qizhenLake.zone: return {}
	var spec: Dictionary=world("qizhen_lake").zones[str(pending_entry.to)]
	var spawn: Dictionary=spec.onFootSpawn if s.qizhenLake.vehicle=="on_foot" else spec.get("kayakEntrySpawns",{}).get(str(pending_entry.from),spec.kayakSpawn)
	pending_entry={}
	return spawn.duplicate()

func bind_world(s: Dictionary,host: Node) -> RefCounted:
	if not WorldSession.eligible_host(s,host):
		if live_session!=null: live_session.cancel()
		live_session=null
		return null
	if live_session!=null and live_session.same_binding(s,host): return live_session
	if live_session!=null: live_session.cancel()
	live_session=WorldSession.new(s,host)
	return live_session

func world_stroke(s: Dictionary,host: Node,side: String,reverse: bool=false) -> Dictionary:
	var session: RefCounted=bind_world(s,host)
	if session==null or not session.stroke(s,host,side,reverse): return {}
	var q: Dictionary=s.qizhenLake
	var cues: Array=[]
	for stroke: Dictionary in session.take_strokes():
		var direction: String=str(stroke.direction)
		var payload: Dictionary={"side":side,"direction":direction,"tutorial":false}
		if q.phase!="boarding_tutorial": cues.append({"cueId":"qizhen_paddle_stroke_recorded","payload":payload}); continue
		var alternating: bool=false
		if direction!="reverse":
			alternating=q.boardingLastSide!=side
			q.boardingStrokeCount=int(q.boardingStrokeCount)+1 if alternating else 0
			q.boardingLastSide=side
		payload={"side":side,"direction":direction,"alternating":alternating,"count":q.boardingStrokeCount}
		if q.boardingStrokeCount>=4:
			q.boardingTutorialCompleted=true; q.phase="lake_exploration"; q.zone="open_water"; q.safeSpawnId="open_water_entry"
			pending_entry={"from":"dock","to":"open_water"}; s.rpgCheckpoint="qizhen_open_water"
			cues.append({"cueId":"qizhen_boarding_completed","payload":payload})
			return _fishing_audio(enter(s,"qizhen_lake","c3_lake","qizhen_open_water"),cues)
		cues.append({"cueId":"qizhen_boarding_stroke_recorded","payload":payload})
	return _fishing_audio(response(),cues)

func world_tick(s: Dictionary,host: Node,delta: float) -> Dictionary:
	var session: RefCounted=bind_world(s,host)
	if session==null: return {}
	var event: Dictionary=session.tick(s,host,delta)
	if event.is_empty(): return {}
	if event.get("invalid",false): return locked("船的位置已失效，请回到安全检查点。")
	var q: Dictionary=s.qizhenLake
	var result: Dictionary=response()
	var cues: Array=[]
	if event.get("started",false):
		cues.append({"cueId":"rpg_qizhen_chase_started","payload":{"zone":"channel"}})
		result.message=prose("chapter3-qizhen-lake.content","chase.voiceSubtitles.start")
	if event.has("progress"):
		q.chaseDistance=clampi(int(event.progress),0,1000)
		q.chaseBestDistance=maxi(int(q.chaseBestDistance),int(q.chaseDistance))
	if event.has("cue"):
		var cue: String=str(event.cue)
		cues.append({"cueId":"qizhen_swan_chase_"+cue,"payload":{"cycle":session.pressure_state.cycleIndex,"segment":session.pressure_state.segment,"gap":roundi(session.actual_gap)}})
		if cue=="telegraph" and not session.telegraph_voice:
			session.telegraph_voice=true
			cues.append({"cueId":"qizhen_swan_chase_telegraph_voice","payload":{"cycle":session.pressure_state.cycleIndex}})
			result.message=prose("chapter3-qizhen-lake.content","chase.voiceSubtitles.telegraph")
		if cue=="final_bank" and not session.final_voice:
			session.final_voice=true; result.message=prose("chapter3-qizhen-lake.content","chase.voiceSubtitles.finalBank")
	if event.get("restarted",false): cues.append({"cueId":"rpg_qizhen_chase_restarted","payload":{"zone":"channel"}})
	if event.has("failure"):
		var reason: String=str(event.failure)
		if reason=="swan_caught":
			q.chaseAttempts+=1; q.chaseDistance=0; q.safeSpawnId="channel_chase"; s.rpgCheckpoint="qizhen_chase"
			result.message=prose("chapter3-qizhen-lake.content","chase.caught")+prose("chapter3-qizhen-lake.content","chase.failed")
			cues.append({"cueId":"qizhen_chase_failed","payload":{"reason":reason,"attempt":q.chaseAttempts,"checkpoint":"qizhen_chase"}})
		else:
			q.capsizeCount+=1
			if q.phase=="swan_chase": q.chaseAttempts+=1; q.chaseDistance=0
			if q.phase=="boarding_tutorial": q.boardingStrokeCount=0; q.boardingLastSide=null; q.safeSpawnId="dock_kayak"; s.rpgCheckpoint="qizhen_dock"
			result.message=prose("chapter3-qizhen-lake.content","boarding.capsizeSameSide")+(prose("chapter3-qizhen-lake.content","chase.failed") if q.phase=="swan_chase" else "")
			cues.append({"cueId":"qizhen_capsize_recovered","payload":{"reason":reason,"zone":q.zone,"count":q.capsizeCount}})
			if q.capsizeCount==6: cues.append({"cueId":"qizhen_capsize_loss_subtitle_unlocked","payload":{"count":6}})
		session.acknowledge_attempt(s)
	if event.get("finished",false): return complete_live_escape(s,host,session,cues)
	return _fishing_audio(result,cues)

func complete_live_escape(s: Dictionary,host: Node,proof: Variant,cues: Array=[]) -> Dictionary:
	if not proof is WorldSession or proof!=live_session or not proof.consume_finish(s,host): return locked("返航记录尚未完成。")
	var q: Dictionary=s.qizhenLake
	consume(s,"magneticFishingRod")
	q.phase="complete"; q.zone="dock"; q.vehicle="on_foot"; q.safeSpawnId="dock_entry"
	q.chaseDistance=1000; q.chaseBestDistance=maxi(int(q.chaseBestDistance),1000)
	q.magneticAttachmentBroken=true; q.transitionReady=true
	s.chapterThreeInterlude.merge({"phase":"reboot","rebootSeen":false,"recoveryOpened":false,"photoFrameIds":[],"photoSequenceSolved":false,"voiceClipOrder":[],"voiceSequenceSolved":false,"officialNoticeSaved":false,"routeScreenshotSaved":false,"networkRecordRead":false,"evidenceIds":[],"timelineOrder":[],"rejectedDecoyIds":[],"statusClockMarkedUntrusted":false,"destinationId":null,"replayUnlocked":false,"completed":false},true)
	s.native.chapter=3; s.native.scene=""; s.native.page="c35_recovery"
	s.runtimeMode="phone"; s.currentScene="phone_home"; s.rpgCheckpoint="qizhen_complete"
	s.ui.controlCenterOpen=false; s.ui.inventoryOpen=false; s.ui.selectedItem=null; s.native.selected_item=""
	cues.append({"cueId":"qizhen_escape_completed"})
	cues.append({"cueId":"chapter35_recovery_requested","payload":{"reason":"qizhen_escape_completed","scene":"phone_home"}})
	return _fishing_audio({"handled":true,"message":prose("chapter3-qizhen-lake.content","chase.complete"),"page":"c35_recovery"},cues)

func targets(scene: String, s: Dictionary) -> Array:
	var q: Dictionary=s.qizhenLake
	if scene=="dorm_hub" and q.phase=="rain_recovery" and not own(s,"hairDryer"):
		return [target("c3_hair_dryer","吹风机",[700,430],"c3_lake_target:hair_dryer",180)]
	if scene=="campus_qizhen_loop" and q.active:
		var gate: Dictionary=world(scene).manifest.qizhen.gate
		if q.phase not in ["inactive","location_search","complete"]: return [target("c3_qizhen_gate","启真湖入口",[gate.x,gate.y],"c3_lake_enter",gate.radius)]
		return []
	if scene!="qizhen_lake" or not q.active: return []
	var list: Array=[]
	for entry: Dictionary in definitions():
		if entry.zone!=q.zone or entry.get("vehicle",q.vehicle)!=q.vehicle: continue
		if entry.kind=="zone_portal" and not portal_visible(q,entry): continue
		if entry.kind=="escape" and q.phase!="swan_chase": continue
		if entry.kind=="outfit" and q.phase!="dock_outfitting": continue
		if entry.kind=="feed_tin" and (not own(s,"improvisedDipNet") or not q.netCombined or q.feedTinRetrieved): continue
		if entry.kind=="swan" and (not light(s) or q.phase not in ["tool_chain","swan_exchange"] or q.swanFed): continue
		# Source retires this physical action after its key-to-cord transaction.
		if entry.id=="qizhen_use_item_1" and q.lockerOpened: continue
		if entry.id=="qizhen_open_workbench" and not can_assemble(s): continue
		var result: Dictionary=from_source(entry,"c3_lake_target:"+str(entry.id))
		var item: String=str(entry.get("acceptedItem",""))
		if entry.kind=="swan" and q.phase=="swan_exchange": item="smallCarp"
		if entry.kind=="feed_tin": item="improvisedDipNet"
		if light(s) and not item.is_empty(): result.item=item
		if entry.kind in ["fishing_spot","reflection"]:
			result.art="res://assets/native/chapter3/water_ripple_light.svg" if light(s) else "res://assets/native/chapter3/water_ripple_dark.svg"
			result.art_size=([240,128] if light(s) else [210,104]) if entry.has("width") else [104,56]
		result.interaction_priority=1 if (entry.kind=="reflection")!=light(s) else 0
		if entry.kind=="swan":
			result.art="res://assets/native/chapter3/black_swan.svg"
			result.art_size=[180,82]
			result.art_offset=[-5,-70]
		if entry.kind=="outfit" and entry.value=="left_paddle":
			result.art="res://assets/native/chapter3/willow_branch.svg"
			result.art_size=[80,44]
		if entry.kind=="paper":
			result.art="res://assets/rpg/theater/generated/paper/paper_residual.png" if not light(s) else "res://assets/rpg/theater/generated/paper/paper_flight_0.png"
			result.art_size=[45,45]
		list.append(result)
	list.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return int(a.get("interaction_priority",0))>int(b.get("interaction_priority",0)))
	return list

func objective(s: Dictionary) -> String:
	var q: Dictionary=s.qizhenLake
	if not q.active or q.phase in ["inactive","complete"]: return ""
	return {"location_search":"用三个独立来源确认纸条下一站","lake_unlocked":"前往启真湖入口","dock_outfitting":"收齐皮划艇和两支临时桨","rain_recovery":"在宿舍找吹风机，调整天气云带","boarding_tutorial":"检查下水条件，交替划桨稳定船身","lake_exploration":"寻找纸条和可用的钓具","tool_chain":"沿湖区线索制作能固定纸条的钓具","swan_exchange":"把小鲤鱼交给围栏边的黑天鹅","paper_capture":"用磁性钓鱼竿固定纸条","swan_chase":"交替划桨返回小码头"}.get(q.phase,"")

func _fishing_audio(result: Dictionary, cues: Array) -> Dictionary:
	result["presentation"] = cues
	return result
