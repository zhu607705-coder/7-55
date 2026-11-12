import * as T from 'three';
import { HALF_WIDTH, GAPS, RAMPS, BRIDGES, OBSTACLES, WALLS, SECTIONS, FINISH, deckAt, elevationAt } from './course.js';
import { createAvatar } from './avatar.js';

const SUN = new T.Vector3(-.42, .29, -.86).normalize();
const BOX = new T.BoxGeometry(1, 1, 1);
const COLORS = {
  roof: '#385763', seam: '#293e4d', edge: '#617e82', concrete: '#5d7981',
  wall: '#244654', bronze: '#956a53', steel: '#213945', pale: '#b7b6a2',
  rail: '#e09a59', danger: '#c54d42', path: '#76e0c5', light: '#ffdb96', teal: '#3b847e',
  recess: '#17313f', black: '#142634',
};
const mat = (color, roughness = .84) => new T.MeshStandardMaterial({ color, roughness });
const mats = Object.fromEntries(Object.entries(COLORS).map(([key, value]) => [key, mat(value)]));
mats.path.emissive.set('#37b59f'); mats.path.emissiveIntensity = .60;
mats.light.emissive.set('#ed9d50'); mats.light.emissiveIntensity = .55;
mats.danger.emissive.set('#a3352b'); mats.danger.emissiveIntensity = .22;
const noop = new T.Vector3();
const pivot = new T.Object3D();

function makeBatch(parent) {
  const entries = new Map();
  return {
    add(kind, x, y, z, sx, sy, sz, rotation = 0, shadow = true, pitch = 0) {
      const name = kind + (shadow ? ' cast' : '');
      if (!entries.has(name)) entries.set(name, { kind, shadow, transforms: [] });
      pivot.position.set(x, y, z);
      pivot.scale.set(sx, sy, sz);
      pivot.rotation.set(pitch, rotation, 0);
      pivot.updateMatrix();
      entries.get(name).transforms.push(pivot.matrix.clone());
    },
    flush() {
      for (const [name, entry] of entries) {
        const mesh = new T.InstancedMesh(BOX, mats[entry.kind], entry.transforms.length);
        entry.transforms.forEach((matrix, i) => mesh.setMatrixAt(i, matrix));
        mesh.name = name;
        mesh.castShadow = entry.shadow;
        mesh.receiveShadow = true;
        parent.add(mesh);
      }
    },
  };
}

function seeded(seed) {
  let value = seed;
  return () => {
    value = (Math.imul(value, 1664525) + 1013904223) >>> 0;
    return value / 4294967296;
  };
}

function createSky(scene) {
  const sky = new T.Mesh(new T.SphereGeometry(450, 24, 14), new T.ShaderMaterial({
    side: T.BackSide,
    depthWrite: false,
    uniforms: {
      sun: { value: SUN },
      low: { value: new T.Color('#f4bd89') },
      upper: { value: new T.Color('#436f8c') },
      halo: { value: new T.Color('#ffaf65') },
    },
    vertexShader: `
      varying vec3 direction;
      void main() {
        direction = position;
        gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
      }`,
    fragmentShader: `
      uniform vec3 sun, low, upper, halo;
      varying vec3 direction;
      void main() {
        vec3 d = normalize(direction);
        vec3 ink = mix(low, upper, smoothstep(-.08,.80,d.y));
        float glare = max(0.0, dot(d, sun));
        ink = mix(ink, halo, pow(glare, 28.0) * .60);
        ink += pow(glare, 360.0) * vec3(.52,.22,.08);
        ink += smoothstep(.9987,.99955,glare) * vec3(2.3,1.7,1.0);
        gl_FragColor = vec4(ink,1.0);
        #include <tonemapping_fragment>
        #include <colorspace_fragment>
      }`,
  }));
  sky.frustumCulled = false;
  scene.add(sky);
  return sky;
}

