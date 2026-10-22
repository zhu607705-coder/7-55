extends "res://tests/test_portrait_exploration.gd"
## Pointer ownership must end before the next surface becomes interactive.
func press_phone_key() -> void:
	for down: bool in [true,false]:
		var e:=InputEventKey.new(); e.keycode=KEY_P; e.physical_keycode=KEY_P; e.pressed=down
		event(e); await frames(1)
	await frames()
func run() -> void:
	state=root.get_node("State");state.developer_mode=true;state.d=state.initial()
	shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames()
	for dimensions: Vector2i in [Vector2i(390,844),Vector2i(430,860),Vector2i(1440,900)]:
		await fixture(dimensions)
		var actor: Vector2=shell.world.player
		var items: Dictionary=state.d.items.duplicate(true)
		var emulation: bool=Input.emulate_mouse_from_touch
		var world_item: Control=await reveal("gamepad")
		var drag_point: Vector2=await begin_drag(world_item,true)
		await press_phone_key()
		check(shell.phone.visible and not shell.world_frame.visible,"phone key switches from world while canceling its drag")
		check(not root.gui_is_dragging() and Gesture.touch_owner()==null and Input.emulate_mouse_from_touch==emulation,"world drag ownership is synchronously released")
		touch(drag_point,false,true);await frames()
		check(state.d.items==items and shell.world.player==actor,"canceled world drop keeps items and actor")
		var chrome: Control=shell.phone_chrome
		if not chrome.inventory_open:await click(chrome.inventory_handle)
		var phone_item: Control=chrome.inventory_slots.get_node("Item_gamepad")
		chrome.inventory_scroll.ensure_control_visible(phone_item);await frames()
		var point: Vector2=phone_item.get_global_rect().get_center()
		motion(point);mouse(point,true);motion(point+Vector2(24,0),Vector2(24,0),MOUSE_BUTTON_MASK_LEFT);await frames(2)
		check(root.gui_is_dragging(),"phone inventory owns a real pointer drag")
		await press_phone_key()
		check(shell.world_frame.visible and not shell.phone.visible,"phone key returns to the retained world")
		check(not root.gui_is_dragging() and Gesture.touch_owner()==null,"phone drag cannot leak into newly revealed world")
		mouse(point+Vector2(24,0),false);await frames()
		check(state.d.items==items and shell.world.player==actor,"canceled phone drop keeps items and actor")
	await shell.shutdown();shell.queue_free();await frames()
	print("NATIVE_SURFACE_GESTURES: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
