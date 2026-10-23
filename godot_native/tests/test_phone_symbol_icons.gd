extends SceneTree
const Symbols=preload("res://scripts/ui/native_symbol_icon.gd")
const Pages=preload("res://scripts/ui/phone_pages.gd")
const Chapter=preload("res://scripts/chapters/chapter1_2.gd")
const Typography=preload("res://scripts/ui/native_typography.gd")
var checks:=0
var failures:=0
var marks:=0
var emissions:Array=[]
func _initialize() -> void: run.call_deferred()
func check(ok: bool, detail: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error(detail)
func click_at(point:Vector2) -> void:
	var motion:=InputEventMouseMotion.new();motion.position=point;motion.global_position=point;root.push_input(motion,true)
	for down:bool in [true,false]:
		var event:=InputEventMouseButton.new();event.position=point;event.global_position=point;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down;root.push_input(event,true)
	await process_frame
func inspect(node: Node) -> void:
	if (node is Label or node is Button) and Symbols.PATTERNS.has(node.text):
		marks+=1
		var mark: Control=node.get_node_or_null("NativeSymbolIcon")
		check(mark!=null,"unsupported source glyph has explicit art: "+node.text)
		if mark:
			check(mark.rows==Symbols.PATTERNS[node.text],"bundled fallback matches its registry; this alone is not Web visual parity")
			check(mark.mouse_filter==Control.MOUSE_FILTER_IGNORE and mark.focus_mode==Control.FOCUS_NONE,"icon never intercepts original input")
			check(mark.size.is_equal_approx(node.size),"art tracks authored control rectangle")
		check(node.get_theme_color("font_color").a==0,"no missing-glyph box drawn under art")
	if node is Button and node.name in ["ZjudingTab_home","ZjudingTab_messages"]:
		marks+=1
		var parts: PackedStringArray=node.text.split("\n")
		check(parts.size()==2 and Symbols.PATTERNS.has(parts[0]),"original composite nav semantics retained")
		var icon: Control=node.get_node_or_null("NativeSymbolIcon")
		var caption: Label=node.get_node_or_null("NativeSymbolCaption")
		check(icon!=null and caption!=null,"composite symbol and caption have separate renderers")
		if icon and caption:
			check(caption.text==parts[1],"caption preserves original Chinese label")
			check(icon.position==Vector2(0,4) and icon.size==Vector2(node.size.x,23),"composite icon has exact authored top row")
			check(caption.position.y>=icon.position.y+icon.size.y,"symbol and caption never overlap")
		check(node.get_theme_color("font_color").a==0,"composite source glyph cannot draw tofu")
	if node is Label and node.text=="✱":
		check(node.size==Vector2(42,42),"settings glyph uses exact authored 42px slot")
		check(node.get_node("NativeSymbolIcon").size==Vector2(42,42),"settings art cannot inherit larger fallback line height")
	if node.name=="CC98Wordmark":
		check(node.text=="CC98" and node.autowrap_mode==TextServer.AUTOWRAP_OFF,"CC98 wordmark cannot break into CC9 / 8")
		check(node.get_theme_font("font")==Typography.display_font(),"wordmark has explicit display role")
		check(node.get_theme_font("font").get_string_size(node.text,HORIZONTAL_ALIGNMENT_LEFT,-1,node.get_theme_font_size("font_size")).x<=42,"wordmark fits original 42px box")
	for child in node.get_children(): inspect(child)
func run() -> void:
	if not load("res://tests/native_test_isolation.gd").is_isolated_save(): quit(2); return
	root.size=Vector2i(500,1000)
	var state: Node=root.get_node("State")
	var pages=Pages.new(); var chapter=Chapter.new()
	pages.action_requested.connect(func(id,value):emissions.append([id,value]))
	var surface:=Control.new(); surface.size=Vector2(424,854); root.add_child(surface)
	var s: Dictionary=state.initial()
	s.native.chapter=2; s.actOne.phase="movement_required"; s.ui.musicPlaying=true
	s.actOne.inventoryRecovered=true; s.items.campusCard=true
	for page in ["phone_home","zjuding","library_app","control_center"]:
		var panel: Control=pages.build(page,chapter.view(page,s),s)
		surface.add_child(panel)
		for i in 4: await process_frame
		inspect(panel)
		if page=="phone_home":
			var launcher:Control=panel.find_child("HomeApp_settings",true,false)
			check(launcher!=null,"actual launcher includes the settings app")
			if launcher!=null:
				for id: String in launcher.get_parent().get_meta("home_visible_app_ids"):
					var app: Control=panel.find_child("HomeApp_"+id,true,false)
					check(app!=null and app.get_node_or_null("OriginalAppArtwork_"+id)!=null,"available launcher app retains its original artwork: "+id)
		if page=="zjuding":
			for tab: String in ["ZjudingTab_home","ZjudingTab_messages"]:
				var button: Control=panel.find_child(tab,true,false)
				check(button!=null and button.get_node_or_null("NativeSymbolIcon")!=null,"actual navigation keeps its source icon: "+tab)
		if page=="control_center":
			var wifi:Button=panel.find_child("ControlNetwork_wifi",true,false)
			var mark:Control=wifi.get_node_or_null("SourceWifiIcon")
			check(mark!=null and mark is Symbols.WifiMark,"network role uses source arcs rather than vibration matrix")
			check(wifi.find_children("NativeSymbolIcon","",true,false).is_empty(),"Wi-Fi cannot contain the old QR-like symbol substitute")
			if mark:
				check(mark.get_rect()==Rect2(9,10,34,34),"source Wi-Fi stays in unchanged network bubble")
				check(mark.ARC_RECTS==[Rect2(8,9,22,18),Rect2(12.5,15,13,11)] and mark.DOT_RECT==Rect2(16.5,23,5,5),"source CSS dimensions include the2px containing border and square dot")
				check(mark.mouse_filter==Control.MOUSE_FILTER_IGNORE and mark.focus_mode==Control.FOCUS_NONE,"Wi-Fi art cannot intercept network input")
				var before:=emissions.size()
				await click_at(mark.get_global_rect().get_center())
				check(emissions.size()==before+1 and emissions.back()==["c1_network","校园网"],"actual pointer on restored WiFi art emits original network action exactly once")
			var cellular:Button=panel.find_child("ControlNetwork_cellular",true,false)
			var before_cellular:=emissions.size()
			await click_at(cellular.get_global_rect().get_center())
			check(emissions.size()==before_cellular+1 and emissions.back()==["c1_network","移动数据"],"neighbor cellular input remains original and single-shot")
			var vibration:Button=panel.find_child("ControlToggle_1",true,false)
			check(vibration.find_children("NativeSymbolIcon","",true,false).size()==1,"legitimate vibration source glyph keeps its separate role")
		panel.queue_free(); await process_frame
	check(marks>=3,"actual navigation and control-center surfaces include their source glyph samples")
	for symbol in Symbols.PATTERNS:
		var button:=Button.new(); button.text=symbol; button.size=Vector2(48,48)
		surface.add_child(button)
		var original:=button.size
		check(Symbols.apply(button,symbol,Color.WHITE,24),"every bundled symbol supported")
		check(button.text==symbol and button.size==original,"semantic text and input geometry retained")
		button.queue_free()
	surface.queue_free(); await process_frame
	print("PHONE_SYMBOL_ICONS: %d checks; %d failures" % [checks,failures]); quit(1 if failures else 0)
