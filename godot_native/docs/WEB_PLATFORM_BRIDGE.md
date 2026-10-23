# Godot Web platform boundary

The Web export runs the independent `godot_native/` project. `main.gd` creates
`scripts/platform/web_platform.gd` only for `OS.has_feature("web")`; desktop
keeps the existing native file dialog. No React, iframe, second controller or
second save format is involved.

Browser imports use a `.json` file picker (`#godot-save-import`). The selected
UTF-8 text is bounded to 48 MiB, written to a temporary `user://` file, and
passed to the existing `State.import_save()` transaction. Temporary input is
removed on success and rejection. Export uses the existing portable journal
archive via `State.export_save()`, then `JavaScriptBridge.download_buffer()`.
Screenshots download as PNG instead of referring to an inaccessible virtual
filesystem path. A download message describes the request, since browsers can
still refuse a download.

On the same origin, the control center offers **导入原网页存档** only when the
retained browser primary or backup key is present. This explicit action reads
only `seven_fifty_five_state` and `seven_fifty_five_state_backup`; it uses the
same validated importer, tries the backup if the primary is invalid, and never
deletes or rewrites either browser key. Startup does not import automatically.

Godot owns `user://` persistence through IndexedDB. In the upstream 4.6
implementation a writable `FileAccess.close()` marks the filesystem dirty;
the next main-loop iteration requests its asynchronous synchronization. The
existing flush/close/rename save transaction remains the authority. There is
no competing localStorage autosave. The control center explains browser-local
storage and export backups, and reports when `OS.is_userfs_persistent()` is
false. That capability alone is not proof of persistence: acceptance must
actually reload the exported application and verify the resumed progress.

For acceptance, `window.__GODOT_755__.snapshot()` returns a fresh JSON copy of
the latest read-only observation, published every 250 ms after the main story
shell mounts. It reports the actual Godot version, state, rendered control
rectangles, phone and world rectangles, local C1 session state, actual audio
and video player summaries, save digest and developer-tools policy. Its public
object has only `snapshot`; no action, mutation, seed, import, route or
checkpoint API exists. All acceptance actions must use the visible controls,
keyboard, touch, ordinary file picker or explicit legacy-save button. The
temporary JavaScript transport object is removed from the global namespace
after the Godot bridge retains its reference.

World observations also include the actual camera, uniform zoom, local viewport
size and rendered touch-control rectangles. Browser tests project physical
object clicks from those measured values instead of guessing at map positions.
These detached geometry values cannot move the camera, issue an interaction,
or write state or saves. The 2026-10-20 progressive-puzzle checks add four native
assertions for exact geometry and mutation isolation to the historical checks
below.

Audio uses the Web `Stream` project override so procedural streams and mixer
effects retain their native behavior; the HTML start gesture unlocks audio.
Playback state alone is not proof of audible output, and automated desktop
touch emulation is not physical-device acceptance.

Focused native validation on Godot 4.7.2 (2026-10-20):

- `test_web_platform.gd`: 18 checks, including malformed-upload byte-preserving
  rejection, controller-owned native/browser import, actual file reload,
  temporary-file retirement, and detached read-only snapshots.
- `test_native_surface_save.gd`: 40 checks.
- `test_prologue_focus_input.gd`: 37 checks.

These 95 native checks do not replace real Web export, IndexedDB reload,
browser download/upload, WebGL, media or mobile acceptance.

Official references:

- [Godot 4.6 Web export restrictions and persistence](https://docs.godotengine.org/en/4.6/tutorials/export/exporting_for_web.html)
- [JavaScriptBridge downloads and callback lifetime](https://docs.godotengine.org/en/4.6/classes/class_javascriptbridge.html)
- [Godot 4.6 filesystem synchronization implementation](https://github.com/godotengine/godot/blob/4.6-stable/platform/web/os_web.cpp)
- [Callback return handling in the Godot JavaScript bridge](https://github.com/godotengine/godot/blob/4.6-stable/platform/web/javascript_bridge_singleton.cpp)
