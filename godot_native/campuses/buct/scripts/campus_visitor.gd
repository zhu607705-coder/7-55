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
# Match the original miniature's 18-source-pixel silhouette; never alter its feet collider.
@export var display_height := 18.0

func _ready() -> void:
	name = "CampusVisitor"
	collision_layer = 2
	collision_mask = 1
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var shape := CollisionShape2D.new()
	shape.name = "FeetCollision"
	var circle := CircleShape2D.new()
	circle.radius = 3.0
	shape.shape = circle
	add_child(shape)
	character_visual=Node2D.new();character_visual.name="StudentVisual"
	character_visual.set_script(STUDENT_VISUAL);add_child(character_visual)
	var profile: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(STUDENT_ROOT+"data/student-movement-profile.json")).duplicate(true)
	# Full-map visual calibration: 88px/s with an 18px student gives ~1.88 cycles/s.
	# The accepted source profile stays unchanged; physical movement remains controller-owned.
	profile["cycle_stride_body_heights"]=2.6
	var extras: Dictionary={}
	for key in profile.get("available_walk_atlases",{}):
		extras[key]=load(STUDENT_ROOT+"assets/"+str(profile.available_walk_atlases[key]))
	if not character_visual.configure(profile,load(STUDENT_ROOT+"assets/"+str(profile.atlas)),display_height,extras):
		push_error("Cannot configure the approved four-direction BUCT student artwork")
	# A tiny above-canopy foot ring preserves control location without fading leaves.
	var locator:=Node2D.new();locator.name="CanopyFootLocator";locator.z_index=30;locator.visible=false
	add_child(locator)
	for style in [[2.6,Color("f6f1cf")],[1.1,Color("2e776e")]]:
		var ring:=Line2D.new();ring.width=style[0];ring.default_color=style[1]
		for i in range(25):ring.add_point(Vector2.from_angle(i*TAU/24.0)*4.5+Vector2(0,1))
		locator.add_child(ring)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(map): return
	var direction := Vector2.ZERO
	if not map.movement_paused():
		direction = Input.get_vector("buct_walk_left","buct_walk_right","buct_walk_up","buct_walk_down")
		manual_input = direction
		if direction.length_squared() > 0.01:
			map.cancel_route_for_manual_input()
		else:
			direction = map.route_direction(global_position)
	var current_speed: float = map.tour_speed if map.guide_active else speed
	if Input.is_action_pressed("buct_walk_fast") and not map.guide_active: current_speed *= 1.45
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

func _draw() -> void:
	# Contact shadow only. Approved transparent student artwork lives on the feet-anchored child.
	draw_set_transform(Vector2.ZERO,0,Vector2(1,0.40))
	draw_circle(Vector2.ZERO,4.1,Color(0.12,0.17,0.14,0.19))
	draw_set_transform(Vector2.ZERO)
