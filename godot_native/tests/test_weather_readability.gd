extends SceneTree
const Game=preload("res://scripts/games/c3_weather.gd")
var checks:=0
var failures:=0
func check(value: bool,label: String) -> void:
	checks+=1
	if not value: failures+=1; push_error("WEATHER VIEW: "+label)
func luminance(color: Color) -> float:
	var result:=0.0
	for i in 3:
		var x: float=color[i]
		result+=(x/12.92 if x<=.04045 else pow((x+.055)/1.055,2.4))*[.2126,.7152,.0722][i]
	return result
func contrast(a: Color,b: Color) -> float:
	var x:=luminance(a); var y:=luminance(b)
	return (maxf(x,y)+.05)/(minf(x,y)+.05)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var game=Game.new(); root.add_child(game); game.set_process(false); await process_frame
	for width: float in [390,430,1280]:
		var factor:=minf((width-20)/960,(844.0-20)/540 if width<1100 else (720.0-20)/540)
		game.scale=Vector2.ONE*factor; game._apply_presentation_layout(true); await process_frame; game._process(0.0)
		check(game.size==Vector2(960,540),"canonical gameplay viewport unchanged")
		check(game.positions==[78.0,22.0,38.0] and game.TARGET==[34.0,52.0,70.0] and game.WIND==[5.5,6.5,7.5],"presentation never changes source physics data")
		check(game.elapsed==0 and game.moves==0 and not game.started,"readability does not advance gameplay")
		check(game.label.get_theme_font_size("font_size")*factor>=15,"instructions meet15 physical pixels")
		check(contrast(game.label.get_theme_color("font_color"),Color("15243a"))>=4.5,"instructions readable on the actual dark surface")
		var text_size: Vector2=game.FONT.get_multiline_string_size(game.label.text,HORIZONTAL_ALIGNMENT_LEFT,game.label.size.x,game.label.get_theme_font_size("font_size"))
		print("WEATHER_LAYOUT ",width," ",factor," ",text_size," label=",game.label.size," font=",game.label.get_theme_font_size("font_size"))
		check(text_size.y<=game.label.size.y+.5,"instruction text fits its box without clipping")
		var surface:=Rect2(Vector2.ZERO,game.size)
		for i in range(game.row_buttons.size()):
			var button: Button=game.row_buttons[i]
			check(surface.encloses(Rect2(button.position,button.size)),"direction control inside surface")
			check(button.size.y*factor>=28 and button.size.x*factor>=28,"direction control has real touch target")
			check(button.get_theme_font_size("font_size")*factor>=14,"direction label is readable")
			check(button.get_meta("weather_band")==2-i/2 and button.get_meta("weather_direction")==(-1 if i%2==0 else 1),"source band/direction identity retained")
			check(contrast(button.get_theme_color("font_color"),button.get_theme_stylebox("normal").bg_color)>=4.5,"direction text contrast")
			if i>=2: check(not Rect2(button.position,button.size).intersects(Rect2(game.row_buttons[i-2].position,game.row_buttons[i-2].size)),"adjacent row targets do not overlap")
		for button: Button in [game.start_button,game.exit_button]:
			check(surface.encloses(Rect2(button.position,button.size)),"start/return stays in surface")
			check(button.size.y*factor>=28,"start/return real touch height")
			check(game.FONT.get_string_size(button.text,HORIZONTAL_ALIGNMENT_LEFT,-1,button.get_theme_font_size("font_size")).x+12<=button.size.x,"start/return caption fits")
		if width>=1100: check(game.row_centers==[175.0,265.0,355.0] and game.row_buttons[0].position==Vector2(42,150),"desktop cloud geometry is preserved")
	game.started=true; game.touch_directions=[1,1,1]; game.directions=[1,1,1]
	game._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(game.paused and game.directions==[0,0,0] and game.touch_directions==[0,0,0] and game.start_button.visible,"existing pause/release/resume contract preserved")
	game.queue_free(); await process_frame
	print("Weather readability: ",checks," checks / ",failures," failures")
	quit(1 if failures else 0)
