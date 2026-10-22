extends "res://tests/test_mobile_bike_chase.gd"
## Automated source-phase fixture; Main routes actual root controls to AudioDirector.
## This does not claim a manual earned Pause -> Exit capture.
func chase_pending(director: Node) -> bool:
	return director.scheduled.any(func(entry):return str(entry.id).begins_with("canteen_chase_") or str(entry.id).begins_with("native_chase_"))

func chase_effects(director: Node) -> bool:
	return director.effects.any(func(entry):return str(entry.id).begins_with("canteen_chase_") or str(entry.id).begins_with("native_chase_"))

func run() -> void:
	state=root.get_node("State");state.developer_mode=true;state.d=state.initial()
	state.d.native.chapter=3;state.d.native.page="phone_home";state.d.native.scene="campus_bootstrap"
	shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames()
	shell.set_process(false);shell.world.set_process(false)
	var game: Control=await open_chase(Vector2i(430,860))
	var director: Node=shell.audio_director
	for cycle: int in range(2):
		await tap(game.start_button)
		while game.model.collisions==0:game._process(.1)
		await frames(2)
		var old_music: AudioStreamPlayer=director.music
		var old_id: int=old_music.get_instance_id()
		check(chase_effects(director),"source collision has real effect owners before Pause/Exit")
		await tap(game.pause_button)
		check(game.paused and old_music.stream_paused and director._paused_prefixes.has("canteen_chase_"),"root Pause acquires the broad source chase audio owner")
		await tap(game.exit_button)
		check(not is_instance_valid(shell.active_game),"root Exit removes the active chase")
		check(not director._paused_prefixes.has("canteen_chase_") and not director._paused_prefixes.has("native_chase_"),"Exit clears both activity pause keys")
		check(not chase_effects(director) and not chase_pending(director),"Exit retires old effects and scheduled chase cues")
		check(not is_instance_valid(old_music) or not old_music.playing,"Exit retires old paused music")
		# Open Tasks through the visible exploration control, then use its Return.
		await click(shell.world_tasks)
		await click(shell.find_child("JournalResume",true,false));await frames(4)
		check(is_instance_valid(shell.active_game),"actual Tasks Return admits a fresh chase owner")
		game=shell.active_game;game.set_process(false)
		check(is_instance_valid(director.music) and director.music.get_instance_id()!=old_id and director.music.playing and not director.music.stream_paused,"Tasks Return starts a fresh unpaused music owner")
		check(not chase_pending(director),"new started cue is consumed instead of blocked by stale pause")
		if not is_instance_valid(director.music):break
	# Reentry still keeps the independent paused Retry contract intact.
	if is_instance_valid(director.music):
		await tap(game.start_button)
		while game.model.collisions==0:game._process(.1)
		await frames(2);await tap(game.pause_button)
		var same_music: AudioStreamPlayer=director.music
		var same_stream: AudioStream=same_music.stream
		await tap(game.retry_button)
		check(not game.running and not game.paused and game.model.tick==0,"paused Retry returns to ready")
		check(not chase_effects(director),"Retry retires old collision effects before resume")
		await tap(game.start_button)
		check(director.music==same_music and same_music.stream==same_stream and same_music.playing and not same_music.stream_paused,"Retry/Start preserves and resumes the same music owner")
		await tap(game.pause_button)
		await tap(game.start_button)
		check(director.music==same_music and not same_music.stream_paused,"ordinary Pause/Continue still resumes the same owner")
		await tap(game.exit_button)
	await shell.shutdown();shell.queue_free();await frames()
	print("BIKE_CHASE_AUDIO_EXIT: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
