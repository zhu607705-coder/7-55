import Phaser from "phaser";
import dormHubMapUrl from "../../assets/rpg/interiors/dorm_hub.png";
import actOneContent from "../../data/act-one-bootstrap.content.json";
import type { RpgBridge } from "./RpgBridge";
import {
  DORM_CAMPUS_CARD,
  DORM_HUB_WORLD,
  DORM_INTERACTION_TARGETS,
  DORM_SPAWN,
  DORM_STATIC_COLLISION_RECTS,
  distanceToDormTarget,
  findNearestDormTarget,
  type DormInteractionTarget,
  type DormInteractionTargetId
} from "./DormHubModel";
import { formatRpgInteractionHint } from "./RpgControlHints";
import { RPG_HUD_LAYOUT } from "./RpgHudLayout";
import {
  configureRpgPlayerSprite,
  ensureRpgPlayerTextures,
  preloadRpgPlayerTextures,
  RPG_PLAYER_NAME_OFFSET_Y,
  type RpgPlayerFacing
} from "./RpgPlayerTextures";
import {
  clearRpgRuntimeDebugState,
  setRpgRuntimeDebugState,
  type RpgRuntimeDebugState
} from "./RpgRuntimeDebug";
import { subscribeRpgSceneBridge } from "./RpgSceneBridgeSubscription";

const DORM_HUB_MAP_KEY = "dorm-hub-user-topdown-map";
const DORM_CAMERA_ZOOM = 960 / DORM_HUB_WORLD.width;

const INTERACTION_COPY: Record<DormInteractionTargetId, string> = {
  upper_bunk: "床帘后只有一床叠得过分认真的被子。",
  lower_bunk: "枕头下面没有捷径，只有一张过期的外卖券。",
  window: "窗外很亮。七点五十五分不会因此晚一点。",
  window_cabinet: "柜门打开了。里面整齐地保存着一片空白。",
  shoe_shelf: "鞋都在，人也该在。这个推理暂时没有帮助。",
  laundry_bin: "洗衣篮拒绝提供任何关于签到记录的证词。",
  desk_01: "蓝色台灯亮了。桌面终于像有人认真学习过。",
  desk_02: "书翻到夹着便签的一页：先找到名字，再谈方向。",
  desk_03: "这是你的书桌。最值钱的东西仍然只有那张校园卡。",
  desk_04: "抽屉里有三支没墨的笔，以及非常稳定的失望。",
  wash_basin: "水龙头还能出水。至少寝室里有一个系统响应正常。",
  lower_shelf: "书脊按课程排好，最薄的那本写着《平时分自救》。",
  floor_backpack: "不是你的包。拉链上挂着一句很明确的‘别翻’。",
  exit_door: "门没有意见，流程有。"
};

export class DormHubScene extends Phaser.Scene {
  private bridge!: RpgBridge;
  private player!: Phaser.Physics.Arcade.Sprite;
  private obstacles!: Phaser.Physics.Arcade.StaticGroup;
  private cursors!: Phaser.Types.Input.Keyboard.CursorKeys;
  private keys!: Record<"W" | "A" | "S" | "D", Phaser.Input.Keyboard.Key>;
  private virtualDirection = { x: 0, y: 0 };
  private interactRequested = false;
  private exitTriggered = false;
  private manualMovementReported = false;
  private pacingDirection = 1;
  private walkingFrame = 0;
  private facing: RpgPlayerFacing = "up";
  private characterName!: Phaser.GameObjects.Text;
  private interactionPrompt!: Phaser.GameObjects.Text;
  private feedbackText!: Phaser.GameObjects.Text;
  private feedbackTween?: Phaser.Tweens.Tween;
  private campusCardPickup?: Phaser.GameObjects.Container;
  private curtainLeft!: Phaser.GameObjects.Rectangle;
  private curtainRight!: Phaser.GameObjects.Rectangle;
  private cabinetLeft!: Phaser.GameObjects.Rectangle;
  private cabinetRight!: Phaser.GameObjects.Rectangle;
  private deskDrawer!: Phaser.GameObjects.Rectangle;
  private backpackRing!: Phaser.GameObjects.Arc;
  private doorPanel!: Phaser.GameObjects.Rectangle;
  private doorHandle!: Phaser.GameObjects.Arc;
  private doorLight!: Phaser.GameObjects.Rectangle;
  private deskLampGlows = new Map<DormInteractionTargetId, Phaser.GameObjects.Arc>();
  private toggledInteractions = new Set<DormInteractionTargetId>();

