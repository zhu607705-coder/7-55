# Compact world inventory

Compact world views now have an expandable bottom item bar. The 44px handle and 48px item controls occupy the letterbox below the world, preserving the scene aspect ratio and visible movement controls. Desktop split view keeps its existing open item bar. Open/closed state is local presentation state and survives viewport orientation changes without changing story saves.

A quick horizontal finger movement scrolls the item row. An upward movement drags an item toward the world; holding for 220ms also permits a deliberate horizontal item drag. A tap selects, a double tap opens the canonical item description, Enter inspects and Space selects. Existing 10px movement, 380ms double-tap and 24px same-item thresholds remain. Slots retain node identity, scroll and focus during selection refreshes.

Dialogues and modal/document/game ownership disable inventory interactions while retaining source-permitted movement. Closing, resizing, hiding or removing a slot safely cancels its active gesture. The actual world-object resolver and controller still validate position, mode, item and progression.

The new 206-check Main fixture covers 390/430 portrait, compact landscape and desktop; it uses real routed purchase/return controls, actor drops, scrolling, inspection, cancellation, orientation and manual movement proof. These automated checks are separate from actual cloud CUA and physical phone acceptance. Actual cloud CUA repeated the player-earned purchase save at 390×844 and 430×860: expand the bag, drag the gamepad onto the actor, then move with D. A missed release retained the item. Expanded/collapsed state and earned progress survived 844×390 landscape and a 390×846 portrait return. This verifies mouse/keyboard operation in compact windows; a real Android/iPhone touch test is not claimed.

The exploration viewport still uses a short 16:9 letterbox in portrait. The bottom bar fixes access to inventory but does not establish final mobile exploration quality. A separate camera/layout improvement remains under review. Authored cinematics and minigames retain their own aspect contracts.
