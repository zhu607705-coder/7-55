extends SceneTree
const Session = preload("res://scripts/ui/chapter4_device_session.gd")
const Preview = preload("res://scripts/ui/chapter4_device_preview.gd")
const DevicePanel = preload("res://scripts/ui/chapter4_device_panel.gd")
const Chapter = preload("res://scripts/chapters/chapter4.gd")
var checks := 0
var failures := 0
var fixture: Dictionary
var source: Dictionary
var font: Font

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func initial(id: String, mode: String = "light", film: bool = true) -> Dictionary:
	var state: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/initial_state.json"))
	state.native = {"chapter":4,"mode":mode,"page":"c4_device","scene":"duan_yongping_temporal_maze","c4_context":id}
	state.chapter4.prologueSeen = true
	state.chapter4.phase = "room204_restore"
	state.chapter4.timeState = "1850_evening"
	state.chapter4.floor = source.assets[id].floor
	state.chapter4.mode = mode
	state.chapter4.factIds = ["a3_archive_film_retrieved"] if film and id == "media_alignment" else []
	return state

func configure_answer(session: RefCounted, answer: Dictionary) -> void:
	match session.puzzle_id:
		"duty_board", "evacuation_route":
			for target in range(answer.order.size()):
				var index: int = session.draft[session.order_key()].find(answer.order[target])
				while index > target:
					check(session.move_card(index,-1),"Move unique card")
					index -= 1
		"archive_index":
			for key: String in ["yearBand","floor","purpose"]: check(session.choose(key,answer[key]),"Choose bounded source option")
		"media_alignment", "positioning_calibration":
			for key: String in source.ranges[session.puzzle_id]:
				while int(session.draft[session.axis_key()][key]) != int(answer[key]):
					check(session.step_axis(key,1 if int(session.draft[session.axis_key()][key]) < int(answer[key]) else -1),"Bounded axis adjustment")
		"power_topology":
			for edge: String in session.draft.powerEdges.duplicate(): session.toggle_edge(edge)
			for edge: String in answer.edgeIds: check(session.toggle_edge(edge),"Select bounded topology edge")

# The shared source device panel still has compatibility coverage. Its numeric
# submission cannot skip the production studio's controller-owned physical steps.
func earn_media_studio_layout(state: Dictionary, controller: RefCounted) -> void:
	if state.native.c4_context != "media_alignment": return
	for event: Dictionary in [
		{"kind":"swap","a":0,"b":2}, {"kind":"swap","a":1,"b":2},
		{"kind":"step","axis":"xOffset","delta":1}, {"kind":"step","axis":"xOffset","delta":1},
		{"kind":"step","axis":"yOffset","delta":-1}, {"kind":"step","axis":"rotationQuarterTurns","delta":1}]:
		controller.dispatch(state,"c4_media_studio_event",event)
	check(load("res://scripts/objects/room302_studio_model.gd").ready_to_record(state.native.get("c4_media_studio",{})),"Media compatibility submission follows legal hat and curtain actions")
	check(not "a3_media_alignment_completed" in state.chapter4.factIds,"Physical preparation alone does not record the completion fact")

func submit(session: RefCounted, state: Dictionary, controller: RefCounted) -> Dictionary:
	var request: Dictionary = session.begin_submit()
	check(not request.is_empty(),session.puzzle_id+" submit generated controller action")
	check(session.begin_submit().is_empty(),session.puzzle_id+" duplicate pending submit ignored")
	check(not session.close(),session.puzzle_id+" pending close ignored")
	check(not session.resolve(request.serial+1,state,{"handled":true}),session.puzzle_id+" stale request ignored")
	var result: Dictionary = controller.dispatch(state,request.action,request.value)
	check(session.resolve(request.serial,state,result),session.puzzle_id+" genuine request resolved")
	return result

