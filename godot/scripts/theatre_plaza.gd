extends Node2D

## A deliberately small, code-drawn first scene.
## All coordinates are in the native 640 x 360 pixel game space.

const VIEWPORT_SIZE := Vector2(640, 360)
const PLAYER_SPEED := 92.0
const PLAYER_HALF_SIZE := Vector2(6, 8)
const WALKABLE_AREA := Rect2(22, 93, 596, 245)

var player_position := Vector2(320, 274)
var player_direction := Vector2.DOWN

# The facade, steps and planters are solid. Keep these rectangles in the same
# coordinate space as _draw() so adjusting the visual layout is predictable.
var solid_areas: Array[Rect2] = [
	Rect2(152, 47, 336, 84),
	Rect2(240, 130, 160, 23),
	Rect2(52, 156, 78, 40),
	Rect2(510, 156, 78, 40),
]


func _ready() -> void:
	queue_redraw()


func _process(delta: float) -> void:
	var direction := Vector2(
		int(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) - int(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)),
		int(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)) - int(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))
	)

	if direction.length_squared() > 0.0:
		direction = direction.normalized()
		player_direction = direction
		try_move(direction * PLAYER_SPEED * delta)

	if Input.is_key_pressed(KEY_R):
		player_position = Vector2(320, 274)

	queue_redraw()


func try_move(motion: Vector2) -> void:
	# Slide separately on x and y. This makes the player naturally move along a
	# planter or the theatre steps instead of stopping against its corner.
	var x_candidate := player_position + Vector2(motion.x, 0)
	if not collides(x_candidate):
		player_position = x_candidate
	var y_candidate := player_position + Vector2(0, motion.y)
	if not collides(y_candidate):
		player_position = y_candidate


func collides(candidate: Vector2) -> bool:
	var player_rect := Rect2(candidate - PLAYER_HALF_SIZE, PLAYER_HALF_SIZE * 2.0)
	if not WALKABLE_AREA.encloses(player_rect):
		return true
	for solid_area in solid_areas:
		if player_rect.intersects(solid_area):
			return true
	return false


func _draw() -> void:
	draw_environment()
	draw_theatre()
	draw_plaza_objects()
	draw_player()


func draw_environment() -> void:
	# Lawn and the broad warm-grey paved plaza.
	draw_rect(Rect2(Vector2.ZERO, VIEWPORT_SIZE), Color("78a66d"))
	draw_rect(Rect2(22, 94, 596, 244), Color("d6cbb5"))
	draw_rect(Rect2(29, 101, 582, 230), Color("e5dcc7"))

	# Pixel clusters give otherwise flat pavement a tile-like surface.
	for y in range(108, 325, 18):
		var row_offset := (int(y / 18) % 2) * 8
		for x in range(39 + row_offset, 604, 32):
			draw_rect(Rect2(x, y, 14, 1), Color("c7baa4"))
			draw_rect(Rect2(x + 14, y, 1, 10), Color("c7baa4"))

	# A darker cross-axis hints at campus circulation without needing a tileset.
	draw_rect(Rect2(300, 154, 40, 177), Color("d1c4ae"))
	draw_line(Vector2(300, 154), Vector2(300, 331), Color("b8ab96"), 1)
	draw_line(Vector2(340, 154), Vector2(340, 331), Color("f1ead9"), 1)

	# Lawn edge and intentionally blocky flowers.
	draw_rect(Rect2(0, 88, 640, 6), Color("5d8f5d"))
	for x in range(18, 624, 23):
		draw_rect(Rect2(x, 84 + (x % 3) * 2, 3, 3), Color("f2d36b"))


func draw_theatre() -> void:
	# The building is an original campus-theatre interpretation: pale stone roof,
	# blue glass facade, an entrance canopy, and a generous front stair.
	draw_rect(Rect2(145, 38, 350, 12), Color("e9e3d0"))
	draw_rect(Rect2(152, 47, 336, 84), Color("526f82"))
	draw_rect(Rect2(158, 53, 324, 72), Color("294e66"))
	draw_rect(Rect2(158, 53, 324, 7), Color("8eb3c1"))

	# Repeated glass panels.
	for x in range(166, 477, 26):
		draw_rect(Rect2(x, 62, 18, 57), Color("3e7590"))
		draw_rect(Rect2(x + 2, 64, 4, 49), Color("6fa7b9"))
		draw_rect(Rect2(x + 7, 64, 2, 49), Color("2a5d77"))
		draw_rect(Rect2(x + 14, 64, 2, 49), Color("8fc3ca"))

	# A shadowed central entrance; no real-world lettering or branding.
	draw_rect(Rect2(250, 68, 140, 58), Color("24465a"))
	draw_rect(Rect2(256, 73, 128, 47), Color("183746"))
	for x in range(262, 380, 20):
		draw_rect(Rect2(x, 76, 15, 41), Color("34637a"))
		draw_rect(Rect2(x + 2, 78, 3, 37), Color("7fb0bd"))

	# Stone sign plinth retained as an editable empty panel.
	draw_rect(Rect2(274, 43, 92, 7), Color("d8d2c0"))
	draw_rect(Rect2(289, 45, 62, 2), Color("a9ad9c"))

	# Entrance canopy and stairs. Their collision rectangle is in solid_areas.
	draw_rect(Rect2(232, 123, 176, 8), Color("c9c2b1"))
	draw_rect(Rect2(240, 131, 160, 7), Color("b6ad9e"))
	draw_rect(Rect2(247, 138, 146, 7), Color("d7cdb9"))
	draw_rect(Rect2(255, 145, 130, 8), Color("afa592"))
	draw_line(Vector2(251, 151), Vector2(389, 151), Color("8d8478"), 1)

	# Columns in two restrained pairs.
	for x in [218, 230, 410, 422]:
		draw_rect(Rect2(x, 88, 6, 37), Color("d4d0c0"))
		draw_rect(Rect2(x + 1, 89, 2, 35), Color("f2ecd9"))


