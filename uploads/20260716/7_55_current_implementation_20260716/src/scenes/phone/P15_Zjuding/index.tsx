import { useEffect, useMemo, useRef, useState, type ReactNode, type RefObject } from "react";
import libraryAvatarUrl from "../../../assets/ui/library_avatar.png";
import libraryRoomEastUrl from "../../../assets/ui/library_room_east.png";
import libraryRoomNorthUrl from "../../../assets/ui/library_room_north.png";
import libraryRoomSouthUrl from "../../../assets/ui/library_room_south.png";
import threeMinuteLeaveMethodUrl from "../../../assets/phone/library-search/runtime/three_minute_leave_method.webp";
import threeMinuteLeaveArtUrl from "../../../assets/phone/library-search/runtime/three_minute_leave_art.webp";
import threeMinutePauseApplicationUrl from "../../../assets/phone/library-search/runtime/three_minute_pause_application.webp";
import threeMinuteRiseBoundariesUrl from "../../../assets/phone/library-search/runtime/three_minute_rise_boundaries.webp";
import threeMinuteEmptySeatUrl from "../../../assets/phone/library-search/runtime/three_minute_empty_seat.webp";
import zjudingHomeUrl from "../../../assets/ui/zjuding_home.png";
import zjudingLoadingUrl from "../../../assets/ui/zjuding_loading.png";
import { PhoneNavButton } from "../../../components/PhoneNavButton";
import { ItemInspectDialog } from "../../../components/ItemInspectDialog";
import type { SceneComponentProps } from "../../../components/ScenePlaceholder";
import type { ItemId, LibraryRecoveryEvidenceId, ZjudingPage } from "../../../core/types";
import { sanitizeZjudingPage, selectFeatureAccess } from "../../../core/FeatureAccess";
import actOneContent from "../../../data/act-one-bootstrap.content.json";
import libraryFinalsContent from "../../../data/library-finals.content.json";
import { kit } from "../../../modules/GameKit";
import { isCatalogClueQuery, normalizeCatalogQuery } from "../../../modules/library-finals/puzzleRules";
import { playSfx } from "../../../modules/Sfx";

const LOAD_DELAY_MS = 1500;
const STUCK_HINT_MS = 3000;

type OverlayState =
  | { kind: "search" }
  | { kind: "actions"; title: string; actions: string[] }
  | { kind: "libraries" }
  | { kind: "date" }
  | { kind: "time" }
  | { kind: "filter" }
  | { kind: "confirm" }
  | null;

type SystemDialogueKind = "inventory" | "inventory_ready" | "departure";

interface SystemDialogueLine {
  speaker: "system" | "player";
  text: string;
  cue?: string;
}

const SYSTEM_DIALOGUES: Record<SystemDialogueKind, SystemDialogueLine[]> = {
  inventory: [
    { speaker: "system", text: actOneContent.audioNarration.act2_system_found_intro.subtitleZh, cue: "act2_system_found_intro" },
    { speaker: "player", text: "拜托了，帮我改一下签到记录" },
    { speaker: "system", text: actOneContent.audioNarration.act2_system_inventory_demand.subtitleZh, cue: "act2_system_inventory_demand" },
    { speaker: "system", text: actOneContent.audioNarration.act2_system_inventory_missing.subtitleZh, cue: "act2_system_inventory_missing" },
    { speaker: "system", text: actOneContent.audioNarration.act2_system_just_find_it.subtitleZh, cue: "act2_system_just_find_it" }
  ],
  inventory_ready: [
    { speaker: "system", text: actOneContent.audioNarration.act2_system_found_intro.subtitleZh, cue: "act2_system_found_intro" },
    { speaker: "player", text: "拜托了，帮我改一下签到记录" },
    { speaker: "system", text: actOneContent.audioNarration.act2_system_inventory_demand.subtitleZh, cue: "act2_system_inventory_demand" },
    { speaker: "system", text: actOneContent.audioNarration.act2_system_departure.subtitleZh, cue: "act2_system_departure" },
    { speaker: "player", text: "？" },
    { speaker: "system", text: actOneContent.audioNarration.act2_system_confession.subtitleZh, cue: "act2_system_confession" },
    { speaker: "system", text: actOneContent.audioNarration.act2_system_friend.subtitleZh, cue: "act2_system_friend" },
    { speaker: "system", text: actOneContent.audioNarration.act2_system_library.subtitleZh, cue: "act2_system_library" },
    { speaker: "system", text: actOneContent.audioNarration.act2_system_move_now.subtitleZh, cue: "act2_system_move_now" }
  ],
  departure: [
    { speaker: "system", text: actOneContent.audioNarration.act2_system_departure.subtitleZh, cue: "act2_system_departure" },
    { speaker: "player", text: "？" },
    { speaker: "system", text: actOneContent.audioNarration.act2_system_confession.subtitleZh, cue: "act2_system_confession" },
    { speaker: "system", text: actOneContent.audioNarration.act2_system_friend.subtitleZh, cue: "act2_system_friend" },
    { speaker: "system", text: actOneContent.audioNarration.act2_system_library.subtitleZh, cue: "act2_system_library" },
    { speaker: "system", text: actOneContent.audioNarration.act2_system_move_now.subtitleZh, cue: "act2_system_move_now" }
  ]
};

interface HubApp {
  label: string;
  icon: string;
  tone: string;
  page?: ZjudingPage;
  badge?: string;
}

interface LibraryApp {
  label: string;
  icon: string;
  opensSpaces?: boolean;
  page?: ZjudingPage;
}

interface CatalogResult {
  id: string;
  title: string;
  author: string;
  callNumber: string;
  year: string;
  publisher: string;
  location: string;
  note: string;
  imageUrl: string;
}

interface RoomData {
  label: string;
  floor: string;
  seats: number;
  available: number;
  imageUrl: string;
}

const HUB_APPS: HubApp[] = [
  { label: "学在浙大", icon: "学", tone: "paper", page: "learn" },
  { label: "智云课堂", icon: "云", tone: "violet" },
  { label: "校园地图", icon: "位", tone: "sky" },
  { label: "网络缴费", icon: "¥", tone: "aqua" },
  { label: "后勤服务", icon: "勤", tone: "orange" },
  { label: "失物招领", icon: "寻", tone: "green" },
  { label: "访客预约", icon: "访", tone: "cyan" },
  { label: "图书馆", icon: "图", tone: "navy", page: "library" },
  { label: "慧学外语", icon: "F", tone: "silver" },
  { label: "意见箱", icon: "信", tone: "blue", badge: "新" },
  { label: "全部", icon: "▦", tone: "grid" }
];

const LIBRARY_APPS: LibraryApp[] = [
  { label: "馆藏检索", icon: "⌕", page: "library_catalog" },
  { label: "借阅信息", icon: "阅" },
  { label: "座位预约", icon: "24", opensSpaces: true },
  { label: "空间预约", icon: "⌂", opensSpaces: true },
  { label: "求是荐书", icon: "荐" },
  { label: "新书通报", icon: "新" },
  { label: "查收查引", icon: "引" },
  { label: "图书馆缴费", icon: "¥" }
];

const HUB_BOTTOM_ITEMS = [
  { label: "首页", icon: "⌂" },
  { label: "通讯录", icon: "◉" },
  { label: "工作台", icon: "▦" },
  { label: "消息", icon: "✦" },
  { label: "我的", icon: "◎" }
] as const;

const LIBRARY_BOTTOM_ITEMS = [
  { label: "首页", icon: "⌂" },
  { label: "我的", icon: "◎" }
] as const;

const CATALOG_COVER_URLS: Record<string, string> = {
  correct: threeMinuteLeaveMethodUrl,
  "distractor-1": threeMinuteLeaveArtUrl,
  "distractor-2": threeMinutePauseApplicationUrl,
  "distractor-3": threeMinuteRiseBoundariesUrl,
  "distractor-4": threeMinuteEmptySeatUrl
};

const CATALOG_RESULTS: CatalogResult[] = libraryFinalsContent.library.catalogResults.map((result) => {
  return {
    id: result.id,
    title: result.title,
    author: result.author,
    callNumber: result.callNumber,
    year: result.year,
    publisher: result.publisher,
    location: result.location,
    note: result.note,
    imageUrl: CATALOG_COVER_URLS[result.cover] ?? threeMinuteEmptySeatUrl
  };
});

