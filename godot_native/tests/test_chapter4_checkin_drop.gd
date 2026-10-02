extends "res://tests/test_chapter4_device_main.gd"
var feedback: Array=[]
var actions: Array=[]
func motion(at: Vector2,mask: int=0,relative: Vector2=Vector2.ZERO) -> void:
	var event:=InputEventMouseMotion.new();event.position=at;event.global_position=at;event.button_mask=mask;event.relative=relative;Input.parse_input_event(event);await process_frame
func mouse(at: Vector2,down: bool) -> void:
	var event:=InputEventMouseButton.new();event.position=at;event.global_position=at;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down;Input.parse_input_event(event);await process_frame
func drag_from(item: Control,end: Vector2) -> void:
	var start: Vector2=item.get_global_rect().get_center()
	var landed: Array=[]; item.drag_finished.connect(func(value): landed.append(value))
	await motion(start);await mouse(start,true)
	for i in range(1,10): await motion(start.lerp(end,i/9.0),MOUSE_BUTTON_MASK_LEFT,(end-start)/9)
	print("DRAGGING ",root.gui_is_dragging()," hovered=",root.gui_get_hovered_control()," start=",start," end=",end)
	await mouse(end,false); await frames(4)
	print("END landed=",landed," messages=",feedback," actions=",actions)
func run() -> void:
	state_node=root.get_node("State");state_node.developer_mode=true
	state_node.feedback.connect(func(message): feedback.append(message))
	state_node.action_completed.connect(func(id,_before,_after,_result): actions.append(id))
	await prepare(Vector2i(1180,812),"c4-755-checkin")
	# Explicit valid stand fixture, not a claim of human navigation.
	shell.world.player=Vector2(836,660); shell.world._sync_player(); shell.world._update_camera(); shell.world.queue_redraw(); await frames(5)
	var point:=Vector2(799,619)
	print("PICKS ",shell.world._pick_target(point,false)," DROP ",shell.world._pick_target(point,true))
	var local: Vector2=(point-shell.world.camera)*shell.world.zoom+shell.world.size/2
	var screen: Vector2=shell.world_view.get_global_transform_with_canvas()*(local*shell.world_view.size/Vector2(shell.world_viewport.size))
	print("BRIDGE expected=",local," actual=",shell.world_view.source_position(shell.world_view.get_global_transform_with_canvas().affine_inverse()*screen))
	var card: Control
	for item in shell.inventory_buttons.get_children():
		if item.item_id=="campusCard": card=item
	await drag_from(card,screen)
	check(state_node.d.chapter4.checkinCardAccepted,"actual Main check-in card drag reaches visible reader")
	await shell.shutdown();shell.queue_free();await frames(3)
	print("C4_CHECKIN_DROP: ",checks," checks; ",failures," failures");quit(1 if failures else 0)
