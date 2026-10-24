extends RefCounted
## One persistent deduction chain; only Chapter4 commits the authored world time.
const IDS := ["1225_bakery","1850_evening","2245_maintenance"]
const EVIDENCE := ["start","delay","event"]
const WHEELS := ["hour","minute"]
static var _data: Dictionary = {}
static func data() -> Dictionary:
	if _data.is_empty(): _data=JSON.parse_string(FileAccess.get_file_as_string("res://data/native/chapter4-clock-chain.json"))
	return _data
static func fresh(id: String="1225_bakery") -> Dictionary:
	var spec: Dictionary=data().runs[id]
	return {"step":0,"source":"","evidence":[],"target":"","repair":"","hour":int(spec.initialHour),"minute":int(spec.initialMinute),"locks":[],"trims":{},"samples":0,"verification":""}
static func integer(v: Variant) -> bool:
	return (v is int or v is float) and is_finite(float(v)) and float(v)==floor(float(v))
static func exact_set(v: Array, expected: Array) -> bool:
	if v.size()!=expected.size(): return false
	for id in expected:
		if v.count(id)!=1: return false
	return true
static func valid_run(v: Variant, id: String) -> bool:
	if id not in IDS or not v is Dictionary or v.size()!=fresh().size(): return false
	for key in fresh():
		if not v.has(key): return false
	for key in ["step","hour","minute","samples"]:
		if not integer(v[key]): return false
	if v.step<0 or v.step>7 or v.hour<0 or v.hour>23 or v.minute<0 or v.minute>55 or int(v.minute)%5!=0 or v.samples<0 or v.samples>3: return false
	var spec: Dictionary=data().runs[id]
	if v.source!=("hall" if v.step>=1 else ""): return false
	if not v.evidence is Array or v.evidence.size()>5: return false
	for entry in v.evidence:
		if entry not in ["start","delay","event","night","cache"] or v.evidence.count(entry)!=1: return false
	if v.step==0 and not v.evidence.is_empty(): return false
	if v.step>=2 and not exact_set(v.evidence,EVIDENCE): return false
	if v.target!=(id if v.step>=3 else "") or v.repair!=(spec.repair if v.step>=4 else ""): return false
	if not v.locks is Array or v.locks.size()>2: return false
	for wheel in v.locks:
		if wheel not in WHEELS or v.locks.count(wheel)!=1: return false
	if v.step<4 and (v.hour!=spec.initialHour or v.minute!=spec.initialMinute or not v.locks.is_empty()): return false
	if v.step>=5 and (not exact_set(v.locks,WHEELS) or v.hour!=spec.hour or v.minute!=spec.minute): return false
	if not v.trims is Dictionary or v.trims.size()>3: return false
	var known: Array=[]
	for channel in channels(id):
		known.append(channel.id)
		if v.trims.has(channel.id) and (not integer(v.trims[channel.id]) or abs(int(v.trims[channel.id]))>45): return false
	for key in v.trims:
		if key not in known: return false
	if v.step<5 and not v.trims.is_empty(): return false
	if v.step>=6 and (v.trims.size()!=3 or not balanced(id,v.trims)): return false
	if v.step<6 and v.samples!=0: return false
	if v.verification!=("live" if v.step==7 else ""): return false
	if v.step==7 and v.samples!=3: return false
	return true

