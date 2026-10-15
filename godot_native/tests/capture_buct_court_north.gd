extends SceneTree
const BUILDING = preload("res://campuses/buct/scripts/court_north_building.gd")
const STUDENT = preload("res://campuses/buct_shared/student/scripts/registered_character_visual.gd")
var view: SubViewport
var objects: Node2D
var building: Node2D
var student: Node2D
var profile: Dictionary
var out: String
var captures: Array[Dictionary] = []
var center := Vector2(520, 465)
var zoom := 4.0

func _initialize() -> void: run.call_deferred()

func shot(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	view.get_texture().get_image().save_png(out.path_join(label + ".png"))
	captures.append({"name": label})

func run() -> void:
	out = OS.get_environment("BUCT_COURT_NORTH_EVIDENCE_DIR").path_join("gpu")
	if DisplayServer.get_name() == "headless" or not out.is_absolute_path():
		push_error("Real existing display and evidence directory required")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(out)
	profile = JSON.parse_string(FileAccess.get_file_as_string("res://campuses/buct/data/court-north-profile.json"))
	view = SubViewport.new()
	view.size = Vector2i(720, 380)
	view.transparent_bg = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	objects = Node2D.new()
	objects.y_sort_enabled = true
	view.add_child(objects)
	var camera := Camera2D.new()
	camera.position = center
	camera.zoom = Vector2.ONE * zoom
	view.add_child(camera)
	camera.make_current()
	var sp: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://campuses/buct_shared/student/data/student-movement-profile.json"))
	sp.cycle_stride_body_heights = 2.6
	var extras: Dictionary = {}
	for id in sp.available_walk_atlases:
		extras[id] = load("res://campuses/buct_shared/student/assets/" + str(sp.available_walk_atlases[id]))
	student = STUDENT.new()
	objects.add_child(student)
	if not student.configure(sp, load("res://campuses/buct_shared/student/assets/" + str(sp.atlas)), 18.0, extras):
		quit(1)
		return
	student.hide()
	await process_frame
	await RenderingServer.frame_post_draw
	var base_bytes := int(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED))
	var base_nodes := get_node_count()
	var texture: Texture2D = load(str(profile.body_asset))
	if not texture.get_image().has_mipmaps():
		push_error("Production texture must retain mipmaps")
		quit(3)
		return
	building = BUILDING.new()
	objects.add_child(building)
	if not building.configure(profile, texture):
		quit(1)
		return
	building.update_actor_foot(483.0, true)
	await process_frame
	await RenderingServer.frame_post_draw
	var bytes := int(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)) - base_bytes
	var nodes := get_node_count() - base_nodes
	await shot("body-compact")
	var whole := Sprite2D.new()
	whole.texture = texture
	whole.centered = false
	whole.position = Vector2(profile.body_image_to_world.origin[0], profile.body_image_to_world.origin[1])
	whole.scale = Vector2.ONE * building.image_scale
	whole.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var material: ShaderMaterial = building.body_passes[0].material.duplicate()
	material.set_shader_parameter("depth_lower", -100000.0)
	material.set_shader_parameter("depth_upper", 100000.0)
	whole.material = material
	objects.add_child(whole)
	building.hide()
	await shot("body-whole-reference")
	whole.hide()
	var poses: Array = []
	for x in profile.collision_test_x:
		var depth: float = building.depth_y_at_world_x(float(x))
		poses.append({"id": "x%d_front" % int(x), "feet": [x, depth + 5.0]})
		poses.append({"id": "x%d_behind" % int(x), "feet": [x, depth - 7.0]})
	for pose in poses:
		student.position = Vector2(pose.feet[0], pose.feet[1])
		student.show()
		for direction in ["down", "left", "right", "up"]:
			student.facing = direction
			student.walking = false
			student.frame_index = 0
			student._apply_frame()
			building.hide()
			await shot(str(pose.id) + "-" + direction + "-student")
			building.show()
			building.update_actor_foot(student.position.y, true)
			await shot(str(pose.id) + "-" + direction + "-actual")
		student.hide()
	var report: Dictionary = {"status": "CAPTURED_PENDING_PIXEL_ANALYSIS", "viewport": [720,380], "camera_center": [center.x,center.y], "camera_zoom":zoom, "production_imported_texture":true, "production_mipmaps":true, "body_texture_delta_bytes":bytes, "body_node_delta":nodes, "component":building.get_diagnostics(), "poses":poses, "captures":captures, "scope":"Fixed renderer probes only. Actual map remains road-restricted; whole-body hiding exists only in this isolated reference fixture."}
	view.queue_free()
	await process_frame
	await process_frame
	var app = load("res://campuses/buct/scenes/playable.tscn").instantiate()
	root.add_child(app)
	await process_frame
	if app.court_north.body_texture != texture:
		push_error("Fixture texture identity differs from production")
		quit(4)
		return
	report["same_production_texture_identity"] = true
	app.visitor.set_physics_process(false)
	# This is an already accepted original-art road location, never a new shortcut.
	app.visitor.position = Vector2(612, 478)
	app.camera.position = app._walking_camera_position()
	app.camera.reset_smoothing()
	for i in range(4):
		await process_frame
		await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join("normal-map-court-north.png"))
	app.show_landmark("west_courts_north_bar")
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join("normal-map-neutral-info.png"))
	app.close_info()
	app.toggle_overview()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join("full-map-overview.png"))
	var file := FileAccess.open(out.path_join("capture-manifest.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "))
	file.close()
	app.queue_free()
	await process_frame
	print("BUCT_COURT_NORTH_GPU_CAPTURED ",captures.size()," component frames and three normal-map frames")
	quit()
