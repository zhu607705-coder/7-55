import React, { useEffect, useMemo, useRef, useState } from "react";
import { createRoot } from "react-dom/client";
import {
  FINALE_ENVIRONMENTS,
  type FinaleEnvironmentAsset,
  type FinaleEnvironmentId
} from "../scenes/rpg/FinaleEnvironmentTextures";
import {
  FINALE_NPC_ANIMATIONS,
  type FinaleNpcAnimationAsset,
  type FinaleNpcAnimationId
} from "../scenes/rpg/FinaleNpcTextures";

const DEFAULT_SCENE: FinaleEnvironmentId = "finale_1f_lobby_maxwell";
const DEFAULT_ACTOR: FinaleNpcAnimationId = "student_walk";

function clamp(value: number, min: number, max: number): number {
  return Math.min(max, Math.max(min, value));
}

function ActorOverlay({
  asset,
  world,
  position,
  scale
}: {
  asset: FinaleNpcAnimationAsset;
  world: { width: number; height: number };
  position: { x: number; y: number };
  scale: number;
}) {
  const [frame, setFrame] = useState(0);

  useEffect(() => {
    setFrame(0);
    if (asset.frameCount <= 1) return undefined;
    const timer = window.setInterval(() => {
      setFrame((current) => (current + 1) % asset.frameCount);
    }, 1000 / asset.fps);
    return () => window.clearInterval(timer);
  }, [asset]);

  return (
    <div
      className="actor-frame"
      aria-label={`角色比例参考：${asset.id}`}
      style={{
        left: `${position.x / world.width * 100}%`,
        top: `${position.y / world.height * 100}%`,
        width: `${asset.frameWidth * scale / world.width * 100}%`,
        height: `${asset.frameHeight * scale / world.height * 100}%`
      }}
    >
      <div
        className="actor-sheet"
        style={{
          width: `${asset.frameCount * 100}%`,
          backgroundImage: `url(${asset.url})`,
          transform: `translateX(${-frame / asset.frameCount * 100}%)`
        }}
      />
      <i className="actor-foot" />
    </div>
  );
}

function EnvironmentStage({
  scene,
  actor,
  actorScale,
  position,
  showGrid,
  onPositionChange
}: {
  scene: FinaleEnvironmentAsset;
  actor: FinaleNpcAnimationAsset;
  actorScale: number;
  position: { x: number; y: number };
  showGrid: boolean;
  onPositionChange: (position: { x: number; y: number }) => void;
}) {
  const stageRef = useRef<HTMLDivElement>(null);
  const dragging = useRef(false);

  const placeActor = (event: React.PointerEvent<HTMLDivElement>) => {
    const rect = stageRef.current?.getBoundingClientRect();
    if (!rect) return;
    const x = (event.clientX - rect.left) / rect.width * scene.sourceSize.width;
    const y = (event.clientY - rect.top) / rect.height * scene.sourceSize.height;
    onPositionChange({
      x: Math.round(clamp(x, 48, scene.sourceSize.width - 48)),
      y: Math.round(clamp(y, 128, scene.sourceSize.height - 12))
    });
  };

  return (
    <div
      ref={stageRef}
      className={`environment-stage${showGrid ? " show-grid" : ""}`}
      onPointerDown={(event) => {
        dragging.current = true;
        event.currentTarget.setPointerCapture(event.pointerId);
        placeActor(event);
      }}
      onPointerMove={(event) => {
        if (dragging.current) placeActor(event);
      }}
      onPointerUp={(event) => {
        dragging.current = false;
        event.currentTarget.releasePointerCapture(event.pointerId);
      }}
      onPointerCancel={() => {
        dragging.current = false;
      }}
    >
      <img src={scene.url} alt={`${scene.title}环境母图`} draggable={false} />
      <ActorOverlay
        asset={actor}
        world={scene.sourceSize}
        position={position}
        scale={actorScale}
      />
    </div>
  );
}

