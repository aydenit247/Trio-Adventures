import StageScene, { at } from './StageScene.js';
import { SCENE3 } from '../data/scenes/scene3_metocy_mart.js';
import Sfx from '../audio/Sfx.js';

// Scene 3 — Metocy Mart. "Hey guys, it's your boy Dulbers Frint!" — then midtocy, then a demon.
export default class MartScene extends StageScene {
  constructor() { super('Mart'); }

  create() {
    this.nextScene = 'Pass';
    // Story flags this scene can set
    ['hasMidtocy', 'dulbersEscaped', 'dulbersDead'].forEach((f) => this.registry.set(f, false));
    this.setupStage({ light: 'moon' });
    Sfx.startLoop('night');

    this.bg = this.placeBg('bg_mart_exterior');
    this.fog(0xa8b8e8, 0.06, 360, 500);

    // Lantern glows on the shopfront
    [[205, 245], [600, 120], [655, 285], [905, 265]].forEach(([x, y]) => {
      const p = at(x, y);
      const g = this.add.image(p.x, p.y, 'fx_glow').setScale(0.45).setBlendMode(Phaser.BlendModes.ADD).setAlpha(0.35).setDepth(3);
      this.tweens.add({ targets: g, alpha: 0.22, yoyo: true, repeat: -1, duration: 180 + Math.random() * 200 });
    });

    const xylo = this.makeChar('xylo', 1450, 566, { h: 330 });
    const lykor = this.makeChar('lykor', 1450, 560, { h: 325 });
    const skorn = this.makeChar('skorn', 1450, 580, { h: 350 });
    if (this.registry.get('skornKing')) skorn.setVisible(false); // still with the goblins, for now
    // Goblin entourage (only if they came along in Scene 2)
    this.allies = [];
    if (this.registry.get('goblinAllies')) {
      this.allies = [
        this.makeChar('gob1', 1500, 612, { tex: 'char_goblin', voice: 'goblin', h: 165 }),
        this.makeChar('gob2', 1500, 618, { tex: 'char_goblin', voice: 'goblin', h: 155 }),
        this.makeChar('chief', 1500, 606, { tex: 'char_goblin_chief', voice: 'chief', h: 195 }),
      ];
    }
    this.dulbers = this.makeChar('dulbers', 470, 560, { h: 235 });
    this.dulbers.setVisible(false);
    this.demon = this.makeChar('demon', 520, 590, { tex: 'char_dulbers_demon', voice: 'dulbers_demon', h: 430 });
    this.demon.setVisible(false);

    // Sign text on the blank board
    const board = at(355, 140);
    this.sign = this.add.container(board.x, board.y).setDepth(5).setAlpha(0);
    this.sign.add([
      this.add.text(0, -10, 'METOCY MART', { fontFamily: 'Cinzel', fontSize: '24px', fontStyle: '900', color: '#f1dfb0', stroke: '#1a0f06', strokeThickness: 4 }).setOrigin(0.5),
      this.add.text(0, 16, 'For all yo metocy needs n shi folk', { fontFamily: 'Nunito', fontSize: '11px', fontStyle: '900', color: '#f1dfb0', stroke: '#1a0f06', strokeThickness: 3 }).setOrigin(0.5),
    ]);

    this.finishStage();
    this.dialogue.play(SCENE3, this.baseHooks({
      enterParty: () => Promise.all([
        this.walk(xylo, 720, 2), this.walk(lykor, 900, 2.1),
        this.registry.get('skornKing') ? Promise.resolve() : this.walk(skorn, 1090, 2.2),
        ...this.allies.map((g, i) => this.walk(g, [1190, 1250, 1130][i], 2.4)),
      ]).then(() => {
        [xylo, lykor, skorn, ...this.allies].forEach((c) => c.img.setFlipX(true));
        // Still has the goblins' writing on his forehead
        if (this.registry.get('foreheadLoser')) this.charLabel(lykor, 'METOCY MART, EAST. LOSER.').setAlpha(1);
      }),
      showSign: async () => {
        Sfx.play('sparkle');
        await this.tweenP({ targets: this.sign, alpha: 1, duration: 500 });
        this.cameras.main.pan(this.sign.x + 200, 300, 600, 'Sine.easeInOut');
        await this.wait(1200);
        this.cameras.main.pan(640, 360, 600, 'Sine.easeInOut');
        await this.wait(600);
      },
      dulbersAppears: async () => {
        Sfx.play('door');
        await this.showChar(this.dulbers, 300);
        this.hop(this.dulbers, 24);
        await this.showLabel(this.charLabel(this.dulbers, 'Dulbers Frint (Trustworthy)'));
      },
      enterShop: () => this.enterShop(),
      showPill: () => this.showPill(),
      skornBurstsIn: async () => {
        Sfx.play('door'); Sfx.play('boom');
        this.cameras.main.shake(300, 0.01);
        skorn.setPosition(1400, 585).setVisible(true).setAlpha(1);
        await this.walk(skorn, 1165, 1.4);
        skorn.img.setFlipX(true);
        await this.showLabel(this.charLabel(skorn, 'The Purple King (Former)'));
      },
      takeIt: async () => {
        this.hidePill();
        for (let i = 0; i < 3; i++) { Sfx.play('gulp'); this.hop([xylo, lykor, skorn][i], 10); await this.wait(450); }
      },
      tripStart: () => this.tripStart(),
      skornTakes: async () => { this.hidePill(); Sfx.play('gulp'); this.hop(skorn, 10); await this.wait(500); },
      skornTrip: () => this.skornTrip(),
      kickedOut: () => this.kickedOut(),
      showPassSign: () => this.showPassSign(),
      xyloLore: () => this.xyloLore(),
      xyloLoreEnd: () => { this.setCharTex(xylo, 'char_xylo'); xylo.img.setFlipX(true); if (this.loreFx) this.loreFx.stop(); },
      giveMidtocy: () => this.giveMidtocy(),
      dulbersEscape: () => this.dulbersEscape(),
      skornPockets: async () => {
        this.registry.set('hasMidtocy', true);
        Sfx.play('grab');
        const l = this.charLabel(skorn, 'Midtocy (Pocketed)');
        await this.showLabel(l);
        this.time.delayedCall(1800, () => this.tweens.add({ targets: l, alpha: 0, duration: 400, onComplete: () => l.destroy() }));
      },
      goblinsTaste: async () => {
        this.hidePill();
        for (const g of this.allies) { Sfx.play('gulp'); this.hop(g, 10); await this.wait(250); }
        this.allies.forEach((g) => g.img.setTint(0xc8a0ff));
      },
      goblinChase: () => this.goblinChase(),
      goblinsGoHome: async () => {
        await Promise.all(this.allies.map((g, i) => this.walk(g, 1500 + i * 60, 1.6)));
        this.allies.forEach((g) => g.setVisible(false));
        this.registry.set('goblinAllies', false);
      },
      leaveRight: async () => {
        const party = [xylo, lykor, skorn].filter((c) => c.visible);
        party.forEach((c, i) => this.time.delayedCall(i * 200, () => this.walk(c, 1500, 1.8)));
        await this.wait(1600);
      },
      revealMidtocy: () => this.revealMidtocy(),
      transform: () => this.transform(),
      fightDulbers: () => this.fightPlaceholder(this.allies.length ? 'The Party (+ Goblins) vs. Dulbers Frint' : 'The Party vs. Dulbers Frint'),
      tripEnd: () => this.tripEnd(),
      dulbersVanish: async () => {
        Sfx.play('boom'); this.cameras.main.flash(300, 160, 90, 255);
        this.demon.setVisible(false);
        if (this.demonLabel) this.demonLabel.setVisible(false);
        await this.wait(400);
      },
    })).then(() => this.finish(this.nextScene));
  }

