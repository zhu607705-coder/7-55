import { createHash } from "node:crypto";
import { copyFile, mkdir, readFile, readdir, writeFile } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import { deflateSync, inflateSync } from "node:zlib";
import { fileURLToPath } from "node:url";

const repoRoot = resolve(dirname(fileURLToPath(import.meta.url)), "..");

export const CHAPTER4_755_ASSET_ROOT = resolve(
  repoRoot,
  "src/assets/rpg/interiors/finale/chapter4-755"
);
export const CHAPTER4_755_CANDIDATE_ROOT = resolve(
  repoRoot,
  "artifacts/chapter4-map-assets-20260820"
);

export const APPROVED_CHAPTER4_755_BASE_PLATES = Object.freeze([
  {
    id: "a1_base",
    floor: "A1",
    destination: "base/a1.png",
    sourceId: "chapter4_a1_base_v01",
    source: "base/chapter4_a1_base_v01.png",
    sourceSha256: "0df950f034d70b57429239871b5977acbd546b960fa0b89918b3718665f485e3"
  },
  {
    id: "a2_base",
    floor: "A2",
    destination: "base/a2.png",
    sourceId: "chapter4_a2_base_v02",
    source: "base/chapter4_a2_base_v02.png",
    sourceSha256: "b1d09d66f13e4a0c63a34ff6eff5a3f446c6925061e8cb421f437e5ac6e7fb04"
  },
  {
    id: "a3_base",
    floor: "A3",
    destination: "base/a3.png",
    sourceId: "chapter4_a3_base_v01",
    source: "base/chapter4_a3_base_v01.png",
    sourceSha256: "3077b3f6a2f16d97ecee866c516f1fd80341889f7a38779cc892680d5ba0a02e"
  }
]);

