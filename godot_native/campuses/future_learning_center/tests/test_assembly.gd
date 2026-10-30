extends SceneTree
const Model=preload("res://campuses/future_learning_center/scripts/puzzles/assembly_model.gd")
const View=preload("res://campuses/future_learning_center/scripts/puzzles/assembly_view.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;printerr("ASSEMBLY: "+label)
func trial(m,kind:String)->void:
	m.start(kind)
	for i:int in 35:m.step(.1)
func photos(m)->void:
	m.set_condition(0);trial(m,"photo");m.set_condition(1);trial(m,"photo")
func _initialize()->void:run.call_deferred()
func run()->void:
	var m=Model.new();m.place(0,0);m.place(1,2);photos(m)
	check(m.receipts.photo_a.passed and m.receipts.photo_b.passed,"subsystem optics works independently")
	trial(m,"feed");check(not m.current_passed() and not m.receipts.feed.passed,"combined support obstructs moving carriage")
	m.set_bracket(0,false);trial(m,"feed");check(m.receipts.feed.passed,"removing support clears feed")
	photos(m);check(not m.receipts.photo_a.passed and not m.current_passed(),"removed attachment cannot retain optical success")
	m.set_bracket(65,true);photos(m);trial(m,"feed");check(m.current_passed(),"outside support resolves actual combined conflict")
	m.set_bracket(-65,true);check(not m.current_passed() and m.completed,"later revisions do not splice prior proofs or revoke completed fact")
	photos(m);trial(m,"feed");check(m.current_passed(),"opposite outside support is legal alternative")
	for x:float in [-33,-31,0,31,33]:
		m.set_bracket(x);check(m.feed_clear()==(absf(x)>=32),"full carriage width at support %s"%x)
	check(not m.set_bracket(INF) and not m.set_bracket(200),"nonfinite and offrail changes rejected")
	var view=View.new();check(view.model is Model,"assembly view shares optics with new model");view.free()
	print("FLC_ASSEMBLY: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
