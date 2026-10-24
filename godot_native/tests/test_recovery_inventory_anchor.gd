extends SceneTree
const Chrome=preload("res://scripts/ui/phone_chrome.gd")
var checks:int=0
var failed:int=0
func _initialize():run.call_deferred()
func check(value:bool,label:String):
 checks+=1
 if not value:failed+=1;push_error(label)
func settle():
 for i in range(4):await process_frame
func semantic_controls(node:Node)->Array:
 var out:Array=[]
 if (node is Label and not node.text.is_empty()) or node is Button:out.append(node)
 for child in node.get_children():out.append_array(semantic_controls(child))
 return out
func physical_rect(control:Control)->Rect2:
 var transform:=control.get_global_transform_with_canvas()
 return Rect2(transform.origin,control.size*transform.get_scale())
func visible_rect(control:Control)->Rect2:
 var bounds:=physical_rect(control);var owner:=control.get_parent()
 while owner!=null:
  if owner is Control and owner.clip_contents:bounds=bounds.intersection(physical_rect(owner))
  owner=owner.get_parent()
 return bounds
func main_reading_clearance(source:Dictionary)->void:
 var state:Node=root.get_node("State");state.d=source.duplicate(true)
 var shell:Control=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await settle()
 shell.set_process(false);shell.world.set_process(false)
 for dims:Vector2i in [Vector2i(390,844),Vector2i(430,860),Vector2i(1180,812),Vector2i(844,390)]:
  root.size=dims;shell.size=Vector2(dims)
  for page:String in ["c35_voice","c35_recovery","c35_photos","photos","c35_journal","c35_official","c35_messages","c35_network","c3_lake"]:
   state.d=source.duplicate(true);state.d.native.chapter=3;state.d.native.scene="";state.d.runtimeMode="phone"
   state.d.native.page=page;state.d.chapterThreeInterlude.evidenceIds=["journal_start"]
   state.d.ui.inventoryOpen=false;shell.mobile_world=false;shell._refresh();await settle()
   var facts:String=JSON.stringify({"recovery":state.d.chapterThreeInterlude,"items":state.d.items,"lake":state.d.qizhenLake})
   var controls:=semantic_controls(shell.page_body)
   check(not controls.is_empty(),"actual Main mounts semantic reading content: "+page)
   var scrolls:Array=[shell.phone_scroll]
   scrolls.append_array(shell.page_body.find_children("*","ScrollContainer",true,false))
   for fraction:float in [0.0,.5,1.0]:
    for scroll:ScrollContainer in scrolls:
     var bar:=scroll.get_v_scroll_bar();scroll.scroll_vertical=roundi((bar.max_value-bar.page)*fraction)
    await settle()
    var handle:Rect2=physical_rect(shell.phone_chrome.inventory_handle)
    var style:StyleBoxFlat=shell.phone_chrome.inventory_handle.get_theme_stylebox("normal")
    var scale:float=shell.phone_chrome.inventory_handle.get_global_transform_with_canvas().get_scale().x
    var shadow:=handle.grow(style.shadow_size*scale);shadow.position+=style.shadow_offset*scale
    var occupied:=handle.merge(shadow).merge(physical_rect(shell.phone_chrome.inventory_count))
    for control:Control in controls:
     if not control.is_visible_in_tree():continue
     var bounds:=visible_rect(control)
     if not bounds.has_area():continue
     var full:=physical_rect(control);var viewport:=physical_rect(shell.phone_scroll)
     check(full.position.x>=viewport.position.x-.5 and full.end.x<=viewport.end.x+.5,"reading content remains horizontally inside real phone: "+str(dims)+" "+page+" "+control.text)
     check(not occupied.intersects(bounds),"real reading text/action clears collapsed bag paint/count: "+str(dims)+" "+page+" "+str(fraction)+" "+control.text)
   check(JSON.stringify({"recovery":state.d.chapterThreeInterlude,"items":state.d.items,"lake":state.d.qizhenLake})==facts,"reading/scrolling never changes earned state: "+page)
 await shell.shutdown();shell.queue_free();await settle()
