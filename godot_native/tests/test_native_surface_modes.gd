extends SceneTree
## Real Main input and ownership. Fixtures isolate layout; not a campaign proof.
var state: Node
var shell: Control
var checks:=0
var failures:=0
func _initialize() -> void: run.call_deferred()
func frames(count: int=4) -> void:
	for i in range(count): await process_frame
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error("SURFACE MODES: "+message)
func key(code: Key) -> void:
	for down: bool in [true,false]:
		var event:=InputEventKey.new(); event.keycode=code; event.physical_keycode=code; event.unicode=112 if code==KEY_P else 0; event.pressed=down
		root.push_input(event,true); await frames(1)
	await frames()
func click(button: Button) -> void:
	check(button!=null and button.is_visible_in_tree() and not button.disabled,"surface button is visible and enabled")
	var point:=button.get_global_rect().get_center()
	check(Rect2(Vector2.ZERO,Vector2(root.size)).has_point(point),"surface button is reachable")
	for down: bool in [true,false]:
		var event:=InputEventMouseButton.new(); event.position=point; event.global_position=point; event.button_index=MOUSE_BUTTON_LEFT; event.pressed=down
		root.push_input(event,true); await frames(1)
	await frames()
func close_shell() -> void:
	if is_instance_valid(shell): await shell.shutdown(); shell.queue_free(); await frames()
func create_shell(view: Vector2i,scene: String="") -> void:
	await close_shell()
	root.size=view
	state.d=state.initial(); state.developer_mode=true
	if not scene.is_empty():
		state.d.native.chapter=2; state.d.native.page="phone_home"; state.d.native.scene=scene
		state.d.runtimeMode="rpg"; state.d.rpgScene=scene; state.d.actOne.phase="complete"; state.d.actOne.movementEnabled=true
		state.d.ui.libraryFinalsPhase="library_entered"
		state.d.items.campusCard=true
	shell=load("res://scenes/main.tscn").instantiate(); root.add_child(shell); await frames(6)
	# Keep presentation-driven progression outside the layout fixture.
	shell.world.set_process(false)
func exclusive(surface: String) -> void:
	check(shell.phone.visible==(surface=="phone") and shell.world_frame.visible==(surface=="world"),"exactly one requested surface: "+surface)
	check(not shell._uses_split_layout(),"no viewport enables a permanent split")
	check(shell.world_viewport.gui_disable_input==(surface=="phone"),"hidden world viewport input is disabled")
