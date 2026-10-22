extends Node2D
## Presentation-only rig at the original 128 x 160 source scale.
## The hull stays rigid. Hand targets, water clipping and effects share one shaft.
const Timeline = preload("res://scripts/presentation/kayak_stroke_timeline.gd")
const WORLD_SCALE: float = 0.52
const GRIP_DISTANCE: float = 22.0
var motion: RefCounted = Timeline.new()
var hull: Sprite2D
var legs: Sprite2D
var waist: Sprite2D
var torso: Sprite2D
var head: Sprite2D
var left_arm: Line2D
var right_arm: Line2D
var left_sleeve: Line2D
var right_sleeve: Line2D
var palms: Array[Sprite2D] = []
var grips: Array[Sprite2D] = []
var paddle: Node2D
var shaft_outline: Line2D
var shaft: Line2D
var blades: Array[Polygon2D] = []
var blade_highlights: Array[Line2D] = []
var water_occlusion: Node2D
var effects: Node2D
var wake: Node2D
var blade_tips: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO]
var blade_points3: Array = [[], []]
var blade_centers3: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]
var blade_world_velocity: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO]
var blade_vertical_velocity: Array[float] = [0.0, 0.0]
var previous_blade_world: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO]
var previous_blade_height: Array[float] = [0.0, 0.0]
var contact_history_ready: bool = false
var hand_points: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO]
var shoulder_points: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO]
var elbows: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO]
var paddle_center3: Vector3 = Vector3.ZERO
var paddle_axis3: Vector3 = Vector3.RIGHT
var submerged_polygon: PackedVector2Array = PackedVector2Array()
var waterline: PackedVector2Array = PackedVector2Array()
var water_contact3: Vector3 = Vector3.ZERO
var water_contact_local: Vector2 = Vector2.ZERO
var wet_blade_surface_local: Vector2 = Vector2.ZERO
var wet_shaft: PackedVector2Array = PackedVector2Array()
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
var last_wet_velocity: Vector2 = Vector2.ZERO
var last_wet_vertical_velocity: float = 0.0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	wake = Node2D.new(); wake.name = "HullWake"; add_child(wake)
	wake.draw.connect(_draw_wake)
	hull = _sprite("Hull", "hull", Vector2(64,80), Vector2.ZERO)
	legs = _sprite("SeatedLegs", "legs", Vector2(64,80), Vector2.ZERO)
	waist = _sprite("WaistRotation", "waist", Vector2(64,80), Vector2.ZERO)
	torso = _sprite("ChestAndShoulders", "torso", Vector2(64,89), Vector2(0,9))
	head = _sprite("Head", "head", Vector2(64,110), Vector2(0,30)); head.z_index = 3
	left_arm = _line(self,"LeftArm",Color("e5b891"),6.0)
	right_arm = _line(self,"RightArm",Color("e5b891"),6.0)
	left_sleeve = _line(self,"LeftSleeve",Color("244f75"),8.0)
	right_sleeve = _line(self,"RightSleeve",Color("244f75"),8.0)
	for i: int in range(2):
		var palm: Sprite2D = _sprite("Palm"+str(i), "hand_palm", Vector2(6,6), Vector2.ZERO)
		palm.z_index = 1; palms.append(palm)
	paddle = Node2D.new(); paddle.name = "DoubleBladePaddle"; paddle.z_index = 2; add_child(paddle)
	shaft_outline = _line(paddle,"ShaftOutline",Color("2c2118"),5.0)
	shaft = _line(paddle,"Shaft",Color("bd8750"),3.0)
	for i: int in range(2):
		var blade := Polygon2D.new(); blade.name = "LeftBlade" if i==0 else "RightBlade"
		blade.color = Color("d99a55"); paddle.add_child(blade); blades.append(blade)
		blade_highlights.append(_line(paddle,"BladeGrain"+str(i),Color("f2bf75"),2.0))
		var grip: Sprite2D = _sprite("GripFingers"+str(i), "hand_grip", Vector2(6,6), Vector2.ZERO)
		grip.z_index = 3; grips.append(grip)
	water_occlusion = Node2D.new(); water_occlusion.name = "BladeWaterOcclusion"; water_occlusion.z_index = 4; add_child(water_occlusion)
	water_occlusion.draw.connect(_draw_water_occlusion)
	effects = Node2D.new(); effects.name = "StrokeSplashAndDrips"; effects.z_index = 5; add_child(effects)
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
	previous_phase="rest"; heading_ready=false; display_speed=0; roll_value=0
	water_strength=0; was_wet=false; submerged_index=0; previous_wet_index=0
	last_wet_world=Vector2.ZERO; last_wet_velocity=Vector2.ZERO; last_wet_vertical_velocity=0
	contact_history_ready=false; boat_world_position=Vector2.ZERO
	for i: int in range(2):
		blade_world_velocity[i]=Vector2.ZERO; blade_vertical_velocity[i]=0
		previous_blade_world[i]=Vector2.ZERO; previous_blade_height[i]=0
	if is_node_ready():
		_sync_rig(); wake.queue_redraw(); water_occlusion.queue_redraw(); effects.queue_redraw()

