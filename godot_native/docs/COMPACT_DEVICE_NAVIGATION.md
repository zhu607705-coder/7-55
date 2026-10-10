# Compact world-device navigation follow-up

The desktop split layout exposes phone and world simultaneously. On a compact window, required world device actions previously changed `native.page` while leaving its phone surface hidden. This was an actual interaction blocker, distinct from controller proof tests.

`main.gd` now listens to controller `action_completed` results for explicit page intent. A compact world action reveals its existing device phone page without changing the controller, world scene, position or camera. Ordinary refreshes are not navigation. Desktop split mode stays split. Returning to the world or explicitly leaving the device clears the runtime-only origin marker.

A genuine `narrative_owned` result from the opened device restores its originating world before the source dialogue starts; menu/ticket callbacks therefore cannot deadlock behind hidden-world pause. Explicit phone-home handoffs are visible, including rain return with its retained dorm scene and the real final lamp acknowledgment. Scene-entry pages and minigame/world-effect requests retain their existing presentation owners.

Generic form LineEdits now explicitly set dark text/caret and a muted dark placeholder against their light background. Layout, values, controller validation and hit areas are unchanged.

## Acceptance

`test_compact_device_navigation.gd`: **694 checks, zero failures**. It instantiates real Main/State/world, checks displayed bounds and sends pointer events through the root viewport at390/430/1280 widths. Source-phase fixtures isolate UI routing; they are not a fresh campaign proof.

Covered classes: canteen mixer, ordering kiosk, shared bike, theater ticket kiosk and program console; Library entrance record/catalog; Chapter4 duty board, elevator, light grid and numeric positioning device. Tests apply real ingredients, options, codes and numeric values; exercise close/return/reopen; preserve world position; finish the source menu/kiosk dialogue; and verify actual rain-rescue and lamp-closure callbacks. Input/placeholder contrast is at least4.5 against the rendered form background.

The graphical acceptance run produced31 page/form/return images with124 successful capture checks. Filled390px forms show the real kiosk code0832 and positioning values−2/1/3. These checks close the bounded compact-device visibility and input-contrast defect, not all mobile presentation or ordinary app-entry coverage.

The follow-up aggregate passes78/78 stages with zero warnings. Runtime/controller campaign evidence remains separately scoped; see `COMPACT_DEVICE_VALIDATION.json`.

## Separate open route issue

An independent actual Home-icon/app-input probe confirmed that the active lake location search is not yet wired into ordinary CC98 witness posts, WeChat friend messages and the Zjuding map cross-check, and the contextual Weather dryer. That required story-app entrance wiring is a separate follow-up. Do not treat the fresh controller campaign or these device-page checks as proof that every ordinary phone route is reachable.

## Subsequent required app-route batch

The lake CC98, Library, WeChat, map and contextual Weather entrances listed as open at this commit are implemented and tested in the following batch. See `CHAPTER3_PHONE_ROUTES.md` and `LAKE_APP_VALIDATION.json`; the historical compact validation JSON retains the scope at its original commit.
