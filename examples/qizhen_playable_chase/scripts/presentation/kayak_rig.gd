extends Node2D
## Layered native rig at the original 128 x 160 source scale.
## Hull/legs/torso/head are lossless groups from the existing vector source.
const Timeline = preload("res://scripts/presentation/kayak_stroke_timeline.gd")
var motion: RefCounted = Timeline.new()
var hull: Sprite2D
var legs: Sprite2D
var torso: Sprite2D
var head: Sprite2D
var left_arm: Line2D
var right_arm: Line2D
var left_sleeve: Line2D
var right_sleeve: Line2D
var paddle: Node2D
var shaft_outline: Line2D
var shaft: Line2D
var blades: Array[Polygon2D] = []
var blade_highlights: Array[Line2D] = []
var water_occlusion: Node2D
var effects: Node2D
var wake: Node2D
var blade_tips: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO]
var spray: Array[Dictionary] = []
var previous_phase: String = "rest"
var render_heading: float = 0.0
var heading_ready: bool = false
var display_speed: float = 0.0
var roll_value: float = 0.0
var effects_clock: float = 0.0
var water_strength: float = 0.0
var submerged_index: int = 0
var emission_clock: float = 0.0
var boat_world_position: Vector2 = Vector2.ZERO
var was_wet: bool = false
var previous_wet_index: int = 0
var last_wet_world: Vector2 = Vector2.ZERO

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	wake = Node2D.new(); wake.name = "HullWake"; add_child(wake)
	wake.draw.connect(_draw_wake)
	hull = _sprite("Hull", "hull", Vector2(64,80), Vector2.ZERO)
	legs = _sprite("SeatedLegs", "legs", Vector2(64,80), Vector2.ZERO)
	torso = _sprite("TorsoTwist", "torso", Vector2(64,92), Vector2(0,12))
	head = _sprite("Head", "head", Vector2(64,110), Vector2(0,30))
	left_arm = _line(self,"LeftArm",Color("e5b891"),7.0)
	right_arm = _line(self,"RightArm",Color("e5b891"),7.0)
	left_sleeve = _line(self,"LeftSleeve",Color("244f75"),9.0)
	right_sleeve = _line(self,"RightSleeve",Color("244f75"),9.0)
	paddle = Node2D.new(); paddle.name = "DoubleBladePaddle"; add_child(paddle)
	shaft_outline = _line(paddle,"ShaftOutline",Color("2c2118"),5.0)
	shaft = _line(paddle,"Shaft",Color("bd8750"),3.0)
	for i: int in range(2):
		var blade := Polygon2D.new(); blade.name = "LeftBlade" if i==0 else "RightBlade"
		blade.color = Color("d99a55"); paddle.add_child(blade); blades.append(blade)
		blade_highlights.append(_line(paddle,"BladeGrain"+str(i),Color("f2bf75"),2.0))
	water_occlusion = Node2D.new(); water_occlusion.name = "BladeWaterOcclusion"; add_child(water_occlusion)
	water_occlusion.draw.connect(_draw_water_occlusion)
	effects = Node2D.new(); effects.name = "StrokeSplashAndDrips"; add_child(effects)
	effects.draw.connect(_draw_effects)
	_sync_rig()

func _sprite(label: String, asset: String, pivot: Vector2, at: Vector2) -> Sprite2D:
	var node := Sprite2D.new(); node.name = label
	node.texture = load("res://assets/paddling/"+asset+".svg")
	node.centered = false; node.offset = -pivot; node.position = at
	add_child(node); return node

func _line(parent: Node, label: String, color: Color, width_value: float) -> Line2D:
	var line := Line2D.new(); line.name=label; line.default_color=color; line.width=width_value
	line.begin_cap_mode=Line2D.LINE_CAP_BOX; line.end_cap_mode=Line2D.LINE_CAP_BOX
	line.joint_mode=Line2D.LINE_JOINT_BEVEL; line.antialiased=false
	parent.add_child(line); return line

func reset() -> void:
	motion.reset(); spray.clear(); effects_clock=0; emission_clock=0
	previous_phase="rest"; heading_ready=false; display_speed=0; water_strength=0; was_wet=false
	if is_node_ready(): _sync_rig()

