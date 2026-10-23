extends Control
## Same aspect-contain behavior as the generic narrative TextureRect.
const Tiled=preload("res://scripts/presentation/source_tiled_texture.gd")
var plate:RefCounted=Tiled.new()
var flip_h:=false
func configure(path:String,mirror:bool=false)->void:
	plate.configure(path);flip_h=mirror
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	set_process(true)
func _process(_delta:float)->void:
	# A later chapter content mount is retryable; stop work after the one successful load.
	if plate.ensure_loaded():set_process(false);queue_redraw()
func _draw()->void:
	var source:Vector2=plate.get_size()
	if source.x<=0 or source.y<=0:return
	var factor:=minf(size.x/source.x,size.y/source.y)
	var target:=Rect2((size-source*factor)/2,source*factor)
	if flip_h:draw_set_transform(Vector2(size.x,0),0,Vector2(-1,1))
	plate.draw_region(self,target,Rect2(Vector2.ZERO,source))
	if flip_h:draw_set_transform(Vector2.ZERO)
