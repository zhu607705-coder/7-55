extends SceneTree
var scripts: Array[String]=[]
var failures:=0
func _initialize() -> void: call_deferred("run")
func collect(path: String) -> void:
	var dir:=DirAccess.open(path)
	if dir==null: return
	for file in dir.get_files():
		if file.ends_with(".gd"): scripts.append(path+"/"+file)
	for folder in dir.get_directories(): collect(path+"/"+folder)
func run() -> void:
	collect("res://scripts"); collect("res://tests"); scripts.sort()
	for path in scripts:
		var script=load(path)
		if script==null or not script.can_instantiate():
			failures+=1; push_error("Cannot compile native script: "+path)
	print("Complete native script graph: ",scripts.size()," scripts, ",failures," failures")
	quit(1 if failures else 0)
