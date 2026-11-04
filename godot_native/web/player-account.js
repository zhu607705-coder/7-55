// The Web host uses the same-origin community session. No game progression or save access.
(() => {
  'use strict';
  const panel = document.createElement('details');
  panel.id = 'player-account';
  panel.hidden = true;
  panel.setAttribute('aria-label', '玩家通行证');
  const summary = document.createElement('summary');
  summary.textContent = '玩家账号';
  const status = document.createElement('p');
  status.setAttribute('role', 'status');
  status.textContent = '正在读取账号…';
  const note = document.createElement('p');
  note.textContent = '登录后可在其他设备继续。账号验证将在新标签页完成，完成后切回游戏。';
  const login = document.createElement('button');
  login.type = 'button'; login.textContent = '登录 / 注册'; login.hidden = true;
  const logout = document.createElement('button');
  logout.type = 'button'; logout.textContent = '退出账号'; logout.hidden = true;
  for (const button of [login, logout]) {
  }
  const community = document.createElement('a');
  community.href = '/'; community.textContent = '前往共创平台';
  community.hidden = true;
  community.target = '_blank'; community.rel = 'noopener';
  const close = document.createElement('button');
  close.type = 'button'; close.textContent = '返回游戏';
  const ticket = document.createElement('div');
  ticket.setAttribute('class', 'player-ticket');
  const title = document.createElement('h2');
  title.textContent = '校园通行证';
  const stamp = document.createElement('span');
  stamp.setAttribute('class', 'player-ticket-stamp');
  stamp.setAttribute('aria-hidden', 'true');
  stamp.textContent = '7:55';
  ticket.append(title, stamp);
  const actions = document.createElement('div');
  actions.setAttribute('class', 'player-ticket-actions');
  actions.append(login, logout, close);
  panel.append(summary, ticket, status, note, actions, community);
  document.body.append(panel);
  let pending = false;
  let generation = 0;
  let sessionChannel = null;
  try {
    if (typeof BroadcastChannel !== 'undefined') {
      sessionChannel = new BroadcastChannel('755-player-session');
      sessionChannel.onmessage = event => { if (event.data === 'changed') void refresh(); };
    }
  } catch { /* Focus refresh remains available when cross-tab channels are blocked. */ }
  // The integrated deployment serves only this canonical entry. A standalone
  // Pages export must not mistake its host's root for the community.
  let connected = location.pathname === '/game/' || location.pathname === '/game/index.html';
  let restoreFocus = null;
  function showAccount() {
    if (panel.hidden) restoreFocus = document.activeElement;
    panel.hidden = false; panel.open = true;
    summary.focus();
    void refresh();
  }
  function closeAccount() {
    panel.open = false; panel.hidden = true;
    const target = restoreFocus?.isConnected ? restoreFocus : document.getElementById('canvas');
    if (target) target.focus();
  }
  function openCommunity(loginRequested = false) {
    if (!connected) {
      showAccount();
      status.textContent = '此游戏页面尚未接上共创平台，请从项目提供的统一网址进入。';
      return false;
    }
    // No asynchronous operation before opening: keep the player's click gesture.
    const opened = window.open(loginRequested ? '/?account=login' : '/', '_blank', 'noopener,noreferrer');
    // noopener may return null even on success. Keep a normal link as a fallback
    // without treating that value as a failed login or reusing the game tab.
    showAccount();
    community.hidden = false;
    community.href = loginRequested ? '/?account=login' : '/';
    community.textContent = loginRequested ? '打开登录 / 注册 ↗' : '前往共创平台 ↗';
    status.textContent = '已请求在新标签页打开。若浏览器拦截，请点下面的链接。';
    return Boolean(opened);
  }
  Object.defineProperty(window, '__GODOT_755_ACCOUNT__', {
    configurable: true,
    value: Object.freeze({ openCommunity: () => openCommunity(), showAccount }),
  });
  close.addEventListener('click', closeAccount);
  panel.addEventListener('keydown', event => {
    event.stopPropagation();
    if (event.key === 'Escape') { event.preventDefault(); closeAccount(); }
  });
  async function request(path, body) {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 8000);
    try {
      const response = await fetch('/api/v1' + path, {
        method: body ? 'POST' : 'GET', credentials: 'same-origin', cache: 'no-store',
        signal: controller.signal,
        headers: body ? { 'Content-Type': 'application/json', 'X-Requested-With': '755-platform' } : { Accept: 'application/json' },
        ...(body ? { body: JSON.stringify(body) } : {}),
      });
      if (!response.ok) throw new Error('Account service unavailable');
      return await response.json();
    } finally { clearTimeout(timer); }
  }
  async function refresh() {
    if (pending) return;
    const current = ++generation;
    try {
      const data = await request('/session');
      if (current !== generation) return;
      if (!Object.prototype.hasOwnProperty.call(data, 'user') || (data.user !== null && typeof data.user?.nickname !== 'string')) throw new Error('Invalid session');
      connected = true;
      community.hidden = false;
      status.textContent = data.user ? '已登录：' + data.user.nickname : '游客试玩';
      summary.textContent = data.user ? data.user.nickname + ' · 账号' : '玩家账号';
      login.hidden = Boolean(data.user); logout.hidden = !data.user;
    } catch {
      if (current !== generation) return;
      status.textContent = '游客试玩 · 账号服务暂时未连接';
      summary.textContent = '玩家账号';
      login.hidden = true; logout.hidden = true;
      community.hidden = !connected;
    }
  }
  function authenticationURL(value) {
    const url = new URL(value);
    if (url.protocol !== 'https:' || url.username || url.password) throw new Error('Invalid authentication destination');
    return url.href;
  }
  async function act(action) {
    if (pending) return;
    pending = true; generation++;
    login.disabled = true; logout.disabled = true;
    try {
      await action();
    } catch {
      status.textContent = '账号操作未完成，请重试。';
    } finally {
      pending = false; login.disabled = false; logout.disabled = false;
    }
  }
  login.addEventListener('click', () => openCommunity(true));
  logout.addEventListener('click', () => {
    if (pending) return;
    // Reserve a tab during the click. Neither logout nor hosted sign-in should
    // unload the game or create a second live game writing the same local save.
    const destination = window.open('about:blank', '_blank');
    if (destination) destination.opener = null;
    return act(async () => {
      try {
        const result = await request('/auth/logout', {});
        if (result.ok !== true) throw new Error('Logout failed');
        status.textContent = '游客试玩'; summary.textContent = '玩家账号';
        login.hidden = false; logout.hidden = true;
        sessionChannel?.postMessage('changed');
        if (result.redirectUrl) {
          const url = authenticationURL(result.redirectUrl);
          if (destination) destination.location.replace(url);
          else {
            community.href = url; community.textContent = '完成登录服务退出 ↗'; community.hidden = false;
            status.textContent = '已退出本站账号。请点下方链接完成登录服务退出。';
          }
        } else if (destination) destination.close();
      } catch (error) {
        if (destination) destination.close();
        throw error;
      }
    });
  });
  window.addEventListener('focus', refresh);
  document.addEventListener('visibilitychange', () => { if (!document.hidden) void refresh(); });
  panel.addEventListener('toggle', () => { if (panel.open) void refresh(); });
  void refresh();
})();
