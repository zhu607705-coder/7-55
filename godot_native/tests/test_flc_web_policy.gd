extends SceneTree
const Policy=preload("res://scripts/release_content_policy.gd")
const Content=preload("res://scripts/platform/web_content.gd")
var checks:=0
var failures:=0
class QuietContent extends "res://scripts/platform/web_content.gd":
	func _show_fatal()->void:pass
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func _initialize()->void:call_deferred("run")
func run()->void:
	check(Policy.flc_activity_available(),"approved activity available")
	check(Policy.family_available("flc_activity"),"activity family allowed")
	check(Policy.scene_available("res://campuses/future_learning_center/scripts/floor_view.gd"),"activity runtime scene allowed")
	if Policy.story_only():
		check(not Policy.campuses_available(),"research campuses remain unavailable")
		for family:String in Policy.CAMPUS_FAMILIES:check(not Policy.family_available(family),"research family rejected")
		check(not Policy.scene_available("res://campuses/buct/scenes/playable.tscn"),"BUCT scene rejected")
		check(not Policy.scene_available("res://campuses/future_learning_center/../buct/test.tscn"),"normalized path cannot escape whitelist")
	var record:Dictionary={"id":"flc_activity_001","family":"flc_activity","file":"content/flc.pck","bytes":1,"sha256":"1".repeat(64)}
	var manifest:Dictionary={"schema":"755-web-content-v1","core":{"file":"index.pck","bytes":1,"sha256":"0".repeat(64)},"packs":[record],"backgroundOrder":["chapter2","chapter3","chapter35","chapter4"]}
	var content:=QuietContent.new();root.add_child(content)
	check(content._configure_manifest(manifest,null),"activity manifest accepted")
	check(content._required_ids(["flc_activity"])==["flc_activity_001"],"activity request covers its actual pack")
	check(not content._ids_ready(["flc_activity_001"]),"unmounted activity is not ready")
	check(Content.required_families({"native":{"chapter":1}})==[],"ordinary first chapter does not fetch activity")
	manifest.packs=[]
	check(content._configure_manifest(manifest,null),"legacy story manifest remains valid")
	check(not await content.ensure_families(["flc_activity"]),"missing activity in stale manifest fails closed rather than empty readiness")
	content.queue_free();await process_frame
	print("FLC_WEB_POLICY ",checks," checks ",failures," failures");quit(1 if failures else 0)
