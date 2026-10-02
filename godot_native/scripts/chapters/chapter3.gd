extends "res://scripts/chapters/c3_base.gd"
const ChargeSession = preload("res://scripts/media/c3_charging_session.gd")
var charge_session: RefCounted
const SceneSession = preload("res://scripts/presentation/c3_scene_session.gd")
var entry_session: RefCounted
const PromoTimeline=preload("res://scripts/presentation/c3_promo_timeline.gd")
const NarrativeSession=preload("res://scripts/presentation/c3_narrative_session.gd")
var story: RefCounted
var story_request: Dictionary={}
var story_state: Dictionary={}
var story_scene: String=""
var theater_entry_played: bool=false
var npc_state: Dictionary={}
var npc_targets: Array=[]
var npc_scene: String=""
var world_source: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/native/chapter3-world-source.json"))

func narrative_session(s: Dictionary,_delta_ms: float=0) -> RefCounted:
	var scene: String=str(s.native.get("scene",""))
	if not is_same(story_state,s) or scene!=story_scene:
		if story!=null: story.cancel()
		story=null; story_request={}; story_state=s; story_scene=scene; theater_entry_played=false
	if story!=null and not story.valid(s):
		story.cancel(); story=null; story_request={}
	if story==null and story_request.is_empty():
		if scene=="canteen_interior" and side_active(s.canteenHunt) and s.canteenHunt.promoDrinkPlaced and not s.canteenHunt.queueGapOpened:
			story_request={"id":"canteen_promo","scene":scene,"lines":source_lines("chapter3-canteen.content","drinks.queueShiftDialogue"),"timelineStartMs":220,"delayMs":220+PromoTimeline.timing(bool(s.native.get("settings",{}).get("reduced_motion",false))).completeAt}
		elif scene=="campus_qizhen_loop" and s.qizhenLake.active and s.qizhenLake.phase=="location_search" and not s.qizhenLake.locationBriefingSeen:
			var source: Dictionary=content("chapter3-qizhen-lake.content").locationSearch
			var authored: Array=[]; var durations: Array=[]
			for i in range(source.approachTransition.visualBeats.size()):
				authored.append(source.approachTransition.visualBeats[i]); durations.append(2400)
				if i<source.dialogue.size(): authored.append(source.dialogue[i]); durations.append(2800)
			for line: String in source.dialogue.slice(source.approachTransition.visualBeats.size()): authored.append(line); durations.append(4200)
			story_request=source.approachTransition.duplicate(true)
			story_request.merge({"id":"qizhen_approach","scene":scene,"lines":authored,"durations":durations,"delayMs":160,"onComplete":"approach"})
		elif scene=="theater_interior" and s.native.get("c3_reversal_pending",false)==true and s.theaterHunt.phase in ["reversal","complete"]:
			var done: bool=s.theaterHunt.phase=="complete"
			story_request={"id":"theater_reversal","scene":scene,"lines":source_lines("chapter3-theater.content","spotlight.endingDialogue"),"delayMs":0 if done else 1320,"visualCompleted":done}
		elif scene=="theater_interior" and s.theaterHunt.phase=="entry_ticket" and not s.theaterHunt.posterCleaned and not s.theaterHunt.ticketCodeRead and not theater_entry_played:
			story_request={"id":"theater_entry","scene":scene,"lines":source_lines("chapter3-theater.content","entryDialogue"),"delayMs":160 if s.native.get("settings",{}).get("reduced_motion",false) else 1100}
	if not story_request.is_empty() and (story==null or story.status=="cancelled"):
		if str(story_request.id)=="theater_reversal" and s.theaterHunt.phase=="complete": story_request.delayMs=0; story_request.visualCompleted=true
		story=NarrativeSession.new(s,story_request)
	return story

func tell(s: Dictionary,id: String,file: String,path: String,extra: Dictionary={}) -> Dictionary:
	return tell_lines(s,id,source_lines(file,path),extra)

func tell_lines(s: Dictionary,id: String,lines: Array,extra: Dictionary={}) -> Dictionary:
	story_state=s; story_scene=str(s.native.scene)
	story_request={"id":id,"scene":story_scene,"lines":lines.duplicate(true)}
	story_request.merge(extra,true)
	story=NarrativeSession.new(s,story_request)
	# AudioDirector must not also synthesize this queue from a joined feedback toast.
	return {"handled":true,"message":"","narrative_owned":true}

func finish_story(s: Dictionary,value: Variant) -> Dictionary:
	if not value is NarrativeSession or value!=story or not value.consume(s): return locked("对话尚未结束。")
	var finish: String=str(story_request.get("onComplete",""))
	if story.sequence_id=="theater_entry": theater_entry_played=true
	if story.sequence_id=="theater_reversal": s.native.c3_reversal_pending=false
	story=null; story_request={}
	match finish:
		"tray_start": s.canteenHunt.trayTaskStarted=true
		"canteen_exit": return _audio_event(enter(s,"campus_bootstrap","c3_canteen","campus_canteen_gate"),"canteen_returned_to_campus")
		"admission":
			var point: Dictionary=world("theater_interior").spawns.theater_auditorium
			return {"handled":true,"teleport":[point.x,point.y]}
		"approach":
			s.qizhenLake.locationBriefingSeen=true
			s.rpgCheckpoint="campus_qizhen_transition_stop"
			var point: Dictionary=world("campus_qizhen_loop").manifest.qizhen.approachTransition.stop
			s.native.player={"x":point.x,"y":point.y,"scene":"campus_qizhen_loop"}
	return response()

func scene_session(s: Dictionary) -> RefCounted:
	if not SceneSession.pending_canteen(s):
		if entry_session != null: entry_session.cancel()
		entry_session = null
		return null
	if entry_session == null or not entry_session.valid(s) or entry_session.status in ["cancelled","consumed"]:
		if entry_session != null: entry_session.cancel()
		entry_session = SceneSession.new(s,"canteen",bool(s.native.get("settings",{}).get("reduced_motion",false)))
	return entry_session

