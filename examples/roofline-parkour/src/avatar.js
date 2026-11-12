import * as T from 'three';
import { RoundedBoxGeometry } from 'three/addons/geometries/RoundedBoxGeometry.js';

const UP = new T.Vector3(0, 1, 0);
const FORWARD = new T.Vector3(0, 0, -1);
const V = (x, y, z) => new T.Vector3(x, y, z);
const smooth = t => t * t * (3 - 2 * t);
const blend = (a, b, amount) => a + (b - a) * amount;

function material(color, roughness = .78) {
  return new T.MeshStandardMaterial({ color, roughness });
}

function boneSegment(geometry, material, group) {
  const mesh = new T.Mesh(geometry, material);
  mesh.castShadow = true;
  group.add(mesh);
  return mesh;
}

function placeBone(mesh, a, b) {
  mesh.position.copy(a).lerp(b, .5);
  const direction = V(0, 0, 0).subVectors(b, a);
  mesh.scale.y = direction.length();
  mesh.quaternion.setFromUnitVectors(UP, direction.normalize());
}

function joint(start, end, pole, upper, lower) {
  const axis = V(0, 0, 0).subVectors(end, start);
  const distance = Math.min(upper + lower - .001, Math.max(Math.abs(upper - lower) + .001, axis.length()));
  axis.normalize();
  end.copy(start).addScaledVector(axis, distance);
  const length = (upper * upper + distance * distance - lower * lower) / (2 * distance);
  const offset = Math.sqrt(Math.max(0, upper * upper - length * length));
  const bend = pole.clone().addScaledVector(axis, -pole.dot(axis)).normalize();
  return start.clone().addScaledVector(axis, length).addScaledVector(bend, offset);
}

