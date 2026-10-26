extends Node2D
## Registered source cutouts across the three playable floors. All appearance
## fragments of one object share one pivot. No input, collision or save writes.
class Pass extends Node2D:
	var owner_world:Control
	var stage:=0
	func _draw()->void:
		if is_instance_valid(owner_world):owner_world.draw_north_source_pass(self,stage)
	func register_object_surface(ids:Array,geometry:Dictionary)->void:
		if is_instance_valid(owner_world):owner_world.register_object_surface(ids,geometry)

var world:Control
var active:=false
var fallback:=false
var host_kind:=""
var key:=""
var floor_id:=""
var clean_plate:ImageTexture
var objects:Dictionary={}
var rows:Array=[]
var back_space:Node2D
var front_space:Node2D
var passes:Array[Pass]=[]
var source_data:Dictionary={}
var collision_snapshot:Array=[]

func _pass(stage:int,label:String)->Pass:
	var node:=Pass.new();node.name=label;node.owner_world=world;node.stage=stage
	add_child(node);passes.append(node);return node

func setup(owner_world:Control)->void:
	world=owner_world;name="NorthFloorSourceObjects"
	_pass(0,"SourceBackground")
	back_space=Node2D.new();back_space.name="SourceObjectsBehindActor";add_child(back_space)
	_pass(1,"SharedActor")
	front_space=Node2D.new();front_space.name="SourceObjectsInFrontOfActor";add_child(front_space)
	_pass(2,"OriginalForegroundAndHUD")
	_pass(3,"Room204Background")
	_pass(4,"Room204HUD")
	for node:Pass in passes:node.hide()

static func area(value:Array)->Rect2:
	return Rect2(float(value[0]),float(value[1]),float(value[2]),float(value[3]))

static func subtract(source:Rect2,cut:Rect2)->Array[Rect2]:
	var overlap:=source.intersection(cut)
	if not overlap.has_area():return [source]
	var pieces:Array[Rect2]=[]
	if source.position.y<overlap.position.y:pieces.append(Rect2(source.position,Vector2(source.size.x,overlap.position.y-source.position.y)))
	if overlap.end.y<source.end.y:pieces.append(Rect2(source.position.x,overlap.end.y,source.size.x,source.end.y-overlap.end.y))
	if source.position.x<overlap.position.x:pieces.append(Rect2(source.position.x,overlap.position.y,overlap.position.x-source.position.x,overlap.size.y))
	if overlap.end.x<source.end.x:pieces.append(Rect2(overlap.end.x,overlap.position.y,source.end.x-overlap.end.x,overlap.size.y))
	return pieces

func configure(scene:String,incoming_floor:String,plate:Texture2D,collisions:Array)->void:
	active=scene=="duan_yongping_temporal_maze" and incoming_floor in ["A1","A2","A3"] and plate!=null
	back_space.visible=active;front_space.visible=active
	if not active:
		_detach();return
	var incoming_key:=incoming_floor+":"+str(plate.get_instance_id())
	if incoming_key==key:return
	_detach()
	for object:Node2D in objects.values():object.get_parent().remove_child(object);object.queue_free()
	objects.clear();key=incoming_key;floor_id=incoming_floor;collision_snapshot=collisions.duplicate(true)
	if source_data.is_empty():source_data=JSON.parse_string(FileAccess.get_file_as_string("res://data/native/north-floor-source-objects.json"))
	rows=source_data.floors[incoming_floor].duplicate(true)
	rows.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return int(a.pixelPriority)<int(b.pixelPriority))
	var image:Image=plate.get_image()
	if image.is_compressed():image.decompress()
	image=image.duplicate()
	image.convert(Image.FORMAT_RGBA8)
	for i:int in rows.size():
		var row:Dictionary=rows[i];var bounds:=area(row.rect)
		var pieces:Array[Rect2]=[bounds]
		# Later source objects own overlapping pixels. Removing the original
		# wall's copy prevents doubled furniture/frames when a prop animates.
		for j:int in range(i+1,rows.size()):
			var remaining:Array[Rect2]=[]
			for piece:Rect2 in pieces:remaining.append_array(subtract(piece,area(rows[j].rect)))
			pieces=remaining
		var object:=Node2D.new();object.name=row.id;object.position=Vector2(bounds.get_center().x,row.baselineY)
		object.set_meta("source_bounds",bounds);object.set_meta("source_fragments",pieces)
		object.set_meta("source_floor",incoming_floor);object.set_meta("kind",row.kind)
		object.set_meta("collision_authority","original_floor_layout")
		for part:Rect2 in pieces:
			var visual:=Sprite2D.new();visual.name="SourceAppearance"+str(object.get_child_count())
			visual.centered=false;visual.texture=plate;visual.region_enabled=true;visual.region_rect=part
			visual.region_filter_clip_enabled=true;visual.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
			visual.position=part.position-object.position;object.add_child(visual)
		back_space.add_child(object);objects[row.id]=object
		image.fill_rect(Rect2i(bounds),Color.TRANSPARENT)
	clean_plate=ImageTexture.create_from_image(image)

