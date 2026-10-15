extends "res://tests/test_lake_app_routes.gd"
## First search must use the source's quest-post prefix, before ordinary feed.
## Scene fixtures are input regression evidence, never earned campaign proof.
const PostStore = preload("res://scripts/data/cc98_store.gd")
func nearest_scroll(node: Node) -> ScrollContainer:
	var p: Node = node.get_parent()
	while p != null:
		if p is ScrollContainer: return p
		p = p.get_parent()
	return null
func witness_order() -> void:
	var witness: Control = named("OpenPost_qizhen-wet-paper-witness")
	check(witness != null, "searched witness exists once before clue collection")
	if witness == null: return
	var ordinary: Array = PostStore.defaults()
	var first: Control = named("OpenPost_" + str(ordinary[0].id))
	check(first != null, "ordinary post links remain in the same feed")
	if first != null:
		check(witness.get_global_rect().position.y < first.get_global_rect().position.y, "source quest witness precedes ordinary feed on first search")
	var scroll: ScrollContainer = nearest_scroll(witness)
	check(scroll != null and scroll != main.phone_scroll, "forum owns result scrolling inside the canonical phone")
	var ids: Array = []
	for button: Node in main.page_body.find_children("OpenPost_*", "Button", true, false): ids.append(str(button.name))
	check(ids.count("OpenPost_qizhen-wet-paper-witness") == 1, "rebuilds do not duplicate the witness")
	for post: Dictionary in PostStore.quest_posts(state.d):
		if post.id == "qizhen-wet-paper-witness": continue
		var previous: Control = named("OpenPost_" + str(post.id))
		check(previous != null and previous.get_global_rect().position.y < witness.get_global_rect().position.y, "existing quest link retains source order: " + str(post.id))
func run() -> void:
	state = root.get_node("State"); state.developer_mode = true
	state.begin_checkpoint("c3-qizhen-location")
	root.size = Vector2i(390,844)
	main = load("res://scenes/main.tscn").instantiate(); root.add_child(main)
	await process_frame; await process_frame
	for width: int in [390,430,1280]:
		await fixture("c3-qizhen-location",width)
		await home(); await press("HomeApp_cc98")
		check(named("OpenPost_qizhen-wet-paper-witness") == null, "no witness before explicit clue search")
		var before: Dictionary = state.d.qizhenLake.duplicate(true)
		await press("Cc98WetProgramSearch")
		check(state.d.qizhenLake == before and state.d.items.wetProgram, "search alone grants no clue and retains the physical program")
		witness_order()
		var ordinary_id: String = str(PostStore.defaults()[0].id)
		await press("OpenPost_" + ordinary_id)
		check(main.phone_builder.cc98_post == ordinary_id, "prior ordinary post still opens through real input")
		await press("Cc98CloseThread")
		witness_order()
		await press("OpenPost_qizhen-wet-paper-witness")
		check(named("Cc98BridgeKeyword") != null, "original witness replies lead to an explicit keyword action")
		await press("Cc98CloseThread")
		await home(); await press("HomeApp_cc98")
		check(named("OpenPost_qizhen-wet-paper-witness") == null, "leaving app preserves original uncollected search lifecycle")
		await press("Cc98WetProgramSearch")
		witness_order()
		await press("OpenPost_qizhen-wet-paper-witness"); await press("Cc98BridgeKeyword")
		await press("Cc98CloseThread")
		witness_order()
		check(state.d.qizhenLake.bridgeClueFound and state.d.items.bridgeKeyword and state.d.items.wetProgram, "explicit collection grants one clue and retains the program")
	await main.shutdown(); main.queue_free(); await process_frame
	print("CC98 witness feed order: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)
