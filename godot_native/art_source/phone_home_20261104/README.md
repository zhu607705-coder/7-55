# Phone-home bonsai source

The runtime crop is `../../assets/native/phone_home/bonsai_stairs_20261104.png` (703×873, SHA-256 `5795298a507de5bbbbd5dec5a1320ca5d9451cdc5552c8a7df37c166d00e9d2c`).

`generated_raw_v2.png` is the original image-generation output (SHA-256 `343a666a08e90c654ff2cc46a41ae2c68e7f48bfc8385a20cd3aa819e9ca6497`). The associated prompt is preserved in `imagegen_prompt_v2.txt`. The runtime crop is x190, y312, width703, height873, without recoloring or alpha thresholding.

The approved current placement is the left tower stair. `PhoneHomeArt.BONSAI_SOURCE_RECT` is (260,524,40,51); the shared hit rectangle is (258,524,50,58). Flower petals and center use this same origin. The move changes coordinates, not the image bytes, original app icons, puzzle rules or tower geometry. Original right-side placement is historical.

The independent preview regression covered 18 combinations of three viewport sizes (390×844, 430×860, 1440×900), three brightness values (0,65,100), and two flower states: 650 assertions, zero failures. Those prior results do not replace the complete-repository integration checks recorded with this PR. Touch was emulated, not physical-device acceptance.
