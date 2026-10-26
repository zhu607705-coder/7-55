extends Control
const CampusMaterial = preload("res://scripts/ui/campus_ui_material.gd")
const CompactOverlay = preload("res://scripts/ui/compact_overlay_layout.gd")
const OverflowText=preload("res://scripts/ui/overflow_text.gd")
var overflow_feedback:ScrollContainer
const WorldOverlay = preload("res://scripts/ui/world_overlay_layout.gd")
const MobileFloorRoute = preload("res://scripts/mobile_floor_route.gd")
const CanteenFloorTap = preload("res://scripts/canteen_floor_tap.gd")
const PlayerMetrics = preload("res://scripts/player_metrics.gd")
const CharacterFacing = preload("res://scripts/character_facing.gd")
const InventoryGesture = preload("res://scripts/ui/inventory_gesture.gd")
const ObjectPicker = preload("res://scripts/world_object_picker.gd")
const KayakObject = preload("res://scripts/objects/kayak_world_adapter.gd")
const CampusWayfinding = preload("res://scripts/ui/campus_wayfinding.gd")
const LibraryEntranceDoor = preload("res://scripts/presentation/library_entrance_door.gd")
const DirectWorldGestures=preload("res://scripts/direct_world_gestures.gd")
const TargetApproach=preload("res://scripts/target_approach.gd")
const NorthObjects=preload("res://scripts/presentation/north_generated_objects.gd")
var north_objects:RefCounted=NorthObjects.new()
var north_source_objects:Node2D
const Room301Layout=preload("res://scripts/objects/room301_exhibit_layout.gd")
var room301_exhibit:Node2D
var elevator_button:Node2D
var north_props:Node2D
const SourceTiledTexture=preload("res://scripts/presentation/source_tiled_texture.gd")
# This chapter-owned script and its setup textures are loaded only after the
# incoming scene's WebContent pack is ready. An inactive canteen is retained
# after its first visit so returning does not rebuild every prop and observer.
const CANTEEN_SCENE_SCRIPT="res://scripts/objects/canteen_object_scene.gd"
const DORM_SCENE_SCRIPT="res://scripts/objects/dorm_scene_adapter.gd"
var library_door:RefCounted=LibraryEntranceDoor.new()
var direct_gestures:RefCounted=DirectWorldGestures.new()
var background_tiles:RefCounted=SourceTiledTexture.new()
var background_is_tiled:bool=false
## Source-pixel exploration surface. No story facts are authored by rendering.
var worlds: Dictionary = {}
var spec: Dictionary = {}
var scene_id := ""
var world_key := ""
var background: Texture2D
var player_frames: Dictionary = {}
var player_side_idle: Texture2D
var player_left_idle: Texture2D
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
var _floor_pending_interaction:Dictionary={}
var _floor_intent_state:Dictionary={}
var _floor_planner := MobileFloorRoute.new()
var _canteen_floor_tap := CanteenFloorTap.new()
var nearby: Dictionary = {}
var walk_clock := 0.0
var facing := "down"
var player_turn:Dictionary={}
signal subtitle_expired(revision:int,text:String)
var subtitle_revision:=0
var subtitle := "":
	set(value):
		subtitle=value
		subtitle_revision+=1
var subtitle_left := 0.0
var font: Font
var selected_overlay: Control
var selected_overlay_native_rect:=Rect2()
var selected_overlay_is_native:=false
var hud_font: Font
var _last_save := 0.0
var _manual_sent := false
var _last_floor := ""
var _input_kind := "keyboard"
var touch_axis := Vector2.ZERO
var kayak: RefCounted
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
var guard_sheets: Dictionary={}
var guard_facing: String="side"
var guard_flip: bool=false
var guard_walk_clock: float=0
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
# The Web observer reads geometry already computed by normal drawing/input.
# It must not call the HUD path, which also retires stale confirmed labels.
var mobile_control_observation: Dictionary = {}
var mobile_confirmed_target_id := ""
var mobile_confirmed_world_key := ""
var capture_mode := false
var host_node: Control
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
var kayak_visual: Node2D
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
	font = load("res://scripts/ui/native_typography.gd").body_font()
	hud_font = load("res://scripts/ui/native_typography.gd").body_font()
	selected_overlay=load("res://scripts/ui/world_selected_overlay.gd").new();add_child(selected_overlay)
	overflow_feedback=OverflowText.new();overflow_feedback.name="OverflowFeedback";overflow_feedback.z_index=90;add_child(overflow_feedback)
	var feedback_label:=Label.new();add_child(feedback_label)
	feedback_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;feedback_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	load("res://scripts/ui/native_typography.gd").apply_body(feedback_label);feedback_label.add_theme_color_override("font_color",Color("f1f2dc"))
	overflow_feedback.setup(feedback_label);overflow_feedback.hide()
	State.world_teleport.connect(_receive_teleport)
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
	kayak_visual=KayakObject.new();kayak_visual.name="NativeKayak";add_child(kayak_visual);kayak_visual.setup(self)
	if north_objects.independent_preview:
		north_props=load("res://scripts/objects/north_prop_scene.gd").new();north_props.name="NorthIndependentProps";add_child(north_props);north_props.setup(self)
	north_source_objects=load("res://scripts/objects/north_floor_source_objects.gd").new();add_child(north_source_objects);north_source_objects.setup(self)
	refresh_world()

func _ensure_scene_visuals(incoming: String) -> void:
	# Called only after the Web content gate. The hidden first-chapter world
	# must not decode actors, the dorm plate or the fourth-chapter guard.
	if incoming.is_empty(): return
	if player_frames.is_empty():
		for direction in ["down","up","side","left"]:
			var frames: Array = []
			for index in range(8):
				var path := "res://assets/rpg/player/player_%s_%d.png" % [direction,index]
				if ResourceLoader.exists(path): frames.append(load(path))
			player_frames[direction] = frames
		player_side_idle = load("res://assets/rpg/player/player_side_idle.png")
		if ResourceLoader.exists("res://assets/rpg/player/player_left_idle.png"):
			player_left_idle=load("res://assets/rpg/player/player_left_idle.png")
	if incoming=="dorm_hub" and not is_instance_valid(native_dorm):
		native_dorm=load(DORM_SCENE_SCRIPT).new();add_child(native_dorm);native_dorm.setup(self)
	if incoming=="duan_yongping_temporal_maze" and guard_model==null:
		guard_model=load("res://scripts/games/chapter4_guard_model.gd")
		guard_sheet=load("res://assets/rpg/npcs/finale/guard_walk_8frame.png")
		guard_sheets={"side":guard_sheet,"up":load("res://assets/rpg/npcs/finale/guard_walk_up_8frame.png"),"down":load("res://assets/rpg/npcs/finale/guard_walk_down_8frame.png")}
	if incoming=="duan_yongping_temporal_maze" and not is_instance_valid(room301_exhibit):
		room301_exhibit=load("res://scripts/objects/room301_exhibit_adapter.gd").new()
		add_child(room301_exhibit);room301_exhibit.setup(self)
	if incoming=="duan_yongping_temporal_maze" and chapter4_layers!=null and not is_instance_valid(elevator_button):
		elevator_button=load("res://scripts/objects/chapter4_elevator_button.gd").new()
		add_child(elevator_button);elevator_button.setup(self)
		chapter4_layers.elevator_button=elevator_button

func _receive_teleport(point: Array) -> void:
	if OS.has_feature("web"):
		var owner: Dictionary = State.d
		if not await WebContent.ensure_state(owner) or not is_inside_tree() or not is_same(owner, State.d): return
	pending_teleport = Vector2(float(point[0]),float(point[1]))
	refresh_world()

