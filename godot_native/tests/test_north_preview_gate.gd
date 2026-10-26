extends SceneTree
## Ordinary production entry owns every cutout; presentation cannot write rules.
const Objects=preload("res://scripts/presentation/north_generated_objects.gd")
var checks:=0
var failures:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func frames()->void:
	for i:int in 3:await process_frame
func run()->void:
	if not preload("res://tests/native_test_isolation.gd").is_isolated_save():quit(2);return
	OS.unset_environment(Objects.PREVIEW_ENV)
	var state:Node=root.get_node("State");state.developer_mode=true
	state.begin_checkpoint("c4-755-classrooms-1850")
	state.d.chapter4.mode="light";state.d.native.mode="light"
	var world:Control=load("res://scripts/world.gd").new();root.add_child(world);world.set_process(false);await frames()
	check(world.north_objects.active and world.north_objects.independent_preview,"Ordinary A1 activates the production independent family without environment flags")
	check(is_instance_valid(world.north_props) and world.north_props.active and world.north_props.objects.size()==53,"All 53 independent generated objects are instantiated by default")
	var counts:={"A1":51,"A2":124,"A3":144}
	for floor_id:String in counts:
		state.d.chapter4.floor=floor_id;state.d.native.floor=floor_id;world.refresh_world();await frames()
		var family:Node2D=world.north_source_objects
		check(family.active and family.floor_id==floor_id and family.objects.size()==counts[floor_id],floor_id+" has its complete registered source-object family")
		check(world.collisions==family.collision_snapshot,floor_id+" source decomposition preserves calibrated physical geometry")
		var before:Dictionary=state.d.duplicate(true);var targets:Array=world.targets.duplicate(true)
		var regions:Array[Rect2]=[];var pixels_unique:=true;var fragments_present:=true
		for object:Node2D in family.objects.values():
			var fragments:Array=object.get_meta("source_fragments")
			fragments_present=fragments_present and object.get_child_count()==fragments.size()
			for fragment:Rect2 in fragments:
				for prior:Rect2 in regions:
					if fragment.intersects(prior):pixels_unique=false
				regions.append(fragment)
		check(pixels_unique and fragments_present,floor_id+" every source pixel has one rendered object owner, including overlaps")
		var clean:Image=family.clean_plate.get_image()
		var source:Image=world.background.get_image()
		if source.is_compressed():source.decompress()
		source.convert(Image.FORMAT_RGBA8)
		var reconstructed:Image=clean.duplicate()
		for region:Rect2 in regions:reconstructed.blit_rect(source,Rect2i(region),Vector2i(region.position))
		check(reconstructed.get_data()==source.get_data(),floor_id+" cutouts reconstruct the immutable original pixel for pixel")
		var cleared:=true
		for row:Dictionary in family.rows:
			var bounds:Rect2=family.area(row.rect)
			cleared=cleared and clean.get_pixelv(Vector2i(bounds.get_center())).a==0
		check(cleared,floor_id+" old baked object pixels are removed from the background")
		check(state.d==before and world.targets==targets,floor_id+" visual composition preserves story and interaction targets")
	OS.set_environment(Objects.PREVIEW_ENV,"0")
	check(Objects.new().independent_preview,"The retired debug switch cannot restore combined production furniture")
	OS.unset_environment(Objects.PREVIEW_ENV)
	world.queue_free();await frames()
	print("NORTH_PRODUCTION_OBJECTS: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
