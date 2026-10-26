extends SceneTree
## Real Main controls: compact source threads and deliberate, non-authoritative navigation.
var shell: Control
var state: Node
var checks=0
var failures=0
var geometry:Array=[]
func _initialize()->void:run.call_deferred()
func frames(count:int=5)->void:
 for i in range(count):await process_frame
func check(ok:bool,message:String)->void:
 checks+=1
 if not ok:failures+=1;push_error("PHONE CLUES: "+message)
func node(id:String)->Control:return shell.page_body.find_child(id,true,false)
func rect(control:Control)->Rect2:
 var transform=control.get_global_transform_with_canvas()
 return Rect2(transform.origin,control.size*transform.get_scale())
func touch(control:Control)->void:
 var point=rect(control).get_center()
 for down:bool in [true,false]:
  var event=InputEventScreenTouch.new();event.index=3;event.position=point;event.pressed=down
  Input.parse_input_event(event);Input.flush_buffered_events();await frames(1)
 await frames()
func restore(checkpoint:String)->void:
 state.developer_mode=true;check(state.begin_checkpoint(checkpoint),"authored checkpoint "+checkpoint);state.developer_mode=false
 state.open_page("phone_home");shell._refresh();await frames()
 state.open_page("cc98");shell._refresh();await frames()
 shell.set_process(false);shell.world.set_process(false);shell.phone_scroll.scroll_vertical=0;await frames()
func capture(name:String)->void:
 var folder=OS.get_environment("PHONE_CLUE_CAPTURE_DIR")
 if folder.is_empty() or DisplayServer.get_name()=="headless":return
 DirAccess.make_dir_recursive_absolute(folder);await create_timer(1.4).timeout;await RenderingServer.frame_post_draw
 check(root.get_texture().get_image().save_png(folder.path_join(name+".png"))==OK,"capture "+name)