export const APPROVED_CHAPTER4_755_STATE_PLATES = Object.freeze([
  {
    id: "a1_2245_opening",
    floor: "A1",
    storyTime: "22:45",
    sourceId: "chapter4_a1_2245_opening_v01",
    source: "overlays/chapter4_a1_2245_opening_v01.png",
    destination: "states/a1_2245_opening.png",
    sourceSha256: "18cd6e61841af0fa5fb5057590c5c69b501957befab4c9d5a51e6878d0860eb4",
    sourceWidth: 1671,
    normalization: "append_last_source_column"
  },
  {
    id: "a1_1225_bakery",
    floor: "A1",
    storyTime: "12:25",
    sourceId: "chapter4_a1_1225_bakery_v01",
    source: "overlays/chapter4_a1_1225_bakery_v01.png",
    destination: "states/a1_1225_bakery.png",
    sourceSha256: "406bfdd13405db63694a6a0dd78701ddc6aa5e6095da289710c5faff967f7bbb",
    sourceWidth: 1671,
    normalization: "append_last_source_column"
  },
  {
    id: "a2_1850_evening",
    floor: "A2",
    storyTime: "18:50",
    sourceId: "chapter4_a2_1850_evening_v01",
    source: "overlays/chapter4_a2_1850_evening_v01.png",
    destination: "states/a2_1850_evening.png",
    sourceSha256: "52621f2fffb2273991a58f534198f8e5fbbeac26dc5cb3631e72658402830b0f",
    sourceWidth: 1672,
    normalization: "byte_copy"
  },
  {
    id: "a3_1850_reference",
    floor: "A3",
    storyTime: "18:50",
    sourceId: "chapter4_a3_1850_reference_v01",
    source: "overlays/chapter4_a3_1850_reference_v01.png",
    destination: "states/a3_1850_reference.png",
    sourceSha256: "e577321b077a70428a8819a376f066633fc5875e40431196eedc7160992b0836",
    sourceWidth: 1672,
    normalization: "byte_copy"
  },
  {
    id: "a1_2245_maintenance",
    floor: "A1",
    storyTime: "22:45",
    sourceId: "chapter4_a1_2245_maintenance_v01",
    source: "overlays/chapter4_a1_2245_maintenance_v01.png",
    destination: "states/a1_2245_maintenance.png",
    sourceSha256: "8059218cf9e49bbcda71bb34307adae2345b1bbcd2e592f65cd71c8fee27b2a3",
    sourceWidth: 1672,
    normalization: "byte_copy"
  },
  {
    id: "a1_0754_blackout",
    floor: "A1",
    storyTime: "07:54",
    sourceId: "chapter4_a1_0754_blackout_v01",
    source: "overlays/chapter4_a1_0754_blackout_v01.png",
    destination: "states/a1_0754_blackout.png",
    sourceSha256: "47a72533a5312d65fe6961b430a0d08216af0aa18d4deb2ce4d586325ea0eef7",
    sourceWidth: 1672,
    normalization: "byte_copy"
  },
  {
    id: "a2_0754_chase",
    floor: "A2",
    storyTime: "07:54",
    sourceId: "chapter4_a2_0754_chase_v01",
    source: "overlays/chapter4_a2_0754_chase_v01.png",
    destination: "states/a2_0754_chase.png",
    sourceSha256: "9444e7bc9ac33fb73166134f54e3658d7151a0c476252716df52a9ab05d086dd",
    sourceWidth: 1672,
    normalization: "byte_copy"
  },
  {
    id: "a2_202_final_minute",
    floor: "A2",
    storyTime: "07:54",
    sourceId: "chapter4_a2_lecture_final_minute_v01",
    source: "overlays/chapter4_a2_lecture_final_minute_v01.png",
    destination: "states/a2_202_final_minute.png",
    sourceSha256: "49143da0edffc7ec53d5d8e2dc354cb5c3591658db0ac8b2017b54f8425c9b83",
    sourceWidth: 1671,
    normalization: "append_last_source_column"
  },
  {
    id: "a1_0755_morning",
    floor: "A1",
    storyTime: "07:55",
    sourceId: "chapter4_a1_0755_morning_v01",
    source: "overlays/chapter4_a1_0755_morning_v01.png",
    destination: "states/a1_0755_morning.png",
    sourceSha256: "ce7922dc71b68bf100b9952adb385e1cfa685b8bda55b3e9499b0a056b013db7",
    sourceWidth: 1672,
    normalization: "byte_copy"
  }
]);

export const APPROVED_CHAPTER4_755_SPRITESHEETS = Object.freeze([
  {
    id: "chapter4_clock_states",
    sourceId: "chapter4_clock_states_v01",
    source: "sprites/chapter4_clock_states_v01.png",
    destination: "sprites/chapter4_clock_states_v01.png",
    sourceSha256: "f0383adb43fc3a2c1da3386756230d2969de794c3ad9104f6bebe0530c9db3e3",
    width: 1225,
    height: 1284
  },
  {
    id: "chapter4_power_panel_states",
    sourceId: "chapter4_power_panel_states_v01",
    source: "sprites/chapter4_power_panel_states_v01.png",
    destination: "sprites/chapter4_power_panel_states_v01.png",
    sourceSha256: "3b043c9f634a36352544e352f0246b0c37196c59f393c5cecf36eb2e4a43b829",
    width: 1312,
    height: 1199
  },
  {
    id: "chapter4_story_items",
    sourceId: "chapter4_story_items_v02",
    source: "sprites/chapter4_story_items_v02.png",
    destination: "sprites/chapter4_story_items_v02.png",
    sourceSha256: "ef78a5a24134d8c0ec4de3d7d656f5a619c6ff299cd4d908f994f811470b7488",
    width: 1536,
    height: 1024
  },
  {
    id: "chapter4_room204_furniture",
    sourceId: "chapter4_a2_room204_furniture_v02",
    source: "sprites/chapter4_a2_room204_furniture_v02.png",
    destination: "sprites/chapter4_a2_room204_furniture_v02.png",
    sourceSha256: "37905e165bd6d5e5b30425d2635eca64feb2f695b21ca9c88b698fee10128b39",
    width: 1536,
    height: 1024
  },
  {
    id: "chapter4_room204_residual",
    sourceId: "chapter4_a2_room204_dark_residual_v02",
    source: "sprites/chapter4_a2_room204_dark_residual_v02.png",
    destination: "sprites/chapter4_a2_room204_dark_residual_v02.png",
    sourceSha256: "a0012d2d74e40d803dfb6875f8b778d581c8fc03618d4db0bd752e0e948f2595",
    width: 1536,
    height: 1024
  }
]);

