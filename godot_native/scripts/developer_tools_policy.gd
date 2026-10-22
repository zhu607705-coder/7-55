extends RefCounted
## A production pack must stay formal even when loaded by an editor binary.
## Neither command-line arguments nor persisted game state can enable tools.
static func available() -> bool:
	return not OS.has_feature("755_production") and OS.is_debug_build()
