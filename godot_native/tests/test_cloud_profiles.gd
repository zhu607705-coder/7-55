extends SceneTree
const Journal=preload("res://scripts/chapters/c3_journal.gd")
const Storage=preload("res://scripts/platform/profile_storage.gd")
const Posts=preload("res://scripts/data/cc98_store.gd")
var checks:=0
var failures:=0
func _initialize() -> void: run.call_deferred()
func check(value: bool,message: String) -> void:
	checks+=1
	if not value: failures+=1;push_error("CLOUD PROFILE: "+message)
func phone_legacy(state: Node, brightness: float, percent: int) -> Dictionary:
	var snapshot: Dictionary=state.initial()
	snapshot.ui.brightness=brightness;snapshot.phoneBattery.percent=percent
	for field: String in ["brightnessRevision","brightnessUserAdjusted","brightnessLegacy100Repaired"]: snapshot.ui.erase(field)
	snapshot.phoneBattery.lowPowerMode=true;snapshot.phoneBattery.rechargeCount=7
	snapshot.ui.homeDeskReturnScene="bonsai";snapshot.native.page="desktop";snapshot.currentScene="desktop"
	return snapshot
func phone_bundle(template: Dictionary, snapshot: Dictionary) -> Dictionary:
	var bundle: Dictionary=template.duplicate(true)
	var envelope: Dictionary=JSON.parse_string(bundle.stateText)
	envelope.state=snapshot.duplicate(true);bundle.stateText=JSON.stringify(envelope)
	return bundle
func check_phone_copy(copy: Dictionary, original: Dictionary, expected: float, repaired: bool, label: String) -> void:
	check(copy.phoneBattery.keys()==["percent"] and copy.phoneBattery.percent==original.phoneBattery.percent,label+" keeps actual battery while retiring charging metadata")
	check(not copy.ui.has("homeDeskReturnScene") and copy.native.page=="bonsai" and copy.currentScene=="bonsai",label+" recovers retired desk return without retaining the charging route")
	check(copy.ui.brightness==expected and copy.ui.brightnessRevision==1 and copy.ui.brightnessLegacy100Repaired==repaired,label+" preserves the bounded brightness migration")
	check(copy.flags==original.flags,label+" grants or erases no puzzle facts")
