import StageScene, { at } from './StageScene.js';
import { SCENE4 } from '../data/scenes/scene4_the_pass.js';
import { LORE_PASSAGES } from '../data/deloyeLore.js';
import Sfx from '../audio/Sfx.js';

// Scene 4 — The Mountain Pass. Mattias appears, then the party has to get past Diddy Chud Giant.
export default class PassScene extends StageScene {
  constructor() { super('Pass'); }

  create() {
    this.nextScene = 'Continue';
    this.setupStage({ light: 'lava' });
    Sfx.startLoop('fire');
    ['sneakWon', 'loreWon'].forEach((f) => this.registry.set(f, false));

    this.bg = this.placeBg('bg_mountain_path');
    this.ash();

    const xylo = this.makeChar('xylo', -150, 572, { h: 320 });
    const lykor = this.makeChar('lykor', -150, 566, { h: 320 });
    const skorn = this.makeChar('skorn', -150, 590, { h: 345 });
    this.party = [xylo, lykor, skorn];
    // Goblin entourage, if they're still around
    this.allies = [];
    if (this.registry.get('goblinAllies')) {
      this.allies = [
        this.makeChar('gob1', -200, 612, { tex: 'char_goblin', voice: 'goblin', h: 160 }),
        this.makeChar('gob2', -200, 618, { tex: 'char_goblin', voice: 'goblin', h: 150 }),
        this.makeChar('chief', -200, 606, { tex: 'char_goblin_chief', voice: 'chief', h: 190 }),
      ];
    }
    this.mattias = this.makeChar('mattias', 1010, 560, { h: 340 });
    this.mattias.setVisible(false);
    this.giant = this.makeChar('giant', 900, 640, { tex: 'char_giant_angry', h: 560 });
    this.giant.setVisible(false);

    this.finishStage();
    this.dialogue.play(SCENE4, this.baseHooks({
      enterParty: () => Promise.all([
        this.walk(xylo, 330), this.walk(lykor, 520), this.walk(skorn, 720),
        ...this.allies.map((g, i) => this.walk(g, [130, 200, 60][i])),
      ]).then(() => [...this.party, ...this.allies].forEach((c) => c.img.setFlipX(false))),
      mattiasAppears: async () => {
        Sfx.play('sparkle'); Sfx.play('boom');
        this.cameras.main.flash(300, 170, 120, 255);
        this.burst(this.mattias.x, this.mattias.y - 170, [0xb06bff, 0x7fb2ff]);
        // His green-screen video, scaled so he finishes exactly where his cutout stands
        await this.playCutscene('vid_mattias_appear', { keyed: true, keepChars: true, x: 999, y: 392, scale: 0.54 });
        this.mattias.setAlpha(1).setVisible(true);
        await this.showLabel(this.charLabel(this.mattias, 'Metocin Mattias (Uninvited)'));
      },
      mattiasVanish: async () => {
        Sfx.play('sparkle');
        this.burst(this.mattias.x, this.mattias.y - 170, [0xb06bff, 0x7fb2ff]);
        this.cameras.main.flash(250, 170, 120, 255);
        this.mattias.setVisible(false);
        await this.wait(400);
      },
      mattiasVoice: async () => { Sfx.play('sparkle'); this.cameras.main.flash(500, 120, 80, 200); await this.wait(300); },
      toGiant: () => this.toGiant(),
      giantWakeVideo: () => this.giantWakeVideo(),
      giantWakes: () => this.giantWakes(),
      giantWakesCalm: () => this.giantWakes({ calm: true }),
      giantTrip: () => this.giantTrip(),
      giantLeaves: () => this.giantLeaves(),
      giantRollsOver: () => this.giantRollsOver(),
      skornSlapsGiant: () => this.skornSlapsGiant(),
      stealBowls: () => this.stealBowls(),
      sneakGame: async () => this.registry.set('sneakWon', await this.sneakGame()),
      loreGame: async () => this.registry.set('loreWon', await this.loreGame()),
      fightGiant: () => this.fight('giant', { allies: this.allies.length > 0 }),
      fightGiantEnraged: () => this.fight('giant', { enraged: true, allies: this.allies.length > 0 }),
      fightGiantTripping: () => this.fight('giant', { enemyTripping: true, allies: this.allies.length > 0 }),
      leaveRight: async () => {
        [...this.party, ...this.allies].forEach((c, i) => this.time.delayedCall(i * 180, () => this.walk(c, 1500, 1.8)));
        await this.wait(1800);
      },
    })).then(() => this.finish(this.nextScene));
  }

