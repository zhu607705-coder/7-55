extends SceneTree
## Real Main and physical wheel/pointer input. An app's inner scroll must not
## move its fixed header or add a second scene-return row below the phone.
var state: Node
var shell: Control
var checks:=0
var failures:=0

func _initialize() -> void: run.call_deferred()
func frames(count: int=4) -> void:
	for i in range(count): await process_frame
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error("PHONE SCROLL SHELL: "+message)
func node(id: String) -> Node: return shell.page_body.find_child(id,true,false)
func rect(target: Control) -> Rect2:
	var transform:=target.get_global_transform_with_canvas()
	return Rect2(transform.origin,target.size*transform.get_scale())
func click(target: Control) -> void:
	check(target!=null and target.is_visible_in_tree(),"physical pointer target exists")
	if target==null: return
	var point:=rect(target).get_center()
	check(Rect2(Vector2.ZERO,Vector2(root.size)).has_point(point),"physical pointer target is in viewport")
	var motion:=InputEventMouseMotion.new();motion.position=point;motion.global_position=point;root.push_input(motion,true)
	await frames(2)
	for down: bool in [true,false]:
		var event:=InputEventMouseButton.new();event.position=point;event.global_position=point
		event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down;event.button_mask=MOUSE_BUTTON_MASK_LEFT if down else 0
		Input.parse_input_event(event);Input.flush_buffered_events();await frames(1)
	await frames()
func wheel(target: Control,button: MouseButton,count: int) -> void:
	var area:=rect(target)
	var point:=area.position+area.size*Vector2(.82,.55)
	for i in range(count):
		var event:=InputEventMouseButton.new();event.position=point;event.global_position=point
		event.button_index=button;event.pressed=true;event.factor=1.0
		root.push_input(event,true)
		# Synthetic wheel input needs a complete press/release pair. Leaving
		# a wheel press active can capture later clicks in headless fixtures.
		var release:=event.duplicate();release.pressed=false;root.push_input(release,true)
		await frames(1)
	await frames()
func fixture() -> void:
	state.d=state.initial();state.developer_mode=true
	state.d.native.chapter=2;state.d.native.scene="dorm_hub";state.d.native.page="phone_home"
	state.d.rpgScene="dorm_hub";state.d.runtimeMode="phone"
	state.d.actOne.phase="movement_required";state.d.actOne.movementEnabled=true;state.d.actOne.inventoryRecovered=true
	state.d.items.campusCard=true;state.d.networkMode="campus_wifi"
	state.d.flags.codeScattered=true;state.d.flags.checkinDone=true
func app_geometry(label: String,phone_rect: Rect2) -> void:
	check(shell.phone.size==Vector2(430,860),label+" retains the canonical phone dimensions")
	check(rect(shell.phone).is_equal_approx(phone_rect),label+" preserves the same visible phone frame")
	check(shell.page_body.get_child_count()==1,label+" has exactly one source app surface")
	check(shell.page_body.get_child(0).get_meta("source_page",false),label+" uses source app ownership")
	check(shell.page_body.find_children("*","Button",true,false).all(func(button):return button.text!="返回现场"),label+" has no duplicate scene-return row")
	check(shell.phone_world_return.is_visible_in_tree(),label+" retains the actual bottom-right map icon")
	check(shell.phone_scroll.scroll_vertical==0,label+" leaves the outer shell at its top")
	var bar: VScrollBar=shell.phone_scroll.get_v_scroll_bar()
	check(bar.max_value-bar.page<=1.0,label+" does not create outer shell overflow")
func run() -> void:
	state=root.get_node("State");fixture()
	root.size=Vector2i(430,860)
	shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames()
	shell.set_process(false);shell.world.set_process(false)
	for viewport: Vector2i in [Vector2i(390,844),Vector2i(430,860),Vector2i(1440,900)]:
		root.size=viewport;shell.size=Vector2(viewport);fixture();shell.mobile_world=false;shell._refresh();await frames()
		var phone_rect:=rect(shell.phone)
		await click(node("HomeApp_cc98"))
		var inner: ScrollContainer=node("Cc98LoginScroll")
		var exit_button: Button=node("Cc98LoginExit")
		check(inner!=null and exit_button!=null,"actual Main mounts the unauthenticated CC98 page at "+str(viewport))
		if inner==null or exit_button==null: continue
		app_geometry("authentication initial",phone_rect)
		var exit_rect:=rect(exit_button)
		var story:=JSON.stringify({"items":state.d.items,"actOne":state.d.actOne})
		await wheel(inner,MOUSE_BUTTON_WHEEL_DOWN,24)
		var bar: VScrollBar=inner.get_v_scroll_bar()
		check(inner.scroll_vertical>0,"real wheel scrolls the authentication conversation")
		check(absf(float(inner.scroll_vertical)-(bar.max_value-bar.page))<=1.0,"real wheel reaches the actual inner bottom")
		check(rect(exit_button).is_equal_approx(exit_rect),"fixed exit does not move when the inner conversation reaches bottom")
		app_geometry("authentication bottom",phone_rect)
		await wheel(inner,MOUSE_BUTTON_WHEEL_DOWN,12)
		check(rect(exit_button).is_equal_approx(exit_rect) and shell.phone_scroll.scroll_vertical==0,"overscroll never hands movement to the outer app header")
		await wheel(inner,MOUSE_BUTTON_WHEEL_UP,24)
		check(inner.scroll_vertical==0 and rect(exit_button).is_equal_approx(exit_rect),"real wheel returns to the form without moving the header")
		await wheel(inner,MOUSE_BUTTON_WHEEL_DOWN,24)
		check(JSON.stringify({"items":state.d.items,"actOne":state.d.actOne})==story,"scrolling leaves all identity facts and items unchanged")
		await click(exit_button)
		check(state.d.native.page=="phone_home","fixed top-left exit works while inner conversation is at its bottom")
		for app: String in ["settings","tiyi","zjuding","wechat"]:
			await click(node("HomeApp_"+app))
			check(state.d.native.page==app,"actual home icon opens "+app)
			app_geometry(app,phone_rect)
			await wheel(shell.page_body.get_child(0),MOUSE_BUTTON_WHEEL_DOWN,8)
			app_geometry(app+" after wheel",phone_rect)
			# The shared map control is the same input used by real compact
			# devices; returning must retain the existing world checkpoint.
			var scene: String=state.d.native.scene
			await click(shell.phone_world_return)
			check(shell.world_frame.is_visible_in_tree() and state.d.native.scene==scene,"shared map icon returns from "+app+" without changing scene")
			await click(shell.mobile_back)
			check(state.d.native.page=="phone_home" and shell.phone.is_visible_in_tree(),"world phone icon restores home after "+app)
			check(rect(shell.phone).is_equal_approx(phone_rect),"round trip preserves phone scale and placement")
	await shell.shutdown();shell.queue_free();await frames()
	print("PHONE_APP_SCROLL_SHELL: %d checks, %d failures" % [checks,failures])
	quit(0 if failures==0 else 1)
