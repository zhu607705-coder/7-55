import {
  useCallback,
  useEffect,
  useRef,
  useState,
  type CSSProperties,
  type PointerEvent as ReactPointerEvent
} from "react";
import {
  createQizhenWeatherControlFrame,
  getQizhenWeatherAlignedBandCount,
  isQizhenWeatherBandAligned,
  QIZHEN_WEATHER_BAND_CONTROLS,
  QIZHEN_WEATHER_CLOUD_TARGET,
  QIZHEN_WEATHER_STABLE_REQUIRED_MS,
  QIZHEN_WEATHER_TARGET_TOLERANCE,
  stepQizhenWeatherControl,
  type QizhenWeatherBandIndex,
  type QizhenWeatherControlDirection,
  type QizhenWeatherControlDirections,
  type QizhenWeatherControlSummary
} from "../../../modules/QizhenWeatherControlModel";
import hairDryerUrl from "../../../assets/rpg/props/items/hair_dryer_generated_v01.png";
import { setQizhenWeatherControlRuntimeSnapshot } from "./QizhenWeatherControlRuntime";

interface QizhenWeatherCalibrationProps {
  readonly onComplete: (summary: QizhenWeatherControlSummary) => boolean;
}

interface ActiveControl {
  readonly bandIndex: QizhenWeatherBandIndex;
  readonly direction: -1 | 1;
}

const NEUTRAL_DIRECTIONS: QizhenWeatherControlDirections = [0, 0, 0];

