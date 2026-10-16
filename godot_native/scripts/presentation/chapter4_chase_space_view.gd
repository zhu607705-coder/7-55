extends Control
## Source actors in the approved independent chase-space whitebox.
const Metrics=preload("res://scripts/player_metrics.gd")
var geometry:RefCounted
var overview:=false
var reduced:=false
var camera:=Vector2.ZERO
var logical:=Vector2(960,600)
var field:=Rect2()
var factor:=1.0
var world_root:Node2D
var player_sprite:Sprite2D
var guard_sprite:Sprite2D
var frames:Dictionary={}
var guards:Dictionary={}
var side_idle:Texture2D
var previous_player:=Vector2.ZERO
var previous_guard:=Vector2.ZERO
var player_point:=Vector2.ZERO
var guard_point:=Vector2.ZERO
var player_facing:="up"
var guard_facing:="up"
var player_left:=false
var guard_left:=false
var direction:=Vector2.RIGHT
var previous_elapsed:=0.0
var initialized:=false
var guard_shown:=false

func _ready()->void:
	clip_contents=true;mouse_filter=Control.MOUSE_FILTER_IGNORE
	world_root=Node2D.new();add_child(world_root)
	for facing:String in ["up","down","side"]:
		frames[facing]=[]
		for i in 8:frames[facing].append(load("res://assets/rpg/player/player_%s_%d.png"%[facing,i]))
		guards[facing]=load("res://assets/rpg/npcs/finale/guard_walk%s_8frame.png"%("" if facing=="side" else "_"+facing))
	side_idle=load("res://assets/rpg/player/player_side_idle.png")
	player_sprite=Sprite2D.new();player_sprite.scale=Vector2.ONE*.65;world_root.add_child(player_sprite)
	guard_sprite=Sprite2D.new();guard_sprite.scale=Vector2.ONE*.68;guard_sprite.hframes=8;world_root.add_child(guard_sprite)
	resized.connect(_fit);_fit()

func reset_view(player:Vector2,guard:Vector2)->void:
	previous_player=player;previous_guard=guard;player_point=player;guard_point=guard
	direction=Vector2.RIGHT if player.y>1000 or player.y<500 else Vector2.LEFT
	camera=_clamp_camera(camera_focus(player,0 if reduced else 100));initialized=true;previous_elapsed=0
	_fit()

func _clamp_camera(point:Vector2)->Vector2:
	var half:=logical*.5
	return point.clamp(half,geometry.world.size-half)

func camera_focus(player:Vector2,ahead:float=100)->Vector2:
	# This presentation-only centerline is not a navigation path or a proof.
	# Small up/down obstacle dodges should not swing the camera into the void.
	var points:Array=geometry.layout.camera_route
	var segment:=0;var nearest:=Vector2.ZERO;var best:=INF
	for i in range(points.size()-1):
		var a:Vector2=geometry.vec(points[i]);var b:Vector2=geometry.vec(points[i+1])
		var edge:=b-a;var at:Vector2=a+edge*clampf((player-a).dot(edge)/edge.length_squared(),0,1)
		var distance:=player.distance_squared_to(at)
		if distance<best:best=distance;nearest=at;segment=i
	var remaining:=maxf(0,ahead)
	for i in range(segment,points.size()-1):
		var target:Vector2=geometry.vec(points[i+1]);var length:=nearest.distance_to(target)
		if remaining<=length:return nearest.move_toward(target,remaining)
		remaining-=length;nearest=target
	return nearest

func present(player:Vector2,guard:Vector2,elapsed:float,running:bool,_landing:int,visible_guard:Variant=null)->void:
	if not initialized:reset_view(player,guard)
	var movement:=player-previous_player;var guard_movement:=guard-previous_guard
	var moving:=running and movement.length_squared()>.0001
	if moving:
		direction=movement.normalized();player_facing="side" if absf(movement.x)>absf(movement.y) else ("up" if movement.y<0 else "down")
		if player_facing=="side":player_left=movement.x<0
	if running and guard_movement.length_squared()>.0001:
		guard_facing="side" if absf(guard_movement.x)>absf(guard_movement.y) else ("up" if guard_movement.y<0 else "down")
		if guard_facing=="side":guard_left=guard_movement.x<0
	if running and not overview:
		var goal:=_clamp_camera(camera_focus(player,0 if reduced else 100))
		camera=camera.lerp(goal,1.0 if reduced else 1-exp(-clampf((elapsed-previous_elapsed)/1000.0,0,.1)*4))
	player_sprite.texture=side_idle if player_facing=="side" and not moving else frames[player_facing][Metrics.frame_at(elapsed) if moving else 0]
	player_sprite.flip_h=player_facing=="side" and player_left;player_sprite.position=player-Metrics.FOOT_CENTER_OFFSET
	guard_sprite.texture=guards[guard_facing];guard_sprite.frame=int(floor(maxf(0,elapsed)*9/1000))%8 if running and guard_movement.length_squared()>.0001 else 0
	guard_sprite.flip_h=guard_facing=="side" and guard_left;guard_sprite.position=guard+Vector2(0,7-128*.68/2)
	guard_shown=bool(visible_guard);guard_sprite.visible=guard_shown
	player_sprite.z_index=int(player.y)+500;guard_sprite.z_index=int(guard.y)+500
	previous_player=player;previous_guard=guard;player_point=player;guard_point=guard;previous_elapsed=elapsed
	_fit();queue_redraw()

