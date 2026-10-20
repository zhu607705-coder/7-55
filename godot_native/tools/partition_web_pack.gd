extends SceneTree
## Internal worker for partition_web_pack.mjs. Run in an empty, isolated project.
## PCKPacker and load_resource_pack use the official Godot implementation; this
## tool never serializes or converts a resource and never starts the game.

func _initialize() -> void:
	var spec_path := ""
	var report_path := ""
	var mode := ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--spec="): spec_path = argument.trim_prefix("--spec=")
		elif argument.begins_with("--report="): report_path = argument.trim_prefix("--report=")
		elif argument.begins_with("--mode="): mode = argument.trim_prefix("--mode=")
	if spec_path.is_empty() or report_path.is_empty() or mode not in ["build", "verify"]:
		_fail("Expected --spec, --report and --mode=build|verify")
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(spec_path))
	if not parsed is Dictionary:
		_fail("Invalid worker specification")
		return
	var spec: Dictionary = parsed
	var report := {"mode": mode, "engine": Engine.get_version_info().string, "packs": [], "checkedEntries": 0, "checkedBytes": 0, "success": false}
	if mode == "build":
		if not ProjectSettings.load_resource_pack(str(spec.input), true):
			_fail("Could not mount source PCK")
			return
		for group: Dictionary in spec.groups:
			var packer := PCKPacker.new()
			var error := packer.pck_start(str(group.output))
			if error != OK:
				_fail("pck_start failed for %s: %s" % [group.id, error_string(error)])
				return
			for entry: Dictionary in group.entries:
				var virtual_path := "res://" + str(entry.path)
				error = packer.add_file(virtual_path, virtual_path)
				if error != OK:
					_fail("add_file failed for %s: %s" % [entry.path, error_string(error)])
					return
			error = packer.flush()
			if error != OK:
				_fail("flush failed for %s: %s" % [group.id, error_string(error)])
				return
			report.packs.append({"id": group.id, "entries": group.entries.size()})
	else:
		# This process has never mounted the original PCK: an omitted entry cannot
		# accidentally be read from it or from the developer's project directory.
		for group: Dictionary in spec.groups:
			if not ProjectSettings.load_resource_pack(str(group.output), false):
				_fail("Could not mount partition %s" % group.id)
				return
			report.packs.append({"id": group.id, "entries": group.entries.size()})
		for entry: Dictionary in spec.entries:
			var virtual_path := "res://" + str(entry.path)
			if not FileAccess.file_exists(virtual_path):
				_fail("Partition entry missing after independent mount: " + str(entry.path))
				return
			var file := FileAccess.open(virtual_path, FileAccess.READ)
			if file == null or file.get_length() != int(entry.bytes):
				_fail("Partition entry length mismatch: " + str(entry.path))
				return
			file.close()
			if FileAccess.get_sha256(virtual_path) != str(entry.sha256) or FileAccess.get_md5(virtual_path) != str(entry.md5):
				_fail("Partition entry digest mismatch: " + str(entry.path))
				return
			report.checkedEntries += 1
			report.checkedBytes += int(entry.bytes)
	report.success = true
	var report_file := FileAccess.open(report_path, FileAccess.WRITE)
	if report_file == null:
		_fail("Could not write worker report")
		return
	report_file.store_string(JSON.stringify(report, "\t") + "\n")
	report_file.close()
	print("PCK partition %s passed: %s entries" % [mode, report.checkedEntries])
	quit(0)

func _fail(message: String) -> void:
	printerr("PCK partition worker: " + message)
	quit(1)
