extends TextureRect
## Source recovered-frame-preview: three original frames, 0.55 s each.
## Presentation only; this node never grants evidence or submits a result.
const FRAME_SECONDS: float=0.55
const FRAME_IDS: Array[String]=["paper_left","paper_middle","paper_right"]
var frames: Array[Texture2D]=[]
var elapsed: float=0
var frame_index: int=0
var reduced_motion: bool=false

func configure(reduce: bool=false) -> void:
	reduced_motion=reduce
	frames.clear()
	for id: String in FRAME_IDS:
		frames.append(load("res://assets/ui/photo-evidence/chapter35_live_"+id+".webp"))
	expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	elapsed=0; frame_index=0; texture=frames[0]

func _process(delta: float) -> void:
	if is_visible_in_tree(): advance_frame(delta)

func advance_frame(delta: float) -> void:
	if reduced_motion or frames.is_empty(): return
	elapsed=fposmod(elapsed+maxf(0,delta),FRAME_SECONDS*frames.size())
	frame_index=int(floor((elapsed+0.000001)/FRAME_SECONDS))%frames.size()
	texture=frames[frame_index]
