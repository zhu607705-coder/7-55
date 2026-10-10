extends SceneTree
const Journal=preload("res://scripts/chapters/c3_journal.gd")
const Archive=preload("res://scripts/media/journal_archive.gd")
const Recipe=preload("res://scripts/ui/qizhen_recipe_frame.gd")
var failures:=0
var checks:=0
func check(value: bool,label: String) -> void:
	checks+=1
	if not value: failures+=1; push_error("TEST FAILED: "+label)
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	if not OS.get_user_data_dir().begins_with("/tmp/"): push_error("Refusing non-test save directory"); quit(1); return
	var state=root.get_node("State")
	state.d=state.initial(); state.developer_mode=false
	state.d.native.chapter=3; state.d.native.scene="qizhen_lake"; state.d.native.page="c3_journal_camera"; state.d.native.player={"x":836,"y":470}
	state.d.rpgScene="qizhen_lake"; state.d.runtimeMode="rpg"; state.d.networkMode="campus_wifi"
	var q: Dictionary=state.d.qizhenLake
	q.active=true; q.phase="lake_exploration"; q.zone="open_water"; q.vehicle="kayak"; q.boardingTutorialCompleted=true
	var journal:=Journal.new()
	var requested: Dictionary=journal.request_capture(state.d,"lake_center")
	var pixels:=Image.create(960,540,false,Image.FORMAT_RGBA8); pixels.fill(Color("245874")); pixels.fill_rect(Rect2i(0,0,400,250),Color("b78254"))
	var path:="user://qizhen_journal/portable-unit.png"; DirAccess.make_dir_recursive_absolute("user://qizhen_journal"); pixels.save_png(path)
	requested.capture.session.receive_capture(path,{"source":"world_viewport_crop","scene":"qizhen_lake","zone":"open_water","player":{"x":836,"y":470},"speed":0,"roll":0,"heading":0,"capturedAtSeconds":755})
	var capture: Dictionary=journal.finish_capture(state.d,requested.capture.session)
	check(capture.accepted,"unit pixels exercise accepted receipt transport")
	var original: String=state.d.qizhenLake.journal.mainPhoto.nativeImagePath
	var sha: String=state.d.qizhenLake.journal.mainPhoto.nativeImageSha256
	var destination:="user://portable-save.json"
	check(state.export_save(destination)==OK,"portable native export includes verified PNG")
	var raw: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(destination))
	check(raw.journalImages.size()==1 and raw.journalImages.has(sha),"duplicate pending/main references embed image once")
	DirAccess.remove_absolute(original); state.d=state.initial()
	var imported: Dictionary=state.import_save(destination)
	check(imported.ok,"portable save imports after original image is unavailable")
	var restored: Dictionary=state.d.qizhenLake.journal.mainPhoto
	check(restored.nativeImagePath=="user://qizhen_journal/imported-"+sha+".png" and FileAccess.get_sha256(restored.nativeImagePath)==sha,"import uses local content-addressed path with exact original bytes")
	check(journal.image_for(restored)!=null,"imported actual image is displayable")
	check(state.d.qizhenLake.journal.pendingDraft.photo.nativeImagePath==restored.nativeImagePath,"all duplicate photo references remap consistently")
	var before: String=JSON.stringify(state.d)
	raw.journalImages[sha].data="broken"; var file:=FileAccess.open(destination,FileAccess.WRITE); file.store_string(JSON.stringify(raw)); file.close()
	check(not state.import_save(destination).ok and JSON.stringify(state.d)==before,"corrupt media rejects entire import without progress mutation")
	check(FileAccess.get_sha256(restored.nativeImagePath)==sha,"corrupt retry cannot overwrite existing image")
	# Browser-origin photos have source recipe only. Native renderer uses that
	# actual stored recipe, not an unrelated scene screenshot.
	var browser_photo: Dictionary=restored.duplicate(true); browser_photo.erase("nativeImagePath"); browser_photo.erase("nativeImageSha256"); browser_photo.erase("nativeCapture")
	check(journal.validate_photo_record(browser_photo),"source-only recipe photo remains valid")
	var frame:=Recipe.new(); root.add_child(frame); frame.configure(browser_photo.recipe)
	check(frame.background!=null and frame.kayak!=null,"source recipe renderer uses original authored background/kayak")
	var p: Dictionary=Recipe.projection({"cropCenterX":836,"cropCenterY":470.5,"zoomStep":1,"kayakX":836,"kayakY":470.5,"headingBucket":2},Vector2(1672,941))
	check(p.origin.is_equal_approx(Vector2(-418,-235.25)) and p.kayak.is_equal_approx(Vector2(836,470.5)),"source crop-centering formulas match both axes")
	check(is_equal_approx(p.kayakWidth,192) and is_equal_approx(p.rotation,PI/2),"source128px kayak scales and heading buckets match")
	p=Recipe.projection({"cropCenterX":0,"cropCenterY":0,"zoomStep":2,"kayakX":0,"kayakY":0,"headingBucket":0},Vector2(1672,941))
	check(p.origin==Vector2.ZERO and p.kayak==Vector2.ZERO,"source crop clamps at authored map boundary")
	frame.queue_free(); await process_frame
	print("Journal portability/recipe: ",checks," checks, ",failures," failures")
	quit(0 if failures==0 else 1)
