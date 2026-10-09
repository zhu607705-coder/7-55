extends Control
const CompactOverlay = preload("res://scripts/ui/compact_overlay_layout.gd")
const MobileFloorRoute = preload("res://scripts/mobile_floor_route.gd")
const CanteenFloorTap = preload("res://scripts/canteen_floor_tap.gd")
const PlayerMetrics = preload("res://scripts/player_metrics.gd")
const ObjectPicker = preload("res://scripts/world_object_picker.gd")
const KayakVisual = preload("res://scripts/ui/kayak_visual.gd")
const CampusWayfinding = preload("res://scripts/ui/campus_wayfinding.gd")
## Source-pixel exploration surface. No story facts are authored by rendering.
var worlds: Dictionary = {}
var spec: Dictionary = {}
var scene_id := ""
var world_key := ""
var background: Texture2D
var player_frames: Dictionary = {}
var player_side_idle: Texture2D
var player := Vector2.ZERO
var camera := Vector2.ZERO
var zoom := 0.85
var world_size := Vector2(960,540)
var background_rect := Rect2(0,0,960,540)
var collisions: Array = []
var targets: Array = []
var mask := PackedByteArray()
var mask_meta: Dictionary = {}
var move_target := Vector2.INF
var _floor_route: Array[Vector2]=[]
var _floor_goal := Vector2.INF
var _floor_status := ""
var _floor_feedback_left := 0.0
var _floor_bounds := Rect2()
var _floor_expected_camera := Vector2.ZERO
var _floor_view_size := Vector2.ZERO
var _floor_view_zoom := 0.0
var _floor_world_key := ""
var _floor_planner := MobileFloorRoute.new()
var _canteen_floor_tap := CanteenFloorTap.new()
var nearby: Dictionary = {}
var walk_clock := 0.0
var facing := "down"
var subtitle := ""
var subtitle_left := 0.0
var font: Font
var _last_save := 0.0
var _manual_sent := false
var _last_floor := ""
var _input_kind := "keyboard"
var touch_axis := Vector2.ZERO
var kayak: RefCounted
var kayak_texture: Texture2D
var safe_player := Vector2.ZERO
var foreground: Array = []
var target_textures: Dictionary = {}
var mode_mix := 0.0
var transition_alpha := 0.0
var pending_teleport := Vector2.INF
var player_flip := false
var guard_model: Script
var guard_state: Dictionary = {}
var guard_position := Vector2.ZERO
var guard_visible := false
var guard_sheet: Texture2D
var guard_kind := ""
var guard_grace := 0.0
var guard_navigation: RefCounted
var guard_navigation_key := ""
var guard_navigation_target := Vector2.INF
var guard_repath_ms := 0.0
var guard_clock_ms := 0.0
var guard_audio_band := ""
var guard_close_voice_played := false
var guard_floor_voice_played := false
var guard_close_requested := false
var guard_recovery_pending := false
const GuardCapture=preload("res://scripts/presentation/chapter4_guard_capture.gd")
var guard_capture:RefCounted=GuardCapture.new()
var stair_handoff:Dictionary={}
var last_zone := ""
var last_vehicle := ""
var pan_offset := Vector2.ZERO
var touch_controls := false
var mobile_exploration := false
var mobile_touch_roles: Dictionary={}
var mobile_mouse_control := false
var capture_mode := false
var host_node: Control
var touch_points: Dictionary = {}
var kayak_mouse_gesture: Dictionary = {}
var chapter4_layers: RefCounted
var room204_object: Node2D
var native_canteen: Node2D
var native_dorm: Node2D
var library_layers: RefCounted
var chapter3_layers: RefCounted
var furniture_drag_preview: Control
var _native_table_drag:=false
var presentation_actor_hidden := false
var kayak_visual: RefCounted = KayakVisual.new()
var lake_session: RefCounted
const KAYAK_BOUNDARY_HINT_COOLDOWN_MS:=2400
const KAYAK_BOUNDARY_HINT_DURATION:=2.2
var _kayak_boundary_hint_at: int=-KAYAK_BOUNDARY_HINT_COOLDOWN_MS
var object_picker: RefCounted=ObjectPicker.new()

func _ready() -> void:
	clip_contents = true
	touch_controls = DisplayServer.is_touchscreen_available()
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	worlds = JSON.parse_string(FileAccess.get_file_as_string("res://data/worlds.json")).worlds
	font = load("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf")
	for direction in ["down","up","side"]:
		var frames: Array = []
		for index in range(8):
			var path := "res://assets/rpg/player/player_%s_%d.png" % [direction,index]
			if ResourceLoader.exists(path): frames.append(load(path))
		player_frames[direction] = frames
	player_side_idle = load("res://assets/rpg/player/player_side_idle.png")
	State.world_teleport.connect(func(point: Array): pending_teleport = Vector2(float(point[0]),float(point[1])); refresh_world())
	if ResourceLoader.exists("res://scripts/games/chapter4_guard_model.gd"):
		guard_model = load("res://scripts/games/chapter4_guard_model.gd")
		guard_sheet = load("res://assets/rpg/npcs/finale/guard_walk_8frame.png")
	State.feedback.connect(_receive_feedback)
	State.story_reset.connect(func(): _kayak_boundary_hint_at=-KAYAK_BOUNDARY_HINT_COOLDOWN_MS)
	if ResourceLoader.exists("res://scripts/ui/chapter4_world_layers.gd"):
		chapter4_layers = load("res://scripts/ui/chapter4_world_layers.gd").new()
	if ResourceLoader.exists("res://scripts/ui/chapter3_world_layers.gd"):
		chapter3_layers=load("res://scripts/ui/chapter3_world_layers.gd").new()
	if ResourceLoader.exists("res://scripts/ui/library_world_layers.gd"):
		library_layers=load("res://scripts/ui/library_world_layers.gd").new()
	room204_object=load("res://scripts/objects/room204_table_adapter.gd").new()
	room204_object.name="Room204OriginalTable"
	add_child(room204_object)
	room204_object.setup(self)
	chapter4_layers.native_prop=room204_object
	native_canteen=load("res://scripts/objects/canteen_object_scene.gd").new();add_child(native_canteen);native_canteen.setup(self)
	native_dorm=load("res://scripts/objects/dorm_scene_adapter.gd").new();add_child(native_dorm);native_dorm.setup(self)
	refresh_world()

func refresh_world() -> void:
	if worlds.is_empty() or State.d.is_empty(): return
	if guard_capture.active and not guard_capture.matches(_guard_capture_context()): _cancel_guard_capture()
	if not stair_handoff.is_empty() and (State.d.native.scene!="duan_yongping_temporal_maze" or State.d.chapter4.phase!="final_chase" or State.d.chapter4.floor!="A2" or int(stair_handoff.attempt)!=int(State.d.chapter4.chaseAttempt)):stair_handoff.clear()
	var incoming := str(State.d.native.scene)
	if is_instance_valid(native_dorm):native_dorm.sync(State.d,incoming)
	if is_instance_valid(native_canteen):native_canteen.sync(State.d,incoming)
	if incoming!=scene_id: _kayak_boundary_hint_at=-KAYAK_BOUNDARY_HINT_COOLDOWN_MS
	if library_layers!=null: library_layers.sync(State.d,incoming!=scene_id)
	if chapter3_layers!=null: chapter3_layers.sync(State.d,incoming!=scene_id)
	if incoming.is_empty(): return
	var floor_id := str(State.d.get("chapterFour",{}).get("floor",State.d.get("chapter4",{}).get("floor","A1")))
	var zone := str(State.d.get("qizhenLake",{}).get("currentZone",State.d.get("qizhenLake",{}).get("zone","dock")))
	var time_id := str(State.d.chapter4.timeState)
	var vehicle_id := str(State.d.qizhenLake.vehicle)
	var phase_id := str(State.d.chapter4.phase)
	var preserve_position := incoming == scene_id and floor_id == _last_floor and zone == last_zone and vehicle_id == last_vehicle
	var prior_position := player
	var key := incoming + ":" + (floor_id+":"+time_id+":"+phase_id if incoming == "duan_yongping_temporal_maze" else zone+":"+vehicle_id if incoming == "qizhen_lake" else "")
	targets = State.get_targets(incoming)
	if key == world_key and pending_teleport == Vector2.INF:
		queue_redraw()
		return
	_cancel_table_drag()
	object_picker.clear()
	_cancel_floor_route()
	kayak_mouse_gesture.clear()
	world_key = key
	pan_offset = Vector2.ZERO
	scene_id = incoming
	_last_floor = floor_id
	last_zone = zone
	last_vehicle = vehicle_id
	spec = worlds.get(scene_id,{})
	if spec.is_empty(): return
	world_size = Vector2(float(spec.worldSize.width),float(spec.worldSize.height))
	background_rect = Rect2(Vector2.ZERO,world_size)
	collisions = spec.get("collisions",[]).duplicate(true)
	if chapter3_layers!=null: collisions=chapter3_layers.adjusted_collisions(collisions,State.d)
	foreground = []
	kayak = null
	for constant_name in spec.get("constants",{}):
		if "OCCLUSION" in str(constant_name) or "FOREGROUND" in str(constant_name):
			var occluders = spec.constants[constant_name]
			if occluders is Array: foreground.append_array(occluders)
			elif occluders is Dictionary: foreground.append(occluders)
	mask = PackedByteArray()
	var image_path := str(spec.get("background",""))
	var spawns: Dictionary = spec.get("spawns",{})
	var checkpoint := str(State.d.get("rpgCheckpoint",""))
	var spawn: Dictionary = spawns.get(checkpoint,{})
	var explicit_lake_entry := false
	if spawn.is_empty():
		for item in spawns.values():
			if item is Dictionary and item.has("x") and item.has("y"):
				if float(item.x) < world_size.x and float(item.y) < world_size.y:
					spawn = item
					break
	if spec.has("manifest"):
		var manifest: Dictionary = spec.manifest
		spawn = manifest.get("spawn",{})
		if checkpoint == "campus_library_gate": spawn = manifest.get("libraryGate",spawn)
		elif checkpoint == "campus_canteen_gate": spawn = manifest.get("canteen",{}).get("approach",spawn)
		elif checkpoint == "campus_theater_junction": spawn = manifest.get("theater",{}).get("approach",spawn)
		elif checkpoint == "campus_qizhen_gate": spawn = manifest.get("qizhen",{}).get("approach",spawn)
		elif checkpoint == "campus_qizhen_transition_stop": spawn = manifest.get("qizhen",{}).get("approachTransition",{}).get("stop",spawn)
		mask_meta = manifest.get("walkability",{})
		if mask_meta.has("bitsBase64"): mask = Marshalls.base64_to_raw(mask_meta.bitsBase64)
		zoom = 1.1 if scene_id == "campus_bootstrap" else 0.9
	elif scene_id == "dorm_hub":
		background_rect = Rect2(245,0,470.5,836)
		zoom = 1.15
		if State.d.actOne.phase == "inventory_required": spawn = {"x":570,"y":460}
	elif scene_id == "qizhen_lake":
		var zone_spec: Dictionary = spec.zones.get(zone,spec.zones.dock)
		image_path = spec.backgrounds.get(zone,spec.backgrounds.dock)
		var vehicle := str(State.d.get("qizhenLake",{}).get("vehicle","on_foot"))
		collisions = zone_spec.get("kayakCollisions",[]) if vehicle == "kayak" else zone_spec.get("onFootCollisions",[])
		spawn = zone_spec.get("kayakSpawn",{}) if vehicle == "kayak" else zone_spec.get("onFootSpawn",{})
		var owner: RefCounted=State.lake_module()
		var entry: Dictionary=owner.take_entry_spawn(State.d) if owner!=null else {}
		if not entry.is_empty(): spawn=entry; explicit_lake_entry=true
		zoom = 0.8
	elif scene_id == "duan_yongping_temporal_maze":
		var floor_spec: Dictionary = spec.layout.floors[0]
		for candidate in spec.layout.floors:
			if str(candidate.storyFloor) == floor_id: floor_spec = candidate
		collisions = floor_spec.staticCollisions.duplicate(true)
		foreground = floor_spec.foregroundOcclusions.duplicate(true)
		spawn = floor_spec.safeSpawn
		image_path = "src/assets/rpg/interiors/finale/chapter4-755/base/"+floor_id.to_lower()+".png"
		var plate_id := floor_id.to_lower()+"_"+time_id
		if floor_id == "A2" and time_id == "0754_blackout": plate_id = "a2_202_final_minute" if phase_id == "final_minute_recovery" else "a2_0754_chase"
		if floor_id == "A3" and time_id == "1850_evening": plate_id = "a3_1850_reference"
		var state_path := "src/assets/rpg/interiors/finale/chapter4-755/states/"+plate_id+".png"
		if ResourceLoader.exists(State.asset(state_path)): image_path = state_path
		for delta in spec.layout.physicalDeltas:
			if delta.storyFloor == floor_id and plate_id in delta.get("statePlateIds",[]) and delta.activation == "plate_active":
				collisions.append_array(delta.get("collisionBounds",[]))
				foreground.append_array(delta.get("occlusionBounds",[]))
		for gate in spec.layout.dynamicGates:
			if gate.storyFloor == floor_id and phase_id in gate.get("activePhases",[]) and gate.get("collision",false): collisions.append(gate.bounds)
		if phase_id == "final_chase" and floor_id == "A1" and not preserve_position: spawn = spec.layout.finalChaseRuntime.playerStart
		zoom = 0.85
	else: zoom = 0.85
	if not image_path.is_empty() and ResourceLoader.exists(State.asset(image_path)): background = load(State.asset(image_path))
	else: background = null
	player = Vector2(float(spawn.get("x",world_size.x/2)),float(spawn.get("y",world_size.y*.8)))
	var stored: Dictionary = State.d.native.get("positions",{}).get(world_key,{})
	if not stored.is_empty() and not explicit_lake_entry: player = Vector2(float(stored.x),float(stored.y))
	if preserve_position and not explicit_lake_entry: player = prior_position
	if pending_teleport != Vector2.INF:
		player = pending_teleport
		pending_teleport = Vector2.INF
	if scene_id == "qizhen_lake" and vehicle_id == "kayak" and ResourceLoader.exists("res://scripts/games/kayak_model.gd"):
		kayak = load("res://scripts/games/kayak_model.gd").new()
		kayak.configure({"phase":"world","bounded":false})
		# Entry headings can differ from the zone's default checkpoint heading.
		# Validate the same rotated full hull that the live session will use.
		kayak.heading = float(spawn.get("heading",-PI/2))
		kayak_texture = load("res://assets/rpg/qizhen/kayak_overhead_frame_a.png")
	if not can_stand(player): player = _find_safe(player)
	transition_alpha = 1.0
	safe_player = player
	if kayak!=null: kayak.position = player
	lake_session=State.lake_module().bind_world(State.d,self) if State.lake_module()!=null else null
	move_target = Vector2.INF
	_manual_sent = bool(State.d.actOne.get("manualControlTested",false))
	_sync_player()
	_update_camera()
	queue_redraw()

