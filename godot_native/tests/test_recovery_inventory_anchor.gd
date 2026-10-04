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
func run():
 var state=root.get_node("State");state.developer_mode=true
 var source:Dictionary=state.initial()
 source.chapterThreeInterlude.recoveryOpened=true
 for id:String in ["campusCard","canteenRealBun","canteenCluelessSoyMilk","canteenEdgeEgg","canteenUselessCongee","temporaryTheaterTicket"]:source.items[id]=true
 # Optional local replay seed is read-only; CI uses the explicit fixture above.
 if not OS.get_environment("BAG_EARNED_SAVE").is_empty():source=JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("BAG_EARNED_SAVE"))).state
 for dims:Vector2i in [Vector2i(390,844),Vector2i(430,860),Vector2i(1180,812),Vector2i(844,390)]:
  root.size=dims
  for page:String in ["c35_voice","c35_recovery","c3_lake"]:
   var s:Dictionary=source.duplicate(true);s.native.page=page;s.ui.inventoryOpen=false
   if page=="c3_lake":s.chapterThreeInterlude.completed=true
   var before:String=JSON.stringify(s)
   var phone:Control=Control.new();phone.size=Vector2(430,860);var factor:float=minf(1,minf((dims.x-36)/430.0,(dims.y-36)/860.0));phone.scale=Vector2.ONE*factor;phone.position=(Vector2(dims)-phone.size*factor)/2;root.add_child(phone)
   var chrome=Chrome.new();phone.add_child(chrome);chrome.refresh(s);await settle()
   var handle:Rect2=chrome.inventory_handle.get_global_rect();var scroll:Rect2=Rect2(phone.position+Vector2(3,43)*factor,Vector2(424,811)*factor)
   check(handle.size.x>=43.99 and handle.size.y>=43.99,"physical44 target "+str(dims))
   check(Rect2(Vector2.ZERO,Vector2(dims)).encloses(handle),"handle inviewport "+str(dims))
   check(not handle.intersects(scroll),"collapsed handle clears reading surface "+str(dims))
   check(not handle.intersects(chrome.task_button.get_global_rect()),"handle doesnot cover Tasks")
   check(not handle.intersects(chrome.time_box.get_global_rect()),"clock remains readable")
   check(not handle.intersects(chrome.status_right.get_global_rect()),"network andbattery remain visible")
   check(handle.encloses(chrome.inventory_count.get_global_rect()),"count kept inside handle")
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
   check(not chrome.inventory_handle.get_global_rect().intersects(scroll),"close restores reading clearance")
   s.native.page="cc98";chrome.refresh(s);await settle()
   check(chrome.inventory.position.x==0 and chrome.inventory_handle.size==Vector2(38,63),"other pages retain source rail")
   phone.queue_free();await process_frame
 print("READING_BAG_ANCHOR ",checks," checks; ",failed," failures")
 quit(1 if failed else 0)
