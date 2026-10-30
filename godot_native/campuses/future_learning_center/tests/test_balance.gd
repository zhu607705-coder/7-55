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
	v.press_at(v.handle_position());v.release_at(View.DESTINATION);advance(v.model);check(v.model.delivered,"dragging whole tray to actual tea table delivers")
	v.model.start_lift();v._notification(View.NOTIFICATION_APPLICATION_FOCUS_OUT);v.model.step(20);check(v.model.paused and not v.model.held,"focus loss freezes pending lift")
	v.close();advance(v.model);check(not v.model.held and not v.model.running,"close cancels work without automatic completion")
	v.show();var event:=InputEventMouseButton.new();event.device=InputEvent.DEVICE_ID_EMULATION;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=true;event.position=v.handle_position();v._gui_input(event);check(not v.model.running,"emulated mouse filtered")
	v.free();print("balance: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