  // ---------------- Atmosphere ----------------
  ash() {
    const { width } = this.scale;
    this.add.particles(0, -10, 'fx_soft', {
      x: { min: 0, max: width }, speedY: { min: 20, max: 60 }, speedX: { min: -20, max: 10 },
      scale: { start: 0.08, end: 0.04 }, alpha: { start: 0.7, end: 0 }, lifespan: 9000, frequency: 70, tint: 0x3a3030,
    }).setDepth(25);
    this.add.particles(0, 720, 'fx_soft', {
      x: { min: 0, max: width }, speedY: { min: -70, max: -30 }, speedX: { min: -15, max: 15 },
      scale: { start: 0.1, end: 0 }, alpha: { start: 0.9, end: 0 }, lifespan: 6000, frequency: 120,
      tint: [0xff7a2a, 0xffb347], blendMode: 'ADD',
    }).setDepth(25);
  }

  burst(x, y, tint) {
    const p = this.add.particles(x, y, 'fx_soft', {
      speed: { min: 80, max: 260 }, scale: { start: 0.5, end: 0 }, lifespan: 700, quantity: 40,
      tint, blendMode: 'ADD', emitting: false,
    }).setDepth(40);
    p.explode(40);
    this.time.delayedCall(900, () => p.destroy());
  }

  // ---------------- The giant ----------------
  async toGiant() {
    const cam = this.cameras.main;
    cam.fade(400, 0, 0, 0, true);
    await this.wait(420);
    this.bg.destroy();
    this.bg = this.placeBg('bg_giant_pass');
    [140, 300, 470].forEach((x, i) => this.party[i].setPosition(x, [585, 578, 600][i]));
    this.allies.forEach((g, i) => g.setPosition([560, 625, 690][i], [620, 626, 614][i]));
    const chest = at(470, 230);
    this.giantLabel = this.label(chest.x, chest.y, 'Diddy Chud Giant (Asleep, Do Not Disturb)').setAlpha(0);
    this.zzz = this.add.text(at(790, 150).x, at(790, 150).y, 'Z z z', {
      fontFamily: 'Cinzel', fontSize: '34px', fontStyle: '900', color: '#f3e3b0', stroke: '#000', strokeThickness: 5,
    }).setDepth(30);
    this.zzzTween = this.tweens.add({ targets: this.zzz, y: this.zzz.y - 30, alpha: 0.2, yoyo: true, repeat: -1, duration: 1400 });
    cam.fadeIn(500, 0, 0, 0);
    await this.wait(500);
    await this.showLabel(this.giantLabel);
  }

  clearSleeping() {
    if (this.zzz) { this.zzz.destroy(); this.zzz = null; }
    if (this.giantLabel) this.giantLabel.setVisible(false);
  }

  // Your video: a purple vial lands on him, smoke, he wakes and stands roaring
  async giantWakeVideo() {
    this.clearSleeping();
    await this.playCutscene('vid_giant_wake');
    this.bg.destroy();
    this.bg = this.placeBg('bg_mountain_path');
    this.cameras.main.fadeIn(300, 0, 0, 0);
    Sfx.play('boom');
    this.cameras.main.shake(500, 0.014);
    await this.showChar(this.giant, 150);
    await this.showLabel(this.giantTag = this.charLabel(this.giant, 'Diddy Chud Giant (Awake, Disturbed)'));
  }

  // Wakes up and stands (no video)
  async giantWakes({ calm = false } = {}) {
    this.clearSleeping();
    Sfx.play(calm ? 'pop' : 'boom');
    if (!calm) { Sfx.play('dramatic'); this.cameras.main.shake(700, 0.018); }
    await this.swapBg('bg_mountain_path', 500);
    await this.showChar(this.giant, 250);
    if (!calm) this.cameras.main.shake(400, 0.012);
    await this.showLabel(this.giantTag = this.charLabel(this.giant, calm ? 'Diddy Chud Giant (Awake, Family)' : 'Diddy Chud Giant (Awake, Disturbed)'));
  }

