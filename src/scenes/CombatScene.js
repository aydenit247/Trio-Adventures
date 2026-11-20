import { PARTY, ITEMS, THROWABLES, TRIP_MISFIRES, FIGHTS, LEVELS } from '../data/combat.js';
import { vignette } from '../fx.js';
import Sfx from '../audio/Sfx.js';
import Outcomes from '../systems/outcomes.js';

// Turn-based combat, launched on top of a story scene (which pauses until the fight ends).
//
//   this.scene.launch('Combat', { fight: 'giant', mods: { enraged: true }, bg: 'bg_mountain_path', onDone })
//
// mods: tripping: 'party' | 'skorn'  — midtocy misfires/crits
//       allies: true                  — goblin backup attacks every round
//       enemyTripping: true           — the enemy sometimes hurts itself
//       enraged: true                 — the enemy has more HP and hits harder
const W = 1280, H = 720;
const UI_TOP = 566;

export default class CombatScene extends Phaser.Scene {
  constructor() { super('Combat'); }

  init(cfg) { this.cfg = cfg; }

  create() {
    const { fight, mods = {}, bg } = this.cfg;
    this.mods = mods;
    this.def = FIGHTS[fight];
    this.level = this.registry.get('level') || 1;
    this.lvlMult = 1 + 0.1 * (this.level - 1);
    this.buff = 0;
    this.busy = true;
    this.handler = null;

    // ---------- Backdrop ----------
    if (bg && this.textures.exists(bg)) {
      const img = this.add.image(W / 2, H / 2, bg);
      img.setScale(Math.max(W / img.width, H / img.height) * 1.05);
    }
    this.add.rectangle(0, 0, W, H, 0x0a0612, 0.45).setOrigin(0);
    vignette(this, 1);

    // ---------- Party ----------
    const partyIds = mods.party || this.def.party;
    const pxs = { 1: [330], 2: [250, 470], 3: [170, 345, 520] }[partyIds.length];
    this.party = partyIds.map((id, i) => {
      const P = PARTY[id];
      const maxHp = Math.round(P.hp * (1 + 0.1 * (this.level - 1)));
      const tripping = mods.tripping === 'party' || (mods.tripping === 'skorn' && id === 'skorn');
      const m = { id, P, maxHp, hp: maxHp, cds: { special: 0, bonus: 0 }, defending: false, tripping,
        idleTex: tripping ? `char_${id}_tweaking` : P.tex };
      m.sprite = this.makeSprite(pxs[i], 556, m.idleTex, P.h, false);
      return m;
    });

    // ---------- Enemies ----------
    const exs = { 1: [960], 2: [870, 1080], 3: [800, 985, 1165] }[this.def.enemies.length];
    this.enemies = this.def.enemies.map((E, i) => {
      const hpMul = (mods.enraged ? 1.15 : 1) * (partyIds.length < this.def.party.length ? 0.75 : 1);
      const e = { ...E, maxHp: Math.round(E.hp * hpMul), hp: Math.round(E.hp * hpMul), turn: 0,
        status: { charm: 0, blind: 0, stun: 0 } };
      if (mods.enraged) e.tag = '(ENRAGED)';
      if (mods.enemyTripping) e.tag = '(Tripping)';
      const feet = E.ai === 'giant' ? 610 : 560;
      e.sprite = this.makeSprite(exs[i], feet, E.tex, E.h, false);
      e.sprite.setInteractive(new Phaser.Geom.Rectangle(-80, -E.h, 160, E.h), Phaser.Geom.Rectangle.Contains);
      e.sprite.on('pointerdown', () => this.handler && this.handler({ click: 'enemy', e }));
      e.sprite.on('pointerover', () => this.handler && this.handler({ hover: 'enemy', e }));
      // Name + HP bar above the head
      const top = Math.max(100, feet - E.h - 34);
      e.nameText = this.add.text(exs[i], top - 18, `${E.name} ${e.tag}`, {
        fontFamily: 'Nunito', fontSize: this.def.enemies.length > 2 ? '13px' : '16px', fontStyle: '900', color: '#1a1324', backgroundColor: '#f3e3b0', padding: { x: 6, y: 1 },
      }).setOrigin(0.5).setDepth(50);
      this.add.rectangle(exs[i] - 80, top + 6, 160, 12, 0x1a1324).setOrigin(0, 0.5).setStrokeStyle(2, 0xe8b923).setDepth(50);
      e.hpBar = this.add.rectangle(exs[i] - 78, top + 6, 156, 8, 0xd8403a).setOrigin(0, 0.5).setDepth(50);
      e.statusText = this.add.text(exs[i], top + 24, '', { fontFamily: 'Nunito', fontSize: '14px', fontStyle: '900', color: '#ffdf8a', stroke: '#000', strokeThickness: 3 }).setOrigin(0.5).setDepth(50);
      if (mods.enemyTripping) e.sprite.img.setTint(0xd8b0ff);
      return e;
    });

    // ---------- Goblin backup ----------
    this.allies = [];
    if (mods.allies) {
      [[60, 560, 150], [640, 566, 140]].forEach(([x, y, h]) => this.allies.push(this.makeSprite(x, y, 'char_goblin_fight', h, true)));
    }

    // ---------- Items ----------
    this.inv = { beer: this.registry.get('inv_beer') || 0, bowl: this.registry.get('inv_bowl') || 0 };
    this.emergency = false;
    if (!this.inv.beer && !this.inv.bowl) { this.inv.beer = 1; this.emergency = true; }

    this.buildUI();
    this.setupInput();
    this.events.once('shutdown', () => this.input.keyboard.removeAllListeners());
    this.runBattle();
  }

  // ======================= Building blocks =======================
  makeSprite(x, feetY, tex, h, flip) {
    const c = this.add.container(x, feetY).setDepth(10 + feetY / 100);
    const shadow = this.add.ellipse(0, 0, h * 0.4, h * 0.07, 0x000000, 0.5);
    const img = this.add.image(0, 0, tex).setOrigin(0.5, 1).setFlipX(flip);
    img.setScale(h / img.height);
    c.add([shadow, img]);
    c.img = img; c.h = h; c.homeX = x; c.homeY = feetY;
    c.breath = this.tweens.add({ targets: img, scaleY: img.scaleY * 1.012, yoyo: true, repeat: -1, duration: 1500 + Math.random() * 500, ease: 'Sine.inOut' });
    return c;
  }

