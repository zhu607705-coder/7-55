import Phaser from "phaser";
import libraryInteriorMapUrl from "../../assets/rpg/interiors/library_interior.png";
import type { GameState, ItemId, LibraryLocationId } from "../../core/types";
import type { RpgBridge } from "./RpgBridge";
import {
  acceptsLibraryItem,
  findLibraryTargetAt,
  findNearestLibraryTarget,
  getLibraryTarget,
  getVisibleLibraryMarkerIds,
  LIBRARY_CHECKPOINT_SPAWNS,
  LIBRARY_ENTRANCE_DOOR,
  LIBRARY_INTERACTION_TARGETS,
  LIBRARY_INTERIOR_WORLD,
  LIBRARY_STATIC_COLLISION_RECTS,
  shouldOpenLibraryEntranceDoor,
  type LibraryInteractionTarget,
  type LibraryInteractionTargetId
} from "./LibraryInteriorModel";
import { formatRpgInteractionHint } from "./RpgControlHints";
import { RPG_HUD_LAYOUT } from "./RpgHudLayout";
import {
  configureRpgPlayerSprite,
  ensureRpgPlayerTextures,
  preloadRpgPlayerTextures,
  RpgPlayerAnimator,
  RPG_PLAYER_WALK_FPS
} from "./RpgPlayerTextures";
import { clearRpgRuntimeDebugState, setRpgRuntimeDebugState } from "./RpgRuntimeDebug";
import { subscribeRpgSceneBridge } from "./RpgSceneBridgeSubscription";

const LIBRARY_INTERIOR_MAP_KEY = "library-interior-gpt-image-map";

const ITEM_LABELS: Partial<Record<ItemId, string>> = {
  callNumber755: "索书号 755",
  itemRecognitionReport: "物品识别报告",
  rightArrow: "右移箭头",
  seatReleasePass: "离座清退 PASS"
};

const FRONT_DESK_REPORT_HINTS = [
  "前台：请出示物品识别报告。",
  "玩家：我用肉眼看不行吗？",
  "前台：肉眼不是本部门认可设备。",
  "系统：你看，眼睛又输了。"
] as const;

const BACKPACK_BASE_SCALE = 0.6;
const BACKPACK_TABLE_PATCH_FRAME = "library-seat-022-clear-patch";
const BACKPACK_TABLE_PATCH_SOURCE = { left: 1080, top: 392, width: 34, height: 38 } as const;
const SHELF_REVEAL_SHIFT_PX = 16;
const SHELF_SPRITE_FRAME = "library-shelf-755-sprite";
const SHELF_FLOOR_FRAME = "library-shelf-755-floor";
const SHELF_SPRITE_BOUNDS = {
  left: 511,
  top: 105,
  width: 112,
  height: 146
} as const;
const SHELF_FLOOR_SOURCE_TOP = SHELF_SPRITE_BOUNDS.top + 160;
const SHELF_BASE_X = SHELF_SPRITE_BOUNDS.left + SHELF_SPRITE_BOUNDS.width / 2;
const SHELF_BASE_Y = SHELF_SPRITE_BOUNDS.top + SHELF_SPRITE_BOUNDS.height / 2;
const SHELF_COLLISION_RECT = LIBRARY_STATIC_COLLISION_RECTS.find((rect) => rect.id === "north_display_shelf")!;
const SHELF_COLLISION_BASE_X = (SHELF_COLLISION_RECT.left + SHELF_COLLISION_RECT.right) / 2;
const SHELF_PAPER_HIDDEN_X = SHELF_SPRITE_BOUNDS.left + 12;
const SHELF_PAPER_REVEALED_X = SHELF_SPRITE_BOUNDS.left - 8;
const SHELF_PAPER_Y = SHELF_SPRITE_BOUNDS.top + 42;

interface MarkerParts {
  container: Phaser.GameObjects.Container;
  ring: Phaser.GameObjects.Arc;
  glyph: Phaser.GameObjects.Text;
}

type EntranceDoorMotion = "closed" | "opening" | "open" | "closing";
type ShelfRevealPhase = "idle" | "shaking" | "sliding" | "paper" | "complete";
type LostFoundMachineMotion = "idle" | "feeding" | "scanning" | "stamping" | "ejecting" | "complete";

export class LibraryInteriorScene extends Phaser.Scene {
  private bridge!: RpgBridge;
  private player!: Phaser.Physics.Arcade.Sprite;
  private obstacles!: Phaser.Physics.Arcade.StaticGroup;
  private cursors!: Phaser.Types.Input.Keyboard.CursorKeys;
  private keys!: Record<"W" | "A" | "S" | "D" | "SHIFT", Phaser.Input.Keyboard.Key>;
  private virtualDirection = { x: 0, y: 0 };
  private interactRequested = false;
  private playerAnimator!: RpgPlayerAnimator;
  private promptText!: Phaser.GameObjects.Text;
  private markers = new Map<LibraryInteractionTargetId, MarkerParts>();
  private backpack!: Phaser.GameObjects.Container;
  private backpackClearPatch!: Phaser.GameObjects.Image;
  private backpackShadow!: Phaser.GameObjects.Ellipse;
  private backpackTag!: Phaser.GameObjects.Rectangle;
  private backpackEvictionAnimating = false;
  private occupancyNote!: Phaser.GameObjects.Container;
  private receipt!: Phaser.GameObjects.Container;
  private seatStatusDot!: Phaser.GameObjects.Arc;
  private seatStatusText!: Phaser.GameObjects.Text;
  private shelfPanel!: Phaser.GameObjects.Container;
  private targetShelfTag!: Phaser.GameObjects.Text;
  private shelfMechanism!: Phaser.GameObjects.Container;
  private shelfPaper!: Phaser.GameObjects.Container;
  private shelfPaperGlow!: Phaser.GameObjects.Arc;
  private shelfCollision!: Phaser.GameObjects.Rectangle;
  private shelfRevealAnimating = false;
  private shelfRevealPhase: ShelfRevealPhase = "idle";
  private shelfRevealOffsetPx = 0;
  private lostFoundIndicator!: Phaser.GameObjects.Arc;
  private lostFoundScanLine!: Phaser.GameObjects.Rectangle;
  private lostFoundStatusText!: Phaser.GameObjects.Text;
  private lostFoundMachine!: Phaser.GameObjects.Container;
  private lostFoundMachineCasing!: Phaser.GameObjects.Rectangle;
  private lostFoundReport!: Phaser.GameObjects.Container;
  private lostFoundStampHead!: Phaser.GameObjects.Container;
  private lostFoundStampLever!: Phaser.GameObjects.Container;
  private lostFoundStampMark!: Phaser.GameObjects.Text;
  private lostFoundValidationLights: Phaser.GameObjects.Arc[] = [];
  private lostFoundMachineMotion: LostFoundMachineMotion = "idle";
  private catalogIndicator!: Phaser.GameObjects.Arc;
  private catalogScanLine!: Phaser.GameObjects.Rectangle;
  private lastVisitCheck = 0;
  private entranceDoorLeft!: Phaser.GameObjects.Container;
  private entranceDoorRight!: Phaser.GameObjects.Container;
  private entranceDoorBlocker!: Phaser.GameObjects.Rectangle;
  private entranceSensorLight!: Phaser.GameObjects.Rectangle;
  private entranceTurnstileFlaps: Phaser.GameObjects.Rectangle[] = [];
  private entranceDoorMotion: EntranceDoorMotion = "closed";
  private entranceAccessGranted = false;
  private entranceRecordDevice!: Phaser.GameObjects.Container;
  private entranceRecordScreen!: Phaser.GameObjects.Rectangle;
  private entranceRecordIndicator!: Phaser.GameObjects.Arc;
  private entranceRecordStatusText!: Phaser.GameObjects.Text;
  private entranceRecordPanel!: Phaser.GameObjects.Container;
  private entranceRecordConfirmButton!: Phaser.GameObjects.Rectangle;
  private entranceRecordConfirmText!: Phaser.GameObjects.Text;
  private entranceRecordConfirmHitArea!: Phaser.GameObjects.Zone;
  private entranceRecordCloseHitArea!: Phaser.GameObjects.Zone;
  private enterKey!: Phaser.Input.Keyboard.Key;
  private escapeKey!: Phaser.Input.Keyboard.Key;
  private reducedMotion = false;
  private frontDeskReportHintIndex = 0;

  constructor() {
    super("library-interior");
  }

  preload(): void {
    if (!this.textures.exists(LIBRARY_INTERIOR_MAP_KEY)) {
      this.load.image(LIBRARY_INTERIOR_MAP_KEY, libraryInteriorMapUrl);
    }
    preloadRpgPlayerTextures(this);
  }

  create(): void {
    this.bridge = this.registry.get("rpgBridge") as RpgBridge;
    this.reducedMotion = window.matchMedia?.("(prefers-reduced-motion: reduce)").matches === true;
    this.frontDeskReportHintIndex = 0;
    this.cameras.main.setBackgroundColor(0x0b1110);
    this.physics.world.setBounds(48, 48, LIBRARY_INTERIOR_WORLD.width - 96, LIBRARY_INTERIOR_WORLD.height - 96);
    this.obstacles = this.physics.add.staticGroup();
    this.drawInterior();
    ensureRpgPlayerTextures(this);

    const storedCheckpoint = this.bridge.getState().rpgCheckpoint;
    const checkpoint = storedCheckpoint === "campus_spawn"
      || storedCheckpoint === "campus_library_gate"
      || storedCheckpoint === "dorm_spawn"
      ? "library_entrance"
      : storedCheckpoint;
    const spawn = LIBRARY_CHECKPOINT_SPAWNS[checkpoint];
    this.player = this.physics.add.sprite(spawn.x, spawn.y, "act1-player-up-0");
    this.player.setCollideWorldBounds(true).setDepth(spawn.y + 120);
    configureRpgPlayerSprite(this.player);
    this.playerAnimator = new RpgPlayerAnimator(this.player, "up");
    this.physics.add.collider(this.player, this.obstacles);

    this.cursors = this.input.keyboard!.createCursorKeys();
    this.keys = this.input.keyboard!.addKeys("W,A,S,D,SHIFT") as Record<"W" | "A" | "S" | "D" | "SHIFT", Phaser.Input.Keyboard.Key>;
    this.enterKey = this.input.keyboard!.addKey(Phaser.Input.Keyboard.KeyCodes.ENTER);
    this.escapeKey = this.input.keyboard!.addKey(Phaser.Input.Keyboard.KeyCodes.ESC);
    this.cameras.main
      .setBounds(0, 0, LIBRARY_INTERIOR_WORLD.width, LIBRARY_INTERIOR_WORLD.height)
      .setZoom(1)
      .startFollow(this.player, true, 0.12, 0.12, 0, 24)
      .setDeadzone(250, 150);

    this.createMarkers();
    this.createHud();
    this.syncWorldFromState();
    this.bridge.setRpgLocation("library_interior", checkpoint);

    subscribeRpgSceneBridge(
      this.events,
      this.bridge,
      (event) => this.handleBridgeEvent(event.name, event.payload),
      clearRpgRuntimeDebugState
    );
    this.bridge.emit("rpg_booted", { scene: "library_interior", checkpoint });
    this.bridge.emit("rpg_library_room_opened");
    this.publishRuntimeDebug(this.getActiveTargets(this.bridge.getState()));

  }

