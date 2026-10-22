extends ScrollContainer
## Bounded text only. Wheel/touch scrolling never changes the map camera.
var label:Label
var previous_text:=""
func setup(body:Label)->void:
	label=body
	horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	vertical_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO
	mouse_filter=Control.MOUSE_FILTER_STOP
	mouse_force_pass_scroll_events=false
	label.reparent(self,false)
	label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	label.add_theme_constant_override("line_spacing",0)
	get_v_scroll_bar().custom_minimum_size.x=12
func layout_body(rect:Rect2,content_height:float)->void:
	# Font measurements, rather than a stale/subpixel container range, own
	# overflow. A fitting one-line caption must not gain a phantom scrollbar.
	vertical_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO if content_height>rect.size.y+.5 else ScrollContainer.SCROLL_MODE_DISABLED
	position=rect.position;size=rect.size
	label.custom_minimum_size=Vector2(0,content_height)
	label.size=Vector2(rect.size.x,content_height)
	if label.text!=previous_text:scroll_vertical=0;previous_text=label.text
func _gui_input(event:InputEvent)->void:
	if event is InputEventScreenDrag:
		scroll_vertical-=int(event.relative.y);accept_event()
