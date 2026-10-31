import { forwardRef, type ButtonHTMLAttributes, type ReactNode } from "react";
import "../../godot_native/web/button.css";

export type ButtonVariant = "primary" | "secondary" | "tertiary" | "ghost" | "text";
export type ButtonSize = "md" | "lg";
export interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: ButtonVariant;
  size?: ButtonSize;
  leadingIcon?: ReactNode;
}

/** Native button semantics; the same material tokens style the Godot Web shell. */
export const Button = forwardRef<HTMLButtonElement, ButtonProps>(function Button(
  { variant = "secondary", size = "md", leadingIcon, className = "", type = "button", children, ...props }, ref
) {
  return <button {...props} ref={ref} type={type} className={`tactile-button ${className}`.trim()} data-variant={variant} data-size={size}>
    {leadingIcon && <span className="tactile-button__icon" aria-hidden="true">{leadingIcon}</span>}
    {children}
    {variant === "text" && <span className="tactile-button__arrow" aria-hidden="true">→</span>}
  </button>;
});
