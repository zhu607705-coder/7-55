extends SceneTree
## GPU verification of the exact single 0.78 wall/mounted-object blend.
func _initialize()->void:run.call_deferred()
func frames()->void:
	for i in 5:await process_frame
	await RenderingServer.frame_post_draw
func run()->void:
	if DisplayServer.get_name()=="headless" or not preload("res://tests/native_test_isolation.gd").is_isolated_save():quit(2);return
	var output:=OS.get_environment("NORTH_PROP_CAPTURE_DIR")
	if output.is_empty():quit(2);return
	var state:Node=root.get_node("State");state.developer_mode=true;state.begin_checkpoint("c4-755-classrooms-1850")
	state.d.chapter4.mode="light";state.d.native.mode="light"
	root.size=Vector2i(1280,720);DisplayServer.window_set_size(root.size)
	var world:Control=load("res://scripts/world.gd").new();world.size=Vector2(1280,720);root.add_child(world);world.set_process(false)
	await frames()
	world.camera=Vector2(1415,590);world.zoom=2.5;world.transition_alpha=0;world.subtitle="";world.nearby={}
	world.player=Vector2(1406,545);world.mode_mix=0
	world.background=load("res://assets/rpg/interiors/finale/chapter4-755/states/a1_0755_morning.png")
	world.north_objects.configure(world.scene_id,"A1",world.background);world.queue_redraw();await frames()
	var final_image:Image=root.get_texture().get_image()
	world.north_props.wall_reveal.self_modulate.a=0;await frames()
	var unobscured:Image=root.get_texture().get_image()
	world.north_props.wall_reveal.self_modulate.a=.78;world.presentation_actor_hidden=true;world.queue_redraw();await frames()
	var background:Image=root.get_texture().get_image()
	var context:Dictionary=world._render_context();var origin:Vector2=context.origin
	var area:=Rect2i(origin+Vector2(1395,511)*2.5,Vector2(23,35)*2.5)
	var count:=0;var max_error:=0.0;var sum_error:=0.0
	for y in range(area.position.y,area.end.y):
		for x in range(area.position.x,area.end.x):
			var a:Color=unobscured.get_pixel(x,y);var b:Color=background.get_pixel(x,y)
			if Vector3(a.r-b.r,a.g-b.g,a.b-b.b).length()<.15:continue
			var expected:Color=b.lerp(a,.22);var actual:Color=final_image.get_pixel(x,y)
			var error:=maxf(absf(actual.r-expected.r),maxf(absf(actual.g-expected.g),absf(actual.b-expected.b)))
			count+=1;max_error=maxf(max_error,error);sum_error+=error
	var report:={"source":"actual GPU viewport three-state comparison","actorPixels":count,"maxChannelError":max_error,"meanChannelError":sum_error/maxi(1,count),"expectedActorContribution":.22,"passed":count>100 and max_error<.025}
	var file:=FileAccess.open(output.path_join("wall_reveal_gpu.json"),FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
	print("NORTH_WALL_REVEAL_GPU: ",JSON.stringify(report));world.queue_free();await process_frame;quit(0 if report.passed else 1)