const Lake = preload("res://scripts/chapters/c3_lake.gd")
const Interlude = preload("res://scripts/chapters/c3_interlude.gd")
const Chase = preload("res://scripts/games/chase_stunt_model.gd")
const Spotlight = preload("res://scripts/games/c3_spotlight_model.gd")
const FOOD_ITEMS: Dictionary = {"A":"canteenRealBun","B":"canteenCluelessSoyMilk","C":"canteenEdgeEgg","E":"canteenUselessCongee"}
const ORDER_WINDOW: Dictionary = {"A":"1","B":"2","D":"3","C":"4","E":"5"}
const RECIPE: Array = ["blackCoffee","sparklingWater","lemonTea"]
const TRAYS: Array = ["tray_blue_01","tray_blue_02","tray_blue_03"]
const PROGRAM: Dictionary = {"opening":"theaterProgramOpening","spotlight":"theaterProgramSpotlight","finale":"theaterProgramFinale"}
const PROGRAM_ORDER: Array = ["spotlight","opening","finale"]
var lake: RefCounted = Lake.new()
var interlude: RefCounted = Interlude.new()
var spotlight: RefCounted = Spotlight.new()
var defense_pending: Dictionary = {}
var defense_session_counter: int = 0

func pages(s: Dictionary) -> Array:
	var list: Array = []
	if s.canteenHunt.active:
		list.append({"id":"c3_canteen","label":"东区食堂"})
		list.append({"id":"c3_campus_map","label":"浙大钉 · 校园地图"})
	if s.theaterHunt.active:
		list.append({"id":"c3_theater","label":"剧院"})
		list.append({"id":"c3_ticket_post","label":"CC98 · 临时退票"})
	list.append_array(lake.pages(s))
	list.append_array(interlude.pages(s))
	return list

func view(page: String, s: Dictionary) -> Dictionary:
	var c: Dictionary = s.canteenHunt
	var t: Dictionary = s.theaterHunt
	match page:
		"c3_location": return {"title":prose("chapter3-qizhen-lake.content","locationSearch.approachTransition.label"),"body":"","art":"res://assets/rpg/campus/zijingang_campus_loop_panorama.png"}
		"c3_campus_map": return {"title":"浙大钉 · 校园地图","body":"紫金港校区","art":"res://assets/rpg/campus/zijingang_campus_plate.png"}
		"c3_canteen":
			var body: String = prose("chapter3-canteen.content","entryDialogue") if c.entryPaperEscaped else ""
			if c.trayTaskStarted: body += "\n"+prose("chapter3-canteen.content","tray.taskStarted")+"\n已交回 %d / 3" % tray_count(c)
			if c.drinkShelfRead: body += "\n"+prose("chapter3-canteen.content","drinks.shelfOrder")
			if c.phase in ["menu_order","pickup_search"]:
				body += "\n"+prose("chapter3-canteen.content","menu.darkIntro" if mode(s,"canteenHunt")=="dark" else "menu.lightIntro")
				for entry: Dictionary in content("chapter3-canteen.content").menu.options:
					body += "\n"+entry.id+" · "+entry["dark" if mode(s,"canteenHunt")=="dark" else "light"]
			return {"title":"东区食堂","body":body,"art":"res://assets/rpg/interiors/canteen_interior.png"}
		"c3_mixer": return {"title":"混合台","body":prose("chapter3-canteen.content","drinks.mixerPrompt")+"\n已加入："+words(c.drinkMixSequence)}
		"c3_menu": return {"title":"点餐机","body":prose("chapter3-canteen.content","menu.lightIntro")}
		"c3_bike": return {"title":"共享单车","body":prose("chapter3-canteen.content","bike.scan")+"\n我的零钱：%.2f 元" % (float(s.wallet.cashCents)/100.0)}
		"c3_theater":
			var body: String = "" if t.phase=="entry_ticket" else prose("chapter3-theater.content","phaseUpdates."+str(t.phase))
			if t.ticketCodeRead: body += "\n"+prose("chapter3-theater.content","ticket.codeVisible")
			return {"title":"剧院","body":body,"art":"res://assets/rpg/interiors/theater_interior.png"}
		"c3_ticket_post":
			var key: String = {"posted":"postedStatus","accepted":"acceptedStatus","first_wave_failed":"firstWaveStatus","delivered":"deliveredStatus"}.get(t.cc98TicketCommissionPhase,"postedStatus")
			return {"title":prose("chapter3-theater.content","cc98TicketCommission.title"),"body":prose("chapter3-theater.content","cc98TicketCommission.body")+"\n"+prose("chapter3-theater.content","cc98TicketCommission.initialReply")+"\n"+prose("chapter3-theater.content","cc98TicketCommission."+key)}
		"c3_kiosk": return {"title":"自助取票","body":prose("chapter3-theater.content","ticket.codePrompt")}
		"c3_program":
			var body: String = prose("chapter3-theater.content","program.consolePrompt")
			for id: String in t.collectedProgramIds:
				body += "\n"+prose("chapter3-theater.content","program.labels."+id)
				if mode(s,"theaterHunt")=="dark": body += " · 荧光编号 "+str(PROGRAM_ORDER.find(id)+1)
			return {"title":"节目单与灯控台","body":body}
	var result: Dictionary = lake.view(page,s)
	return result if not result.is_empty() else interlude.view(page,s)

