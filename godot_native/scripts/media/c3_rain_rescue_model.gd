extends RefCounted
## Presentation-only transcription of QizhenRainRescuePresentation.ts and
## QizhenLakeScene.playRainRescueSequence. Positions remain source pixels.
const START: Dictionary={"x":714.0,"y":424.0,"heading":-PI/2,"roll":0.0}
const ROUTE: Array=[
	{"x":700.0,"y":386.0,"heading":-1.7,"roll":0.11,"side":"left","intensity":0.82},
	{"x":718.0,"y":348.0,"heading":-1.48,"roll":-0.08,"side":"right","intensity":0.9},
	{"x":702.0,"y":307.0,"heading":-1.72,"roll":0.16,"side":"left","intensity":0.96},
	{"x":721.0,"y":267.0,"heading":-1.43,"roll":-0.2,"side":"right","intensity":1.02},
	{"x":699.0,"y":228.0,"heading":-1.82,"roll":0.34,"side":"left","intensity":1.08},
	{"x":724.0,"y":192.0,"heading":-1.37,"roll":-0.48,"side":"right","intensity":1.14}
]
const REDUCED_ROUTE_INDICES: Array=[0,3,4]
const TIMING: Dictionary={
	"normal":{"approachMs":460,"launchMs":520,"strokeMs":420,"strokeGapMs":90,"gustMs":620,"capsizeMs":1080,"rescueHoldMs":1600},
	"reduced":{"approachMs":160,"launchMs":180,"strokeMs":150,"strokeGapMs":35,"gustMs":200,"capsizeMs":400,"rescueHoldMs":800}
}
const WATCHDOG_MS: float=9000.0
const RESCUE_POINT: Vector2=Vector2(720,744)
const APPROACH_POINT: Vector2=Vector2(690,620)
const MAP_SIZE: Vector2=Vector2(1672,941)
const VIDEO_PATH: String="res://assets/rpg/cinematics/qizhen-rain-rescue/qizhen_rain_rescue_hailuo23_v01.ogv"
const VIDEO_DURATION_MS: float=5875.0

static func timing(reduced: bool) -> Dictionary:
	return TIMING.reduced if reduced else TIMING.normal

static func route(reduced: bool) -> Array:
	var result: Array=[]
	for index: int in REDUCED_ROUTE_INDICES if reduced else range(ROUTE.size()): result.append(ROUTE[index].duplicate())
	return result

static func pre_cinematic_ms(reduced: bool) -> float:
	var t: Dictionary=timing(reduced)
	var count: int=REDUCED_ROUTE_INDICES.size() if reduced else ROUTE.size()
	return t.approachMs+t.launchMs+t.strokeMs*count+t.strokeGapMs*(count-1)+t.gustMs+t.capsizeMs

static func duration_ms(reduced: bool) -> float:
	return pre_cinematic_ms(reduced)+timing(reduced).rescueHoldMs

static func _blend(from: Dictionary, to: Dictionary, ratio: float) -> Dictionary:
	var pose: Dictionary={}
	for key: String in ["x","y","heading","roll"]: pose[key]=lerpf(float(from[key]),float(to[key]),ratio)
	return pose

static func pose_at(elapsed_ms: float, reduced: bool, initial: Vector2=APPROACH_POINT) -> Dictionary:
	var t: Dictionary=timing(reduced)
	var time: float=maxf(0,elapsed_ms)
	if time<t.approachMs:
		var p: float=sin(time/t.approachMs*PI/2)
		return {"stage":"approach","x":lerpf(initial.x,690,p),"y":lerpf(initial.y,620,p),"alpha":1.0,"localMs":time}
	time-=t.approachMs
	if time<t.launchMs:
		var p: float=sin(time/t.launchMs*PI/2)
		var pose: Dictionary=START.duplicate()
		pose.merge({"stage":"launch","y":lerpf(468,424,p),"alpha":lerpf(0.36,1,p),"speed":lerpf(54,108,p),"localMs":time},true)
		return pose
	time-=t.launchMs
	var points: Array=route(reduced)
	var previous: Dictionary=START
	for index: int in range(points.size()):
		var point: Dictionary=points[index]
		if time<t.strokeMs:
			var p: float=sin(time/t.strokeMs*PI/2)
			var pose: Dictionary=_blend(previous,point,p)
			pose.merge({"stage":"stroke","side":point.side,"intensity":point.intensity,"strokeIndex":index,"speed":228-p*72,"alpha":1.0,"localMs":time})
			return pose
		time-=t.strokeMs
		previous=point
		if index<points.size()-1:
			if time<t.strokeGapMs:
				var pose: Dictionary=point.duplicate()
				pose.merge({"stage":"gap","speed":36.0,"alpha":1.0,"strokeIndex":index,"localMs":time})
				return pose
			time-=t.strokeGapMs
	var gust: Dictionary={"x":previous.x+46,"y":previous.y-14,"heading":previous.heading+0.72,"roll":-1.0}
	if time<t.gustMs:
		var p: float=pow(time/t.gustMs,3)
		var pose: Dictionary=_blend(previous,gust,p)
		pose.merge({"stage":"gust","speed":118*(1-p),"alpha":1.0,"localMs":time})
		return pose
	time-=t.gustMs
	if time<t.capsizeMs:
		var p: float=pow(clampf(time/roundf(t.capsizeMs*0.62),0,1),3)
		var pose: Dictionary=gust.duplicate()
		# QizhenKayakVisual dramatic capsize. Body begins at roll * 5 = -5.
		pose.merge({"stage":"capsize","speed":0.0,"alpha":1.0,"bodyAngle":lerpf(0,-82,p),"bodyY":lerpf(-5,-22,p),"bodyScale":Vector2(lerpf(1,0.76,p),lerpf(1,0.68,p)),"bodyAlpha":lerpf(1,0.14,p),"localMs":time})
		return pose
	return {"stage":"cinematic","x":gust.x,"y":gust.y,"localMs":time-t.capsizeMs}

static func rescued_pose(elapsed_ms: float, reduced: bool) -> Dictionary:
	var p: float=sin(clampf(elapsed_ms/(180.0 if reduced else 620.0),0,1)*PI/2)
	return {"stage":"rescued","x":720.0,"y":lerpf(756,744,p),"alpha":lerpf(0.28,1,p),"localMs":maxf(0,elapsed_ms)}
