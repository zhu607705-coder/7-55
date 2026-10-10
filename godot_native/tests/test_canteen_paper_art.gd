extends SceneTree
const Paper=preload("res://scripts/presentation/c3_paper_art.gd")
const Model=preload("res://scripts/games/canteen_defense_model.gd")
var checks:=0
var failures:=0

class DrawProbe extends Node2D:
	var poses_drawn:=0
	func _draw() -> void:
		var parent:=Transform2D(0,Vector2.ONE*.56525,0,Vector2(7,4))
		for frame: int in [-1,0,1,2,3]:
			Paper.draw(self,Vector2(60+frame*70,70),1.16,-9,frame,.5,true,parent)
			poses_drawn+=1
		Paper.draw(self,Vector2(80,170),4.9,-7)
		poses_drawn+=1
		Paper.draw(self,Vector2(160,170),.68,86,3,1,true,parent,Vector2(.28,.84))
		Paper.draw(self,Vector2(240,170),.82,-3,1,.18,false,Transform2D.IDENTITY,Vector2.ONE,Color("bdefff"))
		poses_drawn+=2

func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error(label)

func same(a: Variant,b: Variant) -> bool:
	# Source-pixel arithmetic may use int or float; compare numeric values.
	return JSON.parse_string(JSON.stringify(a))==JSON.parse_string(JSON.stringify(b))

