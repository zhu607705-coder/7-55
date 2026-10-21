extends SceneTree
const Notebook = preload("res://scripts/ui/campus_notebook_panel.gd")
var checks := 0
var failures := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func run() -> void:
	for mode: String in Notebook.MODES:
		for width: float in [366.0, 580.0, 840.0]:
			for height: float in [180.0, 700.0]:
				var extent := Vector2(width, height)
				var geo := Notebook.geometry(extent)
				check(geo.body==Rect2(24,18,width-42,height-40), "explicit fixed body margins")
				var marks := Notebook.commands(extent, mode)
				check(marks==Notebook.commands(extent,mode), "deterministic silhouette")
				check(marks.size()<=12, "bounded detail density")
				for mark: Dictionary in marks:
					check(geo.bounds.encloses(mark.rect), "all paint within panel bounds")
					if mark.decoration: check(not geo.body.intersects(mark.rect), "detail never crosses body")
				var panel := Notebook.new()
				panel.mode=mode; panel.size=extent
				var content := Control.new(); panel.add_child(content); root.add_child(panel)
				await process_frame
				check(content.get_rect()==geo.body, "actual container matches declared body")
				check(panel.body_rect()==geo.body, "instance body contract")
				check(panel.mouse_filter==Control.MOUSE_FILTER_IGNORE, "silhouette does not intercept input")
				check(panel.focus_mode==Control.FOCUS_NONE, "silhouette cannot take focus")
				panel.free()
	for extent: Vector2 in [Vector2.ZERO,Vector2.ONE,Vector2(30,20),Vector2(49,47)]:
		var geo := Notebook.geometry(extent)
		check(geo.bounds.encloses(geo.body), "tiny body stays bounded")
		check(Notebook.commands(extent).is_empty(), "tiny panel omits detail")
	var panel := Notebook.new(); panel.mode="unknown"
	check(panel.mode=="notebook", "unknown mode safely defaults")
	panel.free()
	print("Campus notebook panel: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
