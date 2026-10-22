# Tiyi presence-record form

The Library presence-record task uses an inline native form with three numeric fields, source steppers, persistent rejection guidance, earned evidence references and a completed receipt. It replaces the generic modal consumer of `lib_audit`; the existing submission validator, proof reward and narrative gates remain authoritative.

`lib_audit_value` stores only the source's three bounded integer draft fields while investigation is active. Changed values emit the existing `tiyi_audit_value_changed` presentation event, whose source audio owns gain0.28 and playbackRate1.22. Rejected, locked and unchanged native edits do not create new cues or rewards.

The authored source provides numeric steppers. Native keyboard entry is an additional convenience; it does not loosen the validator. Empty and noncanonical input remains local until validated. Source defaults are5/45/1; a saved arrival zero uses the original `saved || default` fallback on remount. Receipt values and the public-notice number are displayed as integers after save/reload.

Source references: `src/scenes/phone/P06_Tiyi/RouteAuditPanel.tsx`, `src/modules/LibraryFinalsController.ts`, and `src/data/library-finals.audio.json`. Executed source fixtures and portable native tests cover setter bounds, rejection tiers, no-op/locked audio, successful proof, draft lifecycle, ordinary save/reload and duplicate protection. Physical-mobile input and subjective audio listening remain separate acceptance work.

At compact widths the content inset reserves the collapsed inventory rail throughout form and receipt scrolling. Actual exported Linux play at390px verified keyboard7/47/3 submission, proof acquisition and readable scrolled receipt/source cards from an ordinary earned save. Earlier error-tier/back/reentry checks belong to the pre-inset capture; the final inset changes only presentation coordinates.
