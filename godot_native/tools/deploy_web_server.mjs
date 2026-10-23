#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import crypto from 'node:crypto';
import { spawn, spawnSync } from 'node:child_process';

// Deploy an already accepted standalone Godot artifact. No build, package
// installation, sudo, SSH authorization change, nginx reload or release pruning.
const options = new Map();
for (let i = 2; i < process.argv.length; i++) {
  const arg = process.argv[i];
  if (!arg.startsWith('--')) throw new Error(`Unexpected argument: ${arg}`);
  const at = arg.indexOf('=');
  const key = at < 0 ? arg.slice(2) : arg.slice(2, at);
  if (options.has(key)) throw new Error(`Duplicate option: --${key}`);
  const value = at < 0 ? (process.argv[i + 1]?.startsWith('--') || !process.argv[i + 1] ? true : process.argv[++i]) : arg.slice(at + 1);
  options.set(key, value);
}
const allowed = ['artifact', 'host', 'remote-root', 'identity', 'port', 'dry-run', 'preflight', 'deploy', 'rollback', 'help'];
for (const key of options.keys()) if (!allowed.includes(key)) throw new Error(`Unknown option: --${key}`);
if (options.has('help') || !options.size) {
  console.log(`Usage:
  node godot_native/tools/deploy_web_server.mjs --artifact DIR --dry-run
  node godot_native/tools/deploy_web_server.mjs --artifact DIR --preflight
  node godot_native/tools/deploy_web_server.mjs --artifact DIR --deploy
  node godot_native/tools/deploy_web_server.mjs --rollback RELEASE --dry-run|--preflight|--deploy
Options: --host zhuhangcheng@10.70.223.113 --remote-root /srv/755/7-55
         --identity /absolute/existing/key --port 22
Dry-run hashes all local files and prints a plan; it does not contact the server.
Preflight uses read-only SSH. Deploy refuses an unprepared or foreign root and
requires an exactly matching, readable nginx -T configuration. No passwords.`);
  process.exit(0);
}
const modeFlags = ['dry-run', 'preflight', 'deploy'].filter(key => options.has(key));
if (modeFlags.length !== 1 || options.get(modeFlags[0]) !== true) throw new Error('Choose exactly one of --dry-run, --preflight, --deploy');
const mode = modeFlags[0];
const target = String(options.get('host') || 'zhuhangcheng@10.70.223.113');
if (!/^(?:[a-zA-Z0-9_.-]+@)?[a-zA-Z0-9_.-]+$/.test(target) || target.startsWith('-')) throw new Error('Use a plain SSH alias or user@host');
const remoteRoot = String(options.get('remote-root') || '/srv/755/7-55');
if (!/^\/(?:[A-Za-z0-9_.-]+\/)+7-55$/.test(remoteRoot) || path.posix.normalize(remoteRoot) !== remoteRoot || /^\/(?:etc|usr|bin|sbin|boot|dev|proc|sys|run)(?:\/|$)/.test(remoteRoot)) throw new Error('remote-root must be a dedicated normalized absolute path ending /7-55, outside system configuration');
const releasePattern = /^[0-9a-f]{12}-[0-9a-f]{16}$/;
const rollback = options.get('rollback');
if (rollback && (typeof rollback !== 'string' || !releasePattern.test(rollback))) throw new Error('Rollback requires an exact release ID printed by this tool');
if (rollback && options.has('artifact')) throw new Error('Rollback does not take --artifact');
const sha = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
async function fileSha(filename) { const h = crypto.createHash('sha256'); for await (const chunk of fs.createReadStream(filename)) h.update(chunk); return h.digest('hex'); }
const safeName = name => typeof name === 'string' && /^[A-Za-z0-9_.\/-]+$/.test(name) && !name.startsWith('/') && name.split('/').every(part => part && part !== '.' && part !== '..');
function walk(directory, prefix = '') {
  return fs.readdirSync(directory, { withFileTypes: true }).sort((a, b) => a.name.localeCompare(b.name, 'en')).flatMap(entry => {
    const name = `${prefix}${entry.name}`;
    if (!safeName(name)) throw new Error(`Unsupported export filename: ${name}`);
    const filename = path.join(directory, entry.name);
    if (entry.isSymbolicLink()) throw new Error(`Export symlink refused: ${name}`);
    if (entry.isDirectory()) return walk(filename, `${name}/`);
    if (!entry.isFile()) throw new Error(`Non-regular export file refused: ${name}`);
    return [{ path: name, filename, bytes: fs.statSync(filename).size }];
  });
}
let artifact, manifest, inventory, artifactDigest, releaseId, contentSummary;
if (!rollback) {
  if (typeof options.get('artifact') !== 'string') throw new Error('Supply --artifact with an already built and accepted export');
  artifact = path.resolve(options.get('artifact'));
  if (fs.lstatSync(artifact).isSymbolicLink() || !fs.statSync(artifact).isDirectory()) throw new Error('Artifact directory must be a real directory, not a symlink');
  artifact = fs.realpathSync(artifact); // macOS /tmp itself resolves to /private/tmp.
  const all = walk(artifact);
  const manifestFile = all.find(file => file.path === 'build-manifest.json');
  if (!manifestFile) throw new Error('Missing build-manifest.json');
  manifest = JSON.parse(fs.readFileSync(manifestFile.filename, 'utf8'));
  if (manifest.runtime !== 'godot-web' || manifest.engine !== '4.7.1.stable.official' || manifest.pack?.engine !== '4.7.1' || manifest.production !== true || manifest.chapterShortcuts !== false || manifest.threads !== false || !/^[0-9a-f]{40}$/.test(manifest.sourceCommit || '') || !Array.isArray(manifest.files) || manifest.files.length < 3) throw new Error('Manifest is not an independent production Godot Web export');
  if (mode === 'deploy' && manifest.sourceDirty !== false) throw new Error('Deploy requires a clean sourceCommit build; dry-run can inspect a dirty candidate without publishing it');
  const records = new Map();
  for (const file of manifest.files) {
    if (!safeName(file.path) || !Number.isSafeInteger(file.bytes) || file.bytes < 0 || !/^[0-9a-f]{64}$/.test(file.sha256 || '') || records.has(file.path)) throw new Error(`Invalid/duplicate build-manifest entry: ${file.path}`);
    records.set(file.path, file);
  }
  const metadata = new Set(['build-manifest.json', 'source-inputs.json', 'pack-inventory.json', '.nojekyll', 'content-manifest.json', 'content-inventory.json']);
  inventory = [];
  for (const file of all) {
    const recorded = records.get(file.path);
    if (!recorded && !metadata.has(file.path)) throw new Error(`Unmanifested export file: ${file.path}`);
    const digest = await fileSha(file.filename);
    if (recorded && (recorded.bytes !== file.bytes || recorded.sha256 !== digest)) throw new Error(`Artifact SHA/size mismatch: ${file.path}`);
    inventory.push({ path: file.path, bytes: file.bytes, sha256: digest });
    records.delete(file.path);
  }
  if (records.size) throw new Error(`Manifest file missing: ${[...records.keys()].join(', ')}`);
  for (const required of ['index.html', 'index.js', 'index.wasm']) if (!inventory.some(file => file.path === required)) throw new Error(`Missing engine resource: ${required}`);
  const html = fs.readFileSync(path.join(artifact, 'index.html'), 'utf8');
  if (!html.includes('name="seven55-runtime" content="godot-web"') || !html.includes('new Engine(') || /<iframe\b|react-dom|phaser|@vite/.test(html)) throw new Error('Entry is not the standalone Godot HTML shell');
  const contentFile = path.join(artifact, 'content-manifest.json');
  if (fs.existsSync(contentFile)) {
    const content = JSON.parse(fs.readFileSync(contentFile, 'utf8'));
    const coverage = JSON.parse(fs.readFileSync(path.join(artifact, 'content-inventory.json'), 'utf8'));
    if (manifest.delivery !== 'chapter-content-packs' || content.schema !== '755-web-content-v1' || content.engine !== '4.7.1' || coverage.schema !== '755-web-content-inventory-v1' || content.core?.file !== 'index.pck' || !Array.isArray(content.packs) || !content.packs.length || !Array.isArray(coverage.groups) || !Array.isArray(coverage.entries) || coverage.full?.engine !== '4.7.1' || coverage.full.count !== coverage.entries.length || manifest.content?.exactCoverage !== true) throw new Error('Incomplete chapter content delivery manifest/coverage proof');
    if (new Set(coverage.entries.map(entry => entry.path)).size !== coverage.entries.length) throw new Error('Duplicate complete-export resource in content inventory');
    const packs = [content.core, ...content.packs];
    for (const pack of content.packs) if (!/^[a-z][a-z0-9_-]{0,63}$/.test(pack.id || '') || pack.file !== `content/${pack.id}-${String(pack.sha256).slice(0, 16)}.pck` || !Number.isSafeInteger(pack.bytes) || pack.bytes < 1 || pack.bytes > 24_000_000) throw new Error('Deferred pack must have its declared content hash in its immutable filename and stay within the 24 MB budget');
    if (new Set(packs.map(pack => pack.file)).size !== packs.length || coverage.groups.length !== packs.length) throw new Error('Duplicate or omitted chapter pack');
    for (const pack of packs) {
      const actual = inventory.find(file => file.path === pack.file);
      const group = coverage.groups.find(item => item.file === pack.file);
      if (!actual || actual.bytes !== pack.bytes || actual.sha256 !== pack.sha256 || !group || group.bytes !== pack.bytes || group.sha256 !== pack.sha256) throw new Error(`Chapter pack differs from delivery manifest/inventory: ${pack.file}`);
    }
    const actualPacks = inventory.filter(file => file.path.endsWith('.pck')).map(file => file.path).sort();
    if (JSON.stringify(actualPacks) !== JSON.stringify(packs.map(pack => pack.file).sort())) throw new Error('Unlisted/full intermediate PCK leaked into server artifact');
    if (!inventory.some(file => file.path === 'content-loader.js')) throw new Error('Chapter content loader is missing');
    contentSummary = { delivery: manifest.delivery, deferredPacks: content.packs.length, coreBytes: content.core.bytes, deferredBytes: content.packs.reduce((sum, pack) => sum + pack.bytes, 0), fullResourceCount: coverage.full.count };
  } else {
    if (mode === 'deploy') throw new Error('Server deployment requires chapter-content-packs, content-manifest.json and complete coverage proof; do not redeploy the old full PCK');
    contentSummary = { delivery: 'monolithic-inspection-only', deploymentAllowed: false };
  }
  artifactDigest = sha(JSON.stringify(inventory));
  releaseId = `${manifest.sourceCommit.slice(0, 12)}-${artifactDigest.slice(0, 16)}`;
} else releaseId = rollback;
const example = fs.readFileSync(path.resolve(import.meta.dirname, '../deploy/nginx-755.conf.example'), 'utf8');
const nginx = example.replaceAll('@@REMOTE_ROOT@@', remoteRoot).replaceAll('@@ROOT_PARENT@@', path.posix.dirname(remoteRoot));
const plan = {
  schema: '7-55-server-delivery-plan/v1', mode, target, remoteRoot, releaseId,
  action: rollback ? 'verify retained release then atomically switch current' : 'upload isolated staging, verify all SHA-256, retain immutable release, atomically switch current',
  ...(manifest ? { artifact, sourceCommit: manifest.sourceCommit, sourceDirty: manifest.sourceDirty, artifactDigest, localFilesVerified: inventory.length, totalBytes: inventory.reduce((sum, file) => sum + file.bytes, 0), ...contentSummary } : {}),
  entryPath: '/7-55/', immutablePath: `/7-55/releases/${releaseId}/`,
  remoteRelease: `${remoteRoot}/releases/${releaseId}`,
  preserves: ['existing root website', 'all older complete release/chapter directories', 'SSH permissions, firewall and packages'],
  nginxConfigurationInstalledByThisTool: false,
  nginxConfiguration: nginx,
};
if (mode === 'dry-run') { console.log(JSON.stringify(plan, null, 2)); process.exit(0); }