func actions(page: String, s: Dictionary) -> Array:
	var c: Dictionary = s.canteenHunt
	var t: Dictionary = s.theaterHunt
	var list: Array = []
	match page:
		"c3_campus_map": list.append(command("c3_walk_campus","进入校园地图"))
		"c3_canteen":
			if c.phase not in ["chasing","theater_reached"] and s.native.scene!="canteen_interior": list.append(command("c3_open_map","查看校园地图"))
			if c.phase=="theater_reached": list.append(command("c3_enter_theater","进入剧院"))
			if c.phase=="exit_blocking": list.append(command("c3_defense","重新拦截纸条"))
			if c.phase=="chasing": list.append(command("c3_chase","开始骑行" if c.chaseAttemptCount==0 else "重试骑行"))
		"c3_mixer":
			for item: String in RECIPE:
				if own(s,item): list.append(command("c3_mix:"+item,{"blackCoffee":"倒入黑咖啡","sparklingWater":"倒入气泡水","lemonTea":"倒入柠檬茶"}[item]))
			if own(s,"badDrink"): list.append(command("c3_bad_drink","试饮"))
		"c3_menu":
			if c.phase=="menu_order":
				var opts: Array = []
				for entry: Dictionary in content("chapter3-canteen.content").menu.options: opts.append(option(entry.id,entry.light))
				list.append(field("c3_order","下单",opts))
		"c3_bike":
			list.append(command("c3_bike_inspect","查看车锁"))
			if own(s,"greaseTissue"): list.append(command("c3_bike_clean","用油渍纸巾擦拭车锁"))
			if not c.bikePaid: list.append(command("c3_bike_pay","扫码支付骑行费"))
			else: list.append(command("c3_chase","开始骑行"))
		"c3_ticket_post":
			if t.cc98TicketCommissionPhase=="posted": list.append(command("c3_ticket_accept",prose("chapter3-theater.content","cc98TicketCommission.acceptLabel")))
			if t.cc98TicketCommissionPhase in ["accepted","first_wave_failed"]: list.append(command("c3_ticket_claim",prose("chapter3-theater.content","cc98TicketCommission.firstWaveLabel" if t.cc98TicketCommissionPhase=="accepted" else "cc98TicketCommission.secondWaveLabel")))
			list.append(field("c3_network","连接网络",[option("campus_wifi","校园网"),option("cellular","移动数据"),option("offline","无网络")]))
		"c3_kiosk": list.append(field("c3_ticket_code","输入取票码"))
		"c3_theater":
			if own(s,"theaterTicketHalfA") and own(s,"theaterTicketHalfB"): list.append(command("c3_ticket_combine","拼接两张票根"))
			if t.phase=="spotlight_hunt": list.append(command("c3_spotlight","开始本幕"))
			if t.phase=="reversal": list.append(command("c3_reversal","翻看纸条背面"))
		"c3_program":
			if t.phase=="program_search":
				var inputs: Array = []
				for index: int in range(3):
					inputs.append({"id":"slot"+str(index),"label":"第 %d 位" % (index+1),"type":"choice","options":[option("opening","开场"),option("spotlight","追光"),option("finale","谢幕")]})
				list.append({"id":"c3_program_submit","label":"提交节目顺序","inputs":inputs})
	list.append_array(lake.actions(page,s))
	list.append_array(interlude.actions(page,s))
	return list

