// Combat rules engine — pure logic, no Phaser. CombatScene drives it and animates the events it
// returns; tools/sim_combat.mjs runs thousands of fights through it in Node for balancing.
//
// Turn order is a speed timeline (like FFX): every unit has `next`, the time of its next turn.
// Whoever has the lowest `next` acts, then waits 100/spd before acting again. Faster = more turns.
//
// Flow per turn:
//   const { u, events, skip } = battle.nextActor();          // start-of-turn stuff (burns, skips)
//   party:  battle.partyAct(u, action, { timing, roll, rolls, accept67 })   → events
//   enemy:  battle.rollChaos() → events;  intent = battle.enemyPlan(u);
//           battle.enemyResolve(u, intent, blockTiming)       → events
//   ally:   battle.allyAct(u)                                 → events
//
// Events are plain objects ({ t: 'dmg', u, amt, hp, text, ... }) the scene plays in order.
import {
  PARTY, COMBOS, ITEMS, FIGHTS, DIFFICULTY, GRADES, BANTER, CHAOS, THROWABLES, TRIP_MISFIRES, BUZZED_MISFIRES,
} from '../data/combat.js';

const BASE = 100;
export const TIMING = { perfect: 1.5, good: 1.2, mid: 0.9 };
export const BLOCK = { perfect: 0.35, good: 0.7, mid: 1 };
const DURATION = ['mogged', 'lorepill', 'downbad', 'cooked', 'gouged', 'locked', 'copium'];

export class Battle {
  constructor({ fight, mods = {}, level = 1, inv = {}, difficulty = 1, rng = Math.random, used67 = false }) {
    this.key = fight;
    this.def = FIGHTS[fight];
    this.mods = mods;
    this.rng = rng;
    this.diff = DIFFICULTY[difficulty] || DIFFICULTY[1];
    this.level = level;
    this.lvl = 1 + 0.1 * (level - 1);
    this.inv = { beer: inv.beer || 0, bowl: inv.bowl || 0 };
    this.used67 = used67;
    this.hype = 0;
    this.now = 0;
    this.chaosUsed = false;
    this.emergencyGiven = false;
    this.stats = { partyTurns: 0, dmgTaken: 0, kos: 0, items: 0, timed: 0, perfects: 0 };

    const ids = mods.party || this.def.party;
    this.party = ids.map((id, i) => {
      const P = PARTY[id];
      const maxHp = Math.round(P.hp * this.lvl);
      return {
        side: 'party', id, key: id, P, name: P.name, maxHp, hp: maxHp, spd: P.spd, order: i,
        meter: 0, cds: { special: 0, bonus: 0 }, st: {}, defending: false,
        tripping: mods.tripping === 'party' || (mods.tripping === 'skorn' && id === 'skorn'),
        lowWarned: false,
      };
    });

    const hpMul = (mods.enraged ? 1.15 : 1) * this.diff.hp * (ids.length < this.def.party.length ? 0.75 : 1);
    this.enemies = this.def.enemies.map((E, i) => {
      const e = {
        side: 'enemy', key: `e${i}`, E, name: E.name, tag: E.tag, ai: E.ai, boss: !!E.boss, order: 10 + i,
        maxHp: Math.round(E.hp * hpMul), spd: E.spd, st: {}, turn: 0, phase: 1,
        secondWind: !!E.secondWind,
      };
      e.hp = e.maxHp;
      if (mods.enraged) e.tag = '(ENRAGED)';
      if (mods.enemyTripping) e.tag = '(Tripping)';
      return e;
    });

    this.allies = mods.allies ? [{ side: 'ally', key: 'ally', name: 'Goblin Backup', hp: 1, maxHp: 1, spd: 9, st: {}, order: 20 }] : [];

    // Opening positions: the party usually gets the first swing
    this.party.forEach((u, i) => { u.next = this.delay(u) * (0.35 + i * 0.02); });
    this.enemies.forEach((u, i) => { u.next = this.delay(u) * (0.7 + i * 0.12); });
    this.allies.forEach((u) => { u.next = this.delay(u) * 0.9; });
  }

  // ------------------------------------------------------------------ helpers
  delay(u) { return BASE / (u.spd * (u.phase === 2 && u.ai === 'giant' ? 1.25 : 1)); }
  alive(list) { return list.filter((x) => x.hp > 0); }
  pick(arr) { return arr[Math.floor(this.rng() * arr.length)]; }
  units() { return [...this.alive(this.party), ...this.alive(this.enemies), ...(this.alive(this.enemies).length ? this.allies : [])]; }
  result() {
    if (!this.alive(this.enemies).length) return 'win';
    if (!this.alive(this.party).length) return 'lose';
    return null;
  }

