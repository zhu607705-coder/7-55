extends Node2D
## Source-data-driven rehearsal. Debug spawn buttons never grant story facts.
const PlayerScript = preload("res://scripts/player.gd")
var manifest: Dictionary
var player: PlayerScript
var ready_for_test: bool = false
var collision_count: int = 0
var occlusion_count: int = 0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if not FileAccess.file_exists("res://generated/theater.json"):
		fail("Run node scripts/export-godot-theater.mjs from the repository root first.")
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://generated/theater.json"))
	if not parsed is Dictionary or parsed.get("schemaVersion") != 1:
		fail("Invalid generated spatial manifest; regenerate assets.")
		return
	manifest = parsed
	var bounds := Vector2(float(manifest.world.width), float(manifest.world.height))
	var texture: Texture2D = load("res://generated/theater.png")
	if texture == null:
		fail("Missing theater texture; regenerate and import assets.")
		return
	var background := Sprite2D.new()
	background.texture = texture
	background.centered = false
	background.z_index = -1
	add_child(background)
	var depth := Node2D.new()
	depth.y_sort_enabled = true
	add_child(depth)
	for rect in manifest.collisions:
		var body := StaticBody2D.new()
		body.name = str(rect.id)
		body.position = Vector2((float(rect.left) + float(rect.right)) / 2.0, (float(rect.top) + float(rect.bottom)) / 2.0)
		var collider := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(float(rect.right) - float(rect.left), float(rect.bottom) - float(rect.top))
		collider.shape = shape
		body.add_child(collider)
		add_child(body)
		collision_count += 1
	for rect in manifest.occlusion:
		var crop := Sprite2D.new()
		crop.texture = texture
		crop.centered = false
		crop.region_enabled = true
		crop.region_rect = Rect2(float(rect.left), float(rect.top), float(rect.right) - float(rect.left), float(rect.bottom) - float(rect.top))
		crop.position.y = float(rect.sortY)
		crop.offset = Vector2(float(rect.left), float(rect.top) - float(rect.sortY))
		depth.add_child(crop)
		occlusion_count += 1
	player = PlayerScript.new()
	player.configure(manifest.player, bounds)
	depth.add_child(player)
	player.reset_to_legacy_spawn(manifest.spawns.lobby)
	var camera := Camera2D.new()
	camera.position.y = -player.foot_bottom_offset
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(bounds.x)
	camera.limit_bottom = int(bounds.y)
	player.add_child(camera)
	build_hud()
	ready_for_test = true

func build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var column := VBoxContainer.new()
	column.position = Vector2(12, 8)
	layer.add_child(column)
	var label := Label.new()
	label.text = "7:55 | SPATIAL TEST ONLY | WASD / arrows | No story or saves"
	column.add_child(label)
	var row := HBoxContainer.new()
	column.add_child(row)
	for zone in ["lobby", "auditorium", "stage"]:
		var button := Button.new()
		button.text = "Test " + zone
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(func(): player.reset_to_legacy_spawn(manifest.spawns[zone]))
		row.add_child(button)
	var controls := HBoxContainer.new()
	controls.position = Vector2(12, 472)
	layer.add_child(controls)
	var labels: Array[String] = ["Left", "Right", "Up", "Down"]
	for index in range(PlayerScript.ACTIONS.size()):
		var action: String = PlayerScript.ACTIONS[index]
		var button := Button.new()
		button.text = labels[index]
		button.custom_minimum_size = Vector2(72, 48)
		button.focus_mode = Control.FOCUS_NONE
		button.button_down.connect(func(): Input.action_press(action))
		button.button_up.connect(func(): Input.action_release(action))
		controls.add_child(button)

func fail(message: String) -> void:
	push_error(message)
	var label := Label.new()
	label.text = message
	label.position = Vector2(20, 20)
	add_child(label)
