extends RefCounted
## Deterministic, runtime-only transport exercise. This model never writes game state.
## Completion proofs replay actual moves against the same immutable authored layouts.
const DATA_PATH := "res://data/native/progressive-transport-levels.json"
const MAX_ACTIONS := 4096
const DIRECTIONS := {"up": Vector2i.UP, "down": Vector2i.DOWN, "left": Vector2i.LEFT, "right": Vector2i.RIGHT}
static var _catalog_cache: Dictionary = {}
var _id: String
var _definition: Dictionary = {}
var _stage_index := 0
var _state: Dictionary = {}
var _history: Array[Dictionary] = []
var _actions: Array[String] = []
var _feedback: Dictionary = {"kind": "observe", "text": "观察通道、物件和出口，再决定第一步。"}

static func _catalog() -> Dictionary:
	if _catalog_cache.is_empty():
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
		if parsed is Dictionary:
			_catalog_cache = parsed.get("puzzles", {}).duplicate(true)
	return _catalog_cache

static func layout_digest(puzzle_id: String) -> String:
	var definition: Dictionary = _catalog().get(puzzle_id, {})
	if definition.is_empty(): return ""
	return JSON.stringify(definition).sha256_text()

func _init(puzzle_id: String = "") -> void:
	_id = puzzle_id
	_definition = _catalog().get(_id, {}).duplicate(true)
	if not _definition.is_empty(): _state = _initial_state()

func _stage() -> Dictionary:
	if _definition.is_empty(): return {}
	return _definition.stages[_stage_index]

func _initial_state() -> Dictionary:
	return {"actor": _stage().actor.duplicate(true), "objects": _stage().objects.duplicate(true), "visited": []}

func _contains(rect: Dictionary, x: int, y: int) -> bool:
	return x >= int(rect.x) and x < int(rect.x) + int(rect.get("width", 1)) and y >= int(rect.y) and y < int(rect.y) + int(rect.get("height", 1))

func _object_at(state: Dictionary, x: int, y: int, ignore: int = -1) -> int:
	for i: int in range(state.objects.size()):
		if i != ignore and _contains(state.objects[i], x, y): return i
	return -1

func _plate_active(state: Dictionary, plate_id: String) -> bool:
	for plate: Dictionary in _stage().plates:
		if str(plate.id) == plate_id:
			return (int(state.actor.x) == int(plate.x) and int(state.actor.y) == int(plate.y)) or _object_at(state, int(plate.x), int(plate.y)) >= 0
	return false

func _gate_open(state: Dictionary, gate: Dictionary) -> bool:
	for requirement: String in gate.get("requires", []):
		if not _plate_active(state, requirement): return false
	return true

func _target_active(state: Dictionary, target_id: String) -> bool:
	for target: Dictionary in _stage().targets:
		if str(target.id) != target_id: continue
		for object: Dictionary in state.objects:
			if object.id == target.objectId:
				return int(object.x) == int(target.x) and int(object.y) == int(target.y)
	return false

func _targets_active(state: Dictionary, ids: Array) -> bool:
	for id: String in ids:
		if not _target_active(state, id): return false
	return true

func _connections(state: Dictionary) -> Dictionary:
	var result := {}
	for connection: Dictionary in _stage().get("connections", []):
		var contact: Dictionary = connection.contact
		result[connection.id] = "on" if _object_at(state, int(contact.x), int(contact.y)) >= 0 else "off"
	return result

func _connection_details(state: Dictionary) -> Array:
	var details: Array = []
	var contacts: Array[String] = []
	var active := _connections(state)
	for source: Dictionary in _stage().get("connections", []):
		var contact: Dictionary = source.contact.duplicate(true)
		var contact_id := "%d_%d" % [int(contact.x), int(contact.y)]
		if not contacts.has(contact_id): contacts.append(contact_id)
		contact.label = "接点 " + String.chr(65 + contacts.find(contact_id))
		contact.active = active[source.id] == "on"
		var ends: PackedStringArray = str(source.id).split("__")
		details.append({"id": source.id, "from": ends[0], "to": ends[1], "contactId": contact_id,
			"contact": contact, "active": contact.active})
	return details

func _circuit_zones() -> Array:
	var labels := {"hall": "大厅", "west_corridor": "西走廊", "east_corridor": "东走廊", "bakery_back_area": "后场", "classroom_zone": "教室区"}
	var result: Array = []
	for id: String in _stage().get("circuitZones", []):
		result.append({"id": id, "label": labels.get(id, id)})
	return result

func _local_goal(state: Dictionary) -> bool:
	if not _targets_active(state, _stage().get("goalTargets", [])): return false
	for id: String in _stage().get("requiredCheckpoints", []):
		if not state.visited.has(id): return false
	if _stage().get("orderedCheckpoints", false):
		if state.visited != _stage().get("requiredCheckpoints", []): return false
	if _stage().has("connections"):
		var actual := _connections(state)
		for id: String in actual:
			var expected: String = "on" if _stage().expectedConnections.has(id) else "off"
			if actual[id] != expected: return false
	return true