  // Upcoming turns for the turn-order bar (doesn't change anything)
  preview(n = 8) {
    const sim = this.units().map((u) => ({ u, next: u.next, skips: (u.st.stun ? 1 : 0) + (u.st.charm ? 1 : 0) + (u.st.flattened ? 1 : 0) }));
    const out = [];
    while (out.length < n && sim.length) {
      sim.sort((a, b) => a.next - b.next || a.u.order - b.u.order);
      const s = sim[0];
      out.push({ u: s.u, skip: s.skips > 0 });
      if (s.skips > 0) s.skips -= 1;
      s.next += this.delay(s.u);
    }
    return out;
  }

  bark(u, kind, chance = 0.35) {
    const who = u.id || u.ai;
    const lines = BANTER[who] && BANTER[who][kind];
    if (!lines || this.rng() > chance) return [];
    return [{ t: 'bark', u, line: this.pick(lines) }];
  }

  addMeter(m, amt) {
    if (m.side !== 'party' || m.hp <= 0 || amt <= 0) return [];
    const before = m.meter;
    m.meter = Math.min(100, m.meter + Math.round(amt));
    return before < 100 && m.meter >= 100 ? [{ t: 'meterFull', u: m }] : [];
  }

  // ------------------------------------------------------------------ turn start
  nextActor() {
    const list = this.units().sort((a, b) => a.next - b.next || a.order - b.order);
    const u = list[0];
    this.now = u.next;
    u.next += this.delay(u);
    const ev = [];
    const had = { ...u.st };
    DURATION.forEach((k) => { if (u.st[k]) { u.st[k] -= 1; if (u.st[k] <= 0) delete u.st[k]; } });

    if (u.side === 'party') {
      this.stats.partyTurns += 1;
      u.defending = false;
      u.cds.special = Math.max(0, u.cds.special - 1);
      u.cds.bonus = Math.max(0, u.cds.bonus - 1);
      if (u.st.flattened) {
        delete u.st.flattened;
        ev.push({ t: 'say', text: `${u.name} is still flattened. Can't move.`, sound: 'miss' });
        return { u, events: ev, skip: true };
      }
      return { u, events: ev, skip: false };
    }
    if (u.side === 'ally') return { u, events: ev, skip: false };

    // Enemy: burns and copium first
    if (had.cooked) {
      ev.push(...this.damageEnemy(null, u, 6, { text: `${u.name} is Cooked. The fire is still going.`, sound: 'fire', raw: true }));
      if (u.hp <= 0) return { u, events: ev, skip: true };
    }
    if (had.copium && u.st.copium !== undefined) {
      const h = Math.min(8, u.maxHp - u.hp);
      u.hp += h;
      ev.push({ t: 'heal', u, amt: h, hp: u.hp, text: `${u.name} is on Copium. (+${h})` });
    }
    // Telegraph counters: CC'd while winding up a sit or a snack
    const cc = u.st.stun ? 'stun' : u.st.charm ? 'charm' : null;
    if (cc && (u.sitPending || u.eatPending)) {
      delete u.st[cc];
      if (u.sitPending) {
        u.sitPending = false;
        ev.push({ t: 'tex', u, tex: u.E.tex });
        ev.push(...this.damageEnemy(null, u, 35, { text: `${u.name} loses his balance and sits on his OWN FOOT!`, sound: 'sitImpact', raw: true, shake: true }));
      } else {
        u.eatPending = false;
        ev.push({ t: 'say', text: `${u.name} drops his Chipotle Bowl. It's over for the bowl.`, sound: 'miss' });
      }
      return { u, events: ev, skip: true };
    }
    if (u.st.stun) {
      delete u.st.stun;
      ev.push({ t: 'say', text: `${u.name} is being sat on and can't move.`, sound: 'miss' });
      return { u, events: ev.concat(this.lockIn(u)), skip: true };
    }
    if (u.st.charm) {
      delete u.st.charm;
      const others = this.alive(this.enemies).filter((x) => x !== u);
      if (others.length) {
        const t = this.pick(others);
        ev.push(...this.damageEnemy(null, t, 6, { text: `${u.name} is GLAZED. He bonks ${t.name} to impress Lykor.`, sound: 'bonk', raw: true }));
      } else {
        ev.push({ t: 'say', text: `${u.name} is too busy staring at Lykor's hair.`, sound: 'sparkle' });
      }
      return { u, events: ev.concat(this.lockIn(u)), skip: true };
    }
    if (had.lorepill && this.rng() < 0.5) {
      ev.push({ t: 'say', text: `${u.name} is Lore-pilled and dozes off mid-turn. Zzz.`, sound: 'miss' });
      return { u, events: ev.concat(this.lockIn(u)), skip: true };
    }
    return { u, events: ev, skip: false };
  }

  // Bosses get Locked In after losing a turn, so you can't chain charm/stun forever
  lockIn(u) {
    if (!u.boss || u.hp <= 0) return [];
    u.st.locked = 3;
    return [{ t: 'status', u, name: 'locked', text: `${u.name} is LOCKED IN. Can't be charmed, stunned or Lore-pilled for a bit.` }];
  }

  canCC(e) { return !e.st.locked || e.sitPending || e.eatPending; }