func _rect(value: Dictionary) -> Rect2:
	if value.has("left"):
		return Rect2(float(value.left),float(value.top),float(value.right)-float(value.left),float(value.bottom)-float(value.top))
	return Rect2(float(value.get("x",0)),float(value.get("y",0)),float(value.get("width",0)),float(value.get("height",0)))

func display_scale_at(point: Vector2) -> float:
	return PlayerMetrics.scale_at(scene_id,point.y,spec.get("manifest",{}).get("perspective",{}))

func kayak_collision_rect(point: Vector2, heading: float) -> Rect2:
	var dimensions := Vector2(83*absf(cos(heading))+67*absf(sin(heading)),83*absf(sin(heading))+67*absf(cos(heading)))
	return Rect2(point-dimensions/2,dimensions)

func can_stand(point: Vector2, kayak_heading: float=NAN) -> bool:
	var boating := scene_id == "qizhen_lake" and str(State.d.qizhenLake.vehicle) == "kayak"
	var heading: float = float(kayak.heading) if kayak else float(spec.get("zones",{}).get(str(State.d.qizhenLake.zone),{}).get("kayakSpawn",{}).get("heading",-PI/2))
	if boating and is_finite(kayak_heading): heading=kayak_heading
	var boat: Rect2 = kayak_collision_rect(point,heading)
	var visual: Rect2 = boat if boating else PlayerMetrics.visual_rect(point,display_scale_at(point))
	if visual.position.x < 0 or visual.position.y < 0 or visual.end.x > world_size.x or visual.end.y > world_size.y: return false
	var feet: Rect2 = boat if boating else PlayerMetrics.foot_rect(point)
	if is_instance_valid(native_canteen) and native_canteen.is_active():return not native_canteen.blocks_feet(feet)
	if boating:
		var contained := false
		for area: Dictionary in spec.zones[str(State.d.qizhenLake.zone)].waterAreas:
			if point.x>=float(area.left) and point.x<=float(area.right) and point.y>=float(area.top) and point.y<=float(area.bottom): contained=true; break
		if not contained: return false
	for obstacle in collisions:
		if obstacle is Dictionary:
			var shape: Dictionary=library_layers.replace_collision(obstacle) if scene_id=="library_interior" and library_layers!=null else obstacle
			if feet.intersects(_rect(shape)): return false
	if scene_id == "duan_yongping_temporal_maze" and chapter4_layers != null:
		for obstacle: Rect2 in chapter4_layers.collisions(State.d):
			if feet.intersects(obstacle): return false
	if not mask.is_empty():
		var middle := feet.get_center()
		for test in [middle,feet.position,feet.position+Vector2(feet.size.x,0),feet.position+Vector2(0,feet.size.y),feet.end]:
			var x := int(floor(test.x/float(mask_meta.cellSize)))
			var y := int(floor(test.y/float(mask_meta.cellSize)))
			if x < 0 or y < 0 or x >= int(mask_meta.gridWidth) or y >= int(mask_meta.gridHeight): return false
			var bit := y*int(mask_meta.gridWidth)+x
			if bit/8 >= mask.size() or (mask[bit/8] & (1 << (bit%8))) == 0: return false
	return true

func resolve_kayak_rotation(previous_heading: float) -> bool:
	# Phaser separates the enlarged Arcade body after a paddle yaw. Keep the
	# authored hull and blockers; only resolve the contact caused by that yaw.
	if kayak==null or not player.is_finite() or player.distance_to(kayak.position)>0.01: return false
	if not can_stand(player,previous_heading): return false
	if can_stand(player): return true
	var before: Rect2=kayak_collision_rect(player,previous_heading)
	var after: Rect2=kayak_collision_rect(player,kayak.heading)
	var growth: Vector2=((after.size-before.size)*0.5).max(Vector2.ZERO)
	var xs: Array[float]=[0.0]
	var ys: Array[float]=[0.0]
	var obstacles: Array[Rect2]=[]
	for obstacle: Dictionary in collisions: obstacles.append(_rect(obstacle))
	# A rotated hull must also remain inside the unchanged source rectangle.
	obstacles.append(Rect2(-1000,-1000,1000,world_size.y+2000))
	obstacles.append(Rect2(world_size.x,-1000,1000,world_size.y+2000))
	obstacles.append(Rect2(-1000,-1000,world_size.x+2000,1000))
	obstacles.append(Rect2(-1000,world_size.y,world_size.x+2000,1000))
	for obstacle: Rect2 in obstacles:
		for offset: float in [obstacle.position.x-after.end.x-0.001,obstacle.end.x-after.position.x+0.001]:
			if absf(offset)<=growth.x+0.002 and not xs.has(offset): xs.append(offset)
		for offset: float in [obstacle.position.y-after.end.y-0.001,obstacle.end.y-after.position.y+0.001]:
			if absf(offset)<=growth.y+0.002 and not ys.has(offset): ys.append(offset)
	var correction:=Vector2.INF
	for x: float in xs:
		for y: float in ys:
			var candidate:=Vector2(x,y)
			if candidate.length_squared()<correction.length_squared() and can_stand(player+candidate): correction=candidate
	if not correction.is_finite(): return false
	player+=correction
	kayak.position=player
	_sync_player()
	return true

func _find_safe(origin: Vector2) -> Vector2:
	if can_stand(origin): return origin
	for radius in range(8,320,8):
		for angle in range(0,360,15):
			var point := origin+Vector2.from_angle(deg_to_rad(float(angle)))*radius
			if can_stand(point): return point
	return origin

func _target_point(target: Dictionary) -> Vector2:
	if target.get("follow_player",false): return player
	var value = target.get("position",[target.get("x",0),target.get("y",0)])
	var point := Vector2(float(value[0]),float(value[1])) if value is Array else Vector2(float(value.x),float(value.y))
	if scene_id == "dorm_hub": point = point*.5+Vector2(245,0)
	return point

func _distance(target: Dictionary) -> float:
	if target.get("follow_player",false): return 0.0
	var point := PlayerMetrics.foot_rect(player).get_center() if scene_id=="duan_yongping_temporal_maze" else player
	if target.has("bounds"):
		var b = target.bounds
		var rect: Rect2
		if b is Array: rect = Rect2(float(b[0]),float(b[1]),float(b[2]),float(b[3]))
		else: rect = _rect(b)
		if scene_id == "dorm_hub": rect = Rect2(rect.position*.5+Vector2(245,0),rect.size*.5)
		return point.distance_to(point.clamp(rect.position,rect.end))
	return point.distance_to(_target_point(target))

func _scene_presentation_blocks() -> bool:
	if guard_capture.active:return true
	if scene_id=="library_interior" and library_layers!=null and library_layers.blocks_movement(): return true
	if is_instance_valid(host_node) and is_instance_valid(host_node.get("c3_narrative_host")) and host_node.c3_narrative_host.blocks_movement(): return true
	if is_instance_valid(host_node) and is_instance_valid(host_node.get("library_story_host")) and host_node.library_story_host.blocks_input(): return true
	return is_instance_valid(host_node) and is_instance_valid(host_node.get("c3_scene_host")) and host_node.c3_scene_host.blocks_world_input()

func _interaction_presentation_blocks() -> bool:
	if _scene_presentation_blocks(): return true
	return is_instance_valid(host_node) and is_instance_valid(host_node.get("c3_narrative_host")) and host_node.c3_narrative_host.blocks_input()

