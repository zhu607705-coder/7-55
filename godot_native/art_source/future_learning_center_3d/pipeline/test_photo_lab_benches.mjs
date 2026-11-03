/** Independent reads of authored sources, emitted plain GLB and real Draco GLB.
 * These are data/geometry checks, not browser, photo-scale or product certification.
 * Run from the art root. Select a namespace or --baseline-only; no arguments tests both new lab-bench namespaces.
 */
import fs from 'node:fs/promises';
import crypto from 'node:crypto';
import {execFileSync} from 'node:child_process';
import {NodeIO, getBounds} from '@gltf-transform/core';
import {ALL_EXTENSIONS} from '@gltf-transform/extensions';
import draco3d from 'draco3dgltf';
import {groups, baseline, art, baselinePaths} from './build_photo_lab_benches.mjs';

const args = process.argv.slice(2);
const baselineOnly = args.length === 1 && args[0] === '--baseline-only';
const selectedNamespaces = baselineOnly ? [] : (args.length ? args : Object.keys(groups));
if (selectedNamespaces.some(n => !groups[n])) throw Error('Unknown lab-bench namespace.');
if (new Set(selectedNamespaces).size !== selectedNamespaces.length) throw Error('Select each namespace only once; duplicate batches are not valid coverage.');
const expectedCount = selectedNamespaces.reduce((n, key) => n + groups[key].expectedCount, 0);
const decoderModule = await draco3d.createDecoderModule();
const io = new NodeIO().registerExtensions(ALL_EXTENSIONS).registerDependencies({
  'draco3d.decoder': decoderModule
});
const sha = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const rows = [], assets = [], preserved = [], errors = [], sourceReports = [], sourceSnapshots = [], runtimeSnapshots = [], sourceFreezes = [], nativeSourceAudits = [], compositions = [];
function check(ok, label, details) {
  rows.push({pass: !!ok, label, ...(details === undefined ? {} : {details})});
  if (!ok) errors.push(label);
  return !!ok;
}
const dimensions = bounds => bounds.max.map((v, i) => v - bounds.min[i]);
const maxEdgeError = (a, b) => Math.max(...['min', 'max'].flatMap(k => a[k].map((v, i) => Math.abs(v - b[k][i]))));
const transformBlenderBounds = b => ({min: [b[0][0], b[0][2], -b[1][1]], max: [b[1][0], b[1][2], -b[0][1]]});

