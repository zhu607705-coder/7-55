extends Node2D
const Body=preload("res://scripts/player_metrics.gd")
const NpcPicker=preload("res://scripts/world_object_picker.gd")
const Space=preload("res://scripts/space/spatial_rules.gd")
const FloorSpace=preload("res://campuses/future_learning_center/scripts/floor_space.gd")
const RoomCamera=preload("res://campuses/future_learning_center/scripts/room_camera.gd")
const Lighting=preload("res://campuses/future_learning_center/scripts/floor_lighting.gd")
const Transit=preload("res://campuses/future_learning_center/scripts/building_transit.gd")
const Workbench=preload("res://campuses/future_learning_center/scripts/workbench_view.gd")
const Stairs=preload("res://campuses/future_learning_center/scripts/stair_view.gd")
const SignalSync=preload("res://campuses/future_learning_center/scripts/signal_sync_view.gd")
const MotionLab=preload("res://campuses/future_learning_center/scripts/motion_lab_view.gd")
const PantryTray=preload("res://campuses/future_learning_center/scripts/pantry_tray_view.gd")
var pantry_tray:Control
var pantry_pending:=false
const TouchStick=preload("res://campuses/future_learning_center/scripts/touch_stick.gd")
const MOTION_ANCHORS:={"solar":"formula_workbench_0","robotics":"robotics_workbench_30"}
var motion_lab:Control
var motion_pending:=""
var signal_sync:Control
var signal_sync_pending:=false
const PuzzleAnchors = {
 "koala": ["koala", "koala_desk_94", 2],
 "machinery": ["machinery", "machinery_workbench_77", 2],
 "seminar_2f": ["solid_projection", "seminar_discussion_table_49", 2],
 "platform": ["platform", "platform_discussion_table_38", 2],
 "robotics": ["robotics", "robotics_workbench_31", 2],
 "team": ["signal_sync", "team_desk_18", 2],
 "formula": ["formula", "formula_workbench_1", 2],
 "studio_2": ["coupled", "studio_2_desk_58", 3],
 "studio_4": ["access", "studio_4_desk_174", 3],
 "studio_3": ["sync", "studio_3_desk_116", 3],
 "studio_1": ["perspective", "studio_1_desk_0", 3],
 "recording": ["recording", "recording_desk_234", 3],
 "pantry": ["balance", "pantry_desk_262", 3],
 "seminar": ["schedule", "seminar_discussion_table_238", 3],
 "xlab_box": ["projection", "xlab_box_projection_table", 3],
 "xlab_south": ["fold", "xlab_south_desk_322", 3],
 "xlab_north": ["logic", "xlab_north_desk_266", 3],
 "flex_c": ["flex", "flex_c_desk_138", 4],
 "collab_b": ["collab", "collab_b_desk_85", 4],
 "focus_a": ["focus", "focus_a_desk_16", 4],
 "storage": ["storage", "storage_cabinet_12", 4],
 "seminar_3": ["assembly", "seminar_3_discussion_table_7", 4],
 "seminar_2": ["rail", "seminar_2_discussion_table_2", 4],
 "seminar_1": ["rules", "seminar_1_whiteboard_0", 4],
}
var puzzle_views:Dictionary={}
var puzzle_layer:CanvasLayer
var active_puzzle:Control
var puzzle_pending:=""
var persistence_enabled:=false
var _restoring:=true
var _suspending:=false
var _checkpoint_elapsed:=0.0
var _completion_stamp:=""
var stairs:Control
var stair_destination:Dictionary={}
var workbench:Control
var workbench_pending:=false
var lighting=Lighting.new()
var transit=Transit.new()
var transit_panel:PanelContainer
var transit_button:Button
var time_button:Button
var preview_hours:=[8.0,12.0,16.0,21.0]
var time_index:=1
var object_hint:=""
# Ambient people are optional presentation, never room model/save state.
const NPC_RANGE:=100.0
var npc_picker=NpcPicker.new()
var npc_pending:=""
var npc_reply:=""
var npc_reply_id:=""
var npc_reply_remaining:=0.0
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
var joystick:Control
var touched_buttons:Dictionary={}
var title_label:Label
var place_label:Label
var ui:CanvasLayer
var invalid_frames:=0
var visible_modules:=0
var floor_tile:Texture2D

func _ready()->void:
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	floor_tile=ImageTexture.create_from_image(_texture("res://campuses/future_learning_center/assets/rooms/pantry_ambient.png").get_image().get_region(Rect2i(1020,450,120,120)))
	texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
	for direction:String in ["down","up","side"]:
		for i:int in 8:_texture("res://assets/rpg/player/player_%s_%d.png"%[direction,i])
	add_child(camera);camera.enabled=true;camera.position_smoothing_enabled=false
	_build_ui()
	var bench_layer:=CanvasLayer.new();bench_layer.layer=5;add_child(bench_layer)
	puzzle_layer=bench_layer
	workbench=Workbench.new();workbench.size=Vector2(960,540);bench_layer.add_child(workbench)
	workbench.closed.connect(func()->void:ui.show();route.clear();workbench_pending=false;_commit_room("2:electrical",workbench.model))
	signal_sync=SignalSync.new();signal_sync.size=Vector2(960,540);bench_layer.add_child(signal_sync)
	signal_sync.closed.connect(func()->void:ui.show();route.clear();signal_sync_pending=false;_commit_room("2:signal_bench",signal_sync.model))
	motion_lab=MotionLab.new();motion_lab.size=Vector2(960,540);bench_layer.add_child(motion_lab)
	motion_lab.closed.connect(func()->void:ui.show();route.clear();motion_pending="";_commit_room("2:solar_bench",motion_lab.solar);_commit_room("2:robot_delivery",motion_lab.robot))
	pantry_tray=PantryTray.new();pantry_tray.size=Vector2(960,540);bench_layer.add_child(pantry_tray)
	pantry_tray.closed.connect(func()->void:ui.show();route.clear();pantry_pending=false;_commit_room("3:pantry_water",pantry_tray.model))
	stairs=Stairs.new();stairs.size=Vector2(960,540);bench_layer.add_child(stairs)
	stairs.cancelled.connect(func()->void:stair_destination.clear();ui.show();route.clear())
	stairs.finished.connect(_finish_stairs)
	load_floor(3);set_hour(12)
	_restore_activity()
	_restoring=false
	_completion_stamp=_completion_signature()
	queue_redraw()

