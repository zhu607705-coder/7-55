extends RefCounted
## One runtime-only transient notice. No story, save, audio or surface authority.
var current: Dictionary={}
# Kept as an empty compatibility view for existing diagnostics. Authored story
# sequences belong to their own scheduler, never to this transient lane.
var pending: Array[Dictionary]=[]

func enqueue(text: String,speaker: String,duration: float,exact: bool=false) -> void:
	if text.strip_edges().is_empty(): return
	# Each new interaction replaces the previous result immediately, including
	# repeated text. Give the new result its own complete lifetime.
	duration=maxf(0,duration)
	pending.clear()
	current={"text":text,"speaker":speaker,"duration":duration,"remaining":duration,"elapsed":0.0,"exact":exact}

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
	current={}; pending.clear()

func discard(text: String) -> void:
	pending=pending.filter(func(item: Dictionary) -> bool: return item.text!=text)
	if current.get("text","")==text: finish()

func clear() -> void:
	current.clear(); pending.clear()
