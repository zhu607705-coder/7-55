extends Node2D
const Body=preload("res://scripts/player_metrics.gd")
const Space=preload("res://scripts/space/spatial_rules.gd")
const FloorSpace=preload("res://campuses/future_learning_center/scripts/floor_space.gd")
const RoomCamera=preload("res://campuses/future_learning_center/scripts/room_camera.gd")
var data:Dictionary
var space=FloorSpace.new()
var framing=RoomCamera.new()
var camera:=Camera2D.new()
var textures:Dictionary={}
var player:=Vector2.ZERO
var route:=PackedVector2Array()
var facing:="down"
var elapsed:=0.0
var walking:=false
var overview:=false
var geometry_visible:=false
var capture_only:=false
var user_control:=true
var touch_vector:=Vector2.ZERO
var touched_buttons:Dictionary={}
var title_label:Label
var place_label:Label
var ui:CanvasLayer
var invalid_frames:=0
var visible_modules:=0
var floor_tile:Texture2D

func _ready()->void:
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	data=JSON.parse_string(FileAccess.get_file_as_string("res://campuses/future_learning_center/data/floor_3.json"))
	space.configure(data)
	for item:Dictionary in data.modules:_texture(item.path)
	floor_tile=ImageTexture.create_from_image(textures["res://campuses/future_learning_center/assets/rooms/pantry.png"].get_image().get_region(Rect2i(1020,450,120,120)))
	texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
	for direction:String in ["down","up","side"]:
		for i:int in 8:_texture("res://assets/rpg/player/player_%s_%d.png"%[direction,i])
	player=Vector2(data.spawn[0],data.spawn[1])-Body.FOOT_CENTER_OFFSET
	add_child(camera);camera.enabled=true;camera.position_smoothing_enabled=false
	framing.update(0,player,space,true);_apply_camera();_build_ui()
	queue_redraw()

func _texture(path:String)->Texture2D:
	if not textures.has(path):
		# Review can consume a fresh raw generated asset before an editor import.
		var source:=Image.load_from_file(ProjectSettings.globalize_path(path))
		if source==null or source.is_empty():push_error("FLC image missing: "+path);return null
		textures[path]=ImageTexture.create_from_image(source)
	return textures[path]

func _process(dt:float)->void:
	elapsed+=dt
	if capture_only:return
	var direction:=Vector2.ZERO
	if user_control and not overview:
		direction=Vector2(int(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT))-int(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)),int(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN))-int(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)))+touch_vector
		if direction.length_squared()>0:route.clear();direction=direction.normalized()
		elif not route.is_empty():
			while not route.is_empty() and player.distance_to(route[0])<4:route.remove_at(0)
			if not route.is_empty():direction=(route[0]-player).normalized()
	var motion:=direction*250.0*minf(dt,.1)
	if not route.is_empty() and motion.length()>player.distance_to(route[0]):motion=route[0]-player
	var before:=player
	player=space.move(player,motion)
	walking=before.distance_to(player)>.01
	if walking:
		if absf(direction.x)>absf(direction.y):facing="side" if direction.x>0 else "left"
		else:facing="down" if direction.y>0 else "up"
	elif motion.length()>0:route.clear()
	if not space.can_stand(player):invalid_frames+=1
	framing.update(dt,player,space,false,overview);_apply_camera()
	if is_instance_valid(place_label):
		var room:Dictionary=space.room_at(player+Body.FOOT_CENTER_OFFSET)
		place_label.text="3F 全层总览" if overview else str(room.get("name","环廊"))
	queue_redraw()

func _apply_camera()->void:
	camera.position=framing.center;camera.zoom=Vector2.ONE*framing.zoom;camera.force_update_scroll()

func set_foot(point:Vector2,snap:=true)->bool:
	var candidate:=point-Body.FOOT_CENTER_OFFSET
	if not space.can_stand(candidate):return false
	player=candidate;route.clear();framing.update(0,player,space,snap,overview);_apply_camera();queue_redraw();return true

func _unhandled_input(event:InputEvent)->void:
	if not user_control:return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_TAB:toggle_overview();get_viewport().set_input_as_handled()
		elif event.keycode==KEY_F2:geometry_visible=not geometry_visible
	elif event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		request_walk(screen_to_world(event.position));get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch and event.pressed:
		request_walk(screen_to_world(event.position));get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.keycode==KEY_ESCAPE and event.pressed:
		route.clear()

func screen_to_world(screen:Vector2)->Vector2:return framing.center+(screen-RoomCamera.VIEW/2)/framing.zoom
func world_to_screen(point:Vector2)->Vector2:return (point-framing.center)*framing.zoom+RoomCamera.VIEW/2
func request_walk(foot:Vector2)->void:
	if overview:return
	route=space.route(player,foot-Body.FOOT_CENTER_OFFSET)