  update(): void {
    const state = this.bridge.getState();
    const entranceRecordOpen = this.entranceRecordPanel.visible;
    const seatedConversation = state.ui.libraryFinalsPuzzle.playerSeated
      && state.ui.libraryFinalsPuzzle.nextQuestId === null;
    const keyboardX = Number(this.cursors.right.isDown || this.keys.D.isDown)
      - Number(this.cursors.left.isDown || this.keys.A.isDown);
    const keyboardY = Number(this.cursors.down.isDown || this.keys.S.isDown)
      - Number(this.cursors.up.isDown || this.keys.W.isDown);
    const vector = new Phaser.Math.Vector2(
      Phaser.Math.Clamp(keyboardX + this.virtualDirection.x, -1, 1),
      Phaser.Math.Clamp(keyboardY + this.virtualDirection.y, -1, 1)
    );

    if (state.actOne.movementEnabled && !seatedConversation && !this.shelfRevealAnimating && !entranceRecordOpen && vector.lengthSq() > 0) {
      vector.normalize().scale(this.keys.SHIFT.isDown ? 225 : 160);
    } else {
      vector.set(0, 0);
    }
    this.player.setVelocity(vector.x, vector.y).setDepth(this.player.y + 120);
    this.playerAnimator.update(vector, this.time.now);
    this.updateEntranceDoor(state);

    const activeTargets = this.getActiveTargets(state);
    const seatedTarget = seatedConversation
      ? activeTargets.find((target) => target.id === "seat_022_chair") ?? null
      : null;
    const nearest = seatedTarget ?? findNearestLibraryTarget(this.player.x, this.player.y, activeTargets);
    this.publishRuntimeDebug(activeTargets);
    const keyboardInteract = Phaser.Input.Keyboard.JustDown(this.cursors.space);

    if (entranceRecordOpen) {
      this.promptText.setVisible(false);
      this.markers.forEach((marker) => marker.container.setVisible(false));
      const confirmRequested = keyboardInteract
        || Phaser.Input.Keyboard.JustDown(this.enterKey)
        || this.interactRequested;
      if (Phaser.Input.Keyboard.JustDown(this.escapeKey)) {
        this.closeEntranceRecordPanel();
      } else if (confirmRequested) {
        this.confirmEntranceRecord();
      }
      this.interactRequested = false;
      return;
    }

    this.updatePrompt(nearest, state);
    this.updateMarkerVisibility(activeTargets, state, nearest);
    this.updateLostFoundStatus(state);

    if (nearest && (keyboardInteract || this.interactRequested)) {
      this.triggerInteraction(nearest, state);
    }
    this.interactRequested = false;

    if (this.time.now - this.lastVisitCheck >= 220) {
      this.lastVisitCheck = this.time.now;
      this.updateVisitedAreas();
    }
  }

  private handleBridgeEvent(name: string, payload?: Record<string, unknown>): void {
    if (!this.sys?.isActive()) {
      return;
    }
    if (name === "rpg_direction_changed") {
      this.virtualDirection = { x: Number(payload?.x) || 0, y: Number(payload?.y) || 0 };
      return;
    }
    if (name === "rpg_interact") {
      this.interactRequested = true;
      return;
    }
    if (name === "rpg_inventory_drop_requested") {
      const itemId = String(payload?.itemId ?? "") as ItemId;
      const canvasX = Number(payload?.canvasX);
      const canvasY = Number(payload?.canvasY);
      if (Number.isFinite(canvasX) && Number.isFinite(canvasY)) {
        this.handleInventoryDrop(itemId, canvasX, canvasY);
      }
      return;
    }
    if (name === "library_rpg_interaction_failed") {
      this.showFailure(String(payload?.reason ?? "unavailable"), String(payload?.targetId ?? ""));
      return;
    }
    if (name === "library_rpg_context_inspected") {
      const text = String(payload?.text ?? "");
      if (text) this.showFeedback(text, "system");
      return;
    }
    if (name === "library_entrance_record_read") {
      this.entranceAccessGranted = true;
      this.updateEntranceRecordDevice(true);
      this.animateEntranceAccessGranted();
      this.showFeedback("记录已保存", "success");
      return;
    }
    if (name === "library_occupied_seat_found") {
      this.animateOccupiedSeat();
      return;
    }
    if (name === "library_occupancy_note_collected") {
      this.animateCollectedObject(this.occupancyNote, "占座纸条已收入道具栏");
      return;
    }
    if (name === "library_archived_rule_opened") {
      this.animateShelfReveal();
      return;
    }
    if (name === "library_archived_rule_recovered") {
      this.showFeedback("旧规则已确认：三项证明要求已核对，可继续补齐未完成材料。", "system");
      return;
    }
    if (name === "library_catalog_unlocked") {
      this.animateCatalogUnlock();
      this.showFeedback("图书馆馆藏检索功能已解锁。", "success");
      return;
    }
    if (name === "library_lost_found_scan_started") {
      this.animateLostFoundScan();
      this.showFeedback("物品身份盖章机：报告已进入托盘，正在扫描。", "system");
      return;
    }
    if (name === "library_bag_nonperson_proof_issued") {
      this.animateLostFoundStamp();
      return;
    }
    if (name === "library_seat_receipt_recovered") {
      this.animateReceiptRecovery();
      return;
    }
    if (name === "library_seat_release_pass_applied") {
      this.animatePassApplication();
      return;
    }
    if (name === "library_backpack_evicted") {
      this.animateBackpackEviction();
      return;
    }
    if (name === "library_seat_recovered") {
      this.animateSitDown();
      return;
    }
    if (name === "library_friend_contacted") {
      this.animateChapterHandoff();
      this.showFeedback("任务更新：找到那本借走签到记录的书", "chapter");
      return;
    }
    if (name === "library_backpack_broadcast_line") {
      this.showFeedback(String(payload?.text ?? ""), "broadcast");
    }
  }

  private handleInventoryDrop(itemId: ItemId, canvasX: number, canvasY: number): void {
    const worldPoint = this.cameras.main.getWorldPoint(canvasX, canvasY);
    const activeDropTargets = this.getActiveDropTargets(this.bridge.getState());
    const target = findLibraryTargetAt(worldPoint.x, worldPoint.y, activeDropTargets);
    if (!target) {
      this.bridge.emit("library_rpg_interaction_failed", { itemId, reason: "no_target" });
      return;
    }
    if (!acceptsLibraryItem(target, itemId)) {
      this.bridge.emit("library_rpg_interaction_failed", {
        itemId,
        targetId: target.id,
        reason: "wrong_item",
        expectedCategory: target.label
      });
      return;
    }

    const actionByTarget: Partial<Record<LibraryInteractionTargetId, string>> = {
      library_shelf_755: "useCallNumberOnShelf",
      lost_found_machine: "stampNonPersonProof",
      seat_022_gap: "useRightArrowOnReceipt",
      seat_022_backpack: "applyPassToBackpack"
    };
    const action = actionByTarget[target.id];
    if (!action) {
      this.bridge.emit("library_rpg_interaction_failed", { itemId, targetId: target.id, reason: "unavailable" });
      return;
    }
    this.bridge.emit("rpg_library_action_requested", { action, targetId: target.id, itemId });
  }

  private triggerInteraction(target: LibraryInteractionTarget, state: GameState): void {
    const puzzle = state.ui.libraryFinalsPuzzle;
    if (target.id === "entrance_record") {
      this.openEntranceRecordPanel();
      return;
    }
    if (target.id === "seat_022_backpack" && !puzzle.backpackInspected) {
      this.requestAction("inspectBackpack", target.id);
      return;
    }
    if (target.id === "occupancy_note") {
      this.requestAction("collectOccupancyNote", target.id);
      return;
    }
    if (target.id === "catalog_terminal" && puzzle.investigationOpened && !puzzle.catalogUnlocked) {
      this.requestAction("unlockCatalogAtTerminal", target.id);
      return;
    }
    if (target.id === "seat_022_chair" && puzzle.backpackEvicted && !puzzle.playerSeated && !this.backpackEvictionAnimating) {
      this.requestAction("sitAt022", target.id);
      return;
    }
    if (target.id === "seat_022_chair" && puzzle.playerSeated && puzzle.nextQuestId === null) {
      this.bridge.emit("library_story_request", { sequenceId: "library_friend_contacted" });
      return;
    }
    if (
      target.id === "front_desk"
      && puzzle.archivedRuleRead
      && !puzzle.nonPersonProofStamped
      && !puzzle.frontDeskProofRequestSeen
    ) {
      this.bridge.emit("library_story_request", { sequenceId: "library_front_desk_proof_request" });
      return;
    }
    if (
      target.id === "front_desk"
      && puzzle.frontDeskProofRequestSeen
      && !puzzle.itemReportGenerated
    ) {
      const text = FRONT_DESK_REPORT_HINTS[this.frontDeskReportHintIndex];
      this.frontDeskReportHintIndex = Math.min(
        this.frontDeskReportHintIndex + 1,
        FRONT_DESK_REPORT_HINTS.length - 1
      );
      this.showFeedback(text, "system");
      return;
    }

    const text = this.getContextText(target.id, state);
    if (text) {
      this.bridge.emit("library_rpg_context_inspected", { targetId: target.id, text });
    }
  }

  private requestAction(action: string, targetId: LibraryInteractionTargetId): void {
    this.bridge.emit("rpg_library_action_requested", { action, targetId });
  }

  private getActiveTargets(state: GameState): LibraryInteractionTarget[] {
    const puzzle = state.ui.libraryFinalsPuzzle;
    return LIBRARY_INTERACTION_TARGETS.filter((target) => {
      if (target.id === "entrance_record") return true;
      if (target.id === "occupancy_note") return puzzle.backpackInspected && !puzzle.occupancyNoteCollected;
      if (target.id === "seat_022_backpack") return puzzle.entranceRecordRead && !puzzle.backpackEvicted;
      if (target.id === "seat_022_gap") return !puzzle.seatReceiptCollected;
      if (target.id === "library_shelf_755") return puzzle.callNumberCollected && !puzzle.archivedRuleCollected;
      if (target.id === "lost_found_machine") return puzzle.lostFoundStage !== "stamped";
      if (target.id === "seat_022_chair") {
        return puzzle.backpackEvicted && puzzle.nextQuestId === null && !this.backpackEvictionAnimating;
      }
      return true;
    });
  }

  private getActiveDropTargets(state: GameState): LibraryInteractionTarget[] {
    return this.getActiveTargets(state).filter((target) => target.acceptedItem !== undefined);
  }

  private updatePrompt(target: LibraryInteractionTarget | null, state: GameState): void {
    if (!target) {
      this.promptText.setVisible(false);
      return;
    }
    const puzzle = state.ui.libraryFinalsPuzzle;
    let prompt = formatRpgInteractionHint(target.label);
    if (target.acceptedItem) {
      const itemLabel = ITEM_LABELS[target.acceptedItem] ?? "对应道具";
      prompt = `拖入「${itemLabel}」  ${target.label}`;
    }
    if (target.id === "seat_022_backpack" && !puzzle.backpackInspected) {
      prompt = formatRpgInteractionHint("检查占座书包");
    } else if (target.id === "seat_022_chair" && puzzle.playerSeated && puzzle.nextQuestId === null) {
      prompt = formatRpgInteractionHint("继续与 022 对话");
    }
    this.promptText.setText(prompt).setVisible(true);
  }

  private updateMarkerVisibility(
    activeTargets: readonly LibraryInteractionTarget[],
    state: GameState,
    nearest: LibraryInteractionTarget | null
  ): void {
    const selectedItem = state.ui.selectedItem;
    const visibleMarkerIds = getVisibleLibraryMarkerIds(activeTargets, nearest, selectedItem);
    const visibleIds = new Set<LibraryInteractionTargetId>(visibleMarkerIds);
    const showingDropTarget = selectedItem !== null
      && activeTargets.some((target) => target.acceptedItem === selectedItem);
    this.markers.forEach((marker, targetId) => {
      const visible = visibleIds.has(targetId);
      marker.container.setVisible(visible);
      if (visible) {
        marker.ring.setStrokeStyle(3, showingDropTarget ? 0x7bd8ff : 0xe8d46c, 0.95);
      }
    });
    const puzzle = state.ui.libraryFinalsPuzzle;
    if (!this.backpackEvictionAnimating) {
      this.updateSeatStatus(puzzle.backpackEvicted);
    }
    this.targetShelfTag.setText(puzzle.callNumberCollected || puzzle.archivedRuleCollected ? "I247.55" : "I247.??");
  }

