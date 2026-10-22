extends "res://campuses/buct/scripts/l_compact_layered_building.gd"
## The complete padded web-generated bar, fixed to its source-pixel registration.
## No public whole-building hiding or movement: original campus art remains below.

func depth_y_at_world_x(world_x: float) -> float:
	var origin := global_position + body_local_origin
	var column := clampi(floori((world_x - origin.x) / image_scale), 0, raw_size.x - 1)
	return origin.y + column_depths[column] * image_scale
