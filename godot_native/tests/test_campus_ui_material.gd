extends SceneTree
const UiMaterial = preload("res://scripts/ui/campus_ui_material.gd")
const PaperPanel = preload("res://scripts/ui/campus_paper_panel.gd")
var checks := 0
var failures := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func run() -> void:
	for kind: String in UiMaterial.KINDS:
		for dimensions: Vector2 in [Vector2.ZERO,Vector2(1,1),Vector2(24,12),Vector2(64,44),Vector2(180,48),Vector2(366,620),Vector2(580,700)]:
			for header_height: float in [0,32,80]:
				var rect := Rect2(Vector2(7.5,11.25),dimensions)
				var geo := UiMaterial.geometry(rect,kind,header_height)
				check(geo.bounds==rect,"bounds never expanded")
				check(geo.body.size.x>=0 and geo.body.size.y>=0,"nonnegative content extent")
				check(rect.encloses(geo.body),"body stays inside supplied rect")
				check(not geo.body.intersects(geo.header),"header never obscures body")
				check(rect.encloses(geo.index),"page index stays within supplied rect")
				check(not geo.heading.intersects(geo.index),"optional page index has its own text region")
				var marks := UiMaterial.commands(rect,kind,{},header_height)
				check(marks==UiMaterial.commands(rect,kind,{},header_height),"deterministic draw commands")
				check(marks.size()<=16,"detail budget remains bounded")
				for mark: Dictionary in marks:
					check(rect.encloses(mark.rect),"decoration never exceeds bounds")
					if mark.decoration: check(not geo.body.intersects(mark.rect),"decoration leaves body clear")
		var min_size := UiMaterial.minimum_size(kind,32)
		var minimum := UiMaterial.geometry(Rect2(Vector2.ZERO,min_size),kind,32)
		check(minimum.body.size.x>=32 and minimum.body.size.y>=20,"minimum retains usable body")
		var style := UiMaterial.panel_style(kind,{},Vector2(18,12))
		check(style.get_content_margin(SIDE_LEFT)==18 and style.get_content_margin(SIDE_BOTTOM)==12,"container padding exact")
		check(style.shadow_size==0,"no unmeasured outward shadow")
	var customized := UiMaterial.palette({"accent":Color("ff0000"),"paper":"invalid","unknown":Color.BLUE})
	check(customized.accent==Color("ff0000"),"caller palette supported")
	check(customized.paper==UiMaterial.PAPER,"invalid color ignored")
	check(not customized.has("unknown"),"unknown palettes cannot change geometry")
	check(UiMaterial.commands(Rect2(0,0,-10,12)).is_empty(),"negative extent draws nothing")
	var panel := PaperPanel.new()
	var style := UiMaterial.panel_style("paper",{},Vector2(15,15))
	panel.add_theme_stylebox_override("panel",style)
	root.add_child(panel)
	var body := Label.new(); body.text="现场记录"; panel.add_child(body)
	await process_frame
	check(panel.get_combined_minimum_size()==body.get_combined_minimum_size()+Vector2(30,30),"material decoration adds no layout extent")
	style=style.duplicate(); style.border_width_left=5; style.border_color=Color("24677c")
	panel.add_theme_stylebox_override("panel",style)
	await process_frame
	check(panel.get_theme_stylebox("panel").border_width_left==5,"evidence selection border retained")
	check(panel.get_theme_stylebox("panel").border_color==Color("24677c"),"evidence state color retained")
	panel.free()
	print("Campus UI material: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
