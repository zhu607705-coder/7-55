extends Node2D
## One source-pixel call plate. The world compositor owns depth/input dispatch;
## this object owns its image, measured hit geometry and transient press feedback.
const Picker=preload("res://scripts/world_object_picker.gd")
const SOURCE_RECTS={
	"A1":Rect2(812,106,12,24),
	"A2":Rect2(835,101,12,23),
	"A3":Rect2(828,88,14,24)
}
const PRESS_MS=220
const LAMP_MS=520
static var layout:Dictionary={}
var world:Control
var appearance:Sprite2D
var active:=false
var floor_id:=""
var source_rect:=Rect2()
var owner_state:Dictionary={}
var pressed_at:=-10000

static func collision_rects(state:Dictionary)->Array:
	# Ordinary movement stops at the visible closed-door sill. The existing
	# transport presentation owns its boarding actor and does not move this body.
	if state.get("native",{}).get("scene","")!="duan_yongping_temporal_maze":return []
	if layout.is_empty():layout=JSON.parse_string(FileAccess.get_file_as_string("res://data/source/chapter4-three-floor-maze.layout.json"))
	for floor:Dictionary in layout.floors:
		if floor.storyFloor!=state.get("chapter4",{}).get("floor",""):continue
		var b:Dictionary=floor.elevator.visibleBounds
		return [Rect2(float(b.x),float(b.y)+float(b.height)-10,float(b.width),10)]
	return []

func setup(owner_world:Control)->void:
	world=owner_world;name="Chapter4ElevatorButton"
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	appearance=Sprite2D.new();appearance.name="OriginalCallPlate";appearance.centered=false
	appearance.region_enabled=true;appearance.region_filter_clip_enabled=true
	# The same sprite is painted through the existing before-player pass, so it
	# keeps the authored depth in ordinary, room204 and room301 compositor paths.
	appearance.hide();add_child(appearance)
	var state_node=world.get_node("/root/State")
	state_node.action_completed.connect(_action_completed)

func sync(state:Dictionary,scene_id:String,plate:Texture2D)->void:
	var next_floor:String=str(state.get("chapter4",{}).get("floor",""))
	active=scene_id=="duan_yongping_temporal_maze" and SOURCE_RECTS.has(next_floor) and plate!=null
	if not active:
		floor_id="";pressed_at=-10000;return
	if floor_id!=next_floor or not is_same(owner_state,state):pressed_at=-10000
	owner_state=state;floor_id=next_floor;source_rect=SOURCE_RECTS[floor_id]
	position=source_rect.position
	appearance.texture=plate;appearance.region_rect=source_rect
	set_meta("source_rect",source_rect)

func owns_target(id:String)->bool:
	return active and id in ["main_elevator","elevator_record"]

func target_ids(state:Dictionary)->Array:
	return ["elevator_record","main_elevator"] if state.get("native",{}).get("mode","")=="dark" else ["main_elevator"]

func geometry()->Dictionary:return {"rect":source_rect}

func paint(canvas:CanvasItem,context:Dictionary,state:Dictionary)->void:
	if not active or appearance.texture==null:return
	var tint:Color=Color.WHITE.lerp(Color(.03,.15,.26),float(context.get("mode_mix",0))*.3)
	canvas.draw_set_transform(context.get("origin",Vector2.ZERO),0,Vector2.ONE*float(context.get("zoom",1)))
	canvas.draw_texture_rect_region(appearance.texture,source_rect,appearance.region_rect,tint)
	var elapsed:int=Time.get_ticks_msec()-pressed_at
	if elapsed<PRESS_MS:
		canvas.draw_rect(source_rect.grow(-2),Color(0,0,0,.24))
	if elapsed<LAMP_MS:
		var lamp:=Rect2(source_rect.position+Vector2(4,5),Vector2(maxf(3,source_rect.size.x-8),3))
		canvas.draw_rect(lamp,Color("f0cb78",1-float(maxi(0,elapsed-PRESS_MS))/(LAMP_MS-PRESS_MS)))
	canvas.draw_set_transform(Vector2.ZERO)
	Picker.record(canvas,target_ids(state),geometry())

func _input(event:InputEvent)->void:
	if not active or not is_instance_valid(world) or world._shell_input_blocked():return
	var point:=Vector2.INF
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:point=event.position
	elif event is InputEventScreenTouch and event.pressed:point=event.position
	if not point.is_finite():return
	var source_point:Vector2=(point-world.size/2)/world.zoom+world.camera
	if not source_rect.has_point(source_point):return
	var target:Dictionary=world._pick_target(source_point)
	if not owns_target(str(target.get("id",""))) or world._distance(target)>float(target.get("radius",0)):return
	pressed_at=Time.get_ticks_msec();world.queue_redraw()

func _action_completed(action:String,previous:Dictionary,_next:Dictionary,_result:Dictionary)->void:
	if not active or action not in ["c4_elevator","c4_record"]:return
	if previous.get("native",{}).get("scene","")!="duan_yongping_temporal_maze" or previous.get("chapter4",{}).get("floor","")!=floor_id:return
	pressed_at=Time.get_ticks_msec();world.queue_redraw()

func snapshot()->Dictionary:
	return {"active":active,"floor":floor_id,"sourceRect":[source_rect.position.x,source_rect.position.y,source_rect.size.x,source_rect.size.y],"pressed":Time.get_ticks_msec()-pressed_at<PRESS_MS}