func refresh_world() -> void:
	if OS.has_feature("web") and not WebContent.ready_for_state(State.d): return
	if worlds.is_empty() or State.d.is_empty(): return
	if guard_capture.active and not guard_capture.matches(_guard_capture_context()): _cancel_guard_capture()
	if not stair_handoff.is_empty() and (State.d.native.scene!="duan_yongping_temporal_maze" or State.d.chapter4.phase!="final_chase" or State.d.chapter4.floor!="A2" or int(stair_handoff.attempt)!=int(State.d.chapter4.chaseAttempt)):stair_handoff.clear()
	var incoming := str(State.d.native.scene)
	_ensure_scene_visuals(incoming)
	if incoming=="canteen_interior" and not is_instance_valid(native_canteen):
		native_canteen=load(CANTEEN_SCENE_SCRIPT).new();add_child(native_canteen);native_canteen.setup(self)
	if is_instance_valid(native_dorm):native_dorm.sync(State.d,incoming)
	if is_instance_valid(native_canteen):native_canteen.sync(State.d,incoming)
	if incoming!=scene_id: _kayak_boundary_hint_at=-KAYAK_BOUNDARY_HINT_COOLDOWN_MS
	if library_layers!=null: library_layers.sync(State.d,incoming!=scene_id)
	library_door.sync(State.d,incoming!=scene_id)
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
	cancel_exploration_gestures()
	object_picker.clear()
	_cancel_floor_route()
	kayak_mouse_gesture.clear()
	world_key = key
	pan_offset = Vector2.ZERO
	scene_id = incoming
	player_turn.clear(); walk_clock=0
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
	# Wide source plates keep their exact authored coordinates, but never upload
	# one oversized GPU texture. Only the explicit lossless adapter opts in;
	# all ordinary interiors retain their original Texture2D path and depth.
	background_is_tiled=SourceTiledTexture.supports(image_path)
	if background_is_tiled:
		background=null
		background_tiles.configure(image_path)
	else:
		background_tiles=SourceTiledTexture.new()
		if not image_path.is_empty() and ResourceLoader.exists(State.asset(image_path)):background=load(State.asset(image_path))
		else:background=null
	if scene_id=="library_interior" and library_layers!=null and library_layers.rebuild.ready:background=library_layers.rebuild.clean_plate
	north_objects.configure(scene_id,floor_id,background)
	if is_instance_valid(north_props):north_props.sync()
	collisions=north_objects.adjusted_collisions(collisions)
	if is_instance_valid(room301_exhibit):
		room301_exhibit.configure(scene_id,floor_id,background)
		if room301_exhibit.active:collisions=Room301Layout.adjusted_collisions(collisions)
	if is_instance_valid(elevator_button):elevator_button.sync(State.d,scene_id,background)
	north_source_objects.configure(scene_id,floor_id,background,collisions)
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
	if not can_stand(player): player = _find_safe(player)
	transition_alpha = 1.0
	safe_player = player
	if kayak!=null: kayak.position = player
	lake_session=State.lake_module().bind_world(State.d,self) if State.lake_module()!=null else null
	move_target = Vector2.INF
	_manual_sent = bool(State.d.actOne.get("manualControlTested",false))
	_sync_player()
	_update_camera()
	if is_instance_valid(kayak_visual):kayak_visual.sync()
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
	for doorway:Rect2 in _door_collision_rects():
		if feet.intersects(doorway):return false
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

func _door_collision_rects()->Array[Rect2]:
	if scene_id=="library_interior":return library_door.collision_rects()
	if scene_id=="theater_interior" and chapter3_layers!=null:return chapter3_layers.doors.collision_rects()
	return []

func interior_door_snapshot()->Dictionary:
	# Detached measurements for ordinary input acceptance; no mutation port.
	if scene_id=="library_interior":
		return {"scene":scene_id,"opening":Rect2(644,681,212,86),"progress":library_door.progress,"visualProgress":library_door.progress,"sensorOpen":library_door.sensor_open,"accessGranted":library_door.access_granted,"leafRects":library_door.leaf_rects(),"collisionRects":library_door.collision_rects(),"playerFoot":PlayerMetrics.foot_rect(player),"departureHeld":false,"routeStatus":_floor_status,"routeWaypointCount":_floor_route.size()}
	if scene_id=="theater_interior" and chapter3_layers!=null:
		var door:RefCounted=chapter3_layers.doors
		return {"scene":scene_id,"opening":door.opening,"progress":door.progress,"visualProgress":door.visual_progress,"sensorOpen":door.sensor_open,"passable":door.passable(),"leafRects":door.leaf_rects(),"collisionRects":door.collision_rects(),"playerFoot":PlayerMetrics.foot_rect(player),"departureHeld":door.departure_held,"clockOwned":door.departure_clock_owned,"routeStatus":_floor_status,"routeWaypointCount":_floor_route.size()}
	return {}

func background_plate_snapshot()->Dictionary:
	# Detached presentation measurements for browser acceptance, never a scene
	# selector or a progression write port.
	if background_is_tiled:
		var snapshot:Dictionary=background_tiles.snapshot();snapshot["tiled"]=true
		return snapshot
	return {"tiled":false,"ready":background!=null,"source":str(spec.get("background","")),"sourceSize":background.get_size() if background!=null else Vector2.ZERO,"tileCount":0}

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
	return _distance_at(target,player)

func _distance_at(target:Dictionary,anchor:Vector2)->float:
	if target.get("follow_player",false): return 0.0
	var point := PlayerMetrics.foot_rect(anchor).get_center() if scene_id=="duan_yongping_temporal_maze" else anchor
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
		subtitle = "靠近后点一下物件。" if mobile_exploration else "靠近可交互的物品后按空格。"; subtitle_left = 2.4; return
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
	if mobile_exploration:
		mobile_confirmed_target_id=str(target.get("id",""));mobile_confirmed_world_key=world_key
	var action: String=str(target.get("action",target.get("id","")))
	var library_scan: bool=scene_id=="library_interior" and action=="lib_scan"
	# A refused identity check must not rotate the player toward the desk.
	if not target.get("follow_player",false) and not library_scan:
		_apply_player_motion(Vector2.ZERO,_target_point(target)-player,0)
	_sync_player()
	if target.get("action","")=="c4_reach202":
		guard_close_requested=true
		return
	if action=="c3_target:theater_exit" and is_instance_valid(host_node) and host_node.has_method("_begin_theater_departure") and host_node._begin_theater_departure():return
	var result: Dictionary=State.act(action,target.get("value"))
	# A successful counter interaction turns the original actor toward the clerk
	# once. Movement remains the ordinary facing authority afterwards.
	if library_scan and result.has("game"):
		player_turn.clear()
		facing="up"; player_flip=false; walk_clock=0
		_cancel_floor_route(); move_target=Vector2.INF
		queue_redraw()

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
	if _inventory_owns_pointer(): cancel_exploration_gestures()
	if not kayak_mouse_gesture.is_empty() and not _kayak_mouse_valid(): kayak_mouse_gesture.clear()
	if _floor_feedback_left>0:
		_floor_feedback_left=maxf(0,_floor_feedback_left-delta)
		if _floor_feedback_left==0 and _floor_route.is_empty(): _floor_goal=Vector2.INF; _floor_status=""
	if direct_gestures.has_active() and not direct_gestures.valid(_direct_gesture_context(),State.d):cancel_exploration_gestures()
	if not _floor_pending_interaction.is_empty() and not _floor_intent_valid():_cancel_floor_route()
	if not _floor_route.is_empty() and (capture_mode or presentation_actor_hidden or not is_visible_in_tree() or get_viewport().gui_is_dragging() or get_tree().root.gui_is_dragging() or not _floor_transform_current()): _cancel_floor_route()
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
	library_door.tick(delta,State.d)
	if chapter4_layers != null and scene_id == "duan_yongping_temporal_maze":
		chapter4_layers.tick(delta,State.d)
		queue_redraw()
	mode_mix = move_toward(mode_mix,1.0 if State.d.native.mode == "dark" else 0.0,delta*4.5)
	transition_alpha = maxf(0,transition_alpha-delta*2.0)
	if subtitle_left > 0 and not _exploration_overlay_blocked():
		subtitle_left -= delta
		if subtitle_left <= 0:
			var expired_revision:=subtitle_revision
			var expired_text:=subtitle
			subtitle="";subtitle_left=0
			subtitle_expired.emit(expired_revision,expired_text)
	queue_redraw()
	# Pause physical actors, while keeping the existing scene fades and visual
	# animation alive, as source physics.pause() does.
	if guard_capture.active:
		_tick_guard_capture(capture_delta_ms)
		return
	if _scene_presentation_blocks():
		cancel_exploration_gestures()
		return
	var shell = host_node
	if _shell_input_blocked():
		cancel_exploration_gestures()
		return
	if is_instance_valid(shell) and is_instance_valid(shell.get("world_effect")) and shell.world_effect.get_meta("blocks_input",false):cancel_exploration_gestures();return
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
	# Settle on-foot facing and animation once, after automatic and manual
	# movement, from the actual collision-resolved displacement.
	var walk_start := player
	var floor_route_finished := false
	if scene_id == "dorm_hub" and not State.d.actOne.get("controlsInstalled",false):
		move_target = Vector2.INF
		axis = Vector2.ZERO
		if State.d.actOne.get("exerciseStarted",false):
			var pace_x := 245 + (520 + sin(Time.get_ticks_msec()/900.0)*130)*.5
			var pace_position := Vector2(pace_x,player.y)
			if can_stand(pace_position): player = pace_position; _sync_player()
	# A zero-length route waypoint still needs its normal completion step.
	if axis.length_squared() > 0 or not _floor_route.is_empty():
		if mobile_exploration and _floor_route.is_empty(): pan_offset=Vector2.ZERO
		axis = axis.normalized()
		var speed := 208.0 if scene_id == "duan_yongping_temporal_maze" and State.d.chapter4.phase == "final_chase" else 176.0 if scene_id == "duan_yongping_temporal_maze" else 160.0 if scene_id == "dorm_hub" else 165.0
		if scene_id in ["canteen_interior","theater_interior","qizhen_lake"] and Input.is_key_pressed(KEY_SHIFT): speed = 228.0
		var displacement := axis*speed*delta
		var old := player
		var following_floor_route:=not _floor_route.is_empty()
		if following_floor_route:
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
		floor_route_finished = following_floor_route and _floor_route.is_empty()
		if old.distance_to(player) > 0:
			_sync_player()
			if scene_id == "dorm_hub" and State.d.actOne.get("movementEnabled",false) and not _manual_sent:
				_manual_sent = true
				State.act("c2_manual_input",{"moved":true,"distance":old.distance_to(player)*2,"input":_input_kind})
	var walked := player-walk_start
	_apply_player_motion(walked,axis,delta)
	# Arrival has no remaining movement input. Retire its walk frame now,
	# before rendering/picking, rather than one process tick after arrival.
	if floor_route_finished: walk_clock=0.0
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
	if floor_route_finished:_resolve_floor_interaction()