func _stage_complete() -> bool:
	if _state.is_empty(): return false
	return _local_goal(_state) and int(_state.actor.x) == int(_stage().exit.x) and int(_state.actor.y) == int(_stage().exit.y)

func _complete() -> bool:
	return not _definition.is_empty() and _stage_index == _definition.stages.size() - 1 and _stage_complete()

func _cell_open(state: Dictionary, x: int, y: int, terrain: String, ignore: int = -1) -> bool:
	var rows: Array = _stage().rows
	if y < 0 or y >= rows.size() or x < 0 or x >= str(rows[y]).length(): return false
	var expected := "~" if terrain == "water" else "."
	if str(rows[y]).substr(x, 1) != expected: return false
	if _object_at(state, x, y, ignore) >= 0: return false
	for gate: Dictionary in _stage().gates:
		if _contains(gate, x, y) and not _gate_open(state, gate): return false
	return true

func _closing_gate_clear(state: Dictionary) -> bool:
	for gate: Dictionary in _stage().gates:
		if _gate_open(state, gate): continue
		if _contains(gate, int(state.actor.x), int(state.actor.y)): return false
		for object: Dictionary in state.objects:
			for y: int in range(int(object.y), int(object.y) + int(object.get("height", 1))):
				for x: int in range(int(object.x), int(object.x) + int(object.get("width", 1))):
					if _contains(gate, x, y): return false
	return true

func _visit_checkpoints(state: Dictionary) -> void:
	for checkpoint: Dictionary in _stage().checkpoints:
		if int(state.actor.x) != int(checkpoint.x) or int(state.actor.y) != int(checkpoint.y): continue
		if state.visited.has(checkpoint.id): continue
		if not _targets_active(state, checkpoint.get("requiresTargets", [])):
			_feedback = {"kind": "observe", "text": "记录点还在等待工具或回程条件就位。", "cell": {"x": checkpoint.x, "y": checkpoint.y}}
			continue
		if _stage().get("orderedCheckpoints", false):
			var order: Array = _stage().requiredCheckpoints
			if state.visited.size() >= order.size() or checkpoint.id != order[state.visited.size()]:
				_feedback = {"kind": "observe", "text": "这里还不是下一处路线记录，请沿现场路线继续核对。", "cell": {"x": checkpoint.x, "y": checkpoint.y}}
				continue
		state.visited.append(checkpoint.id)
		_feedback = {"kind": "record", "text": "已记录：" + str(checkpoint.label), "cell": {"x": checkpoint.x, "y": checkpoint.y}}

func _result(accepted: bool) -> Dictionary:
	var result := snapshot()
	result.accepted = accepted
	return result

func _reject(text: String, cell: Dictionary = {}) -> Dictionary:
	_feedback = {"kind": "blocked", "text": text}
	if not cell.is_empty(): _feedback.cell = cell
	return _result(false)

func apply(action: String) -> Dictionary:
	if _definition.is_empty(): return _reject("练习不存在。")
	if _actions.size() >= MAX_ACTIONS: return _reject("本轮记录已满，请返回现场重新开始练习。")
	if action == "undo":
		if _history.is_empty(): return _reject("当前一拍没有可撤回的动作。")
		_state = _history.pop_back()
		_actions.append(action)
		_feedback = {"kind": "undo", "text": "已撤回；之前完成的练习保持不变。"}
		return _result(true)
	if action == "restart":
		_history.append(_state.duplicate(true))
		_state = _initial_state()
		_actions.append(action)
		_feedback = {"kind": "restart", "text": "当前一拍已重来；这次重来也可以撤回。"}
		return _result(true)
	if action == "continue":
		if not _stage_complete() or _complete(): return _reject("请先让工具就位，并亲自抵达出口。")
		_stage_index += 1
		_state = _initial_state()
		_history.clear()
		_actions.append(action)
		_feedback = {"kind": "observe", "text": "规则保持不变，先观察这一次改变了什么。"}
		return _result(true)
	if not DIRECTIONS.has(action): return _reject("不支持的动作。")
	if _stage_complete(): return _reject("这一拍已完成；可以继续，或撤回再观察。")
	var delta: Vector2i = DIRECTIONS[action]
	var x: int = int(_state.actor.x) + delta.x
	var y: int = int(_state.actor.y) + delta.y
	var candidate: Dictionary = _state.duplicate(true)
	var hit := _object_at(_state, x, y)
	if hit >= 0:
		var object: Dictionary = candidate.objects[hit]
		for yy: int in range(int(object.y) + delta.y, int(object.y) + delta.y + int(object.get("height", 1))):
			for xx: int in range(int(object.x) + delta.x, int(object.x) + delta.x + int(object.get("width", 1))):
				if not _cell_open(_state, xx, yy, str(object.get("terrain", "land")), hit):
					return _reject("这一侧推不动：查看整个物件的宽度、障碍和身后的站位。", {"x": x, "y": y})
		object.x = int(object.x) + delta.x
		object.y = int(object.y) + delta.y
	elif not _cell_open(_state, x, y, "water" if _state.actor.kind == "boat" else "land"):
		return _reject("这里不能通过；观察仍然开放的通道。", {"x": x, "y": y})
	candidate.actor.x = x
	candidate.actor.y = y
	if not _closing_gate_clear(candidate): return _reject("不能让通道在人员或工具身上关闭。", {"x": x, "y": y})
	_history.append(_state.duplicate(true))
	_feedback = {"kind": "move", "text": "物件和通道只随实际行动改变。"}
	_visit_checkpoints(candidate)
	_state = candidate
	_actions.append(action)
	if _stage_complete():
		_feedback = {"kind": "complete", "text": "工具与路线均已确认，你也已抵达出口。"}
	elif _local_goal(_state):
		_feedback = {"kind": "ready", "text": "现场条件已满足；请亲自抵达出口。", "cell": _stage().exit.duplicate(true)}
	return _result(true)