func _try_interact(target: Dictionary = {}) -> void:
	if presentation_actor_hidden or _interaction_presentation_blocks() or _shell_input_blocked(): return
	if target.is_empty(): target = nearby
	if target.is_empty():
		subtitle = "靠近可交互的物品后点交互。" if mobile_exploration else "靠近可交互的物品后按空格。"; subtitle_left = 2.4; return
	if scene_id=="library_interior" and library_layers!=null and library_layers.backpack_eviction_active() and str(target.get("action","")) in ["lib_sit","lib_dialogue_open"]: return
	var distance := _distance(target)
	var limit := float(target.get("radius",100)) * (.5 if scene_id == "dorm_hub" else 1.0)
	if distance > limit:
		State.feedback.emit("太远了，请靠近"+str(target.get("label","目标"))+"。"); return
	var required_mode := str(target.get("mode",""))
	if not required_mode.is_empty() and required_mode != str(State.d.native.mode):
		State.feedback.emit("当前是%s，这个操作需要%s。" % ["深色观察" if State.d.native.mode == "dark" else "浅色操作","深色观察" if required_mode == "dark" else "浅色操作"]); return
	var required_item := str(target.get("item",""))
	if not required_item.is_empty() and str(State.d.native.selected_item) != required_item:
		State.feedback.emit("请先从物品栏选择对应物品。"); return
	_sync_player()
	if target.get("action","")=="c4_reach202":
		guard_close_requested=true
		return
	State.act(str(target.get("action",target.get("id",""))),target.get("value"))

func _sync_player() -> void:
	var source := (player-Vector2(245,0))*2.0 if scene_id == "dorm_hub" else player
	State.d.native.player = {"x":source.x,"y":source.y,"scene":scene_id,"world_x":player.x,"world_y":player.y}
	if not State.d.native.has("positions"): State.d.native.positions = {}
	State.d.native.positions[world_key] = {"x":player.x,"y":player.y}

func _show_kayak_boundary_feedback(at_ms: int=-1) -> bool:
	if scene_id!="qizhen_lake" or kayak==null: return false
	var now: int=Time.get_ticks_msec() if at_ms<0 else at_ms
	if now-_kayak_boundary_hint_at<KAYAK_BOUNDARY_HINT_COOLDOWN_MS: return false
	_kayak_boundary_hint_at=now
	var content: Dictionary=State.content("chapter3-qizhen-lake.content.json")
	State.feedback.emit(str(content.boarding.boundaryBlocked))
	subtitle_left=KAYAK_BOUNDARY_HINT_DURATION
	return true

func _receive_feedback(text: String) -> void:
	subtitle=text
	subtitle_left=clampf(1.6+text.length()*.12,2.4,6.5)
	if scene_id!="qizhen_lake" or str(State.last_result.get("message",""))!=text: return
	# Original triggerSwanCatch shows these two sentences for3000ms. The
	# generic text-length lifetime otherwise outlasts the restarted attempt.
	for cue: Dictionary in State.last_result.get("presentation",[]):
		if str(cue.get("cueId",""))=="qizhen_chase_failed" and str(cue.get("payload",{}).get("reason",""))=="swan_caught":
			subtitle_left=3.0
			return

func _process(delta: float) -> void:
	# Keep the existing simulation cap below. The source capture uses a scene
	# timer, so its presentation clock follows active elapsed time independently.
	var capture_delta_ms:=maxf(0,delta)*1000
	if guard_capture.active and not guard_capture.matches(_guard_capture_context()):
		_cancel_guard_capture()
		return
	delta=minf(delta,.05)
	if not kayak_mouse_gesture.is_empty() and not _kayak_mouse_valid(): kayak_mouse_gesture.clear()
	if _floor_feedback_left>0:
		_floor_feedback_left=maxf(0,_floor_feedback_left-delta)
		if _floor_feedback_left==0 and _floor_route.is_empty(): _floor_goal=Vector2.INF; _floor_status=""
	if not _floor_route.is_empty() and (not mobile_exploration or capture_mode or presentation_actor_hidden or not is_visible_in_tree() or get_viewport().gui_is_dragging() or get_tree().root.gui_is_dragging() or not _floor_transform_current()): _cancel_floor_route()
	if not is_visible_in_tree() or scene_id.is_empty() or capture_mode: return
	if is_instance_valid(host_node) and not host_node.world_frame.is_visible_in_tree(): _cancel_floor_route(); return
	if chapter3_layers!=null:
		chapter3_layers.narrative_session=host_node.c3_narrative_host.current if is_instance_valid(host_node) and is_instance_valid(host_node.c3_narrative_host) else null
		chapter3_layers.tick(delta,State.d)
		if is_instance_valid(native_canteen) and native_canteen.is_active():native_canteen.sync(State.d,scene_id)
		if scene_id in ["canteen_interior","theater_interior"]: collisions=chapter3_layers.adjusted_collisions(collisions,State.d)
	if library_layers!=null:
		library_layers.tick(delta,State.d)
		for event: Dictionary in library_layers.take_cues():
			if is_instance_valid(host_node): host_node._library_world_presentation(str(event.id),event.get("payload",{}),library_layers)
		# The terminal cue can hand the visible surface to its earned reader.
		# Do not apply a held movement key after that handoff in this same tick.
		if is_instance_valid(host_node) and not host_node.world_frame.is_visible_in_tree(): return
	if chapter4_layers != null and scene_id == "duan_yongping_temporal_maze":
		chapter4_layers.tick(delta,State.d)
		queue_redraw()
	mode_mix = move_toward(mode_mix,1.0 if State.d.native.mode == "dark" else 0.0,delta*4.5)
	transition_alpha = maxf(0,transition_alpha-delta*2.0)
	if subtitle_left > 0:
		subtitle_left -= delta
		if subtitle_left <= 0: subtitle = ""
	queue_redraw()
	# Pause physical actors, while keeping the existing scene fades and visual
	# animation alive, as source physics.pause() does.
	if guard_capture.active:
		_tick_guard_capture(capture_delta_ms)
		return
	if _scene_presentation_blocks():
		if mobile_exploration: cancel_exploration_gestures()
		return
	var shell = host_node
	if _shell_input_blocked():
		if mobile_exploration: cancel_exploration_gestures()
		return
	if is_instance_valid(shell) and is_instance_valid(shell.get("world_effect")) and shell.world_effect.get_meta("blocks_input",false): _cancel_floor_route(); return
	var focus := host_node.get_viewport().gui_get_focus_owner() if is_instance_valid(host_node) else get_viewport().gui_get_focus_owner()
	var axis := Vector2.ZERO
	if focus is LineEdit or focus is TextEdit: _cancel_floor_route()
	if not (focus is LineEdit or focus is TextEdit):
		axis = Vector2(float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT))-float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)),float(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN))-float(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)))
	if touch_axis.length_squared() > 0:
		_cancel_floor_route()
		axis = touch_axis
		_input_kind = "touch"
		move_target = Vector2.INF
	elif axis.length_squared() > 0:
		_cancel_floor_route()
		_input_kind = "keyboard"
		move_target = Vector2.INF
	elif not _floor_route.is_empty():
		axis=_floor_route[0]-player
		_input_kind="touch"
	elif move_target != Vector2.INF:
		axis = move_target-player
		_input_kind = "touch"
		if axis.length() < 6: move_target = Vector2.INF; axis = Vector2.ZERO
	if kayak:
		axis = Vector2.ZERO
		move_target = Vector2.INF
		var previous := player
		if lake_session==null or lake_session.status!="recovering":
			kayak.update(delta)
			if can_stand(kayak.position): player = kayak.position
			else:
				kayak.position = previous; kayak.speed = 0
				_show_kayak_boundary_feedback()
		_sync_player()
		State.lake_world_tick(self,delta)
		lake_session=State.lake_module().live_session if State.lake_module()!=null else null
		if State.d.native.scene!=scene_id or str(State.d.qizhenLake.zone)!=last_zone:
			refresh_world(); return
		_sync_player()
	if scene_id == "dorm_hub" and not State.d.actOne.get("controlsInstalled",false):
		move_target = Vector2.INF
		axis = Vector2.ZERO
		if State.d.actOne.get("exerciseStarted",false):
			var pace_x := 245 + (520 + sin(Time.get_ticks_msec()/900.0)*130)*.5
			var pace_position := Vector2(pace_x,player.y)
			if can_stand(pace_position): player = pace_position; walk_clock += delta; facing = "side"; _sync_player()
	# A zero-length route waypoint still needs its normal completion step.
	if axis.length_squared() > 0 or not _floor_route.is_empty():
		if mobile_exploration and _floor_route.is_empty(): pan_offset=Vector2.ZERO
		axis = axis.normalized()
		var speed := 208.0 if scene_id == "duan_yongping_temporal_maze" and State.d.chapter4.phase == "final_chase" else 176.0 if scene_id == "duan_yongping_temporal_maze" else 160.0 if scene_id == "dorm_hub" else 165.0
		if scene_id in ["canteen_interior","theater_interior","qizhen_lake"] and Input.is_key_pressed(KEY_SHIFT): speed = 228.0
		var displacement := axis*speed*delta
		var old := player
		if not _floor_route.is_empty():
			var next: Vector2=player.move_toward(_floor_route[0],speed*delta)
			if _floor_segment_clear(player,next):
				player=next
				# move_toward returns the exact target when this frame reaches it.
				# Relative approximate equality can retire large-coordinate goals early.
				if player==_floor_route[0]:
					_floor_route.pop_front()
					if _floor_route.is_empty(): _floor_status="arrived"; _floor_feedback_left=.45
			else: _stop_floor_route()
		else:
			if scene_id=="duan_yongping_temporal_maze":
				player=_c4_axis_destination(player,Vector2(displacement.x,0))
				player=_c4_axis_destination(player,Vector2(0,displacement.y))
			else:
				if can_stand(player+Vector2(displacement.x,0)): player.x += displacement.x
				if can_stand(player+Vector2(0,displacement.y)): player.y += displacement.y
		if old.distance_to(player) > 0:
			walk_clock += delta
			player_flip = axis.x < 0
			facing = "side" if absf(axis.x) > absf(axis.y) else "up" if axis.y < 0 else "down"
			_sync_player()
			if scene_id == "dorm_hub" and State.d.actOne.get("movementEnabled",false) and not _manual_sent:
				_manual_sent = true
				State.act("c2_manual_input",{"moved":true,"distance":old.distance_to(player)*2,"input":_input_kind})
	else: walk_clock = 0.0
	nearby = {}
	var nearest := INF
	for target in targets:
		if target.get("decorative",false): continue
		var distance := _distance(target)
		# The always-near self-inspection target is a fallback, not a permanent
		# Space-key occluder over the desk, cabinet and earned dorm exit.
		var rank := distance+(1000000.0 if scene_id=="dorm_hub" and target.get("follow_player",false) else 0.0)
		if rank < nearest and distance <= float(target.get("radius",100))*(.5 if scene_id == "dorm_hub" else 1.0):
			nearest = rank
			nearby = target
	_update_guard(delta)
	_update_camera()
	_floor_expected_camera=camera
	_last_save += delta
	if _last_save > 3.0:
		_last_save = 0
		State.save_game()
	queue_redraw()