  async giantTrip() {
    Sfx.play('dramatic');
    this.giantWobble = this.tweens.add({ targets: this.giant, angle: { from: -3, to: 3 }, yoyo: true, repeat: -1, duration: 800, ease: 'Sine.inOut' });
    this.add.particles(this.giant.x, this.giant.y - 300, 'fx_soft', {
      x: { min: -160, max: 160 }, y: { min: -220, max: 220 }, speed: { min: 5, max: 25 },
      scale: { start: 0.45, end: 0 }, alpha: { start: 0.4, end: 0 }, lifespan: 1800, frequency: 70,
      tint: [0xb06bff, 0x5bffb0, 0xff6bd5], blendMode: 'ADD',
    }).setDepth(20);
    if (this.giantTag) this.giantTag.setText('Diddy Chud Giant (Tripping)');
    await this.wait(400);
  }

  async giantLeaves() {
    if (this.giantWobble) this.giantWobble.stop();
    this.giant.setAngle(0);
    if (this.giant.visible) {
      Sfx.play('step');
      this.cameras.main.shake(200, 0.006);
      await this.walk(this.giant, 1600, 2.5);
      this.giant.setVisible(false);
    } else {
      // He was still lying down — he just rolls out of the way
      await this.giantRollsOver();
    }
  }

  async giantRollsOver() {
    this.clearSleeping();
    Sfx.play('boom');
    this.cameras.main.shake(400, 0.008);
    await this.swapBg('bg_mountain_path', 900);
  }

  async skornSlapsGiant() {
    const skorn = this.chars.skorn;
    await this.walk(skorn, 640);
    Sfx.play('whoosh');
    await this.tweenP({ targets: skorn, x: 690, duration: 120, yoyo: true });
    Sfx.play('boom');
    this.cameras.main.shake(350, 0.014);
    await this.wait(300);
  }

  async stealBowls() {
    Sfx.play('grab');
    const skorn = this.chars.skorn;
    const bowls = [0, 1].map((i) => {
      const b = this.add.image(skorn.x - 40 + i * 80, skorn.y - 260, 'item_chipotle_bowl').setDepth(45).setAlpha(0);
      b.setScale(90 / b.width);
      return b;
    });
    await Promise.all(bowls.map((b, i) => this.tweenP({ targets: b, alpha: 1, y: b.y - 20, duration: 300, delay: i * 120, ease: 'Back.out' })));
    const l = this.label(skorn.x, skorn.y - 330, 'Chipotle Bowl ×2 (Stolen)', 16);
    l.setAlpha(0);
    await this.showLabel(l);
    this.registry.set('inv_bowl', (this.registry.get('inv_bowl') || 0) + 2);
    this.time.delayedCall(1500, () => this.tweens.add({ targets: [...bowls, l], alpha: 0, duration: 400 }));
  }

