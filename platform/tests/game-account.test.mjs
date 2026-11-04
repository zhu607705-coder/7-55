import test from 'node:test';
import assert from 'node:assert/strict';
import vm from 'node:vm';
import { readFileSync } from 'node:fs';
const source = readFileSync(new URL('../../godot_native/web/player-account.js', import.meta.url), 'utf8');
const tick = () => new Promise(resolve => setImmediate(resolve));
function host(fetch, options = {}) {
  const elements = [], listeners = {}, redirects = [], opened = [], channels = [];
  function element(tag) {
    const el = { tag, style: {}, hidden: false, disabled: false, textContent: '', children: [], listeners: {},
      setAttribute() {}, append(...items) { this.children.push(...items); },
      addEventListener(name, callback) { this.listeners[name] = callback; },
      isConnected: true, focus() { document.activeElement = this; },
    };
    elements.push(el); return el;
  }
  const body = element('body');
  const canvas = element('canvas'); canvas.id = 'canvas';
  const document = { body, activeElement: canvas, getElementById: id => elements.find(e => e.id === id),
    createElement: element, addEventListener(name, cb) { listeners[name] = cb; } };
  const location = { pathname: options.pathname ?? '/game/', search: '?view=story', hash: '#resume', assign: url => redirects.push(url) };
  const window = { addEventListener(name, cb) { listeners[name] = cb; },
    open(url, target, features) {
      const item = { url, target, features, closed: false, opener: {}, location: { replace: url => { item.destination = url; } }, close() { this.closed = true; } };
      opened.push(item); return options.blocked ? null : item;
    },
  };
  vm.runInNewContext(source, { document, location, fetch, URL, AbortController, setTimeout, clearTimeout,
    window,
    BroadcastChannel: options.channel ? class {
      constructor(name) { this.name = name; this.sent = []; channels.push(this); }
      postMessage(value) { this.sent.push(value); }
    } : undefined,
  });
  return { elements, listeners, redirects, opened, channels, window, document, canvas, panel: elements.find(e => e.tag === 'details'),
    community: elements.find(e => e.tag === 'a'), login: elements.find(e => e.textContent === '登录 / 注册'),
    logout: elements.find(e => e.textContent === '退出账号'), status: elements.find(e => e.tag === 'p'),
  };
}
const response = data => ({ ok: true, json: async () => data });
test('game host keeps one server identity and refreshes after returning from community', async () => {
  let user = null; const calls = [];
  const page = host(async (url, options) => { calls.push({url, options}); return response({user}); });
  await tick(); assert.equal(page.status.textContent, '游客试玩');
  user = { nickname: '<同学>', role: 'member' }; page.listeners.focus(); await tick();
  assert.equal(page.status.textContent, '已登录：<同学>');
  assert.equal(page.login.hidden, true); assert.equal(page.logout.hidden, false);
  assert.ok(calls.every(c => c.url === '/api/v1/session' && c.options.credentials === 'same-origin'));
});
test('game login opens the community login entry without unloading the game or transferring credentials', async () => {
  const calls = [];
  const page = host(async (url, options) => { calls.push({url, options}); return response(url.endsWith('/start') ? {url:'https://identity.example/authorize'} : {user:null}); });
  await tick(); await page.login.listeners.click();
  assert.equal(page.opened[0].url, '/?account=login');
  assert.equal(page.opened[0].features, 'noopener,noreferrer');
  assert.ok(calls.every(call => call.url === '/api/v1/session' && !call.options.body));
  assert.deepEqual(page.redirects, []);
});
test('unavailable identity service leaves game playable and does not fabricate a login', async () => {
  const page = host(async () => { throw new Error('offline'); }); await tick();
  assert.equal(page.login.hidden, true); assert.equal(page.logout.hidden, true);
  assert.match(page.status.textContent, /游客试玩.*未连接/);
  assert.deepEqual(page.redirects, []);
});
test('logout invalidates the server session and stale refresh cannot restore previous identity', async () => {
  let resolveRefresh, calls = 0;
  const page = host(async url => {
    if (url.endsWith('/logout')) return response({ok:true,redirectUrl:null});
    if (++calls === 1) return response({user:{nickname:'A'}});
    return new Promise(resolve => { resolveRefresh = resolve; });
  });
  await tick(); page.listeners.focus(); await tick();
  await page.logout.listeners.click();
  resolveRefresh(response({user:{nickname:'A'}})); await tick();
  assert.equal(page.status.textContent, '游客试玩'); assert.equal(page.logout.hidden, true);
});