  private getContextText(targetId: LibraryInteractionTargetId, state: GameState): string {
    const puzzle = state.ui.libraryFinalsPuzzle;
    if (targetId === "front_desk") {
      if (!puzzle.archivedRuleRead) return "";
      const proofCount = [puzzle.nonPersonProofStamped, puzzle.seatReceiptCollected, puzzle.presenceProofCollected].filter(Boolean).length;
      return proofCount < 3 ? "" : "三项证明已齐，上传给大家看看。";
    }
    if (targetId === "lost_found_machine") {
      return {
        missing_report: "物品身份盖章机：缺少物品识别报告。",
        ready: "物品身份盖章机：将报告拖入进纸托盘。",
        scanning: "物品身份盖章机：报告正在扫描，压章头已就位。",
        stamped: ""
      }[puzzle.lostFoundStage];
    }
    if (targetId === "catalog_terminal") {
      return puzzle.investigationOpened
        ? "馆藏检索已同步到图书馆，可按帖子中的题名继续查找。"
        : "终端可以检索题名、作者和索书号，当前没有调查关键词。";
    }
    if (targetId === "library_shelf_755") {
      return puzzle.callNumberCollected
        ? "书架：I247.55 区域。它看起来不是书架，是一串密码伪装成家具。"
        : "书架：I247.?? 区域。看不清楚，有没有具体索书号？";
    }
    if (targetId === "seat_022_backpack") {
      return puzzle.evictionPassGenerated
        ? "恢复申请已经通过，PASS 可对现场占用物生效。"
        : "";
    }
    const contextByTarget: Record<LibraryInteractionTargetId, string> = {
      entrance_record: "",
      front_desk: "",
      lost_found_machine: "",
      catalog_terminal: "",
      printer: "打印机显示缺纸；旁边的纸盒显示库存充足。",
      library_shelf_755: "",
      seat_022_backpack: "",
      seat_022_gap: "夹缝里露出一角小票，手指无法直接取出。",
      occupancy_note: "纸条引用了一段公开讨论，关键词仍可辨认。",
      seat_022_chair: puzzle.backpackEvicted ? "座位已经空出，可以坐下确认会话。" : "椅子仍被占用。"
    };
    return contextByTarget[targetId];
  }

  private updateVisitedAreas(): void {
    const state = this.bridge.getState();
    const visited = state.ui.libraryFinalsPuzzle.libraryVisitedPoints;
    for (const target of LIBRARY_INTERACTION_TARGETS) {
      const distance = Phaser.Math.Distance.Between(this.player.x, this.player.y, target.x, target.y);
      if (distance > Math.max(target.proximity, 128)) {
        continue;
      }
      if (target.checkpoint) {
        this.bridge.setCheckpoint(target.checkpoint);
      }
      if (target.location && !visited.includes(target.location)) {
        this.bridge.emit("rpg_library_action_requested", {
          action: "visitLibraryPoint",
          point: target.location,
          checkpoint: target.checkpoint
        });
      }
    }
  }

  private publishRuntimeDebug(activeTargets: readonly LibraryInteractionTarget[]): void {
    const state = this.bridge.getState();
    setRpgRuntimeDebugState({
      coordinateSystem: "Phaser world coordinates, origin at top-left, x right, y down",
      scene: "library_interior",
      checkpoint: state.rpgCheckpoint,
      world: { width: LIBRARY_INTERIOR_WORLD.width, height: LIBRARY_INTERIOR_WORLD.height },
      player: {
        x: this.player.x,
        y: this.player.y,
        facing: this.playerAnimator.facing,
        texture: this.playerAnimator.textureKey,
        turning: this.playerAnimator.isTurning,
        walkFps: RPG_PLAYER_WALK_FPS,
        angle: this.player.angle
      },
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
      activeTargets: activeTargets.map((target) => ({
        id: target.id,
        x: target.x,
        y: target.y,
        width: target.width,
        height: target.height,
        ...(target.acceptedItem ? { acceptedItem: target.acceptedItem } : {})
      })),
      collisionRects: LIBRARY_STATIC_COLLISION_RECTS.map((rect) => rect.id === "north_display_shelf"
        ? {
            ...rect,
            left: rect.left + this.shelfRevealOffsetPx,
            right: rect.right + this.shelfRevealOffsetPx
          }
        : rect),
      entranceDoor: {
        state: this.entranceDoorMotion,
        accessGranted: this.entranceAccessGranted
      },
      entranceRecord: {
        open: this.entranceRecordPanel.visible,
        read: state.ui.libraryFinalsPuzzle.entranceRecordRead,
        ...(this.entranceRecordPanel.visible
          ? {
              entries: [
                { time: "07:55", location: "主馆入口" },
                { time: "08:02", location: "二楼南区 022" }
              ],
              calculation: "08:02 - 07:55"
            }
          : {})
      },
      backpack: {
        visible: this.backpackEvictionAnimating || !state.ui.libraryFinalsPuzzle.backpackEvicted,
        mapVisible: !state.ui.libraryFinalsPuzzle.backpackEvicted && !this.backpackClearPatch.visible,
        overlayVisible: this.backpack.visible,
        clearPatchVisible: this.backpackClearPatch.visible,
        x: this.backpack.x,
        y: this.backpack.y,
        scaleX: this.backpack.scaleX,
        scaleY: this.backpack.scaleY,
        angle: this.backpack.angle,
        evictionAnimating: this.backpackEvictionAnimating
      },
      shelfReveal: {
        phase: this.shelfRevealPhase,
        offsetPx: this.shelfRevealOffsetPx,
        paperVisible: this.shelfPaper.visible
      },
      lostFoundStampMachine: {
        stage: state.ui.libraryFinalsPuzzle.lostFoundStage,
        motion: this.lostFoundMachineMotion,
        reportVisible: this.lostFoundReport.visible,
        stampHeadY: this.lostFoundStampHead.y,
        leverAngle: this.lostFoundStampLever.angle,
        stampVisible: this.lostFoundStampMark.visible
      }
    });
  }

  private showFailure(reason: string, targetId: string): void {
    const text = reason === "wrong_item"
      ? "这个道具和目标的证据类型对不上。"
      : reason === "no_target"
        ? "道具没有落在可交互目标上。"
        : "条件还不完整，目标暂时不接受这个操作。";
    this.showFeedback(text, "error");
    if (targetId && this.markers.has(targetId as LibraryInteractionTargetId)) {
      const marker = this.markers.get(targetId as LibraryInteractionTargetId)!;
      this.tweens.add({ targets: marker.container, x: marker.container.x + 5, duration: 55, yoyo: true, repeat: 3 });
    }
  }

  private showFeedback(text: string, tone: "system" | "success" | "error" | "broadcast" | "chapter"): void {
    this.bridge.emit("rpg_subtitle", {
      text,
      tone: tone === "chapter" ? "task" : tone,
      durationMs: tone === "chapter" ? 4200 : 3000
    });
  }

  private animateOccupiedSeat(): void {
    this.occupancyNote.setVisible(true).setAlpha(1);
    this.seatStatusDot.setFillStyle(0xe65c57).setAlpha(1).setScale(1);
    const signalRings = [18, 30, 42].map((radius, index) => {
      const ring = this.add.circle(this.backpack.x, this.backpack.y + 8, radius, 0x9fd8cf, 0)
        .setStrokeStyle(3, index === 2 ? 0xe65c57 : 0x7ed0c3, 0.9)
        .setDepth(this.backpack.depth - 2)
        .setScale(0.45)
        .setAlpha(0);
      this.tweens.add({
        targets: ring,
        alpha: { from: 0.9, to: 0 },
        scale: { from: 0.45, to: 1.25 },
        delay: index * 120,
        duration: 620,
        ease: "Stepped",
        onComplete: () => ring.destroy()
      });
      return ring;
    });
    const signalLabel = this.add.text(this.backpack.x, this.backpack.y - 58, "022  LINK LOST", {
      color: "#f4df87",
      fontFamily: "monospace",
      fontSize: "10px",
      fontStyle: "bold"
    }).setOrigin(0.5).setDepth(this.backpack.depth + 4).setAlpha(0).setStroke("#142521", 3);
    this.tweens.add({
      targets: signalLabel,
      alpha: 1,
      y: signalLabel.y - 8,
      duration: 180,
      yoyo: true,
      hold: 900,
      onComplete: () => signalLabel.destroy()
    });
    this.tweens.add({
      targets: this.seatStatusDot,
      scale: 1.9,
      alpha: 0.3,
      duration: 180,
      yoyo: true,
      repeat: 2,
      onComplete: () => this.seatStatusDot.setScale(1).setAlpha(1)
    });
    this.time.delayedCall(180, () => signalRings.forEach((ring) => ring.setVisible(true)));
    this.showFeedback("022 仍有微弱信号，信号源被书包压住了。", "error");
  }

  private animateCollectedObject(object: Phaser.GameObjects.Container, message: string): void {
    this.animateEvidenceTransfer(object.x, object.y, 0xe7d38f);
    this.tweens.add({
      targets: object,
      y: object.y - 48,
      alpha: 0,
      duration: 420,
      ease: "Stepped",
      onComplete: () => object.setVisible(false)
    });
    this.showFeedback(message, "success");
  }

  private animateShelfReveal(): void {
    if (this.shelfRevealAnimating || this.shelfRevealPhase === "complete") {
      return;
    }
    this.shelfRevealAnimating = true;
    this.shelfRevealPhase = "shaking";
    this.player.setVelocity(0, 0);
    this.targetShelfTag.setText("I247.55");
    this.shelfPanel.setDepth(4300);
    this.shelfMechanism.setVisible(true).setAlpha(1);
    this.shelfPaper
      .setVisible(true)
      .setAlpha(this.reducedMotion ? 0.45 : 0.18)
      .setPosition(SHELF_PAPER_HIDDEN_X, SHELF_PAPER_Y);
    this.shelfPaperGlow
      .setVisible(true)
      .setPosition(SHELF_PAPER_HIDDEN_X, SHELF_PAPER_Y)
      .setAlpha(this.reducedMotion ? 0.12 : 0.04);
    const shakeOffsets = this.reducedMotion ? [0] : [4, -5, 3, -4, 0];
    const shakeDuration = this.reducedMotion ? 1 : 45;
    shakeOffsets.forEach((offset, index) => {
      this.time.delayedCall(index * shakeDuration, () => {
        this.setShelfRevealOffset(offset);
      });
    });
    this.time.delayedCall(shakeOffsets.length * shakeDuration, () => {
      this.shelfRevealPhase = "sliding";
      const slideOffsets = this.reducedMotion ? [SHELF_REVEAL_SHIFT_PX] : [4, 8, 12, SHELF_REVEAL_SHIFT_PX];
      const slideStepDuration = this.reducedMotion ? 140 : 115;
      slideOffsets.forEach((offset, index) => {
        this.time.delayedCall((index + 1) * slideStepDuration, () => this.setShelfRevealOffset(offset));
      });
      this.time.delayedCall(slideOffsets.length * slideStepDuration, () => this.animateShelfPaperReveal());
    });
    this.showFeedback("书架横移了一格，后面夹着一份很旧的黄纸。", "success");
  }

  private animateShelfPaperReveal(): void {
    this.setShelfRevealOffset(SHELF_REVEAL_SHIFT_PX);
    this.shelfRevealPhase = "paper";
    this.tweens.add({
      targets: this.shelfPaperGlow,
      x: SHELF_PAPER_REVEALED_X,
      alpha: this.reducedMotion ? 0.2 : 0.42,
      duration: this.reducedMotion ? 100 : 220,
      yoyo: !this.reducedMotion,
      repeat: this.reducedMotion ? 0 : 1
    });
    this.tweens.add({
      targets: this.shelfPaper,
      x: SHELF_PAPER_REVEALED_X,
      y: SHELF_PAPER_Y + (this.reducedMotion ? 0 : 6),
      alpha: 1,
      duration: this.reducedMotion ? 120 : 240,
      ease: "Stepped",
      onComplete: () => this.time.delayedCall(this.reducedMotion ? 20 : 220, () => {
        this.animateEvidenceTransfer(this.shelfPaper.x, this.shelfPaper.y, 0xd8c48c);
        this.tweens.add({
          targets: [this.shelfPaper, this.shelfPaperGlow],
          y: this.shelfPaper.y - 16,
          alpha: 0,
          duration: this.reducedMotion ? 100 : 220,
          ease: "Stepped",
          onComplete: () => {
            this.shelfPanel.setDepth(430);
            this.shelfPaper.setVisible(false);
            this.shelfPaperGlow.setVisible(false);
            this.shelfRevealAnimating = false;
            this.shelfRevealPhase = "complete";
            this.bridge.emit("library_archived_rule_reveal_completed", { itemId: "archivedLeaveRule" });
          }
        });
      })
    });
  }

  private setShelfRevealOffset(offsetPx: number): void {
    const snappedOffset = Math.round(offsetPx);
    this.shelfRevealOffsetPx = snappedOffset;
    this.shelfPanel.setX(SHELF_BASE_X + snappedOffset);
    this.shelfCollision.setX(SHELF_COLLISION_BASE_X + snappedOffset);
    const body = this.shelfCollision.body as Phaser.Physics.Arcade.StaticBody | null;
    body?.updateFromGameObject();
  }

