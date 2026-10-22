extends SceneTree
var checks:=0
var failures:=0
var subject:Control
var fixture:Dictionary
var toggles:Array=[]
var locks:=0
var closes:=0
func check(ok:bool,why:String):
 checks+=1
 if not ok:failures+=1;push_error(why)
func _initialize():run.call_deferred()
func key(code:int)->InputEventKey:
 var k:=InputEventKey.new();k.keycode=code;k.pressed=true;return k
func run():
 var script=load("res://scripts/ui/chapter4_power_panel.gd")
 if script==null:quit(1);return
 var content:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/source/chapter4-755.content.json"))
 fixture={"native":{"scene":"duan_yongping_temporal_maze","c4_context":"power"},"chapter4":{"floor":"A1","mode":"light","phase":"blackout_light_grid","lightGrid":{"mask":6,"locked":false}}}
 subject=script.new();check(subject.configure(fixture,content.lightGrid,load("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf"),func():return fixture),"Original earned power context accepted")
 subject.toggle_requested.connect(func(id:String):toggles.append(id))
 subject.lock_requested.connect(func():locks+=1)
 subject.close_requested.connect(func():closes+=1)
 root.add_child(subject);await process_frame;await process_frame
 for dimensions:Vector2i in [Vector2i(1180,812),Vector2i(390,844),Vector2i(430,860),Vector2i(844,390)]:
  root.size=dimensions;subject.layout_panel(Vector2(dimensions));await process_frame;await process_frame
  check(subject.frame.position.x>=0 and subject.frame.position.y>=0,"Panel inside "+str(dimensions))
  check(subject.frame.size.x<=dimensions.x and subject.frame.size.y<=dimensions.y,"Bounded panel size "+str(dimensions))
  check(subject.fixture.visible==(dimensions.x>720),"Original responsive cabinet visibility "+str(dimensions))
  for b:Button in subject.buttons:
   check(b.size.y>=44 and b.size.x>=100,"Usable fivezone button "+str(dimensions))
   check(Rect2(Vector2.ZERO,subject.graph.size).encloses(b.get_rect()),"Complete zone bounds "+b.name+str(dimensions))
   var lines:=b.text.split("\n")
   for line:String in lines:check(subject.font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,15).x+12<=b.size.x,"Full source label fits "+line+str(dimensions))
 check(subject.status_label.text=="按下一区，会切换它自身和连线直接相接的区域。","Original coupling explanation restored")
 check(subject.buttons[0].text.contains("大厅") and subject.buttons[0].text.ends_with("暗"),"Hall off from real mask")
 var before:=JSON.stringify(fixture)
 subject.toggle(0);check(toggles==["hall"] and subject.pending,"One intent sent; synchronous pending")
 subject.toggle(0);check(toggles.size()==1,"Repeated press cannot duplicate pending intent")
 check(JSON.stringify(fixture)==before,"Presentation never mutates source mask")
 subject.resolve(fixture,{"message":"测试拒绝"});check(not subject.pending and subject.status_label.text=="测试拒绝","Rejection remains visible")
 subject.buttons[0].grab_focus();subject.handle_key(key(KEY_LEFT));check(subject.selected==1,"Source nearest left focus is west")
 subject.handle_key(key(KEY_DOWN));check(subject.selected==2,"Source nearest down focus is bakery")
 subject.handle_key(key(KEY_RIGHT));check(subject.selected==3,"Source nearest right focus is classroom")
 subject.handle_key(key(KEY_UP));check(subject.selected==4,"Source nearest up focus is east")
 subject.handle_key(key(KEY_SPACE));check(toggles[-1]=="east_corridor","Space submits focused zone")
 subject.resolve(fixture,{})
 fixture.chapter4.lightGrid.mask=int(content.lightGrid.allOnMask);subject.sync_authority(fixture)
 check(subject.status_label.text.begins_with("总负载过高"),"Source overload warning")
 fixture.chapter4.lightGrid.mask=int(content.lightGrid.targetMask);subject.sync_authority(fixture);await process_frame
 check(locks==1 and subject.pending,"Original matching state requests lock once")
 subject.resolve(fixture,{"message":"原证据仍需补全"});await process_frame
 check(locks==1 and subject.retry.visible,"Rejected lock has explicit retry without automatic loop")
 subject.request_lock();check(locks==2,"Explicit retry sends exactly one new request")
 subject.resolve(fixture,{})
 subject.handle_key(key(KEY_ESCAPE));check(closes==1,"Escape closes original panel")
 subject.dispose_session();await process_frame
 subject.toggle(0);subject.request_lock();check(locks==2 and toggles.size()==2,"Disposed owner cannot submit")
 fixture.chapter4.floor="A2";check(not subject.sync_authority(fixture),"Floor/context retirement")
 subject.queue_free();await process_frame
 print("CHAPTER4_POWER_PANEL ",checks," checks; ",failures," failures");quit(1 if failures else 0)
