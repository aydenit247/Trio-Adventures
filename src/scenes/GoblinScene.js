import StageScene, { at } from './StageScene.js';
import { SCENE2 } from '../data/scenes/scene2_goblins.js';
import Sfx from '../audio/Sfx.js';

// Scene 2 — Goblin Village. The goblins decide Lykor is a god.
export default class GoblinScene extends StageScene {
  constructor() { super('Goblin'); }

  create() {
    this.nextScene = 'Mart';
    this.registry.set('goblinAllies', false); // set again if the goblins tag along
    this.setupStage({ light: 'day' });
    Sfx.startLoop('village');

    this.bg = this.placeBg('bg_goblin_village');
    this.fog(0xfff0d0, 0.05, 300, 470);

    // Sunbeams drifting through the trees
    for (let i = 0; i < 3; i++) {
      const beam = this.add.image(250 + i * 330, 120, 'fx_soft').setScale(3, 14).setAngle(18)
        .setTint(0xffe2a8).setAlpha(0.08).setBlendMode(Phaser.BlendModes.ADD).setDepth(3);
      this.tweens.add({ targets: beam, alpha: 0.03, yoyo: true, repeat: -1, duration: 3000 + i * 900, ease: 'Sine.inOut' });
    }

    // The party starts off-screen left
    const skorn = this.makeChar('skorn', -150, 578, { h: 350 });
    const lykor = this.makeChar('lykor', -150, 562, { h: 330 });
    const xylo = this.makeChar('xylo', -150, 566, { h: 330 });

    // Goblins hide until they spot Lykor
    this.goblins = [
      this.makeChar('gob1', 820, 548, { tex: 'char_goblin', voice: 'goblin', h: 200 }),
      this.makeChar('gob2', 975, 530, { tex: 'char_goblin', voice: 'goblin', h: 180, flip: true }),
      this.makeChar('gob3', 1120, 566, { tex: 'char_goblin', voice: 'goblin', h: 215 }),
    ];
    this.goblins.forEach((g) => g.setVisible(false));
    this.chief = this.makeChar('chief', 690, 560, { tex: 'char_goblin_chief', voice: 'chief', h: 245 });
    this.chief.setVisible(false);

    this.finishStage();
    this.dialogue.play(SCENE2, this.baseHooks({
      enterParty: () => Promise.all([this.walk(xylo, 170), this.walk(skorn, 360), this.walk(lykor, 540)])
        .then(() => [xylo, skorn, lykor].forEach((c) => c.img.setFlipX(false))),
      goblinsAppear: () => this.goblinsAppear(),
      goblinsKneel: () => this.goblinsKneel(),
      chiefAppears: () => { Sfx.play('pop'); return this.showChar(this.chief, 500).then(() => this.showLabel(this.charLabel(this.chief, 'Chief Bogdrinker'))); },
      toThrone: () => this.toThrone(),
      crown: () => this.crown(),
      goblinsBlock: () => this.goblinsBlock(),
      beezy: () => this.beezy(),
      sneak: () => this.sneak(),
      sneakCaught: () => { Sfx.play('dramatic'); this.lykor.img.setFlipX(false); this.hop(this.lykor, 20); return this.wait(400); },
      sneakReturn: () => this.sneakReturn(),
      skornSlap: () => this.skornSlap(),
      fightGoblins: () => this.fightPlaceholder('Skorn vs. The Goblins'),
      skornRespect: () => this.showLabel(this.charLabel(this.chars.skorn, 'Skorn (Respected now)')),
      goblinsJoin: () => {
        this.registry.set('goblinAllies', true);
        Sfx.play('choir');
        [...this.goblins, this.chief].forEach((g) => this.hop(g, 16));
        return this.showLabel(this.charLabel(this.goblins[1], 'Goblins (Coming Along, Unfortunately)'));
      },
      goblinsCry: () => { Sfx.play('choir'); this.goblins.forEach((g) => this.hop(g, 14)); return this.wait(300); },
      leave: () => this.leave(),
    })).then(() => this.finish(this.nextScene));
  }

  get lykor() { return this.chars.lykor; }

  async goblinsAppear() {
    Sfx.play('pop');
    for (const g of this.goblins) { this.showChar(g, 300); await this.wait(180); }
    this.gobLabel = this.charLabel(this.goblins[0], 'Goblin (Unemployed)');
    await this.showLabel(this.gobLabel);
  }

  async goblinsKneel() {
    Sfx.play('choir');
    this.cameras.main.flash(400, 255, 240, 200);
    this.gobLabel.setVisible(false);
    // Kneeling art faces right; they kneel toward Lykor on the left
    this.goblins.forEach((g) => { this.setCharTex(g, 'char_goblin_kneel', 150); g.img.setFlipX(true); });
    this.lykorLabel = this.charLabel(this.lykor, 'The Mogging Elf (allegedly)');
    await this.showLabel(this.lykorLabel);
  }

