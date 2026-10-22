extends ColorRect
## Original five-zone topology and cabinet. State/controller owns every mutation.
signal close_requested
signal toggle_requested(zone_id: String)
signal lock_requested
const Ui=preload("res://scripts/ui/native_ui_theme.gd")
const ORDER=["hall","west_corridor","bakery_back_area","classroom_zone","east_corridor"]
const POS={"hall":Vector2(.50,.13),"west_corridor":Vector2(.20,.41),"east_corridor":Vector2(.80,.41),"bakery_back_area":Vector2(.28,.84),"classroom_zone":Vector2(.72,.84)}
const CELLS={"hall":Vector2(2,1),"west_corridor":Vector2(1,2),"east_corridor":Vector2(3,2),"bakery_back_area":Vector2(1,3),"classroom_zone":Vector2(3,3)}
const ART=preload("res://assets/rpg/interiors/finale/chapter4-755/sprites/chapter4_power_panel_states_v01.png")
var frame:PanelContainer
var row:HBoxContainer
var fixture:Control
var graph:Control
var status_label:Label
var retry:Button
var close_button:Button
var buttons:Array[Button]=[]
var zones:Dictionary={}
var grid_data:Dictionary={}
var read_state:Callable
var font:Font
var mask:=0
var selected:=0
var pending:=false
var live:=true
var last_auto_mask:Variant=null
var feedback:=""
var layout_pending:=false
class Lines extends Control:
	var owner_panel:Control
	func _draw():
		for id:String in owner_panel.zones:
			var zone:Dictionary=owner_panel.zones[id]
			for adjacent:String in zone.adjacentZoneIds:
				if owner_panel.zones.has(adjacent) and int(zone.bit)<int(owner_panel.zones[adjacent].bit):
					draw_line(owner_panel.POS[id]*size,owner_panel.POS[adjacent]*size,Color("526c73"),4)
class Cabinet extends Control:
	var owner_panel:Control
	func _draw():
		var picture:=Rect2(Vector2.ZERO,Vector2(142,130))
		var cell:=Vector2(ART.get_size())/2
		# Source JSX keeps the unlit open frame and overlays live switch lamps.
		draw_texture_rect_region(ART,picture,Rect2(Vector2(cell.x,0),cell))
		for zone:Dictionary in owner_panel.grid_data.zones:
			var on:bool=(owner_panel.mask&(1<<int(zone.bit)))!=0
			var center:=Vector2(142*.602,130*(.327+int(zone.bit)*.1025))
			draw_rect(Rect2(center-Vector2(4,4),Vector2(8,8)),Color("fff4a3" if on else "20272a"))
			draw_rect(Rect2(center-Vector2(4,4),Vector2(8,8)),Color("ffc14f" if on else "11191c"),false,1)
func configure(state:Dictionary,contract:Dictionary,pixel_font:Font,reader:Callable)->bool:
	read_state=reader;grid_data=contract; font=pixel_font
	if not context_valid(state) or not contract.has("zones"):return false
	for zone:Dictionary in contract.zones:zones[str(zone.id)]=zone
	for id:String in ORDER:
		if not zones.has(id):return false
	mask=int(state.chapter4.lightGrid.mask)
	color=Color(.008,.028,.05,.78);mouse_filter=Control.MOUSE_FILTER_STOP;set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);theme=Ui.font_theme(font)
	frame=PanelContainer.new();frame.add_theme_stylebox_override("panel",Ui.box(Color("142327"),Color("6d8991"),3,3,Vector2(22,22)));add_child(frame)
	var scroll:=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;frame.add_child(scroll)
	row=HBoxContainer.new();row.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_theme_constant_override("separation",14);scroll.add_child(row)
	fixture=Cabinet.new();fixture.owner_panel=self;fixture.mouse_filter=Control.MOUSE_FILTER_IGNORE;fixture.custom_minimum_size=Vector2(142,130);fixture.size_flags_vertical=Control.SIZE_SHRINK_BEGIN;row.add_child(fixture)
	var body:=VBoxContainer.new();body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.add_theme_constant_override("separation",10);row.add_child(body)
	body.add_child(label("五区配电箱",14,Color("7fa9b1")))
	body.add_child(label("让必要路线亮起",23,Color("edf8f2")))
	graph=Lines.new();graph.owner_panel=self;graph.custom_minimum_size=Vector2(0,242);graph.mouse_filter=Control.MOUSE_FILTER_IGNORE;graph.resized.connect(layout_buttons);body.add_child(graph)
	for i:int in ORDER.size():
		var button:=Button.new();button.name="Zone_"+ORDER[i];button.add_theme_font_size_override("font_size",15);button.pressed.connect(toggle.bind(i));button.focus_entered.connect(func():selected=i);buttons.append(button);graph.add_child(button)
	status_label=label("",16,Color("d9e7e8"));status_label.custom_minimum_size.y=48;body.add_child(status_label)
	body.add_child(label("方向键移动焦点 · Enter / Space 切换 · Esc 关闭",14,Color("a6bbc0")))
	retry=Button.new();retry.text="重试锁定";style(retry,false);retry.custom_minimum_size.y=44;retry.pressed.connect(request_lock);body.add_child(retry)
	close_button=Button.new();close_button.text="关闭箱门";close_button.custom_minimum_size.y=44;style(close_button,false);close_button.pressed.connect(func():if can_close():close_requested.emit());body.add_child(close_button)
	refresh();return true