// New module-specific structural contracts will be finalized from independently
// inspected source geometry. A missing contract fails; it is never auto-approved.
const contracts = {
  photo_lab_center_four_leg_table: {range: [[1.8, 2.6], [.65, .85], [.8, 1.2]], parts: [/Thin rectangular pale laminate top/, /Square steel leg/, /Black floor glide/, /Inset under top long rail/, /Inset under top short rail/]},
  photo_lab_center_black_task_chair: {range: [[.5, .75], [.8, 1.05], [.5, .8]], parts: [/Broad rounded seat/, /Broad gently curved closed back/, /Arm pad/, /Seat post/, /Five star leg/, /Twin caster/]},
  photo_lab_center_open_shelf: {range: [[1.5, 2.1], [1.9, 2.5], [.3, .55]], parts: [/Thin square vertical frame/, /Thin grey shelf tray/, /Wood cubby back/, /Wood cubby side/]},
  photo_lab_center_plain_storage_box: {range: [[.25, .45], [.15, .3], [.2, .35]], parts: [/Unmarked storage box/, /Separate shallow lid/]},
  photo_lab_center_black_transit_case: {range: [[.5, .75], [.3, .55], [.35, .6]], parts: [/Tall transport case body/, /Wide lid/, /Lid perimeter joint/, /Front latch/, /Handle mount/, /Carry grip/]},
  photo_electronics_drawer_bench: {range: [[1.4, 1.9], [.7, .95], [.6, .9]], parts: [/Thick wood top/, /Square steel leg/, /Closed drawer cabinet/, /Drawer front/, /Recessed pull dark well/]},
  photo_electronics_back_shelf_frame: {range: [[1.4, 1.9], [1.15, 1.55], [.22, .45]], parts: [/Back upright/, /Rear shelf/, /Shelf front folded lip/, /Top rear rail/]},
  photo_electronics_wide_instrument_shell: {range: [[.25, .45], [.1, .22], [.23, .4]], parts: [/Neutral enclosed instrument shell/, /Front panel/, /Unlit blank glass/, /Unlabelled rectangular key/, /Neutral control dial/, /Rubber foot/]},
  photo_electronics_tall_instrument_shell: {range: [[.3, .5], [.22, .36], [.18, .34]], parts: [/Neutral enclosed instrument shell/, /Front panel/, /Unlit blank glass/, /Unlabelled rectangular key/, /Neutral control dial/, /Rubber foot/]},
  photo_electronics_green_cutting_mat: {range: [[.5, .7], [.002, .008], [.3, .5]], parts: [/Rounded green cutting mat/]},
  photo_electronics_open_bin: {range: [[.14, .25], [.06, .13], [.08, .17]], parts: [/Open bin floor/, /Open bin side wall/, /Open bin rear wall/, /Low front retaining lip/]}
};
const allowedTextures = {
  photo_lab_center_four_leg_table: ['synthetic_wood'],
  photo_electronics_drawer_bench: ['synthetic_wood_tile'],
  photo_electronics_green_cutting_mat: ['synthetic_grid_tile']
};
function semanticGeometry(doc, id) {
  const nodes = doc.getRoot().listNodes().filter(n => n.getMesh());
  const matching = pattern => nodes.filter(n => pattern.test(n.getName()));
  const bounds = name => {const n = nodes.find(n => n.getName() === name); if (!n) throw Error(`${id}: missing structural mesh ${name}`); return getBounds(n);};
  check(nodes.length > 0, `${id}: independent authored mesh geometry exists`);
  check(!nodes.some(n => /render.only|studio.stage|camera|area.light|backdrop/i.test(n.getName())), `${id}: no render-stage mesh in model source`);
  if (!contracts[id]) throw Error(`${id}: semantic geometry contract is not finalized`);
  if (id === 'photo_lab_center_four_leg_table') {
    const top = bounds('Thin rectangular pale laminate top'), legs = matching(/^Square steel leg/).map(getBounds);
    check(dimensions(top)[1] < .05 && legs.length === 4 && matching(/^Black floor glide/).length === 4 && legs.every(b => b.min[1] < .04 && Math.abs(b.max[1] - top.min[1]) < .004), `${id}: thin rectangular top contacts four floor-reaching steel legs`, {top, legs});
  } else if (id === 'photo_lab_center_black_task_chair') {
    const seat = bounds('Broad rounded seat'), back = bounds('Broad gently curved closed back');
    check(back.max[1] > seat.max[1] + .3 && matching(/^Arm pad/).length === 2 && matching(/^Five star leg/).length === 5 && matching(/^Twin caster/).length === 10, `${id}: raised back, two arms, five-star base and ten twin-caster wheels`, {seat, back});
  } else if (id === 'photo_lab_center_open_shelf') {
    const trays = matching(/^Thin grey shelf tray/).map(getBounds).sort((a, b) => a.min[1] - b.min[1]);
    check(trays.length === 6 && trays.every((b, i) => dimensions(b)[0] > 1.8 && (!i || b.min[1] - trays[i - 1].max[1] > .2)) && matching(/^Thin square vertical frame/).length === 8 && matching(/^Wood cubby back/).length === 6 && matching(/^Wood cubby side/).length === 12, `${id}: six separated shelf levels and six open wood-lined cubbies in an eight-upright frame`, trays);
  } else if (id === 'photo_lab_center_plain_storage_box') {
    const box = bounds('Unmarked storage box'), lid = bounds('Separate shallow lid');
    check(lid.max[1] > box.max[1] && dimensions(lid)[1] < .04 && dimensions(lid)[0] >= dimensions(box)[0] && dimensions(lid)[2] >= dimensions(box)[2], `${id}: separate shallow lid overlaps the unmarked box edges`, {box, lid});
  } else if (id === 'photo_lab_center_black_transit_case') {
    check(matching(/^Front latch/).length === 2 && matching(/^Handle mount/).length === 2 && dimensions(bounds('Carry grip'))[0] > .15 && bounds('Wide lid').max[1] > bounds('Tall transport case body').max[1], `${id}: separate lid, two latches and a spanning carry grip`);
  } else if (id === 'photo_electronics_drawer_bench') {
    const top = bounds('Thick wood top'), drawers = matching(/^Drawer front/).map(getBounds).sort((a, b) => a.min[0] - b.min[0]);
    check(dimensions(top)[1] > .035 && dimensions(top)[1] < .065 && matching(/^Square steel leg/).length === 4 && drawers.length === 2 && drawers[0].max[0] < drawers[1].min[0] && drawers.every(b => b.max[1] < top.min[1]), `${id}: thick bench top on four legs above two distinct drawer fronts`, {top, drawers});
  } else if (id === 'photo_electronics_back_shelf_frame') {
    const shelves = matching(/^Rear shelf/).map(getBounds).sort((a, b) => a.min[1] - b.min[1]);
    check(matching(/^Back upright/).length === 2 && shelves.length === 2 && shelves[1].min[1] > shelves[0].max[1] + .5, `${id}: two full-width upper shelves held by two rear uprights`, shelves);
  } else if (/photo_electronics_(wide|tall)_instrument_shell/.test(id)) {
    const shell = bounds('Neutral enclosed instrument shell'), size = dimensions(shell), wide = id.includes('_wide_');
    check((wide ? size[1] / size[0] < .5 : size[1] / size[0] > .65) && matching(/^Neutral control dial/).length === (wide ? 1 : 2) && matching(/^Rubber foot/).length === 4, `${id}: distinct wide/tall housing proportions, simple controls and four feet`, {shell, aspect: size[1] / size[0]});
    const glassNode = nodes.find(n => n.getName() === 'Unlit blank glass');
    check(glassNode.getMesh().listPrimitives().every(p => !p.getMaterial().getBaseColorTexture() && p.getMaterial().getEmissiveFactor().every(v => v === 0)), `${id}: screen remains unlit and blank, without fabricated readings`);
  } else if (id === 'photo_electronics_green_cutting_mat') {
    const size = dimensions(bounds('Rounded green cutting mat'));
    check(size[1] <= .006 && size[0] / size[2] > 1.4 && size[0] / size[2] < 1.6, `${id}: thin 3:2 mat with an authored repeating grid, not photo pixels`, size);
  } else if (id === 'photo_electronics_open_bin') {
    const rear = bounds('Open bin rear wall'), lip = bounds('Low front retaining lip');
    check(matching(/^Open bin side wall/).length === 2 && lip.max[1] < rear.max[1] * .7, `${id}: two side walls, high rear wall and lower open front lip`, {rear, lip});
  }
}

function parseGLB(bytes, label, compressed) {
  if (!check(bytes.readUInt32LE(0) === 0x46546c67 && bytes.readUInt32LE(4) === 2 && bytes.readUInt32LE(8) === bytes.length, `${label}: valid complete GLB 2 container`)) throw Error(`${label}: malformed GLB`);
  const json = JSON.parse(bytes.subarray(20, 20 + bytes.readUInt32LE(12)).toString());
  if (!check(![...(json.buffers ?? []), ...(json.images ?? [])].some(r => r.uri), `${label}: all buffers and images embedded, no external resources`)) throw Error(`${label}: external resources are not allowed`);
  check((json.scenes?.length === 1) && (json.nodes?.length > 0), `${label}: one nonempty static scene`);
  check(!(json.skins?.length || json.animations?.length || json.cameras?.length || json.extensions?.KHR_lights_punctual), `${label}: no rig, animation, camera or active scene lights`);
  if (compressed) check(json.meshes?.length > 0 && json.meshes.every(m => m.primitives.length && m.primitives.every(p => Number.isInteger(p.extensions?.KHR_draco_mesh_compression?.bufferView))), `${label}: actual Draco-coded primitives`);
  return json;
}

