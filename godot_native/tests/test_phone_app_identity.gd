extends SceneTree
const Candidate=preload("res://scripts/ui/phone_pages.gd")
var expected_cases: Array=[]
var fixture_index:=0
const Ui=preload("res://scripts/ui/native_ui_theme.gd")
var checks:=0
var failures:=0
var report:Array=[]
func _initialize():run.call_deferred()
func check(ok:bool,message:String):
	checks+=1
	if not ok:failures+=1;push_error(message)
func labels(node:Control)->Array:
	var text:Array=[]
	for child in node.find_children("*","Label",true,false):text.append(child.text)
	return text
func buttons(node:Control)->Array:
	var result:Array=[]
	for child in node.find_children("*","Button",true,false):result.append({"name":str(child.name),"text":child.text,"disabled":child.disabled,"tooltip":child.tooltip_text,"rect":str(child.get_rect())})
	return result
func lum(color:Color)->float:
	var c=color.srgb_to_linear();return .2126*c.r+.7152*c.g+.0722*c.b
func frames():
	for i in 3:await process_frame
func fixture(kind:String,state:Dictionary,view:Dictionary={},presence_audit:bool=false):
	var b=Candidate.new();b.s=state.duplicate(true)
	var expected: Dictionary=expected_cases[fixture_index];fixture_index+=1
	b.s.native.page="tiyi" if kind=="tiyi" else "weather"
	b.entry_session.route(b.s);b.entry_session.advance(1400)
	var before=JSON.stringify(b.s)
	var fresh:Control=b._weather() if kind=="weather" else b._tiyi(view)
	var holder=Control.new();holder.theme=Ui.make_theme(load("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf"));root.add_child(holder);holder.add_child(fresh)
	await frames()
	check(expected.labels==labels(fresh),kind+" retains exact authored Label text")
	var ab=expected.buttons;var bb=buttons(fresh)
	for list in [ab,bb]:
		for item in list:
			# Anonymous nav names vary by global instance sequence.
			if item.name.begins_with("@"):item.name="anonymous"
	check(ab==bb,kind+" retains every button text/disabled/tooltip/rect")
	check(expected.actions==b.handled,kind+" retains handled action IDs")
	if presence_audit:
		check_presence_identity(fresh)
		# JSON numbers decode as float; this intent's native contract is integer.
		for event in expected.emissions:
			if event[0]=="lib_audit_value":event[1].value=int(event[1].value)
	for button in fresh.find_children("*","Button",true,false):
		if button.name=="TiyiExercise":
			for mode in ["normal","hover","pressed","hover_pressed","disabled"]:
				var fill:Color=button.get_theme_stylebox(mode).bg_color
				check(1.05/(lum(fill)+.05)>=4.5,"Tiyi white label contrast "+mode)
	var emissions:Array=[];b.action_requested.connect(func(id,value):emissions.append([id,value]))
	for button in fresh.find_children("*","Button",true,false):
		if button.name in ["WeatherWaterCard","TiyiCount47","TiyiExercise"] and not button.disabled:button.pressed.emit()
	if presence_audit:
		fresh.find_child("TiyiPresenceSubmit",true,false).pressed.emit()
		for field in ["arrival","notice","proofs"]:
			fresh.find_child("TiyiPlus_"+field,true,false).pressed.emit()
		fresh.find_child("TiyiPresenceSubmit",true,false).pressed.emit()
		var destinations:Array=[];b.page_requested.connect(func(page):destinations.append(page))
		fresh.find_child("PhoneNav_exit",true,false).pressed.emit()
		check(destinations==["phone_home"],"presence form exit uses the original phone-home intent")
	check(JSON.stringify(b.s)==before,kind+" builder and callbacks leave story state unchanged")
	check(expected.emissions==emissions,kind+" retains original action payloads")
	var frameset=[]
	for dims in [Vector2(390,844),Vector2(430,860),Vector2(1280,900)]:
		var phone_scale=minf(minf(1.0,(dims.y-36)/860.0),(dims.x-36)/430.0)
		var full_scale=phone_scale*424.0/378.0
		var entry={"viewport":str(dims),"outerScale":phone_scale,"pageScale":full_scale,"authoredSize":str(fresh.size),"physicalWidth":fresh.size.x*full_scale}
		check(is_equal_approx(fresh.size.x,378.0),kind+" canonical authored width")
		if kind=="weather":
			var icon=fresh.find_child("WeatherConditionIcon",true,false)
			check(icon!=null and icon.kind==("cloud" if state.qizhenLake.rainSafetyCleared else "rain"),"condition icon matches story weather")
			entry.iconSize=str(icon.size*full_scale)
		frameset.append(entry)
	var metrics=[]
	for label in fresh.find_children("*","Label",true,false):
		metrics.append({"text":label.text,"fontSize":label.get_theme_font_size("font_size"),"rect":str(label.get_rect()),"minimumHeight":label.get_minimum_size().y})
	report.append({"labels":metrics,"kind":kind,"view":view,"actions":b.handled,"emissions":emissions,"buttons":bb,"geometry":frameset})
	holder.queue_free();await frames()
