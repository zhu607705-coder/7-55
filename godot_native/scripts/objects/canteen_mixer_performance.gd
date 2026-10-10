extends "res://scripts/presentation/c3_mixer_motion.gd"
## Source-coordinate, input-transparent mixer body. State remains controller-owned.
var world:Control
var state_node:Node
var bound_state:Dictionary={}
var region_active:=false
var world_buttons:Array[Sprite2D]=[]
const WORLD_BUTTON_ORDER=["sparklingWater","lemonTea","blackCoffee"]
func _ready()->void:
	super._ready()
	for index in range(3):
		var sprite:=Press.sprite(_color(WORLD_BUTTON_ORDER[index]))
		sprite.name="WorldMachineButton"+str(index)
		sprite.scale=Vector2.ONE*(66.0/Press.REGION_SIZE.y)
		sprite.position=Vector2((index-1)*90-33,-330)
		add_child(sprite);world_buttons.append(sprite)
	_pose()
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
	# The counter and glass contact stay fixed. Machine pressure, liquid and
	# final drips observe the accepted controller action only.
	for index in range(world_buttons.size()):
		world_buttons[index].region_rect=Press.region(press_frame() if playing and item_id==WORLD_BUTTON_ORDER[index] else 0)
	scale=Vector2.ONE*.36
func _exit_tree()->void:
	if is_instance_valid(state_node) and state_node.action_completed.is_connected(_on_action):state_node.action_completed.disconnect(_on_action)

func _draw()->void:
	# Same gray-black original dispenser material, kept behind the moving parts.
	draw_texture_rect_region(DISPENSER,Rect2(-153,-340,306,356),Rect2(490,891,274,59))
	draw_texture_rect_region(DISPENSER,Rect2(-153,-340,12,356),Rect2(459,795,28,252))
	draw_texture_rect_region(DISPENSER,Rect2(141,-340,12,356),Rect2(787,795,28,252))
	draw_texture_rect_region(DISPENSER,Rect2(-141,4,282,12),Rect2(491,953,274,70))