function findCatalogResults(query: string): CatalogResult[] {
  const normalized = normalizeCatalogQuery(query);
  if (!normalized) {
    return [];
  }
  const clueQuery = normalizeCatalogQuery(libraryFinalsContent.library.catalogQuery);
  if (normalized.length >= 3 && (clueQuery.startsWith(normalized) || normalized.startsWith(clueQuery))) {
    return CATALOG_RESULTS;
  }
  return CATALOG_RESULTS.filter((result) => {
    return [result.title, result.author, result.callNumber, result.publisher, result.location]
      .some((value) => normalizeCatalogQuery(value).includes(normalized));
  });
}

const RECOVERY_EVIDENCE: Array<{
  id: LibraryRecoveryEvidenceId;
  label: string;
  item: "bagNonPersonProof" | "seat022Receipt" | "libraryPresenceProof";
  source: string;
  nextStep: string;
}> = [
  {
    id: "bag_non_person_proof",
    label: "书包非本人证明",
    item: "bagNonPersonProof",
    source: "失物招领 · 身份登记机",
    nextStep: "先生成物品识别报告，再到馆内登记机盖章"
  },
  {
    id: "seat_022_receipt",
    label: "022 座位小票",
    item: "seat022Receipt",
    source: "二层南区 · 022 桌面夹缝",
    nextStep: "回到 022，检查桌面与座椅之间的夹缝"
  },
  {
    id: "library_presence_proof",
    label: "本人来过证明",
    item: "libraryPresenceProof",
    source: "浙大体艺 · 到馆记录补录",
    nextStep: "用三份来源记录完成体艺补录"
  }
];

const ROOMS: RoomData[] = [
  { label: "二层南", floor: "二层", seats: 32, available: 32, imageUrl: libraryRoomSouthUrl },
  { label: "二层北", floor: "二层", seats: 176, available: 171, imageUrl: libraryRoomNorthUrl },
  { label: "三层东", floor: "三层", seats: 48, available: 47, imageUrl: libraryRoomEastUrl },
  { label: "三层南", floor: "三层", seats: 112, available: 112, imageUrl: libraryRoomSouthUrl }
];

const SEAT_TABLES = [
  { leftStart: 29, rightStart: 25 },
  { leftStart: 21, rightStart: 17 },
  { leftStart: 13, rightStart: 9 },
  { leftStart: 5, rightStart: 1 }
] as const;

const SEAT_LIST_IDS = SEAT_TABLES.flatMap(({ leftStart, rightStart }) =>
  Array.from({ length: 4 }, (_, index) => [leftStart + index, rightStart + index])
    .flat()
    .map((seat) => String(seat).padStart(3, "0"))
).sort();

function PixelAppIcon({ symbol, tone, badge }: { symbol: string; tone: string; badge?: string }) {
  return (
    <span className={`zju-pixel-icon tone-${tone}`} aria-hidden="true">
      <i>{symbol}</i>
      {badge ? <b>{badge}</b> : null}
    </span>
  );
}

function NativeHeader({ title, onBack, onMore }: { title: string; onBack: () => void; onMore?: () => void }) {
  return (
    <header className="zju-native-header" data-ui-part="app-header">
      <PhoneNavButton kind="back" className="zju-native-back" label={`返回，离开${title}`} onClick={onBack} />
      <h1>{title}</h1>
      {onMore ? (
        <button type="button" className="zju-native-more" aria-label={`${title}更多菜单`} onClick={onMore}>
          <span aria-hidden="true">•••</span>
        </button>
      ) : <span className="zju-native-more zju-locked-control-icon" aria-hidden="true">•••</span>}
    </header>
  );
}

function BottomNav({
  items,
  active,
  onSelect
}: {
  items: Array<{ label: string; icon: string }>;
  active: string;
  onSelect: (label: string) => void;
}) {
  return (
    <nav className="zju-native-bottom-nav" aria-label="页面导航" data-ui-part="bottom-navigation">
      {items.map((item) => (
        <button
          key={item.label}
          type="button"
          className={item.label === active ? "is-active" : ""}
          aria-current={item.label === active ? "page" : undefined}
          onClick={() => onSelect(item.label)}
        >
          <span aria-hidden="true">{item.icon}</span>
          {item.label}
        </button>
      ))}
    </nav>
  );
}

function ActionSheet({ title, onClose, children }: { title: string; onClose: () => void; children: ReactNode }) {
  const dialogRef = useRef<HTMLElement>(null);
  const onCloseRef = useRef(onClose);
  onCloseRef.current = onClose;

  useEffect(() => {
    const previouslyFocused = document.activeElement instanceof HTMLElement ? document.activeElement : null;
    const dialog = dialogRef.current;
    const focusableSelector = "button:not([disabled]), input:not([disabled]), [tabindex]:not([tabindex='-1'])";
    const autofocusTarget = dialog?.querySelector<HTMLElement>("[autofocus]");
    const firstFocusable = dialog?.querySelector<HTMLElement>(focusableSelector);
    (autofocusTarget ?? firstFocusable ?? dialog)?.focus();

    function handleKeyDown(event: KeyboardEvent) {
      if (event.key === "Escape") {
        event.preventDefault();
        onCloseRef.current();
        return;
      }
      if (event.key !== "Tab" || !dialog) {
        return;
      }
      const focusable = Array.from(dialog.querySelectorAll<HTMLElement>(focusableSelector));
      const first = focusable[0];
      const last = focusable[focusable.length - 1];
      if (!first || !last) {
        event.preventDefault();
        return;
      }
      if (event.shiftKey && document.activeElement === first) {
        event.preventDefault();
        last.focus();
      } else if (!event.shiftKey && document.activeElement === last) {
        event.preventDefault();
        first.focus();
      }
    }

    document.addEventListener("keydown", handleKeyDown);
    return () => {
      document.removeEventListener("keydown", handleKeyDown);
      previouslyFocused?.focus();
    };
  }, []);

  return (
    <div className="zju-sheet-layer" role="presentation" onPointerDown={onClose}>
      <section
        ref={dialogRef}
        className="zju-sheet"
        role="dialog"
        aria-modal="true"
        aria-label={title}
        tabIndex={-1}
        onPointerDown={(event) => event.stopPropagation()}
      >
        <header>
          <h2>{title}</h2>
          <button type="button" aria-label={`关闭${title}`} onClick={onClose}>
            ×
          </button>
        </header>
        {children}
      </section>
    </div>
  );
}

function SeatMap({
  selectedSeat,
  lost,
  restored,
  dropReady,
  targetSeatRef,
  onSelect
}: {
  selectedSeat: string | null;
  lost: boolean;
  restored: boolean;
  dropReady: boolean;
  targetSeatRef: RefObject<HTMLButtonElement>;
  onSelect: (seat: string) => void;
}) {
  return (
    <section className={`zju-seat-map ${dropReady ? "is-pass-drop-ready" : ""} ${restored ? "is-seat-restored" : ""}`.trim()} aria-label="可选座位地图" data-ui-part="seat-map">
      <div className="zju-seat-tables">
        {SEAT_TABLES.map((table, tableIndex) => (
          <div className="zju-seat-table" key={`${table.leftStart}-${table.rightStart}`}>
            <div className="zju-seat-edge-label top" aria-hidden="true">
              {tableIndex === 1 ? `${String(table.leftStart).padStart(3, "0")}  ${String(table.rightStart).padStart(3, "0")}` : ""}
            </div>
            {Array.from({ length: 4 }, (_, rowIndex) => {
              const leftSeat = String(table.leftStart + rowIndex).padStart(3, "0");
              const rightSeat = String(table.rightStart + rowIndex).padStart(3, "0");
              return (
                <div className="zju-seat-row" key={leftSeat}>
                  <button
                    ref={leftSeat === "022" ? targetSeatRef : undefined}
                    type="button"
                    className={`${selectedSeat === leftSeat ? "is-selected" : ""} ${selectedSeat === leftSeat && lost ? "is-lost" : ""}`.trim()}
                    aria-label={`选择座位${leftSeat}`}
                    data-seat={leftSeat}
                    onClick={() => onSelect(leftSeat)}
                  >
                    <i aria-hidden="true" />
                  </button>
                  <span className="zju-seat-desk" aria-hidden="true" />
                  <button
                    ref={rightSeat === "022" ? targetSeatRef : undefined}
                    type="button"
                    className={`${selectedSeat === rightSeat ? "is-selected" : ""} ${selectedSeat === rightSeat && lost ? "is-lost" : ""}`.trim()}
                    aria-label={`选择座位${rightSeat}`}
                    data-seat={rightSeat}
                    onClick={() => onSelect(rightSeat)}
                  >
                    <i aria-hidden="true" />
                  </button>
                </div>
              );
            })}
            <div className="zju-seat-edge-label bottom" aria-hidden="true">
              {tableIndex === 1
                ? `${String(table.leftStart + 3).padStart(3, "0")}  ${String(table.rightStart + 3).padStart(3, "0")}`
                : ""}
            </div>
          </div>
        ))}
      </div>
      <span className="zju-seat-north" aria-label="北向">
        N<i />
      </span>
      <div className="zju-seat-legend" aria-label="座位状态图例">
        {[
          ["available", "空闲中", "Available"],
          ["reserved", "已预约", "Reserved"],
          ["occupied", "使用中", "Occupied"],
          ["suspending", "暂停中", "Suspending"],
          ["unavailable", "不可用", "Unavailable"]
        ].map(([tone, label, english]) => (
          <span key={tone}>
            <i className={tone} aria-hidden="true" />
            <b>{label}</b>
            <small>{english}</small>
          </span>
        ))}
        <strong>
          请点击白色座位选座
          <small>Please select a seat available</small>
        </strong>
      </div>
    </section>
  );
}

