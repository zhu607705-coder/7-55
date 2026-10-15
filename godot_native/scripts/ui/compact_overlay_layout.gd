extends RefCounted
## Screen-space UI metrics only; the 960x540 playfield, projection and inputs
## remain in source coordinates. CSS reference: rpg.css compact stunt rules.
static func font_size(base: int, physical_floor: int, display_scale: float) -> int:
	return maxi(base,ceili(float(physical_floor)/maxf(display_scale,0.01)))

static func to_local(rect: Rect2, origin: Vector2, display_scale: float) -> Rect2:
	return Rect2((rect.position-origin)/display_scale,rect.size/display_scale)

static func chase(viewport: Vector2, origin: Vector2, display_scale: float) -> Dictionary:
	var enabled := viewport.x < 700 and viewport.y > viewport.x and display_scale < 0.7
	if not enabled: return {"compact":false}
	var playfield := Rect2(origin,Vector2(960,540)*display_scale)
	var width := minf(viewport.x-24.0,480.0)
	var left := (viewport.x-width)/2.0
	var header := Rect2(left,maxf(12.0,playfield.position.y-118.0),width,110.0)
	var toolbar_y := header.position.y+34.0
	var toolbar_width := (width-28.0)/3.0
	var row := Rect2(left,playfield.end.y+8.0,width,52.0)
	var hint_y := row.end.y+8.0
	var hint_height := minf(84.0,viewport.y-12.0-hint_y)
	var modal := Rect2(left+6.0,playfield.get_center().y-82.0,width-12.0,164.0)
	var result := {
		"compact":true,
		"header_panel":header,
		"headline":Rect2(left+8,header.position.y+4,width-16,28),
		"status":Rect2(left+8,header.position.y+82,width-16,24),
		"hint":Rect2(left+8,hint_y+6,width-16,maxf(24,hint_height-12)),
		"hint_panel":Rect2(left,hint_y,width,maxf(36,hint_height)),
		"pause":Rect2(left+8,toolbar_y,toolbar_width,44),
		"retry":Rect2(left+14+toolbar_width,toolbar_y,toolbar_width,44),
		"exit":Rect2(left+20+toolbar_width*2,toolbar_y,toolbar_width,44),
		"modal_panel":modal,
		"modal_title":Rect2(modal.position+Vector2(12,12),Vector2(modal.size.x-24,32)),
		"modal_detail":Rect2(modal.position+Vector2(12,50),Vector2(modal.size.x-24,30)),
		"start":Rect2(playfield.get_center().x-100,modal.end.y-56,200,44),
		"title_font":font_size(24,18,display_scale),
		"status_font":font_size(18,13,display_scale),
		"body_font":font_size(18,14,display_scale),
		"modal_font":font_size(28,19,display_scale),
		"detail_font":font_size(18,12,display_scale),
		"button_font":font_size(18,14,display_scale),
	}
	var weights := [1.0,1.0,2.2,1.15,1.15]
	var actions := ["left","right","jump","bell","item"]
	var x := row.position.x
	var controls := {}
	for i in range(actions.size()):
		var button_width: float=(row.size.x-24.0)*weights[i]/6.5
		controls[actions[i]]=to_local(Rect2(x,row.position.y,button_width,row.size.y),origin,display_scale)
		x+=button_width+6.0
	result["controls"]=controls
	for key: String in result.keys():
		if result[key] is Rect2: result[key]=to_local(result[key],origin,display_scale)
	return result

static func world(font: Font, source_size: Vector2, display_scale: float, text: String) -> Dictionary:
	var scale := maxf(display_scale,0.01)
	var title_font := font_size(20,14,scale)
	var mode_font := font_size(16,12,scale)
	var body_font := font_size(17,12,scale)
	var compact := scale < 0.7
	if not compact:
		var text_size := font.get_multiline_string_size(text,HORIZONTAL_ALIGNMENT_CENTER,source_size.x-52,17)
		return {"compact":false,"title_font":20,"mode_font":16,"body_font":17,"header_height":38.0,"padding":16.0,"body_padding":26.0,"body_width":source_size.x-52,"body_height":minf(source_size.y*.45,maxf(42,text_size.y+18)),"body_gap":12.0,"body_inset":9.0,"mode_rect":Rect2(source_size.x-240,0,240,38)}
	var padding := 10.0/scale
	var body_padding := 12.0/scale
	var header_height := maxf(font.get_height(title_font),font.get_height(mode_font))+10.0/scale
	var body_width := source_size.x-body_padding*2
	var text_size := font.get_multiline_string_size(text,HORIZONTAL_ALIGNMENT_CENTER,body_width,body_font)
	var body_gap := 6.0/scale
	# Real feedback can occupy more than one line. Grow its own bar rather
	# than enlarge the map or allow text to run below the fixed viewport.
	var body_height := minf(source_size.y-header_height-body_gap*2,maxf(32.0/scale,text_size.y+12.0/scale))
	var mode_width := font.get_string_size("浅色操作",HORIZONTAL_ALIGNMENT_LEFT,-1,mode_font).x+padding*2
	return {"compact":true,"title_font":title_font,"mode_font":mode_font,"body_font":body_font,"header_height":header_height,"padding":padding,"body_padding":body_padding,"body_width":body_width,"body_height":body_height,"body_gap":body_gap,"body_inset":6.0/scale,"mode_rect":Rect2(source_size.x-mode_width,0,mode_width,header_height)}