func _c4_axis_destination(start:Vector2,motion:Vector2) -> Vector2:
	if not start.is_finite() or not motion.is_finite() or motion.is_zero_approx():return start
	if not is_zero_approx(motion.x) and not is_zero_approx(motion.y):return start
	var end:Vector2=start+motion
	# Preserve the existing way out when a moving source NPC overlaps the start.
	# This does not relocate the actor unless its requested endpoint is legal.
	if not can_stand(start):return end if can_stand(end) else start
	var current:Vector2=start
	# The original Arcade body separates to contact. Rejecting the whole final
	# frame leaves an arbitrary gap, enough to block the source bakery aisle.
	# Small substeps retain full-foot collision checks, including thin blockers.
	var steps:int=maxi(1,int(ceil(motion.length()/4.0)))
	for index:int in range(steps):
		var next:Vector2=start+motion*(float(index+1)/steps)
		if can_stand(next):
			current=next
			continue
		var blocked:Vector2=next
		for iteration:int in range(12):
			var middle:Vector2=(current+blocked)*0.5
			if can_stand(middle):current=middle
			else:blocked=middle
		return current
	return current

func _update_camera() -> void:
	var half := size/(2*zoom)
	camera = Vector2(clampf(player.x+pan_offset.x,half.x,maxf(half.x,world_size.x-half.x)),clampf(player.y+pan_offset.y,half.y,maxf(half.y,world_size.y-half.y)))
	if world_size.x < half.x*2: camera.x = world_size.x/2
	if world_size.y < half.y*2: camera.y = world_size.y/2

func register_object_surface(ids: Array, geometry: Dictionary) -> void:
	object_picker.add(ids,geometry)

func register_object_bounds(ids: Array, bounds: Rect2) -> void:
	register_object_surface(ids,{"rect":bounds})

func _ordered_targets() -> Array:
	var ordered: Array=targets.duplicate()
	# Coincident lake observation/operation surfaces share one physical object.
	# Paint the existing mode-owned priority last, so visible order and input agree.
	if scene_id=="qizhen_lake":
		ordered.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return int(a.get("interaction_priority",0))<int(b.get("interaction_priority",0)) if int(a.get("interaction_priority",0))!=int(b.get("interaction_priority",0)) else targets.find(a)<targets.find(b))
	return ordered

func _record_plate_targets() -> void:
	# Baked plate regions have no independent CanvasItem z order. Retain the
	# existing click precedence where their authored regions overlap; do not
	# invent depth or promote a target because an inventory item fits it.
	var plate_targets: Array=targets.duplicate()
	plate_targets.reverse()
	for target: Dictionary in plate_targets:
		if target.has("art") or target.get("follow_player",false): continue
		if is_instance_valid(native_canteen) and native_canteen.owns_target(str(target.get("id",""))):continue
		if library_layers!=null and scene_id=="library_interior" and library_layers.owns_pick_target(str(target.get("id",""))): continue
		if chapter3_layers!=null and chapter3_layers.owns_pick_target(target,State.d): continue
		if chapter4_layers!=null and scene_id=="duan_yongping_temporal_maze" and chapter4_layers.owns_pick_target(str(target.get("id",""))): continue
		var geometry: Dictionary
		if target.has("bounds"):
			var b=target.bounds
			var rect: Rect2=Rect2(b[0],b[1],b[2],b[3]) if b is Array else _rect(b)
			if scene_id=="dorm_hub": rect=Rect2(rect.position*.5+Vector2(245,0),rect.size*.5)
			geometry={"rect":rect}
		else:
			# Unmeasured route anchors retain the existing 32px point affordance.
			geometry={"center":_target_point(target),"radius":32.0}
		object_picker.add([str(target.get("id",""))],geometry,false)

func _pick_target(point: Vector2, inventory_drop: bool=false) -> Dictionary:
	if mobile_exploration:
		var hud:=hud_metrics(_hud_line())
		var local:Vector2=(point-camera)*zoom+size/2
		var visible_local:=Rect2(0,hud.header_height,size.x,size.y-hud.header_height-hud.body_height-hud.body_gap)
		var controls:=mobile_control_metrics()
		if not visible_local.has_point(local) or (not kayak and (controls.stick_rect.has_point(local) or controls.interact.has_point(local))): return {}
		var visible_source:=Rect2(camera+(visible_local.position-size/2)/zoom,visible_local.size/zoom)
		var covered:Array=[]
		if not kayak:
			for rect:Rect2 in [controls.stick_rect,controls.interact]: covered.append(Rect2(camera+(rect.position-size/2)/zoom,rect.size/zoom))
		return object_picker.pick_near_visible(point,targets,inventory_drop,14.0/zoom,visible_source,covered)
	return object_picker.pick(point,targets,inventory_drop)

func _render_context() -> Dictionary:
	return {"origin":size/2-camera*zoom,"zoom":zoom,"player":player,"scene_id":scene_id,"floor":_last_floor,"nearby_id":str(nearby.get("id",""))}
func _draw() -> void:
	if is_instance_valid(native_dorm):
		native_dorm.sync(State.d,scene_id)
		native_dorm.configure_view(size/2-camera*zoom,zoom)
	# Retire every existing adapter before a scene-specific early return.
	if is_instance_valid(room204_object):room204_object.sync(State.d,scene_id)
	if is_instance_valid(native_canteen):native_canteen.sync(State.d,scene_id)
	if is_instance_valid(native_canteen) and native_canteen.is_active():
		draw_rect(Rect2(Vector2.ZERO,size),Color("0c1b24"))
		native_canteen.configure_view(size/2-camera*zoom,zoom,player)
		return
	if is_instance_valid(room204_object):
		if room204_object.has_objects():
			room204_object.configure_view(size/2-camera*zoom,zoom)
			return
	object_picker.clear()
	_record_plate_targets()
	var context:=_render_context()
	_draw_base_pass(self,context)
	if scene_id.is_empty(): return
	if chapter4_layers!=null: chapter4_layers.draw_back(self,context,State.d)
	_draw_actor_pass(self,context)
	if chapter4_layers!=null: chapter4_layers.draw_front(self,context,State.d)
	_draw_tail_pass(self,context)
func draw_room204_object_pass(canvas: CanvasItem,before: bool) -> void:
	if not is_instance_valid(room204_object) or not room204_object.has_objects(): return
	var context:=_render_context()
	var front: bool=room204_object.front_of_player(player)
	if before:
		object_picker.clear()
		_record_plate_targets()
		_draw_base_pass(canvas,context)
		if front:
			chapter4_layers.draw_back(canvas,context,State.d)
			_draw_actor_pass(canvas,context)
		chapter4_layers.draw_before_furniture(canvas,context,State.d,front)
		chapter4_layers._draw_furniture(canvas,context,State.d,front,1)
	else:
		chapter4_layers._draw_furniture(canvas,context,State.d,front,2)
		chapter4_layers.draw_after_furniture(canvas,context,State.d,front)
		if not front:
			_draw_actor_pass(canvas,context)
			chapter4_layers.draw_front(canvas,context,State.d)
		_draw_tail_pass(canvas,context)
func _draw_base_pass(canvas: CanvasItem,layer_context: Dictionary) -> void:
	var origin: Vector2=layer_context.origin
	canvas.draw_rect(Rect2(Vector2.ZERO,size),Color("0c1b24"))
	if scene_id.is_empty(): return
	if background: canvas.draw_texture_rect(background,Rect2(origin+background_rect.position*zoom,background_rect.size*zoom),false)
	canvas.draw_rect(Rect2(Vector2.ZERO,size),Color(.03,.15,.26,mode_mix*.3))
	_draw_floor_route(origin,canvas)
	if chapter3_layers!=null: chapter3_layers.draw_back(canvas,layer_context,State.d)
	if library_layers!=null: library_layers.draw_back(canvas,layer_context,State.d)
func _draw_actor_pass(canvas: CanvasItem,layer_context: Dictionary) -> void:
	var origin: Vector2=layer_context.origin
	var frame_set: Array = player_frames.get(facing,[])
	var ordered_targets: Array=_ordered_targets()
	for target in ordered_targets:
		if _target_point(target).y <= player.y: _draw_target(target,origin,canvas)
	if not presentation_actor_hidden and kayak and kayak_texture:
		var presentation: Dictionary=lake_session.actor_presentation() if lake_session!=null else {"offset":Vector2.ZERO,"scale":1.0,"alpha":1.0}
		kayak_visual.draw(canvas,origin+(player+presentation.offset)*zoom,zoom*float(presentation.scale),{"heading":kayak.heading,"roll":kayak.roll,"speed":kayak.speed,"side":kayak.last_side,"strokeAgeMs":(kayak.elapsed-kayak.last_stroke)*1000,"alpha":presentation.alpha},Time.get_ticks_msec())
	elif not presentation_actor_hidden and not frame_set.is_empty():
		var frame: Texture2D = player_side_idle if facing == "side" and walk_clock <= 0 else frame_set[PlayerMetrics.frame_at(walk_clock*1000)]
		var visual: Rect2 = PlayerMetrics.visual_rect(player,display_scale_at(player))
		var dimensions := visual.size*zoom
		var position := origin+visual.position*zoom
		draw_ellipse_shadow(origin+(player+Vector2(0,39))*zoom,Vector2(19,6)*zoom,canvas)
		var actor_ids: Array=[]
		for target: Dictionary in targets:
			if target.get("follow_player",false): actor_ids.push_front(str(target.id))
		if not actor_ids.is_empty(): register_object_surface(actor_ids,{"rect":visual,"texture":frame,"flip_h":player_flip and facing=="side"})
		canvas.draw_texture_rect(frame,Rect2(position,Vector2(-dimensions.x,dimensions.y) if player_flip and facing == "side" else dimensions),false)
	for target in ordered_targets:
		if _target_point(target).y > player.y: _draw_target(target,origin,canvas)
	if chapter3_layers!=null: chapter3_layers.draw_front(canvas,layer_context,State.d)
	if background:
		for cover in foreground:
			if scene_id=="duan_yongping_temporal_maze" and chapter4_layers!=null and chapter4_layers.bakery_foreground_below_player(cover,State.d): continue
			var baseline := float(cover.get("baselineY",cover.get("sortY",cover.get("bottom",0))))
			var alpha := 1.0 - float(cover.get("playerRevealAlpha",0.0))
			if scene_id=="canteen_interior" and chapter3_layers!=null:
				var occlusion: Dictionary=chapter3_layers.canteen_occlusion(cover,player,bool(State.d.native.settings.reduced_motion))
				if not occlusion.visible: continue
				alpha=occlusion.alpha
			elif player.y >= baseline: continue
			var region := _rect(cover.get("maskBounds",cover))
			canvas.draw_texture_rect_region(background,Rect2(origin+region.position*zoom,region.size*zoom),region,Color(1,1,1,alpha))
	if chapter3_layers!=null: chapter3_layers.draw_landmarks(canvas,layer_context,State.d)
	if library_layers!=null: library_layers.draw_front(canvas,layer_context,State.d)