func dispatch(s: Dictionary, action: String, value: Variant = null) -> Dictionary:
	if action=="c3_story_complete": return finish_story(s,value)
	if action=="c3_reversal_visual_complete":
		if not value is NarrativeSession or value!=story or value.sequence_id!="theater_reversal" or s.theaterHunt.phase!="reversal" or s.theaterHunt.spotlightRound<3 or not value.consume_visual(s): return locked("纸面还没有裂开。")
		s.theaterHunt.phase="complete"; s.theaterHunt.decoyRevealed=true
		s.items.decoyPaper=true; s.items.wetProgram=true
		s.qizhenLake.active=true; s.qizhenLake.phase="location_search"
		return {"handled":true,"message":"","narrative_owned":true}
	if action=="c3_reversal_inspect_closed":
		if not value is NarrativeSession or value!=story or value.sequence_id!="theater_reversal" or not value.consume_inspector(s): return locked("先看完纸条背面。")
		return _audio_event({"handled":true,"message":"","narrative_owned":true},"theater_decoy_inspect_closed")
	if action=="c3_promo_visual_complete":
		if not value is NarrativeSession or value!=story or not value.consume_visual(s): return locked("队列尚未让开。")
		s.canteenHunt.queueGapOpened=true; s.canteenHunt.phase="menu_order"
		return _audio_event(response(),"canteen_queue_gap_opened")
	if narrative_session(s)!=null: return locked("对话尚未结束。")
	var result: Dictionary = lake.dispatch(s,action,value)
	if not result.is_empty(): return result
	result=interlude.dispatch(s,action,value)
	if not result.is_empty(): return result
	if not action.begins_with("c3_"): return {}
	var c: Dictionary = s.canteenHunt
	var t: Dictionary = s.theaterHunt
	if action=="c3_entry_paper_complete":
		if not value is SceneSession or value != entry_session or value.kind != "canteen" or not value.consume(s): return locked("纸条仍在食堂入口。")
		c.entryPaperEscaped=true
		return response()
	if action.begins_with("c3_target:"): return physical(s,action.trim_prefix("c3_target:"))
	if action=="c3_charge_result":
		if value!=charge_session or not value is ChargeSession: return locked("补电回执已失效。")
		if charge_session.phase=="cancelled": return response("接线已断开，本次补电未完成。")
		if not charge_session.consume(s): return locked("补电尚未完成。")
		if s.phoneBattery.percent>=45: return response("当前电量 %d%%，暂不需要补电。" % int(s.phoneBattery.percent))
		s.phoneBattery.percent=45
		s.phoneBattery.rechargeCount+=1
		return response("已接入手机充电服务站，电量恢复至 45%。")
	if action=="c3_network":
		if str(value) not in ["campus_wifi","cellular","offline"]: return locked()
		if s.networkMode!=value: s.phoneBattery.percent=maxi(1,int(s.phoneBattery.percent)-1)
		s.networkMode=value
		return response("已切换网络。")
	if action=="c3_open_map": return {"handled":true,"page":"c3_campus_map"}
	if action=="c3_walk_campus":
		if not c.active: return locked()
		return enter(s,"campus_bootstrap","c3_campus_map",s.rpgCheckpoint if str(s.rpgCheckpoint).begins_with("campus_") else "campus_canteen_gate")
	if action=="c3_enter_canteen":
		if not c.active or c.phase in ["chasing","theater_reached"]: return locked()
		var gate: Dictionary=world("campus_bootstrap").manifest.canteen.gate
		if not near(s,"campus_bootstrap",[gate.x,gate.y],float(gate.radius)): return locked("先沿校园地图走到食堂入口。")
		if c.phase in ["tracking","canteen_reached","entered"]: c.phase="tray_search"
		return enter(s,"canteen_interior","c3_canteen","canteen_entrance")
	if action=="c3_enter_theater":
		if c.phase!="theater_reached" and not t.active: return locked()
		var gate: Dictionary=world("campus_bootstrap").manifest.theater.gate
		if not near(s,"campus_bootstrap",[gate.x,gate.y],float(gate.radius)): return locked("先沿校园地图走到剧院入口。")
		if not t.active:
			t.active=true
			t.phase="entry_ticket"
			t.cc98TicketCommissionPhase="posted"
		return enter(s,"theater_interior","c3_theater","theater_auditorium" if t.admitted else "theater_lobby")
	if action.begins_with("c3_mix:"):
		var item: String = action.trim_prefix("c3_mix:")
		if not side_active(c) or c.promoDrinkPlaced or not own(s,item) or item not in RECIPE or not can_operate(s,"canteen_interior","canteen-mixer"): return locked()
		consume(s,item)
		c.drinkMixSequence.append(item)
		if c.drinkMixSequence.size()<3: return response(prose("chapter3-canteen.content","drinks.ingredientAdded"))
		var correct: bool = c.drinkMixSequence==RECIPE
		c.drinkMixSequence=[]
		c.drinkMixAttemptCount+=1
		s.items["dailySpecialSparklingWater" if correct else "badDrink"]=true
		return response(prose("chapter3-canteen.content","drinks.correctMix" if correct else "drinks.wrongMix"))
	match action:
		"c3_defense":
			if c.phase!="exit_blocking" or s.native.scene!="canteen_interior": return locked()
			var path: String="res://scripts/games/canteen_defense.gd"
			if not ResourceLoader.exists(path): return locked("原生拦截场景仍在加载，剧情尚未前进。")
			defense_session_counter+=1
			defense_pending={"session_id":defense_session_counter,"seed":str(defense_session_counter)}
			return {"handled":true,"game":{"script":path,"on_success":"c3_defense_result","session_id":defense_session_counter,"seed":defense_pending.seed,"start_elapsed":0}}
		"c3_defense_result":
			if c.phase!="exit_blocking" or not value is Dictionary or defense_pending.is_empty() or value.get("session_id")!=defense_pending.session_id: return locked("拦截记录不匹配。")
			var seed_value: String=defense_pending.seed
			defense_pending={}
			var path: String="res://scripts/games/canteen_defense_model.gd"
			if not ResourceLoader.exists(path): return locked("拦截记录无法验证。")
			var model: Variant=load(path)
			if not model.validate_result(value,seed_value): return locked("纸条已离开 · 重新拦截")
			# Recover final physical actor positions from the validated input trace,
			# never from caller-supplied terminal coordinates.
			var replay: RefCounted=model.new()
			replay.configure(seed_value)
			for attempt: Array in value.get("attempts",[]):
				model.replay_inputs(replay,attempt); replay.restart_attempt(false)
			model.replay_inputs(replay,value.inputs)
			c.blockHits=3
			c.phase="chase_ready"
			var reduced: bool=s.native.get("settings",{}).get("reduced_motion",false)
			return tell(s,"canteen_escape","chapter3-canteen.content","blocking.escapeDialogue",{"delayMs":220 if reduced else 1020,"stepMs":1200,"tailMs":166 if reduced else 475,"onComplete":"canteen_exit","paperStart":[replay.paper.x,replay.paper.y],"playerStart":[replay.player.x,replay.player.y]})
		"c3_bad_drink":
			if not own(s,"badDrink"): return locked()
			consume(s,"badDrink")
			return tell(s,"canteen_bad_drink","chapter3-canteen.content","drinks.badDrinkConsumed")
		"c3_order":
			if c.phase!="menu_order" or not can_operate(s,"canteen_interior","ordering_kiosk"): return locked()
			if not ORDER_WINDOW.has(str(value)) or own(s,"pickupTicket0755"): return locked()
			c.orderedMenuOption=str(value)
			c.orderAttemptCount+=1
			c.phase="pickup_search"
			s.items.pickupTicket0755=true
			return tell(s,"canteen_order","chapter3-canteen.content","menu.correct" if value=="D" else "menu.wrongGeneric")
		"c3_bike_inspect":
			if c.phase!="chase_ready" or not near_source(s,"campus_bootstrap",get_definition("campus_bootstrap","bike",s)): return locked()
			if mode(s,"canteenHunt")=="dark":
				c.bikeCodeRead=true
				return response(prose("chapter3-canteen.content","bike.codeVisible"))
			return _audio_event(response(prose("chapter3-canteen.content","bike.lockCleaned" if c.bikeLockCleaned else "bike.glareFailed")), "canteen_bike_payment_ready" if c.bikeLockCleaned else "canteen_bike_glare_failed")
		"c3_bike_clean":
			if c.phase!="chase_ready" or not can_operate(s,"campus_bootstrap","bike") or not own(s,"greaseTissue"): return locked(prose("chapter3-canteen.content","bike.scanRule"))
			c.bikeLockCleaned=true
			return _audio_event(response(prose("chapter3-canteen.content","bike.lockCleaned")), "canteen_bike_lock_cleaned")
		"c3_bike_pay":
			if c.phase!="chase_ready" or not c.bikeLockCleaned or not can_operate(s,"campus_bootstrap","bike"): return locked(prose("chapter3-canteen.content","bike.scanRule"))
			if c.bikePaid: return response()
			if not own(s,"cafeteriaWages") or s.wallet.cashCents<200: return locked(prose("chapter3-canteen.content","bike.noMoney"))
			consume(s,"cafeteriaWages")
			s.wallet.cashCents-=200
			c.bikePaid=true
			return response(prose("chapter3-canteen.content","bike.unlock"))
		"c3_chase":
			if c.phase not in ["chase_ready","chasing"] or not c.bikePaid or c.chaseCompleted: return locked()
			c.phase="chasing"
			return {"handled":true,"game":{"type":"chase","on_success":"c3_chase_result","mode":"story","goal":755,"distance":0,"lives":3,"title":prose("chapter3-canteen.content","bike.task"),"instructions":"左右转向，蓄力跳跃、铃铛清道，托盘和风力道具只在本局有效。"}}
		"c3_chase_result":
			if c.phase!="chasing" or not value is Dictionary: return locked("骑行记录无效。")
			var distance: int = int(value.get("distance",-1))
			var lives: int = int(value.get("lives",-1))
			if value.get("mode")!="story" or distance<0 or distance>755 or lives<0 or lives>3 or int(value.get("collisions",-1))<0: return locked("骑行记录无效。")
			if not (distance==755 and lives>0) and lives!=0: return locked("骑行尚未到达终点。")
			if lives>0 and not Chase.validate_result(value): return locked("骑行输入记录未通过重放核验。")
			c.chaseAttemptCount+=1
			c.chaseBestDistance=maxi(int(c.chaseBestDistance),distance)
			if lives==0: return response("本次骑行失败，可以重试。")
			c.chaseCompleted=true
			c.chaseBestLives=maxi(int(c.chaseBestLives),lives)
			c.chaseCollisions=value.collisions
			c.phase="theater_reached"
			result=enter(s,"campus_bootstrap","c3_canteen","campus_theater_junction")
			result.message=prose("chapter3-canteen.content","bike.finish")
			return result
		"c3_ticket_accept":
			if not t.active or t.phase!="entry_ticket" or t.cc98TicketCommissionPhase!="posted": return locked()
			t.cc98TicketCommissionPhase="accepted"
			return response(prose("chapter3-theater.content","cc98TicketCommission.acceptedStatus"))
		"c3_ticket_claim":
			if t.phase!="entry_ticket" or t.cc98TicketCommissionPhase not in ["accepted","first_wave_failed"]: return locked()
			var wave: int = 1 if t.cc98TicketCommissionPhase=="accepted" else 2
			if s.networkMode!="cellular":
				t.cc98TicketCommissionPhase="first_wave_failed"
				return response(prose("chapter3-theater.content","cc98TicketCommission.networkTooSlowStatus"))
			t.cc98TicketCommissionPhase="delivered"
			t.cc98TicketClaimedWave=wave
			return response(prose("chapter3-theater.content","cc98TicketCommission.deliveredFirstWaveReply" if wave==1 else "cc98TicketCommission.deliveredReply"))
		"c3_ticket_code":
			if t.phase!="entry_ticket" or not can_operate(s,"theater_interior","theater_ticket_kiosk"): return locked()
			t.ticketCodeAttempts+=1
			if str(value)!="0832": return locked(prose("chapter3-theater.content","ticket.codeWrong"))
			if t.cc98TicketCommissionPhase!="delivered": return locked(prose("chapter3-theater.content","ticket.phoneReleaseRequired"))
			if not own(s,"temporaryTheaterTicket"): s.items.theaterTicketHalfB=true
			t.ticketCodeRead=true
			return tell(s,"theater_printed","chapter3-theater.content","ticket.ticketPrinted")
		"c3_ticket_combine":
			if not own(s,"theaterTicketHalfA") or not own(s,"theaterTicketHalfB"): return locked()
			consume(s,"theaterTicketHalfA")
			consume(s,"theaterTicketHalfB")
			s.items.temporaryTheaterTicket=true
			return tell(s,"theater_combined","chapter3-theater.content","ticket.combinedDialogue")
		"c3_program_submit":
			if t.phase!="program_search" or not can_operate(s,"theater_interior","theater_light_console"): return locked()
			var order: Array = [value.get("slot0"),value.get("slot1"),value.get("slot2")] if value is Dictionary else parse_order(value)
			if order.size()!=3 or t.collectedProgramIds.size()!=3: return locked(prose("chapter3-theater.content","program.darkIncomplete"))
			t.programOrder=order
			if order!=PROGRAM_ORDER:
				t.programWrongAttempts+=1
				t.programOrder.pop_back()
				return tell(s,"theater_wrong_order","chapter3-theater.content","program.wrongDialogue")
			for item: String in PROGRAM.values(): consume(s,item)
			s.items.spotlightRemote=true
			t.phase="prop_setup"
			return response(prose("chapter3-theater.content","program.unlocked"))
		"c3_spotlight":
			if t.phase!="spotlight_hunt" or mode(s,"theaterHunt")!="light": return locked()
			return {"handled":true,"game":{"script":"res://scripts/games/c3_spotlight.gd","on_success":"c3_spotlight_continue","on_attempt":"c3_spotlight_result","round":int(t.spotlightRound),"attempt":int(t.spotlightMistakes),"title":"追光灯辞职以后"}}
		"c3_spotlight_continue":
			return dispatch(s,"c3_reversal" if t.phase=="reversal" else "c3_spotlight")
		"c3_spotlight_result":
			if t.phase!="spotlight_hunt": return locked()
			var verified: Dictionary = spotlight.validate(value,int(t.spotlightRound),int(t.spotlightMistakes))
			if verified.is_empty(): return locked("演出记录没有完成，请重演本幕。")
			if verified.status=="lost":
				t.spotlightMistakes+=1
				return _audio_event(response(prose("chapter3-theater.content","spotlight.miss")), "theater_spotlight_missed", {"round":verified.round,"reason":"shadow" if int(verified.lives)<=0 else "timeout"})
			t.spotlightRound+=1
			if t.spotlightRound>=3: t.phase="reversal"
			return _audio_event(response(prose("chapter3-theater.content","spotlight.hit")), "theater_spotlight_third_hit" if int(t.spotlightRound)>=3 else "theater_spotlight_hit", {"round":t.spotlightRound,"collected":verified.collected.size(),"ticks":verified.tick})
		"c3_reversal":
			if t.phase!="reversal" or t.spotlightRound<3: return locked()
			s.native.c3_reversal_pending=true
			return tell(s,"theater_reversal","chapter3-theater.content","spotlight.endingDialogue",{"delayMs":1320,"visualCompleted":false})
	return locked()

