import { PARTY, COMBOS, ITEMS, STATUS, LEVELS, DIFFICULTY } from '../data/combat.js';
import { Battle } from '../combat/engine.js';
import { vignette } from '../fx.js';
import Sfx from '../audio/Sfx.js';
import Voice from '../audio/Voice.js';
import Settings from '../systems/settings.js';
import Outcomes from '../systems/outcomes.js';

// Turn-based combat (Combat 2.0), launched on top of a story scene (which pauses until the fight ends).
//
//   this.scene.launch('Combat', { fight: 'giant', mods: { enraged: true }, bg: 'bg_mountain_path', onDone })
//
// mods: tripping: 'party' | 'skorn'  — midtocy misfires/crits
//       allies: true                  — goblin backup joins the turn order
//       enemyTripping: true           — the enemy sometimes hurts itself
//       enraged: true                 — the enemy has more HP and hits harder
//       party: [...]                  — override who fights
//
// The rules live in src/combat/engine.js. This scene asks the engine what happens and animates it:
// a speed-based turn-order bar, timed hits and blocks (shrinking ring, SPACE), ultimate meters,
// team-up combos, statuses, banter, rare chaos events and an end-of-fight grade.
//
// Testing hooks: window.TRIO_QTE = 'perfect' | 'good' | 'mid' resolves every timed press instantly.
const W = 1280, H = 720;
const UI_TOP = 566;
const VOICE_ID = { goblin: 'goblin', dulbers: 'dulbers_demon', giant: 'giant' };

export default class CombatScene extends Phaser.Scene {
  constructor() { super('Combat'); }

  init(cfg) { this.cfg = cfg; }

