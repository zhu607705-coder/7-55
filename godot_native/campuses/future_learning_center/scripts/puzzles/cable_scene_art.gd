extends RefCounted
## Original webpage PNGs only. Crops/pivots are entered after pixel inspection.
const Shared=preload("res://campuses/future_learning_center/scripts/puzzles/schedule_scene_art.gd")
const Optical=preload("res://campuses/future_learning_center/scripts/puzzles/optical_scene_art.gd")
const REQUIRED=["monitor","distribution","socket_square","socket_round","plug_square","plug_round","cable_strip","handle","dock","pillar","adapter","reel","route_clip"]
const PARTS:Dictionary={
 "monitor":{"texture":preload("res://campuses/future_learning_center/assets/puzzles/cable_scene/monitor.png"),"region":Rect2(125,287,1003,724),"box":Vector2(145,113),"pivot":Vector2(627,604)},
 "distribution":{"texture":preload("res://campuses/future_learning_center/assets/puzzles/cable_scene/distribution_housing.png"),"region":Rect2(123,142,1007,967),"box":Vector2(132,130),"pivot":Vector2(626.5,625.5)},
 "socket_square":{"texture":preload("res://campuses/future_learning_center/assets/puzzles/cable_scene/socket_square.png"),"region":Rect2(219,231,816,797),"box":Vector2(20,20),"pivot":Vector2(627,638)},
 "socket_round":{"texture":preload("res://campuses/future_learning_center/assets/puzzles/cable_scene/socket_round.png"),"region":Rect2(190,173,869,861),"box":Vector2(20,20),"pivot":Vector2(626,600)},
 "plug_square":{"texture":preload("res://campuses/future_learning_center/assets/puzzles/cable_scene/plug_square.png"),"region":Rect2(321,309,747,668),"box":Vector2(28,28),"pivot":Vector2(487,771)},
 "plug_round":{"texture":preload("res://campuses/future_learning_center/assets/puzzles/cable_scene/plug_round.png"),"region":Rect2(240,284,852,715),"box":Vector2(28,28),"pivot":Vector2(448,764)},
 "cable_strip":{"texture":preload("res://campuses/future_learning_center/assets/puzzles/cable_scene/cable_strip.png"),"region":Rect2(0,325,2172,76),"box":Vector2(228.6315789473684,8),"pivot":Vector2(1086,363)},
 "handle":{"texture":preload("res://campuses/future_learning_center/assets/puzzles/cable_scene/portable_holder.png"),"region":Rect2(75,146,2024,447),"box":Vector2(190,56),"pivot":Vector2(1087,369.5)},
 "dock":{"texture":preload("res://campuses/future_learning_center/assets/puzzles/cable_scene/dock.png"),"region":Rect2(51,144,1940,504),"box":Vector2(128,48),"pivot":Vector2(1021,396)},
 "pillar":{"texture":preload("res://campuses/future_learning_center/assets/puzzles/cable_scene/pillar_v2.png"),"region":Rect2(403,27,448,1200),"box":Vector2(37.333333333333336,100),"pivot":Vector2(627,627)},
 "adapter":{"texture":preload("res://campuses/future_learning_center/assets/puzzles/cable_scene/adapter_ring.png"),"region":Rect2(113,112,1023,1035),"box":Vector2(56,56),"pivot":Vector2(626,641)},
 "reel":{"texture":preload("res://campuses/future_learning_center/assets/puzzles/cable_scene/cable_reel.png"),"region":Rect2(75,98,1264,973),"box":Vector2(58,50),"pivot":Vector2(707.0,584.5)},
 "route_clip":{"texture":preload("res://campuses/future_learning_center/assets/puzzles/cable_scene/route_clip.png"),"region":Rect2(111,325,1032,566),"box":Vector2(34,20),"pivot":Vector2(625,730)}
}
static func parts()->Dictionary:
 var result:=Shared.PARTS.duplicate(true)
 result["fixture"]=Optical.OPTICAL_PARTS.fixture
 for key:String in PARTS:result[key]=PARTS[key]
 return result
static func complete()->bool:
 for key:String in REQUIRED:
  if not PARTS.has(key):return false
 return true
