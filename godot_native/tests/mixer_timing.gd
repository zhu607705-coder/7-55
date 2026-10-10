extends RefCounted
## Test clock budgets follow accepted pending phases, never a fixed sleep.
const ORDINARY_MS: float=1050.0
const TERMINAL_MS: float=1350.0
const REDUCED_ORDINARY_MS: float=140.0
const REDUCED_TERMINAL_MS: float=220.0
const SCHEDULING_MARGIN_MS: int=250
const Motion=preload("res://scripts/presentation/c3_mixer_motion.gd")

static func finish_current(motion: Node2D) -> void:
	var remaining: float=maxf(0.0,motion.duration_ms-motion.elapsed_ms)
	motion._process((remaining+1.0)/1000.0/Motion.PLAYBACK_RATE)

static func remaining_real_ms(panel: Control) -> int:
	var motion: Node2D=panel.surface.motion
	var remaining: float=maxf(0.0,motion.duration_ms-motion.elapsed_ms) if motion.playing else 0.0
	for pending: Dictionary in panel.surface.pending_pours:
		var terminal: bool=int(pending.next.canteenHunt.drinkMixAttemptCount)>int(pending.before.canteenHunt.drinkMixAttemptCount)
		var reduced: bool=bool(pending.next.native.settings.get("reduced_motion",false))
		remaining+=(REDUCED_TERMINAL_MS if reduced else TERMINAL_MS) if terminal else (REDUCED_ORDINARY_MS if reduced else ORDINARY_MS)
	if panel.finishing:
		var tail: float=260.0 if panel.finish_reduced else panel.SETTLE_MS+panel.RESULT_MS+panel.RETURN_MS
		remaining+=maxf(0.0,tail-panel.finish_elapsed_ms)
	return int(ceil(remaining/Motion.PLAYBACK_RATE))+SCHEDULING_MARGIN_MS
