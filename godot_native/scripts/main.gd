extends Control
## Native phone and RPG shell. All story changes pass through State.
var phone: PanelContainer
var phone_content: VBoxContainer
var phone_padding: Control
var phone_chrome: Control
var phone_document: Control
var phone_document_previous_focus: WeakRef
var control_center: Control
var control_builder: RefCounted
var inspected_item_id := ""
var inventory_gestures := preload("res://scripts/ui/inventory_gesture.gd").new()
var phone_scroll: ScrollContainer
var world_frame: PanelContainer
var world: Control
var world_viewport: SubViewport
var world_view: SubViewportContainer
var status_label: Label
var title_label: Label
var quest_label: Label
var toast: Label
var toast_time := 0.0
var chapter_label: Label
var app_grid: GridContainer
var page_body: VBoxContainer
var c3_device_panel: Control
var modal: Control
var modal_panel: PanelContainer
var modal_notice_slot: Control
var modal_previous_focus: WeakRef
var relayout_pending := false
var active_game: Control
var font: Font
var file_dialog: FileDialog
var export_mode := false
var rebuild_pending := false
var backdrop: ColorRect
var _screenshot_requested := false
var _quit_requested := false
var game_viewport := Vector2(960,540)
# Retained name for existing activity/device callers. This now selects the
# single visible surface at every viewport, not only on mobile.
var mobile_world := false
var world_page_origin_scene := ""
var phone_scroll_page := ""
var mobile_back: Button
var phone_world_return: Button
var world_tasks: Button
var voice_player: AudioStreamPlayer
var phone_builder: RefCounted
var later_phone_builder: RefCounted
var status_row: HBoxContainer
var header_row: HBoxContainer
var footer_row: HBoxContainer
var inventory_dock: PanelContainer
var inventory_buttons: HBoxContainer
var inventory_scroll: ScrollContainer
var inventory_dock_rect := Rect2()
var inventory_handle: Button
var compact_inventory_open := false
var compact_world_contract := false
var media_host: Node
var world_effect: Control
var battery_prank: Control
var capture_busy := false
var audio_director: Node
var c3_scene_host: Control
var library_story_host: Control
var c3_narrative_host: Control
const CanteenObjective = preload("res://scripts/presentation/canteen_objective.gd")
const NativeJournalView = preload("res://scripts/ui/native_journal_view.gd")
const ObservationComparisonSession = preload("res://scripts/presentation/observation_comparison_session.gd")
const ObservationComparisonView = preload("res://scripts/ui/observation_comparison_view.gd")
var observation_comparison_session = ObservationComparisonSession.new()
const PhotoBrightnessSession = preload("res://scripts/ui/photo_brightness_session.gd")
var photo_brightness_session = PhotoBrightnessSession.new()
const PhoneNotice = preload("res://scripts/ui/native_phone_notice.gd")
const NativeUi = preload("res://scripts/ui/native_ui_theme.gd")
const NativeFileDialogTheme = preload("res://scripts/ui/native_file_dialog_theme.gd")
const INK := Color("14212a")
const PAPER := Color("f4f1e8")
const ACCENT := Color("c9e96e")
const BLUE := Color("267b9e")

func _ready() -> void:
	# Let native audio owners retire their mixer-thread playbacks before exit.
	get_tree().auto_accept_quit = false
	get_tree().root.close_requested.connect(_request_quit)
	font = load("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf")
	# Keep the non-phone inherited text size. Phone and modal roles are scoped.
	theme = NativeUi.make_theme(font,18,18)
	_build_shell()
	phone.minimum_size_changed.connect(_schedule_layout)
	State.changed.connect(_schedule_refresh)
	State.action_completed.connect(_on_controller_page_intent)
	State.feedback.connect(_feedback)
	State.game_requested.connect(_open_game)
	State.narrative_requested.connect(_open_narrative)
	State.audio_requested.connect(_play_audio)
	State.media_requested.connect(_apply_media)
	State.world_effect_requested.connect(_open_world_effect)
	State.capture_requested.connect(_capture_world)
	State.battery_reserve_used.connect(func(percent: int):
		if is_instance_valid(battery_prank): battery_prank.consume_reserve(percent)
	)
	State.story_reset.connect(_reset_runtime_presentations)
	State.battery_recharged.connect(func():
		if is_instance_valid(battery_prank): battery_prank.reset()
	)
	resized.connect(_layout)
	_setup_runtime_hosts()
	_restore_shell_surface()
	_refresh()
	_layout()
	_resume_world_activity.call_deferred()
	_resume_recovered_replay.call_deferred()
	_focus_world_surface.call_deferred()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--preview="):
			State.begin_preview(1,arg.trim_prefix("--preview="))
		if arg.begins_with("--checkpoint="): State.begin_checkpoint(arg.trim_prefix("--checkpoint="))
		if arg.begins_with("--page="):
			State.open_page(arg.trim_prefix("--page="))
		if arg == "--screenshot": _screenshot_requested = true

func _box(color: Color, border: Color, radius: int, width: int = 1) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = border
	box.set_border_width_all(width)
	box.set_corner_radius_all(radius)
	box.content_margin_left = 14
	box.content_margin_right = 14
	box.content_margin_top = 10
	box.content_margin_bottom = 10
	return box

func _build_shell() -> void:
	backdrop = ColorRect.new()
	backdrop.color = Color("101e28")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	chapter_label = _label("7:55",NativeUi.FONT_DISPLAY,Color("e9eed7"))
	add_child(chapter_label)
	phone = PanelContainer.new()
	phone.theme = NativeUi.make_theme(font)
	var phone_border := _box(PAPER,Color("0d0c0a"),0,3)
	phone_border.content_margin_left = 3
	phone_border.content_margin_right = 3
	phone_border.content_margin_top = 3
	phone_border.content_margin_bottom = 3
	phone.add_theme_stylebox_override("panel",phone_border)
	phone.size = Vector2(430,860)
	add_child(phone)
	phone_content = VBoxContainer.new()
	phone_content.add_theme_constant_override("separation",0)
	phone.add_child(phone_content)
	phone_padding = Control.new()
	phone_padding.custom_minimum_size = Vector2(424,40)
	phone_padding.mouse_filter = Control.MOUSE_FILTER_IGNORE
	phone_content.add_child(phone_padding)
	var status := HBoxContainer.new()
	status_row = status
	status.custom_minimum_size.y = 40
	phone_content.add_child(status)
	status_label = _label("7:55",14,Color("667b77"))
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status.add_child(status_label)
	status.add_child(_compact_button("模式",func(): State.toggle_mode()))
	status.add_child(_compact_button("设置",_show_settings))
	var header := HBoxContainer.new()
	header_row = header
	phone_content.add_child(header)
	header.add_child(_button("‹",func(): _on_phone_page("phone_home"),Vector2(36,42)))
	title_label = _label("7:55",26)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_label)
	quest_label = _label("",14,Color("53704a"))
	quest_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quest_label.custom_minimum_size = Vector2(424,48)
	phone_content.add_child(quest_label)
	phone_scroll = ScrollContainer.new()
	phone_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	phone_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	# The authored 424px phone canvas owns its app scrollbars. The outer shell
	# still scrolls long fallback pages, but must not reserve another 8px gutter
	# while a header/page transition is settling and widen the phone frame.
	phone_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	phone_content.add_child(phone_scroll)
	page_body = VBoxContainer.new()
	page_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page_body.add_theme_constant_override("separation",0)
	phone_scroll.add_child(page_body)
	var footer := HBoxContainer.new()
	footer_row = footer
	phone_content.add_child(footer)
	for item in [{"label":"应用","call":_show_apps},{"label":"物品","call":_show_inventory},{"label":"记录","call":_show_journal}]:
		var btn := _button(item.label,item.call,Vector2(100,44))
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		footer.add_child(btn)
	if ResourceLoader.exists("res://scripts/ui/phone_chrome.gd"):
		phone_chrome=load("res://scripts/ui/phone_chrome.gd").new()
		phone.add_child(phone_chrome)
		phone_chrome.setup(_read_runtime_state)
		phone_chrome.page_requested.connect(_on_phone_page)
		phone_chrome.task_requested.connect(_show_journal)
		phone_chrome.inspect_requested.connect(_inspect_item)
		phone_chrome.item_selected.connect(func(id: String): State.select_item(id))
		phone_chrome.items_combined.connect(_combine_inventory_items)
		phone_chrome.utility_requested.connect(func(id: String):
			if id=="inventory_toggle":
				State.d.ui.inventoryOpen = not State.d.ui.inventoryOpen
				phone_chrome.refresh(State.d)
		)
	world_frame = PanelContainer.new()
	var world_border := _box(Color("0c151e"),Color("527779"),12,2)
	world_border.content_margin_left=10
	world_border.content_margin_right=10
	world_border.content_margin_top=10
	world_border.content_margin_bottom=10
	world_frame.add_theme_stylebox_override("panel",world_border)
	world_frame.size = Vector2(980,560)
	add_child(world_frame)
	if ResourceLoader.exists("res://scripts/world.gd"):
		world = load("res://scripts/world.gd").new()
		world.theme = NativeUi.font_theme(font)
		world.custom_minimum_size = Vector2(960,540)
		world.size = Vector2(960,540)
		world.host_node = self
		world_view = load("res://scripts/ui/world_viewport_container.gd").new()
		world_view.world_surface = world
		world_view.custom_minimum_size = Vector2(960,540)
		world_view.stretch = true
		world_frame.add_child(world_view)
		world_viewport = SubViewport.new()
		world_viewport.size = Vector2i(960,540)
		world_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		world_view.add_child(world_viewport)
		world_viewport.add_child(world)
	inventory_dock = PanelContainer.new()
	inventory_dock.add_theme_stylebox_override("panel",_box(Color("1e3038"),Color("62787d"),8))
	add_child(inventory_dock)
	var inventory_row := HBoxContainer.new()
	inventory_dock.add_child(inventory_row)
	inventory_row.add_child(_label("物品",17,Color("e7ead9")))
	inventory_scroll = ScrollContainer.new()
	inventory_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	inventory_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	inventory_row.add_child(inventory_scroll)
	inventory_buttons = HBoxContainer.new()
	inventory_buttons.add_theme_constant_override("separation",8)
	inventory_scroll.add_child(inventory_buttons)
	inventory_handle=_button("展开物品栏",_toggle_world_inventory,Vector2(120,44))
	inventory_handle.name="WorldInventoryHandle"
	inventory_handle.autowrap_mode=TextServer.AUTOWRAP_OFF
	inventory_handle.clip_text=true
	add_child(inventory_handle)
	toast = PhoneNotice.create()
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast.z_index = 110
	add_child(toast)
	voice_player = AudioStreamPlayer.new()
	add_child(voice_player)
	mobile_back = _button("手机 · P",_show_phone_surface,Vector2(140,44))
	mobile_back.name = "WorldPhoneButton"
	add_child(mobile_back)
	phone_world_return = _button("返回现场 · Esc",_return_from_phone,Vector2(180,44))
	phone_world_return.name = "PhoneWorldReturn"
	add_child(phone_world_return)
	world_tasks = _button("任务",_show_world_journal,Vector2(84,44))
	world_tasks.name = "WorldTasks"
	world_tasks.autowrap_mode = TextServer.AUTOWRAP_OFF
	world_tasks.clip_text = true
	world_tasks.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	add_child(world_tasks)
	file_dialog = FileDialog.new()
	file_dialog.theme = NativeFileDialogTheme.create(font)
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.filters = PackedStringArray(["*.json ; 7:55 存档"])
	file_dialog.file_selected.connect(_on_file_selected)
	add_child(file_dialog)

