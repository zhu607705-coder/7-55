import { useRef, useState, type CSSProperties } from "react";
import { kit } from "../modules/GameKit";

/**
 * 第四章校时：覆盖在 RPG 画布右缘的半透明表冠。
 * 仅粗指针（触屏）布局挂载；收起态为 48px 圆钮，按住展开为拨盘，
 * 绕中心拖动按角度差累加校时（整圈 = 600 秒，与手机时钟页同一契约），
 * 松手或 pointercancel 收回收起态。拨盘外区域不拦截地图输入。
 */

const CROWN_SECONDS_PER_REVOLUTION = 600;

interface CrownDrag {
  pointerId: number;
  centerX: number;
  centerY: number;
  lastAngle: number;
  remainderSeconds: number;
}

export function RpgClockCrownOverlay() {
  const [expanded, setExpanded] = useState(false);
  const [rotationDeg, setRotationDeg] = useState(0);
  const dragRef = useRef<CrownDrag | null>(null);

  function handlePointerDown(event: React.PointerEvent<HTMLButtonElement>) {
    if (dragRef.current) return;
    event.preventDefault();
    const target = event.currentTarget;
    try {
      target.setPointerCapture(event.pointerId);
    } catch {
      // Pointer capture is optional in older WebKit and some embedded browsers.
    }
    const rect = target.getBoundingClientRect();
    const centerX = rect.left + rect.width / 2;
    const centerY = rect.top + rect.height / 2;
    dragRef.current = {
      pointerId: event.pointerId,
      centerX,
      centerY,
      lastAngle: Math.atan2(event.clientY - centerY, event.clientX - centerX),
      remainderSeconds: 0
    };
    setExpanded(true);
  }

  function handlePointerMove(event: React.PointerEvent<HTMLButtonElement>) {
    const drag = dragRef.current;
    if (!drag || event.pointerId !== drag.pointerId) return;
    event.preventDefault();
    const angle = Math.atan2(event.clientY - drag.centerY, event.clientX - drag.centerX);
    let delta = angle - drag.lastAngle;
    if (delta > Math.PI) delta -= Math.PI * 2;
    else if (delta < -Math.PI) delta += Math.PI * 2;
    if (delta === 0) return;
    drag.lastAngle = angle;
    const totalSeconds = drag.remainderSeconds + (delta / (Math.PI * 2)) * CROWN_SECONDS_PER_REVOLUTION;
    const wholeSeconds = Math.trunc(totalSeconds);
    drag.remainderSeconds = totalSeconds - wholeSeconds;
    setRotationDeg((current) => current + (delta * 180) / Math.PI);
    if (wholeSeconds !== 0) {
      kit.clock.adjustBySeconds(wholeSeconds);
    }
  }

  function endDrag(event: React.PointerEvent<HTMLButtonElement>) {
    const drag = dragRef.current;
    if (!drag || event.pointerId !== drag.pointerId) return;
    dragRef.current = null;
    setExpanded(false);
  }

  function handleKeyDown(event: React.KeyboardEvent<HTMLButtonElement>) {
    if (event.key === "ArrowRight" || event.key === "ArrowUp") {
      event.preventDefault();
      kit.clock.adjustBySeconds(1);
    } else if (event.key === "ArrowLeft" || event.key === "ArrowDown") {
      event.preventDefault();
      kit.clock.adjustBySeconds(-1);
    }
  }

  return (
    <button
      type="button"
      className={`rpg-clock-crown ${expanded ? "is-expanded" : ""}`.trim()}
      aria-label="校时表冠：按住并绕圈拖动以校时"
      aria-expanded={expanded}
      style={{ "--rpg-clock-crown-rotation": `${rotationDeg}deg` } as CSSProperties}
      onPointerDown={handlePointerDown}
      onPointerMove={handlePointerMove}
      onPointerUp={endDrag}
      onPointerCancel={endDrag}
      onKeyDown={handleKeyDown}
    >
      <span aria-hidden="true">◉</span>
    </button>
  );
}