const PNG_SIGNATURE = Buffer.from("89504e470d0a1a0a", "hex");

export function sha256(bytes) {
  return createHash("sha256").update(bytes).digest("hex");
}

export function readPngHeader(bytes, label = "PNG") {
  if (!bytes.subarray(0, 8).equals(PNG_SIGNATURE)) {
    throw new Error(`${label} has an invalid PNG signature.`);
  }
  if (bytes.subarray(12, 16).toString("ascii") !== "IHDR" || bytes.readUInt32BE(8) !== 13) {
    throw new Error(`${label} does not begin with a valid IHDR chunk.`);
  }
  return {
    width: bytes.readUInt32BE(16),
    height: bytes.readUInt32BE(20),
    bitDepth: bytes[24],
    colorType: bytes[25],
    compression: bytes[26],
    filter: bytes[27],
    interlace: bytes[28]
  };
}

export function decodePng(bytes, label = "PNG") {
  if (!bytes.subarray(0, 8).equals(PNG_SIGNATURE)) {
    throw new Error(`${label} has an invalid PNG signature.`);
  }
  let offset = 8;
  let ihdr = null;
  const idat = [];
  while (offset + 12 <= bytes.length) {
    const length = bytes.readUInt32BE(offset);
    const type = bytes.subarray(offset + 4, offset + 8).toString("ascii");
    const dataStart = offset + 8;
    const dataEnd = dataStart + length;
    if (dataEnd + 4 > bytes.length) throw new Error(`${label} contains a truncated ${type} chunk.`);
    const data = bytes.subarray(dataStart, dataEnd);
    if (type === "IHDR") {
      ihdr = {
        width: data.readUInt32BE(0),
        height: data.readUInt32BE(4),
        bitDepth: data[8],
        colorType: data[9],
        compression: data[10],
        filter: data[11],
        interlace: data[12]
      };
    } else if (type === "IDAT") {
      idat.push(data);
    } else if (type === "IEND") {
      break;
    }
    offset = dataEnd + 4;
  }
  if (!ihdr || idat.length === 0) throw new Error(`${label} lacks IHDR or IDAT data.`);
  if (ihdr.bitDepth !== 8 || ![2, 6].includes(ihdr.colorType) || ihdr.interlace !== 0) {
    throw new Error(
      `${label} must be non-interlaced 8-bit RGB/RGBA; got depth=${ihdr.bitDepth} colorType=${ihdr.colorType} interlace=${ihdr.interlace}.`
    );
  }
  if (ihdr.compression !== 0 || ihdr.filter !== 0) {
    throw new Error(`${label} uses an unsupported PNG compression/filter method.`);
  }
  const channels = ihdr.colorType === 6 ? 4 : 3;
  const rowBytes = ihdr.width * channels;
  const encoded = inflateSync(Buffer.concat(idat));
  const expectedLength = (rowBytes + 1) * ihdr.height;
  if (encoded.length !== expectedLength) {
    throw new Error(`${label} decoded byte length mismatch: expected ${expectedLength}, got ${encoded.length}.`);
  }
  const pixels = Buffer.alloc(rowBytes * ihdr.height);
  let sourceOffset = 0;
  for (let y = 0; y < ihdr.height; y += 1) {
    const filterType = encoded[sourceOffset];
    sourceOffset += 1;
    const rowOffset = y * rowBytes;
    for (let x = 0; x < rowBytes; x += 1) {
      const raw = encoded[sourceOffset + x];
      const left = x >= channels ? pixels[rowOffset + x - channels] : 0;
      const above = y > 0 ? pixels[rowOffset - rowBytes + x] : 0;
      const upperLeft = y > 0 && x >= channels
        ? pixels[rowOffset - rowBytes + x - channels]
        : 0;
      let value;
      if (filterType === 0) value = raw;
      else if (filterType === 1) value = raw + left;
      else if (filterType === 2) value = raw + above;
      else if (filterType === 3) value = raw + Math.floor((left + above) / 2);
      else if (filterType === 4) value = raw + paeth(left, above, upperLeft);
      else throw new Error(`${label} uses unsupported row filter ${filterType}.`);
      pixels[rowOffset + x] = value & 0xff;
    }
    sourceOffset += rowBytes;
  }
  return { ...ihdr, channels, pixels };
}

