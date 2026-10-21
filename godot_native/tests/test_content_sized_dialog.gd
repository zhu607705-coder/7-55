extends SceneTree
var checks := 0
var failures := 0
func _initialize() -> void: run.call_deferred()
func frames() -> void:
	for unused in 8: await process_frame
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures += 1; push_error(message)
func run() -> void:
	var state := root.get_node("State")
	state.developer_mode = true
	state.d = state.initial()
	var shell: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(shell)
	await frames()
	for dimensions: Vector2i in [Vector2i(390,844),Vector2i(844,390),Vector2i(1440,900)]:
		root.size = dimensions; shell.size = Vector2(dimensions)
		for repeated in 2:
			var content: VBoxContainer = shell._modal_base("调查记录")
			var text: Label = shell._label("在现场收集证据。",17)
			text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			content.add_child(text)
			await frames()
			var compact_height: float = shell.modal_panel.size.y
			check(compact_height < 300,"short dialog must not become a 700px empty panel")
			check(Rect2(Vector2.ZERO,Vector2(dimensions)).encloses(shell.modal_panel.get_global_rect()),"short dialog contained")
			for row in 40:
				var label: Label = shell._label("现场记录 %d：将来源、时间与物证逐一核对。"%row,17)
				label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				content.add_child(label)
			await frames()
			check(shell.modal_panel.size.y > compact_height,"long record grows naturally")
			check(shell.modal_panel.size.y <= minf(700,dimensions.y-24),"long record capped")
			check(Rect2(Vector2.ZERO,Vector2(dimensions)).encloses(shell.modal_panel.get_global_rect()),"long dialog contained")
			shell._close_modal()
			await frames()
			check(not is_instance_valid(shell.modal),"dismissal releases modal")
	await shell.shutdown(); shell.queue_free(); await frames()
	print("Content-sized dialog: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
