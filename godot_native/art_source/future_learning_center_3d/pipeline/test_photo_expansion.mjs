/** Independent reads of authored sources, emitted plain GLB and real Draco GLB.
 * These are data/geometry checks, not browser, photo-scale or product certification.
 * Run from the art root. Select a namespace, --baseline-only or --pantry-only; no arguments tests all three namespaces.
 */
import fs from 'node:fs/promises';
import crypto from 'node:crypto';
import {execFileSync} from 'node:child_process';
import {NodeIO, getBounds} from '@gltf-transform/core';
import {ALL_EXTENSIONS} from '@gltf-transform/extensions';
import draco3d from 'draco3dgltf';
import {groups, baseline, art, excludedOldAsset, baselinePaths} from './build_photo_expansion.mjs';

const args = process.argv.slice(2);
const baselineOnly = args.length === 1 && args[0] === '--baseline-only';
const pantryOnly = args.length === 1 && args[0] === '--pantry-only';
const selectedNamespaces = baselineOnly || pantryOnly ? [] : (args.length ? args : Object.keys(groups));
if (selectedNamespaces.some(n => !groups[n])) throw Error('Unknown expansion namespace.');
const expectedCount = selectedNamespaces.reduce((n, key) => n + groups[key].expectedCount, 0);
const decoderModule = await draco3d.createDecoderModule();
const io = new NodeIO().registerExtensions(ALL_EXTENSIONS).registerDependencies({
  'draco3d.decoder': decoderModule
});
const sha = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const rows = [], assets = [], preserved = [], errors = [], sourceReports = [], sourceSnapshots = [], nativeSourceAudits = [];
function check(ok, label, details) {
  rows.push({pass: !!ok, label, ...(details === undefined ? {} : {details})});
  if (!ok) errors.push(label);
  return !!ok;
}
const dimensions = bounds => bounds.max.map((v, i) => v - bounds.min[i]);
const maxEdgeError = (a, b) => Math.max(...['min', 'max'].flatMap(k => a[k].map((v, i) => Math.abs(v - b[k][i]))));
const transformBlenderBounds = b => ({min: [b[0][0], b[0][2], -b[1][1]], max: [b[1][0], b[1][2], -b[0][1]]});