  async toThrone() {
    const cam = this.cameras.main;
    cam.fade(400, 0, 0, 0, true);
    await this.wait(420);
    this.bg.destroy();
    this.bg = this.placeBg('bg_goblin_throne');
    const throne = at(470, 395); // throne base in the art
    Object.assign(this.chars.skorn, { x: 215, y: 590 });
    Object.assign(this.chars.xylo, { x: 1175, y: 584 });
    this.lykor.setPosition(throne.x, throne.y + 40).setDepth(12);
    this.chief.setPosition(950, 572);
    const spots = [[380, 585, false], [800, 590, true], [1040, 560, true]];
    this.goblins.forEach((g, i) => {
      g.setPosition(spots[i][0], spots[i][1]);
      g.img.setFlipX(!spots[i][2]); // face the throne
    });
    // Kneeling goblins face right by default (art), flip to face the throne
    this.goblins[0].img.setFlipX(false);
    this.goblins[1].img.setFlipX(true);
    this.goblins[2].img.setFlipX(true);
    if (this.lykorLabel) this.lykorLabel.setVisible(false);
    cam.fadeIn(500, 0, 0, 0);
    await this.wait(500);
  }

  async crown() {
    Sfx.play('sparkle');
    const l = this.charLabel(this.lykor, 'King (Temporary)');
    await this.showLabel(l);
  }

  // A goblin brings Lykor a mug of beer
  async beezy() {
    const l = this.lykor;
    const mug = this.add.container(l.x + 300, l.y - 150).setDepth(40).setAlpha(0);
    const g = this.add.graphics();
    g.fillStyle(0x6b4423).fillRoundedRect(-18, -24, 36, 48, 5);          // wooden mug
    g.fillStyle(0xe8a317, 0.95).fillRect(-14, -16, 28, 36);             // beer
    g.fillStyle(0xfff6dc).fillEllipse(-6, -24, 22, 14).fillEllipse(8, -26, 22, 16); // foam
    g.lineStyle(5, 0x6b4423).strokeEllipse(24, 0, 18, 26);              // handle
    mug.add(g);
    const tag = this.label(0, -52, 'Beezy (Beer)', 15);
    mug.add(tag);
    Sfx.play('pop');
    await this.tweenP({ targets: mug, alpha: 1, x: l.x + 70, y: l.y - 190, duration: 600, ease: 'Back.out' });
    Sfx.play('sparkle');
    this.hop(l, 12);
    this.beezyMug = mug;
    const follow = () => { if (mug.active) mug.setPosition(l.x + 70, l.y - 190); };
    this.events.on('postupdate', follow);
    this.events.once('shutdown', () => this.events.off('postupdate', follow));
    await this.wait(300);
  }

  async goblinsBlock() {
    // Goblins stand up and crowd in front of the king
    Sfx.play('dramatic');
    const xs = [470, 640, 760];
    await Promise.all(this.goblins.map((g, i) => {
      this.setCharTex(g, 'char_goblin', 190);
      g.img.setFlipX(false);
      return this.tweenP({ targets: g, x: xs[i], y: 600, duration: 400, ease: 'Back.out' });
    }));
  }

  async sneak() {
    Sfx.play('tiptoe');
    const goSlow = (c, x) => this.walk(c, x, 6);
    goSlow(this.lykor, 120);
    await this.wait(500);
    this.goblins.forEach((g, i) => goSlow(g, 260 + i * 110));
    Sfx.play('tiptoe');
    await this.wait(1800);
  }

  async sneakReturn() {
    await Promise.all([
      this.walk(this.lykor, 560),
      ...this.goblins.map((g, i) => this.walk(g, 470 + i * 150)),
    ]);
    this.lykor.img.setFlipX(false);
  }

  async skornSlap() {
    const skorn = this.chars.skorn;
    const target = this.goblins[0];
    await this.walk(skorn, target.x - 120);
    Sfx.play('whoosh');
    await this.tweenP({ targets: skorn, x: skorn.x + 50, duration: 120, yoyo: true });
    Sfx.play('boom');
    this.cameras.main.shake(300, 0.012);
    this.tweens.add({ targets: target, angle: 12, x: target.x + 40, yoyo: true, duration: 150 });
  }

  async leave() {
    const party = [this.chars.xylo, this.lykor, this.chars.skorn];
    if (this.registry.get('goblinAllies')) party.push(...this.goblins, this.chief);
    party.forEach((c, i) => this.time.delayedCall(i * 250, () => this.walk(c, 1450, 2)));
    await this.wait(1500);
  }
}
