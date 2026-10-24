extends SceneTree
## Explicit source checkpoint/display fixture, not a claimed earned playthrough.
const Tiled=preload("res://scripts/presentation/source_tiled_texture.gd")
var checks:=0
var failures:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;print("FAIL: ",label)
func frames(count:int=4)->void:
	for i in count:await process_frame
func run()->void:
	check(load("res://tests/native_test_isolation.gd").is_isolated_save(),"isolated Main fixture profile")
	if failures:quit(1);return
	var state:Node=root.get_node("State")
	check(state.begin_checkpoint("c3-qizhen-location"),"authored source checkpoint prepares the investigation facts")
	state.open_page("c3_location")
	check(state.d.native.page=="c3_location" and state.validate_snapshot(state.d),"original page API selects a normally validated location display fixture")
	var facts:=JSON.stringify({"items":state.d.items,"lake":state.d.qizhenLake,"theater":state.d.theaterHunt})
	check(not ResourceLoader.has_cached(Tiled.SOURCE),"oversized source texture is not cached before mounting Main")
	root.size=Vector2i(390,844)
	var shell:Control=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames(5)
	for host in [shell.c3_narrative_host,shell.c3_scene_host,shell.library_story_host]:host.set_process(false)
	shell.world.set_process(false)
	var art:Control=shell.find_child("SourceTiledNarrativeArt",true,false)
	check(art!=null and art.get_script().resource_path=="res://scripts/presentation/source_tiled_view.gd","real Main generic artwork branch mounts tiled narrative view")
	if art!=null:
		check(art.plate.ready and art.plate.textures.size()==7 and art.plate.snapshot().maxTextureDimension<=2048,"real Main artwork owns only imported GPU-sized pieces")
		check(art.custom_minimum_size==Vector2(378,180) and art.size.x>0 and art.size.y>=180,"original narrative artwork size contract survives layout")
	check(not ResourceLoader.has_cached(Tiled.SOURCE),"Main generic artwork never silently loads or caches original giant texture")
	check(JSON.stringify({"items":state.d.items,"lake":state.d.qizhenLake,"theater":state.d.theaterHunt})==facts,"drawing the card does not mutate story/item facts")
	var capture:=OS.get_environment("TILED_MAIN_CAPTURE")
	if not capture.is_empty() and DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png(capture)==OK,"capture actual Main location card after GPU draw")
	await shell.shutdown();shell.queue_free();await frames(2)
	print("SOURCE_TILED_MAIN: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
