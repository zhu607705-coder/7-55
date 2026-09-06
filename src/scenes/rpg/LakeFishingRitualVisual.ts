import Phaser from "phaser";
import anglerUrl from "../../assets/rpg/qizhen_fishing/player_blue_fishing_skiff.png";
import environmentUrl from "../../assets/rpg/qizhen_fishing/qizhen_fishing_dawn_environment.png";
import { type RhythmFishingAction, type RhythmFishingEngine, type RhythmFishingNote, type RhythmFishingJudgment, type RhythmFishingWarningKind, type RhythmFishingResult, type RhythmFishingFailReason } from "../../modules/RhythmFishingEngine";
export type LakeFishingCatchKind = "locker_key" | "net_frame" | "fish" | "paper" | "lake";
export interface LakeFishingRitualOptions<Id extends string> {
  scene: Phaser.Scene; model: RhythmFishingEngine<Id>; width: number; height: number; targetLabel: string;
  catchKind?: LakeFishingCatchKind; reducedMotion?: boolean;
  onInput: (type: "press" | "release") => void;
  onDirection?: (action: "left" | "right", type: "press" | "release") => void;
  onNeutralRelease?: () => void;
  onCancel?: () => void;
  onRetry?: () => void;
}
const FONT = '"Fusion Pixel 12px Proportional SC", "Fusion Pixel", monospace';
const INK = 0x092f36, GOLD = 0xffdd83, PALE = 0xe8f5cc, MINT = 0x76dfc9, RED = 0xf27f69;
const TEXTURE = "qizhen-fishing-dawn-v2";

/** One illustrated lake and one set of cast / line-control cues for story and endless. */
export class LakeFishingRitualVisual<Id extends string = string> {
  readonly root: Phaser.GameObjects.Container;
  private readonly art: Phaser.GameObjects.Graphics;
  private readonly background: Phaser.GameObjects.Image | null;
  private lateBackground: Phaser.GameObjects.Image | null = null;
  private anglerSprite: Phaser.GameObjects.Image | null = null;
  private readonly labels: Record<string, Phaser.GameObjects.Text> = {};
  private readonly pointerZone: Phaser.GameObjects.Zone;
  private held = false;
  private pointerId: number | null = null;
  private pointerDirection: "left" | "right" | null = null;
  private ending: "success" | "failure" | null = null;
  private endCallback: (() => void) | null = null;
  private resultTimer: Phaser.Time.TimerEvent | null = null;
  private feedbackUntil = 0;
  private reactionAt = -10000;
  private splashJudgment: RhythmFishingJudgment = "perfect";
  private destroyed = false;
  private readonly onPointerMove = (pointer: Phaser.Input.Pointer) => {
    if (this.pointerId !== pointer.id || !this.held) return;
    const p = this.logicalPointer(pointer);
    const model = this.options.model;
    const target = Phaser.Math.Clamp((p.x - this.options.width / 2) / (this.options.width * 0.29), -1, 1);
    this.setPointerDirection(Math.abs(target - model.lineX) < 0.08 ? null : target > model.lineX ? "right" : "left");
  };
  private readonly onPointerUp = (pointer: Phaser.Input.Pointer) => {
    if (this.pointerId !== pointer.id) return;
    this.pointerId = null; this.setPointerDirection(null);
    if (this.held) { this.held = false; this.options.onInput("release"); }
  };
  private readonly onPointerCancel = () => {
    this.held = false; this.pointerId = null; this.setPointerDirection(null); this.options.onNeutralRelease?.();
  };

