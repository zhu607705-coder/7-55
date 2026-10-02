extends SceneTree
## Run with an isolated user-data folder: godot --headless --path godot_native -s res://tests/test_phone_chrome.gd -- --fresh
const Chrome=preload("res://scripts/ui/phone_chrome.gd")
const ExistingInventoryItem=preload("res://scripts/ui/inventory_item.gd")
var failures:=0
var checks:=0
var current: Dictionary={}
var pages: Array=[]
var utilities: Array=[]
var inspections: Array=[]
var selections: Array=[]
var combinations: Array=[]
var tasks:=0
func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	checks+=1
	if not value: failures+=1; push_error("PHONE CHROME: "+message)
func run() -> void:
	var state=root.get_node("State")
	state.developer_mode=true
	current=state.initial()
	current.native.page="phone_home"
	current.currentScene="phone_home"
	current.phoneBattery.percent=100
	current.ui.brightness=70
	current.items.headphone=true
	current.items.waterDrop=true
	var parent:=Control.new(); parent.size=Vector2(424,854); root.add_child(parent)
	var chrome:=Chrome.new(); parent.add_child(chrome)
	chrome.page_requested.connect(func(id: String): pages.append(id))
	chrome.utility_requested.connect(func(id: String): utilities.append(id); current.ui.inventoryOpen=not current.ui.inventoryOpen)
	chrome.inspect_requested.connect(func(item: Dictionary): inspections.append(item))
	chrome.item_selected.connect(func(id: String): selections.append(id))
	chrome.items_combined.connect(func(a: String,b: String): combinations.append([a,b]))
	chrome.task_requested.connect(func(): tasks+=1)
	chrome.setup(func(): return current)
	await process_frame
	check(chrome.size==Vector2(424,854),"inside 3px phone border is exactly 424x854")
	check(chrome.status_bar.position==Vector2.ZERO and chrome.status_bar.size==Vector2(424,40),"40px absolute status overlay, no stacked content")
	check(chrome.task_button.position==Vector2(174,5) and chrome.task_button.size==Vector2(76,30),"compact task button centered at y=5")
	check(chrome.inventory.position==Vector2(0,240),"inventory starts left at source y240")
	check(chrome.inventory_handle.size==Vector2(38,63),"closed handle source 26px icon, padding, arrow and borders")
	check(chrome.inventory_handle.position==Vector2.ZERO and not chrome.inventory_body.visible,"inventory starts collapsed")
	check(chrome.inventory_count.text=="2","closed badge counts actual ownership")
	check(chrome.inventory_slots.get_child(0).item_id=="headphone","inventory follows authored order, not item config order")
	check(chrome.time_label.get_theme_font("font")==Chrome.PIXEL_FONT,"same local Fusion Pixel font")
	check(chrome.time_label.text=="07:55" and chrome.time_trusted,"initial trustworthy 07:55")
	check(chrome.status_icons.network=="campus_wifi" and chrome.network_label.text=="ZJUWLAN","native wifi arcs and source network name")
	check(chrome.status_icons.percent==100 and chrome.status_icons.size.x>22,"native battery has dynamic percentage and explicit drawing area")
	check(chrome.status_right.position.x+chrome.status_right.size.x==410,"network battery box exact 14px right padding")
	check(chrome.brightness_veil.color.a==0,"brightness70 leaves veil transparent")
	check(chrome.brightness_veil.z_index==55 and chrome.pixel_grid.z_index==60 and chrome.task_button.z_index==76,"source overlay stacking order")
	check(chrome.acquisition.visible==false,"restored inventory does not play a false acquisition")
	chrome.status_right.pressed.emit(); chrome.task_button.pressed.emit()
	check(pages==["control_center"] and tasks==1,"status and task emit real navigation contracts")
	chrome.inventory_handle.pressed.emit()
	await process_frame
	check(chrome.inventory_open and chrome.inventory_body.visible and utilities==["inventory_toggle"],"handle toggles expanded vertical items and emits state intent")
	check(chrome.inventory_handle.position.x==74 and chrome.inventory_handle.size.x==40,"expanded handle moves after 74px body and gains left border")
	check(chrome.inventory_body.size.x==74 and chrome.inventory_scroll.size.y==116,"source body/slot viewport sizes")
	check(chrome.inventory_slots.get_child(0).size==Vector2(52,52),"actual native item has 52x52 target")
	check(chrome.inventory_slots.get_theme_constant("separation")==8,"exact 8px vertical slot gap")
	var from_slot=chrome.inventory_slots.get_child(0)
	var target_slot=chrome.inventory_slots.get_child(1)
	check(from_slot is ExistingInventoryItem,"real native item inherits existing inventory drag contract")
	from_slot.force_drag({"kind":"inventory_item","item":"headphone"},null)
	var payload=from_slot._get_drag_data(Vector2(20,20))
	check(root.gui_get_drag_data()==payload,"native GUI drag is active with canonical payload")
	check(payload=={"kind":"inventory_item","item":"headphone"},"actual drag creates canonical item payload")
	check(target_slot._can_drop_data(Vector2.ZERO,payload),"other inventory slot accepts combine drop")
	check(not from_slot._can_drop_data(Vector2.ZERO,payload),"self-drop is rejected")
	target_slot._drop_data(Vector2.ZERO,payload)
	check(combinations==[["headphone","waterDrop"]],"drop invokes combination intent with both item IDs")
	var release:=InputEventMouseButton.new(); release.button_index=MOUSE_BUTTON_LEFT; release.pressed=false; release.position=Vector2(423,853); root.push_input(release)
	check(from_slot.artwork.pixels==Chrome.PIXEL_ICONS.headphone,"actual draggable slot uses authored pixel palette")
	chrome._activate_item("headphone")
	check(selections.back()=="headphone" and chrome.inventory_tip.text=="耳机","single click selects and names ordinary object")
	chrome._activate_item("headphone")
	check(inspections.size()==1 and inspections[0].id=="headphone","double click opens full object metadata")
	current.items.occupancyNote=true; chrome.refresh(current)
	await process_frame
	check(chrome.acquisition.visible and chrome.recent_item=="occupancyNote","new ownership starts acquisition flight")
	check(chrome._acquisition_icon.pixels==Chrome.PIXEL_ICONS.occupancyNote,"acquisition uses actual acquired item art")
	chrome._activate_item("occupancyNote")
	check(inspections.size()==2 and inspections.back().id=="occupancyNote","paper single-click opens document immediately")
	current.flags.codeScattered=true
	current.digits.d1="0"; current.digits.d2=null; current.digits.d3="9"; current.digits.d4="8"
	chrome.refresh(current)
	check(chrome.task_button.position==Vector2(144,5) and chrome.task_button.size==Vector2(136,30),"digits expand centered task trigger to exact136px")
	check(chrome.digit_hint.visible and chrome.digit_hint.text=="签到码 0 ? 9 8","source digit hint preserves the earned zero and unknown slots")
	current.phoneBattery.percent=4; current.phoneBattery.lowPowerMode=true; current.networkMode="cellular"; current.ui.brightness=0
	chrome.refresh(current)
	check(chrome.battery_number.text=="4%" and chrome.battery_number.get_theme_color("font_color")==Chrome.RED,"low percentage source red")
	check(chrome.saving_label.visible and chrome.saving_label.text=="省","low-power mode indicator")
	check(chrome.five_g.visible and chrome.status_icons.network=="cellular" and chrome.network_label.text=="流量","cellular bars and outlined 5G")
	check(is_equal_approx(chrome.brightness_veil.color.a,0.3),"zero brightness maximum veil exactly0.3")
	current.ui.brightness=35; chrome.refresh(current)
	check(is_equal_approx(chrome.brightness_veil.color.a,0.15),"source brightness70 curve at35")
	current.ui.brightness=100; current.networkMode="offline"; chrome.refresh(current)
	check(chrome.brightness_veil.color.a==0 and chrome.network_label.text=="无服务" and not chrome.five_g.visible,"full brightness and offline service")
	current.chapterThreeInterlude.completed=true; current.chapter4.prologueSeen=true; current.chapter4.phoneStatusTimeSeconds=28523; current.chapter4.phoneStatusTimeTrusted=false; chrome.refresh(current)
	check(chrome.time_label.text=="07:55:23 不可信" and not chrome.time_trusted,"chapter4 frozen time and trust warning")
	current.chapter4.phoneStatusTimeTrusted=true; current.chapter4.phoneStatusTimeSeconds=86401; chrome.refresh(current)
	check(chrome.time_label.text=="00:00:01" and chrome.time_trusted,"trusted clock uses state seconds and midnight wrap")
	current.flags.checkinDone=true; current.actOne.inventoryRecovered=false; chrome.refresh(current)
	check(not chrome.inventory.visible,"post-checkin unrecovered inventory suppressed")
	current.actOne.inventoryRecovered=true; chrome.refresh(current)
	check(chrome.inventory.visible,"recovered inventory restored")
	current.actOne.phase="friend_message_required"; current.chapterThreeInterlude.completed=false; chrome.refresh(current)
	check(not chrome.task_button.visible,"source chapter2 friend-message task suppression")
	current.actOne.phase="system_required"; chrome.refresh(current)
	check(not chrome.task_button.visible,"source chapter2 system task suppression")
	current.actOne.phase="complete"; chrome.refresh(current)
	check(chrome.task_button.visible and not chrome.digit_hint.visible,"later chapter task returns without chapter1 digits")
	for bare in ["alarm","desktop","ending"]:
		current.native.page=bare; chrome.refresh(current)
		check(not chrome.status_bar.visible and not chrome.task_button.visible and not chrome.inventory.visible,"bare scene hides shell controls: "+bare)
	current.native.page="phone_home"; current.ui.inventoryOpen=true
	for id in Chrome.ITEM_ORDER: current.items[id]=true
	chrome.refresh(current); await process_frame
	check(chrome.inventory_scroll.size.y==260 and chrome.inventory_body.size.y<=328,"many items scroll vertically in bounded source viewport")
	chrome.set_inventory_top(-500)
	check(chrome.inventory_top==108,"drag clamped to source minimum y108")
	chrome.set_inventory_top(1000)
	check(chrome.inventory_top==860-chrome.inventory.size.y-16,"drag clamped above bottom16px")
	chrome.set_input_blocked(true)
	check(chrome.status_right.disabled and chrome.task_button.disabled and chrome.inventory_handle.disabled and chrome.inventory_slots.get_child(0).disabled,"all shell controls disabled for inputBlocked")
	chrome.set_input_blocked(false)
	parent.scale=Vector2.ONE*0.8
	check(chrome.get_global_transform().get_scale()==Vector2.ONE*0.8 and chrome.size==Vector2(424,854),"scaled mobile preserves logical geometry and uniform scale")
	await create_timer(1.2).timeout
	chrome._process(0)
	check(not chrome.acquisition.visible and chrome.recent_item.is_empty(),"acquisition clears after source1150ms")
	current.items={}; chrome.refresh(current)
	check(not chrome.inventory.visible,"empty inventory produces no handle")
	parent.queue_free(); await process_frame
	print("Native phone chrome tests: ","PASS" if failures==0 else "FAIL"," (",checks," checks; ",failures," failures)")
	quit(0 if failures==0 else 1)
