#!/usr/bin/env node
// Exercise the actual pinned export's init and ScriptProcessor creation code.
// This is a capability unit test; real insecure-origin engine/audio acceptance
// remains a separate browser gate (localhost is a secure-context exception).
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import vm from 'node:vm';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import {
  AUDIO_COMPAT_ENGINE, AUDIO_COMPAT_SOURCE_SHA256, AUDIO_COMPAT_OUTPUT_SHA256,
  POSITION_WORKLET_INIT, GUARDED_POSITION_WORKLET_INIT,
  transformWebAudioSource, applyWebAudioCompatibility, verifyWebAudioCompatibility,
} from './web_audio_compat.mjs';

const argument = process.argv.find(value => value.startsWith('--engine-script='));
const exportArgument = process.argv.find(value => value.startsWith('--export='));
if (!argument && !exportArgument) throw new Error('Pass --export=<actual export directory> or --engine-script=<official or compatibility-patched 4.7.1 index.js>');
const filename = argument ? path.resolve(argument.slice('--engine-script='.length)) : path.resolve(exportArgument.slice('--export='.length), 'index.js');
const sha256 = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
let original = fs.readFileSync(filename, 'utf8');
const inputSha256 = sha256(original);
if (inputSha256 === AUDIO_COMPAT_OUTPUT_SHA256) original = original.replace(GUARDED_POSITION_WORKLET_INIT, POSITION_WORKLET_INIT);
assert.equal(sha256(original), AUDIO_COMPAT_SOURCE_SHA256, 'Tests require actual pinned engine bytes');
let checks = 0;
function pass(callback) { callback(); checks++; }
const directory = fs.mkdtempSync(path.join(os.tmpdir(), '755-audio-compat-test-'));
try {
  const result = transformWebAudioSource(original, AUDIO_COMPAT_ENGINE);
  pass(() => assert.equal(sha256(result.source), AUDIO_COMPAT_OUTPUT_SHA256));
  pass(() => assert.equal(result.source.replace(GUARDED_POSITION_WORKLET_INIT, POSITION_WORKLET_INIT), original));
  pass(() => assert.doesNotThrow(() => new vm.Script(result.source)));
  pass(() => assert.throws(() => transformWebAudioSource(original, '4.8.stable.official'), /pinned/));
  pass(() => assert.throws(() => transformWebAudioSource(original, '4.7.2.stable.official'), /pinned/));
  pass(() => assert.throws(() => transformWebAudioSource(original + '\n', AUDIO_COMPAT_ENGINE), /differs from the pinned official/));
  pass(() => assert.throws(() => transformWebAudioSource(original.replace(POSITION_WORKLET_INIT, ''), AUDIO_COMPAT_ENGINE), /exactly one/));
  pass(() => assert.throws(() => transformWebAudioSource(original + POSITION_WORKLET_INIT, AUDIO_COMPAT_ENGINE), /exactly one/));
  pass(() => assert.throws(() => transformWebAudioSource(result.source, AUDIO_COMPAT_ENGINE), /exactly one/));
  fs.writeFileSync(path.join(directory, 'index.js'), original);
  const provenance = applyWebAudioCompatibility(directory, AUDIO_COMPAT_ENGINE);
  pass(() => assert.deepEqual(verifyWebAudioCompatibility(directory, provenance, AUDIO_COMPAT_ENGINE), result.provenance));
  pass(() => assert.throws(() => verifyWebAudioCompatibility(directory, provenance, '4.7.2.stable.official'), /pinned/));
  pass(() => assert.throws(() => verifyWebAudioCompatibility(directory, { ...provenance, sourceSha256: '0'.repeat(64) }, AUDIO_COMPAT_ENGINE), /provenance/));
  pass(() => assert.throws(() => verifyWebAudioCompatibility(directory, { ...provenance, extra: true }, AUDIO_COMPAT_ENGINE), /provenance/));
  fs.appendFileSync(path.join(directory, 'index.js'), '\n');
  pass(() => assert.throws(() => verifyWebAudioCompatibility(directory, provenance, AUDIO_COMPAT_ENGINE), /exact pinned/));
  fs.writeFileSync(path.join(directory, 'index.js'), result.source);

  function initSource(source) {
    const start = source.indexOf('init:function(mix_rate,latency,onstatechange,onlatencyupdate){');
    const end = source.indexOf('},create_input:', start);
    assert.ok(start > 0 && end > start);
    return source.slice(start + 'init:'.length, end + 1);
  }
  const scriptStart = original.indexOf('var GodotAudioScript=');
  const createStart = original.indexOf('create:function(buffer_length,channel_count){', scriptStart);
  const createEnd = original.indexOf('},start:', createStart);
  const scriptCreate = original.slice(createStart, createEnd + 1);
  const workletStart = original.indexOf('function _godot_audio_has_worklet()');
  const workletEnd = original.indexOf('}function ', workletStart);
  const hasWorklet = original.slice(workletStart, workletEnd + 1);
  const scriptCheckStart = original.indexOf('function _godot_audio_has_script_processor()');
  const scriptCheckEnd = original.indexOf('}function ', scriptCheckStart);
  const hasScript = original.slice(scriptCheckStart, scriptCheckEnd + 1);
  function environment(source, worklet) {
    const calls = { states: [], latency: [], script: [], module: [], exit: [], timer: null };
    class AudioContext {
      constructor(options) {
        calls.options = options;
        this.destination = { channelCount: 2 }; this.state = 'suspended'; this.sampleRate = 48000;
        this.baseLatency = 0.01; this.outputLatency = 0.02;
        if (worklet) this.audioWorklet = worklet;
      }
      createScriptProcessor(...args) { calls.script.push(args); return { bufferSize: args[0] }; }
    }
    const context = vm.createContext({
      window: { AudioContext }, GodotAudio: { audioPositionWorkletPromise: null, close_async() {} },
      GodotOS: { atexit(callback) { calls.exit.push(callback); } },
      GodotConfig: { locate_file(file) { return `https://test.invalid/${file}`; } },
      setInterval(callback, milliseconds) { calls.timer = callback; calls.interval = milliseconds; return 7; },
    });
    vm.runInContext(`GodotAudio.init=${initSource(source)}; var GodotAudioScript={script:null,${scriptCreate}}; ${hasWorklet}; ${hasScript}`, context);
    const init = () => context.GodotAudio.init(44100, 50, state => calls.states.push(state), latency => calls.latency.push(latency));
    return { context, calls, init };
  }
  const broken = environment(original);
  pass(() => assert.throws(broken.init, /addModule/));
  const fallback = environment(result.source);
  pass(() => assert.equal(fallback.init(), 2));
  pass(() => assert.equal(fallback.context._godot_audio_has_worklet(), 0));
  pass(() => assert.equal(fallback.context._godot_audio_has_script_processor(), 1));
  pass(() => assert.equal('audioWorklet' in fallback.context.GodotAudio.ctx, false));
  pass(() => assert.equal(fallback.context.GodotAudio.audioPositionWorkletPromise, null));
  pass(() => assert.equal(fallback.context.GodotAudioScript.create(2048, 2), 2048));
  pass(() => assert.deepEqual(fallback.calls.script, [[2048, 2, 2]]));
  pass(() => assert.equal(fallback.context.GodotAudio.driver, fallback.context.GodotAudioScript));
  pass(() => assert.deepEqual(fallback.calls.states, [0]));
  fallback.context.GodotAudio.ctx.state = 'running'; fallback.context.GodotAudio.ctx.onstatechange();
  pass(() => assert.deepEqual(fallback.calls.states, [0, 1]));
  fallback.calls.timer();
  pass(() => assert.equal(fallback.calls.latency[0], 0.03));
  pass(() => assert.equal(fallback.calls.exit.length, 1));
  const pending = Promise.resolve();
  const loaded = [];
  const normal = environment(result.source, { addModule(file) { loaded.push(file); return pending; } });
  pass(() => assert.equal(normal.init(), 2));
  pass(() => assert.equal(normal.context._godot_audio_has_worklet(), 1));
  pass(() => assert.equal(normal.context.GodotAudio.audioPositionWorkletPromise, pending));
  pass(() => assert.deepEqual(loaded, ['https://test.invalid/godot.audio.position.worklet.js']));
  const failed = Promise.reject(new Error('Expected module fetch rejection')); failed.catch(() => {});
  const rejecting = environment(result.source, { addModule() { return failed; } }); rejecting.init();
  await assert.rejects(rejecting.context.GodotAudio.audioPositionWorkletPromise, /Expected module fetch rejection/); checks++;

  // Exercise the real builder's HTML transformation without running an export.
  const build = fs.readFileSync(new URL('./build_web.mjs', import.meta.url), 'utf8');
  const binding = build.slice(build.indexOf('function bindScript('), build.indexOf('function walk('));
  const bindingContext = vm.createContext({ fs, path, output: directory, fileSha256: file => sha256(fs.readFileSync(file)) });
  vm.runInContext(binding, bindingContext);
  const htmlFile = path.join(directory, 'index.html');
  fs.writeFileSync(path.join(directory, 'content-loader.js'), '/* actual loader bytes */');
  fs.writeFileSync(htmlFile, '<script src="index.js" onerror="error()"></script><script src="content-loader.js?v=abcd"></script>');
  bindingContext.bindScript('index.js'); bindingContext.bindScript('content-loader.js');
  pass(() => assert.ok(fs.readFileSync(htmlFile, 'utf8').includes(`src="index.js?v=${AUDIO_COMPAT_OUTPUT_SHA256}" onerror="error()"`)));
  pass(() => assert.ok(fs.readFileSync(htmlFile, 'utf8').includes(`content-loader.js?v=${sha256(fs.readFileSync(path.join(directory, 'content-loader.js')))}`)));
  fs.writeFileSync(htmlFile, '<script src="index.js"></script><script src="index.js"></script>');
  pass(() => assert.throws(() => bindingContext.bindScript('index.js'), /exactly one/));
  fs.writeFileSync(htmlFile, '<script src="indexXjs"></script>');
  pass(() => assert.throws(() => bindingContext.bindScript('index.js'), /exactly one/));
  console.log(JSON.stringify({ success: true, checks, input: filename, inputSha256, sourceSha256: AUDIO_COMPAT_SOURCE_SHA256, patchedSha256: AUDIO_COMPAT_OUTPUT_SHA256, scope: 'Exact official export transform/provenance; actual init missing-worklet regression and preserved ScriptProcessor creation; existing worklet/rejection behavior; HTML script cache identities. No real-browser or audibility claim.' }, null, 2));
} finally { fs.rmSync(directory, { recursive: true, force: true }); }
