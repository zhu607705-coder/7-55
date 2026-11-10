extends RefCounted

const INK := Color("171b25")
const MUTED := Color("626976")
const BLUE := Color("1558b3")
const CANVAS := Color("f2f3f7")
const PILL := Color("edf0f4")

static func panel(parent: Control, rect: Rect2, fill: Color, radius: int) -> Panel:
	var node := Panel.new()
	node.position = rect.position
	node.size = rect.size
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(radius)
	node.add_theme_stylebox_override("panel", style)
	parent.add_child(node)
	return node

static func round_button(button: Button, radius: int) -> Button:
	button.set_meta("phone_button_role", "composite")
	for state: String in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		var style := button.get_theme_stylebox(state).duplicate() as StyleBoxFlat
		style.set_corner_radius_all(radius)
		button.add_theme_stylebox_override(state, style)
	return button

static func icon(parent: Control, kind: String, rect: Rect2, ink: Color) -> void:
	var node := ServiceIcon.new()
	node.position = rect.position
	node.size = rect.size
	node.kind = kind
	node.ink = ink
	parent.add_child(node)

class ServiceIcon extends Control:
	var kind: String
	var ink: Color

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func path(points: Array) -> void:
		draw_polyline(PackedVector2Array(points), ink, 1.8, true)

	func _draw() -> void:
		var unit := minf(size.x,size.y) / 24.0
		draw_set_transform((size - Vector2.ONE * 24 * unit) / 2, 0, Vector2.ONE * unit)
		match kind:
			"learn","library","language_cards":
				path([Vector2(12,7),Vector2(8,5),Vector2(3,5),Vector2(3,18),Vector2(8,18),Vector2(12,20),Vector2(16,18),Vector2(21,18),Vector2(21,5),Vector2(16,5),Vector2(12,7),Vector2(12,20)])
				if kind == "language_cards":
					draw_line(Vector2(15,10),Vector2(19,10),ink,1.5,true)
					draw_line(Vector2(15,14),Vector2(18,14),ink,1.5,true)
			"smart_classroom":
				draw_arc(Vector2(6,13),4,PI*.5,PI*1.65,24,ink,1.8,true)
				draw_arc(Vector2(12,10),5.5,PI,PI*1.95,24,ink,1.8,true)
				draw_arc(Vector2(18,13),4,PI*1.55,TAU+PI*.5,24,ink,1.8,true)
				draw_line(Vector2(6,17),Vector2(18,17),ink,1.8,true)
				path([Vector2(10,9),Vector2(15,12),Vector2(10,15),Vector2(10,9)])
			"campus_map":
				draw_arc(Vector2(12,8),5,PI*.8,PI*2.2,28,ink,1.8,true)
				path([Vector2(8,11),Vector2(12,17),Vector2(16,11)])
				draw_circle(Vector2(12,8),1.4,ink)
				path([Vector2(5,13),Vector2(3,20),Vector2(8,20)])
				path([Vector2(19,13),Vector2(21,20),Vector2(16,20)])
			"network_account","wallet":
				draw_rect(Rect2(3,5,18,12),ink,false,1.8)
				draw_line(Vector2(8,21),Vector2(16,21),ink,1.8,true)
				draw_line(Vector2(12,17),Vector2(12,21),ink,1.8,true)
				path([Vector2(8,12),Vector2(11,9),Vector2(14,12),Vector2(17,9)])
			"all_apps":
				for x in [4,14]:
					for y in [4,14]:
						draw_rect(Rect2(x,y,6,6),ink)
			"directory","campus_card","visitor_preview":
				draw_rect(Rect2(3,5,18,14),ink,false,1.8)
				draw_circle(Vector2(8,10),1.6,ink)
				draw_arc(Vector2(8,15),2.4,PI,TAU,14,ink,1.6,true)
				for y in [10,14]:
					draw_line(Vector2(12,y),Vector2(18,y),ink,1.6,true)
			"feedback_draft":
				draw_rect(Rect2(3,6,18,13),ink,false,1.8)
				path([Vector2(3,7),Vector2(12,13),Vector2(21,7)])
			"lost_found":
				draw_rect(Rect2(4,8,16,12),ink,false,1.8)
				path([Vector2(8,8),Vector2(8,4),Vector2(16,4),Vector2(16,8)])
				draw_line(Vector2(4,13),Vector2(20,13),ink,1.8,true)
			"logistics":
				path([Vector2(3,10),Vector2(12,3),Vector2(21,10),Vector2(21,20),Vector2(3,20),Vector2(3,10)])
				draw_line(Vector2(9,20),Vector2(9,13),ink,1.8,true)
				draw_line(Vector2(15,13),Vector2(15,20),ink,1.8,true)

class CampusLines extends Control:
	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var center := Vector2(size.x - 38,60)
		for radius: float in [23,33,44,56,68]:
			draw_arc(center,radius,-PI*.48,PI*1.18,48,Color("82b8ff",.24),1.0,true)
		draw_line(Vector2(center.x-44,center.y),Vector2(center.x+31,center.y),Color("82b8ff",.3),1,true)
		draw_circle(center,4,Color("acd5ff",.45))
