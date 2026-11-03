/** Independent reads of authored sources, emitted plain GLB and real Draco GLB.
 * These are data/geometry checks, not browser, photo-scale or product certification.
 * Run from the art root. All 14 assets and the restored baseline are required.
 */
import fs from 'node:fs/promises';
import crypto from 'node:crypto';
import {execFileSync} from 'node:child_process';
import {NodeIO, getBounds} from '@gltf-transform/core';
import {ALL_EXTENSIONS} from '@gltf-transform/extensions';
import draco3d from 'draco3dgltf';
import {batches} from './build_photo_living.mjs';

const baseline = '3f7ca5ed03339538229e2e6dc1e8dbf768f18baf';
const art = 'godot_native/art_source/future_learning_center_3d/';
const decoderModule = await draco3d.createDecoderModule();
const io = new NodeIO().registerExtensions(ALL_EXTENSIONS).registerDependencies({
  'draco3d.decoder': decoderModule
});
const sha = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const rows = [], assets = [], preserved = [], errors = [], sourceReports = [], sourceSnapshots = [];
function check(ok, label, details) {
  rows.push({pass: !!ok, label, ...(details === undefined ? {} : {details})});
  if (!ok) errors.push(label);
  return !!ok;
}
const dimensions = bounds => bounds.max.map((v, i) => v - bounds.min[i]);
const maxEdgeError = (a, b) => Math.max(...['min', 'max'].flatMap(k => a[k].map((v, i) => Math.abs(v - b[k][i]))));
const transformBlenderBounds = b => ({min: [b[0][0], b[0][2], -b[1][1]], max: [b[1][0], b[1][2], -b[0][1]]});

// glTF axis order: width X, height Y, depth Z. Ranges reject unit mistakes only;
// they do not establish the photograph's real dimensions.
const contracts = {
  photo_living_capsule_table: {range: [[.9, 1.4], [.7, .85], [2.8, 3.8]], parts: [/capsule tabletop/i, /capsule pedestal/i, /floor plinth/i]},
  photo_living_caramel_armchair: {range: [[.5, .75], [.7, 1], [.45, .7]], parts: [/upholstered.*seat/i, /wood backrest/i, /tubular arm loop.*-1/i, /tubular arm loop.*1$/i, /Front leg -1/, /Rear leg 1/]},
  photo_living_pale_shell_chair: {range: [[.45, .7], [.7, 1], [.45, .75]], parts: [/continuous scooped plywood seat and back/i, /front splayed leg -1/i, /rear splayed leg 1/i]},
  photo_living_orange_office_chair: {range: [[.5, .8], [.85, 1.2], [.5, .8]], parts: [/Orange upholstered.*seat/i, /contoured.*back shell/i, /central gas lift/i, /five star base spoke 0/i, /five star base spoke 4/i, /Twin caster wheel 0/i]},
  photo_living_wood_planter: {range: [[.5, 1], [1.1, 1.9], [.5, 1]], parts: [/planter with open rim/i, /dark soil/i, /woody stem/i, /Individual small leaves/i]},
  photo_pantry_counter: {range: [[2, 2.8], [.8, 1.1], [.5, .8]], parts: [/Base cabinet door 0$/, /Base cabinet door 4$/, /White worktop left/, /White worktop right/, /White worktop front/, /White worktop behind basin/]},
  photo_pantry_sink_faucets: {range: [[.6, .9], [.45, .75], [.45, .75]], parts: [/Sink bowl bottom/, /Sink deep side wall/, /Sink black narrow side rim/, /Tall black curved faucet spout/, /Small silver drinking faucet neck/]},
  photo_pantry_grey_roundfront_appliance: {range: [[.3, .5], [.25, .5], [.35, .6]], parts: [/Grey round front appliance case/, /Round front flat viewing glass/, /Small front control knob/]},
  photo_pantry_white_cleartop_appliance: {range: [[.25, .45], [.35, .6], [.3, .5]], parts: [/White vented appliance body/, /Clear smoke top lid/, /White front grille horizontal slat/, /Scoop bottom/]},
  photo_pantry_backsplash_shelves: {range: [[2, 2.8], [1.1, 1.7], [.35, .65]], parts: [/Vertical olive tile/, /Grey socket track/, /Round black socket module/, /Upper shelf lower plank/, /Plain white shelf bowl/]},
  photo_side_by_side_fridge: {range: [[.8, 1.05], [1.6, 2], [.6, .85]], parts: [/Refrigerator main carcass/, /^Left narrower door structural rear slab$/, /^Right wider door structural rear slab$/, /Central vertical door gasket/, /Left narrower door recessed silver grip floor/, /Right wider door recessed silver grip floor/]},
  photo_fridge_wood_surround: {range: [[1.3, 1.8], [2.4, 3], [.6, .9]], parts: [/Fridge left wood surround/, /Fridge upper cupboard left$/, /Right tall cabinet side/, /Cabinet dispenser black top/, /Dispenser silver drip tray/]},
  waste_bin_grey: {range: [[.4, .6], [.7, .95], [.45, .7]], parts: [/Continuous tapered rounded bin shell/, /Shaped lid lip/, /Irregular black liner/, /Recessed rounded front foot pedal/, /Visible Chinese category print/, /Visible English category print/]},
  waste_bin_blue: {range: [[.4, .6], [.7, .95], [.45, .7]], parts: [/Continuous tapered rounded bin shell/, /Shaped lid lip/, /Irregular black liner/, /Recessed rounded front foot pedal/, /Visible Chinese category print/, /Visible English category print/]}
};