func _apply_player_motion(motion:Vector2,intent:Vector2,delta:float) -> void:
	var pose:=CharacterFacing.pose(motion,intent,facing,player_flip)
	var changed:bool=pose.facing!=facing or (pose.facing=="side" and pose.flip!=player_flip)
	if changed:
		player_turn={"from_facing":facing,"from_flip":player_flip and facing=="side","to_facing":pose.facing,"to_flip":pose.flip and pose.facing=="side","elapsed_ms":0.0,"duration_ms":CharacterFacing.turn_duration(facing,player_flip,pose.facing,pose.flip)}
	elif not player_turn.is_empty():
		player_turn.elapsed_ms+=maxf(0,delta)*1000
		if float(player_turn.elapsed_ms)>=float(player_turn.duration_ms):player_turn.clear()
	facing=pose.facing; player_flip=pose.flip
	walk_clock=walk_clock+maxf(0,delta) if motion.is_finite() and not motion.is_zero_approx() else 0.0

func player_visual() -> Dictionary:
	# One selection path for CanvasItem, native canteen Sprite2D and alpha picking.
	# A complete authored left cycle can replace the genuine side-view mirror.
	var pose:Dictionary=CharacterFacing.turn_pose(player_turn) if not player_turn.is_empty() and player_turn.to_facing==facing and (facing!="side" or player_turn.to_flip==player_flip) else {"facing":facing,"flip":player_flip,"angle":0.0}
	var direction:String=pose.facing
	var flip:bool=pose.flip and direction=="side"
	if flip and player_frames.get("left",[]).size()==8:
		direction="left"; flip=false
	var frames:Array=player_frames.get(direction,[])
	var texture:Texture2D=null
	if not frames.is_empty():
		texture=frames[PlayerMetrics.frame_at((walk_clock if player_turn.is_empty() else 0.0)*1000)%frames.size()]
		if walk_clock<=0 and player_turn.is_empty():
			if direction=="side" and player_side_idle!=null:texture=player_side_idle
			elif direction=="left" and player_left_idle!=null:texture=player_left_idle
	return {"texture":texture,"flip_h":flip,"direction":direction,"angle":float(pose.angle)}

func player_geometry() -> Dictionary:
	var actor:=player_visual()
	var angle:=deg_to_rad(float(actor.angle))
	# Rotate the entire original frame about its registered source anchor.
	return {"rect":PlayerMetrics.visual_rect(player,display_scale_at(player)),"texture":actor.texture,"flip_h":actor.flip_h,"transform":Transform2D(angle,player-player.rotated(angle))}

func _apply_guard_motion(motion:Vector2,intent:Vector2,delta:float) -> void:
	var pose:=CharacterFacing.pose(motion,intent,guard_facing,guard_flip)
	guard_facing=pose.facing; guard_flip=pose.flip
	guard_walk_clock=guard_walk_clock+maxf(0,delta) if motion.is_finite() and not motion.is_zero_approx() else 0.0

func guard_visual() -> Dictionary:
	var texture:Texture2D=guard_sheets.get(guard_facing,guard_sheet)
	var index:=PlayerMetrics.frame_at(guard_walk_clock*1000)
	var columns:=maxi(1,int(texture.get_width()/96)) if texture!=null else 1
	return {"texture":texture,"source":Rect2((index%columns)*96,int(index/columns)*128,96,128),"flip_h":guard_flip and guard_facing=="side","direction":guard_facing}

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
	var object_focus: Variant=host_node.get("object_focus") if is_instance_valid(host_node) else null
	if is_instance_valid(object_focus) and object_focus.apply_owned_camera():return
	# Source victory keeps the full room even while dialogue permits walking.
	# Honor the presentation owner before exploration, resize or pan can follow.
	var narrative: Variant=host_node.get("c3_narrative_host") if is_instance_valid(host_node) else null
	if is_instance_valid(narrative) and narrative.has_method("apply_owned_camera") and narrative.apply_owned_camera(): return
	var scene_owner:Variant=host_node.get("c3_scene_host") if is_instance_valid(host_node) else null
	var authored:bool=(is_instance_valid(scene_owner) and scene_owner.has_method("owns_world_contract") and scene_owner.owns_world_contract()) or (is_instance_valid(narrative) and narrative.has_method("owns_world_contract") and narrative.owns_world_contract())
	# Camera bounds use the unobscured screen region. Map coordinates, zoom,
	# collision and input transforms stay unchanged; only framing moves.
	camera=WorldOverlay.camera_for_safe_rect(player,pan_offset,size,world_size,zoom,Rect2(Vector2.ZERO,size) if capture_mode or font==null or authored else exploration_safe_rect(true))
	if kayak!=null and is_instance_valid(kayak_visual) and not capture_mode and not authored:
		kayak_visual.sync();kayak_visual.configure_view(size/2-camera*zoom,zoom)
		var occupied:Rect2=kayak_visual.visible_input_bounds()
		var safe:Rect2=exploration_safe_rect(true)
		var correction:=Vector2.ZERO
		for axis:int in range(2):
			if occupied.size[axis]>safe.size[axis]:correction[axis]=occupied.get_center()[axis]-safe.get_center()[axis]
			elif occupied.position[axis]<safe.position[axis]:correction[axis]=occupied.position[axis]-safe.position[axis]
			elif occupied.end[axis]>safe.end[axis]:correction[axis]=occupied.end[axis]-safe.end[axis]
		camera+=correction/maxf(.01,zoom)

func exploration_safe_rect(reserve_controls:bool=false) -> Rect2:
	var hud:=hud_metrics(_hud_line())
	var bottom:float=hud.body_rect.position.y
	if reserve_controls and is_instance_valid(host_node):
		var narrative:Variant=host_node.get("c3_narrative_host")
		var view:Variant=narrative.get("view") if is_instance_valid(narrative) else null
		if is_instance_valid(view) and view.is_visible_in_tree() and view.get_parent()==self:
			bottom=minf(bottom,view.panel.position.y-8)
	return Rect2(0,hud.header_height,size.x,maxf(1,bottom-float(hud.header_height)))

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
		if is_instance_valid(room301_exhibit) and room301_exhibit.owns_target(str(target.get("id",""))):continue
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
		var local:Vector2=(point-camera)*zoom+size/2
		var visible_local:=exploration_safe_rect()
		if not visible_local.has_point(local): return {}
		var visible_source:=Rect2(camera+(visible_local.position-size/2)/zoom,visible_local.size/zoom)
		return object_picker.pick_near_visible(point,targets,inventory_drop,14.0/zoom,visible_source,[])
	return object_picker.pick(point,targets,inventory_drop)