func _compact_button(text: String, callback: Callable) -> Button:
	var button := _button(text,callback,Vector2(56,32))
	button.add_theme_font_size_override("font_size",14)
	for state in ["normal","hover","pressed"]:
		var style := _box(Color("e8e6db"),Color("cacdbf"),4)
		style.content_margin_left = 6
		style.content_margin_right = 6
		style.content_margin_top = 4
		style.content_margin_bottom = 4
		button.add_theme_stylebox_override(state,style)
	return button

func _label(text: String, font_size: int = 18, color: Color = INK) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",color)
	return label

func _button(text: String, call: Callable, minimum: Vector2 = Vector2(0,48)) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = minimum
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.pressed.connect(call)
	return button

func _uses_split_layout() -> bool:
	# Compatibility query for existing scene hosts/tests. No layout owns two
	# interactive surfaces. Compactness must never imply a second world owner.
	return false

func _uses_compact_layout() -> bool:
	return DisplayServer.is_touchscreen_available() or size.x < 1100 or size.x <= size.y

func _has_world_scene() -> bool:
	return not str(State.d.get("native",{}).get("scene","")).is_empty()

func _restore_shell_surface() -> void:
	# Desktop resumes the saved world; the prologue has no world and stays on
	# its authored phone. Compact sessions retain their explicit view choice.
	mobile_world = _has_world_scene() and str(State.d.get("runtimeMode","phone")) == "rpg" and (mobile_world or not _uses_compact_layout())

func _surface_navigation_blocked(ignore_world_presentation: bool=false) -> bool:
	if is_instance_valid(modal) or is_instance_valid(phone_document) or is_instance_valid(active_game) or bool(State.d.ui.controlCenterOpen) or capture_busy: return true
	if State.story_input_locked():
		# A compact reload may already have a paused world dialogue. Its only
		# Return path must remain usable; other story/UI owners stay exclusive.
		var issued: RefCounted = State.get_c3_narrative_session()
		if world_frame.is_visible_in_tree() or issued == null or str(issued.scene) != str(State.d.native.scene): return true
	if is_instance_valid(file_dialog) and file_dialog.visible: return true
	if is_instance_valid(world) and world.capture_mode: return true
	if is_instance_valid(world_effect) and world_effect.get_meta("blocks_input",false): return true
	# An explicit device page may suspend a world-only animation (e.g. the
	# Library shelf). Returning must reveal that same owner so it can finish.
	return not ignore_world_presentation and world_frame.is_visible_in_tree() and (_authored_world_contract() or (is_instance_valid(world) and world._interaction_presentation_blocks()))

func _cancel_surface_gestures() -> void:
	for button in inventory_buttons.get_children(): button.cancel_gesture()
	if is_instance_valid(phone_chrome) and is_instance_valid(phone_chrome.inventory_slots):
		for button in phone_chrome.inventory_slots.get_children(): button.cancel_gesture()
	if is_instance_valid(world):
		world.cancel_exploration_gestures()
		world.walk_clock = 0
	if is_instance_valid(world_viewport): world_viewport.gui_release_focus()
	get_viewport().gui_release_focus()

func _show_phone_surface() -> void:
	if _surface_navigation_blocked(): return
	_cancel_surface_gestures()
	world_page_origin_scene = ""
	mobile_world = false
	# Keep the existing world-to-phone homepage route and its app lifecycle.
	State.open_page("phone_home")
	_layout()
	phone_world_return.grab_focus()

func _return_from_phone() -> void:
	if not _has_world_scene() or _surface_navigation_blocked(): return
	_show_world_mobile()

func _focus_world_surface() -> void:
	if not is_instance_valid(world) or not world_frame.is_visible_in_tree(): return
	if _surface_navigation_blocked(true): return
	world.grab_focus()

func _on_controller_page_intent(_action: String,_previous: Dictionary,current: Dictionary,result: Dictionary) -> void:
	if _action=="c35_replay" and _recovered_replay_eligible():
		# The original runtime gate mounts the recovered film from this accepted
		# transition, without a second generic "play" page in between.
		_resume_recovered_replay.call_deferred()
	if _action=="c4_prologue_end" and not bool(_previous.get("chapter4",{}).get("prologueSeen",false)) and bool(current.get("chapter4",{}).get("prologueSeen",false)) and result.get("world_effect",{}).get("kind","")=="paper_flight":
		# This controller commits its world internally and returns a world effect.
		# Reveal that same world before the effect's first rendered frame.
		_show_world_mobile()
		return
	if _action=="lib_story_complete" and not str(result.get("story_finished","")).is_empty(): _focus_library_story.call_deferred()
	if _action in ["c4_checkin_card","c4_checkin_paper"] and current.get("chapter4",{}).get("phase","")=="exterior_closure" and _previous.get("chapter4",{}).get("phase","")=="morning_checkin":
		# Source check-in hands off automatically through the actual door reveal.
		_show_world_mobile()
		State.act.call_deferred("c4_lamp_start")
		return
	# Only a genuine controller-opened device intent creates a fresh session.
	if _action in ["c4_clock","c4_clock_inspected"] and result.get("page","")=="c4_device":
		if _open_chapter4_clock(current):return
	if _action.begins_with("c4_device_") and result.get("page","")=="c4_device":
		if _open_chapter4_device(_action.trim_prefix("c4_device_"),current): return
	if result.has("open_canteen_device"):
		_open_c3_device(str(result.open_canteen_device))
		return
	if result.get("open_canteen_mixer",false):
		_open_c3_device("mixer")
		return
	if result.has("open_theater_device"):
		_open_c3_device(str(result.open_theater_device))
		return
	if result.get("open_inventory",false):
		State.d.ui.inventoryOpen=true
		if is_instance_valid(phone_chrome): phone_chrome.refresh(State.d)
	if result.get("open_world",false) and not str(current.get("native",{}).get("scene","")).is_empty():
		_show_world_mobile()
		return
	if _action=="lib_enter" and result.get("scene","")=="library_interior" and current.get("native",{}).get("scene","")=="library_interior":
		# The Library app's explicit return uses the controller's existing scene
		# result. Reveal that retained world only after entry actually succeeds.
		_show_world_mobile()
		_focus_library_story.call_deferred()
		return
	# A world device can intentionally open an existing phone/page surface. In
	# compact layout that surface must become visible; an ordinary refresh is
	# never navigation. No controller fact or world position is changed here.
	var scene: String=str(current.get("native",{}).get("scene",""))
	if result.get("narrative_owned",false):
		# Phone inventory puzzles can issue world dialogue without first opening
		# a world device. Verify the real controller session, not a result flag or
		# stale page marker, before revealing its retained scene and single host.
		var issued: RefCounted = State.get_c3_narrative_session()
		if issued != null and not scene.is_empty() and str(issued.scene) == scene:
			_show_world_mobile()
			return
	if not result.has("page"): return
	var page: String=str(result.page)
	if page.is_empty(): return
	# Scene-entry pages remain world entries. A controller's explicit home or
	# phone-mode handoff (including the rain return) is a real phone destination.
	if result.has("scene") and not str(result.scene).is_empty() and page!="phone_home" and current.get("runtimeMode","")!="phone":
		if scene != str(_previous.get("native",{}).get("scene","")): _show_world_mobile()
		return
	if result.has("game") or result.has("world_effect") or result.has("narrative"): return
	if mobile_world:
		world_page_origin_scene=scene if not scene.is_empty() and page!="phone_home" else ""
		_cancel_surface_gestures()
		mobile_world=false
		_layout()
	elif page=="phone_home" or scene!=world_page_origin_scene:
		world_page_origin_scene=""

func _layout() -> void:
	var available := size
	var compact_layout := _uses_compact_layout()
	var fitted_activity: bool = _activity_owns_scene()
	var has_world := _has_world_scene()
	if not has_world: mobile_world = false
	var phone_top := 64.0 if has_world else 18.0
	var phone_space := available - Vector2(24,phone_top + 18)
	var phone_scale := maxf(.1,minf(1.0,minf(phone_space.y / 860.0,phone_space.x / 430.0)))
	phone.scale = Vector2.ONE * phone_scale
	phone.size = Vector2(430,860)
	phone.position = Vector2((available.x - 430*phone_scale)/2,phone_top+(phone_space.y-860*phone_scale)/2)
	phone.visible = not mobile_world and not fitted_activity
	phone_world_return.visible = phone.visible and has_world and not is_instance_valid(active_game)
	phone_world_return.position = Vector2(12,12)
	phone_world_return.size = Vector2(180,44)
	if not phone.visible: photo_brightness_session.reset()
	elif not photo_brightness_session.mounted and str(State.d.native.page)=="photos":
		photo_brightness_session.observe("photos",State.d.ui)
	world_frame.visible = mobile_world and not fitted_activity
	world_viewport.gui_disable_input = not world_frame.visible
	mobile_back.visible = world_frame.visible and not is_instance_valid(active_game)
	mobile_back.position = Vector2(12,12)
	world_tasks.visible = mobile_back.visible
	var inventory_available := _inventory_dock_available() and not is_instance_valid(active_game)
	var compact: bool = mobile_world and compact_layout and not _authored_world_contract()
	compact_world_contract = compact
	inventory_handle.visible = world_frame.visible and inventory_available
	inventory_handle.text = "%s物品栏 · %d"%["收起" if compact_inventory_open else "展开",inventory_buttons.get_child_count()]
	inventory_dock.visible = inventory_handle.visible and compact_inventory_open
	var world_extent := Vector2(960,540)
	var border: StyleBoxFlat = world_frame.get_theme_stylebox("panel")
	var margin := 2.0 if compact else 10.0
	border.content_margin_left=margin; border.content_margin_right=margin
	border.content_margin_top=margin; border.content_margin_bottom=margin
	if compact:
		world_frame.scale = Vector2.ONE
		var scene_rect := Rect2(8,64,available.x-16,available.y-72)
		mobile_back.position = Vector2(8,8)
		if available.x>available.y:
			var tray_width := minf(288,available.x*.35) if compact_inventory_open else 196.0
			inventory_handle.position=Vector2(available.x-tray_width-8,8)
			inventory_handle.size=Vector2(tray_width,44)
			inventory_dock.position=Vector2(available.x-tray_width-8,64)
			inventory_dock.size=Vector2(tray_width,76)
			if inventory_dock.visible: scene_rect.size.x-=tray_width+8
		else:
			inventory_handle.position=Vector2(12,available.y-56)
			inventory_handle.size=Vector2(available.x-24,44)
			inventory_dock.position=Vector2(12,available.y-140)
			inventory_dock.size=Vector2(available.x-24,76)
			if inventory_handle.visible: scene_rect.size.y=(inventory_dock.position.y if inventory_dock.visible else inventory_handle.position.y)-8-scene_rect.position.y
		world_frame.position=scene_rect.position
		world_extent=scene_rect.size-Vector2.ONE*4
		world_frame.size=scene_rect.size
	else:
		# Desktop dedicates all available play area to one authored world.
		# Cinematics retain the same 960x540 contract on compact screens.
		world_frame.size=Vector2(980,560)
		if compact_layout:
			inventory_handle.position=Vector2(12,available.y-56)
			inventory_handle.size=Vector2(available.x-24,44)
		else:
			inventory_handle.position=Vector2(available.x-224,12)
			inventory_handle.size=Vector2(212,44)
		inventory_dock.position=Vector2(12,available.y-88)
		inventory_dock.size=Vector2(available.x-24,76)
		var bottom := available.y-12
		if inventory_dock.visible: bottom=inventory_dock.position.y-12
		elif compact_layout and inventory_handle.visible: bottom=inventory_handle.position.y-12
		var world_scale := minf((available.x-24)/980.0,maxf(1,bottom-64)/560.0)
		world_frame.scale=Vector2.ONE*world_scale
		world_frame.position=Vector2((available.x-980*world_scale)/2,64+(bottom-64-560*world_scale)/2)
	var tasks_right: float = inventory_handle.position.x-8 if available.x>available.y and inventory_handle.visible else available.x-mobile_back.position.x
	world_tasks.position=Vector2(tasks_right-84,mobile_back.position.y)
	world_tasks.size=Vector2(84,44)
	# A hidden phone mode retains the world viewport/camera as well as its actor.
	# Only visible world resize or authored ownership can reframe exploration.
	if world_frame.visible: _configure_world_surface(world_extent,compact)
	var dock_rect:=inventory_dock.get_global_rect()
	if dock_rect!=inventory_dock_rect:
		for button in inventory_buttons.get_children(): button.cancel_gesture()
		inventory_dock_rect=dock_rect
	_sync_inventory_dock_input()
	chapter_label.visible=false
	_layout_toast()
	if is_instance_valid(battery_prank):
		battery_prank.position=phone.position if phone.visible else world_frame.position
		battery_prank.scale=phone.scale if phone.visible else world_frame.scale
		battery_prank.size=Vector2(430,860) if phone.visible else Vector2(960,540)
		battery_prank.move_to_front()
	if is_instance_valid(phone_chrome): phone_chrome.set_input_blocked(is_instance_valid(modal) or is_instance_valid(active_game) or is_instance_valid(phone_document))
	if active_game:
		if fitted_activity: active_game.configure_activity_layout(available,compact_layout)
		else:
			var game_scale := minf((available.x-20)/game_viewport.x,(available.y-20)/game_viewport.y)
			active_game.scale=Vector2.ONE*game_scale
			active_game.position=(available-game_viewport*game_scale)/2
	_layout_modal()
	if is_instance_valid(file_dialog) and file_dialog.visible: NativeFileDialogTheme.fit(file_dialog,size)

