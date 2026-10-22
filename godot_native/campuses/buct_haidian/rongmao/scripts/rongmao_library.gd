extends "res://campuses/buct_haidian/rongmao/scripts/compact_layered_building.gd"
const ROOT := "res://campuses/buct_haidian/rongmao/"
var contact_shadow: Sprite2D

func configure_library(data: Dictionary) -> bool:
	var texture: Texture2D=load(ROOT+str(data.body_texture))
	var ok: bool=configure(data,texture)
	if not ok:return false
	var shadow_data: Dictionary=data.contact_shadow_candidate
	var shadow_texture: Texture2D=load(ROOT+str(shadow_data.texture))
	var tr: Dictionary=shadow_data.image_to_world
	if shadow_texture==null or shadow_texture.get_size()!=Vector2(tr.raw_size[0],tr.raw_size[1]):
		push_error("Rongmao contact shadow dimensions differ from registration");return false
	contact_shadow=Sprite2D.new();contact_shadow.name="RongmaoIndependentContactShadow"
	contact_shadow.centered=false;contact_shadow.texture=shadow_texture
	contact_shadow.position=Vector2(tr.origin[0],tr.origin[1])-source_anchor
	contact_shadow.scale=Vector2.ONE*float(tr.scale)
	contact_shadow.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	contact_shadow.z_index=-10
	var material:=ShaderMaterial.new();material.shader=preload("res://campuses/buct_haidian/rongmao/shaders/compact_contact_shadow.gdshader")
	material.set_shader_parameter("foot_depth",depth_texture)
	material.set_shader_parameter("body_origin",Vector2(data.body_image_to_world.origin[0],data.body_image_to_world.origin[1]))
	material.set_shader_parameter("shadow_origin",Vector2(tr.origin[0],tr.origin[1]))
	material.set_shader_parameter("shadow_raw_size",shadow_texture.get_size())
	material.set_shader_parameter("world_scale",image_scale)
	material.set_shader_parameter("raw_body_width",float(raw_size.x))
	material.set_shader_parameter("opacity",float(shadow_data.opacity))
	contact_shadow.material=material;add_child(contact_shadow)
	return true

func make_minimal_ground() -> Polygon2D:
	var ground: Dictionary=profile.ground_candidate
	var texture: Texture2D=load(ROOT+str(ground.texture))
	var wr: Array=ground.image_to_world
	var polygon:=Polygon2D.new();polygon.name="Rongmao141PixelGroundRepair"
	polygon.position=Vector2(wr[0],wr[1]);polygon.texture=texture
	# Logical world vertices derive from the original raw uniform registration.
	# Import size_limit changes texture sampling density only, not source-coordinate geometry.
	polygon.polygon=PackedVector2Array([Vector2.ZERO,Vector2(wr[2],0),Vector2(wr[2],wr[3]),Vector2(0,wr[3])])
	var ts:=texture.get_size();polygon.uv=PackedVector2Array([Vector2.ZERO,Vector2(ts.x,0),ts,Vector2(0,ts.y)])
	polygon.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	var material:=ShaderMaterial.new();material.shader=preload("res://campuses/buct_haidian/rongmao/shaders/minimal_ground.gdshader")
	material.set_shader_parameter("permitted_mask",load(ROOT+str(ground.mask)))
	material.set_shader_parameter("raw_world_origin",polygon.position)
	material.set_shader_parameter("raw_world_size",Vector2(wr[2],wr[3]))
	polygon.material=material
	return polygon
