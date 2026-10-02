extends RefCounted
## Literal rule port of TheaterSpotlightModel.ts. Fixed 50 ms ticks and full replay validation.
const ACTS: Array = [
	{"title":"椅子申请当月亮","subtitle":"吃掉逗号。椅子会自己走路，别让它坐到你身上。","glyph":"，","count":4},
	{"title":"你的影子迟到了","subtitle":"吃掉问号。影子沿着你三秒前的路线追过来。","glyph":"？","count":5},
	{"title":"观众席正在退潮","subtitle":"吃掉感叹号。掌声会把光推走；集齐后钻进谢幕的大嘴。","glyph":"！","count":6}
]
const FOOD: Array = [Vector2(300,193),Vector2(515,341),Vector2(738,187),Vector2(800,361),Vector2(346,344),Vector2(567,178)]

func create(round_id: int, attempt: int = 0) -> Dictionary:
	return {"round":round_id,"attempt":attempt,"tick":0,"status":"running","head":Vector2(156,280),"trail":[Vector2(156,280)],"history":[Vector2(156,280)],"collected":[],"lives":3,"invulnerable":0,"dashTicks":0,"dashCooldown":0,"dashHeld":false,"lastDirection":Vector2.RIGHT,"lastEvent":"none"}

func mouth(s: Dictionary) -> Vector2:
	return Vector2(839,266 + sin(s.tick * 0.035) * 36 if s.round == 2 else 274)

func hazards(s: Dictionary) -> Array:
	var t: float = s.tick * 0.05 * maxf(0.72,1.0-s.attempt*0.045)
	var result: Array = [{"kind":"chair","position":Vector2(421+sin(t*0.8)*40,264+sin(t*1.3)*87),"radius":21},{"kind":"chair","position":Vector2(655+sin(t*0.67+2)*49,281+cos(t*1.1)*69),"radius":21}]
	if s.round >= 1 and s.history.size() > 60: result.append({"kind":"shadow","position":s.history[s.history.size()-61],"radius":22})
	if s.round == 2: result.append({"kind":"eye","position":Vector2(495+cos(t*0.9)*125,255+sin(t*1.5)*88),"radius":23})
	return result

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
		direction /= magnitude
		n.lastDirection = direction
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
	for id: int in range(int(ACTS[n.round].count)):
		if not n.collected.has(id) and n.head.distance_to(FOOD[id]) < 25:
			n.collected.append(id)
			n.lastEvent = "eat"
	if n.collected.size() >= ACTS[n.round].count and n.head.distance_to(mouth(n)) < 35:
		n.status = "won"
		n.lastEvent = "exit"
		return n
	if n.invulnerable == 0 and n.dashTicks == 0:
		for hazard: Dictionary in hazards(n):
			if n.head.distance_to(hazard.position) < hazard.radius+10:
				n.lives -= 1
				n.invulnerable = 36
				n.lastEvent = "hurt"
				break
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
