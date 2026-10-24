extends SceneTree
## Chapter-local fixture coverage, never an earned continuous campaign.
const Chapter=preload("res://scripts/chapters/chapter3.gd")
var checks:Array=[]
var state:Node
var main:Control
var controller:RefCounted=Chapter.new()
func _initialize(): run.call_deferred()
func frames(n:int=4):
	for i in n:await process_frame
func check(ok:bool,name:String,detail:Variant=null):
	checks.append({"pass":ok,"name":name,"detail":detail})
	if not ok:push_error(name)
func find_button(node:Node,text:String)->Button:
	if node is Button:
		if text in node.text:return node
		if text=="‹" and node.name=="PhoneAppBack":return node
		if node.name=={"照片线索":"C35Source_photo","录音线索":"C35Source_voice","消息线索":"C35Source_chat","网络记录":"C35Source_network"}.get(text,""):return node
	for child in node.get_children():
		var found=find_button(child,text)
		if found!=null:return found
	return null
func click(text:String):
	var button=find_button(main.page_body,text)
	check(button!=null and not button.disabled,"enabled actual control: "+text)
	if button==null or button.disabled:return
	var owner=button.get_parent()
	while owner!=null:
		if owner is ScrollContainer:owner.ensure_control_visible(button)
		owner=owner.get_parent()
	await frames()
	var point=button.get_global_rect().get_center()
	check(main.phone_scroll.get_global_rect().has_point(point),"visible hit area: "+text)
	for down in [true,false]:
		var e=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.button_mask=MOUSE_BUTTON_MASK_LEFT if down else 0;e.pressed=down;e.position=point;e.global_position=point;root.push_input(e,true);await frames(1)
	await frames()
func key(code:Key):
	for down in [true,false]:
		var e=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=down;root.push_input(e,true);await frames(1)
	await frames()
func has_text(node:Node,text:String)->bool:
	if node is Label and text in node.text:return true
	for child in node.get_children():
		if has_text(child,text):return true
	return false
func matrix_fixture_checks():
	# Explicit presentation fixtures: these views earn no evidence or campaign proof.
	var pages=load("res://scripts/ui/chapter3_phone_pages.gd").new()
	for evidence:Array in [[],["journal_start"],["journal_start","photo_direction"]]:
		var fixture:Dictionary=state.d.duplicate(true)
		fixture.chapterThreeInterlude.recoveryOpened=true
		fixture.chapterThreeInterlude.evidenceIds=evidence.duplicate()
		var before:String=JSON.stringify(fixture)
		var view:Control=pages.build("c35_recovery",{},fixture)
		check(view.find_child("C35EvidenceMatrix",true,false)==null,"partial evidence cannot expose the four-source matrix: "+str(evidence.size()))
		check(not has_text(view,"段永平教学楼") and not has_text(view,"22:45:00") and find_button(view,"开始回放")==null,"partial evidence cannot reveal destination, unresolved endpoint or replay: "+str(evidence.size()))
		check(has_text(view,"22:37:05")==evidence.has("journal_start"),"only the earned journal start is restored: "+str(evidence.size()))
		check(JSON.stringify(fixture)==before,"building the partial recovery view never writes evidence")
		view.free()
	var fixture:Dictionary=state.d.duplicate(true)
	var interlude:Dictionary=fixture.chapterThreeInterlude
	interlude.recoveryOpened=true
	interlude.evidenceIds=["journal_start","photo_direction","network_destination","broadcast_end"]
	interlude.photoSequenceSolved=true;interlude.voiceSequenceSolved=true
	interlude.officialNoticeSaved=true;interlude.routeScreenshotSaved=true;interlude.networkRecordRead=true
	interlude.networkRecordId="record_theater_hall"
	var before:String=JSON.stringify(fixture)
	var view:Control=pages.build("c35_recovery",{},fixture)
	check(view.find_child("C35EvidenceMatrix",true,false)!=null and has_text(view,"CC98 × 照片") and has_text(view,"录音 × 网络"),"all four earned classes reveal the original cross-source comparisons")
	check(has_text(view,"22:44:31 · 剧场前厅") and not has_text(view,"22:44:57"),"matrix reports the saved candidate without replacing it with the correct record")
	check(find_button(view,"段永平教学楼")==null and find_button(view,"开始回放")==null,"matrix visibility does not bypass old-time exclusions or destination selection")
	check(JSON.stringify(fixture)==before,"matrix reconstruction is read-only")
	view.free()
	interlude.rejectedDecoyIds=["canteen_0755","theater_0832","status_clock_075523"]
	interlude.statusClockMarkedUntrusted=true
	view=pages.build("c35_recovery",{},fixture)
	check(has_text(view,"恢复的时间线") and view.find_child("C35Destination",true,false)!=null and find_button(view,"开始回放")==null,"original completed-exclusion gate still opens only destination choices")
	view.free()
	interlude.networkRecordId="record_0755";interlude.destinationId="duan_yongping_a1";interlude.phase="destination_verified"
	before=JSON.stringify(fixture)
	view=pages.build("c35_recovery",{},fixture)
	check(has_text(view,"22:44:57 · 北教学区 A 区") and has_text(view,"路径记录已恢复") and has_text(view,"回放会从启真湖最后一帧开始，并在已确认地点结束。"),"verified destination restores the original replay explanation and selected record")
	check(find_button(view,"开始回放")!=null and not interlude.replayUnlocked,"accepted path exposes the existing replay action without executing it")
	check(JSON.stringify(fixture)==before,"the confirmed-path card does not write replay or story state")
	view.free()
