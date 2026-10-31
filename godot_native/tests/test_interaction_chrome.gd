extends SceneTree
const Hardware=preload("res://scripts/ui/interaction_chrome.gd")
var checks:=0
var failures:=0
func check(ok:bool,message:String)->void:
	checks+=1
	if not ok:failures+=1;push_error("INTERACTION CHROME: "+message)
func _initialize()->void:run.call_deferred()
func run()->void:
	for fill:Color in [Hardware.PAPER,Hardware.TRAY]:
		var button:=Button.new();button.size=Vector2(76,30);button.position=Vector2(174,5);button.disabled=true
		root.add_child(button)
		var before:=button.get_rect()
		Hardware.apply_states(button,Hardware.style(fill),Hardware.style(fill.lightened(.08),Hardware.CORAL))
		check(button.disabled,"styles preserve disabled authority")
		check(button.get_rect()==before,"styles preserve exact control rectangle")
		for role:String in ["normal","hover","pressed","hover_pressed","disabled","focus"]:
			check(button.has_theme_stylebox_override(role),"explicit complete state "+role)
			var style:StyleBox=button.get_theme_stylebox(role)
			check(style.content_margin_left==0 and style.content_margin_top==0,"state does not shift children "+role)
		check(button.get_theme_stylebox("pressed").bg_color!=button.get_theme_stylebox("hover").bg_color,"pressed distinct from hover")
		check(button.get_theme_stylebox("disabled").bg_color!=button.get_theme_stylebox("normal").bg_color,"blocked affordance distinct")
		check(button.get_theme_stylebox("focus").bg_color.a==0 and button.get_theme_stylebox("focus").border_width_left==2,"focus outline never hides selected material")
		Hardware.set_selected(button,true)
		var marker:Control=button.get_node("HardwareDetail")
		check(marker.mouse_filter==Control.MOUSE_FILTER_IGNORE and marker.focus_mode==Control.FOCUS_NONE,"material detail cannot intercept mouse/touch/keyboard")
		check(marker.selected,"selection detail exists")
		Hardware.set_selected(button,false)
		check(not marker.selected,"selection clears without reparenting control")
		check(button.get_rect()==before,"selection leaves hit rectangle unchanged")
		button.free()
	print("INTERACTION_CHROME: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