function buildCity(scene) {
  const random = seeded(755);
  const group = new T.Group();
  group.name = 'Coastal skyline';
  scene.add(group);
  const rows = [
    { x: 28, y: -36, near: true, count: Math.ceil((FINISH + 100) / 14), depth: 24 },
    { x: 85, y: -30, near: false, count: Math.ceil((FINISH + 150) / 18), depth: 32 },
    { x: 154, y: -24, near: false, count: Math.ceil((FINISH + 175) / 18), depth: 42 },
  ];
  for (const side of [-1, 1]) {
    for (const row of rows) {
      const body = new T.InstancedMesh(BOX, mat('#ffffff'), row.count);
      const caps = new T.InstancedMesh(BOX, mat('#c9c5ae'), row.count);
      const faces = new T.InstancedMesh(BOX, mat('#c0d0c7'), row.count);
      const windows = new T.InstancedMesh(BOX, mat('#688997'), row.near ? row.count * 7 : 1);
      const shades = side < 0 ? ['#567987', '#638795', '#c1947d', '#75929b'] : ['#486979', '#698c94', '#c49a7d', '#466172'];
      let windowIndex = 0;
      for (let n = 0; n < row.count; n++) {
        const x = side * (row.x + random() * row.depth);
        const z = 25 - n * (row.near ? 14 : 18) - random() * 6;
        const height = 11 + random() * (row.near ? 33 : 43);
        const w = 8 + random() * 11;
        const d = 7 + random() * 10;
        const y = row.y + height / 2;
        const assign = (mesh, i, px, py, pz, sx, sy, sz) => {
          pivot.position.set(px, py, pz);
          pivot.scale.set(sx, sy, sz);
          pivot.rotation.set(0, 0, 0);
          pivot.updateMatrix();
          mesh.setMatrixAt(i, pivot.matrix);
        };
        assign(body, n, x, y, z, w, height, d);
        body.setColorAt(n, new T.Color(shades[n % shades.length]));
        assign(caps, n, x, y + height / 2 + .32, z, w + .45, .64, d + .45);
        assign(faces, n, x, y + height / 2 + 1.1, z, w * .46, 1.7, d * .52);
        if (row.near) {
          for (let floor = 0; floor < 7; floor++) {
            const wy = y + height / 2 - 2.3 - floor * height / 8.1;
            assign(windows, windowIndex++, x - side * (w / 2 + .021), wy, z, .05, .74, d * .70);
          }
        }
      }
      group.add(body, caps, faces);
      if (row.near) group.add(windows);
    }
  }
  const water = new T.Mesh(new T.PlaneGeometry(760, 1100), mat('#527882', .44));
  water.rotation.x = -Math.PI / 2;
  water.position.set(0, -37, -FINISH / 2);
  scene.add(water);
}

