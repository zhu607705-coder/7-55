extends Node2D
## Inserts the native rig at the original actor depth, below front targets and HUD.
## This adapter owns presentation lifetime only; world/model own movement and input.
const RigScene=preload("res://scenes/objects/kayak_rig.tscn")
class DrawPass extends Node2D:
	var world: Control
	var before:=false
	func _draw() -> void:
		if is_instance_valid(world): world.draw_kayak_object_pass(self,before)
	func register_object_surface(ids: Array,geometry: Dictionary) -> void:
		if is_instance_valid(world): world.register_object_surface(ids,geometry)
var world: Control
var before_pass: DrawPass
var rig: Node2D
var after_pass: DrawPass
var active:=false

func setup(owner_world: Control) -> void:
	world=owner_world
	before_pass=DrawPass.new();before_pass.name="BeforeKayak";before_pass.world=world;before_pass.before=true;add_child(before_pass)
	after_pass=DrawPass.new();after_pass.name="AfterKayak";after_pass.world=world;add_child(after_pass)
	hide()

func sync() -> void:
	active=is_instance_valid(world) and world.scene_id=="qizhen_lake" and world.kayak!=null
	if active and not is_instance_valid(rig):
		rig=RigScene.instantiate();add_child(rig);move_child(rig,1)
	elif not active and is_instance_valid(rig):
		remove_child(rig);rig.queue_free();rig=null
	visible=active
	if is_instance_valid(rig):rig.visible=not world.presentation_actor_hidden

func configure_view(origin: Vector2,zoom: float) -> void:
	if not active or not is_instance_valid(rig):return
	var model: RefCounted=world.kayak
	var presentation: Dictionary=world.lake_session.actor_presentation() if world.lake_session!=null else {"offset":Vector2.ZERO,"scale":1.0,"alpha":1.0}
	rig.configure_view(origin+(world.player+presentation.offset)*zoom,zoom*float(presentation.scale),{
		"heading":model.heading,"roll":model.roll,"speed":model.speed,
		"strokeEvents":model.inputs,"tick":model.tick,"side":model.last_side,
		"strokeAgeMs":(model.elapsed-model.last_stroke)*1000,"alpha":presentation.alpha
	})
	before_pass.queue_redraw();after_pass.queue_redraw()

func paddle_input_bounds(side:String)->Rect2:
	if not active or not is_instance_valid(rig) or side not in ["left","right"]:return Rect2()
	var paddle:Node2D=rig.get_node("BodyRoll/"+side.capitalize()+"Paddle")
	var transform:Transform2D=world.get_global_transform_with_canvas().affine_inverse()*paddle.get_global_transform_with_canvas()
	var shaft:Line2D=paddle.get_node("ShaftOutline")
	var points:PackedVector2Array=[]
	for index:int in range(1,shaft.points.size()):points.append(transform*shaft.points[index])
	var blade:Polygon2D=paddle.get_node("BladePivot/Blade")
	var blade_transform:Transform2D=world.get_global_transform_with_canvas().affine_inverse()*blade.get_global_transform_with_canvas()
	for point:Vector2 in blade.polygon:points.append(blade_transform*point)
	var area:=Rect2(points[0],Vector2.ZERO)
	for point:Vector2 in points:area=area.expand(point)
	return area.grow(maxf(6.0,14.0/maxf(.01,world.hud_display_scale())))

func visible_input_bounds()->Rect2:
	if not active or not is_instance_valid(rig):return Rect2()
	var result:Rect2=paddle_input_bounds("left").merge(paddle_input_bounds("right"))
	for path:String in ["BodyRoll/Hull","BodyRoll/SeatedPlayer"]:
		var sprite:Sprite2D=rig.get_node(path)
		var transform:Transform2D=world.get_global_transform_with_canvas().affine_inverse()*sprite.get_global_transform_with_canvas()
		var area:Rect2=sprite.get_rect()
		for point:Vector2 in [area.position,Vector2(area.end.x,area.position.y),area.end,Vector2(area.position.x,area.end.y)]:result=result.expand(transform*point)
	return result
