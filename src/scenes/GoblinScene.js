import StageScene, { at } from './StageScene.js';
import { SCENE2 } from '../data/scenes/scene2_goblins.js';
import Sfx from '../audio/Sfx.js';

// Scene 2 — Goblin Village. The goblins decide Lykor is a god.
export default class GoblinScene extends StageScene {
  constructor() { super('Goblin'); }

  create() {
    this.nextScene = 'Mart';
    // Story flags this scene can set (they change later scenes)
    ['goblinAllies', 'skornKing', 'chugWon', 'lykorDethroned', 'foreheadLoser'].forEach((f) => this.registry.set(f, false));
    this.registry.set('inv_beer', 0);
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
      giftBeezy: () => this.giftBeezy(),
      chugGame: async () => {
        const won = await this.mashGame({
          title: 'BEEZY CHUG-OFF', hint: 'Mash SPACE (or click) to chug!',
          you: { portrait: 'lykor', label: 'Lykor' },
          rival: { portrait: 'chief', label: 'Chief Bogdrinker (400-year champ)' },
        });
        this.registry.set('chugWon', won);
      },
      passOut: () => this.passOut(),
      wakeOutside: () => this.wakeOutside(),
      crownSkorn: () => this.crownSkorn(),
      dethrone: () => this.dethrone(),
      sneak: () => this.sneak(),
      sneakCaught: () => { Sfx.play('dramatic'); this.lykor.img.setFlipX(false); this.hop(this.lykor, 20); return this.wait(400); },
      sneakReturn: () => this.sneakReturn(),
      skornSlap: () => this.skornSlap(),
      fightGoblins: () => this.fight('goblins'),
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
    this.kingLabel = this.charLabel(this.lykor, 'King (Temporary)');
    await this.showLabel(this.kingLabel);
  }

  async giftBeezy() {
    Sfx.play('grab');
    const mugs = [0, 1, 2].map((i) => {
      const m = this.add.image(900 + i * 70, 260, 'item_beer').setDepth(45).setAlpha(0);
      m.setScale(70 / m.width);
      return m;
    });
    await Promise.all(mugs.map((m, i) => this.tweenP({ targets: m, alpha: 1, y: 230, duration: 300, delay: i * 120, ease: 'Back.out' })));
    await this.wait(400);
    await Promise.all(mugs.map((m) => this.tweenP({ targets: m, x: this.lykor.x, y: this.lykor.y - 200, scale: m.scale * 0.4, alpha: 0, duration: 450 })));
    mugs.forEach((m) => m.destroy());
    this.registry.set('inv_beer', (this.registry.get('inv_beer') || 0) + 3);
  }

  async passOut() {
    Sfx.play('boom');
    if (this.beezyMug) this.beezyMug.setVisible(false);
    await this.tweenP({ targets: this.lykor, angle: -88, y: this.lykor.y + 40, duration: 500, ease: 'Bounce.out' });
    this.cameras.main.fade(700, 0, 0, 0, true);
    await this.wait(900);
  }

  async wakeOutside() {
    this.registry.set('foreheadLoser', true);
    this.bg.destroy();
    this.bg = this.placeBg('bg_goblin_village');
    this.goblins.forEach((g) => g.setVisible(false));
    this.chief.setVisible(false);
    if (this.kingLabel) this.kingLabel.destroy();
    this.chars.xylo.setPosition(260, 570); this.chars.skorn.setPosition(1000, 585);
    this.lykor.setAngle(0).setPosition(640, 565);
    this.cameras.main.fadeIn(800, 0, 0, 0);
    await this.wait(800);
    await this.showLabel(this.charLabel(this.lykor, 'METOCY MART, EAST. LOSER.'));
  }

  async crownSkorn() {
    this.registry.set('skornKing', true);
    Sfx.play('choir');
    const skorn = this.chars.skorn;
    await this.showLabel(this.charLabel(skorn, 'The Purple King (Downgrade)'));
    if (this.kingLabel) this.kingLabel.setText('King (Former)');
    this.goblins.forEach((g) => { this.setCharTex(g, 'char_goblin_kneel', 150); g.img.setFlipX(g.x > skorn.x); });
  }

  async dethrone() {
    this.registry.set('lykorDethroned', true);
    Sfx.play('dramatic');
    if (this.kingLabel) this.kingLabel.setText('Lykor (Dethroned)');
    this.mugOwner = this.chars.skorn; // the beezy goes to Skorn
    this.hop(this.chars.skorn, 14);
    await this.wait(400);
  }

  // A goblin brings Lykor a mug of beer
  async beezy() {
    const mug = this.add.container(this.lykor.x + 300, this.lykor.y - 150).setDepth(40).setAlpha(0);
    const img = this.add.image(0, 0, 'item_beer');
    img.setScale(64 / img.width);
    mug.add([img, this.label(0, -48, 'Beezy (Beer)', 15)]);
    this.mugOwner = this.lykor;
    Sfx.play('pop');
    await this.tweenP({ targets: mug, alpha: 1, x: this.lykor.x + 70, y: this.lykor.y - 190, duration: 600, ease: 'Back.out' });
    Sfx.play('sparkle');
    this.hop(this.lykor, 12);
    this.beezyMug = mug;
    const follow = () => { if (mug.active && this.mugOwner) mug.setPosition(this.mugOwner.x + 70, this.mugOwner.y - 190); };
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
    const party = [this.chars.xylo, this.lykor];
    if (!this.registry.get('skornKing')) party.push(this.chars.skorn); // the Purple King stays behind
    if (this.registry.get('goblinAllies')) party.push(...this.goblins, this.chief);
    party.forEach((c, i) => this.time.delayedCall(i * 250, () => this.walk(c, 1450, 2)));
    await this.wait(1500);
  }
}
