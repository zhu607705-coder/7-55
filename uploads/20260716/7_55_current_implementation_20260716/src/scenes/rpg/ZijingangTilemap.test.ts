import { describe, expect, it } from "vitest";
import campusMap from "../../data/maps/zijingang-campus.json";

interface MapObject {
  name: string;
  x?: number;
  y?: number;
  width?: number;
  height?: number;
  rotation?: number;
  polygon?: Array<{ x: number; y: number }>;
  polyline?: Array<{ x: number; y: number }>;
  properties?: Array<{ name: string; value: unknown }>;
}

interface MapLayer {
  name: string;
  type: string;
  data?: number[];
  objects?: MapObject[];
}

const layers = campusMap.layers as unknown as MapLayer[];
const layer = (name: string) => layers.find((candidate) => candidate.name === name);
const property = (object: MapObject, name: string) => object.properties?.find((candidate) => candidate.name === name)?.value;
const placementRectangle = (object: MapObject) => {
  const width = Number(property(object, "placementWidth"));
  const height = Number(property(object, "placementHeight"));
  const centerX = (object.x ?? 0) + Number(property(object, "placementOffsetX") ?? 0);
  const bottom = (object.y ?? 0) + Number(property(object, "placementBottomOffsetY") ?? 0);
  return { left: centerX - width / 2, right: centerX + width / 2, top: bottom - height, bottom };
};
const rectanglesOverlap = (
  first: ReturnType<typeof placementRectangle>,
  second: ReturnType<typeof placementRectangle>,
  clearance = 0
) => first.left < second.right + clearance
  && first.right > second.left - clearance
  && first.top < second.bottom + clearance
  && first.bottom > second.top - clearance;

const scaleClassRules = {
  landmark: { min: 320, max: 490 },
  campus_block: { min: 230, max: 270 },
  service_building: { min: 155, max: 190 },
  athletics_site: { min: 390, max: 430 },
  utility_structure: { min: 90, max: 150 }
} as const;

