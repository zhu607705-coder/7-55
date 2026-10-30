extends RefCounted
## Isolated teaching experiment, never a chapter/save/inventory authority.
const RADII:=[28.0,44.0,58.0]
var gear:=-1
var belt:=0 # 0 absent, 1 open belt, 2 crossed belt
var tension:=0 # loose / seated / overtight
var running:=false
var outcome:=""
var elapsed:=0.0
var motor_phase:=0.0
var gear_phase:=0.0
var output_phase:=0.0
var travel:=.12
var history:Array[Dictionary]=[]

func reset()->void:
	gear=-1;belt=0;tension=0;running=false;outcome="";elapsed=0
	motor_phase=0;gear_phase=0;output_phase=0;travel=.12
func cancel()->void:running=false
func edit(part:String,value:int)->bool:
	if part not in ["gear","belt","tension"] or value<0 or value>2:return false
	history.append({"gear":gear,"belt":belt,"tension":tension})
	if history.size()>32:history.pop_front()
	if part=="gear" and value in [0,1,2]:gear=value
	elif part=="belt" and value in [0,1,2]:belt=value
	elif part=="tension" and value in [0,1,2]:tension=value
	else:return false
	running=false;outcome="";elapsed=0;travel=.12
	return true
func undo()->bool:
	if history.is_empty():return false
	var previous:Dictionary=history.pop_back()
	gear=previous.gear;belt=previous.belt;tension=previous.tension
	return_to_start();return true
func return_to_start()->void:
	running=false;outcome="";elapsed=0;travel=.12;motor_phase=0;gear_phase=0;output_phase=0
func diagnosis()->String:
	if gear<0:return "missing_gear"
	if gear==0:return "gear_small"
	if gear==2:return "gear_large"
	if belt==0:return "missing_belt"
	if tension==0:return "slack"
	if tension==2:return "tight"
	if belt==1:return "reverse"
	return "passed"
func start()->bool:
	if running:return false
	running=true;elapsed=0;outcome="";travel=.12
	return true
func step(dt:float)->void:
	if not running or dt<=0 or not is_finite(dt):return
	var verdict:=diagnosis()
	var duration:=3.0 if verdict=="passed" else 1.4
	var advance:=minf(dt,duration-elapsed)
	elapsed+=advance
	if verdict not in ["gear_large","tight"]:motor_phase+=advance*3.6
	if gear==1 and verdict!="tight":gear_phase-=advance*3.6
	if gear==1 and belt>0 and tension==1:
		var sign_value:=1.0 if belt==2 else -1.0
		output_phase+=advance*3.6*sign_value
		travel=clampf(.12+elapsed*(.8/3.0)*sign_value,0,.92)
	if elapsed>=duration-.0001:running=false;outcome=verdict
func message()->String:
	if running:return "观察齿轮、皮带和送料块，看看动力停在了哪里。"
	return {"":"把零件盘里的齿轮装到中间轴位，再按开关试转。","missing_gear":"电机空转：中间轴上还没有齿轮。","gear_small":"齿轮间留着空隙，动力没有接过去。","gear_large":"两枚齿轮顶住了，轴转不起来。","missing_belt":"齿轮已经在转，右侧送料轴还没有接上。","slack":"皮带打滑了：轮子转，送料块却没动。","tight":"皮带绷得太紧，传动被卡住了。","reverse":"送料块向左退了，观察两端轮子的转向。","passed":"试件到达右侧刻线，传动试验通过。"}.get(outcome,"")