function inspectDracoBitstream(bytes, json, label) {
  const d = decoderModule, bin = bytes.subarray(28 + bytes.readUInt32LE(12));
  let triangles = 0, valid = true;
  const encodedPositionBits = [];
  for (const meshJSON of json.meshes) for (const primitive of meshJSON.primitives) {
    const extension = primitive.extensions.KHR_draco_mesh_compression;
    const view = json.bufferViews[extension.bufferView];
    const raw = bin.subarray(view.byteOffset ?? 0, (view.byteOffset ?? 0) + view.byteLength);
    const decoder = new d.Decoder(), buffer = new d.DecoderBuffer(), mesh = new d.Mesh(), transform = new d.AttributeQuantizationTransform();
    let status;
    try {
      buffer.Init(raw, raw.length);
      // Read quantization metadata from the compressed attribute itself; the
      // manifest's encoding.positionBits is not accepted as independent proof.
      decoder.SkipAttributeTransform(d.POSITION);
      status = decoder.DecodeBufferToMesh(buffer, mesh);
      valid &&= status.ok() && mesh.num_faces() > 0;
      if (!status.ok()) throw Error(`${label}: direct Draco decode failed`);
      const attribute = decoder.GetAttributeByUniqueId(mesh, extension.attributes.POSITION);
      const hasQuantization = transform.InitFromAttribute(attribute);
      const bits = hasQuantization ? transform.quantization_bits() : null;
      encodedPositionBits.push(bits);
      valid &&= bits === 20;
      triangles += mesh.num_faces();
    } finally {
      for (const object of [transform, status, mesh, buffer, decoder]) if (object) d.destroy(object);
    }
  }
  check(valid, `${label}: direct Draco bitstream decode proves 20-bit positions`, {encodedPositionBits, triangles});
  return triangles;
}

function geometry(doc, label) {
  let triangles = 0, finite = true, validIndices = true, degenerate = 0, normalsValid = true, topology = true, materialLinks = true;
  const invalidParts = [];
  for (const mesh of doc.getRoot().listMeshes()) for (const p of mesh.listPrimitives()) {
    const pos = p.getAttribute('POSITION'), normal = p.getAttribute('NORMAL');
    topology &&= p.getMode() === 4;
    materialLinks &&= !!p.getMaterial();
    if (!pos || pos.getElementSize() !== 3) {finite = false; continue;}
    const a = pos.getArray(), order = p.getIndices()?.getArray() ?? Array.from({length: pos.getCount()}, (_, i) => i);
    triangles += order.length / 3;
    finite &&= [...a].every(Number.isFinite);
    validIndices &&= order.length % 3 === 0 && [...order].every(i => Number.isInteger(i) && i >= 0 && i < pos.getCount());
    if (!normal || normal.getCount() !== pos.getCount() || normal.getElementSize() !== 3) normalsValid = false;
    else {
      const a = normal.getArray();
      for (let i = 0; i < a.length; i += 3) normalsValid &&= Number.isFinite(Math.hypot(a[i], a[i + 1], a[i + 2])) && Math.abs(Math.hypot(a[i], a[i + 1], a[i + 2]) - 1) < .01;
    }
    let bad = 0;
    for (let i = 0; i < order.length; i += 3) {
      const x = order[i] * 3, y = order[i + 1] * 3, z = order[i + 2] * 3;
      const ux = a[y] - a[x], uy = a[y + 1] - a[x + 1], uz = a[y + 2] - a[x + 2];
      const vx = a[z] - a[x], vy = a[z + 1] - a[x + 1], vz = a[z + 2] - a[x + 2];
      if (Math.hypot(uy * vz - uz * vy, uz * vx - ux * vz, ux * vy - uy * vx) < 1e-12) bad++;
    }
    degenerate += bad;
    if (bad) invalidParts.push({mesh: mesh.getName(), material: p.getMaterial()?.getName(), degenerate: bad});
    for (const semantic of p.listSemantics()) {
      const attr = p.getAttribute(semantic);
      finite &&= [...attr.getArray()].every(Number.isFinite) && attr.getCount() === pos.getCount();
    }
  }
  check(topology && triangles > 0 && Number.isInteger(triangles), `${label}: nonempty triangle topology`, triangles);
  check(finite && validIndices, `${label}: finite aligned attributes and valid indices`);
  check(normalsValid, `${label}: finite unit normals on every vertex`);
  check(degenerate === 0, `${label}: no zero-area triangles`, {degenerate, invalidParts});
  check(materialLinks, `${label}: every primitive has an assigned material`);
  let sceneTriangles = 0;
  doc.getRoot().listScenes()[0].traverse(n => { for (const p of n.getMesh()?.listPrimitives() ?? []) sceneTriangles += (p.getIndices()?.getCount() ?? p.getAttribute('POSITION').getCount()) / 3; });
  return {triangles, sceneTriangles, degenerate};
}

