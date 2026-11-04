extends RefCounted
## Local presentation for the two routed phone-home top notices only.
## No global theme, font, geometry, routing, timing or input ownership changes.
const PAPER:=Color("f6efe2")
const INK:=Color("282521")
const EDGE:=Color("6f655a")
const FOCUS:=Color("bd4036")
# Original cool-gray/red semantics, minimally deepened for small child labels.
const DETAIL:=Color("5a6573")
const TIME:=Color("a54444")

static func card(fill:Color=PAPER)->StyleBoxFlat:
	var box:=StyleBoxFlat.new()
	box.bg_color=fill;box.border_color=EDGE;box.set_border_width_all(1)
	box.set_corner_radius_all(3);box.shadow_color=Color(0.043,0.039,0.043,0.18)
	box.shadow_offset=Vector2(3,4);box.shadow_size=0
	# Match the existing authored rectangle: borders cannot enlarge hit targets.
	box.set_content_margin_all(0)
	return box

static func focus()->StyleBoxFlat:
	var box:=StyleBoxFlat.new()
	box.bg_color=Color.TRANSPARENT;box.border_color=FOCUS;box.set_border_width_all(2)
	box.set_corner_radius_all(3);box.set_content_margin_all(0)
	return box

static func routed_banner(button:Button)->void:
	# Empty Button.text means custom child content, not a transparent hotspot.
	# Opt only these routed notices out of the shared tactile ghost heuristic.
	button.set_meta("tactile_exempt",true)
	button.set_meta("phone_jump_notice",true)
	for state:String in ["normal","hover","pressed","hover_pressed","disabled"]:
		var fill:=PAPER.lerp(Color.WHITE,0.28) if state=="hover" else PAPER
		if state in ["pressed","hover_pressed"]:fill=PAPER.lerp(INK,0.06)
		button.add_theme_stylebox_override(state,card(fill))
	button.add_theme_stylebox_override("focus",focus())
	button.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
