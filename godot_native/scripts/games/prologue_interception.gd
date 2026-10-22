extends Control
## Read the moving text, discover the solid error window, and retain its words.
signal finished(result: Dictionary)
signal cancelled
signal presentation_requested(id: String, payload: Dictionary)
const WordModel=preload("res://scripts/games/prologue_word_model.gd")
const SuccessPresentation=preload("res://scripts/ui/checkin_success_view.gd")
const NativeUi=preload("res://scripts/ui/native_ui_theme.gd")
const DIALOGUE=["旁白：喂！你拽我弹窗干什么？！快松手！要未响应了！", "玩家：帮我补签到！", "玩家：不帮就一起死机！", "旁白：行行行！算你狠！我帮你想办法还不行吗？先把手指挪开！"]
const INK=Color("354243")
const PAPER=Color("f6efdc")
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
var retry:Button
var resume_button:Button
var review_button:Button
var close_review:Button
var help_button:Button
var field=Rect2()
var display_scale=1.0
var session=WordModel.new()
var content:Dictionary={}
var left_held=false
var right_held=false
var pointer_id=-99
var drag_offset=0.0
var show_landing=false
var lock_from=Vector2(215,605)
var success_view:Control
var success_continue:Button
var reduced_motion=false
var lock_help_button:Button
var lock_help_open=false
var lock_release_count=0

func _ready()->void:
	var source=JSON.parse_string(FileAccess.get_file_as_string("res://data/source/act-one-bootstrap.content.json"))
	if source is Dictionary:intro_segments=source.get("audioNarration",{}).get("prologue_narrator_intro",{}).get("subtitleSegmentsZh",[])
	content=JSON.parse_string(FileAccess.get_file_as_string("res://data/native/prologue-interception.content.json"))
	mouse_filter=Control.MOUSE_FILTER_STOP;focus_mode=Control.FOCUS_ALL;grab_focus()
	success_view=SuccessPresentation.new();add_child(success_view)
	retry=_button("继续当前阶段",_retry)
	resume_button=_button("继续",_resume)
	review_button=_button("重看完整线索",func():_review(true))
	close_review=_button("继续寻找",func():_review(false))
	help_button=_button("显示落点帮助",func():show_landing=not show_landing;queue_redraw())
	success_continue=_button("继续",_continue_success)
	success_continue.name="CheckinSuccessContinue"
	NativeUi.apply_button(success_continue,Color("f8f8ef"),Color("193f38"),Color("b9cbbd"),24,1,14,Vector2(12,6),Color("193f38"))
	lock_help_button=_button("键盘帮助",_toggle_lock_help)
	lock_help_button.name="NarratorLockKeyboardHelp"
	get_tree().root.focus_exited.connect(_pause)
	_reset_session()

func _button(text:String,callback:Callable)->Button:
	var button=Button.new();button.text=text;button.pressed.connect(callback);add_child(button)
	return button

func _reset_session()->void:
	var widths:Dictionary={}
	for stage:Dictionary in content.get("stages",[]):
		for word:String in stage.targets+stage.distractors:widths[word]=get_theme_default_font().get_string_size(word,HORIZONTAL_ALIGNMENT_LEFT,-1,WordModel.FONT_SIZE).x
	session.setup(content,widths)
	_sync()

func start(request:Dictionary)->void:
	config=request;done=false;paused=false;dialogue_index=0;hold_ms=0;intro_elapsed_ms=0
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
	if not session.reviewing:presentation_requested.emit("prologue_playback_resumed",{})

func _exit_tree()->void:
	presentation_requested.emit("prologue_scene_closed",{})
	if get_tree().root.focus_exited.is_connected(_pause):get_tree().root.focus_exited.disconnect(_pause)

func _review(value:bool)->void:
	if not phase in ["deploy","intercept","failed"] or paused:return
	_clear_input();session.set_review(value);grab_focus()
	presentation_requested.emit("prologue_playback_paused" if value else "prologue_playback_resumed",{})
	queue_redraw()