  setTex(sprite, tex, flip = false) {
    if (!this.textures.exists(tex)) return;
    if (sprite.breath) sprite.breath.stop();
    sprite.img.setTexture(tex).setFlipX(flip);
    sprite.img.setScale(sprite.h / sprite.img.height);
    sprite.breath = this.tweens.add({ targets: sprite.img, scaleY: sprite.img.scaleY * 1.012, yoyo: true, repeat: -1, duration: 1600, ease: 'Sine.inOut' });
  }

  // Snap every sprite back to its spot (overlapping yoyo tweens can drift)
  settle() {
    [...this.party, ...this.enemies].forEach((u) => {
      const c = u.sprite;
      this.tweens.killTweensOf(c);
      c.setPosition(c.homeX, u.hp > 0 ? c.homeY : c.y);
      if (u.hp > 0) c.setAngle(0);
      this.tweens.getTweensOf(c.img).forEach((t) => { if (t !== c.breath) t.stop(); });
      c.img.setY(0).setAngle(0);
    });
    this.allies.forEach((c) => { this.tweens.killTweensOf(c); c.setPosition(c.homeX, c.homeY); });
  }

  tweenP(cfg) { return new Promise((res) => this.tweens.add({ ...cfg, onComplete: res })); }
  wait(ms) { return new Promise((res) => this.time.delayedCall(ms, res)); }
  alive(list) { return list.filter((x) => x.hp > 0); }

  buildUI() {
    // Top message bar
    this.msgBg = this.add.rectangle(W / 2, 34, 980, 46, 0x120e1e, 0.9).setStrokeStyle(2, 0xe8b923).setDepth(90);
    this.msg = this.add.text(W / 2, 34, '', { fontFamily: 'Nunito', fontSize: '21px', fontStyle: '700', color: '#f4efff', align: 'center', wordWrap: { width: 950 } }).setOrigin(0.5).setDepth(91);

    // Bottom panel
    const g = this.add.graphics().setDepth(80);
    g.fillGradientStyle(0x1d1633, 0x1d1633, 0x0b0812, 0x0b0812, 0.95).fillRect(0, UI_TOP, W, H - UI_TOP);
    g.lineStyle(3, 0xe8b923, 1).lineBetween(0, UI_TOP, W, UI_TOP);
    g.lineStyle(1, 0xe8b923, 0.4).lineBetween(780, UI_TOP + 12, 780, H - 12);

    // Party cards
    this.cards = this.party.map((m, i) => {
      const x = 16 + i * 254, y = UI_TOP + 14;
      const box = this.add.rectangle(x, y, 244, 128, 0x000000, 0.25).setOrigin(0).setStrokeStyle(2, 0x5a4a7a).setDepth(81);
      const por = this.add.image(x + 36, y + 40, `portrait_${m.id}`).setDisplaySize(58, 58).setDepth(82);
      const name = this.add.text(x + 72, y + 10, m.P.name, { fontFamily: 'Cinzel', fontSize: '20px', fontStyle: '900', color: '#f3e3b0' }).setDepth(82);
      const lbl = this.add.text(x + 72, y + 38, m.P.hpLabel, { fontFamily: 'Nunito', fontSize: '13px', fontStyle: '900', color: '#a49cc4' }).setDepth(82);
      this.add.rectangle(x + 12, y + 86, 220, 14, 0x1a1324).setOrigin(0, 0.5).setStrokeStyle(2, 0xe8b923).setDepth(82);
      const bar = this.add.rectangle(x + 14, y + 86, 216, 10, 0x5ad86a).setOrigin(0, 0.5).setDepth(83);
      const num = this.add.text(x + 232, y + 66, '', { fontFamily: 'Nunito', fontSize: '14px', fontStyle: '900', color: '#f4efff' }).setOrigin(1, 0.5).setDepth(83);
      const st = this.add.text(x + 12, y + 104, '', { fontFamily: 'Nunito', fontSize: '13px', fontStyle: '900', color: '#ffdf8a' }).setDepth(83);
      return { box, bar, num, st, por };
    });
    if (this.party.length === 1) {
      this.add.text(290, UI_TOP + 30, `Level ${this.level}`, { fontFamily: 'Cinzel', fontSize: '20px', color: '#e8b923' }).setDepth(82);
    }

    // Command menu
    this.menuTitle = this.add.text(800, UI_TOP + 10, '', { fontFamily: 'Cinzel', fontSize: '18px', fontStyle: '900', color: '#e8b923' }).setDepth(82);
    this.menuTexts = [];
    for (let i = 0; i < 5; i++) {
      const t = this.add.text(810, UI_TOP + 38 + i * 23, '', { fontFamily: 'Nunito', fontSize: '19px', fontStyle: '900', color: '#f4efff' })
        .setDepth(82).setInteractive({ useHandCursor: true });
      t.on('pointerover', () => this.handler && this.handler({ hover: 'menu', i }));
      t.on('pointerdown', () => this.handler && this.handler({ click: 'menu', i }));
      this.menuTexts.push(t);
    }
    this.refresh();
  }

  refresh() {
    this.party.forEach((m, i) => {
      const c = this.cards[i];
      const f = Math.max(0, m.hp) / m.maxHp;
      c.bar.width = 216 * f;
      c.bar.fillColor = f > 0.5 ? 0x5ad86a : f > 0.25 ? 0xe8c43a : 0xd8403a;
      c.num.setText(`${Math.max(0, m.hp)}/${m.maxHp}`);
      const tags = [];
      if (m.hp <= 0) tags.push('DOWN BAD');
      if (m.defending) tags.push('DEFENDING');
      if (this.buff > 0) tags.push('HYPED');
      if (m.tripping) tags.push('TWEAKING');
      c.st.setText(tags.join(' · '));
      c.por.setAlpha(m.hp > 0 ? 1 : 0.35);
    });
    this.enemies.forEach((e) => {
      e.hpBar.width = 156 * Math.max(0, e.hp) / e.maxHp;
      const s = [];
      if (e.status.charm) s.push('CHARMED');
      if (e.status.blind) s.push('BLINDED');
      if (e.status.stun) s.push('SAT ON');
      if (e.sitPending) s.push('ABOUT TO SIT — DEFEND!');
      e.statusText.setText(s.join(' · '));
    });
  }

