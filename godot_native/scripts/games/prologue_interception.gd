extends Control
## Read the moving text, discover the solid error window, and retain its words.
signal finished(result: Dictionary)
signal cancelled
signal presentation_requested(id: String, payload: Dictionary)
const WordModel=preload("res://scripts/games/prologue_word_model.gd")
const SuccessPresentation=preload("res://scripts/ui/checkin_success_view.gd")
const CharacterFlow=preload("res://scripts/games/prologue_character_flow.gd")
const AsciiField=preload("res://scripts/games/prologue_ascii_field.gdshader")
const AsciiAtlas=preload("res://assets/native/prologue_terminal_20261022/ascii_glyph_atlas.png")
const FineAsciiAtlas=preload("res://assets/native/prologue_terminal_20261022/ascii_fine_glyph_atlas.png")
const NativeUi=preload("res://scripts/ui/native_ui_theme.gd")
const DIALOGUE=["旁白：喂！你拽我弹窗干什么？！快松手！要未响应了！", "玩家：帮我补签到！", "玩家：不帮就一起死机！", "旁白：行行行！算你狠！我帮你想办法还不行吗？先把手指挪开！"]
const INK=CharacterFlow.INK
const PAPER=CharacterFlow.PANEL
var phase="success"
var elapsed=0.0
var blocks=0
var misses=0
var paddle=50.0
var orb=Vector2(50,42)
var hold_ms=0.0
var holding=false
var dragging=false
var paused=false
var done=false
var dialogue_index=0
var intro_elapsed_ms=0.0
var intro_segments:Array=[]
var config:Dictionary={}
var resume_button:Button
var field=Rect2()
var display_scale=1.0
var session=WordModel.new()
var content:Dictionary={}
var left_held=false
var right_held=false
var pointer_id=-99
var drag_offset=0.0
var lock_from=Vector2(215,605)
var success_view:Control
var success_continue:Button
var reduced_motion=false
var lock_help_button:Button
var lock_help_open=false
var lock_release_count=0
var field_material:ShaderMaterial
var field_texture:ImageTexture
var text_flow_clock=0.0

func _ready()->void:
	field_material=ShaderMaterial.new();field_material.shader=AsciiField;material=field_material
	field_material.set_shader_parameter("glyph_atlas",AsciiAtlas)
	field_material.set_shader_parameter("fine_glyph_atlas",FineAsciiAtlas)
	field_material.set_shader_parameter("hanzi_masks",CharacterFlow.mask_texture())
	field_material.set_shader_parameter("mask_count",CharacterFlow.mask_texture().get_height()/20.0)
	field_material.set_shader_parameter("flow_cell",CharacterFlow.FLOW_CELL)
	field_material.set_shader_parameter("stroke_cell",CharacterFlow.STROKE_CELL)
	field_material.set_shader_parameter("assembly_duration",CharacterFlow.ASSEMBLY_DURATION)
	field_material.set_shader_parameter("assembly_distance",CharacterFlow.ASSEMBLY_DISTANCE)
	field_material.set_shader_parameter("field_occupancy",CharacterFlow.FIELD_OCCUPANCY)
	field_material.set_shader_parameter("word_cell_size",WordModel.GLYPH_CELL)
	field_material.set_shader_parameter("letter_gap",WordModel.LETTER_GAP)
	var pixel=Image.create(1,1,false,Image.FORMAT_RGBA8);pixel.fill(Color.WHITE)
	field_texture=ImageTexture.create_from_image(pixel)
	var source=JSON.parse_string(FileAccess.get_file_as_string("res://data/source/act-one-bootstrap.content.json"))
	if source is Dictionary:intro_segments=source.get("audioNarration",{}).get("prologue_narrator_intro",{}).get("subtitleSegmentsZh",[])
	content=JSON.parse_string(FileAccess.get_file_as_string("res://data/native/prologue-interception.content.json"))
	mouse_filter=Control.MOUSE_FILTER_STOP;focus_mode=Control.FOCUS_ALL;grab_focus()
	success_view=SuccessPresentation.new();add_child(success_view)
	resume_button=_button("返回字流",_resume)
	resume_button.name="PrologueResume"
	success_continue=_button("收起回执",_continue_success)
	success_continue.name="CheckinSuccessContinue"
	NativeUi.apply_button(success_continue,Color("F4EAD5"),Color("44332D"),Color("A1744E"),0,2,16,Vector2(12,6),Color("44332D"))
	success_continue.add_theme_font_override("font",SuccessPresentation.PIXEL_FONT)
	lock_help_button=_button("键盘帮助",_toggle_lock_help)
	lock_help_button.name="NarratorLockKeyboardHelp"
	get_tree().root.focus_exited.connect(_pause)
	_reset_session()

