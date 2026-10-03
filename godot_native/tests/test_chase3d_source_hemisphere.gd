extends SceneTree
const Adapter=preload("res://scripts/presentation/chase3d/source_material_adapter.gd")
var checks:=0
var failures:=0
func _initialize() -> void:run.call_deferred()
func check(value: bool,label: String) -> void:
	checks+=1
	if not value:failures+=1;push_error(label)
func run() -> void:
	var adapter:=Adapter.new()
	var source:=StandardMaterial3D.new();source.albedo_color=Color("788b6d");source.roughness=.88;source.metallic=0
	var material: ShaderMaterial=adapter.material_for(source)
	check(material.shader.code.contains("ambient_light_disabled"),"native flat ambient disabled to avoid double lighting")
	check(material.shader.code.contains("0.5 * world_normal.y + 0.5"),"original Three hemisphere normal weighting")
	check(material.shader.code.contains("linear_albedo * (1.0 - METALLIC) * irradiance / 3.141592653589793"),"original Three indirect Lambert BRDF")
	var sky: Vector3=material.get_shader_parameter("source_sky_linear")
	var ground: Vector3=material.get_shader_parameter("source_ground_linear")
	var expected_sky:=Color("eaf4f1").srgb_to_linear();var expected_ground:=Color("6e7b65").srgb_to_linear()
	check(sky.distance_to(Vector3(expected_sky.r,expected_sky.g,expected_sky.b))<.000001,"source sky light transformed to linear exactly once")
	check(ground.distance_to(Vector3(expected_ground.r,expected_ground.g,expected_ground.b))<.000001,"source ground light transformed to linear exactly once")
	check(material.get_shader_parameter("source_hemisphere_intensity")==2.0,"source hemisphere intensity2 retained")
	var basic:=StandardMaterial3D.new();basic.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	check(adapter.material_for(basic)==basic,"source unlit material stays unlit")
	var unsupported:=StandardMaterial3D.new();unsupported.normal_enabled=true
	check(adapter.material_for(unsupported)==unsupported and adapter.skipped_unsupported==1,"unsupported source material features explicitly retained and counted")
	print("SOURCE_HEMISPHERE checks=",checks," failures=",failures,"; equation/parameter test, not native pixel parity")
	quit(1 if failures else 0)
