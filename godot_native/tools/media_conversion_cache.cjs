// Derived bytes only: a cache hit never replaces fresh full-stream validation.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const {spawnSync} = require('node:child_process');
const hash = value => crypto.createHash('sha256').update(value).digest('hex');
const fileHash = file => hash(fs.readFileSync(file));
function toolIdentity(command) {
  const candidates = command.includes(path.sep) ? [path.resolve(command)] : (process.env.PATH || '').split(path.delimiter).map(dir => path.join(dir, command));
  const executable = candidates.find(file => {try {fs.accessSync(file,fs.constants.X_OK);return fs.statSync(file).isFile();} catch {return false;}});
  if (!executable) throw Error(`Missing media tool: ${command}`);
  const result = spawnSync(executable,['-version'],{encoding:'utf8',timeout:30000,maxBuffer:1024*1024});
  if (result.status !== 0 || result.error) throw Error(`Cannot identify media tool: ${command}`);
  return {sha256:fileHash(executable),version:result.stdout.trim()};
}
function identity({sourceSha256,converterSha256,tools,maxBytes}) {
  return {schema:1,sourceSha256,converterSha256,helperSha256:fileHash(__filename),tools,maxBytes,
    platform:process.platform,arch:process.arch,config:{video:'libtheora',qualities:[8,7,6,5,4],audio:'libvorbis',audioQuality:5,map:['0:v:0','0:a?']}};
}
function location(root,expected) {
  if (!root) return null;
  if (!path.isAbsolute(root)) throw Error('MEDIA_CONVERSION_CACHE_DIR must be absolute');
  const dir=path.join(root,hash(JSON.stringify(expected)));
  return {dir,output:path.join(dir,'output.ogv'),receipt:path.join(dir,'receipt.json')};
}
function read(root,expected) {
  const files=location(root,expected);if(!files)return {hit:false,reason:'disabled'};
  try {
    for(const file of [root,files.dir])if(!fs.lstatSync(file).isDirectory()||fs.lstatSync(file).isSymbolicLink())throw Error('non-directory cache path');
    for(const file of [files.output,files.receipt])if(!fs.lstatSync(file).isFile()||fs.lstatSync(file).isSymbolicLink())throw Error('nonregular cache entry');
    const row=JSON.parse(fs.readFileSync(files.receipt,'utf8'));
    if(JSON.stringify(row.identity)!==JSON.stringify(expected))throw Error('identity mismatch');
    const bytes=fs.statSync(files.output).size;
    if(bytes!==row.bytes||bytes>expected.maxBytes||bytes<1||fileHash(files.output)!==row.outputSha256)throw Error('output bytes mismatch');
    if(!expected.config.qualities.includes(row.quality)||!Array.isArray(row.attempts)||!row.attempts.length)throw Error('invalid encoding receipt');
    return {hit:true,...files,...row};
  } catch(error) {return {hit:false,reason:error.code==='ENOENT'?'miss':`rejected: ${error.message}`};}
}
function write(root,expected,source,{quality,attempts}) {
  const files=location(root,expected);if(!files)return;
  fs.mkdirSync(root,{recursive:true});
  if(fs.lstatSync(root).isSymbolicLink())throw Error('Symlink media cache root');
  fs.mkdirSync(files.dir,{recursive:true});
  if(fs.lstatSync(files.dir).isSymbolicLink())throw Error('Symlink media cache entry');
  const stage=fs.mkdtempSync(path.join(files.dir,'.staged-'));
  try {
    const output=path.join(stage,'output.ogv');fs.copyFileSync(source,output);
    const receipt={identity:expected,quality,attempts,bytes:fs.statSync(output).size,outputSha256:fileHash(output)};
    if(receipt.bytes>expected.maxBytes)throw Error('Oversize cached media');
    fs.writeFileSync(path.join(stage,'receipt.json'),JSON.stringify(receipt)+'\n');
    fs.renameSync(output,files.output);fs.renameSync(path.join(stage,'receipt.json'),files.receipt);
  } finally {fs.rmSync(stage,{recursive:true,force:true});}
}
module.exports={identity,toolIdentity,read,write,fileHash};
