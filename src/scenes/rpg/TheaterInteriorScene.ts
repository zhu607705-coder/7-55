import Phaser from "phaser";
import theaterInteriorMapUrl from "../../assets/rpg/interiors/theater_interior.png";
import ticketInspectorIdleUrl from "../../assets/rpg/theater/generated/actors/ticket_inspector_idle_front.png";
import ticketInspectorScanUrl from "../../assets/rpg/theater/generated/actors/ticket_inspector_scan_front.png";
import stageManagerGhostIdleUrl from "../../assets/rpg/theater/generated/actors/stage_manager_ghost_idle.png";
import stageManagerGhostPointUrl from "../../assets/rpg/theater/generated/actors/stage_manager_ghost_point.png";
import propBoxGhostUrl from "../../assets/rpg/theater/generated/effects/clue_prop_box_ghost.png";
import paperFuturePathUrl from "../../assets/rpg/theater/generated/effects/clue_paper_future_path.png";
import spotlightBeamArtUrl from "../../assets/rpg/theater/generated/effects/spotlight_beam.png";
import spotlightFaultStripUrl from "../../assets/rpg/theater/generated/effects/spotlight_fault_strip.png";
import spotlightHitRingUrl from "../../assets/rpg/theater/generated/effects/spotlight_hit_ring.png";
import spotlightSparksUrl from "../../assets/rpg/theater/generated/effects/spotlight_sparks.png";
import programOpeningUrl from "../../assets/rpg/theater/generated/icons/item_theater_program_opening.png";
import programSpotlightUrl from "../../assets/rpg/theater/generated/icons/item_theater_program_spotlight.png";
import programFinaleUrl from "../../assets/rpg/theater/generated/icons/item_theater_program_finale.png";
import paperFlightUrl from "../../assets/rpg/theater/generated/paper/paper_flight_0.png";
import paperResidualUrl from "../../assets/rpg/theater/generated/paper/paper_residual.png";
import paperFluorescentUrl from "../../assets/rpg/theater/generated/paper/paper_fluorescent.png";
import paperLockedUrl from "../../assets/rpg/theater/generated/effects/paper_reversal_locked.png";
import paperCrackedUrl from "../../assets/rpg/theater/generated/effects/paper_reversal_cracked.png";
import paperEscapeUrl from "../../assets/rpg/theater/generated/effects/paper_reversal_escape.png";
import paperFragmentsUrl from "../../assets/rpg/theater/generated/effects/paper_reversal_fragments.png";
import type { GameSubtitleTone } from "../../components/GameSubtitleFrame";
import type { GameState, ItemId, TheaterMode, TheaterProgramId } from "../../core/types";
import theaterContent from "../../data/chapter3-theater.content.json";
import { formatRpgDragHint, formatRpgInteractionHint } from "./RpgControlHints";
import { RPG_HUD_LAYOUT } from "./RpgHudLayout";
import {
  formatRpgModeRequirement,
  isPlayerWithinRpgTarget,
  resolveRpgItemDrop
} from "./RpgInteractionContract";
import {
  configureRpgPlayerSprite,
  ensureRpgPlayerTextures,
  preloadRpgPlayerTextures,
  RpgPlayerAnimator,
  RPG_PLAYER_WALK_FPS
} from "./RpgPlayerTextures";
import { clearRpgRuntimeDebugState, setRpgRuntimeDebugState } from "./RpgRuntimeDebug";
import { subscribeRpgSceneBridge } from "./RpgSceneBridgeSubscription";
import {
  requireTheaterRuntimePort,
  selectTheaterRuntimeSpawnZone,
  type TheaterRuntimePort
} from "./TheaterRuntimeContract";
import {
  getTheaterSpotlightAssist,
  THEATER_SPOTLIGHT_ROUNDS,
  type TheaterSpotlightFailureReason,
  type TheaterSpotlightLane
} from "./TheaterSpotlightModel";
import {
  THEATER_AUDITORIUM_SPAWN,
  THEATER_GATE_BLOCKER,
  THEATER_INTERACTION_TARGETS,
  THEATER_INTERIOR_WORLD,
  THEATER_LOBBY_SPAWN,
  THEATER_OCCLUSION_RECTS,
  THEATER_STAGE_SPAWN,
  THEATER_STATIC_COLLISION_RECTS,
  findNearestTheaterTarget,
  type TheaterInteractionTarget
} from "./TheaterInteriorModel";

const THEATER_MAP_KEY = "chapter-3-theater-interior-map";
const THEATER_PAPER_KEY = "chapter-3-theater-paper";
const THEATER_PAPER_RESIDUAL_KEY = "chapter-3-theater-paper-residual";
const THEATER_PAPER_FLUORESCENT_KEY = "chapter-3-theater-paper-fluorescent";
const THEATER_PAPER_LOCKED_KEY = "chapter-3-theater-paper-locked";
const THEATER_PAPER_CRACKED_KEY = "chapter-3-theater-paper-cracked";
const THEATER_PAPER_ESCAPE_KEY = "chapter-3-theater-paper-escape";
const THEATER_PAPER_FRAGMENTS_KEY = "chapter-3-theater-paper-fragments";
const THEATER_INSPECTOR_IDLE_KEY = "chapter-3-theater-inspector-idle";
const THEATER_INSPECTOR_SCAN_KEY = "chapter-3-theater-inspector-scan";
const THEATER_MANAGER_GHOST_IDLE_KEY = "chapter-3-theater-manager-ghost-idle";
const THEATER_MANAGER_GHOST_POINT_KEY = "chapter-3-theater-manager-ghost-point";
const THEATER_PROP_GHOST_KEY = "chapter-3-theater-prop-ghost";
const THEATER_PAPER_PATH_KEY = "chapter-3-theater-paper-path";
const THEATER_SPOTLIGHT_BEAM_ART_KEY = "chapter-3-theater-spotlight-beam-art";
const THEATER_SPOTLIGHT_HIT_RING_KEY = "chapter-3-theater-spotlight-hit-ring";
const THEATER_SPOTLIGHT_SPARKS_KEY = "chapter-3-theater-spotlight-sparks";
const THEATER_SPOTLIGHT_FAULT_KEY = "chapter-3-theater-spotlight-fault";
const THEATER_PROGRAM_KEYS: Record<TheaterProgramId, string> = {
  opening: "chapter-3-theater-program-opening",
  spotlight: "chapter-3-theater-program-spotlight",
  finale: "chapter-3-theater-program-finale"
};
const WALK_SPEED = 165;
const RUN_SPEED = 228;
const DIALOGUE_STEP_MS = 2500;
// Feedback subtitle tiers: instant result, confirmation, guidance, clue, task update.
const FEEDBACK_INSTANT_MS = 1400;
const FEEDBACK_CONFIRM_MS = 1800;
const FEEDBACK_GUIDANCE_MS = 2400;
const FEEDBACK_CLUE_MS = 3000;
// Lines opening with one of these prefixes keep the narrator/system tone but get
// their own speaker label on the shared subtitle frame.
const THEATER_DIALOGUE_SPEAKERS = ["检票员", "取票机", "灯控台", "手机系统"] as const;
const THEATER_TICKET_FIXTURE_COLLISION_RECTS = [
  {
    id: "ticket_inspector_fixture",
    left: 720,
    top: 633,
    right: 786,
    bottom: 786
  },
  {
    id: "ticket_reader_fixture",
    left: 883,
    top: 650,
    right: 931,
    bottom: 786
  }
] as const;

interface OcclusionVisual {
  id: string;
  bounds: Phaser.Geom.Rectangle;
  sortY: number;
  image: Phaser.GameObjects.Image;
}

interface ProgramVisual {
  container: Phaser.GameObjects.Container;
  glow: Phaser.GameObjects.Arc;
}

interface PanelButtonHitArea {
  x: number;
  y: number;
  width: number;
  height: number;
  action: () => void;
}

interface TicketDropGuideVisual {
  target: TheaterInteractionTarget;
  targetOutline: Phaser.GameObjects.Rectangle;
}

interface TheaterTargetMarker {
  target: TheaterInteractionTarget;
  container: Phaser.GameObjects.Container;
  ring: Phaser.GameObjects.Arc;
  glyph: Phaser.GameObjects.Text;
}

interface PendingFeedback {
  text: string;
  tone: GameSubtitleTone;
  durationMs: number;
  speaker?: string;
}

type SpotlightStage = "idle" | "preview" | "ready" | "tracking" | "hit" | "miss";

function theaterDropTargetLabel(kind: TheaterInteractionTarget["kind"]): string {
  return {
    poster: "入口海报",
    gate: "检票闸机右侧读票器",
    scanner: "道具箱旁票据扫描器",
    vent: "后台通风口",
    console: "灯光控制台",
    kiosk: "取票机",
    program: "节目单",
    prop: "道具箱",
    exit: "剧院出口"
  }[kind];
}

export class TheaterInteriorScene extends Phaser.Scene {
  private runtime!: TheaterRuntimePort;
  private player!: Phaser.Physics.Arcade.Sprite;
  private playerAnimator!: RpgPlayerAnimator;
  private obstacles!: Phaser.Physics.Arcade.StaticGroup;
  private gateBlocker: Phaser.GameObjects.Rectangle | null = null;
  private cursors!: Phaser.Types.Input.Keyboard.CursorKeys;
  private keys!: Record<"W" | "A" | "S" | "D" | "SHIFT" | "TAB", Phaser.Input.Keyboard.Key>;
  private virtualDirection = { x: 0, y: 0 };
  private interactRequested = false;
  private promptText!: Phaser.GameObjects.Text;
  private darkOverlay!: Phaser.GameObjects.Rectangle;
  private currentMode: TheaterMode = "light";
  private currentPhase: GameState["theaterHunt"]["phase"] = "entry_ticket";
  private reducedMotion = false;
  private dialogueLocked = false;
  private paperBusy = false;
  private ticketCombinePending = false;
  private occlusionVisuals: OcclusionVisual[] = [];
  private activeOcclusionIds: string[] = [];
  private softenedOcclusionIds: string[] = [];
  private programVisuals = new Map<TheaterProgramId, ProgramVisual>();
  private darkClues: Array<Phaser.GameObjects.Rectangle | Phaser.GameObjects.Text> = [];
  private programOrderClue!: Phaser.GameObjects.Text;
  private propGhostClue!: Phaser.GameObjects.Text;
  private paper!: Phaser.GameObjects.Image;
  private panel: Phaser.GameObjects.Container | null = null;
  private panelKind: "code" | "program" | null = null;
  private panelButtons: PanelButtonHitArea[] = [];
  private panelOpeningPointerDownTime = -1;
  private codeInput = "";
  private codeDisplay: Phaser.GameObjects.Text | null = null;
  private spotlightPanel: Phaser.GameObjects.Container | null = null;
  private spotlightTitle: Phaser.GameObjects.Text | null = null;
  private spotlightStatus: Phaser.GameObjects.Text | null = null;
  private spotlightPaper: Phaser.GameObjects.Image | null = null;
  private spotlightDecoyPaper: Phaser.GameObjects.Image | null = null;
  private spotlightConsoleGuide: Phaser.GameObjects.Container | null = null;
  private spotlightPathPreview: Phaser.GameObjects.Graphics | null = null;
  private spotlightBeam: Phaser.GameObjects.Graphics | null = null;
  private spotlightBeamArt: Phaser.GameObjects.Image | null = null;
  private spotlightAimRing: Phaser.GameObjects.Arc | null = null;
  private spotlightAimMarker: Phaser.GameObjects.Arc | null = null;
  private spotlightFireButton: Phaser.GameObjects.Rectangle | null = null;
  private spotlightFireLabel: Phaser.GameObjects.Text | null = null;
  private spotlightControlHint: Phaser.GameObjects.Text | null = null;
  private spotlightTimeBar: Phaser.GameObjects.Rectangle | null = null;
  private spotlightLockBar: Phaser.GameObjects.Rectangle | null = null;
  private spotlightLockText: Phaser.GameObjects.Text | null = null;
  private spotlightAssistText: Phaser.GameObjects.Text | null = null;
  private spotlightStage: SpotlightStage = "idle";
  private spotlightAimX = 0;
  private spotlightActionElapsedMs = 0;
  private spotlightCurrentLockMs = 0;
  private spotlightMaxContinuousLockMs = 0;
  private spotlightFirstBeamAtMs: number | null = null;
  private spotlightEarlyExposureMs = 0;
  private spotlightBeamActivated = false;
  private spotlightPointerAiming = false;
  private spotlightPointerFiring = false;
  private spotlightBeamActive = false;
  private spotlightDecoyOverlap = false;
  private spotlightLastFailureReason: TheaterSpotlightFailureReason | null = null;
  private spotlightPreviewTween: Phaser.Tweens.Tween | null = null;
  private spotlightVisualTweens: Phaser.Tweens.Tween[] = [];
  private spotlightDelayTimers: Phaser.Time.TimerEvent[] = [];
  private spotlightChoiceOpen = false;
  private ticketInspector: Phaser.GameObjects.Container | null = null;
  private ticketInspectorSprite: Phaser.GameObjects.Image | null = null;
  private ticketInspectorArm: Phaser.GameObjects.Rectangle | null = null;
  private ticketReader: Phaser.GameObjects.Container | null = null;
  private ticketReaderLight: Phaser.GameObjects.Rectangle | null = null;
  private ticketDropGuides = new Map<string, TicketDropGuideVisual>();
  private targetMarkers = new Map<string, TheaterTargetMarker>();
  private pendingFeedback: PendingFeedback[] = [];
  private lastFeedbackUntilMs = 0;
  private stageManagerGhost: Phaser.GameObjects.Image | null = null;
  private propBoxGhostSprite: Phaser.GameObjects.Image | null = null;
  private paperFuturePathSprite: Phaser.GameObjects.Image | null = null;

  constructor() {
    super("theater-interior");
  }

