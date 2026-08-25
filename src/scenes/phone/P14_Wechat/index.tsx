import { useEffect, useRef, useState } from "react";
import { PhoneNavButton } from "../../../components/PhoneNavButton";
import type { SceneComponentProps } from "../../../components/ScenePlaceholder";
import { kit } from "../../../modules/GameKit";
import { consumeFriendChatIntent } from "../../../modules/NavIntent";
import { playSfx } from "../../../modules/Sfx";
import { playVo, type VoPlaybackHandle } from "../../../modules/VoicePlayer";
import qizhenContent from "../../../data/chapter3-qizhen-lake.content.json";
import chapterFourWechatContent from "../../../data/chapter4-wechat.content.json";
import chapterFourCc98Content from "../../../data/chapter4-cc98.content.json";
import { CHAPTER_FOUR_CC98_CLUES } from "../../../modules/ChapterFourCc98Model";
import {
  selectChapterFourWechatProjection
} from "../../../modules/ChapterFourWechatModel";
import type { ChapterThreeInterludeRouteMessageId } from "../../../modules/ChapterThreePhoneInterludeController";
import { selectChapterThreeInterludeViewModel } from "../../../modules/ChapterThreeInterludeModel";

type ChapterFourChatView = "official" | "group" | "archive" | "friend" | null;

type InterludeWechatView = "inbox" | "official" | "group";

type OfficialAccountMenu = "daily" | "archive";

const INTERLUDE_ROUTE_MESSAGES: ReadonlyArray<{
  id: ChapterThreeInterludeRouteMessageId;
  author: string;
  text: string;
  withdrawn?: boolean;
}> = [
  { id: "computer_left_on", author: "林昊", text: "203 还开着吗？我电脑没关。" },
  { id: "guard_east", author: "陈嘉", text: "刚看见保安从东边过去。" },
  { id: "east_closed", author: "周琪", text: "东边入口已经封了，别再往那边走。" },
  { id: "west_cleaner", author: "室友", text: "我在西侧看见保洁推车，大厅主入口应该还能进。" },
  { id: "withdrawn", author: "陈嘉", text: "陈嘉撤回了一条消息", withdrawn: true }
];

