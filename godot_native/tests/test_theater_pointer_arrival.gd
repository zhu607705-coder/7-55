extends SceneTree
const Game=preload("res://scripts/games/c3_spotlight.gd")
const Model=preload("res://scripts/games/c3_spotlight_model.gd")
var checks:=0
var failures:=0
func check(value:bool,message:String)->void:
	checks+=1
	if not value:failures+=1;push_error(message)
func _initialize()->void:run.call_deferred()
func run()->void:
	root.get_node("State").developer_mode=true
	var game:=Game.new();root.add_child(game);game.set_process(false)
	await process_frame
	for dimensions:Vector2i in [Vector2i(1280,720),Vector2i(1024,768),Vector2i(390,844),Vector2i(844,390)]:
		root.size=dimensions
		var fit:float=minf((dimensions.x-20.0)/960.0,(dimensions.y-20.0)/540.0)
		game.scale=Vector2.ONE*fit
		for act:int in [0,2]:
			for anchor:Vector2 in [Vector2(156,280),Vector2(305,230),Vector2(675,320),Vector2(80,150),Vector2(880,390)]:
				game.setup({"round":act,"attempt":0});game._primary();game.state.head=anchor
				var target:Vector2=anchor+Vector2(4.15,0)
				var press:=InputEventMouseButton.new();press.button_index=MOUSE_BUTTON_LEFT;press.pressed=true;press.position=game.model_to_pointer(target);game._gui_input(press)
				var previous:float=anchor.distance_to(target)
				for tick in 24:
					game._process(.05)
					var remaining:float=game.state.head.distance_to(target)
					check(remaining<=previous+.001,"stationary pointer cannot bounce: %s act%d %s tick%d"%[dimensions,act,anchor,tick])
					previous=remaining
				check(game.state.head.distance_to(target)<.001,"held pointer converges across stretched/compressed/mobile areas")
				var proof:Dictionary={"version":2,"round":act,"attempt":0,"inputs":game.trace}
				check(proof.inputs[0].x<1.0,"final step records analog amplitude rather than a normalized overshoot")
	# Explicit source example from independent review: 156 <-> 164.3 must end at 160.15.
	var rules:=Model.new();var s:Dictionary=rules.create(0);var target:=Vector2(160.15,280)
	for tick in 30:
		var axis:Vector2=rules.pointer_axis(s,target);s=rules.step(s,{"x":axis.x,"y":axis.y,"dash":false})
	check(s.head.distance_to(target)<.001,"reviewer's exact alternating-step example reaches 160.15")
	# Existing dash lasts nine ticks; once its explicit impulse ends, the held aim converges.
	s=rules.create(0)
	for tick in 30:
		var axis:Vector2=rules.pointer_axis(s,target,tick==0);s=rules.step(s,{"x":axis.x,"y":axis.y,"dash":tick==0})
	check(s.head.distance_to(target)<.001 and s.dashTicks==0,"dash completion does not leave a stationary-pointer oscillator")
	game.queue_free();await process_frame
	print("THEATER_POINTER_ARRIVAL: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
