extends SceneTree
const Model=preload("res://scripts/games/large_world_model.gd")
const Geo=preload("res://scripts/games/lake_geometry.gd")
var view: Node2D
var passed: Array[String]=[]
var failures: Array[String]=[]
var alignment: Array[Dictionary]=[]
func check(ok: bool,label: String) -> void:
 if ok:passed.append(label);print("PASS ",label)
 else:failures.append(label);push_error(label)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 view=load("res://scenes/blender_lake_sample.tscn").instantiate();root.add_child(view);view.set_process(false);view.title_open=false
 check(view.environment_glb.get_child_count()>15,"environment is an instantiated GLB with batched paint groups")
 check(view.boat_3d.get_child_count()>0,"boat is an instantiated GLB")
 check(view.actor_sprite is Sprite3D and view.actor_sprite.alpha_cut==SpriteBase3D.ALPHA_CUT_DISCARD,"live pixel actor participates in 3D depth testing")
 check(view.rig.get_parent()==view.actor_canvas,"approved rig renders into a live isolated texture")
 var maximum: float=0
 for size in [Vector2i(1280,720),Vector2i(844,390),Vector2i(390,844),Vector2i(1024,768)]:
  root.size=size;view._update_layout()
  for p in [Vector2(6000,2850),Vector2(5810,3655),Vector2(5480,3140)]:
   for speed: float in [0.0,140.0,285.0]:
    view.game.position=p;view.game.speed=speed;view._sync(0,true)
    for q in [p,p+Vector2(100,0),p+Vector2(0,100)]:
     var error: float=view.world_to_screen(q).distance_to(view.ground_to_screen_3d(q));maximum=maxf(maximum,error)
     alignment.append({"size":[size.x,size.y],"center":[p.x,p.y],"speed":speed,"zoom":view.cam.zoom.x,"point":[q.x,q.y],"error_px":error})
 check(maximum<.01,"108 ground projection probes across 3 positions / zooms and 4 aspect ratios under 0.01px")
 var game:=Model.new();game.navigation_check=view._platform_clear;game.position=Vector2(6000,2900);game.heading=-PI/2;game.speed=285;game.input(true,0,false,false)
 for n in range(240):game.step(1./120)
 check(game.position.y>=2836.9,"northbound boat stops at the visible float surface")
 check(not view.DOCK_RECT.has_point(game.position+Vector2.from_angle(game.heading)*39),"rigid bow cannot overlap the float deck")
 game.reset();game.position=Vector2(5790,3500);game.heading=0;game.speed=285;game.navigation_check=view._platform_clear;game.input(true,0,false,false)
 for n in range(240):game.step(1./120)
 check(Geo.water(game.position+Vector2.from_angle(game.heading)*39,1),"rigid bow remains in water at the east stone bank")
 check(not view._platform_clear(Vector2(6000,2770),-PI/2),"float footprint rejects an intersecting hull")
 check(not view._contact_allowed(game,{"type":"dock"}),"E cannot claim a remote mooring")
 for scenario in [{"p":Vector2(5843,3500),"h":PI/2,"turn":-1.0},{"p":Vector2(6000,2829),"h":0.0,"turn":-1.0},{"p":Vector2(5952,2754),"h":-PI/2,"turn":1.0}]:
  game.reset();game.position=scenario.p;game.heading=scenario.h;game.navigation_check=view._platform_clear;game.input(false,scenario.turn,false,false)
  var safe_rotation: bool=true
  for n in range(126):
   game.step(1./120);safe_rotation=safe_rotation and view._platform_clear(game.position,game.heading)
  check(safe_rotation,"stationary turn cannot rotate the rigid hull into shore or platform at "+str(scenario.p))
 game.reset();game.position=Vector2(6000,2850);game.heading=-PI/2;game.route_goals=view.sample_goals();game.progress=2;game.recovered=true;game.interaction_check=view._contact_allowed;game.input(false,0,true,true)
 for n in range(240):game.step(1./120)
 check(game.status=="running" and game.action_hold==0,"holding E 15px from deck cannot complete mooring")
 check(not view.actor_sprite.no_depth_test,"pixel actor does not bypass the depth buffer")
 view._restart();view.title_open=false;view.game.input(true,0,false,false);view.game.step(1.);view._sync(0,true)
 var before: Dictionary=view.game.result();view._set_overview(true)
 for n in range(60):view._process(1./60)
 check(before==view.game.result(),"map pauses physics and sample goals")
 check(view.rig.get_parent()==view,"map restores original 2D actor rendering")
 view._set_overview(false);view._sync(0,true)
 check(view.rig.get_parent()==view.actor_canvas,"return from map restores depth-tested actor")
 check(view.keys.is_empty() and view.touch_left==-1 and view.touch_right==-1,"map return clears stale inputs")
 var out: Dictionary={"passed":passed,"failures":failures,"maximum_ground_alignment_error_px":maximum,"alignment_probes":alignment}
 var f:=FileAccess.open("res://../verification/sample-tests.json",FileAccess.WRITE);f.store_string(JSON.stringify(out,"  "));print("SAMPLE_TESTS ",passed.size()," passed / ",failures.size()," failed");quit(0 if failures.is_empty() else 1)
