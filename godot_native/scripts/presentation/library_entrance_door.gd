extends RefCounted
## LibraryInteriorModel source geometry. Motion and obstruction are runtime-only;
## only the existing controller-owned entrance record grants access.
const Metrics=preload("res://scripts/player_metrics.gd")
const SpatialRules=preload("res://scripts/space/spatial_rules.gd")
const CENTER=Vector2(750,724)
const CLOSED_CENTERS=[697.0,803.0]
const LEAF_SIZE=Vector2(106,86)
const OPEN_OFFSET=56.0
const BLOCKER_Y=736.0
const BLOCKER_HEIGHT=12.0
const SENSOR=Rect2(594,582,312,284)
const CLEARANCE=Rect2(638,726,224,32)
# Source 1500×900 plate: the two painted south-wall bases flank the entrance.
# Without these fixed strips a wide floor route can walk outside the building,
# around a plant/glass panel and back inside while the actual leaves stay shut.
# Keep the complete central aperture open; trim and clear interior floor are
# foreground only. These solids do not depend on admission or animation.
const LAYOUT_PATH="res://data/native/library-entrance-geometry.json"
var fixed_collision_rects:Array[Rect2]=[]
var active:bool=false
var initialized:bool=false
var bound_state:Dictionary={}
var progress:float=0
var sensor_open:bool=false
var access_granted:bool=false
var reduced:bool=false

func _init()->void:
	var layout:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(LAYOUT_PATH))
	for row:Dictionary in layout.fixedCollisionRects:
		var r:Array=row.rect
		fixed_collision_rects.append(Rect2(float(r[0]),float(r[1]),float(r[2]),float(r[3])))

func _point(state:Dictionary)->Vector2:
	var p:Dictionary=state.get("native",{}).get("player",{})
	return Vector2(p.get("x",0),p.get("y",0))

func sync(state:Dictionary,scene_changed:bool=false)->void:
	active=str(state.get("native",{}).get("scene",""))=="library_interior"
	if not active:
		initialized=false;progress=0;sensor_open=false;access_granted=false;bound_state={};return
	access_granted=bool(state.get("ui",{}).get("libraryFinalsPuzzle",{}).get("entranceRecordRead",false))
	reduced=bool(state.get("native",{}).get("settings",{}).get("reduced_motion",false))
	if not initialized or scene_changed or not is_same(bound_state,state):
		bound_state=state;initialized=true
		sensor_open=access_granted and (SENSOR.has_point(_point(state)) or CLEARANCE.intersects(Metrics.foot_rect(_point(state))))
		progress=1.0 if sensor_open else 0.0

func tick(delta:float,state:Dictionary)->void:
	sync(state)
	if not active:return
	var occupied:bool=CLEARANCE.intersects(Metrics.foot_rect(_point(state)))
	sensor_open=access_granted and (SENSOR.has_point(_point(state)) or occupied)
	var target:float=1.0 if sensor_open else 0.0
	var duration:float=.12 if reduced else .36 if sensor_open else .32
	# A restored or re-entering valid actor cannot be swept by a closing leaf.
	if access_granted and occupied:progress=1.0
	else:progress=move_toward(progress,target,clampf(delta,0,.1)/duration)

func leaf_rects()->Array[Rect2]:
	return [Rect2(Vector2(CLOSED_CENTERS[0]-OPEN_OFFSET*progress,CENTER.y)-LEAF_SIZE/2,LEAF_SIZE),Rect2(Vector2(CLOSED_CENTERS[1]+OPEN_OFFSET*progress,CENTER.y)-LEAF_SIZE/2,LEAF_SIZE)]

func collision_rects()->Array[Rect2]:
	var out:Array[Rect2]=[]
	if not active:return out
	for leaf:Rect2 in leaf_rects():out.append(Rect2(leaf.position.x,BLOCKER_Y,leaf.size.x,BLOCKER_HEIGHT))
	out.append_array(fixed_collision_rects)
	return out

func foreground_regions(source:Rect2)->Array[Rect2]:
	# The clean plate's open passage is floor, not an opaque foreground object.
	# Keep the original fixed sides/header; the moving leaves own the aperture.
	if not active or source!=Rect2(505,672,490,72):return [source]
	return [Rect2(505,672,139,72),Rect2(856,672,139,72),Rect2(644,672,212,9)]

func draw(canvas:CanvasItem,context:Dictionary,front:bool)->void:
	if not active or SpatialRules.in_front(CENTER.y+LEAF_SIZE.y/2,context.player)!=front:return
	var z:float=context.zoom;var origin:Vector2=context.origin
	canvas.draw_set_transform(origin,0,Vector2.ONE*z)
	canvas.draw_rect(Rect2(637,673.5,226,9),Color("263c43"))
	canvas.draw_rect(Rect2(742,672,16,8),Color("72b6aa") if access_granted else Color("c75d55"))
	for index:int in range(2):
		var leaf:Rect2=leaf_rects()[index]
		canvas.draw_rect(leaf,Color("7fb1bd",.34))
		canvas.draw_rect(leaf,Color("263c43"),false,4)
		canvas.draw_rect(leaf.grow(-7),Color("b8dfe4",.4),false,2)
		canvas.draw_line(leaf.position+Vector2(11,9),leaf.position+Vector2(77,77),Color("e8f7f5",.25),3)
		var handle_x:float=leaf.end.x-10 if index==0 else leaf.position.x+5
		canvas.draw_rect(Rect2(handle_x,CENTER.y-14,5,28),Color("e3ece8",.82))
	canvas.draw_set_transform(Vector2.ZERO)