func _button(text:String,callback:Callable)->Button:
	var button=Button.new();button.text=text;button.pressed.connect(callback);add_child(button)
	NativeUi.apply_button(button,CharacterFlow.PANEL,INK,CharacterFlow.RULE,0,1,16,Vector2(12,6),CharacterFlow.ACCENT)
	return button

func _reset_session()->void:
	for stage:Dictionary in content.get("stages",[]):
		for word:String in stage.targets+stage.distractors:CharacterFlow.word_cells(word)
	session.setup(content)
	session.reading_time_scale=2.0 if reduced_motion else 1.0
	_sync()

func start(request:Dictionary)->void:
	config=request;done=false;paused=false;dialogue_index=0;hold_ms=0;intro_elapsed_ms=0;text_flow_clock=0
	lock_help_open=false;lock_release_count=0
	reduced_motion=bool(request.get("reduced_motion",false))
	_reset_session();_clear_input();_switch("blackout" if request.get("resume",false) else "success")

func _continue_success()->void:
	# This only advances a local visual beat, never the chapter or interception proof.
	if phase!="success" or paused or done:return
	_switch("error");grab_focus()

func _clear_input()->void:
	left_held=false;right_held=false;dragging=false;pointer_id=-99;holding=false
	session.stop_pointer()

func _toggle_lock_help()->void:
	if phase!="lock" or paused or done:return
	lock_help_open=not lock_help_open
	lock_help_button.text="收起键盘帮助" if lock_help_open else "键盘帮助"
	grab_focus();queue_redraw()

func _release_lock()->void:
	if holding and hold_ms>0 and hold_ms<1400:lock_release_count+=1
	holding=false;hold_ms=0

func _lock_feedback()->String:
	if holding and hold_ms>0:return "旁白还在挣扎，那个字却慢慢稳了下来。"
	if lock_release_count>=3:return "它每次刚安静下来，旁白就趁空隙溜走。"
	if lock_release_count==2:return "刚才碰到时，那个字停了一下。"
	if lock_release_count==1:return "差一点，话头又溜走了。"
	return "旁白像是要把最后半句话带走。"

func _pause()->void:
	if paused or done:return
	paused=true;_clear_input()
	if phase=="lock":hold_ms=0
	presentation_requested.emit("prologue_playback_paused",{})

func _resume()->void:
	if not paused or done:return
	paused=false;grab_focus()
	presentation_requested.emit("prologue_playback_resumed",{})

func _exit_tree()->void:
	presentation_requested.emit("prologue_scene_closed",{})
	if get_tree().root.focus_exited.is_connected(_pause):get_tree().root.focus_exited.disconnect(_pause)

func _switch(next:String)->void:
	phase=next;elapsed=0
	if is_instance_valid(success_view):success_view.visible=phase=="success"
	match phase:
		"blackout":presentation_requested.emit("prologue_blackout_started",{"durationMs":7000})
		"deploy":presentation_requested.emit("prologue_narrator_intro",{})
		"lock":
			_clear_input();lock_from=session.cards[0].position if not session.cards.is_empty() else Vector2(session.board_x,605)
			presentation_requested.emit("prologue_error_lock_ready",{"requiredHoldMs":1400})
		"caught":
			dialogue_index=0
			presentation_requested.emit("prologue_narrator_caught",{"blockedCount":blocks,"lockHeldMs":hold_ms})
		"burst":presentation_requested.emit("prologue_white_burst",{})

