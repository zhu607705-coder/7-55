extends Control
## Input-transparent machine assembly. Backdrop, flavor controls, nozzle, glass,
## liquid and drip are independent. Only the source controller owns facts.
const Press = preload("res://scripts/presentation/drink_machine_press.gd")
const MACHINE = preload("res://assets/native/canteen_objects/canteen_drink_dispenser.png")
const Motion = preload("res://scripts/presentation/c3_mixer_motion.gd")
const BACKDROP = preload("res://assets/native/mixer/canteen_tasting_counter_clean_background.png")
var components: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/native/mixer/components.json")).components
var motion: Node2D
var press_buttons: Array[Sprite2D] = []
# Historical fixture alias; these are now machine buttons, never bottle artwork.
var bottles: Array[Sprite2D] = []
var board := Rect2()
var machine_bounds := Rect2()
var cup_foot := Vector2.ZERO
var bottle_feet: Array[Vector2] = []
var bottle_height: float = 100.0
var source_slots: Array = []
var motion_scale: float = 1.0
var pending_pours: Array[Dictionary] = []
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	motion = Motion.new(); motion.name = "IndependentMachineParts"; add_child(motion)
	press_buttons.assign(motion.rig.selectors);bottles.assign(press_buttons)
	motion.hold_terminal_result=true
	motion.presentation_finished.connect(_play_next_pour)
func configure(area: Rect2, contact: Vector2, glass_height: float, contacts: Array[Vector2], ingredient_height: float) -> void:
	board = area; cup_foot = contact; bottle_feet = contacts; bottle_height = ingredient_height
	motion_scale = glass_height / 150.0
	machine_bounds=Rect2(cup_foot+Motion.Rig.BOUNDS.position*motion_scale,Motion.Rig.BOUNDS.size*motion_scale)
	motion.position = cup_foot; motion.scale = Vector2.ONE * motion_scale
	_layout_bottles(); queue_redraw()
func _layout_bottles() -> void:
	motion.slot_ids=source_slots.map(func(slot):return str(slot.id))
	for index in range(mini(press_buttons.size(),source_slots.size())):
		var value:int=Motion.Source.COLORS[str(source_slots[index].id)]
		motion.rig.set_color(index,Color((value>>16&255)/255.0,(value>>8&255)/255.0,(value&255)/255.0))
func synchronize(model: Dictionary, state: Dictionary) -> void:
	if model.is_empty(): return
	source_slots = model.slots.duplicate(true)
	_layout_bottles()
	if not motion.playing and pending_pours.is_empty():
		motion.set_sequence(state.get("canteenHunt",{}).get("drinkMixSequence",[]))
	motion.reduced = bool(state.get("native",{}).get("settings",{}).get("reduced_motion",false))
	_sync_visibility()
func _set_origin(_id: String) -> void:
	# The machine's outlet is fixed; selecting a color never moves a bottle.
	pass
func accept(action: String, before: Dictionary, next: Dictionary, result: Dictionary) -> void:
	# Commit happened in State.act. Queue only its observed presentations so rapid
	# input never cuts an earlier cup cycle off or delays controller transactions.
	pending_pours.append({"action":action,"before":before.duplicate(true),"next":next.duplicate(true),"result":result.duplicate(true)})
	if not motion.playing: _play_next_pour()
	else: motion.stage_next_cup()
func _play_next_pour() -> void:
	while not pending_pours.is_empty():
		var pour: Dictionary=pending_pours.pop_front()
		_set_origin(str(pour.action).trim_prefix("c3_mix:"))
		if motion.accept(pour.action,pour.before,pour.next,pour.result):
			if not pending_pours.is_empty():motion.stage_next_cup()
			break
	_sync_visibility()
func is_pouring() -> bool:
	return motion.playing or not pending_pours.is_empty()
func cancel_presentation() -> void:
	pending_pours.clear()
	motion.reset()
func reject(id: String, reduced: bool) -> void:
	# Missing repeated clicks keep source feedback but cannot interrupt a pour.
	if is_pouring(): return
	_set_origin(id); motion.reject(id,reduced); _sync_visibility()
func _sync_visibility() -> void:
	for index in range(mini(press_buttons.size(),source_slots.size())):
		var slot: Dictionary = source_slots[index]
		var selected: bool = motion.playing and not motion.denied and str(slot.id)==motion.item_id
		press_buttons[index].visible = true
		press_buttons[index].modulate.a = 1.0 if slot.owned or selected else 0.28
	queue_redraw()
func _process(_delta: float) -> void:
	_sync_visibility()
func _draw() -> void:
	if board.size.x <= 0: return
	# Cover using a source region, not anisotropic image stretching. The empty
	# wooden worktop stays still; no cup, bottle, liquid or contact is baked in.
	var source_size := Vector2(BACKDROP.get_size())
	var zoom: float = maxf(board.size.x/source_size.x,board.size.y/source_size.y)
	var source_extent: Vector2 = board.size/zoom
	var source_rect := Rect2((source_size-source_extent)/2,source_extent)
	draw_texture_rect_region(BACKDROP,board,source_rect)
	# The three-outlet fixed body is owned by the independent rig child.