  applyCC(e, kind, turns = 1) {
    if (e.hp <= 0) return [];
    if (!this.canCC(e)) return [{ t: 'say', text: `${e.name} is Locked In. Didn't work.`, sound: 'miss', ms: 900 }];
    e.st[kind] = Math.max(e.st[kind] || 0, turns);
    const txt = {
      charm: `${e.name} is charmed by the hair. They might just… stand there.`,
      stun: `${e.name} is SAT ON. They lose their next turn.`,
      lorepill: `${e.name} is LORE-PILLED. Getting sleepy…`,
    }[kind];
    return [{ t: 'status', u: e, name: kind, text: txt }];
  }

  applyStatus(e, name, turns, text) {
    if (e.hp <= 0) return [];
    e.st[name] = Math.max(e.st[name] || 0, turns);
    return [{ t: 'status', u: e, name, text }];
  }

  // ------------------------------------------------------------------ party
  options(m) {
    const combos = COMBOS.filter((c) => c.who.includes(m.id) && c.who.every((id) => {
      const p = this.party.find((x) => x.id === id);
      return p && p.hp > 0 && p.meter >= c.cost;
    }) && this.party.length > 1);
    return {
      special: m.cds.special === 0,
      bonus: m.cds.bonus === 0,
      ult: m.meter >= 100,
      combos,
      items: this.inv.beer + this.inv.bowl > 0,
    };
  }

  partyAct(m, a, o = {}) {
    const ev = [];
    if (a.type === 'defend') {
      m.defending = true;
      m.cds.special = Math.max(0, m.cds.special - 1);
      m.cds.bonus = Math.max(0, m.cds.bonus - 1);
      ev.push({ t: 'say', text: `${m.name} braces. (Defending: half damage, enemies aim at ${m.name}, cooldowns tick faster.)`, sound: 'throw', ms: 1300 });
      ev.push(...this.addMeter(m, 12));
      return ev;
    }
    if (a.type === 'item') return this.useItem(m, a.item, a.target);

    // Misfires: midtocy trip or beezy buzz
    const buzzed = m.st.buzzed;
    delete m.st.buzzed;
    if (a.type === 'move' && a.slot !== 'ult') {
      if (m.tripping && this.rng() < 0.22) return [{ t: 'misfire', u: m, text: this.pick(TRIP_MISFIRES[m.id]), sound: 'miss', ms: 1500 }];
      if (buzzed && this.rng() < 0.25) return [{ t: 'misfire', u: m, text: this.pick(BUZZED_MISFIRES[m.id]), sound: 'miss', ms: 1500 }];
    }
    const crit = m.tripping && this.rng() < 0.2 ? 2 : 1;
    if (crit > 1) ev.push({ t: 'float', u: m, text: 'TWEAK CRIT!', color: '#ff6bd5', sound: 'crit' });
    if (o.timing) { this.stats.timed += 1; if (o.timing === 'perfect') this.stats.perfects += 1; }
    const hitOpts = { attacker: m, timing: o.timing, crit };

    if (a.type === 'combo') {
      ev.push(...this.doCombo(m, a.combo, a.target, hitOpts));
    } else {
      const move = m.P.moves[a.slot];
      if (move.cd) m.cds[a.slot] = move.cd + (a.slot === 'special' && m.st.bricked ? 1 : 0);
      if (a.slot === 'special') delete m.st.bricked;
      if (a.slot === 'ult') { m.meter = 0; ev.push(...this.bark(m, 'ult', 1)); }
      ev.push(...this.doMove(m, move, a.target, hitOpts, o));
    }
    if (this.hype > 0 && !(a.type === 'move' && m.P.moves[a.slot].kind === 'buff')) this.hype -= 1;
    if (o.timing === 'perfect') ev.push(...this.bark(m, 'perfect', 0.3));
    return ev;
  }

