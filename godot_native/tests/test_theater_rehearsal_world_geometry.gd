extends SceneTree
## Source-sized rack, opaque pick surface and live foot-body route. The fixture
## begins after original ticket admission; it does not award any mainline fact.
const Metrics=preload("res://scripts/player_metrics.gd")
const Layers=preload("res://scripts/ui/chapter3_world_layers.gd")
var state:Node
var world:Control
var checks:=0
var failures:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error("THEATER REHEARSAL WORLD: "+label)
func route(start:Vector2,goal:Vector2)->Array[Vector2i]:
	var step:=8.0
	var frontier:Array[Vector2i]=[Vector2i.ZERO]
	var seen:Dictionary={Vector2i.ZERO:Vector2i.ZERO}
	var cursor:=0
	var found:=Vector2i(99999,99999)
	while cursor<frontier.size() and seen.size()<35000:
		var cell:Vector2i=frontier[cursor];cursor+=1
		var point:Vector2=start+Vector2(cell)*step
		if point.distance_to(goal)<5:found=cell;break
		for direction:Vector2i in [Vector2i.UP,Vector2i.LEFT,Vector2i.DOWN,Vector2i.RIGHT]:
			var next:Vector2i=cell+direction
			if seen.has(next):continue
			if not world.can_stand(point+Vector2(direction)*step/2) or not world.can_stand(point+Vector2(direction)*step):continue
			seen[next]=cell;frontier.append(next)
	var result:Array[Vector2i]=[]
	if found.x==99999:return result
	while found!=Vector2i.ZERO:
		result.push_front(found-seen[found]);found=seen[found]
	return result
func key(code:int,down:bool)->void:
	var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=down
	Input.parse_input_event(event);Input.flush_buffered_events()
func opaque_in(tex:Texture2D,bounds:Rect2)->int:
	var image:Image=tex.get_image()
	if image.is_compressed():image.decompress()
	var source:=Rect2(image.get_used_rect())
	var fit:float=minf(120.0/source.size.x,100.0/source.size.y)
	var top_left:Vector2=Vector2(560-source.size.x*fit/2,206-source.size.y*fit)
	var count:=0
	for y:int in range(ceili(bounds.position.y),floori(bounds.end.y)):
		for x:int in range(ceili(bounds.position.x),floori(bounds.end.x)):
			var pixel:Vector2i=Vector2i(source.position+(Vector2(x+.5,y+.5)-top_left)/fit)
			if pixel.x>=0 and pixel.y>=0 and pixel.x<image.get_width() and pixel.y<image.get_height() and image.get_pixelv(pixel).a>.2:count+=1
	return count
func run()->void:
	check(load("res://tests/native_test_isolation.gd").is_isolated_save(),"isolated user storage")
	if failures:quit(1);return
	check(ResourceLoader.exists(Layers.REHEARSAL_RACK_ASSET),"generated standalone rack is imported")
	if failures:quit(1);return
	var tex:Texture2D=load(Layers.REHEARSAL_RACK_ASSET)
	var image:Image=tex.get_image()
	if image.is_compressed():image.decompress()
	check(image.get_pixel(0,0).a<.1,"rack ships a transparent outside surface")
	var used:=Rect2(image.get_used_rect())
	check(used.has_area(),"rack contains actual visible material")
	if not used.has_area():quit(1);return
	var scale_to_fit:float=minf(120.0/used.size.x,100.0/used.size.y)
	check(used.size.x*scale_to_fit>=96,"visible rack spans its entire authored physical base width")
	check(opaque_in(tex,Rect2(512,184,32,22))>0 and opaque_in(tex,Rect2(576,184,32,22))>0,"both measured base sides contain visible physical rack pixels")
	state=root.get_node("State");state.developer_mode=true;state.begin_checkpoint("c3-theater-code")
	state.d.theaterHunt.admitted=true;state.d.theaterHunt.phase="program_search"
	state.d.native.player={"scene":"theater_interior","x":1080.0,"y":590.0};state.d.native.positions={"theater_interior:":{"x":1080.0,"y":590.0}}
	world=load("res://scripts/world.gd").new();world.size=Vector2(960,540);root.add_child(world)
	await process_frame;world.set_process(false);world._process(0)
	var original_solids:Array=world.spec.collisions.duplicate(true)
	check(world.player==Vector2(1080,590) and world.can_stand(world.player),"original auditorium checkpoint stays safe")
	check(not world.can_stand(Vector2(560,195)-Metrics.FOOT_CENTER_OFFSET),"rack base blocks actual shared foot body")
	for point:Vector2 in [Vector2(540,206),Vector2(560,206),Vector2(580,206),Vector2(365,206)]:
		check(world.can_stand(point),"side-wing operator passage is clear "+str(point))
	var before:Array=world.collisions.duplicate(true)
	for i:int in range(10):world._process(.05)
	check(world.collisions==before,"rack collision does not accumulate per tick")
	for phase:String in ["entry_ticket","program_search","prop_setup","spotlight_ready","spotlight_hunt","reversal","complete"]:
		state.d.theaterHunt.phase=phase;world.chapter3_layers.sync(state.d)
		check(world.chapter3_layers.entries(state.d).filter(func(entry:Dictionary)->bool:return entry.id=="theater_shadow_rehearsal").size()==1,"physical rack remains visible during "+phase)
		check(world.chapter3_layers.adjusted_collisions(original_solids,state.d).filter(func(box:Dictionary)->bool:return box.id=="c3_dynamic_rehearsal_rack").size()==1,"one physical rack footprint during "+phase)
	state.d.theaterHunt.phase="program_search";world.refresh_world();world._process(0)
	var path:Array[Vector2i]=route(world.player,Vector2(560,206))
	check(not path.is_empty(),"collision-checked connected route joins original auditorium to rack stand")
	for direction:Vector2i in path:
		var code:int=KEY_W if direction==Vector2i.UP else KEY_A if direction==Vector2i.LEFT else KEY_S if direction==Vector2i.DOWN else KEY_D
		var prior:Vector2=world.player
		key(code,true);world._process(8.0/165.0);key(code,false)
		check(world.can_stand(world.player) and world.player.distance_to(prior+Vector2(direction)*8)<.05,"ordinary keyboard follows safe source route")
	check(world.player.distance_to(Vector2(560,206))<5,"actual body reaches source operator stand")
	world.queue_redraw();await process_frame
	var picked:=false
	for y:int in range(108,205,3):
		for x:int in range(501,620,3):
			if world.object_picker.pick(Vector2(x,y),world.targets,false).get("id","")=="theater_shadow_rehearsal":picked=true;break
		if picked:break
	check(picked,"actual alpha-backed rack rendering registers the same physical target")
	var target:Dictionary={}
	for entry:Dictionary in world.targets:
		if entry.id=="theater_shadow_rehearsal":target=entry
	check(not target.is_empty() and world._distance(target)<=target.radius,"rendered rack uses reachable shared interaction radius")
	if not target.is_empty():
		var facts:String=JSON.stringify(state.d.theaterHunt);var items:String=JSON.stringify(state.d.items)
		world._try_interact(target)
		check(state.last_result.has("game") and state.last_result.game.kind=="theater_shadow_rehearsal","ordinary world target enters its validated rehearsal")
		check(JSON.stringify(state.d.theaterHunt)==facts and JSON.stringify(state.d.items)==items,"world rehearsal entry retains original ticket and every mainline fact")
	world.queue_free();await process_frame
	print("THEATER_REHEARSAL_WORLD_GEOMETRY: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
