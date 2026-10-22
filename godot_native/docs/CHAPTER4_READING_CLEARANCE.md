# C4 fallback reading clearance

The original maintenance clue's first glyph strokes touched/clipped the phone's left border, and the collapsed bag overlapped the Return row. The title itself was present. This change gives only c4_notes/c4_device fallback body text a12logical-pixel horizontal inset and opts those two pages into the existing reading bag anchor. Original text, font, title, actions, controller and expanded drawer geometry remain unchanged. Other pages keep their existing policy.

The fallback already supports body_inset; the two pages now use a minimum12 while honoring a larger supplied inset. The bag reuses the established desktop outside-edge and compact header placement, including its44physical-pixel target, gesture cancellation and absolute style-margin reset.

Focused reproduction:256checks/75failures before,256/0 after. Existing reading-anchor258, modal/world-input7 and floor-panel49 checks pass. Other fallback policies and facts/items are checked. No broad aggregate or new export was run for this localized presentation change.

Actual same-checkpoint comparison: the already-completed diagnosis no longer opens from the physical cart, and ordinaryPhone correctly opensHome. That initial approach is retained as actual-before-1180. I therefore replayed the original clock/cart sequence from unchanged installedplatebe5db037, captured an earned pre-diagnosis save38105c2862640d2751c1811bf4093d07fda14a944b03c5b65d6f34e00a6b7c29, and used its exact bytes in the candidate. No state was edited.

Before1180: actual-before-diagnosis/captures/c4_device-102699.png; before390: c4_device-146127.png. After1180: actual-after-1180/captures/c4_device-29170.png; after390: c4_device-277787.png; actual426x860: c4_device-320923.png. Exact430x860 is automated coverage, not the window-manager result.

Actual390 drawer opening, card keyboard inspection withEnter, Escape return and drawer closing work. The physical double-click attempt did not open inspection; no cause or fix is claimed. The now-clearReturn row reaches the cart; after a patrol safe-return during tool delay, ordinaryD/Space reopens the same diagnosis. Chapter facts/items stayed identical. These are native source-project inputs withDummy audio, not hearing/finger-hardware/package acceptance. F10 remains untested.

Four proposed files: scripts/main.gd, scripts/ui/phone_chrome.gd, tests/test_chapter4_reading_clearance.gd, this document. The separate Recovery reading candidate modifies the same anchor function; retain its page rules when eventually combining the C4 opt-in. Do not overwrite that candidate with this snapshot. Earlier38unique paths remain frozen; this adds only2new eventual paths (test/document), making40if the user selects the full union. No Git mutation occurred.
