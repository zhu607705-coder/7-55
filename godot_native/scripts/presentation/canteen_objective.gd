extends RefCounted
## Read-only early canteen guidance from existing controller facts.
## Later phases keep their authored objectives; no new save or progression state.
static func current(s: Dictionary) -> Dictionary:
	var hunt: Dictionary=s.get("canteenHunt",{})
	if not hunt.get("active",false): return {}
	if s.get("chapterThreeInterlude",{}).get("completed",false) or s.get("chapter4",{}).get("prologueSeen",false): return {}
	if s.get("qizhenLake",{}).get("active",false) or s.get("theaterHunt",{}).get("active",false): return {}
	var phase:=str(hunt.get("phase",""))
	if phase=="tracking":
		return {"id":"tracking","title":"追上逃跑的记录纸条","detail":"纸条钻进了食堂。前往东区食堂，继续追踪。"}
	if phase not in ["tray_search","drink_mix"]: return {}
	if not hunt.get("entryPaperEscaped",false):
		return {"id":"paper_entry","title":"靠近食堂里的异常纸条","detail":"纸条停在入口附近。靠近它，继续追踪。"}
	var dark: bool=s.get("native",{}).get("mode","light")=="dark"
	if not hunt.get("trayTaskStarted",false):
		return {"id":"tray_start","title":"与收餐口阿姨交谈","detail":"切回浅色操作，再到右侧收餐口与阿姨交谈。" if dark else "到右侧收餐口，与阿姨交谈。"}
	var returned:=0
	for id: String in ["tray_blue_01","tray_blue_02","tray_blue_03"]:
		if hunt.get("returnedTrayIds",[]).has(id): returned+=1
	if returned>=3: return {}
	if not hunt.get("carriedTrayIds",[]).is_empty():
		return {"id":"tray_carry","title":"交回手中的餐盘（%d/3）"%returned,"detail":"一次只能搬一个餐盘。切回浅色操作，把它交给右侧收餐口阿姨。" if dark else "一次只能搬一个餐盘。把它交给右侧收餐口阿姨，再找下一只。"}
	return {"id":"tray_return","title":"找出并交回带污渍的餐盘（%d/3）"%returned,"detail":"阿姨托你送回三只脏盘。深色观察辨认污渍，浅色操作拿起餐盘；每次搬一个。"}