  preload(): void {
    if (!this.textures.exists(THEATER_MAP_KEY)) {
      this.load.image(THEATER_MAP_KEY, theaterInteriorMapUrl);
    }
    const art: Array<[string, string]> = [
      [THEATER_PAPER_KEY, paperFlightUrl],
      [THEATER_PAPER_RESIDUAL_KEY, paperResidualUrl],
      [THEATER_PAPER_FLUORESCENT_KEY, paperFluorescentUrl],
      [THEATER_PAPER_LOCKED_KEY, paperLockedUrl],
      [THEATER_PAPER_CRACKED_KEY, paperCrackedUrl],
      [THEATER_PAPER_ESCAPE_KEY, paperEscapeUrl],
      [THEATER_PAPER_FRAGMENTS_KEY, paperFragmentsUrl],
      [THEATER_INSPECTOR_IDLE_KEY, ticketInspectorIdleUrl],
      [THEATER_INSPECTOR_SCAN_KEY, ticketInspectorScanUrl],
      [THEATER_MANAGER_GHOST_IDLE_KEY, stageManagerGhostIdleUrl],
      [THEATER_MANAGER_GHOST_POINT_KEY, stageManagerGhostPointUrl],
      [THEATER_PROP_GHOST_KEY, propBoxGhostUrl],
      [THEATER_PAPER_PATH_KEY, paperFuturePathUrl],
      [THEATER_SPOTLIGHT_BEAM_ART_KEY, spotlightBeamArtUrl],
      [THEATER_SPOTLIGHT_HIT_RING_KEY, spotlightHitRingUrl],
      [THEATER_SPOTLIGHT_SPARKS_KEY, spotlightSparksUrl],
      [THEATER_SPOTLIGHT_FAULT_KEY, spotlightFaultStripUrl],
      [THEATER_PROGRAM_KEYS.opening, programOpeningUrl],
      [THEATER_PROGRAM_KEYS.spotlight, programSpotlightUrl],
      [THEATER_PROGRAM_KEYS.finale, programFinaleUrl]
    ];
    art.forEach(([key, url]) => {
      if (!this.textures.exists(key)) this.load.image(key, url);
    });
    preloadRpgPlayerTextures(this);
  }

  create(): void {
    this.runtime = requireTheaterRuntimePort(this.registry.get("theaterRuntimePort"));
    const state = this.runtime.getState();
    this.reducedMotion = window.matchMedia?.("(prefers-reduced-motion: reduce)").matches === true;
    this.currentMode = state.theaterHunt.mode;
    this.currentPhase = state.theaterHunt.phase;
    this.cameras.main.setBackgroundColor(0x09070a);
    this.physics.world.setBounds(66, 18, THEATER_INTERIOR_WORLD.width - 132, THEATER_INTERIOR_WORLD.height - 42);
    this.obstacles = this.physics.add.staticGroup();
    this.drawInterior(state.theaterHunt.admitted);
    this.ensureTheaterTextures();
    ensureRpgPlayerTextures(this);

    const spawn = this.resolveSpawn(state);
    this.player = this.physics.add.sprite(spawn.x, spawn.y, "act1-player-up-0");
    this.player.setCollideWorldBounds(true).setDepth(spawn.y + 120);
    configureRpgPlayerSprite(this.player);
    this.playerAnimator = new RpgPlayerAnimator(this.player, "up");
    this.physics.add.collider(this.player, this.obstacles);

    this.cursors = this.input.keyboard!.createCursorKeys();
    this.keys = this.input.keyboard!.addKeys("W,A,S,D,SHIFT,TAB") as Record<
      "W" | "A" | "S" | "D" | "SHIFT" | "TAB",
      Phaser.Input.Keyboard.Key
    >;
    this.input.keyboard!.addCapture(Phaser.Input.Keyboard.KeyCodes.TAB);
    this.input.keyboard!.addCapture(Phaser.Input.Keyboard.KeyCodes.SPACE);
    const keyHandler = (event: KeyboardEvent) => this.handlePanelKey(event);
    const pointerHandler = (pointer: Phaser.Input.Pointer) => this.handlePanelPointer(pointer);
    const pointerMoveHandler = (pointer: Phaser.Input.Pointer) => this.handleSpotlightPointerMove(pointer);
    const pointerUpHandler = () => this.handleSpotlightPointerUp();
    this.input.keyboard!.on("keydown", keyHandler);
    this.input.on("pointerdown", pointerHandler);
    this.input.on("pointermove", pointerMoveHandler);
    this.input.on("pointerup", pointerUpHandler);
    this.events.once(Phaser.Scenes.Events.SHUTDOWN, () => {
      this.input.keyboard?.off("keydown", keyHandler);
      this.input.off("pointerdown", pointerHandler);
      this.input.off("pointermove", pointerMoveHandler);
      this.input.off("pointerup", pointerUpHandler);
      this.destroySpotlightPanel();
    });

    this.cameras.main
      .setBounds(0, 0, THEATER_INTERIOR_WORLD.width, THEATER_INTERIOR_WORLD.height)
      .setZoom(1)
      .startFollow(this.player, true, 0.13, 0.13, 0, 24)
      .setDeadzone(250, 150);

    this.createProgramFragments();
    this.createTicketInspectionPoint();
    this.createTicketDropGuides();
    this.syncTicketInspectionPoint(state);
    this.createWorldHotspots();
    // Interactions attach to the visible fixtures; no floating world markers.
    this.createModeLayer();
    this.createPrompt();
    this.createPaper();
    this.syncWorldFromState(state, true);

    subscribeRpgSceneBridge(
      this.events,
      this.runtime,
      (event) => this.handleBridgeEvent(event.name, event.payload),
      clearRpgRuntimeDebugState
    );
    this.runtime.setRpgLocation(
      "theater_interior",
      state.theaterHunt.admitted ? state.rpgCheckpoint === "theater_stage" ? "theater_stage" : "theater_auditorium" : "theater_lobby"
    );
    this.runtime.emit("rpg_booted", { scene: "theater_interior", checkpoint: this.runtime.getState().rpgCheckpoint });
    this.runtime.emit("theater_interior_opened");

    if (this.currentPhase === "entry_ticket" && !state.theaterHunt.posterCleaned && !state.theaterHunt.ticketCodeRead) {
      this.dialogueLocked = true;
      this.time.delayedCall(this.reducedMotion ? 160 : 1100, () => {
        this.queueDialogue(theaterContent.entryDialogue, () => { this.dialogueLocked = false; });
      });
    } else if (this.currentPhase === "spotlight_hunt") {
      this.beginSpotlightRound();
    } else if (this.currentPhase === "reversal") {
      this.animateReversal();
    }
  }

  update(_time: number, delta: number): void {
    const state = this.runtime.getState();
    this.syncWorldFromState(state);
    this.updateSpotlightRound(delta);

    if (Phaser.Input.Keyboard.JustDown(this.keys.TAB) && !this.panel && !this.spotlightPanel && !this.dialogueLocked) {
      this.requestModeToggle();
    }

    const keyboardX = Number(this.cursors.right.isDown || this.keys.D.isDown)
      - Number(this.cursors.left.isDown || this.keys.A.isDown);
    const keyboardY = Number(this.cursors.down.isDown || this.keys.S.isDown)
      - Number(this.cursors.up.isDown || this.keys.W.isDown);
    const vector = new Phaser.Math.Vector2(
      Phaser.Math.Clamp(keyboardX + this.virtualDirection.x, -1, 1),
      Phaser.Math.Clamp(keyboardY + this.virtualDirection.y, -1, 1)
    );
    // Text overlays only pause interactions. Movement remains available while
    // the subtitle is visible, unless a real panel or animation is active.
    const movementAllowed = state.actOne.movementEnabled
      && !this.paperBusy
      && !this.panel
      && !this.spotlightPanel;
    if (movementAllowed && vector.lengthSq() > 0) {
      vector.normalize().scale(this.keys.SHIFT.isDown ? RUN_SPEED : WALK_SPEED);
    } else {
      vector.set(0, 0);
    }
    this.player.setVelocity(vector.x, vector.y).setDepth(this.player.y + 120);
    this.playerAnimator.update(vector, this.time.now);
    this.updateOcclusion();

    const targets = this.getActiveTargets(state);
    const nearest = findNearestTheaterTarget(this.player.x, this.player.y, targets);
    this.updatePrompt(nearest, state);
    this.publishDebugState(nearest, state);
    const keyboardInteract = Phaser.Input.Keyboard.JustDown(this.cursors.space);
    if (nearest && !this.dialogueLocked && !this.paperBusy && !this.panel && !this.spotlightPanel && (keyboardInteract || this.interactRequested)) {
      this.triggerTarget(nearest, state);
    }
    this.interactRequested = false;
  }

  private resolveSpawn(state: GameState): { x: number; y: number } {
    const spawnZone = selectTheaterRuntimeSpawnZone(state);
    if (spawnZone === "lobby") return THEATER_LOBBY_SPAWN;
    if (spawnZone === "stage") return THEATER_STAGE_SPAWN;
    return THEATER_AUDITORIUM_SPAWN;
  }

  private drawInterior(admitted: boolean): void {
    this.add.image(0, 0, THEATER_MAP_KEY).setOrigin(0).setDepth(-1000);
    this.occlusionVisuals = THEATER_OCCLUSION_RECTS.map((definition) => ({
      id: definition.id,
      bounds: new Phaser.Geom.Rectangle(
        definition.left,
        definition.top,
        definition.right - definition.left,
        definition.bottom - definition.top
      ),
      sortY: definition.sortY,
      image: this.add.image(0, 0, THEATER_MAP_KEY)
        .setOrigin(0)
        .setCrop(definition.left, definition.top, definition.right - definition.left, definition.bottom - definition.top)
        .setDepth(-900)
        .setVisible(false)
    }));
    const collisionVisible = import.meta.env.DEV
      && new URLSearchParams(window.location.search).get("rpgCollision") === "1";
    THEATER_STATIC_COLLISION_RECTS.forEach((rect) => {
      const collision = this.add.rectangle(
        (rect.left + rect.right) / 2,
        (rect.top + rect.bottom) / 2,
        rect.right - rect.left,
        rect.bottom - rect.top,
        collisionVisible ? 0xff3355 : 0x000000,
        collisionVisible ? 0.24 : 0
      ).setDepth(collisionVisible ? 4900 : rect.bottom - 20);
      if (collisionVisible) collision.setStrokeStyle(2, 0xffd4dc, 0.9);
      this.obstacles.add(collision);
    });
    if (!admitted) {
      this.gateBlocker = this.add.rectangle(
        (THEATER_GATE_BLOCKER.left + THEATER_GATE_BLOCKER.right) / 2,
        (THEATER_GATE_BLOCKER.top + THEATER_GATE_BLOCKER.bottom) / 2,
        THEATER_GATE_BLOCKER.right - THEATER_GATE_BLOCKER.left,
        THEATER_GATE_BLOCKER.bottom - THEATER_GATE_BLOCKER.top,
        collisionVisible ? 0xffcc33 : 0x000000,
        collisionVisible ? 0.28 : 0
      ).setDepth(collisionVisible ? 4901 : 680);
      this.obstacles.add(this.gateBlocker);
    }
  }

  private updateOcclusion(): void {
    const body = this.player.body as Phaser.Physics.Arcade.Body | null;
    const footY = body?.bottom ?? this.player.y;
    const playerBounds = this.player.getBounds();
    const active: string[] = [];
    const softened: string[] = [];
    this.occlusionVisuals.forEach((visual) => {
      const horizontalOverlap = playerBounds.right > visual.bounds.left && playerBounds.left < visual.bounds.right;
      const behind = horizontalOverlap && footY < visual.sortY - 1;
      const intersects = behind && Phaser.Geom.Intersects.RectangleToRectangle(playerBounds, visual.bounds);
      const targetAlpha = intersects ? 0.52 : 1;
      visual.image
        .setDepth(behind ? this.player.depth + 2 : -900)
        .setVisible(behind)
        .setAlpha(this.reducedMotion ? targetAlpha : Phaser.Math.Linear(visual.image.alpha, targetAlpha, 0.18));
      if (behind) active.push(visual.id);
      if (intersects) softened.push(visual.id);
    });
    this.activeOcclusionIds = active;
    this.softenedOcclusionIds = softened;
  }

  private ensureTheaterTextures(): void {
    if (!this.textures.exists(THEATER_PAPER_KEY)) {
      const g = this.add.graphics();
      g.fillStyle(0x101820, 0.3).fillEllipse(18, 27, 34, 9);
      g.fillStyle(0xeee9db).fillPoints([
        new Phaser.Geom.Point(4, 4),
        new Phaser.Geom.Point(31, 7),
        new Phaser.Geom.Point(27, 30),
        new Phaser.Geom.Point(7, 27)
      ], true);
      g.lineStyle(2, 0x66dfff, 0.95).strokePoints([
        new Phaser.Geom.Point(4, 4),
        new Phaser.Geom.Point(31, 7),
        new Phaser.Geom.Point(27, 30),
        new Phaser.Geom.Point(7, 27)
      ], true);
      g.lineStyle(2, 0x5c6670, 0.8).lineBetween(10, 12, 25, 14).lineBetween(9, 18, 23, 20);
      g.generateTexture(THEATER_PAPER_KEY, 36, 34);
      g.destroy();
    }
    Object.values(THEATER_PROGRAM_KEYS).forEach((key) => {
      if (this.textures.exists(key)) return;
      const g = this.add.graphics();
      g.fillStyle(0xf3ead4).fillRect(2, 2, 30, 24);
      g.lineStyle(2, 0x6e2f33).strokeRect(2, 2, 30, 24);
      g.lineStyle(2, 0x8e6b55).lineBetween(8, 9, 26, 9).lineBetween(8, 14, 24, 14).lineBetween(8, 19, 20, 19);
      g.generateTexture(key, 34, 28);
      g.destroy();
    });
  }

  private createProgramFragments(): void {
    THEATER_INTERACTION_TARGETS.filter((target) => target.kind === "program").forEach((target) => {
      const programId = target.programId!;
      const glow = this.add.circle(0, 0, 26, 0x2aaeff, 0.16)
        .setStrokeStyle(4, 0x83e4ff, 0.94);
      const image = this.add.image(0, 0, THEATER_PROGRAM_KEYS[programId]).setDisplaySize(48, 48);
      const container = this.add.container(target.x, target.y, [glow, image])
        .setDepth(target.y + 40)
        .setSize(58, 50)
        .setInteractive({ useHandCursor: true })
        .on("pointerover", () => {
          image.setScale(1.14);
          glow.setStrokeStyle(4, 0xbef4ff, 1);
        })
        .on("pointerout", () => {
          image.setScale(1);
          glow.setStrokeStyle(4, 0x83e4ff, 0.94);
        })
        .on("pointerdown", () => this.triggerPointerTarget(target));
      this.tweens.add({
        targets: glow,
        scale: { from: 0.82, to: 1.18 },
        alpha: { from: 0.3, to: 0.9 },
        duration: 820,
        yoyo: true,
        repeat: -1,
        ease: "Sine.easeInOut"
      });
      this.programVisuals.set(programId, { container, glow });
    });
  }

