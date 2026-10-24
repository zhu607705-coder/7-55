extends SceneTree
const Model=preload("res://scripts/presentation/liangzhu_performance_model.gd")
var checks:=0
var failures:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error("LIANGZHU_MODEL: "+label)
func run()->void:
	check(Model.LOGICAL_SIZE==Vector2i(240,135) and Model.RASTER_SIZE==Vector2i(1200,675) and Model.DURATION_MS==54000,"Fine raster preserves layout while the original three-scene timeline is54 seconds")
	var data:Dictionary=Model.content()
	check(data.durationMs==54000 and data.scenes.size()==3 and data.qtes.size()==3,"authored content and model agree on duration/scenes/interactive cues")
	var previous_end:=0.0
	var ids:Dictionary={}
	for cue:Dictionary in data.cues:
		check(float(cue.startMs)==previous_end and float(cue.endMs)>float(cue.startMs) and not ids.has(cue.id),"dialogue cues are unique and leave no stale-subtitle gap")
		previous_end=float(cue.endMs);ids[cue.id]=true
		var at:Dictionary=Model.pose_at(float(cue.startMs))
		check(at.cueId==cue.id and at.text==cue.text and at.speaker==cue.speaker and at.lineStartMs==cue.startMs,"actual subtitle reads its original source cue and speaker")
	check(previous_end==Model.DURATION_MS and not JSON.stringify(data).contains("小九妹"),"complete timeline uses original text only")
	for qte:Dictionary in data.qtes:check(Model.pose_at(qte.atMs).lineStartMs==qte.atMs,"QTE wait is authored on a voice boundary rather than cutting a future generated word")
	for pair:Array in [[0,0],[7999,0],[8000,1],[19999,1],[20000,2],[37999,2],[38000,3],[54000,3]]:
		check(Model.pose_at(pair[0]).beat==pair[1],"authored beat boundary "+str(pair[0]))
	check(Model.pose_at(0).actors[0].foot==Vector2(108,90) and Model.pose_at(0).actors[1].foot==Vector2(132,90),"same-source actors begin between the chair backs and shared desk")
	var study:Dictionary=Model.pose_at(6000)
	check(study.actors.all(func(a:Dictionary)->bool:return a.foot.y>88 and a.foot.y<96),"visible first-scene chests paint over chair backs while the desk still covers the lower body")
	check(Model.pose_at(8000).actors[0].foot==study.actors[0].foot and Model.pose_at(8000).actors[1].foot==study.actors[1].foot and Model.pose_at(0,true).actors[0].foot==study.actors[0].foot,"departing path and reduced opening preserve the same depth-calibrated foot placement")
	var chamber:Dictionary=Model.pose_at(29000)
	check(chamber.actors[0].foot==Vector2(108,106) and chamber.actors[1].foot==Vector2(132,90) and chamber.actors[1].foot.y>88 and chamber.actors[1].foot.y<96,"second-scene Yingtai paints in front of the chair back and behind the desk while Shanbo stays on its near side")
	check(Model.pose_at(29000,true).actors[1].foot==chamber.actors[1].foot and Model.pose_at(46000).actors[1].foot==Vector2(132,102),"reduced chamber uses the same physical ordering without moving the final-act fan target")
	check(Model.pose_at(20000).sceneId=="chamber-meeting" and Model.pose_at(38000).sceneId=="grave-butterflies" and Model.pose_at(38000).text.begins_with("后来"),"chamber and later grave are causally distinct scenes")
	check(Model.pose_at(20000).curtain==0 and Model.pose_at(38000).curtain==0,"scene relocation occurs behind the closed front cloth")
	check(Model.pose_at(40000).actors[0].alpha==0 and Model.pose_at(40000).stageProps.filter(func(p:Dictionary)->bool:return p.alpha>0).size()==1,"the deceased role is absent and the empty chair remains visible")
	check(Model.pose_at(15500).fans[0].attachment.kind=="handoff" and Model.pose_at(17000).fans[0].attachment.actor=="scholar","passive canonical handoff uses actual actor sockets")
	check(Model.pose_at(47000).fans.size()==2 and Model.pose_at(47000).fans.all(func(f:Dictionary)->bool:return f.attachment.actor=="yingtai"),"both final fans belong to the visible actor's two hands")
	check(Model.pose_at(48000).fans.all(func(f:Dictionary)->bool:return f.kind=="butterfly" and f.attachment.launchMs==48000),"butterflies carry the exact bone-sampled release frame")
	check(Model.pose_at(49000).fans[0].flap!=Model.pose_at(49180).fans[0].flap,"butterflies change wing frames")
	for ms:int in [0,8000,9500,11000,14000,15000,16200,19999,20000,29000,33500,37999,38000,42000,46000,48000,52000,54000]:
		var pose:Dictionary=Model.pose_at(ms)
		check(pose.actors.all(func(a:Dictionary)->bool:return Rect2(12,32,216,91).has_point(a.foot) and a.foot.is_equal_approx((a.foot*5).round()/5)),"complete actor cels remain within stage and fine grid at meaningful boundaries")
	for span:Array in [[100,7900],[8500,19500],[20500,37500],[38500,47999],[48000,53500]]:
		var first:Dictionary=Model.pose_at(span[0],true);var last:Dictionary=Model.pose_at(span[1],true)
		check(first.actors==last.actors and first.fans==last.fans and first.curtain==last.curtain,"reduced motion keeps each actionable/post-release tableau static while original text advances")
	for qte:Dictionary in data.qtes:
		var reduced_pose:Dictionary=Model.pose_at(qte.atMs,true)
		var target:Dictionary=qte.targetAttachment
		var actor:Dictionary=reduced_pose.actors.filter(func(a:Dictionary)->bool:return a.id==target.actor)[0]
		check(actor.alpha>0.0,"reduced-motion QTE target belongs to an actually visible actor: "+str(qte.id))
		if qte.entity=="fan":check(reduced_pose.fans.any(func(f:Dictionary)->bool:return f.kind=="fan" and f.attachment.kind=="socket" and f.attachment.actor==target.actor and f.attachment.socket==target.socket),"reduced-motion fan QTE targets a real held fan, never the empty post-release wrist")
		else:check(qte.direction=="left" and reduced_pose.actors==Model.pose_at(float(qte.atMs)+100,true).actors,"reduced turn keeps the visible actor and authored static-left cue without motion")
	check(Model.pose_at(48000,true).actors[1].alpha==0.0 and Model.pose_at(48000,true).fans.all(func(f:Dictionary)->bool:return f.kind=="butterfly" and f.attachment.kind=="fixed"),"only after the release beat does reduced motion switch to the static butterfly tableau")
	var model=Model.new(false,"passive");model.tick(.25);var before:Dictionary=model.snapshot();model.pause();model.tick(5)
	check(model.elapsed_ms==before.elapsedMs and model.runtime_ms==before.runtimeMs,"pause freezes both clocks")
	model.resume();model.tick(.1,false);var focus_at:float=model.elapsed_ms;model.tick(.1,true)
	check(model.focus_paused and model.elapsed_ms==focus_at,"focus return needs explicit resume")
	model.resume();model.tick(.1,true,true);check(model.elapsed_ms==focus_at,"host modal blocks playback")
	model.tick(NAN);model.tick(INF);model.tick(-1);check(model.elapsed_ms==focus_at,"invalid deltas cannot seek or finish")
	check(model.tick(54) and model.status=="complete" and model.elapsed_ms==54000 and not model.tick(.1),"real passive clock completes exactly once without fabricated QTE success")
	check(model.qte_completed.is_empty() and model.qte_results.is_empty(),"explicit passive mode never claims player QTE success")
	var sample=Model.new();var untouched:Dictionary=sample.snapshot();Model.pose_at(53000)
	check(sample.snapshot()==untouched and Model.pose_at(53000).samplingMode=="canonical-passive-presentation","offline sampling neither advances interactive clocks nor claims earned actions")
	var copy:Dictionary=Model.content();copy.cues[0].text="changed"
	check(Model.pose_at(0).text!="changed","returned content cannot mutate canonical dialogue")
	print("LIANGZHU_MODEL: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
