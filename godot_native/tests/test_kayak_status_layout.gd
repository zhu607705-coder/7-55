extends SceneTree
## Source-string layout fixtures; no gameplay outcome or earned-state claim.
const View=preload("res://scripts/ui/kayak_status_view.gd")
var checks:=0
var failures:=0
func _initialize() -> void:run.call_deferred()
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("KAYAK STATUS: "+label)
func painted_paddle(world:Control,side:String)->Rect2:
	# Read the actual rendered line/polygon, including the outline stroke.
	# The invisible touch padding may overlap a non-interactive status caption.
	var paddle:Node2D=world.kayak_visual.rig.get_node("BodyRoll/"+side.capitalize()+"Paddle")
	var shaft:Line2D=paddle.get_node("ShaftOutline")
	var transform:Transform2D=world.get_global_transform_with_canvas().affine_inverse()*shaft.get_global_transform_with_canvas()
	var area:=Rect2(transform*shaft.points[0],Vector2.ZERO)
	for point:Vector2 in shaft.points:area=area.expand(transform*point)
	area=area.grow(shaft.width*.5*maxf(transform.x.length(),transform.y.length()))
	var blade:Polygon2D=paddle.get_node("BladePivot/Blade")
	transform=world.get_global_transform_with_canvas().affine_inverse()*blade.get_global_transform_with_canvas()
	for point:Vector2 in blade.polygon:area=area.expand(transform*point)
	return area
func run() -> void:
	check(load("res://tests/native_test_isolation.gd").is_isolated_save(),"actual world geometry fixture uses an isolated save profile")
	if failures:quit(1);return
	var state:Node=root.get_node("State");state.developer_mode=true;state.d=state.initial()
	state.d.native.chapter=3;state.d.native.scene="qizhen_lake";state.d.native.page="c3_lake";state.d.native.mode="light";state.d.runtimeMode="rpg";state.d.rpgScene="qizhen_lake"
	state.d.qizhenLake.merge({"active":true,"phase":"tool_chain","zone":"open_water","vehicle":"kayak","boardingTutorialCompleted":true,"rainSafetyCleared":true,"kayakEquipped":true,"leftPaddleEquipped":true,"rightPaddleEquipped":true},true)
	var world:Control=load("res://scripts/world.gd").new();world.size=Vector2(960,540);root.add_child(world);world.set_process(false)
	var font: Font=load("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf")
	var content: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/source/chapter3-qizhen-lake.content.json"))
	var boarding: Dictionary=content.boarding
	var chase: Dictionary=content.chase
	var cases: Array=[]
	for mode: String in [boarding.forwardMode,boarding.reverseMode,boarding.reverseCoast]:
		for tilt: int in [0,70,100]:
			cases.append({"status":"%s · %s %d%%%s" % [mode,boarding.tilt,tilt," · "+boarding.capsizeWarning if tilt>=70 else ""],"alert":"","progress":""})
	for phase: String in chase.phaseLabels:
		for danger: String in chase.dangerLabels:
			for segment: String in chase.segmentLabels:
				cases.append({"status":"%s · %s 100%% · %s" % [boarding.reverseMode,boarding.tilt,boarding.capsizeWarning],"alert":"%s · %s · %s 230" % [chase.phaseLabels[phase],chase.dangerLabels[danger],chase.gapLabel],"progress":chase.segmentLabels[segment]+" 100%"})
	var views: Array=[{"size":Vector2(370,712),"scale":1.0,"header":44.0,"controls":true},{"size":Vector2(410,728),"scale":1.0,"header":44.0,"controls":true},{"size":Vector2(824,314),"scale":1.0,"header":44.0,"controls":true},{"size":Vector2(528,314),"scale":1.0,"header":44.0,"controls":true},{"size":Vector2(370,628),"scale":1.0,"header":44.0,"controls":true},{"size":Vector2(960,540),"scale":1.1795,"header":38.0,"controls":false},{"size":Vector2(300,436),"scale":1.0,"header":44.0,"controls":true}]
	var reported:Dictionary={}
	for viewport: Dictionary in views:
		world.size=viewport.size;world.mobile_exploration=viewport.controls;world._update_camera()
		var paddles:Dictionary=world.kayak_paddle_rects()
		check(paddles.size()==2,"status fixture contains both actual rig paddles at "+str(viewport.size))
		var painted:Dictionary={"left":painted_paddle(world,"left"),"right":painted_paddle(world,"right")}
		for hit:Rect2 in paddles.values():check(hit.size.x*viewport.scale>=28 and hit.size.y*viewport.scale>=28,"real moving paddle keeps its physical input target floor")
		for sample: Dictionary in cases:
			var before: String=JSON.stringify(sample)
			var m: Dictionary=View.layout(font,viewport.size,viewport.scale,viewport.header,sample.status,sample.alert,sample.progress)
			check(Rect2(Vector2.ZERO,viewport.size).encloses(m.panel),"panel inside "+str(viewport.size))
			check(m.panel.position.y>=viewport.header+5/viewport.scale,"panel stays below original header")
			check(m.font_size*viewport.scale>=14,"physical text floor retained")
			var text: String=""
			var previous_bottom: float=m.panel.position.y
			for row: Dictionary in m.rows:
				check(m.panel.encloses(row.rect),"whole row inside panel")
				check(row.rect.position.y>=previous_bottom,"rows never overprint one another")
				var measured: Vector2=font.get_multiline_string_size(row.display_text,HORIZONTAL_ALIGNMENT_LEFT,row.rect.size.x,m.font_size)
				check(measured.x<=row.rect.size.x+.01 and measured.y<=row.rect.size.y+.01,"all glyphs fit without ellipsis")
				for phrase: String in row.text.split(" · "):
					check(row.display_text.contains(phrase),"source phrase remains intact across measured row breaks")
				text+=row.text;previous_bottom=row.rect.end.y
			check(text.contains(sample.status) and (sample.alert.is_empty() or text.contains(sample.alert)) and (sample.progress.is_empty() or text.contains(sample.progress)),"every original dynamic phrase/value remains present")
			if not sample.alert.is_empty():
				check(m.panel.encloses(m.risk_bar) and m.risk_bar.position.y>previous_bottom,"risk bar follows full text")
			if viewport.controls:
				if (m.panel.intersects(painted.left) or m.panel.intersects(painted.right)) and not reported.has(viewport.size):
					reported[viewport.size]=true;print("STATUS_PADDLE_OVERLAP ",JSON.stringify({"viewport":viewport.size,"panel":m.panel,"paddles":painted,"sourceText":sample}))
				check(not m.panel.intersects(painted.left) and not m.panel.intersects(painted.right),"panel does not cover either actual painted paddle")
			check(JSON.stringify(sample)==before,"layout never changes source status data")
	world.free();await process_frame
	print("KAYAK_STATUS_LAYOUT: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