func load_floor(floor_number:int,arrival:Vector2=Vector2.INF)->bool:
	if not floor_number in Transit.FLOORS:return false
	if is_instance_valid(joystick):joystick.cancel()
	var next:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://campuses/future_learning_center/data/floor_%d.json"%floor_number))
	var next_space=FloorSpace.new();next_space.configure(next)
	var foot:=Vector2(next.spawn[0],next.spawn[1]) if not arrival.is_finite() else arrival
	if not next_space.can_stand(foot-Body.FOOT_CENTER_OFFSET):return false
	if is_instance_valid(active_puzzle):active_puzzle.close()
	puzzle_pending=""
	if is_instance_valid(joystick):joystick.cancel()
	if is_instance_valid(workbench) and workbench.visible:workbench.close()
	if is_instance_valid(signal_sync) and signal_sync.visible:signal_sync.close()
	if is_instance_valid(motion_lab) and motion_lab.visible:motion_lab.close()
	if is_instance_valid(pantry_tray) and pantry_tray.visible:pantry_tray.close()
	if is_instance_valid(stairs):stairs.model.cancel();stairs.hide();stair_destination.clear();ui.show()
	workbench_pending=false
	signal_sync_pending=false
	motion_pending=""
	pantry_pending=false
	_clear_npc_interaction()
	data=next;space=next_space;route.clear();touch_vector=Vector2.ZERO;touched_buttons.clear()
	for item:Dictionary in data.modules:_texture(item.path)
	for item:Dictionary in data.get("objects",[]):_texture(item.path)
	for item:Dictionary in data.get("npcs",[]):_texture(item.path)
	for item:Dictionary in data.get("atriums",[]):_texture(item.source)
	if data.has("atrium"):_texture(data.atrium.source)
	player=foot-Body.FOOT_CENTER_OFFSET;framing=RoomCamera.new();overview=false
	framing.update(0,player,space,true);_apply_camera()
	if is_instance_valid(title_label):title_label.text="未来学习中心  /  %dF"%floor_number
	if is_instance_valid(transit_panel):transit_panel.hide()
	if not _restoring:checkpoint_state()
	queue_redraw();return true

func set_hour(hour:float)->void:
	lighting.set_hour(hour);self_modulate=lighting.ambient
	if is_instance_valid(time_button):time_button.text="光照 %02d:00"%int(hour)
	queue_redraw()

func travel_to(floor_number:int)->bool:
	if is_instance_valid(stairs) and stairs.visible:return false
	var target:Dictionary=transit.destination(data,player,floor_number)
	if target.is_empty():return false
	var landing:Dictionary=transit.nearby(data,player)
	if landing.kind=="stairs":
		if not stairs.open(int(data.floor),floor_number,str(landing.id)):return false
		_clear_npc_interaction()
		stair_destination=target.duplicate(true);stair_destination["source"]=int(data.floor)
		route.clear();touch_vector=Vector2.ZERO;touched_buttons.clear();transit_panel.hide();ui.hide();return true
	return load_floor(int(target.floor),Vector2(target.point[0],target.point[1]))

func _finish_stairs(receipt:Dictionary)->void:
	ui.show()
	if receipt.is_empty() or stair_destination.is_empty():return
	var expected:Dictionary=stair_destination.duplicate(true);stair_destination.clear()
	if int(data.floor)!=int(expected.source) or receipt.source!=expected.source or receipt.floor!=expected.floor or receipt.via!=expected.via:return
	# Revalidate the actual source landing and paired destination at arrival.
	var target:Dictionary=transit.destination(data,player,int(receipt.floor))
	if target.is_empty() or target.via!=receipt.via:return
	load_floor(int(target.floor),Vector2(target.point[0],target.point[1]))

func _texture(path:String)->Texture2D:
	if not textures.has(path):
		if OS.has_feature("web"):
			textures[path]=load(path);return textures[path]
		# Review can consume a fresh raw generated asset before an editor import.
		var source:=Image.load_from_file(ProjectSettings.globalize_path(path))
		if source==null or source.is_empty():push_error("FLC image missing: "+path);return null
		textures[path]=ImageTexture.create_from_image(source)
	return textures[path]

func _process(dt:float)->void:
	elapsed+=dt
	_tick_npc_feedback(dt)
	if capture_only:return
	_checkpoint_elapsed+=dt
	if persistence_enabled and _checkpoint_elapsed>=3:
		_checkpoint_elapsed=0
		var stamp:=_completion_signature()
		if stamp!=_completion_stamp and checkpoint_state():_completion_stamp=stamp
	if is_instance_valid(active_puzzle) and active_puzzle.visible:return
	if is_instance_valid(workbench) and workbench.visible:return
	if is_instance_valid(signal_sync) and signal_sync.visible:return
	if is_instance_valid(motion_lab) and motion_lab.visible:return
	if is_instance_valid(pantry_tray) and pantry_tray.visible:return
	if is_instance_valid(stairs) and stairs.visible:return
	var direction:=Vector2.ZERO
	if user_control and not overview:
		direction=Vector2(int(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT))-int(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)),int(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN))-int(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)))+touch_vector
		if direction.length_squared()>0:route.clear();puzzle_pending="";_clear_npc_interaction();direction=direction.limit_length()
		elif not route.is_empty():
			# Follow the validated corner all the way before taking the next leg.
			# Skipping it four pixels early can cut into a chair's foot collider.
			while not route.is_empty() and player.distance_to(route[0])<.1:route.remove_at(0)
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
	if not puzzle_pending.is_empty() and route.is_empty():
		var pending:=puzzle_pending;puzzle_pending="";open_puzzle(pending)
	if workbench_pending and route.is_empty():
		workbench_pending=false;open_workbench()
	if signal_sync_pending and route.is_empty():
		signal_sync_pending=false;open_signal_sync()
	if not motion_pending.is_empty() and route.is_empty():
		var pending:=motion_pending;motion_pending="";open_motion_lab(pending)
	if pantry_pending and route.is_empty():
		pantry_pending=false;open_pantry()
	if not npc_pending.is_empty() and route.is_empty():
		var pending:=npc_pending;npc_pending=""
		if not talk_to_npc(pending):_npc_feedback("暂时无法靠近。")
	if is_instance_valid(place_label):
		var room:Dictionary=space.room_at(player+Body.FOOT_CENTER_OFFSET)
		var landing:Dictionary=transit.nearby(data,player)
		transit_button.visible=not landing.is_empty() and not overview
		if not landing.is_empty():transit_button.text=str(landing.name)
		elif is_instance_valid(transit_panel):transit_panel.hide()
		place_label.text=("%dF 全层总览"%int(data.floor)) if overview else str(room.get("name","环廊"))+object_hint+("  ·  "+npc_reply if not npc_reply.is_empty() else "")
		if can_open_workbench() and not overview:place_label.text+="  ·  操作台"
	queue_redraw()

