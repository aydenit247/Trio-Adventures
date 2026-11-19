import DialogueBox from '../ui/DialogueBox.js';
import { SCENE1 } from '../data/scenes/scene1_the_map.js';
import { vignette } from '../fx.js';
import Sfx from '../audio/Sfx.js';

// Scene 1 — "The Map". Painted camp backdrop, full-body characters, and the
// map-burning cutscene video. Press ESC to skip to the title card.

// The camp art is 1024x572. It's shown 10% larger than "cover" so the fire sits
// above the dialogue box; `at()` converts art coordinates to screen coordinates.
const BG = { scale: 1.375, left: -64, top: -100 };
const at = (x, y) => ({ x: x * BG.scale + BG.left, y: y * BG.scale + BG.top });
const FIRE = at(525, 405);
const SACK = at(185, 420);

export default class IntroScene extends Phaser.Scene {
  constructor() { super('Intro'); }

  create() {
    const { width, height } = this.scale;
    this.cameras.main.setBackgroundColor('#05040a').fadeIn(1400, 0, 0, 0);
    this.lit = false;
    this.day = false;
    this.speaker = null;
    this.finished = false;

    Sfx.startLoop('night');
    this.events.once('shutdown', () => { Sfx.stopLoop('night'); Sfx.stopLoop('fire'); });

    // ---------- Backdrop ----------
    this.bgUnlit = this.placeBg('bg_camp_unlit');
    this.bgLit = this.placeBg('bg_camp_lit').setAlpha(0);

    // Moonlit fog drifting through the camp
    this.fog = [];
    for (let i = 0; i < 6; i++) {
      const f = this.add.image(Phaser.Math.Between(-100, width), Phaser.Math.Between(330, 480), 'fx_soft')
        .setScale(Phaser.Math.Between(12, 20), Phaser.Math.FloatBetween(1.2, 2.2))
        .setAlpha(0.08).setTint(0xb8c4ff).setDepth(2);
      this.tweens.add({ targets: f, x: f.x + Phaser.Math.Between(120, 260), yoyo: true, repeat: -1,
        duration: Phaser.Math.Between(10000, 18000), ease: 'Sine.inOut' });
      this.fog.push(f);
    }

    // ---------- Fire effects (on top of the lit painting) ----------
    this.groundGlow = this.add.image(FIRE.x, FIRE.y + 20, 'fx_glow').setScale(3.4, 0.9)
      .setBlendMode(Phaser.BlendModes.ADD).setAlpha(0).setDepth(3);
    this.fireGlow = this.add.image(FIRE.x, FIRE.y - 40, 'fx_glow').setScale(2.2)
      .setBlendMode(Phaser.BlendModes.ADD).setAlpha(0).setDepth(3);
    this.flames = this.add.particles(FIRE.x, FIRE.y - 8, 'fx_soft', {
      x: { min: -30, max: 30 }, speedY: { min: -160, max: -80 }, speedX: { min: -15, max: 15 },
      scale: { start: 0.6, end: 0.05 }, alpha: { start: 0.3, end: 0 },
      lifespan: { min: 400, max: 800 }, frequency: 30,
      tint: [0xffe27a, 0xffb02e, 0xff6a1f], blendMode: 'ADD', emitting: false,
    }).setDepth(3);
    this.embers = this.add.particles(FIRE.x, FIRE.y - 40, 'fx_soft', {
      x: { min: -30, max: 30 }, speedY: { min: -240, max: -110 }, speedX: { min: -60, max: 60 },
      scale: { start: 0.12, end: 0 }, lifespan: { min: 1200, max: 2400 }, frequency: 90,
      tint: [0xffd27a, 0xff8a2a], blendMode: 'ADD', emitting: false,
    }).setDepth(4);
    this.smoke = this.add.particles(FIRE.x, FIRE.y - 90, 'fx_soft', {
      x: { min: -15, max: 15 }, speedY: { min: -50, max: -25 }, speedX: { min: -8, max: 20 },
      scale: { start: 0.8, end: 3 }, alpha: { start: 0.1, end: 0 }, lifespan: 4000, frequency: 300,
      tint: 0x9a9aaa, emitting: false,
    }).setDepth(3);

    // ---------- Characters ----------
    this.chars = {
      lykor: this.makeChar('lykor', 455, 538, 330),
      xylo: this.makeChar('xylo', 975, 538, 330),
      skorn: this.makeChar('skorn', 1125, 562, 355),
    };

    // ---------- Labels ----------
    this.bagLabel = this.label(SACK.x, SACK.y - 58, 'DO NOT TOUCH (Skorn)').setAlpha(0);
    this.fireLabel = this.label(FIRE.x, FIRE.y - 150, 'Fire (needs food)').setAlpha(0);

    // ---------- Atmosphere ----------
    this.dawn = this.add.rectangle(0, 0, width, height, 0xffa070, 0).setOrigin(0)
      .setBlendMode(Phaser.BlendModes.ADD).setDepth(850);
    vignette(this);
    this.cameras.main.zoomTo(1.02, 40000, 'Sine.easeInOut');

    this.skipHint = this.add.text(width - 16, 12, 'ESC: skip', { fontFamily: 'Nunito', fontSize: '16px', color: '#a49cc4' })
      .setOrigin(1, 0).setDepth(950);
    this.input.keyboard.once('keydown-ESC', () => this.finish());

    this.dialogue = new DialogueBox(this);
    this.dialogue.play(SCENE1, {
      onLine: (s) => this.setSpeaker(!s.who || s.who === 'narrator' ? null : s.who),
      showBagLabel: () => this.showLabel(this.bagLabel),
      showFireLabel: () => this.showLabel(this.fireLabel),
      skornGrabsMap: () => this.skornGrabsMap(),
      burnMap: () => this.burnMap(),
      freakout: () => {
        Sfx.play('dramatic'); Sfx.play('boom');
        this.cameras.main.shake(450, 0.012);
        Object.values(this.chars).forEach((c) => this.hop(c, 18));
        return this.wait(400);
      },
      morning: () => this.morning(),
    }).then(() => this.finish());
  }

