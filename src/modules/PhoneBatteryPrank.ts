export type BatteryPrankNotice = { kind: "warning" | "joke"; text: string; seconds: number };

/** Presentation only: never changes battery, save state or navigation. */
export class PhoneBatteryPrank {
  private deadline: number | null = null;
  private used = false;

  consumeReserve(now: number, percent: number): boolean {
    if (percent !== 1 || this.used) return false;
    this.used = true;
    this.deadline = now + 10_000;
    return true;
  }

  reset(): void { this.deadline = null; this.used = false; }

  view(now: number): BatteryPrankNotice | null {
    if (this.deadline === null || now >= this.deadline + 3500) return null;
    if (now >= this.deadline) return { kind: "joke", text: "吓吓你的", seconds: 0 };
    return {
      kind: "warning",
      text: "请在 10秒之内充电，不然手机就会自动关机。",
      seconds: Math.ceil((this.deadline - now) / 1000)
    };
  }
}
