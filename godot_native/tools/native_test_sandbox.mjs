import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {randomUUID} from 'node:crypto';

// Linux keeps the existing XDG contract. macOS resolves user:// independently
// of XDG, so give a disposable project config its own custom user directory.
// No runner changes HOME or the real project's project.godot.
if (!['linux', 'darwin'].includes(process.platform)) {
  throw new Error('NATIVE_TEST_PLATFORM_REQUIRED: isolated native tests support Linux and macOS; refusing to launch Godot');
}
const importCaches = new Map();
export function createNativeTestSandbox(sourceProject, prefix = '755-native-check-') {
  sourceProject = path.resolve(sourceProject);
  const storageBase = process.platform === 'darwin'
    ? path.join(os.homedir(), 'Library', 'Application Support') : os.tmpdir();
  fs.mkdirSync(storageBase, {recursive: true});
  const root = fs.mkdtempSync(path.join(storageBase, prefix));
  for (const folder of ['data', 'config', 'cache', 'state', 'tmp', 'runtime', 'evidence']) {
    fs.mkdirSync(path.join(root, folder));
  }
  const userData = path.join(root, 'data', 'SevenFiftyFiveNative');
  fs.mkdirSync(userData);
  const env = {
    ...process.env,
    XDG_DATA_HOME: path.join(root, 'data'), XDG_CONFIG_HOME: path.join(root, 'config'),
    XDG_CACHE_HOME: path.join(root, 'cache'), XDG_STATE_HOME: path.join(root, 'state'),
    GODOT_TEST_USER_DATA_DIR: userData, GODOT_SILENCE_ROOT_WARNING: '1',
    BUCT_V4_QA_DIR: path.join(root, 'evidence')
  };
  if (process.platform === 'linux') return {root, userData, env, project: sourceProject};

  // Retain res://../src and original-source hash checks without copying assets.
  const workspace = path.join(root, 'workspace');
  fs.mkdirSync(workspace);
  for (const sibling of ['src', 'public', 'docs', 'package.json', 'package-lock.json', 'node_modules']) {
    const source = path.join(path.dirname(sourceProject), sibling);
    if (fs.existsSync(source)) fs.symlinkSync(source, path.join(workspace, sibling));
  }
  const project = path.join(workspace, path.basename(sourceProject));
  fs.mkdirSync(project);
  for (const entry of fs.readdirSync(sourceProject)) {
    if (['project.godot', 'project.binary', '.godot', '.screenshots', 'exports'].includes(entry)) continue;
    fs.symlinkSync(path.join(sourceProject, entry), path.join(project, entry));
  }
  const original = fs.readFileSync(path.join(sourceProject, 'project.godot'), 'utf8');
  const name = `${path.basename(root)}/data/SevenFiftyFiveNative`;
  let config = original.replace(/^config\/(?:use_custom_user_dir|custom_user_dir_name)=.*\r?\n/gm, '');
  const settings = `config/use_custom_user_dir=true\nconfig/custom_user_dir_name="${name}"\n`;
  config = /^\[application\]$/m.test(config)
    ? config.replace(/^\[application\]\r?\n/m, `[application]\n${settings}`)
    : `${config}\n[application]\n${settings}`;
  fs.writeFileSync(path.join(project, 'project.godot'), config);
  // Reuse imported resources between fresh profiles. No saved game lives here.
  if (!importCaches.has(sourceProject)) importCaches.set(sourceProject,
    process.env.GODOT_TEST_IMPORT_PROJECT === sourceProject ? process.env.GODOT_TEST_IMPORT_CACHE : (
      fs.existsSync(path.join(sourceProject, '.godot')) ? path.join(sourceProject, '.godot')
        : fs.mkdtempSync(path.join(os.tmpdir(), '755-native-import-cache-'))
    )
  );
  const importCache = importCaches.get(sourceProject);
  fs.mkdirSync(importCache, {recursive: true});
  fs.symlinkSync(importCache, path.join(project, '.godot'));
  env.GODOT_TEST_IMPORT_CACHE = importCache;
  env.GODOT_TEST_IMPORT_PROJECT = sourceProject;
  const nonce = randomUUID();
  env.GODOT_NATIVE_TEST_NONCE = nonce;
  fs.writeFileSync(path.join(root, '.native-test-fixture.json'), JSON.stringify({
    schema: 'native-macos-test-v1', nonce, user_data_dir: userData, mirror_project: project
  }));
  // Existing lake guards compare the fixture parent with the declared temp root.
  env.TMPDIR = storageBase; env.TEMP = storageBase; env.TMP = storageBase;
  return {root, userData, env, project};
}