  private animateCatalogUnlock(): void {
    this.catalogIndicator.setFillStyle(0x65dca0).setAlpha(1).setScale(1);
    this.catalogScanLine.setVisible(true).setAlpha(0.9).setY(526);
    this.tweens.add({
      targets: this.catalogScanLine,
      y: 580,
      alpha: 0.25,
      duration: 420,
      ease: "Stepped",
      onComplete: () => this.catalogScanLine.setVisible(false)
    });
    this.tweens.add({
      targets: this.catalogIndicator,
      scale: 1.8,
      alpha: 0.35,
      duration: 130,
      yoyo: true,
      repeat: 2,
      onComplete: () => this.catalogIndicator.setScale(1).setAlpha(1)
    });
  }

  private animateLostFoundScan(): void {
    this.tweens.killTweensOf([
      this.lostFoundReport,
      this.lostFoundScanLine,
      this.lostFoundStampHead,
      this.lostFoundStampLever
    ]);
    this.lostFoundMachineMotion = "feeding";
    this.lostFoundIndicator.setFillStyle(0xe1b953).setAlpha(1).setScale(1);
    this.lostFoundStampHead.setY(5);
    this.lostFoundStampLever.setAngle(-24);
    this.lostFoundStampMark.setVisible(false).setAlpha(0).setScale(1.4);
    this.lostFoundReport.setVisible(true).setAlpha(1).setPosition(-58, 39);
    this.lostFoundScanLine.setVisible(false).setAlpha(0.95).setY(26);

    const beginScan = () => {
      this.lostFoundMachineMotion = "scanning";
      if (this.reducedMotion) {
        this.lostFoundScanLine.setVisible(false);
        return;
      }
      this.lostFoundScanLine.setVisible(true).setAlpha(0.95).setY(26);
      this.tweens.add({
        targets: this.lostFoundScanLine,
        y: 51,
        alpha: 0.28,
        duration: 340,
        yoyo: true,
        repeat: 1,
        ease: "Stepped",
        onComplete: () => this.lostFoundScanLine.setVisible(false)
      });
    };

    if (this.reducedMotion) {
      this.lostFoundReport.setX(0);
      beginScan();
    } else {
      this.tweens.add({
        targets: this.lostFoundReport,
        x: 0,
        duration: 220,
        ease: "Stepped",
        onComplete: beginScan
      });
    }
    this.tweens.add({
      targets: this.lostFoundIndicator,
      alpha: 0.35,
      duration: 120,
      yoyo: true,
      repeat: 4,
      onComplete: () => this.lostFoundIndicator.setAlpha(1)
    });
  }

  private updateSeatStatus(isAvailable: boolean): void {
    this.seatStatusDot.setFillStyle(isAvailable ? 0x55c98c : 0xe65c57);
    this.seatStatusText
      .setText(isAvailable ? "022 · 空闲" : "022 · 占用")
      .setColor(isAvailable ? "#8ce1b4" : "#f0d56a");
  }

  private animateLostFoundStamp(): void {
    const machine = getLibraryTarget("lost_found_machine");
    this.tweens.killTweensOf([
      this.lostFoundReport,
      this.lostFoundScanLine,
      this.lostFoundStampHead,
      this.lostFoundStampLever,
      this.lostFoundMachine
    ]);
    this.lostFoundMachine.setPosition(machine.x, machine.y);
    this.lostFoundMachineMotion = "stamping";
    this.lostFoundScanLine.setVisible(false).setY(26);
    this.lostFoundIndicator.setFillStyle(0x5ed68d).setAlpha(1).setScale(1);
    this.lostFoundReport.setVisible(true).setAlpha(1).setPosition(0, 39);
    this.lostFoundStampMark.setVisible(true).setAlpha(0).setScale(1.45);
    this.tweens.add({
      targets: this.lostFoundIndicator,
      scale: 2,
      alpha: 0.3,
      duration: 110,
      yoyo: true,
      repeat: 4,
      onComplete: () => this.lostFoundIndicator.setScale(1).setAlpha(1)
    });

    const impact = () => {
      this.lostFoundStampMark.setAlpha(1);
      if (this.reducedMotion) {
        this.lostFoundStampMark.setScale(1);
      } else {
        this.tweens.add({
          targets: this.lostFoundStampMark,
          scale: 1,
          duration: 120,
          ease: "Stepped"
        });
        this.tweens.add({
          targets: this.lostFoundMachine,
          y: machine.y + 3,
          duration: 45,
          yoyo: true,
          repeat: 1,
          onComplete: () => this.lostFoundMachine.setY(machine.y)
        });
      }

      this.time.delayedCall(this.reducedMotion ? 1 : 140, () => {
        this.tweens.add({ targets: this.lostFoundStampHead, y: 5, duration: this.reducedMotion ? 1 : 120, ease: "Stepped" });
        this.tweens.add({ targets: this.lostFoundStampLever, angle: -24, duration: this.reducedMotion ? 1 : 140, ease: "Stepped" });
      });
      this.time.delayedCall(this.reducedMotion ? 2 : 280, () => {
        this.lostFoundMachineMotion = "ejecting";
        this.tweens.add({
          targets: this.lostFoundReport,
          x: 58,
          y: 50,
          alpha: 0,
          duration: this.reducedMotion ? 1 : 420,
          ease: "Stepped",
          onComplete: () => {
            this.lostFoundReport.setVisible(false).setPosition(-58, 39).setAlpha(1);
            this.lostFoundStampMark.setVisible(false).setAlpha(0);
            this.lostFoundMachineMotion = "complete";
            this.animateEvidenceTransfer(machine.x + 52, machine.y + 42, 0x5ed68d);
          }
        });
      });
    };

    if (this.reducedMotion) {
      this.lostFoundStampHead.setY(25);
      this.lostFoundStampLever.setAngle(8);
      impact();
    } else {
      this.tweens.add({
        targets: this.lostFoundStampHead,
        y: 25,
        duration: 110,
        ease: "Stepped",
        onComplete: impact
      });
      this.tweens.add({
        targets: this.lostFoundStampLever,
        angle: 8,
        duration: 110,
        ease: "Stepped"
      });
    }
    this.showFeedback("盖章完成：书包不等于本人。", "success");
  }

  private animateReceiptRecovery(): void {
    const gap = getLibraryTarget("seat_022_gap");
    this.receipt.setVisible(true).setAlpha(1).setPosition(gap.x - 68, gap.y - 24);
    this.tweens.add({
      targets: this.receipt,
      x: gap.x + 32,
      angle: 6,
      duration: 520,
      ease: "Stepped",
      onComplete: () => {
        this.animateEvidenceTransfer(this.receipt.x, this.receipt.y, 0x78a9df);
        this.time.delayedCall(500, () => this.receipt.setVisible(false));
      }
    });
    this.showFeedback("小票向“右”了。", "success");
  }

  private animatePassApplication(): void {
    const pass = this.add.text(this.player.x, this.player.y - 18, "PASS", {
      color: "#f6f1dc",
      backgroundColor: "#2f8a59",
      fontFamily: "monospace",
      fontSize: "14px",
      padding: { x: 8, y: 5 }
    }).setOrigin(0.5).setDepth(6200);
    this.tweens.add({
      targets: pass,
      x: this.backpack.x,
      y: this.backpack.y - 34,
      angle: 360,
      duration: 620,
      ease: "Stepped",
      onComplete: () => pass.destroy()
    });
  }

  private animateBackpackEviction(): void {
    this.backpackEvictionAnimating = true;
    const backpackTarget = getLibraryTarget("seat_022_backpack");
    this.backpackClearPatch.setVisible(true);
    this.backpack
      .setPosition(backpackTarget.x, backpackTarget.y)
      .setScale(BACKPACK_BASE_SCALE)
      .setAngle(-4)
      .setAlpha(1)
      .setVisible(true);
    this.backpackShadow.setAlpha(0.32).setScale(1);
    this.seatStatusDot.setFillStyle(0xe1b953).setAlpha(1).setScale(1);
    this.seatStatusText.setText("022 · 转移中").setColor("#f0d56a");
    const lines = [
      "书包：主人马上回来。",
      "玩家：什么时候？",
      "书包：三分钟。",
      "系统：它三天前也是这么说的。"
    ];
    lines.forEach((text, index) => {
      this.time.delayedCall(index * 720, () => this.bridge.emit("library_backpack_broadcast_line", { text, index }));
    });
    this.tweens.add({
      targets: this.backpack,
      x: this.backpack.x + 7,
      duration: 70,
      yoyo: true,
      repeat: 8,
      onComplete: () => {
        this.tweens.add({
          targets: this.backpack,
          x: getLibraryTarget("lost_found_machine").x,
          y: getLibraryTarget("lost_found_machine").y + 40,
          alpha: 0,
          duration: 1200,
          delay: 1900,
          ease: "Stepped",
          onComplete: () => {
            this.backpack.setVisible(false);
            this.backpackEvictionAnimating = false;
            this.updateSeatStatus(true);
            this.seatStatusDot.setAlpha(1).setScale(1);
            this.seatStatusText.setAlpha(1).setScale(1);
          }
        });
      }
    });
    this.tweens.add({
      targets: [this.seatStatusDot, this.seatStatusText],
      scale: 1.25,
      duration: 140,
      yoyo: true,
      repeat: 2,
      ease: "Stepped",
      onComplete: () => {
        this.seatStatusDot.setScale(1);
        this.seatStatusText.setScale(1);
      }
    });
  }

  private animateSitDown(): void {
    this.player.setVelocity(0, 0);
    this.tweens.add({
      targets: this.player,
      x: getLibraryTarget("seat_022_chair").x,
      y: getLibraryTarget("seat_022_chair").y,
      duration: 420,
      ease: "Stepped",
      onComplete: () => {
        this.playerAnimator.setFacing("up");
        this.showFeedback("022 已恢复。", "success");
      }
    });
  }

  private animateEvidenceTransfer(worldX: number, worldY: number, color: number): void {
    const camera = this.cameras.main;
    const startX = (worldX - camera.worldView.x) * camera.zoom;
    const startY = (worldY - camera.worldView.y) * camera.zoom;
    const targetX = 872;
    const targetY = 470;
    const packet = this.add.container(startX, startY).setScrollFactor(0).setDepth(10120);
    const plate = this.add.rectangle(0, 0, 28, 22, color, 0.96).setStrokeStyle(3, 0x16201e, 1);
    const fold = this.add.triangle(8, -6, 0, 0, 8, 0, 8, 8, 0xf4ead1, 0.85);
    const lineA = this.add.rectangle(-5, 2, 11, 2, 0x27322f, 0.85);
    const lineB = this.add.rectangle(-2, 7, 16, 2, 0x27322f, 0.65);
    packet.add([plate, fold, lineA, lineB]);

    const receiver = this.add.circle(targetX, targetY, 18, color, 0.08)
      .setStrokeStyle(3, color, 0.92)
      .setScrollFactor(0)
      .setDepth(10110)
      .setAlpha(0);
    this.tweens.add({
      targets: receiver,
      alpha: 1,
      scale: 1.55,
      duration: 180,
      yoyo: true,
      hold: 430,
      onComplete: () => receiver.destroy()
    });

    for (let index = 0; index < 5; index += 1) {
      const pixel = this.add.rectangle(startX, startY, 5, 5, color, 0.9)
        .setScrollFactor(0)
        .setDepth(10100);
      this.tweens.add({
        targets: pixel,
        x: targetX + (index % 2 === 0 ? -8 : 8),
        y: targetY + (index - 2) * 5,
        alpha: 0,
        delay: index * 55,
        duration: 520,
        ease: "Stepped",
        onComplete: () => pixel.destroy()
      });
    }

    this.tweens.add({
      targets: packet,
      x: targetX,
      y: targetY,
      angle: 90,
      scale: 0.28,
      alpha: 0.2,
      duration: 650,
      ease: "Stepped",
      onComplete: () => packet.destroy()
    });
  }