  // ---------------- Building blocks ----------------
  placeBg(key) {
    const img = this.add.image(BG.left, BG.top, key).setOrigin(0);
    return img.setScale(BG.scale * (1024 / img.width));
  }

  makeChar(id, x, feetY, h) {
    const c = this.add.container(x, feetY).setDepth(10 + feetY / 100);
    const shadow = this.add.ellipse(0, 0, h * 0.42, h * 0.07, 0x000000, 0.5);
    const img = this.add.image(0, 0, `char_${id}`).setOrigin(0.5, 1);
    const s = h / img.height;
    img.setScale(s);
    c.add([shadow, img]);
    c.img = img; c.baseScale = s; c.id = id;
    // Idle breathing
    this.tweens.add({ targets: img, scaleY: s * 1.012, scaleX: s * 0.996, yoyo: true, repeat: -1,
      duration: 1600 + Math.random() * 600, ease: 'Sine.inOut', delay: Math.random() * 800 });
    return c;
  }

  label(x, y, text) {
    return this.add.text(x, y, text, {
      fontFamily: 'Nunito', fontSize: '18px', fontStyle: '900', color: '#1a1324',
      backgroundColor: '#f3e3b0', padding: { x: 8, y: 2 },
    }).setOrigin(0.5).setDepth(30);
  }

  showLabel(lbl) {
    Sfx.play('pop');
    lbl.setScale(0.6);
    return this.tweenP({ targets: lbl, alpha: 1, scale: 1, duration: 260, ease: 'Back.out' });
  }

  setSpeaker(id) {
    if (id === this.speaker) return;
    this.speaker = id;
    if (id && this.chars[id]) this.hop(this.chars[id], 8);
  }

  hop(c, px) {
    this.tweens.add({ targets: c.img, y: -px, duration: 110, yoyo: true, ease: 'Quad.out' });
  }

  tweenP(cfg) { return new Promise((res) => this.tweens.add({ ...cfg, onComplete: res })); }
  wait(ms) { return new Promise((res) => this.time.delayedCall(ms, res)); }

  // Walks a character to x with a bobbing step and footstep sounds.
  walk(c, toX, msPerPx = 2.2) {
    const dist = Math.abs(toX - c.x);
    c.img.setFlipX(toX < c.x);
    const steps = this.tweens.add({ targets: c.img, y: -7, duration: 170, yoyo: true, repeat: -1, ease: 'Sine.inOut',
      onYoyo: () => Sfx.play('step') });
    return this.tweenP({ targets: c, x: toX, duration: dist * msPerPx, ease: 'Linear',
      onUpdate: () => { if (this.paper && this.paper.follow === c) this.syncPaper(); } })
      .then(() => { steps.stop(); c.img.y = 0; });
  }

  syncPaper() {
    const c = this.paper.follow;
    this.paper.setPosition(c.x + (c.img.flipX ? -60 : 60), c.y - 175);
  }

  // Character lighting: dim whoever isn't talking, warm firelight once the fire is lit.
  update(time) {
    const flick = this.lit ? 0.85 + 0.15 * Math.sin(time * 0.023) * Math.sin(time * 0.0137) : 0;
    Object.values(this.chars).forEach((c) => {
      const b = !this.speaker || this.speaker === c.id ? 1 : 0.62;
      const [r, g, bl] = this.day ? [255, 238, 222] : this.lit ? [255, 205 + 25 * flick, 165 + 20 * flick] : [205, 212, 255];
      c.img.setTint(Phaser.Display.Color.GetColor(r * b, g * b, bl * b));
    });
    if (this.lit) this.fireGlow.setAlpha(0.24 + 0.12 * flick);
  }