// Fixed semantic contracts are populated from the independent authored meshes,
// never by trusting names or dimensions copied from the build receipt alone.
const contracts = {
  photo_lounge_orange_single: {range: [[.7, 1.05], [.7, 1], [.65, 1]], parts: [/thin charcoal outer bowl/i, /padded continuous back and arms/i, /Separate rounded upholstered seat/, /Tapered four star blade/]},
  photo_lounge_orange_double: {range: [[1.2, 1.7], [.7, 1], [.65, 1]], parts: [/thin charcoal outer bowl/i, /padded continuous back and arms/i, /Separate rounded upholstered seat/, /shallow back upholstery seam/i, /Tapered four star blade/]},
  photo_lounge_round_table: {range: [[.45, .7], [.4, .65], [.45, .7]], parts: [/Thin warm white round top/, /Slender central black post/, /Single continuous rectangular cross foot/]},
  photo_lounge_grey_bar_chair: {range: [[.35, .6], [.9, 1.2], [.35, .65]], parts: [/Thin grey molded bar seat/, /Low rounded grey molded back/, /Slender black splayed leg/, /Front footrest/]},
  photo_lounge_square_stool: {range: [[.25, .45], [.6, .9], [.22, .42]], parts: [/Narrow rectangular top/, /Slim squared splayed leg/, /Front and rear straight foot rail/, /Side straight foot rail/]},
  photo_lounge_window_counter: {range: [[1.5, 2.1], [.9, 1.3], [.3, .55]], parts: [/Narrow pale wood continuous counter/, /Long black under top rail/, /Black angled rectangular bar leg/, /Long rear low brace/]},
  photo_workshop_green_tool_cart: {range: [[.85, 1.2], [.75, 1.1], [.4, .65]], parts: [/Green enclosed cabinet body/, /Shallow black drawer 01/, /Deep lower black drawer/, /Rubber top work mat/, /Caster rubber tyre/, /Silver right push handle/, /Left side tray floor/]},
  photo_workshop_square_hole_board: {range: [[.65, .95], [.5, .8], [.015, .08]], parts: [/432 actual square holes/, /Folded vertical edge stiffener/, /Bottom mounting rail/]},
  photo_workshop_blue_driver_rack: {range: [[.25, .4], [.23, .38], [.07, .16]], parts: [/Black rack base/, /Rack horizontal holder rail/, /Driver 00 polished shaft/, /Driver 07 polished shaft/, /Blue anodised grip 00/, /Blue rotating end cap 07/]},
  photo_workshop_red_flat_case: {range: [[.3, .55], [.035, .09], [.15, .28]], parts: [/Red shallow lower shell/, /Red fitted shallow lid/, /Moulded diagonal lid rib/, /Small red front closure/, /Red rear hinge/]},
  photo_workshop_black_red_case: {range: [[.25, .43], [.045, .11], [.17, .31]], parts: [/Black lower molded shell/, /Black upper lid/, /Bright red clasp/, /Rear case hinge/, /Carry handle crossbar/]},
  photo_workshop_small_vise: {range: [[.12, .22], [.09, .18], [.18, .32]], parts: [/Cast iron swivel base/, /Rear fixed jaw casting/, /Front movable jaw casting/, /Fixed steel jaw plate/, /Moving steel jaw plate/, /Vise screw shaft/, /Sliding cross handle/]},
  photo_print_white_mfp: {range: [[.35, .6], [.35, .65], [.42, .75]], parts: [/Low rounded printer chassis/, /Extended lower paper tray/, /Angled control fascia/, /Inactive LCD/, /Rounded scanner lower shell/, /ADF raised feed tray/, /ADF adjustable paper guide left/]},
  photo_print_black_compact: {range: [[.4, .65], [.15, .32], [.3, .55]], parts: [/Low wide charcoal printer body/, /Horizontal paper exit slot/, /Low rounded scanner lid/, /Muted blue grey ink window/, /Top corner control strip/]},
  photo_honors_display_cabinet: {range: [[3, 4.3], [2, 2.7], [.4, .7]], parts: [/Lower cabinet carcass/, /Warm white counter slab/, /Base cabinet wood door 0/, /Base cabinet wood door 5/, /Upper cubby upright 0/, /Upper cubby upright 6/, /Upper shelf roof/]},
  photo_honors_lightwood_frame: {range: [[.25, .43], [.18, .34], [.08, .2]], parts: [/Frame closed hardboard rear/, /REPLACEABLE blank photo panel/, /Light oak frame side/, /Light oak frame horizontal rail/, /Rear easel support/]},
  photo_honors_certificate_stand: {range: [[.18, .35], [.25, .43], [.06, .16]], parts: [/Oak slotted certificate base/, /Satin metal closed backing/, /REPLACEABLE neutral certificate face/, /Sleeve horizontal lip/]},
  photo_honors_trophy_silhouette: {range: [[.18, .35], [.28, .47], [.11, .24]], parts: [/Broad black trophy display plinth/, /Slim black trophy pedestal/, /Blank inset trophy plaque/, /Faceted brass central column/, /Open trophy head corner/, /Gold head diagonal insert/]}
};
const allowedTextures = {
  photo_lounge_orange_single: ['terracotta_woven_upholstery_base', 'terracotta_woven_upholstery_normal'],
  photo_lounge_orange_double: ['terracotta_woven_upholstery_base', 'terracotta_woven_upholstery_normal'],
  photo_lounge_window_counter: ['pale_wood_bar_counter_base'],
  photo_workshop_green_tool_cart: ['synthetic_rubber_tile'],
  photo_honors_display_cabinet: ['synthetic_oak_lod0', 'synthetic_oak_lod1', 'synthetic_oak_lod2'],
  photo_honors_lightwood_frame: ['synthetic_oak_lod0', 'synthetic_oak_lod1', 'synthetic_oak_lod2'],
  photo_honors_certificate_stand: ['synthetic_oak_lod0', 'synthetic_oak_lod1', 'synthetic_oak_lod2'],
  photo_honors_trophy_silhouette: ['synthetic_oak_lod0', 'synthetic_oak_lod1', 'synthetic_oak_lod2']
};
function semanticGeometry(doc, id) {
  const nodes = doc.getRoot().listNodes().filter(n => n.getMesh());
  const matching = pattern => nodes.filter(n => pattern.test(n.getName()));
  const bounds = name => {const n = nodes.find(n => n.getName() === name); if (!n) throw Error(`${id}: missing structural mesh ${name}`); return getBounds(n);};
  check(nodes.length > 1, `${id}: multiple independent authored parts`);
  check(!nodes.some(n => /render.only|studio.stage|camera|area.light|backdrop/i.test(n.getName())), `${id}: no render-stage mesh in model source`);
  if (!contracts[id]) throw Error(`${id}: semantic geometry contract is not finalized`);
  if (/photo_lounge_orange_/.test(id)) {
    const seat = bounds('Separate rounded upholstered seat'), back = bounds('Orange padded continuous back and arms');
    check(back.max[1] > seat.max[1] + .2 && matching(/^Tapered four star blade/).length === 4 && matching(/^Small floor glide/).length === 4, `${id}: raised upholstered bowl, separate seat and exactly four splayed base blades`, {seat, back});
  } else if (id === 'photo_lounge_round_table') {
    const top = bounds('Thin warm white round top'), post = bounds('Slender central black post'), size = dimensions(top);
    const foot = bounds('Single continuous rectangular cross foot'), plate = bounds('Black underside mounting plate');
    check(Math.abs(size[0] - size[2]) < .001 && size[1] < .04 && post.min[1] < foot.max[1] && post.max[1] > plate.min[1] && top.min[1] - plate.max[1] <= .003 && matching(/^Recessed foot glide/).length === 4, `${id}: thin round top, post touching foot and mounting plate, one cross foot and four glides`, {top, post, foot, plate});
  } else if (id === 'photo_lounge_grey_bar_chair') {
    const seat = bounds('Thin grey molded bar seat'), back = bounds('Low rounded grey molded back'), foot = bounds('Front footrest');
    check(seat.min[1] > .65 && back.max[1] > seat.max[1] + .15 && foot.max[1] < seat.min[1] - .15 && matching(/^Slender black splayed leg/).length === 4, `${id}: elevated seat, short back, four legs and lower footrest`, {seat, back, foot});
  } else if (id === 'photo_lounge_square_stool') {
    const top = bounds('Narrow rectangular top');
    check(dimensions(top)[1] < .06 && top.min[1] > .65 && matching(/^Slim squared splayed leg/).length === 4, `${id}: thin elevated rectangular seat supported by four legs`, top);
  } else if (id === 'photo_lounge_window_counter') {
    const top = bounds('Narrow pale wood continuous counter'), size = dimensions(top);
    check(size[0] > 4 * size[2] && size[1] < .06 && top.min[1] > .95 && matching(/^Black angled rectangular bar leg/).length === 4, `${id}: long narrow counter at bar height with four distinct supporting legs`, top);
  } else if (id === 'photo_workshop_green_tool_cart') {
    const shallow = matching(/^Shallow black drawer \d/).map(getBounds), deep = bounds('Deep lower black drawer');
    check(shallow.length === 5 && shallow.every(b => b.min[1] > deep.max[1]) && matching(/^Caster rubber tyre/).length === 4, `${id}: five shallow drawers above a deeper drawer and four casters`, {shallow, deep});
  } else if (id === 'photo_workshop_blue_driver_rack') {
    check(matching(/^Driver \d\d polished shaft$/).length === 8 && matching(/^Blue anodised grip \d\d$/).length === 8 && matching(/^Blue rotating end cap \d\d$/).length === 8, `${id}: eight independent shafts, grips and end caps`);
  } else if (id === 'photo_workshop_red_flat_case') {
    const base = bounds('Red shallow lower shell'), lid = bounds('Red fitted shallow lid');
    check(lid.min[1] >= base.max[1] - .003 && matching(/^Small red front closure/).length === 2 && matching(/^Red rear hinge/).length === 2, `${id}: thin fitted lid above base with two closures and two rear hinges`, {base, lid});
  } else if (id === 'photo_workshop_black_red_case') {
    check(matching(/^Bright red clasp/).length === 2 && matching(/^Rear case hinge/).length === 2 && dimensions(bounds('Carry handle crossbar'))[0] > .08, `${id}: two clasps, two rear hinges and a real spanning carry handle`);
  } else if (id === 'photo_workshop_small_vise') {
    const fixed = bounds('Fixed steel jaw plate'), moving = bounds('Moving steel jaw plate');
    check(fixed.min[2] > moving.max[2] || moving.min[2] > fixed.max[2], `${id}: fixed and sliding jaw plates leave an actual gap`, {fixed, moving});
  } else if (id === 'photo_print_white_mfp') {
    const body = bounds('Low rounded printer chassis'), tray = bounds('Extended lower paper tray'), scanner = bounds('Rounded scanner lower shell'), adf = bounds('ADF raised feed tray');
    check(tray.max[2] > body.max[2] + .04 && adf.max[1] > scanner.max[1] + .02, `${id}: extended output tray and raised document feed assembly are separate geometry`, {body, tray, scanner, adf});
  } else if (id === 'photo_print_black_compact') {
    const body = bounds('Low wide charcoal printer body'), slot = bounds('Horizontal paper exit slot');
    check(dimensions(body)[1] < dimensions(body)[0] * .5 && dimensions(slot)[0] > dimensions(body)[0] * .6 && dimensions(slot)[1] < .03, `${id}: low broad body and narrow horizontal paper exit`, {body, slot});
  } else if (id === 'photo_honors_display_cabinet') {
    check(matching(/^Base cabinet wood door \d$/).length === 6 && matching(/^Upper cubby upright \d$/).length === 7 && bounds('Upper shelf base').min[1] > bounds('Warm white counter slab').max[1] + .5, `${id}: six lower doors and six open upper cubbies above a separate counter`);
  } else if (id === 'photo_honors_lightwood_frame') {
    check(matching(/^Light oak frame side/).length === 2 && matching(/^Light oak frame horizontal rail/).length === 2 && dimensions(bounds('REPLACEABLE blank photo panel'))[2] < .02, `${id}: four frame rails surround a blank replaceable face with separate easel support`);
  } else if (id === 'photo_honors_certificate_stand') {
    check(bounds('REPLACEABLE neutral certificate face').max[1] > bounds('Oak slotted certificate base').max[1] + .2, `${id}: neutral replaceable certificate face rises above the slotted base`);
  } else if (id === 'photo_honors_trophy_silhouette') {
    check(matching(/^Open trophy head corner/).length === 4 && bounds('Silver head lower sill').min[1] > bounds('Broad black trophy display plinth').max[1] + .15, `${id}: four open-head corner pieces above pedestal and a blank plaque`);
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
function rightSurfaceAt(triangles, y, z) {
  const hits = [];
  for (const [a, b, c] of triangles) {
    const denominator = (b[2] - c[2]) * (a[1] - c[1]) + (c[1] - b[1]) * (a[2] - c[2]);
    if (Math.abs(denominator) < 1e-14) continue;
    const u = ((b[2] - c[2]) * (y - c[1]) + (c[1] - b[1]) * (z - c[2])) / denominator;
    const v = ((c[2] - a[2]) * (y - c[1]) + (a[1] - c[1]) * (z - c[2])) / denominator;
    const w = 1 - u - v;
    if (Math.min(u, v, w) >= -1e-7) hits.push(u * a[0] + v * b[0] + w * c[0]);
  }
  return hits.length ? Math.max(...hits) : NaN;
}
function checkPerforations(doc, label, offset) {
  const cellSize = .03, grid = new Map();
  for (const node of doc.getRoot().listNodes().filter(n => n.getMesh())) for (const triangle of worldTriangles(node)) {
    const [a, b, c] = triangle;
    const determinant = (b[1] - c[1]) * (a[0] - c[0]) + (c[0] - b[0]) * (a[1] - c[1]);
    if (Math.abs(determinant) < 1e-14) continue;
    const xs = triangle.map(p => p[0]), ys = triangle.map(p => p[1]);
    for (let x = Math.floor(Math.min(...xs) / cellSize); x <= Math.floor(Math.max(...xs) / cellSize); x++) {
      for (let y = Math.floor(Math.min(...ys) / cellSize); y <= Math.floor(Math.max(...ys) / cellSize); y++) {
        const key = `${x},${y}`;
        if (!grid.has(key)) grid.set(key, []);
        grid.get(key).push({a, b, c, determinant});
      }
    }
  }
  function covered(x, y) {
    for (const {a, b, c, determinant} of grid.get(`${Math.floor(x / cellSize)},${Math.floor(y / cellSize)}`) ?? []) {
      const u = ((b[1] - c[1]) * (x - c[0]) + (c[0] - b[0]) * (y - c[1])) / determinant;
      const v = ((c[1] - a[1]) * (x - c[0]) + (a[0] - c[0]) * (y - c[1])) / determinant;
      if (Math.min(u, v, 1 - u - v) >= -1e-7) return true;
    }
    return false;
  }
  const blockedHoles = [], missingWeb = [];
  for (let col = 0; col < 24; col++) for (let row = 0; row < 18; row++) {
    const x = (col - 11.5) * .03 + offset[0], y = .047 + (row + .5) * .03 + offset[1];
    for (const [dx, dy] of [[0, 0], [-.003, -.003], [-.003, .003], [.003, -.003], [.003, .003]]) if (covered(x + dx, y + dy)) blockedHoles.push({col, row, dx, dy});
    if (!covered(x + .010, y)) missingWeb.push({col, row});
  }
  check(blockedHoles.length === 0 && missingWeb.length === 0, `${label}: 432 square holes stay open at centre and corners while surrounding sheet remains solid`, {holeCount: 432, openRayTests: 2160, solidRayTests: 432, blockedHoleCount: blockedHoles.length, missingWebCount: missingWeb.length, firstBlocked: blockedHoles.slice(0, 8), firstMissingWeb: missingWeb.slice(0, 8)});
}
async function checkPantryRevision() {
  try {
    const id = excludedOldAsset, file = `sources/models/photo_living/${id}/lod0_source.glb`, bytes = await fs.readFile(file);
    sourceSnapshots.push({file, sha256: sha(bytes)});
    const doc = await io.readBinary(bytes), nodes = doc.getRoot().listNodes();
    const node = name => {const n = nodes.find(n => n.getName() === name && n.getMesh()); if (!n) throw Error(`Missing revised microwave mesh: ${name}`); return n;};
    const bodyNode = node('Grey round front appliance case'), body = getBounds(bodyNode), bodySize = dimensions(body);
    const glass = getBounds(node('Round front flat viewing glass')), ring = getBounds(node('Thin silver viewing-window edge'));
    const frame = getBounds(node('Microwave slim rectangular door frame')), knob = getBounds(node('Small front control knob'));
    const triangles = worldTriangles(bodyNode), topVertices = triangles.flat().filter(p => Math.abs(p[1] - body.max[1]) < 1e-6);
    const bevelInset = body.max[0] - Math.max(...topVertices.map(p => p[0]));
    check(bevelInset >= .003 && bevelInset <= .004, 'microwave actual casing top-edge bevel inset is 3–4mm, not the previous 12mm', {bevelInset});
    check(Math.abs(dimensions(glass)[0] - dimensions(glass)[1]) < 1e-5 && dimensions(glass)[2] < .002, 'microwave has a circular, flat viewing glass rather than a protruding rounded door', {glassSize: dimensions(glass)});
    const ringDiameter = dimensions(ring)[0], ringRatio = ringDiameter / bodySize[0];
    check(ringRatio > .70 && ringRatio < .80 && dimensions(ring)[2] < .004, 'microwave viewing-window diameter and thin edge fit the casing', {ringDiameter, ringRatio, edgeDepth: dimensions(ring)[2]});
    check(dimensions(frame)[2] <= .013 && frame.max[1] < body.max[1] && frame.min[1] > body.min[1], 'microwave slim rectangular door frame stays within the casing height', {frame});
    check(dimensions(knob)[0] <= .03 && knob.max[2] - body.max[2] < .03, 'microwave control knob is small and only slightly projects', {knob});
    check(!nodes.some(n => /Round door lower pale grip|Right side pressed panel|Right side grey panel inset/.test(n.getName())), 'unsupported lower projecting handle and stacked side plates are absent');
    const innerX = rightSurfaceAt(triangles, .19, -.019), outerX = rightSurfaceAt(triangles, .34, 0), recessDepth = outerX - innerX;
    check(Number.isFinite(recessDepth) && recessDepth >= .0012 && recessDepth <= .0014 && Math.abs(outerX - body.max[0]) < 1e-6, 'actual triangle rays verify a 1.3mm inward side impression', {innerX, outerX, recessDepth});
    const oldBytes = execFileSync('git', ['show', baseline + ':' + art + file], {maxBuffer: 32 * 1024 * 1024});
    const old = await io.readBinary(oldBytes), oldRing = old.getRoot().listNodes().find(n => n.getName() === 'Round front slim silver rim');
    check(!!oldRing && ringDiameter < dimensions(getBounds(oldRing))[0] * .92, 'new microwave viewing edge is materially smaller than the immutable old shape', {newDiameter: ringDiameter, oldDiameter: oldRing ? dimensions(getBounds(oldRing))[0] : null});
    const layoutFile = 'sources/photo_pantry_composition.json', layoutBytes = await fs.readFile(layoutFile), layout = JSON.parse(layoutBytes);
    sourceSnapshots.push({file: layoutFile, sha256: sha(layoutBytes)});
    const expected = ['photo_pantry_counter', 'photo_pantry_sink_faucets', id, 'photo_pantry_white_cleartop_appliance', 'photo_pantry_backsplash_shelves', 'photo_side_by_side_fridge', 'photo_fridge_wood_surround'];
    check(layout.units === 'm' && layout.instances.length === 7 && new Set(layout.instances.map(i => i.asset)).size === 7 && layout.instances.every(i => expected.includes(i.asset)), 'pantry composition reuses exactly seven distinct existing assets');
    const transformed = {}, docs = {};
    for (const instance of layout.instances) {
      check(instance.source === `sources/models/photo_living/${instance.asset}/lod0_source.glb`, `${instance.asset}: canonical existing source reference, no duplicated composition mesh`);
      check(instance.scale.every(v => v === 1) && instance.rotationBlenderXYZ.every(v => v === 0) && instance.translationBlenderXYZ.length === 3 && instance.translationBlenderXYZ.every(Number.isFinite), `${instance.asset}: finite translation only, no shape-distorting assembly transform`);
      docs[instance.asset] = await io.read(instance.source);
      const b = getBounds(docs[instance.asset].getRoot().listScenes()[0]), t = instance.translationBlenderXYZ, offset = [t[0], t[2], -t[1]];
      transformed[instance.asset] = Object.fromEntries(['min', 'max'].map(k => [k, b[k].map((v, i) => v + offset[i])]));
    }
    const counter = transformed.photo_pantry_counter, fridge = transformed.photo_side_by_side_fridge, surround = transformed.photo_fridge_wood_surround;
    const cabinetGap = counter.min[0] - surround.max[0];
    check(fridge.max[0] < surround.max[0] && surround.max[0] < counter.min[0] && cabinetGap >= 0 && cabinetGap <= .05, 'pantry has refrigerator left of its recess cabinet, adjacent to the counter within 5cm', {fridge, surround, counter, cabinetGap});
    check(Math.abs(fridge.min[1] - counter.min[1]) < .03 && Math.abs(surround.min[1] - counter.min[1]) < .01, 'refrigerator, surrounding cabinet and counter share a plausible floor datum');
    const worktop = getBounds(docs.photo_pantry_counter.getRoot().listNodes().find(n => n.getName() === 'White worktop left'));
    check(Math.abs(transformed[id].min[1] - worktop.max[1]) < .001 && Math.abs(transformed.photo_pantry_white_cleartop_appliance.min[1] - worktop.max[1]) < .001, 'both countertop appliances rest on the actual worktop height');
    check(transformed.photo_pantry_sink_faucets.min[1] < worktop.max[1] - .1, 'sink basin remains below the worktop, not floating on it');
    check(!['meshes', 'vertices', 'buffers', 'geometry'].some(k => k in layout), 'composition JSON contains references and transforms only, no copied mesh payload');
  } catch (error) {check(false, 'revised pantry shape and composition inspection completed', error.stack);}
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
    const manifest = JSON.parse(await fs.readFile(runtimeBase + 'manifest.json'));
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
      if (id === 'photo_workshop_square_hole_board') checkPerforations(source, label + ' source', [0, 0, 0]);
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
      parseGLB(plainBytes, label + ' plain', false);
      const encodedJSON = parseGLB(compressedBytes, label + ' Draco', true);
      const directDracoTriangles = inspectDracoBitstream(compressedBytes, encodedJSON, label);
      const plain = await io.readBinary(plainBytes), decoded = await io.readBinary(compressedBytes);
      const plainGeometry = geometry(plain, label + ' plain'), decodedGeometry = geometry(decoded, label + ' Draco');
      if (id === 'photo_workshop_square_hole_board') {
        checkPerforations(plain, label + ' plain', offset);
        checkPerforations(decoded, label + ' Draco', offset);
      }
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
      asset.levels.push({level: level.level, sourceTriangles: sourceGeometry.sceneTriangles, plainTriangles: plainGeometry.triangles, decodedTriangles: decodedGeometry.triangles, sourceSize, decodedSize: dimensions(decodedBounds), sourceToPlainErrorM, plainToDracoErrorM, sourceEnvelopeToleranceM, bytes: compressedBytes.length, sha256: sha(compressedBytes)});
    }
    check(asset.levels.length === 3 && asset.levels[0].sourceTriangles > asset.levels[1].sourceTriangles && asset.levels[1].sourceTriangles > asset.levels[2].sourceTriangles, `${id}: independently authored decreasing source LODs`);
    check(asset.levels.length === 3 && asset.levels[0].decodedTriangles > asset.levels[1].decodedTriangles && asset.levels[1].decodedTriangles > asset.levels[2].decodedTriangles, `${id}: genuinely decreasing decoded LODs`);
    assets.push(asset);
  } catch (error) {check(false, `${id}: validation completed without exception`, error.stack);}
}