func _activity_owns_scene() -> bool:
	# Layout adapters opt into one full-scene owner. The shared host opts in
	# for chase and source fishing; other activities retain their own contracts.
	return is_instance_valid(active_game) and active_game.has_method("configure_activity_layout") and (not active_game.has_method("uses_activity_layout") or active_game.uses_activity_layout())

func _authored_world_contract() -> bool:
	# Active cinematics retain their source camera/aspect through interruptions.
	# A canteen session waiting for proximity still belongs to exploration.
	return is_instance_valid(active_game) or (is_instance_valid(world_effect) and not (world_effect.has_method("uses_responsive_exploration") and world_effect.uses_responsive_exploration())) or (is_instance_valid(c3_scene_host) and c3_scene_host.owns_world_contract()) or (is_instance_valid(c3_narrative_host) and c3_narrative_host.owns_world_contract()) or (is_instance_valid(library_story_host) and library_story_host.current!=null)

func _configure_world_surface(extent: Vector2,compact: bool) -> void:
	if not is_instance_valid(world): return
	var dimensions:=Vector2i(maxi(1,int(extent.x)),maxi(1,int(extent.y)))
	var changed: bool=world_viewport.size!=dimensions or world.mobile_exploration!=compact
	world_view.custom_minimum_size=Vector2(dimensions)
	world_view.size=Vector2(dimensions)
	world.custom_minimum_size=Vector2(dimensions)
	world.size=Vector2(dimensions)
	world.mobile_exploration=compact
	world_frame.size=Vector2(dimensions)+Vector2.ONE*(4 if compact else 20)
	if changed:
		for button in inventory_buttons.get_children(): button.cancel_gesture()
		world.cancel_exploration_gestures()
		world.pan_offset=Vector2.ZERO
		world._update_camera()
		world.queue_redraw()

func _layout_toast() -> void:
	if not is_instance_valid(toast): return
	# Generic shell modals own a reserved row below their header. The notice
	# remains a single non-interactive root label, never a modal focus target.
	if is_instance_valid(modal_notice_slot):
		modal_notice_slot.visible=not toast.text.is_empty()
		if modal_notice_slot.visible:
			toast.scale=Vector2.ONE
			PhoneNotice.layout(toast,maxf(1,modal_panel.size.x-32))
			modal_notice_slot.custom_minimum_size.y=toast.size.y
			toast.global_position=modal_notice_slot.global_position
		return
	if is_instance_valid(phone) and phone.visible and not is_instance_valid(active_game):
		toast.scale=phone.scale
		PhoneNotice.layout(toast,392)
		toast.position=phone.position+Vector2(19,55)*phone.scale
	else:
		toast.scale=Vector2.ONE
		PhoneNotice.layout(toast,minf(680,maxf(160,size.x-32)))
		toast.position=Vector2((size.x-toast.size.x)/2,maxf(12,size.y-toast.size.y-maxf(72,size.y*.1)))

func _scene_owns_feedback(message: String) -> bool:
	if str(State.d.native.page)!="desktop": return false
	var line:=message.strip_edges().trim_suffix("。")
	return line=="起床蠢货！！！" if State.d.native.get("wake_warned",false) else line=="你没有5分钟了，但你很有勇气"

func _schedule_layout() -> void:
	if relayout_pending: return
	relayout_pending = true
	_relayout_after_minimum.call_deferred()

func _relayout_after_minimum() -> void:
	relayout_pending = false
	if is_inside_tree(): _layout()

func _layout_modal() -> void:
	if is_instance_valid(modal) and modal.has_method("layout_panel"):
		modal.layout_panel(size)
		return
	if is_instance_valid(c3_device_panel):
		var compact: bool=_uses_compact_layout()
		c3_device_panel.configure_layout(size,compact)
		if compact:
			# Compact device presentation is an unscaled modal, not a miniature
			# world canvas. Gameplay/controller state and RPG geometry stay shared.
			c3_device_panel.scale=Vector2.ONE
			c3_device_panel.position=Vector2.ZERO
		else:
			var world_rect: Rect2=world_view.get_global_rect()
			var device_scale: float=minf(world_rect.size.x/960.0,world_rect.size.y/540.0)
			c3_device_panel.scale=Vector2.ONE*device_scale
			c3_device_panel.global_position=world_rect.position+(world_rect.size-Vector2(960,540)*device_scale)/2
		return
	if not is_instance_valid(modal_panel): return
	modal_panel.size = Vector2(maxf(1,minf(580,size.x-24)),maxf(1,minf(700,size.y-24)))
	modal_panel.position = (size-modal_panel.size)/2
	_layout_toast()

func _schedule_refresh() -> void:
	_sync_inventory_dock_input()
	if rebuild_pending: return
	rebuild_pending = true
	_refresh.call_deferred()

func _refresh() -> void:
	rebuild_pending = false
	if State.d.is_empty(): return
	# Refresh authority without remounting or resetting the current draft.
	if is_instance_valid(modal) and modal.has_method("sync_authority"):
		if not modal.sync_authority(State.d): _close_modal()
	var n: Dictionary = State.d.native
	if n.page=="control_center":
		n.page="phone_home"
		State.d.ui.controlCenterOpen=true
	var page: String = n.page
	# Preserve the source Photos mount baseline behind Control Center overlays.
	var photos_mounted := not mobile_world
	if photo_brightness_session.observe(page if photos_mounted else "",State.d.ui):
		State.act("lib_dim_photo")
	# A new phone destination starts at its top. Same-page state refreshes keep
	# the player's scroll position, including open overlay/brightness updates.
	if page != phone_scroll_page:
		phone_scroll.scroll_vertical = 0
		phone_scroll_page = page
	var view: Dictionary = State.get_view(page)
	view["actions"] = State.get_actions(page)
	status_label.text = "7:55  ·  %s  ·  %d%%" % ["校园网" if State.d.networkMode == "campus_wifi" else "移动网络",int(State.d.phoneBattery.percent)]
	title_label.text = str(view.get("title","7:55"))
	chapter_label.text = "7:55   /   CHAPTER %s%s" % [str(int(n.chapter))," · DEV" if State.developer_mode else ""]
	quest_label.text = "当前任务  ·  " + State.objective()
	for child in page_body.get_children():
		page_body.remove_child(child)
		child.queue_free()
	var custom_body: Control
	if phone_builder == null and ResourceLoader.exists("res://scripts/ui/phone_pages.gd"):
		phone_builder = load("res://scripts/ui/phone_pages.gd").new()
		phone_builder.connect("action_requested",_on_phone_action)
		phone_builder.connect("page_requested",_on_phone_page)
		if phone_builder.has_signal("presentation_requested"): phone_builder.connect("presentation_requested",_play_presentation_cue)
		if phone_builder.has_signal("document_requested"): phone_builder.connect("document_requested",_open_phone_document)
	if later_phone_builder == null and ResourceLoader.exists("res://scripts/ui/chapter3_phone_pages.gd"):
		later_phone_builder = load("res://scripts/ui/chapter3_phone_pages.gd").new()
		later_phone_builder.connect("action_requested",_on_phone_action)
		later_phone_builder.connect("page_requested",_on_phone_page)
		if later_phone_builder.has_signal("presentation_requested"): later_phone_builder.connect("presentation_requested",_play_presentation_cue)
	if phone_builder: phone_builder.entry_session=State.get_phone_entry_session()
	var source_entry_loading: bool=phone_builder!=null and phone_builder.entry_session.family=="zjuding" and phone_builder.entry_session.phase!="ready"
	if later_phone_builder and not source_entry_loading: custom_body = later_phone_builder.build(page,view,State.d)
	if custom_body == null and phone_builder: custom_body = phone_builder.build(page,view,State.d)
	var bare := page in ["alarm","desktop","ending"]
	status_row.visible = false
	quest_label.visible = false
	footer_row.visible = false
	phone_padding.visible = not bare
	if is_instance_valid(phone_chrome): phone_chrome.refresh(State.d)
	header_row.visible = custom_body == null and not bare
	var handled_action_ids: Array = []
	if custom_body:
		custom_body.z_index = 65 if page=="control_center" else 0
		if page == "cc98":
			# Off-tree labels still cache the default font. Prime the existing
			# phone theme before tree-entry layout shapes the complete forum.
			custom_body.theme = phone.theme
			custom_body.propagate_notification(Control.NOTIFICATION_THEME_CHANGED)
		page_body.add_child(custom_body)
		handled_action_ids = custom_body.get_meta("handled_action_ids",[])
		if (page == "phone_home" or page == "desktop") and not custom_body.get_meta("handles_app_grid",false): _add_app_grid(page_body)
	else:
		if view.has("art") and ResourceLoader.exists(State.asset(str(view.art))):
			var artwork := TextureRect.new()
			artwork.texture = load(State.asset(str(view.art)))
			artwork.flip_h = bool(view.get("mirror_art",false))
			artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			artwork.custom_minimum_size = Vector2(378,180)
			page_body.add_child(artwork)
		var body := _label(str(view.get("body","")),19)
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		page_body.add_child(body)
		for row in view.get("rows",[]):
			if row is Dictionary:
				var block := _label(str(row.get("title",""))+"\n"+str(row.get("body","")),17)
				block.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				page_body.add_child(block)
			else:
				var line := _label(str(row),17)
				line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				page_body.add_child(line)
		if page == "phone_home" or page == "desktop":
			_add_app_grid(page_body)
	for action in view.actions:
		if custom_body and (custom_body.get_meta("handles_all_actions",false) or page == "phone_home"): continue
		if handled_action_ids.has(str(action.id)): continue
		var copy: Dictionary = action.duplicate(true)
		var button := _button(str(action.get("label",action.id)),func(): _invoke_action(copy))
		button.disabled = bool(action.get("disabled",false))
		page_body.add_child(button)
	if not str(n.scene).is_empty():
		page_body.add_child(_button("返回现场",_show_world_mobile))
	_refresh_inventory_dock()
	_refresh_control_center()
	if world and world.has_method("refresh_world"): world.refresh_world()
	_layout()