  say(text, ms = 1100) {
    this.msg.setText(text);
    this.tweens.add({ targets: this.msg, alpha: { from: 0.3, to: 1 }, duration: 150 });
    return this.wait(ms);
  }

  floatText(x, y, text, color = '#ffffff', size = 34) {
    const t = this.add.text(x, y, text, { fontFamily: 'Cinzel', fontSize: `${size}px`, fontStyle: '900', color, stroke: '#000', strokeThickness: 6 })
      .setOrigin(0.5).setDepth(95);
    this.tweens.add({ targets: t, y: y - 60, alpha: 0, duration: 1100, ease: 'Quad.out', onComplete: () => t.destroy() });
  }

  burst(x, y, tint, n = 30, speed = 220) {
    const p = this.add.particles(x, y, 'fx_soft', {
      speed: { min: speed * 0.3, max: speed }, scale: { start: 0.45, end: 0 }, lifespan: 700, tint, blendMode: 'ADD', emitting: false,
    }).setDepth(60);
    p.explode(n);
    this.time.delayedCall(900, () => p.destroy());
  }

  // ======================= Input =======================
  setupInput() {
    const kb = this.input.keyboard;
    const map = { ArrowUp: 'up', KeyW: 'up', ArrowDown: 'down', KeyS: 'down', ArrowLeft: 'left', KeyA: 'left',
      ArrowRight: 'right', KeyD: 'right', Enter: 'ok', Space: 'ok', KeyE: 'ok', Escape: 'back', Backspace: 'back', KeyX: 'back' };
    kb.on('keydown', (ev) => {
      const k = map[ev.code];
      if (k && this.handler) this.handler({ key: k });
    });
  }

  // Generic vertical menu. options: [{ label, desc, disabled }] → resolves index, or -1 for back.
  menu(title, options, allowBack) {
    return new Promise((resolve) => {
      let sel = options.findIndex((o) => !o.disabled);
      if (sel < 0) sel = 0;
      this.menuTitle.setText(title);
      const render = () => {
        this.menuTexts.forEach((t, i) => {
          const o = options[i];
          if (!o) { t.setText('').setVisible(false); return; }
          t.setVisible(true).setText(`${i === sel ? '▶ ' : '   '}${o.label}`)
            .setColor(o.disabled ? '#6e6690' : i === sel ? '#e8b923' : '#f4efff');
        });
        if (options[sel]) this.msg.setText(options[sel].desc || '');
      };
      const choose = (i) => {
        if (!options[i] || options[i].disabled) { Sfx.play('tick'); return; }
        Sfx.play('confirm');
        this.handler = null;
        resolve(i);
      };
      this.handler = (ev) => {
        if (ev.key === 'up') { sel = (sel + options.length - 1) % options.length; Sfx.play('tick'); render(); }
        else if (ev.key === 'down') { sel = (sel + 1) % options.length; Sfx.play('tick'); render(); }
        else if (ev.key === 'ok') choose(sel);
        else if (ev.key === 'back' && allowBack) { Sfx.play('tick'); this.handler = null; resolve(-1); }
        else if (ev.hover === 'menu' && options[ev.i]) { sel = ev.i; render(); }
        else if (ev.click === 'menu') choose(ev.i);
      };
      render();
    });
  }

  clearMenu() {
    this.menuTitle.setText('');
    this.menuTexts.forEach((t) => t.setText('').setVisible(false));
  }

  // Pick a target from a list of sprites (left/right). Resolves the item or null for back.
  pickTarget(list, label) {
    return new Promise((resolve) => {
      if (list.length === 1) { resolve(list[0]); return; }
      let sel = 0;
      const arrow = this.add.text(0, 0, '▼', { fontFamily: 'Nunito', fontSize: '34px', color: '#e8b923', stroke: '#000', strokeThickness: 5 }).setOrigin(0.5).setDepth(96);
      const bob = this.tweens.add({ targets: arrow, y: '+=8', yoyo: true, repeat: -1, duration: 300 });
      const place = () => {
        const t = list[sel];
        arrow.setPosition(t.sprite.x, t.sprite.y - (t.sprite.h || t.P.h) - 64);
        this.msg.setText(`${label}: ${t.name || t.P.name}   (←/→, ENTER · ESC to go back)`);
      };
      const done = (v) => { bob.stop(); arrow.destroy(); this.handler = null; resolve(v); };
      this.handler = (ev) => {
        if (ev.key === 'left') { sel = (sel + list.length - 1) % list.length; Sfx.play('tick'); place(); }
        else if (ev.key === 'right') { sel = (sel + 1) % list.length; Sfx.play('tick'); place(); }
        else if (ev.key === 'ok') { Sfx.play('confirm'); done(list[sel]); }
        else if (ev.key === 'back') done(null);
        else if (ev.hover === 'enemy' && list.includes(ev.e)) { sel = list.indexOf(ev.e); place(); }
        else if (ev.click === 'enemy' && list.includes(ev.e)) { Sfx.play('confirm'); done(ev.e); }
      };
      place();
    });
  }

  // ======================= Battle flow =======================
  async runBattle() {
    // Intro banner
    const ban = this.add.text(W / 2, 290, this.def.title, {
      fontFamily: 'Cinzel', fontSize: '52px', fontStyle: '900', color: '#ff6a4a', stroke: '#000', strokeThickness: 8,
    }).setOrigin(0.5).setDepth(99).setScale(0.4).setAlpha(0);
    Sfx.play('boom'); this.cameras.main.shake(300, 0.01);
    await this.tweenP({ targets: ban, scale: 1, alpha: 1, duration: 450, ease: 'Back.out' });
    await this.wait(900);
    this.tweens.add({ targets: ban, alpha: 0, duration: 400, onComplete: () => ban.destroy() });
    if (this.emergency) await this.say('No items? Here — 1 Emergency Beezy (complimentary).', 1400);
    if (this.mods.tripping === 'party') await this.say('Everyone is still tweaking. Moves might misfire… or CRIT.', 1600);
    if (this.mods.tripping === 'skorn') await this.say('Skorn is still tweaking. He might misfire… or CRIT.', 1500);
    if (this.mods.allies) await this.say('Goblin backup is here! (They attack every round.)', 1400);

    await this.tutorial();

    for (;;) {
      for (const m of this.party) {
        if (m.hp <= 0 || !this.alive(this.enemies).length) continue;
        m.defending = false;
        this.settle();
        this.refresh();
        const act = await this.chooseAction(m);
        await this.doAction(m, act);
        this.refresh();
      }
      if (!this.alive(this.enemies).length) return this.victory();
      if (this.mods.allies) { await this.allyAssist(); if (!this.alive(this.enemies).length) return this.victory(); }
      for (const e of this.alive(this.enemies)) {
        this.settle();
        await this.enemyTurn(e);
        this.refresh();
        if (!this.alive(this.party).length) return this.defeat();
      }
      // End of round
      this.party.forEach((m) => { m.cds.special = Math.max(0, m.cds.special - 1); m.cds.bonus = Math.max(0, m.cds.bonus - 1); });
      if (this.buff > 0) this.buff -= 1;
      this.refresh();
    }
  }