  // ---------------- Minigame: Snore Sneak ----------------
  // Move only while he SNORES. Moving during the quiet inhale fills the snore meter.
  sneakGame() {
    return new Promise((resolve) => {
      const { width } = this.scale;
      const D = 975;
      const ui = [];
      const add = (o) => { ui.push(o.setDepth(D)); return o; };
      this.clearSleeping();
      if (this.giantLabel) this.giantLabel.setVisible(false);

      add(this.add.rectangle(0, 0, width, 720, 0x000000, 0.25).setOrigin(0));
      add(this.add.text(width / 2, 40, 'SNORE SNEAK', { fontFamily: 'Cinzel', fontSize: '40px', fontStyle: '900', color: '#ffcf4a', stroke: '#000', strokeThickness: 6 }).setOrigin(0.5));
      const help = add(this.add.text(width / 2, 88, 'Hold → or SPACE to sneak — ONLY while he snores', { fontFamily: 'Nunito', fontSize: '20px', color: '#f3e3b0', stroke: '#000', strokeThickness: 4 }).setOrigin(0.5));
      const cue = add(this.add.text(width / 2, 170, '', { fontFamily: 'Cinzel', fontSize: '46px', fontStyle: '900', color: '#7dff8a', stroke: '#000', strokeThickness: 7 }).setOrigin(0.5));

      // Snore meter (top right)
      add(this.add.text(980, 30, 'Snore Meter', { fontFamily: 'Nunito', fontSize: '18px', fontStyle: '900', color: '#ffffff', stroke: '#000', strokeThickness: 4 }));
      add(this.add.rectangle(980, 58, 260, 22, 0x1a1324).setOrigin(0, 0.5).setStrokeStyle(2, 0xe8b923));
      const meter = add(this.add.rectangle(982, 58, 0, 18, 0xff4a3a).setOrigin(0, 0.5));

      // Progress track with sections across his body
      const x0 = 140, x1 = 1140, ty = 682;
      add(this.add.rectangle(x0, ty, x1 - x0, 8, 0x1a1324).setOrigin(0, 0.5).setStrokeStyle(2, 0xe8b923));
      [['Legs', 0.17], ['Belly (Squishy)', 0.5], ['Arm (Hairy)', 0.83]].forEach(([t, f]) => {
        add(this.add.text(x0 + (x1 - x0) * f, ty - 26, t, { fontFamily: 'Nunito', fontSize: '15px', fontStyle: '900', color: '#1a1324', backgroundColor: '#f3e3b0', padding: { x: 6, y: 1 } }).setOrigin(0.5));
      });
      const marker = add(this.add.image(x0, ty, 'portrait_skorn').setDisplaySize(40, 40));

      const startX = this.party.map((c) => c.x);
      let prog = 0, heat = 0, phase = 'wait', phaseT = 0, grace = 0, warned = false, live = false, over = false, holding = false;
      const keys = this.input.keyboard.addKeys({ right: 'RIGHT', d: 'D', space: 'SPACE' });
      const pDown = () => { holding = true; }; const pUp = () => { holding = false; };
      this.input.on('pointerdown', pDown); this.input.on('pointerup', pUp);

      const section = () => Math.min(2, Math.floor(prog / 34));
      const setPhase = (p) => {
        phase = p;
        warned = false;
        if (p === 'snore') {
          phaseT = 1.8;
          cue.setText('ZZZZZZ — MOVE!').setColor('#7dff8a');
          Sfx.play('snore');
          this.cameras.main.shake(1400, 0.002);
        } else {
          phaseT = Phaser.Math.FloatBetween(1.0, 1.9) / (1 + section() * 0.25);
          grace = 0.3; // a moment to react
          cue.setText('…shhh — FREEZE!').setColor('#ff6a5a');
        }
        this.tweens.add({ targets: cue, scale: { from: 1.25, to: 1 }, duration: 200 });
      };

      const end = (won) => {
        over = true; live = false;
        this.input.off('pointerdown', pDown); this.input.off('pointerup', pUp);
        this.input.keyboard.removeKey(keys.right); this.input.keyboard.removeKey(keys.d);
        cue.setText(won ? 'MADE IT!' : 'HE\'S WAKING UP…').setColor(won ? '#ffcf4a' : '#ff6a5a');
        Sfx.play(won ? 'confirm' : 'dramatic');
        if (!won) this.cameras.main.shake(500, 0.012);
        this.time.delayedCall(1400, () => { ui.forEach((o) => o.destroy()); this.events.off('update', tick); resolve(won); });
      };

      const tick = (time, delta) => {
        if (!live || over) return;
        const dt = delta / 1000;
        phaseT -= dt;
        grace = Math.max(0, grace - dt);
        // Warning: the snore is about to end
        if (phase === 'snore' && !warned && phaseT < 0.45) { warned = true; cue.setText('zzz… (slowing down)').setColor('#ffd84a'); }
        if (phaseT <= 0) setPhase(phase === 'snore' ? 'inhale' : 'snore');
        const moving = holding || keys.right.isDown || keys.d.isDown || keys.space.isDown;
        if (moving) {
          prog = Math.min(100, prog + 11 * dt);
          if (phase === 'inhale' && grace <= 0) { heat += 42 * dt; if (Math.random() < 0.08) Sfx.play('step'); }
        } else {
          heat = Math.max(0, heat - 9 * dt);
        }
        meter.width = 2.56 * Math.min(100, heat);
        marker.x = x0 + (x1 - x0) * (prog / 100);
        this.party.forEach((c, i) => { c.x = startX[i] + (prog / 100) * 900; c.img.setFlipX(false); });
        if (heat >= 100) end(false);
        else if (prog >= 100) end(true);
      };
      this.events.on('update', tick);

      // 3-2-1 then go
      [['3', 0], ['2', 700], ['1', 1400]].forEach(([t, ms]) => this.time.delayedCall(ms, () => { cue.setText(t).setColor('#ffffff'); Sfx.play('tick'); }));
      this.time.delayedCall(2100, () => { live = true; help.setAlpha(0.8); setPhase('snore'); });
    });
  }

