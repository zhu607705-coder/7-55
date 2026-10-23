import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import zlib from 'node:zlib';

const schema = '755-http-gzip-v1';
const excluded = new Set(['build-manifest.json', 'source-inputs.json', 'pack-inventory.json']);
const hash = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const eligible = file => !excluded.has(file) && /\.(?:wasm|pck|js|json)$/.test(file) || /^(?:boot|content\/chunks)\/[^/]+\.bin$/.test(file);
function walk(root, directory = root) {
  return fs.readdirSync(directory, {withFileTypes:true}).sort((a,b)=>a.name.localeCompare(b.name)).flatMap(entry => {
    const full = path.join(directory,entry.name);
    if(entry.isSymbolicLink()) throw Error('Compression rejects symlink: '+full);
    if(entry.isDirectory()) return walk(root,full);
    if(!entry.isFile()) throw Error('Compression rejects non-file: '+full);
    return [path.relative(root,full).split(path.sep).join('/')];
  });
}
function safe(root, file) {
  if(typeof file!=='string'||!file||file.startsWith('/')||/[\\?#\x00-\x1f]/.test(file)||file.split('/').some(x=>!x||x==='.'||x==='..')) throw Error('Invalid compression path');
  const full=path.resolve(root,file), real=fs.realpathSync(full);
  if(!real.startsWith(root+path.sep)||real!==full||!fs.lstatSync(full).isFile()) throw Error('Compression file escaped root');
  return full;
}
function receipt(files) {
  return {schema,encoding:'gzip',level:6,minSavingsBytes:4096,minSavingsRatio:0.1,files,
    bytes:files.reduce((sum,f)=>sum+f.bytes,0),sourceBytes:files.reduce((sum,f)=>sum+f.sourceBytes,0),
    savedBytes:files.reduce((sum,f)=>sum+f.sourceBytes-f.bytes,0)};
}
export function prepareWebCompression(directory) {
  const root=fs.realpathSync(directory), candidates=walk(root);
  if(candidates.some(file=>file.endsWith('.gz'))) throw Error('Compression output already exists; use a fresh export');
  const files=[];
  for(const source of candidates.filter(eligible)) {
    const input=fs.readFileSync(safe(root,source));
    if(input.length<8192) continue;
    const compressed=zlib.gzipSync(input,{level:6});
    if(input.length-compressed.length<4096||compressed.length>input.length*0.9) continue;
    const file=source+'.gz';
    fs.writeFileSync(path.join(root,file),compressed,{flag:'wx'});
    files.push({source,file,sourceBytes:input.length,sourceSha256:hash(input),bytes:compressed.length,sha256:hash(compressed)});
  }
  return receipt(files);
}
export function verifyWebCompression(directory, expected) {
  const root=fs.realpathSync(directory), actualFiles=walk(root).filter(file=>file.endsWith('.gz')).sort();
  if(expected==null) {
    if(actualFiles.length) throw Error('Unregistered gzip files');
    return null;
  }
  if(expected.schema!==schema||expected.encoding!=='gzip'||!Array.isArray(expected.files)||expected.files.length>2000) throw Error('Invalid compression receipt');
  const seen=new Set();
  for(const file of expected.files) {
    if(!eligible(file.source)||file.file!==file.source+'.gz'||seen.has(file.source)||!Number.isSafeInteger(file.sourceBytes)||file.sourceBytes<8192||!Number.isSafeInteger(file.bytes)||file.bytes<1||!/^[a-f0-9]{64}$/.test(file.sourceSha256)||!/^[a-f0-9]{64}$/.test(file.sha256)) throw Error('Invalid compressed file identity');
    seen.add(file.source);
    const input=fs.readFileSync(safe(root,file.source)), compressed=fs.readFileSync(safe(root,file.file));
    if(input.length!==file.sourceBytes||hash(input)!==file.sourceSha256||compressed.length!==file.bytes||hash(compressed)!==file.sha256) throw Error('Compressed file differs from receipt: '+file.source);
    if(input.length-compressed.length<4096||compressed.length>input.length*0.9) throw Error('Compression does not meet savings policy');
    const restored=zlib.gunzipSync(compressed,{maxOutputLength:file.sourceBytes});
    if(!restored.equals(input)) throw Error('Compressed payload does not restore its original: '+file.source);
  }
  if(JSON.stringify(actualFiles)!==JSON.stringify(expected.files.map(file=>file.file).sort())) throw Error('Missing or unexpected gzip file');
  const canonical=receipt(expected.files);
  if(JSON.stringify(canonical)!==JSON.stringify(expected)) throw Error('Compression totals or policy differ');
  return canonical;
}
