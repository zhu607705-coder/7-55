import Phaser from "phaser";
import dormHubMapUrl from "../../assets/rpg/interiors/dorm_hub.png";
import actOneContent from "../../data/act-one-bootstrap.content.json";
import type { RpgBridge } from "./RpgBridge";
import {
  configureRpgPlayerSprite,
  ensureRpgPlayerTextures,
  preloadRpgPlayerTextures,
  RPG_PLAYER_NAME_OFFSET_Y,
  type RpgPlayerFacing
} from "./RpgPlayerTextures";
import { subscribeRpgSceneBridge } from "./RpgSceneBridgeSubscription";

const DORM_HUB_MAP_KEY = "dorm-hub-gpt-image-map";

export class DormHubScene extends Phaser.Scene {
  private bridge!: RpgBridge;
  private player!: Phaser.Physics.Arcade.Sprite;
  private obstacles!: Phaser.Physics.Arcade.StaticGroup;
  private cursors!: Phaser.Types.Input.Keyboard.CursorKeys;
  private keys!: Record<"W" | "A" | "S" | "D", Phaser.Input.Keyboard.Key>;
  private virtualDirection = { x: 0, y: 0 };
  private interactRequested = false;
  private messageShown = false;
  private exitTriggered = false;
  private manualMovementReported = false;
  private pacingDirection = 1;
  private walkingFrame = 0;
  private facing: RpgPlayerFacing = "down";
  private characterName!: Phaser.GameObjects.Text;
  private campusCardPickup?: Phaser.GameObjects.Container;

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
    this.physics.world.setBounds(12, 12, 936, 516);
    this.obstacles = this.physics.add.staticGroup();
    this.drawRoom();
    this.createCampusCardPickup();
    ensureRpgPlayerTextures(this);
    this.player = this.physics.add.sprite(480, 468, "act1-player-down-0").setCollideWorldBounds(true);
    configureRpgPlayerSprite(this.player);
    this.physics.add.collider(this.player, this.obstacles);
    this.player.setInteractive({ useHandCursor: true });
    this.player.on("pointerdown", () => this.bridge.emit("rpg_character_inspected"));
    this.characterName = this.add.text(480, 432, "", {
      color: "#fff7df",
      backgroundColor: "#17212add",
      fontFamily: "monospace",
      fontSize: "10px",
      padding: { x: 4, y: 2 }
    }).setOrigin(0.5).setDepth(520);
    this.cursors = this.input.keyboard!.createCursorKeys();
    this.keys = this.input.keyboard!.addKeys("W,A,S,D") as Record<"W" | "A" | "S" | "D", Phaser.Input.Keyboard.Key>;

    const exitZone = this.add.zone(480, 520, 108, 24);
    this.physics.add.existing(exitZone, true);
    this.physics.add.overlap(this.player, exitZone, () => {
      if (this.bridge.getState().actOne.canLeaveDorm && !this.exitTriggered) {
        this.exitTriggered = true;
        this.bridge.emit("rpg_dorm_exit");
      }
    });

