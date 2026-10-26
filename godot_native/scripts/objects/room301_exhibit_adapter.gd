extends Node2D
## Independent A3 room301 objects composited around the real world player.
## This adapter never advances a quest, adds an item or owns input/save state.
const Layout=preload("res://scripts/objects/room301_exhibit_layout.gd")
const Prop=preload("res://scripts/objects/room301_exhibit_prop.gd")
const Metrics=preload("res://scripts/player_metrics.gd")
class DrawPass extends Node2D:
	var adapter:Node2D
	var phase:=0
	func _draw()->void:
		if is_instance_valid(adapter):adapter.draw_pass(self,phase)
	func register_object_surface(ids:Array,geometry:Dictionary)->void:
		if is_instance_valid(adapter):adapter.world.register_object_surface(ids,geometry)
var world:Control
var source_space:Node2D
var props:Dictionary={}
var passes:Array[DrawPass]=[]
var active:=false
var plate:Texture2D
var plate_id:=0
var floor_tile:ImageTexture
var back_props:Array[Node2D]=[]
var front_props:Array[Node2D]=[]

func setup(owner_world:Control)->void:
	world=owner_world;name="Room301Exhibit"
	for i:int in 3:
		var pass_node:=DrawPass.new();pass_node.name=["BeforeExhibits","SharedPlayer","AfterExhibits"][i]
		pass_node.adapter=self;pass_node.phase=i;pass_node.z_index=[-2,0,2][i]
		add_child(pass_node);passes.append(pass_node)
	source_space=Node2D.new();source_space.name="SourceCoordinates";add_child(source_space);hide()

func configure(scene:String,floor_id:String,source_plate:Texture2D)->void:
	active=Layout.active(scene,floor_id) and source_plate!=null
	visible=active
	if not active:return
	plate=source_plate
	if plate_id==plate.get_instance_id():return
	for node:Node in source_space.get_children():source_space.remove_child(node);node.queue_free()
	props.clear();plate_id=plate.get_instance_id()
	var case_texture:Texture2D=load(Layout.data().generatedCase.texture)
	var film_texture:Texture2D=load("res://assets/rpg/interiors/finale/chapter4-755/props/chapter4_a3_archive_film_v01.png")
	for definition:Dictionary in Layout.data().objects:
		var prop:=Prop.new();prop.configure(definition,plate,case_texture,film_texture)
		# Documents and the globe remain individual nodes attached to the case.
		# Their original absolute source coordinates are converted exactly once.
		var parent:Node2D=props.get(str(definition.get("parentId","")),source_space)
		var source_position:Vector2=prop.position
		parent.add_child(prop)
		if parent!=source_space:prop.position=source_position-parent.position
		props[definition.id]=prop
	var image:Image=plate.get_image()
	if image.is_compressed():image.decompress()
	floor_tile=ImageTexture.create_from_image(image.get_region(Rect2i(Layout.rect(Layout.data().floorDonor))))
	var sample:Color=image.get_pixel(440,269)
	# All authored A3 variants share this material point. The current plate
	# supplies the room illumination; there is no second time-of-day authority.
	var reference:Texture2D=load("res://assets/rpg/interiors/finale/chapter4-755/base/a3.png")
	var ref_image:Image=reference.get_image()
	if ref_image.is_compressed():ref_image.decompress()
	var original:Color=ref_image.get_pixel(440,269)
	props.archive_case.generated.modulate=Color(minf(1,sample.r/maxf(.001,original.r)),minf(1,sample.g/maxf(.001,original.g)),minf(1,sample.b/maxf(.001,original.b)))
	props.archive_case.drawer.modulate=props.archive_case.generated.modulate

func configure_view(context:Dictionary)->void:
	if not active:return
	source_space.position=context.origin;source_space.scale=Vector2.ONE*float(context.zoom)
	source_space.modulate=Color.WHITE.lerp(Color(.03,.15,.26),float(context.get("mode_mix",0))*.3)
	var foot:float=Metrics.foot_rect(context.player).end.y
	back_props.clear();front_props.clear()
	for prop:Node2D in props.values():
		if prop.definition.has("parentId"):continue
		var front:bool=float(prop.definition.baselineY)>foot
		prop.z_index=1 if front else -1
		(front_props if front else back_props).append(prop)
	for list:Array[Node2D] in [back_props,front_props]:
		list.sort_custom(func(a:Node2D,b:Node2D)->bool:return float(a.definition.baselineY)<float(b.definition.baselineY))
		for i:int in list.size():source_space.move_child(list[i],i)
	props.archive_case.present_drawer(world.chapter4_layers.archive_motion.sample())
	for pass_node:DrawPass in passes:pass_node.queue_redraw()

func owns_target(id:String)->bool:return active and id=="a3_301_archive_index"

func _register(list:Array[Node2D])->void:
	for prop:Node2D in list:
		world.register_object_surface(prop.definition.get("targetIds",[]),prop.geometry())

func clean_floor(canvas:CanvasItem,context:Dictionary)->void:
	if floor_tile==null:return
	# One native repeated material draw, at the original pixel density. The
	# donor is a complete, unobstructed floor tile from this same time plate.
	canvas.draw_set_transform(context.origin,0,Vector2.ONE*float(context.zoom))
	canvas.draw_texture_rect(floor_tile,Layout.rect(Layout.data().sourceRegion),true)
	canvas.draw_set_transform(Vector2.ZERO)

func draw_pass(canvas:CanvasItem,phase:int)->void:
	if not active:return
	var context:Dictionary=world._render_context()
	match phase:
		0:
			world.object_picker.clear();world._record_plate_targets()
			world._draw_base_pass(canvas,context)
			world.chapter4_layers.draw_back(canvas,context,world.get_node("/root/State").d)
			_register(back_props)
		1:world._draw_actor_pass(canvas,context)
		2:
			_register(front_props)
			world.chapter4_layers.draw_front(canvas,context,world.get_node("/root/State").d)
			world._draw_tail_pass(canvas,context)

func snapshot()->Dictionary:
	return {"active":active,"objects":props.size() if active else 0,"sourceRegion":Layout.data().sourceRegion,"archiveBounds":Layout.data().archiveTarget,"requiredPassage":Layout.data().requiredPassage}
