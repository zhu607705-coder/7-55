import { useCallback, useEffect, useRef, useState, type CSSProperties } from "react";
import { useMediaQuery } from "../../components/useMediaQuery";
import { getAudioContextConstructor } from "../../core/ClientCompatibility";
import type { EventBus } from "../../core/EventBus";
import type { CanteenChaseAttempt } from "../../modules/ChapterThreeCanteenController";
import { setCanteenChaseSnapshot } from "./CanteenChaseRuntime";
import { visiblePedestrians } from "./canteen-chase/ChaseGeometry";
import { ChaseRenderer } from "./canteen-chase/ChaseRenderer";
import { chaseStageAt } from "./canteen-chase/ChaseRoute";
import { ChaseStuntModel, visibleStuntObstacles, STUNT_PICKUPS, STUNT_RAMPS, type ChaseStuntAction, type ChaseStuntEvent } from "./canteen-chase/ChaseStuntModel";
interface CanteenChaseOverlayProps {
    events: EventBus;
    onAttempt: (attempt: CanteenChaseAttempt) => void;
}
const keyActions: Partial<Record<string, ChaseStuntAction>> = { KeyA: "left", ArrowLeft: "left", KeyD: "right", ArrowRight: "right", Space: "jump", KeyJ: "bell", KeyE: "item" };
const inputNames: Record<ChaseStuntAction, string> = { left: "左转", right: "右转", jump: "蓄力起跳", bell: "响铃开路", item: "使用道具" };
function snapshot(m: ChaseStuntModel) { return { started: m.started, paused: m.paused, runState: m.runState, distance: m.distance, lives: m.lives, lane: m.lane, collisions: m.collisions, charge: m.charge, airHeight: m.airHeight, bellCooldown: m.bellCooldown, boost: m.boostSeconds, shield: m.shield, powerup: m.powerup, combo: m.combo, score: m.score, stunts: m.stunts, speed: m.speed, feedback: m.feedbackSeconds > 0 ? m.feedback : "" }; }
/** The scene's stunt model owns temporary movement; the chapter controller owns the outcome. */
export function CanteenChaseOverlay({ events, onAttempt }: CanteenChaseOverlayProps) {
    const coarse = useMediaQuery("(pointer: coarse)"), reduced = useMediaQuery("(prefers-reduced-motion: reduce)");
    const callbackRef = useRef({ events, onAttempt });
    callbackRef.current = { events, onAttempt };
    const eventRef = useRef<(e: ChaseStuntEvent) => void>(() => { });
    const [model] = useState(() => new ChaseStuntModel(e => eventRef.current(e)));
    const [view, setView] = useState(() => snapshot(model));
    const [assetState, setAssetState] = useState<"loading" | "ready" | "error">("loading");
    const canvasRef = useRef<HTMLCanvasElement>(null), rendererRef = useRef<ChaseRenderer | null>(null), audioRef = useRef<AudioContext | null>(null);
    const touch = useRef(new Map<number, ChaseStuntAction>()), finished = useRef(false), lastFrame = useRef(0);
    const publish = useCallback(() => {
        setView(snapshot(model));
        setCanteenChaseSnapshot({ active: true, coordinateSystem: "3D road projection, horizon at top center, distance increases forward", mode: "story", runState: model.runState, distance: Math.floor(model.distance), goal: 755, lives: model.lives, lane: model.lane, collisions: model.collisions, paused: model.paused, countdown: null,
            visibleObstacles: visibleStuntObstacles(model.distance).slice(-12).map(o => ({ id: o.id, kind: o.kind, lane: o.lane, distanceAhead: Math.round(o.distance - model.distance) })),
            visiblePedestrians: visiblePedestrians(model.distance).slice(-6).map(p => ({ id: p.id, kind: p.kind, side: p.side, distanceAhead: Math.round(p.distance - model.distance) })), narration: null,
            stunt: { started: model.started, airHeight: model.airHeight, charge: model.charge, bellCooldown: model.bellCooldown, powerup: model.powerup, shield: model.shield, combo: model.combo, stunts: model.stunts, speed: model.speed, paperLane: model.paperLane, paperGap: model.paperGap, cleared: [...model.clearedObstacleIds], pickups: STUNT_PICKUPS.filter(p => !model.collectedPickupIds.has(p.id) && p.distance >= model.distance && p.distance < model.distance + 96), ramps: STUNT_RAMPS.filter(r => r.distance >= model.distance && r.distance < model.distance + 96) } });
    }, [model]);
    const sound = useCallback((kind: ChaseStuntEvent["type"]) => {
        const ctx = audioRef.current;
        if (!ctx || ctx.state !== "running")
            return;
        const at = ctx.currentTime, osc = ctx.createOscillator(), gain = ctx.createGain();
        osc.type = kind === "bell" ? "sine" : "triangle";
        const hz = kind === "bell" ? 880 : kind === "collision" ? 110 : kind === "jump" ? 320 : kind === "collect" ? 660 : 440;
        osc.frequency.setValueAtTime(hz, at);
        osc.frequency.exponentialRampToValueAtTime(kind === "jump" ? 720 : hz * .75, at + .15);
        gain.gain.setValueAtTime(.07, at);
        gain.gain.exponentialRampToValueAtTime(.0001, at + .22);
        osc.connect(gain).connect(ctx.destination);
        osc.onended = () => { osc.disconnect(); gain.disconnect(); };
        osc.start(at);
        osc.stop(at + .23);
    }, []);
    eventRef.current = e => {
        if (e.type !== "stunt")
            sound(e.type);
        if (e.type === "collision")
            callbackRef.current.events.emit("canteen_chase_collision", { collisions: model.collisions, lives: model.lives });
        if (e.type === "finish" && !finished.current) {
            finished.current = true;
            callbackRef.current.events.emit("canteen_chase_finish", { result: model.runState, mode: "story", distance: Math.floor(model.distance), lives: model.lives, collisions: model.collisions });
            callbackRef.current.onAttempt({ mode: "story", distance: Math.floor(model.distance), lives: model.lives, collisions: model.collisions });

        }
        publish();
    };
    const start = useCallback(() => {
        if (rendererRef.current?.getAssetState() !== "ready")
            return;
        if (!audioRef.current) {
            const Audio = getAudioContextConstructor();
            if (Audio)
                audioRef.current = new Audio();
        }
        void audioRef.current?.resume();
        model.start();
        publish();
        callbackRef.current.events.emit("canteen_chase_run_started", { mode: "story" });
    }, [model, publish]);
    const restart = useCallback(() => { finished.current = false; touch.current.clear(); model.restart(); publish(); callbackRef.current.events.emit("canteen_chase_run_started", { mode: "story" }); }, [model, publish]);
    const actionFor = (code: string): ChaseStuntAction | undefined => keyActions[code];
    useEffect(() => {
        const canvas = canvasRef.current;
        if (!canvas)
            return;
        const renderer = new ChaseRenderer(canvas);
        rendererRef.current = renderer;
        renderer.setReducedMotion(reduced);
        renderer.render(model);
        let frame = 0, lastPublish = 0;
        lastFrame.current = performance.now();
        const tick = (now: number) => { const delta = Math.max(0, Math.min(250, now - lastFrame.current)); lastFrame.current = now; const ready = renderer.getAssetState(); setAssetState(ready); if (ready === "ready")
            model.update(delta); renderer.render(model); if (now - lastPublish > 70) {
            publish();
            lastPublish = now;
        } frame = requestAnimationFrame(tick); };
        frame = requestAnimationFrame(tick);
        return () => { cancelAnimationFrame(frame); renderer.destroy(); rendererRef.current = null; };
    }, [model, publish, reduced]);
    useEffect(() => {
        const down = (e: KeyboardEvent) => { if (e.ctrlKey || e.altKey || e.metaKey || e.repeat)
            return; const a = actionFor(e.code); if (!a)
            return; e.preventDefault(); if (!model.started) {
            if (a === "jump")
                start();
            return;
        } if (model.runState === "lost") {
            if (a === "jump")
                restart();
            return;
        } model.press(a); publish(); };
        const up = (e: KeyboardEvent) => { const a = actionFor(e.code); if (a) {
            e.preventDefault();
            model.release(a);
            publish();
        } };
        const hide = () => { if (document.hidden) {
            model.setPaused(true);
            touch.current.clear();
            publish();
        } lastFrame.current = performance.now(); };
        window.addEventListener("keydown", down);
        window.addEventListener("keyup", up);
        document.addEventListener("visibilitychange", hide);
        const previous = window.advanceTime;
        window.advanceTime = (ms: number) => { model.update(ms); rendererRef.current?.render(model); publish(); };
        return () => { window.removeEventListener("keydown", down); window.removeEventListener("keyup", up); document.removeEventListener("visibilitychange", hide); model.releaseControls(); if (previous)
            window.advanceTime = previous;
        else
            delete window.advanceTime; };
    }, [model, publish, start, restart]);
    useEffect(() => () => { void audioRef.current?.close(); setCanteenChaseSnapshot(null); }, []);
    function pressTouch(a: ChaseStuntAction, e: React.PointerEvent<HTMLButtonElement>) { e.preventDefault(); touch.current.set(e.pointerId, a); e.currentTarget.setPointerCapture?.(e.pointerId); model.press(a); publish(); }
    function releaseTouch(e: React.PointerEvent<HTMLButtonElement>, cancel = false) { const a = touch.current.get(e.pointerId); if (!a)
        return; touch.current.delete(e.pointerId); if (cancel) {
        model.releaseControls();
        touch.current.clear();
    }
    else
        model.release(a); publish(); }
    const powerup = view.powerup === "tray" ? "餐盘护具" : view.powerup === "gust" ? "顺风纸团" : "等待拾取";
    return <section className={`canteen-chase-overlay canteen-bike-rush-3d is-${view.runState} ${view.paused ? "is-paused" : ""} is-stunt-chase`} aria-label="755 米校园特技追纸" data-run-state={view.runState} data-mode="story">
   <canvas ref={canvasRef} className="canteen-bike-canvas" role="img" aria-label="可以自由转向、飞跃、响铃和拾取道具的立体校园追逐"/>
   <header className="stunt-hud" style={{ "--stunt-progress": `${view.distance / 755 * 100}%` } as CSSProperties}>
     <div><small>{chaseStageAt(view.distance).label}</small><strong>{Math.floor(view.distance)}<small> / 755m</small></strong></div>
     <div className="stunt-route-meter"><i /></div>
     <div><small>连招 / 特技</small><strong>{view.combo} / {view.stunts}</strong></div>
     <div><small>机会</small><strong>{"●".repeat(view.lives)}{"○".repeat(3 - view.lives)}</strong></div>
   </header>
   {view.started && view.runState === "running" ? <>
     <aside className="stunt-pocket"><strong>{view.shield ? "餐盘保护中" : powerup}</strong><span>E 使用道具</span><span>J 车铃 {view.bellCooldown > .05 ? `${view.bellCooldown.toFixed(1)}s` : "就绪"}</span></aside>
     {view.feedback ? <div className="stunt-feedback" role="status">{view.feedback}</div> : null}
     {view.charge > 0 ? <div className="stunt-charge"><span>松手起跳</span><i style={{ width: `${view.charge * 100}%` }}/></div> : null}
     {view.boost > 0 ? <div className="stunt-boost">顺风加速！</div> : null}
   </> : null}
   {assetState !== "ready" ? <div className="canteen-bike-asset-status" role="status"><p>{assetState === "error" ? "骑行人物未能加载" : "正在准备自行车与校园…"}</p>{assetState === "error" ? <button onClick={() => window.location.reload()}>重新载入</button> : null}</div> : null}
   {!view.started && assetState === "ready" ? <div className="stunt-modal"><small>755m · 校园特技追纸</small><h2>这次，骑出点花样。</h2><p>A / D 连续转向<br />按住 Space 蓄力，松手飞跃<br />J 响铃开路 · E 使用捡到的道具</p><p className="stunt-tip">彩色跳台通往飞跃捷径，每段补给恢复一次机会。<br />实心路障要跳，车铃只能震开部分围堵。</p><button onClick={start}>上车追纸</button></div> : null}
   {view.runState === "lost" ? <div className="stunt-modal"><h2>车还在，人也还在。</h2><p>飞跃 {view.stunts} 次 · 本次 {Math.floor(view.distance)} 米</p><p>提前蓄力跳过横栏，路人和纸障可以响铃开路。</p><button onClick={restart}>再骑一次</button></div> : null}
   {view.runState === "won" ? <div className="stunt-modal"><h2>追到了！</h2><p>755 米 · 特技 {view.stunts} 次 · 得分 {view.score}</p></div> : null}
   {view.paused && view.started && view.runState === "running" ? <div className="stunt-modal"><h2>停下来喘口气</h2><button onClick={() => { model.setPaused(false); lastFrame.current = performance.now(); publish(); }}>继续追纸</button></div> : null}
   {view.started && view.runState === "running" && !view.paused ? (coarse ? <nav className="stunt-touch" aria-label="特技骑行触屏操作">{(["left", "jump", "bell", "item", "right"] as const).map(a => <button key={a} aria-label={inputNames[a]} onPointerDown={e => pressTouch(a, e)} onPointerUp={e => releaseTouch(e)} onPointerCancel={e => releaseTouch(e, true)} onLostPointerCapture={e => releaseTouch(e, true)}>{a === "left" ? "◀" : a === "right" ? "▶" : a === "jump" ? "按住跳" : a === "bell" ? "响铃" : "道具"}</button>)}</nav> : <footer className="stunt-keyboard">A / D 转向　 Space 蓄力跳　 J 响铃　 E 道具</footer>) : null}
 </section>;
}
