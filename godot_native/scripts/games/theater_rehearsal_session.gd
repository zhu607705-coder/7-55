extends RefCounted
## An exact, one-use rehearsal binding. Never serialized into a game save.
const Model=preload("res://scripts/games/theater_shadow_rehearsal_model.gd")
var token: Dictionary={}
var owner: Dictionary={}
var retired := false

func _init(state: Dictionary={}, serial: int=0) -> void:
	owner=state
	if state.is_empty():retired=true;return
	var theater: Dictionary=state.get("theaterHunt",{})
	var native: Dictionary=state.get("native",{})
	token={"id":serial,"nonce":Crypto.new().generate_random_bytes(16).hex_encode(),"puzzleId":Model.PUZZLE_ID,"layoutDigest":Model.layout_digest(),"scene":str(native.get("scene","")),"phase":str(theater.get("phase","")),"mode":str(native.get("mode",theater.get("mode","light"))),"checkpoint":str(state.get("rpgCheckpoint","")),"admitted":bool(theater.get("admitted",false))}

func current(state: Dictionary) -> bool:
	if retired or not is_same(state,owner):return false
	var theater: Dictionary=state.get("theaterHunt",{})
	var native: Dictionary=state.get("native",{})
	return str(state.get("runtimeMode",""))=="rpg" and str(state.get("rpgScene",""))=="theater_interior" and bool(theater.get("active",false)) and bool(theater.get("admitted",false)) and token.scene==str(native.get("scene","")) and token.scene=="theater_interior" and token.phase==str(theater.get("phase","")) and token.mode==str(native.get("mode",theater.get("mode","light"))) and token.mode=="light" and token.checkpoint==str(state.get("rpgCheckpoint",""))

func matches(value: Variant) -> bool:
	return not retired and value is Dictionary and value==token

func cancel(value: Variant) -> bool:
	if not matches(value):return false
	invalidate();return true

func invalidate() -> void:
	retired=true;owner={}

func consume(state: Dictionary, value: Variant) -> bool:
	if not current(state) or not value is Dictionary or not matches(value.get("session")):return false
	var valid: bool=not Model.replay(value).is_empty()
	invalidate()
	return valid