func _layout_controls()->void:
	display_scale=minf(size.x/430.0,size.y/820.0)
	field=Rect2((size-Vector2(430,820)*display_scale)/2,Vector2(430,820)*display_scale)
	var visible_game=phase in ["deploy","intercept"]
	for button:Button in [resume_button,success_continue,lock_help_button]:
		button.scale=Vector2.ONE*display_scale
	success_view.position=field.position;success_view.scale=Vector2.ONE*display_scale
	success_view.visible=phase=="success"
	success_continue.visible=phase=="success" and (elapsed>=1.8 or reduced_motion) and not paused
	resume_button.text="返回字流" if visible_game else "返回回执" if phase=="success" else "返回交涉" if phase in ["lock","caught"] else "返回剧情"
	lock_help_button.visible=phase=="lock" and not paused
	resume_button.visible=paused
	for item:Array in [[resume_button,Rect2(115,668,200,48)],[success_continue,Rect2(125,704,180,48)],[lock_help_button,Rect2(118,704,194,42)]]:
		var rect:Rect2=item[1];item[0].position=field.position+rect.position*display_scale;item[0].size=rect.size

func _sync()->void:
	blocks=session.completed_stages;misses=session.total_misses;paddle=session.board_x/430.0*100

func _process(delta:float)->void:
	_layout_controls()
	if paused or done:
		if phase=="success":success_view.pose(elapsed,reduced_motion,paused)
		_update_terminal_field();queue_redraw();return
	var dt=clampf(delta,0,.25)
	text_flow_clock+=dt
	elapsed+=dt
	if phase in ["deploy","intercept"]:
		intro_elapsed_ms+=dt*1000
		var result=session.advance(dt,float(right_held)-float(left_held))
		for event:Dictionary in result:
			match event.kind:
				"stage_complete":presentation_requested.emit("prologue_error_intercepted",{"blockedCount":event.completed,"requiredBlocks":3})
				"miss":
					presentation_requested.emit("prologue_error_intercept_missed",{"misses":event.misses,"maxMisses":3})
					if int(event.hint.tier)==3:presentation_requested.emit("prologue_error_round_failed",{"misses":event.misses})
		if session.phase=="hint":
			# Keep the earned collection and the current grip; re-emit missing words.
			var target=session.board_target
			session.continue_stage()
			session.set_target(target)
		_sync()
		if session.phase=="complete":_switch("lock")
		else:phase="deploy" if session.phase=="clue" else "intercept"
	else:
		match phase:
			"success":
				if elapsed>=SuccessPresentation.DURATION:_switch("error")
			"error":
				if elapsed>=1.9:_switch("red")
			"red":
				if elapsed>=.35:_switch("blackout")
			"blackout":
				if elapsed>=7:_switch("deploy")
			"lock":
				if holding:
					hold_ms=minf(1400,hold_ms+dt*1000)
					if hold_ms>=1400:holding=false;_switch("caught")
			"caught":
				var previous=dialogue_index
				dialogue_index=3 if elapsed>=5.2 else 2 if elapsed>=4.1 else 1 if elapsed>=3 else 0
				if dialogue_index==3 and previous!=3:presentation_requested.emit("prologue_narrator_bargain",{})
				if elapsed>=8.9:_switch("burst")
			"burst":
				if elapsed>=.95:_switch("whiteout")
			"whiteout":
				if elapsed>=.7:
					done=true
					finished.emit({"interceptedCount":blocks,"lockHeldMs":hold_ms,"failed":false,"dialogueCount":4,"whiteoutCompleted":true})
	if phase=="success":success_view.pose(elapsed,reduced_motion,paused)
	_update_terminal_field();queue_redraw()

func _logical(point:Vector2)->Vector2:return (point-field.position)/maxf(.0001,display_scale)
func _position(percent:Vector2)->Vector2:return field.position+field.size*percent/100
func board_center()->Vector2:return field.position+Vector2(session.board_x,WordModel.BOARD_Y)*display_scale
func _lock_center()->Vector2:return lock_from.lerp(Vector2(215,352),clampf(elapsed/.55,0,1))

