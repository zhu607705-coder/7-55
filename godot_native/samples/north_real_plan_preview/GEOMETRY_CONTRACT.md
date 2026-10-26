# North plan / geometry / object boundary v1

These interfaces reserve stable identities for later reconstruction. They do **not**
certify any geometry. This viewer always returns `navigation_available() == false`.
A later playable adapter needs its own reviewed implementation and tests; changing
a JSON flag cannot activate player movement, story progression, or transport.

## Identity and evidence

| Field | Contract |
| --- | --- |
| `building.id` | `north1` … `north4`; never derived from story `A1/A2/A3` |
| `floor.id` | `northN:fM`, stable across art revisions |
| `sourceId` | Key in `sources`; links to official historical notice and archive |
| `sourceMember` | Exact original archive member, or `null` when not recovered |
| `documentedFloorNumbers` | Available historical sheets, **not** current total occupied floors |
| `currentTotalFloorCount` | `null` until separately verified; a WFS height/count field is insufficient |
| `art` | Optional candidate resource, SHA-256, dimensions and registration status |
| `geometry` | Independently reviewed data, never produced from generated art or label boxes |

The official archive URLs are references, not a permission to redistribute their
binaries. No university PDFs, PNGs or RARs are bundled. The four original project
art plates are included byte-for-byte, not as copies of the plan drawings.

## Future geometry payload

The current 18 entries use `status: "not_extracted"`, `coordinateSpace: null`, and
empty arrays. Future records must keep these field meanings:

```text
coordinateSpace: {
  id, sourceId, sourceMember, page,
  units: "source_px" | "metres",
  origin, xAxis, yAxis,
  calibrationEvidenceIds,
  artTransform: null | { uniformScale, rotationRadians, translation, evidenceIds }
}
walkablePolygons: [{ id, outer: [[x,y],...], holes: [[[x,y],...],...], evidenceIds }]
solidPolygons:    [{ id, outer: [[x,y],...], holes: [[[x,y],...],...], evidenceIds }]
rooms: [{ id: "northN:fM:room:<source label>", sourceLabel, polygonId, evidenceIds }]
portals: [{ id, kind: "door" | "stair" | "elevator", polygonId,
            arrivalPoint: [x,y], targetFloorId, targetPortalId, evidenceIds }]
evidence: [{ id, sourceId, sourceMember, page, observation, verifiedBy, verifiedAt }]
```

Rules before a future adapter may accept the payload:

1. Resolve every reference and prove the source coordinate system. Art pixels are
   not survey units. No nonuniform stretch or inferred compass rotation.
2. Validate polygon winding, nonzero area, no self-intersection, bounded coordinates,
   holes and wall clearance with the actual player footprint. A text-label bounding
   box is only a transcription anchor, never a room or collision polygon.
3. Distinguish open courts, roof terraces, inaccessible roofs and partial upper
   wings. Never copy one footprint up the building or mirror another building.
4. Every portal names a reciprocal compatible endpoint and a safe arrival point.
   A stair icon does not by itself prove a cross-floor connection.
5. Review room IDs against the original sheet, including service and shared spaces.
   Prove reachability and collision contact in the actual runtime at each floor.
6. Explicitly map any story location to a verified space without changing existing
   controllers, time states, evidence gates or saves implicitly. Six time states are
   not six physical storeys.

## Independent object layers

Each floor reserves `objectLayer: { status: "unplaced", instances: [] }`. It is
separate from both the clean architecture plate and collision data.

```text
object asset: { id, libraryFileId, libraryVersion, sha256, texture,
                nativeSize: [w,h], pivot: [x,y], contactBaseline,
                provenance, license, artStatus: "designed_candidate" }
instance: { id, assetId, floorId, position, uniformScale, flipX,
            placementEvidenceIds, collisionId: null | verifiedSolidPolygonId }
```

Preserve the approved original identity, transparent PNG bytes, pixel pivot and
uniform scale. Do not repaint or bake props into the building plate. A visually
plausible desk/door/elevator is not evidence of a real furnishing or exact doorway.
Unverified objects must remain explicitly designed candidates and cannot create
collision or transport by themselves. No instances are placed in this increment.
