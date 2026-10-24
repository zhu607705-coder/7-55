extends SceneTree
## Actual Main regressions: native picker theme isolation and generic-modal
## notice ownership. DEV state and isolated user paths never write formal saves.
const Ui=preload("res://scripts/ui/native_ui_theme.gd")
const Notice=preload("res://scripts/ui/native_phone_notice.gd")
var checks:=0
var failures:=0
var shell: Control
var state: Node
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("DIALOG NOTICE: "+message)
func frames(count: int=3) -> void:
	for i in count:await process_frame
func key(code: Key) -> void:
	for down in [true,false]:
		var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=down
		root.push_input(event,true);await frames(1)
func click(button: Control) -> void:
	check(button!=null,"click target exists")
	if button==null:return
	var at:=button.get_global_transform_with_canvas()*(button.size/2)
	var viewport:=button.get_viewport()
	if viewport is Window and viewport!=root:at+=Vector2(viewport.position)
	var motion:=InputEventMouseMotion.new();motion.position=at;root.push_input(motion,true)
	for down in [true,false]:
		var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.position=at;event.global_position=at;event.pressed=down
		root.push_input(event,true);await frames(1)
func controls(node: Node,result: Array[Control]) -> void:
	for child in node.get_children(true):
		if child is Control:result.append(child)
		controls(child,result)
func button_with_text(node: Node,text: String) -> Button:
	var found: Array[Control]=[];controls(node,found)
	for child in found:
		if child is Button and child.text==text and child.is_visible_in_tree():return child
	return null
func blend(foreground: Color,background: Color) -> Color:
	return Color(background.r*(1.0-foreground.a)+foreground.r*foreground.a,background.g*(1.0-foreground.a)+foreground.g*foreground.a,background.b*(1.0-foreground.a)+foreground.b*foreground.a,1)
func background(control: Control,style_name: String,base: Color) -> Color:
	var style:=control.get_theme_stylebox(style_name)
	return blend(style.bg_color,base) if style is StyleBoxFlat else base
func readable(control: Control,color_name: String,base: Color,minimum: float,context: String) -> void:
	var ink:=blend(control.get_theme_color(color_name),base)
	var ratio:=Ui._contrast(ink,base)
	check(ratio>=minimum,context+" "+control.get_class()+" "+color_name+" contrast="+str(ratio))
func check_dialog_theme() -> void:
	var dialog: FileDialog=shell.file_dialog
	var panel: StyleBoxFlat=dialog.get_theme_stylebox("panel","AcceptDialog")
	var base:=panel.bg_color
	check(base==ThemeDB.get_default_theme().get_stylebox("panel","AcceptDialog").bg_color,"native dark panel retained")
	check(dialog.theme!=shell.theme,"FileDialog explicitly owns independent complete theme")
	var found: Array[Control]=[];controls(dialog,found)
	var labels:=0;var fields:=0;var buttons:=0;var disabled:=0;var lists:=0
	for child in found:
		if not child.is_visible_in_tree():continue
		if child is Label and not child.text.is_empty():
			labels+=1;readable(child,"font_color",base,4.5,"visible native label")
			check(child.get_theme_font("font")==load("res://scripts/ui/native_typography.gd").body_font(),"native label uses the shared bundled readable body font")
		elif child is LineEdit:
			fields+=1
			readable(child,"font_color",background(child,"normal",base),4.5,"visible native field")
			readable(child,"font_uneditable_color",background(child,"read_only",base),3.0,"native readonly field")
			readable(child,"font_placeholder_color",background(child,"normal",base),4.5,"native placeholder")
		elif child is Button:
			buttons+=1
			for variant in [["font_color","normal"],["font_hover_color","hover"],["font_pressed_color","pressed"]]:
				readable(child,variant[0],background(child,variant[1],base),4.5,"native action")
			readable(child,"font_disabled_color",background(child,"disabled",base),3.0,"native disabled action")
			if child.disabled:disabled+=1
		elif child is ItemList:
			lists+=1;readable(child,"font_color",background(child,"panel",base),4.5,"visible native file list")
	check(labels>=4,"actual path/sidebar/file captions checked")
	check(fields>=2,"actual path and filename fields checked")
	check(buttons>=4 and disabled>=1,"actual native normal and disabled buttons checked")
	check(lists>=1,"actual file list checked")
	check(dialog.access==FileDialog.ACCESS_FILESYSTEM,"filesystem scope unchanged")
	check(dialog.filters==PackedStringArray(["*.json ; 7:55 存档"]),"save filter unchanged")
	check(dialog.file_selected.is_connected(shell._on_file_selected),"save/import callback unchanged")
