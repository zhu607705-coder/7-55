extends RefCounted
## Presentation clock, independent of story time and saves. The source plan is
## north-up: east is +X, south is +Y. Sunlight only enters a facing window.
var hour:=12.0
var sun:=Vector2.DOWN
var elevation:=1.0
var daylight:=1.0
var ambient:=Color.WHITE
var sunlit:Dictionary={}

func set_hour(value:float)->void:
	hour=fposmod(value,24.0)
	var phase:=clampf((hour-6.0)/12.0,0.0,1.0)
	daylight=sin(phase*PI) if hour>6.0 and hour<18.0 else 0.0
	elevation=maxf(.15,daylight)
	sun=Vector2(cos(phase*PI),sin(phase*PI)).normalized()
	var night:=Color(.48,.52,.64)
	var day:=Color(.97,.98,1.0)
	ambient=night.lerp(day,smoothstep(0.0,.45,daylight))
	if daylight>0.0:
		ambient=ambient.lerp(Color(1.0,.84,.70),pow(1.0-daylight,3.0)*.16)

func incidence(normal:Vector2)->float:
	return maxf(0.0,sun.dot(normal))*daylight

func cast_vector(height:float)->Vector2:
	return -sun*height*(1.8-elevation*1.3)

func sun_color(strength:float)->Color:
	return Color(1.0,lerpf(.70,.94,daylight),lerpf(.42,.82,daylight),strength*.25)

func draw_room(canvas:CanvasItem,definition:Dictionary,view:Rect2)->void:
	sunlit.clear()
	for window:Dictionary in definition.get("windows",[]):
		var strength:=incidence(Vector2(window.normal[0],window.normal[1]))
		if strength<.015:continue
		var a:=Vector2(window.a[0],window.a[1]);var b:=Vector2(window.b[0],window.b[1])
		var ray:=cast_vector(float(window.get("height",360)))
		var beam:=PackedVector2Array([a,b,b+ray,a+ray])
		var bounds:=Rect2(a,Vector2.ZERO).expand(b).expand(a+ray).expand(b+ray)
		if not bounds.intersects(view):continue
		var clip:=PackedVector2Array()
		for p:Array in window.floor:clip.append(Vector2(p[0],p[1]))
		# Each pane has its own beam; clipping prevents light through walls/voids.
		for polygon:PackedVector2Array in Geometry2D.intersect_polygons(beam,clip):
			if polygon.size()>2:
				canvas.draw_colored_polygon(polygon,sun_color(strength))
				if not sunlit.has(window.room):sunlit[window.room]=[]
				sunlit[window.room].append(polygon)
	if daylight<.2:
		for room:Dictionary in definition.rooms:
			var bounds:=Rect2(room.bounds[0],room.bounds[1],room.bounds[2],room.bounds[3])
			if not bounds.intersects(view):continue
			for region:Dictionary in definition.ground:
				if not str(region.id).begins_with(str(room.id)+"_floor_"):continue
				var polygon:=PackedVector2Array()
				for p:Array in region.polygon:polygon.append(Vector2(p[0],p[1]))
				canvas.draw_colored_polygon(polygon,Color(1.0,.84,.61,.12*(1.0-daylight/.2)))
				var center:=bounds.get_center()
				for ring:int in range(5,0,-1):
					var pool:=PackedVector2Array()
					for i:int in 32:pool.append(center+Vector2(cos(TAU*i/32),sin(TAU*i/32))*(120+ring*65))
					for lit:PackedVector2Array in Geometry2D.intersect_polygons(pool,polygon):
						if lit.size()>2:canvas.draw_colored_polygon(lit,Color(1.0,.80,.48,.035))

func draw_shadow(canvas:CanvasItem,object:Dictionary)->void:
	if daylight<=0.0 or object.get("mounted",false) or not sunlit.has(object.room):return
	var box:=Rect2(object.footprint[0],object.footprint[1],object.footprint[2],object.footprint[3])
	var shift:=cast_vector(float(object.get("height",65)))
	var points:=PackedVector2Array([box.position,Vector2(box.end.x,box.position.y),box.end,Vector2(box.position.x,box.end.y)])
	for p:Vector2 in points.duplicate():points.append(p+shift)
	var hull:=Geometry2D.convex_hull(points)
	var floor:=PackedVector2Array()
	for p:Array in object.get("floor",[]):floor.append(Vector2(p[0],p[1]))
	if floor.size()>2:
		for polygon:PackedVector2Array in Geometry2D.intersect_polygons(hull,floor):
			if polygon.size()>2:
				for lit:PackedVector2Array in sunlit[object.room]:
					for shadow:PackedVector2Array in Geometry2D.intersect_polygons(polygon,lit):
						if shadow.size()>2:canvas.draw_colored_polygon(shadow,Color(.1,.15,.24,.25*daylight))

func draw_contact(canvas:CanvasItem,object:Dictionary)->void:
	# Contact remains visible in diffuse daylight and indoor lighting. It belongs
	# to the prop's ground footprint, not to the painted floor material.
	if object.get("mounted",false):return
	var box:=Rect2(object.footprint[0],object.footprint[1],object.footprint[2],object.footprint[3])
	var floor:=PackedVector2Array()
	for p:Array in object.get("floor",[]):floor.append(Vector2(p[0],p[1]))
	if floor.size()<3:return
	for layer:int in [0,1]:
		var oval:=PackedVector2Array()
		var radius:=box.size*Vector2(.52,.50)+Vector2.ONE*(3 if layer==0 else 0)
		for i:int in 16:oval.append(box.get_center()+Vector2(cos(TAU*i/16),sin(TAU*i/16))*radius)
		for polygon:PackedVector2Array in Geometry2D.intersect_polygons(oval,floor):
			if polygon.size()>2:canvas.draw_colored_polygon(polygon,Color(.12,.16,.19,.06 if layer==0 else .10))
