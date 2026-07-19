import { useEffect, useMemo, useState } from "react";
import type { GameStore } from "../core/types";
import { applyDeveloperCheckpoint, DEVELOPER_CHECKPOINTS, getActiveDeveloperCheckpoint, restoreDeveloperBackup, type DeveloperCheckpointId } from "../modules/DeveloperChannel";

interface DeveloperChannelProps {
  store: GameStore;
  onVisibilityChange?: (open: boolean) => void;
}

export function DeveloperChannel({ store, onVisibilityChange }: DeveloperChannelProps) {
  const params = new URLSearchParams(window.location.search);
  const explicitlyRequested = params.get("dev") === "1" || params.has("devCheckpoint");
  const [available, setAvailable] = useState(() => isDeveloperChannelAvailable(window.location.search, import.meta.env.DEV));
  const [open, setOpen] = useState(() => explicitlyRequested && isDeveloperChannelAvailable(window.location.search, import.meta.env.DEV));
  const [active, setActive] = useState(() => getActiveDeveloperCheckpoint());
  const chapters = useMemo(() => ["第一章", "第二章", "第三章"] as const, []);
  useEffect(() => {
    onVisibilityChange?.(open);
  }, [onVisibilityChange, open]);
  useEffect(() => {
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.ctrlKey && event.shiftKey && event.key.toLowerCase() === "d") {
        event.preventDefault();
        setAvailable(true);
        setOpen((value) => !value);
      }
    };
    window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  }, []);
  const stopPointerPropagation = (event: React.SyntheticEvent) => event.stopPropagation();
  if (!available) return null;
  if (!open) return <button type="button" className="developer-channel-trigger" aria-label="打开开发者通道" onPointerDown={stopPointerPropagation} onPointerUp={stopPointerPropagation} onClick={(event) => { stopPointerPropagation(event); setOpen(true); }}>DEV</button>;
  return <aside className="developer-channel" aria-label="开发者通道" onPointerDown={stopPointerPropagation} onPointerUp={stopPointerPropagation} onClick={stopPointerPropagation}>
    <header><div><small>7:55 DEV</small><strong>玩法节点直达</strong></div><button type="button" aria-label="关闭开发者通道" onClick={() => setOpen(false)}>×</button></header>
    <div className="developer-channel-scroll">
      {chapters.map((chapter) => <section key={chapter}><h2>{chapter}</h2>{DEVELOPER_CHECKPOINTS.filter((item) => item.chapter === chapter).map((item) => <button key={item.id} type="button" className={active === item.id ? "is-active" : ""} onClick={() => { applyDeveloperCheckpoint(store, item.id as DeveloperCheckpointId); setActive(item.id); }}><strong>{item.label}</strong><span>{item.detail}</span></button>)}</section>)}
    </div>
    <footer><button type="button" onClick={() => { if (restoreDeveloperBackup(store)) setActive(null); }}>恢复进入前存档</button><span>Ctrl Shift D</span></footer>
  </aside>;
}

export function isDeveloperChannelAvailable(search: string, _devMode: boolean): boolean {
  const params = new URLSearchParams(search);
  return params.get("dev") !== "0";
}