function FinaleEnvironmentDebug() {
  const scenes = useMemo(() => Object.values(FINALE_ENVIRONMENTS), []);
  const actors = useMemo(() => Object.values(FINALE_NPC_ANIMATIONS), []);
  const [sceneId, setSceneId] = useState<FinaleEnvironmentId>(DEFAULT_SCENE);
  const [actorId, setActorId] = useState<FinaleNpcAnimationId>(DEFAULT_ACTOR);
  const [actorScale, setActorScale] = useState(1);
  const [showGrid, setShowGrid] = useState(false);
  const [position, setPosition] = useState({ x: 836, y: 760 });
  const scene = FINALE_ENVIRONMENTS[sceneId];
  const actor = FINALE_NPC_ANIMATIONS[actorId];

  return (
    <main className="debug-page">
      <header>
        <div>
          <p className="eyebrow">《7:55》终章 · 环境与人物合成检查</p>
          <h1>段永平教学楼环境母图</h1>
          <p>点击或拖动场景放置实际 NPC，用源坐标检查比例、动线和后续碰撞落点。</p>
        </div>
        <div className="header-facts">
          <span>{scenes.length} 张环境图</span>
          <span>1672×941</span>
          <span>Phaser 运行层</span>
        </div>
      </header>

      <nav className="scene-tabs" aria-label="终章环境场景">
        {scenes.map((entry) => (
          <button
            key={entry.id}
            type="button"
            className={entry.id === sceneId ? "is-active" : ""}
            onClick={() => setSceneId(entry.id)}
          >
            <strong>{entry.title}</strong>
            <span>{entry.projection === "top_down_orthographic" ? "俯视" : "序幕侧视"}</span>
          </button>
        ))}
      </nav>

      <section className="workspace">
        <EnvironmentStage
          scene={scene}
          actor={actor}
          actorScale={actorScale}
          position={position}
          showGrid={showGrid}
          onPositionChange={setPosition}
        />

        <aside>
          <div>
            <p className="aside-label">当前场景</p>
            <h2>{scene.title}</h2>
            <p>{scene.purpose}</p>
          </div>

          <dl>
            <div><dt>投影</dt><dd>{scene.projection}</dd></div>
            <div><dt>时间单元</dt><dd>{scene.temporalCellId ?? "当前清楼时间"}</dd></div>
            <div><dt>人物坐标</dt><dd>{position.x}, {position.y}</dd></div>
          </dl>

          <label>
            角色动作
            <select value={actorId} onChange={(event) => setActorId(event.target.value as FinaleNpcAnimationId)}>
              {actors.map((entry) => <option key={entry.id} value={entry.id}>{entry.id}</option>)}
            </select>
          </label>

          <label>
            角色倍率 <output>{actorScale.toFixed(2)}×</output>
            <input
              type="range"
              min="0.7"
              max="1.6"
              step="0.05"
              value={actorScale}
              onChange={(event) => setActorScale(Number(event.target.value))}
            />
          </label>

          <label className="toggle">
            <input type="checkbox" checked={showGrid} onChange={(event) => setShowGrid(event.target.checked)} />
            显示源坐标网格
          </label>

          <div>
            <p className="aside-label">保持为动态层</p>
            <div className="tags">
              {scene.dynamicLayers.map((layer) => <span key={layer}>{layer}</span>)}
            </div>
          </div>
        </aside>
      </section>
    </main>
  );
}

