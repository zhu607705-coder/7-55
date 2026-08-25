import {
  useEffect,
  useRef,
  type ButtonHTMLAttributes,
  type ReactNode
} from "react";
import { PhoneNavButton, type PhoneNavKind } from "./PhoneNavButton";

interface PhoneAppScaffoldProps {
  children: ReactNode;
  header?: ReactNode;
  footer?: ReactNode;
  className?: string;
  contentClassName?: string;
  contentMode?: "scroll" | "fixed";
  label: string;
}

/**
 * Shared application-internal scaffold. It fills the scene area below the global
 * status bar and never owns or changes the canonical 430×860 phone viewport.
 */
export function PhoneAppScaffold({
  children,
  header,
  footer,
  className = "",
  contentClassName = "",
  contentMode = "scroll",
  label
}: PhoneAppScaffoldProps) {
  return (
    <section className={`phone-app-scaffold ${className}`.trim()} aria-label={label}>
      {header}
      <main className={`phone-app-content is-${contentMode} ${contentClassName}`.trim()}>
        {children}
      </main>
      {footer}
    </section>
  );
}

interface PhoneAppHeaderProps {
  title: string;
  eyebrow?: string;
  navigation?: {
    kind: PhoneNavKind;
    label: string;
    onClick: () => void;
  };
  end?: ReactNode;
  className?: string;
}

/**
 * Shared header geometry and navigation semantics for phone applications.
 * App-specific classes may change the palette, while the 44px navigation target,
 * title hierarchy and end-slot alignment remain stable.
 */
export function PhoneAppHeader({
  title,
  eyebrow,
  navigation,
  end,
  className = ""
}: PhoneAppHeaderProps) {
  return (
    <header className={`phone-app-header ${className}`.trim()} data-phone-app-part="header">
      <span className="phone-app-header__nav-slot">
        {navigation ? (
          <PhoneNavButton
            kind={navigation.kind}
            label={navigation.label}
            onClick={navigation.onClick}
          />
        ) : null}
      </span>
      <span className="phone-app-header__title">
        {eyebrow ? <small>{eyebrow}</small> : null}
        <h1>{title}</h1>
      </span>
      <span className="phone-app-header__end">{end}</span>
    </header>
  );
}

export interface PhoneAppBottomNavItem {
  id: string;
  label: string;
  icon: ReactNode;
  locked?: boolean;
  badge?: string;
}

interface PhoneAppBottomNavProps {
  items: readonly PhoneAppBottomNavItem[];
  activeId: string;
  onSelect: (id: string) => void;
  className?: string;
  label?: string;
}

/** Locked items are rendered without button, focus or click semantics. */
export function PhoneAppBottomNav({
  items,
  activeId,
  onSelect,
  className = "",
  label = "应用导航"
}: PhoneAppBottomNavProps) {
  return (
    <nav className={`phone-app-bottom-nav ${className}`.trim()} aria-label={label} data-phone-app-part="bottom-nav">
      {items.map((item) => {
        const content = (
          <>
            <span className="phone-app-bottom-nav__icon" aria-hidden="true">{item.icon}</span>
            <span className="phone-app-bottom-nav__label">{item.label}</span>
            {item.badge ? <b className="phone-app-bottom-nav__badge">{item.badge}</b> : null}
          </>
        );
        if (item.locked) {
          return (
            <span key={item.id} className="phone-app-bottom-nav__locked" aria-hidden="true">
              {content}
            </span>
          );
        }
        const active = item.id === activeId;
        return (
          <button
            key={item.id}
            type="button"
            className={active ? "is-active" : ""}
            aria-current={active ? "page" : undefined}
            onClick={() => onSelect(item.id)}
          >
            {content}
          </button>
        );
      })}
    </nav>
  );
}

interface PhoneActionSheetProps {
  title: string;
  onClose: () => void;
  children: ReactNode;
  description?: string;
  className?: string;
  returnFocusElement?: HTMLElement | null;
}

/**
 * Shared modal interaction contract: Escape closes, Tab stays inside the sheet,
 * and focus returns to the previously focused control on teardown.
 */
