import { CHARACTERS, PORTRAIT_FILES } from '../data/characters.js';

// Loads assets, shows the loading screen, and makes placeholder portraits
// for any image that hasn't been added to assets/portraits/ yet.
export default class BootScene extends Phaser.Scene {
  constructor() { super('Boot'); }

  preload() {
    const { width, height } = this.scale;

    this.add.text(width / 2, height / 2 - 40, 'Loading…', {
      fontFamily: 'Cinzel', fontSize: '42px', color: '#f3e3b0',
    }).setOrigin(0.5);
    this.add.text(width / 2, height / 2 + 6, '(on some loading shi)', {
      fontFamily: 'Nunito', fontSize: '20px', color: '#9a8fb8', fontStyle: 'italic',
    }).setOrigin(0.5);

    const barBg = this.add.rectangle(width / 2, height / 2 + 60, 420, 14, 0x1d1830).setOrigin(0.5);
    const bar = this.add.rectangle(barBg.x - 210, barBg.y, 0, 14, 0xe8b923).setOrigin(0, 0.5);
    this.load.on('progress', (p) => { bar.width = 420 * p; });

    // Missing files are expected while art is still coming in — don't treat them as errors.
    this.missing = new Set();
    this.load.on('loaderror', (file) => this.missing.add(file.key));

    PORTRAIT_FILES.forEach((f) => this.load.image(`portrait_${f}`, `assets/portraits/${f}.png`));
  }

  create() {
    // Base portrait placeholder for every character without a real image yet.
    Object.entries(CHARACTERS).forEach(([id, c]) => {
      const key = `portrait_${id}`;
      if (!this.textures.exists(key) || this.missing.has(key)) {
        if (this.textures.exists(key)) this.textures.remove(key);
        this.makePlaceholder(key, c.name || '?', c.color);
      }
    });
    this.time.delayedCall(250, () => this.scene.start('Intro'));
  }

  makePlaceholder(key, name, color) {
    const size = 256;
    const tex = this.textures.addDynamicTexture(key, size, size);
    const g = this.add.graphics();
    g.fillStyle(color, 1).fillRect(0, 0, size, size);
    g.fillStyle(0x000000, 0.35).fillRect(0, size * 0.62, size, size * 0.38);
    g.fillStyle(0xffffff, 0.12).fillCircle(size / 2, size * 0.42, size * 0.26);
    tex.draw(g, 0, 0);
    const letter = this.add.text(0, 0, (name[0] || '?').toUpperCase(), {
      fontFamily: 'Cinzel', fontSize: '120px', color: '#ffffff',
    }).setOrigin(0.5);
    tex.draw(letter, size / 2, size * 0.42);
    const label = this.add.text(0, 0, 'portrait\n(pending)', {
      fontFamily: 'Nunito', fontSize: '22px', color: '#ffffff', align: 'center',
    }).setOrigin(0.5);
    tex.draw(label, size / 2, size * 0.82);
    g.destroy(); letter.destroy(); label.destroy();
  }
}
