import { useEffect, useState } from "react";
import { PhoneNavButton } from "../../../components/PhoneNavButton";
import type { SceneComponentProps } from "../../../components/ScenePlaceholder";
import actOneContent from "../../../data/act-one-bootstrap.content.json";
import { kit } from "../../../modules/GameKit";
import { playSfx } from "../../../modules/Sfx";

/**
 * P04 校园卡余额（浙大钉「我的」页）：第二章取得校园卡后显示余额并承接右移箭头交互。
 */
export function CampusCardScene({ state, router, events }: SceneComponentProps) {
  const [balanceAnimating, setBalanceAnimating] = useState(false);
  const movementQuestActive = state.actOne.phase === "movement_required" || state.actOne.phase === "movement_ready";
  const shifted = state.actOne.balanceShifted;

  useEffect(() => {
    let timer: number | null = null;
    const unsubscribe = events.subscribe((event) => {
      if (event.name !== "item_dropped" || event.payload?.target !== "campus_card_balance") {
        return;
      }
      if (event.payload?.item !== "rightArrow") {
        playSfx("04_", { volume: 0.5 });
        kit.flags.toast("余额没有向任何方向移动。", "system");
        return;
      }
      if (!kit.actOne.shiftBalance()) {
        kit.flags.toast("这个箭头还不能改动余额。", "system");
        return;
      }
      setBalanceAnimating(true);
      timer = window.setTimeout(() => setBalanceAnimating(false), 1100);
      kit.flags.toast("小数点向右移动两位：余额 ¥6.00", "task");
    });
    return () => {
      unsubscribe();
      if (timer !== null) {
        window.clearTimeout(timer);
      }
    };
  }, [events]);

  function returnToZjuding() {
    kit.flags.setUi("zjudingPage", "hub");
    router.goTo("zjuding");
  }

  return (
    <section className="app-screen campus-card" aria-label="校园卡">
      <header className="card-actions" aria-hidden="true">
        <span>
          <i className="ca-ico scan" />
          扫一扫
        </span>
        <span>
          <i className="ca-ico pay" />
          付款码
        </span>
        <span>
          <i className="ca-ico charge" />
          卡片充值
        </span>
        <span>
          <i className="ca-ico wallet" />
          卡包
        </span>
      </header>

      <article className="zju-card px-panel-dark">
        <header className="zju-card-head">
          <i className="zju-badge" aria-hidden="true" />
          <h1>浙江大学</h1>
          <small>ZHEJIANG UNIVERSITY</small>
        </header>
        <div className="zju-card-body">
          <div className="zju-photo" aria-hidden="true">
            <i className="hair" />
            <i className="face" />
            <i className="hoodie" />
          </div>
          <dl className="zju-fields">
            <div>
              <dt>学　号：</dt>
              <dd>{actOneContent.studentId}</dd>
            </div>
            <div>
              <dt>姓　名：</dt>
              <dd>{actOneContent.studentName}</dd>
            </div>
            <div>
              <dt>卡账户：</dt>
              <dd>1000100000</dd>
            </div>
            <div className="balance-row">
              <dt>校园卡余额：</dt>
              <dd
                className={`balance-value ${movementQuestActive ? "is-act2-target" : ""} ${shifted ? "is-shifted" : ""} ${balanceAnimating ? "is-shifting" : ""}`}
                data-drop-target={movementQuestActive && !shifted ? "campus_card_balance" : undefined}
              >
                {movementQuestActive ? (
                  <>
                    ¥<span className="act2-balance-number">{shifted ? "6.00" : "0.06"}</span>
                    {balanceAnimating ? <i className="balance-shift-arrow" aria-hidden="true">→</i> : null}
                  </>
                ) : (
                  <>¥<span>0.06</span></>
                )}
              </dd>
            </div>
          </dl>
        </div>
        <div className="zju-wallet-row">
          <i className="coin" aria-hidden="true" />
          我的零钱：<strong>{shifted ? "¥6.00" : "¥0.06"}</strong>
          <span aria-hidden="true">›</span>
        </div>
      </article>

      <section className="card-shortcuts" aria-hidden="true">
        <span>
          <i className="cs-ico bill" />
          账单
        </span>
        <span>
          <i className="cs-ico pay2" />
          付款码
        </span>
        <span>
          <i className="cs-ico charge2" />
          卡片充值
        </span>
        <span>
          <i className="cs-ico lost" />
          挂失·解挂
        </span>
      </section>

      <section className="card-news px-panel" aria-hidden="true">
        <header>
          <strong>▎校园新闻</strong>
          <em>查看全部 ›</em>
        </header>
        <p>浙江大学图书馆暑期开放安排通知！</p>
        <div className="news-banner">2026 年暑期图书馆开放安排</div>
        <footer>1天前 · 校园资讯中心</footer>
      </section>

      <PhoneNavButton kind="back" className="app-back px-btn paper" onClick={returnToZjuding} label="返回浙大钉" />

      <nav className="card-nav" aria-hidden="true">
        <span className="is-active">首页</span>
        <span>资讯</span>
        <span className="qr">校园码</span>
        <span>应用</span>
        <span>我的</span>
      </nav>
    </section>
  );
}
