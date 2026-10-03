# First wet-paper search result order

The first wet-program search put the newly revealed witness thread below every ordinary forum post. A player received a success message but then had to search the old feed for the result. The source React page places quest posts before ordinary posts (`src/scenes/phone/P02_CC98/index.tsx`, `visiblePosts`).

The native first-search augmentation now inserts the witness after the existing quest prefix. Previously collected witnesses already used that prefix and keep their behavior. Post contents, existing links, explicit keyword collection and app-exit search reset are unchanged.

Validation: the baseline failed 9 ordering assertions across 390, 430 and 1280 widths; the corrected candidate passes all 222 focused checks. The existing ordinary lake-app regression passes 635 checks. Real 430×860 pointer play on an unchanged earned pre-clue save confirms the wet-program drag, nearby witness result, thread/Back, prior ordinary link and Exit/re-search. Search alone leaves the location state and items unchanged. This is a focused result-navigation check, not whole-campaign or physical-device acceptance.
