// Title card — shown right after the intro: "Trio Adventures" by Ebain.
export default class TitleScene extends Phaser.Scene {
  constructor() { super('Title'); }

  create() {
    const { width, height } = this.scale;
    this.cameras.main.fadeIn(1200, 0, 0, 0);

    const bg = this.add.graphics();
    bg.fillGradientStyle(0x150f2b, 0x150f2b, 0x3a1830, 0x3a1830, 1).fillRect(0, 0, width, height);
    for (let i = 0; i < 40; i++) {
      const p = this.add.circle(Phaser.Math.Between(0, width), Phaser.Math.Between(0, height),
        Phaser.Math.Between(1, 3), 0x7fb2ff, 0.6);
      this.tweens.add({ targets: p, y: p.y - 80, alpha: 0, duration: Phaser.Math.Between(3000, 7000), repeat: -1 });
    }

    const title = this.add.text(width / 2, height * 0.36, 'Trio Adventures', {
      fontFamily: 'Cinzel', fontSize: '104px', fontStyle: '900', color: '#f3e3b0',
      stroke: '#2a1a08', strokeThickness: 10,
      shadow: { offsetX: 0, offsetY: 6, color: '#000', blur: 14, fill: true },
    }).setOrigin(0.5).setScale(0.6).setAlpha(0);
    const by = this.add.text(width / 2, height * 0.36 + 86, 'by Ebain', {
      fontFamily: 'Cinzel', fontSize: '34px', color: '#e8b923',
    }).setOrigin(0.5).setAlpha(0);

    this.tweens.add({ targets: title, scale: 1, alpha: 1, duration: 1100, ease: 'Back.out', delay: 300 });
    this.tweens.add({ targets: by, alpha: 1, duration: 800, delay: 1200 });

    // Menu
    this.items = [
      { text: 'New Game', fn: () => this.toast('Chapter 1: Goblin Village — coming soon\n(on some construction shi)') },
      { text: 'Replay Intro', fn: () => this.scene.start('Intro') },
    ];
    this.sel = 0;
    this.menuTexts = this.items.map((it, i) => {
      const t = this.add.text(width / 2, height * 0.66 + i * 52, it.text, {
        fontFamily: 'Nunito', fontSize: '32px', fontStyle: '900', color: '#f4efff',
      }).setOrigin(0.5).setAlpha(0).setInteractive({ useHandCursor: true });
      t.on('pointerover', () => { this.sel = i; this.renderMenu(); });
      t.on('pointerdown', () => this.items[i].fn());
      this.tweens.add({ targets: t, alpha: 1, duration: 500, delay: 1800 + i * 120 });
      return t;
    });
    this.renderMenu();

    const kb = this.input.keyboard;
    kb.on('keydown-UP', () => this.move(-1));
    kb.on('keydown-W', () => this.move(-1));
    kb.on('keydown-DOWN', () => this.move(1));
    kb.on('keydown-S', () => this.move(1));
    kb.on('keydown-ENTER', () => this.items[this.sel].fn());
    kb.on('keydown-SPACE', () => this.items[this.sel].fn());

    this.add.text(width / 2, height - 28, 'v0.1 — foundation build', {
      fontFamily: 'Nunito', fontSize: '16px', color: '#6e6690',
    }).setOrigin(0.5);
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
    this.toastText = this.add.text(width / 2, height * 0.88, msg, {
      fontFamily: 'Nunito', fontSize: '22px', color: '#ffdf8a', align: 'center',
      backgroundColor: '#1a1324', padding: { x: 16, y: 10 },
    }).setOrigin(0.5);
    this.time.delayedCall(2600, () => this.toastText && this.toastText.destroy());
  }
}
