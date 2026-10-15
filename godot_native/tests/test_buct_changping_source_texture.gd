extends SceneTree
## Run both in the source project and with --main-pack <normal-export.pck>.
## The corrupt raw-file fixture is a process-local PCK overlay, never a repo edit.
## BUCT_EXPECT_SOURCELESS=1 requires a real export without the original PNG.
## BUCT_SOURCE_TEXTURE_REPORT optionally selects an absolute JSON report path.
const VERIFY = preload("res://campuses/buct_changping/scripts/verified_source_texture.gd")
var checks := 0
var failures: Array[String] = []
var records: Array[Dictionary] = []
var raw_source_present := false
var texture_class := ""
var finished := false

func _initialize() -> void:
	create_timer(45.0).timeout.connect(_timeout)
	run.call_deferred()

func _timeout() -> void:
	if not finished:
		failures.append("Source texture test exceeded 45 seconds")
		finish()

func check(ok: bool, label: String) -> void:
	checks += 1
	records.append({"pass": ok, "label": label})
	if not ok:
		failures.append(label)
		push_error(label)

func require(ok: bool, label: String) -> bool:
	if not ok:
		failures.append("Fixture: " + label)
		push_error("Fixture: " + label)
		finish()
	return ok

func finish() -> void:
	if finished:
		return
	finished = true
	if failures.is_empty() and checks != 14:
		failures.append("Expected all 14 checks, got %d" % checks)
	var report := {"checks": checks, "failures": failures, "records": records,
		"raw_source_present_before_overlay": raw_source_present, "texture_class": texture_class}
	var report_path := OS.get_environment("BUCT_SOURCE_TEXTURE_REPORT")
	if not report_path.is_empty():
		var file := FileAccess.open(report_path, FileAccess.WRITE) if report_path.is_absolute_path() else null
		if file == null:
			failures.append("Cannot write absolute BUCT_SOURCE_TEXTURE_REPORT: " + report_path)
			report["failures"] = failures
		else:
			file.store_string(JSON.stringify(report, "  ") + "\n")
			file.close()
	print("SOURCE_TEXTURE_TEST_REPORT ", JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)

func run() -> void:
	raw_source_present = FileAccess.file_exists(VERIFY.SOURCE_PATH)
	if not require(OS.get_environment("BUCT_EXPECT_SOURCELESS") != "1" or not raw_source_present, "Export must omit original PNG"):
		return
	var source: Texture2D = load(VERIFY.SOURCE_PATH) as Texture2D
	if not require(source != null, "Approved imported texture loads"):
		return
	texture_class = source.get_class()
	var image: Image = source.get_image()
	if not require(image != null and not image.is_empty(), "Imported texture exposes an image"):
		return
	check(not VERIFY.matches(null), "Reject null texture")
	check(not VERIFY.matches(42), "Reject non-texture value")
	check(not VERIFY.image_matches(null), "Reject null image")
	check(not VERIFY.image_matches(Image.new()), "Reject empty image")
	var small := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	check(not VERIFY.image_matches(small), "Reject wrong image dimensions")
	check(VERIFY.matches(source), "Accept authentic imported source texture")
	check(VERIFY.image_matches(image), "Accept actual decoded source image")
	var pixels: Image = image.duplicate()
	if pixels.is_compressed():
		if not require(pixels.decompress() == OK, "Source image decompresses"):
			return
	pixels.clear_mipmaps()
	pixels.convert(Image.FORMAT_RGBA8)
	var changed_bytes := pixels.get_data()
	changed_bytes[0] = changed_bytes[0] ^ 1
	var changed := Image.create_from_data(pixels.get_width(), pixels.get_height(), false, Image.FORMAT_RGBA8, changed_bytes)
	check(not VERIFY.image_matches(changed), "Reject a one-bit change in one pixel")
	var mipmapped: Image = pixels.duplicate()
	if not require(mipmapped.generate_mipmaps() == OK, "Mipmap fixture builds"):
		return
	var before := mipmapped.get_data()
	check(VERIFY.image_matches(mipmapped) and mipmapped.has_mipmaps() and mipmapped.get_data() == before,
		"Validate a private copy without changing caller pixels or mipmaps")
	var wrong_identity := ImageTexture.create_from_image(pixels)
	check(not VERIFY.matches(wrong_identity), "Reject correct pixels with a different resource identity")
	var wrong_size := ImageTexture.create_from_image(small)
	wrong_size.take_over_path(VERIFY.SOURCE_PATH)
	check(not VERIFY.matches(wrong_size), "Reject correct-path texture with wrong dimensions")
	source.take_over_path(VERIFY.SOURCE_PATH)
	var impostor := ImageTexture.create_from_image(changed)
	impostor.take_over_path(VERIFY.SOURCE_PATH)
	check(not VERIFY.matches(impostor), "Reject correct-path and correct-size texture with changed pixels")
	source.take_over_path(VERIFY.SOURCE_PATH)
	check(VERIFY.matches(source), "Restored authentic resource still passes")
	# A correct cached texture must not conceal a present but corrupted raw PNG.
	# Adding this raw path to the pack leaves its imported .ctex entry untouched.
	var fixture_dir := OS.get_cache_dir().path_join("755-source-texture-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
	if not require(DirAccess.make_dir_recursive_absolute(fixture_dir) == OK, "Create unique fixture directory"):
		return
	var raw_path := fixture_dir.path_join("corrupt-source.png")
	var file := FileAccess.open(raw_path, FileAccess.WRITE)
	if not require(file != null, "Open corrupt raw fixture"):
		return
	file.store_string("invalid approved source: test fixture only")
	file.close()
	var pack_path := fixture_dir.path_join("corrupt-source.pck")
	var packer := PCKPacker.new()
	if not require(packer.pck_start(pack_path) == OK, "Start corrupt-source PCK"):
		return
	if not require(packer.add_file(VERIFY.SOURCE_PATH, raw_path) == OK, "Pack corrupt raw fixture"):
		return
	if not require(packer.flush() == OK, "Flush corrupt-source PCK"):
		return
	if not require(ProjectSettings.load_resource_pack(pack_path, true), "Mount corrupt-source overlay"):
		return
	check(FileAccess.file_exists(VERIFY.SOURCE_PATH)
		and FileAccess.get_sha256(VERIFY.SOURCE_PATH) != VERIFY.SOURCE_SHA256
		and VERIFY.image_matches(source.get_image()) and not VERIFY.matches(source),
		"Reject corrupted present raw PNG even while cached imported pixels remain authentic")
	finish()
