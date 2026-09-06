import * as THREE from "three";
import { ThreePrimitiveCache } from "../ThreePrimitiveCache";
import { CHASE_GOAL_METERS, CHASE_WORLD_PER_METER, chaseStageAt } from "./ChaseRoute";
import { createChaseBicycleRig, DEFAULT_CHASE_RIDER_RIG_PALETTE } from "./ChaseRiderRig";

const C = {
  asphalt: 0x657073, asphaltDetail: 0x727b7b, marking: 0xecece0,
  stone: 0xd6d6c8, joints: 0xb9bfb6, pavement: 0xe0d9c8, tactile: 0xd3bd83,
  lawn: 0x788b6d, leaf: 0x3b6045, leafLight: 0x59794e, leafDark: 0x2c4c3b,
  trunk: 0x776654, bark: 0x948270, metal: 0x455c60, timber: 0xa88760,
  brick: 0xa99f8c, brickLight: 0xbfb6a4, cream: 0xe2dfd3,
  glass: 0x6a8587, glassLight: 0x95a9a5, frame: 0xd5d9d0,
  concrete: 0xb4bdb6, orange: 0xd99248, dark: 0x344b50
} as const;

/** Authored roadside models, independent of the campus navigation map. */
class CampusEnvironmentBuilder {
  readonly root = new THREE.Group();
  private readonly grain: THREE.CanvasTexture;
  constructor(private readonly cache: ThreePrimitiveCache) {
    this.root.name = "canteen-chase-four-stage-campus";
    const canvas = document.createElement("canvas");
    canvas.width = canvas.height = 128;
    const context = canvas.getContext("2d");
    if (context) {
      const pixels = context.createImageData(128, 128);
      let seed = 755;
      for (let i = 0; i < pixels.data.length; i += 4) {
        seed = Math.imul(seed, 1664525) + 1013904223 | 0;
        const value = 207 + ((seed >>> 24) % 49);
        pixels.data[i] = pixels.data[i + 1] = pixels.data[i + 2] = value;
        pixels.data[i + 3] = 255;
      }
      context.putImageData(pixels, 0, 0);
    }
    this.grain = new THREE.CanvasTexture(canvas);
    this.grain.wrapS = this.grain.wrapT = THREE.RepeatWrapping;
    this.grain.anisotropy = 4;
  }

  mesh(geometry: THREE.BufferGeometry, color: number, x = 0, y = 0, z = 0, metal = false): THREE.Mesh {
    const mesh = new THREE.Mesh(geometry, this.cache.material(color, {
      shading: "standard", roughness: metal ? 0.46 : 0.88,
      metalness: metal ? 0.35 : 0, flatShading: false
    }));
    mesh.position.set(x, y, z);
    mesh.userData.chaseStatic = true;
    return mesh;
  }

  box(w: number, h: number, d: number, color: number, x = 0, y = 0, z = 0): THREE.Mesh {
    const grainColors: readonly number[] = [C.asphalt, C.lawn, C.pavement, C.cream, C.brick];
    const grainSurface = grainColors.includes(color);
    const geometry = grainSurface ? this.cache.box(w, h, d).clone() : this.cache.box(w, h, d);
    if (grainSurface) {
      const positions = geometry.getAttribute("position"), normals = geometry.getAttribute("normal");
      const uv = geometry.getAttribute("uv");
      for (let i = 0; i < uv.count; i += 1) {
        const top = Math.abs(normals.getY(i)) > 0.9;
        const side = Math.abs(normals.getX(i)) > 0.9;
        uv.setXY(i, (side ? positions.getZ(i) + z : positions.getX(i) + x) * 1.7,
          (top ? positions.getZ(i) + z : positions.getY(i) + y) * 1.7);
      }
    }
    const result = this.mesh(geometry, color, x, y, z);
    if (grainSurface) {
      const material = result.material as THREE.MeshStandardMaterial;
      material.map = this.grain;
      material.needsUpdate = true;
    }
    return result;
  }

  sphere(x: number, y: number, z: number, sx: number, sy: number, sz: number, color: number): THREE.Mesh {
    const mesh = this.mesh(this.cache.sphere(1, 12, 8), color, x, y, z);
    mesh.scale.set(sx, sy, sz);
    return mesh;
  }

