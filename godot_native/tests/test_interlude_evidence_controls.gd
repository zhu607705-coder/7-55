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
func click(text:String,scope_text:String=""):
	var scope=main.page_body if scope_text.is_empty() else find_card(main.page_body.get_child(0),scope_text)
	var button=find_button(scope,text) if scope!=null else null
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
func has_text(node:Node,text:String)->bool:
	if node is Label and text in node.text:return true
	for child in node.get_children():
		if has_text(child,text):return true
	return false
func find_card(node:Node,text:String)->Node:
	for child in node.get_children():
		if child is PanelContainer and has_text(child,text):return child
		var found=find_card(child,text)
		if found!=null:return found
	return null
var focused:bool=true
func back():await click("‹")
func run():
	state=root.get_node("State");state.developer_mode=true;state.d=state.initial()
	state.d.native.chapter=3;state.d.native.scene="";state.d.native.page="c35_recovery";state.d.runtimeMode="phone";state.d.qizhenLake.phase="complete";state.d.qizhenLake.active=true
	var width=430 if OS.get_environment("INTERLUDE_QA_WIDTH")=="430" else 390
	root.size=Vector2i(width,860 if width==430 else 844)
	main=load("res://scenes/main.tscn").instantiate();root.add_child(main);await frames()
	# Only window focus is injected for a headless host; real audio and Controls run.
	main.media_host.setup(func()->Dictionary:
		var snapshot=main._read_runtime_state();snapshot.native.host.focused=focused;return snapshot)
	await click("打开恢复工具");await click("查看划船帖");await click("安全返航");await click("发布收尾并保存时间");await click("返回记录恢复")
	await click("录音线索")
	await click("试听后可选","CLIP D7")
	check(state.d.native.get("c35_voice_selection",[]).is_empty(),"unreviewed clip cannot enter selection")
	await click("▶","CLIP D7");await create_timer(.6).timeout
	check(main.media_host.current!=null and main.media_host.current.phase=="playing","actual audio starts from visible native control")
	await click("暂停","CLIP D7")
	var paused=main.media_host.current.position_ms if main.media_host.current!=null else -1.0
	await create_timer(.3).timeout
	check(main.media_host.current!=null and main.media_host.current.phase=="paused" and absf(main.media_host.current.position_ms-paused)<2,"pause keeps audio and progress still")
	await click("继续播放","CLIP D7");await create_timer(.25).timeout;await back()
	check(main.media_host.current==null,"voice back control cancels real player")
	check(not state.d.native.get("c35_listened",[]).has("lake"),"early back cannot mint heard flag")
	await click("录音线索");await click("▶","CLIP D7");await create_timer(.2).timeout
	focused=false;await frames();check(main.media_host.current==null,"focus interruption cancels media ownership")
	focused=true
	var source=controller.interlude.content("chapter3-interlude-voice-memos.audio.content")
	for recording in source.recordings:
		await click("▶",recording.code)
		var session=main.media_host.current
		check(session!=null and session.clip_id==recording.id and not session.fallback,"real source audio resolved: "+recording.id)
		if session!=null:
			var deadline=Time.get_ticks_msec()+int(session.duration_ms)+5000
			while session.phase=="playing" and Time.get_ticks_msec()<deadline:await process_frame
			check(state.d.native.get("c35_listened",[]).has(recording.id),"real audition earned heard receipt: "+recording.id,{"session":session.snapshot(),"verified":session.verified_ms,"heard":session.heard_ready,"listened":state.d.native.get("c35_listened",[])})
			check(session.phase=="finished","source clip completed: "+recording.id)
			check(is_equal_approx(session.position_ms,session.end_ms),"completed progress reaches endpoint: "+recording.id)
			print("AUDITION ",recording.id," ",session.snapshot()," verified ",session.verified_ms," heard ",session.heard_ready," saved ",state.d.native.get("c35_listened",[]))
	# Pick a wrong set, prove rejection, then correct it through selection controls.
	for code in ["CLIP D7","CLIP 91","CLIP 4C","CLIP E2"]:await click("保留这段",code)
	await click("进入排序");await click("确认录音顺序")
	check(not state.d.chapterThreeInterlude.voiceSequenceSolved,"wrong reviewed voice candidate cannot solve")
	await click("重新筛选");await click("清空选择")
	check(state.d.native.c35_voice_selection.is_empty(),"clear removes all voice candidates")
	for code in ["CLIP 3A","CLIP 4C","CLIP 91","CLIP D7"]:await click("保留这段",code)
	await click("进入排序");await click("确认录音顺序")
	check(not state.d.chapterThreeInterlude.voiceSequenceSolved,"correct voice set in reverse order cannot solve")
	for i in 3:await click("上移","CLIP D7")
	for i in 2:await click("上移","CLIP 91")
	await click("上移","CLIP 4C")
	check(find_button(find_card(main.page_body.get_child(0),"CLIP D7"),"上移").disabled,"first audio entry cannot move before start")
	check(find_button(find_card(main.page_body.get_child(0),"CLIP 3A"),"下移").disabled,"last audio entry cannot move past end")
	await click("确认录音顺序");check(state.d.chapterThreeInterlude.voiceSequenceSolved,"native reordering validates continuous source audio route")
	await back();await click("照片线索")
	for code in ["FRM B2","FRM 91","FRM 4C"]:await click(code)
	await click("确认照片顺序");await back();await click("消息线索")
	await click("保存通知");await click("麦斯威夜间自习群")
	await click("选择","203 还开着吗");await click("选择","刚看见保安");await click("保存路线截图")
	check(not state.d.chapterThreeInterlude.routeScreenshotSaved,"wrong route pair remains unresolved")
	await click("选择","东边入口已经封了")
	check(state.d.native.c35_route_selection.size()==2 and not state.d.native.c35_route_selection.has("east_closed"),"route selection limit preserves existing pair")
	await click("已选","203 还开着吗");await click("已选","刚看见保安")
	await click("选择","我在西侧看见保洁推车");await click("选择","东边入口已经封了");await click("保存路线截图")
	check(state.d.chapterThreeInterlude.routeScreenshotSaved,"route pair accepted in reverse selection order")
	await back();await click("网络记录");await create_timer(1.6).timeout;await frames()
	for record in ["22:44:31","22:43:11","22:44:12"]:
		await click("保存候选记录",record)
		check(find_button(find_card(main.page_body.get_child(0),record),"已保存")!=null,"candidate marker updates: "+record)
	await click("保存候选记录","22:44:57")
	check(state.d.chapterThreeInterlude.evidenceIds.size()==4,"all four evidence categories earned through actual controls")
	# Popup options receive real keyboard input; they do not write story evidence.
	var before=state.d.chapterThreeInterlude.duplicate(true)
	var options=main.page_body.find_children("*","OptionButton",true,false)
	for i in 3:
		options=main.page_body.find_children("*","OptionButton",true,false)
		main.phone_scroll.ensure_control_visible(options[i]);await frames();options[i].grab_focus()
		await key(KEY_SPACE);await key(KEY_DOWN);await key(KEY_ENTER)
	check(controller.interlude.filtered_records(state.d).size()==1,"three keyboard-operated filters isolate one candidate")
	check(state.d.chapterThreeInterlude==before,"filter operations do not advance evidence")
	await back()
	for entry in [["食堂 0755","这是更早"],["剧场 08:32","这是本机"],["状态栏 07:55:23","这是编号"]]:await click(entry[1],entry[0])
	check(state.d.chapterThreeInterlude.rejectedDecoyIds.is_empty(),"wrong exclusion reasons never validate records")
	for entry in [["食堂 0755","这是编号"],["剧场 08:32","这是更早"],["状态栏 07:55:23","这是本机"]]:await click(entry[1],entry[0])
	for destination in ["启真湖小码头","剧场前厅","基础图书馆南侧"]:
		await click(destination);check(state.d.chapterThreeInterlude.destinationId==null,"wrong destination rejected: "+destination)
	await click("段永平教学楼 A 楼一层");await click("开始回放")
	check(state.d.chapterThreeInterlude.replayUnlocked and state.d.native.page=="c4_notes","earned chapter-local evidence opens normal Chapter4 surface")
	check(find_button(main.page_body,"播放恢复回放")!=null,"Chapter4 prologue remains an explicit visible action")
	state.developer_mode=false;check(state.save_game(),"final interlude facts save through ordinary serializer")
	var saved=state.d.duplicate(true);state.d=state.initial();check(state.load_game(),"final interlude facts reload")
	check(state.d.chapterThreeInterlude==saved.chapterThreeInterlude,"reloaded interlude facts remain identical")
	check(state.d.native.c35_listened.size()==7 and main.media_host.current==null,"reviewed receipts persist without live audio session")
	state.developer_mode=true;await main.shutdown();main.queue_free();await frames()
	var failures=checks.filter(func(c):return not c.pass)
	var output=OS.get_environment("INTERLUDE_QA_REPORT")
	if output.is_empty():output="user://interlude-evidence-controls.json"
	FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"viewport":root.size,"coverage":"chapter-local fixture; actual native Control pointer/keyboard and real audio playback; headless window-focus injected; not earned campaign; no CUA"},"  "))
	print("INTERLUDE_EVIDENCE_CONTROLS ",checks.size()," checks; ",failures.size()," failures")
	quit(1 if not failures.is_empty() else 0)
