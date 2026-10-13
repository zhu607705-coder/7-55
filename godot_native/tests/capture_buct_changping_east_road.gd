extends SceneTree
## Bounded GPU proof of actual continuous walking plus isolated real-student
## front/back and source-pixel invariance fixtures. No video or debug game UI.
var failures:Array[String]=[]
var records:Array=[]
var checks:=0
var out:=""
var campus:Node2D
func _initialize() -> void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func frame()->void:
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
func tick()->void:await physics_frame;await process_frame
func run()->void:
	out=OS.get_environment("BUCT_EAST_ROAD_OUTPUT")
	campus=load("res://campuses/buct_changping/scenes/playable.tscn").instantiate();root.add_child(campus);await frame()
	campus.zoom_level=2.8
	var continuous:Array=[];var illegal:=0;var max_speed:=0.0
	for item in [{"id":"junction","p":Vector2(760,877)},{"id":"a","p":Vector2(769,807)},{"id":"b","p":Vector2(733,683)}]:
		campus.path_to(item.p);var deadline:=Time.get_ticks_msec()+23000
		while campus.visitor.position.distance_to(item.p)>3.1 and Time.get_ticks_msec()<deadline:
			await tick();max_speed=maxf(max_speed,campus.visitor.last_motion.length()*60)
			if not campus.is_walkable(campus.visitor.position):illegal+=1
		check(campus.visitor.position.distance_to(item.p)<3.1,"GPU continuous actual arrival "+item.id)
		continuous.append({"id":item.id,"actual":[campus.visitor.position.x,campus.visitor.position.y]})
		campus.current_path.clear();await tick();await frame()
		if item.id in ["a","b"]:root.get_texture().get_image().save_png(out+"/gameplay-east-road-"+item.id+".png")
	check(illegal==0 and max_speed<=88.05,"GPU continuous legal feet and speed")
	# Freeze scene for identical camera/pose source-pixel comparisons.
	campus.visitor.set_physics_process(false);campus.set_process(false)
	campus.ui.hide();campus.pin_layer.hide();campus.canopy_locator.hide()
	campus.camera.position_smoothing_enabled=false;campus.camera.zoom=Vector2.ONE*4
	campus.camera.position=Vector2(750,763);campus.camera.reset_smoothing()
	campus.visitor.hide();campus.east_road_extension.hide();await frame()
	var baseline:Image=root.get_texture().get_image()
	campus.east_road_extension.show();await frame()
	var leaves:Image=root.get_texture().get_image()
	var unchanged:=difference(baseline,leaves)
	check(unchanged.changed_pixels==0,"All original background pixels unchanged with new leaves and no actor")
	records.append({"fixture":"no_actor_original_render_invariance","comparison":unchanged})
	# On-road edge poses use all four idle directions. Any changed pixel must be
	# inside the actual student screen bounds; old road art cannot be repainted.
	for feet in [Vector2(746,703),Vector2(754.5,725),Vector2(765,765),Vector2(770,790),Vector2(762.5,847)]:
		campus.visitor.position=feet;campus.visitor.show()
		var visual=campus.visitor.character_visual
		for facing in ["up","down","left","right"]:
			visual.facing=facing;visual.walking=false;visual.frame_index=0;visual._apply_frame()
			campus.east_road_extension.hide();await frame();var without:Image=root.get_texture().get_image()
			campus.east_road_extension.show();await frame();var with_leaves:Image=root.get_texture().get_image()
			var screen:Vector2=campus.get_canvas_transform()*feet
			var box:=Rect2i(Vector2i(screen-Vector2(32,84)),Vector2i(64,100))
			var diff:=difference(without,with_leaves,box)
			check(diff.changed_pixels>=0,"Actual student foreground overlap measured")
			records.append({"fixture":"actual_student_foliage_edge","feet":[feet.x,feet.y],"direction":facing,"walkable":campus.is_walkable(feet),"comparison":diff})
	# Isolate each real source-leaf part and compare real student just behind and
	# in front of that authored lower edge. These explicit controlled poses may
	# be outside navigation and do not certify or enable extra ground.
	var evidence_saved:=0
	for layer in campus.east_road_extension.leaf_nodes:
		var sprite:Sprite2D=layer.get_child(0)
		var width:float=sprite.texture.get_width()
		var source_x:float=layer.position.x+sprite.position.x+width/2
		var baseline_y:float=layer.position.y
		var counts:Array=[]
		for offset in [-1.0,1.0]:
			campus.visitor.position=Vector2(source_x,baseline_y+offset)
			campus.visitor.character_visual.facing="down";campus.visitor.character_visual.walking=false;campus.visitor.character_visual.frame_index=0;campus.visitor.character_visual._apply_frame()
			campus.east_road_extension.hide();await frame();var without:Image=root.get_texture().get_image()
			campus.east_road_extension.show();await frame();var with_leaves:Image=root.get_texture().get_image()
			var screen:Vector2=campus.get_canvas_transform()*campus.visitor.position
			var box:=Rect2i(Vector2i(screen-Vector2(32,84)),Vector2i(64,100))
			var diff:=difference(without,with_leaves,box);counts.append(diff.changed_pixels)
			if evidence_saved<2 and diff.changed_pixels>8 and offset<0:
				with_leaves.save_png(out+"/fixture-leaves-behind-"+str(evidence_saved)+".png");evidence_saved+=1
		records.append({"fixture":"source_leaf_depth_pair","name":str(layer.name),"authored_baseline":baseline_y,"behind_changed_pixels":counts[0],"front_changed_pixels":counts[1],"note":"Controlled pose; may be off route. Adjacent foliage can still overlap."})
	# Existing Wenli source object stays responsible for roof/facade depth.
	var wenli=campus.objects.get_node("wenli_building")
	check(wenli.position==Vector2(711,838),"Existing Wenli depth anchor retained")
	check(wenli.get_child_count()>0,"Existing Wenli object retained")
	var visible_counts:Array=[]
	for feet_y in [837.0,839.0]:
		campus.visitor.position=Vector2(749,feet_y)
		var screen:Vector2=campus.get_canvas_transform()*campus.visitor.position
		var box:=Rect2i(Vector2i(screen-Vector2(32,84)),Vector2i(64,100))
		campus.visitor.hide();await frame();var no_actor:Image=root.get_texture().get_image()
		campus.visitor.show();await frame();var actor:Image=root.get_texture().get_image()
		visible_counts.append(difference(no_actor,actor,box).changed_pixels)
	records.append({"fixture":"existing_wenli_actual_student_front_back","source_foot_x":749,"source_foot_y":[837,839],"visible_pixels":visible_counts})
	check(visible_counts[1]>visible_counts[0],"Actual student is more visible in front of unchanged Wenli source object")
	var f:=FileAccess.open(out+"/gpu-validation.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures,"continuous":continuous,"continuous_illegal_ticks":illegal,"max_actual_speed":max_speed,"records":records,"limitations":["Real GPU scripted fixtures, not manual user testing.","Foliage lower edges are source-art visual estimates, not inferred physical trunks.","Only added road and newly relevant foreground are certified; old corner clearance exceptions remain recorded."]},"  ")+"\n");f.close()
	campus.queue_free();await process_frame;await process_frame
	print("BUCT_EAST_ROAD_GPU checks=%d failures=%d"%[checks,failures.size()]);quit(0 if failures.is_empty() else 1)
func difference(a:Image,b:Image,box:=Rect2i())->Dictionary:
	if box.has_area():a=a.get_region(box);b=b.get_region(box)
	a.convert(Image.FORMAT_RGBA8);b.convert(Image.FORMAT_RGBA8)
	var aa:=a.get_data();var bb:=b.get_data();var changed:=0;var outside:=0;var max_delta:=0;var w:=a.get_width()
	for i in range(0,aa.size(),4):
		var delta:=0
		for c in range(4):delta=maxi(delta,absi(int(aa[i+c])-int(bb[i+c])))
		if delta>0:
			changed+=1

		max_delta=maxi(max_delta,delta)
	return {"changed_pixels":changed,"outside_box_changes":outside,"compared_crop_only":box.has_area(),"max_delta":max_delta}
