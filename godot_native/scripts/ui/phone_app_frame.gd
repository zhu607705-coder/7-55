extends Control
## One phone-local navigation bar, one scroll owner and a contextual action bar.
## No progression, save, network or playback authority lives in this frame.
signal back_requested
signal scroll_changed(value: float)
const Typography = preload("res://scripts/ui/native_typography.gd")
const NativeUi = preload("res://scripts/ui/native_ui_theme.gd")
const Palette = preload("res://scripts/ui/phone_palette.gd")
const Symbols = preload("res://scripts/ui/native_symbol_icon.gd")
const PAPER := Palette.BACKGROUND
const INK := Palette.INK
const MUTED := Palette.MUTED
const LINE := Palette.LINE
const EXTENT := Vector2(424,814)
const NAV_HEIGHT := 56
const READING_INSET := 18
var background: ColorRect
var toolbar: Control
var back_button: Button
var title_label: Label
var subtitle_label: Label
var scroll: ScrollContainer
var content_margin: MarginContainer
var content: VBoxContainer
var footer: VBoxContainer
var footer_margin: MarginContainer
var footer_background: ColorRect
var _reading_touch := -1
var _reading_start := 0.0
var _reading_scroll := 0
var _reading_dragging := false


func _init() -> void:
	custom_minimum_size=EXTENT
	size=EXTENT
	clip_contents=true
	set_meta("source_page",true)
	set_meta("handles_all_actions",true)
	var backdrop := ColorRect.new();background=backdrop
	backdrop.color=PAPER;backdrop.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(backdrop);backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	toolbar=Control.new();toolbar.name="PhoneAppToolbar";add_child(toolbar)
	var navigation_background := ColorRect.new();navigation_background.name="PhoneAppToolbarBackground"
	navigation_background.color=Palette.CHROME;navigation_background.mouse_filter=Control.MOUSE_FILTER_IGNORE
	toolbar.add_child(navigation_background);navigation_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	back_button=Button.new();back_button.name="PhoneAppBack"
	back_button.set_meta("phone_button_role","navigation")
	Typography.apply_body(back_button)
	back_button.position=Vector2(8,6);back_button.size=Vector2(44,44)
	back_button.pressed.connect(func() -> void: back_requested.emit());toolbar.add_child(back_button)
	title_label=make_label("",20,INK);title_label.position=Vector2(60,6);title_label.size=Vector2(304,26);toolbar.add_child(title_label)
	title_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	title_label.autowrap_mode=TextServer.AUTOWRAP_OFF;title_label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;title_label.clip_text=true
	subtitle_label=make_label("",14,MUTED);subtitle_label.clip_text=true;subtitle_label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;subtitle_label.position=Vector2(60,32);subtitle_label.size=Vector2(304,18);toolbar.add_child(subtitle_label)
	subtitle_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var rule := ColorRect.new();rule.color=LINE;rule.mouse_filter=Control.MOUSE_FILTER_IGNORE;toolbar.add_child(rule)
	rule.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE);rule.offset_top=-1
	scroll=ScrollContainer.new();scroll.name="PhoneAppScroll";scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_SHOW_NEVER;add_child(scroll)
	scroll.get_v_scroll_bar().value_changed.connect(func(value: float) -> void: scroll_changed.emit(value))
	var inset := MarginContainer.new();content_margin=inset;inset.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	inset.add_theme_constant_override("margin_left",READING_INSET);inset.add_theme_constant_override("margin_right",READING_INSET)
	inset.add_theme_constant_override("margin_top",READING_INSET);inset.add_theme_constant_override("margin_bottom",24);scroll.add_child(inset)
	content=VBoxContainer.new();content.size_flags_horizontal=Control.SIZE_EXPAND_FILL;content.add_theme_constant_override("separation",16);inset.add_child(content)
	footer_background=ColorRect.new();footer_background.name="PhoneAppActionBackground";footer_background.color=Palette.CHROME
	footer_background.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(footer_background)
	footer_margin=MarginContainer.new();footer_margin.name="PhoneAppActionBar";add_child(footer_margin)
	footer_margin.add_theme_constant_override("margin_left",READING_INSET);footer_margin.add_theme_constant_override("margin_right",READING_INSET)
	footer_margin.add_theme_constant_override("margin_top",12);footer_margin.add_theme_constant_override("margin_bottom",18)
	footer=VBoxContainer.new();footer.add_theme_constant_override("separation",8);footer_margin.add_child(footer)
	footer.minimum_size_changed.connect(_layout.call_deferred);resized.connect(_layout)
	configure("","")