func _add_app_grid(parent: Control) -> void:
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation",8)
	grid.add_theme_constant_override("v_separation",8)
	parent.add_child(grid)
	for page in State.get_pages():
		if str(page.id) in ["phone_home","desktop","alarm"]: continue
		var target := str(page.id)
		var button := _button(str(page.get("label",target)),func(): _close_modal(); State.open_page(target),Vector2(119,64))
		grid.add_child(button)

func _open_chapter4_clock(current: Dictionary) -> bool:
	var choices:Array=[];var required:=""
	for action in State.get_actions("c4_device"):
		if action.id=="c4_clock_set":choices=action.inputs[0].options
	for module in State.modules:
		if module.has_method("_required_time"):required=module._required_time(current.chapter4)
	var panel:Control=load("res://scripts/ui/chapter4_clock_panel.gd").new()
	if not panel.configure(current,choices,required,font):panel.free();return false
	_close_modal()
	if is_instance_valid(modal):panel.free();return false
	var focused=get_viewport().gui_get_focus_owner();modal_previous_focus=weakref(focused) if focused!=null else null
	modal=panel;modal_panel=panel.frame
	panel.close_requested.connect(_close_modal)
	panel.submit_requested.connect(func(value:Dictionary):
		var result:Dictionary=State.act("c4_clock_set",value)
		if is_instance_valid(panel) and modal==panel:panel.resolve(State.d,result)
	)
	add_child(panel);_show_world_mobile();_layout_modal();_sync_inventory_dock_input();return true

func _open_chapter4_device(id: String, current: Dictionary) -> bool:
	var device: Control = load("res://scripts/ui/chapter4_device_panel.gd").new()
	if not device.configure(id,current,font):
		device.free()
		return false
	_close_modal()
	if is_instance_valid(modal):
		device.free()
		return false
	_cancel_world_effect()
	var previous_focus = get_viewport().gui_get_focus_owner()
	modal_previous_focus = weakref(previous_focus) if previous_focus != null else null
	modal = device
	modal_panel = device.frame
	device.close_requested.connect(_close_modal)
	device.submit_requested.connect(func(action: String,value: Dictionary,serial: int):
		var result: Dictionary = State.act(action,value)
		if is_instance_valid(device) and modal == device:
			device.resolve_submission(serial,State.d,result)
	)
	add_child(device)
	_show_world_mobile()
	if is_instance_valid(phone_chrome): phone_chrome.set_input_blocked(true)
	return true

func _invoke_action(action: Dictionary) -> void:
	if str(action.get("id",""))=="c4_clock_set":
		_open_chapter4_clock(State.d);return
	# Existing phone action lists must never reopen the retired generic form.
	if str(action.get("id","")).begins_with("c4_solve_"):
		_open_chapter4_device(str(action.id).trim_prefix("c4_solve_"),State.d)
		return
	if action.has("input") or action.has("inputs"):
		_show_form(action)
	else: State.act(str(action.id),action.get("value"))

func _modal_base(title: String) -> VBoxContainer:
	_cancel_world_effect()
	_close_modal()
	var previous_focus = get_viewport().gui_get_focus_owner()
	modal_previous_focus = weakref(previous_focus) if previous_focus != null else null
	modal = ColorRect.new()
	modal.name = "NativeModalOverlay"
	modal.focus_mode = Control.FOCUS_ALL
	modal.mouse_filter = Control.MOUSE_FILTER_STOP
	modal.theme = NativeUi.make_theme(font)
	modal.z_index = 100
	if is_instance_valid(phone_chrome): phone_chrome.set_input_blocked(true)
	modal.color = Color(0.03,0.06,0.08,0.88)
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(modal)
	var panel := PanelContainer.new()
	modal_panel = panel
	panel.name = "NativeModalPanel"
	panel.add_theme_stylebox_override("panel",NativeUi.box(NativeUi.PAPER,NativeUi.INK,NativeUi.EDGE,0,Vector2(16,16)))
	modal.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation",12)
	panel.add_child(box)
	var header := HBoxContainer.new()
	box.add_child(header)
	var label := _label(title,NativeUi.FONT_TITLE)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(label)
	header.add_child(_button("关闭",_close_modal,Vector2(70,44)))
	modal_notice_slot=Control.new()
	modal_notice_slot.name="NativeModalNotice"
	modal_notice_slot.mouse_filter=Control.MOUSE_FILTER_IGNORE
	modal_notice_slot.hide()
	box.add_child(modal_notice_slot)
	modal_notice_slot.item_rect_changed.connect(_layout_toast)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation",10)
	scroll.add_child(content)
	_layout_modal()
	modal.grab_focus()
	_sync_inventory_dock_input()
	return content

func _modal_focus_controls(parent: Node, result: Array[Control]) -> void:
	for child in parent.get_children():
		if child is Control and child.is_visible_in_tree() and child.focus_mode != Control.FOCUS_NONE:
			if not child is BaseButton or not child.disabled: result.append(child)
		_modal_focus_controls(child,result)

func _input(event: InputEvent) -> void:
	_sync_inventory_dock_input()
	if not is_instance_valid(modal) or not event is InputEventKey or not event.pressed: return
	if modal.has_method("handle_key") and modal.handle_key(event):
		get_viewport().set_input_as_handled();return
	# OptionButton popups own their own keyboard navigation while open.
	for choice in modal.find_children("*","OptionButton",true,false):
		if choice.get_popup().visible: return
	if event.keycode == KEY_ESCAPE:
		_close_modal()
		get_viewport().set_input_as_handled()
		return
	var focused = get_viewport().gui_get_focus_owner()
	if event.keycode == KEY_TAB:
		var controls: Array[Control] = []
		_modal_focus_controls(modal,controls)
		if controls.is_empty(): modal.grab_focus()
		else:
			var index = controls.find(focused)
			if index < 0: index = 0 if event.shift_pressed else -1
			controls[posmod(index+(-1 if event.shift_pressed else 1),controls.size())].grab_focus()
		get_viewport().set_input_as_handled()
	elif focused == null or (focused != modal and not modal.is_ancestor_of(focused)):
		modal.focus_mode = Control.FOCUS_ALL
		modal.grab_focus()
		get_viewport().set_input_as_handled()

func _close_modal() -> void:
	if is_instance_valid(modal) and modal.has_method("can_close") and not modal.can_close(): return
	if is_instance_valid(modal) and modal.has_method("dispose_session"): modal.dispose_session()
	var closing_device: Control=c3_device_panel
	c3_device_panel=null
	if is_instance_valid(closing_device) and closing_device.has_method("dismiss"): closing_device.dismiss()
	var closed_item := inspected_item_id
	inspected_item_id=""
	if is_instance_valid(modal):
		remove_child(modal)
		modal.queue_free()
	modal = null
	_sync_inventory_dock_input()
	modal_panel = null
	modal_notice_slot = null
	_layout_toast()
	var restored_control := false
	if modal_previous_focus != null:
		var previous_focus = modal_previous_focus.get_ref()
		if is_instance_valid(previous_focus) and previous_focus is Control and previous_focus.is_inside_tree() and previous_focus.is_visible_in_tree() and previous_focus.focus_mode != Control.FOCUS_NONE:
			previous_focus.grab_focus()
			restored_control = true
	modal_previous_focus = null
	# Item inspection returns to its still-open bag. World focus is only the
	# fallback for a vanished/hidden originating control or a world interaction.
	if not restored_control: _focus_world_surface.call_deferred()
	if closed_item=="decoyPaper":
		var story_owned: bool=is_instance_valid(c3_narrative_host) and c3_narrative_host.has_method("inspector_closed") and c3_narrative_host.inspector_closed(closed_item)
		if not story_owned and is_instance_valid(audio_director): audio_director.cue("theater_decoy_inspect_closed")
	if is_instance_valid(phone_chrome): phone_chrome.set_input_blocked(is_instance_valid(active_game) or is_instance_valid(phone_document))

func _open_c3_device(kind: String) -> void:
	if is_instance_valid(modal) or is_instance_valid(active_game) or is_instance_valid(phone_document): return
	if not is_instance_valid(world) or world._interaction_presentation_blocks(): return
	if not world_frame.is_visible_in_tree(): _show_world_mobile()
	# A world device returns keyboard control to its originating SubViewport,
	# rather than a stale phone/root focus owner after Escape.
	modal_previous_focus=weakref(world)
	modal=Control.new()
	modal.name="C3WorldDeviceOverlay"
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.mouse_filter=Control.MOUSE_FILTER_STOP
	modal.focus_mode=Control.FOCUS_ALL
	modal.z_index=100
	add_child(modal)
	var canteen_device: bool=kind.begins_with("drink:") or kind in ["menu","bike"]
	var panel_script: String="res://scripts/ui/c3_canteen_device_panel.gd" if canteen_device else "res://scripts/ui/c3_mixer_panel.gd" if kind=="mixer" else "res://scripts/ui/c3_theater_device_panel.gd"
	c3_device_panel=load(panel_script).new()
	c3_device_panel.name="C3WorldDevicePanel"
	modal.add_child(c3_device_panel)
	c3_device_panel.closed.connect(func(_reason: String):
		if is_instance_valid(c3_device_panel):
			c3_device_panel=null
			_close_modal())
	var reader:=func() -> Dictionary: return State.d
	var opened: bool=c3_device_panel.setup(kind,reader,State.act,_feedback,State.toggle_mode) if canteen_device else c3_device_panel.setup(reader,State.act,_feedback) if kind=="mixer" else c3_device_panel.setup(kind,reader,State.act,_feedback)
	if not opened: _close_modal(); return
	world.move_target=Vector2.INF
	world.touch_axis=Vector2.ZERO
	world.walk_clock=0
	world.subtitle=""; world.subtitle_left=0
	if is_instance_valid(phone_chrome): phone_chrome.set_input_blocked(true)
	_layout_modal()
	modal.grab_focus()

