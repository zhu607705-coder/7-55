extends RefCounted
## One floor-wide ground envelope. It supplements, never approximates or replaces,
## the source interior solids. Movement, routing, restore and depth share this model.
const Metrics=preload("res://scripts/player_metrics.gd")
const Common=preload("res://scripts/space/spatial_rules.gd")
var active:=false
var floor_id:=""
var source_size:=Vector2(1672,941)
var regions:Array[Rect2]=[]
var voids:Array[Rect2]=[]
var solid_faces:Array=[]
var data:Dictionary={}
var source_objects:Dictionary={}

static func foot_y(anchor:Vector2)->float:return Common.foot_y(anchor)
static func depth_in_front(baseline:float,ground_y:float)->bool:return Common.depth_in_front(baseline,ground_y)
static func in_front(baseline:float,anchor:Vector2)->bool:return Common.in_front(baseline,anchor)
static func npc_cover_alpha(cover:Dictionary,ground_y:float,player:Vector2)->float:
	return Common.npc_cover_alpha(cover,ground_y,player)
static func rect(row:Array)->Rect2:return Common.rect(row)

func clear()->void:
	active=false;floor_id="";regions.clear();voids.clear();solid_faces.clear()

func configure(incoming:String)->void:
	if incoming==floor_id and active:return
	clear()
	if data.is_empty():data=JSON.parse_string(FileAccess.get_file_as_string("res://data/native/north-floor-space.json"))
	if not data.get("floors",{}).has(incoming):return
	floor_id=incoming;active=true
	source_size=Vector2(data.sourceSize[0],data.sourceSize[1])
	for row:Dictionary in data.floors[incoming].groundRegions:regions.append(rect(row.rect))
	var face_ids:Array=data.floors[incoming].get("solidFaceSourceIds",[])
	if not face_ids.is_empty():
		if source_objects.is_empty():source_objects=JSON.parse_string(FileAccess.get_file_as_string("res://data/native/north-floor-source-objects.json"))
		for row:Dictionary in source_objects.floors[incoming]:
			if row.id not in face_ids:continue
			var bounds:=rect(row.rect)
			solid_faces.append({"id":"space_face_"+str(row.id),"sourceObjectId":row.id,"maskBounds":{"x":bounds.position.x,"y":bounds.position.y,"width":bounds.size.x,"height":bounds.size.y},"baselineY":row.baselineY,"renderMode":"foot_behind_baseline"})
	_compile_voids()

static func subtract(area:Rect2,cut:Rect2)->Array[Rect2]:
	return Common.subtract(area,cut)

func allows_foot(foot:Rect2)->bool:
	if not active or not Rect2(Vector2.ZERO,source_size).encloses(foot):return false
	return Common.covered_by_rects(foot,regions)

func _compile_voids()->void:
	var remaining:Array[Rect2]=[Rect2(Vector2.ZERO,source_size)]
	for region:Rect2 in regions:
		var next:Array[Rect2]=[]
		for piece:Rect2 in remaining:next.append_array(subtract(piece,region))
		remaining=next
	voids=remaining

func snapshot()->Dictionary:
	return {"active":active,"floor":floor_id,"groundRegions":regions.duplicate(),"nonGround":voids.duplicate(),"solidFaces":solid_faces.duplicate(true),"sourceSize":source_size,"footSize":Metrics.FOOT_SIZE,"depth":"shared foot bottom"}