func set_paused(value: bool) -> void:
	motion.set_paused(value)

func request_stroke(side: String, reverse: bool=false) -> void:
	motion.request_stroke(side,reverse)

func sync_pose(point: Vector2, heading: float, speed: float, roll: float, zoom: float, delta: float, snap: bool=false, world_position: Vector2=Vector2.ZERO) -> void:
	boat_world_position=world_position
	position=point; scale=Vector2.ONE*zoom*0.52
	if not heading_ready or snap:
		render_heading=heading; heading_ready=true
	elif not motion.paused:
		# Presentation-only 45ms heading filter smooths the controller's
		# discrete impulse without changing its heading/velocity/collision.
		render_heading=lerp_angle(render_heading,heading,1.0-exp(-22.0*maxf(delta,0.0)))
	rotation=render_heading+PI/2
	display_speed=speed; roll_value=clampf(roll,-1.0,1.0)

func advance(delta: float) -> void:
	if motion.paused:return
	var dt: float=maxf(delta,0.0)
	motion.advance(dt); effects_clock+=dt; emission_clock+=dt
	_sync_rig()
	var current_phase: String=motion.phase()
	var wet: bool=water_strength>0.02
	if was_wet and (not wet or previous_wet_index!=submerged_index):
		_emit_splash(last_wet_world,7,true)
	if wet:
		var water_point: Vector2=_local_to_world(blade_tips[submerged_index])
		if not was_wet:_emit_splash(water_point,3,false)
		if current_phase=="power" and emission_clock>=0.045:
			emission_clock=0.0
			_emit_splash(water_point,2,false)
		last_wet_world=water_point
	previous_wet_index=submerged_index
	was_wet=wet
	previous_phase=current_phase
	for i: int in range(spray.size()-1,-1,-1):
		if effects_clock-float(spray[i].born)>.56:spray.remove_at(i)
	wake.queue_redraw(); water_occlusion.queue_redraw(); effects.queue_redraw()

func _sync_rig() -> void:
	if not is_node_ready():return
	var pose: Dictionary=motion.pose()
	var lean: float=float(pose.lean)
	var twist: float=float(pose.twist)
	torso.position=Vector2(roll_value*1.2,12+lean);torso.rotation=twist
	head.position=torso.position+Vector2(0,18).rotated(twist*.45);head.rotation=twist*.25
	# A single rigid shaft in 3D; its ends have opposite depth. Projection
	# changes the shape honestly rather than stretching a baked boat sprite.
	var sweep: float=float(pose.sweep)
	var pitch: float=float(pose.pitch)
	var axis3:=Vector3(cos(sweep)*cos(pitch),sin(sweep)*cos(pitch),sin(pitch))
	var center3:=Vector3(0,3+lean*.25,9+float(pose.lift))
	var end0: Vector2=_project(center3-axis3*75)
	var end1: Vector2=_project(center3+axis3*75)
	shaft_outline.points=PackedVector2Array([end0,end1]);shaft.points=shaft_outline.points
	for i: int in range(2):
		var s: float=-1.0 if i==0 else 1.0
		var tip: Vector2=_project(center3+axis3*86*s)
		var neck: Vector2=_project(center3+axis3*61*s)
		var axis: Vector2=(tip-neck).normalized();var perpendicular:=Vector2(-axis.y,axis.x)
		blades[i].polygon=PackedVector2Array([neck-perpendicular*3,neck+axis*9-perpendicular*7,tip-perpendicular*5,tip+axis*3,tip+perpendicular*5,neck+axis*9+perpendicular*7,neck+perpendicular*3])
		blade_highlights[i].points=PackedVector2Array([neck+axis*5,tip-axis*3])
		blade_tips[i]=tip-axis*8
	var shoulder_l: Vector2=torso.position+Vector2(-11,-8).rotated(twist)
	var shoulder_r: Vector2=torso.position+Vector2(11,-8).rotated(twist)
	var hand_l: Vector2=_project(center3-axis3*22)
	var hand_r: Vector2=_project(center3+axis3*22)
	_arm(left_arm,left_sleeve,shoulder_l,hand_l,-1)
	_arm(right_arm,right_sleeve,shoulder_r,hand_r,1)
	# Derive wetness from the actual blended 3D blade depth. During rapid
	# side changes the dry opposite blade must never inherit the old mask.
	var left_depth: float=center3.z-axis3.z*78
	var right_depth: float=center3.z+axis3.z*78
	submerged_index=0 if left_depth<right_depth else 1
	water_strength=clampf(-minf(left_depth,right_depth)/9.5,0.0,1.0)

