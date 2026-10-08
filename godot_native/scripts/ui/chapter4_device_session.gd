extends RefCounted
## An ephemeral source-panel draft. Never writes progression or a save.
const SOURCE_PATH := "res://data/native/chapter4-device-source.json"
var source: Dictionary = {}
var puzzle_id := ""
var definition: Dictionary = {}
var mode := "light"
var completed := false
var prerequisite_ready := false
var pending := false
var feedback := ""
var draft: Dictionary = {}
var opened := false
var serial := 0
var pending_serial := 0

func _init() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SOURCE_PATH))
	if parsed is Dictionary: source = parsed

func open(id: String, state: Dictionary) -> bool:
	if not source.get("definitions",{}).has(id): return false
	var chapter: Dictionary = state.get("chapter4",{})
	if chapter.get("phase","") != "room204_restore" or chapter.get("floor","") != source.assets[id].floor or state.get("native",{}).get("c4_context","") != id: return false
	puzzle_id = id
	definition = source.definitions[id].duplicate(true)
	mode = str(chapter.get("mode","light"))
	completed = definition.factId in chapter.get("factIds",[])
	prerequisite_ready = _prerequisite(state)
	pending = false
	pending_serial = 0
	feedback = ""
	draft = source.defaults.duplicate(true)
	opened = true
	return true

func close() -> bool:
	if pending: return false
	opened = false
	draft = {}
	feedback = ""
	return true

func compatible(state: Dictionary) -> bool:
	var chapter: Dictionary = state.get("chapter4",{})
	return opened and chapter.get("phase","") == "room204_restore" and chapter.get("floor","") == source.assets[puzzle_id].floor and chapter.get("mode","") == mode and state.get("native",{}).get("c4_context","") == puzzle_id

func operation_locked() -> bool:
	return puzzle_id in ["media_alignment","positioning_calibration"] and not prerequisite_ready

func editable() -> bool:
	return opened and not pending and not completed and mode == "light" and not operation_locked()

func view_kind() -> String:
	if completed: return "completed"
	if operation_locked(): return "locked"
	if mode == "dark": return "observation"
	return "controls"

func order_key() -> String:
	return "dutyOrder" if puzzle_id == "duty_board" else "evacuationOrder"

func move_card(index: int, delta: int) -> bool:
	if not editable() or puzzle_id not in ["duty_board","evacuation_route"] or abs(delta) != 1: return false
	var order: Array = draft[order_key()]
	var next := index + delta
	if index < 0 or index >= order.size() or next < 0 or next >= order.size(): return false
	var old: Variant = order[index]
	order[index] = order[next]
	order[next] = old
	return true

func choose(key: String, value: String) -> bool:
	if not editable() or puzzle_id != "archive_index" or not source.options.has(key): return false
	var valid := false
	for option: Dictionary in source.options[key]:
		if option.value == value: valid = true
	if not valid: return false
	draft[{"yearBand":"archiveYearBand","floor":"archiveFloor","purpose":"archivePurpose"}[key]] = value
	return true

func axis_key() -> String:
	return "mediaAlignment" if puzzle_id == "media_alignment" else "calibration"

func step_axis(key: String, delta: int) -> bool:
	if not editable() or not source.ranges.has(puzzle_id) or not source.ranges[puzzle_id].has(key) or abs(delta) != 1: return false
	var limits: Array = source.ranges[puzzle_id][key]
	var next := int(draft[axis_key()][key]) + delta
	if next < limits[0] or next > limits[1]: return false
	draft[axis_key()][key] = next
	return true

func toggle_edge(id: String) -> bool:
	if not editable() or puzzle_id != "power_topology" or not source.edges.has(id): return false
	var edges: Array = draft.powerEdges
	if id in edges: edges.erase(id)
	elif edges.size() < 5: edges.append(id)
	else: return false
	return true

func answer() -> Dictionary:
	var result := {"puzzleId":puzzle_id}
	match puzzle_id:
		"duty_board", "evacuation_route": result.order = draft[order_key()].duplicate()
		"archive_index":
			if draft.archiveYearBand.is_empty() or draft.archiveFloor.is_empty() or draft.archivePurpose.is_empty(): return {}
			result.merge({"yearBand":draft.archiveYearBand,"floor":draft.archiveFloor,"purpose":draft.archivePurpose})
		"media_alignment", "positioning_calibration": result.merge(draft[axis_key()])
		"power_topology":
			if draft.powerEdges.size() != 5: return {}
			result.edgeIds = draft.powerEdges.duplicate()
	return result

func can_submit() -> bool:
	return editable() and not answer().is_empty()

func controller_value(value: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	match puzzle_id:
		"duty_board", "evacuation_route":
			for index in range(value.order.size()): result[["a","b","c","d"][index]] = value.order[index]
		"power_topology":
			for edge: String in source.edges: result[edge] = "on" if edge in value.edgeIds else "off"
		_:
			result = value.duplicate(true)
			result.erase("puzzleId")
	return result

func begin_submit() -> Dictionary:
	if not can_submit(): return {}
	var value := controller_value(answer())
	pending = true
	feedback = ""
	serial += 1
	pending_serial = serial
	return {"action":"c4_solve_"+puzzle_id,"value":value,"serial":pending_serial}

func resolve(request_serial: int, state: Dictionary, result: Dictionary) -> bool:
	if not opened or not pending or request_serial != pending_serial: return false
	pending = false
	pending_serial = 0
	# The controller uses handled/message for both failure and success. Only
	# its persisted fact proves acceptance. No prose or local answer inference.
	completed = definition.factId in state.get("chapter4",{}).get("factIds",[])
	feedback = "" if completed else str(result.get("message","当前组合与现场痕迹不一致，可以继续调整。"))
	if not completed and feedback.is_empty(): feedback = "当前组合与现场痕迹不一致，可以继续调整。"
	return true

func update_authority(state: Dictionary) -> void:
	if not opened: return
	var facts: Array = state.get("chapter4",{}).get("factIds",[])
	completed = definition.factId in facts
	prerequisite_ready = _prerequisite(state)

func _prerequisite(state: Dictionary) -> bool:
	if puzzle_id == "positioning_calibration": return bool(state.get("items",{}).get("clockPositioningPlate",false)) and "positioning_plate_collected" in state.get("chapter4",{}).get("factIds",[])
	return "a3_archive_film_retrieved" in state.get("chapter4",{}).get("factIds",[])
