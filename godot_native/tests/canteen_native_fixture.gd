extends RefCounted
## Declared prerequisite fixture for renderer/input comparison; not earned progress.
static func install(state:Node,phase:String="tray_search")->void:
	seed(755);state.developer_mode=true;state.d=state.initial()
	state.d.native.chapter=3;state.d.native.page="phone_home";state.d.native.scene="canteen_interior";state.d.native.mode="light"
	state.d.runtimeMode="rpg";state.d.rpgScene="canteen_interior"
	state.d.actOne.phase="complete";state.d.actOne.inventoryRecovered=true;state.d.actOne.controlsInstalled=true;state.d.actOne.manualControlTested=true;state.d.actOne.movementEnabled=true
	state.d.canteenHunt.active=true;state.d.canteenHunt.phase=phase;state.d.canteenHunt.entryPaperEscaped=true;state.d.canteenHunt.trayTaskStarted=true
	state.d.items.campusCard=true
	var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/worlds.json")).worlds.canteen_interior
	state.d.native.c3_tray_slots=data.constants.CANTEEN_TRAY_SLOTS.slice(0,12).duplicate(true)
	state.d.native.positions={"canteen_interior:":{"x":1194.0,"y":834.0}}
	if phase in ["menu_order","pickup_search"]:state.d.canteenHunt.promoDrinkPlaced=true;state.d.canteenHunt.queueGapOpened=true