func _apply_camera()->void:
	camera.position=framing.center;camera.zoom=Vector2.ONE*framing.zoom;camera.force_update_scroll()

func set_foot(point:Vector2,snap:=true)->bool:
	var candidate:=point-Body.FOOT_CENTER_OFFSET
	if not space.can_stand(candidate):return false
	player=candidate;route.clear();framing.update(0,player,space,snap,overview);_apply_camera();queue_redraw();return true

func _unhandled_input(event:InputEvent)->void:
	if not user_control:return
	if event is InputEventScreenTouch and event.canceled:
		if not npc_pending.is_empty():route.clear()
		_clear_npc_interaction();return
	if is_instance_valid(active_puzzle) and active_puzzle.visible:return
	if is_instance_valid(stairs) and stairs.visible:return
	if is_instance_valid(workbench) and workbench.visible:return
	if is_instance_valid(signal_sync) and signal_sync.visible:return
	if is_instance_valid(motion_lab) and motion_lab.visible:return
	if is_instance_valid(pantry_tray) and pantry_tray.visible:return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_TAB:toggle_overview();get_viewport().set_input_as_handled()
		elif event.keycode==KEY_F2:geometry_visible=not geometry_visible
		elif event.keycode==KEY_L:_cycle_time()
		elif event.keycode==KEY_E:open_transit()
		elif event.keycode==KEY_SPACE:
			if not open_pantry() and not open_workbench() and not open_signal_sync() and not open_motion_lab("solar") and not open_motion_lab("robotics"):
				var opened:=false
				for key:String in PuzzleAnchors:
					if open_puzzle(key):opened=true;break
				if not opened and not talk_nearby_npc():inspect_nearby()
	elif event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		point_action(screen_to_world(event.position));get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch and event.pressed and not event.canceled:
		point_action(screen_to_world(event.position));get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.keycode==KEY_ESCAPE and event.pressed:
		route.clear();_clear_npc_interaction()

func screen_to_world(screen:Vector2)->Vector2:return framing.center+(screen-RoomCamera.VIEW/2)/framing.zoom
func world_to_screen(point:Vector2)->Vector2:return (point-framing.center)*framing.zoom+RoomCamera.VIEW/2
func request_walk(foot:Vector2)->void:
	if overview:return
	_clear_npc_interaction()
	puzzle_pending=""
	workbench_pending=false
	signal_sync_pending=false
	motion_pending=""
	pantry_pending=false
	route=space.route(player,foot-Body.FOOT_CENTER_OFFSET)
func pantry_desk()->Dictionary:
	if int(data.floor)!=3:return {}
	for item:Dictionary in data.objects:
		if item.id=="pantry_pantry_island_250":return item
	return {}
func pantry_approach()->Vector2:
	var item:=pantry_desk()
	if item.is_empty():return Vector2.INF
	var box:Rect2=Space.rect(item.footprint)
	for point:Vector2 in [Vector2(box.end.x+55,box.get_center().y),Vector2(box.position.x-55,box.get_center().y),Vector2(box.get_center().x,box.end.y+80)]:
		if space.can_stand(point-Body.FOOT_CENTER_OFFSET):return point
	return Vector2.INF
func can_open_pantry()->bool:
	var item:=pantry_desk()
	if item.is_empty() or overview:return false
	var foot:=player+Body.FOOT_CENTER_OFFSET;var box:Rect2=Space.rect(item.footprint)
	return foot.distance_to(foot.clamp(box.position,box.end))<=105
func open_pantry()->bool:
	if _has_open_station():return false
	if not can_open_pantry():return false
	if is_instance_valid(joystick):joystick.cancel()
	route.clear();touch_vector=Vector2.ZERO;touched_buttons.clear()
	pantry_pending=false;motion_pending="";signal_sync_pending=false;workbench_pending=false
	_clear_npc_interaction()
	pantry_tray.open();ui.hide();return true
func motion_desk(mode:String)->Dictionary:
	if int(data.floor)!=2 or not MOTION_ANCHORS.has(mode):return {}
	for item:Dictionary in data.objects:
		if item.id==MOTION_ANCHORS[mode]:return item
	return {}
func motion_approach(mode:String)->Vector2:
	var item:=motion_desk(mode)
	if item.is_empty():return Vector2.INF
	var box:Rect2=Space.rect(item.footprint)
	for point:Vector2 in [Vector2(box.position.x-55,box.get_center().y),Vector2(box.end.x+55,box.get_center().y),Vector2(box.get_center().x,box.end.y+80)]:
		if space.can_stand(point-Body.FOOT_CENTER_OFFSET):return point
	return Vector2.INF
func can_open_motion_lab(mode:String)->bool:
	var item:=motion_desk(mode)
	if item.is_empty() or overview:return false
	var foot:=player+Body.FOOT_CENTER_OFFSET;var box:Rect2=Space.rect(item.footprint)
	return foot.distance_to(foot.clamp(box.position,box.end))<=105
func open_motion_lab(mode:String)->bool:
	if _has_open_station():return false
	if not can_open_motion_lab(mode):return false
	if is_instance_valid(joystick):joystick.cancel()
	route.clear();touch_vector=Vector2.ZERO;touched_buttons.clear();motion_pending="";signal_sync_pending=false;workbench_pending=false
	_clear_npc_interaction()
	motion_lab.open(mode);ui.hide();return true
func signal_sync_desk()->Dictionary:
	if int(data.floor)!=2:return {}
	for item:Dictionary in data.objects:
		if item.id=="team_desk_6":return item
	return {}
func signal_sync_approach()->Vector2:
	var item:=signal_sync_desk()
	if item.is_empty():return Vector2.INF
	var box:Rect2=Space.rect(item.footprint)
	# Choose a clear side of the actual desk footprint, without changing map geometry.
	for point:Vector2 in [Vector2(box.position.x-55,box.get_center().y),Vector2(box.end.x+55,box.get_center().y),Vector2(box.get_center().x,box.end.y+80)]:
		if space.can_stand(point-Body.FOOT_CENTER_OFFSET):return point
	return Vector2.INF
