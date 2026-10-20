/* Standalone Godot content transport. This never reads or writes story state. */
(function () {
  'use strict';
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
      }
    }
    if (!Array.isArray(manifest.backgroundOrder) || manifest.backgroundOrder.some(id => !families.has(id))) throw new Error('Invalid background order');
    return manifest;
  }
  function create(options) {
    const manifest = validate(options.manifest);
    const engine = options.engine;
    const records = new Map(manifest.packs.map(pack => [pack.id, { pack, status: 'idle', received: 0, error: '', attempts: 0, source: '' }]));
    const foreground = new Set();
    let receive = null;
    let active = null;
    let background = false;
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
      if (background && !saveData) for (const family of manifest.backgroundOrder) for (const record of records.values()) if (record.pack.family === family && record.status === 'idle') return record;
      return null;
    }
    function notify(record, path, error) { if (receive && !disposed) receive(record.pack.id, path, error || ''); }
    async function download(record) {
      const store = await cache();
      let response = record.attempts === 1 && store ? await store.match(cacheKey(record.pack)).catch(() => null) : null;
      record.source = response ? 'verified-cache' : 'network';
      if (!response) response = await fetch(new URL(record.pack.file, document.baseURI).href, { cache: 'force-cache', priority: foreground.has(record.pack.id) ? 'high' : 'low' });
      if (!response.ok) throw new Error('HTTP ' + response.status);
      let bytes;
      if (response.body && response.body.getReader) {
        bytes = new Uint8Array(record.pack.bytes);
        const reader = response.body.getReader();
        let count = 0;
        try {
          while (true) {
            const chunk = await reader.read();
            if (chunk.done) break;
            if (count + chunk.value.byteLength > bytes.byteLength) throw new Error('Content size differs');
            bytes.set(chunk.value, count); count += chunk.value.byteLength; record.received = count;
          }
        } catch (error) { await reader.cancel().catch(() => {}); throw error; }
        if (count !== record.pack.bytes) throw new Error('Incomplete content');
      } else {
        bytes = new Uint8Array(await response.arrayBuffer()); record.received = bytes.byteLength;
        if (bytes.byteLength !== record.pack.bytes) throw new Error('Content size differs');
      }
      // On plain-IP HTTP, WebCrypto may be unavailable. The native coordinator
      // always independently hashes the MEMFS file before mounting or caching.
      if (typeof crypto !== 'undefined' && crypto.subtle) {
        const digest = Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256', bytes))).map(b => b.toString(16).padStart(2, '0')).join('');
        if (digest !== record.pack.sha256) throw new Error('Content digest differs');
      }
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
      active = record; record.status = 'downloading'; record.error = ''; record.received = 0; record.attempts++;
      try { await download(record); }
      catch (error) {
        record.status = 'error'; record.error = String(error.message || error); record.buffer = null;
        const store = await cache(); if (store) await store.delete(cacheKey(record.pack)).catch(() => {});
        active = null; notify(record, '', record.error); pump();
      }
    }
    const host = {
      manifest: () => JSON.stringify(manifest),
      install: callback => { receive = callback; },
      request: raw => { for (const id of selectIds(raw)) foreground.add(id); pump(); },
      retry: raw => {
        for (const id of selectIds(raw)) {
          const record = records.get(id); foreground.add(id);
          if (record.status === 'error') { record.status = 'idle'; record.error = ''; }
        }
        pump();
      },
      acknowledge: async (id, accepted, message) => {
        const record = records.get(id);
        if (!record || record !== active || record.status !== 'mounting') return;
        record.status = accepted ? 'mounted' : 'error'; record.error = accepted ? '' : String(message || 'Content verification failed');
        const store = await cache();
        if (accepted && store && record.source !== 'verified-cache') {
          await store.put(cacheKey(record.pack), new Response(record.buffer, { headers: { 'Content-Type': 'application/octet-stream' } })).catch(() => {});
        } else if (!accepted && store) await store.delete(cacheKey(record.pack)).catch(() => {});
        record.buffer = null; active = null; pump();
      },
      startPrefetch: () => {
        // Two frames leave the first chapter's first paint and input ahead of
        // optional network work. Only one small content block runs at a time.
        requestAnimationFrame(() => requestAnimationFrame(() => { background = true; pump(); }));
      },
      snapshot: () => JSON.stringify({ background, saveData, active: active ? active.pack.id : '', packs: Array.from(records.values(), r => ({ id: r.pack.id, family: r.pack.family, status: r.status, received: r.received, bytes: r.pack.bytes, error: r.error, source: r.source, attempts: r.attempts })) }),
      dispose: () => { disposed = true; receive = null; }
    };
    return host;
  }
  window.Godot755Content = Object.freeze({ create, validate });
})();