  constructor() {
    super("dorm-hub");
  }

  preload(): void {
    if (!this.textures.exists(DORM_HUB_MAP_KEY)) {
      this.load.image(DORM_HUB_MAP_KEY, dormHubMapUrl);
    }
    preloadRpgPlayerTextures(this);
  }

  create(): void {
    this.bridge = this.registry.get("rpgBridge") as RpgBridge;
    this.cameras.main.setBackgroundColor(0x050607);
    this.physics.world.setBounds(24, 36, DORM_HUB_WORLD.width - 48, DORM_HUB_WORLD.height - 72);
    this.obstacles = this.physics.add.staticGroup();
    this.drawRoom();
    this.createAmbientAnimations();
    this.createInteractionTargets();
    this.createCampusCardPickup();
    ensureRpgPlayerTextures(this);

    const actOne = this.bridge.getState().actOne;
    const cardPending = !actOne.inventoryRecovered
      && (actOne.phase === "prologue" || actOne.phase === "inventory_required");
    const spawn = cardPending ? { x: 650, y: 920 } : DORM_SPAWN;
    this.player = this.physics.add.sprite(spawn.x, spawn.y, "act1-player-up-0").setCollideWorldBounds(true);
    configureRpgPlayerSprite(this.player);
    this.physics.add.collider(this.player, this.obstacles);
    this.player.setInteractive({ useHandCursor: true });
    this.player.on("pointerdown", () => this.bridge.emit("rpg_character_inspected"));

    this.characterName = this.add.text(spawn.x, spawn.y - RPG_PLAYER_NAME_OFFSET_Y, "", {
      color: "#fff7df",
      backgroundColor: "#17212add",
      fontFamily: "monospace",
      fontSize: "11px",
      padding: { x: 5, y: 2 }
    }).setOrigin(0.5).setDepth(5000);

    this.createHud();
    this.cursors = this.input.keyboard!.createCursorKeys();
    this.keys = this.input.keyboard!.addKeys("W,A,S,D") as Record<"W" | "A" | "S" | "D", Phaser.Input.Keyboard.Key>;
    this.cameras.main
      .setBounds(0, 0, DORM_HUB_WORLD.width, DORM_HUB_WORLD.height)
      .setZoom(DORM_CAMERA_ZOOM)
      .startFollow(this.player, true, 0.12, 0.12, 0, 12)
      .setDeadzone(230, 130);

    const exitZone = this.add.zone(470, 1540, 132, 80);
    this.physics.add.existing(exitZone, true);
    this.physics.add.overlap(this.player, exitZone, () => this.tryExitDorm());

    subscribeRpgSceneBridge(
      this.events,
      this.bridge,
      (event) => this.handleBridgeEvent(event.name, event.payload),
      clearRpgRuntimeDebugState
    );
    this.bridge.setRpgLocation("dorm_hub", this.bridge.getState().rpgCheckpoint);
    this.bridge.emit("rpg_booted", { scene: "dorm_hub" });
    this.bridge.emit("rpg_dorm_room_opened");
    this.publishRuntimeDebug();
  }