func _show_apps() -> void:
	_close_modal()
	world_page_origin_scene=""
	State.open_page("phone_home")

func _toggle_world_inventory() -> void:
	compact_inventory_open=not compact_inventory_open
	_layout()
	# A collapsed bag returns Space to the world; opening keeps its keyboard
	# navigation on the handle. Reuse the existing presentation/input gates.
	if compact_inventory_open or not is_instance_valid(world) or not world_frame.is_visible_in_tree(): return
	if _inventory_dock_input_blocked(): return
	world.grab_focus()

func _inventory_dock_available() -> bool:
	return inventory_buttons.get_child_count()>0 and not (State.d.flags.checkinDone and not State.d.actOne.inventoryRecovered)

func _inventory_dock_input_blocked() -> bool:
	if is_instance_valid(modal) or is_instance_valid(phone_document) or is_instance_valid(active_game) or bool(State.d.ui.controlCenterOpen) or State.story_input_locked(): return true
	if is_instance_valid(file_dialog) and file_dialog.visible: return true
	if is_instance_valid(world) and (world._interaction_presentation_blocks() or world.capture_mode): return true
	return is_instance_valid(world_effect) and world_effect.get_meta("blocks_input",false)

func _sync_inventory_dock_input() -> void:
	if not is_instance_valid(inventory_dock): return
	if is_instance_valid(active_game):
		inventory_dock.hide(); inventory_handle.hide()
		if is_instance_valid(world_tasks): world_tasks.hide()
	var blocked:=_inventory_dock_input_blocked()
	inventory_handle.disabled=blocked
	if is_instance_valid(world_tasks): world_tasks.disabled=blocked
	var navigation_blocked := _surface_navigation_blocked()
	if is_instance_valid(mobile_back): mobile_back.disabled=navigation_blocked
	if is_instance_valid(phone_world_return): phone_world_return.disabled=navigation_blocked
	blocked=blocked or not inventory_dock.is_visible_in_tree()
	for button in inventory_buttons.get_children():
		if blocked and not button.disabled: button.cancel_gesture()
		button.disabled=blocked

func _refresh_inventory_dock() -> void:
	# Selection refreshes must preserve pointer ownership, focus, order and scroll.
	# Only ownership changes create/remove slots; the shared tap history stays put.
	var existing: Dictionary={}
	for button in inventory_buttons.get_children(): existing[button.item_id]=button
	var catalog = State.content("items.config.json")
	for item in catalog:
		var id:=str(item.id)
		if not State.d.items.get(id,false): continue
		if existing.has(id):
			existing.erase(id)
			continue
		var entry: Dictionary = item
		var button = load("res://scripts/ui/inventory_item.gd").new()
		button.name="WorldItem_"+id
		button.item_id = id
		button.text = str(item.name)
		button.custom_minimum_size = Vector2(86,48)
		button.add_theme_font_size_override("font_size",14)
		button.gestures=inventory_gestures
		button.selection_requested.connect(func(item_id: String):
			if not _inventory_dock_input_blocked(): State.select_item(item_id)
		)
		button.inspection_requested.connect(func(_id: String):
			if not _inventory_dock_input_blocked(): _inspect_item(entry)
		)
		button.drag_finished.connect(func(landed: bool): if not landed: State.feedback.emit("没有落在可使用的物品上，道具仍在物品栏。"))
		inventory_buttons.add_child(button)
	for button in existing.values():
		button.cancel_gesture()
		inventory_buttons.remove_child(button)
		button.queue_free()
	_sync_inventory_dock_input()

func _inspect_item(item: Dictionary) -> void:
	var box := _modal_base(str(item.name))
	inspected_item_id=str(item.get("id",""))
	var catalog = JSON.parse_string(FileAccess.get_file_as_string("res://data/native/item_catalog.json"))
	var entry: Dictionary = catalog.get(str(item.id),{}) if catalog is Dictionary else {}
	var document: Dictionary = entry.get("document",{})
	var description := str(item.get("desc","")) # Canonical observation prose; never derive hints from uses[].target
	if not document.is_empty():
		description = str(document.get("heading",item.name))+"\n\n"
		for field in document.get("fields",[]): description += str(field.label)+"："+str(field.value)+"\n"
		description += "\n"+"\n".join(document.get("body",[]))+"\n\n"+str(document.get("footer",""))
	var text := _label(description,19)
	text.name="InventoryObservation"
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(text)
	box.add_child(_button("选择使用",func(): State.select_item(str(item.id)); _close_modal()))

func _show_inventory() -> void:
	var box := _modal_base("物品")
	var catalog = State.content("items.config.json")
	var metadata: Dictionary = {}
	if catalog is Dictionary: metadata = catalog.get("items",catalog)
	elif catalog is Array:
		for entry in catalog: metadata[str(entry.get("id",""))] = entry
	var count := 0
	for key in State.d.items:
		if not State.d.items[key]: continue
		count += 1
		var item: Dictionary = metadata.get(key,{}) if metadata.get(key,{}) is Dictionary else {}
		var item_id := str(key)
		var label := str(item.get("name",item_id))
		var item_entry: Dictionary = item.duplicate(true)
		item_entry["id"] = item_id
		item_entry["name"] = label
		var item_button=load("res://scripts/ui/inventory_item.gd").new()
		item_button.text=label; item_button.item_id=item_id; item_button.gestures=inventory_gestures; item_button.allow_drag=false
		item_button.custom_minimum_size=Vector2(0,44)
		item_button.selection_requested.connect(func(id: String): State.select_item(id))
		item_button.inspection_requested.connect(func(_id: String): _inspect_item(item_entry))
		box.add_child(item_button)
		var desc := _label(str(item.get("desc",item.get("description",item.get("intro","")))),16)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(desc)
	if count == 0: box.add_child(_label("口袋里暂时没有物品。"))
	for action in State.get_actions("phone_home"):
		if str(action.id) == "c1_combine" and count >= 2:
			var combine: Dictionary = action
			box.add_child(_button("组合物品",func(): _invoke_action(combine)))

func _show_world_journal() -> void:
	# A queued top-row press cannot replace another input owner or a phone page.
	if not world_tasks.is_visible_in_tree() or _inventory_dock_input_blocked(): return
	world.cancel_exploration_gestures()
	_show_journal()

func _show_journal() -> void:
	# Keep the destination promised by the mounted journal across rotation.
	var return_to_world: bool=world_frame.is_visible_in_tree()
	var box := _modal_base("调查记录")
	if return_to_world: modal_previous_focus=weakref(world)
	_refresh_observation_comparison()
	var current: Dictionary=CanteenObjective.current(State.d)
	var journal:=NativeJournalView.new()
	journal.configure(State.objective(),str(current.get("detail","")),State.d.native.log,observation_comparison_session.available(),return_to_world)
	journal.resume_requested.connect(func():
		_close_modal()
		if return_to_world or _is_canteen_defense_entry() or _is_bike_chase_entry(): _show_world_mobile()
	)
	journal.comparison_requested.connect(func(): _show_observation_comparison(true))
	box.add_child(journal)
	journal.call_deferred("focus_control","JournalResume")

func _refresh_observation_comparison() -> void:
	var documents: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/native/item_catalog.json"))
	observation_comparison_session.refresh(State.d,State.content("items.config.json"),documents if documents is Dictionary else {})

func _show_observation_comparison(from_journal: bool=false) -> void:
	if is_instance_valid(active_game) or State.story_input_locked(): return
	_refresh_observation_comparison()
	if not observation_comparison_session.available(): return
	var box := _modal_base("线索对照")
	if from_journal:
		if world_frame.is_visible_in_tree(): modal_previous_focus=weakref(world)
		var back:=_button("返回调查记录",_show_journal)
		back.name="ObservationJournalReturn"
		box.add_child(back)
	var comparison = ObservationComparisonView.new()
	comparison.configure(observation_comparison_session)
	comparison.close_requested.connect(_close_modal)
	box.add_child(comparison)
	comparison.call_deferred("_restore_focus","ObservationSlot0")

func _show_form(action: Dictionary) -> void:
	var box := _modal_base(str(action.get("label","输入")))
	var fields: Array = action.get("inputs",[{"id":"value","label":action.get("placeholder",""),"type":action.get("input","text"),"options":action.get("options",[])}])
	var editors: Dictionary = {}
	for field in fields:
		var key := str(field.get("id","value"))
		if not str(field.get("label","")).is_empty(): box.add_child(_label(str(field.label),17))
		if field.get("type") == "choice":
			var dropdown := OptionButton.new()
			dropdown.custom_minimum_size.y = 46
			dropdown.fit_to_longest_item = false
			dropdown.clip_text = true
			dropdown.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			var values: Array = []
			for option in field.get("options",[]):
				dropdown.add_item(str(option.get("label",option.get("id",""))) if option is Dictionary else str(option))
				values.append(option.get("id",option.get("value")) if option is Dictionary else option)
			box.add_child(dropdown)
			editors[key] = {"node":dropdown,"options":values}
		else:
			var input := LineEdit.new()
			input.custom_minimum_size.y = 46
			input.placeholder_text = str(field.get("placeholder",action.get("placeholder","请输入")))
			input.add_theme_color_override("font_color",INK)
			input.add_theme_color_override("font_placeholder_color",Color("526059"))
			input.add_theme_color_override("caret_color",INK)
			box.add_child(input)
			editors[key] = {"node":input,"type":field.get("type","text")}
	box.add_child(_button("确认",func():
		var result: Dictionary = {}
		for key in editors:
			var editor: Dictionary = editors[key]
			if editor.node is OptionButton:
				result[key] = editor.options[editor.node.selected] if editor.node.selected >= 0 and editor.node.selected < editor.options.size() else ""
			else: result[key] = str(editor.node.text)
		_close_modal()
		State.act(str(action.id),result if action.has("inputs") else result.get("value",""))
	))

func _show_file_dialog(saving: bool) -> void:
	export_mode=saving
	file_dialog.file_mode=FileDialog.FILE_MODE_SAVE_FILE if saving else FileDialog.FILE_MODE_OPEN_FILE
	if saving: file_dialog.current_file="7-55-native-save.json"
	file_dialog.popup_centered(NativeFileDialogTheme.fit(file_dialog,size))

func _show_settings() -> void:
	# The active minigame owns its input surface, as does the source game host.
	# Phone chrome already blocks this entry; the native F10 shortcut follows
	# the same rule instead of mounting a second input owner over a live run.
	if is_instance_valid(active_game): return
	var box := _modal_base("控制中心")
	box.add_child(_button("当前：%s → 切换%s" % ["深色观察" if State.d.native.mode == "dark" else "浅色操作","浅色操作" if State.d.native.mode == "dark" else "深色观察"],func(): State.toggle_mode(); _show_settings()))
	box.add_child(_button("保存进度",func(): _feedback("已保存" if State.save_game() else "测试会话不覆盖正式存档")))
	box.add_child(_button("导出存档",func(): _show_file_dialog(true)))
	box.add_child(_button("导入存档",func(): _show_file_dialog(false)))
	box.add_child(_button("重新开始",func():
		var confirm := _modal_base("确认重新开始？")
		confirm.add_child(_label("将重置故事进度。此操作不会退出应用。",17))
		confirm.add_child(_button("确认重置",func(): State.new_game(); _close_modal()))
	))
	box.add_child(_button("全屏 / 窗口",func(): DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)))
	box.add_child(_button("DEV · 独立场景检查",_show_developer))
	box.add_child(_button("保存画面截图",func(): _close_modal(); _capture.call_deferred()))
	var note := _label("原生 Godot 迁移进行中\n支持原生存档与原版浏览器 v2–35 存档。",15,Color("6b756c"))
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(note)