func _initial_npcs(s: Dictionary) -> Array:
	if is_same(npc_state,s) and not npc_targets.is_empty(): return npc_targets
	npc_state=s; npc_targets=[]
	var c: Dictionary=world_source.constants
	var queue: Array=[]
	for x: float in c.CANTEEN_COUNTER_NPC_X:
		for y: float in c.CANTEEN_QUEUE_NPC_Y: queue.append({"x":x,"y":y})
	queue.shuffle()
	var seated: Array=c.CANTEEN_SEATED_NPC_PLACEMENTS.duplicate(true)+c.CANTEEN_SEATED_EXTRA_NPC_PLACEMENTS.duplicate(true)
	seated.shuffle()
	for i in range(c.CANTEEN_QUEUE_NPC_DIALOGUE.size()):
		npc_targets.append({"id":"initial-queue-npc-"+str(i),"label":"交谈","x":queue[i].x,"y":queue[i].y,"proximity":48,"kind":"npc","dialogue":c.CANTEEN_QUEUE_NPC_DIALOGUE[i]})
	for i in range(c.CANTEEN_SEATED_NPC_DIALOGUE.size()):
		npc_targets.append({"id":"initial-seated-npc-"+str(i),"label":"交谈","x":seated[i].x,"y":seated[i].y-30,"width":72,"height":88,"proximity":54,"kind":"npc","dialogue":c.CANTEEN_SEATED_NPC_DIALOGUE[i]})
	var x: float=c.CANTEEN_COUNTER_NPC_X.pick_random()
	npc_targets.append({"id":"initial-counter-npc","label":"交谈","x":x,"y":c.CANTEEN_COUNTER_NPC_Y,"stand":{"x":x,"y":265},"width":64,"height":80,"proximity":56,"kind":"npc","dialogue":c.CANTEEN_COUNTER_NPC_DIALOGUE})
	return npc_targets