  private animateChapterHandoff(): void {
    const wash = this.add.rectangle(480, 270, 960, 540, 0xf7f2df, 0)
      .setScrollFactor(0)
      .setDepth(10130);
    const leftPage = this.add.rectangle(-18, 0, 36, 58, 0xede3c3)
      .setStrokeStyle(3, 0x3c3025);
    const rightPage = this.add.rectangle(18, 0, 36, 58, 0xede3c3)
      .setStrokeStyle(3, 0x3c3025);
    const spine = this.add.rectangle(0, 0, 4, 58, 0xb54b43);
    const book = this.add.container(480, 270, [leftPage, rightPage, spine])
      .setScrollFactor(0)
      .setDepth(10140)
      .setScale(0.25)
      .setAlpha(0);
    this.tweens.add({
      targets: wash,
      alpha: { from: 0, to: 0.68 },
      duration: 220,
      yoyo: true,
      hold: 360,
      onComplete: () => wash.destroy()
    });
    this.tweens.add({
      targets: book,
      alpha: 1,
      scale: 1.2,
      angle: -4,
      duration: 340,
      ease: "Stepped",
      yoyo: true,
      hold: 280,
      onComplete: () => book.destroy()
    });
  }

  private updateEntranceDoor(state: GameState): void {
    this.entranceAccessGranted = state.ui.libraryFinalsPuzzle.entranceRecordRead;
    const shouldOpen = shouldOpenLibraryEntranceDoor(
      this.entranceAccessGranted,
      this.player.x,
      this.player.y
    );
    if (shouldOpen && (this.entranceDoorMotion === "closed" || this.entranceDoorMotion === "closing")) {
      this.openEntranceDoor();
    } else if (!shouldOpen && this.entranceDoorMotion === "open") {
      this.closeEntranceDoor();
    }
  }

  private animateEntranceAccessGranted(): void {
    this.openEntranceDoor();
    this.entranceSensorLight.setFillStyle(0x55d892).setAlpha(1);
    this.tweens.add({
      targets: this.entranceSensorLight,
      alpha: 0.35,
      duration: 90,
      yoyo: true,
      repeat: 4,
      ease: "Stepped"
    });
    const scanLine = this.add.rectangle(LIBRARY_ENTRANCE_DOOR.x, 696, 188, 6, 0x6ce0af, 0.45)
      .setDepth(940);
    this.tweens.add({
      targets: scanLine,
      y: 828,
      alpha: 0,
      duration: 420,
      ease: "Stepped",
      onComplete: () => scanLine.destroy()
    });
  }

  private openEntranceDoor(): void {
    if (this.entranceDoorMotion === "open" || this.entranceDoorMotion === "opening") {
      return;
    }
    this.stopEntranceDoorTweens();
    this.entranceDoorMotion = "opening";
    this.entranceSensorLight.setFillStyle(0x55d892).setAlpha(1);
    this.time.delayedCall(120, () => {
      if (this.entranceDoorMotion === "opening" || this.entranceDoorMotion === "open") {
        this.setEntranceBarrierEnabled(false);
      }
    });
    this.tweens.add({
      targets: this.entranceDoorLeft,
      x: LIBRARY_ENTRANCE_DOOR.closedLeftX - LIBRARY_ENTRANCE_DOOR.openOffset,
      duration: 360,
      ease: "Stepped"
    });
    this.tweens.add({
      targets: this.entranceDoorRight,
      x: LIBRARY_ENTRANCE_DOOR.closedRightX + LIBRARY_ENTRANCE_DOOR.openOffset,
      duration: 360,
      ease: "Stepped",
      onComplete: () => {
        if (this.entranceDoorMotion === "opening") {
          this.entranceDoorMotion = "open";
        }
      }
    });
    this.tweens.add({
      targets: this.entranceTurnstileFlaps[0],
      angle: -90,
      alpha: 0.28,
      duration: 240,
      ease: "Stepped"
    });
    this.tweens.add({
      targets: this.entranceTurnstileFlaps[1],
      angle: 90,
      alpha: 0.28,
      duration: 240,
      ease: "Stepped"
    });
  }

  private closeEntranceDoor(): void {
    if (this.entranceDoorMotion === "closed" || this.entranceDoorMotion === "closing") {
      return;
    }
    this.stopEntranceDoorTweens();
    this.entranceDoorMotion = "closing";
    this.entranceSensorLight.setFillStyle(0xd1aa54).setAlpha(0.9);
    this.tweens.add({
      targets: this.entranceDoorLeft,
      x: LIBRARY_ENTRANCE_DOOR.closedLeftX,
      duration: 320,
      ease: "Stepped"
    });
    this.tweens.add({
      targets: this.entranceDoorRight,
      x: LIBRARY_ENTRANCE_DOOR.closedRightX,
      duration: 320,
      ease: "Stepped",
      onComplete: () => {
        if (this.entranceDoorMotion === "closing") {
          this.entranceDoorMotion = "closed";
          this.setEntranceBarrierEnabled(true);
          this.entranceSensorLight.setFillStyle(0xc75d55).setAlpha(0.95);
        }
      }
    });
    this.entranceTurnstileFlaps.forEach((flap) => {
      this.tweens.add({ targets: flap, angle: 0, alpha: 0.58, duration: 220, ease: "Stepped" });
    });
  }

  private setEntranceDoorInstant(open: boolean): void {
    this.stopEntranceDoorTweens();
    this.entranceDoorLeft.setX(open
      ? LIBRARY_ENTRANCE_DOOR.closedLeftX - LIBRARY_ENTRANCE_DOOR.openOffset
      : LIBRARY_ENTRANCE_DOOR.closedLeftX);
    this.entranceDoorRight.setX(open
      ? LIBRARY_ENTRANCE_DOOR.closedRightX + LIBRARY_ENTRANCE_DOOR.openOffset
      : LIBRARY_ENTRANCE_DOOR.closedRightX);
    this.entranceTurnstileFlaps[0].setAngle(open ? -90 : 0).setAlpha(open ? 0.28 : 0.58);
    this.entranceTurnstileFlaps[1].setAngle(open ? 90 : 0).setAlpha(open ? 0.28 : 0.58);
    this.entranceDoorMotion = open ? "open" : "closed";
    this.entranceSensorLight.setFillStyle(open ? 0x55d892 : 0xc75d55).setAlpha(0.95);
    this.setEntranceBarrierEnabled(!open);
  }

  private stopEntranceDoorTweens(): void {
    this.tweens.killTweensOf([
      this.entranceDoorLeft,
      this.entranceDoorRight,
      ...this.entranceTurnstileFlaps
    ]);
  }

  private setEntranceBarrierEnabled(enabled: boolean): void {
    const body = this.entranceDoorBlocker.body as Phaser.Physics.Arcade.StaticBody | null;
    if (body) {
      body.enable = enabled;
    }
  }

  private syncWorldFromState(): void {
    const puzzle = this.bridge.getState().ui.libraryFinalsPuzzle;
    if (puzzle.playerSeated && puzzle.nextQuestId === null) {
      const seat = getLibraryTarget("seat_022_chair");
      this.player.setPosition(seat.x, seat.y);
      this.playerAnimator.setFacing("up");
    }
    this.entranceAccessGranted = puzzle.entranceRecordRead;
    this.updateEntranceRecordDevice(puzzle.entranceRecordRead);
    this.setEntranceDoorInstant(shouldOpenLibraryEntranceDoor(
      this.entranceAccessGranted,
      this.player.x,
      this.player.y
    ));
    const backpackTarget = getLibraryTarget("seat_022_backpack");
    this.backpackClearPatch.setVisible(puzzle.backpackEvicted);
    this.backpack
      .setPosition(backpackTarget.x, backpackTarget.y)
      .setScale(BACKPACK_BASE_SCALE)
      .setAngle(-4)
      .setAlpha(1)
      .setVisible(false);
    this.backpackEvictionAnimating = false;
    this.occupancyNote.setVisible(puzzle.backpackInspected && !puzzle.occupancyNoteCollected);
    this.receipt.setVisible(false);
    this.setShelfRevealOffset(puzzle.archivedRuleCollected ? SHELF_REVEAL_SHIFT_PX : 0);
    this.shelfRevealPhase = puzzle.archivedRuleCollected ? "complete" : "idle";
    this.targetShelfTag.setText(puzzle.callNumberCollected || puzzle.archivedRuleCollected ? "I247.55" : "I247.??");
    this.shelfMechanism.setVisible(puzzle.archivedRuleCollected);
    this.shelfPaper.setVisible(false);
    this.shelfPaperGlow.setVisible(false);
    this.updateSeatStatus(puzzle.backpackEvicted);
    this.seatStatusDot.setAlpha(1).setScale(1);
    this.seatStatusText.setAlpha(1).setScale(1);
    this.catalogIndicator.setFillStyle(puzzle.catalogUnlocked ? 0x65dca0 : 0xd2aa54).setAlpha(1);
    this.catalogScanLine.setVisible(false);
    this.syncLostFoundStampMachine(puzzle.lostFoundStage);
  }

  private createMarkers(): void {
    LIBRARY_INTERACTION_TARGETS.forEach((target, index) => {
      const ring = this.add.circle(0, 0, 10, 0x173331, 0.72).setStrokeStyle(3, 0xe8d46c, 0.95);
      const glyph = this.add.text(0, -1, target.acceptedItem ? "↧" : "·", {
        color: target.acceptedItem ? "#8fd7ff" : "#fff6c7",
        fontFamily: "monospace",
        fontSize: target.acceptedItem ? "11px" : "18px",
        fontStyle: "bold"
      }).setOrigin(0.5);
      const markerGap = target.id === "entrance_record" ? 44 : 18;
      const container = this.add.container(target.x, target.y - target.height / 2 - markerGap, [ring, glyph])
        .setDepth(5000 + index)
        .setVisible(false);
      this.tweens.add({
        targets: container,
        y: container.y - 3,
        duration: 720 + index * 18,
        yoyo: true,
        repeat: -1,
        ease: "Stepped"
      });
      this.markers.set(target.id, { container, ring, glyph });
    });
  }

  private createHud(): void {
    this.promptText = this.add.text(RPG_HUD_LAYOUT.centerX, RPG_HUD_LAYOUT.promptBottomY, "", {
      color: "#fff7df",
      backgroundColor: "#10201deb",
      fontFamily: "monospace",
      fontSize: "12px",
      padding: { x: 13, y: 6 }
    }).setOrigin(0.5, 1).setScrollFactor(0).setDepth(10000).setVisible(false);

    this.createEntranceRecordPanel();
  }

