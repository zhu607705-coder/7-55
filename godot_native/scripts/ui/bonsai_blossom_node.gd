extends Node2D
## One addressable native blossom object; its identity survives every key pose.
const Art = preload("res://scripts/presentation/bonsai_growth_art.gd")
const Session = preload("res://scripts/presentation/bonsai_growth_session.gd")
var blossom_index := 0
var presentation_age := Session.DURATION_MS
var reduced_motion := false

func configure(index: int) -> void:
	blossom_index = index
	name = "Blossom%d" % (index + 1)
	position = Art.ANCHORS[index]
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func present(age: float, reduced: bool) -> void:
	presentation_age = age
	reduced_motion = reduced
	queue_redraw()

func _draw() -> void:
	var pose := Session.pose(presentation_age, blossom_index, reduced_motion)
	var blend: float = 1.0 if presentation_age >= Session.DURATION_MS else pose.source_mix
	var lift := Vector2(0, pose.lift)
	if blend < 1.0:
		# The attachment stays fixed while this blossom's stem tip follows its bud.
		draw_line(Vector2(0,35), lift + Vector2(0,-3), Color("314624"), 7, false)
		draw_line(Vector2(-1,35), lift + Vector2(-1,-3), Color("6a823a"), 3, false)
		draw_set_transform(lift, Art.ANGLES[blossom_index] + pose.angle, Vector2.ONE * Art.SCALES[blossom_index])
		draw_texture(Art.closed_frame, -Art.CLOSED_ANCHOR, Color(1,1,1,1.0-pose.atlas_mix))
		draw_texture(Art.frames[pose.frame], -Art.FRAME_ANCHOR, Color(1,1,1,pose.atlas_mix*(1.0-blend)))
		draw_set_transform(Vector2.ZERO)
	draw_texture(Art.endpoint_parts[blossom_index], Vector2(Art.REGIONS[blossom_index].position)-Art.ANCHORS[blossom_index], Color(1,1,1,blend))
