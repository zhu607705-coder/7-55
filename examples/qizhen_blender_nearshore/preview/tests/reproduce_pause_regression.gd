extends SceneTree
const Timeline=preload("res://scripts/presentation/kayak_stroke_timeline.gd")
func _initialize() -> void:
	var motion=Timeline.new()
	motion.request_stroke("left")
	motion.advance(.20)
	motion.request_stroke("right")
	var before=not motion.pending.is_empty()
	motion.set_paused(false)
	var after=not motion.pending.is_empty()
	print(JSON.stringify({"pending_before_idempotent_unpause":before,"pending_after_idempotent_unpause":after,"regression_present":before and not after}))
	quit(0)