func can_open_signal_sync()->bool:
	var item:=signal_sync_desk()
	if item.is_empty() or overview:return false
	var foot:=player+Body.FOOT_CENTER_OFFSET;var box:Rect2=Space.rect(item.footprint)
	return foot.distance_to(foot.clamp(box.position,box.end))<=105
func open_signal_sync()->bool:
	if _has_open_station():return false
	if not can_open_signal_sync():return false
	if is_instance_valid(joystick):joystick.cancel()
	route.clear();touch_vector=Vector2.ZERO;touched_buttons.clear();signal_sync_pending=false;workbench_pending=false
	_clear_npc_interaction()
	signal_sync.open();ui.hide();return true
func workshop_bench()->Dictionary:
	if not data.has("workshopReference"):return {}
	for o:Dictionary in data.objects:
		if o.id==data.workshopReference.bench:return o
	return {}
func can_open_workbench()->bool:
	var item:=workshop_bench()
	if item.is_empty() or overview:return false
	var foot:=player+Body.FOOT_CENTER_OFFSET;var box:Rect2=Space.rect(item.footprint)
	return foot.distance_to(foot.clamp(box.position,box.end))<=105
func open_workbench()->bool:
	if _has_open_station():return false
	if not can_open_workbench():return false
	if is_instance_valid(joystick):joystick.cancel()
	route.clear();touch_vector=Vector2.ZERO;touched_buttons.clear();workbench_pending=false
	if is_instance_valid(joystick):joystick.cancel()
	_clear_npc_interaction()
	workbench.open();ui.hide();return true
func point_action(at:Vector2)->void:
	if _has_open_station():return
	var pantry:=pantry_desk()
	if not pantry.is_empty() and Space.rect(pantry.bounds).has_point(at):
		if open_pantry():return
		var approach:=pantry_approach()
		if approach.is_finite():request_walk(approach);pantry_pending=not route.is_empty()
		return
	for mode:String in MOTION_ANCHORS:
		var bench:=motion_desk(mode)
		if not bench.is_empty() and Space.rect(bench.bounds).has_point(at):
			if open_motion_lab(mode):return
			var approach:=motion_approach(mode)
			if approach.is_finite():request_walk(approach);motion_pending=mode if not route.is_empty() else ""
			return
	var desk:=signal_sync_desk()
	if not desk.is_empty() and Space.rect(desk.bounds).has_point(at):
		if open_signal_sync():return
		var approach:=signal_sync_approach()
		if approach.is_finite():request_walk(approach);signal_sync_pending=not route.is_empty()
		return
	if int(data.floor) in [2,3,4]:
		for key:String in PuzzleAnchors:
			var anchor:=puzzle_anchor(key)
			if not anchor.is_empty() and Space.rect(anchor.bounds).has_point(at):
				if open_puzzle(key):return
				var approach:=puzzle_approach(key)
				if approach.is_finite():
					request_walk(approach);puzzle_pending=key
				return
	var item:=workshop_bench()
	if not item.is_empty() and Space.rect(item.bounds).has_point(at):
		if open_workbench():return
		var target:Array=data.workshopReference.approach
		request_walk(Vector2(target[0],target[1]));workbench_pending=not route.is_empty()
	else:
		var person:=npc_at(at)
		if not person.is_empty():request_npc(str(person.id))
		else:request_walk(at)
func toggle_overview()->void:
	if is_instance_valid(joystick):joystick.cancel()
	_clear_npc_interaction()
	overview=not overview;route.clear();touch_vector=Vector2.ZERO

func _notification(what:int)->void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]:suspend_activity()

func _build_ui()->void:
	ui=CanvasLayer.new();add_child(ui)
	var panel:=Control.new();panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);panel.mouse_filter=Control.MOUSE_FILTER_IGNORE;ui.add_child(panel)
	var font:Font=load("res://scripts/ui/native_typography.gd").body_font()
	var shade:=ColorRect.new();shade.color=Color(.035,.055,.085,.9);shade.position=Vector2(0,0);shade.size=Vector2(960,40);shade.mouse_filter=Control.MOUSE_FILTER_IGNORE;panel.add_child(shade)
	title_label=Label.new();title_label.position=Vector2(18,8);title_label.add_theme_font_override("font",font);title_label.add_theme_font_size_override("font_size",17);panel.add_child(title_label)
	time_button=Button.new();time_button.set_meta("tactile_keep_layout",true);time_button.set_meta("tactile_variant","secondary");time_button.position=Vector2(644,5);time_button.size=Vector2(130,30);time_button.add_theme_font_override("font",font);time_button.pressed.connect(_cycle_time);panel.add_child(time_button)
	transit_button=Button.new();transit_button.set_meta("tactile_keep_layout",true);transit_button.set_meta("tactile_variant","secondary");transit_button.position=Vector2(390,462);transit_button.size=Vector2(180,38);transit_button.add_theme_font_override("font",font);transit_button.pressed.connect(open_transit);panel.add_child(transit_button);transit_button.hide()
	transit_panel=PanelContainer.new();transit_panel.position=Vector2(330,350);transit_panel.size=Vector2(300,85);panel.add_child(transit_panel);transit_panel.hide()
	var choices:=HBoxContainer.new();transit_panel.add_child(choices)
	for f:int in Transit.FLOORS:
		var choice:=Button.new();choice.set_meta("tactile_keep_layout",true);choice.set_meta("tactile_variant","secondary");choice.name=str(f);choice.text="%dF"%f;choice.custom_minimum_size=Vector2(90,70);choice.add_theme_font_override("font",font);choices.add_child(choice);choice.pressed.connect(func()->void:travel_to(f))
	var button:=Button.new();button.set_meta("tactile_keep_layout",true);button.set_meta("tactile_variant","secondary");button.text="楼层总图";button.position=Vector2(790,5);button.size=Vector2(155,30);button.add_theme_font_override("font",font);button.add_theme_font_size_override("font_size",14);button.pressed.connect(toggle_overview);panel.add_child(button)
	var footer:=ColorRect.new();footer.color=Color(.035,.055,.085,.86);footer.position=Vector2(0,509);footer.size=Vector2(960,31);footer.mouse_filter=Control.MOUSE_FILTER_IGNORE;panel.add_child(footer)
	place_label=Label.new();place_label.position=Vector2(18,513);place_label.add_theme_font_override("font",font);place_label.add_theme_font_size_override("font_size",14);panel.add_child(place_label)
	var touch_enabled:=OS.has_feature("mobile") or OS.get_environment("FLC_TOUCH")=="1"
	if OS.has_feature("web"):touch_enabled=bool(JavaScriptBridge.eval("window.matchMedia('(pointer: coarse)').matches"))
	if touch_enabled:
		joystick=TouchStick.new();joystick.position=Vector2(18,343);joystick.size=Vector2(156,156);panel.add_child(joystick)
		joystick.moved.connect(func(value:Vector2)->void:touch_vector=value)