func check_phone_cloud_boundaries(state: Node) -> void:
	var original: Dictionary=state.d.duplicate(true)
	var seed: Dictionary=state.capture_cloud_bundle(true)
	check(seed.get("ok",false),"phone cloud matrix has a valid fresh portable template")
	if not seed.get("ok",false): return
	var cases: Array=[
		{"label":"untouched legacy100","brightness":100.0,"percent":0,"expected":65.0,"repaired":true},
		{"label":"explicit manual100","brightness":100.0,"percent":1,"expected":100.0,"repaired":false,"manual":true},
		{"label":"legacy45","brightness":45.0,"percent":7,"expected":45.0,"repaired":false},
		{"label":"legacy20","brightness":20.0,"percent":0,"expected":20.0,"repaired":false},
		{"label":"historical manual100","brightness":100.0,"percent":7,"expected":100.0,"repaired":false,"manual_log":true},
		{"label":"earned plant100","brightness":100.0,"percent":100,"expected":100.0,"repaired":false,"plant_lit":true}
	]
	for item: Dictionary in cases:
		var snapshot:=phone_legacy(state,float(item.brightness),int(item.percent))
		if item.get("manual",false):
			snapshot.ui.brightnessRevision=1;snapshot.ui.brightnessUserAdjusted=true;snapshot.ui.brightnessLegacy100Repaired=false
		if item.get("manual_log",false): snapshot.native.log.append({"text":"屏幕亮度已调整。","time":"2026-11-04T00:00:00"})
		if item.get("plant_lit",false): snapshot.flags.plantLit=true
		var incoming:=phone_bundle(seed.bundle,snapshot)
		var incoming_bytes: String=incoming.stateText
		var active_before:=JSON.stringify(state.d)
		var prepared: Dictionary=state.prepare_cloud_bundle(incoming,{})
		check(prepared.get("ok",false),str(item.label)+" cloud import validates")
		check(incoming.stateText==incoming_bytes and JSON.stringify(state.d)==active_before,"cloud preparation does not mutate input or active profile")
		if prepared.get("ok",false):
			check_phone_copy(prepared.state,snapshot,float(item.expected),bool(item.repaired),str(item.label)+" input")
			check(prepared.state.ui.brightnessUserAdjusted==bool(item.get("manual",false) or item.get("manual_log",false)),str(item.label)+" input retains manual evidence")
		state.d=snapshot.duplicate(true)
		active_before=JSON.stringify(state.d)
		var captured: Dictionary=state.capture_cloud_bundle()
		check(captured.get("ok",false),str(item.label)+" cloud output validates")
		check(JSON.stringify(state.d)==active_before,"cloud capture retires metadata only in its copy")
		if captured.get("ok",false):
			var exported: Dictionary=JSON.parse_string(captured.bundle.stateText).state
			check_phone_copy(exported,snapshot,float(item.expected),bool(item.repaired),str(item.label)+" output")
			check(exported.ui.brightnessUserAdjusted==bool(item.get("manual",false) or item.get("manual_log",false)),str(item.label)+" output retains manual evidence")
			var roundtrip: Dictionary=state.prepare_cloud_bundle(captured.bundle,captured.images)
			check(roundtrip.get("ok",false) and roundtrip.state==exported,str(item.label)+" cloud round trip is idempotent")
	for invalid_field: String in ["lowPowerMode","rechargeCount","homeDeskReturnScene","partialBrightness"]:
		var invalid:=phone_legacy(state,100,0)
		match invalid_field:
			"lowPowerMode": invalid.phoneBattery.lowPowerMode="true"
			"rechargeCount": invalid.phoneBattery.rechargeCount=-1
			"homeDeskReturnScene": invalid.ui.homeDeskReturnScene="settings"
			"partialBrightness": invalid.ui.brightnessRevision=1
		state.d=invalid.duplicate(true)
		var active_before:=JSON.stringify(state.d)
		check(not state.prepare_cloud_bundle(phone_bundle(seed.bundle,invalid),{}).get("ok",false),"cloud input rejects malformed "+invalid_field+" before migration")
		check(not state.capture_cloud_bundle().get("ok",false),"cloud output rejects malformed "+invalid_field+" before migration")
		check(JSON.stringify(state.d)==active_before,"rejected phone cloud operation preserves active state")
	state.d=original
	var fresh: Dictionary=state.capture_cloud_bundle(true)
	check(fresh.get("ok",false) and JSON.parse_string(fresh.bundle.stateText).state.ui.brightness==65,"fresh cloud restart uses corrected65 default")