  private createTicketInspectionPoint(): void {
    const gateTarget = THEATER_INTERACTION_TARGETS.find((target) => target.kind === "gate");
    if (!gateTarget) return;

    const inspectorShadow = this.add.ellipse(0, 31, 42, 12, 0x09080c, 0.48);
    this.ticketInspectorSprite = this.add.image(0, -16, THEATER_INSPECTOR_IDLE_KEY)
      .setScale(0.75)
      .setOrigin(0.5);
    this.ticketInspectorArm = null;
    this.ticketInspector = this.add.container(753, 681, [
      inspectorShadow,
      this.ticketInspectorSprite
    ])
      .setDepth(832)
      .setSize(66, 86)
      .setInteractive({ useHandCursor: true })
      .on("pointerover", () => this.ticketInspector?.setScale(1.06))
      .on("pointerout", () => this.ticketInspector?.setScale(1))
      .on("pointerdown", () => this.triggerPointerTarget(gateTarget));

    const readerShadow = this.add.ellipse(0, 29, 35, 11, 0x09080c, 0.5);
    const readerStem = this.add.rectangle(0, 8, 22, 42, 0x263443).setStrokeStyle(3, 0x101820, 0.95);
    const readerHead = this.add.rectangle(0, -18, 34, 25, 0x182431).setStrokeStyle(3, 0x090f18, 0.95);
    this.ticketReaderLight = this.add.rectangle(0, -20, 20, 8, 0x58d7f2, 0.9)
      .setStrokeStyle(1, 0xb6f5ff, 0.9);
    const readerSlot = this.add.rectangle(0, -10, 22, 3, 0xd8bd72, 0.92);
    const readerLabel = this.add.text(0, 9, "验票", {
      color: "#e8d9b9",
      fontFamily: "monospace",
      fontSize: "9px"
    }).setOrigin(0.5);
    this.ticketReader = this.add.container(907, 690, [
      readerShadow,
      readerStem,
      readerHead,
      this.ticketReaderLight,
      readerSlot,
      readerLabel
    ])
      .setDepth(839)
      .setSize(48, 72)
      .setInteractive({ useHandCursor: true })
      .on("pointerover", () => this.ticketReader?.setScale(1.06))
      .on("pointerout", () => this.ticketReader?.setScale(1))
      .on("pointerdown", () => this.triggerPointerTarget(gateTarget));

    const collisionVisible = import.meta.env.DEV
      && new URLSearchParams(window.location.search).get("rpgCollision") === "1";
    THEATER_TICKET_FIXTURE_COLLISION_RECTS.forEach((bounds) => {
      const collision = this.add.rectangle(
        (bounds.left + bounds.right) / 2,
        (bounds.top + bounds.bottom) / 2,
        bounds.right - bounds.left,
        bounds.bottom - bounds.top,
        collisionVisible ? 0xffcc33 : 0x000000,
        collisionVisible ? 0.28 : 0
      ).setDepth(collisionVisible ? 4901 : bounds.bottom);
      if (collisionVisible) collision.setStrokeStyle(2, 0xfff0ad, 0.9);
      this.obstacles.add(collision);
    });

    if (!this.reducedMotion) {
      this.tweens.add({
        targets: this.ticketInspector,
        y: 680,
        duration: 1350,
        yoyo: true,
        repeat: -1,
        ease: "Sine.easeInOut"
      });
      this.tweens.add({
        targets: this.ticketReaderLight,
        alpha: { from: 0.55, to: 1 },
        duration: 760,
        yoyo: true,
        repeat: -1,
        ease: "Sine.easeInOut"
      });
    }
  }

  private syncTicketInspectionPoint(state: GameState): void {
    const interactive = !state.theaterHunt.admitted && state.theaterHunt.phase === "entry_ticket";
    [this.ticketInspector, this.ticketReader].forEach((object) => {
      if (!object) return;
      if (interactive) object.setInteractive({ useHandCursor: true });
      else object.disableInteractive();
    });
    if (state.theaterHunt.admitted) {
      this.ticketReaderLight?.setFillStyle(0x64e58d, 1).setStrokeStyle(1, 0xd5ffe0, 1);
    }
  }

  private createTicketDropGuides(): void {
    THEATER_INTERACTION_TARGETS
      .filter((target) => (
        target.acceptedItem
        && target.dropWidth
        && target.dropHeight
      ))
      .forEach((target) => {
        const dropWidth = target.dropWidth!;
        const dropHeight = target.dropHeight!;
        const targetOutline = this.add.rectangle(
          target.x,
          target.y,
          dropWidth,
          dropHeight,
          0x000000,
          0
        )
          .setStrokeStyle(2, 0x72dcff, 0.9)
          .setDepth(2240)
          .setVisible(false);
        this.ticketDropGuides.set(target.id, { target, targetOutline });
      });
  }

  private syncTicketDropGuides(state: GameState): void {
    this.ticketDropGuides.forEach((guide) => {
      const phaseReady = guide.target.kind === "poster"
        ? state.theaterHunt.phase === "entry_ticket"
          && !state.theaterHunt.posterCleaned
        : guide.target.kind === "gate"
          ? state.theaterHunt.phase === "entry_ticket"
            && !state.theaterHunt.admitted
          : guide.target.kind === "scanner"
            ? state.theaterHunt.phase === "prop_setup"
              && state.theaterHunt.managerHintRead
              && !state.theaterHunt.propBoxOpened
            : guide.target.kind === "vent"
              ? state.theaterHunt.phase === "prop_setup"
                && state.theaterHunt.propBoxOpened
                && !state.theaterHunt.paperDusted
              : guide.target.kind === "console"
                ? state.theaterHunt.phase === "spotlight_ready"
                  && state.theaterHunt.paperDusted
                : false;
      const visible = state.ui.selectedItem === guide.target.acceptedItem
        && state.theaterHunt.mode === guide.target.requiredMode
        && phaseReady;
      guide.targetOutline.setVisible(visible);
      if (!visible) return;

      const ready = isPlayerWithinRpgTarget(guide.target, this.player.x, this.player.y);
      guide.targetOutline.setStrokeStyle(ready ? 3 : 2, ready ? 0x63e58b : 0x72dcff, 0.92);
    });
  }

  private createWorldHotspots(): void {
    const bounds: Record<string, { x: number; y: number; width: number; height: number }> = {
      theater_poster: { x: 278, y: 755, width: 365, height: 160 },
      theater_ticket_kiosk: { x: 1146, y: 755, width: 100, height: 150 },
      theater_ticket_gate: { x: 907, y: 690, width: 112, height: 126 },
      theater_light_console: { x: 1140, y: 500, width: 130, height: 110 },
      theater_prop_box: { x: 292, y: 166, width: 100, height: 100 },
      theater_prop_scanner: { x: 364, y: 170, width: 76, height: 94 },
      theater_backstage_vent: { x: 936, y: 95, width: 78, height: 55 },
      theater_exit: { x: 836, y: 842, width: 156, height: 92 }
    };
    Object.entries(bounds).forEach(([id, rect]) => {
      const target = THEATER_INTERACTION_TARGETS.find((candidate) => candidate.id === id);
      if (!target) return;
      const hoverFrame = this.add.rectangle(rect.x, rect.y, rect.width, rect.height, 0x7bd8ff, 0.07)
        .setStrokeStyle(3, 0x9fe8ff, 0.9)
        .setDepth(rect.y + 1)
        .setVisible(false);
      this.add.zone(rect.x, rect.y, rect.width, rect.height)
        .setDepth(rect.y + 2)
        .setInteractive({ useHandCursor: true })
        .on("pointerover", () => {
          if (this.panel || this.spotlightPanel) return;
          const state = this.runtime.getState();
          if (!this.getActiveTargets(state).some((candidate) => candidate.id === target.id)) return;
          hoverFrame.setVisible(true);
        })
        .on("pointerout", () => hoverFrame.setVisible(false))
        .on("pointerdown", () => this.triggerPointerTarget(target));
    });
  }

  private createTargetMarkers(): void {
    THEATER_INTERACTION_TARGETS.forEach((target, index) => {
      const isDrop = Boolean(target.acceptedItem);
      const isExit = target.kind === "exit";
      const ring = this.add.circle(0, 0, 10, 0x173331, 0.72).setStrokeStyle(3, 0xe8d46c, 0.95);
      const glyph = this.add.text(0, -1, isDrop ? "↧" : isExit ? "↙" : "·", {
        color: isDrop ? "#8fd7ff" : "#fff6c7",
        fontFamily: "monospace",
        fontSize: isDrop ? "11px" : isExit ? "14px" : "18px",
        fontStyle: "bold"
      }).setOrigin(0.5);
      const lift = (target.dropHeight ?? 72) / 2 + 18;
      const container = this.add.container(target.x, target.y - lift, [ring, glyph])
        .setDepth(2260 + index)
        .setVisible(false);
      if (!this.reducedMotion) {
        this.tweens.add({
          targets: container,
          y: container.y - 3,
          duration: 720 + index * 18,
          yoyo: true,
          repeat: -1,
          ease: "Stepped"
        });
      }
      this.targetMarkers.set(target.id, { target, container, ring, glyph });
    });
  }

  private syncTargetMarkers(state: GameState): void {
    const activeIds = new Set(this.getActiveTargets(state).map((target) => target.id));
    const selectedItem = state.ui.selectedItem;
    this.targetMarkers.forEach((marker, targetId) => {
      const visible = activeIds.has(targetId);
      marker.container.setVisible(visible);
      if (!visible) return;
      const itemMatch = selectedItem !== null && marker.target.acceptedItem === selectedItem;
      marker.ring.setStrokeStyle(itemMatch ? 4 : 3, itemMatch ? 0x7bd8ff : 0xe8d46c, 0.95);
      marker.glyph.setColor(itemMatch ? "#b9ecff" : marker.target.acceptedItem ? "#8fd7ff" : "#fff6c7");
    });
  }

  private createModeLayer(): void {
    this.darkOverlay = this.add.rectangle(
      THEATER_INTERIOR_WORLD.width / 2,
      THEATER_INTERIOR_WORLD.height / 2,
      THEATER_INTERIOR_WORLD.width,
      THEATER_INTERIOR_WORLD.height,
      0x090c24,
      0.6
    ).setDepth(1500).setAlpha(this.currentMode === "dark" ? 0.6 : 0);

    const posterTicket = this.add.rectangle(282, 731, 40, 24, 0x88e8ff, 0.15)
      .setStrokeStyle(3, 0x88e8ff, 0.95).setDepth(1602);
    const posterLabel = this.add.text(282, 731, "A", {
      color: "#c8f7ff", fontFamily: "monospace", fontSize: "17px"
    }).setOrigin(0.5).setDepth(1603);
    const kioskCode = this.add.text(1146, 715, theaterContent.ticket.codeVisible, {
      color: "#94e9ff",
      backgroundColor: "#081423dd",
      fontFamily: "monospace",
      fontSize: "13px",
      padding: { x: 7, y: 4 }
    }).setOrigin(0.5).setDepth(1603);
    this.programOrderClue = this.add.text(836, 286, theaterContent.program.darkOrder, {
      color: "#98e9ff",
      backgroundColor: "#091126dd",
      fontFamily: "monospace",
      fontSize: "15px",
      padding: { x: 9, y: 5 }
    }).setOrigin(0.5).setDepth(1603);
    this.propGhostClue = this.add.text(310, 108, `${theaterContent.prop.ghost}\n${theaterContent.prop.managerHint}`, {
      color: "#9eeaff",
      backgroundColor: "#091126dd",
      fontFamily: "monospace",
      fontSize: "12px",
      align: "center",
      wordWrap: { width: 280 },
      padding: { x: 8, y: 5 }
    }).setOrigin(0.5).setDepth(1603);
    this.propBoxGhostSprite = this.add.image(294, 165, THEATER_PROP_GHOST_KEY)
      .setScale(0.78)
      .setDepth(1603)
      .setVisible(false);
    this.stageManagerGhost = this.add.image(500, 166, THEATER_MANAGER_GHOST_IDLE_KEY)
      .setScale(0.7)
      .setDepth(1604)
      .setVisible(false);
    this.paperFuturePathSprite = this.add.image(835, 180, THEATER_PAPER_PATH_KEY)
      .setScale(0.78)
      .setDepth(2101)
      .setVisible(false);
    if (!this.reducedMotion) {
      this.tweens.add({
        targets: [this.propBoxGhostSprite, this.stageManagerGhost],
        alpha: { from: 0.58, to: 0.9 },
        duration: 760,
        yoyo: true,
        repeat: -1,
        ease: "Stepped"
      });
      this.time.addEvent({
        delay: 720,
        loop: true,
        callback: () => {
          if (!this.stageManagerGhost?.visible) return;
          this.stageManagerGhost.setTexture(
            this.stageManagerGhost.texture.key === THEATER_MANAGER_GHOST_IDLE_KEY
              ? THEATER_MANAGER_GHOST_POINT_KEY
              : THEATER_MANAGER_GHOST_IDLE_KEY
          );
        }
      });
    }
    this.darkClues = [posterTicket, posterLabel, kioskCode, this.programOrderClue, this.propGhostClue];
    this.darkClues.forEach((clue) => clue.setVisible(false));
  }

  private createPrompt(): void {
    this.promptText = this.add.text(RPG_HUD_LAYOUT.centerX, RPG_HUD_LAYOUT.promptBottomY, "", {
      color: "#fff7df",
      fontFamily: "monospace",
      fontSize: "13px",
      stroke: "#07111c",
      strokeThickness: 4,
      align: "center"
    }).setOrigin(0.5, 1).setScrollFactor(0).setDepth(5200).setVisible(false);
  }

  private createPaper(): void {
    const state = this.runtime.getState();
    const paperKey = state.theaterHunt.mode === "dark"
      ? THEATER_PAPER_RESIDUAL_KEY
      : state.theaterHunt.paperDusted
        ? THEATER_PAPER_FLUORESCENT_KEY
        : THEATER_PAPER_KEY;
    this.paper = this.add.image(835, 180, paperKey)
      .setDepth(2100)
      .setVisible(["spotlight_ready", "spotlight_hunt", "reversal"].includes(this.currentPhase));
    this.tweens.add({
      targets: this.paper,
      y: "+=7",
      angle: { from: -4, to: 4 },
      duration: 760,
      yoyo: true,
      repeat: -1,
      ease: "Sine.easeInOut"
    });

    const consoleTarget = THEATER_INTERACTION_TARGETS.find((target) => target.kind === "console");
    if (!consoleTarget) return;
    const guideRing = this.add.circle(0, 0, 45, 0xe7c769, 0.12)
      .setStrokeStyle(5, 0xffdf73, 0.96);
    const guideArrow = this.add.text(0, -60, "↓", {
      color: "#ffdf73",
      fontFamily: "monospace",
      fontSize: "28px"
    }).setOrigin(0.5);
    const guideLabel = this.add.text(0, -92, theaterContent.spotlight.readyHint, {
      color: "#fff4c7",
      backgroundColor: "#17140dee",
      fontFamily: "monospace",
      fontSize: "12px",
      align: "center",
      wordWrap: { width: 270 },
      padding: { x: 8, y: 5 }
    }).setOrigin(0.5, 1);
    this.spotlightConsoleGuide = this.add.container(consoleTarget.x, consoleTarget.y, [guideRing, guideArrow, guideLabel])
      .setDepth(2110)
      .setVisible(this.currentPhase === "spotlight_ready");
    if (!this.reducedMotion) {
      this.tweens.add({
        targets: guideRing,
        scale: { from: 0.88, to: 1.16 },
        alpha: { from: 0.45, to: 1 },
        duration: 760,
        yoyo: true,
        repeat: -1,
        ease: "Sine.easeInOut"
      });
    }
  }

