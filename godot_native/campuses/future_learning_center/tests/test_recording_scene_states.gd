extends SceneTree
## Gesture and presentation regression; state is never awarded by visual settling.
const RecordingView=preload("res://campuses/future_learning_center/scripts/puzzles/recording_view.gd")
const SyncView=preload("res://campuses/future_learning_center/scripts/puzzles/sync_view.gd")
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
func key(v,code:int)->void:
 var e:=InputEventKey.new();e.keycode=code;e.pressed=true;v._input(e)
func tick(v,count:int)->void:
 for i:int in count:v._process(.1)
func run()->void:
 var r=RecordingView.new();root.add_child(r);r.open();r.set_process(false)
 check(r.visuals!=null,"recording generated scene exists")
 r.model.move_baffle(150);r.model.drive(1);r.model.step(.1)
 var arrived_x:float=r.model.x;var rev:int=r.model.revision
 touch(r,2,Vector2(441,130),true);motion(r,2,Vector2(441,180))
 check(r.model.baffle_y==200 and not r.model.running,"drag keeps exact off-center grip and stops feed")
 check(r.model.revision>rev,"live collision drag records change")
 if r.visuals!=null:check(r.visuals.object_at("Baffle",Vector2.ZERO)==Vector2(441,200),"sprite directly follows constrained model")
 motion(r,3,Vector2(441,270));mouse(r,Vector2(670,185),false)
 check(r.model.baffle_y==200 and r.touch_id==2,"foreign input cannot move/release drag")
 touch(r,2,Vector2(441,180),true,true)
 check(r.model.baffle_y==150 and r.model.revision==rev and r.touch_id==-1,"cancel restores only edited pose/revision")
 check(r.model.x==arrived_x and not r.model.running and not r.model.photographing,"cancel retains travelled position and safety stop")
 touch(r,2,Vector2(441,300),false);mouse(r,Vector2(670,185),true,true);mouse(r,Vector2(670,185),false,true)
 check(not r.model.photographing and r.model.baffle_y==150,"late and synthesized releases inert")
 r.model.x=440
 touch(r,4,Vector2(441,150),true);motion(r,4,Vector2(441,300))
 check(r.model.baffle_y<=224.001 and not r.model.baffle(r.model.baffle_y).intersects(r.model.carriage(r.model.x)),"swept baffle cannot cross carriage")
 r._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
 check(r.model.baffle_y==150 and r.model.x==440 and not r.baffle_drag,"focus rollback keeps actual carriage")
 r.model.x=220
 touch(r,5,Vector2(733,216),true);motion(r,5,Vector2(733,265))
 check(r.drive_handle_y()==259 and r.model.direction==0,"drive handle preview follows exact grab offset without starting motor")
 touch(r,5,Vector2(733,265),false)
 check(r.model.direction==1,"detent release commits drive")
 tick(r,70);check(r.model.x==670 and r.model.reached_round==r.model.round_id,"actual forward travel reaches current round")
 touch(r,6,Vector2(441,150),true);motion(r,6,Vector2(441,300));touch(r,6,Vector2(441,300),false)
 var reached:int=r.model.reached_round
 check(reached==r.model.round_id and r.model.light_blocked(),"post-arrival shade preserves arrival evidence")
 mouse(r,Vector2(670,185),true);mouse(r,Vector2(670,185),false)
 tick(r,3);check(r.model.photographing and not r.model.completed,"partial exposure is not completion")
 tick(r,4);check(r.model.completed and r.model.photo_kind=="clear" and r.model.photo_round==reached,"model exposure completes same-round photograph")
 var history_count:int=r.model.history.size();r._sync_visuals(.5)
 check(r.model.history.size()==history_count,"visual sync does not award a second photo")
 r.close();r.open();check(r.model.completed and r.model.x==670 and not r.model.photographing,"reentry preserves result but not active exposure")
 mouse(r,Vector2(640,445),true);mouse(r,Vector2(640,445),false)
 check(r.model.x==652 and r.model.reached_round==-1 and r.wheel_angle<0,"left handwheel stroke moves18 and invalidates arrival")
 tick(r,2);check(r.wheel_angle==0,"short wheel response settles")
 key(r,KEY_RIGHT);check(r.model.x==670,"keyboard right performs short forward stroke")
 key(r,KEY_UP);check(r.model.baffle_y==290,"keyboard up moves plate by constrained increment")
 key(r,KEY_ENTER);check(r.model.photographing,"keyboard enter requests exposure")
 r._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT);check(not r.model.photographing,"focus stops keyboard exposure")
 r.queue_free()
 var s=SyncView.new();root.add_child(s);s.open();s.set_process(false)
 check(s.visuals!=null,"sync generated scene exists")
 s.model.start();tick(s,4);var travel:float=s.model.travel;var elapsed:float=s.model.elapsed;rev=s.model.revision
 touch(s,10,Vector2(450,260),true);motion(s,10,Vector2(312,260))
 check(s.model.offsets[1]==-138 and s.model.aligned() and not s.model.running,"strip follows exact pointer delta and cancels pending run")
 check(s.model.travel==travel and s.model.elapsed==elapsed,"edit does not rewind physical trial state")
 if s.visuals!=null:
  check(s.visuals.objects.Paper1Tile1.position.x==s.visuals.PAPER_APERTURE_SIZE.x*.5-138,"generated paper pixels move together with record origin")
  check(s.visuals.paper_windows[1].clip_contents,"paper pixels clipped in guide aperture")
 motion(s,11,Vector2(220,260));touch(s,11,Vector2(220,260),false)
 check(s.model.offsets[1]==-138 and s.touch_id==10,"foreign strip pointer rejected")
 touch(s,10,Vector2(312,260),false,true)
 check(s.model.offsets[1]==0 and s.model.revision==rev and not s.model.running,"strip cancel restores offset/revision without resurrecting run")
 check(s.model.travel==travel and s.model.elapsed==elapsed,"strip cancel retains real trial progression")
 touch(s,12,Vector2(450,260),true);motion(s,12,Vector2(312,260));touch(s,12,Vector2(312,260),false)
 mouse(s,Vector2(740,383),true);mouse(s,Vector2(740,383),false)
 tick(s,26);check(s.model.travel==1 and s.model.gate==0 and not s.model.completed,"carriage arrives before gate starts")
 tick(s,2);check(s.model.gate>0 and s.model.gate<1 and not s.model.completed,"gate follows continuous model intermediate state")
 tick(s,5);check(s.model.completed and s.model.receipts.back().passed,"aligned full trial completes only in model")
 var receipts:int=s.model.receipts.size();s._sync_visuals(.5);check(s.model.receipts.size()==receipts,"visual state does not create receipt")
 mouse(s,Vector2(850,464),true);mouse(s,Vector2(850,464),false)
 check(s.model.dataset==1 and s.model.offsets==[0.0,0.0] and s.model.completed and not s.model.transfer_completed,"visible roll center replaces data preserving prior completion")
 touch(s,13,Vector2(450,260),true);motion(s,13,Vector2(542,260));touch(s,13,Vector2(542,260),false)
 mouse(s,Vector2(740,383),true);mouse(s,Vector2(740,383),false);tick(s,34)
 check(s.model.transfer_completed,"second roll completes with different origin")
 s.close();s.open();check(s.model.transfer_completed and s.model.offsets[1]==92 and not s.model.running,"sync reentry retains result and paper origins")
 key(s,KEY_UP);key(s,KEY_LEFT);check(s.model.offsets[0]==-2,"keyboard selects and shifts camera strip")
 key(s,KEY_DOWN);key(s,KEY_RIGHT);check(s.model.offsets[1]==94,"keyboard selects and shifts sensor strip")
 key(s,KEY_ENTER);check(s.model.running,"keyboard starts trial")
 s._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT);key(s,KEY_ENTER);check(not s.model.paused,"keyboard resumes paused trial")
 key(s,KEY_ESCAPE);check(not s.visible and not s.model.running,"keyboard escape closes without live trial")
 s.queue_free()
 print("FLC_RECORDING_SCENE_STATES %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
