extends SceneTree
const Adapter=preload("res://scripts/presentation/chase3d/source_material_adapter.gd")
var checks:=0
var failures:=0
func _initialize() -> void:run.call_deferred()
func check(value: bool,message: String) -> void:
	checks+=1
	if not value:failures+=1;push_error(message)
func run() -> void:
	var adapter:=Adapter.new();adapter.hemisphere_enabled=false
	var scene: Node=load("res://assets/native_755/ride/world_shared.scn").instantiate()
	var matched:=0
	for mesh: MeshInstance3D in scene.find_children("*","MeshInstance3D",true,false):
		for surface in range(mesh.mesh.get_surface_count()):
			var material: Material=mesh.get_active_material(surface)
			if not material is StandardMaterial3D:continue
			var result: Material=adapter.material_for(material)
			if adapter.is_source_grain(material.albedo_texture):
				matched+=1
				check(result is ShaderMaterial,"exact source grain gets linear sampler")
				if not result is ShaderMaterial:continue
				check(result.get_shader_parameter("source_linear_grain")==material.albedo_texture,"original texture resource and bytes preserved")
				check(result.get_shader_parameter("base_color")==material.albedo_color,"original material color preserved")
				check(result.get_shader_parameter("source_roughness")==material.roughness,"original roughness preserved")
				check(result.get_shader_parameter("source_metallic")==material.metallic,"original metallic preserved")
				check(result.shader.code.contains("source_linear_grain : filter_linear_mipmap_anisotropic") and not result.shader.code.contains("source_linear_grain : source_color"),"linear source map not reinterpreted as sRGB")
				check(adapter.material_for(material)==result,"one immutable-source adaptation reused")
			else:check(result==material,"sRGB labels and other source materials unchanged")
	check(matched>0,"authored source grain fingerprint matched")
	check(adapter.skipped_unsupported==0,"all source grain material features retained")
	scene.free()
	print("SOURCE_LINEAR_GRAIN checks=",checks," matched=",matched," failures=",failures,"; shader/material contract, not GPU pixel parity")
	quit(1 if failures else 0)
