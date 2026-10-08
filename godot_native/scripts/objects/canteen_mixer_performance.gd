extends "res://scripts/presentation/c3_mixer_motion.gd"
## Source-coordinate, input-transparent mixer body. State remains controller-owned.
var world:Control
var state_node:Node
var bound_state:Dictionary={}
var region_active:=false
func setup(owner_world:Control)->void:
	world=owner_world;name="MixerPerformance";position=Vector2(260,775);scale=Vector2.ONE*.36
	set_meta("source_depth",818.0);z_index=preload("res://scripts/objects/canteen_scene_object.gd").draw_layer(818)
	if world==null:return
	state_node=world.get_node("/root/State");state_node.action_completed.connect(_on_action)
func sync(s:Dictionary,active:bool)->void:
	region_active=active
	if not is_same(bound_state,s) or not active:
		bound_state=s;reset(s.get("canteenHunt",{}).get("drinkMixSequence",[]))
	else:set_sequence(s.get("canteenHunt",{}).get("drinkMixSequence",[]))
	reduced=bool(s.native.settings.get("reduced_motion",false))
func _on_action(action:String,before:Dictionary,next:Dictionary,result:Dictionary)->void:
	if not region_active or str(next.native.scene)!="canteen_interior":return
	accept(action,before,next,result)
func _process(delta:float)->void:
	if not region_active or world==null:return
	var visible_world:=world.is_visible_in_tree()
	if is_instance_valid(world.host_node):visible_world=visible_world and world.host_node.world_frame.is_visible_in_tree()
	if not visible_world:
		if playing:reset(bound_state.get("canteenHunt",{}).get("drinkMixSequence",[]))
		return
	super._process(delta)
func _pose()->void:
	super._pose()
	# The source-coordinate cup briefly swells against its fixed counter contact.
	# This has no body/click surface and never changes the cabinet footprint.
	var swell:float=0.0
	if playing and not outcome.is_empty() and not reduced:swell=.28*sin(clampf(elapsed_ms/duration_ms,0,1)*PI)
	scale=Vector2.ONE*(.36+swell)
func _exit_tree()->void:
	if is_instance_valid(state_node) and state_node.action_completed.is_connected(_on_action):state_node.action_completed.disconnect(_on_action)
