# Button directions: A/B visual study only

This isolated study starts from PR188 head `e894c3f`. It changes no production
script, autoload, route, save semantics, background art or font. The study script
instantiates the actual entry and pause menu, then changes only those preview
instances. Existing button callbacks and keyboard focus remain attached.

- A: 4-unit corners, restrained paper keys, low lift, grouped secondary actions.
- B: 1-unit corners, flat paper rows with thin separators, dark ink primary action.

Both deliberately depart from the initial 10-unit keycap specification. They are
proposals for the user's choice, not an approved replacement. No production
entry links here. The preview branch must not be merged or deployed as a product.

Run headless layout/input checks with `UI_CAPTURE_VALIDATE=1 UI_CAPTURE_DIR=/tmp/study`
and `godot --headless --path godot_native --script res://design_studies/button_directions/capture_study.gd`.
For actual screenshots omit the validation flag and use a real GL display.
Use Godot 4.7.1 and fresh XDG data/config/cache directories. The dedicated workflow
runs only on this preview branch and uploads four original PNGs plus a receipt.

The four views preserve original captions. The shared compact layout groups
campus choices, import/export, and window/screenshot actions; it does not modify
those actions. Each target is at least44px high. Headless tests check containment,
callbacks, Tab movement and a real pointer-operated close. Screenshots are DEV
fixtures, not gameplay completion or physical-phone performance evidence.