function materials(doc, label, id, level) {
  const root = doc.getRoot(), mats = root.listMaterials(), textures = root.listTextures();
  check(mats.length >= 1 && mats.length <= 32, `${label}: bounded distinct material groups`, mats.length);
  check(mats.every(m => [m.getMetallicFactor(), m.getRoughnessFactor(), ...m.getBaseColorFactor()].every(v => Number.isFinite(v) && v >= 0 && v <= 1) && m.getEmissiveFactor().every(v => Number.isFinite(v) && v >= 0) && ['OPAQUE', 'MASK', 'BLEND'].includes(m.getAlphaMode())), `${label}: finite valid metallic-roughness PBR factors`);
  check(textures.every(t => (allowedTextures[id] ?? []).includes(t.getName())), `${label}: only declared synthetic material images, never the input photograph`);
  check(textures.every(t => t.getImage()?.length > 0 && ['image/png', 'image/jpeg'].includes(t.getMimeType()) && t.getSize()?.every(v => Number.isInteger(v) && v > 0 && v <= Math.max(256, 1024 / 2 ** level))), `${label}: embedded valid bounded texture images`);
  for (const mesh of root.listMeshes()) for (const p of mesh.listPrimitives()) if (p.getMaterial()?.getBaseColorTexture() || p.getMaterial()?.getNormalTexture()) check(!!p.getAttribute('TEXCOORD_0'), `${label}: textured primitive supplies UV coordinates`);
  const factors = mats.map(m => ({
    name: m.getName(), baseColor: m.getBaseColorFactor(), metallic: m.getMetallicFactor(),
    roughness: m.getRoughnessFactor(), emissive: m.getEmissiveFactor(),
    alphaMode: m.getAlphaMode(), alphaCutoff: m.getAlphaCutoff(), doubleSided: m.getDoubleSided(),
    baseColorTexture: m.getBaseColorTexture()?.getName() ?? null,
    normalTexture: m.getNormalTexture()?.getName() ?? null,
    metalRoughTexture: m.getMetallicRoughnessTexture()?.getName() ?? null,
    occlusionTexture: m.getOcclusionTexture()?.getName() ?? null,
    emissiveTexture: m.getEmissiveTexture()?.getName() ?? null
  })).sort((a, b) => a.name.localeCompare(b.name));
  return {names: mats.map(m => m.getName()).sort(), factors, textureHashes: textures.map(t => sha(t.getImage())).sort()};
}

