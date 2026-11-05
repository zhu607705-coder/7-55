extends "res://tests/test_phone_battery_simplified.gd"
## Real Main controls at the corrected default; explicit item prerequisite
## fixtures are labeled and never presented as an earned campaign playthrough.
var output:=OS.get_environment("UI_CAPTURE_DIR")
var captures: Array=[]
func take(id: String) -> void:
	await frames(5)
	if output.is_empty() or DisplayServer.get_name()=="headless":return
	DirAccess.make_dir_recursive_absolute(output)
	await RenderingServer.frame_post_draw
	var rendered:=root.get_texture().get_image()
	check(rendered.save_png(output.path_join(id+".png"))==OK,"actual puzzle frame saved")
	captures.append({"id":id,"brightness":state.d.ui.brightness,"plantLit":state.d.flags.plantLit,"flowerBloomed":state.d.flags.flowerBloomed,"battery":state.d.phoneBattery.percent})
func slider_to(value: float) -> void:
	var slider: Control=named("ControlBrightness")
	check(is_instance_valid(slider),"real Control Center slider exists")
	if not is_instance_valid(slider):return
	var point:=slider.get_global_transform_with_canvas()*Vector2(slider.size.x*.5,104*(1-value/100))
	var motion:=InputEventMouseMotion.new();motion.position=point;root.push_input(motion,true)
	for down: bool in [true,false]:
		var event:=InputEventMouseButton.new();event.position=point;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down;root.push_input(event,true)
	await frames(8)
func run() -> void:
	if not preload("res://tests/native_test_isolation.gd").is_isolated_save():quit(2);return
	create_timer(120).timeout.connect(func():push_error("Brightness puzzle deadline");quit(2))
	state=root.get_node("State");state.developer_mode=false;state.d=state.initial()
	shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames(6)
	shell.set_process(false);shell.audio_director.set_process(false);shell.audio_director.reset()
	for dimensions: Vector2i in [Vector2i(390,844),Vector2i(1440,900)]:
		root.size=dimensions;shell.size=Vector2(dimensions)
		if DisplayServer.get_name()!="headless":DisplayServer.window_set_size(dimensions)
		var prefix:="%dx%d-"%[dimensions.x,dimensions.y]
		await fixture("alarm")
		check(state.d.ui.brightness==65 and not state.d.flags.plantLit,"fresh actual Main opens at relative65 without a plant fact")
		await take(prefix+"opening65")
		await fixture("phone_home",0)
		await click(named("HomeBonsaiOpen"))
		check(state.d.native.page=="bonsai" and state.d.ui.brightness==65 and not state.d.flags.plantLit,"first real bonsai entry at65 does not auto-light")
		await take(prefix+"bonsai65-unsolved")
		# Fixture the other two independent prerequisites to isolate the light gate.
		state.d.flags.plantWatered=true;state.d.flags.plantFertilized=true;shell._refresh();await frames()
		check(not state.d.flags.flowerBloomed and not state.d.flags.plantLit,"water/fertilizer alone still cannot solve at65")
		await click(named("ControlCenterTrigger"))
		await slider_to(79)
		check(state.d.ui.brightness==79 and not state.d.flags.plantLit and not state.d.flags.flowerBloomed,"actual pointer79 remains below unchanged threshold")
		await take(prefix+"manual79-unsolved")
		await slider_to(80)
		check(state.d.ui.brightness==80 and state.d.flags.plantLit and state.d.flags.flowerBloomed,"actual pointer80 triggers the original light gate only now")
		check(state.d.phoneBattery.percent==0,"light puzzle remains operable at zero battery")
		check(state.d.ui.brightnessUserAdjusted,"real pointer records manual preference")
		await take(prefix+"manual80-solved")
		await slider_to(100)
		check(state.save_game() and state.load_game() and state.d.ui.brightness==100 and state.d.ui.brightnessUserAdjusted,"manual100 survives ordinary save/reload")
		check(state.d.flags.plantLit and state.d.flags.flowerBloomed,"reload never erases earned plant progress")
		shell._refresh();await frames()
		await take(prefix+"manual100-reloaded")
	await shell.shutdown();shell.queue_free();await frames()
	if not output.is_empty():
		var file:=FileAccess.open(output.path_join("brightness-puzzle.json"),FileAccess.WRITE)
		file.store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures,"scope":"Real native pointer controls; water/fertilizer prerequisites explicitly fixture-seeded, not earned campaign."},"\t"));file.close()
	print("BRIGHTNESS_PUZZLE_START: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
