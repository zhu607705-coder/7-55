extends RefCounted
## Shared temporary subtitle for the Future Learning Center object closeups.
const FONT_SIZE := 21
const TEXT_WIDTH := 904.0
const BACKGROUND := Color("253e46")
const INK := Color("f5f1e4")
const BOTTOM := 532.0

static func duration(message: String) -> float:
	# Keep the familiar five-second minimum and allow longer copy time to read.
	return clampf(1.6 + message.length() * 0.12, 5.0, 8.0)

static func layout(font: Font, message: String) -> Dictionary:
	var text_size: Vector2 = font.get_multiline_string_size(message, HORIZONTAL_ALIGNMENT_LEFT, TEXT_WIDTH, FONT_SIZE)
	var panel_height := maxf(46.0, ceilf(text_size.y) + 20.0)
	var panel := Rect2(16, BOTTOM - panel_height, 928, panel_height)
	var baseline := panel.position.y + (panel_height - text_size.y) / 2.0 + font.get_ascent(FONT_SIZE)
	return {"panel": panel, "baseline": Vector2(28, baseline), "text_size": text_size}

static func paint(canvas: CanvasItem, font: Font, message: String) -> void:
	if message.is_empty(): return
	var metrics := layout(font, message)
	canvas.draw_rect(metrics.panel, BACKGROUND)
	canvas.draw_multiline_string(font, metrics.baseline, message, HORIZONTAL_ALIGNMENT_LEFT, TEXT_WIDTH, FONT_SIZE, -1, INK)