export function PhoneActionSheet({
  title,
  onClose,
  children,
  description,
  className = "",
  returnFocusElement = null
}: PhoneActionSheetProps) {
  const dialogRef = useRef<HTMLElement>(null);
  const explicitReturnFocusRef = useRef<HTMLElement | null>(returnFocusElement);
  const previouslyFocusedRef = useRef<HTMLElement | null>(
    typeof document !== "undefined" && document.activeElement instanceof HTMLElement
      ? document.activeElement
      : null
  );
  const onCloseRef = useRef(onClose);
  onCloseRef.current = onClose;

  useEffect(() => {
    const dialog = dialogRef.current;
    const focusableSelector = "button:not([disabled]), input:not([disabled]), textarea:not([disabled]), select:not([disabled]), [tabindex]:not([tabindex='-1'])";
    const autofocusTarget = dialog?.querySelector<HTMLElement>("[data-phone-autofocus], [autofocus]");
    const firstFocusable = dialog?.querySelector<HTMLElement>(focusableSelector);
    (autofocusTarget ?? firstFocusable ?? dialog)?.focus();

    function handleKeyDown(event: KeyboardEvent) {
      if (event.key === "Escape") {
        event.preventDefault();
        onCloseRef.current();
        return;
      }
      if (event.key !== "Tab" || !dialog) return;
      const focusable = Array.from(dialog.querySelectorAll<HTMLElement>(focusableSelector));
      const first = focusable[0];
      const last = focusable[focusable.length - 1];
      if (!first || !last) {
        event.preventDefault();
        return;
      }
      if (event.shiftKey && document.activeElement === first) {
        event.preventDefault();
        last.focus();
      } else if (!event.shiftKey && document.activeElement === last) {
        event.preventDefault();
        first.focus();
      }
    }

    document.addEventListener("keydown", handleKeyDown);
    return () => {
      document.removeEventListener("keydown", handleKeyDown);
      const explicitTarget = explicitReturnFocusRef.current;
      if (explicitTarget?.isConnected) {
        explicitTarget.focus();
      } else {
        previouslyFocusedRef.current?.focus();
      }
    };
  }, []);

  return (
    <div className="phone-app-sheet-layer" role="presentation" onPointerDown={onClose}>
      <section
        ref={dialogRef}
        className={`phone-app-sheet ${className}`.trim()}
        role="dialog"
        aria-modal="true"
        aria-labelledby="phone-app-sheet-title"
        aria-describedby={description ? "phone-app-sheet-description" : undefined}
        tabIndex={-1}
        onPointerDown={(event) => event.stopPropagation()}
      >
        <header className="phone-app-sheet__header">
          <span>
            <small>QUICK PANEL</small>
            <h2 id="phone-app-sheet-title">{title}</h2>
          </span>
          <button type="button" aria-label={`关闭${title}`} onClick={onClose}>×</button>
        </header>
        {description ? <p id="phone-app-sheet-description" className="phone-app-sheet__description">{description}</p> : null}
        <div className="phone-app-sheet__body">{children}</div>
      </section>
    </div>
  );
}

interface PhoneAppFeedbackProps {
  children: ReactNode;
  tone?: "info" | "success" | "warning" | "error";
  className?: string;
}

export function PhoneAppFeedback({ children, tone = "info", className = "" }: PhoneAppFeedbackProps) {
  return (
    <p className={`phone-app-feedback is-${tone} ${className}`.trim()} role="status" aria-live="polite">
      {children}
    </p>
  );
}

interface PhoneStateViewProps {
  kind: "loading" | "empty" | "error" | "offline";
  title: string;
  description: string;
  icon?: ReactNode;
  primaryAction?: ReactNode;
  secondaryAction?: ReactNode;
  className?: string;
}

export function PhoneStateView({
  kind,
  title,
  description,
  icon,
  primaryAction,
  secondaryAction,
  className = ""
}: PhoneStateViewProps) {
  return (
    <section className={`phone-state-view is-${kind} ${className}`.trim()} aria-live={kind === "loading" ? "polite" : "assertive"}>
      {icon ? <span className="phone-state-view__icon" aria-hidden="true">{icon}</span> : null}
      <h2>{title}</h2>
      <p>{description}</p>
      {primaryAction || secondaryAction ? (
        <div className="phone-state-view__actions">
          {primaryAction}
          {secondaryAction}
        </div>
      ) : null}
    </section>
  );
}

interface PhoneListRowProps extends Omit<ButtonHTMLAttributes<HTMLButtonElement>, "children" | "type"> {
  title: string;
  description?: string;
  leading?: ReactNode;
  trailing?: ReactNode;
  locked?: boolean;
}

export function PhoneListRow({
  title,
  description,
  leading,
  trailing,
  locked = false,
  className = "",
  ...buttonProps
}: PhoneListRowProps) {
  const content = (
    <>
      {leading ? <span className="phone-list-row__leading" aria-hidden="true">{leading}</span> : null}
      <span className="phone-list-row__copy">
        <strong>{title}</strong>
        {description ? <small>{description}</small> : null}
      </span>
      <span className="phone-list-row__trailing">{trailing ?? (locked ? null : "›")}</span>
    </>
  );

  if (locked) {
    return <span className={`phone-list-row is-locked ${className}`.trim()} aria-hidden="true">{content}</span>;
  }

  return (
    <button {...buttonProps} type="button" className={`phone-list-row ${className}`.trim()}>
      {content}
    </button>
  );
}

interface PhoneSegmentedControlProps<T extends string> {
  label: string;
  value: T;
  options: readonly { value: T; label: string }[];
  onChange: (value: T) => void;
  className?: string;
}

export function PhoneSegmentedControl<T extends string>({
  label,
  value,
  options,
  onChange,
  className = ""
}: PhoneSegmentedControlProps<T>) {
  return (
    <div className={`phone-segmented-control ${className}`.trim()} role="group" aria-label={label}>
      {options.map((option) => {
        const selected = option.value === value;
        return (
          <button
            key={option.value}
            type="button"
            className={selected ? "is-selected" : ""}
            aria-pressed={selected}
            onClick={() => onChange(option.value)}
          >
            {option.label}
          </button>
        );
      })}
    </div>
  );
}
