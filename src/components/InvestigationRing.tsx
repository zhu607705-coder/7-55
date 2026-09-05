import {
  useEffect,
  useId,
  useRef,
  useState,
  type CSSProperties,
  type KeyboardEvent
} from "react";

export type InvestigationRingNodeState = "ready" | "complete" | "locked";

export interface InvestigationRingNode<Id extends string = string> {
  id: Id;
  label: string;
  detail?: string;
  statusLabel: string;
  state: InvestigationRingNodeState;
}

export interface InvestigationRingProps<Id extends string = string> {
  ariaLabel: string;
  title: string;
  eyebrow?: string;
  completed: number;
  total: number;
  nodes: readonly InvestigationRingNode<Id>[];
  centerLabel?: string;
  hint?: string;
  compact?: boolean;
  className?: string;
  onActivate?: (id: Id) => void;
}

interface RingNodePosition extends CSSProperties {
  "--investigation-node-x": string;
  "--investigation-node-y": string;
}

function ringPoint(index: number, total: number): { x: number; y: number } {
  const angle = -Math.PI / 2 + (Math.PI * 2 * index) / Math.max(total, 1);
  return {
    x: 50 + Math.cos(angle) * 32.5,
    y: 50 + Math.sin(angle) * 32.5
  };
}

export function InvestigationRing<Id extends string>({
  ariaLabel,
  title,
  eyebrow,
  completed,
  total,
  nodes,
  centerLabel = "并行调查",
  hint = "各节点可以任意顺序处理",
  compact = false,
  className = "",
  onActivate
}: InvestigationRingProps<Id>) {
  const hintId = useId();
  const buttonRefs = useRef<Array<HTMLButtonElement | null>>([]);
  const [activeIndex, setActiveIndex] = useState(0);
  const points = nodes.map((_, index) => ringPoint(index, nodes.length));
  const focusableIndices = nodes
    .map((node, index) => node.state === "locked" ? -1 : index)
    .filter((index) => index >= 0);

  useEffect(() => {
    if (focusableIndices.includes(activeIndex)) return;
    setActiveIndex(focusableIndices[0] ?? -1);
  }, [activeIndex, focusableIndices]);

  function moveFocus(nextIndex: number, direction: 1 | -1) {
    if (focusableIndices.length === 0) return;
    let normalized = (nextIndex + nodes.length) % nodes.length;
    for (let attempts = 0; attempts < nodes.length; attempts += 1) {
      if (nodes[normalized]?.state !== "locked") {
        setActiveIndex(normalized);
        buttonRefs.current[normalized]?.focus();
        return;
      }
      normalized = (normalized + direction + nodes.length) % nodes.length;
    }
  }

  function handleNodeKeyDown(
    event: KeyboardEvent<HTMLButtonElement>,
    index: number,
    node: InvestigationRingNode<Id>
  ) {
    if (event.key === "ArrowRight" || event.key === "ArrowDown") {
      event.preventDefault();
      moveFocus(index + 1, 1);
    } else if (event.key === "ArrowLeft" || event.key === "ArrowUp") {
      event.preventDefault();
      moveFocus(index - 1, -1);
    } else if (event.key === "Home") {
      event.preventDefault();
      moveFocus(focusableIndices[0] ?? 0, 1);
    } else if (event.key === "End") {
      event.preventDefault();
      moveFocus(focusableIndices[focusableIndices.length - 1] ?? nodes.length - 1, -1);
    } else if ((event.key === "Enter" || event.key === " ") && node.state !== "locked") {
      event.preventDefault();
      onActivate?.(node.id);
    }
  }

  return (
    <section
      className={`investigation-ring ${compact ? "investigation-ring--compact" : ""} ${className}`.trim()}
      aria-label={ariaLabel}
      aria-describedby={hintId}
    >
      <header className="investigation-ring__header">
        <div>
          {eyebrow ? <small>{eyebrow}</small> : null}
          <h2>{title}</h2>
        </div>
        <strong aria-label={`已完成 ${completed} 项，共 ${total} 项`}>{completed}/{total}</strong>
      </header>

      <div className="investigation-ring__field">
        <svg
          className="investigation-ring__track"
          viewBox="0 0 100 100"
          preserveAspectRatio="none"
          aria-hidden="true"
        >
          {nodes.length === 2 ? (
            <ellipse cx="50" cy="50" rx="32.5" ry="32.5" />
          ) : (
            <polygon points={points.map(({ x, y }) => `${x},${y}`).join(" ")} />
          )}
        </svg>

        <div className="investigation-ring__center" aria-hidden="true">
          <span>{centerLabel}</span>
          <strong>{completed}<i>/</i>{total}</strong>
          <small>{completed === total ? "已查齐" : "尚有未查"}</small>
        </div>

        {nodes.map((node, index) => {
          const position = points[index];
          const disabled = node.state === "locked" || !onActivate;
          const style: RingNodePosition = {
            "--investigation-node-x": `${position.x}%`,
            "--investigation-node-y": `${position.y}%`
          };
          return (
            <button
              key={node.id}
              ref={(element) => { buttonRefs.current[index] = element; }}
              type="button"
              className="investigation-ring__node"
              data-state={node.state}
              style={style}
              disabled={disabled}
              tabIndex={!disabled && index === activeIndex ? 0 : -1}
              aria-label={`${node.label}，${node.statusLabel}${node.detail ? `，${node.detail}` : ""}`}
              onFocus={() => setActiveIndex(index)}
              onKeyDown={(event) => handleNodeKeyDown(event, index, node)}
              onClick={() => onActivate?.(node.id)}
            >
              <span className="investigation-ring__node-state" aria-hidden="true" />
              <span className="investigation-ring__node-copy">
                <strong>{node.label}</strong>
                {node.detail ? <small>{node.detail}</small> : null}
              </span>
              <em>{node.statusLabel}</em>
            </button>
          );
        })}
      </div>

      <p id={hintId} className="investigation-ring__hint">
        <span aria-hidden="true">↔</span>{hint}
      </p>
    </section>
  );
}
