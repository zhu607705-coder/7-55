import Phaser from "phaser";
import { RPG_PIXEL_FONT_FAMILY } from "./RpgRenderResolution";
import { FISHING_BOARD as BOARD, FISHING_LANES, fishingTileGeometry } from "./QizhenFishingRhythmLayout";
import type {
  QizhenFishingFailReason, QizhenFishingJudgment, QizhenFishingNote,
  QizhenFishingResult, QizhenFishingRhythmModel, QizhenFishingWarningKind,
} from "./QizhenFishingRhythmModel";

export interface QizhenFishingRhythmVisualOptions {
  scene: Phaser.Scene;
  model: QizhenFishingRhythmModel;
  anchor: { x: number; y: number };
  lineFrom?: () => { x: number; y: number };
  targetLabel: string;
  reducedMotion: boolean;
  depth?: number;
}
const WORDS = { perfect: "精准", great: "良好", good: "命中", miss: "错过" } as const;
const COLORS = { perfect: 0xffd77e, great: 0x94dfa4, good: 0x9edaff, miss: 0xff9e8a } as const;

/** One screen-space root, including tiles and keys. No stencil masks or
 * independently transformed notes. The existing model owns all judgments.
 */
export class QizhenFishingRhythmVisual {
  private readonly scene: Phaser.Scene;
  private readonly model: QizhenFishingRhythmModel;
  private readonly root: Phaser.GameObjects.Container;
  private readonly tiles: Phaser.GameObjects.Graphics;
  private readonly feedback: Phaser.GameObjects.Graphics;
  private readonly water: Phaser.GameObjects.Graphics;
  private readonly status: Phaser.GameObjects.Text;
  private readonly judgment: Phaser.GameObjects.Text;
  private readonly cue: Phaser.GameObjects.Text;
  private readonly noteLabels: Phaser.GameObjects.Text[];
  private readonly firstVisible = new Map<number, number>();
  private readonly timers = new Set<Phaser.Time.TimerEvent>();
  private drawnTiles: ReturnType<typeof fishingTileGeometry>[] = [];
  private flashUntil = 0;
  private flashColor = 0xf4f1df;
  private flashAction: QizhenFishingNote["action"] | null = null;
  private destroyed = false;
  private resultShown = false;
  private statusCache = "";

  constructor(private readonly options: QizhenFishingRhythmVisualOptions) {
    this.scene = options.scene;
    this.model = options.model;
    this.water = this.scene.add.graphics().setDepth(2600);
    this.root = this.scene.add.container(0, 0).setScrollFactor(0).setDepth(options.depth ?? 10000);
    const background = this.scene.add.graphics();
    background.fillStyle(0x06131d, 0.5).fillRect(0, 72, 960, 468);
    background.fillStyle(0x0b1c29, 0.98).fillRoundedRect(BOARD.left, BOARD.top, BOARD.right - BOARD.left, BOARD.bottom - BOARD.top, 8);
    background.lineStyle(2, 0x7296a5, 0.9).strokeRoundedRect(BOARD.left, BOARD.top, BOARD.right - BOARD.left, BOARD.bottom - BOARD.top, 8);
    for (const lane of FISHING_LANES) {
      background.fillStyle(0x142c3b, 1).fillRect(lane.x - 61, BOARD.noteTop, 122, BOARD.noteBottom - BOARD.noteTop);
      background.lineStyle(1, lane.color, 0.22).lineBetween(lane.x, BOARD.noteTop, lane.x, BOARD.noteBottom);
      background.fillStyle(0x203849, 1).fillRoundedRect(lane.x - 61, BOARD.keyTop, 122, BOARD.keyBottom - BOARD.keyTop, 4);
      background.lineStyle(2, lane.color, 0.9).strokeRoundedRect(lane.x - 61, BOARD.keyTop, 122, BOARD.keyBottom - BOARD.keyTop, 4);
    }
    this.root.add(background);
    this.text(480, 103, `节奏钓取 · ${options.targetLabel}`, 17);
    this.status = this.text(480, 127, "", 12);
    this.text(480, 158, "短块点按 · 长条按住到尾端过线", 12, "#bacdd5");
    this.tiles = this.scene.add.graphics();
    this.root.add(this.tiles);
    this.feedback = this.scene.add.graphics();
    this.root.add(this.feedback);
    this.noteLabels = FISHING_LANES.map((lane) => this.text(lane.x, 0, lane.key, 18, "#152535").setVisible(false));
    for (const lane of FISHING_LANES) {
      this.text(lane.x, BOARD.keyTop + 15, lane.key, 24);
      this.text(lane.x, BOARD.keyTop + 36, lane.label, 10, "#c2d8df");
    }
    this.judgment = this.text(746, 322, "", 18);
    this.cue = this.text(480, 510, "", 12, "#e4edf1");
    this.update();
  }

