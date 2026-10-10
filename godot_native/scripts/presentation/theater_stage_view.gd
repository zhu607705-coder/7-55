extends TextureRect
const Stage=preload("res://scripts/presentation/theater_stage_model.gd")
const Ink=preload("res://scripts/presentation/theater_stage_ink.gd")
var viewport:SubViewport
var stage:Node3D
var ink:Node2D
var last_visual_time:=-1.0
var last_screen:=""
var last_tick:=-1
var last_round:=-1
func _ready()->void:
	size=Vector2(960,540);mouse_filter=Control.MOUSE_FILTER_IGNORE;texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	viewport=SubViewport.new();viewport.name="StageViewport";viewport.size=Vector2i(960,540);viewport.own_world_3d=true;viewport.render_target_update_mode=SubViewport.UPDATE_WHEN_VISIBLE;viewport.msaa_3d=Viewport.MSAA_DISABLED;viewport.positional_shadow_atlas_size=512;add_child(viewport)
	stage=Stage.new();viewport.add_child(stage)
	ink=Ink.new();viewport.add_child(ink)
	texture=viewport.get_texture()
	var lens:=ShaderMaterial.new();lens.shader=preload("res://scripts/presentation/theater_lens.gdshader");material=lens
func sync(game:Control)->void:
	if not is_instance_valid(stage):return
	if game.visual_time==last_visual_time and game.screen==last_screen and game.state.tick==last_tick and game.state.round==last_round:return
	last_visual_time=game.visual_time;last_screen=game.screen;last_tick=game.state.tick;last_round=game.state.round
	stage.update_pose(game.state,game.visual_time);ink.game=game;ink.queue_redraw()
	viewport.render_target_update_mode=SubViewport.UPDATE_ONCE if game.screen=="paused" else SubViewport.UPDATE_WHEN_VISIBLE
