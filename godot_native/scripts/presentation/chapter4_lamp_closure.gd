extends Control
## One owned native view of the original two-question and layered-lamp consumer.
## The host submits answers/proof; this view never reads or writes campaign state.
signal save_requested(answers:Dictionary)
signal acknowledged(proof:Dictionary)
const Sequence=preload("res://scripts/presentation/chapter4_lamp_sequence.gd")
const Ui=preload("res://scripts/ui/native_ui_theme.gd")
const Lamp3D=preload("res://scripts/presentation/chapter4_lamp_3d.gd")
const SummaryFont=preload("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf")
const FINAL_MESSAGE="从此，你将与历史上众多灿若星辰的名字一起，共享'浙大人'这个无上荣光的称号！"
var config:Dictionary={}
var answers:Dictionary={}
var stage:="questions"
var phase:="entering"
var question_index:=0
var stage_ms:=0.0
var playback_ms:=0.0
var reduced:=false
var disposed:=false
var completed:=false
var feedback:=""
var lamp:Dictionary={}
var panel:PanelContainer
var scroll:ScrollContainer
var column:VBoxContainer
var question_group:VBoxContainer
var choices_grid:GridContainer
var instruction:Label
var caption:Label
var buttons:Array[Button]=[]
var panel_origin:=Vector2.ZERO
var stars:Array=[]
var star_texture:Texture2D
var spark_canvas:Control
var art:ColorRect
var art_material:ShaderMaterial
var star_canvas:Control
var lamp_3d:SubViewportContainer
var uses_blender_lamp:=false
func configure(value:Dictionary)->void:
	config=value.duplicate(true)
	reduced=bool(config.get("settings",{}).get("reduced_motion",false))
	answers=config.get("selectedAnswers",{}).duplicate()
	if config.get("answersSaved",false):stage="saved"
func _ready()->void:
	clip_contents=true;mouse_filter=Control.MOUSE_FILTER_STOP;focus_mode=Control.FOCUS_ALL
	for key in ["dark","outline","glow","core","leds"]:
		var path:String="res://assets/rpg/cinematics/chapter4-755/canruo-star-lamp/lamp_"+key+".png"
		if ResourceLoader.exists(path):lamp[key]=load(path)
	_build_stars()
	star_canvas=Control.new();star_canvas.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var additive:=CanvasItemMaterial.new();additive.blend_mode=CanvasItemMaterial.BLEND_MODE_ADD;star_canvas.material=additive
	star_canvas.draw.connect(_draw_stars);add_child(star_canvas)
	art=ColorRect.new();art.mouse_filter=Control.MOUSE_FILTER_IGNORE;art_material=ShaderMaterial.new();art_material.shader=preload("res://scripts/presentation/chapter4_lamp_layers.gdshader");art.material=art_material
	for key in lamp:art_material.set_shader_parameter(key+"_tex",lamp[key])
	add_child(art)
	# The original five-layer renderer remains a deliberate rollback path. The
	# default consumer now renders the approved, genuine Blender lamp geometry.
	if str(config.get("lampPresentation","blender"))!="layered":
		lamp_3d=Lamp3D.new();lamp_3d.name="BlenderLampPresentation";add_child(lamp_3d)
		uses_blender_lamp=lamp_3d.available
		if not uses_blender_lamp:lamp_3d.queue_free();lamp_3d=null
	art.visible=not uses_blender_lamp;star_canvas.visible=not uses_blender_lamp
	spark_canvas=Control.new();spark_canvas.mouse_filter=Control.MOUSE_FILTER_IGNORE;spark_canvas.draw.connect(_draw_sparks);add_child(spark_canvas)
	panel=PanelContainer.new();panel.add_theme_stylebox_override("panel",Ui.box(Color("08121ded"),Color("d0bb7670"),1,3,Vector2(24,22)));add_child(panel)
	scroll=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;panel.add_child(scroll);move_child(spark_canvas,get_child_count()-1)
	column=VBoxContainer.new();column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;column.add_theme_constant_override("separation",16);scroll.add_child(column)
	caption=Label.new();caption.text="07:55\n灿若星辰";caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;caption.add_theme_font_size_override("font_size",24);caption.add_theme_color_override("font_color",Color("fff2b7"));caption.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(caption)
	resized.connect(_layout);_rebuild();_layout();grab_focus()
func _label(text:String,font_size:int=18,color:Color=Color("f7f1dd"))->Label:
	var label:=Label.new();label.text=text;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.add_theme_font_size_override("font_size",font_size);label.add_theme_color_override("font_color",color)
	label.add_theme_constant_override("line_spacing",5);label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return label