function semanticGeometry(doc, id) {
  const nodes = doc.getRoot().listNodes().filter(n => n.getMesh());
  const bounds = name => {
    const node = nodes.find(n => n.getName() === name);
    if (!node) throw Error(`${id}: missing semantic mesh ${name}`);
    return getBounds(node);
  };
  if (id === 'photo_living_capsule_table') {
    const top = bounds('Long charcoal capsule tabletop'), pedestal = bounds('Broad charcoal capsule pedestal');
    const ts = dimensions(top), ps = dimensions(pedestal);
    check(ts[2] > 2 * ts[0] && ts[1] < .08 && ps[1] > .5 && ps[0] < ts[0] && ps[2] < ts[2] && Math.abs(top.min[1] - pedestal.max[1]) < .02, `${id}: long thin tabletop sits on a narrower broad pedestal`, {top, pedestal});
  } else if (id === 'photo_living_caramel_armchair') {
    const seat = bounds('Caramel upholstered rounded seat'), back = bounds('Curved natural wood backrest');
    const legs = ['Front leg -1', 'Front leg 1', 'Rear leg -1', 'Rear leg 1'].map(bounds);
    check(seat.min[1] > .35 && seat.max[1] < .6 && back.max[1] > seat.max[1] + .2 && legs.every(b => b.min[1] < .04 && b.max[1] > .4), `${id}: seat, raised back and four supporting legs have distinct geometry`, {seat, back, legs});
  } else if (id === 'photo_living_pale_shell_chair') {
    const shell = bounds('Pale continuous scooped plywood seat and back');
    const legs = ['Pale front splayed leg -1', 'Pale front splayed leg 1', 'Pale rear splayed leg -1', 'Pale rear splayed leg 1'].map(bounds);
    check(shell.min[1] > .35 && shell.max[1] > .75 && legs.every(b => b.min[1] < .04 && b.max[1] > .4 && b.max[1] <= shell.min[1] + .03), `${id}: one raised seat/back shell and four lower splayed legs`, {shell, legs});
  } else if (id === 'photo_pantry_sink_faucets') {
    const bowl = bounds('Sink bowl bottom'), rim = bounds('Sink black narrow side rim');
    const mainTap = bounds('Tall black curved faucet spout'), drinkingTap = bounds('Small silver drinking faucet neck');
    check(bowl.max[1] < rim.min[1] - .12 && mainTap.max[1] > rim.max[1] + .25 && drinkingTap.max[1] > rim.max[1] + .2, `${id}: recessed basin and two separate raised faucet spouts`, {bowl, rim, mainTap, drinkingTap});
  } else if (id === 'photo_pantry_counter') {
    const left = bounds('White worktop left'), right = bounds('White worktop right'), front = bounds('White worktop front'), rear = bounds('White worktop behind basin');
    check(right.min[0] - left.max[0] > .5 && front.min[2] - rear.max[2] > .4 && Math.abs(left.max[1] - right.max[1]) < .001, `${id}: countertop pieces leave a real basin aperture`, {left, right, front, rear});
  } else if (id === 'photo_side_by_side_fridge') {
    const left = bounds('Left narrower door structural rear slab'), right = bounds('Right wider door structural rear slab'), gasket = bounds('Central vertical door gasket');
    check(dimensions(left)[0] < dimensions(right)[0] && right.min[0] > left.max[0] && gasket.min[0] > left.max[0] && gasket.max[0] < right.min[0] && Math.abs(left.min[1] - right.min[1]) < .001 && Math.abs(left.max[1] - right.max[1]) < .001, `${id}: unequal-width doors align at top and bottom around a separate central gap`, {left, right, gasket});
    for (const prefix of ['Left narrower door', 'Right wider door']) {
      const face = bounds(prefix + ' broad front face'), grip = bounds(prefix + ' recessed silver grip floor');
      const lower = bounds(prefix + ' inner front below grip'), upper = bounds(prefix + ' inner front above grip');
      const sideClear = prefix.startsWith('Left') ? face.max[0] < grip.min[0] : face.min[0] > grip.max[0];
      check(face.max[2] - grip.max[2] > .01 && sideClear && lower.max[1] < grip.min[1] && upper.min[1] > grip.max[1], `${id}: ${prefix} has a genuine unobstructed recessed grip`, {face, grip, lower, upper});
    }
  }
}

