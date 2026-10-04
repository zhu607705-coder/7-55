extends SceneTree
## Actual scene controls retain their authored palette under the shared theme.
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
func assert_palette(button: Button,fill: Color,ink: Color,border: Color,width: int,label: String,interactive_fills: Dictionary={}) -> void:
	var normal: StyleBoxFlat=button.get_theme_stylebox("normal")
	for mode: String in ["normal","hover","pressed","hover_pressed","disabled"]:
		var style: StyleBoxFlat=button.get_theme_stylebox(mode)
		check(style.bg_color.is_equal_approx(interactive_fills.get(mode,fill)),label+" "+mode+" keeps local feedback palette")
		check(contrast(ink,style.bg_color)>=4.5,label+" "+mode+" feedback text remains readable")
		check(style.border_width_left==width,label+" "+mode+" keeps border width")
		if width>0:check(style.border_color.is_equal_approx(border),label+" "+mode+" keeps local border")
		check(style.corner_radius_top_left==normal.corner_radius_top_left,label+" "+mode+" keeps corner shape")
		check(style.content_margin_left==normal.content_margin_left and style.content_margin_top==normal.content_margin_top,label+" "+mode+" keeps content margins")
	for role: String in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_focus_color","font_disabled_color"]:
		check(button.get_theme_color(role).is_equal_approx(ink),label+" "+role+" keeps local ink")
	check(contrast(ink,fill)>=4.5,label+" local text remains readable")
	var focus: StyleBox=button.get_theme_stylebox("focus")
	check(focus!=null,label+" has a focus indicator")
	if focus is StyleBoxFlat:
		check(contrast(focus.border_color,fill)>=3.0,label+" focus outline contrast at least3:1")
func frames(count: int=2) -> void:
	for i in count:await process_frame
func run() -> void:
	var state=root.get_node("State");state.developer_mode=true;state.d=state.initial()
	var main=load("res://scenes/main.tscn").instantiate();root.add_child(main);await frames(5)
	var opening=load("res://scripts/presentation/c3_opening_view.gd").new();main.add_child(opening)
	for button: Button in [opening.advance_button,opening.skip_button]:
		assert_palette(button,Color("101e28",.94),Color("f4edd6"),Color("cfbd74"),2,"opening "+button.text)
		var focus: StyleBoxFlat=button.get_theme_stylebox("focus")
		check(focus.border_color.is_equal_approx(Color("9ee7f1")) and focus.border_width_left==3,"opening authored focus outline retained")
	opening.queue_free();await frames()
	for ready: bool in [false,true]:
		var ring=load("res://scripts/ui/c3_investigation_ring.gd").new();main.add_child(ring)
		ring.configure([{"label":"照片","ready":ready,"page":"c35_photos"},{"label":"录音","ready":ready,"page":"c35_voice"},{"label":"群聊","ready":ready,"page":"c35_messages"},{"label":"网络","ready":ready,"page":"c35_network"}])
		var fill:Color=Color("d3dfcf") if ready else Color("efe9d8")
		var feedback:Dictionary={"hover":fill.lightened(.06),"pressed":fill.darkened(.12),"hover_pressed":fill.darkened(.12)}
		for button: Button in ring.buttons:assert_palette(button,fill,Color("1b2328"),Color("3d8168") if ready else Color("1f6d7f"),2,"ring "+str(ready)+" "+button.text,feedback)
		check(ring.completed==(4 if ready else 0),"style preserves ring completion semantics")
		ring.queue_free();await frames()
	var spotlight=load("res://scripts/games/c3_spotlight.gd").new();main.add_child(spotlight);spotlight.set_process(false)
	for round_index in 3:
		spotlight.setup({"round":round_index,"attempt":0})
		assert_palette(spotlight.pause_button,Color("11152d"),Color("fff0cb"),Color("595a77"),1,"spotlight pause round"+str(round_index))
		for button: Button in [spotlight.start_button,spotlight.dash_button]:
			assert_palette(button,[Color("ffcf68"),Color("94f3d0"),Color("ff94bc")][round_index],Color("11152d"),Color.TRANSPARENT,0,"spotlight action round"+str(round_index))
		check(spotlight.state.round==round_index and spotlight.state.tick==0,"style refresh does not advance spotlight model")
	spotlight.queue_free();await frames();await main.shutdown();main.queue_free();await frames()
	print("NATIVE_SCENE_BUTTON_STATES: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