  async enterShop() {
    Sfx.play('door');
    const cam = this.cameras.main;
    cam.fade(400, 0, 0, 0, true);
    await this.wait(420);
    Sfx.stopLoop('night'); Sfx.startLoop('shop');
    this.sign.setVisible(false);
    this.bg.destroy();
    this.bg = this.placeBg('bg_mart_interior');
    this.light = 'candle';
    // Dulbers by the counter, party by the door
    this.dulbers.setPosition(470, 565).img.setFlipX(false);
    this.chars.xylo.setPosition(860, 570);
    this.chars.lykor.setPosition(1010, 562);
    if (!this.registry.get('skornKing')) this.chars.skorn.setPosition(1165, 585);
    this.allies.forEach((g, i) => g.setPosition([745, 805, 680][i], [622, 628, 618][i]));
    Object.values(this.chars).forEach((c) => { if (c !== this.dulbers) c.img.setFlipX(true); });
    // Candle glows
    [[330, 320], [495, 300], [740, 300], [1000, 330]].forEach(([x, y]) => {
      const p = at(x, y);
      const g = this.add.image(p.x, p.y, 'fx_glow').setScale(0.3).setBlendMode(Phaser.BlendModes.ADD).setAlpha(0.3).setDepth(3);
      this.tweens.add({ targets: g, alpha: 0.18, yoyo: true, repeat: -1, duration: 150 + Math.random() * 250 });
    });
    cam.fadeIn(500, 0, 0, 0);
    await this.wait(500);
  }

