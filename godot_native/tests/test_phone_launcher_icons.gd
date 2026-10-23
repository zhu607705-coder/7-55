extends SceneTree
const Pages=preload("res://scripts/ui/phone_pages.gd")
const Utilities=preload("res://scripts/chapters/phone_utilities.gd")
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
			var artwork:Control=button.get_node("OriginalAppArtwork_"+id)
			var name_label:Label=home.find_child("OriginalAppName_"+id,true,false)
			check(artwork!=null and button.get_node_or_null("LauncherGlyph")==null,"original app artwork replaces the upstream outline glyph")
			check(name_label.visible and name_label.text==Utilities.LABELS[id],"original application label remains visible")
			check(artwork.size.is_equal_approx(Vector2(48,48)) and button.size.is_equal_approx(Vector2(48,48)),"original48px artwork and hit frame remain aligned "+id+" art="+str(artwork.size)+" button="+str(button.size))
			check(button.tooltip_text==Utilities.LABELS[id] and button.accessibility_name==Utilities.LABELS[id],"accessible name preserves the real app title")
			button.grab_focus();await process_frame
			var expected_route:String={"timeline_recovery":"c35_recovery","voice_memos":"c35_voice"}.get(id,id)
			route="";await key(KEY_ENTER)
			check(route==expected_route,"keyboard activation preserves original route "+id)
			button.release_focus();await process_frame
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