  update(): void {
    const actOne = this.bridge.getState().actOne;
    const keyboardX = Number(this.cursors.right.isDown || this.keys.D.isDown)
      - Number(this.cursors.left.isDown || this.keys.A.isDown);
    const keyboardY = Number(this.cursors.down.isDown || this.keys.S.isDown)
      - Number(this.cursors.up.isDown || this.keys.W.isDown);
    const vector = new Phaser.Math.Vector2(
      Phaser.Math.Clamp(keyboardX + this.virtualDirection.x, -1, 1),
      Phaser.Math.Clamp(keyboardY + this.virtualDirection.y, -1, 1)
    );

    if (actOne.movementEnabled && vector.lengthSq() > 0) {
      vector.normalize().scale(150);
      if (!this.manualMovementReported) {
        this.manualMovementReported = true;
        this.bridge.emit("rpg_manual_movement_started");
      }
    } else if (actOne.exerciseStarted && !actOne.gamepadPurchased) {
      if (this.player.x >= 650) this.pacingDirection = -1;
      if (this.player.x <= 390) this.pacingDirection = 1;
      vector.set(this.pacingDirection * 78, 0);
    } else {
      vector.set(0, 0);
    }

    this.player.setVelocity(vector.x, vector.y).setDepth(this.player.y + 2000);
    this.updatePlayerAnimation(vector);
    this.characterName
      .setText(actOne.characterNamed ? actOneContent.studentName : "")
      .setVisible(actOne.characterNamed)
      .setPosition(this.player.x, this.player.y - RPG_PLAYER_NAME_OFFSET_Y)
      .setDepth(this.player.y + 2050);

    const nearest = findNearestDormTarget(this.player.x, this.player.y);
    const cardPending = !actOne.inventoryRecovered;
    const nearCard = cardPending
      && Phaser.Math.Distance.Between(this.player.x, this.player.y, DORM_CAMPUS_CARD.x, DORM_CAMPUS_CARD.y) <= DORM_CAMPUS_CARD.proximity;
    this.updatePrompt(nearest, nearCard);

    const keyboardInteract = Phaser.Input.Keyboard.JustDown(this.cursors.space);
    if (keyboardInteract || this.interactRequested) {
      if (nearCard) {
        this.collectCampusCard();
      } else if (nearest) {
        this.triggerInteraction(nearest);
      }
    }
    this.interactRequested = false;
    this.publishRuntimeDebug();
  }

  private handleBridgeEvent(name: string, payload?: Record<string, unknown>): void {
    if (name === "rpg_direction_changed") {
      this.virtualDirection = { x: Number(payload?.x) || 0, y: Number(payload?.y) || 0 };
      return;
    }
    if (name === "rpg_interact") {
      this.interactRequested = true;
      return;
    }
    if (name === "rpg_camera_recenter") {
      this.cameras.main.startFollow(this.player, true, 0.12, 0.12, 0, 12);
      return;
    }
    if (name === "rpg_camera_zoom") {
      const delta = Number(payload?.delta) || 0;
      this.cameras.main.setZoom(Phaser.Math.Clamp(this.cameras.main.zoom + delta, 0.9, 1.35));
    }
  }

  private drawRoom(): void {
    this.textures.get(DORM_HUB_MAP_KEY).setFilter(Phaser.Textures.FilterMode.NEAREST);
    this.add.image(0, 0, DORM_HUB_MAP_KEY).setOrigin(0).setDepth(0);
    this.createRoomColliders();
  }

  private createRoomColliders(): void {
    const showDebug = new URLSearchParams(window.location.search).get("debugColliders") === "1";
    for (const rect of DORM_STATIC_COLLISION_RECTS) {
      const obstacle = this.add.rectangle(
        (rect.left + rect.right) / 2,
        (rect.top + rect.bottom) / 2,
        rect.right - rect.left,
        rect.bottom - rect.top,
        showDebug ? 0xff315b : 0x000000,
        showDebug ? 0.18 : 0
      ).setDepth(4000);
      if (showDebug) obstacle.setStrokeStyle(2, 0xffd743, 0.9);
      this.obstacles.add(obstacle);
    }
  }

  private createHud(): void {
    this.interactionPrompt = this.add.text(RPG_HUD_LAYOUT.centerX, RPG_HUD_LAYOUT.promptBottomY, "", {
      color: "#fff7d6",
      backgroundColor: "#152128e8",
      fontFamily: "monospace",
      fontSize: "14px",
      padding: { x: 10, y: 6 },
      stroke: "#0b1115",
      strokeThickness: 2
    }).setOrigin(0.5, 1).setScrollFactor(0).setDepth(10000).setVisible(false);

    this.feedbackText = this.add.text(RPG_HUD_LAYOUT.centerX, RPG_HUD_LAYOUT.feedbackBottomY, "", {
      color: "#eef7f3",
      backgroundColor: "#10212be8",
      fontFamily: "monospace",
      fontSize: "14px",
      align: "center",
      wordWrap: { width: 620 },
      padding: { x: 12, y: 8 },
      stroke: "#091014",
      strokeThickness: 2
    }).setOrigin(0.5, 1).setScrollFactor(0).setDepth(10000).setAlpha(0);
  }

