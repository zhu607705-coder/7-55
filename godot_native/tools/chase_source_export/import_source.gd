extends SceneTree
func _initialize() -> void:
	var base: String=ProjectSettings.globalize_path("res://.chase-source-export/")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/native_755/ride/"))
	var files: PackedStringArray=DirAccess.get_files_at(base)
	for file: String in files:
		if file.ends_with(".json") or file.ends_with(".bin"):
			var copy_error:=DirAccess.copy_absolute(base+file,ProjectSettings.globalize_path("res://assets/native_755/ride/"+file))
			if copy_error!=OK:push_error("Data copy failed: "+file);quit(1);return
		if not file.ends_with(".glb") or file=="rider.glb":continue
		var output: String="res://assets/native_755/ride/"+file.get_basename()+".scn"
		if FileAccess.file_exists(output):continue
		var doc:=GLTFDocument.new();var state:=GLTFState.new()
		var error:=doc.append_from_file(base+file,state,0)
		if error!=OK:push_error("GLTF append "+file+" "+str(error));quit(1);return
		var scene: Node=doc.generate_scene(state)
		if scene==null:push_error("GLTF scene "+file);quit(1);return
		var packed:=PackedScene.new();error=packed.pack(scene)
		if error==OK:error=ResourceSaver.save(packed,output,ResourceSaver.FLAG_COMPRESS)
		print("IMPORTED ",file," ",error)
		scene.free();packed=null;state=null;doc=null
		if error!=OK:quit(1);return
	quit()