// Open each native file in the already installed Blender with auto-execution
// disabled. This only reads source files; it neither renders nor saves them.
if (assets.length) try {
  const entries = assets.map(a => ({asset: a.id, file: `sources/models/${a.namespace}/${a.id}/${a.id}.blend`}));
  const python = `import bpy,json,re\nfrom pathlib import Path\nentries=json.loads(${JSON.stringify(JSON.stringify(entries))})\nresults=[]\nfor entry in entries:\n try:\n  bpy.ops.wm.open_mainfile(filepath=str(Path(entry['file']).resolve()),load_ui=False,use_scripts=False)\n  result=dict(entry)\n  result.update({'meshObjects':sum(o.type=='MESH' for o in bpy.data.objects),'cameras':len(bpy.data.cameras),'lights':len(bpy.data.lights),'stages':[o.name for o in bpy.data.objects if re.search(r'render.only|studio.stage|backdrop',o.name,re.I)],'unpackedImages':[i.name for i in bpy.data.images if i.users and i.source=='FILE' and not i.packed_file],'usedImages':[i.name for i in bpy.data.images if i.users and i.source in ['FILE','GENERATED']],'metric':bpy.context.scene.unit_settings.system=='METRIC' and abs(bpy.context.scene.unit_settings.scale_length-1)<1e-8})\n  results.append(result)\n except Exception as error:\n  results.append(dict(entry,error=str(error)))\nprint('SOURCE_BLEND_AUDIT_JSON '+json.dumps(results),flush=True)\n`;
  await fs.mkdir('/tmp/flc-photo-expansion-blender-config', {recursive: true});
  const output = execFileSync('blender', ['--background', '--factory-startup', '--disable-autoexec', '--threads', '1', '--python-expr', python], {encoding: 'utf8', timeout: 180000, maxBuffer: 16 * 1024 * 1024, env: {...process.env, BLENDER_USER_CONFIG: '/tmp/flc-photo-expansion-blender-config'}});
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
  const saved = JSON.parse(await fs.readFile('review/photo_expansion/baseline.json'));
  const paths = baselinePaths();
  check(saved.baselineCommit === baseline && saved.excludedAsset === excludedOldAsset && saved.assets.length === 18, 'exact baseline commit and 18 preserved asset identities');
  check(JSON.stringify(saved.files.map(f => art + f.path).sort()) === JSON.stringify(paths.slice().sort()), 'baseline receipt includes every committed prior asset file');
  for (const file of saved.files) {
    const before = execFileSync('git', ['show', baseline + ':' + art + file.path], {maxBuffer: 128 * 1024 * 1024});
    const now = await fs.readFile(file.path);
    check(sha(before) === file.sha256 && before.length === file.bytes, 'baseline digest independently verified: ' + file.path);
    check(now.equals(before), 'prior asset unchanged: ' + file.path);
    preserved.push(file);
  }
} catch (error) {check(false, '18-asset immutable baseline check completed', error.stack);}

