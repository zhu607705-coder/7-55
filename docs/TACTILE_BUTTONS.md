# Shared tactile buttons

## Scope

`godot_native/web/button.css` is the single browser material implementation. The production Godot HTML shell inlines its exact bytes at export and verifies the SHA-256 in delivery verification. The retained React `Button` imports that same file. It is not a second production runtime.

No generic Button existed. The new `Button` forwards native props/ref, defaults to `type="button"`, and supports `variant` and `size`. Existing `PhoneNavButton` and `PhoneListRow` retain their public contracts. Native disabled semantics, handlers, IDs, routing, save data and scene controllers remain unchanged. Text arrows and optional leading icons are decorative (`aria-hidden`).

The coverage ledger is `docs/ui/button-coverage.json` (original locations for traceability). It covers paired and self-closing JSX tags. 353 shared component uses include the chapter-introduction action. The 32 remaining native elements are the shared implementation, physical objects, collectible targets, map/seat positions, or transparent scene/backdrop hit regions. Their geometry/affordance must not become raised rectangular keys.

Rich list rows, app launchers, navigation and status controls use `data-layout="content"`: the existing layout remains, while the shared neutral material replaces their former skin. Ordinary action buttons use the exact 40u key geometry. This prevents multi-line cards from being cropped into 40px keys and preserves the existing navigation hit area. No global `button` selector skins scene objects.

## Material contract

- `md`: label 14px, u = 1px. `lg`: label 16px, u = 16/14px.
- All material geometry derives from u: height 40u, padding 18u, radius 10u, border 1u, icon 16u and press offset 1u.
- Primary: #404859 → #273042; secondary: #FFFFFF → #F4F5F7; tertiary: #F3F4F6 → #E7E9EC. Ghost has no face at rest. Text has an underline and moving arrow.
- Exactly two inset shadow slots precede two outer slots in each rest/hover/pressed state. The second inset becomes transparent when pressed. Insets belong to the actual element, never an overlay.
- Transform 120ms; shadow 140ms; face/label/edge color 160ms. Reduced-motion disables transitions. Focus-visible and native disabled remain available; forced-colors retains a visible border and focus outline.
- Scoped material declarations deliberately use `!important` to replace legacy scene skins without changing positioning or content-layout rules. Existing selection classes/ARIA values retain a neutral visible edge.

## Verification

`node scripts/verify-button-material.mjs` checks coverage, shell hooks and exact export provenance/tamper rejection. `scripts/verify-button-material-browser.mjs` exercises all ten variant/size combinations, pointer press/hover, keyboard focus/Enter, native disabled, mobile overflow, the actual production shell template presentation and real retained phone/control-center controls. CI uploads screenshots, computed style records and commit/tree provenance.

The acceptance board is **not** a game screenshot. The shell presentation fixture is **not** proof of Godot engine loading or gameplay. Native Web acceptance remains independently required. A retained React build likewise does not establish production Godot acceptance.
