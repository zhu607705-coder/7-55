import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
const root = process.env.BUCT_REPOSITORY_ROOT ? path.resolve(process.env.BUCT_REPOSITORY_ROOT) : path.resolve(import.meta.dirname, '..');
const read = relative => fs.readFileSync(path.join(root, relative));
const json = relative => JSON.parse(read(relative));
const sha = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const validation = json('docs/BUCT_CHANGPING_EAST_ROAD_VALIDATION.json');
const campus = 'godot_native/campuses/buct_changping/';
const data = json(campus + 'data/east_road_extension.json');
const route = json(campus + 'data/playable_route.json');
let checks = 0;
const failures = [];
function check(ok, text) { checks++; if (!ok) failures.push(text); }
for (const entry of validation.unchanged_source_contracts) {
  check(sha(read(entry.path)) === entry.sha256, `${entry.accepted_baseline_tree ? "Exact accepted document baseline" : "Unchanged exact-base source"}: ${entry.path}`);
}
check(data.polygon_source_xy.length === 28, 'Original reviewed 28-vertex paved polygon');
check(JSON.stringify(data.polygon_source_xy) === JSON.stringify(validation.reviewed_polygon), 'No shrinkage or changed reviewed road outline');
check(route.route_waypoints.length === 41 && route.landmarks.length === 3, 'Original guide and POI counts');
check(JSON.stringify(route.spawn) === '[515,1510]', 'Original spawn');
check(route.walkable_polygons.length === 81, 'Original route still contains exactly 81 authored polygons');
check(data.exposed_union_boundary_segments.length === 40, 'Bounded union boundary certificate');
check(data.foliage.every(item => item.source_spans_y_x0_x1_exclusive.every(row => row[2] > row[1])), 'Nonempty exact source leaf spans');
check(data.foliage.filter(item => item.id.includes('_west_')).every(item => item.source_spans_y_x0_x1_exclusive.every(row => row[0] >= 833)), 'West low grass is not a foreground occluder');
const script = read(campus + 'scripts/east_road_extension.gd').toString();
check(!/StaticBody2D|CollisionShape2D|CollisionPolygon2D/.test(script), 'Source leaves add no physical obstacle');
check(script.includes('was_original_paving(p):return true'), 'Preserve inherited old paving behavior');
check(script.includes('exposed_edges'), 'New radius check uses exposed union edges');
const movement = json('godot_native/campuses/buct_shared/student/data/student-movement-profile.json');
check(Object.values(movement.directions).flatMap(states => Object.values(states).flat()).length === 34, 'All 34 original student atlas poses retained');
console.log(JSON.stringify({ checks, failures, base_head: validation.base_head, base_tree: validation.base_tree }, null, 2));
if (failures.length) process.exit(1);
