# Canteen tray-to-drink objective handoff

The native objective previously stopped producing guidance after the third dirty tray. The generic “在食堂截住纸条” returned while the source puzzle still expected the player to investigate the queue, prepare a drink, and use the existing promotion target.

This bounded presentation change extends `scripts/presentation/canteen_objective.gd`. It reads existing facts and returns a title/detail pair. It does not write to a save, change dialogue, award an item, consume currency, add an interaction, or create a progression gate. The existing Main journal and objective consumers display the result without new UI.

## Source wording and branch order

`src/core/QuestModel.ts:461–508`, `canteenInteriorTask`, is the original authority for these titles and their order:

| Existing condition after three target trays | Original title retained |
| --- | --- |
| Queue challenge unseen | 查看第三列队伍和新品宣传板 |
| Queue seen, shelf unread | 查看饮料货架的颜色顺序 |
| Shelf seen, no product or placed drink | 按货架顺序调配今日新品（n/3） |
| Product owned, not placed | 把今日新品气泡水放入宣传板空杯位 |
| Drink placed, queue shift pending | 等待第三列队伍让出位置 |
| Queue opened, phase is `menu_order` | 看看菜单里有什么异常 |

The early paper/auntie/tray objectives retain their existing ordering. Once the original queue transition opens the gap and sets `menu_order`, the existing journal displays the source menu title and exact hints: “两种模式下，菜单有几个字不一样。” and “深色观察看字，浅色操作下单。” These are original QuestModel text, without added editorial wording or a revealed menu answer. `pickup_search` and every subsequent phase keep the current native objectives.

The original controller does not require a player to follow this suggested order. The change preserves that freedom. Reading the shelf early still counts; collecting or mixing early remains available. Once the existing queue conversation is seen, a previously read shelf goes directly to mixing guidance.

## Editorial detail versus authored dialogue

The following journal details are new UX copy, not new lines attributed to a character:

- The queue detail says to continue pursuing the paper, then speak to the front student and inspect the promotion. It restates the already earned pursuit and points to visible authored objects. It does not claim the paper is behind a particular window.
- The shelf/mixer details summarize the existing student's statement that the front of the queue wants to see the new product, and the original QuestModel hints that machines supply ingredients and the mixer records pour order.
- The product detail names the visible promotion board and empty cup slot. It does not provide a recipe, menu choice, pickup number, or later solution.
- Dark-mode details add “切回浅色操作。” because these existing physical targets are exposed in light mode. Waiting for a placed drink's queue presentation does not ask for a mode switch.
- References to resuming the paper pursuit are connective UX wording, not an additional prerequisite or assertion about the paper's precise location.

Source evidence:

- `src/data/chapter3-canteen.content.json:43–78`: queue dialogue, machines, shelf and mixer prompts, promotion copy, and queue shift dialogue
- `src/modules/ChapterThreeCanteenController.ts:258–383`: existing queue/shelf facts, free ingredient collection, ordered consumption, failed/successful recipe outcomes, promotion consumption, and terminal queue transition
- `src/scenes/rpg/CanteenInteriorModel.ts:249–287`: authored mixer, promotion, and queue-student targets and stand points
- Native consumers remain `scripts/chapters/chapter3.gd:706–719` and `scripts/main.gd:935`

There is an existing numbering inconsistency: QuestModel/content call the promotion location the third window, but the actual model target at x1232 is labeled “第五个窗口宣传灯箱空杯位”. The new detail deliberately omits a window number and identifies the visible board/empty cup slot. No target or original content was edited.

## Verification

`tests/export_canteen_handoff_source.mjs` extracts and executes the original TypeScript `canteenInteriorTask` AST. The checked-in fixture covers 96 combinations of source phase, queue/shelf/product/promotion flags, and partial sequence count. Native tests compare every title and ID in both light and dark mode (192 cases), assert no recipe disclosure, and compare the complete save before/after projection.

`tests/test_canteen_drink_handoff.gd` runs the existing Main scene headlessly at 390×844, 430×860, and 1440×900. It checks all handoff details for full text visibility and onscreen journal controls, retains the existing return focus, and checks exact save preservation on journal dismissal. It also runs queue dialogue → ingredient collection → wrong mix → partial correct mix → close/reopen → successful retry → item selection → promotion → the existing queue acknowledgement. Wages, cash, tissue, source failure output, and later phase behavior remain unchanged.

The queue interaction uses an explicit controller target intent at the authored stand (735,255). The original randomized counter NPC can be nearer there than the queue student: a counter NPC at (790,214) is about 23 px from the player by its bounds, while the queue student is 37 px away. Therefore Space can select that NPC instead. The test does not override the nearest target or change the runtime to hide that overlap. All subsequent devices, pours, journal returns, item selection, and promotion use actual routed keyboard/pointer controls from authored stand-point fixtures. Continuous/manual navigation and pointer targeting of the queue student remain separate acceptance work.

These are automated source/Control/layout checks. They do not claim a GUI screenshot review, continuous player walking, or full manual campaign acceptance. The optional `CANTEEN_EARNED_SAVE` input is only read. Tests run with developer mode and isolated `/tmp` XDG directories so the formal profile cannot be saved over.

Commands from the original repository, after integration:

```sh
node godot_native/tests/export_canteen_handoff_source.mjs --source-root . --check
# Run the standard native validator for aggregate integration acceptance:
node godot_native/tools/validate_native.mjs
```

The new `test_*.gd` script is discovered by the existing aggregate validator. Its default uses a documented post-tray fixture derived from the original canteen checkpoint. Supplying an earned save tests that actual saved state without changing it.

`tests/test_canteen_menu_objective.gd` adds eight executed-QuestModel cases for light/dark mode, unseen/seen dark menu clue, and pending/completed queue shift. It reads the actual post-promotion snapshot when supplied and checks Main Tasks/journal through routed pointer, touch, and keyboard input at 390×844, 430×860, and 1440×900. Full save/action-count equality, journal line visibility, return focus, and later-phase exclusion are asserted. The existing handoff test now expects the source menu objective after the unchanged promotion acknowledgement.
