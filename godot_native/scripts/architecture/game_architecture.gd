extends Architecture
## Project composition root. The upstream addon remains byte-for-byte vendored.
const ProgressionModel = preload("res://scripts/architecture/models/progression_model.gd")
const ChapterSystem = preload("res://scripts/architecture/systems/chapter_system.gd")
const ContentUtility = preload("res://scripts/architecture/utilities/content_utility.gd")

func init() -> void:
	if not models.is_empty(): return
	register_utility(ContentUtility.new())
	register_model(ProgressionModel.new())
	register_system(ChapterSystem.new())
	# Also permit State's legacy snapshot property before entering the scene tree.
	for component in utilities.values() + models.values() + systems.values():
		component.architecture = self

# Existing native controllers are synchronous. Keep saving and signal ordering
# in the same call stack; asynchronous commands require a separate future API.
func send_command(command: AbstractCommand):
	command.architecture = self
	var result = command.execute()
	command.architecture = null
	return result

func send_query(query: AbstractQuery):
	query.architecture = self
	var result = query.do()
	query.architecture = null
	return result
