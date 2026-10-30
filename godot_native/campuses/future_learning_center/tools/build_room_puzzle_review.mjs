// Builds the room-by-room design review and checks coverage against real maps.
// Coverage is not proof of a playable level. Only the named toy models below
// are enumerated; placement, controllers and engine interactions remain pending.
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { readFile, writeFile } from 'node:fs/promises';

const campus = new URL('../', import.meta.url);
const read = name => readFile(new URL(name, campus), 'utf8');
const sha = value => createHash('sha256').update(value).digest('hex');
const raw = await read('design/room_puzzles.v2.json');
const design = JSON.parse(raw);
const sourceRaw = await read('design/transcript_sources.v1.json');
const sources = new Set(JSON.parse(sourceRaw).clips.map(clip => clip.id));
const floors = new Map();
const expected = new Set();
const sourceHashes = {};
let checks = 0;
function check(value, message) { checks++; assert.ok(value, message); }

for (const n of design.scope.floors) {
  const text = await read(`data/floor_${n}.json`);
  const floor = JSON.parse(text);
  floors.set(n, floor);
  sourceHashes[`data/floor_${n}.json`] = sha(text);
  for (const room of floor.rooms) expected.add(`${n}:${room.id}`);
}
const actual = new Set();
const emptyAnchorRooms = [];
let anchorReferences = 0;
const textFields = ['title', 'problem', 'objective', 'actions', 'experiment', 'counterexample', 'solution', 'completion', 'transfer', 'feedback', 'recovery', 'payoff'];
for (const puzzle of design.rooms) {
  check(!actual.has(puzzle.id), `Duplicate room puzzle: ${puzzle.id}`);
  actual.add(puzzle.id);
  check(puzzle.id === `${puzzle.floor}:${puzzle.room}`, `Unstable room ID: ${puzzle.id}`);
  check(expected.has(puzzle.id), `Unknown map room: ${puzzle.id}`);
  const floor = floors.get(puzzle.floor);
  check(floor.rooms.find(room => room.id === puzzle.room).name === puzzle.roomName, `${puzzle.id}: room name differs from map`);
  for (const field of textFields) check(typeof puzzle[field] === 'string' && puzzle[field].trim().length > 0, `${puzzle.id}: missing ${field}`);
  check(puzzle.hypotheses.length >= 2, `${puzzle.id}: needs competing explanations`);
  check(puzzle.evidence.length >= 3 && new Set(puzzle.evidence.map(item => item.owner)).size >= 2, `${puzzle.id}: evidence is not distributed`);
  check(puzzle.hints.length === 3, `${puzzle.id}: expected three optional hint tiers`);
  check(Number.isInteger(puzzle.difficulty?.entry) && puzzle.difficulty.entry >= 1 && puzzle.difficulty.entry <= 4, `${puzzle.id}: invalid entry difficulty`);
  check(Number.isInteger(puzzle.difficulty?.extension) && puzzle.difficulty.extension >= puzzle.difficulty.entry && puzzle.difficulty.extension <= 5, `${puzzle.id}: invalid extension difficulty`);
  check(puzzle.difficulty.teaching && puzzle.difficulty.readability && puzzle.difficulty.assessedBy === 'local_design_draft_not_playtested', `${puzzle.id}: missing teaching or unverified difficulty attribution`);
  check(puzzle.minutes.length === 2 && puzzle.minutes[0] > 0 && puzzle.minutes[1] >= puzzle.minutes[0], `${puzzle.id}: invalid pacing estimate`);
  check(['main', 'side'].includes(puzzle.role), `${puzzle.id}: missing role`);
  for (const id of puzzle.sources) check(sources.has(id), `${puzzle.id}: unknown transcript reference ${id}`);
  for (const id of puzzle.anchors) {
    const object = floor.objects.find(item => item.id === id);
    check(object && object.room === puzzle.room, `${puzzle.id}: object ${id} is not in this room`);
    anchorReferences++;
  }
  if (!puzzle.anchors.length) {
    check(typeof puzzle.placementNote === 'string' && puzzle.props.length > 0, `${puzzle.id}: an empty room needs an explicit new-prop/placement plan`);
    emptyAnchorRooms.push(puzzle.id);
  }
}
const missing = [...expected].filter(id => !actual.has(id));
check(missing.length === 0, `Missing room puzzles: ${missing.join(', ')}`);
const main = design.rooms.filter(room => room.role === 'main').map(room => room.id);
check(new Set(design.mainLearningRoute).size === main.length && main.every(id => design.mainLearningRoute.includes(id)), 'Suggested route must include each main puzzle exactly once');
check(design.status === 'design_only', 'Do not claim runtime delivery');
check(!design.scope.changeArchitecture && !design.scope.changeProductionChapter, 'Room coverage must preserve architecture and established chapter gates');
check(design.allRoomsRequiredForEnding === false, 'Optional room exploration must not silently become mandatory clearing');
check(design.interactionPrinciple?.primary === 'visible_in_scene_objects' && design.interactionPrinciple.defaultActionButtonRows === false && design.interactionPrinciple.defaultHotkeyPrompts === false, 'All rooms must preserve the user object-first interaction principle');
check(design.interactionPrinciple.touchLocomotion === 'analog_joystick_and_tap_to_approach', 'Touch locomotion must keep analog control and tap-to-approach');

