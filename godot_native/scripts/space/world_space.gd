extends RefCounted
const Rules=preload("res://scripts/space/spatial_rules.gd")
const North=preload("res://scripts/space/north_floor_space.gd")
var north:RefCounted=North.new()
var data:Dictionary={}
var active:=false
var scene_id:=""
var variant:=""
var body_mode:="feet"
var world_bounds:=Rect2()
var visual_bounds:=Rect2()
var regions:Array[Rect2]=[]
var voids:Array[Rect2]=[]
var mask_bits:=PackedByteArray()
var mask_definition:Dictionary={}
var source_foregrounds:Array=[]

func configure(scene:String,spec:Dictionary,state:Dictionary,plate:Rect2,bits:=PackedByteArray(),definition:Dictionary={})->void:
	if data.is_empty():data=JSON.parse_string(FileAccess.get_file_as_string("res://data/native/world-space.json"))
	scene_id=scene;active=data.scenes.has(scene);variant=scene;body_mode="feet"
	regions.clear();voids.clear();source_foregrounds.clear();mask_bits=PackedByteArray();mask_definition={}
	world_bounds=Rect2(Vector2.ZERO,Vector2(spec.worldSize.width,spec.worldSize.height));visual_bounds=world_bounds
	if not active:return
	var profile:Dictionary=data.scenes[scene]
	if profile.get("visualBounds","")=="background":visual_bounds=plate
	if scene=="duan_yongping_temporal_maze":
		north.configure(str(state.chapter4.floor));regions=north.regions.duplicate();variant=scene+":"+str(state.chapter4.floor)
	elif scene=="qizhen_lake":
		var zone:=str(state.qizhenLake.get("currentZone",state.qizhenLake.zone));variant=scene+":"+zone+":"+str(state.qizhenLake.vehicle)
		if state.qizhenLake.vehicle=="kayak":
			body_mode="hull"
			for area:Dictionary in spec.zones[zone].waterAreas:regions.append(Rules.rect(area))
		else:
			for row:Array in profile.zones[zone].onFootRegions:regions.append(Rules.rect(row))
		for cover:Dictionary in spec.zones[zone].get("occlusions",[]):source_foregrounds.append(cover.duplicate(true))
	elif spec.has("manifest"):
		regions.append(world_bounds)
		mask_definition=definition if not definition.is_empty() else spec.manifest.walkability
		mask_bits=bits if not bits.is_empty() else Marshalls.base64_to_raw(str(mask_definition.get("bitsBase64","")))
		if scene=="campus_bootstrap":_campus_foregrounds(spec)
		else:
			for cover:Dictionary in mask_definition.get("foregroundObstacles",[]):
				var row:Dictionary=cover.duplicate(true);row["baselineY"]=float(cover.bottom);source_foregrounds.append(row)
	else:
		for row:Array in profile.get("groundRegions",[]):regions.append(Rules.rect(row))
	var remaining:Array[Rect2]=[world_bounds]
	for ground:Rect2 in regions:
		var next:Array[Rect2]=[]
		for piece:Rect2 in remaining:next.append_array(Rules.subtract(piece,ground))
		remaining=next
	voids=remaining

func _campus_foregrounds(spec:Dictionary)->void:
	var landmarks:Dictionary=spec.get("landmarkConstants",{}).get("ZIJINGANG_CAMPUS_LANDMARKS",{})
	for landmark:Dictionary in landmarks.values():
		if not landmark.get("occlusionEnabled",false):continue
		for index:int in landmark.occlusionPolygons.size():
			var points:=Rules.polygon(landmark.occlusionPolygons[index])
			var bounds:=Rect2(points[0],Vector2.ZERO)
			for point:Vector2 in points:bounds=bounds.expand(point)
			source_foregrounds.append({"id":"campus_"+str(landmark.id)+"_"+str(index),"polygon":points,"maskBounds":bounds,"baselineY":float(landmark.worldCenter.y)+float(landmark.visualFootprint.height)/2})

func allows_body(body:Rect2)->bool:
	if not allows_ground(body):return false
	if not mask_definition.is_empty():return Rules.mask_allows_rect(body,mask_bits,mask_definition)
	return true

func allows_ground(body:Rect2)->bool:
	return active and world_bounds.encloses(body) and Rules.covered_by_rects(body,regions)

func snapshot()->Dictionary:
	return {"active":active,"scene":scene_id,"variant":variant,"bodyMode":body_mode,"groundRegions":regions.duplicate(),"nonGround":voids.duplicate(),"mask":not mask_definition.is_empty(),"foregroundCount":source_foregrounds.size(),"projection":data.scenes.get(scene_id,{}).get("projection","")}
