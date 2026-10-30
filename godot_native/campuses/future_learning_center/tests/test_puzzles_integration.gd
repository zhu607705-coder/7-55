extends SceneTree
const Floor = preload("res://campuses/future_learning_center/scripts/floor_view.gd")
const Stick = preload("res://campuses/future_learning_center/scripts/puzzles/walk_joystick.gd")
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
 var stick=Stick.new();root.add_child(stick);stick.position=Vector2(100,100);stick.scale=Vector2(1.5,1.5)
 var event:=InputEventScreenTouch.new();event.index=3;event.pressed=true;event.position=Vector2(244,205);stick._input(event)
 check(stick.pointer_id==3 and absf(stick.value.x-.5)<.01,"Scaled analog stick preserves half speed")
 event=InputEventScreenTouch.new();event.index=4;event.pressed=true;event.position=Vector2(205,205);stick._input(event)
 check(stick.pointer_id==3,"Second hand cannot steal movement touch")
 event.pressed=false;stick._input(event)
 check(stick.pointer_id==3,"Second hand release cannot stop first hand")
 event.index=3;event.canceled=true;stick._input(event)
 check(stick.pointer_id==-1 and stick.value==Vector2.ZERO,"Canceled touch releases movement")
 stick._move(Vector2(90,70));stick._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
 check(stick.value==Vector2.ZERO,"Focus loss releases movement")
 print("FLC_PUZZLES_INTEGRATION: %d checks, %d failures"%[checks,failures])
 world.queue_free();stick.queue_free()
 await process_frame
 quit(1 if failures else 0)
