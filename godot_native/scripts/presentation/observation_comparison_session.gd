extends RefCounted
## Optional, read-only comparison of information the player has already earned.
## No recipe matching, progression writes, hidden target IDs or save-format fields.
var cards: Array[Dictionary] = []
var selected: Array[String] = ["", ""]
var active_slot := 0
var stage := "selection"

func refresh(state: Dictionary, catalog: Array, documents: Dictionary = {}) -> void:
	cards.clear()
	var chapter := int(state.get("native",{}).get("chapter",1))
	if chapter not in [1,2]:
		_clear_missing_selection()
		return
	var items: Dictionary = state.get("items",{})
	for entry: Dictionary in catalog:
		var id := str(entry.get("id",""))
		if id.is_empty() or not items.get(id,false): continue
		var body := str(entry.get("desc",""))
		var document: Dictionary = documents.get(id,{}).get("document",{})
		if not document.is_empty():
			body = str(document.get("heading",entry.get("name",id)))
			for field: Dictionary in document.get("fields",[]): body += "\n"+str(field.get("label",""))+"："+str(field.get("value",""))
			for paragraph: String in document.get("body",[]): body += "\n"+paragraph
			if not str(document.get("footer","")).is_empty(): body += "\n"+str(document.footer)
		_add("item:"+id,str(entry.get("name",id)),"持有的道具",body,"items.config.json / item_catalog.json")
	var f: Dictionary = state.get("flags",{})
	var digits: Dictionary = state.get("digits",{})
	for clue: Array in [["cardZeroTaken","d1","0","缺勤记录","本周缺勤 0 次。"],["tiyiCountTaken","d2","7","锻炼次数","课外锻炼 47；取下的数字是 7。"],["gearNineTaken","d3","9","齿轮背面","齿轮背面刻着 9。"],["flowerEightTaken","d4","8","花心数字","从花心取下的数字是 8。"]]:
		if f.get(clue[0],false) and str(digits.get(clue[1],"")) == clue[2]: _add("observation:"+clue[0],clue[3],"已记下的线索",clue[4],"chapter1_2.gd / earned digit")
	for clue: Array in [["plantWatered","盆栽 · 水","盆栽已经浇过水。"],["plantLit","盆栽 · 光","盆栽的光照条件已经满足。"],["plantFertilized","盆栽 · 肥","盆栽已经施过肥。"]]:
		if f.get(clue[0],false): _add("observation:"+clue[0],clue[1],"已发生的变化",clue[2],"chapter1_2.gd / bonsai condition")
	var a: Dictionary = state.get("actOne",{})
	if a.get("cc98Login",{}).get("studentIdDiscovered",false) and a.get("inventoryRecovered",false):
		_add("observation:card_identity","校园卡身份","已核对的卡面","林星宇\n学号 3250100755","chapter1_2.gd / c2_card_identity")
	if a.get("balanceShifted",false):
		_add("observation:balance_shift","小数点移动","已发生的变化","校园卡余额的小数点向右移动了两位：0.06 → 6.00。","chapter1_2.gd / c2_balance")
	var library: Dictionary = state.get("ui",{}).get("libraryFinalsPuzzle",{})
	if library.get("entranceRecordRead",false):
		_add("observation:library_record","入馆记录","已读取的记录","07:55：进入基础馆\n08:02：到达一层书库 022\n一层书库 022：存在未闭合会话\n最后活动：未知","library022.gd / library_record")
	if library.get("backpackInspected",false) and library.get("photoCaptured",false) and library.get("photoDimmed",false):
		_add("observation:bag_label","书包标签","已看清的照片","高数教材 x1\n水杯 x1　充电器 x1\n半包纸 x1\n姓名：未检测到\n学号：未检测到\n人格：加载失败","PhotoEvidenceOverlay.tsx / earned readable label")
	# Submitted paper remains available only after its corresponding earned fact.
	for proof: Array in [["archivedRuleRead","archivedLeaveRule"],["nonPersonProofStamped","bagNonPersonProof"],["seatReceiptCollected","seat022Receipt"],["presenceProofCollected","libraryPresenceProof"]]:
		if not library.get(proof[0],false) or items.get(proof[1],false): continue
		var record: Dictionary = documents.get(proof[1],{}).get("document",{})
		if record.is_empty(): continue
		var text := str(record.get("heading",""))
		for field: Dictionary in record.get("fields",[]): text += "\n"+str(field.get("label",""))+"："+str(field.get("value",""))
		for paragraph: String in record.get("body",[]): text += "\n"+paragraph
		if not str(record.get("footer","")).is_empty(): text += "\n"+str(record.footer)
		_add("archive:"+str(proof[1]),str(record.get("heading",proof[1])),"已取得的材料",text,"item_catalog.json / earned library proof")
	_clear_missing_selection()

func _add(id: String, title: String, kind: String, body: String, provenance: String) -> void:
	cards.append({"id":id,"title":title,"kind":kind,"body":body,"provenance":provenance})

func card(id: String) -> Dictionary:
	for entry: Dictionary in cards:
		if entry.id == id: return entry.duplicate(true)
	return {}

func available() -> bool: return cards.size() >= 2

func select_slot(index: int) -> bool:
	if index not in [0,1]: return false
	active_slot = index
	stage = "selection"
	return true

func choose(id: String) -> bool:
	if card(id).is_empty() or selected[1-active_slot] == id: return false
	selected[active_slot] = id
	if selected[1-active_slot].is_empty(): active_slot = 1-active_slot
	return true

func can_compare() -> bool:
	return not selected[0].is_empty() and not selected[1].is_empty() and selected[0] != selected[1] and not card(selected[0]).is_empty() and not card(selected[1]).is_empty()

func compare() -> bool:
	if not can_compare(): return false
	stage = "comparison"
	return true

func swap() -> bool:
	if not can_compare(): return false
	var first := selected[0]
	selected[0] = selected[1]
	selected[1] = first
	return true

func clear() -> void:
	selected = ["", ""]
	active_slot = 0
	stage = "selection"

func _clear_missing_selection() -> void:
	for i in range(2):
		if card(selected[i]).is_empty(): selected[i] = ""
	if not can_compare(): stage = "selection"
