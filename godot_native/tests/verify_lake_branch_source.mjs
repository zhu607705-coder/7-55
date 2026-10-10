// Regenerate expectations from the active source, then test the native controller.
// Native persistence always uses a fresh /tmp home and never a player's save.
import {spawnSync} from 'node:child_process';
import {mkdtempSync,mkdirSync,rmSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {dirname,join,resolve} from 'node:path';
import {fileURLToPath} from 'node:url';
const root=resolve(dirname(fileURLToPath(import.meta.url)),'../..');
const sandbox=mkdtempSync(join(tmpdir(),'755-lake-source-parity-'));
try {
  for(const folder of ['home','data','config','cache','state'])mkdirSync(join(sandbox,folder));
  const env={...process.env,HOME:join(sandbox,'home'),XDG_DATA_HOME:join(sandbox,'data'),XDG_CONFIG_HOME:join(sandbox,'config'),XDG_CACHE_HOME:join(sandbox,'cache'),XDG_STATE_HOME:join(sandbox,'state'),GODOT_SILENCE_ROOT_WARNING:'1'};
  for(const [command,args] of [
    [process.execPath,['godot_native/tests/export_lake_branch_source_fixtures.mjs']],
    [process.env.GODOT_BIN||'godot',['--headless','--path','godot_native','--script','res://tests/test_qizhen_branches.gd','--','--fresh']]
  ]) {
    const result=spawnSync(command,args,{cwd:root,env,encoding:'utf8',timeout:120000,maxBuffer:8*1024*1024});
    const output=(result.stdout||'')+(result.stderr||'');process.stdout.write(output);
    if(result.error||result.status!==0||/(?:^|\n)ERROR:|SCRIPT ERROR:|Parse Error:/.test(output))throw new Error(`Lake source parity failed: ${result.error||result.status}`);
  }
} finally {rmSync(sandbox,{recursive:true,force:true});}
