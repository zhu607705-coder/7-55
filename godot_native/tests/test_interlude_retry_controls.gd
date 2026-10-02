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
	if node is Button and text in node.text:return node
	for child in node.get_children():
		var found=find_button(child,text)
		if found!=null:return found
	return null
func click(text:String):
	var button=find_button(main.page_body,text)
	check(button!=null and not button.disabled,"enabled actual control: "+text)
	if button==null or button.disabled:return
	main.phone_scroll.ensure_control_visible(button);await frames()
	var point=button.get_global_rect().get_center()
	check(main.phone_scroll.get_global_rect().has_point(point),"visible hit area: "+text)
	for down in [true,false]:
		var e=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.button_mask=MOUSE_BUTTON_MASK_LEFT if down else 0;e.pressed=down;e.position=point;e.global_position=point;root.push_input(e,true);await frames(1)
	await frames()
func key(code:Key):
	for down in [true,false]:
		var e=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=down;root.push_input(e,true);await frames(1)
	await frames()
func run():
	state=root.get_node("State");state.developer_mode=true;state.d=state.initial()
	state.d.native.chapter=3;state.d.native.scene="";state.d.native.page="c35_recovery";state.d.runtimeMode="phone";state.d.qizhenLake.phase="complete";state.d.qizhenLake.active=true
	root.size=Vector2i(390,844)
	main=load("res://scenes/main.tscn").instantiate();root.add_child(main);await frames()
	await click("打开恢复工具");await click("查看划船帖")
	await click("安全返航");check(not state.d.chapterThreeInterlude.evidenceIds.has("journal_start"),"summary draft is not publication")
	await click("细节暂不公开");await click("发布收尾并保存时间")
	check(state.d.qizhenLake.journal.summaryChoice=="details_withheld","actual chosen journal summary published")
	await click("返回记录恢复")
	# Source ring order uses clockwise next/previous plus Home/End, not spatial nearest.
	var first=find_button(main.page_body,"照片线索");first.grab_focus();await key(KEY_RIGHT)
	check(root.gui_get_focus_owner()==find_button(main.page_body,"录音线索"),"ring Right moves to next source")
	await key(KEY_RIGHT)
	check(root.gui_get_focus_owner()==find_button(main.page_body,"消息线索"),"ring Right continues clockwise from rightmost source")
	await key(KEY_END)
	check(root.gui_get_focus_owner()==find_button(main.page_body,"网络记录"),"ring End reaches last source")
	await key(KEY_HOME)
	check(root.gui_get_focus_owner()==find_button(main.page_body,"照片线索"),"ring Home returns to first source")
	await key(KEY_ENTER)
	check(state.d.native.page=="c35_photos","ring keyboard activation opens photo branch")
	if state.d.native.page!="c35_photos":state.open_page("c35_photos");await frames()
	for code in ["FRM B2","FRM D7","FRM 4C"]:await click(code)
	await click("确认照片顺序")
	check(not state.d.chapterThreeInterlude.photoSequenceSolved,"mirrored photo attempt cannot solve")
	await click("FRM 91")
	check(state.d.native.c35_photo_selection.size()==3 and not state.d.native.c35_photo_selection.has("paper_middle"),"fourth selection does not silently replace a candidate")
	await click("FRM D7");await click("FRM 4C");await click("FRM 91");await click("FRM 4C");await click("确认照片顺序")
	check(state.d.chapterThreeInterlude.photoSequenceSolved and state.d.chapterThreeInterlude.photoFrameIds==["paper_left","paper_middle","paper_right"],"correct photo order accepted through real controls")
	# A repeated wrong attempt after success must not corrupt the accepted proof.
	await click("FRM 91");await click("FRM D7");await click("确认照片顺序")
	check(state.d.chapterThreeInterlude.photoFrameIds==["paper_left","paper_middle","paper_right"],"solved photo proof remains unchanged on wrong retry",state.d.chapterThreeInterlude.photoFrameIds)
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
