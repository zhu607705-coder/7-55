extends RefCounted
## Scene-local text interception. No State, saves, audio, or chapter writes.
const EXTENT=Vector2(430,820)
const ARENA=Rect2(18,270,394,474)
const BOARD_SIZE=Vector2(164,58)
const BOARD_Y=658.0
const BOARD_SPEED=440.0
const MAX_TILT=PI/30.0
const STEP=1.0/120.0
const CARD_HEIGHT=48.0
const FONT_SIZE=24
const SPAWN_INTERVAL=1.9
var stages:Array=[]
var widths:Dictionary={}
var stage=0
var completed_stages=0
var collected:Array=[]
var cards:Array=[]
var phase="clue"
var reviewing=false
var clue_elapsed=0.0
var board_x=215.0
var board_target=215.0
var board_angle=0.0
var board_velocity=0.0
var moved_distance=0.0
var total_misses=0
var stage_misses=0
var hint:Dictionary={}
var contacts:Array=[]
var captures:Array=[]
var clock=0.0
var accumulator=0.0
var spawn_clock=0.0
var spawn_index=0
var target_serial=0
var serial=0
var transition_left=0.0
var last_move=0.0
var events:Array=[]

func setup(content:Dictionary,measured_widths:Dictionary={}) -> void:
	stages=content.get("stages",[]).duplicate(true)
	widths=measured_widths.duplicate()
	stage=0;completed_stages=0;collected=[];cards=[];phase="clue";reviewing=false
	clue_elapsed=0;board_x=215;board_target=215;board_angle=0;board_velocity=0
	moved_distance=0;total_misses=0;stage_misses=0;hint={};contacts=[];captures=[];clock=0;accumulator=0
	spawn_clock=0;spawn_index=0;target_serial=0;serial=0;transition_left=0;last_move=0;events=[]

func current() -> Dictionary:
	return stages[mini(stage,stages.size()-1)] if not stages.is_empty() else {}

func missing() -> Array:
	return current().get("targets",[]).filter(func(word):return not word in collected)

func clue_duration() -> float:
	var total=0.0
	for fragment:String in current().get("fragments",[]):total+=maxf(1.8,fragment.length()*.18)
	return total

func clue_index() -> int:
	var remaining=clue_elapsed
	var fragments:Array=current().get("fragments",[])
	for index:int in fragments.size():
		remaining-=maxf(1.8,str(fragments[index]).length()*.18)
		if remaining<0:return index
	return maxi(0,fragments.size()-1)

func begin_search() -> void:
	if phase!="clue":return
	phase="search";spawn_clock=SPAWN_INTERVAL-.35;spawn_index=0
	events.append({"kind":"search_started","stage":stage})

func set_target(value:float) -> void:
	board_target=clampf(value,ARENA.position.x+BOARD_SIZE.x/2+4,ARENA.end.x-BOARD_SIZE.x/2-4)

func stop_pointer() -> void:
	board_target=board_x

func set_review(value:bool) -> void:
	reviewing=value
	board_target=board_x;board_velocity=0

func continue_stage() -> void:
	if phase!="hint":return
	phase="search";hint={};cards.clear();spawn_index=0;target_serial=0;spawn_clock=SPAWN_INTERVAL-.7
	board_target=board_x;board_velocity=0;accumulator=0
	events.append({"kind":"continued","stage":stage,"collected":collected.duplicate()})

func advance(delta:float,direction:float=0) -> Array:
	events=[]
	if reviewing or phase in ["hint","complete"]:return events
	accumulator+=clampf(delta,0,.25)
	while accumulator+0.0000001>=STEP:
		accumulator=maxf(0,accumulator-STEP)
		if reviewing or phase in ["hint","complete"]:break
		_tick(STEP,direction)
	return events.duplicate(true)

