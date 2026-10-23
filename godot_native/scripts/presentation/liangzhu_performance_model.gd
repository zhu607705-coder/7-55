extends RefCounted
## Runtime-only original stage blocking and optional QTEs. No State/save authority.
const LOGICAL_SIZE=Vector2i(240,135)
const PIXELS_PER_UNIT=5.0
const RASTER_SIZE=Vector2i(1200,675)
const DURATION_MS=54000.0
const BEATS=[0.0,8000.0,20000.0,38000.0,54000.0]
const CONTENT_PATH="res://data/native/liangzhu-performance.content.json"
const BUTTERFLY_LAUNCH_MS=48000.0
static var _content:Dictionary={}
var elapsed_ms:=0.0
var runtime_ms:=0.0
var manually_paused:=false
var focus_paused:=false
var input_blocked:=false
var reduced_motion:=false
var playback_mode:="interactive"
var status:="playing"
var active_qte:Dictionary={}
var qte_completed:Dictionary={}
var qte_results:Array[Dictionary]=[]

func _init(reduced:bool=false,mode:String="interactive")->void:
	reduced_motion=reduced;playback_mode=mode if mode in ["interactive","passive"] else "interactive"

static func _definition()->Dictionary:
	if _content.is_empty():
		var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string(CONTENT_PATH))
		if parsed is Dictionary:_content=parsed
	return _content

static func content()->Dictionary:return _definition().duplicate(true)

func set_playback_mode(mode:String)->bool:
	if elapsed_ms!=0.0 or runtime_ms!=0.0 or status!="playing" or mode not in ["interactive","passive"]:return false
	playback_mode=mode;return true

func pause()->void:
	if status in ["playing","waiting","failure"]:manually_paused=true;_clear_hold()

func resume()->void:
	if status in ["playing","waiting","failure"]:manually_paused=false;focus_paused=false

func cancel()->void:
	if status!="complete":status="cancelled"
	active_qte={}

func _clear_hold()->void:
	if not active_qte.is_empty():active_qte.holdOwner="";active_qte.holdStart=-1.0

func interrupt_input(reason:String="interrupted")->void:
	_clear_hold()
	if status=="waiting":active_qte.interruption=reason;focus_paused=true

func _begin_qte(definition:Dictionary)->void:
	active_qte=definition.duplicate(true)
	active_qte.merge({"status":"waiting","elapsedMs":0.0,"holdOwner":"","holdStart":-1.0,"hintTier":0,"attempts":1,"feedback":"","interruption":""},true)
	status="waiting"

func _fail_qte()->Dictionary:
	status="failure";active_qte.status="failure";active_qte.feedback=active_qte.failure
	active_qte.hintTier=mini(2,int(active_qte.hintTier)+1);_clear_hold()
	return {"accepted":false,"reason":"missed","qteId":active_qte.id}

func retry_qte()->bool:
	if status!="failure" or active_qte.is_empty():return false
	status="waiting";active_qte.status="waiting";active_qte.elapsedMs=0.0;active_qte.feedback="";active_qte.interruption="";active_qte.attempts=int(active_qte.attempts)+1
	_clear_hold();return true

func request_qte_help()->String:
	if active_qte.is_empty():return ""
	active_qte.hintTier=mini(2,int(active_qte.hintTier)+1)
	return str(active_qte.help[mini(int(active_qte.hintTier)-1,active_qte.help.size()-1)])

func _pass_qte(direction:String="")->Dictionary:
	var id:String=active_qte.id
	qte_completed[id]=true
	qte_results.append({"id":id,"action":active_qte.action,"runtimeMs":runtime_ms,"timelineMs":elapsed_ms,"attempts":active_qte.attempts,"direction":direction,"mode":"interactive"})
	active_qte={};status="playing"
	return {"accepted":true,"reason":"passed","qteId":id}

func qte_input(action:String,phase:String="tap",direction:String="",owner:String="keyboard")->Dictionary:
	if playback_mode!="interactive" or status!="waiting" or manually_paused or focus_paused or input_blocked or active_qte.is_empty():return {"accepted":false,"reason":"inactive"}
	if action!=str(active_qte.action):return {"accepted":false,"reason":"different_action"}
	if action=="catch" and phase=="tap":return _pass_qte()
	if action=="turn" and phase=="swipe":
		if direction==str(active_qte.direction):return _pass_qte(direction)
		return _fail_qte()
	if action=="butterfly":
		if phase=="press":
			if owner.is_empty() or not str(active_qte.holdOwner).is_empty():return {"accepted":false,"reason":"owned"}
			active_qte.holdOwner=owner;active_qte.holdStart=runtime_ms;return {"accepted":true,"reason":"holding"}
		if phase=="release":
			if owner!=str(active_qte.holdOwner) or float(active_qte.holdStart)<0.0:return {"accepted":false,"reason":"different_owner"}
			var held:float=runtime_ms-float(active_qte.holdStart)
			if held>=float(active_qte.holdMinMs) and held<=float(active_qte.holdMaxMs):return _pass_qte()
			return _fail_qte()
	return {"accepted":false,"reason":"different_phase"}