    subscribeRpgSceneBridge(this.events, this.bridge, (event) => {
      if (event.name === "rpg_direction_changed") {
        this.virtualDirection = { x: Number(event.payload?.x) || 0, y: Number(event.payload?.y) || 0 };
      }
      if (event.name === "rpg_interact") {
        this.interactRequested = true;
      }
    });
    this.bridge.emit("rpg_booted", { scene: "dorm_hub" });
    this.bridge.emit("rpg_dorm_room_opened");
  }

  update(): void {
    const actOne = this.bridge.getState().actOne;
    const movementEnabled = actOne.movementEnabled;
    const x = Number(this.cursors.right.isDown || this.keys.D.isDown) - Number(this.cursors.left.isDown || this.keys.A.isDown) + this.virtualDirection.x;
    const y = Number(this.cursors.down.isDown || this.keys.S.isDown) - Number(this.cursors.up.isDown || this.keys.W.isDown) + this.virtualDirection.y;
    const vector = new Phaser.Math.Vector2(x, y);
    if (movementEnabled && vector.lengthSq() > 0) {
      vector.normalize().scale(130);
      if (!this.manualMovementReported) {
        this.manualMovementReported = true;
        this.bridge.emit("rpg_manual_movement_started");
      }
    } else if (actOne.exerciseStarted && !actOne.gamepadPurchased) {
      if (this.player.x >= 586) this.pacingDirection = -1;
      if (this.player.x <= 374) this.pacingDirection = 1;
      vector.set(this.pacingDirection * 72, 0);
    } else {
      vector.set(0, 0);
    }
    this.player.setVelocity(vector.x, vector.y).setDepth(this.player.y + 20);
    this.updatePlayerAnimation(vector);
    this.characterName
      .setText(actOne.characterNamed ? actOneContent.studentName : "")
      .setVisible(actOne.characterNamed)
      .setPosition(this.player.x, this.player.y - RPG_PLAYER_NAME_OFFSET_Y)
      .setDepth(this.player.y + 40);
    const keyboardInteract = Phaser.Input.Keyboard.JustDown(this.cursors.space);
    const interact = keyboardInteract || this.interactRequested;
    const nearCampusCard = !actOne.inventoryRecovered
      && Phaser.Math.Distance.Between(this.player.x, this.player.y, 718, 250) < 132;
    if (nearCampusCard && interact) {
      this.collectCampusCard();
      this.interactRequested = false;
      return;
    }
    const nearDesk = Phaser.Math.Distance.Between(this.player.x, this.player.y, 755, 300) < 138;
    if (nearDesk && interact && !this.messageShown) {
      this.messageShown = true;
      this.bridge.emit("toast", { text: actOneContent.dorm.roommateMessage, tone: "task", durationMs: 5200 });
    }
    this.interactRequested = false;
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

  private createCampusCardPickup(): void {
    if (this.bridge.getState().actOne.inventoryRecovered) {
      return;
    }
    const pickup = this.add.container(718, 250).setDepth(520).setSize(70, 52).setAngle(-4);
    const glow = this.add.rectangle(0, 0, 46, 31, 0xffe56a, 0.06).setStrokeStyle(1, 0xffe56a, 0.34);
    const shadow = this.add.rectangle(1, 2, 38, 23, 0x251f1a, 0.34);
    const card = this.add.rectangle(0, 0, 38, 23, 0xe7edf0).setStrokeStyle(2, 0x173e77);
    const portrait = this.add.rectangle(-12, 0, 9, 13, 0x6f98c2).setStrokeStyle(1, 0x244c77);
    const head = this.add.circle(-12, -2, 2.5, 0xe5b98e);
    const body = this.add.rectangle(-12, 4, 5, 4, 0x315d8d);
    const lineA = this.add.rectangle(6, -4, 17, 2, 0x6083a4);
    const lineB = this.add.rectangle(4, 2, 20, 2, 0x8aa0b4);
    const lineC = this.add.rectangle(2, 7, 16, 2, 0x8aa0b4);
    const hitTarget = this.add.rectangle(0, 0, 70, 52, 0xffffff, 0.001).setInteractive({ useHandCursor: true });
    hitTarget.on("pointerdown", () => this.collectCampusCard());
    pickup.add([glow, shadow, card, portrait, head, body, lineA, lineB, lineC, hitTarget]);
    this.campusCardPickup = pickup;
    this.tweens.add({ targets: glow, alpha: 0.18, duration: 780, yoyo: true, repeat: -1, ease: "Stepped" });
  }

  private collectCampusCard(): void {
    const actOne = this.bridge.getState().actOne;
    if (actOne.inventoryRecovered) {
      this.bridge.emit("toast", { text: "校园卡已经在物品栏里。", tone: "system", durationMs: 2600 });
      return;
    }
    if (actOne.phase !== "prologue" && actOne.phase !== "inventory_required") {
      this.bridge.emit("toast", { text: "桌上的校园卡暂时还不能拿走。", tone: "system", durationMs: 2600 });
      return;
    }
    this.bridge.emit("rpg_campus_card_collected");
    if (this.bridge.getState().actOne.inventoryRecovered) {
      this.campusCardPickup?.destroy();
      this.campusCardPickup = undefined;
      this.bridge.emit("toast", {
        text: actOne.phase === "prologue"
          ? `获得校园卡：${actOneContent.studentName} · ${actOneContent.studentId}。回手机看看余额。`
          : "旧存档已恢复：校园卡重新放回道具栏。",
        tone: "task",
        durationMs: 5200
      });
    }
  }

  private drawRoom(): void {
    this.textures.get(DORM_HUB_MAP_KEY).setFilter(Phaser.Textures.FilterMode.NEAREST);
    this.add.image(480, 270, DORM_HUB_MAP_KEY).setDisplaySize(960, 540).setDepth(0);
    this.createRoomColliders();

    this.add.text(480, 506, actOneContent.dorm.exitLabel, {
      color: "#ffffff",
      backgroundColor: "#17212acc",
      fontFamily: "monospace",
      fontSize: "12px",
      padding: { x: 5, y: 3 }
    }).setOrigin(0.5).setDepth(500);

    this.add.zone(770, 300, 300, 390).setInteractive({ useHandCursor: true }).on("pointerdown", () => {
      this.bridge.emit("toast", { text: actOneContent.dorm.roommateMessage, tone: "task", durationMs: 3200 });
    });
    this.add.zone(480, 78, 116, 108).setInteractive({ useHandCursor: true }).on("pointerdown", () => {
      this.bridge.emit("toast", { text: "门锁着。你现在连离开寝室都要先完成系统流程。", tone: "system", durationMs: 3200 });
    });
  }

  private createRoomColliders(): void {
    const addObstacle = (x: number, y: number, width: number, height: number) => {
      const obstacle = this.add.rectangle(x, y, width, height, 0x000000, 0).setDepth(y);
      this.obstacles.add(obstacle);
    };

    addObstacle(164, 238, 230, 390);
    addObstacle(795, 258, 310, 452);
    addObstacle(558, 150, 84, 78);
  }

  private drawFloorAndWalls(): void {
    this.add.rectangle(480, 278, 760, 404, 0x77624c).setStrokeStyle(8, 0x2d241f);
    for (let y = 132; y <= 452; y += 24) {
      this.add.line(480, y, -306, 0, 306, 0, 0x4f4035, 0.34).setOrigin(0.5).setDepth(1);
    }
    for (let x = 124; x <= 836; x += 54) {
      this.add.line(x, 286, 0, -160, 0, 160, 0xa38b6f, 0.15).setOrigin(0.5).setDepth(1);
    }
    this.add.rectangle(480, 104, 760, 64, 0xc8bea8).setStrokeStyle(4, 0x554b40).setDepth(64);
    this.add.rectangle(480, 126, 760, 9, 0x5f5145).setDepth(66);
    this.add.rectangle(480, 420, 250, 54, 0x5a5047, 0.42).setStrokeStyle(2, 0x3c342e, 0.5).setDepth(2);
    for (let x = 378; x <= 582; x += 34) {
      this.add.rectangle(x, 420, 16, 46, x % 68 === 4 ? 0x7d5a47 : 0x53656d, 0.42).setDepth(3);
    }
  }

  private drawWindow(): void {
    const frame = this.add.rectangle(598, 101, 120, 54, 0x34434a).setStrokeStyle(5, 0x4f4236).setDepth(82);
    this.add.rectangle(598, 101, 108, 42, 0x7ea4ae).setDepth(83);
    this.add.rectangle(598, 112, 108, 18, 0x415e64, 0.62).setDepth(84);
    this.add.rectangle(598, 101, 5, 43, 0xd7d0bd).setDepth(85);
    this.add.rectangle(598, 101, 109, 4, 0xd7d0bd).setDepth(85);
    [560, 579, 618, 640].forEach((x, index) => {
      this.add.line(x, 94 + index * 3, 0, 0, -4, 22, 0xd9edf0, 0.7).setLineWidth(2).setDepth(86);
    });
    frame.setInteractive({ useHandCursor: true }).on("pointerdown", () => {
      this.bridge.emit("toast", { text: "窗外还在下雨。去图书馆的路不会因此缩短。", tone: "system", durationMs: 3200 });
    });
  }

  private drawBunkBed(x: number, y: number, width: number, height: number): void {
    const collision = this.add.rectangle(x, y, width, height, 0x000000, 0).setDepth(y);
    this.obstacles.add(collision);
    this.add.rectangle(x, y, width, height, 0x493c35).setStrokeStyle(5, 0x211c19).setDepth(y - 3);
    const levels = [y - 72, y + 62];
    levels.forEach((levelY, index) => {
      this.add.rectangle(x + 4, levelY, width - 20, 82, 0x244b6a).setStrokeStyle(4, 0x172c3b).setDepth(levelY);
      this.add.rectangle(x + 5, levelY - 9, width - 28, 51, index === 0 ? 0x355f82 : 0x2d5676).setDepth(levelY + 1);
      for (let stripe = -36; stripe <= 36; stripe += 18) {
        this.add.rectangle(x + stripe, levelY - 9, 4, 51, 0xd4b45f, 0.46).setDepth(levelY + 2);
      }
      this.add.rectangle(x - 35, levelY - 12, 31, 25, 0xe1d7bd).setDepth(levelY + 3);
    });
    this.add.rectangle(x - width / 2 + 9, y, 9, height - 12, 0x788087).setStrokeStyle(2, 0x30373b).setDepth(y + 2);
    this.add.rectangle(x + width / 2 - 9, y, 9, height - 12, 0x788087).setStrokeStyle(2, 0x30373b).setDepth(y + 2);
    for (let rung = -54; rung <= 55; rung += 22) {
      this.add.rectangle(x + width / 2 - 23, y + rung, 27, 5, 0xa4a8a5).setDepth(y + 4);
    }
    this.add.rectangle(x + width / 2 - 23, y, 5, 132, 0x8b918f).setDepth(y + 3);
    this.add.rectangle(x - 42, y + 2, 36, 54, 0x202c36).setStrokeStyle(2, 0x10171c).setDepth(y + 5);
    this.add.text(x - 42, y + 2, "W12", { color: "#d9d8d1", fontFamily: "monospace", fontSize: "9px" })
      .setOrigin(0.5).setDepth(y + 6);
  }

  private drawDeskRow(x: number, y: number, width: number, height: number): void {
    const collision = this.add.rectangle(x, y, width, height, 0x000000, 0).setDepth(y);
    this.obstacles.add(collision);
    this.add.rectangle(x, y - 55, width, 110, 0x91663e).setStrokeStyle(4, 0x3e2c21).setDepth(y - 4);
    [-50, 0, 50].forEach((offset, index) => {
      this.add.rectangle(x + offset, y - 83, 45, 45, index === 1 ? 0x31485a : 0x5a4330).setStrokeStyle(2, 0x30251e).setDepth(y - 2);
      this.add.rectangle(x + offset, y - 35, 44, 27, 0xceb183).setStrokeStyle(2, 0x56422e).setDepth(y + 2);
      this.add.rectangle(x + offset + 8, y - 39, 17, 11, 0xe4ddc9).setDepth(y + 3);
      this.add.circle(x + offset - 14, y - 41, 7, index === 0 ? 0x638c78 : 0x456a8d).setDepth(y + 4);
      this.add.rectangle(x + offset, y + 20, 38, 43, 0x514036).setStrokeStyle(3, 0x2b211c).setDepth(y + 6);
      this.add.rectangle(x + offset, y + 49, 48, 13, 0x6f5949).setDepth(y + 7);
    });
    this.add.rectangle(x, y + 80, width - 8, 42, 0x6f5036).setStrokeStyle(3, 0x38291f).setDepth(y + 8);
    this.add.rectangle(x - 48, y + 80, 35, 32, 0x42576b).setDepth(y + 9);
    this.add.rectangle(x + 3, y + 80, 35, 32, 0x7b6044).setDepth(y + 9);
    this.add.rectangle(x + 52, y + 80, 35, 32, 0x536b55).setDepth(y + 9);
  }

  private drawWardrobe(x: number, y: number, width: number, height: number): void {
    const collision = this.add.rectangle(x, y, width, height, 0x000000, 0).setDepth(y);
    this.obstacles.add(collision);
    this.add.rectangle(x, y, width, height, 0x8a613d).setStrokeStyle(4, 0x3d2d22).setDepth(y);
    this.add.rectangle(x, y, 3, height - 8, 0x493728).setDepth(y + 1);
    this.add.circle(x - 8, y, 2.5, 0xd1bd83).setDepth(y + 2);
    this.add.circle(x + 8, y, 2.5, 0xd1bd83).setDepth(y + 2);
  }

  private drawCommonTable(x: number, y: number, width: number, height: number): void {
    const collision = this.add.rectangle(x, y, width, height, 0x000000, 0).setDepth(y);
    this.obstacles.add(collision);
    this.add.rectangle(x + 3, y + 7, width, height, 0x765136, 0.48).setDepth(y - 2);
    this.add.rectangle(x, y, width, height, 0xb08a5d).setStrokeStyle(4, 0x4b3425).setDepth(y);
    this.add.rectangle(x - 68, y + 25, 12, 55, 0x5e402d).setDepth(y + 1);
    this.add.rectangle(x + 68, y + 25, 12, 55, 0x5e402d).setDepth(y + 1);
    this.add.rectangle(x - 61, y + 8, 27, 17, 0xe3d8bc).setAngle(-7).setDepth(y + 2);
    this.add.rectangle(x + 58, y + 5, 18, 26, 0x486c5f).setStrokeStyle(2, 0x284339).setDepth(y + 2);
  }

  private drawShoeRack(x: number, y: number): void {
    this.add.rectangle(x, y, 104, 44, 0x4f4035).setStrokeStyle(3, 0x2a221d).setDepth(92);
    for (let shelf = 0; shelf < 2; shelf += 1) {
      for (let pair = 0; pair < 3; pair += 1) {
        const shoeX = x - 34 + pair * 34;
        const shoeY = y - 9 + shelf * 20;
        this.add.ellipse(shoeX - 5, shoeY, 15, 7, shelf === 0 ? 0xd7d4c8 : 0x58708a).setDepth(94);
        this.add.ellipse(shoeX + 7, shoeY, 15, 7, shelf === 0 ? 0xd7d4c8 : 0x58708a).setDepth(94);
      }
    }
  }

  private drawCeilingFan(): void {
    const fan = this.add.container(470, 106).setDepth(96);
    const hub = this.add.circle(0, 0, 8, 0x5c625e).setStrokeStyle(2, 0x303431);
    const blades = [0, 90, 180, 270].map((angle) =>
      this.add.rectangle(0, -17, 8, 31, 0x747b76).setOrigin(0.5, 1).setAngle(angle)
    );
    fan.add([...blades, hub]);
    this.tweens.add({ targets: fan, angle: 360, duration: 5200, repeat: -1, ease: "Linear" });
  }

  private drawClutter(): void {
    const poster = this.add.rectangle(303, 101, 72, 42, 0xe4d9bf).setStrokeStyle(3, 0x695744).setDepth(86);
    this.add.text(303, 101, "海纳江河\n启真厚德", {
      color: "#8d3028",
      align: "center",
      fontFamily: "monospace",
      fontSize: "10px",
      lineSpacing: 1
    }).setOrigin(0.5).setDepth(87);
    poster.setInteractive({ useHandCursor: true }).on("pointerdown", () => {
      this.bridge.emit("toast", { text: "墙上的字很端正。你的出勤记录暂时没有这种待遇。", tone: "system", durationMs: 3200 });
    });
    const lampGlow = this.add.circle(746, 185, 28, 0xffd777, 0.12).setDepth(182);
    this.add.rectangle(746, 181, 6, 25, 0x4b4d49).setAngle(22).setDepth(184);
    this.add.triangle(754, 169, -13, 8, 13, 8, 0, -9, 0xc9b274).setDepth(185);
    this.tweens.add({ targets: lampGlow, alpha: 0.22, duration: 1600, yoyo: true, repeat: -1 });
    this.add.circle(326, 150, 10, 0x6f8a51).setDepth(146);
    this.add.rectangle(326, 162, 19, 14, 0x865236).setDepth(147);
  }
}
