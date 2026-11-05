extends SceneTree
const Metrics=preload("res://scripts/player_metrics.gd")
const Rules=preload("res://scripts/space/spatial_rules.gd")
var checks:=0
var failures:=0
var world:Control
var state:Node
var output:=OS.get_environment("LIBRARY_OBJECT_CAPTURE_DIR")
class AssetSheet extends Control:
	var textures:Dictionary
	func _draw()->void:
		var ids:Array=textures.keys()
		for i:int in ids.size():
			var area:=Rect2((i%5)*300,(i/5)*250,300,250)
			for y:int in 15:
				for x:int in 18:draw_rect(Rect2(area.position+Vector2(x,y)*17,Vector2(17,17)),Color("d8dcd7") if (x+y)%2 else Color("b7c1bf"))
			var texture:Texture2D=textures[ids[i]]
			var factor:float=minf(250.0/texture.get_width(),205.0/texture.get_height())
			var extent:Vector2=texture.get_size()*factor
			draw_texture_rect(texture,Rect2(area.position+Vector2((300-extent.x)/2,12),extent),false)
			draw_rect(Rect2(area.position+Vector2(0,222),Vector2(300,28)),Color("23332f"))
			draw_string(ThemeDB.fallback_font,area.position+Vector2(10,242),str(ids[i]),HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("f6f1dc"))
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error("LIBRARY_OBJECT_SCENE "+label)
func stand(center:Vector2)->bool:return world.can_stand(center-Metrics.FOOT_CENTER_OFFSET)
func counter_contact()->void:
	var area:Rect2=world.library_layers.objects.areas.front_desk_counter
	world.capture_mode=false
	for sample:Array in [[Vector2(110,555),Vector2.RIGHT,"west"],[Vector2(535,555),Vector2.LEFT,"east"],[Vector2(334,704),Vector2.UP,"south"],[Vector2(120,623),Vector2.RIGHT,"west corner"],[Vector2(535,623),Vector2.LEFT,"east corner"]]:
		world.player=sample[0];world.move_target=Vector2.INF;world.touch_axis=sample[1];world._sync_player()
		check(world.can_stand(world.player),"counter approach starts on clear floor "+sample[2])
		for frame:int in 80:world._process(.016)
		world.touch_axis=Vector2.ZERO
		var feet:=Metrics.foot_rect(world.player)
		var aligned:=false
		match sample[2]:
			"west":aligned=feet.end.x<=area.position.x+.01
			"east":aligned=feet.position.x>=area.end.x-.01
			"south":aligned=feet.position.y>=area.end.y-.01
			"west corner":aligned=feet.end.x<=area.position.x+6
			"east corner":aligned=feet.position.x>=area.end.x-6
		check(world.can_stand(world.player) and world.player.distance_to(sample[0])>20 and aligned,"ordinary movement stops outside the painted cabinet "+sample[2])
		if sample[2]=="west":
			var at:Vector2=world.player
			world.touch_axis=Vector2.DOWN
			for frame:int in 30:world._process(.016)
			world.touch_axis=Vector2.ZERO
			check(world.can_stand(world.player) and absf(world.player.y-at.y-79.2)<.01,"walking along the side stays clear through its front corner")
	check(not stand(Vector2(area.position.x+3,590)) and not stand(Vector2(area.end.x-3,590)),"both former side gaps are solid")
	check(not stand(Vector2(area.position.x+12,655)) and not stand(Vector2(area.end.x-12,655)),"both former front-corner gaps are solid")
	world.capture_mode=true
