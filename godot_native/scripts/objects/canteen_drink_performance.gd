extends Node2D
## Passive accepted-action observer. Inventory, picking and progression stay
## entirely with the original controller and the registered machine props.
const ATLAS_PATH := "res://assets/native/canteen_animation/drink_dispense_8f.png"
const CELL := Vector2(128, 128)
const TINTS := {"sparklingWater":Color("8bd4f0"), "lemonTea":Color("f2f0dc"), "blackCoffee":Color("665650")}
const COLUMNS := 4
const FRAME_COUNT := 8
const DRAW_RECT := Rect2(-12, -35, 24, 29)
const SOURCE_DEPTH := 197.0
const NORMAL_MS := 640.0
const REDUCED_MS := 160.0
const MACHINES: Array[Dictionary] = [
	{"target":"drink-machine-sparkling", "item":"sparklingWater", "point":Vector2(1421, 196)},
	{"target":"drink-machine-lemon", "item":"lemonTea", "point":Vector2(1473, 196)},
	{"target":"drink-machine-coffee", "item":"blackCoffee", "point":Vector2(1525, 196)},
]
var world: Control
var state_node: Node
var bound_state: Dictionary = {}
var region_active := false
var slots: Dictionary = {}
var sprites: Dictionary = {}
var observed_accepts := 0
var last_owned: Dictionary = {}
var pending_grants: Dictionary = {}
var atlas: Texture2D

func _init() -> void:
	for spec: Dictionary in MACHINES:
		slots[spec.item] = {"playing":false, "waiting":false, "handoff_modal_id":0, "elapsed_ms":0.0, "reduced":false, "accepts":0}

func _ready() -> void:
	_build()
	visibility_changed.connect(_on_visibility_changed)

func setup(owner_world: Control) -> void:
	world = owner_world
	name = "DrinkDispenserPerformance"
	set_meta("source_depth", SOURCE_DEPTH)
	# Same coarse source-depth bucket as canteen_scene_object.draw_layer.
	z_index = clampi(int(floor(SOURCE_DEPTH / 40.0)) + 1, 1, 50)
	if is_instance_valid(world): _bind_state(world.get_node_or_null("/root/State"))

func _bind_state(owner_state: Node) -> void:
	_disconnect_state()
	cancel()
	state_node = owner_state
	if is_instance_valid(state_node) and state_node.has_signal("action_completed"):
		state_node.action_completed.connect(_on_action)

func _disconnect_state() -> void:
	if is_instance_valid(state_node) and state_node.has_signal("action_completed") and state_node.action_completed.is_connected(_on_action):
		state_node.action_completed.disconnect(_on_action)

func _build() -> void:
	if not sprites.is_empty(): return
	# Missing media stays invisible; it never substitutes a fabricated dispense.
	if ResourceLoader.exists(ATLAS_PATH): atlas = load(ATLAS_PATH)
	for spec: Dictionary in MACHINES:
		var sprite := Sprite2D.new()
		sprite.name = str(spec.target).replace("-", "_") + "_accepted_dispense"
		sprite.texture = atlas
		sprite.modulate = TINTS[spec.item]
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.centered = false
		sprite.region_enabled = true
		var factor: float = minf(DRAW_RECT.size.x / CELL.x, DRAW_RECT.size.y / CELL.y)
		sprite.scale = Vector2.ONE * factor
		sprite.position = spec.point + DRAW_RECT.get_center() - CELL * factor / 2
		sprite.hide()
		add_child(sprite)
		sprites[spec.item] = sprite

