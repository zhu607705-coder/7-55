extends SceneTree
const Rebuild=preload("res://scripts/ui/library_object_rebuild.gd")
const Layers=preload("res://scripts/ui/library_world_layers.gd")
const Picker=preload("res://scripts/world_object_picker.gd")
const Library=preload("res://scripts/chapters/library022.gd")
const PlayerMetrics=preload("res://scripts/player_metrics.gd")
var checks: int=0
var failures: int=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error(label)
func _initialize() -> void: call_deferred("run")
func same_solids(a: Array,b: Array) -> bool:
	if a.size()!=b.size(): return false
	for i in range(a.size()):
		if str(a[i].id)!=str(b[i].id): return false
		for coordinate: String in ["left","top","right","bottom"]:
			if not is_equal_approx(float(a[i][coordinate]),float(b[i][coordinate])): return false
	return true
func run() -> void:
	var assets: RefCounted=Rebuild.new()
	check(not assets.ready and assets.issues.is_empty() and assets.textures.is_empty(),"constructing a Chapter 1 world never probes deferred Chapter 2 textures")
	assets.ensure_loaded(true)
	var source: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/worlds.json")).worlds.library_interior
	check(assets.layout.schema=="native-library-object-layout-v1" and Vector2(assets.layout.worldSize[0],assets.layout.worldSize[1])==Vector2(1500,900),"rebuilt library retains exact source world")
	check(assets.bounds("north_display_shelf")==Rect2(502,110,123,123),"movable shelf uses authored source pixels")
	check(assets.bounds("backpack")==Rect2(1238,388,34,38),"baked backpack erasure is distinct from scaled sprite")
	check(Vector2(assets.layout.objects.backpack.textureSize[0],assets.layout.objects.backpack.textureSize[1])==Vector2(56,80) and is_equal_approx(float(assets.layout.objects.backpack.scale),0.6),"backpack texture keeps uniform original actor scale")
	check(assets.bounds("catalog_terminal")==Rect2(613,516,133,97) and assets.bounds("printer")==Rect2(788,510,77,104),"devices retain visible collision footprints")
	check(Rect2(assets.layout.removedDoorLeaves.left,assets.layout.removedDoorLeaves.top,assets.layout.removedDoorLeaves.width,assets.layout.removedDoorLeaves.height)==Rect2(644,681,212,86),"door erasure is explicit and separate from fixed entrance glass")
	for id: String in assets.layout.objects:
		for collision_id: String in assets.layout.objects[id].collisionIds:
			check(source.collisions.any(func(row: Dictionary) -> bool: return row.id==collision_id),"independent art maps to an existing solid "+collision_id)
	for crop: Dictionary in assets.layout.staticForeground:
		var collision: Dictionary={}
		for row: Dictionary in source.collisions:
			if row.id==crop.id: collision=row; break
		check(not collision.is_empty() and crop.rect==[collision.left,collision.top,collision.right-collision.left,collision.bottom-collision.top] and float(crop.baselineY)==float(collision.bottom),"same-source shelf foreground matches existing footprint "+str(crop.id))
	var before: String=JSON.stringify(source.collisions)
	var layer: RefCounted=Layers.new()
	var state: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/initial_state.json"))
	state.native={"scene":"library_interior","mode":"light","settings":{}}
	state.native.chapter=2; state.ui.libraryFinalsPhase="evidence_gathering"
	layer.sync(state)
	var state_before: String=JSON.stringify(state)
	layer.tick(0.025,state)
	check(JSON.stringify(state)==state_before,"asset presentation never creates story facts")
	check(JSON.stringify(source.collisions)==before and same_solids(layer.adjusted_collisions(source.collisions,state),source.collisions),"independent texture activation never moves authored solids")
	var controller: RefCounted=Library.new()
	var native_targets: Array=controller.targets("library_interior",state)
	var printers: Array=native_targets.filter(func(target: Dictionary) -> bool: return str(target.id)=="printer")
	check(printers.size()==1 and str(printers[0].action)=="lib_printer","actual printer art has one native observation intent")
	var saved: String=JSON.stringify(state)
	var observed: Dictionary=controller.dispatch(state,"lib_printer")
	check(str(observed.get("message",""))=="打印机显示缺纸；旁边的纸盒显示库存充足。" and FileAccess.get_file_as_string("res://../src/scenes/rpg/LibraryInteriorScene.ts").contains(str(observed.get("message",""))),"printer keeps its original authored context")
	check(JSON.stringify(state)==saved,"printer observation grants no evidence, item, or visit receipt")
	if OS.get_cmdline_user_args().has("--require-generated"): check(assets.ready,"complete generated PNG asset set is available: "+str(assets.issues))
	if assets.ready:
		check(assets.snapshot().fallback=="" and assets.textures.size()==4,"complete asset set activates atomically without source fallback")
		var retry: RefCounted=Rebuild.new()
		retry.layout.cleanPlate="res://assets/native/library_rebuild_20261020/not_yet_mounted.png"
		check(not retry.ensure_loaded(true) and not retry.issues.is_empty(),"a missing chapter texture stays an incomplete presentation")
		retry.layout.cleanPlate=assets.layout.cleanPlate
		check(retry.ensure_loaded(true) and retry.issues.is_empty(),"a later mounted family can recover from the first missing-texture attempt")
		check(layer.owns_pick_target("catalog_terminal") and layer.owns_pick_target("printer") and layer.owns_pick_target("backpack") and layer.owns_pick_target("bag_photo") and layer.owns_pick_target("backpack_pass"),"regenerated physical surfaces own exact alpha picking")
		check(layer.backpack_pose().visible,"unmoved backpack is an independent visible object")
		var shelf_geometry: Dictionary=assets.geometry("north_display_shelf",assets.bounds("north_display_shelf"))
		check(absf(shelf_geometry.rect.position.x-502)<3 and absf(shelf_geometry.rect.end.x-625)<3 and shelf_geometry.rect.position.y<=114 and absf(shelf_geometry.rect.end.y-233)<2,"generated cabinet and both planters visibly cover the authored solid extent")
		for id: String in ["catalog_terminal","printer"]:
			var geometry: Dictionary=assets.geometry(id,assets.bounds(id))
			var rendered: Rect2=geometry.rect
			var region: Rect2=geometry.source
			check(is_equal_approx(rendered.size.x/region.size.x,rendered.size.y/region.size.y) and is_equal_approx(rendered.end.y,assets.bounds(id).end.y),"generated device fits its actual alpha extent uniformly on original floor baseline "+id)
			check(assets.bounds(id).encloses(rendered),"generated device remains inside original solid footprint "+id)
		var chair: Dictionary=assets.layout.objects.catalog_terminal.components[0]
		var chair_geometry: Dictionary=assets.component_geometry("catalog_terminal",chair)
		check(chair_geometry.rect.end.y==646 and Rect2(636,594,55,52).encloses(chair_geometry.rect),"the generated stool stays visibly inside its original independent chair footprint")
		check(is_equal_approx(chair_geometry.rect.size.x/chair_geometry.source.size.x,chair_geometry.rect.size.y/chair_geometry.source.size.y),"the separate stool is never stretched")
		check(PlayerMetrics.foot_rect(Vector2(663,621)).position.y<646 and layer._in_pass(layer._floor_depth(646),{"player":Vector2(663,621)},true),"chair stays in front while the actor foot box has not cleared its back edge")
		check(PlayerMetrics.foot_rect(Vector2(663,623)).position.y>646 and not layer._in_pass(layer._floor_depth(646),{"player":Vector2(663,623)},true),"actor renders in front as soon as the real foot box clears the chair")
		var body_parts: Array=assets.pieces("catalog_terminal",assets.bounds("catalog_terminal"))
		check(body_parts.size()==3,"terminal body is split around its removed stool region")
		for part: Dictionary in body_parts:
			check(not Rect2(part.source).intersects(chair_geometry.source),"the moved stool is not duplicated in the original desk position")
		for id: String in assets.textures:
			var texture: Texture2D=assets.textures[id]
			var pixels: Image=texture.get_image()
			if pixels.is_compressed(): pixels.decompress()
			var transparent:=Vector2i(-1,-1); var opaque:=Vector2i(-1,-1)
			for y in range(pixels.get_height()):
				for x in range(pixels.get_width()):
					var alpha: float=pixels.get_pixel(x,y).a
					if alpha<0.05: transparent=Vector2i(x,y)
					elif alpha>0.95: opaque=Vector2i(x,y)
					if transparent.x>=0 and opaque.x>=0: break
				if transparent.x>=0 and opaque.x>=0: break
			var picker: RefCounted=Picker.new()
			var geometry: Dictionary={"rect":Rect2(Vector2.ZERO,texture.get_size()),"texture":texture}
			check(not picker.contains(geometry,Vector2(transparent)+Vector2(0.5,0.5)),"transparent sprite margin cannot steal a click "+id)
			check(picker.contains(geometry,Vector2(opaque)+Vector2(0.5,0.5)),"visible sprite pixels remain pickable "+id)
		state.ui.libraryFinalsPuzzle.backpackEvicted=true; layer.sync(state)
		for i in range(90): layer.tick(0.05,state)
		check(not layer.backpack_pose().visible,"eviction retires the independent bag without leaving baked duplicate pixels")
	else:
		check(assets.snapshot().fallback=="original_source_layers" and not assets.issues.is_empty(),"incomplete image generation exposes an explicit original-source fallback")
		check(not layer.owns_pick_target("printer") and not layer.owns_pick_target("catalog_terminal"),"fallback keeps existing plate picking until the full texture set is ready")
	var probe: RefCounted=Rebuild.new()
	check(probe._load_texture("res://assets/rpg/interiors/library_interior.png",[1500,900],true)==null,"opaque floor artwork cannot masquerade as a transparent generated prop")
	check(probe._load_texture("res://assets/rpg/interiors/library_interior.png",[1499,900],false)==null,"mismatched image dimensions cannot stretch the authored world")
	print("Library rebuilt objects: ",checks," checks, ",failures," failures; generated=",assets.ready)
	quit(1 if failures else 0)
