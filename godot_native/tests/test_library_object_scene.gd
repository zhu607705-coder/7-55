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
func opaque_runs(image: Image, y: int) -> Array[Vector2i]:
	var runs: Array[Vector2i] = []
	var left := -1
	for x: int in range(image.get_width() + 1):
		var painted := x < image.get_width() and image.get_pixel(x, y).a > .5
		if painted and left < 0: left = x
		elif not painted and left >= 0:
			runs.append(Vector2i(left, x - left))
			left = -1
	return runs
func counter_contact()->void:
	var area:Rect2=world.library_layers.objects.areas.front_desk_counter
	world.capture_mode=false
	for sample:Array in [[Vector2(110,555),Vector2.RIGHT,"west"],[Vector2(535,555),Vector2.LEFT,"east"],[Vector2(334,704),Vector2.UP,"south"],[Vector2(126,623),Vector2.RIGHT,"west corner"],[Vector2(535,623),Vector2.LEFT,"east corner"]]:
		world.player=sample[0];world.move_target=Vector2.INF;world.touch_axis=sample[1];world._sync_player()
		check(world.can_stand(world.player),"counter approach starts on clear floor "+sample[2])
		for frame:int in 80:world._process(.016)
		world.touch_axis=Vector2.ZERO
		var feet:=Metrics.foot_rect(world.player,world.scene_id)
		var aligned:=false
		match sample[2]:
			"west","west corner":aligned=absf(feet.end.x-area.position.x)<.002
			"east","east corner":aligned=absf(feet.position.x-area.end.x)<.002
			"south":aligned=absf(feet.position.y-area.end.y)<.002
		check(world.can_stand(world.player) and world.player.distance_to(sample[0])>10 and aligned,"the full-width foot stops at the cabinet side "+sample[2])
		if sample[2] in ["west","east"]:
			var at:Vector2=world.player
			world.touch_axis=Vector2.DOWN
			for frame:int in 36:world._process(.016)
			check(world.can_stand(world.player) and absf(world.player.y-at.y-95.04)<.01,"walking along the cabinet clears the front corner "+sample[2])
			world.touch_axis=sample[1]
			for frame:int in 10:world._process(.016)
			world.touch_axis=Vector2.ZERO
			check(world.can_stand(world.player) and absf(world.player.x-at.x-26.4*sample[1].x)<.01,"can turn along the front aisle after clearing the corner "+sample[2])
	check(not stand(Vector2(area.position.x+3,590)) and not stand(Vector2(area.end.x-3,590)),"both former side gaps are solid")
	check(not stand(Vector2(area.position.x+12,655)) and not stand(Vector2(area.end.x-12,655)),"both former front-corner gaps are solid")
	world.capture_mode=true
func check_rear_contact(center:Vector2,edge:float,label:String)->void:
	var start:=Metrics.anchor_from_foot_center(center)
	check(world.can_stand(start),label+" approach is open")
	var stopped:Vector2=world._axis_destination(start,Vector2(0,edge-center.y+24))
	check(world.can_stand(stopped) and absf(Metrics.foot_rect(stopped,world.scene_id).end.y-edge)<.002 and not world.can_stand(stopped+Vector2.DOWN),label+" stops at the measured ground edge")