func _tick(dt:float,direction:float) -> void:
	clock+=dt
	if absf(direction)>.01:set_target(board_target+direction*BOARD_SPEED*dt)
	var previous_x=board_x
	board_x=move_toward(board_x,board_target,BOARD_SPEED*dt)
	board_velocity=(board_x-previous_x)/dt
	moved_distance+=absf(board_x-previous_x)
	if absf(board_x-previous_x)>.01:last_move=clock
	board_angle=move_toward(board_angle,clampf(board_velocity/BOARD_SPEED,-1,1)*MAX_TILT,dt*PI)
	if phase=="clue":
		clue_elapsed+=dt
		if clue_elapsed>=clue_duration():begin_search()
		return
	if transition_left>0:
		transition_left-=dt
		if transition_left<=0:
			if completed_stages>=stages.size():phase="complete";return
			stage+=1;collected=[];stage_misses=0;phase="clue";clue_elapsed=0;cards.clear();spawn_clock=0;spawn_index=0;target_serial=0
			return
	spawn_clock+=dt
	if transition_left<=0 and spawn_clock>=SPAWN_INTERVAL and cards.size()<2:
		_spawn();spawn_clock=SPAWN_INTERVAL-1.0 if stage==0 and spawn_index==1 and total_misses==0 else 0
	for card:Dictionary in cards.duplicate():
		if phase!="search":break
		if card.resolved:
			card.position+=card.velocity*dt
			var extent=rotated_extent(card.size/2,card.angle)
			if card.position.x<ARENA.position.x+extent.x:card.position.x=ARENA.position.x+extent.x;card.velocity.x=absf(card.velocity.x)
			if card.position.x>ARENA.end.x-extent.x:card.position.x=ARENA.end.x-extent.x;card.velocity.x=-absf(card.velocity.x)
			if card.position.y+extent.y<ARENA.position.y or card.position.y-extent.y>ARENA.end.y+60:cards.erase(card)
			continue
		_move_card(card,dt,previous_x)

func _spawn() -> void:
	var wanted=missing()
	if wanted.is_empty():return
	var target=spawn_index%2==0
	var word:String
	if target:
		var targets:Array=current().get("targets",[])
		while targets[target_serial%targets.size()] in collected:target_serial+=1
		word=str(targets[target_serial%targets.size()]);target_serial+=1
	else:
		var background:Array=current().get("distractors",[])
		word=str(background[(spawn_index/2 as int)%background.size()])
	serial+=1
	var width=maxf(64,float(widths.get(word,word.length()*24))+32)
	var target_from_left=(int(spawn_index/2)%2)==0
	var from_left=target_from_left if target else not target_from_left
	var demonstration=stage==0 and spawn_index==1 and total_misses==0
	var lane:float=ARENA.position.x+width/2+4 if from_left else ARENA.end.x-width/2-4
	if demonstration:lane=215
	var center=Vector2(lane,294)
	# A word remains readable for at least 3s + .35s per character before contact.
	var readable=3.0+.35*word.length()
	var travel=BOARD_Y-BOARD_SIZE.y/2-CARD_HEIGHT/2-center.y
	var velocity=Vector2(0.0 if demonstration else 4.0 if from_left else -4.0,travel/readable)
	cards.append({"id":serial,"text":word,"target":target,"demonstration":demonstration,"position":center,"size":Vector2(width,CARD_HEIGHT),"angle":deg_to_rad(-3 if from_left else 3),"velocity":velocity,"resolved":false,"life":.65,"age":0.0})
	spawn_index+=1
	events.append({"kind":"spawn","id":serial,"text":word})

func _move_card(card:Dictionary,dt:float,previous_board_x:float) -> void:
	card.age+=dt
	var remaining=dt
	var spent=0.0
	for iteration in range(8):
		if remaining<=.000001:return
		var board_center=Vector2(previous_board_x+board_velocity*spent,BOARD_Y)
		var hit=sweep_rect(card.position,card.velocity,card.size/2,card.angle,board_center,Vector2(board_velocity,0),BOARD_SIZE/2,board_angle,remaining)
		var collision_time=float(hit.get("time",remaining+1))
		var normal:Vector2=hit.get("normal",Vector2.ZERO)
		var kind="board" if not hit.is_empty() else ""
		var ext=rotated_extent(card.size/2,card.angle)
		for boundary in [{"axis":0,"plane":ARENA.position.x+ext.x,"normal":Vector2.RIGHT},{"axis":0,"plane":ARENA.end.x-ext.x,"normal":Vector2.LEFT},{"axis":1,"plane":ARENA.position.y+ext.y,"normal":Vector2.DOWN}]:
			var axis:int=boundary.axis;var n:Vector2=boundary.normal
			if card.velocity.dot(n)>=0:continue
			var time=(float(boundary.plane)-card.position[axis])/card.velocity[axis]
			if time>=-.000001 and time<=remaining and time<collision_time:collision_time=maxf(0,time);normal=n;kind="wall"
		if kind.is_empty():card.position+=card.velocity*remaining;remaining=0
		else:
			card.position+=card.velocity*collision_time;spent+=collision_time;remaining-=collision_time
			var relative:Vector2=card.velocity-(Vector2(board_velocity,0) if kind=="board" else Vector2.ZERO)
			card.velocity=relative.bounce(normal)+(Vector2(board_velocity,0) if kind=="board" else Vector2.ZERO)
			card.position+=normal*.05
			if kind=="board":
				var ax=Vector2.RIGHT.rotated(card.angle);var ay=Vector2.DOWN.rotated(card.angle)
				var point:Vector2=card.position-ax*card.size.x/2*signf(normal.dot(ax))-ay*card.size.y/2*signf(normal.dot(ay))
				contacts.append({"point":point,"normal":normal,"id":card.id,"text":card.text,"time":clock,"board_angle":board_angle,"demonstration":card.get("demonstration",false)})
				if contacts.size()>24:contacts.pop_front()
				_on_contact(card)
				return
		if card.position.y-card.size.y/2>ARENA.end.y:
			if card.text in missing() and (not current().get("ordered",false) or card.text==missing()[0]):
				var reason="unmoved" if moved_distance<6 else "wrong_side" if absf(board_x-card.position.x)>BOARD_SIZE.x/2+card.size.x/2 else "late"
				_fail(reason,card)
			else:cards.erase(card)
			return

