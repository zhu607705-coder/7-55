import { useEffect, useRef, useState } from "react";
import { PhoneNavButton } from "../../../components/PhoneNavButton";
import type { SceneComponentProps } from "../../../components/ScenePlaceholder";
import { kit } from "../../../modules/GameKit";
import { consumeFriendChatIntent } from "../../../modules/NavIntent";
import { playSfx } from "../../../modules/Sfx";
import { playVo, type VoPlaybackHandle } from "../../../modules/VoicePlayer";

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
  const { flags, ui } = state;
  const followupPending = state.actOne.phase === "friend_message_required";
  const followupVisible = flags.checkinDone && state.actOne.phase !== "prologue";
  const movementQuestActive = state.actOne.phase === "movement_required" || state.actOne.phase === "movement_ready";
  const [followupStep, setFollowupStep] = useState(followupVisible && !followupPending ? 3 : 0);
  const sequenceVoRef = useRef<VoPlaybackHandle | null>(null);

  // 首次进入朋友聊天：视觉节奏由剧情计时器控制，音频失败不影响推进。
  useEffect(() => {
    if (!openedFriend || flags.codeScattered) {
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
  }, [openedFriend, flags.codeScattered, events]);

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

  const slashState = flags.slashTaken
    ? "gone"
    : flags.slashHalfDropped
      ? "half"
      : "full";

  return (
    <section className="wechat-scene" aria-label="微信">
      {!openedFriend ? (
        <div className={`wx-list ${listTilt ? "is-tilting" : ""}`}>
          <header className="wx-header">
            <PhoneNavButton
              kind="exit"
              className="wx-back"
              onClick={() => router.goTo("phone_home")}
              label="退出微信，返回手机主页"
            />
            <h1>聊天(4)</h1>
            <span className="wx-header-tools" aria-hidden="true">
              ⌕ ⊕
            </span>
          </header>
          <div className="wx-device-tip">已登录 2 台设备 ›</div>

          <ul className="wx-rows">
            <li>
              <button
                type="button"
                className="wx-row"
                onClick={() =>
                  kit.flags.toast("文件传输助手：只有你给自己发的表情包。")
                }
              >
                <span className="wx-avatar file-helper" aria-hidden="true" />
                <span className="wx-row-main">
                  <strong>文件传输助手</strong>
                  <em>[图片]</em>
                </span>
                <time>09:28</time>
              </button>
            </li>
            <li>
              <button
                type="button"
                className="wx-row"
                onClick={() => setOpenedFriend(true)}
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
                    {followupVisible
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