  foliage(seed: number, color: number): THREE.Mesh {
    const positions: number[] = [];
    const a = new THREE.Vector3(), b = new THREE.Vector3(), center = new THREE.Vector3();
    let randomSeed = seed + 755;
    const random = () => {
      randomSeed = Math.imul(randomSeed, 1664525) + 1013904223 | 0;
      return (randomSeed >>> 0) / 4294967296;
    };
    for (let leaf = 0; leaf < 52; leaf += 1) {
      const azimuth = random() * Math.PI * 2, vertical = random() * 2 - 1;
      const radial = Math.cbrt(random()), equator = Math.sqrt(1 - vertical * vertical);
      center.set(Math.cos(azimuth) * equator * radial, vertical * radial * 0.8, Math.sin(azimuth) * equator * radial);
      const angle = random() * Math.PI * 2, length = 0.3 + random() * 0.18;
      a.set(Math.cos(angle) * length, (random() - 0.5) * 0.23, Math.sin(angle) * length);
      b.set(-Math.sin(angle) * length * 0.52, 0.015, Math.cos(angle) * length * 0.52);
      const tilt = new THREE.Quaternion().setFromEuler(new THREE.Euler((random() - 0.5) * 2.3, 0, (random() - 0.5) * 2.0));
      a.applyQuaternion(tilt);
      b.applyQuaternion(tilt);
      const tips = [center.clone().add(a), center.clone().add(b), center.clone().sub(a), center.clone().sub(b)];
      const ridge = center.clone().add(new THREE.Vector3(0, 0.036, 0));
      for (let n = 0; n < 4; n += 1) positions.push(...ridge.toArray(), ...tips[n].toArray(), ...tips[(n + 1) % 4].toArray());
    }
    const geometry = new THREE.BufferGeometry();
    geometry.setAttribute("position", new THREE.Float32BufferAttribute(positions, 3));
    geometry.setAttribute("uv", new THREE.Float32BufferAttribute(new Float32Array(positions.length / 3 * 2), 2));
    geometry.computeVertexNormals();
    const result = this.mesh(geometry, color);
    (result.material as THREE.MeshStandardMaterial).side = THREE.DoubleSide;
    return result;
  }

  pole(from: number[], to: number[], radius: number, color: number): THREE.Mesh {
    const a = new THREE.Vector3(...from);
    const b = new THREE.Vector3(...to);
    const direction = b.clone().sub(a);
    const mesh = this.mesh(this.cache.cylinder(radius * 0.85, radius, direction.length(), 10), color);
    mesh.position.copy(a).add(b).multiplyScalar(0.5);
    mesh.quaternion.setFromUnitVectors(new THREE.Vector3(0, 1, 0), direction.normalize());
    return mesh;
  }

  label(text: string, width: number, height: number, color = "#355461"): THREE.Mesh {
    const canvas = document.createElement("canvas");
    canvas.width = 768;
    canvas.height = 160;
    const context = canvas.getContext("2d");
    if (context) {
      context.fillStyle = color;
      context.fillRect(0, 0, 768, 160);
      context.fillStyle = "#f1ecdc";
      context.font = "500 74px sans-serif";
      context.textAlign = "center";
      context.textBaseline = "middle";
      context.fillText(text, 384, 82);
    }
    const texture = new THREE.CanvasTexture(canvas);
    texture.colorSpace = THREE.SRGBColorSpace;
    texture.anisotropy = 4;
    const material = new THREE.MeshBasicMaterial({ map: texture, toneMapped: false });
    return new THREE.Mesh(this.cache.plane(width, height), material);
  }

