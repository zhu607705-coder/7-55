(function (root) {
  'use strict';
  // Godot renders the requested surface immediately. The system fullscreen
  // request is optional and only uses the activation already supplied by play.
  root.install755SceneOrientation = function () {
    if (root.__GODOT_755_ORIENTATION__ && !root.__GODOT_755_ORIENTATION__.disposed) return root.__GODOT_755_ORIENTATION__;
    const doc = root.document;
    let wanted = false, portraitRequired = false, disposed = false;
    let epoch = 0, ownedFullscreen = false, ownedLock = false, busy = false;
    function release() {
      if (ownedLock) {
        ownedLock = false;
        try { root.screen.orientation.unlock(); } catch (_) {}
      }
      if (ownedFullscreen) {
        ownedFullscreen = false;
        if (doc.fullscreenElement === doc.documentElement && doc.exitFullscreen) {
          Promise.resolve(doc.exitFullscreen()).catch(() => {});
        }
      }
    }
    async function requestLandscape() {
      if (busy || doc.fullscreenElement || doc.fullscreenEnabled === false || !doc.documentElement.requestFullscreen) return;
      const generation = epoch;
      busy = true;
      try {
        await doc.documentElement.requestFullscreen({ navigationUI: 'hide' });
        ownedFullscreen = doc.fullscreenElement === doc.documentElement;
        if (disposed || generation !== epoch || !wanted) { release(); return; }
        if (ownedFullscreen && root.screen?.orientation?.lock) {
          await root.screen.orientation.lock('landscape');
          ownedLock = true;
          if (disposed || generation !== epoch || !wanted) release();
        }
      } catch (_) {
        // The same Godot surface works in the browser viewport.
      } finally {
        busy = false;
      }
    }
    const api = {
      get disposed() { return disposed; },
      update(value) {
        if (disposed) return;
        const next = Boolean(value?.landscapePreferred);
        portraitRequired = !next && Boolean(value?.portraitRequired);
        if (next === wanted) return;
        wanted = next;
        epoch++;
        if (!wanted) {
          release();
          return;
        }
        if (root.navigator?.userActivation?.isActive && root.matchMedia?.('(any-pointer: coarse)').matches) requestLandscape();
      },
      snapshot() { return { wanted, portraitRequired, visible: false, busy, ownedFullscreen, ownedLock }; },
      dispose() { if (!disposed) { disposed = true; epoch++; release(); } }
    };
    root.__GODOT_755_ORIENTATION__ = api;
    return api;
  };
})(window);