func check_picker_bounds(context: String) -> void:
	var dialog: FileDialog=shell.file_dialog
	var window_rect:=Rect2(Vector2(dialog.position),Vector2(dialog.size))
	check(Rect2(Vector2.ZERO,Vector2(root.size)).encloses(window_rect),context+" native picker fits viewport")
	var content_rect:=Rect2(Vector2.ZERO,Vector2(dialog.size))
	for button: Button in [dialog.get_ok_button(),dialog.get_cancel_button()]:
		check(button.is_visible_in_tree() and content_rect.encloses(button.get_global_rect()),context+" native "+button.text+" fully visible")
	var found: Array[Control]=[];controls(dialog.get_vbox(),found)
	var fields:=0
	for child in found:
		if child is LineEdit and child.is_visible_in_tree():
			fields+=1
			check(content_rect.encloses(child.get_global_rect()) and child.size.x>=28,context+" path/filename editable field fully visible")
		elif child is OptionButton and child.is_visible_in_tree():
			check(content_rect.encloses(child.get_global_rect()),context+" native path/filter caption fully visible")
			check(not child.fit_to_longest_item and child.clip_text,context+" long closed captions are bounded")
	check(fields>=2,context+" native path and filename fields retained")
	check(dialog.favorites_enabled==(root.size.x>=560) and dialog.recent_list_enabled==(root.size.x>=560),context+" native sidebar adapts to viewport")
	check(dialog.overwrite_warning_enabled,context+" native overwrite safety retained")
	print("PICKER BOUNDS ",context," ",window_rect," intrinsic=",dialog.get_contents_minimum_size())

func popup_items(popup: PopupMenu) -> Array:
	var result:=[]
	for i in popup.item_count:
		result.append([popup.get_item_id(i),popup.get_item_text(i),popup.get_item_tooltip(i),popup.get_item_metadata(i)])
	return result

func check_long_drive_caption() -> void:
	var dialog: FileDialog=shell.file_dialog
	var drive: MenuButton
	for menu: MenuButton in dialog.get_vbox().find_children("*","MenuButton",true,false):
		if menu.is_visible_in_tree() and not menu.text.is_empty():drive=menu;break
	check(drive!=null,"actual native drive selector exists")
	if drive==null:return
	var original:={"text":drive.text,"clip":drive.clip_text,"overrun":drive.text_overrun_behavior,"minimum":drive.custom_minimum_size,"tooltip":drive.tooltip_text,"focus":drive.focus_mode,"mouse":drive.mouse_filter}
	var items:=popup_items(drive.get_popup())
	var path:=dialog.current_dir;var filename:=dialog.current_file
	# Deterministic counterpart to a real checkout below HOME: Godot chooses
	# the longest drive prefix, so CI uses /home/runner instead of local /.
	for caption: String in ["/home/runner","/home/runner/very-long-workspace-volume"]:
		drive.text=caption
		for viewport: Vector2i in [Vector2i(390,844),Vector2i(430,860)]:
			root.size=viewport;shell._layout();await frames(5)
			var context:="long drive "+caption+" "+str(viewport)
			check_picker_bounds(context)
			check(drive.clip_text and drive.text_overrun_behavior==TextServer.OVERRUN_TRIM_ELLIPSIS,context+" compact drive caption ellipsized")
			check(drive.size.x>=44 and Rect2(Vector2.ZERO,Vector2(dialog.size)).encloses(drive.get_global_rect()),context+" drive target remains usable and contained")
			check(drive.text==caption and popup_items(drive.get_popup())==items,context+" full caption and native popup entries retained")
			check(dialog.current_dir==path and dialog.current_file==filename,context+" current path and filename unchanged")
			check(drive.tooltip_text==original.tooltip and drive.focus_mode==original.focus and drive.mouse_filter==original.mouse,context+" native tooltip and input properties unchanged")
			await click(drive);await frames()
			check(drive.get_popup().visible and popup_items(drive.get_popup())==items,context+" native drive popup opens with complete entries")
			await key(KEY_ESCAPE);await frames()
			check(not drive.get_popup().visible and dialog.visible,context+" popup Escape returns to picker without selecting a drive")
		root.size=Vector2i(1440,900);shell._layout();await frames(5)
		check_picker_bounds("desktop after long drive")
		check(drive.clip_text==original.clip and drive.text_overrun_behavior==original.overrun and drive.custom_minimum_size==original.minimum,"desktop restores original drive layout properties")
		check(drive.size.x>44,"desktop expands the long drive caption beyond its compact target")
		check(drive.text==caption and popup_items(drive.get_popup())==items and dialog.current_dir==path and dialog.current_file==filename,"desktop restores layout without changing native values")
	drive.text=original.text;await frames()