func _button(text:String,callback:Callable)->Button:
	var button:=Button.new();button.text=text;button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;button.custom_minimum_size.y=48
	Ui.apply_button(button,Color("102330"),Color("f7edcc"),Color("7f8a85"),2,1,18,Vector2(14,10),Color("ffda88"))
	button.pressed.connect(callback);buttons.append(button);return button
func _rebuild()->void:
	buttons.clear();question_group=null;instruction=null;choices_grid=null
	for child in column.get_children():column.remove_child(child);child.queue_free()
	panel.visible=stage!="playback"
	caption.visible=stage in ["playback","final"]
	if stage=="questions":
		column.add_child(_label("07:55 · 校史墙留下的两项问题",14,Color("b8a778")))
		column.add_child(_label("灯仍未点亮",24,Color("fff2b7")))
		question_group=VBoxContainer.new();question_group.add_theme_constant_override("separation",14);column.add_child(question_group)
		var q:Dictionary=config.questions[question_index]
		question_group.add_child(_label("第一问 · 01 / 02" if question_index==0 else "第二问 · 02 / 02",15,Color("d8bd68")))
		question_group.add_child(_label(q.prompt,22))
		choices_grid=GridContainer.new();choices_grid.columns=3 if size.x>=600 else 1;choices_grid.add_theme_constant_override("h_separation",8);choices_grid.add_theme_constant_override("v_separation",8);question_group.add_child(choices_grid)
		for option in q.options:
			var button:=_button(option.label,choose.bind(str(q.id),str(option.id)));button.disabled=phase!="ready";button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
			Ui.apply_button(button,Color.TRANSPARENT,Color("e7edf2"),Color.TRANSPARENT,0,0,18,Vector2(10,10),Color("fff4c9"));choices_grid.add_child(button)
		instruction=_label("选择你的回答" if phase=="ready" else "问题正在浮现",15,Color("d0c8a8"));question_group.add_child(instruction)
		if not feedback.is_empty():column.add_child(_label(feedback,16,Color("ffb7a6")))
	elif stage=="saved":column.add_child(_label("回答已保存",24,Color("fff2b7")))
	elif stage=="submitting":column.add_child(_label("正在确认回答",22))
	elif stage=="final":
		column.add_child(_label(FINAL_MESSAGE,18,Color("fff2c6")))
		for i in 2:
			var q:Dictionary=config.questions[i];var answer:=""
			for option in q.options:
				if str(option.id)==str(answers.get(q.id,"")):answer=str(option.label)
			var summary:=_label(("求学所向" if i==0 else "成人所守")+"  ·  "+answer,16,Color("fff0b6"))
			summary.name="LampAnswerSummary%d"%(i+1)
			# Both complete lines use one bundled face. A standalone activity must
			# not mix per-glyph system CJK fallbacks inside the same answer.
			summary.add_theme_font_override("font",SummaryFont)
			column.add_child(summary)
		column.add_child(_button("继续",acknowledge));column.add_child(_label("按 Space 或 Enter 继续",14,Color("c3bea9")))
	_layout();_focus_first.call_deferred();queue_redraw()
func _focus_first()->void:
	if disposed or not is_inside_tree():return
	if not buttons.is_empty() and not buttons[0].disabled:buttons[0].grab_focus()
	else:grab_focus()
func _layout()->void:
	if not is_instance_valid(panel):return
	var portrait:=size.x<600
	var width:=minf(720,size.x-32)
	# Keep real font/target sizes. Small heights scroll instead of scaling text.
	if is_instance_valid(choices_grid):choices_grid.columns=1 if portrait else 3
	var desired:=(500.0 if portrait else 330.0) if stage=="questions" else (360.0 if stage=="final" else 150.0)
	if not portrait and stage=="final":desired=280
	var height:=minf(desired,size.y-32)
	panel_origin=Vector2((size.x-width)/2,(size.y-height)/2 if stage!="final" else size.y-height-16)
	panel.position=panel_origin;panel.size=Vector2(width,height)
	if stage=="final" and uses_blender_lamp and not portrait:
		width=minf(520,size.x*.49-24);height=minf(360,size.y-32)
		panel_origin=Vector2(size.x-width-16,(size.y-height)/2)
		panel.position=panel_origin;panel.size=Vector2(width,height)
	caption.position=Vector2(size.x-220,20 if stage=="final" else size.y-92);caption.size=Vector2(200,72)
	if stage=="final" and size.y<450:caption.position.y=8;caption.add_theme_font_size_override("font_size",18)
	else:caption.add_theme_font_size_override("font_size",24)
	if stage=="final" and uses_blender_lamp:
		caption.position=Vector2(16,16);caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT
	else:caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	_update_art();queue_redraw();star_canvas.queue_redraw();spark_canvas.queue_redraw()