  constructor(private readonly options: LakeFishingRitualOptions<Id>) {
    const { scene, width, height } = options;
    this.root = scene.add.container(0, 0).setScrollFactor(0).setDepth(9000);
    this.background = scene.textures.exists(TEXTURE) ? this.makeBackground() : null;
    if (!this.background) {
      const image = new window.Image();
      image.onload = () => {
        if (this.destroyed || !scene.sys.isActive()) return;
        if (!scene.textures.exists(TEXTURE)) scene.textures.addImage(TEXTURE, image);
        this.lateBackground = this.makeBackground(); this.root.sendToBack(this.lateBackground);
      };
      image.src = environmentUrl;
    }
    this.art = scene.add.graphics(); this.root.add(this.art);
    const mountAngler = () => {
      if (this.destroyed || this.anglerSprite) return;
      this.anglerSprite = scene.add.image(0, 0, "qizhen-blue-angler-v2").setOrigin(0.5, 1);
      this.root.addAt(this.anglerSprite, this.root.getIndex(this.art) + 1);
    };
    if (scene.textures.exists("qizhen-blue-angler-v2")) mountAngler();
    else {
      const playerImage = new window.Image();
      playerImage.onload = () => {
        if (this.destroyed || !scene.sys.isActive()) return;
        if (!scene.textures.exists("qizhen-blue-angler-v2")) scene.textures.addImage("qizhen-blue-angler-v2", playerImage);
        mountAngler();
      };
      playerImage.src = anglerUrl;
    }
    const text = (key: string, value: string, size: number, color = "#e8f5cc") => {
      const label = scene.add.text(0, 0, value, { fontFamily: FONT, fontSize: `${size}px`, color, align: "center", lineSpacing: 5, wordWrap: { width: width - 44 } }).setOrigin(0.5);
      this.labels[key] = label; this.root.add(label); return label;
    };
    text("title", "启真湖拒绝被钓", width > 600 ? 23 : 21);
    text("target", `这一竿 · ${options.targetLabel}`, 14, "#b7d9c7");
    text("phase", "01 / 瞄准抛竿", 14, "#ffdd83");
    ["按住","松开","按住","松开"].forEach((label,i)=>text(`beat${i}`,label,12,"#9ebfb1"));
    text("beatAction","",width>600?23:18,"#ffe2a0");
    text("nextBeat","",13,"#b5d0bf");
    text("countIn","",width>600?45:36,"#ffdd83");
    text("instruction", "左右对准鱼影，按住蓄力后松手", width > 600 ? 18 : 16);
    text("feedback", "", width > 600 ? 22 : 19, "#ffdd83");
    text("tension", "线的张力", 13);
    text("guide", "A / D 控线 · Space 收线 / 放线", 14, "#e8f5cc");
    text("swan", "它也在钓你。", 13, "#d2e7c2");
    text("cancel", options.onCancel ? "收竿离开 · Esc" : "", 12, "#bcd3c8");
    text("result", "", 25, "#ffdd83"); text("resultBody", "", 16); text("retry", "", 17, "#123f3e");
    this.pointerZone = scene.add.zone(width / 2, height / 2, width, height).setScrollFactor(0).setInteractive(); this.root.add(this.pointerZone);
    this.pointerZone.on("pointerdown", (pointer: Phaser.Input.Pointer) => {
      if (this.pointerId !== null) return;
      const p = this.logicalPointer(pointer);
      if (options.onCancel && p.x > width - 146 && p.y > height - 42) { options.onCancel(); return; }
      if (this.ending === "failure") { if (this.hit(p, this.resultButton())) this.handleResultInput(); return; }
      if (this.ending) return;
      this.held = true; this.pointerId = pointer.id; options.onInput("press"); this.onPointerMove(pointer);
    });
    scene.input.on("pointermove", this.onPointerMove);
    scene.input.on("pointerup", this.onPointerUp);
    scene.input.on("pointerupoutside", this.onPointerUp);
    scene.game.canvas.addEventListener("pointercancel", this.onPointerCancel);
    this.update();
  }
  private makeBackground(): Phaser.GameObjects.Image {
    const { scene, width, height } = this.options;
    const image = scene.add.image(width / 2, height / 2, TEXTURE);
    image.setScale(Math.max(width / image.width, height / image.height));
    this.root.add(image); return image;
  }
  private logicalPointer(pointer: Phaser.Input.Pointer) {
    const rect = this.options.scene.game.canvas.getBoundingClientRect();
    const event = pointer.event as PointerEvent | TouchEvent | MouseEvent;
    const touch = event && "changedTouches" in event ? event.changedTouches[0] : null;
    const clientX = touch?.clientX ?? (event && "clientX" in event ? event.clientX : rect.left + pointer.x * rect.width / this.options.width);
    const clientY = touch?.clientY ?? (event && "clientY" in event ? event.clientY : rect.top + pointer.y * rect.height / this.options.height);
    return { x: (clientX - rect.left) * this.options.width / rect.width, y: (clientY - rect.top) * this.options.height / rect.height };
  }
  private setPointerDirection(direction: "left" | "right" | null): void {
    if (this.pointerDirection === direction) return;
    if (this.pointerDirection) this.options.onDirection?.(this.pointerDirection, "release");
    this.pointerDirection = direction;
    if (direction) this.options.onDirection?.(direction, "press");
  }
  private hit(p: {x:number;y:number}, box: {x:number;y:number;width:number;height:number}): boolean {
    return p.x >= box.x && p.x <= box.x + box.width && p.y >= box.y && p.y <= box.y + box.height;
  }
  private resultButton() { return { x: this.options.width * 0.23, y: this.options.height * 0.66, width: this.options.width * 0.54, height: 44 }; }
  handleResultInput(): boolean {
    if (this.ending !== "failure") return false;
    if (this.options.onRetry) this.options.onRetry(); else this.endCallback?.();
    return true;
  }
  notifyJudgment(_note: RhythmFishingNote, judgment: RhythmFishingJudgment, _errorMs = 0): void {
    this.reactionAt = this.options.scene.time.now; this.feedbackUntil = this.reactionAt + 800; this.splashJudgment = judgment;
    this.labels.feedback.setText(judgment === "perfect" ? "漂亮！把湖拽近了一截" : judgment === "miss" ? "这一钩脱了，跟住鱼影！" : "稳住，再收一截").setColor(judgment === "miss" ? "#ffb195" : "#ffdd83");
  }
  notifyHoldBroken(_note: RhythmFishingNote): void { this.labels.feedback.setText("先稳住收线，再松手起鱼"); this.feedbackUntil = this.options.scene.time.now + 650; }
  notifyWarning(_kind: RhythmFishingWarningKind, _tension: number): void { this.labels.feedback.setText("线要绷断了，松手！"); this.feedbackUntil = this.options.scene.time.now + 650; }
  playResult(result: RhythmFishingResult<Id>, onComplete: () => void): void {
    if (this.destroyed || this.ending) return;
    this.ending = "success"; this.onPointerCancel();
    this.labels.result.setText("这一口，湖认输了");
    this.labels.resultBody.setText(`${this.options.targetLabel}浮上来了\n${result.grade} · 收获 ${result.perfect + result.great + result.good} / ${this.options.model.totalNotes}`);
    this.resultTimer = this.options.scene.time.delayedCall(1500, () => { if (!this.destroyed) onComplete(); });
  }
  playFailure(_reason: RhythmFishingFailReason | "grade", onComplete: () => void): void {
    if (this.destroyed || this.ending) return;
    this.ending = "failure"; this.onPointerCancel(); this.endCallback = onComplete;
    this.labels.result.setText("这次，湖把你钓走了");
    this.labels.resultBody.setText("左右跟住鱼影，猛拽时松手放线。\n跟着四拍：稳、放、收、提。");
    this.labels.retry.setText(this.options.onRetry ? "再下一竿" : "查看本局结果");
  }

