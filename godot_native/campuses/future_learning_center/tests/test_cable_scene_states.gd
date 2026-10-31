extends SceneTree
const SignalView=preload("res://campuses/future_learning_center/scripts/puzzles/signal_sync_view.gd")
const FlexView=preload("res://campuses/future_learning_center/scripts/puzzles/flex_view.gd")
var checks:=0
var failures:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func touch(v,id:int,at:Vector2,down:bool,canceled:=false)->void:
 var e:=InputEventScreenTouch.new();e.index=id;e.position=at;e.pressed=down;e.canceled=canceled;v._input(e)
func motion(v,id:int,at:Vector2)->void:
 var e:=InputEventScreenDrag.new();e.index=id;e.position=at;v._input(e)
func mouse(v,at:Vector2,down:bool,emulated:=false)->void:
 var e:=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.position=at;e.pressed=down
 if emulated:e.device=InputEvent.DEVICE_ID_EMULATION
 v._input(e)
func mouse_motion(v,at:Vector2)->void:
 var e:=InputEventMouseMotion.new();e.position=at;v._input(e)
func key(v,code:int)->void:
 var e:=InputEventKey.new();e.keycode=code;e.pressed=true;v._input(e)
func tick(v,count:int)->void:
 for i:int in count:v._process(.1)
