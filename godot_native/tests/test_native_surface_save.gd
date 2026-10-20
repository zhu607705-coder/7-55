extends "res://tests/test_native_surface_modes.gd"
## Source-phase layout fixtures. Real buttons, native disk writes and fresh Main
## instances verify both explicit surfaces without changing earned progression.
func disk_mode(expected:String) -> void:
	var saved:Dictionary=state._read_native_save(state.SAVE_PATH)
	check(not saved.is_empty() and saved.state.runtimeMode==expected,"ordinary saved file retains explicit "+expected+" mode")
func reload_primary(surface:String,actor:Vector2,prior:Dictionary) -> void:
	await close_shell()
	state.d=state.initial();check(state.load_game(),"primary save reload succeeds for "+surface)
	shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames(8)
	shell.world.set_process(false)
	exclusive(surface)
	check(state.d.runtimeMode==("phone" if surface=="phone" else "rpg"),"ordinary restart restores the last explicit surface")
	check(state.d.native.scene==prior.scene and state.d.rpgCheckpoint==prior.checkpoint and shell.world.player==actor,"ordinary restart preserves scene, checkpoint and actor")
	check(state.d.items==prior.items and state.d.wallet==prior.wallet and state.d.actOne==prior.actOne and state.d.ui.libraryFinalsPuzzle==prior.puzzle,"ordinary restart preserves inventory, wallet and progression")
func verify_viewport(view:Vector2i) -> void:
	await create_shell(view,"library_interior")
	state.d.rpgCheckpoint="library_entrance"
	shell.world.player=shell.world._find_safe(Vector2(715,790));shell.world._sync_player()
	var actor:Vector2=shell.world.player
	var prior:Dictionary={"scene":state.d.native.scene,"checkpoint":state.d.rpgCheckpoint,"items":state.d.items.duplicate(true),"wallet":state.d.wallet.duplicate(true),"actOne":state.d.actOne.duplicate(true),"puzzle":state.d.ui.libraryFinalsPuzzle.duplicate(true)}
	var file:String="user://native-surface-save.json"
	state.developer_mode=false
	check(state.save_game(),"normal authoritative save succeeds at "+str(view))
	check(state.export_save(file)==OK,"normal portable export succeeds")
	await click(shell.mobile_back);exclusive("phone");disk_mode("phone")
	for i in range(2):
		var imported:Dictionary=state.import_save(file);await frames(8)
		check(imported.ok,"normal import succeeds")
		exclusive("world")
		check(state.d.native.scene==prior.scene and shell.world.player==actor and state.d.rpgCheckpoint==prior.checkpoint,"import restores scene position and checkpoint")
		check(state.d.items==prior.items and state.d.wallet==prior.wallet and state.d.actOne==prior.actOne and state.d.ui.libraryFinalsPuzzle==prior.puzzle,"import retains inventory, wallet and evidence")
		check(not is_instance_valid(shell.active_game),"import creates no unrelated activity owner")
		await click(shell.mobile_back);exclusive("phone");disk_mode("phone")
	# Reload the actual last phone choice first, then exercise the ordinary
	# Return button and prove the separately saved world choice survives too.
	await reload_primary("phone",actor,prior)
	await click(shell.phone_world_return);exclusive("world");disk_mode("rpg")
	await reload_primary("world",actor,prior)
	state.new_game();await frames(6);exclusive("phone")
	check(state.d.native.page=="alarm" and not shell.phone_world_return.visible,"new game returns to authored alarm")
	await close_shell()
func run() -> void:
	if not load("res://tests/native_test_isolation.gd").is_isolated_save():
		push_error("Surface persistence requires an isolated native test profile");quit(2);return
	state=root.get_node("State")
	for view:Vector2i in [Vector2i(1440,900),Vector2i(1280,720),Vector2i(390,844),Vector2i(430,860)]:
		await verify_viewport(view)
	print("NATIVE_SURFACE_SAVE: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