  private text(x: number, y: number, value: string, size: number, color = "#f4f1df") {
    const object = this.scene.add.text(x, y, value, {
      fontFamily: RPG_PIXEL_FONT_FAMILY, fontSize: `${size}px`, color,
    }).setOrigin(0.5);
    this.root.add(object);
    return object;
  }

  update(): void {
    if (this.destroyed) return;
    this.drawWater();
    if (this.resultShown) return;
    const elapsed = this.model.elapsedSec;
    const tension = Math.round(this.model.tension);
    const alert = tension < 20 ? " · 松线 ▼" : tension > 80 ? " · 绷紧 ▲" : "";
    const summary = `${this.model.judgedCount}/${this.model.totalNotes}    张力 ${tension}${alert}    连击 ${this.model.combo}${this.model.assist ? " · 辅助" : ""}`;
    if (summary !== this.statusCache) {
      this.status.setText(summary);
      this.statusCache = summary;
    }
    this.tiles.clear();
    this.drawnTiles = [];
    this.noteLabels.forEach((label) => label.setVisible(false));
    const next = this.model.notes.find((note) => note.judgment === null);
    for (const note of this.model.notes) {
      if (note.judgment !== null && !note.holding) continue;
      if (elapsed < note.spawnSec && note !== next) continue;
      if (!this.firstVisible.has(note.index)) this.firstVisible.set(note.index, elapsed);
      const tile = fishingTileGeometry(note, elapsed, this.firstVisible.get(note.index)!);
      if (tile.height <= 0) continue;
      this.drawnTiles.push(tile);
      const laneIndex = FISHING_LANES.findIndex((lane) => lane.action === note.action);
      const lane = FISHING_LANES[laneIndex];
      this.tiles.fillStyle(note.holding ? lane.color : 0xf8f2df, 1).fillRect(tile.x, tile.y, tile.width, tile.height);
      this.tiles.lineStyle(2, lane.color, 1).strokeRect(tile.x + 1, tile.y + 1, tile.width - 2, Math.max(0, tile.height - 2));
      const stripeY = Math.min(BOARD.noteBottom - 5, tile.headY + 7);
      if (stripeY >= tile.y && stripeY + 4 <= tile.y + tile.height) {
        this.tiles.fillStyle(lane.color, 1).fillRect(tile.x + 5, stripeY, tile.width - 10, 4);
      }
      const label = this.noteLabels[laneIndex];
      if (!label.visible && tile.headY >= BOARD.noteTop + 12 && tile.headY <= BOARD.noteBottom - 12) {
        label.setY(tile.headY - 1).setVisible(true);
      }
    }
    this.drawJudgment();
    const holding = this.model.notes.some((note) => note.holding);
    this.cue.setText(holding ? "保持按住" : next ? "到线时按对应键" : "收线中");
    if (this.scene.time.now >= this.flashUntil) this.judgment.setText("");
  }

