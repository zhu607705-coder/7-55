extends SceneTree
## Original boundary behavior plus presentation clock; no earned-route claim.
var state: Node
var host: Control
var checks:=0
var failures:=0
var messages: Array=[]
func _initialize() -> void: run.call_deferred()
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("KAYAK BOUNDARY: "+label)
func run() -> void:
	state=root.get_node("State");state.developer_mode=true;state.d=state.initial()
	var s: Dictionary=state.d
	s.native.chapter=3;s.native.scene="qizhen_lake";s.native.page="c3_lake";s.native.mode="light";s.runtimeMode="rpg";s.rpgScene="qizhen_lake"
	s.qizhenLake.merge({"active":true,"phase":"tool_chain","zone":"open_water","vehicle":"kayak","boardingTutorialCompleted":true,"rainSafetyCleared":true,"kayakEquipped":true,"leftPaddleEquipped":true,"rightPaddleEquipped":true},true)
	host=load("res://scripts/world.gd").new();host.size=Vector2(960,540);root.add_child(host);host.set_process(false)
	state.feedback.connect(func(text):messages.append(text))
	var original: String=state.content("chapter3-qizhen-lake.content.json").boarding.boundaryBlocked
	# Exact left edge of the unchanged lily_piles rectangle and unchanged83px hull.
	host.player=Vector2(1020-83.0/2,600);host.kayak.position=host.player;host.kayak.heading=0;host.kayak.speed=80;host.kayak.remainder=0
	host.lake_session._previous=host.player;host.lake_session._motion_remainder=0
	check(host.can_stand(host.player),"source contact starts with a legal full hull")
	var before: Vector2=host.player
	var facts: String=JSON.stringify(s.qizhenLake)
	host._process(.05)
	check(host.player==before and host.kayak.position==before and host.kayak.speed==0,"blocked movement still stops without sliding or turning")
	check(messages==[original],"blocked contact emits exact original reverse instructions once")
	check(is_equal_approx(host.subtitle_left,2.2),"original2.2s visible duration")
	check(host.lake_session.status=="running" and JSON.stringify(s.qizhenLake)==facts,"feedback does not cancel proof or change lake facts")
	if host.has_method("_show_kayak_boundary_feedback"):
		messages.clear();host._kayak_boundary_hint_at=-2400
		check(host._show_kayak_boundary_feedback(0),"first encounter has no initial wait")
		check(not host._show_kayak_boundary_feedback(2399),"2399ms remains inside original cooldown")
		check(messages.size()==1,"repeated collision cannot flood the hint")
		check(host._show_kayak_boundary_feedback(2400) and messages.size()==2,"2400ms boundary allows next original hint")
		check(not host._show_kayak_boundary_feedback(2400),"same-time duplicate stays silent")
		s.qizhenLake.zone="channel";host.refresh_world()
		check(not host._show_kayak_boundary_feedback(4799),"same lake scene retains cooldown across a zone change")
		check(host._show_kayak_boundary_feedback(4800),"zone change does not lengthen the cooldown")
		s.qizhenLake.zone="open_water";host.refresh_world()
		s.native.scene="campus_bootstrap";host.refresh_world();s.native.scene="qizhen_lake";host.refresh_world()
		check(host._show_kayak_boundary_feedback(0),"fresh lake scene resets transient hint clock")
		state.story_reset.emit()
		check(host._show_kayak_boundary_feedback(0),"ordinary state replacement resets transient hint clock")
	else: check(false,"boundary feedback includes its original cooldown owner")
	# Recover from the same collision through an ordinary legal reverse step.
	host.player=before;host.kayak.position=before;host.kayak.heading=0;host.kayak.speed=-80;host.kayak.remainder=0
	host.lake_session._previous=before;host.lake_session._motion_remainder=0
	host._process(.05)
	check(host.player.x<before.x and host.can_stand(host.player),"reverse step can leave the retained obstacle bounds")
	check(host.kayak.heading==0 and host.lake_session.status=="running","reverse keeps heading and session authority")
	for i in 45:host._process(.05)
	check(host.subtitle.is_empty(),"hint expires after original duration during clear-water recovery")
	for extent: Vector2 in [Vector2(370,712),Vector2(410,728)]:
		host.size=extent;host.mobile_exploration=true;host.subtitle=original
		var hud: Dictionary=host.hud_metrics(original)
		var footer:=Rect2(hud.body_gap,extent.y-hud.body_gap-hud.body_height,extent.x-hud.body_gap*2,hud.body_height)
		var needed: Vector2=host.font.get_multiline_string_size(original,HORIZONTAL_ALIGNMENT_CENTER,hud.body_width,hud.body_font)
		check(needed.y+16<=hud.body_height and needed.x<=hud.body_width+.01,"full original reverse instructions fit compact footer")
		for rectangle: Rect2 in host.kayak_paddle_rects().values():
			check(not rectangle.intersects(footer),"expanded original hint leaves visible paddle targets clear")
	host.free();await process_frame
	print("KAYAK_BOUNDARY_FEEDBACK: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
