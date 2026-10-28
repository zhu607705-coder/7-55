extends SceneTree
const Body=preload("res://scripts/player_metrics.gd")
const Space=preload("res://scripts/space/spatial_rules.gd")
const FloorSpace=preload("res://campuses/future_learning_center/scripts/floor_space.gd")
const RoomCamera=preload("res://campuses/future_learning_center/scripts/room_camera.gd")
const Lighting=preload("res://campuses/future_learning_center/scripts/floor_lighting.gd")
const Transit=preload("res://campuses/future_learning_center/scripts/building_transit.gd")
var checks:=0
var failures:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;printerr("FLC_FAIL: "+label)
func foot(p:Array)->Vector2:return Vector2(p[0],p[1])-Body.FOOT_CENTER_OFFSET
func check_floor(floor_number:int)->void:
	var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://campuses/future_learning_center/data/floor_%d.json"%floor_number))
	var space=FloorSpace.new();space.configure(data)
	var spawn:=foot(data.spawn)
	check(space.can_stand(spawn),"legal starting foot box")
	if floor_number==3:check(data.rooms.filter(func(r:Dictionary)->bool:return str(r.id).begins_with("studio_")).size()==4,"four studios retained from source plan")
	if floor_number==4:check(data.rooms.filter(func(r:Dictionary)->bool:return str(r.id).begins_with("seminar_")).size()==3,"three west rooms retained from 4F drawing")
	if floor_number==2:
		var platform:Dictionary=data.rooms.filter(func(r:Dictionary)->bool:return r.id=="platform")[0]
		var b:Rect2=Space.rect(platform.bounds)
		check(space.can_stand(b.get_center()-Body.FOOT_CENTER_OFFSET),"2F central platform is solid ground")
		check(not data.doors.any(func(d:Dictionary)->bool:return d.room=="platform" or d.room=="classroom"),"no invented door around 2F platform")
		check(space.segment_clear(Vector2(b.position.x-80,b.get_center().y)-Body.FOOT_CENTER_OFFSET,Vector2(b.end.x+80,b.get_center().y)-Body.FOOT_CENTER_OFFSET),"2F platform is continuously open to both corridors")
	check(data.world[0]>5000 and data.world[1]>7500,"large assembled map")
	for module:Dictionary in data.modules:
		check(FileAccess.file_exists(module.path),str(module.id)+" saved in project")
		var source:Rect2=Space.rect(module.crop);var placed:Rect2=Space.rect(module.bounds)
		check(absf(source.size.x/source.size.y-placed.size.x/placed.size.y)<.00001,str(module.id)+" uniform image scale")
	for p:Array in data.openSamples:
		check(space.can_stand(foot(p)),"clear source floor "+str(p))
		check(not space.route(spawn,foot(p)).is_empty(),"reachable clear room "+str(p))
	for p:Array in data.blockedSamples:check(not space.can_stand(foot(p)),"solid wall/void/shaft "+str(p))
	check(space.invalid_links.is_empty(),"all authored graph links valid: "+str(space.invalid_links))
	for door:Dictionary in data.doors:
		var a:=foot(door.inside);var b:=foot(door.outside)
		check(space.can_stand(a) and space.can_stand(b),str(door.id)+" both thresholds fit complete feet")
		check(space.segment_clear(a,b),str(door.id)+" aperture really crosses")
		check(not space.route(spawn,a).is_empty(),str(door.id)+" reached through corridor network")
		check(not space.route(a,spawn).is_empty(),str(door.id)+" can return")
	for direction:Vector2 in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
		var stopped:Vector2=space.move(spawn,direction*12000)
		check(space.can_stand(stopped),"swept motion cannot tunnel "+str(direction))
		check(stopped.distance_to(spawn)<6000,"wall stops long motion "+str(direction))
		var backed:Vector2=space.move(stopped,-direction*50)
		check(space.can_stand(backed) and backed.distance_to(stopped)>20,"walk away from boundary "+str(direction))
	# The whole footprint must reject an outer-edge straddle, even if its centre
	# still lies on the corridor. This catches centre-only navigation regressions.
	check(not space.can_stand(Vector2(2,500)),"complete actor cannot straddle world boundary")
	for room:Dictionary in data.rooms:
		var bounds:Rect2=Space.rect(room.bounds)
		var inside:=bounds.get_center()-Body.FOOT_CENTER_OFFSET
		if not space.can_stand(inside):continue
		var cam=RoomCamera.new();cam.update(0,inside,space,true)
		for i:int in 180:cam.update(1.0/60,inside,space)
		check(space.focus_bounds(space.room_at(inside+Body.FOOT_CENTER_OFFSET)).grow(.2).encloses(cam.visible_rect()),str(room.id)+" camera stays inside room")
		check(cam.visible_rect().encloses(Body.visual_rect(inside)),str(room.id)+" full actor in view")
	# Same stopped input at 30/60/144 Hz: presentation settles to the same point.
	var positions:Array[Vector2]=[]
	for fps:int in [30,60,144]:
		var cam=RoomCamera.new();cam.update(0,spawn,space,true)
		var target:=spawn+Vector2(220,90)
		for i:int in fps*2:cam.update(1.0/fps,target,space)
		positions.append(cam.center)
	check(positions[0].distance_to(positions[1])<1 and positions[1].distance_to(positions[2])<1,"camera convergence independent of frame rate")
	for t:Dictionary in data.transits:
		var start:=foot(t.arrival)
		check(space.can_stand(start),"%dF %s landing feet fit"%[floor_number,t.id])
		check(not space.route(spawn,start).is_empty(),"%dF %s reached from rooms"%[floor_number,t.id])
		check(Transit.destination(data,spawn,2 if floor_number!=2 else 3).is_empty(),"floor selection unavailable away from landing")
		for target:int in [2,3,4]:
			var result:Dictionary=Transit.destination(data,start,target)
			var allowed:bool=target!=floor_number and (t.kind=="elevator" or absi(target-floor_number)==1)
			check(result.is_empty()!=allowed,"floor route availability %d -> %d via %s"%[floor_number,target,t.id])
			if not allowed:continue
			var other:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://campuses/future_learning_center/data/floor_%d.json"%target))
			var destination_space=FloorSpace.new();destination_space.configure(other)
			check(destination_space.can_stand(foot(result.point)),"arrival remains on flat ground")
			var back:Dictionary=Transit.destination(other,foot(result.point),floor_number)
			check(not back.is_empty() and foot(back.point).distance_to(start)<.01,"paired transit returns to same landing")
	for item:Dictionary in data.objects:
		check(FileAccess.file_exists(item.path),"independent object saved: "+str(item.id))
		if item.mounted:continue
		check(not space.can_stand(Space.rect(item.footprint).get_center()-Body.FOOT_CENTER_OFFSET),"feet blocked by prop: "+str(item.id))
	if floor_number==3:
		for room:Dictionary in data.rooms:
			if not str(room.id).begins_with("studio_"):continue
			var upper:Array=data.objects.filter(func(o:Dictionary)->bool:return o.get("cluster","")==str(room.id)+"_bank_0" and not o.mounted)
			var lower:Array=data.objects.filter(func(o:Dictionary)->bool:return o.get("cluster","")==str(room.id)+"_bank_1" and not o.mounted)
			var upper_bounds:Rect2=Space.rect(upper[0].footprint)
			var lower_bounds:Rect2=Space.rect(lower[0].footprint)
			for o:Dictionary in upper:upper_bounds=upper_bounds.merge(Space.rect(o.footprint))
			for o:Dictionary in lower:lower_bounds=lower_bounds.merge(Space.rect(o.footprint))
			var aisle:=Vector2(upper_bounds.position.x-35,(upper_bounds.end.y+lower_bounds.position.y)/2)-Body.FOOT_CENTER_OFFSET
			var door:Dictionary=data.doors.filter(func(d:Dictionary)->bool:return d.room==room.id)[0]
			check(space.segment_clear(foot(door.inside),aisle),str(room.id)+" complete feet can cross between facing desk banks")
			check(not space.route(aisle,foot(door.outside)).is_empty(),str(room.id)+" middle aisle returns through room door")
		var island:Dictionary=data.objects.filter(func(o:Dictionary)->bool:return o.asset=="pantry_island")[0]
		var island_box:Rect2=Space.rect(island.footprint)
		var pantry_door:Dictionary=data.doors.filter(func(d:Dictionary)->bool:return d.room=="pantry")[0]
		for point:Vector2 in [Vector2(island_box.position.x-45,island_box.get_center().y),Vector2(island_box.end.x+45,island_box.get_center().y),Vector2(island_box.get_center().x,island_box.position.y-65),Vector2(island_box.get_center().x,island_box.end.y+90)]:
			var anchor:=point-Body.FOOT_CENTER_OFFSET
			check(space.can_stand(anchor),"complete feet fit beside pantry island")
			check(not space.route(foot(pantry_door.inside),anchor).is_empty(),"pantry island side remains reachable from entrance")
	check(data.objects.size()>60,"furnished room assembly")