func check_notice(context: String) -> void:
	var card: Rect2=shell.toast.get_global_rect()
	var panel: Rect2=shell.modal_panel.get_global_rect()
	var slot: Rect2=shell.modal_notice_slot.get_global_rect()
	check(shell.toast.visible and shell.modal_notice_slot.visible,context+" notice and row visible")
	check(panel.encloses(card),context+" card contained in modal")
	check(slot.encloses(card),context+" card contained in reserved row")
	check(Rect2(Vector2.ZERO,Vector2(root.size)).encloses(card),context+" card contained in viewport")
	var found: Array[Control]=[];controls(shell.modal,found)
	for child in found:
		if child is BaseButton and child.is_visible_in_tree():
			var visible_rect:=child.get_global_rect()
			var ancestor:=child.get_parent() as Control
			while is_instance_valid(ancestor):
				if ancestor.clip_contents:visible_rect=visible_rect.intersection(ancestor.get_global_rect())
				ancestor=ancestor.get_parent() as Control
			check(not visible_rect.has_area() or not card.intersects(visible_rect),context+" notice avoids visible "+str(child.get("text")))
	var box: VBoxContainer=shell.modal_panel.get_child(0)
	check(not card.intersects(box.get_child(0).get_global_rect()),context+" title/header unobscured")
	check(shell.toast.mouse_filter==Control.MOUSE_FILTER_IGNORE and shell.toast.focus_mode==Control.FOCUS_NONE,context+" card never intercepts pointer/focus")
	check(shell.modal_notice_slot.mouse_filter==Control.MOUSE_FILTER_IGNORE and shell.modal_notice_slot.focus_mode==Control.FOCUS_NONE,context+" slot never intercepts pointer/focus")
	check(shell.toast.get_theme_stylebox("normal").bg_color==Notice.PAPER and shell.toast.get_theme_color("font_color")==Notice.INK,context+" source final light notification colors retained")