export function encodePng({ width, height, colorType, channels, pixels }) {
  if (![2, 6].includes(colorType) || channels !== (colorType === 6 ? 4 : 3)) {
    throw new Error("encodePng accepts only 8-bit RGB/RGBA pixel buffers.");
  }
  const rowBytes = width * channels;
  if (pixels.length !== rowBytes * height) throw new Error("encodePng pixel buffer length mismatch.");
  const scanlines = Buffer.alloc((rowBytes + 1) * height);
  for (let y = 0; y < height; y += 1) {
    const targetOffset = y * (rowBytes + 1);
    scanlines[targetOffset] = 0;
    pixels.copy(scanlines, targetOffset + 1, y * rowBytes, (y + 1) * rowBytes);
  }
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(width, 0);
  ihdr.writeUInt32BE(height, 4);
  ihdr[8] = 8;
  ihdr[9] = colorType;
  ihdr[10] = 0;
  ihdr[11] = 0;
  ihdr[12] = 0;
  return Buffer.concat([
    PNG_SIGNATURE,
    pngChunk("IHDR", ihdr),
    pngChunk("IDAT", deflateSync(scanlines, { level: 9 })),
    pngChunk("IEND", Buffer.alloc(0))
  ]);
}

export function appendLastPngColumn(bytes, label = "PNG") {
  const decoded = decodePng(bytes, label);
  const width = decoded.width + 1;
  const rowBytes = width * decoded.channels;
  const sourceRowBytes = decoded.width * decoded.channels;
  const pixels = Buffer.alloc(rowBytes * decoded.height);
  for (let y = 0; y < decoded.height; y += 1) {
    const sourceOffset = y * sourceRowBytes;
    const targetOffset = y * rowBytes;
    decoded.pixels.copy(pixels, targetOffset, sourceOffset, sourceOffset + sourceRowBytes);
    decoded.pixels.copy(
      pixels,
      targetOffset + sourceRowBytes,
      sourceOffset + sourceRowBytes - decoded.channels,
      sourceOffset + sourceRowBytes
    );
  }
  return encodePng({ ...decoded, width, pixels });
}

export function alphaBounds(decoded, region = null, threshold = 13) {
  if (decoded.channels !== 4) throw new Error("alphaBounds requires an RGBA PNG.");
  const rect = region ?? { x: 0, y: 0, width: decoded.width, height: decoded.height };
  assertRectInside(rect, decoded.width, decoded.height, "alpha scan region");
  let minX = rect.x + rect.width;
  let minY = rect.y + rect.height;
  let maxX = -1;
  let maxY = -1;
  for (let y = rect.y; y < rect.y + rect.height; y += 1) {
    for (let x = rect.x; x < rect.x + rect.width; x += 1) {
      const alpha = decoded.pixels[(y * decoded.width + x) * 4 + 3];
      if (alpha < threshold) continue;
      minX = Math.min(minX, x);
      minY = Math.min(minY, y);
      maxX = Math.max(maxX, x);
      maxY = Math.max(maxY, y);
    }
  }
  if (maxX < minX || maxY < minY) return null;
  return { x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1 };
}

