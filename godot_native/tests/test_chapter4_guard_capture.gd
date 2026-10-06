extends SceneTree
const Capture=preload("res://scripts/presentation/chapter4_guard_capture.gd")
const Metrics=preload("res://scripts/player_metrics.gd")
var checks:=0
var failures:=0
func _initialize():run.call_deferred()
func check(ok:bool,why:String):
 checks+=1
 if not ok:failures+=1;push_error(why)
func context(action:String)->Dictionary:
 return {"scene":"duan_yongping_temporal_maze","floor":"A1","phase":"maintenance_repair"if action=="c4_recover_patrol"else"final_chase","time":"2245_maintenance"if action=="c4_recover_patrol"else"0754_blackout","mode":"light","guardMode":"patrol"if action=="c4_recover_patrol"else"chase","attempt":3}
func frames(n:=3):
 for i in n:await process_frame
func run():
 for action:String in ["c4_recover_patrol","c4_fail_chase"]:
  var c:=Capture.new();var ctx:=context(action);var value:Dictionary={"expectedAttempt":3,"failureFloor":"A1"}if action=="c4_fail_chase"else{}
  check(c.begin(ctx,action,value),"Original caller starts "+action)
  check(not c.begin(ctx,action,value),"Duplicate capture rejected")
  check(c.advance(5199,ctx).is_empty(),"No resume at5199ms")
  var result:Dictionary=c.advance(1,ctx)
  check(result.get("action","")==action and result.value==value and not c.active,"One exact5200ms owned resume")
  check(c.advance(6000,ctx).is_empty(),"No second resume")
  c.begin(ctx,action,value);c.advance(1200,ctx)
  check(c.advance(9999,ctx,false).is_empty() and c.elapsed_ms==1200,"Suspended scene does not spend caption time")
  check(c.advance(-100,ctx).is_empty()and c.elapsed_ms==1200,"Negative time rejected")
  check(c.advance(INF,ctx).is_empty()and c.elapsed_ms==1200,"Nonfinite time rejected")
  c.cancel();check(c.advance(9999,ctx).is_empty()and not c.active,"Cancel never resumes")
  for field:String in ["scene","floor","phase","time","mode","guardMode","attempt"]:
   c.begin(ctx,action,value);c.advance(4800,ctx);var changed:Dictionary=ctx.duplicate();changed[field]=99 if field=="attempt"else"changed"
   check(c.advance(1000,changed).is_empty()and not c.active,"Context change cancels "+field)
  c.begin(ctx,action,value);var original:Dictionary=ctx.duplicate();ctx.attempt=4
  check(c.matches(original) and not c.matches(ctx),"Context is retained by value")
  c.cancel();ctx=original
  c.begin(ctx,action,value);check(not c.advance(6000,ctx).is_empty(),"One long scene frame still settles once")
 var state:Node=root.get_node("State");state.developer_mode=true
 for checkpoint:String in ["c4-755-maintenance-2245","c4-755-chase"]:
  state.begin_checkpoint(checkpoint)
  var world:Control=load("res://scripts/world.gd").new();world.size=Vector2(960,540);root.add_child(world);world.set_process(false);await frames()
  var chapter:Dictionary=state.d.chapter4
  var patrol:bool=chapter.guardMode=="patrol"
  world.guard_kind=str(chapter.guardMode)+str(chapter.floor)+str(chapter.chaseAttempt)
  world.guard_position=Metrics.foot_rect(world.player).get_center()
  world.guard_state=world.guard_model.maintenance_state(0x7552245,false)if patrol else world.guard_model.chase_state(int(chapter.chaseAttempt))
  if not patrol:world.guard_state.phase="running";world.guard_state.elapsedMs=4000;world.guard_state.stableCommittedFrames=4
  var before:Dictionary=state.d.duplicate(true);var player:Vector2=world.player;var guard:Vector2=world.guard_position
  world._update_guard(0)
  check(world.guard_capture.active and world.guard_visible,"Actual native contact caller starts visible hold "+checkpoint)
  check(state.d.chapter4==before.chapter4,"Contact no longer commits immediate recovery")
  check(world._scene_presentation_blocks() and world._interaction_presentation_blocks(),"One owner blocks world input")
  check(world._hud_line()=="保安："+Capture.LINE,"Exact original caught caption")
  check(world._get_drag_data(Vector2(100,100))==null,"Drag cannot escape capture ownership")
  world._try_interact({"action":"c4_power"})
  check(state.d.chapter4==before.chapter4,"Interaction cannot submit during capture")
  world.transition_alpha=.5;world._process(.1)
  check(world.transition_alpha<.5,"Capture freezes physics but not the existing scene fade")
  world._process(5.099)
  check(world.guard_capture.active and world.player==player and world.guard_position==guard,"5199ms freeze preserves physical positions")
  check(state.d.chapter4==before.chapter4,"No early controller side effect")
  world._process(.001)
  check(not world.guard_capture.active,"Source scene-time hold completes at5200ms")
  if patrol:check(world.player==Vector2(836,716)and state.d.chapter4.chaseAttempt==before.chapter4.chaseAttempt,"Original patrol recovery remains authoritative")
  else:check(state.d.chapter4.chaseAttempt==before.chapter4.chaseAttempt+1,"Original chase controller increments once")
  var after:Dictionary=state.d.chapter4.duplicate(true);world._tick_guard_capture(9999);check(state.d.chapter4==after,"Settled callback cannot run twice")
  # Closing/replacing a world during another hold must not create any retry.
  world._begin_guard_capture("c4_recover_patrol"if patrol else"c4_fail_chase",{}if patrol else{"expectedAttempt":state.d.chapter4.chaseAttempt,"failureFloor":state.d.chapter4.floor})
  var owner:RefCounted=world.guard_capture;var saved:Dictionary=state.d.chapter4.duplicate(true)
  root.remove_child(world);world.free();check(not owner.active and owner.advance(9999,{}).is_empty(),"World disposal cancels old clock")
  check(state.d.chapter4==saved,"Disposal cannot retry or relocate")
  await frames()
 print("CHAPTER4_GUARD_CAPTURE ",checks," checks; ",failures," failures");quit(1 if failures else 0)
