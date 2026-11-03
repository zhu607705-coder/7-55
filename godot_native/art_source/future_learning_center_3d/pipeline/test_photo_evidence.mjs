/** Independent native, source, plain and actual Draco inspection. No visual/Web acceptance claim. */
import fs from 'node:fs/promises';import crypto from 'node:crypto';import path from 'node:path';import {execFileSync} from 'node:child_process';
import {NodeIO,getBounds} from '@gltf-transform/core';import {ALL_EXTENSIONS} from '@gltf-transform/extensions';import draco3d from 'draco3dgltf';
// --root and --outdir accept absolute or caller-relative paths; output never needs to touch the asset tree.
const option=name=>{const arg=process.argv.find(a=>a.startsWith('--'+name+'='));return arg?.slice(name.length+3);};
const requestedRoot=option('root'),requestedOut=option('outdir');
const explicitOutput=requestedOut?path.resolve(requestedOut):undefined;
if(requestedRoot)process.chdir(path.resolve(requestedRoot));
const outputRoot=explicitOutput??path.resolve('review/photo_evidence');
const baselineVersion=option('baseline-version')??'published';
if(!['recovered','published'].includes(baselineVersion))throw Error('Use --baseline-version=recovered or --baseline-version=published');
await fs.mkdir(outputRoot,{recursive:true});
const io=new NodeIO().registerExtensions(ALL_EXTENSIONS).registerDependencies({'draco3d.decoder':await draco3d.createDecoderModule()});
const sha=b=>crypto.createHash('sha256').update(b).digest('hex');const checks=[],assets=[],nativeByPath={};
const check=(ok,label,details)=>checks.push({pass:!!ok,label,...(details===undefined?{}:{details})});
const size=b=>b.max.map((x,i)=>x-b.min[i]);const tris=d=>d.getRoot().listMeshes().reduce((a,m)=>a+m.listPrimitives().reduce((v,p)=>v+(p.getIndices()?.getCount()??p.getAttribute('POSITION').getCount())/3,0),0);
const boundsError=(a,b)=>Math.max(...a.min.map((x,i)=>Math.abs(x-b.min[i])),...a.max.map((x,i)=>Math.abs(x-b.max[i])));
function geometry(d,label){let degenerate=0,finite=true,indexOK=true,normalOK=true;for(const m of d.getRoot().listMeshes())for(const p of m.listPrimitives()){
 check(p.getMode()===4,label+' triangle topology');const pos=p.getAttribute('POSITION'),a=pos.getArray(),n=p.getAttribute('NORMAL'),idx=p.getIndices()?.getArray()??Array.from({length:pos.getCount()},(_,i)=>i);
 finite&&=Array.from(a).every(Number.isFinite);indexOK&&=idx.length%3===0&&Array.from(idx).every(i=>Number.isInteger(i)&&i>=0&&i<pos.getCount());
 if(!n)normalOK=false;else {const na=n.getArray();for(let i=0;i<na.length;i+=3)normalOK&&=Number.isFinite(na[i])&&Math.abs(Math.hypot(na[i],na[i+1],na[i+2])-1)<.015;}
 for(let i=0;i<idx.length;i+=3){let [x,y,z]=[idx[i]*3,idx[i+1]*3,idx[i+2]*3],u=[0,1,2].map(k=>a[y+k]-a[x+k]),v=[0,1,2].map(k=>a[z+k]-a[x+k]);if(Math.hypot(u[1]*v[2]-u[2]*v[1],u[2]*v[0]-u[0]*v[2],u[0]*v[1]-u[1]*v[0])<1e-12)degenerate++;}
 }
 check(finite&&indexOK,label+' finite vertices and valid indices');check(normalOK,label+' finite unit normals');check(degenerate===0,label+' no zero area triangles',degenerate);
 check(d.getRoot().listMaterials().every(m=>[...m.getBaseColorFactor(),m.getMetallicFactor(),m.getRoughnessFactor()].every(v=>Number.isFinite(v)&&v>=0&&v<=1)),label+' bounded PBR factors');
 check(d.getRoot().listSkins().length===0&&d.getRoot().listAnimations().length===0,label+' static unrigged scope');
 return {triangles:tris(d),degenerate,materials:d.getRoot().listMaterials().length,textures:d.getRoot().listTextures().length};
}
async function native(file){if(nativeByPath[file])return nativeByPath[file];const b=await fs.readFile(file),out=path.join(outputRoot,`native_${path.basename(file,'.blend')}.json`);execFileSync('blender',['-b','-t','1',path.resolve(file),'--python',path.resolve('review/photo_evidence/inspect_native.py'),'--',out],{stdio:'pipe',maxBuffer:8e6,cwd:process.cwd(),env:{...process.env,PWD:process.cwd()}});check(sha(await fs.readFile(file))===sha(b),file+' read-only native inspection');const n=JSON.parse(await fs.readFile(out));check(n.objects.length>0&&n.objects.every(o=>o.finite),file+' native finite mesh geometry');nativeByPath[file]=n;return n;}
if(process.argv.includes('--compositions-only')){const r=await validateCompositions();process.exit(r.sourceHashFailures||r.contactOutliers||r.unresolvedIntersections?1:0);}
const groups={photo_instruments:6,photo_lab_contents:7,photo_bench_contents:7};
for(const [group,count] of Object.entries(groups)){
 const folder=`sources/models/${group}`,ids=(await fs.readdir(folder,{withFileTypes:true})).filter(e=>e.isDirectory()).map(e=>e.name).sort(),receipt=JSON.parse(await fs.readFile(`review/${group}/build_report.json`));check(ids.length===count,group+' expected distinct source count');
 for(const id of ids){const base=`${folder}/${id}`,run=`web/assets/models/${group}/${id}`,blend=await fs.readFile(`${base}/${id}.blend`),n=await native(`${base}/${id}.blend`),manifest=JSON.parse(await fs.readFile(run+'/manifest.json'));const row={id,group,blendSha256:sha(blend),levels:[]};
 check(manifest.encoding.positionBits===20,id+' 20-bit position encoding');check(Math.abs(manifest.calibration.uniformScale-1)<1e-7,id+' no hidden scale correction');
 for(let level=0;level<3;level++){
  const label=`${id} LOD${level}`,sb=await fs.readFile(`${base}/lod${level}_source.glb`),src=await io.readBinary(sb),sBounds=getBounds(src.getRoot().listScenes()[0]),r=receipt.records.filter(r=>r.asset===id&&r.level===level),m=manifest.levels[level];check(r.length===1,label+' unique author receipt');
  const actual=geometry(src,label+' source');check(m.inputSha256===sha(sb)&&r[0]?.sha256===sha(sb),label+' source hash provenance');check(actual.triangles===r[0]?.triangles,label+' actual source triangles match receipt');
  if(level===0){const nb={min:[n.bounds[0][0],n.bounds[0][2],-n.bounds[1][1]],max:[n.bounds[1][0],n.bounds[1][2],-n.bounds[0][1]]};check(boundsError(sBounds,nb)<1e-5,label+' native bounds match exported geometry');check(n.triangles===actual.triangles,label+' native topology matches exported triangles');}
  const pb=await fs.readFile(run+'/'+m.uncompressedFile),db=await fs.readFile(run+'/'+m.file),plain=await io.readBinary(pb),dec=await io.readBinary(db),jb=JSON.parse(db.subarray(20,20+db.readUInt32LE(12))),pBounds=getBounds(plain.getRoot().listScenes()[0]),dBounds=getBounds(dec.getRoot().listScenes()[0]);
  const pg=geometry(plain,label+' plain'),dg=geometry(dec,label+' Draco');check(jb.meshes.every(mesh=>mesh.primitives.every(p=>p.extensions?.KHR_draco_mesh_compression)),label+' actual Draco encoded primitives');check(![...(jb.buffers??[]),...(jb.images??[])].some(b=>b.uri&&!b.uri.startsWith('data:')),label+' self contained');check(m.sha256===sha(db)&&m.bytes===db.length,label+' runtime hash and bytes');check(pg.triangles===dg.triangles&&dg.triangles===m.triangles,label+' true decoded triangle count');
  const err=boundsError(pBounds,dBounds);check(err<.0001,label+' plain versus decoded envelope error under 0.1mm',err);check(size(sBounds).every((v,i)=>Math.abs(v-size(dBounds)[i])<.001),label+' source size preserved within 1mm');check(Math.abs(dBounds.min[1])<.001,label+' ground pivot within 1mm');
  row.levels.push({level,sourceTriangles:actual.triangles,plainTriangles:pg.triangles,decodedTriangles:dg.triangles,dracoBytes:db.length,plainBytes:pb.length,encodingErrorM:err,sizeM:size(dBounds),sourceSha256:sha(sb),dracoSha256:sha(db)});
 }
 check(row.levels[0].decodedTriangles>row.levels[1].decodedTriangles&&row.levels[1].decodedTriangles>row.levels[2].decodedTriangles,id+' decreasing actual LOD counts');assets.push(row);
 }
}
// Geometry contracts are checked against native mesh bounds, not only metadata.
const findNative=id=>Object.entries(nativeByPath).find(([p])=>p.endsWith('/'+id+'.blend'))?.[1];
const dp=findNative('photo_instrument_dp800_series_candidate');check(dp.bounds[1].map((x,i)=>x-dp.bounds[0][i]).every((v,i)=>Math.abs(v-[.239,.4295,.157][i])<.0002),'DP800 candidate official 239x157x418mm body; 429.5mm depth including protrusions',dp.bounds);
const drone=findNative('photo_quadrotor_unknown');if(drone){const motors=drone.objects.filter(o=>/Blue motor bell/.test(o.name));check(motors.length===4,'quadrotor has four actual motor meshes');const centers=motors.map(o=>o.bounds[0].map((v,i)=>(v+o.bounds[1][i])/2));check(new Set(centers.map(c=>c.slice(0,2).map(v=>v.toFixed(3)).join(','))).size===4,'quadrotor motor centers distinct');check(drone.objects.filter(o=>/landing skid/i.test(o.name)).length>=2,'quadrotor has two landing skid meshes');}
const pc=findNative('lab_open_pc_chassis');if(pc){const names=pc.objects.map(o=>o.name);check(names.some(n=>/Mainboard tray/i.test(n))&&names.filter(n=>/Corner chassis rail/i.test(n)).length===4&&names.some(n=>/Visible insulated harness/i.test(n)),'open PC has separate board tray four corner rails and internal harness meshes',names);}
if(pc){check(!pc.objects.some(o=>o.bounds[0][0]>.085&&(o.bounds[1][1]-o.bounds[0][1])>.30&&(o.bounds[1][2]-o.bounds[0][2])>.30),'open PC positive-X side is not closed by a full panel');}
const instrumentNative=Object.entries(nativeByPath).filter(([p])=>p.includes('/photo_instruments/')).map(([p,n])=>({path:p,n}));
check(new Set(instrumentNative.map(({n})=>JSON.stringify(n.objects.map(o=>({bounds:o.bounds,triangles:o.triangles}))))).size===6,'six instrument actual mesh layouts differ, not metadata-only variants');
for(const {path:p,n} of instrumentNative)check(n.objects.every(o=>/candidate|estimated|unknown|unconfirmed/i.test(o.properties.evidenceStatus??'')),p+' native evidence status is explicitly provisional');
const instruments=assets.filter(a=>a.group==='photo_instruments');check(new Set(instruments.map(a=>a.levels[0].sourceSha256)).size===6,'six instrument source files independently authored, DP800 intentionally reused twice');
// Pinned recovered and publication variants; one version is selected for the entire run.
// Changing either baseline and this pin is an explicit baseline change requiring review.
const baseline='fe75c9aa98abed4a69770e92c1f7a9be82db3a64',art='godot_native/art_source/future_learning_center_3d/';
const baselineManifestSha256='6a0da63c9847fb98e901699014c86dcad620ddb49434ed147eb0627624dbfb42';
const baselineBytes=await fs.readFile(new URL('./photo_preserved_baseline_v1.json',import.meta.url));
if(sha(baselineBytes)!==baselineManifestSha256)throw Error('Frozen baseline manifest SHA256 mismatch');
const frozen=JSON.parse(baselineBytes);
if(frozen.schema!==2||frozen.provenance.localRecoveryCommit!==baseline||frozen.fileCount!==570||frozen.files.length!==570)throw Error('Invalid frozen baseline provenance or file count');
const preserved=[],seen=new Set();
for(const entry of frozen.files){
 const p=entry.path,expected=baselineVersion==='recovered'?entry:entry.published;
 if(seen.has(p)||!(p.startsWith(art+'sources/models/')||p.startsWith(art+'web/assets/models/'))||p.split('/').includes('..')||!expected||!/^[a-f0-9]{64}$/.test(expected.sha256)||!Number.isSafeInteger(expected.bytes)||expected.bytes<0)throw Error('Invalid frozen baseline entry '+p);
 seen.add(p);const now=await fs.readFile(p.slice(art.length));
 check(now.length===expected.bytes&&sha(now)===expected.sha256,(baselineVersion==='recovered'?'restored baseline unchanged ':'exact published baseline variant ')+p);
 preserved.push({path:p,sha256:sha(now),bytes:now.length,version:baselineVersion,recoveredSha256:entry.sha256,changedFromRecovered:expected.sha256!==entry.sha256});
}
const failures=checks.filter(c=>!c.pass);const report={scope:'Actual source/plain/Draco and independent read-only native validation. Not visual approval, physical measurement confirmation, browser frame time, GPU performance, or functional electronics simulation.',baseline:{commit:baseline,meaning:'Local recovery provenance only; not an upstream ancestor or original 82abe Git object. No Git object access required',manifestSha256:baselineManifestSha256,version:baselineVersion,meaningOfComparison:baselineVersion==='recovered'?'Exact recovery bytes':'Exact approved metadata-sanitized publication bytes; not identical to recovery bytes',preservedFileCount:preserved.length,preserved},uniqueSourceCount:assets.length,levelsPerSource:3,totalUniqueRuntimeLod0Triangles:assets.reduce((v,a)=>v+a.levels[0].decodedTriangles,0),assets,checks:checks.length,failures:failures.length,failedChecks:failures,rows:checks};
await fs.writeFile(path.join(outputRoot,'validation.json'),JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify({assets:assets.length,checks:checks.length,failures,reportSha256:sha(await fs.readFile(path.join(outputRoot,'validation.json')))},null,2));if(failures.length)process.exitCode=1;

