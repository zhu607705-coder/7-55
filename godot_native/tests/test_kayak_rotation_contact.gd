extends SceneTree
var state: Node
var host: Control
var checks:=0
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(value: bool,label: String) -> void:
 checks+=1
 if not value: failures+=1;push_error(label)
func setup(saved_position: Vector2=Vector2.INF) -> void:
 if is_instance_valid(host): host.free()
 state.d=state.initial()
 var s: Dictionary=state.d
 s.native.positions={};s.native.chapter=3;s.native.scene="qizhen_lake";s.native.page="c3_lake";s.native.mode="light";s.runtimeMode="rpg";s.rpgScene="qizhen_lake"
 s.qizhenLake.merge({"active":true,"phase":"boarding_tutorial","zone":"dock","vehicle":"kayak","boardingTutorialCompleted":false,"rainSafetyCleared":true,"kayakEquipped":true,"leftPaddleEquipped":true,"rightPaddleEquipped":true},true)
 if saved_position.is_finite(): s.native.positions["qizhen_lake:dock:kayak"]={"x":saved_position.x,"y":saved_position.y}
 host=load("res://scripts/world.gd").new();host.size=Vector2(960,540);root.add_child(host);host.set_process(false);host.refresh_world()
func frames(count: int) -> void:
 for i in range(count):
  host._process(1.0/60)
  check(host.can_stand(host.player),"every integrated frame keeps full source hull outside dock")
  check(state.lake_module().live_session.status!="cancelled","ordinary physics cannot cancel live session")
func stroke(side: String,reverse: bool=false) -> void: state.lake_module().world_stroke(state.d,host,side,reverse)
func run() -> void:
 state=root.get_node("State");state.developer_mode=true
 # Original authored spawn is first made safe by existing refresh; do not move it by fiat.
 for reverse: bool in [false,true]:
  for side: String in ["left","right"]:
   setup()
   var start: Vector2=host.player
   var model=load("res://scripts/games/kayak_model.gd").new();model.configure({"phase":"world","bounded":false});model.position=start;model.heading=host.kayak.heading;model.capsize_allowance=0.3;model.stroke(side,reverse)
   stroke(side,reverse)
   check(host.kayak.heading==model.heading and host.kayak.roll==model.roll and host.kayak.speed==model.speed,"contact preserves exact source stroke heading/roll/impulse")
   check(host.player.distance_to(start)<6,"initial dock separation is local, not a spawn teleport")
   frames(30)
   check(state.d.qizhenLake.boardingStrokeCount==(0 if reverse else 1),"reverse cannot satisfy forward tutorial")
   stroke("right" if side=="left" else "left",false);frames(20)
   check(state.d.qizhenLake.boardingStrokeCount>0,"following stroke remains accepted after dock contact")
 # Keep real motion frames between tutorial inputs; the old test omitted this.
 setup()
 for side: String in ["left","right","left","right"]:
  stroke(side);frames(12)
 check(state.d.qizhenLake.boardingTutorialCompleted and state.d.qizhenLake.zone=="open_water","four integrated forward strokes reach open water")
 # A backwards bump stops at the same dock and can be escaped with forward strokes.
 setup();stroke("left",true);frames(30)
 var stopped: Vector2=host.player;var heading: float=host.kayak.heading
 check(host.kayak.speed==0 and host.can_stand(stopped),"backward dock contact stops motion without overlap")
 frames(10);check(host.kayak.heading==heading,"collision itself does not rotate the hull")
 stroke("right");frames(20);check(host.player.distance_to(stopped)>5,"ordinary opposite stroke moves away from boundary")
 # The real failed save's legal position reloads without editing its coordinates.
 var failed_pose:=Vector2(706.272583007812,387.929443359375)
 setup(failed_pose);check(host.player.is_equal_approx(failed_pose),"ordinary failed-save pose is preserved on reload")
 stroke("left",true);frames(12);stroke("right");frames(12)
 check(state.d.qizhenLake.boardingStrokeCount==1,"failed-save session accepts reverse then forward after reload")
 # Four close same-side strokes still capsize; physics fix must not make balancing easier.
 setup()
 for i in range(4): stroke("left");frames(2)
 check(state.d.qizhenLake.capsizeCount==1,"source same-side capsize remains")
 frames(70)
 check(state.lake_module().live_session.status=="running","capsize retry restores a live session")
 stroke("right");frames(12)
 check(state.d.qizhenLake.boardingStrokeCount==1,"retry accepts a new stroke")
 # Calling a stroke cannot legitimize a caller-moved pose or remint a cancelled receipt.
 setup();host.player+=Vector2(400,0);host.kayak.position=host.player
 stroke("left")
 check(state.lake_module().live_session.status=="cancelled" and state.d.qizhenLake.boardingStrokeCount==0,"forged teleport rejected before contact separation")
 host.free();host=load("res://scripts/world.gd").new();host.size=Vector2(960,540);root.add_child(host);host.set_process(false)
 check(state.lake_module().live_session.status=="running","normal host recreation gets a fresh binding")
 # A geometric correction never accepts an origin already inside a solid.
 setup();host.player=Vector2(714,500);host.kayak.position=host.player
 check(not host.resolve_kayak_rotation(-PI/2) and host.player==Vector2(714,500),"deep invalid pose cannot be repaired into proof")
 host.free();print("Kayak rotation contact: ",checks," checks, ",failures," failures");quit(1 if failures else 0)
