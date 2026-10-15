extends RefCounted
## Presentation only. Original returnedTrayIds changes own acceptance and rewards.
static func duration(reduced:bool)->float:return .16 if reduced else .32
static func sample(age:float,hand:Vector2,anchor:Vector2,height:float,reduced:bool)->Dictionary:
	var t:float=clampf(age/duration(reduced),0,1)
	var contact_t:float=.3125
	var impact_t:float=.5625
	var pressure:float=0
	if t>=contact_t and t<impact_t:
		pressure=lerpf(0,.015 if reduced else .11,smoothstep(contact_t,impact_t,t))
	elif t>=impact_t:
		if reduced:pressure=lerpf(.015,0,smoothstep(impact_t,1,t))
		elif t<.80:pressure=lerpf(.11,-.014,smoothstep(impact_t,.80,t))
		else:pressure=lerpf(-.014,0,smoothstep(.80,1,t))
	var contact:Vector2=anchor+Vector2(0,-height*.67*(1-pressure))
	var at:Vector2=contact
	var angle:float=-PI/2
	if t<contact_t:
		var approach:float=smoothstep(0,contact_t,t)
		at=hand.lerp(contact+Vector2(-1,-2 if not reduced else 0),approach)
		if not reduced:at.y-=sin(approach*PI)*8
		angle=lerpf(0,-PI/2-.20 if not reduced else -PI/2,approach)
	elif t<impact_t:
		var lay:float=smoothstep(contact_t,impact_t,t)
		at+=Vector2(-1,-2 if not reduced else 0)*(1-lay)
		angle=lerpf(-PI/2-.20 if not reduced else -PI/2,-PI/2,lay)
	var alpha:float=1-smoothstep(.75,1,t)
	return {"size":lerpf(24,28,smoothstep(0,contact_t,t)),"position":at,"angle":angle,"pressure":pressure,"alpha":alpha,"contact":contact,"settled":t>=1,"phase":"approach" if t<contact_t else ("contact" if t<impact_t else ("weight" if t<.80 else "settle"))}
