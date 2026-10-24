/* Standalone Godot content transport. This never reads or writes story state. */
(function () {
  'use strict';
  // Content identities come from the current release manifest. IndexedDB also
  // works on a plain-IP HTTP origin, where CacheStorage/WebCrypto do not.
  const BLOCK_BYTES = 1024 * 1024;
  function sha256() {
    const state = new Uint32Array([0x6a09e667,0xbb67ae85,0x3c6ef372,0xa54ff53a,0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19]);
    const constants = new Uint32Array([0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2]);
    const pending = new Uint8Array(64), words = new Uint32Array(64);
    let used = 0, length = 0;
    const rotate = (value, count) => (value >>> count) | (value << (32 - count));
    function compress(bytes, offset) {
      for (let i=0; i<16; i++) { const at=offset+i*4; words[i]=((bytes[at]<<24)|(bytes[at+1]<<16)|(bytes[at+2]<<8)|bytes[at+3])>>>0; }
      for (let i=16; i<64; i++) { const a=words[i-15], b=words[i-2]; words[i]=(words[i-16]+(rotate(a,7)^rotate(a,18)^(a>>>3))+words[i-7]+(rotate(b,17)^rotate(b,19)^(b>>>10)))>>>0; }
      // This runs once per 64 bytes. Keep the working state scalar so verifying
      // a full engine does not allocate hundreds of thousands of iterators,
      // temporary arrays and callbacks on the browser's main thread.
      let a=state[0],b=state[1],c=state[2],d=state[3],e=state[4],f=state[5],g=state[6],h=state[7];
      for (let i=0; i<64; i++) {
        const t1=(h+(rotate(e,6)^rotate(e,11)^rotate(e,25))+((e&f)^(~e&g))+constants[i]+words[i])>>>0;
        const t2=((rotate(a,2)^rotate(a,13)^rotate(a,22))+((a&b)^(a&c)^(b&c)))>>>0;
        h=g;g=f;f=e;e=(d+t1)>>>0;d=c;c=b;b=a;a=(t1+t2)>>>0;
      }
      state[0]=(state[0]+a)>>>0;state[1]=(state[1]+b)>>>0;state[2]=(state[2]+c)>>>0;state[3]=(state[3]+d)>>>0;
      state[4]=(state[4]+e)>>>0;state[5]=(state[5]+f)>>>0;state[6]=(state[6]+g)>>>0;state[7]=(state[7]+h)>>>0;
    }
    return {
      update(bytes) {
        length+=bytes.byteLength;
        let at=0;
        if (used) { const take=Math.min(64-used,bytes.byteLength);pending.set(bytes.subarray(0,take),used);used+=take;at+=take;if(used===64){compress(pending,0);used=0;} }
        for (;at+64<=bytes.byteLength;at+=64) compress(bytes,at);
        if(at<bytes.byteLength){pending.set(bytes.subarray(at),0);used=bytes.byteLength-at;}
        return this;
      },
      hex() {
        const tail=new Uint8Array(used<56?64:128);tail.set(pending.subarray(0,used));tail[used]=128;
        const bits=length*8, view=new DataView(tail.buffer);view.setUint32(tail.length-8,Math.floor(bits/4294967296));view.setUint32(tail.length-4,bits>>>0);
        for(let at=0;at<tail.length;at+=64)compress(tail,at);
        return Array.from(state,value=>value.toString(16).padStart(8,'0')).join('');
      }
    };
  }
  const yieldToBrowser = () => new Promise(resolve => setTimeout(resolve, 0));
  function abortError() { const error=new Error('Content transfer cancelled');error.name='AbortError';return error; }
  function checkSignal(signal) { if(signal && signal.aborted)throw abortError(); }
  function abortable(promise,signal) {
    if(!signal)return promise;
    checkSignal(signal);
    return new Promise((resolve,reject)=>{
      const abort=()=>{signal.removeEventListener('abort',abort);reject(abortError());};
      signal.addEventListener('abort',abort,{once:true});
      Promise.resolve(promise).then(value=>{signal.removeEventListener('abort',abort);resolve(value);},error=>{signal.removeEventListener('abort',abort);reject(error);});
    });
  }
  async function digestParts(parts,signal) {
    // Keep the WASM chunks separate: concatenating a second whole engine buffer
    // just to hash it increases peak startup memory. Yield between 1 MiB slices
    // so fallback verification cannot monopolize an input/rendering frame.
    const hash = sha256();
    for (const bytes of parts) for (let offset = 0; offset < bytes.byteLength; offset += BLOCK_BYTES) {
      checkSignal(signal);
      hash.update(bytes.subarray(offset, offset + BLOCK_BYTES));
      if (bytes.byteLength >= BLOCK_BYTES || parts.length > 1) await yieldToBrowser();
    }
    checkSignal(signal);return hash.hex();
  }
  async function digestBytes(bytes,signal) {
    checkSignal(signal);
    // Secure origins have the browser's asynchronous native implementation.
    // Plain-IP HTTP and restricted contexts keep the verified JS fallback.
    if (globalThis.crypto && globalThis.crypto.subtle) {
      try {
        const result = await abortable(globalThis.crypto.subtle.digest('SHA-256', bytes),signal);
        checkSignal(signal);
        return Array.from(new Uint8Array(result), value => value.toString(16).padStart(2, '0')).join('');
      } catch (error) { checkSignal(signal); /* A denied crypto capability must not disable loading. */ }
    }
    return digestParts([bytes],signal);
  }
  function identity(resource) {
    if (!resource || !Number.isSafeInteger(resource.bytes) || resource.bytes<1 || resource.bytes>1024*1024*1024 || !/^[a-f0-9]{64}$/.test(resource.sha256) || typeof resource.file!=='string') throw new Error('Invalid resource identity');
    const base=new URL('.',document.baseURI), url=new URL(resource.file,base);
    if(url.origin!==base.origin || !url.pathname.startsWith(base.pathname) || /[\\?#\x00-\x1f]/.test(resource.file) || resource.file.startsWith('/') || resource.file.split('/').some(part=>!part || part==='.' || part==='..')) throw new Error('Invalid resource path');
    return url.href;
  }
  function chunkTable(resource) {
    identity(resource);
    const deferred=resource.transportChunks!==undefined, chunks=deferred?resource.transportChunks:resource.chunks;
    if(deferred && (!/^[a-z0-9_]+$/.test(resource.id)||resource.file!==`content/${resource.id}-${resource.sha256.slice(0,16)}.pck`))throw new Error('Invalid content chunk owner');
    if(!Array.isArray(chunks) || chunks.length!==Math.ceil(resource.bytes/BLOCK_BYTES))throw new Error('Invalid resource chunks');
    chunks.forEach((chunk,index)=>{
      identity(chunk);
      const validPath=deferred?chunk.file===`content/chunks/${resource.id}-${String(index+1).padStart(4,'0')}-${chunk.sha256.slice(0,16)}.bin`:chunk.file.startsWith('boot/')&&chunk.file.includes(chunk.sha256.slice(0,16));
      if(chunk.offset!==index*BLOCK_BYTES || chunk.bytes!==Math.min(BLOCK_BYTES,resource.bytes-chunk.offset) || !validPath)throw new Error('Invalid resource chunk identity');
    });
    return chunks;
  }
  function createResourceCache() {
    let database, unavailable=false;
    let activeDownloads=0;
    const waitingDownloads=[];
    const stats={storage:'opening',reusedBytes:0,networkBytes:0,writtenBytes:0};
    function acquire(signal) {
      checkSignal(signal);
      return new Promise((resolve,reject)=>{
        const ticket={grant(){
          if(signal)signal.removeEventListener('abort',cancel);
          activeDownloads++;let released=false;
          resolve(()=>{if(released)return;released=true;activeDownloads--;if(waitingDownloads.length)waitingDownloads.shift().grant();});
        }};
        const cancel=()=>{const at=waitingDownloads.indexOf(ticket);if(at>=0)waitingDownloads.splice(at,1);reject(abortError());};
        if(activeDownloads<3)ticket.grant();else {waitingDownloads.push(ticket);if(signal)signal.addEventListener('abort',cancel,{once:true});}
      });
    }
    async function fetchChunk(chunk,priority,signal) {
      const release=await acquire(signal);
      try {
        checkSignal(signal);
        const response=await abortable(fetch(identity(chunk),{cache:'force-cache',priority:priority||'high',signal}),signal);
        if(!response.ok || response.status!==200)throw new Error('Chunk HTTP '+response.status);
        const bytes=new Uint8Array(await abortable(response.arrayBuffer(),signal));checkSignal(signal);return bytes;
      } finally {release();}
    }
    function db() {
      if(!database)database=new Promise(resolve=>{
        if(typeof indexedDB==='undefined'){unavailable=true;stats.storage='unavailable';resolve(null);return;}
        let request;
        try{request=indexedDB.open('755-godot-resources-v1',1);}catch(_){unavailable=true;stats.storage='unavailable';resolve(null);return;}
        request.onupgradeneeded=()=>{if(!request.result.objectStoreNames.contains('chunks'))request.result.createObjectStore('chunks');};
        request.onsuccess=()=>{if(unavailable){request.result.close();return;}stats.storage='indexeddb';request.result.onversionchange=()=>request.result.close();resolve(request.result);};
        request.onerror=request.onblocked=()=>{unavailable=true;stats.storage='unavailable';resolve(null);};
      });
      return unavailable?Promise.resolve(null):database;
    }
    async function operation(mode,run) {
      const connection=await db();if(!connection)return null;
      return new Promise(resolve=>{
        let transaction,result=null;
        try{transaction=connection.transaction('chunks',mode);const request=run(transaction.objectStore('chunks'));if(request)request.onsuccess=()=>{result=request.result;};}
        catch(_){unavailable=true;stats.storage='unavailable';resolve(null);return;}
        transaction.oncomplete=()=>resolve(result===undefined?null:result);
        transaction.onerror=transaction.onabort=()=>{unavailable=true;stats.storage='unavailable';resolve(null);};
      });
    }
    const key=(resource,index)=>resource.sha256+':'+index;
    const chunkKey=chunk=>'chunk:'+chunk.sha256;
    async function discard(resource,first=0) {
      for(let index=first;index<Math.ceil(resource.bytes/BLOCK_BYTES);index++) {
        await operation('readwrite',store=>store.delete(key(resource,index)));
        const chunks=resource.transportChunks||resource.chunks;
        if(chunks)await operation('readwrite',store=>store.delete(chunkKey(chunks[index])));
      }
    }
    function completed(resource,options,output,reused,network) {
      stats.reusedBytes+=reused;
      const source=network?(reused?'resumed-network':'network'):'verified-cache';
      if(!options.response)return {buffer:output.buffer,source,reusedBytes:reused};
      let index=0;
      const stream=new ReadableStream({pull(controller){if(index===output.length){controller.close();return;}const bytes=output[index];output[index++]=null;controller.enqueue(bytes);},cancel(){output.length=0;}});
      return {response:new Response(stream,{headers:{'Content-Type':'application/wasm','Content-Length':String(resource.bytes)}}),source,reusedBytes:reused};
    }
    async function loadChunks(resource,options) {
      const chunks=chunkTable(resource), controller=new AbortController(), signal=controller.signal;
      checkSignal(options.signal);
      const cancel=()=>controller.abort();
      if(options.signal)options.signal.addEventListener('abort',cancel,{once:true});
      try {
      const output=options.response?[]:new Uint8Array(resource.bytes), missing=[];
      let received=0,reused=0,network=0,next=0;
      function accept(index,bytes) {
        checkSignal(signal);
        if(options.response)output[index]=bytes;else output.set(bytes,chunks[index].offset);
        received+=bytes.byteLength;
        if(options.onProgress)options.onProgress(received,resource.bytes,{reusedBytes:reused,networkBytes:network,storage:stats.storage});
      }
      for(let index=0;index<chunks.length;index++) {
        checkSignal(signal);
        const chunk=chunks[index], canonical=chunkKey(chunk);
        let saved=await operation('readonly',store=>store.get(canonical)), legacy=false;
        if(!saved){saved=await operation('readonly',store=>store.get(key(resource,index)));legacy=!!saved;}
        const bytes=saved && saved.bytes instanceof ArrayBuffer?new Uint8Array(saved.bytes):null;
        if(bytes && bytes.byteLength===chunk.bytes && await digestBytes(bytes,signal)===chunk.sha256) {
          if(legacy) {
            const migrated=await operation('readwrite',store=>store.put({bytes:bytes.buffer,digest:chunk.sha256},canonical));
            if(migrated!==null)await operation('readwrite',store=>store.delete(key(resource,index)));
          }
          reused+=bytes.byteLength;accept(index,bytes);
        }
        else {if(saved)await operation('readwrite',store=>store.delete(legacy?key(resource,index):canonical));missing.push(index);}
      }
      // Independent complete small files avoid compressed HTTP Range offsets.
      // Three workers bound peak transient memory and connection pressure.
      async function worker() {
        while(next<missing.length) {
          checkSignal(signal);
          const index=missing[next++], chunk=chunks[index];
          const bytes=await fetchChunk(chunk,options.priority,signal);network+=bytes.byteLength;stats.networkBytes+=bytes.byteLength;
          if(bytes.byteLength!==chunk.bytes || await digestBytes(bytes,signal)!==chunk.sha256)throw new Error('Chunk digest or size differs');
          const saved=await operation('readwrite',store=>store.put({bytes:bytes.buffer,digest:chunk.sha256},chunkKey(chunk)));
          if(saved!==null)stats.writtenBytes+=bytes.byteLength;
          accept(index,bytes);
        }
      }
      const workers=Array.from({length:Math.min(3,missing.length)},worker);
      try { await Promise.all(workers); }
      catch(error){controller.abort();await Promise.allSettled(workers);throw error;}
      const digest=options.response?await digestParts(output,signal):await digestBytes(output,signal);
      if(digest!==resource.sha256){await discard(resource);throw new Error('Content digest differs');}
      return completed(resource,options,output,reused,network);
      } finally {if(options.signal)options.signal.removeEventListener('abort',cancel);}
    }
    async function load(resource,options={}) {
      const signal=options.signal;checkSignal(signal);
      if(resource && (resource.transportChunks!==undefined||resource.chunks!==undefined))return loadChunks(resource,options);
      const url=identity(resource), output=options.response?[]:new Uint8Array(resource.bytes);
      let received=0, reused=0, network=0;
      const progress=()=>{if(options.onProgress)options.onProgress(received,resource.bytes,{reusedBytes:reused,networkBytes:network,storage:stats.storage});};
      const accept=bytes=>{checkSignal(signal);if(options.response)output.push(bytes);else output.set(bytes,received);received+=bytes.byteLength;progress();};
      // Partial chunks are quarantined transport data: every byte, including
      // reused chunks, must pass the manifest's complete SHA before any caller
      // receives them. Their local digest detects a torn/corrupt IDB record.
      for(let index=0;received<resource.bytes;index++) {
        checkSignal(signal);
        const saved=await operation('readonly',store=>store.get(key(resource,index)));
        if(!saved)break;
        const bytes=saved.bytes instanceof ArrayBuffer?new Uint8Array(saved.bytes):null;
        if(!bytes || bytes.byteLength!==Math.min(BLOCK_BYTES,resource.bytes-received) || await digestBytes(bytes,signal)!==saved.digest) {await discard(resource,index);break;}
        reused+=bytes.byteLength;accept(bytes);
      }
      if(received<resource.bytes) {
        const release=await acquire(signal);
        try {
        checkSignal(signal);
        // The core/WASM names are mutable on GitHub Pages. Never force reuse of
        // a stale HTTP response after its manifest has changed. Deferred URLs
        // already contain their content hash and may use normal HTTP reuse.
        const priority=options.priority||'high';
        async function fullGet() {
          const response=await abortable(fetch(url,{cache:'reload',priority,headers:{},signal}),signal);
          if(!response.ok)throw new Error('HTTP '+response.status);
          if(response.status!==200){if(response.body)await response.body.cancel().catch(()=>{});throw new Error('Content range differs');}
          return response;
        }
        let response;
        try {response=await abortable(fetch(url,{cache:resource.file.startsWith('content/')?'force-cache':'no-cache',priority,headers:received?{Range:'bytes='+received+'-'}:{},signal}),signal);}
        catch(error) {
          checkSignal(signal);
          // Chromium can reject a gzip byte-range before exposing any Response
          // or encoding headers. Only a real resume attempt gets this single
          // complete retry. Errors from that complete GET remain visible.
          if(!received)throw error;
          response=await fullGet();
        }
        if(!response.ok)throw new Error('HTTP '+response.status);
        if(response.status===206) {
          const range=response.headers && response.headers.get('Content-Range');
          const encoding=response.headers && response.headers.get('Content-Encoding');
          if(range!=='bytes '+received+'-'+(resource.bytes-1)+'/'+resource.bytes || (encoding && encoding!=='identity')) {
            if(response.body)await response.body.cancel().catch(()=>{});
            // Some proxies range over a compressed representation rather than
            // decoded manifest bytes. Try one complete identity-independent
            // GET instead of repeating that same unusable Range on every load.
            response=await fullGet();
          }
        } else if(response.status!==200)throw new Error('Unexpected content status');
        if(response.status===200 && received) {
          // A server may ignore Range (including gzip delivery). Consume its
          // complete decoded body without mixing it with a cached prefix.
          received=0;reused=0;if(options.response)output.length=0;
        }
        let block=new Uint8Array(Math.min(BLOCK_BYTES,resource.bytes-received)), filled=0;
        async function append(bytes) {
          network+=bytes.byteLength;stats.networkBytes+=bytes.byteLength;
          let at=0;
          while(at<bytes.byteLength) {
            checkSignal(signal);
            if(!block.byteLength){await discard(resource);throw new Error('Content size differs');}
            const take=Math.min(block.byteLength-filled,bytes.byteLength-at);block.set(bytes.subarray(at,at+take),filled);filled+=take;at+=take;
            if(filled===block.byteLength) {
              const index=received/BLOCK_BYTES;
              const digest=await digestBytes(block,signal);
              const saved=await operation('readwrite',store=>store.put({bytes:block.buffer,digest},key(resource,index)));
              if(saved!==null)stats.writtenBytes+=block.byteLength;
              accept(block);block=new Uint8Array(Math.min(BLOCK_BYTES,resource.bytes-received));filled=0;
            }
          }
        }
        if(response.body && response.body.getReader) {
          const reader=response.body.getReader();
          try{while(true){const item=await abortable(reader.read(),signal);if(item.done)break;await append(item.value);}}
          catch(error){await reader.cancel().catch(()=>{});throw error;}
        } else await append(new Uint8Array(await abortable(response.arrayBuffer(),signal)));
        if(received!==resource.bytes || filled)throw new Error('Incomplete content');
        } finally {release();}
      }
      const digest=options.response?await digestParts(output,signal):await digestBytes(output,signal);
      if(digest!==resource.sha256){await discard(resource);throw new Error('Content digest differs');}
      // WASM is streamed to Godot's official fetch-based preloader. No second
      // whole-file concatenation or persistent override of browser fetch.
      return completed(resource,options,output,reused,network);
    }
    return {load,discard,snapshot:()=>({...stats})};
  }
  function bootResources(build,manifest,executable) {
    if(!build || !Array.isArray(build.files) || typeof executable!=='string')throw new Error('Invalid boot manifest');
    const file=executable+'.wasm', matches=build.files.filter(item=>item.path===file), cores=build.files.filter(item=>item.path===manifest.core.file);
    if(matches.length!==1 || cores.length!==1 || cores[0].bytes!==manifest.core.bytes || cores[0].sha256!==manifest.core.sha256)throw new Error('Release manifests differ');
    const wasm={file,bytes:matches[0].bytes,sha256:matches[0].sha256};identity(wasm);
    const chunks=build.bootChunks;
    if(!chunks || chunks.schema!=='755-boot-chunks-v1' || chunks.chunkBytes!==BLOCK_BYTES || !chunks.resources)throw new Error('Missing boot chunks');
    function attach(resource) {
      const table=chunks.resources[resource.file];
      if(!table || table.file!==resource.file || table.bytes!==resource.bytes || table.sha256!==resource.sha256)throw new Error('Boot resource versions differ');
      chunkTable(table);
      for(const chunk of table.chunks) {
        const declared=build.files.filter(item=>item.path===chunk.file);
        if(declared.length!==1 || declared[0].bytes!==chunk.bytes || declared[0].sha256!==chunk.sha256)throw new Error('Boot chunk versions differ');
      }
      return table;
    }
    return {wasm:attach(wasm),core:attach(manifest.core)};
  }
  async function initEngine(engine,executable,resource,response) {
    const url=identity(resource), original=globalThis.fetch;
    const scoped=function(input,init) {
      const requestUrl=typeof input==='string'?input:(input.url||String(input));
      const method=init&&init.method || (input&&input.method) || 'GET';
      if(method==='GET' && new URL(requestUrl,document.baseURI).href===url)return Promise.resolve(response);
      return original.call(globalThis,input,init);
    };
    globalThis.fetch=scoped;
    try{return await engine.init(executable);}finally{if(globalThis.fetch===scoped)globalThis.fetch=original;}
  }
  const families = new Set(['chapter2', 'chapter3', 'chapter35', 'chapter4', 'campus_shared', 'campus_chaoyang', 'campus_haidian', 'campus_changping']);
  function validate(manifest) {
    if (!manifest || manifest.schema !== '755-web-content-v1' || !Array.isArray(manifest.packs) || manifest.packs.length > 100) throw new Error('Invalid content manifest');
    const ids = new Set();
    const paths = new Set();
    const base = new URL('.', document.baseURI);
    for (const pack of [manifest.core].concat(manifest.packs)) {
      if (!pack || !Number.isSafeInteger(pack.bytes) || pack.bytes < 1 || !/^[a-f0-9]{64}$/.test(pack.sha256) || typeof pack.file !== 'string') throw new Error('Invalid content identity');
      const url = new URL(pack.file, base);
      if (url.origin !== base.origin || !url.pathname.startsWith(base.pathname) || /[?#]/.test(pack.file) || pack.file.startsWith('/') || pack.file.split('/').includes('..') || paths.has(pack.file)) throw new Error('Invalid content path');
      paths.add(pack.file);
      if (pack !== manifest.core) {
        if (!/^[a-z0-9_]+$/.test(pack.id) || ids.has(pack.id) || !families.has(pack.family) || pack.bytes > 24000000) throw new Error('Invalid content group');
        ids.add(pack.id);
        if(pack.transportChunks!==undefined)for(const chunk of chunkTable(pack)) {
          if(paths.has(chunk.file))throw new Error('Duplicate content chunk path');
          paths.add(chunk.file);
        }
      }
    }
    if (!Array.isArray(manifest.backgroundOrder) || manifest.backgroundOrder.some(id => !families.has(id))) throw new Error('Invalid background order');
    return manifest;
  }
  function create(options) {
    const manifest = validate(options.manifest);
    const engine = options.engine;
    const resourceCache = options.resourceCache || createResourceCache();
    const records = new Map(manifest.packs.map(pack => [pack.id, { pack, status: 'idle', received: 0, error: '', attempts: 0, source: '' }]));
    const foreground = new Set();
    let receive = null;
    let active = null;
    let background = false;
    // Warm only the next chapter, not every remaining PCK into MEMFS. The
    // native availability coordinator advances this window after real entry.
    let prefetchFamilies = new Set(manifest.backgroundOrder.slice(0, 1));
    let disposed = false;
    let cachePromise;
    const saveData = !!(navigator.connection && navigator.connection.saveData);
    const cacheKey = pack => new URL('/.755-content-cache/' + pack.sha256 + '.pck', location.origin).href;
    function cache() {
      if (!cachePromise) cachePromise = Promise.resolve().then(() => typeof caches === 'undefined' ? null : caches.open('755-godot-content-v1')).catch(() => null);
      return cachePromise;
    }
    function selectIds(raw) {
      let ids;
      try { ids = JSON.parse(raw); } catch (_) { return []; }
      return Array.isArray(ids) && ids.length <= records.size ? ids.filter(id => typeof id === 'string' && records.has(id)) : [];
    }
    function next() {
      for (const id of foreground) if (records.get(id).status === 'idle') return records.get(id);
      if (background && !saveData && !document.hidden) for (const family of manifest.backgroundOrder) if (prefetchFamilies.has(family)) for (const record of records.values()) if (record.pack.family === family && record.status === 'idle') return record;
      return null;
    }
    function notify(record, path, error) { if (receive && !disposed) receive(record.pack.id, path, error || ''); }
    function current(run) { checkSignal(run.controller.signal);if(disposed||active!==run)throw abortError(); }
    function preemptOptional() {
      if(!active || active.record.status!=='downloading' || foreground.has(active.record.pack.id))return;
      const required=[...foreground].some(id=>id!==active.record.pack.id&&records.get(id).status==='idle');
      if(document.hidden || !prefetchFamilies.has(active.record.pack.family) || required)active.controller.abort();
    }
    async function download(run) {
      const record=run.record, signal=run.controller.signal;
      const store = await cache();
      current(run);
      let response = record.attempts === 1 && store ? await abortable(store.match(cacheKey(record.pack)).catch(() => null),signal) : null;
      current(run);
      record.source = response ? 'verified-cache' : 'network';
      if (!response) {
        const loaded = await resourceCache.load(record.pack, { signal, priority: foreground.has(record.pack.id) ? 'high' : 'low', onProgress: count => { if(active===run&&!disposed&&!signal.aborted)record.received = count; } });
        current(run);
        record.source = loaded.source;
        record.buffer = loaded.buffer;
        const path = '/755-content/' + record.pack.sha256 + '.pck';
        engine.copyToFS(path, record.buffer);
        record.status = 'mounting';
        notify(record, path, '');
        return;
      }
      if (!response.ok) throw new Error('HTTP ' + response.status);
      let bytes;
      if (response.body && response.body.getReader) {
        bytes = new Uint8Array(record.pack.bytes);
        const reader = response.body.getReader();
        let count = 0;
        try {
          while (true) {
            const chunk = await abortable(reader.read(),signal);
            current(run);
            if (chunk.done) break;
            if (count + chunk.value.byteLength > bytes.byteLength) throw new Error('Content size differs');
            bytes.set(chunk.value, count); count += chunk.value.byteLength; record.received = count;
          }
        } catch (error) { await reader.cancel().catch(() => {}); throw error; }
        if (count !== record.pack.bytes) throw new Error('Incomplete content');
      } else {
        bytes = new Uint8Array(await abortable(response.arrayBuffer(),signal));current(run);record.received = bytes.byteLength;
        if (bytes.byteLength !== record.pack.bytes) throw new Error('Content size differs');
      }
      if (await digestBytes(bytes,signal) !== record.pack.sha256) throw new Error('Content digest differs');
      current(run);
      record.buffer = bytes.buffer;
      const path = '/755-content/' + record.pack.sha256 + '.pck';
      engine.copyToFS(path, record.buffer);
      record.status = 'mounting';
      notify(record, path, '');
    }
    async function pump() {
      if (disposed || !receive || active) return;
      const record = next();
      if (!record) return;
      const run={record,controller:new AbortController()};
      active = run; record.status = 'downloading'; record.error = ''; record.received = 0; record.attempts++;
      try { await download(run); }
      catch (error) {
        if(active!==run)return;
        const cancelled=disposed||run.controller.signal.aborted||error.name==='AbortError';
        run.controller.abort(); // Stop sibling chunk workers after any failure.
        record.status = cancelled?'idle':'error'; record.error = cancelled?'':String(error.message || error); record.buffer = null;
        if(!cancelled){const store = await cache(); if (store) await store.delete(cacheKey(record.pack)).catch(() => {});}
        if(active!==run)return;
        active = null;if(!cancelled)notify(record, '', record.error);pump();
      }
    }
    const onVisibility = () => { preemptOptional();if (!document.hidden) pump(); };
    if (typeof document.addEventListener === 'function') document.addEventListener('visibilitychange', onVisibility);
    const host = {
      manifest: () => JSON.stringify(manifest),
      install: callback => { receive = callback; },
      setPrefetchFamilies: raw => {
        if(disposed)return;
        let selected;
        try { selected = JSON.parse(raw); } catch (_) { return; }
        if (!Array.isArray(selected) || selected.length > 1 || selected.some(family => !manifest.backgroundOrder.includes(family))) return;
        prefetchFamilies = new Set(selected);preemptOptional();pump();
      },
      request: raw => { if(disposed)return;for (const id of selectIds(raw)) foreground.add(id);preemptOptional();pump(); },
      retry: raw => {
        if(disposed)return;
        for (const id of selectIds(raw)) {
          const record = records.get(id); foreground.add(id);
          if (record.status === 'error') { record.status = 'idle'; record.error = ''; }
        }
        preemptOptional();pump();
      },
      acknowledge: async (id, accepted, message) => {
        const record = records.get(id);
        const run=active;
        if (disposed || !record || !run || record !== run.record || record.status !== 'mounting') return;
        record.status = accepted ? 'mounted' : 'error'; record.error = accepted ? '' : String(message || 'Content verification failed');
        const store = await cache();
        if(disposed||active!==run)return;
        if (accepted && store && record.source !== 'verified-cache') {
          await store.put(cacheKey(record.pack), new Response(record.buffer, { headers: { 'Content-Type': 'application/octet-stream' } })).catch(() => {});
        } else if (!accepted && store) await store.delete(cacheKey(record.pack)).catch(() => {});
        if (!accepted) await resourceCache.discard(record.pack);
        record.buffer = null;if(active===run){active = null;pump();}
      },
      startPrefetch: () => {
        // Two frames leave the first chapter's first paint and input ahead of
        // optional network work. Only one small content block runs at a time.
        requestAnimationFrame(() => requestAnimationFrame(() => { if(!disposed){background = true;pump();} }));
      },
      snapshot: () => JSON.stringify({ background, saveData, prefetchFamilies: [...prefetchFamilies], active: active ? active.record.pack.id : '', resourceCache: resourceCache.snapshot(), packs: Array.from(records.values(), r => ({ id: r.pack.id, family: r.pack.family, status: r.status, received: r.received, bytes: r.pack.bytes, error: r.error, source: r.source, attempts: r.attempts })) }),
      dispose: () => {
        disposed = true;receive = null;
        if(active){active.controller.abort();if(active.record.status==='downloading'||active.record.status==='mounting')active.record.status='idle';}
        active=null;for(const record of records.values())record.buffer=null;
        if (typeof document.removeEventListener === 'function') document.removeEventListener('visibilitychange', onVisibility);
      }
    };
    return host;
  }
  window.Godot755Content = Object.freeze({ create, validate, createResourceCache, bootResources, initEngine });
})();
