extends SceneTree
const Model=preload("res://scripts/games/c3_spotlight_model.gd")
var failures:=0
var checks:=0
func check(value: bool,message: String) -> void:
	checks+=1
	if not value: failures+=1; push_error("TEST FAILED: "+message)
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	root.size=Vector2i(1440,900)
	await process_frame
	var state=root.get_node("State"); state.developer_mode=true; state.d=state.initial(); state.d.native.chapter=3; state.d.native.scene="theater_interior"; state.d.native.page="c3_theater"
	state.d.runtimeMode="rpg"; state.d.rpgScene="theater_interior"; state.d.theaterHunt.active=true; state.d.theaterHunt.phase="spotlight_hunt"
	var shell=load("res://scenes/main.tscn").instantiate(); root.add_child(shell); await process_frame
	state.act("c3_spotlight")
	for round_id in 3:
		var game: Control=shell.active_game
		check(game!=null and game.state.round==round_id and game.screen=="intro","source intro appears for actual act "+str(round_id))
		game.set_process(false)
		check(str(round_id+1) in game.badge.text,"source act badge refreshes after setup")
		check(game.overlay_title.get_theme_color("font_color").get_luminance()>.4,"dark stage subtitle remains readable")
		game.start_button.pressed.emit()
		check(game.screen=="running" and not game.start_button.visible,"actual primary button starts act")
		game.pause_button.pressed.emit(); var paused_tick: int=game.state.tick; game._process(.1)
		check(game.screen=="paused" and game.state.tick==paused_tick,"pause halts model")
		game.start_button.pressed.emit()
		var rules:=Model.new()
		var loops:=0
		while game.state.status=="running" and loops<1601:
			loops+=1
			var s: Dictionary=game.state; var aim: Vector2=rules.mouth(s); var closest:=INF
			for i in int(Model.ACTS[round_id].count):
				if not s.collected.has(i) and s.head.distance_to(Model.FOOD[i])<closest: closest=s.head.distance_to(Model.FOOD[i]); aim=Model.FOOD[i]
			var direction: Vector2=(aim-s.head).normalized()
			for hazard: Dictionary in rules.hazards(s):
				if s.head.distance_to(hazard.position)<100 and s.invulnerable==0:
					if s.dashCooldown<=1: game.dash_button.pressed.emit()
					elif s.dashTicks==0 and s.head.distance_to(hazard.position)<65: direction=(direction+(s.head-hazard.position).normalized()*1.6).normalized()
			var event: InputEventMouse=InputEventMouseMotion.new()
			event.button_mask=MOUSE_BUTTON_MASK_LEFT
			if not game.dragging:
				var press:=InputEventMouseButton.new();press.button_index=MOUSE_BUTTON_LEFT;press.pressed=true;event=press
			event.position=game.model_to_pointer(s.head+direction*35)
			game._gui_input(event); game._process(.05)
		check(game.state.status=="won","actual native pointer/queued dash flow completes act "+str(round_id))
		check(state.d.theaterHunt.spotlightRound==round_id+1,"submitted actual trace advances controller before result screen")
		check(game.screen=="result" and game.approved and game.start_button.visible,"approved source result retained for user acknowledgement")
		check(game.start_button.text==("拉开最后的幕布" if round_id==2 else "下一幕"),"source result continuation copy")
		if round_id<2:
			game.start_button.pressed.emit(); await process_frame
			check(shell.active_game!=game,"continuation creates next real act")
		else:
			check(state.d.theaterHunt.phase=="reversal" and not state.d.theaterHunt.decoyRevealed,"final result waits before reversal handoff")
	await shell.shutdown(); shell.queue_free(); await process_frame
	print("Theater source UI: ",checks," checks, ",failures," failures")
	quit(0 if failures==0 else 1)
