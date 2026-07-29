extends Node2D

## Data-driven interaction layer for the supplied auditorium artwork.
## The source map was rotated clockwise to put the stage at the top. All area
## coordinates below refer to that 941 x 1672 portrait source image; the game
## itself remains a 640 x 360 landscape viewport with a vertical Camera2D.

const VIEW_SIZE := Vector2(640, 360)
const MAP_SOURCE_SIZE := Vector2(941, 1672)
const MAP_SCALE := 640.0 / 941.0
const MAP_WORLD_SIZE := MAP_SOURCE_SIZE * MAP_SCALE
const PLAYER_SPEED := 132.0
const PLAYER_RADIUS_SOURCE := 11.0
const WALK_FRAME_SECONDS := 0.18
const PLAYER_FRAMES := {
	"side": [
		preload("res://assets/player/player_side_0.png"),
		preload("res://assets/player/player_side_1.png"),
	],
	"up": [
		preload("res://assets/player/player_up_0.png"),
		preload("res://assets/player/player_up_1.png"),
	],
	"down": [
		preload("res://assets/player/player_down_0.png"),
		preload("res://assets/player/player_down_1.png"),
	],
}

var player_position := (MAP_SOURCE_SIZE - Vector2(86, 840)) * MAP_SCALE
var current_zone: Dictionary = {}
var status_message := "从侧入口进入剧场。靠近高亮区域后按 E 互动。"
var message_time_left := 5.0
var show_zone_overlays := false
var stage_lights_on := false
var seat_info_visible := false
var e_was_down := false
var m_was_down := false
var r_was_down := false
var player_facing := "down"
var side_facing_left := false
var walk_frame := 0
var walk_frame_time := 0.0

# Seat banks were identified from the map and treated as solid. A simple list
# makes them easy to tune later, or replace with TileMap collision polygons.
var solid_source_rects: Array[Rect2] = [
	Rect2(176, 440, 160, 165), Rect2(365, 445, 230, 165), Rect2(623, 440, 155, 165),
	Rect2(166, 620, 170, 205), Rect2(355, 620, 245, 210), Rect2(615, 615, 170, 210),
	Rect2(150, 852, 180, 165), Rect2(350, 852, 255, 172), Rect2(610, 852, 180, 165),
	Rect2(190, 1098, 178, 102), Rect2(383, 1098, 176, 105), Rect2(577, 1098, 174, 102),
	Rect2(145, 1222, 195, 185), Rect2(369, 1220, 208, 190), Rect2(603, 1220, 190, 185),
	Rect2(60, 20, 150, 120), Rect2(732, 20, 155, 120),
	Rect2(48, 1490, 260, 145), Rect2(628, 1490, 260, 145),
]

# Each zone has a world purpose, a gameplay prompt, and a visual source-space
# rectangle. This is the deliberate region recognition layer for the artwork.
var interactable_zones: Array[Dictionary] = [
	{
		"id": "stage", "name": "演出舞台", "area": Rect2(185, 55, 570, 350),
		"prompt": "按 E 切换舞台工作灯", "action": "stage"
	},
	{
		"id": "stalls", "name": "一层观众席", "area": Rect2(135, 415, 670, 615),
		"prompt": "按 E 查看观众席信息", "action": "seats"
	},
	{
		"id": "control", "name": "灯光与音响控制台", "area": Rect2(385, 1015, 180, 98),
		"prompt": "按 E 打开技术控制台", "action": "control"
	},
	{
		"id": "left_stairs", "name": "左侧看台楼梯", "area": Rect2(35, 830, 140, 210),
		"prompt": "按 E 查看二层看台通道", "action": "stairs"
	},
	{
		"id": "right_stairs", "name": "右侧看台楼梯", "area": Rect2(765, 830, 140, 210),
		"prompt": "按 E 查看二层看台通道", "action": "stairs"
	},
	{
		"id": "backstage", "name": "后台出入口", "area": Rect2(315, 1450, 310, 175),
		"prompt": "按 E 前往后台（预留）", "action": "backstage"
	},
]