  create() {
    const { fight, mods = {}, bg } = this.cfg;
    this.mods = mods;
    this.level = this.registry.get('level') || 1;
    this.handler = null;
    this.diff = DIFFICULTY[Settings.combatDiff] || DIFFICULTY[1];

    // Items as they were when the fight started (a retry after losing gets them back)
    if (!this.cfg.startInv) this.cfg.startInv = { beer: this.registry.get('inv_beer') || 0, bowl: this.registry.get('inv_bowl') || 0 };
    this.registry.set('inv_beer', this.cfg.startInv.beer);
    this.registry.set('inv_bowl', this.cfg.startInv.bowl);
    this.battle = new Battle({
      fight, mods, level: this.level, difficulty: Settings.combatDiff,
      inv: { beer: this.registry.get('inv_beer') || 0, bowl: this.registry.get('inv_bowl') || 0 },
      used67: !!this.registry.get('used67'),
    });
    const B = this.battle;
    this.def = B.def;

    // ---------- Backdrop ----------
    if (bg && this.textures.exists(bg)) {
      const img = this.add.image(W / 2, H / 2, bg);
      img.setScale(Math.max(W / img.width, H / img.height) * 1.05);
    }
    this.add.rectangle(0, 0, W, H, 0x0a0612, 0.45).setOrigin(0);
    vignette(this, 1);

    // ---------- Party ----------
    const pxs = { 1: [330], 2: [250, 470], 3: [170, 345, 520] }[B.party.length];
    this.party = B.party;
    this.party.forEach((m, i) => {
      m.shown = m.hp;
      m.idleTex = m.tripping ? `char_${m.id}_tweaking` : m.P.tex;
      m.sprite = this.makeSprite(pxs[i], 556, m.idleTex, m.P.h, false);
      m.h = m.P.h;
    });

    // ---------- Enemies ----------
    const exs = { 1: [960], 2: [870, 1080], 3: [800, 985, 1165] }[B.enemies.length];
    this.enemies = B.enemies;
    this.enemies.forEach((e, i) => {
      const E = e.E;
      e.shown = e.hp;
      e.h = E.h;
      const feet = E.ai === 'giant' ? 610 : 560;
      e.sprite = this.makeSprite(exs[i], feet, E.tex, E.h, false);
      e.sprite.setInteractive(new Phaser.Geom.Rectangle(-80, -E.h, 160, E.h), Phaser.Geom.Rectangle.Contains);
      e.sprite.on('pointerdown', () => this.handler && this.handler({ click: 'unit', u: e }));
      e.sprite.on('pointerover', () => this.handler && this.handler({ hover: 'unit', u: e }));
      const top = Math.max(150, feet - E.h - 34);
      e.nameText = this.add.text(exs[i], top - 18, `${e.name} ${e.tag}`, {
        fontFamily: 'Nunito', fontSize: B.enemies.length > 2 ? '13px' : '16px', fontStyle: '900', color: '#1a1324', backgroundColor: '#f3e3b0', padding: { x: 6, y: 1 },
      }).setOrigin(0.5).setDepth(50);
      this.add.rectangle(exs[i] - 80, top + 6, 160, 12, 0x1a1324).setOrigin(0, 0.5).setStrokeStyle(2, 0xe8b923).setDepth(50);
      e.hpBar = this.add.rectangle(exs[i] - 78, top + 6, 156, 8, 0xd8403a).setOrigin(0, 0.5).setDepth(50);
      e.statusText = this.add.text(exs[i], top + 26, '', {
        fontFamily: 'Nunito', fontSize: '13px', fontStyle: '900', color: '#ffdf8a', stroke: '#000', strokeThickness: 3, align: 'center', wordWrap: { width: 260 },
      }).setOrigin(0.5, 0).setDepth(50);
      if (mods.enemyTripping) e.sprite.img.setTint(0xd8b0ff);
    });

    // ---------- Goblin backup ----------
    this.allySprites = [];
    if (mods.allies) {
      [[60, 560, 150], [640, 566, 140]].forEach(([x, y, h]) => this.allySprites.push(this.makeSprite(x, y, 'char_goblin_fight', h, true)));
    }

    this.buildUI();
    this.setupInput();
    this.events.once('shutdown', () => { this.input.keyboard.removeAllListeners(); Voice.stop?.(); });
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

  settle() {
    [...this.party, ...this.enemies].forEach((u) => {
      const c = u.sprite;
      this.tweens.killTweensOf(c);
      c.setPosition(c.homeX, u.hp > 0 ? c.homeY : c.y);
      if (u.hp > 0) c.setAngle(0);
      this.tweens.getTweensOf(c.img).forEach((t) => { if (t !== c.breath) t.stop(); });
      c.img.setY(0).setAngle(0);
    });
    this.allySprites.forEach((c) => { this.tweens.killTweensOf(c); c.setPosition(c.homeX, c.homeY); });
  }

  tweenP(cfg) { return new Promise((res) => this.tweens.add({ ...cfg, onComplete: res })); }
  wait(ms) { return new Promise((res) => this.time.delayedCall(ms, res)); }
  alive(list) { return list.filter((x) => x.hp > 0); }
  headY(u) { return u.sprite.y - u.h; }
  midY(u) { return u.sprite.y - u.h * 0.55; }

  buildUI() {
    this.msgBg = this.add.rectangle(W / 2, 34, 1000, 46, 0x120e1e, 0.9).setStrokeStyle(2, 0xe8b923).setDepth(90);
    this.msg = this.add.text(W / 2, 34, '', { fontFamily: 'Nunito', fontSize: '20px', fontStyle: '700', color: '#f4efff', align: 'center', wordWrap: { width: 970 } }).setOrigin(0.5).setDepth(91);

    const g = this.add.graphics().setDepth(80);
    g.fillGradientStyle(0x1d1633, 0x1d1633, 0x0b0812, 0x0b0812, 0.95).fillRect(0, UI_TOP, W, H - UI_TOP);
    g.lineStyle(3, 0xe8b923, 1).lineBetween(0, UI_TOP, W, UI_TOP);
    g.lineStyle(1, 0xe8b923, 0.4).lineBetween(780, UI_TOP + 12, 780, H - 12);

    // Party cards: name, HP, meter, statuses
    this.cards = this.party.map((m, i) => {
      const x = 16 + i * 254, y = UI_TOP + 12;
      const box = this.add.rectangle(x, y, 244, 132, 0x000000, 0.25).setOrigin(0).setStrokeStyle(2, 0x5a4a7a).setDepth(81);
      const por = this.add.image(x + 34, y + 36, `portrait_${m.id}`).setDisplaySize(54, 54).setDepth(82);
      this.add.text(x + 68, y + 8, m.P.name, { fontFamily: 'Cinzel', fontSize: '20px', fontStyle: '900', color: '#f3e3b0' }).setDepth(82);
      this.add.text(x + 68, y + 34, m.P.hpLabel, { fontFamily: 'Nunito', fontSize: '12px', fontStyle: '900', color: '#a49cc4' }).setDepth(82);
      const num = this.add.text(x + 232, y + 56, '', { fontFamily: 'Nunito', fontSize: '14px', fontStyle: '900', color: '#f4efff' }).setOrigin(1, 0.5).setDepth(83);
      this.add.rectangle(x + 12, y + 74, 220, 14, 0x1a1324).setOrigin(0, 0.5).setStrokeStyle(2, 0xe8b923).setDepth(82);
      const bar = this.add.rectangle(x + 14, y + 74, 216, 10, 0x5ad86a).setOrigin(0, 0.5).setDepth(83);
      const mlabel = this.add.text(x + 12, y + 86, '', { fontFamily: 'Nunito', fontSize: '11px', fontStyle: '900', color: '#c9a8ff' }).setDepth(83);
      this.add.rectangle(x + 12, y + 104, 220, 9, 0x1a1324).setOrigin(0, 0.5).setStrokeStyle(1, 0x8a6ad8).setDepth(82);
      const meter = this.add.rectangle(x + 13, y + 104, 218, 7, 0x9a6bff).setOrigin(0, 0.5).setDepth(83);
      const st = this.add.text(x + 12, y + 112, '', { fontFamily: 'Nunito', fontSize: '12px', fontStyle: '900', color: '#ffdf8a', wordWrap: { width: 228 } }).setDepth(83);
      const glow = this.add.rectangle(x, y, 244, 132).setOrigin(0).setStrokeStyle(3, 0xffdf4a).setDepth(84).setVisible(false);
      this.tweens.add({ targets: glow, alpha: 0.25, yoyo: true, repeat: -1, duration: 450 });
      return { box, bar, num, st, por, meter, mlabel, glow };
    });
    if (this.party.length === 1) {
      this.add.text(290, UI_TOP + 24, `Level ${this.level}`, { fontFamily: 'Cinzel', fontSize: '20px', color: '#e8b923' }).setDepth(82);
      this.add.text(290, UI_TOP + 54, `Difficulty: ${this.diff.name}`, { fontFamily: 'Nunito', fontSize: '15px', color: '#a49cc4' }).setDepth(82);
    }

    // Command menu (6 rows)
    this.menuTitle = this.add.text(800, UI_TOP + 8, '', { fontFamily: 'Cinzel', fontSize: '17px', fontStyle: '900', color: '#e8b923' }).setDepth(82);
    this.menuTexts = [];
    for (let i = 0; i < 6; i++) {
      const t = this.add.text(810, UI_TOP + 32 + i * 20, '', { fontFamily: 'Nunito', fontSize: '17px', fontStyle: '900', color: '#f4efff' })
        .setDepth(82).setInteractive({ useHandCursor: true });
      t.on('pointerover', () => this.handler && this.handler({ hover: 'menu', i }));
      t.on('pointerdown', () => this.handler && this.handler({ click: 'menu', i }));
      this.menuTexts.push(t);
    }

    // Turn order bar
    this.add.text(24, 66, 'TURN ORDER', { fontFamily: 'Cinzel', fontSize: '13px', fontStyle: '900', color: '#e8b923', stroke: '#000', strokeThickness: 4 }).setDepth(89);
    this.timeline = this.add.container(0, 0).setDepth(89);
    this.refresh();
  }

  // Redraw the upcoming turns (current actor first, bigger)
  drawTimeline(current) {
    this.timeline.removeAll(true);
    const list = [{ u: current, skip: false, now: true }, ...this.battle.preview(7)];
    let x = 24;
    list.forEach((s, i) => {
      const size = i === 0 ? 58 : 44;
      const y = 86 + (i === 0 ? 0 : 7);
      const col = s.u.side === 'party' ? 0x4a8aff : s.u.side === 'ally' ? 0x5aa83c : 0xd8403a;
      const tex = s.u.side === 'party' ? `portrait_${s.u.id}` : s.u.side === 'ally' ? 'portrait_goblin' : s.u.E.portrait;
      const bg = this.add.rectangle(x, y, size, size, 0x120e1e, 0.92).setOrigin(0).setStrokeStyle(i === 0 ? 4 : 2, i === 0 ? 0xe8b923 : col);
      this.timeline.add(bg);
      if (this.textures.exists(tex)) this.timeline.add(this.add.image(x + size / 2, y + size / 2, tex).setDisplaySize(size - 6, size - 6));
      this.timeline.add(this.add.rectangle(x, y + size - 5, size, 5, col).setOrigin(0));
      if (s.skip) {
        this.timeline.add(this.add.rectangle(x, y, size, size, 0x000000, 0.55).setOrigin(0));
        this.timeline.add(this.add.text(x + size / 2, y + size / 2, 'SKIP', { fontFamily: 'Nunito', fontSize: '13px', fontStyle: '900', color: '#ff6a5a', stroke: '#000', strokeThickness: 3 }).setOrigin(0.5));
      }
      if (i === 0) this.timeline.add(this.add.text(x + size / 2, y + size + 4, 'NOW', { fontFamily: 'Nunito', fontSize: '11px', fontStyle: '900', color: '#e8b923', stroke: '#000', strokeThickness: 3 }).setOrigin(0.5, 0));
      x += size + 6;
    });
  }

  statusTags(u) {
    return Object.keys(u.st).filter((k) => STATUS[k] && (k !== 'shield' || u.st[k] > 0)).map((k) => (k === 'shield' ? `SHIELD ${u.st[k]}` : STATUS[k].label));
  }

  refresh() {
    const B = this.battle;
    this.party.forEach((m, i) => {
      const c = this.cards[i];
      const f = Math.max(0, m.shown) / m.maxHp;
      c.bar.width = 216 * f;
      c.bar.fillColor = f > 0.5 ? 0x5ad86a : f > 0.25 ? 0xe8c43a : 0xd8403a;
      c.num.setText(`${Math.max(0, m.shown)}/${m.maxHp}`);
      c.meter.width = 218 * m.meter / 100;
      c.meter.fillColor = m.meter >= 100 ? 0xffdf4a : 0x9a6bff;
      c.mlabel.setText(m.meter >= 100 ? `${m.P.meterLabel}: ULTIMATE READY` : `${m.P.meterLabel} ${m.meter}%`);
      c.glow.setVisible(m.meter >= 100 && m.hp > 0);
      const tags = [];
      if (m.hp <= 0) tags.push('KNOCKED OUT');
      if (m.defending) tags.push('DEFENDING');
      if (B.hype > 0 && m.hp > 0) tags.push(`HYPED ×${B.hype}`);
      if (m.tripping) tags.push('TWEAKING');
      tags.push(...this.statusTags(m));
      if (m.cds.special > 0 && m.st.bricked) tags.push('BRICKED');
      c.st.setText([...new Set(tags)].join(' · '));
      c.por.setAlpha(m.hp > 0 ? 1 : 0.35);
    });
    this.enemies.forEach((e) => {
      e.hpBar.width = 156 * Math.max(0, e.shown) / e.maxHp;
      const s = e.shown > 0 ? this.statusTags(e) : [];
      if (e.sitPending) s.push('ABOUT TO SIT — DEFEND/BLOCK!');
      if (e.eatPending) s.push('ABOUT TO EAT — HIT HIM 30+!');
      e.statusText.setText(s.join(' · '));
    });
    this.registry.set('inv_beer', B.inv.beer);
    this.registry.set('inv_bowl', B.inv.bowl);
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

  // Speech bubble + TTS voice
  bubble(u, line) {
    let x = Phaser.Math.Clamp(u.sprite.x, 130, W - 130);
    let y = Math.max(170, this.headY(u) - 20);
    if (u.side === 'enemy' && this.headY(u) < 220) { x = u.sprite.x - 250; y = 390; } // giant-sized: talk from the side
    const t = this.add.text(x, y, line, { fontFamily: 'Nunito', fontSize: '17px', fontStyle: '900', color: '#1a1324', align: 'center', wordWrap: { width: 230 } }).setOrigin(0.5, 1).setDepth(94);
    const bg = this.add.rectangle(x, y + 6, t.width + 22, t.height + 14, 0xfffbea).setOrigin(0.5, 1).setStrokeStyle(3, 0x1a1324).setDepth(93);
    const tail = this.add.triangle(x, y + 14, -8, 0, 8, 0, 0, 12, 0xfffbea).setDepth(93);
    [t, bg, tail].forEach((o) => { o.setScale(0.6); this.tweens.add({ targets: o, scale: 1, duration: 160, ease: 'Back.out' }); });
    this.time.delayedCall(1900, () => this.tweens.add({ targets: [t, bg, tail], alpha: 0, duration: 250, onComplete: () => [t, bg, tail].forEach((o) => o.destroy()) }));
    Voice.say(u.id || VOICE_ID[u.ai] || 'narrator', line);
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
    this.input.on('pointerdown', () => { if (this.handler) this.handler({ tap: true }); });
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
            .setColor(o.disabled ? '#6e6690' : i === sel ? '#e8b923' : o.hot ? '#ffdf4a' : '#f4efff');
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

  // Pick a unit (left/right). Resolves the unit or null for back.
  pickTarget(list, label, describe) {
    return new Promise((resolve) => {
      if (list.length === 1) { resolve(list[0]); return; }
      let sel = 0;
      const arrow = this.add.text(0, 0, '▼', { fontFamily: 'Nunito', fontSize: '34px', color: '#e8b923', stroke: '#000', strokeThickness: 5 }).setOrigin(0.5).setDepth(96);
      const bob = this.tweens.add({ targets: arrow, y: '+=8', yoyo: true, repeat: -1, duration: 300 });
      const place = () => {
        const t = list[sel];
        arrow.setPosition(t.sprite.x, Math.max(130, this.headY(t) - 50));
        this.msg.setText(`${label}: ${t.name}${describe ? describe(t) : ''}   (←/→, ENTER · ESC to go back)`);
      };
      const done = (v) => { bob.stop(); arrow.destroy(); this.handler = null; resolve(v); };
      this.handler = (ev) => {
        if (ev.key === 'left') { sel = (sel + list.length - 1) % list.length; Sfx.play('tick'); place(); }
        else if (ev.key === 'right') { sel = (sel + 1) % list.length; Sfx.play('tick'); place(); }
        else if (ev.key === 'ok') { Sfx.play('confirm'); done(list[sel]); }
        else if (ev.key === 'back') done(null);
        else if (ev.hover === 'unit' && list.includes(ev.u)) { sel = list.indexOf(ev.u); place(); }
        else if (ev.click === 'unit' && list.includes(ev.u)) { Sfx.play('confirm'); done(ev.u); }
      };
      place();
    });
  }

  // ======================= Timed hits / blocks =======================
  // A ring shrinks onto a gold circle. Press SPACE (or click) when they line up.
  // Resolves 'perfect' | 'good' | 'mid'.
  qte(x, y, prompt, dur = 850) {
    if (!Settings.timedHits) return Promise.resolve('good');
    if (typeof window !== 'undefined' && window.TRIO_QTE) return Promise.resolve(window.TRIO_QTE);
    return new Promise((resolve) => {
      const R = 46;
      const win = this.diff.window;
      const perfectW = 8 * win, goodW = 22 * win;
      const g = this.add.graphics().setDepth(97);
      const label = this.add.text(x, y - R - 70, prompt, { fontFamily: 'Cinzel', fontSize: '22px', fontStyle: '900', color: '#ffdf4a', stroke: '#000', strokeThickness: 6 }).setOrigin(0.5).setDepth(97);
      const st = { r: 170 };
      let done = false;
      const draw = () => {
        g.clear();
        g.fillStyle(0x000000, 0.35).fillCircle(x, y, R + goodW);
        g.lineStyle(goodW * 2, 0x7dff8a, 0.18).strokeCircle(x, y, R);
        g.lineStyle(4, 0xe8b923, 1).strokeCircle(x, y, R);
        const d = Math.abs(st.r - R);
        g.lineStyle(5, d <= perfectW ? 0xffdf4a : d <= goodW ? 0x7dff8a : 0xffffff, 1).strokeCircle(x, y, Math.max(1, st.r));
      };
      const finish = (res) => {
        if (done) return; done = true;
        tw.stop(); this.handler = null;
        Sfx.play(res === 'perfect' ? 'perfect' : res === 'good' ? 'good' : 'miss');
        const col = { perfect: '#ffdf4a', good: '#7dff8a', mid: '#a49cc4' }[res];
        label.setText({ perfect: 'PERFECT!', good: 'GOOD', mid: 'MID' }[res]).setColor(col).setScale(1.3);
        this.tweens.add({ targets: label, scale: 1, duration: 200 });
        if (res === 'perfect') this.burst(x, y, [0xffdf4a, 0xffffff], 24, 220);
        this.time.delayedCall(320, () => { g.destroy(); label.destroy(); resolve(res); });
      };
      Sfx.play('ring');
      const tw = this.tweens.add({
        targets: st, r: R - goodW - 6, duration: dur, ease: 'Linear',
        onUpdate: draw,
        onComplete: () => finish('mid'),
      });
      draw();
      this.time.delayedCall(60, () => {
        if (done) return;
        this.handler = (ev) => {
          if (ev.key !== 'ok' && !ev.tap) return;
          const d = Math.abs(st.r - R);
          finish(d <= perfectW ? 'perfect' : d <= goodW ? 'good' : 'mid');
        };
      });
    });
  }

  // ======================= Battle flow =======================
  async runBattle() {
    const B = this.battle;
    const ban = this.add.text(W / 2, 290, this.def.title, {
      fontFamily: 'Cinzel', fontSize: '52px', fontStyle: '900', color: '#ff6a4a', stroke: '#000', strokeThickness: 8,
    }).setOrigin(0.5).setDepth(99).setScale(0.4).setAlpha(0);
    Sfx.play('boom'); this.cameras.main.shake(300, 0.01);
    await this.tweenP({ targets: ban, scale: 1, alpha: 1, duration: 450, ease: 'Back.out' });
    await this.wait(900);
    this.tweens.add({ targets: ban, alpha: 0, duration: 400, onComplete: () => ban.destroy() });
    if (this.mods.tripping === 'party') await this.say('Everyone is still tweaking. Moves might misfire… or CRIT.', 1600);
    if (this.mods.tripping === 'skorn') await this.say('Skorn is still tweaking. He might misfire… or CRIT.', 1500);
    if (this.mods.allies) await this.say('Goblin backup is here! (They\'re in the turn order now.)', 1400);

    await this.tutorial();

    for (;;) {
      const res = B.result();
      if (res === 'win') return this.victory();
      if (res === 'lose') return this.defeat();
      this.settle();
      const turn = B.nextActor();
      const u = turn.u;
      this.drawTimeline(u);
      this.refresh();
      await this.play(turn.events);
      if (turn.skip || B.result()) { this.refresh(); continue; }

      if (u.side === 'party') await this.partyTurn(u);
      else if (u.side === 'enemy') await this.enemyTurn(u);
      else { await this.play(B.allyAct(u)); }
      this.refresh();
    }
  }

  tutorial() {
    let seen = false;
    try { seen = localStorage.getItem('trio_tut_combat2') === '1'; } catch (e) { /* blocked */ }
    if (seen) return Promise.resolve();
    return new Promise((resolve) => {
      const ui = [];
      const add = (o) => { ui.push(o.setDepth(97)); return o; };
      add(this.add.rectangle(0, 0, W, H, 0x000000, 0.75).setOrigin(0));
      add(this.add.rectangle(W / 2, 330, 980, 560, 0x120e1e, 0.97).setStrokeStyle(3, 0xe8b923));
      add(this.add.text(W / 2, 78, 'How To Fight (on some combat shi)', { fontFamily: 'Cinzel', fontSize: '32px', fontStyle: '900', color: '#e8b923' }).setOrigin(0.5));
      const lines = [
        ['Turn order', 'Top left shows who goes next. Faster characters get more turns. Stuns push enemies back.'],
        ['Timed hits', 'When the ring shrinks onto the gold circle, press SPACE. PERFECT = 1.5× damage.'],
        ['Timed blocks', 'Same ring when an enemy attacks you. A PERFECT block takes way less damage.'],
        ['Meter', 'Hitting, timed presses, blocking and defending fill it. Full = ULTIMATE. Half = team-up combos.'],
        ['Special / Bonus', 'Big moves on a cooldown. They grey out for a few turns after you use them.'],
        ['Defend', 'Half damage, enemies aim at you, builds meter and speeds up your cooldowns.'],
        ['Items', 'Beezy heals 30 (and makes you Buzzed). Chipotle Bowl heals 60. Both revive knocked-out allies.'],
        ['Bosses', 'They get LOCKED IN after a charm/stun, telegraph big moves, and change at half HP.'],
      ];
      lines.forEach(([k, v], i) => {
        add(this.add.text(W / 2 - 460, 122 + i * 58, k, { fontFamily: 'Cinzel', fontSize: '20px', fontStyle: '900', color: '#f3e3b0' }));
        add(this.add.text(W / 2 - 270, 124 + i * 58, v, { fontFamily: 'Nunito', fontSize: '18px', color: '#f4efff', wordWrap: { width: 720 } }));
      });
      const go = add(this.add.text(W / 2, 590, 'You can change difficulty and turn timed presses off in Settings (O).  —  press ENTER to fight', { fontFamily: 'Nunito', fontSize: '17px', fontStyle: '900', color: '#a49cc4' }).setOrigin(0.5));
      this.tweens.add({ targets: go, alpha: 0.4, yoyo: true, repeat: -1, duration: 700 });
      const done = () => {
        this.handler = null;
        try { localStorage.setItem('trio_tut_combat2', '1'); localStorage.setItem('trio_tut_combat', '1'); } catch (e) { /* blocked */ }
        Sfx.play('confirm');
        ui.forEach((o) => o.destroy());
        resolve();
      };
      this.time.delayedCall(600, () => { this.handler = (ev) => { if (ev.key === 'ok' || ev.tap) done(); }; });
    });
  }

  // ======================= Party turn =======================
  async partyTurn(m) {
    const card = this.cards[this.party.indexOf(m)];
    card.box.setStrokeStyle(3, 0xe8b923);
    const arrow = this.add.text(m.sprite.x, this.headY(m) - 30, '▼', { fontFamily: 'Nunito', fontSize: '28px', color: '#e8b923', stroke: '#000', strokeThickness: 5 }).setOrigin(0.5).setDepth(96);
    const bob = this.tweens.add({ targets: arrow, y: '+=8', yoyo: true, repeat: -1, duration: 300 });
    const act = await this.chooseAction(m);
    bob.stop(); arrow.destroy(); card.box.setStrokeStyle(2, 0x5a4a7a);
    this.clearMenu();
    await this.performAction(m, act);
  }

  async chooseAction(m) {
    const B = this.battle;
    for (;;) {
      const o = B.options(m);
      const mv = m.P.moves;
      const cd = (slot) => (m.cds[slot] > 0 ? `  (${m.cds[slot]})` : '');
      const items = B.inv.beer + B.inv.bowl;
      const anyUlt = o.ult || o.combos.length > 0;
      const i = await this.menu(`What will ${m.name} do?`, [
        { label: mv.main.name, desc: mv.main.desc },
        { label: mv.special.name + cd('special'), desc: mv.special.desc, disabled: !o.special },
        { label: mv.bonus.name + cd('bonus'), desc: mv.bonus.desc, disabled: !o.bonus },
        { label: `★ Ultimate / Team-Up  ${m.meter}%`, hot: anyUlt, desc: anyUlt ? 'Something is ready. Open it.' : `Meter ${m.meter}%. Fill it by hitting, landing timed presses, blocking and defending. 100% = ultimate, 50% from two people = team-up.` },
        { label: `Items (${items})`, desc: items ? 'Beezy heals 30. Chipotle Bowl heals 60. Both can revive a knocked-out ally.' : 'No items left.', disabled: !items },
        { label: 'Defend', desc: 'Half damage until your next turn. Enemies aim at you. +meter, cooldowns tick faster.' },
      ], false);

      if (i <= 2) {
        const slot = ['main', 'special', 'bonus'][i];
        const move = mv[slot];
        if (move.kind === 'buff') return { type: 'move', slot };
        this.clearMenu();
        const target = await this.pickTarget(this.alive(this.enemies), move.name, (t) => this.enemyBlurb(t));
        if (!target) continue;
        return { type: 'move', slot, target };
      }
      if (i === 3) {
        Object.assign(o, B.options(m));
        const combos = COMBOS.filter((c) => c.who.includes(m.id) && c.who.every((id) => this.party.some((p) => p.id === id)));
        const opts = [{ key: 'ult', label: `${mv.ult.name}${o.ult ? '' : `  (${m.meter}%)`}`, desc: mv.ult.desc, disabled: !o.ult, hot: o.ult }];
        combos.forEach((c) => {
          const ok = o.combos.includes(c);
          const partners = c.who.filter((id) => id !== m.id).map((id) => PARTY[id].name).join(' + ');
          opts.push({ key: c, label: `${c.name} (w/ ${partners})`, desc: `${c.desc} Needs ${c.cost}% meter from everyone in it.`, disabled: !ok, hot: ok });
        });
        opts.push({ key: null, label: 'Back', desc: '' });
        const j = await this.menu('Ultimate / Team-Up', opts.slice(0, 6), true);
        if (j < 0 || !opts[j].key) continue;
        const pick = opts[j].key;
        if (pick === 'ult') {
          if (mv.ult.kind === 'mogsupreme') return { type: 'move', slot: 'ult' };
          this.clearMenu();
          const target = await this.pickTarget(this.alive(this.enemies), mv.ult.name, (t) => this.enemyBlurb(t));
          if (!target) continue;
          return { type: 'move', slot: 'ult', target };
        }
        this.clearMenu();
        const target = pick.aoe ? this.alive(this.enemies)[0] : await this.pickTarget(this.alive(this.enemies), pick.name, (t) => this.enemyBlurb(t));
        if (!target) continue;
        return { type: 'combo', combo: pick, target };
      }
      if (i === 4) {
        const opts = [];
        if (B.inv.beer) opts.push({ key: 'beer', label: `Beezy ×${B.inv.beer}`, desc: ITEMS.beer.desc });
        if (B.inv.bowl) opts.push({ key: 'bowl', label: `Chipotle Bowl ×${B.inv.bowl}`, desc: ITEMS.bowl.desc });
        opts.push({ key: null, label: 'Back', desc: '' });
        const j = await this.menu('Items', opts, true);
        if (j < 0 || !opts[j].key) continue;
        let target = m;
        if (this.party.length > 1) {
          this.clearMenu();
          target = await this.pickTarget(this.party, `Give ${ITEMS[opts[j].key].name} to`, (t) => (t.hp <= 0 ? ' (KNOCKED OUT — revive)' : ` (${t.hp}/${t.maxHp})`));
          if (!target) continue;
        }
        return { type: 'item', item: opts[j].key, target };
      }
      return { type: 'defend' };
    }
  }

  enemyBlurb(t) {
    const tags = this.statusTags(t);
    return ` (${t.hp}/${t.maxHp})${tags.length ? ' · ' + tags.join(', ') : ''}`;
  }

  async performAction(m, a) {
    const B = this.battle;
    if (a.type === 'defend') {
      this.tweens.add({ targets: m.sprite, x: m.sprite.x - 12, yoyo: true, duration: 120 });
      await this.play(B.partyAct(m, a));
      return;
    }
    if (a.type === 'item') { await this.play(B.partyAct(m, a)); return; }

    const opts = {};
    if (a.type === 'combo') {
      Sfx.play('combo');
      await this.comboIntro(a.combo, m);
      opts.timing = await this.qte(a.target.sprite.x, this.midY(a.target), 'TEAM-UP! SPACE!');
      await this.play(B.partyAct(m, a, opts));
      this.party.forEach((p) => this.unpose(p));
      return;
    }

    const move = m.P.moves[a.slot];
    const t = a.target;
    if (move.kind === 'crashout') {
      await this.pose(m, move.pose);
      Sfx.play('roar'); this.cameras.main.shake(900, 0.012);
      this.burst(m.sprite.x, m.sprite.y - m.h * 0.5, [0xff3a2a, 0xff8a2a], 40, 260);
      await this.say(`${m.name} is CRASHING OUT. Rolling the dice…`, 900);
      opts.roll = await this.rollDie();
      this.unpose(m);
      if (opts.roll > 1 && opts.roll < 7) await this.lunge(m);
    } else if (move.kind === 'fullcrash') {
      await this.pose(m, move.pose);
      Sfx.play('roar'); this.cameras.main.shake(1200, 0.02); this.cameras.main.flash(300, 255, 60, 30);
      this.burst(m.sprite.x, m.sprite.y - m.h * 0.5, [0xff3a2a, 0xff8a2a, 0xffdf4a], 70, 340);
      await this.say(`${m.name} is FULLY crashing out. Two dice. On some dice shi.`, 1000);
      const r = await this.rollDice2();
      opts.rolls = r.rolls; opts.accept67 = r.accept67;
      this.unpose(m);
      await this.lunge(m);
    } else if (move.kind === 'buff') {
      await this.pose(m, move.pose);
    } else if (move.kind === 'mogsupreme' || move.kind === 'chudout') {
      // animated by their events
    } else {
      await this.pose(m, move.pose, m.id === 'xylo' && (move.fx === 'blast' || move.fx === 'fire'));
      if (move.timed) opts.timing = await this.qte(t.sprite.x, this.midY(t), 'SPACE!');
      await this.moveFx(m, move, t);
    }
    const ev = B.partyAct(m, a, opts);
    if (B.used67 && !this.registry.get('used67')) { this.registry.set('used67', true); Outcomes.unlock('c_67'); }
    await this.play(ev);
    this.unpose(m);
  }

  async moveFx(m, move, t) {
    if (move.fx === 'slap') await this.lunge(m);
    if (move.fx === 'blast') await this.projectile(m, t, [0xb06bff, 0x7f5bff]);
    if (move.fx === 'fire') {
      Sfx.play('fire');
      const flame = this.add.particles(m.sprite.x + 70, m.sprite.y - m.h * 0.7, 'fx_soft', {
        speedX: { min: 500, max: 800 }, speedY: { min: -60, max: 60 }, scale: { start: 0.6, end: 0.1 }, lifespan: 650,
        frequency: 12, tint: [0xff5a1a, 0xffb02a, 0xffe07a], blendMode: 'ADD',
      }).setDepth(60);
      await this.wait(600);
      flame.stop(); this.time.delayedCall(700, () => flame.destroy());
      this.burst(t.sprite.x, this.midY(t), [0xff5a1a, 0xffb02a], 30, 220);
    }
    if (move.fx === 'lore') {
      Sfx.play('pages'); this.time.delayedCall(500, () => Sfx.play('choir'));
      const runes = this.add.particles(t.sprite.x, this.midY(t), 'fx_soft', {
        x: { min: -120, max: 120 }, y: { min: -160, max: 120 }, speedY: { min: -60, max: -20 },
        scale: { start: 0.35, end: 0 }, lifespan: 1000, frequency: 25, tint: [0xffd27a, 0xfff2b0], blendMode: 'ADD',
      }).setDepth(60);
      await this.say(`${m.name} reads from Deloye Lore, Vol. 1 of ∞… it goes on for a while…`, 1400);
      runes.stop(); this.time.delayedCall(1000, () => runes.destroy());
    }
    if (move.fx === 'sparkle') {
      Sfx.play('hairflip');
      this.burst(m.sprite.x + 40, m.sprite.y - m.h * 0.85, [0xfff2b0, 0xffffff], 25, 180);
    }
    if (move.fx === 'mog') {
      Sfx.play('mog');
      this.cameras.main.flash(350, 255, 230, 160);
      this.floatText(W / 2, 240, 'MOG', '#ffdf4a', 80);
      await this.wait(450);
    }
  }

  async comboIntro(c, m) {
    const members = c.who.map((id) => this.party.find((p) => p.id === id));
    const poses = { skorn: 'char_skorn_throw', lykor: 'char_lykor_scream', xylo: 'char_xylo_lore' };
    members.forEach((p) => this.setTex(p.sprite, poses[p.id]));
    this.cameras.main.flash(250, 255, 220, 120);
    const big = this.add.text(W / 2, 250, c.name, { fontFamily: 'Cinzel', fontSize: '64px', fontStyle: '900', color: '#ffdf4a', stroke: '#000', strokeThickness: 9 }).setOrigin(0.5).setDepth(98).setScale(0.3);
    await this.tweenP({ targets: big, scale: 1, duration: 350, ease: 'Back.out' });
    await this.say(c.desc, 1300);
    this.tweens.add({ targets: big, alpha: 0, duration: 300, onComplete: () => big.destroy() });
  }

  async pose(m, tex, flip = false) {
    this.setTex(m.sprite, tex, flip);
    this.tweens.add({ targets: m.sprite.img, y: -10, yoyo: true, duration: 120 });
    await this.wait(250);
  }

  unpose(m) { if (m.hp > 0) this.setTex(m.sprite, m.idleTex); }

  lunge(m, dx = 70) {
    return this.tweenP({ targets: m.sprite, x: m.sprite.x + dx, yoyo: true, duration: 140, ease: 'Quad.out' });
  }

  async projectile(m, target, tint, scale = 1.2) {
    Sfx.play('zap');
    const orb = this.add.image(m.sprite.x + 60, m.sprite.y - m.h * 0.65, 'fx_soft').setTint(tint[0]).setScale(scale)
      .setBlendMode(Phaser.BlendModes.ADD).setDepth(60);
    const trail = this.add.particles(0, 0, 'fx_soft', { follow: orb, scale: { start: 0.5 * scale, end: 0 }, lifespan: 300, frequency: 15, tint, blendMode: 'ADD' }).setDepth(59);
    await this.tweenP({ targets: orb, x: target.sprite.x, y: this.midY(target), duration: 450, ease: 'Quad.in' });
    this.burst(orb.x, orb.y, tint, 35, 260);
    orb.destroy(); trail.stop(); this.time.delayedCall(400, () => trail.destroy());
  }

  // ======================= Enemy turn =======================
  async enemyTurn(e) {
    const B = this.battle;
    const chaos = B.rollChaos();
    if (chaos.length) { await this.play(chaos); this.refresh(); if (B.result() || e.hp <= 0) return; }
    const it = B.enemyPlan(e);
    let block = null;
    if (it.kind === 'hit') {
      const single = !it.aoe && it.targets.length === 1;
      const t = it.targets[0];
      await this.say(it.text, 650);
      const dx = e.ai === 'giant' ? -30 : -60;
      this.tweens.add({ targets: e.sprite, x: e.sprite.x + dx, duration: 420, ease: 'Quad.out' });
      const qx = single ? t.sprite.x : this.party.length > 1 ? this.party[1].sprite.x : this.party[0].sprite.x;
      const qy = single ? this.midY(t) : 380;
      block = await this.qte(qx, qy, single ? `BLOCK! (SPACE) — ${t.name}` : 'EVERYONE BRACE! (SPACE)', it.sit ? 950 : 800);
      this.tweens.add({ targets: e.sprite, x: e.sprite.homeX, duration: 160 });
    } else if (it.kind !== 'phase') {
      await this.tweenP({ targets: e.sprite, x: e.sprite.x - 25, yoyo: true, duration: 150 });
    }
    await this.play(B.enemyResolve(e, it, block));
  }

  // ======================= Event playback =======================
  async play(events) {
    for (const ev of events) await this.playOne(ev);
    this.refresh();
  }

  async playOne(ev) {
    const u = ev.u;
    switch (ev.t) {
      case 'say':
        if (ev.sound) Sfx.play(ev.sound);
        await this.say(ev.text, ev.ms || 1100);
        break;
      case 'dmg': {
        u.shown = ev.hp;
        Sfx.play(ev.sound || 'hit');
        if (ev.shake) this.cameras.main.shake(500, 0.02);
        u.sprite.img.setTintFill(0xffffff);
        this.time.delayedCall(90, () => { u.sprite.img.clearTint(); if (this.mods.enemyTripping) u.sprite.img.setTint(0xd8b0ff); if (u.disguise) u.sprite.img.setTint(0xff7a7a); });
        this.tweens.add({ targets: u.sprite, x: u.sprite.homeX + 14, yoyo: true, repeat: 2, duration: 50, onComplete: () => u.sprite.setX(u.sprite.homeX) });
        this.floatText(u.sprite.x + Phaser.Math.Between(-20, 20), this.midY(u) - 20, `-${ev.amt}`, '#ff6a5a', ev.label === 'PERFECT!' ? 44 : 34);
        if (ev.label) this.floatText(u.sprite.x, this.midY(u) - 80, ev.label, { 'PERFECT!': '#ffdf4a', GOOD: '#7dff8a', MID: '#a49cc4' }[ev.label], 24);
        this.refresh();
        if (ev.text) await this.say(ev.text, ev.quick ? 600 : 1050);
        else await this.wait(ev.quick ? 260 : 420);
        break;
      }
      case 'heal':
        u.shown = ev.hp;
        Sfx.play(ev.sound || 'heal');
        if (ev.amt > 0) this.floatText(u.sprite.x, this.midY(u) - 20, `+${ev.amt}`, '#7dff8a');
        this.burst(u.sprite.x, this.midY(u), [0x7dff8a, 0xfff2b0], 20, 120);
        this.refresh();
        if (ev.text) await this.say(ev.text, 1200);
        else await this.wait(ev.quick ? 200 : 400);
        break;
      case 'selfHit':
        u.shown = ev.hp;
        Sfx.play('hurt');
        this.floatText(u.sprite.x, this.midY(u), `-${ev.amt}`, '#ff6a5a');
        this.refresh();
        await this.say(ev.text, 1500);
        break;
      case 'attack':
        if (ev.sound) Sfx.play(ev.sound);
        if (ev.block === 'perfect' || ev.block === 'good') Sfx.play('block');
        if (ev.sit) this.cameras.main.shake(1100, 0.03);
        else if (u.ai === 'giant') this.cameras.main.shake(500, 0.016);
        break;
      case 'hurt': {
        u.shown = ev.hp;
        Sfx.play('hurt');
        this.setTex(u.sprite, u.P.hurt);
        this.tweens.add({ targets: u.sprite, x: u.sprite.homeX - 12, yoyo: true, repeat: 2, duration: 50, onComplete: () => u.sprite.setX(u.sprite.homeX) });
        this.floatText(u.sprite.x, this.midY(u) - 10, `-${ev.amt}`, '#ff6a5a');
        if (ev.block === 'perfect') this.floatText(u.sprite.x, this.midY(u) - 70, 'PERFECT BLOCK', '#ffdf4a', 22);
        else if (ev.block === 'good') this.floatText(u.sprite.x, this.midY(u) - 70, 'BLOCKED', '#7dff8a', 22);
        if (u.defending) this.floatText(u.sprite.x, this.midY(u) + 30, 'DEFENDED', '#8ad8ff', 18);
        this.refresh();
        await this.wait(ev.quick ? 300 : 650);
        if (u.hp > 0) this.setTex(u.sprite, u.idleTex);
        break;
      }
      case 'ko':
        this.setTex(u.sprite, u.P.hurt);
        await this.tweenP({ targets: u.sprite, alpha: 0.3, angle: -10, duration: 400 });
        await this.say(`${u.name} is knocked out. (An item can revive them.)`, 1100);
        break;
      case 'down':
        Sfx.play('enemyDown');
        await this.tweenP({ targets: u.sprite, alpha: 0.15, angle: 12, y: u.sprite.homeY + 20, duration: 500 });
        if (!ev.fake) {
          u.nameText.setText(`${u.name} (Defeated)`);
          u.statusText.setText('');
          await this.say(`${u.name} is down!`, 800);
        } else await this.wait(500);
        break;
      case 'revive':
        u.shown = ev.hp;
        Sfx.play('heal');
        await this.tweenP({ targets: u.sprite, alpha: 1, angle: 0, y: u.sprite.homeY, duration: 350 });
        if (u.side === 'party') this.setTex(u.sprite, u.idleTex);
        this.refresh();
        await this.say(ev.text, 1300);
        break;
      case 'status': {
        const s = STATUS[ev.name];
        const lbl = s ? s.label : ev.name.toUpperCase();
        const col = (u.side === 'enemy') === (s ? s.good : false) ? '#ff8a6a' : '#ffdf4a';
        Sfx.play(s && s.good && u.side === 'enemy' ? 'telegraph' : 'sparkle');
        this.floatText(u.sprite.x, this.headY(u) + 30, lbl, col, 22);
        this.refresh();
        if (!ev.quiet) await this.say(ev.text, 1250);
        break;
      }
      case 'meterFull':
        Sfx.play('meterFull');
        this.floatText(u.sprite.x, this.headY(u) - 10, 'ULTIMATE READY', '#ffdf4a', 22);
        this.refresh();
        if (ev.text) await this.say(ev.text, 1300);
        break;
      case 'bark':
        this.bubble(u, ev.line);
        await this.wait(350);
        break;
      case 'float':
        if (ev.sound) Sfx.play(ev.sound);
        this.floatText(u.sprite.x, this.headY(u) - 20, ev.text, ev.color || '#fff', 26);
        break;
      case 'misfire':
        Sfx.play('miss');
        this.tweens.add({ targets: u.sprite, angle: { from: -8, to: 8 }, yoyo: true, repeat: 2, duration: 120, onComplete: () => u.sprite.setAngle(0) });
        await this.say(ev.text, ev.ms || 1500);
        break;
      case 'hype':
        Sfx.play('buff');
        this.cameras.main.flash(300, 255, 210, 90);
        this.floatText(W / 2, 250, 'ON SOME TYPE SHI', '#ffdf4a', 54);
        this.party.forEach((p) => p.hp > 0 && this.burst(p.sprite.x, this.midY(p), [0xffdf4a, 0xfff2b0], 25, 160));
        this.refresh();
        await this.say(ev.text, 1600);
        break;
      case 'throwThing': {
        Sfx.play('throw');
        const t = this.add.text(u.sprite.x, this.headY(u), ev.thing, {
          fontFamily: 'Nunito', fontSize: '18px', fontStyle: '900', color: '#1a1324', backgroundColor: '#f3e3b0', padding: { x: 6, y: 2 },
        }).setOrigin(0.5).setDepth(95);
        this.tweens.add({ targets: t, angle: 720, duration: 600 });
        await this.tweenP({ targets: t, x: ev.target.sprite.x, y: this.midY(ev.target), duration: 600, ease: 'Quad.in' });
        t.destroy();
        break;
      }
      case 'sixSeven': await this.sixSevenDance(); break;
      case 'mogSupreme': await this.mogSupremeFx(u); break;
      case 'chudOut':
        this.setTex(u.sprite, 'char_xylo_chudout');
        await this.playChudOut();
        this.burst(ev.target.sprite.x, ev.target.sprite.y - 40, [0xb8a890, 0xffffff], 50, 300);
        break;
      case 'combo': await this.comboFx(ev); break;
      case 'item': {
        const it = ITEMS[ev.item];
        const icon = this.add.image(u.sprite.x, this.headY(u) - 40, it.tex).setDepth(95);
        icon.setScale(70 / icon.width);
        await this.tweenP({ targets: icon, x: ev.target.sprite.x, y: this.midY(ev.target), duration: 400 });
        icon.destroy();
        Sfx.play(ev.item === 'beer' ? 'gulp' : 'sparkle');
        break;
      }
      case 'tex':
        this.setTex(u.sprite, ev.tex);
        if (this.mods.enemyTripping) u.sprite.img.setTint(0xd8b0ff);
        break;
      case 'telegraph':
        if (ev.tex) this.setTex(u.sprite, ev.tex);
        Sfx.play(ev.status === 'sit' ? 'sitWarn' : 'telegraph');
        this.refresh();
        await this.say(ev.text, 1900);
        break;
      case 'phase': await this.phaseFx(ev); break;
      case 'miss':
        Sfx.play('miss');
        await this.say(ev.text, 1100);
        break;
      case 'chaos': await this.chaosFx(ev.c); break;
      case 'allyAttack': {
        const g = Phaser.Utils.Array.GetRandom(this.allySprites);
        if (g) await this.tweenP({ targets: g, x: g.homeX + 50, yoyo: true, duration: 140 });
        break;
      }
      default: break;
    }
  }

  // ======================= Big moments =======================
  async phaseFx(ev) {
    const e = ev.u;
    if (!ev.quick) {
      Sfx.play('dramatic'); this.cameras.main.shake(700, 0.015); this.cameras.main.flash(400, 255, 80, 60);
      const ban = this.add.text(W / 2, 260, 'PHASE 2', { fontFamily: 'Cinzel', fontSize: '80px', fontStyle: '900', color: '#ff6a4a', stroke: '#000', strokeThickness: 10 }).setOrigin(0.5).setDepth(98).setScale(0.4);
      await this.tweenP({ targets: ban, scale: 1, duration: 400, ease: 'Back.out' });
      this.time.delayedCall(900, () => this.tweens.add({ targets: ban, alpha: 0, duration: 300, onComplete: () => ban.destroy() }));
    }
    if (ev.disguise) {
      this.burst(e.sprite.x, this.midY(e), [0x9a6bff, 0xff3a6a], 50, 260);
      Sfx.play('whoosh');
      e.h = 380;
      e.sprite.h = 380;
      this.setTex(e.sprite, PARTY[ev.disguise].tex, true);
      e.sprite.img.setTint(0xff7a7a);
      e.nameText.setText(`Dulbers Frint (as "${PARTY[ev.disguise].name}")`);
    } else if (e.ai === 'giant') {
      e.nameText.setText(`${e.name} (Aight. Bet.)`);
      this.setTex(e.sprite, e.E.tex);
      e.sprite.img.setTint(0xffb0a0);
    }
    await this.say(ev.text, 1700);
  }

  async chaosFx(c) {
    Sfx.play('titleSting');
    const ui = [];
    ui.push(this.add.rectangle(W / 2, 300, 720, 200, 0x120e1e, 0.95).setStrokeStyle(3, 0xff6bd5).setDepth(97));
    ui.push(this.add.text(W / 2, 222, 'CHAOS EVENT', { fontFamily: 'Cinzel', fontSize: '26px', fontStyle: '900', color: '#ff6bd5' }).setOrigin(0.5).setDepth(98));
    if (c.portrait && this.textures.exists(c.portrait)) ui.push(this.add.image(W / 2 - 280, 310, c.portrait).setDisplaySize(110, 110).setDepth(98));
    ui.push(this.add.text(c.portrait ? W / 2 + 60 : W / 2, 310, c.title, { fontFamily: 'Nunito', fontSize: '22px', fontStyle: '900', color: '#f4efff', align: 'center', wordWrap: { width: c.portrait ? 520 : 660 } }).setOrigin(0.5).setDepth(98));
    ui.forEach((o) => { o.setAlpha(0); this.tweens.add({ targets: o, alpha: 1, duration: 250 }); });
    if (c.id === 'dulbmeethus') Voice.say('dulbmeethus', "Y'all could hear me doe?");
    if (c.id === 'mattias') Voice.say('mattias', 'Impressive.');
    if (c.id === 'rock') { this.cameras.main.shake(400, 0.01); }
    await this.wait(2000);
    ui.forEach((o) => o.destroy());
  }

  async mogSupremeFx(m) {
    this.setTex(m.sprite, 'char_lykor_mog');
    Sfx.play('mog'); Sfx.play('choir');
    const dim = this.add.rectangle(0, 0, W, H, 0x000000, 0).setOrigin(0).setDepth(70);
    await this.tweenP({ targets: dim, fillAlpha: 0.6, duration: 300 });
    this.tweens.add({ targets: m.sprite, scale: 1.25, duration: 900, ease: 'Sine.inOut' });
    this.burst(m.sprite.x, m.sprite.y - m.h * 0.85, [0xfff2b0, 0xffffff, 0xffdf4a], 70, 300);
    const big = this.add.text(W / 2, 260, 'MOG SUPREME', { fontFamily: 'Cinzel', fontSize: '96px', fontStyle: '900', color: '#ffdf4a', stroke: '#000', strokeThickness: 10 }).setOrigin(0.5).setDepth(98).setScale(0.5);
    await this.tweenP({ targets: big, scale: 1, duration: 700, ease: 'Back.out' });
    this.cameras.main.flash(500, 255, 240, 200);
    await this.wait(500);
    this.tweens.add({ targets: [big, dim], alpha: 0, duration: 300, onComplete: () => { big.destroy(); dim.destroy(); } });
    await this.tweenP({ targets: m.sprite, scale: 1, duration: 250 });
  }

  async comboFx(ev) {
    const c = ev.combo;
    const [a, b] = ev.members;
    const t = ev.target;
    if (c.id === 'elftoss') {
      const ly = this.party.find((p) => p.id === 'lykor');
      Sfx.play('throw');
      this.bubble(ly, 'NOT THE HAIR—');
      this.tweens.add({ targets: ly.sprite, angle: 720, duration: 650 });
      await this.tweenP({ targets: ly.sprite, x: t.sprite.x - 60, y: t.sprite.y - 80, duration: 650, ease: 'Quad.in' });
      this.cameras.main.shake(400, 0.02);
      this.tweens.add({ targets: ly.sprite, x: ly.sprite.homeX, y: ly.sprite.homeY, angle: 0, duration: 500, delay: 300 });
    } else if (c.id === 'loreslap') {
      const sk = this.party.find((p) => p.id === 'skorn');
      this.setTex(sk.sprite, 'char_skorn_slap');
      Sfx.play('pages');
    } else if (c.id === 'fireball') {
      const xy = this.party.find((p) => p.id === 'xylo');
      Sfx.play('fire');
      const flame = this.add.particles(xy.sprite.x + 70, xy.sprite.y - xy.h * 0.7, 'fx_soft', {
        speedX: { min: 600, max: 900 }, speedY: { min: -120, max: 120 }, scale: { start: 1.0, end: 0.2 }, lifespan: 800,
        frequency: 8, tint: [0xff5a1a, 0xffb02a, 0xffe07a, 0xfff2b0], blendMode: 'ADD',
      }).setDepth(60);
      await this.wait(800);
      flame.stop(); this.time.delayedCall(800, () => flame.destroy());
    } else if (c.id === 'trio') {
      this.cameras.main.flash(500, 255, 255, 255);
      Sfx.play('roar'); Sfx.play('choir');
      for (const p of this.alive(this.party)) { this.tweens.add({ targets: p.sprite, x: t.sprite.x - 120, duration: 260, yoyo: true, ease: 'Quad.out' }); await this.wait(140); }
      this.cameras.main.shake(800, 0.03);
      await this.wait(300);
    }
    if (a && b) { /* members are available for future per-combo art */ }
  }

  // Xylo's green-screen Chud Out video over the battlefield
  playChudOut() {
    return new Promise((resolve) => {
      if (!this.cache.video.exists('vid_xylo_chudout_short')) { Sfx.play('chudThud'); resolve(); return; }
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
      const flick = this.time.addEvent({ delay: 70, repeat: 14, callback: () => num.setText(String(Phaser.Math.Between(1, 6))) });
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
          if (await this.offer67()) { result = 7; num.setText('7'); Sfx.play('choir'); await this.wait(500); }
        }
        ui.forEach((o) => o.destroy());
        resolve(result);
      });
    });
  }

