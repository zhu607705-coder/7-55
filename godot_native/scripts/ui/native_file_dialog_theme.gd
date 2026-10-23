extends RefCounted
## Engine-owned file picking is not a phone page. Copy the complete native
## palette so its dark panels never inherit the shell's light-page text/styles.
## Scope includes built-in overwrite/new-folder dialogs and option popups.
static func create(font: Font) -> Theme:
	var design: Theme=ThemeDB.get_default_theme().duplicate()
	design.default_font=font
	for type: String in design.get_type_list():
		for role: String in design.get_font_list(type):
			design.set_font(role,type,font)
	# Disabled controls stay disabled; only their presentation becomes legible.
	var subdued:=Color("b3b3b3")
	for type: String in ["Button","MenuButton","OptionButton","CheckButton","CheckBox","Tree","PopupMenu"]:
		design.set_color("font_disabled_color",type,subdued)
	design.set_color("font_uneditable_color","LineEdit",subdued)
	design.set_color("font_placeholder_color","LineEdit",subdued)
	design.set_color("font_hover_color","PopupMenu",Color.WHITE)
	return design

static func fit(dialog: FileDialog,available: Vector2) -> Vector2i:
	# Long folder names stay complete in the menus and editable path field;
	# only each closed caption is ellipsized instead of widening the window.
	for choice in dialog.get_vbox().find_children("*","OptionButton",true,false):
		choice.fit_to_longest_item=false
		choice.clip_text=true
		choice.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	# Keep the full filename readable in native overwrite/error messages.
	for child in dialog.get_children(true):
		if child is AcceptDialog: child.dialog_autowrap=true
	# Native optional sidebars need 148px. Compact layouts retain the actual
	# back/forward/up/path/file/filter controls and restore sidebars on desktop.
	var compact:=available.x<560
	# Godot 4.7's drive selector is a MenuButton, not an OptionButton. On Unix
	# its closed caption can be the complete HOME path. The other native menu
	# is icon-only sorting; leave that control and every popup entry untouched.
	for menu: MenuButton in dialog.get_vbox().find_children("*","MenuButton",true,false):
		var original_key:=&"_755_drive_caption_layout"
		if menu.text.is_empty() and not menu.has_meta(original_key):continue
		if compact:
			if not menu.has_meta(original_key):
				menu.set_meta(original_key,{"clip":menu.clip_text,"overrun":menu.text_overrun_behavior,"minimum":menu.custom_minimum_size})
			menu.clip_text=true
			menu.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
			menu.custom_minimum_size.x=maxf(44,menu.custom_minimum_size.x)
		elif menu.has_meta(original_key):
			var original: Dictionary=menu.get_meta(original_key)
			menu.clip_text=original.clip
			menu.text_overrun_behavior=original.overrun
			menu.custom_minimum_size=original.minimum
			menu.remove_meta(original_key)
	dialog.favorites_enabled=not compact
	dialog.recent_list_enabled=not compact
	var target:=Vector2i(minf(800,available.x-16),minf(540,available.y-64))
	# Theme/sidebar sorting can reset an AcceptDialog to its intrinsic minimum
	# after popup_centered. Apply the bounded extent after that native sort.
	dialog.set_deferred("size",target)
	dialog.set_deferred("position",Vector2i((available-Vector2(target))/2))
	return target