func _show_developer() -> void:
	var box := _modal_base("DEV · 不写入正式存档")
	box.add_child(_label("正式进度已隔离；检查点使用原版完整状态。",16))
	if ResourceLoader.exists("res://tests/visual_gallery.gd"):
		box.add_child(_button("生成真实页面回归图（不改正式进度）",_run_visual_gallery))
	var checkpoint_select := OptionButton.new()
	checkpoint_select.custom_minimum_size.y = 46
	checkpoint_select.fit_to_longest_item = false
	checkpoint_select.clip_text = true
	checkpoint_select.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var checkpoints: Array = State.developer_checkpoints()
	for checkpoint in checkpoints: checkpoint_select.add_item(str(checkpoint.chapter)+" · "+str(checkpoint.label))
	box.add_child(checkpoint_select)
	box.add_child(_button("载入剧情检查点",func():
		if checkpoint_select.selected >= 0 and checkpoint_select.selected < checkpoints.size():
			State.begin_checkpoint(str(checkpoints[checkpoint_select.selected].id))
			_close_modal()
	))
	box.add_child(_label("只看场景（不补全前置剧情）：",16))
	for entry in [[1,"dorm_hub","宿舍"],[2,"campus_bootstrap","校园"],[2,"library_interior","图书馆"],[3,"canteen_interior","食堂"],[3,"theater_interior","剧场"],[3,"qizhen_lake","启真湖"],[4,"duan_yongping_temporal_maze","教学楼"]]:
		var choice: Array = entry
		box.add_child(_button(str(choice[2]),func(): State.begin_preview(int(choice[0]),str(choice[1])); _close_modal()))
	if State.developer_mode: box.add_child(_button("恢复正式进度",func(): State.restore_formal(); _close_modal()))

func _focus_library_story() -> void:
	# Library dialogue owns root focus. Return it after the view has closed so
	# the next prompted world interaction works without a pointer click.
	if not is_instance_valid(world) or not world_frame.is_visible_in_tree() or str(world.scene_id)!="library_interior": return
	if world._interaction_presentation_blocks() or world._shell_input_blocked(): return
	if State.get_library_story_session()!=null or (is_instance_valid(world_effect) and world_effect.get_meta("blocks_input",false)): return
	world.grab_focus()

func _show_world_mobile() -> void:
	if not _has_world_scene(): return
	world_page_origin_scene=""
	_cancel_surface_gestures()
	mobile_world = true
	_layout()
	_resume_world_activity()
	_focus_world_surface.call_deferred()

func _recovered_replay_eligible() -> bool:
	var recovered: Dictionary=State.d.get("chapterThreeInterlude",{})
	return State.d.get("qizhenLake",{}).get("phase","")=="complete" and recovered.get("phase","")=="replay_ready" and bool(recovered.get("replayUnlocked",false)) and not bool(State.d.get("chapter4",{}).get("prologueSeen",false))

func _resume_recovered_replay() -> void:
	# Admission belongs to the explicit source transition or ordinary startup.
	# Return, resize and refresh never poll this gate or recreate a closed film.
	if not is_inside_tree() or not _recovered_replay_eligible(): return
	if is_instance_valid(active_game) or is_instance_valid(modal) or is_instance_valid(phone_document) or is_instance_valid(world_effect): return
	if State.story_input_locked() or bool(State.d.ui.controlCenterOpen): return
	toast.text=""; toast_time=0; toast.hide()
	State.act("c4_prologue")

func _is_bike_chase_entry() -> bool:
	var chase: Dictionary=State.d.canteenHunt
	return str(State.d.native.scene)=="campus_bootstrap" and bool(chase.active) and str(chase.phase)=="chasing" and bool(chase.bikePaid) and not bool(chase.chaseCompleted)

func _resume_world_activity() -> void:
	if not _is_bike_chase_entry():
		_resume_canteen_defense(); return
	# RpgGameHost mounts the chase for this persisted phase. Paid chase_ready
	# still uses the existing bike interaction; Exit is never polled/reopened.
	if not is_inside_tree() or not world_frame.is_visible_in_tree(): return
	if is_instance_valid(active_game) or is_instance_valid(modal) or is_instance_valid(phone_document) or is_instance_valid(world_effect): return
	if bool(State.d.ui.controlCenterOpen) or State.story_input_locked(): return
	if is_instance_valid(c3_scene_host) and c3_scene_host.owns_world_contract(): return
	mobile_world=true
	State.act("c3_chase")

func _is_canteen_defense_entry() -> bool:
	return str(State.d.native.scene)=="canteen_interior" and bool(State.d.canteenHunt.active) and str(State.d.canteenHunt.phase)=="exit_blocking"

func _resume_canteen_defense() -> void:
	# Source CanteenInteriorScene starts defense when an exit_blocking scene
	# is entered. Admission belongs to scene entry/explicit Return, never to
	# refresh, resize or a per-frame loop: Exit must remain exited.
	if not is_inside_tree() or not world_frame.is_visible_in_tree(): return
	if not _is_canteen_defense_entry(): return
	if is_instance_valid(active_game) or is_instance_valid(modal) or is_instance_valid(phone_document) or is_instance_valid(world_effect): return
	if bool(State.d.ui.controlCenterOpen) or State.story_input_locked(): return
	if is_instance_valid(c3_scene_host) and c3_scene_host.owns_world_contract(): return
	# Desktop entry also owns a world return after rotation, Exit or victory.
	mobile_world=true
	State.act("c3_defense")

func _play_audio(path: String) -> void:
	var resolved := State.asset(path)
	if ResourceLoader.exists(resolved):
		voice_player.stop()
		voice_player.stream = load(resolved)
		voice_player.volume_db = linear_to_db(float(State.d.native.settings.volume))
		voice_player.play()

func _open_game(config: Dictionary) -> void:
	if config.get("type","")=="chase" and config.get("departure",false):
		_open_chase_film("start")
		return
	if config.get("type","")=="chase":
		_queue_chase_scene("ride",config)
		return
	_open_game_now(config)

func _open_game_now(config: Dictionary) -> void:
	# The source opens the real A1 doors before the registered lamp questions.
	# This local visual prelude never changes controller facts or completion proof.
	if config.get("kind","")=="star_lamp_closure" and not config.get("native_exterior_presented",false):
		_cancel_world_effect(); _close_modal(); _show_world_mobile()
		world_effect=load("res://scripts/ui/chapter4_exterior_door.gd").new()
		world.add_child(world_effect)
		world_effect.opened.connect(func():
			var continued: Dictionary=config.duplicate(true)
			continued.native_exterior_presented=true
			_open_game(continued)
		)
		world_effect.setup(_read_runtime_state,func(source: Vector2): return world.size/2+(source-world.camera)*world.zoom)
		return
	_cancel_world_effect()
	_close_modal()
	if is_instance_valid(active_game):
		if active_game.has_method("dispose_presentation"):active_game.dispose_presentation()
		active_game.queue_free()
	var path := str(config.get("script","res://scripts/ui/minigame_host.gd"))
	if not ResourceLoader.exists(path):
		_feedback("该原生小游戏尚未接入，剧情未前进。")
		return
	active_game = load(path).new()
	active_game.z_index = 100
	if is_instance_valid(phone_chrome): phone_chrome.set_input_blocked(true)
	var game_size = config.get("viewport",[960,540])
	game_viewport = Vector2(float(game_size[0]),float(game_size[1]))
	active_game.custom_minimum_size = game_viewport
	active_game.size = game_viewport
	add_child(active_game)
	var owned_game: Control=active_game
	var finish := func(result: Dictionary):
		if not is_instance_valid(owned_game) or active_game!=owned_game:return
		var callback := str(config.get("on_success",config.get("callback","")))
		if config.get("type","")=="chase" and callback=="c3_chase_result":
			_finish_chase_owner(owned_game,result)
			return
		# Tiyi retains its finished track while the existing chapter authority
		# validates the unchanged ten-fix proof. Return only closes this view.
		if path == "res://scripts/games/virtual_run.gd" and is_instance_valid(active_game) and active_game.has_method("resolve"):
			var submitted_game: Control = active_game
			if not callback.is_empty(): State.act(callback,result)
			if is_instance_valid(submitted_game) and active_game == submitted_game:
				submitted_game.resolve(bool(State.d.actOne.exerciseStarted))
			_layout()
			return
		var node := active_game
		active_game = null
		if is_instance_valid(node): node.queue_free()
		if not callback.is_empty(): State.act(callback,result)
		_layout()
		if config.get("type","")=="rhythm": _focus_world_surface.call_deferred()
	if active_game.has_signal("finished"): active_game.connect("finished",finish)
	elif active_game.has_signal("completed"): active_game.connect("completed",finish)
	if active_game.has_signal("cancelled"):
		active_game.connect("cancelled",func():
			if not is_instance_valid(owned_game) or active_game!=owned_game:return
			if owned_game.has_method("dispose_presentation"):owned_game.dispose_presentation()
			if is_instance_valid(active_game): active_game.queue_free()
			active_game = null
			_layout()
			if config.get("type","")=="chase":_focus_chase_world.call_deferred()
			elif config.get("type","")=="rhythm":_focus_world_surface.call_deferred()
		)
	if active_game.has_signal("attempt_submitted"):
		var submitted_game: Control=active_game
		active_game.connect("attempt_submitted",func(proof: Dictionary):
			var before_round: int=int(State.d.theaterHunt.spotlightRound)
			State.act(str(config.get("on_attempt","")),proof)
			if is_instance_valid(submitted_game): submitted_game.resolve(int(State.d.theaterHunt.spotlightRound)>before_round,State.d.theaterHunt.phase=="reversal")
		)
	if active_game.has_signal("presentation_requested"):
		active_game.connect("presentation_requested",_game_presentation)
	if active_game.has_method("setup"): active_game.setup(config)
	elif active_game.has_method("start"): active_game.start(config)
	if _activity_owns_scene(): mobile_world=true
	_layout()

## The accepted replay is saved before an optional arrival film. The film has
## no domain callback, so skipping, cancelling or reloading cannot grant twice.
func _finish_chase_owner(owner: Control,proof: Dictionary) -> void:
	if not is_instance_valid(owner) or active_game!=owner or owner.get_meta("proof_submitted",false):return
	owner.set_meta("proof_submitted",true)
	owner.set_process(false);owner.set_process_input(false)
	if owner.has_method("dispose_presentation"):owner.dispose_presentation()
	var accepted: Dictionary=State.act("c3_chase_result",proof)
	if accepted.get("chase_arrival",false):
		# The accepted result remains in the journal. The film owns its visible
		# caption, so the same success message must not cover it a second time.
		toast.text="";toast_time=0;toast.hide();_layout_toast()
	# Release the entire ride viewport before allocating the ending world.
	await get_tree().process_frame
	if not is_instance_valid(owner) or active_game!=owner:return
	active_game=null;owner.queue_free()
	if accepted.get("chase_arrival",false) and State.d.canteenHunt.chaseCompleted and State.d.canteenHunt.phase=="theater_reached":
		_open_chase_film("finish")
	else:_layout()