export function QizhenWeatherCalibration({ onComplete }: QizhenWeatherCalibrationProps) {
  const [frame, setFrame] = useState(createQizhenWeatherControlFrame);
  const [moves, setMoves] = useState(0);
  const [controlledBands, setControlledBands] = useState<[boolean, boolean, boolean]>([false, false, false]);
  const [activeDirections, setActiveDirections] = useState<QizhenWeatherControlDirections>(NEUTRAL_DIRECTIONS);
  const activeControlsRef = useRef(new Map<string, ActiveControl>());
  const activeDirectionsRef = useRef<QizhenWeatherControlDirections>(NEUTRAL_DIRECTIONS);
  const completedRef = useRef(false);

  const publishDirections = useCallback(() => {
    const totals = [0, 0, 0];
    activeControlsRef.current.forEach(({ bandIndex, direction }) => {
      totals[bandIndex] += direction;
    });
    const next = totals.map((total) => Math.sign(total) as QizhenWeatherControlDirection) as [
      QizhenWeatherControlDirection,
      QizhenWeatherControlDirection,
      QizhenWeatherControlDirection
    ];
    activeDirectionsRef.current = next;
    setActiveDirections(next);
  }, []);

  const pressControl = useCallback((token: string, control: ActiveControl) => {
    if (activeControlsRef.current.has(token)) return;
    activeControlsRef.current.set(token, control);
    setMoves((current) => current + 1);
    setControlledBands((current) => {
      if (current[control.bandIndex]) return current;
      const next: [boolean, boolean, boolean] = [...current];
      next[control.bandIndex] = true;
      return next;
    });
    publishDirections();
  }, [publishDirections]);

  const releaseControl = useCallback((token: string) => {
    if (!activeControlsRef.current.delete(token)) return;
    publishDirections();
  }, [publishDirections]);

  const clearControls = useCallback(() => {
    activeControlsRef.current.clear();
    publishDirections();
  }, [publishDirections]);

  useEffect(() => {
    const byCode = new Map<string, ActiveControl>();
    QIZHEN_WEATHER_BAND_CONTROLS.forEach((control) => {
      byCode.set(control.backwardCode, { bandIndex: control.bandIndex, direction: -1 });
      byCode.set(control.forwardCode, { bandIndex: control.bandIndex, direction: 1 });
    });
    const handleKeyDown = (event: KeyboardEvent) => {
      const control = byCode.get(event.code);
      if (!control) return;
      event.preventDefault();
      pressControl(`key:${event.code}`, control);
    };
    const handleKeyUp = (event: KeyboardEvent) => {
      if (!byCode.has(event.code)) return;
      event.preventDefault();
      releaseControl(`key:${event.code}`);
    };
    const handleVisibilityChange = () => {
      if (document.visibilityState !== "visible") clearControls();
    };
    window.addEventListener("keydown", handleKeyDown);
    window.addEventListener("keyup", handleKeyUp);
    window.addEventListener("blur", clearControls);
    document.addEventListener("visibilitychange", handleVisibilityChange);
    return () => {
      window.removeEventListener("keydown", handleKeyDown);
      window.removeEventListener("keyup", handleKeyUp);
      window.removeEventListener("blur", clearControls);
      document.removeEventListener("visibilitychange", handleVisibilityChange);
      activeControlsRef.current.clear();
    };
  }, [clearControls, pressControl, releaseControl]);

  useEffect(() => {
    let animationFrame = 0;
    let lastFrameAt = performance.now();
    const tick = (now: number) => {
      const deltaMs = now - lastFrameAt;
      lastFrameAt = now;
      setFrame((current) => stepQizhenWeatherControl(current, activeDirectionsRef.current, deltaMs));
      animationFrame = window.requestAnimationFrame(tick);
    };
    animationFrame = window.requestAnimationFrame(tick);
    return () => window.cancelAnimationFrame(animationFrame);
  }, []);

  const alignedBandCount = getQizhenWeatherAlignedBandCount(frame.positions);
  const allBandsControlled = controlledBands.every(Boolean);
  const stableProgress = Math.min(1, frame.stableMs / QIZHEN_WEATHER_STABLE_REQUIRED_MS);

  useEffect(() => {
    setQizhenWeatherControlRuntimeSnapshot({
      active: true,
      positions: frame.positions,
      alignedBandCount,
      controlledBands,
      activeDirections,
      stableMs: frame.stableMs,
      requiredStableMs: QIZHEN_WEATHER_STABLE_REQUIRED_MS,
      elapsedMs: frame.elapsedMs,
      moves,
      windDirection: "left"
    });
  }, [activeDirections, alignedBandCount, controlledBands, frame, moves]);

  useEffect(() => () => setQizhenWeatherControlRuntimeSnapshot(null), []);

  useEffect(() => {
    if (completedRef.current
      || !allBandsControlled
      || frame.stableMs < QIZHEN_WEATHER_STABLE_REQUIRED_MS) return;
    completedRef.current = true;
    const accepted = onComplete({
      moves,
      cloudOffsets: frame.positions,
      controlledBands,
      stableMs: frame.stableMs,
      elapsedMs: frame.elapsedMs
    });
    if (!accepted) {
      completedRef.current = false;
      setFrame((current) => ({ ...current, stableMs: 0 }));
    }
  }, [allBandsControlled, controlledBands, frame, moves, onComplete]);

  function handlePointerDown(
    event: ReactPointerEvent<HTMLButtonElement>,
    bandIndex: QizhenWeatherBandIndex,
    direction: -1 | 1
  ) {
    event.preventDefault();
    event.currentTarget.setPointerCapture?.(event.pointerId);
    pressControl(`pointer:${event.pointerId}`, { bandIndex, direction });
  }

  function handlePointerRelease(event: ReactPointerEvent<HTMLButtonElement>) {
    releaseControl(`pointer:${event.pointerId}`);
  }

  function pulseKeyboardButton(bandIndex: QizhenWeatherBandIndex, direction: -1 | 1, token: string) {
    pressControl(token, { bandIndex, direction });
    window.setTimeout(() => releaseControl(token), 140);
  }

  return (
    <section className="qizhen-weather-calibration" aria-label="湖区云层校准">
      <header>
        <img src={hairDryerUrl} alt="寝室吹风机" />
        <div><strong>风向校准</strong><span>逆风修正三层云带</span></div>
        <output>{alignedBandCount}/3 · {(frame.stableMs / 1000).toFixed(1)}s</output>
      </header>

      <div className="qizhen-weather-airflow" aria-label="西南风持续向左推动云带">
        <strong>持续风力</strong><span>←</span><i /><i /><i />
      </div>
      <p className="qizhen-weather-instruction">高层 Q/E · 中层 A/D · 低层 Z/C　后退 / 前进</p>

      <div className="qizhen-weather-bands">
        {QIZHEN_WEATHER_BAND_CONTROLS.map((control) => {
          const bandIndex = control.bandIndex;
          const aligned = isQizhenWeatherBandAligned(frame.positions[bandIndex], bandIndex);
          return (
            <article
              className={`qizhen-weather-band ${aligned ? "is-aligned" : ""} ${controlledBands[bandIndex] ? "has-input" : ""}`}
              key={control.label}
            >
              <span>{control.label}</span>
              <div
                className="qizhen-weather-track"
                role="meter"
                aria-label={`${control.label}云带位置`}
                aria-valuemin={0}
                aria-valuemax={100}
                aria-valuenow={Math.round(frame.positions[bandIndex])}
              >
                <i
                  className="qizhen-weather-target"
                  style={{
                    "--cloud-position": QIZHEN_WEATHER_CLOUD_TARGET[bandIndex],
                    "--cloud-tolerance": QIZHEN_WEATHER_TARGET_TOLERANCE
                  } as CSSProperties}
                />
                <b
                  className={aligned ? "is-aligned" : ""}
                  style={{ "--cloud-position": frame.positions[bandIndex] } as CSSProperties}
                ><em /><em /><em /></b>
                <small aria-hidden="true">←</small>
              </div>
              {([-1, 1] as const).map((direction) => {
                const key = direction === -1 ? control.backwardKey : control.forwardKey;
                const active = activeDirections[bandIndex] === direction;
                return (
                  <button
                    type="button"
                    className={active ? "is-active" : ""}
                    aria-label={`${control.label}${direction === -1 ? "后退" : "前进"}，键盘 ${key}`}
                    key={direction}
                    onPointerDown={(event) => handlePointerDown(event, bandIndex, direction)}
                    onPointerUp={handlePointerRelease}
                    onPointerCancel={handlePointerRelease}
                    onLostPointerCapture={handlePointerRelease}
                    onClick={(event) => {
                      if (event.detail === 0) {
                        pulseKeyboardButton(bandIndex, direction, `button:${bandIndex}:${direction}`);
                      }
                    }}
                  ><kbd>{key}</kbd><small>{direction === -1 ? "退" : "进"}</small></button>
                );
              })}
            </article>
          );
        })}
      </div>

      <div className={`qizhen-weather-stability ${alignedBandCount === 3 ? "is-aligned" : ""}`}>
        <span>{allBandsControlled ? "同步稳定" : "三层均需操作"}</span>
        <i><b style={{ "--stability-progress": stableProgress } as CSSProperties} /></i>
        <strong>{Math.round(stableProgress * 100)}%</strong>
      </div>
    </section>
  );
}
