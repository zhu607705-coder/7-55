# Chapter 4 guard capture presentation

On guard contact, the native world previously submitted patrol recovery or chase
failure immediately. This omitted the original caught dialogue and its reading
time. Ordinary reload could therefore cycle through several unattended chase
admissions before the player understood what happened.

The original `ChapterFourGuardPresentation.ts` pauses physics, displays
`你在这里干什么？已经这么晚了，快点回去，要清楼了。` with speaker `保安` for 5200 ms,
then resumes through the caller's existing callback. Scene shutdown or destruction
cancels the callback. Both maintenance patrol and final pursuit use that helper.
Automatic retry and pursuit arming grace are original behavior and remain intact.

## Native ownership

`chapter4_guard_capture.gd` owns only this presentation clock and one pending
controller request. World contact creates it once. During the hold the world
blocks movement, interaction and inventory drops, retains the guard/player
positions, and continues existing visual fades. The clock advances while the
world is visible and focused with no competing modal owner. Hiding or suspending
the world retains the remaining reading time.

The captured scene, floor, phase, time state, mode, guard mode and chase attempt
must still match before completion. A changed context, world removal or disposal
cancels the request. Completion returns the existing action once; `State.act`
and the original Chapter 4 controller still own relocation, attempt counting and
save changes. No second progression state is introduced.

## Validation status

The initial candidate passed 62 capture checks, 17 existing guard checks and 7
modal/world input checks. The final fade-preserving revision passed 64 capture
checks plus the same 17 guard and 7 modal checks. Those include both actual World contact branches,
5199/5200 ms boundaries, duplicate contact, pause, cancellation, context changes,
physical position preservation and disposal without retry. The updated passive
observer also passes its parser check.

The initial actual chase replay used an unchanged earned, zero-attempt ordinary
save. A passive observer recorded two complete capture cycles, with 5222.85 and
5214.56 ms of reported presentation time. Sampled wall intervals were 5547 and
5567 ms; the timer was not claimed to be exactly 5200 ms of wall time. Both actor
positions and the attempt counter stayed fixed throughout each hold, followed
by exactly one attempt increment. A third capture was incomplete at the 24 s
recording cutoff. These were unattended admissions, not player skill attempts.

The final code was then tested by actual walking at 390 x 844 on an unchanged
earned maintenance save. The complete caption wrapped into two readable lines.
Both actors stayed fixed for the capture, followed by the original recovery to
(836,716), with no chase-attempt increment. Reported presentation time was
5206.43 ms and the sampled wall interval was 5317 ms. Ordinary window close
finished with exit 0.

A final ordinary zero-attempt chase reload on the fade-preserving code recorded
two more complete holds: 5220.59 and 5225.03 ms of presentation time, with wall
intervals of 5545 and 5560 ms. Both positions remained fixed and each completed
hold incremented the attempt exactly once. The 23983 ms trace cutoff again fell
inside a third hold. The separately recorded close at 34436 ms had attempt 4
and no active hold; it does not extend continuous timeline coverage. Actual
close-during-caption is not claimed. Active disposal and stale-callback
cancellation are covered by the focused World tests.

The observer takes screenshots and reads live state only. It injects no input,
simulation clock or story state and is excluded from the proposed production
scope. Audio used Dummy; this is not an audibility acceptance result.
No fresh exported package, full aggregate run or physical-phone acceptance was
performed for this isolated candidate. Ordinary autosaves remain labeled copies;
the canonical bakery save and the earned zero-attempt pursuit input are intact.

## Scope

This isolated candidate adds the presentation helper, its focused test and this
document, with a small World integration. Original guard models, navigation,
collision, difficulty, controller rules, source art and authored dialogue are
unchanged. The previous 47-path candidate union stays separately frozen. No Git
scope has been selected, and nothing has been staged, committed or published.