func sync(s: Dictionary, active: bool) -> void:
	var replaced := not is_same(bound_state, s)
	var activated := active and not region_active
	bound_state = s
	region_active = active and str(s.get("native", {}).get("scene", "")) == "canteen_interior"
	if replaced or activated or not region_active:
		cancel()
		last_owned.clear()
		for spec: Dictionary in MACHINES:
			last_owned[spec.item] = bool(s.get("items", {}).get(spec.item, false))
		return
	# Remember only this live dictionary's real grant edge. Main defers its
	# changed refresh, so _on_action also samples this before accepting a cue.
	for spec: Dictionary in MACHINES:
		var owned := bool(s.get("items", {}).get(spec.item, false))
		if owned and not bool(last_owned.get(spec.item, owned)):
			pending_grants[spec.item] = true
		elif not owned:
			pending_grants.erase(spec.item)
		last_owned[spec.item] = owned
	if not _context_available():
		cancel()
	elif _shell_blocked():
		_hold_closing_handoff(_closing_drink_item())

static func accepted_item(action: String, before: Dictionary, next: Dictionary, result: Dictionary) -> String:
	if not action.begins_with("c3_drink_take:") or not bool(result.get("handled", false)): return ""
	var target := action.trim_prefix("c3_drink_take:")
	var item := ""
	for spec: Dictionary in MACHINES:
		if target == spec.target:
			item = spec.item
			break
	if item.is_empty(): return ""
	for snapshot: Dictionary in [before, next]:
		var native: Dictionary = snapshot.get("native", {})
		if str(native.get("scene", "")) != "canteen_interior" or str(native.get("mode", "")) != "light": return ""
	if bool(before.get("items", {}).get(item, false)) or not bool(next.get("items", {}).get(item, false)): return ""
	# locked() also says handled=true. Require the controller's accepted cue and
	# its matching item, never a message string or an inferred recipe/outcome.
	for event: Variant in result.get("presentation", []):
		if event is Dictionary and str(event.get("cueId", "")) == "canteen_drink_collected" and str(event.get("payload", {}).get("itemId", "")) == item:
			return item
	return ""

static func duration_ms(reduced: bool) -> float:
	return REDUCED_MS if reduced else NORMAL_MS

static func frame_at(elapsed_ms: float, reduced: bool = false) -> int:
	# Reduced motion has one stable full-bottle pose, with no moving stream.
	if reduced: return 7
	return clampi(int(floor(maxf(0.0, elapsed_ms) / (NORMAL_MS / FRAME_COUNT))), 0, FRAME_COUNT - 1)

static func frame_region(frame: int) -> Rect2:
	var bounded := clampi(frame, 0, FRAME_COUNT - 1)
	return Rect2(Vector2(bounded % COLUMNS, floori(float(bounded) / COLUMNS)) * CELL, CELL)

func _on_action(action: String, before: Dictionary, next: Dictionary, result: Dictionary) -> void:
	if not _context_available():
		cancel()
		return
	if not is_instance_valid(state_node) or not is_same(bound_state, state_node.get("d")):
		cancel()
		return
	# State.act emits action_completed synchronously, while Main's changed
	# handler merely schedules _refresh. Do not wait for a render/process pass
	# to discover the grant, and never rebind a replacement save here.
	sync(bound_state, region_active)
	var item := accepted_item(action, before, next, result)
	if item.is_empty() or not bool(pending_grants.get(item, false)): return
	if not bool(bound_state.get("items", {}).get(item, false)): return
	var waiting := _shell_blocked()
	if waiting and _closing_drink_item() != item:
		cancel()
		return
	pending_grants.erase(item)
	var slot: Dictionary = slots[item]
	# A hidden inactive compatibility panel can emit closed on a deferred call.
	# Keep its fact pending; the active closeup panel owns its own visual tail.
	slot.playing = not waiting
	slot.waiting = waiting
	slot.handoff_modal_id = world.host_node.modal.get_instance_id() if waiting else 0
	slot.elapsed_ms = 0.0
	slot.reduced = bool(next.get("native", {}).get("settings", {}).get("reduced_motion", false))
	slot.accepts = int(slot.accepts) + 1
	observed_accepts += 1
	_pose()

