extends Control
## Read-only source-art view. The activity remains the only movement/proof owner.
const Metrics=preload("res://scripts/player_metrics.gd")
const WORLD_SIZE=Vector2(1672,941)
const SOURCE_VIEW=Vector2(960,540)
var overview:=false
var camera:=Vector2.ZERO
var initialized:=false
var world_root:Node2D
var plate_sprite:Sprite2D
var player_sprite:Sprite2D
var guard_sprite:Sprite2D
var exit_label:Label
var frames:Dictionary={}
var guards:Dictionary={}
var side_idle:Texture2D
var previous_player:=Vector2.ZERO
var previous_guard:=Vector2.ZERO
var player_facing:="up"
var guard_facing:="up"
var player_left:=false
var guard_left:=false
var moving:=false
var field:=Rect2()
var factor:=1.0

func _ready():
	clip_contents=true;mouse_filter=Control.MOUSE_FILTER_IGNORE
	world_root=Node2D.new();add_child(world_root)
	plate_sprite=Sprite2D.new();plate_sprite.centered=false;plate_sprite.texture=load("res://assets/rpg/interiors/finale/finale_stairwell.png");world_root.add_child(plate_sprite)
	for facing:String in ["up","down","side"]:
		frames[facing]=[]
		for i in 8:frames[facing].append(load("res://assets/rpg/player/player_%s_%d.png"%[facing,i]))
		var suffix:="" if facing=="side" else "_"+facing
		guards[facing]=load("res://assets/rpg/npcs/finale/guard_walk%s_8frame.png"%suffix)
	side_idle=load("res://assets/rpg/player/player_side_idle.png")
	player_sprite=Sprite2D.new();player_sprite.scale=Vector2.ONE*.65;world_root.add_child(player_sprite)
	guard_sprite=Sprite2D.new();guard_sprite.hframes=8;guard_sprite.scale=Vector2.ONE*.68;world_root.add_child(guard_sprite)
	exit_label=Label.new();exit_label.text="二楼走廊";exit_label.position=Vector2(788,78);exit_label.add_theme_font_size_override("font_size",16);exit_label.mouse_filter=Control.MOUSE_FILTER_IGNORE;world_root.add_child(exit_label)
	resized.connect(_fit)
	_fit()

func reset_view(player:Vector2,guard:Vector2):
	previous_player=player;previous_guard=guard;player_facing="up";guard_facing="up";player_left=false;guard_left=false;moving=false
	camera=_clamp_camera(player-Metrics.FOOT_CENTER_OFFSET);initialized=true
	_fit()

func _clamp_camera(point:Vector2)->Vector2:
	# Original camera-only headroom is -190; collision coordinates never change.
	return Vector2(clampf(point.x,480,1192),clampf(point.y,80,671))

func present(player:Vector2,guard:Vector2,elapsed:float,running:bool,landing:int,guard_visible:Variant=null):
	if not is_instance_valid(world_root):return
	if not initialized:reset_view(player,guard)
	var delta_player:=player-previous_player;var delta_guard:=guard-previous_guard
	moving=running and delta_player.length_squared()>.0001
	if moving:
		player_facing="side" if absf(delta_player.x)>absf(delta_player.y) else "up" if delta_player.y<0 else "down"
		if player_facing=="side":player_left=delta_player.x<0
	if running and delta_guard.length_squared()>.0001:
		guard_facing="side" if absf(delta_guard.x)>absf(delta_guard.y) else "up" if delta_guard.y<0 else "down"
		if guard_facing=="side":guard_left=delta_guard.x<0
	if running and not overview:
		var target:=player-Metrics.FOOT_CENTER_OFFSET;var requested:=camera
		if absf(target.x-camera.x)>75:requested.x=target.x-signf(target.x-camera.x)*75
		if absf(target.y-camera.y)>40:requested.y=target.y-signf(target.y-camera.y)*40
		camera=_clamp_camera(camera.lerp(requested,.18))
	player_sprite.texture=side_idle if player_facing=="side" and not moving else frames[player_facing][Metrics.frame_at(elapsed) if moving else 0]
	player_sprite.flip_h=player_facing=="side" and player_left
	player_sprite.position=player-Metrics.FOOT_CENTER_OFFSET
	# finale_npc_manifest declares 9fps for these three original guard sheets.
	guard_sprite.texture=guards[guard_facing];guard_sprite.frame=int(floor(maxf(0,elapsed)*9.0/1000.0))%8;guard_sprite.flip_h=guard_facing=="side" and guard_left
	guard_sprite.position=guard+Vector2(0,7-128*.68/2);guard_sprite.visible=elapsed>2000 if guard_visible==null else bool(guard_visible)
	player_sprite.z_index=int(player.y)+500;guard_sprite.z_index=int(guard.y)+502
	exit_label.visible=not overview and landing==2 and player.distance_to(Vector2(715,80))<175
	exit_label.z_index=2000
	previous_player=player;previous_guard=guard
	_fit();queue_redraw()

func _fit():
	var logical:=WORLD_SIZE if overview else SOURCE_VIEW
	factor=minf(size.x/logical.x,size.y/logical.y)
	field=Rect2((size-logical*factor)/2,logical*factor)
	if is_instance_valid(world_root):
		world_root.scale=Vector2.ONE*factor
		world_root.position=field.position-(Vector2.ZERO if overview else camera-SOURCE_VIEW/2)*factor

func to_world(local:Vector2)->Vector2:
	if overview or factor<=0 or not field.has_point(local):return Vector2.INF
	return (local-field.position)/factor+camera-SOURCE_VIEW/2

func _draw():
	draw_rect(Rect2(Vector2.ZERO,size),Color("080e13"))
	if overview and initialized:
		var bounds:=Rect2((camera-SOURCE_VIEW/2)*factor+field.position,SOURCE_VIEW*factor).intersection(field)
		draw_rect(bounds,Color("e8dbac"),false,1)
