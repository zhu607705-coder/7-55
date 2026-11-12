import { LANES, SECTIONS, MODES, OBSTACLES, WALLS, FINISH, floorAt, elevationAt, sectionAt, adjacentToWall } from './course.js';

const clamp = (value, min, max) => Math.min(max, Math.max(min, value));
const JUMP_VELOCITY = 8.3;
const GRAVITY = 20.4;
const RADIUS = .28;
const RECOVERY = .63;
export const FIXED_STEP = 1 / 120;

function overlapsLane(x, obstacle) {
  return Math.abs(x - obstacle.x) < obstacle.span * .5 + RADIUS;
}

export class Runner {
  constructor(mode = 'standard') {
    this.mode = mode;
    this.reset();
  }

  reset() {
    this.phase = 'ready';
    this.elapsed = 0;
    this.falls = 0;
    this.checkpoint = 0;
    this.events = [];
    this.recoverFrom = '';
    this.placeAtCheckpoint();
  }

  placeAtCheckpoint() {
    const start = SECTIONS[this.checkpoint];
    this.s = start.start;
    this.x = 0;
    this.lane = 1;
    this.y = elevationAt(start.start);
    this.vy = 0;
    this.vx = 0;
    this.speed = start.speed * MODES[this.mode].speed;
    this.grounded = true;
    this.coyote = 0;
    this.jumpBuffer = 0;
    this.slideBuffer = 0;
    this.slide = 0;
    this.vault = null;
    this.wall = null;
    this.landing = 0;
    this.stride = 0;
    this.recovery = 0;
  }

  start() {
    if (this.phase !== 'ready') return;
    this.phase = 'running';
    this.events.push({ type: 'start' });
  }

  action(action) {
    if (this.phase !== 'running') return;
    if (action === 'left' || action === 'right') {
      if (!this.wall) this.lane = clamp(this.lane + (action === 'left' ? -1 : 1), 0, LANES.length - 1);
    } else if (action === 'jump') {
      this.jumpBuffer = MODES[this.mode].buffer;
    } else if (action === 'slide') {
      this.slideBuffer = .17;
    } else if (action === 'restart') {
      this.fail('重新起跑');
    }
  }

  fail(reason) {
    if (this.phase !== 'running') return;
    this.falls += 1;
    this.recoverFrom = reason;
    this.recovery = RECOVERY;
    this.phase = 'recovering';
    this.events.push({ type: 'fall', reason });
  }

  launch(type = 'jump', velocity = JUMP_VELOCITY) {
    this.grounded = false;
    this.coyote = 0;
    this.jumpBuffer = 0;
    this.slide = 0;
    this.vy = velocity;
    this.events.push({ type });
  }

  startJump() {
    const wall = WALLS.find(w => this.s >= w.start && this.s <= w.gap.start + .9 && adjacentToWall(this.x, w));
    if (wall && !this.vault && this.y > elevationAt(this.s) - .23) {
      this.wall = wall;
      this.launch('wall', 0);
      return;
    }
    if (!this.grounded && this.coyote <= 0) return;
    const hurdle = OBSTACLES.find(o => o.type === 'hurdle' && o.start > this.s &&
      o.start - this.s <= MODES[this.mode].vaultWindow && overlapsLane(this.x, o));
    if (hurdle) {
      this.vault = { obstacle: hurdle, from: this.s, to: hurdle.end + 1.05, height: elevationAt(hurdle.start) };
      this.launch('vault', 0);
    } else {
      this.launch();
    }
  }

  leaveWall() {
    const side = this.wall.side;
    this.wall = null;
    this.lane = side > 0 ? 2 : 0;
    this.launch('wall-jump', 4.4);
  }