func _render_context() -> Dictionary:
	return {"origin":size/2-camera*zoom,"zoom":zoom,"player":player,"scene_id":scene_id,"floor":_last_floor,"nearby_id":str(nearby.get("id","")),"background":background,"mode_mix":mode_mix}
func _draw() -> void:
	if mobile_exploration:mobile_control_metrics()
	if is_instance_valid(elevator_button):elevator_button.sync(State.d,scene_id,background)
	if is_instance_valid(kayak_visual):kayak_visual.sync()
	if is_instance_valid(native_dorm):
		native_dorm.sync(State.d,scene_id)
		native_dorm.configure_view(size/2-camera*zoom,zoom)
	if is_instance_valid(north_props):north_props.sync()
	# Retire every existing adapter before a scene-specific early return.
	if is_instance_valid(room204_object):room204_object.sync(State.d,scene_id)
	if is_instance_valid(native_canteen):native_canteen.sync(State.d,scene_id)
	if is_instance_valid(north_source_objects) and north_source_objects.active:north_source_objects.configure_view(_render_context())
	if is_instance_valid(room301_exhibit):
		room301_exhibit.visible=room301_exhibit.active and Room301Layout.active(scene_id,_last_floor)
		if room301_exhibit.visible:
			room301_exhibit.configure_view(_render_context())
			return
	if is_instance_valid(native_canteen) and native_canteen.is_active():
		draw_rect(Rect2(Vector2.ZERO,size),Color("0c1b24"))
		native_canteen.configure_view(size/2-camera*zoom,zoom,player)
		return
	if is_instance_valid(room204_object):
		if room204_object.has_objects():
			room204_object.configure_view(size/2-camera*zoom,zoom)
			return
	if is_instance_valid(kayak_visual) and kayak_visual.active:
		draw_rect(Rect2(Vector2.ZERO,size),Color("0c1b24"))
		kayak_visual.configure_view(size/2-camera*zoom,zoom)
		return
	if is_instance_valid(north_props) and north_props.active:
		north_props.configure_view(size/2-camera*zoom,zoom,player,mode_mix)
		return
	if is_instance_valid(north_source_objects) and north_source_objects.active and north_source_objects.fallback:return
	object_picker.clear()
	_record_plate_targets()
	var context:=_render_context()
	_draw_base_pass(self,context)
	if scene_id.is_empty(): return
	if chapter4_layers!=null: chapter4_layers.draw_back(self,context,State.d)
	_draw_actor_pass(self,context)
	if chapter4_layers!=null: chapter4_layers.draw_front(self,context,State.d)
	_draw_tail_pass(self,context)
func draw_north_source_pass(canvas:CanvasItem,stage:int)->void:
	if not is_instance_valid(north_source_objects) or not north_source_objects.active:return
	var context:=_render_context()
	if stage in [0,3]:
		object_picker.clear();_record_plate_targets();_draw_base_pass(canvas,context)
	elif stage==1:
		if chapter4_layers!=null:chapter4_layers.draw_back(canvas,context,State.d)
		_draw_actor_pass(canvas,context)
	else:
		if stage==2 and chapter4_layers!=null:chapter4_layers.draw_front(canvas,context,State.d)
		_draw_tail_pass(canvas,context)

func draw_north_prop_pass(canvas:CanvasItem,stage:int)->void:
	if not is_instance_valid(north_props) or not north_props.active:return
	var context:=_render_context()
	if stage==0:
		object_picker.clear()
		_record_plate_targets()
		_draw_base_pass(canvas,context)
	elif stage==1:
		if chapter4_layers!=null:chapter4_layers.draw_back(canvas,context,State.d)
		_draw_actor_pass(canvas,context,true)
	elif stage==3:
		north_objects.draw_wall_reveal(canvas,context)
	else:
		_draw_actor_foreground_suffix(canvas,context)
		if chapter4_layers!=null:chapter4_layers.draw_front(canvas,context,State.d)
		_draw_tail_pass(canvas,context)

func draw_kayak_object_pass(canvas: CanvasItem,before: bool) -> void:
	if not is_instance_valid(kayak_visual) or not kayak_visual.active:return
	var context:=_render_context()
	if before:
		object_picker.clear()
		_record_plate_targets()
		_draw_base_pass(canvas,context)
		for target: Dictionary in _ordered_targets():
			if _target_point(target).y<=player.y:_draw_target(target,context.origin,canvas)
	else:
		_draw_actor_foreground(canvas,context)
		_draw_tail_pass(canvas,context)

func draw_room204_object_pass(canvas: CanvasItem,before: bool) -> void:
	if not is_instance_valid(room204_object) or not room204_object.has_objects(): return
	var context:=_render_context()
	var front: bool=room204_object.front_of_player(player)
	if before:
		object_picker.clear()
		_record_plate_targets()
		if north_source_objects.host_kind!="room204":_draw_base_pass(canvas,context)
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
		if north_source_objects.host_kind!="room204":_draw_tail_pass(canvas,context)
func _draw_base_pass(canvas: CanvasItem,layer_context: Dictionary) -> void:
	var origin: Vector2=layer_context.origin
	canvas.draw_rect(Rect2(Vector2.ZERO,size),Color("0c1b24"))
	if scene_id.is_empty(): return
	if background_is_tiled:
		if background_tiles.ensure_loaded():background_tiles.draw_region(canvas,Rect2(origin+background_rect.position*zoom,background_rect.size*zoom),Rect2(Vector2.ZERO,background_tiles.get_size()))
	elif background:
		var visual_plate:Texture2D=north_source_objects.clean_plate if is_instance_valid(north_source_objects) and north_source_objects.active else background
		canvas.draw_texture_rect(visual_plate,Rect2(origin+background_rect.position*zoom,background_rect.size*zoom),false)
	if scene_id=="theater_interior" and chapter3_layers!=null:
		chapter3_layers.theater_rebuild.draw_background(canvas,layer_context,State.d)
	north_objects.draw_background(canvas,layer_context)
	if is_instance_valid(room301_exhibit) and room301_exhibit.active:room301_exhibit.clean_floor(canvas,layer_context)
	canvas.draw_rect(Rect2(Vector2.ZERO,size),Color(.03,.15,.26,mode_mix*.3))
	_draw_floor_route(origin,canvas)
	if chapter3_layers!=null: chapter3_layers.draw_back(canvas,layer_context,State.d)
	if library_layers!=null: library_layers.draw_back(canvas,layer_context,State.d)
	library_door.draw(canvas,layer_context,false)
func _draw_actor_pass(canvas: CanvasItem,layer_context: Dictionary,defer_foreground:bool=false) -> void:
	var origin: Vector2=layer_context.origin
	north_objects.draw_objects(canvas,layer_context,false)
	var actor:Dictionary=player_visual()
	var ordered_targets: Array=_ordered_targets()
	for target in ordered_targets:
		if _target_point(target).y <= player.y: _draw_target(target,origin,canvas)
	if not presentation_actor_hidden and not kayak and actor.texture!=null:
		var frame:Texture2D=actor.texture
		var visual: Rect2 = PlayerMetrics.visual_rect(player,display_scale_at(player))
		draw_ellipse_shadow(origin+(player+Vector2(0,39))*zoom,Vector2(19,6)*zoom,canvas)
		var actor_ids: Array=[]
		for target: Dictionary in targets:
			if target.get("follow_player",false): actor_ids.push_front(str(target.id))
		if not actor_ids.is_empty(): register_object_surface(actor_ids,player_geometry())
		canvas.draw_set_transform(origin+player*zoom,deg_to_rad(float(actor.angle)),Vector2.ONE*zoom)
		canvas.draw_texture_rect(frame,Rect2(visual.position-player,Vector2(-visual.size.x,visual.size.y) if actor.flip_h else visual.size),false)
		canvas.draw_set_transform(Vector2.ZERO)
	if defer_foreground:_draw_actor_foreground_prefix(canvas,layer_context)
	else:_draw_actor_foreground(canvas,layer_context)

func _draw_actor_foreground(canvas: CanvasItem,layer_context: Dictionary) -> void:
	_draw_actor_foreground_prefix(canvas,layer_context)
	north_objects.draw_objects(canvas,layer_context,true)
	_draw_actor_foreground_suffix(canvas,layer_context)

func _draw_actor_foreground_prefix(canvas: CanvasItem,layer_context: Dictionary) -> void:
	var origin: Vector2=layer_context.origin
	var ordered_targets: Array=_ordered_targets()
	for target in ordered_targets:
		if _target_point(target).y > player.y: _draw_target(target,origin,canvas)
	if chapter3_layers!=null: chapter3_layers.draw_front(canvas,layer_context,State.d)

