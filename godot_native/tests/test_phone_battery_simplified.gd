extends SceneTree
## Real Main and native pointer/key input; isolated fixtures, not campaign proof.
var state: Node
var shell: Control
var checks:=0
var failures:=0
func _initialize()->void:run.call_deferred()
func frames(count:int=4)->void:
	for unused in count:await process_frame
func check(ok:bool,message:String)->void:
	checks+=1
	if not ok:failures+=1;push_error("PHONE_BATTERY_SIMPLIFIED: "+message)
func named(id:String)->Control:return shell.find_child(id,true,false) as Control
func click(control:Control)->void:
	check(is_instance_valid(control),"visible input target exists")
	if not is_instance_valid(control):return
	var point:Vector2=control.get_global_transform_with_canvas()*(control.size/2)
	var motion:=InputEventMouseMotion.new();motion.position=point;root.push_input(motion,true)
	for down:bool in [true,false]:
		var event:=InputEventMouseButton.new();event.position=point;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down;root.push_input(event,true)
	await frames()
func key(code:Key)->void:
	for down:bool in [true,false]:
		var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=down;root.push_input(event,true)
	await frames()
func audit_removed(node:Node)->void:
	check(not str(node.name) in ["PutPhoneOnDesk","HomeChargingDock","DeskDockContact","DeskUnplug","LowPowerToggle"],"retired control absent: "+str(node.name))
	if node is Label or node is Button:
		check(not node.text.contains("充电") and not node.text.contains("低电量模式"),"no obsolete charging or power-mode instructions")
	for child:Node in node.get_children():audit_removed(child)
func fixture(page:String="phone_home",percent:int=17)->void:
	state.d=state.initial();state.d.native.page=page;state.d.phoneBattery.percent=percent
	state.d.native.settings.music=false;state.d.native.settings.effects=false
	shell._refresh();await frames();shell._layout();shell._clear_notice_presentations()
func snapshot(_id:String)->void:await frames()
func finish()->void:
	print("PHONE_BATTERY_SIMPLIFIED: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
func run()->void:
	if not load("res://tests/native_test_isolation.gd").is_isolated_save():quit(2);return
	create_timer(90).timeout.connect(func():push_error("Battery UI regression deadline");quit(2))
	# Charging has no runtime code left to instantiate, including by old saved routes.
	for retired:String in ["scripts/chapters/home_desk.gd", "scripts/media/home_charging_host.gd", "scripts/ui/home_charging_dock.gd", "scripts/media/c3_charging.gd", "scripts/media/c3_charging_session.gd", "scripts/media/c3_charging_view.gd"]:
		check(not FileAccess.file_exists("res://"+retired),"retired charging script is removed: "+retired)
	state=root.get_node("State");state.developer_mode=true;state.d=state.initial()
	check(state.d.ui.brightness==65,"new game relative brightness remains below plant requirement")
	check(state.d.phoneBattery.percent==17,"original opening battery remains17 without a recharge")
	shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames(6)
	shell.set_process(false);shell.audio_director.set_process(false);shell.audio_director.reset()
	for extent:Vector2i in [Vector2i(430,860),Vector2i(390,844),Vector2i(1440,900)]:
		root.size=extent;shell.size=Vector2(extent)
		if DisplayServer.get_name()!="headless":DisplayServer.window_set_size(extent)
		var prefix:="%dx%d-"%[extent.x,extent.y]
		await fixture("alarm")
		check(is_zero_approx(shell.phone_chrome.brightness_veil.color.a) and not shell.phone_chrome.brightness_grade.visible,"opening uses neutral65 without a dim-then-lift pass")
		await snapshot(prefix+"01-alarm-normal")
		await fixture("desktop");audit_removed(shell.page_body)
		check(named("OpeningAction_c1_wake")!=null,"ordinary wake action survives removal of charging desk")
		await snapshot(prefix+"02-wake-no-dock")
		await fixture("phone_home",1);audit_removed(shell.page_body)
		await snapshot(prefix+"03-home-one-percent")
		await click(named("ControlCenterTrigger"))
		check(is_instance_valid(shell.control_center),"Control Center opens at one percent")
		await click(named("ControlNetwork_cellular"))
		check(state.d.phoneBattery.percent==0 and state.d.ui.brightness==65,"real network action drains1 to0 without dimming")
		audit_removed(shell.control_center)
		check(named("ControlBattery").size.y==55,"battery status uses compact read-only panel")
		check(shell.phone.get_global_rect().encloses(named("ControlSaveNow").get_global_rect()),"save stays inside phone after compacting panel")
		check(is_zero_approx(shell.phone_chrome.brightness_veil.color.a) and not shell.phone_chrome.brightness_grade.visible,"zero battery preserves the current65 brightness")
		await snapshot(prefix+"04-control-zero-percent")
		for repeat in 3:
			await click(named("PhoneNav_close"));check(not is_instance_valid(shell.control_center),"Control Center repeatedly closes at0")
			await click(named("ControlCenterTrigger"));check(is_instance_valid(shell.control_center),"Control Center repeatedly reopens at0")
			await click(named("ControlNetwork_wifi") if repeat%2==0 else named("ControlNetwork_cellular"))
			check(state.d.phoneBattery.percent==0,"repeated actions do not invent reserve or negative battery")
		var brightness:Control=named("ControlBrightness");brightness.grab_focus()
		await key(KEY_DOWN)
		check(state.d.ui.brightness==55,"manual brightness still decreases via native focused input")
		brightness=named("ControlBrightness");brightness.grab_focus();await key(KEY_UP)
		check(state.d.ui.brightness==65 and is_zero_approx(shell.phone_chrome.brightness_veil.color.a) and not shell.phone_chrome.brightness_grade.visible,"manual brightness returns to65 even at0 battery")
		for step in range(4):
			brightness=named("ControlBrightness");brightness.grab_focus();await key(KEY_UP)
		check(state.d.ui.brightness==100 and is_zero_approx(shell.phone_chrome.brightness_veil.color.a) and state.d.ui.brightnessUserAdjusted,"explicit manual100 remains available and recorded at0 battery")
		await click(named("PhoneNav_close"));shell._clear_notice_presentations()
		await click(named("HomeBonsaiOpen"))
		check(state.d.native.page=="bonsai","ordinary bonsai entry remains usable at zero battery")
		audit_removed(shell.page_body)
		await snapshot(prefix+"05-bonsai-zero-percent")
		check(is_instance_valid(shell.battery_prank) and shell.battery_prank.mouse_filter==Control.MOUSE_FILTER_IGNORE and shell.get("home_charging_host")==null,"presentation-only prank never creates a charging gate")
	await shell.shutdown();shell.queue_free();await frames()
	finish()