  private createInteractionTargets(): void {
    for (const target of DORM_INTERACTION_TARGETS) {
      this.add.zone(target.x, target.y, target.width, target.height)
        .setInteractive({ useHandCursor: true })
        .on("pointerdown", () => {
          const distance = this.player
            ? distanceToDormTarget(this.player.x, this.player.y, target)
            : Number.POSITIVE_INFINITY;
          if (distance <= target.proximity + 24) {
            this.triggerInteraction(target);
          } else {
            this.showFeedback(`先走近一点，再${target.label}。`);
            this.pulseTarget(target, 0x7fd8ff);
          }
        });
    }
  }

  private createAmbientAnimations(): void {
    const windowLight = this.add.rectangle(491, 181, 232, 214, 0x7fd7ff, 0.035).setDepth(900);
    this.tweens.add({ targets: windowLight, alpha: 0.095, duration: 2400, yoyo: true, repeat: -1, ease: "Sine.easeInOut" });

    this.curtainLeft = this.add.rectangle(386, 153, 22, 158, 0x24599c, 0.16).setDepth(950);
    this.curtainRight = this.add.rectangle(596, 153, 22, 158, 0x24599c, 0.16).setDepth(950);
    this.tweens.add({ targets: this.curtainLeft, x: 389, angle: 1.5, duration: 1800, yoyo: true, repeat: -1, ease: "Sine.easeInOut" });
    this.tweens.add({ targets: this.curtainRight, x: 593, angle: -1.5, duration: 2050, yoyo: true, repeat: -1, ease: "Sine.easeInOut" });

    this.cabinetLeft = this.add.rectangle(453, 315, 63, 153, 0x252a30, 0.88).setStrokeStyle(2, 0x11161b).setDepth(1000);
    this.cabinetRight = this.add.rectangle(523, 315, 63, 153, 0x252a30, 0.88).setStrokeStyle(2, 0x11161b).setDepth(1000);
    this.add.circle(472, 316, 3, 0xc4c9c2).setDepth(1001);
    this.add.circle(504, 316, 3, 0xc4c9c2).setDepth(1001);

    const lampPositions: Array<[DormInteractionTargetId, number, number]> = [
      ["desk_01", 830, 218],
      ["desk_02", 830, 486],
      ["desk_03", 830, 758],
      ["desk_04", 830, 1048]
    ];
    lampPositions.forEach(([id, x, y], index) => {
      const glow = this.add.circle(x - 18, y + 24, 64, index % 2 === 0 ? 0x84b7ff : 0xffdf8a, 0.045)
        .setBlendMode(Phaser.BlendModes.ADD)
        .setDepth(920);
      this.deskLampGlows.set(id, glow);
      this.tweens.add({ targets: glow, alpha: 0.085, duration: 1500 + index * 210, yoyo: true, repeat: -1, ease: "Sine.easeInOut" });
    });

    [0, 1, 2].forEach((index) => {
      const steam = this.add.circle(842 + index * 4, 392 - index * 7, 3 - index * 0.45, 0xe6f4f0, 0.34).setDepth(1200);
      this.tweens.add({ targets: steam, y: steam.y - 22, x: steam.x + (index % 2 === 0 ? 5 : -5), alpha: 0, duration: 1550 + index * 260, delay: index * 310, repeat: -1 });
    });

    this.deskDrawer = this.add.rectangle(838, 1218, 72, 18, 0x66411f, 0.86).setStrokeStyle(2, 0x2c1b10).setDepth(1200);
    this.backpackRing = this.add.circle(714, 1382, 52, 0xffd954, 0).setStrokeStyle(2, 0xffd954, 0.22).setDepth(1300);
    this.tweens.add({ targets: this.backpackRing, alpha: 0.32, scale: 1.08, duration: 1150, yoyo: true, repeat: -1, ease: "Sine.easeInOut" });

    this.doorLight = this.add.rectangle(470, 1550, 118, 130, 0xffdf91, 0)
      .setStrokeStyle(2, 0xffe9af, 0)
      .setDepth(1180);
    this.doorPanel = this.add.rectangle(470, 1550, 118, 130, 0x6b3d20, 0.9)
      .setStrokeStyle(5, 0x2c1a11, 0.96)
      .setDepth(1200);
    this.add.rectangle(470, 1492, 106, 6, 0x98613a, 0.8).setDepth(1201);
    this.add.rectangle(470, 1608, 106, 6, 0x3d2417, 0.9).setDepth(1201);
    this.doorHandle = this.add.circle(506, 1557, 5, 0xb5a170, 0.96)
      .setStrokeStyle(2, 0x302a20, 0.9)
      .setDepth(1202);
  }

