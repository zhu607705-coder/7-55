extends SceneTree
var view: Node2D
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	view=load("res://scenes/qizhen_large_world.tscn").instantiate();root.add_child(view);view.auto_control=true;view.title_open=false;view.game.paused=true
	await process_frame
	view.overview=true;view._sync(0,true)
	for i in range(4):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://01-overview-runtime.png")
	view.overview=false;view.game.paused=false;view._sync(0,true)
	for i in range(4):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://02-dock-runtime.png")
	view.game.position=view.Geo.p(807,459);view.game.heading=PI/2;view.game.progress=1;view._sync(0,true)
	for i in range(4):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://03-central-runtime.png")
	view.game.position=view.Geo.p(776,532);view.game.heading=PI/2;view.game.progress=2;view._sync(0,true)
	for i in range(4):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://04-island-runtime.png")
	print("STILLS are runtime scene inspection placements, not a recorded successful playthrough.")
	quit()
