extends SceneTree
## Portable contract test. Native clipboard/shortcut coverage runs when available;
## --require-native-clipboard makes its absence a failure instead of a clear skip.
const CopyTitle=preload("res://scripts/ui/earned_catalog_title.gd")
const Chapter=preload("res://scripts/chapters/chapter1_2.gd")
class ClipboardProbe extends CopyTitle:
	var available=true
	var reject_write=false
	var text="unrelated clipboard"
	var writes=0
	func _clipboard_supported() -> bool: return available
	func _write_clipboard(value: String) -> void:
		writes+=1
		if not reject_write: text=value
	func _read_clipboard() -> String: return text

var checks=0
var failures=0
var state: Node
var shell: Control
var controller=Chapter.new()
var clipboard=ClipboardProbe.new()
var emitted: Array=[]
var routed: Array=[]
var earned: Dictionary
var clue: Dictionary
var geometry: Array=[]

func _initialize() -> void: run.call_deferred()
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error("EARNED CATALOG TITLE: "+message)
func frames(count: int=4) -> void:
	for i in range(count): await process_frame
func node(id: String) -> Node: return shell.page_body.find_child(id,true,false)
func click(target: Control) -> void:
	check(target!=null,"pointer target exists")
	if target==null: return
	var point=target.get_global_transform_with_canvas()*(target.size/2)
	var motion=InputEventMouseMotion.new(); motion.position=point; root.push_input(motion,true)
	for down in [true,false]:
		var event=InputEventMouseButton.new(); event.position=point; event.button_index=MOUSE_BUTTON_LEFT; event.pressed=down; root.push_input(event,true)
		await frames(1)
	await frames()
func key(code: Key,control: bool=false,unicode: int=0) -> void:
	for down in [true,false]:
		var event=InputEventKey.new(); event.keycode=code; event.physical_keycode=code; event.ctrl_pressed=control; event.unicode=unicode; event.pressed=down; root.push_input(event,true)
		await frames(1)
func type_title(value: String) -> void:
	for character in value: await key(KEY_NONE,false,character.unicode_at(0))
func capture(name: String) -> void:
	var directory=OS.get_environment("CATALOG_TITLE_CAPTURE_DIR")
	if directory.is_empty() or DisplayServer.get_name()=="headless": return
	DirAccess.make_dir_recursive_absolute(directory)
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(directory.path_join(name+".png"))==OK,"Fixture screenshot saved")
func render(page: String="cc98") -> void:
	# This fixture explicitly opens the phone after Escape/normal reload.
	shell.mobile_world=false
	state.d.native.page=page
	shell._refresh(); await frames()
	if state.get_phone_entry_session().phase=="loading":
		state.advance_phone_entry(1500); shell._refresh(); await frames()
func open_clue() -> void:
	shell.phone_builder.cc98_post="seat-022-backpack"
	await render()
	var copy: Control=node("Cc98CopyCatalogTitle")
	if copy:
		shell.phone_scroll.ensure_control_visible(copy)
		await frames()
func acknowledge() -> void:
	var session=controller.library.story_session(earned)
	while session!=null:
		session.attach(earned,self)
		for line in session.lines: session.advance(earned,self)
		controller.dispatch(earned,"lib_story_complete",session)
		session=controller.library.story_session(earned)
func restore_earned() -> void:
	state.d=earned.duplicate(true)
	shell.phone_builder.native_library.reset()
	await open_clue()
func assert_copy_is_local(before: String,count: int,routes: int) -> void:
	check(JSON.stringify(state.d)==before,"Copy leaves complete story, inventory, native state and page unchanged")
	check(emitted.size()==count and routed.size()==routes,"Copy emits no State action, search action, or navigation")
	check(shell.phone_builder.native_library.catalog_query.is_empty(),"Copy does not fill the catalogue query")
	check(not state.d.ui.libraryFinalsPuzzle.catalogSearchCompleted and not state.d.items.callNumber755,"Copy does not earn search proof or an item")
	check(not is_instance_valid(shell.modal),"Copy has no pending confirmation or navigation modal")
