# Make visible kayak paddles work with a mouse

The final PR68 package showed left/right paddle controls in its 430-wide layout, but clicking them with a mouse or touchpad did nothing. A/D immediately moved the same live boat. Both bound-window and physical desktop clicks were tried. The inherited mouse branch handled walking controls only; kayak strokes were available through keyboard and ScreenTouch.

This change gives the painted paddles a mouse owner. Press inside a visible rectangle arms that side; release submits one existing `State.lake_world_stroke`. The renderer and mouse hit test use the same 100×92 rectangles. The pressed border and short release/direction feedback expose ownership without adding another permanent control. Hidden desktop paddles do not intercept water clicks, while a visible touch-capability fallback works independently of viewport width.

Main forwards only an already-owned mouse move/release before GUI routing. Like the original `RpgGameHost.tsx` pointer capture and window pointer-up listener, dragging outside the button is not cancellation: the release still belongs to its starting paddle. Releasing over another control does not activate that control. Focus loss, resize, changed world, phone/Tasks/blocked presentation and capture mode cancel ownership. Repeated release, emulated touch-mouse events, and competing finger/mouse pointers on one side cannot duplicate a stroke.

The existing native finger path, its 24-logical-pixel reverse threshold, keyboard input, impulses, capsizing, full-hull separation and receipt validation are unchanged. The source web pointer threshold is 18 physical pixels; this narrowly scoped fix matches the current native finger behavior and does not claim complete gesture-layout parity or physical-phone acceptance.

## Validation boundary

An initial real-Main event fixture reproduced six missing mouse behaviors among 22 checks. Its first draft happened to click an underlying exit target in the old world handler; that fixture issue is preserved, and the reproduction was rerun at the same neutral channel setting as the actual failure. The strengthened final test also validates correct side/direction, competing pointers, blocked presentation and desktop fallback; final counts are recorded with the release gate. These are synthetic input checks, not manual play.

Actual CUA used the identical earned channel save from the failed published package. At 430×860, the same previously ineffective bound clicks now move the boat. Physical mouse clicks also work. Downward drags released below the buttons reverse travel; an upward drag released over the top Tasks area remains owned by the original paddle. A later ordinary Tasks click opens it, Return restores the world, and mouse paddles still work. Normal Save/close exited 0. Every item and lake fact matches the starting save, with no reward, loss, difficulty change or main progress edit. The main C4 save remains unchanged at 270 operated / 10 scoped formal acceptances.

Actual sessions use Dummy audio; there is no listening claim. Focus loss, cancellation during a held gesture, repeated/emulated events and simultaneous physical-finger cases are bounded automated coverage unless separately recorded as actual. The existing portrait kayak status-line clipping is outside this fix.


## Final gate

The strengthened pointer fixture passes 32/32 against both source and fresh packed resources. Nine affected scripts pass, including world picking, Main shell/modal input, source lake differential, fixed-step guard, mobile world feedback and fishing focus return.

Fresh official Linux export exited 0. Runtime SHA-256: `bce46b7845cfebaf789386d13b7569e9488094cda77fd81c876faeff68ec51f7`. PCK: 583,716,428 bytes, SHA-256 `c7b2895a51448ef1da87f41e89c16c2ee9edd887c6e9564911938c7dabf02a67`. Actual final 390×844 normal reload preserves all items/lake facts, returns to the channel and accepts visible left/right mouse clicks. Resizing to desktop 1180×812 restores the existing keyboard presentation without permanent virtual paddles. Normal Save and close succeed. Main save remains `520d4d56991ca08fbbfa34e42b24e24cdd7778c00ec98ea5c594236396c75460`.