func set_paused(value: bool) -> void:
	# This is a state transition, not a per-frame reset.
	if motion.paused == value: return
	motion.set_paused(value)
	# Freeze existing droplets with the pose. Invalidate derivatives so neither
	# camera changes during pause nor the first resumed frame can make a splash.
	contact_history_ready=false; emission_clock=0
	for i: int in range(2):
		blade_world_velocity[i]=Vector2.ZERO; blade_vertical_velocity[i]=0

func request_stroke(side: String, reverse: bool=false) -> void:
	motion.request_stroke(side,reverse)

func sync_pose(point: Vector2, heading: float, speed: float, roll: float, zoom: float, delta: float, snap: bool=false, world_position: Vector2=Vector2.ZERO) -> void:
	boat_world_position=world_position
	position=point; scale=Vector2.ONE*zoom*WORLD_SCALE
	if not heading_ready or snap:
		render_heading=heading; heading_ready=true; contact_history_ready=false
	elif not motion.paused:
		# Presentation-only heading filter, with no force or model writes.
		render_heading=lerp_angle(render_heading,heading,1.0-exp(-22.0*maxf(delta,0.0)))
	rotation=render_heading+PI/2
	display_speed=speed; roll_value=clampf(roll,-1.0,1.0)

func advance(delta: float) -> void:
	if motion.paused:return
	var dt: float=maxf(delta,0.0)
	if not contact_history_ready and dt>0:
		_sync_rig(); _sample_blade_velocity(dt)
	motion.advance(dt); effects_clock+=dt; emission_clock+=dt
	_sync_rig()
	_sample_blade_velocity(dt)
	var current_phase: String=motion.phase()
	var wet: bool=water_strength>0.02
	if was_wet and (not wet or previous_wet_index!=submerged_index):
		_emit_splash(last_wet_world,5,true,last_wet_velocity,last_wet_vertical_velocity)
	if wet:
		var velocity: Vector2=blade_world_velocity[submerged_index]
		var vertical: float=blade_vertical_velocity[submerged_index]
		var water_point: Vector2=_local_to_world(wet_blade_surface_local)
		if not was_wet or previous_wet_index!=submerged_index:
			emission_clock=0
			_emit_splash(_local_to_world(water_contact_local),3,false,velocity,vertical)
		if current_phase=="power" and emission_clock>=0.045:
			emission_clock=fmod(emission_clock,0.045)
			_emit_splash(water_point,2,false,velocity,vertical)
		last_wet_world=water_point; last_wet_velocity=velocity; last_wet_vertical_velocity=vertical
	previous_wet_index=submerged_index; was_wet=wet; previous_phase=current_phase
	for i: int in range(spray.size()-1,-1,-1):
		if effects_clock-float(spray[i].born)>.56:spray.remove_at(i)
	wake.queue_redraw(); water_occlusion.queue_redraw(); effects.queue_redraw()

