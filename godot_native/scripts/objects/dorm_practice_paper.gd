extends Node2D
## Exact existing story-paper renderer. Practice never calls State or a controller.
const PaperArt = preload("res://scripts/presentation/c3_paper_art.gd")
@export var animate := false
@export var reduced_motion := false
var elapsed := 0.0
var frame := -1
func _process(delta: float) -> void:
	elapsed += delta
	var next_frame: int = int(elapsed / 0.13) % 4 if animate and not reduced_motion else -1
	if next_frame != frame:
		frame = next_frame
		queue_redraw()
func _draw() -> void:
	PaperArt.draw(self, Vector2.ZERO, 1.0, 0.0, frame)
func commands() -> Array:
	return PaperArt.frame_commands(frame)