func _open_chase_film(stage: String) -> void:
	_queue_chase_scene(stage,{})

func _queue_chase_scene(stage: String,config: Dictionary) -> void:
	_cancel_world_effect();_close_modal()
	if is_instance_valid(active_game):
		if active_game.has_method("dispose_presentation"):active_game.dispose_presentation()
		active_game.queue_free()
	var loading: Control=load("res://scripts/presentation/chase_loading.gd").new()
	active_game=loading;loading.z_index=120;mobile_world=true
	var admitted: Array[Control]=[null]
	add_child(loading)
	loading.cancelled.connect(func():
		if active_game!=loading and active_game!=admitted[0]:return
		if stage=="ride":_game_presentation("native_activity_closed",{"prefixes":["native_chase_","canteen_chase_"]})
		if is_instance_valid(admitted[0]):
			if admitted[0].has_method("dispose_presentation"):admitted[0].dispose_presentation()
			admitted[0].queue_free()
		active_game=null;loading.queue_free();_layout();_focus_chase_world.call_deferred())
	_layout()
	# Draw the acknowledgement before synchronous resource creation. The
	# captured owner also prevents Exit or replacement from reopening a scene.
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_instance_valid(loading) or active_game!=loading:return
	active_game=null
	if stage=="ride":_open_game_now(config)
	else:_open_chase_film_now(stage)
	admitted[0]=active_game
	if not is_instance_valid(admitted[0]):loading.queue_free();return
	# Keep the acknowledgement as the input owner through the first loaded
	# frame. Clicks queued during synchronous allocation must reach Return,
	# never the newly revealed Start button at a similar screen position.
	admitted[0].process_mode=Node.PROCESS_MODE_DISABLED
	loading.grab_focus()
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_instance_valid(loading):return
	loading.queue_free()
	if is_instance_valid(admitted[0]) and active_game==admitted[0]:
		admitted[0].process_mode=Node.PROCESS_MODE_INHERIT
		if admitted[0].focus_mode!=Control.FOCUS_NONE:admitted[0].grab_focus()
		else:get_viewport().gui_release_focus()

func _open_chase_film_now(stage: String) -> void:
	_cancel_world_effect();_close_modal()
	if is_instance_valid(active_game):
		if active_game.has_method("dispose_presentation"):active_game.dispose_presentation()
		active_game.queue_free()
	var presenter: Control=load("res://scripts/presentation/chase_transition_3d_presenter.gd").new()
	active_game=presenter;presenter.z_index=100
	game_viewport=Vector2(960,540);mobile_world=true
	add_child(presenter)
	presenter.completed.connect(func(completed_stage: String,_skipped: bool):
		if active_game!=presenter or completed_stage!=stage:return
		if stage=="start":_continue_chase_departure(presenter)
		else:_close_chase_film(presenter))
	presenter.cancelled.connect(func(_cancelled_stage: String):_close_chase_film(presenter))
	_layout()
	presenter.play(stage,false,bool(State.d.native.settings.get("reduced_motion",false)))

func _close_chase_film(owner: Control) -> void:
	if not is_instance_valid(owner) or active_game!=owner:return
	owner.dispose();active_game=null;owner.queue_free();mobile_world=true;_layout()
	_focus_chase_world.call_deferred()

func _focus_chase_world() -> void:
	if not is_instance_valid(world) or not world_frame.is_visible_in_tree():return
	if world._shell_input_blocked() or world._interaction_presentation_blocks():return
	# Root phone buttons and the world SubViewport have separate focus owners.
	get_viewport().gui_release_focus()
	world.grab_focus()

func _continue_chase_departure(owner: Control) -> void:
	if not is_instance_valid(owner) or active_game!=owner:return
	owner.dispose()
	# No overlapping transition and ride worlds; stale callbacks cannot reopen.
	owner.release_render_world()
	await get_tree().process_frame
	if not is_instance_valid(owner) or active_game!=owner:return
	active_game=null;owner.queue_free()
	if State.d.canteenHunt.phase=="chase_ready" and State.d.canteenHunt.bikePaid and not State.d.canteenHunt.chaseCompleted:
		State.act("c3_chase_departed")
	_layout()

func _open_narrative(config: Dictionary) -> void:
	var box := _modal_base(str(config.get("title","7:55")))
	var label := _label(str(config.get("text",config.get("body",""))),20)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(label)
	box.add_child(_button("继续",func(): _close_modal(); State.act(str(config.get("on_complete","")),{"acknowledged":true})))

func _on_file_selected(path: String) -> void:
	if export_mode: _feedback("已导出存档" if State.export_save(path) == OK else "导出失败，进度仍保留。")
	else: _feedback(str(State.import_save(path).message))

func _feedback_world_active() -> bool:
	return is_instance_valid(world) and is_instance_valid(world_frame) and world_frame.is_visible_in_tree() and not str(State.d.native.scene).is_empty() and not is_instance_valid(active_game)

func _virtual_run_owns_feedback(message: String) -> bool:
	if not is_instance_valid(active_game) or not active_game.has_method("owns_result_feedback"): return false
	if str(active_game.get_script().resource_path) != "res://scripts/games/virtual_run.gd": return false
	return active_game.owns_result_feedback(message)

func _feedback(message: String,tone: String="system") -> void:
	# The device owns failed-attempt feedback while submitting.
	if is_instance_valid(modal) and modal.has_method("owns_feedback") and modal.owns_feedback(): return
	if _virtual_run_owns_feedback(message): return
	if _scene_owns_feedback(message):
		toast.text=""; toast_time=0; toast.hide()
		_layout_toast()
		return
	var duration: float=clampf(1.6+message.length()*.12,2.4,6.5)
	if _feedback_world_active() and not is_instance_valid(modal_notice_slot):
		# One subtitle owner: the source RPG bottom-safe-zone surface.
		toast.text=""; toast_time=0; toast.hide()
		world.subtitle=message; world.subtitle_left=duration; world.queue_redraw()
		return
	PhoneNotice.set_message(toast,message,str(PhoneNotice.SPEAKERS.get(tone,"系统")))
	toast_time = duration
	_layout_toast()
	toast.move_to_front()

func _process(delta: float) -> void:
	if compact_world_contract!=(mobile_world and _uses_compact_layout() and not _authored_world_contract()): _layout()
	_sync_inventory_dock_input()
	if is_instance_valid(c3_device_panel) and is_instance_valid(world):
		c3_device_panel.set_feedback(world.subtitle if world.subtitle_left>0 else "")
	for cue: String in State.advance_phone_entry(delta*1000): _play_presentation_cue(cue)
	if toast_time > 0:
		toast_time -= delta
		if toast_time <= 0:
			toast.text = ""; toast.hide()
			_layout_toast()
	if _screenshot_requested and Engine.get_process_frames() > 90:
		_screenshot_requested = false
		_capture.call_deferred()

func _capture() -> void:
	await RenderingServer.frame_post_draw
	if DisplayServer.get_name() != "headless":
		var capture_path := "user://screenshot.png"
		if FileAccess.file_exists("res://project.godot"):
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.screenshots"))
			capture_path = "res://.screenshots/"+str(State.d.native.page)+"-"+str(Time.get_ticks_msec())+".png"
		get_viewport().get_texture().get_image().save_png(capture_path)
		print("Screenshot: ",ProjectSettings.globalize_path(capture_path))

func _unhandled_key_input(event: InputEvent) -> void:
	if not is_visible_in_tree(): return
	if event is InputEventKey and event.pressed and not event.echo:
		if is_instance_valid(modal):
			if event.keycode == KEY_F12: _capture.call_deferred()
			return
		var focused := get_viewport().gui_get_focus_owner()
		if event.keycode == KEY_P and not event.ctrl_pressed and not event.alt_pressed and not event.meta_pressed and not (focused is LineEdit or focused is TextEdit):
			if mobile_world: _show_phone_surface()
			else: _return_from_phone()
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_ESCAPE and not mobile_world:
			_return_from_phone()
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_F10: _show_settings()
		if event.keycode == KEY_F12: _capture.call_deferred()
		if event.keycode == KEY_D and event.ctrl_pressed and event.shift_pressed: _show_developer()
		if event.keycode == KEY_G and event.ctrl_pressed and event.shift_pressed: _run_visual_gallery()

func _read_runtime_state() -> Dictionary:
	var snapshot: Dictionary = State.d.duplicate(true)
	snapshot.native["host"] = {"phone_modal_open":is_instance_valid(modal) or is_instance_valid(phone_document) or bool(State.d.ui.controlCenterOpen),"minigame_open":is_instance_valid(active_game),"focused":get_window().has_focus(),"world_visible":is_instance_valid(world) and world_frame.is_visible_in_tree(),"world_scene":str(world.scene_id) if is_instance_valid(world) else "","world_display_scale":world_frame.scale.x if is_instance_valid(world_frame) else 1.0}
	return snapshot

func _setup_runtime_hosts() -> void:
	if ResourceLoader.exists("res://scripts/presentation/c3_narrative_host.gd") and c3_narrative_host==null:
		c3_narrative_host=load("res://scripts/presentation/c3_narrative_host.gd").new(); add_child(c3_narrative_host)
		c3_narrative_host.cinematic_started.connect(_layout)
		c3_narrative_host.setup(world,func() -> Dictionary: return State.d,State.get_c3_narrative_session,State.act,_game_presentation,_read_runtime_state)
		if c3_narrative_host.has_signal("inspect_requested"): c3_narrative_host.inspect_requested.connect(_inspect_item_by_id)
	if ResourceLoader.exists("res://scripts/presentation/library_story_host.gd") and library_story_host==null:
		library_story_host=load("res://scripts/presentation/library_story_host.gd").new(); add_child(library_story_host)
		library_story_host.setup(func() -> Dictionary: return State.d,State.get_library_story_session,State.act,_game_presentation,_read_runtime_state)
	if ResourceLoader.exists("res://scripts/presentation/c3_scene_host.gd") and c3_scene_host == null:
		c3_scene_host=load("res://scripts/presentation/c3_scene_host.gd").new()
		add_child(c3_scene_host)
		c3_scene_host.cinematic_started.connect(_layout)
		c3_scene_host.setup(world,func() -> Dictionary: return State.d,State.get_scene_session,State.act,_game_presentation,_read_runtime_state)
	if ResourceLoader.exists("res://scripts/media/audio_director.gd") and audio_director == null:
		audio_director = load("res://scripts/media/audio_director.gd").new()
		add_child(audio_director)
		audio_director.external_cue_prefixes = ["chapter35_voice_audition_"]
		audio_director.setup(_read_runtime_state)
		State.action_completed.connect(audio_director.update_state)
		audio_director.subtitle_timed.connect(func(text: String,surface: String,duration_ms: float,_tone: String):
			if surface == "toast":
				if is_instance_valid(active_game) and active_game.has_method("owns_pickup_subtitle") and active_game.owns_pickup_subtitle(text): return
				if _virtual_run_owns_feedback(text): return
				_feedback(text,_tone)
				if _feedback_world_active(): world.subtitle_left=maxf(.1,duration_ms/1000.0)
				else: toast_time = maxf(.1,duration_ms/1000.0)
		)
		audio_director.visual_requested.connect(_presentation_visual)
		audio_director.inspect_requested.connect(_inspect_item_by_id)
		State.feedback.connect(audio_director.feedback)
	if ResourceLoader.exists("res://scripts/media/c3_media_host.gd") and media_host == null:
		media_host = load("res://scripts/media/c3_media_host.gd").new()
		add_child(media_host)
		media_host.setup(_read_runtime_state)
		media_host.event.connect(func(action: String,value: Variant): State.act(action,value))
	if ResourceLoader.exists("res://scripts/media/c3_battery_prank.gd") and battery_prank == null:
		battery_prank = load("res://scripts/media/c3_battery_prank.gd").new()
		add_child(battery_prank)
		battery_prank.setup(_read_runtime_state)
		battery_prank.set_anchors_preset(Control.PRESET_TOP_LEFT)

