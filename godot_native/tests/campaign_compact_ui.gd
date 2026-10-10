extends RefCounted
## Actual compact Main/Home/app input, using the campaign's existing State.
## No checkpoint, initial-state replacement, hidden page route, or story writes.
var runner: SceneTree
var main: Control
var previous_size: Vector2i

func begin(r: SceneTree) -> bool:
	runner=r
	runner.phone_clock_owned=false
	previous_size=r.root.size
	if is_instance_valid(r.page): r.page.free(); r.page=null
	r.root.size=Vector2i(390,844)
	main=load("res://scenes/main.tscn").instantiate()
	r.root.add_child(main)
	await flush()
	main.world.set_process(false)
	r.trace.append({"compactMainMounted":{"width":390,"height":844,"chapter":r.state.d.native.chapter,"lakePhase":r.state.d.qizhenLake.phase},"freshCampaignStateRetained":true})
	return r.check(main.size==Vector2(390,844),"actual Main mounted at compact390x844")

func close() -> void:
	if is_instance_valid(main):
		await main.shutdown()
		main.queue_free()
		await flush()
	main=null
	runner.root.size=previous_size
	runner.phone_clock_owned=true

func flush() -> void:
	await runner.process_frame
	await runner.process_frame
	await runner.process_frame

func named(id: String,from: Node=null) -> Control:
	var node: Node=main if from==null else from
	if node is Control and str(node.name)==id and not node.is_queued_for_deletion(): return node
	for child in node.get_children():
		if child.is_queued_for_deletion(): continue
		var found: Control=named(id,child)
		if found!=null: return found
	return null

func button_text(text: String,from: Node=null) -> Button:
	var node: Node=main if from==null else from
	if node is Button and node.text==text and node.is_visible_in_tree() and not node.is_queued_for_deletion(): return node
	for child in node.get_children():
		if child.is_queued_for_deletion(): continue
		var found: Button=button_text(text,child)
		if found!=null: return found
	return null

func reveal(control: Control,label: String) -> bool:
	if not runner.check(is_instance_valid(control),"compact control exists: "+label): return false
	var ancestor: Node=control.get_parent()
	while ancestor!=null:
		if ancestor is ScrollContainer: ancestor.ensure_control_visible(control)
		ancestor=ancestor.get_parent()
	await flush()
	if not runner.check(control.is_visible_in_tree(),"compact control visible: "+label): return false
	var point: Vector2=control.get_global_rect().get_center()
	if not runner.check(Rect2(Vector2.ZERO,Vector2(runner.root.size)).has_point(point),"compact hit area reachable: "+label): return false
	if control is BaseButton and not runner.check(not control.disabled,"compact button enabled: "+label): return false
	return true

func click(id: String) -> bool:
	return await click_control(named(id),id)

func click_text(text: String) -> bool:
	return await click_control(button_text(text),text)

func click_control(control: Control,label: String) -> bool:
	if not await reveal(control,label): return false
	var point: Vector2=control.get_global_rect().get_center()
	runner.trace.append({"compactPointerClick":label,"page":runner.state.d.native.page,"point":[point.x,point.y]})
	await pointer_button(point,true)
	await pointer_button(point,false)
	await flush()
	return true

func pointer_button(point: Vector2,pressed: bool) -> void:
	var event:=InputEventMouseButton.new()
	event.button_index=MOUSE_BUTTON_LEFT
	event.button_mask=MOUSE_BUTTON_MASK_LEFT if pressed else 0
	event.position=point; event.global_position=point; event.pressed=pressed
	Input.parse_input_event(event)
	await runner.process_frame

