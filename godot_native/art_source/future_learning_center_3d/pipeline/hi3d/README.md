# Hi3D MCP connection and furniture pass ·2026-11-02

Configured in the host Codex client as `hi3d`, Streamable HTTP,
`https://agent.hi3d.cn/mcp`, with OAuth. Authentication succeeded in the user's
browser. Other pre-existing client settings were compared with a private backup
and preserved. No credential, raw auth configuration or presigned URL belongs in
this directory.

`connection_20261102.json` records the actual eleven-tool discovery. Native calls
to `get_capabilities`, `get_balance`, `upload_input` and `quote_generation` succeeded.
This verifies more than merely writing a config entry. The existing chat did not
hot-add a `hi3d` tool namespace; a fresh native Codex MCP connection works without
restarting the app. Restart/reopen the client session if its tool picker needs to
reload the catalog. Saved OAuth does not require reauthorization for that reload.

The configured client supports OAuth as documented in the
[official Codex MCP guide](https://learn.chatgpt.com/docs/extend/mcp?surface=cli).
The verified CLI version is `0.166.0-alpha.5.1`.

## Native client route

`client.py` calls the configured service through Codex's own MCP/OAuth client in
an ephemeral protocol context. It never starts a model turn or delegates to an
agent, and does not export bearer credentials. Other MCP servers are disabled
only inside that temporary context. Its input/output files should stay in a
private scratch directory, with permission0600; upload tokens last24hours.

```sh
python3 pipeline/hi3d/client.py get_capabilities --output /private/tmp/hi3d-capabilities.json
```

The actual service supports image-to-3D, fixed GLB output, up to four reference
uploads, private or CC-BY-4.0 selection, and PBR options. Version3.0's `high_quality`
input maps to its `standard` tier. The master tier is not selected. Its2D tool
offers Seedream v4.5 in the China environment and does not offer2D multiview
generation. This pass keeps the established built-in imagegen reference route.

## Reviewable asset batch

The complete references and exact prompts are in
`sources/concepts/20261102_exhibition_rest/`:

- One mobile exhibition table turnaround and three deterministic view-panel crops.
- Approximate silver-covered installation reference.
- Approximate open thread-cube exhibit reference.
- Compact two-seat sofa reference.
- Pantry/rest interior direction based on requirements and the existing layout.

Concept images are not survey or inventory authority. In particular, a generated
room image can vary stool counts; the model remains six high stools, two two-seat
conversation groups, and one compact sofa. No room bounds or door openings were
redesigned from the concept. Original user-photo paths were unavailable, so no
new source-photo hashes or exact student-work reconstruction are claimed.

Three exact quotes were obtained, one per complete asset input set:
mobile exhibition table45points, silver exhibit45points, sofa45points. All use
v3.0 high_quality/standard, model_with_texture, PBR enabled and private visibility.
The table's three views are quoted together as one object. The quote records
include expiration times; no paid task has been submitted.

The tool contract requires explicit confirmation of the current estimate before
`create_generation(confirmed=true)`. The user was offered a45point table pilot or
the135point three-asset batch. Pending amount confirmation is not permission.
Refresh an expired quote only when ready to submit; do not keep requoting the
same unchanged parameters while waiting. Ask again if price or scope changes.
Submissions are never automatically retried after a timeout or uncertain state.

## Work completed independently of paid generation

The authored viewer now includes caster forks, axle caps and brake tabs on the
exhibition tables, denser ruled thread fans, pantry cabinet doors and pulls,
stool bases/footrests, individual vending drink silhouettes, real leaf geometry
and separate refrigerator door panels. Its far-right refrigerator remains at
the same world position. The sofa was moved to eliminate overlap with a
conversation chair; both the side passage and rear service gap remain at least0.7m.
The entry position is unchanged, while the initial look direction shows more of
the room. These are authored changes, not falsely attributed to Hi3D output.

Rebuild only the affected furniture and web assembly:

```sh
/Applications/Blender.app/Contents/MacOS/Blender --background --factory-startup --python scripts/refine_exhibition_pantry.py
node pipeline/split_building.mjs
node scripts/test_exhibition_pantry.mjs
```

The existing dynamic desk parts retain their local articulation. New provider
outputs still require original-file preservation, metric/axis calibration,
material-map inspection, local LOD/Draco processing and real viewer acceptance
before replacing the corresponding furniture. This pass is the independent3D
authoring viewer; it does not constitute a native Godot release.