func _project(v: Vector3) -> Vector2:
	return Vector2(v.x,v.y-v.z*.65)

func _arm(line: Line2D, sleeve: Line2D, shoulder: Vector2, hand: Vector2, bend: float) -> void:
	var delta: Vector2=hand-shoulder
	var direction: Vector2=delta.normalized()
	var midpoint: Vector2=(shoulder+hand)*.5
	var height: float=sqrt(maxf(0.0,19.0*19.0-delta.length_squared()*.25))
	var elbow: Vector2=midpoint+Vector2(-direction.y,direction.x)*height*bend
	line.points=PackedVector2Array([shoulder,elbow,hand])
	sleeve.points=PackedVector2Array([shoulder,shoulder.lerp(elbow,.40)])

func _local_to_world(at: Vector2) -> Vector2:
	return boat_world_position+at.rotated(rotation)*.52

func _emit_splash(at: Vector2, count: int, exiting: bool) -> void:
	for i: int in range(count):
		var n: float=float((motion.started_strokes*17+i*7)%11)
		var velocity:=Vector2((n-5)*10,(17+n*2)*(-1.0 if motion.reverse else 1.0)).rotated(rotation)*.52
		spray.append({"point":at,"born":effects_clock,"velocity":velocity,"height":18+n*2 if exiting else 5+n,"large":exiting})
	if spray.size()>90:spray= spray.slice(spray.size()-90)

func _ellipse(node: CanvasItem, at: Vector2, dimensions: Vector2, color: Color, width_value: float=1.0) -> void:
	var points:=PackedVector2Array()
	for i: int in range(25):points.append(at+Vector2(cos(TAU*i/24),sin(TAU*i/24))*dimensions)
	node.draw_polyline(points,color,width_value,false)

func _draw_wake() -> void:
	var amount: float=clampf(absf(display_speed)/340.0,0,1)
	if amount<.01:return
	var direction: float=1 if display_speed>=0 else -1
	for i: int in range(3):
		var u: float=fmod(effects_clock*1.5+i/3.0,1.0)
		var a: float=(1-u)*amount*.40
		_ellipse(wake,Vector2(0,(64+u*60)*direction),Vector2(16+u*20,8+u*19),Color(.66,.91,.94,a),1.5)

func _draw_water_occlusion() -> void:
	if water_strength<=.001:return
	var index: int=submerged_index
	# Tint + partial visibility belongs solely to the submerged active blade.
	# The hull, arms, shaft and dry blade never receive this water mask.
	water_occlusion.draw_colored_polygon(blades[index].polygon,Color(.09,.39,.43,.72*water_strength))
	var p: Vector2=blade_tips[index]
	_ellipse(water_occlusion,p,Vector2(14,5),Color(.73,.95,.94,.83*water_strength),1.5)
	water_occlusion.draw_line(p+Vector2(-9,0),p+Vector2(8,-1),Color(.84,.98,.96,.8*water_strength),1.5,false)

func _draw_effects() -> void:
	for drop: Dictionary in spray:
		var age_value: float=effects_clock-float(drop.born)
		var u: float=age_value/.56
		var world: Vector2=drop.point+drop.velocity*age_value
		var p: Vector2=(world-boat_world_position).rotated(-rotation)/.52
		p+=Vector2(0,-sin(u*PI)*float(drop.height)).rotated(-rotation)
		var extent: float=2.0 if bool(drop.large) else 1.4
		effects.draw_rect(Rect2(p.round(),Vector2(extent,extent+1)),Color(.79,.96,.96,(1-u)*.9))
