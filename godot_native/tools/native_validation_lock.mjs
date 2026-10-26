import fs from 'node:fs';
import path from 'node:path';
export function acquireNativeWorkspaceLock(project, purpose) {
 const lock = path.join(project, '.validation/runner.lock');
 fs.mkdirSync(path.dirname(lock), {recursive: true});
 try {fs.mkdirSync(lock);} catch (error) {
  if (error.code !== 'EEXIST') throw error;
  throw Error(`Native workspace is busy: ${lock}. Do not share res:// or .godot during preparation/validation. If abandoned, verify its owner is stopped before removing the lock.`);
 }
 fs.writeFileSync(path.join(lock, 'owner.json'), JSON.stringify({pid: process.pid, purpose, startedAt: new Date().toISOString()}));
 const cleanup = () => fs.rmSync(lock, {recursive: true, force: true});
 process.once('exit', cleanup);
 return () => {cleanup(); process.removeListener('exit', cleanup);};
}
