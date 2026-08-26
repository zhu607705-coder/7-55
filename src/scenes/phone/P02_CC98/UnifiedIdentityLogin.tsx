import { useEffect, useMemo, useState, type FormEvent } from "react";
import type { GameState } from "../../../core/types";
import actOneContent from "../../../data/act-one-bootstrap.content.json";
import {
  CC98_LOGIN_FREE_ATTEMPTS,
  CC98_LOGIN_HINTS,
  CC98_LOGIN_STUDENT_ID,
  getCc98LoginRemainingMs
} from "../../../modules/Cc98UnifiedLoginModel";
import { kit } from "../../../modules/GameKit";

interface UnifiedIdentityLoginProps {
  state: GameState;
  onExit: () => void;
}

function formatWaitSeconds(remainingMs: number): string {
  return `${Math.max(0, Math.ceil(remainingMs / 1000))}s`;
}

export function UnifiedIdentityLogin({ state, onExit }: UnifiedIdentityLoginProps) {
  const login = state.actOne.cc98Login;
  const [studentId, setStudentId] = useState("");
  const [password, setPassword] = useState("");
  const [passwordVisible, setPasswordVisible] = useState(false);
  const [feedback, setFeedback] = useState("先从随身校园卡确认账号，再拆开密码提示。");
  const [nowMs, setNowMs] = useState(() => Date.now());
  const remainingMs = getCc98LoginRemainingMs(login, nowMs);
  const locked = remainingMs > 0;
  const immediateAttemptsLeft = Math.max(0, CC98_LOGIN_FREE_ATTEMPTS - login.failureCount);
  const nextPenaltySeconds = Math.max(30, (login.failureCount - CC98_LOGIN_FREE_ATTEMPTS + 2) * 30);

  const revealedHints = useMemo(
    () => CC98_LOGIN_HINTS.slice(0, login.revealedHintCount),
    [login.revealedHintCount]
  );

  useEffect(() => {
    if (!locked) return;
    const timer = window.setInterval(() => setNowMs(Date.now()), 250);
    return () => window.clearInterval(timer);
  }, [locked, login.lockUntilMs]);

  function readCampusCard() {
    const result = kit.actOne.discoverCc98StudentId();
    if (result === "campus_card_required") {
      setFeedback("随身物品里没有校园卡，当前无法确认 10 位学号。");
      return;
    }
    setStudentId(CC98_LOGIN_STUDENT_ID);
    setFeedback(`校园卡已读取：${actOneContent.studentName}，学号已填入。`);
  }

  function revealNextHint() {
    const count = kit.actOne.revealCc98LoginHint();
    const hint = CC98_LOGIN_HINTS[count - 1];
    if (hint) {
      setFeedback(`提示 ${count}/3 已展开：${hint.clue}`);
    } else {
      setFeedback("三段密码提示已经全部展开，按顺序拼接即可。");
    }
  }

  function submitLogin(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const result = kit.actOne.submitCc98Login(studentId, password);
    if (result.status === "authenticated" || result.status === "already_authenticated") {
      setFeedback("认证通过，正在进入 CC98。");
      return;
    }
    if (result.status === "identity_unavailable") {
      setFeedback("先读取校园卡上的学号，再提交认证。");
      return;
    }
    if (result.status === "locked") {
      setNowMs(Date.now());
      setFeedback(`尝试暂时锁定，还需等待 ${formatWaitSeconds(result.remainingMs)}。`);
      return;
    }
    setPassword("");
    setNowMs(Date.now());
    const mismatch = result.reason === "student_id"
      ? "学号与校园卡不一致。"
      : result.reason === "password"
        ? "密码片段、顺序或大小写不正确。"
        : "学号和密码均未通过核验。";
    setFeedback(result.lockDurationMs > 0
      ? `${mismatch} 已累计 ${result.failureCount} 次失败，等待 ${formatWaitSeconds(result.lockDurationMs)} 后可重试。`
      : `${mismatch} 还可立即尝试 ${CC98_LOGIN_FREE_ATTEMPTS - result.failureCount} 次。`
    );
  }

  return (
    <section className="app-screen cc98-unified-login" aria-label="浙江大学统一身份认证解谜">
      <div className="cc98-login-backdrop" aria-hidden="true" />
      <header className="cc98-login-brand">
        <span className="cc98-login-seal" aria-hidden="true"><i>Z</i></span>
        <div>
          <strong>浙江大学统一身份认证</strong>
          <small>UNIFIED IDENTITY AUTHENTICATION</small>
        </div>
      </header>

      <main className="cc98-login-scroll">
        <section className="cc98-login-panel" aria-label="浙大通行证登录">
          <header>
            <div>
              <small>首次进入 CC98</small>
              <h1>浙大通行证</h1>
            </div>
            <span className="cc98-login-qr" aria-hidden="true"><i /><i /><i /></span>
          </header>

          <form onSubmit={submitLogin}>
            <label className="cc98-login-field">
              <span aria-hidden="true">ID</span>
              <input
                value={studentId}
                onChange={(event) => setStudentId(event.target.value.replace(/\D/g, "").slice(0, 10))}
                inputMode="numeric"
                autoComplete="off"
                placeholder="10 位学号"
                aria-label="统一身份认证学号"
              />
            </label>
            <label className="cc98-login-field">
              <span aria-hidden="true">KEY</span>
              <input
                value={password}
                onChange={(event) => setPassword(event.target.value.slice(0, 24))}
                type={passwordVisible ? "text" : "password"}
                autoComplete="off"
                placeholder="按提示组合密码"
                aria-label="统一身份认证密码"
              />
              <button
                type="button"
                className="cc98-password-visibility"
                aria-pressed={passwordVisible}
                onClick={() => setPasswordVisible((current) => !current)}
              >
                {passwordVisible ? "隐藏" : "显示"}
              </button>
            </label>

            <div className="cc98-login-attempts" aria-live="polite">
              <span>失败记录 {login.failureCount}</span>
              {locked
                ? <strong>锁定 {formatWaitSeconds(remainingMs)}</strong>
                : <strong>{immediateAttemptsLeft > 0 ? `立即机会 ${immediateAttemptsLeft}/3` : `下次失败等待 ${nextPenaltySeconds}s`}</strong>}
            </div>

            <button
              className="cc98-login-submit"
              type="submit"
              disabled={locked || !studentId || !password}
            >
              {locked ? `等待 ${formatWaitSeconds(remainingMs)}` : "登 录"}
            </button>
          </form>

          <p className="cc98-login-feedback" role="status" aria-live="polite">{feedback}</p>
        </section>

        <section className="cc98-login-evidence" aria-label="认证线索">
          <header>
            <div><small>本地找回</small><strong>认证线索</strong></div>
            <span>{login.revealedHintCount}/3</span>
          </header>

          <button type="button" className="cc98-campus-card-clue" onClick={readCampusCard}>
            <span className="cc98-mini-card" aria-hidden="true"><i>ZJU</i><b>07:55</b></span>
            <span>
              <strong>{login.studentIdDiscovered ? "校园卡身份已读取" : "查看随身校园卡"}</strong>
              <small>{login.studentIdDiscovered ? `${actOneContent.studentName} · ${actOneContent.studentId}` : "卡面记录了持卡人的 10 位学号"}</small>
            </span>
            <b>{login.studentIdDiscovered ? "填入" : "读取"}</b>
          </button>

          <ol className="cc98-password-clues">
            {CC98_LOGIN_HINTS.map((hint, index) => {
              const revealed = index < login.revealedHintCount;
              return (
                <li key={hint.id} className={revealed ? "is-revealed" : ""}>
                  <span>{index + 1}</span>
                  <div>
                    <strong>{revealed ? hint.label : "待解锁片段"}</strong>
                    <small>{revealed ? hint.clue : "展开上一条提示后显示"}</small>
                  </div>
                  <b>{revealed ? hint.fragment : "•••"}</b>
                </li>
              );
            })}
          </ol>

          <button
            type="button"
            className="cc98-reveal-hint"
            onClick={revealNextHint}
            disabled={login.revealedHintCount >= CC98_LOGIN_HINTS.length}
          >
            {login.revealedHintCount >= CC98_LOGIN_HINTS.length ? "提示已全部展开" : `展开提示 ${login.revealedHintCount + 1}`}
          </button>
        </section>

        <p className="cc98-login-local-note">剧情内离线认证 · 不连接真实账号服务</p>
      </main>

      <button type="button" className="cc98-login-exit" onClick={onExit}>退出认证</button>
    </section>
  );
}