func _context_available() -> bool:
	if not region_active or not is_instance_valid(world) or not world.is_visible_in_tree() or not is_visible_in_tree(): return false
	if is_instance_valid(state_node) and not is_same(bound_state, state_node.get("d")): return false
	if str(bound_state.get("native", {}).get("scene", "")) != "canteen_interior" or str(bound_state.get("native", {}).get("mode", "")) != "light": return false
	var host: Variant = world.get("host_node")
	if is_instance_valid(host):
		var frame: Variant = host.get("world_frame")
		if is_instance_valid(frame) and frame is CanvasItem and not frame.is_visible_in_tree(): return false
	return true

func _shell_blocked() -> bool:
	return is_instance_valid(world) and world.has_method("_shell_input_blocked") and bool(world._shell_input_blocked())

func _closing_drink_item() -> String:
	if not _context_available(): return ""
	var host: Variant = world.get("host_node")
	if not is_instance_valid(host): return ""
	var panel: Variant = host.get("c3_device_panel")
	var modal: Variant = host.get("modal")
	if not is_instance_valid(panel) or not is_instance_valid(modal): return ""
	if not panel is Control or not modal is Node or not modal.is_ancestor_of(panel): return ""
	if bool(panel.get("active")) or panel.visible or str(panel.get("kind")) != "drink": return ""
	if not is_same(panel.get("bound_state"), bound_state): return ""
	if is_instance_valid(host.get("active_game")) or is_instance_valid(host.get("phone_document")) or bool(bound_state.get("ui", {}).get("controlCenterOpen", false)): return ""
	for spec: Dictionary in MACHINES:
		if str(panel.get("target_id")) == spec.target and str(panel.get("item_id")) == spec.item:
			return spec.item
	return ""

func _hold_closing_handoff(item: String) -> void:
	if item.is_empty():
		cancel()
		return
	for key: String in pending_grants.keys():
		if key != item: pending_grants.erase(key)
	for key: String in slots:
		var slot: Dictionary = slots[key]
		if key != item or not bool(slot.waiting) or int(slot.handoff_modal_id) != world.host_node.modal.get_instance_id():
			slot.playing = false
			slot.waiting = false
			slot.handoff_modal_id = 0
			slot.elapsed_ms = 0.0
	_pose()

func cancel() -> void:
	pending_grants.clear()
	for slot: Dictionary in slots.values():
		slot.playing = false
		slot.waiting = false
		slot.handoff_modal_id = 0
		slot.elapsed_ms = 0.0
	for sprite: Sprite2D in sprites.values(): sprite.hide()

func _process(delta: float) -> void:
	if not _context_available():
		cancel()
		return
	if _shell_blocked():
		_hold_closing_handoff(_closing_drink_item())
		return
	for item: String in slots:
		var slot: Dictionary = slots[item]
		if not bool(slot.waiting): continue
		slot.waiting = false
		slot.handoff_modal_id = 0
		slot.playing = bool(bound_state.get("items", {}).get(item, false)) and str(bound_state.get("native", {}).get("mode", "")) == "light"
		slot.elapsed_ms = 0.0
	advance(delta)

func advance(delta: float) -> void:
	for slot: Dictionary in slots.values():
		if not slot.playing: continue
		slot.elapsed_ms = minf(duration_ms(slot.reduced), float(slot.elapsed_ms) + maxf(0.0, delta) * 1000.0)
		if float(slot.elapsed_ms) >= duration_ms(slot.reduced): slot.playing = false
	_pose()

func _pose() -> void:
	for item: String in sprites:
		var sprite: Sprite2D = sprites[item]
		var slot: Dictionary = slots[item]
		sprite.visible = bool(slot.playing) and sprite.texture != null
		sprite.region_rect = frame_region(frame_at(float(slot.elapsed_ms), bool(slot.reduced)))

func _on_visibility_changed() -> void:
	if not is_visible_in_tree(): cancel()

func _exit_tree() -> void:
	cancel()
	_disconnect_state()
