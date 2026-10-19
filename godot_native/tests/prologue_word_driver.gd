extends RefCounted
## Reads visible card state and issues existing pointer intents; never writes proof.
static func goal(game)->float:return goal_model(game.session)
static func goal_model(session)->float:
 var wanted:Array=session.missing()
 var next=str(wanted[0]) if not wanted.is_empty() else ""
 var desired=float(session.board_x)
 var found=false
 for card:Dictionary in session.cards:
  if not card.resolved and card.text in wanted and (not session.current().get("ordered",false) or card.text==next):
   desired=card.position.x;found=true;break
 for card:Dictionary in session.cards:
  var wrong=not card.text in wanted or (session.current().get("ordered",false) and card.text!=next)
  if card.resolved or not wrong:continue
  # Let the earlier wrong word cross before moving under a later target.
  if (not found or (card.position.y>=500 and card.position.y<=716)) and absf(clampf(desired,104,326)-card.position.x)<82+card.size.x/2+6:
   desired=104.0 if card.position.x>215 else 326.0
 return desired
static func steer(game)->void:
 if game.phase in ["deploy","intercept"] and not game.session.reviewing:
  var x=goal(game)
  game._pointer(game.board_center(),true)
  game._pointer(game.field.position+Vector2(x,658)*game.display_scale,true)
 elif game.phase=="lock":game._pointer(game.field.position+game._lock_center()*game.display_scale,true)
static func until(game,target:String,seconds:float=120)->bool:
 for index in int(seconds/.01):
  if game.phase==target:return true
  if game.phase=="failed":return false
  steer(game);game._process(.01)
 return game.phase==target
