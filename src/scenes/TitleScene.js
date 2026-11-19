import { coverImage, vignette } from '../fx.js';

// Title card — shown right after the intro: "Trio Adventures" by Ebain.
export default class TitleScene extends Phaser.Scene {
  constructor() { super('Title'); }

  create() {
    const { width, height } = this.scale;
    this.cameras.main.fadeIn(1200, 0, 0, 0);

    // Backdrop: the trio, slowly drifting, darkened toward the bottom for the menu
    if (this.textures.exists('bg_title')) {
      const img = coverImage(this, 'bg_title').setY(height / 2 + 40);
      this.tweens.add({ targets: img, scale: img.scale * 1.04, y: img.y + 10, duration: 18000, yoyo: true, repeat: -1, ease: 'Sine.inOut' });
    } else {
      this.add.graphics().fillGradientStyle(0x150f2b, 0x150f2b, 0x3a1830, 0x3a1830, 1).fillRect(0, 0, width, height);
    }
    const shade = this.add.graphics();
    shade.fillGradientStyle(0x07060c, 0x07060c, 0x07060c, 0x07060c, 0, 0, 0.97, 0.97).fillRect(0, height * 0.35, width, height * 0.65);
    vignette(this, 5);
    this.add.particles(0, 0, 'fx_soft', {
      x: { min: 0, max: width }, y: height + 10, speedY: { min: -60, max: -25 }, speedX: { min: -10, max: 10 },
      scale: { start: 0.12, end: 0 }, alpha: { start: 0.8, end: 0 }, lifespan: 7000, frequency: 160,
      tint: [0xffc36b, 0x9fb8ff], blendMode: 'ADD',
    }).setDepth(6);

    const title = this.add.text(width / 2, height * 0.64, 'Trio Adventures', {
      fontFamily: 'Cinzel', fontSize: '96px', fontStyle: '900', color: '#f3e3b0',
      stroke: '#2a1a08', strokeThickness: 10,
      shadow: { offsetX: 0, offsetY: 6, color: '#000', blur: 14, fill: true },
    }).setOrigin(0.5).setScale(0.6).setAlpha(0).setDepth(10);
    const by = this.add.text(width / 2, height * 0.64 + 76, 'by Ebain', {
      fontFamily: 'Cinzel', fontSize: '30px', color: '#e8b923',
    }).setOrigin(0.5).setAlpha(0).setDepth(10);

    this.tweens.add({ targets: title, scale: 1, alpha: 1, duration: 1100, ease: 'Back.out', delay: 300 });
    this.tweens.add({ targets: by, alpha: 1, duration: 800, delay: 1200 });

    // Menu
    this.items = [
      { text: 'New Game', fn: () => this.toast('Chapter 1: Goblin Village — coming soon\n(on some construction shi)') },
      { text: 'Replay Intro', fn: () => this.scene.start('Intro') },
    ];
    this.sel = 0;
    this.menuTexts = this.items.map((it, i) => {
      const t = this.add.text(width / 2 - 140 + i * 280, height * 0.88, it.text, {
        fontFamily: 'Nunito', fontSize: '28px', fontStyle: '900', color: '#f4efff',
      }).setOrigin(0.5).setAlpha(0).setDepth(10).setInteractive({ useHandCursor: true });
      t.on('pointerover', () => { this.sel = i; this.renderMenu(); });
      t.on('pointerdown', () => this.items[i].fn());
      this.tweens.add({ targets: t, alpha: 1, duration: 500, delay: 1800 + i * 120 });
      return t;
    });
    this.renderMenu();

    const kb = this.input.keyboard;
    ['UP', 'W', 'LEFT', 'A'].forEach((k) => kb.on(`keydown-${k}`, () => this.move(-1)));
    ['DOWN', 'S', 'RIGHT', 'D'].forEach((k) => kb.on(`keydown-${k}`, () => this.move(1)));
    kb.on('keydown-ENTER', () => this.items[this.sel].fn());
    kb.on('keydown-SPACE', () => this.items[this.sel].fn());

    this.add.text(width - 16, height - 14, 'v0.2 — foundation build', {
      fontFamily: 'Nunito', fontSize: '14px', color: '#6e6690',
    }).setOrigin(1, 1).setDepth(10);
  }

  move(d) { this.sel = (this.sel + d + this.items.length) % this.items.length; this.renderMenu(); }

  renderMenu() {
    this.menuTexts.forEach((t, i) => {
      const on = i === this.sel;
      t.setText(on ? `▶  ${this.items[i].text}  ◀` : this.items[i].text).setColor(on ? '#e8b923' : '#f4efff');
    });
  }

  toast(msg) {
    if (this.toastText) this.toastText.destroy();
    const { width, height } = this.scale;
    this.toastText = this.add.text(width / 2, 50, msg, {
      fontFamily: 'Nunito', fontSize: '22px', color: '#ffdf8a', align: 'center',
      backgroundColor: '#1a1324', padding: { x: 16, y: 10 },
    }).setOrigin(0.5).setDepth(20);
    this.time.delayedCall(2600, () => this.toastText && this.toastText.destroy());
  }
}
