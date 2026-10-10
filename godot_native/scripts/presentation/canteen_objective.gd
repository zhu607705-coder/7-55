extends RefCounted
## Read-only canteen guidance from existing controller facts and QuestModel.
## Includes existing menu, pickup and bike handoffs; no new save or progression state.
static func current(s: Dictionary) -> Dictionary:
	var hunt: Dictionary=s.get("canteenHunt",{})
	if not hunt.get("active",false): return {}
	if s.get("chapterThreeInterlude",{}).get("completed",false) or s.get("chapter4",{}).get("prologueSeen",false): return {}
	if s.get("qizhenLake",{}).get("active",false) or s.get("theaterHunt",{}).get("active",false): return {}
	var phase:=str(hunt.get("phase",""))
	if phase=="tracking":
		return {"id":"tracking","title":"追上逃跑的记录纸条","detail":"纸条钻进了食堂。前往东区食堂，继续追踪。"}
	if phase=="chase_ready": return bike_handoff(s,hunt)
	if phase not in ["tray_search","drink_mix","menu_order","pickup_search"]: return {}
	if not hunt.get("entryPaperEscaped",false):
		return {"id":"paper_entry","title":"靠近食堂里的异常纸条","detail":"纸条停在入口附近。靠近它，继续追踪。"}
	var dark: bool=s.get("native",{}).get("mode","light")=="dark"
	if not hunt.get("trayTaskStarted",false):
		return {"id":"tray_start","title":"与收餐口阿姨交谈","detail":"切回浅色操作，再到右侧收餐口与阿姨交谈。" if dark else "到右侧收餐口，与阿姨交谈。"}
	var returned:=0
	for id: String in ["tray_blue_01","tray_blue_02","tray_blue_03"]:
		if hunt.get("returnedTrayIds",[]).has(id): returned+=1
	if returned>=3: return drink_handoff(s,hunt,dark)
	if not hunt.get("carriedTrayIds",[]).is_empty():
		return {"id":"tray_carry","title":"交回手中的餐盘（%d/3）"%returned,"detail":"一次只能搬一个餐盘。切回浅色操作，把它交给右侧收餐口阿姨。" if dark else "一次只能搬一个餐盘。把它交给右侧收餐口阿姨，再找下一只。"}
	return {"id":"tray_return","title":"找出并交回带污渍的餐盘（%d/3）"%returned,"detail":"阿姨托你送回三只脏盘。深色观察辨认污渍，浅色操作拿起餐盘；每次搬一个。"}

static func bike_handoff(s: Dictionary, hunt: Dictionary) -> Dictionary:
	# The source keeps chase_ready while cleaning and paying. These existing
	# facts change the next instruction, never the controller's ride gate.
	if hunt.get("bikePaid",false):
		return {"id":"bike_ride","title":"骑车追上纸条","detail":"车锁已开。回到共享单车，选择“开始骑行”。"}
	var light: String="切回浅色操作。" if s.get("native",{}).get("mode","light")=="dark" else ""
	if hunt.get("bikeLockCleaned",false):
		return {"id":"bike_pay","title":"用餐盘回收费支付骑行","detail":light+"餐盘回收费已到账。用 2.00 元支付一次骑行。"}
	return {"id":"bike_clean","title":"清洁车锁并用餐盘回收费支付骑行","detail":light+"在车锁旁清除反光并付款。"}

static func drink_handoff(s: Dictionary, hunt: Dictionary, dark: bool) -> Dictionary:
	# Preserve src/core/QuestModel.ts canteenInteriorTask's branch order.
	# This is guidance only: the original controller still allows exploration
	# and mixing out of order, and owns every ingredient and queue transition.
	if hunt.get("queueGapOpened",false):
		if hunt.get("phase","")=="menu_order":
			return {"id":"menu_order","title":"看看菜单里有什么异常","detail":"两种模式下，菜单有几个字不一样。\n深色观察看字，浅色操作下单。"}
		if hunt.get("phase","")=="pickup_search":
			return {"id":"pickup","title":"找到这张小票对应的窗口","detail":"同一个号码，各窗口叫出的餐品未必相同。\n深色观察能听见残留的叫号；交票要用浅色操作。"}
		return {}
	var light: String="切回浅色操作。" if dark else ""
	if not hunt.get("queueChallengeSeen",false):
		return {"id":"queue","title":"查看第三列队伍和新品宣传板","detail":light+"继续追查食堂里的纸条。到第三列队伍前，与排队同学交谈，看看新品宣传板。"}
	if not hunt.get("drinkShelfRead",false):
		return {"id":"drink_shelf","title":"查看饮料货架的颜色顺序","detail":light+"排队同学说，前面的人要先看新品。到饮料货架查看颜色顺序。"}
	if not s.get("items",{}).get("dailySpecialSparklingWater",false) and not hunt.get("promoDrinkPlaced",false):
		return {"id":"drink_mix","title":"按货架顺序调配今日新品（%d/3）"%hunt.get("drinkMixSequence",[]).size(),"detail":light+"前面的队伍在等新品。饮料机提供原料；到调配台，按已查看的货架顺序倒入。"}
	if not hunt.get("promoDrinkPlaced",false):
		# Original prose says window 3; the authored target label says window 5.
		# Name the visible board and cup slot without a contradictory number.
		return {"id":"promo_drop","title":"把今日新品气泡水放入宣传板空杯位","detail":light+"新品已调好。把它放到新品宣传板下方的空杯位，再继续追查纸条。"}
	return {"id":"queue_shift","title":"等待第三列队伍让出位置","detail":"新品已放进宣传板。等队伍移动后，继续追查纸条。"}
