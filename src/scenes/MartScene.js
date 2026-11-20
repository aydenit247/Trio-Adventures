import StageScene, { at } from './StageScene.js';
import { SCENE3 } from '../data/scenes/scene3_metocy_mart.js';
import Sfx from '../audio/Sfx.js';

// Scene 3 — Metocy Mart. "Hey guys, it's your boy Dulbers Frint!" — then midtocy, then a demon.
export default class MartScene extends StageScene {
  constructor() { super('Mart'); }

  create() {
    this.nextScene = 'Pass';
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
        if (this.pill) {
          this.tweens.add({ targets: [this.pill, this.pillGlow, this.pillLabel], alpha: 0, scale: 0.2, duration: 400 });
        }
        for (let i = 0; i < 3; i++) { Sfx.play('gulp'); this.hop([xylo, lykor, skorn][i], 10); await this.wait(450); }
      },
      tripStart: () => this.tripStart(),
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

  async revealMidtocy() {
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
    if (this.swirl) this.swirl.stop();
    await this.swapBg('bg_mart_interior', 700);
    this.light = 'candle';
    ['xylo', 'lykor', 'skorn'].forEach((k) => { this.setCharTex(this.chars[k], `char_${k}`); this.chars[k].img.setFlipX(true); });
  }
}
