import DialogueBox from '../ui/DialogueBox.js';
import { SCENE1 } from '../data/scenes/scene1_the_map.js';

// Scene 1 — "The Map". A staged cutscene for now; free-roam camp comes once
// the overworld exists. Press ESC to skip to the title card.
export default class IntroScene extends Phaser.Scene {
  constructor() { super('Intro'); }

  create() {
    const { width, height } = this.scale;
    this.cameras.main.fadeIn(800, 0, 0, 0);

    // Sky, stars, ground
    const sky = this.add.graphics();
    sky.fillGradientStyle(0x0b0a24, 0x0b0a24, 0x1d1a45, 0x1d1a45, 1).fillRect(0, 0, width, height * 0.52);
    for (let i = 0; i < 90; i++) {
      const s = this.add.circle(Phaser.Math.Between(0, width), Phaser.Math.Between(0, height * 0.48),
        Phaser.Math.FloatBetween(0.6, 1.8), 0xffffff, Phaser.Math.FloatBetween(0.3, 0.9));
      this.tweens.add({ targets: s, alpha: 0.15, yoyo: true, repeat: -1, duration: Phaser.Math.Between(800, 2400) });
    }
    this.add.rectangle(0, height * 0.5, width, height * 0.5, 0x1c2a1a).setOrigin(0);

    // Tents
    const tents = this.add.graphics();
    tents.fillStyle(0x6b5a3a).fillTriangle(100, 360, 220, 240, 340, 360);
    tents.fillStyle(0x5a4a30).fillTriangle(940, 360, 1060, 240, 1180, 360);

    // Campfire (unlit until the map goes in)
    const fx = width / 2, fy = 380;
    this.add.ellipse(fx, fy + 16, 150, 34, 0x3a3030);
    const logs = this.add.graphics();
    logs.fillStyle(0x5b3a22).fillRect(fx - 55, fy, 110, 14).fillRect(fx - 14, fy - 10, 28, 30);
    this.fire = this.add.container(fx, fy);
    [0xff5a1f, 0xffa31a, 0xffe066].forEach((c, i) => {
      const f = this.add.ellipse(0, -18 - i * 6, 64 - i * 18, 90 - i * 22, c, 0.95);
      this.fire.add(f);
      this.tweens.add({ targets: f, scaleY: 1.18, scaleX: 0.9, yoyo: true, repeat: -1, duration: 160 + i * 70 });
    });
    this.fire.setScale(0);
    this.glow = this.add.circle(fx, fy - 20, 260, 0xff8a2a, 0).setBlendMode(Phaser.BlendModes.ADD);

    // Character "standees" (placeholders until real art/sprites)
    this.standee('lykor', 430, 440);
    this.standee('xylo', 1010, 440);
    this.skorn = this.standee('skorn', 820, 462);

    // Lykor's bag
    this.bag = this.add.ellipse(240, 430, 70, 54, 0x7a5a36).setStrokeStyle(2, 0x3d2b18);
    this.bagLabel = this.label(240, 388, 'DO NOT TOUCH (Skorn)').setAlpha(0);
    this.fireLabel = this.label(fx, fy - 140, 'Fire (needs food)').setAlpha(0);

    // Dawn overlay for "the next morning"
    this.dawn = this.add.rectangle(0, 0, width, height, 0xffb37a, 0).setOrigin(0).setBlendMode(Phaser.BlendModes.ADD);

    this.add.text(width - 16, 12, 'ESC: skip', { fontFamily: 'Nunito', fontSize: '16px', color: '#6e6690' }).setOrigin(1, 0);
    this.input.keyboard.once('keydown-ESC', () => this.finish());

    this.dialogue = new DialogueBox(this);
    this.dialogue.play(SCENE1, {
      showBagLabel: () => this.tweenP({ targets: this.bagLabel, alpha: 1, duration: 300 }),
      showFireLabel: () => this.tweenP({ targets: this.fireLabel, alpha: 1, duration: 300 }),
      skornGrabsMap: () => this.skornGrabsMap(),
      burnMap: () => this.burnMap(),
      morning: () => this.tweenP({ targets: this.dawn, alpha: 0.28, duration: 1400 }),
    }).then(() => this.finish());
  }

  standee(id, x, y) {
    const c = this.add.container(x, y);
    const img = this.add.image(0, -60, `portrait_${id}`).setDisplaySize(110, 110);
    const frame = this.add.rectangle(0, -60, 114, 114).setStrokeStyle(3, 0xe8b923);
    const name = this.label(0, 6, id[0].toUpperCase() + id.slice(1));
    c.add([img, frame, name]);
    this.tweens.add({ targets: c, y: y - 4, yoyo: true, repeat: -1, duration: 1200 + Math.random() * 400 });
    return c;
  }

  label(x, y, text) {
    return this.add.text(x, y, text, {
      fontFamily: 'Nunito', fontSize: '18px', fontStyle: '900', color: '#1a1324',
      backgroundColor: '#f3e3b0', padding: { x: 8, y: 2 },
    }).setOrigin(0.5);
  }

  tweenP(cfg) { return new Promise((res) => this.tweens.add({ ...cfg, onComplete: res })); }

  async skornGrabsMap() {
    this.paper = this.add.rectangle(this.bag.x, this.bag.y - 10, 34, 24, 0xf1e6c8).setStrokeStyle(2, 0x8a7a55);
    this.paperLabel = this.label(this.bag.x, this.bag.y - 44, 'map (very important)').setFontSize(14);
    this.tweens.add({ targets: this.paperLabel, alpha: 0, delay: 350, duration: 300 });
    await this.tweenP({ targets: [this.paper, this.paperLabel], x: this.skorn.x + 80, y: '+=40', duration: 700, ease: 'Sine.inOut' });
  }

  async burnMap() {
    const fx = this.fire.x, fy = this.fire.y;
    this.paperLabel.destroy();
    await this.tweenP({ targets: this.paper, x: fx, y: fy - 10, angle: 360, duration: 600 });
    this.paper.destroy();
    this.cameras.main.flash(250, 255, 170, 90);
    this.fireLabel.setText('Fire (fed)');
    this.tweens.add({ targets: this.glow, alpha: 0.18, duration: 500 });
    await this.tweenP({ targets: this.fire, scale: 1, duration: 500, ease: 'Back.out' });
  }

  finish() {
    if (this.finished) return;
    this.finished = true;
    this.cameras.main.fadeOut(900, 0, 0, 0);
    this.cameras.main.once('camerafadeoutcomplete', () => this.scene.start('Title'));
  }
}