func choose(id:String,value:String)->void:
	if disposed or completed or stage!="questions" or phase!="ready":return
	var q:Dictionary=config.questions[question_index]
	if id!=str(q.id):return
	var valid:=false
	for option in q.options:
		if value==str(option.id):valid=true
	if not valid:return
	answers[id]=value;phase="dissolving";stage_ms=0
	for button in buttons:button.disabled=true
	instruction.text="星光粒子消散中"
func accept_save(result:Dictionary)->void:
	if disposed or stage!="submitting":return
	if result.get("accepted",false):stage="saved";stage_ms=0;feedback=""
	else:stage="questions";question_index=1;phase="entering";stage_ms=0;feedback=str(result.get("message","回答未能保存，请重试。"));feedback="回答未能保存，请重试。" if feedback.is_empty() else feedback
	_rebuild()
func advance(delta_ms:float,focused:bool=true)->void:
	if disposed or completed or not focused or delta_ms<=0:return
	var dt:=minf(delta_ms,100.0)
	stage_ms+=dt
	if stage=="questions":
		var duration:=120.0 if reduced else 1150.0
		if phase=="entering" and stage_ms>=duration:
			phase="ready";stage_ms=0;_rebuild()
		elif phase=="dissolving" and stage_ms>=(160.0 if reduced else 980.0):
			stage_ms=0
			if question_index==0:question_index=1;phase="entering";_rebuild()
			else:stage="submitting";_rebuild();save_requested.emit(answers.duplicate())
		if is_instance_valid(question_group):
			var a:=1.0
			if phase=="entering":a=Sequence.smooth(stage_ms/duration)
			elif phase=="dissolving":a=1-Sequence.smooth(stage_ms/(160.0 if reduced else 980.0))
			question_group.modulate.a=a
			question_group.pivot_offset=question_group.size/2
			question_group.scale=Vector2.ONE if reduced else Vector2.ONE*(lerpf(.975,1,a) if phase=="entering" else (lerpf(1.025,1,a) if phase=="dissolving" else 1.0))
	elif stage=="saved" and stage_ms>=(240.0 if reduced else 1100.0):
		stage="playback";stage_ms=0;playback_ms=0;_rebuild()
	elif stage=="playback":
		playback_ms=minf(playback_ms+dt,float(Sequence.frame(0,reduced).duration))
		if playback_ms>=float(Sequence.frame(0,reduced).duration):stage="final";stage_ms=0;_rebuild()
	if stage=="playback":caption.modulate.a=float(Sequence.frame(playback_ms,reduced).caption)
	else:caption.modulate.a=1
	_update_art();queue_redraw();star_canvas.queue_redraw();spark_canvas.queue_redraw()
func acknowledge()->void:
	if disposed or completed or stage!="final":return
	completed=true
	acknowledged.emit({"consumer":"ChapterFourStarLampClosure","answers":answers.duplicate(),"playbackMs":playback_ms,"acknowledged":true})
func dispose()->void:
	disposed=true;buttons.clear()
	if is_instance_valid(lamp_3d):lamp_3d.dispose()
func _exit_tree()->void:dispose()
func _gui_input(event:InputEvent)->void:
	if not event is InputEventKey or not event.pressed or event.echo:return
	if stage=="final" and event.keycode in [KEY_SPACE,KEY_ENTER,KEY_KP_ENTER]:acknowledge();accept_event()
	elif event.keycode==KEY_TAB:
		var enabled:Array[Button]=[]
		for button in buttons:
			if not button.disabled:enabled.append(button)
		if not enabled.is_empty():
			var index:=enabled.find(get_viewport().gui_get_focus_owner());index=posmod(index+(-1 if event.shift_pressed else 1),enabled.size());enabled[index].grab_focus()
		accept_event()
func _build_stars()->void:
	var image:=Image.create(32,32,false,Image.FORMAT_RGBA8)
	for y in 32:
		for x in 32:
			var d:=Vector2((x+.5)/32*2-1,(y+.5)/32*2-1).length();image.set_pixel(x,y,Color(1,1,1,roundf(pow(maxf(0,1-d),1.7)*255)/255))
	star_texture=ImageTexture.create_from_image(image)
	for layer in [{"count":4200,"min":38.0,"max":54.0,"size":.12,"color":Color("97acd2"),"opacity":.5,"seed":1.1},{"count":1600,"min":28.0,"max":38.0,"size":.19,"color":Color("d4dded"),"opacity":.66,"seed":2.4},{"count":520,"min":20.0,"max":28.0,"size":.28,"color":Color("ffe7ae"),"opacity":.82,"seed":4.7}]:
		var rng:int=int(floor(float(layer.seed)*1000003))&0xffffffff
		for i in int(layer.count):
			rng=(rng*1664525+1013904223)&0xffffffff;var radius:=float(layer.min)+float(rng)/4294967296.0*(float(layer.max)-float(layer.min))
			rng=(rng*1664525+1013904223)&0xffffffff;var ct:=float(rng)/4294967296.0*2-1
			rng=(rng*1664525+1013904223)&0xffffffff;var phi:=float(rng)/4294967296.0*TAU;var st:=sqrt(1-ct*ct)
			stars.append({"p":Vector3(radius*st*cos(phi),radius*ct,radius*st*sin(phi)),"size":layer.size,"color":layer.color,"opacity":layer.opacity,"seed":layer.seed})
