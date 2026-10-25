extends SceneTree
## Default/main behavior and the explicit, debug-only 53-object preview are
## separate configurations of one renderer, not separate progression systems.
const Objects=preload("res://scripts/presentation/north_generated_objects.gd")
const Metrics=preload("res://scripts/player_metrics.gd")
var checks:=0
var failures:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func frames()->void:
	for i in 3:await process_frame
func run()->void:
	if not preload("res://tests/native_test_isolation.gd").is_isolated_save():quit(2);return
	for request:String in ["","0","true","1"]:
		check(not Objects.preview_allowed(false,request),"Production/release refuses every environment request: "+request)
		check(Objects.preview_allowed(true,request)==(request=="1"),"Debug preview requires exact explicit opt-in: "+request)
	OS.unset_environment(Objects.PREVIEW_ENV)
	var state:Node=root.get_node("State");state.developer_mode=true
	state.begin_checkpoint("c4-755-classrooms-1850")
	state.d.chapter4.mode="light";state.d.native.mode="light"
	var baseline:Control=load("res://scripts/world.gd").new();root.add_child(baseline);baseline.set_process(false);await frames()
	var family:RefCounted=baseline.north_objects
	check(not family.independent_preview and family.active,"Ordinary A1 keeps main's existing pilot, not raw-plate fallback")
	check(not is_instance_valid(baseline.north_props),"Default world never instantiates the independent-node rendering path")
	check(FileAccess.get_sha256("res://data/native/north-baseline-objects.json")=="d689820ba7c791fcd846dce209e358616c118a4c2672ecbc64485a7b0c878500","Default data is byte-identical to main abd8b0028e8443795518243da7930ee760bc92e9")
	check(family.prop_textures.is_empty() and family.asset_registrations().is_empty() and family.object_registrations().is_empty(),"Default path loads no new masters or independent cleanup registrations")
	check(not family.owns_cover({"id":"a1_foreground_019"}),"Default retains original 105 lectern foreground")
	check(family.data.wall.get("sourceExclusions",[]).is_empty() and family.data.wall.get("restoredSourceParts",[]).is_empty(),"Default wall retains main's original source overlays without preview exclusions")
	var contact:=Vector2(1308,584)-Metrics.FOOT_CENTER_OFFSET-Vector2(0,Metrics.FOOT_SIZE.y/2)
	check(baseline.can_stand(contact) and family.wall_in_front(contact),"PR173 exact-contact wall reveal remains active by default")
	var original:Array=baseline.spec.layout.floors[0].staticCollisions.duplicate(true)
	var baseline_collisions:Array=family.adjusted_collisions(original)
	var targets:Array=baseline.targets.duplicate(true)
	var before:Dictionary=state.d.duplicate(true)
	OS.set_environment(Objects.PREVIEW_ENV,"1")
	var preview:Control=load("res://scripts/world.gd").new();root.add_child(preview);preview.set_process(false);await frames()
	check(preview.north_objects.independent_preview and preview.north_props.active,"Explicit debug opt-in activates preview")
	check(preview.north_props.objects.size()==53,"Preview retains exactly 53 independent object nodes")
	check(preview.north_objects.adjusted_collisions(original)==baseline_collisions,"Preview and default share all authored calibrated collisions")
	check(preview.targets==targets and state.d==before,"Opt-in does not change targets, progression or save state")
	check(preview.north_objects.wall_in_front(contact),"PR173 exact-contact wall reveal also holds in preview")
	OS.unset_environment(Objects.PREVIEW_ENV)
	check(not Objects.new().independent_preview,"Removing opt-in gives subsequent worlds the default configuration")
	baseline.queue_free();preview.queue_free();await frames()
	print("NORTH_PREVIEW_GATE: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