  private createEntranceRecordPanel(): void {
    const backdrop = this.add.rectangle(0, 0, 960, 540, 0x07100f, 0.74);

    const shadow = this.add.rectangle(7, 9, 680, 385, 0x000000, 0.55);
    const bezel = this.add.rectangle(0, 0, 680, 385, 0x182b28, 0.99)
      .setStrokeStyle(5, 0xd3c68e, 0.98);
    const screen = this.add.rectangle(0, 5, 648, 348, 0x0b1e1c, 1)
      .setStrokeStyle(2, 0x4e766c, 0.9);
    const header = this.add.rectangle(0, -151, 648, 46, 0x254a43, 1);
    const headerAccent = this.add.rectangle(-318, -151, 7, 44, 0xe0ca70, 1);
    const title = this.add.text(-300, -151, "图书馆门禁 · 入馆记录", {
      color: "#f6f0d7",
      fontFamily: "monospace",
      fontSize: "17px",
      fontStyle: "bold"
    }).setOrigin(0, 0.5);
    const recordId = this.add.text(255, -151, "LOG 01", {
      color: "#9ce4bf",
      fontFamily: "monospace",
      fontSize: "12px",
      fontStyle: "bold"
    }).setOrigin(1, 0.5);

    const scanLines = [-112, -76, -40, -4, 32, 68, 104].map((y) => (
      this.add.rectangle(0, y, 622, 2, 0x8ec3b7, 0.045)
    ));

    const leftCard = this.add.rectangle(-157, -24, 252, 126, 0x15312e, 0.96)
      .setStrokeStyle(3, 0x5e8c80, 0.82);
    const leftLabel = this.add.text(-264, -70, "入馆扫描", {
      color: "#a9c9c0",
      fontFamily: "monospace",
      fontSize: "12px"
    }).setOrigin(0, 0.5);
    const leftTime = this.add.text(-157, -24, "07:55", {
      color: "#f3dc83",
      fontFamily: "monospace",
      fontSize: "38px",
      fontStyle: "bold"
    }).setOrigin(0.5);
    const leftLocation = this.add.text(-157, 22, "主馆入口", {
      color: "#eff7ef",
      fontFamily: "monospace",
      fontSize: "13px"
    }).setOrigin(0.5);

    const rightCard = this.add.rectangle(157, -24, 252, 126, 0x15312e, 0.96)
      .setStrokeStyle(3, 0x5e8c80, 0.82);
    const rightLabel = this.add.text(50, -70, "到达记录", {
      color: "#a9c9c0",
      fontFamily: "monospace",
      fontSize: "12px"
    }).setOrigin(0, 0.5);
    const rightTime = this.add.text(157, -24, "08:02", {
      color: "#8ce1b4",
      fontFamily: "monospace",
      fontSize: "38px",
      fontStyle: "bold"
    }).setOrigin(0.5);
    const rightLocation = this.add.text(157, 22, "二楼南区 022", {
      color: "#eff7ef",
      fontFamily: "monospace",
      fontSize: "13px"
    }).setOrigin(0.5);
    const direction = this.add.text(0, -23, "→", {
      color: "#d9cb90",
      fontFamily: "monospace",
      fontSize: "24px",
      fontStyle: "bold"
    }).setOrigin(0.5);

    const calculationLabel = this.add.text(0, 69, "到座耗时核对：08:02 − 07:55", {
      color: "#dcebe5",
      fontFamily: "monospace",
      fontSize: "14px",
      fontStyle: "bold"
    }).setOrigin(0.5);
    const seatStatus = this.add.text(0, 96, "目标记录：二楼南区 022 · 会话未闭合", {
      color: "#8fb9ae",
      fontFamily: "monospace",
      fontSize: "12px"
    }).setOrigin(0.5);

    this.entranceRecordConfirmButton = this.add.rectangle(0, 137, 172, 38, 0x397b61, 1)
      .setStrokeStyle(3, 0xbce7c8, 0.95);
    this.entranceRecordConfirmText = this.add.text(0, 137, "记下记录", {
      color: "#f5f6df",
      fontFamily: "monospace",
      fontSize: "14px",
      fontStyle: "bold"
    }).setOrigin(0.5);
    const closeButton = this.add.rectangle(307, -151, 38, 34, 0x142421, 0.92)
      .setStrokeStyle(2, 0x739288, 0.82);
    const closeGlyph = this.add.text(307, -152, "×", {
      color: "#d9e8e2",
      fontFamily: "monospace",
      fontSize: "20px"
    }).setOrigin(0.5);
    const controls = this.add.text(0, 174, "Enter / 空格 确认 · Esc 关闭", {
      color: "#7fa49b",
      fontFamily: "monospace",
      fontSize: "10px"
    }).setOrigin(0.5);

    this.entranceRecordPanel = this.add.container(480, 270, [
      backdrop,
      shadow,
      bezel,
      screen,
      ...scanLines,
      header,
      headerAccent,
      title,
      recordId,
      leftCard,
      rightCard,
      leftLabel,
      rightLabel,
      leftTime,
      rightTime,
      leftLocation,
      rightLocation,
      direction,
      calculationLabel,
      seatStatus,
      this.entranceRecordConfirmButton,
      this.entranceRecordConfirmText,
      closeButton,
      closeGlyph,
      controls
    ])
      .setScrollFactor(0)
      .setDepth(10300)
      .setVisible(false)
      .setAlpha(0)
      .setScale(0.96);

    this.entranceRecordConfirmHitArea = this.add.zone(480, 407, 172, 38)
      .setScrollFactor(0)
      .setDepth(10320)
      .setVisible(false)
      .setInteractive({ useHandCursor: true })
      .disableInteractive();
    this.entranceRecordCloseHitArea = this.add.zone(787, 119, 38, 34)
      .setScrollFactor(0)
      .setDepth(10320)
      .setVisible(false)
      .setInteractive({ useHandCursor: true })
      .disableInteractive();

    this.entranceRecordConfirmHitArea
      .on("pointerover", () => this.entranceRecordConfirmButton.setFillStyle(0x4a9473, 1))
      .on("pointerout", () => this.entranceRecordConfirmButton.setFillStyle(0x397b61, 1))
      .on("pointerdown", () => this.confirmEntranceRecord());
    this.entranceRecordCloseHitArea
      .on("pointerover", () => closeButton.setFillStyle(0x31534b, 1))
      .on("pointerout", () => closeButton.setFillStyle(0x142421, 0.92))
      .on("pointerdown", () => this.closeEntranceRecordPanel());
  }

  private createEntranceRecordDevice(): void {
    const target = getLibraryTarget("entrance_record");
    const shadow = this.add.rectangle(3, 5, 146, 60, 0x111a18, 0.58);
    const casing = this.add.rectangle(0, 0, 146, 60, 0xd8cdb0, 1)
      .setStrokeStyle(4, 0x2b413c, 1);
    this.entranceRecordScreen = this.add.rectangle(0, -4, 130, 34, 0x163d35, 1)
      .setStrokeStyle(2, 0x6f9e91, 0.9);
    this.entranceRecordIndicator = this.add.circle(-54, -4, 4, 0xe3c65d, 1);
    const title = this.add.text(-43, -10, "入馆记录", {
      color: "#f4efdc",
      fontFamily: "monospace",
      fontSize: "12px",
      fontStyle: "bold"
    }).setOrigin(0, 0.5);
    this.entranceRecordStatusText = this.add.text(-43, 5, "点击查看", {
      color: "#a8d8c9",
      fontFamily: "monospace",
      fontSize: "9px"
    }).setOrigin(0, 0.5);
    const base = this.add.rectangle(0, 25, 82, 8, 0x8a8069, 1)
      .setStrokeStyle(2, 0x2b413c, 1);
    const hitTarget = this.add.rectangle(0, 0, 154, 68, 0xffffff, 0.001)
      .setInteractive({ useHandCursor: true });

    this.entranceRecordDevice = this.add.container(750, 727, [
      shadow,
      casing,
      this.entranceRecordScreen,
      this.entranceRecordIndicator,
      title,
      this.entranceRecordStatusText,
      base,
      hitTarget
    ]).setDepth(848);

    hitTarget
      .on("pointerover", () => {
        this.entranceRecordScreen.setStrokeStyle(3, 0xcfe7a6, 1);
        this.entranceRecordDevice.setScale(1.02);
      })
      .on("pointerout", () => {
        this.entranceRecordScreen.setStrokeStyle(2, 0x6f9e91, 0.9);
        this.entranceRecordDevice.setScale(1);
      })
      .on("pointerdown", () => {
        if (!this.player || this.entranceRecordPanel.visible) {
          return;
        }
        const distance = Phaser.Math.Distance.Between(this.player.x, this.player.y, target.x, target.y);
        if (distance <= target.proximity + 24) {
          this.bridge.setCheckpoint("library_entrance");
          this.openEntranceRecordPanel();
          return;
        }
        this.tweens.add({
          targets: this.entranceRecordDevice,
          x: { from: 747, to: 753 },
          duration: 55,
          yoyo: true,
          repeat: 2,
          onComplete: () => this.entranceRecordDevice.setX(750)
        });
      });
  }

  private openEntranceRecordPanel(): void {
    if (this.entranceRecordPanel.visible) {
      return;
    }
    const alreadyRead = this.bridge.getState().ui.libraryFinalsPuzzle.entranceRecordRead;
    this.player.setVelocity(0, 0);
    this.bridge.emit("rpg_subtitle_clear");
    this.promptText.setVisible(false);
    this.entranceRecordConfirmText.setText(alreadyRead ? "关闭记录" : "记下记录");
    this.tweens.killTweensOf(this.entranceRecordPanel);
    this.entranceRecordPanel
      .setVisible(true)
      .setAlpha(0)
      .setScale(this.reducedMotion ? 1 : 0.96);
    this.entranceRecordConfirmHitArea.setVisible(true).setInteractive({ useHandCursor: true });
    this.entranceRecordCloseHitArea.setVisible(true).setInteractive({ useHandCursor: true });
    this.tweens.add({
      targets: this.entranceRecordPanel,
      alpha: 1,
      scale: 1,
      duration: this.reducedMotion ? 1 : 140,
      ease: "Stepped"
    });
    this.tweens.add({
      targets: this.entranceRecordIndicator,
      alpha: 0.28,
      duration: 95,
      yoyo: true,
      repeat: 3,
      onComplete: () => this.entranceRecordIndicator.setAlpha(1)
    });
  }

  private confirmEntranceRecord(): void {
    if (!this.entranceRecordPanel.visible) {
      return;
    }
    const alreadyRead = this.bridge.getState().ui.libraryFinalsPuzzle.entranceRecordRead;
    this.closeEntranceRecordPanel();
    if (!alreadyRead) {
      this.requestAction("readEntranceRecord", "entrance_record");
    }
  }

  private closeEntranceRecordPanel(): void {
    if (!this.entranceRecordPanel.visible) {
      return;
    }
    this.entranceRecordConfirmHitArea.disableInteractive().setVisible(false);
    this.entranceRecordCloseHitArea.disableInteractive().setVisible(false);
    this.tweens.killTweensOf(this.entranceRecordPanel);
    this.tweens.add({
      targets: this.entranceRecordPanel,
      alpha: 0,
      scale: this.reducedMotion ? 1 : 0.97,
      duration: this.reducedMotion ? 1 : 100,
      ease: "Stepped",
      onComplete: () => this.entranceRecordPanel.setVisible(false)
    });
  }

  private updateEntranceRecordDevice(read: boolean): void {
    this.entranceRecordScreen.setFillStyle(read ? 0x205746 : 0x163d35, 1);
    this.entranceRecordIndicator.setFillStyle(read ? 0x72d79d : 0xe3c65d, 1);
    this.entranceRecordStatusText
      .setText(read ? "已读取 · 点击复查" : "点击查看")
      .setColor(read ? "#bdebc9" : "#a8d8c9");
  }

  private drawInterior(): void {
    this.textures.get(LIBRARY_INTERIOR_MAP_KEY).setFilter(Phaser.Textures.FilterMode.NEAREST);
    this.add.image(750, 450, LIBRARY_INTERIOR_MAP_KEY).setDisplaySize(1500, 900).setDepth(0);
    this.createInteriorColliders();

    this.add.text(750, 66, "基础图书馆  ·  二层南区", {
      color: "#e9ddbd",
      backgroundColor: "#172520dc",
      fontFamily: "monospace",
      fontSize: "17px",
      fontStyle: "bold",
      padding: { x: 12, y: 6 }
    }).setOrigin(0.5).setDepth(90);

    this.drawEntrance();
    this.drawFrontDesk();
    this.drawCatalogArea();
    this.drawShelves();
    this.drawSeatingArea();
    this.drawAmbientDetails();
  }

  private createInteriorColliders(): void {
    const addObstacle = (x: number, y: number, width: number, height: number) => {
      const obstacle = this.add.rectangle(x, y, width, height, 0x000000, 0).setDepth(y + 30);
      this.obstacles.add(obstacle);
      return obstacle;
    };

    LIBRARY_STATIC_COLLISION_RECTS.forEach((rect) => {
      const obstacle = addObstacle(
        (rect.left + rect.right) / 2,
        (rect.top + rect.bottom) / 2,
        rect.right - rect.left,
        rect.bottom - rect.top
      );
      if (rect.id === "north_display_shelf") {
        this.shelfCollision = obstacle;
      }
    });

    if (import.meta.env.DEV && new URLSearchParams(window.location.search).get("debugColliders") === "1") {
      const overlay = this.add.graphics().setDepth(20000).setScrollFactor(1);
      overlay.fillStyle(0xe84f4f, 0.2).lineStyle(2, 0xffdf5d, 0.95);
      LIBRARY_STATIC_COLLISION_RECTS.forEach((rect) => {
        overlay.fillRect(rect.left, rect.top, rect.right - rect.left, rect.bottom - rect.top);
        overlay.strokeRect(rect.left, rect.top, rect.right - rect.left, rect.bottom - rect.top);
      });
    }
  }

