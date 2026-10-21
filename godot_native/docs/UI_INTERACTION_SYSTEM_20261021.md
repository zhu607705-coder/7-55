# Status update: user-selected low-occlusion surfaces

The material/type description below records the earlier structural candidate, not final visual approval. The user subsequently locked five role-specific proposals. See [UI_SELECTED_HANDOFF_20261021.md](UI_SELECTED_HANDOFF_20261021.md) for the current exact type, none/scrim and placement contract. Unselected phone/app/device identities remain scoped rather than receiving a blanket skin.

# Interaction surface map — 2026-10-21

This maps the native game’s existing owners, not a new gameplay state machine.
Presentation may restyle a control. Only existing controller intents may earn
progress, consume items, advance narration, or persist a save.

## Common visual states

`interaction_chrome.gd` provides paper faces, navy equipment trays, thin metal
edges and a coral selection mark. `apply_states` assigns normal, hover, pressed,
hover-pressed, disabled and keyboard-focus styles explicitly. Pressed darkens the
face; disabled reduces contrast; focus is a contrasting transparent outline,
separate from selection. No style changes a minimum size, callback, permission or
input owner. `HardwareDetail` is mouse-transparent and never focusable. On a
larger transparent touch target, detail/focus follows the actual `painted_rect`.

## Surface owners and transitions

| Surface / owner | Inputs and ordinary transition | Blocked, failure, success | Close / interruption |
|---|---|---|---|
| Phone status / `phone_chrome.status_right` | Mouse/touch or focused button activation emits `page_requested(control_center)`; clock/network/battery read shared state | Disabled when Main owns an overlay. Low battery and untrusted clock retain authored warning values; opening never earns evidence | Existing Control Center return restores its previous app and draft |
| Phone task tab / `phone_chrome.task_button` | Mouse/touch, Enter/Space via Button emits `task_requested`; Main opens journal | Shared task facts only. Four ordered digit slots remain masked until earned; no answer invented by presentation | Journal Close/resume returns through Main; task tab blocks while modal owns input |
| Phone inventory handle / `phone_chrome.inventory_handle` | Click/tap or keyboard activation toggles drawer; pointer drag moves authored drawer vertically | Hidden during original chapter-one inventory lock and when no owned items. Modal blocks input. Reading-page anchor keeps existing larger transparent hit area | Collapse clears local selection via existing intent. Page/anchor changes cancel owned gestures; dragging the handle suppresses accidental click |
| Item slots / `inventory_item.gd`, PhoneChrome `InventorySlot` | Single tap/Space selects; double tap/click or Enter inspects. Native drag submits canonical `{kind: inventory_item, item: id}` | Selected slot gains coral edge/mark; never a green check gem. Disabled slots cannot start gestures. Rejected drop emits existing feedback; item remains owned | Escape cancels drag. Hidden/disabled/focus loss cancels owned touch/drag. Item-inspection close restores prior focus via Main |
| Touch item gesture / `inventory_item.gd` | Single touch owner; 10px threshold; early motion along scroll axis scrolls, held motion can drag | Extra fingers cannot acquire a second source or release first owner. Drop accepted only by existing target/controller | Canceled touch releases ownership, not an item-use intent |
| Combination / `InventorySlot._drop_data` | Different item accepts canonical drop and emits `items_combined` | Existing controller validates recipe and consume/retain semantics. Self-drop rejected. UI cannot manufacture result | Failed recipe remains recoverable with original inventory state |
| Acquisition / `phone_chrome.acquisition` | Actual increase in owned IDs triggers existing item-art flight | Restore does not simulate a new reward. No success badge or progression callback added | Existing expiry/settle lifecycle; exact digit and item receipt geometry preserved |
| World inventory / `main.gd`, `world_inventory_item.gd` | Main owns expand/collapse and keyboard focus; shared native item gesture submits world use | Existing range, physical target and story gates; each rejected use retains readable feedback | Collapse returns focus to world only when no other modal/phone owner exists |
| Task/journal / `native_journal_view.gd`, `main.gd` | Current objective first; optional evidence comparison and lazy history remain separate | Task copy reflects controller facts; navigation cannot solve puzzle | Close/Escape/resume through existing Main owner, with focus restoration |
| Dialogue / story hosts, `world.gd`, narrative views | Continue/interact only through existing narrative owner | Speaker, source text and completion proof remain authored; subtitle queue has one owner | Modal/media interruption obeys existing session rules; no decorative animation completes dialogue |
| Notices / Main notice queue + PhoneNotice/world subtitle | Controller feedback enters existing queue or device-local feedback surface | Success/error are text and material, not duplicate badges; timing and audio ownership unchanged | Expiry remains queue-owned; decorative UI never clears story facts |
| Device/puzzle overlay / chapter-specific views | Existing controller-backed real controls; keyboard/touch events shared | Disabled or out-of-order actions remain rejected by controller | Existing close/cancel/retry owner restores world; no generic card replaces puzzle geometry |

