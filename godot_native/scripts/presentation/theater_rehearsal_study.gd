extends RefCounted
## Optional folio evidence from real accepted trials. Never a completion gate.
var trials:Dictionary={}
var pairs:Dictionary={}
var sealed:Dictionary={}
const NEEDS=[["spread"],["distance"],["lamp_x","lamp_depth"]]

func record(trial:Dictionary)->void:
	var round_id:int=int(trial.round)
	if round_id<0 or round_id>2:return
	if not trials.has(round_id):trials[round_id]=[];pairs[round_id]={}
	for prior:Dictionary in trials[round_id]:
		var relation:String=compare(prior,trial)
		if relation in NEEDS[round_id]:pairs[round_id][relation]={"before":prior.duplicate(true),"after":trial.duplicate(true)}
	trials[round_id].append(trial.duplicate(true))
	if trials[round_id].size()>24:trials[round_id].pop_front()

static func compare(a:Dictionary,b:Dictionary)->String:
	if a.round!=b.round or a.objects.size()!=b.objects.size():return ""
	var changes:Array[String]=[]
	for key:String in ["lampX","lampDepth"]:
		if not is_equal_approx(float(a[key]),float(b[key])):changes.append(key)
	for i:int in a.objects.size():
		if a.objects[i].id!=b.objects[i].id:return ""
		for key:String in ["x","depth","spread"]:
			if not is_equal_approx(float(a.objects[i].get(key,0)),float(b.objects[i].get(key,0))):changes.append(str(i)+"/"+key)
	if changes.size()!=1:return ""
	var changed:String=changes[0]
	if changed=="0/spread" and absf(float(a.objects[0].spread)-float(b.objects[0].spread))>=.24:return "spread"
	if changed=="0/depth" and absf(float(a.objects[0].depth)-float(b.objects[0].depth))>=.8:return "distance"
	if changed=="lampX" and absf(float(a.lampX)-float(b.lampX))>=.4:return "lamp_x"
	if changed=="lampDepth" and absf(float(a.lampDepth)-float(b.lampDepth))>=.5:return "lamp_depth"
	return ""

func snapshot(round_id:int)->Dictionary:
	var found:Dictionary=pairs.get(round_id,{})
	var ready:bool=true
	for relation:String in NEEDS[round_id]:
		if not found.has(relation):ready=false
	return {"ready":ready,"sealed":bool(sealed.get(round_id,false)),"pairs":found.duplicate(true),"trials":trials.get(round_id,[]).size()}

func seal(round_id:int)->bool:
	if not snapshot(round_id).ready or sealed.get(round_id,false):return false
	sealed[round_id]=true;return true
