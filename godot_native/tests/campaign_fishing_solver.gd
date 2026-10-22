extends RefCounted
## Input-only chart follower; never writes campaign state or proof outcomes.
const Fishing=preload("res://scripts/games/rhythm_fishing_model.gd")
func solve_fishing(id: String) -> RefCounted:
	var fish: RefCounted=Fishing.new()
	fish.configure(id,Fishing.load_chart(id))
	fish.press("right")
	var cast_started: bool=false
	for i: int in range(16000):
		if fish.phase in ["completed","failed"]: break
		fish.update(1.0/120.0)
		var difference: float=fish.fish_x()-fish.line_x
		if difference>0.018:
			fish.release("left")
			fish.press("right")
		elif difference< -0.018:
			fish.release("right")
			fish.press("left")
		else:
			fish.release("right")
			fish.release("left")
		if fish.stage=="casting":
			if fish.aligned() and not cast_started:
				fish.press("hook")
				cast_started=true
			elif fish.held_at>=0 and fish.elapsed-fish.held_at>=0.6: fish.release("hook")
		elif fish.stage=="fighting":
			var note: Dictionary=fish.current_note()
			if note.is_empty(): continue
			var until: float=float(note.timeSec)-fish.elapsed
			if until<=0:
				fish.release("hook")
			elif int(fish.rhythm_position(fish.elapsed).x) in [0,2]: fish.press("hook")
			else: fish.release("hook")
	return fish
