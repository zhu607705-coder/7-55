extends SceneTree
## Isolated persistence + actual PhoneChrome composition. Not a campaign proof.
const Policy=preload("res://scripts/ui/phone_brightness_policy.gd")
const Chrome=preload("res://scripts/ui/phone_chrome.gd")
var checks:=0
var failures:=0
var state: Node
func _initialize() -> void: run.call_deferred()
func check(ok: bool, reason: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error("PHONE_BRIGHTNESS: "+reason)
func write_legacy(value: float) -> void:
	var snapshot: Dictionary=state.initial()
	snapshot.ui.brightness=value
	snapshot.phoneBattery.lowPowerMode=true
	snapshot.phoneBattery.rechargeCount=1
	var file:=FileAccess.open(state.SAVE_PATH,FileAccess.WRITE)
	file.store_string(JSON.stringify({"format":"7-55-godot-native","version":1,"sourceVersion":36,"state":snapshot}))
	file.close()
func run() -> void:
	if not preload("res://tests/native_test_isolation.gd").is_isolated_save(): quit(2); return
	state=root.get_node("State")
	state.developer_mode=true
	var initial: Dictionary=state.initial()
	check(initial.ui.brightness==65,"fresh opening preserves the original light puzzle")
	check(is_zero_approx(Policy.veil_alpha(65,"alarm")) and is_zero_approx(Policy.grade_strength(65)),"fresh65 is genuinely neutral, without dimmer or grade")
	check(is_equal_approx(Policy.veil_alpha(33,"phone_home"),(1-33.0/65)*.35),"saved33 uses calibrated lower range")
	check(is_equal_approx(Policy.veil_alpha(45,"phone_home"),(1-45.0/65)*.35),"saved45 uses calibrated lower range")
	for page: String in ["alarm","desktop"]:
		for value: float in [0,20,33,45,50,65,85]:
			check(is_equal_approx(Policy.veil_alpha(value,page),maxf(0,1-value/65.0)*.35),"opening uses the saved relative brightness without a hidden floor: "+page)
		check(is_zero_approx(Policy.veil_alpha(100,page)),"manual100 has no dimmer before composite grading")
	for page: String in ["phone_home","wechat","cc98","zjuding","tiyi","settings","bonsai","control_center","photos"]:
		var previous:=1.0
		for value: float in [0,20,33,45,50,85,100]:
			var alpha:=Policy.veil_alpha(value,page)
			check(alpha<=previous,"manual steps never darken as brightness rises on "+page)
			check(is_equal_approx(alpha,maxf(0,1-value/65.0)*0.35),"ordinary page uses exact calibrated mapping: "+page)
			previous=alpha
	check(Policy.veil_alpha(-100)==0.35 and Policy.veil_alpha(200)==0,"presentation clamps without unsafe color output")
	for value: float in [0,20,50,65,79,80,100]:
		check(is_equal_approx(Policy.grade_strength(value),clampf((value-65)/35,0,1)),"progressive upper range is exact")
		check(Policy.veil_alpha(value)==0 or Policy.grade_strength(value)==0,"never dim and relight the same composition")
	var chrome:=Chrome.new();root.add_child(chrome)
	for value: float in [0,20,33,45,50,100]:
		write_legacy(value)
		check(state.load_game() and state.d.ui.brightness==value,"Continue preserves ambiguous legacy/manual scalar "+str(value))
		check(state.d.phoneBattery.keys()==["percent"] and state.d.phoneBattery.percent==17,"old power metadata cannot affect display")
		for page: String in ["alarm","desktop","phone_home","settings","bonsai","photos"]:
			state.d.native.page=page
			for percent: int in [0,1,17,100]:
				state.d.phoneBattery.percent=percent
				var before: Dictionary=state.d.duplicate(true)
				chrome.refresh(state.d)
				check(is_equal_approx(chrome.brightness_veil.color.a,Policy.veil_alpha(value,page)),"actual chrome honors page calibration independent of battery")
				check(chrome.brightness_grade.visible==(value>65) and is_equal_approx(chrome.brightness_grade.strength,Policy.grade_strength(value)),"actual grade is bypassed at or below65")
				check(state.d==before,"rendering cannot alter saved preference, puzzle or battery")
		state.d.native.page="phone_home";state.d.currentScene="phone_home"
		state.developer_mode=false
		check(state.save_game() and state.load_game() and state.d.ui.brightness==value,"ordinary save/reload preserves manual scalar "+str(value))
		check(state.d.ui.brightnessRevision==1,"save round trip preserves the explicit brightness preference revision")
		state.developer_mode=true
	chrome.queue_free()
	await process_frame
	print("PHONE_BRIGHTNESS_POLICY: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