func _fit()->void:
	if geometry==null:return
	if overview:
		logical=geometry.world.size
	else:
		# Adapt the camera extent, never stretch the world or shrink a wide phone
		# into a fixed 16:10 island. Keep enough height for the full corridor.
		var previous_logical:=logical
		var aspect:=maxf(1,size.x)/maxf(1,size.y)
		var width:=600.0 if size.y>size.x else 960.0
		logical=Vector2(width,maxf(360,width/aspect))
		logical.x=logical.y*aspect
		# A rotation changes the visible extent immediately. Refit on the actor
		# at that boundary, otherwise a short landscape can start off-screen.
		camera=_clamp_camera(camera_focus(player_point,0 if reduced else 100) if initialized and not logical.is_equal_approx(previous_logical) else camera)
	factor=minf(size.x/logical.x,size.y/logical.y);field=Rect2((size-logical*factor)*.5,logical*factor)
	if is_instance_valid(world_root):
		world_root.scale=Vector2.ONE*factor
		world_root.position=field.position-(Vector2.ZERO if overview else camera-logical*.5)*factor
	queue_redraw()

func to_world(local:Vector2)->Vector2:
	if overview or factor<=0 or not field.has_point(local):return Vector2.INF
	return (local-field.position)/factor+camera-logical*.5

func _arrow(at:Vector2,heading:Vector2,color:Color)->void:
	var side:=heading.orthogonal()
	draw_line(at-heading*25,at+heading*25,color,4)
	draw_polyline(PackedVector2Array([at+heading*8+side*14,at+heading*25,at+heading*8-side*14]),color,4)

func _draw()->void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("11181b"))
	if geometry==null or factor<=0:return
	var origin:Vector2=field.position-(Vector2.ZERO if overview else camera-logical*.5)*factor
	draw_set_transform(origin,0,Vector2.ONE*factor)
	for floor_rect:Rect2 in geometry.floors:
		draw_rect(floor_rect,Color("646e70"))
		if not overview:
			for x in range(int(floor_rect.position.x)+60,int(floor_rect.end.x),120):draw_line(Vector2(x,floor_rect.position.y+6),Vector2(x,floor_rect.end.y-6),Color("737d7b"),1)
	# Draw the actual solid complement, rather than outlining overlapping floor
	# rectangles: those outlines looked like walls across the open stair turns.
	for wall:Rect2 in geometry.walls:
		if wall in geometry.obstacles:continue
		draw_rect(wall,Color("303c40"));draw_rect(wall,Color("b3b2a4"),false,5)
		if wall.size.y>48:draw_line(wall.position+Vector2(8,18),Vector2(wall.end.x-8,wall.position.y+18),Color("526062"),4)
	# Stair risers live only in the two authored connecting passages.
	for connector in [Rect2(2700,920,240,280),Rect2(60,400,240,280)]:
		for y in range(int(connector.position.y),int(connector.end.y),20):draw_line(Vector2(connector.position.x+8,y),Vector2(connector.end.x-8,y),Color("aab3a5"),3)
	for i in geometry.obstacles.size():
		var obstacle:Rect2=geometry.obstacles[i]
		draw_rect(obstacle,Color("726456"));draw_rect(obstacle,Color("e5bd75"),false,5)
		if geometry.layout.obstacles[i].type=="storage":
			draw_line(obstacle.position+Vector2(10,10),obstacle.end-Vector2(10,10),Color("bea689"),4)
			draw_line(Vector2(obstacle.end.x-10,obstacle.position.y+10),Vector2(obstacle.position.x+10,obstacle.end.y-10),Color("bea689"),4)
		else:
			for y in range(int(obstacle.position.y)+18,int(obstacle.end.y),24):draw_line(Vector2(obstacle.position.x+8,y),Vector2(obstacle.end.x-8,y),Color("dab66b"),7)
	for y in [1320,800,280]:
		for x in [390,1210,1920,2600]:_arrow(Vector2(x,y),Vector2.LEFT if y==800 else Vector2.RIGHT,Color("ded394"))
	for at in [Vector2(2820,1080),Vector2(180,550)]:_arrow(at,Vector2.UP,Color("eee5b2"))
	_arrow(Vector2(2820,800),Vector2.LEFT,Color("eee5b2"));_arrow(Vector2(180,280),Vector2.RIGHT,Color("eee5b2"))
	for gate:Rect2 in geometry.gates:draw_rect(gate,Color("b6d0b030"));draw_rect(gate,Color("b6d0b0"),false,3)
	draw_rect(geometry.exit,Color("79b9c630"));draw_rect(geometry.exit,Color("b1e1dd"),false,4)
	draw_set_transform(Vector2.ZERO)
	# A bounded edge marker points at the real off-camera guard. It never fakes
	# a chase distance or writes progress, and disappears while the guard is seen.
	if guard_shown and not overview:
		var screen_guard:Vector2=origin+guard_point*factor
		if not field.grow(-22).has_point(screen_guard):
			var point:=screen_guard.clamp(field.position+Vector2.ONE*24,field.end-Vector2.ONE*24)
			var heading:Vector2=(screen_guard-field.get_center()).normalized()
			draw_circle(point,17,Color("b75648"));_arrow(point,heading,Color("fff0c7"))
			draw_string(get_theme_font("font"),point+Vector2(-18,-28),"保安",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("fff0c7"))
