extends "res://tests/test_room301_archive_main.gd"
## Reversible layout preview only, separate from final acceptance evidence.
func select_index_preview()->void:
	for i in range(3):await press_key(KEY_RIGHT)
	await press_key(KEY_DOWN)
	for i in range(3):await press_key(KEY_RIGHT)
	await press_key(KEY_DOWN)
	for i in range(2):await press_key(KEY_RIGHT)
func run()->void:
	if DisplayServer.get_name()=="headless":print("ROOM301_INDEX_PREVIEW: graphical display required");quit(0);return
	state_node=root.get_node("State")
	var output:=OS.get_environment("ROOM301_TAB_PREVIEW_DIR")
	if output.is_empty():output=ProjectSettings.globalize_path("res://.screenshots/room301-tabs")
	DirAccess.make_dir_recursive_absolute(output)
	for dim:Vector2i in [Vector2i(1280,720),Vector2i(390,844)]:
		await prepare_archive(dim);shell._show_world_mobile();await frames(3)
		var panel:Control=await open_archive()
		await select_index_preview();await frames(4);await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output+"/room301-index-tabs-%dx%d.png"%[dim.x,dim.y])
		check(not panel.session.completed,"Preview does not submit or grant film")
		check(panel.view.index_targets.size()==3,"Preview has exactly three attached selectors")
		await press_key(KEY_ESCAPE)
	await shell.shutdown();shell.queue_free();await frames(3)
	print("ROOM301_INDEX_PREVIEW: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