  update(): void {
    if (this.destroyed) return;
    const { width: w, height: h, model } = this.options, g = this.art;
    const portrait = w < 600, now = this.options.scene.time.now;
    const t = this.options.reducedMotion ? 0 : now / 1000;
    const waterY = h * (portrait ? 0.56 : 0.56);
    const fishX = w * 0.5 + model.fishX * w * 0.29, hookX = w * 0.5 + model.lineX * w * 0.29;
    g.clear();
    if (!this.background && !this.lateBackground) { g.fillStyle(0x164f53); g.fillRect(0, 0, w, h); }
    g.fillStyle(INK, 0.7); g.fillRect(0, 0, w, portrait ? 122 : 143);
    g.fillStyle(INK, 0.78); g.fillRect(0, h - 89, w, 89);
    g.lineStyle(1, GOLD, 0.38); g.lineBetween(20, portrait ? 122 : 143, w - 20, portrait ? 122 : 143);
    // Tiny moving flecks and curved ripples sit over the painted environment.
    for (let i = 0; i < 38; i++) {
      const x = (i * 97.31 + Math.sin(t * 0.4 + i) * 9) % w;
      const y = h * 0.39 + (i * 43.7) % (h * 0.39);
      g.lineStyle(i % 3 === 0 ? 2 : 1, i % 3 === 0 ? GOLD : MINT, 0.12 + Math.sin(t + i) * 0.06);
      g.lineBetween(x, y, x + 5 + i % 15, y);
    }
    const giantX = fishX * 0.35 + w * 0.33;
    this.drawLakeCreature(g, giantX, waterY + h * 0.16, portrait ? 0.68 : 1.16, t, model.isHolding, model.judgedCount / model.totalNotes);
    const swanX = w * 0.82 + Math.sin(t * 0.5) * 10, swanY = h * 0.39;
    this.drawSwan(g, swanX, swanY, portrait ? 0.67 : 0.85, t, model.fishRushing);
    this.labels.swan.setPosition(swanX - (portrait ? 25 : 0), swanY - 55).setText(model.fishRushing ? "嘎！松手！" : model.liftReady ? "现在，起鱼！" : "它也在钓你。");
    // Fish shadow and the player's bobber occupy the same readable horizontal water lane.
    const fishScale = portrait ? 0.84 : 1;
    const pulse = Math.sin(t * 5) * 0.5 + 0.5;
    g.fillStyle(model.liftReady ? GOLD : model.fishRushing ? RED : MINT, model.liftReady ? 0.2 + pulse * 0.1 : 0.1);
    g.fillEllipse(fishX, waterY, 108 * fishScale, 46 * fishScale);
    this.drawFish(g, fishX, waterY, fishScale, t, model.liftReady ? GOLD : model.fishRushing ? 0xbc6650 : 0x184941);
    g.lineStyle(2, model.liftReady ? GOLD : MINT, model.aligned ? 0.8 : 0.3);
    g.strokeEllipse(fishX, waterY + 4, 80 * fishScale, 25 * fishScale);
    if (model.stage === "casting") {
      g.lineStyle(1, PALE, 0.8);
      g.lineBetween(hookX - 15, waterY, hookX + 15, waterY); g.lineBetween(hookX, waterY - 13, hookX, waterY + 13);
    }
    const rodTip = this.drawAngler(g, w * (portrait ? 0.26 : 0.16), h * 0.82, portrait ? 0.73 : 1, t, model.lineX, model.tension, model.isHolding);
    this.drawLine(g, rodTip.x, rodTip.y, hookX, waterY + 9, model.tension, model.fishRushing, t);
    g.fillStyle(0x062b30, 0.45); g.fillEllipse(hookX, waterY + 20, 24, 7);
    g.fillStyle(0xf7e7b8); g.fillRoundedRect(hookX - 4, waterY + 1, 8, 22, 3);
    g.fillStyle(model.aligned ? 0xe86543 : 0x7e7570); g.fillRoundedRect(hookX - 4, waterY + 1, 8, 11, 3);
    g.lineStyle(1, 0x2a3932); g.lineBetween(hookX, waterY - 4, hookX, waterY + 1);
    this.drawSplash(g, hookX, waterY + 10, now - this.reactionAt, this.splashJudgment !== "miss");
    if (model.liftReady && model.stage === "fighting") {
      for (let i = 0; i < 6; i++) {
        const a = i * Math.PI / 3 + t;
        g.fillStyle(GOLD, 0.8); g.fillRect(fishX + Math.cos(a) * 54 - 2, waterY + Math.sin(a) * 25 - 2, 4, 4);
      }
    }
    this.layoutLabels(w, h, portrait, model, now);
    const musicVisible=model.stage!=="casting"&&!this.ending;
    const trackCenter=portrait?w*.5:w*.65;
    const beatY=portrait?229:h-131,spacing=portrait?75:106;
    const commands=["按住稳线","松开放线","按住收线","松开起鱼"];
    const firstX=trackCenter-1.5*spacing,lastX=trackCenter+1.5*spacing;
    if(musicVisible){
      g.lineStyle(2,MINT,.25);g.lineBetween(firstX,beatY,lastX,beatY);
      const cursorX=firstX+Math.min(3,model.rhythmBeat+model.beatProgress)*spacing;
      g.lineStyle(2,GOLD,.72);g.lineBetween(firstX,beatY,cursorX,beatY);
      g.fillStyle(PALE,.95);g.fillCircle(cursorX,beatY,3);
    }
    for(let i=0;i<4;i++){
      const x=firstX+i*spacing,active=i===model.rhythmBeat,pulse=Math.exp(-model.beatProgress*8);
      this.labels[`beat${i}`].setVisible(musicVisible).setPosition(x,beatY+20).setColor(active?"#ffe2a0":"#9ebfb1");
      if(musicVisible){g.fillStyle(active?GOLD:0x375e56,1);g.fillCircle(x,beatY,active?5+pulse*2:4);if(active){g.lineStyle(1,GOLD,pulse*.7);g.strokeCircle(x,beatY,9+(1-pulse)*5);}}
    }
    this.labels.beatAction.setVisible(musicVisible).setText(model.stage==="count_in"?"听四拍，准备开始":commands[model.rhythmBeat]).setPosition(trackCenter,beatY-47);
    this.labels.nextBeat.setVisible(musicVisible&&model.stage==="fighting").setText(`${model.rhythmName} · ${Math.round(60/model.beatSec)} BPM  下一拍：${commands[(model.rhythmBeat+1)%4]}`).setPosition(trackCenter,beatY-22);
    this.labels.countIn.setVisible(model.stage==="count_in"&&!this.ending).setText(`预备 ${model.countIn}`).setPosition(w/2,h*.47);
    if(musicVisible&&model.rhythmBeat===3){g.lineStyle(3,GOLD,Math.exp(-model.beatProgress*7)*.65);g.strokeEllipse(fishX,waterY+4,90+model.beatProgress*40,32+model.beatProgress*16);}
    for(let i=0;i<4;i++)this.root.bringToTop(this.labels[`beat${i}`]);
    this.root.bringToTop(this.labels.beatAction);this.root.bringToTop(this.labels.nextBeat);this.root.bringToTop(this.labels.countIn);
    const meterX = portrait ? 36 : w * 0.35, meterY = h - 64, meterW = portrait ? w - 72 : w * 0.36;
    const value = model.stage === "casting" ? model.castPower : model.tension / 100;
    g.fillStyle(0x051f28, 0.9); g.fillRoundedRect(meterX, meterY, meterW, 12, 4);
    if (model.stage === "casting") { g.fillStyle(MINT, 0.4); g.fillRect(meterX + meterW * 0.3, meterY, meterW * 0.6, 12); }
    g.fillStyle(model.stage === "casting" ? value >= 0.3 && value <= 0.9 ? MINT : GOLD : value >= 0.8 ? RED : GOLD, 0.95);
    g.fillRoundedRect(meterX, meterY + 2, Math.max(3, meterW * Math.min(value, 1)), 8, 3);
    for (let i = 0; i < model.totalNotes; i++) {
      const x = w / 2 + (i - (model.totalNotes - 1) / 2) * 16, y = portrait ? 103 : 123;
      const note = model.notes[i];g.fillStyle(note.judgment === null ? 0x436b61 : note.judgment === "miss" ? RED : GOLD, 1);g.fillCircle(x, y, 3.3);
    }
    if (this.ending) this.drawResult(g, w, h, t);
  }

