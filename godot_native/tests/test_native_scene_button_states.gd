extends SceneTree
## Actual scene controls adopt neutral materials without changing behavior or focus.
var checks:=0
var failures:=0
func _initialize() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("SCENE BUTTON STATES: "+message)
func luminance(color: Color) -> float:
	var c: Color=color.srgb_to_linear();return .2126*c.r+.7152*c.g+.0722*c.b
func contrast(a: Color,b: Color) -> float:
	return (maxf(luminance(a),luminance(b))+.05)/(minf(luminance(a),luminance(b))+.05)
func assert_palette(button: Button,_fill: Color,_ink: Color,_border: Color,_width: int,label: String,_interactive_fills: Dictionary={}) -> void:
	var normal: StyleBox=button.get_theme_stylebox("normal")
	check(normal.get_script()==load("res://scripts/ui/tactile_button_material.gd"),label+" uses shared native material")
	if normal.get_script()!=load("res://scripts/ui/tactile_button_material.gd"):return
	var palette: Array=normal.PALETTES[normal.variant]
	var ink: Color=palette[3]
	for mode: String in ["normal","hover","pressed","hover_pressed","disabled"]:
		check(button.get_theme_stylebox(mode)==normal,label+" "+mode+" same animated layer stack")
	for role: String in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_focus_color"]:
		check(button.get_theme_color(role).is_equal_approx(ink),label+" "+role+" neutral variant ink")
	check(button.get_theme_color("font_disabled_color").is_equal_approx((Color("bcc2ca") if normal.variant=="primary" else Color("626a75"))),label+" disabled ink")
	if normal.variant not in ["ghost","text"]:
		check(contrast(ink,palette[0])>=4.5 and contrast(ink,palette[1])>=4.5,label+" gradient text contrast")
	var focus: StyleBox=button.get_theme_stylebox("focus")
	check(focus!=null,label+" existing focus indicator retained")
func assert_transparent_pause(button: Button,_ink: Color,label: String) -> void:
	# Previously light text floated on dark art. A neutral light key is needed
	# now: the requested gray ghost ink would lose contrast on that world art.
	assert_palette(button,Color.TRANSPARENT,Color.WHITE,Color.TRANSPARENT,0,label)
	check(button.focus_mode==Control.FOCUS_ALL,label+" remains keyboard focusable")
	var outline: StyleBoxFlat=button.get_theme_stylebox("focus")
	check(outline!=null and is_zero_approx(outline.bg_color.a),label+" focus keeps transparent outline")
	check(outline.border_width_left==2,label+" existing focus width retained")
func frames(count: int=2) -> void:
	for i in count:await process_frame
func run() -> void:
	var state=root.get_node("State");state.developer_mode=true;state.d=state.initial()
	var main=load("res://scenes/main.tscn").instantiate();root.add_child(main);await frames(5)
	var opening=load("res://scripts/presentation/c3_opening_view.gd").new();main.add_child(opening);await frames()
	for button: Button in [opening.advance_button,opening.skip_button]:
		assert_palette(button,Color("101e28",.94),Color("f4edd6"),Color("cfbd74"),2,"opening "+button.text)
		var focus: StyleBoxFlat=button.get_theme_stylebox("focus")
		check(focus.border_color.is_equal_approx(Color("9ee7f1")) and focus.border_width_left==3,"opening authored focus outline retained")
	opening.queue_free();await frames()
	for ready: bool in [false,true]:
		var ring=load("res://scripts/ui/c3_investigation_ring.gd").new();main.add_child(ring)
		ring.configure([{"label":"照片","ready":ready,"page":"c35_photos"},{"label":"录音","ready":ready,"page":"c35_voice"},{"label":"群聊","ready":ready,"page":"c35_messages"},{"label":"网络","ready":ready,"page":"c35_network"}])
		await frames()
		var fill:Color=Color("d3dfcf") if ready else Color("efe9d8")
		var feedback:Dictionary={"hover":fill.lightened(.06),"pressed":fill.darkened(.12),"hover_pressed":fill.darkened(.12)}
		for button: Button in ring.buttons:assert_palette(button,fill,Color("1b2328"),Color("3d8168") if ready else Color("1f6d7f"),2,"ring "+str(ready)+" "+button.text,feedback)
		check(ring.completed==(4 if ready else 0),"style preserves ring completion semantics")
		ring.queue_free();await frames()
	var spotlight=load("res://scripts/games/c3_spotlight.gd").new();main.add_child(spotlight);spotlight.set_process(false)
	for round_index in 3:
		spotlight.setup({"round":round_index,"attempt":0});await frames()
		# Pause freezing/input release are covered by test_theater_show_ui and test_theater_lens.
		assert_transparent_pause(spotlight.pause_button,Color("fff0cb"),"spotlight pause round"+str(round_index))
		for button: Button in [spotlight.start_button,spotlight.dash_button]:
			assert_palette(button,[Color("ffcf68"),Color("94f3d0"),Color("ff94bc")][round_index],Color("11152d"),Color.TRANSPARENT,0,"spotlight action round"+str(round_index))
		check(spotlight.state.round==round_index and spotlight.state.tick==0,"style refresh does not advance spotlight model")
	spotlight.queue_free();await frames();await main.shutdown();main.queue_free();await frames()
	print("NATIVE_SCENE_BUTTON_STATES: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
