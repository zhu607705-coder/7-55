extends RefCounted
## Shared transient tree ownership, separate from each player's explicit pause.
const KEY := &"seven55_tree_pause_leases"

static func _audio(node: Node, result: Array[Dictionary], freeze: bool = false) -> void:
	if node is AudioStreamPlayer and node.has_stream_playback():
		result.append({"player":weakref(node),"playback":weakref(node.get_stream_playback()),"manual_paused":node.stream_paused})
		if freeze:node.stream_paused = true
	for child: Node in node.get_children(): _audio(child,result,freeze)

static func _same(record: Dictionary) -> AudioStreamPlayer:
	var player: AudioStreamPlayer = record.player.get_ref()
	var playback: AudioStreamPlayback = record.playback.get_ref()
	if not is_instance_valid(player) or player.is_queued_for_deletion() or playback == null or not player.has_stream_playback():return null
	return player if player.get_stream_playback() == playback else null

static func _pause_clocks(node: Node, result: Array[Dictionary]) -> void:
	if node.has_method("pause_for_platform") and node.has_method("resume_from_platform") and node.has_method("presentation_clock"):
		result.append({"director":weakref(node),"owned":node.pause_for_platform()})
	for child: Node in node.get_children():_pause_clocks(child,result)

static func owns_clock(tree: SceneTree, director: Node) -> bool:
	if tree.has_meta(KEY):
		for record: Dictionary in tree.get_meta(KEY).clocks:
			if record.director.get_ref() == director:return bool(record.owned)
	return false

static func begin(tree: SceneTree, owner: Node) -> void:
	if not tree.has_meta(KEY):
		var audio: Array[Dictionary] = []
		_audio(tree.root,audio,true)
		var clocks: Array[Dictionary] = []
		_pause_clocks(tree.root,clocks)
		tree.set_meta(KEY,{"prior":tree.paused,"owners":{},"audio":audio,"overrides":[],"clocks":clocks})
	var lease: Dictionary = tree.get_meta(KEY)
	lease.owners[owner.get_instance_id()] = true

static func original_pause(tree: SceneTree, player: AudioStreamPlayer) -> bool:
	if tree.has_meta(KEY):
		for record: Dictionary in tree.get_meta(KEY).audio:
			if _same(record) == player:return bool(record.manual_paused)
	return player.stream_paused

static func enforce(tree: SceneTree) -> void:
	if tree.has_meta(KEY):tree.paused = true

static func release(tree: SceneTree, owner: Node, overrides: Array[Dictionary] = []) -> void:
	if not tree.has_meta(KEY):return
	var lease: Dictionary = tree.get_meta(KEY)
	lease.owners.erase(owner.get_instance_id())
	lease.overrides.append_array(overrides)
	if not lease.owners.is_empty():
		tree.paused = true
		# The releasing platform may have computed foreground audio ownership,
		# but another modal still holds the tree. Defer that restoration too.
		for record: Dictionary in overrides:
			var player := _same(record)
			if player != null:player.stream_paused = true
		return
	# New/replaced playbacks never belonged to this lease's original capture.
	var current: Array[Dictionary] = []
	_audio(tree.root,current)
	var restore: Array[Dictionary] = []
	for record: Dictionary in current:
		var player := _same(record)
		var captured := false
		for original: Dictionary in lease.audio:
			if player != null and _same(original) == player:
				captured = true
				break
		if not captured:restore.append(record)
	for record: Dictionary in lease.clocks:
		var director: Node = record.director.get_ref()
		if is_instance_valid(director) and bool(record.owned):director.resume_from_platform()
	tree.remove_meta(KEY)
	tree.paused = bool(lease.prior)
	if not tree.paused:
		for original: Dictionary in lease.audio:
			var player := _same(original)
			if player != null:player.stream_paused = bool(original.manual_paused)
		restore.append_array(lease.overrides)
		for record: Dictionary in restore:
			var player := _same(record)
			if player != null:player.stream_paused = bool(record.manual_paused)
