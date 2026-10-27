extends RefCounted
## Rendering isolation only. Build a NEW scene, mesh, material and light per world.
## Read-only snapshots receive immutable data; never pass the current model here.

static func viewport(parent: Node) -> SubViewport:
	var surface := SubViewport.new()
	surface.own_world_3d = true
	surface.physics_object_picking = false
	surface.gui_disable_input = true
	surface.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	surface.msaa_3d = Viewport.MSAA_2X
	parent.add_child(surface)
	return surface

static func image(parent: Node, surface: SubViewport) -> TextureRect:
	var display := TextureRect.new()
	display.texture = surface.get_texture()
	display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	display.show_behind_parent = true
	display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	parent.add_child(display)
	return display
