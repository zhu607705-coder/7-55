extends SceneTree
const Ui = preload("res://scripts/ui/native_ui_theme.gd")
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("NATIVE UI THEME: " + message)
func luminance(color: Color) -> float:
	var value := color.srgb_to_linear()
	return 0.2126 * value.r + 0.7152 * value.g + 0.0722 * value.b
func contrast(a: Color, b: Color) -> float:
	return (maxf(luminance(a),luminance(b)) + 0.05) / (minf(luminance(a),luminance(b)) + 0.05)
func run() -> void:
	var font: Font = load("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf")
	var host := Control.new()
	host.theme = Ui.make_theme(font)
	host.size = Vector2(424,854)
	root.add_child(host)
	check(host.theme.default_font == font,"bundled original font preserved")
	check(host.theme.default_font_size == 13,"source body token")
	check(host.theme.get_font_size("font_size","Button") == 14,"source button token")
	for role: String in ["NativeCaption","NativeBody","NativeTitle","NativeDisplay"]:
		check(host.theme.get_type_variation_base(role) == "Label","semantic type remains a Label: " + role)
	var button := Button.new()
	button.text = "确认并继续"
	button.position = Vector2(20,30)
	button.size = Vector2(280,48)
	host.add_child(button)
	var before := Rect2(button.position,button.size)
	Ui.apply_button(button,Color("24677c"),Color.WHITE,Color("101923"),0,3,14,Vector2(14,8),Color("7fd1d4"))
	await process_frame
	check(Rect2(button.position,button.size) == before,"style adapter preserves measured layout")
	check(button.get_theme_font("font") == font,"button inherits authored font")
	for state: String in ["normal","hover","pressed","hover_pressed","disabled"]:
		var style: StyleBoxFlat = button.get_theme_stylebox(state)
		check(button.has_theme_stylebox_override(state),"complete state: " + state)
		check(style.corner_radius_top_left == 0 and style.border_width_left == 3,"app edge and radius stable: " + state)
		check(style.content_margin_left == 14 and style.content_margin_top == 8,"state layout does not jump: " + state)
		check(style.bg_color.b > style.bg_color.r,"teal app palette retained: " + state)
		if state != "disabled": check(contrast(Color.WHITE,style.bg_color) >= 4.5,"normal/hover/pressed text readable: " + state)
	check(button.get_theme_color("font_hover_color") == Color.WHITE,"dark accent retains white hovered text")
	check(button.get_theme_color("font_focus_color") == Color.WHITE,"dark accent retains white focused text")
	var focus: StyleBoxFlat = button.get_theme_stylebox("focus")
	check(focus.bg_color.a == 0 and focus.border_width_left == 2,"visible transparent keyboard focus overlay")
	check(focus.border_color == Color("7fd1d4"),"app-specific focus accent retained")
	button.disabled = true
	check(button.disabled,"adapter does not override controller disabled state")
	var dark_button := Button.new()
	host.add_child(dark_button)
	Ui.apply_button(dark_button,Ui.FOCUS,Color.WHITE)
	check(contrast(dark_button.get_theme_stylebox("focus").border_color,Ui.FOCUS) >= 3.0,"keyboard focus stays visible on dark blue actions")
	var field := LineEdit.new()
	field.size = Vector2(280,46)
	host.add_child(field)
	Ui.apply_input(field)
	var normal: StyleBoxFlat = field.get_theme_stylebox("normal")
	check(contrast(field.get_theme_color("font_color"),normal.bg_color) >= 7.0,"form text high contrast")
	check(contrast(field.get_theme_color("font_placeholder_color"),normal.bg_color) >= 4.5,"form placeholder readable")
	check(field.get_theme_color("caret_color") == Ui.INK,"form caret contrast")
	check(field.has_theme_stylebox_override("read_only"),"readonly field state explicitly styled")
	field.text = "0832"
	field.editable = false
	Ui.apply_input(field)
	check(field.text == "0832" and not field.editable,"form draft and readonly permission untouched")
	var local_font := SystemFont.new()
	local_font.font_names = PackedStringArray(["sans-serif"])
	var local_theme := Theme.new()
	local_theme.default_font = local_font
	var local_host := Control.new()
	local_host.theme = local_theme
	host.add_child(local_host)
	var local_button := Button.new()
	local_host.add_child(local_button)
	Ui.apply_button(local_button)
	check(local_button.get_theme_font("font") == local_font,"authored Library platform-font exception retained")
	var world_theme := Ui.font_theme(font)
	check(world_theme.default_font == font and world_theme.default_font_size == 16,"world font-only scope retains16px baseline")
	check(world_theme.get_type_list().is_empty(),"world receives no phone button or field styling")
	check(Ui.font_size_for_scale(14,424.0/378.0) == 13,"14px logical role maps to13px authored without unreadable round-down")
	for viewport: Vector2 in [Vector2(390,844),Vector2(430,860),Vector2(1440,900)]:
		var scale := minf(1.0,minf((viewport.y-36.0)/860.0,(viewport.x-36.0)/430.0))
		var authored_scale := scale*424.0/378.0
		var authored_font_size := Ui.font_size_for_scale(Ui.FONT_LABEL,424.0/378.0)
		check(44.0*scale >= 28.0,"flow button exceeds28px compact hit floor: " + str(viewport))
		check(authored_font_size*authored_scale >= 12.0,"authored phone button physical readability: " + str(viewport))
		print("UI size ",viewport,": phone button=",authored_font_size*authored_scale,"px, flow hit=",44.0*scale,"px")
	host.free()
	print("Native UI theme: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
