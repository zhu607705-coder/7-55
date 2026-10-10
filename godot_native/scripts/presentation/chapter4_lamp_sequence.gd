extends RefCounted
## Source: ChapterFourStarLampSequence.ts. Pure presentation clock, no state writes.
static func smooth(value:float)->float:
	var t:=clampf(value,0,1)
	return t*t*t*(t*(t*6-15)+10)
static func frame(time_ms:float,reduced:bool=false)->Dictionary:
	var t:=maxf(0,time_ms)
	var rise:=1.0 if reduced else smooth((t-120)/2080)
	return {"duration":3600.0 if reduced else 5800.0,"rise":rise,
		"reveal":smooth(t/(200.0 if reduced else 260.0)),
		"led":smooth((t-(850.0 if reduced else 2350.0))/(620.0 if reduced else 780.0))*.7,
		"core":smooth((t-(1300.0 if reduced else 2750.0))/(650.0 if reduced else 800.0))*.62,
		"glow":smooth((t-(1460.0 if reduced else 2930.0))/(760.0 if reduced else 960.0))*.26,
		"caption":smooth((t-(2650.0 if reduced else 4150.0))/(280.0 if reduced else 300.0)),
		"camera":Vector3(0,lerpf(-5.8,.35,rise),-lerpf(12.4,15.8,rise)),
		"look":Vector3(0,lerpf(-4.1,.25,rise),0),"scale":lerpf(1.16,.92,rise),"offset":lerpf(-.22,0,rise)}
