extends RefCounted
## Deterministic rule port of TheaterSpotlightModel.ts. Fixed 50 ms ticks and full replay validation.
const ACTS: Array = [
	{"title":"椅子申请当月亮","subtitle":"追上游走的逗号。预判轨迹，绕开走动的椅子。","glyph":"，","count":4},
	{"title":"你的影子迟到了","subtitle":"两枚问号成一组。先点亮任一枚，及时把光接到另一枚。","glyph":"？","count":5},
	{"title":"观众席正在退潮","subtitle":"同色标点成对亮起。","glyph":"！","count":6}
]
const FOOD: Array = [Vector2(300,193),Vector2(515,341),Vector2(738,187),Vector2(800,361),Vector2(346,344),Vector2(567,178)]

func create(round_id: int, attempt: int = 0) -> Dictionary:
	return {"round":round_id,"attempt":attempt,"tick":0,"status":"running","head":Vector2(156,280),"trail":[Vector2(156,280)],"history":[Vector2(156,280)],"collected":[],"focus":[0,0,0,0,0,0],"primed":-1,"pairTicks":0,"pairFailures":0,"lives":3,"invulnerable":0,"dashTicks":0,"dashCooldown":0,"dashHeld":false,"lastDirection":Vector2.RIGHT,"lastEvent":"none"}

func food(s:Dictionary,id:int)->Vector2:
	if s.round==2:return FOOD[id]
	var t:float=s.tick*.05*maxf(.82,1.0-s.attempt*.035)
	var horizontal:float=[35.0,48.0,60.0][s.round]
	var vertical:float=[18.0,23.0,29.0][s.round]
	return FOOD[id]+Vector2(sin(t*(.85+s.round*.15+id*.09)+id*1.4)*horizontal,cos(t*(1.1+id*.08)+id*1.7)*vertical)
func focus_ticks(s:Dictionary)->int:return [1,20,16][s.round]
func light_radius(s:Dictionary)->float:return 25.0 if s.round==0 else 75.0
func pair_window(s:Dictionary)->int:return 110 if s.round==1 else 125
func pairs(s:Dictionary)->Array:return [[0,2],[4,3]] if s.round==1 else [[0,2],[4,3],[5,1]]
func partner(s:Dictionary,id:int)->int:
	for pair:Array in pairs(s):
		if pair.has(id):return pair[1] if pair[0]==id else pair[0]
	return -1
func active_food(s:Dictionary)->Array:
	if s.round==0:return [0,1,2,3].filter(func(id):return not s.collected.has(id))
	if s.primed>=0:return [partner(s,s.primed)]
	if s.round==1 and s.collected.size()==4:return [1]
	var result:Array=[]
	for pair:Array in pairs(s):
		for id:int in pair:
			if not s.collected.has(id):result.append(id)
	return result
func echo(s:Dictionary)->Dictionary:
	return {"position":s.history[s.history.size()-61]} if s.round==2 and s.history.size()>60 else {}
func food_blocked(s:Dictionary,id:int,origin:Vector2=Vector2.INF)->bool:
	if s.round==0:return false
	if not origin.is_finite():origin=s.head
	var point:Vector2=food(s,id);var ray:Vector2=point-origin
	for hazard:Dictionary in hazards(s):
		if hazard.kind!="chair":continue
		var ratio:float=clampf((hazard.position-origin).dot(ray)/maxf(.001,ray.length_squared()),0,1)
		if (origin+ray*ratio).distance_to(hazard.position)<hazard.radius+5:return true
	return false
func _reset_pair(s:Dictionary)->void:
	if s.primed>=0:s.pairFailures+=1
	s.primed=-1;s.pairTicks=0;s.focus=[0,0,0,0,0,0]

func mouth(s: Dictionary) -> Vector2:
	return Vector2(839,266 + sin(s.tick * 0.035) * 36 if s.round == 2 else 274)

func hazards(s: Dictionary) -> Array:
	var t: float = s.tick * 0.05 * maxf(0.72,1.0-s.attempt*0.045)
	var result: Array = [{"kind":"chair","position":Vector2(421+sin(t*0.8)*66,264+sin(t*1.3)*82),"radius":21},{"kind":"chair","position":Vector2(655+sin(t*0.67+2)*72,281+cos(t*1.1)*78),"radius":21}]
	if s.round == 1 and s.history.size() > 60: result.append({"kind":"shadow","position":s.history[s.history.size()-61],"radius":22})
	if s.round == 2: result.append({"kind":"eye","position":Vector2(495+cos(t*0.9)*125,255+sin(t*1.5)*88),"radius":23})
	return result

func pointer_axis(s:Dictionary,target:Vector2,dash:bool=false)->Vector2:
	# Preserve analog magnitude so the last 50ms step cannot overrun its target.
	var next_dash:int=maxi(0,s.dashTicks-1)
	if dash and not s.dashHeld and s.dashCooldown<=1:next_dash=9
	var distance:float=16.5 if next_dash>0 else 8.3
	var bounded:=Vector2(clampf(target.x,71,889),clampf(target.y,145,396))
	var drift:=Vector2.ZERO
	if s.round==2 and next_dash==0:drift=Vector2(cos((s.tick+1)*.019)*.7,sin((s.tick+1)*.028)*1.5)
	return ((bounded-s.head-drift)/distance).limit_length(1.0)

