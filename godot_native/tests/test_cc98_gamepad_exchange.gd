extends SceneTree
const UI = preload("res://scripts/ui/native_ui_theme.gd")
## Source-phase fixtures exercise the real transaction surface and authority.
## This does not stand in for an earned manual campaign run.
var state: Node
var shell: Control
var checks := 0
var failures := 0

func _initialize() -> void: run.call_deferred()
func frames(count: int = 4) -> void:
	for i in range(count): await process_frame
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error("CC98 GAMEPAD: " + message)
func named(node: Node, value: String) -> Node:
	if node.name == value: return node
	for child in node.get_children():
		var found := named(child, value)
		if found != null: return found
	return null
func contained(inner: Rect2, outer: Rect2) -> bool:
	return outer.grow(1).encloses(inner)
func click(control: Control) -> void:
	check(control != null and control.is_visible_in_tree(), "actual visible control exists")
	if control == null: return
	var point := control.get_global_transform_with_canvas() * (control.size / 2)
	var motion := InputEventMouseMotion.new(); motion.position = point; motion.global_position = point
	Input.parse_input_event(motion); await frames(1)
	for down: bool in [true, false]:
		var event := InputEventMouseButton.new(); event.position = point; event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT; event.pressed = down
		Input.parse_input_event(event); await frames(1)
	await frames()
func fixture(viewport: Vector2i, cents: int = 600, shifted: bool = true) -> void:
	state.d = state.initial(); state.developer_mode = true
	state.d.native.chapter = 2; state.d.native.page = "cc98"
	state.d.actOne.phase = "movement_required"; state.d.actOne.dormHubUnlocked = true
	state.d.actOne.inventoryRecovered = true; state.d.items.campusCard = true
	state.d.actOne.cc98Login.authenticated = true; state.d.actOne.cc98Login.studentIdDiscovered = true
	state.d.actOne.characterNamed = true; state.d.actOne.exerciseStarted = true
	state.d.actOne.balanceShifted = shifted; state.d.wallet.campusCardCents = cents
	state.d.networkMode = "campus_wifi"
	root.size = viewport; shell.size = Vector2(viewport); shell.mobile_world = false
	shell.phone_builder.cc98_post = "act-two-gamepad-market"
	shell._refresh(); await frames()
func refresh() -> void:
	shell._refresh(); await frames()
func check_geometry(purchased: bool = false) -> void:
	var panel: Control = named(shell.page_body, "Cc98GamepadExchange")
	var button: Button = named(shell.page_body, "Cc98GamepadReturn" if purchased else "Cc98GamepadPurchase")
	check(panel != null and button != null, "market post owns its transaction surface")
	if panel == null or button == null: return
	var phone_rect: Rect2 = shell.phone.get_global_rect()
	check(shell.phone.size == Vector2(430, 860), "canonical phone frame remains unchanged")
	check(contained(button.get_global_rect(), phone_rect), "primary control stays inside actual phone bounds")
	check(contained(button.get_global_rect(), shell.phone_scroll.get_global_rect()), "primary control is in the visible app without outer scrolling")
	check(button.get_global_rect().size.y >= 44, "scaled primary control retains44px physical pointer target")
	for mode: String in ["normal","hover","pressed","hover_pressed"]:
		check(UI._contrast(Color.WHITE,button.get_theme_stylebox(mode).bg_color)>=4.5,"active purchase/return text contrast in "+mode)
	check(panel.size.y <= shell.phone_builder.APP_HEIGHT + 0.1, "app does not grow for an appended purchase action")
	check(panel.get_meta("handles_all_actions", false), "consumer suppresses generic duplicate action footer")
	check(not named(panel, "Cc98GamepadScroll").get_h_scroll_bar().visible, "post and product never overflow horizontally")
	var preview: Control = named(panel, "Cc98GamepadIllustration")
	check(preview != null and preview.size.x > 280 and preview.size.y >= 84, "source gamepad illustration has readable space")
	var drawing: Control = named(panel, "Cc98GamepadDrawing")
	check(contained(drawing.get_global_rect(), preview.get_global_rect()), "gamepad is centered inside its illustration panel")
	var recipient: Label = named(panel, "Cc98GamepadRecipient")
	check(recipient.get_line_count() == recipient.get_visible_line_count(), "all recipient text remains readable")
	check(named(panel, "Cc98GamepadPostBody").text == "方向键、摇杆和一个不太灵的 A 键都在。只收 6 元，不议价，也不接受 0.06 元分期。", "complete authored post body retained")
	check(button.text == ("回寝室试用手柄" if purchased else "支付 6 元购买手柄"), "source action copy retained")