const remoteProgram = String.raw`
import base64, datetime, hashlib, json, os, pathlib, re, shutil, stat, subprocess, sys, tarfile, time, uuid
p=json.loads(base64.b64decode(sys.argv[1]))
base=pathlib.Path(p['remoteRoot'])
rid=p['releaseId']
def fail(message): raise RuntimeError(message)
def digest_file(filename):
 h=hashlib.sha256()
 with open(filename,'rb') as f:
  for part in iter(lambda:f.read(1024*1024),b''): h.update(part)
 return h.hexdigest()
def sync_directory(directory):
 fd=os.open(directory,os.O_RDONLY)
 try: os.fsync(fd)
 finally: os.close(fd)
def current_release():
 link=base/'current'
 if not link.exists() and not link.is_symlink(): return None
 if not link.is_symlink(): fail('current exists and is not this tool\'s symlink')
 value=os.readlink(link)
 if not re.fullmatch(r'releases/[0-9a-f]{12}-[0-9a-f]{16}',value): fail('current points outside the immutable release layout')
 if link.resolve().parent != (base/'releases').resolve(): fail('current escaped the release root')
 if not link.resolve().is_dir(): fail('current points to a missing retained release')
 return value.split('/')[1]
def preflight():
 blockers=[]
 exists=base.is_dir() and not base.is_symlink()
 if not exists: blockers.append('Exact remote-root must already exist as a real directory owned by the SSH user')
 elif str(base.resolve()) != str(base) or base.stat().st_uid != os.getuid() or not os.access(base,os.W_OK|os.X_OK): blockers.append('Exact remote-root must be canonical, owned and writable by the SSH user')
 elif base.stat().st_mode & (stat.S_IWGRP|stat.S_IWOTH): blockers.append('Delivery root must not be writable by unrelated group/other users')
 parent=base if exists else next((x for x in base.parents if x.exists()),pathlib.Path('/'))
 disk=shutil.disk_usage(parent)
 traversal=[]
 for directory in [base,*base.parents]:
  if directory.exists() and not directory.stat().st_mode & stat.S_IXOTH: traversal.append(str(directory))
 if traversal: blockers.append('Nginx static path needs readable/traversable directories; no permissions are changed: '+', '.join(traversal))
 executable=shutil.which('nginx') or next((x for x in ['/usr/sbin/nginx','/usr/local/sbin/nginx'] if os.path.isfile(x)),None)
 nginx={'executable':executable,'testReadable':False,'isolatedConfigurationMatches':False}
 if executable:
  test=subprocess.run([executable,'-T'],capture_output=True,text=True,timeout=20)
  # Do not echo nginx configuration: it can contain unrelated application secrets.
  nginx['testReadable']=test.returncode==0
  nginx['isolatedConfigurationMatches']=p['nginxConfiguration'].strip() in test.stdout
  nginx['conflictingServerWarning']='conflicting server name' in test.stderr
  if not nginx['testReadable']: blockers.append('nginx -T must succeed read-only as this user before deploy; ask the administrator to prepare the isolated snippet')
  if not nginx['isolatedConfigurationMatches']: blockers.append('nginx -T does not contain the exact rendered isolated /7-55/ configuration; current route ownership is unproven')
  if nginx['conflictingServerWarning']: blockers.append('nginx -T reports conflicting server names; resolve before selecting the delivery vhost')
 else: blockers.append('nginx is not installed/readable; this tool does not install packages')
 current=None
 if exists:
  allowed={'releases','current','.755-delivery-root.json','.755-deployments.jsonl','.755-deploy-lock','.staging'}
  foreign=sorted(x.name for x in base.iterdir() if x.name not in allowed)
  if foreign: blockers.append('remote-root contains foreign entries: '+', '.join(foreign))
  for name in ['releases','.staging']:
   folder=base/name
   if folder.exists() and (folder.is_symlink() or not folder.is_dir() or folder.stat().st_uid != os.getuid()): blockers.append(name+' is not an owned real directory')
   elif folder.exists() and folder.stat().st_mode & (stat.S_IWGRP|stat.S_IWOTH): blockers.append(name+' is writable by group/other users')
   elif folder.exists() and folder.stat().st_dev != base.stat().st_dev: blockers.append(name+' must share the delivery root filesystem for atomic rename')
  marker=base/'.755-delivery-root.json'
  if marker.exists():
   try:
    data=json.loads(marker.read_text())
    if data.get('schema')!='7-55-server-root/v1' or data.get('remoteRoot')!=str(base): blockers.append('Existing ownership marker does not match this delivery root')
   except Exception: blockers.append('Existing ownership marker is not valid JSON')
  elif any((base/name).exists() for name in ['releases','current','.staging']): blockers.append('Existing deployment directories lack this tool\'s root ownership marker')
  try: current=current_release()
  except Exception as exc: blockers.append(str(exc))
 if p.get('totalBytes') and disk.free < p['totalBytes']+64*1024*1024: blockers.append('Insufficient free disk for an independent staged release plus 64 MiB headroom')
 return {'ready':not blockers,'blockers':blockers,'host':{'user':os.environ.get('USER'),'uid':os.getuid(),'cpuCount':os.cpu_count(),'memoryBytes':os.sysconf('SC_PAGE_SIZE')*os.sysconf('SC_PHYS_PAGES')},'disk':{'path':str(parent),'totalBytes':disk.total,'freeBytes':disk.free},'remoteRoot':str(base),'currentRelease':current,'nginx':nginx}
def verify_release(folder):
 receipt_path=folder/'.755-release.json'
 if not folder.is_dir() or folder.is_symlink() or not receipt_path.is_file() or receipt_path.is_symlink(): fail('Retained release is not a regular verified release')
 receipt=json.loads(receipt_path.read_text())
 if receipt.get('schema')!='7-55-server-release/v1' or receipt.get('releaseId')!=rid: fail('Retained release receipt/ID mismatch')
 files=receipt.get('files',[])
 if hashlib.sha256(json.dumps(files,separators=(',',':'),ensure_ascii=False).encode()).hexdigest()!=receipt.get('artifactDigest'): fail('Retained release inventory digest mismatch')
 if rid != receipt['sourceCommit'][:12]+'-'+receipt['artifactDigest'][:16]: fail('Retained release ID does not bind its full artifact inventory')
 required={x['path'] for x in files}|{'.755-entry.html','.755-release.json','SHA256SUMS'}
 actual=set()
 for directory,dirs,names in os.walk(folder,followlinks=False):
  for name in dirs:
   if (pathlib.Path(directory)/name).is_symlink(): fail('Retained release directory symlink')
  for name in names:
   file=pathlib.Path(directory)/name
   if file.is_symlink() or not file.is_file(): fail('Retained release contains a non-regular file')
   actual.add(str(file.relative_to(folder)))
 if actual!=required: fail('Retained release missing/extra files')
 for entry in files:
  if not re.fullmatch(r'[A-Za-z0-9_./-]+',entry['path']) or any(x in ('','..','.') for x in entry['path'].split('/')): fail('Unsafe retained inventory path')
  file=folder/entry['path']
  if file.stat().st_size!=entry['bytes'] or digest_file(file)!=entry['sha256']: fail('Retained file SHA mismatch: '+entry['path'])
 if (folder/'SHA256SUMS').read_text()!=''.join(x['sha256']+'  '+x['path']+'\n' for x in files): fail('Retained SHA256SUMS does not match the bound inventory')
 expected_entry='<!doctype html>\n<meta charset="utf-8">\n<meta http-equiv="refresh" content="0;url=/7-55/releases/'+rid+'/">\n<title>7:55</title>\n<script>location.replace("/7-55/releases/'+rid+'/")</script>\n<a href="/7-55/releases/'+rid+'/">打开 7:55</a>\n'
 if (folder/'.755-entry.html').read_text()!=expected_entry: fail('Retained entry redirect is not bound to this release')
 return receipt
result=preflight()
if p['action']=='preflight':
 print(json.dumps(result,ensure_ascii=False));sys.exit(0 if result['ready'] else 2)
if not result['ready']: fail('Deployment preflight refused: '+'; '.join(result['blockers']))
lock=base/'.755-deploy-lock'
try: lock.mkdir(mode=0o700)
except FileExistsError: fail('Another deployment lock exists; inspect it manually, never auto-break it')
stage=None
try:
 (lock/'owner.json').write_text(json.dumps({'id':str(uuid.uuid4()),'pid':os.getpid(),'startedAt':time.time()}))
 previous=current_release()
 release=base/'releases'/rid
 if p['action']=='upload':
  marker=base/'.755-delivery-root.json'
  if not marker.exists(): marker.write_text(json.dumps({'schema':'7-55-server-root/v1','remoteRoot':str(base)})+'\n');os.chmod(marker,0o644)
  stage=base/'.staging'/(rid+'-'+str(uuid.uuid4()))
  stage.mkdir(parents=True,mode=0o755)
  expected={x['path']:x for x in p['uploadFiles']}
  seen=set()
  with tarfile.open(fileobj=sys.stdin.buffer,mode='r|') as archive:
   for member in archive:
    name=member.name.removeprefix('./')
    if member.isdir():
     if name in ('','.'): continue
     if not re.fullmatch(r'[A-Za-z0-9_./-]+',name.rstrip('/')) or any(x in ('','..','.') for x in name.rstrip('/').split('/')): fail('Unsafe archive directory')
     continue
    if not member.isfile() or name not in expected or name in seen: fail('Unexpected, duplicate or non-regular archive member: '+name)
    entry=expected[name]
    if member.size!=entry['bytes']: fail('Archive size mismatch: '+name)
    destination=stage/name;destination.parent.mkdir(parents=True,exist_ok=True,mode=0o755)
    h=hashlib.sha256()
    with archive.extractfile(member) as source,open(destination,'xb') as output:
     for chunk in iter(lambda:source.read(1024*1024),b''): h.update(chunk);output.write(chunk)
     output.flush();os.fsync(output.fileno())
    os.chmod(destination,0o644)
    if h.hexdigest()!=entry['sha256']: fail('Uploaded SHA mismatch: '+name)
    seen.add(name)
  if seen!=set(expected): fail('Uploaded archive omitted manifest files')
  verify_release(stage)
  for directory,dirs,names in os.walk(stage,topdown=False): sync_directory(directory)
  (base/'releases').mkdir(exist_ok=True,mode=0o755)
  if release.exists():
   retained=verify_release(release)
   if retained['artifactDigest']!=p['artifactDigest']: fail('Release ID collision; retained release is never overwritten')
   shutil.rmtree(stage);stage=None
  else:
   os.rename(stage,release);stage=None
   sync_directory(base/'.staging');sync_directory(base/'releases')
 else: verify_release(release)
 # Both directory rename and symlink replacement remain on the same filesystem.
 temporary=base/('.current-'+str(uuid.uuid4()))
 os.symlink('releases/'+rid,temporary);os.replace(temporary,base/'current')
 sync_directory(base)
 record={'schema':'7-55-server-activation/v1','releaseId':rid,'previousRelease':previous,'action':p['action'],'activatedAt':datetime.datetime.now(datetime.timezone.utc).isoformat(),'entryPath':'/7-55/','immutablePath':'/7-55/releases/'+rid+'/'}
 with open(base/'.755-deployments.jsonl','a') as journal: journal.write(json.dumps(record)+'\n');journal.flush();os.fsync(journal.fileno())
 print(json.dumps({'activated':True,'record':record,'retainedAllOlderReleases':True,'nginxChanged':False},ensure_ascii=False))
finally:
 if stage is not None and stage.exists(): shutil.rmtree(stage)
 shutil.rmtree(lock)
`;
const shellQuote = value => `'${String(value).replaceAll("'", "'\\''")}'`;
const sshArgs = ['-o', 'BatchMode=yes', '-o', 'StrictHostKeyChecking=yes', '-o', 'ConnectTimeout=10', '-o', 'ConnectionAttempts=1'];
if (options.has('port')) { const port = Number(options.get('port')); if (!Number.isInteger(port) || port < 1 || port > 65535) throw new Error('Invalid SSH port'); sshArgs.push('-p', String(port)); }
if (options.has('identity')) {
  const identity = options.get('identity');
  if (typeof identity !== 'string' || !path.isAbsolute(identity) || !fs.statSync(identity).isFile()) throw new Error('identity must be an absolute path to an existing file');
  sshArgs.push('-i', identity, '-o', 'IdentitiesOnly=yes');
}
function remoteCommand(payload) { return `python3 -c ${shellQuote(remoteProgram)} ${shellQuote(Buffer.from(JSON.stringify(payload)).toString('base64'))}`; }
const common = { remoteRoot, releaseId, nginxConfiguration: nginx, totalBytes: plan.totalBytes || 0 };
const preflight = spawnSync('ssh', [...sshArgs, target, remoteCommand({ ...common, action: 'preflight' })], { encoding: 'utf8', maxBuffer: 4 * 1024 * 1024 });
if (preflight.stdout) console.log(preflight.stdout.trim());
if (preflight.stderr) process.stderr.write(preflight.stderr);
if (preflight.error || preflight.status !== 0) { console.error('Read-only preflight did not pass. No upload, configuration or permission changes were attempted.'); process.exit(preflight.status || 1); }
if (mode === 'preflight') process.exit(0);
if (rollback) {
  const result = spawnSync('ssh', [...sshArgs, target, remoteCommand({ ...common, action: 'rollback' })], { encoding: 'utf8', maxBuffer: 4 * 1024 * 1024 });
  if (result.stdout) console.log(result.stdout.trim());
  if (result.stderr) process.stderr.write(result.stderr);
  if (result.error || result.status !== 0) process.exit(result.status || 1);
} else {
  const temporary = fs.mkdtempSync(path.join(os.tmpdir(), '755-server-delivery-'));
  try {
    const entry = `<!doctype html>\n<meta charset="utf-8">\n<meta http-equiv="refresh" content="0;url=/7-55/releases/${releaseId}/">\n<title>7:55</title>\n<script>location.replace("/7-55/releases/${releaseId}/")</script>\n<a href="/7-55/releases/${releaseId}/">打开 7:55</a>\n`;
    const receipt = { schema: '7-55-server-release/v1', releaseId, sourceCommit: manifest.sourceCommit, artifactDigest, files: inventory };
    fs.writeFileSync(path.join(temporary, '.755-entry.html'), entry);
    fs.writeFileSync(path.join(temporary, '.755-release.json'), `${JSON.stringify(receipt, null, 2)}\n`);
    fs.writeFileSync(path.join(temporary, 'SHA256SUMS'), inventory.map(file => `${file.sha256}  ${file.path}\n`).join(''));
    const generated = await Promise.all(walk(temporary).map(async file => ({ path: file.path, bytes: file.bytes, sha256: await fileSha(file.filename) })));
    const ssh = spawn('ssh', [...sshArgs, target, remoteCommand({ ...common, action: 'upload', artifactDigest, uploadFiles: [...inventory, ...generated] })], { stdio: ['pipe', 'pipe', 'inherit'] });
    const tar = spawn('tar', ['-cf', '-', '-C', artifact, '.', '-C', temporary, '.755-entry.html', '.755-release.json', 'SHA256SUMS'], { stdio: ['ignore', 'pipe', 'inherit'], env: { ...process.env, COPYFILE_DISABLE: '1' } });
    tar.stdout.pipe(ssh.stdin);
    ssh.stdout.pipe(process.stdout);
    // Remote refusal may close stdin before tar completes. Report process status,
    // not an unhandled EPIPE; no partial stage becomes current.
    const stopArchive = () => { tar.stdout.unpipe(ssh.stdin); tar.stdout.destroy(); if (tar.exitCode === null) tar.kill('SIGTERM'); };
    ssh.stdin.on('error', error => { if (error.code !== 'EPIPE') console.error(error.message); stopArchive(); });
    ssh.once('close', code => { if (code !== 0) stopArchive(); });
    const status = child => new Promise((resolve, reject) => { child.once('error', reject); child.once('close', code => resolve(code)); });
    let tarStatus, sshStatus;
    try { [tarStatus, sshStatus] = await Promise.all([status(tar), status(ssh)]); }
    catch (error) { stopArchive(); ssh.kill('SIGTERM'); throw error; }
    if (tarStatus !== 0 || sshStatus !== 0) throw new Error(`Upload failed (tar=${tarStatus}, ssh=${sshStatus}); inspect the retained current release before retrying`);
  } finally { fs.rmSync(temporary, { recursive: true, force: true }); }
}