function parseGLB(bytes, label, compressed) {
  if (!check(bytes.readUInt32LE(0) === 0x46546c67 && bytes.readUInt32LE(4) === 2 && bytes.readUInt32LE(8) === bytes.length, `${label}: valid complete GLB 2 container`)) throw Error(`${label}: malformed GLB`);
  const json = JSON.parse(bytes.subarray(20, 20 + bytes.readUInt32LE(12)).toString());
  check(![...(json.buffers ?? []), ...(json.images ?? [])].some(r => r.uri), `${label}: all buffers and images embedded, no external resources`);
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
  check(mats.length >= 2 && mats.length <= 16, `${label}: bounded distinct material groups`, mats.length);
  check(mats.every(m => [m.getMetallicFactor(), m.getRoughnessFactor(), ...m.getBaseColorFactor()].every(v => Number.isFinite(v) && v >= 0 && v <= 1) && m.getEmissiveFactor().every(v => Number.isFinite(v) && v >= 0) && ['OPAQUE', 'MASK', 'BLEND'].includes(m.getAlphaMode())), `${label}: finite valid metallic-roughness PBR factors`);
  check(textures.every(t => /^(charcoal_wood(?:_normal)?|natural_oak_plywood|pale_ash_shell)_lod[012]$/.test(t.getName()) && /^photo_living_/.test(id)), `${label}: only declared synthetic wood images, never the input photograph`);
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

for (const [reportName, ids] of Object.entries(batches)) {
  let report;
  try {
    const reportFile = `review/photo_living/${reportName}.json`, reportBytes = await fs.readFile(reportFile);
    sourceReports.push({file: reportFile, sha256: sha(reportBytes), bytes: reportBytes.length});
    report = JSON.parse(reportBytes);
    check(report.units === 'm', `${reportName}: explicitly metric source receipt`);
    check(report.records.length === ids.length * 3 && report.records.every(r => ids.includes(r.asset) && [0, 1, 2].includes(r.level)), `${reportName}: complete declared batch, no hidden additional asset`);
  } catch (error) {check(false, `${reportName}: readable source receipt`, error.message); continue;}
  for (const id of ids) try {
    const sourceBase = `sources/models/photo_living/${id}/`, runtimeBase = `web/assets/models/photo_living/${id}/`;
    const manifest = JSON.parse(await fs.readFile(runtimeBase + 'manifest.json'));
    const receiptSets = [0, 1, 2].map(level => report.records.filter(r => r.asset === id && r.level === level));
    if (!check(receiptSets.every(r => r.length === 1), `${id}: exactly one authored source receipt per level`)) continue;
    check(manifest.levels.length === 3 && manifest.levels.map(r => r.level).join(',') === '0,1,2', `${id}: three ordered runtime LODs`);
    check(manifest.encoding.positionBits === 20, `${id}: explicit 20-bit Draco position encoding`);
    check(Math.abs(manifest.calibration.uniformScale - 1) < 1e-5 && manifest.calibration.yawDegrees === 0, `${id}: no concealed scale or facing correction`);
    const blend = await fs.readFile(sourceBase + id + '.blend');
    check(blend.subarray(0, 7).toString() === 'BLENDER', `${id}: native editable Blender source`);
    sourceSnapshots.push({file: sourceBase + id + '.blend', sha256: sha(blend)});
    const asset = {id, nativeSourceSha256: sha(blend), levels: []};
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
      for (const texture of source.getRoot().listTextures()) {
        const authoredImage = await fs.readFile(sourceBase + texture.getName() + '.png');
        check(sha(authoredImage) === sha(texture.getImage()), `${label}: embedded synthetic image matches its editable source PNG`, texture.getName());
      }
      check(sourceGeometry.sceneTriangles === receipt.triangles, `${label}: actual source triangles match Blender receipt`, {actual: sourceGeometry.sceneTriangles, receipt: receipt.triangles});
      check(sha(sourceBytes) === receipt.sha256 && sha(sourceBytes) === level.inputSha256, `${label}: exact source and receipt hashes`);
      check(maxEdgeError(sourceBounds, transformBlenderBounds(receipt.boundsBlenderXYZ)) < 1e-5 && sourceSize.every((v, i) => Math.abs(v - [receipt.sizeBlenderXYZ[0], receipt.sizeBlenderXYZ[2], receipt.sizeBlenderXYZ[1]][i]) < 1e-5), `${label}: independently measured bounds match Blender XYZ receipt`, sourceBounds);
      check(sourceSize.every((v, i) => v >= contracts[id].range[i][0] && v <= contracts[id].range[i][1]), `${label}: plausible metre envelope, not certified photo dimensions`, sourceSize);
      const plainBytes = await fs.readFile(runtimeBase + level.uncompressedFile), compressedBytes = await fs.readFile(runtimeBase + level.file);
      parseGLB(plainBytes, label + ' plain', false);
      const encodedJSON = parseGLB(compressedBytes, label + ' Draco', true);
      const directDracoTriangles = inspectDracoBitstream(compressedBytes, encodedJSON, label);
      const plain = await io.readBinary(plainBytes), decoded = await io.readBinary(compressedBytes);
      const plainGeometry = geometry(plain, label + ' plain'), decodedGeometry = geometry(decoded, label + ' Draco');
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
      // The measured worst case is the shelf LOD2 losing 1.3mm of cord detail.
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
      asset.levels.push({level: level.level, sourceTriangles: sourceGeometry.sceneTriangles, plainTriangles: plainGeometry.triangles, decodedTriangles: decodedGeometry.triangles, sourceSize, decodedSize: dimensions(decodedBounds), sourceToPlainErrorM, plainToDracoErrorM, sourceEnvelopeToleranceM, bytes: compressedBytes.length, sha256: sha(compressedBytes)});
    }
    check(asset.levels.length === 3 && asset.levels[0].sourceTriangles > asset.levels[1].sourceTriangles && asset.levels[1].sourceTriangles > asset.levels[2].sourceTriangles, `${id}: independently authored decreasing source LODs`);
    check(asset.levels.length === 3 && asset.levels[0].decodedTriangles > asset.levels[1].decodedTriangles && asset.levels[1].decodedTriangles > asset.levels[2].decodedTriangles, `${id}: genuinely decreasing decoded LODs`);
    assets.push(asset);
  } catch (error) {check(false, `${id}: validation completed without exception`, error.stack);}
}

