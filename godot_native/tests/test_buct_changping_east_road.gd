extends SceneTree
## Exact production scene, real CharacterBody2D ticks. No position writes during
## the continuous spawn -> J -> A -> B -> J -> spawn proof.
var checks := 0
var failures: Array[String] = []
var report: Dictionary = {}
var trace: Array = []
var campus: Node2D
func _initialize() -> void: run.call_deferred()
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func vec(a: Array) -> Vector2:return Vector2(a[0],a[1])
func tick() -> void:await physics_frame;await process_frame
func legacy_walkable(p:Vector2) -> bool:
	for off in [Vector2.ZERO,Vector2(3,0),Vector2(-3,0),Vector2(0,3),Vector2(0,-3)]:
		var inside:=false
		for i in range(campus.walk_polys.size()-1):
			if Geometry2D.is_point_in_polygon(p+off,campus.walk_polys[i]):inside=true;break
		if not inside:return false
	for poly in campus.blockers:
		if Geometry2D.is_point_in_polygon(p,poly):return false
	return true
func disk_clear(p:Vector2) -> bool:
	if not campus._in_paving(p):return false
	for edge in campus.east_road_extension.exposed_edges:
		if p.distance_squared_to(Geometry2D.get_closest_point_to_segment(p,edge[0],edge[1]))<9.0-0.0001:return false
	return true