func run()->void:
	if not preload("res://tests/native_test_isolation.gd").is_isolated_save():printerr("Use samples/future_learning_center/run.mjs --test");quit(2);return
	for f:int in [2,3,4]:check_floor(f)
	var light=Lighting.new()
	light.set_hour(8);check(light.incidence(Vector2.RIGHT)>0 and light.incidence(Vector2.LEFT)==0,"morning enters east windows only")
	check(light.cast_vector(100).x<0,"morning prop shadow points west")
	var morning_length:float=light.cast_vector(100).length()
	light.set_hour(12);check(light.incidence(Vector2.DOWN)>.9 and light.incidence(Vector2.UP)==0,"noon southern window illumination")
	check(light.cast_vector(100).length()<morning_length,"noon shadow shorter than morning")
	light.set_hour(16);check(light.incidence(Vector2.LEFT)>0 and light.incidence(Vector2.RIGHT)==0,"afternoon enters west windows only")
	check(light.cast_vector(100).x>0,"afternoon shadow points east")
	light.set_hour(21);check(light.daylight==0 and light.incidence(Vector2.DOWN)==0,"night has no sunlight")
	var file_path:=OS.get_environment("FLC_TEST_REPORT")
	if not file_path.is_empty():
		var file:=FileAccess.open(file_path,FileAccess.WRITE);file.store_string(JSON.stringify({"checks":checks,"failures":failures,"floors":[2,3,4],"engine":Engine.get_version_info()},"  "));file.close()
	print("FLC_TESTS: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