  // How-to-fight card, shown before the first fight ever
  tutorial() {
    let seen = false;
    try { seen = localStorage.getItem('trio_tut_combat') === '1'; } catch (e) { /* blocked */ }
    if (seen) return Promise.resolve();
    return new Promise((resolve) => {
      const ui = [];
      const add = (o) => { ui.push(o.setDepth(97)); return o; };
      add(this.add.rectangle(0, 0, W, H, 0x000000, 0.7).setOrigin(0));
      add(this.add.rectangle(W / 2, 300, 860, 440, 0x120e1e, 0.97).setStrokeStyle(3, 0xe8b923));
      add(this.add.text(W / 2, 112, 'How To Fight (on some combat shi)', { fontFamily: 'Cinzel', fontSize: '32px', fontStyle: '900', color: '#e8b923' }).setOrigin(0.5));
      const lines = [
        ['Main', 'Your basic attack. Always available.'],
        ['Special', 'Big move. Has a cooldown, so it greys out for a few turns after you use it.'],
        ['Bonus', 'A side move: buffs, throws, sitting on people. Also has a cooldown.'],
        ['Items', 'Beezy heals 30. Chipotle Bowl heals 60.'],
        ['Defend', 'Take half damage until your next turn. Use it when a big attack is coming.'],
        ['Dice', "Skorn's Crash Out rolls a d6. Roll a 6 and something special might happen…"],
      ];
      lines.forEach(([k, v], i) => {
        add(this.add.text(W / 2 - 390, 168 + i * 50, k, { fontFamily: 'Cinzel', fontSize: '22px', fontStyle: '900', color: '#f3e3b0' }));
        add(this.add.text(W / 2 - 250, 170 + i * 50, v, { fontFamily: 'Nunito', fontSize: '19px', color: '#f4efff', wordWrap: { width: 630 } }));
      });
      const go = add(this.add.text(W / 2, 486, '↑/↓ pick · ENTER confirm · ←/→ pick a target  —  press ENTER to fight', { fontFamily: 'Nunito', fontSize: '18px', fontStyle: '900', color: '#a49cc4' }).setOrigin(0.5));
      this.tweens.add({ targets: go, alpha: 0.4, yoyo: true, repeat: -1, duration: 700 });
      const done = () => {
        this.handler = null;
        try { localStorage.setItem('trio_tut_combat', '1'); } catch (e) { /* blocked */ }
        Sfx.play('confirm');
        ui.forEach((o) => o.destroy());
        resolve();
      };
      this.time.delayedCall(600, () => {
        this.handler = (ev) => { if (ev.key === 'ok') done(); };
        this.input.once('pointerdown', () => { if (this.handler) done(); });
      });
    });
  }

  async chooseAction(m) {
    const card = this.cards[this.party.indexOf(m)];
    card.box.setStrokeStyle(3, 0xe8b923);
    const arrow = this.add.text(m.sprite.x, m.sprite.y - m.P.h - 30, '▼', { fontFamily: 'Nunito', fontSize: '28px', color: '#e8b923', stroke: '#000', strokeThickness: 5 }).setOrigin(0.5).setDepth(96);
    const bob = this.tweens.add({ targets: arrow, y: '+=8', yoyo: true, repeat: -1, duration: 300 });
    const cleanup = () => { bob.stop(); arrow.destroy(); card.box.setStrokeStyle(2, 0x5a4a7a); };
    for (;;) {
      const mv = m.P.moves;
      const cd = (slot) => (m.cds[slot] > 0 ? `  (${m.cds[slot]} turn${m.cds[slot] > 1 ? 's' : ''})` : '');
      const items = this.inv.beer + this.inv.bowl;
      const i = await this.menu(`What will ${m.P.name} do?`, [
        { label: mv.main.name, desc: mv.main.desc },
        { label: mv.special.name + cd('special'), desc: mv.special.desc, disabled: m.cds.special > 0 },
        { label: mv.bonus.name + cd('bonus'), desc: mv.bonus.desc, disabled: m.cds.bonus > 0 },
        { label: `Items (${items})`, desc: items ? 'Beezy heals 30. Chipotle Bowl heals 60.' : 'No items left.', disabled: !items },
        { label: 'Defend', desc: 'Brace. Take half damage until your next turn (a quarter from a giant sit).' },
      ], false);
      if (i <= 2) {
        const slot = ['main', 'special', 'bonus'][i];
        const move = mv[slot];
        let target = null;
        if (['hit', 'throw', 'crashout', 'chudout'].includes(move.kind)) {
          this.clearMenu();
          target = await this.pickTarget(this.alive(this.enemies), move.name);
          if (!target) continue;
        }
        cleanup(); this.clearMenu();
        return { type: 'move', slot, move, target };
      }
      if (i === 3) {
        const opts = [];
        if (this.inv.beer) opts.push({ key: 'beer', label: `Beezy ×${this.inv.beer}`, desc: 'Heals 30.' });
        if (this.inv.bowl) opts.push({ key: 'bowl', label: `Chipotle Bowl ×${this.inv.bowl}`, desc: 'Heals 60.' });
        opts.push({ key: null, label: 'Back', desc: '' });
        const j = await this.menu('Items', opts, true);
        if (j < 0 || !opts[j].key) continue;
        let target = m;
        if (this.party.length > 1) {
          this.clearMenu();
          target = await this.pickTarget(this.alive(this.party), `Give ${ITEMS[opts[j].key].name} to`);
          if (!target) continue;
        }
        cleanup(); this.clearMenu();
        return { type: 'item', item: opts[j].key, target };
      }
      cleanup(); this.clearMenu();
      return { type: 'defend' };
    }
  }

