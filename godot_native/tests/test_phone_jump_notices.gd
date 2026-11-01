extends SceneTree
## Two routed banners only. Protect main dialogue/check-in source byte identity.
const Surface=preload("res://scripts/ui/phone_jump_notice.gd")
const Typography=preload("res://scripts/ui/native_typography.gd")
const Ui=preload("res://scripts/ui/native_ui_theme.gd")
# Explicitly approved scope excludes these main72fe surfaces.
const UNCHANGED_MAIN_SOURCE:={
	"res://scripts/presentation/library_story_view.gd":"f79a92f325a0d0345c4dc717bb4c8afb7a07dc9d2120176b56a3b33e1945d0dd",
	"res://scripts/ui/selected_dialogue_layout.gd":"dfb4328faec3e1a1272ffea7332116fb7cb0d16512457359adf356232a667fed",
	"res://scripts/ui/native_checkin_page.gd":"7e7ee48bd14d3334aa3d69779c89e2a4a281f4deb0ad561e8ad9ddf4911717b6",
	"res://scripts/ui/checkin_success_view.gd":"2754e4d0a794666a5534534ac64a59e86d759358787c9adb2f6dba8adf5a71e9",
	"res://scripts/ui/native_typography.gd":"d763b08aa1718e34bdf88b745af3635a8dbe157832105533859d6ddc229c89f2",
}
var checks:=0
var failures:=0
var shell:Control
var state:Node
func _initialize()->void:run.call_deferred()
func check(ok:bool,message:String)->void:
	checks+=1
	if not ok:failures+=1;push_error("PHONE JUMP NOTICE: "+message)
func frames(n:int=4)->void:
	for i in n:await process_frame
func key(code:Key)->void:
	for down:bool in [true,false]:
		var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=down;Input.parse_input_event(event);await frames(1)
	await frames()
func click_at(point:Vector2)->void:
	for down:bool in [true,false]:
		var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.position=point;event.pressed=down;Input.parse_input_event(event);await frames(1)
	await frames()
func home(recovery:bool=false)->void:
	state.d=state.initial();state.d.native.page="phone_home";state.d.runtimeMode="phone";state.d.ui.brightness=100
	if recovery:state.d.qizhenLake.phase="complete";state.d.native.chapter=3
	shell.mobile_world=false;shell._refresh();await frames(8)
func run()->void:
	if not load("res://tests/native_test_isolation.gd").is_isolated_save():quit(2);return
	for source:String in UNCHANGED_MAIN_SOURCE:
		check(FileAccess.get_file_as_string(source).sha256_text()==UNCHANGED_MAIN_SOURCE[source],"out-of-scope source stays byte-identical to main: "+source)
	state=root.get_node("State");state.developer_mode=true;state.d=state.initial()
	shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames()
	for extent:Vector2i in [Vector2i(390,844),Vector2i(844,390),Vector2i(1280,720)]:
		root.size=extent;shell.size=Vector2(extent);await frames()
		for recovery:bool in [false,true]:
			await home(recovery)
			var name_value:="HomeInterludeTopNotice" if recovery else "HomeFriendTopNotice"
			var button:Button=shell.page_body.find_child(name_value,true,false)
			check(button!=null,"real banner exists "+name_value)
			if button==null:continue
			var rect:=button.get_global_rect()
			check(shell.phone.get_global_rect().encloses(rect),"banner remains inside canonical phone")
			check(button.size.is_equal_approx(Vector2(400,62)/(424.0/378.0) if recovery else Vector2(352,50)),"authored banner hitbox unchanged")
			check(button.get_node_or_null("TactileMaterialState")==null,"local opaque notice survives global empty-button ghost adoption")
			for mode:String in ["normal","hover","pressed","hover_pressed","disabled"]:
				var box:=button.get_theme_stylebox(mode) as StyleBoxFlat
				check(box!=null and box.bg_color.a==1 and box.border_width_left==1,"all banner states keep opaque thin edge: "+mode)

				for child:Node in button.get_children():
					if child is Label:
						check(Ui._contrast(child.get_theme_color("font_color"),box.bg_color)>=4.5,"actual child ink on every painted face: "+mode+" "+child.text)
						check(child.get_theme_font("font")==Typography.body_font(),"actual notice labels retain original font")
			var focus:=button.get_theme_stylebox("focus") as StyleBoxFlat
			check(focus!=null and focus.border_width_left==2 and Ui._contrast(focus.border_color,Surface.PAPER)>=3,"visible focus without moving hitbox")
			button.disabled=true;await click_at(rect.get_center());check(state.d.native.page=="phone_home","disabled notice does not navigate")
			button.disabled=false;await frames();await click_at(rect.get_center())
			check(state.d.native.page==("c35_recovery" if recovery else "wechat"),"real pointer keeps exact destination")
			if recovery:
				var back:Button=shell.page_body.find_child("C35IntroBack",true,false)
				check(back!=null,"recovery has its real return control")
				if back!=null:await click_at(back.get_global_rect().get_center())
				check(state.d.native.page=="phone_home","recovery real return reaches same homepage")
			else:
				await key(KEY_ESCAPE);check(state.d.native.page=="phone_home","WeChat returns to same homepage")
				button=shell.page_body.find_child(name_value,true,false);button.grab_focus();await key(KEY_ENTER)
				check(state.d.native.page=="wechat","focused notice Enter keeps destination")
		await home()
		state.d.native.chapter=2;state.d.actOne.phase="friend_message_required";shell._refresh();await frames(8)
		var followup:Button=shell.page_body.find_child("HomeFriendTopNotice",true,false)
		check(followup!=null,"later friend banner retains its trigger")
		if followup!=null:
			var body_text:=""
			for child:Node in followup.get_children():
				if child is Label and child.text!="朋友":body_text=child.text
			check(body_text=="签上了吗？？","later friend source words unchanged")
			await click_at(followup.get_global_rect().get_center())
			check(state.d.native.page=="wechat","later friend banner still routes to WeChat")

	print("Phone jump notices: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
