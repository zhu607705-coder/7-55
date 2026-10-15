extends SceneTree
## Root-pointer fixtures. Actual CUA and physical touch remain separate evidence.
var state: Node
var shell: Control
var checks:=0
var failures:=0
var messages: Array=[]
var actions: Array=[]
func _initialize() -> void: run.call_deferred()
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1;push_error("WORLD ITEM COMBINATION: "+label)
func frames(n: int=3) -> void:
	for i in n: await process_frame
func event(e: InputEvent) -> void: Input.parse_input_event(e);Input.flush_buffered_events()
func mouse(p: Vector2,down: bool) -> void:
	var e:=InputEventMouseButton.new();e.position=p;e.global_position=p;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=down;event(e)
func motion(p: Vector2,delta: Vector2=Vector2.ZERO,mask: int=0) -> void:
	var e:=InputEventMouseMotion.new();e.position=p;e.global_position=p;e.relative=delta;e.button_mask=mask;event(e)
func slot(id: String) -> Control: return shell.inventory_buttons.get_node_or_null("WorldItem_"+id)
func reset(dim: Vector2i,ids: Array) -> void:
	if is_instance_valid(shell):await shell.shutdown();shell.free();await frames()
	state.d=state.initial();var s: Dictionary=state.d
	s.native.chapter=3;s.native.scene="qizhen_lake";s.native.page="c3_lake";s.native.mode="light";s.runtimeMode="rpg";s.rpgScene="qizhen_lake"
	s.qizhenLake.merge({"active":true,"phase":"tool_chain","zone":"channel","vehicle":"kayak","boardingTutorialCompleted":true,"rainSafetyCleared":true,"kayakEquipped":true,"leftPaddleEquipped":true,"rightPaddleEquipped":true},true)
	for id: String in s.items:s.items[id]=false
	for id: String in ids:s.items[id]=true
	root.size=dim;shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames()
	shell._show_world_mobile();shell.compact_inventory_open=true;shell._layout();await frames();shell.world.set_process(false)
	messages.clear();actions.clear()
func begin(id: String) -> Vector2:
	var p: Vector2=slot(id).get_global_rect().get_center();motion(p);mouse(p,true);motion(p-Vector2(0,18),Vector2(0,-18),MOUSE_BUTTON_MASK_LEFT);await frames()
	check(root.gui_is_dragging(),"visible source starts one native drag")
	return p-Vector2(0,18)
func release_to(id: String,from: Vector2) -> void:
	var end: Vector2=slot(id).get_global_rect().get_center()
	for i in range(1,5):motion(from.lerp(end,i/4.0),(end-from)/4,MOUSE_BUTTON_MASK_LEFT);await process_frame
	mouse(end,false);await frames();check(not root.gui_is_dragging(),"drop releases native pointer")
