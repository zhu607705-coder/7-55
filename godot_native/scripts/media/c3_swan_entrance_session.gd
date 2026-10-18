extends RefCounted
## One-shot presentation lease. This is never a chase/progression receipt.
const WorldSession = preload("res://scripts/chapters/c3_lake_world_session.gd")
var _state: Dictionary
var _lake: Dictionary
var _attempt: int
var _host: WeakRef
var _presenter: WeakRef
var _model: RefCounted
var source_pose: Dictionary
var reduced_motion: bool
var status: String = "issued"

static func capture_pose(s: Dictionary, proof: RefCounted) -> Dictionary:
	if not proof is WorldSession or proof._world == null: return {}
	var host: Node = proof._world.get_ref()
	if not proof.valid(s,host) or s.qizhenLake.phase != "paper_capture" or s.qizhenLake.zone != "swan_cove": return {}
	if not host.player.is_finite() or not host.can_stand(host.player): return {}
	return {"position":host.player,"heading":host.kayak.heading,"roll":host.kayak.roll,"speed":0.0,"strokeAgeMs":1000.0}

func _init(s: Dictionary, captured_pose: Dictionary) -> void:
	_state = s
	_lake = s.qizhenLake
	_attempt = int(_lake.chaseAttempts)
	source_pose = captured_pose.duplicate(true)
	reduced_motion = bool(s.native.get("settings",{}).get("reduced_motion",false))

func _matches_state(s: Dictionary) -> bool:
	var q: Dictionary = s.get("qizhenLake",{})
	return is_same(s,_state) and is_same(q,_lake) and s.get("runtimeMode") == "rpg" and s.get("rpgScene") == "qizhen_lake" and s.get("native",{}).get("scene") == "qizhen_lake" and q.get("active",false) and q.get("phase") == "swan_chase" and q.get("zone") == "channel" and q.get("vehicle") == "kayak" and q.get("paperCaptured",false) and q.get("swanReleased",false) and int(q.get("chaseAttempts",-1)) == _attempt

func begin(s: Dictionary, host: Node, presenter: Node) -> bool:
	if status != "issued" or source_pose.is_empty() or not _matches_state(s) or not WorldSession.eligible_host(s,host) or not is_instance_valid(presenter) or not presenter.is_inside_tree(): return false
	_host = weakref(host)
	_presenter = weakref(presenter)
	_model = host.kayak
	status = "playing"
	return true

func matches(s: Dictionary, host: Node, presenter: Node) -> bool:
	return status == "playing" and _matches_state(s) and _host != null and _host.get_ref() == host and _presenter != null and _presenter.get_ref() == presenter and is_instance_valid(presenter) and presenter.is_inside_tree() and WorldSession.eligible_host(s,host) and host.kayak == _model

func dismiss(presenter: Node, cancelled: bool=false) -> bool:
	if status != "playing" or _presenter == null or _presenter.get_ref() != presenter: return false
	status = "cancelled" if cancelled else "dismissed"
	_host = null
	_presenter = null
	_model = null
	return true
