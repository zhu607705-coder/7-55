extends RefCounted
## The three reversible paper strips are controller-owned, including failed drafts.
const IDS=["classroom_104","classroom_105","main_elevator"]
const EDGES={"classroom_104":[70,210],"classroom_105":[210,120],"main_elevator":[120,260]}
static func initial()->Dictionary:
	return {"version":1,"order":["main_elevator","classroom_104","classroom_105"],"backs":{"classroom_104":true,"classroom_105":false,"main_elevator":true}}
static func valid(value:Variant)->bool:
	if not value is Dictionary or value.size()!=3 or value.get("version")!=1 or not value.get("order") is Array or value.order.size()!=3 or not value.get("backs") is Dictionary or value.backs.size()!=3:return false
	for id:String in IDS:
		if value.order.count(id)!=1 or not value.backs.get(id) is bool:return false
	return true
static func endpoints(value:Dictionary,id:String)->Array:
	var pair:Array=EDGES[id].duplicate()
	if value.backs[id]:pair=[320-pair[0],320-pair[1]]
	return pair
static func connected(value:Dictionary)->bool:
	if not valid(value):return false
	var last:=70
	for id:String in value.order:
		var edges:Array=endpoints(value,id)
		if edges[0]!=last:return false
		last=int(edges[1])
	return last==260
static func transition(value:Dictionary,event:Variant)->Dictionary:
	if not valid(value) or not event is Dictionary:return {}
	var next:Dictionary=value.duplicate(true)
	match event.get("kind",""):
		"swap":
			if event.size()!=3 or event.get("a") not in IDS or event.get("b") not in IDS or event.a==event.b:return {}
			var a:int=next.order.find(event.a);var b:int=next.order.find(event.b)
			next.order[a]=event.b;next.order[b]=event.a
		"flip":
			if event.size()!=2 or event.get("id") not in IDS:return {}
			next.backs[event.id]=not next.backs[event.id]
		_:return {}
	return next