  async tripStart() {
    Sfx.play('dramatic');
    this.cameras.main.flash(500, 180, 80, 255);
    await this.swapBg('bg_mart_interior_trip', 900);
    ['xylo', 'lykor', 'skorn'].forEach((k) => this.setCharTex(this.chars[k], `char_${k}_tweaking`));
    ['xylo', 'lykor', 'skorn'].forEach((k) => this.chars[k].img.setFlipX(true));
    this.tripOn();
    // Swirling particles
    this.swirl = this.add.particles(640, 360, 'fx_soft', {
      x: { min: -640, max: 640 }, y: { min: -360, max: 360 }, speed: { min: 10, max: 40 },
      scale: { start: 0.5, end: 0 }, alpha: { start: 0.35, end: 0 }, lifespan: 3000, frequency: 60,
      tint: [0xb06bff, 0x5bffb0, 0xff6bd5], blendMode: 'ADD',
    }).setDepth(6);
    await this.wait(500);
  }

  // Removes the floating "Metocy (100% Real)" pill once it's taken, exposed or no longer relevant
  hidePill() {
    if (!this.pill) return;
    const t = [this.pill, this.pillGlow, this.pillLabel];
    this.tweens.killTweensOf(t);
    this.tweens.add({ targets: t, alpha: 0, duration: 300, onComplete: () => t.forEach((o) => o.destroy()) });
    this.pill = null;
  }

  async showPill() {
    Sfx.play('sparkle');
    const p = at(520, 285);
    this.pillGlow = this.add.image(p.x, p.y, 'fx_glow').setScale(0.6).setTint(0x7fb2ff)
      .setBlendMode(Phaser.BlendModes.ADD).setAlpha(0).setDepth(28);
    this.pill = this.add.image(p.x, p.y, 'item_metocy').setDepth(29).setAlpha(0);
    this.pill.setScale(170 / this.pill.width);
    this.pillLabel = this.label(p.x, p.y - 62, 'Metocy (100% Real)', 16).setAlpha(0);
    this.tweens.add({ targets: [this.pill, this.pillGlow], alpha: 1, duration: 400 });
    this.tweens.add({ targets: [this.pill, this.pillGlow], y: p.y - 10, yoyo: true, repeat: -1, duration: 1200, ease: 'Sine.inOut' });
    await this.showLabel(this.pillLabel);
  }

  // Only Skorn trips: he wobbles in a purple haze, the rest of the screen stays sober
  async skornTrip() {
    const skorn = this.chars.skorn;
    Sfx.play('dramatic');
    this.setCharTex(skorn, 'char_skorn_tweaking'); skorn.img.setFlipX(true);
    this.skornWobble = this.tweens.add({ targets: skorn, angle: { from: -4, to: 4 }, yoyo: true, repeat: -1, duration: 700, ease: 'Sine.inOut' });
    this.skornHaze = this.add.particles(skorn.x, skorn.y - 180, 'fx_soft', {
      x: { min: -90, max: 90 }, y: { min: -150, max: 150 }, speed: { min: 5, max: 25 },
      scale: { start: 0.35, end: 0 }, alpha: { start: 0.4, end: 0 }, lifespan: 1800, frequency: 90,
      tint: [0xb06bff, 0x5bffb0, 0xff6bd5], blendMode: 'ADD',
    }).setDepth(20);
    Sfx.startLoop('trip');
    await this.wait(400);
  }

  async kickedOut() {
    this.hidePill();
    Sfx.play('door'); Sfx.play('boom');
    const cam = this.cameras.main;
    cam.shake(250, 0.01);
    cam.fade(300, 0, 0, 0, true);
    await this.wait(320);
    Sfx.stopLoop('shop'); Sfx.startLoop('night');
    this.bg.destroy();
    this.bg = this.placeBg('bg_mart_exterior');
    this.light = 'moon';
    this.sign.setVisible(true).setAlpha(1);
    this.dulbers.setVisible(false);
    this.chars.xylo.setPosition(560, 572);
    this.chars.lykor.setPosition(740, 566);
    this.chars.skorn.setPosition(930, 586);
    ['xylo', 'lykor', 'skorn'].forEach((k) => this.chars[k].img.setFlipX(false));
    this.registry.set('dulbersEscaped', true);
    cam.fadeIn(400, 0, 0, 0);
    await this.wait(400);
  }

