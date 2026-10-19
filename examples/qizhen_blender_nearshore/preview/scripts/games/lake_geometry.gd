extends RefCounted
## Approximate north-up tracing of the published 2024 campus illustration.
## Game coordinates are NOT metres. Connections and boat passage are provisional.
const ORIGIN = Vector2(690, 290)
const SCALE = 50.0
const SIZE = Vector2(9000, 16000)
static func p(x: float, y: float) -> Vector2:
	return (Vector2(x,y)-ORIGIN)*SCALE
static func polygon(points: Array) -> PackedVector2Array:
	var out:=PackedVector2Array()
	for a in points:out.append(p(a[0],a[1]))
	return out
static var lake_cache: PackedVector2Array=PackedVector2Array()
static var island_cache: PackedVector2Array=PackedVector2Array()
static func lake() -> PackedVector2Array:
	if lake_cache.is_empty():lake_cache=polygon([[794.0,324.5],[827.5,325.0],[815.5,331.0],[814.5,345.0],[807.5,358.0],[807.5,364.0],[814.0,376.5],[834.5,387.0],[834.0,389.5],[823.5,393.0],[823.5,438.0],[827.5,443.0],[827.5,451.0],[830.0,454.5],[838.0,452.5],[848.5,456.0],[845.0,471.5],[819.0,474.5],[816.5,480.0],[821.5,495.0],[816.5,515.0],[820.5,526.0],[829.5,533.0],[819.5,553.0],[821.0,574.5],[790.0,574.5],[790.5,566.0],[783.0,558.5],[770.5,552.0],[768.5,525.0],[761.5,507.0],[760.5,489.0],[760.0,485.5],[767.5,478.0],[772.5,464.0],[777.5,458.0],[776.5,451.0],[785.5,421.0],[785.5,409.0],[782.5,405.0],[773.0,398.5],[758.0,394.5],[749.5,386.0],[749.5,380.0],[755.0,383.5],[766.5,379.0],[766.5,372.0],[773.5,364.0],[769.5,338.0],[771.5,337.0],[774.0,344.5],[782.0,342.5],[791.5,334.0]])
	return lake_cache
static func island() -> PackedVector2Array:
	if island_cache.is_empty():island_cache=polygon([[793.0,476.5],[789.5,481.0],[789.5,506.0],[782.5,514.0],[781.5,523.0],[777.5,532.0],[777.5,537.0],[781.5,542.0],[781.5,547.0],[788.5,553.0],[792.5,562.0],[798.0,565.5],[801.0,565.5],[810.5,558.0],[819.5,539.0],[819.5,533.0],[812.5,525.0],[808.5,513.0],[808.5,509.0],[813.5,494.0],[808.5,489.0],[802.0,477.5]])
	return island_cache
static func water(at: Vector2, clearance: float=0) -> bool:
	if not Geometry2D.is_point_in_polygon(at,lake()) or Geometry2D.is_point_in_polygon(at,island()):return false
	if clearance>0:
		for i in range(8):
			var q: Vector2=at+Vector2.from_angle(TAU*i/8.0)*clearance
			if not Geometry2D.is_point_in_polygon(q,lake()) or Geometry2D.is_point_in_polygon(q,island()):return false
	return true
static func dock() -> Vector2:return p(810,347)
static func goals() -> Array[Dictionary]:
	return [
		{"point":p(779,390),"radius":160.0,"type":"gate","title":"01  离开教学浮码头","hint":"向西南划入开阔湖面 · 持续交替划桨"},
		{"point":p(804,456),"radius":155.0,"type":"inspect","title":"02  找到漂浮信号","hint":"靠近黄色信号浮标 · 按 S 刹停，再按住 E 检查"},
		{"point":p(773,530),"radius":150.0,"type":"gate","title":"03  沿岛西侧南下","hint":"绕过长岛西岸 · 留意岸线收窄，提前转向"},
		{"point":p(804,571),"radius":150.0,"type":"collect","title":"04  取回南端防水袋","hint":"绕到岛南端 · 刹停后按住 E 捞起防水袋"},
		{"point":p(819,551),"radius":110.0,"type":"gate","title":"05  东支水道返航","hint":"从岛东侧返航 · 狭窄处收桨，避免擦岸"},
		{"point":p(814,515),"radius":95.0,"type":"gate","title":"06  通过岛东窄口","hint":"沿岛东岸转向北 · 注意外侧岸线"},
		{"point":p(814,477),"radius":125.0,"type":"gate","title":"07  避开黑天鹅返航","hint":"橙色虚线预示冲刺方向 · 提前横向避让"},
		{"point":p(793,417),"radius":170.0,"type":"gate","title":"08  横渡中央水面","hint":"继续向北 · 岛与南岸已在身后"},
		{"point":dock(),"radius":115.0,"type":"dock","title":"09  安全靠回浮码头","hint":"船头朝北、速度低于 45 · 按住 E 系泊"}
	]
