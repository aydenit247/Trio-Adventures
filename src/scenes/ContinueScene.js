import { vignette } from '../fx.js';
import Sfx from '../audio/Sfx.js';

// End of what's built so far.
export default class ContinueScene extends Phaser.Scene {
  constructor() { super('Continue'); }

  create() {
    const { width, height } = this.scale;
    this.cameras.main.fadeIn(1000, 0, 0, 0);
    Sfx.play('titleSting');
    this.add.particles(0, 0, 'fx_soft', {
      x: { min: 0, max: width }, y: height + 10, speedY: { min: -50, max: -20 },
      scale: { start: 0.12, end: 0 }, alpha: { start: 0.8, end: 0 }, lifespan: 7000, frequency: 140,
      tint: [0xffc36b, 0x9fb8ff], blendMode: 'ADD',
    });
    vignette(this, 5);
    this.add.text(width / 2, height * 0.38, 'To be continued…', {
      fontFamily: 'Cinzel', fontSize: '72px', fontStyle: '900', color: '#f3e3b0', stroke: '#2a1a08', strokeThickness: 8,
    }).setOrigin(0.5).setDepth(10);
    this.add.text(width / 2, height * 0.52, 'Next time: Metocin Mattias & the Diddy Chud Giant', {
      fontFamily: 'Nunito', fontSize: '26px', color: '#e8b923',
    }).setOrigin(0.5).setDepth(10);
    const hint = this.add.text(width / 2, height * 0.8, 'Press Space to return to the title', {
      fontFamily: 'Nunito', fontSize: '20px', color: '#a49cc4',
    }).setOrigin(0.5).setDepth(10);
    this.tweens.add({ targets: hint, alpha: 0.3, yoyo: true, repeat: -1, duration: 900 });
    const go = () => {
      Sfx.play('confirm');
      this.cameras.main.fade(600, 0, 0, 0, true);
      this.cameras.main.once('camerafadeoutcomplete', () => this.scene.start('Title'));
    };
    this.time.delayedCall(800, () => {
      this.input.keyboard.once('keydown-SPACE', go);
      this.input.keyboard.once('keydown-ENTER', go);
      this.input.once('pointerdown', go);
    });
  }
}
