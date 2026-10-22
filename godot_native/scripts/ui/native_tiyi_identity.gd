extends RefCounted
## Sport-app visual adapter. Source plate, text, actions and timers stay owned
## by PhonePages; this helper owns only coherent colors and focus styling.
const Ui=preload("res://scripts/ui/native_ui_theme.gd")
# Darker sport colors keep white labels readable after hover/press tinting.
const BLUE=Color("1a63ad")
const GREEN=Color("256b43")
static func style_exit(button: Button) -> void:
	Ui.apply_button(button,Color("f4f8ff"),Color("23599d"),Color("a9c9ef"),8,1,30,Vector2.ZERO,Color("174d9d"))
static func style_exercise(button: Button,started: bool) -> void:
	Ui.apply_button(button,GREEN if started else BLUE,Color.WHITE,Color("287448") if started else Color("194f8d"),10,2,13,Vector2.ZERO,Color("174d9d"))
	# The disabled running card is status, so its authored white labels retain
	# contrast. All child labels already explicitly own that same ink color.
	button.add_theme_color_override("font_disabled_color",Color.WHITE)
