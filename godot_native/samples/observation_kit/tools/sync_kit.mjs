#!/usr/bin/env node
// Copy four explicit portable files into a standalone Godot namespace.
// --check never mutates; no implicit creation of another level or project.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {fileURLToPath} from 'node:url';

const source = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const samples = path.dirname(source);
const args = process.argv.slice(2);
const check = args.includes('--check');
const targetArg = args.find(arg => !arg.startsWith('--')) || 'library_time';
if (args.some(arg => arg.startsWith('--') && arg !== '--check')) throw Error('Usage: sync_kit.mjs [sample_name] [--check]');
if (!/^[a-z][a-z0-9_]*$/.test(targetArg) || targetArg === 'observation_kit') throw Error('Use a single existing sample directory name');
const project = path.join(samples, targetArg);
if (!fs.existsSync(project) || !fs.statSync(project).isDirectory()) throw Error(`Create the isolated sample directory first: ${project}`);
const target = path.join(project, 'kit');
const files = ['camera_rig.gd', 'pointer_owners.gd', 'history_surface.gd', 'capture_inputs.gd'];
const hashes = {};
for (const file of files) {
  const bytes = fs.readFileSync(path.join(source, file));
  const text = bytes.toString('utf8');
  if (/(?:res:\/\/\.\.|(?:preload|load)\s*\(|user:\/\/|FileAccess|DirAccess|HTTPRequest)/.test(text)) throw Error(`${file}: kit must have no resource or external-state dependencies`);
  const destination = path.join(target, file);
  if (check) {
    if (!fs.existsSync(destination) || !fs.readFileSync(destination).equals(bytes)) throw Error(`Stale or missing kit copy: ${destination}`);
  } else {
    fs.mkdirSync(target, {recursive: true});
    fs.writeFileSync(destination, bytes);
  }
  hashes[file] = crypto.createHash('sha256').update(bytes).digest('hex');
}
console.log(JSON.stringify({kind: 'observation-kit', mode: check ? 'check' : 'sync', sample: targetArg, files: hashes}));
