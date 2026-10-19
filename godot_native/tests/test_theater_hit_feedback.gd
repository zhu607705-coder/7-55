extends SceneTree
const Game=preload("res://scripts/games/c3_spotlight.gd")
const Pointer=preload("res://tests/theater_trace_pointer.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func _initialize()->void:run.call_deferred()
func run()->void:
	root.size=Vector2i(1152,648)
	var proof:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/spotlight_manual_excerpt.json"))
	var game:=Game.new();game.setup({"round":2});root.add_child(game);game.set_process(false);game._primary()
	var expected:Dictionary=game.rules.create(2);var injuries:=0
	for input:Dictionary in proof.inputs:
		expected=game.rules.step(expected,input)
		Pointer.feed(game,input);game._process(.05)
		check(game.state.lives==expected.lives and game.state.invulnerable==expected.invulnerable,"feedback does not alter health or protection timers")
		if expected.lastEvent=="hurt":
			injuries+=1
			check(game.hit_count==injuries and game.hit_remaining==.65,"one burst starts per actual model injury")
			check(game.hit_origin.distance_to(game.state.head)<.001 and game.hit_life==game.state.lives,"impact position and lost HUD wick match the resolved injury")
			var snapshot:Dictionary=game.state.duplicate(true);game._process(0);game.refresh();game.refresh()
			check(game.hit_count==injuries and game.state==snapshot,"extra render refreshes cannot repeat damage or the burst")
			game._pause();var remaining:float=game.hit_remaining;game._process(2.0)
			check(game.hit_remaining==remaining and game.state==snapshot,"pause freezes impact animation and model history")
			game._primary()
	check(injuries>0,"fixture contains a real enemy contact")
	for banned:String in ["3秒前","三秒前","一端留光","暖光本人"]:
		check(not game.overlay_body.text.contains(banned) and not game.relay_status.text.contains(banned),"removed explanatory labels stay absent")
	for h:Dictionary in game.rules.hazards(game.state):check(h.kind!="shadow","cooperative echo is never a damage hazard")
	game.setup({"round":2,"attempt":1})
	check(game.hit_remaining==0 and game.hit_count==0 and game.hit_life==-1,"retry/reuse clears all transient feedback")
	check(game.state.lives==3 and game.state.history.size()==1,"feedback reset does not fabricate progress")
	game.queue_free();await process_frame
	print("THEATER_HIT_FEEDBACK: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