test('native navigation bridge exposes only navigation and keeps account controls hidden until requested', async () => {
  const page = host(async () => response({user:null}));
  const bridge = page.window.__GODOT_755_ACCOUNT__;
  assert.equal(page.panel.hidden, true);
  assert.deepEqual(Object.keys(bridge).sort(), ['openCommunity','showAccount']);
  bridge.openCommunity();
  assert.equal(page.opened[0].url, '/');
  assert.equal(page.opened[0].target, '_blank');
  assert.equal(page.opened[0].features, 'noopener,noreferrer');
  assert.equal(page.panel.hidden, false);
  page.elements.find(e => e.textContent === '返回游戏').listeners.click();
  assert.equal(page.panel.hidden, true);
  assert.equal(page.document.activeElement, page.canvas);
  assert.deepEqual(page.redirects, []);
});

test('blocked popups retain a normal link and standalone exports never assume a community at their host root', async () => {
  const blocked = host(async () => response({user:null}), {blocked:true});
  blocked.window.__GODOT_755_ACCOUNT__.openCommunity();
  assert.equal(blocked.community.hidden, false);
  assert.equal(blocked.community.href, '/');
  assert.equal(blocked.community.target, '_blank');
  assert.deepEqual(blocked.redirects, []);
  const standalone = host(async () => { throw new Error('offline'); }, {pathname:'/7-55/'});
  await tick(); standalone.window.__GODOT_755_ACCOUNT__.openCommunity();
  assert.equal(standalone.opened.length, 0);
  assert.match(standalone.status.textContent, /尚未接上共创平台/);
});

test('hosted logout uses a separate tab and preserves a manual fallback when it is blocked', async () => {
  for (const blocked of [false,true]) {
    const calls = [];
    const page = host(async (url, options) => {
      calls.push({url,options});
      return response(url.endsWith('/logout') ? {ok:true,redirectUrl:'https://identity.example/logout'} : {user:{nickname:'A'}});
    }, {blocked});
    await tick(); await page.logout.listeners.click();
    assert.equal(calls.at(-1).url, '/api/v1/auth/logout');
    assert.equal(calls.at(-1).options.headers['X-Requested-With'], '755-platform');
    if (blocked) assert.equal(page.community.href, 'https://identity.example/logout');
    else {
      assert.equal(page.opened[0].opener, null);
      assert.equal(page.opened[0].destination, 'https://identity.example/logout');
    }
    assert.equal(page.logout.hidden, true);
    assert.deepEqual(page.redirects, []);
  }
});

test('cross-tab notifications recheck server identity and never accept a claimed user from a message', async () => {
  let user = {id:'player-a', nickname:'A'}, calls = 0;
  const page = host(async url => {
    calls++;
    return response(url.endsWith('/logout') ? {ok:true,redirectUrl:null} : {user});
  }, {channel:true});
  await tick();
  const channel = page.channels[0];
  assert.equal(channel.name, '755-player-session');
  channel.onmessage({data:{user:{nickname:'fake'}}}); await tick();
  assert.equal(calls, 1);
  user = null;
  channel.onmessage({data:'changed'}); await tick();
  assert.equal(page.status.textContent, '游客试玩');
  user = {id:'player-a',nickname:'A'};
  channel.onmessage({data:'changed'}); await tick();
  await page.logout.listeners.click();
  assert.deepEqual(channel.sent, ['changed']);
});