func _gui_input(event:InputEvent)->void:
	if paused:return
	if event is InputEventKey and not event.echo:
		var code=event.physical_keycode if event.physical_keycode else event.keycode
		if code in [KEY_SPACE,KEY_ENTER] and phase=="success":
			if event.pressed:_continue_success()
			accept_event()
		elif code in [KEY_A,KEY_LEFT]:left_held=event.pressed;accept_event()
		elif code in [KEY_D,KEY_RIGHT]:right_held=event.pressed;accept_event()
		elif code in [KEY_SPACE,KEY_ENTER] and phase=="lock":
			if event.pressed:holding=true
			else:_release_lock()
			accept_event()
		elif code==KEY_ESCAPE and event.pressed:_pause();accept_event()
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		_pointer_begin(event.position,-1) if event.pressed else _pointer_end(-1)
		accept_event()
	elif event is InputEventScreenTouch:
		if event.pressed and not event.canceled:_pointer_begin(event.position,event.index)
		else:_pointer_end(event.index)
		accept_event()
	elif event is InputEventMouseMotion and dragging and pointer_id==-1:_pointer_move(event.position);accept_event()
	elif event is InputEventScreenDrag and dragging and pointer_id==event.index:_pointer_move(event.position);accept_event()

func _pointer_begin(point:Vector2,id:int)->void:
	if session.reviewing or pointer_id!=-99:return
	var local=_logical(point)
	if phase=="lock":
		if local.distance_to(_lock_center())<=58:holding=true;pointer_id=id
	elif phase in ["deploy","intercept"]:
		var board_point=(local-Vector2(session.board_x,WordModel.BOARD_Y)).rotated(-session.board_angle)
		if Rect2(-WordModel.BOARD_SIZE/2,WordModel.BOARD_SIZE).has_point(board_point):
			dragging=true;pointer_id=id;drag_offset=local.x-session.board_x;grab_focus()

func _pointer_move(point:Vector2)->void:
	if dragging and not session.reviewing:session.set_target(_logical(point).x-drag_offset)

func _pointer_end(id:int)->void:
	if id!=pointer_id:return
	pointer_id=-99;dragging=false;session.stop_pointer()
	if phase=="lock":_release_lock()
	else:holding=false

func _pointer(point:Vector2,down:bool)->void:
	if down:
		if dragging:_pointer_move(point)
		else:_pointer_begin(point,-1)
	else:_pointer_end(-1)