if (!baselineOnly) await checkPantryRevision();
check(assets.length === expectedCount, 'all selected expansion assets fully decoded', {expectedCount, actual: assets.length, selectedNamespaces});
const changedInputs = [];
for (const input of [...sourceReports, ...sourceSnapshots]) {
  try {if (sha(await fs.readFile(input.file)) !== input.sha256) changedInputs.push(input.file);}
  catch {changedInputs.push(input.file);}
}
check(changedInputs.length === 0, 'all source receipts and native/GLB inputs stayed unchanged during validation', changedInputs);
const output = baselineOnly ? 'baseline_validation.json' : pantryOnly ? 'pantry_validation.json' : selectedNamespaces.length === 1 ? selectedNamespaces[0] + '_validation.json' : 'validation.json';
await fs.mkdir('review/photo_expansion', {recursive: true});
await fs.writeFile('review/photo_expansion/' + output, JSON.stringify({
  schema: 1, checks: rows.length, failures: errors.length, passed: errors.length === 0,
  selectedNamespaces, completeExpansion: selectedNamespaces.length === 3 && assets.length === expectedCount,
  scope: 'Independent real geometry and direct Draco bitstream decode, source provenance, 18 prior assets unchanged, and revised pantry shape/composition contracts. Proportions are photographic estimates. No browser/GPU, Godot, collision or exact-product acceptance.',
  preservedBaseline: baseline, sourceReports, nativeSourceAudits, preservedOriginalFiles: preserved, assets, errors, rows
}, null, 2) + '\n');
console.log(`Photo expansion: ${rows.length} checks, ${errors.length} failures, ${assets.length}/${expectedCount} selected new assets, ${preserved.length} old files compared.`);
for (const error of errors) console.error(error);
if (errors.length) process.exitCode = 1;