func label(text:String,points:int,ink:Color)->Label:
	var node:=Label.new();node.text=text;node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;node.add_theme_font_size_override("font_size",points);node.add_theme_color_override("font_color",ink);return node
func style(button:Button,on:bool):
	for key in Ui.button_styles(Color("23463e" if on else "121d21"),Color("efffe9" if on else "c4d3d5"),Color("8ccdb2" if on else "52676f"),2,2,Vector2(6,6)):
		button.add_theme_stylebox_override(key,Ui.button_styles(Color("23463e" if on else "121d21"),Color("efffe9" if on else "c4d3d5"),Color("8ccdb2" if on else "52676f"),2,2,Vector2(6,6))[key])
	button.add_theme_font_size_override("font_size",15)
	for key in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:button.add_theme_color_override(key,Color("efffe9" if on else "c4d3d5"))
func _ready():
	resized.connect(func():layout_panel(size));layout_panel(size);buttons[0].grab_focus.call_deferred();maybe_lock.call_deferred(mask)
func layout_panel(available:Vector2):
	if frame==null:return
	fixture.visible=available.x>720
	var width:=minf(600,available.x-28)
	frame.size=Vector2(width,minf(550,available.y-24));frame.position=(available-frame.size)/2
	layout_buttons.call_deferred()
func layout_buttons():
	if graph==null:return
	for i:int in buttons.size():
		var b:Button=buttons[i];b.size=Vector2(graph.size.x*.38,58);b.position=POS[ORDER[i]]*graph.size-b.size/2
	graph.queue_redraw()
func context_valid(state:Dictionary)->bool:
	var c:Dictionary=state.get("chapter4",{})
	return live and state.get("native",{}).get("scene","")=="duan_yongping_temporal_maze" and state.native.get("c4_context","")=="power" and c.get("floor","")=="A1" and c.get("mode","")=="light" and c.get("phase","")=="blackout_light_grid" and not c.get("lightGrid",{}).get("locked",false)
func sync_authority(state:Dictionary)->bool:
	if not context_valid(state):return false
	var next:int=int(state.chapter4.lightGrid.mask)
	if next!=mask:mask=next;feedback="";refresh()
	return true
func refresh():
	if buttons.is_empty():return
	for i:int in buttons.size():
		var z:Dictionary=zones[ORDER[i]];var on:bool=(mask&(1<<int(z.bit)))!=0
		buttons[i].text=("■ " if on else "□ ")+str(z.label)+"\n"+("亮" if on else "暗");buttons[i].disabled=pending;style(buttons[i],on)
	var solved:=mask==int(grid_data.targetMask)
	if not solved:last_auto_mask=null
	retry.visible=solved and not pending and last_auto_mask==mask
	retry.disabled=pending;close_button.disabled=pending
	status_label.text="总负载过高。核对已记录的必要路线，关闭旁路回路。" if mask==int(grid_data.allOnMask) else feedback if not feedback.is_empty() else "正在同步配电状态……" if pending else "按下一区，会切换它自身和连线直接相接的区域。"
	fixture.queue_redraw();graph.queue_redraw();maybe_lock.call_deferred(mask)
func toggle(index:int):
	if not live or pending or not read_state.is_valid() or not context_valid(read_state.call()):return
	selected=index;pending=true;feedback="";refresh();toggle_requested.emit(ORDER[index])
func resolve(state:Dictionary,result:Dictionary):
	if not live:return
	pending=false
	if not sync_authority(state):close_requested.emit();return
	feedback=str(result.get("message",""));refresh()
func maybe_lock(expected:int):
	if not live or not is_inside_tree() or pending or expected!=mask or mask!=int(grid_data.targetMask) or last_auto_mask==mask:return
	if not read_state.is_valid() or not context_valid(read_state.call()):return
	last_auto_mask=mask;request_lock()
func request_lock():
	if not live or pending:return
	if not read_state.is_valid() or not context_valid(read_state.call()):return
	pending=true;feedback="";refresh();lock_requested.emit()
func can_close()->bool:return live and not pending
func owns_feedback()->bool:return live and pending
func dispose_session():live=false
func handle_key(event:InputEventKey)->bool:
	if not live or not event.pressed or event.echo:return false
	if event.keycode==KEY_ESCAPE:
		if can_close():close_requested.emit()
		return true
	if pending:return event.keycode in [KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN,KEY_ENTER,KEY_KP_ENTER,KEY_SPACE]
	if event.keycode in [KEY_ENTER,KEY_KP_ENTER,KEY_SPACE]:
		if close_button.has_focus():close_requested.emit()
		elif retry.has_focus():request_lock()
		else:toggle(selected)
		return true
	if event.keycode not in [KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN]:return false
	var origin:Vector2=CELLS[ORDER[selected]];var nearest:=selected;var best:=INF
	for i:int in ORDER.size():
		var d:Vector2=CELLS[ORDER[i]]-origin
		var eligible:bool=(event.keycode==KEY_LEFT and d.x<0) or (event.keycode==KEY_RIGHT and d.x>0) or (event.keycode==KEY_UP and d.y<0) or (event.keycode==KEY_DOWN and d.y>0)
		if eligible and d.length_squared()<best:nearest=i;best=d.length_squared()
	selected=nearest;buttons[selected].grab_focus();return true