function InterludeWechatEvidence({ state, router }: Pick<SceneComponentProps, "state" | "router">) {
  const [view, setView] = useState<InterludeWechatView>("inbox");
  const [feedback, setFeedback] = useState("");
  const [selectedRouteMessages, setSelectedRouteMessages] = useState<ChapterThreeInterludeRouteMessageId[]>([]);
  const interlude = state.chapterThreeInterlude;
  const interludeViewModel = selectChapterThreeInterludeViewModel(state);
  const destinationCopyUnlocked = interludeViewModel.destinationSelectionUnlocked || interlude.destinationId !== null;

  function saveOfficialNotice() {
    const result = kit.chapterThreeInterlude.saveOfficialNotice();
    setFeedback(result === "accepted" || result === "already_complete"
      ? "公众号通知已保存。"
      : "先在记录恢复中确认划船帖的离湖时间。"
    );
  }

  function saveRouteScreenshot() {
    const result = kit.chapterThreeInterlude.saveRouteScreenshot(selectedRouteMessages);
    setFeedback(result === "accepted" || result === "already_complete"
      ? "入口变化已截图：东侧关闭，西侧主入口可通行。"
      : result === "incorrect"
        ? "这两条消息还不能拼出可通行入口。需要同时确认封闭方向和可进入方向。"
        : "先在记录恢复中确认划船帖的离湖时间。"
    );
  }

  function toggleRouteMessage(messageId: ChapterThreeInterludeRouteMessageId) {
    if (interlude.routeScreenshotSaved) return;
    setSelectedRouteMessages((current) => current.includes(messageId)
      ? current.filter((id) => id !== messageId)
      : current.length >= 2
        ? [current[1], messageId]
        : [...current, messageId]
    );
    setFeedback("");
  }

  if (view === "official") {
    return (
      <section className="interlude-wechat-page app-screen" aria-label="紫金港楼宇服务公众号通知">
        <header className="interlude-app-header">
          <PhoneNavButton kind="back" label="返回微信消息列表" onClick={() => setView("inbox")} />
          <div><small>公众号 · 22:40</small><h1>紫金港楼宇服务</h1></div>
          <span aria-hidden="true">•••</span>
        </header>
        <main className="interlude-scroll">
          <article className="interlude-official-notice">
            <small>校园楼宇运行通知</small>
            <h2>夜间闭楼与入口调整</h2>
            <div className="interlude-building-plate" aria-hidden="true"><b>{destinationCopyUnlocked ? "A1" : "A?"}</b><i /><i /><i /></div>
            <p>22:45 起，{destinationCopyUnlocked ? "段永平教学楼" : "北教学区一处楼宇"}进入夜间清楼。A 楼一层东侧入口暂停通行，人员请从大厅主入口进入。</p>
            <p>主电梯保留运行，楼层开放情况以现场提示为准。</p>
            <button type="button" onClick={saveOfficialNotice}>
              {interlude.officialNoticeSaved ? "通知已保存" : "保存通知"}
            </button>
          </article>
          {feedback ? <p className="interlude-feedback" role="status">{feedback}</p> : null}
        </main>
      </section>
    );
  }

  if (view === "group") {
    return (
      <section className="interlude-wechat-page app-screen" aria-label="麦斯威夜间自习群">
        <header className="interlude-app-header">
          <PhoneNavButton kind="back" label="返回微信消息列表" onClick={() => setView("inbox")} />
          <div><small>群聊 · 18人</small><h1>麦斯威夜间自习群</h1></div>
          <span aria-hidden="true">•••</span>
        </header>
        <main className="interlude-scroll interlude-chat-thread">
          <div className="interlude-chat-time">22:41</div>
          <p className="interlude-chat-instruction">选中两条能够同时确认“哪边关闭”和“哪边可进入”的消息。</p>
          {INTERLUDE_ROUTE_MESSAGES.map((message) => {
            const selected = selectedRouteMessages.includes(message.id);
            return (
              <button
                key={message.id}
                type="button"
                className={`interlude-route-message ${selected ? "is-selected" : ""} ${message.withdrawn ? "is-withdrawn" : ""}`.trim()}
                aria-pressed={selected}
                disabled={interlude.routeScreenshotSaved}
                onClick={() => toggleRouteMessage(message.id)}
              >
                <b>{message.author}</b>
                <span>{message.text}</span>
                <em>{selected ? "已选" : "选择"}</em>
              </button>
            );
          })}
          {interlude.routeScreenshotSaved ? (
            <figure className="interlude-route-shot">
              <div aria-hidden="true"><i /><i /><i /><b>A1</b></div>
              <figcaption>22:42 入口调整截图 · 东侧关闭 / 西侧主入口可通行</figcaption>
            </figure>
          ) : null}
          <button
            type="button"
            className="interlude-primary-action"
            disabled={!interlude.routeScreenshotSaved && selectedRouteMessages.length !== 2}
            onClick={saveRouteScreenshot}
          >
            {interlude.routeScreenshotSaved ? "截图已保存" : "保存路线截图"}
          </button>
          {feedback ? <p className="interlude-feedback" role="status">{feedback}</p> : null}
        </main>
      </section>
    );
  }

  return (
    <section className="interlude-wechat-page app-screen" aria-label="微信恢复证据">
      <header className="interlude-app-header">
        <PhoneNavButton kind="exit" label="退出微信，返回手机主页" onClick={() => router.goTo("phone_home")} />
        <div><small>微信</small><h1>消息</h1></div>
        <span aria-hidden="true">＋</span>
      </header>
      <main className="interlude-chat-list">
        <button type="button" onClick={() => setView("official")}>
          <span className="interlude-chat-avatar is-official" aria-hidden="true">楼</span>
          <span><strong>紫金港楼宇服务</strong><small>有一条未归档的运行通知</small></span>
          <time>22:40</time>
          {interlude.officialNoticeSaved ? <em>已存</em> : null}
        </button>
        <button type="button" onClick={() => setView("group")}>
          <span className="interlude-chat-avatar is-group" aria-hidden="true">18</span>
          <span><strong>麦斯威夜间自习群</strong><small>有两条消息可组成路线截图</small></span>
          <time>22:42</time>
          {interlude.routeScreenshotSaved ? <em>已存</em> : null}
        </button>
      </main>
      <button type="button" className="interlude-return-recovery" onClick={() => router.goTo("timeline_recovery")}>返回记录恢复</button>
    </section>
  );
}

/**
 * P14 微信：聊天列表（朋友头像＝斜线，藏着 P03 谜题）＋朋友聊天页（小影散码演出）。
 * 斜线谜题：自动旋转开启 → 斜线一端掉落挂在框上 → 点剩余端 3 次 → 整条掉落成道具。
 */