function worldTriangles(node) {
  const matrix = node.getWorldMatrix(), out = [];
  for (const primitive of node.getMesh().listPrimitives()) {
    const position = primitive.getAttribute('POSITION');
    const indices = primitive.getIndices()?.getArray() ?? Array.from({length: position.getCount()}, (_, i) => i);
    const points = Array.from({length: position.getCount()}, (_, i) => {
      const p = position.getElement(i, []);
      return [0, 1, 2].map(k => matrix[k] * p[0] + matrix[k + 4] * p[1] + matrix[k + 8] * p[2] + matrix[k + 12]);
    });
    for (let i = 0; i < indices.length; i += 3) out.push([points[indices[i]], points[indices[i + 1]], points[indices[i + 2]]]);
  }
  return out;
}
function checkOpenBin(doc, label) {
  const b = getBounds(doc.getRoot().listScenes()[0]), x = (b.min[0] + b.max[0]) / 2, z = (b.min[2] + b.max[2]) / 2;
  const hits = [];
  for (const node of doc.getRoot().listNodes().filter(n => n.getMesh())) for (const [a, b, c] of worldTriangles(node)) {
    const determinant = (b[2] - c[2]) * (a[0] - c[0]) + (c[0] - b[0]) * (a[2] - c[2]);
    if (Math.abs(determinant) < 1e-14) continue;
    const u = ((b[2] - c[2]) * (x - c[0]) + (c[0] - b[0]) * (z - c[2])) / determinant;
    const v = ((c[2] - a[2]) * (x - c[0]) + (a[0] - c[0]) * (z - c[2])) / determinant;
    if (Math.min(u, v, 1 - u - v) >= -1e-7) hits.push(u * a[1] + v * b[1] + (1 - u - v) * c[1]);
  }
  const topHit = hits.length ? Math.max(...hits) : Infinity;
  check(Number.isFinite(topHit) && topHit - b.min[1] <= (b.max[1] - b.min[1]) * .25, `${label}: actual vertical triangle ray reaches the floor through the open top`, {topHit, floor: b.min[1], height: b.max[1] - b.min[1]});
}
async function checkCompositionReferences(namespaces) {
  const previous = JSON.parse(await fs.readFile('review/photo_lab_benches/baseline.json'));
  const known = new Map();
  for (const file of previous.files.filter(f => f.path.endsWith('.blend'))) {
    const id = file.path.split('/').at(-2);
    known.set(id, {file: file.path, previous: true, sha256: file.sha256});
  }
  for (const [namespace, group] of Object.entries(groups)) for (const id of group.ids) known.set(id, {file: `sources/models/${namespace}/${id}/${id}.blend`, previous: false});
  for (const namespace of namespaces) try {
    const file = `sources/models/${namespace}/composition.json`, bytes = await fs.readFile(file), composition = JSON.parse(bytes);
    sourceSnapshots.push({file, sha256: sha(bytes)});
    check(composition.units === 'metres' && composition.coordinateSystem === 'Blender Z-up', `${namespace}: composition explicitly uses metres and Blender Z-up`);
    check(Array.isArray(composition.instances) && composition.instances.length > 0, `${namespace}: composition has explicit asset instances`);
    const instanceIds = composition.instances.map(i => i.instanceId);
    check(instanceIds.every(id => typeof id === 'string' && id.length > 0) && new Set(instanceIds).size === instanceIds.length, `${namespace}: instance IDs are unique while asset references may repeat`);
    check(groups[namespace].ids.every(id => composition.instances.some(i => i.assetId === id)), `${namespace}: all new module assets are placed by reference`);
    const materialCatalog = new Map(), referenceMaterials = new Map();
    for (const id of groups[namespace].ids) {
      const doc = await io.read(`sources/models/${namespace}/${id}/lod0_source.glb`);
      for (const material of doc.getRoot().listMaterials()) materialCatalog.set(material.getName(), material.getBaseColorFactor());
    }
    let reused = 0;
    const reusedAssetIds = new Set();
    for (const instance of composition.instances) {
      const label = `${namespace} instance ${instance.instanceId}`, reference = known.get(instance.assetId);
      if (!check(!!reference && instance.sourcePath === reference.file, `${label}: canonical existing independent native source reference`, {assetId: instance.assetId, sourcePath: instance.sourcePath})) continue;
      const native = await fs.readFile(reference.file);
      check(native.subarray(0, 7).toString() === 'BLENDER', `${label}: referenced native source exists and opens as a Blender file header`);
      check(instance.sourceSha256 === sha(native), `${label}: declared source hash matches the actual referenced native bytes`);
      if (reference.previous) {
        reused++;
        reusedAssetIds.add(instance.assetId);
        check(sha(native) === reference.sha256, `${label}: reused old source remains byte-identical to the immutable 37-asset baseline`);
      }
      check(Array.isArray(instance.position) && instance.position.length === 3 && instance.position.every(Number.isFinite) && Array.isArray(instance.rotationEuler) && instance.rotationEuler.length === 3 && instance.rotationEuler.every(Number.isFinite), `${label}: finite Blender position and Euler rotation in radians`);
      check(Array.isArray(instance.scale) && instance.scale.length === 3 && instance.scale.every(v => v === 1), `${label}: reference uses original size without stretching or silently rescaling`);
      if (instance.assetId === 'photo_workshop_square_hole_board') check(instance.materialOverrides && Object.keys(instance.materialOverrides).length > 0, `${label}: existing square-hole board is recolored through an instance override only`);
      if (instance.materialOverrides !== undefined) {
        const serialized = JSON.stringify(instance.materialOverrides);
        check(!/"(?:uri|texture|image|file|path)"\s*:/i.test(serialized), `${label}: material override contains no external image or resource reference`);
        const numeric = value => typeof value === 'number' ? Number.isFinite(value) && value >= 0 && value <= 1 : Array.isArray(value) ? value.every(numeric) : value && typeof value === 'object' ? Object.values(value).every(numeric) : typeof value === 'string' || typeof value === 'boolean' || value === null;
        check(numeric(instance.materialOverrides), `${label}: instance material override has finite bounded PBR values`);
        if (!referenceMaterials.has(instance.assetId)) {
          const sourceGLB = reference.file.slice(0, reference.file.lastIndexOf('/') + 1) + 'lod0_source.glb';
          const doc = await io.read(sourceGLB);
          referenceMaterials.set(instance.assetId, new Set(doc.getRoot().listMaterials().map(m => m.getName())));
        }
        for (const [slot, target] of Object.entries(instance.materialOverrides)) {
          check(slot === 'allSlots' || referenceMaterials.get(instance.assetId).has(slot), `${label}: override addresses an actual source material slot`, slot);
          if (typeof target === 'string') {
            check(materialCatalog.has(target), `${label}: named override resolves to an existing module material`, target);
            if (instance.assetId === 'photo_workshop_square_hole_board') {
              const color = materialCatalog.get(target)?.slice(0, 3) ?? [];
              check(color.length === 3 && Math.max(...color) - Math.min(...color) <= .06, `${label}: square-hole board override is a neutral grey material`, {target, color});
            }
          }
        }
      }
    }
    check(reused > 0, `${namespace}: composition genuinely reuses prior asset IDs`, {reusedInstances: reused});
    const requiredReuse = namespace === 'photo_lab_center' ? ['photo_monitor_stand', 'photo_keyboard', 'photo_mouse'] : ['photo_workshop_square_hole_board', 'photo_monitor_stand', 'photo_workshop_blue_driver_rack', 'photo_workshop_red_flat_case'];
    check(requiredReuse.every(id => reusedAssetIds.has(id)), `${namespace}: expected old props are reused rather than exported as new duplicates`, [...reusedAssetIds]);
    check(!['meshes', 'vertices', 'buffers', 'geometry'].some(key => key in composition) && composition.instances.every(i => !['meshes', 'vertices', 'buffers', 'geometry'].some(key => key in i)), `${namespace}: composition holds references and transforms, no duplicated mesh payload`);
    compositions.push({namespace, file, sha256: sha(bytes), instances: composition.instances.length, distinctAssetIds: [...new Set(composition.instances.map(i => i.assetId))], reusedInstances: reused, reusedAssetIds: [...reusedAssetIds].sort()});
  } catch (error) {check(false, `${namespace}: composition reference validation completed`, error.stack);}
}

