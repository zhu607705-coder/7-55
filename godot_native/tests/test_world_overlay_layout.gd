extends SceneTree
const Layout=preload("res://scripts/ui/world_overlay_layout.gd")
var checks:=0
var failures:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error("WORLD OVERLAY: "+label)
func run()->void:
	var font:Font=load("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf")
	var text:="已获得非人物品证明。系统：记录已经存入物品栏，可以继续查看。"
	for extent:Vector2 in [Vector2(960,540),Vector2(370,700),Vector2(824,314)]:
		for scale:float in [.38,1.0,1.45]:
			for text_scale:float in [1.0,1.25,3.0]:
				var metrics:=Layout.hud(font,extent,scale,text,false,text_scale)
				var needed:=font.get_multiline_string_size(text,HORIZONTAL_ALIGNMENT_CENTER,metrics.body_width,metrics.body_font)
				check(metrics.body_content_height>=needed.y,"feedback stores the full actual wrapped glyph height")
				check(metrics.body_font*scale>=15*text_scale,"text setting preserves body readability")
				var region:=Rect2(8,40,extent.x-16,extent.y-48)
				var dialogue:=Layout.dialogue(font,region,scale,"系统",text,"",text_scale)
				check(region.encloses(dialogue.panel),"dialogue stays wholly inside its region, including enlarged text")
				check(dialogue.body.size.y>=font.get_multiline_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,dialogue.body.size.x,dialogue.body_font).y,"full dialogue is measured, never clipped to a fixed card")
	# Regression: original full-viewport clamp put the southeast mat (935px)
	# behind the footer; the same zoom must now put it inside the clear region.
	var extent:=Vector2(960,540)
	var room:=Vector2(1672,941)
	var safe:=Rect2(0,32,960,460)
	for zoom:float in [.45,.85,1.6]:
		var camera:=Layout.camera_for_safe_rect(Vector2(1380,852),Vector2.ZERO,extent,room,zoom,safe)
		var point:Vector2=(Vector2(1352,935)-camera)*zoom+extent/2
		check(point.y<safe.end.y,"southeast door/mat clears footer at zoom "+str(zoom))
		var before:=Vector2(1380,852)
		check(((before-camera)*zoom+extent/2).is_finite(),"source projection remains finite")
		var round_trip:Vector2=(((before-camera)*zoom+extent/2)-extent/2)/zoom+camera
		check(round_trip.is_equal_approx(before),"inverse pointer mapping retains source position")
	var interior:=Vector2(1200,700)
	check(Layout.camera_for_safe_rect(interior,Vector2.ZERO,Vector2(528,314),Vector2(2400,1800),1.1,Rect2(0,44,528,100)).is_equal_approx(interior),"interior camera stays player-centered despite a narrow control-safe frame")
	var old_camera:=Vector2(1380,room.y-extent.y/(2*.85))
	var old_y:float=(935-old_camera.y)*.85+extent.y/2
	check(old_y>safe.end.y,"baseline reproduces bottom HUD occlusion")
	print("WORLD_OVERLAY_LAYOUT: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
