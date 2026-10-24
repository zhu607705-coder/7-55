extends "res://tests/test_full_campaign.gd"
## Portable boundaries earned by the existing fresh C1→library controller route.
## Spatial test setup remains explicit in the parent; these are not walking proof.
var capture_dir:=OS.get_environment("LIBRARY_CAPTURE_DIR")
func run()->void:
	state=root.get_node("State");state.d=state.initial()
	witness=Node.new();root.add_child(witness)
	for module in state.modules:
		var script_path:String=module.get_script().resource_path
		if script_path.ends_with("/chapter3.gd"):chapter3=module
		if script_path.ends_with("/chapter4.gd"):chapter4=module
	pages.action_requested.connect(func(id,value):state.act(id,value))
	pages.page_requested.connect(func(id):state.open_page(id))
	await beginning()
	if failures==0:await library()
	await finish()
func step(id:String,value:Variant=null)->Dictionary:
	if id=="lib_sit":capture("before_library_sit")
	var result:Dictionary=await super.step(id,value)
	if id=="lib_shelf":capture("before_library_rule_read")
	if id=="lib_sit":capture("before_library_022_opening")
	if id=="lib_opening_complete":capture("after_library_handoff")
	return result
func capture(label:String)->void:
	if capture_dir.is_empty():return
	DirAccess.make_dir_recursive_absolute(capture_dir)
	check(state.export_save(capture_dir.path_join(label+".json"))==OK,"earned library boundary "+label)
