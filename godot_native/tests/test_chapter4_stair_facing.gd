extends SceneTree
const Stairs=preload("res://scripts/games/chapter4_stairs.gd")
const WalkArt=preload("res://scripts/player_walk_art.gd")
var checks:=0
var failures:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func run()->void:
	var directions:=[Vector3.FORWARD,Vector3.BACK,Vector3.RIGHT,Vector3.LEFT]
	var cameras:=[Vector3(0,3,6),Vector3(6,3,0),Vector3(0,3,-6),Vector3(-6,3,0)]
	var expected:=[[["up",false],["down",false],["side",false],["side",true]],[["side",false],["side",true],["down",false],["up",false]],[["down",false],["up",false],["side",true],["side",false]],[["side",true],["side",false],["up",false],["down",false]]]
	var game=Stairs.new();root.add_child(game)
	game.camera=Camera3D.new();root.add_child(game.camera)
	game.actor=Sprite3D.new();root.add_child(game.actor)
	for view_index in cameras.size():
		game.camera.position=cameras[view_index];game.camera.look_at(Vector3.ZERO)
		for index in directions.size():
			game.facing_world=directions[index];game.walking=false;game.walk_ms=0
			var retained:Vector3=game.facing_world
			game._process(.016)
			var want:Array=expected[view_index][index]
			check(game.facing==want[0] and (game.facing!="side" or game.facing_left==want[1]),"Four-direction selection at camera %d direction %d"%[view_index,index])
			check(game.actor.texture==WalkArt.texture(game.facing),"Idle renders the shared side/front/back source frame")
			check(game.facing_world==retained and not game.walking and game.walk_ms==0,"A camera turn preserves stopped world heading and motion state")
	game.facing_world=Vector3.FORWARD
	game.camera.position=cameras[0];game.camera.look_at(Vector3.ZERO);game._process(.016)
	var before:Texture2D=game.actor.texture
	game.camera.position=cameras[1];game.camera.look_at(Vector3.ZERO);game._process(.016)
	check(before==WalkArt.texture("up") and game.actor.texture==WalkArt.texture("side"),"Camera-only rotation changes the visible actor view without a walk")
	game.camera.queue_free();game.actor.queue_free();game.queue_free();await process_frame
	print("STAIR_FACING ",checks," checks; ",failures," failures");quit(1 if failures else 0)
