extends TextureRect
const Stage=preload("res://scripts/presentation/theater_stage_model.gd")
const Ink=preload("res://scripts/presentation/theater_stage_ink.gd")
var viewport:SubViewport
var stage:Node3D
var ink:Node2D
func _ready()->void:
	size=Vector2(960,540);mouse_filter=Control.MOUSE_FILTER_IGNORE;texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	viewport=SubViewport.new();viewport.name="StageViewport";viewport.size=Vector2i(960,540);viewport.own_world_3d=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;viewport.msaa_3d=Viewport.MSAA_DISABLED;add_child(viewport)
	stage=Stage.new();viewport.add_child(stage)
	ink=Ink.new();viewport.add_child(ink)
	texture=viewport.get_texture()
	var lens:=ShaderMaterial.new();lens.shader=preload("res://scripts/presentation/theater_lens.gdshader");material=lens
func sync(game:Control)->void:
	if not is_instance_valid(stage):return
	stage.update_pose(game.state,game.visual_time);ink.game=game;ink.queue_redraw()
	viewport.render_target_update_mode=SubViewport.UPDATE_ONCE if game.screen=="paused" else SubViewport.UPDATE_ALWAYS