func draw_plaza_objects() -> void:
	# Symmetrical planter beds. Draw their shadow, stone border and foliage in
	# separate pixels so they can later become TileMap layers one-for-one.
	draw_planter(Rect2(52, 156, 78, 40))
	draw_planter(Rect2(510, 156, 78, 40))
	draw_tree(Vector2(91, 167))
	draw_tree(Vector2(549, 167))

	# Benches, lamps and a couple of campus wayfinding bollards.
	draw_bench(Vector2(164, 204), false)
	draw_bench(Vector2(438, 204), true)
	draw_lamp(Vector2(205, 178))
	draw_lamp(Vector2(435, 178))
	draw_lamp(Vector2(66, 247))
	draw_lamp(Vector2(574, 247))
	draw_bollard(Vector2(275, 212))
	draw_bollard(Vector2(365, 212))

	# Low plantings at the outer edge make the scene feel enclosed but keep a
	# clear, readable route through the foreground.
	for x in range(30, 145, 19):
		draw_shrub(Vector2(x, 105 + (x % 4) * 2))
	for x in range(498, 611, 19):
		draw_shrub(Vector2(x, 105 + (x % 4) * 2))


func draw_planter(rect: Rect2) -> void:
	draw_rect(rect.grow(3), Color("a79e8d"))
	draw_rect(rect, Color("d8d1bb"))
	draw_rect(rect.grow(-4), Color("537a57"))
	for x in range(int(rect.position.x + 6), int(rect.end.x - 4), 11):
		draw_rect(Rect2(x, rect.position.y + 8, 5, 4), Color("8fb05f"))
		draw_rect(Rect2(x + 2, rect.position.y + 13, 6, 4), Color("3f714d"))


func draw_tree(center: Vector2) -> void:
	draw_rect(Rect2(center.x - 3, center.y + 8, 6, 14), Color("785b3a"))
	draw_rect(Rect2(center.x - 12, center.y - 8, 24, 21), Color("2f6448"))
	draw_rect(Rect2(center.x - 8, center.y - 13, 16, 8), Color("467d52"))
	draw_rect(Rect2(center.x - 14, center.y - 3, 7, 10), Color("42794e"))
	draw_rect(Rect2(center.x + 7, center.y - 4, 8, 11), Color("315f43"))
	draw_rect(Rect2(center.x - 6, center.y - 10, 8, 4), Color("6fa567"))


func draw_shrub(position: Vector2) -> void:
	draw_rect(Rect2(position.x - 5, position.y - 3, 12, 7), Color("3c734b"))
	draw_rect(Rect2(position.x - 2, position.y - 6, 7, 5), Color("5a9456"))


func draw_bench(position: Vector2, flip: bool) -> void:
	var direction := -1.0 if flip else 1.0
	draw_rect(Rect2(position.x - 12, position.y, 24, 4), Color("7c5336"))
	draw_rect(Rect2(position.x - 12, position.y - 5, 24, 3), Color("a8784b"))
	draw_rect(Rect2(position.x - 9 * direction, position.y + 4, 3, 5), Color("515758"))
	draw_rect(Rect2(position.x + 6 * direction, position.y + 4, 3, 5), Color("515758"))


func draw_lamp(position: Vector2) -> void:
	draw_rect(Rect2(position.x - 1, position.y - 13, 3, 17), Color("42535a"))
	draw_rect(Rect2(position.x - 4, position.y - 15, 9, 4), Color("344750"))
	draw_rect(Rect2(position.x - 2, position.y - 14, 5, 2), Color("f6df83"))
	draw_rect(Rect2(position.x - 3, position.y + 4, 7, 2), Color("586269"))


func draw_bollard(position: Vector2) -> void:
	draw_rect(Rect2(position.x - 3, position.y - 7, 6, 11), Color("5c6970"))
	draw_rect(Rect2(position.x - 2, position.y - 9, 4, 3), Color("e4d47c"))


func draw_player() -> void:
	# A 12 x 16-pixel player placeholder is deliberately easy to replace with a
	# Sprite2D later. The dark ground shadow fixes it to the plaza visually.
	var render_position := player_position.round()
	draw_rect(Rect2(render_position.x - 5, render_position.y + 6, 11, 3), Color(0.25, 0.24, 0.22, 0.35))
	draw_rect(Rect2(render_position.x - 4, render_position.y - 7, 8, 5), Color("e7bb8e"))
	draw_rect(Rect2(render_position.x - 5, render_position.y - 9, 10, 3), Color("473b36"))
	draw_rect(Rect2(render_position.x - 5, render_position.y - 2, 10, 8), Color("d85e4f"))
	draw_rect(Rect2(render_position.x - 5, render_position.y + 6, 4, 3), Color("343c57"))
	draw_rect(Rect2(render_position.x + 1, render_position.y + 6, 4, 3), Color("343c57"))
	# A single bright pixel acts as a simple direction indicator.
	draw_rect(Rect2(render_position + player_direction * 5.0 - Vector2.ONE, Vector2(2, 2)), Color("f4e7b1"))
