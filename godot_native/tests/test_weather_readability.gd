extends SceneTree
const Game=preload("res://scripts/games/c3_weather.gd")
var checks:=0
var failures:=0
var context: String=""
func check(value: bool,label: String) -> void:
	checks+=1
	if not value: failures+=1; push_error("WEATHER VIEW: "+context+" "+label)
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
	for extent: Vector2 in [Vector2(1280,720),Vector2(1024,768),Vector2(390,844),Vector2(391,844),Vector2(400,844),Vector2(430,860),Vector2(844,390)]:
		root.size=Vector2i(extent)
		context="viewport=%s" % extent
		var factor:=minf((extent.x-20)/960,(extent.y-20)/540)
		game.scale=Vector2.ONE*factor; game._apply_presentation_layout(true); await process_frame; game._process(0.0)
		check(game.size==Vector2(960,540),"canonical gameplay viewport unchanged")
		check(game.positions==[78.0,22.0,38.0] and game.TARGET==[34.0,52.0,70.0] and game.WIND==[5.5,6.5,7.5],"presentation never changes source physics data")
		check(game.elapsed==0 and game.moves==0 and not game.started,"readability does not advance gameplay")
		check(game.label.get_theme_font_size("font_size")*factor>=15,"instructions meet 15 physical pixels")
		check(contrast(game.label.get_theme_color("font_color"),Color("15243a"))>=4.5,"instructions readable on actual dark surface")
		var text_size: Vector2=game.FONT.get_string_size(game.label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,game.label.get_theme_font_size("font_size"))
		print("WEATHER_LAYOUT ",extent," scale=",factor," text=",text_size," cloud=",game.cloud_size*factor," label=",Rect2(game.label.position,game.label.size)," shaped_min=",game.label.get_combined_minimum_size()," rows=",game.row_centers)
		check(text_size.y<=game.label.size.y+.5 and text_size.x<=game.label.size.x+.5,"instruction text fits without clipping")
		check(game.label.size.y>=game.label.get_combined_minimum_size().y,"status reserves actual shaped fallback-font height")
		check("Q/E" not in game.label.text and "A/D" not in game.label.text and "Z/C" not in game.label.text,"hotkeys are not the default interface")
		check(game.get_children().filter(func(c): return c is Button).size()==2,"only start/pause and navigation buttons remain")
		var surface:=Rect2(Vector2.ZERO,game.size)
		for band: int in range(3):
			var cloud: Rect2=game.cloud_rect(band)
			context="viewport=%s band=%d rect=%s" % [extent,band,cloud]
			check(surface.encloses(cloud),"visible cloud and touch area stay inside surface")
			check(cloud.size.y*factor>=44 and cloud.size.x*factor>=44,"cloud has 44 physical pixel touch target")
			check(not cloud.intersects(Rect2(game.label.position,game.label.size)),"cloud target does not cover status text")
			if band>0:
				var previous: Rect2=game.cloud_rect(band-1)
				check(not cloud.intersects(previous),"adjacent cloud targets do not overlap; other_band=%d other_rect=%s" % [band-1,previous])
				check(cloud.end.y<=previous.position.y,"cloud rows stay separate even when wind aligns their x positions; other_band=%d other_rect=%s" % [band-1,previous])
			for button: Button in [game.start_button,game.exit_button]:
				check(not cloud.intersects(Rect2(button.position,button.size)),"cloud target does not cover navigation")
		context="viewport=%s" % extent
		for button: Button in [game.start_button,game.exit_button]:
			check(surface.encloses(Rect2(button.position,button.size)),"start/return stays inside surface")
			check(button.size.y*factor>=44 and button.size.x*factor>=44,"start/return real touch size")
			check(button.get_theme_font_size("font_size")*factor>=14,"navigation label readable")
			check(game.FONT.get_string_size(button.text,HORIZONTAL_ALIGNMENT_LEFT,-1,button.get_theme_font_size("font_size")).x+12<=button.size.x,"start/return caption fits")
			check(contrast(button.get_theme_color("font_color"),button.get_theme_stylebox("normal").bg_color)>=4.5,"navigation text contrast")
		if extent.x>=1100: check(game.row_centers==[175.0,265.0,355.0],"desktop cloud geometry preserved")
	context="pause regression"
	game._resume_shared_pause(); game.directions=[1,1,1]; game.held_keys[KEY_C]=true
	game._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(game.paused and game.directions==[0,0,0] and game.held_keys.is_empty() and game.pointer_owner==game.NO_POINTER and game.shared_pause_overlay.is_open(),"pause releases all sources and exposes shared resume")
	game.queue_free(); await process_frame
	print("Weather readability: ",checks," checks / ",failures," failures")
	quit(1 if failures else 0)
