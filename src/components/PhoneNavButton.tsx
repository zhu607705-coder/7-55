import { forwardRef, type ButtonHTMLAttributes, type ReactNode } from "react";

export type PhoneNavKind = "back" | "exit" | "close";

interface PhoneNavButtonProps extends Omit<ButtonHTMLAttributes<HTMLButtonElement>, "type" | "children"> {
  kind: PhoneNavKind;
  label: string;
  glyph?: ReactNode;
}

const DEFAULT_GLYPHS: Record<PhoneNavKind, string> = {
  back: "‹",
  exit: "×",
  close: "×"
};

/**
 * Shared phone navigation contract. App-specific classes may change its skin,
 * while semantics, hit size and accessibility stay consistent.
 */
export const PhoneNavButton = forwardRef<HTMLButtonElement, PhoneNavButtonProps>(function PhoneNavButton(
  { kind, label, glyph, className = "", ...props },
  ref
) {
  return (
    <button
      {...props}
      ref={ref}
      type="button"
      className={`phone-nav-button is-${kind} ${className}`.trim()}
      data-phone-nav={kind}
      aria-label={label}
    >
      <span className="phone-nav-glyph" aria-hidden="true">{glyph ?? DEFAULT_GLYPHS[kind]}</span>
    </button>
  );
});