## Phone chrome geometry held fixed

- Phone interior 424×854; status band 40px.
- Task tab 76×30, or 136×30 with earned-digit slots. Digit font, positions,
  visibility and `digit_clue_geometry` are unchanged. The plain task label is
  enlarged inside its existing single-line rectangle.
- Drawer body 74px; slot 52×52; slot separation 8px; existing 38/40px handle.
- Dynamic reading anchor, transformed release coordinates, touch ownership,
  scroll range, item artwork and acquisition path remain the existing code.
- Screen-wide grid remains hidden; material details do not cover app text.

## Component families and hierarchy

| Family | Existing surfaces | Deliberate form and hierarchy |
|---|---|---|
| World | Exploration/location/mode/feedback | Separate small location and mode signs; content-measured feedback rather than a full-width strip. Original world art, camera and authored coordinates stay authoritative. |
| Investigation folder | Journal, owned items, clue comparison | Bound paper with cloth spine, fixed binding loops and page edges. Current-page index is a real title, not a fake tab. Journal leads with the current scene artwork thumbnail and controller objective; resume is a compact primary action; history and comparison are subordinate. |
| Evidence sheet | Item inspection | Independent loose sheet, original item image, exact canonical document/observation text and existing use action. No invented stamps, codes or claims. |
| Dialogue | Library and chapter-three narrative | Speaker/body/prompt hierarchy with measured readable body font. Preserve each host's real timing and advance/pause contract; do not add a universal advance button. |
| Phone | Existing apps and device chrome | Preserve source app identity and original input rectangles. Hide the full-screen grid; use clean Chinese body text and one common title/body/digit family plus explicit bitmap icon roles. Known unsupported symbols use deterministic pixel primitives, not platform fonts. |
| Physical devices | Theater terminal and room302 studio | Terminal has a metal shell, inset readout and tactile keypad; submit is primary. Studio chooses portrait composition from available geometry, independently of keyboard/touch hardware. Keep original device colors and control mapping. |
| Utility menus | Control center and file dialog | Save is the primary action; other choices are neutral and reset is explicitly distinguished. Close stays outside long scrolling content. |

## Input ownership (unchanged)

```text
exploration ── P ── phone
    │                │
    ├─ Tasks ─────── journal ── comparison
    │                │
    └─ inventory ── inspect item
                     │
        close / Esc ─┴── prior valid focus / world fallback

story or device host owns input → world gestures are blocked
modal owner closes              → existing owner/focus is restored
```

These are existing entry points, not newly invented keyboard commands. Source
story controllers alone issue progress, item consumption and save changes. The
same feedback event remains owned by its original queue; an active compact
terminal can suppress only its redundant background rendering.

## Coverage and limits

This redesign applies shared type/material/state roles to the existing surfaces
above. It does not replace source-specific minigame boards, invent a new map,
rewrite placeholder story content, change world artwork, or claim every
cinematic has received an aesthetic overhaul. The existing campus-navigation
app remains an app; the campus-world screenshot is exploration, not a new map UI.

Headless checks verify state/geometry, not aesthetic quality. Actual screenshot
inspection, keyboard/touch end-to-end checks, device-specific layouts and the
final commit's CI remain independent acceptance gates. The research document
separates inspected game references from inaccessible user-supplied pages.

## Latest typography and corner direction

All ordinary UI Chinese, Latin text, numerals, headings and buttons now use the same Campus UI Sans instance; size and hierarchy distinguish roles, not a second display family. A bundled symbol-only fallback remains for the documented missing symbols; known phone pictograms use explicit bitmap primitives. No platform font fallback is enabled. Original baked lettering and the endless-stair authored spatial Label3D art remain source artwork, not another HUD family.

Shared controls use small 4px corners and panels 6px, with antialiasing disabled; notebook and primitive shells use integer rectangle steps. These paint profiles do not change hit rectangles or content padding. The actual GPU component specimen is a separate visual gate, not proof supplied by style properties alone.