func _draw_actor_foreground_suffix(canvas: CanvasItem,layer_context: Dictionary) -> void:
	var origin:Vector2=layer_context.origin
	if background or background_is_tiled:
		for cover in foreground:
			if north_objects.owns_cover(cover):continue
			if scene_id=="theater_interior" and chapter3_layers!=null and chapter3_layers.theater_rebuild.owns_legacy_cover(cover): continue
			if scene_id=="duan_yongping_temporal_maze" and chapter4_layers!=null and chapter4_layers.bakery_foreground_below_player(cover,State.d): continue
			var baseline := float(cover.get("baselineY",cover.get("sortY",cover.get("bottom",0))))
			var alpha := 1.0 - float(cover.get("playerRevealAlpha",0.0))
			if scene_id=="canteen_interior" and chapter3_layers!=null:
				var occlusion: Dictionary=chapter3_layers.canteen_occlusion(cover,player,bool(State.d.native.settings.reduced_motion))
				if not occlusion.visible: continue
				alpha=occlusion.alpha
			elif player.y >= baseline: continue
			var region := _rect(cover.get("maskBounds",cover))
			var regions:Array[Rect2]=[]
			if scene_id=="library_interior":regions=library_door.foreground_regions(region)
			else:regions.append(region)
			for visible_region:Rect2 in regions:
				var dest:=Rect2(origin+visible_region.position*zoom,visible_region.size*zoom)
				if background_is_tiled:background_tiles.draw_region(canvas,dest,visible_region,Color(1,1,1,alpha))
				else:canvas.draw_texture_rect_region(background,dest,visible_region,Color(1,1,1,alpha))
	if chapter3_layers!=null: chapter3_layers.draw_landmarks(canvas,layer_context,State.d)
	if library_layers!=null: library_layers.draw_front(canvas,layer_context,State.d)
	library_door.draw(canvas,layer_context,true)
func _draw_tail_pass(canvas: CanvasItem,layer_context: Dictionary) -> void:
	var origin: Vector2=layer_context.origin
	if lake_session!=null: lake_session.draw(canvas,origin,zoom,bool(State.d.native.settings.reduced_motion))
	if guard_visible and guard_sheet:
		var guard_size := Vector2(96,128)*.68*zoom
		var actor:Dictionary=guard_visual()
		canvas.draw_set_transform(origin+guard_position*zoom,0,Vector2(-1 if actor.flip_h else 1,1))
		canvas.draw_texture_rect_region(actor.texture,Rect2(-Vector2(guard_size.x/2,guard_size.y*.89),guard_size),actor.source)
		canvas.draw_set_transform(Vector2.ZERO)
	var name_text := str(State.d.get("playerName",State.d.get("characterName","")))
	if not presentation_actor_hidden and not name_text.is_empty(): canvas.draw_string(font,origin+player*zoom+Vector2(-25,22),name_text,HORIZONTAL_ALIGNMENT_CENTER,100,14,Color.WHITE)
	if _exploration_overlay_blocked():
		if is_instance_valid(selected_overlay):selected_overlay.hide()
		if is_instance_valid(overflow_feedback):overflow_feedback.hide()
		if transition_alpha>0:canvas.draw_rect(Rect2(Vector2.ZERO,size),Color(.04,.08,.12,transition_alpha))
		return
	if scene_id=="campus_bootstrap":
		var campus_visible:=exploration_safe_rect()
		CampusWayfinding.draw_label(canvas,layer_context,font,hud_display_scale(),campus_visible)
	if capture_mode:
		if is_instance_valid(selected_overlay):selected_overlay.hide()
		if is_instance_valid(overflow_feedback):overflow_feedback.hide()
		return
	# An authored full-room film owns the image; navigation help must not
	# cover the source door/paper while its independent dialogue is visible.
	var narrative:Variant=host_node.get("c3_narrative_host") if is_instance_valid(host_node) else null
	var film:bool=is_instance_valid(narrative) and narrative.has_method("owns_world_contract") and narrative.owns_world_contract()
	if film and subtitle.is_empty():
		if is_instance_valid(selected_overlay):selected_overlay.hide()
		if is_instance_valid(overflow_feedback):overflow_feedback.hide()
		if transition_alpha>0:canvas.draw_rect(Rect2(Vector2.ZERO,size),Color(.04,.08,.12,transition_alpha))
		return
	var line := _hud_line()
	var hud := hud_metrics(line)
	# Native overlay is synchronized by Main outside CanvasItem drawing.
	# Standalone world fixtures retain their local presentation path.
	if not selected_overlay_is_native:_sync_selected_overlay()
	var body_rect:Rect2=hud.body_rect
	if is_instance_valid(overflow_feedback):overflow_feedback.visible=hud.body_overflow and hud.body_height>0 and (not subtitle.is_empty() or guard_capture.active)
	if film:body_rect.position.y=hud.body_gap
	var device:Variant=host_node.get("c3_device_panel") if is_instance_valid(host_node) else null
	var device_feedback:bool=is_instance_valid(device) and device.has_method("owns_feedback_surface") and device.owns_feedback_surface()
	if device_feedback and is_instance_valid(overflow_feedback): overflow_feedback.hide()
	if hud.body_height>0 and not device_feedback and (not subtitle.is_empty() or guard_capture.active):
		CampusMaterial.draw(canvas,body_rect,"paper")
		if hud.body_overflow and is_instance_valid(overflow_feedback):
			overflow_feedback.label.text=line;overflow_feedback.label.add_theme_font_size_override("font_size",hud.body_font)
			overflow_feedback.label.add_theme_color_override("font_color",CampusMaterial.INK)
			overflow_feedback.layout_body(Rect2(body_rect.position.x+hud.body_padding,body_rect.position.y+hud.body_inset,body_rect.size.x-hud.body_padding*2,body_rect.size.y-hud.body_inset*2),hud.body_content_height)
			overflow_feedback.show()
		else:
			canvas.draw_multiline_string(hud_font,Vector2(body_rect.position.x+hud.body_padding,body_rect.position.y+hud.body_inset+hud_font.get_ascent(hud.body_font)),line,HORIZONTAL_ALIGNMENT_CENTER,hud.body_width,hud.body_font,-1,CampusMaterial.INK)
	if transition_alpha > 0: canvas.draw_rect(Rect2(Vector2.ZERO,size),Color(.04,.08,.12,transition_alpha))

func _exploration_overlay_blocked()->bool:
	if capture_mode or _shell_input_blocked():return true
	if is_instance_valid(host_node):
		var frame:Variant=host_node.get("world_frame")
		if is_instance_valid(frame) and not frame.is_visible_in_tree():return true
		for key:String in ["c3_narrative_host","library_story_host"]:
			var owner:Variant=host_node.get(key)
			if is_instance_valid(owner) and owner.has_method("blocks_input") and owner.blocks_input():return true
	return false

func sync_selected_overlay_native(parent:Control,rect:Rect2)->void:
	if not is_instance_valid(selected_overlay):return
	if selected_overlay.get_parent()!=parent:selected_overlay.reparent(parent,false)
	selected_overlay_is_native=true
	selected_overlay_native_rect=rect
	selected_overlay.position=rect.position
	selected_overlay.clip_contents=true
	_sync_selected_overlay()

func _sync_selected_overlay()->void:
	if not is_instance_valid(selected_overlay):return
	var blocked:bool=_exploration_overlay_blocked()
	selected_overlay.visible=not blocked and transition_alpha<=0
	if blocked:
		if is_instance_valid(overflow_feedback):overflow_feedback.hide()
	if not selected_overlay.visible:return
	var title:Dictionary={"dorm_hub":"寝室","campus_bootstrap":"紫金港校区","library_interior":"基础图书馆","canteen_interior":"东食堂","theater_interior":"剧场","qizhen_lake":"启真湖","duan_yongping_temporal_maze":"段永平教学楼","campus_qizhen_loop":"通往启真湖的路"}
	var hud:Dictionary=hud_metrics(_hud_line())
	var display:float=hud_display_scale()
	var extent:Vector2=selected_overlay_native_rect.size if selected_overlay_is_native else size
	var mode_rect:Rect2=Rect2(hud.mode_rect.position*display,hud.mode_rect.size*display) if selected_overlay_is_native else hud.mode_rect
	# Idle control prose is not painted behind the selected interaction label.
	# Use the real lower safe edge instead of reserving an invisible feedback row.
	var safe_bottom:float=size.y-hud.body_gap
	if is_instance_valid(host_node) and is_instance_valid(host_node.get("world_tasks")):
		safe_bottom=minf(safe_bottom,(host_node.world_tasks.get_global_rect().position.y-host_node.world_view.get_global_rect().position.y)/display-hud.body_gap)
	var bottom:float=safe_bottom*display if selected_overlay_is_native else safe_bottom
	selected_overlay.mobile_exploration=mobile_exploration
	selected_overlay.sync_view(extent,1.0 if selected_overlay_is_native else display,str(title.get(scene_id,scene_id)),State.objective(),str((_mobile_confirmed_target() if mobile_exploration else nearby).get("label","")) if subtitle.is_empty() and not _interaction_presentation_blocks() else "","深色观察" if State.d.native.mode=="dark" else "浅色操作",mode_rect,bottom,str(host_node.phone_chrome.time_label.text) if is_instance_valid(host_node) and is_instance_valid(host_node.phone_chrome) else "",str((_mobile_confirmed_target() if mobile_exploration else nearby).get("hud_prompt","")))

