# CC98 investigation and evidence uploads

The Library investigation thread now reserves space beside the compact inventory rail, measures wrapped reply text, and renders integer floor numbers. A visible jump control moves to the existing four evidence cards after the replies. The original BD reply order and domain actions are retained.

Each full evidence card accepts its matching held item through the existing `lib_upload` action. Explicit upload buttons invoke the same action. Wrong-card feedback stays readable during inventory refreshes. Missing items, repeated submissions, network requirements and later phases remain controller-checked. A successful archived-rule upload consumes that original; the non-person proof, seat receipt and presence proof remain held for the recovery application.

`test_cc98_investigation_layout.gd` covers actual Main controls, precise slot dispatch, repeated/wrong/missing submissions, scrolling, narrow layouts and controller guards. `test_earned_catalog_title.gd` retains the earlier copy-title workflow. Source reference: `src/scenes/phone/P13_CC98` and `src/modules/LibraryFinalsController.ts`.
