extends RefCounted
## Original short pixel cues replacing five verified all-zero source assets.
## Exact cue/asset pairs only. This supplies a waveform, never timing or state.
const STREAMS = {
	"appear":preload("res://data/native/prologue-sfx/appear.res"),
	"miss":preload("res://data/native/prologue-sfx/miss.res"),
	"ready":preload("res://data/native/prologue-sfx/ready.res"),
	"grab":preload("res://data/native/prologue-sfx/grab.res"),
	"burst":preload("res://data/native/prologue-sfx/burst.res")
}
static func stream(cue: String, asset: String) -> AudioStreamWAV:
	match cue + ":" + asset:
		"prologue_narrator_intro:fx_narrator_circle_appear": return STREAMS.appear
		"prologue_error_intercept_missed:fx_act1_controls_install", "prologue_error_round_failed:fx_act1_controls_install": return STREAMS.miss
		"prologue_error_lock_ready:fx_act1_movement_unlock": return STREAMS.ready
		"prologue_narrator_caught:fx_narrator_grab": return STREAMS.grab
		"prologue_white_burst:fx_narrator_white_burst": return STREAMS.burst
	return null

# Reproducible source parameters for the prebuilt resources. Runtime playback
# reads the cached resources above, avoiding first-cue synthesis stalls.
static func tone(cue: String, asset: String) -> Dictionary:
	match cue + ":" + asset:
		"prologue_narrator_intro:fx_narrator_circle_appear":
			return _tone("triangle", .22, [[0,160],[.07,420],[.22,330]], [[0,.00001],[.005,.17],[.060,.09],[.22,.00001]])
		"prologue_error_intercept_missed:fx_act1_controls_install", "prologue_error_round_failed:fx_act1_controls_install":
			# The manifest retains its .78/.64 playback rates for miss/failure.
			return _tone("triangle", .20, [[0,300],[.065,230],[.11,230],[.20,190]], [[0,.00001],[.004,.16],[.075,.00001],[.105,.14],[.20,.00001]])
		"prologue_error_lock_ready:fx_act1_movement_unlock":
			return _tone("triangle", .24, [[0,360],[.095,360],[.12,540],[.24,540]], [[0,.00001],[.005,.16],[.095,.00001],[.125,.14],[.24,.00001]])
		"prologue_narrator_caught:fx_narrator_grab":
			return _tone("triangle", .14, [[0,160],[.035,100],[.14,70]], [[0,.00001],[.004,.18],[.035,.09],[.14,.00001]])
		"prologue_white_burst:fx_narrator_white_burst":
			# One restrained impact; the source manifest owns all three flashes.
			return _tone("triangle", .12, [[0,1800],[.02,480],[.12,90]], [[0,.00001],[.003,.18],[.025,.09],[.12,.00001]])
	return {}

static func _tone(waveform: String, stop: float, frequencies: Array, gains: Array) -> Dictionary:
	var result := {"waveform":waveform,"start":0.0,"stop":stop,"frequency":[],"gain":[]}
	for point in frequencies: result.frequency.append({"at":float(point[0]),"value":float(point[1]),"curve":"exponential"})
	for point in gains: result.gain.append({"at":float(point[0]),"value":float(point[1]),"curve":"exponential"})
	return result