  // Two dice for FULL CRASH OUT
  rollDice2() {
    return new Promise((resolve) => {
      const ui = [];
      const add = (o) => { ui.push(o.setDepth(97)); return o; };
      add(this.add.rectangle(0, 0, W, H, 0x000000, 0.6).setOrigin(0));
      add(this.add.text(W / 2, 140, 'on some DOUBLE dice shi', { fontFamily: 'Cinzel', fontSize: '40px', fontStyle: '900', color: '#ff6a4a', stroke: '#000', strokeThickness: 7 }).setOrigin(0.5));
      const dice = [W / 2 - 150, W / 2 + 150].map((x) => { const d = add(this.add.image(x, 320, 'item_dice')); d.setScale(170 / d.width); return d; });
      const nums = [W / 2 - 150, W / 2 + 150].map((x) => add(this.add.text(x, 460, '', { fontFamily: 'Cinzel', fontSize: '60px', fontStyle: '900', color: '#ffffff', stroke: '#000', strokeThickness: 8 }).setOrigin(0.5)));
      dice.forEach((d, i) => this.tweens.add({ targets: d, angle: i ? -720 : 720, duration: 1100, ease: 'Cubic.out' }));
      Sfx.play('diceRoll'); this.time.delayedCall(120, () => Sfx.play('diceRoll'));
      const flick = this.time.addEvent({ delay: 70, repeat: 14, callback: () => nums.forEach((n) => n.setText(String(Phaser.Math.Between(1, 6)))) });
      this.time.delayedCall(1150, async () => {
        flick.remove();
        const rolls = [Phaser.Math.Between(1, 6), Phaser.Math.Between(1, 6)];
        rolls.forEach((r, i) => { nums[i].setText(String(r)); this.tweens.add({ targets: nums[i], scale: { from: 1.6, to: 1 }, duration: 250, ease: 'Back.out' }); });
        const sum = rolls[0] + rolls[1];
        Sfx.play(sum >= 10 ? 'sparkle' : sum <= 3 ? 'miss' : 'pop');
        const txt = rolls[0] === 6 && rolls[1] === 6 ? 'DOUBLE SIXES.' : rolls[0] === 1 && rolls[1] === 1 ? 'Snake eyes… uh oh.' : `${sum} × 7 = ${sum * 7} damage`;
        const sub = add(this.add.text(W / 2, 540, txt, { fontFamily: 'Nunito', fontSize: '26px', fontStyle: '900', color: '#f3e3b0', stroke: '#000', strokeThickness: 5 }).setOrigin(0.5));
        await this.wait(1000);
        let accept67 = false;
        if (rolls[0] === 6 && rolls[1] === 6 && !this.registry.get('used67')) {
          sub.setText('Double sixes… you could add +1 to one of them. Once per game.');
          accept67 = await this.offer67();
          if (accept67) { nums[1].setText('7'); Sfx.play('choir'); await this.wait(500); }
        }
        ui.forEach((o) => o.destroy());
        resolve({ rolls, accept67 });
      });
    });
  }

