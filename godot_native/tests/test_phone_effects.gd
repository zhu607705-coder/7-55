extends SceneTree
const Pages = preload("res://scripts/ui/phone_pages.gd")
const Chapter = preload("res://scripts/chapters/chapter1_2.gd")
var pages = Pages.new()
var chapter = Chapter.new()
var state: Dictionary
var failed = 0
func _process(delta: float) -> bool:
	# Standalone factory fixture supplies the same persistent host clock as Main.
	if not state.is_empty():
		var clock: RefCounted=chapter.phone_entry_session(state)
		for event: Dictionary in clock.advance(delta*1000):
			if event.has("action"): chapter.dispatch(state,str(event.action),event.get("value"))
	return false

func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	state = JSON.parse_string(FileAccess.get_file_as_string("res://data/initial_state.json"))
	state.native = {"chapter":1,"page":"phone_home","scene":"","mode":"light","selected_item":""}
	pages.action_requested.connect(func(id,value): chapter.dispatch(state,id,value))
	state.ui.autoRotate = true
	var home = pages.build("phone_home",chapter.view("phone_home",state),state)
	root.add_child(home)
	await create_timer(1.75).timeout
	if not state.flags.gearFallen:
		failed += 1
		push_error("Actual native gear tween did not publish valid elapsed result")
	home.queue_free()
	await process_frame
	state.flags.codeScattered = true
	state.ui.autoRotate = true
	state.native.page = "wechat"
	var wechat = pages.build("wechat",chapter.view("wechat",state),state)
	root.add_child(wechat)
	await create_timer(1.35).timeout
	if not state.flags.slashHalfDropped:
		failed += 1
		push_error("Actual native avatar tween did not publish valid elapsed result")
	wechat.queue_free()
	await process_frame
	# Tower inventory drop starts insertion; only the completed native timeline consumes it.
	state.native.page="phone_home"
	state.items.towerKey=true
	var tower_home=pages.build("phone_home",chapter.view("phone_home",state),state)
	root.add_child(tower_home)
	await process_frame
	var tower=tower_home.find_child("TowerDropTarget",true,false)
	tower._drop_data(Vector2(10,10),{"kind":"inventory_item","item":"towerKey"})
	if not state.native.get("tower_key_pending",false) or state.flags.towerOpened:
		failed+=1; push_error("Tower drop must start an uncommitted key animation")
	tower_home.free()
	var animated=pages.build("phone_home",chapter.view("phone_home",state),state)
	root.add_child(animated)
	await create_timer(1.9).timeout
	if not state.flags.towerOpened or state.items.towerKey or not state.items.fertilizer:
		failed+=1; push_error("Tower 650ms insertion plus rotation did not commit the item transformation")
	animated.free()
	# Actual friend-chat start / skip / flying digits / laugh timeline.
	state.flags.codeScattered=false
	state.native.page="wechat"
	pages.entry_session=chapter.phone_entry_session(state)
	chapter.dispatch(state,"c1_friend")
	pages.friend_open=true
	var friend=pages.build("wechat",chapter.view("wechat",state),state)
	root.add_child(friend)
	await create_timer(2.1).timeout
	if state.flags.codeScattered:
		failed+=1; push_error("Code scattered before the authored attack completed")
	await create_timer(2.15).timeout
	var skip=friend.find_child("FriendAttackSkip",true,false)
	if skip.mouse_filter!=Control.MOUSE_FILTER_STOP:
		failed+=1; push_error("Attack skip was not enabled after 4 seconds")
	skip.pressed.emit()
	await create_timer(5.6).timeout
	if not state.flags.codeScattered:
		failed+=1; push_error("Skipped attack still must finish the authored laugh and scatter")
	friend.free()
	print("PHONE_EFFECT_TESTS: 4 timelines checked; %d failures" % failed)
	quit(1 if failed else 0)