func _sync_rig() -> void:
	if not is_node_ready():return
	var pose: Dictionary=motion.pose()
	var lean: float=float(pose.lean)
	var twist: float=float(pose.twist)
	var hip_twist: float=float(pose.hip_twist)
	# Hips stay seated; chest drives the stroke and head follows more quietly.
	waist.position=Vector2(roll_value*.6,lean*.25); waist.rotation=hip_twist
	torso.position=waist.position+Vector2(0,9+lean*.65).rotated(hip_twist); torso.rotation=twist
	head.position=torso.position+Vector2(0,21).rotated(twist*.55); head.rotation=twist*.22
	var sweep: float=float(pose.sweep)
	var pitch: float=float(pose.pitch)
	paddle_axis3=Vector3(cos(sweep)*cos(pitch),sin(sweep)*cos(pitch),sin(pitch))
	paddle_center3=Vector3(0,3+lean*.25,9+float(pose.lift))
	var end0: Vector2=_project(paddle_center3-paddle_axis3*75)
	var end1: Vector2=_project(paddle_center3+paddle_axis3*75)
	shaft_outline.points=PackedVector2Array([end0,end1]); shaft.points=shaft_outline.points
	var transverse:=Vector3(-sin(sweep),cos(sweep),0)
	var blade_outline: Array[Vector2]=[Vector2(61,-3),Vector2(70,-7),Vector2(86,-5),Vector2(89,0),Vector2(86,5),Vector2(70,7),Vector2(61,3)]
	for i: int in range(2):
		var s: float=-1.0 if i==0 else 1.0
		var points3: Array[Vector3]=[]
		var projected:=PackedVector2Array()
		for vertex: Vector2 in blade_outline:
			var p: Vector3=paddle_center3+paddle_axis3*vertex.x*s+transverse*vertex.y*s
			points3.append(p); projected.append(_project(p))
		blade_points3[i]=points3; blades[i].polygon=projected
		blade_highlights[i].points=PackedVector2Array([_project(paddle_center3+paddle_axis3*66*s),_project(paddle_center3+paddle_axis3*83*s)])
		blade_centers3[i]=paddle_center3+paddle_axis3*78*s
		blade_tips[i]=_project(blade_centers3[i])
		hand_points[i]=_project(paddle_center3+paddle_axis3*GRIP_DISTANCE*s)
		# Shoulders sit beside the chest, near the neck, rather than at the waist.
		shoulder_points[i]=torso.position+Vector2(11*s,7-float(pose.shoulder_drive)*.6).rotated(twist)
		palms[i].position=hand_points[i]; grips[i].position=hand_points[i]
		palms[i].rotation=(end1-end0).angle(); grips[i].rotation=palms[i].rotation
		palms[i].flip_h=i==1; grips[i].flip_h=i==1
	elbows[0]=_arm(left_arm,left_sleeve,shoulder_points[0],hand_points[0],-1)
	elbows[1]=_arm(right_arm,right_sleeve,shoulder_points[1],hand_points[1],1)
	_sync_water_contact(transverse)

func _project(v: Vector3) -> Vector2:
	return Vector2(v.x,v.y-v.z*.65)

func _arm(line: Line2D, sleeve: Line2D, shoulder: Vector2, hand: Vector2, bend: float) -> Vector2:
	var delta: Vector2=hand-shoulder
	var direction: Vector2=delta.normalized()
	# These are projected limbs, not two equal 19px circles. Foreshortening
	# reduces the bend on the near hand; the elbow keeps its outward branch.
	var bend_height: float=minf(10.0,delta.length()*.38)
	var elbow: Vector2=shoulder.lerp(hand,.46)+Vector2(-direction.y,direction.x)*bend_height*bend
	line.points=PackedVector2Array([shoulder,elbow,hand])
	sleeve.points=PackedVector2Array([shoulder,shoulder.lerp(elbow,.66)])
	return elbow

func _sync_water_contact(transverse: Vector3) -> void:
	submerged_polygon.clear(); waterline.clear(); wet_shaft.clear()
	water_strength=0; water_contact3=Vector3.ZERO; water_contact_local=Vector2.ZERO; wet_blade_surface_local=Vector2.ZERO
	var depth0: float=paddle_center3.z-paddle_axis3.z*89
	var depth1: float=paddle_center3.z+paddle_axis3.z*89
	submerged_index=0 if depth0<depth1 else 1
	if minf(depth0,depth1)>=0:return
	var s: float=-1.0 if submerged_index==0 else 1.0
	var outward: Vector3=paddle_axis3*s
	var station: float=-paddle_center3.z/outward.z
	water_contact3=paddle_center3+outward*station
	water_contact3.z=0
	water_contact_local=Vector2(water_contact3.x,water_contact3.y)
	var clipped: Array[Vector3]=_clip_underwater(blade_points3[submerged_index])
	var centroid:=Vector3.ZERO
	for vertex: Vector3 in clipped:
		submerged_polygon.append(_project(vertex)); centroid+=vertex
	if clipped.is_empty():return
	centroid/=clipped.size()
	wet_blade_surface_local=Vector2(centroid.x,centroid.y)
	water_strength=clampf(-minf(depth0,depth1)/10.0,0,1)
	# Intersect the actual blade edges when the surface crosses the blade.
	# At full burial the surface crosses only the narrow shaft near its neck.
	var hits: Array[Vector3]=[]
	var vertices: Array=blade_points3[submerged_index]
	for i: int in range(vertices.size()):
		var a: Vector3=vertices[i]; var b: Vector3=vertices[(i+1)%vertices.size()]
		if (a.z<0)!=(b.z<0):hits.append(a.lerp(b,-a.z/(b.z-a.z)))
	if hits.size()>=2:
		waterline=PackedVector2Array([_project(hits[0]),_project(hits[1])])
	elif station<61:
		var across: Vector2=Vector2(transverse.x,transverse.y)*2.8
		waterline=PackedVector2Array([water_contact_local-across,water_contact_local+across])
	if station<75:wet_shaft=PackedVector2Array([water_contact_local,_project(paddle_center3+outward*75)])