func toggle_overview()->void:
	overview=not overview;route.clear();touch_vector=Vector2.ZERO

func _notification(what:int)->void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT:route.clear();touch_vector=Vector2.ZERO;touched_buttons.clear()

func _build_ui()->void:
	ui=CanvasLayer.new();add_child(ui)
	var panel:=Control.new();panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);panel.mouse_filter=Control.MOUSE_FILTER_IGNORE;ui.add_child(panel)
	var font:Font=load("res://scripts/ui/native_typography.gd").body_font()
	var shade:=ColorRect.new();shade.color=Color(.035,.055,.085,.9);shade.position=Vector2(0,0);shade.size=Vector2(960,40);shade.mouse_filter=Control.MOUSE_FILTER_IGNORE;panel.add_child(shade)
	title_label=Label.new();title_label.text="未来学习中心  /  3F";title_label.position=Vector2(18,8);title_label.add_theme_font_override("font",font);title_label.add_theme_font_size_override("font_size",17);panel.add_child(title_label)
	var button:=Button.new();button.text="楼层总图 · Tab";button.position=Vector2(790,5);button.size=Vector2(155,30);button.add_theme_font_override("font",font);button.add_theme_font_size_override("font_size",14);button.pressed.connect(toggle_overview);panel.add_child(button)
	var footer:=ColorRect.new();footer.color=Color(.035,.055,.085,.86);footer.position=Vector2(0,509);footer.size=Vector2(960,31);footer.mouse_filter=Control.MOUSE_FILTER_IGNORE;panel.add_child(footer)
	place_label=Label.new();place_label.position=Vector2(18,513);place_label.add_theme_font_override("font",font);place_label.add_theme_font_size_override("font_size",14);panel.add_child(place_label)
	var hint:=Label.new();hint.text="WASD / 方向键行走  ·  点击地面前往";hint.position=Vector2(602,513);hint.add_theme_font_override("font",font);hint.add_theme_font_size_override("font_size",13);panel.add_child(hint)
	if OS.has_feature("mobile") or OS.get_environment("FLC_TOUCH")=="1":
		hint.text="轻触地面前往  ·  左下方向键移动"
		for entry:Array in [["↑",Vector2(76,374),Vector2.UP],["↓",Vector2(76,450),Vector2.DOWN],["←",Vector2(38,412),Vector2.LEFT],["→",Vector2(114,412),Vector2.RIGHT]]:
			var control:=Button.new();control.text=entry[0];control.position=entry[1];control.size=Vector2(38,38);control.add_theme_font_size_override("font_size",22);panel.add_child(control)
			control.button_down.connect(func()->void:touched_buttons[entry[0]]=entry[2];_touch_changed())
			control.button_up.connect(func()->void:touched_buttons.erase(entry[0]);_touch_changed())

func _touch_changed()->void:
	touch_vector=Vector2.ZERO
	for vector:Vector2 in touched_buttons.values():touch_vector+=vector
	touch_vector=touch_vector.limit_length()

func _region(texture:Texture2D,source:Rect2,at:Vector2,scale_value:float)->void:
	draw_texture_rect_region(texture,Rect2(at,source.size*scale_value),source)

func _tile(texture:Texture2D,source:Rect2,area:Rect2,scale_value:=1.0)->void:
	var tile_size:=source.size*scale_value
	var visible:Rect2=area.intersection(framing.visible_rect().grow(20)) if not capture_only else area
	if not visible.has_area():return
	var start:=Vector2(floorf((visible.position.x-area.position.x)/tile_size.x),floorf((visible.position.y-area.position.y)/tile_size.y))
	var end:=Vector2(ceilf((visible.end.x-area.position.x)/tile_size.x),ceilf((visible.end.y-area.position.y)/tile_size.y))
	for y:int in range(int(start.y),int(end.y)):
		for x:int in range(int(start.x),int(end.x)):
			var box:=Rect2(area.position+Vector2(x,y)*tile_size,tile_size).intersection(area)
			draw_texture_rect_region(texture,box,Rect2(source.position,box.size/scale_value))