func step(s: Dictionary, input: Dictionary) -> Dictionary:
	if s.status != "running": return s
	var n: Dictionary = s.duplicate(true)
	n.tick += 1
	n.invulnerable = maxi(0,s.invulnerable-1)
	n.dashTicks = maxi(0,s.dashTicks-1)
	n.dashCooldown = maxi(0,s.dashCooldown-1)
	n.dashHeld = input.dash
	n.lastEvent = "none"
	var direction: Vector2 = Vector2(clampf(input.x,-1,1),clampf(input.y,-1,1))
	var magnitude: float = direction.length()
	if magnitude > 0.001:
		n.lastDirection = direction/magnitude
		if magnitude>1.0:direction/=magnitude
	if input.dash and not s.dashHeld and n.dashCooldown == 0:
		n.dashTicks = 9
		n.dashCooldown = 100
		n.lastEvent = "dash"
	var speed: float = 330.0 if n.dashTicks > 0 else 166.0
	if n.dashTicks > 0 and magnitude < 0.001: direction = s.lastDirection
	n.head += direction*speed*0.05
	if s.round == 2 and n.dashTicks == 0: n.head += Vector2(cos(n.tick*0.019)*0.7,sin(n.tick*0.028)*1.5)
	n.head = Vector2(clampf(n.head.x,71,889),clampf(n.head.y,145,396))
	n.history.append(n.head)
	if n.history.size() > 100: n.history.pop_front()
	if n.head.distance_to(s.trail[0]) > 3:
		n.trail.push_front(n.head)
		n.trail = n.trail.slice(0,24+n.collected.size()*5)
	if n.primed>=0:
		n.pairTicks-=1
		if n.pairTicks<=0:_reset_pair(n);n.lastEvent="reset"
	if s.collected.size()>=ACTS[n.round].count and n.head.distance_to(mouth(n))<35:
		n.status="won";n.lastEvent="exit";return n
	var hurt:=false
	if n.invulnerable == 0 and n.dashTicks == 0:
		for hazard: Dictionary in hazards(n):
			if n.head.distance_to(hazard.position) < hazard.radius+10:
				n.lives -= 1
				n.invulnerable = 36
				n.lastEvent = "hurt";hurt=true
				_reset_pair(n)
				break
	var eligible:Array=active_food(n);var selected:=-1;var nearest:float=INF
	for id:int in eligible:
		var distance:float=n.head.distance_to(food(n,id))
		if distance<light_radius(n) and distance<nearest and not food_blocked(n,id):selected=id;nearest=distance
	if n.round==2:
		var echo_state:Dictionary=echo(n);var charged:Array=[]
		if not hurt and not echo_state.is_empty() and n.dashTicks==0:
			var ghost:Vector2=echo_state.position
			for pair:Array in pairs(n):
				if n.collected.has(pair[0]):continue
				for side:int in [0,1]:
					var own:int=pair[side];var other:int=pair[1-side]
					if n.head.distance_to(food(n,own))<light_radius(n) and ghost.distance_to(food(n,other))<light_radius(n) and not food_blocked(n,own) and not food_blocked(n,other,ghost):charged=pair;break
				if not charged.is_empty():break
		for id:int in range(int(ACTS[n.round].count)):
			if n.collected.has(id):continue
			n.focus[id]=n.focus[id]+1 if charged.has(id) else 0
		if not charged.is_empty() and n.focus[charged[0]]>=focus_ticks(n):
			n.collected.append_array(charged);n.focus=[0,0,0,0,0,0];n.lastEvent="eat"
	elif not hurt:
		for id:int in range(int(ACTS[n.round].count)):
			if n.collected.has(id) or n.primed==id:continue
			if id==selected and (n.round==0 or n.dashTicks==0):n.focus[id]+=1
			else:n.focus[id]=maxi(0,n.focus[id]-2)
			if n.focus[id]<focus_ticks(n):continue
			if n.round==0 or (n.round==1 and id==1):n.collected.append(id);n.lastEvent="eat"
			elif n.primed<0:n.primed=id;n.pairTicks=pair_window(n);n.lastEvent="prime"
			else:
				n.collected.append(n.primed);n.collected.append(id);n.primed=-1;n.pairTicks=0;n.focus=[0,0,0,0,0,0];n.lastEvent="eat"
	if n.collected.size() >= ACTS[n.round].count and n.head.distance_to(mouth(n)) < 35:
		n.status = "won"
		n.lastEvent = "exit"
		return n
	if n.lives <= 0 or n.tick >= 1600: n.status = "lost"
	return n

func validate(value: Variant, round_id: int, attempt: int) -> Dictionary:
	if not value is Dictionary: return {}
	if value.get("version") != 2 or value.get("round") != round_id or value.get("attempt") != attempt: return {}
	var inputs: Variant = value.get("inputs")
	if not inputs is Array or inputs.is_empty() or inputs.size() > 1600: return {}
	var s: Dictionary = create(round_id,attempt)
	for input: Variant in inputs:
		if s.status != "running" or not input is Dictionary: return {}
		if not (input.get("x") is float or input.get("x") is int) or not (input.get("y") is float or input.get("y") is int) or not input.get("dash") is bool: return {}
		if not is_finite(input.x) or not is_finite(input.y) or absf(input.x) > 1 or absf(input.y) > 1: return {}
		s = step(s,input)
	return s if s.status != "running" else {}
