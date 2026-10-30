extends SceneTree
const Model=preload("res://campuses/future_learning_center/scripts/puzzles/perspective_model.gd")
const View=preload("res://campuses/future_learning_center/scripts/puzzles/perspective_view.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func advance(m)->void:
	for i:int in 10:m.step(.1)
func shoot(m,view:int)->void:m.observe(view);m.start();advance(m)
func arrange(m,ids:Array)->void:
	for i:int in 4:m.place(ids[i],i)
func _initialize()->void:
	var m=Model.new();var north:=0;var south:=0;var both:Array=[];var three:Array=[]
	for a:int in 4:
		for b:int in 4:
			for c:int in 4:
				for d:int in 4:
					if a==b or a==c or a==d or b==c or b==d or c==d:continue
					var ids:=[a,b,c,d];arrange(m,ids)
					if m.matches(0):north+=1
					if m.matches(1):south+=1
					if m.matches(0) and m.matches(1):
						both.append(ids)
						if m.matches(2):three.append(ids)
	check(north==2 and south==2,"each local photo allows two layouts")
	check(both==[[0,1,2,3]] and three==both,"enumerated 24 layouts; one joint solution, third independently consistent")
	check(Model.rotated_slot(0,2)==3 and Model.rotated_slot(1,2)==2,"opposite side swaps rows AND columns")
	check(Model.rotated_slot(0,1)==1 and Model.rotated_slot(2,1)==0,"short side rotates 90 degrees")
	m=Model.new();check(m.matches(0) and not m.matches(1),"entry layout only matches north")
	var original:Array=m.slots.duplicate();var rev:int=m.revision;m.observe(1);m.rotate_paper(1)
	check(m.slots==original and m.revision==rev,"observer and paper never move world pieces")
	check(m.observed(1)==[3,1,2,0],"actual initial south view is true 180 rotation")
	shoot(m,0);shoot(m,0);check(not m.completed and m.receipts.size()==1,"duplicate photo not second evidence")
	arrange(m,[0,1,2,3]);check(m.receipts.is_empty(),"editing invalidates earlier photo")
	shoot(m,0);shoot(m,1);check(m.completed and m.current_passed(),"same layout two real photos complete")
	check(not m.observe(2),"third viewpoint only available with record")
	m.set_extension(true);check(not m.extension_completed,"opening record is not verification")
	shoot(m,2);check(m.extension_completed and m.current_passed(true),"third viewpoint separately verified")
	m.place(0,1);check(m.completed and not m.current_passed(),"achievement monotonic, current proof invalid")
	m.undo();check(m.slots==[0,1,2,3] and m.receipts.is_empty(),"undo cannot revive stale evidence")
	m.start();m.step(.2);m.pause();var elapsed:float=m.elapsed;m.step(10);check(m.elapsed==elapsed and m.receipts.is_empty(),"pause freezes exposure")
	m.resume();advance(m);check(m.receipts.has(2),"resume completes correct exposure")
	m.start();m.place(0,1);advance(m);check(m.receipts.is_empty(),"mid exposure edit cannot certify old layout")
	check(not m.place(-1,0) and not m.place(0,4) and not m.observe(4),"invalid inputs rejected")
	var v=View.new();v.press_at(View.CELLS[1]);v.release_at(View.CELLS[2]);check(v.model.slots==[0,1,2,3],"physical model drag swaps slots")
	v.press_at(View.CELLS[0]);v.cancel_pointer();v.release_at(View.CELLS[1]);check(v.model.slots==[0,1,2,3],"canceled drag has no late swap")
	v.press_at(View.PHOTOS[0]);v.release_at(View.PHOTOS[0]+Vector2(50,20));check(v.model.paper_turns[0]==1 and v.model.slots==[0,1,2,3],"paper turns, geometry stays fixed")
	v.press_at(View.FEET[1]);check(v.model.observer==1,"physical footprint changes observer")
	v.model.start();v._notification(View.NOTIFICATION_APPLICATION_FOCUS_OUT);advance(v.model);check(v.model.receipts.is_empty(),"focus loss cannot fabricate photo")
	v.close();advance(v.model);check(not v.model.running and v.model.receipts.is_empty(),"close cancels trial")
	v.show();var event:=InputEventMouseButton.new();event.device=InputEvent.DEVICE_ID_EMULATION;event.pressed=true;event.button_index=MOUSE_BUTTON_LEFT;event.position=View.FEET[0];v._gui_input(event);check(v.model.observer==1,"synthetic mouse ignored")
	v.model.place(0,1)
	v.model.start();v.touch_id=7
	var canceled:=InputEventScreenTouch.new();canceled.index=7;canceled.pressed=false;canceled.canceled=true;v._gui_input(canceled)
	advance(v.model);check(not v.model.running and v.model.receipts.is_empty(),"canceled touch aborts exposure without evidence")
	owner_cancel(v,"_gui_input")
	v.free();print("perspective: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)

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
