extends ColorRect
## Original archive-index answer, presented as cards and a physical drawer.
signal submit_requested(action: String, value: Dictionary, serial: int)
signal close_requested
signal world_handoff_requested(fresh_success: bool)
const Session = preload("res://scripts/ui/chapter4_device_session.gd")
const View = preload("res://scripts/objects/room301_archive_view.gd")
const Ui = preload("res://scripts/ui/native_ui_theme.gd")
var session: RefCounted
var frame: PanelContainer
var view: Control
var header: HBoxContainer
var title: Label
var hint: Label
var feedback: Label
var close_button: Button
var input_mode := "keyboard"
var _safe_insets := Vector4.ZERO
var safe_area := Rect2()
var fresh_success := false
var retired := false
var authority_owner: Dictionary

func configure(id: String, state: Dictionary, font: Font = null) -> bool:
	session=Session.new()
	if id!="archive_index" or not _context(state) or not session.open(id,state): return false
	authority_owner=state
	if font!=null: theme=Ui.font_theme(font)
	name="Room301Archive"; color=Color("202523"); z_index=100; clip_contents=true
	mouse_filter=Control.MOUSE_FILTER_STOP; focus_mode=Control.FOCUS_ALL
	set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	view=View.new(); add_child(view)
	view.reduced=bool(state.get("native",{}).get("settings",{}).get("reduced_motion",false))
	view.choice_requested.connect(_choose)
	view.drawer_requested.connect(_submit)
	view.motion_finished.connect(_refresh)
	header=HBoxContainer.new(); header.add_theme_constant_override("separation",8); add_child(header)
	title=_label("找出旧导视胶片",21); title.autowrap_mode=TextServer.AUTOWRAP_OFF; title.clip_text=true
	title.size_flags_horizontal=Control.SIZE_EXPAND_FILL; header.add_child(title)
	close_button=Button.new(); close_button.name="ReturnToArchive"; close_button.text="返回301"; close_button.custom_minimum_size=Vector2(100,48)
	Ui.apply_button(close_button,Color("434b43"),Color("f1e3c6"),Color("8f9a85"),4,2,15,Vector2(8,6),Color("e3c17a"))
	close_button.pressed.connect(func(): if can_close(): close_requested.emit())
	header.add_child(close_button)
	hint=_label("",14); add_child(hint)
	feedback=_label("",14); add_child(feedback)
	_refresh(); return true

func _ready() -> void:
	resized.connect(_layout)
	if size.is_zero_approx(): layout_fullscreen(get_viewport_rect(),_safe_insets)
	else: _layout()
	grab_focus.call_deferred()

func _label(text: String, pixels: int) -> Label:
	var node:=Label.new(); node.text=text; node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	node.add_theme_font_size_override("font_size",pixels); node.add_theme_color_override("font_color",Color("e3d7bd"))
	node.mouse_filter=Control.MOUSE_FILTER_IGNORE; return node

func uses_exclusive_game_viewport() -> bool: return true
func layout_panel(available: Vector2) -> void: layout_fullscreen(Rect2(Vector2.ZERO,available),_safe_insets)
func _layout() -> void: layout_fullscreen(Rect2(position,size),_safe_insets)
func layout_fullscreen(area: Rect2, insets: Vector4 = Vector4.ZERO) -> void:
	if view==null: return
	if size!=area.size or position!=area.position or _safe_insets!=insets: cancel_input()
	_safe_insets=insets; position=area.position; size=area.size
	safe_area=Rect2(Vector2(insets.x+14,insets.y+14),Vector2(maxf(1,size.x-insets.x-insets.z-28),maxf(1,size.y-insets.y-insets.w-28)))
	var short_view:=size.y<540
	header.position=safe_area.position; header.size=Vector2(safe_area.size.x,48)
	title.add_theme_font_size_override("font_size",18 if size.x<500 else 21)
	hint.position=safe_area.position+Vector2(0,52 if short_view else 55); hint.size=Vector2(safe_area.size.x,24 if short_view else 48)
	feedback.position=Vector2(safe_area.position.x,safe_area.end.y-(28 if short_view else 42)); feedback.size=Vector2(safe_area.size.x,28 if short_view else 42)
	view.position=Vector2.ZERO; view.size=size
	var top:=hint.position.y+(28 if short_view else 52)
	view.layout_scene(Rect2(Vector2(safe_area.position.x,top),Vector2(safe_area.size.x,maxf(90,feedback.position.y-top-(4 if short_view else 6)))))