func _mobile_confirmed_target() -> Dictionary:
	if mobile_confirmed_target_id.is_empty(): return {}
	if mobile_confirmed_world_key==world_key and not _interaction_presentation_blocks() and not _shell_input_blocked():
		for target:Dictionary in targets:
			if str(target.get("id",""))==mobile_confirmed_target_id and _distance(target)<=float(target.get("radius",100))*(.5 if scene_id=="dorm_hub" else 1.0): return target
	mobile_confirmed_target_id=""; mobile_confirmed_world_key=""
	return {}

func _hud_line() -> String:
	if guard_capture.active:return "保安："+GuardCapture.LINE
	if not subtitle.is_empty(): return subtitle
	var label_target:Dictionary=_mobile_confirmed_target() if mobile_exploration else nearby
	if not label_target.is_empty(): return ("点物件 · " if mobile_exploration else "空格 · ")+str(label_target.get("hud_prompt",label_target.get("label","")))
	if kayak: return "点船桨或在艇侧上划 · 下划后退" if mobile_exploration else "A / D 左右划桨 · S + 划桨后退"
	return "点地面行走 · 点物件查看 · 双指查看地图" if mobile_exploration else "WASD 移动  /  空格 交互  /  滚轮 缩放"

func hud_display_scale() -> float:
	# The world lives in a SubViewport; its local transform cannot see the
	# outer phone/desktop presentation scale. Read the real display rectangle.
	if is_instance_valid(host_node) and is_instance_valid(host_node.world_view):
		var view: Control=host_node.world_view
		return maxf(0.01,absf(view.get_global_transform_with_canvas().get_scale().x)*view.size.x/maxf(size.x,1.0))
	return 1.0

func hud_metrics(text: String) -> Dictionary:
	var hud:=WorldOverlay.hud(hud_font,size,hud_display_scale(),text,mobile_exploration,float(State.d.native.settings.get("text_scale",1.0)))
	# The visible mode control belongs to the same root-space footer as the
	# phone/bag/journal. Expose its actual rectangle; no invisible top hit area.
	if is_instance_valid(host_node) and is_instance_valid(host_node.get("world_mode")) and is_instance_valid(host_node.get("world_view")):
		hud.header_height=0.0
		var surface:Control=host_node.world_view
		var mode:Control=host_node.world_mode
		var physical:Rect2=mode.get_global_rect()
		var display:float=hud_display_scale()
		hud.mode_rect=Rect2((physical.position-surface.get_global_rect().position)/display,physical.size/display)
	var narrative:Variant=host_node.get("c3_narrative_host") if is_instance_valid(host_node) else null
	if subtitle.is_empty() and is_instance_valid(narrative) and narrative.blocks_input() and (not narrative.has_method("owns_world_contract") or not narrative.owns_world_contract()):
		# The dialogue supplies the useful text. Retire idle movement prose so
		# enlarged dialogue and the movement targets retain separate regions.
		hud.body_height=0.0;hud.body_overflow=false
	var bottom:float=size.y-hud.body_gap
	if is_instance_valid(host_node) and is_instance_valid(host_node.get("world_tasks")) and is_instance_valid(host_node.get("world_view")):
		bottom=minf(bottom,(host_node.world_tasks.get_global_rect().position.y-host_node.world_view.get_global_rect().position.y)/hud_display_scale()-hud.body_gap)
	# Library's root-space dialogue can coexist with earned system feedback.
	# Stack the feedback above the dialogue, converting display coordinates once.
	if is_instance_valid(host_node):
		var story:Variant=host_node.get("library_story_host")
		if subtitle.is_empty() and is_instance_valid(story) and story.blocks_input():
			hud.body_height=0.0;hud.body_overflow=false
		# The story host owns visible prose while active. Keep the world's
		# footer stable so hidden feedback cannot shift the exploration camera.
	var available:float=maxf(1,bottom-hud.header_height-hud.body_gap)
	if hud.body_height>available:
		hud.body_height=available;hud.body_inset=minf(hud.body_inset,maxf(0,(available-1)/2));hud.body_overflow=true
	var surface_width: float=minf(size.x-hud.body_gap*2,hud.body_width+hud.body_padding*2)
	hud.body_rect=Rect2((size.x-surface_width)/2,maxf(hud.header_height+hud.body_gap,bottom-hud.body_height),surface_width,hud.body_height)
	return hud

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
	if (mobile_exploration or touch_controls or event is InputEventScreenTouch or event is InputEventScreenDrag) and _mobile_exploration_input(event): return
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
			if not clicked.is_empty():
				var limit:float=float(clicked.get("radius",100))*(.5 if scene_id=="dorm_hub" else 1.0)
				if _distance(clicked)<=limit or not _queue_target_approach(clicked):_try_interact(clicked)
			else:_mobile_floor_tap(event.position)
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
	if data.get("kind")=="inventory_item" and is_instance_valid(host_node) and is_instance_valid(host_node.get("world_view")):
		at_position=host_node.world_view.release_source_position(at_position,data)
	if not at_position.is_finite():return
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
			if not exploration_safe_rect().has_point(at_position) or not _floor_visible_rect().has_point(point): return
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
	_cancel_floor_route();move_target=Vector2.INF;touch_axis=Vector2.ZERO;direct_gestures.cancel()
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
		guard_facing="side"; guard_flip=false; guard_walk_clock=0
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
			if guard_clock_ms>=guard_repath_ms or guard_position.distance_to(guard_navigation_target)<10:
				var path: Array=guard_navigation.path(guard_position,foot if same_floor else Vector2(1001,214))
				guard_navigation_target=path[0] if not path.is_empty() else Vector2.INF
				guard_repath_ms=guard_clock_ms+260
			if guard_navigation_target!=Vector2.INF and guard_position.distance_squared_to(guard_navigation_target)>4:
				velocity=guard_position.direction_to(guard_navigation_target)*174
	var change:=velocity*delta
	var previous_guard:=guard_position
	if _guard_can_stand(guard_position+Vector2(change.x,0),walls): guard_position.x+=change.x
	if _guard_can_stand(guard_position+Vector2(0,change.y),walls): guard_position.y+=change.y
	_apply_guard_motion(guard_position-previous_guard,velocity,delta)

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
	elif what==NOTIFICATION_WM_WINDOW_FOCUS_OUT:cancel_exploration_gestures()
	elif what==NOTIFICATION_VISIBILITY_CHANGED and is_inside_tree() and not is_visible_in_tree():cancel_exploration_gestures()
	elif what==NOTIFICATION_RESIZED:cancel_exploration_gestures()

func cancel_exploration_gestures() -> void:
	_cancel_table_drag()
	touch_axis=Vector2.ZERO;move_target=Vector2.INF
	mobile_confirmed_target_id="";mobile_confirmed_world_key=""
	if direct_gestures!=null:direct_gestures.cancel()
	kayak_mouse_gesture.clear()
	_cancel_floor_route()

func kayak_paddle_rects() -> Dictionary:
	if kayak==null or not is_instance_valid(kayak_visual):return {}
	kayak_visual.sync();kayak_visual.configure_view(size/2-camera*zoom,zoom)
	return {"left":kayak_visual.paddle_input_bounds("left"),"right":kayak_visual.paddle_input_bounds("right")}

func _kayak_mouse_context() -> Array:
	return [world_key,size,host_node.world_view.get_global_rect() if is_instance_valid(host_node) else get_global_rect(),kayak.get_instance_id() if kayak!=null else 0]

