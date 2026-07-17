import type { SceneComponentProps } from "../../../components/ScenePlaceholder";

export function ChapterTransitionScene({ state, router }: SceneComponentProps) {
  return (
    <section className="chapter-transition-screen" aria-label="第三章完成">
      <div className="chapter-transition-track" aria-hidden="true">
        <i /><i /><i />
        <span>755</span>
      </div>
      <main>
        <span className="chapter-transition-time">07:56</span>
        <p>CHAPTER 03 · CLEAR</p>
        <h1>下一章</h1>
        <strong>下一任务将在校园内继续。</strong>
        <dl>
          <div><dt>距离</dt><dd>{Math.round(state.bikeArcade.bestDistance)}m</dd></div>
          <div><dt>剩余机会</dt><dd>{state.bikeArcade.bestLives}</dd></div>
          <div><dt>尝试</dt><dd>{state.bikeArcade.attemptCount}</dd></div>
        </dl>
        <button type="button" onClick={() => router.goTo("phone_home")}>返回手机桌面</button>
        <button type="button" className="secondary" onClick={() => router.goTo("bike_arcade")}>重玩求是潮</button>
      </main>
    </section>
  );
}
