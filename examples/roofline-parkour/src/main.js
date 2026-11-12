import './style.css';
import { FEATURES, FINISH, MODES, SECTIONS, sectionAt } from './course.js';
import { FIXED_STEP, Runner } from './runner.js';
import { createView } from './visual.js';

const get = id => document.getElementById(id);
const root = get('game');
const canvas = get('scene');
const cue = get('cue');
const primary = get('primary');
const recordKey = mode => `roofline-best-${FINISH}-${mode}`;
get('route-length').textContent = FINISH;
for (const section of SECTIONS.slice(1)) {
  const marker = document.createElement('b');
  marker.style.left = (section.start / FINISH * 100) + '%';
  get('route-line').append(marker);
}
const reduced = matchMedia('(prefers-reduced-motion: reduce)').matches;
const model = new Runner();
const learned = new Set();
const modeButtons = [...document.querySelectorAll('[data-mode]')];
let view;
let paused = false;
let notice = '';
let noticeUntil = 0;
let best = loadBest(model.mode);
let muted = false;
let audio;
let clock = 0;

function loadBest(mode) {
  try {
    return Number(localStorage.getItem(recordKey(mode))) || 0;
  } catch {
    return 0;
  }
}

function sound(type) {
  if (!audio || muted || audio.state !== 'running') return;
  const settings = {
    step: [101, 66, .042, .025],
    jump: [206, 378, .15, .075],
    vault: [265, 520, .13, .055],
    land: [120, 61, .11, .085],
    slide: [153, 54, .20, .055],
    wall: [253, 407, .16, .06],
    'wall-jump': [409, 590, .13, .06],
    checkpoint: [390, 698, .26, .067],
    fall: [169, 73, .18, .09],
    finish: [430, 788, .65, .08],
  }[type];
  if (!settings) return;
  const [from, to, duration, volume] = settings;
  const time = audio.currentTime;
  const wave = audio.createOscillator();
  const gain = audio.createGain();
  wave.type = ['slide', 'land', 'step'].includes(type) ? 'triangle' : 'sine';
  wave.frequency.setValueAtTime(from, time);
  wave.frequency.exponentialRampToValueAtTime(to, time + duration);
  gain.gain.setValueAtTime(.0001, time);
  gain.gain.exponentialRampToValueAtTime(volume, time + .012);
  gain.gain.exponentialRampToValueAtTime(.0001, time + duration);
  wave.connect(gain).connect(audio.destination);
  wave.start(time);
  wave.stop(time + duration);
}

function unlockSound() {
  const Audio = window.AudioContext || window.webkitAudioContext;
  if (Audio && !audio) audio = new Audio();
  if (audio?.state === 'suspended') audio.resume().catch(() => {});
}

function setMenu() {
  const waiting = model.phase === 'ready';
  const finished = model.phase === 'finished';
  const shown = waiting || finished || paused;
  get('menu').hidden = !shown;
  get('menu').dataset.state = finished ? 'finish' : paused ? 'paused' : 'start';
  get('veil').hidden = !shown;
  get('hud').hidden = waiting || finished;
  get('touch').hidden = shown || model.phase !== 'running';
  get('pause').disabled = paused;
  get('modes').hidden = !waiting;
  get('controls').hidden = !waiting;
  get('pause-actions').hidden = !paused && !finished;
  get('restart').hidden = finished;
  get('sound').hidden = finished;
  get('menu-title').textContent = paused ? '已暂停' : finished ? '抵达信号塔' : '追光线';
  if (paused) get('menu-copy').textContent = '继续这一趟，或回到起点。';
  else if (finished) get('menu-copy').textContent =
    `${model.elapsed.toFixed(2)} 秒 · ${model.falls ? '失误 ' + model.falls + ' 次' : '无失误'} · 最快 ${best.toFixed(2)} 秒`;
  else get('menu-copy').textContent = model.mode === 'challenge' ? '速度更快，起跳和滑铲要更准。' : '穿过屋顶和检修桥，跑到信号塔。';
  primary.textContent = paused ? '继续' : finished ? '再跑一次' : '起跑';
}

function reset(toStart) {
  model.reset();
  paused = false;
  notice = '';
  noticeUntil = 0;
  if (toStart) model.start();
  setMenu();
}

function togglePause() {
  if (!['running', 'recovering'].includes(model.phase)) return;
  paused = !paused;
  setMenu();
  if (paused) primary.focus({ preventScroll: true });
  else document.activeElement?.blur();
}

primary.addEventListener('click', () => {
  if (!view) return;
  unlockSound();
  if (paused) togglePause();
  else if (model.phase === 'finished') reset(true);
  else {
    model.start();
    setMenu();
  }
  document.activeElement?.blur();
});
for (const button of modeButtons) button.addEventListener('click', () => {
  model.mode = button.dataset.mode;
  best = loadBest(model.mode);
  for (const candidate of modeButtons) candidate.setAttribute('aria-pressed', String(candidate === button));
  reset(false);
});
get('pause').addEventListener('click', togglePause);
get('restart').addEventListener('click', () => reset(true));
get('quit').addEventListener('click', () => reset(false));
get('sound').addEventListener('click', () => {
  muted = !muted;
  get('sound').setAttribute('aria-pressed', String(muted));
  get('sound').textContent = muted ? '开启声音' : '静音';
});
document.addEventListener('visibilitychange', () => {
  if (document.hidden && !paused) togglePause();
});