func _text(text:String,y:float,color:Color=INK,font_size:int=20,width:float=386,balanced:bool=false)->void:
	var font=get_theme_default_font();var lines:Array=[]
	for paragraph:String in text.split("\n"):
		var line=""
		var limit=width
		if balanced:
			var full_width=font.get_string_size(paragraph,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
			var line_count=maxi(1,ceili(full_width/width))
			if line_count>1:limit=minf(width,full_width/line_count+font_size*.5)
		for i:int in paragraph.length():
			var next=line+paragraph.substr(i,1)
			var closing=paragraph.substr(i,1) in "，。！？；：、）】》”’…"
			if font.get_string_size(next,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x>limit and not line.is_empty() and not (balanced and closing):lines.append(line);line=paragraph.substr(i,1)
			else:line=next
		lines.append(line)
	for i:int in lines.size():
		var measured=font.get_string_size(lines[i],HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
		draw_string(font,Vector2((430-measured)/2,y+i*(font_size+8)),lines[i],HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)

func _narration_card(text:String,y:float,height:float,speaker:String,font_size:int=20)->void:
	# Quiet terminal output is readable independently from the moving ASCII field.
	var box=Rect2(22,y,386,height)
	draw_rect(box,PAPER)
	draw_line(Vector2(38,y+36),Vector2(392,y+36),CharacterFlow.RULE,1)
	_text(speaker,y+24,CharacterFlow.MUTED,14)
	_text(text,y+64,INK,font_size,348,true)

func _retained_words(y:float)->void:
	# Keep each earned word intact; these are records of actual contacts, not
	# advance answers or another puzzle-completion authority.
	var font=get_theme_default_font();var width=0.0;var words:Array=[]
	for capture:Dictionary in session.captures:
		var word=str(capture.word)
		var extent=font.get_string_size(word,HORIZONTAL_ALIGNMENT_LEFT,-1,17).x+16
		words.append({"word":word,"width":extent});width+=extent
	width+=maxi(0,words.size()-1)*6
	_text("已留下",y-16,CharacterFlow.MUTED,14)
	var x=(430-width)/2
	for word:Dictionary in words:
		draw_rect(Rect2(x,y,word.width,34),PAPER)
		draw_rect(Rect2(x,y,word.width,34),CharacterFlow.RULE,false,1)
		draw_string(font,Vector2(x+8,y+23),word.word,HORIZONTAL_ALIGNMENT_LEFT,-1,17,INK)
		x+=word.width+6

func _update_terminal_field()->void:
	var bodies=PackedVector4Array();bodies.resize(CharacterFlow.WORD_SLOTS)
	var symbols=PackedVector4Array();symbols.resize(CharacterFlow.WORD_SLOTS)
	var styles=PackedVector4Array();styles.resize(CharacterFlow.WORD_SLOTS)
	var more=PackedVector2Array();more.resize(CharacterFlow.WORD_SLOTS)
	var index=0
	if phase=="lock":
		var center=_lock_center()
		var struggle=sin(elapsed*(24 if holding else 5))*(3.0*(1.0-hold_ms/1400) if holding else 1.3)
		var ids=CharacterFlow.mask_indices("话")
		bodies[0]=Vector4(center.x+struggle,center.y,1,1)
		symbols[0]=Vector4(ids.x,ids.y,1,0);styles[0]=Vector4(elapsed,1,0,0)
	elif phase in ["deploy","intercept"]:
		for card:Dictionary in session.cards:
			if index>=2:break
			if not WordModel.ARENA.intersects(Rect2(card.position-card.size/2,card.size)):continue
			var opacity=clampf(session.transition_left/WordModel.STAGE_TRANSITION,0,1) if card.resolved and session.transition_left>0 else 1.0
			var ids=CharacterFlow.mask_indices(card.text)
			bodies[index]=Vector4(card.position.x,card.position.y,card.text.length(),opacity)
			symbols[index]=Vector4(ids.x,ids.y,cos(card.angle),sin(card.angle))
			styles[index]=Vector4(card.age,1,0,0);index+=1

	if phase in ["deploy","intercept"] and not reduced_motion:
		index=CharacterFlow.PHYSICAL_SLOTS
		for cloud:Dictionary in CharacterFlow.cloud_words(session.current().get("fragments",[]),text_flow_clock):
			if index>=CharacterFlow.PHYSICAL_SLOTS+CharacterFlow.CLUE_SLOTS:break
			var ids=CharacterFlow.mask_letters(cloud.text)
			bodies[index]=Vector4(cloud.position.x,cloud.position.y,cloud.text.length(),cloud.alpha)
			symbols[index]=Vector4(ids.x,ids.y,cos(cloud.angle),sin(cloud.angle));more[index]=Vector2(ids.z,ids.w)
			styles[index]=Vector4(cloud.age,cloud.scale,0,0);index+=1
		index=CharacterFlow.PHYSICAL_SLOTS+CharacterFlow.CLUE_SLOTS
		for cloud:Dictionary in CharacterFlow.ambient_words(text_flow_clock,session.stage):
			if index>=CharacterFlow.WORD_SLOTS:break
			var ids=CharacterFlow.mask_letters(cloud.text)
			bodies[index]=Vector4(cloud.position.x,cloud.position.y,cloud.text.length(),cloud.alpha)
			symbols[index]=Vector4(ids.x,ids.y,cos(cloud.angle),sin(cloud.angle));more[index]=Vector2(ids.z,ids.w)
			styles[index]=Vector4(cloud.age,cloud.scale,0,0);index+=1
	field_material.set_shader_parameter("field_rect",Vector4(CharacterFlow.FIELD_RECT.position.x,CharacterFlow.FIELD_RECT.position.y,CharacterFlow.FIELD_RECT.size.x,CharacterFlow.FIELD_RECT.size.y))
	field_material.set_shader_parameter("word_more",more)
	field_material.set_shader_parameter("flow_clock",text_flow_clock)
	field_material.set_shader_parameter("reduced_motion",reduced_motion)
	field_material.set_shader_parameter("word_data",bodies)
	field_material.set_shader_parameter("word_symbols",symbols)
	field_material.set_shader_parameter("word_style",styles)

func _draw_character_flow()->void:
	draw_texture_rect(field_texture,CharacterFlow.FIELD_RECT,false,Color.MAGENTA)

func _draw_terminal_window(center:Vector2,extent:Vector2,angle:float=0)->void:
	var half=extent/2
	draw_set_transform(field.position+center*display_scale,angle,Vector2.ONE*display_scale)
	draw_rect(Rect2(-half,extent),PAPER)
	draw_rect(Rect2(-half,Vector2(extent.x,18)),Color("10212B"))
	draw_rect(Rect2(-half,extent),CharacterFlow.ACCENT,false,1)
	var font=SuccessPresentation.PIXEL_FONT
	draw_string(font,Vector2(-half.x+9,-half.y+13),"! ERROR",HORIZONTAL_ALIGNMENT_LEFT,-1,12,CharacterFlow.ACCENT)
	draw_line(Vector2(-half.x+8,-half.y+18),Vector2(half.x-8,-half.y+18),CharacterFlow.RULE,1)
	var text="经度与纬度不存在"
	var width=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x
	draw_string(font,Vector2(-width/2,13),text,HORIZONTAL_ALIGNMENT_LEFT,-1,14,INK)
	draw_set_transform(field.position,0,Vector2.ONE*display_scale)

func _draw_board()->void:
	_draw_terminal_window(Vector2(session.board_x,WordModel.BOARD_Y),WordModel.BOARD_SIZE,session.board_angle)

func _draw()->void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("e8e1d0") if phase=="success" else CharacterFlow.BACKGROUND)
	if phase=="blackout":draw_rect(Rect2(Vector2.ZERO,size),Color.BLACK);return
	if phase=="red":
		var shade=CharacterFlow.BACKGROUND.lerp(Color("371A25"),smoothstep(0.0,.35,elapsed))
		draw_rect(Rect2(Vector2.ZERO,size),shade);return
	if phase in ["burst","whiteout"]:
		draw_rect(Rect2(Vector2.ZERO,size),Color.WHITE if phase=="whiteout" else CharacterFlow.BACKGROUND.lerp(Color.WHITE,CharacterFlow.burst_opacity(elapsed)))
		return
	draw_set_transform(field.position,0,Vector2.ONE*display_scale)
	if phase=="success":pass # Independent child objects render the accepted receipt.
	elif phase=="error":
		_draw_terminal_window(Vector2(215,400),Vector2(310,86))
	else:
		if phase in ["deploy","intercept","lock","caught"]:_draw_character_flow()
		if phase in ["deploy","intercept"]:
			# Original voiced narration owns this lane; puzzle fragments never add speech.
			if intro_segments.size()>=3 and intro_elapsed_ms<8500:
				var index=2 if intro_elapsed_ms>=6800 else 1 if intro_elapsed_ms>=3400 else 0
				_narration_card(str(intro_segments[index]),98,112,"旁白",18)
			if not session.captures.is_empty():_text("已留下："+" · ".join(session.captures.map(func(c):return c.word)),219,INK,17)
			for contact:Dictionary in session.contacts:
				var age=session.clock-float(contact.time)
				if age<.22:draw_line(contact.point-Vector2(9+age*30,0),contact.point+Vector2(9+age*30,0),Color(INK,1-age/.22),2)
			_draw_board()
			if reduced_motion and phase=="deploy":
				var fragments:Array=session.current().get("fragments",[])
				for i:int in fragments.size():_text(str(fragments[i]),337+i*56,INK,23)
		elif phase=="lock":
			_narration_card(_lock_feedback(),110,126,"眼前的字",20)
			var center=_lock_center()
			draw_arc(center,55,0,TAU,64,CharacterFlow.RULE,1)
			draw_arc(center,62,-PI/2,-PI/2+TAU*hold_ms/1400,60,CharacterFlow.ACCENT,3)
			if elapsed>=.55 and not session.captures.is_empty():_retained_words(520)
			if lock_help_open:_text("空格 / Enter 与触碰圆圈等效。\n按键状态会同步到这个字。",624,CharacterFlow.MUTED,15)
		elif phase=="caught":
			var line:String=DIALOGUE[dialogue_index]
			var colon=line.find("：")
			_narration_card(line.substr(colon+1),286,206,line.left(colon),23)
	if paused:
		draw_rect(Rect2(30,540,370,190),PAPER)
		_text("已暂停",582,INK,25)
		_text("文字已停住，已留下的字仍在。" if phase in ["deploy","intercept"] else "这一段停在这里。",624,INK,17)
	draw_set_transform(Vector2.ZERO)
