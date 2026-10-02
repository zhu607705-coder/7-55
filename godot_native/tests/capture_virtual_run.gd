extends "res://tests/test_virtual_run_controls.gd"
## Run only in the lead's graphical session. Headless rendering is not evidence.
var captured := 0
var capture_dir := "res://.screenshots/virtual-run"

func capture(label: String) -> void:
	await frames(3)
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	check(not image.is_empty(),"graphical capture is nonempty")
	check(image.save_png(capture_dir.path_join(label+".png")) == OK,"save graphical fixture")
	captured += 1

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Run test_virtual_run_controls.gd headlessly; this capture harness needs the lead's graphical session.")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir))
	for view: Vector2i in [Vector2i(390,844),Vector2i(430,860)]:
		await spawn(view)
		var tag := "%dx%d" % [view.x,view.y]
		verify_layout()
		await capture(tag+"-01-ready")
		await mouse_click(game.point_buttons[6])
		await capture(tag+"-02-wrong-point")
		for i in range(5): await mouse_click(game.target)
		await capture(tag+"-03-halfway")
		for i in range(4): await mouse_click(game.target)
		await capture(tag+"-04-final-target")
		await mouse_click(game.target)
		check(results.size() == 1,"capture path used ten real presses")
		game.resolve(false)
		await capture(tag+"-05-authority-rejected")
		await mouse_click(game.target)
		game.resolve(true)
		await capture(tag+"-06-accepted-result")
		await mouse_click(game.return_button)
		check(cancels == 1,"real return control closes result")
	print("VIRTUAL_RUN_CAPTURES: %d captures; %d checks; %d failures. Automated fixtures, not manual campaign proof." % [captured,checks,failures])
	quit(1 if failures else 0)