func _detach()->void:
	for space:Node2D in [back_space,front_space]:
		if is_instance_valid(space) and space.get_parent()!=self:space.reparent(self,false)
		space.z_index=0
	for node:Pass in passes:
		if node.get_parent()!=self:node.reparent(self,false)
		node.hide()
	fallback=false;host_kind=""

func configure_view(context:Dictionary)->void:
	if not active:return
	var new_host:="fallback"
	if is_instance_valid(world.north_props) and world.north_props.active:new_host="generated"
	elif is_instance_valid(world.room301_exhibit) and world.room301_exhibit.active:new_host="exhibit"
	elif is_instance_valid(world.room204_object) and world.room204_object.has_objects():new_host="room204"
	if host_kind!=new_host:
		_detach();host_kind=new_host;fallback=new_host=="fallback"
		if new_host=="generated":
			back_space.reparent(world.north_props.behind_space,false);front_space.reparent(world.north_props.front_space,false)
		elif new_host=="exhibit":
			back_space.reparent(world.room301_exhibit.source_space,false);front_space.reparent(world.room301_exhibit.source_space,false)
			back_space.z_index=-1;front_space.z_index=1
		elif new_host=="room204":
			var host:Node2D=world.room204_object
			for node:Node2D in [passes[3],back_space,front_space,passes[4]]:node.reparent(host,false)
			host.move_child(passes[3],0);host.move_child(back_space,1)
			host.move_child(front_space,host.get_child_count()-2);host.move_child(passes[4],host.get_child_count()-1)
			passes[3].show();passes[4].show()
		else:
			move_child(passes[0],0);move_child(back_space,1);move_child(passes[1],2);move_child(front_space,3);move_child(passes[2],4)
			for i:int in 3:passes[i].show()
	var nested:=new_host in ["generated","exhibit"]
	for space:Node2D in [back_space,front_space]:
		space.position=Vector2.ZERO if nested else Vector2(context.origin)
		space.scale=Vector2.ONE if nested else Vector2.ONE*float(context.zoom)
		# The exhibit's source parent already applies this same mode tint.
		space.modulate=Color.WHITE if new_host=="exhibit" else Color.WHITE.lerp(Color(.03,.15,.26),float(context.get("mode_mix",0))*.3)
	# Fixed source rectangles contain floor and shadows. Their original measured
	# foreground crops remain the sole occlusion owner. They neither sort over
	# an NPC nor incur a per-frame reparent/sort of hundreds of static nodes.
	for node:Pass in passes:
		if node.visible:node.queue_redraw()

func snapshot()->Dictionary:
	return {"active":active,"floor":floor_id,"objects":objects.size(),"host":host_kind,"sourceCoordinates":[1672,941],"collisionAuthority":"original_floor_layout"}