export function WechatScene({ state, router, events }: SceneComponentProps) {
  const [openedFriend, setOpenedFriend] = useState(() =>
    consumeFriendChatIntent(),
  );
  const [attackPhase, setAttackPhase] = useState(0);
  const [attackSkippable, setAttackSkippable] = useState(false);
  const [listTilt, setListTilt] = useState(false);
  const [mentorLineFalling, setMentorLineFalling] = useState(false);
  const [mentorHintStep, setMentorHintStep] = useState(0);
  const [friendAvatarPreDropTapCount, setFriendAvatarPreDropTapCount] = useState(0);
  const [chapterFourChatView, setChapterFourChatView] = useState<ChapterFourChatView>(null);
  const [officialArticleId, setOfficialArticleId] = useState<string | null>(null);
  const [officialAccountMenu, setOfficialAccountMenu] = useState<OfficialAccountMenu>("daily");
  const { flags, ui } = state;
  const followupPending = state.actOne.phase === "friend_message_required";
  const followupVisible = flags.checkinDone && state.actOne.phase !== "prologue";
  const movementQuestActive = state.actOne.phase === "movement_required" || state.actOne.phase === "movement_ready";
  const qizhenLocationChat = state.qizhenLake.active && state.qizhenLake.phase === "location_search";
  const [qizhenChatStep, setQizhenChatStep] = useState(() => state.qizhenLake.lakeClueFound ? qizhenContent.locationSearch.wechat.length : 0);
  const [followupStep, setFollowupStep] = useState(followupVisible && !followupPending ? 3 : 0);
  const sequenceVoRef = useRef<VoPlaybackHandle | null>(null);
  const chapterFourWechat = selectChapterFourWechatProjection(state.chapter4);
  const chapterFourStudyIndexImported = state.chapter4.clueIds.includes(
    CHAPTER_FOUR_CC98_CLUES.studyIndexImported
  );

  // 首次进入朋友聊天：视觉节奏由剧情计时器控制，音频失败不影响推进。
  useEffect(() => {
    if (chapterFourWechat.active || !openedFriend || flags.codeScattered) {
      return undefined;
    }
    let cancelled = false;
    const timers: number[] = [];
    const later = (fn: () => void, ms: number) => {
      timers.push(
        window.setTimeout(() => {
          if (!cancelled) {
            fn();
          }
        }, ms)
      );
    };

    later(() => {
      setAttackPhase(1);
      playSfx("07_");
    }, 900);

    let attackAdvanced = false;
    let sequenceCompleted = false;
    const completeSequence = () => {
      if (cancelled || sequenceCompleted) {
        return;
      }
      sequenceCompleted = true;
      sequenceVoRef.current = null;
      setAttackPhase(4);
      kit.flags.setFlag("codeScattered", true);
      events.emit("code_scattered");
      kit.flags.toast("任务更新：找回四位签到码", "task");
    };
    const continueAfterAttack = () => {
      if (cancelled || attackAdvanced) {
        return;
      }
      attackAdvanced = true;
      setAttackSkippable(false);
      setAttackPhase(3);
      playSfx("09_");
      sequenceVoRef.current = playVo("xy_laugh", {
        subtitle: false,
        tone: "xiaoying",
        onEnded: completeSequence
      });
    };

    later(() => {
      setAttackPhase(2);
      kit.flags.shake(true);
      playSfx("08_");
      events.emit("xiaoying_attack");
      sequenceVoRef.current = playVo("xy_attack", {
        subtitle: false,
        tone: "xiaoying",
        onEnded: continueAfterAttack
      });
    }, 2000);

    // 第一段语音开始两秒后才开放跳过，正常情况下仍播放到文件结束。
    later(() => {
      if (!attackAdvanced) {
        setAttackSkippable(true);
      }
    }, 4000);

    return () => {
      cancelled = true;
      timers.forEach((t) => window.clearTimeout(t));
      sequenceVoRef.current?.cancel();
      sequenceVoRef.current = null;
    };
  }, [chapterFourWechat.active, openedFriend, flags.codeScattered, events]);

  useEffect(() => {
    if (!openedFriend || !followupPending) {
      return undefined;
    }
    setFollowupStep(1);
    playSfx("07_");
    const timers = [
      window.setTimeout(() => {
        setFollowupStep(2);
        events.emit("act2_friend_reply_filled");
      }, 700),
      window.setTimeout(() => {
        setFollowupStep(3);
        playSfx("07_");
      }, 1550),
      window.setTimeout(() => {
        if (kit.actOne.completeFriendExchange()) {
          kit.flags.toast("任务更新：找到系统", "task");
        }
      }, 2150)
    ];
    return () => timers.forEach((timer) => window.clearTimeout(timer));
  }, [events, followupPending, openedFriend]);

  useEffect(() => {
    if (!openedFriend || !qizhenLocationChat || state.qizhenLake.lakeClueFound) return undefined;
    const timers = qizhenContent.locationSearch.wechat.map((_, index) => window.setTimeout(() => {
      setQizhenChatStep(index + 1);
    }, 260 + index * 520));
    return () => timers.forEach((timer) => window.clearTimeout(timer));
  }, [openedFriend, qizhenLocationChat, state.qizhenLake.lakeClueFound]);

  // 自动旋转触发斜线掉一半
  useEffect(() => {
    if (
      openedFriend ||
      !ui.autoRotate ||
      !flags.codeScattered ||
      flags.slashHalfDropped ||
      flags.slashTaken
    ) {
      return undefined;
    }
    setListTilt(true);
    playSfx("16_");
    const timer = window.setTimeout(() => {
      setListTilt(false);
      kit.flags.setFlag("slashHalfDropped", true);
      kit.flags.setUi("autoRotate", false);
      kit.flags.shake();
      playSfx("19_");
      kit.flags.toast("咔——斜线断了一截，挂在头像框上晃悠。");
    }, 1100);
    return () => window.clearTimeout(timer);
  }, [
    openedFriend,
    ui.autoRotate,
    flags.codeScattered,
    flags.slashHalfDropped,
    flags.slashTaken,
  ]);

  useEffect(() => {
    let fallingTimer: number | null = null;
    const unsubscribe = events.subscribe((event) => {
      if (event.name !== "item_dropped" || event.payload?.target !== "mentor_avatar") {
        return;
      }
      if (!movementQuestActive) {
        kit.flags.toast("导师头像现在不接受附件。", "system");
        return;
      }
      if (event.payload?.item !== "weatherWater") {
        playSfx("04_", { volume: 0.5 });
        setMentorHintStep((current) => Math.max(current, 1));
        kit.flags.toast("卡扣反而更紧了。它需要能渗进胶缝的东西。", "system");
        return;
      }
      if (!kit.actOne.releaseMentorLine()) {
        return;
      }
      setMentorLineFalling(true);
      fallingTimer = window.setTimeout(() => setMentorLineFalling(false), 900);
      kit.flags.toast("竖线滑落了。获得道具：竖线", "task");
    });
    return () => {
      unsubscribe();
      if (fallingTimer !== null) {
        window.clearTimeout(fallingTimer);
      }
    };
  }, [events, movementQuestActive]);

  function clickFriendAvatar(e: React.MouseEvent) {
    e.stopPropagation();
    if (chapterFourWechat.active) {
      setChapterFourChatView("friend");
      return;
    }
    if (!flags.codeScattered || flags.slashTaken) {
      setOpenedFriend(true);
      return;
    }
    if (!flags.slashHalfDropped) {
      const taps = friendAvatarPreDropTapCount + 1;
      setFriendAvatarPreDropTapCount(taps);
      const hint = taps === 2
        ? "或许可以再斜一点"
        : taps >= 5
          ? "它也想转转罢"
          : ui.autoRotate
            ? "斜线晃了晃，还没掉。"
            : "头像上的斜线纹丝不动。";
      kit.flags.toast(hint);
      return;
    }
    const taps = flags.slashTapCount + 1;
    kit.flags.setFlag("slashTapCount", taps);
    if (taps >= 3) {
      kit.flags.setFlag("slashTaken", true);
      kit.inventory.addItem("slashLine", "wechat");
      events.emit("slash_taken");
      playSfx("19_");
      kit.flags.toast("检测到未经授权的友情支援。", "xiaoying");
    } else {
      playSfx("02_");
      kit.flags.toast("你戳了戳剩下的一端……");
    }
  }

  function clickMentorAvatar(e: React.MouseEvent | React.KeyboardEvent) {
    e.stopPropagation();
    if (!movementQuestActive) {
      if (state.actOne.phase === "prologue") {
        kit.flags.toast("导师的消息，还是等签完到再回吧。");
      }
      return;
    }
    if (state.actOne.mentorLineReleased) {
      kit.flags.toast("头像中间留下了一道很干净的空隙。", "system");
      return;
    }
    events.emit("act2_mentor_line_stuck");
    kit.flags.toast("这条竖线被透明胶和两枚卡扣封在头像框里。", "system");
    events.emit("act2_mentor_hint_advanced", { step: 1 });
    setMentorHintStep((current) => Math.max(current, 1));
  }

  function skipAttackVoice() {
    if (attackPhase !== 2 || !attackSkippable) {
      return;
    }
    setAttackSkippable(false);
    sequenceVoRef.current?.skip();
  }

  function showChapterFourResult(
    result: ReturnType<typeof kit.chapterFour.readWechatOfficialNotice>,
    accepted: string,
    locked: string
  ) {
    if (result === "accepted") {
      playSfx("07_");
      kit.flags.toast(accepted, "task");
      return;
    }
    if (result === "already_complete") {
      kit.flags.toast("这份资料已经保存。", "system");
      return;
    }
    kit.flags.toast(locked, "system");
  }

  function readOfficialNotice() {
    showChapterFourResult(
      kit.chapterFour.readWechatOfficialNotice(),
      "已保存夜间运行通知。回到一楼核对电梯历史状态。",
      "第四章开始后才能查看这条运行通知。"
    );
  }

  function archiveElevatorAudio() {
    showChapterFourResult(
      kit.chapterFour.archiveWechatElevatorAudio(),
      "已归档主电梯提示音。可以返回电梯进行时间对齐。",
      "先回到一楼，在深色观察中记录电梯历史提示音。"
    );
  }

  function saveStudentRoute() {
    showChapterFourResult(
      kit.chapterFour.saveWechatStudentRoute(),
      "路线讨论已保存。",
      !chapterFourStudyIndexImported
        ? "先去 CC98 学习天地，把课程年份入口、旧讨论和现场核验三项导入群文件。"
        : "先阅读公众号通知，并抵达二楼清楼阶段。"
    );
  }

  function archiveWayfindingPhotos() {
    showChapterFourResult(
      kit.chapterFour.archiveWechatWayfindingPhotos(),
      "新旧导视板照片已归档，可以发给朋友对照。",
      "先在三楼深色观察中找到旧导视板残影。"
    );
  }

  function compareWayfindingPhotos() {
    showChapterFourResult(
      kit.chapterFour.compareWechatWayfindingPhotos(),
      "照片对照完成。回三楼按旧编号校准导视板。",
      "先把三楼新旧导视板照片保存到文件传输助手。"
    );
  }

  function openFriendConversation() {
    if (chapterFourWechat.active) {
      setChapterFourChatView("friend");
      return;
    }
    setOpenedFriend(true);
  }

  function collectLakeKeyword() {
    if (state.qizhenLake.lakeClueFound) return;
    if (!kit.qizhenLake.collectLakeClue()) {
      kit.flags.toast("这条聊天还不能作为地点记录。", "system");
      return;
    }
    kit.flags.toast("已从聊天中保存地点词：湖面。", "task");
  }

  function closeChapterFourChat() {
    if (chapterFourChatView === "official" && officialArticleId) {
      setOfficialArticleId(null);
      return;
    }
    setChapterFourChatView(null);
  }

  function openOfficialAccount() {
    setOfficialArticleId(null);
    setOfficialAccountMenu("daily");
    setChapterFourChatView("official");
  }

  function renderOfficialAccount() {
    const optionalArticles = chapterFourWechatContent.official.optionalArticles;
    const selectedArticle = optionalArticles.find((article) => article.id === officialArticleId);

    if (officialArticleId === "night-notice") {
      return (
        <article className="wx-official-article wx-official-story-reader">
          <small>{chapterFourWechatContent.official.accountType} · {chapterFourWechatContent.official.publishedAt}</small>
          <h2>{chapterFourWechatContent.official.articleTitle}</h2>
          <div className="wx-official-cover" aria-hidden="true"><i /><b>1F</b><i /></div>
          <p>{chapterFourWechatContent.official.summary}</p>
          <ul>
            {chapterFourWechatContent.official.details.map((line) => <li key={line}>{line}</li>)}
          </ul>
          <button type="button" className="wx-evidence-action" onClick={readOfficialNotice}>
            {chapterFourWechat.officialNoticeRead ? "已保存通知" : chapterFourWechatContent.official.readAction}
          </button>
        </article>
      );
    }

    if (selectedArticle) {
      return (
        <article className="wx-official-reader" aria-label={selectedArticle.title}>
          <div className={`wx-lore-cover is-${selectedArticle.coverTone}`} aria-hidden="true">
            <span>{selectedArticle.section}</span>
            <i /><i /><i />
          </div>
          <small>{selectedArticle.publishedAt} · {chapterFourWechatContent.official.name}</small>
          <h2>{selectedArticle.title}</h2>
          {selectedArticle.body.map((paragraph) => <p key={paragraph}>{paragraph}</p>)}
          <footer>阅读 {selectedArticle.readCount} · 校园日常记录</footer>
        </article>
      );
    }

    const visibleArticles = officialAccountMenu === "daily"
      ? optionalArticles.slice(0, 3)
      : optionalArticles;

    return (
      <section className="wx-official-account" aria-label={`${chapterFourWechatContent.official.name}公众号主页`}>
        <header className="wx-official-profile">
          <span className="wx-official-profile-avatar" aria-hidden="true">后勤</span>
          <span>
            <strong>{chapterFourWechatContent.official.name}</strong>
            <small>{chapterFourWechatContent.official.profileNote}</small>
          </span>
          <em>已关注</em>
        </header>

        <button
          type="button"
          className="wx-official-featured"
          onClick={() => setOfficialArticleId("night-notice")}
        >
          <span className="wx-official-featured-cover" aria-hidden="true"><i /><b>1F</b><i /></span>
          <span>
            <small>夜间通知 · {chapterFourWechatContent.official.publishedAt}</small>
            <strong>{chapterFourWechatContent.official.articleTitle}</strong>
            <em>{chapterFourWechatContent.official.summary}</em>
          </span>
          <b className="wx-official-story-state">{chapterFourWechat.officialNoticeRead ? "已保存" : "主线通知"}</b>
        </button>

        <section className="wx-official-feed" aria-label={officialAccountMenu === "daily" ? "校园日常" : "往期推文"}>
          <header>
            <h2>{officialAccountMenu === "daily" ? "校园日常" : "往期推文"}</h2>
            <small>{visibleArticles.length} 篇</small>
          </header>
          {visibleArticles.map((article) => (
            <button
              type="button"
              className="wx-official-feed-row"
              key={article.id}
              onClick={() => setOfficialArticleId(article.id)}
            >
              <span className={`wx-lore-thumb is-${article.coverTone}`} aria-hidden="true"><i /><i /></span>
              <span>
                <small>{article.section} · {article.publishedAt}</small>
                <strong>{article.title}</strong>
                <em>{article.summary}</em>
              </span>
              <b aria-hidden="true">›</b>
            </button>
          ))}
        </section>

        <nav className="wx-official-menu" aria-label="公众号自定义菜单">
          <button type="button" onClick={() => setOfficialArticleId("night-notice")}>夜间通知</button>
          <button
            type="button"
            className={officialAccountMenu === "daily" ? "is-active" : ""}
            onClick={() => setOfficialAccountMenu("daily")}
          >校园日常</button>
          <button
            type="button"
            className={officialAccountMenu === "archive" ? "is-active" : ""}
            onClick={() => setOfficialAccountMenu("archive")}
          >往期推文</button>
        </nav>
      </section>
    );
  }

  function renderChapterFourChat() {
    const view = chapterFourChatView;
    if (!view) return null;
    const titles = {
      official: chapterFourWechatContent.official.name,
      group: chapterFourWechatContent.group.name,
      archive: chapterFourWechatContent.archive.name,
      friend: "朋友"
    } as const;
    return (
      <div className="wx-chat wx-chapter4-chat">
        <header className="wx-header">
          <PhoneNavButton
            kind="back"
            className="wx-back"
            onClick={closeChapterFourChat}
            label={view === "official" && officialArticleId ? "返回公众号主页" : "返回聊天列表"}
          />
          <h1>{titles[view]}</h1>
          <span className="wx-header-tools" aria-hidden="true">…</span>
        </header>
        <div className={`wx-chat-body ${view === "official" ? "is-official-account" : ""}`.trim()}>
          {view === "official" ? (
            renderOfficialAccount()
          ) : null}
          {view === "group" ? (
            <section className="wx-group-thread" aria-label="麦斯威夜间自习群聊天记录">
              <div className="wx-time-divider">22:47 · {chapterFourWechatContent.group.memberCount}人</div>
              {chapterFourStudyIndexImported ? (
                <button
                  type="button"
                  className="wx-group-file-card"
                  onClick={() => setChapterFourChatView("archive")}
                >
                  <span aria-hidden="true">档</span>
                  <span>
                    <b>学习天地资料索引</b>
                    <small>{chapterFourCc98Content.maxwellHandoff.afterImport}</small>
                  </span>
                  <em>群文件 ›</em>
                </button>
              ) : null}
              {chapterFourWechatContent.group.messages.map((message, index) => (
                <div className="wx-msg" key={`${message.sender}-${message.text}`}>
                  <span className={`wx-msg-avatar wx-student-avatar student-${index + 1}`} aria-hidden="true" />
                  <p><b>{message.sender}</b>{message.text}</p>
                </div>
              ))}
              <div className="wx-recalled-message">{chapterFourWechatContent.group.recalled}</div>
              <div className="wx-msg">
                <span className="wx-msg-avatar wx-student-avatar student-1" aria-hidden="true" />
                <p><b>林昊</b>{chapterFourWechatContent.group.followup}</p>
              </div>
              <button type="button" className="wx-evidence-action" onClick={saveStudentRoute}>
                {chapterFourWechat.studentRouteSaved ? "路线讨论已保存" : chapterFourWechatContent.group.saveAction}
              </button>
            </section>
          ) : null}
          {view === "archive" ? (
            <section className="wx-evidence-archive" aria-label="第四章现场资料">
              {chapterFourWechat.archiveCount === 0 && !chapterFourStudyIndexImported ? <p>{chapterFourWechatContent.archive.empty}</p> : null}
              {chapterFourWechat.officialNoticeRead ? (
                <article className="wx-evidence-card"><small>公众号推送 · 22:40</small><strong>{chapterFourWechatContent.archive.officialNotice}</strong><em>已读</em></article>
              ) : null}
              {chapterFourStudyIndexImported ? (
                <article className="wx-evidence-card wx-study-index-file">
                  <small>群文件 · 学习天地</small>
                  <strong>课程年份入口与旧自习讨论</strong>
                  <em>已从 CC98 导入</em>
                </article>
              ) : null}
              {chapterFourWechat.elevatorAudioAvailable ? (
                <article className="wx-evidence-card">
                  <small>现场录音 · 1F</small><strong>▶ {chapterFourWechatContent.archive.elevatorAudio}</strong>
                  <button type="button" onClick={archiveElevatorAudio}>{chapterFourWechat.elevatorAudioArchived ? "已归档" : "保存录音"}</button>
                </article>
              ) : null}
              {chapterFourWechat.studentRouteSaved ? (
                <article className="wx-evidence-card"><small>群聊截图 · 2F</small><strong>{chapterFourWechatContent.archive.studentRoute}</strong><em>待现场核验</em></article>
              ) : null}
              {chapterFourWechat.wayfindingPhotosAvailable ? (
                <article className="wx-evidence-card">
                  <small>现场照片 · 3F</small><strong>{chapterFourWechatContent.archive.wayfindingPhotos}</strong>
                  <button type="button" onClick={archiveWayfindingPhotos}>{chapterFourWechat.wayfindingPhotosArchived ? "已归档" : "保存照片"}</button>
                </article>
              ) : null}
            </section>
          ) : null}
          {view === "friend" ? (
            <section className="wx-chapter4-friend" aria-label="朋友导视板对照聊天">
              <div className="wx-msg"><span className="wx-msg-avatar" aria-hidden="true"><i /></span><p>{chapterFourWechatContent.friend.request}</p></div>
              {chapterFourWechat.wayfindingPhotosArchived ? (
                <>
                  <div className="wx-msg is-self"><p>{chapterFourWechatContent.friend.selfCaption}</p></div>
                  <div className="wx-photo-comparison" aria-label="新旧导视板照片">
                    <figure><div className="wx-sign-board is-current">2F →</div><figcaption>当前导视</figcaption></figure>
                    <figure><div className="wx-sign-board is-old">← 2F</div><figcaption>历史残影</figcaption></figure>
                  </div>
                  <button type="button" className="wx-evidence-action" onClick={compareWayfindingPhotos}>
                    {chapterFourWechat.wayfindingCompared ? "照片已完成对照" : chapterFourWechatContent.friend.compareAction}
                  </button>
                  {chapterFourWechat.wayfindingCompared ? (
                    <div className="wx-msg"><span className="wx-msg-avatar" aria-hidden="true"><i /></span><p>{chapterFourWechatContent.friend.analysis}</p></div>
                  ) : null}
                </>
              ) : <p className="wx-field-note">文件传输助手里还没有两张导视板照片。</p>}
            </section>
          ) : null}
        </div>
      </div>
    );
  }

  if (
    state.qizhenLake.phase === "complete"
    && !state.chapterThreeInterlude.completed
    && state.chapterThreeInterlude.recoveryOpened
  ) {
    return <InterludeWechatEvidence state={state} router={router} />;
  }

  const slashState = flags.slashTaken
    ? "gone"
    : flags.slashHalfDropped
      ? "half"
      : "full";

  return (
    <section className="wechat-scene" aria-label="微信">
      {chapterFourChatView ? renderChapterFourChat() : !openedFriend ? (
        <div className={`wx-list ${listTilt ? "is-tilting" : ""}`}>
          <header className="wx-header">
            <PhoneNavButton
              kind="exit"
              className="wx-back"
              onClick={() => router.goTo("phone_home")}
              label="退出微信，返回手机主页"
            />
            <h1>聊天({chapterFourWechat.active ? 6 : 4})</h1>
            <span className="wx-header-tools" aria-hidden="true">
              ⌕ ⊕
            </span>
          </header>
          <div className="wx-device-tip">已登录 2 台设备 ›</div>

          <ul className="wx-rows">
            {chapterFourWechat.active ? (
              <>
                <li>
                  <button type="button" className="wx-row" onClick={() => setChapterFourChatView("group")}>
                    <span className="wx-avatar wx-group-avatar" aria-hidden="true"><i /><i /><i /><i /></span>
                    <span className="wx-row-main"><strong>{chapterFourWechatContent.group.name}</strong><em>{chapterFourWechat.studentRouteSaved ? "路线讨论已保存" : chapterFourStudyIndexImported ? "学习天地资料已加入群文件" : "等你从 CC98 导入资料索引"}</em></span>
                    <time>22:47</time>
                  </button>
                </li>
                <li>
                  <button type="button" className="wx-row" onClick={openOfficialAccount}>
                    <span className="wx-avatar wx-official-avatar" aria-hidden="true">后勤</span>
                    <span className="wx-row-main"><strong>{chapterFourWechatContent.official.name}</strong><em>{chapterFourWechatContent.official.articleTitle}</em></span>
                    <time>22:40</time>
                  </button>
                </li>
              </>
            ) : null}
            <li>
              <button
                type="button"
                className="wx-row"
                onClick={() => chapterFourWechat.active
                  ? setChapterFourChatView("archive")
                  : kit.flags.toast("文件传输助手：只有你给自己发的表情包。")}
              >
                <span className="wx-avatar file-helper" aria-hidden="true" />
                <span className="wx-row-main">
                  <strong>文件传输助手</strong>
                  <em>{chapterFourWechat.active ? `已保存 ${chapterFourWechat.archiveCount} 项现场资料` : "[图片]"}</em>
                </span>
                <time>09:28</time>
              </button>
            </li>
            <li>
              <button
                type="button"
                className="wx-row"
                onClick={openFriendConversation}
                aria-label="打开朋友聊天"
              >
                <span
                  className={`wx-avatar friend-avatar slash-${slashState}`}
                  role="button"
                  tabIndex={0}
                  aria-label="朋友头像"
                  onClick={clickFriendAvatar}
                  onKeyDown={(e) => {
                    if (e.key === "Enter" || e.key === " ") {
                      e.preventDefault();
                      clickFriendAvatar(e as unknown as React.MouseEvent);
                    }
                  }}
                >
                  {slashState !== "gone" ? (
                    <i className="slash-top" aria-hidden="true" />
                  ) : null}
                  {slashState === "half" ? (
                    <i className="slash-hang" aria-hidden="true" />
                  ) : null}
                </span>
                <span className="wx-row-main">
                  <strong>朋友</strong>
                  <em>
                    {qizhenLocationChat
                      ? "你到底到哪了？"
                      : followupVisible
                      ? followupPending ? "成功了吗" : "？"
                      : flags.codeScattered
                      ? "这是签到码 ▓▓▓▓"
                      : "快快老师在点名，学在浙大"}
                  </em>
                </span>
                <time>07:55</time>
              </button>
            </li>
            <li>
              <button
                type="button"
                className="wx-row"
                onClick={() =>
                  kit.flags.toast("室友：还有 12 秒进入梦乡最深处。")
                }
              >
                <span
                  className="wx-avatar roommate-avatar"
                  aria-hidden="true"
                />
                <span className="wx-row-main">
                  <strong>室友</strong>
                  <em>晚上一起去食堂吃饭呀~</em>
                </span>
                <time>07:21</time>
              </button>
            </li>
            <li>
              <button
                type="button"
                className="wx-row"
                onClick={() => kit.flags.toast("导师：实验报告仍然不会自己完成。")}
              >
                <span
                  className={`wx-avatar mentor-avatar ${mentorLineFalling ? "is-line-falling" : ""} ${state.actOne.mentorLineReleased ? "is-line-released" : ""} ${movementQuestActive && !state.actOne.mentorLineReleased ? "is-stuck-target" : ""} ${mentorHintStep > 0 ? `hint-stage-${Math.min(mentorHintStep, 3)}` : ""}`}
                  role="button"
                  tabIndex={movementQuestActive ? 0 : -1}
                  aria-label="导师头像上的竖线"
                  data-drop-target={movementQuestActive && !state.actOne.mentorLineReleased ? "mentor_avatar" : undefined}
                  onClick={clickMentorAvatar}
                  onKeyDown={(event) => {
                    if (event.key === "Enter" || event.key === " ") {
                      event.preventDefault();
                      clickMentorAvatar(event);
                    }
                  }}
                >
                  {!state.actOne.mentorLineReleased || mentorLineFalling ? <i className="mentor-stuck-line" aria-hidden="true" /> : null}
                  {movementQuestActive && !state.actOne.mentorLineReleased ? (
                    <span className="mentor-stuck-ornaments" aria-hidden="true">
                      <i className="mentor-clamp clamp-top" />
                      <i className="mentor-clamp clamp-bottom" />
                      <i className="mentor-glue glue-left" />
                      <i className="mentor-glue glue-right" />
                      <i className="mentor-stuck-glint" />
                    </span>
                  ) : null}
                </span>
                <span className="wx-row-main">
                  <strong>导师</strong>
                  <em>
                    {movementQuestActive && !state.actOne.mentorLineReleased
                      ? mentorHintStep >= 2
                        ? "头像胶缝里似乎缺一点能流动的东西。"
                        : mentorHintStep >= 1
                          ? "两枚卡扣在发亮，中间的竖线还是拔不动。"
                          : "头像框中间多了一条被封住的竖线。"
                      : "请把实验报告的初稿发我一下。"}
                  </em>
                </span>
                <time>07:18</time>
              </button>
            </li>
          </ul>

          <nav className="wx-tabs" aria-hidden="true">
            <span className="is-active">
              <i className="tab-chat" />
              聊天
            </span>
            <span>
              <i className="tab-contact" />
              联系人
            </span>
            <span>
              <i className="tab-discover" />
              探索
            </span>
            <span>
              <i className="tab-me" />
              我的
            </span>
          </nav>
        </div>
      ) : (
        <div className={`wx-chat ${attackPhase === 2 ? "is-smashed" : ""}`}>
          <header className="wx-header">
            <PhoneNavButton
              kind="back"
              className="wx-back"
              onClick={() => setOpenedFriend(false)}
              label="返回聊天列表"
            />
            <h1>朋友</h1>
            <span className="wx-header-tools" aria-hidden="true">
              …
            </span>
          </header>

          <div className="wx-chat-body">
            <div className="wx-msg">
              <span className="wx-msg-avatar" aria-hidden="true">
                <i />
              </span>
              <p>快快老师在点名，学在浙大。</p>
            </div>
            {flags.codeScattered || attackPhase >= 1 ? (
              <div className="wx-msg">
                <span className="wx-msg-avatar" aria-hidden="true">
                  <i />
                </span>
                <p className="wx-code-msg">
                  这是签到码{" "}
                  {flags.codeScattered && attackPhase === 0 ? (
                    <span className="code-holes">▢▢▢▢</span>
                  ) : (
                    <span
                      className={`code-digits ${attackPhase >= 3 ? "is-flying" : ""}`}
                    >
                      <b className="fly-1">▓</b>
                      <b className="fly-2">▓</b>
                      <b className="fly-3">▓</b>
                      <b className="fly-4">▓</b>
                    </span>
                  )}
                </p>
              </div>
            ) : null}

            {attackPhase >= 2 && attackPhase < 4 ? (
              <div className="xiaoying-burst" role="alert">
                <span className="xiaoying-eye" aria-hidden="true" />
                <strong>等等等等，你想翘课？没门！</strong>
                <span>我不会让你签上的！</span>
                {attackPhase >= 3 ? (
                  <span className="xy-laugh">找你的数字去吧哈哈哈</span>
                ) : null}
              </div>
            ) : null}

            {attackPhase === 2 && attackSkippable ? (
              <button
                type="button"
                className="wx-attack-skip"
                aria-label="跳过小影语音"
                onClick={skipAttackVoice}
              />
            ) : null}

            {followupStep >= 1 ? (
              <div className="wx-msg wx-followup-message wx-followup-message--incoming">
                <span className="wx-msg-avatar" aria-hidden="true"><i /></span>
                <p>成功了吗</p>
              </div>
            ) : null}
            {followupStep === 1 ? (
              <div className="wx-reply-composer" aria-hidden="true">
                <span /><span /><span />
              </div>
            ) : null}
            {followupStep >= 2 ? (
              <div className={`wx-msg is-self wx-followup-message wx-followup-message--self ${followupStep === 2 ? "is-sending" : "is-sent"}`}>
                <p>没有，但我正试着威胁系统</p>
                <i className="wx-send-trace" aria-hidden="true" />
              </div>
            ) : null}
            {followupStep === 2 ? (
              <div className="wx-friend-typing" aria-hidden="true">
                <span className="wx-msg-avatar"><i /></span>
                <b><i /><i /><i /></b>
              </div>
            ) : null}
            {followupStep >= 3 ? (
              <div className="wx-msg wx-followup-message wx-followup-message--question">
                <span className="wx-msg-avatar" aria-hidden="true"><i /></span>
                <p>？</p>
              </div>
            ) : null}

            {qizhenLocationChat ? (
              <section className="wx-qizhen-location-chat" aria-label="启真湖地点线索">
                {qizhenContent.locationSearch.wechat.slice(0, qizhenChatStep).map((line) => (
                  <div key={line} className={`wx-msg wx-qizhen-message ${line.startsWith("自动回复：") ? "is-self" : ""}`.trim()}>
                    {!line.startsWith("自动回复：") ? <span className="wx-msg-avatar" aria-hidden="true"><i /></span> : null}
                    <p>{line}</p>
                  </div>
                ))}
                {qizhenChatStep === qizhenContent.locationSearch.wechat.length ? (
                  <button type="button" className="wx-qizhen-save-clue" onClick={collectLakeKeyword} disabled={state.qizhenLake.lakeClueFound}>
                    {state.qizhenLake.lakeClueFound ? "已保存地点词：湖面" : "保存地点词：湖面"}
                  </button>
                ) : null}
              </section>
            ) : null}

            {followupVisible && !followupPending ? (
              <div className="task-update">任务：找到系统</div>
            ) : flags.codeScattered && !flags.checkinDone && attackPhase !== 2 && attackPhase !== 3 ? (
              <div className="task-update">任务：找回四位签到码</div>
            ) : null}
          </div>
        </div>
      )}
    </section>
  );
}
