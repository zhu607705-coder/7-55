extends SceneTree
## Headless geometry/type regression; not a raster or physical-device review.
const Pages=preload("res://scripts/ui/chapter3_phone_pages.gd")
const Ui=preload("res://scripts/ui/native_ui_theme.gd")
const Typography=preload("res://scripts/ui/native_typography.gd")
const Chapter=preload("res://scripts/chapters/chapter3.gd")
var checks:=0
var failures:=0
func _initialize()->void: run.call_deferred()
func check(ok:bool,message:String)->void:
	checks+=1
	if not ok: failures+=1;push_error("C35 TYPE: "+message)
func inspect(node:Node,surface:Control,page:String)->void:
	if node is Label and node.has_theme_font_size_override("font_size"):
		# Other composited components retain their own font contracts.
		if node.get_script()==null:
			check(node.get_theme_font_size("font_size")>=14,"no reduced 10px page labels: "+page+" / "+node.text.left(24))
	if node is Label or node is BaseButton:
		var bounds:Rect2=node.get_global_rect()
		var outer:Rect2=surface.get_global_rect()
		check(bounds.position.x>=outer.position.x-.1 and bounds.end.x<=outer.end.x+.1,"control remains within phone width: "+page+" / "+str(node.name))
		if node is Label:
			check(node.size.y+.1>=node.get_minimum_size().y,"label has its measured wrapped height: "+page+" / "+node.text.left(24))
	for child:Node in node.get_children():inspect(child,surface,page)
func run()->void:
	var pages=Pages.new()
	for requested:int in [11,12,13,14,15,16,17,21,25,35]:
		var text:Label=pages.label("中文正文与时间 07:55",requested)
		check(text.get_theme_font("font")==Typography.body_font(),"container labels use bundled body font")
		check(text.get_theme_font_size("font_size")==maxi(15,requested),"requested type retained with caption floor "+str(requested))
		check(text.get_theme_font_size("font_size")*(366.0/430.0)>=12,"390px mobile text exceeds 12px "+str(requested))
		text.free()
	var chapter=Chapter.new()
	var state:Dictionary=root.get_node("State").initial()
	state.native.settings.reduced_motion=true
	state.qizhenLake.phase="complete";state.qizhenLake.active=true
	chapter.dispatch(state,"c35_begin");chapter.dispatch(state,"c35_journal","safe_return")
	for dimensions:Vector2 in [Vector2(390,844),Vector2(430,860),Vector2(1440,900)]:
		var host:=Control.new()
		host.theme=Ui.make_theme(load("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf"))
		host.scale=Vector2.ONE*minf(1.0,minf((dimensions.x-24)/430.0,(dimensions.y-36)/860.0))
		root.add_child(host)
		var scroll:=ScrollContainer.new();scroll.size=Vector2(424,814)
		scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
		scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_SHOW_NEVER
		host.add_child(scroll)
		for page:String in ["c35_recovery","c35_journal","c35_photos","c35_voice","c35_official","c35_messages","c35_network","c3_ticket_post"]:
			var surface:Control=pages.build(page,chapter.view(page,state),state)
			scroll.add_child(surface)
			for i:int in 5:await process_frame
			check(surface.size.x<=424.1,"page does not enlarge phone "+page)
			inspect(surface,surface,page)
			scroll.remove_child(surface);surface.free()
		host.free()
	print("C35_TYPOGRAPHY: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
