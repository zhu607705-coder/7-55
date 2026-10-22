extends SceneTree
const Chase=preload("res://scripts/games/chase_stunt_model.gd")
const Fishing=preload("res://scripts/games/rhythm_fishing_model.gd")
const Kayak=preload("res://scripts/games/kayak_model.gd")
var failures: int=0
func check(ok: bool,message: String) -> void:
	if not ok:
		failures+=1
		push_error(message)
	else: print("PASS ",message)
func _init() -> void:
	var idle: RefCounted=Chase.new()
	for i: int in range(16000):
		if idle.status!="running": break
		idle.step()
	check(idle.status=="lost" and idle.collisions==3,"Untouched chase loses by real collisions")
	var jump: RefCounted=Chase.new()
	jump.press("jump")
	for i: int in range(60): jump.step()
	check(jump.air_height==0 and jump.charge>0.7,"Jump charges on hold without premature takeoff")
	jump.release("jump")
	jump.step()
	check(jump.air_height>0 and jump.air_velocity>7,"Charged release jumps")
	var tray: RefCounted=Chase.new()
	while tray.distance<27: tray.step()
	check(tray.powerup=="tray","Visible tray is collected on matching lane")
	tray.press("item")
	check(tray.shield and tray.powerup=="","Item input equips and consumes carried tray")
	while tray.distance<44: tray.step()
	check(not tray.shield and tray.lives==3 and tray.collisions==0,"Tray absorbs one collision without lost life")
	var bell: RefCounted=Chase.new()
	while bell.distance<30: bell.step()
	bell.press("bell")
	check(bell.cleared.size()==2 and bell.bell_cooldown>2,"Bell clears only reachable soft obstacles")
	var chase: RefCounted=Chase.new()
	chase.press("left")
	while chase.lane>0.5: chase.step()
	chase.neutral()
	while chase.status=="running": chase.step()
	var chase_result: Dictionary=chase.result()
	check(chase.status=="won" and Chase.validate_result(chase_result),"755 m continuous-steering win replays exactly")
	save_fixture("chase",chase_result)
	check(Chase.validate_result(JSON.parse_string(JSON.stringify(chase_result))),"Chase replay survives JSON save/load numeric types")
	var forged: Dictionary=chase_result.duplicate(true)
	forged.collisions=999
	check(not Chase.validate_result(forged),"Forged chase collision summary rejected")
	for id: String in ["locker_key","net_frame","fish","paper"]:
		var fish: RefCounted=solve_fishing(id)
		check(fish.phase=="completed" and fish.final_result.get("passed",false),"Fishing "+id+" playable to completion")
		if not fish.final_result.is_empty():
			check(Fishing.validate_result(fish.final_result,id),"Fishing "+id+" full v4 trace replays")
			save_fixture("rhythm_"+id,fish.final_result)
			forged=fish.final_result.duplicate(true)
			forged.inputs=[]
			check(not Fishing.validate_result(forged,id),"Fishing "+id+" forged summary rejected")
	var no_inputs: RefCounted=Fishing.new()
	no_inputs.configure("locker_key",Fishing.load_chart("locker_key"))
	no_inputs.update(30)
	check(no_inputs.phase=="idle" and no_inputs.elapsed==0,"Fishing clock stays idle until first real input")
	no_inputs.press("hook")
	no_inputs.update(0.1)
	no_inputs.release("hook")
	check(no_inputs.stage=="casting","Unaligned/undercharged cast does not start fight")
	var unsafe: RefCounted=Kayak.new()
	unsafe.configure({"phase":"boarding","goal":4})
	for i: int in range(4): unsafe.stroke("left")
	check(unsafe.status=="lost" and unsafe.capsizes==1,"Four same-side strokes capsize")
	for phase: String in ["boarding","rain","travel","chase"]:
		var cfg: Dictionary={"phase":phase,"goal":1000 if phase=="chase" else (220 if phase=="travel" else 4)}
		var boat: RefCounted=Kayak.new()
		boat.configure(cfg)
		var count: int=0
		while boat.status=="running" and boat.tick<10000:
			if boat.tick%36==0:
				boat.stroke("left" if count%2==0 else "right")
				count+=1
			if boat.status=="running": boat.step()
		var result: Dictionary=boat.result()
		check(boat.status=="won","Kayak "+phase+" completes with alternate strokes")
		check(Kayak.validate_result(result,cfg),"Kayak "+phase+" trace replays")
		save_fixture("kayak_"+phase,result)
		check(Kayak.validate_result(JSON.parse_string(JSON.stringify(result)),cfg),"Kayak "+phase+" replay survives JSON save/load")
	var boat: RefCounted=Kayak.new()
	boat.configure({"phase":"world","bounded":false})
	boat.position=Vector2(2000,2000)
	boat.stroke("left")
	boat.update(0.25)
	check(boat.position.x>2000 and boat.status=="running","World kayak uses caller coordinates without channel clamps")
	boat.speed=0
	boat.stroke("left",true)
	boat.update(0.1)
	check(boat.speed<0,"Reverse stroke escapes stopped boundary")
	print("MINIGAME MODEL FAILURES: ",failures)
	quit(1 if failures else 0)

func solve_fishing(id: String) -> RefCounted:
	var fish: RefCounted=Fishing.new()
	fish.configure(id,Fishing.load_chart(id))
	fish.press("right")
	var cast_started: bool=false
	for i: int in range(16000):
		if fish.phase in ["completed","failed"]: break
		fish.update(1.0/120.0)
		var difference: float=fish.fish_x()-fish.line_x
		if difference>0.018:
			fish.release("left")
			fish.press("right")
		elif difference< -0.018:
			fish.release("right")
			fish.press("left")
		else:
			fish.release("right")
			fish.release("left")
		if fish.stage=="casting":
			if fish.aligned() and not cast_started:
				fish.press("hook")
				cast_started=true
			elif fish.held_at>=0 and fish.elapsed-fish.held_at>=0.6: fish.release("hook")
		elif fish.stage=="fighting":
			var note: Dictionary=fish.current_note()
			if note.is_empty(): continue
			var until: float=float(note.timeSec)-fish.elapsed
			if until<=0:
				fish.release("hook")
			elif int(fish.rhythm_position(fish.elapsed).x) in [0,2]: fish.press("hook")
			else: fish.release("hook")
	return fish

func save_fixture(name: String,value: Dictionary) -> void:
	var file: FileAccess=FileAccess.open("res://tests/fixtures/"+name+".json",FileAccess.WRITE)
	if file: file.store_string(JSON.stringify(value))