  // ======================= Party actions =======================
  async doAction(m, a) {
    if (a.type === 'defend') {
      m.defending = true;
      Sfx.play('throw');
      this.tweens.add({ targets: m.sprite, x: m.sprite.x - 12, yoyo: true, duration: 120 });
      await this.say(`${m.P.name} braces. (Defending)`, 900);
      return;
    }
    if (a.type === 'item') {
      const it = ITEMS[a.item];
      this.inv[a.item] -= 1;
      this.registry.set(it.key, this.inv[a.item]);
      const t = a.target;
      const icon = this.add.image(m.sprite.x, m.sprite.y - m.P.h - 40, it.tex).setDepth(95);
      icon.setScale(70 / icon.width);
      await this.tweenP({ targets: icon, x: t.sprite.x, y: t.sprite.y - t.P.h * 0.6, duration: 400 });
      icon.destroy();
      Sfx.play(a.item === 'beer' ? 'gulp' : 'sparkle'); Sfx.play('heal');
      const healed = Math.min(it.heal, t.maxHp - t.hp);
      t.hp += healed;
      this.floatText(t.sprite.x, t.sprite.y - t.P.h * 0.7, `+${healed}`, '#7dff8a');
      this.burst(t.sprite.x, t.sprite.y - t.P.h * 0.5, [0x7dff8a, 0xfff2b0], 20, 120);
      this.refresh();
      await this.say(`${t.P.name} has a ${it.name}. +${healed} ${t.P.hpLabel}.`, 1100);
      return;
    }

    const { move, slot, target } = a;
    if (move.cd) m.cds[slot] = move.cd + 1;

    // Midtocy: misfire or crit
    let crit = 1;
    if (m.tripping) {
      const r = Math.random();
      if (r < 0.22) {
        Sfx.play('miss');
        this.tweens.add({ targets: m.sprite, angle: { from: -8, to: 8 }, yoyo: true, repeat: 2, duration: 120, onComplete: () => m.sprite.setAngle(0) });
        await this.say(Phaser.Utils.Array.GetRandom(TRIP_MISFIRES[m.id]), 1600);
        return;
      }
      if (r < 0.42) { crit = 2; Sfx.play('crit'); this.floatText(m.sprite.x, m.sprite.y - m.P.h - 20, 'TWEAK CRIT!', '#ff6bd5', 26); }
    }
    const dmgOf = (power) => Math.round(power * this.lvlMult * (this.buff > 0 ? 1.5 : 1) * crit);

    if (move.kind === 'buff') {
      await this.pose(m, move.pose);
      Sfx.play('buff');
      this.cameras.main.flash(300, 255, 210, 90);
      this.floatText(W / 2, 250, 'ON SOME TYPE SHI', '#ffdf4a', 54);
      this.party.forEach((p) => p.hp > 0 && this.burst(p.sprite.x, p.sprite.y - p.P.h * 0.5, [0xffdf4a, 0xfff2b0], 25, 160));
      this.buff = 3; // counts down at round end → lasts through next round
      this.refresh();
      await this.say(`${m.P.name} screams "on some type shi"! The party is HYPED (hits 50% harder for 2 turns).`, 1700);
      this.unpose(m);
      return;
    }

    if (move.kind === 'crashout') {
      await this.pose(m, move.pose);
      Sfx.play('roar'); this.cameras.main.shake(900, 0.012);
      this.burst(m.sprite.x, m.sprite.y - m.P.h * 0.5, [0xff3a2a, 0xff8a2a], 40, 260);
      await this.say(`${m.P.name} is CRASHING OUT. Rolling the dice…`, 900);
      const roll = await this.rollDie();
      this.unpose(m);
      if (roll === 7) { await this.sixSeven(); return; }
      if (roll === 1) {
        m.hp = Math.max(1, m.hp - 10);
        this.floatText(m.sprite.x, m.sprite.y - m.P.h * 0.6, '-10', '#ff6a5a');
        await this.say(`A 1. ${m.P.name} crashes out on HIMSELF. (-10)`, 1500);
        return;
      }
      const power = { 2: 18, 3: 18, 4: 30, 5: 30, 6: 40 }[roll];
      await this.lunge(m);
      await this.hitEnemy(target, dmgOf(power), `${m.P.name} crashes out on ${target.name}!`);
      return;
    }

    if (move.kind === 'throw') {
      const thing = Phaser.Utils.Array.GetRandom(THROWABLES);
      await this.pose(m, move.pose);
      Sfx.play('throw');
      const t = this.add.text(m.sprite.x, m.sprite.y - m.P.h, thing, {
        fontFamily: 'Nunito', fontSize: '18px', fontStyle: '900', color: '#1a1324', backgroundColor: '#f3e3b0', padding: { x: 6, y: 2 },
      }).setOrigin(0.5).setDepth(95);
      this.tweens.add({ targets: t, angle: 720, duration: 600 });
      await this.tweenP({ targets: t, x: target.sprite.x, y: target.sprite.y - target.h * 0.6, duration: 600, ease: 'Quad.in' });
      t.destroy();
      this.unpose(m);
      await this.hitEnemy(target, dmgOf(move.power), `${m.P.name} throws ${thing} at ${target.name}!`);
      return;
    }

    if (move.kind === 'chudout') {
      await this.playChudOut();
      Sfx.play('chudThud'); this.cameras.main.shake(900, 0.025);
      this.burst(target.sprite.x, target.sprite.y - 40, [0xb8a890, 0xffffff], 50, 300);
      await this.hitEnemy(target, dmgOf(move.power), `${m.P.name} CHUDS OUT and sits on ${target.name}!`);
      if (target.hp > 0) { target.status.stun = 1; this.refresh(); }
      return;
    }

    // Standard hit with effects
    await this.pose(m, move.pose, m.id === 'xylo' && move.fx === 'blast');
    if (move.fx === 'slap') { await this.lunge(m); }
    if (move.fx === 'blast') await this.projectile(m, target, [0xb06bff, 0x7f5bff]);
    if (move.fx === 'lore') {
      Sfx.play('pages'); this.time.delayedCall(500, () => Sfx.play('choir'));
      const runes = this.add.particles(target.sprite.x, target.sprite.y - target.h * 0.5, 'fx_soft', {
        x: { min: -120, max: 120 }, y: { min: -160, max: 120 }, speedY: { min: -60, max: -20 },
        scale: { start: 0.35, end: 0 }, lifespan: 1000, frequency: 25, tint: [0xffd27a, 0xfff2b0], blendMode: 'ADD',
      }).setDepth(60);
      await this.say(`${m.P.name} reads from Deloye Lore, Vol. 1 of ∞… it goes on for a while…`, 1500);
      runes.stop(); this.time.delayedCall(1000, () => runes.destroy());
    }
    if (move.fx === 'sparkle') {
      Sfx.play('hairflip');
      this.burst(m.sprite.x + 40, m.sprite.y - m.P.h * 0.85, [0xfff2b0, 0xffffff], 25, 180);
    }
    if (move.fx === 'mog') {
      Sfx.play('mog');
      this.cameras.main.flash(350, 255, 230, 160);
      this.floatText(W / 2, 240, 'MOG', '#ffdf4a', 80);
      await this.wait(500);
    }
    this.unpose(m);
    await this.hitEnemy(target, dmgOf(move.power), `${m.P.name} uses ${move.name} on ${target.name}!`, { slap: 'slap', blast: 'impactMagic', lore: 'impactMagic' }[move.fx]);
    if (target.hp > 0 && move.charm && Math.random() < move.charm) {
      target.status.charm = 1; this.refresh();
      await this.say(`${target.name} is charmed by the hair. They might just… stand there.`, 1200);
    }
    if (target.hp > 0 && move.blind) {
      target.status.blind = 1; this.refresh();
      await this.say(`${target.name} is BLINDED by Lykor's beauty.`, 1100);
    }
  }

