extends SceneTree
## Source-string layout fixtures; no gameplay outcome or earned-state claim.
const View=preload("res://scripts/ui/kayak_status_view.gd")
var checks:=0
var failures:=0
func _initialize() -> void:run.call_deferred()
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("KAYAK STATUS: "+label)
func run() -> void:
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
	for viewport: Dictionary in views:
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
				check(not m.panel.intersects(Rect2(70,viewport.size.y-176,100,92)) and not m.panel.intersects(Rect2(viewport.size.x-170,viewport.size.y-176,100,92)),"panel does not cover either painted paddle")
			check(JSON.stringify(sample)==before,"layout never changes source status data")
	print("KAYAK_STATUS_LAYOUT: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