const successors = new Map([...actual].map(id => [id, []]));
for (const link of design.links) {
  check(actual.has(link.from) && actual.has(link.to), 'Knowledge link refers to an unknown room');
  check(link.kind === 'suggested_knowledge_transfer', 'Do not turn design links into floor-access gates');
  successors.get(link.from).push(link.to);
}
const visited = new Set(), active = new Set();
function visit(id) {
  check(!active.has(id), `Circular learning prerequisite: ${id}`);
  if (visited.has(id)) return;
  active.add(id);
  for (const next of successors.get(id)) visit(next);
  active.delete(id); visited.add(id);
}
for (const id of actual) visit(id);

const toyResults = [];
function permutations(values) {
  if (!values.length) return [[]];
  const result = [];
  for (const item of new Set(values)) {
    const rest = values.slice(); rest.splice(rest.indexOf(item), 1);
    for (const tail of permutations(rest)) result.push([item, ...tail]);
  }
  return result;
}
function solarDistance(model, setup, sky, intensity = 1) {
  const panel = model.panels.find(item => item.id === setup.panel);
  const mass = model.baseMass + panel.mass;
  const alignment = Math.max(0, Math.cos((setup.tilt - sky.angle) * Math.PI / 180));
  let speed = 0, distance = 0;
  // Deliberately dimensionless design model; not a vehicle-physics claim.
  for (let i = 0; i < Math.round(model.duration / model.dt); i++) {
    const time = i * model.dt;
    const phase = sky.phases.find(([start, end]) => time >= start && time < end);
    const input = (phase?.[2] ?? 0) * intensity * panel.area * alignment;
    const force = input * 2.4 / setup.ratio * Math.max(0, 1 - speed / (setup.ratio * 4));
    const drag = .08 * mass + .012 * speed * speed;
    speed = Math.max(0, speed + (force - drag) / mass * model.dt);
    distance += speed * model.dt;
  }
  return distance;
}
for (const puzzle of design.rooms.filter(room => room.model)) {
  const model = puzzle.model;
  if (model.kind === 'solar_endurance') {
    const setups = model.panels.flatMap(panel => model.tilts.flatMap(tilt => model.ratios.map(ratio => ({ panel: panel.id, tilt, ratio }))));
    const scenarios = model.scenarios.map(sky => {
      const baselineDistance = solarDistance(model, model.baseline, sky);
      const ranked = setups.map(setup => ({ ...setup, distance: solarDistance(model, setup, sky) })).sort((a, b) => b.distance - a.distance);
      const winning = ranked.filter(row => row.distance > baselineDistance + .01);
      check(winning.length > 1, 'Solar-car challenge must accept several better builds');
      check(ranked.every(row => Number.isFinite(row.distance) && row.distance >= 0), 'Every solar run must remain finite');
      check(solarDistance(model, model.baseline, sky, 0) === 0, 'No light and no initial energy must not move a solar car');
      check(solarDistance(model, model.baseline, sky) === baselineDistance, 'The same sky and build must replay the same race');
      check(ranked[0].tilt === sky.angle, 'The visible sunlight direction must affect the preferred panel orientation');
      return { scenario: sky.id, enumeratedBuilds: ranked.length, baselineDistance, winningBuilds: winning.length, example: ranked[0] };
    });
    toyResults.push({ room: puzzle.id, kind: model.kind, scenarios, scope: model.units, doesNotValidateNativeRaceOrBalance: true });
  } else if (model.kind === 'three_beat_schedule') {
    const solutions = [];
    const count = model.beats ** model.tasks.length;
    for (let n = 0; n < count; n++) {
      let code = n;
      const beats = model.tasks.map(() => { const value = code % model.beats; code = Math.floor(code / model.beats); return value; });
      const byId = Object.fromEntries(model.tasks.map((task, i) => [task.id, beats[i]]));
      const dependencies = model.tasks.every(task => task.after.every(id => byId[id] < byId[task.id]));
      const exclusive = model.tasks.every((task, i) => model.tasks.every((other, j) => i === j || task.resource !== other.resource || beats[i] !== beats[j]));
      if (dependencies && exclusive) solutions.push(Object.fromEntries(Object.entries(byId).map(([id, beat]) => [id, beat + 1])));
    }
    check(solutions.length > 0, 'Three-beat rehearsal needs a valid schedule');
    check(solutions.some(solution => solution.capture_A === 1 && solution.assemble_B === 1 && solution.capture_B === 2 && solution.compare === 3), 'Documented rehearsal solution must be feasible');
    toyResults.push({ room: puzzle.id, kind: model.kind, enumeratedSchedules: count, solutions, doesNotValidateNpcExecution: true });
  } else if (model.kind === 'tray_water_balance') {
    const torque = (water, cups, support = 0) => -model.trayTare * support + cups.reduce((sum, cup, i) => sum + (model.glassTare + water[cup]) * (model.arms[i] - support), 0);
    const {water, cups} = model.witness;
    check(water.every((ml,i) => Math.abs(ml-model.targets[i]) <= model.band), 'Water witness must meet all four visible bands');
    check(Math.abs(torque(water,cups)) <= model.tolerance, 'Filled tray witness must balance');
    check(permutations([0,1,2,3]).every(order => Math.abs(torque(model.targets,order)) > model.tolerance), 'Exact centre fills must still need fine adjustment');
    check(model.capacity / model.flowMlPerSecond === 45, 'Slow full-glass time is 45 seconds');
    check(Math.abs(torque([65,85,115,150],[1,0,2,3],.25)) <= model.tolerance, 'Offset-support variant must remain feasible');
    toyResults.push({room:puzzle.id,kind:model.kind,status:'water_and_balance_witness_checked_not_runtime_acceptance'});
  } else if (model.kind === 'tray_balance') {
    const layouts = permutations(model.weights);
    const torque = weights => weights.reduce((sum, weight, i) => sum + weight * model.arms[i], 0);
    const solutions = layouts.filter(weights => Math.abs(torque(weights)) <= model.tolerance);
    check(solutions.length > 1, 'Tray should accept equivalent balanced arrangements');
    check(Math.abs(torque([1, 2, 2, 1])) <= model.tolerance, 'Documented tray example is unbalanced');
    check(Math.abs(torque([1, 1, 2, 2])) > model.tolerance, 'Equal cup counts alone must not pass');
    toyResults.push({ room: puzzle.id, kind: model.kind, enumeratedUniqueArrangements: layouts.length, solutions, doesNotValidateCarryingPhysics: true });
  } else if (model.kind === 'power_partition') {
    const solutions = [];
    const count = 2 ** model.active.length;
    for (let mask = 0; mask < count; mask++) {
      const assignment = model.active.map((_, i) => (mask >> i) & 1);
      const loads = [model.idle, model.active].map(values => values.reduce((totals, value, i) => { totals[assignment[i]] += value; return totals; }, [0, 0]));
      if (loads.every(totals => totals.every(load => load <= model.capacity))) solutions.push({ assignment, idleLoads: loads[0], activeLoads: loads[1] });
    }
    check(solutions.length === 4, 'Power example should allow both pairings and both bus labels');
    check(model.active[0] + model.active[1] > model.capacity && model.idle[0] + model.idle[1] <= model.capacity, 'Idle-only counterexample must actually fail at peak load');
    toyResults.push({ room: puzzle.id, kind: model.kind, enumeratedAssignments: count, solutions, scope: 'teaching model, not real electrical engineering' });
  } else throw new Error(`Unsupported toy model: ${model.kind}`);
}