  async pose(m, tex, flip = false) {
    this.setTex(m.sprite, tex, flip);
    this.tweens.add({ targets: m.sprite.img, y: -10, yoyo: true, duration: 120 });
    await this.wait(250);
  }

  unpose(m) { if (m.hp > 0) this.setTex(m.sprite, m.idleTex); }

  lunge(m) {
    return this.tweenP({ targets: m.sprite, x: m.sprite.x + 70, yoyo: true, duration: 140, ease: 'Quad.out' });
  }

  async projectile(m, target, tint) {
    Sfx.play('zap');
    const orb = this.add.image(m.sprite.x + 60, m.sprite.y - m.P.h * 0.65, 'fx_soft').setTint(tint[0]).setScale(1.2)
      .setBlendMode(Phaser.BlendModes.ADD).setDepth(60);
    const trail = this.add.particles(0, 0, 'fx_soft', { follow: orb, scale: { start: 0.5, end: 0 }, lifespan: 300, frequency: 15, tint, blendMode: 'ADD' }).setDepth(59);
    await this.tweenP({ targets: orb, x: target.sprite.x, y: target.sprite.y - target.h * 0.55, duration: 450, ease: 'Quad.in' });
    this.burst(orb.x, orb.y, tint, 35, 260);
    orb.destroy(); trail.stop(); this.time.delayedCall(400, () => trail.destroy());
  }

  async hitEnemy(e, dmg, line, sound = 'hit') {
    e.hp = Math.max(0, e.hp - dmg);
    Sfx.play(sound);
    e.sprite.img.setTintFill(0xffffff);
    this.time.delayedCall(90, () => e.sprite.img.clearTint());
    this.tweens.add({ targets: e.sprite, x: e.sprite.x + 14, yoyo: true, repeat: 2, duration: 50 });
    this.floatText(e.sprite.x, e.sprite.y - e.h * 0.7, `-${dmg}`, '#ff6a5a');
    this.refresh();
    await this.say(`${line} (-${dmg})`, 1100);
    if (e.hp <= 0) await this.enemyDown(e);
  }

  async enemyDown(e) {
    Sfx.play('enemyDown');
    e.nameText.setText(`${e.name} (Defeated)`);
    e.statusText.setText('');
    await this.tweenP({ targets: e.sprite, alpha: 0.15, angle: 12, y: e.sprite.y + 20, duration: 500 });
    await this.say(`${e.name} is down!`, 800);
  }

  // Xylo's green-screen Chud Out video over the battlefield
  playChudOut() {
    return new Promise((resolve) => {
      const vid = this.add.video(W / 2, H / 2 - 40, 'vid_xylo_chudout_short').setDepth(70);
      if (this.renderer.pipelines) vid.setPostPipeline('ChromaKey');
      vid.setMute(Sfx.muted);
      let done = false;
      const end = () => {
        if (done) return; done = true;
        this.handler = null;
        vid.stop(); vid.destroy(); skip.destroy();
        resolve();
      };
      const skip = this.add.text(W - 16, UI_TOP - 10, 'Space: skip', { fontFamily: 'Nunito', fontSize: '15px', color: '#ffffffaa' }).setOrigin(1, 1).setDepth(96);
      vid.on('created', () => vid.setDisplaySize(W * 0.8, H * 0.8));
      vid.on('complete', end);
      vid.on('error', end);
      vid.play(false);
      this.time.delayedCall(2500, () => { if (!done && !vid.isPlaying()) end(); });
      this.time.delayedCall(300, () => { if (!done) this.handler = (ev) => { if (ev.key === 'ok') end(); }; });
    });
  }

