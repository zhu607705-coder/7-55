extends RefCounted
## Shared screen-space typography and bounds. Never receives world camera zoom.
const BODY_PX:=16
const SPEAKER_PX:=14
const TITLE_PX:=16
const UI_REFERENCE_SIZE:=Vector2(1280,720)
const MIN_UI_SCALE:=.8

static func ui_scale(display_extent:Vector2)->float:
	# Scale with the fitted game surface. Keep a legible floor in a small letterbox.
	return ui_units(display_extent,1.0)

static func ui_units(extent:Vector2,display_scale:float)->float:
	return maxf(MIN_UI_SCALE/maxf(.01,display_scale),minf(extent.x/UI_REFERENCE_SIZE.x,extent.y/UI_REFERENCE_SIZE.y))

static func pixels(physical:float,display_scale:float)->float:
	return physical/maxf(.01,display_scale)

static func font_pixels(physical:int,display_scale:float)->int:
	return maxi(1,ceili(pixels(physical,display_scale)))

static func hud(font:Font,extent:Vector2,display_scale:float,text:String,touch:bool,text_scale:float=1.0,body_px:int=BODY_PX)->Dictionary:
	var s:=maxf(.01,display_scale)
	var unit:=ui_units(extent,s)
	var gap:=6*unit
	var padding:=10*unit
	var body_padding:=12*unit
	var body_font:=maxi(1,ceili(body_px*unit*text_scale))
	var title_font:=maxi(1,ceili((18 if touch else TITLE_PX)*unit))
	var mode_font:=maxi(1,ceili(SPEAKER_PX*unit))
	var available_width:=maxf(1,minf(extent.x-body_padding*2,680*unit))
	var natural_width:=maxf(220*unit,font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,body_font).x)
	var width:=minf(available_width,natural_width)
	var measured:=font.get_multiline_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,width,body_font)
	var inset:=8*unit
	var content_height:=measured.y
	var height:=maxf((44 if touch else 34)*unit,content_height+inset*2)
	var header:=maxf((44 if touch else 32)*unit,font.get_height(title_font)+10*unit)
	# A long caption keeps the scene usable. Its complete text remains in the
	# existing scroll surface instead of taking over the visible map.
	var budget:=minf(extent.y/3.0,extent.y-header-96*unit)
	budget=maxf(inset*2+1,budget)
	var overflow:=height>budget
	if overflow:
		width=maxf(1,width-14*unit)
		content_height=font.get_multiline_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,width,body_font).y
		height=budget
	var mode_width:=font.get_string_size("浅色模式",HORIZONTAL_ALIGNMENT_LEFT,-1,mode_font).x+padding*2
	return {"compact":true,"title_font":title_font,"mode_font":mode_font,"body_font":body_font,"header_height":header,"padding":padding,"body_padding":body_padding,"body_width":width,"body_height":height,"body_content_height":content_height,"body_overflow":overflow,"body_gap":gap,"body_inset":inset,"mode_rect":Rect2(extent.x-mode_width,0,mode_width,header)}

static func dialogue(font:Font,extent:Rect2,display_scale:float,speaker:String,text:String,prompt:String="",text_scale:float=1.0)->Dictionary:
	var s:=maxf(.01,display_scale)
	var unit:=ui_units(extent.size,s)
	var padding:=10*unit
	var gap:=4*unit
	var width:=minf(760*unit,extent.size.x)
	var inner_width:=maxf(1,width-padding*2)
	var body_font:=maxi(1,ceili(BODY_PX*unit*text_scale))
	var speaker_font:=maxi(1,ceili(SPEAKER_PX*unit))
	var prompt_font:=maxi(1,ceili(12*unit))
	var speaker_height:=ceilf(font.get_height(speaker_font)) if not speaker.is_empty() else 0.0
	var body_height:=ceilf(font.get_multiline_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,inner_width,body_font).y)
	var prompt_height:=ceilf(font.get_height(prompt_font)) if not prompt.is_empty() else 0.0
	var body_y:=padding+speaker_height+(gap if speaker_height>0 else 0.0)
	var footer:=padding+(prompt_height+gap if prompt_height>0 else 0.0)
	var visible_height:=minf(body_height,maxf(1,extent.size.y-body_y-footer))
	var overflow:=visible_height<body_height
	if overflow:
		inner_width=maxf(1,inner_width-14*unit)
		body_height=ceilf(font.get_multiline_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,inner_width,body_font).y)
	var height:=minf(extent.size.y,body_y+visible_height+footer)
	var top:=maxf(extent.position.y,extent.end.y-height)
	return {"panel":Rect2(extent.position.x+(extent.size.x-width)/2,top,width,height),"speaker":Rect2(padding,padding,inner_width,speaker_height),"body":Rect2(padding,body_y,inner_width,body_height),"body_viewport":Rect2(padding,body_y,width-padding*2,visible_height),"body_overflow":overflow,"prompt":Rect2(padding,body_y+visible_height+gap,inner_width,prompt_height),"body_font":body_font,"speaker_font":speaker_font,"prompt_font":prompt_font}

static func camera_for_safe_rect(player:Vector2,pan:Vector2,extent:Vector2,world_size:Vector2,zoom:float,safe:Rect2)->Vector2:
	var z:=maxf(.01,zoom)
	var target:=player+pan
	var camera:=target
	for axis:int in range(2):
		var full_half:float=extent[axis]/(2*z)
		if world_size[axis]<=full_half*2:
			var half:float=safe.size[axis]/(2*z)
			var offset:float=(extent[axis]/2-safe.get_center()[axis])/z
			camera[axis]=(world_size[axis]/2 if world_size[axis]<=half*2 else clampf(target[axis],half,world_size[axis]-half))+offset
			continue
		var far:float=world_size[axis]-full_half
		# Keep original follow in the interior. Ease in the HUD offset before
		# reaching either original map bound, rather than jumping at that bound.
		var fade:float=maxf(.0001,minf(full_half,(far-full_half)/2))
		var near_weight:float=clampf((full_half+fade-target[axis])/fade,0,1)
		var far_weight:float=clampf((target[axis]-(far-fade))/fade,0,1)
		camera[axis]=clampf(target[axis],full_half,far)-safe.position[axis]/z*near_weight+(extent[axis]-safe.end[axis])/z*far_weight
	return camera