func _on_contact(card:Dictionary) -> void:
	card.resolved=true
	events.append({"kind":"contact","id":card.id,"text":card.text})
	if transition_left>0:return
	var wanted:Array=current().get("targets",[])
	if not card.text in wanted:
		# A passive initial graze demonstrates the real solid window, not a choice.
		if not card.get("demonstration",false) or moved_distance>=6:_fail("meaning",card)
		return
	if card.text in collected:return
	if current().get("ordered",false) and card.text!=wanted[collected.size()]:_fail("order",card);return
	collected.append(card.text)
	captures.append({"stage":stage,"id":card.id,"word":card.text,"age":card.age,"spawn_time":clock-card.age,"time":clock})
	events.append({"kind":"collected","word":card.text,"stage":stage})
	if missing().is_empty():
		completed_stages+=1;transition_left=.65
		events.append({"kind":"stage_complete","completed":completed_stages})

func _fail(reason:String,card:Dictionary) -> void:
	if phase!="search":return
	total_misses+=1;stage_misses+=1;phase="hint";board_target=board_x;board_velocity=0
	var next_word=str(missing()[0]) if not missing().is_empty() else ""
	var width=maxf(64,float(widths.get(next_word,next_word.length()*24))+32)
	var landing=ARENA.position.x+width/2+4+4*(3.0+.35*next_word.length())
	hint={"reason":reason,"tier":mini(3,stage_misses),"word":card.text,"missing":missing(),"landing_x":landing}
	events.append({"kind":"miss","misses":total_misses,"hint":hint.duplicate(true)})

static func rotated_extent(half:Vector2,angle:float) -> Vector2:
	return Vector2(absf(cos(angle))*half.x+absf(sin(angle))*half.y,absf(sin(angle))*half.x+absf(cos(angle))*half.y)

static func polygon(center:Vector2,half:Vector2,angle:float) -> PackedVector2Array:
	var result=PackedVector2Array()
	for p:Vector2 in [Vector2(-half.x,-half.y),Vector2(half.x,-half.y),half,Vector2(-half.x,half.y)]:result.append(center+p.rotated(angle))
	return result

static func sweep_rect(a:Vector2,va:Vector2,ha:Vector2,aa:float,b:Vector2,vb:Vector2,hb:Vector2,ab:float,dt:float) -> Dictionary:
	# Continuous separating-axis intervals for two oriented rectangles.
	var enter=0.0;var leave=dt;var hit_normal=Vector2.ZERO
	var overlap_normal=Vector2.ZERO;var overlap_depth=INF;var starts_inside=true
	var axes=[Vector2.RIGHT.rotated(aa),Vector2.DOWN.rotated(aa),Vector2.RIGHT.rotated(ab),Vector2.DOWN.rotated(ab)]
	for axis:Vector2 in axes:
		var radius=ha.x*absf(axis.dot(axes[0]))+ha.y*absf(axis.dot(axes[1]))+hb.x*absf(axis.dot(axes[2]))+hb.y*absf(axis.dot(axes[3]))
		var offset=(a-b).dot(axis);var speed=(va-vb).dot(axis)
		if absf(offset)>radius:starts_inside=false
		elif radius-absf(offset)<overlap_depth:
			overlap_depth=radius-absf(offset);overlap_normal=axis*(1 if offset>=0 else -1)
		if absf(speed)<.000001:
			if absf(offset)>radius:return {}
			continue
		var first=(-radius-offset)/speed;var last=(radius-offset)/speed
		var n=-axis if speed>0 else axis
		if first>last:var swap=first;first=last;last=swap
		if first>=enter:enter=first;hit_normal=n
		leave=minf(leave,last)
		if enter>leave:return {}
	if starts_inside and (va-vb).dot(overlap_normal)<0:return {"time":0.0,"normal":overlap_normal}
	if leave<0 or enter>dt or hit_normal==Vector2.ZERO:return {}
	return {"time":maxf(0,enter),"normal":hit_normal}
