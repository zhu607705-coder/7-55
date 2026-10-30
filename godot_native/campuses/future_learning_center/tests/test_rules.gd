extends SceneTree
const Model=preload("res://campuses/future_learning_center/scripts/puzzles/rules_model.gd")
const View=preload("res://campuses/future_learning_center/scripts/puzzles/rules_view.gd")
var checks:=0
var failures:=0
func check(value:bool,label:String)->void:
	checks+=1
	if not value:failures+=1;printerr("RULES_FAIL: "+label)
func trial(m:RefCounted,station:int,a:int,b:int)->void:
	m.place(a,station*2);m.place(b,station*2+1);m.start(station);m.step(2)
func _initialize()->void:
	for rule:int in 2:
		var m=Model.new();m.true_rule=rule
		check(not m.place(6,0) and not m.place(0,4),"invalid tile/slot rejected")
		trial(m,1,0,1 if rule==0 else 2)
		check(not m.completed,"transfer before contrast cannot complete")
		trial(m,0,0,1)
		check(m.informative,"opposed predictions observed even if rejected")
		trial(m,1,0,1)
		check(not m.completed and m.outcome=="repeated","reusing same pair cannot pass transfer")
		trial(m,1,2,3 if rule==0 else 4)
		check(m.completed,"new rule-matching pair completes")
		m.place(2,-1);check(m.completed,"achievement survives reversible rearrangement")
	var m=Model.new();m.place(0,0);m.place(2,1);m.start(0);m.step(.3);m.pause();m.step(10)
	check(m.evidence.is_empty() and is_equal_approx(m.elapsed,.3),"focus pause cannot create evidence")
	m.resume();m.step(1);check(m.informative,"resumed actual trial records contrast")
	m.start(1);m.place(4,2);m.step(10);check(not m.running and m.evidence.size()==1,"edit invalidates in-flight trial")
	m.place(0,2);check(m.slots[0]==-1 and m.slots[2]==0,"one physical tile cannot duplicate")
	var view=View.new();var at:Vector2=view.tile_position(0)
	view.press_at(at);view.release_at(Vector2(5,5));check(view.model.slots==[-1,-1,-1,-1],"bad drop preserves layout")
	view.press_at(at);view.cancel_pointer();view.release_at(view.SLOTS[0]);check(view.model.slots[0]==-1,"cancelled drag ignores later release")
	view.press_at(at);view.release_at(view.SLOTS[0]);check(view.model.slots[0]==0,"drag places actual tile")
	view.model.start(0);view.close();view.model.step(10);check(view.model.evidence.is_empty(),"close cancels hidden experiment")
	view.free()
	print("FLC_RULES: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
