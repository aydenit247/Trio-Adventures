import BootScene from './scenes/BootScene.js';
import IntroScene from './scenes/IntroScene.js';
import TitleScene from './scenes/TitleScene.js';
import GoblinScene from './scenes/GoblinScene.js';
import MartScene from './scenes/MartScene.js';
import ContinueScene from './scenes/ContinueScene.js';

export const GAME_W = 1280;
export const GAME_H = 720;

const config = {
  type: Phaser.AUTO,
  parent: 'game',
  width: GAME_W,
  height: GAME_H,
  backgroundColor: '#07060c',
  scale: {
    mode: Phaser.Scale.FIT,
    autoCenter: Phaser.Scale.CENTER_BOTH,
  },
  scene: [BootScene, IntroScene, TitleScene, GoblinScene, MartScene, ContinueScene],
};

// Wait for web fonts so canvas text doesn't render in a fallback font.
const start = () => { window.game = new Phaser.Game(config); };
if (document.fonts && document.fonts.load) {
  Promise.all([
    document.fonts.load('900 64px Cinzel'),
    document.fonts.load('400 24px Nunito'),
    document.fonts.load('900 24px Nunito'),
  ]).then(start, start);
} else {
  start();
}