const style = document.createElement("style");
style.textContent = `
  :root { color-scheme: dark; font-family: "Fusion Pixel 12px Proportional SC", monospace; }
  * { box-sizing: border-box; }
  body { margin: 0; background: #071015; color: #eef3e9; }
  button, select, input { font: inherit; }
  .debug-page { min-height: 100vh; padding: 24px; background: radial-gradient(circle at 20% 0, #17313a 0, #071015 44%); }
  header, .scene-tabs, .workspace { width: min(1480px, 100%); margin-inline: auto; }
  header { display: flex; align-items: flex-end; justify-content: space-between; gap: 24px; padding: 20px 22px; border: 1px solid #617b78; background: rgba(7, 16, 21, .9); }
  h1, h2, p { margin: 0; }
  h1 { margin-top: 7px; font-size: clamp(24px, 3vw, 34px); }
  h2 { margin-bottom: 8px; color: #f2d75a; font-size: 20px; }
  .eyebrow { color: #79d7dc; }
  header p:last-child, aside p { margin-top: 8px; color: #a8b7b5; line-height: 1.55; }
  .header-facts { display: flex; flex-wrap: wrap; justify-content: flex-end; gap: 8px; }
  .header-facts span { padding: 7px 9px; border: 1px solid #425e5c; background: #101f23; color: #b9d7d2; white-space: nowrap; }
  .scene-tabs { display: grid; grid-template-columns: repeat(6, minmax(130px, 1fr)); gap: 8px; margin-top: 12px; }
  .scene-tabs button { display: grid; gap: 4px; min-height: 66px; padding: 10px; border: 1px solid #415754; background: #101c20; color: #d9e3dd; text-align: left; cursor: pointer; }
  .scene-tabs button span { color: #88a29f; font-size: 11px; }
  .scene-tabs button:hover, .scene-tabs button.is-active { border-color: #f2d75a; background: #1a282a; }
  .scene-tabs button.is-active strong { color: #f2d75a; }
  .workspace { display: grid; grid-template-columns: minmax(0, 1fr) 300px; gap: 12px; margin-top: 12px; align-items: start; }
  .environment-stage { position: relative; aspect-ratio: 1672 / 941; overflow: hidden; border: 1px solid #6d8480; background: #030709; touch-action: none; cursor: crosshair; }
  .environment-stage > img { display: block; width: 100%; height: 100%; object-fit: contain; image-rendering: pixelated; user-select: none; }
  .environment-stage.show-grid::after { content: ""; position: absolute; inset: 0; pointer-events: none; background-image: linear-gradient(rgba(121, 215, 220, .18) 1px, transparent 1px), linear-gradient(90deg, rgba(121, 215, 220, .18) 1px, transparent 1px); background-size: calc(100% / 16) calc(100% / 9); }
  .actor-frame { position: absolute; overflow: hidden; transform: translate(-50%, -100%); z-index: 3; image-rendering: pixelated; filter: drop-shadow(0 2px 1px rgba(0, 0, 0, .7)); pointer-events: none; }
  .actor-sheet { position: absolute; inset: 0 auto 0 0; height: 100%; background-repeat: no-repeat; background-size: 100% 100%; image-rendering: pixelated; }
  .actor-foot { position: absolute; left: 25%; right: 25%; bottom: 0; height: 2px; background: #f2d75a; box-shadow: 0 0 5px #f2d75a; }
  aside { display: grid; gap: 18px; padding: 18px; border: 1px solid #617b78; background: rgba(8, 17, 21, .94); }
  .aside-label { color: #79d7dc; font-size: 12px; }
  dl { display: grid; gap: 8px; margin: 0; }
  dl div { display: grid; grid-template-columns: 88px 1fr; gap: 8px; }
  dt { color: #8da19e; }
  dd { margin: 0; overflow-wrap: anywhere; color: #dce8e1; }
  label { display: grid; gap: 8px; color: #c7d4ce; }
  select { width: 100%; padding: 8px; border: 1px solid #4a6360; background: #102025; color: #eef3e9; }
  label output { justify-self: end; margin-top: -22px; color: #f2d75a; }
  .toggle { display: grid; grid-template-columns: auto 1fr; align-items: center; justify-content: start; }
  .tags { display: flex; flex-wrap: wrap; gap: 6px; margin-top: 8px; }
  .tags span { padding: 5px 7px; border: 1px solid #3b5755; color: #9ed7d4; font-size: 11px; overflow-wrap: anywhere; }
  @media (max-width: 1040px) { .scene-tabs { grid-template-columns: repeat(3, 1fr); } .workspace { grid-template-columns: 1fr; } aside { grid-template-columns: repeat(2, minmax(0, 1fr)); } }
  @media (max-width: 620px) { .debug-page { padding: 12px; } header { align-items: stretch; flex-direction: column; } .header-facts { justify-content: flex-start; } .scene-tabs { grid-template-columns: repeat(2, 1fr); } .workspace { gap: 8px; } aside { grid-template-columns: 1fr; padding: 14px; } }
`;
document.head.appendChild(style);

createRoot(document.getElementById("root")!).render(<FinaleEnvironmentDebug />);