func _initialize() -> void:
	var frames: Dictionary={}
	for frame: int in [-1,0,1,2,3]:frames[str(frame)]=Paper.frame_commands(frame)
	check(frames["0"]==frames["2"],"source recovery poses repeat on frames0/2")
	check(frames["1"]!=frames["3"],"left/right stride poses differ beyond body bob")
	for frame: int in range(4):
		var commands: Array=frames[str(frame)]
		var lift: int=2 if frame%2==0 else 0
		var left: int=-5 if frame==1 else 4 if frame==3 else 0
		var right: int=4 if frame==1 else -5 if frame==3 else 0
		check(commands.size()==17,"run frame retains shadow, legs, planes, creases, print and face")
		check(same(commands[1],["polygon",[[16,36-lift],[24,38-lift],[21+left,47],[14+left,46]],"41535e",1]),"authored left folded leg "+str(frame))
		check(same(commands[2],["polygon",[[39,34-lift],[48,33-lift],[50+right,44],[43+right,46]],"41535e",1]),"authored right folded leg "+str(frame))
		check(same(commands[0][1],[32,45,48 if frame%2==0 else 55,8]),"shadow changes width with planted/rising step "+str(frame))
		check(same(commands[4][1][0],[5,5-lift]),"paper body follows2px source lift "+str(frame))
	check(frames["-1"][1][2]=="60717c","resting pickup art has no running legs")
	var changed: Array=Paper.frame_commands(1)
	changed[1][1][0][0]=-100
	check(Paper.frame_commands(1)[1][1][0][0]==16,"callers cannot mutate the shared art")

	# World, portrait close view and overview use one camera composition, even
	# when the source sprite is mirrored and angled. No second camera or origin.
	var point:=Vector2(836,520)
	for zoom: float in [.56525,.68,.19]:
		var offset:=Vector2(41,87)
		var camera:=Transform2D(0,Vector2.ONE*zoom,0,offset)
		for flip: bool in [false,true]:
			for angle: float in [-9,0,9]:
				var pose: Transform2D=Paper.pose_transform(point,1.16,angle,flip)
				check((camera*pose*Vector2.ZERO).is_equal_approx(offset+point*zoom),"camera retains model anchor")
				for local: Vector2 in [Vector2(-29,-25),Vector2(22,22),Vector2(-18,21)]:
					var expected: Vector2=(point+(local*Vector2(-1.16 if flip else 1.16,1.16)).rotated(deg_to_rad(angle)))*zoom+offset
					check((camera*pose*local).is_equal_approx(expected),"source scale/flip/rotation before board camera")
	var default_pose: Transform2D=Paper.pose_transform(Vector2(80,92),4.9,-7)
	check(default_pose.is_equal_approx(Transform2D(deg_to_rad(-7),Vector2.ONE*4.9,0,Vector2(80,92))),"existing pickup defaults remain unflipped screen-space art")
	for axes: Vector2 in [Vector2(1.16,1.16),Vector2(.94,1.08),Vector2(.28,.84)]:
		for flip: bool in [false,true]:
			for angle: float in [-9,14.75,86]:
				var camera:=Transform2D(0,Vector2.ONE*.56525,0,Vector2(7,4))
				var pose: Transform2D=Paper.pose_transform(point,1.0,angle,flip,axes)
				for local: Vector2 in [Vector2.ZERO,Vector2(-29,-25),Vector2(22,22)]:
					var mirrored:=Vector2(-axes.x if flip else axes.x,axes.y)
					var expected: Vector2=(point+(local*mirrored).rotated(deg_to_rad(angle)))*.56525+Vector2(7,4)
					check((camera*pose*local).is_equal_approx(expected),"nonuniform source scale/flip/rotation precedes camera")
				var screen_pose: Transform2D=Paper.pose_transform(point*.56525+Vector2(7,4),.56525,angle,flip,axes)
				check(screen_pose.is_equal_approx(camera*pose),"world and screen-space victory draw paths compose camera once")
	check(Paper.ORIGIN==Vector2(32,25),"64x50 source paper retains centered origin")
	var untinted: Color=Paper.command_color("d7e0e3",.34,.5)
	check(untinted.is_equal_approx(Color("d7e0e3",.17)),"default tint preserves source RGB and opacity")
	var tint:=Color("bdefff")
	tint.a=.02
	var tinted: Color=Paper.command_color("d7e0e3",.34,.5,tint)
	check(tinted.is_equal_approx(Color(untinted.r*tint.r,untinted.g*tint.g,untinted.b*tint.b,.17)),"arrival tint multiplies RGB without changing source/sprite alpha")
	check(Paper.command_color("ffffff",1,1,Color("bdefff")).is_equal_approx(Color("bdefff")),"white source pixel receives exact authored bdefff tint")

	var run=Model.new()
	run.configure("paper-art")
	run.player=Vector2(110,850);run.paper=Vector2(750,520)
	run.route.assign([Vector2(1200,520)]);run.route_index=0
	var seen: Array[int]=[run.paper_frame]
	for tick in range(28):
		run.step({"x":0,"y":0,"dash":false})
		if run.paper_frame!=seen[-1]:seen.append(run.paper_frame)
	check(seen==[0,1,2,3,0],"renderer consumes the existing112-to82ms four-frame model clock")
	var proof: Dictionary=run.result()
	var frame_before: int=run.paper_frame
	var frame_ms_before: float=run.paper_frame_ms
	for repaint in range(60):
		Paper.frame_commands(run.paper_frame)
		Paper.pose_transform(run.paper,1.16,run.paper_angle,run.paper_flip)
	check(run.result()==proof and run.paper_frame==frame_before and run.paper_frame_ms==frame_ms_before,"paused/repeated paints cannot step the simulation or proof")
	run.status="won";run.step({"x":0,"y":0,"dash":false})
	check(run.paper_frame==frame_before,"terminal model keeps the final authored pose")
	run.restart_attempt(false)
	check(run.paper_frame==0 and run.paper_frame_ms==0,"retry uses source recovery frame0")

	# The original impact is a34px recoil with an exit-route flash. Its sprite
	# keeps the current run frame; it does not introduce a second impact clock.
	run.paper=Vector2(750,520);run.player=run.paper-Model.BODY_CENTER
	run.route.assign([run.paper+Vector2(100,0)]);run.route_index=0
	run.paper_hit_cooldown=0;run.paper_frame=1
	var before: Vector2=run.paper
	run.update_paper()
	check(run.paper.is_equal_approx(before+Vector2(78.0/60+34,0)),"authored impact recoil remains34px after normal movement")
	check(run.turnarounds==1 and run.paper_hit_cooldown==720 and run.route_flash==760,"turnaround/cooldown/route flash remain model-owned")
	check(run.paper_frame==1 and Paper.frame_commands(run.paper_frame)==frames["1"],"impact preserves current folded-leg stride")
	var dump_path: String=OS.get_environment("CANTEEN_PAPER_DUMP")
	if not dump_path.is_empty():
		var file=FileAccess.open(dump_path,FileAccess.WRITE)
		check(file!=null,"source-oracle geometry dump is writable")
		if file!=null:file.store_string(JSON.stringify(frames))
	call_deferred("check_draw_calls")

func check_draw_calls() -> void:
	var probe=DrawProbe.new()
	root.add_child(probe)
	await process_frame
	await process_frame
	check(probe.poses_drawn>=8,"source poses, unchanged pickup, nonuniform victory and tinted ghost calls execute on CanvasItem")
	probe.free()
	print("CANTEEN_PAPER_ART ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
