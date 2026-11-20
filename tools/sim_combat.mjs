// Balance simulator: runs fights through the real combat engine with a scripted player.
//   node tools/sim_combat.mjs [runs]
// Player skill = how often timed hits/blocks land PERFECT / GOOD / MID.
import { Battle } from '../src/combat/engine.js';

const RUNS = Number(process.argv[2] || 3000);
const SKILL = {
  sloppy: { atk: [0.05, 0.3], blk: [0.03, 0.22] },
  average: { atk: [0.3, 0.45], blk: [0.22, 0.43] },
  good: { atk: [0.6, 0.32], blk: [0.5, 0.38] },
};
const timing = (rng, [p, g]) => { const r = rng(); return r < p ? 'perfect' : r < p + g ? 'good' : 'mid'; };
const d6 = (rng) => 1 + Math.floor(rng() * 6);

function choose(b, m, rng) {
  const o = b.options(m);
  const party = b.party;
  const enemies = b.alive(b.enemies);
  const weakest = enemies.slice().sort((x, y) => x.hp - y.hp)[0];
  const boss = enemies.slice().sort((x, y) => y.hp - x.hp)[0];
  const down = party.filter((p) => p.hp <= 0);
  const low = b.alive(party).filter((p) => p.hp < p.maxHp * 0.35).sort((x, y) => x.hp - y.hp);
  const items = b.inv.beer + b.inv.bowl;
  const item = b.inv.bowl ? 'bowl' : 'beer';
  if (down.length && items) return { type: 'item', item, target: down[0] };
  if (low.length && items && rng() < 0.85) return { type: 'item', item: low[0].hp < 25 && b.inv.bowl ? 'bowl' : (b.inv.beer ? 'beer' : 'bowl'), target: low[0] };
  const sitting = enemies.some((e) => e.sitPending);
  if (sitting && m.hp < m.maxHp * 0.6 && rng() < 0.7) return { type: 'defend' };
  if (o.ult) return { type: 'move', slot: 'ult', target: m.id === 'skorn' ? boss : weakest };
  if (o.combos.length && rng() < 0.6) {
    const c = o.combos.find((x) => x.id === 'trio') || o.combos[0];
    return { type: 'combo', combo: c, target: weakest };
  }
  if (o.special && (m.id !== 'xylo' || rng() < 0.9)) return { type: 'move', slot: 'special', target: weakest };
  if (o.bonus) {
    if (m.id === 'lykor' && (party.length < 2 || b.hype > 0)) return { type: 'move', slot: 'main', target: weakest };
    return { type: 'move', slot: 'bonus', target: m.id === 'xylo' ? boss : weakest };
  }
  return { type: 'move', slot: 'main', target: weakest };
}

function run(fight, mods, skill, opts = {}) {
  let seed = Math.random();
  const rng = Math.random;
  const b = new Battle({ fight, mods, level: opts.level || 1, inv: opts.inv || {}, difficulty: opts.diff ?? 1, rng, used67: true });
  let guard = 0;
  while (!b.result() && guard++ < 400) {
    const { u, skip } = b.nextActor();
    if (skip || b.result()) continue;
    if (u.side === 'party') {
      const a = choose(b, u, rng);
      const move = a.type === 'move' ? u.P.moves[a.slot] : null;
      const timed = (move && move.timed) || a.type === 'combo';
      b.partyAct(u, a, { timing: timed ? timing(rng, SKILL[skill].atk) : null, roll: d6(rng), rolls: [d6(rng), d6(rng)] });
    } else if (u.side === 'enemy') {
      b.rollChaos();
      const it = b.enemyPlan(u);
      b.enemyResolve(u, it, it.kind === 'hit' ? timing(rng, SKILL[skill].blk) : null);
    } else b.allyAct(u);
  }
  const hpLeft = b.party.reduce((s, p) => s + p.hp, 0) / b.party.reduce((s, p) => s + p.maxHp, 0);
  return { win: b.result() === 'win', turns: b.stats.partyTurns, hpLeft, kos: b.stats.kos, grade: b.result() === 'win' ? b.grade().g : '-' };
}

const SETUPS = [
  ['goblins', {}, { level: 1 }, 'Goblins (Skorn solo, L1)'],
  ['dulbers', { tripping: 'party' }, { level: 1 }, 'Dulbers, party tripping (L1)'],
  ['dulbers', { tripping: 'skorn' }, { level: 1 }, 'Dulbers, Skorn tripping (L1)'],
  ['dulbers', { tripping: 'party' }, { level: 2 }, 'Dulbers, party tripping (L2, after goblins)'],
  ['giant', {}, { level: 2, inv: { beer: 3 } }, 'Giant (L2, 3 beezy)'],
  ['giant', { enraged: true }, { level: 2, inv: { beer: 3 } }, 'Giant ENRAGED (L2, 3 beezy)'],
  ['giant', { enemyTripping: true }, { level: 2 }, 'Giant tripping (L2, no items)'],
  ['giant', { allies: true }, { level: 1, inv: {} }, 'Giant + goblin allies (L1)'],
  ['giant', {}, { level: 3, inv: { beer: 3 } }, 'Giant (L3, 3 beezy)'],
];

const pct = (x) => `${Math.round(x * 100)}%`.padStart(4);
for (const [fight, mods, opts, label] of SETUPS) {
  const row = [label.padEnd(44)];
  for (const skill of ['sloppy', 'average', 'good']) {
    let w = 0, t = 0, hp = 0; const grades = {};
    for (let i = 0; i < RUNS; i++) {
      const r = run(fight, mods, skill, opts);
      if (r.win) { w += 1; hp += r.hpLeft; grades[r.grade] = (grades[r.grade] || 0) + 1; }
      t += r.turns;
    }
    const topG = Object.entries(grades).sort((a, b) => b[1] - a[1])[0];
    row.push(`${skill}: win ${pct(w / RUNS)} hp ${pct(w ? hp / w : 0)} t${(t / RUNS).toFixed(0).padStart(3)} ${topG ? topG[0] : '-'}`);
  }
  console.log(row.join(' | '));
}
