extends Node2D
## Original surreal light-creature, marks, eyes and exit. Everything here lives
## inside the same stage viewport as geometry, so lighting and targets agree.
var game:Control
func ellipse(center:Vector2,extent:Vector2,color:Color)->void:
	var points:=PackedVector2Array()
	for i in 40:points.append(center+Vector2(cos(i*TAU/40),sin(i*TAU/40))*extent*.5)
	draw_colored_polygon(points,color)
func eye(point:Vector2,width:float,head:Vector2,awake:bool=true)->void:
	ellipse(point,Vector2(width*2,width),Color("ffedc9") if awake else Color("524858"))
	var offset:Vector2=((head-point)/110).clamp(Vector2(-width*.24,-width*.13),Vector2(width*.24,width*.13))
	draw_circle(point+offset,width*.27,Color("171936"));draw_rect(Rect2(point+offset-Vector2.ONE,Vector2(2,2)),Color("e85881"))
func _draw()->void:
	if not is_instance_valid(game) or game.state.is_empty():return
	var s:Dictionary=game.state;var color:Color=game.COLORS[s.round];var cream:Color=game.CREAM
	var act:Dictionary=game.Model.ACTS[s.round]
	# Audience is a sparse near-black silhouette, not another gameplay boundary.
	for i in 16:
		var p:=Vector2(32+i*60,449+sin(i*2)*6)
		ellipse(p+Vector2(0,10),Vector2(44,34),Color("17121e"));eye(p,10,s.head,s.round==2)
	var mouth:Vector2=game.rules.mouth(s);var open:bool=s.collected.size()==act.count
	ellipse(mouth+Vector2(0,16),Vector2(98,32),Color(0.02,.02,.04,.55))
	ellipse(mouth,Vector2(108,95 if open else 47),Color("602e43"));ellipse(mouth,Vector2(94,80 if open else 31),Color("c97086"));ellipse(mouth,Vector2(75,62 if open else 12),Color("120f1f"))
	for i in 5:
		draw_rect(Rect2(mouth.x-31+i*13,mouth.y-(29 if open else 4),9,11 if open else 5),cream)
		if open:draw_rect(Rect2(mouth.x-31+i*13,mouth.y+19,9,10),cream)
	var actor_color:Color=Color("ffd76f") if s.round==2 else color
	var echo_state:Dictionary=game.rules.echo(s)
	var active:Array=game.rules.active_food(s)
	if game.screen=="running":
		for id in int(act.count):
			if s.collected.has(id):continue
			var p:Vector2=game.rules.food(s,id);var enabled:bool=active.has(id) or s.primed==id
			var tint:Color=color
			if s.round>0:
				var groups:Array=game.rules.pairs(s)
				for index in groups.size():
					if groups[index].has(id):tint=game.COLORS[index]
			var own_reach:bool=s.head.distance_to(p)<game.rules.light_radius(s)
			var own_lit:bool=enabled and own_reach and not game.rules.food_blocked(s,id)
			var echo_reach:bool=not echo_state.is_empty() and echo_state.position.distance_to(p)<game.rules.light_radius(s)
			var echo_lit:bool=enabled and echo_reach and not game.rules.food_blocked(s,id,echo_state.position)
			var blocked:bool=enabled and (own_reach or echo_reach) and not own_lit and not echo_lit
			var amount:float=float(s.focus[id])/game.rules.focus_ticks(s)
			if own_lit:draw_line(s.head,p,Color(actor_color,.38),2)
			if echo_lit:draw_line(echo_state.position,p,Color("78eeed"),2)
			ellipse(p+Vector2(0,10),Vector2(36,12),Color(.08,.035,.06,.55))
			if s.round<2:
				for future_tick in [5,10,15]:
					var future:Dictionary=s.duplicate(false);future.tick=s.tick+future_tick
					draw_circle(game.rules.food(future,id),1.4,Color(tint,.20))
			draw_arc(p,23,0,TAU,36,Color(tint,.8 if enabled else .18),2)
			if amount>0:draw_arc(p,25,-PI*.5,-PI*.5+TAU*amount,36,cream,3)
			if s.primed==id:draw_circle(p,29,Color(tint,.13))
			if blocked:
				draw_line(p+Vector2(-10,-10),p+Vector2(10,10),Color("b77a86"),2)
				draw_line(p+Vector2(10,-10),p+Vector2(-10,10),Color("b77a86"),2)
			else:draw_string(game.font,p+Vector2(-18,10),act.glyph,HORIZONTAL_ALIGNMENT_CENTER,36,36,cream if enabled else Color("90716c"))
	if not echo_state.is_empty():
		var ghost:Vector2=echo_state.position
		var past:=PackedVector2Array(s.history.slice(maxi(0,s.history.size()-85),s.history.size()-60))
		if past.size()>1:draw_polyline(past,Color(.35,.9,.95,.20),7)
		ellipse(ghost+Vector2(0,8),Vector2(48,22),Color(.3,.9,.95,.12))
		draw_circle(ghost,13,Color(.38,.92,.95,.65))
		draw_rect(Rect2(ghost-Vector2(15,19),Vector2(30,5)),Color("477d96"));draw_rect(Rect2(ghost-Vector2(8,32),Vector2(16,15)),Color("477d96"))
		draw_circle(ghost+Vector2(-4,-2),2,Color("d9ffff"));draw_circle(ghost+Vector2(4,-2),2,Color("d9ffff"))
		draw_string(game.font,ghost+Vector2(-43,-40),"3秒前的光",HORIZONTAL_ALIGNMENT_CENTER,86,13,Color("a9f5ed"))
	for hazard:Dictionary in game.rules.hazards(s):
		var p:Vector2=hazard.position
		if hazard.kind=="shadow":
			ellipse(p,Vector2(49,39),Color(.024,.031,.059,.86));draw_colored_polygon(PackedVector2Array([p+Vector2(-24,0),p+Vector2(24,0),p+Vector2(0,31)]),Color(.024,.031,.059,.86));eye(p-Vector2(0,3),13,s.head)
		elif hazard.kind=="eye":draw_arc(p,25,0,TAU,40,Color(1,.58,.74,.7),2);eye(p,25,s.head)
	if s.trail.size()>1:
		var points:=PackedVector2Array(s.trail)
		draw_polyline(points,Color(actor_color,.10),29 if s.dashTicks>0 else 20,false);draw_polyline(points,Color(actor_color,.67),9,false);draw_polyline(points,Color(cream,.94),3,false)
	ellipse(s.head+Vector2(0,8),Vector2(40,17),Color(actor_color,.20))
	draw_circle(s.head,13,Color.WHITE if s.invulnerable>0 and s.tick%4<2 else actor_color)
	draw_rect(Rect2(s.head-Vector2(15,19),Vector2(30,5)),Color("11152d"));draw_rect(Rect2(s.head-Vector2(8,32),Vector2(16,15)),Color("11152d"));draw_rect(Rect2(s.head-Vector2(8,30),Vector2(16,3)),cream)
	for x in [-6,3]:draw_rect(Rect2(s.head+Vector2(x,-3),Vector2(3,5)),Color("11152d"))
	draw_line(s.head+Vector2(-3,6),s.head+Vector2(4,6),Color("11152d"),2)