  tree(seed: number, mature = true): THREE.Group {
    const group = new THREE.Group();
    const height = mature ? 5.0 + (seed * 7 % 11) * 0.15 : 3.6 + seed % 3 * 0.22;
    group.add(this.pole([0, 0, 0], [0.14, height * 0.84, -0.08], 0.19, C.trunk));
    for (let branch = 0; branch < 7; branch += 1) {
      const angle = branch * 2.4 + seed * 0.7;
      const x = Math.cos(angle) * (1.2 + branch % 3 * 0.23);
      const z = Math.sin(angle) * (1.15 + branch % 3 * 0.22);
      const y = height - 0.7 + branch % 3 * 0.49;
      group.add(this.pole([0, height * 0.58, 0], [x * 0.84, y, z * 0.84], 0.09, C.trunk));
      for (let cluster = 0; cluster < 2; cluster += 1) {
        const azimuth = angle + cluster * 2.1;
        const radius = 0.59 + (seed + branch * 3 + cluster) % 5 * 0.065;
        const foliage = this.foliage(seed * 173 + branch * 13 + cluster,
          [C.leaf, C.leafLight, C.leafDark][(seed + branch + cluster) % 3]);
        foliage.position.set(x + Math.cos(azimuth) * 0.52, y + 0.3 + cluster % 2 * 0.52, z + Math.sin(azimuth) * 0.51);
        foliage.scale.set(radius, radius * 0.85, radius * 1.1);
        foliage.rotation.set(cluster * 0.2, angle, branch * 0.12);
        group.add(foliage);
      }
    }
    const crown = this.foliage(seed * 151, C.leafLight);
    crown.position.set(0.1, height + 0.82, 0.12);
    crown.scale.set(0.95, 0.74, 0.91);
    group.add(crown);
    for (const side of [-1, 1]) {
      group.add(this.pole([side * 0.1, 0.03, 0.05], [side * 0.58, 0.025, 0.24], 0.08, C.trunk));
    }
    return group;
  }

  planter(length: number, flower = false): THREE.Group {
    const group = new THREE.Group();
    group.add(this.box(length, 0.42, 1.2, C.stone, 0, 0.21));
    group.add(this.box(length - 0.18, 0.05, 1.02, 0x6a6353, 0, 0.44));
    for (let x = -length / 2 + 0.35; x < length / 2; x += 0.55) {
      group.add(this.sphere(x, 0.66, 0, 0.47, 0.35, 0.42, x < 0 ? C.leafDark : C.leaf));
      if (flower) for (const z of [-0.2, 0.16]) {
        group.add(this.sphere(x + z * 0.4, 0.96, z, 0.065, 0.055, 0.065, z < 0 ? 0xead4b0 : 0xc98981));
      }
    }
    return group;
  }

  bench(): THREE.Group {
    const group = new THREE.Group();
    for (let n = 0; n < 5; n += 1) {
      group.add(this.box(2.1, 0.07, 0.115, C.timber, 0, 0.59, -0.25 + n * 0.14));
      if (n < 3) group.add(this.box(2.1, 0.115, 0.065, C.timber, 0, 0.83 + n * 0.15, 0.36));
    }
    for (const x of [-0.8, 0.8]) {
      group.add(this.pole([x, 0.05, -0.22], [x, 0.64, -0.14], 0.038, C.metal));
      group.add(this.pole([x, 0.04, 0.36], [x, 1.2, 0.39], 0.038, C.metal));
      group.add(this.pole([x, 0.82, -0.16], [x, 0.83, 0.34], 0.032, C.metal));
    }
    return group;
  }

  lamp(): THREE.Group {
    const group = new THREE.Group();
    group.add(this.mesh(this.cache.cylinder(0.2, 0.28, 0.24, 16), C.metal, 0, 0.12));
    group.add(this.pole([0, 0.12, 0], [0, 5.3, 0], 0.064, C.metal));
    group.add(this.pole([0, 5.2, 0], [0.7, 5.55, 0], 0.048, C.metal));
    group.add(this.box(0.94, 0.1, 0.37, C.metal, 0.85, 5.51));
    group.add(this.box(0.76, 0.035, 0.26, 0xf2e6c6, 0.89, 5.44));
    group.add(this.box(0.32, 0.52, 0.025, 0x779689, 0.08, 3.2, 0.05));
    return group;
  }