func _kayak_mouse_valid() -> bool:
	if kayak==null or not is_visible_in_tree() or _interaction_presentation_blocks() or _shell_input_blocked() or capture_mode: return false
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
	return direct_gestures.owns_side(side)

func _kayak_mouse_input(event: InputEvent) -> bool:
	if kayak==null:return false
	# A finger already has its own source route. Its emulated mouse is never a
	# second stroke; a real simultaneous pointer cannot claim the same paddle.
	if event is InputEventScreenTouch and event.pressed and not kayak_mouse_gesture.is_empty():
		return _direct_touch_role(event.position) in ["paddle_"+str(kayak_mouse_gesture.side),"water_"+str(kayak_mouse_gesture.side)]
	if not (event is InputEventMouseButton or event is InputEventMouseMotion): return false
	if event.device==-1: return true
	if not kayak_mouse_gesture.is_empty():
		var copy: InputEvent=event.duplicate(); copy.position=_kayak_root_point(event.position)
		return handle_root_kayak_pointer(copy)
	if not event is InputEventMouseButton or event.button_index!=MOUSE_BUTTON_LEFT or not event.pressed: return false
	var role:String=_direct_touch_role(event.position)
	if role.begins_with("paddle_") or role.begins_with("water_"):
		var side:String=role.get_slice("_",1)
		if _kayak_finger_owns(side):return true
		var point:=_kayak_root_point(event.position)
		kayak_mouse_gesture={"side":side,"role":role,"start":point,"last":point,"context":_kayak_mouse_context(),"scale":hud_display_scale()}
		_cancel_floor_route();grab_focus();queue_redraw();return true
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
		if not str(gesture.get("role","paddle_")).begins_with("water_") or event.position.distance_to(gesture.start)/maxf(.01,float(gesture.scale))>10:
			State.lake_world_stroke(self,str(gesture.side),(event.position.y-gesture.start.y)/maxf(.01,float(gesture.scale))>24)
		queue_redraw()
	return true

func mobile_control_metrics() -> Dictionary:
	var metrics:Dictionary={"scheme":"direct_world","gestureArea":exploration_safe_rect(true),"mode":hud_mode_rect(),"paddles":kayak_paddle_rects()}
	if mobile_exploration and is_visible_in_tree():
		mobile_control_observation={"frame":Engine.get_process_frames(),"world_key":world_key,"size":size,"display_scale":hud_display_scale(),"metrics":metrics}
	return metrics

func _inventory_owns_pointer() -> bool:
	if is_instance_valid(InventoryGesture.touch_owner()): return true
	if not is_inside_tree() or not get_tree().root.gui_is_dragging(): return false
	var data:Variant=get_tree().root.gui_get_drag_data()
	return data is Dictionary and data.get("kind","")=="inventory_item"

func _mobile_local_from_root(point: Vector2) -> Vector2:
	if not is_instance_valid(host_node): return get_global_transform_with_canvas().affine_inverse()*point
	var view: Control=host_node.world_view
	var pixel:Vector2=view.get_global_transform_with_canvas().affine_inverse()*point
	pixel*=Vector2(get_viewport().size)/Vector2(maxf(1,view.size.x),maxf(1,view.size.y))
	return get_global_transform_with_canvas().affine_inverse()*pixel

func handle_root_exploration_pointer(event: InputEvent) -> bool:
	# GUI owns acquisition. Capture only an existing scene pointer; inventory,
	# native furniture dragging and modal presses retain their original owner.
	var id:int=-999
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		if event is InputEventScreenTouch and event.pressed:return false
		id=event.index
	elif event is InputEventMouseButton or event is InputEventMouseMotion:
		if event is InputEventMouseButton and (event.button_index!=MOUSE_BUTTON_LEFT or event.pressed):return false
	else:return false
	if not direct_gestures.pointers.has(id):return false
	if capture_mode or not is_visible_in_tree() or _scene_presentation_blocks() or _shell_input_blocked() or _inventory_owns_pointer() or not direct_gestures.valid(_direct_gesture_context(),State.d):
		cancel_exploration_gestures();return true
	if is_instance_valid(host_node) and (not host_node.world_frame.is_visible_in_tree() or (is_instance_valid(host_node.get("world_effect")) and host_node.world_effect.get_meta("blocks_input",false))):
		cancel_exploration_gestures();return true
	if direct_gestures.pointers[id].role=="furniture" or get_viewport().gui_is_dragging() or get_tree().root.gui_is_dragging():return false
	var copy:InputEvent=event.duplicate()
	copy.position=_mobile_local_from_root(event.position)
	if copy is InputEventMouse:copy.global_position=copy.position
	_mobile_exploration_input(copy)
	return true

func _begin_direct_pointer(id:int,point:Vector2,role:String)->void:
	var duplicate:bool=direct_gestures.pointers.has(id)
	_direct_gesture_action(direct_gestures.begin(id,point,role,_direct_gesture_context(),State.d))
	if not duplicate and direct_gestures.pointers.has(id):
		var target:Dictionary=_pick_target((point-size/2)/zoom+camera) if role=="map" else {}
		direct_gestures.pointers[id]["target_id"]=str(target.get("id",""))

func _end_direct_pointer(id:int,point:Vector2,canceled:bool)->void:
	if direct_gestures.pointers.has(id) and direct_gestures.pointers[id].role=="map":
		var target:Dictionary=_pick_target((point-size/2)/zoom+camera)
		canceled=canceled or str(target.get("id",""))!=str(direct_gestures.pointers[id].get("target_id",""))
	_direct_gesture_action(direct_gestures.end(id,point,canceled or not Rect2(Vector2.ZERO,size).has_point(point),_direct_gesture_context(),State.d))

func _direct_gesture_context()->Array:
	return [world_key,str(State.d.get("runtimeMode","")),str(State.d.get("native",{}).get("scene","")),size,camera,zoom,host_node.world_view.get_global_rect() if is_instance_valid(host_node) else get_global_rect()]

func _direct_touch_role(local:Vector2)->String:
	if hud_mode_rect().has_point(local):return "mode"
	if not exploration_safe_rect(true).has_point(local):return "ignored"
	var point:Vector2=(local-size/2)/zoom+camera
	if chapter4_layers!=null and scene_id=="duan_yongping_temporal_maze" and not chapter4_layers.pick_drag(point,State.d).is_empty():return "furniture"
	if kayak!=null:
		# Real entities keep their authored hit/distance/mode rules before water.
		if not _pick_target(point).is_empty():return "map"
		var paddles:Dictionary=kayak_paddle_rects()
		var side:String=kayak_visual.paddle_side_at(local,paddles)
		if not side.is_empty():return "paddle_"+side
		# A stroke may start in the visible water beside the moving boat. A tap
		# on this water stays neutral; the actual paddle still accepts a tap.
		var beside:Vector2=(point-player).rotated(-float(kayak.heading)-PI/2)
		if absf(beside.x)>=28 and absf(beside.x)<=180 and absf(beside.y)<=140 and can_stand(point):return "water_"+("left" if beside.x<0 else "right")
	return "map"

func _mobile_pan(delta: Vector2) -> void:
	_cancel_floor_route()
	var limit:=size*.35/zoom
	pan_offset=(pan_offset-delta/zoom).clamp(-limit,limit)
	move_target=Vector2.INF
	_update_camera(); queue_redraw()

func _direct_gesture_action(action:Dictionary)->void:
	if action.is_empty():return
	match str(action.kind):
		"tap":_mobile_floor_tap(action.point)
		"pan":
			_mobile_pan(action.delta);direct_gestures.context=_direct_gesture_context()
		"camera":
			_cancel_floor_route();move_target=Vector2.INF
			var before:Vector2=(Vector2(action.center)-Vector2(action.delta)-size/2)/zoom+camera
			zoom=clampf(zoom*float(action.ratio),.45,1.6)
			_update_camera()
			var after:Vector2=(Vector2(action.center)-size/2)/zoom+camera
			var limit:Vector2=size*.35/zoom
			pan_offset=(pan_offset+before-after).clamp(-limit,limit)
			_update_camera();queue_redraw()
			direct_gestures.context=_direct_gesture_context()
		"stroke":State.lake_world_stroke(self,str(action.side),bool(action.reverse))
		"mode":
			cancel_exploration_gestures()
			if not _interaction_presentation_blocks():State.toggle_mode()

