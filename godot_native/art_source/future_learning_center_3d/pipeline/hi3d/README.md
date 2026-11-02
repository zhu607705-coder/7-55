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

Three successful tasks used the explicitly approved135point batch:

| Asset | Task | Actual points |
|---|---|---|
| Mobile exhibition table | d0d4c88ae6c444f8bdc3ff66e144560a |45|
| Silver-covered exhibit | dcdd1e8a91ed4571aa4e3c706d5d1abd |45|
| Two-seat sofa | ed018de298f64816945e46b92a6b295b |45|

`batch_20261102.json` is the current ledger. The older pending-quote file is
historical and explicitly superseded. One rejected silver submission created
no task and deducted no points, verified by task listing and balance. Only after
reconciliation and first-task completion was a new45point quote submitted once.
There are no uncertain or automatically repeated paid jobs. Latest reported
balance is25points; task receipts own the135point cost rather than subtracting
a historical balance snapshot. Permanent model-page URLs are in each receipt.

`download_outputs.py` preserves both provider GLBs, native previews, hashes and
provenance. Its private input contains signed download URLs and stays outside
the source tree. No credentials or signed URLs belong in this package.

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

## Local geometry, materials and runtime acceptance

Table: keep the original caster/frame geometry; `pipeline/refine_table.py`
replaces its wavy board with a flat rounded manufactured top and adjusts satin
steel. Four widths translate end assemblies without changing caster size.
Sofa: `pipeline/refine_sofa.py` edits seat span to fit the reserved footprint,
keeps exterior bands rigid, preserves the color map, authors matte dielectric
upholstery and smooth vertex normals. Raw imports had no NORMAL attribute;
exporting them with flat DCC shading caused false surface seams and was rejected.
Silver exhibit: uniform placement scale fits its generated silhouette on the
existing table, without stretching the room or the model.

Blender's `pipeline/decimate_static.py` bakes true polygon LODs for the edited
meshes; ordinary simplification can stall at split normals/UV seams.
`pipeline/build_asset.mjs` accepts INPUT OUTPUT HEIGHT YAW MAX_TEXTURE_PX
followed by optional MID_SOURCE FAR_SOURCE. All levels share the same metric
calibration. It resizes maps to1024/512/256, emits plain and Draco GLBs, independently
decodes them, and checks topology and envelope errors below1mm.

All original Hi3D models have base-color and metallic/roughness textures; they
have no normal or AO texture. The sofa's unreliable metallic response is
intentionally replaced locally. Original files are never overwritten.

`web/assets/generated_furniture_catalog.json` binds six placements to the three
paid sources plus local variants. One shared local Draco decoder serves the
chair and these static assets. Highest detail is forced on ordinary object
inspection; distance controls LOD elsewhere. Failed optional assets keep
authored fallback geometry. Neutral local environment reflections support foil
and satin metal without remote HDR downloads.

Run `node scripts/test_hi3d_assets.mjs` for fee/source receipts, actual reductions,
map budgets, geometry envelopes, six placements, pointer inspection, rotation,
return, mobile sizing and injected per-asset/catalog failure. Also run the
existing collision, browser, floor, furniture, north-density, chair-asset and
exhibition/pantry regressions. This acceptance is local Chrome desktop/mobile
emulation; physical mobile and native Godot integration are separate work.

Rebuild all local derivatives without paid calls: `python3 pipeline/rebuild_hi3d.py`.
Preserved normalized inputs are tracked and hashed in the edit receipts.
