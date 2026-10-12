extends "res://campuses/buct/scripts/l_compact_layered_building.gd"
## A genuine fixed-position RGBA object. The full-campus image remains below it.
## No public hide/move control is offered until the entire hidden base is repaired.
const ASSET_DIR := "res://campuses/buct/assets/west_inner_l/"
var foliage_nodes: Array[Node2D] = []
var ground_patch: Sprite2D

func _ready() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://campuses/buct/data/west-inner-l-profile.json"))
	var configured_ok := configure(data, preload("res://campuses/buct/assets/west_inner_l/west-inner-l-body.png"))
	if not configured_ok:
		push_error("Chaoyang L-building configuration failed")
		hide()
		return
	for item in profile.get("source_foliage", []):
		var canopy := Node2D.new()
		canopy.name = "PreservedSourceCanopy_" + str(item.id)
		canopy.position = Vector2(item.anchor[0], item.anchor[1]) - source_anchor
		var sprite := Sprite2D.new()
		sprite.name = "ExactSourceLeaves"
		sprite.centered = false
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.texture = load(ASSET_DIR + str(item.asset))
		sprite.position = Vector2(item.source_rect[0], item.source_rect[1]) - Vector2(item.anchor[0], item.anchor[1])
		canopy.add_child(sprite)
		add_child(canopy)
		foliage_nodes.append(canopy)
	# This file must already be a mask-limited, registered patch. No shader crops
	# or guessed terrain colors are used to manufacture missing scene art.
	if ResourceLoader.exists(ASSET_DIR + "south-ground-repair.png"):
		ground_patch = Sprite2D.new()
		ground_patch.name = "MinimalExposedOldFacadeRepair"
		ground_patch.centered = false
		ground_patch.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		ground_patch.texture = load(ASSET_DIR + "south-ground-repair.png")
		ground_patch.position = Vector2(476, 675) - source_anchor
		ground_patch.z_index = -10
		add_child(ground_patch)
	visibility_changed.connect(_sync_native_visibility)
	_sync_native_visibility()

func _sync_native_visibility() -> void:
	if is_instance_valid(physics_body):physics_body.collision_layer = 1 if is_visible_in_tree() else 0

func depth_y_at_world_x(world_x: float) -> float:
	var origin := global_position + body_local_origin
	var column := clampi(floori((world_x-origin.x)/image_scale),0,raw_size.x-1)
	return origin.y + column_depths[column]*image_scale