@onready var camera: Camera2D = $Camera2D
@onready var player_sprite: Sprite2D = $PlayerSprite
@onready var zone_label: Label = $HUD/TopBar/Zone
@onready var prompt_label: Label = $HUD/MessagePanel/Prompt
@onready var message_label: Label = $HUD/MessagePanel/Message


func _ready() -> void:
	camera.make_current()
	update_player_sprite(Vector2.ZERO, 0.0)
	update_current_zone()
	update_hud()
	queue_redraw()


func _process(delta: float) -> void:
	var direction := get_move_direction()
	if direction != Vector2.ZERO:
		try_move(direction * PLAYER_SPEED * delta)
	update_player_sprite(direction, delta)

	var e_down := Input.is_key_pressed(KEY_E)
	if e_down and not e_was_down:
		interact_with_current_zone()
	e_was_down = e_down

	var m_down := Input.is_key_pressed(KEY_M)
	if m_down and not m_was_down:
		show_zone_overlays = not show_zone_overlays
		status_message = "区域标记已%s。" % ("显示" if show_zone_overlays else "隐藏")
		message_time_left = 2.5
	m_was_down = m_down

	var r_down := Input.is_key_pressed(KEY_R)
	if r_down and not r_was_down:
		player_position = layout_to_world(Vector2(86, 840))
		status_message = "已回到侧入口。"
		message_time_left = 2.0
	r_was_down = r_down

	message_time_left = maxf(0.0, message_time_left - delta)
	update_current_zone()
	update_camera()
	update_hud()
	queue_redraw()


func get_move_direction() -> Vector2:
	var direction := Vector2(
		int(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) - int(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)),
		int(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)) - int(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))
	)
	return direction.normalized() if direction.length_squared() > 0.0 else Vector2.ZERO


func try_move(motion: Vector2) -> void:
	var x_candidate := player_position + Vector2(motion.x, 0)
	if not is_blocked(x_candidate):
		player_position = x_candidate
	var y_candidate := player_position + Vector2(0, motion.y)
	if not is_blocked(y_candidate):
		player_position = y_candidate


func is_blocked(world_position: Vector2) -> bool:
	var source_position := map_to_layout_point(world_to_source(world_position))
	var source_bounds := Rect2(Vector2(22, 22), MAP_SOURCE_SIZE - Vector2(44, 44))
	if not source_bounds.has_point(source_position):
		return true
	for seat_block in solid_source_rects:
		if seat_block.grow(PLAYER_RADIUS_SOURCE).has_point(source_position):
			return true
	return false


func update_current_zone() -> void:
	var source_position := map_to_layout_point(world_to_source(player_position))
	current_zone = {}
	var best_area := 1000000000.0
	for zone in interactable_zones:
		var zone_area: float = zone.area.get_area()
		if zone.area.grow(24).has_point(source_position) and zone_area < best_area:
			current_zone = zone
			best_area = zone_area


func interact_with_current_zone() -> void:
	if current_zone.is_empty():
		status_message = "这里没有可互动的设施。按 M 可查看区域划分。"
		message_time_left = 2.4
		return

	match current_zone.action:
		"stage":
			stage_lights_on = not stage_lights_on
			status_message = "舞台工作灯已%s。" % ("开启" if stage_lights_on else "关闭")
		"seats":
			seat_info_visible = not seat_info_visible
			status_message = "一层观众席：中央区、左右侧区与环形看台。"
		"control":
			show_zone_overlays = not show_zone_overlays
			status_message = "技术控制台：区域%s，等待接入灯光音响系统。" % ("标记已开启" if show_zone_overlays else "标记已关闭")
		"stairs":
			status_message = "二层看台通道已确认：下一步可切换至二楼场景。"
		"backstage":
			status_message = "后台场景接口已预留；稍后可在这里切换到化妆间或装卸区。"
	message_time_left = 4.2


