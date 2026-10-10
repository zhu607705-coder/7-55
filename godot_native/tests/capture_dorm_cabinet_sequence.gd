extends "res://tests/capture_dorm_manual.gd"
## Actual GUI inputs use the original harness (F8 cabinet, Space open/close,
## F10 desktop/mobile layout). This captures the native framebuffer, not a mockup.
var sequence_busy:=false
var sequence_serial:=0
func action_done(action: String,before: Dictionary,after: Dictionary,_result: Dictionary) -> void:
	if action!="c2_dorm_prop":return
	var was_open: bool=before.native.get("dorm_props",{}).get("cabinet_open",false)
	var is_open: bool=after.native.get("dorm_props",{}).get("cabinet_open",false)
	if was_open==is_open:return
	print("DORM_REAL_INPUT ",action," cabinet_open=",is_open)
	if not sequence_busy:
		sequence_busy=true
		record_sequence.call_deferred(is_open)
func record_sequence(opening: bool) -> void:
	sequence_busy=true;sequence_serial+=1
	var world=shell.world
	var adapter=world.native_dorm
	var origin: Vector2=world.size/2-world.camera*world.zoom
	var pixel: Vector2=adapter._root_point(origin+(Vector2(360,208)*.5+Vector2(245,0))*world.zoom)
	var dimension: Vector2=Vector2.ONE*256*world.zoom*.5*adapter._root_scale()
	var region:=Rect2i(Vector2i(pixel.floor()),Vector2i(dimension.ceil()))
	region=region.intersection(Rect2i(Vector2i.ZERO,root.size))
	var dir:=OS.get_environment("DORM_FRAME_CAPTURE_DIR")
	if dir.is_empty():dir=OS.get_user_data_dir()+"/cabinet-sequences"
	dir+="/%02d_%dx%d_%s"%[sequence_serial,root.size.x,root.size.y,"open" if opening else "close"]
	DirAccess.make_dir_recursive_absolute(dir)
	# Keep PNG encoding out of the active animation: it would inflate the next delta.
	var full_before:=root.get_texture().get_image()
	var captured: Array[Image]=[]
	var rows: Array[String]=["file,milliseconds,cabinet_amount,pose"]
	var started:=Time.get_ticks_usec()
	while Time.get_ticks_usec()-started<500000 and captured.size()<90:
		await RenderingServer.frame_post_draw
		var milliseconds: float=(Time.get_ticks_usec()-started)/1000.0
		captured.append(root.get_texture().get_image().get_region(region))
		rows.append("%03d.png,%.3f,%.6f,%d"%[captured.size()-1,milliseconds,adapter.cabinet_amount,adapter.cabinet_frame_index()])
	full_before.save_png(dir+"/full_before.png")
	for i in captured.size():captured[i].save_png(dir+"/%03d.png"%i)
	var file:=FileAccess.open(dir+"/trace.csv",FileAccess.WRITE)
	file.store_string("\n".join(rows)+"\n");file.close()
	root.get_texture().get_image().save_png(dir+"/full_after.png")
	print("DORM_REAL_SEQUENCE ",dir," frames=",captured.size()," root_crop=",region)
	sequence_busy=false