func definitions(scene: String, s: Dictionary) -> Array:
	if scene!=npc_scene:
		npc_scene=scene; npc_targets=[]
	var list: Array = source_targets(scene).duplicate(true)
	if scene=="campus_bootstrap" and s.canteenHunt.phase=="chase_ready":
		var bike: Dictionary=world(scene).manifest.canteen.bike
		list.append({"id":"bike","label":"共享单车","x":bike.x,"y":bike.y,"proximity":170,"kind":"bike"})
	if scene=="canteen_interior":
		var constants: Dictionary = world(scene).constants
		list.append_array(constants.CANTEEN_DRINK_MACHINES)
		for key: String in ["CANTEEN_DRINK_SHELF","CANTEEN_MIX_STATION","CANTEEN_PROMO_BOARD","CANTEEN_QUEUE_COLUMN_THREE"]: list.append(constants[key])
		list.append({"id":"auntie","label":"与收餐口阿姨交谈","x":1515,"y":610,"stand":{"x":1466,"y":608},"width":46,"height":70,"proximity":64,"kind":"auntie"})
		list.append_array(_initial_npcs(s))
		if not s.native.get("c3_tray_slots") is Array or s.native.c3_tray_slots.size()<constants.CANTEEN_TRAYS.size():
			var slots: Array = constants.CANTEEN_TRAY_SLOTS.duplicate(true)
			slots.shuffle()
			s.native.c3_tray_slots=slots.slice(0,12)
		var trays: Array = constants.CANTEEN_TRAYS
		for index: int in range(trays.size()):
			var slot: Dictionary = s.native.c3_tray_slots[index]
			list.append({"id":trays[index].id,"label":"餐盘","kind":"tray","x":slot.x,"y":slot.y,"width":26,"height":40,"proximity":85,"stand":slot.stand})
	return list

func get_definition(scene: String, id: String, s: Dictionary) -> Dictionary:
	for entry: Dictionary in definitions(scene,s):
		if entry.id==id: return entry
	return {}

func can_operate(s: Dictionary, scene: String, id: String) -> bool:
	if scene=="canteen_interior" and SceneSession.pending_canteen(s): return false
	var key: String = "canteenHunt" if scene in ["canteen_interior","campus_bootstrap"] else "theaterHunt"
	var entry: Dictionary = get_definition(scene,id,s)
	return not entry.is_empty() and mode(s,key)=="light" and near_source(s,scene,entry)

func side_active(c: Dictionary) -> bool:
	return c.active and c.phase in ["tray_search","drink_mix","menu_order","pickup_search","chase_ready"]

func tray_count(c: Dictionary) -> int:
	var count: int = 0
	for id: String in TRAYS:
		if c.returnedTrayIds.has(id): count+=1
	return count

func physical(s: Dictionary, id: String) -> Dictionary:
	var scene: String = str(s.native.scene)
	if scene=="canteen_interior" and SceneSession.pending_canteen(s): return locked("先找到排队的纸条。")
	var entry: Dictionary = get_definition(scene,id,s)
	if entry.is_empty() or not near_source(s,scene,entry): return locked("先走近一点再操作。")
	if scene=="campus_bootstrap" and id=="bike" and s.canteenHunt.phase=="chase_ready": return {"handled":true,"page":"c3_bike"}
	if scene=="canteen_interior": return canteen_target(s,entry)
	if scene=="theater_interior": return theater_target(s,entry)
	return locked()