func _draw_tail_pass(canvas: CanvasItem,layer_context: Dictionary) -> void:
	var origin: Vector2=layer_context.origin
	if lake_session!=null: lake_session.draw(canvas,origin,zoom,bool(State.d.native.settings.reduced_motion))
	if guard_visible and guard_sheet:
		var guard_size := Vector2(96,128)*.68*zoom
		var frame_index := int(Time.get_ticks_msec()/110)%8
		var columns := maxi(1,int(guard_sheet.get_width()/96))
		var frame_region := Rect2((frame_index%columns)*96,int(frame_index/columns)*128,96,128)
		canvas.draw_texture_rect_region(guard_sheet,Rect2(origin+guard_position*zoom-Vector2(guard_size.x/2,guard_size.y*.89),guard_size),frame_region)
	var name_text := str(State.d.get("playerName",State.d.get("characterName","")))
	if not presentation_actor_hidden and not name_text.is_empty(): canvas.draw_string(font,origin+player*zoom+Vector2(-25,22),name_text,HORIZONTAL_ALIGNMENT_CENTER,100,14,Color.WHITE)
	if scene_id=="campus_bootstrap":
		var campus_hud:=hud_metrics(_hud_line())
		var campus_visible:=Rect2(0,campus_hud.header_height,size.x,size.y-campus_hud.header_height-campus_hud.body_height-campus_hud.body_gap)
		CampusWayfinding.draw_label(canvas,layer_context,font,hud_display_scale(),campus_visible)
	if capture_mode: return
	var title: Dictionary = {"dorm_hub":"寝室", "campus_bootstrap":"紫金港校区", "library_interior":"基础图书馆", "canteen_interior":"东食堂", "theater_interior":"剧场", "qizhen_lake":"启真湖", "duan_yongping_temporal_maze":"段永平教学楼", "campus_qizhen_loop":"通往启真湖的路"}
	var line := _hud_line()
	var hud := hud_metrics(line)
	canvas.draw_rect(Rect2(0,0,size.x,hud.header_height),Color(.04,.1,.13,.86))
	if hud.compact:
		var mode_text: String="深色观察" if State.d.native.mode == "dark" else "浅色操作"
		var mode_width: float=font.get_string_size(mode_text,HORIZONTAL_ALIGNMENT_LEFT,-1,hud.mode_font).x
		var baseline: float=(hud.header_height-font.get_height(hud.title_font))/2+font.get_ascent(hud.title_font)
		canvas.draw_string(font,Vector2(hud.padding,baseline),str(title.get(scene_id,scene_id)),HORIZONTAL_ALIGNMENT_LEFT,size.x-mode_width-hud.padding*3,hud.title_font,Color("f0eede"))
		var mode_baseline: float=(hud.header_height-font.get_height(hud.mode_font))/2+font.get_ascent(hud.mode_font)
		canvas.draw_string(font,Vector2(size.x-mode_width-hud.padding,mode_baseline),mode_text,HORIZONTAL_ALIGNMENT_RIGHT,mode_width,hud.mode_font,Color("a8d8e9"))
	else:
		canvas.draw_string(font,Vector2(16,26),str(title.get(scene_id,scene_id)),HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("f0eede"))
		canvas.draw_string(font,Vector2(size.x-230,25),"深色观察" if State.d.native.mode == "dark" else "浅色操作",HORIZONTAL_ALIGNMENT_RIGHT,214,16,Color("a8d8e9"))
	var text_height: float=hud.body_height
	canvas.draw_rect(Rect2(hud.body_gap,size.y-hud.body_gap-text_height,size.x-hud.body_gap*2,text_height),Color(.02,.08,.12,.88))
	canvas.draw_multiline_string(font,Vector2(hud.body_padding,size.y-hud.body_gap-text_height+hud.body_inset+font.get_ascent(hud.body_font)),line,HORIZONTAL_ALIGNMENT_CENTER,hud.body_width,hud.body_font,-1,Color("f1f2dc"))
	if touch_controls or mobile_exploration: _draw_touch_controls(canvas)
	if transition_alpha > 0: canvas.draw_rect(Rect2(Vector2.ZERO,size),Color(.04,.08,.12,transition_alpha))

func _hud_line() -> String:
	if guard_capture.active:return "保安："+GuardCapture.LINE
	if not subtitle.is_empty(): return subtitle
	if not nearby.is_empty(): return ("交互 · " if mobile_exploration else "空格 · ")+str(nearby.get("hud_prompt",nearby.get("label","")))
	if kayak: return "点按或上划左桨 / 右桨前进 · 下划后退" if mobile_exploration else "A / D 左右划桨 · S + 划桨后退"
	return "摇杆移动 · 交互 · 拖动空白处查看" if mobile_exploration else "WASD 移动  /  空格 交互  /  滚轮 缩放"

func hud_display_scale() -> float:
	# The world lives in a SubViewport; its local transform cannot see the
	# outer phone/desktop presentation scale. Read the real display rectangle.
	if is_instance_valid(host_node) and is_instance_valid(host_node.world_view):
		var view: Control=host_node.world_view
		return maxf(0.01,absf(view.get_global_transform_with_canvas().get_scale().x)*view.size.x/maxf(size.x,1.0))
	return 1.0

func hud_metrics(text: String) -> Dictionary:
	if mobile_exploration:
		var width:=size.x-24
		# Feedback grows to its full measured height. Controls already follow
		# this bar's top edge, so source paragraphs never paint through them.
		var height:=maxf(38,font.get_multiline_string_size(text,HORIZONTAL_ALIGNMENT_CENTER,width,14).y+16)
		return {"compact":true,"title_font":18,"mode_font":14,"body_font":14,"header_height":44.0,"padding":10.0,"body_padding":12.0,"body_width":width,"body_height":height,"body_gap":6.0,"body_inset":8.0,"mode_rect":Rect2(size.x-104,0,104,44)}
	return CompactOverlay.world(font,size,hud_display_scale(),text)

func hud_mode_rect() -> Rect2:
	return hud_metrics("").mode_rect

func _draw_target(target: Dictionary, origin: Vector2, canvas: CanvasItem=null) -> void:
	if canvas==null: canvas=self
	if chapter3_layers!=null and chapter3_layers.handles_target(target,State.d): return
	if not target.has("art"): return
	var path := State.asset(str(target.art))
	if not target_textures.has(path):
		if not ResourceLoader.exists(path): return
		target_textures[path] = load(path)
	var texture: Texture2D = target_textures[path]
	var extent = target.get("art_size",[48,48])
	var dimensions := Vector2(float(extent[0]),float(extent[1]))
	var offset = target.get("art_offset",[0,0])
	var point := _target_point(target)+Vector2(float(offset[0]),float(offset[1]))
	var scale_to_fit := minf(dimensions.x/texture.get_width(),dimensions.y/texture.get_height())
	var drawn := Vector2(texture.get_size())*scale_to_fit*zoom
	register_object_surface([str(target.get("id",""))],{"rect":Rect2(point-drawn/(2*zoom),drawn/zoom),"texture":texture})
	canvas.draw_texture_rect(texture,Rect2(origin+point*zoom-drawn/2,drawn),false)

func draw_ellipse_shadow(center: Vector2, extent: Vector2, canvas: CanvasItem=null) -> void:
	if canvas==null: canvas=self
	var points := PackedVector2Array()
	for index in range(20): points.append(center+Vector2(cos(index*TAU/20)*extent.x,sin(index*TAU/20)*extent.y))
	canvas.draw_colored_polygon(points,Color(0,0,0,.25))

func _shell_input_blocked() -> bool:
	return is_instance_valid(host_node) and (is_instance_valid(host_node.get("modal")) or is_instance_valid(host_node.get("active_game")) or is_instance_valid(host_node.get("phone_document")) or bool(State.d.ui.controlCenterOpen))

func _gui_input(event: InputEvent) -> void:
	if is_instance_valid(native_dorm):native_dorm.observe_input(event)
	if capture_mode or _scene_presentation_blocks() or _shell_input_blocked(): return
	if is_instance_valid(host_node) and is_instance_valid(host_node.get("world_effect")) and host_node.world_effect.get_meta("blocks_input",false): return
	if _kayak_mouse_input(event): accept_event(); return
	if mobile_exploration and _mobile_exploration_input(event): return
	if event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_RIGHT or event.button_mask & MOUSE_BUTTON_MASK_MIDDLE):
		pan_offset -= event.relative/zoom
		accept_event()
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT and hud_mode_rect().has_point(event.position):
			if _interaction_presentation_blocks(): accept_event(); return
			State.toggle_mode()
			accept_event()
			return
		grab_focus()
		if event.button_index == MOUSE_BUTTON_WHEEL_UP: zoom = minf(1.6,zoom+.1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN: zoom = maxf(.45,zoom-.1)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			var point: Vector2 = (event.position-size/2)/zoom+camera
			if chapter4_layers != null and scene_id == "duan_yongping_temporal_maze" and not chapter4_layers.pick_drag(point,State.d).is_empty():
				move_target = Vector2.INF
				return
			var clicked: Dictionary = _pick_target(point)
			if not clicked.is_empty(): _try_interact(clicked)
			else: move_target = point
		accept_event()
	if event is InputEventScreenTouch:
		touch_controls = true
		if event.pressed:
			touch_points[event.index] = event.position
			if not kayak:
				if Rect2(size.x-126,size.y-188,100,96).has_point(event.position): _try_interact()
				else: touch_axis = _touch_axis_at(event.position)
		else:
			if kayak and touch_points.has(event.index):
				var start: Vector2 = touch_points[event.index]
				State.lake_world_stroke(self,"left" if start.x < size.x/2 else "right",event.position.y-start.y > 24)
			touch_points.erase(event.index)
			touch_axis = Vector2.ZERO
		_input_kind = "touch"
		accept_event()
	if event is InputEventScreenDrag:
		touch_controls = true
		if not kayak: touch_axis = _touch_axis_at(event.position)
		accept_event()
	if kayak and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_A,KEY_LEFT,KEY_D,KEY_RIGHT]:
			State.lake_world_stroke(self,"left" if event.keycode in [KEY_A,KEY_LEFT] else "right",Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN))
			accept_event()
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		_try_interact()
		accept_event()

func _get_drag_data(at_position: Vector2) -> Variant:
	if capture_mode or _interaction_presentation_blocks() or _shell_input_blocked() or chapter4_layers == null or scene_id != "duan_yongping_temporal_maze": return null
	if is_instance_valid(host_node) and is_instance_valid(host_node.get("world_effect")): return null
	var point := (at_position-size/2)/zoom+camera
	var payload: Dictionary = chapter4_layers.pick_drag(point,State.d)
	if payload.is_empty(): return null
	_finish_table_drag(false)
	furniture_drag_preview=room204_object.drag_preview(point,zoom,bool(State.d.native.settings.get("reduced_motion",false))) if is_instance_valid(room204_object) else null
	_native_table_drag=is_instance_valid(furniture_drag_preview)
	if not _native_table_drag:
		var label:=Label.new()
		label.text="桌椅组 ↑"
		label.add_theme_font_override("font",font)
		label.add_theme_color_override("font_color",Color("b8edf4"))
		label.add_theme_font_size_override("font_size",18)
		furniture_drag_preview=label
	set_drag_preview(furniture_drag_preview)
	_cancel_floor_route()
	move_target = Vector2.INF
	return payload

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if presentation_actor_hidden or capture_mode or _interaction_presentation_blocks() or _shell_input_blocked(): return false
	if is_instance_valid(host_node) and is_instance_valid(host_node.get("world_effect")) and host_node.world_effect.get_meta("blocks_input",false): return false
	return data is Dictionary and data.get("kind") in ["inventory_item","chapter4_room204_group"]

