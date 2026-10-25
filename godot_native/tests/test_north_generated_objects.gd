extends SceneTree
## Isolated A1 geometry regression: rendered bases, real player body, safe fallbacks.
const Objects=preload('res://scripts/presentation/north_generated_objects.gd')
const Metrics=preload('res://scripts/player_metrics.gd')
var checks:=0
var failures:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func frames(n:=2)->void:
	for i in n:await process_frame
func anchor_for_feet(center:Vector2)->Vector2:return center-Metrics.FOOT_CENTER_OFFSET
func run()->void:
	var expected:=OS.get_environment('GODOT_TEST_USER_DATA_DIR').simplify_path().trim_suffix('/')
	if expected.is_empty() or OS.get_user_data_dir().simplify_path().trim_suffix('/')!=expected:
		push_error('Disposable save profile required');quit(2);return
	var state:Node=root.get_node('State');state.developer_mode=true;state.begin_checkpoint('c4-755-hall-clock')
	state.d.chapter4.timeState='0755_morning';state.d.chapter4.mode='light';state.d.native.mode='light'
	var world:Control=load('res://scripts/world.gd').new();world.size=Vector2(1280,720);root.add_child(world);world.set_process(false);await frames()
	var objects:RefCounted=world.north_objects
	check(objects.active and objects.data.desks.size()==24,'A1 loads exactly 24 authored desk instances')
	var original:Array=world.spec.layout.floors[0].staticCollisions.duplicate(true)
	var source_copy:Array=original.duplicate(true)
	var adapted:Array=objects.adjusted_collisions(original)
	check(original==source_copy,'Art adapter never mutates source collision data')
	check(adapted.size()==original.size()+24,'Table and chair bases replace each single old tabletop box')
	check(objects.adjusted_collisions(adapted)==adapted,'Reapplying adapter cannot duplicate physical bases')
	var replaced:Array=[]
	for object:Dictionary in objects.data.desks:replaced.append(object.sourceCollisionId)
	for box:Dictionary in original:
		if box.get('id','') not in replaced:check(box in adapted,'Non-desk source wall/gate remains unchanged: '+str(box.get('id','')))
	var colors:Dictionary={}
	var image:Image=objects.desk_texture.get_image()
	if image.is_compressed():image.decompress()
	for y in image.get_height():
		for x in image.get_width():
			var pixel:Color=image.get_pixel(x,y)
			if pixel.a>0:colors[pixel.to_html(false)]=true
	check(colors.size()<=6,'Legacy collision-reference desk retains original palette (not rendered as the new desk)')
	for object:Dictionary in objects.data.desks:
		var graphic:Rect2=objects.desk_rect(object);var bases:Array=objects.desk_solids(object)
		check(is_equal_approx(graphic.size.x/240,graphic.size.y/279),'Each prop preserves uniform source scale')
		check(is_equal_approx(graphic.end.y,float(object.baselineY)),'Visible chair feet meet registered ground line')
		for base:Rect2 in bases:
			check(graphic.encloses(base),'Solid base stays inside visible prop extent')
			check(not world.can_stand(anchor_for_feet(base.get_center())),'Real foot box stops inside table/chair base')
		var old_box:Dictionary=original.filter(func(box:Dictionary):return box.get('id','')==object.sourceCollisionId)[0]
		var old_area:=Rect2(float(old_box.x),float(old_box.y),float(old_box.width),float(old_box.height))
		check(world.can_stand(anchor_for_feet(old_area.get_center())),'Painted tabletop face no longer creates an elevated invisible wall')
		var side:Vector2=anchor_for_feet(Vector2(graphic.end.x+13,graphic.end.y-16))
		check(world.can_stand(side),'Clear aisle beside desk remains walkable '+str(object.id)+' '+str(side))
	# Exercise live swept movement against the same geometry used by rendering.
	var first:Dictionary=objects.data.desks[1];var base:Rect2=objects.desk_solids(first)[0]
	var start:Vector2=anchor_for_feet(Vector2(base.position.x-Metrics.FOOT_SIZE.x/2-3,base.get_center().y))
	check(world.can_stand(start),'Sweep starts in clear aisle')
	var stop:Vector2=world._c4_axis_destination(start,Vector2(100,0))
	check(stop.x>start.x and absf(Metrics.foot_rect(stop).end.x-base.position.x)<.01,'Swept body meets visible table base without tunnelling')
	check(world.can_stand(stop) and not world.can_stand(stop+Vector2(.02,0)),'Contact separates at source edge rather than a large gap')
	var chair:Rect2=objects.desk_solids(first)[1]
	start=anchor_for_feet(Vector2(chair.get_center().x,chair.end.y+Metrics.FOOT_SIZE.y/2+3))
	check(world.can_stand(start),'Reverse sweep starts beyond chair')
	stop=world._c4_axis_destination(start,Vector2(0,-50))
	check(absf(Metrics.foot_rect(stop).position.y-chair.end.y)<.01,'Upward movement stops at visible chair feet')
	check(world.can_stand(anchor_for_feet(Vector2(1308,552))),'Partition painted face remains walk-behind space')
	check(not world.can_stand(anchor_for_feet(Vector2(1308,590))),'Authored solid partition base still blocks')
	check(objects.wall_in_front(anchor_for_feet(Vector2(1308,552))),'A legal stand behind the wall receives source 22 percent reveal')
	var wall_contact:=Vector2(1308,545)
	check(Metrics.foot_rect(wall_contact).end.y==float(objects.data.wall.baselineY),'Regression fixture touches the authored wall baseline exactly')
	for offset:float in [-.02,0.0,.02]:
		var at:Vector2=wall_contact+Vector2(0,offset)
		check(world.can_stand(at)==(offset<=0),'Wall contact preserves the source collision boundary at '+str(offset))
		check(objects.wall_in_front(at)==(offset<=0),'Wall remains in front through exact contact, but not beyond its baseline at '+str(offset))
	var wall_stop:Vector2=world._c4_axis_destination(wall_contact-Vector2(0,3),Vector2(0,10))
	check(world.can_stand(wall_stop) and absf(Metrics.foot_rect(wall_stop).end.y-float(objects.data.wall.baselineY))<.01,'Actual downward sweep stops at the authored partition base')
	check(objects.wall_in_front(wall_stop),'Swept wall contact retains the foreground reveal instead of popping behind the player')
	check(not objects.wall_in_front(anchor_for_feet(Vector2(1308,605))),'Standing beyond solid base renders player fully in front')
	var floor:Dictionary=world.spec.layout.floors[0]
	check(world.can_stand(Vector2(float(floor.safeSpawn.x),float(floor.safeSpawn.y))),'Authored A1 safe spawn remains legal')
	var plate:Texture2D=world.background
	var fallback:RefCounted=Objects.new();fallback.data=fallback.data.duplicate(true);fallback.data.desk.texture='res://missing_north_object_for_test.png'
	fallback.configure('duan_yongping_temporal_maze','A1',plate)
	check(not fallback.active and fallback.adjusted_collisions(original)==original,'Missing chapter art preserves whole original scene and collision together')
	var inactive:RefCounted=Objects.new();inactive.configure('duan_yongping_temporal_maze','A2',plate)
	check(not inactive.active and inactive.desk_texture==null and inactive.wall_texture==null,'A2 does not load or replace A1 art')
	var before:Dictionary=state.d.duplicate(true)
	objects.configure('duan_yongping_temporal_maze','A1',plate);var composite_id:int=objects.wall_composite.get_instance_id()
	objects.configure('duan_yongping_temporal_maze','A1',plate)
	check(objects.wall_composite.get_instance_id()==composite_id,'Same time plate reuses composed wall rather than rebuilding every refresh')
	check(state.d==before,'Presentation and collision calibration never write progression')
	for time_id:String in ['2245_opening','2245_maintenance','0754_blackout','1225_bakery','0755_morning']:
		var time_plate:Texture2D=load('res://assets/rpg/interiors/finale/chapter4-755/states/a1_'+time_id+'.png')
		objects.configure('duan_yongping_temporal_maze','A1',time_plate)
		check(objects.active,'Generated family remains available for '+time_id)
		var tint:Color=objects.desk_tints[objects.data.desks[0].id]
		if time_id.begins_with('2245') or time_id=='0754_blackout':
			check((tint.r+tint.g+tint.b)/3<.65,'Night desk adopts source time lighting '+time_id)
			check((objects.wall_tint.r+objects.wall_tint.g+objects.wall_tint.b)/3<.65,'Night wall adopts source time lighting '+time_id)
		var source_image:Image=time_plate.get_image()
		if source_image.is_compressed():source_image.decompress()
		var clue:Color=objects.wall_composite.get_image().get_pixel((1324-1226)*3,(574-473)*3)
		check(clue.is_equal_approx(source_image.get_pixel(1324,574)),'Preserved chalk shelf pixels do not receive generated-material tint twice '+time_id)
	objects.configure('theater_interior','',plate)
	check(not objects.active and objects.adjusted_collisions(original)==original,'Leaving A1 restores source-only collision behavior')
	world.queue_free();await frames(3)
	print('NORTH_GENERATED_OBJECTS: %d checks; %d failures'%[checks,failures]);quit(1 if failures else 0)
