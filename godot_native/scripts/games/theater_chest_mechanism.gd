extends RefCounted
## A mounted chest's temporary puzzle. No member is written to a game save.
const SYMBOLS: Array = ["fan", "butterfly", "lamp"]
const SOLUTION: Array = ["fan", "butterfly", "lamp"]
var token: Dictionary = {}
var owner: Dictionary = {}
var retired: bool = false
var slots: Array = ["", "", ""]
var crank_installed: bool = false
var clue_open: bool = false
var drawer_open: bool = false
var turns: int = 0

func _init(state: Dictionary = {}, serial: int = 0) -> void:
	owner = state
	if state.is_empty():
		retired = true
		return
	token = {"id": serial, "nonce": Crypto.new().generate_random_bytes(16).hex_encode(), "scene": "theater_interior", "phase": str(state.get("theaterHunt", {}).get("phase", "")), "checkpoint": str(state.get("rpgCheckpoint", ""))}

func current(state: Dictionary) -> bool:
	if retired or not is_same(state, owner): return false
	var theater: Dictionary = state.get("theaterHunt", {})
	var native: Dictionary = state.get("native", {})
	return str(state.get("runtimeMode", "")) == "rpg" and str(state.get("rpgScene", "")) == token.scene and str(native.get("scene", "")) == token.scene and str(native.get("mode", theater.get("mode", ""))) == "light" and bool(theater.get("active", false)) and bool(theater.get("admitted", false)) and bool(theater.get("propBoxOpened", false)) and token.phase == "prop_setup" and str(theater.get("phase", "")) == token.phase and str(state.get("rpgCheckpoint", "")) == token.checkpoint

func matches(value: Variant) -> bool:
	return not retired and value is Dictionary and value == token

func invalidate() -> void:
	retired = true
	owner = {}

func cancel(value: Variant) -> bool:
	if not matches(value): return false
	invalidate()
	return true

func snapshot() -> Dictionary:
	var remaining: Array = []
	for symbol: String in SYMBOLS:
		if symbol not in slots: remaining.append(symbol)
	if not crank_installed: remaining.append("crank")
	return {"session": token.duplicate(true), "slots": slots.duplicate(), "remaining": remaining, "crank_installed": crank_installed, "clue_open": clue_open, "clue_order": SOLUTION.duplicate() if clue_open else [], "drawer_open": drawer_open, "turns": turns}

func apply(state: Dictionary, action: String, value: Variant) -> Dictionary:
	if not current(state) or not value is Dictionary or not matches(value.get("session")):
		return {"handled": true, "ephemeral": true, "accepted": false, "message": "这次箱内查看已经结束。"}
	match action:
		"inspect":
			clue_open = not clue_open
			return _result(true)
		"place":
			if drawer_open: return _result(false)
			var piece: String = str(value.get("piece", ""))
			if piece == "crank":
				if not value.get("slot") is String or str(value.get("slot")) != "axle": return _result(false, "转柄要装在轮盘中轴。")
				crank_installed = true
				return _result(true)
			var destination: Variant = value.get("slot")
			if piece not in SYMBOLS or typeof(destination) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(destination)) or float(destination) != floor(float(destination)) or destination < 0 or destination > 2:
				return _result(false)
			var index: int = int(destination)
			var previous: int = slots.find(piece)
			if previous == index: return _result(true)
			if previous >= 0: slots[previous] = slots[index]
			slots[index] = piece
			return _result(true)
		"turn":
			if drawer_open: return _result(false)
			if not crank_installed: return _result(false, "轮盘中轴还缺一枚转柄。")
			var direction: Variant = value.get("direction")
			if typeof(direction) not in [TYPE_INT, TYPE_FLOAT] or direction not in [-1, 1]: return _result(false)
			if direction == 1: slots.push_front(slots.pop_back())
			else: slots.push_back(slots.pop_front())
			turns += 1
			return _result(true)
		"open":
			if drawer_open: return _result(true)
			if not crank_installed or slots != SOLUTION: return _result(false, "夹层还卡着，三枚符号没有对上。")
			drawer_open = true
			return _result(true, "夹层里是一张后台通风口示意图。")
	return _result(false)

func _result(accepted: bool, message: String = "") -> Dictionary:
	return {"handled": true, "ephemeral": true, "accepted": accepted, "message": message, "mechanism": snapshot()}
