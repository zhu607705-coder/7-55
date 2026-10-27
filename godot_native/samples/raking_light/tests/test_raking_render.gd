extends SceneTree
## Real-render counterexamples. These fixtures set poses directly; the separate
## capture_raking_light.gd proves ordinary input, not this pixel comparison.
const SCENE=preload("res://scenes/raking_light.tscn")
var checks:=0
var failures:=0
var view: Control

func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error("TEST FAILED: "+label)
	else: print("PASS ",label)
func rendered_frame() -> void:
	await process_frame; await process_frame; await RenderingServer.frame_post_draw
func luminance(color: Color) -> float: return color.r*0.2126+color.g*0.7152+color.b*0.0722
func sample_color(image: Image,point: Vector2) -> Color:
	return image.get_pixel(clampi(int(round(point.x)),0,image.get_width()-1),clampi(int(round(point.y)),0,image.get_height()-1))
func sample(image: Image,point: Vector2) -> float:
	return luminance(sample_color(image,point))
func paper_exposure(image: Image) -> Dictionary:
	var count:=0.0; var clipped:=0.0; var white:=0.0; var mean:=0.0
	# Interior paper samples exclude the brass handles and the card's silhouette.
	for ix: int in range(21):
		for iz: int in range(13):
			var p:=Vector2(-1.30+ix*0.13,-0.90+iz*0.15)
			var point: Vector3=view.current_world.paper_pivot.to_global(Vector3(p.x,view.current_world.groove_height(p),p.y))
			var color:=sample_color(image,view.current_world.screen_point(point))
			count+=1; mean+=luminance(color)
			if minf(color.r,minf(color.g,color.b))>=0.985: white+=1
			if maxf(color.r,maxf(color.g,color.b))>=0.995: clipped+=1
	return {"mean":mean/count,"white_fraction":white/count,"clipped_fraction":clipped/count}
func groove_contrast(image: Image) -> float:
	var result:=0.0
	for probe: Dictionary in view.current_world.groove_probes:
		var p: Vector2=probe.p; var side: Vector2=probe.side
		var a: Vector2=p+side; var b: Vector2=p-side
		var point_a: Vector3=Vector3(a.x,view.current_world.groove_height(a),a.y)
		var point_b: Vector3=Vector3(b.x,view.current_world.groove_height(b),b.y)
		var screen_a: Vector2=view.current_world.screen_point(view.current_world.paper_pivot.to_global(point_a))
		var screen_b: Vector2=view.current_world.screen_point(view.current_world.paper_pivot.to_global(point_b))
		result+=absf(sample(image,screen_a)-sample(image,screen_b))
	return result/maxf(1,view.current_world.groove_probes.size())
func image_difference(a: Image,b: Image) -> float:
	var difference:=0.0
	for y: int in range(0,a.get_height(),4):
		for x: int in range(0,a.get_width(),4): difference+=absf(luminance(a.get_pixel(x,y))-luminance(b.get_pixel(x,y)))
	return difference/(ceil(a.get_width()/4.0)*ceil(a.get_height()/4.0))
func run() -> void:
	if DisplayServer.get_name()=="headless" or RenderingServer.get_video_adapter_name().is_empty():
		push_error("Actual graphical renderer required for raking pixel checks"); quit(2); return
	root.size=Vector2i(390,844)
	view=SCENE.instantiate(); root.add_child(view); await rendered_frame(); view.set_process(false)
	view.model.reset(); view._process(0); await rendered_frame()
	var entry: Image=view.current_viewport.get_texture().get_image()
	var entry_exposure:=paper_exposure(entry)
	# Keep the paper pose and lamp azimuth identical in this angle comparison.
	view.model.paper_tilt=Vector2(8.96,-6.08); view.model.lamp_azimuth=-28; view.model.lamp_elevation=80
	view._process(0); await rendered_frame()
	var frontal: Image=view.current_viewport.get_texture().get_image()
	var frontal_exposure:=paper_exposure(frontal)
	var frontal_contrast:=groove_contrast(frontal)
	view.model.lamp_elevation=16
	view._process(0); await rendered_frame()
	var on: Image=view.current_viewport.get_texture().get_image()
	var on_exposure:=paper_exposure(on)
	var history_on: Image=view.history_viewport.get_texture().get_image()
	var full_on: Image=root.get_texture().get_image()
	view.current_world.lamp.light_energy=0
	await rendered_frame()
	var off: Image=view.current_viewport.get_texture().get_image()
	var history_off: Image=view.history_viewport.get_texture().get_image()
	var off_exposure:=paper_exposure(off)
	var on_contrast:=groove_contrast(on); var off_contrast:=groove_contrast(off)
	# Compare the actual paper region, not a viewport-wide average diluted by the room.
	check(absf(on_exposure.mean-off_exposure.mean)>0.025 and image_difference(on,off)>0.002,"Actual paper pixels respond to the physical lamp")
	check(on_contrast>off_contrast+0.02,"Actual groove-side contrast is stronger under the raking lamp than with it off")
	check(on_contrast>frontal_contrast+0.02 and on_contrast>frontal_contrast*1.4,"At an identical paper pose, raking light reveals more groove contrast than the near-normal lamp")
	check(entry_exposure.white_fraction<=0.02 and entry_exposure.clipped_fraction<=0.10,"Entry paper is not made unreadable by white or channel clipping")
	check(frontal_exposure.white_fraction<=0.02 and frontal_exposure.clipped_fraction<=0.10 and on_exposure.white_fraction<=0.02 and on_exposure.clipped_fraction<=0.10,"The normal/raking comparison remains within the paper's unsaturated tonal range")
	check(history_on.get_data()==history_off.get_data(),"Changing current lamp illumination does not change historical pixels")
	check(on.get_width()==390 and on.get_height()>250,"Actual portrait render has expected nonzero dimensions")
	var directory:=OS.get_environment("RAKING_RENDER_ARTIFACT_DIR")
	if not directory.is_empty():
		DirAccess.make_dir_recursive_absolute(directory)
		entry.save_png(directory.path_join("raking-entry-exposure.png"))
		frontal.save_png(directory.path_join("raking-normal-light.png"))
		on.save_png(directory.path_join("raking-lamp-on.png"))
		off.save_png(directory.path_join("raking-lamp-off.png"))
		full_on.save_png(directory.path_join("raking-physical-light-frame.png"))
	print("RAKING_RENDER checks=",checks," failures=",failures," on_contrast=",on_contrast," off_contrast=",off_contrast," frontal_contrast=",frontal_contrast," entry_exposure=",entry_exposure," frontal_exposure=",frontal_exposure," raking_exposure=",on_exposure," paper_lamp_delta=",absf(on_exposure.mean-off_exposure.mean)," image_delta=",image_difference(on,off)," adapter=",RenderingServer.get_video_adapter_name())
	view.queue_free(); await process_frame; quit(1 if failures else 0)