  // ---------------- Minigame: Lore Session ----------------
  // Xylo reads pages from different chapters of Deloye Lore. Each page tells a short epic story and stops
  // mid-sentence; pick the continuation that stays true to the lore. Diddy Chud is a lore nerd:
  // true lore soothes him, wrong lore wakes him up.
  loreGame() {
    return new Promise((resolve) => {
      const { width } = this.scale;
      const D = 975;
      const ui = [];
      const add = (o) => { ui.push(o.setDepth(D)); return o; };
      const xylo = this.chars.xylo;
      this.setCharTex(xylo, 'char_xylo_lore', 340);
      Sfx.play('choir');

      add(this.add.rectangle(0, 0, width, 720, 0x000000, 0.8).setOrigin(0));
      // Sleep meter
      add(this.add.text(width / 2, 18, "Diddy Chud's Sleep", { fontFamily: 'Nunito', fontSize: '16px', fontStyle: '900', color: '#ffffff', stroke: '#000', strokeThickness: 4 }).setOrigin(0.5));
      add(this.add.rectangle(width / 2 - 200, 42, 400, 18, 0x1a1324).setOrigin(0, 0.5).setStrokeStyle(2, 0xe8b923));
      const sleepBar = add(this.add.rectangle(width / 2 - 198, 42, 0, 14, 0x7fb2ff).setOrigin(0, 0.5));
      // The book page
      add(this.add.rectangle(width / 2, 385, 1000, 640, 0xe9d8a6).setStrokeStyle(6, 0x6b4423));
      const where = add(this.add.text(width / 2, 88, '', { fontFamily: 'Nunito', fontSize: '15px', fontStyle: '900', color: '#8a6a3a' }).setOrigin(0.5));
      const title = add(this.add.text(width / 2, 116, '', { fontFamily: 'Cinzel', fontSize: '28px', fontStyle: '900', color: '#3a2412' }).setOrigin(0.5));
      const body = add(this.add.text(width / 2, 148, '', {
        fontFamily: 'Cinzel', fontSize: '19px', color: '#2a1a0a', align: 'left', lineSpacing: 7, wordWrap: { width: 900 },
      }).setOrigin(0.5, 0));
      const foot = add(this.add.text(width / 2, 690, '', { fontFamily: 'Nunito', fontSize: '15px', fontStyle: '900', color: '#6b4423' }).setOrigin(0.5));
      const flash = add(this.add.text(width / 2, 72, '', { fontFamily: 'Cinzel', fontSize: '24px', fontStyle: '900', color: '#7dff8a', stroke: '#000', strokeThickness: 6 }).setOrigin(0.5).setAlpha(0));

      let sleep = 40, round = -1, opts = [], sel = 0, optTexts = [], state = 'intro';
      const setSleep = () => { sleepBar.width = 3.96 * Math.max(0, Math.min(100, sleep)); };
      setSleep();

      // Intro page
      where.setText('DELOYE LORE · Vol. 1 of ∞');
      title.setText('Xylo opens the sacred book…');
      body.setText('Read each page aloud to Diddy Chud Giant. Every page stops mid-sentence — choose how the story '
        + 'truly continues. Stay true to the lore and he sinks deeper into sleep. Get it wrong, and he will know.');
      foot.setText('Press SPACE (or click) to begin');

      const clearOpts = () => { optTexts.forEach((t) => t.destroy()); optTexts = []; };
      const render = () => optTexts.forEach((t, i) => t.setText(`${i === sel ? '▶ ' : '   '}${opts[i]}`).setColor(i === sel ? '#7a2a0a' : '#2a1a0a'));

      const nextRound = () => {
        round += 1;
        clearOpts();
        if (round >= LORE_PASSAGES.length) return finish(sleep >= 80);
        state = 'question';
        const L = LORE_PASSAGES[round];
        where.setText(L.where);
        title.setText(L.title);
        body.setText(L.text);
        opts = Phaser.Utils.Array.Shuffle([L.right, ...L.wrong]);
        sel = 0;
        const top = body.y + body.height + 26;
        opts.forEach((o, i) => {
          const t = add(this.add.text(176, top + i * 44, '', {
            fontFamily: 'Cinzel', fontSize: '20px', fontStyle: '900', color: '#2a1a0a', wordWrap: { width: 960 },
          })).setInteractive({ useHandCursor: true });
          t.on('pointerover', () => { sel = i; render(); });
          t.on('pointerdown', () => pick(i));
          optTexts.push(t);
        });
        foot.setText(`Page ${round + 1} of ${LORE_PASSAGES.length} — ↑/↓ + ENTER, 1/2/3, or click: how does the story continue?`);
        render();
        Sfx.play('pop');
      };

      const pick = (i) => {
        if (state !== 'question') return;
        state = 'wait';
        const right = opts[i] === LORE_PASSAGES[round].right;
        if (right) {
          sleep += 15; Sfx.play('sparkle');
          flash.setText('TRUE LORE ✓  (he snuggles deeper)').setColor('#7dff8a');
        } else {
          sleep -= 20; Sfx.play('dramatic'); this.cameras.main.shake(250, 0.008);
          flash.setText('"…that ain\'t canon…" (he stirs)').setColor('#ff6a5a');
        }
        optTexts.forEach((t, j) => { if (opts[j] === LORE_PASSAGES[round].right) t.setColor('#2a7a2a'); });
        setSleep();
        this.tweens.add({ targets: flash, alpha: { from: 1, to: 0 }, duration: 1500 });
        if (sleep <= 0) { this.time.delayedCall(1200, () => finish(false)); return; }
        this.time.delayedCall(1500, nextRound);
      };

      const finish = (won) => {
        state = 'done';
        clearOpts();
        kb.off('keydown', onKey); this.input.off('pointerdown', onClick);
        where.setText('');
        title.setText(won ? 'THE LORE HAS SPOKEN' : 'THE LORE HAS FAILED');
        body.setText(won ? 'Diddy Chud Giant sleeps like a baby.' : 'Diddy Chud Giant is waking up… and he is a lore purist.');
        foot.setText('');
        Sfx.play(won ? 'confirm' : 'boom');
        this.time.delayedCall(1600, () => {
          ui.forEach((o) => o.destroy());
          this.setCharTex(xylo, 'char_xylo'); xylo.img.setFlipX(false);
          resolve(won);
        });
      };

      const kb = this.input.keyboard;
      const onKey = (e) => {
        if (state === 'intro' && (e.code === 'Space' || e.code === 'Enter')) { nextRound(); return; }
        if (state !== 'question') return;
        if (e.code === 'ArrowUp' || e.code === 'KeyW') { sel = (sel + opts.length - 1) % opts.length; Sfx.play('tick'); render(); }
        else if (e.code === 'ArrowDown' || e.code === 'KeyS') { sel = (sel + 1) % opts.length; Sfx.play('tick'); render(); }
        else if (e.code === 'Enter' || e.code === 'Space') pick(sel);
        else if (['Digit1', 'Digit2', 'Digit3'].includes(e.code)) pick(Number(e.code.slice(-1)) - 1);
      };
      const onClick = () => { if (state === 'intro') nextRound(); };
      this.time.delayedCall(400, () => { kb.on('keydown', onKey); this.input.on('pointerdown', onClick); });
    });
  }
}
