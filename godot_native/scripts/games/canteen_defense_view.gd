extends Control
## Presentation-only clipped camera; the host owns all input and simulation.
var host: Control
var is_overview: bool=false
func _ready() -> void:
	clip_contents=true
	mouse_filter=Control.MOUSE_FILTER_IGNORE
func _draw() -> void:
	host.draw_board_view(self,is_overview)