  private handleBridgeEvent(name: string, payload?: Record<string, unknown>): void {
    if (!this.sys?.isActive()) return;
    if (name === "rpg_direction_changed") {
      this.virtualDirection = { x: Number(payload?.x) || 0, y: Number(payload?.y) || 0 };
      return;
    }
    if (name === "rpg_interact") {
      this.interactRequested = true;
      return;
    }
    if (name === "rpg_inventory_drop_requested") {
      this.handleInventoryDrop(payload);
      return;
    }
    if (name === "theater_mode_changed") {
      this.playModeTransition(String(payload?.mode) === "dark" ? "dark" : "light");
      return;
    }
    if (name === "theater_ticket_code_read") {
      this.showFeedback(theaterContent.ticket.codeVisible, "system", FEEDBACK_CLUE_MS);
      return;
    }
    if (name === "theater_ticket_code_panel_opened") {
      this.openCodePanel();
      return;
    }
    if (name === "theater_ticket_code_wrong") {
      this.showFeedback(theaterContent.ticket.codeWrong, "system", FEEDBACK_CONFIRM_MS);
      return;
    }
    if (name === "theater_ticket_commission_required") {
      this.showFeedback(theaterContent.ticket.commissionRequired, "system", FEEDBACK_CONFIRM_MS);
      return;
    }
    if (name === "theater_ticket_phone_release_required") {
      this.closePanel();
      this.showFeedback(theaterContent.ticket.phoneReleaseRequired, "system", FEEDBACK_CONFIRM_MS);
      return;
    }
    if (name === "theater_ticket_printed") {
      this.closePanel();
      this.queueDialogue([theaterContent.ticket.ticketPrinted]);
      return;
    }
    if (name === "theater_ticket_already_delivered") {
      this.closePanel();
      return;
    }
    if (name === "theater_poster_cleaned") {
      this.animatePosterCleaned();
      return;
    }
    if (name === "theater_ticket_halves_ready") {
      this.ticketCombinePending = true;
      this.animateTicketCombine();
      return;
    }
    if (name === "theater_ticket_combined") {
      return;
    }
    if (name === "theater_ticket_admitted") {
      this.animateAdmission();
      return;
    }
    if (name === "theater_program_collected") {
      this.animateProgramCollected(String(payload?.programId) as TheaterProgramId);
      return;
    }
    if (name === "theater_program_order_read") {
      this.showFeedback(theaterContent.program.darkOrder, "system", FEEDBACK_CLUE_MS);
      return;
    }
    if (name === "theater_program_order_changed") {
      if (this.panelKind === "program") this.refreshProgramPanel();
      return;
    }
    if (name === "theater_program_order_wrong") {
      this.queueDialogue(theaterContent.program.wrongDialogue);
      if (this.panelKind === "program") this.refreshProgramPanel();
      return;
    }
    if (name === "theater_program_order_solved") {
      this.closePanel();
      return;
    }
    if (name === "theater_prop_ghost_read") {
      this.queueDialogue([theaterContent.prop.ghost, theaterContent.prop.managerHint]);
      return;
    }
    if (name === "theater_prop_box_locked") {
      this.showFeedback(theaterContent.prop.locked, "system", FEEDBACK_CONFIRM_MS);
      return;
    }
    if (name === "theater_prop_box_opened") {
      this.animatePropBoxOpened();
      return;
    }
    if (name === "theater_paper_dusted") {
      this.animateVentDust();
      return;
    }
    if (name === "theater_spotlight_started") {
      this.beginSpotlightRound();
      return;
    }
    if (name === "theater_spotlight_hit") {
      this.animateSpotlightHit(false);
      return;
    }
    if (name === "theater_spotlight_missed") {
      this.animateSpotlightMiss(payload);
      return;
    }
    if (name === "theater_spotlight_third_hit") {
      this.animateSpotlightHit(true);
      return;
    }
    if (name === "theater_reversal_completed") {
      this.queueDialogue(theaterContent.spotlight.endingDialogue.slice(0, 2), () => {
        this.runtime.emit("theater_decoy_inspect_requested");
      });
      return;
    }
    if (name === "theater_decoy_inspect_closed") {
      this.queueDialogue(theaterContent.spotlight.endingDialogue.slice(2));
    }
  }

  private requestModeToggle(): void {
    const state = this.runtime.getState();
    if (!state.theaterHunt.active || ["reversal", "complete"].includes(state.theaterHunt.phase)) return;
    const mode: TheaterMode = state.theaterHunt.mode === "light" ? "dark" : "light";
    this.runtime.emit("rpg_theater_mode_requested", { mode });
  }

  private playModeTransition(mode: TheaterMode): void {
    this.currentMode = mode;
    this.tweens.killTweensOf(this.darkOverlay);
    this.tweens.add({
      targets: this.darkOverlay,
      alpha: mode === "dark" ? 0.6 : 0,
      duration: this.reducedMotion ? 120 : 450,
      ease: "Sine.easeInOut"
    });
    this.syncDarkClues(this.runtime.getState());
    this.runtime.emit(mode === "dark" ? "theater_dark_mode_enabled" : "theater_light_mode_enabled");
  }

  private syncDarkClues(state: GameState): void {
    const dark = state.theaterHunt.mode === "dark";
    const posterVisible = dark && state.theaterHunt.phase === "entry_ticket" && !state.theaterHunt.posterCleaned;
    const kioskVisible = dark && state.theaterHunt.phase === "entry_ticket";
    this.darkClues[0]?.setVisible(posterVisible);
    this.darkClues[1]?.setVisible(posterVisible);
    this.darkClues[2]?.setVisible(kioskVisible);
    this.programOrderClue?.setVisible(
      dark && state.theaterHunt.phase === "program_search" && state.theaterHunt.collectedProgramIds.length === 3
    );
    const propGhostVisible = dark && state.theaterHunt.phase === "prop_setup" && !state.theaterHunt.propBoxOpened;
    this.propGhostClue?.setVisible(propGhostVisible);
    this.propBoxGhostSprite?.setVisible(propGhostVisible);
    this.stageManagerGhost?.setVisible(propGhostVisible);
    this.paperFuturePathSprite?.setVisible(dark && state.theaterHunt.phase === "spotlight_ready");
  }

  private getActiveTargets(state: GameState): TheaterInteractionTarget[] {
    if (state.theaterHunt.phase === "entry_ticket") {
      return THEATER_INTERACTION_TARGETS.filter((target) => ["poster", "kiosk", "gate"].includes(target.kind));
    }
    if (state.theaterHunt.phase === "program_search") {
      return THEATER_INTERACTION_TARGETS.filter((target) => (
        target.kind === "console"
        || (target.kind === "program"
          && target.programId !== undefined
          && !state.theaterHunt.collectedProgramIds.includes(target.programId))
      ));
    }
    if (state.theaterHunt.phase === "prop_setup") {
      return THEATER_INTERACTION_TARGETS.filter((target) => ["prop", "scanner", "vent"].includes(target.kind));
    }
    if (state.theaterHunt.phase === "spotlight_ready") {
      return THEATER_INTERACTION_TARGETS.filter((target) => target.kind === "console");
    }
    if (state.theaterHunt.phase === "complete") {
      return THEATER_INTERACTION_TARGETS.filter((target) => target.kind === "exit");
    }
    return [];
  }

  private triggerTarget(target: TheaterInteractionTarget, state: GameState): void {
    if (target.kind === "exit") {
      this.runtime.emit("rpg_theater_exit_requested");
      return;
    }
    if (target.kind === "poster") {
      this.showFeedback(theaterContent.ticket.posterGlare, "system", FEEDBACK_GUIDANCE_MS);
      return;
    }
    if (target.kind === "kiosk") {
      if (state.theaterHunt.cc98TicketCommissionPhase === "delivered") {
        return;
      }
      this.runtime.emit("rpg_theater_ticket_kiosk_requested");
      return;
    }
    if (target.kind === "gate") {
      this.showFeedback(theaterContent.ticket.gateDenied, "narrator", FEEDBACK_CONFIRM_MS);
      return;
    }
    if (target.kind === "program" && target.programId) {
      if (state.theaterHunt.mode === "light") {
        this.runtime.emit("rpg_theater_program_collect_requested", { programId: target.programId });
      } else if (state.theaterHunt.collectedProgramIds.length === 3) {
        this.runtime.emit("rpg_theater_program_order_read_requested");
      } else {
        this.showFeedback(theaterContent.program.darkIncomplete, "system", FEEDBACK_GUIDANCE_MS);
      }
      return;
    }
    if (target.kind === "console") {
      if (state.theaterHunt.phase === "program_search") {
        if (state.theaterHunt.mode === "dark") {
          if (state.theaterHunt.collectedProgramIds.length === 3) {
            this.runtime.emit("rpg_theater_program_order_read_requested");
          } else {
            this.showFeedback(theaterContent.program.darkIncomplete, "system", FEEDBACK_GUIDANCE_MS);
          }
        } else if (state.theaterHunt.collectedProgramIds.length === 3) {
          this.openProgramPanel();
        } else {
          this.queueDialogue([theaterContent.program.consolePrompt, theaterContent.program.consoleState]);
        }
      } else if (state.theaterHunt.phase === "spotlight_ready") {
        return;
      }
      return;
    }
    if (target.kind === "prop") {
      if (state.theaterHunt.propBoxOpened) {
        this.showFeedback(theaterContent.prop.opened, "system", FEEDBACK_GUIDANCE_MS);
        return;
      }
      this.runtime.emit("rpg_theater_prop_inspect_requested");
      return;
    }
    if (target.kind === "scanner") {
      this.showFeedback(
        state.theaterHunt.mode === "dark" ? theaterContent.prop.managerHint : theaterContent.prop.locked,
        "system",
        state.theaterHunt.mode === "dark" ? FEEDBACK_CLUE_MS : FEEDBACK_CONFIRM_MS
      );
      return;
    }
    if (target.kind === "vent") {
      return;
    }
  }

  private triggerPointerTarget(target: TheaterInteractionTarget): void {
    const state = this.runtime.getState();
    if (this.dialogueLocked || this.paperBusy || this.panel || this.spotlightPanel) return;
    if (!this.getActiveTargets(state).some((candidate) => candidate.id === target.id)) {
      this.showFeedback(theaterContent.feedback.inactiveTarget, "system", FEEDBACK_INSTANT_MS);
      return;
    }
    if (!findNearestTheaterTarget(this.player.x, this.player.y, [target])) {
      this.showFeedback(
        theaterContent.feedback.moveCloser,
        "system",
        FEEDBACK_GUIDANCE_MS
      );
      return;
    }
    this.triggerTarget(target, state);
  }

  private updatePrompt(target: TheaterInteractionTarget | null, state: GameState): void {
    if (!target || this.dialogueLocked || this.paperBusy || this.panel || this.spotlightPanel) {
      this.promptText.setVisible(false);
      return;
    }
    const dragOnly = (target.kind === "poster" && state.items.greaseTissue && !state.theaterHunt.posterCleaned)
      || (target.kind === "gate" && state.items.temporaryTheaterTicket)
      || (target.kind === "console" && state.theaterHunt.phase === "spotlight_ready" && state.items.spotlightRemote)
      || (target.kind === "scanner" && state.items.temporaryTheaterTicket)
      || (target.kind === "vent" && state.items.fluorescentBrush);
    const label = target.kind === "poster"
      ? dragOnly ? "油渍纸巾 → 入口海报" : "查看海报栏"
      : target.kind === "kiosk"
        ? "查看取票机"
        : target.kind === "gate"
          ? dragOnly ? "临时观演票 → 右侧验票槽" : "与检票员对话"
          : target.kind === "program"
            ? state.theaterHunt.mode === "dark" ? "查看残影" : "取得节目单残页"
            : target.kind === "console"
              ? dragOnly ? "追光灯遥控器 → 灯控台" : "操作灯控台"
              : target.kind === "prop"
                ? "查看道具箱"
                : target.kind === "scanner"
                  ? dragOnly ? "临时观演票 → 票据扫描口" : "检查票据扫描器"
                  : target.kind === "exit"
                    ? "离开剧院"
                    : dragOnly ? "荧光粉刷 → 后台通风口" : "检查后台通风口";
    this.promptText
      .setText(dragOnly ? formatRpgDragHint(label) : formatRpgInteractionHint(label))
      .setVisible(true);
  }

  private syncWorldFromState(state: GameState, immediate = false): void {
    if (state.theaterHunt.mode !== this.currentMode) {
      if (immediate) {
        this.currentMode = state.theaterHunt.mode;
        this.darkOverlay?.setAlpha(this.currentMode === "dark" ? 0.6 : 0);
      } else {
        this.playModeTransition(state.theaterHunt.mode);
      }
    }
    if (state.theaterHunt.phase !== this.currentPhase) {
      this.currentPhase = state.theaterHunt.phase;
    }
    this.syncDarkClues(state);
    this.programVisuals.forEach((visual, programId) => {
      const collected = state.theaterHunt.collectedProgramIds.includes(programId);
      const available = state.theaterHunt.phase === "program_search" && !collected;
      visual.container.setVisible(available);
      if (visual.container.input) visual.container.input.enabled = available;
      visual.glow.setVisible(state.theaterHunt.mode === "dark" && !collected);
    });
    this.paper?.setVisible(["spotlight_ready", "spotlight_hunt", "reversal"].includes(state.theaterHunt.phase));
    this.paper?.setTexture(
      state.theaterHunt.mode === "dark"
        ? THEATER_PAPER_RESIDUAL_KEY
        : state.theaterHunt.paperDusted
          ? THEATER_PAPER_FLUORESCENT_KEY
          : THEATER_PAPER_KEY
    );
    this.spotlightConsoleGuide?.setVisible(state.theaterHunt.phase === "spotlight_ready");
    if (state.theaterHunt.admitted && this.gateBlocker) this.removeGateBlocker();
    this.syncTicketInspectionPoint(state);
    this.syncTicketDropGuides(state);
    this.syncTargetMarkers(state);
  }

  private removeGateBlocker(): void {
    if (!this.gateBlocker) return;
    this.obstacles.remove(this.gateBlocker, true, true);
    this.gateBlocker = null;
  }

