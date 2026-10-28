extends Node
## Explicit QA scene using the real Main and its accepted-action signal.
## Source checkpoints are labelled; this is not a continuous-playthrough claim.
const Fixture=preload("res://tests/helpers/chapter4_time_feedback_fixture.gd")
@onready var state_node: Node=get_node("/root/State")
var shell: Control
var busy:=false
var reduced:=false
var bar: HFlowContainer
var note: Label
var capture_directory: String

func _ready() -> void:
	if not state_node.developer_tools_available() or OS.has_feature("755_production"):
		push_error("Time-feedback QA is unavailable in a production build.");get_tree().quit(2);return
	capture_directory=OS.get_environment("C4_FEEDBACK_CAPTURE_DIR")
	var recording:=not capture_directory.is_empty() or OS.get_environment("C4_FEEDBACK_REQUIRE_GRAPHICAL")=="1" or OS.get_cmdline_args().has("--write-movie")
	if recording and (DisplayServer.get_name()=="headless" or RenderingServer.get_current_rendering_method()=="dummy"):
		push_error("Real viewport capture requires a supported graphical renderer; no images were written.");get_tree().quit(2);return
	state_node.developer_mode=true
	var layer:=CanvasLayer.new();layer.layer=90;add_child(layer)
	bar=HFlowContainer.new();layer.add_child(bar)
	bar.theme=load("res://scripts/ui/native_ui_theme.gd").font_theme(load("res://scripts/ui/native_typography.gd").body_font())
	for entry in [["comparison","1 核对时间"],["restoration","2 204复原"],["minute","3 分针归位"]]:
		var button:=Button.new();button.text=entry[1];button.custom_minimum_size=Vector2(100,32)
		var kind: String=entry[0];button.pressed.connect(func(): play_sample(kind));bar.add_child(button)
	var toggle:=CheckButton.new();toggle.text="减弱动态";toggle.toggled.connect(func(on): reduced=on);bar.add_child(toggle)
	note=Label.new();note.text="QA 源检查点 · 非连续通关 · 不写正式存档";note.mouse_filter=Control.MOUSE_FILTER_IGNORE;note.theme=bar.theme;note.add_theme_font_size_override("font_size",13);layer.add_child(note)
	get_viewport().size_changed.connect(_layout_toolbar);_layout_toolbar()
	if not capture_directory.is_empty(): capture_sequence.call_deferred()
	elif OS.get_environment("C4_FEEDBACK_AUTOPLAY")=="1": autoplay.call_deferred()
	else: play_sample.call_deferred("comparison")

func _layout_toolbar() -> void:
	var dimensions:=get_viewport().get_visible_rect().size
	bar.position=Vector2(8,maxf(0,dimensions.y-94));bar.size=Vector2(maxf(1,dimensions.x-16),68)
	note.position=Vector2(8,maxf(0,dimensions.y-22))

func play_sample(kind: String) -> void:
	if busy:return
	busy=true
	if is_instance_valid(shell):
		await shell.shutdown();shell.queue_free();await get_tree().process_frame
	Fixture.prepare(state_node,kind);state_node.d.native.settings.reduced_motion=reduced
	shell=load("res://scenes/main.tscn").instantiate();add_child(shell)
	for i in 5:await get_tree().process_frame
	shell._show_world_mobile();shell._refresh()
	for i in 3:await get_tree().process_frame
	state_node.act(Fixture.action(kind))
	# The existing projection must really finish its own 900ms before this
	# host is eligible. Nothing in this harness fabricates its terminal proof.
	var until:=Time.get_ticks_msec()+6000
	while is_instance_valid(shell) and shell.chapter4_time_feedback.cue!=kind and Time.get_ticks_msec()<until:
		await get_tree().process_frame
	busy=false
	if not is_instance_valid(shell) or shell.chapter4_time_feedback.cue!=kind:
		push_error("Accepted feedback did not start before the QA timeout: "+kind)
		get_tree().quit(1)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var kinds: Dictionary={KEY_1:"comparison",KEY_2:"restoration",KEY_3:"minute"}
		if kinds.has(event.keycode):play_sample(kinds[event.keycode]);get_viewport().set_input_as_handled()

func autoplay() -> void:
	for kind in ["comparison","restoration","minute"]:
		await play_sample(kind)
		await get_tree().create_timer(1.7).timeout
	await shell.shutdown();get_tree().quit()

func capture_sequence() -> void:
	DirAccess.make_dir_recursive_absolute(capture_directory)
	var records: Array=[]
	for dimensions in [Vector2i(1280,720),Vector2i(390,844),Vector2i(844,390)]:
		get_window().size=dimensions
		for kind in ["comparison","restoration","minute"]:
			await play_sample(kind)
			var feedback: Control=shell.chapter4_time_feedback
			if feedback.cue!=kind:push_error("Accepted presentation did not start: "+kind);get_tree().quit(1);return
			feedback.set_process(false);feedback.motion.pause()
			for stamp in [.10,.58,.94]:
				feedback._sample_time(stamp)
				await get_tree().process_frame;await RenderingServer.frame_post_draw
				var file: String="%s-%dx%d-%03d.png"%[kind,dimensions.x,dimensions.y,int(stamp*100)]
				var image:=get_viewport().get_texture().get_image()
				if image==null or image.is_empty() or image.save_png(capture_directory.path_join(file))!=OK:
					push_error("Viewport capture failed");get_tree().quit(1);return
				records.append({"file":file,"cue":kind,"seconds":stamp,"width":image.get_width(),"height":image.get_height()})
	FileAccess.open(capture_directory.path_join("capture.json"),FileAccess.WRITE).store_string(JSON.stringify({"engine":Engine.get_version_info().string,"display":DisplayServer.get_name(),"renderer":RenderingServer.get_current_rendering_method(),"source":"actual Main viewport; isolated source-checkpoint fixtures, not continuous earned gameplay","captures":records},"  ")+"\n")
	await shell.shutdown();get_tree().quit()