func _retry()->void:
	if phase!="failed":return
	_clear_input();session.set_review(false);session.continue_stage();show_landing=false
	phase="intercept";elapsed=0;grab_focus();_sync()

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
	var visible_game=phase in ["deploy","intercept","failed"]
	for button:Button in [retry,resume_button,review_button,close_review,help_button,success_continue,lock_help_button]:
		button.scale=Vector2.ONE*display_scale
	success_view.position=field.position;success_view.scale=Vector2.ONE*display_scale
	success_view.visible=phase=="success"
	success_continue.visible=phase=="success" and not paused
	lock_help_button.visible=phase=="lock" and not paused
	retry.visible=phase=="failed" and not paused and not session.reviewing
	resume_button.visible=paused
	review_button.visible=visible_game and not paused and not session.reviewing
	close_review.visible=visible_game and session.reviewing and not paused
	help_button.visible=phase=="failed" and int(session.hint.get("tier",0))>=3 and not paused and not session.reviewing
	for item:Array in [[retry,Rect2(86,568,258,48)],[resume_button,Rect2(115,460,200,48)],[review_button,Rect2(118,768,194,38)],[close_review,Rect2(86,618,258,48)],[help_button,Rect2(86,514,258,38)],[success_continue,Rect2(125,704,180,48)],[lock_help_button,Rect2(118,704,194,42)]]:
		var rect:Rect2=item[1];item[0].position=field.position+rect.position*display_scale;item[0].size=rect.size

func _sync()->void:
	blocks=session.completed_stages;misses=session.total_misses;paddle=session.board_x/430.0*100

func _process(delta:float)->void:
	_layout_controls()
	if paused or done:
		if phase=="success":success_view.pose(elapsed,reduced_motion,paused)
		queue_redraw();return
	var dt=clampf(delta,0,.25)
	elapsed+=dt
	if phase in ["deploy","intercept","failed"]:
		if not session.reviewing and phase!="failed":intro_elapsed_ms+=dt*1000
		var result=session.advance(dt,float(right_held)-float(left_held))
		for event:Dictionary in result:
			match event.kind:
				"stage_complete":presentation_requested.emit("prologue_error_intercepted",{"blockedCount":event.completed,"requiredBlocks":3})
				"miss":
					_clear_input();show_landing=false
					presentation_requested.emit("prologue_error_intercept_missed",{"misses":event.misses,"maxMisses":3})
					if int(event.hint.tier)==3:presentation_requested.emit("prologue_error_round_failed",{"misses":event.misses})
		_sync()
		if session.phase=="complete":_switch("lock")
		else:phase="failed" if session.phase=="hint" else "deploy" if session.phase=="clue" else "intercept"
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
	queue_redraw()

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
		elif code==KEY_R and event.pressed and phase in ["deploy","intercept","failed"]:_review(not session.reviewing);accept_event()
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
	# A paper dialogue lane gives the authored line a clear entry point without
	# covering the word arena or adding a second system-message surface.
	var box=Rect2(22,y,386,height)
	draw_rect(Rect2(box.position+Vector2(3,4),box.size),Color("354243",.20))
	draw_rect(box,Color("fcf6e6"));draw_rect(box,INK,false,2)
	draw_line(Vector2(38,y+36),Vector2(392,y+36),Color("cdc4ae"),1)
	_text(speaker,y+24,Color("697268"),14)
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
	_text("已留下",y-16,Color("697268"),14)
	var x=(430-width)/2
	for word:Dictionary in words:
		draw_rect(Rect2(x,y,word.width,34),Color("f8f3e5"))
		draw_rect(Rect2(x,y,word.width,34),Color("b6b7a8"),false,1)
		draw_string(font,Vector2(x+8,y+23),word.word,HORIZONTAL_ALIGNMENT_LEFT,-1,17,INK)
		x+=word.width+6