async function validateCompositions(){
 const layouts=[];for(const group of ['photo_lab_contents','photo_bench_contents']){
  const source=`sources/models/${group}/composition.json`,out=path.join(outputRoot,`${group}_composition_validation.json`);await fs.access(source);
  execFileSync('blender',['-b','-t','1','--python',path.resolve('review/photo_evidence/inspect_composition.py'),'--',path.resolve(source),out],{stdio:'pipe',maxBuffer:8e6,cwd:process.cwd(),env:{...process.env,PWD:process.cwd()}});
  const data=JSON.parse(await fs.readFile(out)),sourceData=JSON.parse(await fs.readFile(source));for(const pair of data.intersectionCandidates){const allowed=(sourceData.allowContacts??[]).find(a=>a.instances.includes(pair.a)&&a.instances.includes(pair.b));pair.declaredAllowedContact=!!allowed;if(allowed)pair.declaredReason=allowed.reason;}data.unresolvedIntersections=data.intersectionCandidates.filter(p=>!p.declaredAllowedContact);data.sourceManifestSha256=sha(await fs.readFile(source));data.sourceHashFailures=data.instances.filter(i=>!i.sourceHashMatches);data.contactOutliers=data.instances.filter(i=>i.supportDeltaM!==undefined&&(i.supportDeltaM<-.003||i.supportDeltaM>.015||i.supportXYOverlap===false));layouts.push(data);
 }
 const result={scope:'Two static photo-estimated candidate layouts; actual transformed native geometry, bounded intersection screening, declared scale/material variants and source hashes. No physics or visual approval.',layoutCount:layouts.length,instanceCount:layouts.reduce((n,l)=>n+l.instances.length,0),unresolvedIntersections:layouts.reduce((n,l)=>n+l.unresolvedIntersections.length,0),sourceHashFailures:layouts.reduce((n,l)=>n+l.sourceHashFailures.length,0),contactOutliers:layouts.reduce((n,l)=>n+l.contactOutliers.length,0),intersectionCandidates:layouts.reduce((n,l)=>n+l.intersectionCandidates.length,0),layouts};
 await fs.writeFile(path.join(outputRoot,'composition_validation.json'),JSON.stringify(result,null,2)+'\n');console.log(JSON.stringify({sourceHashFailures:result.sourceHashFailures,contactOutliers:result.contactOutliers,intersectionCandidates:result.intersectionCandidates,unresolvedIntersections:result.unresolvedIntersections,reportSha256:sha(await fs.readFile(path.join(outputRoot,'composition_validation.json')))}));
 return result;
}
