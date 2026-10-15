extends RefCounted
## Literal TheaterInteriorScene.animateReversal source screen-space layers.
var source: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/native/chapter3-world-source.json"))
var words: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/source/chapter3-theater.content.json"))
var textures: Dictionary={}
var font: Font=load("res://assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf")
func texture(key: String) -> Texture2D:
	if not textures.has(key): textures[key]=load(str(source.assets[key]))
	return textures[key]
static func phase_at(ms: float) -> String:
	if ms>=1320: return "dialogue"
	if ms>=770: return "escape"
	if ms>=370: return "fragments"
	if ms>=220: return "cracked"
	return "locked"
func draw(c: CanvasItem,session: RefCounted,size: Vector2) -> void:
	if session.sequence_id!="theater_reversal" or session.visual_acknowledged or session.elapsed_ms>=1320: return
	var t: float=session.elapsed_ms
	var factor: float=minf(size.x/960,size.y/540)
	var origin: Vector2=(size-Vector2(960,540)*factor)/2
	c.draw_set_transform(origin,0,Vector2.ONE*factor)
	c.draw_rect(Rect2(60,55,840,430),Color("09060a",.97)); c.draw_rect(Rect2(60,55,840,430),Color("c05260",.9),false,4)
	var title: String=words.spotlight.reversal
	var width: float=font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,19).x
	c.draw_string(font,Vector2(480-width/2,127),title,HORIZONTAL_ALIGNMENT_LEFT,-1,19,Color("ffadb5"))
	c.draw_set_transform(Vector2.ZERO)
	if t<370:
		_image(c,origin,factor,"paperLockedUrl" if t<220 else "paperCrackedUrl",Vector2(480,290),1.65,1,0)
		c.draw_set_transform(origin,0,Vector2.ONE*factor)
		for line: Array in [[Vector2(480,272),Vector2(472,289)],[Vector2(472,289),Vector2(486,300)],[Vector2(486,300),Vector2(477,316)],[Vector2(480,287),Vector2(498,280)],[Vector2(482,301),Vector2(500,311)]]: c.draw_line(line[0],line[1],Color("8c7d77",.92),2)
		c.draw_set_transform(Vector2.ZERO)
	if t>=370:
		var fragment_p: float=clampf((t-370)/(120.0 if session.reduced else 420.0),0,1)
		if fragment_p<1: _image(c,origin,factor,"paperFragmentsUrl",Vector2(480,290),lerpf(1.4,2,fragment_p),1-fragment_p,0)
		var shard_p: float=clampf((t-370)/(120.0 if session.reduced else 400.0),0,1)
		if shard_p<1:
			for shard: Dictionary in session.shards:
				var p:=Vector2(480,290).lerp(Vector2(shard.x,shard.y),shard_p)
				c.draw_set_transform(origin+p*factor,deg_to_rad(float(shard.angle)+180*shard_p),Vector2.ONE*factor)
				c.draw_rect(Rect2(-float(shard.width)/2,-4,float(shard.width),8),Color("e7dbc8",1-shard_p))
			c.draw_set_transform(Vector2.ZERO)
	if t>=770:
		var p: float=clampf((t-770)/(160.0 if session.reduced else 560.0),0,1)
		if p<1: _image(c,origin,factor,"paperEscapeUrl",Vector2(390,310).lerp(Vector2(860,225),p),1,.74*(1-p),240*p)
func _image(c: CanvasItem,origin: Vector2,factor: float,key: String,p: Vector2,scale_value: float,alpha: float,angle: float) -> void:
	var tex: Texture2D=texture(key)
	c.draw_set_transform(origin+p*factor,deg_to_rad(angle),Vector2.ONE*factor*scale_value)
	c.draw_texture(tex,-tex.get_size()/2,Color(1,1,1,alpha)); c.draw_set_transform(Vector2.ZERO)