for (const namespace of selectedNamespaces) {
  const ids = groups[namespace].ids, reportName = namespace;
  let report;
  try {
    const reportFile = `review/${namespace}/build_report.json`, reportBytes = await fs.readFile(reportFile);
    sourceReports.push({file: reportFile, sha256: sha(reportBytes), bytes: reportBytes.length});
    report = JSON.parse(reportBytes);
    check(report.units === 'm', `${reportName}: explicitly metric source receipt`);
    check(report.records.length === ids.length * 3 && report.records.every(r => ids.includes(r.asset) && [0, 1, 2].includes(r.level)), `${reportName}: complete declared batch, no hidden additional asset`);
  } catch (error) {check(false, `${reportName}: readable source receipt`, error.message); continue;}
  for (const id of ids) try {
    const sourceBase = `sources/models/${namespace}/${id}/`, runtimeBase = `web/assets/models/${namespace}/${id}/`;
    const manifestBytes = await fs.readFile(runtimeBase + 'manifest.json'), manifest = JSON.parse(manifestBytes);
    runtimeSnapshots.push({file: runtimeBase + 'manifest.json', sha256: sha(manifestBytes)});
    const receiptSets = [0, 1, 2].map(level => report.records.filter(r => r.asset === id && r.level === level));
    if (!check(receiptSets.every(r => r.length === 1), `${id}: exactly one authored source receipt per level`)) continue;
    check(manifest.levels.length === 3 && manifest.levels.map(r => r.level).join(',') === '0,1,2', `${id}: three ordered runtime LODs`);
    check(manifest.encoding.positionBits === 20, `${id}: explicit 20-bit Draco position encoding`);
    check(Math.abs(manifest.calibration.uniformScale - 1) < 1e-5 && manifest.calibration.yawDegrees === 0, `${id}: no concealed scale or facing correction`);
    const blend = await fs.readFile(sourceBase + id + '.blend');
    check(blend.subarray(0, 7).toString() === 'BLENDER', `${id}: native editable Blender source`);
    sourceSnapshots.push({file: sourceBase + id + '.blend', sha256: sha(blend)});
    const asset = {id, namespace, nativeSourceSha256: sha(blend), levels: []};
    const nearBytes = await fs.readFile(sourceBase + 'lod0_source.glb');
    const nearDoc = await io.readBinary(nearBytes), nearBounds = getBounds(nearDoc.getRoot().listScenes()[0]);
    const offset = [-(nearBounds.min[0] + nearBounds.max[0]) / 2, -nearBounds.min[1], -(nearBounds.min[2] + nearBounds.max[2]) / 2];
    check(manifest.source.sha256 === sha(nearBytes) && manifest.source.bytes === nearBytes.length, `${id}: manifest points to exact near source`);
    const partNodes = nearDoc.getRoot().listNodes().filter(n => n.getMesh()).map(n => n.getName());
    for (const part of contracts[id].parts) check(partNodes.some(n => part.test(n)), `${id}: independent authored mesh part ${part}`);
    semanticGeometry(nearDoc, id);
    for (const level of manifest.levels) {
      const label = `${id} LOD${level.level}`, receipt = receiptSets[level.level][0];
      check(level.file === `lod${level.level}.draco.glb` && level.uncompressedFile === `lod${level.level}.glb` && level.inputFile === `lod${level.level}_source.glb`, `${label}: exact declared source and output filenames`);
      const sourceBytes = await fs.readFile(sourceBase + `lod${level.level}_source.glb`);
      sourceSnapshots.push({file: sourceBase + `lod${level.level}_source.glb`, sha256: sha(sourceBytes)});
      parseGLB(sourceBytes, label + ' source', false);
      const source = await io.readBinary(sourceBytes), sourceBounds = getBounds(source.getRoot().listScenes()[0]), sourceSize = dimensions(sourceBounds);
      const sourceGeometry = geometry(source, label + ' source'), sourceMaterials = materials(source, label + ' source', id, level.level);
      if (id === 'photo_electronics_open_bin') checkOpenBin(source, label + ' source');
      for (const texture of source.getRoot().listTextures()) {
        if (!(allowedTextures[id] ?? []).includes(texture.getName())) throw Error(`${label}: undeclared source texture`);
        const imageFile = texture.getName() + '.png';
        const authoredImage = await fs.readFile(sourceBase + imageFile);
        sourceSnapshots.push({file: sourceBase + imageFile, sha256: sha(authoredImage)});
        check(sha(authoredImage) === sha(texture.getImage()), `${label}: embedded synthetic image matches its editable source PNG`, texture.getName());
      }
      check(sourceGeometry.sceneTriangles === receipt.triangles, `${label}: actual source triangles match Blender receipt`, {actual: sourceGeometry.sceneTriangles, receipt: receipt.triangles});
      check(sha(sourceBytes) === receipt.sha256 && sha(sourceBytes) === level.inputSha256, `${label}: exact source and receipt hashes`);
      check(maxEdgeError(sourceBounds, transformBlenderBounds(receipt.boundsBlenderXYZ)) < 1e-5 && sourceSize.every((v, i) => Math.abs(v - [receipt.sizeBlenderXYZ[0], receipt.sizeBlenderXYZ[2], receipt.sizeBlenderXYZ[1]][i]) < 1e-5), `${label}: independently measured bounds match Blender XYZ receipt`, sourceBounds);
      check(sourceSize.every((v, i) => v >= contracts[id].range[i][0] && v <= contracts[id].range[i][1]), `${label}: plausible metre envelope, not certified photo dimensions`, sourceSize);
      const plainBytes = await fs.readFile(runtimeBase + level.uncompressedFile), compressedBytes = await fs.readFile(runtimeBase + level.file);
      runtimeSnapshots.push({file: runtimeBase + level.uncompressedFile, sha256: sha(plainBytes)}, {file: runtimeBase + level.file, sha256: sha(compressedBytes)});
      parseGLB(plainBytes, label + ' plain', false);
      const encodedJSON = parseGLB(compressedBytes, label + ' Draco', true);
      const directDracoTriangles = inspectDracoBitstream(compressedBytes, encodedJSON, label);
      const plain = await io.readBinary(plainBytes), decoded = await io.readBinary(compressedBytes);
      const plainGeometry = geometry(plain, label + ' plain'), decodedGeometry = geometry(decoded, label + ' Draco');
      if (id === 'photo_electronics_open_bin') {checkOpenBin(plain, label + ' plain'); checkOpenBin(decoded, label + ' Draco');}
      const plainMaterials = materials(plain, label + ' plain', id, level.level), decodedMaterials = materials(decoded, label + ' Draco', id, level.level);
      check(JSON.stringify(plainMaterials) === JSON.stringify(decodedMaterials), `${label}: Draco preserves material names and embedded image bytes`);
      check(sourceMaterials.names.every(n => plainMaterials.names.includes(n)), `${label}: material groups survive optimization`);
      check(sourceMaterials.factors.every(m => plainMaterials.factors.some(p => JSON.stringify(m) === JSON.stringify(p))) && JSON.stringify(sourceMaterials.textureHashes) === JSON.stringify(plainMaterials.textureHashes), `${label}: optimization retains authored PBR factors and texture bytes`);
      check(compressedBytes.length === level.bytes && sha(compressedBytes) === level.sha256 && plainBytes.length === level.uncompressedBytes, `${label}: runtime file sizes and exact compressed hash`);
      check(decodedGeometry.triangles === directDracoTriangles && decodedGeometry.triangles === level.triangles && decodedGeometry.sceneTriangles === plainGeometry.sceneTriangles && decodedGeometry.triangles === plainGeometry.triangles, `${label}: actual Draco decoding preserves emitted plain triangle count`, {source: sourceGeometry.sceneTriangles, plain: plainGeometry.triangles, decoded: decodedGeometry.triangles, directDracoTriangles});
      const plainBounds = getBounds(plain.getRoot().listScenes()[0]), decodedBounds = getBounds(decoded.getRoot().listScenes()[0]);
      const expectedBounds = Object.fromEntries(['min', 'max'].map(k => [k, sourceBounds[k].map((v, i) => v + offset[i])]));
      const sourceToPlainErrorM = maxEdgeError(expectedBounds, plainBounds), plainToDracoErrorM = maxEdgeError(plainBounds, decodedBounds);
      // A simplifying LOD is compared to its own source, not another LOD's details.
      // Bound simplification error by its configured relative error and a 2mm cap.
      const simplified = plainGeometry.sceneTriangles < sourceGeometry.sceneTriangles;
      const sourceEnvelopeToleranceM = simplified ? Math.min(.002, Math.max(.0001, level.error * Math.max(...sourceSize))) : .0001;
      check(sourceToPlainErrorM <= sourceEnvelopeToleranceM, `${label}: metric source envelope preserved by optimization`, {sourceToPlainErrorM, sourceEnvelopeToleranceM, simplified});
      check(plainToDracoErrorM < .0001, `${label}: measured Draco edge error below 0.1mm`, {plainToDracoErrorM});
      // build_asset measures its pre-write JS geometry, whereas this test reads
      // actual float32 plain GLB bytes. Permit one float32 rounding unit only.
      const float32RoundoffM = Math.max(...sourceSize) * 2 ** -23 + 1e-9;
      check(Math.abs(plainToDracoErrorM - level.boundsEncodingErrorM) <= float32RoundoffM, `${label}: encoding-error receipt agrees within float32 serialization precision`, {plainToDracoErrorM, reportedErrorM: level.boundsEncodingErrorM, float32RoundoffM});
      check(maxEdgeError(decodedBounds, level.bounds) < 1e-8, `${label}: decoded bounds match manifest`);
      check(Math.abs(decodedBounds.min[1] - expectedBounds.min[1]) <= sourceEnvelopeToleranceM + .0001, `${label}: shared near-source grounding retained`);
      if (level.level === 0) check(Math.abs(decodedBounds.min[0] + decodedBounds.max[0]) < .001 && Math.abs(decodedBounds.min[2] + decodedBounds.max[2]) < .001 && Math.abs(decodedBounds.min[1]) < .001, `${label}: centered grounded near pivot`);
      asset.levels.push({level: level.level, sourceFile: sourceBase + `lod${level.level}_source.glb`, sourceSha256: sha(sourceBytes), plainFile: runtimeBase + level.uncompressedFile, plainSha256: sha(plainBytes), dracoFile: runtimeBase + level.file, sourceTriangles: sourceGeometry.sceneTriangles, plainTriangles: plainGeometry.triangles, decodedTriangles: decodedGeometry.triangles, sourceSize, decodedSize: dimensions(decodedBounds), sourceToPlainErrorM, plainToDracoErrorM, sourceEnvelopeToleranceM, bytes: compressedBytes.length, sha256: sha(compressedBytes)});
    }
    check(asset.levels.length === 3 && asset.levels[0].sourceTriangles > asset.levels[1].sourceTriangles && asset.levels[1].sourceTriangles > asset.levels[2].sourceTriangles, `${id}: independently authored decreasing source LODs`);
    check(asset.levels.length === 3 && asset.levels[0].decodedTriangles > asset.levels[1].decodedTriangles && asset.levels[1].decodedTriangles > asset.levels[2].decodedTriangles, `${id}: genuinely decreasing decoded LODs`);
    assets.push(asset);
  } catch (error) {check(false, `${id}: validation completed without exception`, error.stack);}
}