  private createCampusCardPickup(): void {
    if (this.bridge.getState().actOne.inventoryRecovered) return;
    const pickup = this.add.container(DORM_CAMPUS_CARD.x, DORM_CAMPUS_CARD.y).setDepth(1500).setSize(76, 58).setAngle(-3);
    const glow = this.add.rectangle(0, 0, 52, 35, 0xffe56a, 0.08).setStrokeStyle(2, 0xffe56a, 0.55);
    const shadow = this.add.rectangle(2, 3, 44, 28, 0x251f1a, 0.38);
    const card = this.add.rectangle(0, 0, 44, 28, 0xe7edf0).setStrokeStyle(2, 0x173e77);
    const portrait = this.add.rectangle(-14, 0, 10, 15, 0x6f98c2).setStrokeStyle(1, 0x244c77);
    const head = this.add.circle(-14, -3, 3, 0xe5b98e);
    const body = this.add.rectangle(-14, 5, 6, 5, 0x315d8d);
    const lineA = this.add.rectangle(7, -5, 19, 2, 0x6083a4);
    const lineB = this.add.rectangle(5, 2, 22, 2, 0x8aa0b4);
    const lineC = this.add.rectangle(3, 8, 18, 2, 0x8aa0b4);
    const hitTarget = this.add.rectangle(0, 0, 76, 58, 0xffffff, 0.001).setInteractive({ useHandCursor: true });
    hitTarget.on("pointerdown", () => this.collectCampusCard());
    pickup.add([glow, shadow, card, portrait, head, body, lineA, lineB, lineC, hitTarget]);
    this.campusCardPickup = pickup;
    this.tweens.add({ targets: [glow, pickup], alpha: { from: 0.72, to: 1 }, y: "-=3", duration: 760, yoyo: true, repeat: -1, ease: "Sine.easeInOut" });
  }

  private triggerInteraction(target: DormInteractionTarget): void {
    if (target.id === "exit_door") {
      this.tryExitDorm();
      if (!this.bridge.getState().actOne.canLeaveDorm) this.animateDoorRejection();
      return;
    }

    if (target.id === "desk_03" && !this.bridge.getState().actOne.inventoryRecovered) {
      this.collectCampusCard();
      return;
    }

    switch (target.id) {
      case "upper_bunk":
      case "lower_bunk":
        this.animateBed(target);
        break;
      case "window":
        this.animateCurtains();
        break;
      case "window_cabinet":
        this.animateCabinet();
        break;
      case "shoe_shelf":
      case "laundry_bin":
      case "lower_shelf":
        this.pulseTarget(target, 0xffd75d);
        break;
      case "desk_01":
      case "desk_03":
        this.toggleDeskLamp(target.id);
        break;
      case "desk_02":
        this.animatePageFlip();
        break;
      case "desk_04":
        this.animateDrawer();
        break;
      case "wash_basin":
        this.animateWater();
        break;
      case "floor_backpack":
        this.animateBackpack();
        break;
      default:
        break;
    }
    this.showFeedback(INTERACTION_COPY[target.id]);
  }

  private animateBed(target: DormInteractionTarget): void {
    const ripple = this.add.rectangle(target.x, target.y, target.width - 24, Math.min(170, target.height - 24), 0x5ba7ff, 0)
      .setStrokeStyle(3, 0x8ec8ff, 0.8).setDepth(1300);
    this.tweens.add({ targets: ripple, alpha: 0.7, scaleX: 1.04, duration: 160, yoyo: true, repeat: 2, onComplete: () => ripple.destroy() });
  }

  private animateCurtains(): void {
    this.tweens.killTweensOf([this.curtainLeft, this.curtainRight]);
    this.tweens.add({ targets: this.curtainLeft, x: 365, scaleX: 1.22, duration: 300, yoyo: true, repeat: 1, ease: "Sine.easeInOut" });
    this.tweens.add({ targets: this.curtainRight, x: 617, scaleX: 1.22, duration: 300, yoyo: true, repeat: 1, ease: "Sine.easeInOut" });
  }

