export interface Notice {
  id: number;
  text: string;
  tone: "system" | "xiaoying" | "task";
  durationMs: number;
}

/** Presentation only. Reading time runs while one notice is actually visible. */
export class NoticeQueue {
  private active: Notice | null = null;
  private readonly pending: Notice[] = [];
  private paused = false;
  private remainingMs = 0;
  private deadline = 0;

  enqueue(notice: Notice, now: number): void {
    this.advance(now);
    if ([this.active, ...this.pending].some(item => item?.text === notice.text && item.tone === notice.tone)) return;
    this.pending.push(notice);
    if (!this.active) this.startNext(now);
  }

  setPaused(paused: boolean, now: number): void {
    if (paused === this.paused) return;
    if (!this.paused) {
      this.advance(now);
      this.remainingMs = this.active ? Math.max(0, this.deadline - now) : 0;
    }
    this.paused = paused;
    if (!paused && this.active) this.deadline = now + this.remainingMs;
  }

  advance(now: number): void {
    if (this.paused || !this.active || now < this.deadline) return;
    this.active = null;
    // A backgrounded timer cannot consume notices the player never saw.
    this.startNext(now);
  }

  visible(now: number): Notice | null {
    this.advance(now);
    return this.paused || !this.active ? null : { ...this.active, durationMs: Math.max(1, this.deadline - now) };
  }

  private startNext(now: number): void {
    this.active = this.pending.shift() ?? null;
    this.remainingMs = this.active?.durationMs ?? 0;
    this.deadline = now + this.remainingMs;
  }
}