static func make_label(copy: String, font_size: int, color: Color) -> Label:
	var result := Label.new();Typography.apply_body(result);result.text=copy
	result.add_theme_font_size_override("font_size",font_size);result.add_theme_color_override("font_color",color)
	result.mouse_filter=Control.MOUSE_FILTER_IGNORE;return result

func _ready() -> void:
	set_process_input(false)
	_layout()

func enable_touch_reading() -> void:
	# Godot's emulated mouse scroll can be intercepted by chat bubbles and cards.
	# Opt in only where the investigation owns the vertical reading surface.
	ready.connect(func() -> void: set_process_input(true))

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or scroll.vertical_scroll_mode==ScrollContainer.SCROLL_MODE_DISABLED:
		_reading_touch=-1
		_reading_dragging=false
		return
	if event is InputEventScreenTouch:
		if event.pressed and _reading_touch<0:
			var bar := scroll.get_v_scroll_bar()
			var bounds := scroll.get_global_transform_with_canvas() * Rect2(Vector2.ZERO,scroll.size)
			if bar.max_value<=bar.page or not bounds.has_point(event.position): return
			for child_name: String in ["C35ChoiceSheet","C35GroupSettingsView","C35NoteDrawer"]:
				if has_node(child_name): return
			var seek_bar := content.find_child("C35RecordingSeek",true,false) as Control
			if seek_bar!=null and (seek_bar.get_global_transform_with_canvas()*Rect2(Vector2.ZERO,seek_bar.size)).has_point(event.position): return
			_reading_touch=event.index
			_reading_start=event.position.y
			_reading_scroll=scroll.scroll_vertical
		elif event.index==_reading_touch and (not event.pressed or event.canceled):
			_reading_touch=-1
			if _reading_dragging: scroll.propagate_notification(Control.NOTIFICATION_SCROLL_END)
			_reading_dragging=false
	elif event is InputEventScreenDrag and event.index==_reading_touch:
		var scale_y := maxf(.001,absf(scroll.get_global_transform_with_canvas().get_scale().y))
		var delta: float=(event.position.y-_reading_start)/scale_y
		if not _reading_dragging:
			if absf(delta)<10: return
			_reading_dragging=true
			scroll.propagate_notification(Control.NOTIFICATION_SCROLL_BEGIN)
		scroll.scroll_vertical=_reading_scroll-roundi(delta)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and event.device==InputEvent.DEVICE_ID_EMULATION and _reading_dragging:
		get_viewport().set_input_as_handled()

func configure(title: String, subtitle: String, offset: int=0, exits: bool=false) -> void:
	title_label.text=title;subtitle_label.text=subtitle
	subtitle_label.visible=not subtitle.is_empty()
	title_label.position.y=6 if subtitle_label.visible else 15
	back_button.text="×" if exits else "‹"
	NativeUi.apply_button(back_button,Color.TRANSPARENT,INK,Color.TRANSPARENT,0,0,24,Vector2.ZERO)
	var has_symbol := Symbols.apply(back_button,back_button.text,INK,20)
	var symbol := back_button.get_node_or_null("NativeSymbolIcon") as Control
	if symbol!=null:symbol.visible=has_symbol
	back_button.tooltip_text="退出，返回手机主页" if exits else "返回上一页"
	back_button.accessibility_name=back_button.tooltip_text
	back_button.set_meta("phone_nav_kind","exit" if exits else "back")
	back_button.set_meta("phone_nav_label",back_button.tooltip_text)
	scroll.set_deferred("scroll_vertical",offset)

func _layout() -> void:
	toolbar.size=Vector2(size.x,NAV_HEIGHT)
	var footer_height := footer.get_combined_minimum_size().y+30 if footer.get_child_count()>0 else 0.0
	footer_margin.visible=footer_height>0
	footer_margin.position=Vector2(0,size.y-footer_height);footer_margin.size=Vector2(size.x,footer_height)
	footer_background.visible=footer_margin.visible;footer_background.position=footer_margin.position;footer_background.size=footer_margin.size
	scroll.position=Vector2(0,NAV_HEIGHT);scroll.size=Vector2(size.x,maxf(1,size.y-NAV_HEIGHT-footer_height))
