// Fixed same-origin transport. Native State owns all parsing, migration and gameplay.
(() => {
  'use strict';
  const base = '/api/v1/me/game-save';
  const uuid = /^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$/;
  const sha = /^[a-f0-9]{64}$/;
  let uncommitted = false;
  let saveChannel;
  try { saveChannel = new BroadcastChannel('755-game-save'); } catch { /* Heartbeat remains available. */ }
  window.addEventListener('beforeunload', event => {
    if (uncommitted) { event.preventDefault(); event.returnValue = ''; }
  });
  function base64(bytes) {
    const parts = [];
    for (let index = 0; index < bytes.length; index += 32768) parts.push(String.fromCharCode(...bytes.subarray(index, index + 32768)));
    return btoa(parts.join(''));
  }
  async function diskFile(path) {
    const db = await new Promise((resolve, reject) => {
      const request = indexedDB.open('/userfs');
      request.onupgradeneeded = () => { request.transaction.abort(); reject(new Error('missing_database')); };
      request.onsuccess = () => resolve(request.result); request.onerror = () => reject(request.error);
    });
    try {
      return await new Promise((resolve, reject) => {
        const tx = db.transaction('FILE_DATA', 'readonly');
        const request = tx.objectStore('FILE_DATA').get(path);
        tx.oncomplete = () => resolve(request.result?.contents);
        tx.onerror = tx.onabort = () => reject(tx.error || new Error('read_failed'));
      });
    } finally { db.close(); }
  }
  async function persist(args) {
    if (!window.crypto?.subtle || typeof indexedDB === 'undefined' ||
        !(args.profile === 'guest' || uuid.test(args.profile)) || !Array.isArray(args.files) || args.files.length > 12) throw new Error('本机持久存储不可用，请导出备份。');
    for (const file of args.files) {
      if (!file.path.startsWith('/userfs/') || !file.path.includes('/profiles/' + args.profile + '/') || file.path.includes('..') || !sha.test(file.digest)) throw new Error('存档目录无效。');
    }
    const deadline = Date.now() + 20000;
    while (Date.now() < deadline) {
      let matches = true;
      for (const file of args.files) {
        try {
          const value = await diskFile(file.path);
          const bytes = value && (ArrayBuffer.isView(value) ? new Uint8Array(value.buffer, value.byteOffset, value.byteLength) : new Uint8Array(value));
          if (!bytes || bytes.length > 12 * 1024 ** 2) { matches = false; break; }
          const digest = [...new Uint8Array(await crypto.subtle.digest('SHA-256', bytes))].map(v => v.toString(16).padStart(2, '0')).join('');
          if (digest !== file.digest) { matches = false; break; }
        } catch { matches = false; break; }
      }
      if (matches) return { ok: true, status: 200, data: { persisted: true } };
      await new Promise(resolve => setTimeout(resolve, 100));
    }
    throw new Error('本机备份尚未确认写入，请重试或导出，暂时不要刷新。');
  }
  async function request(operation, raw, receive) {
    let timer;
    try {
      const args = JSON.parse(raw);
      if (operation === 'persist') { receive(JSON.stringify(await persist(args))); return; }
      if (operation !== 'session' && !uuid.test(args.owner)) throw new Error('账号标识无效。');
      let url = base, method = 'GET', body;
      const headers = { Accept: 'application/json' };
      if (args.owner) headers['X-755-Member'] = args.owner;
      if (operation === 'session') url = '/api/v1/session';
      else if (operation === 'head') { /* canonical owner endpoint */ }
      else if (operation === 'snapshot') {
        if (!uuid.test(args.id)) throw new Error('存档标识无效。');
        url += '/snapshots/' + args.id;
      } else if (operation === 'asset' || operation === 'assetExists' || operation === 'upload') {
        if (!sha.test(args.sha)) throw new Error('照片指纹无效。');
        url += '/assets/' + args.sha;
        if (operation === 'assetExists') method = 'HEAD';
        if (operation === 'upload') {
          if (typeof args.data !== 'string' || args.data.length > 16 * 1024 ** 2 + 4) throw new Error('照片过大。');
          const text = atob(args.data); body = Uint8Array.from(text, character => character.charCodeAt(0));
          method = 'PUT'; headers['Content-Type'] = 'application/octet-stream';
        }
      } else if (['save', 'restart', 'restore'].includes(operation)) {
        method = operation === 'save' ? 'PUT' : 'POST';
        if (operation !== 'save') url += '/' + operation;
        body = JSON.stringify(args.input); headers['Content-Type'] = 'application/json';
      } else throw new Error('不支持的存档操作。');
      if (!['GET', 'HEAD'].includes(method)) headers['X-Requested-With'] = '755-platform';
      const controller = new AbortController(); timer = setTimeout(() => controller.abort(), operation === 'upload' ? 30000 : 15000);
      const response = await fetch(url, { method, body, headers, credentials: 'same-origin', cache: 'no-store', signal: controller.signal });
      let data;
      if (response.ok && operation === 'asset') {
        const bytes = new Uint8Array(await response.arrayBuffer());
        if (bytes.length > 12 * 1024 ** 2) throw new Error('照片超过大小限制。');
        data = { mime: 'image/png', data: base64(bytes) };
      } else if (operation === 'assetExists') data = { exists: response.ok };
      else data = await response.json().catch(() => ({ error: { message: '存档服务没有返回可读取的数据。' } }));
      if (response.ok && ['save', 'restart', 'restore'].includes(operation)) saveChannel?.postMessage('changed');
      receive(JSON.stringify({ ok: response.ok, status: response.status, data, error: response.ok ? '' : data?.error?.message || '存档请求未完成。' }));
    } catch (error) {
      receive(JSON.stringify({ ok: false, status: 0, error: error instanceof Error ? error.message : '连接失败，请重试。' }));
    } finally { clearTimeout(timer); }
  }
  Object.defineProperty(window, '__GODOT_755_CLOUD__', { configurable: true,
    value: Object.freeze({ request, pending: value => { uncommitted = value === true; }, watch: receive => {
      if (saveChannel) saveChannel.onmessage = event => { if (event.data === 'changed') receive('changed'); };
      window.addEventListener('offline', () => receive('offline'));
      window.addEventListener('focus', () => receive('changed'));
      document.addEventListener('visibilitychange', () => { if (!document.hidden) receive('changed'); });
      try {
        const channel = new BroadcastChannel('755-player-session');
        channel.onmessage = event => { if (event.data === 'changed') receive('changed'); };
      } catch { /* Focus and the native heartbeat remain available. */ }
    } }) });
})();