func canteen_target(s: Dictionary, entry: Dictionary) -> Dictionary:
	var c: Dictionary = s.canteenHunt
	var dark: bool = mode(s,"canteenHunt")=="dark"
	var id: String = entry.id
	match str(entry.kind):
		"npc":
			if dark or c.phase not in ["tray_search","drink_mix"]: return locked()
			if str(entry.id).begins_with("initial-queue-npc-") and float(entry.x)==float(world("canteen_interior").constants.CANTEEN_QUEUE_COLUMN_THREE.x): return locked()
			return tell_lines(s,"canteen_npc_"+str(entry.id),[entry.dialogue])
		"auntie":
			if not side_active(c) or dark: return locked()
			if tray_count(c)==3: return tell(s,"canteen_tray_done","chapter3-canteen.content","tray.afterCompletion")
			if not c.trayTaskStarted:
				return tell(s,"canteen_tray_intro","chapter3-canteen.content","tray.introDialogue",{"onComplete":"tray_start"})
			if c.carriedTrayIds.is_empty(): return response(prose("chapter3-canteen.content","tray.emptyHanded"))
			if dark: return response(prose("chapter3-canteen.content","tray.collectWrongMode"))
			var tray_id: String = c.carriedTrayIds[0]
			unique(c.returnedTrayIds,tray_id)
			c.carriedTrayIds=[]
			if tray_count(c)==3:
				if not own(s,"cafeteriaWages"):
					s.items.cafeteriaWages=true
					s.items.greaseTissue=true
					s.wallet.cashCents+=200
				return tell_lines(s,"canteen_tray_complete",[prose("chapter3-canteen.content","tray.correctReturn")]+source_lines("chapter3-canteen.content","tray.completionDialogue"))
			return tell(s,"canteen_tray_return","chapter3-canteen.content","tray.correctReturn" if tray_id in TRAYS else "tray.wrongReturn")
		"tray":
			if not side_active(c) or not c.trayTaskStarted or c.returnedTrayIds.has(id) or tray_count(c)==3: return locked()
			if dark:
				if id in TRAYS:
					c.identifiedTrayIds=TRAYS.duplicate()
					return response("油渍和蓝光都在。")
				return response("这只餐盘很干净。")
			if not c.carriedTrayIds.is_empty(): return response(prose("chapter3-canteen.content","tray.handsFull"))
			c.carriedTrayIds=[id]
			return response(prose("chapter3-canteen.content","tray.collected"))
		"queue_gap":
			c.queueChallengeSeen=true
			return tell(s,"canteen_queue","chapter3-canteen.content","drinks.queueDialogue")
		"drink_machine":
			if not side_active(c) or c.promoDrinkPlaced or dark: return locked()
			s.items[entry.value]=true
			return response(prose("chapter3-canteen.content","drinks.collected."+str(entry.value)))
		"drink_shelf":
			c.drinkShelfRead=true
			return response(prose("chapter3-canteen.content","drinks.shelfPrompt")+"\n"+prose("chapter3-canteen.content","drinks.shelfOrder"))
		"mixer": return {"handled":true,"page":"c3_mixer"}
		"promo":
			if not side_active(c) or c.promoDrinkPlaced or not own(s,"dailySpecialSparklingWater") or dark: return locked()
			consume(s,"dailySpecialSparklingWater")
			c.promoDrinkPlaced=true
			return tell(s,"canteen_promo","chapter3-canteen.content","drinks.queueShiftDialogue",{"delayMs":PromoTimeline.timing(bool(s.native.get("settings",{}).get("reduced_motion",false))).completeAt})
		"kiosk":
			if c.phase not in ["menu_order","pickup_search"]: return locked()
			if dark:
				c.menuDarkClueRead=true
				var lines: String = prose("chapter3-canteen.content","menu.darkIntro")
				for opt: Dictionary in content("chapter3-canteen.content").menu.options: lines+="\n"+opt.id+" · "+opt.dark
				return response(lines)
			return {"handled":true,"page":"c3_menu"}
		"pickup":
			if dark:
				if str(entry.value)=="3": c.pickupDarkClueRead=true
				return tell(s,"canteen_pickup_clue","chapter3-canteen.content","pickup.darkClueRead") if str(entry.value)=="3" else response(prose("chapter3-canteen.content","pickup.darkEmpty"))
			if c.phase!="pickup_search" or not own(s,"pickupTicket0755"): return locked(prose("chapter3-canteen.content","pickup.noTicket"))
			if ORDER_WINDOW.get(c.orderedMenuOption)!=str(entry.value): return locked(prose("chapter3-canteen.content","pickup.wrongWindow"))
			var selected: String = c.orderedMenuOption
			consume(s,"pickupTicket0755")
			c.orderedMenuOption=null
			c.pickupAttemptCount+=1
			if selected!="D":
				s.items[FOOD_ITEMS[selected]]=true
				c.phase="menu_order"
				return response(prose("chapter3-canteen.content","pickup.foodCollected."+selected))
			c.phase="exit_blocking"
			var defense: Dictionary=dispatch(s,"c3_defense")
			if defense.get("game") is Dictionary: defense.game["source_pickup_prelude"]=true
			defense.message=prose("chapter3-canteen.content","pickup.window3")
			return defense
		"cart":
			# Retained source legacy objects are not an alternative completion route.
			return locked("纸条正在寻找出口，需要持续拦截。")
		"bike":
			if c.phase!="chase_ready": return locked()
			return {"handled":true,"page":"c3_bike"}
		"exit":
			if not side_active(c): return locked()
			return enter(s,"campus_bootstrap","c3_canteen","campus_canteen_gate")
	return locked()

func theater_target(s: Dictionary, entry: Dictionary) -> Dictionary:
	var t: Dictionary = s.theaterHunt
	var dark: bool = mode(s,"theaterHunt")=="dark"
	match str(entry.kind):
		"charger":
			if dark: return locked("深色观察只能查看设备。切到浅色操作后接入充电线。")
			if s.phoneBattery.percent>=45: return response("当前电量 %d%%，暂不需要补电。" % int(s.phoneBattery.percent))
			if not ChargeSession.rejection(s).is_empty(): return locked("请走到充电服务站旁接线。")
			if charge_session!=null and charge_session.phase=="charging": return response("正在补电，请在设备旁稍候")
			charge_session=ChargeSession.new()
			return {"handled":true,"world_effect":{"script":"res://scripts/media/c3_charging.gd","session":charge_session,"on_event":"c3_charge_result","target_id":"theater_charging_station"}}
		"poster":
			if t.phase!="entry_ticket" or t.posterCleaned: return locked()
			if dark or not own(s,"greaseTissue"): return response(prose("chapter3-theater.content","ticket.posterGlare"))
			consume(s,"greaseTissue")
			t.posterCleaned=true
			s.items.theaterTicketHalfA=true
			return response(prose("chapter3-theater.content","ticket.posterCleaned"))
		"kiosk":
			if t.phase!="entry_ticket": return locked()
			if dark:
				t.ticketCodeRead=true
				return response(prose("chapter3-theater.content","ticket.codeVisible"))
			return {"handled":true,"page":"c3_kiosk"}
		"gate":
			if t.phase!="entry_ticket" or dark or not own(s,"temporaryTheaterTicket"): return response(prose("chapter3-theater.content","ticket.gateDenied"))
			t.admitted=true
			t.phase="program_search"
			s.rpgCheckpoint="theater_auditorium" # Original controller commits this before the admission exchange.
			return tell(s,"theater_admission","chapter3-theater.content","ticket.admissionDialogue",{"onComplete":"admission","tailMs":80 if s.native.get("settings",{}).get("reduced_motion",false) else 260})
		"program":
			if t.phase!="program_search": return locked()
			if dark: return response(prose("chapter3-theater.content","program.labels."+str(entry.programId))+" · 荧光编号 "+str(PROGRAM_ORDER.find(entry.programId)+1))
			unique(t.collectedProgramIds,entry.programId)
			s.items[PROGRAM[entry.programId]]=true
			return response(prose("chapter3-theater.content","program.ordinary"))
		"console":
			if t.phase=="program_search":
				if dark: return response(prose("chapter3-theater.content","program.darkInspectHint"))
				if t.collectedProgramIds.size()<3: return tell_lines(s,"theater_console",[prose("chapter3-theater.content","program.consolePrompt"),prose("chapter3-theater.content","program.consoleState")])
				return {"handled":true,"page":"c3_program"}
			if t.phase!="spotlight_ready" or dark or not own(s,"spotlightRemote") or not t.paperDusted: return locked()
			consume(s,"spotlightRemote")
			t.phase="spotlight_hunt"
			return dispatch(s,"c3_spotlight")
		"prop":
			if t.phase!="prop_setup": return locked()
			if dark:
				t.propGhostRead=true
				t.managerHintRead=true
				return tell_lines(s,"theater_prop_ghost",[prose("chapter3-theater.content","prop.ghost"),prose("chapter3-theater.content","prop.managerHint")])
			return response(prose("chapter3-theater.content","prop.opened" if t.propBoxOpened else "prop.locked"))
		"scanner":
			if t.phase!="prop_setup" or dark or not own(s,"temporaryTheaterTicket"): return locked()
			consume(s,"temporaryTheaterTicket")
			s.items.fluorescentBrush=true
			t.propBoxOpened=true
			return response(prose("chapter3-theater.content","prop.scannerAccepted"))
		"vent":
			if t.phase!="prop_setup" or dark or not own(s,"fluorescentBrush"): return locked()
			consume(s,"fluorescentBrush")
			t.paperDusted=true
			t.phase="spotlight_ready"
			return response(prose("chapter3-theater.content","prop.ventComplete"))
		"exit":
			if t.phase!="complete": return locked()
			return enter(s,"campus_qizhen_loop","c3_location","campus_theater_junction")
	return locked()

