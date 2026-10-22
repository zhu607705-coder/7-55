// Godot 4.7.2's common audio init loads the Sample position worklet before
// selecting a mixer. On insecure HTTP audioWorklet is absent, so that load
// throws before the engine can try its existing ScriptProcessor mixer. This
// release uses Stream playback; only skip the unavailable optional worklet.
// Do not fabricate an AudioWorklet or advertise Sample playback support.
// Upstream 4.7.2-stable: platform/web/js/libs/library_godot_audio.js:1285,
// platform/web/os_web.cpp:303 and servers/audio/audio_server.cpp:228.
// https://github.com/godotengine/godot/tree/4.7.2-stable/platform/web
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';

export const AUDIO_COMPAT_ENGINE = '4.7.2.stable.official';
export const AUDIO_COMPAT_ID = '755-godot-4.7.2-position-worklet-capability-v1';
export const AUDIO_COMPAT_SOURCE_SHA256 = '33c94cb3175f3333b82e2a3be5e8e86f77986f0aa2042b1631f6367a4e5bb6ba';
export const AUDIO_COMPAT_OUTPUT_SHA256 = '649986c2276d830baa17cd1774a4bb192fc929186e040394b4fc728a350919cd';
export const POSITION_WORKLET_INIT = 'GodotAudio.audioPositionWorkletPromise=ctx.audioWorklet.addModule(path);';
export const GUARDED_POSITION_WORKLET_INIT = 'if(ctx.audioWorklet){GodotAudio.audioPositionWorkletPromise=ctx.audioWorklet.addModule(path)}';
const sha256 = source => crypto.createHash('sha256').update(source).digest('hex');
const count = (source, needle) => source.split(needle).length - 1;
function requireEngine(engine) {
  if (engine !== AUDIO_COMPAT_ENGINE) throw new Error(`Audio compatibility transform requires pinned ${AUDIO_COMPAT_ENGINE}; review upstream before changing the pin`);
}
function receipt() {
  return {
    id: AUDIO_COMPAT_ID, engine: AUDIO_COMPAT_ENGINE, file: 'index.js',
    sourceSha256: AUDIO_COMPAT_SOURCE_SHA256, sha256: AUDIO_COMPAT_OUTPUT_SHA256,
    replacements: 1, playback: 'Stream', missingWorkletMixer: 'upstream-ScriptProcessor',
  };
}

export function transformWebAudioSource(source, engine) {
  requireEngine(engine);
  if (count(source, POSITION_WORKLET_INIT) !== 1 || count(source, GUARDED_POSITION_WORKLET_INIT) !== 0) throw new Error('Expected exactly one unmodified Godot position-worklet initializer');
  if (sha256(source) !== AUDIO_COMPAT_SOURCE_SHA256) throw new Error('Godot engine script differs from the pinned official template; review upstream instead of applying a guessed transform');
  const patched = source.replace(POSITION_WORKLET_INIT, GUARDED_POSITION_WORKLET_INIT);
  if (sha256(patched) !== AUDIO_COMPAT_OUTPUT_SHA256) throw new Error('Godot audio compatibility output differs from its pinned bytes');
  return { source: patched, provenance: receipt() };
}

export function applyWebAudioCompatibility(directory, engine) {
  const file = path.join(directory, 'index.js');
  const result = transformWebAudioSource(fs.readFileSync(file, 'utf8'), engine);
  fs.writeFileSync(file, result.source);
  verifyWebAudioCompatibility(directory, result.provenance, engine);
  return result.provenance;
}

export function verifyWebAudioCompatibility(directory, provenance, engine) {
  requireEngine(engine);
  const source = fs.readFileSync(path.join(directory, 'index.js'), 'utf8');
  if (count(source, GUARDED_POSITION_WORKLET_INIT) !== 1 || count(source, POSITION_WORKLET_INIT) !== 0 || sha256(source) !== AUDIO_COMPAT_OUTPUT_SHA256) throw new Error('Actual engine script is not the exact pinned audio compatibility output');
  const restored = source.replace(GUARDED_POSITION_WORKLET_INIT, POSITION_WORKLET_INIT);
  if (sha256(restored) !== AUDIO_COMPAT_SOURCE_SHA256) throw new Error('Cannot recover the exact official engine script from the audio compatibility output');
  const expected = receipt();
  if (!provenance || Object.keys(provenance).length !== Object.keys(expected).length || Object.entries(expected).some(([key, value]) => provenance[key] !== value)) throw new Error('Audio compatibility provenance differs from the actual verified transform');
  return expected;
}