func _drop_data(at_position: Vector2, data: Variant) -> void:
	if not _can_drop_data(at_position,data): return
	var point := (at_position-size/2)/zoom+camera
	if data.get("kind") == "chapter4_room204_group":
		var result: Dictionary = chapter4_layers.resolve_drag(data,point,State.d) if chapter4_layers != null else {}
		if result.is_empty(): State.feedback.emit("桌椅没有对上残影，已回到原位。")
		else:
			_sync_player()
			State.act(str(result.action),result.value)
		return
	# CanteenInteriorScene.handleInventoryDrop gives badDrink its own source-
	# space self-use circle before ordinary object picking. No mode is required.
	if scene_id=="canteen_interior" and str(data.get("item",""))=="badDrink":
		if not point.is_finite(): return
		if mobile_exploration:
			var controls:=mobile_control_metrics()
			if not _floor_visible_rect().has_point(point) or controls.stick_rect.has_point(at_position) or controls.interact.has_point(at_position): return
		if point.distance_to(player-Vector2(0,24))<=58.0:
			State.act("c3_bad_drink")
		else: State.feedback.emit("把难喝饮料拖到人物自己身上才能喝掉。")
		return
	var matching: Dictionary = _pick_target(point,true)
	if matching.is_empty(): State.feedback.emit("没有落在可使用的物品上，道具仍在物品栏。") ; return
	if (matching.has("item") and str(matching.item) != str(data.item)) or (not matching.get("acceptedItems",[]).is_empty() and str(data.item) not in matching.acceptedItems): State.feedback.emit("这个物品不适合当前目标。") ; return
	State.select_item(str(data.item))
	_try_interact(matching)

func _guard_capture_context()->Dictionary:
	var chapter:Dictionary=State.d.get("chapter4",{})
	return {"scene":State.d.get("native",{}).get("scene",""),"floor":chapter.get("floor",""),"phase":chapter.get("phase",""),"time":chapter.get("timeState",""),"mode":chapter.get("mode",""),"guardMode":chapter.get("guardMode",""),"attempt":int(chapter.get("chaseAttempt",0))}

func _sync_guard_capture_input():
	if is_instance_valid(host_node) and host_node.has_method("_sync_inventory_dock_input"):host_node._sync_inventory_dock_input()

func _begin_guard_capture(action:String,value:Dictionary={}):
	if not guard_capture.begin(_guard_capture_context(),action,value):return
	_cancel_floor_route();move_target=Vector2.INF;touch_axis=Vector2.ZERO;touch_points.clear()
	if mobile_exploration:cancel_exploration_gestures()
	walk_clock=0;guard_visible=true
	_sync_guard_capture_input();queue_redraw()

func _cancel_guard_capture():
	if not guard_capture.active:return
	guard_capture.cancel();guard_kind=""
	_sync_guard_capture_input();queue_redraw()

func _tick_guard_capture(delta_ms:float):
	var context:=_guard_capture_context()
	if not guard_capture.matches(context):_cancel_guard_capture();return
	var running:=is_visible_in_tree() and not capture_mode and get_window().has_focus() and not _shell_input_blocked()
	if is_instance_valid(host_node):running=running and host_node.world_frame.is_visible_in_tree()
	var result:Dictionary=guard_capture.advance(delta_ms,context,running)
	queue_redraw()
	if result.is_empty():return
	# The original controller remains the sole relocation/attempt authority.
	guard_kind=""
	guard_recovery_pending=result.action=="c4_recover_patrol"
	_sync_guard_capture_input()
	State.act(str(result.action),result.value)

func _exit_tree():
	guard_capture.cancel()

func _guard_cue(id: String,payload: Dictionary = {}) -> void:
	if is_instance_valid(host_node) and host_node.has_method("_game_presentation"): host_node._game_presentation(id,payload)

func accept_stair_handoff(value:Dictionary)->bool:
	var c:Dictionary=State.d.chapter4
	if State.d.native.scene!="duan_yongping_temporal_maze" or c.phase!="final_chase" or c.floor!="A2" or c.chaseStairwellStage!="complete":return false
	if value.get("destination","")!="A2" or int(value.get("attempt",-1))!=int(c.chaseAttempt):return false
	var lead:=float(value.get("leadDistance",NAN))
	if not is_finite(lead):return false
	stair_handoff={"attempt":int(c.chaseAttempt),"leadDistance":clampf(lead,600,2000)};guard_kind="";return true

func _update_guard(delta: float) -> void:
	guard_visible=false
	if not guard_model or scene_id!="duan_yongping_temporal_maze": guard_kind=""; return
	var chapter: Dictionary=State.d.chapter4
	var mode:=str(chapter.guardMode)
	if mode not in ["patrol","chase"]: guard_kind=""; return
	# The source runtime replaces A1 with the stair scene while inside. Its
	# old guard cannot continue behind the activity or after an explicit Exit.
	if mode=="chase" and chapter.floor=="A1" and chapter.chaseStairwellStage=="inside":guard_kind="";return
	var key:=mode+str(chapter.floor)+str(chapter.chaseAttempt)
	if guard_kind!=key:
		guard_kind=key
		guard_navigation_key=""
		guard_navigation_target=Vector2.INF
		guard_repath_ms=0
		guard_clock_ms=0
		guard_audio_band=""
		guard_close_requested=false
		guard_close_voice_played=false
		guard_floor_voice_played=false
		if mode=="patrol":
			guard_state=guard_model.maintenance_state(0x7552245,guard_recovery_pending)
			guard_recovery_pending=false
			guard_position=guard_state.position
			guard_grace=0
		else:
			guard_state=guard_model.chase_state(int(chapter.chaseAttempt))
			guard_position=Vector2(590,724)
			guard_grace=0 # Source model itself owns the four-frame/two-second grace.
			if chapter.floor=="A2" and chapter.chaseStairwellStage=="complete":
				# Source runtime recreates after the isolated stairwell handoff with
				# a minimum600px guard lag, rather than starting a second grace.
				var lead:=600.0
				if not stair_handoff.is_empty() and int(stair_handoff.attempt)==int(chapter.chaseAttempt):lead=float(stair_handoff.leadDistance)
				stair_handoff.clear()
				guard_state.merge({"phase":"portal_transfer","floor":"A2","guardFloor":"A1","portalApplied":true,"portalRemainingDistance":lead},true)
	guard_clock_ms+=delta*1000
	var walls: Array=[]
	for box in collisions: walls.append(_rect(box))
	var feet: Rect2=PlayerMetrics.foot_rect(player)
	var foot: Vector2=feet.get_center()
	var velocity:=Vector2.ZERO
	if mode=="patrol":
		if chapter.floor!="A1": return
		var result: Dictionary=guard_model.maintenance_step(guard_state,delta*1000,guard_position,foot,walls)
		guard_state=result.state
		velocity=result.desiredVelocity
		guard_visible=true
		if result.enteredPursuit: State.feedback.emit("保安发现了你。")
		if guard_model.maintenance_contact(guard_position,feet):
			_begin_guard_capture("c4_recover_patrol")
			return
	else:
		var inside_finish: bool=chapter.floor=="A2" and Rect2(1287,302,132,109).has_point(foot)
		var inside_stair: bool=chapter.floor=="A1" and Rect2(932,145,138,107).has_point(foot)
		var same_floor:=str(guard_state.get("guardFloor","A1"))==str(chapter.floor)
		var result: Dictionary=guard_model.chase_step(guard_state,{"deltaMs":delta*1000,"committedAndApplied":_last_floor==chapter.floor and background!=null,"floor":chapter.floor,"playerPosition":foot,"guardPosition":guard_position,"playerInsideFinish":inside_finish and guard_close_requested,"playerEnteredMainStair":inside_stair,"guardContact":same_floor and guard_model.chase_contact(guard_position,feet)})
		guard_state=result.state
		if not inside_finish: guard_close_requested=false
		if result.guardPortalArrival:
			guard_position=Vector2(966,174)
			if not guard_floor_voice_played:
				guard_floor_voice_played=true
				_guard_cue("final_chase_floor_changed",{"attempt":chapter.chaseAttempt,"floor":"A2"})
		same_floor=str(guard_state.get("guardFloor","A1"))==str(chapter.floor)
		guard_visible=bool(result.guardVisible) and same_floor
		var gap:=guard_position.distance_to(foot) if same_floor else INF
		var band:="close" if gap<=120 else "tracking" if gap<=420 else "catch_up"
		if band!=guard_audio_band:
			guard_audio_band=band
			_guard_cue("final_chase_pressure_"+band,{"attempt":chapter.chaseAttempt,"routeDistance":roundi(float(result.remainingRouteDistance))})
			if band=="close" and not guard_close_voice_played:
				guard_close_voice_played=true
				_guard_cue("final_chase_close_voice",{"attempt":chapter.chaseAttempt})
		if result.portalRequested:
			var response: Dictionary=State.act("c4_chase",{"expectedAttempt":chapter.chaseAttempt,"leadDistance":float(guard_state.portalRemainingDistance)})
			if not response.has("game"): guard_state=guard_model.resolve_portal(guard_state,false)
			return
		if result.finishRequested:
			State.act("c4_reach202")
			guard_state=guard_model.resolve_finish(guard_state,State.d.chapter4.phase=="final_minute_recovery")
			return
		if result.failureRequested:
			_begin_guard_capture("c4_fail_chase",{"expectedAttempt":chapter.chaseAttempt,"failureFloor":chapter.floor})
			return
		if guard_visible:
			var nav_key:=world_key+":"+str(collisions.hash())
			if guard_navigation==null or guard_navigation_key!=nav_key:
				guard_navigation=load("res://scripts/games/chapter4_guard_navigation.gd").new()
				guard_navigation.setup(walls,world_size.x,world_size.y)
				guard_navigation_key=nav_key
				guard_repath_ms=0
			if guard_clock_ms>=guard_repath_ms or guard_navigation_target==Vector2.INF or guard_position.distance_to(guard_navigation_target)<10:
				var path: Array=guard_navigation.path(guard_position,foot if same_floor else Vector2(1001,214))
				guard_navigation_target=path[0] if not path.is_empty() else Vector2.INF
				guard_repath_ms=guard_clock_ms+260
			if guard_navigation_target!=Vector2.INF and guard_position.distance_squared_to(guard_navigation_target)>4:
				velocity=guard_position.direction_to(guard_navigation_target)*174
	var change:=velocity*delta
	if _guard_can_stand(guard_position+Vector2(change.x,0),walls): guard_position.x+=change.x
	if _guard_can_stand(guard_position+Vector2(0,change.y),walls): guard_position.y+=change.y