func run() -> void:
	if not load("res://tests/native_test_isolation.gd").is_isolated_save(): push_error("Refusing non-test save directory");quit(1);return
	var state=root.get_node("State")
	var a:="11111111-1111-4111-8111-111111111111"
	var b:="22222222-2222-4222-8222-222222222222"
	check(state.activate_profile(a,false).ok,"profile A initialized")
	check(state.SAVE_PATH.contains(a),"save path uses stable member identifier")
	check_phone_cloud_boundaries(state)
	var post: Dictionary={"id":"cloud-personal-note","avatar":"anonymous"}
	for field in Posts.POST_FIELDS: post[field]="来自 A 的个人编辑"
	check(Posts.import_bundle({"posts":[post],"questPostOverrides":{}})==OK,"personal documents saved in A namespace")
	state.d.native.chapter=3;state.d.native.scene="qizhen_lake";state.d.native.page="c3_journal_camera";state.d.native.player={"x":836,"y":470}
	state.d.rpgScene="qizhen_lake";state.d.runtimeMode="rpg";state.d.networkMode="campus_wifi"
	var lake: Dictionary=state.d.qizhenLake
	lake.active=true;lake.phase="lake_exploration";lake.zone="open_water";lake.vehicle="kayak";lake.boardingTutorialCompleted=true
	var journal:=Journal.new();var requested: Dictionary=journal.request_capture(state.d,"lake_center")
	var pixels:=Image.create(960,540,false,Image.FORMAT_RGBA8);pixels.fill(Color("245874"))
	pixels.fill_rect(Rect2i(0,0,400,250),Color("b78254"))
	var original:=Storage.journal_folder()+"unit.png"
	DirAccess.make_dir_recursive_absolute(Storage.journal_folder());pixels.save_png(original)
	check(requested.capture.session.receive_capture(original,{"source":"world_viewport_crop","scene":"qizhen_lake","zone":"open_water","player":{"x":836,"y":470},"speed":0,"roll":0,"heading":0,"capturedAtSeconds":755}),"profile-owned capture accepted")
	var receipt: Dictionary=journal.finish_capture(state.d,requested.capture.session)
	check(receipt.accepted,"journal receives genuine capture receipt")
	if not receipt.accepted: print(receipt);quit(1);return
	check(state.save_game(),"complete checkpoint saved")
	var captured: Dictionary=state.capture_cloud_bundle()
	check(captured.ok,"full cloud bundle produced from validated state")
	if not captured.get("ok",false): print(captured);quit(1);return
	check(captured.bundle.assets.size()==1,"photo attachment deduplicated")
	check(not captured.bundle.stateText.contains(a),"portable state has no source account directory")
	var legacy_bundle: Dictionary=captured.bundle.duplicate(true)
	var legacy_state: Dictionary=JSON.parse_string(legacy_bundle.stateText)
	legacy_state.sourceVersion=35
	legacy_state.state.actOne.erase("tiyiUpdateStage")
	legacy_state.state.ui.erase("homeDeskReturnScene")
	legacy_bundle.stateText=JSON.stringify(legacy_state)
	var migrated: Dictionary=state.prepare_cloud_bundle(legacy_bundle,captured.images)
	check(migrated.ok,"v35 cloud save follows native v36 migration")
	check(migrated.get("state",{}).get("actOne",{}).has("tiyiUpdateStage"),"cloud migration restores required v36 fields")
	legacy_state.sourceVersion=36;legacy_bundle.stateText=JSON.stringify(legacy_state)
	check(not state.prepare_cloud_bundle(legacy_bundle,captured.images).ok,"v36 cannot use the v35 missing-field exception")
	var photo: Dictionary=state.d.qizhenLake.journal.mainPhoto.duplicate(true)
	check(state.activate_profile(b,false).ok,"profile B initialized independently")
	check(int(state.d.native.chapter)==1,"B has fresh progress rather than A checkpoint")
	check(Posts.load_posts().all(func(entry):return str(entry.id)!="cloud-personal-note"),"B does not read A personal documents")
	check(journal.image_for(photo)==null,"B renderer refuses A local image path")
	check(not Storage.valid_photo_path("user://profiles/../qizhen_journal/stolen.png"),"traversal rejected")
	check(state.save_game(),"B progress can be saved independently")
	check(state.activate_profile(a).hasSave and int(state.d.native.chapter)==3,"A local checkpoint remains intact")
	DirAccess.remove_absolute(str(photo.nativeImagePath));DirAccess.remove_absolute(original)
	var prepared: Dictionary=state.prepare_cloud_bundle(captured.bundle,captured.images)
	check(prepared.ok,"downloaded complete bundle validates before installation")
	check(state.install_cloud_bundle(prepared).ok,"state, photos and documents restored together")
	var restored: Dictionary=state.d.qizhenLake.journal.mainPhoto
	check(restored.nativeImagePath.begins_with(Storage.journal_folder()),"downloaded photo installed in current owner namespace")
	check(journal.image_for(restored)!=null,"restored image decodes")
	check(Posts.load_posts().any(func(entry):return str(entry.id)=="cloud-personal-note" and entry.body==post.body),"personal edit survived complete restore")
	var before:=JSON.stringify(state.d)
	var broken: Dictionary=captured.images.duplicate(true)
	broken[captured.bundle.assets[0]].data="broken"
	check(not state.prepare_cloud_bundle(captured.bundle,broken).ok and JSON.stringify(state.d)==before,"bad attachment cannot partially replace current state")
	var future: Dictionary=captured.bundle.duplicate(true);var envelope: Dictionary=JSON.parse_string(future.stateText);envelope.sourceVersion=999;future.stateText=JSON.stringify(envelope)
	check(not state.prepare_cloud_bundle(future,captured.images).ok,"future save rejected without mutation")
	var fresh: Dictionary=state.capture_cloud_bundle(true)
	check(fresh.ok and int(JSON.parse_string(fresh.bundle.stateText).state.native.chapter)==1,"restart candidate begins from real initial state")
	check(fresh.bundle.stores.posts.contains(post.body) and JSON.stringify(state.d)==before,"preparing restart keeps edits and old active state")
	var fixture:=OS.get_environment("GODOT_CLOUD_FIXTURE")
	if not fixture.is_empty(): check(state.export_save(fixture)==OK,"explicit isolated browser fixture exported")
	var disk_path: String=state.SAVE_PATH
	var valid_disk:=FileAccess.get_file_as_string(disk_path)
	var future_disk: Dictionary=JSON.parse_string(valid_disk);future_disk.sourceVersion=999
	var handle:=FileAccess.open(disk_path,FileAccess.WRITE);handle.store_string(JSON.stringify(future_disk));handle.close()
	var future_bytes:=FileAccess.get_file_as_bytes(disk_path)
	check(not state.activate_profile(a).ok,"future local save blocks initialization rather than loading older backup")
	check(FileAccess.get_file_as_bytes(disk_path)==future_bytes,"future local save remains byte-for-byte intact")
	check(not state.save_game(),"blocked initialization cannot overwrite future local save")
	handle=FileAccess.open(disk_path,FileAccess.WRITE);handle.store_string(valid_disk);handle.close()
	handle=FileAccess.open(state.BACKUP_PATH,FileAccess.WRITE);handle.store_buffer(future_bytes);handle.close()
	check(not state.activate_profile(a).ok,"future backup also blocks automatic replacement")
	check(FileAccess.get_file_as_string(disk_path)==valid_disk and FileAccess.get_file_as_bytes(state.BACKUP_PATH)==future_bytes,"valid main and future backup both remain intact")
	var legacy: Dictionary=state.initial();legacy.native.page="phone_home"
	var legacy_bytes:=JSON.stringify({"format":"7-55-godot-native","version":1,"sourceVersion":state.SOURCE_VERSION,"state":legacy})
	handle=FileAccess.open("user://save.json",FileAccess.WRITE);handle.store_string("{broken");handle.close()
	handle=FileAccess.open("user://save.previous.json",FileAccess.WRITE);handle.store_string(legacy_bytes);handle.close()
	var guest: Dictionary=state.activate_profile("guest")
	check(guest.get("hasSave",false) and state.d.native.page=="phone_home","legacy guest migration recovers its valid previous save when main is corrupt")
	check(FileAccess.get_file_as_string("user://save.json")=="{broken" and FileAccess.get_file_as_string("user://save.previous.json")==legacy_bytes,"legacy migration preserves both original files")
	check(Posts.load_posts().all(func(entry):return str(entry.id)!="cloud-personal-note"),"legacy guest recovery does not borrow account A documents")
	print("CLOUD_PROFILES ",checks," checks; ",failures," failures")
	quit(0 if failures==0 else 1)
