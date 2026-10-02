extends SceneTree
## Unit fixtures below are synthetic test pixels, never gameplay/evidence assets.
const Journal=preload("res://scripts/chapters/c3_journal.gd")
const Camera=preload("res://scripts/media/c3_capture_session.gd")
const Pages=preload("res://scripts/ui/c3_journal_pages.gd")
var module: RefCounted=Journal.new()
var checks: int=0
var errors: int=0
var tick: int=700
var created_paths: Array=[]
var test_path: String="user://qizhen_journal/unit_test_pixels.png"
func check(value: bool, label_value: String) -> void:
	checks+=1
	if not value:
		errors+=1
		push_error(label_value)
func initial() -> Dictionary:
	var s: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/initial_state.json"))
	s.native={"chapter":3,"page":"c3_journal_camera","scene":"qizhen_lake","mode":"light","player":{"x":836,"y":470}}
	s.qizhenLake.active=true
	s.qizhenLake.phase="lake_exploration"
	s.qizhenLake.zone="open_water"
	s.qizhenLake.vehicle="kayak"
	s.qizhenLake.boardingTutorialCompleted=true
	s.networkMode="campus_wifi"
	return s
func at(s: Dictionary, spot: String) -> void:
	var definition: Dictionary=Journal.SPOTS[spot]
	var a: Array=definition.areas[0]
	s.qizhenLake.zone=definition.zone
	s.native.player={"x":(float(a[0])+float(a[2]))/2,"y":(float(a[1])+float(a[3]))/2}
func capture(s: Dictionary, spot: String, fixed_tick: int=-1) -> Dictionary:
	at(s,spot)
	var request: Dictionary=module.request_capture(s,spot)
	if not request.get("capture") is Dictionary: return request
	var session: RefCounted=request.capture.session
	tick+=1
	var meta: Dictionary={"source":"world_viewport_crop","scene":"qizhen_lake","zone":s.qizhenLake.zone,"player":s.native.player.duplicate(),"speed":0,"roll":0,"heading":0,"capturedAtSeconds":tick if fixed_tick<0 else fixed_tick}
	check(session.receive_capture(test_path,meta),"host supplies readable test image")
	check(session.is_complete(),"capability reports completed receipt")
	var receipt: Dictionary=module.finish_capture(s,session)
	if receipt.get("photo") is Dictionary: created_paths.append(receipt.photo.nativeImagePath)
	return receipt
