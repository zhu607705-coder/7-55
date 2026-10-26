extends Control
## Display-only uniform transform. No geometry is inferred from alpha or pixels.

var texture: Texture2D
var zoom := 1.0
var pan := Vector2.ZERO
var dragging := false
var touch_index := -1
var checkerboard := true

func _ready() -> void:
	clip_contents = true
	mouse_default_cursor_shape = Control.CURSOR_DRAG
	resized.connect(_on_resize)

func set_plate(value: Texture2D) -> void:
	texture = value
	reset_view()

func reset_view() -> void:
	zoom = 1.0
	pan = Vector2.ZERO
	dragging = false
	touch_index = -1
	queue_redraw()

func set_zoom(value: float) -> void:
	zoom = clampf(value, 1.0, 4.0)
	_clamp_pan()
	queue_redraw()

func image_rect() -> Rect2:
	if texture == null or size.x <= 0 or size.y <= 0:
		return Rect2()
	var source_size := texture.get_size()
	var fit := minf(size.x / source_size.x, size.y / source_size.y)
	var shown := source_size * fit * zoom
	return Rect2((size - shown) / 2.0 + pan, shown)

func _clamp_pan() -> void:
	if texture == null:
		pan = Vector2.ZERO
		return
	var extent := image_rect().size
	var limit := Vector2(maxf(0.0, (extent.x - size.x) / 2.0), maxf(0.0, (extent.y - size.y) / 2.0))
	pan = pan.clamp(-limit, limit)

func _on_resize() -> void:
	_clamp_pan()
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_VISIBILITY_CHANGED:
		dragging = false
		touch_index = -1

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("151e28"))
	if checkerboard:
		for y in range(0, ceili(size.y), 24):
			for x in range(0, ceili(size.x), 24):
				if (x / 24 + y / 24) % 2 == 0:
					draw_rect(Rect2(x, y, 24, 24), Color("1d2934"))
	if texture != null:
		draw_texture_rect(texture, image_rect(), false)

func _gui_input(event: InputEvent) -> void:
	if texture == null:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.pressed
		elif event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			set_zoom(zoom * (1.2 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.2))
		accept_event()
	elif event is InputEventMouseMotion and dragging:
		if not event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			dragging = false
			return
		pan += event.relative
		_clamp_pan()
		queue_redraw()
		accept_event()
	elif event is InputEventScreenTouch:
		if event.pressed and touch_index == -1:
			touch_index = event.index
		elif not event.pressed and touch_index == event.index:
			touch_index = -1
		accept_event()
	elif event is InputEventScreenDrag and event.index == touch_index:
		pan += event.relative
		_clamp_pan()
		queue_redraw()
		accept_event()
