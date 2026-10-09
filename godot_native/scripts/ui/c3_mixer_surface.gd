extends Control
## Input-transparent physical assembly. Clean backdrop, glass, bottles, liquid
## and pouring stream are independent. Only the source controller owns facts.
const Motion = preload("res://scripts/presentation/c3_mixer_motion.gd")
const BACKDROP = preload("res://assets/native/mixer/canteen_tasting_counter_clean_background.png")
var components: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/native/mixer/components.json")).components
var motion: Node2D
var bottles: Array[Sprite2D] = []
var board := Rect2()
var cup_foot := Vector2.ZERO
var bottle_feet: Array[Vector2] = []
var bottle_height: float = 100.0
var source_slots: Array = []
var motion_scale: float = 1.0
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for index in range(3):
		var sprite := Sprite2D.new()
		sprite.name = "IngredientBottle"+str(index)
		sprite.centered = false
		sprite.region_enabled = true
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(sprite); bottles.append(sprite)
	motion = Motion.new(); motion.name = "IndependentPourParts"; add_child(motion)
func configure(area: Rect2, contact: Vector2, glass_height: float, contacts: Array[Vector2], ingredient_height: float) -> void:
	board = area; cup_foot = contact; bottle_feet = contacts; bottle_height = ingredient_height
	motion_scale = glass_height / 150.0
	motion.position = cup_foot; motion.scale = Vector2.ONE * motion_scale
	_layout_bottles(); queue_redraw()
func _layout_bottles() -> void:
	for index in range(mini(bottles.size(),source_slots.size())):
		var id: String = str(source_slots[index].id)
		var part: Dictionary = components[id]; var r: Array = part.region
		var sprite: Sprite2D = bottles[index]
		sprite.texture = load(part.path)
		sprite.region_rect = Rect2(r[0],r[1],r[2],r[3])
		var factor: float = bottle_height / float(r[3])
		sprite.scale = Vector2.ONE * factor
		if index < bottle_feet.size(): sprite.position = bottle_feet[index] - Vector2(float(r[2])*factor/2,bottle_height)
func synchronize(model: Dictionary, state: Dictionary) -> void:
	if model.is_empty(): return
	source_slots = model.slots.duplicate(true)
	_layout_bottles()
	motion.set_sequence(state.get("canteenHunt",{}).get("drinkMixSequence",[]))
	motion.reduced = bool(state.get("native",{}).get("settings",{}).get("reduced_motion",false))
	_sync_visibility()
func _set_origin(id: String) -> void:
	for index in range(source_slots.size()):
		if str(source_slots[index].id) != id or index >= bottle_feet.size(): continue
		var part: Dictionary = components[id]
		var cap_ratio: float = float(part.cap_pixels) / float(part.region[3])
		# The active body starts exactly at this bottle's uncapped mouth.
		var mouth: Vector2 = bottle_feet[index] - Vector2(0,bottle_height*(1.0-cap_ratio))
		motion.pour_origin = (mouth-cup_foot)/motion_scale
		return
func accept(action: String, before: Dictionary, next: Dictionary, result: Dictionary) -> void:
	_set_origin(action.trim_prefix("c3_mix:"))
	motion.accept(action,before,next,result)
	_sync_visibility()
func reject(id: String, reduced: bool) -> void:
	_set_origin(id); motion.reject(id,reduced); _sync_visibility()
func _sync_visibility() -> void:
	for index in range(mini(bottles.size(),source_slots.size())):
		var slot: Dictionary = source_slots[index]
		bottles[index].visible = not (motion.playing and str(slot.id)==motion.item_id)
		bottles[index].modulate.a = 1.0 if slot.owned else 0.28
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
	for index in range(bottle_feet.size()):
		if index < bottles.size() and bottles[index].visible: _contact(bottle_feet[index],bottle_height*0.18,3.0)
func _contact(at: Vector2, radius: float, depth: float) -> void:
	var points := PackedVector2Array()
	for index in range(12):
		var angle: float = TAU*index/12
		points.append(at+Vector2(cos(angle)*radius,sin(angle)*depth))
	draw_colored_polygon(points,Color(0.09,0.06,0.03,0.16))