  async showPassSign() {
    Sfx.play('sparkle');
    const x = 1150, y = 470;
    const sign = this.add.container(x, y).setDepth(12).setAlpha(0);
    const g = this.add.graphics();
    g.fillStyle(0x4a3220).fillRect(-6, -10, 12, 120);                 // post
    g.fillStyle(0x7a5532).fillRoundedRect(-95, -60, 190, 56, 6);       // board
    g.lineStyle(3, 0x3a2414).strokeRoundedRect(-95, -60, 190, 56, 6);
    sign.add([g, this.add.text(0, -32, "GIANT'S PASS →", {
      fontFamily: 'Cinzel', fontSize: '22px', fontStyle: '900', color: '#f1dfb0', stroke: '#1a0f06', strokeThickness: 4,
    }).setOrigin(0.5)]);
    await this.tweenP({ targets: sign, alpha: 1, duration: 400 });
    this.hop(this.chars.skorn, 10);
  }

  async xyloLore() {
    const xylo = this.chars.xylo;
    Sfx.play('sparkle'); Sfx.play('choir');
    this.setCharTex(xylo, 'char_xylo_lore', 340);
    this.loreFx = this.add.particles(xylo.x, xylo.y - 200, 'fx_soft', {
      speedY: { min: -60, max: -20 }, speedX: { min: -40, max: 40 }, scale: { start: 0.25, end: 0 },
      alpha: { start: 0.8, end: 0 }, lifespan: 1600, frequency: 70, tint: [0xffd27a, 0xfff2b0], blendMode: 'ADD',
    }).setDepth(20);
    await this.showLabel(this.charLabel(xylo, 'Deloye Lore (Vol. 1 of ∞)'));
  }

  async giveMidtocy() {
    this.registry.set('hasMidtocy', true);
    Sfx.play('grab');
    const pill = this.add.image(this.dulbers.x, this.dulbers.y - 150, 'item_midtocy').setDepth(45);
    pill.setScale(90 / pill.width);
    const skorn = this.chars.skorn;
    await this.tweenP({ targets: pill, x: skorn.x, y: skorn.y - 200, angle: 360, duration: 700, ease: 'Sine.inOut' });
    await this.tweenP({ targets: pill, alpha: 0, scale: pill.scale * 0.3, duration: 250 });
    pill.destroy();
    this.hop(skorn, 10);
  }

  async dulbersEscape() {
    // A flash of his demon form, then he's gone
    this.registry.set('dulbersEscaped', true);
    const d = this.dulbers;
    Sfx.play('boom');
    this.cameras.main.flash(200, 255, 60, 30);
    this.setCharTex(d, 'char_dulbers_demon', 300);
    await this.wait(450);
    this.cameras.main.flash(300, 160, 90, 255);
    const p = this.add.particles(d.x, d.y - 120, 'fx_soft', {
      speed: { min: 60, max: 220 }, scale: { start: 0.6, end: 0 }, lifespan: 800, tint: [0x8a4fff, 0x2a1a3a], emitting: false,
    }).setDepth(40);
    p.explode(50);
    d.setVisible(false);
    const l = this.label(d.x, d.y - 260, 'Dulbers Frint (Will Be Back)', 18);
    l.setAlpha(0);
    await this.showLabel(l);
    this.time.delayedCall(2200, () => this.tweens.add({ targets: l, alpha: 0, duration: 500 }));
  }