  doMove(m, move, t, h, o) {
    const ev = [];
    switch (move.kind) {
      case 'hit': {
        ev.push(...this.damageEnemy(m, t, move.power, { ...h, text: `${m.name} uses ${move.name} on ${t.name}!`, sound: { slap: 'slap', blast: 'impactMagic', lore: 'impactMagic', fire: 'fire', mog: 'hit', sparkle: 'hit' }[move.fx] }));
        if (t.hp <= 0) break;
        if (move.charm && this.rng() < move.charm + (h.timing === 'perfect' ? 0.15 : 0)) ev.push(...this.applyCC(t, 'charm'));
        if (move.mogged) ev.push(...this.applyStatus(t, 'mogged', move.mogged, `${t.name} is MOGGED. Insecure now. Takes 25% more damage.`));
        if (move.lorepill && (h.timing === 'perfect' || this.rng() < move.lorepill)) ev.push(...this.applyCC(t, 'lorepill', 2));
        if (move.cooked) ev.push(...this.applyStatus(t, 'cooked', move.cooked, `${t.name} is COOKED. On fire for a few turns.`));
        break;
      }
      case 'throw': {
        const thing = this.pick(THROWABLES);
        ev.push({ t: 'throwThing', u: m, target: t, thing });
        ev.push(...this.damageEnemy(m, t, move.power, { ...h, text: `${m.name} throws ${thing} at ${t.name}!` }));
        if (t.hp > 0 && this.rng() < move.downbad) ev.push(...this.applyStatus(t, 'downbad', 2, `${t.name} is DOWN BAD. Getting hit with ${thing} was humbling. Deals half damage.`));
        break;
      }
      case 'crashout': {
        const r = o.roll;
        if (r === 7) { this.used67 = true; ev.push({ t: 'sixSeven' }); this.alive(this.enemies).forEach((e) => ev.push(...this.damageEnemy(m, e, 67, { raw: true, text: `The party does the 6-7 on ${e.name}!` }))); break; }
        if (r === 1) {
          const d = Math.min(10, m.hp - 1);
          m.hp -= d;
          ev.push({ t: 'selfHit', u: m, amt: d, hp: m.hp, text: `A 1. ${m.name} crashes out on HIMSELF. (-${d})` });
          break;
        }
        const power = { 2: 18, 3: 18, 4: 30, 5: 30, 6: 40 }[r];
        ev.push(...this.damageEnemy(m, t, power, { ...h, text: `${m.name} crashes out on ${t.name}!` }));
        break;
      }
      case 'buff':
        this.hype = 3;
        ev.push({ t: 'hype', u: m, text: `${m.name} screams "on some type shi"! The party is HYPED (next 3 attacks hit 50% harder).` });
        ev.push(...this.addMeter(m, 15));
        break;
      case 'fullcrash': {
        const [a, b] = o.rolls;
        let mult = 1;
        if (a === 6 && b === 6 && o.accept67) {
          this.used67 = true;
          ev.push({ t: 'sixSeven' });
          this.alive(this.enemies).forEach((e) => ev.push(...this.damageEnemy(m, e, 67, { raw: true, text: `The party does the 6-7 on ${e.name}!` })));
        } else if (a === 6 && b === 6) { mult = 2; ev.push({ t: 'say', text: 'DOUBLE SIXES. DOUBLE DAMAGE.', sound: 'crit', ms: 1000 }); }
        if (a === 1 && b === 1) {
          const d = Math.min(15, m.hp - 1);
          m.hp -= d;
          ev.push({ t: 'selfHit', u: m, amt: d, hp: m.hp, text: `SNAKE EYES. ${m.name} crashes out so hard he hurts himself. (-${d})` });
        }
        if (t.hp > 0) ev.push(...this.damageEnemy(m, t, 7 * (a + b) * mult, { ...h, text: `${m.name} FULLY crashes out on ${t.name}! (${a} + ${b})` }));
        if (t.hp > 0) {
          const strip = ['hyped', 'shield', 'copium', 'locked'].filter((k) => t.st[k]);
          strip.forEach((k) => delete t.st[k]);
          ev.push({ t: 'status', u: t, name: 'humbled', text: `${t.name} is HUMBLED.${strip.length ? ' Their buffs are gone.' : ''}` });
        }
        break;
      }
      case 'mogsupreme':
        ev.push({ t: 'mogSupreme', u: m });
        this.alive(this.enemies).forEach((e) => {
          ev.push(...this.damageEnemy(m, e, move.power, { ...h, text: `MOG SUPREME hits ${e.name}!`, sound: 'mog' }));
          if (e.hp > 0) { e.st.mogged = 3; e.st.blind = 1; ev.push({ t: 'status', u: e, name: 'mogged', text: `${e.name} is MOGGED and BLINDED.` }); }
        });
        break;
      case 'chudout': {
        ev.push({ t: 'chudOut', u: m, target: t });
        const locked = !this.canCC(t);
        ev.push(...this.damageEnemy(m, t, move.power + (locked ? 15 : 0), { ...h, text: `${m.name} CHUDS OUT and sits on ${t.name}!`, sound: 'chudThud', shake: true }));
        if (t.hp > 0) {
          if (locked) ev.push({ t: 'say', text: `${t.name} is Locked In, so he doesn't lose a turn. But it hurt extra.`, ms: 1200 });
          else ev.push(...this.applyCC(t, 'stun'));
        }
        break;
      }
      default: break;
    }
    return ev;
  }