func run() -> void:
	if not OS.get_user_data_dir().begins_with("/tmp/"):quit(2);return
	state=root.get_node("State");state.developer_mode=true
	state.feedback.connect(func(text):messages.append(text));state.action_completed.connect(func(id,_a,_b,_c):actions.append(id))
	for dim: Vector2i in [Vector2i(390,844),Vector2i(430,860),Vector2i(1180,812)]:
		await reset(dim,["nylonCord","brokenNetFrame"])
		var before: String=JSON.stringify(state.d.items)
		await release_to("brokenNetFrame",await begin("nylonCord"))
		check(messages.count("四件材料尚未集齐。")==1,"world pair reaches the existing four-part recipe once "+str(dim))
		check(JSON.stringify(state.d.items)==before and not state.d.qizhenLake.netCombined,"incomplete pair retains original recipe and all items")
		check(not messages.has("没有落在可使用的物品上，道具仍在物品栏。"),"recognized item is not misreported as an empty drop")
		mouse(slot("brokenNetFrame").get_global_rect().get_center(),false);await frames()
		check(messages.count("四件材料尚未集齐。")==1,"duplicate mouse release cannot combine twice")
		await reset(dim,["decoyPaper","fishingRod"])
		await release_to("fishingRod",await begin("decoyPaper"))
		check(state.d.qizhenLake.decoyBaitAttached and not state.d.items.decoyPaper and state.d.items.fishingRod,"accepting original controller consumes only the bait")
		check(actions.count("c3_bait")==1,"accepted recipe dispatches once")
		mouse(slot("fishingRod").get_global_rect().get_center(),false);await frames()
		check(actions.count("c3_bait")==1,"repeat release after consuming the source stays neutral")
		await reset(dim,["decoyPaper","fishingRod"])
		var from: Vector2=await begin("decoyPaper")
		var esc:=InputEventKey.new();esc.keycode=KEY_ESCAPE;esc.pressed=true;event(esc);await frames();mouse(slot("fishingRod").get_global_rect().get_center(),false);await frames()
		check(state.d.items.decoyPaper and not state.d.qizhenLake.decoyBaitAttached,"Escape cancels without a late recipe")
		await reset(dim,["decoyPaper","fishingRod"]);from=await begin("decoyPaper")
		shell._show_phone_surface();await frames();mouse(Vector2(100,100),false);await frames()
		check(state.d.items.decoyPaper and not state.d.qizhenLake.decoyBaitAttached and not root.gui_is_dragging(),"surface switch cancels owned drop")
		await reset(dim,["decoyPaper","fishingRod"]);from=await begin("decoyPaper")
		shell._show_world_journal();await frames();mouse(Vector2(100,100),false);await frames()
		check(state.d.items.decoyPaper and not state.d.qizhenLake.decoyBaitAttached,"Tasks blocks background combination")
	await reset(Vector2i(430,860),["decoyPaper","fishingRod"])
	var target: Control=slot("fishingRod")
	var data: Dictionary={"kind":"inventory_item","item":"decoyPaper"}
	check(target._can_drop_data(target.size/2,data),"owned visible pair accepts the real drop data")
	check(not target._can_drop_data(Vector2(-1,20),data),"outside painted target is not accepted")
	check(not target._can_drop_data(target.size/2,{"kind":"inventory_item","item":"fishingRod"}),"self-drop is not a recipe")
	check(not target._can_drop_data(target.size/2,{"kind":"inventory_item","item":"swanMagnet"}),"unowned source cannot dispatch")
	check(not target._can_drop_data(target.size/2,{"kind":"other","item":"decoyPaper"}),"unrelated payload is refused")
	target.disabled=true;check(not target._can_drop_data(target.size/2,data),"disabled target refuses drop")
	target.disabled=false
	var from: Vector2=await begin("decoyPaper")
	slot("decoyPaper").notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT);await frames();mouse(target.get_global_rect().get_center(),false);await frames()
	check(state.d.items.decoyPaper and not state.d.qizhenLake.decoyBaitAttached,"focus loss cancels without late consumption")
	await reset(Vector2i(430,860),["decoyPaper","fishingRod"]);from=await begin("decoyPaper")
	root.size=Vector2i(390,844);shell.size=Vector2(390,844);shell._layout();await frames();mouse(slot("fishingRod").get_global_rect().get_center(),false);await frames()
	check(state.d.items.decoyPaper and not state.d.qizhenLake.decoyBaitAttached,"resize cancels the outgoing geometry's drag")
	await reset(Vector2i(390,844),["decoyPaper","fishingRod"])
	var start: Vector2=slot("decoyPaper").get_global_rect().get_center()
	var end: Vector2=slot("fishingRod").get_global_rect().get_center()
	var touch:=InputEventScreenTouch.new();touch.index=7;touch.position=start;touch.pressed=true;event(touch)
	var finger:=InputEventScreenDrag.new();finger.index=7;finger.position=start-Vector2(0,18);finger.relative=Vector2(0,-18);event(finger);await frames()
	check(root.gui_is_dragging(),"existing touch arbitration starts one native item drag")
	finger=InputEventScreenDrag.new();finger.index=7;finger.position=end;finger.relative=end-start;event(finger);await frames()
	touch=InputEventScreenTouch.new();touch.index=7;touch.position=end;touch.pressed=false;event(touch);await frames(5)
	check(state.d.qizhenLake.decoyBaitAttached and actions.count("c3_bait")==1,"touch release reaches the same authoritative recipe once")
	var emulated:=InputEventMouseButton.new();emulated.device=-1;emulated.position=end;emulated.global_position=end;emulated.button_index=MOUSE_BUTTON_LEFT;emulated.pressed=false;event(emulated);await frames()
	check(actions.count("c3_bait")==1 and not root.gui_is_dragging(),"emulated follow-up release cannot duplicate consumption")
	await shell.shutdown();shell.free();await frames()
	print("WORLD_INVENTORY_COMBINATIONS: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
