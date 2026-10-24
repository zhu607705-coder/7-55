extends RefCounted
## A skinned cloth-surface print using ZJU's published standard mark.
## No floating billboard, invented logo, or extra animation/progression clock.
const MARK_PATH: String="res://assets/native_755/ride/rodin/zju_official_emblem.png"
const PRINT_WIDTH: float=.36
const PRINT_CENTER_Y: float=2.05
static func attach(visual: Node3D,skeleton: Skeleton3D) -> void:
	if not ResourceLoader.exists(MARK_PATH):return
	var shader:=Shader.new()
	shader.code="""shader_type spatial;
render_mode blend_mix,depth_prepass_alpha,cull_back;
uniform sampler2D emblem: source_color,filter_linear_mipmap;
void fragment(){
  if(UV.x<0.0||UV.y<0.0||UV.x>1.0||UV.y>1.0){discard;}
  vec2 source_uv=mix(vec2(0.20,0.16),vec2(0.78,0.88),UV);
  vec3 ink=texture(emblem,source_uv).rgb;
  float coverage=1.0-smoothstep(0.42,0.88,(ink.r+ink.g+ink.b)/3.0);
  ALBEDO=vec3(0.91,0.90,0.85);ROUGHNESS=0.92;ALPHA=coverage;
}
"""
	var material:=ShaderMaterial.new();material.shader=shader;material.set_shader_parameter("emblem",load(MARK_PATH))
	for source: Node in visual.find_children("*","MeshInstance3D",true,false):
		if source.skin==null:continue
		for surface: int in range(source.mesh.get_surface_count()):
			var arrays: Array=source.mesh.surface_get_arrays(surface)
			var positions: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
			var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
			var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
			if indices.is_empty():continue
			var selected:=PackedInt32Array()
			for triangle: int in range(0,indices.size(),3):
				var center: Vector3=(positions[indices[triangle]]+positions[indices[triangle+1]]+positions[indices[triangle+2]])/3
				var normal: Vector3=(normals[indices[triangle]]+normals[indices[triangle+1]]+normals[indices[triangle+2]])/3
				if absf(center.x)<.43 and center.y>1.66 and center.y<2.35 and center.z>0 and normal.z>.35:
					selected.append_array(PackedInt32Array([indices[triangle],indices[triangle+1],indices[triangle+2]]))
			if selected.is_empty():continue
			var printed: Array=arrays.duplicate(true)
			var shifted:=positions.duplicate();var uv:=PackedVector2Array()
			for index: int in range(positions.size()):
				shifted[index]+=normals[index]*.002
				uv.append(Vector2(positions[index].x/PRINT_WIDTH+.5,.5-(positions[index].y-PRINT_CENTER_Y)/PRINT_WIDTH))
			printed[Mesh.ARRAY_VERTEX]=shifted;printed[Mesh.ARRAY_TEX_UV]=uv;printed[Mesh.ARRAY_INDEX]=selected
			var mesh:=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,printed)
			mesh.surface_set_material(0,material)
			var patch:=MeshInstance3D.new();patch.name="ZjuBackPrint";patch.mesh=mesh;patch.skin=source.skin
			source.add_child(patch);patch.skeleton=patch.get_path_to(skeleton);patch.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			patch.set_meta("source","https://www.zju.edu.cn/572/main.htm")
