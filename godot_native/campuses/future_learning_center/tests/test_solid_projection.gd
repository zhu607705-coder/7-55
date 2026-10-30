extends SceneTree
const Model=preload("res://campuses/future_learning_center/scripts/puzzles/solid_projection_model.gd")
const View=preload("res://campuses/future_learning_center/scripts/puzzles/solid_projection_view.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func finish(m)->void:
 for i:int in 10:m.step(.1)
func cell(index:int)->Vector3i:return Vector3i(index%2,(index/2)%2,index/4)
func _initialize()->void:
 var solutions:=[0,0];var height_fields:=[{},{}];var supported:=0
 for turn:int in 2:
  for a:int in 8:
   for b:int in 8:
    for c:int in 8:
     var m=Model.new();m.bar_turn=turn;m.poses.assign([cell(a),cell(b),cell(c)])
     if not m.valid(m.poses,turn):continue
     supported+=1
     for target:int in 2:
      m.extension=target==1
      if m.matches(0) and m.matches(1) and m.matches(2):
       solutions[target]+=1
       var vox:Array=m.voxels();vox.sort();height_fields[target][str(vox)]=true
 check(solutions==[4,4],"all four physical piece permutations accepted for each target")
 check(height_fields[0].size()==1 and height_fields[1].size()==1,"all three views plus support uniquely determine each height field")
 print("solid enumeration supported=",supported," accepted=",solutions)
 var m=Model.new();check(not m.place(1,Vector3i(0,0,1)),"floating cube rejected")
 check(m.place(0,Vector3i(0,0,0)),"long block horizontal base")
 check(m.place(1,Vector3i(1,0,1)) and m.place(2,Vector3i(1,1,0)),"first legal assembly")
 check(not m.place(0,Model.TRAY),"cannot remove supporting block under upper cube")
 m.start();finish(m);check(m.completed,"three projections actual exposure passes")
 var rev:int=m.revision;m.rotate_holder();check(m.revision==rev and m.receipts.size()==3,"holder rotation keeps notch-local proof")
 m=Model.new();m.rotate_bar();m.place(0,Vector3i(1,0,0));m.place(1,Vector3i(0,0,0));m.place(2,Vector3i(1,0,1));m.start();finish(m)
 check(m.completed,"alternate internal bar arrangement passes")
 m.set_extension(true);check(m.receipts.is_empty(),"target replacement invalidates proof")
 m=Model.new();m.set_extension(true);m.rotate_bar();m.place(0,Vector3i(0,0,0));m.place(1,Vector3i(0,1,1));m.place(2,Vector3i(1,1,0));m.start();finish(m)
 check(m.extension_completed,"masked side still validates supported target")
 check(not m.rotate_bar(),"rotation cannot destroy support or overlap")
 m.start();m.pause();finish(m);check(m.running and m.elapsed==0,"paused exposure frozen")
 m.cancel();finish(m);check(not m.running,"cancel stops exposure")
 var v=View.new();v.press_at(v.piece_position(0));v.model.advance_drag(.1);v.model.advance_drag(.1);v.move_at(v.project_point(v.piece_center_offset(0)));v.release_at(v.project_point(v.piece_center_offset(0)));v.model.advance_drag(.1);v.model.advance_drag(.1);check(v.model.poses[0]==Vector3i(0,0,0),"physical bar dropped into base")
 v.press_at(v.piece_position(1));v.model.advance_drag(.1);v.model.advance_drag(.1);v.move_at(v.project_point(Vector3(1,0,1)+v.piece_center_offset(1)));v.release_at(v.project_point(Vector3(1,0,1)+v.piece_center_offset(1)));v.model.advance_drag(.1);v.model.advance_drag(.1);check(v.model.poses[1]==Vector3i(1,0,1),"drop finds supported upper layer")
 v.press_at(v.piece_position(2));v.cancel_pointer();v.release_at(v.slot_point(1,1));check(v.model.poses[2]==Model.TRAY,"canceled drop preserves rack identity")
 v.press_at(v.sheet_position());v.release_at(Vector2(760,370));check(v.model.extension,"physical masked target sheet installed")
 v.model.start();v._notification(View.NOTIFICATION_APPLICATION_FOCUS_OUT);finish(v.model);check(not v.model.completed,"focus loss cannot validate unfinished build")
 v.close();finish(v.model);check(not v.model.running,"closed exposure canceled")
 v.show()
 var e:=InputEventScreenTouch.new();e.index=10;e.pressed=true;e.position=v.piece_position(2);v._gui_input(e)
 e=InputEventScreenTouch.new();e.index=11;e.pressed=true;e.position=v.piece_position(1);v._gui_input(e)
 check(v.touch_id==10 and v.held==2,"second finger cannot steal solid")
 var mouse:=InputEventMouseButton.new();mouse.device=InputEvent.DEVICE_ID_EMULATION;mouse.button_index=MOUSE_BUTTON_LEFT;mouse.pressed=true;mouse.position=Vector2(830,470);v._gui_input(mouse)
 check(not v.model.running and v.held==2,"emulated mouse ignored")
 e=InputEventScreenTouch.new();e.index=10;e.canceled=true;e.pressed=false;e.position=v.slot_point(1,1);v._gui_input(e)
 v.release_at(v.slot_point(1,1));check(v.model.poses[2]==Model.TRAY,"touchcancel late release cannot add volume")
 v.press_at(v.piece_position(2));v.release_at(Vector2(940,530));check(v.model.poses[2]==Model.TRAY,"outside drop remains on rack")
 v.press_at(v.sheet_position());v.cancel_pointer();v.release_at(Vector2(620,475));check(v.model.extension,"canceled sheet removal preserves target")
 e=InputEventScreenTouch.new();e.index=20;e.pressed=true;e.position=v.piece_position(2);v._gui_input(e)
 e=InputEventScreenTouch.new();e.index=20;e.pressed=true;e.canceled=true;e.position=v.piece_position(2);v._gui_input(e)
 check(v.touch_id==-1 and v.held==-1,"pressed cancellation releases owner")
 e=InputEventScreenTouch.new();e.index=21;e.pressed=true;e.position=v.piece_position(2);v._gui_input(e)
 check(v.touch_id==21,"new finger accepted after pressed cancellation")
 v.cancel_pointer()
 var transaction=View.new();var start:Vector2=transaction.piece_position(0)+Vector2(8,5);transaction.press_at(start)
 transaction.model.advance_drag(.1);transaction.model.advance_drag(.1);transaction.move_at(start+Vector2(100,20))
 check(transaction.piece_position(0).distance_to(start+Vector2(100,20)-Vector2(8,5))<.01,"same 3D solid follows hand with original grab offset")
 check(transaction.model.poses[0]==Model.TRAY and transaction.model.history.is_empty() and not transaction.model.start(),"carried geometry cannot fabricate assembly proof")
 var before:Vector3=transaction.model.preview_origin;transaction.move_at(Vector2(950,530));check(transaction.model.preview_origin==before,"illegal workspace motion stays at last admissible pose")
 transaction.release_at(Vector2(445,300));check(transaction.model.poses[0]==Model.TRAY,"far release cannot jump onto base")
 transaction.press_at(start);transaction.model.advance_drag(.1);transaction.model.advance_drag(.1);transaction.move_at(start+Vector2(100,20));transaction.cancel_pointer()
 check(transaction.piece_position(0)==View.RACK[0],"canceled hand motion restores rack solid")
 transaction.free()
 v.free();print("solid_projection: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
