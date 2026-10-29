extends Control
## Formal optional reading activity: native vectors, no browser frame or reward.
signal cancelled
const Card=preload("res://scripts/games/library_geometry/card.gd")
static var intro_seen:=false
var cards:Array=[]
var scroll:ScrollContainer
var page:Control
var grid:GridContainer
var back:Button
var suspended:=false
var disposed:=false
var reduced:=false
var intro_play:=false
var setting_reduced:=false
var media_query:JavaScriptObject
var media_callback:JavaScriptObject

func _ready()->void:
	var session_seen=intro_seen
	if OS.has_feature("web"):
		# This is only a presentation-once flag, never a gameplay/save fact.
		session_seen=session_seen or bool(JavaScriptBridge.eval("(function(){try{const k='755.library.geometry.entrance.v1';const seen=sessionStorage.getItem(k)==='1';sessionStorage.setItem(k,'1');return seen}catch(e){return false}})()",true))
		media_query=JavaScriptBridge.get_interface("window").matchMedia("(prefers-reduced-motion: reduce)")
		media_callback=JavaScriptBridge.create_callback(_motion_changed)
		media_query.addEventListener("change",media_callback)
	intro_play=not session_seen;intro_seen=true
	mouse_filter=Control.MOUSE_FILTER_STOP
	var paper=ColorRect.new();paper.color=Color("f8f8f5");paper.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(paper);paper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var font=FontVariation.new();font.base_font=load("res://assets/native/library_geometry/InterVariable.woff2")
	font.fallbacks=[load("res://scripts/ui/native_typography.gd").body_font()]
	var ui=Theme.new();ui.default_font=font;theme=ui
	scroll=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scroll.focus_mode=Control.FOCUS_NONE;scroll.follow_focus=true
	add_child(scroll);scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page=Control.new();page.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(page)
	grid=GridContainer.new();grid.columns=3;grid.add_theme_constant_override("h_separation",12);grid.add_theme_constant_override("v_separation",12);page.add_child(grid)
	for kind:int in 3:
		var card=Card.new();card.kind=kind;card.size_flags_horizontal=Control.SIZE_EXPAND_FILL;grid.add_child(card)
		card.sketch.intro_play=intro_play;cards.append(card)
	back=Button.new();back.text="‹";back.tooltip_text="返回图书馆";back.accessibility_name=back.tooltip_text
	back.flat=true;back.pressed.connect(_leave);add_child(back)
	preload("res://scripts/ui/native_symbol_icon.gd").apply(back,"‹",Color("393c38"),22)
	var back_focus=StyleBoxFlat.new();back_focus.bg_color=Color.TRANSPARENT
	back_focus.border_color=Card.FOCUS_INK;back_focus.set_border_width_all(2);back_focus.set_corner_radius_all(8)
	back.add_theme_stylebox_override("focus",back_focus)
	var chain:Array=[back]+cards
	for i:int in chain.size():
		var current:Control=chain[i]
		current.focus_next=current.get_path_to(chain[(i+1)%chain.size()])
		current.focus_previous=current.get_path_to(chain[(i+chain.size()-1)%chain.size()])
		if current!=back:current.focus_entered.connect(func():scroll.ensure_control_visible(current))
	resized.connect(_layout);_layout()

func setup(config:Dictionary)->void:
	setting_reduced=bool(config.get("reduced_motion",false));_motion_changed([])
	if OS.has_feature("web"):
		var hover=bool(JavaScriptBridge.eval("typeof matchMedia==='function' && matchMedia('(any-hover: hover) and (any-pointer: fine)').matches",true))
		for card:Control in cards:card.allow_hover=hover

func _motion_changed(_arguments:Array)->void:
	reduced=setting_reduced or (media_query!=null and bool(media_query.matches))
	for card:Control in cards:
		card.sketch.reduced=reduced
		if reduced:card.quiet()

func configure_activity_layout(available:Vector2,_compact:bool)->void:
	custom_minimum_size=Vector2.ZERO;position=Vector2.ZERO;scale=Vector2.ONE
	size=available.min(get_viewport_rect().size);_layout()

func _layout()->void:
	if not grid:return
	scroll.offset_top=64
	var narrow=size.x<=760
	grid.columns=1 if narrow else 3
	var available=maxf(260,size.x-(40 if narrow else 64))
	var width=minf(480 if narrow else 1200,available)
	var height=3*360+24 if narrow else 360
	var top=8.0 if narrow else maxf(0,(size.y-height)/2-64)
	grid.position=Vector2((size.x-width)/2,top);grid.size=Vector2(width,height)
	for card:Control in cards:card.custom_minimum_size=Vector2(width if narrow else (width-24)/3,360)
	page.custom_minimum_size=Vector2(maxf(0,size.x-12),maxf(size.y-64,top+height+32))
	back.position=Vector2(12,12);back.size=Vector2(44,44)

func _process(delta:float)->void:
	if disposed or suspended:return
	for card:Control in cards:card.tick(minf(.05,delta))

func _input(event:InputEvent)->void:
	if disposed or not is_visible_in_tree():return
	if event is InputEventKey and event.pressed and not event.echo and (event.physical_keycode if event.physical_keycode else event.keycode)==KEY_ESCAPE:
		_leave();get_viewport().set_input_as_handled()

func _leave()->void:
	if disposed:return
	dispose_presentation();cancelled.emit()

func dispose_presentation()->void:
	disposed=true
	for card:Control in cards:card.quiet()

func _exit_tree()->void:
	if media_query!=null and media_callback!=null:media_query.removeEventListener("change",media_callback)
	for card:Control in cards:card.quiet()

func _notification(what:int)->void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_WM_WINDOW_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]:
		suspended=true
		for card:Control in cards:card.quiet()
	elif what in [NOTIFICATION_APPLICATION_FOCUS_IN,NOTIFICATION_WM_WINDOW_FOCUS_IN]:suspended=false