  private drawJudgment(): void {
    const g = this.feedback.clear();
    const active = this.scene.time.now < this.flashUntil;
    const color = active ? this.flashColor : 0xf4f1df;
    g.lineStyle(5, color, 1).lineBetween(BOARD.left + 8, BOARD.judgmentY, BOARD.right - 8, BOARD.judgmentY);
    for (const lane of FISHING_LANES) {
      if (this.model.notes.some((note) => note.action === lane.action && note.holding)
        || (active && this.flashAction === lane.action)) {
        g.fillStyle(lane.color, 0.3).fillRect(lane.x - 59, BOARD.keyTop + 2, 118, BOARD.keyBottom - BOARD.keyTop - 4);
      }
    }
  }

  private drawWater(): void {
    const g = this.water.clear();
    const { x, y } = this.options.anchor;
    const from = this.options.lineFrom?.();
    if (from) g.lineStyle(2, 0xd7e7df, 0.8).lineBetween(from.x, from.y, x, y);
    g.fillStyle(0xe75f50, 1).fillCircle(x, y, 7);
    g.fillStyle(0xfff3d2, 1).fillRect(x - 3, y - 8, 6, 5);
    const pulse = this.options.reducedMotion ? 0 : Math.sin(this.scene.time.now / 240) * 3;
    g.lineStyle(2, 0xb1e0e7, 0.5).strokeEllipse(x, y + 4, 38 + pulse, 16 + pulse);
  }

  notifyJudgment(note: QizhenFishingNote, judgment: QizhenFishingJudgment, _errorMs: number): void {
    if (this.destroyed) return;
    this.flashUntil = this.scene.time.now + 380;
    this.flashColor = COLORS[judgment];
    this.flashAction = note.action;
    this.judgment.setText(WORDS[judgment]).setColor(Phaser.Display.Color.IntegerToColor(this.flashColor).rgba);
  }

  notifyHoldBroken(note: QizhenFishingNote): void {
    if (this.destroyed) return;
    this.notifyJudgment(note, "miss", 0);
    this.judgment.setText("松开过早");
  }

  notifyWarning(_kind: QizhenFishingWarningKind, _tension: number): void {
    // Numeric tension and the explicit low/high symbol update above.
  }

  private result(title: string, detail: string, onComplete: () => void, duration: number): void {
    if (this.destroyed || this.resultShown) return;
    this.resultShown = true;
    this.drawnTiles = [];
    this.tiles.clear();
    this.noteLabels.forEach((label) => label.setVisible(false));
    this.judgment.setText("");
    this.text(480, 276, title, 28);
    this.text(480, 316, detail, 14);
    this.cue.setText("");
    const timer = this.scene.time.delayedCall(duration, () => {
      this.timers.delete(timer);
      if (!this.destroyed) onComplete();
    });
    this.timers.add(timer);
  }

  playResult(result: QizhenFishingResult, onComplete: () => void): void {
    this.result(`钓取成功 · ${result.grade}`, `准确率 ${(result.accuracy * 100).toFixed(0)}%`, onComplete, 840);
  }

  playFailure(reason: QizhenFishingFailReason | "grade", onComplete: () => void): void {
    this.result(reason === "line_snapped" ? "钓线断了" : reason === "hook_escaped" ? "脱钩了" : "这次没钓住",
      "道具已保留，可以重试", onComplete, 840);
  }

  getDebugSnapshot() {
    return {
      renderer: "logical_geometry_v2", coordinateSystem: "960x540 logical screen",
      maskCount: 0, board: BOARD, lanes: FISHING_LANES,
      tiles: this.drawnTiles.map((tile) => ({ ...tile })),
      notes: this.model.notes.filter((note) => note.judgment === null || note.holding)
        .map(({ index, action, timeSec, holdSec, holding }) => ({ index, action, timeSec, holdSec, holding })),
    };
  }

  destroy(): void {
    if (this.destroyed) return;
    this.destroyed = true;
    for (const timer of this.timers) timer.remove();
    this.timers.clear();
    this.firstVisible.clear();
    this.water.destroy();
    this.root.destroy();
  }
}
