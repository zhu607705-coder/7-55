extends SceneTree
## Regression: app-wide dark text must not hide labels on the dark stair panel;
## gallery snapshots must wait for the real reveal and name the actual level.
const Stairs = preload("res://scripts/games/chapter4_stairs.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("STAIR PRESENTATION: " + message)

func run() -> void:
	var holder := Control.new()
	holder.size = Vector2(960, 540)
	var dark_text_theme := Theme.new()
	dark_text_theme.set_color("font_color", "Label", Color("14212a"))
	holder.theme = dark_text_theme
	root.add_child(holder)
	var stairs := Stairs.new()
	holder.add_child(stairs)
	stairs.setup({"session": "presentation-test"})
	var gallery: Node = load("res://tests/visual_gallery.gd").new()
	root.add_child(gallery)
	var ids: Array = []
	for index in range(4):
		var ready: bool = await gallery._load_stair_gallery_level(stairs, index)
		check(ready, "gallery settles on level %d" % (index + 1))
		check(stairs.reveal_done and not stairs.busy, "capture occurs after reveal")
		check(stairs.level.id == stairs.source.levels[index].id, "actual source level identity")
		check(stairs.caption.text.begins_with("%d / 4" % (index + 1)), "visible level caption matches filename")
		check(stairs.caption.get_theme_color("font_color") == Stairs.PANEL_FOREGROUND, "caption overrides inherited dark text")
		ids.append(stairs.level.id)
		var labels := 0
		for row in stairs.toolbar.get_children():
			if row.is_queued_for_deletion(): continue
			for child in row.get_children():
				if child is Label:
					labels += 1
					check(child.get_theme_color("font_color") == Stairs.PANEL_FOREGROUND, "mechanism label remains visible")
		check(labels == stairs.level.mechanisms.size(), "all mechanism labels covered")
	check(ids == ["stair_a", "stair_b", "stair_c", "stair_d"], "four distinct authored levels captured")
	var fg: float = Stairs.PANEL_FOREGROUND.srgb_to_linear().get_luminance()
	var bg: float = Stairs.PANEL_BACKGROUND.srgb_to_linear().get_luminance()
	check((fg + 0.05) / (bg + 0.05) >= 4.5, "normal text contrast at least 4.5:1")
	check(not await gallery._load_stair_gallery_level(stairs, 4), "invalid level rejected")
	gallery.cancelled = true
	check(not await gallery._load_stair_gallery_level(stairs, 1), "cancelled capture rejected")
	gallery.queue_free()
	holder.queue_free()
	await process_frame
	await process_frame
	print("STAIR PRESENTATION checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