func set_input_mode(mode: String) -> void:
	if mode not in ["keyboard","touch"] or mode==input_mode: return
	cancel_input(); input_mode=mode; view.touch_mode=mode=="touch"; _refresh()

func _refresh() -> void:
	if session==null or view==null: return
	var next_interactive: bool=session.editable()
	if view.interactive and not next_interactive: cancel_input()
	view.interactive=next_interactive
	view.present(session.source,session.draft,session.completed,session.mode=="dark")
	close_button.disabled=session.pending
	if session.completed:
		title.text="旧导视胶片已取出"
		hint.text="索引和原件已经对应。回到 302 的扫描台，对齐旧影像与现在的楼层。"
	elif session.mode=="dark":
		hint.text="抽屉边留下了三条索引痕迹。看清年代、楼层和用途，再切回浅色动手。"
	else:
		hint.text="点按索引签，或左右滑动切换内容。选好后，拉开黄铜把手。" if input_mode=="touch" else "拨动抽屉上的三条索引签，再拉把手。↑↓选签 · ←→切换 · Enter检索。"

func _choose(key: String, value: String) -> void:
	if not view.interactive or not session.choose(key,value): return
	view.motion=""
	view.focused_row=View.KEYS.find(key); feedback.text=""; _refresh()

func _submit() -> void:
	if not session.editable(): return
	var request: Dictionary=session.begin_submit()
	if request.is_empty():
		feedback.text="先设置年代、楼层和用途三条索引签。"
		view.begin_result(false); _refresh(); return
	feedback.text=""; cancel_input(); _refresh()
	submit_requested.emit(request.action,request.value,request.serial)

func handle_key(event: InputEventKey) -> bool:
	if input_mode!="keyboard" or not event.pressed or event.echo or not is_visible_in_tree(): return false
	if view.dragging: cancel_input()
	if close_button.has_focus() and event.keycode in [KEY_ENTER,KEY_KP_ENTER,KEY_SPACE]: return false
	if event.keycode in [KEY_ENTER,KEY_KP_ENTER,KEY_SPACE]: _submit(); return true
	if not session.editable(): return false
	if event.keycode in [KEY_UP,KEY_DOWN]:
		view.focused_row=posmod(view.focused_row+(-1 if event.keycode==KEY_UP else 1),3); view.queue_redraw(); return true
	if event.keycode in [KEY_LEFT,KEY_RIGHT]:
		view.cycle_index(view.focused_row,-1 if event.keycode==KEY_LEFT else 1); return true
	return false

func _context(state: Dictionary) -> bool:
	var native: Dictionary=state.get("native",{})
	var c: Dictionary=state.get("chapter4",{})
	return native.get("chapter",0)==4 and native.get("scene","")=="duan_yongping_temporal_maze" and native.get("mode","")==c.get("mode","") and native.get("c4_context","")=="archive_index" and c.get("phase","")=="room204_restore" and c.get("floor","")=="A3" and bool(c.get("prologueSeen",false))

func sync_authority(state: Dictionary) -> bool:
	if session==null or not is_same(state,authority_owner) or not _context(state) or not session.compatible(state): fresh_success=false; cancel_input(); return false
	session.update_authority(state); _refresh(); return true

func resolve_submission(serial: int, state: Dictionary, result: Dictionary) -> void:
	if not is_same(state,authority_owner) or not _context(state) or not session.compatible(state): cancel_input(); return
	if session.resolve(serial,state,result):
		fresh_success=session.completed
		feedback.text="胶片已取出。返回 301 后，去 302 的扫描台继续。" if session.completed else session.feedback
		view.begin_result(session.completed); _refresh()

func can_close() -> bool: return session==null or not session.pending
func owns_feedback() -> bool: return session!=null and session.pending
func set_feedback(message: String) -> void:
	if feedback!=null: feedback.text=message
func cancel_input() -> void:
	if view!=null: view.cancel_gesture()
func dispose_session() -> void:
	if retired: return
	retired=true
	world_handoff_requested.emit(fresh_success)
	fresh_success=false
	cancel_input()
	if view!=null: view.interactive=false; view.motion=""
	if session!=null: session.pending=false; session.pending_serial=0; session.close()
func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_WINDOW_FOCUS_OUT or what==NOTIFICATION_EXIT_TREE or (what==NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree()): cancel_input()
