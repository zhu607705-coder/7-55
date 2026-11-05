extends Control
## One replaceable, phone-local receipt. No story, queue or save authority.
## A node-owned clock cannot dismiss a later notice after this one is replaced.
const Notice=preload("res://scripts/ui/native_phone_notice.gd")
const Ui=preload("res://scripts/ui/native_ui_theme.gd")
class CloseButton extends Button:
	func _draw() -> void:
		var center:=size/2
		draw_line(center+Vector2(-5,-5),center+Vector2(5,5),Notice.INK,2)
		draw_line(center+Vector2(-5,5),center+Vector2(5,-5),Notice.INK,2)
var card: Label
var close_button: Button
var remaining:=2.2
var previous_focus: WeakRef

func show_message(text: String,width: float,speaker: String="系统") -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	set_meta("phone_local_notice",true)
	var focused:=get_viewport().gui_get_focus_owner()
	if is_instance_valid(focused): previous_focus=weakref(focused)
	card=Notice.create(text,speaker)
	card.set_meta("notice_close_space",36)
	add_child(card)
	size=Notice.layout(card,width)
	close_button=CloseButton.new(); close_button.name="PhoneNoticeClose"
	close_button.position=Vector2(width-40,4); close_button.size=Vector2(36,32)
	close_button.tooltip_text="关闭提示"; close_button.set_meta("tactile_exempt",true)
	close_button.set_meta("phone_button_role","navigation")
	Ui.apply_button(close_button,Color.TRANSPARENT,Notice.INK,Color.TRANSPARENT,0,0,14,Vector2.ZERO)
	close_button.pressed.connect(dismiss)
	add_child(close_button)
	remaining=maxf(2.2,float(text.length())*.075)

func dismiss() -> void:
	if not visible: return
	if close_button.has_focus() and previous_focus!=null:
		var focused=previous_focus.get_ref()
		if is_instance_valid(focused) and focused.is_visible_in_tree(): focused.grab_focus()
	hide()
	queue_free()

func _process(delta: float) -> void:
	remaining=maxf(0,remaining-delta)
	if remaining<=0: dismiss()

func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_ESCAPE:
		dismiss(); get_viewport().set_input_as_handled()