const coverage = [...floors].map(([n, floor]) => {
  const puzzles = design.rooms.filter(room => room.floor === n);
  return { floor: n, mapRooms: floor.rooms.length, designedRooms: puzzles.length, main: puzzles.filter(room => room.role === 'main').length, side: puzzles.filter(room => room.role === 'side').length, estimatedPuzzleMinutes: [0, 1].map(i => puzzles.reduce((sum, room) => sum + room.minutes[i], 0)) };
});
const totalMinutes = [0, 1].map(i => coverage.reduce((sum, floor) => sum + floor.estimatedPuzzleMinutes[i], 0));
const mainMinutes = [0, 1].map(i => design.rooms.filter(room => room.role === 'main').reduce((sum, room) => sum + room.minutes[i], 0));
const proof = { schema: '755.flc.room-puzzle-review.v2', status: 'coverage_and_four_toy_models_checked_not_runtime_acceptance', generatedAt: new Date().toISOString(), baselineCommit: design.baselineCommit, designSha256: sha(raw), transcriptLedgerSha256: sha(sourceRaw), sourceHashes, checks, totalMapRooms: expected.size, totalDesignedRooms: actual.size, missingRooms: missing, coverage, anchorReferences, roomsWithOnlyProposedProps: emptyAnchorRooms, knowledgeLinks: design.links.length, toyResults, limits: ['Room and source coverage is checked; presence of a solution paragraph is not proof that the puzzle is solvable.', 'Only four additional numerical toy models are checked here; the earlier four-room slice has its own separate verifier.', 'The other room geometries, puzzle rules and authored targets still need executable blockouts.', 'No native runtime, object placement, NPC navigation, chapter gate, save migration, voice or human playtime is validated.'] };
const roleName = room => room.role === 'main' ? '主线候选' : '可选探索';
const anchor = room => `room-${room.floor}-${room.room.replaceAll('_', '-')}`;
const familyNames = { motion: '运输与路径', evidence: '记录与复现', optics: '光路与遮挡', assembly: '结构与装配', space: '空间与视角', rules: '规则推断', coordination: '共享条件与协作', balance: '平衡与搬运' };
let md = '# 每一层、每一个房间的谜题设计\n\n2026-10-29 · 房间覆盖版 v2 · 基于 Qwen 本地转录提炼的设计方法\n\n';
md += `**当前三层地图的 ${actual.size} 个房间/功能区各有一张谜题设计卡：二楼 8 个、三楼 10 个、四楼 7 个。** 每间围绕一个可独立观察、推断、操作并验证的问题展开。按钮次数、提示层数或换情境重复不另计关卡。茶水区也有轻谜题；X-Lab 小间也有专门设计。\n\n`;
md += '上一版四关串联保留为机制样本，已经不再代表整栋楼的设计范围。以下 8 间为建议连续体验的主线候选，17 间为随时可玩的探索支线。两类都有实际操作和完成结果；主线标记不是按编号锁门，当前设计也不强迫玩家清完全部房间。既有楼梯、电梯、门洞、灰色地面与二楼开放平台保留，卫生间不在当前可进入房间列表中。\n\n';
md += '**全楼交付是设计；二楼已有隔离原生小样。** 现有评审入口包含传动操作台、[双屏同步](../review/SIGNAL_SYNC_20261029.md)、[太阳能竞赛与机器人往返](../review/MOTION_PUZZLES_20261029.md)，另有独立浏览器遮光样本。其余本文玩法尚未实现，小样没有正式剧情或持久存档接入。所有新增实验盒、图卡、夹具、NPC 记录和对白均为虚构玩法提案，不宣称是实拍现场已有器材或真实人员活动。\n\n';
md += '**全楼交互准则：** [直接操纵场景物件](../review/OBJECT_INTERACTION_20261029.md)，用拖动、旋转、插拔、实体操纵杆和摇杆完成主要动作；禁止用屏幕按钮排或默认热键提示替代。提示和记录通过实物按需打开，触屏行走采用模拟摇杆与轻触前往。\n\n';
md += '## 全楼一览\n\n';
for (const item of coverage) {
  md += `### ${item.floor}F · ${design.floorThemes[item.floor]}\n\n${item.designedRooms}/${item.mapRooms} 个房间有谜题设计。\n\n| 房间 / 功能区 | 谜题 | 玩家主要做什么 | 路线定位 |\n| --- | --- | --- | --- |\n`;
  for (const room of design.rooms.filter(room => room.floor === item.floor)) md += `| ${room.roomName} | [${room.title}](#${anchor(room)}) | ${room.objective} | ${roleName(room)} |\n`;
  md += '\n';
}
md += '## 房间之间怎样联系\n\n';
md += '相近房间共享操作语言，下一间改变限制或需要解释的现象；不同功能区则使用对应的工作台、显示器、白板、柜子、大桌和沙发。每间可单独试验，其他房间的发现提供帮助。全楼以知识与装置状态串联，支线完成不构成统一门槛。\n\n';
md += '```mermaid\nflowchart TD\n    A[2F 电工区：传动] -.-> B[2F 机器人：往返]\n    B -.-> C[2F 平台：遮光与取景]\n    C -.-> D[3F 工作室3：对齐记录]\n    D -.-> E[3F 录播室：送料与遮挡顺序]\n    E -.-> F[3F X-Lab南区：折叠与携带]\n    F -.-> G[4F 协作区：两侧复现]\n    G -.-> H[4F 研讨间3：整机组合验证]\n    H -.-> I[2F 大厅：实际试演与收束]\n```\n\n';
md += '虚线表示建议体验，不是强制房门解锁顺序。通过仍由当前物件和真实试验裁决；不要求补读便笺或先失败几次。大厅收束复用已有规则，不另算第 26 个房间谜题。\n\n| 可选学习链 | 如何递进 |\n| --- | --- |\n';
md += '| 2F 研讨室 → 3F 工作室1 → X-Lab 小间 | 三视图约束 → 面对面参照 → 同一实体的双视向轮廓 |\n| 2F 机加工 → 3F 工作室4 → X-Lab 南区 → 4F 储藏室 | 保留加工基准 → 保留安装通道 → 保留折叠空间 → 保留取用退路 |\n| 2F 考拉 → 3F X-Lab 北区 → 4F 研讨间1 | 从操作反推规则 → 区分输入组合 → 主动构造反例 |\n| 3F 工作室2 → 4F 研讨间2 | 分开过口再连接 → 临时让位再交会 |\n| 3F 开放研讨 → 4F 专注区 → 流动工位 | 共享工具调度 → 同时工作的容量 → 工位改变后的关系保持 |\n| 3F 茶水区 | 2–3 分钟的低压力平衡与搬运；大桌和沙发成为玩法的一部分 |\n\n';
md += `### 节奏与完成后的变化\n\n主线候选八关的纯谜题时间暂估 ${mainMinutes[0]}–${mainMinutes[1]} 分钟；全部 25 间暂估 ${totalMinutes[0]}–${totalMinutes[1]} 分钟。均未计跨楼移动和自由探索，也未做真人测时。首次制作仍可先做一个切片，但设计覆盖已扩展到全部房间，不能再把其余房间标成“以后考虑”。\n\n`;
md += '主线结果服务于演示装置的运转、记录、运输与整机验证。支线结果优先改变本房间的可见状态：车跑通、盒能开合、同伴能喝到茶、柜内器材能取出。可在探索页回看完成过的作品，不向常驻任务栏塞入 25 项清单，也不把所有支线都绑定新背包物品。\n\n';
md += '## 逐间设计卡\n\n每张卡都包含问题、竞争解释、三处线索、可区分解释的实验、反例、参考解、完成条件与变式。“制作者/试用者”是虚构记录作者的角色区分，不表示每间必须新增两名 NPC。可以由三名主要同学在不同时间留下记录；读到这些记录仍是可选帮助。\n\n';
md += '[提示规则与全楼难度曲线](GUIDANCE_AND_DIFFICULTY_20261029.md) · [待发送 Argon 审阅包](ARGON_REVIEW_PACKET_20261029.md)。以下等级是本地作者预测，待 Argon 审阅与真人试玩；提示须主动请求，把手和接口在场景可见，详细说明按需出现。\n\n';
for (const room of design.rooms) {
  const objects = room.anchors.map(id => floors.get(room.floor).objects.find(item => item.id === id));
  md += `<a id="${anchor(room)}"></a>\n\n### ${room.floor}F · ${room.roomName}：${room.title}\n\n`;
  md += `${roleName(room)} · ${familyNames[room.family]} · 目标体验 ${room.minutes[0]}–${room.minutes[1]} 分钟（待试玩）\n\n`;
  if (room.implementation) md += `**实现状态：** [隔离原生小样](../review/${room.implementation.review ?? 'SIGNAL_SYNC_20261029.md'})，可走近工作台操作；没有正式剧情或持久存档接入。\n\n`;
  md += `**难度：** 入门 ${room.difficulty.entry} / 进阶 ${room.difficulty.extension}（5 级制，未试玩）。\n\n**教学顺序：** ${room.difficulty.teaching}\n\n**可读性要求：** ${room.difficulty.readability}\n\n`;
  md += `**看见的问题：** ${room.problem}\n\n**玩家目标：** ${room.objective}\n\n**实际操作：** ${room.actions}\n\n`;
  md += `**已有对象：** ${objects.length ? objects.map(item => `${item.name}（\`${item.id}\`）`).join('、') : '当前数据未摆独立对象。'}\n\n**新增提案：** ${room.props.join('、')}。${room.placementNote ?? '新增物件在既有对象或房间内安排；源对象引用不代表已完成可达性和尺寸验收。'}\n\n`;
  md += '**三处线索：**\n\n';
  for (const evidence of room.evidence) md += `- ${evidence.owner}：${evidence.text}。\n`;
  md += `\n**两种解释：** ${room.hypotheses.map(text => `“${text}”`).join(' / ')}。\n\n**区分实验：** ${room.experiment}\n\n**反例：** ${room.counterexample}\n\n`;
  md += `**作者参考解：** ${room.solution}\n\n**完成条件：** ${room.completion}\n\n**换情境应用：** ${room.transfer}\n\n`;
  md += `**现场反馈：** ${room.feedback}\n\n**三层自选提示：** ${room.hints.join(' → ')}\n\n**撤回与恢复：** ${room.recovery}\n\n**解完后的房间：** ${room.payoff}\n\n`;
  if (room.visualBeats) {
    md += '**可见演出顺序：**\n\n';
    for (const [index, beat] of room.visualBeats.entries()) md += `${index + 1}. ${beat}\n`;
    md += '\n';
  }
  md += `**转录方法依据：** [${room.sources.join('、')}](TRANSCRIPT_EVIDENCE_20261029.md)。具体房间谜题是本项目原创提案，引用的是设计方法，不是原视频的精确关卡。${room.legacy ? ` 原四关机制样本编号：\`${room.legacy}\`。` : ''}\n\n`;
}
md += '## 空间与实现共同要求\n\n';
md += '1. 先保留房间轮廓、门洞、上下楼配对和脚底可走区域，再为谜题摆位。画面遮挡、人物碰撞、物件扫掠、光路与取景分别计算并共用物体变换。不能为了出题临时封住门，或让人物站上电梯顶、栏杆与中庭挑空。\n';
md += '2. 不把房间改成抽象棋盘大厅。大多数新增机构安放在既有桌面、柜内或局部装置中，房间里仍能看到同一机构的状态。近景保持同向投影和等比放大，物件独立透明，不用换一张完成图蒙混。\n';
md += '3. 每间保留一个清楚的主要操作面和退出动作；不让玩家为开始操作猜热区。鼠标拖动、键盘移动/确认、触摸点选再放置访问同一模型。声效与配音不承载唯一线索。\n';
md += '4. 状态字段暂只是设计占位：当前配置、配置版本、本次试验与房间验证结果。正式接入现有控制器/存档时再定义 schema、迁移与已完成事实不倒退；观察、NPC 动画、语音播完、翻页均不能独立推进。\n';
md += '5. 主要 NPC 的拿取、观察、操作与走路是实际场景行为，使用同一地面和障碍数据；角色无路可走时不穿桌，不把核心解法绑在 NPC 恰好站到某一像素。支线记录不要求为每间屋新增人物。\n';
md += '6. 先验房间自己的正确解、合理错解、可逆性与迁移案例，再验与相邻房间的关系。X-Lab 小间是新对象摆位的明确待办；其余已存在对象也不能由名称推断可达性。\n\n';
md += '## 本轮验证与下一步\n\n';
md += `- 房间覆盖与文档结构检查：${checks} 项通过；${actual.size}/${expected.size} 房间有完整设计卡，${anchorReferences} 个已有对象引用与楼层/房间匹配，${design.links.length} 条学习联系无循环。\n`;
md += '- 新增四组抽象规则已核验：太阳能小车同日照下的多种有效改装、研讨区三拍调度、茶水区托盘平衡、专注区双支路负载分组。小车数值为无量纲设计样例，不是真实车辆预测或最终平衡。其余房间的几何、具体图案与规则还须白模验证，不能因为写了参考解就宣称全部可玩。\n';
md += '- 上一版四关的有限模型报告独立保留，不把它的检查数加成全楼运行时通过率。双屏同步的独立 Godot 小样在单独的实现记录中验收；本报告不验证运行时、浏览器、NPC、正式存档或真人体验。\n\n';
md += '[房间结构化设计](room_puzzles.v2.json) · [本轮覆盖与样例规则核验](room_puzzle_review.v2.json) · [原四关机制详稿](README.md) · [转录来源与时间段](TRANSCRIPT_EVIDENCE_20261029.md)\n\n';
md += '生成与核验：\n\n```sh\nnode godot_native/campuses/future_learning_center/tools/build_room_puzzle_review.mjs --write\n```\n\n本页由 `room_puzzles.v2.json` 生成。先修改结构化设计再运行命令，避免房间表、详情与核验数量分叉。\n';

if (process.argv.includes('--write')) {
  await writeFile(new URL('design/ROOM_PUZZLES_20261029.md', campus), md);
  await writeFile(new URL('design/room_puzzle_review.v2.json', campus), JSON.stringify(proof, null, 2) + '\n');
}
console.log(JSON.stringify({ status: proof.status, checks, coverage, main: main.length, side: actual.size - main.length, anchorReferences, missingRooms: missing, roomsNeedingNewProps: emptyAnchorRooms, toyModels: toyResults.map(item => ({ room: item.room, kind: item.kind, solutions: item.solutions?.length ?? item.validTriggerInterval })), generated: process.argv.includes('--write') }, null, 2));
