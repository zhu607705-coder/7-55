extends RefCounted
## Short, non-authoritative NPC cues. No nodes, input surfaces, timers or save writes.
## Timing and glint motifs reference patch-gg/pixelfx; see NPC_PIXEL_FEEDBACK.md.

const DURATIONS := {"approach": 0.44, "dialogue": 0.64, "complete": 0.88}
const PRIORITY := {"approach": 0, "dialogue": 1, "complete": 2}
const APPROACH_DWELL := 0.12
const APPROACH_COOLDOWN := 1.8
const MAX_ACTIVE := 3
const MASTER_SIZE := 80.0
const INK := Color("202b35")
const BLUE := Color("7993a1")
const PAPER := Color("e8e0c8")
const MUTED := Color("c5c1a9")

var effects: Array[Dictionary] = []
var clock := 0.0
var context_key := ""
var owner: Dictionary = {}
var focus_id := ""
var focus_age := 0.0
var focus_emitted := false
var last_approach: Dictionary = {}
var completed: Dictionary = {}

func bind(key: String, state: Dictionary) -> void:
	if key == context_key and is_same(owner, state): return
	reset()
	context_key = key
	owner = state

func reset() -> void:
	clear_visuals()
	clock = 0.0
	last_approach.clear()
	completed.clear()
	context_key = ""
	owner = {}

func clear_visuals() -> void:
	effects.clear()
	focus_id = ""
	focus_age = 0.0
	focus_emitted = false

func advance(delta: float, nearby_id: String, allow_approach: bool = true) -> void:
	var dt := maxf(0.0, delta)
	clock += dt
	for effect: Dictionary in effects: effect.age += dt
	effects = effects.filter(func(effect: Dictionary) -> bool: return effect.age < DURATIONS[effect.kind])
	# Expired re-entry records have no visual or gameplay meaning.
	for id: String in last_approach.keys():
		if clock - float(last_approach[id]) > APPROACH_COOLDOWN * 2: last_approach.erase(id)
	if not allow_approach: return
	if nearby_id != focus_id:
		focus_id = nearby_id
		focus_age = 0.0
		focus_emitted = false
	if focus_id.is_empty(): return
	focus_age += dt
	if focus_age < APPROACH_DWELL or focus_emitted: return
	focus_emitted = true
	if clock - float(last_approach.get(focus_id, -APPROACH_COOLDOWN)) < APPROACH_COOLDOWN: return
	if play(focus_id, "approach"): last_approach[focus_id] = clock

func play(id: String, kind: String, receipt: String = "") -> bool:
	if id.is_empty() or not DURATIONS.has(kind): return false
	if kind == "complete" and not receipt.is_empty():
		if completed.has(receipt): return false
		completed[receipt] = true
	for index: int in range(effects.size()):
		var current: Dictionary = effects[index]
		if current.id != id: continue
		if PRIORITY[current.kind] > PRIORITY[kind]: return false
		# Rapid repeats must not restart a cue on every input event.
		if current.kind == kind and float(current.age) < 0.30: return false
		effects.remove_at(index)
		break
	if effects.size() >= MAX_ACTIVE:
		var retire := -1
		for index: int in range(effects.size()):
			if PRIORITY[effects[index].kind] <= PRIORITY[kind]:
				retire = index
				break
		if retire < 0: return false
		effects.remove_at(retire)
	effects.append({"id": id, "kind": kind, "age": 0.0})
	return true

static func frame_for(kind: String, age: float, reduced: bool) -> int:
	if not DURATIONS.has(kind) or age < 0 or age >= DURATIONS[kind]: return -1
	return 3 if reduced else mini(7, int(age / float(DURATIONS[kind]) * 8))

static func _pixel(out: Array[Dictionary], rect: Rect2, color: Color, alpha: float) -> void:
	color.a = alpha
	out.append({"rect": rect, "color": color})

static func _glint(out: Array[Dictionary], at: Vector2, arm: int, alpha: float) -> void:
	# Hard, integer-aligned clusters; no glow, gradients or random speckle.
	_pixel(out, Rect2(at + Vector2(-2, -arm), Vector2(4, arm * 2)), INK, alpha)
	_pixel(out, Rect2(at + Vector2(-arm, -2), Vector2(arm * 2, 4)), INK, alpha)
	_pixel(out, Rect2(at + Vector2(-1, -arm + 1), Vector2(2, maxi(2, arm * 2 - 2))), PAPER, alpha)
	_pixel(out, Rect2(at + Vector2(-arm + 1, -1), Vector2(maxi(2, arm * 2 - 2), 2)), BLUE, alpha)

static func pixels(kind: String, frame: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if frame < 0 or frame > 7: return out
	var alpha := 1.0 if frame < 5 else 2.0 / 3.0 if frame < 7 else 1.0 / 3.0
	if kind == "approach":
		var spread: int = [7, 10, 13, 14, 14, 14, 14, 14][frame]
		_glint(out, Vector2(-spread, 0), 4 if frame < 6 else 3, alpha)
		_glint(out, Vector2(spread, -4), 3, alpha)
	elif kind == "dialogue":
		for index: int in range(3):
			if frame < index: continue
			var lift := -3 if frame == index + 1 or frame == index + 2 else 0
			var at := Vector2(-17 + index * 14, lift)
			_pixel(out, Rect2(at + Vector2(-1, -1), Vector2(10, 10)), INK, alpha)
			_pixel(out, Rect2(at, Vector2(8, 8)), PAPER if index == mini(frame, 2) else MUTED, alpha)
	elif kind == "complete":
		var spread: int = [5, 11, 18, 23, 26, 23, 18, 12][frame]
		for index: int in range(4):
			var direction := Vector2([-1, 1, -0.55, 0.55][index], [-0.2, -0.2, 0.8, -0.9][index])
			var arm := 6 if frame in [2, 3, 4] else 4 if frame < 6 else 3
			_glint(out, (direction * spread).round(), arm, alpha)
	return out

static func placement(actor: Rect2, origin: Vector2, zoom: float, safe: Rect2, excluded: Array[Rect2] = []) -> Dictionary:
	if not actor.has_area() or zoom <= 0 or not safe.has_area(): return {}
	var scale_value := 0.4 * zoom
	var extent := Vector2.ONE * MASTER_SIZE * scale_value
	var centers: Array[Vector2] = [
		Vector2(actor.get_center().x, actor.position.y - 20),
		Vector2(actor.end.x + 20, actor.position.y + 16),
		Vector2(actor.position.x - 20, actor.position.y + 16)
	]
	for anchor: Vector2 in centers:
		var center := (origin + anchor * zoom).round()
		var bounds := Rect2(center - extent / 2, extent).grow(1)
		if not safe.encloses(bounds): continue
		var covered := false
		for region: Rect2 in excluded:
			if bounds.intersects(region): covered = true; break
		if not covered: return {"center": center, "scale": scale_value, "bounds": bounds}
	return {}

static func draw_effect(canvas: CanvasItem, kind: String, age: float, reduced: bool, layout: Dictionary) -> void:
	if layout.is_empty(): return
	for pixel: Dictionary in pixels(kind, frame_for(kind, age, reduced)):
		var rect: Rect2 = pixel.rect
		var at: Vector2 = (layout.center + rect.position * float(layout.scale)).round()
		var extent: Vector2 = (rect.size * float(layout.scale)).ceil().max(Vector2.ONE)
		canvas.draw_rect(Rect2(at, extent), pixel.color)
