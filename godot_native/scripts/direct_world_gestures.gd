extends RefCounted
## Pointer ownership only. Returned intents are consumed by the live world;
## this object knows no player, controller, save, collision or puzzle state.
const PAN_THRESHOLD=10.0
var pointers:Dictionary={}
var context:Array=[]
var owner_state:Dictionary={}
var camera_ids:Array[int]=[]
var camera_center:=Vector2.ZERO
var camera_distance:=0.0
var camera_latched:=false

func has_active()->bool:return not pointers.is_empty()
func valid(next_context:Array,state:Dictionary)->bool:return not has_active() or (context==next_context and is_same(owner_state,state))
func owns_side(side:String)->bool:
	for pointer:Dictionary in pointers.values():
		if str(pointer.role) in ["paddle_"+side,"water_"+side]:return true
	return false
func cancel()->void:
	pointers.clear();camera_ids.clear();context=[];owner_state={};camera_distance=0;camera_latched=false

func begin(id:int,point:Vector2,role:String,next_context:Array,state:Dictionary)->Dictionary:
	if not valid(next_context,state):cancel()
	if pointers.has(id):return {}
	if not has_active():context=next_context;owner_state=state
	if role.begins_with("paddle_") or role.begins_with("water_"):
		if owns_side(role.get_slice("_",1)):role="ignored"
	if role=="map" and camera_latched:role="ignored"
	pointers[id]={"role":role,"start":point,"last":point,"panned":false}
	if role=="mode":return {"kind":"mode"}
	if role=="map" and camera_ids.is_empty():
		for other:int in pointers:
			if other!=id and pointers[other].role=="map":
				camera_ids.assign([other,id])
				camera_latched=true
				for key:int in camera_ids:pointers[key].role="camera";pointers[key].panned=true
				camera_center=(Vector2(pointers[other].last)+point)/2
				camera_distance=Vector2(pointers[other].last).distance_to(point)
				break
	elif role=="map" and not camera_ids.is_empty():pointers[id].role="ignored"
	return {}

func drag(id:int,point:Vector2,next_context:Array,state:Dictionary)->Dictionary:
	if not valid(next_context,state):cancel();return {}
	if not pointers.has(id):return {}
	var pointer:Dictionary=pointers[id]
	var previous:Vector2=pointer.last
	pointer.last=point
	if pointer.role=="camera" and camera_ids.size()==2 and pointers.has(camera_ids[0]) and pointers.has(camera_ids[1]):
		var a:Vector2=pointers[camera_ids[0]].last;var b:Vector2=pointers[camera_ids[1]].last
		var center:Vector2=(a+b)/2;var distance:float=a.distance_to(b)
		var result:Dictionary={"kind":"camera","center":center,"delta":center-camera_center,"ratio":distance/camera_distance if camera_distance>1 and distance>1 else 1.0}
		camera_center=center;camera_distance=distance;return result
	if pointer.role=="map" and (pointer.panned or point.distance_to(pointer.start)>PAN_THRESHOLD):
		pointer.panned=true;return {"kind":"pan","delta":point-previous}
	return {}

func end(id:int,point:Vector2,canceled:bool,next_context:Array,state:Dictionary)->Dictionary:
	if not valid(next_context,state):cancel();return {}
	if not pointers.has(id):return {}
	var pointer:Dictionary=pointers[id];pointers.erase(id)
	if id in camera_ids:camera_ids.clear();camera_distance=0
	var result:Dictionary={}
	if not canceled:
		if pointer.role=="map" and not pointer.panned and point.distance_to(pointer.start)<=PAN_THRESHOLD:result={"kind":"tap","point":point}
		elif str(pointer.role).begins_with("paddle_") or (str(pointer.role).begins_with("water_") and point.distance_to(pointer.start)>PAN_THRESHOLD):
			result={"kind":"stroke","side":str(pointer.role).get_slice("_",1),"reverse":point.y-Vector2(pointer.start).y>24}
	if not has_active():context=[];owner_state={};camera_latched=false
	return result