func tick(delta:float,focused:bool=true,blocked:bool=false)->bool:
	if status in ["complete","cancelled"]:return false
	input_blocked=blocked
	if not focused:focus_paused=true;_clear_hold()
	if blocked:_clear_hold()
	if manually_paused or focus_paused or blocked or status=="failure" or not is_finite(delta) or delta<=0:return false
	var advance:float=delta*1000.0
	runtime_ms+=advance
	if status=="waiting":
		active_qte.elapsedMs=float(active_qte.elapsedMs)+advance
		if float(active_qte.elapsedMs)>=float(active_qte.windowMs):_fail_qte()
		elif float(active_qte.holdStart)>=0.0 and runtime_ms-float(active_qte.holdStart)>float(active_qte.get("holdMaxMs",INF)):_fail_qte()
		return false
	var next:float=minf(DURATION_MS,elapsed_ms+advance)
	if playback_mode=="interactive":
		for definition:Dictionary in _definition().get("qtes",[]):
			if not qte_completed.has(str(definition.id)) and float(definition.atMs)>=elapsed_ms and float(definition.atMs)<=next:
				elapsed_ms=float(definition.atMs);_begin_qte(definition);return false
	elapsed_ms=next
	if elapsed_ms>=DURATION_MS:status="complete";return true
	return false

func qte_snapshot()->Dictionary:
	if active_qte.is_empty():return {}
	var result:Dictionary=active_qte.duplicate(true)
	result.holding=not str(result.holdOwner).is_empty()
	result.holdProgress=clampf((runtime_ms-float(result.holdStart))/float(result.get("holdMinMs",1.0)),0,1) if result.holding else 0.0
	result.helpText=str(result.help[mini(int(result.hintTier)-1,result.help.size()-1)]) if int(result.hintTier)>0 else ""
	result.erase("holdOwner");result.erase("holdStart")
	return result

func snapshot()->Dictionary:
	var result:Dictionary=pose_at(elapsed_ms,reduced_motion)
	result.merge({"status":status,"manuallyPaused":manually_paused,"focusPaused":focus_paused,"playbackMode":playback_mode,"runtimeMs":runtime_ms,"qte":qte_snapshot(),"qteCompleted":qte_completed.keys(),"qteResults":qte_results.duplicate(true)},true)
	return result

static func _point(x:float,y:float)->Vector2:
	return Vector2(roundf(x*PIXELS_PER_UNIT),roundf(y*PIXELS_PER_UNIT))/PIXELS_PER_UNIT

static func _stride(ms:float)->int:return 1 if int(floor(ms/220.0))%2==0 else 0

static func _walk_actor(actor:Dictionary,from:Vector2,to:Vector2,fraction:float,ms:float)->void:
	var point:Vector2=from.lerp(to,clampf(fraction,0,1))
	actor.foot=_point(point.x,point.y);actor.frame=_stride(ms)

static func _curtain(ms:float)->float:
	if ms<2400:return ms/2400.0
	for boundary:float in [20000.0,38000.0]:
		if ms>=boundary-1400.0 and ms<boundary:return (boundary-ms)/1400.0
		if ms>=boundary and ms<boundary+2000.0:return (ms-boundary)/2000.0
	return 1.0

static func _socket_fan(actor:String,side:int=0,socket:String="FanSocket",spread:int=3)->Dictionary:
	return {"kind":"fan","point":Vector2.ZERO,"spread":spread,"flap":0,"side":side,"attachment":{"kind":"socket","actor":actor,"socket":socket}}

