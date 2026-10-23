extends Button
## Original colored object icons, using the shared campus palette and fine grid.
## Drawing is independent from the retained 44px touch/focus target and actions.
const NativeUi=preload("res://scripts/ui/native_ui_theme.gd")
const SLOT_FILL:=Color("F4EAD5")
const SLOT_EDGE:=Color("A1744E")
const MASTER_SIZE:=80
static var artwork:Dictionary={}
var glyph:String="phone"
func _has_point(point:Vector2)->bool:
	return Rect2(Vector2.ZERO,size).has_point(point)

func _gui_input(event:InputEvent)->void:
	if (event is InputEventScreenTouch or event is InputEventMouseButton) and event.canceled and not event.pressed:
		# Godot 4.7.1 BaseButton treats a cancelled release as an ordinary click.
		# Clear its press attempt before native activation, without changing input
		# emulation, callbacks, or the control's final enabled state.
		if not disabled:
			disabled=true
			disabled=false
		accept_event()

func _init()->void:
	text=""
	tooltip_text="打开手机 · P"
	custom_minimum_size=Vector2(44,44)
	size=Vector2(44,44)
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	apply_slot_style(self)
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	button_down.connect(queue_redraw)
	button_up.connect(queue_redraw)

static func apply_slot_style(button:Button,selected:bool=false)->void:
	# All tools and item slots share the same opaque plate, including disabled
	# and pointer states. Borders indicate hover/selection without recoloring it.
	for state:String in ["normal","hover","pressed","hover_pressed","disabled"]:
		var edge:Color=Color("C77964") if selected else SLOT_EDGE
		if state in ["hover","pressed","hover_pressed"]:edge=Color("D3A451") if not selected else edge
		if state=="disabled":edge=Color("A39B87")
		button.add_theme_stylebox_override(state,NativeUi.box(SLOT_FILL,edge,2 if selected else 1,4,Vector2.ZERO))
	button.add_theme_stylebox_override("focus",NativeUi.box(Color.TRANSPARENT,Color("344452"),2,4,Vector2.ZERO))
	button.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND

func _draw()->void:
	var edge:=36.0 if is_hovered() and not disabled else 34.0
	var origin:=((size-Vector2.ONE*edge)/2).round()+Vector2(0,1 if is_pressed() else 0)
	draw_texture_rect(artwork_texture(),Rect2(origin,Vector2.ONE*edge),false,Color(1,1,1,.45 if disabled else 1.0))

func artwork_texture()->ImageTexture:
	if not artwork.has(glyph):artwork[glyph]=ImageTexture.create_from_image(paint_master(glyph))
	return artwork[glyph]

static func block(image:Image,rect:Rect2i,hex:String)->void:
	image.fill_rect(rect,Color(hex))

static func disk(image:Image,center:Vector2,radius:float,hex:String)->void:
	for y:int in range(maxi(0,int(center.y-radius)),mini(MASTER_SIZE,int(center.y+radius)+1)):
		for x:int in range(maxi(0,int(center.x-radius)),mini(MASTER_SIZE,int(center.x+radius)+1)):
			if Vector2(x+.5,y+.5).distance_squared_to(center)<=radius*radius:image.set_pixel(x,y,Color(hex))

static func star(image:Image,x:int,y:int)->void:
	block(image,Rect2i(x-1,y-4,2,8),"F4CD77")
	block(image,Rect2i(x-4,y-1,8,2),"F4CD77")
	block(image,Rect2i(x-1,y-1,2,2),"FFF0B2")

