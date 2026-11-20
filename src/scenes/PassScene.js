import StageScene, { at } from './StageScene.js';
import { SCENE4 } from '../data/scenes/scene4_the_pass.js';
import Sfx from '../audio/Sfx.js';

// Scene 4 — The Mountain Pass. Foundation: art, staging and beats are in place; dialogue TBD.
export default class PassScene extends StageScene {
  constructor() { super('Pass'); }

  create() {
    this.nextScene = 'Continue';
    this.setupStage({ light: 'lava' });
    Sfx.startLoop('fire');

    this.bg = this.placeBg('bg_mountain_path');
    this.ash();

    const xylo = this.makeChar('xylo', -150, 572, { h: 320 });
    const lykor = this.makeChar('lykor', -150, 566, { h: 320 });
    const skorn = this.makeChar('skorn', -150, 590, { h: 345 });
    this.mattias = this.makeChar('mattias', 1010, 560, { h: 340 });
    this.mattias.setVisible(false);
    this.giant = this.makeChar('giant', 900, 640, { tex: 'char_giant_angry', h: 560 });
    this.giant.setVisible(false);

    this.finishStage();
    this.dialogue.play(SCENE4, this.baseHooks({
      enterParty: () => Promise.all([this.walk(xylo, 330), this.walk(lykor, 520), this.walk(skorn, 720)])
        .then(() => [xylo, lykor, skorn].forEach((c) => c.img.setFlipX(false))),
      mattiasAppears: async () => {
        Sfx.play('sparkle'); Sfx.play('boom');
        this.cameras.main.flash(300, 170, 120, 255);
        this.burst(this.mattias.x, this.mattias.y - 170, [0xb06bff, 0x7fb2ff]);
        // His green-screen video, scaled so he finishes exactly where his cutout stands
        await this.playCutscene('vid_mattias_appear', { keyed: true, keepChars: true, x: 999, y: 392, scale: 0.54 });
        this.mattias.setAlpha(1).setVisible(true);
        await this.showLabel(this.charLabel(this.mattias, 'Metocin Mattias (Uninvited)'));
      },
      mattiasVanish: async () => {
        Sfx.play('sparkle');
        this.burst(this.mattias.x, this.mattias.y - 170, [0xb06bff, 0x7fb2ff]);
        this.cameras.main.flash(250, 170, 120, 255);
        this.mattias.setVisible(false);
        await this.wait(400);
      },
      toGiant: () => this.toGiant(),
      giantWakes: () => this.giantWakes(),
      fightGiant: () => this.fightPlaceholder('BOSS: Diddy Chud Giant'),
    })).then(() => this.finish(this.nextScene));
  }

  // Falling ash and rising embers
  ash() {
    const { width } = this.scale;
    this.add.particles(0, -10, 'fx_soft', {
      x: { min: 0, max: width }, speedY: { min: 20, max: 60 }, speedX: { min: -20, max: 10 },
      scale: { start: 0.08, end: 0.04 }, alpha: { start: 0.7, end: 0 }, lifespan: 9000, frequency: 70, tint: 0x3a3030,
    }).setDepth(25);
    this.add.particles(0, 720, 'fx_soft', {
      x: { min: 0, max: width }, speedY: { min: -70, max: -30 }, speedX: { min: -15, max: 15 },
      scale: { start: 0.1, end: 0 }, alpha: { start: 0.9, end: 0 }, lifespan: 6000, frequency: 120,
      tint: [0xff7a2a, 0xffb347], blendMode: 'ADD',
    }).setDepth(25);
  }

  burst(x, y, tint) {
    const p = this.add.particles(x, y, 'fx_soft', {
      speed: { min: 80, max: 260 }, scale: { start: 0.5, end: 0 }, lifespan: 700, quantity: 40,
      tint, blendMode: 'ADD', emitting: false,
    }).setDepth(40);
    p.explode(40);
    this.time.delayedCall(900, () => p.destroy());
  }

  async toGiant() {
    const cam = this.cameras.main;
    cam.fade(400, 0, 0, 0, true);
    await this.wait(420);
    this.bg.destroy();
    this.bg = this.placeBg('bg_giant_pass');
    const party = [this.chars.xylo, this.chars.lykor, this.chars.skorn];
    [140, 300, 470].forEach((x, i) => party[i].setPosition(x, [585, 578, 600][i]));
    const chest = at(470, 230);
    this.giantLabel = this.label(chest.x, chest.y, 'Diddy Chud Giant (Asleep, Do Not Disturb)').setAlpha(0);
    this.zzz = this.add.text(at(790, 150).x, at(790, 150).y, 'Z z z', {
      fontFamily: 'Cinzel', fontSize: '34px', fontStyle: '900', color: '#f3e3b0', stroke: '#000', strokeThickness: 5,
    }).setDepth(30);
    this.tweens.add({ targets: this.zzz, y: this.zzz.y - 30, alpha: 0.2, yoyo: true, repeat: -1, duration: 1400 });
    cam.fadeIn(500, 0, 0, 0);
    await this.wait(500);
    await this.showLabel(this.giantLabel);
  }

  async giantWakes() {
    this.zzz.destroy();
    this.giantLabel.setVisible(false);
    // Cutscene: a purple vial lands on him, smoke, he wakes up and stands up roaring
    await this.playCutscene('vid_giant_wake');
    this.bg.destroy();
    this.bg = this.placeBg('bg_mountain_path'); // he's standing now — the path behind him is empty
    this.cameras.main.fadeIn(300, 0, 0, 0);
    Sfx.play('boom');
    this.cameras.main.shake(500, 0.014);
    await this.showChar(this.giant, 150);
    this.cameras.main.shake(400, 0.012);
    await this.showLabel(this.charLabel(this.giant, 'Diddy Chud Giant (Awake, Disturbed)'));
  }
}