func run():
 var state=root.get_node("State");state.developer_mode=true
 var source:Dictionary=state.initial()
 source.chapterThreeInterlude.recoveryOpened=true
 source.qizhenLake.phase="complete"
 for id:String in ["campusCard","canteenRealBun","canteenCluelessSoyMilk","canteenEdgeEgg","canteenUselessCongee","temporaryTheaterTicket"]:source.items[id]=true
 # Optional local replay seed is read-only; CI uses the explicit fixture above.
 if not OS.get_environment("BAG_EARNED_SAVE").is_empty():source=JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("BAG_EARNED_SAVE"))).state
 for dims:Vector2i in [Vector2i(390,844),Vector2i(430,860),Vector2i(1180,812),Vector2i(844,390)]:
  root.size=dims
  for page:String in ["c35_voice","c35_recovery","c35_photos","photos","c35_journal","c35_official","c35_messages","c35_network","c3_lake"]:
   var s:Dictionary=source.duplicate(true);s.native.page=page;s.ui.inventoryOpen=false
   if page=="c3_lake":s.chapterThreeInterlude.completed=true
   var before:String=JSON.stringify(s)
   var phone:Control=Control.new();phone.size=Vector2(430,860);var factor:float=minf(1,minf((dims.x-36)/430.0,(dims.y-36)/860.0));phone.scale=Vector2.ONE*factor;phone.position=(Vector2(dims)-phone.size*factor)/2;root.add_child(phone)
   var chrome=Chrome.new();phone.add_child(chrome);chrome.refresh(s);await settle()
   var handle:Rect2=chrome.inventory_handle.get_global_rect();var scroll:Rect2=Rect2(phone.position+Vector2(3,43)*factor,Vector2(424,811)*factor)
   check(handle.size.x>=27.99 and handle.size.y>=43.99,"approved28x44 physical target "+str(dims))
   check(Rect2(Vector2.ZERO,Vector2(dims)).encloses(handle),"handle inviewport "+str(dims))
   check(chrome.inventory.position.y>=0 and chrome.inventory.position.x<=0,"collapsed handle remains on authored draggable left rail "+str(dims))
   check(not handle.intersects(chrome.task_button.get_global_rect()),"handle doesnot cover Tasks")
   check(not handle.intersects(chrome.time_box.get_global_rect()),"clock remains readable")
   check(not handle.intersects(chrome.status_right.get_global_rect()),"network andbattery remain visible")
   check(Rect2(Vector2.ZERO,Vector2(dims)).encloses(chrome.inventory_count.get_global_rect()),"attached count remains inside viewport")
   check(chrome.inventory_count.position==Vector2(chrome.inventory_handle.size.x-chrome.inventory_count.size.x+8,-8),"count retains authored top-right attachment")
   var face:Rect2=chrome.inventory_handle.get_meta("painted_rect")
   var face_global:Rect2=Rect2(handle.position+face.position*factor,face.size*factor)
   check(handle.encloses(face_global),"painted face stays inside transparent target")
   if chrome.inventory.position.y<0 and chrome.inventory.position.x>0:
    check(face_global.position.y>=phone.position.y and face_global.end.y<=scroll.position.y,"portrait painted face stays in top chrome")
   var same_rect:Rect2=handle
   for i in range(5):chrome._layout_inventory_anchor()
   check(chrome.inventory_handle.get_global_rect()==same_rect,"stable anchor")
   var style:StyleBoxFlat=chrome.inventory_handle.get_theme_stylebox("normal")
   var margins:Array=[style.expand_margin_left,style.expand_margin_top,style.expand_margin_right,style.expand_margin_bottom]
   chrome._refresh_inventory();await settle();style=chrome.inventory_handle.get_theme_stylebox("normal")
   check(margins==[style.expand_margin_left,style.expand_margin_top,style.expand_margin_right,style.expand_margin_bottom],"refresh never accumulates painted offsets")
   check(JSON.stringify(s)==before,"presentation preserves earned state")
   s.ui.inventoryOpen=true;chrome.refresh(s);await settle()
   check(chrome.inventory.position==Vector2(0,chrome.inventory_top),"expanded drawer authored anchor")
   check(chrome.inventory_handle.position==Vector2(74,0) and chrome.inventory_handle.size==Vector2(40,63),"expanded handle geometry unchanged")
   check(chrome.inventory_body.size.x==74 and chrome.inventory_scroll.size.x==62,"expanded item/drop geometry unchanged")
   var slot=chrome.inventory_slots.get_child(0);var point:Vector2=slot.get_global_rect().get_center()
   var down:InputEventMouseButton=InputEventMouseButton.new();down.button_index=MOUSE_BUTTON_LEFT;down.position=point;down.global_position=point;down.pressed=true;Input.parse_input_event(down);await process_frame
   for step in range(1,6):
    var move:InputEventMouseMotion=InputEventMouseMotion.new();move.position=point+Vector2(16*step,0);move.global_position=move.position;move.relative=Vector2(16,0);move.button_mask=MOUSE_BUTTON_MASK_LEFT;Input.parse_input_event(move);await process_frame
   check(root.gui_is_dragging(),"real native drag starts before relocation")
   phone.position.x+=1;await settle()
   check(not root.gui_is_dragging() and not slot._drag_was_started,"anchor movement cancels native drag")
   down.pressed=false;Input.parse_input_event(down);await settle()
   phone.position.x-=1;await settle()
   var touch:InputEventScreenTouch=InputEventScreenTouch.new();touch.index=0;touch.position=slot.get_global_rect().get_center();touch.pressed=true;Input.parse_input_event(touch);await process_frame
   check(slot._touch_index==0,"touch owns slot before page transition")
   s.native.page="cc98";chrome.refresh(s);await settle()
   check(slot._touch_index==-1 and slot.Gesture.touch_owner()==null,"leaving reading page releases touch owner")
   touch.pressed=false;Input.parse_input_event(touch);await settle()
   s.native.page=page;chrome.refresh(s);await settle()
   var lower:float=chrome.inventory_top+20;chrome.set_inventory_top(lower)
   check(chrome.inventory.position.y==lower,"expanded drawer still moves")
   s.ui.inventoryOpen=false;chrome.refresh(s);await settle()
   check(chrome.inventory_handle.get_global_rect().size.is_equal_approx(handle.size),"close restores same collapsed target size")
   check(chrome.inventory.position.x<=0 and chrome.inventory.position.y==lower,"close retains left rail and deliberate vertical position")
   s.native.page="cc98";chrome.refresh(s);await settle()
   check(chrome.inventory.position.x==0 and chrome.inventory_handle.size==Vector2(maxf(38,28.0/factor),maxf(63,44.0/factor)),"other pages retain source rail")
   phone.queue_free();await process_frame
 var route=Chrome.new();root.add_child(route)
 for completed:bool in [false,true]:
  for lake_phase:String in ["locked","complete"]:
   var s:Dictionary=source.duplicate(true)
   s.chapterThreeInterlude.completed=completed;s.qizhenLake.phase=lake_phase
   for page:String in ["photos","c35_photos","c35_journal","c35_official","c35_messages","c35_network","cc98","phone_home","c3_ticket_post","c3_lake"]:
    s.native.page=page;route.refresh(s);await settle()
    var expected:bool=page=="c3_lake" or (not completed and (page in ["c35_photos","c35_journal","c35_official","c35_messages","c35_network"] or (page=="photos" and lake_phase=="complete")))
    check(route._reading_inventory_anchor()==expected,"reading-page guard: "+page+" / "+lake_phase+" / "+str(completed))
 route.queue_free();await process_frame
 await main_reading_clearance(source)
 print("READING_BAG_ANCHOR ",checks," checks; ",failed," failures")
 quit(1 if failed else 0)
