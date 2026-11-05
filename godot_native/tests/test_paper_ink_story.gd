extends SceneTree
## Presentation scope and color regression. Synthetic input is not hardware proof.
const Ink=preload("res://scripts/ui/paper_ink_material.gd")
const TactileMaterial=preload("res://scripts/ui/tactile_button_material.gd")
const FlatMaterial=preload("res://scripts/ui/phone_flat_button_material.gd")
var checks:=0
var failures:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,note:String)->void:
	checks+=1
	if not ok:failures+=1;push_error("PAPER_INK_STORY: "+note)
func frames(n:int=5)->void:
	for i in n:await process_frame
func ratio(a:Color,b:Color)->float:
	var x:=a.srgb_to_linear();var y:=b.srgb_to_linear()
	var l1:=.2126*x.r+.7152*x.g+.0722*x.b;var l2:=.2126*y.r+.7152*y.g+.0722*y.b
	return (maxf(l1,l2)+.05)/(minf(l1,l2)+.05)
func run()->void:
	check(load("res://tests/native_test_isolation.gd").is_isolated_save(),"isolated user data")
	if failures:quit(1);return
	for fill:Color in [Ink.PAPER,Color("fff7df")]:
		check(ratio(Ink.INK,fill)>=4.5,"paper body text contrast")
		check(ratio(Ink.SOFT_INK,fill)>=4.5,"paper secondary text contrast")
		check(ratio(Ink.EDGE.lerp(Ink.GOLD,.3),fill)>=3,"hover pen edge remains visible")
		check(ratio(Ink.FOCUS,fill)>=3,"brick-red keyboard focus contrast")
	var paper:=Ink.panel_style(Vector2(18,12))
	check(paper.get_minimum_size()==Vector2(36,24),"fine pen does not change explicit panel insets")
	check(paper.border_width_left==1 and paper.corner_radius_top_left==2,"paper has one thin border and small corner")
	var scope:=Control.new();scope.set_meta("paper_ink_scope",true);root.add_child(scope)
	var nav:=Button.new();nav.text="返回";nav.position=Vector2(10,10);nav.size=Vector2(100,44);scope.add_child(nav)
	var icon:=Button.new();icon.text="";icon.set_meta("tactile_variant","ghost");icon.size=Vector2(44,44);scope.add_child(icon)
	var object:=Button.new();object.set_meta("tactile_exempt",true);object.size=Vector2(60,60);scope.add_child(object)
	var separate:=Button.new();separate.text="独立研究";root.add_child(separate)
	await frames()
	check(nav.get_theme_stylebox("normal").paper_ink,"late-created story navigation inherits scope")
	check(icon.get_theme_stylebox("normal").paper_ink and icon.get_theme_stylebox("normal").bg_color.a==0,"transparent icon keeps its existing artwork visible")
	check(object.get_node_or_null("TactileMaterialState")==null,"physical apparatus is never adopted")
	check(not separate.get_theme_stylebox("normal").paper_ink,"standalone research scene does not inherit story skin")
	check(nav.get_theme_stylebox("focus").border_color==Ink.FOCUS,"late-created navigation receives visible focus")
	scope.queue_free();separate.queue_free();await frames()
	var state:Node=root.get_node("State");state.d=state.initial();state.d.native.page="checkin";state.d.networkMode="campus_wifi";state.d.native.settings.volume=0
	var main:Control=load("res://scenes/main.tscn").instantiate();root.add_child(main);await frames(10)
	check(main.get_meta("paper_ink_scope",false),"real Main owns the presentation scope")
	var submit:Button=main.find_child("CheckinSubmit",true,false)
	check(submit!=null and submit.disabled and submit.get_theme_stylebox("normal") is FlatMaterial,"real check-in submit is both disabled and phone-flat")
	var zero:Control=main.find_child("CheckinSlotFrame_0",true,false)
	check(zero!=null and not zero.get_meta("paper_ink_surface",false) and zero.get_theme_stylebox("panel") is StyleBoxFlat and zero.get_theme_stylebox("panel").shadow_size==0,"real phone form slot retains its authored flat surface")
	var protected_inputs:int=0
	for button:Button in main.find_children("*","Button",true,false):
		var adapter:=button.get_node_or_null("TactileMaterialState")
		if adapter!=null:
			if adapter.phone_flat:
				check(adapter.material is FlatMaterial and button.get_meta("phone_button_material","")=="flat" and adapter.material.shadow_size==0,"phone-owned Main control retains its flat skin: "+str(button.name))
				protected_inputs+=1
			else:
				check(adapter.material is TactileMaterial and adapter.material.paper_ink,"non-phone Main control retains paper ink: "+str(button.name))
	check(protected_inputs>=12,"actual keypad and navigation audited, not detached specimens only")
	state.d.ui.controlCenterOpen=true;main._refresh_control_center();await frames()
	var network:Button=main.find_child("ControlNetwork_wifi",true,false)
	check(network!=null and network.get_meta("phone_button_role","")=="composite" and network.get_meta("phone_button_selected",false) and network.get_theme_stylebox("normal") is FlatMaterial,"selected network keeps its authored phone composite state")
	if network!=null:
		for mode:String in ["normal","hover","pressed","hover_pressed","disabled"]:
			var face:StyleBoxFlat=network.get_theme_stylebox(mode)
			for label_name:String in ["NetworkTitle","NetworkStatus"]:
				var label:Label=network.get_node(label_name)
				check(ratio(label.get_theme_color("font_color"),face.bg_color)>=4.5,"selected network child remains readable in "+mode+": "+label_name)
	var center:Control=main.find_child("ControlCenterPanel",true,false)
	check(center!=null and not center.get_meta("paper_ink_surface",false) and center.get_theme_stylebox("panel") is StyleBoxFlat and center.get_theme_stylebox("panel").shadow_size==0,"real control center keeps the shared flat phone overlay")
	state.d.ui.controlCenterOpen=false;main._refresh_control_center();await frames()
	main._show_journal();await frames()
	check(main.modal_panel.get_theme_stylebox("panel") is StyleBoxFlat and main.modal_panel.get_theme_stylebox("panel").shadow_size==0,"real task panel has a flat background for dark text")
	main._close_modal();await main.shutdown();main.queue_free();await frames()
	print("PAPER_INK_STORY: ",checks," checks; ",failures," failures");quit(1 if failures else 0)