func _draw_stars()->void:
	if stage!="playback" or uses_blender_lamp:return
	var frame:=Sequence.frame(playback_ms,reduced);var camera:Vector3=frame.camera;var forward:Vector3=(Vector3(frame.look)-camera).normalized();var right:=forward.cross(Vector3.UP).normalized();var up:=right.cross(forward).normalized();var focal:=size.y/(2*tan(deg_to_rad(44.0)/2))
	for star in stars:
		var relative:Vector3=Vector3(star.p)-camera;var depth:=relative.dot(forward)
		if depth<=.1 or depth>=120:continue
		var pos:=Vector2(size.x/2+relative.dot(right)/depth*focal,size.y/2-relative.dot(up)/depth*focal)
		if not Rect2(Vector2.ZERO,size).has_point(pos):continue
		var c:Color=Color(star.color).lerp(Color("01030a"),1-exp(-.016*.016*depth*depth));c.a=float(star.opacity)*(.68+float(frame.glow)*.12)*(.88+sin(playback_ms*.0012+float(star.seed))*.12)
		# Same perspective point distribution; source soft point texture replaces hard discs.
		var diameter:=maxf(1.0,float(star.size)*size.y*.5/depth)
		star_canvas.draw_texture_rect(star_texture,Rect2(pos-Vector2.ONE*diameter/2,Vector2.ONE*diameter),false,c)
func _update_art()->void:
	if uses_blender_lamp and is_instance_valid(lamp_3d):
		lamp_3d.position=Vector2.ZERO
		var mesh_size:=size
		if stage=="final":
			if size.x<600:mesh_size=Vector2(size.x,maxf(120,panel.position.y-10))
			else:mesh_size=Vector2(maxf(200,panel.position.x-12),size.y)
		lamp_3d.size=mesh_size
		var mesh_time:=playback_ms if stage in ["playback","final"] else 0.0
		lamp_3d.apply_frame(Sequence.frame(mesh_time,reduced),stage)
		return
	if not is_instance_valid(art) or lamp.is_empty():return
	art.size=size
	var frame:=Sequence.frame(playback_ms,reduced)
	var bounds:=size*(1.14 if stage=="playback" else (1.18 if stage=="final" else 1.16))
	var dimensions:Vector2=lamp.dark.get_size();dimensions*=minf(bounds.x/dimensions.x,bounds.y/dimensions.y)
	dimensions*=float(frame.scale) if stage=="playback" else (.88 if stage=="final" else 1.0)
	var position_art:Vector2=(size-dimensions)/2+Vector2(0,float(frame.offset)*bounds.y if stage=="playback" else 0)
	art_material.set_shader_parameter("art_rect",Vector4(position_art.x/size.x,position_art.y/size.y,dimensions.x/size.x,dimensions.y/size.y))
	art_material.set_shader_parameter("viewport_pixels",size)
	art_material.set_shader_parameter("stage_id",1 if stage=="playback" else (2 if stage=="final" else 0))
	art_material.set_shader_parameter("levels",Vector4(frame.led,frame.core,frame.glow,frame.reveal))
func _draw()->void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("01030a"))
func _draw_sparks()->void:
	if (stage=="saved" or (stage=="questions" and phase!="ready")) and not reduced:
		for i in 54:
			var progress:=clampf((stage_ms-(i%12)*24)/(1150.0 if phase=="entering" and stage=="questions" else 980.0),0,1)
			var angle:=deg_to_rad(fmod(i*137.508,360));var distance:=48+(i%9)*13
			var origin:=panel_origin+Vector2(panel.size.x*(4+(i*37)%92)/100.0,panel.size.y*(8+(i*53)%84)/100.0)
			var travel:=1-progress if phase=="entering" and stage=="questions" else progress
			var point:=origin+Vector2(cos(angle),sin(angle))*distance*travel
			var radius:=float(2+i%4)/2;var shape:=PackedVector2Array()
			for offset in [Vector2(0,-1),Vector2(.28,-.28),Vector2(1,0),Vector2(.28,.28),Vector2(0,1),Vector2(-.28,.28),Vector2(-1,0),Vector2(-.28,-.28)]:shape.append(point+offset*radius)
			spark_canvas.draw_colored_polygon(shape,Color(1,.94,.68,sin(progress*PI)*.7))