func _apply_media(config: Dictionary) -> void:
	_setup_runtime_hosts()
	if is_instance_valid(media_host): media_host.apply(config)
	else: _feedback("音频播放组件尚未就绪，进度没有改变。")

func _cancel_world_effect() -> void:
	if is_instance_valid(world_effect) and world_effect.has_method("cancel"): world_effect.cancel()

func _open_world_effect(config: Dictionary) -> void:
	_cancel_world_effect()
	if not world or not ResourceLoader.exists(str(config.get("script",""))): return
	world.refresh_world()
	world_effect = load(str(config.script)).new()
	world.add_child(world_effect)
	world_effect.set_meta("blocks_input",bool(config.get("blocks_input",false)))
	var setup := config.duplicate()
	setup["read_state"] = _read_runtime_state
	setup["world"] = world
	setup["project_position"] = func(source: Vector2): return world.size/2+(source-world.camera)*world.zoom
	world_effect.event.connect(func(action: String,value: Variant): State.act(action,value))
	var effect_owner:Control=world_effect
	world_effect.tree_exited.connect(func():
		if world_effect==effect_owner:_focus_world_surface.call_deferred()
	)
	world_effect.setup(setup)

func _capture_world(config: Dictionary) -> void:
	var session = config.get("session")
	if session == null: return
	if capture_busy or DisplayServer.get_name() == "headless" or not is_instance_valid(world) or world.scene_id != str(config.get("scene","qizhen_lake")):
		if session.has_method("fail_from_host"): session.fail_from_host("当前没有可拍摄的现场画面。")
		State.act(str(config.get("on_cancel","c3_journal_capture_cancel")),session)
		return
	capture_busy = true
	_cancel_world_effect()
	world.capture_mode = true
	world.queue_redraw()
	await RenderingServer.frame_post_draw
	var path := ""
	var metadata: Dictionary = {}
	var photograph := world_viewport.get_texture().get_image()
	if not photograph.is_empty():
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://qizhen_journal"))
		path = "user://qizhen_journal/"+str(Time.get_ticks_usec())+".png"
		if photograph.save_png(path) != OK: path = ""
		metadata = {"source":"world_viewport_crop","width":photograph.get_width(),"height":photograph.get_height(),"scene":str(world.scene_id),"zone":str(State.d.qizhenLake.zone),"player":State.d.native.player.duplicate(true),"camera":{"x":world.camera.x,"y":world.camera.y,"zoom":world.zoom},"speed":float(world.kayak.speed) if world.kayak else 0.0,"roll":float(world.kayak.roll) if world.kayak else 0.0,"heading":float(world.kayak.heading) if world.kayak else 0.0,"capturedAtSeconds":int(floor(Time.get_ticks_msec()/1000.0))}
	world.capture_mode = false
	world.queue_redraw()
	capture_busy = false
	if path.is_empty():
		if session.has_method("fail_from_host"): session.fail_from_host("画面读取失败，请回到现场重试。")
		State.act(str(config.get("on_cancel","c3_journal_capture_cancel")),session)
		return
	session.receive_capture(path,metadata)
	State.act(str(config.get("on_success","c3_journal_capture_result")),session)

func _reset_runtime_presentations() -> void:
	photo_brightness_session.reset()
	observation_comparison_session.clear()
	world_page_origin_scene=""
	_restore_shell_surface()
	if is_instance_valid(world):
		world.world_key=""; world.scene_id=""; world.pending_teleport=Vector2.INF
		world.guard_kind=""; world.move_target=Vector2.INF; world.touch_axis=Vector2.ZERO
	if is_instance_valid(c3_narrative_host): c3_narrative_host.reset()
	_close_phone_document()
	if is_instance_valid(library_story_host): library_story_host.reset()
	if is_instance_valid(c3_scene_host): c3_scene_host.reset()
	if is_instance_valid(control_center): control_center.queue_free()
	control_center=null
	State.d.ui.controlCenterOpen=false
	_close_modal()
	_cancel_world_effect()
	if is_instance_valid(active_game): active_game.queue_free()
	active_game = null
	if is_instance_valid(voice_player): voice_player.stop()
	if is_instance_valid(audio_director):
		audio_director.reset()
		audio_director.setup(_read_runtime_state)
	if is_instance_valid(media_host) and media_host.has_method("_stop_current"): media_host._stop_current()
	if is_instance_valid(battery_prank): battery_prank.reset()
	_resume_canteen_defense_after_reset.call_deferred()

func _resume_canteen_defense_after_reset() -> void:
	# Import installs state before story_reset; fit the new scene before entry.
	if not is_inside_tree(): return
	_layout()
	_resume_world_activity()

func _play_presentation_cue(cue: String) -> void:
	if is_instance_valid(audio_director): audio_director.cue(cue)

func _game_presentation(cue: String,payload: Dictionary = {}) -> void:
	if is_instance_valid(audio_director): audio_director.cue(cue,payload)

func _presentation_visual(definition: Dictionary) -> void:
	var text := str(definition.get("title",""))
	var detail := str(definition.get("detail",""))
	if not detail.is_empty(): text += "\n" + detail
	if text.is_empty(): return
	_feedback(text)
	if _feedback_world_active(): world.subtitle_left=maxf(.1,float(definition.get("durationMs",2600))/1000.0)
	else: toast_time = maxf(.1,float(definition.get("durationMs",2600))/1000.0)

func _combine_inventory_items(a: String,b: String) -> void:
	var pair := [a,b]
	for recipe in [["theaterTicketHalfA","theaterTicketHalfB","c3_ticket_combine"],["fishingRod","decoyPaper","c3_bait"],["nylonCord","brokenNetFrame","c3_net_combine"],["fishingRod","swanMagnet","c3_magnet_combine"]]:
		if recipe[0] in pair and recipe[1] in pair:
			State.act(str(recipe[2]))
			return
	State.act("c1_combine",{"a":a,"b":b})

func _on_phone_page(page: String) -> void:
	if page=="control_center":
		_cancel_world_effect()
		State.d.ui.controlCenterOpen=true
		_refresh_control_center()
		return
	world_page_origin_scene=""
	State.open_page(page)

func _on_phone_action(id: String,value: Variant) -> void:
	match id:
		"native_control_center_close":
			State.d.ui.controlCenterOpen=false
			_refresh_control_center()
			return
		"native_save_tools": _show_settings(); return
		"native_save_now": _feedback("进度已保存。" if State.save_game() else "测试会话不覆盖正式存档。"); return
		"native_reset_progress": State.new_game(); return
	if value==null:
		var page: String="control_center" if State.d.ui.controlCenterOpen else str(State.d.native.page)
		for action in State.get_actions(page):
			if str(action.id)==id: _invoke_action(action); return
	State.act(id,value)

func _refresh_control_center() -> void:
	if is_instance_valid(control_center):
		phone.remove_child(control_center)
		control_center.queue_free()
	control_center=null
	if not State.d.ui.controlCenterOpen: return
	if control_builder==null:
		control_builder=load("res://scripts/ui/phone_pages.gd").new()
		control_builder.action_requested.connect(_on_phone_action)
		control_builder.page_requested.connect(_on_phone_page)
		control_builder.presentation_requested.connect(_play_presentation_cue)
	control_center=control_builder.build("control_center",State.get_view("control_center"),State.d)
	control_center.z_index=65
	phone.add_child(control_center)

func _inspect_item_by_id(id: String) -> void:
	var items: Variant=State.content("items.config.json")
	if items is Array:
		for item in items:
			if str(item.get("id",""))==id:
				_inspect_item(item)
				return

func _run_visual_gallery() -> void:
	if not ResourceLoader.exists("res://tests/visual_gallery.gd"): return
	var runner=load("res://tests/visual_gallery.gd").new()
	get_tree().root.add_child(runner)
	runner.start(self)

func _request_quit() -> void:
	if _quit_requested: return
	_quit_requested = true
	await shutdown()
	get_tree().quit()

func shutdown() -> void:
	# Native audio retires on the mixer thread. Await the real owners before
	# immediate test/standalone exit instead of leaking a still-playing stream.
	set_process(false)
	if is_instance_valid(world): world.set_process(false)
	if is_instance_valid(c3_scene_host): c3_scene_host.reset(); c3_scene_host.set_process(false)
	if is_instance_valid(library_story_host): library_story_host.reset(); library_story_host.set_process(false)
	if is_instance_valid(c3_narrative_host): c3_narrative_host.reset(); c3_narrative_host.set_process(false)
	_cancel_world_effect()
	if is_instance_valid(active_game): active_game.queue_free(); active_game=null
	if is_instance_valid(voice_player): voice_player.stop(); voice_player.stream=null
	if is_instance_valid(media_host): await media_host.shutdown()
	if is_instance_valid(battery_prank): await battery_prank.shutdown()
	if is_instance_valid(audio_director): await audio_director.shutdown()

func _open_phone_document(config: Dictionary) -> void:
	_close_phone_document()
	var focused: Control=get_viewport().gui_get_focus_owner()
	phone_document_previous_focus=weakref(focused) if focused!=null else null
	phone_document=Control.new(); phone_document.custom_minimum_size=Vector2(424,854); phone_document.z_index=120
	phone.add_child(phone_document)
	var overlay: Control=load("res://scripts/ui/phone_document_modal.gd").new()
	overlay.setup(phone_builder,str(config.get("item_id","")),true)
	overlay.scale=Vector2.ONE*phone_builder.PHONE_SCALE
	phone_document.add_child(overlay)
	overlay.closed.connect(_close_phone_document)
	if is_instance_valid(phone_chrome): phone_chrome.set_input_blocked(true)
	_layout()

func _close_phone_document() -> void:
	if is_instance_valid(phone_document): phone_document.queue_free()
	phone_document=null
	_sync_inventory_dock_input()
	if phone_document_previous_focus!=null:
		var control=phone_document_previous_focus.get_ref()
		if is_instance_valid(control) and control.is_inside_tree(): control.grab_focus()
	phone_document_previous_focus=null
	if is_instance_valid(phone_chrome): phone_chrome.set_input_blocked(is_instance_valid(modal) or is_instance_valid(active_game))
