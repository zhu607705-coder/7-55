extends SceneTree
const Body=preload("res://scripts/player_metrics.gd")
const Space=preload("res://scripts/space/spatial_rules.gd")
const FloorSpace=preload("res://campuses/future_learning_center/scripts/floor_space.gd")
const RoomCamera=preload("res://campuses/future_learning_center/scripts/room_camera.gd")
var checks:=0
var failures:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;printerr("FLC_FAIL: "+label)
func foot(p:Array)->Vector2:return Vector2(p[0],p[1])-Body.FOOT_CENTER_OFFSET
func run()->void:
	if not preload("res://tests/native_test_isolation.gd").is_isolated_save():printerr("Use samples/future_learning_center/run.mjs --test");quit(2);return
	var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://campuses/future_learning_center/data/floor_3.json"))
	var space=FloorSpace.new();space.configure(data)
	var spawn:=foot(data.spawn)
	check(space.can_stand(spawn),"legal starting foot box")
	check(data.rooms.filter(func(r:Dictionary)->bool:return str(r.id).begins_with("studio_")).size()==4,"four studios retained from source plan")
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
	var first:Dictionary=data.corridors[0];var edge:Vector2=Vector2(first.polygon[0][0],first.polygon[0][1])
	check(not space.can_stand(edge+Vector2(2,180)-Body.FOOT_CENTER_OFFSET),"complete feet cannot straddle corridor wall")
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
	var file_path:=OS.get_environment("FLC_TEST_REPORT")
	if not file_path.is_empty():
		var file:=FileAccess.open(file_path,FileAccess.WRITE);file.store_string(JSON.stringify({"checks":checks,"failures":failures,"rejectedLinks":space.invalid_links,"world":data.world,"engine":Engine.get_version_info()},"  "));file.close()
	print("FLC_TESTS: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