  doCombo(m, c, t, h) {
    const ev = [];
    const members = c.who.map((id) => this.party.find((x) => x.id === id));
    members.forEach((p) => { p.meter -= c.cost; if (p !== m) p.next += this.delay(p) * 0.5; });
    ev.push({ t: 'combo', combo: c, members, target: t });
    if (c.id === 'loreslap') {
      for (let i = 0; i < c.hits && t.hp > 0; i++) ev.push(...this.damageEnemy(m, t, c.power, { ...h, quick: true, text: i === 0 ? 'Xylo reads. Skorn slaps on every comma.' : null, sound: 'slap' }));
      if (t.hp > 0) ev.push(...this.applyCC(t, 'lorepill', c.lorepill));
    } else if (c.aoe) {
      this.alive(this.enemies).forEach((e) => {
        ev.push(...this.damageEnemy(m, e, c.power, { ...h, text: `${c.name} hits ${e.name}!`, sound: 'fire' }));
        if (e.hp > 0 && c.cooked) e.st.cooked = c.cooked;
      });
      ev.push({ t: 'say', text: 'Everything is COOKED. Lykor\'s hair is fine. Somehow.', ms: 1000 });
    } else {
      ev.push(...this.damageEnemy(m, t, c.power, { ...h, text: `${c.name}!`, shake: true }));
      if (t.hp > 0 && c.mogged) ev.push(...this.applyStatus(t, 'mogged', c.mogged, `${t.name} is MOGGED.`));
    }
    if (c.heal) {
      this.alive(this.party).forEach((p) => {
        const amt = Math.min(c.heal, p.maxHp - p.hp);
        p.hp += amt;
        ev.push({ t: 'heal', u: p, amt, hp: p.hp, quick: true });
      });
    }
    return ev;
  }

  useItem(m, key, t) {
    const it = ITEMS[key];
    const ev = [];
    this.inv[key] -= 1;
    this.stats.items += 1;
    ev.push({ t: 'item', u: m, target: t, item: key });
    let amt = it.heal;
    if (t.st.gouged) amt = Math.round(amt / 2);
    if (t.hp <= 0) {
      t.hp = Math.min(t.maxHp, amt);
      t.meter = 0;
      t.st = {};
      t.next = this.now + this.delay(t) * 0.6;
      ev.push({ t: 'revive', u: t, hp: t.hp, text: `${t.name} is back! (${t.hp} ${t.P.hpLabel})` });
    } else {
      const healed = Math.min(amt, t.maxHp - t.hp);
      t.hp += healed;
      ev.push({ t: 'heal', u: t, amt: healed, hp: t.hp, text: `${t.name} has a ${it.name}. +${healed} ${t.P.hpLabel}.${t.st.gouged ? ' (Price Gouged: half healing)' : ''}` });
    }
    if (key === 'beer') { t.st.buzzed = 1; ev.push({ t: 'status', u: t, name: 'buzzed', text: `${t.name} is a little Buzzed.`, quiet: true }); }
    return ev;
  }

  // Party → enemy damage
  damageEnemy(m, e, base, o = {}) {
    if (e.hp <= 0) return [];
    let dmg = base;
    let label = null;
    if (!o.raw) {
      dmg *= this.lvl * (this.hype > 0 ? 1.5 : 1) * (o.crit || 1);
      if (o.timing) { dmg *= TIMING[o.timing]; label = { perfect: 'PERFECT!', good: 'GOOD', mid: 'MID' }[o.timing]; }
    }
    if (e.st.mogged) dmg *= 1.25;
    dmg = Math.max(1, Math.round(dmg));
    const ev = [];
    if (e.st.shield) {
      const ab = Math.min(e.st.shield, dmg);
      e.st.shield -= ab;
      dmg -= ab;
      if (e.st.shield <= 0) delete e.st.shield;
      ev.push({ t: 'say', text: `The Aura Shield absorbs ${ab}.${e.st.shield ? '' : ' It shatters!'}`, sound: 'sparkle', ms: 800 });
    }
    e.hp = Math.max(0, e.hp - dmg);
    ev.push({ t: 'dmg', u: e, amt: dmg, hp: e.hp, text: o.text ? `${o.text} (-${dmg})` : null, sound: o.sound || 'hit', label, shake: o.shake, quick: o.quick });
    if (m) ev.push(...this.addMeter(m, Math.min(15, dmg / 3) + (o.timing === 'perfect' ? 8 : o.timing === 'good' ? 4 : 0)));
    if (e.st.copium && dmg >= 25) { delete e.st.copium; ev.push({ t: 'say', text: 'That broke his Copium.', ms: 800 }); }
    if (e.eatPending && dmg >= 30 && e.hp > 0) { e.eatPending = false; ev.push({ t: 'say', text: `${e.name} drops his Chipotle Bowl! No snack for him.`, sound: 'miss', ms: 1100 }); }
    if (e.hp <= 0) {
      if (e.secondWind) {
        e.secondWind = false;
        e.hp = 10;
        ev.push({ t: 'down', u: e, fake: true });
        ev.push({ t: 'revive', u: e, hp: e.hp, text: `${e.name} gets back up. "I NEED THIS JOB!" (Second Wind)` });
      } else {
        e.sitPending = false; e.eatPending = false; e.st = {};
        ev.push({ t: 'down', u: e });
      }
    } else if (e.phase === 1 && e.boss && e.hp <= e.maxHp * 0.5) {
      e.phasePending = true;
    }
    return ev;
  }