func _guard_can_stand(point: Vector2,walls: Array) -> bool:
	var extent:=Vector2(10,8) if State.d.chapter4.guardMode=="patrol" else Vector2(10.2,7.65)
	var body:=Rect2(point-extent,extent*2)
	for wall in walls:
		if body.intersects(wall): return false
	return point.x>=extent.x and point.y>=extent.y and point.x<=world_size.x-extent.x and point.y<=world_size.y-extent.y

func _finish_table_drag(settle:=true) -> void:
	if not _native_table_drag: return
	_native_table_drag=false
	if is_instance_valid(furniture_drag_preview): furniture_drag_preview.retire()
	furniture_drag_preview=null
	if is_instance_valid(room204_object): room204_object.finish_drag(settle)

func _cancel_table_drag() -> void:
	if not _native_table_drag: return
	_finish_table_drag(false)
	if is_inside_tree() and get_viewport().gui_is_dragging(): get_viewport().gui_cancel_drag()

func _notification(what: int) -> void:
	if what==NOTIFICATION_DRAG_END: _finish_table_drag()
	elif what==NOTIFICATION_WM_WINDOW_FOCUS_OUT: _cancel_table_drag()
	elif what==NOTIFICATION_VISIBILITY_CHANGED and is_inside_tree() and not is_visible_in_tree(): _cancel_table_drag()
	elif what==NOTIFICATION_RESIZED: _cancel_table_drag()
	if what==NOTIFICATION_WM_WINDOW_FOCUS_OUT and (mobile_exploration or not kayak_mouse_gesture.is_empty()): cancel_exploration_gestures()

func cancel_exploration_gestures() -> void:
	_cancel_table_drag()
	touch_axis=Vector2.ZERO; touch_points.clear(); mobile_touch_roles.clear(); mobile_mouse_control=false; move_target=Vector2.INF
	kayak_mouse_gesture.clear()
	_cancel_floor_route()

func kayak_paddle_rects() -> Dictionary:
	return {"left":Rect2(70,size.y-176,100,92),"right":Rect2(size.x-170,size.y-176,100,92)}

func _kayak_mouse_context() -> Array:
	return [world_key,size,host_node.world_view.get_global_rect() if is_instance_valid(host_node) else get_global_rect(),kayak.get_instance_id() if kayak!=null else 0]

func _kayak_mouse_valid() -> bool:
	if kayak==null or not is_visible_in_tree() or not (touch_controls or mobile_exploration) or _interaction_presentation_blocks() or _shell_input_blocked() or capture_mode: return false
	if is_instance_valid(host_node):
		if not is_instance_valid(host_node.world_frame) or not host_node.world_frame.is_visible_in_tree(): return false
		if is_instance_valid(host_node.get("world_effect")) and host_node.world_effect.get_meta("blocks_input",false): return false
	return kayak_mouse_gesture.get("context",[])==_kayak_mouse_context()

func _kayak_root_point(point: Vector2) -> Vector2:
	if not is_instance_valid(host_node): return get_global_transform_with_canvas()*point
	var view: Control=host_node.world_view
	var pixel: Vector2=get_global_transform_with_canvas()*point
	return view.get_global_transform_with_canvas()*(pixel*view.size/Vector2(get_viewport().size))

func _kayak_finger_owns(side: String) -> bool:
	for gesture: Dictionary in mobile_touch_roles.values():
		if gesture.role=="paddle" and ("left" if gesture.start.x<size.x/2 else "right")==side: return true
	for point: Vector2 in touch_points.values():
		if ("left" if point.x<size.x/2 else "right")==side: return true
	return false

func _kayak_mouse_input(event: InputEvent) -> bool:
	if kayak==null or not (touch_controls or mobile_exploration): return false
	# A finger already has its own source route. Its emulated mouse is never a
	# second stroke; a real simultaneous pointer cannot claim the same paddle.
	if event is InputEventScreenTouch and event.pressed and not kayak_mouse_gesture.is_empty():
		return kayak_paddle_rects()[kayak_mouse_gesture.side].has_point(event.position)
	if not (event is InputEventMouseButton or event is InputEventMouseMotion): return false
	if event.device==-1: return true
	if not kayak_mouse_gesture.is_empty():
		var copy: InputEvent=event.duplicate(); copy.position=_kayak_root_point(event.position)
		return handle_root_kayak_pointer(copy)
	if not event is InputEventMouseButton or event.button_index!=MOUSE_BUTTON_LEFT or not event.pressed: return false
	for side: String in kayak_paddle_rects():
		if not kayak_paddle_rects()[side].has_point(event.position): continue
		if _kayak_finger_owns(side): return true
		var point:=_kayak_root_point(event.position)
		kayak_mouse_gesture={"side":side,"start":point,"last":point,"context":_kayak_mouse_context(),"scale":hud_display_scale()}
		_cancel_floor_route(); grab_focus(); queue_redraw()
		return true
	return false

func handle_root_kayak_pointer(event: InputEvent) -> bool:
	# Main forwards an owned release before GUI routing, including outside the
	# SubViewport. Like source pointer capture, leaving the button is not cancel.
	if kayak_mouse_gesture.is_empty() or not (event is InputEventMouseButton or event is InputEventMouseMotion): return false
	if not _kayak_mouse_valid(): kayak_mouse_gesture.clear(); return false
	if event.device==-1: return true
	if event is InputEventMouseMotion:
		kayak_mouse_gesture.last=event.position; queue_redraw(); return true
	if event.button_index!=MOUSE_BUTTON_LEFT: return false
	if not event.pressed:
		var gesture: Dictionary=kayak_mouse_gesture; kayak_mouse_gesture={}
		# Match the existing native finger threshold; physics/impulse are still
		# exclusively dispatched by the controller's original world-stroke owner.
		State.lake_world_stroke(self,str(gesture.side),(event.position.y-gesture.start.y)/maxf(.01,float(gesture.scale))>24)
		queue_redraw()
	return true

func mobile_control_metrics() -> Dictionary:
	# Physical-pixel controls occupy a reserved strip above the subtitle.
	var body: Dictionary=hud_metrics(_hud_line())
	var bottom: float=size.y-float(body.body_height)-float(body.body_gap)-12
	var radius:=50.0
	var center:=Vector2(62,bottom-radius)
	return {"stick":center,"radius":radius,"stick_rect":Rect2(center-Vector2.ONE*radius,Vector2.ONE*radius*2),"interact":Rect2(size.x-78,bottom-60,60,60)}

func _mobile_pan(delta: Vector2) -> void:
	_cancel_floor_route()
	var limit:=size*.35/zoom
	pan_offset=(pan_offset-delta/zoom).clamp(-limit,limit)
	move_target=Vector2.INF
	_update_camera(); queue_redraw()

func _mobile_exploration_input(event: InputEvent) -> bool:
	# Emulated mouse events cannot repeat a finger tap or turn a pan into walking.
	if (event is InputEventMouseButton or event is InputEventMouseMotion) and event.device==-1: return true
	var metrics:=mobile_control_metrics()
	if event is InputEventKey and event.pressed: _cancel_floor_route()
	if event is InputEventMouseButton and event.pressed: _cancel_floor_route()
	if event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_RIGHT or event.button_mask & MOUSE_BUTTON_MASK_MIDDLE):
		_mobile_pan(event.relative); accept_event(); return true
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if not event.pressed and mobile_mouse_control:
			mobile_mouse_control=false; touch_axis=Vector2.ZERO; accept_event(); return true
		if event.pressed and not kayak and metrics.stick_rect.has_point(event.position):
			mobile_mouse_control=true; touch_axis=_touch_axis_at(event.position); accept_event(); return true
		if event.pressed and not kayak and metrics.interact.has_point(event.position): _try_interact(); accept_event(); return true
		if event.pressed and not kayak and not hud_mode_rect().has_point(event.position):
			_mobile_floor_tap(event.position); accept_event(); return true
	if event is InputEventMouseMotion and mobile_mouse_control:
		touch_axis=_touch_axis_at(event.position); accept_event(); return true
	if event is InputEventScreenTouch:
		touch_controls=true
		if event.pressed:
			_cancel_floor_route()
			var role: String="mode" if hud_mode_rect().has_point(event.position) else "interact" if not kayak and metrics.interact.has_point(event.position) else "stick" if not kayak and metrics.stick_rect.has_point(event.position) else "paddle" if kayak and event.position.y>size.y-180 else "pan"
			mobile_touch_roles[event.index]={"role":role,"start":event.position,"last":event.position,"panned":false}
			if role=="mode" and not _interaction_presentation_blocks(): State.toggle_mode()
			elif role=="interact": _try_interact()
			elif role=="stick": touch_axis=_touch_axis_at(event.position)
		elif mobile_touch_roles.has(event.index):
			var gesture: Dictionary=mobile_touch_roles[event.index]
			if gesture.role=="stick": touch_axis=Vector2.ZERO
			elif not event.canceled:
				if gesture.role=="paddle": State.lake_world_stroke(self,"left" if gesture.start.x<size.x/2 else "right",event.position.y-gesture.start.y>24)
				elif gesture.role=="pan" and not gesture.panned:
					_mobile_floor_tap(event.position)
			mobile_touch_roles.erase(event.index)
		accept_event(); return true
	if event is InputEventScreenDrag:
		if mobile_touch_roles.has(event.index):
			var gesture: Dictionary=mobile_touch_roles[event.index]
			if gesture.role=="stick": touch_axis=_touch_axis_at(event.position)
			elif gesture.role=="pan" and (gesture.panned or event.position.distance_to(gesture.start)>10):
				gesture.panned=true; _mobile_pan(event.position-gesture.last)
			gesture.last=event.position
		accept_event(); return true
	return false

func _touch_axis_at(point: Vector2) -> Vector2:
	if mobile_exploration:
		var metrics:=mobile_control_metrics()
		var difference: Vector2=point-metrics.stick
		if not metrics.stick_rect.grow(16).has_point(point) or difference.length()<10: return Vector2.ZERO
		return difference.normalized()
	var origin := Vector2(90,size.y-140)
	var difference := point-origin
	if absf(difference.x)>90 or absf(difference.y)>80: return Vector2.ZERO
	if difference.length()<14: return Vector2.ZERO
	return difference.normalized()

