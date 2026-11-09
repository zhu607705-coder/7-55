extends SceneTree
const Investigation = preload("res://scripts/chapters/c35_investigation.gd")
var state: Node
var shell: Control
var failures := 0

func _initialize() -> void: run.call_deferred()

func check(ok: bool, message: String) -> void:
	if not ok:
		failures+=1
		push_error(message)

func frames() -> void:
	for frame in 5: await process_frame

func click(target: Vector2) -> void:
	for pressed in [true,false]:
		var event := InputEventScreenTouch.new()
		event.position=target
		event.pressed=pressed
		root.push_input(event,true)
		await frames()

func press(text: String) -> void:
	for control: Button in shell.page_body.find_children("*","Button",true,false):
		if (control.text==text or control.name==text) and control.is_visible_in_tree() and not control.disabled:
			await click(control.get_global_rect().get_center())
			return
	check(false,"Expected enabled button: "+text)

func finger(index: int,position: Vector2,pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index=index
	event.position=position
	event.pressed=pressed
	root.push_input(event,true)
	await frames()

func run() -> void:
	root.size=Vector2i(390,844)
	state=root.get_node("State")
	state.developer_mode=true
	state.d=state.initial()
	state.d.native.chapter=3
	state.d.native.page="c35_recovery"
	state.d.native.settings.reduced_motion=true
	state.d.qizhenLake.phase="complete"
	state.d.chapterThreeInterlude.phase="reboot"
	check(state.validate_snapshot(state.d),"Original interlude save remains valid")
	Investigation.begin(state.d)
	state.act("c35_trace:submit")
	check(Investigation.step(state.d)=="inbox","Out-of-order submission cannot mint a receipt")
	shell=load("res://scenes/main.tscn").instantiate()
	root.add_child(shell)
	await frames()
	await press("C35CourseConversation")
	await press("C35GroupSettings")
	check(shell.page_body.find_child("C35GroupSettingsView",true,false)!=null,"Group header opens settings")
	await press("聊天记录")
	await press("C35Avatar_ta")
	await press("查看本机文件")
	await press("C35Preview_"+Investigation.EARLIER_FILE_ID)
	state.act("c35_trace:attach",Investigation.EARLIER_FILE_ID)
	check(Investigation.step(state.d)=="file","The previous week's file cannot be attached")
	await frames()
	await press("PhoneAppBack")
	await press("PhoneAppBack")
	await press("拍摄作业")
	await press("C35CameraShutter")
	await press("附上原图")
	state.act("c35_trace:submit")
	check(Investigation.step(state.d)=="attached","Sending requires a chosen reply")
	await frames()
	await press("C35ChooseHomework")
	await press("C35Candidate_bare")
	await press("C35SendHomework")
	check(Investigation.step(state.d)=="attached" and state.d.native[Investigation.KEY].identity_requested,"The assistant asks who sent an unsigned message")
	var direct_status := shell.page_body.find_child("C35ReadStatus",true,false) as Label
	check(direct_status!=null and direct_status.text=="已读" and direct_status.autowrap_mode==TextServer.AUTOWRAP_OFF and direct_status.size.x>=58,"Direct-message receipt fits on one line")
	await press("C35ChooseHomework")
	await press("C35Candidate_identity")
	var draft: TextEdit=shell.page_body.find_child("C35SubmissionText",true,false)
	check(not draft.editable and draft.text==Investigation.REPLIES.identity,"A choice fills the readonly outgoing message")
	await press("C35SendHomework")
	check(Investigation.step(state.d)=="file_error" and state.validate_snapshot(state.d),"A photo submission gets a valid retry receipt")
	await press("处理附件")
	await press("转为 PDF")
	await press("附到补交")
	await press("C35SendHomework")
	check(Investigation.step(state.d)=="receipt" and state.d.native[Investigation.KEY].reply=="identity","The corrected submission preserves the chosen message")
	await press("查看最近照片")
	await press("查看 CC98 划船帖")
	await press("C35JournalComposer")
	check(not state.d.chapterThreeInterlude.evidenceIds.has("journal_start"),"Opening the candidate sheet does not publish")
	await press("C35Candidate_safe_return")
	await press("‹")
	await press("C35ChatComposer")
	await press("C35Candidate_route")
	var group_status := shell.page_body.find_child("C35ReadStatus",true,false) as Label
	check(group_status!=null and group_status.get_line_count()==1 and group_status.size.x>=58,"Group receipt has space for the read count")
	await press("C35Avatar_chen_jia")
	check(Investigation.step(state.d)=="seen","Another group member does not supply the location")
	await press("C35Avatar_zhou_qi")
	await press("C35LocationShare")
	var map: Control=shell.page_body.find_child("C35CampusPinMap",true,false)
	check(is_instance_valid(map),"Position card opens actual campus map")
	if map!=null:
		check(map.layers.ready and map.layers.manifest.layers.any(func(row): return row.id=="north_teaching_V3"),"Map uses the active North Teaching layers")
		check(map.zoom==1 and map.center==Investigation.CAMPUS_SIZE/2 and map.lake_gate.is_finite(),"Shared position opens the full campus with a known starting landmark")
		var midpoint:=map.get_global_rect().get_center()
		await finger(0,midpoint-Vector2(25,0),true)
		await finger(1,midpoint+Vector2(25,0),true)
		var drag := InputEventScreenDrag.new()
		drag.index=1;drag.position=midpoint+Vector2(70,0)
		root.push_input(drag,true)
		await frames()
		await finger(1,drag.position,false)
		await finger(0,midpoint-Vector2(25,0),false)
		check(map.zoom>1.5 and not map.pin.is_finite(),"Pinch zoom does not leave a marker")
		await press("C35MapOverview")
		check(map.zoom==1 and map.center==Investigation.CAMPUS_SIZE/2,"Compass restores the entire campus")
		await click(map.get_global_rect().get_center())
		await press("使用这个落点")
		check(Investigation.step(state.d)=="map","Wrong spot can be retried")
		map=shell.page_body.find_child("C35CampusPinMap",true,false)
		var east: Vector2=map._map_origin()+Investigation.EAST_APPROACH.get_center()*map._map_scale()
		await click(map.get_global_transform_with_canvas()*east)
		await press("使用这个落点")
		check(Investigation.step(state.d)=="map" and "东侧入口" in str(state.last_result.get("message","")),"Closed east entrance gets specific feedback")
		map=shell.page_body.find_child("C35CampusPinMap",true,false)
		var source: Vector2=Investigation.WEST_APPROACH.get_center()
		var local: Vector2=map._map_origin()+source*map._map_scale()
		await click(map.get_global_transform_with_canvas()*local)
		await press("使用这个落点")
	await press("22:44:31 · 剧场前厅")
	check(Investigation.step(state.d)=="arrival","Wrong time source cannot unlock replay")
	await press("22:44:57 · 北教学区 A 区 · 3 秒")
	check(Investigation.can_replay(state.d) and state.validate_snapshot(state.d),"Correct map and time receipts make a valid save")
	var broken: Dictionary=state.d.duplicate(true)
	broken.native[Investigation.KEY].pin=[3000,2000]
	check(not state.validate_snapshot(broken),"Persisted off-target pin is rejected")
	check(state.d.chapterThreeInterlude.evidenceIds==["journal_start"],"Short route does not manufacture old evidence")
	await press("从西侧大厅开始回放")
	check(is_instance_valid(shell.active_game) and not state.d.chapter4.prologueSeen,"Original replay waits for acknowledgement")
	if is_instance_valid(shell.active_game):
		shell.active_game._skip_prologue()
		await frames()
		shell.active_game._finish({"acknowledged":true})
		await frames()
		check(state.d.chapter4.prologueSeen and state.d.chapterThreeInterlude.completed,"Acknowledgement enters the original Chapter 4")
	await shell.shutdown()
	shell.queue_free()
	await frames()
	quit(1 if failures else 0)