async function sourceFilesIn(directory) {
  const paths = [];
  for (const entry of await fs.readdir(directory, {withFileTypes: true})) {
    const file = directory + '/' + entry.name;
    if (entry.isSymbolicLink()) throw Error(`Source trees may not contain external file links: ${file}`);
    if (entry.isDirectory()) paths.push(...await sourceFilesIn(file));
    else paths.push(file);
  }
  return paths;
}
for (const namespace of selectedNamespaces) try {
  const file = `review/${namespace}/source_freeze.json`, bytes = await fs.readFile(file), freeze = JSON.parse(bytes);
  const files = freeze.sourceFiles ?? freeze.files;
  if (!check((freeze.state ?? freeze.status) === 'frozen' && Array.isArray(files) && files.length > 0, `${namespace}: explicit final source-freeze receipt`)) continue;
  const root = `sources/models/${namespace}/`;
  if (!check(files.every(f => typeof f.path === 'string' && f.path.startsWith(root) && !f.path.includes('/../')), `${namespace}: frozen paths stay inside the assigned new source namespace`)) continue;
  const actualFiles = await sourceFilesIn(root.slice(0, -1));
  check(JSON.stringify(files.map(f => f.path).sort()) === JSON.stringify(actualFiles.sort()), `${namespace}: frozen inventory includes all native, GLB, tile and composition files`);
  for (const record of files) {
    const content = await fs.readFile(record.path);
    check(sha(content) === record.sha256 && content.length === record.bytes, `${namespace}: final frozen source bytes match ${record.path}`);
    sourceSnapshots.push({file: record.path, sha256: sha(content)});
  }
  sourceSnapshots.push({file, sha256: sha(bytes)});
  sourceFreezes.push({namespace, file, sha256: sha(bytes), sourceFileCount: files.length});
} catch (error) {check(false, `${namespace}: frozen source inventory validation completed`, error.stack);}

