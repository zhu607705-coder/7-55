extends RefCounted
## Runtime-only reading order. No story, save, audio or surface authority.
var current: Dictionary={}
var pending: Array[Dictionary]=[]

func enqueue(text: String,speaker: String,duration: float,exact: bool=false) -> void:
	if text.strip_edges().is_empty(): return
	if current.get("text","")==text:
		if exact:
			current.duration=duration
			current.remaining=maxf(0,duration-float(current.elapsed))
			current.speaker=speaker
			current.exact=true
		return
	for item: Dictionary in pending:
		if item.text!=text: continue
		if exact: item.duration=duration; item.remaining=duration; item.speaker=speaker; item.exact=true
		return
	var item: Dictionary={"text":text,"speaker":speaker,"duration":duration,"remaining":duration,"elapsed":0.0,"exact":exact}
	if current.is_empty(): current=item
	else: pending.append(item)

func advance(delta: float) -> void:
	if current.is_empty(): return
	current.elapsed+=maxf(0,delta)
	current.remaining=maxf(0,float(current.remaining)-maxf(0,delta))
	if current.remaining<=0: finish()

func sync_remaining(value: float) -> void:
	if current.is_empty(): return
	current.remaining=maxf(0,minf(float(current.remaining),value))
	current.elapsed=maxf(float(current.elapsed),float(current.duration)-float(current.remaining))

func finish() -> void:
	current=pending.pop_front() if not pending.is_empty() else {}

func discard(text: String) -> void:
	pending=pending.filter(func(item: Dictionary) -> bool: return item.text!=text)
	if current.get("text","")==text: finish()

func clear() -> void:
	current.clear(); pending.clear()
