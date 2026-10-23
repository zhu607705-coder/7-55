extends SceneTree
const Edges=preload("res://scripts/ui/pixel_edges.gd")
const Ui=preload("res://scripts/ui/native_ui_theme.gd")
const MaterialUi=preload("res://scripts/ui/campus_ui_material.gd")
const Specimen=preload("res://tests/ui_design_specimen.gd")
const Hardware=preload("res://scripts/ui/interaction_chrome.gd")
var checks:=0
var failures:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,message:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(message)
func run()->void:
	for panel:bool in [false,true]:
		var style:=StyleBoxFlat.new();style.content_margin_left=13;style.content_margin_right=17
		Edges.configure(style,panel)
		check(not style.anti_aliasing and style.corner_detail==2,"low-resolution corner profile")
		check(style.corner_radius_top_left==(6 if panel else 4),"shared role radius")
		check(style.content_margin_left==13 and style.content_margin_right==17,"edge profile cannot alter layout")
	for styles:Dictionary in [Ui.button_styles(Ui.PAPER,Ui.INK,Ui.INK),Ui.button_styles(Color("142a35"),Ui.PAPER,Ui.INK)]:
		for state:String in styles:
			var style:StyleBoxFlat=styles[state]
			check(style.corner_radius_top_left==4 and not style.anti_aliasing,"all button states share corner profile "+state)
	check(MaterialUi.panel_style().corner_radius_top_left==6,"paper uses shared panel profile")
	check(Hardware.style(Color.WHITE).corner_radius_top_left==4,"hardware uses control profile")
	for dimensions:Vector2 in [Vector2.ZERO,Vector2.ONE,Vector2(44,44),Vector2(366,180),Vector2(840,700)]:
		var rect:=Rect2(Vector2(12,18),dimensions)
		for piece:Rect2 in Edges.silhouette(rect):check(rect.encloses(piece),"integer silhouette stays inside bounds")
		if dimensions.x>=16:
			var pieces:=Edges.silhouette(rect)
			check(pieces.size()==3,"explicit silhouette has bounded integer steps")
			check(not pieces[0].has_point(rect.position) and not pieces[1].has_point(rect.position) and not pieces[2].has_point(rect.position),"hard outer corner removed without extending bounds")
	for dimensions:Vector2 in [Vector2(390,844),Vector2(1440,900)]:
		var host:=Control.new();host.size=dimensions;root.add_child(host)
		var specimen:=Specimen.new();host.add_child(specimen)
		await process_frame
		await process_frame
		var bounds:=Rect2(Vector2.ZERO,dimensions)
		for control:Node in specimen.find_children("*","Control",true,false):
			check(bounds.encloses(control.get_global_rect()),"production specimen component fits "+str(dimensions)+" "+str(control.name))
		host.free()
	print("Pixel edges: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
