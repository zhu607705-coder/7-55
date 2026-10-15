extends SceneTree
## Focused mock-primitive binding/lifecycle test. Not artwork/import/GPU acceptance.
## Run only in a complete restored Godot project after reviewing this draft.
const BASE=preload("res://campuses/buct_changping/scripts/registered_hd_region.gd")
const V4=preload("res://campuses/buct_changping/scripts/registered_hd_north_large.gd")
class MockCampus extends Node2D:
	var world: Node2D
	var objects: Node2D
	var SOURCE: Texture2D
	var initialized:=false
var failures: Array[String]=[]
var checks:=0
func _initialize() -> void:run.call_deferred()
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func primitive_texture() -> ImageTexture:
	var image:=Image.create(8,8,false,Image.FORMAT_RGBA8)
	image.fill(Color(.25,.5,.75,1));image.generate_mipmaps()
	return ImageTexture.create_from_image(image)
func make_lower(map: MockCampus,side: String) -> Node2D:
	var expected: Dictionary=V4.LOWER_SPECS[side]
	var lower=BASE.new();lower.campus=map
	lower.name="RegisteredHDRegion_"+str(expected.id)
	lower.profile={"id":expected.id,"schema":expected.schema,"roi_xywh":expected.roi.duplicate(),"source_sha256":BASE.SOURCE_SHA,"quality_approved":true,"ground_rgba_sha256":expected.ground_rgba_sha256}
	lower.ground_texture=primitive_texture()
	lower.ground_sprite=Sprite2D.new();lower.ground_sprite.texture=lower.ground_texture
	var material:=ShaderMaterial.new();material.shader=BASE.WEST_GROUND_SHADER if side=="west" else BASE.GROUND_SHADER
	lower.ground_sprite.material=material;lower.add_child(lower.ground_sprite)
	map.world.add_child(lower);map.world.move_child(lower,map.objects.get_index())
	lower._committed=true;lower.set_process(false)
	return lower
func run() -> void:
	var map:=MockCampus.new();root.add_child(map)
	map.world=Node2D.new();map.add_child(map.world)
	map.objects=Node2D.new();map.world.add_child(map.objects)
	map.SOURCE=primitive_texture()
	var original_source=map.SOURCE
	var original_objects=map.objects
	var west=make_lower(map,"west");var east=make_lower(map,"east")
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://campuses/buct_changping/data/north_large_hd_region.template.json"))
	check(not V4._valid_v4_profile(data),"Unapproved template fails closed")
	data.quality_approved=true
	check(V4._valid_v4_profile(data),"Mock canonical geometry/ownership schema validates")
	var bad:=data.duplicate(true);bad.texels_per_source_pixel=5
	check(not V4._valid_v4_profile(bad),"Silent native 4x to 5x upscale rejects")
	bad=data.duplicate(true);bad.shared_lower_edges[0].rect[0]=350
	check(not V4._valid_v4_profile(bad),"Broad coincident overlap cannot activate west slot")
	check(V4._estimate_v4_layer_bytes(data)==9689195,"Owned 5x bands counted with native 4x ground and one owner-index mask")
	var upper=V4.new();upper.campus=map;upper.profile=data
	upper.name="RegisteredHDRegion_north_large"
	upper.ground_texture=primitive_texture()
	upper.lower_strip_textures={"west":primitive_texture(),"east":primitive_texture()}
	upper.ground_sprite=Sprite2D.new();upper.ground_sprite.texture=upper.ground_texture
	var material:=ShaderMaterial.new();material.shader=V4.V4_SHADER
	upper.ground_sprite.material=material;upper.add_child(upper.ground_sprite)
	# This intentionally bypasses asset preparation to isolate display binding.
	upper._v4_prepared=true
	map.world.add_child(upper);upper._committed=true
	upper.visibility_changed.connect(upper._refresh_v4_visibility)
	upper._process(0.0)
	check(upper._last_lower_state==[true,true],"Both exact active accepted lower owners bind")
	check(west.ground_sprite.material.get_shader_parameter("external_top_owner_active")==true,"Only west shared band yields")
	check(east.ground_sprite.material.get_shader_parameter("external_top_owner_active")==true,"Only partial east shared band yields")
	check(upper.get_index()>west.get_index() and upper.get_index()>east.get_index() and upper.get_index()<map.objects.get_index(),"Directed top owner renders after both lower grounds and before objects")
	var foreign:=Node2D.new()
	check(not west.clear_external_top_owner(foreign),"Foreign owner cannot clear v4 guard");foreign.free()
	var frozen_roi: Array=west.profile.roi_xywh.duplicate()
	west.profile.roi_xywh=[350,167,384,256];upper._process(0.0)
	check(upper._last_lower_state==[false,true],"Coincident broad unrelated west ROI fails closed")
	check(west.ground_sprite.material.get_shader_parameter("external_top_owner_active")==false,"Rejected west immediately restores its own display")
	west.profile.roi_xywh=frozen_roi;upper._process(0.0)
	east.hide();upper._process(0.0)
	check(upper._last_lower_state==[true,false],"Hidden east disables only its local input and guard")
	east.show();upper._process(0.0)
	upper.hide()
	check(west.ground_sprite.material.get_shader_parameter("external_top_owner_active")==false and east.ground_sprite.material.get_shader_parameter("external_top_owner_active")==false,"Hiding upper synchronously releases both incoming guards")
	upper.show()
	check(upper._last_lower_state==[true,true],"Showing upper reauthenticates exact lower owners")
	map.world.remove_child(upper)
	check(west.ground_sprite.material.get_shader_parameter("external_top_owner_active")==false and east.ground_sprite.material.get_shader_parameter("external_top_owner_active")==false,"Direct upper detach restores both original guards")
	check(map.SOURCE==original_source and map.objects==original_objects and map.objects.get_child_count()==0,"Mock source/object identities remain unchanged; zero physics added")
	upper.free();map.queue_free()
	print(JSON.stringify({"checks":checks,"failures":failures,"scope":"mock primitive binding/lifecycle only","asset_validation_run":false,"gpu_run":false}))
	quit(0 if failures.is_empty() else 1)
