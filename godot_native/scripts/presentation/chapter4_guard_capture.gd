extends RefCounted
## Source ChapterFourGuardPresentation: one 5200ms caption, then owned resume.
const LINE="你在这里干什么？已经这么晚了，快点回去，要清楼了。"
const DISPLAY_MS=5200.0
var active:=false
var elapsed_ms:=0.0
var expected:Dictionary={}
var request:Dictionary={}
func begin(context:Dictionary,action:String,value:Dictionary={})->bool:
	if active or context.get("scene","")!="duan_yongping_temporal_maze":return false
	if action=="c4_recover_patrol":
		if context.get("phase","")!="maintenance_repair" or context.get("guardMode","")!="patrol":return false
	elif action=="c4_fail_chase":
		if context.get("phase","")!="final_chase" or context.get("guardMode","")!="chase":return false
	else:return false
	expected=context.duplicate(true);request={"action":action,"value":value.duplicate(true)};elapsed_ms=0;active=true;return true
func matches(context:Dictionary)->bool:
	return active and context==expected
func advance(delta_ms:float,context:Dictionary,running:bool=true)->Dictionary:
	if not active:return {}
	if not matches(context):cancel();return {}
	if not running or not is_finite(delta_ms):return {}
	elapsed_ms+=maxf(0,delta_ms)
	if elapsed_ms<DISPLAY_MS:return {}
	var result:=request.duplicate(true)
	active=false;request={};expected={};return result
func cancel():
	active=false;request={};expected={};elapsed_ms=0
