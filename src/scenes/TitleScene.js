import { coverImage, vignette } from '../fx.js';
import Sfx from '../audio/Sfx.js';
import Save, { SCENE_NAMES } from '../systems/save.js';
import Outcomes, { OUTCOMES } from '../systems/outcomes.js';

// Title card — shown right after the intro: "Trio Adventures" by Ebain.
export default class TitleScene extends Phaser.Scene {
  constructor() { super('Title'); }

  create() {
    this.leaving = false;
    this.menuReady = false;
    const { width, height } = this.scale;
    this.cameras.main.fadeIn(1200, 0, 0, 0);
    // Main menu music (loops; trims the silence at the start/end of the file)
    Sfx.playMusic('assets/audio/menu_theme.mp3', { volume: 0.55, loopStart: 0.8, loopEnd: 194.2, fadeIn: 3 });
    this.events.once('shutdown', () => Sfx.stopMusic(1.5));
    // If the browser blocked the music, tell the player how to turn it on
    const hint = this.add.text(width / 2, 22, '🔊 Click or press any key to turn on sound', {
      fontFamily: 'Nunito', fontSize: '18px', color: '#ffdf8a', backgroundColor: '#1a1324cc', padding: { x: 12, y: 6 },
    }).setOrigin(0.5, 0).setDepth(30).setVisible(false);
    this.time.addEvent({ delay: 500, loop: true, callback: () => hint.setVisible(!!Sfx.musicBlocked && !Sfx.muted) });

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
    this.menuTexts = [];
    this.subText = null;
    this.mainMenu();
    this.time.delayedCall(1800, () => { this.menuReady = true; this.renderMenu(); this.menuTexts.forEach((t, n) => this.tweens.add({ targets: t, alpha: 1, duration: 400, delay: n * 90 })); });

    const kb = this.input.keyboard;
    ['UP', 'W', 'LEFT', 'A'].forEach((k) => kb.on(`keydown-${k}`, () => this.move(-1)));
    ['DOWN', 'S', 'RIGHT', 'D'].forEach((k) => kb.on(`keydown-${k}`, () => this.move(1)));
    kb.on('keydown-ENTER', () => this.choose(this.sel));
    kb.on('keydown-SPACE', () => this.choose(this.sel));
    kb.on('keydown-ESC', () => { if (this.inSub) { Sfx.play('click'); this.mainMenu(); } });

    this.add.text(width - 16, height - 14, 'v0.3 — Chapter 1', {
      fontFamily: 'Nunito', fontSize: '14px', color: '#6e6690',
    }).setOrigin(1, 1).setDepth(10);
  }

  mainMenu() {
    this.inSub = false;
    this.confirmNew = false;
    const save = Save.read();
    const items = [];
    if (save) items.push({ text: 'Continue', sub: `Saved at: ${SCENE_NAMES[save.scene] || save.scene}`, fn: () => { const sc = Save.load(this.registry); this.go(sc === 'Continue' ? 'Continue' : sc); } });
    items.push({ text: save ? 'New Game' : 'Start Game', fn: () => this.newGame(!!save) });
    items.push({ text: 'Chapters', fn: () => this.chapterMenu() });
    items.push({ text: `Outcomes ${Outcomes.count()}/${OUTCOMES.length}`, fn: () => this.overlay('Outcomes') });
    items.push({ text: 'Settings', fn: () => this.overlay('Settings') });
    items.push({ text: 'Replay Intro', fn: () => this.go('Intro') });
    this.setMenu(items);
  }

  chapterMenu() {
    this.inSub = true;
    this.setMenu([
      { text: 'Goblin Village', fn: () => this.startChapter('Goblin') },
      { text: 'Metocy Mart', fn: () => this.startChapter('Mart') },
      { text: 'The Pass', fn: () => this.startChapter('Pass') },
      { text: 'Back', fn: () => this.mainMenu() },
    ]);
  }

  // Jump straight into a chapter with sensible default progress
  startChapter(key) {
    const r = this.registry;
    r.reset();
    r.set('level', key === 'Pass' ? 2 : 1);
    r.set('xp', key === 'Pass' ? 60 : 0);
    if (key !== 'Goblin') r.set('inv_beer', 3);
    if (key === 'Pass') r.set('hasMidtocy', true);
    Save.write(r, key);
    this.go(key);
  }

  newGame(hasSave) {
    if (hasSave && !this.confirmNew) {
      this.confirmNew = true;
      this.toast('Start over? This replaces your save.\nPress again to confirm.');
      return;
    }
    Save.newGame(this.registry);
    this.go('Goblin');
  }

  overlay(key) {
    this.scene.launch(key);
    this.events.once('resume', () => this.mainMenu());
  }

  setMenu(items) {
    const { width, height } = this.scale;
    this.menuTexts.forEach((t) => t.destroy());
    this.items = items;
    this.sel = 0;
    const style = { fontFamily: 'Nunito', fontSize: '24px', fontStyle: '900', color: '#f4efff' };
    this.menuTexts = items.map((it, i) => {
      const t = this.add.text(0, height * 0.88, it.text, style).setOrigin(0.5).setDepth(10).setAlpha(this.menuReady ? 1 : 0)
        .setInteractive({ useHandCursor: true });
      t.on('pointerover', () => { if (this.sel !== i) Sfx.play('tick'); this.sel = i; this.renderMenu(); });
      t.on('pointerdown', () => this.choose(i));
      return t;
    });
    // Lay out in one centered row, sized to the labels (room for the ▶ ◀ markers)
    const gap = items.length > 5 ? 40 : 56, widths = this.menuTexts.map((t) => t.width + 40);
    let x = width / 2 - (widths.reduce((a, b) => a + b, 0) + gap * (widths.length - 1)) / 2;
    this.menuTexts.forEach((t, i) => { t.setX(x + widths[i] / 2); x += widths[i] + gap; });
    this.renderMenu();
  }

  go(key) {
    if (this.leaving) return;
    this.leaving = true;
    this.cameras.main.fade(700, 0, 0, 0, true);
    this.cameras.main.once('camerafadeoutcomplete', () => this.scene.start(key));
  }

  move(d) { this.sel = (this.sel + d + this.items.length) % this.items.length; Sfx.play('tick'); this.renderMenu(); }

  choose(i) { if (!this.menuReady || this.leaving) return; Sfx.play('confirm'); this.items[i].fn(); }

  renderMenu() {
    if (!this.subText) {
      this.subText = this.add.text(this.scale.width / 2, this.scale.height * 0.88 + 34, '', { fontFamily: 'Nunito', fontSize: '16px', fontStyle: 'italic', color: '#a49cc4' }).setOrigin(0.5).setDepth(10);
    }
    const cur = this.items[this.sel];
    this.subText.setText(cur && cur.sub ? cur.sub : '').setX(this.menuTexts[this.sel] ? this.menuTexts[this.sel].x : this.scale.width / 2)
      .setAlpha(this.menuReady ? 1 : 0);
    this.menuTexts.forEach((t, i) => {
      const on = i === this.sel;
      t.setText(on ? `▶ ${this.items[i].text} ◀` : this.items[i].text).setColor(on ? '#e8b923' : '#f4efff');
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