func search_from_input(native_paste: bool=false) -> Dictionary:
	await render("library_catalog")
	var query: LineEdit=node("LibraryCatalogQuery")
	check(query.text.is_empty(),"Catalogue opens with an ordinary empty manual query")
	await click(query)
	if native_paste: await key(KEY_V,true)
	else: await type_title(clipboard.text)
	check(query.text=="三分钟离座法","Normal input receives exact copied/manual title")
	check(not state.d.ui.libraryFinalsPuzzle.catalogSearchCompleted,"Input alone cannot submit a search")
	await click(node("LibraryCatalogSearch"))
	return {"ids":state.d.native.get("lib_catalog_result_ids",[]).duplicate(),"complete":state.d.ui.libraryFinalsPuzzle.catalogSearchCompleted,"items":state.d.items.duplicate(true)}

func run() -> void:
	state=root.get_node("State"); state.developer_mode=true
	earned=state.initial(); earned.native.chapter=2; earned.native.page="cc98"; earned.native.scene="library_interior"
	earned.actOne.phase="complete"; earned.actOne.cc98Login.authenticated=true; earned.networkMode="campus_wifi"
	earned.ui.libraryFinalsPhase="occupied_seat_found"; earned.ui.libraryFinalsPuzzle.backpackInspected=true
	controller.dispatch(earned,"lib_note")
	var source: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(CopyTitle.SOURCE_PATH))
	for reply: Dictionary in source.cc98.storyReplies:
		if int(reply.floor)==12: clue={"title":"%s 楼 · %s" % [reply.floor,reply.author],"body":str(reply.get("quote",""))+"\n"+str(reply.text)}
	check(clipboard.title_for_reply(earned,clue).is_empty(),"Collected note alone never exposes a title-copy action")
	check(clipboard.copy_reply_title(earned,clue)=="请先阅读调查帖中的题名线索。" and clipboard.writes==0,"Unopened investigation never touches clipboard")
	controller.dispatch(earned,"lib_investigate","wrong-item")
	check(not earned.ui.libraryFinalsPuzzle.investigationOpened,"Wrong investigation input keeps source gate locked")
	controller.dispatch(earned,"lib_investigate","occupancyNote"); acknowledge()
	check(earned.ui.libraryFinalsPuzzle.investigationOpened and not earned.items.occupancyNote,"Ordinary investigation earns the source reply")
	check(clipboard.title_for_reply(earned,clue)=="三分钟离座法","Copied text is extracted verbatim from authored 12th-floor clue")
	check(clipboard.title_for_reply(earned,{"title":"4 楼","body":clue.body}).is_empty(),"Unrelated reply cannot expose copy")
	check(clipboard.title_for_reply(earned,{"title":clue.title,"body":"unrelated"}).is_empty(),"Missing visible source clue cannot expose copy")
	state.d=earned.duplicate(true)
	shell=load("res://scenes/main.tscn").instantiate(); root.add_child(shell); await frames(); shell.set_process(false)
	shell.phone_builder.earned_catalog_title=clipboard
	shell.phone_builder.action_requested.connect(func(id,value): emitted.append([id,value]))
	shell.phone_builder.page_requested.connect(func(page): routed.append(page))
	for viewport in [Vector2i(390,844),Vector2i(430,860),Vector2i(1440,900)]:
		root.size=viewport; shell.size=Vector2(viewport); await frames()
		await restore_earned()
		var copy: Button=node("Cc98CopyCatalogTitle")
		var status: Label=node("Cc98CatalogTitleFeedback")
		check(copy!=null and copy.text=="复制题名","Explicit copy button appears beside earned source reply")
		if copy==null: continue
		var rect=copy.get_global_rect()
		check(rect.size.y>=44,"Copy touch target is at least44 physical pixels at "+str(viewport))
		check(shell.phone_scroll.get_global_rect().grow(.5).encloses(rect),"Scrolled copy button remains inside actual phone viewport")
		check(not rect.intersects(status.get_global_rect()),"Copy target never overlaps its feedback")
		var bodies=shell.page_body.find_children("*","Label",true,false).filter(func(label): return label.text==clue.body)
		check(bodies.size()==1,"Complete authored clue text remains unchanged")
		if bodies.size()==1:
			check(bodies[0].get_line_count()==bodies[0].get_visible_line_count(),"Full clue remains readable without clipped lines")
			check(bodies[0].get_global_rect().end.y<=rect.position.y,"New control does not cover clue text")
		var before=JSON.stringify(state.d); var count=emitted.size(); var routes=routed.size()
		for i in range(3): await click(copy); assert_copy_is_local(before,count,routes)
		check(clipboard.text=="三分钟离座法" and status.text.begins_with("已复制"),"Repeated copy reports verified clipboard success")
		check(status.get_line_count()==status.get_visible_line_count(),"Success feedback fits its inline label")
		await capture("earned-title-copy-"+str(viewport.x))
		shell.phone_builder.native_library.catalog_query="已有的手动输入"
		await click(copy)
		check(shell.phone_builder.native_library.catalog_query=="已有的手动输入","Copy preserves any existing manual catalogue draft")
		shell.phone_builder.native_library.catalog_query=""
		geometry.append({"viewport":str(viewport),"copyRect":str(rect),"feedbackRect":str(status.get_global_rect())})
		clipboard.available=false
		var writes=clipboard.writes; await click(copy)
		check(clipboard.writes==writes and status.text.contains("无法复制"),"Unsupported platform reports failure without attempting clipboard write")
		assert_copy_is_local(before,count,routes)
		clipboard.available=true; clipboard.reject_write=true; clipboard.text="unrelated clipboard"
		await click(copy)
		check(status.text.contains("复制未完成") and clipboard.text=="unrelated clipboard","Write/readback mismatch cannot report success")
		check(status.get_line_count()==status.get_visible_line_count(),"Failure feedback remains fully visible")
		await capture("earned-title-failure-"+str(viewport.x))
		assert_copy_is_local(before,count,routes)
		clipboard.reject_write=false
		# Stale callback checks the current gate, even if an old button still exists.
		state.d.ui.libraryFinalsPuzzle.investigationOpened=false; writes=clipboard.writes; await click(copy)
		check(clipboard.writes==writes and status.text.contains("先阅读"),"Revoked state cannot copy through a stale rendered control")
		await render(); check(node("Cc98CopyCatalogTitle")==null,"Copy disappears if investigation is not earned")
		await restore_earned()
		await click(node("Cc98CopyCatalogTitle"))
		shell.phone_scroll.scroll_vertical=0; await frames(); await click(node("Cc98BackToFeed"))
		check(node("Cc98CopyCatalogTitle")==null and node("Cc98CatalogTitleFeedback")==null,"Back dismisses local copy feedback without pending work")
		await open_clue()
		check(node("Cc98CatalogTitleFeedback").text=="可在馆藏检索中手动粘贴","Reopening reply has clean local feedback")
		await key(KEY_ESCAPE)
		check(not is_instance_valid(shell.modal) and not state.d.ui.libraryFinalsPuzzle.catalogSearchCompleted,"Cancel/Escape never searches or leaves a copy modal")
	# Manual typing and copied text pass exactly the same existing input/controller path.
	await restore_earned(); clipboard.text="三分钟离座法"
	var without_terminal=await search_from_input()
	check(without_terminal.ids.size()==5 and not without_terminal.complete,"Exact title still cannot bypass terminal evidence gate")
	await click(node("LibraryCatalogResult_three-minute-leave-method"))
	check(not state.d.items.callNumber755,"Selection before terminal still cannot award source evidence")
	controller.dispatch(earned,"lib_catalog_terminal")
	await restore_earned(); var typed=await search_from_input()
	check(typed.ids.size()==5 and typed.complete and not typed.items.callNumber755,"Manual search yields five source results but requires deliberate selection")
	var native_available=DisplayServer.has_feature(DisplayServer.FEATURE_CLIPBOARD)
	check(native_available or not OS.get_cmdline_user_args().has("--require-native-clipboard"),"Required native clipboard exists")
	if native_available:
		var previous=DisplayServer.clipboard_get()
		await restore_earned(); shell.phone_builder.earned_catalog_title=CopyTitle.new(); await open_clue()
		var before=JSON.stringify(state.d); var count=emitted.size(); var routes=routed.size()
		await click(node("Cc98CopyCatalogTitle")); assert_copy_is_local(before,count,routes)
		check(DisplayServer.clipboard_get()=="三分钟离座法","Actual OS clipboard receives source title")
		var pasted=await search_from_input(true)
		check(pasted==typed,"Native clipboard Ctrl+V and manual typing produce identical search/controller state")
		DisplayServer.clipboard_set(previous)
		print("Native clipboard copy and Ctrl+V: PASS")
	else:
		print("Native clipboard copy and Ctrl+V: SKIP (headless display; adapter failure/contract tests passed separately)")
	await shell.shutdown(); shell.queue_free(); await frames()
	print("Earned catalog title: ",checks," checks, ",failures," failures; geometry=",JSON.stringify(geometry))
	quit(1 if failures else 0)
