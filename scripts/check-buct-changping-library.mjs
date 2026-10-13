#!/usr/bin/env node
// Dependency-free immutable-asset and registration checks before native tests.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(process.argv[2] || path.join(here, '..', 'godot_native'));
const campus = path.join(root, 'campuses/buct_changping');
const read = relative => fs.readFileSync(path.join(campus, relative));
const hash = buffer => crypto.createHash('sha256').update(buffer).digest('hex');
const profile = JSON.parse(read('data/library_registration.json'));
const body = read('assets/library_body.png');
const ids = read('data/library_surfaces.r8.bin');
const width = body.readUInt32BE(16);
const height = body.readUInt32BE(20);
const checks = [];
function check(ok, message) {
  checks.push(Boolean(ok));
  console.log(`${ok ? 'PASS' : 'FAIL'} ${message}`);
}
check(body.subarray(0, 8).equals(Buffer.from([137,80,78,71,13,10,26,10])) && width === 1225 && height === 1284 && body[24] === 8 && body[25] === 6, 'Original padded RGBA PNG dimensions and format');
check(hash(body) === profile.body_sha256, 'Body equals reviewed original bytes');
check(ids.length === width * height && [...new Set(ids)].sort().join(',') === '0,1,2', 'One-byte two-face semantic field');
check(hash(ids) === profile.surface_id_sha256, 'Semantic field equals reviewed registration');
check(profile.depth_rows_raw_y.length === 2 && profile.depth_rows_raw_y.every(row => row.length === width && row.every(Number.isFinite)), 'Two complete finite contact-depth rows');
check(profile.body_image_to_world.scale > 0 && profile.body_image_to_world.rotation_degrees === 0, 'One explicit uniform transform');
const importText = read('assets/library_body.png.import').toString('utf8');
check(importText.includes('mipmaps/generate=true') && importText.includes('process/fix_alpha_border=false'), 'Committed production mipmap/alpha import settings');
check(hash(read('assets/approved-changping.png')) === 'f92a8de6ef703bab4b2e471a49acc082dd4d128d264d99d3ed1818fdb0c93707', 'Approved campus painting remains unchanged');
check(hash(read('data/playable_route.json')) === '7042e3511177177b9db1501b587c0593376302cf707b22bf96b110d74d6fb7c6', 'Original 41-point route and walkable polygons unchanged');
check(profile.collision_footprints_source_xy.length === 2 && JSON.stringify(profile.collision_footprints_source_xy[0]) === JSON.stringify([[518,781],[573,780],[577,805],[518,805]]), 'Original south ground-foot collision retained');
console.log(`CHANGPING_LIBRARY_SOURCE ${checks.filter(Boolean).length}/${checks.length} passed`);
process.exitCode = checks.every(Boolean) ? 0 : 1;