  // ------------------------------------------------------------------ chaos (very rare)
  rollChaos() {
    if (this.chaosUsed || this.rng() > 0.015) return [];
    const pool = CHAOS.filter((c) => (!c.onlyIn || c.onlyIn.includes(this.key)) && (!c.notIn || !c.notIn.includes(this.key)));
    const c = this.pick(pool);
    this.chaosUsed = true;
    const ev = [{ t: 'chaos', c }];
    if (c.id === 'beezy') {
      const t = this.alive(this.party).sort((a, b) => a.hp / a.maxHp - b.hp / b.maxHp)[0];
      const amt = Math.min(30, t.maxHp - t.hp);
      t.hp += amt;
      ev.push({ t: 'heal', u: t, amt, hp: t.hp, text: `…and throws ${t.name} a beezy. +${amt}. He keeps running.` });
    } else if (c.id === 'dulbmeethus') {
      const t = this.pick(this.alive(this.party));
      t.meter = 100;
      ev.push({ t: 'meterFull', u: t, text: `Dulbmeethus blesses ${t.name}. Meter: FULL.` });
    } else if (c.id === 'mattias') {
      this.alive(this.party).forEach((p) => ev.push(...this.addMeter(p, 15)));
      ev.push({ t: 'say', text: 'He leaves. Everyone feels weirdly motivated. (+15 meter)', ms: 1400 });
    } else if (c.id === 'rock') {
      const t = this.pick(this.alive(this.enemies));
      ev.push(...this.damageEnemy(null, t, 25, { raw: true, text: `It lands on ${t.name}.`, sound: 'chudThud', shake: true }));
    }
    return ev;
  }

  // ------------------------------------------------------------------ enemies
  target(e, mode = 'weak') {
    const alive = this.alive(this.party);
    const defenders = alive.filter((p) => p.defending);
    if (defenders.length && this.rng() < 0.7) return this.pick(defenders);
    if (mode === 'strong') return alive.slice().sort((a, b) => b.hp - a.hp)[0];
    if (mode === 'random') return this.pick(alive);
    const w = alive.map((p) => 1 + 2 * (1 - p.hp / p.maxHp));
    let r = this.rng() * w.reduce((s, x) => s + x, 0);
    for (let i = 0; i < alive.length; i++) { r -= w[i]; if (r <= 0) return alive[i]; }
    return alive[alive.length - 1];
  }

