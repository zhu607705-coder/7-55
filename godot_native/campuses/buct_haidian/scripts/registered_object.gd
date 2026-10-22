@tool
extends Node2D
## One 2D object cut from the approved source in the original pixel camera.
## Sprite silhouette, original UV coordinates and ground physics are independent.
@export var source_position := Vector2.ZERO
@export var footprint_polygons: Array[PackedVector2Array] = []
@export var show_footprint := false:
	set(value):
		show_footprint = value
		queue_redraw()
func _draw() -> void:
	if show_footprint:
		for p in footprint_polygons:
			draw_colored_polygon(p,Color(0.05,0.77,0.73,0.17))
			var edge := p.duplicate()
			edge.append(edge[0])
			draw_polyline(edge,Color(0.15,0.8,0.75,0.94),1)

func _ready() -> void:
	visibility_changed.connect(_sync_physics)
	_sync_physics()

func _sync_physics() -> void:
	for child in get_children():
		if child is StaticBody2D:
			child.collision_layer = 1 if is_visible_in_tree() else 0