  private handleInventoryDrop(payload?: Record<string, unknown>): void {
    const itemId = String(payload?.itemId ?? "") as ItemId;
    const canvasX = Number(payload?.canvasX);
    const canvasY = Number(payload?.canvasY);
    if (!Number.isFinite(canvasX) || !Number.isFinite(canvasY)) {
      this.runtime.emit("rpg_item_use_feedback", { itemId, reason: "missed_target" });
      return;
    }
    const world = this.cameras.main.getWorldPoint(canvasX, canvasY);
    const state = this.runtime.getState();
    const activeTargets = this.getActiveTargets(state);
    const result = resolveRpgItemDrop({
      targets: activeTargets,
      itemId,
      dropX: world.x,
      dropY: world.y,
      playerX: this.player.x,
      playerY: this.player.y,
      mode: state.theaterHunt.mode
    });
    if (!result.target) {
      const ticketDetail = itemId === "temporaryTheaterTicket"
        ? state.theaterHunt.phase === "entry_ticket"
          ? "票已退回：请拖到检票闸机右侧发蓝光的「验票」读票器框内。"
          : state.theaterHunt.phase === "prop_setup"
            ? "票已退回：请拖到道具箱旁发蓝光的票据扫描口框内。"
            : "票已退回：当前阶段没有临时观演票的使用点。"
        : "道具没有放到当前阶段对应的真实物体。";
      this.runtime.emit("rpg_item_use_feedback", {
        itemId,
        reason: "missed_target",
        detail: ticketDetail
      });
      return;
    }
    const targetLabel = result.target.label;
    if (result.kind === "wrong_item") {
      this.runtime.emit("rpg_item_use_feedback", {
        itemId,
        reason: result.target.acceptedItem ? "wrong_item" : "locked",
        targetLabel
      });
      return;
    }
    if (result.kind === "wrong_mode") {
      this.runtime.emit("rpg_item_use_feedback", {
        itemId,
        reason: "locked",
        targetLabel,
        detail: formatRpgModeRequirement(result.expectedMode ?? "light")
      });
      return;
    }
    if (result.kind === "too_far") {
      this.runtime.emit("rpg_item_use_feedback", {
        itemId,
        reason: "too_far",
        targetLabel,
        detail: itemId === "temporaryTheaterTicket"
          ? result.target.kind === "gate"
            ? "票已退回；请靠近读票器。"
            : "票已退回；请靠近扫描器。"
          : undefined
      });
      return;
    }
    if (result.kind !== "accepted") return;
    const target = result.target;
    if (target.kind === "poster") this.runtime.emit("rpg_theater_poster_tissue_requested");
    else if (target.kind === "gate") this.runtime.emit("rpg_theater_admission_requested");
    else if (target.kind === "scanner") this.runtime.emit("rpg_theater_prop_ticket_requested");
    else if (target.kind === "vent") this.runtime.emit("rpg_theater_vent_brush_requested");
    else if (target.kind === "console") this.runtime.emit("rpg_theater_spotlight_start_requested");
  }

  private openCodePanel(): void {
    if (this.panel) return;
    this.runtime.emit("rpg_subtitle_clear");
    this.codeInput = "";
    const panel = this.add.container(480, 270).setScrollFactor(0).setDepth(6200);
    const shade = this.add.rectangle(0, 0, 560, 360, 0x0a0b12, 0.98).setStrokeStyle(4, 0xb18b4b, 0.96);
    const title = this.add.text(0, -145, theaterContent.ticket.codePrompt, {
      color: "#fff2d8", fontFamily: "monospace", fontSize: "17px", align: "center", wordWrap: { width: 470 }
    }).setOrigin(0.5);
    this.codeDisplay = this.add.text(0, -75, "· · · ·", {
      color: "#8fe8ff", backgroundColor: "#07131ddd", fontFamily: "monospace", fontSize: "30px", padding: { x: 24, y: 8 }
    }).setOrigin(0.5);
    panel.add([shade, title, this.codeDisplay]);
    "0123456789".split("").forEach((digit, index) => {
      const x = -180 + (index % 5) * 90;
      const y = 5 + Math.floor(index / 5) * 58;
      this.addPanelButton(panel, x, y, 70, 42, digit, () => {
        if (this.codeInput.length < 4) this.codeInput += digit;
        this.updateCodeDisplay();
      });
    });
    this.addPanelButton(panel, -150, 132, 120, 42, "退格", () => {
      this.codeInput = this.codeInput.slice(0, -1);
      this.updateCodeDisplay();
    });
    this.addPanelButton(panel, 0, 132, 120, 42, "提交", () => {
      if (this.codeInput.length === 4) this.runtime.emit("rpg_theater_ticket_code_submitted", { code: this.codeInput });
    });
    this.addPanelButton(panel, 150, 132, 120, 42, "关闭", () => this.closePanel());
    this.panel = panel;
    this.panelKind = "code";
    this.panelOpeningPointerDownTime = this.input.activePointer.isDown
      ? this.input.activePointer.downTime
      : -1;
  }

  private updateCodeDisplay(): void {
    const slots = Array.from({ length: 4 }, (_, index) => this.codeInput[index] ?? "·");
    this.codeDisplay?.setText(slots.join(" "));
  }

  private openProgramPanel(): void {
    if (this.panel) return;
    this.runtime.emit("rpg_subtitle_clear");
    const state = this.runtime.getState();
    const panel = this.add.container(480, 270).setScrollFactor(0).setDepth(6200);
    const shade = this.add.rectangle(0, 0, 620, 390, 0x0b0b12, 0.98).setStrokeStyle(4, 0xb18b4b, 0.96);
    const title = this.add.text(0, -160, `${theaterContent.program.consolePrompt}\n${theaterContent.program.consoleState}`, {
      color: "#fff2d8", fontFamily: "monospace", fontSize: "17px", align: "center"
    }).setOrigin(0.5);
    panel.add([shade, title]);
    const labels = theaterContent.program.labels;
    const orderText = state.theaterHunt.programOrder.map((id) => labels[id]).join("  →  ") || "_  →  _  →  _";
    panel.add(this.add.text(0, -82, orderText, {
      color: "#8fe8ff", backgroundColor: "#07131ddd", fontFamily: "monospace", fontSize: "22px", padding: { x: 20, y: 9 }
    }).setOrigin(0.5));
    state.theaterHunt.collectedProgramIds.forEach((programId, index) => {
      this.addPanelButton(panel, -190 + index * 190, 4, 150, 48, labels[programId], () => {
        const current = this.runtime.getState().theaterHunt.programOrder;
        if (!current.includes(programId) && current.length < 3) {
          this.runtime.emit("rpg_theater_program_order_set_requested", { order: [...current, programId] });
        }
      });
    });
    this.addPanelButton(panel, -205, 92, 120, 42, "撤回", () => {
      const current = this.runtime.getState().theaterHunt.programOrder;
      this.runtime.emit("rpg_theater_program_order_set_requested", { order: current.slice(0, -1) });
    });
    this.addPanelButton(panel, -68, 92, 120, 42, "清空", () => {
      this.runtime.emit("rpg_theater_program_order_set_requested", { order: [] });
    });
    this.addPanelButton(panel, 68, 92, 120, 42, "提交", () => {
      this.runtime.emit("rpg_theater_program_order_submit_requested");
    });
    this.addPanelButton(panel, 205, 92, 120, 42, "关闭", () => this.closePanel());
    this.panel = panel;
    this.panelKind = "program";
    this.panelOpeningPointerDownTime = this.input.activePointer.isDown
      ? this.input.activePointer.downTime
      : -1;
  }

  private refreshProgramPanel(): void {
    this.closePanel();
    this.openProgramPanel();
  }

  private addPanelButton(
    panel: Phaser.GameObjects.Container,
    x: number,
    y: number,
    width: number,
    height: number,
    label: string,
    action: () => void
  ): void {
    const button = this.add.rectangle(x, y, width, height, 0x26313e, 0.98)
      .setStrokeStyle(2, 0x8aa0ad, 0.94);
    const text = this.add.text(x, y, label, { color: "#fff5df", fontFamily: "monospace", fontSize: "17px" }).setOrigin(0.5);
    panel.add([button, text]);
    this.panelButtons.push({ x, y, width, height, action });
  }

  private closePanel(): void {
    this.panel?.destroy(true);
    this.panel = null;
    this.panelKind = null;
    this.panelButtons = [];
    this.panelOpeningPointerDownTime = -1;
    this.codeDisplay = null;
  }

  private handlePanelPointer(pointer: Phaser.Input.Pointer): void {
    const logical = this.getLogicalPointerPosition(pointer);
    if (this.panel) {
      if (this.panelOpeningPointerDownTime >= 0 && pointer.downTime === this.panelOpeningPointerDownTime) {
        this.panelOpeningPointerDownTime = -1;
        return;
      }
      const localX = logical.x - 480;
      const localY = logical.y - 270;
      const button = [...this.panelButtons].reverse().find((candidate) => (
        Math.abs(localX - candidate.x) <= candidate.width / 2
        && Math.abs(localY - candidate.y) <= candidate.height / 2
      ));
      button?.action();
      return;
    }
    if (!["ready", "tracking"].includes(this.spotlightStage)) return;
    const localX = logical.x - 480;
    const localY = logical.y - 270;
    const insideAimTrack = localX >= -340 && localX <= 340 && localY >= 58 && localY <= 126;
    const insideFireButton = localX >= 205 && localX <= 355 && localY >= 142 && localY <= 202;
    if (insideFireButton && this.spotlightStage === "tracking") {
      this.spotlightPointerFiring = true;
      return;
    }
    if (insideAimTrack) {
      this.spotlightPointerAiming = true;
      this.setSpotlightAim(localX);
    }
  }

  private handleSpotlightPointerMove(pointer: Phaser.Input.Pointer): void {
    if (!this.spotlightPointerAiming || !["ready", "tracking"].includes(this.spotlightStage)) return;
    this.setSpotlightAim(this.getLogicalPointerPosition(pointer).x - 480);
  }

  private handleSpotlightPointerUp(): void {
    this.spotlightPointerAiming = false;
    this.spotlightPointerFiring = false;
  }

  private getLogicalPointerPosition(pointer: Phaser.Input.Pointer): { x: number; y: number } {
    const bounds = this.game.canvas.getBoundingClientRect();
    const event = pointer.event as PointerEvent | MouseEvent | TouchEvent | undefined;
    const touch = "touches" in (event ?? {}) ? (event as TouchEvent).touches[0] : undefined;
    const clientX = touch?.clientX ?? ("clientX" in (event ?? {}) ? (event as PointerEvent | MouseEvent).clientX : pointer.x);
    const clientY = touch?.clientY ?? ("clientY" in (event ?? {}) ? (event as PointerEvent | MouseEvent).clientY : pointer.y);
    return {
      x: (clientX - bounds.left) * 960 / Math.max(1, bounds.width),
      y: (clientY - bounds.top) * 540 / Math.max(1, bounds.height)
    };
  }

  private handlePanelKey(event: KeyboardEvent): void {
    if (this.panelKind === "code") {
      if (/^[0-9]$/.test(event.key) && this.codeInput.length < 4) {
        this.codeInput += event.key;
        this.updateCodeDisplay();
      } else if (event.key === "Backspace") {
        this.codeInput = this.codeInput.slice(0, -1);
        this.updateCodeDisplay();
      } else if (event.key === "Enter" && this.codeInput.length === 4) {
        this.runtime.emit("rpg_theater_ticket_code_submitted", { code: this.codeInput });
      } else if (event.key === "Escape") {
        this.closePanel();
      }
      return;
    }
    if (["ready", "tracking"].includes(this.spotlightStage)) {
      if (event.key === "1") this.setSpotlightAim(-230);
      else if (event.key === "2") this.setSpotlightAim(0);
      else if (event.key === "3") this.setSpotlightAim(230);
    }
  }

  private animatePosterCleaned(): void {
    this.paperBusy = true;
    const wipe = this.add.rectangle(282, 755, 22, 150, 0xf4ead6, 0.48).setDepth(2100).setAngle(-12);
    this.tweens.add({
      targets: wipe,
      x: 430,
      alpha: 0,
      duration: this.reducedMotion ? 120 : 520,
      ease: "Cubic.easeInOut",
      onComplete: () => {
        wipe.destroy();
        this.paperBusy = false;
        this.showFeedback(theaterContent.ticket.posterCleaned, "success", FEEDBACK_CONFIRM_MS);
        this.animateTicketCombine();
      }
    });
  }

  private animateTicketCombine(): void {
    if (!this.ticketCombinePending || this.paperBusy) return;
    this.ticketCombinePending = false;
    this.paperBusy = true;
    const left = this.add.rectangle(430, 270, 80, 52, 0xe7d5a6, 1).setScrollFactor(0).setDepth(6500).setStrokeStyle(3, 0x5f2c32);
    const right = this.add.rectangle(530, 270, 80, 52, 0xdce7ee, 1).setScrollFactor(0).setDepth(6500).setStrokeStyle(3, 0x244d6d);
    this.tweens.add({
      targets: left,
      x: 480,
      duration: this.reducedMotion ? 120 : 480,
      ease: "Cubic.easeInOut"
    });
    this.tweens.add({
      targets: right,
      x: 480,
      duration: this.reducedMotion ? 120 : 480,
      ease: "Cubic.easeInOut",
      onComplete: () => {
        left.destroy();
        right.destroy();
        this.paperBusy = false;
        this.runtime.emit("rpg_theater_ticket_combine_requested");
      }
    });
  }

  private animateAdmission(): void {
    this.ticketReaderLight?.setFillStyle(0x64e58d, 1).setStrokeStyle(1, 0xd5ffe0, 1);
    this.ticketInspector?.disableInteractive();
    this.ticketReader?.disableInteractive();
    this.ticketInspectorSprite?.setTexture(THEATER_INSPECTOR_SCAN_KEY);
    this.time.delayedCall(this.reducedMotion ? 160 : 900, () => {
      this.ticketInspectorSprite?.setTexture(THEATER_INSPECTOR_IDLE_KEY);
    });
    this.removeGateBlocker();
    this.dialogueLocked = true;
    this.queueDialogue(theaterContent.ticket.admissionDialogue, () => {
      const transitionMs = this.reducedMotion ? 80 : 260;
      this.cameras.main.fadeOut(transitionMs, 8, 6, 10);
      this.time.delayedCall(transitionMs, () => {
        this.player.setPosition(THEATER_AUDITORIUM_SPAWN.x, THEATER_AUDITORIUM_SPAWN.y);
        this.cameras.main.centerOn(this.player.x, this.player.y).fadeIn(transitionMs, 8, 6, 10);
        this.dialogueLocked = false;
        this.flushPendingFeedback();
      });
    });
  }

