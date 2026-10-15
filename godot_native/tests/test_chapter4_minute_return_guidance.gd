extends SceneTree
const Chapter=preload("res://scripts/chapters/chapter4.gd")
var count:=0
var failures:=0
func _initialize():run.call_deferred()
func check(ok:bool,label:String):
 count+=1
 if not ok:failures+=1;push_error(label)
func run():
 var state:Node=root.get_node("State");state.developer_mode=true;state.begin_checkpoint("c4-755-chase")
 var s:Dictionary=state.d.duplicate(true)
 s.chapter4.phase="return_to_clock";s.chapter4.floor="A2";s.chapter4.guardMode="absent";s.chapter4.mode="light"
 s.items.finalMinute=true;s.items.attendanceRecordPaper=true
 var chapter:RefCounted=Chapter.new()
 var before:=JSON.stringify(s)
 check(chapter.objective(s)==chapter.content.tasks.return_via_main_stair.label,"A2 keeps original return-via-stair objective")
 check(JSON.stringify(s)==before,"Reading A2 objective never mutates progression")
 var items:Dictionary=s.items.duplicate(true);var facts:Array=s.chapter4.factIds.duplicate()
 var result:Dictionary=chapter.dispatch(s,"c4_return_stair")
 check(result.get("handled",false) and s.chapter4.floor=="A1" and s.chapter4.phase=="return_to_clock","Original return action reaches A1 without phase skip")
 check(chapter.objective(s)==chapter.content.tasks.install_final_minute.label,"A1 selects original install-final-minute objective")
 check(s.items==items and s.chapter4.factIds==facts,"Guidance/return grants or consumes no items or facts")
 before=JSON.stringify(s);chapter.objective(s)
 check(JSON.stringify(s)==before,"Reading A1 objective never mutates progression")
 var targets:Array=chapter.targets("duan_yongping_temporal_maze",s)
 check(targets.any(func(t:Dictionary):return t.get("action","")=="c4_install_minute" and t.get("item","")=="finalMinute" and t.get("mode","")=="light"),"Original clock item and light-mode interaction remain authoritative")
 s.chapter4.completed=true
 check(chapter.objective(s)=="签到完成 · 7:55","Completed chapter keeps existing higher-priority objective")
 print("CHAPTER4_MINUTE_RETURN_GUIDANCE ",count," checks; ",failures," failures");quit(1 if failures else 0)
