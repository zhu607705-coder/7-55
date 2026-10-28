extends Node2D
## Independent presentation nodes. Wall-mounted reveal sprites share an opacity
## group with the wall; grounded objects keep individual foot-depth sorting.
## No target, collision, save or progression authority lives in this node.
const ALPHA_CUTOFF=preload("res://shaders/north_prop_alpha_cutoff.gdshader")

class DrawPass extends Node2D:
	var world:Control
	var stage:=0
	func _draw()->void:
		if is_instance_valid(world):world.draw_north_prop_pass(self,stage)
	func register_object_surface(ids:Array,geometry:Dictionary)->void:
		if is_instance_valid(world):world.register_object_surface(ids,geometry)

var world:Control
var behind_space:Node2D
var front_space:Node2D
var reveal_space:Node2D
var wall_reveal:CanvasGroup
var passes:Array[DrawPass]=[]
var objects:Dictionary={}
var reveal_objects:Dictionary={}
var registrations:Array=[]
var active:=false

func _pass(stage:int,label:String,parent:Node)->DrawPass:
	var node:=DrawPass.new();node.name=label;node.world=world;node.stage=stage
	parent.add_child(node);passes.append(node);return node

func _space(label:String,parent:Node)->Node2D:
	var node:=Node2D.new();node.name=label;parent.add_child(node);return node

func setup(owner_world:Control)->void:
	world=owner_world
	_pass(0,"Background",self)
	behind_space=_space("BehindActorSourceCoordinates",self)
	_pass(1,"ActorAndFrontTargets",self)
	wall_reveal=CanvasGroup.new();wall_reveal.name="WallRevealSingleAlpha";add_child(wall_reveal)
	wall_reveal.self_modulate=Color(1,1,1,.78)
	_pass(3,"WallSurface",wall_reveal)
	reveal_space=_space("WallMountedRevealSourceCoordinates",wall_reveal)
	front_space=_space("FrontOfActorSourceCoordinates",self)
	_pass(2,"LegacyForegroundAndHUD",self)
	hide()

func _appearance(registration:Dictionary)->Sprite2D:
	var sprite:=Sprite2D.new();sprite.name="Appearance"
	sprite.centered=false;sprite.region_enabled=true
	sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	var material:=ShaderMaterial.new();material.shader=ALPHA_CUTOFF
	material.set_shader_parameter("alpha_cutoff",float(registration.alphaCutoff))
	var palette:=PackedColorArray()
	for value:String in world.north_objects.data.palette.colors:palette.append(Color(value))
	material.set_shader_parameter("shared_palette",palette)
	var kind:String=registration.get("assetId",registration.id)
	material.set_shader_parameter("wood_material",kind in ["lectern_105","student_table","student_chair"])
	material.set_shader_parameter("green_material",kind in ["blackboard_105","plant_105"])
	sprite.material=material
	return sprite

func sync()->void:
	active=is_instance_valid(world) and world.north_objects.active and world.north_objects.independent_preview
	visible=active
	if not active:return
	var family:RefCounted=world.north_objects
	if registrations.is_empty():registrations=family.object_registrations()
	for registration:Dictionary in registrations:
		if not objects.has(registration.id):
			var object:=Node2D.new();object.name=registration.nodeName
			behind_space.add_child(object);objects[registration.id]=object
			object.add_child(_appearance(registration))
			if registration.get("renderMode","")=="wall_attached":
				var reveal:=_appearance(registration);reveal.name=str(registration.nodeName)+"Reveal"
				reveal.set_meta("owner_object_id",registration.id)
				reveal_space.add_child(reveal);reveal_objects[registration.id]=reveal
		var object:Node2D=objects[registration.id]
		object.position=Vector2(float(registration.centerX),float(registration.baselineY))
		var appearance:Sprite2D=object.get_node("Appearance")
		appearance.texture=family.prop_textures[registration.get("assetId",registration.id)]
		appearance.region_rect=family.rect(registration.visibleRect)
		appearance.scale=Vector2.ONE*float(registration.scale)
		appearance.position=Vector2(-appearance.region_rect.size.x/2,-appearance.region_rect.size.y)*float(registration.scale)
		if reveal_objects.has(registration.id):
			var reveal:Sprite2D=reveal_objects[registration.id]
			reveal.texture=appearance.texture;reveal.region_rect=appearance.region_rect
			reveal.scale=appearance.scale;reveal.position=object.position+appearance.position

func configure_view(origin:Vector2,zoom:float,player:Vector2,mode_mix:float)->void:
	if not active:return
	for source_space:Node2D in [behind_space,front_space,reveal_space]:
		source_space.position=origin;source_space.scale=Vector2.ONE*zoom
	var family:RefCounted=world.north_objects
	var mode_tint:=Color.WHITE.lerp(Color(.03,.15,.26),mode_mix*.3)
	wall_reveal.visible=family.wall_in_front(player)
	for registration:Dictionary in registrations:
		var object:Node2D=objects[registration.id]
		var mounted:bool=registration.get("renderMode","")=="wall_attached"
		var source_space:Node2D=front_space if not mounted and family.prop_in_front(registration,player) else behind_space
		if object.get_parent()!=source_space:object.reparent(source_space,false)
		var tint:Color=family.object_tint(registration)*mode_tint
		object.get_node("Appearance").modulate=tint
		if mounted:reveal_objects[registration.id].modulate=tint
	for source_space:Node2D in [behind_space,front_space]:
		var sorted:Array=source_space.get_children()
		sorted.sort_custom(func(a:Node2D,b:Node2D):return a.position.y<b.position.y)
		for index:int in sorted.size():source_space.move_child(sorted[index],index)
	for draw_pass:DrawPass in passes:draw_pass.queue_redraw()
