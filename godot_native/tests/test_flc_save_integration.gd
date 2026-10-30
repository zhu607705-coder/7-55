extends SceneTree
## Actual-file tests: use the repository sandbox and platform-aware isolation guard.
const Codec=preload("res://scripts/flc_room_save.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error("FLC_SAVE_INTEGRATION: "+label)
func canonical(value:Variant)->Variant:return JSON.parse_string(JSON.stringify(value))
func _initialize()->void:call_deferred("run")
func run()->void:
 if not preload("res://tests/native_test_isolation.gd").is_isolated_save():
  push_error("Refusing to touch a nonisolated user-data directory");quit(2);return
 var state=root.get_node_or_null("State")
 if state==null:
  state=load("res://scripts/state.gd").new();root.add_child(state)
 state.developer_mode=false;state.d=state.initial()
 var prior:Dictionary=state.d.duplicate(true)
 check(state.validate_snapshot(prior),"old native state without namespace remains valid")
 check(state.save_game(),"old namespace-absent save writes")
 state.d=state.initial();check(state.load_game() and not state.d.native.has("flc_rooms"),"old save loads without fabricating rooms")
 var m=load(Codec.ROOT+Codec.ROOMS["2:formula"][0]).new()
 m.edit("panel",1);m.edit("tilt",1);m.edit("gear",1);m.place_on_track(true);m.start();m.step(30)
 var water=load(Codec.ROOT+Codec.ROOMS["3:pantry_water"][0]).new();water.water[0]=60;water.tap_open=true
 var location:Dictionary={"floor":2,"player":[500.0,600.0],"hour":12.0}
 check(state.commit_flc_snapshot({"2:formula":m,"3:pantry_water":water},location),"one batch commits independent apparatus and location")
 var written:Dictionary=state.d.native.flc_rooms.duplicate(true)
 check(state.d.items==prior.items and state.d.wallet==prior.wallet and state.d.chapter4==prior.chapter4,"room save changes no reward, inventory or chapter facts")
 state.d=state.initial();check(state.load_game(),"cold restart reads ordinary native file")
 check(canonical(state.d.native.flc_rooms)==canonical(written) and canonical(state.flc_location())==canonical(location),"room namespace and location retained")
 var restored=load(Codec.ROOT+Codec.ROOMS["2:formula"][0]).new()
 check(state.restore_flc_room("2:formula",restored) and restored.completed and restored.records.size()==1,"cold start restores measured completion")
 check(not restored.running and restored.ticks==0,"restart never advances interrupted machine")
 var restored_water=load(Codec.ROOT+Codec.ROOMS["3:pantry_water"][0]).new()
 check(state.restore_flc_room("3:pantry_water",restored_water) and restored_water.water[0]==60 and not restored_water.tap_open,"persist water but close tap on restart")
 var export_path:="user://flc-export.json"
 check(state.export_save(export_path)==OK,"portable export includes same validated namespace")
 state.d=state.initial();var imported:Dictionary=state.import_save(export_path)
 check(imported.get("ok",false) and canonical(state.d.native.flc_rooms)==canonical(written),"portable import retains room proof without browser normalizer")
 state.developer_mode=true
 check(not state.commit_flc_room("2:formula",m) and canonical(state.d.native.flc_rooms)==canonical(written),"preview mode cannot commit formal save")
 state.developer_mode=false
 state.d.wallet=-1 # force authoritative validator failure after checkpoint assembly
 var invalid_before:Dictionary=state.d.native.flc_rooms.duplicate(true)
 check(not state.commit_flc_location({"floor":3,"player":[1,2],"hour":9}) and state.d.native.flc_rooms==invalid_before,"failed authoritative save rolls namespace back")
 state.d=prior.duplicate(true);state.d.native.flc_rooms=written.duplicate(true)
 var bad:Dictionary=state.d.duplicate(true);bad.native.flc_rooms.rooms["2:formula"].fields.gear=88
 check(not state.validate_snapshot(bad),"import boundary rejects invalid room index")
 bad=state.d.duplicate(true);bad.native.flc_rooms.location.floor=4.5
 check(not state.validate_snapshot(bad),"fractional floor rejected")
 check(state.save_game(),"write valid primary before backup check")
 check(state.commit_flc_location({"floor":3,"player":[700,800],"hour":16}),"second save retains valid previous backup")
 var file=FileAccess.open(state.SAVE_PATH,FileAccess.WRITE);file.store_string("broken");file.close()
 state.d=state.initial();check(state.load_game() and canonical(state.flc_location())==canonical(location),"corrupt primary recovers prior namespace from backup")
 print("FLC_SAVE_INTEGRATION: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