func update_camera() -> void:
	var half_height := VIEW_SIZE.y * 0.5
	camera.position = Vector2(
		VIEW_SIZE.x * 0.5,
		clampf(player_position.y, half_height, MAP_WORLD_SIZE.y - half_height)
	)


func update_hud() -> void:
	if current_zone.is_empty():
		zone_label.text = "当前位置：公共通道"
		prompt_label.text = "WASD / 方向键移动   ·   M 显示区域划分"
	else:
		zone_label.text = "当前位置：%s" % current_zone.name
		prompt_label.text = "%s   ·   M 显示区域" % current_zone.prompt
	message_label.text = status_message if message_time_left > 0.0 else "E 交互 · M 显示区域 · R 回到侧入口"


func _draw() -> void:
	if stage_lights_on:
		draw_stage_lighting()
	if show_zone_overlays:
		draw_zone_overlays()
	if seat_info_visible:
		draw_seat_highlights()


func draw_stage_lighting() -> void:
	var stage_rect := source_rect_to_world(interactable_zones[0].area)
	draw_rect(stage_rect, Color(1.0, 0.77, 0.31, 0.16))
	for x in range(int(stage_rect.position.x + 55), int(stage_rect.end.x), 105):
		draw_circle(Vector2(x, stage_rect.position.y + 84), 34, Color(1.0, 0.9, 0.54, 0.12))


func draw_zone_overlays() -> void:
	for zone in interactable_zones:
		var rect := source_rect_to_world(zone.area)
		var color := Color(0.98, 0.73, 0.22, 0.14)
		if not current_zone.is_empty() and zone.id == current_zone.id:
			color = Color(0.34, 0.9, 0.67, 0.20)
		draw_rect(rect, color)
		draw_rect(rect, Color(color.r, color.g, color.b, 0.72), false, 2.0)


func draw_seat_highlights() -> void:
	for index in range(15):
		var rect := source_rect_to_world(solid_source_rects[index])
		draw_rect(rect, Color(1.0, 0.83, 0.36, 0.08))


func source_to_world(source_position: Vector2) -> Vector2:
	return source_position * MAP_SCALE


func world_to_source(world_position: Vector2) -> Vector2:
	return world_position / MAP_SCALE


func source_rect_to_world(source_rect: Rect2) -> Rect2:
	var rotated_rect := layout_to_map_rect(source_rect)
	return Rect2(source_to_world(rotated_rect.position), rotated_rect.size * MAP_SCALE)


func layout_to_world(layout_position: Vector2) -> Vector2:
	return source_to_world(layout_to_map_point(layout_position))


func layout_to_map_point(layout_position: Vector2) -> Vector2:
	return MAP_SOURCE_SIZE - layout_position


func map_to_layout_point(map_position: Vector2) -> Vector2:
	return MAP_SOURCE_SIZE - map_position


func layout_to_map_rect(layout_rect: Rect2) -> Rect2:
	return Rect2(MAP_SOURCE_SIZE - layout_rect.end, layout_rect.size)


func update_player_sprite(direction: Vector2, delta: float) -> void:
	if direction != Vector2.ZERO:
		if absf(direction.x) > absf(direction.y):
			player_facing = "side"
			side_facing_left = direction.x < 0.0
		elif direction.y < 0.0:
			player_facing = "up"
		else:
			player_facing = "down"

		walk_frame_time += delta
		if walk_frame_time >= WALK_FRAME_SECONDS:
			walk_frame = 1 - walk_frame
			walk_frame_time = 0.0
	else:
		walk_frame = 0
		walk_frame_time = 0.0

	player_sprite.texture = PLAYER_FRAMES[player_facing][walk_frame]
	player_sprite.flip_h = player_facing == "side" and side_facing_left
	player_sprite.position = player_position - Vector2(0, 10)