func run()->void:
 var source:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/source/chapter3-qizhen-lake.content.json"))
 var expected_replies:Array[String]=[]
 var source_replies:Array=source.locationSearch.cc98.replies
 check(source_replies.size()==3,"source witness retains all three authored replies")
 for i:int in range(source_replies.size()):
  var prefix:String="%d楼："%[3,8,14][i]
  check(str(source_replies[i]).begins_with(prefix),"source witness floor prefix retained "+str(i))
  expected_replies.append(str(source_replies[i]).trim_prefix(prefix))
 state=root.get_node("State");state.developer_mode=true;state.begin_checkpoint("c1-home")
 shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames()
 for dim:Vector2i in [Vector2i(390,844),Vector2i(360,640),Vector2i(430,932)]:
  root.size=dim;shell.size=Vector2(dim);await frames()
  await restore("c3-qizhen-location")
  await touch(node("Cc98WetProgramSearch"));check(node("OpenPost_qizhen-wet-paper-witness")!=null,"ordinary search exposes authored witness post")
  await touch(node("OpenPost_qizhen-wet-paper-witness"))
  check(node("Cc98ThreadBody")!=null,"ordinary touch opens source thread")
  if node("Cc98ThreadBody")==null:continue
  var before=JSON.stringify(state.d)
  check(not state.d.qizhenLake.bridgeClueFound and not state.d.items.bridgeKeyword,"opening and compacting do not grant keyword")
  check(node("Cc98ThreadBody").text=="如题。","original body preserved")
  check(node("Cc98ThreadBody").get_line_count()==node("Cc98ThreadBody").get_visible_line_count(),"body text is not clipped")
  check(node("Cc98ThreadPost").size.y<120,"one-line body no longer has fixed 120px empty floor")
  var replies_jump=node("Cc98ThreadRepliesJump")
  var scroll_rect=rect(shell.phone_scroll)
  check(scroll_rect.encloses(rect(replies_jump)),"non-spoiling replies navigation visible on first screen "+str(dim))
  check(rect(replies_jump).size.x>=28 and rect(replies_jump).size.y>=28,"visible navigation has real 28px target")
  var labels:Array=[]
  for i:int in range(3):
   var reply=node("Cc98ThreadReply_"+str(i));labels.append(reply)
   check(reply!=null and reply.get_line_count()==reply.get_visible_line_count(),"all authored witness reply lines fit "+str(i))
   if i>0:check(rect(labels[i-1]).end.y<rect(reply).position.y,"reply order and separation retained")
  check(rect(node("Cc98BridgeKeyword")).position.y>rect(labels.back()).end.y,"original keyword summary remains after all replies")
  check(node("Cc98ThreadBody").text=="如题。" and labels.map(func(label):return label.text)==expected_replies,"source body and complete reply sequence preserved")
  check(shell.page_body.find_children("Cc98ThreadReply_*","Label",true,false).size()==expected_replies.size(),"source replies render exactly once without duplicates")
  var rail_clear=true;var sampled_lines=0
  var chrome=shell.phone_chrome
  for fraction:float in [0.0,0.25,0.5,0.75,1.0]:
   shell.phone_scroll.scroll_vertical=roundi((shell.phone_scroll.get_v_scroll_bar().max_value-shell.phone_scroll.get_v_scroll_bar().page)*fraction);await frames(1)
   var shadow=rect(chrome.inventory_handle);shadow.position+=Vector2(3,3)*chrome.inventory_handle.get_global_transform_with_canvas().get_scale()
   for line:Label in shell.page_body.find_children("*","Label",true,false):
    if not rect(line).intersects(scroll_rect):continue
    sampled_lines+=1
    for rail:Rect2 in [rect(chrome.inventory_handle),rect(chrome.inventory_count),shadow]:
     if rect(line).intersects(rail):rail_clear=false
  check(sampled_lines>=20,"real source text sampled across scroll range")
  check(rail_clear,"collapsed inventory rail, badge and shadow never cover thread text")
  shell.phone_scroll.scroll_vertical=0;await frames()
  await capture("witness-first-"+str(dim.x))
  await touch(replies_jump)
  check(shell.phone_scroll.scroll_vertical>0,"real touch uses existing outer scroll owner")
  check(JSON.stringify(state.d)==before,"reply navigation has no domain write")
  var target=node("Cc98ThreadReplies")
  check(absf(rect(target).position.y-scroll_rect.position.y)<3 or shell.phone_scroll.scroll_vertical==int(shell.phone_scroll.get_v_scroll_bar().max_value-shell.phone_scroll.get_v_scroll_bar().page),"reply anchor is visible or reaches real scroll limit")
  shell.phone_scroll.ensure_control_visible(node("Cc98BridgeKeyword"));await frames()
  check(scroll_rect.grow(1).encloses(rect(node("Cc98BridgeKeyword"))),"original keyword control is fully reachable")
  await touch(node("Cc98BridgeKeyword"))
  check(state.d.qizhenLake.bridgeClueFound and state.d.items.bridgeKeyword,"only original explicit keyword intent grants source clue")
  geometry.append({"viewport":str(dim),"witnessBodyHeight":node("Cc98ThreadPost").size.y,"scrollRange":shell.phone_scroll.get_v_scroll_bar().max_value-shell.phone_scroll.get_v_scroll_bar().page})
  await restore("c2-cc98-upload")
  await touch(node("OpenPost_seat-022-backpack"))
  before=JSON.stringify(state.d)
  check(node("Cc98ReplyBody_24")==null,"unearned BD replies remain hidden")
  for id:String in ["Cc98RepliesJump","Cc98EvidenceJump"]:
   check(scroll_rect.grow(1).encloses(rect(node(id))),"investigation first screen exposes "+id)
  await capture("investigation-first-"+str(dim.x))
  await touch(node("Cc98RepliesJump"))
  check(shell.phone_scroll.scroll_vertical>0 and JSON.stringify(state.d)==before,"reading anchor changes scroll only")
  shell.phone_scroll.scroll_vertical=0;await frames();await touch(node("Cc98EvidenceJump"))
  check(JSON.stringify(state.d)==before,"original uploader anchor has no submission side effect")
  for evidence:String in ["archived_leave_rule","bag_non_person_proof","seat_022_receipt","library_presence_proof"]:
   check(rect(shell.phone_scroll).grow(1).encloses(rect(node("Cc98EvidenceSlot_"+evidence))),"original uploader anchor reveals source slot "+evidence)
  check(shell.page_body.find_children("*","ScrollContainer",true,false).is_empty(),"long source thread has one scroll owner")
 await shell.shutdown();shell.queue_free();await frames()
 print("Phone clue discoverability: ",checks," checks, ",failures," failures; geometry=",JSON.stringify(geometry));quit(1 if failures else 0)
