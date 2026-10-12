extends CharacterBody2D
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
	var profile: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(STUDENT_ROOT+"data/student-movement-profile.json"))
	# Whole-campus travel is faster than the 8px/s art pilot. Keep actual displacement
	# driving phases, using a map-specific 46.8px stride: 1.88 cycles/s at speed 88.
	# This is an animation-readability calibration, not a biological gait claim.
	profile["cycle_stride_body_heights"]=2.6
	var extras: Dictionary={}
	for key in profile.get("available_walk_atlases",{}):
		extras[key]=load(STUDENT_ROOT+"assets/"+str(profile.available_walk_atlases[key]))
	if not character_visual.configure(profile,load(STUDENT_ROOT+"assets/"+str(profile.atlas)),display_height,extras):
		push_error("Cannot configure approved BUCT student artwork")

func _physics_process(delta: float) -> void:
	if not is_instance_valid(map): return
	var direction := Vector2.ZERO
	if not map.movement_paused():
		direction = Input.get_vector("buct_changping_walk_left","buct_changping_walk_right","buct_changping_walk_up","buct_changping_walk_down")
		manual_input = direction
		if direction.length_squared() > 0.01:
			map.cancel_route_for_manual_input()
		else:
			direction = map.route_direction(global_position)
	var current_speed: float = map.tour_speed if map.guide_active else speed
	if Input.is_action_pressed("buct_changping_walk_fast") and not map.guide_active: current_speed *= 1.45
	var wanted := direction * current_speed
	var motion := wanted * delta
	# Union-of-paved-polygons restriction; real building and trunk collisions remain native.
	if motion.length_squared() > 0:
		if not map.is_walkable(global_position + motion):
			if map.is_walkable(global_position+Vector2(motion.x,0)): wanted.y=0
			elif map.is_walkable(global_position+Vector2(0,motion.y)): wanted.x=0
			else: wanted=Vector2.ZERO
			map.notify_boundary()
	velocity = wanted
	var previous := global_position
	move_and_slide()
	last_motion = global_position-previous
	walking = last_motion.length_squared()>0.0001
	if walking:
		facing=last_motion.normalized()
		phase += delta*11.0
	character_visual.advance_motion(last_motion,delta)
	queue_redraw()

func _draw() -> void:
	# Static ground contact only; body/limbs are the approved transparent student frames.
	draw_set_transform(Vector2.ZERO,0,Vector2(1,0.42))
	draw_circle(Vector2.ZERO,3.0,Color(0.12,0.17,0.14,0.19))
	draw_set_transform(Vector2.ZERO)