func capture(id:String,center:Vector2,scale_value:float=1.0,focus:=Vector2(750,450))->void:
	if output.is_empty() or DisplayServer.get_name()=="headless":return
	world.player=center-Metrics.FOOT_CENTER_OFFSET
	world.transition_alpha=0
	world.camera=focus;world.zoom=scale_value;world._sync_player();world.queue_redraw()
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(id+".png"))
func run()->void:
	state=root.get_node("State");state.developer_mode=true;state.begin_checkpoint("c2-seat-arrival")
	state.d.native.positions={};state.d.native.scene="library_interior";state.d.rpgScene="library_interior";state.d.runtimeMode="rpg"
	root.size=Vector2i(1500,900)
	world=load("res://scripts/world.gd").new();world.size=Vector2(1500,900);root.add_child(world);world.set_process(false);world.capture_mode=true
	await process_frame
	var scene:RefCounted=world.library_layers.objects
	check(scene.ready,"complete sprite family and clean plate activate together")
	if not scene.ready:print(scene.issues);quit(1);return
	counter_contact()
	check(world.background==scene.clean_plate and world.background.get_size()==Vector2(1500,900),"real world uses exact source-sized empty plate")
	var record_read:bool=state.d.ui.libraryFinalsPuzzle.entranceRecordRead
	state.d.ui.libraryFinalsPuzzle.entranceRecordRead=false;world.refresh_world()
	await process_frame;await process_frame
	check(world._pick_target(Vector2(750,658)).get("id","")=="entrance_record","post-mounted reader owns its actual elevated screen")
	var entrance_target:Dictionary=world.targets.filter(func(target:Dictionary):return target.id=="entrance_record")[0]
	check(world._distance_at(entrance_target,Vector2(715,730))<=entrance_target.radius,"reader remains reachable on the first closed-door approach")
	check(not stand(Vector2(750,708)) and stand(Vector2(715,708)),"new reader post has a solid base and leaves the admission lane clear")
	check(world._pick_target(Vector2(700,720)).get("id","")=="entrance_record","closed glass door offers the same admission action as its reader")
	state.d.ui.libraryFinalsPuzzle.entranceRecordRead=true;world.refresh_world()
	check(not world.targets.any(func(target:Dictionary):return target.id=="entrance_record"),"acknowledged gate record stops offering its notification")
	state.d.ui.libraryFinalsPuzzle.entranceRecordRead=record_read;world.refresh_world()
	check(scene.snapshot().shelfSharesTexture,"evidence shelf uses the ordinary north-south stack artwork")
	var previous_right:=0.0
	for column:int in 9:
		var id:="north_display_shelf" if column==5 else "row_shelf_"+str(column)
		var area:Rect2=scene.areas[id]
		check(scene.rows[id].shelfNumber==column+1,"physical shelf number matches its column "+id)
		check(area.size.is_equal_approx(Vector2(45,231)) and area.position.y==85,"north-south stacks share size and rear alignment "+id)
		if column>0:check(area.position.x-previous_right>=37,"clear north-south aisle "+id)
		else:check(area.position.x==124,"west edge of stacks")
		previous_right=area.end.x
		check(stand(Vector2(area.get_center().x,120)) and not stand(Vector2(area.get_center().x,280)),"elevated rear permits feet behind the measured shelf base "+id)
		for side:int in [-1,1]:
			var edge:float=area.position.x if side<0 else area.end.x
			var outside:=Vector2(edge+side*Metrics.FOOT_SIZE.x/2,280)
			check(stand(outside) and not stand(outside-Vector2(side*3,0)),"feet stop at the painted upright "+id)
	check(previous_right==830,"east edge of stacks")
	var desk_back:Rect2=scene.areas.desk_back_1
	check(desk_back.position==Vector2(270,435) and desk_back.end.x==489 and desk_back.size.y>110,"enlarged desk cabinet meets rear and east boundaries")
	check(not scene.rows.has("southwest_display_shelf") and not scene.rows.has("southeast_display_shelf") and stand(Vector2(256,780)) and stand(Vector2(1190,780)),"both entrance cabinet locations are visibly and physically clear")
	var cooler:Rect2=scene.areas.water_dispenser
	var actor:=Metrics.visual_rect(Vector2.ZERO,world.display_scale_at(Vector2.ZERO))
	check(is_equal_approx(actor.size.y,66.56) and is_equal_approx(actor.end.y,Metrics.GROUND_OFFSET) and is_equal_approx(cooler.size.y,92) and cooler.end.y==788,"cooler doubles uniformly about its original foot point")
	check(scene.areas.reading_divider_shelf==Rect2(903,68,40,274),"divider fills its complete architectural edge")
	for index:int in range(1,5):
		var id:="reading_table_"+str(index)
		var table:Rect2=scene.areas[id]
		for side:String in ["north","south"]:
			var left:Rect2=scene.areas[id+"_"+side+"_left"]
			var right:Rect2=scene.areas[id+"_"+side+"_right"]
			check(absf((left.get_center().x+right.get_center().x)/2-table.get_center().x)<=.51 and left.size.x>26 and right.size.x>26,"paired seats center on their own table "+id+" "+side)
		check(is_equal_approx(scene.areas[id+"_west"].size.y,scene.areas[id+"_east"].size.y),"opposing seats share physical height "+id)
	for id:String in ["reading_table_1","reading_table_2","reading_table_3","reading_table_4","front_desk_counter"]:
		var intended:=Rules.rect(scene.rows[id].bounds)
		var drawn:Rect2=scene.areas[id]
		check(drawn.size.x/intended.size.x>.97 and drawn.size.y/intended.size.y>.97,"calibrated furniture silhouette fills its measured rectangle "+id)
	var wide_table:Rect2=scene.areas.reading_table_4
	check(wide_table.has_point(Vector2(1368,445)),"receipt's authored seam is on the real wide tabletop")
	check(scene.areas.reading_table_4_west.end.x>wide_table.position.x and scene.areas.reading_table_4_east.position.x<wide_table.end.x,"side chairs meet the wide table edges without detached gaps")
	for side:int in [515,845]:
		var first:Rect2=scene.areas["fixed_glass_"+str(side)+"_0"]
		var last:Rect2=scene.areas["fixed_glass_"+str(side)+"_3"]
		check(absf(first.position.x-side)<.01 and absf(last.end.x-(655 if side==515 else 986))<.01 and first.position.y==682 and last.end.y==825,"fixed glass paint covers its exact original solid edges "+str(side))
	for family:String in scene.textures:
		var image:Image=scene.textures[family].get_image()
		if image.is_compressed():image.decompress()
		var clear:=false;var solid:=false;var valid:=true
		for y:int in image.get_height():
			for x:int in image.get_width():
				var alpha:int=roundi(image.get_pixel(x,y).a*255)
				clear=clear or alpha==0;solid=solid or alpha==255
				valid=valid and (alpha in [0,255] or (family=="glass_panel" and alpha==170))
		check(clear and solid and valid,"verified real alpha "+family)
	check(stand(Vector2(985,135)),"old table bounding-box corner is visibly clear walkable floor")
	check(stand(Vector2(925,438)),"plant foliage does not form an invisible full-height wall")
	check(not stand(Vector2(950,494)),"same plant's visible pot base remains solid")
	check(not stand(Vector2(1063,233)),"table's real base remains solid")
	check(stand(Vector2(1063,185)),"elevated table top permits walking behind with feet on clear floor")
	check(Rules.in_front(scene.baseline("reading_table_1"),Vector2(1063,185)-Metrics.FOOT_CENTER_OFFSET),"same table occludes a player standing behind its ground contact")
	check(not Rules.in_front(scene.baseline("reading_table_1"),Vector2(1063,290)-Metrics.FOOT_CENTER_OFFSET),"same table stays behind a player in the front aisle")
	var before:=JSON.stringify(state.d)
	for target:Vector2 in [Vector2(1040,300),Vector2(1180,500),Vector2(625,355),Vector2(430,700),Vector2(715,650)]:
		check(world.can_stand(target),"library interaction approach remains reachable "+str(target))
	var obstacles:Array=world._floor_obstacles()
	var legal:=true
	for row:Dictionary in world.collisions:
		if not row.get("nativeLibraryObject",false):continue
		var rect:=Rules.rect(world.library_layers.replace_collision(row))
		legal=legal and obstacles.has(Rect2(rect.position-Metrics.foot_rect(Vector2.ZERO).end,rect.size+Metrics.FOOT_SIZE))
	check(legal,"pointer navigation uses the same generated-object feet as keyboard movement")
	check(JSON.stringify(state.d)==before,"all geometry queries preserve story and inventory")
	world.transition_alpha=0
	world.player=Vector2(1180,500);world._sync_player();world.queue_redraw()
	await process_frame;await process_frame
	check(world._pick_target(Vector2(1368,448)).get("id")=="seat_022_gap","visible table seam accepts the existing right-arrow interaction")
	state.d.ui.libraryFinalsPhase="evidence_gathering"
	state.d.ui.libraryFinalsPuzzle.backpackEvicted=true;state.d.items.callNumber755=true;state.d.ui.libraryFinalsPuzzle.callNumberCollected=true
	world.refresh_world();await process_frame;await process_frame
	var chair:Rect2=scene.areas.reading_table_4_south_right
	check(world._pick_target(chair.get_center()).get("id")=="seat_022_chair","visible 022 chair owns its ordinary click surface")
	var shelf:Rect2=scene.areas.north_display_shelf
	var book:Rect2=world.library_layers.book.geometry(scene).rect
	check(world._pick_target(book.get_center()).get("id")=="library_shelf_755","specific book spine owns the item-drop surface")
	check(world._pick_target(Vector2(shelf.get_center().x,shelf.position.y+20)).get("id","")!="library_shelf_755","unrelated parts of the same stack do not extract the book")
	var target:Dictionary=world._pick_target(book.get_center())
	if not target.is_empty():
		check(target.radius==64 and world._distance_at(target,Vector2(625,355))>target.radius,"no premature compartment prompt from the old display cabinet range at the entry checkpoint")
		check(world._distance_at(target,Vector2(603,230))<target.radius,"actual neighbouring aisle retains the controller's reach distance")
	state.d.ui.libraryFinalsPuzzle.backpackEvicted=false;world.library_layers.sync(state.d,true);world.refresh_world()
	await capture("library_objects_overview",Vector2(1100,300))
	await capture("library_actor_behind_table",Vector2(1063,185))
	await capture("library_actor_front_table",Vector2(1047,290))
	await capture("library_counter_west",Vector2(144,586),1.5,Vector2(340,610))
	await capture("library_entry_post",Vector2(715,750),1.3,Vector2(750,690))
	if not output.is_empty() and DisplayServer.get_name()!="headless":
		for dimensions:Vector2i in [Vector2i(1280,720),Vector2i(844,390)]:
			root.size=dimensions;world.size=Vector2(dimensions)
			await process_frame
			var zoom:float=dimensions.x/960.0
			var focus:=Vector2(755,dimensions.y/(2*zoom))
			await capture("library_shelf_aisle_"+str(dimensions.x),Vector2(667,300),zoom,focus)
	world.queue_free();await process_frame
	if not output.is_empty() and DisplayServer.get_name()!="headless":
		var sheet_height:int=ceili(scene.textures.size()/5.0)*250
		root.size=Vector2i(1500,sheet_height)
		var sheet:=AssetSheet.new();sheet.textures=scene.textures;sheet.size=Vector2(1500,sheet_height);root.add_child(sheet)
		await process_frame;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output.path_join("library_transparent_objects.png"))
		sheet.queue_free();await process_frame
	print("LIBRARY_OBJECT_SCENE ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