  private animateCabinet(): void {
    const opening = !this.toggledInteractions.has("window_cabinet");
    if (opening) this.toggledInteractions.add("window_cabinet");
    else this.toggledInteractions.delete("window_cabinet");
    this.tweens.add({ targets: this.cabinetLeft, x: opening ? 424 : 453, duration: 260, ease: "Stepped" });
    this.tweens.add({ targets: this.cabinetRight, x: opening ? 552 : 523, duration: 260, ease: "Stepped" });
  }

  private toggleDeskLamp(id: DormInteractionTargetId): void {
    const glow = this.deskLampGlows.get(id);
    if (!glow) return;
    const enabled = !this.toggledInteractions.has(id);
    if (enabled) this.toggledInteractions.add(id);
    else this.toggledInteractions.delete(id);
    this.tweens.killTweensOf(glow);
    this.tweens.add({ targets: glow, alpha: enabled ? 0.31 : 0.025, scale: enabled ? 1.12 : 1, duration: 220, ease: "Stepped" });
  }

  private animatePageFlip(): void {
    const page = this.add.rectangle(786, 586, 48, 72, 0xf0ead4, 0.92).setStrokeStyle(2, 0x6a5a42).setDepth(1400);
    this.tweens.add({ targets: page, scaleX: 0.05, angle: 4, duration: 190, yoyo: true, repeat: 1, ease: "Sine.easeInOut", onComplete: () => page.destroy() });
  }

  private animateDrawer(): void {
    const open = !this.toggledInteractions.has("desk_04");
    if (open) this.toggledInteractions.add("desk_04");
    else this.toggledInteractions.delete("desk_04");
    this.tweens.add({ targets: this.deskDrawer, x: open ? 790 : 838, duration: 240, ease: "Stepped" });
  }

  private animateWater(): void {
    [0, 1, 2].forEach((index) => {
      const ring = this.add.circle(164, 1030, 12 + index * 5, 0x7ed9ff, 0).setStrokeStyle(2, 0x7ed9ff, 0.8).setDepth(1450);
      this.tweens.add({ targets: ring, scale: 1.8, alpha: 0, duration: 620, delay: index * 120, onComplete: () => ring.destroy() });
    });
  }

  private animateBackpack(): void {
    this.tweens.add({ targets: this.backpackRing, angle: 8, scale: 1.22, alpha: 0.75, duration: 120, yoyo: true, repeat: 3 });
  }

  private animateDoorRejection(): void {
    const door = this.add.rectangle(470, 1536, 140, 104, 0x6f3e1e, 0.35).setStrokeStyle(3, 0xc99355, 0.75).setDepth(1600);
    this.tweens.add({ targets: door, x: "+=6", duration: 55, yoyo: true, repeat: 5, onComplete: () => door.destroy() });
  }

  private animateDoorOpening(): void {
    this.doorLight.setAlpha(0.9).setStrokeStyle(2, 0xffe9af, 0.85);
    this.tweens.add({
      targets: this.doorLight,
      alpha: { from: 0.15, to: 0.95 },
      scaleX: { from: 0.18, to: 1 },
      duration: 280,
      ease: "Stepped"
    });
    this.tweens.add({
      targets: [this.doorPanel, this.doorHandle],
      x: "-=54",
      scaleX: 0.08,
      duration: 360,
      ease: "Stepped"
    });
    this.cameras.main.flash(90, 255, 238, 190, false);
  }

  private pulseTarget(target: DormInteractionTarget, color: number): void {
    const pulse = this.add.rectangle(target.x, target.y, target.width + 12, target.height + 12, color, 0)
      .setStrokeStyle(3, color, 0.85).setDepth(1600);
    this.tweens.add({ targets: pulse, alpha: 0.75, scale: 1.05, duration: 160, yoyo: true, repeat: 1, onComplete: () => pulse.destroy() });
  }

  private updatePrompt(target: DormInteractionTarget | null, nearCard: boolean): void {
    if (nearCard) {
      this.interactionPrompt.setText(formatRpgInteractionHint("拾取校园卡")).setVisible(true);
      return;
    }
    if (target) {
      this.interactionPrompt.setText(formatRpgInteractionHint(target.label)).setVisible(true);
      return;
    }
    this.interactionPrompt.setVisible(false);
  }

