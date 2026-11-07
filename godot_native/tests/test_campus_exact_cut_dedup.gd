extends SceneTree
## Compare actual new segment code against the frozen old segment implementation.
## All stand, support, water and solid tests remain the real current code.
const Layered = preload("res://scripts/presentation/campus_layered_map.gd")
const Metrics = preload("res://scripts/player_metrics.gd")
var checks := 0
var failures := 0
var old_calls := 0
var new_calls := 0
var old_world: Variant
var new_world: Variant
func _initialize() -> void:
	run.call_deferred()
func check(value: bool,label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("Exact cut dedup: "+label)
func compare(a: Vector2,b: Vector2,label: String) -> bool:
	old_world.stand_calls=0
	new_world.profile.standCalls=0
	var expected: bool=old_world._floor_segment_clear(a,b)
	var actual: bool=new_world._floor_segment_clear(a,b)
	old_calls+=int(old_world.stand_calls)
	new_calls+=int(new_world.profile.standCalls)
	check(actual==expected,label)
	check(int(new_world.profile.standCalls)<=int(old_world.stand_calls),label+" never adds foot checks")
	return actual
func initialize_world(world: Variant,art: RefCounted) -> void:
	world.scene_id="campus_bootstrap"
	world.world_size=Vector2(256,256)
	world._floor_bounds=Rect2(0,0,256,256)
	world.mask.resize(512)
	world.mask.fill(255)
	world.mask_meta={"cellSize":4,"gridWidth":64,"gridHeight":64}
	world.campus_layers=art
func run() -> void:
	check(load("res://tests/native_test_isolation.gd").is_isolated_save(),"isolated save")
	if failures:
		quit(1)
		return
	var state=root.get_node("State")
	state.developer_mode=true;state.d=state.initial()
	var base: String=get_script().resource_path.get_base_dir()
	old_world=load(base.path_join("pre_dedup_segment_reference.gd")).new()
	new_world=load(base.path_join("profile_campus_floor_world.gd")).new()
	var art:=Layered.new();art.ready=true
	var bits:=PackedByteArray();bits.resize(8192);bits.fill(0)
	for area: Rect2i in [Rect2i(40,68,94,24),Rect2i(108,68,24,96),Rect2i(108,138,104,24)]:
		for y in range(area.position.y,area.end.y):
			for x in range(area.position.x,area.end.x):
				var i:=y*256+x;bits[i/8]|=1<<(i%8)
	art.walk_supports=[{"id":"reviewed_s","origin":Vector2.ZERO,"width":256,"height":256,"bits":bits,"bounds":Rect2(40,68,172,96)}]
	art.source_floor_overrides=[Rect2(40,60,190,140)]
	initialize_world(old_world,art);initialize_world(new_world,art)
	var feet: Array[Vector2]=[]
	for x in range(50,121,5):feet.append(Vector2(x,80))
	for y in range(85,151,5):feet.append(Vector2(120,y))
	for x in range(125,201,5):feet.append(Vector2(x,150))
	var random:=RandomNumberGenerator.new();random.seed=7554001
	for i in range(240):
		var a:=feet[random.randi_range(0,feet.size()-1)]+Vector2(random.randf_range(-0.25,0.25),random.randf_range(-0.25,0.25))-Metrics.foot_center_offset("campus_bootstrap")
		var b:=feet[random.randi_range(0,feet.size()-1)]+Vector2(random.randf_range(-0.25,0.25),random.randf_range(-0.25,0.25))-Metrics.foot_center_offset("campus_bootstrap")
		compare(a,b,"real segment differential "+str(i))
	# Positive overlap only exists for t in (0.0625,0.065). Distinct nearby
	# floating cuts must not be epsilon-merged, even though exact duplicates go.
	bits.fill(0)
	for y in range(80,160):
		for x in range(90,148):
			var i:=y*256+x;bits[i/8]|=1<<(i%8)
	var hole:=100*256+110;bits[hole/8]&=~(1<<(hole%8))
	art.walk_supports[0].bits=bits
	art.walk_supports[0].bounds=Rect2(90,80,58,80)
	var a:=Vector2(93.75,100.74)-Metrics.foot_rect(Vector2.ZERO,"campus_bootstrap").position
	var b:=a+Vector2(4,4)
	check(not compare(a,b,"tiny hole forward"),"tiny unsupported interval stays rejected")
	check(not compare(b,a,"tiny hole reverse"),"reverse tiny unsupported interval stays rejected")
	bits[hole/8]|=1<<(hole%8);art.walk_supports[0].bits=bits
	check(compare(a,b,"restored support"),"restored exact same edge remains legal")
	var water:=Rect2(110,100,1,1)
	art.water_regions=[{"bounds":water,"rects":[water]}]
	check(not compare(a,b,"physical water"),"water remains blocking")
	art.water_regions=[]
	old_world.collisions=[{"x":110,"y":100,"width":1,"height":1}]
	new_world.collisions=old_world.collisions.duplicate(true)
	check(not compare(a,b,"story collision"),"story collision remains blocking")
	check(new_calls<old_calls,"exact dedup actually removes redundant foot work")
	old_world.free();new_world.free()
	print("Exact cut dedup: ",checks," checks, ",failures," failures; old stand calls=",old_calls," new stand calls=",new_calls)
	quit(0 if failures==0 else 1)