  async offer67() {
    const opts = [{ label: '+1 (make it a 7)', desc: 'Do the 6-7. Only once in the entire game.' }, { label: 'Nah, keep it', desc: 'Save it.' }];
    [this.menuTitle, ...this.menuTexts].forEach((t) => t.setDepth(98));
    const choice = await this.menu('+1?', opts, false);
    [this.menuTitle, ...this.menuTexts].forEach((t) => t.setDepth(82));
    this.clearMenu();
    if (choice === 0) { this.registry.set('used67', true); Outcomes.unlock('c_67'); return true; }
    this.registry.set('declined67', true); Outcomes.unlock('c_no67');
    return false;
  }

  async sixSevenDance() {
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
  }

  // ======================= Endings =======================
  async victory() {
    this.clearMenu();
    this.settle();
    Sfx.play('victory');
    const grade = this.battle.grade();
    const xp = Math.round(this.def.xp * grade.xp);
    const total = (this.registry.get('xp') || 0) + xp;
    this.registry.set('xp', total);
    let lvl = this.level;
    while (LEVELS[lvl + 1] !== undefined && total >= LEVELS[lvl + 1]) lvl += 1;
    const leveled = lvl > this.level;
    this.registry.set('level', lvl);
    try {
      const best = JSON.parse(localStorage.getItem('trio_grades') || '{}');
      const order = 'SABCDF';
      if (!best[this.battle.key] || order.indexOf(grade.g) < order.indexOf(best[this.battle.key])) best[this.battle.key] = grade.g;
      localStorage.setItem('trio_grades', JSON.stringify(best));
    } catch (e) { /* blocked */ }
    const st = this.battle.stats;
    const ui = [
      this.add.rectangle(0, 0, W, H, 0x000000, 0.65).setOrigin(0),
      this.add.text(W / 2, 140, 'VICTORY', { fontFamily: 'Cinzel', fontSize: '80px', fontStyle: '900', color: '#ffdf4a', stroke: '#000', strokeThickness: 10 }).setOrigin(0.5),
      this.add.text(W / 2, 210, '(on some winning shi)', { fontFamily: 'Nunito', fontSize: '22px', color: '#f3e3b0' }).setOrigin(0.5),
      this.add.text(W / 2 - 180, 330, grade.g, { fontFamily: 'Cinzel', fontSize: '150px', fontStyle: '900', color: grade.color, stroke: '#000', strokeThickness: 12 }).setOrigin(0.5).setScale(0.2),
      this.add.text(W / 2 - 40, 290, `RANK: ${grade.g}`, { fontFamily: 'Cinzel', fontSize: '30px', fontStyle: '900', color: grade.color, stroke: '#000', strokeThickness: 6 }).setOrigin(0, 0.5),
      this.add.text(W / 2 - 40, 330, `(${grade.label})`, { fontFamily: 'Nunito', fontSize: '22px', fontStyle: '900', color: '#f4efff' }).setOrigin(0, 0.5),
      this.add.text(W / 2 - 40, 372, `Perfect presses ${st.perfects}/${st.timed} · Damage taken ${st.dmgTaken} · KOs ${st.kos} · Turns ${st.partyTurns}`, { fontFamily: 'Nunito', fontSize: '16px', color: '#a49cc4' }).setOrigin(0, 0.5),
      this.add.text(W / 2, 450, `+${xp} XP${grade.xp > 1 ? `  (rank bonus ×${grade.xp})` : ''}`, { fontFamily: 'Cinzel', fontSize: '32px', fontStyle: '900', color: '#7dff8a', stroke: '#000', strokeThickness: 6 }).setOrigin(0.5),
    ];
    if (leveled) ui.push(this.add.text(W / 2, 494, `LEVEL UP! The party is now Level ${lvl}`, { fontFamily: 'Cinzel', fontSize: '28px', fontStyle: '900', color: '#ffdf4a', stroke: '#000', strokeThickness: 6 }).setOrigin(0.5));
    ui.push(this.add.text(W / 2, 540, 'Press SPACE to continue', { fontFamily: 'Nunito', fontSize: '20px', color: '#a49cc4' }).setOrigin(0.5));
    ui.forEach((o) => o.setDepth(99));
    this.tweens.add({ targets: ui[3], scale: 1, duration: 500, ease: 'Back.out', delay: 300 });
    this.time.delayedCall(450, () => { Sfx.play(grade.g === 'S' ? 'perfect' : 'pop'); if (grade.g === 'S') this.cameras.main.flash(300, 255, 230, 120); });
    await this.wait(900);
    this.handler = (ev) => { if (ev.key === 'ok' || ev.tap) { this.handler = null; this.end('win'); } };
  }

