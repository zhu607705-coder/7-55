extends Control
## Isolated actual renderer; does not call State or mutate a formal story save.
const Stairs=preload("res://scripts/games/chapter4_stairs.gd")
var game:Control
func _ready()->void:
	game=Stairs.new()
	game.level_index=1
	game.theme=preload("res://scripts/ui/native_ui_theme.gd").font_theme(load("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf"))
	add_child(game)
	game.setup({"session":"stair-b-asset-preview"})
	game.size=get_viewport_rect().size
	game.cancelled.connect(func():get_tree().quit())
	resized.connect(func():game.size=size)
func _unhandled_key_input(event:InputEvent)->void:
	if event.is_action_pressed("ui_cancel"):get_tree().quit()
