extends CharacterBody2D
const SpatialRules=preload("res://scripts/space/spatial_rules.gd")
## Small overhead visitor. Position is the feet, not the head/sprite center.
var map: Node2D
var walking := false
var phase := 0.0
var facing := Vector2.DOWN
var speed := 88.0
var manual_input := Vector2.ZERO
var last_motion := Vector2.ZERO
const STUDENT_ROOT := "res://campuses/buct_shared/student/"
const STUDENT_VISUAL = preload(STUDENT_ROOT + "scripts/registered_character_visual.gd")
var character_visual: Node2D
@export var character_profile_path := STUDENT_ROOT + "data/student-movement-profile.json"
@export var display_height := 10.0
@export var show_registration_ring := false

func _ready() -> void:
	name = "CampusVisitor"
	collision_layer = 2
	collision_mask = 1
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var shape := CollisionShape2D.new()
	shape.name = "FeetCollision"
	var circle := CircleShape2D.new()
	circle.radius = 1.65
	shape.shape = circle
	add_child(shape)
	character_visual=Node2D.new();character_visual.name="StudentVisual"
	character_visual.set_script(STUDENT_VISUAL);add_child(character_visual)
	var profile: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(character_profile_path))
	var artwork_root := character_profile_path.get_base_dir().get_base_dir()+"/assets/"
	var extras: Dictionary={}
	for key in profile.get("available_walk_atlases",{}):
		extras[key]=load(artwork_root+str(profile.available_walk_atlases[key]))
	if not character_visual.configure(profile,load(artwork_root+str(profile.atlas)),display_height,extras):
		push_error("Cannot configure the registered BUCT student artwork")
		if is_instance_valid(map):map.return_to_entry()

func _physics_process(delta: float) -> void:
	if not is_instance_valid(map): return
	var direction := Vector2.ZERO
	if not map.movement_paused():
		direction = map.walk_input()
		manual_input = direction
		if direction.length_squared() > 0.01:
			map.cancel_route_for_manual_input()
		else:
			direction = map.route_direction(global_position)
	var current_speed: float = map.tour_speed if map.guide_active else speed
	if Input.is_action_pressed("buct_pilot_walk_fast") and not map.guide_active: current_speed *= 1.45
	var wanted := direction * current_speed
	var motion := wanted * delta
	if manual_input.length_squared()<.01:
		motion=motion.limit_length(global_position.distance_to(map.route_motion_target()))
	# Sweep the original foot circle to contact on both axes. Native bodies
	# still separate real buildings and trunks after this ground constraint.
	var goal:=SpatialRules.sweep_axis(global_position,Vector2(motion.x,0),map.is_walkable,1.0)
	goal=SpatialRules.sweep_axis(goal,Vector2(0,motion.y),map.is_walkable,1.0)
	if goal.distance_squared_to(global_position+motion)>.00001:map.notify_boundary()
	velocity=(goal-global_position)/delta if delta>0 else Vector2.ZERO
	var previous := global_position
	move_and_slide()
	if not map.is_walkable(global_position) and map.is_walkable(previous):
		global_position=previous;velocity=Vector2.ZERO
	last_motion = global_position-previous
	walking = last_motion.length_squared()>0.0001
	if walking:
		facing=last_motion.normalized()
		phase += delta*11.0
	character_visual.advance_motion(last_motion,delta)
	queue_redraw()

func stop_motion(reset_facing: bool = false) -> void:
	velocity=Vector2.ZERO;manual_input=Vector2.ZERO;last_motion=Vector2.ZERO
	walking=false;phase=0.0
	if is_instance_valid(character_visual):
		if reset_facing:
			facing=Vector2.DOWN;character_visual.reset_pose()
		else:character_visual.advance_motion(Vector2.ZERO,0.0)
	queue_redraw()

func _draw() -> void:
	# Ground contact is separate from every transparent body frame.
	draw_set_transform(Vector2.ZERO,0,Vector2(1,0.42))
	draw_circle(Vector2.ZERO,2.3,Color(0.12,0.17,0.14,0.19))
	draw_set_transform(Vector2.ZERO)
	if show_registration_ring:
		draw_arc(Vector2(0,0.5),3.4,0.1,PI-0.1,20,Color(0.31,0.64,0.59,0.8),0.38,true)