const keys = {
  KeyA: 'left', ArrowLeft: 'left', KeyD: 'right', ArrowRight: 'right',
  Space: 'jump', KeyW: 'jump', ArrowUp: 'jump',
  KeyS: 'slide', ArrowDown: 'slide', ShiftLeft: 'slide', ShiftRight: 'slide',
  KeyR: 'restart',
};
document.addEventListener('keydown', event => {
  if (event.repeat || event.altKey || event.metaKey || event.ctrlKey) return;
  if (event.code === 'Escape') {
    event.preventDefault();
    togglePause();
  } else if (!paused && model.phase === 'running' && keys[event.code]) {
    event.preventDefault();
    model.action(keys[event.code]);
  }
});
for (const button of document.querySelectorAll('[data-action]')) {
  button.addEventListener('pointerdown', event => {
    event.preventDefault();
    if (!paused) model.action(button.dataset.action);
  });
  button.addEventListener('click', event => {
    if (!event.detail && !paused) model.action(button.dataset.action);
  });
}
const fingers = new Map();
canvas.addEventListener('pointerdown', event => {
  if (event.pointerType === 'mouse' || paused || model.phase !== 'running') return;
  canvas.setPointerCapture(event.pointerId);
  fingers.set(event.pointerId, { x: event.clientX, y: event.clientY, fired: false });
});
canvas.addEventListener('pointermove', event => {
  const start = fingers.get(event.pointerId);
  if (!start || start.fired || paused) return;
  const dx = event.clientX - start.x;
  const dy = event.clientY - start.y;
  if (Math.max(Math.abs(dx), Math.abs(dy)) < 23) return;
  start.fired = true;
  model.action(Math.abs(dx) > Math.abs(dy) ? (dx > 0 ? 'right' : 'left') : (dy > 0 ? 'slide' : 'jump'));
});
canvas.addEventListener('pointerup', event => {
  const start = fingers.get(event.pointerId);
  fingers.delete(event.pointerId);
  if (start && !start.fired && !paused) model.action('jump');
});
canvas.addEventListener('pointercancel', event => fingers.delete(event.pointerId));
canvas.addEventListener('lostpointercapture', event => fingers.delete(event.pointerId));

function drainEvents() {
  for (const event of model.events.splice(0)) {
    sound(event.type);
    if (['jump', 'vault', 'wall', 'wall-jump', 'slide'].includes(event.type)) learned.add(event.type);
    if (event.type === 'checkpoint') {
      notice = '检查点';
      noticeUntil = model.elapsed + 1.35;
    } else if (event.type === 'fall' || event.type === 'respawn') {
      if (event.type === 'respawn') {
        notice = '从' + SECTIONS[model.checkpoint].name + '重新起跑';
        noticeUntil = model.elapsed + 1.15;
      }
      setMenu();
    } else if (event.type === 'finish') {
      if (!best || model.elapsed < best) {
        best = model.elapsed;
        try { localStorage.setItem(recordKey(model.mode), String(best)); } catch { /* Session result still appears. */ }
      }
      setMenu();
      primary.focus({ preventScroll: true });
    }
  }
}

function updateHud() {
  root.dataset.phase = model.phase;
  root.dataset.pose = model.pose;
  root.dataset.distance = model.s.toFixed(2);
  root.dataset.lane = model.lane;
  root.dataset.checkpoint = model.checkpoint;
  root.dataset.falls = model.falls;
  const distance = Math.floor(model.s);
  get('clock').value = model.elapsed.toFixed(2);
  get('distance').textContent = distance;
  get('route-fill').style.width = (model.s / FINISH * 100).toFixed(2) + '%';
  get('section').textContent = SECTIONS[sectionAt(model.s)].name;
  let hint = '';
  if (!paused && model.phase === 'recovering') {
    hint = model.recoverFrom;
  } else if (!paused && model.phase === 'running') {
    if (model.wall && model.s > model.wall.gap.end - 5 && !learned.has('wall-jump')) hint = '再跳一步，回到屋顶';
    else if (model.elapsed < noticeUntil) hint = notice;
    else {
      const next = FEATURES.find(item => item.at >= model.s - 1 && item.at - model.s < 11);
      if (next?.type === 'bridge') hint = next.x > 0 ? '窄桥在右侧' : '窄桥在中间';
      else if (next?.type === 'hurdle' && !learned.has('vault')) hint = '低栏 · 临近时起跳';
      else if (next?.type === 'gap' && !learned.has('jump')) hint = '屋沿 · 跳到对面';
      else if (next?.type === 'beam' && !learned.has('slide')) hint = '低梁 · 滑过去';
      else if (next?.type === 'wall' && !learned.has('wall')) hint = next.wall.side > 0 ? '靠右侧墙面起跳' : '靠左侧墙面起跳';
    }
  }
  cue.hidden = !hint;
  if (cue.textContent !== hint) cue.textContent = hint;
}

try {
  view = createView(canvas, reduced);
} catch (error) {
  console.error(error);
  get('menu-copy').textContent = '无法启动 3D 画面。请在支持 WebGL 2 的浏览器中打开。';
  primary.disabled = true;
}

if (view) {
  let previous = performance.now();
  let accumulator = 0;
  const resize = new ResizeObserver(() => view.resize());
  resize.observe(canvas);
  setMenu();
  function frame(now) {
    const dt = Math.min((now - previous) / 1000, .12);
    previous = now;
    if (!paused && !document.hidden) {
      accumulator += dt;
      while (accumulator >= FIXED_STEP) {
        model.step(FIXED_STEP);
        accumulator -= FIXED_STEP;
      }
      clock += dt;
    } else accumulator = 0;
    drainEvents();
    updateHud();
    view.draw(model, dt, clock);
    requestAnimationFrame(frame);
  }
  requestAnimationFrame(frame);
}