static func paint_master(kind:String)->Image:
	var image:=Image.create(MASTER_SIZE,MASTER_SIZE,false,Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	match kind:
		"phone":
			block(image,Rect2i(20,4,40,72),"202B35")
			block(image,Rect2i(17,8,46,64),"202B35")
			block(image,Rect2i(20,8,40,64),"526B7A")
			block(image,Rect2i(20,8,3,62),"A9BCC2")
			block(image,Rect2i(23,15,34,46),"243F5A")
			block(image,Rect2i(25,17,30,42),"83A7B6")
			block(image,Rect2i(25,41,30,18),"547F9D")
			block(image,Rect2i(25,56,30,3),"385B79")
			block(image,Rect2i(34,10,12,2),"202B35")
			block(image,Rect2i(36,65,8,5),"C5C1A9")
			disk(image,Vector2(46,27),5,"F4CD77")
			block(image,Rect2i(29,37,8,7),"F4EAD5")
			block(image,Rect2i(42,37,8,7),"A9B577")
			block(image,Rect2i(29,48,8,7),"C77964")
			block(image,Rect2i(42,48,8,7),"F4CD77")
		"journal":
			block(image,Rect2i(10,9,56,64),"44332D")
			block(image,Rect2i(13,6,53,62),"70503B")
			block(image,Rect2i(18,9,49,58),"D8C7A0")
			block(image,Rect2i(21,9,43,54),"F4EAD5")
			block(image,Rect2i(23,12,38,48),"E8E0C8")
			block(image,Rect2i(16,6,9,62),"A76A4C")
			block(image,Rect2i(18,7,3,59),"D89C6A")
			block(image,Rect2i(25,64,41,3),"A39B87")
			block(image,Rect2i(31,20,23,3),"547F9D")
			for y:int in [30,38,46]:block(image,Rect2i(31,y,23 if y<46 else 16,2),"A39B87")
			block(image,Rect2i(54,6,7,13),"9A514A")
			block(image,Rect2i(57,6,4,10),"C77964")
		"map":
			for panel:Array in [[6,17,23,54,"70503B"],[28,10,23,54,"70503B"],[50,17,23,54,"70503B"],[8,18,19,50,"D8C7A0"],[29,12,20,49,"F4EAD5"],[51,19,20,49,"E8E0C8"]]:
				block(image,Rect2i(panel[0],panel[1],panel[2],panel[3]),panel[4])
			block(image,Rect2i(12,24,12,14),"A9B577")
			block(image,Rect2i(15,38,9,8),"72865C")
			block(image,Rect2i(31,17,15,9),"A9B577")
			block(image,Rect2i(52,43,15,14),"A9B577")
			block(image,Rect2i(42,33,7,24),"83A7B6")
			block(image,Rect2i(49,38,13,7),"83A7B6")
			block(image,Rect2i(27,16,2,49),"A1744E")
			block(image,Rect2i(49,17,2,48),"C79B62")
			for point:Vector2i in [Vector2i(17,54),Vector2i(23,51),Vector2i(30,47),Vector2i(35,42)]:
				block(image,Rect2i(point,Vector2i(3,3)),"A76A4C")
			disk(image,Vector2(37,33),7,"9A514A")
			block(image,Rect2i(35,37,4,7),"9A514A")
			disk(image,Vector2(37,32),3,"F4CD77")
		"light":
			for index:int in range(8):
				var point:Vector2=(Vector2(40,40)+Vector2.from_angle(index*TAU/8)*30).round()
				block(image,Rect2i(Vector2i(point)-Vector2i(3,3),Vector2i(6,6)),"D3A451")
				block(image,Rect2i(Vector2i(point)-Vector2i(2,2),Vector2i(4,4)),"F4CD77")
			disk(image,Vector2(40,40),23,"A76A4C")
			disk(image,Vector2(40,39),21,"D3A451")
			disk(image,Vector2(39,37),18,"F4CD77")
			disk(image,Vector2(34,31),9,"FFF0B2")
		"dark":
			disk(image,Vector2(39,41),29,"243F5A")
			disk(image,Vector2(37,38),27,"385B79")
			disk(image,Vector2(36,38),21,"D8C7A0")
			disk(image,Vector2(34,36),19,"FFF0B2")
			disk(image,Vector2(45,28),18,"385B79")
			disk(image,Vector2(24,45),3,"F4CD77")
			star(image,58,17);star(image,54,45);star(image,67,33)
		"bag":
			block(image,Rect2i(26,9,28,15),"70503B")
			block(image,Rect2i(31,13,18,9),"44332D")
			block(image,Rect2i(14,22,52,50),"44332D")
			block(image,Rect2i(17,22,46,46),"A1744E")
			block(image,Rect2i(19,24,42,14),"C79B62")
			block(image,Rect2i(19,41,42,3),"70503B")
			block(image,Rect2i(35,35,10,16),"D3A451")
			block(image,Rect2i(38,38,4,9),"FFF0B2")
	return image
