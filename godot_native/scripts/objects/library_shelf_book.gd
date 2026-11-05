extends RefCounted
## Physical book presentation and pointer ownership. The chapter grants evidence.
const Picker=preload("res://scripts/world_object_picker.gd")
const SOURCE:=Rect2(140,840,35,110)
const LOCATION:="06架 · 南端上层 · 755号"
const PULL_DISTANCE:=18.0
var owner_state:Dictionary={}
var pulling:=false
var pointer_id:=0
var start:=Vector2.ZERO
var offset:=0.0
var context:Array=[]
var visual_offset:=0.0
var return_from:=0.0
var return_ms:=280.0
var hold_ms:=0.0
var release_offset:=18.0
var reduced:=false
var animation_assets:RefCounted

func sync(state:Dictionary,replaced:=false)->void:
	if replaced or not is_same(state,owner_state):
		cancel();visual_offset=0;return_ms=280;release_offset=PULL_DISTANCE
	owner_state=state
	reduced=bool(state.get("native",{}).get("settings",{}).get("reduced_motion",false))
	if not available():cancel()

func advance(delta:float)->void:
	var ms:float=clampf(delta,0,.05)*1000
	if pulling:
		hold_ms+=ms
		visual_offset=offset if reduced else lerpf(visual_offset,offset,1-exp(-24*ms/1000))
	elif return_ms<280:
		return_ms=minf(280,return_ms+ms)
		var t:float=return_ms/280
		# A small damped overshoot seats the book against its original backstop.
		visual_offset=return_from*(1-t)*(1-t)*cos(t*PI*.75)
		if reduced or return_ms>=280:visual_offset=0;return_ms=280

func available()->bool:
	var native:Dictionary=owner_state.get("native",{})
	var puzzle:Dictionary=owner_state.get("ui",{}).get("libraryFinalsPuzzle",{})
	return native.get("scene","")=="library_interior" and owner_state.get("ui",{}).get("libraryFinalsPhase","")=="evidence_gathering" and puzzle.get("callNumberCollected",false) and not puzzle.get("archivedRuleCollected",false) and owner_state.get("items",{}).get("callNumber755",false)

func geometry(objects:RefCounted,shelf_offset:=0.0)->Dictionary:
	var whole:Dictionary=objects.geometry("north_display_shelf",Vector2(shelf_offset,0))
	var factor:float=whole.rect.size.x/whole.source.size.x
	return {"texture":whole.texture,"source":SOURCE,"rect":Rect2(whole.rect.position+SOURCE.position*factor,SOURCE.size*factor)}

func begin(id:int,point:Vector2,next_context:Array)->void:
	pulling=true;pointer_id=id;start=point;offset=0;hold_ms=0;return_ms=280;context=next_context.duplicate()

func matches(next_context:Array)->bool:
	return available() and context==next_context and owner_state.get("native",{}).get("mode","")=="light"

func drag(point:Vector2)->void:
	offset=clampf(point.y-start.y,0,30)

func finish(point:Vector2)->bool:
	drag(point)
	var extracted:bool=offset>=PULL_DISTANCE and absf(point.x-start.x)<32
	release_offset=maxf(visual_offset,offset)
	var last_offset:float=maxf(visual_offset,offset)
	cancel()
	if not extracted:return_from=last_offset;visual_offset=last_offset;return_ms=0
	return extracted

func cancel()->void:
	pulling=false;offset=0;context=[];visual_offset=0;return_ms=280

func draw(canvas:CanvasItem,objects:RefCounted,font:Font,shelf_offset:float,reveal_ms:float,revealing:bool)->void:
	var g:=geometry(objects,shelf_offset)
	var slot:Rect2=g.rect
	canvas.draw_rect(slot,Color("241d19"))
	var collected:bool=owner_state.get("ui",{}).get("libraryFinalsPuzzle",{}).get("archivedRuleCollected",false)
	var travel:float=visual_offset
	var alpha:=1.0
	if collected:
		if not revealing or reveal_ms>=420:return
		var t:float=clampf(reveal_ms/420,0,1)
		travel=lerpf(release_offset,42,1-pow(1-t,3))
		alpha=1-smoothstep(.55,1.0,t)
	var loosen:float=sin(hold_ms*.028)*.55*(1-clampf(travel/18,0,1)) if pulling and not reduced else 0.0
	g.rect.position+=Vector2(loosen,travel)
	var animated:bool=animation_assets!=null and animation_assets.ready and (travel>.2 or collected)
	if animated:
		var index:int=mini(7,int(clampf(travel/30,0,1)*7))
		if collected:index=15 if reduced else 8+mini(7,int(clampf(reveal_ms/420,0,1)*8))
		var factor:float=slot.size.y/animation_assets.BOOK_HEIGHT
		var at:Vector2=Vector2(slot.get_center().x,slot.end.y)+Vector2(loosen,travel)-animation_assets.BOOK_PIVOT*factor
		canvas.draw_texture_rect_region(animation_assets.book,Rect2(at,animation_assets.BOOK_CELL*factor),animation_assets.book_source(index),Color(1,1,1,alpha))
	elif travel>.2:
		var exposed:float=minf(travel,14)
		var side:=Rect2(g.rect.position+Vector2(2,-exposed),Vector2(g.rect.size.x,exposed))
		canvas.draw_rect(Rect2(g.rect.position+Vector2(2,3),g.rect.size),Color(0,0,0,.20*alpha))
		canvas.draw_rect(side,Color(.72,.64,.45,alpha))
		canvas.draw_rect(side.grow(-1),Color(.91,.86,.69,alpha))
		for line:int in range(2,int(exposed),3):
			canvas.draw_line(side.position+Vector2(1,line),side.position+Vector2(side.size.x-1,line),Color(.57,.50,.35,.65*alpha),.5)
	if not animated:canvas.draw_texture_rect_region(g.texture,g.rect,g.source,Color(1,1,1,alpha))
	if available():
		# Small ordinary catalogue slip beside the earned book, anchored to its spine.
		var label:=Rect2(Vector2(slot.end.x+1,slot.end.y-9),Vector2(19,10))
		canvas.draw_rect(label,Color("e8d9b8"))
		canvas.draw_string(font,label.position+Vector2(1,8),"755",HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("263c43"))
		Picker.record(canvas,["library_shelf_755"],{"rect":slot.grow(5)})
