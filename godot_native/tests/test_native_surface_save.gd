extends "res://tests/test_native_surface_modes.gd"
func run() -> void:
	state=root.get_node("State")
	await create_shell(Vector2i(1440,900),"library_interior")
	state.d.rpgCheckpoint="library_entrance"
	shell.world.player=shell.world._find_safe(Vector2(715,790)); shell.world._sync_player()
	var actor: Vector2=shell.world.player
	var items: Dictionary=state.d.items.duplicate(true)
	var puzzle: Dictionary=state.d.ui.libraryFinalsPuzzle.duplicate(true)
	var file: String="user://native-surface-save.json"
	state.developer_mode=false
	check(state.save_game(),"normal authoritative save succeeds")
	check(state.export_save(file)==OK,"normal portable export succeeds")
	await click(shell.mobile_back); exclusive("phone")
	for i in range(2):
		var imported: Dictionary=state.import_save(file); await frames(8)
		check(imported.ok,"normal import succeeds")
		exclusive("world")
		check(shell.world.player==actor and state.d.rpgCheckpoint=="library_entrance","import restores scene position and checkpoint")
		check(state.d.items==items and state.d.ui.libraryFinalsPuzzle==puzzle,"import retains inventory and evidence")
		check(not is_instance_valid(shell.active_game),"import creates no unrelated activity owner")
		await click(shell.mobile_back); exclusive("phone")
	# Shutdown/recreate reads the ordinary primary save, retaining progression.
	await close_shell()
	state.d=state.initial(); check(state.load_game(),"primary save reload succeeds")
	shell=load("res://scenes/main.tscn").instantiate(); root.add_child(shell); await frames(8)
	exclusive("world")
	check(shell.world.player==actor and state.d.items==items and state.d.ui.libraryFinalsPuzzle==puzzle,"ordinary restart preserves world progression")
	# A deliberate phone-only new game must clear the previous surface owner.
	state.new_game(); await frames(6); exclusive("phone")
	check(state.d.native.page=="alarm" and not shell.phone_world_return.visible,"new game returns to authored alarm")
	await close_shell()
	print("NATIVE_SURFACE_SAVE: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
