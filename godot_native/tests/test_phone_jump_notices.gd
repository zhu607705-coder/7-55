extends SceneTree
## Two routed banners only. Preserve independent world/dialogue sources and real routes.
const Surface=preload("res://scripts/ui/native_phone_notice.gd")
const Typography=preload("res://scripts/ui/native_typography.gd")
const Ui=preload("res://scripts/ui/native_ui_theme.gd")
# Notice styling must leave these independent world/dialogue surfaces intact.
# Check-in's reviewed changes remove duplicate pause UI and redundant receipt copy;
# its print geometry, timing and real receipt route have dedicated behavior tests.
const REVIEWED_SURFACE_HASHES:={
	"res://scripts/presentation/library_story_view.gd":"217f4c1b35af66d7c20e864d0c3f80d01ac71f8a929772ac4f0ff65872b29cdd",
	"res://scripts/ui/selected_dialogue_layout.gd":"a3d5da59614b807640729e5f0c9b50a7e227fdbf6819791047a7edb80b2c1e03",
	"res://scripts/ui/checkin_success_view.gd":"cf60aa06ee738968ca33a147d19038b412de5dd6f9c38f7ba1398fd5852029d3",
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
	for source:String in REVIEWED_SURFACE_HASHES:
		check(FileAccess.get_file_as_string(source).sha256_text()==REVIEWED_SURFACE_HASHES[source],"independently reviewed surface retains its approved bytes: "+source)
	state=root.get_node("State");state.developer_mode=true;state.d=state.initial()
	shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);await frames()
	for extent:Vector2i in [Vector2i(390,844),Vector2i(844,390),Vector2i(1280,720)]:
		root.size=extent;shell.size=Vector2(extent);await frames()
		for recovery:bool in [false,true]:
			await home(recovery)
			var name_value:="HomeInterludeTopNotice" if recovery else "HomeFriendNotice"
			var button:Button=shell.page_body.find_child(name_value,true,false)
			check(button!=null,"real banner exists "+name_value)
			if button==null:continue
			var rect:=button.get_global_rect()
			check(shell.phone.get_global_rect().encloses(rect),"banner remains inside canonical phone")
			var body_text:="检测到 7 分 55 秒未同步记录" if recovery else "速来！老师开始雷达签到！"
			var width:float=400/(424.0/378.0) if recovery else 352
			check(button.size.is_equal_approx(Vector2(width,Surface.summary_height(width,body_text))),"banner hitbox follows the shared measured summary height")
			check(button.get_node("NoticeBody").get_global_rect().end.y<=rect.end.y+.01,"wrapped banner body stays inside its visible card")
			check(button.get_node_or_null("TactileMaterialState")==null,"local opaque notice survives global empty-button ghost adoption")
			for mode:String in ["normal","hover","pressed","hover_pressed","disabled"]:
				var box:=button.get_theme_stylebox(mode) as StyleBoxFlat
				check(box!=null and box.bg_color.a==1 and box.border_width_left==2 and box.shadow_size==0,"all banner states keep an opaque flat edge: "+mode)

				for child:Node in button.get_children():
					if child is Label:
						check(Ui._contrast(child.get_theme_color("font_color"),box.bg_color)>=4.5,"actual child ink on every painted face: "+mode+" "+child.text)
						check(child.get_theme_font("font")== (Typography.display_font() if child.name=="NoticeTitle" else Typography.body_font()),"actual notice labels retain their shared title/body role")
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
		var followup:Button=shell.page_body.find_child("HomeFriendNotice",true,false)
		check(followup!=null,"later friend banner retains its trigger")
		if followup!=null:
			check(followup.get_node("NoticeBody").text=="签上了吗？？","later friend source words unchanged")
			await click_at(followup.get_global_rect().get_center())
			check(state.d.native.page=="wechat","later friend banner still routes to WeChat")

	print("Phone jump notices: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