  private animateProgramCollected(programId: TheaterProgramId): void {
    const visual = this.programVisuals.get(programId);
    if (!visual) return;
    this.paperBusy = true;
    this.showFeedback(theaterContent.program.ordinary, "system", FEEDBACK_CONFIRM_MS);
    this.tweens.add({
      targets: visual.container,
      y: visual.container.y - 30,
      scale: 0.35,
      alpha: 0,
      duration: this.reducedMotion ? 120 : 420,
      ease: "Back.easeIn",
      onComplete: () => {
        visual.container.setVisible(false);
        this.paperBusy = false;
      }
    });
  }

  private animatePropBoxOpened(): void {
    this.paperBusy = true;
    this.showFeedback(theaterContent.prop.scannerAccepted, "success", FEEDBACK_CONFIRM_MS);
    const glow = this.add.circle(292, 170, 58, 0x8df0ff, 0.28).setDepth(2100).setStrokeStyle(4, 0xbaf8ff, 0.92);
    this.tweens.add({
      targets: glow,
      scale: 1.45,
      alpha: 0,
      duration: this.reducedMotion ? 120 : 620,
      onComplete: () => {
        glow.destroy();
        this.paperBusy = false;
      }
    });
  }

  private animateVentDust(): void {
    this.paperBusy = true;
    const particles = Array.from({ length: 18 }, (_, index) => this.add.circle(
      936 + Phaser.Math.Between(-24, 24),
      130 + Phaser.Math.Between(-10, 20),
      2 + index % 2,
      0x8eefff,
      0.85
    ).setDepth(2100));
    particles.forEach((particle, index) => {
      this.tweens.add({
        targets: particle,
        x: 835 + Phaser.Math.Between(-150, 150),
        y: 190 + Phaser.Math.Between(-20, 40),
        alpha: 0,
        duration: this.reducedMotion ? 120 : 580 + index * 18,
        onComplete: () => particle.destroy()
      });
    });
    this.time.delayedCall(this.reducedMotion ? 140 : 650, () => {
      this.paperBusy = false;
      this.showFeedback(theaterContent.prop.ventComplete, "success", FEEDBACK_CONFIRM_MS);
    });
  }

  private beginSpotlightRound(): void {
    this.destroySpotlightPanel();
    const state = this.runtime.getState();
    if (state.theaterHunt.phase !== "spotlight_hunt") return;
    this.runtime.emit("rpg_subtitle_clear");
    const round = state.theaterHunt.spotlightRound;
    const config = THEATER_SPOTLIGHT_ROUNDS[round];
    if (!config) return;
    const assist = getTheaterSpotlightAssist(state.theaterHunt.spotlightMistakes);
    const previewMs = config.previewMs + assist.previewBonusMs;
    const panel = this.add.container(480, 270).setScrollFactor(0).setDepth(7000);
    const shade = this.add.rectangle(0, 0, 858, 446, 0x040611, 0.96)
      .setStrokeStyle(5, 0xe3c76e, 0.96);
    const innerFrame = this.add.rectangle(0, 0, 832, 420, 0x08101d, 0.88)
      .setStrokeStyle(2, 0x66d9ed, 0.84);
    const headerBand = this.add.rectangle(0, -181, 792, 50, 0x172338, 0.98)
      .setStrokeStyle(2, 0xd7bd68, 0.72);
    const arena = this.add.rectangle(0, 8, 724, 242, 0x0b1628, 0.94)
      .setStrokeStyle(3, 0x4d7188, 0.94);
    const stageTop = this.add.rectangle(0, -112, 724, 5, 0x73e3ef, 0.52);
    const stageFloor = this.add.rectangle(0, 104, 724, 45, 0x111827, 0.92)
      .setStrokeStyle(2, 0x2e5064, 0.7);
    const leftCurtain = this.add.rectangle(-398, 6, 34, 342, 0x4e1625, 0.9)
      .setStrokeStyle(2, 0xa64551, 0.72);
    const rightCurtain = this.add.rectangle(398, 6, 34, 342, 0x4e1625, 0.9)
      .setStrokeStyle(2, 0xa64551, 0.72);
    const scanLine = this.add.rectangle(0, -102, 716, 3, 0x73efff, 0.18);
    this.spotlightTitle = this.add.text(-330, -181, `第 ${round + 1} / 3 轮 · 观察`, {
      color: "#fff2c6", fontFamily: "monospace", fontSize: "20px", fontStyle: "bold"
    }).setOrigin(0, 0.5);
    this.spotlightStatus = this.add.text(0, -143, theaterContent.spotlight.preview, {
      color: "#91edff", fontFamily: "monospace", fontSize: "15px", align: "center",
      wordWrap: { width: 660 }
    }).setOrigin(0.5);
    this.spotlightControlHint = this.add.text(0, 145, "观察尾迹，记住最后一个灯区。", {
      color: "#bcefff", fontFamily: "monospace", fontSize: "14px", align: "center"
    }).setOrigin(0.5);
    const lockTrack = this.add.rectangle(-192, 178, 270, 10, 0x26313e, 0.96).setOrigin(0, 0.5).setVisible(false);
    const timerTrack = this.add.rectangle(-192, 200, 270, 8, 0x26313e, 0.92).setOrigin(0, 0.5).setVisible(false);
    this.spotlightLockBar = this.add.rectangle(-192, 178, 270, 10, 0x66e4ff, 0.96).setOrigin(0, 0.5).setVisible(false);
    this.spotlightTimeBar = this.add.rectangle(-192, 200, 270, 8, 0xffdf73, 0.96).setOrigin(0, 0.5).setVisible(false);
    this.spotlightLockText = this.add.text(-326, 178, theaterContent.spotlight.lockLabel, {
      color: "#bcefff", fontFamily: "monospace", fontSize: "13px"
    }).setOrigin(0, 0.5).setVisible(false);
    this.spotlightAssistText = this.add.text(0, -112, assist.active ? theaterContent.spotlight.assistHint : "", {
      color: "#ffe699", fontFamily: "monospace", fontSize: "12px"
    }).setOrigin(0.5).setVisible(assist.active);
    this.spotlightFireButton = this.add.rectangle(276, 188, 150, 48, 0x25384a, 0.98)
      .setStrokeStyle(3, 0xb9d7e8, 0.9)
      .setVisible(false);
    this.spotlightFireLabel = this.add.text(276, 188, theaterContent.spotlight.fireLabel, {
      color: "#f4fbff", fontFamily: "monospace", fontSize: "16px"
    }).setOrigin(0.5).setVisible(false);
    panel.add([
      shade,
      innerFrame,
      leftCurtain,
      rightCurtain,
      headerBand,
      arena,
      stageTop,
      stageFloor,
      scanLine,
      this.spotlightTitle,
      this.spotlightStatus,
      this.spotlightControlHint,
      lockTrack,
      timerTrack,
      this.spotlightLockBar,
      this.spotlightTimeBar,
      this.spotlightLockText,
      this.spotlightAssistText,
      this.spotlightFireButton,
      this.spotlightFireLabel
    ]);
    const roundPipX = 245;
    for (let index = 0; index < 3; index += 1) {
      const completed = index < round;
      const active = index === round;
      const pip = this.add.rectangle(roundPipX + index * 34, -181, 24, 12, completed ? 0xf0d56d : active ? 0x78e6f5 : 0x2b3a49, 1)
        .setStrokeStyle(2, active ? 0xe9fbff : 0x7c7250, active ? 0.96 : 0.58);
      panel.add(pip);
      if (active && !this.reducedMotion) {
        this.spotlightVisualTweens.push(this.tweens.add({
          targets: pip,
          alpha: { from: 0.52, to: 1 },
          scaleX: { from: 0.86, to: 1.08 },
          duration: 360,
          yoyo: true,
          repeat: -1,
          ease: "Sine.easeInOut"
        }));
      }
    }
    panel.add(this.add.rectangle(0, 90, 650, 4, 0x708394, 0.62));
    [-230, 0, 230].forEach((x) => {
      panel.add(this.add.rectangle(x, 5, 2, 210, 0x41617a, 0.2));
    });
    const lanePositions: Record<TheaterSpotlightLane, number> = { left: -230, center: 0, right: 230 };
    (Object.entries(lanePositions) as [TheaterSpotlightLane, number][]).forEach(([lane, x]) => {
      const laneLabel = lane === "left" ? "左" : lane === "center" ? "中" : "右";
      const circle = this.add.circle(x, 90, 52, 0x65dded, 0.025).setStrokeStyle(3, 0x80dbe5, 0.34);
      const innerCircle = this.add.circle(x, 90, 38, 0xe7c769, 0.025).setStrokeStyle(2, 0xd9c76d, 0.32);
      const labelPlate = this.add.rectangle(x, 116, 54, 22, 0x101c2a, 0.94).setStrokeStyle(1, 0x66889a, 0.72);
      const label = this.add.text(x, 116, laneLabel, {
        color: "#d9eef2", fontFamily: "monospace", fontSize: "13px", fontStyle: "bold"
      }).setOrigin(0.5);
      panel.add([circle, innerCircle, labelPlate, label]);
      if (!this.reducedMotion) {
        this.spotlightVisualTweens.push(this.tweens.add({
          targets: circle,
          alpha: { from: 0.35, to: 0.95 },
          scale: { from: 0.94, to: 1.06 },
          duration: 660 + Math.abs(x),
          delay: x + 230,
          yoyo: true,
          repeat: -1,
          ease: "Sine.easeInOut"
        }));
      }
    });

    if (!this.reducedMotion) {
      this.spotlightVisualTweens.push(this.tweens.add({
        targets: scanLine,
        y: { from: -102, to: 105 },
        alpha: { from: 0.04, to: 0.32 },
        duration: 1500,
        repeat: -1,
        ease: "Linear"
      }));
    }

    this.spotlightPathPreview = this.add.graphics();
    this.spotlightPathPreview.lineStyle(6, 0x62dfff, 0.82);
    this.drawSpotlightPath(this.spotlightPathPreview, config.pathPoints, false);
    if (config.decoyPathPoints) {
      this.drawSpotlightPath(this.spotlightPathPreview, config.decoyPathPoints, true);
    }
    panel.add(this.spotlightPathPreview);
    const path = this.createSpotlightSpline(config.pathPoints);
    const trailDots = Array.from({ length: 13 }, (_, index) => {
      const point = path.getPoint(index / 12);
      const dot = this.add.circle(point.x, point.y, index % 3 === 0 ? 4 : 2, 0x8df2ff, 0.72);
      panel.add(dot);
      if (!this.reducedMotion) {
        this.spotlightVisualTweens.push(this.tweens.add({
          targets: dot,
          alpha: { from: 0.18, to: 0.95 },
          scale: { from: 0.65, to: 1.28 },
          duration: 420,
          delay: index * 58,
          yoyo: true,
          repeat: -1,
          ease: "Sine.easeInOut"
        }));
      }
      return dot;
    });
    const start = path.getPoint(0);
    this.spotlightPaper = this.add.image(start.x, start.y, THEATER_PAPER_RESIDUAL_KEY)
      .setAlpha(0.94);
    panel.add(this.spotlightPaper);
    if (!this.reducedMotion) {
      this.spotlightVisualTweens.push(this.tweens.add({
        targets: this.spotlightPaper,
        scale: { from: 0.96, to: 1.08 },
        alpha: { from: 0.72, to: 1 },
        duration: 180,
        yoyo: true,
        repeat: -1,
        ease: "Stepped"
      }));
    }
    if (config.decoyPathPoints) {
      const decoyPath = this.createSpotlightSpline(config.decoyPathPoints);
      const decoyStart = decoyPath.getPoint(0);
      this.spotlightDecoyPaper = this.add.image(decoyStart.x, decoyStart.y, THEATER_PAPER_ESCAPE_KEY)
        .setAlpha(0.42);
      panel.add(this.spotlightDecoyPaper);
    }
    this.spotlightBeam = this.add.graphics();
    this.spotlightBeamArt = this.add.image(0, -22, THEATER_SPOTLIGHT_BEAM_ART_KEY)
      .setScale(0.78)
      .setAlpha(0.2)
      .setVisible(false);
    this.spotlightAimRing = this.add.circle(0, 90, config.beamRadius, 0xffdf73, 0.06)
      .setStrokeStyle(4, 0xffe999, 0.58)
      .setVisible(false);
    this.spotlightAimMarker = this.add.circle(0, 90, 5, 0xfff2aa, 0.94).setVisible(false);
    panel.add([this.spotlightBeam, this.spotlightBeamArt]);
    panel.add([this.spotlightAimRing, this.spotlightAimMarker]);
    trailDots.forEach((dot) => panel.bringToTop(dot));
    panel.bringToTop(this.spotlightPaper);
    this.spotlightPanel = panel;
    this.spotlightStage = "preview";
    this.spotlightAimX = 0;
    this.spotlightActionElapsedMs = 0;
    this.spotlightCurrentLockMs = 0;
    this.spotlightMaxContinuousLockMs = 0;
    this.spotlightFirstBeamAtMs = null;
    this.spotlightEarlyExposureMs = 0;
    this.spotlightBeamActivated = false;
    this.spotlightBeamActive = false;
    this.spotlightPointerAiming = false;
    this.spotlightPointerFiring = false;
    this.spotlightLastFailureReason = null;
    this.spotlightChoiceOpen = false;
    if (!this.reducedMotion) {
      const previewState = { progress: 0 };
      this.spotlightPreviewTween = this.tweens.add({
        targets: previewState,
        progress: 1,
        duration: previewMs,
        ease: "Linear",
        onUpdate: () => {
          const point = path.getPoint(previewState.progress);
          this.spotlightPaper?.setPosition(point.x, point.y).setAngle(previewState.progress * 220);
          if (config.decoyPathPoints && this.spotlightDecoyPaper) {
            const decoyPoint = this.createSpotlightSpline(config.decoyPathPoints).getPoint(previewState.progress);
            this.spotlightDecoyPaper.setPosition(decoyPoint.x, decoyPoint.y).setAngle(-previewState.progress * 170);
          }
        }
      });
    } else {
      const end = path.getPoint(1);
      this.spotlightPaper.setPosition(end.x, end.y);
    }
    this.scheduleSpotlight(previewMs, () => this.prepareSpotlightAction(round));
  }

