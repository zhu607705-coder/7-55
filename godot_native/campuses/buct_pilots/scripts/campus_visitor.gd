extends CharacterBody2D
## Small overhead visitor. Position is the feet, not the head/sprite center.
var map: Node2D
var walking := false
var phase := 0.0
var facing := Vector2.DOWN
var speed := 88.0
var manual_input := Vector2.ZERO
var last_motion := Vector2.ZERO

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
	queue_redraw()

func _draw() -> void:
	# Vector-built miniature, no generic replacement scenery or raster editing.
	draw_set_transform(Vector2(0,-1),0,Vector2(1,0.40))
	draw_circle(Vector2.ZERO,6.3,Color(0.12,0.17,0.14,0.22))
	draw_set_transform(Vector2.ZERO)
	var step := sin(phase)*1.5 if walking else 0.0
	var navy := Color("344e59")
	draw_line(Vector2(-2,-5),Vector2(-2+step,0),navy,2.5,true)
	draw_line(Vector2(2,-5),Vector2(2-step,0),navy,2.5,true)
	draw_circle(Vector2(-2+step,0),1.6,Color("493d32"))
	draw_circle(Vector2(2-step,0),1.6,Color("493d32"))
	draw_style_box(_coat(),Rect2(-4,-12,8,9))
	draw_line(Vector2(-4,-10),Vector2(-5,-6-step),Color("d9c49d"),2.0,true)
	draw_line(Vector2(4,-10),Vector2(5,-6+step),Color("d9c49d"),2.0,true)
	if facing.y<0.25: draw_style_box(_pack(),Rect2(-2.8,-10,5.6,6))
	draw_circle(Vector2(0,-14),3.7,Color("6b5139"))
	draw_circle(Vector2(0,-13.1),2.8,Color("d7bb8f"))
	draw_arc(Vector2(0,-14.5),3.1,PI,TAU,12,Color("514433"),2.6,true)
	draw_arc(Vector2(0,1),7.2,0.1,PI-0.1,20,Color(0.31,0.64,0.59,0.8),0.8,true)

func _coat() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color=Color("577b81")
	s.corner_radius_top_left=3; s.corner_radius_top_right=3
	s.corner_radius_bottom_left=2; s.corner_radius_bottom_right=2
	return s
func _pack() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color=Color("bead83")
	s.corner_radius_top_left=2; s.corner_radius_top_right=2
	s.corner_radius_bottom_left=1; s.corner_radius_bottom_right=1
	return s