func run() -> void:
	campus=load("res://campuses/buct_changping/scenes/playable.tscn").instantiate();root.add_child(campus)
	await tick();await tick()
	check(campus.initialized,"Production scene initialized")
	check(campus.data.route_waypoints.size()==41 and campus.data.landmarks.size()==3,"Original 41 guide points and 3 POIs retained")
	check(campus.walk_polys.size()==82,"Exactly one polygon appended to original 81")
	check(campus.visitor.speed==88 and campus.visitor.display_height==18,"Student height/speed unchanged")
	check(campus.visitor.get_node("FeetCollision").shape.radius==3,"Actual circle radius unchanged")
	check(is_instance_valid(campus.library_layer) and is_instance_valid(campus.first_teaching_layer),"Current real building layers retained")
	check(campus.east_road_extension.find_children("*","CollisionObject2D",true,false).is_empty(),"Added source leaves create no physics")
	check(not campus.is_walkable(Vector2(763.25,881)),"New junction counterexample rejected by radius3 union boundary")
	check(campus.is_walkable(Vector2(751,868.5))==legacy_walkable(Vector2(751,868.5)),"Inherited old corner behavior intentionally retained")
	var original_cell_count:=0;var new_cells:Array[Vector2i]=[]
	for cell in campus.walk_cells:
		var p:Vector2=campus.grid.get_point_position(cell)
		if legacy_walkable(p):original_cell_count+=1
		else:new_cells.append(cell)
	var reachable:=0;var start:Vector2i=campus.nearest_cell(vec(campus.data.spawn))
	for cell in new_cells:
		if not campus.grid.get_id_path(start,cell).is_empty():reachable+=1
	check(reachable==new_cells.size(),"Every added navgrid node reachable from actual spawn")
	var bad_samples:Array=[]
	var edges:=0;var interior_samples:=0;var illegal:=0;var inherited:=0
	for cell in campus.walk_cells:
		var p:Vector2=campus.grid.get_point_position(cell)
		if p.x<717 or p.y<665 or p.y>887:continue
		for off in [Vector2i(1,0),Vector2i(0,1),Vector2i(1,1),Vector2i(-1,1)]:
			var qcell:Vector2i=cell+off
			if not campus.grid.is_in_boundsv(qcell) or campus.grid.is_point_solid(qcell):continue
			if off.x!=0 and off.y!=0:
				if campus.grid.is_point_solid(cell+Vector2i(off.x,0)) or campus.grid.is_point_solid(cell+Vector2i(0,off.y)):continue
			var q:Vector2=campus.grid.get_point_position(qcell);edges+=1
			var inherited_edge:=legacy_walkable(p) and legacy_walkable(q)
			if off.x!=0 and off.y!=0:inherited_edge=inherited_edge and legacy_walkable(campus.grid.get_point_position(cell+Vector2i(off.x,0))) and legacy_walkable(campus.grid.get_point_position(cell+Vector2i(0,off.y)))
			for step in range(17):
				var sample:Vector2=p.lerp(q,step/16.0);interior_samples+=1
				if inherited_edge:
					if not legacy_walkable(sample) or not disk_clear(sample):inherited+=1
				elif not legacy_walkable(sample):
					if not campus.is_walkable(sample) or not disk_clear(sample):
						illegal+=1;bad_samples.append({"a":[p.x,p.y],"b":[q.x,q.y],"sample":[sample.x,sample.y],"a_old":legacy_walkable(p),"b_old":legacy_walkable(q)})
				elif not disk_clear(sample):inherited+=1
	check(illegal==0,"All newly introduced AStar edge interiors inside radius3 legal union for added permissions")
	report.geometry={"original_grid_cells":original_cell_count,"added_grid_cells":new_cells.size(),"added_reachable":reachable,"local_grid_edges":edges,"edge_samples":interior_samples,"new_illegal_samples":illegal,"bad_samples":bad_samples,"inherited_old_radius_crossing_samples_preserved":inherited}
	if OS.get_environment("BUCT_EAST_ROAD_GEOMETRY_ONLY")=="1":
		write_optional_evidence("geometry-detail.json",report.geometry);print(JSON.stringify(report.geometry));campus.queue_free();await process_frame;quit(0 if illegal==0 and failures.is_empty() else 1);return
	# Normal path-following movement, no synthetic speed or position assignment.
	var max_speed:=0.0;var illegal_ticks:=0;var new_radius_fail:=0;var physics_ticks:=0;var arrived:Array=[]
	for target in [Vector2(760,877),Vector2(769,807),Vector2(733,683),Vector2(760,877),vec(campus.data.spawn)]:
		check(campus.path_to(target),"Production AStar route exists to "+str(target))
		var before:Vector2=campus.visitor.position;var start_time:=Time.get_ticks_msec()
		while campus.visitor.position.distance_to(target)>3.1 and Time.get_ticks_msec()-start_time<23000:
			await tick();physics_ticks+=1
			var p:Vector2=campus.visitor.position
			max_speed=maxf(max_speed,campus.visitor.last_motion.length()*Engine.physics_ticks_per_second)
			if not campus.is_walkable(p):illegal_ticks+=1
			if not legacy_walkable(p) and not disk_clear(p):new_radius_fail+=1
			if physics_ticks%4==0:trace.append([p.x,p.y])
			before=p
		check(campus.visitor.position.distance_to(target)<=3.1,"Actual student continuously reaches "+str(target))
		arrived.append({"target":[target.x,target.y],"actual":[campus.visitor.position.x,campus.visitor.position.y]})
	campus.current_path.clear();await tick()
	check(illegal_ticks==0 and new_radius_fail==0,"Continuous real physics never enters illegal feet")
	check(max_speed<=88.05,"Continuous default movement never exceeds speed88")
	report.continuous={"physics_ticks":physics_ticks,"illegal_ticks":illegal_ticks,"new_radius_failures":new_radius_fail,"max_actual_speed":max_speed,"arrivals":arrived,"position_writes_after_initial_spawn":0,"trace_every_4_ticks":trace}
	# Original guide is a separate regression; its established reset is preserved.
	campus.start_guide();var deadline:=Time.get_ticks_msec()+20000
	while campus.guide_active and Time.get_ticks_msec()<deadline:await tick()
	check(not campus.guide_active and campus.visitor.position.distance_to(Vector2(566,816))<8,"Original guide completes at the original library endpoint")
	check(campus.visited.size()==3,"Original guide still visits exactly three POIs")
	report.guide={"guide_index":campus.guide_index,"actual_feet":[campus.visitor.position.x,campus.visitor.position.y],"visited":campus.visited.duplicate()}
	campus.close_info();campus.guide_active=false;campus.current_path.clear()
	# Explicit isolated boundary fixtures. These position writes are not presented
	# as travel or as newly opened building/water access.
	var fixtures:Array=[]
	for item in [{"name":"east_road_edge","start":Vector2(769,807),"key":KEY_RIGHT},{"name":"west_grass","start":Vector2(749,725),"key":KEY_LEFT},{"name":"bounded_north_end","start":Vector2(733,683),"key":KEY_UP},{"name":"toward_lake_unopened_ground","start":Vector2(559,848),"key":KEY_LEFT},{"name":"toward_wenli_building","start":Vector2(769,807),"key":KEY_LEFT}]:
		campus.visitor.position=item.start;campus.visitor.velocity=Vector2.ZERO;await tick()
		key(item.key,true)
		for frame_index in range(65):await tick()
		var stop:Vector2=campus.visitor.position
		check(campus.is_walkable(stop),"Held key stays legal: "+item.name)
		check(campus.visitor.last_motion.length()<0.001,"Held key stops at boundary: "+item.name)
		key(item.key,false);await tick();var released:Vector2=campus.visitor.position
		for frame_index in range(5):await tick()
		check(campus.visitor.position.distance_to(released)<0.001 and campus.visitor.manual_input.length()<0.001,"Key release clears movement: "+item.name)
		fixtures.append({"name":item.name,"stop":[stop.x,stop.y],"release_drift":campus.visitor.position.distance_to(released)})
	campus.visitor.set_physics_process(false);campus.visitor.position=Vector2(550,814);await tick()
	var hit=campus.visitor.move_and_collide(Vector2(0,-40),true)
	check(hit!=null,"Native real library collider still stops radius3 feet")
	report.boundaries=fixtures
	report.checks=checks;report.failures=failures;report.scope="Automated native physics, production script. Preserved legacy circular-clearance exceptions are counted separately; no surveyed campus claims."
	write_optional_evidence("native-validation.json",report)
	campus.queue_free();await process_frame;await process_frame
	print("BUCT_CHANGPING_EAST_ROAD checks=%d failures=%d"%[checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
func key(code:int,pressed:bool) -> void:
	var ev:=InputEventKey.new();ev.keycode=code;ev.physical_keycode=code;ev.pressed=pressed;Input.parse_input_event(ev)

func write_optional_evidence(filename:String,payload:Dictionary) -> void:
	var out:=OS.get_environment("BUCT_EAST_ROAD_OUTPUT")
	# The shared validator also invokes this test directly without an evidence
	# directory. Logging is optional; never turn an empty env into a root path.
	if out.is_empty():return
	var file:=FileAccess.open(out.path_join(filename),FileAccess.WRITE)
	if file==null:
		check(false,"Cannot open explicitly requested evidence file: "+filename)
		return
	file.store_string(JSON.stringify(payload,"  ")+"\n");file.close()
