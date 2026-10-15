extends SceneTree
func _initialize() -> void:run.call_deferred()
func run() -> void:
	var source: Node3D=load("res://assets/derived/chase_transition_3d/source_transition.glb").instantiate()
	root.add_child(source)
	var report: Array=[]
	for name: String in ["source_00007","source_00657"]:
		var owner3d: Node3D=source.find_child(name,true,false)
		var groups: Dictionary={};var old: Array=[];var triangles: int=0
		for child: MeshInstance3D in owner3d.find_children("*","MeshInstance3D",true,false):
			if child.skin!=null:continue
			var relative: Transform3D=owner3d.global_transform.affine_inverse()*child.global_transform
			for surface: int in range(child.mesh.get_surface_count()):
				if child.mesh.surface_get_primitive_type(surface)!=Mesh.PRIMITIVE_TRIANGLES:continue
				var material: Material=child.get_active_material(surface)
				var key: String=str(material.get_instance_id())+":"+str(child.mesh.surface_get_format(surface))
				if not groups.has(key):
					var builder:=SurfaceTool.new();builder.begin(Mesh.PRIMITIVE_TRIANGLES);builder.set_material(material)
					groups[key]=builder
				var arrays: Array=child.mesh.surface_get_arrays(surface).duplicate(true)
				var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
				for i: int in range(vertices.size()):vertices[i]=relative*vertices[i]
				arrays[Mesh.ARRAY_VERTEX]=vertices
				var normal_basis: Basis=relative.basis.inverse().transposed()
				if arrays[Mesh.ARRAY_NORMAL]!=null:
					var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
					for i: int in range(normals.size()):normals[i]=(normal_basis*normals[i]).normalized()
					arrays[Mesh.ARRAY_NORMAL]=normals
				if arrays[Mesh.ARRAY_TANGENT]!=null:
					var tangents: PackedFloat32Array=arrays[Mesh.ARRAY_TANGENT]
					for i: int in range(0,tangents.size(),4):
						var tangent: Vector3=(normal_basis*Vector3(tangents[i],tangents[i+1],tangents[i+2])).normalized()
						tangents[i]=tangent.x;tangents[i+1]=tangent.y;tangents[i+2]=tangent.z
					arrays[Mesh.ARRAY_TANGENT]=tangents
				var transformed:=ArrayMesh.new();transformed.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
				groups[key].append_from(transformed,0,Transform3D.IDENTITY)
				triangles+=(arrays[Mesh.ARRAY_INDEX].size() if arrays[Mesh.ARRAY_INDEX]!=null and arrays[Mesh.ARRAY_INDEX].size()>0 else arrays[Mesh.ARRAY_VERTEX].size())/3
			old.append(child)
		var after_triangles: int=0;var index: int=0
		for builder: SurfaceTool in groups.values():
			var mesh: ArrayMesh=builder.commit()
			var item:=MeshInstance3D.new();item.name="ExactSourceBatch_%03d"%index;item.mesh=mesh;item.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			owner3d.add_child(item);item.owner=source;index+=1
			var arrays: Array=mesh.surface_get_arrays(0)
			after_triangles+=(arrays[Mesh.ARRAY_INDEX].size() if arrays[Mesh.ARRAY_INDEX]!=null and arrays[Mesh.ARRAY_INDEX].size()>0 else arrays[Mesh.ARRAY_VERTEX].size())/3
		for child: Node in old:child.get_parent().remove_child(child);child.free()
		report.append({"root":name,"before_draw_meshes":old.size(),"after_draw_meshes":groups.size(),"before_triangles":triangles,"after_triangles":after_triangles})
		if triangles!=after_triangles:push_error("Batch triangle count mismatch");quit(1);return
	source.scene_file_path=""
	var packed:=PackedScene.new();packed.pack(source)
	var result: Error=ResourceSaver.save(packed,"res://assets/derived/chase_transition_3d/source_geometry.scn",ResourceSaver.FLAG_COMPRESS)
	var file:=FileAccess.open("res://assets/derived/chase_transition_3d/batch_report.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
	print("SOURCE_BATCH ",JSON.stringify(report)," saved=",result)
	source.queue_free();await process_frame;quit(0 if result==OK else 1)