  private drawEntrance(): void {
    const createGlassPanel = (x: number, handleX: number) => {
      const glass = this.add.rectangle(0, 0, 106, 86, 0x7fb1bd, 0.34)
        .setStrokeStyle(4, 0x263c43, 0.95);
      const innerFrame = this.add.rectangle(0, 0, 92, 72, 0xb8dfe4, 0.08)
        .setStrokeStyle(2, 0xb8dfe4, 0.4);
      const shine = this.add.line(0, 0, -42, -34, 24, 34, 0xe8f7f5, 0.25)
        .setLineWidth(3, 3);
      const handle = this.add.rectangle(handleX, 0, 5, 28, 0xe3ece8, 0.82)
        .setStrokeStyle(2, 0x32474b, 0.95);
      return this.add.container(x, LIBRARY_ENTRANCE_DOOR.y, [glass, innerFrame, shine, handle])
        .setDepth(834);
    };

    this.add.rectangle(LIBRARY_ENTRANCE_DOOR.x, 678, 226, 9, 0x263c43, 0.96)
      .setStrokeStyle(2, 0xa7c7c9, 0.65)
      .setDepth(836);
    this.entranceSensorLight = this.add.rectangle(LIBRARY_ENTRANCE_DOOR.x, 676, 16, 8, 0xc75d55, 0.95)
      .setStrokeStyle(2, 0x1d2a2d, 1)
      .setDepth(840);
    this.entranceDoorLeft = createGlassPanel(LIBRARY_ENTRANCE_DOOR.closedLeftX, 45);
    this.entranceDoorRight = createGlassPanel(LIBRARY_ENTRANCE_DOOR.closedRightX, -45);

    this.entranceTurnstileFlaps = [715, 785].map((x) => this.add.rectangle(x, 806, 42, 8, 0x8fc9d1, 0.58)
      .setStrokeStyle(2, 0x23383d, 0.95)
      .setDepth(932));

    this.entranceDoorBlocker = this.add.rectangle(
      LIBRARY_ENTRANCE_DOOR.x,
      LIBRARY_ENTRANCE_DOOR.blockerY,
      LIBRARY_ENTRANCE_DOOR.blockerWidth,
      12,
      0x000000,
      0
    ).setDepth(825);
    this.obstacles.add(this.entranceDoorBlocker);

    this.createEntranceRecordDevice();
  }

  private drawFrontDesk(): void {
    this.add.text(315, 682, "信息台 / 失物招领", {
      color: "#f2e5c6",
      backgroundColor: "#23332fee",
      fontFamily: "monospace",
      fontSize: "14px",
      padding: { x: 8, y: 4 }
    }).setOrigin(0.5).setDepth(810);

    const target = getLibraryTarget("lost_found_machine");
    const shadow = this.add.ellipse(2, 57, 88, 18, 0x101715, 0.5);
    this.lostFoundMachineCasing = this.add.rectangle(0, 0, 82, 94, 0x34433f, 1)
      .setStrokeStyle(4, 0x18231f, 1);
    const topCap = this.add.rectangle(0, -51, 90, 12, 0x65736c, 1)
      .setStrokeStyle(3, 0x18231f, 1);
    const titlePlate = this.add.text(0, -60, "STAMP 0.22", {
      color: "#f0d56a",
      backgroundColor: "#1b2824ee",
      fontFamily: "monospace",
      fontSize: "9px",
      fontStyle: "bold",
      padding: { x: 4, y: 2 }
    }).setOrigin(0.5);
    const screen = this.add.rectangle(0, -33, 54, 18, 0x173b35, 1)
      .setStrokeStyle(2, 0x7fa89b, 0.9);
    this.lostFoundIndicator = this.add.circle(-33, -33, 5, 0xc96a5e, 1)
      .setStrokeStyle(2, 0x18231f, 1);
    this.lostFoundStatusText = this.add.text(0, -33, "", {
      color: "#f2e5c6",
      fontFamily: "monospace",
      fontSize: "9px",
      fontStyle: "bold"
    }).setOrigin(0.5);

    const validationXs = [-22, 0, 22];
    const validationLabels = ["名", "号", "人"];
    const validationTexts: Phaser.GameObjects.Text[] = [];
    this.lostFoundValidationLights = validationXs.map((x, index) => {
      const light = this.add.circle(x, -13, 4, 0xc96a5e, 1)
        .setStrokeStyle(1, 0x18231f, 1);
      validationTexts.push(this.add.text(x, -4, validationLabels[index], {
        color: "#c6d1ca",
        fontFamily: "monospace",
        fontSize: "7px"
      }).setOrigin(0.5));
      return light;
    });

    const leftGuide = this.add.rectangle(-25, 18, 6, 52, 0x718078, 1)
      .setStrokeStyle(2, 0x18231f, 1);
    const rightGuide = this.add.rectangle(25, 18, 6, 52, 0x718078, 1)
      .setStrokeStyle(2, 0x18231f, 1);
    const stampBridge = this.add.rectangle(0, 4, 54, 8, 0x56645e, 1)
      .setStrokeStyle(2, 0x18231f, 1);
    const tray = this.add.rectangle(0, 39, 64, 28, 0x232f2c, 1)
      .setStrokeStyle(3, 0x18231f, 1);
    const feedSlot = this.add.rectangle(0, 28, 48, 5, 0x0d1513, 1)
      .setStrokeStyle(1, 0xa0b1a9, 0.7);
    const base = this.add.rectangle(0, 52, 90, 12, 0x59665f, 1)
      .setStrokeStyle(3, 0x18231f, 1);

    const stampStem = this.add.rectangle(0, -9, 8, 23, 0x9ba69f, 1)
      .setStrokeStyle(2, 0x26332f, 1);
    const stampHead = this.add.rectangle(0, 6, 36, 12, 0xb94f49, 1)
      .setStrokeStyle(3, 0x5a2624, 1);
    this.lostFoundStampHead = this.add.container(0, 5, [stampStem, stampHead]);

    const leverArm = this.add.rectangle(0, 12, 6, 38, 0x9ba69f, 1)
      .setStrokeStyle(2, 0x26332f, 1);
    const leverKnob = this.add.rectangle(0, 33, 14, 10, 0xb94f49, 1)
      .setStrokeStyle(2, 0x5a2624, 1);
    this.lostFoundStampLever = this.add.container(33, -10, [leverArm, leverKnob]).setAngle(-24);

    const paper = this.add.rectangle(0, 0, 46, 28, 0xf2ead5, 1)
      .setStrokeStyle(2, 0x5a625d, 1);
    const reportLineOne = this.add.rectangle(-5, -7, 25, 2, 0x87928c, 0.9);
    const reportLineTwo = this.add.rectangle(-8, -1, 19, 2, 0x87928c, 0.7);
    this.lostFoundStampMark = this.add.text(4, 5, "非本人", {
      color: "#b43f3f",
      fontFamily: "monospace",
      fontSize: "9px",
      fontStyle: "bold"
    }).setOrigin(0.5).setVisible(false);
    this.lostFoundReport = this.add.container(-58, 39, [paper, reportLineOne, reportLineTwo, this.lostFoundStampMark])
      .setVisible(false);
    this.lostFoundScanLine = this.add.rectangle(0, 26, 46, 3, 0xe1b953, 0.95)
      .setVisible(false);

    const hitTarget = this.add.zone(0, 0, target.width, target.height)
      .setInteractive({ useHandCursor: true });
    this.lostFoundMachine = this.add.container(target.x, target.y, [
      shadow,
      this.lostFoundMachineCasing,
      topCap,
      titlePlate,
      screen,
      this.lostFoundIndicator,
      this.lostFoundStatusText,
      ...this.lostFoundValidationLights,
      ...validationTexts,
      leftGuide,
      rightGuide,
      stampBridge,
      tray,
      feedSlot,
      base,
      this.lostFoundStampHead,
      this.lostFoundStampLever,
      this.lostFoundReport,
      this.lostFoundScanLine,
      hitTarget
    ]).setDepth(target.y + 82);

    hitTarget
      .on("pointerover", () => this.lostFoundMachineCasing.setStrokeStyle(4, 0xe1b953, 1))
      .on("pointerout", () => this.lostFoundMachineCasing.setStrokeStyle(4, 0x18231f, 1))
      .on("pointerdown", () => {
        const distance = Phaser.Math.Distance.Between(this.player.x, this.player.y, target.x, target.y);
        if (distance > target.proximity + 24) {
          this.showFeedback("先走近物品身份盖章机。", "system");
          return;
        }
        this.bridge.setCheckpoint("library_front_desk");
        const text = this.getContextText(target.id, this.bridge.getState());
        if (text) {
          this.bridge.emit("library_rpg_context_inspected", { targetId: target.id, text });
        }
      });
  }

  private updateLostFoundStatus(state: GameState): void {
    const stage = state.ui.libraryFinalsPuzzle.lostFoundStage;
    const labels = {
      missing_report: "缺报告",
      ready: "投入报告",
      scanning: "扫描",
      stamped: "完成"
    } as const;
    const colors = {
      missing_report: 0xc96a5e,
      ready: 0xe1b953,
      scanning: 0xe1b953,
      stamped: 0x5ed68d
    } as const;
    this.lostFoundStatusText.setText(labels[stage]);
    this.lostFoundIndicator.setFillStyle(colors[stage]);
    this.lostFoundStatusText.setColor(stage === "stamped" ? "#bdebc9" : stage === "missing_report" ? "#f1b3ad" : "#f7e6a6");
    this.lostFoundValidationLights.forEach((light, index) => {
      const color = stage === "stamped"
        ? 0x5ed68d
        : stage === "scanning" && index < 2
          ? 0xe1b953
          : stage === "ready"
            ? 0xe1b953
            : 0xc96a5e;
      light.setFillStyle(color).setAlpha(stage === "missing_report" ? 0.72 : 1);
    });
  }

  private syncLostFoundStampMachine(stage: GameState["ui"]["libraryFinalsPuzzle"]["lostFoundStage"]): void {
    const machine = getLibraryTarget("lost_found_machine");
    this.tweens.killTweensOf([
      this.lostFoundMachine,
      this.lostFoundReport,
      this.lostFoundScanLine,
      this.lostFoundStampHead,
      this.lostFoundStampLever,
      this.lostFoundStampMark
    ]);
    this.lostFoundMachine.setPosition(machine.x, machine.y);
    this.lostFoundStampHead.setY(5);
    this.lostFoundStampLever.setAngle(-24);
    this.lostFoundScanLine.setVisible(false).setY(26).setAlpha(0.95);
    this.lostFoundReport.setVisible(false).setPosition(-58, 39).setAlpha(1);
    this.lostFoundStampMark.setVisible(false).setAlpha(0).setScale(1.4);
    this.lostFoundMachineMotion = stage === "stamped" ? "complete" : "idle";
    if (stage === "scanning") {
      this.animateLostFoundScan();
    }
  }

  private drawCatalogArea(): void {
    this.add.text(760, 408, "馆藏检索 / 打印", {
      color: "#f2e5c6",
      backgroundColor: "#23332fee",
      fontFamily: "monospace",
      fontSize: "13px",
      fontStyle: "bold",
      padding: { x: 8, y: 4 }
    }).setOrigin(0.5).setDepth(680);
    this.catalogIndicator = this.add.circle(687, 512, 5, 0xd2aa54, 1)
      .setStrokeStyle(2, 0x1b2926, 1)
      .setDepth(706);
    this.catalogScanLine = this.add.rectangle(653, 526, 58, 4, 0x65dca0, 0.9)
      .setDepth(704)
      .setVisible(false);
  }