func _draw_touch_controls(canvas: CanvasItem=null) -> void:
	if canvas==null: canvas=self
	if mobile_exploration and not kayak:
		var metrics:=mobile_control_metrics()
		canvas.draw_circle(metrics.stick,metrics.radius,Color(.02,.10,.13,.66))
		for direction in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
			canvas.draw_circle(metrics.stick+direction*32,10,Color(.84,.88,.74,.72))
		canvas.draw_circle(metrics.interact.get_center(),30,Color(.02,.10,.13,.76))
		canvas.draw_string(font,metrics.interact.position+Vector2(8,37),"交互",HORIZONTAL_ALIGNMENT_CENTER,44,16,Color.WHITE)
		return
	var caption_font := CompactOverlay.font_size(22 if kayak else 21,12,hud_display_scale())
	if kayak:
		for side: String in kayak_paddle_rects():
			var rect: Rect2=kayak_paddle_rects()[side]
			var held: bool=kayak_mouse_gesture.get("side","")==side
			canvas.draw_rect(rect,Color(.02,.10,.13,.84 if held else .65))
			canvas.draw_rect(rect,Color("dbc487") if held else Color("52767a"),false,2 if held else 1)
			canvas.draw_string(font,rect.position+Vector2(18,46),"左桨" if side=="left" else "右桨",HORIZONTAL_ALIGNMENT_CENTER,64,caption_font,Color.WHITE)
			if held:
				var reverse: bool=(kayak_mouse_gesture.last.y-kayak_mouse_gesture.start.y)/maxf(.01,float(kayak_mouse_gesture.scale))>24
				canvas.draw_string(font,rect.position+Vector2(8,74),"↓ 后退" if reverse else "松开划桨",HORIZONTAL_ALIGNMENT_CENTER,84,CompactOverlay.font_size(13,12,hud_display_scale()),Color("e9d8aa"))
	else:
		var origin := Vector2(90,size.y-140)
		canvas.draw_circle(origin,65,Color(.02,.10,.13,.65))
		for point in [Vector2(-44,0),Vector2(44,0),Vector2(0,-44),Vector2(0,44)]:
			canvas.draw_circle(origin+point,16,Color(.84,.88,.74,.65))
		canvas.draw_circle(Vector2(size.x-76,size.y-140),42,Color(.02,.10,.13,.65))
		canvas.draw_string(font,Vector2(size.x-112,size.y-132),"空格",HORIZONTAL_ALIGNMENT_CENTER,72,caption_font,Color.WHITE)

func _cancel_floor_route() -> void:
	_floor_route.clear(); _floor_goal=Vector2.INF; _floor_status=""; _floor_feedback_left=0

func _stop_floor_route() -> void:
	_floor_route.clear(); move_target=Vector2.INF; _floor_status="blocked"; _floor_feedback_left=.9

func _floor_transform_current() -> bool:
	return world_key==_floor_world_key and size==_floor_view_size and is_equal_approx(zoom,_floor_view_zoom) and camera.is_equal_approx(_floor_expected_camera)

func _floor_visible_rect() -> Rect2:
	var hud:=hud_metrics(_hud_line())
	var local:=Rect2(0,hud.header_height,size.x,maxf(0,size.y-hud.header_height-hud.body_height-hud.body_gap))
	return Rect2(camera+(local.position-size/2)/zoom,local.size/zoom).intersection(Rect2(Vector2.ZERO,world_size))

func _floor_anchor_bounds(visible: Rect2) -> Rect2:
	var feet:=PlayerMetrics.foot_rect(Vector2.ZERO)
	return Rect2(visible.position-feet.position,visible.size-feet.size)

func _floor_obstacles() -> Array:
	if is_instance_valid(native_canteen) and native_canteen.is_active():return native_canteen.navigation_obstacles(PlayerMetrics.foot_rect(Vector2.ZERO))
	var obstacles: Array=[]
	var feet:=PlayerMetrics.foot_rect(Vector2.ZERO)
	for obstacle in collisions:
		if not obstacle is Dictionary: continue
		var shape: Dictionary=library_layers.replace_collision(obstacle) if scene_id=="library_interior" and library_layers!=null else obstacle
		var rect:=_rect(shape)
		obstacles.append(Rect2(rect.position-feet.end,rect.size+feet.size))
	if scene_id=="duan_yongping_temporal_maze" and chapter4_layers!=null:
		for rect: Rect2 in chapter4_layers.collisions(State.d): obstacles.append(Rect2(rect.position-feet.end,rect.size+feet.size))
	return obstacles

func _floor_stand(point: Vector2) -> bool:
	return _floor_bounds.has_point(point) and can_stand(point)

func _floor_segment_clear(a: Vector2,b: Vector2,planned_obstacles: Array=[],validated_nodes: bool=false) -> bool:
	# Planning is synchronous and has already checked each graph node. Walking
	# always takes the default branch and reads current collisions every frame.
	if not validated_nodes and (not _floor_stand(a) or not _floor_stand(b)): return false
	for obstacle: Rect2 in (planned_obstacles if validated_nodes else _floor_obstacles()):
		if MobileFloorRoute.segment_hits(a,b,obstacle): return false
	if mask.is_empty(): return true
	# Test every interval where any of the authoritative five foot samples
	# changes mask cell. No approximate stepping can tunnel a narrow mask gap.
	var cuts: Array[float]=[0.0,1.0]
	var feet:=PlayerMetrics.foot_rect(Vector2.ZERO)
	var change:=b-a
	var cell:=float(mask_meta.cellSize)
	for offset: Vector2 in [feet.get_center(),feet.position,Vector2(feet.end.x,feet.position.y),Vector2(feet.position.x,feet.end.y),feet.end]:
		for axis in [0,1]:
			if absf(change[axis])<.000001: continue
			var first: float=(a+offset)[axis]
			var last: float=(b+offset)[axis]
			for index in range(int(floor(minf(first,last)/cell))+1,int(floor(maxf(first,last)/cell))+1):
				var fraction: float=(index*cell-first)/change[axis]
				if fraction>0 and fraction<1: cuts.append(fraction)
	cuts.sort()
	for index in range(1,cuts.size()):
		if not can_stand(a.lerp(b,cuts[index])) or not can_stand(a.lerp(b,(cuts[index-1]+cuts[index])*.5)): return false
	return true

func _floor_empty_destination(point: Vector2) -> bool:
	var local: Vector2=(point-camera)*zoom+size/2
	var hud:=hud_metrics(_hud_line())
	var visible:=Rect2(0,hud.header_height,size.x,size.y-hud.header_height-hud.body_height-hud.body_gap)
	var controls:=mobile_control_metrics()
	if not visible.has_point(local) or controls.stick_rect.has_point(local) or controls.interact.has_point(local): return false
	for surface: Dictionary in object_picker.surfaces:
		if surface.painted and object_picker.contains(surface.geometry,point): return false
	var frames: Array=player_frames.get(facing,[])
	if not frames.is_empty():
		var frame: Texture2D=player_side_idle if facing=="side" and walk_clock<=0 else frames[PlayerMetrics.frame_at(walk_clock*1000)]
		if object_picker.contains({"rect":PlayerMetrics.visual_rect(player,display_scale_at(player)),"texture":frame,"flip_h":player_flip and facing=="side"},point): return false
	return _pick_target(point).is_empty()

func _canteen_floor_goal(goal: Vector2,obstacles: Array) -> Vector2:
	# This precision aid applies only to the measured rectangle-only canteen.
	# Exact legal goals, including disconnected ones, keep their original intent.
	_canteen_floor_tap.candidate_count=0
	if scene_id!="canteen_interior" or not mask.is_empty() or _floor_stand(goal): return goal
	var point:=goal+PlayerMetrics.FOOT_CENTER_OFFSET
	for obstacle: Dictionary in collisions:
		if _rect(obstacle).has_point(point): return goal
	if not Rect2(Vector2.ZERO,world_size).encloses(PlayerMetrics.visual_rect(goal,display_scale_at(goal))): return goal
	return _canteen_floor_tap.nearest(goal,CanteenFloorTap.PIXEL_RADIUS/zoom,obstacles,_floor_stand,func(anchor: Vector2): return _floor_empty_destination(anchor+PlayerMetrics.FOOT_CENTER_OFFSET))

func _mobile_floor_tap(local: Vector2) -> void:
	_cancel_floor_route(); move_target=Vector2.INF
	if presentation_actor_hidden or capture_mode or _interaction_presentation_blocks() or _shell_input_blocked(): return
	if get_viewport().gui_is_dragging() or get_tree().root.gui_is_dragging(): return
	var hud:=hud_metrics(_hud_line())
	var visible:=Rect2(0,hud.header_height,size.x,size.y-hud.header_height-hud.body_height-hud.body_gap)
	var controls:=mobile_control_metrics()
	if not visible.has_point(local) or controls.stick_rect.has_point(local) or controls.interact.has_point(local): return
	var point: Vector2=(local-size/2)/zoom+camera
	# Furniture owns the press before overlapping targets, as in canonical input.
	if chapter4_layers!=null and scene_id=="duan_yongping_temporal_maze" and not chapter4_layers.pick_drag(point,State.d).is_empty(): return
	var clicked:=_pick_target(point)
	if not clicked.is_empty(): _try_interact(clicked); return
	if kayak or (scene_id=="dorm_hub" and not _manual_sent): return
	# Painted occluders and actor pixels are not empty floor. Selection stays
	# entirely with the unchanged picker; this route never chooses a target.
	for surface: Dictionary in object_picker.surfaces:
		if surface.painted and object_picker.contains(surface.geometry,point): return
	var frames: Array=player_frames.get(facing,[])
	if not frames.is_empty():
		var frame: Texture2D=player_side_idle if facing=="side" and walk_clock<=0 else frames[PlayerMetrics.frame_at(walk_clock*1000)]
		if object_picker.contains({"rect":PlayerMetrics.visual_rect(player,display_scale_at(player)),"texture":frame,"flip_h":player_flip and facing=="side"},point): return
	_floor_bounds=_floor_anchor_bounds(_floor_visible_rect())
	_floor_goal=point
	_floor_world_key=world_key; _floor_view_size=size; _floor_view_zoom=zoom; _floor_expected_camera=camera
	# Tap/marker denote the exact collision-foot center, not the sprite origin
	# or its shadow at +39. Object and inventory hit coordinates are unchanged.
	var goal:=point-PlayerMetrics.FOOT_CENTER_OFFSET
	var obstacles:=_floor_obstacles()
	var resolved:=_canteen_floor_goal(goal,obstacles)
	if resolved!=goal:
		goal=resolved
		_floor_goal=goal+PlayerMetrics.FOOT_CENTER_OFFSET
	_floor_route=_floor_planner.plan(player,goal,obstacles,_floor_bounds,_floor_stand,func(a: Vector2,b: Vector2): return _floor_segment_clear(a,b,obstacles,true))
	if _floor_route.is_empty(): _stop_floor_route()
	else: _floor_status="moving"
	grab_focus(); queue_redraw()

func _draw_floor_route(origin: Vector2, canvas: CanvasItem=null) -> void:
	if canvas==null: canvas=self
	if _floor_goal==Vector2.INF or capture_mode or presentation_actor_hidden: return
	var color:=Color(.74,.87,.77,.9)
	var previous: Vector2=origin+PlayerMetrics.foot_rect(player).get_center()*zoom
	for anchor: Vector2 in _floor_route:
		var next: Vector2=origin+PlayerMetrics.foot_rect(anchor).get_center()*zoom
		canvas.draw_line(previous,next,Color(.74,.87,.77,.23),1.0,true); previous=next
	var point:=origin+_floor_goal*zoom
	if _floor_status=="blocked":
		var blocked:=Color("f0b35e")
		canvas.draw_circle(point,10,Color(.08,.06,.03,.8))
		canvas.draw_line(point+Vector2(-5,-5),point+Vector2(5,5),blocked,2.5,true)
		canvas.draw_line(point+Vector2(-5,5),point+Vector2(5,-5),blocked,2.5,true)
	else: canvas.draw_arc(point,7,0,TAU,24,color,1.5,true)
