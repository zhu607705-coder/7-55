extends SceneTree
const Save=preload("res://scripts/flc_room_save.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error("FLC_SAVE: "+label)
func model(id:String)->RefCounted:return load(Save.ROOT+Save.ROOMS[id][0]).new()
func wire(value:Variant)->Variant:return JSON.parse_string(JSON.stringify(value))
func round_trip(id:String,m:Object)->Object:
 var captured:=Save.capture(id,m)
 check(not captured.is_empty(),id+" captures")
 var fresh=model(id)
 check(Save.restore(id,fresh,wire(captured)),id+" restores real JSON")
 check(wire(Save.capture(id,fresh))==wire(captured),id+" checkpoint stable")
 return fresh
func _initialize()->void:
 var all:=Save.empty()
 for id:String in Save.ROOMS:
  var m=model(id)
  var known:Dictionary={}
  for prop:Dictionary in m.get_property_list():
   if int(prop.usage)&PROPERTY_USAGE_SCRIPT_VARIABLE:known[prop.name]=true
  for field:String in Save.ROOMS[id][1]:check(known.has(field) and Save.SCHEMA[id].fields.has(field),id+" captured field exists in current model/schema: "+field)
  for field:String in Save.SCHEMA[id].reset:
   check(known.has(field) and wire(Save.encode(m.get(field)))==wire(Save.SCHEMA[id].reset[field]),id+" reset matches current default: "+field)
  var p:=Save.capture(id,m);all.rooms[id]=p
  var n=round_trip(id,m)
  for field:String in Save.ROOMS[id][1]:
   var original:Variant=m.get(field);var restored:Variant=n.get(field)
   check(typeof(original)==typeof(restored),id+" restored property type: "+field)
   if original is Array:check(original.get_typed_builtin()==restored.get_typed_builtin(),id+" restored array element type: "+field)
  check(not n.get("completed") if "completed" in Save.ROOMS[id][1] else not n.get("earned"),id+" no initial completion")
  var bad:Dictionary=p.duplicate(true);bad.fields["running"]=true
  check(not Save.restore(id,n,bad),id+" unknown field rejected")
 check(Save.ROOMS.size()==29 and Save.valid(wire(all)),"25 canonical plus four isolated apparatus, no room count inferred")
 check(Save.valid(Save.empty()),"old absent namespace maps to empty")
 var m=model("2:formula");m.edit("panel",1);m.edit("tilt",1);m.edit("gear",1);m.place_on_track(true);m.start();m.step(30)
 var n=round_trip("2:formula",m)
 check(n.completed and n.records.size()==1 and n.personal_best[0]>62,"earned race persists with measured record")
 check(not n.running and n.ticks==0 and not n.on_track,"race does not restart or fake additional ticks")
 m.place_on_track(true);m.start();m.step(3);n=round_trip("2:formula",m)
 check(not n.running and n.records.size()==1,"unfinished race never becomes new result")
 var p:=Save.capture("2:formula",m);p.fields.gear=99
 var before:=Save.capture("2:formula",n)
 check(not Save.restore("2:formula",n,p) and Save.capture("2:formula",n)==before,"invalid restore is nonmutating")
 p=Save.capture("2:formula",m);p.fields.records=Save.encode([{"won":true}])
 check(not Save.valid_room("2:formula",p),"malformed historical record rejected before notebook can read it")
 m=model("2:platform");m.move_board(Vector2(700,210));m.move_board(Vector2(700,430));m.shutter()
 for i:int in 6:m.step(.1)
 n=round_trip("2:platform",m)
 check(n.records.has(0) and n.records[0].board is Vector2,"numeric receipt keys and nested vectors survive JSON")
 m=model("4:storage");m.swing_to(.5);n=round_trip("4:storage",m)
 check(n.positions is Array and n.positions.is_typed() and n.positions[0] is Vector2,"typed vector arrays restored")
 m=model("2:machinery");m.start_cut(0);m.step(.4);m.cancel();n=round_trip("2:machinery",m)
 check(n.kerfs[0] is PackedVector2Array and n.progress[0]>0 and not n.running,"actual partial kerf survives but cutter motor does not restart")
 m=model("2:robot_delivery");n=round_trip("2:robot_delivery",m)
 check(n.tiles.has(Vector2i(2,1)) and n.tiles[Vector2i(2,1)].kind=="oneway","Vector2i map keys preserve authored module identities")
 m=model("3:pantry_water");m.water[0]=60;m.tap_open=true;n=round_trip("3:pantry_water",m)
 check(n.water[0]==60 and not n.tap_open and n.phase=="table","water persists, unattended tap stops")
 m=model("3:studio_4");m.set_cover(false);m.slide_to(180);n=round_trip("3:studio_4",m)
 check(n.insertion==m.insertion and not n.cover,"assembly geometry persists without synthetic open-close cycle")
 m=model("3:xlab_south");m.change_route(1);m.start()
 for i:int in 20:m.step(.1)
 n=round_trip("3:xlab_south",m)
 check(n.operated and n.trial_revision==n.revision and not n.running,"completed unfolded electrical proof survives while timer stops")
 n.swing_to(0,PI);n.swing_to(1,PI)
 check(n.completed,"continue physical folding after restart using same completed electrical proof")
 n.swing_to(1,0);n.swing_to(0,0);check(not Save.capture("3:xlab_south",n).is_empty(),"floating-point roundoff at unfolded stop is accepted")
 m=model("3:studio_4");m.set_cover(false);m.slide_to(185);m.set_cover(true);m.swing_to(PI/2)
 n=round_trip("3:studio_4",m);n.swing_to(0)
 check(n.completed,"saved actual open pose can finish actual closing, no replayed animation")
 m=model("2:electrical");m.set_reverse(true);n=round_trip("2:electrical",m)
 check(n.travel==.92 and not n.running,"reverse apparatus resumes at correct physical origin")
 m=model("3:pantry");m.delivered=true;m.completed=true;n=round_trip("3:pantry",m)
 check(n.travel==1,"delivered tray remains at destination rather than jumping to source")
 m=model("4:seminar_2");m.begin_drag(0);m.drag_to(Vector2(200,310));m.end_drag()
 var pose:Vector2=m.pose(0);n=round_trip("4:seminar_2",m)
 check(n.pose(0)==pose and n.edge_fraction[0]>.1,"committed mid-edge cart remains at physical resting pose")
 m.set_extension(true);n=round_trip("4:seminar_2",m)
 check(n.extension_trial_armed and n.lengths[0]==2,"actual extension eligibility survives restart")
 for bad_case:Array in [["2:robot_delivery","last_trace",[1]],["3:pantry_water","cups",[0,0,0,0]],["4:seminar_2","positions",[999,8]],["2:solar_bench","best",{0:{}}]]:
  var bad_model=model(bad_case[0]);var bad_payload:=Save.capture(bad_case[0],bad_model)
  bad_payload.fields[bad_case[1]]=Save.encode(bad_case[2])
  check(not Save.valid_room(bad_case[0],bad_payload),"malformed nested type or finite domain rejected: "+bad_case[1])
 m=model("4:seminar_1");m.place(0,0);m.place(1,1);m.start(0);m.step(1)
 for i:int in 65:m.place(2,0);m.place(3,1);m.start(0);m.step(1)
 n=round_trip("4:seminar_1",m)
 for device in [m,n]:device.place(0,2);device.place(1,3);device.start(1);device.step(1)
 check(not m.completed and not n.completed,"old station-zero pair remains excluded after more than64 observations")
 check(not Save.valid_location({"floor":5,"player":[10,20],"hour":12}),"invalid floor rejected")
 check(not Save.valid_location({"floor":2,"player":[NAN,20],"hour":12}),"nonfinite location rejected")
 all.location={"floor":3,"player":[500,600],"hour":18.0}
 check(Save.valid(wire(all)),"optional location survives JSON")
 all.rooms["unknown:room"]={}
 check(not Save.valid(all),"unknown room ID rejected")
 print("FLC_ROOM_SAVE: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