  async defeat() {
    this.clearMenu();
    Sfx.play('defeat');
    Outcomes.unlock('c_cooked');
    [
      this.add.rectangle(0, 0, W, H, 0x000000, 0.7).setOrigin(0),
      this.add.text(W / 2, 250, 'YOU GOT COOKED', { fontFamily: 'Cinzel', fontSize: '76px', fontStyle: '900', color: '#ff6a4a', stroke: '#000', strokeThickness: 10 }).setOrigin(0.5),
      this.add.text(W / 2, 330, '(on some losing shi)', { fontFamily: 'Nunito', fontSize: '24px', color: '#f3e3b0' }).setOrigin(0.5),
      this.add.text(W / 2, 400, 'Tip: time your blocks, Defend before big telegraphed moves, and save items for revives.', { fontFamily: 'Nunito', fontSize: '18px', color: '#f4efff' }).setOrigin(0.5),
      this.add.text(W / 2, 470, 'Press SPACE to try again', { fontFamily: 'Nunito', fontSize: '22px', color: '#a49cc4' }).setOrigin(0.5),
    ].forEach((o) => o.setDepth(99));
    await this.wait(900);
    this.handler = (ev) => { if (ev.key === 'ok' || ev.tap) { this.handler = null; this.scene.restart(this.cfg); } };
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
