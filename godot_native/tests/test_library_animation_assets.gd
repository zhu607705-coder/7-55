extends SceneTree
const Assets=preload("res://scripts/objects/library_animation_assets.gd")
const ActorTexture=preload("res://scripts/objects/library_actor_texture.gd")
const Metrics=preload("res://scripts/player_metrics.gd")
var checks:=0
var failures:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,message:String)->void:
	checks+=1
	if not ok:failures+=1;push_error("LIBRARY_ANIMATION "+message)

func jacket_luminance(image: Image) -> float:
	var jacket := [Color("243f5a"), Color("344452"), Color("385b79"), Color("526b7a"), Color("547f9d")]
	var total := 0.0
	var count := 0
	for y in range(54, 99):
		for x in range(27, 70):
			var pixel := image.get_pixel(x, y)
			if pixel in jacket:
				total += pixel.get_luminance()
				count += 1
	return 255.0 * total / maxi(1, count)

func run()->void:
	var state:Node=root.get_node("State")
	var before:String=JSON.stringify(state.d)
	var assets:=Assets.new()
	check(assets.ensure_loaded(),"complete generated family activates atomically")
	if not assets.ready:quit(1);return
	var palette:Dictionary={}
	var art:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://docs/art/art_direction_v1.json"))
	for hex:String in art.palette.colors:palette[Color(hex).to_rgba32()]=true
	for direction:String in ["down","up","side"]:
		var hashes:Dictionary={}
		var idle_luma := jacket_luminance(assets.idles[direction].get_image())
		var previous_luma := idle_luma
		var first_luma := 0.0
		check(assets.walks[direction].size()==16,"sixteen actual frames "+direction)
		for index:int in 16:
			var texture:Texture2D=assets.walks[direction][index]
			var image:Image=texture.get_image()
			if image.is_compressed():image.decompress()
			var bounds:Rect2i=image.get_used_rect()
			check(texture.get_size()==Metrics.FRAME,"same shared 96 by 128 placement frame")
			check(bounds.end.y>=126 and bounds.end.y<=128,"soles share the registered foot baseline")
			check(bounds.position.x>0 and bounds.end.x<96 and bounds.position.y>4,"complete silhouette has transparent margin")
			var valid:=true
			for y:int in image.get_height():
				for x:int in image.get_width():
					var color:Color=image.get_pixel(x,y)
					if color.a!=0 and (color.a!=1 or not palette.has(color.to_rgba32())):valid=false
			check(valid,"real cutout alpha and locked 32-color palette")
			var luma := jacket_luminance(image)
			check(absf(luma - previous_luma) <= 2.5, "coat stays on the same brightness ramp " + direction + " frame " + str(index))
			if index == 0: first_luma = luma
			previous_luma = luma
			hashes[image.get_data().hex_encode().sha256_text()]=true
			check(assets.actor(direction,false,index*55,true).texture==texture,"clock selects consecutive intermediate frame")
		check(hashes.size()==16,"all walking frames are distinct "+direction)
		check(maxf(absf(first_luma - previous_luma), absf(idle_luma - previous_luma)) <= 2.5, "wrap and stop preserve coat brightness "+direction)
		check(assets.actor(direction,false,880,true).texture==assets.walks[direction][0],"cycle preserves the original 880 milliseconds")
		check(assets.actor(direction,false,473,false).texture==assets.idles[direction],"stopping selects a stable matching idle")
	check(assets.actor("left",false,55,true).flip_h and assets.actor("left",false,55,true).texture==assets.walks.side[1],"left uses the same complete character mirrored")
	check(assets.book.get_size()==Vector2(768,640),"book atlas has sixteen complete cells")
	check(assets.book_source(15)==Rect2(576,480,192,160),"last page-turn frame has an exact atlas boundary")
	var canvas := Node2D.new()
	root.add_child(canvas)
	canvas.position = Vector2(0.37, 1.25)
	canvas.scale = Vector2.ONE * 0.85
	var transform := canvas.get_global_transform_with_canvas()
	for phase in [0.13, 0.37, 0.63, 0.87]:
		var at := Vector2(301 + phase, 203 - phase)
		var original := transform * at
		var snapped := transform * ActorTexture.snap_draw_anchor(canvas, at)
		check(snapped.is_equal_approx(original.round()), "actor keeps one texel phase during fractional camera motion")
	canvas.free()
	for ms:int in range(0,1760,5):
		check(Metrics.frame_for_count(ms,8)==Metrics.frame_at(ms),"additional samples retain the original shared stride clock")
	check(JSON.stringify(state.d)==before,"loading and sampling animations never change progress or saves")
	print("LIBRARY_ANIMATION ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
