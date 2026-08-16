import * as THREE from "three";

export type ThreeFlatMaterial = THREE.MeshLambertMaterial | THREE.MeshBasicMaterial;

interface FlatMaterialOptions {
  unlit?: boolean;
  opacity?: number;
  depthWrite?: boolean;
}

function cacheKey(values: readonly (number | boolean)[]): string {
  return values.join(":");
}

/**
 * Page-lifetime cache for immutable low-poly primitives.
 *
 * Three.js otherwise allocates one GPU geometry and one material for every
 * visually identical pixel block. The cache deliberately keeps only finite,
 * parameter-keyed resources so scene remounts can reuse them without growing
 * the resource set.
 */
export class ThreePrimitiveCache {
  private readonly geometries = new Map<string, THREE.BufferGeometry>();
  private readonly materials = new Map<string, ThreeFlatMaterial>();
  private readonly ownedGeometries = new Set<THREE.BufferGeometry>();
  private readonly ownedMaterials = new Set<THREE.Material>();

  material(color: number, options: FlatMaterialOptions = {}): ThreeFlatMaterial {
    const unlit = options.unlit ?? false;
    const opacity = options.opacity ?? 1;
    const depthWrite = options.depthWrite ?? true;
    const key = cacheKey([color, unlit, opacity, depthWrite]);
    const cached = this.materials.get(key);
    if (cached) return cached;
    const material = unlit
      ? new THREE.MeshBasicMaterial({ color, transparent: opacity < 1, opacity, depthWrite })
      : new THREE.MeshLambertMaterial({ color, flatShading: true, transparent: opacity < 1, opacity, depthWrite });
    this.materials.set(key, material);
    this.ownedMaterials.add(material);
    return material;
  }

  box(width: number, height: number, depth: number): THREE.BoxGeometry {
    return this.geometry(`box:${cacheKey([width, height, depth])}`, () => new THREE.BoxGeometry(width, height, depth));
  }

  plane(width: number, height: number): THREE.PlaneGeometry {
    return this.geometry(`plane:${cacheKey([width, height])}`, () => new THREE.PlaneGeometry(width, height));
  }

  torus(radius: number, tube: number, radialSegments: number, tubularSegments: number): THREE.TorusGeometry {
    return this.geometry(
      `torus:${cacheKey([radius, tube, radialSegments, tubularSegments])}`,
      () => new THREE.TorusGeometry(radius, tube, radialSegments, tubularSegments)
    );
  }

  cylinder(
    radiusTop: number,
    radiusBottom: number,
    height: number,
    radialSegments: number,
    heightSegments = 1,
    openEnded = false
  ): THREE.CylinderGeometry {
    return this.geometry(
      `cylinder:${cacheKey([radiusTop, radiusBottom, height, radialSegments, heightSegments, openEnded])}`,
      () => new THREE.CylinderGeometry(radiusTop, radiusBottom, height, radialSegments, heightSegments, openEnded)
    );
  }

  cone(radius: number, height: number, radialSegments: number): THREE.ConeGeometry {
    return this.geometry(
      `cone:${cacheKey([radius, height, radialSegments])}`,
      () => new THREE.ConeGeometry(radius, height, radialSegments)
    );
  }

  icosahedron(radius: number, detail: number): THREE.IcosahedronGeometry {
    return this.geometry(
      `icosahedron:${cacheKey([radius, detail])}`,
      () => new THREE.IcosahedronGeometry(radius, detail)
    );
  }

  ownsGeometry(geometry: THREE.BufferGeometry): boolean {
    return this.ownedGeometries.has(geometry);
  }

  ownsMaterial(material: THREE.Material): boolean {
    return this.ownedMaterials.has(material);
  }

  get geometryCount(): number {
    return this.ownedGeometries.size;
  }

  get materialCount(): number {
    return this.ownedMaterials.size;
  }

  private geometry<T extends THREE.BufferGeometry>(key: string, create: () => T): T {
    const cached = this.geometries.get(key);
    if (cached) return cached as T;
    const geometry = create();
    this.geometries.set(key, geometry);
    this.ownedGeometries.add(geometry);
    return geometry;
  }
}