static func pose_at(time_ms:float,reduced:bool=false)->Dictionary:
	var ms:float=clampf(time_ms if is_finite(time_ms) else 0.0,0,DURATION_MS)
	var beat:int=0 if ms<8000 else 1 if ms<20000 else 2 if ms<38000 else 3
	var data:Dictionary=_definition()
	var scene:Dictionary=data.scenes[0 if beat<=1 else beat-1]
	var cue:Dictionary=data.cues[-1]
	for candidate:Dictionary in data.cues:
		if ms>=float(candidate.startMs) and ms<float(candidate.endMs):cue=candidate;break
	var a:Dictionary={"id":"scholar","row":0,"frame":3,"foot":Vector2(108,90),"flip":false,"alpha":1.0}
	var b:Dictionary={"id":"yingtai","row":1,"frame":3,"foot":Vector2(132,90),"flip":true,"alpha":1.0}
	var fans:Array=[]
	if beat==1:
		if ms<9500:
			_walk_actor(a,Vector2(108,90),Vector2(94,90),(ms-8000)/1500.0,ms)
			_walk_actor(b,Vector2(132,90),Vector2(146,90),(ms-8000)/1500.0,ms+110)
		elif ms<11000:
			_walk_actor(a,Vector2(94,90),Vector2(94,106),(ms-9500)/1500.0,ms)
			_walk_actor(b,Vector2(146,90),Vector2(146,108),(ms-9500)/1500.0,ms+110)
		elif ms<14000:
			_walk_actor(a,Vector2(94,106),Vector2(110,106),(ms-11000)/3000.0,ms)
			_walk_actor(b,Vector2(146,108),Vector2(130,108),(ms-11000)/3000.0,ms+110)
		else:a.foot=Vector2(110,106);b.foot=Vector2(130,108);a.frame=2;b.frame=2
		var fan:Dictionary=_socket_fan("yingtai")
		if ms>=15000 and ms<16200:fan.attachment={"kind":"handoff","fromActor":"yingtai","fromSocket":"FanSocket","toActor":"scholar","toSocket":"FanSocket","amount":clampf((ms-15000)/1200.0,0,1),"arc":0.4}
		elif ms>=16200:fan.attachment={"kind":"socket","actor":"scholar","socket":"FanSocket"}
		if ms>=18000:b.frame=3
		fans.append(fan)
	elif beat==2:
		a.foot=Vector2(108,106);b.foot=Vector2(132,90);a.frame=0;b.frame=3
		if ms>=27000 and ms<=29000:a.frame=2;b.frame=2
		elif ms>29000:a.frame=3;b.frame=3;a.flip=ms<33500
		fans.append(_socket_fan("yingtai",0,"FanSocket",1))
	elif beat==3:
		a.alpha=0.0;a.foot=Vector2(108,85);b.foot=Vector2(132,102);b.frame=3
		if ms>=45000:b.frame=2
		if ms>=49000:b.alpha=[170.0/255.0,85.0/255.0,0.0][clampi(int((ms-49000)/900.0),0,2)]
		if ms>=42000:
			for side:int in 2:
				var socket:String="FanSocket" if side==0 else "LeftFanSocket"
				if ms<BUTTERFLY_LAUNCH_MS:fans.append(_socket_fan("yingtai",side,socket,clampi(3-int(maxf(0,ms-46000)/650.0),0,3)))
				else:
					var start:Vector2=Vector2(122.2,88) if side==0 else Vector2(137.4,85.4)
					var end:=Vector2(112,50) if side==0 else Vector2(132,46)
					var progress:float=clampf((ms-BUTTERFLY_LAUNCH_MS)/4000.0,0,1)
					var point:Vector2=start.lerp(end,progress);point.x+=sin(progress*PI*2.0+side*PI)*3.0*sin(progress*PI)
					fans.append({"kind":"butterfly","point":_point(point.x,point.y),"spread":3,"flap":int((ms-BUTTERFLY_LAUNCH_MS)/180.0)%4,"side":side,"attachment":{"kind":"release","actor":"yingtai","socket":socket,"launchMs":BUTTERFLY_LAUNCH_MS,"progress":progress,"start":start,"end":end}})
	var curtain:float=_curtain(ms)
	if reduced:
		curtain=1.0
		a.foot=[Vector2(108,90),Vector2(110,106),Vector2(108,106),Vector2(108,85)][beat]
		b.foot=[Vector2(132,90),Vector2(130,108),Vector2(132,90),Vector2(132,102)][beat]
		a.frame=2 if beat==1 else 3;b.frame=a.frame;a.flip=false;b.flip=true
		fans=[]
		if beat in [1,2]:fans.append(_socket_fan("yingtai",0,"FanSocket",3 if beat==1 else 1))
		if beat==3:
			# Reduced motion preserves the actual waiting target; it does not
			# substitute the post-release tableau before the player's action.
			b.frame=2;b.alpha=1.0 if ms<BUTTERFLY_LAUNCH_MS else 0.0
			for side:int in 2:
				if ms<BUTTERFLY_LAUNCH_MS:fans.append(_socket_fan("yingtai",side,"FanSocket" if side==0 else "LeftFanSocket",3))
				else:fans.append({"kind":"butterfly","point":Vector2(112,50) if side==0 else Vector2(132,46),"spread":3,"flap":1,"side":side,"attachment":{"kind":"fixed"}})
	var stage_props:Array=[]
	for source:Dictionary in data.stageProps:
		var prop:Dictionary=source.duplicate(true)
		prop.alpha=1.0 if beat<3 or str(prop.id)=="left_chair" else 0.0
		stage_props.append(prop)
	var speaker:String=cue.speaker
	return {"elapsedMs":ms,"durationMs":DURATION_MS,"beat":beat,"sceneId":scene.id,"sceneTitle":scene.title,"speaker":speaker,"text":cue.text,"cueId":cue.id,"lineStartMs":cue.startMs,"lineEndMs":cue.endMs,"delivery":cue.delivery,"caption":(speaker+"：" if not speaker.is_empty() else "")+str(cue.text),"curtain":curtain,"actors":[a,b],"fans":fans,"stageProps":stage_props,"reducedMotion":reduced,"samplingMode":"canonical-passive-presentation"}