func _mobile_exploration_input(event: InputEvent) -> bool:
	# This is a direct scene surface. The map never reserves invisible controls.
	if (event is InputEventMouseButton or event is InputEventMouseMotion) and event.device==-1:return true
	if event is InputEventKey and event.pressed:_cancel_floor_route()
	if event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_RIGHT or event.button_mask & MOUSE_BUTTON_MASK_MIDDLE):
		direct_gestures.cancel();_mobile_pan(event.relative);accept_event();return true
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed:
			var role:String=_direct_touch_role(event.position)
			# Preserve Godot's real furniture drag owner, including overlapping
			# targets. A press never opens that target or starts a floor route.
			if role=="furniture":_cancel_floor_route();return false
			_cancel_floor_route();grab_focus()
			_begin_direct_pointer(-999,event.position,role)
		else:_end_direct_pointer(-999,event.position,false)
		accept_event();return true
	if event is InputEventMouseMotion and direct_gestures.pointers.has(-999):
		_direct_gesture_action(direct_gestures.drag(-999,event.position,_direct_gesture_context(),State.d));accept_event();return true
	if event is InputEventScreenTouch:
		touch_controls=true;_input_kind="touch"
		if event.pressed:
			_cancel_floor_route();grab_focus()
			_begin_direct_pointer(event.index,event.position,_direct_touch_role(event.position))
		else:_end_direct_pointer(event.index,event.position,event.canceled)
		accept_event();return true
	if event is InputEventScreenDrag:
		_direct_gesture_action(direct_gestures.drag(event.index,event.position,_direct_gesture_context(),State.d));accept_event();return true
	return false

func _cancel_floor_route() -> void:
	_floor_route.clear(); _floor_goal=Vector2.INF; _floor_status=""; _floor_feedback_left=0
	_floor_pending_interaction.clear();_floor_intent_state={}

func _stop_floor_route() -> void:
	_floor_route.clear(); move_target=Vector2.INF; _floor_status="blocked"; _floor_feedback_left=.9
	_floor_pending_interaction.clear();_floor_intent_state={}

func _floor_transform_current() -> bool:
	return world_key==_floor_world_key and size==_floor_view_size and is_equal_approx(zoom,_floor_view_zoom) and camera.is_equal_approx(_floor_expected_camera)

func _floor_visible_rect() -> Rect2:
	var local:=exploration_safe_rect()
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
	for doorway:Rect2 in _door_collision_rects():obstacles.append(Rect2(doorway.position-feet.end,doorway.size+feet.size))
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
	var visible:=exploration_safe_rect(true)
	if not visible.has_point(local): return false
	for surface: Dictionary in object_picker.surfaces:
		if surface.painted and object_picker.contains(surface.geometry,point): return false
	var actor:Dictionary=player_visual()
	if actor.texture!=null:
		if object_picker.contains(player_geometry(),point): return false
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

func _floor_phase_context()->Array:
	var n:Dictionary=State.d.get("native",{});var ui:Dictionary=State.d.get("ui",{})
	var lake:Dictionary=State.d.get("qizhenLake",{});var chapter:Dictionary=State.d.get("chapter4",{})
	return [str(State.d.get("runtimeMode","")),str(n.get("scene","")),str(n.get("mode","")),str(n.get("selected_item","")),str(State.d.get("actOne",{}).get("phase","")),str(ui.get("libraryFinalsPhase","")),str(State.d.get("canteenHunt",{}).get("phase","")),str(State.d.get("theaterHunt",{}).get("phase","")),str(lake.get("phase","")),str(lake.get("zone","")),str(lake.get("vehicle","")),str(chapter.get("phase","")),str(chapter.get("floor","")),str(chapter.get("timeState",""))]

func _floor_intent_valid()->bool:
	if _floor_pending_interaction.is_empty() or not is_same(_floor_intent_state,State.d) or _floor_pending_interaction.world_key!=world_key or _floor_pending_interaction.phase!=_floor_phase_context():return false
	if _interaction_presentation_blocks() or _shell_input_blocked() or not is_visible_in_tree():return false
	for target:Dictionary in targets:
		if str(target.get("id",""))==str(_floor_pending_interaction.target.get("id","")):return target==_floor_pending_interaction.target
	return false

func _queue_target_approach(target:Dictionary)->bool:
	if kayak!=null or _interaction_presentation_blocks() or (scene_id=="dorm_hub" and (not State.d.actOne.get("controlsInstalled",false) or not State.d.actOne.get("movementEnabled",false))):return false
	var limit:float=float(target.get("radius",100))*(.5 if scene_id=="dorm_hub" else 1.0)
	var area:=Rect2(_target_point(target),Vector2.ZERO)
	if target.has("bounds"):
		var raw:Variant=target.bounds
		area=Rect2(float(raw[0]),float(raw[1]),float(raw[2]),float(raw[3])) if raw is Array else _rect(raw)
		if scene_id=="dorm_hub":area=Rect2(area.position*.5+Vector2(245,0),area.size*.5)
	var authored:=Vector2.INF
	if target.has("stand"):
		var raw:Variant=target.stand
		if raw is Dictionary:authored=Vector2(float(raw.x),float(raw.y))
		elif raw is Array and raw.size()>=2:authored=Vector2(float(raw[0]),float(raw[1]))
		if scene_id=="dorm_hub" and authored.is_finite():authored=authored*.5+Vector2(245,0)
	_floor_bounds=_floor_anchor_bounds(_floor_visible_rect())
	var offset:Vector2=PlayerMetrics.FOOT_CENTER_OFFSET if scene_id=="duan_yongping_temporal_maze" else Vector2.ZERO
	var obstacles:Array=_floor_obstacles();var attempts:=0
	for goal:Vector2 in TargetApproach.candidates(player,area,limit,offset,authored):
		if not _floor_stand(goal) or _distance_at(target,goal)>limit:continue
		attempts+=1
		var route:Array[Vector2]=_floor_planner.plan(player,goal,obstacles,_floor_bounds,_floor_stand,func(a:Vector2,b:Vector2):return _floor_segment_clear(a,b,obstacles,true))
		if not route.is_empty():
			_floor_route=route;_floor_goal=goal+PlayerMetrics.FOOT_CENTER_OFFSET;_floor_status="moving"
			_floor_world_key=world_key;_floor_view_size=size;_floor_view_zoom=zoom;_floor_expected_camera=camera
			_floor_intent_state=State.d
			_floor_pending_interaction={"target":target.duplicate(true),"world_key":world_key,"phase":_floor_phase_context()}
			grab_focus();queue_redraw();return true
		if attempts>=TargetApproach.MAX_PLANS:break
	return false

func _resolve_floor_interaction()->void:
	if _floor_pending_interaction.is_empty():return
	if not _floor_intent_valid():_cancel_floor_route();return
	var current:Dictionary={}
	for target:Dictionary in targets:
		if str(target.get("id",""))==str(_floor_pending_interaction.target.get("id","")):current=target;break
	_floor_pending_interaction.clear();_floor_intent_state={}
	if not current.is_empty():_try_interact(current)

func _mobile_floor_tap(local: Vector2) -> void:
	_cancel_floor_route(); move_target=Vector2.INF
	if presentation_actor_hidden or capture_mode or _scene_presentation_blocks() or _shell_input_blocked(): return
	if get_viewport().gui_is_dragging() or get_tree().root.gui_is_dragging(): return
	var visible:=exploration_safe_rect(true)
	if not visible.has_point(local): return
	var point: Vector2=(local-size/2)/zoom+camera
	# Furniture owns the press before overlapping targets, as in canonical input.
	if chapter4_layers!=null and scene_id=="duan_yongping_temporal_maze" and not chapter4_layers.pick_drag(point,State.d).is_empty(): return
	var clicked:=_pick_target(point)
	if not clicked.is_empty():
		var limit:float=float(clicked.get("radius",100))*(.5 if scene_id=="dorm_hub" else 1.0)
		if _distance(clicked)>limit and _queue_target_approach(clicked):return
		_try_interact(clicked);return
	if kayak or (scene_id=="dorm_hub" and (not State.d.actOne.get("controlsInstalled",false) or not State.d.actOne.get("movementEnabled",false))): return
	# Painted occluders and actor pixels are not empty floor. Selection stays
	# entirely with the unchanged picker; this route never chooses a target.
	for surface: Dictionary in object_picker.surfaces:
		if surface.painted and object_picker.contains(surface.geometry,point): return
	var actor:Dictionary=player_visual()
	if actor.texture!=null:
		if object_picker.contains(player_geometry(),point): return
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
