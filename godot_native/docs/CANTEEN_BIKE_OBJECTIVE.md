# Bicycle objective follows cleaning and payment

The native `chase_ready` task previously always said “清洁车锁并用餐盘回收费支付骑行”, including after payment. The source controller intentionally keeps `chase_ready` during both cleaning and payment; only `startChase()` changes the phase to `chasing`.

This change extends the existing read-only `canteen_objective.gd` projection. Main Tasks and the journal already consume it. It reads the existing `bikeLockCleaned` and `bikePaid` facts and changes no interaction, gate, item, wallet, controller, save or simulation.

| Existing facts | Task | Detail |
| --- | --- | --- |
| Not cleaned, not paid | 清洁车锁并用餐盘回收费支付骑行 | 在车锁旁清除反光并付款。 |
| Cleaned, not paid | 用餐盘回收费支付骑行 | 餐盘回收费已到账。用 2.00 元支付一次骑行。 |
| Paid | 骑车追上纸条 | 车锁已开。回到共享单车，选择“开始骑行”。 |

The first title preserves the native title. The cleaned title narrows it to the remaining action. The clean detail is original `bike.hints[0]`; the payment detail is original `bike.unlock`; the paid title is original `bike.task` without its `任务：` prefix. The paid detail is new UI guidance naming the already visible “开始骑行” button. It is not dialogue. Dark mode adds “切回浅色操作。” only while cleaning or payment remains, matching the existing operation gates. Optional dark code observation remains optional. No recipe, number answer, later destination or route is disclosed.

Source evidence:

- `src/core/QuestModel.ts:742–774`: active canteen quest selection; `chase_ready` uses `bike.task` and `bike.hints`
- `src/data/chapter3-canteen.content.json:151–181`: authored bike prose and task
- `src/modules/ChapterThreeCanteenController.ts:630–700`: cleaning and payment retain `chase_ready`, retain tissue, consume wages and exactly ¥2 once, and start the chase only from the existing paid state
- `godot_native/scripts/ui/c3_canteen_device_panel.gd:63–73,211–216`: the existing Clean, Pay and Start Ride controls

## East Canteen phone summary assessed separately

`chapter3.gd:view("c3_canteen")` at lines 121–130 builds a cumulative page from the original entry dialogue, the original tray assignment plus the returned count, and the learned shelf record. `pages()` keeps this page available while the canteen route remains active. The summary does not select the current task and does not drive progression. Consequently it can still show the old tray instruction with 3/3 after defense and on campus.

That code structure explains the observed text as accumulated earlier information; it does not prove an explicit author decision to keep imperative wording after completion. The wording can be confusing, but changing this separate summary would broaden the presentation scope. It is unchanged here.

## Verification

`test_canteen_bike_objective.gd` runs the actual Main scene headlessly. It covers all three guidance states, both modes and both optional observation states. It checks current-task precedence, original source wording, later-phase suppression, no extra disclosure and complete save equality. At 390×844, 430×860 and 1440×900 it uses pointer, touch and keyboard Tasks controls, verifies onscreen untruncated text, return focus, and unchanged action count/save. It also uses the real bike modal controls for Clean → close → Tasks → reopen → Pay → close → Tasks → reopen → Ride, verifying the existing item, wallet and phase outcomes.

The device-flow fixture stands near the original bike anchor, using the same nearby walkable position as the existing bicycle world-drop test. It is not a claim of continuous walking or earned manual campaign completion. All runs use isolated `/tmp` XDG directories and developer mode; no formal save is rewritten. No GUI was used.

Final focused results on the isolated staged project:

- Bike objective: 1,444 checks, zero failures
- Existing objective journal: 338 checks, zero failures
- Drink handoff: 1,826 checks, zero failures, 192 source cases
- Menu objective: 756 checks, zero failures, 8 source cases
- Pickup objective: 1,214 checks, zero failures, 47 source cases
- Chapter 3 controller regression: 72 checks, zero failures

The four earlier objective tests stop asserting that `chase_ready` has no projected guidance; their unrelated phase exclusions remain. The new test covers that phase explicitly. Aggregate release verification and earned CUA acceptance remain the integrating task's responsibility.
