extends SceneTree
const Selected = preload("res://scripts/ui/selected_ui_theme.gd")
const Typography = preload("res://scripts/ui/native_typography.gd")
var checks := 0
var failures := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func _initialize() -> void:
	for surface: String in Selected.SURFACES:
		var panel := Selected.panel(surface)
		check(panel.opacity == 0.9 and panel.spacing == 8 and panel.corner == 6, surface + " locked panel dimensions")
		check(panel.background == ("scrim" if surface == "hud" else "none"), surface + " locked surface")
		for text_role: String in Selected.ROLES:
			var role := Selected.role(surface, text_role)
			var font: FontVariation = Selected.font(surface, text_role)
			var expected:FontVariation=Typography.display_font() if text_role=="heading" else Typography.body_font()
			check(font.base_font.get_data()==expected.base_font.get_data() and font.fallbacks.size()==1 and font.fallbacks[0]==Typography._symbol_fallback_font(), "selected role uses the current project face and explicit symbol fallback")
			check(not font.base_font.allow_system_fallback and not font.fallbacks[0].allow_system_fallback, "no platform fallback")
			check(font.base_font.get_font_name()=="755 Morning Note" and font.base_font.get_font_weight()==int(role.weight),"selected metadata matches its actual family and real weight")
			check(font.variation_embolden == 0, "no synthetic bold")
			check(role.outline == 0 and role.tracking == 0 and role.shadow, "locked text effects")
			check(role.size == (18 if text_role == "heading" else (11 if text_role == "tip" else (13 if surface == "hud" and text_role == "body" else 14))), "exact role size")
			var label := Label.new()
			Selected.apply_label(label, surface, text_role)
			check(label.get_theme_font("font") == font and label.get_theme_font_size("font_size") == role.size, "measurement and rendering share instance")
			check(label.texture_filter==CanvasItem.TEXTURE_FILTER_NEAREST,"selected text retains the common pixel sampling")
			check(label.get_theme_constant("outline_size") == 0 and label.modulate.a == 1, "no glyph stroke or compounded opacity")
			check(absf(font.get_height(role.size) + label.get_theme_constant("line_spacing") - Selected.line_height(surface, text_role)) <= 0.51, "leading matches within integer line-spacing precision")
			label.free()
		var button := Button.new()
		button.text = "保留交互范围"
		button.custom_minimum_size = Vector2(44, 44)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		Selected.apply_button(button, surface)
		var minimum_before := button.get_combined_minimum_size()
		for state: String in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
			check(button.get_theme_stylebox(state) is StyleBoxEmpty, "transparent button " + state)
		check(button.get_theme_stylebox("focus") is StyleBoxFlat, "keyboard focus retained")
		var shadow := button.get_node("SelectedTextShadow") as Label
		check(shadow.mouse_filter == Control.MOUSE_FILTER_IGNORE and shadow.show_behind_parent, "button shadow is input-transparent and behind text")
		check(shadow.get_theme_color("font_color").a == 0 and shadow.get_theme_color("font_shadow_color").a > 0, "button helper renders shadow only, not doubled foreground")
		Selected.apply_button(button, surface)
		check(shadow.focus_mode == Control.FOCUS_NONE and shadow.autowrap_mode == button.autowrap_mode and shadow.horizontal_alignment == button.alignment, "shadow preserves wrap/alignment and cannot focus")
		check(button.get_combined_minimum_size() == minimum_before and button.custom_minimum_size == Vector2(44, 44), "shadow cannot change button hit/minimum dimensions")
		check(shadow.get_theme_font("font") == button.get_theme_font("font"), "shadow and button measure same font")
		check(button.get_child_count() == 1, "reapplying role does not stack shadows")
		button.free()
		check(Selected.font("hud","body").base_font.get_font_name()==Selected.font("hud","heading").base_font.get_font_name(),"HUD body and heading share the project family")
	check(Selected.color("hud", "body") == Color("#eedff1"), "HUD exact body color")
	for surface: String in ["interaction", "dialogue", "journal", "theater"]:
			check(Selected.role(surface, "heading").weight == 500, "authored Medium heading selected")
			check(Selected.font(surface, "heading").base_font.get_font_weight() == 500, "actual font weight 500")
	print("Selected UI theme: ", checks, " checks, ", failures, " failures")
	quit(1 if failures else 0)
