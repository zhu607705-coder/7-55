#!/usr/bin/env bash
set -euo pipefail
MEDIA_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# Share the validator/source-sync lock. user:// isolation does not isolate res://.
mkdir -p "$MEDIA_ROOT/.validation"
if ! mkdir "$MEDIA_ROOT/.validation/runner.lock"; then
  echo "Native workspace busy; do not convert media during source sync/import/validation" >&2
  exit 1
fi
printf 'media conversion shell pid=%s\n' "$$" > "$MEDIA_ROOT/.validation/runner.lock/owner.txt"
trap 'rm -f "$MEDIA_ROOT/.validation/runner.lock/owner.txt"; rmdir "$MEDIA_ROOT/.validation/runner.lock"' EXIT
"${NODE_BIN:-node}" - "$MEDIA_ROOT" "$@" <<'NODE'
// libtheora -q is VBR; combining it with -b does not impose a file-size cap.
// Keep q8 unless the actual result exceeds the delivery budget. Retry a bounded
// quality ladder, then validate whole streams before replacing generated media.
// https://ffmpeg.org/ffmpeg-codecs.html#libtheora
const fs = require('node:fs');
const path = require('node:path');
const os = require('node:os');
const crypto = require('node:crypto');
const { spawnSync } = require('node:child_process');
const mediaRoot = process.argv[2];
const options = new Map();
for (const argument of process.argv.slice(3)) {
  const match = argument.match(/^--(input|output|max-bytes|report)=(.+)$/);
  if (!match || options.has(match[1])) throw new Error(`Invalid/duplicate media conversion argument: ${argument}`);
  options.set(match[1], match[2]);
}
// A lower limit is useful for an isolated real-clip regression. A larger limit
// cannot weaken production's 24 MB PCK budget (500 KB is reserved for overhead).
const maxBytes = Number(options.get('max-bytes') || 23_500_000);
if (!Number.isSafeInteger(maxBytes) || maxBytes < 1024 || maxBytes > 23_500_000) throw new Error('Media budget must be 1024..23500000 bytes');
if (options.has('input') !== options.has('output')) throw new Error('--input and --output must be supplied together');
const ffmpeg = process.env.FFMPEG_BIN || 'ffmpeg';
const ffprobe = process.env.FFPROBE_BIN || 'ffprobe';
const inputs = options.has('input') ? [{ input: path.resolve(options.get('input')), output: path.resolve(options.get('output')) }] : [
  'rpg/cinematics/chapter4-prologue/chapter35_to_chapter4_h3_transition',
  'rpg/cinematics/qizhen-rain-rescue/qizhen_rain_rescue_hailuo23_v01',
].map(relative => ({ input: path.join(mediaRoot, 'assets', relative + '.mp4'), output: path.join(mediaRoot, 'assets', relative + '.ogv') }));
function run(command, args) {
  const result = spawnSync(command, args, { encoding: 'utf8', maxBuffer: 4 * 1024 * 1024, timeout: 600_000 });
  if (result.error || result.status !== 0) throw new Error(`${command} failed: ${result.error?.message || result.stderr || result.status}`);
  return result.stdout;
}
function probe(filename) {
  return JSON.parse(run(ffprobe, ['-v', 'error', '-count_frames', '-show_entries', 'format=duration:stream=index,codec_type,codec_name,width,height,r_frame_rate,avg_frame_rate,duration,nb_read_frames,channels,sample_rate', '-of', 'json', filename]));
}
function rate(stream) {
  for (const value of [stream.avg_frame_rate, stream.r_frame_rate]) {
    const [numerator, denominator] = String(value).split('/').map(Number);
    if (numerator > 0 && denominator > 0) return numerator / denominator;
  }
  throw new Error('Video frame rate cannot be measured');
}
function validate(source, generated) {
  const video = source.streams.filter(stream => stream.codec_type === 'video');
  const actualVideo = generated.streams.filter(stream => stream.codec_type === 'video');
  const audio = source.streams.filter(stream => stream.codec_type === 'audio');
  const actualAudio = generated.streams.filter(stream => stream.codec_type === 'audio');
  if (video.length !== 1 || actualVideo.length !== 1 || actualVideo[0].codec_name !== 'theora') throw new Error('Conversion must preserve the complete single video stream');
  const before = video[0], after = actualVideo[0];
  if (before.width !== after.width || before.height !== after.height || Math.abs(rate(before) - rate(after)) > 0.000001 || !Number.isSafeInteger(Number(before.nb_read_frames)) || Number(before.nb_read_frames) < 1 || before.nb_read_frames !== after.nb_read_frames) throw new Error('Conversion changed resolution, frame rate or decoded frame count');
  const tolerance = Math.max(0.12, 1 / rate(before) + 0.05);
  if (!Number.isFinite(Number(source.format.duration)) || !Number.isFinite(Number(generated.format.duration)) || Number(source.format.duration) <= 0 || Number(generated.format.duration) <= 0 || Math.abs(Number(source.format.duration) - Number(generated.format.duration)) > tolerance) throw new Error('Conversion changed complete clip duration');
  if (audio.length !== actualAudio.length || audio.some((stream, index) => actualAudio[index].codec_name !== 'vorbis' || stream.channels !== actualAudio[index].channels || stream.sample_rate !== actualAudio[index].sample_rate || (Number.isFinite(Number(stream.duration)) && (!Number.isFinite(Number(actualAudio[index].duration)) || Math.abs(Number(stream.duration) - Number(actualAudio[index].duration)) > tolerance)))) throw new Error('Conversion dropped or changed an audio track');
}
const reports = [];
for (const { input, output } of inputs) {
  if (input === output || path.extname(output) !== '.ogv') throw new Error('Conversion output must be a distinct generated .ogv file');
  const sourceSha256 = crypto.createHash('sha256').update(fs.readFileSync(input)).digest('hex');
  const source = probe(input);
  const temporary = fs.mkdtempSync(path.join(os.tmpdir(), '755-bounded-ogv-'));
  const candidate = path.join(temporary, 'candidate.ogv');
  const attempts = [];
  try {
    let quality;
    for (const level of [8, 7, 6, 5, 4]) {
      // No -fs, -t, -r, scale, shortest, or stream dropping: only video quality
      // changes on retry. Every authored audio track keeps Vorbis quality 5.
      run(ffmpeg, ['-nostdin', '-y', '-v', 'error', '-i', input, '-map', '0:v:0', '-map', '0:a?', '-c:v', 'libtheora', '-q:v', String(level), '-c:a', 'libvorbis', '-q:a', '5', candidate]);
      const bytes = fs.statSync(candidate).size;
      attempts.push({ quality: level, bytes });
      if (bytes <= maxBytes) { quality = level; break; }
    }
    if (quality === undefined) throw new Error(`OGV remains above ${maxBytes} bytes after bounded quality retries: ${JSON.stringify(attempts)}`);
    const generated = probe(candidate);
    validate(source, generated);
    if (crypto.createHash('sha256').update(fs.readFileSync(input)).digest('hex') !== sourceSha256) throw new Error('Original source clip changed during conversion');
    fs.mkdirSync(path.dirname(output), { recursive: true });
    const replacement = output + `.validated-${process.pid}.tmp`;
    try { fs.copyFileSync(candidate, replacement); fs.renameSync(replacement, output); }
    finally { fs.rmSync(replacement, { force: true }); }
    const row = { input, output, maxBytes, quality, attempts, bytes: fs.statSync(output).size, sourceSha256, outputSha256: crypto.createHash('sha256').update(fs.readFileSync(output)).digest('hex'), source, generated, fullStreamValidation: true };
    reports.push(row);
    console.log(JSON.stringify({ input, output, quality, attempts, bytes: row.bytes, maxBytes, fullStreamValidation: true }));
  } finally { fs.rmSync(temporary, { recursive: true, force: true }); }
}
// A formal validation run checks this receipt, not mere .ogv existence.
// Custom single-clip regressions do not certify production preparation.
if (!options.has('input')) {
  const receipt = path.join(mediaRoot, '.validation', 'media-prepared.json');
  fs.mkdirSync(path.dirname(receipt), { recursive: true });
  fs.writeFileSync(receipt, JSON.stringify({
    converterSha256: crypto.createHash('sha256').update(fs.readFileSync(path.join(mediaRoot, 'tools/convert_media.sh'))).digest('hex'),
    reports: reports.map(row => ({ input: path.relative(mediaRoot, row.input), output: path.relative(mediaRoot, row.output), sourceSha256: row.sourceSha256, outputSha256: row.outputSha256, fullStreamValidation: row.fullStreamValidation }))
  }, null, 2) + '\n');
}
if (options.has('report')) {
  const filename = path.resolve(options.get('report'));
  fs.mkdirSync(path.dirname(filename), { recursive: true });
  fs.writeFileSync(filename, JSON.stringify({ success: true, maxBytes, reports }, null, 2) + '\n');
}
NODE