func check_east_contact(center:Vector2,edge:float,label:String)->void:
	var start:=Metrics.anchor_from_foot_center(center)
	var stopped:Vector2=world._axis_destination(start,Vector2(edge-center.x-24,0))
	var feet:=Metrics.foot_rect(stopped,world.scene_id)
	check(world.can_stand(start) and world.can_stand(stopped) and absf(feet.position.x-edge)<.002 and not world.can_stand(stopped+Vector2.LEFT),label+" keeps the body outside the painted side")

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
	check(scene.areas.keys().all(func(id:String):return scene.areas[id]==scene.geometry(id).rect),"all fitted objects share the registered paint pixel grid")
	var counter:Rect2=scene.areas.front_desk_counter
	check(stand(counter.position+Vector2(30,25)) and not stand(counter.position+Vector2(30,37)),"the approach behind the raised arm remains open to its measured rear ground edge")
	check(Rules.depth_in_front(scene.baseline("front_desk_counter"),666) and not Rules.depth_in_front(scene.baseline("front_desk_counter"),667),"the whole cabinet follows its original front edge")
	var measured_width:=Metrics.foot_size(world.scene_id).x
	var body_fits:=measured_width==36.0
	for direction:String in ["down","up","side"]:
		var poses:Array=world.library_layers.animations.walks[direction].duplicate()
		poses.append(world.library_layers.animations.idles[direction])
		for texture:Texture2D in poses:
			var top:Rect2i=texture.get_image().get_region(Rect2i(0,0,96,104)).get_used_rect()
			var radius:=maxi(48-top.position.x,top.end.x-48)*Metrics.DISPLAY_SCALE
			body_fits=body_fits and radius<=measured_width/2
	check(body_fits,"the collision width covers the upper body in every actual library walk and idle frame")
	var catalog:Rect2=scene.areas.catalog_desk
	check_rear_contact(Vector2(catalog.end.x-16,525),555,"catalog table")
	check_east_contact(Vector2(773,597),catalog.end.x,"catalog table")
	check_east_contact(Vector2(539,536),scene.areas.desk_back_1.end.x,"desk bookcase")
	check_rear_contact(Vector2(820,548),576.56,"printer's original rear edge")
	var previous_side:=Metrics.anchor_from_foot_center(Vector2(493,619))
	var recovered:Vector2=world._find_safe(previous_side)
	check(not world.can_stand(previous_side) and world.can_stand(recovered) and recovered.x>=counter.end.x+measured_width/2,"an old side position recovers to the same outside aisle")
	var worktop:Rect2=scene.table_surface("front_desk_counter")
	var terminal:Rect2=scene.geometry("desk_terminal").rect
	var terminal_x:=terminal.get_center().x
	check(worktop.has_point(Vector2(terminal_x,terminal.position.y+terminal.size.y*.75)) and worktop.has_point(Vector2(terminal_x,terminal.end.y-1)),"monitor stand and keyboard sit on the front worktop")
	var service:Transform2D=world.library_layers.desk_service_transform()
	var idle:Dictionary=world.library_layers.stamp_pose()
	check(worktop.has_point(service*Vector2(idle.stampBottom)),"idle stamp foot sits on the usable worktop")
	var stamp_point:=service*(Vector2(idle.stampRect.position)+Vector2(idle.stampRect.size)*Vector2(.5,.25))
	check(str(world._pick_target(stamp_point).get("id","")) in ["front_desk","identity_machine"],"the relocated stamp is picked at its visible handle")
	var stamp_motion=preload("res://scripts/presentation/library_stamp_motion.gd")
	for phase_ms:float in [0.0,340.0,1080.0,1400.0]:
		var sample:Dictionary=stamp_motion.sample(phase_ms,-1)
		var sheet:=Rect2(Vector2(sample.paper)-Vector2(sample.paperSize)/2,Vector2(sample.paperSize))
		check(worktop.encloses(service*sheet) and worktop.has_point(service*Vector2(sample.stampBottom)),"stamp and report keep tabletop contact through "+str(phase_ms))
	check(world.background==scene.clean_plate and world.background.get_size()==Vector2(1500,900),"real world uses exact source-sized empty plate")
	check(world.texture_filter==CanvasItem.TEXTURE_FILTER_NEAREST,"library paint bypasses the SubViewport linear default")
	for id: String in scene.rows:
		var geometry: Dictionary = scene.geometry(id)
		var display: Rect2 = geometry.rect
		var source: Rect2 = geometry.source
		check(display.position == display.position.round() and display.size == source.size and source.size == scene.areas[id].size.round(),"same world pixel grid for " + id)
	check(scene.geometry("north_display_shelf").texture == scene.geometry("row_shelf_0").texture,"ordinary and interactive stacks share their actual raster tile")
	var rail: Rect2 = scene.areas.diagonal_rail
	var sample_y := rail.position.y + rail.size.y * .75
	check(not Rules.depth_in_front(scene.baseline_at("diagonal_rail", rail.position.x + 6),sample_y),"actor at the outer end of the sloped railing is in front")
	check(Rules.depth_in_front(scene.baseline_at("diagonal_rail", rail.end.x - 6),sample_y),"same foot Y on the carpet side is behind the railing")
	check(not stand(rail.position + rail.size * Vector2(.91,.98)),"end post blocks feet down to the painted ground contact")
	for chair_id: String in world.library_layers.CHAIR_IDS:
		var approach: Vector2 = world.library_layers.chair_approach(chair_id)
		var chair: Rect2 = scene.areas[world.library_layers.CHAIR_IDS[chair_id]]
		check(world.can_stand(approach) and not stand(chair.get_center()+Vector2(0,chair.size.y*.4)),"chair has a solid foot and a reachable rear approach "+chair_id)
	var record_read:bool=state.d.ui.libraryFinalsPuzzle.entranceRecordRead
	state.d.ui.libraryFinalsPuzzle.entranceRecordRead=false;world.refresh_world()
	await process_frame;await process_frame
	check(world._pick_target(world.library_gate.reader_rect(0).get_center()).get("id","")=="entrance_record","cabinet reader owns its actual elevated screen")
	var entrance_target:Dictionary=world.targets.filter(func(target:Dictionary):return target.id=="entrance_record")[0]
	check(world._distance_at(entrance_target,Vector2(715,842))<=entrance_target.radius,"reader is reachable from the authored entrance spawn")
	check(stand(Vector2(750,708)) and stand(Vector2(750,806)),"retired reader base and raised turnstile top leave floor behind")
	for index:int in 3:
		var cabinet:Rect2=scene.areas["entrance_turnstile_%d"%index]
		check_rear_contact(Vector2(cabinet.get_center().x,765),836,"turnstile "+str(index))
	check(world._pick_target(world.library_gate.reader_rect(1).get_center()).get("id","")=="entrance_record_east","each lane has its own physical reader")
	state.d.ui.libraryFinalsPuzzle.entranceRecordRead=true;world.refresh_world()
	check(world.targets.any(func(target:Dictionary):return target.id=="entrance_record" and target.label=="刷卡入馆"),"acknowledged record leaves a reusable card reader")
	state.d.ui.libraryFinalsPuzzle.entranceRecordRead=record_read;world.refresh_world()
	check(scene.snapshot().shelfSharesTexture,"evidence shelf uses the ordinary north-south stack artwork")
	var previous_right:=0.0
	for column:int in 9:
		var id:="north_display_shelf" if column==5 else "row_shelf_"+str(column)
		var area:Rect2=scene.areas[id]
		check(scene.rows[id].shelfNumber==column+1,"physical shelf number matches its column "+id)
		check(area.size.is_equal_approx(Vector2(45,231)) and area.position.y==85,"north-south stacks share size and rear alignment "+id)
		if column>0:check(area.position.x-previous_right>=37,"clear north-south aisle "+id)
		else:check(area.position.x==122,"west shelf bank leaves room for the sliding shelf's shake")
		previous_right=area.end.x
		check(stand(Vector2(area.get_center().x,120)) and not stand(Vector2(area.get_center().x,280)),"elevated rear permits feet behind the measured shelf base "+id)
		for side:int in [-1,1]:
			var edge:float=area.position.x if side<0 else area.end.x
			var outside:=Vector2(edge+side*measured_width/2,280)
			check(stand(outside) and not stand(outside-Vector2(side*3,0)),"shoulders clear the painted upright "+id)
	check(previous_right==847,"east shelf bank leaves room for the sliding shelf's final pose")
	var desk_back:Rect2=scene.areas.desk_back_1
	check(desk_back.position==Vector2(270,435) and desk_back.end.x==489 and desk_back.size.y>110,"enlarged desk cabinet meets rear and east boundaries")
	check(not scene.rows.has("southwest_display_shelf") and not scene.rows.has("southeast_display_shelf") and stand(Vector2(256,780)) and stand(Vector2(1190,780)),"both entrance cabinet locations are visibly and physically clear")
	var cooler:Rect2=scene.areas.water_dispenser
	var actor:=Metrics.visual_rect(Vector2.ZERO,world.display_scale_at(Vector2.ZERO))
	check(is_equal_approx(actor.size.y,Metrics.FRAME.y*Metrics.DISPLAY_SCALE) and is_equal_approx(actor.end.y,Metrics.GROUND_OFFSET) and is_equal_approx(cooler.size.y,92) and cooler.end.y==788,"library player uses indoor size and keeps the calibrated floor anchor")
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
	for id: String in ["reading_table_1", "reading_table_4", "catalog_desk"]:
		var table: Image = scene.geometry(id).texture.get_image()
		var upper := table.get_region(Rect2i(0, table.get_height() / 4, table.get_width(), 1)).get_used_rect()
		var lower := table.get_region(Rect2i(0, table.get_height() / 2, table.get_width(), 1)).get_used_rect()
		var foot_row := table.get_height() * 9 / 10
		check(upper.size.x >= table.get_width() - 2 and abs(upper.size.x - lower.size.x) <= 1 and abs(upper.position.x - lower.position.x) <= 1,"tabletop stays orthographic " + id)
		check(table.get_pixel(table.get_width() / 2, foot_row).a == 0 and table.get_region(Rect2i(0, foot_row, table.get_width(), 1)).get_used_rect().size.x > table.get_width() / 2,"complete table has legs and a transparent opening " + id)
		var upper_supports := opaque_runs(table, table.get_height() * 4 / 5)
		var feet := opaque_runs(table, table.get_height() - 1)
		check(upper_supports.size() == 2 and upper_supports == feet and absi(feet[0].y - feet[1].y) <= 1,"table legs stay vertical and parallel from apron to floor " + id)
	var picker := preload("res://scripts/world_object_picker.gd").new()
	var seat_id := "reading_table_4_south_right"
	var seat_point: Vector2 = scene.seat_point(seat_id)
	check(picker.contains(scene.geometry(seat_id,Vector2.ZERO,"seat"),seat_point) and not picker.contains(scene.geometry(seat_id,Vector2.ZERO,"back"),seat_point),"sitting point is on the seat plane with a separate backrest")
	var chair_pixels: Image = scene.geometry(seat_id).texture.get_image()
	var ink := chair_pixels.get_used_rect()
	var upper_legs := opaque_runs(chair_pixels, ink.position.y + floori(ink.size.y * .79))
	var lower_legs := opaque_runs(chair_pixels, ink.end.y - 1)
	check(upper_legs.size() == 2 and upper_legs == lower_legs and upper_legs[0].y == upper_legs[1].y,"both front legs have constant width and aligned feet with a transparent gap")
	var chair_back: Image = scene.geometry(seat_id,Vector2.ZERO,"back").texture.get_image()
	var center_x := ink.get_center().x
	var upper_slat := ink.position.y + floori(ink.size.y * .15)
	var seat_strip := ink.position.y + floori(ink.size.y * .24)
	var lower_slat := ink.position.y + floori(ink.size.y * .32)
	check(chair_back.get_pixel(center_x, upper_slat).a == 1 and chair_back.get_pixel(center_x, seat_strip).a == 0 and chair_back.get_pixel(center_x, lower_slat).a == 1,"two separate backrest slats leave the seat visible between them")
	var upper_span := opaque_runs(chair_back, upper_slat)
	var lower_span := opaque_runs(chair_back, lower_slat)
	check(upper_span == [Vector2i(0, chair_back.get_width())] and lower_span == upper_span,"both backrest slats reach the same two posts")
	var outline_rows: Array[int] = []
	for row in range(1, chair_back.get_height()):
		var opaque := chair_back.get_pixel(center_x, row).a == 1
		if opaque != (chair_back.get_pixel(center_x, row - 1).a == 1):
			outline_rows.append(row if opaque else row - 1)
	var ink_color := Color("202b35").to_rgba32()
	check(outline_rows.size() == 4 and outline_rows.all(func(row: int) -> bool: return chair_back.get_pixel(center_x, row).to_rgba32() == ink_color),"both slat edges survive map-scale sampling")
	check(outline_rows.size() == 4 and outline_rows[1] - outline_rows[0] >= 6 and outline_rows[3] - outline_rows[2] >= 5,"exterior ink preserves both slat faces at map scale")
	var seat_pixels: Image = scene.geometry(seat_id, Vector2.ZERO, "seat").texture.get_image()
	var seat_row := ink.position.y + floori(ink.size.y * .56)
	var seat_span := opaque_runs(seat_pixels, seat_row)
	var post_spans := opaque_runs(chair_back, seat_row)
	var seat_fits_behind := false
	if post_spans.size() == 2 and seat_span.size() == 1:
		var left_edge := post_spans[0].x + post_spans[0].y
		seat_fits_behind = seat_span[0] == Vector2i(left_edge, post_spans[1].x - left_edge)
	check(post_spans == lower_legs and seat_fits_behind,"full seat meets the post edges from behind without covering them")
	var opposite_chair: Image = scene.textures["chair_south"].get_image()
	var opposite_row := floori(opposite_chair.get_height() * .93)
	var opposite_legs := opaque_runs(opposite_chair, opposite_row)
	var wood_row := ink.position.y + floori(ink.size.y * .85)
	var matching_leg_faces := opposite_legs.size() == 2 and lower_legs.size() == 2
	if matching_leg_faces:
		for side in 2:
			var reference: Vector2i = opposite_legs[side]
			var leg: Vector2i = lower_legs[side]
			var reference_wood := 0
			var visible_wood := 0
			for x in range(reference.x, reference.x + reference.y):
				reference_wood += int(opposite_chair.get_pixel(x, opposite_row).to_rgba32() != ink_color)
			for x in range(leg.x, leg.x + leg.y):
				visible_wood += int(chair_pixels.get_pixel(x, wood_row).to_rgba32() != ink_color)
			matching_leg_faces = matching_leg_faces and visible_wood >= roundi(reference_wood * float(chair_pixels.get_width()) / opposite_chair.get_width())
	check(matching_leg_faces,"exterior post ink leaves the same wood width as the opposite chair")
	for prop: String in ["reading_table_1_lamp", "reading_table_4_book", "catalog_terminal"]:
		var owner: String = scene.rows[prop].depthOwner
		var area: Rect2 = scene.geometry(prop).rect
		check(scene.table_surface(owner).has_point(Vector2(area.get_center().x,area.end.y - 1)) and scene.baseline(prop)==scene.baseline(owner),"tabletop contact and depth agree " + prop)
	var wide_table:Rect2=scene.areas.reading_table_4
	check(absf(scene.areas.catalog_terminal_chair.get_center().x-scene.areas.catalog_terminal.get_center().x)<1,"catalog seat aligns with monitor center")
	check(wide_table.has_point(Vector2(1368,445)),"receipt's authored seam is on the real wide tabletop")
	check(scene.areas.reading_table_4_west.end.x>wide_table.position.x and scene.areas.reading_table_4_east.position.x<wide_table.end.x,"side chairs meet the wide table edges without detached gaps")
	check(not scene.textures.has("glass_panel"),"no side glass is mounted in the object layer")
	for x:float in [580.,910.]:
		check(stand(Vector2(x,750)),"former side glass leaves a clear approach floor "+str(x))
		check(not stand(Vector2(x,world.library_gate.axis_y)),"solid low guardrail closes the bypass "+str(x))
	for family:String in scene.textures:
		var image:Image=scene.textures[family].get_image()
		if image.is_compressed():image.decompress()
		var clear:=false;var solid:=false;var valid:=true
		for y:int in image.get_height():
			for x:int in image.get_width():
				var alpha:int=roundi(image.get_pixel(x,y).a*255)
				clear=clear or alpha==0;solid=solid or alpha==255
				valid=valid and alpha in [0,255]
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
		var feet:=Metrics.foot_rect(Vector2.ZERO,world.scene_id)
		legal=legal and obstacles.has(Rect2(rect.position-feet.end,rect.size+feet.size))
	check(legal,"pointer navigation uses the same generated-object feet as keyboard movement")
	check(JSON.stringify(state.d)==before,"all geometry queries preserve story and inventory")
	world.transition_alpha=0
	world.player=Vector2(1180,500);world._sync_player();world.queue_redraw()
	await process_frame;await process_frame
	var seam: Vector2 = world.library_layers.receipt_anchor()
	check(scene.table_surface("reading_table_4").has_point(seam+Vector2(13,3)) and world._pick_target(seam+Vector2(0,3)).get("id")=="seat_022_gap","visible table seam stays inside the tabletop and accepts the right arrow")
	state.d.ui.libraryFinalsPhase="evidence_gathering"
	state.d.ui.libraryFinalsPuzzle.backpackEvicted=true;state.d.items.callNumber755=true;state.d.ui.libraryFinalsPuzzle.callNumberCollected=true
	world.refresh_world();await process_frame;await process_frame
	check(world._pick_target(seat_point).get("id")=="seat_022_chair","visible 022 seat owns its ordinary click surface")
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
	await capture("library_counter_west",Vector2(137,586),1.5,Vector2(340,610))
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