  // Cartoon chase: the goblins run Dulbers around the shop, then a dust-cloud brawl
  async goblinChase() {
    const d = this.dulbers;
    const gobs = this.allies;
    gobs.forEach((g) => this.setCharTex(g, 'char_goblin_fight', g.h));
    Sfx.play('dramatic');
    const lap = async (toX) => {
      d.img.setFlipX(toX < d.x);
      gobs.forEach((g) => g.img.setFlipX(toX < g.x));
      Sfx.play('tiptoe');
      await Promise.all([
        this.walk(d, toX, 0.9),
        ...gobs.map((g, i) => this.wait(150 + i * 90).then(() => this.walk(g, toX + (toX < 640 ? 1 : -1) * (90 + i * 60), 0.95))),
      ]);
    };
    await lap(120); await lap(1150); await lap(380);
    // Brawl cloud
    const cx = 520, cy = 470;
    [d, ...gobs].forEach((c) => c.setVisible(false));
    Sfx.play('boom');
    const cloud = this.add.particles(cx, cy, 'fx_soft', {
      x: { min: -120, max: 120 }, y: { min: -90, max: 60 }, speed: { min: 20, max: 80 },
      scale: { start: 1.2, end: 2.2 }, alpha: { start: 0.55, end: 0 }, lifespan: 900, frequency: 25, tint: 0xb8a890,
    }).setDepth(35);
    const words = ['BONK!', 'POW!', 'SPOON!', 'NO REFUNDS!', 'BOGDRINKER!', 'OW!'];
    for (let i = 0; i < 9; i++) {
      const w = this.add.text(cx + Phaser.Math.Between(-150, 150), cy + Phaser.Math.Between(-140, 40), words[i % words.length], {
        fontFamily: 'Cinzel', fontSize: '30px', fontStyle: '900', color: '#ffdf4a', stroke: '#000', strokeThickness: 6,
      }).setOrigin(0.5).setDepth(36).setAngle(Phaser.Math.Between(-20, 20)).setScale(0.3);
      this.tweens.add({ targets: w, scale: 1, duration: 150, ease: 'Back.out', yoyo: true, hold: 250, onComplete: () => w.destroy() });
      this.cameras.main.shake(120, 0.008);
      Sfx.play(i % 2 ? 'boom' : 'pop');
      await this.wait(260);
    }
    cloud.stop();
    await this.wait(700);
    cloud.destroy();
    this.registry.set('dulbersDead', true);
    // Only goblins walk out of the cloud
    gobs.forEach((g, i) => { g.setPosition(cx - 120 + i * 120, 615); g.setVisible(true); g.img.clearTint(); this.setCharTex(g, i === 2 ? 'char_goblin_chief' : 'char_goblin', g.h); });
    Sfx.play('choir');
  }

  async revealMidtocy() {
    this.hidePill();
    // The pill they took, as it really is
    const fake = this.add.image(640, 230, 'item_midtocy').setDepth(45).setAlpha(0);
    const s = 300 / fake.width;
    fake.setScale(s * 0.3);
    Sfx.play('boom');
    await this.tweenP({ targets: fake, alpha: 1, scale: s, angle: 8, duration: 450, ease: 'Back.out' });
    this.tweens.add({ targets: fake, angle: -8, yoyo: true, repeat: -1, duration: 700, ease: 'Sine.inOut' });
    const fl = this.label(640, 340, 'MIDTOCY', 26).setDepth(46).setAlpha(0);
    await this.showLabel(fl);
    this.time.delayedCall(2500, () => this.tweens.add({ targets: [fake, fl], alpha: 0, duration: 500, onComplete: () => { fake.destroy(); fl.destroy(); } }));
    Sfx.play('dramatic');
    const shelf = at(150, 225);
    const l = this.label(shelf.x + 40, shelf.y - 40, 'MIDTOCY (fake, made in a bucket)', 17);
    l.setAlpha(0);
    await this.showLabel(l);
    this.cameras.main.shake(250, 0.006);
  }

  async transform() {
    Sfx.play('boom');
    this.dulbers.setVisible(false);
    await this.playCutscene('vid_dulbers_transform', { keyed: true });
    Sfx.play('boom');
    this.cameras.main.shake(500, 0.014);
    await this.showChar(this.demon, 200);
    this.demonLabel = this.charLabel(this.demon, 'Dulbers Frint (Not Trustworthy)');
    await this.showLabel(this.demonLabel);
  }

  async tripEnd() {
    this.tripOff();
    Sfx.stopLoop('trip');
    if (this.swirl) this.swirl.stop();
    if (this.skornWobble) { this.skornWobble.stop(); this.chars.skorn.setAngle(0); }
    if (this.skornHaze) this.skornHaze.stop();
    await this.swapBg('bg_mart_interior', 700);
    this.light = 'candle';
    ['xylo', 'lykor', 'skorn'].forEach((k) => { this.setCharTex(this.chars[k], `char_${k}`); this.chars[k].img.setFlipX(true); });
  }
}