func run() -> void:
	state = root.get_node("State"); state.developer_mode = true; state.d = state.initial()
	shell = load("res://scenes/main.tscn").instantiate(); root.add_child(shell); await frames(); shell.set_process(false)
	for viewport: Vector2i in [Vector2i(390,844), Vector2i(430,860), Vector2i(1440,900)]:
		await fixture(viewport, 6, false); check_geometry()
		check(named(shell.page_body, "Cc98GamepadBalance").text == "¥0.06", "original six-cent balance displayed")
		check(named(shell.page_body, "Cc98GamepadRecipient").text == "林星宇 · 3250100755", "owned identity matches source")
		await click(named(shell.page_body, "Cc98GamepadPurchase"))
		check(not state.d.actOne.gamepadPurchased and not state.d.items.gamepad and state.d.wallet.campusCardCents == 6, "wrong balance cannot buy or debit")
		check(str(state.last_result.message).contains("零点零六元"), "controller purchase rejection is shown by existing feedback")
		state.d.wallet.campusCardCents = 600; await refresh()
		await click(named(shell.page_body, "Cc98GamepadPurchase"))
		check(not state.d.actOne.gamepadPurchased and state.d.wallet.campusCardCents == 600, "amount alone cannot bypass balance-shift proof")
		state.d.actOne.balanceShifted = true; state.d.wallet.campusCardCents = 599; await refresh()
		await click(named(shell.page_body, "Cc98GamepadPurchase"))
		check(not state.d.actOne.gamepadPurchased and state.d.wallet.campusCardCents == 599, "one-cent short still rejects purchase")
		state.d.wallet.campusCardCents = 600; await refresh()
		await click(named(shell.page_body, "Cc98GamepadPurchase"))
		check(state.d.actOne.gamepadPurchased and state.d.items.gamepad and state.d.wallet.campusCardCents == 0, "exact six yuan buys one gamepad and debits once")
		check_geometry(true)
		check(named(shell.page_body, "Cc98GamepadFeedback").text == "支付成功：游戏手柄已放入道具栏。", "successful payment feedback matches source")
		state.act("c2_purchase_gamepad"); await frames()
		check(state.d.wallet.campusCardCents == 0 and state.d.items.gamepad, "repeated purchase intent never charges twice")
		state.d = JSON.parse_string(JSON.stringify(state.d)); await refresh()
		check(named(shell.page_body, "Cc98GamepadReturn") != null and state.d.wallet.campusCardCents == 0, "serialized purchase reopens without a second payment")
		await click(named(shell.page_body, "Cc98BackToFeed"))
		await click(named(shell.page_body, "OpenPost_act-two-gamepad-market"))
		check_geometry(true)
		check(named(shell.page_body, "Cc98GamepadPurchase") == null, "reopened purchased post offers return only")
		await click(named(shell.page_body, "Cc98GamepadReturn"))
		check(state.d.native.scene == "dorm_hub" and state.d.runtimeMode == "rpg", "return emits authoritative dorm scene intent")
		check(state.last_result.get("open_world", false) and shell.world_frame.visible and shell.mobile_world, "return reveals actual world immediately")
		check(not shell.phone.visible, "return selects the exclusive world surface")
		check(not state.d.actOne.controlsInstalled and not state.d.actOne.manualControlTested, "return does not auto-install controls or solve movement")
	await fixture(Vector2i(430,860))
	state.d.items.campusCard = false; await refresh()
	check(named(shell.page_body, "Cc98GamepadRecipient").text == "身份信息尚未读取", "unowned campus card never reveals recipient")
	state.d.items.campusCard = true; state.d.actOne.inventoryRecovered = false; await refresh()
	check(named(shell.page_body, "Cc98GamepadRecipient").text == "身份信息尚未读取", "unrecovered inventory never reveals recipient")
	await fixture(Vector2i(430,860))
	state.d.networkMode = "cellular"; await refresh()
	check(named(shell.page_body, "Cc98GamepadPurchase") == null, "wrong network cannot expose market transaction")
	state.act("c2_purchase_gamepad")
	check(not state.d.actOne.gamepadPurchased and state.d.wallet.campusCardCents == 600, "direct wrong-network intent is rejected")
	await fixture(Vector2i(430,860))
	state.d.actOne.cc98Login.authenticated = false; await refresh()
	check(named(shell.page_body, "Cc98GamepadPurchase") == null, "unauthenticated visit displays login instead of purchase")
	state.act("c2_purchase_gamepad")
	check(not state.d.actOne.gamepadPurchased and state.d.wallet.campusCardCents == 600, "direct unauthenticated intent is rejected")
	await fixture(Vector2i(430,860))
	state.d.actOne.phase = "inventory_required"; await refresh()
	check(named(shell.page_body, "Cc98GamepadPurchase") == null, "inactive phase hides the marketplace story surface")
	state.act("c2_purchase_gamepad")
	check(not state.d.actOne.gamepadPurchased and state.d.wallet.campusCardCents == 600, "direct inactive-phase intent is rejected")
	await fixture(Vector2i(430,860))
	state.d.actOne.gamepadPurchased = true; state.d.actOne.controlsInstalled = true; state.d.items.gamepad = false; state.d.wallet.campusCardCents = 0
	await refresh()
	check(named(shell.page_body, "Cc98GamepadReturn") != null and named(shell.page_body, "Cc98GamepadPurchase") == null, "consumed gamepad remains purchased on reopen")
	check(named(shell.page_body, "Cc98GamepadFeedback").text == "手柄已经连接。", "installed control status does not claim item remains in inventory")
	await fixture(Vector2i(390,844))
	var edited_body := "保留玩家编辑的正文。".repeat(120)
	shell.phone_builder.cc98_drafts["act-two-gamepad-market"] = {"body": edited_body}
	await refresh()
	check(named(shell.page_body, "Cc98GamepadPostBody").text == edited_body, "existing edited post content is preserved in full")
	check(named(shell.page_body, "Cc98GamepadScroll").get_v_scroll_bar().max_value > 800, "long edited content scrolls within the app")
	check(contained(named(shell.page_body, "Cc98GamepadPurchase").get_global_rect(), shell.phone_scroll.get_global_rect()), "long post cannot push purchase out of the visible app")
	await shell.shutdown(); shell.queue_free(); await frames()
	print("CC98 gamepad exchange: ", checks, " checks, ", failures, " failures")
	quit(1 if failures else 0)
