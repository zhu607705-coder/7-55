extends SceneTree
## Requires real generated art. Source patches, node pivots/depth, time lighting and
## existing interaction are tested; this headless script is not a visual acceptance.
const Objects=preload("res://scripts/presentation/north_generated_objects.gd")
const Metrics=preload("res://scripts/player_metrics.gd")
var checks:=0
var failures:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func frames(n:=2)->void:
	for i in n:await process_frame
func anchor_for_bottom(x:float,y:float)->Vector2:
	return Vector2(x,y)-Metrics.FOOT_CENTER_OFFSET-Vector2(0,Metrics.FOOT_SIZE.y/2)
func run()->void:
	if not preload("res://tests/native_test_isolation.gd").is_isolated_save():quit(2);return
	OS.set_environment(Objects.PREVIEW_ENV,"1")
	var registration:RefCounted=Objects.new()
	var provenance:Array=JSON.parse_string(FileAccess.get_file_as_string("res://assets/native/north_objects_20261025/web_batch2_provenance.json"))
	for asset:Dictionary in registration.asset_registrations():
		if asset.id in ["lectern_105","bookcase_105"]:continue
		var rows:Array=provenance.filter(func(row:Dictionary):return str(row.get("texture",row.get("local_file",row.get("local_master","")))).get_file()==str(asset.texture).get_file())
		check(rows.size()==1 and rows[0].sha256==asset.sha256,"Current web master has one exact provenance mapping "+str(asset.id))
	for prop:Dictionary in registration.data.props:
		if not ResourceLoader.exists(prop.texture):
			printerr("NORTH_INDEPENDENT_PROPS_BLOCKED: real generated asset not supplied: "+str(prop.texture));quit(2);return
	var state:Node=root.get_node("State");state.developer_mode=true
	state.begin_checkpoint("c4-755-classrooms-1850")
	state.d.chapter4.mode="light";state.d.native.mode="light"
	var world:Control=load("res://scripts/world.gd").new();world.size=Vector2(1280,720);root.add_child(world);world.set_process(false);await frames()
	var family:RefCounted=world.north_objects;var scene:Node2D=world.north_props
	check(family.active and scene.active,"Complete real family activates independent nodes")
	if not family.active:world.queue_free();await frames();quit(1);return
	var placed:=0
	for object:Node2D in scene.objects.values():
		if object.get_parent() in [scene.behind_space,scene.front_space]:placed+=1
	check(scene.objects.size()==53 and placed==53,"Exactly one Node2D per generated prop and separate desk/chair; source-floor layers retain their own owner")
	check(scene.passes[0].get_index()<scene.behind_space.get_index() and scene.behind_space.get_index()<scene.passes[1].get_index() and scene.passes[1].get_index()<scene.front_space.get_index() and scene.front_space.get_index()<scene.passes[3].get_index(),"Render passes preserve source actor sandwich without elevating the world above UI")
	var bible:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://docs/art/art_direction_v1.json"))
	check(family.data.palette.colors==bible.palette.colors and family.data.palette.colors.size()==32,"All new base-art colors use the locked shared32 palette before time lighting")
	for object:Node2D in scene.objects.values():
		var palette:PackedColorArray=object.get_node("Appearance").material.get_shader_parameter("shared_palette")
		check(palette.size()==32,"Each actual independent sprite receives all 32 palette entries")
	var state_before:Dictionary=state.d.duplicate(true)
	var targets_before:Array=world.targets.duplicate(true)
	var source:Array=world.spec.layout.floors[0].staticCollisions.duplicate(true)
	var adjusted:Array=family.adjusted_collisions(source)
	var wall:Dictionary=adjusted.filter(func(box:Dictionary):return box.get("id","")=="a1_air_wall_005")[0]
	check(family.rect([wall.x,wall.y,wall.width,wall.height])==Rect2(1226,584,381,12),"Wall collider remains source-authored")
	var preserved:Array=[]
	for part:Dictionary in family.data.wall.preservedSourceParts:preserved.append(part.id)
	check(preserved==["chalk_shelf"],"Only the original chalk shelf remains in the wall composite; all five props are independent")
	check(family.owns_cover({"id":"a1_foreground_019"}),"Generated lectern retires the independent old source foreground crop")
	check(not family.owns_cover({"id":"a1_foreground_020"}),"Unchanged 104 lectern keeps its original foreground crop")
	for prop:Dictionary in family.data.props:
		var object:Node2D=scene.objects[prop.id];var sprite:Sprite2D=object.get_node("Appearance")
		var graphic:Rect2=family.prop_rect(prop)
		check(object.name==StringName(prop.nodeName),"Independently named node "+str(prop.id))
		check(object.z_index==0 and object.get_child_count()==1 and sprite.texture==family.prop_textures[prop.id],"One generated sprite per object "+str(prop.id))
		check(object.position==Vector2(prop.centerX,prop.baselineY),"Authored foot pivot "+str(prop.id))
		check(is_equal_approx(graphic.end.y,float(prop.baselineY)),"Visible art meets its own baseline "+str(prop.id))
		check(sprite.scale==Vector2.ONE*float(prop.scale),"No anisotropic texture stretching "+str(prop.id))
		check(sprite.texture_filter==CanvasItem.TEXTURE_FILTER_NEAREST,"Pixel sampling is nearest "+str(prop.id))
		check(FileAccess.get_sha256(prop.texture)==str(prop.sha256),"Downloaded web master bytes are unchanged "+str(prop.id))
		check(sprite.material is ShaderMaterial and is_equal_approx(float(sprite.material.get_shader_parameter("alpha_cutoff")),8.0/255.0),"Low-alpha web noise is discarded by registered native shader "+str(prop.id))
		for delta:float in [-.02,0.0,.02]:
			var player:=anchor_for_bottom(prop.centerX,float(prop.get("depthBaselineY",prop.baselineY))+delta)
			scene.configure_view(Vector2(12,40),.85,player,0)
			if prop.get("renderMode","")=="wall_attached":
				check(object.get_parent()==scene.behind_space and scene.wall_reveal.visible==(delta<=0),"Wall-mounted visual anchor is separate from its wall-depth reveal "+str(prop.id)+" / "+str(delta))
			else:
				check(object.get_parent()==(scene.front_space if delta<=0 else scene.behind_space),"Independent foot depth including contact "+str(prop.id)+" / "+str(delta))
		var old_rect:Rect2=family.rect(prop.sourceRect)
		var cleaned:=true;var excluded:=true
		for y:int in range(int(old_rect.position.y),int(old_rect.end.y)):
			for x:int in range(int(old_rect.position.x),int(old_rect.end.x)):
				var point:=Vector2(x+.5,y+.5)
				var covered:bool=family.rect(family.data.wall.destinationRect).has_point(point)
				for patch:Dictionary in prop.cleanup:covered=covered or family.rect(patch.rect).has_point(point)
				cleaned=cleaned and covered;excluded=excluded and not family.source_part_keeps_pixel(point)
		check(cleaned,"Every old prop pixel has a bounded cleanup owner "+str(prop.id))
		check(excluded,"No old prop pixels survive any preserved-source overlay "+str(prop.id))
	check(scene.reveal_objects.size()==2 and is_equal_approx(scene.wall_reveal.self_modulate.a,.78),"Only two wall-mounted reveal appearances share ONE wall opacity group")
	for prop:Dictionary in family.data.props:
		if prop.get("renderMode","")!="wall_attached":continue
		var reveal:Sprite2D=scene.reveal_objects[prop.id]
		check(reveal.texture==scene.objects[prop.id].get_node("Appearance").texture and reveal.modulate.a==1,"Mounted reveal uses the real asset at full local alpha before group reveal")
		check(reveal.get_meta("owner_object_id")==prop.id,"Reveal is a presentation proxy of the same logical object")
	for group:Dictionary in family.data.desks:
		var table:Node2D=scene.objects[str(group.id)+"_student_table"]
		var chair:Node2D=scene.objects[str(group.id)+"_student_chair"]
		check(table.position==Vector2(group.centerX,float(group.baselineY)-5.8) and chair.position==Vector2(group.centerX,group.baselineY),"Separate table/chair keep both original foot lines "+str(group.id))
		var bases:Array=family.desk_solids(group)
		check(bases[0].is_equal_approx(Rect2(float(group.centerX)-21,float(group.baselineY)-11.4,42,5.6)) and bases[1].is_equal_approx(Rect2(float(group.centerX)-12,float(group.baselineY)-5.8,24,5.8)),"Both pre-existing solid bases remain exact "+str(group.id))
		var between:=anchor_for_bottom(group.centerX,float(group.baselineY)-3)
		scene.configure_view(Vector2.ZERO,1,between,0)
		check(table.get_parent()==scene.behind_space and chair.get_parent()==scene.front_space,"Actor can sort between table and chair, not behind a combined sprite "+str(group.id))
	for part:Dictionary in family.data.deskParts:
		check(FileAccess.get_sha256(part.texture)==str(part.sha256),"Separate student asset stays byte-identical to web master "+str(part.id))
	check(family.source_part_keeps_pixel(Vector2(1380.5,574.5)) and not family.source_part_keeps_pixel(Vector2(1381.5,574.5)),"Chalk shelf excludes old lectern overlap at the exact left boundary")
	check(not family.source_part_keeps_pixel(Vector2(1435.5,574.5)) and family.source_part_keeps_pixel(Vector2(1436.5,574.5)),"Chalk shelf retains the non-overlapping right segment")
	var lectern:Dictionary=family.data.props[0]
	check(lectern.cleanup.size()==2 and family.rect(lectern.cleanup[0].rect)==Rect2(1381,596,55,18) and family.rect(lectern.cleanup[1].rect)==Rect2(1381,614,55,4),"Floor restoration covers measured legacy outline and shadow, not merely the narrower new sprite")
	check(family.rect(lectern.cleanup[0].donorRect)==Rect2(1438,596,55,18) and family.rect(lectern.cleanup[1].donorRect)==Rect2(1483,614,20,4),"Both cleanup donors use same-height current-time floor and avoid the next desk row")
	for time_id:String in ["2245_opening","2245_maintenance","0754_blackout","1225_bakery","0755_morning"]:
		var plate:Texture2D=load("res://assets/rpg/interiors/finale/chapter4-755/states/a1_"+time_id+".png")
		family.configure("duan_yongping_temporal_maze","A1",plate);scene.sync()
		scene.configure_view(Vector2.ZERO,1,anchor_for_bottom(1406,620),0)
		check(family.active and family.plate==plate,"Cleanup and tint use current authored time plate "+time_id)
		var source_image:Image=plate.get_image()
		if source_image.is_compressed():source_image.decompress()
		var restored:Color=family.wall_composite.get_image().get_pixel((1400-1226)*3,(574-473)*3)
		check(restored.is_equal_approx(source_image.get_pixel(1457,574)),"Shelf behind new transparent silhouette uses same-time clean donor, never the old lectern "+time_id)
		for prop:Dictionary in family.data.props:
			var tint:Color=family.prop_tints[prop.id]
			check(scene.objects[prop.id].get_node("Appearance").modulate==tint,"Independent material tint reaches actual sprite "+str(prop.id)+" / "+time_id)
			if time_id.begins_with("2245") or time_id=="0754_blackout":
				check((tint.r+tint.g+tint.b)/3<.65,"No day-lit new prop during night/blackout "+str(prop.id)+" / "+time_id)
		scene.configure_view(Vector2.ZERO,1,anchor_for_bottom(1406,620),1)
		for prop:Dictionary in family.data.props:
			check(scene.objects[prop.id].get_node("Appearance").modulate==family.prop_tints[prop.id]*Color.WHITE.lerp(Color(.03,.15,.26),.3),"Dark mode applied exactly once "+str(prop.id))
	var original_plate:Texture2D=world.background
	family.configure("duan_yongping_temporal_maze","A1",original_plate);scene.sync()
	check(state.d==state_before and world.targets==targets_before,"Rendering leaves story, save state and authored target list unchanged")
	var matches:Array=world.targets.filter(func(t:Dictionary):return t.get("id","")=="a1_classroom_105_lectern_terminal")
	check(matches.size()==1,"One original lectern target, no duplicate generated interaction")
	if matches.size()==1:
		var target:Dictionary=matches[0]
		check(family.rect(target.bounds)==Rect2(1380,558,62,56) and target.radius==100 and target.mode=="light" and target.action=="c4_class105","Lectern bounds, range, mode and action remain source-authored")
		world.player=anchor_for_bottom(1406,630);world._try_interact(target)
		check(state.d.chapter4.factIds.has("classroom_105_terminal_replay_checked"),"Original near lectern interaction still reaches controller fact")
	check(world.targets.filter(func(t:Dictionary):return "bookcase" in str(t.get("id",""))).is_empty(),"Bookcase has no invented gameplay action")
	for floor_id:String in ["A2","A3"]:
		family.configure("duan_yongping_temporal_maze",floor_id,original_plate);scene.sync()
		check(not scene.visible and not scene.active and not family.active,"Independent render path is retired outside A1 "+floor_id)
		check(family.adjusted_collisions(source)==source,"Other floor collision remains source-only "+floor_id)
	world.queue_free();await frames(3)
	print("NORTH_INDEPENDENT_PROPS: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
