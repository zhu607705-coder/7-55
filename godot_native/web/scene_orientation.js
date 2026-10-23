(function (root) {
  'use strict';
  // Presentation only: the native snapshot chooses the active surface.
  // Fullscreen/rotation requests run inside this button's real user gesture.
  root.install755SceneOrientation = function () {
    if (root.__GODOT_755_ORIENTATION__ && !root.__GODOT_755_ORIENTATION__.disposed) return root.__GODOT_755_ORIENTATION__;
    const doc = root.document;
    const layer = doc.createElement('div');
    layer.id = 'scene-orientation'; layer.hidden = true;
    layer.setAttribute('role', 'dialog'); layer.setAttribute('aria-label', '横屏场景');
    layer.style.cssText = 'position:fixed;inset:0;z-index:1000;display:none;align-items:center;justify-content:center;background:#22282eef;padding:24px;box-sizing:border-box;color:#ece6d5;font:18px/1.6 system-ui,sans-serif';
    const card = doc.createElement('div');
    card.style.cssText = 'max-width:360px;width:100%;padding:28px;box-sizing:border-box;background:#eee7d5;color:#303431;border-top:5px solid #83533c';
    const title = doc.createElement('h2'); title.textContent = '横过手机，展开场景'; title.style.cssText = 'font-size:24px;margin:0 0 16px';
    const copy = doc.createElement('p'); copy.textContent = '手机应用保持竖屏。地图与舞台适合横屏，直接触摸场景里的物件。';
    const enter = doc.createElement('button'); enter.id = 'scene-landscape-enter'; enter.textContent = '横屏全屏';
    const dismiss = doc.createElement('button'); dismiss.id = 'scene-landscape-dismiss'; dismiss.textContent = '暂用竖屏';
    for (const button of [enter, dismiss]) button.style.cssText = 'display:block;width:100%;min-height:48px;margin:12px 0 0;border:1px solid #6f6553;background:#eee7d5;color:#303431;font:inherit;cursor:pointer';
    enter.style.background = '#373e39'; enter.style.color = '#eee7d5';
    card.append(title, copy, enter, dismiss); layer.appendChild(card); doc.body.appendChild(layer);
    let wanted = false, dismissed = false, disposed = false, epoch = 0, ownedLock = false, ownedFullscreen = false, busy = false;
    let restoreFocus = null;
    const coarse = () => typeof root.matchMedia === 'function' && root.matchMedia('(any-pointer: coarse)').matches;
    const portrait = () => root.innerWidth < root.innerHeight;
    function show() {
      const visible = !disposed && wanted && coarse() && portrait() && !dismissed;
      const wasVisible = !layer.hidden;
      layer.hidden = !visible; layer.style.display = visible ? 'flex' : 'none';
      if (visible && !wasVisible) { restoreFocus = doc.activeElement; enter.focus(); }
      if (!visible && wasVisible && restoreFocus && restoreFocus.isConnected && restoreFocus.focus) restoreFocus.focus();
    }
    function release() {
      if (ownedLock) { try { root.screen.orientation.unlock(); } catch (_) {} ownedLock = false; }
      if (ownedFullscreen) {
        ownedFullscreen = false;
        if (doc.fullscreenElement === doc.documentElement && doc.exitFullscreen) Promise.resolve(doc.exitFullscreen()).catch(() => {});
      }
    }
    async function requestLandscape() {
      if (disposed || !wanted || busy) return;
      const generation = epoch; busy = true; enter.disabled = true;
      try {
        if (!doc.fullscreenElement && typeof doc.documentElement.requestFullscreen === 'function') {
          await doc.documentElement.requestFullscreen(); ownedFullscreen = doc.fullscreenElement === doc.documentElement;
        }
        if (disposed || generation !== epoch || !wanted) { release(); return; }
        if (root.screen && root.screen.orientation && typeof root.screen.orientation.lock === 'function') {
          await root.screen.orientation.lock('landscape'); ownedLock = true;
          if (disposed || generation !== epoch || !wanted) { release(); return; }
        }
      } catch (_) {
        // Unsupported APIs leave a usable manual-rotation and portrait path.
      } finally {
        busy = false; enter.disabled = false;
        if (!disposed && wanted && portrait()) copy.textContent = '请将手机横过来。也可以先用竖屏继续，进度会保留。';
        show();
      }
    }
    enter.addEventListener('click', requestLandscape);
    dismiss.addEventListener('click', () => { dismissed = true; show(); });
    root.addEventListener('resize', show);
    const api = {
      get disposed() { return disposed; },
      update(value) {
        const next = Boolean(value && value.landscapePreferred);
        if (next !== wanted) {
          wanted = next; epoch++;
          if (!wanted) { dismissed = false; release(); }
        }
        show();
      },
      snapshot() { return { wanted, visible: !layer.hidden, dismissed, busy, ownedLock, ownedFullscreen }; },
      dispose() { if (disposed) return; disposed = true; epoch++; release(); root.removeEventListener('resize', show); layer.remove(); }
    };
    root.__GODOT_755_ORIENTATION__ = api;
    return api;
  };
})(window);
