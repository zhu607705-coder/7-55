extends Control
## Pixel phone close-up. Input-transparent and state-read-only; no wall clock.
const PIXEL_FONT = preload("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf")
const PANEL_SIZE := Vector2(248, 138)
const INSERT_MS := 180.0
const DURATION_MS := 2200.0
const INK := Color("d4e7df")
const MUTED := Color("8da9a0")
const CURRENT := Color("80dbae")
var presentation: Dictionary = {}
var panel_rect := Rect2()
var station_anchor := Vector2.ZERO

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE

static func tail_duration(result: String) -> float:
	return 760.0 if result == "success" else 240.0

static func pose(elapsed_ms: float, result: String, tail_ms: float, battery: int, reduced: bool) -> Dictionary:
	var elapsed := clampf(elapsed_ms, 0, DURATION_MS)
	var insertion := 1.0 if reduced else smoothstep(0, INSERT_MS, elapsed)
	var alpha := 1.0
	if not result.is_empty():
		var withdrawal := clampf((tail_ms - (520.0 if result == "success" else 0.0)) / 240.0, 0, 1)
		insertion = 0.0 if reduced else insertion * (1.0 - smoothstep(0, 1, withdrawal))
		alpha = 1.0 - withdrawal
	return {
		"battery": clampi(battery, 0, 100),
		"progress": int(floor(elapsed / DURATION_MS * 100.0)),
		"insert": insertion,
		"flow": result.is_empty() and elapsed >= INSERT_MS,
		"flow_step": 0 if reduced else int(elapsed / 90.0) % 12,
		"reduced": reduced,
		"alpha": alpha,
		"result": result,
		"title": "补电完成" if result == "success" else "接线已断开" if result == "cancelled" else "正在连接" if elapsed < INSERT_MS else "保持连接",
		"detail": "电量已更新" if result == "success" else "本次未完成" if result == "cancelled" else "连接进度 %d%%" % int(floor(elapsed / DURATION_MS * 100.0))
	}

func present(extent: Vector2, anchor: Vector2, elapsed_ms: float, result: String, tail_ms: float, battery: int, reduced: bool) -> void:
	size = extent
	station_anchor = anchor
	presentation = pose(elapsed_ms, result, tail_ms, battery, reduced)
	var factor := minf(1.0, minf(maxf(1, extent.x - 16) / PANEL_SIZE.x, maxf(1, extent.y - 16) / PANEL_SIZE.y))
	var dimensions := PANEL_SIZE * factor
	var origin := anchor + Vector2(-dimensions.x / 2, -dimensions.y - 54)
	origin.x = clampf(origin.x, 8, maxf(8, extent.x - dimensions.x - 8))
	origin.y = clampf(origin.y, 8, maxf(8, extent.y - dimensions.y - 8))
	panel_rect = Rect2(origin.floor(), dimensions)
	queue_redraw()

func _draw() -> void:
	if presentation.is_empty(): return
	var alpha: float = presentation.alpha
	var factor := panel_rect.size.x / PANEL_SIZE.x
	var plug: Vector2 = panel_rect.position + Vector2(44, 118 + (1.0 - float(presentation.insert)) * 12) * factor
	# A thin stepped tether identifies the physical station; it never catches input.
	var elbow := Vector2(station_anchor.x, panel_rect.end.y + 12 * factor)
	var panel_exit := Vector2(plug.x, panel_rect.end.y)
	var tether := PackedVector2Array([station_anchor, elbow, Vector2(plug.x, elbow.y), panel_exit])
	draw_polyline(tether, Color(MUTED, alpha * 0.85), 2.0, false)
	if presentation.flow:
		var offset := float(presentation.flow_step) / 12.0
		for i in 3:
			var along := fposmod(offset + i / 3.0, 1.0)
			var point := station_anchor.lerp(elbow, along).round()
			draw_rect(Rect2(point - Vector2(1, 1), Vector2(3, 3)), Color(CURRENT, alpha))
	draw_set_transform(panel_rect.position, 0, Vector2.ONE * factor)
	draw_rect(Rect2(Vector2(3, 3), PANEL_SIZE), Color(0, 0, 0, alpha * 0.3))
	draw_rect(Rect2(Vector2.ZERO, PANEL_SIZE), Color(Color("122326"), alpha))
	draw_rect(Rect2(Vector2.ZERO, PANEL_SIZE), Color(MUTED, alpha), false, 1)
	# Device geometry is a close-up of the in-game phone, not another phone app.
	draw_rect(Rect2(17, 13, 54, 103), Color(Color("071116"), alpha))
	draw_rect(Rect2(17, 13, 54, 103), Color(INK, alpha), false, 2)
	draw_rect(Rect2(22, 26, 44, 74), Color(Color("203a3c"), alpha))
	draw_rect(Rect2(37, 19, 14, 2), Color(MUTED, alpha))
	draw_rect(Rect2(40, 107, 8, 3), Color(MUTED, alpha))
	draw_rect(Rect2(39, 114, 10, 2), Color(MUTED, alpha))
	var plug_y := 118.0 + (1.0 - float(presentation.insert)) * 12.0
	draw_line(Vector2(44, PANEL_SIZE.y), Vector2(44, plug_y + 7), Color(MUTED, alpha), 2.0, false)
	draw_rect(Rect2(40, plug_y - 3, 8, 3), Color(INK, alpha))
	draw_rect(Rect2(38, plug_y, 12, 7), Color(MUTED, alpha))
	# Only actual battery fills the battery glyph. Connection progress has its
	# own straight bar and label, so partial time cannot look like energy gained.
	draw_rect(Rect2(31, 46, 24, 12), Color(INK, alpha), false, 1)
	draw_rect(Rect2(55, 49, 3, 6), Color(INK, alpha))
	var fill := floorf(20.0 * float(presentation.battery) / 100.0)
	if fill > 0: draw_rect(Rect2(33, 48, fill, 8), Color(CURRENT, alpha))
	var battery_text := "%d%%" % int(presentation.battery)
	var text_width := PIXEL_FONT.get_string_size(battery_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	draw_string(PIXEL_FONT, Vector2(44 - text_width / 2, 78), battery_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(INK, alpha))
	draw_string(PIXEL_FONT, Vector2(87, 27), "手机 · 接线", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(MUTED, alpha))
	draw_string(PIXEL_FONT, Vector2(87, 52), str(presentation.title), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(CURRENT if presentation.result == "success" else INK, alpha))
	draw_string(PIXEL_FONT, Vector2(87, 74), "电量 %d%%" % int(presentation.battery), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(INK, alpha))
	draw_string(PIXEL_FONT, Vector2(87, 96), str(presentation.detail), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(MUTED, alpha))
	if presentation.result.is_empty():
		draw_rect(Rect2(87, 106, 140, 3), Color(Color("36514e"), alpha))
		draw_rect(Rect2(87, 106, floorf(140.0 * float(presentation.progress) / 100.0), 3), Color(CURRENT, alpha))
	else:
		draw_string(PIXEL_FONT, Vector2(87, 117), "可以拔线" if presentation.result == "success" else "电量未增加", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(MUTED, alpha))
	draw_set_transform(Vector2.ZERO)