static func valid_legacy_run(v: Variant, id: String) -> bool:
	if id not in IDS or not v is Dictionary or v.size()!=fresh().size(): return false
	for key in fresh():
		if not v.has(key): return false
	for key in ["step","hour","minute","samples"]:
		if not integer(v[key]): return false
	if v.step<0 or v.step>7 or v.hour<0 or v.hour>23 or v.minute<0 or v.minute>55 or int(v.minute)%5!=0 or v.samples<0 or v.samples>3: return false
	var spec: Dictionary=data().runs[id]
	if v.source!=("hall" if v.step>=1 else ""): return false
	if not v.evidence is Array or v.evidence.size()>5: return false
	for entry in v.evidence:
		if entry not in ["start","delay","event","night","cache"] or v.evidence.count(entry)!=1: return false
	if v.step==0 and not v.evidence.is_empty(): return false
	if v.step>=2 and not exact_set(v.evidence,EVIDENCE): return false
	if v.target!=(id if v.step>=3 else "") or v.repair!=(spec.repair if v.step>=4 else ""): return false
	if not v.locks is Array or v.locks.size()>2: return false
	for wheel in v.locks:
		if wheel not in WHEELS or v.locks.count(wheel)!=1 or v[wheel]!=spec[wheel]: return false
	if v.step<4 and (v.hour!=spec.initialHour or v.minute!=spec.initialMinute or not v.locks.is_empty()): return false
	if v.step>=5 and not exact_set(v.locks,WHEELS): return false
	if v.step==4 and v.locks.size()==2: return false
	if not v.trims is Dictionary or v.trims.size()>3: return false
	var known: Array=[]
	for channel in channels(id):
		known.append(channel.id)
		if v.trims.has(channel.id) and (not integer(v.trims[channel.id]) or v.trims[channel.id]!=-channel.drift): return false
	for key in v.trims:
		if key not in known: return false
	if v.step<5 and not v.trims.is_empty(): return false
	if v.step>=6 and v.trims.size()!=3: return false
	if v.step==5 and v.trims.size()==3: return false
	if v.step<6 and v.samples!=0: return false
	if v.verification!=("live" if v.step==7 else ""): return false
	if v.step==7 and v.samples!=3: return false
	return true
static func valid(v: Variant) -> bool:
	if not v is Dictionary or v.size()!=2 or not integer(v.get("version")) or int(v.version) not in [1,2] or not v.get("runs") is Dictionary or v.runs.size()>3: return false
	for id in v.runs:
		if not (valid_legacy_run(v.runs[id],id) if int(v.version)==1 else valid_run(v.runs[id],id)): return false
	return true
static func valid_state(s: Dictionary) -> bool:
	var value: Variant=s.native.get("c4_clock_chain")
	if not valid(value): return false
	for id in value.runs:
		if data().runs[id].fact not in s.chapter4.factIds: return false
	return true
static func current(s: Dictionary, id: String) -> Dictionary:
	if not s.native.has("c4_clock_chain"): return fresh(id)
	if not valid_state(s): return {}
	var result:Dictionary=storage(s).runs.get(id,fresh(id)).duplicate(true)
	for key in ["step","hour","minute","samples"]:result[key]=int(result[key])
	for key in result.trims:result.trims[key]=int(result.trims[key])
	return result
static func storage(s:Dictionary)->Dictionary:
	var value:Dictionary=s.native.get("c4_clock_chain",{"version":2,"runs":{}}).duplicate(true)
	if int(value.version)==1:
		for id:String in value.runs:
			var run:Dictionary=value.runs[id]
			# Version 1 saved individually accepted corrections. Preserve all completed
			# stages and translate their values to the linked delay circuit.
			var old:Dictionary=run.trims.duplicate(true)
			var dial:int=int(old.get("dial",0))
			var movement:int=int(old.get("movement",0))-dial
			var phone:int=int(old.get("phone",0))-movement
			if old.has("dial"):run.trims.dial=dial
			if old.has("movement"):run.trims.movement=movement
			if old.has("phone"):run.trims.phone=phone
		value.version=2
	return value
static func residuals(id:String,trims:Dictionary)->Array:
	var drift:Array=data().runs[id].drifts
	var dial:int=int(trims.get("dial",0))
	var movement:int=int(trims.get("movement",0))
	var phone:int=int(trims.get("phone",0))
	return [int(drift[0])+dial,int(drift[1])+dial+movement,int(drift[2])+movement+phone]
static func balanced(id:String,trims:Dictionary)->bool:
	return residuals(id,trims)==[0,0,0]
static func channels(id: String) -> Array:
	var values: Array=data().channels.duplicate(true)
	for index in values.size(): values[index].drift=data().runs[id].drifts[index]
	return values
static func corrections(id: String) -> Array:
	var values: Array=[]
	for drift in data().runs[id].drifts:
		for value in [-abs(int(drift)),abs(int(drift))]:
			if value not in values: values.append(value)
	values.sort()
	return values
static func completed(s: Dictionary,id: String) -> bool:
	var run:=current(s,id)
	return not run.is_empty() and run.step==7
