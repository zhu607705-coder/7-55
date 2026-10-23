extends SceneTree
## Explicit render fixture: source coordinates, collisions and controller facts
## stay independent from the bounded GPU textures used for the same wide plate.
var checks:=0
var failures:=0
var state:Node
var world:Control
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error("TILED WORLD BACKGROUND: "+label)
func fixture(scene:String,point:Vector2)->void:
	state.d=state.initial();state.d.native.chapter=3;state.d.native.scene=scene;state.d.native.page="phone_home";state.d.native.mode="light"
	state.d.runtimeMode="rpg";state.d.rpgScene=scene;state.d.actOne.phase="complete";state.d.theaterHunt.phase="complete";state.d.theaterHunt.admitted=true
	state.d.qizhenLake.active=true;state.d.qizhenLake.phase="location_search";state.d.qizhenLake.locationBriefingSeen=false
	state.d.native.player={"scene":scene,"x":point.x,"y":point.y};state.d.native.positions={scene+":":{"x":point.x,"y":point.y}}
	if is_instance_valid(world):world.world_key="";world.refresh_world();world._process(0)
func key(code:int,pressed:bool)->void:
	var e:=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=pressed;Input.parse_input_event(e);Input.flush_buffered_events()
func run()->void:
	check(load("res://tests/native_test_isolation.gd").is_isolated_save(),"isolated original-world render fixture")
	state=root.get_node("State");state.developer_mode=true;fixture("campus_qizhen_loop",Vector2(7730,840))
	var original:Dictionary=state.d.qizhenLake.duplicate(true)
	world=load("res://scripts/world.gd").new();world.size=Vector2(960,540);root.add_child(world);await process_frame;world.set_process(false);await process_frame
	var plate:Dictionary=world.background_plate_snapshot()
	check(world.background_is_tiled and world.background==null,"wide plate cannot upload its original oversized Texture2D")
	check(plate.ready and plate.tiled and plate.sourceSize.x==13668 and plate.sourceSize.y==1084 and plate.tileCount==7 and plate.maxTextureDimension<=2048,"actual renderer uses seven bounded textures with exact source dimensions")
	check(not ResourceLoader.has_cached("res://assets/rpg/campus/zijingang_campus_loop_panorama.png"),"original oversized panorama is not eagerly loaded by the world")
	check(world.world_size==Vector2(13668,1084) and world.background_rect==Rect2(0,0,13668,1084),"source world and rendering rectangle remain exactly unchanged")
	check(world.collisions==world.spec.get("collisions",[]) and not world.mask.is_empty(),"original loop collisions and compressed walkability remain authoritative")
	check(world.can_stand(world.player) and state.d.qizhenLake==original,"loading bounded presentation textures grants no clue or story fact")
	world.grab_focus();var before:Vector2=world.player;var moved:=false
	for row:Array in [[KEY_D,Vector2.RIGHT],[KEY_A,Vector2.LEFT],[KEY_W,Vector2.UP],[KEY_S,Vector2.DOWN]]:
		if not world.can_stand(world.player+row[1]*8.25):continue
		key(row[0],true);world._process(.05);key(row[0],false);moved=world.player.distance_to(before)>0;break
	check(moved and world.can_stand(world.player) and state.d.qizhenLake==original,"real keyboard still moves the exact source-body through the original mask without story mutation")
	var old_adapter:RefCounted=world.background_tiles
	fixture("library_interior",Vector2(715,792.5));await process_frame
	check(not world.background_is_tiled and world.background!=null and world.background_tiles!=old_adapter,"ordinary interior releases the tiled adapter and retains its original Texture2D consumer")
	check(not world.background_plate_snapshot().tiled and world.background_plate_snapshot().ready,"interior readonly geometry reports its ordinary ready plate")
	fixture("campus_qizhen_loop",Vector2(7730,840));await process_frame;await process_frame
	check(world.background_is_tiled and world.background==null and world.background_plate_snapshot().ready and world.can_stand(world.player),"ordinary scene re-entry restores the bounded plate and original safe body")
	world.queue_free();await process_frame
	print("TILED_WORLD_BACKGROUND: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
