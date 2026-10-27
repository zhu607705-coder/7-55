extends SceneTree
const Rules=preload("res://scripts/space/spatial_rules.gd")
const Space=preload("res://scripts/space/world_space.gd")
const PolygonGround=preload("res://scripts/space/polygon_ground.gd")
const Body=preload("res://scripts/player_metrics.gd")
var checks:=0
var failures:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error("WORLD_SPACE: "+label)
func polygon(area:Rect2)->PackedVector2Array:
	return PackedVector2Array([area.position,Vector2(area.end.x,area.position.y),area.end,Vector2(area.position.x,area.end.y)])
func run()->void:
	create_timer(40).timeout.connect(func():push_error("WORLD_SPACE watchdog");quit(2))
	var ground:RefCounted=PolygonGround.new()
	ground.configure([polygon(Rect2(0,0,10,20)),polygon(Rect2(10,0,10,20))],3)
	check(ground.allows_circle(Vector2(10,10)),"adjacent paving has no imaginary wall at its internal seam")
	check(not ground.allows_circle(Vector2(2.9,10)) and ground.allows_circle(Vector2(3,10)),"full original circle stops at exact outer ground contact")
	ground.configure([polygon(Rect2(0,0,20,8)),polygon(Rect2(0,8,8,12)),polygon(Rect2(12,8,8,12)),polygon(Rect2(8,12,4,8))],3)
	check(not ground.allows_circle(Vector2(7.5,7.5)),"diagonal paving hole is rejected even when five old samples lie on ground")
	ground.configure([PackedVector2Array([Vector2(757.93,921.99),Vector2(762.93,886.99),Vector2(749.07,885.01),Vector2(744.07,920.01)])],3)
	check(not ground.allows_circle(Vector2(749,887)),"oblique source edge remains a boundary despite inclusive point-in-polygon tolerance")
	check(ground.allows_circle(Vector2(754,900)),"the centre of the same oblique paving remains open")
	var bits:=PackedByteArray();bits.resize(32);bits.fill(255);bits[8]&=~(1<<7)
	var definition:={"cellSize":1,"gridWidth":16,"gridHeight":16}
	check(not Rules.mask_allows_rect(Rect2(4,2,8,8),bits,definition),"full source mask catches an interior blocked pixel missed by corners and centre")
	bits.fill(255)
	check(Rules.mask_allows_rect(Rect2(4,2,8,8),bits,definition),"unchanged clear source mask remains open")
	check(not Rules.covered_by_rects(Rect2(1,1,8,8),[Rect2(0,0,4,10),Rect2(6,0,4,10)]),"whole physical body cannot bridge a ground slit")
	check(Rules.depth_in_front(264,264) and not Rules.in_front(264,Vector2(400,250)),"all depth comparisons use contact feet, including equality")
	var stopped:=Rules.sweep_axis(Vector2(10,10),Vector2(1000,0),func(p:Vector2):return p.x+3<=50 or p.x-3>=51,1)
	check(stopped.x<=47.001 and stopped.x>=46.999,"continuous movement cannot skip a thin wall during a large frame")
	var lake_space:RefCounted=Space.new()
	var lake_spec:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/worlds.json")).worlds.qizhen_lake
	lake_space.configure("qizhen_lake",lake_spec,{"qizhenLake":{"zone":"dock","currentZone":"open_water","vehicle":"kayak"}},Rect2(0,0,1672,941))
	check(lake_space.variant=="qizhen_lake:open_water:kayak" and lake_space.regions[0]==Rules.rect(lake_spec.zones.open_water.waterAreas[0]),"legacy rendered-zone alias cannot select a different collision basin than the visible source plate")
	var state:Node=root.get_node("State");state.developer_mode=true;state.begin_checkpoint("c4-755-room204-1850")
	var world:Control=load("res://scripts/world.gd").new();world.size=Vector2(960,540);root.add_child(world);world.set_process(false)
	check(world.world_space.data.scenes.size()==world.worlds.size() and world.worlds.keys().all(func(id:String):return world.world_space.data.scenes.has(id)),"every formal map has an explicit spatial registration")
	var cases:Array=[]
	for scene:String in ["dorm_hub","campus_bootstrap","library_interior","canteen_interior","theater_interior","campus_qizhen_loop"]:cases.append({"scene":scene})
	for floor_id:String in ["A1","A2","A3"]:cases.append({"scene":"duan_yongping_temporal_maze","floor":floor_id})
	for zone:String in ["dock","open_water","channel","swan_cove"]:cases.append({"scene":"qizhen_lake","zone":zone,"vehicle":"kayak"})
	cases.append({"scene":"qizhen_lake","zone":"dock","vehicle":"on_foot"})
	for row:Dictionary in cases:
		state.d.native.scene=row.scene;state.d.rpgCheckpoint="";state.d.native.positions={}
		if row.has("floor"):state.d.chapter4.floor=row.floor
		if row.has("zone"):state.d.qizhenLake.zone=row.zone;state.d.qizhenLake.vehicle=row.vehicle
		world.scene_id="";world.world_key="";world.refresh_world()
		var label:String=world.world_space.variant
		check(world.world_space.active,label+" registers one common ground authority")
		check(world.can_stand(world.player),label+" actual safe spawn remains physically valid")
		var body:Rect2=world.kayak_collision_rect(world.player,world.kayak.heading) if world.kayak else Body.foot_rect(world.player)
		check(world.world_space.allows_body(body),label+" complete physical body stays on source ground/water")
		check(not world.can_stand(Vector2(0,0)),label+" outer north-west perimeter blocks full body")
		var before:=JSON.stringify(state.d)
		if not world.kayak:
			for motion:Vector2 in [Vector2(-20000,0),Vector2(20000,0),Vector2(0,-20000),Vector2(0,20000)]:
				var contact:Vector2=world._axis_destination(world.player,motion)
				check(world.can_stand(contact),label+" held direction reaches legal contact without crossing geometry")
				check(world.world_space.allows_body(Body.foot_rect(contact)),label+" foot rectangle remains on ground at contact")
		else:
			for heading:float in [0.0,PI/4,PI/2,PI]:
				var water:Rect2=world.world_space.regions[0]
				check(not world.can_stand(Vector2(water.position.x+1,water.get_center().y),heading),label+" whole rotated hull rejects water-edge overhang")
		check(JSON.stringify(state.d)==before,label+" collision and depth queries cannot advance the story")
		if row.scene=="dorm_hub":check(not world.can_stand(Vector2(100,500)),"dorm black gutter is not walkable floor")
		if row.scene=="campus_bootstrap":check(world.world_space.source_foregrounds.size()==4,"campus uses only the four source-enabled landmark polygons")
		if row.scene=="campus_qizhen_loop":check(world.world_space.source_foregrounds.size()==4 and world.world_space.mask_definition.gridWidth==3417,"side-view keeps its own source mask and foreground props")
		if row.scene=="qizhen_lake" and row.vehicle=="on_foot":
			check(not world.can_stand(Vector2(630,500)-Body.FOOT_CENTER_OFFSET),"feet cannot stand beside the visible pier on water")
			check(world.can_stand(Vector2(700,570)-Body.FOOT_CENTER_OFFSET),"visible pier remains walkable with full shared feet")
	world.queue_free();await process_frame
	print("WORLD_SPACE: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
