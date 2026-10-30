extends SceneTree
const Model=preload("res://campuses/future_learning_center/scripts/puzzles/projection_model.gd")
const View=preload("res://campuses/future_learning_center/scripts/puzzles/projection_view.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func advance(m)->void:
	for i:int in 12:m.step(.1)
func shoot(m)->void:m.start();advance(m)
func _initialize()->void:
	var m=Model.new();var base:Array=[];var advanced:Array=[];var front_count:=0;var collisions:=0
	for a:int in 4:
		for b:int in 4:
			for h:int in 2:
				for k:int in 2:
					m.place(0,a,h);m.place(1,b,k);m.set_extension(false)
					if not m.legal():collisions+=1
					if m.matches(0):front_count+=1
					if m.matches(0) and m.matches(1):base.append([a,b,h,k])
					m.set_extension(true)
					if m.matches(0) and m.matches(1):advanced.append([a,b,h,k])
	check(collisions==0,"all 64 supported configurations have no volume overlap")
	check(front_count==16,"16 base front candidates")
	check(base==[[0,2,0,0],[2,0,0,0]],"two base solutions accepted")
	check(advanced==[[0,2,1,0]],"masked raised target enumerates one visible-constraint solution")
	m=Model.new();check(m.matches(0) and not m.matches(1) and m.legal(),"same depth is legal counterexample")
	check(not m.place(0,4,0) and not m.place(1,0,2) and not m.place(-1,0,0),"invalid supports rejected")
	m.place(1,2,0);shoot(m);check(not m.completed,"one view insufficient")
	var rev:int=m.geometry_revision;m.rotate_fixture();check(m.geometry_revision==rev and m.receipts.has(0),"rotation preserves geometry evidence")
	check(not m.start(),"cannot expose unsettled fixture")
	advance(m);shoot(m);check(m.completed and m.current_passed(),"same geometry verified twice")
	m.place(0,1,0);check(m.receipts.is_empty() and not m.current_passed() and m.completed,"edit clears current proof not achievement")
	m.undo();check(m.depths==[0,2] and m.receipts.is_empty(),"undo does not resurrect receipts")
	m.start();m.step(.2);m.pause();var elapsed:float=m.elapsed;m.step(20);check(m.elapsed==elapsed,"paused exposure frozen")
	m.resume();advance(m);check(m.receipts.has(1),"resume exposure")
	m.rotate_fixture();m.pause();var angle:float=m.angle;m.step(10);check(m.angle==angle,"paused rotation frozen")
	m.resume();advance(m);m.start();m.place(0,3,0);advance(m);check(m.receipts.is_empty(),"in flight edit cannot certify stale geometry")
	m.set_extension(true);check(m.receipts.is_empty(),"new target invalidates old observations")
	m.place(0,0,1);m.place(1,2,0);shoot(m);m.rotate_fixture();advance(m);shoot(m);check(m.extension_completed,"masked target completed with actual geometry")
	var v=View.new();v.press_at(v.slot_point(0,0));v.release_at(Vector2(940,530));check(v.model.depths[0]==0,"invalid drop preserves support")
	v.press_at(v.slot_point(0,0));v.cancel_pointer();v.release_at(v.slot_point(0,2));check(v.model.depths[0]==0,"cancel rejects late release")
	v.press_at(v.slot_point(0,0));v.move_at(v.slot_point(0,2));v.release_at(v.slot_point(0,2));check(v.model.depths[0]==2,"drag slides same piece")
	var height_start:=v.height_point(0);v.press_at(height_start);v.move_at(height_start-Vector2(0,48));v.release_at(height_start-Vector2(0,48));check(v.model.heights[0]==1,"physical lift changes height")
	v.model.rotate_fixture();v._notification(View.NOTIFICATION_APPLICATION_FOCUS_OUT);angle=v.model.angle;v.model.step(5);check(v.model.angle==angle,"focus loss stops moving fixture")
	v.close();v.model.step(5);check(v.model.angle==angle,"closed fixture stays frozen")
	v.show();var event:=InputEventMouseButton.new();event.device=InputEvent.DEVICE_ID_EMULATION;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=true;event.position=v.height_point(0);v._gui_input(event);check(v.model.heights[0]==1,"emulated mouse does not duplicate touch")
	v.model.view_side=0
	v.press_at(v.mask_position());v.release_at(Vector2(687,171));check(v.model.extension,"physical strip dragged onto target card")
	v.press_at(v.mask_position());v.cancel_pointer();v.release_at(Vector2(827,482));check(v.model.extension,"canceled strip removal preserves attachment")
	v.press_at(v.mask_position());v.release_at(Vector2(940,530));check(v.model.extension,"invalid strip drop preserves attachment")
	v.press_at(v.mask_position());v.release_at(Vector2(827,482));check(not v.model.extension,"physical strip returned to tray")
	v.model.place(0,3,0)
	v.model.start();v.touch_id=7
	var canceled:=InputEventScreenTouch.new();canceled.index=7;canceled.pressed=false;canceled.canceled=true;v._gui_input(canceled)
	advance(v.model);check(not v.model.running and v.model.receipts.is_empty(),"canceled touch aborts exposure without evidence")
	owner_cancel(v,"_gui_input")
	var transaction=View.new();var start:=transaction.slot_point(0,0);transaction.press_at(start);transaction.move_at(start+Vector2(32.5,0))
	check(is_equal_approx(transaction.model.preview_depth,.5) and transaction.model.depths[0]==0 and transaction.model.history.is_empty(),"intermediate continuous supported preview without commit or undo")
	check(transaction.model.displayed_voxels(0)[0].y==.5,"rendered voxels follow transaction")
	transaction.cancel_pointer();check(transaction.model.displayed_pose(0)==Vector2.ZERO,"cancel restores original visible pose")
	transaction.press_at(start);transaction.move_at(start+Vector2(65,0));transaction.release_at(start+Vector2(130,0));check(transaction.model.depths[0]==0,"far release cannot teleport")
	transaction.press_at(start);transaction.move_at(start+Vector2(65,0));transaction.release_at(start+Vector2(65,0));check(transaction.model.depths[0]==1 and transaction.model.history.size()==1,"release commits once")
	transaction.model.angle=0;transaction.model.view_side=0
	var body:=transaction.project_point(Vector3(0.5,1.1,1.5));transaction.press_at(body);transaction.move_at(body+Vector2(0,9));check(is_equal_approx(transaction.model.preview_depth,1.5),"body drag uses vertical depth axis at front")
	transaction._notification(View.NOTIFICATION_APPLICATION_FOCUS_OUT);check(transaction.model.displayed_pose(0)==Vector2(1,0),"focus loss rolls back physical pose")
	transaction.free()
	v.free();print("projection: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)

func owner_cancel(view:Control,method:String)->void:
	if not view.is_inside_tree():root.add_child(view)
	view.show()
	var contact:=InputEventScreenTouch.new();contact.index=8;contact.position=Vector2(700,75);contact.pressed=true
	view.call(method,contact);contact.canceled=true;view.call(method,contact)
	check(view.touch_id==-1,"pressed cancellation releases owner")
	view.call(method,contact);check(view.touch_id==-1,"orphan canceled press cannot reacquire")
	contact.canceled=false;contact.index=9;view.call(method,contact)
	check(view.touch_id==9,"next finger can acquire after cancellation")
	var foreign:=InputEventScreenTouch.new();foreign.index=10;foreign.pressed=true;foreign.canceled=true;view.call(method,foreign)
	check(view.touch_id==9,"non-owner cancellation cannot steal capture")
	contact.pressed=false;contact.canceled=true;view.call(method,contact)