func home() -> bool:
	if main.world_frame.is_visible_in_tree() and main.mobile_back.is_visible_in_tree():
		if not await click_control(main.mobile_back,"返回手机主页"): return false
	for attempt in range(7):
		if runner.state.d.native.page=="phone_home": return runner.check(main.phone.is_visible_in_tree(),"compact Home surface visible")
		var candidate: Control=named("PhoneNav_exit")
		if candidate==null or not candidate.is_visible_in_tree(): candidate=named("TiyiLoadingExit")
		if candidate==null or not candidate.is_visible_in_tree(): candidate=named("ZjudingLoadingExit")
		if candidate==null or not candidate.is_visible_in_tree(): candidate=named("FriendChatBack")
		if candidate==null or not candidate.is_visible_in_tree(): candidate=named("PhoneNav_back")
		if candidate==null or not candidate.is_visible_in_tree(): candidate=button_text("‹")
		if (candidate==null or not candidate.is_visible_in_tree()) and runner.state.d.native.page=="zjuding":
			candidate=named("ZjudingMenu_2")
			if candidate==null or not candidate.is_visible_in_tree(): candidate=named("ZjudingProfileMenu")
		if not await click_control(candidate,"source app back/home control"): return false
	return runner.check(false,"compact app returns Home through visible navigation")

func open_app(id: String) -> bool:
	if not await home(): return false
	if not await click("HomeApp_"+id): return false
	var entry: RefCounted=runner.state.get_phone_entry_session()
	if id=="zjuding" and not entry.entry_allowed:
		if not runner.check(entry.phase=="loading","Zjuding source mount refuses cellular"): return false
		if not await click("ControlCenterTrigger"): return false
		if not await click("ControlNetwork_wifi"): return false
		if not await click_control(named("PhoneNav_close",main.control_center),"close Control Center"): return false
		if not runner.check(not entry.entry_allowed,"restoring WiFi does not rewrite mounted entry snapshot"): return false
		if not await click("ZjudingLoadingExit"): return false
		if not await click("HomeApp_zjuding"): return false
		entry=runner.state.get_phone_entry_session()
	if entry.family in ["tiyi","zjuding"] and entry.entry_allowed:
		# Source apps own a real mount loader. Wait for its normal ready event;
		# do not mutate the phase or advance a separate clock beside Main.
		var deadline:=Time.get_ticks_msec()+8000
		while entry.phase=="loading" and Time.get_ticks_msec()<deadline: await runner.process_frame
		if not runner.check(entry.phase=="ready","accepted app mount reaches ready within bounded wait"): return false
		await flush()
	return true

func inventory(opened: bool) -> bool:
	if main.phone_chrome.inventory_open!=opened:
		if not await click("InventoryHandle"): return false
	return runner.check(main.phone_chrome.inventory_open==opened,"actual compact inventory "+("opens" if opened else "closes"))

func drag_item(item: String,target_id: String) -> bool:
	if not await inventory(true): return false
	var target: Control=named(target_id)
	if not await reveal(target,target_id): return false
	var source: Control=named("Item_"+item)
	if not await reveal(source,"inventory "+item): return false
	var start: Vector2=source.get_global_rect().get_center()
	var end: Vector2=target.get_global_rect().get_center()
	await pointer_button(start,true)
	var previous: Vector2=start
	for frame in range(1,13):
		var point: Vector2=start.lerp(end,float(frame)/12)
		var motion:=InputEventMouseMotion.new()
		motion.position=point; motion.global_position=point
		motion.relative=point-previous; motion.button_mask=MOUSE_BUTTON_MASK_LEFT
		Input.parse_input_event(motion)
		previous=point
		await runner.process_frame
	var payload: Variant=runner.root.gui_get_drag_data()
	var dragging: bool=payload is Dictionary and payload.get("kind")=="inventory_item" and payload.get("item")==item
	runner.check(dragging,"actual native inventory drag payload: "+item)
	runner.trace.append({"compactInventoryDrag":{"item":item,"target":target_id,"from":[start.x,start.y],"to":[end.x,end.y],"actualPayload":payload},"page":runner.state.d.native.page})
	await pointer_button(end,false)
	await flush()
	return dragging