func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("user://qizhen_journal")
	var pixels: Image=Image.create(960,540,false,Image.FORMAT_RGBA8)
	pixels.fill(Color("135b71"))
	pixels.fill_rect(Rect2i(0,0,480,270),Color("d3ac64"))
	pixels.save_png(test_path)
	var blank: Image=Image.create(960,540,false,Image.FORMAT_RGBA8)
	blank.fill(Color.BLACK)
	check(not module.image_has_variance(blank),"opaque black framebuffer rejected")
	blank.fill(Color.TRANSPARENT)
	check(not module.image_has_variance(blank),"transparent framebuffer rejected")
	check(module.image_has_variance(pixels),"unit image variance fixture accepted")
	var fixture: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/qizhen_journal.json"))
	for entry: Dictionary in fixture.captures:
		var recipe: Dictionary=module.build_recipe(entry.spotId,Vector2(entry.x,entry.y),entry.heading,entry.speed,entry.roll,entry.gone)
		check(JSON.parse_string(JSON.stringify(recipe))==entry.recipe,"original TypeScript recipe "+str(entry.spotId))
		check(module.derive_tags(recipe,entry.speed,entry.roll)==entry.tags,"original TypeScript tags "+str(entry.spotId))
	for entry: Dictionary in fixture.projections:
		var before: String=JSON.stringify(entry.journal)
		check(JSON.parse_string(JSON.stringify(module.project_thread(entry.journal,entry.input)))==entry.expected,"original TypeScript complete thread seed "+str(entry.journal.threadSeed))
		check(JSON.stringify(entry.journal)==before,"thread projection never changes persisted state")
	check(module.resolve_spot("open_water",Vector2(700,380))=="lake_center","stand-area inclusive first corner")
	check(module.resolve_spot("open_water",Vector2(980,560))=="lake_center","stand-area inclusive opposite corner")
	check(module.resolve_spot("open_water",Vector2(981,560)).is_empty(),"outside measured area rejected")
	check(module.resolve_spot("dock",Vector2(700,600))=="dock","dock on-foot standing area available")
	check(module.resolve_spot("channel",Vector2(836,470)).is_empty(),"narrow channel contains no photo location")
	var s: Dictionary=initial()
	var before: String=JSON.stringify(s)
	check(module.precheck_capture(s,"lake_center").accepted,"teaching-complete locked journal can precheck")
	check(JSON.stringify(s)==before,"capture precheck writes nothing")
	var request: Dictionary=module.request_capture(s,"lake_center")
	check(request.has("capture") and JSON.stringify(s)==before,"capture request produces capability without writing story facts")
	check(not module.finish_capture(s,{"sessionId":request.capture.session.id}).accepted,"dictionary receipt cannot forge photo")
	check(not module.finish_capture(s,Camera.new()).accepted,"another object cannot forge capability identity")
	check(not module.request_capture(s,"lake_center").accepted,"concurrent capture rejected")
	request.capture.session.fail_from_host("hidden_world")
	check(not module.cancel_capture(request.capture.session).accepted,"host cancellation reports capture failure")
	check(JSON.stringify(s)==before,"cancel does not create photo or draft")
	for invalid_key: String in ["source","zone","capturedAtSeconds","player"]:
		request=module.request_capture(s,"lake_center")
		var meta: Dictionary={"source":"world_viewport_crop","scene":"qizhen_lake","zone":"open_water","player":s.native.player.duplicate(),"speed":0,"roll":0,"heading":0,"capturedAtSeconds":1}
		match invalid_key:
			"source": meta.source="unknown_snapshot"
			"zone": meta.zone="dock"
			"capturedAtSeconds": meta.capturedAtSeconds=1.5
			"player": meta.player.x=10
		request.capture.session.receive_capture(test_path,meta)
		check(not module.finish_capture(s,request.capture.session).accepted and JSON.stringify(s)==before,"mismatched receipt rejected without facts: "+invalid_key)
	var result: Dictionary=capture(s,"lake_center")
	check(result.accepted and s.qizhenLake.journal.mainPhoto!=null,"real image receipt writes photo")
	check(s.qizhenLake.journal.pendingDraft.kind=="main" and s.qizhenLake.journal.status=="main_draft","main capture creates source main-draft state")
	check(s.qizhenLake.journal.pendingDraft.id=="qizhen-draft-"+str(result.photo.id),"draft ID matches source idempotence contract")
	check(module.image_for(result.photo)!=null,"saved image hash verifies and reloads")
	check(module.finish_capture(s,module.last_capture).duplicate,"exact resolved capability retry is idempotent")
	check(not module.precheck_main_publish(s).accepted,"unfilled main draft cannot publish")
	check(module.discard_draft(s,"close").discarded,"closing unsaved draft rolls it back")
	check(s.qizhenLake.journal.mainPhoto==null and s.qizhenLake.journal.pendingDraft==null and s.qizhenLake.journal.status=="capture_ready","main rollback removes unposted photo and restores capture-ready")
	capture(s,"lake_center")
	check(not module.save_draft(s,{"titleId":"not_an_authored_option","statusId":"status_still_afloat"}).accepted,"unknown option cannot become title")
	var choices: Dictionary={"titleId":"title_makeshift_boat","statusId":"status_still_afloat"}
	check(module.save_draft(s,choices).accepted,"authored title and status save")
	check(module.save_draft(s,choices).duplicate,"identical save idempotence")
	check(not module.discard_draft(s,"close").discarded,"closing saved draft retains it")
	check(module.discard_draft(s,"retake").discarded,"explicit retake rolls back saved unposted draft")
	check(s.qizhenLake.journal.mainTitleId==choices.titleId,"retake preserves main choice memory")
	capture(s,"lake_center")
	check(s.qizhenLake.journal.pendingDraft.titleId==choices.titleId,"retake draft restores title choice")
	var full: Dictionary=s.qizhenLake.journal.pendingDraft.duplicate(true)
	full.id="forged-id"
	check(not module.save_draft(s,full).accepted,"full draft mismatched identity rejected")
	s.networkMode="cellular"
	before=JSON.stringify(s)
	check(module.publish_main(s).reason=="offline" and JSON.stringify(s)==before,"offline main retains image choices and draft")
	s.networkMode="campus_wifi"
	check(module.publish_main(s).accepted,"campus wifi publishes main")
	check(s.qizhenLake.journal.status=="open" and s.qizhenLake.journal.publishedSpotIds==["lake_center"] and s.qizhenLake.journal.pendingDraft==null,"main transaction records unique thread and clears pending")
	check(int(s.qizhenLake.journal.threadSeed)>=1 and str(s.qizhenLake.journal.threadId)=="qizhen-journal-"+str(s.qizhenLake.journal.threadSeed),"thread ID derives persistent one-time seed")
	s.networkMode="cellular"
	before=JSON.stringify(s)
	check(module.publish_main(s).duplicate and JSON.stringify(s)==before,"already-posted main retry succeeds offline without writes")
	capture(s,"dock")
	check(s.qizhenLake.journal.pendingDraft.kind=="spot","optional capture always creates caption draft")
	check(not module.save_draft(s,{"captionId":"caption_swan_gone"}).accepted,"caption from another spot rejected")
	check(module.save_draft(s,{"captionId":"caption_dock_return"}).accepted,"authored per-spot caption saves")
	before=JSON.stringify(s)
	check(module.publish_reply(s,"dock").reason=="offline" and JSON.stringify(s)==before,"offline optional reply retains complete draft")
	s.networkMode="campus_wifi"
	check(module.publish_reply(s,"dock").accepted,"optional reply publishes into same thread")
	check(s.qizhenLake.journal.pendingDraft.captionId=="caption_dock_return","source retains caption-bearing pending draft")
	s.networkMode="cellular"
	check(module.publish_reply(s,"dock").duplicate,"optional published retry bypasses offline gate")
	check(module.discard_draft(s,"retake").discarded and s.qizhenLake.journal.optionalPhotos.has("dock"),"retake cannot delete already-published photo")
	capture(s,"reflection")
	check(module.discard_draft(s,"close").discarded and not s.qizhenLake.journal.optionalPhotos.has("reflection"),"unsaved optional close removes unposted photo")
	capture(s,"swan_cove")
	module.save_draft(s,{"captionId":"caption_swan_stare"})
	s.networkMode="campus_wifi"
	module.publish_reply(s,"swan_cove")
	check(not s.qizhenLake.journal.fishingAssistUnlocked and not s.qizhenLake.journal.fishingAssistConsumed and not s.qizhenLake.journal.memoryCardUnlocked,"optional photos invent no unwritten source assistance/reward")
	var projected: Dictionary=module.project_thread(s.qizhenLake.journal,s.qizhenLake)
	var expected_floor: int=2
	for reply: Dictionary in projected.replies:
		check(int(reply.floor)==expected_floor,"all projected floors stay contiguous")
		expected_floor+=1
	var builder: RefCounted=Pages.new()
	var ui: Control=builder.build("c3_journal",module.view("c3_journal",s),s)
	check(ui!=null and ui.get_meta("handles_all_actions"),"independent native thread builder handles all actions")
	ui.free()
	ui=builder.build("c3_journal_camera",module.view("c3_journal_camera",s),s)
	check(ui!=null,"independent camera builder supports caption draft")
	ui.free()
	s.qizhenLake.phase="swan_chase"
	check(module.precheck_capture(s,"dock").reason=="swan_chase" and module.publish_reply(s,"dock").reason=="swan_chase","chase rejects both capture and duplicate publication")
	s.qizhenLake.phase="complete"
	s.qizhenLake.journal.status="archived"
	check(module.precheck_capture(s,"dock").reason=="journal_archived" and module.publish_main(s).reason=="archived","archived journal is immutable")
	check(module.validate_journal_snapshot(s.qizhenLake.journal),"journal typed validator accepts real photos caption draft and archive")
	var saved: Dictionary=JSON.parse_string(JSON.stringify(s))
	check(JSON.parse_string(JSON.stringify(module.project_thread(saved.qizhenLake.journal,saved.qizhenLake)))==JSON.parse_string(JSON.stringify(module.project_thread(s.qizhenLake.journal,s.qizhenLake))),"JSON save/reload preserves thread identities floors and photos")
	var bad: Dictionary=s.qizhenLake.journal.duplicate(true)
	bad.mainPhoto.recipe.cropCenterX=INF
	check(not module.validate_journal_snapshot(bad),"journal typed validator rejects nonfinite recipe")
	bad=s.qizhenLake.journal.duplicate(true)
	bad.pendingDraft.id="fake"
	check(not module.validate_journal_snapshot(bad),"journal typed validator rejects orphan draft")
	bad=s.qizhenLake.journal.duplicate(true)
	bad.mainPhoto.nativeImagePath="user://qizhen_journal/../save.json"
	check(not module.validate_journal_snapshot(bad),"journal typed validator rejects image path traversal")
	# A copied recipe without the native actual-image receipt never substitutes art.
	check(module.image_for({"recipe":{"zone":"dock"}})==null,"missing photo remains missing rather than replaced by map")
	# Remove only synthetic unit files and controller-created copies in this isolated test home.
	created_paths.append(test_path)
	for path: String in created_paths:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	print("Qizhen journal: %d checks, %d errors" % [checks,errors])
	quit(0 if errors==0 else 1)