func _touch_changed()->void:
	touch_vector=Vector2.ZERO
	for vector:Vector2 in touched_buttons.values():touch_vector+=vector
	touch_vector=touch_vector.limit_length()

func _cycle_time()->void:
	time_index=(time_index+1)%preview_hours.size();set_hour(preview_hours[time_index])

func open_transit()->void:
	var landing:Dictionary=transit.nearby(data,player)
	if landing.is_empty() or overview:return
	_clear_npc_interaction()
	route.clear()
	for button:Button in transit_panel.get_child(0).get_children():
		var target:=int(str(button.name));button.disabled=transit.destination(data,player,target).is_empty()
		button.text=("上楼 %dF" if target>int(data.floor) else "下楼 %dF")%target if landing.kind=="stairs" and target!=int(data.floor) else "%dF"%target
	transit_panel.visible=not transit_panel.visible

func inspect_nearby()->void:
	_clear_npc_interaction()
	object_hint=""
	var foot:=player+Body.FOOT_CENTER_OFFSET;var distance:=100.0
	for item:Dictionary in data.get("objects",[]):
		if item.get("mounted",false):continue
		var box:Rect2=Space.rect(item.footprint)
		var closest:=foot.clamp(box.position,box.end)
		if foot.distance_to(closest)<distance:
			distance=foot.distance_to(closest);object_hint="  ·  "+str(item.name)

# NPC geometry uses the player's existing sprite scale and foot-center contract.
# It is deliberately stationary: no second navigation or saved actor state.
func npc_by_id(id:String)->Dictionary:
	for person:Dictionary in data.get("npcs",[]):
		if str(person.id)==id:return person
	return {}

func npc_foot(person:Dictionary)->Vector2:
	return Vector2(person.foot[0],person.foot[1])

func npc_geometry(person:Dictionary)->Dictionary:
	var frame:Vector2=Vector2(person.frameSize[0],person.frameSize[1])
	return {"rect":Body.visual_rect(npc_foot(person)-Body.FOOT_CENTER_OFFSET),"texture":_texture(str(person.path)),"source":Rect2(Vector2.ZERO,frame)}

func npc_at(point:Vector2)->Dictionary:
	if overview:return {}
	var people:Array=data.get("npcs",[]).duplicate()
	people.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return float(a.foot[1])>float(b.foot[1]))
	for person:Dictionary in people:
		if not npc_picker.contains(npc_geometry(person),point):continue
		# A transparent sprite corner cannot steal an object click; nor can a
		# person behind an opaque foreground prop be picked through that prop.
		for prop:Dictionary in data.get("objects",[]):
			if float(prop.baseline)<npc_foot(person).y:continue
			if npc_picker.contains({"rect":Space.rect(prop.bounds),"source":Space.rect(prop.crop),"texture":_texture(str(prop.path))},point):return {}
		return person
	return {}

func can_talk_to_npc(person:Dictionary)->bool:
	if person.is_empty() or overview or _has_open_station():return false
	var foot:=player+Body.FOOT_CENTER_OFFSET
	if str(space.room_at(foot).get("id",""))!=str(person.room):return false
	var distance:=foot.distance_to(npc_foot(person))
	if distance>NPC_RANGE:return false
	# Stop the sight/approach test outside the other actor's solid foot box.
	var edge:=foot+(npc_foot(person)-foot).normalized()*maxf(0.0,distance-24.0)
	return space.segment_clear(player,edge-Body.FOOT_CENTER_OFFSET)

func npc_approach(person:Dictionary)->Vector2:
	var best:=Vector2.INF
	var length:=INF
	for direction:Vector2 in [Vector2.DOWN,Vector2.RIGHT,Vector2.LEFT,Vector2.UP,Vector2(1,1).normalized(),Vector2(-1,1).normalized(),Vector2(1,-1).normalized(),Vector2(-1,-1).normalized()]:
		var foot:=npc_foot(person)+direction*55.0
		var target:=foot-Body.FOOT_CENTER_OFFSET
		if str(space.room_at(foot).get("id",""))!=str(person.room) or not space.can_stand(target):continue
		if not space.segment_clear(target,npc_foot(person)+direction*24.0-Body.FOOT_CENTER_OFFSET):continue
		var path:PackedVector2Array=space.route(player,target)
		if path.is_empty() and player.distance_to(target)>1.0:continue
		var distance:=0.0
		var previous:=player
		for corner:Vector2 in path:distance+=previous.distance_to(corner);previous=corner
		if distance<length:length=distance;best=foot
	return best

func talk_to_npc(id:String)->bool:
	var person:=npc_by_id(id)
	if not can_talk_to_npc(person):return false
	_clear_npc_interaction()
	route.clear();touch_vector=Vector2.ZERO;touched_buttons.clear()
	puzzle_pending="";workbench_pending=false;signal_sync_pending=false;motion_pending="";pantry_pending=false
	if is_instance_valid(joystick):joystick.cancel()
	object_hint=""
	_npc_feedback(str(person.name)+"："+str(person.line),id)
	return true

func request_npc(id:String)->void:
	if _has_open_station() or overview:return
	var person:=npc_by_id(id)
	if person.is_empty():return
	if talk_to_npc(id):return
	var approach:=npc_approach(person)
	_clear_npc_interaction()
	if not approach.is_finite():
		route.clear();puzzle_pending="";workbench_pending=false;signal_sync_pending=false;motion_pending="";pantry_pending=false
		_npc_feedback("暂时无法靠近。");return
	request_walk(approach)
	if not route.is_empty():npc_pending=id
	else:_npc_feedback("暂时无法靠近。")