/** 浙大钉与图书馆：统一使用 430×860 手机画布，新增页面均由原生 React/CSS 组成。 */
export function ZjudingScene({ state, router, events }: SceneComponentProps) {
  const [phase, setPhase] = useState<"loading" | "ready">("loading");
  const [stuckHint, setStuckHint] = useState(false);
  const [overlay, setOverlay] = useState<OverlayState>(null);
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedLibrary, setSelectedLibrary] = useState("请选择馆舍");
  const [selectedRoom, setSelectedRoom] = useState("二层南");
  const [selectedDate, setSelectedDate] = useState("07月10日 · 今天");
  const [selectedTime, setSelectedTime] = useState("00:01 - 23:59");
  const [seatView, setSeatView] = useState<"map" | "list">("map");
  const [spaceMode, setSpaceMode] = useState<"list" | "quick">("list");
  const [railCollapsed, setRailCollapsed] = useState(false);
  const [directoryName, setDirectoryName] = useState(() => state.actOne.characterNamed ? actOneContent.studentName : "");
  const [directoryStudentId, setDirectoryStudentId] = useState(() => state.actOne.characterNamed ? actOneContent.studentId : "");
  const [directoryCardStatus, setDirectoryCardStatus] = useState<"idle" | "scanning" | "read">(
    () => state.actOne.characterNamed ? "read" : "idle"
  );
  const [directoryHintStep, setDirectoryHintStep] = useState(0);
  const [systemDialogue, setSystemDialogue] = useState<SystemDialogueKind | null>(null);
  const [systemDialogueIndex, setSystemDialogueIndex] = useState(0);
  const [catalogQuery, setCatalogQuery] = useState("");
  const [catalogSubmitted, setCatalogSubmitted] = useState(false);
  const [catalogSubmittedQuery, setCatalogSubmittedQuery] = useState("");
  const [catalogAdvanced, setCatalogAdvanced] = useState(false);
  const [catalogFeedback, setCatalogFeedback] = useState("");
  const [catalogSelectedId, setCatalogSelectedId] = useState<string | null>(null);
  const [recoveryFeedback, setRecoveryFeedback] = useState("");
  const [submittedDocument, setSubmittedDocument] = useState<ItemId | null>(null);
  const [draggedRecoveryItem, setDraggedRecoveryItem] = useState("");
  const seatDropTargetRef = useRef<HTMLButtonElement>(null);
  const directoryScanTimerRef = useRef<number | null>(null);
  const onCampusWifi = state.networkMode === "campus_wifi";
  const finalsPhase = state.ui.libraryFinalsPhase;
  const finalsPuzzle = state.ui.libraryFinalsPuzzle;
  const access = selectFeatureAccess(state);
  const recoveryUnlocked = access.libraryRecovery;
  const currentPage = sanitizeZjudingPage(state);
  const actOnePhase = state.actOne.phase;
  const movementQuestActive = actOnePhase === "movement_required" || actOnePhase === "movement_ready";
  const visibleCatalogResults = useMemo(() => {
    if (catalogSubmitted) {
      return findCatalogResults(catalogSubmittedQuery);
    }
    return finalsPuzzle.catalogSearchCompleted ? CATALOG_RESULTS : [];
  }, [catalogSubmitted, catalogSubmittedQuery, finalsPuzzle.catalogSearchCompleted]);

  useEffect(() => {
    if (phase !== "loading") {
      return undefined;
    }

    if (onCampusWifi) {
      const timer = window.setTimeout(() => setPhase("ready"), LOAD_DELAY_MS);
      return () => window.clearTimeout(timer);
    }

    const timer = window.setTimeout(() => {
      setStuckHint(true);
      kit.flags.toast("请连接校园网。", "system");
    }, STUCK_HINT_MS);
    return () => window.clearTimeout(timer);
  }, [phase, onCampusWifi]);

  function scanDirectoryCampusCard() {
    if (!state.items.campusCard) {
      kit.flags.toast("读卡器没有读到有效证件。", "system");
      return;
    }
    if (directoryScanTimerRef.current !== null) {
      return;
    }
    setDirectoryCardStatus("scanning");
    playSfx("01_");
    directoryScanTimerRef.current = window.setTimeout(() => {
      setDirectoryName(actOneContent.studentName);
      setDirectoryStudentId(actOneContent.studentId);
      setDirectoryCardStatus("read");
      directoryScanTimerRef.current = null;
      events.emit("act2_directory_card_scanned", {
        name: actOneContent.studentName,
        studentId: actOneContent.studentId
      });
      kit.flags.setUi("selectedItem", null);
      kit.flags.toast("证件信息已读入。黄页还在等你主动呼叫。", "task");
    }, 650);
  }

  useEffect(() => {
    const unsubscribe = events.subscribe((event) => {
      if (event.name !== "item_dropped" || event.payload?.target !== "directory_identity") {
        return;
      }
      if (event.payload?.item !== "campusCard") {
        playSfx("04_", { volume: 0.5 });
        kit.flags.toast("读卡区只认校园身份凭证。这件道具没有姓名和学号。", "system");
        return;
      }
      scanDirectoryCampusCard();
    });
    return () => {
      unsubscribe();
      if (directoryScanTimerRef.current !== null) {
        window.clearTimeout(directoryScanTimerRef.current);
        directoryScanTimerRef.current = null;
      }
    };
  }, [events, state.items.campusCard]);

  useEffect(() => events.subscribe((event) => {
    if (event.name === "inventory_drag_started") {
      setDraggedRecoveryItem(String(event.payload?.itemId ?? ""));
      return;
    }
    if (event.name === "inventory_drag_ended") {
      setDraggedRecoveryItem("");
      return;
    }
    if (event.name !== "item_dropped") return;
    const target = String(event.payload?.target ?? "");
    if (!target.startsWith("recovery-upload:")) return;
    const evidenceId = target.slice("recovery-upload:".length) as LibraryRecoveryEvidenceId;
    const expectedItem: Record<LibraryRecoveryEvidenceId, ItemId> = {
      bag_non_person_proof: "bagNonPersonProof",
      seat_022_receipt: "seat022Receipt",
      library_presence_proof: "libraryPresenceProof"
    };
    if (!(evidenceId in expectedItem) || expectedItem[evidenceId] !== event.payload?.item) {
      setRecoveryFeedback("这个槽位需要对应名称的恢复证明。");
      return;
    }
    uploadRecoveryEvidence(evidenceId);
  }), [events]);

  useEffect(() => {
    if (!state.actOne.characterNamed) {
      return;
    }
    setDirectoryName(actOneContent.studentName);
    setDirectoryStudentId(actOneContent.studentId);
    setDirectoryCardStatus("read");
  }, [state.actOne.characterNamed]);

  const searchResults = useMemo(() => {
    const query = searchQuery.trim();
    if (!query) {
      return HUB_APPS.slice(0, 6);
    }
    return HUB_APPS.filter((app) => app.label.includes(query));
  }, [searchQuery]);

  function announce(text: string) {
    playSfx("02_");
    kit.flags.toast(text, "system");
  }

  function goPage(page: ZjudingPage) {
    playSfx("02_");
    setOverlay(null);
    kit.flags.setUi("zjudingPage", sanitizeZjudingPage(state, page));
  }

  function goBack() {
    const previous: Partial<Record<ZjudingPage, ZjudingPage>> = {
      login: "hub",
      directory: "hub",
      learn: "hub",
      library: "hub",
      library_spaces: "library",
      library_seat: "library_spaces",
      library_catalog: "library",
      library_recovery: "library"
    };
    const page = previous[currentPage];
    if (page) {
      goPage(page);
      return;
    }
    router.goTo("phone_home");
  }

  function openApp(label: string, page?: ZjudingPage) {
    if (label === "校园地图") {
      openCampusMap();
      return;
    }
    if (page) {
      goPage(page);
      return;
    }
    return;
  }

  function openCampusMap() {
    playSfx("01_");
    setOverlay(null);
    const libraryActive = finalsPhase !== "idle" && finalsPhase !== "library_route_unlocked";
    const scene = libraryActive ? state.rpgScene : actOnePhase === "complete" ? "campus_bootstrap" : "dorm_hub";
    if (!kit.actOne.enterRpg(scene)) {
      kit.flags.toast("校园地图还没有响应你的进入请求。", "system");
    }
  }

  function emitSystemCue(line: SystemDialogueLine) {
    if (line.cue) {
      events.emit(line.cue);
    }
  }

  function openSystemDialogue() {
    let kind: SystemDialogueKind | null = null;
    if (actOnePhase === "system_required") {
      kind = state.items.campusCard && state.actOne.inventoryRecovered ? "inventory_ready" : "inventory";
    } else if (actOnePhase === "system_return_required") {
      kind = "departure";
    } else if (actOnePhase === "inventory_required") {
      kit.flags.toast("它看了看你的空手，又缩回了红圈里。", "system");
      return;
    }
    if (!kind) {
      announce("求是印章没有回应。");
      return;
    }
    setSystemDialogue(kind);
    setSystemDialogueIndex(0);
    emitSystemCue(SYSTEM_DIALOGUES[kind][0]);
  }

  function advanceSystemDialogue() {
    if (!systemDialogue) {
      return;
    }
    const lines = SYSTEM_DIALOGUES[systemDialogue];
    const nextIndex = systemDialogueIndex + 1;
    if (nextIndex < lines.length) {
      setSystemDialogueIndex(nextIndex);
      emitSystemCue(lines[nextIndex]);
      return;
    }
    if (systemDialogue === "inventory") {
      kit.actOne.confrontSystem();
      kit.flags.toast("任务更新：找到道具栏", "task");
    } else if (systemDialogue === "inventory_ready") {
      kit.actOne.confrontSystem();
      kit.actOne.startMovementQuest();
      kit.flags.toast("任务更新：找到移动的办法", "task");
    } else {
      kit.actOne.startMovementQuest();
      kit.flags.toast("任务更新：找到移动的办法", "task");
    }
    setSystemDialogue(null);
    setSystemDialogueIndex(0);
  }

  function openCampusCard() {
    playSfx("02_");
    if (!state.items.campusCard) {
      kit.flags.toast("校园卡还在寝室右侧书桌上。先打开校园地图。", "task");
      return;
    }
    kit.flags.setUi("zjudingPage", "hub");
    router.goTo("campus_card");
  }

  function submitDirectoryIdentity() {
    if (kit.actOne.identifyCharacter(directoryName, directoryStudentId)) {
      kit.flags.toast("黄页联络成功：寝室人物已显示姓名。", "task");
      goPage("hub");
      return;
    }
    playSfx("03_");
    kit.flags.toast("姓名或学号不匹配。校园卡上写着完整信息。", "system");
  }

  function inspectDirectoryCardReader() {
    if (directoryCardStatus === "scanning") {
      kit.flags.toast("读卡器正在逐字识别。", "system");
      return;
    }
    if (directoryCardStatus === "read") {
      kit.flags.toast("姓名和学号已经读入。现在只差拨出这通电话。", "system");
      return;
    }
    if (state.ui.selectedItem === "campusCard") {
      scanDirectoryCampusCard();
      return;
    }
    const hints = [
      "黄页要核对两个字段：姓名和 10 位编号。",
      "这两个字段印在同一张校园身份凭证上。",
      "在物品栏选中电子校园卡，再点击读卡区；也可以直接拖过来。"
    ];
    const hintIndex = Math.min(directoryHintStep, hints.length - 1);
    kit.flags.toast(hints[hintIndex], "system");
    events.emit("act2_directory_hint_advanced", { step: hintIndex + 1 });
    setDirectoryHintStep((current) => Math.min(current + 1, hints.length - 1));
  }

  function enterRoom(room: string) {
    setSelectedRoom(room);
    kit.flags.setUi("librarySelectedSeat", null);
    kit.flags.setUi("librarySeatReserved", false);
    goPage("library_seat");
  }

  function selectSeat(seat: string) {
    if (finalsPhase !== "idle") {
      announce("本章的 022 状态由图书馆现场记录管理。");
      return;
    }
    if (state.ui.librarySeatReserved) {
      kit.flags.setUi("librarySeatReserved", false);
    }
    kit.flags.setUi("librarySelectedSeat", seat);
    playSfx("01_");
  }

  function requestReservation() {
    if (!state.ui.librarySelectedSeat) {
      announce("请先选择一个白色座位。");
      return;
    }
    if (state.ui.librarySeatReserved) {
      announce(`座位 ${state.ui.librarySelectedSeat} 已预约。`);
      return;
    }
    setOverlay({ kind: "confirm" });
  }

  function confirmReservation() {
    kit.flags.setUi("librarySeatReserved", true);
    setOverlay(null);
    playSfx("01_");
    kit.flags.toast(`预约成功：${selectedRoom} ${state.ui.librarySelectedSeat} 号座位。`, "task");
  }

  function submitCatalogSearch() {
    setCatalogFeedback("");
    const query = catalogQuery.trim();
    if (!query) {
      setCatalogSubmitted(false);
      setCatalogSubmittedQuery("");
      setCatalogFeedback("请输入书名、作者或索书号。");
      return;
    }
    const results = findCatalogResults(query);
    setCatalogSubmitted(true);
    setCatalogSubmittedQuery(query);
    setCatalogSelectedId(null);
    if (results.length === 0) {
      setCatalogFeedback(`没有找到与“${query}”相符的馆藏。`);
      return;
    }
    if (!isCatalogClueQuery(query)) {
      setCatalogFeedback(`检索完成：找到 ${results.length} 本馆藏。`);
      return;
    }
    const clueSynchronized = finalsPuzzle.catalogSearchCompleted || kit.libraryFinals.searchCatalog(query);
    setCatalogFeedback(clueSynchronized
      ? `检索完成：找到 ${results.length} 本相似馆藏，请核对题名与索书号。`
      : `检索完成：找到 ${results.length} 本相似馆藏。调查帖中的题名提示尚未同步。`);
  }

  function chooseCatalogResult(result: CatalogResult) {
    if (result.id === "three-minute-leave-method" && finalsPuzzle.callNumberCollected) {
      setCatalogSelectedId(result.id);
      setCatalogFeedback(`已获得线索：索书号 ${result.callNumber}。`);
      return;
    }
    if (!kit.libraryFinals.selectCatalogResult(result.id)) {
      if (result.id === "three-minute-leave-method") {
        setCatalogSelectedId(null);
        setCatalogFeedback("这本书可能相关，但调查帖中的题名提示还没有完成核对。");
      } else {
        setCatalogSelectedId(result.id);
        setCatalogFeedback(`${result.title}的索书号和 022 没有可核对的关系。`);
      }
      return;
    }
    setCatalogSelectedId(result.id);
    setCatalogFeedback(`已获得线索：索书号 ${result.callNumber}。`);
  }

  function openRecoveryPage() {
    setRecoveryFeedback("");
    if (finalsPhase === "top_ten_reached" && !kit.libraryFinals.openRecoveryApplication()) {
      setRecoveryFeedback("十大排名还没有被图书馆系统同步。");
      return;
    }
    if (!recoveryUnlocked) {
      setRecoveryFeedback("恢复申请只在帖子进入十大第一后开放。");
      return;
    }
    goPage("library_recovery");
  }

  function uploadRecoveryEvidence(evidenceId: LibraryRecoveryEvidenceId) {
    setRecoveryFeedback("");
    if (!kit.libraryFinals.uploadRecoveryEvidence(evidenceId)) {
      setRecoveryFeedback("该证明还未获得、已提交，或当前申请尚未开放。");
    }
  }

  function generateEvictionPass() {
    setRecoveryFeedback("");
    if (!kit.libraryFinals.generateEvictionPass()) {
      setRecoveryFeedback("三项恢复材料尚未齐全。");
    }
  }

  if (phase === "loading") {
    return (
      <section className="app-screen zjuding-loading" aria-label="浙大钉加载中">
        <div className="app-bg-crop zjuding-loading-crop">
          <img className="app-bg" src={zjudingLoadingUrl} alt="" aria-hidden="true" />
        </div>
        {!onCampusWifi ? (
          <div className="zjuding-stuck">
            <span className="loading-dots" aria-hidden="true">
              <i />
              <i />
              <i />
            </span>
            {stuckHint ? <p className="px-chip stuck-chip">转啊转啊转……（请连接校园网）</p> : null}
          </div>
        ) : null}
        <button type="button" className="app-exit px-btn paper" onClick={() => router.goTo("phone_home")}>
          退出
        </button>
      </section>
    );
  }

  let page: JSX.Element;

  if (currentPage === "login") {
    page = (
      <section className="app-screen zju-native-page zju-login-page" aria-label="浙江大学统一身份认证">
        <NativeHeader
          title="统一身份认证"
          onBack={goBack}
          onMore={() => setOverlay({ kind: "actions", title: "登录帮助", actions: ["找回账号", "安全提示"] })}
        />
        <main className="zju-login-content">
          <div className="zju-login-mark" aria-hidden="true">ZJU</div>
          <h2>校园身份信息</h2>
          <p>旧登录入口已合并到电子校园卡。</p>
          <section className="zju-login-form">
            <label>
              <span>姓名</span>
              <strong>{actOneContent.studentName}</strong>
            </label>
            <label>
              <span>学号</span>
              <strong>{actOneContent.studentId}</strong>
            </label>
            <button type="button" className="primary" onClick={() => goPage("directory")}>
              前往部门黄页
            </button>
          </section>
        </main>
      </section>
    );
  } else if (currentPage === "directory") {
    page = (
      <section className="app-screen zju-native-page zju-directory-page" aria-label="浙大钉部门黄页">
        <NativeHeader
          title="部门黄页"
          onBack={goBack}
          onMore={() => setOverlay({ kind: "actions", title: "黄页菜单", actions: ["最近通话", "收藏号码"] })}
        />
        <main className="zju-directory-content">
          <section className="zju-directory-contacts" aria-label="部门联系人">
            {actOneContent.departments.map((department) => (
              <article key={department.id}>
                <span aria-hidden="true">☎</span>
                <div><strong>{department.label}</strong><small>{department.id === "game_support" ? "3250••••55" : department.phone}</small></div>
              </article>
            ))}
          </section>
          <section className="zju-directory-identity" aria-label="联络寝室人物">
            <div
              className={`zju-directory-card-reader is-${directoryCardStatus}`}
              data-drop-target="directory_identity"
              role="button"
              tabIndex={0}
              aria-label="校园卡读卡区"
              onClick={inspectDirectoryCardReader}
              onKeyDown={(event) => {
                if (event.key === "Enter" || event.key === " ") {
                  event.preventDefault();
                  inspectDirectoryCardReader();
                }
              }}
            >
              <span className="zju-directory-card-chip" aria-hidden="true"><i /></span>
              <div>
                <strong>{directoryCardStatus === "read" ? "电子校园卡已读取" : "校园身份读卡区"}</strong>
                <small>
                  {directoryCardStatus === "scanning"
                    ? "正在识别持卡人字段……"
                    : directoryCardStatus === "read"
                      ? "姓名与 10 位学号已填入"
                      : state.ui.selectedItem === "campusCard"
                        ? "校园卡已对准，点击读取"
                      : "点击查看提示，或将身份凭证放入此处"}
                </small>
              </div>
              <b aria-hidden="true">{directoryCardStatus === "read" ? "OK" : directoryCardStatus === "scanning" ? "···" : "?"}</b>
            </div>
            <header>
              <span aria-hidden="true">☎</span>
              <div><strong>联络未命名人物</strong><small>请输入校园卡上的完整身份</small></div>
            </header>
            <label>
              <span>姓名</span>
              <input
                value={directoryName}
                onChange={(event) => setDirectoryName(event.target.value)}
                placeholder="校园卡姓名"
                autoComplete="off"
              />
            </label>
            <label>
              <span>学号</span>
              <input
                inputMode="numeric"
                value={directoryStudentId}
                onChange={(event) => setDirectoryStudentId(event.target.value.replace(/\D/g, "").slice(0, actOneContent.studentId.length))}
                placeholder="10 位学号"
                autoComplete="off"
              />
            </label>
            <button type="button" className="zju-call-button" onClick={submitDirectoryIdentity}>
              {state.actOne.characterNamed ? `已联络：${actOneContent.studentName}` : "☎ 呼叫"}
            </button>
          </section>
        </main>
      </section>
    );
  } else if (currentPage === "learn") {
    page = (
      <section className="app-screen zjuding-home" aria-label="学在浙大">
        <div className="app-bg-crop zjuding-home-crop">
          <img className="app-bg" src={zjudingHomeUrl} alt="" aria-hidden="true" />
        </div>
        <button
          type="button"
          className="zjuding-checkin-hotspot"
          aria-label="校务签到"
          onClick={() => {
            playSfx("02_");
            router.goTo("checkin");
          }}
        />
        <PhoneNavButton kind="back" className="app-back px-btn paper" onClick={goBack} label="返回浙大钉" />
        <nav className="zjuding-nav" aria-label="学在浙大导航">
          <button type="button" className="zjuding-tab is-active" aria-current="page" onClick={() => announce("当前位于学在浙大。") }>
            <i className="tab-ico learn" aria-hidden="true" />
            学在浙大
          </button>
          <span className="zjuding-tab zju-locked-control-icon" data-locked-icon="learn-secondary" aria-hidden="true">
            <i className="tab-ico mine" />
          </span>
        </nav>
      </section>
    );
  } else if (currentPage === "library") {
    page = (
      <section className="app-screen zju-native-page zju-library-home" aria-label="浙大移动图书馆">
        <NativeHeader
          title="浙大移动图书馆"
          onBack={goBack}
        />
        <main className="zju-library-scroll">
          <section className="zju-library-hero" data-ui-part="reader-profile">
            <img src={libraryAvatarUrl} alt={`${actOneContent.studentName}读者头像`} />
            <div>
              <h2>{actOneContent.studentName}</h2>
              <p>{actOneContent.studentId} <span aria-hidden="true">▱</span></p>
            </div>
            <span className="zju-reader-activate zju-locked-control-icon" data-locked-icon="reader-activate" aria-hidden="true">✓</span>
            <span className="zju-reader-mail zju-locked-control-icon" data-locked-icon="reader-mail" aria-hidden="true">✉</span>
            <span className="zju-reader-faq zju-locked-control-icon" data-locked-icon="reader-help" aria-hidden="true">?</span>
            <div className="zju-library-landscape" aria-hidden="true">
              <i /><i /><i /><i /><i />
            </div>
          </section>

          <section className="zju-library-services" aria-label="图书馆服务" data-ui-part="service-grid">
            <button type="button" data-app-id="馆藏检索" onClick={() => goPage("library_catalog")}>
              <span aria-hidden="true">⌕</span>馆藏检索
            </button>
            {LIBRARY_APPS.slice(1).map((app) => (
              <span
                key={app.label}
                className="zju-static-app zju-locked-icon-slot"
                data-locked-app={app.label}
                aria-hidden="true"
              >
                <span className="zju-library-service-icon">{app.icon}</span>
                <span className="zju-locked-label">{app.label}</span>
              </span>
            ))}
            {recoveryUnlocked ? (
              <button type="button" data-app-id="022恢复申请" onClick={openRecoveryPage}>
                <span aria-hidden="true">PASS</span>022恢复申请
              </button>
            ) : (
              <span className="zju-static-app zju-locked-icon-slot" data-locked-app="022恢复申请" aria-hidden="true">
                <span className="zju-library-service-icon">PASS</span>
                <span className="zju-locked-label">022恢复申请</span>
              </span>
            )}
            <button type="button" data-app-id="返回现场" onClick={openCampusMap}>
              <span aria-hidden="true">↗</span>返回现场
            </button>
          </section>

          {finalsPhase === "top_ten_reached" ? (
            <button type="button" className="zju-library-recovery-alert" onClick={openRecoveryPage}>
              <strong>022 座位恢复申请已开放</strong>
              <span>帖子当前排名 01，可提交三项证明。</span>
              <b aria-hidden="true">›</b>
            </button>
          ) : null}

          {[
            {
              title: "活动日历",
              icon: "▣",
              rows: [["（活动报名）“我著·我...", "06-15"], ["（活动报名）书香浙大·开...", "06-12"]]
            },
            {
              title: "通知公告",
              icon: "▤",
              rows: [["图书馆数字资源校外访...", "2022-04-08"], ["关于新增校外数据库访...", "2022-03-28"]]
            },
            {
              title: "规章制度",
              icon: "▥",
              rows: [["图书馆座位预约管理规则", "查看"], ["读者文明使用空间须知", "查看"]]
            }
          ].map((panel) => (
            <section className="zju-library-info-card" key={panel.title} data-ui-part="information-card">
              <header><h3>xxx</h3><span>xxx</span></header>
              {panel.rows.map(([label, value]) => (
                <p key={label}><span>xxx</span><time>xxx</time></p>
              ))}
            </section>
          ))}
        </main>
        <nav className="zju-native-bottom-nav zju-bottom-static" aria-label="页面导航">
          {LIBRARY_BOTTOM_ITEMS.map((item) => (
            <span key={item.label} data-locked-icon={`library-${item.label}`} aria-hidden="true">
              <i>{item.icon}</i><small>{item.label}</small>
            </span>
          ))}
        </nav>
      </section>
    );
  } else if (currentPage === "library_catalog") {
    const resultsVisible = visibleCatalogResults.length > 0;
    page = (
      <section className="app-screen zju-native-page zju-catalog-page" aria-label="图书馆馆藏检索">
        <NativeHeader
          title="浙大移动图书馆"
          onBack={goBack}
        />
        <main className="zju-catalog-content">
          <nav className="zju-catalog-databases" aria-label="文献库选择">
            <button type="button" className="is-active">中文文献库</button>
            <span className="zju-static-xxx">xxx</span>
          </nav>

          <section className="zju-catalog-query-panel" aria-label="检索条件">
            <div className="zju-catalog-search">
            <label>
              <span aria-hidden="true">⌕</span>
              <input
                value={catalogQuery}
                onChange={(event) => setCatalogQuery(event.target.value)}
                onKeyDown={(event) => event.key === "Enter" && submitCatalogSearch()}
                placeholder="搜索文献"
                aria-label="馆藏检索关键词"
              />
            </label>
            <button type="button" className="zju-catalog-submit" onClick={submitCatalogSearch}>搜索</button>
            </div>
            <div className="zju-catalog-filter-row" aria-label="检索范围">
              <button type="button" className="zju-catalog-field"><small>检索字段</small><strong>书名</strong><span aria-hidden="true">▾</span></button>
              <button type="button" className="zju-catalog-scope"><small>馆藏范围</small><strong>全部馆藏</strong><span aria-hidden="true">▾</span></button>
            </div>
          </section>

          <div className="zju-catalog-tools">
            <button type="button" onClick={() => setCatalogAdvanced((value) => !value)}>
              {catalogAdvanced ? "收起高级检索" : "高级检索"}
            </button>
            <strong>检索到的书籍数：{visibleCatalogResults.length}</strong>
          </div>
          {catalogAdvanced ? (
            <section className="zju-catalog-advanced" aria-label="高级检索字段">
              <label>题名匹配<input readOnly value="包含全部关键词" /></label>
              <label>索书号分类<input readOnly value="全部分类" /></label>
              <label>馆藏地点<input readOnly value="基础图书馆" /></label>
            </section>
          ) : null}

          {catalogFeedback ? <p className="zju-catalog-feedback" aria-live="polite">{catalogFeedback}</p> : null}

          {resultsVisible ? (
            <section className="zju-catalog-results" aria-label="馆藏检索结果">
              <h2><i aria-hidden="true" /><span>检索结果</span><small>{visibleCatalogResults.length} 条</small></h2>
              {visibleCatalogResults.map((result) => {
                const correctSelected = result.id === "three-minute-leave-method" && (finalsPuzzle.callNumberCollected || catalogSelectedId === result.id);
                const wrongSelected = catalogSelectedId === result.id && result.id !== "three-minute-leave-method";
                return (
                  <article key={result.id} className={`${correctSelected ? "is-correct" : ""} ${wrongSelected ? "is-wrong" : ""}`.trim()}>
                    <button type="button" aria-label={`选择馆藏${result.title}`} onClick={() => chooseCatalogResult(result)}>
                      <img src={result.imageUrl} alt={`${result.title}封面`} />
                      <span className="zju-catalog-book-copy">
                        <strong>{result.title}</strong>
                        <small>著者：{result.author}</small>
                        <small>索书号：<b>{result.callNumber}</b></small>
                        <em><i>{result.year}</i><i>{result.publisher}</i></em>
                        <span>{result.location}</span>
                      </span>
                    </button>
                    {correctSelected ? <p>{result.note}</p> : null}
                  </article>
                );
              })}
            </section>
          ) : catalogSubmitted ? (
            <section className="zju-catalog-recommendations" aria-label="无检索结果">
              <h2>没有匹配馆藏</h2>
              <p>可尝试书名、作者或索书号中的连续文字。</p>
            </section>
          ) : (
            <section className="zju-catalog-recommendations" aria-label="新书推荐">
              <h2>新书推荐</h2>
              <p>输入题名后，相似书籍会同时列出。</p>
            </section>
          )}
        </main>
      </section>
    );
  } else if (currentPage === "library_recovery") {
    const submitted = finalsPuzzle.recoverySubmittedEvidenceIds;
    const passReady = finalsPuzzle.evictionPassGenerated || ["pass_ready", "backpack_removed", "seat_recovered", "friend_contacted"].includes(finalsPhase);
    page = (
      <section className="app-screen zju-native-page zju-recovery-page" aria-label="022座位恢复申请">
        <NativeHeader
          title="022座位恢复申请"
          onBack={goBack}
        />
        <main className="zju-recovery-content">
          <header className="zju-recovery-summary">
            <span>022</span>
            <div>
              <strong>基础馆 · 二楼南区</strong>
              <small>CC98 公示排名：01</small>
            </div>
            <b>{passReady ? "PASS" : `${submitted.length}/3`}</b>
          </header>
          <div className="zju-recovery-progress" aria-label={`恢复材料进度 ${submitted.length}/3`}>
            <span style={{ width: `${passReady ? 100 : submitted.length / 3 * 100}%` }} />
          </div>
          <section className="zju-recovery-rule">
            <strong>旧版规则 · 恢复条件</strong>
            <p>CC98 公示已生效。三份材料分别确认占用物身份、座位编号与本人到馆记录。</p>
          </section>
          <section className="zju-recovery-slots" aria-label="恢复证明槽位">
            {RECOVERY_EVIDENCE.map((evidence, index) => {
              const owned = state.items[evidence.item];
              const uploaded = submitted.includes(evidence.id);
              const status = uploaded ? "已核验" : owned ? "可提交" : "待取得";
              return (
                <article
                  key={evidence.id}
                  className={`${uploaded ? "is-uploaded" : owned ? "is-ready" : "is-missing"} ${
                    draggedRecoveryItem
                      ? draggedRecoveryItem === evidence.item ? "is-compatible-drop" : "is-incompatible-drop"
                      : ""
                  }`.trim()}
                  data-drop-target={`recovery-upload:${evidence.id}`}
                  data-compatible-item={evidence.item}
                >
                  <span>{String(index + 1).padStart(2, "0")}</span>
                  <div>
                    <header><strong>{evidence.label}</strong><b>{status}</b></header>
                    <small>来源：{evidence.source}</small>
                    <em>{uploaded ? "材料已锁定到本次申请" : owned ? "道具栏已识别，可提交校验" : evidence.nextStep}</em>
                  </div>
                  <button
                    type="button"
                    disabled={!uploaded && (!owned || finalsPhase !== "recovery_application")}
                    onClick={() => uploaded ? setSubmittedDocument(evidence.item) : uploadRecoveryEvidence(evidence.id)}
                  >
                    {uploaded ? "查看" : "提交"}
                  </button>
                </article>
              );
            })}
          </section>
          {recoveryFeedback ? <p className="zju-recovery-feedback" aria-live="polite">{recoveryFeedback}</p> : null}
          {passReady ? (
            <section className="zju-pass-result" aria-label="座位释放PASS已签发">
              <strong>PASS 已签发</strong>
              <p>凭证只对 RPG 图书馆内的 022 书包生效。</p>
              <button type="button" onClick={openCampusMap}>回图书馆处理书包</button>
            </section>
          ) : (
            <button type="button" className="zju-recovery-submit" disabled={submitted.length < 3 || finalsPhase !== "recovery_application"} onClick={generateEvictionPass}>
              生成 022 座位释放 PASS
            </button>
          )}
        </main>
      </section>
    );
  } else if (currentPage === "library_spaces") {
    page = (
      <section className={`app-screen zju-native-page zju-spaces-page ${railCollapsed ? "rail-collapsed" : ""}`} aria-label="图书馆空间列表">
        <NativeHeader
          title="图书馆空间预约..."
          onBack={goBack}
          onMore={() => setOverlay({ kind: "actions", title: "空间预约菜单", actions: ["刷新空位", "我的预约", "预约规则"] })}
        />
        <main className="zju-space-shell">
          <aside className="zju-space-rail" data-ui-part="reservation-rail">
            <button type="button" aria-label={railCollapsed ? "展开座位预约栏" : "收起座位预约栏"} onClick={() => setRailCollapsed((value) => !value)}>
              <span aria-hidden="true">{railCollapsed ? "»" : "»"}</span>
              <b>座<br />位<br />预<br />约</b>
            </button>
          </aside>
          <section className="zju-space-main">
            <div className="zju-space-tabs" role="tablist" aria-label="空间选择模式">
              <button type="button" role="tab" aria-selected={spaceMode === "list"} className={spaceMode === "list" ? "is-active" : ""} onClick={() => setSpaceMode("list")}>列表</button>
              <button type="button" role="tab" aria-selected={spaceMode === "quick"} className={spaceMode === "quick" ? "is-active" : ""} onClick={() => setSpaceMode("quick")}>快速选择</button>
            </div>
            <div className="zju-space-toolbar">
              <p>显示 <strong>{spaceMode === "list" ? 25 : 4}</strong> 空间</p>
              <button type="button" onClick={() => setOverlay({ kind: "libraries" })}>
                {selectedLibrary}<span aria-hidden="true">▼</span>
              </button>
            </div>
            {spaceMode === "list" ? (
              <div className="zju-room-list" aria-label="可预约空间列表" data-ui-part="room-list">
                {ROOMS.map((room) => (
                  <article className="zju-room-card" key={room.label}>
                    <div className="zju-room-photo">
                      <img src={room.imageUrl} alt={`${room.label}自习空间`} />
                      <span>主馆</span>
                    </div>
                    <div className="zju-room-copy">
                      <header><h2>{room.label}</h2><span>{room.floor}</span></header>
                      <p>座位 {room.seats}　空闲 <strong>{room.available}</strong></p>
                      <button type="button" aria-label={`预约${room.label}`} onClick={() => enterRoom(room.label)}>预约</button>
                    </div>
                  </article>
                ))}
              </div>
            ) : (
              <div className="zju-room-quick" aria-label="快速选择空间" data-ui-part="quick-room-grid">
                {ROOMS.map((room) => (
                  <button type="button" key={room.label} onClick={() => enterRoom(room.label)}>
                    <strong>{room.label}</strong>
                    <span>空闲 {room.available}</span>
                  </button>
                ))}
              </div>
            )}
          </section>
        </main>
        <BottomNav
          items={[{ label: "首页", icon: "⌂" }, { label: "我的中心", icon: "♙" }]}
          active="首页"
          onSelect={(label) => announce(label === "首页" ? "当前位于空间预约列表。" : "我的预约已打开。")}
        />
      </section>
    );
  } else if (currentPage === "library_seat") {
    const investigationActive = [
      "occupied_seat_found",
      "evidence_gathering",
      "top_ten_rising",
      "top_ten_reached",
      "recovery_application",
      "pass_ready",
      "backpack_removed",
      "seat_recovered",
      "friend_contacted"
    ].includes(finalsPhase);
    const investigationStatus = finalsPuzzle.playerSeated
      ? "座位已恢复"
      : finalsPuzzle.backpackEvicted
        ? "清退已执行"
        : finalsPuzzle.evictionPassGenerated
          ? "PASS 已签发"
          : finalsPhase === "recovery_application"
            ? "恢复申请待提交"
            : ["top_ten_rising", "top_ten_reached"].includes(finalsPhase)
              ? "公示审核中"
              : "占用异常";
    page = (
      <section className="app-screen zju-native-page zju-seat-page" aria-label="图书馆座位选择">
        <NativeHeader
          title="图书馆空间预约..."
          onBack={goBack}
          onMore={() => setOverlay({ kind: "actions", title: "选座菜单", actions: ["刷新座位", "预约规则", "取消预约"] })}
        />
        <main className="zju-seat-content">
          <section className="zju-seat-room-summary" data-ui-part="room-summary">
            <div>
              <h2>主馆 · 二层 · {selectedRoom}</h2>
              <p>
                <button type="button" onClick={() => announce("平面图已打开。")}>查看平面图 ›</button>
                <button type="button" onClick={() => announce(`${selectedRoom}房间详情已打开。`) }>查看房间详情 ›</button>
              </p>
            </div>
            <button type="button" className="zju-seat-available" onClick={() => announce("当前空余 32 个座位。")}>空余 32</button>
          </section>

          {investigationActive ? (
            <section className="zju-seat-investigation" aria-label="022调查状态">
              <span aria-hidden="true">022</span>
              <div>
                <small>当前现场状态</small>
                <strong>{investigationStatus}</strong>
                <p>{finalsPuzzle.backpackEvicted ? "现场已清空，座位等待本人确认。" : "书包仍在现场，手机页面只负责查询与提交材料。"}</p>
              </div>
              <button type="button" onClick={openCampusMap}>返回现场</button>
            </section>
          ) : (
            <section className="zju-seat-booking" aria-label="预约日期与时段" data-ui-part="booking-controls">
              <button type="button" onClick={() => setOverlay({ kind: "date" })}>
                <strong>{selectedDate.split(" · ")[0]}</strong>
                <span>{selectedDate.split(" · ")[1]}</span>
                <i aria-hidden="true" />
              </button>
              <button type="button" onClick={() => setOverlay({ kind: "time" })}>
                <strong>{selectedTime}</strong>
                <i aria-hidden="true" />
              </button>
            </section>
          )}

          <div className="zju-seat-view-tabs" role="tablist" aria-label="座位显示模式">
            <button type="button" role="tab" aria-selected={seatView === "map"} className={seatView === "map" ? "is-active" : ""} onClick={() => setSeatView("map")}>地图模式</button>
            <button type="button" role="tab" aria-selected={seatView === "list"} className={seatView === "list" ? "is-active" : ""} onClick={() => setSeatView("list")}>列表模式</button>
          </div>

          <div className="zju-seat-toolbar">
            <p>已选座位号：<strong>{state.ui.librarySelectedSeat ?? "-"}</strong></p>
            <button type="button" onClick={() => setOverlay({ kind: "filter" })}><span aria-hidden="true">▽≡</span>筛选</button>
          </div>

          {seatView === "map" ? (
            <SeatMap
              selectedSeat={state.ui.librarySelectedSeat}
              lost={finalsPuzzle.backpackInspected && !finalsPuzzle.playerSeated}
              restored={finalsPuzzle.playerSeated}
              dropReady={false}
              targetSeatRef={seatDropTargetRef}
              onSelect={selectSeat}
            />
          ) : (
            <section className="zju-seat-list" aria-label="可选座位列表" data-ui-part="seat-list">
              {SEAT_LIST_IDS.map((seat) => (
                <button key={seat} type="button" className={state.ui.librarySelectedSeat === seat ? "is-selected" : ""} onClick={() => selectSeat(seat)}>
                  {seat}
                </button>
              ))}
            </section>
          )}

          {investigationActive ? (
            <p className="library-finals-drop-hint">手机端保留调查记录；书包、小票与 PASS 操作均在图书馆现场完成。</p>
          ) : null}
        </main>
        <footer className="zju-seat-actions" data-ui-part="reservation-actions">
          <button type="button" className="secondary" onClick={goBack}><span aria-hidden="true">↶</span>返回</button>
          <button type="button" className="primary" onClick={requestReservation}>
            {state.ui.librarySeatReserved ? "预约成功" : "立即预约"}
          </button>
        </footer>
      </section>
    );
  } else {
    page = (
      <section className="app-screen zju-native-page zju-hub-page" aria-label="浙大钉首页">
        <main className="zju-hub-content">
          <section className="zju-hub-profile" data-ui-part="profile-header">
            <button
              type="button"
              className="zju-hub-avatar"
              aria-label="打开个人菜单"
              aria-haspopup="dialog"
              onClick={() => setOverlay({
                kind: "actions",
                title: "个人菜单",
                actions: ["个人资料", "账号与安全", "退出浙大钉"]
              })}
            >
              <span>{actOneContent.studentName}</span><i aria-hidden="true">▣</i>
            </button>
            <div className="zju-hub-name">
              <strong>{actOneContent.studentName}</strong><small>浙江大学</small>
            </div>
            <span className="zju-hub-search-pill zju-locked-control-icon" data-locked-icon="hub-search" aria-hidden="true">⌕</span>
          </section>

          <section className="zju-identity-card" data-ui-part="identity-card">
            <div className="zju-id-decoration" aria-hidden="true"><i /><i /><i /></div>
            <div className="zju-id-summary">
              {(["system_required", "inventory_required", "system_return_required"] as const).includes(
                actOnePhase as "system_required" | "inventory_required" | "system_return_required"
              ) ? (
                <button
                  type="button"
                  className="zju-id-seal zju-system-seal is-active"
                  aria-label="系统红圈"
                  onClick={openSystemDialogue}
                >
                  求
                </button>
              ) : (
                <span className="zju-id-seal" aria-hidden="true">求</span>
              )}
              <div><h2>{actOneContent.studentName}</h2><p>{actOneContent.studentId}/求是学院（归口...</p></div>
              <span className="zju-id-summary-icon zju-locked-control-icon" data-locked-icon="identity-qr" aria-hidden="true">▦</span>
            </div>
            <div className="zju-id-actions">
              <span className="zju-static-action zju-locked-icon-slot" data-locked-icon="identity-code" data-locked-app="身份码" aria-hidden="true">
                <span>◎</span><small className="zju-locked-label">身份码</small>
              </span>
              <button type="button" onClick={openCampusCard}><span aria-hidden="true">▣</span>电子校园卡</button>
              <span className="zju-static-action zju-locked-icon-slot" data-locked-icon="identity-wallet" data-locked-app="校园钱包" aria-hidden="true">
                <span>◇</span><small className="zju-locked-label">校园钱包</small>
              </span>
              {access.departmentDirectory ? (
                <button type="button" onClick={() => goPage("directory")}>
                  <span aria-hidden="true">☎</span>部门黄页
                  {movementQuestActive && !state.actOne.characterNamed ? <b>任务</b> : null}
                </button>
              ) : (
                <span className="zju-static-action zju-locked-icon-slot" data-locked-app="部门黄页" aria-hidden="true">
                  <span>☎</span><small className="zju-locked-label">部门黄页</small>
                </span>
              )}
            </div>
          </section>

          <div className="zju-baishitong-search zju-locked-control-icon" data-locked-icon="campus-search" aria-hidden="true"><span>⌕</span></div>

          <section className="zju-hub-app-panel" aria-label="浙大钉应用" data-ui-part="application-grid">
            {HUB_APPS.map((app) => {
              const enabled = app.label === "学在浙大"
                || app.label === "校园地图"
                || (app.label === "图书馆" && access.library);
              return enabled ? (
                <button key={app.label} type="button" data-app-id={app.label} onClick={() => openApp(app.label, app.page)}>
                  <PixelAppIcon symbol={app.icon} tone={app.tone} badge={app.badge} />
                  <span>{app.label}</span>
                </button>
              ) : (
                <span
                  key={app.label}
                  className="zju-static-app zju-locked-icon-slot"
                  data-locked-app={app.label}
                  aria-hidden="true"
                >
                  <PixelAppIcon symbol={app.icon} tone={app.tone} />
                  <span className="zju-locked-label">{app.label}</span>
                </span>
              );
            })}
          </section>
        </main>
        <nav className="zju-native-bottom-nav zju-bottom-static" aria-label="页面导航">
          {HUB_BOTTOM_ITEMS.map((item, index) => (
            <span key={item.label} data-locked-icon={`hub-nav-${index + 1}`} aria-hidden="true">
              <i>{item.icon}</i><small>{item.label}</small>
            </span>
          ))}
        </nav>
      </section>
    );
  }

  return (
    <>
      {page}
      <ItemInspectDialog
        open={submittedDocument !== null}
        itemId={submittedDocument}
        variant="phone"
        portalRoot={typeof document === "undefined" ? null : document.querySelector(".phone-frame")}
        onClose={() => setSubmittedDocument(null)}
      />
      {systemDialogue ? (
        <div className="zju-system-dialogue-layer" role="dialog" aria-modal="true" aria-label="系统对话">
          <div className="zju-system-orb" aria-hidden="true"><span>求</span><i /></div>
          <section className={`zju-system-dialogue is-${SYSTEM_DIALOGUES[systemDialogue][systemDialogueIndex].speaker}`}>
            <small>{SYSTEM_DIALOGUES[systemDialogue][systemDialogueIndex].speaker === "system" ? "系统" : "我"}</small>
            <p>{SYSTEM_DIALOGUES[systemDialogue][systemDialogueIndex].text}</p>
            <button type="button" aria-label="继续对话" onClick={advanceSystemDialogue}>›</button>
          </section>
        </div>
      ) : null}
      {overlay?.kind === "search" ? (
        <ActionSheet title="浙大百事通" onClose={() => setOverlay(null)}>
          <label className="zju-search-field">
            <span>搜索应用</span>
            <input autoFocus value={searchQuery} onChange={(event) => setSearchQuery(event.target.value)} placeholder="输入应用名称" />
          </label>
          <div className="zju-sheet-actions">
            {searchResults.length ? (
              searchResults.map((app) => (
                <button key={app.label} type="button" onClick={() => openApp(app.label, app.page)}>
                  {app.label}
                </button>
              ))
            ) : (
              <p>没有匹配的应用</p>
            )}
          </div>
        </ActionSheet>
      ) : null}
      {overlay?.kind === "actions" ? (
        <ActionSheet title={overlay.title} onClose={() => setOverlay(null)}>
          <div className="zju-sheet-actions">
            {overlay.actions.map((action) => (
              <button
                key={action}
                type="button"
                onClick={() => {
                  setOverlay(null);
                  action === "退出浙大钉" ? router.goTo("phone_home") : announce(`${action}已执行。`);
                }}
              >
                {action}
              </button>
            ))}
          </div>
        </ActionSheet>
      ) : null}
      {overlay?.kind === "libraries" ? (
        <ActionSheet title="选择馆舍" onClose={() => setOverlay(null)}>
          <div className="zju-sheet-actions">
            {["主馆", "基础馆", "农医馆", "紫金港西区馆"].map((library) => (
              <button
                key={library}
                type="button"
                onClick={() => {
                  setSelectedLibrary(library);
                  setOverlay(null);
                  announce(`已选择${library}。`);
                }}
              >
                {library}
              </button>
            ))}
          </div>
        </ActionSheet>
      ) : null}
      {overlay?.kind === "date" ? (
        <ActionSheet title="预约日期" onClose={() => setOverlay(null)}>
          <div className="zju-sheet-actions">
            {["07月10日 · 今天", "07月11日 · 明天", "07月12日 · 后天"].map((date) => (
              <button key={date} type="button" onClick={() => { setSelectedDate(date); setOverlay(null); }}>
                {date}
              </button>
            ))}
          </div>
        </ActionSheet>
      ) : null}
      {overlay?.kind === "time" ? (
        <ActionSheet title="预约时段" onClose={() => setOverlay(null)}>
          <div className="zju-sheet-actions">
            {["08:00 - 12:00", "13:00 - 17:00", "18:00 - 22:00", "00:01 - 23:59"].map((time) => (
              <button key={time} type="button" onClick={() => { setSelectedTime(time); setOverlay(null); }}>
                {time}
              </button>
            ))}
          </div>
        </ActionSheet>
      ) : null}
      {overlay?.kind === "filter" ? (
        <ActionSheet title="筛选座位" onClose={() => setOverlay(null)}>
          <div className="zju-sheet-actions">
            {["靠窗", "有电源", "安静区", "全部座位"].map((filter) => (
              <button key={filter} type="button" onClick={() => { setOverlay(null); announce(`已应用筛选：${filter}。`); }}>
                {filter}
              </button>
            ))}
          </div>
        </ActionSheet>
      ) : null}
      {overlay?.kind === "confirm" ? (
        <ActionSheet title="确认预约" onClose={() => setOverlay(null)}>
          <p className="reservation-summary">
            {selectedRoom} · {state.ui.librarySelectedSeat} 号座位
            <br />
            {selectedDate}，{selectedTime}
          </p>
          <div className="zju-sheet-actions two-column">
            <button type="button" onClick={() => setOverlay(null)}>
              再想一下
            </button>
            <button type="button" className="primary" onClick={confirmReservation}>
              确认预约
            </button>
          </div>
        </ActionSheet>
      ) : null}
    </>
  );
}
