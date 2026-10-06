extends SceneTree
var checks:=0
var failures:=0
var state: Node
var shell: Control
func _initialize() -> void: run.call_deferred()
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1;push_error(label)
func frames(n:=4) -> void:
	for i in range(n):await process_frame
func all_labels(n: Node) -> Array:
	var out:Array=[]
	if n is Label:out.append(n)
	for c in n.get_children():out.append_array(all_labels(c))
	return out
func run() -> void:
	state=root.get_node("State");state.d=state.initial();state.d.native.chapter=4;state.d.native.scene="duan_yongping_temporal_maze";state.d.native.mode="light"
	state.d.chapter4.phase="maintenance_repair";state.d.chapter4.prologueSeen=true;state.d.chapter4.floor="A1";state.d.chapter4.timeState="2245_maintenance";state.d.chapter4.mode="light";state.d.native.c4_context="maintenance"
	state.d.items.campusCard=true;state.d.items.shortPryBar=true
	root.size=Vector2i(1180,812);shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames();shell.world.set_process(false)
	var facts: String=JSON.stringify(state.d.chapter4.factIds);var items: String=JSON.stringify(state.d.items)
	for dims: Vector2i in [Vector2i(1180,812),Vector2i(390,844),Vector2i(430,860)]:
		root.size=dims;shell.size=Vector2(dims);shell._layout();await frames()
		for page: String in ["c4_notes","c4_device"]:
			for context: String in ["maintenance","deduction","elevator","power"]:
				state.d.native.c4_context=context;state.d.ui.inventoryOpen=false;shell._on_phone_page(page);await frames()
				var view: Dictionary=state.get_view(page);var expected: String=str(view.get("body",""));var body: Label
				for label: Label in all_labels(shell.page_body):
					if label.text==expected:body=label;break
				check(body!=null,"Original full body exists "+page+context)
				if body:
					var bounds: Rect2=body.get_global_rect();var inner: Rect2=shell.phone_content.get_global_rect();var scale: float=shell.phone.scale.x
					check(bounds.position.x>=inner.position.x+11.99*scale and bounds.end.x<=inner.end.x-11.99*scale,"Body has reading gutter on both sides "+str(dims)+page+context)
					check(body.autowrap_mode==TextServer.AUTOWRAP_WORD_SMART,"Original clue wraps inside frame")
					check(not shell.phone_chrome.inventory_handle.get_global_rect().intersects(bounds),"Collapsed bag clears clue body")
				var buttons:Array=[]
				for c in shell.page_body.get_children():
					if c is Button:buttons.append(c)
				for b: Button in buttons:
					check(not shell.phone_chrome.inventory_handle.get_global_rect().intersects(b.get_global_rect()),"Collapsed bag clears action/Return row")
				check(shell.title_label.text==str(view.get("title","7:55")),"Full original title unchanged")
				check(shell.phone.size==Vector2(430,860),"Outer phone stays authored430x860")
				check(shell.phone_chrome.inventory_handle.get_global_rect().size.x>=43.99,"Existing44physical bag target preserved")
		# Existing non-C4 fallback policies remain unchanged, including the
		# separately frozen Recovery-reading candidate that is not merged here.
		for page: String in ["cc98","phone_home","photos","c4_bio","c4_lamp"]:
			state.d.native.page=page;shell.phone_chrome.refresh(state.d);await frames(2)
			check(not shell.phone_chrome._reading_inventory_anchor(),"Unchanged bag policy for "+page)
		state.d.native.page="c4_device";state.d.ui.inventoryOpen=true;shell.phone_chrome.refresh(state.d);await frames()
		check(shell.phone_chrome.inventory_handle.size==Vector2(40,63),"Expanded drawer handle unchanged")
		check(shell.phone_chrome.inventory_body.size.x==74,"Expanded inventory body unchanged")
		state.d.ui.inventoryOpen=false;shell.phone_chrome.refresh(state.d);await frames()
		check(shell.phone_chrome._reading_inventory_anchor(),"Closing drawer restores C4 reading anchor")
	check(JSON.stringify(state.d.chapter4.factIds)==facts and JSON.stringify(state.d.items)==items,"Layout never grants facts or changes inventory")
	shell.queue_free();await frames();print("C4_READING_CLEARANCE ",checks," checks; ",failures," failures");quit(1 if failures else 0)
