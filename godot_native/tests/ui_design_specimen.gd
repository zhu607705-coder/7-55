extends Control
## GPU-only reference surface assembled from production style factories.
## No controller, save, or gameplay dependency; state labels are QA annotations.
const Ui=preload("res://scripts/ui/native_ui_theme.gd")
const MaterialUi=preload("res://scripts/ui/campus_ui_material.gd")
const Notebook=preload("res://scripts/ui/campus_notebook_panel.gd")
const Typography=preload("res://scripts/ui/native_typography.gd")
func _ready()->void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background:=ColorRect.new();background.color=Color("172b36");background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(background)
	var margin:=MarginContainer.new();margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side:String in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,16)
	add_child(margin)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",10);margin.add_child(column)
	# One project family with actual Regular/Medium roles and unchanged sizes.
	for sample: Array in [[28,"校园调查 7:55","display"],[18,"正文与按钮 · Morning Note","body"],[15,"0123456789 Aa，。！？","display"]]:
		var line:=Label.new();line.name="TypeSample"+str(sample[0]);line.text=sample[1]
		line.set_meta("typography_role",sample[2])
		if sample[2]=="display":Typography.apply_display(line)
		else:Typography.apply_body(line)
		line.add_theme_font_size_override("font_size",sample[0])
		line.add_theme_color_override("font_color",MaterialUi.PAPER)
		line.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;column.add_child(line)
	for dark:bool in [false,true]:
		var grid:=GridContainer.new();grid.columns=3;grid.add_theme_constant_override("h_separation",8);grid.add_theme_constant_override("v_separation",8);column.add_child(grid)
		var fill:=MaterialUi.NAVY if dark else MaterialUi.PAPER
		var ink:=MaterialUi.PAPER if dark else MaterialUi.INK
		var states:=Ui.button_styles(fill,ink,MaterialUi.WOOD)
		for state:String in ["normal","hover","pressed","hover_pressed","disabled","focus"]:
			var button:=Button.new();button.text=state;Typography.apply_body(button);button.add_theme_font_size_override("font_size",12)
			button.custom_minimum_size=Vector2(108,48);button.mouse_filter=Control.MOUSE_FILTER_IGNORE;button.focus_mode=Control.FOCUS_NONE
			button.add_theme_stylebox_override("normal",states.normal if state=="focus" else states[state]);button.add_theme_color_override("font_color",ink)
			grid.add_child(button)
			if state=="focus":
				var ring:=Panel.new();ring.mouse_filter=Control.MOUSE_FILTER_IGNORE;ring.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);ring.add_theme_stylebox_override("panel",states.focus);button.add_child(ring)
	for kind:String in ["paper","placard"]:
		var panel:=PanelContainer.new();panel.add_theme_stylebox_override("panel",MaterialUi.panel_style(kind));column.add_child(panel)
		var text:=Label.new();text.text="校园界面 · "+kind;Typography.apply_body(text);text.add_theme_color_override("font_color",MaterialUi.PAPER if kind=="placard" else MaterialUi.INK);panel.add_child(text)
	for kind:String in ["notebook","loose_sheet"]:
		var panel:=Notebook.new();panel.mode=kind;panel.custom_minimum_size.y=110;column.add_child(panel)
		var text:=Label.new();text.text="调查记录 · "+kind;Typography.apply_body(text);text.add_theme_color_override("font_color",MaterialUi.INK);panel.add_child(text)