  private showFeedback(text: string): void {
    this.feedbackTween?.stop();
    this.feedbackText.setText(text).setAlpha(0).setVisible(true);
    this.feedbackTween = this.tweens.add({
      targets: this.feedbackText,
      alpha: { from: 0, to: 1 },
      duration: 120,
      hold: 2300,
      yoyo: true,
      ease: "Stepped",
      onComplete: () => this.feedbackText.setVisible(false)
    });
  }

  private tryExitDorm(): void {
    if (this.exitTriggered) return;
    if (this.bridge.getState().actOne.canLeaveDorm) {
      this.exitTriggered = true;
      this.showFeedback("门开了。前往校园地图。");
      this.animateDoorOpening();
      this.time.delayedCall(520, () => this.bridge.emit("rpg_dorm_exit"));
      return;
    }
    this.showFeedback(INTERACTION_COPY.exit_door);
  }

  private collectCampusCard(): void {
    const actOne = this.bridge.getState().actOne;
    if (actOne.inventoryRecovered) {
      this.showFeedback("校园卡已经在物品栏里。");
      return;
    }
    if (actOne.phase !== "prologue" && actOne.phase !== "inventory_required") {
      this.showFeedback("桌上的校园卡暂时还不能拿走。");
      return;
    }
    this.bridge.emit("rpg_campus_card_collected");
    if (!this.bridge.getState().actOne.inventoryRecovered) return;
    this.campusCardPickup?.destroy();
    this.campusCardPickup = undefined;
    this.showFeedback(
      actOne.phase === "prologue"
        ? `获得校园卡：${actOneContent.studentName} · ${actOneContent.studentId}。回手机查看余额。`
        : "校园卡重新放回了物品栏。"
    );
  }

  private updatePlayerAnimation(vector: Phaser.Math.Vector2): void {
    if (vector.lengthSq() > 0) {
      if (Math.abs(vector.x) > Math.abs(vector.y)) {
        this.facing = "side";
        this.player.setFlipX(vector.x < 0);
      } else {
        this.facing = vector.y < 0 ? "up" : "down";
        this.player.setFlipX(false);
      }
      const nextFrame = Math.floor(this.time.now / 130) % 2;
      if (nextFrame !== this.walkingFrame || this.player.texture.key !== `act1-player-${this.facing}-${nextFrame}`) {
        this.walkingFrame = nextFrame;
        this.player.setTexture(`act1-player-${this.facing}-${nextFrame}`);
      }
      return;
    }
    if (this.walkingFrame !== 0 || this.player.texture.key !== `act1-player-${this.facing}-0`) {
      this.walkingFrame = 0;
      this.player.setTexture(`act1-player-${this.facing}-0`);
    }
  }

  private publishRuntimeDebug(): void {
    const state = this.bridge.getState();
    const activeTargets: NonNullable<RpgRuntimeDebugState["activeTargets"]> = DORM_INTERACTION_TARGETS.map((target) => ({
      id: target.id,
      x: target.x,
      y: target.y,
      width: target.width,
      height: target.height
    }));
    if (!state.actOne.inventoryRecovered) {
      activeTargets.push({ id: "campus_card", x: DORM_CAMPUS_CARD.x, y: DORM_CAMPUS_CARD.y, width: 76, height: 58 });
    }
    setRpgRuntimeDebugState({
      coordinateSystem: "Phaser world coordinates, origin at top-left, x right, y down",
      scene: "dorm_hub",
      checkpoint: state.rpgCheckpoint,
      world: { width: DORM_HUB_WORLD.width, height: DORM_HUB_WORLD.height },
      player: { x: this.player.x, y: this.player.y, facing: this.facing },
      input: {
        gameEnabled: this.game.input.enabled,
        sceneEnabled: this.input.enabled,
        keyboardEnabled: this.input.keyboard?.enabled ?? false,
        keys: {
          up: this.cursors.up.isDown || this.keys.W.isDown,
          down: this.cursors.down.isDown || this.keys.S.isDown,
          left: this.cursors.left.isDown || this.keys.A.isDown,
          right: this.cursors.right.isDown || this.keys.D.isDown,
          interact: this.cursors.space.isDown
        }
      },
      camera: {
        scrollX: this.cameras.main.scrollX,
        scrollY: this.cameras.main.scrollY,
        zoom: this.cameras.main.zoom,
        mode: "follow"
      },
      activeTargets,
      collisionRects: DORM_STATIC_COLLISION_RECTS
    });
  }
}
