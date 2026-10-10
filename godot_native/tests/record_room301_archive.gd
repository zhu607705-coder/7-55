extends "res://tests/test_room301_archive_main.gd"
## Optional fixed-30fps movie of real source-seeded Main inputs.
## This is not a physical-phone or real-time performance benchmark.
func run()->void:
	if DisplayServer.get_name()=="headless":print("ROOM301_MOVIE requires a graphical display");quit(0);return
	state_node=root.get_node("State")
	# MovieWriter fixes its capture to the project's initial 1440x900 surface.
	# Do not resize that root after recording begins: it crops the encoded view.
	await prepare_archive(Vector2i(1440,900))
	shell.world.player=Vector2(290,442);shell.world._sync_player();shell._show_world_mobile();await frames(8)
	var panel:Control=await open_archive()
	await frames(24)
	await select_index(panel,"yearBand","1977_1984");await select_index(panel,"floor","A1");await select_index(panel,"purpose","attendance")
	await click_at(panel.view.handle.get_center());await frames(27)
	check(not panel.session.completed,"Movie wrong original index is rejected")
	await press_key(KEY_ESCAPE);await frames(10);panel=await open_archive()
	await select_index(panel,"yearBand","1991_1998");await select_index(panel,"floor","A3");await select_index(panel,"purpose","wayfinding")
	await frames(12);await click_at(panel.view.handle.get_center());await frames(18)
	check(panel.session.completed,"Movie correct original index is controller accepted")
	await press_key(KEY_ESCAPE);await frames(42)
	check(shell.world.chapter4_layers.archive_motion.stage=="idle","Movie world drawer reaches its terminal source pose")
	panel=await open_archive();await frames(28)
	check(panel.session.completed and not panel.fresh_success,"Movie completed reentry does not replay acquisition")
	await press_key(KEY_ESCAPE);await frames(12)
	await shell.shutdown();shell.queue_free();await frames(3)
	print("ROOM301_MOVIE: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