  // ---------------- Story beats ----------------
  async skornGrabsMap() {
    const skorn = this.chars.skorn;
    this.speaker = 'skorn';
    await this.walk(skorn, SACK.x + 95);
    Sfx.play('grab');
    this.paper = this.add.rectangle(0, 0, 34, 24, 0xf1e6c8).setStrokeStyle(2, 0x8a7a55).setDepth(40);
    this.paper.follow = skorn; this.syncPaper();
    const tag = this.label(this.paper.x, this.paper.y - 34, 'map (very important)').setFontSize(14);
    this.tweens.add({ targets: tag, alpha: 0, y: tag.y - 20, delay: 900, duration: 400, onComplete: () => tag.destroy() });
    this.hop(skorn, 10);
    await this.wait(500);
  }

  async burnMap() {
    const skorn = this.chars.skorn;
    await this.walk(skorn, FIRE.x + 190);
    skorn.img.setFlipX(true);
    Sfx.play('whoosh');
    this.paper.follow = null;
    await this.tweenP({ targets: this.paper, x: FIRE.x, y: FIRE.y - 20, angle: 540, duration: 520, ease: 'Quad.in' });
    this.paper.destroy(); this.paper = null;
    this.cameras.main.flash(250, 255, 200, 140);
    await this.playCutscene('vid_map_burn');

    // Back to the camp — the fire is going now
    this.bgUnlit.setVisible(false);
    this.bgLit.setAlpha(1);
    this.lit = true;
    skorn.x = 1125; // back to his spot while the cutscene had the screen
    skorn.img.setFlipX(false);
    this.fireLabel.setText('Fire (fed)');
    this.flames.start(); this.embers.start(); this.smoke.start();
    this.groundGlow.setAlpha(0.35);
    this.fog.forEach((f) => f.setTint(0xffc89a).setAlpha(0.05));
    Sfx.startLoop('fire');
    this.cameras.main.fadeIn(500, 0, 0, 0);
    await this.wait(500);
  }

  // Plays a full-screen video; Space/Enter/click skips. Hides the scene while it runs.
  playCutscene(key) {
    return new Promise((resolve) => {
      const { width, height } = this.scale;
      const hidden = [...Object.values(this.chars), this.bagLabel, this.fireLabel, this.skipHint];
      hidden.forEach((o) => o.setVisible(false));

      let done = false;
      const vid = this.add.video(width / 2, height / 2, key).setDepth(800);
      const skipTxt = this.add.text(width - 16, height - 14, 'Space: skip', {
        fontFamily: 'Nunito', fontSize: '16px', color: '#ffffffaa',
      }).setOrigin(1, 1).setDepth(960);
      const finish = () => {
        if (done) return; done = true;
        this.input.keyboard.off('keydown-SPACE', finish);
        this.input.keyboard.off('keydown-ENTER', finish);
        this.input.off('pointerdown', finish);
        this.cameras.main.fade(250, 0, 0, 0, true);
        this.time.delayedCall(260, () => {
          vid.stop(); vid.destroy(); skipTxt.destroy();
          hidden.forEach((o) => o.setVisible(true));
          resolve();
        });
      };

      vid.setMute(Sfx.muted);
      vid.on('created', () => vid.setDisplaySize(width, height));
      vid.on('complete', finish);
      vid.on('error', finish);
      vid.play(false);
      // If the video can't start (blocked or failed), don't leave the player stuck
      this.time.delayedCall(3000, () => { if (!done && !vid.isPlaying()) finish(); });
      this.time.delayedCall(400, () => {
        if (done) return;
        this.input.keyboard.on('keydown-SPACE', finish);
        this.input.keyboard.on('keydown-ENTER', finish);
        this.input.on('pointerdown', finish);
      });
    });
  }

  async morning() {
    this.tweens.add({ targets: this.groundGlow, alpha: 0.15, duration: 1600 });
    this.embers.stop();
    this.lit = false;
    this.day = true;
    Sfx.stopLoop('night'); Sfx.stopLoop('fire');
    Sfx.play('birds');
    this.fireGlow.setAlpha(0.15);
    await this.tweenP({ targets: this.dawn, alpha: 0.3, duration: 1600 });
  }

  finish() {
    if (this.finished) return;
    this.finished = true;
    this.cameras.main.fade(900, 0, 0, 0, true);
    this.cameras.main.once('camerafadeoutcomplete', () => this.scene.start('Title'));
  }
}