func _draw()->void:
	if data.is_empty():return
	visible_modules=0
	# Every legal threshold has an actual floor beneath it, including transparent
	# margins between a generated wall silhouette and its rectangular PNG bounds.
	for row:Dictionary in data.ground:
		if not (str(row.id).contains("corridor") or str(row.id).contains("cross") or str(row.id).contains("landing") or str(row.id).contains("outside_") or str(row.id).contains("threshold") or str(row.id).ends_with("_east") or str(row.id).ends_with("_west") or str(row.id).ends_with("_north") or str(row.id).ends_with("_south")):continue
		var polygon:PackedVector2Array=Space.polygon(row.polygon)
		if str(row.id).contains("outside_"):
			var bounds:=Rect2(polygon[0],Vector2.ZERO)
			for point:Vector2 in polygon:bounds=bounds.expand(point)
			bounds.position.x-=32;bounds.size.x+=64
			polygon=PackedVector2Array([bounds.position,Vector2(bounds.end.x,bounds.position.y),bounds.end,Vector2(bounds.position.x,bounds.end.y)])
		var uv:=PackedVector2Array()
		for point:Vector2 in polygon:uv.append(point/floor_tile.get_size())
		draw_polygon(polygon,PackedColorArray([Color.WHITE]),uv,floor_tile)
	var join:Rect2=Space.rect(data.xlabJoin.bounds)
	if join.has_area():
		var wood:Texture2D=textures["res://campuses/future_learning_center/assets/rooms/xlab_north.png"]
		_tile(wood,Rect2(325,1750,140,140),join)
		_tile(wood,Rect2(12,1450,70,250),Rect2(join.position.x,join.position.y,116,join.size.y),1.66)
		_tile(wood,Rect2(725,1450,80,250),Rect2(join.end.x-133,join.position.y,133,join.size.y),1.66)
	var landing:Rect2=Space.rect(data.northeastLanding.bounds)
	_tile(textures["res://campuses/future_learning_center/assets/rooms/xlab_north.png"],Rect2(725,950,80,250),Rect2(landing.end.x-133,landing.position.y,133,landing.size.y),1.66)
	_draw_atrium()
	for item:Dictionary in data.modules:
		if not capture_only and not Space.rect(item.bounds).intersects(framing.visible_rect().grow(120)):continue
		visible_modules+=1
		_region(textures[item.path],Space.rect(item.crop),Vector2(item.at[0],item.at[1]),float(item.scale))
	if not capture_only:
		var frame:=Body.frame_at(elapsed*1000.0) if walking else 0
		var actor:Texture2D=textures["res://assets/rpg/player/player_%s_%d.png"%["side" if facing=="left" else facing,frame]]
		draw_circle(player+Body.FOOT_CENTER_OFFSET,11,Color(0,0,0,.18))
		if facing=="left":
			draw_set_transform(player,0,Vector2(-1,1));draw_texture_rect(actor,Body.visual_rect(Vector2.ZERO),false);draw_set_transform(Vector2.ZERO)
		else:draw_texture_rect(actor,Body.visual_rect(player),false)
		_draw_covers()
	if geometry_visible:
		for region:Dictionary in data.ground:draw_colored_polygon(Space.polygon(region.polygon),Color(.25,.85,.7,.15))
		for edge:PackedVector2Array in space.ground.edges:draw_line(edge[0],edge[1],Color(.9,.35,.3,.8),2)
		draw_rect(Body.foot_rect(player),Color(.3,1,.8),false,2)

func _draw_atrium()->void:
	var b:Rect2=Space.rect(data.atrium.bounds)
	var plate:Texture2D=textures[data.atrium.source]
	# Same-source strips repeat at a uniform scale; void never becomes ground.
	_tile(plate,Rect2(420,385,195,350),b.grow(-65),3.0)
	_tile(plate,Rect2(389,405,29,160),Rect2(b.position,Vector2(87,b.size.y)),3.0)
	_tile(plate,Rect2(625,405,29,160),Rect2(b.end.x-87,b.position.y,87,b.size.y),3.0)
	_tile(plate,Rect2(420,322,195,40),Rect2(b.position.x,b.position.y,b.size.x,120),3.0)
	_tile(plate,Rect2(420,950,195,42),Rect2(b.position.x,b.end.y-126,b.size.x,126),3.0)

func _draw_covers()->void:
	var body:Rect2=Body.visual_rect(player)
	for cover:Dictionary in data.occluders:
		var item:Dictionary={}
		for row:Dictionary in data.modules:
			if row.id==cover.module:item=row;break
		if item.is_empty():continue
		var source:Rect2=Space.rect(cover.rect)
		var origin:=Vector2(item.at[0],item.at[1])-Vector2(item.crop[0],item.crop[1])*float(item.scale)
		var baseline:float=origin.y+float(cover.baseline)*float(item.scale)
		if not Space.in_front(baseline,player):continue
		var painted:=Rect2(origin+source.position*float(item.scale),source.size*float(item.scale))
		var hit:=painted.intersection(body)
		if not hit.has_area():continue
		var slice:=Rect2((hit.position-origin)/float(item.scale),hit.size/float(item.scale))
		draw_texture_rect_region(textures[item.path],hit,slice,Color(1,1,1,.78))
