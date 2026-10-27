extends RefCounted
## Runtime-only support-NPC gestures. Uses authored whole poses and a fixed foot pivot.
## No movement, collision, dialogue, inventory or story authority lives here.

var responses: Dictionary = {}
var attention: Dictionary = {}

func reset() -> void:
	responses.clear()
	attention.clear()

func respond(id: String, now_ms: float, duration_ms: float) -> void:
	responses[id] = {"start": now_ms, "duration": clampf(duration_ms, 1800.0, 6200.0)}

func sample(id: String, now_ms: float, nearby: bool, reduced_motion: bool) -> Dictionary:
	if nearby:
		if not attention.has(id): attention[id] = now_ms
	else:
		attention.erase(id)
	var phase := "attention" if nearby else "idle"
	var frame := 1 if nearby else 0
	var angle := 0.0
	# An occasional page/watch check replaces mechanical continuous frame flicker.
	var idle_time := fposmod(now_ms + float(id.hash() % 1200), 4600.0)
	if not nearby and idle_time > 4120.0: frame = 1
	if nearby and not reduced_motion:
		var greeting := (now_ms - float(attention[id])) / 340.0
		if greeting < 1.0: angle = sin(clampf(greeting, 0.0, 1.0) * PI) * 1.4
	if responses.has(id):
		var response: Dictionary = responses[id]
		var elapsed := maxf(0.0, now_ms - float(response.start))
		var duration := float(response.duration)
		if elapsed >= duration:
			responses.erase(id)
		else:
			phase = "settling" if elapsed >= duration - 320.0 else "speaking"
			frame = 0 if phase == "settling" else 1 if fposmod(elapsed, 1050.0) < 720.0 else 0
			var beat := fposmod(elapsed, 1050.0)
			angle = sin(beat / 360.0 * PI) * 2.0 if beat < 360.0 and phase == "speaking" else 0.0
	if reduced_motion:
		frame = 0
		angle = 0.0
	return {"phase": phase, "frame": frame, "angle_degrees": angle}
