extends RefCounted
## Shared geometry and ground-depth rules. Never reads or writes story state.
const PlayerBodyMetrics=preload("res://scripts/player_metrics.gd")
const Picker=preload("res://scripts/world_object_picker.gd")
const CONTACT_EPSILON:=.001

static func foot_y(anchor:Vector2)->float:return PlayerBodyMetrics.foot_rect(anchor).end.y
static func depth_in_front(baseline:float,ground_y:float)->bool:return ground_y<=baseline+.01
static func in_front(baseline:float,anchor:Vector2)->bool:return depth_in_front(baseline,foot_y(anchor))
static func legacy_baseline(depth:float,player_depth_offset:float)->float:
	return depth-player_depth_offset+foot_y(Vector2.ZERO)
static func record_baseline(cover:Dictionary)->float:
	return float(cover.get("baselineY",cover.get("sortY",cover.get("bottom",0))))
static func npc_cover_alpha(cover:Dictionary,ground_y:float,player:Vector2,player_ground_y:=INF)->float:
	var baseline:=record_baseline(cover)
	if not depth_in_front(baseline,ground_y):return 0.0
	var reveal:=float(cover.get("playerRevealAlpha",0))
	var player_depth:float=player_ground_y if is_finite(player_ground_y) else foot_y(player)
	if reveal>0 and ground_y<=player_depth and depth_in_front(baseline,player_depth):return 0.0
	return 1.0-reveal
static func draw_actor_covers(canvas:CanvasItem,context:Dictionary,ground_y:float,actor_bounds:Rect2)->void:
	var plate:Texture2D=context.get("background")
	if plate==null:return
	for cover:Dictionary in context.get("actor_occluders",[]):
		var bounds:=rect(cover.get("maskBounds",cover))
		var alpha:=npc_cover_alpha(cover,ground_y,Vector2(context.get("player",Vector2.ZERO)),float(context.get("player_ground_y",INF)))
		if context.get("actor_after_foreground",false):alpha=1.0-float(cover.get("playerRevealAlpha",0)) if depth_in_front(record_baseline(cover),ground_y) else 0.0
		if not actor_bounds.intersects(bounds) or alpha<=0:continue
		Picker.record(canvas,[],{"polygon":cover.polygon} if cover.has("polygon") else bounds)
		var tint:=Color.WHITE.lerp(Color(.03,.15,.26),float(context.get("mode_mix",0))*.3);tint.a=alpha
		canvas.draw_set_transform(Vector2(context.origin),0,Vector2.ONE*float(context.zoom))
		if cover.has("polygon"):
			var uv:=PackedVector2Array()
			for point:Vector2 in cover.polygon:uv.append(point/plate.get_size())
			canvas.draw_polygon(cover.polygon,PackedColorArray([tint]),uv,plate)
		else:canvas.draw_texture_rect_region(plate,bounds,bounds,tint)
		canvas.draw_set_transform(Vector2.ZERO)
static func rect(value:Variant)->Rect2:
	if value is Rect2:return value
	if value is Array:return Rect2(float(value[0]),float(value[1]),float(value[2]),float(value[3]))
	var x:=float(value.get("x",value.get("left",0)));var y:=float(value.get("y",value.get("top",0)))
	return Rect2(x,y,float(value.get("width",float(value.get("right",x))-x)),float(value.get("height",float(value.get("bottom",y))-y)))
static func subtract(area:Rect2,cut:Rect2)->Array[Rect2]:
	var hit:=area.intersection(cut)
	if not hit.has_area():return [area]
	var out:Array[Rect2]=[]
	if area.position.y<hit.position.y:out.append(Rect2(area.position.x,area.position.y,area.size.x,hit.position.y-area.position.y))
	if hit.end.y<area.end.y:out.append(Rect2(area.position.x,hit.end.y,area.size.x,area.end.y-hit.end.y))
	if area.position.x<hit.position.x:out.append(Rect2(area.position.x,hit.position.y,hit.position.x-area.position.x,hit.size.y))
	if hit.end.x<area.end.x:out.append(Rect2(hit.end.x,hit.position.y,area.end.x-hit.end.x,hit.size.y))
	return out
static func covered_by_rects(body:Rect2,regions:Array)->bool:
	var remaining:Array[Rect2]=[body]
	for region:Rect2 in regions:
		var next:Array[Rect2]=[]
		for piece:Rect2 in remaining:next.append_array(subtract(piece,region))
		remaining=next
		if remaining.is_empty():return true
	return false
static func mask_allows_rect(body:Rect2,bits:PackedByteArray,definition:Dictionary)->bool:
	var cell:=float(definition.get("cellSize",0));var width:=int(definition.get("gridWidth",0));var height:=int(definition.get("gridHeight",0))
	if cell<=0 or width<=0 or height<=0 or bits.size()*8<width*height:return false
	if body.position.x<0 or body.position.y<0 or body.end.x>width*cell or body.end.y>height*cell:return false
	var first:=Vector2i(floori(body.position.x/cell),floori(body.position.y/cell))
	var last:=Vector2i(floori((body.end.x-CONTACT_EPSILON)/cell),floori((body.end.y-CONTACT_EPSILON)/cell))
	for y in range(first.y,last.y+1):
		for x in range(first.x,last.x+1):
			var index:=y*width+x
			if (bits[index/8] & (1 << (index%8)))==0:return false
	return true
static func sweep_axis(start:Vector2,motion:Vector2,allowed:Callable,max_step:float=4.0)->Vector2:
	if not start.is_finite() or not motion.is_finite() or motion.is_zero_approx():return start
	if not is_zero_approx(motion.x) and not is_zero_approx(motion.y):return start
	var end:=start+motion
	if not allowed.call(start):return end if allowed.call(end) else start
	var current:=start
	var steps:=maxi(1,ceili(motion.length()/max_step))
	for index:int in steps:
		var next:=start+motion*(float(index+1)/steps)
		if allowed.call(next):current=next;continue
		var blocked:=next
		for iteration:int in 12:
			var middle:=(current+blocked)*.5
			if allowed.call(middle):current=middle
			else:blocked=middle
		return current
	return current
static func polygon(value:Array)->PackedVector2Array:
	var result:=PackedVector2Array()
	for point:Variant in value:
		result.append(Vector2(point[0],point[1]) if point is Array else Vector2(point.x,point.y))
	return result
static func circle_hits_polygon(center:Vector2,radius:float,points:PackedVector2Array)->bool:
	if points.size()<3:return false
	if Geometry2D.is_point_in_polygon(center,points):return true
	for index in points.size():
		if center.distance_to(Geometry2D.get_closest_point_to_segment(center,points[index],points[(index+1)%points.size()]))<radius-CONTACT_EPSILON:return true
	return false