// Open each native file in the already installed Blender with auto-execution
// disabled. This only reads source files; it neither renders nor saves them.
if (assets.length) try {
  const entries = assets.map(a => ({asset: a.id, file: `sources/models/${a.namespace}/${a.id}/${a.id}.blend`}));
  const python = `import bpy,json,re\nfrom pathlib import Path\nentries=json.loads(${JSON.stringify(JSON.stringify(entries))})\nresults=[]\nfor entry in entries:\n try:\n  bpy.ops.wm.open_mainfile(filepath=str(Path(entry['file']).resolve()),load_ui=False,use_scripts=False)\n  result=dict(entry)\n  result.update({'meshObjects':sum(o.type=='MESH' for o in bpy.data.objects),'cameras':len(bpy.data.cameras),'lights':len(bpy.data.lights),'stages':[o.name for o in bpy.data.objects if re.search(r'render.only|studio.stage|backdrop',o.name,re.I)],'unpackedImages':[i.name for i in bpy.data.images if i.users and i.source=='FILE' and not i.packed_file],'usedImages':[i.name for i in bpy.data.images if i.users and i.source in ['FILE','GENERATED']],'metric':bpy.context.scene.unit_settings.system=='METRIC' and abs(bpy.context.scene.unit_settings.scale_length-1)<1e-8})\n  results.append(result)\n except Exception as error:\n  results.append(dict(entry,error=str(error)))\nprint('SOURCE_BLEND_AUDIT_JSON '+json.dumps(results),flush=True)\n`;
  await fs.mkdir('/tmp/flc-photo-lab-benches-blender-config', {recursive: true});
  const output = execFileSync('blender', ['--background', '--factory-startup', '--disable-autoexec', '--threads', '1', '--python-expr', python], {encoding: 'utf8', timeout: 180000, maxBuffer: 16 * 1024 * 1024, env: {...process.env, BLENDER_USER_CONFIG: '/tmp/flc-photo-lab-benches-blender-config'}});
  const line = output.split('\n').find(line => line.startsWith('SOURCE_BLEND_AUDIT_JSON '));
  if (!line) throw Error('Blender did not return a native-source audit.');
  nativeSourceAudits.push(...JSON.parse(line.slice('SOURCE_BLEND_AUDIT_JSON '.length)));
  for (const audit of nativeSourceAudits) {
    check(!audit.error && audit.meshObjects > 0 && audit.metric, `${audit.asset}: native Blender source opens with real metric mesh objects`, audit);
    check(audit.cameras === 0 && audit.lights === 0 && audit.stages?.length === 0, `${audit.asset}: native source contains no camera, light or render-stage object`);
    check(audit.unpackedImages?.length === 0, `${audit.asset}: native source image textures are packed`, {usedImages: audit.usedImages, unpackedImages: audit.unpackedImages});
  }
} catch (error) {check(false, 'independent native Blender source inspection completed', error.message);}

// Independent immutable-byte preservation check. A saved manifest alone is not
// proof: each recorded digest is checked against the actual baseline git object.
try {
  const saved = JSON.parse(await fs.readFile('review/photo_lab_benches/baseline.json'));
  const paths = baselinePaths();
  check(saved.baselineCommit === baseline && saved.assets.length === 37, 'exact baseline commit and 37 preserved asset identities');
  check(JSON.stringify(saved.files.map(f => art + f.path).sort()) === JSON.stringify(paths.slice().sort()), 'baseline receipt includes every committed prior asset file');
  for (const file of saved.files) {
    const before = execFileSync('git', ['show', baseline + ':' + art + file.path], {maxBuffer: 128 * 1024 * 1024});
    const now = await fs.readFile(file.path);
    check(sha(before) === file.sha256 && before.length === file.bytes, 'baseline digest independently verified: ' + file.path);
    check(now.equals(before), 'prior asset unchanged: ' + file.path);
    preserved.push(file);
  }
} catch (error) {check(false, '37-asset immutable baseline check completed', error.stack);}

if (!baselineOnly) await checkCompositionReferences(selectedNamespaces);
check(assets.length === expectedCount, 'all selected lab-bench assets fully decoded', {expectedCount, actual: assets.length, selectedNamespaces});
const changedInputs = [];
for (const input of [...sourceReports, ...sourceSnapshots, ...runtimeSnapshots]) {
  try {if (sha(await fs.readFile(input.file)) !== input.sha256) changedInputs.push(input.file);}
  catch {changedInputs.push(input.file);}
}
check(changedInputs.length === 0, 'all source receipts, native/GLB/tile/composition inputs and runtime files stayed unchanged during validation', changedInputs);
const output = baselineOnly ? 'baseline_validation.json' : selectedNamespaces.length === 1 ? selectedNamespaces[0] + '_validation.json' : 'validation.json';
await fs.mkdir('review/photo_lab_benches', {recursive: true});
await fs.writeFile('review/photo_lab_benches/' + output, JSON.stringify({
  schema: 1, checks: rows.length, failures: errors.length, passed: errors.length === 0,
  selectedNamespaces, completeLabBenches: selectedNamespaces.length === 2 && assets.length === expectedCount,
  scope: 'Independent real geometry and direct Draco bitstream decode, source provenance, 37 prior assets unchanged, and old/new asset composition references. Proportions are photographic estimates. No browser/GPU, Godot, collision or exact-product acceptance.',
  preservedBaseline: baseline, sourceReports, sourceFreezes, runtimeFiles: runtimeSnapshots, nativeSourceAudits, compositions, preservedOriginalFiles: preserved, assets, errors, rows
}, null, 2) + '\n');
console.log(`Photo lab benches: ${rows.length} checks, ${errors.length} failures, ${assets.length}/${expectedCount} selected new assets, ${preserved.length} old files compared.`);
for (const error of errors) console.error(error);
if (errors.length) process.exitCode = 1;