  // ======================= Dice ("on some dice shi") + the 6-7 =======================
  rollDie() {
    return new Promise((resolve) => {
      const ui = [];
      const add = (o) => { ui.push(o.setDepth(97)); return o; };
      add(this.add.rectangle(0, 0, W, H, 0x000000, 0.55).setOrigin(0));
      add(this.add.text(W / 2, 150, 'on some dice shi', { fontFamily: 'Cinzel', fontSize: '40px', fontStyle: '900', color: '#ffdf4a', stroke: '#000', strokeThickness: 7 }).setOrigin(0.5));
      const die = add(this.add.image(W / 2, 320, 'item_dice'));
      die.setScale(200 / die.width);
      const num = add(this.add.text(W / 2, 470, '', { fontFamily: 'Cinzel', fontSize: '64px', fontStyle: '900', color: '#ffffff', stroke: '#000', strokeThickness: 8 }).setOrigin(0.5));
      this.tweens.add({ targets: die, angle: 720, duration: 1100, ease: 'Cubic.out' });
      Sfx.play('diceRoll');
      let ticks = 0;
      const flick = this.time.addEvent({ delay: 70, repeat: 14, callback: () => { num.setText(String(Phaser.Math.Between(1, 6))); ticks += 1; } });
      this.time.delayedCall(1150, async () => {
        flick.remove();
        const n = Phaser.Math.Between(1, 6);
        num.setText(String(n));
        Sfx.play(n === 6 ? 'sparkle' : n === 1 ? 'miss' : 'pop');
        this.tweens.add({ targets: num, scale: { from: 1.6, to: 1 }, duration: 250, ease: 'Back.out' });
        const outcome = { 1: 'Crashed out on himself…', 2: 'Mild crash out.', 3: 'Mild crash out.', 4: 'Big crash out!', 5: 'Big crash out!', 6: 'MAXIMUM CRASH OUT!' }[n];
        const sub = add(this.add.text(W / 2, 530, outcome, { fontFamily: 'Nunito', fontSize: '24px', fontStyle: '900', color: '#f3e3b0', stroke: '#000', strokeThickness: 5 }).setOrigin(0.5));
        await this.wait(900);
        let result = n;
        if (n === 6 && !this.registry.get('used67')) {
          sub.setText('…a 6. You could add +1. Once per game.');
          const opts = [{ label: '+1 (make it a 7)', desc: 'Do the 6-7. Only once in the entire game.' }, { label: 'Nah, keep the 6', desc: 'Save it.' }];
          [this.menuTitle, ...this.menuTexts].forEach((t) => t.setDepth(98));
          const choice = await this.menu('+1?', opts, false);
          [this.menuTitle, ...this.menuTexts].forEach((t) => t.setDepth(82));
          this.clearMenu();
          if (choice === 0) { result = 7; num.setText('7'); Sfx.play('choir'); this.registry.set('used67', true); Outcomes.unlock('c_67'); await this.wait(500); }
          else { this.registry.set('declined67', true); Outcomes.unlock('c_no67'); }
        }
        ui.forEach((o) => o.destroy());
        resolve(result);
      });
    });
  }

  async sixSeven() {
    // The whole party does the 6-7 dance → 67 damage to every enemy
    const big = this.add.text(W / 2, 250, '6 - 7', { fontFamily: 'Cinzel', fontSize: '120px', fontStyle: '900', color: '#ffdf4a', stroke: '#000', strokeThickness: 10 })
      .setOrigin(0.5).setDepth(98);
    this.tweens.add({ targets: big, scale: { from: 0.9, to: 1.15 }, yoyo: true, repeat: 5, duration: 220 });
    for (let beat = 0; beat < 8; beat++) {
      this.party.forEach((p, i) => { if (p.hp > 0) this.tweens.add({ targets: p.sprite.img, y: -26, angle: (beat + i) % 2 ? 10 : -10, yoyo: true, duration: 140 }); });
      Sfx.play('dance');
      this.cameras.main.shake(120, 0.008);
      await this.wait(280);
    }
    await this.wait(200);
    this.settle();
    big.destroy();
    for (const e of this.alive(this.enemies)) await this.hitEnemy(e, 67, `The party does the 6-7 on ${e.name}!`);
  }

  // ======================= Allies & enemies =======================
  async allyAssist() {
    const targets = this.alive(this.enemies);
    if (!targets.length || !this.allies.length) return;
    const g = Phaser.Utils.Array.GetRandom(this.allies);
    const t = Phaser.Utils.Array.GetRandom(targets);
    await this.tweenP({ targets: g, x: g.x + 50, yoyo: true, duration: 140 });
    await this.hitEnemy(t, 6, `Goblin backup bonks ${t.name} with a spoon!`, 'bonk');
  }

  async enemyTurn(e) {
    if (e.status.stun > 0) { Sfx.play('miss'); e.status.stun -= 1; this.refresh(); await this.say(`${e.name} is being sat on and can't move.`, 1100); return; }
    if (e.status.charm > 0) { Sfx.play('sparkle'); e.status.charm -= 1; this.refresh(); await this.say(`${e.name} is too busy staring at Lykor's hair.`, 1100); return; }
    if (this.mods.enemyTripping && Math.random() < 0.3) {
      if (Math.random() < 0.5) { await this.hitEnemy(e, 10, `${e.name} punches a rock that insulted him.`, 'stomp'); }
      else await this.say(`${e.name} yells "WHY IS THE SKY SO LOUD" and forgets to attack.`, 1500);
      return;
    }
    const mult = this.mods.enraged ? 1.2 : 1;
    const targets = this.alive(this.party);
    const pick = () => Phaser.Utils.Array.GetRandom(targets);

    // Blind: the next attack may miss
    const blindMiss = () => {
      if (e.status.blind > 0) { e.status.blind -= 1; this.refresh(); if (Math.random() < 0.6) return true; }
      return false;
    };

    await this.tweenP({ targets: e.sprite, x: e.sprite.x - 40, yoyo: true, duration: 150 });

    if (e.ai === 'goblin') {
      if (blindMiss()) { Sfx.play('miss'); await this.say(`${e.name} swings his spoon at nothing. Blinded.`, 1100); return; }
      const t = pick();
      Sfx.play('bonk');
      await this.hurtParty(t, Math.round(6 * mult), `${e.name} bonks ${t.P.name} with a spoon!`);
      return;
    }

    if (e.ai === 'dulbers') {
      const r = Math.random();
      if (e.hp < e.maxHp * 0.55 && r < 0.3) {
        const heal = 15; e.hp = Math.min(e.maxHp, e.hp + heal);
        this.floatText(e.sprite.x, e.sprite.y - e.h * 0.7, `+${heal}`, '#7dff8a'); this.refresh(); Sfx.play('heal');
        await this.say('Dulbers uses his customer service voice: "Thank you for shopping at Metocy Mart!" (+15)', 1600);
        return;
      }
      if (blindMiss()) { Sfx.play('miss'); await this.say('Dulbers tries to price-gouge someone but can\'t see who. Blinded.', 1300); return; }
      if (r < 0.62) {
        const t = pick(); Sfx.play('slap');
        await this.hurtParty(t, Math.round(28 * mult), `Dulbers price-gouges ${t.P.name}! "That'll be 28 HP, plus tax."`);
      } else {
        Sfx.play('roar');
        await this.say('Dulbers screams "NO REFUNDS!" It hurts everyone\'s ears.', 900);
        for (const t of this.alive(this.party)) await this.hurtParty(t, Math.round(18 * mult), null);
      }
      return;
    }

    if (e.ai === 'giant') {
      e.turn += 1;
      if (e.sitPending) {
        e.sitPending = false;
        Sfx.play('sitImpact'); this.cameras.main.shake(1100, 0.03);
        await this.say('DIDDY CHUD SITS ON EVERYONE!', 900);
        for (const t of this.alive(this.party)) await this.hurtParty(t, Math.round(40 * mult), null, true);
        this.setTex(e.sprite, e.tex);
        this.refresh();
        return;
      }
      if (e.turn % 3 === 0) {
        e.sitPending = true;
        this.setTex(e.sprite, e.sitTex);
        Sfx.play('sitWarn');
        this.refresh();
        await this.say('Diddy Chud Giant is getting ready to SIT. (Defend!)', 1500);
        return;
      }
      if (blindMiss()) { Sfx.play('stomp'); await this.say('Diddy Chud stomps… the wrong spot. Blinded.', 1200); return; }
      if (e.turn % 2) {
        const t = pick();
        Sfx.play('stomp'); this.cameras.main.shake(400, 0.014);
        await this.hurtParty(t, Math.round(22 * mult), `Diddy Chud stomps on ${t.P.name}!`);
      } else {
        Sfx.play('stomp'); this.time.delayedCall(250, () => Sfx.play('stomp')); this.cameras.main.shake(700, 0.018);
        await this.say('Diddy Chud pounds the ground!', 800);
        for (const t of this.alive(this.party)) await this.hurtParty(t, Math.round(15 * mult), null);
      }
    }
  }

