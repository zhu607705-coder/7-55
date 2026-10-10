extends SceneTree
const Chapter=preload("res://scripts/chapters/chapter4.gd")
var checks:=0
var failures:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func run()->void:
	var state:=root.get_node("State");state.begin_checkpoint("c4-755-checkin")
	var original:Dictionary=state.d.duplicate(true);var chapter:=Chapter.new()
	for flags in 16:
		var s:=original.duplicate(true);var c:Dictionary=s.chapter4
		c.checkinCardAccepted=bool(flags&1);c.checkinPaperAccepted=bool(flags&2)
		c.factIds.erase("checkin_card_accepted");c.factIds.erase("checkin_paper_accepted")
		if flags&4:c.factIds.append("checkin_card_accepted")
		if flags&8:c.factIds.append("checkin_paper_accepted")
		var card:bool=c.checkinCardAccepted and c.factIds.has("checkin_card_accepted")
		var paper:bool=c.checkinPaperAccepted and c.factIds.has("checkin_paper_accepted")
		var expected: String="submit_attendance_paper" if card and not paper else ("read_campus_card" if paper and not card else "complete_checkin")
		var before:=JSON.stringify(s)
		check(chapter.objective(s)==str(chapter.content.tasks[expected].label),"Source partial check-in conjunction "+str(flags))
		check(JSON.stringify(s)==before,"Guidance grants no flag/item for "+str(flags))
	state.begin_checkpoint("c4-755-closure")
	for saved in [false,true]:
		var s:Dictionary=state.d.duplicate(true);s.chapter4.factIds.erase("zhu_two_questions_answered")
		if saved:s.chapter4.factIds.append("zhu_two_questions_answered")
		var before:=JSON.stringify(s)
		check(chapter.objective(s)==str(chapter.content.tasks["acknowledge_exterior_closure" if saved else "answer_zhu_two_questions"].label),"Original answered/unanswered closure task "+str(saved))
		check(JSON.stringify(s)==before,"Closure guidance is read-only")
		var result:=chapter.dispatch(s,"c4_closure_done",{"acknowledged":true,"playbackMs":5800})
		check(not s.chapter4.completed,"Task text cannot bypass issued session and answers")
	print("CHAPTER4_CLOSURE_GUIDANCE ",checks," checks; ",failures," failures");quit(1 if failures else 0)