  // Decide what the enemy does. Returns an intent the scene animates and then resolves.
  enemyPlan(e) {
    e.turn += 1;
    const party = this.alive(this.party);
    const all = { aoe: true, targets: party };

    if (e.phasePending) {
      e.phasePending = false;
      e.phase = 2;
      if (e.ai === 'giant') return { kind: 'phase', text: 'Diddy Chud Giant gets up. "Aight. Bet." (He\'s faster now. And hungry.)', bark: 'phase' };
      if (e.ai === 'dulbers') { e.disguise = this.pick(party).id; e.disguiseTurns = 2; return { kind: 'phase', text: `Dulbers SHAPESHIFTS… into ${PARTY[e.disguise].name}?! (Bootleg version)`, bark: 'phase', disguise: e.disguise }; }
    }

    if (this.mods.enemyTripping && this.rng() < 0.3) {
      return this.rng() < 0.5
        ? { kind: 'selfHurt', power: 10, text: `${e.name} punches a rock that insulted him.` }
        : { kind: 'nothing', text: `${e.name} yells "WHY IS THE SKY SO LOUD" and forgets to attack.` };
    }

    if (e.ai === 'goblin') {
      const buddies = this.alive(this.enemies).filter((x) => x !== e && !x.st.hyped);
      if (buddies.length && this.rng() < 0.18) return { kind: 'hype', other: this.pick(buddies), text: `${e.name} yells "LET'S GOOOO!"`, bark: 'hype' };
      const t = this.target(e);
      return { kind: 'hit', name: 'Spoon Bonk', power: 9, targets: [t], text: `${e.name} bonks ${t.name} with a spoon!`, sound: 'bonk' };
    }

    if (e.ai === 'dulbers') {
      if (e.phase === 2) {
        e.disguiseTurns -= 1;
        if (e.disguiseTurns < 0) {
          const opts = party.map((p) => p.id).filter((id) => id !== e.disguise);
          e.disguise = opts.length ? this.pick(opts) : e.disguise;
          e.disguiseTurns = 1;
          return { kind: 'phase', text: `Dulbers shapeshifts into ${PARTY[e.disguise].name} now.`, disguise: e.disguise, quick: true };
        }
        if (e.hp < e.maxHp * 0.35 && !e.copeUsed && this.rng() < 0.3) {
          e.copeUsed = true;
          return { kind: 'buff', status: 'copium', turns: 3, text: 'Dulbers: "I\'m not losing, I\'m just… restocking." (COPIUM: heals each turn. Hit him hard to break it.)' };
        }
        if (e.disguise === 'skorn') { const t = this.target(e); return { kind: 'hit', name: 'Diddy Slap (Bootleg)', power: 36, targets: [t], text: `Bootleg Skorn slaps ${t.name}!`, sound: 'slap' }; }
        if (e.disguise === 'lykor') { const t = this.target(e); return { kind: 'hit', name: 'Hair Flip (Knockoff)', power: 18, targets: [t], flatten: 0.45, text: `Knockoff Lykor hair-flips at ${t.name}!`, sound: 'hairflip' }; }
        return { kind: 'hit', name: 'Eldritch Blast (Generic)', power: 20, ...all, text: 'Generic Xylo blasts the whole party!', sound: 'zap' };
      }
      const r = this.rng();
      if (this.inv.beer > 0 && e.hp < e.maxHp * 0.75 && (e.stole || 0) < 2 && r < 0.22) {
        e.stole = (e.stole || 0) + 1;
        return { kind: 'steal', text: 'Dulbers steals one of your Beezys and chugs it in front of you.' };
      }
      const lykor = party.find((p) => p.id === 'lykor');
      if (lykor && !e.st.shield && !e.shielded && r < 0.35) {
        e.shielded = true;
        return { kind: 'shield', amt: 35, drain: lykor, text: "Dulbers steals some of Lykor's aura and makes an AURA SHIELD out of it." };
      }
      if (this.rng() < 0.62) { const t = this.target(e); return { kind: 'hit', name: 'Price Gouge', power: 34, targets: [t], gouge: true, text: `Dulbers price-gouges ${t.name}! "That'll be 34 HP, plus tax."`, sound: 'slap' }; }
      return { kind: 'hit', name: 'NO REFUNDS', power: 21, ...all, brick: true, text: 'Dulbers screams "NO REFUNDS!" It hurts everyone\'s ears.', sound: 'roar' };
    }

    if (e.ai === 'giant') {
      if (e.sitPending) { e.sitPending = false; return { kind: 'hit', name: 'SIT', power: 44, ...all, sit: true, text: 'DIDDY CHUD SITS ON EVERYONE!', sound: 'sitImpact', tex: e.E.tex }; }
      if (e.eatPending) { e.eatPending = false; return { kind: 'eat', amt: 60, text: 'Diddy Chud eats an entire Chipotle Bowl. BIG BACK. (+60)' }; }
      e.tele = (e.tele || 0) + 1;
      if (e.tele % 3 === 0) {
        e.sitCount = (e.sitCount || 0) + 1;
        if (e.phase === 2 && e.sitCount % 2 === 0) { e.eatPending = true; return { kind: 'telegraph', text: 'Diddy Chud pulls out a Chipotle Bowl… (Hit him for 30+ or stun him to make him drop it!)', status: 'eat' }; }
        e.sitPending = true;
        return { kind: 'telegraph', text: 'Diddy Chud Giant is getting ready to SIT. (Defend, block it, or charm/stun him to make him fall!)', tex: e.E.sitTex, status: 'sit' };
      }
      if (e.tele % 3 === 1) { const t = this.target(e, 'strong'); return { kind: 'hit', name: 'Stomp', power: 28, targets: [t], text: `Diddy Chud stomps on ${t.name}!`, sound: 'stomp' }; }
      return { kind: 'hit', name: 'Ground Pound', power: 17, ...all, text: 'Diddy Chud pounds the ground!', sound: 'stomp' };
    }
    return { kind: 'nothing', text: `${e.name} waits.` };
  }