func check_presence_identity(form:Control):
	check(form.name=="TiyiPresenceForm" and labels(form).has("浙大体艺"),"library fixture mounts the branded inline presence form")
	check(form.find_child("TiyiCount47",true,false)==null and form.find_child("TiyiExercise",true,false)==null,"presence form never substitutes the prologue or movement action")
	check(form.find_child("TiyiRecordedRoute",true,false).text=="寝室 → 图书馆入口 → 022","presence form shows only recorded source route points")
	for field in [["arrival","5","到座耗时（分钟）"],["notice","45","公示编号（号）"],["proofs","1","证明数量（项）"]]:
		var input=form.find_child("TiyiField_"+field[0],true,false)
		check(input is LineEdit and input.text==field[1] and input.editable and input.tooltip_text==field[2],"source field and wrong default: "+field[0])
		check(input.get_rect().end.y<=Candidate.APP_HEIGHT and input.size.y>=28,"source field remains in the first app viewport: "+field[0])
	var submit=form.find_child("TiyiPresenceSubmit",true,false)
	check(submit is Button and submit.text=="提交补录" and not submit.disabled and submit.get_rect().end.y<=Candidate.APP_HEIGHT,"source-ready inline submit is visible and enabled")
	for mode in ["normal","hover","pressed","hover_pressed","disabled"]:
		check(1.05/(lum(submit.get_theme_stylebox(mode).bg_color)+.05)>=4.5,"presence submit white label contrast "+mode)
	for source in [[0,"07:55 基础馆入口 → 08:02 一层书库 022\n填写两次记录的分钟差"],[1,"楼主编辑原文：旧申请统一挂在公示编号 47\n23 是回复楼层；填写原文中的公示编号"],[2,"本人确实到馆；目标座位与凭据一致；当前占用物不具备本人身份。\n填写规则列出的证明类别数量"]]:
		check(form.find_child("TiyiEvidence_"+str(source[0]),true,false).text==source[1],"source evidence text stays exact: "+str(source[0]))
func run():
	expected_cases=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/phone-app-identity-contract.json")).cases
	var state=root.get_node("State");state.developer_mode=true
	for rain in [true,false]:
		for water_state in range(3):
			var s=state.initial();s.qizhenLake.rainSafetyCleared=not rain;s.actOne.exerciseStarted=water_state>0;s.actOne.weatherWaterTaken=water_state==2
			await fixture("weather",s)
	for available in [false,true]:
		for complete in [false,true]:
			var lake=state.initial();lake.qizhenLake.active=true;lake.qizhenLake.phase="rain_recovery";lake.qizhenLake.rainRescueCompleted=true;lake.qizhenLake.weatherAdjustmentRequested=available;lake.items.hairDryer=available;lake.qizhenLake.rainSafetyCleared=complete
			await fixture("weather",lake)
	for phase in ["prologue","movement_required"]:
		for started in [false,true]:
			var s=state.initial();s.networkMode="cellular";s.actOne.phase=phase;s.actOne.exerciseStarted=started
			await fixture("tiyi",s)
	var s=state.initial();s.networkMode="cellular";s.native.chapter=2;s.actOne.phase="complete"
	s.ui.libraryFinalsPhase="evidence_gathering"
	var puzzle:Dictionary=s.ui.libraryFinalsPuzzle
	puzzle.investigationOpened=true;puzzle.entranceRecordRead=true;puzzle.archivedRuleRead=true;puzzle.archivedRuleBriefingSeen=true
	puzzle.libraryVisitedPoints=["entrance","seat_022"]
	var source_view=load("res://scripts/chapters/library022.gd").new().view("tiyi",s)
	await fixture("tiyi",s,source_view,true)
	var f=FileAccess.open("user://phone-app-identity-report.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"cases":report},"\t"));f.close()
	print("APP_IDENTITY_PROBE: ",checks," checks; ",failures," failures");quit(1 if failures else 0)
