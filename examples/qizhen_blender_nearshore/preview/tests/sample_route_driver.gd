extends RefCounted
var throttle: bool=false
var turn: float=0
var brake: bool=false
var use: bool=false
var dock_stage: bool=false
var return_stage: int=0
func control(game: RefCounted) -> void:
 var goal: Dictionary=game.route_goals[game.progress]
 var target: Vector2=goal.point
 throttle=false;brake=false;use=false
 if goal.type=="dock":
  if not dock_stage:
   if return_stage==0:
    target=Vector2(5650,3310)
    if game.position.distance_to(target)<75:return_stage=1
   else:
    target=Vector2(6000,3060)
    if game.position.distance_to(target)<55 and game.speed<65:dock_stage=true
  else:target=Vector2(6000,2843)
 var delta: Vector2=target-game.position
 var desired: float=delta.angle()
 if goal.type=="dock" and dock_stage and delta.length()<50:desired=-PI/2
 var error: float=angle_difference(game.heading,desired)
 turn=clampf(error*2.9,-1,1)
 var distance: float=delta.length()
 if goal.type=="gate":
  throttle=absf(error)<.95;brake=absf(error)>1.2
 elif goal.type=="collect":
  if distance<55:
   brake=true;use=true
  elif distance<110:
   throttle=game.speed<45 and absf(error)<.8;brake=game.speed>65
  else:throttle=absf(error)<.85;brake=absf(error)>1.1
 elif goal.type=="dock":
  if not dock_stage:
   if distance<130 and return_stage>0:throttle=game.speed<45 and absf(error)<.5;brake=game.speed>55
   else:throttle=absf(error)<.7;brake=absf(error)>1.0
  else:
   throttle=game.speed<40 and distance>8 and absf(error)<.25
   brake=game.speed>48 or distance<10
   use=true
