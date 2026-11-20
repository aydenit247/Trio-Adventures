import Sfx from '../audio/Sfx.js';

// Base for full-screen menus that open on top of whatever is running (Settings, Outcomes).
// Pauses every active scene and resumes them on close.
export default class OverlayScene extends Phaser.Scene {
  openOverlay(title) {
    const { width, height } = this.scale;
    this.paused = this.game.scene.getScenes(true).filter((s) => s !== this && s.scene.key !== this.scene.key);
    this.paused.forEach((s) => s.scene.pause());
    this.scene.bringToTop();
    this.add.rectangle(0, 0, width, height, 0x07060c, 0.94).setOrigin(0).setInteractive();
    const g = this.add.graphics();
    g.lineStyle(2, 0xe8b923, 0.8).strokeRoundedRect(60, 40, width - 120, height - 80, 14);
    this.add.text(width / 2, 84, title, { fontFamily: 'Cinzel', fontSize: '44px', fontStyle: '900', color: '#f3e3b0', stroke: '#2a1a08', strokeThickness: 6 }).setOrigin(0.5);
    this.add.text(width / 2, height - 62, 'ESC / Backspace: close', { fontFamily: 'Nunito', fontSize: '16px', color: '#a49cc4' }).setOrigin(0.5);
    const kb = this.input.keyboard;
    ['ESC', 'BACKSPACE'].forEach((k) => kb.on(`keydown-${k}`, () => this.close()));
    this.closing = false;
  }

  close() {
    if (this.closing) return;
    this.closing = true;
    Sfx.play('click');
    // Wait a beat so the closing keypress doesn't land in the scene underneath
    setTimeout(() => {
      this.paused.forEach((s) => { if (s.scene.isPaused()) s.scene.resume(); });
      this.scene.stop();
    }, 120);
  }
}
