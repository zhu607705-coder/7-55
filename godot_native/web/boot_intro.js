(function (root) {
  'use strict';
  // Loading presentation only. The existing verified transport and Engine
  // promise chain remain the authority for readiness and the Start gesture.
  root.install755BootIntro = function () {
    const previous = root.__GODOT_755_BOOT_INTRO__;
    if (previous && !previous.disposed) return previous;
    const doc = root.document;
    const layer = doc.getElementById('loading');
    const toggle = doc.getElementById('boot-motion-toggle');
    if (!layer) return null;
    const preference = typeof root.matchMedia === 'function'
      ? root.matchMedia('(prefers-reduced-motion: reduce)') : null;
    const transitions = {
      loading: ['loading', 'ready', 'error'],
      ready: ['ready', 'starting', 'error'],
      starting: ['starting', 'running', 'error'],
      error: ['error'],
      running: ['running']
    };
    let stage = 'loading', phase = 'preparing';
    let current = 0, total = 0, manuallyPaused = false, disposed = false;
    let reduced = Boolean(preference && preference.matches);
    function animated() { return layer.dataset.bootAnimation === 'true'; }
    function ratio() {
      return total > 0 && current <= total ? current / total : null;
    }
    function motion() {
      if (disposed || stage === 'ready' || stage === 'starting' || stage === 'running' || stage === 'error') return 'stopped';
      if (!animated()) return 'off';
      if (reduced) return 'reduced';
      return manuallyPaused || doc.hidden ? 'paused' : 'running';
    }
    function render() {
      layer.dataset.introState = stage;
      layer.dataset.introPhase = phase;
      layer.dataset.bootMotion = motion();
      layer.dataset.bootProgress = ratio() === null ? 'unknown' : 'known';
      layer.style.setProperty('--boot-real-progress', ratio() === null ? '0' : String(ratio()));
      layer.setAttribute('aria-busy', String(stage === 'loading' || stage === 'starting'));
      if (toggle) {
        toggle.hidden = disposed || !animated() || reduced || stage !== 'loading';
        toggle.setAttribute('aria-pressed', String(manuallyPaused));
        toggle.textContent = manuallyPaused ? '继续动效' : '暂停动效';
      }
    }
    function visibilityChanged() { if (!disposed) render(); }
    function preferenceChanged(event) {
      if (disposed) return;
      reduced = Boolean(event.matches);
      render();
    }
    function toggleMotion() {
      if (disposed || reduced || !animated() || stage === 'running' || stage === 'error') return;
      manuallyPaused = !manuallyPaused;
      render();
    }
    function releaseListeners() {
      doc.removeEventListener('visibilitychange', visibilityChanged);
      if (toggle) toggle.removeEventListener('click', toggleMotion);
      if (preference) {
        if (typeof preference.removeEventListener === 'function') preference.removeEventListener('change', preferenceChanged);
        else if (typeof preference.removeListener === 'function') preference.removeListener(preferenceChanged);
      }
    }
    const api = {
      get disposed() { return disposed; },
      update(value) {
        if (!value) return;
        if (disposed) {
          // The original shell can expose a post-handoff WebGL/engine error.
          // Keep that static error visible without restarting animation or
          // subscribing to document/media events again.
          if (stage === 'running' && value.stage === 'error') {
            stage = 'error'; phase = 'error'; render();
          }
          return;
        }
        const next = value.stage || stage;
        if (!transitions[stage].includes(next)) return;
        stage = next;
        if (stage === 'loading' && ['preparing', 'downloading', 'verifying'].includes(value.phase)) phase = value.phase;
        else if (stage !== 'loading') phase = stage;
        // Complete bytes do not imply verified resources, a ready engine or
        // story progress. Only the original promise chain can send ready.
        render();
        if (stage === 'error' || stage === 'running') {
          releaseListeners();
          disposed = true;
        }
      },
      progress(received, expected) {
        if (disposed || stage !== 'loading' || !Number.isFinite(received) || received < 0 || !Number.isFinite(expected) || expected < 0) return;
        current = received;
        total = expected;
        render();
      },
      snapshot() {
        return { stage, phase, current, total, ratio: ratio(), reducedMotion: reduced, manuallyPaused, documentHidden: Boolean(doc.hidden), motion: motion(), disposed };
      },
      dispose() {
        if (disposed) return;
        disposed = true;
        releaseListeners();
        render();
      }
    };
    doc.addEventListener('visibilitychange', visibilityChanged);
    if (toggle) toggle.addEventListener('click', toggleMotion);
    if (preference) {
      if (typeof preference.addEventListener === 'function') preference.addEventListener('change', preferenceChanged);
      else if (typeof preference.addListener === 'function') preference.addListener(preferenceChanged);
    }
    root.__GODOT_755_BOOT_INTRO__ = api;
    render();
    return api;
  };
  // The DOM loading surface already exists here. Begin reduced-motion and
  // background handling before the following engine script has downloaded.
  root.install755BootIntro();
})(window);
