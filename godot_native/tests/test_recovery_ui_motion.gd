extends SceneTree
const Pages=preload("res://scripts/ui/chapter3_phone_pages.gd")
const Motion=preload("res://scripts/ui/c3_evidence_motion.gd")
const Session=preload("res://scripts/media/c3_voice_session.gd")
var checks:int=0
var failures:int=0
func _initialize():run.call_deferred()
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures+=1;push_error(label)
func descendants(n:Node)->Array:
 var nodes:Array=[n]
 for child:Node in n.get_children():nodes.append_array(descendants(child))
 return nodes
func run():
 var s:Dictionary=root.get_node("State").initial()
 s.qizhenLake.phase="complete";s.chapterThreeInterlude.recoveryOpened=true;s.chapterThreeInterlude.evidenceIds=["journal_start"]
 s.native.page="c35_voice";s.native.c35_listened=["lake","stone","lobby","broadcast","decoy_canteen","decoy_theater","decoy_library"];s.native.c35_voice_selection=["lake"]
 var session=Session.new("lake","",5200);session.phase="playing";session.position_ms=2000
 var source_before:String=JSON.stringify(s);var snapshot_before:Dictionary=session.snapshot()
 var pages=Pages.new()
 for width:int in [340,378,424]:
  var page=pages.build("c35_voice",{"media_session":session},s);page.size=Vector2(width,2400);root.add_child(page)
  for i:int in range(5):await process_frame
  var nodes:Array=descendants(page);var waves:Array=nodes.filter(func(n):return n.name=="SourceWaveform")
  check(waves.size()==7,"seven original waveform rows at"+str(width))
  for wave in waves:check(wave.bins.size()==32,"source bins retained")
  var panels:Array=nodes.filter(func(n):return n.has_meta("recording_id")and n.get_meta("recording_id")=="lake")
  check(panels.size()==1,"one source clip row")
  var progress=panels[0].get_children().filter(func(n):return n.get_script()!=null and str(n.get_script().resource_path).ends_with("c3_voice_progress.gd"))[0]
  progress.refresh();check(is_equal_approx(progress.band.position_ratio,2000.0/5200),"playhead uses measured position")
  session.phase="paused";var position=session.position_ms
  for i:int in range(6):progress._process(.5)
  check(session.position_ms==position and progress.band.phase=="paused","pause does not synthesize progress")
  check(JSON.stringify(s)==source_before,"presentation does not write evidence")
  check(page.get_combined_minimum_size().x<=width+.01,"page minimum fits compact width")
  for node in nodes:
   if node is Button and "\n" in node.text:
    var face:Font=node.get_theme_font("font");var pixels:int=node.get_theme_font_size("font_size")
    var ink_width:float=face.get_string_size(node.text.split("\n")[0],HORIZONTAL_ALIGNMENT_LEFT,-1,pixels).x
    var style:StyleBox=node.get_theme_stylebox("normal")
    check(ink_width<=node.size.x-style.get_content_margin(SIDE_LEFT)-style.get_content_margin(SIDE_RIGHT)+.1,"full excerpt label fits without trimming")
    check(node.custom_minimum_size.y>=54 and node.text_overrun_behavior==TextServer.OVERRUN_NO_TRIMMING,"excerpt keeps two visible lines and touch height")
  page.queue_free();await process_frame;session.phase="playing"
 check(session.snapshot()==snapshot_before,"renderer leaves transient capability unchanged")
 var first=pages.build("c35_recovery",{},s);root.add_child(first);await process_frame
 var ring=descendants(first).filter(func(n):return n.get_script()!=null and str(n.get_script().resource_path).ends_with("c3_investigation_ring.gd"))[0]
 check(ring.arrivals.is_empty(),"initial recovered state has no fake arrival")
 first.queue_free();await process_frame
 s.chapterThreeInterlude.photoSequenceSolved=true
 var second=pages.build("c35_recovery",{},s);root.add_child(second);await process_frame
 ring=descendants(second).filter(func(n):return n.get_script()!=null and str(n.get_script().resource_path).ends_with("c3_investigation_ring.gd"))[0]
 check(ring.arrivals==["c35_photos"] and ring.completed==1,"only actual new readiness drives arrival")
 var before:float=ring.arrival_elapsed;ring.hide();ring._process(.2);check(ring.arrival_elapsed==before,"hidden arrival freezes")
 ring.show();ring.foreground=false;ring._process(.2);check(ring.arrival_elapsed==before,"unfocused arrival freezes")
 second.queue_free();await process_frame
 s.native.settings.reduced_motion=true
 var reduced=pages.build("c35_recovery",{},s);root.add_child(reduced);await process_frame
 ring=descendants(reduced).filter(func(n):return n.get_script()!=null and str(n.get_script().resource_path).ends_with("c3_investigation_ring.gd"))[0]
 check(ring.reduced_motion and ring.arrival_elapsed==0,"reduced motion suppresses decorative clock")
 check(reduced.modulate.a==1,"reduced motion keeps final page immediately visible")
 reduced.queue_free();await process_frame
 # Reentry/rebuild does not replay a consumed arrival or reveal new evidence.
 s.native.settings.reduced_motion=false
 var revisited=pages.build("c35_recovery",{},s);root.add_child(revisited);await process_frame
 ring=descendants(revisited).filter(func(n):return n.get_script()!=null and str(n.get_script().resource_path).ends_with("c3_investigation_ring.gd"))[0]
 check(ring.arrivals.is_empty(),"same readiness reentry has no duplicate arrival")
 check(revisited.modulate.a==1,"same-page rebuild does not restart entry fade")
 revisited.queue_free();await process_frame
 var counts:Dictionary={"pressed":0}
 for reduce:bool in [false,true]:
  var button:Button=Button.new();button.size=Vector2(140,54);root.add_child(button);Motion.press(button,reduce)
  button.pressed.connect(func():counts.pressed+=1)
  var rectangle:Rect2=button.get_rect()
  button.button_down.emit();check(button.self_modulate!=Color.WHITE,"press has immediate feedback")
  button.button_up.emit();button.button_down.emit()
  await create_timer(.14).timeout
  check(button.self_modulate!=Color.WHITE,"new held press cancels old release tween")
  button.hide();check(button.self_modulate==Color.WHITE,"hidden press cancels feedback immediately")
  button.show();button.button_down.emit();button.focus_exited.emit()
  check(button.self_modulate==Color.WHITE,"focus interruption releases feedback")
  button.button_down.emit();button.button_up.emit()
  if reduce:check(button.self_modulate==Color.WHITE,"reduced motion releases immediately")
  else:
   await create_timer(.14).timeout
   check(button.self_modulate==Color.WHITE,"normal release settles")
  check(button.get_rect()==rectangle,"feedback never changes hit rectangle")
  check(counts.pressed==0,"presentation never synthesizes an action")
  button.button_down.emit();button.button_up.emit();button.queue_free();await process_frame
 # Essential measured progress remains correct in reduced motion.
 var source:Dictionary={"targetDurationMs":5200,"soundEvents":[]}
 var wave=preload("res://scripts/ui/c3_voice_progress.gd").new()
 session.phase="playing";session.position_ms=2600
 wave.setup(session,source,{"waveform":Array([.1,.2,.3]),"durationMs":5200},true);root.add_child(wave);await process_frame
 check(wave.band.position_ratio==.5,"reduced motion still shows measured audio progress")
 var snapshot:Dictionary=session.snapshot();session.phase="paused";wave.refresh()
 for i:int in range(10):wave._process(.2)
 check(wave.position_ms==2600 and wave.band.phase=="paused","reduced motion paused clock stays fixed")
 wave.queue_free();await process_frame
 print("RECOVERY_UI_MOTION ",checks," checks; ",failures," failures")
 quit(1 if failures else 0)