  step(dt) {
    if (this.phase === 'recovering') {
      this.elapsed += dt;
      this.recovery -= dt;
      if (this.recovery <= 0) {
        this.placeAtCheckpoint();
        this.phase = 'running';
        this.events.push({ type: 'respawn' });
      }
      return;
    }
    if (this.phase !== 'running') return;
    this.elapsed += dt;
    const mode = MODES[this.mode];
    const baseSpeed = SECTIONS[sectionAt(this.s)].speed * mode.speed;
    const runningSpeed = baseSpeed * (this.slide > 0 ? 1.04 : this.wall ? 1.05 : 1);
    this.speed += (runningSpeed - this.speed) * Math.min(1, dt * 8);

    if (this.jumpBuffer > 0) {
      if (this.wall) {
        if (this.s >= this.wall.gap.end - 1.2) this.leaveWall();
      } else if (!this.vault) {
        this.startJump();
      }
    }
    if (this.slideBuffer > 0 && this.grounded && this.slide <= 0) {
      this.slide = mode.slide;
      this.slideBuffer = 0;
      this.events.push({ type: 'slide' });
    }

    const lastS = this.s;
    const lastY = this.y;
    const lastX = this.x;
    this.s += this.speed * dt;
    const desiredX = this.wall ? this.wall.side * 3.32 : LANES[this.lane];
    this.x += (desiredX - this.x) * (1 - Math.exp(-dt * (this.grounded ? 15 : 11)));
    this.vx = (this.x - lastX) / dt;

    const floor = floorAt(this.s, this.x);
    const baseline = elevationAt(this.s);
    this.landing = Math.max(0, this.landing - dt * 5.5);
    if (this.wall) {
      this.y += (baseline + .94 - this.y) * (1 - Math.exp(-dt * 13));
      if (this.s >= this.wall.release) this.leaveWall();
    } else if (this.vault) {
      const p = clamp((this.s - this.vault.from) / (this.vault.to - this.vault.from), 0, 1);
      this.y = this.vault.height + Math.sin(p * Math.PI) * 1.12;
      if (p === 1) {
        this.vault = null;
        if (floor !== null) this.land(floor);
      }
    } else {
      if (this.grounded) {
        if (floor === null) {
          this.grounded = false;
          this.coyote = mode.coyote;
        } else this.y = floor;
      }
      if (!this.grounded) {
        this.vy -= GRAVITY * dt;
        this.y += this.vy * dt;
        if (floor !== null && this.vy <= 0 && this.y <= floor && lastY >= floor - .20) this.land(floor);
      }
    }

    for (const obstacle of OBSTACLES) {
      if (this.s + RADIUS < obstacle.start || lastS - RADIUS > obstacle.end || !overlapsLane(this.x, obstacle)) continue;
      const clearance = this.y - elevationAt(obstacle.start);
      if (obstacle.type === 'hurdle' && (this.vault?.obstacle === obstacle || clearance >= .87)) continue;
      if (obstacle.type === 'beam' && this.slide > 0 && clearance <= .09) continue;
      this.fail(obstacle.type === 'beam' ? '低梁 · 按下滑过' : obstacle.type === 'barrier' ? '机组 · 从亮灯一侧绕过' : '低栏 · 起跳或撑越');
      return;
    }

    if (this.y < baseline - 3) {
      this.fail('踩空 · 看准落脚处');
      return;
    }
    this.jumpBuffer = Math.max(0, this.jumpBuffer - dt);
    this.slideBuffer = Math.max(0, this.slideBuffer - dt);
    this.slide = Math.max(0, this.slide - dt);
    this.coyote = Math.max(0, this.coyote - dt);
    const oldStride = Math.floor(this.stride * 2);
    if (this.grounded || this.wall) this.stride += this.speed * dt / 2.48;
    if (Math.floor(this.stride * 2) !== oldStride && this.slide <= 0) this.events.push({ type: 'step' });

    const section = sectionAt(this.s);
    if (section > this.checkpoint && this.grounded) {
      this.checkpoint = section;
      this.events.push({ type: 'checkpoint' });
    }
    if (this.s >= FINISH && this.grounded && this.checkpoint === SECTIONS.length - 1) {
      this.phase = 'finished';
      this.s = FINISH;
      this.events.push({ type: 'finish' });
    }
  }

  land(height) {
    this.y = height;
    this.vy = 0;
    this.grounded = true;
    this.landing = 1;
    this.events.push({ type: 'land' });
  }

  get pose() {
    if (this.wall) return 'wall';
    if (this.vault) return 'vault';
    if (!this.grounded) return 'jump';
    if (this.slide > 0) return 'slide';
    return this.phase === 'ready' || this.phase === 'finished' ? 'idle' : 'run';
  }
}
