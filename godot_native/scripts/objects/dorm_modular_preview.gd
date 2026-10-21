extends Node2D
## Review/practice sandbox only. No progression mutations, no alternate save.
const Room = preload("res://scenes/objects/dorm_modular_candidate.tscn")
var candidate: Node2D
var reference: Sprite2D
var caption: Label
var paper: Node2D
var exploded := false
var original_positions: Dictionary = {}
func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("111923"))
	reference = Sprite2D.new()
	reference.texture = load("res://assets/rpg/interiors/dorm_hub.png")
	reference.centered = false
	add_child(reference)
	candidate = Room.instantiate()
	add_child(candidate)
	paper = candidate.get_node("Canonical0755Paper")
	for node in candidate.get_node("Furnishings").get_children():
		original_positions[node.name] = node.position
	caption = Label.new()
	caption.text = "SOURCE                               MODULAR CANDIDATE\nSpace: same 0755 paper run cycle | E: separate objects | R: reset\nSink: game-art reference only; real dorm layout NOT verified.\nCandidate preview. No story rewards, saves or production scene replacement."
	caption.add_theme_font_size_override("font_size", 17)
	add_child(caption)
	get_viewport().size_changed.connect(layout)
	layout()
func layout() -> void:
	var size := get_viewport_rect().size
	var zoom := minf((size.x-60)/1882.0,(size.y-120)/1672.0)
	reference.scale = Vector2.ONE*zoom
	candidate.scale = Vector2.ONE*zoom
	reference.position = Vector2((size.x-1882*zoom)/2, 110)
	candidate.position = reference.position+Vector2(941*zoom+20,0)
	caption.position = Vector2(20,8)
func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:return
	match event.keycode:
		KEY_SPACE: paper.animate = not paper.animate
		KEY_E: set_exploded(not exploded)
		KEY_R:
			set_exploded(false)
			paper.animate = false
			paper.position = Vector2(531,834)
func set_exploded(value: bool) -> void:
	exploded=value
	for node in candidate.get_node("Furnishings").get_children():
		var base: Vector2=original_positions[node.name]
		node.position = base+Vector2(-45 if base.x<470 else 45,0) if value else base
	candidate.get_node("CleanPlate").modulate.a = .25 if value else 1.0
