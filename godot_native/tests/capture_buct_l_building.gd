extends SceneTree
const BUILDING = preload("res://campuses/buct/scripts/l_compact_layered_building.gd")
const STUDENT = preload("res://campuses/buct_shared/student/scripts/registered_character_visual.gd")
const ASSETS := "res://campuses/buct/assets/west_inner_l/"
var view: SubViewport
var objects: Node2D
var building: Node2D
var student: Node2D
var trees: Array[Sprite2D] = []
var whole: Sprite2D
var profile: Dictionary
var captures: Array[Dictionary] = []
var out: String
var center := Vector2(517,653)
var zoom := 3.0
func _initialize() -> void:run.call_deferred()
func texture(path: String) -> Texture2D:
	# Exercise the exact imported resources used by production, including export.
	return load(path) as Texture2D

func shot(name: String) -> void:
	await process_frame;await RenderingServer.frame_post_draw
	view.get_texture().get_image().save_png(out.path_join(name+".png"))
	captures.append({"name":name})
func run() -> void:
	out=OS.get_environment("BUCT_L_EVIDENCE_DIR").path_join("gpu")
	if DisplayServer.get_name()=="headless" or not out.is_absolute_path():push_error("Real renderer and evidence directory required");quit(2);return
	DirAccess.make_dir_recursive_absolute(out)
	view=SubViewport.new();view.size=Vector2i(640,420);view.transparent_bg=true;view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(view)
	objects=Node2D.new();objects.y_sort_enabled=true;view.add_child(objects)
	var camera:=Camera2D.new();camera.position=center;camera.zoom=Vector2.ONE*zoom;view.add_child(camera);camera.make_current()
	profile=JSON.parse_string(FileAccess.get_file_as_string("res://campuses/buct/data/west-inner-l-profile.json"))
	var sp: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://campuses/buct_shared/student/data/student-movement-profile.json"))
	sp.cycle_stride_body_heights=2.6
	var extra: Dictionary={}
	for id in sp.available_walk_atlases:extra[id]=texture("res://campuses/buct_shared/student/assets/"+str(sp.available_walk_atlases[id]))
	student=STUDENT.new();objects.add_child(student)
	if not student.configure(sp,texture("res://campuses/buct_shared/student/assets/"+str(sp.atlas)),18.0,extra):quit(1);return
	student.hide()
	for item in profile.source_foliage:
		var sprite:=Sprite2D.new();sprite.texture=texture(ASSETS+str(item.asset));sprite.centered=false
		sprite.position=Vector2(item.anchor[0],item.anchor[1]);sprite.offset=Vector2(item.source_rect[0],item.source_rect[1])-sprite.position
		sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;objects.add_child(sprite);sprite.hide();trees.append(sprite)
	await process_frame;await RenderingServer.frame_post_draw
	var base_bytes:=int(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED));var base_nodes:=get_node_count()
	var body_texture: Texture2D=load("res://campuses/buct/assets/west_inner_l/west-inner-l-body.png")
	var imported_image:=body_texture.get_image()
	if not imported_image.has_mipmaps():push_error("Production L texture must import mipmaps");quit(3);return
	var production_mipmaps: bool=imported_image.has_mipmaps()
	imported_image=null
	building=BUILDING.new();objects.add_child(building)
	if not building.configure(profile,body_texture):quit(1);return
	building.update_actor_foot(686,true)
	await process_frame;await RenderingServer.frame_post_draw
	var bytes:=int(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED))-base_bytes;var nodes:=get_node_count()-base_nodes
	await shot("body-compact")
	whole=Sprite2D.new();whole.texture=body_texture;whole.centered=false;whole.position=Vector2(426,591.9801026957638);whole.scale=Vector2.ONE*building.image_scale
	whole.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var material: ShaderMaterial=building.body_passes[0].material.duplicate();material.set_shader_parameter("depth_lower",-100000.0);material.set_shader_parameter("depth_upper",100000.0)
	whole.material=material;objects.add_child(whole);building.hide();await shot("body-whole-reference");whole.hide()
	for i in range(trees.size()):trees[i].show();await shot("tree-%d"%i);trees[i].hide()
	var poses: Array=[{"id":"annex_front","feet":[478,682]},{"id":"annex_behind","feet":[478,666]},{"id":"main_corner_front","feet":[560,685]},{"id":"main_corner_behind","feet":[560,672]},{"id":"return_inner_behind","feet":[568,687]},{"id":"return_front","feet":[568,703]},{"id":"west_join_front","feet":[480,682]},{"id":"west_join_behind","feet":[480,667]}]
	for pose in poses:
		student.position=Vector2(pose.feet[0],pose.feet[1]);student.show()
		for direction in ["down","left","right","up"]:
			student.facing=direction;student.walking=false;student.frame_index=0;student._apply_frame()
			building.hide()
			for tree in trees:tree.hide()
			await shot(str(pose.id)+"-"+direction+"-student")
			building.show();building.update_actor_foot(student.position.y,true)
			for tree in trees:tree.show()
			await shot(str(pose.id)+"-"+direction+"-actual")
		student.hide()
	var report: Dictionary={"status":"CAPTURED_PENDING_PIXEL_ANALYSIS","viewport":[640,420],"camera_center":[center.x,center.y],"camera_zoom":zoom,"body_texture_delta_bytes":bytes,"production_imported_texture":true,"production_mipmaps":production_mipmaps,"body_node_delta":nodes,"component":building.get_diagnostics(),"poses":poses,"captures":captures,"scope":"Fixed render probes; this does not create new walkable routes."}
	var file:=FileAccess.open(out.path_join("capture-manifest.json"),FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
	view.queue_free();await process_frame;await process_frame
	var app=load("res://campuses/buct/scenes/playable.tscn").instantiate();root.add_child(app);await process_frame
	if app.l_building.body_texture!=body_texture:push_error("Fixture differs from production preload texture identity");quit(4);return
	report["same_production_preload_texture_identity"]=true
	file=FileAccess.open(out.path_join("capture-manifest.json"),FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
	app.visitor.set_physics_process(false);app.visitor.position=Vector2(541,705);app.camera.position=app._walking_camera_position();app.camera.reset_smoothing()
	for i in range(3):await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join("full-map-l-neighborhood.png"))
	app.show_landmark("west_inner_l_block");await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join("full-map-l-info.png"))
	app.close_info();app.toggle_overview();await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join("full-map-overview.png"))
	app.queue_free();await process_frame
	print("BUCT_L_GPU_CAPTURED ",captures.size()," component frames and 3 full-scene images")
	quit()
