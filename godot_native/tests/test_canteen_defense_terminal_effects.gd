extends SceneTree
const Game=preload("res://scripts/games/canteen_defense.gd")
const Model=preload("res://scripts/games/canteen_defense_model.gd")
var checks:=0
var failures:=0
var completions: Array=[]
func check(ok: bool,label: String)->void:
	checks+=1
	if not ok: failures+=1;push_error(label)
func proof(run: RefCounted)->String:
	return JSON.stringify([run.result(),run.rng_s0,run.rng_s1,run.rng_s2,run.paper_frame,run.paper_frame_ms,run.route_flash,run.paper_hit_cooldown])
func _initialize()->void:
	for reduced: bool in [false,true]:
		# Exercise the actual host without its unrelated asset-loading _ready.
		var game:=Game.new()
		game.start_button=Button.new()
		game.model=Model.new();game.model.configure("terminal-paper-contact")
		game.config={"session_id":"terminal-effect-test","reduced_motion":reduced}
		game.running=true
		game.defense_effects.reset(reduced)
		game.finished.connect(func(result: Dictionary):completions.append(result))
		var run: RefCounted=game.model
		run.tick=3599;run.elapsed_ms=3599*1000.0/60
		run.paper=Vector2(750,520);run.player=run.paper-Model.BODY_CENTER
		run.route.assign([run.paper+Vector2(100,0)]);run.route_index=0;run.paper_hit_cooldown=0
		game._process(Model.DT)
		check(run.status=="won" and run.tick==3600 and run.turnarounds==1 and game.sent,"real terminal step can contact before accepting victory")
		var accepted:=proof(run)
		var contact: Dictionary=game.defense_effects.snapshot()
		check(contact.points.size()>1 and contact.points[0]==run.paper and is_equal_approx(contact.alpha,.95),"terminal contact is retained for its first draw")
		game._process(.025)
		var aged: Dictionary=game.defense_effects.snapshot()
		check(aged.points==contact.points and aged.alpha<contact.alpha and aged.alpha>0,"victory hold advances frozen-route fade")
		check(proof(run)==accepted,"victory fade cannot mutate accepted proof or RNG")
		# Focus loss enters the existing pause path even in the terminal hold.
		game._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
		var wait_before: float=game.finish_wait
		var effects_before: Dictionary=game.defense_effects.snapshot()
		var age_before: float=game.defense_effects.shake_age_ms
		game._process(2)
		check(game.paused and game.finish_wait==wait_before and game.sent,"focus pause freezes victory hold instead of completing offscreen")
		check(game.defense_effects.snapshot()==effects_before and game.defense_effects.shake_age_ms==age_before,"pause freezes terminal flash and shake")
		check(proof(run)==accepted,"terminal pause leaves proof and RNG intact")
		game.begin()
		check(not game.paused and game.sent,"existing resume returns to terminal hold")
		game._process(.05)
		check(game.defense_effects.camera_offset(Vector2(960,540),1)==Vector2.ZERO,"terminal shake expires at75ms or stays disabled in reduced motion")
		while game.defense_effects.age_ms<game.defense_effects.duration_ms:
			game._process(.01)
		check(game.defense_effects.snapshot().points.is_empty() and game.sent,"source flash expiry clears path before existing850ms handoff")
		while game.sent: game._process(.01)
		check(completions.size()==(2 if reduced else 1) and completions[-1].success,"existing completion emits once after unpaused hold")
		check(proof(run)==accepted,"entire terminal presentation leaves accepted proof/RNG unchanged")
		game.start_button.free();game.free()
	print("CANTEEN_DEFENSE_TERMINAL_EFFECTS ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