func _initialize() -> void: call_deferred("run")
func run() -> void:
	fixture = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/chapter4-device-oracle.json"))
	source = JSON.parse_string(FileAccess.get_file_as_string(Session.SOURCE_PATH))
	font = load("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf")
	for entry: Dictionary in fixture.cases: test_model(entry)
	test_bounds()
	test_authority_gates()
	for dimensions: Vector2i in [Vector2i(390,844),Vector2i(430,860),Vector2i(1280,720),Vector2i(1440,900)]:
		for entry: Dictionary in fixture.cases:
			await test_panel(entry,dimensions)
			await test_readonly_panel(entry,dimensions,"dark",false,true)
			await test_readonly_panel(entry,dimensions,"light",true,true)
		await test_readonly_panel(fixture.cases[2],dimensions,"dark",false,false)
		await test_readonly_panel(fixture.cases[2],dimensions,"light",false,false)
	print("C4_DEVICE_PANELS ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)

func test_model(entry: Dictionary) -> void:
	var id: String = entry.id
	var controller := Chapter.new()
	var state := initial(id)
	var session := Session.new()
	check(session.open(id,state),id+" opens authenticated context")
	check(session.draft == source.defaults,id+" exact source default draft")
	if id in ["archive_index","power_topology"]: check(not session.can_submit(),id+" incomplete submit disabled")
	var state_before := JSON.stringify(state)
	configure_answer(session,entry.wrong)
	check(JSON.stringify(state) == state_before,id+" local adjustments do not write state/save")
	var draft_before: Dictionary = session.draft.duplicate(true)
	var preview_before := Preview.project(id,session.draft,source)
	check_projection(preview_before,entry.previewWrong)
	var result := submit(session,state,controller)
	check(result.get("handled",false) and not session.completed,id+" handled is not acceptance")
	check(not entry.factId in state.chapter4.factIds,id+" wrong result writes no solved fact")
	check(session.draft == draft_before,id+" wrong result preserves local draft")
	check(not session.feedback.is_empty(),id+" failed feedback remains visible")
	check(Preview.project(id,session.draft,source) == preview_before,id+" wrong result preview keeps current draft")
	var fake_request: Dictionary = session.begin_submit()
	session.resolve(fake_request.serial,state,{"handled":true,"message":source.definitions[id].successText,"accepted":true})
	check(not session.completed,id+" success prose/accepted flag without fact cannot complete")
	configure_answer(session,entry.correct)
	check(JSON.parse_string(JSON.stringify(session.answer())) == entry.correct,id+" current edited answer equals original source oracle")
	var final_preview := Preview.project(id,session.draft,source)
	check_projection(final_preview,entry.previewCorrect)
	check(final_preview != preview_before,id+" preview changes with current adjustments")
	earn_media_studio_layout(state,controller)
	submit(session,state,controller)
	check(session.completed and entry.factId in state.chapter4.factIds,id+" only controller fact completes")
	check(session.view_kind() == "completed" and not session.editable(),id+" success remains completed/read-only")
	check(session.begin_submit().is_empty(),id+" duplicate successful submit ignored")
	check(session.feedback.is_empty(),id+" success clears rejection feedback")
	var complete_draft: Dictionary = session.draft.duplicate(true)
	check(not session.move_card(0,1) and not session.step_axis("xOffset",1) and not session.choose("floor","A1") and not session.toggle_edge(source.edges.keys()[0]),id+" completed controls cannot edit")
	check(session.draft == complete_draft,id+" completed draft stable")
	check(session.close() and session.draft.is_empty(),id+" close unmount discards draft")
	check(session.open(id,state) and session.completed,id+" reopen from completed save is read-only")
	check(session.draft == source.defaults,id+" completed reopen still uses defaults")
	state = initial(id)
	session.open(id,state)
	configure_answer(session,entry.correct)
	session.close()
	session.open(id,JSON.parse_string(JSON.stringify(state)))
	check(session.draft == source.defaults and not session.completed,id+" close/reopen and ordinary save/reload reset unfinished draft")
	state.chapter4.mode = "dark"
	session.open(id,state)
	var dark_draft: Dictionary = session.draft.duplicate(true)
	check(session.view_kind() == "observation" and not session.can_submit(),id+" dark observation read-only")
	check(not session.move_card(0,1) and not session.step_axis("horizontal",1) and not session.choose("floor","A2") and not session.toggle_edge(source.edges.keys()[0]),id+" dark mutation rejected")
	check(session.draft == dark_draft,id+" dark has no draft mutation")

func test_bounds() -> void:
	for id: String in ["duty_board","evacuation_route"]:
		var session := Session.new()
		session.open(id,initial(id))
		check(not session.move_card(0,-1) and not session.move_card(session.draft[session.order_key()].size()-1,1),id+" order endpoints bounded")
		for iteration in range(20):
			session.move_card(0,1)
			check(session.draft[session.order_key()].size() == (3 if id == "duty_board" else 4),id+" unique card count preserved")
			var seen := {}
			for card: String in session.draft[session.order_key()]: seen[card] = true
			check(seen.size() == session.draft[session.order_key()].size(),id+" no duplicate order cards")
	for id: String in source.ranges:
		var session := Session.new()
		session.open(id,initial(id))
		for key: String in source.ranges[id]:
			for iteration in range(20): session.step_axis(key,-1)
			check(session.draft[session.axis_key()][key] == source.ranges[id][key][0],id+" lower bound "+key)
			for iteration in range(20): session.step_axis(key,1)
			check(session.draft[session.axis_key()][key] == source.ranges[id][key][1],id+" upper bound "+key)
	var topology := Session.new()
	topology.open("power_topology",initial("power_topology"))
	for edge: String in source.edges: topology.toggle_edge(edge)
	check(topology.draft.powerEdges.size() == 5 and topology.can_submit(),"Topology cannot exceed exactly five edges")
	topology.toggle_edge(source.edges.keys()[0])
	check(not topology.can_submit(),"Topology under five disables submission")
	check(topology.toggle_edge(source.edges.keys()[5]),"Deselect permits replacement edge")
	var archive := Session.new()
	archive.open("archive_index",initial("archive_index"))
	check(not archive.choose("floor","A9"),"Archive rejects unbounded option")
	archive.choose("yearBand","1991_1998"); archive.choose("floor","A3")
	check(not archive.can_submit(),"Archive two fields insufficient")
	archive.choose("purpose","wayfinding")
	check(archive.can_submit(),"Archive all fields enables submission")
	archive.choose("floor","")
	check(not archive.can_submit(),"Archive placeholder clears completeness")
	check(source.traces.evacuation_route == ["202 门外：完整鞋印的脚尖朝向门外","东侧走廊墙边：同一种鞋底纹连续出现","交通核心转角：右脚外缘磨损加深，脚尖偏向楼梯","主楼梯黄线内：只留下半枚向下的鞋印"],"Four exact source shoeprint observation rows")

func test_authority_gates() -> void:
	for entry: Dictionary in fixture.cases:
		var id: String = entry.id
		for gate: String in ["phase","floor","mode","context"]:
			var state := initial(id)
			var session := Session.new()
			session.open(id,state)
			configure_answer(session,entry.correct)
			var request: Dictionary = session.begin_submit()
			earn_media_studio_layout(state,Chapter.new())
			match gate:
				"phase": state.chapter4.phase = "maintenance_repair"
				"floor": state.chapter4.floor = "A2" if source.assets[id].floor != "A2" else "A1"
				"mode": state.chapter4.mode = "dark"
				"context": state.native.c4_context = "clock"
			var controller := Chapter.new()
			var result: Dictionary = controller.dispatch(state,request.action,request.value)
			session.resolve(request.serial,state,result)
			check(not session.completed and not entry.factId in state.chapter4.factIds,id+" controller preserves "+gate+" gate")
			check(not session.compatible(state),id+" session detects stale "+gate)
	var state := initial("media_alignment","dark",false)
	var opening := Chapter.new()
	var opened: Dictionary = opening.dispatch(state,"c4_device_media_alignment")
	check(opened.get("page","") == "c4_device","Missing-film view remains openable for prerequisite explanation")
	var session := Session.new()
	session.open("media_alignment",state)
	check(session.view_kind() == "locked" and not session.can_submit(),"Film prerequisite lock precedes observation controls")
	state.chapter4.mode = "light"
	state.native.mode = "light"
	var controller := Chapter.new()
	var result: Dictionary = controller.dispatch(state,"c4_solve_media_alignment",{"xOffset":2,"yOffset":-1,"rotationQuarterTurns":1})
	check(not "a3_media_alignment_completed" in state.chapter4.factIds and not result.message.is_empty(),"Controller film completion guard retained")

func configure_panel_answer(panel: Control, answer: Dictionary) -> void:
	var session: RefCounted = panel.session
	match session.puzzle_id:
		"duty_board", "evacuation_route":
			for target in range(answer.order.size()):
				while session.draft[session.order_key()].find(answer.order[target]) > target:
					var up: Button = panel.find_child("up_"+answer.order[target],true,false)
					check(up != null and not up.disabled,"Native order button is enabled")
					up.pressed.emit()
		"archive_index":
			for key: String in ["yearBand","floor","purpose"]:
				var node: OptionButton = panel.find_child("choice_"+key,true,false)
				for index in range(source.options[key].size()):
					if source.options[key][index].value == answer[key]: node.item_selected.emit(index); break
		"media_alignment", "positioning_calibration":
			for key: String in source.ranges[session.puzzle_id]:
				while int(session.draft[session.axis_key()][key]) != int(answer[key]):
					var prefix := "plus_" if int(session.draft[session.axis_key()][key]) < int(answer[key]) else "minus_"
					var node: Button = panel.find_child(prefix+key,true,false)
					check(node != null and not node.disabled,"Native axis button is enabled")
					node.pressed.emit()
		"power_topology":
			for edge: String in session.draft.powerEdges.duplicate(): panel.find_child("edge_"+edge,true,false).pressed.emit()
			for edge: String in answer.edgeIds:
				var node: Button = panel.find_child("edge_"+edge,true,false)
				check(not node.disabled,"Native topology selection enabled")
				node.pressed.emit()

func test_panel(entry: Dictionary, dimensions: Vector2i) -> void:
	root.size = dimensions
	var state := initial(entry.id)
	var panel := DevicePanel.new()
	check(panel.configure(entry.id,state,font),entry.id+" panel configured")
	root.add_child(panel)
	for frame in range(4): await process_frame
	for frame in range(3): await process_frame
	var viewport_rect := Rect2(Vector2.ZERO,Vector2(dimensions))
	check(viewport_rect.encloses(panel.frame.get_global_rect()),entry.id+" frame contained "+str(dimensions))
	check(panel.frame.get_global_rect().encloses(panel.submit_button.get_global_rect()),entry.id+" footer contained "+str(dimensions))
	check(panel.scroll.get_h_scroll_bar().max_value <= panel.scroll.get_h_scroll_bar().page+1,entry.id+" no horizontal overflow "+str(dimensions))
	for node in panel.find_children("*","Button",true,false):
		check(node.size.y >= 43.9,entry.id+" 44px touch target "+node.name)
		check(node.get_theme_font_size("font_size") >= 14,entry.id+" readable button "+node.name)
		check(node.get_global_rect().position.x >= panel.frame.global_position.x and node.get_global_rect().end.x <= panel.frame.get_global_rect().end.x+1,entry.id+" control horizontal containment "+node.name+str(dimensions))
	var dispatch_count := [0]
	var request_serial := [0]
	panel.submit_requested.connect(func(_action: String,_value: Dictionary,serial: int): dispatch_count[0] += 1; request_serial[0] = serial)
	configure_panel_answer(panel,entry.wrong)
	panel._submit_or_close(); panel._submit_or_close()
	check(dispatch_count[0] == 1,entry.id+" panel rapid submit dispatches only once")
	var draft: Dictionary = panel.session.draft.duplicate(true)
	panel.resolve_submission(request_serial[0],state,{"handled":true,"message":"设置与现场留下的痕迹不符。"})
	check(is_instance_valid(panel) and panel.session.draft == draft and not panel.session.completed,entry.id+" panel retained through rejection")
	check(panel.feedback_label.text == "设置与现场留下的痕迹不符。",entry.id+" local feedback surface")
	configure_panel_answer(panel,entry.correct)
	var controller := Chapter.new()
	earn_media_studio_layout(state,controller)
	panel.submit_requested.connect(func(action: String,value: Dictionary,serial: int):
		var result: Dictionary = controller.dispatch(state,action,value)
		panel.resolve_submission(serial,state,result)
	)
	panel.submit_button.pressed.emit()
	check(panel.session.completed and panel.session.view_kind() == "completed",entry.id+" native UI adjustment → controller success")
	check(panel.submit_button.text == "返回现场" and panel.preview == null,entry.id+" completed UI readonly and stays open")
	var closed := [false]
	panel.close_requested.connect(func(): closed[0] = true)
	panel.submit_button.pressed.emit()
	check(closed[0],entry.id+" completed footer explicitly closes")
	panel.dispose_session()
	root.remove_child(panel)
	panel.queue_free()
	await process_frame

func check_projection(actual: Dictionary, expected: Dictionary) -> void:
	for key: String in expected:
		if key == "position": check(actual.position == Vector2(expected.position[0],expected.position[1]),"Native preview transform equals executed source TSX")
		elif key in ["rotation","pressY","pressure"]: check(float(actual[key]) == float(expected[key]),"Native preview numeric geometry equals executed source TSX "+key)
		else: check(actual[key] == expected[key],"Native preview derives source-equivalent current draft "+key)

func test_readonly_panel(entry: Dictionary, dimensions: Vector2i, mode: String, completed: bool, film: bool) -> void:
	root.size = dimensions
	var state := initial(entry.id,mode,film)
	if completed: state.chapter4.factIds.append(entry.factId)
	var panel := DevicePanel.new()
	check(panel.configure(entry.id,state,font),entry.id+" readonly panel configured")
	root.add_child(panel)
	for frame in range(4): await process_frame
	for frame in range(3): await process_frame
	check(panel.preview == null,entry.id+" readonly preview shows source asset")
	check(panel.find_children("*","Button",true,false).size() == 2,entry.id+" readonly shows only two close controls")
	check(Rect2(Vector2.ZERO,Vector2(dimensions)).encloses(panel.frame.get_global_rect()),entry.id+" readonly frame containment")
	check(panel.frame.get_global_rect().encloses(panel.submit_button.get_global_rect()),entry.id+" readonly footer containment")
	check(panel.scroll.get_h_scroll_bar().max_value <= panel.scroll.get_h_scroll_bar().page+1,entry.id+" readonly no horizontal overflow")
	check(panel.bg == Color("071f2b") if mode == "dark" else panel.bg == Color("e8e5d7"),entry.id+" source light/dark palette")
	var visible_text: PackedStringArray = []
	for node in panel.find_children("*","Label",true,false):
		visible_text.append(node.text)
		check(node.get_theme_font_size("font_size") >= 13,entry.id+" readable readonly label")
	if not completed and mode == "dark" and film:
		for trace: String in source.traces[entry.id]: check(visible_text.has("• "+trace),entry.id+" exact rendered source observation row")
	if entry.id == "media_alignment" and not film:
		check(visible_text.has("缺少可校准底片"),"Missing film explains prerequisite in both modes")
		check(not visible_text.has("• "+source.traces.media_alignment[0]),"Missing film takes precedence over observation controls")
	if completed: check(visible_text.has(source.definitions[entry.id].successText),entry.id+" exact completed record")
	root.remove_child(panel)
	panel.queue_free()
	await process_frame
