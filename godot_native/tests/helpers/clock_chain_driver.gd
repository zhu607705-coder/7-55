extends RefCounted
const Model=preload("res://scripts/games/chapter4_clock_chain.gd")
static func events(id:String)->Array:
	var spec:Dictionary=Model.data().runs[id]
	var result:Array=[{"kind":"source","id":"hall"}]
	for evidence in Model.EVIDENCE:result.append({"kind":"evidence","id":evidence})
	result.append({"kind":"link"});result.append({"kind":"target","hour":spec.hour,"minute":spec.minute});result.append({"kind":"repair","id":spec.repair})
	for axis in Model.WHEELS:
		var start:int=int(spec.initialHour if axis=="hour" else spec.initialMinute)
		var count:int=posmod(int(spec[axis])-start,24 if axis=="hour" else 60)/(1 if axis=="hour" else 5)
		for i in count:result.append({"kind":"wheel","axis":axis,"delta":1})
		result.append({"kind":"lock","axis":axis})
	result.append({"kind":"compare_wheels"})
	var dial:int=-int(spec.drifts[0])
	var movement:int=-int(spec.drifts[1])-dial
	var phone:int=-int(spec.drifts[2])-movement
	for pair in [["dial",dial],["movement",movement],["phone",phone]]:result.append({"kind":"trim","channel":pair[0],"correction":pair[1]})
	result.append({"kind":"balance"})
	for i in 3:result.append({"kind":"sample"})
	result.append({"kind":"verify","id":"live"})
	return result
static func complete(controller:RefCounted,state:Dictionary,id:String)->bool:
	controller.dispatch(state,"c4_clock")
	var request:Dictionary=controller.dispatch(state,"c4_clock_begin")
	if not request.has("clock"):return false
	for event in events(id):
		var result:Dictionary=controller.dispatch(state,"c4_clock_event",{"session":request.clock.session,"event":event})
		if not result.get("accepted",false):return false
	controller.dispatch(state,"c4_clock_set",{"session":request.clock.session,"time":id})
	return state.chapter4.timeState==id
