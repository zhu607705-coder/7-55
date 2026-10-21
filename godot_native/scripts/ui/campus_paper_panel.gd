extends PanelContainer
## Container-owned content with inset-only stationery details. No event handlers.
const UiMaterial = preload("res://scripts/ui/campus_ui_material.gd")
var header_rule := false

func _ready() -> void:
	resized.connect(queue_redraw)
	theme_changed.connect(queue_redraw)

func _draw() -> void:
	if size.x<24 or size.y<12: return
	if header_rule:
		# Existing app heading owns this space; no decorative title is added.
		draw_rect(Rect2(0,size.y-2,size.x,1),UiMaterial.PAPER_EDGE)
		draw_rect(Rect2(0,size.y-2,minf(28,size.x),1),UiMaterial.CORAL)
		return
	# PanelContainer renders its actual StyleBox first. Keep stateful evidence
	# borders, fills and padding intact; add only marks inside the outer edge.
	var inside := Rect2(Vector2(3,3),(size-Vector2(6,6)).max(Vector2.ZERO))
	for command: Dictionary in UiMaterial.commands(Rect2(Vector2.ZERO,size)):
		if command.decoration and inside.encloses(command.rect):
			draw_rect(command.rect,command.color)
