extends SceneTree
var checks:=0
var errors:=0
func check(value: bool,label: String) -> void:
	checks+=1
	if not value: errors+=1; push_error("SHELL INPUT: "+label)
func _initialize() -> void: call_deferred("run")
func click_at(point: Vector2) -> void:
	var motion:=InputEventMouseMotion.new(); motion.position=point; motion.global_position=point
	root.push_input(motion,true)
	var down:=InputEventMouseButton.new(); down.position=point; down.global_position=point; down.button_index=MOUSE_BUTTON_LEFT; down.pressed=true
	root.push_input(down,true)
	var up:=down.duplicate(); up.pressed=false
	root.push_input(up,true)
	await process_frame
	await process_frame
func run() -> void:
	root.size=Vector2i(1440,900)
	var state: Node=root.get_node("State")
	state.developer_mode=true; state.d=state.initial(); state.d.native.page="wechat"
	var main=load("res://scenes/main.tscn").instantiate(); root.add_child(main)
	await process_frame; await process_frame
	var nav=main.page_body.find_child("PhoneNav_exit",true,false)
	check(nav!=null,"native source navigation is present")
	if nav:
		var point: Vector2=nav.get_global_rect().get_center()
		await click_at(point)
		var hover=root.gui_get_hovered_control()
		print("CLICK ",point," HOVER ",hover.get_path() if hover else "none"," PAGE ",state.d.native.page)
		check(state.d.native.page=="phone_home","actual root pointer reaches app exit under overlay chrome")
	main.queue_free(); await process_frame
	print("Native shell input: ",checks," checks, ",errors," errors")
	quit(1 if errors else 0)