  building(width: number, floors: number, depth: number, variant: number): THREE.Group {
    const group = new THREE.Group();
    const height = floors * 2.8 + 0.6;
    const wall = [C.cream, C.brick, 0xc9c7bb, 0xb2b4a6][variant % 4];
    group.add(this.box(width, height, depth, wall, 0, height / 2));
    group.add(this.box(width + 0.45, 0.2, depth + 0.4, C.stone, 0, height + 0.08));
    group.add(this.box(width - 0.35, 0.24, depth - 0.35, C.concrete, 0, height + 0.3));
    for (let floor = 0; floor < floors; floor += 1) {
      const y = 1.65 + floor * 2.8;
      group.add(this.box(width + 0.8, 0.15, depth + 0.8, C.stone, 0, y + 1.0));
      for (const face of [0, 1, -1]) {
        const row = new THREE.Group();
        const span = face === 0 ? width : depth;
        const count = Math.max(2, Math.floor(span / 2));
        for (let col = 0; col < count; col += 1) {
          const x = (col - (count - 1) / 2) * (span - 1.35) / count;
          const tint = (col + floor + variant) % 3 ? C.glass : C.glassLight;
          row.add(this.box(1.6, 1.89, 0.16, C.frame, x, y, 0.02));
          row.add(this.box(1.48, 1.76, 0.055, tint, x, y, 0.13));
          row.add(this.box(0.045, 1.52, 0.07, C.frame, x, y, 0.17));
          row.add(this.box(1.4, 0.08, 0.3, C.stone, x, y - 0.86, 0.13));
          row.add(this.box(1.2, 0.035, 0.08, C.frame, x, y + 0.26, 0.17));
          if (variant % 2 && floor > 0) {
            for (const offset of [-0.53, 0.53]) row.add(this.box(0.07, 1.95, 0.44, C.timber, x + offset, y, 0.26));
          }
        }
        if (face === 0) row.position.z = depth / 2;
        else {
          row.rotation.y = face * Math.PI / 2;
          row.position.x = face * width / 2;
        }
        group.add(row);
      }
    }
    // Shaded entrance recess, mullions, handles, canopy and accessible paving.
    group.add(this.box(2.6, 2.35, 0.18, C.dark, 0, 1.175, depth / 2 + 0.22));
    group.add(this.box(2.3, 2.12, 0.045, C.glassLight, 0, 1.16, depth / 2 + 0.34));
    for (const x of [-0.12, 0.12]) group.add(this.pole([x, 0.75, depth / 2 + 0.39], [x, 1.28, depth / 2 + 0.39], 0.017, C.metal));
    group.add(this.box(3.6, 0.16, 2.0, C.frame, 0, 2.72, depth / 2 + 0.7));
    group.add(this.box(3.4, 0.08, 2.0, C.pavement, 0, 0.04, depth / 2 + 0.85));
    for (const x of [-1.58, 1.58]) group.add(this.pole([x, 0, depth / 2 + 1.5], [x, 2.72, depth / 2 + 1.5], 0.055, C.metal));
    if (variant === 0) {
      const sign = this.label("东区食堂", 3.9, 0.72);
      sign.position.set(0, 3.2, depth / 2 + 0.11);
      group.add(sign);
    }
    for (const x of [-width * 0.33, width * 0.33]) {
      group.add(this.box(0.9, 0.6, 1.3, C.concrete, x, height + 0.5, 0));
      for (let slat = 0; slat < 4; slat += 1) group.add(this.box(0.75, 0.035, 0.05, C.metal, x, height + 0.33 + slat * 0.12, 0.68));
    }
    return group;
  }

  rack(color: number): THREE.Group {
    const group = new THREE.Group();
    for (let n = 0; n < 3; n += 1) {
      const bike = createChaseBicycleRig(this.cache, { ...DEFAULT_CHASE_RIDER_RIG_PALETTE, blue: color }).bicycleRoot;
      bike.position.set((n - 1) * 0.95, 0.055, n % 2 * 0.15);
      bike.rotation.y = -0.42;
      bike.traverse((part) => { if (part instanceof THREE.Mesh) part.userData.chaseStatic = true; });
      group.add(bike);
      group.add(this.pole([(n - 1) * 0.95, 0.02, -0.9], [(n - 1) * 0.95, 0.4, -0.9], 0.025, C.metal));
    }
    return group;
  }

