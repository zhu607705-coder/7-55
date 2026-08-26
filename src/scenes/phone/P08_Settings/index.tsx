import { useMemo, useState } from "react";
import { PhoneNavButton } from "../../../components/PhoneNavButton";
import type { SceneComponentProps } from "../../../components/ScenePlaceholder";
import {
  DEFAULT_PHONE_HOME_APP_ORDER,
  canRemovePhoneHomeApp
} from "../../../core/PhoneHomeApps";
import type { PhoneHomeAppId } from "../../../core/types";
import {
  CHAPTER_FOUR_BACKGROUND_RECORD_IDS,
  selectChapterFourSettingsProjection
} from "../../../modules/ChapterFourSettingsModel";
import { kit } from "../../../modules/GameKit";
import { playSfx } from "../../../modules/Sfx";

type SettingsPage =
  | "root"
  | "network"
  | "sound"
  | "display"
  | "desktop"
  | "apps"
  | "privacy"
  | "activity"
  | "about";

const APP_LABELS: Record<PhoneHomeAppId, string> = {
  wechat: "微信",
  tiyi: "浙大体艺",
  zjuding: "浙大钉",
  settings: "设置",
  photos: "照片",
  timeline_recovery: "记录恢复",
  voice_memos: "录音",
  cc98: "CC98",
  control_center: "控制中心",
  clock: "时钟"
};

const SETTINGS_ROWS: ReadonlyArray<{ id: Exclude<SettingsPage, "root">; icon: string; label: string; note: string }> = [
  { id: "network", icon: "网", label: "校园网络与移动数据", note: "查看当前连接" },
  { id: "sound", icon: "声", label: "声音与振动", note: "背景音乐" },
  { id: "display", icon: "显", label: "显示与辅助", note: "亮度与可读性" },
  { id: "desktop", icon: "桌", label: "桌面与壁纸", note: "移动图标与恢复排布" },
  { id: "apps", icon: "应", label: "应用管理", note: "恢复可选应用" },
  { id: "privacy", icon: "权", label: "隐私与权限", note: "相机、照片与网络" },
  { id: "activity", icon: "电", label: "电池与后台活动", note: "检查 07:55 记录" },
  { id: "about", icon: "系", label: "系统诊断与关于", note: "存档与运行状态" }
];

const BACKGROUND_RECORDS = [
  { id: "weather_refresh_0748", time: "07:48", app: "天气", action: "天气卡片刷新", drain: "1%" },
  { id: CHAPTER_FOUR_BACKGROUND_RECORD_IDS.photoIndex, time: "07:55", app: "照片", action: "重新建立 IMG_0755 索引", drain: "7%" },
  { id: "wechat_sync_0752", time: "07:52", app: "微信", action: "同步两条新消息", drain: "1%" },
  { id: CHAPTER_FOUR_BACKGROUND_RECORD_IDS.clockWake, time: "07:55", app: "时钟", action: "系统时间被后台唤醒", drain: "5%" },
  { id: CHAPTER_FOUR_BACKGROUND_RECORD_IDS.mapResume, time: "07:55", app: "浙大钉", action: "恢复 A2 室内定位", drain: "6%" },
  { id: "cc98_cache_0802", time: "08:02", app: "CC98", action: "读取热门话题缓存", drain: "1%" }
] as const;