  private drawShelves(): void {
    this.add.text(500, 92, "文学 / 社科书架", {
      color: "#eadfca",
      backgroundColor: "#24342fee",
      fontFamily: "monospace",
      fontSize: "13px",
      padding: { x: 8, y: 4 }
    }).setOrigin(0.5).setDepth(120);

    const mapTexture = this.textures.get(LIBRARY_INTERIOR_MAP_KEY);
    if (!mapTexture.has(SHELF_SPRITE_FRAME)) {
      mapTexture.add(
        SHELF_SPRITE_FRAME,
        0,
        SHELF_SPRITE_BOUNDS.left,
        SHELF_SPRITE_BOUNDS.top,
        SHELF_SPRITE_BOUNDS.width,
        SHELF_SPRITE_BOUNDS.height
      );
    }
    if (!mapTexture.has(SHELF_FLOOR_FRAME)) {
      mapTexture.add(
        SHELF_FLOOR_FRAME,
        0,
        SHELF_SPRITE_BOUNDS.left,
        SHELF_FLOOR_SOURCE_TOP,
        SHELF_SPRITE_BOUNDS.width,
        SHELF_SPRITE_BOUNDS.height
      );
    }

    this.add.image(SHELF_BASE_X, SHELF_BASE_Y, LIBRARY_INTERIOR_MAP_KEY, SHELF_FLOOR_FRAME)
      .setDepth(410);
    const upperRail = this.add.rectangle(0, -48, SHELF_SPRITE_BOUNDS.width, 5, 0x4a3525)
      .setStrokeStyle(2, 0x241a14);
    const lowerRail = this.add.rectangle(0, 48, SHELF_SPRITE_BOUNDS.width, 5, 0x4a3525)
      .setStrokeStyle(2, 0x241a14);
    const recess = this.add.rectangle(-47, -30, 17, 46, 0x171612, 0.94)
      .setStrokeStyle(2, 0x7d6337, 0.9);
    const boltTop = this.add.rectangle(-47, -46, 4, 4, 0xd2ae54);
    const boltBottom = this.add.rectangle(-47, 46, 4, 4, 0xd2ae54);
    this.shelfMechanism = this.add.container(
      SHELF_BASE_X,
      SHELF_BASE_Y,
      [upperRail, lowerRail, recess, boltTop, boltBottom]
    ).setDepth(418).setVisible(false);
    this.shelfPaperGlow = this.add.circle(
      SHELF_PAPER_HIDDEN_X,
      SHELF_PAPER_Y,
      22,
      0xf0df9b,
      0.12
    ).setDepth(422).setVisible(false);
    this.shelfPaper = this.createPaperObject(
      SHELF_PAPER_HIDDEN_X,
      SHELF_PAPER_Y,
      "旧规",
      0xe7d8ab
    ).setDepth(425).setVisible(false);
    const shelfSprite = this.add.image(0, 0, LIBRARY_INTERIOR_MAP_KEY, SHELF_SPRITE_FRAME);
    this.targetShelfTag = this.add.text(0, SHELF_SPRITE_BOUNDS.height / 2 + 15, "I247.??", {
      color: "#18231f",
      backgroundColor: "#e8d9b8",
      fontFamily: "monospace",
      fontSize: "11px",
      padding: { x: 5, y: 3 }
    }).setOrigin(0.5);
    this.shelfPanel = this.add.container(
      SHELF_BASE_X,
      SHELF_BASE_Y,
      [shelfSprite, this.targetShelfTag]
    ).setDepth(430);
  }

  private drawSeatingArea(): void {
    this.add.text(1140, 105, "二层南区 · 安静阅览", {
      color: "#e9dfc7",
      backgroundColor: "#24342fee",
      fontFamily: "monospace",
      fontSize: "14px",
      padding: { x: 8, y: 4 }
    }).setOrigin(0.5).setDepth(120);

    this.seatStatusDot = this.add.circle(1252, 322, 6, 0xe65c57, 1)
      .setStrokeStyle(2, 0x24342f, 1)
      .setDepth(548);
    this.seatStatusText = this.add.text(1300, 322, "022 · 占用", {
      color: "#f0d66c",
      fontFamily: "monospace",
      fontSize: "14px",
      fontStyle: "bold"
    }).setOrigin(0.5).setDepth(548).setStroke("#24342f", 3);
    const backpack = getLibraryTarget("seat_022_backpack");
    const note = getLibraryTarget("occupancy_note");
    const gap = getLibraryTarget("seat_022_gap");
    const mapTexture = this.textures.get(LIBRARY_INTERIOR_MAP_KEY);
    if (!mapTexture.has(BACKPACK_TABLE_PATCH_FRAME)) {
      mapTexture.add(
        BACKPACK_TABLE_PATCH_FRAME,
        0,
        BACKPACK_TABLE_PATCH_SOURCE.left,
        BACKPACK_TABLE_PATCH_SOURCE.top,
        BACKPACK_TABLE_PATCH_SOURCE.width,
        BACKPACK_TABLE_PATCH_SOURCE.height
      );
    }
    this.backpackClearPatch = this.add.image(
      backpack.x,
      backpack.y,
      LIBRARY_INTERIOR_MAP_KEY,
      BACKPACK_TABLE_PATCH_FRAME
    ).setDepth(2).setVisible(false);
    this.backpack = this.createBackpack(backpack.x, backpack.y).setVisible(false);
    this.occupancyNote = this.createPaperObject(note.x, note.y, "纸条", 0xe9dcae);
    this.receipt = this.createPaperObject(gap.x, gap.y, "022", 0xf1ead8).setVisible(false);
  }

  private drawStudyTable(x: number, y: number, label: string, target = false): void {
    this.addFurniture(x, y, 184, 78, target ? 0x7b593c : 0x68503a, 0x2f241b);
    this.add.rectangle(x, y - 29, 170, 12, target ? 0xb9864b : 0x8a6848).setDepth(y + 84);
    this.add.circle(x - 55, y - 22, 9, 0xe6ce73, 0.9).setStrokeStyle(2, 0x5e4e27).setDepth(y + 88);
    this.add.rectangle(x + 45, y - 15, 38, 24, target ? 0x284759 : 0x435951).setStrokeStyle(2, 0x1a2925).setDepth(y + 88);
    [-66, 66].forEach((offset) => {
      this.add.rectangle(x + offset, y + 86, 54, 46, 0x334641).setStrokeStyle(3, 0x19231f).setDepth(y + 108);
    });
    this.add.text(x, y - 5, label, {
      color: target ? "#f0d66c" : "#d7cbb1",
      fontFamily: "monospace",
      fontSize: target ? "15px" : "12px",
      fontStyle: "bold"
    }).setOrigin(0.5).setDepth(y + 90);
  }

  private createBackpack(x: number, y: number): Phaser.GameObjects.Container {
    const outline = 0x111820;
    const strap = 0x273c54;
    const body = 0x244b71;
    const bodyLight = 0x3f7196;
    const pocket = 0x183a5b;
    const hardware = 0xc87842;

    this.backpackShadow = this.add.ellipse(2, 29, 54, 14, 0x111715, 0.32);

    const leftStrap = this.add.rectangle(-22, 4, 8, 44, strap).setAngle(-10);
    const rightStrap = this.add.rectangle(22, 4, 8, 44, strap).setAngle(10);
    const leftStrapEnd = this.add.rectangle(-20, 25, 8, 7, hardware).setAngle(-10);
    const rightStrapEnd = this.add.rectangle(20, 25, 8, 7, hardware).setAngle(10);

    const handleTop = this.add.rectangle(0, -38, 18, 5, outline);
    const handleLeft = this.add.rectangle(-7, -34, 4, 8, outline);
    const handleRight = this.add.rectangle(7, -34, 4, 8, outline);
    const handleInset = this.add.rectangle(0, -37, 10, 2, bodyLight);

    const outerCap = this.add.rectangle(0, -27, 30, 8, outline);
    const outerShoulders = this.add.rectangle(0, -21, 44, 8, outline);
    const outerBody = this.add.rectangle(0, -5, 54, 28, outline);
    const outerLower = this.add.rectangle(0, 13, 50, 12, outline);
    const outerBase = this.add.rectangle(0, 23, 40, 8, outline);
    const innerCap = this.add.rectangle(0, -26, 24, 5, bodyLight);
    const innerShoulders = this.add.rectangle(0, -20, 38, 6, body);
    const innerBody = this.add.rectangle(0, -5, 46, 24, body);
    const innerLower = this.add.rectangle(0, 13, 42, 9, body);
    const innerBase = this.add.rectangle(0, 22, 32, 5, 0x1d4163);

    const leftPipingTop = this.add.rectangle(-21, -15, 3, 10, hardware, 0.88);
    const leftPipingBody = this.add.rectangle(-24, 1, 3, 21, hardware, 0.88);
    const rightShade = this.add.rectangle(22, 0, 3, 23, 0x122f49, 0.92);
    const fabricHighlight = this.add.rectangle(-10, -17, 10, 3, 0x77a1b8, 0.7);
    const zipperTrack = this.add.rectangle(0, -10, 36, 3, outline);
    const zipperTeeth = [-12, -6, 0, 6, 12].map((offset) => (
      this.add.rectangle(offset, -9, 2, 2, hardware)
    ));
    const zipperPull = this.add.rectangle(17, -7, 4, 7, hardware).setStrokeStyle(1, outline);

    const pocketTopOutline = this.add.rectangle(0, 5, 30, 5, outline);
    const pocketOutline = this.add.rectangle(0, 12, 36, 12, outline);
    const pocketBottomOutline = this.add.rectangle(0, 20, 28, 6, outline);
    const pocketTop = this.add.rectangle(0, 5, 24, 3, 0x356b8b);
    const pocketBody = this.add.rectangle(0, 12, 30, 9, pocket);
    const pocketBottom = this.add.rectangle(0, 19, 22, 4, pocket);
    const pocketFlap = this.add.rectangle(0, 8, 24, 2, 0x4f7f9a);
    const leftBuckle = this.add.rectangle(-21, 21, 5, 5, hardware).setAngle(-10);
    const rightBuckle = this.add.rectangle(21, 21, 5, 5, hardware).setAngle(10);

    this.backpackTag = this.add.rectangle(8, 9, 9, 7, 0xe7d9a7).setStrokeStyle(2, 0x5f552f);
    const tagMark = this.add.rectangle(8, 9, 4, 2, 0x53615a);

    return this.add.container(x, y, [
      this.backpackShadow,
      leftStrap,
      rightStrap,
      leftStrapEnd,
      rightStrapEnd,
      handleTop,
      handleLeft,
      handleRight,
      handleInset,
      outerCap,
      outerShoulders,
      outerBody,
      outerLower,
      outerBase,
      innerCap,
      innerShoulders,
      innerBody,
      innerLower,
      innerBase,
      leftPipingTop,
      leftPipingBody,
      rightShade,
      fabricHighlight,
      zipperTrack,
      ...zipperTeeth,
      zipperPull,
      pocketTopOutline,
      pocketOutline,
      pocketBottomOutline,
      pocketTop,
      pocketBody,
      pocketBottom,
      pocketFlap,
      leftBuckle,
      rightBuckle,
      this.backpackTag,
      tagMark
    ]).setDepth(y + 150).setScale(BACKPACK_BASE_SCALE).setAngle(-4);
  }

  private createPaperObject(x: number, y: number, text: string, color: number): Phaser.GameObjects.Container {
    const paper = this.add.rectangle(0, 0, 42, 30, color).setStrokeStyle(3, 0x42372a);
    const fold = this.add.triangle(15, -9, 0, 0, 10, 0, 10, 10, 0xc5b48b);
    const label = this.add.text(-1, 2, text, { color: "#40372c", fontFamily: "monospace", fontSize: "9px" }).setOrigin(0.5);
    return this.add.container(x, y, [paper, fold, label]).setDepth(y + 180);
  }

  private drawAmbientDetails(): void {
    for (let index = 0; index < 10; index += 1) {
      const mote = this.add.rectangle(
        90 + (index * 83) % 1320,
        140 + (index * 113) % 610,
        3,
        3,
        0xffefbd,
        0.28
      ).setDepth(20);
      this.tweens.add({
        targets: mote,
        y: mote.y - 18,
        alpha: 0.08,
        duration: 1800 + index * 90,
        yoyo: true,
        repeat: -1
      });
    }
  }

  private drawZoneFloor(x: number, y: number, width: number, height: number, color: number, border: number): void {
    this.add.rectangle(x + width / 2, y, width, height, color, 0.18)
      .setStrokeStyle(3, border, 0.32)
      .setDepth(3);
    const runner = this.add.graphics().setDepth(4);
    runner.fillStyle(border, 0.12);
    for (let row = y - height / 2 + 26; row < y + height / 2; row += 72) {
      runner.fillRect(x + 10, row, width - 20, 6);
    }
  }

  private drawPlant(x: number, y: number, scale: number): void {
    const pot = this.add.rectangle(0, 18, 32, 30, 0x8a5d3d).setStrokeStyle(3, 0x432e23);
    const stem = this.add.rectangle(0, -5, 5, 30, 0x315f45);
    const leaves = [
      this.add.ellipse(-12, -13, 24, 12, 0x477c55).setAngle(28),
      this.add.ellipse(12, -18, 24, 12, 0x5b8b5e).setAngle(-28),
      this.add.ellipse(-9, -30, 20, 11, 0x3f704d).setAngle(55),
      this.add.ellipse(9, -35, 20, 11, 0x6a965f).setAngle(-55)
    ];
    this.add.container(x, y, [pot, stem, ...leaves]).setScale(scale).setDepth(y + 45);
  }

  private addFurniture(x: number, y: number, width: number, height: number, color: number, stroke: number): void {
    const furniture = this.add.rectangle(x, y, width, height, color).setStrokeStyle(4, stroke).setDepth(y + 60);
    this.obstacles.add(furniture);
  }
}
