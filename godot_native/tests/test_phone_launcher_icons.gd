extends SceneTree
const Pages=preload("res://scripts/ui/phone_pages.gd")
const Utilities=preload("res://scripts/chapters/phone_utilities.gd")
const Icons=preload("res://scripts/ui/phone_launcher_icons.gd")
var checks:=0
var failures:=0
var route:=""
var pages:=Pages.new()
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func key(code:Key)->void:
	for down:bool in [true,false]:
		var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=down;root.push_input(event)
	await process_frame
func run()->void:
	root.size=Vector2i(500,1000)
	pages.page_requested.connect(func(id:String):route=id)
	for interlude:bool in [false,true]:
		var state:Dictionary=root.get_node("State").initial()
		state.actOne.phase="complete"
		state.ui.libraryFinalsPuzzle.backpackInspected=true;state.ui.libraryFinalsPuzzle.investigationOpened=true
		if interlude:state.qizhenLake.phase="complete"
		var home:Control=pages.build("phone_home",{},state);root.add_child(home)
		await process_frame;await process_frame
		var expected:Array=[]
		for id:String in Utilities.APP_IDS:
			if Utilities.app_available(state,id):expected.append(id)
		check(home.find_child("HomeApp_settings",true,false).get_parent().get_meta("home_visible_app_ids")==expected,"exact authored available launcher count/order, no new notes/map route")
		for id:String in expected:
			var button:Button=home.find_child("HomeApp_"+id,true,false)
			var glyph:TextureRect=button.get_node("LauncherGlyph")
			var focus_name:Label=home.find_child("LauncherFocusName_"+id,true,false)
			check(button.text.is_empty() and not focus_name.visible,"icon-only entry has no permanent text")
			check(glyph.texture!=null and glyph.texture.resource_path.ends_with(str(Icons.FILES[id])+".svg"),"real original vector matches actual app semantic")
			check(glyph.size.is_equal_approx(Vector2(24,24)) and button.size.is_equal_approx(Vector2(48,48)),"24px icon keeps original48px hit target: "+id+str(glyph.size)+str(button.size))
			check(button.tooltip_text==Utilities.LABELS[id] and button.accessibility_name==Utilities.LABELS[id],"tooltip and accessible name preserve real app title")
			button.grab_focus();await process_frame
			check(focus_name.visible and root.gui_get_focus_owner()==button,"keyboard focus reveals the app name")
			var expected_route:String={"timeline_recovery":"c35_recovery","voice_memos":"c35_voice"}.get(id,id)
			route="";await key(KEY_ENTER)
			check(route==expected_route,"keyboard activation preserves original route "+id)
			button.release_focus();await process_frame
			check(not focus_name.visible,"focus-only name retires after focus leaves")
			route=""
			var point:Vector2=button.get_global_rect().get_center()
			var motion:=InputEventMouseMotion.new();motion.position=point;motion.global_position=point;root.push_input(motion)
			for down:bool in [true,false]:
				var event:=InputEventMouseButton.new();event.position=point;event.global_position=point;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down;root.push_input(event)
			await process_frame
			check(route==expected_route,"mouse activation preserves original route "+id)
			button.release_focus();await process_frame
		home.free()
	print("PHONE_LAUNCHER_ICONS: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