function buildRoute(scene) {
  const groups = [];
  const limits = [...new Set([-26, FINISH + 26, ...[...GAPS, ...RAMPS, ...BRIDGES].flatMap(part => [part.start, part.end])])].sort((a, b) => a - b);
  for (let index = 1; index < limits.length; index++) {
    const start = limits[index - 1], end = limits[index];
    const center = -(start + end) / 2;
    const deck = deckAt(-center);
    if (!deck) continue;
    const group = new T.Group();
    const batch = makeBatch(group);
    const depth = end - start;
    const base = elevationAt(-center);
    const slope = (elevationAt(end) - elevationAt(start)) / depth;
    group.position.y = base;
    scene.add(group);
    groups.push({ object: group, start, end });

    if (deck.half < HALF_WIDTH) {
      const width = deck.half * 2;
      batch.add('steel', deck.x, -.26, center, width, .52, depth);
      batch.add('roof', deck.x, -.04, center, width, .08, depth);
      if (GAPS.some(gap => Math.abs(gap.start - end) < .3)) {
        batch.add('light', deck.x, .014, -end + .14, width - .16, .03, .12, 0, false);
      }
      for (const side of [-1, 1]) {
        const x = deck.x + side * (deck.half - .06);
        batch.add('path', x, .025, center, .052, .05, depth, 0, false);
        batch.add('steel', x, -1.22, center, .13, .14, depth);
        for (let s = start + .36; s < end - .1; s += .92) {
          batch.add('seam', deck.x, .004, -s, width - .18, .014, .050, 0, false);
          batch.add('bronze', x, -.82, -s, .12, .09, 1.16, 0, true, side * .68);
        }
      }
      batch.flush();
      continue;
    }

    if (slope) {
      const pitch = Math.atan(slope);
      const length = Math.hypot(depth, slope * depth);
      batch.add('steel', 0, -.31 * Math.cos(pitch), center - .31 * Math.sin(pitch), HALF_WIDTH * 2, .62, length, 0, true, pitch);
      batch.add('roof', 0, -.052 * Math.cos(pitch), center - .052 * Math.sin(pitch), HALF_WIDTH * 2 - .12, .104, length, 0, true, pitch);
      for (const side of [-1, 1]) {
        batch.add('rail', side * 4.10, .046, center, .10, .085, length, 0, true, pitch);
        batch.add('steel', side * 4.18, .86, center, .13, .12, length, 0, true, pitch);
        for (let s = start + .65; s < end - .4; s += 2.0) {
          batch.add('edge', side * 4.17, elevationAt(s) - base + .43, -s, .12, .86, .12);
        }
      }
      batch.flush();
      continue;
    }

    if (depth >= 1) {
      batch.add('wall', 0, -15.0, center, 10.8, 27, depth);
      batch.add('concrete', 0, -.69, center, 9.65, 1.22, depth);
    }
    batch.add('roof', 0, -.094, center, HALF_WIDTH * 2, .188, depth);
    for (const side of [-1, 1]) {
      batch.add('edge', side * 4.23, -.11, center, .21, .22, depth);
      batch.add('seam', side * 3.91, .012, center, .07, .024, depth, 0, false);
      for (let s = start + 2; s < end - 1; s += 4.1) {
        batch.add('edge', side * 4.47, .42, -s, .11, 1.07, .12);
        const span = Math.min(4.1, end - s - .45);
        if (span > 0) batch.add('steel', side * 4.47, .90, -s - span / 2, .11, .09, span);
        batch.add('recess', side * 5.413, -4.0, -s, .08, 4.0, 2.7, 0, false);
        batch.add('teal', side * 5.459, -3.6, -s, .035, .07, 2.38, 0, false);
        batch.add('concrete', side * 5.41, -7.6, -s, .15, .15, 3.1, 0, false);
        if (Math.floor(s / 4.1) % 5 === (side > 0 ? 1 : 3)) {
          batch.add('concrete', side * 4.83, -.15, -s, .92, .31, 1.8);
          batch.add('steel', side * 4.85, .38, -s, .59, .82, 1.40);
          batch.add('edge', side * 4.85, .83, -s, .68, .12, 1.50);
          for (let fin = -2; fin <= 2; fin++) {
            batch.add('recess', side * 4.54, .45, -s + fin * .21, .045, .43, .095, 0, false);
          }
        }
      }
      for (let s = Math.ceil(start / 3.2) * 3.2; s < end; s += 3.2) {
        batch.add('seam', side * 2.95, .005, -s, 2.10, .011, .024, 0, false);
      }
    }
    for (const lip of [start, end]) {
      if (depth < 1 || !GAPS.some(gap => gap.start === lip || gap.end === lip)) continue;
      batch.add('rail', 0, .012, -lip + (lip === end ? .10 : -.10), HALF_WIDTH * 2, .024, .18);
      for (let n = -5; n <= 5; n++) {
        batch.add('light', n * .7, .027, -lip + (lip === end ? .51 : -.51), .30, .022, .072, 0, false);
      }
    }
    for (let s = Math.ceil(start / 8) * 8 + 1; s < end - 1; s += 8) {
      for (const x of [-1.24, 1.24]) batch.add('edge', x, .012, -s, .042, .018, .91, 0, false);
    }
    batch.flush();
  }

  function localGroup(start, end, draw) {
    const object = new T.Group();
    object.position.y = elevationAt((start + end) / 2);
    const batch = makeBatch(object);
    draw(batch);
    batch.flush();
    scene.add(object);
    groups.push({ object, start, end });
  }

  for (const item of OBSTACLES) {
    localGroup(item.start, item.end, b => {
      const z = -(item.start + item.end) / 2;
      const depth = item.end - item.start;
      if (item.type === 'hurdle') {
        b.add('steel', item.x, .30, z, item.span, .60, depth);
        b.add('danger', item.x, .67, z, item.span, .16, depth);
        b.add('rail', item.x, .77, z, item.span, .05, depth + .06);
        for (let x = -3.75; x < 4; x += .78) {
          b.add('edge', x, .30, z + depth / 2 + .012, .5, .28, .033);
          b.add('light', x, .66, z + depth / 2 + .022, .34, .055, .032, 0, false);
        }
      } else if (item.type === 'beam') {
        b.add('steel', 0, 1.58, z, item.span + .25, 1.01, depth);
        b.add('path', 0, 1.09, z + depth / 2 + .025, item.span, .07, .065, 0, false);
        for (const x of [-4.22, 4.22]) {
          b.add('bronze', x, 1.10, z, .22, 2.2, depth + .12);
          b.add('path', x, .62, z + depth * .5 + .08, .14, .58, .10, 0, false);
        }
        for (let x = -3.75; x < 4; x += .75) b.add('recess', x, 1.59, z + depth / 2 + .015, .47, .42, .04);
      } else {
        b.add('concrete', item.x, 1.49, z, item.span, 2.98, depth);
        b.add('steel', item.x, 1.26, z + depth * .5 + .045, item.span - .24, 2.3, .10);
        b.add('rail', item.x, 2.92, z, item.span + .13, .18, depth + .12);
        for (let n = -3; n <= 3; n++) b.add('edge', item.x + n * .67, 1.64, z + depth / 2 + .115, .46, .93, .04);
        for (let n = 0; n < 6; n++) b.add('path', -Math.sign(item.x) * 2.52, .018, z + 4.5 - n, .84, .036, .11, 0, false);
      }
    });
  }

  for (const wall of WALLS) {
    localGroup(wall.start, wall.end, b => {
      const x = wall.side * 4.23;
      const width = wall.end - wall.start;
      const z = -(wall.start + wall.end) / 2;
      b.add('teal', x, 1.34, z, .43, 3.12, width);
      b.add('steel', x, 3.00, z, .56, .17, width);
      b.add('steel', x, -.56, z, .66, .35, width);
      b.add('steel', x, -3.84, z, .41, .24, width);
      const gapLength = wall.gap.end - wall.gap.start;
      for (let t = 0; t < 4; t++) {
        const stride = gapLength / 4;
        const center = wall.gap.start + (t + .5) * stride;
        const diagonal = Math.hypot(3.15, stride);
        const brace = t % 2 ? -1 : 1;
        const braceGroup = new T.Group();
        const mesh = new T.Mesh(BOX, mats.steel);
        mesh.position.set(x, elevationAt(center) - 2.18, -center);
        mesh.scale.set(.30, diagonal, .24);
        mesh.rotation.x = brace * Math.atan2(stride, 3.15);
        braceGroup.add(mesh);
        scene.add(braceGroup);
        groups.push({ object: braceGroup, start: center - stride, end: center + stride });
      }
      for (let n = wall.start + .6; n < wall.end - .55; n += 1.34) {
        b.add('concrete', x - wall.side * .25, 1.62, -n, .09, 2.36, 1.21);
        b.add('path', x - wall.side * .31, 1.94, -n, .034, .13, .95, 0, false);
        b.add('seam', x - wall.side * .31, 1.23, -n, .033, .035, .94, 0, false);
      }
      for (const s of [wall.start, wall.end]) b.add('rail', x - wall.side * .28, 1.51, -s, .12, 3.22, .21);
      for (let i = 0; i < 5; i++) b.add('path', wall.side * 2.47, .022, -wall.start + 5 - i, .85, .027, .13, 0, false);
    });
  }
  for (const bridge of BRIDGES) {
    localGroup(bridge.start - 9, bridge.start, b => {
      const height = elevationAt(bridge.start - 4.5);
      for (let n = 0; n < 7; n++) {
        const s = bridge.start - 8 + n * 1.10;
        const y = elevationAt(s) - height + .023;
        b.add('path', bridge.x - .26, y, -s, .52, .035, .11, .62, false);
        b.add('path', bridge.x + .26, y, -s, .52, .035, .11, -.62, false);
      }
    });
  }
  localGroup(382, 389, b => {
    for (const side of [-1, 1]) {
      const x = side * 4.38;
      b.add('steel', x, 2.14, -382, .50, 4.28, .68);
      b.add('rail', x, 3.32, -381.63, .28, .28, .08);
      b.add('concrete', side * 7.1, .4, -386, 3.25, 3.0, 4.0);
      b.add('steel', side * 7.05, 5.8, -387.5, .22, 8.45, .22);
      b.add('light', side * 7.05, 10.1, -387.5, .30, .23, .30, 0, false);
    }
    b.add('bronze', 0, 4.28, -382, 9.3, .32, .68);
    b.add('path', 0, 4.10, -381.62, 8.55, .085, .12, 0, false);
  });
  for (const section of SECTIONS.slice(1)) {
    localGroup(section.start - 2, section.start + 2, b => {
      for (const side of [-1, 1]) {
        const x = side * 4.04;
        b.add('steel', x, 1.22, -section.start, .25, 2.45, .53);
        b.add('path', x, 1.96, -section.start + .29, .15, .51, .08, 0, false);
        b.add('light', x, 2.42, -section.start, .36, .15, .56, 0, false);
      }
      b.add('path', 0, .022, -section.start, HALF_WIDTH * 2, .036, .11, 0, false);
    });
  }
  localGroup(FINISH - 4, FINISH + 27, b => {
    for (const side of [-1, 1]) {
      b.add('steel', side * 3.72, 3.22, -FINISH, .48, 6.45, .95);
      b.add('rail', side * 3.44, 4.63, -FINISH + .47, .1, 2.40, .09);
      b.add('path', side * 3.42, 2.75, -FINISH + .51, .11, 3.60, .08, 0, false);
    }
    b.add('steel', 0, 6.36, -FINISH, 7.6, .38, .97);
    b.add('light', 0, 6.24, -FINISH + .5, 7.4, .09, .15, 0, false);
    b.add('path', 0, .021, -FINISH, 7.6, .04, .16, 0, false);
    for (const side of [-1, 1]) {
      b.add('concrete', side * 2.65, .7, -FINISH - 14, 2.45, 1.4, 4.8);
      b.add('steel', side * 2.65, 3.8, -FINISH - 20.2, .27, 7.6, .27);
    }
    b.add('steel', 0, 11.0, -FINISH - 20.2, .41, 22, .41);
    for (const y of [8.0, 11.6, 15.2, 18.8]) {
      b.add('edge', 0, y, -FINISH - 20.2, 6.3, .13, .13);
      for (const side of [-1, 1]) b.add('steel', side * 2.84, y + .55, -FINISH - 20.2, .09, 1.18, .09);
    }
    b.add('light', 0, 22.38, -FINISH - 20.2, .48, .44, .48, 0, false);
  });
  return groups;
}

