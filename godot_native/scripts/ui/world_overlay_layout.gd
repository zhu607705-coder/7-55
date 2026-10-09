extends RefCounted
## Shared screen-space typography and bounds. Never receives world camera zoom.
const BODY_PX:=15
const SPEAKER_PX:=14
const TITLE_PX:=16

static func pixels(physical:float,display_scale:float)->float:
	return physical/maxf(.01,display_scale)

static func font_pixels(physical:int,display_scale:float)->int:
	return maxi(1,ceili(pixels(physical,display_scale)))

static func hud(font:Font,extent:Vector2,display_scale:float,text:String,touch:bool,text_scale:float=1.0)->Dictionary:
	var s:=maxf(.01,display_scale)
	var gap:=pixels(6,s)
	var padding:=pixels(10,s)
	var body_padding:=pixels(12,s)
	var type_scale:=clampf(extent.x*s/960.0,1.0,1.2)
	var body_font:=font_pixels(ceili(BODY_PX*type_scale*text_scale),s)
	var title_font:=font_pixels(ceili((18 if touch else TITLE_PX)*type_scale),s)
	var mode_font:=font_pixels(ceili(SPEAKER_PX*type_scale),s)
	var width:=maxf(1,extent.x-body_padding*2)
	var measured:=font.get_multiline_string_size(text,HORIZONTAL_ALIGNMENT_CENTER,width,body_font)
	var inset:=pixels(8,s)
	var content_height:=measured.y
	var height:=maxf(pixels(34,s),content_height+inset*2)
	var header:=maxf(pixels(44 if touch else 32,s),font.get_height(title_font)+pixels(10,s))
	# Preserve a useful world strip and the real touch targets. Unusually
	# long/enlarged messages retain their text in a bounded scroll surface.
	var budget:=minf(extent.y-header-pixels(124 if touch else 16,s),maxf(font.get_height(body_font)+inset*2,extent.y-header-pixels(188 if touch else 72,s)))
	budget=maxf(inset*2+1,budget)
	var overflow:=height>budget
	if overflow:
		width=maxf(1,width-pixels(14,s))
		content_height=font.get_multiline_string_size(text,HORIZONTAL_ALIGNMENT_CENTER,width,body_font).y
		height=budget
	var mode_width:=font.get_string_size("浅色操作",HORIZONTAL_ALIGNMENT_LEFT,-1,mode_font).x+padding*2
	return {"compact":true,"title_font":title_font,"mode_font":mode_font,"body_font":body_font,"header_height":header,"padding":padding,"body_padding":body_padding,"body_width":width,"body_height":height,"body_content_height":content_height,"body_overflow":overflow,"body_gap":gap,"body_inset":inset,"mode_rect":Rect2(extent.x-mode_width,0,mode_width,header)}

static func dialogue(font:Font,extent:Rect2,display_scale:float,speaker:String,text:String,prompt:String="",text_scale:float=1.0)->Dictionary:
	var s:=maxf(.01,display_scale)
	var padding:=pixels(10,s)
	var gap:=pixels(4,s)
	var width:=minf(pixels(760,s),extent.size.x)
	var inner_width:=maxf(1,width-padding*2)
	var type_scale:=clampf(extent.size.x*s/960.0,1.0,1.2)
	var body_font:=font_pixels(ceili(BODY_PX*type_scale*text_scale),s)
	var speaker_font:=font_pixels(ceili(SPEAKER_PX*type_scale),s)
	var prompt_font:=font_pixels(12,s)
	var speaker_height:=ceilf(font.get_height(speaker_font)) if not speaker.is_empty() else 0.0
	var body_height:=ceilf(font.get_multiline_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,inner_width,body_font).y)
	var prompt_height:=ceilf(font.get_height(prompt_font)) if not prompt.is_empty() else 0.0
	var body_y:=padding+speaker_height+(gap if speaker_height>0 else 0.0)
	var footer:=padding+(prompt_height+gap if prompt_height>0 else 0.0)
	var visible_height:=minf(body_height,maxf(1,extent.size.y-body_y-footer))
	var overflow:=visible_height<body_height
	if overflow:
		inner_width=maxf(1,inner_width-pixels(14,s))
		body_height=ceilf(font.get_multiline_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,inner_width,body_font).y)
	var height:=minf(extent.size.y,body_y+visible_height+footer)
	var top:=maxf(extent.position.y,extent.end.y-height)
	return {"panel":Rect2(extent.position.x+(extent.size.x-width)/2,top,width,height),"speaker":Rect2(padding,padding,inner_width,speaker_height),"body":Rect2(padding,body_y,inner_width,body_height),"body_viewport":Rect2(padding,body_y,width-padding*2,visible_height),"body_overflow":overflow,"prompt":Rect2(padding,body_y+visible_height+gap,inner_width,prompt_height),"body_font":body_font,"speaker_font":speaker_font,"prompt_font":prompt_font}

static func camera_for_safe_rect(player:Vector2,pan:Vector2,extent:Vector2,world_size:Vector2,zoom:float,safe:Rect2)->Vector2:
	var z:=maxf(.01,zoom)
	var offset:Vector2=(extent/2-safe.get_center())/z
	var half:Vector2=safe.size/(2*z)
	var center:=player+pan
	for axis:int in range(2):
		center[axis]=world_size[axis]/2 if world_size[axis]<=half[axis]*2 else clampf(center[axis],half[axis],world_size[axis]-half[axis])
	return center+offset