func run() -> void:
	state=root.get_node("State")
	for view: Vector2i in [Vector2i(1440,900),Vector2i(1280,720),Vector2i(390,844),Vector2i(430,860)]:
		await create_shell(view)
		exclusive("phone")
		check(not shell.phone_world_return.visible and not shell.mobile_back.visible,"phone-only opening offers no empty world")
		await key(KEY_P); await key(KEY_ESCAPE); exclusive("phone")
		check(state.d.native.page=="alarm" and state.d.native.scene.is_empty(),"opening shortcuts do not bypass story")
		await create_shell(view,"library_interior")
		if view.x>=1100:
			exclusive("world")
			check(shell.world_frame.get_global_rect().size.x>view.x*.85,"desktop world uses the full play width")
			check(not shell.world.mobile_exploration,"desktop keeps keyboard/camera contract")
		else:
			exclusive("phone")
			await click(shell.phone_world_return)
			exclusive("world")
			check(shell.world.mobile_exploration,"compact world keeps responsive exploration")
		var actor: Vector2=shell.world.player
		var world_instance: int=shell.world.get_instance_id()
		var scene: String=state.d.native.scene
		var progress: Dictionary=state.d.ui.libraryFinalsPuzzle.duplicate(true)
		var items: Dictionary=state.d.items.duplicate(true)
		for cycle in range(3):
			shell.world.pan_offset=Vector2(17,9); shell.world._update_camera()
			var camera: Vector2=shell.world.camera
			var pan: Vector2=shell.world.pan_offset
			shell.world.move_target=actor+Vector2(30,0); shell.world.touch_axis=Vector2.RIGHT
			await click(shell.mobile_back)
			exclusive("phone")
			check(shell.world.move_target==Vector2.INF and shell.world.touch_axis==Vector2.ZERO,"opening phone cancels world gestures")
			shell.world._process(.05); await key(KEY_W); await key(KEY_SPACE)
			check(shell.world.player==actor and state.d.native.scene==scene,"phone input cannot move or interact with hidden world")
			check(shell.world.get_instance_id()==world_instance,"phone never remounts the world")
			check(Rect2(Vector2.ZERO,Vector2(view)).encloses(shell.phone.get_global_rect()),"canonical phone fits available viewport")
			await key(KEY_ESCAPE); exclusive("world")
			check(shell.world.has_focus(),"return restores keyboard focus")
			check(shell.world.camera==camera and shell.world.pan_offset==pan,"same-size phone open/back preserves camera and pan")
			check(shell.world.player==actor and state.d.items==items and state.d.ui.libraryFinalsPuzzle==progress,"open/back preserves actor items and story")
		# Root input must reserve P while the retained world viewport owns focus.
		shell.world.grab_focus(); await frames()
		check(shell.world.has_focus(),"P regression starts with world SubViewport focus")
		await key(KEY_P); exclusive("phone")
		var text_input:=LineEdit.new(); shell.add_child(text_input); text_input.grab_focus(); await frames()
		await key(KEY_P)
		check(shell.phone.visible and text_input.has_focus(),"P typed in a phone text field does not switch surfaces")
		text_input.queue_free(); await frames()
		shell._show_settings(); await frames()
		var modal: Control=shell.modal
		await key(KEY_P)
		check(shell.modal==modal and shell.phone.visible,"shortcut does not steal modal ownership")
		await key(KEY_ESCAPE)
		check(not is_instance_valid(shell.modal) and shell.phone.visible,"Escape closes only the foremost modal")
		shell._open_phone_document({"item_id":"seat022Receipt"}); await frames()
		await key(KEY_P)
		check(is_instance_valid(shell.phone_document) and shell.phone.visible,"document owns input until dismissed")
		shell._close_phone_document(); await frames()
		state.d.ui.controlCenterOpen=true; shell._refresh_control_center(); await frames(); await key(KEY_P)
		check(shell.phone.visible and state.d.ui.controlCenterOpen,"Control Center owns input")
		state.d.ui.controlCenterOpen=false; shell._refresh_control_center(); await frames()
		await click(shell.phone_world_return); exclusive("world")
		await click(shell.inventory_handle)
		check(shell.inventory_dock.visible,"single world inventory opens")
		check(Rect2(Vector2.ZERO,Vector2(view)).encloses(shell.inventory_dock.get_global_rect()),"inventory stays inside viewport")
		# Rotation changes geometry only, including a phone opened over a world.
		await key(KEY_P); exclusive("phone")
		for rotated: Vector2i in [Vector2i(844,390),Vector2i(390,844),Vector2i(1440,900),view]:
			root.size=rotated; shell.size=Vector2(rotated); shell._layout(); await frames()
			exclusive("phone")
			check(shell.world.get_instance_id()==world_instance and shell.world.player==actor,"rotation preserves world identity and actor")
		await click(shell.phone_world_return); exclusive("world")
		check(not is_instance_valid(shell.active_game),"ordinary scene return creates no activity")
		shell._open_game({"script":"res://scripts/games/virtual_run.gd","viewport":[430,860]}); await frames()
		var activity: Control=shell.active_game
		await key(KEY_P)
		check(shell.active_game==activity and shell.mobile_world,"phone shortcut cannot replace the active minigame")
		activity.cancelled.emit(); await frames()
		check(not is_instance_valid(shell.active_game) and shell.world_frame.visible,"activity close returns to its retained world")
	# Existing phone-mode story return, such as rain rescue, must stay phone.
	await close_shell(); state.d=state.initial(); state.developer_mode=true
	state.d.native.scene="dorm_hub"; state.d.native.page="phone_home"; state.d.runtimeMode="phone"
	root.size=Vector2i(1440,900); shell=load("res://scenes/main.tscn").instantiate(); root.add_child(shell); await frames()
	exclusive("phone")
	check(shell.phone_world_return.visible,"controller phone handoff retains explicit world return")
	await close_shell()
	print("NATIVE_SURFACE_MODES: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