try {
  // This is the locally restored archive baseline, not an invented old git object.
  const paths = execFileSync('git', ['ls-tree', '-r', '--name-only', '--full-tree', baseline, '--', art + 'sources/models/photo_desktop', art + 'web/assets/models/photo_desktop'], {encoding: 'utf8'}).trim().split('\n').filter(p => /\/(photo_monitor_stand|photo_desk_divider|photo_monitor_arm)\//.test(p));
  check(paths.filter(p => /\.(blend|glb)$/.test(p)).length === 30, 'restored baseline contains all 30 unrelated monitor/divider/arm model files');
  for (const file of paths) {
    const before = execFileSync('git', ['show', baseline + ':' + file], {maxBuffer: 64 * 1024 * 1024});
    const now = await fs.readFile(file.slice(art.length));
    check(now.equals(before), 'unrelated candidate unchanged: ' + file);
    preserved.push({path: file, sha256: sha(now), bytes: now.length});
  }
} catch (error) {check(false, 'restored baseline invariance check completed', error.message);}

check(assets.length === 14, 'all 14 independent living-area assets fully decoded', assets.length);
const changedInputs = [];
for (const input of [...sourceReports, ...sourceSnapshots]) {
  try { if (sha(await fs.readFile(input.file)) !== input.sha256) changedInputs.push(input.file); }
  catch { changedInputs.push(input.file); }
}
check(changedInputs.length === 0, 'all 3 receipts, 14 native sources and 42 source GLBs stayed unchanged during validation', changedInputs);
await fs.mkdir('review/photo_living', {recursive: true});
await fs.writeFile('review/photo_living/validation.json', JSON.stringify({
  schema: 1, checks: rows.length, failures: errors.length, passed: errors.length === 0,
  scope: 'Independent source/receipt, finite geometry, normals, PBR, real Draco decode, metric envelope and decreasing LOD checks. Single-photo scale and hidden parts remain assumptions. No browser/GPU, Godot, collision, interaction or exact-product acceptance.',
  preservedBaseline: baseline, preservedBaselineMeaning: 'Local restore commit for the archived five source assets; does not claim the unavailable old git object exists.',
  sourceReports, preservedOriginalFiles: preserved, assets, errors, rows
}, null, 2) + '\n');
console.log(`Photo living: ${rows.length} checks, ${errors.length} failures, ${assets.length}/14 assets, ${preserved.length} unrelated files compared.`);
for (const error of errors) console.error(error);
if (errors.length) process.exitCode = 1;
