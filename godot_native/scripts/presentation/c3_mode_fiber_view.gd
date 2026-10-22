extends Node2D
## Source-coordinate circles. Parent owns visibility, depth ordering and clock.
## Intentionally absent from object picking, physics and gameplay state.
const SOURCE_DEPTH := 1602.0
var samples: Array=[]
func _init() -> void:
	name="CanteenModeFibers"
	set_meta("source_depth",SOURCE_DEPTH)
	hide()
func set_samples(next_samples: Array) -> void:
	samples=next_samples.duplicate(true)
	visible=not samples.is_empty()
	queue_redraw()
func _draw() -> void:
	for sample: Dictionary in samples:
		var color: Color=sample.color
		color.a*=clampf(float(sample.alpha),0,1)
		draw_circle(sample.point,float(sample.radius),color)