export function SettingsScene({ state, router }: SceneComponentProps) {
  const [page, setPage] = useState<SettingsPage>("root");
  const [query, setQuery] = useState("");
  const [selectedRecords, setSelectedRecords] = useState<string[]>([]);
  const [feedback, setFeedback] = useState("");
  const settingsProjection = selectChapterFourSettingsProjection(state);
  const filteredRows = useMemo(() => SETTINGS_ROWS.filter((row) => (
    !query.trim() || `${row.label}${row.note}`.includes(query.trim())
  )), [query]);
  const removableApps = useMemo(() => state.ui.homeAppOrder.filter((appId) => (
    canRemovePhoneHomeApp(state, appId)
  )), [state.actOne, state.ui.homeAppOrder, state.ui.libraryFinalsPuzzle]);

  function openPage(next: Exclude<SettingsPage, "root">) {
    playSfx("02_", { volume: 0.45 });
    setFeedback("");
    setPage(next);
  }

  function goBack() {
    if (page === "root") {
      router.goTo("phone_home");
      return;
    }
    setFeedback("");
    setPage("root");
  }

  function moveApp(appId: PhoneHomeAppId, direction: -1 | 1) {
    const order = [...state.ui.homeAppOrder];
    const index = order.indexOf(appId);
    const target = index + direction;
    if (index < 0 || target < 0 || target >= order.length) return;
    [order[index], order[target]] = [order[target], order[index]];
    kit.flags.setUi("homeAppOrder", order);
    setFeedback(`${APP_LABELS[appId]}已移动。`);
  }

  function restoreApp(appId: PhoneHomeAppId) {
    kit.flags.setUi("hiddenHomeAppIds", state.ui.hiddenHomeAppIds.filter((id) => id !== appId));
    setFeedback(`${APP_LABELS[appId]}已回到桌面。`);
  }

  function verifyDesktopLayout() {
    const result = kit.chapterFour.restoreDesktopLayout(state.ui.homeAppOrder);
    setFeedback(result === "accepted" || result === "already_complete"
      ? "旧桌面排布已核对，辅助记录已保存。"
      : result === "incorrect"
        ? "第一排仍不对。旧截图从左到右是微信、浙大钉、照片、CC98。"
        : "进入第四章后才能核对这张旧桌面截图。"
    );
  }

  function toggleRecord(id: string) {
    if (settingsProjection.backgroundActivityVerified) return;
    setSelectedRecords((current) => current.includes(id)
      ? current.filter((recordId) => recordId !== id)
      : [...current, id]
    );
    setFeedback("");
  }

  function verifyActivity() {
    const result = kit.chapterFour.verifyBackgroundActivity(selectedRecords);
    setFeedback(result === "accepted" || result === "already_complete"
      ? "三条 07:55 异常记录已归档。照片索引、时钟唤醒和 A2 定位共用同一时刻。"
      : result === "incorrect"
        ? "记录还混着正常刷新。只保留同时发生在 07:55 的三条异常活动。"
        : "第四章尚未开始，这里只有普通后台记录。"
    );
  }

  function renderSubpage() {
    if (page === "network") return <section className="settings-detail-card"><h2>校园网络与移动数据</h2><dl><div><dt>当前网络</dt><dd>{state.networkMode === "campus_wifi" ? "ZJUWLAN" : state.networkMode === "cellular" ? "移动数据" : "离线"}</dd></div><div><dt>CC98</dt><dd>{state.networkMode === "campus_wifi" ? "可访问" : "等待校园网"}</dd></div></dl><button type="button" onClick={() => kit.flags.setUi("controlCenterOpen", true)}>打开控制中心切换网络</button></section>;
    if (page === "sound") return <section className="settings-detail-card"><h2>声音与振动</h2><button type="button" className="settings-toggle-row" aria-pressed={!state.ui.musicMuted} onClick={() => kit.flags.setUi("musicMuted", !state.ui.musicMuted)}><span><b>背景音乐</b><small>语音与操作音效保持开启</small></span><em>{state.ui.musicMuted ? "关闭" : "开启"}</em></button></section>;
    if (page === "display") return <section className="settings-detail-card"><h2>显示与辅助</h2><label className="settings-range"><span><b>屏幕亮度</b><output>{Math.round(state.ui.brightness)}%</output></span><input type="range" min="0" max="100" value={state.ui.brightness} onChange={(event) => kit.flags.setUi("brightness", Number(event.currentTarget.value))} /></label><p>照片取证会读取这个亮度值。</p></section>;
    if (page === "desktop") return <section className="settings-detail-card"><h2>桌面与壁纸</h2><p>桌面也支持长按图标进入编辑。这里可用按钮精确调整顺序。</p><div className="settings-layout-reference"><small>旧截图第一排</small><strong>微信　浙大钉　照片　CC98</strong></div><ol className="settings-app-order">{state.ui.homeAppOrder.map((appId, index) => <li key={appId}><span>{index + 1}. {APP_LABELS[appId]}</span><span><button type="button" aria-label={`将${APP_LABELS[appId]}前移`} disabled={index === 0} onClick={() => moveApp(appId, -1)}>↑</button><button type="button" aria-label={`将${APP_LABELS[appId]}后移`} disabled={index === state.ui.homeAppOrder.length - 1} onClick={() => moveApp(appId, 1)}>↓</button></span></li>)}</ol><button type="button" onClick={() => { kit.flags.setUi("homeAppOrder", [...DEFAULT_PHONE_HOME_APP_ORDER]); setFeedback("桌面已恢复默认顺序。"); }}>恢复默认顺序</button>{settingsProjection.active ? <button type="button" onClick={verifyDesktopLayout}>核对旧桌面截图</button> : null}</section>;
    if (page === "apps") return <section className="settings-detail-card"><h2>应用管理</h2>{state.ui.hiddenHomeAppIds.length ? <ul className="settings-hidden-apps">{state.ui.hiddenHomeAppIds.map((appId) => <li key={appId}><span>{APP_LABELS[appId]}</span><button type="button" onClick={() => restoreApp(appId)}>恢复</button></li>)}</ul> : <p>没有从桌面移除的可选应用。</p>}{removableApps.length ? <p>当前允许从桌面移除　{removableApps.map((appId) => APP_LABELS[appId]).join("、")}</p> : <p>当前阶段还没有可删除的可选应用。</p>}<p>微信、照片、CC98、浙大钉、设置等剧情应用只能移动。</p></section>;
    if (page === "privacy") return <section className="settings-detail-card"><h2>隐私与权限</h2><dl><div><dt>相机</dt><dd>取证时使用</dd></div><div><dt>照片</dt><dd>保存剧情照片</dd></div><div><dt>校园网络</dt><dd>CC98 与校内服务</dd></div></dl></section>;
    if (page === "activity") return <section className="settings-detail-card settings-activity"><h2>电池与后台活动</h2><p>{settingsProjection.active ? "选出同时发生在 07:55 的三条异常活动。" : "当前没有需要核验的剧情记录。"}</p><div className="settings-record-list">{BACKGROUND_RECORDS.map((record) => { const selected = selectedRecords.includes(record.id); return <button key={record.id} type="button" aria-pressed={selected} disabled={!settingsProjection.active || settingsProjection.backgroundActivityVerified} className={selected ? "is-selected" : ""} onClick={() => toggleRecord(record.id)}><time>{record.time}</time><span><b>{record.app}</b><small>{record.action}</small></span><em>{record.drain}</em></button>; })}</div>{settingsProjection.active ? <button type="button" disabled={settingsProjection.backgroundActivityVerified || selectedRecords.length !== 3} onClick={verifyActivity}>{settingsProjection.backgroundActivityVerified ? "记录已归档" : "核验所选记录"}</button> : null}</section>;
    if (page === "about") return <section className="settings-detail-card"><h2>系统诊断与关于</h2><dl><div><dt>游戏时间</dt><dd>07:55</dd></div><div><dt>存档</dt><dd>自动保存与上一版本恢复</dd></div><div><dt>桌面应用</dt><dd>{state.ui.homeAppOrder.length - state.ui.hiddenHomeAppIds.length} 个可见</dd></div></dl></section>;
    return null;
  }

  return (
    <section className="app-screen settings-page" aria-label="设置">
      <header className="settings-header">
        <PhoneNavButton kind="back" label={page === "root" ? "退出设置，返回手机主页" : "返回设置"} onClick={goBack} />
        <div><small>PHONE SYSTEM</small><h1>{page === "root" ? "设置" : SETTINGS_ROWS.find((row) => row.id === page)?.label}</h1></div>
        <span aria-hidden="true">07:55</span>
      </header>
      {page === "root" ? <main className="settings-root"><label className="settings-search"><span aria-hidden="true">⌕</span><input value={query} onChange={(event) => setQuery(event.currentTarget.value)} placeholder="搜索设置项" aria-label="搜索设置项" /></label><div className="settings-section-list">{filteredRows.map((row) => <button key={row.id} type="button" onClick={() => openPage(row.id)}><i aria-hidden="true">{row.icon}</i><span><b>{row.label}</b><small>{row.note}</small></span><em aria-hidden="true">›</em></button>)}</div></main> : <main className="settings-detail">{renderSubpage()}</main>}
      {feedback ? <p className="settings-feedback" role="status">{feedback}</p> : null}
    </section>
  );
}