func _word(text:String,center:Vector2,extent:Vector2,angle:float,color:Color=PAPER)->void:
	var polygon=WordModel.polygon(center,extent/2,angle)
	var shadow=WordModel.polygon(center+Vector2(4,7),extent/2,angle)
	draw_colored_polygon(shadow,Color("65706a",.17*color.a));draw_colored_polygon(polygon,color)
	var outline=polygon.duplicate();outline.append(polygon[0]);draw_polyline(outline,Color("73746a",color.a),1.5,true)
	draw_set_transform(field.position+center*display_scale,angle,Vector2.ONE*display_scale)
	var font=get_theme_default_font();var measured=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,24).x
	draw_string(font,Vector2(-measured/2,8),text,HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color(INK,color.a))
	draw_set_transform(field.position,0,Vector2.ONE*display_scale)

func _draw_board()->void:
	var center=Vector2(session.board_x,WordModel.BOARD_Y)
	var half=WordModel.BOARD_SIZE/2
	draw_colored_polygon(WordModel.polygon(center+Vector2(4,10),half,session.board_angle),Color("65706a",.20))
	draw_colored_polygon(WordModel.polygon(center+Vector2(0,6),half,session.board_angle),Color("9b8580"))
	draw_set_transform(field.position+center*display_scale,session.board_angle,Vector2.ONE*display_scale)
	draw_rect(Rect2(-half,WordModel.BOARD_SIZE),Color("f4e2df"))
	draw_rect(Rect2(-half,Vector2(164,18)),Color("dfbabb"))
	draw_rect(Rect2(-half,WordModel.BOARD_SIZE),Color("9b5f66"),false,2)
	var font=get_theme_default_font()
	draw_string(font,Vector2(-69,-15),"位置错误",HORIZONTAL_ALIGNMENT_LEFT,-1,11,INK)
	draw_string(font,Vector2(66,-15),"×",HORIZONTAL_ALIGNMENT_LEFT,-1,11,INK)
	var text="经度与纬度不存在"
	var width=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x
	draw_string(font,Vector2(-width/2,13),text,HORIZONTAL_ALIGNMENT_LEFT,-1,14,INK)
	draw_set_transform(field.position,0,Vector2.ONE*display_scale)

func hint_text()->String:
	var hint=session.hint;var reason=str(hint.get("reason","late"));var tier=int(hint.get("tier",1))
	var text={"unmoved":"字从窗口旁边离开了。\n窗口还留在原来的位置。","meaning":"刚才留下的是“%s”。\n它不符合这段话的要求。"%hint.get("word",""),"order":"这一段来得太早了。\n原句的先后还没有接上。","wrong_side":"窗口还在另一侧。\n这块字从旁边离开了。","late":"目标已经越过窗口。\n刚才的移动晚了一点。"}.get(reason,"")
	if tier>=2:
		text+="\n\n"+["前后的文字都在说“留下”。\n窗口的标题栏可以拖动。","需要留下两个坐标名称，先后不限。\n拖动窗口，让它们碰到窗沿。","按原句先后接回三段。\n拖动窗口，已有的字会保留。"][session.stage]
	if tier>=3:
		text+="\n\n"+("下一段："+str(session.missing()[0]) if session.current().get("ordered",false) else "还缺："+"、".join(session.missing()))
	return text