  // Apply the intent. block = 'perfect' | 'good' | 'mid' | null
  enemyResolve(e, it, block) {
    const ev = [];
    if (it.bark) ev.push(...this.bark(e, it.bark, 1));
    else if (it.kind === 'hit') ev.push(...this.bark(e, 'taunt', 0.15));
    switch (it.kind) {
      case 'phase':
        if (it.disguise) e.disguise = it.disguise;
        ev.push({ t: 'phase', u: e, text: it.text, disguise: it.disguise, quick: it.quick });
        return ev;
      case 'nothing': ev.push({ t: 'say', text: it.text, ms: 1400 }); return ev;
      case 'selfHurt': return ev.concat(this.damageEnemy(null, e, it.power, { raw: true, text: it.text, sound: 'stomp' }));
      case 'hype':
        it.other.st.hyped = 1;
        ev.push({ t: 'status', u: it.other, name: 'hyped', text: `${it.other.name} is HYPED UP. His next bonk does double damage.` });
        return ev;
      case 'telegraph':
        ev.push({ t: 'telegraph', u: e, text: it.text, tex: it.tex, status: it.status });
        return ev;
      case 'eat': {
        const amt = Math.min(it.amt, e.maxHp - e.hp);
        e.hp += amt;
        ev.push({ t: 'heal', u: e, amt, hp: e.hp, text: it.text, sound: 'gulp' });
        return ev;
      }
      case 'steal': {
        this.inv.beer -= 1;
        const amt = Math.min(30, e.maxHp - e.hp);
        e.hp += amt;
        ev.push({ t: 'heal', u: e, amt, hp: e.hp, text: `${it.text} (+${amt}) (${this.inv.beer} left)`, sound: 'gulp' });
        return ev;
      }
      case 'shield':
        e.st.shield = it.amt;
        it.drain.meter = Math.max(0, it.drain.meter - 25);
        ev.push({ t: 'status', u: e, name: 'shield', text: `${it.text} (Absorbs ${it.amt}. Lykor loses 25 meter.)` });
        return ev;
      case 'buff':
        e.st[it.status] = it.turns;
        ev.push({ t: 'status', u: e, name: it.status, text: it.text });
        return ev;
      default: break;
    }

    // Attacks
    if (e.st.blind) {
      delete e.st.blind;
      if (this.rng() < 0.6) { ev.push({ t: 'miss', u: e, text: `${e.name} swings at nothing. BLINDED.`, sound: 'miss' }); return ev; }
    }
    let mult = this.diff.dmg * (this.mods.enraged ? 1.1 : 1);
    if (e.st.hyped) { mult *= 2; delete e.st.hyped; }
    if (e.st.downbad) mult *= 0.5;
    if (block) { this.stats.timed += 1; if (block === 'perfect') this.stats.perfects += 1; }
    ev.push({ t: 'attack', u: e, text: it.text, sound: it.sound, sit: it.sit, block });
    if (it.tex) ev.push({ t: 'tex', u: e, tex: it.tex });
    it.targets.filter((p) => p.hp > 0).forEach((p) => {
      let dmg = it.power * mult * (block ? BLOCK[block] : 1);
      if (p.defending) dmg *= it.sit ? 0.25 : 0.5;
      ev.push(...this.hurt(p, Math.max(1, Math.round(dmg)), block, it.aoe));
      if (p.hp <= 0) return;
      const soft = p.defending || block === 'perfect' || block === 'good';
      if (it.gouge && block !== 'perfect') ev.push(...this.partyStatus(p, 'gouged', 2, `${p.name} is PRICE GOUGED. Healing is halved for a bit.`));
      if (it.sit && !soft) ev.push(...this.partyStatus(p, 'flattened', 1, `${p.name} is FLATTENED. Loses their next turn.`));
      if (it.flatten && !soft && this.rng() < it.flatten) ev.push(...this.partyStatus(p, 'flattened', 1, `${p.name} is too charmed by the knockoff hair. Loses their next turn.`));
    });
    if (it.brick) {
      const p = this.pick(this.alive(this.party));
      if (p) { p.st.bricked = 1; p.cds.special += 1; ev.push({ t: 'status', u: p, name: 'bricked', text: `${p.name} is BRICKED. Their special takes an extra turn.` }); }
    }
    return ev;
  }

  partyStatus(p, name, turns, text) {
    p.st[name] = turns;
    return [{ t: 'status', u: p, name, text }];
  }

  hurt(p, dmg, block, aoe) {
    const ev = [];
    p.hp = Math.max(0, p.hp - dmg);
    this.stats.dmgTaken += dmg;
    ev.push({ t: 'hurt', u: p, amt: dmg, hp: p.hp, block, quick: aoe });
    ev.push(...this.addMeter(p, dmg * 0.35 + (block === 'perfect' ? 15 : block === 'good' ? 8 : 0)));
    if (p.hp <= 0) {
      this.stats.kos += 1;
      p.meter = 0; p.st = {}; p.defending = false;
      ev.push({ t: 'ko', u: p });
      ev.push(...this.bark(p, 'ko', 0.8));
      const buddy = this.alive(this.party)[0];
      if (buddy) ev.push(...this.bark(buddy, 'allyKo', 0.6));
      if (buddy && this.inv.beer + this.inv.bowl === 0 && !this.emergencyGiven) {
        this.emergencyGiven = true;
        this.inv.beer = 1;
        ev.push({ t: 'say', text: 'Someone\'s down and you\'re out of items? Here — 1 Emergency Beezy (complimentary).', sound: 'grab', ms: 1600 });
      }
    } else if (!p.lowWarned && p.hp < p.maxHp * 0.3) {
      p.lowWarned = true;
      ev.push(...this.bark(p, 'lowhp', 0.8));
    } else if (!aoe) {
      ev.push(...this.bark(p, 'hurt', 0.12));
    }
    return ev;
  }

  allyAct(u) {
    const t = this.pick(this.alive(this.enemies));
    return [{ t: 'allyAttack', u, target: t }, ...this.damageEnemy(null, t, 10, { raw: true, text: `Goblin backup bonks ${t.name} with a spoon!`, sound: 'bonk' })];
  }

  // ------------------------------------------------------------------ grade
  grade() {
    const s = this.stats;
    const maxHp = this.party.reduce((a, p) => a + p.maxHp, 0);
    let score = 100;
    score -= 45 * Math.min(1.5, s.dmgTaken / maxHp);
    score -= 12 * s.kos;
    score -= 3 * s.items;
    score += 15 * (s.timed ? s.perfects / s.timed : 0);
    score -= Math.max(0, s.partyTurns - this.def.par) * 1.2;
    score = Math.round(Math.max(0, Math.min(100, score)));
    const g = GRADES.find((x) => score >= x.min);
    return { score, ...g };
  }
}