  async hurtParty(m, dmg, line, isSit = false) {
    if (m.defending) dmg = Math.round(dmg * (isSit ? 0.25 : 0.5));
    m.hp = Math.max(0, m.hp - dmg);
    Sfx.play('hurt');
    this.setTex(m.sprite, m.P.hurt);
    this.tweens.add({ targets: m.sprite, x: m.sprite.x - 12, yoyo: true, repeat: 2, duration: 50 });
    this.floatText(m.sprite.x, m.sprite.y - m.P.h * 0.7, `-${dmg}`, '#ff6a5a');
    this.refresh();
    if (line) await this.say(`${line} (-${dmg}${m.defending ? ', defended' : ''})`, 1100);
    else await this.wait(350);
    if (m.hp <= 0) {
      await this.tweenP({ targets: m.sprite, alpha: 0.3, angle: -10, duration: 400 });
      await this.say(`${m.P.name} is down bad.`, 900);
    } else {
      this.setTex(m.sprite, m.idleTex);
    }
  }

  // ======================= Endings =======================
  async victory() {
    this.clearMenu();
    Sfx.play('victory');
    const xp = this.def.xp;
    const total = (this.registry.get('xp') || 0) + xp;
    this.registry.set('xp', total);
    let lvl = this.level;
    while (LEVELS[lvl + 1] !== undefined && total >= LEVELS[lvl + 1]) lvl += 1;
    const leveled = lvl > this.level;
    this.registry.set('level', lvl);
    const ui = [
      this.add.rectangle(0, 0, W, H, 0x000000, 0.6).setOrigin(0),
      this.add.text(W / 2, 230, 'VICTORY', { fontFamily: 'Cinzel', fontSize: '84px', fontStyle: '900', color: '#ffdf4a', stroke: '#000', strokeThickness: 10 }).setOrigin(0.5),
      this.add.text(W / 2, 310, '(on some winning shi)', { fontFamily: 'Nunito', fontSize: '24px', color: '#f3e3b0' }).setOrigin(0.5),
      this.add.text(W / 2, 380, `+${xp} XP`, { fontFamily: 'Cinzel', fontSize: '34px', fontStyle: '900', color: '#7dff8a', stroke: '#000', strokeThickness: 6 }).setOrigin(0.5),
    ];
    if (leveled) ui.push(this.add.text(W / 2, 440, `LEVEL UP! The party is now Level ${lvl}`, { fontFamily: 'Cinzel', fontSize: '28px', fontStyle: '900', color: '#ffdf4a', stroke: '#000', strokeThickness: 6 }).setOrigin(0.5));
    ui.push(this.add.text(W / 2, 540, 'Press SPACE to continue', { fontFamily: 'Nunito', fontSize: '20px', color: '#a49cc4' }).setOrigin(0.5));
    ui.forEach((o) => o.setDepth(99));
    await this.wait(700);
    this.handler = (ev) => { if (ev.key === 'ok') { this.handler = null; this.end('win'); } };
    this.input.once('pointerdown', () => { if (this.handler) { this.handler = null; this.end('win'); } });
  }

  async defeat() {
    this.clearMenu();
    Sfx.play('defeat');
    Outcomes.unlock('c_cooked');
    [
      this.add.rectangle(0, 0, W, H, 0x000000, 0.7).setOrigin(0),
      this.add.text(W / 2, 260, 'YOU GOT COOKED', { fontFamily: 'Cinzel', fontSize: '76px', fontStyle: '900', color: '#ff6a4a', stroke: '#000', strokeThickness: 10 }).setOrigin(0.5),
      this.add.text(W / 2, 340, '(on some losing shi)', { fontFamily: 'Nunito', fontSize: '24px', color: '#f3e3b0' }).setOrigin(0.5),
      this.add.text(W / 2, 460, 'Press SPACE to try again', { fontFamily: 'Nunito', fontSize: '22px', color: '#a49cc4' }).setOrigin(0.5),
    ].forEach((o) => o.setDepth(99));
    await this.wait(700);
    const retry = () => { this.handler = null; this.scene.restart(this.cfg); };
    this.handler = (ev) => { if (ev.key === 'ok') retry(); };
    this.input.once('pointerdown', () => { if (this.handler) retry(); });
  }

  end(result) {
    this.cameras.main.fade(400, 0, 0, 0, true);
    this.cameras.main.once('camerafadeoutcomplete', () => {
      const done = this.cfg.onDone;
      this.scene.stop();
      if (done) done(result);
    });
  }
}