static func transition(id: String, checkpoint: Dictionary, event: Variant) -> Dictionary:
	var result: Dictionary={"accepted":false,"checkpoint":checkpoint.duplicate(true),"message":"这一步还没有对应的依据。","motion":""}
	if not valid_run(checkpoint,id) or not event is Dictionary or not event.get("kind") is String: return result
	var next: Dictionary=checkpoint.duplicate(true)
	var spec: Dictionary=data().runs[id]
	match event.kind:
		"source":
			if next.step!=0 or event.size()!=2: return result
			if event.get("id")!="hall": result.message="这份记录没有响应刚才的拨动，不能作为现场时间源。";return result
			next.source="hall";next.step=1;result.message="现场脉冲已接入。钟壳上的刻印，可以和记录相互核对。"
		"evidence":
			if next.step!=1 or event.size()!=2 or event.get("id") not in ["start","delay","event","night","cache"]: return result
			if event.id in next.evidence: next.evidence.erase(event.id)
			else: next.evidence.append(event.id)
			result.message=""
		"link":
			if next.step!=1 or event.size()!=1: return result
			if not exact_set(next.evidence,EVIDENCE): result.message="刻印或事件对不上。需要同一事件的起点、间隔和终点三条记录。";return result
			next.step=2;result.message="三个碎片属于同一次事件。用起点和间隔，推算刻线对应的时刻。"
		"target":
			if next.step!=2 or event.size()!=3 or not integer(event.get("hour")) or not integer(event.get("minute")): return result
			if event.hour!=spec.hour or event.minute!=spec.minute: result.message="这个时刻与记录的起点、间隔不一致。";return result
			next.target=id;next.step=3;result.message="时刻已记入终端。先试拨，看看哪一段传动没有跟上。"
		"repair":
			if next.step!=3 or event.size()!=2: return result
			if event.get("id")!=spec.repair: result.message="指针仍有同样的异常。再比较转轴、两根针和固定槽的运动。";result.motion="rebound";return result
			next.repair=spec.repair;next.step=4;result.motion="repair";result.message="传动稳定了。分别拨动两组轮轴，再固定它们。"
		"wheel":
			if next.step!=4 or event.size()!=3 or event.get("axis") not in WHEELS or not integer(event.get("delta")) or abs(int(event.delta))!=1: return result
			if event.axis in next.locks: result.message="这根轴已经固定，先松开锁扣。";return result
			var axis: String=event.axis
			next[axis]=posmod(int(next[axis])+int(event.delta)*(5 if axis=="minute" else 1),60 if axis=="minute" else 24)
			result.motion="wheel";result.message=""
		"lock":
			if next.step!=4 or event.size()!=2 or event.get("axis") not in WHEELS: return result
			var axis:String=event.axis
			if axis in next.locks:next.locks.erase(axis)
			else:next.locks.append(axis)
			result.motion="latch";result.message=""
		"compare_wheels":
			if next.step!=4 or event.size()!=1:return result
			if not exact_set(next.locks,WHEELS):result.message="锁扣还开着，试转时轮轴会滑动。";return result
			if next.hour!=spec.hour or next.minute!=spec.minute:result.message="两针合成的时刻与事件记录不符。";result.motion="rebound";return result
			next.step=5;result.message="三路接收留下了错开的脉冲。"
		"trim":
			if next.step!=5 or event.size()!=3 or event.get("channel") not in ["dial","movement","phone"] or not integer(event.get("correction")) or abs(int(event.correction))>45:return result
			next.trims[event.channel]=int(event.correction)
			result.motion="trim";result.message=""
		"balance":
			if next.step!=5 or event.size()!=1:return result
			if next.trims.size()!=3 or not balanced(id,next.trims):result.message="同一脉冲抵达三处的时刻仍不相合。检查连线经过了哪些延迟轮。";return result
			next.step=6;result.message="三处影线重合。换一段间隔，看看它们是否还一起前进。"
		"sample":
			if next.step!=6 or event.size()!=1 or next.samples>=3: return result
			next.samples+=1;result.motion="sample";result.message="已记录第 %d 次机械脉冲。"%int(next.samples)
		"verify":
			if next.step!=6 or event.size()!=2 or next.samples!=3: return result
			if event.get("id")!="live": result.message="冻结缓存不走秒，漂移信号的间隔会变长。找出持续等间隔前进的一路。";return result
			next.step=7;next.verification="live";result.message="连续三次间隔一致。可以合上表冠，让旧钟与现场同时生效。"
		_: return result
	result.accepted=true;result.checkpoint=next
	return result