  construction(): void {
    const z0 = -377 * CHASE_WORLD_PER_METER - 10;
    const length = (566 - 377) * CHASE_WORLD_PER_METER - 22;
    this.root.add(this.box(9, 0.04, length, 0xa79881, 13.5, 0.02, z0 - length / 2));
    for (let n = 0; n * 5.3 < length; n += 1) {
      const z = z0 - n * 5.3;
      this.root.add(this.box(0.1, 1.85, 5.1, n % 2 ? 0x678e8a : 0x789f94, 9.05, 1.04, z));
      this.root.add(this.box(0.2, 0.11, 5.2, C.frame, 9.05, 2.02, z));
      this.root.add(this.pole([9.05, 0, z + 2.58], [9.05, 2.16, z + 2.58], 0.055, C.metal));
      this.root.add(this.box(0.5, 0.16, 0.7, C.concrete, 9.05, 0.08, z + 2.58));
    }
    for (let n = 0; n < 4; n += 1) {
      const z = z0 - 17 - n * 23;
      for (let tier = 0; tier < 3; tier += 1) {
        this.root.add(this.box(3.6 - tier * 0.2, 0.32, 1.7, 0xb69a78, 12.5, tier * 0.38 + 0.2, z));
      }
      for (let pipe = 0; pipe < 4; pipe += 1) {
        const cylinder = this.mesh(this.cache.cylinder(0.24, 0.24, 3.8, 16, 1, true), C.concrete, 15.5 + pipe * 0.54, 0.25, z - 4);
        cylinder.rotation.x = Math.PI / 2;
        this.root.add(cylinder);
      }
    }
    // The road remains governed only by visible ChaseGeometry obstacles.
    const warning = this.label("前方施工", 3.6, 0.75, "#a97643");
    warning.position.set(7.35, 2.2, z0 + 8);
    this.root.add(warning, this.pole([7.35, 0, z0 + 8], [7.35, 2.55, z0 + 8], 0.045, C.metal));
  }

  theater(): THREE.Group {
    const group = new THREE.Group();
    group.name = "canteen-shared-modeled-theater";
    // Independently designed folded-roof hall: broad glazing, asymmetric
    // volumes and timber fins. No earlier facade or visual reference is used.
    for (const side of [-1, 1]) {
      const wing = this.building(side < 0 ? 8.5 : 6.5, side < 0 ? 2 : 3, 6, side < 0 ? 2 : 1);
      wing.position.set(side * 10.2, 0, -2.4);
      group.add(wing);
      const planter = this.planter(4.2, true);
      planter.position.set(side * 8.1, 0, 2.7);
      const lamp = this.lamp();
      lamp.position.set(side * 10.4, 0, 5.2);
      group.add(planter, lamp);
    }
    group.add(this.box(13.2, 8.6, 6, C.cream, 0, 4.3, -2));
    group.add(this.box(11.6, 7.2, 0.12, C.dark, 0, 3.9, 1.06));
    for (let col = -4; col <= 4; col += 1) for (let row = 0; row < 3; row += 1) {
      group.add(this.box(1.18, 1.75, 0.08, (col + row) % 3 ? C.glass : C.glassLight,
        col * 1.25, 2 + row * 1.85, 1.15));
    }
    for (let x = -6; x <= 6; x += 0.6) {
      if (Math.abs(x) < 2.6) continue;
      group.add(this.box(0.11, 7.2, 0.52, C.timber, x, 4.1, 1.47));
    }
    for (const side of [-1, 1]) {
      const roof = this.box(8.2, 0.27, 8.4, C.frame, side * 3.7, 8.6, -1.7);
      roof.rotation.z = side * 0.12;
      group.add(roof);
      const fascia = this.box(8.2, 0.38, 0.14, C.metal, side * 3.7, 8.55, 2.5);
      fascia.rotation.z = side * 0.12;
      group.add(fascia);
    }
    group.add(this.box(4.6, 3.3, 0.32, C.dark, 0, 1.65, 1.7));
    for (const side of [-1, 1]) {
      group.add(this.box(2.05, 3.08, 0.08, C.glassLight, side * 1.08, 1.6, 1.91));
      group.add(this.pole([side * 0.16, 1.1, 2.02], [side * 0.16, 1.68, 2.02], 0.026, C.metal));
    }
    group.add(this.box(0.09, 3.25, 0.16, C.frame, 0, 1.65, 1.98));
    group.add(this.box(6.4, 0.15, 2.2, C.frame, 0, 3.52, 2.0));
    const sign = this.label("剧场", 2.8, 0.57);
    sign.position.set(0, 4.04, 1.71);
    group.add(sign);
    return group;
  }

