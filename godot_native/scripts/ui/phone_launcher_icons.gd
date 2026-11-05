extends RefCounted
## Source-Web CSS shapes adapted to the locked 24px glyph / 48px hit geometry.
## PNG, text wordmark and the interactive gear keep their source renderers in Pages.
const Ui=preload("res://scripts/ui/native_ui_theme.gd")
const FILES={"wechat":"messages","tiyi":"sports","photos":"album","timeline_recovery":"recovery","voice_memos":"voice","control_center":"controls","clock":"clock"}
const SOURCE_COLORS={"wechat":Color("61b58c"),"tiyi":Color("e8893f"),"zjuding":Color("ece9df"),"settings":Color("777989"),"photos":Color("ece9df"),"timeline_recovery":Color("173948"),"voice_memos":Color("0a0a0c"),"cc98":Color("4d7ed9"),"control_center":Color("756aa9"),"clock":Color("20272f")}
static func add_to(button:Control,id:String)->TextureRect:
	var glyph:=TextureRect.new()
	glyph.name="LauncherGlyph"
	glyph.texture=load("res://ui_assets/phone_icons/"+str(FILES[id])+".svg")
	glyph.position=Vector2(12,12);glyph.size=Vector2(24,24)
	glyph.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	glyph.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	glyph.mouse_filter=Control.MOUSE_FILTER_IGNORE
	button.add_child(glyph)
	return glyph

static func apply_feedback(button: Button, fill: Color, caption: Label) -> void:
	# Called by the actual launcher builder, not a blanket material adapter.
	# The original app art (and the independently falling cog) stays untouched.
	button.set_meta("phone_button_role","launcher")
	button.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	var states: Dictionary={
		"normal":fill,
		"hover":fill.lerp(Ui.PAPER,.24),
		"pressed":fill.lerp(Ui.INK,.24),
		"hover_pressed":fill.lerp(Ui.INK,.24),
		"disabled":fill.lerp(Ui.PAPER,.55),
	}
	var authored: StyleBoxFlat=button.get_theme_stylebox("normal")
	for state: String in states:
		var style: StyleBoxFlat=authored.duplicate()
		style.bg_color=states[state]
		style.shadow_size=0;style.shadow_offset=Vector2.ZERO;style.shadow_color=Color.TRANSPARENT
		button.add_theme_stylebox_override(state,style)
	var focus: StyleBoxFlat=button.get_theme_stylebox("focus").duplicate()
	focus.border_color=Ui.FOCUS
	button.add_theme_stylebox_override("focus",focus)
	if button.get_node_or_null("LauncherFeedback")!=null:return
	var feedback:=LauncherFeedback.new()
	feedback.name="LauncherFeedback";feedback.button=button;feedback.caption=caption
	feedback.mark_ink=Ui.INK if Ui._contrast(Ui.INK,fill)>=3.0 else Ui.PAPER
	button.add_child(feedback)

class LauncherFeedback extends Control:
	## Static ink marks give a shape cue, not only a near-identical color change.
	## Native Button owns pointer, keyboard, touch, cancellation and activation.
	var button: Button
	var caption: Label
	var mark_ink:=Color("222322")
	var visual_state: String="normal"
	var _last_focus:=false
	var _last_size:=Vector2.ZERO
	func _ready() -> void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		focus_mode=Control.FOCUS_NONE
		z_index=2
		set_process(true)
		_refresh()
	func _process(_delta: float) -> void: _refresh()
	func _refresh() -> void:
		if not is_instance_valid(button):return
		var mode:=button.get_draw_mode()
		var next: String="disabled" if button.disabled else "pressed" if mode in [BaseButton.DRAW_PRESSED,BaseButton.DRAW_HOVER_PRESSED] else "hover" if mode==BaseButton.DRAW_HOVER else "normal"
		var focused: bool=button.has_focus() and not button.disabled
		if next==visual_state and focused==_last_focus and _last_size==button.size:return
		visual_state=next;_last_focus=focused;_last_size=button.size;size=button.size
		queue_redraw()
	func _draw() -> void:
		if visual_state=="disabled" or (visual_state=="normal" and not _last_focus):return
		# Inset corner strokes remain inside the original48px app hit frame.
		var inset: float=5.0 if visual_state=="pressed" else 4.0
		var end:=size-Vector2.ONE*inset
		var stroke:=mark_ink
		draw_polyline(PackedVector2Array([Vector2(inset,inset+8),Vector2(inset,inset),Vector2(inset+9,inset)]),stroke,2,false)
		draw_polyline(PackedVector2Array([Vector2(end.x-9,end.y),end,Vector2(end.x,end.y-8)]),stroke,2,false)
		if visual_state=="pressed":
			# Pressed adds the other corners. No lift, bevel, shadow or icon shift.
			draw_polyline(PackedVector2Array([Vector2(end.x-7,inset),Vector2(end.x,inset),Vector2(end.x,inset+7)]),stroke,2,false)
			draw_polyline(PackedVector2Array([Vector2(inset,end.y-7),Vector2(inset,end.y),Vector2(inset+7,end.y)]),stroke,2,false)
		# A small drawn rule underneath the authored title ties feedback to the app.
		# It is decoration only and does not enlarge or replace the hit rectangle.
		if is_instance_valid(caption):
			var caption_local: Vector2=button.get_global_transform().affine_inverse()*caption.global_position
			var y: float=caption_local.y+caption.size.y+1
			var x: float=caption_local.x+8
			var width: float=maxf(0,caption.size.x-16)
			draw_line(Vector2(x,y),Vector2(x+width*.62,y),Color("222322"),2,false)
			draw_line(Vector2(x+width*.62,y+.5),Vector2(x+width,y+.5),Color("222322"),2,false)