export function createAvatar() {
  const root = new T.Group();
  const jacket = material('#cf7541');
  const shell = material('#e99356');
  const seam = material('#7e4837');
  const skin = material('#b77d64');
  const hair = material('#202733');
  const canvas = material('#395558');
  const pants = material('#2b4153');
  const stitch = material('#658292');
  const dark = material('#20374c');
  const sole = material('#182e39');
  const accents = material('#53cfbf');
  const cream = material('#f4dbb3');
  const visor = material('#233e53', .36);
  const scarfInk = material('#c94c36');
  const box = new T.BoxGeometry(1, 1, 1);
  const round = new RoundedBoxGeometry(1, 1, 1, 1, .13);
  const headShape = new T.SphereGeometry(1, 12, 9);
  const hairline = new T.SphereGeometry(1, 14, 9, 0, Math.PI * 2, 0, Math.PI * .58);
  const hip = new T.Group();
  const upper = new T.Group();
  root.add(hip, upper);

  function detail(group, geo, mat, position, size) {
    const mesh = boneSegment(geo, mat, group);
    mesh.position.set(...position);
    mesh.scale.set(...size);
    return mesh;
  }

  detail(hip, round, pants, [0, 0, 0], [.435, .245, .292]);
  detail(hip, round, seam, [0, .094, .022], [.452, .065, .30]);
  detail(hip, round, canvas, [-.15, .053, .153], [.15, .087, .054]);

  detail(upper, round, seam, [0, .137, 0], [.392, .30, .31]);
  detail(upper, round, jacket, [0, .234, -.006], [.548, .365, .318]);
  detail(upper, round, shell, [0, .351, -.012], [.524, .135, .320]);
  detail(upper, round, seam, [0, .143, -.170], [.023, .338, .025]);
  detail(upper, round, jacket, [0, .397, .092], [.336, .136, .226]);
  detail(upper, round, seam, [0, .431, -.01], [.225, .084, .232]);
  detail(upper, headShape, skin, [0, .498, -.021], [.097, .087, .098]);

  detail(upper, headShape, skin, [0, .625, -.021], [.156, .185, .151]);
  detail(upper, round, skin, [0, .558, -.074], [.233, .115, .182]);
  detail(upper, hairline, hair, [0, .665, .006], [.168, .171, .157]);
  detail(upper, round, hair, [0, .605, .092], [.244, .115, .133]);
  detail(upper, headShape, skin, [0, .607, -.170], [.037, .033, .038]);
  for (const side of [-1, 1]) {
    detail(upper, headShape, skin, [side * .151, .613, -.015], [.032, .049, .032]);
    detail(upper, round, visor, [side * .065, .648, -.151], [.047, .018, .018]);
  }
  detail(upper, round, accents, [-.166, .618, -.012], [.025, .039, .039]);

  const sling = new T.Group();
  sling.position.set(.067, .184, .176);
  sling.rotation.z = -.20;
  upper.add(sling);
  detail(sling, round, dark, [0, 0, .014], [.247, .290, .104]);
  detail(sling, round, canvas, [0, .030, .071], [.226, .173, .020]);
  detail(sling, round, accents, [0, -.017, .084], [.142, .022, .013]);
  detail(sling, round, cream, [.058, -.023, .095], [.037, .032, .018]);
  const strap = detail(upper, box, dark, [0, .204, -.170], [.046, .421, .027]);
  strap.rotation.z = -.68;
  const rearStrap = detail(upper, box, dark, [-.077, .251, .168], [.044, .38, .025]);
  rearStrap.rotation.z = .69;
  const scarf = new T.Group();
  upper.add(scarf);
  scarf.position.set(.093, .433, .10);
  detail(scarf, box, scarfInk, [0, 0, .17], [.125, .03, .34]);
  const scarfTail = new T.Group();
  scarfTail.position.z = .33;
  scarf.add(scarfTail);
  detail(scarfTail, box, scarfInk, [0, 0, .143], [.108, .025, .286]);
  detail(scarfTail, box, cream, [0, .016, .254], [.108, .014, .045]);

  const thighGeometry = new T.CylinderGeometry(.097, .117, 1, 9);
  const shinGeometry = new T.CylinderGeometry(.067, .096, 1, 9);
  const upperArmGeometry = new T.CylinderGeometry(.069, .093, 1, 9);
  const forearmGeometry = new T.CylinderGeometry(.054, .073, 1, 9);
  const limbs = [-1, 1].map(side => {
    const shoe = new T.Group();
    root.add(shoe);
    detail(shoe, round, dark, [0, .029, -.054], [.147, .097, .255]);
    detail(shoe, round, sole, [0, -.019, -.060], [.157, .043, .279]);
    detail(shoe, round, cream, [0, -.001, -.177], [.133, .041, .078]);
    detail(shoe, round, accents, [0, .016, .065], [.092, .038, .026]);
    const forearm = boneSegment(forearmGeometry, jacket, root);
    detail(forearm, round, seam, [0, .40, 0], [.132, .136, .128]);
    const shin = boneSegment(shinGeometry, pants, root);
    detail(shin, round, stitch, [side * .069, -.12, .012], [.02, .44, .036]);
    return {
      side, shoe, footTarget: V(0, .06, 0), handTarget: V(0, .8, 0), shoePitch: 0,
      thigh: boneSegment(thighGeometry, pants, root),
      shin,
      upperArm: boneSegment(upperArmGeometry, shell, root),
      forearm,
      glove: detail(root, round, dark, [0, 0, 0], [.087, .112, .092]),
      knee: detail(root, headShape, pants, [0, 0, 0], [.094, .096, .095]),
    };
  });

  let lastDistance = -20;
  let lastPose = 'idle';
  let transition = 0;
  function pose(model, clock, dt) {
    const type = model.pose;
    const snap = Math.abs(model.s - lastDistance) > 4;
    if (lastPose !== type) transition = .12;
    const weight = snap ? 1 : 1 - Math.exp(-dt * (transition > 0 ? 24 : 58));
    lastDistance = model.s;
    lastPose = type;
    transition = Math.max(0, transition - dt);
    const wall = model.wall?.side ?? 0;
    const gait = model.stride;
    const charge = model.landing;
    const strideWave = Math.sin(gait * Math.PI * 4);
    const breathing = type === 'idle' ? Math.sin(clock * 2.6) * .010 : 0;
    const crouch = type === 'idle' ? 1.17 + breathing : type === 'slide' ? .43 : type === 'vault' ? .70 : type === 'jump' ? .92 : .98 - charge * .18;
    hip.position.y = blend(hip.position.y, crouch + (type === 'run' ? strideWave * .032 : 0), weight);
    hip.rotation.y = blend(hip.rotation.y, -model.vx * .018, weight);
    hip.rotation.z = blend(hip.rotation.z, wall * -.20, weight);
    upper.position.copy(hip.position).add(V(0, .04, type === 'slide' ? .02 : -.065));
    const lean = type === 'idle' ? -.055 : type === 'slide' ? -.94 : type === 'vault' ? -.84 : -.18 - charge * .23;
    upper.rotation.x = blend(upper.rotation.x, lean, weight);
    upper.rotation.y = blend(upper.rotation.y, -model.vx * .022 + (type === 'run' ? Math.sin(gait * Math.PI * 2) * .10 : 0), weight);
    upper.rotation.z = blend(upper.rotation.z, wall * -.32 - model.vx * .024, weight);
    scarf.rotation.x = Math.sin(clock * (type === 'idle' ? 2 : 11)) * .16 + .11;
    scarf.rotation.y = -.16 + Math.sin(clock * 4) * .13;
    scarfTail.rotation.x = Math.sin(clock * 12 - 1.5) * .24;
    hip.updateMatrix();
    upper.updateMatrix();

    for (const limb of limbs) {
      const side = limb.side;
      const p = (gait + (side > 0 ? .5 : 0)) % 1;
      const swing = (p - .49) / .51;
      const stance = p < .49;
      const foot = V(side * .15, .052, stance ? -.56 + p / .49 * 1.21 : .65 - smooth(swing) * 1.21);
      if (!stance) foot.y += Math.sin(swing * Math.PI) * .31;
      const hand = V(side * .34, crouch + .19, Math.cos(p * Math.PI * 2) * .34 - .20);
      let shoePitch = stance ? 0 : Math.sin(swing * Math.PI) * -.32;
      if (type === 'idle') {
        foot.set(side * .17, .052, side * .115);
        hand.set(side * .30, crouch - .17, side * .08);
      } else if (type === 'jump') {
        const brace = T.MathUtils.clamp(-model.vy / 9, 0, 1);
        foot.set(side * .15, (side > 0 ? .41 : .30) - brace * .21,
          blend(side > 0 ? -.56 : .32, side * -.22, brace));
        hand.set(side * .45, crouch + .40 - brace * .32, -.42 + brace * .29);
        shoePitch = -.26 + brace * .24;
      } else if (type === 'vault') {
        const progress = Math.min(1, (model.s - model.vault.from) / (model.vault.to - model.vault.from));
        const tuck = Math.sin(Math.PI * progress);
        foot.set(side * .19, .20 + tuck * .35, side > 0 ? -.63 : -.28);
        hand.set(side * .40, .72, -.45);
        if (side > 0 && progress < .39) {
          const reach = Math.sin(Math.PI * progress / .39);
          hand.lerp(V(.36, model.vault.height + .79 - model.y, model.s - model.vault.obstacle.start), reach);
        }
        shoePitch = -.48;
      } else if (type === 'slide') {
        foot.set(side * .21, .12, side > 0 ? -.94 : -.55);
        hand.set(side * .43, .20, side > 0 ? -.41 : .31);
        shoePitch = -.33;
      } else if (type === 'wall') {
        const step = Math.cos(p * Math.PI * 2);
        foot.set(wall * (.40 + .18 * step), .25 + .20 * Math.sin(p * Math.PI * 2), -.15 + step * .46);
        hand.set(side === wall ? wall * .50 : side * .37, crouch + .16, -.20 + step * .31);
        shoePitch = wall * -.13;
      }
      const pelvis = V(side * .17, -.025, 0).applyMatrix4(hip.matrix);
      const shoulder = V(side * .28, .36, 0).applyMatrix4(upper.matrix);
      limb.footTarget.lerp(foot, weight);
      limb.handTarget.lerp(hand, weight);
      foot.copy(limb.footTarget);
      hand.copy(limb.handTarget);
      limb.shoePitch = blend(limb.shoePitch, shoePitch, weight);
      const knee = joint(pelvis, foot, FORWARD, .575, .57);
      const elbow = joint(shoulder, hand, V(side * .38, -.52, .72), .34, .34);
      placeBone(limb.thigh, pelvis, knee);
      placeBone(limb.shin, knee, foot);
      placeBone(limb.upperArm, shoulder, elbow);
      placeBone(limb.forearm, elbow, hand);
      limb.knee.position.copy(knee);
      limb.glove.position.copy(hand);
      limb.glove.quaternion.setFromUnitVectors(UP, V(0, 0, 0).subVectors(hand, elbow).normalize());
      limb.shoe.position.copy(foot);
      limb.shoe.rotation.set(limb.shoePitch, side * .08, wall * -.20);
    }
    root.position.set(model.x, model.y, -model.s);
    const yaw = model.phase === 'finished' ? -1.73 : -model.vx * .025;
    root.rotation.y = blend(root.rotation.y, yaw, snap ? 1 : 1 - Math.exp(-dt * 6));
  }

  return { root, pose };
}
