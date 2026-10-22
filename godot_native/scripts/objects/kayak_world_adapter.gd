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
