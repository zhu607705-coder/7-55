extends SceneTree
## An admitted source checkpoint is a presentation fixture, not a completed
## ticket/mainline playthrough. All collision assertions use the shared body.
const Rebuild=preload("res://scripts/presentation/theater_object_rebuild.gd")
const Metrics=preload("res://scripts/player_metrics.gd")
const Picker=preload("res://scripts/world_object_picker.gd")
var checks:=0
var failures:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error("THEATER OBJECT REBUILD: "+label)
func contains_pixel(image:Image,geometry:Dictionary,point:Vector2)->bool:
	var pixel:Vector2=geometry.source.position+(point-geometry.destination.position)/geometry.scale
	return image.get_pixel(clampi(int(pixel.x),0,image.get_width()-1),clampi(int(pixel.y),0,image.get_height()-1)).a>.05
func blocks(boxes:Array,point:Vector2)->bool:
	for box:Dictionary in boxes:
		if Rect2(box.left,box.top,box.right-box.left,box.bottom-box.top).has_point(point):return true
	return false
func run()->void:
	check(load("res://tests/native_test_isolation.gd").is_isolated_save(),"isolated storage")
	if failures:quit(1);return
	var rebuild:RefCounted=Rebuild.new()
	check(rebuild.textures.is_empty(),"unvisited theater never loads deferred chapter art")
	var state:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/initial_state.json"))
	state.native={"scene":"theater_interior","mode":"light"}
	var before:String=JSON.stringify(state)
	rebuild.sync(state,true)
	check(rebuild.ready() and rebuild.mode()=="generated","complete imported generated family activates")
	if not rebuild.ready() or rebuild.mode()!="generated":quit(1);return
	check(rebuild.source_texture.get_size()==Vector2(1672,941),"source pixels retain original theater projection")
	var hash:=HashingContext.new();hash.start(HashingContext.HASH_SHA256);hash.update(FileAccess.get_file_as_bytes(rebuild.data.source.asset))
	check(hash.finish().hex_encode()==str(rebuild.data.source.sha256),"decomposition references the exact checked-in theater plate")
	check(rebuild.data.objects.size()==16,"six seating groups and ten measured physical fixture objects are independently owned")
	var frame:=Rect2(0,0,1672,941)
	var ids:Dictionary={};var target_ids:Dictionary={};var parts:=0
	for object:Dictionary in rebuild.objects():
		check(not ids.has(object.id),"one renderer owns "+str(object.id));ids[object.id]=true
		for target:String in object.targetIds:
			check(not target_ids.has(target),"one object owns native pick surface "+target);target_ids[target]=true
		if object.category=="seat_group":check(object.parts.size()==4,"all four rows remain physical "+str(object.id))
		for part:Dictionary in object.parts:
			parts+=1
			var bounds:Rect2=Rebuild.rect(part.sourceRect)
			check(frame.encloses(bounds) and bounds.has_area(),"source sprite crop remains inside original plate "+str(object.id))
			for point:Vector2 in Rebuild.points(part.polygon):check(bounds.grow(.01).has_point(point),"source outline cannot borrow unrelated furniture pixels "+str(object.id))
			for band:Dictionary in part.cleanBands:
				check(frame.encloses(Rebuild.rect(band.donorRect)) and bounds.encloses(Rebuild.rect(band.targetRect)),"clean-floor donor and destination are source-sized "+str(object.id))
	check(parts==34,"chairs stay independent from rebuilt sound desk")
	var meshes:Array=rebuild.clean_mesh_cache
	check(meshes.size()>34,"background erasure uses clipped local same-source pixels")
	for mesh:Dictionary in meshes:
		for uv:Vector2 in mesh.uv:check(uv.x>=0 and uv.y>=0 and uv.x<=1 and uv.y<=1,"clean patch never samples outside source texture")
	for id:String in rebuild.replacement_geometry:
		var geometry:Dictionary=rebuild.replacement_geometry[id]
		var texture:Texture2D=geometry.texture
		var image:Image=texture.get_image();if image.is_compressed():image.decompress()
		check(image.detect_alpha()!=Image.ALPHA_NONE,"generated object has real transparent outside pixels "+id)
		check(is_equal_approx(geometry.destination.size.x/geometry.source.size.x,geometry.destination.size.y/geometry.source.size.y),"alpha extent has uniform source scale "+id)
		var picker:RefCounted=Picker.new();var rendered:Dictionary={"rect":geometry.destination,"texture":texture,"source":geometry.source}
		var opaque:=false;var clear:=false
		for y:int in range(int(geometry.source.position.y),int(geometry.source.end.y)):
			for x:int in range(int(geometry.source.position.x),int(geometry.source.end.x)):
				var point:Vector2=geometry.destination.position+(Vector2(x+.5,y+.5)-geometry.source.position)*geometry.scale
				if image.get_pixel(x,y).a<.01 and not clear:check(not picker.contains(rendered,point),"transparent margin does not steal native clicks "+id);clear=true
				if image.get_pixel(x,y).a>.95 and not opaque:check(picker.contains(rendered,point),"visible generated material stays pickable "+id);opaque=true
				if opaque and clear:break
			if opaque and clear:break
		check(opaque and clear,"generated alpha contains both material and open floor "+id)
		var object:Dictionary=rebuild._object(id)
		var footprint:Dictionary=object.collisionGenerated[0]
		var bottom:Rect2=Rect2(footprint.left,footprint.top,footprint.right-footprint.left,footprint.bottom-footprint.top)
		check(geometry.destination.grow(.01).encloses(bottom),"physical base stays inside rendered alpha extent "+id)
		for x:float in [bottom.position.x+2,bottom.get_center().x,bottom.end.x-2]:
			var material:=false
			for y:int in range(int(bottom.position.y),int(bottom.end.y)):
				if contains_pixel(image,geometry,Vector2(x,y+.5)):material=true;break
			check(material,"both physical sides and center contain visible supporting material "+id)
	var cached:Dictionary=rebuild.replacement_geometry.duplicate()
	for i:int in range(100):rebuild.sync(state);rebuild.refresh_assets()
	check(rebuild.replacement_geometry==cached and rebuild.clean_mesh_cache==meshes,"successful textures and clean geometry remain cached across frames")
	var source:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/worlds.json")).worlds.theater_interior
	var source_before:String=JSON.stringify(source.collisions)
	var solids:Array=rebuild.adjusted_collisions(source.collisions,state)
	check(JSON.stringify(source.collisions)==source_before,"source collision manifest remains unchanged")
	check(rebuild.adjusted_collisions(solids,state)==solids,"per-row physical bases never accumulate on repeated updates")
	check(blocks(solids,Vector2(1160,560)) and blocks(solids,Vector2(1160,592)) and blocks(solids,Vector2(1160,624)),"three lower-right chair rows cannot be walked through")
	check(not blocks(solids,Vector2(1220,535)),"sound-console opening above extended chair rows remains clear")
	check(not blocks(solids,Vector2(265,160)) and blocks(solids,Vector2(265,205)),"prop chest clears the old invisible upper wall while its actual lower base stays solid")
	check(rebuild.adjusted_collisions([],state).is_empty(),"presentation cannot invent solids without an original physical fixture")
	var missing:Dictionary=rebuild.data.duplicate(true)
	for object:Dictionary in missing.objects:
		if object.id=="stage_prop_chest":object.replacement.asset="res://assets/native/theater_rebuild_20261020/pending.png"
	var fallback:RefCounted=Rebuild.new(missing);fallback.sync(state,true)
	check(fallback.ready() and fallback.mode()=="source_atlas" and fallback.replacement_geometry.is_empty(),"one missing image leaves the entire replacement family on coherent source atlas art")
	check(fallback.entries(state).size()==34,"fallback keeps all original independent source sprites")
	for object:Dictionary in fallback.data.objects:
		if object.id=="stage_prop_chest":object.replacement.asset=rebuild._object("stage_prop_chest").replacement.asset
	fallback.next_retry_ms=0;fallback.sync(state)
	check(fallback.mode()=="generated" and fallback.replacement_geometry.size()==3,"later mounted chapter textures activate atomically without reentering the room")
	var opaque_definition:Dictionary=rebuild.data.duplicate(true)
	for object:Dictionary in opaque_definition.objects:
		if object.id=="stage_prop_chest":object.replacement.asset=rebuild.data.source.asset
	var opaque_rebuild:RefCounted=Rebuild.new(opaque_definition);opaque_rebuild.sync(state)
	check(opaque_rebuild.mode()=="source_atlas","opaque background cannot impersonate a generated transparent prop")
	check(JSON.stringify(state)==before,"splitting, drawing geometry, collision replacement and retries never write game state")
	var live:Node=root.get_node("State");live.developer_mode=true;live.begin_checkpoint("c3-theater-code")
	live.d.theaterHunt.admitted=true;live.d.theaterHunt.phase="program_search"
	live.d.native.player={"scene":"theater_interior","x":1080.0,"y":590.0}
	var world:Control=load("res://scripts/world.gd").new();world.size=Vector2(960,540);root.add_child(world)
	await process_frame;world.set_process(false);world._process(0)
	check(world.can_stand(Vector2(1080,590)),"original auditorium checkpoint remains open")
	for foot:Vector2 in [Vector2(1160,560),Vector2(1160,592),Vector2(1160,624),Vector2(265,205)]:check(not world.can_stand(foot-Metrics.FOOT_CENTER_OFFSET),"real shared body is stopped by visible fixture "+str(foot))
	for anchor:Vector2 in [Vector2(265,130),Vector2(420,200),Vector2(420,218),Vector2(560,206),Vector2(365,206),Vector2(665,790),Vector2(1080,750),Vector2(476,755),Vector2(1080,590)]:check(world.can_stand(anchor),"source interaction stand and clear former air wall remain open "+str(anchor))
	world.queue_free();await process_frame
	print("THEATER_OBJECT_REBUILD: %d checks; %d failures; generated=%s"%[checks,failures,rebuild.mode()]);quit(1 if failures else 0)
