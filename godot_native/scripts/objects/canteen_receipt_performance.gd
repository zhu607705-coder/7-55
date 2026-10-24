extends Node2D
## The point-of-sale terminal observes the original order transaction. Its paper,
## roller and lip are disposable presentation; they never dispatch or save facts.
const SOURCE_DEPTH := 247.0
const TERMINAL_POINT := Vector2(790, 226)
const SLOT_POINT := Vector2(-.5, -3.4)
const PAPER_WIDTH := 6.5
const PAPER_LENGTH := 12.0
const NORMAL_MS := 1080.0
const REDUCED_MS := 180.0
const Metrics = preload("res://scripts/player_metrics.gd")
const INK := Color("202B35")
const PAPER := Color("F4EAD5")
const PAPER_SHADE := Color("D8C7A0")
const METAL_SHADE := Color("344452")
const METAL_MID := Color("526B7A")
const METAL_LIGHT := Color("7993A1")

class PaperPart extends Node2D:
	var length := 0.0
	func _draw() -> void:
		if length <= 0.0: return
		var edge: float = floorf(length * 4.0) / 4.0
		draw_rect(Rect2(-PAPER_WIDTH / 2, 0, PAPER_WIDTH, edge), PAPER)
		draw_rect(Rect2(PAPER_WIDTH / 2 - .5, 0, .5, edge), PAPER_SHADE)
		# Small ink bars are a receipt texture, never a second clue or tiny prose.
		for row in range(5):
			var y: float = 2.0 + row * 1.5
			if y + .5 > edge: break
			draw_rect(Rect2(-2.0, y, 3.75 if row % 2 == 0 else 2.5, .5), INK)
		if edge >= PAPER_LENGTH:
			for x in range(6):
				draw_rect(Rect2(-3.0 + x, edge - .25, .5, .25), PAPER_SHADE)

class RollerPart extends Node2D:
	var phase := 0
	func _draw() -> void:
		draw_rect(Rect2(-4.0, -.5, 8.0, 1.25), INK)
		for i in range(4):
			var x: float = -3.5 + i * 2.0 + phase * .25
			draw_rect(Rect2(x, 0, .75, .25), METAL_MID)

class LipPart extends Node2D:
	func _draw() -> void:
		draw_rect(Rect2(-4.5, -.75, 9.0, .5), METAL_LIGHT)
		draw_rect(Rect2(-4.0, -.25, 8.0, .5), METAL_SHADE)

var world: Control
var state_node: Node
var bound_state: Dictionary = {}
var region_active := false
var last_count := 0
var last_ticket := false
var pending_order := -1
var observed_orders := 0
var playing := false
var elapsed_ms := 0.0
var reduced := false
var hand := Vector2.ZERO
var paper_depth := SOURCE_DEPTH
var paper: PaperPart
var roller: RollerPart
var lip: LipPart

func _ready() -> void:
	name = "CanteenReceiptPrinter"
	position = TERMINAL_POINT
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	z_index = preload("res://scripts/objects/canteen_scene_object.gd").draw_layer(SOURCE_DEPTH)
	set_meta("source_depth", SOURCE_DEPTH)
	paper = PaperPart.new(); paper.name = "ReceiptPaper"; add_child(paper)
	roller = RollerPart.new(); roller.name = "FeedRoller"; add_child(roller)
	lip = LipPart.new(); lip.name = "PrinterLip"; add_child(lip)
	visibility_changed.connect(_on_visibility_changed)
	_pose()

func setup(owner_world: Control) -> void:
	world = owner_world
	# The loose paper changes from machine support to the player's hand plane.
	# Keep the roller/lip at the original terminal depth throughout.
	if is_instance_valid(paper) and paper.get_parent() == self: paper.reparent(get_parent(), false)
	if is_instance_valid(world): bind_state(world.get_node_or_null("/root/State"))

func bind_state(owner_state: Node) -> void:
	_disconnect_state()
	cancel()
	state_node = owner_state
	if is_instance_valid(state_node) and state_node.has_signal("action_completed"):
		state_node.action_completed.connect(_on_action)

func _disconnect_state() -> void:
	if is_instance_valid(state_node) and state_node.has_signal("action_completed") and state_node.action_completed.is_connected(_on_action):
		state_node.action_completed.disconnect(_on_action)

func sync(s: Dictionary, active: bool) -> void:
	var replaced := not is_same(bound_state, s)
	var activated := active and not region_active
	bound_state = s
	region_active = active and str(s.get("native", {}).get("scene", "")) == "canteen_interior"
	var count: int = int(s.get("canteenHunt", {}).get("orderAttemptCount", 0))
	var ticket: bool = bool(s.get("items", {}).get("pickupTicket0755", false))
	if replaced or activated or not region_active:
		cancel()
	elif count == last_count + 1 and not last_ticket and ticket:
		pending_order = count
	elif not ticket:
		pending_order = -1
	last_count = count
	last_ticket = ticket
	if not _context_available(): cancel()

