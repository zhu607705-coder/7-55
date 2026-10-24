extends SceneTree
const Pages=preload("res://scripts/ui/chapter3_phone_pages.gd")
const Motion=preload("res://scripts/ui/c3_evidence_motion.gd")
const Session=preload("res://scripts/media/c3_voice_session.gd")
var checks:int=0
var failures:int=0
var shell: Control
func frames(count:int=6):
 for i in count:await process_frame
func physical_rect(control:Control)->Rect2:
 var transform:=control.get_global_transform_with_canvas()
 return Rect2(transform.origin,control.size*transform.get_scale())
func mount(page:Control)->void:
 # Inject only the measured audio capability, not an alternative layout.
 # The real Main phone/container still owns physical scale and clipping.
 for child in shell.page_body.get_children():
  shell.page_body.remove_child(child);child.queue_free()
 shell.page_body.add_child(page);shell._layout()
 await frames()
func archived(page:Control)->Array:
 return descendants(page).filter(func(n):return n is Label and n.text.ends_with(" · 已归档")).map(func(n):return n.text)
func source_buttons(page:Control)->Array:
 return descendants(page).filter(func(n):return n is Button and str(n.name).begins_with("C35Source_"))
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
 s.native.chapter=3;s.native.scene="";s.runtimeMode="phone"
 s.native.page="c35_voice";s.native.c35_listened=["lake","stone","lobby","broadcast","decoy_canteen","decoy_theater","decoy_library"];s.native.c35_voice_selection=["lake"]
 var session=Session.new("lake","",5200);session.phase="playing";session.position_ms=2000
 var source_before:String=JSON.stringify(s);var snapshot_before:Dictionary=session.snapshot()
 var pages=Pages.new()
 var state:Node=root.get_node("State");state.developer_mode=true;state.d=s.duplicate(true)
 shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames()
 shell.set_process(false);shell.world.set_process(false);shell.mobile_world=false;shell._refresh();await frames()
 for dimensions:Vector2i in [Vector2i(390,844),Vector2i(430,860),Vector2i(1440,900)]:
  root.size=dimensions;shell.size=Vector2(dimensions)
  var page=pages.build("c35_voice",{"media_session":session},s);await mount(page)
  var nodes:Array=descendants(page);var waves:Array=nodes.filter(func(n):return n.name=="SourceWaveform")
  check(waves.size()==7,"seven original waveform rows at"+str(dimensions))
  for wave in waves:check(wave.bins.size()==32,"source bins retained")
  var panels:Array=nodes.filter(func(n):return n.has_meta("recording_id")and n.get_meta("recording_id")=="lake")
  check(panels.size()==1,"one source clip row")
  if panels.size()!=1:continue
  var progress_nodes:Array=panels[0].get_children().filter(func(n):return n.get_script()!=null and str(n.get_script().resource_path).ends_with("c3_voice_progress.gd"))
  check(progress_nodes.size()==1,"one measured progress owner for source clip")
  if progress_nodes.size()!=1:continue
  var progress=progress_nodes[0]
  progress.refresh();check(is_equal_approx(progress.band.position_ratio,2000.0/5200),"playhead uses measured position")
  session.phase="paused";var position=session.position_ms
  for i:int in range(6):progress._process(.5)
  check(session.position_ms==position and progress.band.phase=="paused","pause does not synthesize progress")
  check(JSON.stringify(s)==source_before,"presentation does not write evidence")
  check(shell.phone.size==Vector2(430,860) and page.size==Vector2(424,814),"real Main retains canonical logical dimensions at every physical viewport")
  check(physical_rect(shell.phone_content).grow(.5).encloses(physical_rect(page)),"voice app fits scaled phone content")
  for panel in panels:
   page.scroll.ensure_control_visible(progress.get_parent());await frames()
   check(physical_rect(page.scroll).grow(.5).encloses(physical_rect(progress)),"measured waveform can be revealed inside actual phone scroll: "+str(dimensions)+" scroll "+str(physical_rect(page.scroll))+" waveform "+str(physical_rect(progress)))
  for node in nodes:
   if node is Button and "\n" in node.text:
    var face:Font=node.get_theme_font("font");var pixels:int=node.get_theme_font_size("font_size")
    var ink_width:float=face.get_string_size(node.text.split("\n")[0],HORIZONTAL_ALIGNMENT_LEFT,-1,pixels).x
    var style:StyleBox=node.get_theme_stylebox("normal")
    check(ink_width<=node.size.x-style.get_content_margin(SIDE_LEFT)-style.get_content_margin(SIDE_RIGHT)+.1,"full excerpt label fits without trimming")
    check(node.custom_minimum_size.y>=54 and node.text_overrun_behavior==TextServer.OVERRUN_NO_TRIMMING,"excerpt keeps two visible lines and touch height")
  session.phase="playing"
 check(session.snapshot()==snapshot_before,"renderer leaves transient capability unchanged")
 # The rebuilt recovery page presents source rows, not the retired ring.
 # Readiness must be derived only from authoritative evidence and stay stable
 # across reentry, hidden state, and reduced-motion presentation.
 var first=pages.build("c35_recovery",{},s);await mount(first)
 check(source_buttons(first).size()==4,"all four recovery sources remain available")
 check(archived(first).is_empty(),"initial recovered state has no invented archived source")
 check(JSON.stringify(s)==source_before,"initial source presentation does not write evidence")
 s.chapterThreeInterlude.photoSequenceSolved=true
 var earned_before:String=JSON.stringify(s)
 var second=pages.build("c35_recovery",{},s);await mount(second)
 check(archived(second)==["照片 · 已归档"],"only actual photo readiness marks its source archived")
 check(source_buttons(second).size()==4,"archiving never removes the other source controls")
 second.hide();await frames();second.show();await frames()
 check(archived(second)==["照片 · 已归档"] and JSON.stringify(s)==earned_before,"hide/show neither replays progression nor creates evidence")
 s.native.settings.reduced_motion=true
 var reduced=pages.build("c35_recovery",{},s);await mount(reduced)
 check(archived(reduced)==["照片 · 已归档"],"reduced motion keeps exact earned source feedback")
 check(reduced.modulate.a==1,"reduced motion keeps final page immediately visible")
 s.native.settings.reduced_motion=false
 var revisited=pages.build("c35_recovery",{},s);await mount(revisited)
 check(archived(revisited)==["照片 · 已归档"],"same readiness reentry has no duplicate or invented archived sources")
 check(revisited.modulate.a==1,"same-page rebuild does not restart entry fade")
 check(JSON.stringify(s)==earned_before,"reentry never writes source evidence")
 await shell.shutdown();shell.queue_free();await frames()
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
