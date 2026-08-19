import React, { useEffect, useMemo, useState } from "react";
import { createRoot } from "react-dom/client";
import {
  FINALE_NPC_ANIMATIONS,
  type FinaleNpcAnimationAsset,
  type FinaleNpcAnimationId
} from "../scenes/rpg/FinaleNpcTextures";

const CHARACTER_GROUPS = [
  { title: "远处离楼学生", prefix: "student_" },
  { title: "保洁员与清洁车", prefix: "cleaner_", extras: ["cleaning_cart"] },
  { title: "清楼保安", prefix: "guard_" }
] as const;

function AnimationCard({ asset, scale }: { asset: FinaleNpcAnimationAsset; scale: number }) {
  const [frame, setFrame] = useState(0);

  useEffect(() => {
    setFrame(0);
    if (asset.frameCount <= 1) return undefined;
    const timer = window.setInterval(() => {
      setFrame((current) => {
        if (current + 1 < asset.frameCount) return current + 1;
        return asset.loop ? 0 : current;
      });
    }, 1000 / asset.fps);
    return () => window.clearInterval(timer);
  }, [asset]);

  return (
    <article className="animation-card">
      <div
        className="sprite-stage"
        style={{
          width: asset.frameWidth * scale,
          height: asset.frameHeight * scale
        }}
      >
        <div
          className="sprite-sheet"
          style={{
            width: asset.frameWidth * asset.frameCount * scale,
            height: asset.frameHeight * scale,
            backgroundImage: `url(${asset.url})`,
            backgroundSize: `${asset.frameWidth * asset.frameCount * scale}px ${asset.frameHeight * scale}px`,
            transform: `translateX(${-frame * asset.frameWidth * scale}px)`
          }}
        />
        <div className="anchor-line" />
      </div>
      <div className="animation-meta">
        <strong>{asset.id}</strong>
        <span>{asset.frameCount} 帧 · {asset.fps} FPS · {asset.frameWidth}×{asset.frameHeight}</span>
      </div>
    </article>
  );
}

function FinaleNpcDebug() {
  const [scale, setScale] = useState(1.5);
  const assets = useMemo(() => Object.values(FINALE_NPC_ANIMATIONS), []);

  return (
    <main className="debug-page">
      <header>
        <div>
          <p className="eyebrow">《7:55》终章 · 段永平教学楼</p>
          <h1>三名真人角色动画整合预览</h1>
          <p>统一脚底锚点、透明背景和像素缩放。黄色线表示运行时落脚基线。</p>
        </div>
        <label>
          预览倍率
          <input
            type="range"
            min="1"
            max="3"
            step="0.25"
            value={scale}
            onChange={(event) => setScale(Number(event.target.value))}
          />
          <output>{scale.toFixed(2)}×</output>
        </label>
      </header>

      {CHARACTER_GROUPS.map((group) => {
        const groupAssets = assets.filter((asset) => (
          asset.id.startsWith(group.prefix)
          || ("extras" in group && group.extras.includes(asset.id as "cleaning_cart"))
        ));
        return (
          <section key={group.title}>
            <h2>{group.title}</h2>
            <div className="animation-grid">
              {groupAssets.map((asset) => (
                <AnimationCard key={asset.id} asset={asset} scale={scale} />
              ))}
            </div>
          </section>
        );
      })}
    </main>
  );
}

const style = document.createElement("style");
style.textContent = `
  :root { color-scheme: dark; font-family: "Fusion Pixel 12px Proportional SC", monospace; }
  * { box-sizing: border-box; }
  body { margin: 0; background: #0a1014; color: #edf1e8; }
  .debug-page { min-height: 100vh; padding: 32px; background: radial-gradient(circle at top, #1b2c31 0, #0a1014 52%); }
  header { display: flex; justify-content: space-between; gap: 24px; align-items: flex-end; max-width: 1280px; margin: 0 auto 36px; padding: 24px; border: 1px solid #627b78; background: rgba(10, 17, 20, .86); }
  h1, h2, p { margin: 0; }
  h1 { margin-top: 8px; font-size: 28px; }
  h2 { margin-bottom: 14px; color: #f2d75a; font-size: 18px; }
  .eyebrow { color: #78d7dc; }
  header p:last-child { margin-top: 10px; color: #9fb3b0; }
  label { display: grid; grid-template-columns: 100px 190px 56px; gap: 10px; align-items: center; white-space: nowrap; }
  section { max-width: 1280px; margin: 0 auto 34px; }
  .animation-grid { display: flex; flex-wrap: wrap; gap: 14px; align-items: flex-start; }
  .animation-card { min-width: 210px; padding: 14px; border: 1px solid #405654; background: rgba(15, 25, 28, .92); }
  .sprite-stage { position: relative; margin: 0 auto 12px; overflow: hidden; background-color: #1c2d31; background-image: linear-gradient(45deg, #21363a 25%, transparent 25%), linear-gradient(-45deg, #21363a 25%, transparent 25%), linear-gradient(45deg, transparent 75%, #21363a 75%), linear-gradient(-45deg, transparent 75%, #21363a 75%); background-size: 16px 16px; background-position: 0 0, 0 8px, 8px -8px, -8px 0; image-rendering: pixelated; }
  .sprite-sheet { position: absolute; left: 0; top: 0; image-rendering: pixelated; background-repeat: no-repeat; }
  .anchor-line { position: absolute; left: 0; right: 0; bottom: 0; height: 2px; background: #f2d75a; opacity: .72; }
  .animation-meta { display: grid; gap: 5px; }
  .animation-meta strong { color: #78d7dc; font-size: 13px; }
  .animation-meta span { color: #9fb3b0; font-size: 12px; }
  @media (max-width: 760px) { .debug-page { padding: 18px; } header { align-items: stretch; flex-direction: column; } label { grid-template-columns: 84px 1fr 48px; } }
`;
document.head.appendChild(style);

createRoot(document.getElementById("root")!).render(<FinaleNpcDebug />);
