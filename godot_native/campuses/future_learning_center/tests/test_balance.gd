extends SceneTree
const Model=preload("res://campuses/future_learning_center/scripts/puzzles/balance_model.gd")
const View=preload("res://campuses/future_learning_center/scripts/puzzles/balance_view.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func advance(m)->void:
	for i:int in 16:m.step(.1)
func arrange(m,ids:Array)->void:
	for i:int in 4:m.place(ids[i],i)
func _initialize()->void:
	var base:=0;var extension:=0;var weights:Dictionary={};var m=Model.new()
	for a:int in 4:
		for b:int in 4:
			for c:int in 4:
				for d:int in 4:
					var ids:=[a,b,c,d]
					if a==b or a==c or a==d or b==c or b==d or c==d:continue
					arrange(m,ids);m.set_extension(false)
					if m.balanced():
						base+=1;weights[str([Model.WEIGHTS[a],Model.WEIGHTS[b],Model.WEIGHTS[c],Model.WEIGHTS[d]])]=true
					m.set_extension(true)
					if m.balanced():extension+=1
	check(base==8 and weights.size()==2,"two weight arrangements, all eight identity permutations")
	check(extension==4,"offset pivot has four identity solutions")
	m=Model.new();check(is_equal_approx(m.torque(),3),"actual initial torque")
	check(not m.start_delivery(),"cannot bypass physical lift")
	m.start_lift();m.step(.1);check(m.tilt>0 and m.elevation>0,"continuous tilt while lifting")
	advance(m);check(not m.held and not m.completed and m.slots==[0,1,2,3],"unbalanced lift stops without losing cups")
	arrange(m,[0,2,3,1]);check(m.balanced(),"balanced arrangement")
	m.start_lift();advance(m);check(m.held and not m.completed,"lift alone not completion")
	check(m.start_delivery(),"actual stable lift authorizes carry");m.step(.1);check(m.travel>0 and m.travel<1,"delivery moves continuously")
	m.pause();var travel:float=m.travel;m.step(20);check(m.travel==travel and not m.completed,"paused carry never completes")
	m.resume();advance(m);check(m.completed and m.delivered and m.travel==1,"four cups delivered")
	m.place(0,1);check(not m.delivered and m.completed and m.lift_revision==-1,"edit invalidates current receipt not achievement")
	m.undo();m.start_lift();advance(m);m.set_extension(true);check(not m.held and not m.start_delivery(),"pivot invalidates earlier lift")
	arrange(m,[0,2,1,3]);check(m.balanced(),"extension moment zero")
	m.start_lift();advance(m);m.start_delivery();advance(m);check(m.extension_completed,"extension physically delivered")
	m=Model.new();check(not m.place(4,0) and not m.place(0,4),"bad cup/slot rejected")
	arrange(m,[0,2,3,1]);m.start_lift();m.step(.2);m.cancel();advance(m);check(not m.held and not m.completed,"canceled lift cannot create receipt")
	m.start_lift();m.step(NAN);m.step(-1);check(m.elapsed==0,"invalid dt ignored")
	var v=View.new();v.press_at(v.cup_position(1));v.release_at(v.cup_position(3));check(v.model.slots==[0,3,2,1],"direct cup swap preserves identity")
	v.press_at(v.cup_position(0));v.cancel_pointer();v.release_at(v.cup_position(2));check(v.model.slots[0]==0,"canceled late drop ignored")
	v.press_at(v.cup_position(0));v.release_at(Vector2(950,530));check(v.model.slots[0]==0,"invalid drop keeps four cups")
	v.press_at(v.handle_position());advance(v.model);check(v.model.held,"physical handle lifts balanced tray")
	v.press_at(v.handle_position());var landing:=View.DESTINATION+Vector2(0,-83)*.65;v.move_at(landing);var before_release:=v.tray_center();v.release_at(landing);check(v.tray_center().distance_to(before_release)<.01,"release retains actual tray position, no source replay");advance(v.model);check(v.model.delivered,"dragging whole tray to actual tea table delivers")
	v.model.start_lift();v._notification(View.NOTIFICATION_APPLICATION_FOCUS_OUT);v.model.step(20);check(v.model.paused and not v.model.held,"focus loss freezes pending lift")
	v.close();advance(v.model);check(not v.model.held and not v.model.running,"close cancels work without automatic completion")
	v.show();var event:=InputEventMouseButton.new();event.device=InputEvent.DEVICE_ID_EMULATION;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=true;event.position=v.handle_position();v._gui_input(event);check(not v.model.running,"emulated mouse filtered")
	owner_cancel(v,"_gui_input")
	var transaction=View.new();arrange(transaction.model,[0,2,3,1]);transaction.model.start_lift();advance(transaction.model)
	var start:=transaction.tray_center();var hand:=transaction.handle_position();transaction.press_at(hand);transaction.move_at(hand+Vector2(200,0))
	check(transaction.tray_center().x>start.x+190 and transaction.handle_position().distance_to(hand+Vector2(200,0))<.02,"actual tray follows same grasp while perspective scale changes")
	check(not transaction.model.completed and transaction.model.held,"preview motion alone earns nothing")
	transaction.cancel_pointer();check(transaction.tray_center()==start and not transaction.model.completed,"cancel restores lifted grasp origin")
	transaction.press_at(hand);transaction.move_at(hand+Vector2(200,0));transaction.release_at(Vector2(750,254))
	check(transaction.tray_center()==start and not transaction.model.completed,"distant release cannot invent delivery")
	transaction.press_at(hand);transaction.move_at(Vector2(750,254.05));transaction._notification(View.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(transaction.tray_center()==start and not transaction.model.completed,"focus loss rolls back tray without completing")
	transaction.model.resume();transaction.press_at(hand);transaction.move_at(Vector2(750,254.05));transaction.release_at(Vector2(750,254.05))
	var settled_from:=transaction.tray_center();transaction.model.step(.09)
	check(transaction.tray_center().distance_to(settled_from)<1 and not transaction.model.completed,"settle stays at destination, completion waits for contact")
	transaction.model.step(.1);check(transaction.model.completed and transaction.tray_center()==View.DESTINATION,"settle finishes at actual destination")
	transaction.free()
	v.free();print("balance: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)

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