async function normalizeAssets() {
  const baseDirectory = resolve(CHAPTER4_755_ASSET_ROOT, "base");
  const stateDirectory = resolve(CHAPTER4_755_ASSET_ROOT, "states");
  const spriteDirectory = resolve(CHAPTER4_755_ASSET_ROOT, "sprites");
  await mkdir(baseDirectory, { recursive: true });
  await mkdir(stateDirectory, { recursive: true });
  await mkdir(spriteDirectory, { recursive: true });
  await assertDirectoryContainsOnly(baseDirectory, APPROVED_CHAPTER4_755_BASE_PLATES.map(({ destination }) => destination));
  await assertDirectoryContainsOnly(stateDirectory, APPROVED_CHAPTER4_755_STATE_PLATES.map(({ destination }) => destination));
  await assertDirectoryContainsOnly(spriteDirectory, APPROVED_CHAPTER4_755_SPRITESHEETS.map(({ destination }) => destination));

  for (const base of APPROVED_CHAPTER4_755_BASE_PLATES) {
    const sourceBytes = await readApprovedSource(base);
    const destinationPath = resolve(CHAPTER4_755_ASSET_ROOT, base.destination);
    await mkdir(dirname(destinationPath), { recursive: true });
    await copyFile(resolve(CHAPTER4_755_CANDIDATE_ROOT, base.source), destinationPath);
    const destinationBytes = await readFile(destinationPath);
    if (sha256(destinationBytes) !== base.sourceSha256 || !sourceBytes.equals(destinationBytes)) {
      throw new Error(`${base.id} formal base must remain the approved byte-for-byte source.`);
    }
    assertPngContract(decodePng(destinationBytes, base.destination), 1672, 941, 3, base.destination);
    console.log(`normalized base ${base.id} byte_copy sha256=${base.sourceSha256}`);
  }

  for (const state of APPROVED_CHAPTER4_755_STATE_PLATES) {
    const sourceBytes = await readApprovedSource(state);
    const decoded = decodePng(sourceBytes, state.sourceId);
    assertPngContract(decoded, state.sourceWidth, 941, 3, state.sourceId);
    const destinationPath = resolve(CHAPTER4_755_ASSET_ROOT, state.destination);
    await mkdir(dirname(destinationPath), { recursive: true });
    if (state.normalization === "byte_copy") {
      await copyFile(resolve(CHAPTER4_755_CANDIDATE_ROOT, state.source), destinationPath);
    } else if (state.normalization === "append_last_source_column") {
      await writeFile(destinationPath, appendLastPngColumn(sourceBytes, state.sourceId));
    } else {
      throw new Error(`${state.id} has unsupported normalization ${state.normalization}.`);
    }
    const destinationBytes = await readFile(destinationPath);
    assertPngContract(decodePng(destinationBytes, state.destination), 1672, 941, 3, state.destination);
    console.log(
      `normalized state ${state.id} ${state.normalization} source=${state.sourceSha256} output=${sha256(destinationBytes)}`
    );
  }

  for (const sheet of APPROVED_CHAPTER4_755_SPRITESHEETS) {
    const sourceBytes = await readApprovedSource(sheet);
    assertPngContract(decodePng(sourceBytes, sheet.sourceId), sheet.width, sheet.height, 4, sheet.sourceId);
    const destinationPath = resolve(CHAPTER4_755_ASSET_ROOT, sheet.destination);
    await mkdir(dirname(destinationPath), { recursive: true });
    await copyFile(resolve(CHAPTER4_755_CANDIDATE_ROOT, sheet.source), destinationPath);
    const destinationBytes = await readFile(destinationPath);
    if (!destinationBytes.equals(sourceBytes)) throw new Error(`${sheet.id} sprite copy changed bytes.`);
    console.log(`normalized sprite ${sheet.id} byte_copy sha256=${sheet.sourceSha256}`);
  }
}

