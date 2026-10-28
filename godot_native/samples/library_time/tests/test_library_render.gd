extends SceneTree
const Scene = preload("res://scenes/library_time.tscn")
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	if not ok: failures+=1; push_error("TEST FAILED: "+label)
	else: print("PASS ",label)
func settle() -> void:
	await process_frame; await process_frame; await RenderingServer.frame_post_draw
func difference(a: Image, b: Image, region: Rect2i) -> float:
	var total := 0.0; var count := 0
	for y: int in range(maxi(0,region.position.y),mini(a.get_height(),region.end.y)):
		for x: int in range(maxi(0,region.position.x),mini(a.get_width(),region.end.x)):
			var ca := a.get_pixel(x,y); var cb := b.get_pixel(x,y)
			total+=(absf(ca.r-cb.r)+absf(ca.g-cb.g)+absf(ca.b-cb.b))/3.0; count+=1
	return total/maxi(1,count)
func run() -> void:
	if DisplayServer.get_name()=="headless": print("LIBRARY_RENDER skipped=headless"); quit(2); return
	root.size=Vector2i(390,844); var view := Scene.instantiate(); root.add_child(view); await settle()
	check(RenderingServer.get_video_adapter_name()!="","real graphical renderer present")
	var now_before: Image=view.current_viewport.get_texture().get_image()
	var past_before: Array[Image]=[]
	for index: int in range(2): past_before.append(view.history_viewports[index].get_texture().get_image())
	for index: int in range(2):
		var world=view.history_worlds[index]
		# Remove every mesh of this physical occluder, including rim/handle/binder.
		for blocker: MeshInstance3D in world.blockers: blocker.hide()
		await settle()
		var unblocked: Image=view.history_viewports[index].get_texture().get_image()
		var hidden: Vector2=world.screen_point(world.glyph_point(index!=0))
		var exposed: Vector2=world.screen_point(world.glyph_point(index==0))
		var hidden_delta := difference(past_before[index],unblocked,Rect2i(Vector2i(hidden)-Vector2i(13,11),Vector2i(26,22)))
		var exposed_delta := difference(past_before[index],unblocked,Rect2i(Vector2i(exposed)-Vector2i(9,5),Vector2i(18,10)))
		print("LIBRARY_PIXELS snapshot=",index," hidden_delta=",hidden_delta," exposed_delta=",exposed_delta)
		check(hidden_delta>.025,"historical occluder physically replaces hidden-fragment pixels")
		check(exposed_delta<.075,"other historical fragment stays exposed, not a global reveal shader")
		for blocker: MeshInstance3D in world.blockers: blocker.show()
		await settle()
	check(difference(now_before,view.current_viewport.get_texture().get_image(),Rect2i(0,0,390,844))<.0001,"history geometry changes cannot affect current-world pixels")
	view.current_world.update_current(4,1,false,1.0)
	# Pause only the controller's presentation update so the test can inspect a pulled mesh.
	view.set_process(false); await settle()
	var now_after: Image=view.current_viewport.get_texture().get_image()
	check(difference(now_before,now_after,Rect2i(200,450,160,150))>.006,"actual present book moves with visible depth")
	for index: int in range(2): check(difference(past_before[index],view.history_viewports[index].get_texture().get_image(),Rect2i(0,0,174,210))<.0001,"current retrieval never rewrites historical pixels")
	var output := OS.get_environment("LIBRARY_RENDER_ARTIFACT_DIR")
	if not output.is_empty():
		now_before.save_png(output+"/present-baseline.png")
		past_before[0].save_png(output+"/morning-fragment.png"); past_before[1].save_png(output+"/afternoon-fragment.png")
		for dimensions: Vector2i in [Vector2i(430,860),Vector2i(1280,720),Vector2i(844,390)]:
			root.size=dimensions; await settle(); view.model.resume(); view.resume_button.hide(); view.reset_button.hide(); view.queue_redraw(); await settle()
			root.get_texture().get_image().save_png(output+"/layout-%dx%d.png"%[dimensions.x,dimensions.y])
	print("LIBRARY_RENDER failures=",failures)
	view.queue_free(); await process_frame; quit(1 if failures else 0)
