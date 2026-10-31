extends SceneTree
## Isolated presentation fixtures, not earned play; verifies source art and semantics.
const View = preload("res://scripts/ui/observation_comparison_view.gd")
const Session = preload("res://scripts/presentation/observation_comparison_session.gd")
const Typography = preload("res://scripts/ui/native_typography.gd")
const Art = preload("res://scripts/ui/phone_chrome.gd")
var checks := 0
var failures := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func frames() -> void:
	for i in 4: await process_frame
func inspect(node: Node, width: float) -> void:
	if node is Label or node is Button:
		var expected: Font=Typography.display_font() if node.get_meta("typography_role","body")=="display" else Typography.body_font()
		check(node.get_theme_font("font")==expected,"bundled shared role font: "+str(node.name))
		check(node.get_theme_font_size("font_size")>=15,"readable authored type")
		check(node.size.x<=width+.5,"text/control width bounded: "+str(node.name))
	if node is Button:
		for state_name in ["normal","hover","pressed","hover_pressed","disabled","focus"]:
			check(node.has_theme_stylebox_override(state_name),"explicit button state "+state_name)
	for child in node.get_children(): inspect(child,width)
func run() -> void:
	if not load("res://tests/native_test_isolation.gd").is_isolated_save(): quit(2); return
	var state: Node = root.get_node("State")
	var s: Dictionary = state.initial(); s.items.headphone=true; s.items.waterDrop=true; s.flags.plantWatered=true
	var catalog: Array=JSON.parse_string(FileAccess.get_file_as_string("res://data/source/items.config.json"))
	var model=Session.new(); model.refresh(s,catalog)
	var before := JSON.stringify(s)
	for width in [320,600]:
		var scroll := ScrollContainer.new(); scroll.size=Vector2(width,700); root.add_child(scroll)
		var view=View.new(); view.configure(model); scroll.add_child(view)
		await frames()
		inspect(view,width)
		var selected: Button=view.find_child("ObservationSlot0",true,false)
		check(selected.get_node("HardwareDetail").selected,"active slot has shape marker, not color only")
		var image: Control=view.find_child("ObservationItemArt_headphone",true,false)
		check(image!=null and image.pixels==Art.PIXEL_ICONS.headphone,"existing item art reused exactly")
		check(image.mouse_filter==Control.MOUSE_FILTER_IGNORE and image.texture_filter==CanvasItem.TEXTURE_FILTER_NEAREST,"item pixels stay crisp and do not intercept input")
		check(view._item_art(model.card("observation:plantWatered"),40)==null,"observation has no fabricated art")
		model.clear(); model.choose("item:headphone"); model.choose("observation:plantWatered"); model.compare()
		view._render(); await frames(); inspect(view,width)
		check(view.find_child("ObservationBody0",true,false).text==model.card("item:headphone").body,"item body unchanged")
		check(view.find_child("ObservationBody1",true,false).text==model.card("observation:plantWatered").body,"observation body unchanged")
		var leaf: StyleBoxFlat=view.find_child("ObservationCard0",true,false).get_theme_stylebox("panel")
		check(leaf.bg_color.a==0 and leaf.border_width_left==0 and leaf.border_width_bottom==1,"content leaf has no nested thick frame")
		scroll.queue_free(); await frames(); model.clear()
	check(JSON.stringify(s)==before,"presentation never mutates earned state")
	print("OBSERVATION_DESIGN: %d checks; %d failures" % [checks,failures]); quit(1 if failures else 0)