async function readApprovedSource(entry) {
  const bytes = await readFile(resolve(CHAPTER4_755_CANDIDATE_ROOT, entry.source));
  const digest = sha256(bytes);
  if (digest !== entry.sourceSha256) {
    throw new Error(`${entry.sourceId} source hash mismatch: expected ${entry.sourceSha256}, got ${digest}.`);
  }
  return bytes;
}

async function assertDirectoryContainsOnly(directory, destinations) {
  const allowed = new Set(destinations.map((destination) => destination.split("/").at(-1)));
  const unexpected = (await readdir(directory)).filter((name) => !allowed.has(name));
  if (unexpected.length) {
    throw new Error(`${directory} contains unapproved active assets: ${unexpected.join(", ")}.`);
  }
}

function assertPngContract(decoded, width, height, channels, label) {
  if (decoded.width !== width || decoded.height !== height || decoded.channels !== channels) {
    throw new Error(
      `${label} must be ${width}x${height} with ${channels} channels; got ${decoded.width}x${decoded.height} with ${decoded.channels}.`
    );
  }
}

function assertRectInside(rect, width, height, label) {
  if (
    !Number.isInteger(rect.x) || !Number.isInteger(rect.y)
    || !Number.isInteger(rect.width) || !Number.isInteger(rect.height)
    || rect.width <= 0 || rect.height <= 0
    || rect.x < 0 || rect.y < 0
    || rect.x + rect.width > width || rect.y + rect.height > height
  ) {
    throw new Error(`${label} is outside ${width}x${height}: ${JSON.stringify(rect)}.`);
  }
}

function paeth(left, above, upperLeft) {
  const prediction = left + above - upperLeft;
  const leftDistance = Math.abs(prediction - left);
  const aboveDistance = Math.abs(prediction - above);
  const upperLeftDistance = Math.abs(prediction - upperLeft);
  if (leftDistance <= aboveDistance && leftDistance <= upperLeftDistance) return left;
  if (aboveDistance <= upperLeftDistance) return above;
  return upperLeft;
}

function pngChunk(type, data) {
  const typeBytes = Buffer.from(type, "ascii");
  const chunk = Buffer.alloc(12 + data.length);
  chunk.writeUInt32BE(data.length, 0);
  typeBytes.copy(chunk, 4);
  data.copy(chunk, 8);
  chunk.writeUInt32BE(crc32(Buffer.concat([typeBytes, data])), 8 + data.length);
  return chunk;
}

const CRC_TABLE = Array.from({ length: 256 }, (_, index) => {
  let value = index;
  for (let bit = 0; bit < 8; bit += 1) {
    value = (value & 1) ? (0xedb88320 ^ (value >>> 1)) : (value >>> 1);
  }
  return value >>> 0;
});

function crc32(bytes) {
  let crc = 0xffffffff;
  for (const byte of bytes) crc = CRC_TABLE[(crc ^ byte) & 0xff] ^ (crc >>> 8);
  return (crc ^ 0xffffffff) >>> 0;
}

const invokedAsScript = process.argv[1]
  && resolve(process.argv[1]) === fileURLToPath(import.meta.url);
if (invokedAsScript) {
  await normalizeAssets();
  console.log(
    `chapter4 7:55 normalization PASS bases=${APPROVED_CHAPTER4_755_BASE_PLATES.length} states=${APPROVED_CHAPTER4_755_STATE_PLATES.length} sprites=${APPROVED_CHAPTER4_755_SPRITESHEETS.length}`
  );
}
