extends RefCounted
## Dimensionless teaching dynamics, NOT a calibrated vehicle prediction.
## P_e=12*A*I*cos(beta-alpha); P_m<=.65*P_e; tau=4*P_m/80*(1-omega/80).
## Implicit midpoint enforces delta kinetic energy + resistance work = motor work.
const AREAS:=[1.0,1.65]
const MASSES:=[.4,1.1]
const TILTS:=[0.0,30.0,60.0]
const RATIOS:=[1.0,1.6,2.4]
const DT:=.05
const DURATION:=30.0
var panel:=0
var tilt:=0
var gear:=2
var scenario:=0
var revision:=0
var trial_revision:=-1
var on_track:=false
var running:=false
var ticks:=0
var accumulator:=0.0
var completed:=false
var extension_completed:=false
var cars:Array[Dictionary]=[]
var segments:Array[Dictionary]=[]
var records:Array[Dictionary]=[]
var personal_best:Array[float]=[0.0,0.0]
var outcome:=""
func _init()->void:_reset_cars()
func _reset_cars()->void:
	cars=[]
	for i:int in 2:cars.append({"v":0.0,"distance":0.0,"electrical_energy":0.0,"mechanical_energy":0.0,"peak_power_fraction":0.0,"energy_error":0.0})
func time()->float:return ticks*DT
func light_angle()->float:return 30.0 if scenario==0 else 60.0
func shadow_end()->float:return 16.0 if scenario==0 else 18.0
func irradiance(at:float)->float:
	if at>=10 and at<shadow_end():return .2 if scenario==0 else .15
	return 1.0 if scenario==0 else .8
func configuration()->Array[int]:return [panel,tilt,gear]
func baseline()->Array[int]:return [0,0,2] if scenario==0 else [0,1,1]
func cancel()->void:running=false;accumulator=0
func _changed()->void:
	cancel();revision+=1;trial_revision=-1;ticks=0;segments.clear();_reset_cars();outcome=""
func edit(part:String,value:int)->bool:
	if part=="panel" and value in [-1,0,1]:
		if panel==value:return true
		panel=value
	elif part=="tilt" and value in [0,1,2]:
		if tilt==value:return true
		tilt=value
	elif part=="gear" and value in [-1,0,1,2]:
		if gear==value:return true
		gear=value
	else:return false
	_changed();on_track=false;return true
func set_scenario(value:int)->bool:
	if value not in [0,1]:return false
	if scenario==value:return true
	scenario=value;_changed();return true
func place_on_track(value:bool)->void:
	cancel();on_track=value
	if value:_reset_cars();ticks=0;segments.clear()
func start()->bool:
	if running or not on_track or panel<0 or gear<0:return false
	_reset_cars();segments.clear();ticks=0;accumulator=0;trial_revision=revision;running=true;outcome="";return true
func forces(speed:float,area:float,mass:float,ratio:float,budget:float)->Vector3:
	var omega:=speed*ratio/.1
	var torque:float=4*budget/80*maxf(0,1-omega/80)
	return Vector3(torque*ratio/.1,.18*mass*9.81+(.05+.1*area)*speed*speed,torque*omega)
func advance_car(state:Dictionary,config:Array,light:float)->void:
	var area:float=AREAS[config[0]];var mass:float=.8+MASSES[config[0]];var ratio:float=RATIOS[config[2]]
	var electrical:float=12*area*light*maxf(0,cos(deg_to_rad(TILTS[config[1]]-light_angle())))
	var budget:=.65*electrical
	var speed:float=state.v
	var next:=0.0;var moving_dt:=DT
	var f:=forces(speed*.5,area,mass,ratio,budget)
	if speed>0 and speed-DT*(f.y-f.x)/mass<0:moving_dt=mass*speed/(f.y-f.x)
	elif speed==0 and forces(0,area,mass,ratio,budget).x<=forces(0,area,mass,ratio,budget).y:moving_dt=0
	else:
		var lo:=0.0;var hi:=maxf(speed,80*.1/ratio)+1
		for i:int in 42:
			var mid:float=(lo+hi)*.5
			f=forces((speed+mid)*.5,area,mass,ratio,budget)
			if mid-speed-DT*(f.x-f.y)/mass>0:hi=mid
			else:lo=mid
		next=(lo+hi)*.5
	var midpoint:float=(speed+next)*.5
	f=forces(midpoint,area,mass,ratio,budget)
	var distance:=midpoint*moving_dt
	state.distance+=distance;state.v=next
	state.electrical_energy+=electrical*DT;state.mechanical_energy+=f.z*moving_dt
	state.peak_power_fraction=maxf(state.peak_power_fraction,f.z/budget if budget>0 else 0)
	state.energy_error=maxf(state.energy_error,absf(.5*mass*(next*next-speed*speed)+f.y*distance-f.z*moving_dt))
func step(dt:float)->void:
	if not running or not is_finite(dt) or dt<=0:return
	accumulator+=dt
	while accumulator+1e-9>=DT and running:
		accumulator-=DT
		var light:=irradiance(time())
		advance_car(cars[0],configuration(),light);advance_car(cars[1],baseline(),light)
		ticks+=1
		if ticks in [20,200,int(shadow_end()/DT),600]:segments.append({"time":time(),"player":cars[0].distance,"baseline":cars[1].distance})
		if ticks>=600:
			running=false;accumulator=0
			if trial_revision!=revision:return
			var won:bool=cars[0].distance>cars[1].distance+1e-6
			completed=completed or won
			if scenario==1:extension_completed=extension_completed or won
			personal_best[scenario]=maxf(personal_best[scenario],cars[0].distance)
			records.append({"scenario":scenario,"configuration":configuration(),"revision":revision,"cars":cars.duplicate(true),"segments":segments.duplicate(true),"won":won})
			if records.size()>12:records.pop_front()
			outcome="本场距离领先" if won else "本场到站，轨迹已保留"
