extends RefCounted
## Shared read-only access rule. Network transport never installs the client.
const UPDATE_PHASES = ["movement_required", "reservation_briefing_required", "reservation_required", "movement_ready", "complete", "identity_required", "phone_link_required", "controls_required", "item_required", "map_required", "chapter_two_ready"]
const STAGES = ["not_started", "official_entry_found", "package_ready", "installed", "legacy_ready"]

static func update_required(s: Dictionary) -> bool:
	return str(s.get("actOne",{}).get("phase","prologue")) in UPDATE_PHASES or str(s.get("ui",{}).get("libraryFinalsPhase","idle"))!="idle"

static func installed(s: Dictionary) -> bool:
	return s.get("actOne",{}).get("tiyiUpdateStage","not_started") in ["installed","legacy_ready"]

static func allowed(s: Dictionary) -> bool:
	return s.get("networkMode")=="cellular" and (not update_required(s) or installed(s))

static func needs_update(s: Dictionary) -> bool:
	return update_required(s) and not installed(s)