func _draw()->void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("e8e1d0"))
	if phase=="blackout":draw_rect(Rect2(Vector2.ZERO,size),Color.BLACK);return
	if phase=="red":draw_rect(Rect2(Vector2.ZERO,size),Color("ef223d"));return
	if phase in ["burst","whiteout"]:
		if phase=="whiteout" or int(elapsed*18)%2==0:draw_rect(Rect2(Vector2.ZERO,size),Color.WHITE)
		return
	draw_set_transform(field.position,0,Vector2.ONE*display_scale)
	if phase=="success":pass # Independent child objects render the accepted receipt.
	elif phase=="error":
		draw_rect(Rect2(30,330,370,140),PAPER);_text("经度与纬度不存在",400,INK,25)
	else:
		_text("经度与纬度不存在",38,Color("963f4b"),24)
		_text("第 %d / 3 段"%mini(3,blocks+1),72,INK,17)
		if phase in ["deploy","intercept","failed"]:
			# Original voiced narration owns this lane; puzzle fragments never add speech.
			if intro_segments.size()>=3 and intro_elapsed_ms<8500:
				var index=2 if intro_elapsed_ms>=6800 else 1 if intro_elapsed_ms>=3400 else 0
				_narration_card(str(intro_segments[index]),98,112,"旁白",18)
			if not session.captures.is_empty():_text("已留下："+" · ".join(session.captures.map(func(c):return c.word)),219,INK,17)
			draw_rect(WordModel.ARENA,Color("ece7d9"));draw_rect(WordModel.ARENA,Color("b6b7a8"),false,2)
			_text("字句还在向外走",732,Color("787b70"),14)
			_draw_board()
			for card:Dictionary in session.cards:
				var color=Color("fff9e7") if not card.resolved else Color("e2ead3",clampf(session.transition_left/.65,0,1) if session.transition_left>0 else 1)
				_word(card.text,card.position,card.size,card.angle,color)
			for contact:Dictionary in session.contacts:
				var age=session.clock-float(contact.time)
				if age<.22:draw_arc(contact.point,8+age*30,0,TAU,24,Color(.72,.24,.29,1-age/.22),2,true)
			if show_landing and not session.missing().is_empty():
				var x=clampf(float(session.hint.get("landing_x",215)),60,370)
				draw_line(Vector2(x,626),Vector2(x,643),Color("a76c43"),2,true)
				draw_circle(Vector2(x,629),4,Color("a76c43"))
			if phase=="deploy" or session.reviewing:
				draw_rect(Rect2(30,282,370,318 if session.reviewing else 260),PAPER)
				var fragments:Array=session.current().get("fragments",[])
				if session.reviewing:
					for i:int in fragments.size():_text(str(fragments[i]),337+i*56,INK,23)
				else:
					var at=session.clue_index()
					for i:int in range(maxi(0,at-2),at+1):_text(str(fragments[i]),440+(i-at)*44,INK if i==at else Color("83887a"),24 if i==at else 19)
			elif phase=="failed":
				draw_rect(Rect2(30,275,370,350),PAPER)
				_text("刚才这一下",313,Color("963f4b"),24)
				_text(hint_text(),344,INK,17)
		elif phase=="lock":
			_narration_card(_lock_feedback(),110,126,"眼前的字",20)
			var center=_lock_center()
			draw_circle(center,55,Color("ad414a"));draw_arc(center,62,-PI/2,-PI/2+TAU*hold_ms/1400,60,Color("a8782b"),5)
			var struggle=sin(elapsed*(24 if holding else 5))*(3.0*(1.0-hold_ms/1400) if holding else 1.3)
			var font=get_theme_default_font();var glyph_width=font.get_string_size("话",HORIZONTAL_ALIGNMENT_LEFT,-1,32).x
			draw_string(font,center+Vector2(-glyph_width/2+struggle,11),"话",HORIZONTAL_ALIGNMENT_LEFT,-1,32,PAPER)
			if elapsed>=.55 and not session.captures.is_empty():_retained_words(520)
			if lock_help_open:_text("空格 / Enter 与触碰圆圈等效。\n按键状态会同步到这个字。",624,Color("637067"),15)
		elif phase=="caught":
			var line:String=DIALOGUE[dialogue_index]
			var colon=line.find("：")
			_narration_card(line.substr(colon+1),286,206,line.left(colon),23)
	if paused:
		draw_rect(Rect2(30,300,370,230),PAPER);_text("已暂停",380,INK,28)
	draw_set_transform(Vector2.ZERO)