func talk_nearby_npc()->bool:
	var best:=""
	var distance:=INF
	for person:Dictionary in data.get("npcs",[]):
		if not can_talk_to_npc(person):continue
		var candidate:float=(player+Body.FOOT_CENTER_OFFSET).distance_to(npc_foot(person))
		if candidate<distance:distance=candidate;best=str(person.id)
	return talk_to_npc(best) if not best.is_empty() else false

func _npc_feedback(message:String,id:String="")->void:
	object_hint="";npc_reply=message;npc_reply_id=id
	npc_reply_remaining=clampf(1.6+float(message.length())*.12,2.4,6.5)

func _clear_npc_interaction()->void:
	npc_pending="";npc_reply="";npc_reply_id="";npc_reply_remaining=0.0

func _tick_npc_feedback(dt:float)->void:
	if npc_reply_remaining<=0.0:return
	npc_reply_remaining=maxf(0.0,npc_reply_remaining-dt)
	if npc_reply_remaining==0.0:npc_reply="";npc_reply_id=""

func _draw_npc(person:Dictionary)->void:
	var geometry:=npc_geometry(person)
	draw_circle(npc_foot(person)+Vector2(1,2),10,Color(0,0,0,.16))
	draw_texture_rect_region(geometry.texture,geometry.rect,geometry.source)

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
		draw_colored_polygon(polygon,Color("afb2b3"))
	var join:Rect2=Space.rect(data.get("xlabJoin",{}).get("bounds",[0,0,0,0]))
	if join.has_area():
		var wood:Texture2D=textures["res://campuses/future_learning_center/assets/rooms/xlab_north_ambient.png"]
		_tile(wood,Rect2(325,1750,140,140),join)
		_tile(wood,Rect2(12,1450,70,250),Rect2(join.position.x,join.position.y,116,join.size.y),1.66)
		_tile(wood,Rect2(725,1450,80,250),Rect2(join.end.x-133,join.position.y,133,join.size.y),1.66)
	_draw_atrium()
	for item:Dictionary in data.modules:
		if not capture_only and not Space.rect(item.bounds).intersects(framing.visible_rect().grow(120)):continue
		visible_modules+=1
		if item.has("asset") and not item.get("core",false):draw_rect(Space.rect(item.bounds),Color("afb2b3"))
		_region(textures[item.path],Space.rect(item.crop),Vector2(item.at[0],item.at[1]),float(item.scale))
	var view:Rect2=space.world_bounds if capture_only else framing.visible_rect().grow(200)
	lighting.draw_room(self,data,view)
	var items:Array=[]
	for object:Dictionary in data.get("objects",[]):
		if not Space.rect(object.bounds).grow(200).intersects(view):continue
		lighting.draw_contact(self,object);lighting.draw_shadow(self,object);items.append(object)
	for person:Dictionary in data.get("npcs",[]):
		if npc_geometry(person).rect.intersects(view):items.append({"npc":person,"baseline":float(person.foot[1])})
	if not capture_only:items.append({"actor":true,"baseline":player.y+Body.FOOT_CENTER_OFFSET.y})
	items.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return float(a.baseline)<float(b.baseline))
	for item:Dictionary in items:
		if item.get("actor",false):_draw_actor()
		elif item.has("npc"):_draw_npc(item.npc)
		else:
			_draw_prop(item)
			if int(data.floor)==3:
				if item.id=="pantry_pantry_island_250" and not pantry_tray.model.earned:pantry_tray.draw_room_prop(self,Space.rect(item.bounds))
				elif item.id=="pantry_lounge_coffee_table_249" and pantry_tray.model.earned:pantry_tray.draw_room_prop(self,Space.rect(item.bounds),true)
			if int(data.floor)==2:
				for mode:String in MOTION_ANCHORS:
					if item.id==MOTION_ANCHORS[mode]:motion_lab.draw_room_prop(self,mode,Space.rect(item.bounds))
			if int(data.floor)==2 and item.id in ["team_monitor_front_9","team_monitor_front_13"]:
				SignalSync.mini(self,Space.rect(item.bounds),int(signal_sync.model.displayed.left if item.id=="team_monitor_front_9" else signal_sync.model.displayed.right))
			_draw_puzzle_prop(item)
			if item.id==data.get("workshopReference",{}).get("bench",""):
				var b:Rect2=Space.rect(item.bounds)
				Workbench.mini(self,b.position+Vector2(40,6),1.1,workbench.model)
	if not capture_only:_draw_covers()
	if geometry_visible:
		for region:Dictionary in data.ground:draw_colored_polygon(Space.polygon(region.polygon),Color(.25,.85,.7,.15))
		for edge:PackedVector2Array in space.ground.edges:draw_line(edge[0],edge[1],Color(.9,.35,.3,.8),2)
		draw_rect(Body.foot_rect(player),Color(.3,1,.8),false,2)

func _draw_prop(item:Dictionary)->void:
	var box:Rect2=Space.rect(item.bounds)
	var source:Rect2=Space.rect(item.crop)
	var scale_value:=float(item.scale)
	var hit:Rect2=box.intersection(Body.visual_rect(player))
	if capture_only or not item.has("actorOcclusionAlpha") or player.y+Body.FOOT_CENTER_OFFSET.y>=float(item.baseline) or not hit.has_area():
		_region(textures[item.path],source,box.position,scale_value);return
	# Only the overlap with the actor fades. The remaining canopy and its alpha
	# holes keep their original pixels, and the ground collision stays separate.
	var strips:Array[Rect2]=[
		Rect2(box.position,Vector2(box.size.x,hit.position.y-box.position.y)),
		Rect2(Vector2(box.position.x,hit.end.y),Vector2(box.size.x,box.end.y-hit.end.y)),
		Rect2(Vector2(box.position.x,hit.position.y),Vector2(hit.position.x-box.position.x,hit.size.y)),
		Rect2(Vector2(hit.end.x,hit.position.y),Vector2(box.end.x-hit.end.x,hit.size.y))]
	for strip:Rect2 in strips:
		if strip.has_area():draw_texture_rect_region(textures[item.path],strip,Rect2(source.position+(strip.position-box.position)/scale_value,strip.size/scale_value))
	draw_texture_rect_region(textures[item.path],hit,Rect2(source.position+(hit.position-box.position)/scale_value,hit.size/scale_value),Color(1,1,1,float(item.actorOcclusionAlpha)))

