extends RefCounted
## Original glyph field: stable marks advected by one clock, never random flicker.
## Presentation only. No target words, collision, input, save or progression writes.
const STROKE_GLYPHS="@#%*+"
const Layout=preload("res://scripts/games/prologue_word_model.gd")
const FLOW_CELL=Vector2(4,6)
const ASSEMBLY_DURATION=.28
const ASSEMBLY_DISTANCE=90.0
const STROKE_CELL=Vector2(3,4)
const FIELD_OCCUPANCY=.95
const FIELD_RECT=Rect2(Vector2.ZERO,Layout.EXTENT)
const CLUE_BOUNDS=FIELD_RECT
const CLUE_SPEED=430.0
const WORD_SLOTS=32
const PHYSICAL_SLOTS=2
const CLUE_SLOTS=6
const AMBIENT_SLOTS=WORD_SLOTS-PHYSICAL_SLOTS-CLUE_SLOTS
const BACKGROUND=Color("070B10")
const PANEL=Color("0B1219")
const INK=Color("DBEDF4")
const ACCENT=Color("9AD9EF")
const MUTED=Color("809BA9")
const RULE=Color("294553")
const CAUTION=Color("D5A0A2")
static var _masks:Dictionary={}
static var _words:Dictionary={}
static var _mask_texture:ImageTexture
static var _mask_order:Array=[]
static var _cloud_cache:Dictionary={}
static var _ambient_fragments:Array=[]

static func ambient_fragments()->Array:
	if _ambient_fragments.is_empty():
		_ambient_fragments=JSON.parse_string(FileAccess.get_file_as_string("res://data/native/prologue-flow-atmosphere.json")).get("fragments",[])
	return _ambient_fragments

static func mask_texture()->ImageTexture:
	if _mask_texture!=null:return _mask_texture
	if _masks.is_empty():_masks=JSON.parse_string(FileAccess.get_file_as_string("res://data/native/prologue-ascii-masks.json")).get("masks",{})
	_mask_order=_masks.keys();_mask_order.sort()
	var canvas=Image.create(20,20*_mask_order.size(),false,Image.FORMAT_RGBA8)
	canvas.fill(Color.BLACK)
	for index:int in _mask_order.size():
		var rows:Array=_masks[_mask_order[index]]
		for row:int in rows.size():
			for col:int in str(rows[row]).length():
				if str(rows[row]).substr(col,1)=="1":canvas.set_pixel(col,index*20+row,Color.WHITE)
	_mask_texture=ImageTexture.create_from_image(canvas)
	return _mask_texture

static func mask_indices(text:String)->Vector2:
	mask_texture()
	return Vector2(_mask_order.find(text.substr(0,1)),_mask_order.find(text.substr(1,1)) if text.length()>1 else 0)

static func word_cells(text:String)->Array:
	if _words.has(text):return _words[text]
	if _masks.is_empty():_masks=JSON.parse_string(FileAccess.get_file_as_string("res://data/native/prologue-ascii-masks.json")).get("masks",{})
	var result:Array=[]
	var offset=-Layout.word_size(text)/2
	for index:int in text.length():
		var character=text.substr(index,1)
		var rows:Array=_masks.get(character,[])
		for row:int in rows.size():
			for column:int in str(rows[row]).length():
				if str(rows[row]).substr(column,1)!="1":continue
				var seed=character.unicode_at(0)+column*17+row*23
				var position=offset+Vector2(index*(Layout.GLYPH_GRID*Layout.GLYPH_CELL+Layout.LETTER_GAP)+column*Layout.GLYPH_CELL,row*Layout.GLYPH_CELL)
				result.append({"position":position,"glyph":STROKE_GLYPHS.substr(seed%STROKE_GLYPHS.length(),1),"shade":.76+float(seed%4)*.08})
	_words[text]=result
	return result

static func mask_letters(text:String)->Vector4:
	mask_texture()
	var result=Vector4.ZERO
	for index:int in mini(4,text.length()):result[index]=_mask_order.find(text.substr(index,1))
	return result

static func cloud_parts(fragments:Array)->Array:
	var key="|".join(fragments)
	if _cloud_cache.has(key):return _cloud_cache[key]
	var result:Array=[]
	for fragment:String in fragments:
		var piece=""
		for index:int in fragment.length():
			var character=fragment.substr(index,1);var code=character.unicode_at(0)
			if code<0x4e00 or code>0x9fff:continue
			piece+=character
			if piece.length()==4:result.append(piece);piece=""
		if not piece.is_empty():result.append(piece)
	_cloud_cache[key]=result
	return result

static func cloud_words(fragments:Array,clock:float)->Array:
	var parts=cloud_parts(fragments)
	var result:Array=[]
	var period=maxf(1060.0,ceilf(parts.size()/3.0)*190.0)
	for index:int in parts.size():
		if result.size()>=CLUE_SLOTS:break
		var lane=index%3
		var y=-120.0+fposmod(clock*CLUE_SPEED+floorf(index/3.0)*190.0+lane*95.0,period)
		var opacity=clampf(minf(y+50.0,870.0-y)/65.0,0,1)*.46
		if opacity<=0:continue
		var x=86.0+lane*129.0+sin(clock*1.1+index*1.7)*20.0
		result.append({"text":str(parts[index]),"position":Vector2(x,y),"alpha":opacity,"scale":.40+float(index%3)*.025,"angle":sin(clock*.8+index)*.045,"age":(y+120.0)/CLUE_SPEED})
	return result

static func ambient_words(clock:float,stage:int)->Array:
	# Independent visual debris. Phrases change only outside the visible field;
	# no random-per-frame flicker, fake catch targets, or gameplay clocks.
	var fragments=ambient_fragments()
	var result:Array=[]
	for index:int in AMBIENT_SLOTS:
		var seed=float(index*37+11)
		var direction=Vector2(.23*sin(seed),1.0).normalized()
		if index%6==3:direction=Vector2(-1.0,.32).normalized()
		elif index%6==4:direction=Vector2(1.0,.43).normalized()
		elif index%9==8:direction=Vector2(-.26,-1.0).normalized()
		var horizontal=absf(direction.x)>.8
		var span=750.0 if horizontal else 1140.0
		var speed=460.0+float((index*53)%260)
		var travel=clock*speed+float(index)*137.0
		var cycle=floori(travel/span)
		var offset=fposmod(travel,span)-span*.5
		var cross=Vector2(-direction.y,direction.x)
		var spread=(370.0 if horizontal else 170.0)*sin(seed*1.31)
		var position=Vector2(215,410)+direction*offset+cross*(spread+sin(clock*1.7+seed)*18.0)
		var scale=.24+float(index%5)*.028
		var alpha=.23+float(index%4)*.045
		var edge=minf(minf(position.x+100.0,530.0-position.x),minf(position.y+70.0,890.0-position.y))
		alpha*=clampf(edge/60.0,0,1)
		var phrase=str(fragments[posmod(index*7+cycle*5+stage*13,fragments.size())])
		result.append({"text":phrase,"position":position,"alpha":alpha,"scale":scale,"angle":sin(seed*.7)*.23+sin(clock*.9+seed)*.055,"age":1.0})
	return result

static func burst_opacity(seconds:float)->float:
	# A single monotonic wash; SFX retain their authored independent timestamps.
	return smoothstep(0.0,.95,seconds)

static func assembly_distance(age:float)->float:
	return ASSEMBLY_DISTANCE*(1.0-smoothstep(0.0,ASSEMBLY_DURATION,age))