func targets(scene: String, s: Dictionary) -> Array:
	if scene=="canteen_interior" and SceneSession.pending_canteen(s): return []
	var list: Array = lake.targets(scene,s)
	if scene=="campus_bootstrap" and s.canteenHunt.active:
		var manifest: Dictionary=world(scene).manifest
		if s.canteenHunt.phase not in ["chasing","theater_reached"]:
			var gate: Dictionary=manifest.canteen.gate
			list.append(target("c3_canteen_gate","东区食堂入口",[gate.x,gate.y],"c3_enter_canteen",gate.radius))
		if s.canteenHunt.phase=="theater_reached":
			var gate: Dictionary=manifest.theater.gate
			list.append(target("c3_theater_gate","剧院入口",[gate.x,gate.y],"c3_enter_theater",gate.radius))
		if s.canteenHunt.phase=="chase_ready": list.append(from_source(get_definition(scene,"bike",s),"c3_target:bike"))
	if scene not in ["canteen_interior","theater_interior"]: return list
	var active: bool = s.canteenHunt.active if scene=="canteen_interior" else s.theaterHunt.active
	if not active: return list
	for entry: Dictionary in definitions(scene,s):
		if scene=="theater_interior":
			var allowed: Array={"entry_ticket":["poster","kiosk","gate","charger"],"program_search":["console","program","charger"],"prop_setup":["prop","scanner","vent","charger"],"spotlight_ready":["console","charger"],"complete":["exit","charger"]}.get(s.theaterHunt.phase,["charger"])
			if entry.kind not in allowed: continue
		if scene=="canteen_interior":
			if not side_active(s.canteenHunt): continue
			if entry.kind=="npc" and (s.native.mode!="light" or s.canteenHunt.phase not in ["tray_search","drink_mix"]): continue
			if entry.kind=="npc" and str(entry.id).begins_with("initial-queue-npc-") and float(entry.x)==float(world(scene).constants.CANTEEN_QUEUE_COLUMN_THREE.x): continue
			if entry.kind=="auntie" and s.native.mode!="light": continue
			if entry.kind=="tray" and (not s.canteenHunt.trayTaskStarted or tray_count(s.canteenHunt)==3): continue
			if entry.kind in ["queue_gap","drink_machine","drink_shelf","mixer","promo"] and (s.native.mode!="light" or s.canteenHunt.promoDrinkPlaced or s.canteenHunt.queueGapOpened): continue
			if entry.kind=="pickup" and s.canteenHunt.phase!="pickup_search": continue
			if entry.kind=="kiosk" and s.canteenHunt.phase!="menu_order" and not (s.canteenHunt.phase=="pickup_search" and s.native.mode=="dark" and not s.canteenHunt.menuDarkClueRead): continue
		if entry.kind=="cart": continue
		if entry.kind=="tray" and (s.canteenHunt.returnedTrayIds.has(entry.id) or s.canteenHunt.carriedTrayIds.has(entry.id)): continue
		var item: String = str(entry.get("acceptedItem",""))
		# Inspection remains reachable in either mode; successful physical effects
		# are validated again by the controller, independent of dark evidence.
		var result: Dictionary = from_source(entry,"c3_target:"+str(entry.id))
		if scene=="canteen_interior" and entry.kind=="pickup" and s.canteenHunt.phase=="pickup_search": item="pickupTicket0755"
		if entry.kind=="console" and s.theaterHunt.phase!="spotlight_ready": item=""
		if not item.is_empty():
			result.item_hint=item
			if s.native.mode=="light": result.item=item
		if entry.kind=="tray":
			result.art="res://assets/native/chapter3/tray_dirty.svg" if s.native.mode=="dark" and entry.id in TRAYS and s.canteenHunt.trayTaskStarted else "res://assets/native/chapter3/tray_clean.svg"
			result.art_size=[28,28]
		if entry.kind=="charger":
			result.art="res://assets/native/chapter3/charging_station.svg"
			result.art_size=[80,84]
			result.art_offset=[0,-2]
		if entry.kind=="program":
			if s.theaterHunt.collectedProgramIds.has(entry.programId): continue
			result.art="res://assets/rpg/theater/generated/icons/item_theater_program_"+str(entry.programId)+".png"
			result.art_size=[34,40]
		list.append(result)
	return list

func objective(s: Dictionary) -> String:
	if s.chapterThreeInterlude.completed or s.chapter4.prologueSeen: return ""
	var more: String = interlude.objective(s)
	if not more.is_empty(): return more
	more=lake.objective(s)
	if not more.is_empty(): return more
	if s.theaterHunt.active and s.theaterHunt.phase!="complete":
		return {"entry_ticket":"进入剧院","program_search":"取得节目单残页，确认节目顺序。","prop_setup":"让纸条留下能够被追光灯识别的痕迹。","spotlight_ready":"把追光灯遥控器接到灯控台。","spotlight_hunt":"控制光完成三幕演出。","reversal":"看清纸条真正的去向。"}.get(s.theaterHunt.phase,"")
	if not s.canteenHunt.active: return ""
	return {"tracking":"追上逃跑的记录纸条","tray_search":"在食堂截住纸条","drink_mix":"在食堂截住纸条","menu_order":"在食堂截住纸条","pickup_search":"核对取餐窗口","exit_blocking":"在食堂截住纸条","chase_ready":"清洁车锁并用餐盘回收费支付骑行","chasing":"骑车追上纸条","theater_reached":"在剧院逼停纸条"}.get(s.canteenHunt.phase,"")

func _audio_event(result: Dictionary, id: String, payload: Dictionary = {}) -> Dictionary:
	result["presentation"] = [{"cueId":id,"payload":payload}]
	return result