func _draw_atrium()->void:
	var all:Array=data.get("atriums",[]).duplicate()
	if data.has("atrium"):all.append(data.atrium)
	for atrium:Dictionary in all:_atrium(atrium)

func _atrium(atrium:Dictionary)->void:
	var b:Rect2=Space.rect(atrium.bounds)
	var plate:Texture2D=textures[atrium.source]
	var crops:Dictionary=atrium.get("crops",{})
	# Same-source strips repeat at a uniform scale; void never becomes ground.
	_tile(plate,Space.rect(crops.get("interior",[420,385,195,350])),b.grow(-65),3.0)
	_tile(plate,Space.rect(crops.get("west",[389,405,29,160])),Rect2(b.position,Vector2(87,b.size.y)),3.0)
	_tile(plate,Space.rect(crops.get("east",[625,405,29,160])),Rect2(b.end.x-87,b.position.y,87,b.size.y),3.0)
	_tile(plate,Space.rect(crops.get("north",[420,322,195,40])),Rect2(b.position.x,b.position.y,b.size.x,120),3.0)
	_tile(plate,Space.rect(crops.get("south",[420,950,195,42])),Rect2(b.position.x,b.end.y-126,b.size.x,126),3.0)

func _draw_actor()->void:
	var frame:=Body.frame_at(elapsed*1000.0) if walking else 0
	var actor:Texture2D=textures["res://assets/rpg/player/player_%s_%d.png"%["side" if facing=="left" else facing,frame]]
	draw_circle(player+Body.FOOT_CENTER_OFFSET,11,Color(0,0,0,.18))
	if facing=="left":
		draw_set_transform(player,0,Vector2(-1,1));draw_texture_rect(actor,Body.visual_rect(Vector2.ZERO),false);draw_set_transform(Vector2.ZERO)
	else:draw_texture_rect(actor,Body.visual_rect(player),false)

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

# Object stations are optional activities; only the host State facade persists them.
func puzzle_anchor(key:String)->Dictionary:
	if not PuzzleAnchors.has(key) or int(data.get("floor",0))!=int(PuzzleAnchors[key][2]):return {}
	for item:Dictionary in data.get("objects",[]):
		if str(item.id)==str(PuzzleAnchors[key][1]):return item
	return {}

func puzzle_approach(key:String)->Vector2:
	var item:=puzzle_anchor(key)
	if item.is_empty():return Vector2.INF
	var box:Rect2=Space.rect(item.footprint)
	var best:=Vector2.INF
	var distance:=INF
	for offset:Vector2 in [Vector2(0,65),Vector2(-65,0),Vector2(65,0),Vector2(0,-65)]:
		var point:=box.get_center()+offset+Vector2(signf(offset.x)*box.size.x/2,signf(offset.y)*box.size.y/2)
		var target:=point-Body.FOOT_CENTER_OFFSET
		if not space.can_stand(target):continue
		var path:PackedVector2Array=space.route(player,target)
		if path.is_empty() and player.distance_to(target)>1:continue
		var length:=0.0;var previous:=player
		for waypoint:Vector2 in path:length+=previous.distance_to(waypoint);previous=waypoint
		if length<distance:distance=length;best=point
	return best

func open_puzzle(key:String)->bool:
	if _has_open_station():return false
	var item:=puzzle_anchor(key)
	if item.is_empty() or overview:return false
	var box:Rect2=Space.rect(item.footprint)
	var foot:=player+Body.FOOT_CENTER_OFFSET
	if foot.distance_to(foot.clamp(box.position,box.end))>105:return false
	if not puzzle_views.has(key):
		var script=load("res://campuses/future_learning_center/scripts/puzzles/%s_view.gd"%PuzzleAnchors[key][0])
		if script==null:return false
		var view:Control=script.new();view.size=Vector2(960,540);puzzle_layer.add_child(view)
		view.closed.connect(func()->void:active_puzzle=null;ui.show();route.clear();puzzle_pending="";_commit_room(_room_id(key),view.model))
		puzzle_views[key]=view
		_restore_room(_room_id(key),view.model)
	if is_instance_valid(active_puzzle):active_puzzle.close()
	route.clear();puzzle_pending="";touch_vector=Vector2.ZERO
	if is_instance_valid(joystick):joystick.cancel()
	_clear_npc_interaction()
	active_puzzle=puzzle_views[key];active_puzzle.open();ui.hide();return true

