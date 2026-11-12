extends Control
## Contrast plates and progress ink above the 3D road and below native controls.
var host: Control
func _ready() -> void:
	clip_contents=true;mouse_filter=Control.MOUSE_FILTER_IGNORE
func _draw() -> void:host.draw_chase_field(self)
