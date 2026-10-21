extends Control
## Selected HUD 2 / interaction 1. Screen-space presentation only.
## World motion, targets, camera and progression remain owned by world.gd.
const Selected = preload("res://scripts/ui/selected_ui_theme.gd")
class Scrim extends PanelContainer:
	func _draw()->void:
		# The selected scrim fades left-to-right, not an opaque paper card.
		for x:int in range(ceili(size.x)):
			var edge:float=minf(x,size.x-1-x)
			var cut:float=6-sqrt(maxf(0,36-pow(maxf(0,6-edge),2))) if edge<6 else 0
			var color:=Color("20352d");color.a=.9*maxf(0,1-float(x)/maxf(1,size.x))
			draw_line(Vector2(x+.5,cut),Vector2(x+.5,size.y-cut),color,1)

var task: PanelContainer
var task_scroll: ScrollContainer
var task_column: VBoxContainer
var clock: Label
var location: Label
var objective: Label
var task_tip: Label
var plaque: VBoxContainer
var object_heading: Label
var object_body: Label
var object_hint: Label
var mode: Label
var geometry: Dictionary = {}
var mobile_exploration:=false
var compact_header:HBoxContainer
var compact_clock:Label
var compact_location:Label

func _init() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	z_index=85
	task=Scrim.new();task.name="SelectedHud2";task.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(task)
	var material:=StyleBoxFlat.new()
	material.bg_color=Color.TRANSPARENT
	material.set_corner_radius_all(6);material.set_content_margin_all(8)
	task.add_theme_stylebox_override("panel",material)
	task_scroll=ScrollContainer.new();task_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	task_scroll.mouse_filter=Control.MOUSE_FILTER_IGNORE;task_scroll.mouse_force_pass_scroll_events=false;task.add_child(task_scroll)
	task_column=VBoxContainer.new();task_column.mouse_filter=Control.MOUSE_FILTER_IGNORE;task_column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	task_column.add_theme_constant_override("separation",8);task_scroll.add_child(task_column)
	compact_header=HBoxContainer.new();compact_header.add_theme_constant_override("separation",8);compact_header.mouse_filter=Control.MOUSE_FILTER_IGNORE;task_column.add_child(compact_header)
	compact_clock=_label(compact_header,"hud","heading")
	compact_location=_label(compact_header,"hud","tip")
	location=_label(task_column,"hud","tip")
	clock=_label(task_column,"hud","heading")
	objective=_label(task_column,"hud","body")
	task_tip=_label(task_column,"hud","tip");task_column.move_child(task_tip,3)
	plaque=VBoxContainer.new();plaque.name="SelectedInteraction1";plaque.mouse_filter=Control.MOUSE_FILTER_IGNORE
	plaque.add_theme_constant_override("separation",8);add_child(plaque)
	object_heading=_label(plaque,"interaction","heading")
	object_heading.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	object_body=_label(plaque,"interaction","body")
	object_body.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	object_hint=_label(plaque,"interaction","button")
	object_hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	mode=_label(self,"hud","button");mode.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER

func _label(parent:Node,surface:String,role:String)->Label:
	var label:=Label.new();label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	Selected.apply_label(label,surface,role);parent.add_child(label)
	return label

func sync_view(extent:Vector2,display_scale:float,title:String,goal:String,prompt:String,mode_text:String,mode_rect:Rect2,bottom:float,clock_text:String="",object_detail:String="")->void:
	var s:=maxf(.01,display_scale)
	scale=Vector2.ONE/s;size=extent*s
	location.text=title;clock.text=clock_text;clock.visible=not clock_text.is_empty();objective.text=goal;task_tip.text="当前任务"
	object_heading.text=prompt;object_body.text=object_detail;object_body.visible=not object_detail.is_empty() and object_detail!=prompt;object_hint.text="交互" if mobile_exploration else "空格 · 交互"
	mode.text=mode_text
	var compact:bool=size.y<450
	compact_header.visible=compact
	compact_clock.text=clock_text;compact_clock.visible=not clock_text.is_empty()
	compact_location.text=title
	location.visible=not compact;clock.visible=not compact and not clock_text.is_empty()
	var inset:=Vector2(size.x*.06,size.y*.06)
	# Same selected left-column composition, bounded scroll for long source goals.
	var width:=minf(300,maxf(1,size.x*.65))
	# A compact header must still leave a complete first objective line.
	# The previous percentage-only cap clipped that line on short landscapes.
	var first_line:float=Selected.font("hud","body").get_height(Selected.size("hud","body"))
	var header_height:float=compact_header.get_combined_minimum_size().y if compact else location.get_combined_minimum_size().y+clock.get_combined_minimum_size().y+8
	var first_goal_budget:float=16+header_height+task_tip.get_combined_minimum_size().y+16+first_line
	var available_height:=maxf(32,minf(maxf(size.y*.36,first_goal_budget),bottom*s-inset.y-8))
	task.position=inset;task.size=Vector2(width,available_height)
	task.custom_minimum_size=Vector2.ZERO
	var minimum:=task_column.get_combined_minimum_size().y+16
	task.size.y=minf(available_height,maxf(32,minimum));task.queue_redraw()
	# A passive readable HUD must not consume authored world floor taps.
	# Only actual overflow owns pointer scrolling; labels/columns stay transparent.
	task_scroll.mouse_filter=Control.MOUSE_FILTER_STOP if task_column.get_combined_minimum_size().y>task_scroll.size.y+.5 else Control.MOUSE_FILTER_IGNORE
	var plaque_width:=minf(420,maxf(1,size.x*.76))
	plaque.size=Vector2(plaque_width,0)
	var plaque_height:=plaque.get_combined_minimum_size().y
	plaque.position=Vector2((size.x-plaque_width)/2,clampf(size.y*.5-plaque_height*.5,task.position.y+task.size.y+8,maxf(task.position.y+task.size.y+8,bottom*s-plaque_height-8)))
	plaque.visible=not prompt.is_empty()
	mode.position=mode_rect.position*s;mode.size=mode_rect.size*s
	geometry={"task":Rect2(task.position,task.size),"interaction":Rect2(plaque.position,Vector2(plaque_width,plaque_height)),"mode":Rect2(mode.position,mode.size),"extent":Rect2(Vector2.ZERO,size)}