  transition(stage: "start" | "finish"): THREE.Group {
    const root = new THREE.Group();
    root.name = `canteen-transition-${stage}-world`;
    root.add(this.box(65, 0.08, 65, C.lawn, 0, -0.1, -7));
    root.add(this.box(11.1, 0.04, 65, C.asphalt, 0, -0.03, -7));
    for (const side of [-1, 1]) {
      root.add(this.box(3.2, 0.12, 65, C.pavement, side * 7.25, 0, -7));
      for (let z = 20; z > -35; z -= 1.3) root.add(this.box(0.23, 0.2, 1.24, C.stone, side * 5.65, 0.06, z));
      for (let n = 0; n < 4; n += 1) {
        const tree = this.tree(n * 2 + (side > 0 ? 1 : 0), stage === "start");
        tree.position.set(side * 11.4, 0, 9 - n * 11);
        root.add(tree);
      }
      const lamp = this.lamp();
      lamp.position.set(side * 6.05, 0, -7);
      root.add(lamp);
    }
    for (const x of [-1.675, 1.675]) for (let z = 20; z > -24; z -= 7.6) root.add(this.box(0.11, 0.006, 3.4, C.marking, x, -0.004, z));
    if (stage === "start") {
      const canteen = this.building(18, 2, 8, 0);
      canteen.position.set(-18, 0, -3);
      canteen.rotation.y = Math.PI / 2;
      const rack = this.rack(0x508998);
      rack.position.set(8.9, 0.08, -4.2);
      root.add(canteen, rack);
    } else {
      const theater = this.theater();
      theater.position.set(0, 0, -18.5);
      root.add(theater);
      const approach = this.box(18.6, 0.035, 13, C.pavement, 0, 0.02, -12.4);
      approach.name = "canteen-transition-flat-theater-approach";
      root.add(approach);
    }
    return root;
  }

