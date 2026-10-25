extends RefCounted
## Stage-local timber signs and a quiet surtitles rail. No playback authority.
const INK=Color("202B35")
const PAPER=Color("E8E0C8")
const WOOD=Color("44332D")
const GOLD=Color("C79B62")
const CINNABAR=Color("9A514A")

class PaperSurface extends Control:
	var caption_rail:=false
	func _ready()->void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)
	func _draw()->void:
		var bounds:=Rect2(Vector2.ZERO,size)
		var edge:=Color("A1744E")
		draw_rect(bounds,Color(0.125,0.169,0.208,0.94))
		if caption_rail:
			# The line sits on the stage apron, with no opaque sheet over the actors.
			draw_line(Vector2(18,1),Vector2(size.x-18,1),edge,1)
			for x:float in [8.0,size.x-9.0]:
				draw_line(Vector2(x,7),Vector2(x,size.y-7),Color("70503B"),1)
				draw_line(Vector2(x-3,7),Vector2(x+3,7),edge,1)
				draw_line(Vector2(x-3,size.y-7),Vector2(x+3,size.y-7),edge,1)
		else:
			draw_rect(bounds.grow(-1),Color("70503B"),false,1)
			draw_line(Vector2(8,size.y-5),Vector2(size.x-8,size.y-5),edge,1)
			draw_rect(Rect2(5,5,3,size.y-10),Color("9A514A"))

class SignSurface extends Control:
	var owner_button:Button
	func _draw()->void:
		var active:bool=owner_button.is_hovered() or owner_button.has_focus()
		var face:=Color("70503B") if active else Color("44332D")
		if owner_button.is_pressed():face=Color("344452")
		var bounds:=Rect2(Vector2(1,2),size-Vector2(2,4))
		draw_rect(bounds,face)
		draw_rect(bounds,Color("C79B62") if active else Color("A1744E"),false,1)
		draw_rect(bounds.grow(-3),Color("A1744E"),false,1)
		for x:float in [7.0,size.x-8.0]:
			draw_line(Vector2(x,7),Vector2(x,size.y-7),Color("202B35"),1)

class StageButton extends Button:
	func _ready()->void:
		if name=="PerformanceProgramme":return
		var face:=SignSurface.new();face.name="TimberFace";face.owner_button=self
		face.mouse_filter=Control.MOUSE_FILTER_IGNORE;face.show_behind_parent=true
		add_child(face);face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		for event:String in ["resized","mouse_entered","mouse_exited","button_down","button_up","focus_entered","focus_exited"]:
			connect(event,face.queue_redraw)

static func surface(caption_rail:bool=false)->Control:
	var node:=PaperSurface.new();node.caption_rail=caption_rail;node.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return node

static func button(id:String,text:String,action:Callable)->Button:
	var node:=StageButton.new();node.name=id;node.text=text
	# Native Button owns text alignment, drawing and pointer hit area.
	# Preserve the performance root as the existing keyboard/QTE owner.
	# The complete sign scales with the stage frame; no separate floating label.
	node.alignment=HORIZONTAL_ALIGNMENT_CENTER;node.focus_mode=Control.FOCUS_NONE
	for state:String in ["normal","hover","pressed","focus","disabled"]:
		var style:=StyleBoxEmpty.new()
		style.content_margin_left=14;style.content_margin_right=14
		style.content_margin_top=8;style.content_margin_bottom=8
		node.add_theme_stylebox_override(state,style)
	for state:String in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:node.add_theme_color_override(state,PAPER)
	node.add_theme_color_override("font_disabled_color",Color("A39B87"))
	node.pressed.connect(action)
	return node