  private prepareSpotlightAction(round: number): void {
    if (!this.spotlightPanel || this.runtime.getState().theaterHunt.spotlightRound !== round) return;
    this.runtime.emit("rpg_theater_mode_requested", { mode: "light" });
    this.spotlightStage = "ready";
    this.spotlightTitle?.setText(`第 ${round + 1} / 3 轮 · 预置`);
    this.spotlightStatus?.setText("预置追光灯").setColor("#ffe49a");
    this.spotlightControlHint?.setText("拖动下方滑轨，或按 ← / → 移动。").setColor("#fff3bd");
    this.spotlightPaper?.setTexture(THEATER_PAPER_FLUORESCENT_KEY).setVisible(false).clearTint();
    this.spotlightDecoyPaper?.setVisible(false);
    this.spotlightPathPreview?.setVisible(false);
    this.spotlightAimRing?.setVisible(true);
    this.spotlightAimMarker?.setVisible(true);
    this.spotlightLockText?.setVisible(true);
    this.spotlightLockBar?.setVisible(true).setScale(0, 1);
    this.spotlightTimeBar?.setVisible(true).setScale(1, 1);
    this.spotlightFireButton?.setVisible(true).setFillStyle(0x25384a, 0.98);
    this.spotlightFireLabel?.setVisible(true);
    this.setSpotlightAim(this.spotlightAimX);
    this.scheduleSpotlight(900, () => this.startSpotlightTracking(round));
  }

  private startSpotlightTracking(round: number): void {
    const state = this.runtime.getState();
    if (!this.spotlightPanel || state.theaterHunt.spotlightRound !== round || state.theaterHunt.phase !== "spotlight_hunt") return;
    this.spotlightStage = "tracking";
    this.spotlightTitle?.setText(`第 ${round + 1} / 3 轮 · 锁定`);
    this.spotlightChoiceOpen = true;
    this.spotlightActionElapsedMs = 0;
    this.spotlightCurrentLockMs = 0;
    this.spotlightMaxContinuousLockMs = 0;
    this.spotlightFirstBeamAtMs = null;
    this.spotlightEarlyExposureMs = 0;
    this.spotlightBeamActivated = false;
    this.spotlightStatus?.setText(theaterContent.spotlight.choose).setColor("#ffe49a");
    this.spotlightControlHint?.setText(theaterContent.spotlight.controlHint).setColor("#fff3bd");
    this.spotlightPaper?.setTexture(THEATER_PAPER_FLUORESCENT_KEY).setVisible(true).clearTint();
    this.spotlightDecoyPaper?.setVisible(Boolean(THEATER_SPOTLIGHT_ROUNDS[round]?.decoyPathPoints));
  }

  private updateSpotlightRound(delta: number): void {
    if (!this.spotlightPanel || !["ready", "tracking"].includes(this.spotlightStage)) return;
    const state = this.runtime.getState();
    const round = state.theaterHunt.spotlightRound;
    const config = THEATER_SPOTLIGHT_ROUNDS[round];
    if (!config) return;
    const assist = getTheaterSpotlightAssist(state.theaterHunt.spotlightMistakes);
    const direction = Number(this.cursors.right.isDown || this.keys.D.isDown)
      - Number(this.cursors.left.isDown || this.keys.A.isDown);
    if (direction !== 0) this.setSpotlightAim(this.spotlightAimX + direction * delta * 0.38);
    if (this.spotlightPointerFiring && !this.input.activePointer.isDown) this.spotlightPointerFiring = false;
    this.spotlightBeamActive = this.spotlightStage === "tracking"
      && (this.spotlightPointerFiring || this.cursors.space.isDown);
    this.drawSpotlightBeam(config.beamRadius * assist.radiusScale);
    if (this.spotlightStage !== "tracking") return;

    this.spotlightActionElapsedMs = Math.min(config.actionMs, this.spotlightActionElapsedMs + delta);
    const progress = Phaser.Math.Clamp(this.spotlightActionElapsedMs / config.actionMs, 0, 1);
    const motionProgress = Phaser.Math.Clamp(progress / 0.72, 0, 1);
    const path = this.createSpotlightSpline(config.pathPoints);
    const target = path.getPoint(motionProgress);
    this.spotlightPaper?.setPosition(target.x, target.y).setAngle(motionProgress * 220);

    let decoy: Phaser.Math.Vector2 | null = null;
    if (config.decoyPathPoints && this.spotlightDecoyPaper) {
      decoy = this.createSpotlightSpline(config.decoyPathPoints).getPoint(Phaser.Math.Clamp(progress / 0.78, 0, 1));
      this.spotlightDecoyPaper.setPosition(decoy.x, decoy.y).setAngle(-motionProgress * 170);
    }

    if (this.spotlightBeamActive) {
      this.spotlightBeamActivated = true;
      if (this.spotlightFirstBeamAtMs === null) this.spotlightFirstBeamAtMs = this.spotlightActionElapsedMs;
    }
    const beamRadius = config.beamRadius * assist.radiusScale;
    const targetOverlap = this.spotlightBeamActive
      && Math.hypot(target.x - this.spotlightAimX, target.y - 90) <= beamRadius + 12;
    const decoyOverlap = Boolean(
      this.spotlightBeamActive
      && decoy
      && Math.hypot(decoy.x - this.spotlightAimX, decoy.y - 90) <= beamRadius + 10
    );
    if (this.spotlightBeamActive && !targetOverlap && !decoyOverlap && progress < 0.68) {
      this.spotlightEarlyExposureMs += delta;
    } else {
      this.spotlightEarlyExposureMs = Math.max(0, this.spotlightEarlyExposureMs - delta * 1.5);
    }
    if (this.spotlightEarlyExposureMs >= 450) {
      this.spotlightChoiceOpen = false;
      this.spotlightStage = "miss";
      this.runtime.emit("rpg_theater_spotlight_attempt", {
        round,
        lane: this.getSpotlightAimLane(),
        maxContinuousLockMs: this.spotlightMaxContinuousLockMs,
        beamActivated: this.spotlightBeamActivated,
        firstBeamAtMs: this.spotlightFirstBeamAtMs,
        submittedAtMs: this.spotlightActionElapsedMs,
        actionMs: config.actionMs
      });
      return;
    }
    if (decoyOverlap && !targetOverlap) {
      this.spotlightCurrentLockMs = 0;
      if (!this.spotlightDecoyOverlap) {
        this.spotlightStatus?.setText("断裂尾迹是假残影。").setColor("#ffb3b3");
      }
    } else if (targetOverlap) {
      this.spotlightCurrentLockMs += delta;
      this.spotlightStatus?.setText("锁定中，保持照射。").setColor("#9af3ff");
    } else if (this.spotlightCurrentLockMs > 0) {
      this.spotlightCurrentLockMs = Math.max(0, this.spotlightCurrentLockMs - delta * 2.4);
      this.spotlightStatus?.setText("光圈脱离纸条，重新锁定。").setColor("#ffd49a");
    }
    this.spotlightDecoyOverlap = decoyOverlap;
    this.spotlightMaxContinuousLockMs = Math.max(this.spotlightMaxContinuousLockMs, this.spotlightCurrentLockMs);
    const requiredLockMs = config.requiredLockMs * assist.lockScale;
    this.spotlightLockBar?.setScale(Phaser.Math.Clamp(this.spotlightCurrentLockMs / requiredLockMs, 0, 1), 1);
    this.spotlightTimeBar?.setScale(1 - progress, 1);

    if (this.spotlightCurrentLockMs >= requiredLockMs) {
      this.spotlightChoiceOpen = false;
      this.spotlightStage = "hit";
      this.runtime.emit("rpg_theater_spotlight_attempt", {
        round,
        lane: this.getSpotlightAimLane(),
        maxContinuousLockMs: this.spotlightMaxContinuousLockMs,
        beamActivated: this.spotlightBeamActivated,
        firstBeamAtMs: this.spotlightFirstBeamAtMs,
        submittedAtMs: this.spotlightActionElapsedMs,
        actionMs: config.actionMs
      });
      return;
    }
    if (this.spotlightActionElapsedMs >= config.actionMs) {
      this.spotlightChoiceOpen = false;
      this.spotlightStage = "miss";
      this.runtime.emit("rpg_theater_spotlight_attempt", {
        round,
        lane: this.getSpotlightAimLane(),
        maxContinuousLockMs: this.spotlightMaxContinuousLockMs,
        beamActivated: this.spotlightBeamActivated,
        firstBeamAtMs: this.spotlightFirstBeamAtMs,
        submittedAtMs: this.spotlightActionElapsedMs,
        actionMs: config.actionMs
      });
    }
  }

  private setSpotlightAim(x: number): void {
    this.spotlightAimX = Phaser.Math.Clamp(x, -320, 320);
    this.spotlightAimRing?.setX(this.spotlightAimX);
    this.spotlightAimMarker?.setX(this.spotlightAimX);
  }

  private getSpotlightAimLane(): TheaterSpotlightLane {
    if (this.spotlightAimX <= -112) return "left";
    if (this.spotlightAimX >= 112) return "right";
    return "center";
  }

  private drawSpotlightBeam(radius: number): void {
    this.spotlightAimRing?.setRadius(radius);
    this.spotlightBeam?.clear();
    if (!this.spotlightBeam) return;
    const activeAlpha = this.spotlightBeamActive ? 0.3 : 0.06;
    this.spotlightBeamArt
      ?.setPosition(this.spotlightAimX, -22)
      .setVisible(["ready", "tracking"].includes(this.spotlightStage))
      .setAlpha(this.spotlightBeamActive ? 0.84 : 0.18);
    this.spotlightBeam
      .fillStyle(0xffe89a, activeAlpha)
      .fillTriangle(this.spotlightAimX - 15, -105, this.spotlightAimX + 15, -105, this.spotlightAimX + radius, 90)
      .fillTriangle(this.spotlightAimX - 15, -105, this.spotlightAimX - radius, 90, this.spotlightAimX + radius, 90);
    this.spotlightAimRing
      ?.setFillStyle(0xffdf73, this.spotlightBeamActive ? 0.28 : 0.06)
      .setStrokeStyle(this.spotlightBeamActive ? 5 : 3, 0xffeb9c, this.spotlightBeamActive ? 0.98 : 0.58);
    this.spotlightFireButton
      ?.setFillStyle(this.spotlightBeamActive ? 0x7c5f22 : 0x25384a, 0.98)
      .setStrokeStyle(3, this.spotlightBeamActive ? 0xffe99b : 0xb9d7e8, 0.94);
  }

  private resetSpotlightBeamVisual(): void {
    this.spotlightBeam?.clear();
    this.spotlightBeamArt?.setVisible(false);
    this.spotlightAimRing
      ?.setFillStyle(0xffdf73, 0.06)
      .setStrokeStyle(3, 0xffeb9c, 0.58);
    this.spotlightFireButton
      ?.setFillStyle(0x25384a, 0.98)
      .setStrokeStyle(3, 0xb9d7e8, 0.94);
  }

  private createSpotlightSpline(points: readonly { x: number; y: number }[]): Phaser.Curves.Spline {
    return new Phaser.Curves.Spline(points.map((point) => new Phaser.Math.Vector2(point.x, point.y)));
  }

  private drawSpotlightPath(
    graphics: Phaser.GameObjects.Graphics,
    points: readonly { x: number; y: number }[],
    broken: boolean
  ): void {
    const spline = this.createSpotlightSpline(points);
    const samples = Array.from({ length: 31 }, (_, index) => spline.getPoint(index / 30));
    graphics.lineStyle(broken ? 3 : 6, broken ? 0x7994a2 : 0x62dfff, broken ? 0.48 : 0.82);
    samples.slice(0, -1).forEach((point, index) => {
      if (broken && index % 5 >= 2) return;
      const next = samples[index + 1];
      graphics.lineBetween(point.x, point.y, next.x, next.y);
    });
  }

  private scheduleSpotlight(delayMs: number, callback: () => void): void {
    const timer = this.time.delayedCall(delayMs, () => {
      this.spotlightDelayTimers = this.spotlightDelayTimers.filter((candidate) => candidate !== timer);
      callback();
    });
    this.spotlightDelayTimers.push(timer);
  }

  private animateSpotlightHit(finalHit: boolean): void {
    this.spotlightChoiceOpen = false;
    this.spotlightStage = "hit";
    this.spotlightBeamActive = false;
    this.spotlightPointerFiring = false;
    this.resetSpotlightBeamVisual();
    const hitCount = this.runtime.getState().theaterHunt.spotlightRound;
    this.spotlightTitle?.setText(`第 ${hitCount} / 3 轮 · 命中`);
    this.spotlightStatus?.setText(`${theaterContent.spotlight.hit}  已命中 ${hitCount} / 3`).setColor("#fff4b2");
    this.spotlightControlHint?.setText("连续锁定完成。").setColor("#fff4b2");
    this.spotlightLockBar?.setScale(1, 1).setFillStyle(0xffe487, 1);
    if (this.spotlightPanel) {
      const originX = this.spotlightPaper?.x ?? this.spotlightAimX;
      const originY = this.spotlightPaper?.y ?? 90;
      this.spotlightPaper?.setTexture(THEATER_PAPER_LOCKED_KEY).clearTint();
      const hitRingArt = this.add.image(originX, originY, THEATER_SPOTLIGHT_HIT_RING_KEY).setScale(0.42);
      const sparkArt = this.add.image(originX, originY, THEATER_SPOTLIGHT_SPARKS_KEY).setScale(0.4);
      this.spotlightPanel.add([hitRingArt, sparkArt]);
      this.spotlightVisualTweens.push(this.tweens.add({
        targets: hitRingArt,
        scale: 0.92,
        alpha: 0,
        duration: this.reducedMotion ? 100 : 460,
        ease: "Cubic.easeOut",
        onComplete: () => hitRingArt.destroy()
      }));
      this.spotlightVisualTweens.push(this.tweens.add({
        targets: sparkArt,
        scale: 0.68,
        alpha: 0,
        duration: this.reducedMotion ? 100 : 540,
        ease: "Cubic.easeOut",
        onComplete: () => sparkArt.destroy()
      }));
      for (let index = 0; index < 3; index += 1) {
        const ring = this.add.circle(originX, originY, 18 + index * 8, 0xffe68a, 0)
          .setStrokeStyle(4 - index, index === 0 ? 0xffffff : 0xffdf73, 0.92);
        this.spotlightPanel.add(ring);
        this.spotlightVisualTweens.push(this.tweens.add({
          targets: ring,
          scale: 2.5 + index * 0.35,
          alpha: 0,
          duration: this.reducedMotion ? 100 : 420 + index * 90,
          ease: "Cubic.easeOut",
          onComplete: () => ring.destroy()
        }));
      }
      for (let index = 0; index < 12; index += 1) {
        const angle = Math.PI * 2 * index / 12;
        const spark = this.add.rectangle(originX, originY, 7, 3, index % 2 === 0 ? 0xffe68a : 0x8ff2ff, 0.96)
          .setAngle(Phaser.Math.RadToDeg(angle));
        this.spotlightPanel.add(spark);
        this.spotlightVisualTweens.push(this.tweens.add({
          targets: spark,
          x: originX + Math.cos(angle) * 72,
          y: originY + Math.sin(angle) * 48,
          alpha: 0,
          duration: this.reducedMotion ? 100 : 360,
          ease: "Cubic.easeOut",
          onComplete: () => spark.destroy()
        }));
      }
    }
    if (!this.reducedMotion) this.cameras.main.shake(80, 0.002);
    if (finalHit) {
      this.scheduleSpotlight(80, () => this.animateReversal());
    } else {
      this.scheduleSpotlight(350, () => this.beginSpotlightRound());
    }
  }

