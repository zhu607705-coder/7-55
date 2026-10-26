extends SceneTree
## Missing real art must never activate cleanup, nodes, or adapted collision.
const Objects=preload("res://scripts/presentation/north_generated_objects.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func _initialize()->void:run.call_deferred()
func run()->void:
	OS.set_environment(Objects.PREVIEW_ENV,"1")
	var plate:Texture2D=load("res://assets/rpg/interiors/finale/chapter4-755/base/a1.png")
	var original:Array=[{"id":"a1_air_wall_005","x":1226,"y":584,"width":381,"height":12}]
	for missing_id:String in ["lectern_105","bookcase_105","blackboard_105","notice_105","plant_105","student_table","student_chair"]:
		var adapter:RefCounted=Objects.new();adapter.data=adapter.data.duplicate(true)
		for registration:Dictionary in adapter.asset_registrations():
			if registration.id==missing_id:registration.texture="res://missing_"+missing_id+"_fixture.png"
		adapter.configure("duan_yongping_temporal_maze","A1",plate)
		check(not adapter.active,"Missing "+missing_id+" disables the entire generated family")
		check(adapter.wall_composite==null,"Missing "+missing_id+" cannot erase the baked source props")
		check(adapter.adjusted_collisions(original)==original,"Missing "+missing_id+" preserves original collision")
		check(not adapter.owns_cover({"id":"a1_classroom_partition_face"}),"Missing "+missing_id+" restores source foreground")
		check(not adapter.owns_cover({"id":"a1_foreground_019"}),"Missing "+missing_id+" restores original lectern foreground")
		check(adapter.issues.has("missing:res://missing_"+missing_id+"_fixture.png"),"Missing prop has a precise diagnostic")
	for floor_id:String in ["A2","A3"]:
		var adapter:RefCounted=Objects.new();adapter.configure("duan_yongping_temporal_maze",floor_id,plate)
		check(not adapter.active and adapter.prop_textures.is_empty(),floor_id+" never loads A1 props")
		check(adapter.adjusted_collisions(original)==original,floor_id+" keeps source geometry")
	print("NORTH_PROP_FAIL_CLOSED: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
