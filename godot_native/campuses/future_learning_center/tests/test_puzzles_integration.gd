extends SceneTree
const Floor = preload("res://campuses/future_learning_center/scripts/floor_view.gd")
const Stick = preload("res://campuses/future_learning_center/scripts/touch_stick.gd")
var checks:=0
var failures:=0
func check(value:bool,message:String)->void:
 checks+=1
 if not value:failures+=1;push_error(message)
func _initialize()->void:call_deferred("run")
func run()->void:
 var world=Floor.new();root.add_child(world);world.user_control=false
 check(world.load_floor(4),"4F loads")
 check(Floor.PuzzleAnchors.size()==24,"24 registry stations plus original electrical workbench cover 25 rooms")
 check(world.puzzle_views.is_empty(),"Stations are lazy, not all running")
 var anchors:Dictionary={}
 for key:String in Floor.PuzzleAnchors:
  var id:String=str(Floor.PuzzleAnchors[key][2])+":"+str(Floor.PuzzleAnchors[key][1])
  check(not anchors.has(id),"One visible object owns one registry entry: "+id);anchors[id]=true
 for id:String in ["2:formula_workbench_0","2:robotics_workbench_30","2:team_desk_6","3:pantry_pantry_island_250","2:electrical_assembly_bench"]:
  check(not anchors.has(id),"External physical anchor is not overwritten: "+id);anchors[id]=true
 check(anchors.size()==29,"25 rooms retain 29 distinct activity objects, not 29 rooms")
 check(not world.open_puzzle("flex_c"),"Remote click cannot teleport into station")
 for key:String in Floor.PuzzleAnchors:
  var station_floor:int=Floor.PuzzleAnchors[key][2]
  world.load_floor(station_floor)
  check(not world.puzzle_anchor(key).is_empty(),"Existing furniture anchor: "+key)
  var point:Vector2=world.puzzle_approach(key)
  check(point.is_finite(),"Legal path to station: "+key)
  if not point.is_finite():continue
  check(world.set_foot(point),"Legal approach: "+key)
  var previous:Vector2=world.player
  world.point_action(world.Space.rect(world.puzzle_anchor(key).bounds).get_center())
  check(world.active_puzzle!=null,"Object click opens native station: "+key)
  if world.active_puzzle==null:continue
  var station:Control=world.active_puzzle
  var model=station.model
  check(station.visible and not world.ui.visible,"World UI hidden in station")
  station.close()
  check(world.player==previous and world.ui.visible,"Close returns same place")
  check(world.open_puzzle(key) and world.active_puzzle.model==model,"Reopen preserves model")
  world.load_floor(4 if station_floor==2 else 2)
  check(world.active_puzzle==null and not station.visible,"Transit closes station")
  check(not world.open_puzzle(key),"No station from another floor")
  world.load_floor(4)
 world.load_floor(2)
 var bench_point:Array=world.data.workshopReference.approach
 check(world.set_foot(Vector2(bench_point[0],bench_point[1])),"Original electrical approach remains legal")
 var bench_player:Vector2=world.player
 world.point_action(world.Space.rect(world.workshop_bench().bounds).get_center())
 check(world.workbench.visible and not world.ui.visible,"Original electrical object still opens")
 var bench_model=world.workbench.model
 world.workbench.close()
 check(world.ui.visible and world.player==bench_player,"Electrical returns to same floor position")
 check(world.open_workbench() and world.workbench.model==bench_model,"Electrical preserves model on reopening")
 world.load_floor(3)
 check(not world.workbench.visible,"Floor transit closes electrical")
 for mode:String in ["solar","robotics","signal","pantry"]:
  world.load_floor(3 if mode=="pantry" else 2)
  var object:Dictionary
  var approach:Vector2
  var station:Control
  var key:String={"solar":"formula","robotics":"robotics","signal":"team","pantry":"pantry"}[mode]
  if mode=="pantry":object=world.pantry_desk();approach=world.pantry_approach();station=world.pantry_tray
  elif mode=="signal":object=world.signal_sync_desk();approach=world.signal_sync_approach();station=world.signal_sync
  else:object=world.motion_desk(mode);approach=world.motion_approach(mode);station=world.motion_lab
  check(not object.is_empty() and approach.is_finite(),"External real object and legal approach: "+mode)
  if object.is_empty() or not approach.is_finite():continue
  check(world.set_foot(approach),"Stand at external object: "+mode)
  var saved:Vector2=world.player
  world.point_action(world.Space.rect(object.bounds).get_center())
  check(station.visible and not world.ui.visible and visible_stations(world)==1,"World object click opens only external "+mode)
  var other:Dictionary=world.puzzle_anchor(key)
  check(not other.is_empty() and other.id!=object.id,"Original and external mechanism have separate visible objects: "+mode)
  world.point_action(world.Space.rect(other.bounds).get_center())
  check(visible_stations(world)==1 and station.visible,"Underlying station click cannot overlap external "+mode)
  check(not world.open_puzzle(key),"Registry API cannot open through external modal "+mode)
  check(world.route.is_empty() and world.puzzle_pending.is_empty(),"Modal object click cannot queue background walking "+mode)
  station.close()
  check(world.player==saved and world.ui.visible and visible_stations(world)==0,"External close restores same floor position: "+mode)
  check(world.set_foot(world.puzzle_approach(key)),"Reach retained original mechanism: "+mode)
  world.point_action(world.Space.rect(other.bounds).get_center())
  check(is_instance_valid(world.active_puzzle) and visible_stations(world)==1,"Original mechanism still opens from its separate object: "+mode)
  var blocked:bool
  if mode=="pantry":blocked=not world.open_pantry()
  elif mode=="signal":blocked=not world.open_signal_sync()
  else:blocked=not world.open_motion_lab(mode)
  check(blocked and visible_stations(world)==1,"External API cannot overlap registry station: "+mode)
  if is_instance_valid(world.active_puzzle):world.active_puzzle.close()
 var stick=Stick.new();root.add_child(stick);stick.position=Vector2(100,100);stick.scale=Vector2(1.5,1.5)
 var transform:Transform2D=stick.get_global_transform_with_canvas()
 var event:=InputEventScreenTouch.new();event.index=3;event.pressed=true;event.position=transform*(Stick.CENTER+Vector2(Stick.RADIUS*.5,0));stick._input(event)
 check(stick.pointer_owner==3 and absf(stick.value.x-.5)<.01,"Actual main analog stick preserves scaled half speed")
 event=InputEventScreenTouch.new();event.index=4;event.pressed=true;event.position=transform*Stick.CENTER;stick._input(event)
 check(stick.pointer_owner==3,"Second hand cannot steal movement touch")
 event.pressed=false;stick._input(event)
 check(stick.pointer_owner==3,"Second hand release cannot stop first hand")
 event.index=3;event.pressed=true;event.canceled=true;stick._input(event)
 check(stick.pointer_owner==-2 and stick.value==Vector2.ZERO,"Pressed canceled touch releases movement")
 stick._input(event);check(stick.pointer_owner==-2,"Orphan canceled press cannot reacquire stick")
 var mouse:=InputEventMouseButton.new();mouse.device=InputEvent.DEVICE_ID_EMULATION;mouse.button_index=MOUSE_BUTTON_LEFT;mouse.pressed=true;mouse.position=transform*(Stick.CENTER+Vector2(25,0));stick._input(mouse)
 check(stick.pointer_owner==-2 and stick.value==Vector2.ZERO,"Emulated mouse never duplicates a canceled finger")
 event.canceled=false;event.pressed=true;event.position=transform*(Stick.CENTER+Vector2(0,26));stick._input(event)
 var motion:=InputEventScreenDrag.new();motion.index=3;motion.position=transform*(Stick.CENTER+Vector2(-26,0));stick._input(motion)
 check(stick.pointer_owner==3 and absf(stick.value.x+.5)<.01,"Scaled drag follows actual local joystick geometry")
 stick._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
 check(stick.value==Vector2.ZERO and stick.pointer_owner==-2,"Focus loss releases movement")
 print("FLC_PUZZLES_INTEGRATION: %d checks, %d failures"%[checks,failures])
 world.queue_free();stick.queue_free()
 await process_frame
 quit(1 if failures else 0)

func visible_stations(world:Node)->int:
 var count:=0
 for station:Control in [world.workbench,world.motion_lab,world.signal_sync,world.pantry_tray]:
  if is_instance_valid(station) and station.visible:count+=1
 for station:Control in world.puzzle_views.values():
  if is_instance_valid(station) and station.visible:count+=1
 return count