func snapshot() -> Dictionary:
	if _definition.is_empty(): return {"valid": false, "puzzleId": _id, "complete": false, "completed": false, "feedback": _feedback.duplicate(true)}
	var stage: Dictionary = _stage()
	var plates: Array = []
	for source: Dictionary in stage.plates:
		var plate: Dictionary = source.duplicate(true)
		plate.active = _plate_active(_state, str(plate.id))
		plates.append(plate)
	var gates: Array = []
	for source: Dictionary in stage.gates:
		var gate: Dictionary = source.duplicate(true)
		gate.open = _gate_open(_state, gate)
		gates.append(gate)
	var targets: Array = []
	for source: Dictionary in stage.targets:
		var target: Dictionary = source.duplicate(true)
		target.active = _target_active(_state, str(target.id))
		target.required = stage.goalTargets.has(target.id)
		for object: Dictionary in _state.objects:
			if object.id == target.objectId:
				target.width = int(object.get("width", 1))
				target.height = int(object.get("height", 1))
		targets.append(target)
	var checkpoints: Array = []
	for source: Dictionary in stage.checkpoints:
		var checkpoint: Dictionary = source.duplicate(true)
		checkpoint.visited = _state.visited.has(checkpoint.id)
		checkpoints.append(checkpoint)
	var goal := _local_goal(_state)
	var exit: Dictionary = stage.exit.duplicate(true)
	exit.open = goal
	var board := {"width": str(stage.rows[0]).length(), "height": stage.rows.size(), "tiles": stage.rows.duplicate(true)}
	return {"valid": true, "puzzleId": _id, "title": _definition.title, "context": stage.get("context", ""),
		"stageIndex": _stage_index, "stageCount": _definition.stages.size(), "totalStages": _definition.stages.size(),
		"stageTitle": stage.title, "objective": stage.objective, "teachingGoal": stage.teachingGoal,
		"width": board.width, "height": board.height, "tiles": board.tiles.duplicate(true), "board": board,
		"actor": _state.actor.duplicate(true), "player": _state.actor.duplicate(true),
		"objects": _state.objects.duplicate(true), "tools": _state.objects.duplicate(true),
		"plates": plates, "gates": gates, "targets": targets, "checkpoints": checkpoints, "exit": exit,
		"localGoal": goal, "goalMet": goal, "exitReady": goal, "stageComplete": _stage_complete(),
		"complete": _complete(), "completed": _complete(), "feedback": _feedback.duplicate(true),
		"hints": stage.hints.duplicate(true), "canUndo": not _history.is_empty(), "actionsCount": _actions.size(),
		"connections": _connections(_state), "connectionDetails": _connection_details(_state), "circuitZones": _circuit_zones(), "checkpointOrder": _state.visited.duplicate(true), "localOnly": _definition.get("localOnly", false)}

func proof() -> Dictionary:
	return {"puzzleId": _id, "layoutDigest": layout_digest(_id), "actions": _actions.duplicate()}

func _controller_value() -> Dictionary:
	if not _complete(): return {}
	if _id == "power_topology": return _connections(_state)
	if _id == "evacuation_route":
		var result := {}
		for i: int in range(_state.visited.size()): result[String.chr(97 + i)] = _state.visited[i]
		return result
	return {}

static func replay(puzzle_id: String, actions: Variant) -> Dictionary:
	if not _catalog().has(puzzle_id) or not actions is Array or actions.size() > MAX_ACTIONS:
		return {"valid": false, "completed": false, "controllerValue": {}, "reason": "invalid_trace"}
	var model = (load("res://scripts/games/progressive_transport_model.gd") as GDScript).new(puzzle_id)
	for action: Variant in actions:
		if not action is String:
			return {"valid": false, "completed": false, "controllerValue": {}, "reason": "invalid_action_type"}
		var result: Dictionary = model.apply(action)
		if not result.accepted:
			return {"valid": false, "completed": false, "controllerValue": {}, "reason": "illegal_action"}
	return {"valid": true, "completed": model._complete(), "controllerValue": model._controller_value(), "snapshot": model.snapshot()}