  private layoutLabels(w: number, h: number, portrait: boolean, model: RhythmFishingEngine<Id>, now: number): void {
    const labels = this.labels;
    labels.title.setPosition(w / 2, portrait ? 24 : 71); labels.target.setPosition(w / 2, portrait ? 48 : 96);
    labels.phase.setPosition(portrait ? w / 2 : 103, portrait ? 73 : 75).setText(model.stage === "casting" ? "01 / 瞄准抛竿" : model.stage === "count_in" ? "02 / 四拍预备" : "03 / 跟拍遛鱼");
    const hint = model.stage === "count_in" ? "听四拍：稳住 → 放线 → 收线 → 松手提竿" : model.stage === "casting" ? model.isHolding ? "蓄到绿色区 · 松手抛竿" : "左右对准鱼影 · 按住蓄力"
      : model.fishRushing ? "鱼在猛拽！松手放线，继续左右跟随" : model.liftReady ? model.aligned && model.tracking >= 1 ? "闪金了！现在松手起鱼" : "跟住鱼影！稳住后再松手" : "左右跟住鱼影 · 跟着四拍收线";
    labels.instruction.setText(hint).setPosition(w / 2, portrait ? 147 : 165).setColor(model.fishRushing ? "#ffb096" : "#fff0c2").setVisible(model.stage === "casting" && !this.ending);
    labels.feedback.setPosition(w / 2, h * 0.60).setVisible(now < this.feedbackUntil && !this.ending);
    labels.tension.setPosition(portrait ? w / 2 : w * 0.28, h - 58).setText(model.stage === "casting" ? "抛竿力度" : `张力 ${Math.round(model.tension)}%`);
    if (portrait) labels.tension.setPosition(w / 2, h - 78);
    labels.guide.setPosition(w / 2, h - 33).setText(portrait ? "左右控线 · 中间按钮按住 / 松开" : "A / D 控线 · Space 按住 / 松开 · 鼠标可拖动控线");
    labels.cancel.setPosition(w - 83, h - 13);
    labels.result.setPosition(w / 2, h * 0.39); labels.resultBody.setPosition(w / 2, h * 0.52);
    labels.retry.setPosition(w / 2, h * 0.66 + 22);
    if (model.lastCue.startsWith("抛偏") || model.lastCue.startsWith("太轻") || model.lastCue.startsWith("太重")) labels.instruction.setText(model.lastCue);
    for (const key of ["phase", "guide", "tension", "swan"]) labels[key].setVisible(!this.ending);
  }
  private drawResult(g: Phaser.GameObjects.Graphics, w: number, h: number, t: number): void {
    g.fillStyle(0x062b32, 0.86); g.fillRect(0, 0, w, h);
    g.lineStyle(1, GOLD, 0.55);g.strokeRoundedRect(w * 0.12, h * 0.27, w * 0.76, h * 0.49, 12);
    if (this.ending === "failure") { const b = this.resultButton();g.fillStyle(GOLD);g.fillRoundedRect(b.x,b.y,b.width,b.height,8); }
    else this.drawCatch(g, w / 2, h * 0.22 + Math.sin(t * 3) * 2);
    for (const k of ["result","resultBody","retry"]) this.root.bringToTop(this.labels[k]);
    this.root.bringToTop(this.labels.cancel);this.root.bringToTop(this.pointerZone);
  }
  private drawLine(g: Phaser.GameObjects.Graphics, ax:number,ay:number,bx:number,by:number,tension:number,rush:boolean,t:number):void {
    const points=[];
    for(let i=0;i<=24;i++){const u=i/24;points.push({x:ax+(bx-ax)*u+Math.sin(u*Math.PI)*Math.sin(t*20)*(rush?3:0.5),y:ay+(by-ay)*u+Math.sin(u*Math.PI)*(1-tension/100)*46});}
    g.lineStyle(3,INK,0.35);g.strokePoints(points,false);g.lineStyle(1.2,tension>80?RED:0xffe5a9,0.95);g.strokePoints(points,false);
  }
  private drawFish(g:Phaser.GameObjects.Graphics,x:number,y:number,s:number,t:number,color:number):void {
    g.fillStyle(color,0.95);g.fillEllipse(x,y,48*s,20*s);
    g.fillTriangle(x-19*s,y,x-37*s,y-13*s+Math.sin(t*7)*3,x-37*s,y+13*s+Math.sin(t*7)*3);
    g.fillTriangle(x-2*s,y-8*s,x+2*s,y-19*s,x+13*s,y-7*s);
    g.fillStyle(0xeecb87,0.5);g.fillEllipse(x+3*s,y+4*s,30*s,6*s);
    g.fillStyle(GOLD);g.fillCircle(x+16*s,y-3*s,2*s);
    g.lineStyle(1,INK,0.7);g.lineBetween(x+9*s,y-6*s,x+6*s,y+5*s);
  }
  private drawLakeCreature(g:Phaser.GameObjects.Graphics,x:number,y:number,s:number,t:number,pulling:boolean,progress:number):void {
    const breathe=Math.sin(t*1.6)*3, rise=progress*20;
    g.fillStyle(0x062d36,0.2);g.fillEllipse(x,y+15*s,340*s,76*s);
    g.fillStyle(0x174d4b,0.42);g.fillEllipse(x,y+breathe-rise,285*s,87*s);
    g.fillStyle(0x29695b,0.32);g.fillEllipse(x-7*s,y-13*s+breathe-rise,228*s,42*s);
    g.fillStyle(0x0b3b3e,0.4);g.fillTriangle(x-120*s,y-rise,x-193*s,y-48*s+Math.sin(t*2)*8,x-177*s,y+56*s);
    for(let row=0;row<4;row++)for(let i=0;i<14;i++){
      const px=x+(i-7)*16*s+(row%2)*8*s,py=y+(row-2)*14*s+breathe-rise;
      if(Math.abs(i-7)*.12+Math.abs(row-2)*.18>1.04)continue;
      g.lineStyle(1,0x6da787,0.15);g.beginPath();g.arc(px,py,7*s,.2,Math.PI-.2);g.strokePath();
    }
    const eyeX=x+102*s, eyeY=y-17*s+breathe-rise;
    g.fillStyle(0x163d39,0.8);g.fillEllipse(eyeX,eyeY,33*s,24*s);g.fillStyle(GOLD,0.72);g.fillEllipse(eyeX+3*s,eyeY,17*s,14*s);g.fillStyle(INK);g.fillEllipse(eyeX+5*s,eyeY,4*s,13*s);
    g.lineStyle(2,0x8eb493,0.28);g.beginPath();g.arc(x+111*s,y+8*s-rise,24*s,-.2,1.2);g.strokePath();
    g.lineStyle(1,PALE,0.28);g.beginPath();g.moveTo(x+126*s,y+12*s-rise);g.lineTo(x+165*s,y+17*s+Math.sin(t)*5-rise);g.lineTo(x+193*s,y+2*s-rise);g.strokePath();
    // The lake's tiny rod hooks the angler's absurd floating campus hat.
    if(pulling){g.lineStyle(1,GOLD,0.4);g.lineBetween(x+124*s,y-rise,x+143*s,y-64*s-rise);g.lineBetween(x+143*s,y-64*s-rise,x+184*s,y-76*s-rise);g.fillStyle(0xdec18a,.8);g.fillEllipse(x+185*s,y-79*s-rise,24*s,6*s);}
  }
  private drawSwan(g:Phaser.GameObjects.Graphics,x:number,y:number,s:number,t:number,rush:boolean):void {
    const bob=Math.sin(t*2)*2;
    g.fillStyle(0x092f34,0.25);g.fillEllipse(x,y+14*s,82*s,14*s);
    g.fillStyle(0x10242b);g.fillEllipse(x,y+bob,62*s,28*s);
    g.fillTriangle(x-22*s,y,x-40*s,y-12*s,x-34*s,y+8*s);
    g.lineStyle(10*s,0x10242b);g.beginPath();g.moveTo(x+19*s,y-3*s+bob);g.lineTo(x+30*s,y-17*s+bob);g.lineTo(x+27*s,y-36*s+bob);g.lineTo(x+19*s,y-43*s+bob);g.strokePath();
    g.fillStyle(0x152b31);g.fillEllipse(x+19*s,y-43*s+bob,18*s,14*s);
    g.fillStyle(0xcf5b36);g.fillTriangle(x+14*s,y-45*s+bob,x+1*s,y-40*s+bob,x+14*s,y-38*s+bob);
    g.fillStyle(0xffe8bc);g.fillCircle(x+17*s,y-46*s+bob,1.2*s);
    for(let i=0;i<6;i++){g.lineStyle(1,0x547273,.8);g.beginPath();g.arc(x-9*s+i*5*s,y-2*s,11*s,.1,2);g.strokePath();}
    if(rush){g.lineStyle(2,GOLD,.65);g.lineBetween(x-35*s,y-28*s,x-42*s,y-33*s);g.lineBetween(x-29*s,y-35*s,x-32*s,y-42*s);}
    g.lineStyle(1,PALE,.35);g.strokeEllipse(x,y+15*s,79*s+Math.sin(t*3)*5,14*s);
  }
  private drawAngler(g:Phaser.GameObjects.Graphics,x:number,y:number,s:number,t:number,lean:number,tension:number,held:boolean):{x:number;y:number} {
    const bob=Math.sin(t*1.8)*2, hy=y-98*s+bob;
    if (this.anglerSprite) {
      const sprite = this.anglerSprite, targetWidth = 224 * s;
      sprite.setVisible(!this.ending).setScale(targetWidth / sprite.width).setPosition(x, y + 25 * s + bob).setAngle(lean * 1.2 + (held ? -0.6 : 0));
      g.fillStyle(0x082e35, 0.3); g.fillEllipse(x, y + 26*s, targetWidth, 20*s);
      const localX = targetWidth * 0.121, localY = -sprite.displayHeight * 0.465;
      const angle = sprite.rotation;
      const handX = sprite.x + localX * Math.cos(angle) - localY * Math.sin(angle);
      const handY = sprite.y + localX * Math.sin(angle) + localY * Math.cos(angle);
      const tipX = handX + (88 + lean*10)*s, tipY = handY - (83 - tension*0.27)*s;
      g.lineStyle(4*s, 0x314e46); g.beginPath(); g.moveTo(handX-9*s,handY+10*s); g.lineTo(handX,handY); g.lineTo(handX+35*s,handY-45*s); g.lineTo(tipX-24*s,tipY-6*s); g.lineTo(tipX,tipY); g.strokePath();
      g.lineStyle(1, GOLD, .7); g.lineBetween(handX,handY,handX+35*s,handY-45*s);
      g.fillStyle(0xa79c74);g.fillCircle(handX-6*s,handY+12*s,6*s);g.fillStyle(0x294239);g.fillCircle(handX-6*s,handY+12*s,3*s);
      return {x:tipX,y:tipY};
    }
    g.fillStyle(0x082e35,.4);g.fillEllipse(x+14*s,y+16*s,167*s,27*s);
    g.fillStyle(0x69412e);g.fillTriangle(x-87*s,y-5*s,x+87*s,y-5*s,x+56*s,y+24*s);g.fillTriangle(x-87*s,y-5*s,x+56*s,y+24*s,x-51*s,y+24*s);
    g.fillStyle(0xaf8650);g.fillEllipse(x,y-6*s,170*s,36*s);g.fillStyle(0x3b3830);g.fillEllipse(x,y-7*s,140*s,23*s);
    for(let i=0;i<5;i++){g.lineStyle(1,0x806240);g.lineBetween(x-55*s+i*27*s,y-18*s,x-55*s+i*27*s,y+3*s);}
    g.fillStyle(0x3e6570);g.fillRoundedRect(x-25*s,y-52*s,45*s,43*s,9*s);g.fillStyle(0x24434f);g.fillRoundedRect(x+9*s,y-41*s,31*s,32*s,7*s);
    g.fillStyle(0x172f35);g.fillRoundedRect(x-17*s,y-20*s,28*s,12*s,3*s);g.fillRoundedRect(x+27*s,y-18*s,23*s,11*s,3*s);
    g.fillStyle(0x315b7b);g.fillRoundedRect(x-22*s,hy+23*s,43*s,55*s,7*s);g.fillStyle(0x5e89a5);g.fillRect(x-18*s,hy+28*s,9*s,40*s);
    g.fillStyle(0x213d53);g.fillRect(x+13*s,hy+32*s,5*s,38*s);g.lineStyle(2,0x4a5948);g.lineBetween(x-8*s,hy+26*s,x-6*s,hy+74*s);
    g.fillStyle(0xd7a87e);g.fillRoundedRect(x-15*s,hy-5*s,32*s,34*s,9*s);g.fillStyle(0x283536);g.fillEllipse(x,hy-5*s,39*s,26*s);
    g.fillStyle(0x445046);g.fillEllipse(x-7*s,hy-10*s,25*s,9*s);g.fillStyle(0x162d30);g.fillRect(x-18*s,hy,9*s,13*s);
    g.fillStyle(0x765039);g.fillRect(x+11*s,hy+10*s,4*s,3*s);
    const handX=x+(42+lean*10)*s,handY=hy+(held?28:38)*s;
    g.lineStyle(13*s,0x416b8b);g.beginPath();g.moveTo(x+15*s,hy+34*s);g.lineTo(x+30*s,hy+49*s);g.lineTo(handX,handY);g.strokePath();
    g.fillStyle(0xe3b789);g.fillCircle(handX,handY,5*s);
    const tipX=handX+(85+lean*15)*s,tipY=handY-(80-tension*.27)*s;
    g.lineStyle(4*s,0x3d4f3f);g.beginPath();g.moveTo(handX-15*s,handY+20*s);g.lineTo(handX,handY);g.lineTo(handX+35*s,handY-43*s);g.lineTo(tipX-28*s,tipY-7*s);g.lineTo(tipX,tipY);g.strokePath();
    g.lineStyle(1,0xe1c278,.8);g.lineBetween(handX,handY,handX+35*s,handY-43*s);
    g.fillStyle(0xb49e6e);g.fillCircle(handX-6*s,handY+12*s,7*s);g.fillStyle(0x364c48);g.fillCircle(handX-6*s,handY+12*s,3*s);
    return {x:tipX,y:tipY};
  }
  private drawSplash(g:Phaser.GameObjects.Graphics,x:number,y:number,ms:number,success:boolean):void {
    if(ms<0||ms>750)return;const p=ms/750;
    g.lineStyle(2,success?GOLD:MINT,(1-p)*.75);g.strokeEllipse(x,y,20+p*105,7+p*31);
    for(let i=0;i<9;i++){const a=i/9*Math.PI*2;g.fillStyle(success?PALE:MINT,1-p);g.fillCircle(x+Math.cos(a)*p*55,y+Math.sin(a)*p*18-Math.sin(p*Math.PI)*22,2.4-p);}
  }
  private drawCatch(g:Phaser.GameObjects.Graphics,x:number,y:number):void {
    const kind=this.options.catchKind;
    if(kind==='fish'||kind==='lake'){this.drawFish(g,x,y,1.7,0,GOLD);return;}
    g.lineStyle(4,GOLD);g.fillStyle(GOLD);
    if(kind==='locker_key'){g.strokeCircle(x-11,y,10);g.lineBetween(x,y,x+31,y);g.lineBetween(x+20,y,x+20,y+11);g.lineBetween(x+29,y,x+29,y+8);}
    else if(kind==='net_frame'){g.strokeEllipse(x,y,56,38);g.lineBetween(x,y+20,x,y+43);for(let i=-2;i<=2;i++){g.lineStyle(1,GOLD,.5);g.lineBetween(x+i*9,y-15,x+i*9,y+15);g.lineBetween(x-23,y+i*6,x+23,y+i*6);}}
    else {g.fillRoundedRect(x-22,y-27,44,54,3);g.lineStyle(3,0x9aac9b);g.strokeRoundedRect(x+8,y-30,9,20,4);g.lineStyle(2,INK,.5);for(let i=0;i<4;i++)g.lineBetween(x-13,y-12+i*9,x+12,y-12+i*9);}
  }
  destroy(): void {
    if (this.destroyed) return;this.destroyed=true;
    this.resultTimer?.remove(false);this.resultTimer=null;
    this.options.scene.input.off("pointermove",this.onPointerMove);
    this.options.scene.input.off("pointerup",this.onPointerUp);this.options.scene.input.off("pointerupoutside",this.onPointerUp);
    this.options.scene.game.canvas.removeEventListener("pointercancel",this.onPointerCancel);
    this.setPointerDirection(null);this.root.destroy(true);
  }
}