func _clip_underwater(vertices: Array) -> Array[Vector3]:
	var result: Array[Vector3]=[]
	for i: int in range(vertices.size()):
		var a: Vector3=vertices[i]; var b: Vector3=vertices[(i+1)%vertices.size()]
		if a.z<0:result.append(a)
		if (a.z<0)!=(b.z<0):result.append(a.lerp(b,-a.z/(b.z-a.z)))
	return result

func _sample_blade_velocity(dt: float) -> void:
	for i: int in range(2):
		# Differentiate the same material point in the stationary lake frame.
		# Height projection, screen zoom and the moving contact line are excluded.
		var center3: Vector3=blade_centers3[i]
		var world: Vector2=_local_to_world(Vector2(center3.x,center3.y))
		var height_value: float=center3.z*WORLD_SCALE
		blade_world_velocity[i]=(world-previous_blade_world[i])/dt if contact_history_ready and dt>0 else Vector2.ZERO
		blade_vertical_velocity[i]=(height_value-previous_blade_height[i])/dt if contact_history_ready and dt>0 else 0.0
		previous_blade_world[i]=world; previous_blade_height[i]=height_value
	if dt>0:contact_history_ready=true

func _local_to_world(at: Vector2) -> Vector2:
	return boat_world_position+at.rotated(rotation)*WORLD_SCALE

func _emit_splash(at: Vector2, count: int, exiting: bool, velocity: Vector2=Vector2.ZERO, vertical_velocity: float=0.0) -> void:
	var speed: float=velocity.length()
	var energy: float=clampf((speed+absf(vertical_velocity)*.35)/180.0,0.0,1.5)
	var direction: Vector2=velocity.normalized()
	var cross_direction:=Vector2(-direction.y,direction.x)
	var number: int=maxi(1,int(round(count*clampf(energy,.35,1.3))))
	for i: int in range(number):
		# A deterministic spread changes only the spray fan, never its source
		# direction or energy. Reverse is already present in measured motion.
		var fan: float=float((motion.started_strokes*17+i*7)%11)/5.0-1.0
		var drop_velocity: Vector2=velocity*.16+cross_direction*fan*minf(speed,240)*.10
		var lift: float=(7.0 if exiting else 3.0)+energy*(13.0 if exiting else 5.0)
		spray.append({"point":at,"born":effects_clock,"velocity":drop_velocity,"height":lift,"large":exiting,"source_velocity":velocity,"intensity":energy})
	if spray.size()>90:spray=spray.slice(spray.size()-90)

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
	if submerged_polygon.size()>=3:
		water_occlusion.draw_colored_polygon(submerged_polygon,Color(.09,.39,.43,.68))
	if wet_shaft.size()==2:water_occlusion.draw_polyline(wet_shaft,Color(.09,.39,.43,.60),4.0,false)
	if waterline.size()==2:
		water_occlusion.draw_polyline(waterline,Color(.75,.96,.94,.85),1.5,false)
		var speed: float=blade_world_velocity[submerged_index].length()
		if speed>8:
			var trailing: Vector2=-blade_world_velocity[submerged_index].normalized().rotated(-rotation)*minf(5.0,speed*.025)
			water_occlusion.draw_line(waterline[0],waterline[0]+trailing,Color(.65,.91,.92,.5),1,false)
			water_occlusion.draw_line(waterline[1],waterline[1]+trailing,Color(.65,.91,.92,.5),1,false)

func _draw_effects() -> void:
	for drop: Dictionary in spray:
		var age_value: float=effects_clock-float(drop.born)
		var u: float=age_value/.56
		var world: Vector2=drop.point+drop.velocity*age_value
		var p: Vector2=(world-boat_world_position).rotated(-rotation)/WORLD_SCALE
		p+=Vector2(0,-sin(u*PI)*float(drop.height)).rotated(-rotation)
		var extent: float=2.0 if bool(drop.large) else 1.4
		effects.draw_rect(Rect2(p.round(),Vector2(extent,extent+1)),Color(.79,.96,.96,(1-u)*.9))
