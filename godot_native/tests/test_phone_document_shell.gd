extends SceneTree
var failures:=0
func check(value: bool,message: String) -> void:
	if not value: failures+=1; push_error("TEST FAILED: "+message)
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	var state=root.get_node("State"); state.developer_mode=true; state.d=state.initial(); state.d.native.page="phone_home"
	var shell=load("res://scenes/main.tscn").instantiate(); root.add_child(shell); await process_frame
	shell.phone_builder.document_requested.emit({"item_id":"bagNonPersonProof","source":"library_recovery"})
	await process_frame; await process_frame
	check(is_instance_valid(shell.phone_document),"builder document signal opens shared phone overlay")
	var overlay: Control=shell.phone_document.get_child(0)
	check((overlay.size*overlay.scale).is_equal_approx(Vector2(424,854)),"document covers entire inner phone including status strip")
	check(shell.phone_document.size.is_equal_approx(Vector2(424,854)),"container wrapper avoids scale reset and overflow")
	check(shell.phone_chrome.input_blocked,"shared chrome input blocked under document")
	check(shell._read_runtime_state().native.host.phone_modal_open,"other hosts observe active document modal")
	overlay.closed.emit(); await process_frame
	check(not is_instance_valid(shell.phone_document) and not shell.phone_chrome.input_blocked,"closing restores shared chrome")
	shell.phone_builder.document_requested.emit({"item_id":"seat022Receipt","source":"library_recovery"}); await process_frame
	state.story_reset.emit(); await process_frame
	check(not is_instance_valid(shell.phone_document),"reset cancels standalone phone document")
	await shell.shutdown(); shell.queue_free(); await process_frame
	print("Phone document shell failures: ",failures)
	quit(1 if failures else 0)
