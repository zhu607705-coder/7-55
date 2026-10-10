extends SceneTree
const Preview=preload("res://tests/preview_theater.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func _initialize()->void:run.call_deferred()
func run()->void:
	root.size=Vector2i(1152,648)
	var proof:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/spotlight_manual_excerpt.json"))
	var preview:=Preview.new();root.add_child(preview);preview.set_process(false);preview.round_id=2;preview._new_act();preview.game.set_process(false);preview.game._primary()
	for tick in int(proof.startTick):preview._review_step(proof,.05)
	check(preview.game.state.collected.is_empty(),"excerpt begins before the demonstrated pair")
	var snapshot:Dictionary=preview.game.state.duplicate(true);preview.game._pause();preview.game._process(4.0)
	check(preview.game.state==snapshot,"pause freezes all history and charge ticks")
	preview.game._primary()
	var seen_pair:=false
	check(not preview.show_review_cursor,"demonstration cursor defaults off outside capture")
	var destination_ahead:=false
	for frame in roundi(float(proof.durationTicks)*1.5):
		var prior_tick:int=preview.game.state.tick
		preview._review_step(proof,0.0 if frame%3==0 else .05)
		if proof.has("pointer_visuals") and prior_tick<proof.inputs.size():
			var visual:Dictionary=proof.pointer_visuals[prior_tick]
			check(preview.game.dragging==visual.held,"held marker follows the captured physical press/release")
			if visual.held:
				check(preview.game.pointer.distance_to(Vector2(visual.x,visual.y))<.001,"shown destination is the recorded pointer, not the next model step")
				if preview.game.pointer.distance_to(preview.game.state.head)>100:destination_ahead=true
		if preview.game.state.collected==[0,2]:seen_pair=true
	if proof.has("pointer_visuals"):check(destination_ahead,"actual distant aiming destination is visible before arrival")
	var state:Dictionary=preview.game.state
	check(state.tick==proof.startTick+proof.durationTicks and state.status=="running","native duration ends at the recorded excerpt tick")
	check(state.collected==[0,2] and seen_pair and state.lives==proof.lives,"physical recording replays one completed pair and preserves real damage")
	check(state.head.distance_to(Vector2(proof.expectedHead.x,proof.expectedHead.y))<.01,"source/native/pointer replay converge at the recorded endpoint")
	check(preview.game.rules.validate(proof,2,0).is_empty(),"partial video input cannot claim a completed attempt")
	preview.queue_free();await process_frame
	print("THEATER_REVIEW_ROUTE: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