  private animateSpotlightMiss(payload?: Record<string, unknown>): void {
    this.spotlightChoiceOpen = false;
    this.spotlightStage = "miss";
    this.spotlightBeamActive = false;
    this.spotlightPointerFiring = false;
    this.resetSpotlightBeamVisual();
    this.spotlightTitle?.setText(`第 ${this.runtime.getState().theaterHunt.spotlightRound + 1} / 3 轮 · 重试`);
    const reason = String(payload?.failureReason ?? "late") as TheaterSpotlightFailureReason;
    this.spotlightLastFailureReason = reason;
    const failureHints = theaterContent.spotlight.failureHints as Partial<Record<TheaterSpotlightFailureReason, string>>;
    const failureHint = failureHints[reason] ?? theaterContent.spotlight.wrongHint;
    this.spotlightStatus?.setText(`${theaterContent.spotlight.miss}\n${failureHint}`).setColor("#ff9f9f");
    this.spotlightControlHint?.setText("保持已完成轮次，重新观察本轮。").setColor("#bcefff");
    if (this.spotlightPanel) {
      const faultArt = this.add.image(0, 60, THEATER_SPOTLIGHT_FAULT_KEY).setScale(0.72);
      this.spotlightPanel.add(faultArt);
      this.spotlightVisualTweens.push(this.tweens.add({
        targets: faultArt,
        x: 48,
        alpha: 0,
        duration: this.reducedMotion ? 90 : 620,
        ease: "Cubic.easeOut",
        onComplete: () => faultArt.destroy()
      }));
      for (let index = 0; index < 5; index += 1) {
        const strip = this.add.rectangle(-300 + index * 150, -80 + index * 37, 96, 8, index % 2 === 0 ? 0xe65867 : 0x65dbe8, 0.72);
        this.spotlightPanel.add(strip);
        this.spotlightVisualTweens.push(this.tweens.add({
          targets: strip,
          x: strip.x + (index % 2 === 0 ? 86 : -86),
          alpha: 0,
          duration: this.reducedMotion ? 90 : 260 + index * 35,
          ease: "Cubic.easeOut",
          onComplete: () => strip.destroy()
        }));
      }
    }
    if (this.spotlightPaper && !this.reducedMotion) {
      this.tweens.add({
        targets: this.spotlightPaper,
        x: this.spotlightPaper.x + 54,
        y: this.spotlightPaper.y - 24,
        angle: this.spotlightPaper.angle + 220,
        duration: 360,
        yoyo: true,
        ease: "Sine.easeInOut"
      });
    }
    this.scheduleSpotlight(1100, () => this.beginSpotlightRound());
  }

  private animateReversal(): void {
    if (!this.spotlightPanel) {
      const panel = this.add.container(480, 270).setScrollFactor(0).setDepth(7000);
      panel.add(this.add.rectangle(0, 0, 840, 430, 0x09060a, 0.97).setStrokeStyle(4, 0xc05260, 0.9));
      this.spotlightStatus = this.add.text(0, -150, theaterContent.spotlight.reversal, {
        color: "#ffadb5", fontFamily: "monospace", fontSize: "19px"
      }).setOrigin(0.5);
      this.spotlightPaper = this.add.image(0, 20, THEATER_PAPER_LOCKED_KEY).setScale(1.65);
      panel.add([this.spotlightStatus, this.spotlightPaper]);
      this.spotlightPanel = panel;
    }
    this.paperBusy = true;
    this.spotlightStatus?.setText(theaterContent.spotlight.reversal).setColor("#ffadb5");
    const paper = this.spotlightPaper;
    const cracks = this.add.graphics().setScrollFactor(0).setDepth(7100);
    cracks.lineStyle(2, 0x8c7d77, 0.92);
    cracks
      .lineBetween(480, 272, 472, 289)
      .lineBetween(472, 289, 486, 300)
      .lineBetween(486, 300, 477, 316)
      .lineBetween(480, 287, 498, 280)
      .lineBetween(482, 301, 500, 311);
    if (paper) {
      paper.setTexture(THEATER_PAPER_LOCKED_KEY).setVisible(true).clearTint().setScale(1.65).setAlpha(1).setPosition(0, 20);
      this.scheduleSpotlight(220, () => paper.setTexture(THEATER_PAPER_CRACKED_KEY));
      this.scheduleSpotlight(370, () => {
        cracks.destroy();
        paper.setVisible(false);
        const fragmentsArt = this.add.image(480, 290, THEATER_PAPER_FRAGMENTS_KEY)
          .setScrollFactor(0)
          .setDepth(7100)
          .setScale(1.4);
        this.tweens.add({
          targets: fragmentsArt,
          scale: 2,
          alpha: 0,
          duration: this.reducedMotion ? 120 : 420,
          onComplete: () => fragmentsArt.destroy()
        });
        for (let index = 0; index < 8; index += 1) {
          const shard = this.add.rectangle(480, 290, 12 + index % 3 * 4, 8, 0xe7dbc8, 1)
            .setScrollFactor(0)
            .setDepth(7100)
            .setAngle(index * 27);
          this.tweens.add({
            targets: shard,
            x: 480 + Phaser.Math.Between(-120, 120),
            y: 330 + Phaser.Math.Between(20, 100),
            angle: "+=180",
            alpha: 0,
            duration: this.reducedMotion ? 120 : 400,
            onComplete: () => shard.destroy()
          });
        }
      });
    }
    this.scheduleSpotlight(770, () => {
      const shadow = this.add.image(390, 310, THEATER_PAPER_ESCAPE_KEY)
        .setScrollFactor(0)
        .setDepth(7050)
        .setAlpha(0.74);
      this.tweens.add({
        targets: shadow,
        x: 860,
        y: 225,
        angle: 240,
        alpha: 0,
        duration: this.reducedMotion ? 160 : 560,
        onComplete: () => shadow.destroy()
      });
    });
    this.scheduleSpotlight(1320, () => {
      this.paperBusy = false;
      this.destroySpotlightPanel();
      this.runtime.emit("rpg_theater_reversal_complete_requested");
    });
  }

  private destroySpotlightPanel(): void {
    this.spotlightPreviewTween?.stop();
    this.spotlightPreviewTween = null;
    this.spotlightVisualTweens.forEach((tween) => tween.stop());
    this.spotlightVisualTweens = [];
    this.spotlightDelayTimers.forEach((timer) => timer.remove(false));
    this.spotlightDelayTimers = [];
    this.spotlightPanel?.destroy(true);
    this.spotlightPanel = null;
    this.spotlightTitle = null;
    this.spotlightStatus = null;
    this.spotlightPaper = null;
    this.spotlightDecoyPaper = null;
    this.spotlightPathPreview = null;
    this.spotlightBeam = null;
    this.spotlightBeamArt = null;
    this.spotlightAimRing = null;
    this.spotlightAimMarker = null;
    this.spotlightFireButton = null;
    this.spotlightFireLabel = null;
    this.spotlightControlHint = null;
    this.spotlightTimeBar = null;
    this.spotlightLockBar = null;
    this.spotlightLockText = null;
    this.spotlightAssistText = null;
    this.spotlightStage = "idle";
    this.spotlightPointerAiming = false;
    this.spotlightPointerFiring = false;
    this.spotlightBeamActive = false;
    this.spotlightDecoyOverlap = false;
    this.spotlightLastFailureReason = null;
    this.spotlightChoiceOpen = false;
  }

  private queueDialogue(lines: readonly string[], onComplete?: () => void): void {
    this.dialogueLocked = true;
    lines.forEach((text, index) => {
      this.time.delayedCall(index * DIALOGUE_STEP_MS, () => {
        this.emitSubtitle(text, this.dialogueToneFor(text), DIALOGUE_STEP_MS - 120, this.dialogueSpeakerFor(text));
      });
    });
    this.time.delayedCall(lines.length * DIALOGUE_STEP_MS, () => {
      this.dialogueLocked = false;
      onComplete?.();
      this.flushPendingFeedback();
    });
  }

  private dialogueToneFor(text: string): GameSubtitleTone {
    if (text.startsWith("玩家：")) return "player";
    if (text.startsWith("系统：") || text.startsWith("手机系统：")) return "system";
    if (text.startsWith("任务：")) return "task";
    return "narrator";
  }

  private dialogueSpeakerFor(text: string): string | undefined {
    return THEATER_DIALOGUE_SPEAKERS.find((name) => text.startsWith(`${name}：`));
  }

  private showFeedback(text: string, tone: GameSubtitleTone, durationMs = FEEDBACK_GUIDANCE_MS): void {
    // Feedback arriving while a queued dialogue plays is held back so it cannot
    // overwrite the current line; it is flushed once the dialogue finishes.
    if (this.dialogueLocked) {
      this.pendingFeedback.push({ text, tone, durationMs, speaker: this.dialogueSpeakerFor(text) });
      return;
    }
    this.emitSubtitle(text, tone, durationMs, this.dialogueSpeakerFor(text));
  }

  private emitSubtitle(text: string, tone: GameSubtitleTone, durationMs: number, speaker?: string): void {
    this.lastFeedbackUntilMs = this.time.now + durationMs;
    const visibleText = speaker && text.startsWith(`${speaker}：`)
      ? text.slice(speaker.length + 1).trimStart()
      : text;
    this.runtime.emit("rpg_subtitle", { text: visibleText, tone, durationMs, ...(speaker ? { speaker } : {}) });
  }

  private flushPendingFeedback(): void {
    if (this.dialogueLocked || this.pendingFeedback.length === 0) return;
    const pending = this.pendingFeedback.splice(0);
    let offsetMs = 0;
    pending.forEach((entry) => {
      this.time.delayedCall(offsetMs, () => this.emitSubtitle(entry.text, entry.tone, entry.durationMs, entry.speaker));
      offsetMs += entry.durationMs;
    });
  }

  private publishDebugState(target: TheaterInteractionTarget | null, state: GameState): void {
    const spotlightConfig = THEATER_SPOTLIGHT_ROUNDS[state.theaterHunt.spotlightRound];
    const spotlightAssist = getTheaterSpotlightAssist(state.theaterHunt.spotlightMistakes);
    const activeTicketGuide = Array.from(this.ticketDropGuides.values())
      .find((guide) => guide.targetOutline.visible);
    setRpgRuntimeDebugState({
      coordinateSystem: "Phaser world coordinates, origin at top-left, x right, y down",
      world: THEATER_INTERIOR_WORLD,
      player: {
        x: Math.round(this.player.x),
        y: Math.round(this.player.y),
        facing: this.playerAnimator.facing,
        cardinalFacing: this.playerAnimator.cardinalFacing,
        texture: this.playerAnimator.textureKey,
        turning: this.playerAnimator.isTurning,
        walkFps: RPG_PLAYER_WALK_FPS,
        collisionWidth: Number((this.player.body?.width ?? 0).toFixed(2)),
        collisionHeight: Number((this.player.body?.height ?? 0).toFixed(2))
      },
      camera: {
        scrollX: Math.round(this.cameras.main.scrollX),
        scrollY: Math.round(this.cameras.main.scrollY),
        zoom: Number(this.cameras.main.zoom.toFixed(2)),
        mode: "follow"
      },
      scene: "theater_interior",
      checkpoint: state.rpgCheckpoint,
      activeTargets: this.getActiveTargets(state).map((candidate) => ({
        id: candidate.id,
        label: candidate.label,
        x: candidate.x,
        y: candidate.y,
        width: candidate.dropWidth ?? candidate.proximity * 2,
        height: candidate.dropHeight ?? candidate.proximity * 2,
        dropWidth: candidate.dropWidth,
        dropHeight: candidate.dropHeight,
        stand: candidate.stand,
        proximity: candidate.proximity,
        acceptedItem: candidate.acceptedItem,
        requiredMode: candidate.requiredMode
      })),
      collisionRects: [
        ...THEATER_STATIC_COLLISION_RECTS,
        ...THEATER_TICKET_FIXTURE_COLLISION_RECTS
      ],
      theater: {
        runtimeContractVersion: this.runtime.contractVersion,
        phase: state.theaterHunt.phase,
        mode: state.theaterHunt.mode,
        activeTarget: target?.id ?? null,
        panel: this.panelKind,
        spotlightChoiceOpen: this.spotlightChoiceOpen,
        ticketDropGuide: activeTicketGuide
          ? {
              targetId: activeTicketGuide.target.id,
              targetLabel: theaterDropTargetLabel(activeTicketGuide.target.kind),
              visible: true,
              playerReady: isPlayerWithinRpgTarget(
                activeTicketGuide.target,
                this.player.x,
                this.player.y
              ),
              maxDistance: activeTicketGuide.target.proximity,
              dropBounds: {
                x: activeTicketGuide.target.x,
                y: activeTicketGuide.target.y,
                width: activeTicketGuide.target.dropWidth ?? activeTicketGuide.target.proximity * 2,
                height: activeTicketGuide.target.dropHeight ?? activeTicketGuide.target.proximity * 2
              }
            }
          : null,
        spotlight: {
          stage: this.spotlightStage,
          round: state.theaterHunt.spotlightRound,
          aimX: Math.round(this.spotlightAimX),
          aimLane: this.getSpotlightAimLane(),
          beamActive: this.spotlightBeamActive,
          actionElapsedMs: Math.round(this.spotlightActionElapsedMs),
          actionRemainingMs: Math.max(0, Math.round((spotlightConfig?.actionMs ?? 0) - this.spotlightActionElapsedMs)),
          currentLockMs: Math.round(this.spotlightCurrentLockMs),
          maxContinuousLockMs: Math.round(this.spotlightMaxContinuousLockMs),
          requiredLockMs: Math.round((spotlightConfig?.requiredLockMs ?? 0) * spotlightAssist.lockScale),
          earlyExposureMs: Math.round(this.spotlightEarlyExposureMs),
          assistActive: spotlightAssist.active,
          lastFailureReason: this.spotlightLastFailureReason,
          target: this.spotlightPaper
            ? {
                x: Math.round(this.spotlightPaper.x),
                y: Math.round(this.spotlightPaper.y),
                visible: this.spotlightPaper.visible
              }
            : null,
          decoyVisible: this.spotlightDecoyPaper?.visible === true
        },
        activeOcclusionIds: this.activeOcclusionIds,
        softenedOcclusionIds: this.softenedOcclusionIds
      }
    });
  }
}
