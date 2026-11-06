extends SceneTree
## Starts a second engine against isolated real files to test autoload startup.
var failures:=0
var checks:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func write(path:String,value:Dictionary)->void:
	var f:=FileAccess.open(path,FileAccess.WRITE);f.store_string(JSON.stringify(value));f.close()
func run()->void:
	if not load("res://tests/native_test_isolation.gd").is_isolated_save():quit(2);return
	var s:Node=root.get_node("State")
	var args:=OS.get_cmdline_user_args()
	if not args.is_empty() and args[0]=="child":
		var before:=FileAccess.get_file_as_bytes(s.SAVE_PATH)
		var backup:=FileAccess.get_file_as_bytes(s.BACKUP_PATH)
		check(not s.persistence_ready,"future file must block startup persistence")
		s.open_page("weather");s.open_page("phone_home")
		check(not s.save_game(),"repeated writes blocked")
		check(before==FileAccess.get_file_as_bytes(s.SAVE_PATH),"primary bytes preserved")
		check(backup==FileAccess.get_file_as_bytes(s.BACKUP_PATH),"backup bytes preserved")
		var entry:Node=load("res://scenes/entry.tscn").instantiate();root.add_child(entry)
		check(entry.story_button.disabled,"story entry disabled")
		check(entry.detail.visible and "更新" in entry.detail.text,"visible update explanation")
		entry.open_story();check(not entry.opening,"direct story entry blocked")
		entry.open_flc();check(not entry.opening,"direct FLC entry blocked")
		print("STARTUP checks=",checks," failures=",failures)
		entry.queue_free();quit(1 if failures else 0);return
	var current:Dictionary={"format":"7-55-godot-native","version":1,"sourceVersion":s.SOURCE_VERSION,"state":s.initial()}
	var future:Dictionary=current.duplicate(true);future.sourceVersion=s.SOURCE_VERSION+1
	for future_primary:bool in [true,false]:
		write(s.SAVE_PATH,future if future_primary else current);write(s.BACKUP_PATH,current if future_primary else future)
		var output:Array=[]
		var status:=OS.execute(OS.get_executable_path(),PackedStringArray(["--headless","--path",ProjectSettings.globalize_path("res://"),"--script",get_script().resource_path,"--","child"]),output,true)
		print("STARTUP CHILD ",future_primary," ",output)
		check(status==0,"separate-process startup protection")
	for version:Variant in [35,36,37,37.5,999,"37",null]:
		write(s.SAVE_PATH,current);write(s.BACKUP_PATH,current);s.persistence_ready=true;s.d=s.initial()
		var candidate:Dictionary=current.duplicate(true);candidate.sourceVersion=version;candidate.state.native.page="phone_home"
		if version is int and version==35:candidate.state.actOne.erase("tiyiUpdateStage")
		if version==null:candidate.erase("sourceVersion")
		write("user://candidate.json",candidate)
		var before:Dictionary=s.d.duplicate(true)
		var main_bytes:=FileAccess.get_file_as_bytes(s.SAVE_PATH);var backup_bytes:=FileAccess.get_file_as_bytes(s.BACKUP_PATH)
		var result:Dictionary=s.import_save("user://candidate.json")
		var supported:bool=version==null or float(version)<=s.SOURCE_VERSION
		check(bool(result.ok)==supported,"import version acceptance "+str(version))
		if not supported:
			check("较新" in result.message,"future rejection explains update requirement")
			check(s.d==before,"future import preserves live state")
			check(main_bytes==FileAccess.get_file_as_bytes(s.SAVE_PATH) and backup_bytes==FileAccess.get_file_as_bytes(s.BACKUP_PATH),"future import preserves exact files")
	# Rejection must precede optional media/store validation and installation.
	future.journalImages={"invalid":"must not be prepared"};future.cc98Stores={"invalid":true}
	write("user://candidate.json",future)
	check("较新" in s.import_save("user://candidate.json").message,"future guard precedes media and store work")
	var f:=FileAccess.open(s.SAVE_PATH,FileAccess.WRITE);f.store_string("broken");f.close();write(s.BACKUP_PATH,current)
	s.persistence_ready=true
	check(s.load_game(),"corrupt primary recovers valid backup")
	# Profile switching must clear a previous block and retain its older broad check.
	check(s.activate_profile("11111111-1111-1111-1111-111111111111",false).ok,"new compatible profile activates")
	var foreign:Dictionary=future.duplicate(true);foreign.format="future-format"
	write(s.SAVE_PATH,foreign)
	check(not s.activate_profile("11111111-1111-1111-1111-111111111111").ok,"future profile with changed envelope stays protected")
	check(not s.persistence_ready and not s.save_compatibility_error.is_empty(),"profile reports blocked persistence")
	check(s.activate_profile("22222222-2222-2222-2222-222222222222",false).ok,"switch to compatible profile succeeds")
	check(s.persistence_ready and s.save_compatibility_error.is_empty(),"compatible profile clears block")
	print("FUTURE SAVE REGRESSION checks=",checks," failures=",failures);quit(1 if failures else 0)
