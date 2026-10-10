extends RefCounted
## PhotosScene's useRef/useEffect lifecycle; never writes puzzle state itself.
## Rebuilding a native page or opening Control Center is not a React unmount.
var mounted := false
var brightness_at_capture: Variant = null
var previous_brightness := 0.0

func reset() -> void:
	mounted = false
	brightness_at_capture = null
	previous_brightness = 0.0

func observe(page: String, ui: Dictionary) -> bool:
	if page != "photos":
		reset()
		return false
	var puzzle: Dictionary = ui.libraryFinalsPuzzle
	var brightness: float = float(ui.brightness)
	var captured: bool = bool(puzzle.photoCaptured)
	var dimmed: bool = bool(puzzle.photoDimmed)
	if not mounted:
		mounted = true
		brightness_at_capture = brightness if captured and not dimmed else null
		previous_brightness = brightness
		return false
	var previous := previous_brightness
	previous_brightness = brightness
	if not captured or dimmed: return false
	if brightness_at_capture == null:
		brightness_at_capture = brightness
		return false
	# The authoritative lib_dim_photo action still checks phase and capture.
	# Finite validation matches source isPhotoReadable and prevents NaN/Inf intent.
	return is_finite(brightness) and brightness <= 20.0 and brightness != previous and brightness != float(brightness_at_capture)
