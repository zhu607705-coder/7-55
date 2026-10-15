extends SceneTree
## Short bounded GPU complement: real legal edge feet + actual walking frames.
var campus:Node2D
var checks:=0
var failures:Array[String]=[]
var records:Array=[]
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func frame()->void:await process_frame;await process_frame;await RenderingServer.frame_post_draw
func run()->void:
	var out:=OS.get_environment("BUCT_EAST_ROAD_OUTPUT")
	campus=load("res://campuses/buct_changping/scenes/playable.tscn").instantiate();root.add_child(campus);await frame()
	campus.visitor.set_physics_process(false);campus.set_process(false)
	campus.ui.hide();campus.pin_layer.hide();campus.canopy_locator.hide()
	campus.camera.position_smoothing_enabled=false;campus.camera.zoom=Vector2.ONE*3.5;campus.camera.position=Vector2(750,760);campus.camera.reset_smoothing()
	campus.visitor.hide();campus.east_road_extension.hide();await frame();var no_leaves:Image=root.get_texture().get_image()
	campus.east_road_extension.show();await frame();var leaf_only:Image=root.get_texture().get_image()
	var unchanged:=diff(no_leaves,leaf_only)
	var view:Vector2=root.get_visible_rect().size
	var map_rect:=Rect2(campus.camera.position-view/(3.5*2),view/3.5)
	var leaf_bounds:=Rect2(Vector2(750,760),Vector2.ZERO)
	for leaf in campus.east_road_extension.profile.foliage:
		for span in leaf.source_spans_y_x0_x1_exclusive:leaf_bounds=leaf_bounds.expand(Vector2(span[1],span[0])).expand(Vector2(span[2],span[0]+1))
	check(map_rect.encloses(leaf_bounds),"Fixed viewport encloses all added source leaf pixels")
	check(unchanged==0,"No-actor full viewport original render exactly unchanged")
	var frames:Array=[{"feet":Vector2(762.5,847),"direction":"right","frame":0},{"feet":Vector2(762.5,847),"direction":"right","frame":4},{"feet":Vector2(754.5,725),"direction":"left","frame":3}]
	var crops:Array[Image]=[]
	campus.camera.zoom=Vector2.ONE*6
	for item in frames:
		campus.visitor.position=item.feet
		campus.camera.position=item.feet+Vector2(0,-7);campus.camera.reset_smoothing()
		var visual=campus.visitor.character_visual;visual.facing=item.direction;visual.walking=true;visual.frame_index=item.frame;visual._apply_frame()
		check(campus.is_walkable(item.feet),"Real walking frame uses legal source feet")
		campus.visitor.hide();campus.east_road_extension.show();await frame();var ground:Image=root.get_texture().get_image()
		campus.visitor.show();campus.east_road_extension.hide();await frame();var front:Image=root.get_texture().get_image()
		campus.east_road_extension.show();await frame();var layered:Image=root.get_texture().get_image()
		var screen:Vector2=campus.get_canvas_transform()*item.feet
		var box:=Rect2i(Vector2i(screen-Vector2(48,126)),Vector2i(96,150))
		check(Rect2i(Vector2i.ZERO,front.get_size()).encloses(box),"Complete actual student comparison box inside viewport")
		var before:=front.get_region(box);var after:=layered.get_region(box);var empty:=ground.get_region(box)
		var occlusion_pixels:=diff(before,after);var visible_pixels:=diff(empty,after)
		check(occlusion_pixels>0,"Actual walking atlas pixels intersect source leaf foreground")
		check(visible_pixels>100,"Actual student remains visibly present after leaf occlusion")
		records.append({"feet":[item.feet.x,item.feet.y],"direction":item.direction,"state":"walk","frame":item.frame,"occlusion_changed_pixels":occlusion_pixels,"visible_student_pixels":visible_pixels,"source_height":18,"camera_zoom":6,"viewport_pixels":[front.get_width(),front.get_height()],"canvas_transform":[campus.get_canvas_transform().x.x,campus.get_canvas_transform().x.y,campus.get_canvas_transform().y.x,campus.get_canvas_transform().y.y,campus.get_canvas_transform().origin.x,campus.get_canvas_transform().origin.y],"comparison_box":[box.position.x,box.position.y,box.size.x,box.size.y],"walkable":campus.is_walkable(item.feet)})
		crops.append(before);crops.append(after)
	var sheet:=Image.create(96*2,150*3,false,Image.FORMAT_RGBA8)
	for i in range(crops.size()):sheet.blit_rect(crops[i],Rect2i(0,0,96,150),Vector2i((i%2)*96,(i/2)*150))
	sheet.save_png(out+"/walking-leaf-pairs-diagnostic.png")
	var f:=FileAccess.open(out+"/gpu-walking-leaf-validation.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures,"viewport_pixels":[no_leaves.get_width(),no_leaves.get_height()],"no_actor_viewport_changed_pixels":unchanged,"invariance_source_view_rect":[map_rect.position.x,map_rect.position.y,map_rect.size.x,map_rect.size.y],"records":records,"contact_sheet":"Left: foreground hidden; right: actual source-leaf foreground. Each row is one legal-foot actual walking pose. Diagnostic only, not gameplay."},"  ")+"\n");f.close()
	campus.queue_free();await process_frame;await process_frame;print("BUCT_EAST_ROAD_WALK_LEAVES checks=%d failures=%d"%[checks,failures.size()]);quit(0 if failures.is_empty() else 1)
func diff(a:Image,b:Image)->int:
	a.convert(Image.FORMAT_RGBA8);b.convert(Image.FORMAT_RGBA8);var aa:=a.get_data();var bb:=b.get_data();var count:=0
	for i in range(0,aa.size(),4):
		if aa[i]!=bb[i] or aa[i+1]!=bb[i+1] or aa[i+2]!=bb[i+2] or aa[i+3]!=bb[i+3]:count+=1
	return count