func run()->void:
 var s=SignalView.new();root.add_child(s);s.open();s.set_process(false)
 check(s.visuals!=null,"signal has generated raster scene")
 var wiring:Dictionary=s.model.cables.duplicate();var revision:int=s.model.revision
 touch(s,1,Vector2(690,175),true);motion(s,1,Vector2(750,215))
 check(s.model.positions[0]==Vector2(740,220),"screen follows exact off-center grip on same event")
 check(s.port_at("screen_a")==Vector2(660,245),"port follows same physical screen identity")
 check(s.model.cables==wiring and s.model.revision==revision,"moving screen cannot rewire or invalidate receipts")
 if s.visuals!=null:check(s.visuals.objects.Monitor0.position==s.model.positions[0],"monitor pixels and model pose agree")
 motion(s,2,Vector2(610,150));mouse(s,Vector2(150,225),false)
 check(s.touch_id==1 and s.model.positions[0]==Vector2(740,220),"foreign pointers cannot move or release screen")
 touch(s,1,Vector2(750,215),false,true)
 check(s.model.positions[0]==Vector2(680,180) and s.touch_id==-1,"screen cancel restores original pose")
 touch(s,1,Vector2(750,215),false)
 check(s.model.positions[0]==Vector2(680,180),"late touch release is inert")
 mouse(s,Vector2(690,175),true);touch(s,2,Vector2(150,225),true);mouse_motion(s,Vector2(750,215))
 check(s.mouse_owned and s.touch_id==-1 and not s.model.running,"mouse owns gesture against second touch")
 s._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
 check(not s.mouse_owned and s.model.positions[0]==Vector2(680,180),"focus cancels screen movement")
 touch(s,3,s.port_at("screen_b")+Vector2(6,3),true)
 motion(s,3,s.port_at("live_b")+Vector2(6,3));touch(s,3,s.port_at("live_b")+Vector2(6,3),false)
 check(s.model.cables.screen_b=="live_b","off-center plug drop uses grasp offset")
 mouse(s,Vector2(150,225),true,true);mouse(s,Vector2(150,225),false,true)
 check(not s.model.running,"emulated mouse cannot change source")
 mouse(s,Vector2(150,225),true);mouse(s,Vector2(150,225),false);tick(s,8)
 check(s.model.screens==[1,2] and not s.model.completed,"A arrives before B; no animation-only proof")
 tick(s,6);check(s.model.receipts.size()==1 and not s.model.completed,"one source pattern is insufficient")
 s._sync_visuals(10);check(s.model.receipts.size()==1,"visual settle cannot add receipt")
 key(s,KEY_ENTER);tick(s,14);check(s.model.completed and s.model.receipts.size()==2,"keyboard source action provides second real model pattern")
 key(s,KEY_TAB);key(s,KEY_RIGHT)
 check(s.model.positions[0]==Vector2(690,180) and s.model.receipts.size()==2,"keyboard screen move preserves wiring proof")
 s.close();s.open();check(s.model.completed and s.model.cables.screen_b=="live_b","signal reentry retains identity and result")
 s.queue_free()
 var f=FlexView.new();root.add_child(f);f.open();f.set_process(false)
 check(f.visuals!=null,"flex has generated raster scene")
 var identity:int=f.visuals.board.get_instance_id() if f.visuals!=null else -1
 var cable_identity:int=f.visuals.cables.Cable0.get_instance_id() if f.visuals!=null else -1
 mouse(f,Vector2(610,232),true)
 check(f.pending_unplug==0 and f.model.connections==[0,1,2],"mouse-down only lifts plug; does not disconnect model")
 touch(f,4,Vector2(730,300),true);touch(f,4,Vector2(730,300),false)
 check(f.mouse_owned and f.touch_id==-1 and not f.model.running,"foreign touch cannot start trial while mouse owns plug")
 f._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
 check(f.model.connections==[0,1,2] and not f.mouse_owned,"focus preserves pending unplug")
 mouse(f,Vector2(400,400),false);check(f.model.connections==[0,1,2],"late mouse release cannot unplug")
 touch(f,5,Vector2(610,232),true);motion(f,5,Vector2(450,420));touch(f,5,Vector2(450,420),false,true)
 check(f.model.connections==[0,1,2],"touch cancel preserves plug")
 touch(f,6,Vector2(610,232),true);touch(f,6,Vector2(1100,420),false)
 check(f.model.connections==[0,1,2],"outside viewport release cancels unplug")
 touch(f,7,Vector2(610,232),true);touch(f,7,Vector2(450,420),false)
 check(f.model.connections==[-1,1,2],"owned blank-space drop unplugs once")
 f.model.edit(0,0)
 mouse(f,Vector2(730,300),true);mouse(f,Vector2(730,300),false);tick(f,16)
 check(f.model.records.size()==1 and not f.model.station_proofs[0],"single first-station trial not proof")
 mouse(f,Vector2(730,300),true);mouse(f,Vector2(730,300),false);tick(f,16)
 check(f.model.station_proofs[0] and not f.model.completed,"two changed patterns prove station A only")
 var connections:Array=f.model.connections.duplicate();revision=f.model.revision
 touch(f,8,Vector2(490,122),true);motion(f,8,Vector2(530,152))
 f.keyboard_index=6;key(f,KEY_ENTER)
 check(not f.model.running,"keyboard cannot start trial during pointer-owned board preview")
 check(f.board_offset()==Vector2(40,30) and f.model.station==0,"same board follows exact handle grasp; station not committed during drag")
 if f.visuals!=null:check(f.visuals.board.position==f.board_offset(),"all board sprites transform on same event")
 touch(f,8,Vector2(530,152),false,true)
 check(f.board_offset()==Vector2.ZERO and f.model.station==0 and f.model.revision==revision,"canceled transfer restores station pose without model write")
 touch(f,9,Vector2(480,122),true);motion(f,9,Vector2(794,205));touch(f,9,Vector2(794,205),false);tick(f,4)
 check(f.model.station==1 and f.board_offset()==Vector2(30,14),"accepted transfer settles at station B")
 check(f.model.connections==connections and f.model.station_proofs[0],"same cables and prior station proof survive move")
 if f.visuals!=null:
  check(f.visuals.board.get_instance_id()==identity and f.visuals.cables.Cable0.get_instance_id()==cable_identity,"board and cable node identities never duplicated on transfer")
  check(f.visuals.objects.Socket0_0.position==Vector2(350,232),"socket remains fixed in board-local coordinates")
 mouse(f,Vector2(730,300),true);mouse(f,Vector2(730,300),false);tick(f,16)
 check(not f.model.records.back().valid and not f.model.completed,"same screen-space connection fails changed station roles")
 for i:int in 2:
  mouse(f,f.from_board(Vector2(275,164)),true);mouse(f,f.from_board(Vector2(275,164)),false)
 check(f.model.orientation==2 and f.model.connections==connections,"adapter turns source roles without rewiring")
 for i:int in 2:
  mouse(f,Vector2(730,300),true);mouse(f,Vector2(730,300),false);tick(f,16)
 check(f.model.completed,"second station requires two valid patterns")
 var records:int=f.model.records.size();f._sync_visuals(5);check(f.model.records.size()==records,"presentation cannot award station proof")
 var grip:Vector2=f.route_grip(1)
 touch(f,10,grip+Vector2(4,2),true);motion(f,10,f.route_seat(1,false)+Vector2(4,2));touch(f,10,f.route_seat(1,false)+Vector2(4,2),false)
 check(not f.model.outer[1] and f.model.cable_status(1)=="blocked","route drop transformed with grasp offset reaches model collision")
 check(f.from_board(f.model.point_at_distance(f.model.cable_path(1),f.model.failure_distance(1)))==Vector2(501,316),"failure point uses same station translation")
 f.close();f.open();check(f.model.completed and f.model.station==1 and f.board_offset()==Vector2(30,14),"flex reentry retains same model result and transform")
 f.keyboard_index=3;key(f,KEY_ENTER);check(f.model.orientation==0,"keyboard rotates physical adapter")
 f.keyboard_index=4;key(f,KEY_ENTER);check(f.model.station==0,"keyboard moves same board")
 key(f,KEY_ESCAPE);check(not f.visible and not f.model.running,"keyboard close clears active trial")
 f.queue_free();await process_frame
 print("FLC_CABLE_SCENE_STATES %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