export function createView(canvas, reducedMotion) {
  const renderer = new T.WebGLRenderer({ canvas, antialias: true, powerPreference: 'high-performance' });
  renderer.shadowMap.enabled = true;
  renderer.shadowMap.type = T.PCFShadowMap;
  renderer.outputColorSpace = T.SRGBColorSpace;
  renderer.toneMapping = T.ACESFilmicToneMapping;
  renderer.toneMappingExposure = 1.05;
  const scene = new T.Scene();
  scene.fog = new T.FogExp2('#d8a98b', .0082);
  const camera = new T.PerspectiveCamera(62, 1, .1, 480);
  const sky = createSky(scene);
  const ambient = new T.HemisphereLight('#c5e2ff', '#546878', 2.05);
  scene.add(ambient);
  const sun = new T.DirectionalLight('#ffd1a3', 3.15);
  sun.castShadow = true;
  sun.shadow.mapSize.set(1536, 1536);
  Object.assign(sun.shadow.camera, { left: -24, right: 24, top: 30, bottom: -30, near: 2, far: 102 });
  sun.shadow.normalBias = .035;
  sun.shadow.bias = -.00027;
  sun.shadow.camera.updateProjectionMatrix();
  scene.add(sun, sun.target);
  buildCity(scene);
  const route = buildRoute(scene);
  const avatar = createAvatar();
  scene.add(avatar.root);
  let cameraX = 0;
  let cameraLift = 0;
  let finishTurn = 0;
  let previousS = -100;
  const aim = noop.clone();
  const shadowTarget = noop.clone();

  function resize() {
    const width = canvas.clientWidth;
    const height = canvas.clientHeight;
    if (!width || !height) return;
    renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, width < 680 ? 1.45 : 1.65));
    renderer.setSize(width, height, false);
    camera.aspect = width / height;
    camera.fov = camera.aspect < 1 ? 69 : 59;
    camera.updateProjectionMatrix();
  }

  function draw(model, delta, clock) {
    const snap = Math.abs(previousS - model.s) > 7;
    const eased = snap ? 1 : 1 - Math.exp(-delta * 6);
    cameraX += (model.x * .33 - cameraX) * eased;
    const base = elevationAt(model.s);
    const lift = reducedMotion ? 0 : Math.max(0, model.y - base) * .43;
    cameraLift += (lift - cameraLift) * eased;
    const portrait = camera.aspect < 1;
    const back = portrait ? 7.5 : 5.5;
    const openingAngle = model.phase === 'ready' ? .55 : 0;
    const arrival = model.phase === 'finished';
    finishTurn += ((arrival ? .55 : 0) - finishTurn) * (reducedMotion || snap ? 1 : 1 - Math.exp(-delta * 2.5));
    camera.position.set(cameraX + openingAngle + Math.sin(finishTurn) * back,
      base + (portrait ? 4.2 : 3.45) + cameraLift, -model.s + Math.cos(finishTurn) * back);
    const focus = finishTurn / .55;
    const arrivalOffset = portrait ? .8 : 2.1;
    aim.set(T.MathUtils.lerp(model.x * .19, model.x - arrivalOffset, focus), base + 1.02 + cameraLift * .42,
      -model.s - T.MathUtils.lerp(portrait ? 11 : 14, portrait ? 1.8 : 1.1, focus));
    camera.lookAt(aim);
    sky.position.copy(camera.position);
    shadowTarget.set(0, base, -Math.floor((model.s + 10) * 2) / 2);
    sun.target.position.copy(shadowTarget);
    sun.position.copy(shadowTarget).addScaledVector(SUN, 56);
    for (const group of route) group.object.visible = group.end > model.s - 20 && group.start < model.s + 158;
    avatar.pose(model, clock, delta);
    renderer.render(scene, camera);
    previousS = model.s;
  }

  resize();
  return { resize, draw, renderer };
}