func run():
	state=root.get_node("State");state.developer_mode=true;state.d=state.initial()
	state.d.native.chapter=3;state.d.native.scene="";state.d.native.page="c35_recovery";state.d.runtimeMode="phone";state.d.qizhenLake.phase="complete";state.d.qizhenLake.active=true
	root.size=Vector2i(390,844)
	matrix_fixture_checks()
	main=load("res://scenes/main.tscn").instantiate();root.add_child(main);await frames()
	await click("开始恢复");await click("查看划船帖")
	await click("安全返航");check(not state.d.chapterThreeInterlude.evidenceIds.has("journal_start"),"summary draft is not publication")
	await click("细节暂不公开");await click("发布收尾并保存时间")
	check(state.d.qizhenLake.journal.summaryChoice=="details_withheld","actual chosen journal summary published")
	await click("‹")
	# Source ring order uses clockwise next/previous plus Home/End, not spatial nearest.
	var first=find_button(main.page_body,"照片线索");first.grab_focus();await key(KEY_DOWN)
	check(root.gui_get_focus_owner()==find_button(main.page_body,"录音线索"),"source-list Down moves to next source")
	await key(KEY_DOWN)
	check(root.gui_get_focus_owner()==find_button(main.page_body,"消息线索"),"source-list Down continues clockwise from rightmost source")
	await key(KEY_END)
	check(root.gui_get_focus_owner()==find_button(main.page_body,"网络记录"),"source-list End reaches last source")
	await key(KEY_HOME)
	check(root.gui_get_focus_owner()==find_button(main.page_body,"照片线索"),"source-list Home returns to first source")
	await key(KEY_ENTER)
	check(state.d.native.page=="c35_photos","source-list keyboard activation opens photo branch")
	if state.d.native.page!="c35_photos":state.open_page("c35_photos");await frames()
	for code in ["FRM B2","FRM D7","FRM 4C"]:await click(code)
	await click("确认照片顺序")
	check(not state.d.chapterThreeInterlude.photoSequenceSolved,"mirrored photo attempt cannot solve")
	check(find_button(main.page_body,"FRM 91").disabled,"source fourth selection is disabled at three choices")
	check(state.d.native.c35_photo_selection.size()==3 and not state.d.native.c35_photo_selection.has("paper_middle"),"fourth selection does not silently replace a candidate")
	await click("重排")
	check(state.d.native.c35_photo_selection.is_empty(),"source reorder clears the draft")
	await click("FRM B2");await click("FRM 91");await click("FRM 4C");await click("确认照片顺序")
	check(state.d.chapterThreeInterlude.photoSequenceSolved and state.d.chapterThreeInterlude.photoFrameIds==["paper_left","paper_middle","paper_right"],"correct photo order accepted through real controls")
	# Accepted proof is read-only in the UI, and stale submissions cannot rewrite it.
	check(find_button(main.page_body,"重排")==null and find_button(main.page_body,"确认照片顺序")==null,"solved gallery has no stale submit or reorder action")
	check(find_button(main.page_body,"FRM B2").disabled,"solved gallery disables selection edits")
	controller.dispatch(state.d,"c35_photos",["paper_left","mirrored_a","paper_right"])
	check(state.d.chapterThreeInterlude.photoFrameIds==["paper_left","paper_middle","paper_right"],"stale wrong retry preserves accepted photo proof")
	# Stale domain messages follow source already_complete semantics.
	var before=state.d.qizhenLake.journal.duplicate(true)
	state.d.chapterThreeInterlude.phase="timeline_assembly"
	controller.dispatch(state.d,"c35_journal","safe_return")
	check(state.d.qizhenLake.journal==before and state.d.chapterThreeInterlude.phase=="timeline_assembly","repeated journal publication cannot rewrite archive or regress phase")
	# Native persistence serializes earned and draft data, never the live media owner.
	state.developer_mode=false
	check(state.save_game(),"isolated ordinary save accepts chapter-local fixture")
	var proof=state.d.chapterThreeInterlude.photoFrameIds.duplicate()
	state.d=state.initial();check(state.load_game(),"isolated ordinary save reloads")
	check(state.d.chapterThreeInterlude.photoSequenceSolved and state.d.chapterThreeInterlude.photoFrameIds==proof,"accepted photo facts survive ordinary reload")
	state.developer_mode=true
	await main.shutdown();main.queue_free();await frames()
	var failures=checks.filter(func(c):return not c.pass)
	var output=OS.get_environment("INTERLUDE_QA_REPORT")
	if output.is_empty():output="user://interlude-retry-controls.json"
	FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"coverage":"chapter-local fixture; actual native Control pointer/keyboard input; not earned campaign; no CUA"},"  "))
	print("INTERLUDE_RETRY_CONTROLS ",checks.size()," checks; ",failures.size()," failures")
	quit(1 if not failures.is_empty() else 0)
