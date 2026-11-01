extends RefCounted
## Everything uses the existing fixed-camera mesh pool and one physical plane.
static func draw(r: Node, v: Control) -> void:
	var bounds: Rect2 = v.Model.BOUNDS
	r.box("coupling_tray",r.p(bounds.get_center(),1.5),Vector3(bounds.size.x+16,3,(bounds.size.y+16)/r.Q),r.DARK)
	for edge: Rect2 in [Rect2(bounds.position-Vector2(8,8),Vector2(bounds.size.x+16,8)),Rect2(bounds.position+Vector2(-8,bounds.size.y),Vector2(bounds.size.x+16,8)),Rect2(bounds.position-Vector2(8,0),Vector2(8,bounds.size.y)),Rect2(bounds.position+Vector2(bounds.size.x,0),Vector2(8,bounds.size.y))]:
		r.box("rim"+str(edge),r.p(edge.get_center(),10),Vector3(edge.size.x,14,edge.size.y/r.Q),r.TEAL)
	var wall_index := 0
	for wall: Rect2 in v.model.walls():
		r.box("barrier"+str(wall_index),r.p(wall.get_center(),16),Vector3(wall.size.x,26,wall.size.y/r.Q),r.DARK)
		r.box("barrier_cap"+str(wall_index),r.p(wall.get_center(),30),Vector3(wall.size.x-4,2,wall.size.y/r.Q-4),r.METAL)
		wall_index += 1
	var pads: Array = v.model.targets()
	for i: int in 2:
		var target: Vector2 = pads[i]
		r.box("contact_well"+str(i),r.p(target,3.5),Vector3(54,1,54/r.Q),r.DARK)
		for x: float in [-17,17]:
			r.box("copper_contact"+str([i,x]),r.p(target+Vector2(x,0),4.5),Vector3(6,1,45/r.Q),Color("c49559"),Basis.IDENTITY,.6)
		var wire := Vector2(646,target.y)
		r.tube("contact_wire"+str(i),r.p(target,4),r.p(wire,4),1.4,Color("c49559"),.5)
		r.tube("return_wire"+str(i),r.p(wire,4),r.p(Vector2(646,254+i*20),4),1.4,Color("c49559"),.5)
		r.tube("fixture_wire"+str(i),r.p(Vector2(646,254+i*20),4),r.p(Vector2(745,254+i*20),4),1.5,Color("c49559"),.5)
		var at: Vector2 = v.model.positions[i]
		r.box("slider"+str(i),r.p(at,13),Vector3(48,20,48/r.Q),r.TEAL if i==0 else r.BLUE)
		for x: float in [-14,14]:
			r.box("slider_rail"+str([i,x]),r.p(at+Vector2(x,0),24),Vector3(4,2,35/r.Q),r.METAL)
		r.cylinder("pin"+str(i),r.p(at,26),6,6,Color("c49559"),Basis.IDENTITY,.7)
		# Distinct physical silhouettes remain legible without relying on color.
		if i==0: r.cylinder("round_mark",r.p(at+Vector2(0,15),24),3,2,r.IVORY)
		else: r.box("square_mark",r.p(at+Vector2(0,15),24),Vector3(6,2,6),r.IVORY)
	var clip_drag: Vector2 = v.drag_delta if v.gesture=="clip" else Vector2.ZERO
	if v.model.linked:
		var from: Vector3 = r.p(v.model.positions[0],31)+Vector3(clip_drag.x,0,clip_drag.y/r.Q)*r.U
		var to: Vector3 = r.p(v.model.positions[1],31)+Vector3(clip_drag.x,0,clip_drag.y/r.Q)*r.U
		r.tube("bridge",from,to,4,Color("c49559"),.7)
		r.cylinder("bridge_grip",(from+to)/2+Vector3(0,.05,0),9,12,r.ORANGE)
	else:
		var at: Vector2 = v.CLIP_HOME+clip_drag
		r.line("loose_bridge",at-Vector2(25,0),at+Vector2(25,0),4,Color("c49559"),12)
		r.cylinder("loose_grip",r.visible_p(at,17),9,12,r.ORANGE)
	r.pad("bridge_recess",v.CLIP_HOME,Vector2(82,30),r.DARK,2)
	# A small removable tray shows its two perpendicular throats as real geometry.
	if v.model.level==0:
		var at: Vector2 = v.PLATE_HOME+(v.drag_delta if v.gesture=="plate" else Vector2.ZERO)
		r.pad("spare_tray",at,Vector2(98,68),r.TEAL,6)
		for line: Array in [[Vector2(-18,-27),Vector2(-18,13)],[Vector2(-18,25),Vector2(-18,27)],[Vector2(-18,0),Vector2(18,0)],[Vector2(31,0),Vector2(42,0)]]:
			r.line("spare_wall"+str(line),at+line[0],at+line[1],2.6,r.METAL,12)
		r.cylinder("spare_grip",r.visible_p(at+Vector2(-40,0),16),7,10,r.ORANGE)
	var fixture := Vector2(747,280)
	r.box("terminal_base",r.p(fixture,7),Vector3(68,14,64),r.TEAL)
	r.cylinder("terminal_socket",r.p(fixture,21),23,14,r.DARK)
	var bulb: MeshInstance3D = r.mesh("terminal_lens",r.bevel(Vector3(38,24,38)),r.p(fixture,37),Color("f1cc6b") if v.model.powered else Color("b8c2bf"),Basis.IDENTITY,0,v.model.powered)
	bulb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	# The test pulse follows the current circuit, not a completion animation toggle.
	if v.model.running or v.model.powered:
		var t: float = .5 if v.reduced_motion else fposmod(v.motion_time*.7,1)
		var route: Array[Vector2] = [pads[1],Vector2(646,pads[1].y),Vector2(646,274),Vector2(745,274)]
		var length := 0.0
		for i: int in 3: length += route[i].distance_to(route[i+1])
		var distance := t*length
		var at: Vector2 = route[0]
		for i: int in 3:
			var segment: float = route[i].distance_to(route[i+1])
			if distance <= segment:
				at = route[i].lerp(route[i+1],distance/maxf(segment,.001)); break
			distance -= segment
		r.cylinder("power_pulse",r.p(at,7),3,4,Color("f1cc6b"))
	if v.model.blocked:
		var at: Vector2 = v.model.collision_point
		r.cylinder("contact_stop",r.p(at,25),5,3,r.ORANGE)
