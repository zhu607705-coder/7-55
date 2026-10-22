extends Control
## Clipped decorative background; every dynamic hazard is separately projected.
var host: Control
func _ready() -> void:
	clip_contents=true;mouse_filter=Control.MOUSE_FILTER_IGNORE
func _draw() -> void:host.draw_chase_field(self)