func run() -> void:
	state=root.get_node("State");state.developer_mode=true;state.d=state.initial();state.d.native.page="phone_home"
	shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames(5)
	# Actual normal F10 -> Export entrance and built-in Cancel preserve settings.
	root.size=Vector2i(1440,900);shell._layout();await frames()
	await key(KEY_F10)
	check(is_instance_valid(shell.modal),"actual F10 opens settings")
	await click(button_with_text(shell.modal,"导出存档"));await frames(5)
	check(shell.file_dialog.visible and shell.file_dialog.file_mode==FileDialog.FILE_MODE_SAVE_FILE,"actual Export opens save-file dialog")
	check_dialog_theme()
	check_picker_bounds("desktop")
	var preserved_file: String=shell.file_dialog.current_file
	var preserved_path: String=shell.file_dialog.current_dir
	for viewport: Vector2i in [Vector2i(390,844),Vector2i(430,860),Vector2i(844,390),Vector2i(1440,900)]:
		root.size=viewport;shell._layout();await frames(5)
		check_picker_bounds("live resize "+str(viewport))
		check(shell.file_dialog.current_file==preserved_file and shell.file_dialog.current_dir==preserved_path,"resizing preserves current file and directory")
		await key(KEY_TAB)
		var focus=shell.file_dialog.gui_get_focus_owner()
		check(focus!=null and shell.file_dialog.is_ancestor_of(focus),"resize retains native keyboard focus")
	await check_long_drive_caption()
	var settings=shell.modal
	await key(KEY_TAB)
	var dialog_focus=shell.file_dialog.gui_get_focus_owner()
	check(dialog_focus!=null and shell.file_dialog.is_ancestor_of(dialog_focus),"Tab retains native picker focus")
	await click(shell.file_dialog.get_cancel_button());await frames()
	check(not shell.file_dialog.visible and shell.modal==settings,"native cancel returns to unchanged settings")
	# Existing-file flow uses checked-in read-only data, then cancels overwrite.
	var fixture:=ProjectSettings.globalize_path("res://data/native_phone_photos.json")
	var original:=FileAccess.get_file_as_bytes(fixture)
	await click(button_with_text(shell.modal,"导出存档"));await frames()
	shell.file_dialog.current_path=fixture;await frames()
	await click(shell.file_dialog.get_ok_button());await frames()
	var overwrite: ConfirmationDialog
	for child in shell.file_dialog.get_children(true):
		if child is ConfirmationDialog and child.visible:overwrite=child
	check(overwrite!=null,"existing-file selection still requires native overwrite confirmation")
	if overwrite!=null:
		var label: Label=overwrite.get_label()
		readable(label,"font_color",overwrite.get_theme_stylebox("panel","AcceptDialog").bg_color,4.5,"visible overwrite caption")
		await click(overwrite.get_cancel_button());await frames()
		check(not overwrite.visible and shell.file_dialog.visible,"overwrite cancel returns to picker")
	check(FileAccess.get_file_as_bytes(fixture)==original,"cancel never changes existing file")
	await click(shell.file_dialog.get_cancel_button());await frames()
	await click(button_with_text(shell.modal,"导入存档"));await frames()
	check(shell.file_dialog.file_mode==FileDialog.FILE_MODE_OPEN_FILE,"import keeps native open-file mode")
	check_dialog_theme()
	await key(KEY_ESCAPE);await frames()
	check(not shell.file_dialog.visible and shell.modal==settings,"picker Escape preserves settings modal")
	await key(KEY_ESCAPE);check(not is_instance_valid(shell.modal),"settings Escape works after picker closes")
	for viewport: Vector2i in [Vector2i(390,844),Vector2i(430,860),Vector2i(1440,900)]:
		root.size=viewport;shell._layout();await frames()
		await key(KEY_F10);await frames()
		shell._clear_notice_presentations()
		var context:=str(viewport)
		var body: Control=shell.modal_panel.get_meta("dialog_content").get_parent()
		var original_height:=body.size.y
		var original_save: Rect2=shell.save_progress_button.get_global_rect()
		var original_panel: Rect2=shell.modal_panel.get_global_rect()
		await click(button_with_text(shell.modal,"导出存档"));await frames(5)
		check_picker_bounds(context)
		shell.file_dialog.current_path=fixture;await frames()
		await click(shell.file_dialog.get_ok_button());await frames()
		var confirm: ConfirmationDialog
		for child in shell.file_dialog.get_children(true):
			if child is ConfirmationDialog and child.visible:confirm=child
		check(confirm!=null,context+" actual Save button opens overwrite confirmation")
		if confirm!=null:
			check(Rect2(Vector2.ZERO,Vector2(root.size)).encloses(Rect2(Vector2(confirm.position),Vector2(confirm.size))),context+" overwrite confirmation fits viewport")
			await click(confirm.get_cancel_button());await frames()
			check(not confirm.visible,context+" overwrite Cancel remains clickable")
		await click(shell.file_dialog.get_cancel_button());await frames()
		check(not shell.file_dialog.visible and is_instance_valid(shell.modal),context+" native Cancel returns to settings")
		check(FileAccess.get_file_as_bytes(fixture)==original,context+" test never writes an exported save")
		await click(button_with_text(shell.modal,"保存进度"));await frames()
		check(shell.toast.text=="测试会话不覆盖正式存档",context+" actual DEV save action displays result without persistence")
		check_notice(context)
		check(shell.save_progress_button.get_global_rect().is_equal_approx(original_save),context+" Save target stays fixed when a notice appears")
		check(body.get_global_rect().encloses(original_save),context+" Save remains inside the visible scroll viewport")
		check(body.size.y<original_height,context+" notice row reserves layout rather than covering actions")
		var previous_focus=root.gui_get_focus_owner()
		shell._feedback("已导出存档");await frames()
		check(shell.toast.text=="测试会话不覆盖正式存档",context+" later export status cannot overwrite the message being read")
		shell._process(10);await frames()
		check(shell.toast.text=="已导出存档",context+" pending export status receives its own reading turn")
		check_notice(context+" export status")
		check(root.gui_get_focus_owner()==previous_focus,context+" feedback does not move keyboard focus")
		await key(KEY_TAB)
		var focus=root.gui_get_focus_owner()
		check(focus!=null and shell.modal.is_ancestor_of(focus),context+" modal Tab remains trapped")
		shell._feedback("导出失败，进度仍保留。请检查保存位置是否可写，然后重新选择文件夹，再次尝试导出存档。");await frames()
		shell._process(10);await frames()
		check(shell.toast.text.begins_with("导出失败"),context+" queued multiline error appears in source order")
		check_notice(context+" multiline")
		check(shell.save_progress_button.get_global_rect().is_equal_approx(original_save) and shell.modal_panel.get_global_rect().is_equal_approx(original_panel),context+" multiline notice cannot move the Save target or recenter the menu: save="+str(shell.save_progress_button.get_global_rect())+" original="+str(original_save)+" panel="+str(shell.modal_panel.get_global_rect())+" original="+str(original_panel))
		# Expire the row between press and release, as a slow touch frame may do.
		var presses: Array[int]=[0]
		shell.save_progress_button.pressed.connect(func(): presses[0]+=1)
		for down in [true,false]:
			var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.position=original_save.get_center();event.global_position=event.position;event.pressed=down
			root.push_input(event,true)
			if down:shell._process(10)
			await frames()
		check(presses[0]==1,context+" one press still activates Save once when the footer expires before release")
		check(shell.toast.text=="测试会话不覆盖正式存档",context+" stable target invokes the real Save handler without writing a formal save")
		shell._process(10);await frames()
		check(not shell.toast.visible and not shell.modal_notice_slot.visible,context+" expiry hides notice and removes reserved row")
		check(is_equal_approx(body.size.y,original_height),context+" expiry restores original scroll space")
		check(shell.save_progress_button.get_global_rect().is_equal_approx(original_save),context+" expiry leaves the Save target at its original position")
		shell._feedback("已导出存档");await frames()
		await click(button_with_text(shell.modal,"关闭"));await frames()
		check(not is_instance_valid(shell.modal),context+" close button remains clickable with notice")
		check(shell.toast.visible,context+" closing modal retains current notice lifetime")
		check(shell.toast.scale==shell.phone.scale and shell.toast.position.is_equal_approx(shell.phone.position+Vector2(19,55)*shell.phone.scale),context+" notice returns to final source top-phone position")
		await key(KEY_F10);await frames();check_notice(context+" reopened")
		await key(KEY_ESCAPE);shell._process(10);await frames()
	# Generic settings owns feedback even while the RPG is visible in split mode.
	state.begin_checkpoint("c3-canteen-drinks");shell._refresh();shell.mobile_world=true;shell._layout();await frames()
	await key(KEY_F10);shell._feedback("已导出存档");await frames()
	check_notice("desktop RPG settings")
	await key(KEY_ESCAPE)
	await shell.shutdown();shell.queue_free();await frames()
	print("NATIVE_DIALOG_NOTICE: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
