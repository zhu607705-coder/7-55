extends "res://tests/test_phone_app_scroll_shell.gd"
## Send raw touch through Input, including the engine's normal mouse emulation.
## The temporary touch capability is test-only; production input settings stay unchanged.
func touch(point: Vector2,down: bool,canceled: bool=false) -> void:
	var event:=InputEventScreenTouch.new();event.index=0;event.position=point;event.pressed=down;event.canceled=canceled
	Input.parse_input_event(event);Input.flush_buffered_events();await frames(2)
func swipe(start: Vector2,end: Vector2) -> void:
	await touch(start,true)
	for i in range(1,11):
		var event:=InputEventScreenDrag.new();event.index=0;event.position=start.lerp(end,i/10.0);event.relative=(end-start)/10.0
		Input.parse_input_event(event);Input.flush_buffered_events();await frames(2)
	await touch(end,false);await create_timer(.35).timeout;await frames()
func tap(target: Control) -> void:
	check(target!=null and target.is_visible_in_tree(),"raw touch target exists")
	if target==null: return
	var point:=rect(target).get_center()
	await touch(point,true);await touch(point,false);await frames()
func run() -> void:
	var old_mouse: bool=Input.emulate_mouse_from_touch
	var old_touch: bool=Input.emulate_touch_from_mouse
	Input.emulate_mouse_from_touch=true
	# Headless DisplayServer reports this test capability via the same official
	# Input flag used for desktop touch emulation. Events below remain raw touch.
	Input.emulate_touch_from_mouse=true
	check(DisplayServer.is_touchscreen_available(),"fixture exercises the engine's touch-enabled ScrollContainer path")
	state=root.get_node("State");fixture();root.size=Vector2i(390,844)
	shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames()
	shell.set_process(false);shell.world.set_process(false)
	for viewport: Vector2i in [Vector2i(390,844),Vector2i(430,860),Vector2i(360,640)]:
		root.size=viewport;shell.size=Vector2(viewport);fixture();shell.mobile_world=false;shell._refresh();await frames()
		await tap(node("HomeApp_cc98"))
		var scroll: ScrollContainer=node("Cc98LoginScroll")
		check(scroll!=null,"raw home touch opens authentication")
		if scroll==null: continue
		var exit_button: Button=node("Cc98LoginExit")
		var header_rect:=rect(exit_button);var phone_rect:=rect(shell.phone)
		var story:=JSON.stringify({"items":state.d.items,"actOne":state.d.actOne})
		var area:=rect(scroll)
		# Negative control reproduces the former authored-canvas blocker in this
		# instance only, so a mouse-wheel surrogate cannot satisfy this test.
		var content: Control=node("Cc98ReadCampusCard").get_parent()
		content.mouse_filter=Control.MOUSE_FILTER_STOP
		await swipe(area.position+area.size*Vector2(.84,.75),area.position+area.size*Vector2(.84,.35))
		check(scroll.scroll_vertical==0,"former STOP canvas blocks the same raw touch sequence")
		content.mouse_filter=Control.MOUSE_FILTER_PASS
		# This is the same within-page diagonal-free swipe used by Web acceptance.
		await swipe(area.position+area.size*Vector2(.84,.75),area.position+area.size*Vector2(.84,.35))
		check(scroll.scroll_vertical>0,"raw screen swipe scrolls the actual authentication body "+str(viewport))
		check(rect(exit_button).is_equal_approx(header_rect) and shell.phone_scroll.scroll_vertical==0,"touch scroll leaves the header and outer viewport fixed")
		check(rect(shell.phone).is_equal_approx(phone_rect),"touch scroll never changes phone size or position")
		check(JSON.stringify({"items":state.d.items,"actOne":state.d.actOne})==story,"swiping does not trigger a card or identity action")
		# A vertical swipe starting on the actual card button must cancel its
		# press rather than reading the card on release.
		scroll.scroll_vertical=0;await frames()
		var reader: Button=node("Cc98ReadCampusCard")
		var start:=rect(reader).get_center()
		await swipe(start,start-Vector2(0,110))
		check(scroll.scroll_vertical>0,"raw swipe can start over an interactive card")
		check(not state.d.actOne.cc98Login.studentIdDiscovered,"dragging the card button never activates it")
		await tap(reader)
		check(state.d.actOne.cc98Login.studentIdDiscovered,"a stationary raw touch still reads the original campus card")
		scroll=node("Cc98LoginScroll");area=rect(scroll)
		await swipe(area.position+area.size*Vector2(.84,.75),area.position+area.size*Vector2(.84,.25))
		var reply: Button=node("Cc98RevealHint")
		check(rect(scroll).grow(1).encloses(rect(reply)),"touch scroll exposes the complete original reply control")
		await tap(reply)
		check(state.d.actOne.cc98Login.revealedHintCount==1,"stationary touch replies through the existing controller once")
		scroll=node("Cc98LoginScroll");area=rect(scroll)
		await swipe(area.position+area.size*Vector2(.84,.35),area.position+area.size*Vector2(.84,.75))
		check(scroll.scroll_vertical==0,"reverse raw swipe returns to the original form")
		await tap(node("Cc98LoginExit"))
		check(state.d.native.page=="phone_home","raw touch still activates the fixed top-left exit after scrolling")
	await shell.shutdown();shell.queue_free();await frames()
	Input.emulate_mouse_from_touch=old_mouse;Input.emulate_touch_from_mouse=old_touch
	print("CC98_AUTH_TOUCH_SCROLL: %d checks, %d failures" % [checks,failures])
	quit(0 if failures==0 else 1)