static func accepted_order(action: String, value: Variant, before: Dictionary, next: Dictionary, result: Dictionary) -> bool:
	if action != "c3_order" or str(value) not in ["A", "B", "C", "D", "E"] or not result.get("handled", false): return false
	for snapshot: Dictionary in [before, next]:
		var native: Dictionary = snapshot.get("native", {})
		if native.get("scene") != "canteen_interior" or native.get("mode") != "light": return false
		if not snapshot.get("canteenHunt", {}).get("active", false): return false
	var old: Dictionary = before.get("canteenHunt", {})
	var current: Dictionary = next.get("canteenHunt", {})
	return old.get("phase") == "menu_order" and current.get("phase") == "pickup_search" \
		and int(current.get("orderAttemptCount", 0)) == int(old.get("orderAttemptCount", 0)) + 1 \
		and current.get("orderedMenuOption") == str(value) \
		and not before.get("items", {}).get("pickupTicket0755", false) \
		and next.get("items", {}).get("pickupTicket0755", false)

func _on_action(action: String, before: Dictionary, next: Dictionary, result: Dictionary) -> void:
	if not _context_available() or not is_instance_valid(state_node) or not is_same(bound_state, state_node.get("d")):
		cancel(); return
	sync(bound_state, region_active)
	var option: Variant = next.get("canteenHunt", {}).get("orderedMenuOption")
	if not accepted_order(action, option, before, next, result) or pending_order != int(next.canteenHunt.orderAttemptCount): return
	pending_order = -1
	playing = true
	elapsed_ms = 0.0
	reduced = bool(next.get("native", {}).get("settings", {}).get("reduced_motion", false))
	hand = world.player + Vector2(16, -3) - TERMINAL_POINT
	observed_orders += 1
	_pose()

func _context_available() -> bool:
	if not region_active or not is_instance_valid(world) or not world.is_visible_in_tree() or not is_visible_in_tree(): return false
	if is_instance_valid(state_node) and not is_same(bound_state, state_node.get("d")): return false
	var native: Dictionary = bound_state.get("native", {})
	if native.get("scene") != "canteen_interior" or native.get("mode") != "light": return false
	var host: Variant = world.get("host_node")
	if is_instance_valid(host):
		var frame: Variant = host.get("world_frame")
		if is_instance_valid(frame) and frame is CanvasItem and not frame.is_visible_in_tree(): return false
	return true

static func sample(age_ms: float, reduced_motion: bool = false) -> Dictionary:
	var duration: float = REDUCED_MS if reduced_motion else NORMAL_MS
	var t: float = clampf(age_ms / duration, 0.0, 1.0)
	if reduced_motion:
		return {"progress":t, "length":PAPER_LENGTH if t < 1 else 0.0, "take":0.0, "sway":0.0, "lip":0.0, "roller":0, "phase":"ready" if t < 1 else "settled"}
	var length: float = PAPER_LENGTH * smoothstep(.04, .50, t)
	var take: float = smoothstep(.72, 1.0, t)
	var sway: float = sin(clampf((t - .5) / .22, 0, 1) * TAU) * .5 if t >= .5 and t < .72 else 0.0
	return {"progress":t, "length":length if t < 1 else 0.0, "take":take, "sway":sway,
		"lip":sin(smoothstep(0.0, .08, t) * PI / 2) * (1.0 - smoothstep(.50, .64, t)) * .5,
		"roller":int(t * 48.0) % 4 if t < .5 else 0,
		"phase":"feed" if t < .5 else "ready" if t < .72 else "take" if t < 1 else "settled"}

func advance(delta: float) -> void:
	if not playing: return
	elapsed_ms += maxf(0.0, delta) * 1000.0
	if elapsed_ms >= (REDUCED_MS if reduced else NORMAL_MS): playing = false
	_pose()

func _process(delta: float) -> void:
	if not _context_available(): cancel(); return
	advance(delta)

func _pose() -> void:
	if not is_instance_valid(paper): return
	var pose: Dictionary = sample(elapsed_ms, reduced)
	for part: Node2D in [paper, roller, lip]: part.visible = playing
	paper.length = float(pose.length) if playing else 0.0
	paper.position = TERMINAL_POINT + SLOT_POINT.lerp(hand - Vector2(0, PAPER_LENGTH / 2), float(pose.take)) + Vector2(float(pose.sway), 0)
	paper.rotation = 0.0
	var player: Vector2 = TERMINAL_POINT + hand - Vector2(16, -3)
	paper_depth = lerpf(SOURCE_DEPTH, Metrics.foot_rect(player).end.y + 1.0, smoothstep(0, .6, float(pose.take)))
	paper.z_index = preload("res://scripts/objects/canteen_scene_object.gd").draw_layer(paper_depth)
	roller.position = SLOT_POINT
	roller.phase = int(pose.roller)
	lip.position = SLOT_POINT + Vector2(0, -float(pose.lip))
	for part: Node2D in [paper, roller, lip]: part.queue_redraw()

func draw_order_entries() -> Array:
	return [{"node":self, "depth":SOURCE_DEPTH}, {"node":paper, "depth":paper_depth}]

func paper_surface() -> Dictionary:
	if not is_instance_valid(paper) or not paper.visible or paper.length <= 0: return {}
	return {"depth":paper_depth, "canvas_z":paper.z_index, "root_order":paper.get_index(), "ids":[],
		"geometry":{"rect":Rect2(-PAPER_WIDTH / 2, 0, PAPER_WIDTH, paper.length), "transform":paper.transform}}

func cancel() -> void:
	pending_order = -1
	playing = false
	elapsed_ms = 0.0
	hand = Vector2.ZERO
	_pose()

func _on_visibility_changed() -> void:
	if not is_visible_in_tree(): cancel()

func _exit_tree() -> void:
	cancel()
	_disconnect_state()
	if is_instance_valid(paper) and paper.get_parent() != self: paper.queue_free()
