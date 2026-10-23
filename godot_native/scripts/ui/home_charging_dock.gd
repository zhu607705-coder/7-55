extends Control
## Small physical object, independent hit surfaces, read-only charging feedback.
const FONT = preload("res://scripts/ui/native_typography.gd")
var desk: RefCounted
var authority: Dictionary
var charge_button: Button
var status: Label
var pickup: Button
var unplug: Button
var flowing := false
var phone_art: Control

class PhoneBody extends Control:
	func _draw() -> void:
		draw_rect(Rect2(9, 3, 48, 91), Color("293038"))
		draw_rect(Rect2(12, 12, 42, 69), Color("dbdfcf"))
		draw_rect(Rect2(28, 86, 10, 3), Color("b7c3ba"))
		draw_rect(Rect2(26, 7, 14, 2), Color("8d9c92"))

func configure(controller: RefCounted, charge: Callable, cancel_charge: Callable, take_phone: Callable, state: Dictionary) -> void:
	desk = controller; authority = state
	size = Vector2(218, 174); mouse_filter = Control.MOUSE_FILTER_IGNORE
	var artwork := TextureRect.new()
	artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	artwork.name = "DockBody"; artwork.texture = load("res://assets/ui/home_charging_dock.png")
	artwork.position = Vector2(64, 0); artwork.size = Vector2(144, 144)
	artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	artwork.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST; artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(artwork)
	# This area surrounds the rendered USB/front body, not the transparent cable canvas.
	charge_button = _target("DeskDockContact", Rect2(100, 54, 76, 58), "接入桌面充电座")
	charge_button.pressed.connect(charge)
	phone_art = PhoneBody.new(); phone_art.position = Vector2(6, 35); phone_art.size = Vector2(66, 100)
	phone_art.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(phone_art)
	pickup = _target("DeskPhonePickup", Rect2(6, 35, 66, 100), "拿起手机，返回原页面")
	pickup.pressed.connect(take_phone)
	unplug = _target("DeskUnplug", Rect2(75, 107, 44, 32), "拔下充电线，取消补电")
	unplug.pressed.connect(cancel_charge)

	status = Label.new(); status.name = "DeskChargingStatus"; FONT.apply_body(status)
	status.position = Vector2(0, 142); status.size = Vector2(218, 28)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.add_theme_font_size_override("font_size", 12); status.add_theme_color_override("font_color", Color("526b57"))
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(status)
	_process(0)

func _target(id: String, rect: Rect2, hint: String) -> Button:
	var button := Button.new(); button.name = id; button.position = rect.position; button.size = rect.size
	button.tooltip_text = hint
	for style in ["normal", "hover", "pressed", "disabled"]: button.add_theme_stylebox_override(style, StyleBoxEmpty.new())
	add_child(button)
	return button

func _process(_delta: float) -> void:
	if desk == null or not is_instance_valid(status): return
	var can_pickup: bool = desk.returning(authority)
	pickup.visible = can_pickup
	var session: RefCounted = desk.session
	var active: bool = session != null and session.phase in ["issued", "charging"]
	unplug.visible = active; phone_art.visible = can_pickup or active
	flowing = active
	queue_redraw()
	status.text = "连接 %d%% · 电量 %d%%" % [int(session.elapsed_ms / 22.0), int(authority.phoneBattery.percent)] if active else "补电完成 · %d%%" % int(authority.phoneBattery.percent) if session != null and session.phase == "consumed" else "接线已断开" if session != null and session.phase == "cancelled" else ""

func _draw() -> void:
	if not flowing: return
	draw_polyline(PackedVector2Array([Vector2(39, 129), Vector2(39, 135), Vector2(122, 135), Vector2(122, 105)]), Color("6a776b"), 2.0, false)
	# Separate active connector/contact: the dock body always means start, never
	# toggle, so duplicate dispatch cannot turn a valid start into cancellation.
	draw_rect(Rect2(88, 121, 17, 8), Color("33483d"))
	draw_rect(Rect2(105, 123, 6, 4), Color("b3b7a0"))
