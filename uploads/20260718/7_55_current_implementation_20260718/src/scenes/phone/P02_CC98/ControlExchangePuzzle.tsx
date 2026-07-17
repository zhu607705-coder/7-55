import type { SceneRouter } from "../../../core/SceneRouter";
import actOneContent from "../../../data/act-one-bootstrap.content.json";
import { kit } from "../../../modules/GameKit";

interface ControlExchangePuzzleProps {
  router: Pick<SceneRouter, "goTo">;
  balanceShifted: boolean;
  purchased: boolean;
}

export function ControlExchangePuzzle({ router, balanceShifted, purchased }: ControlExchangePuzzleProps) {
  function purchase() {
    const result = kit.actOne.purchaseGamepad();
    if (result === "insufficient_balance") {
      kit.flags.toast("你只有 0.06 块。卖家拒绝 100 期免息。", "system");
      return;
    }
    if (result === "inactive") {
      kit.flags.toast("卖家暂时不认识这段剧情。", "system");
      return;
    }
    if (result === "already_owned") {
      kit.flags.toast("手柄已经在道具栏里。", "system");
      return;
    }
    kit.flags.toast("支付成功：获得游戏手柄。自动行走已停止。", "task");
  }

  function returnToDorm() {
    if (!kit.actOne.enterRpg("dorm_hub")) {
      router.goTo("phone_home");
    }
  }

  return (
    <section className={`cc98-control-exchange ${purchased ? "is-purchased" : ""}`} aria-label="CC98游戏手柄交易">
      <div className="cc98-control-preview" aria-hidden="true">
        <span className="gamepad-grip left" />
        <span className="gamepad-body"><i>＋</i><b>A</b><em>B</em></span>
        <span className="gamepad-grip right" />
      </div>
      <dl>
        <div><dt>商品</dt><dd>二手游戏手柄 × 1</dd></div>
        <div><dt>售价</dt><dd>¥6.00，不议价</dd></div>
        <div><dt>你的余额</dt><dd className={balanceShifted ? "is-enough" : "is-short"}>¥{balanceShifted ? "6.00" : "0.06"}</dd></div>
        <div><dt>收货人</dt><dd>{actOneContent.studentName} · {actOneContent.studentId}</dd></div>
      </dl>
      {purchased ? (
        <button type="button" onClick={returnToDorm}>回寝室试用手柄</button>
      ) : (
        <button type="button" onClick={purchase}>{actOneContent.cc98ExchangePost.action}</button>
      )}
    </section>
  );
}