func _draw_puzzle_prop(item:Dictionary)->void:
	if not int(data.floor) in [2,3,4]:return
	var key:=""
	for candidate:String in PuzzleAnchors:
		if int(data.floor)==int(PuzzleAnchors[candidate][2]) and item.id==PuzzleAnchors[candidate][1]:key=candidate;break
	if key.is_empty():return
	# These two apparatus groups are now independently mounted raster sprites.
	if data.has("roomLayout") and key in ["team","recording"]:return
	var box:Rect2=Space.rect(item.bounds)
	var at:=Vector2(box.get_center().x,box.position.y+box.size.y*.24)
	# Physical tabletop apparatus, not a floating menu icon.
	var width:=minf(74,box.size.x*.7)
	draw_rect(Rect2(at-Vector2(width/2,4),Vector2(width,24)),Color("545957"))
	draw_rect(Rect2(at-Vector2(width/2,8),Vector2(width,24)),Color("d7d3c4"))
	if key in ["formula","robotics"]:
		draw_line(at+Vector2(-30,10),at+Vector2(30,10),Color("586360"),2)
		draw_rect(Rect2(at+Vector2(-15,-4),Vector2(26,12)),Color("889b97"))
		for x:int in [-10,6]:draw_circle(at+Vector2(x,9),4,Color("414947"))
	elif key=="team":
		for x:int in [-25,5]:
			draw_rect(Rect2(at+Vector2(x,-14),Vector2(22,20)),Color("414b4e"))
			draw_rect(Rect2(at+Vector2(x+3,-11),Vector2(16,13)),Color("a4b4ad"))
	elif key=="platform":
		draw_rect(Rect2(at+Vector2(-23,-15),Vector2(40,27)),Color("dedccf"))
		draw_line(at+Vector2(-20,12),at+Vector2(-25,20),Color("5e6762"),2)
		draw_line(at+Vector2(14,12),at+Vector2(20,20),Color("5e6762"),2)
	elif key=="seminar_2f":
		for i:int in 3:draw_rect(Rect2(at+Vector2(-22+i*14,-6-i%2*8),Vector2(13,17)),Color("9eaa96"))
	elif key=="machinery":
		draw_rect(Rect2(at+Vector2(-25,-5),Vector2(42,18)),Color("a79978"))
		for x:int in [-27,17]:draw_rect(Rect2(at+Vector2(x,-8),Vector2(7,24)),Color("4f625d"))
	elif key=="koala":
		for i:int in 4:draw_rect(Rect2(at+Vector2(-27+i*15,-4),Vector2(12,18)),Color("c4c6b4"))
	elif key=="xlab_box":
		for x:int in [-18,10]:
			draw_rect(Rect2(at+Vector2(x,-15),Vector2(8,25)),Color("77877d"))
			draw_rect(Rect2(at+Vector2(x,-15),Vector2(19,5)),Color("adb4a2"))
	elif key=="pantry":
		draw_rect(Rect2(at+Vector2(-30,-3),Vector2(60,18)),Color("777662"))
		for i:int in 4:draw_circle(at+Vector2(-22+i*15,4),4,Color("e0dccb"))
	elif key=="seminar":
		for i:int in 4:draw_rect(Rect2(at+Vector2(-25+i*14,-3),Vector2(10,15)),Color("849186"))
	elif key=="recording":
		draw_line(at+Vector2(-28,5),at+Vector2(28,5),Color("d5cfb1"),2)
		draw_rect(Rect2(at+Vector2(-3,-15),Vector2(6,28)),Color("657574"))
	elif key=="flex_c":
		for i:int in 3:
			var x:=at.x-25+i*24
			draw_line(Vector2(x,at.y-4),Vector2(x+5,at.y+10),Color("444f51"),3)
	elif key in ["collab_b","seminar_3"]:
		draw_line(at+Vector2(-25,4),at+Vector2(25,4),Color("ded7a5"),2)
		draw_rect(Rect2(at+Vector2(-8,-14),Vector2(5,26)),Color("4b5557"))
	elif key=="seminar_2":
		draw_line(at+Vector2(-30,8),at+Vector2(30,8),Color("4b5557"),3)
		for x:int in [-18,18]:draw_rect(Rect2(at+Vector2(x,-2),Vector2(10,8)),Color("77745e"))
	elif key=="storage":
		draw_rect(Rect2(at+Vector2(-24,-8),Vector2(22,18)),Color("a49172"))
		draw_rect(Rect2(at+Vector2(4,-5),Vector2(23,15)),Color("bcad90"))
	else:
		for i:int in 3:draw_circle(at+Vector2(-22+i*22,3),5,Color("687670"))


# The formal host opts in.	Standalone reviews never write the player's save.
func _save_state()->Node:
	if not persistence_enabled or not is_inside_tree():return null
	return get_node_or_null("/root/State")
func _room_id(key:String)->String:
	return "%d:%s"%[int(PuzzleAnchors[key][2]),"seminar" if key=="seminar_2f" else key]
func _room_models()->Dictionary:
	var models:Dictionary={}
	if is_instance_valid(workbench):models["2:electrical"]=workbench.model
	if is_instance_valid(signal_sync):models["2:signal_bench"]=signal_sync.model
	if is_instance_valid(motion_lab):
		models["2:solar_bench"]=motion_lab.solar;models["2:robot_delivery"]=motion_lab.robot
	if is_instance_valid(pantry_tray):models["3:pantry_water"]=pantry_tray.model
	for key:String in puzzle_views:
		if is_instance_valid(puzzle_views[key]):models[_room_id(key)]=puzzle_views[key].model
	return models
func _restore_room(id:String,model:Object)->void:
	var state:=_save_state()
	if state!=null and state.has_method("restore_flc_room"):state.restore_flc_room(id,model)
func _restore_activity()->void:
	var state:=_save_state()
	if state==null:return
	for id:String in _room_models():_restore_room(id,_room_models()[id])
	var location:Dictionary=state.flc_location() if state.has_method("flc_location") else {}
	if location.is_empty():load_floor(2);return
	var floor_number:=int(location.get("floor",2))
	var at:Array=location.get("player",[])
	# Persisted actor coordinates still have to fit the current source collision map.
	if at.size()==2:
		if not load_floor(floor_number,Vector2(float(at[0]),float(at[1]))+Body.FOOT_CENTER_OFFSET):load_floor(floor_number)
	else:load_floor(floor_number)
	set_hour(float(location.get("hour",12)))
func _commit_room(id:String,model:Object)->void:
	if _restoring or _suspending:return
	var state:=_save_state()
	if state!=null and state.has_method("commit_flc_room"):state.commit_flc_room(id,model)
func checkpoint_state()->bool:
	if _restoring:return false
	var state:=_save_state()
	if state==null or not state.has_method("commit_flc_snapshot") or data.is_empty():return false
	return state.commit_flc_snapshot(_room_models(),{"floor":int(data.floor),"player":[player.x,player.y],"hour":lighting.hour})
func _completion_signature()->String:
	var rows:Array=[]
	for id:String in _room_models():
		var model:Object=_room_models()[id]
		for prop:Dictionary in model.get_property_list():
			if str(prop.name) in ["complete","completed","earned","transfer","extension_completed","advanced_earned"]:
				rows.append([id,prop.name,model.get(prop.name)])
	return str(rows)
func suspend_activity()->void:
	if _suspending:return
	_suspending=true
	_clear_npc_interaction()
	route.clear();touch_vector=Vector2.ZERO;touched_buttons.clear()
	puzzle_pending="";workbench_pending=false;signal_sync_pending=false;motion_pending="";pantry_pending=false
	if is_instance_valid(joystick):joystick.cancel()
	if is_instance_valid(active_puzzle):active_puzzle.close()
	for view:Control in [workbench,signal_sync,motion_lab,pantry_tray]:
		if is_instance_valid(view) and view.visible:view.close()
	if is_instance_valid(stairs):stairs.model.cancel();stairs.hide()
	stair_destination.clear()
	if is_instance_valid(transit_panel):transit_panel.hide()
	_suspending=false
	checkpoint_state()
func _exit_tree()->void:
	if persistence_enabled:suspend_activity()

func _has_open_station()->bool:
	for view in [active_puzzle,workbench,signal_sync,motion_lab,pantry_tray,stairs]:
		if is_instance_valid(view) and view.visible:return true
	return false