describe("Zijingang Tiled map", () => {
  it("uses editable tile and object layers without a full-map image layer", () => {
    expect(layers.some((candidate) => candidate.type === "imagelayer")).toBe(false);
    expect(layer("Ground")?.type).toBe("tilelayer");
    expect(layer("Water")?.type).toBe("tilelayer");
    expect(layer("Landmarks")?.type).toBe("objectgroup");
    expect(layer("Environment")?.type).toBe("objectgroup");
    expect(layer("StructureFootprints")?.type).toBe("objectgroup");
    expect(layer("StructureCollisions")?.type).toBe("objectgroup");
  });

  it("keeps the legacy road tile layer empty and owns roads as Tiled polylines", () => {
    expect(layer("Roads")?.data?.every((gid) => gid === 0)).toBe(true);
    const roads = layer("RoadPaths")?.objects ?? [];
    expect(roads.length).toBeGreaterThanOrEqual(20);
    expect(roads.map((road) => road.name)).toEqual(expect.arrayContaining([
      "north_perimeter",
      "south_perimeter",
      "west_north_link",
      "east_north_link",
      "qizhen_west_bank",
      "qizhen_east_bank",
      "middle_bridge_link"
    ]));
    const kinds = roads.flatMap((road) => road.properties ?? [])
      .filter((property) => property.name === "kind")
      .map((property) => property.value);
    expect(kinds).toContain("road");
    expect(kinds).toContain("path");
  });

  it("keeps the east north road continuous through the stadium access", () => {
    const roads = layer("RoadPaths")?.objects ?? [];
    const eastRoad = roads.find((road) => road.name === "east_north_link");
    const stadiumAccess = roads.find((road) => road.name === "stadium_walk");
    const absolutePoints = (object: MapObject) => (object.polyline ?? []).map((point) => ({
      x: (object.x ?? 0) + point.x,
      y: (object.y ?? 0) + point.y
    }));

    expect(eastRoad).toBeDefined();
    expect(absolutePoints(eastRoad as MapObject)).toEqual([
      { x: 1350, y: 500 },
      { x: 2380, y: 500 }
    ]);
    expect(absolutePoints(stadiumAccess as MapObject)[0]).toEqual({ x: 2050, y: 500 });
    expect(roads.some((road) => road.name === "east_north_link_a" || road.name === "east_north_link_b")).toBe(false);
  });

  it("keeps landmarks and high-detail environment objects independently addressable", () => {
    expect(layer("Landmarks")?.objects).toHaveLength(7);
    expect((layer("Environment")?.objects?.length ?? 0)).toBeGreaterThanOrEqual(22);
    expect(layer("Environment")?.objects?.map((object) => object.name)).toEqual(expect.arrayContaining([
      "great_lawn",
      "lake_heart_island",
      "nanhuayuan",
      "qizhen_bridge"
    ]));
  });

  it("builds coherent campus greenery from avenue, grove, and lake-bank groups", () => {
    const environment = layer("Environment")?.objects ?? [];
    const count = (name: string) => environment.filter((object) => object.name === name).length;
    const vegetationNames = new Set(["avenue_tree_row", "tree_grove", "willow_bank"]);
    const vegetation = environment.filter((object) => vegetationNames.has(object.name));
    const worldCenter = {
      x: campusMap.width * campusMap.tilewidth / 2,
      y: campusMap.height * campusMap.tileheight / 2
    };
    const quadrantCounts = [
      vegetation.filter((object) => (object.x ?? 0) < worldCenter.x && (object.y ?? 0) < worldCenter.y).length,
      vegetation.filter((object) => (object.x ?? 0) >= worldCenter.x && (object.y ?? 0) < worldCenter.y).length,
      vegetation.filter((object) => (object.x ?? 0) < worldCenter.x && (object.y ?? 0) >= worldCenter.y).length,
      vegetation.filter((object) => (object.x ?? 0) >= worldCenter.x && (object.y ?? 0) >= worldCenter.y).length
    ];

    expect(count("avenue_tree_row")).toBeGreaterThanOrEqual(9);
    expect(count("tree_grove")).toBeGreaterThanOrEqual(8);
    expect(count("willow_bank")).toBeGreaterThanOrEqual(6);
    quadrantCounts.forEach((quadrantCount) => expect(quadrantCount).toBeGreaterThanOrEqual(5));
  });

  it("uses visible world width as the canonical scale for every structure", () => {
    const structures = [...(layer("Landmarks")?.objects ?? []), ...(layer("Environment")?.objects ?? [])]
      .filter((object) => property(object, "scaleClass"));

    expect(structures.length).toBeGreaterThanOrEqual(15);
    structures.forEach((structure) => {
      const scaleClass = property(structure, "scaleClass") as keyof typeof scaleClassRules;
      const visualWidth = Number(property(structure, "visualWidth"));
      const placementWidth = Number(property(structure, "placementWidth"));
      const projection = property(structure, "projection");
      expect(Number(property(structure, "displayWidth"))).toBeGreaterThan(0);
      expect(placementWidth).toBeGreaterThan(0);
      if (projection === "front") {
        expect(placementWidth).toBeCloseTo(visualWidth, 4);
      }
      expect(Number(property(structure, "placementHeight"))).toBeGreaterThan(0);
      expect(visualWidth).toBeGreaterThanOrEqual(scaleClassRules[scaleClass].min);
      expect(visualWidth).toBeLessThanOrEqual(scaleClassRules[scaleClass].max);
      if (scaleClass !== "athletics_site" && scaleClass !== "landmark") {
        expect(Number(property(structure, "collisionWidth"))).toBeGreaterThan(0);
        expect(Number(property(structure, "collisionHeight"))).toBeGreaterThan(0);
      }
    });
  });

  it("keeps every repeated environment model on one visual and collision scale", () => {
    const structures = (layer("Environment")?.objects ?? []).filter((object) => property(object, "scaleClass"));
    const modelScales = new Map<string, string>();

    structures.forEach((structure) => {
      const signature = [
        property(structure, "visualWidth"),
        property(structure, "displayWidth"),
        property(structure, "placementHeight"),
        property(structure, "projection"),
        property(structure, "collisionWidth"),
        property(structure, "collisionHeight")
      ].join(":");
      const previous = modelScales.get(structure.name);
      if (previous) expect(signature).toBe(previous);
      modelScales.set(structure.name, signature);
    });

    expect((layer("Environment")?.objects ?? []).filter((object) => object.name.startsWith("service_block")).length)
      .toBeGreaterThanOrEqual(2);
  });

  it("stores the foundation library as an editable L-shaped footprint with matching collision decomposition", () => {
    const footprint = (layer("StructureFootprints")?.objects ?? [])
      .find((object) => property(object, "owner") === "foundation_library");
    const collisions = (layer("StructureCollisions")?.objects ?? [])
      .filter((object) => property(object, "owner") === "foundation_library");
    const foundation = (layer("Landmarks")?.objects ?? [])
      .find((object) => object.name === "foundation_library");

    expect(property(foundation as MapObject, "placementShape")).toBe("polygon");
    expect(footprint?.polygon).toHaveLength(12);
    expect(collisions).toHaveLength(4);
    expect(collisions.every((collision) => (collision.width ?? 0) > 0 && (collision.height ?? 0) > 0)).toBe(true);
  });

  it("keeps the South Gate as a front-facing horizontal facade beside the south road", () => {
    const southGate = (layer("Landmarks")?.objects ?? []).find((object) => object.name === "south_gate") as MapObject;
    const southRoad = (layer("RoadPaths")?.objects ?? []).find((object) => object.name === "south_perimeter") as MapObject;
    const visualWidth = Number(property(southGate, "visualWidth"));
    const renderHeight = visualWidth * Number(property(southGate, "renderAspect"));
    const gateBaseline = (southGate.y ?? 0) + Number(property(southGate, "placementBottomOffsetY"));

    expect(southGate.rotation ?? 0).toBe(0);
    expect(visualWidth / renderHeight).toBeGreaterThan(6);
    expect(renderHeight).toBeLessThan(80);
    expect(southRoad.y).toBeGreaterThan(gateBaseline);
    expect((southRoad.y ?? 0) - gateBaseline).toBeGreaterThanOrEqual(50);
  });

  it("uses cardinal orthographic elevations for every named landmark", () => {
    const landmarks = layer("Landmarks")?.objects ?? [];

    expect(landmarks).toHaveLength(7);
    landmarks.forEach((landmark) => {
      const renderAspect = Number(property(landmark, "renderAspect"));
      expect(["front", "side"], landmark.name).toContain(property(landmark, "projection"));
      expect(landmark.rotation ?? 0, landmark.name).toBe(0);
      expect(renderAspect, landmark.name).toBeGreaterThan(0.1);
      expect(renderAspect, landmark.name).toBeLessThan(0.8);
    });
  });

  it("mixes front and side elevations without any 45-degree building projection", () => {
    const environment = layer("Environment")?.objects ?? [];
    const buildingObjects = environment.filter((object) => ["front", "side"].includes(String(property(object, "projection"))));
    const projections = buildingObjects.map((object) => property(object, "projection"));

    expect(projections).toContain("front");
    expect(projections.filter((projection) => projection === "side").length).toBeGreaterThanOrEqual(4);
    expect(buildingObjects.map((object) => object.name)).toEqual(expect.arrayContaining([
      "dorm_cluster_side",
      "teaching_courtyard_side",
      "service_block_side",
      "greenhouse_garden_side"
    ]));
    buildingObjects.forEach((instance) => {
      expect(["front", "side"], instance.name).toContain(property(instance, "projection"));
      expect(instance.rotation ?? 0, instance.name).toBe(0);
    });

    const sportsField = environment.find((object) => object.name === "sports_courts") as MapObject;
    expect(property(sportsField, "projection")).toBe("top");
  });

  it("keeps every structural placement on land and clear of other structures", () => {
    const structures = [...(layer("Landmarks")?.objects ?? []), ...(layer("Environment")?.objects ?? [])]
      .filter((object) => property(object, "scaleClass"));
    const water = layer("Water")?.data ?? [];

    structures.forEach((structure) => {
      const placement = placementRectangle(structure);
      for (let y = 0; y < campusMap.height; y += 1) {
        for (let x = 0; x < campusMap.width; x += 1) {
          if (!water[y * campusMap.width + x]) continue;
          const waterCell = {
            left: x * campusMap.tilewidth,
            right: (x + 1) * campusMap.tilewidth,
            top: y * campusMap.tileheight,
            bottom: (y + 1) * campusMap.tileheight
          };
          expect(rectanglesOverlap(placement, waterCell)).toBe(false);
        }
      }
    });

    for (let first = 0; first < structures.length; first += 1) {
      for (let second = first + 1; second < structures.length; second += 1) {
        expect(rectanglesOverlap(
          placementRectangle(structures[first]),
          placementRectangle(structures[second]),
          4
        )).toBe(false);
      }
    }
  });

  it("models each bridge as one continuous deck over continuous water with a matching collision corridor", () => {
    const bridges = (layer("Environment")?.objects ?? []).filter((object) => object.name === "qizhen_bridge");
    const water = layer("Water")?.data ?? [];
    const collisions = layer("WaterCollisions")?.objects ?? [];

    expect(bridges).toHaveLength(4);
    bridges.forEach((bridge) => {
      const spanStartX = Number(property(bridge, "spanStartX"));
      const spanEndX = Number(property(bridge, "spanEndX"));
      expect(property(bridge, "displayWidth")).toBe(spanEndX - spanStartX);

      const midpointX = bridge.x ?? 0;
      const midpointY = bridge.y ?? 0;
      const tileX = Math.floor(midpointX / campusMap.tilewidth);
      const tileY = Math.floor(midpointY / campusMap.tileheight);
      expect(water[tileY * campusMap.width + tileX]).toBeGreaterThan(0);

      const collisionAtMidpoint = collisions.some((collision) => {
        const left = collision.x ?? 0;
        const top = collision.y ?? 0;
        return midpointX >= left
          && midpointX < left + (collision.width ?? 0)
          && midpointY >= top
          && midpointY < top + (collision.height ?? 0);
      });
      expect(collisionAtMidpoint).toBe(false);
    });
  });

  it("requires every vehicle-road crossing over water to have a bridge deck", () => {
    const roads = (layer("RoadPaths")?.objects ?? []).filter((object) => property(object, "kind") === "road");
    const bridges = (layer("Environment")?.objects ?? []).filter((object) => object.name === "qizhen_bridge");
    const water = layer("Water")?.data ?? [];

    roads.forEach((road) => {
      const points = road.polyline ?? [];
      for (let pointIndex = 1; pointIndex < points.length; pointIndex += 1) {
        const start = {
          x: (road.x ?? 0) + points[pointIndex - 1].x,
          y: (road.y ?? 0) + points[pointIndex - 1].y
        };
        const end = {
          x: (road.x ?? 0) + points[pointIndex].x,
          y: (road.y ?? 0) + points[pointIndex].y
        };
        const length = Math.hypot(end.x - start.x, end.y - start.y);

        for (let distance = 0; distance <= length; distance += 8) {
          const ratio = length === 0 ? 0 : distance / length;
          const x = start.x + (end.x - start.x) * ratio;
          const y = start.y + (end.y - start.y) * ratio;
          const tileX = Math.floor(x / campusMap.tilewidth);
          const tileY = Math.floor(y / campusMap.tileheight);
          const crossesWater = water[tileY * campusMap.width + tileX] > 0;
          if (!crossesWater) continue;

          const hasBridge = bridges.some((bridge) => (
            x >= Number(property(bridge, "spanStartX"))
            && x <= Number(property(bridge, "spanEndX"))
            && Math.abs(y - (bridge.y ?? 0)) <= Number(property(bridge, "corridorHalfWidth"))
          ));
          expect(hasBridge, `${road.name} crosses water without a bridge at ${Math.round(x)},${Math.round(y)}`).toBe(true);
        }
      }
    });
  });

  it("keeps visible environment structure footprints clear of vehicle roads", () => {
    const roads = (layer("RoadPaths")?.objects ?? []).filter((object) => property(object, "kind") === "road");
    const buildings = (layer("Environment")?.objects ?? []).filter((object) => property(object, "scaleClass"));

    buildings.forEach((building) => {
      const visibleFootprint = placementRectangle(building);

      roads.forEach((road) => {
        const points = (road as MapObject & { polyline?: Array<{ x: number; y: number }> }).polyline ?? [];
        for (let index = 1; index < points.length; index += 1) {
          const startX = (road.x ?? 0) + points[index - 1].x;
          const startY = (road.y ?? 0) + points[index - 1].y;
          const endX = (road.x ?? 0) + points[index].x;
          const endY = (road.y ?? 0) + points[index].y;
          const roadFootprint = {
            left: Math.min(startX, endX) - 17,
            right: Math.max(startX, endX) + 17,
            top: Math.min(startY, endY) - 17,
            bottom: Math.max(startY, endY) + 17
          };
          expect(rectanglesOverlap(visibleFootprint, roadFootprint, 4)).toBe(false);
        }
      });
    });
  });

  it("keeps the athletics field at a campus-scale footprint", () => {
    const sportsField = (layer("Environment")?.objects ?? []).find((object) => object.name === "sports_courts");
    expect(Number(property(sportsField as MapObject, "visualWidth"))).toBeGreaterThanOrEqual(390);
    expect(Number(property(sportsField as MapObject, "visualWidth"))).toBeLessThanOrEqual(430);
    expect(Number(property(sportsField as MapObject, "placementHeight")))
      .toBeCloseTo(Number(property(sportsField as MapObject, "placementWidth")) * 271 / 362, 4);
    expect(sportsField?.x).toBeLessThanOrEqual(2040);
    expect(sportsField?.y).toBeGreaterThanOrEqual(850);
  });

  it("keeps the southeast greenhouse readable at the default camera scale", () => {
    const greenhouse = (layer("Environment")?.objects ?? []).find((object) => object.name === "greenhouse_garden_side");
    expect(Number(property(greenhouse as MapObject, "visualWidth"))).toBeGreaterThanOrEqual(120);
  });
});
