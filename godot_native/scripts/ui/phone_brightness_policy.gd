extends RefCounted
## Display calibration is independent of battery, story facts and source art.
## 65 is the neutral display anchor: the former unfiltered100 composition.
## Below65 only dim; above65 only lift. Story thresholds keep the raw scalar.
const INITIAL_BRIGHTNESS := 65.0
const PREFERENCE_REVISION := 1
const MAX_VEIL_ALPHA := 0.35

static func display_brightness(value: float, _page: String="") -> float:
	# Presentation cannot secretly replace the puzzle's relative brightness.
	return clampf(value,0.0,100.0)

static func veil_alpha(value: float, page: String="") -> float:
	return maxf(0.0,1.0-display_brightness(value,page)/INITIAL_BRIGHTNESS)*MAX_VEIL_ALPHA

static func grade_strength(value: float, page: String="") -> float:
	return clampf((display_brightness(value,page)-INITIAL_BRIGHTNESS)/(100.0-INITIAL_BRIGHTNESS),0.0,1.0)

static func valid_preference(ui: Dictionary) -> bool:
	var present:=0
	for key: String in ["brightnessRevision","brightnessUserAdjusted","brightnessLegacy100Repaired"]:
		if ui.has(key): present+=1
	if present==0: return true # Exact legacy absence is handled at load/import.
	if present!=3: return false
	var revision: Variant=ui.brightnessRevision
	return (revision is int or revision is float) and revision==PREFERENCE_REVISION and ui.brightnessUserAdjusted is bool and ui.brightnessLegacy100Repaired is bool

static func mark_manual(snapshot: Dictionary) -> void:
	snapshot.ui.brightnessRevision=PREFERENCE_REVISION
	snapshot.ui.brightnessUserAdjusted=true
	if not snapshot.ui.has("brightnessLegacy100Repaired"): snapshot.ui.brightnessLegacy100Repaired=false

static func upgrade_legacy(snapshot: Dictionary) -> void:
	if snapshot.ui.has("brightnessRevision"): return
	var manual:=false
	for entry: Dictionary in snapshot.native.get("log",[]):
		if str(entry.get("text",""))=="屏幕亮度已调整。": manual=true
	var eligible: bool=snapshot.runtimeMode=="phone" and int(snapshot.native.chapter)==1 and str(snapshot.native.scene).is_empty() and snapshot.actOne.phase=="prologue"
	for key: String in ["plantLit","plantWatered","plantFertilized","flowerBloomed","flowerEightTaken","checkinDone"]:
		eligible=eligible and not bool(snapshot.flags.get(key,false))
	eligible=eligible and snapshot.ui.libraryFinalsPhase=="idle" and snapshot.native.page!="photos" and snapshot.currentScene!="photos"
	for key: String in ["photoCaptured","photoDimmed","itemReportGenerated"]:
		eligible=eligible and not bool(snapshot.ui.libraryFinalsPuzzle.get(key,false))
	for key: String in ["canteenHunt","theaterHunt","qizhenLake"]:
		eligible=eligible and not bool(snapshot[key].get("active",false))
	eligible=eligible and not bool(snapshot.chapter4.get("prologueSeen",false)) and not bool(snapshot.chapter4.get("completed",false))
	# The former full-brightness default bypassed the >=80 plant action. Repair
	# only untouched early progression at exactly100. Silent historical Settings
	# writes are ambiguous; retain a durable receipt rather than claim provenance.
	var repaired:=eligible and not manual and float(snapshot.ui.brightness)==100.0
	if repaired: snapshot.ui.brightness=INITIAL_BRIGHTNESS
	snapshot.ui.brightnessRevision=PREFERENCE_REVISION
	snapshot.ui.brightnessUserAdjusted=manual
	snapshot.ui.brightnessLegacy100Repaired=repaired
