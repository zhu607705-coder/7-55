extends SceneTree
const Symbols=preload("res://scripts/ui/native_symbol_icon.gd")
const Pages=preload("res://scripts/ui/phone_pages.gd")
const Chapter=preload("res://scripts/chapters/chapter1_2.gd")
const Typography=preload("res://scripts/ui/native_typography.gd")
var checks:=0
var failures:=0
var marks:=0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, detail: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error(detail)
func inspect(node: Node) -> void:
	if (node is Label or node is Button) and Symbols.PATTERNS.has(node.text):
		marks+=1
		var mark: Control=node.get_node_or_null("NativeSymbolIcon")
		check(mark!=null,"unsupported source glyph has explicit art: "+node.text)
		if mark:
			check(mark.rows==Symbols.PATTERNS[node.text],"pattern retains correct source meaning")
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
	var state: Node=root.get_node("State")
	var pages=Pages.new(); var chapter=Chapter.new()
	var surface:=Control.new(); surface.size=Vector2(424,854); root.add_child(surface)
	var s: Dictionary=state.initial()
	s.native.chapter=2; s.actOne.phase="movement_required"; s.ui.musicPlaying=true
	s.actOne.inventoryRecovered=true; s.items.campusCard=true
	for page in ["phone_home","zjuding","library_app","control_center"]:
		var panel: Control=pages.build(page,chapter.view(page,s),s)
		surface.add_child(panel)
		for i in 4: await process_frame
		inspect(panel)
		panel.queue_free(); await process_frame
	check(marks>=7,"actual affected app surfaces include icon samples")
	for symbol in Symbols.PATTERNS:
		var button:=Button.new(); button.text=symbol; button.size=Vector2(48,48)
		surface.add_child(button)
		var original:=button.size
		check(Symbols.apply(button,symbol,Color.WHITE,24),"every bundled symbol supported")
		check(button.text==symbol and button.size==original,"semantic text and input geometry retained")
		button.queue_free()
	surface.queue_free(); await process_frame
	print("PHONE_SYMBOL_ICONS: %d checks; %d failures" % [checks,failures]); quit(1 if failures else 0)