  build(): THREE.Group {
    const length = CHASE_GOAL_METERS * CHASE_WORLD_PER_METER;
    const center = -length / 2;
    this.root.add(this.box(100, 0.09, length + 130, C.lawn, 0, -0.13, center));
    this.root.add(this.box(11.1, 0.07, length + 100, C.asphalt, 0, -0.055, center));
    for (const side of [-1, 1]) {
      this.root.add(this.box(3.2, 0.14, length + 95, C.pavement, side * 7.26, -0.015, center));
      this.root.add(this.box(0.12, 0.014, length + 90, C.marking, side * 5.23, 0.005, center));
      this.root.add(this.box(0.3, 0.012, length + 90, C.tactile, side * 7.35, 0.065, center));
      for (let z = 24; z > -length - 35; z -= 1.3) {
        this.root.add(this.box(0.23, 0.2, 1.24, C.stone, side * 5.65, 0.06, z));
        this.root.add(this.box(3.1, 0.006, 0.024, C.joints, side * 7.3, 0.061, z));
      }
      for (let z = 12; z > -length - 12; z -= 24) {
        this.root.add(this.box(0.32, 0.014, 0.68, C.dark, side * 5.36, 0.008, z));
        for (let n = 0; n < 6; n += 1) this.root.add(this.box(0.27, 0.016, 0.036, C.metal, side * 5.36, 0.018, z - 0.28 + n * 0.1));
      }
    }
    for (const x of [-1.675, 1.675]) for (let z = 20; z > -length - 15; z -= 7.6) {
      this.root.add(this.box(0.11, 0.006, 3.4, C.marking, x, -0.01, z));
    }
    // Low-contrast surface repairs stay decorative, distinct from real barriers.
    for (let n = 0; n * 21.8 < length; n += 1) {
      this.root.add(this.box(0.8, 0.002, 2.5, C.asphaltDetail, (n % 3 - 1) * 3.35, -0.015, -n * 21.8));
    }
    for (let n = 0; n * 12 < length + 36; n += 1) {
      const z = 14 - n * 12;
      const distance = Math.max(0, -z / CHASE_WORLD_PER_METER);
      const stage = chaseStageAt(distance);
      for (const side of [-1, 1]) {
        if (stage.id === "construction" && side > 0) continue;
        const tree = this.tree(n * 3 + (side > 0 ? 1 : 0), stage.id !== "theater");
        tree.position.set(side * (stage.id === "theater" ? 12.5 : 10.5) + Math.sin(n * 3.7) * 0.35, 0, z + side * 1.7);
        this.root.add(tree);
        if (n % 2 === 1) {
          const hedge = this.planter(5.5, stage.id === "theater");
          hedge.rotation.y = Math.PI / 2;
          hedge.position.set(side * 13.2, 0, z - 5.2);
          this.root.add(hedge);
        }
        if (n % 2 === 0) {
          const lamp = this.lamp();
          lamp.position.set(side * 6.08, 0, z - 4.2);
          if (side > 0) lamp.rotation.y = Math.PI;
          this.root.add(lamp);
        }
        if (n % 3 === 0) {
          const planter = this.planter(stage.id === "theater" ? 4.4 : 2.6, stage.id === "theater");
          planter.rotation.y = Math.PI / 2;
          planter.position.set(side * 9.1, 0, z - 5.5);
          const bench = this.bench();
          bench.rotation.y = -side * Math.PI / 2;
          bench.position.set(side * 8.25, 0.06, z - 1.5);
          this.root.add(planter, bench);
        }
      }
    }
    const buildings = [
      { d: 0, side: -1, w: 18, f: 2, type: 0 },
      { d: 40, side: 1, w: 14, f: 3, type: 1 },
      { d: 104, side: -1, w: 12, f: 3, type: 2 },
      { d: 152, side: 1, w: 20, f: 4, type: 3 },
      { d: 232, side: -1, w: 18, f: 3, type: 3 },
      { d: 306, side: 1, w: 24, f: 3, type: 2 },
      { d: 435, side: -1, w: 16, f: 3, type: 1 },
      { d: 502, side: -1, w: 20, f: 4, type: 2 },
      { d: 617, side: -1, w: 14, f: 2, type: 2 },
      { d: 647, side: 1, w: 18, f: 2, type: 1 }
    ];
    for (const entry of buildings) {
      const building = this.building(entry.w, entry.f, 8, entry.type);
      building.position.set(entry.side * 20, 0, -entry.d * CHASE_WORLD_PER_METER);
      building.rotation.y = -entry.side * Math.PI / 2;
      this.root.add(building);
    }
    for (const entry of [{ d: 20, side: 1, color: 0x508998 }, { d: 174, side: -1, color: 0xaa9260 }, { d: 630, side: 1, color: 0x54758a }]) {
      const rack = this.rack(entry.color);
      rack.position.set(entry.side * 9.05, 0.06, -entry.d * CHASE_WORLD_PER_METER);
      rack.rotation.y = entry.side * Math.PI / 2;
      this.root.add(rack);
    }
    this.construction();
    const avenueSign = this.label("求是路", 2.4, 0.55);
    avenueSign.position.set(-7.1, 2.7, -190 * CHASE_WORLD_PER_METER);
    this.root.add(avenueSign, this.pole([-7.1, 0, avenueSign.position.z], [-7.1, 2.98, avenueSign.position.z], 0.04, C.metal));
    return this.root;
  }
}

export function createChaseCampusEnvironment(cache: ThreePrimitiveCache): THREE.Group {
  return new CampusEnvironmentBuilder(cache).build();
}

export function createChaseTheaterFacade(cache: ThreePrimitiveCache): THREE.Group {
  return new CampusEnvironmentBuilder(cache).theater();
}

export function createChaseTransitionEnvironment(cache: ThreePrimitiveCache, stage: "start" | "finish"): THREE.Group {
  return new CampusEnvironmentBuilder(cache).transition(stage);
}
