extends RefCounted
## QA-only translation of a validated model trace into real pointer/dash events.
static func feed(game:Control,input:Dictionary)->void:
	var state:Dictionary=game.state;var next_dash:int=maxi(0,state.dashTicks-1)
	if input.dash and not state.dashHeld and state.dashCooldown<=1:next_dash=9
	var step_distance:float=16.5 if next_dash>0 else 8.3
	var drift:=Vector2.ZERO
	if state.round==2 and next_dash==0:drift=Vector2(cos((state.tick+1)*.019)*.7,sin((state.tick+1)*.028)*1.5)
	var target:Vector2=state.head+Vector2(input.x,input.y)*step_distance+drift
	game.queued_dash=bool(input.dash)
	if not game.dragging:
		var press:=InputEventMouseButton.new();press.button_index=MOUSE_BUTTON_LEFT;press.pressed=true;press.position=game.model_to_pointer(target);game._gui_input(press)
	else:
		var motion:=InputEventMouseMotion.new();motion.button_mask=MOUSE_BUTTON_MASK_LEFT;motion.position=game.model_to_pointer(target);game._gui_input(motion)
