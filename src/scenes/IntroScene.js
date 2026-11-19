import DialogueBox from '../ui/DialogueBox.js';
import { SCENE1 } from '../data/scenes/scene1_the_map.js';
import { coverImage, vignette } from '../fx.js';

// Scene 1 — "The Map". A staged cutscene for now; free-roam camp comes once
// the overworld exists. Press ESC to skip to the title card.
//
// If assets/backgrounds/camp_night.jpg exists it's used as the backdrop;
// otherwise the scene draws its own night forest.
export default class IntroScene extends Phaser.Scene {
  constructor() { super('Intro'); }

  create() {
    const { width, height } = this.scale;
    this.cameras.main.fadeIn(1200, 0, 0, 0);

    if (this.textures.exists('bg_camp_night')) {
      coverImage(this, 'bg_camp_night');
    } else {
      this.drawNightForest();
    }

    // ---------- Campfire ----------
    const fx = width / 2, fy = 380;
    this.fireX = fx; this.fireY = fy;
    this.groundGlow = this.add.image(fx, fy + 10, 'fx_glow').setScale(2.6, 0.7)
      .setBlendMode(Phaser.BlendModes.ADD).setAlpha(0);
    const pit = this.add.graphics();
    for (let i = 0; i < 12; i++) { // stone ring
      const a = (i / 12) * Math.PI * 2;
      pit.fillStyle(i % 2 ? 0x4a4550 : 0x3a3640).fillEllipse(fx + Math.cos(a) * 62, fy + 12 + Math.sin(a) * 16, 26, 16);
    }
    pit.fillStyle(0x4a2e1a);
    pit.fillRect(fx - 50, fy - 2, 100, 12); // logs
    pit.fillStyle(0x5b3a22);
    pit.fillTriangle(fx - 40, fy + 10, fx + 8, fy - 26, fx + 18, fy - 20);
    pit.fillTriangle(fx + 40, fy + 10, fx - 8, fy - 26, fx - 18, fy - 20);

    this.flames = this.add.particles(fx, fy - 6, 'fx_soft', {
      x: { min: -22, max: 22 }, speedY: { min: -150, max: -70 }, speedX: { min: -18, max: 18 },
      scale: { start: 0.8, end: 0.05 }, alpha: { start: 0.75, end: 0 },
      lifespan: { min: 450, max: 850 }, frequency: 22, quantity: 1,
      tint: [0xffe27a, 0xffb02e, 0xff6a1f, 0xff3d12], blendMode: 'ADD', emitting: false,
    });
    this.embers = this.add.particles(fx, fy - 20, 'fx_soft', {
      x: { min: -20, max: 20 }, speedY: { min: -220, max: -110 }, speedX: { min: -50, max: 50 },
      scale: { start: 0.14, end: 0 }, lifespan: { min: 900, max: 1800 }, frequency: 110,
      tint: [0xffd27a, 0xff8a2a], blendMode: 'ADD', emitting: false,
    });
    this.smoke = this.add.particles(fx, fy - 40, 'fx_soft', {
      x: { min: -10, max: 10 }, speedY: { min: -60, max: -30 }, speedX: { min: -12, max: 22 },
      scale: { start: 0.6, end: 2.4 }, alpha: { start: 0.16, end: 0 }, lifespan: 3200, frequency: 260,
      tint: 0x8a8a9a,
    });
    this.fireGlow = this.add.image(fx, fy - 30, 'fx_glow').setScale(1.6)
      .setBlendMode(Phaser.BlendModes.ADD).setAlpha(0);

    // ---------- Characters (portrait standees until full-body art exists) ----------
    this.chars = {
      lykor: this.standee('lykor', 430, 440),
      xylo: this.standee('xylo', 1010, 440),
      skorn: this.standee('skorn', 820, 462),
    };
    this.skorn = this.chars.skorn;

    // ---------- Lykor's bag ----------
    const bag = this.add.graphics();
    bag.fillStyle(0x000000, 0.35).fillEllipse(240, 452, 84, 18);
    bag.fillStyle(0x6e4f2e).fillEllipse(240, 430, 72, 56);
    bag.fillStyle(0x5a3f24).fillRect(222, 400, 36, 10);
    bag.lineStyle(2, 0x3d2b18).strokeEllipse(240, 430, 72, 56);
    this.bag = { x: 240, y: 430 };
    this.bagLabel = this.label(240, 388, 'DO NOT TOUCH (Skorn)').setAlpha(0);
    this.fireLabel = this.label(fx, fy - 140, 'Fire (needs food)').setAlpha(0);

    // ---------- Atmosphere ----------
    this.dawn = this.add.rectangle(0, 0, width, height, 0xffa070, 0).setOrigin(0)
      .setBlendMode(Phaser.BlendModes.ADD).setDepth(850);
    vignette(this);
    this.cameras.main.zoomTo(1.02, 40000, 'Sine.easeInOut');

    this.add.text(width - 16, 12, 'ESC: skip', { fontFamily: 'Nunito', fontSize: '16px', color: '#8a82aa' })
      .setOrigin(1, 0).setDepth(950).setScrollFactor(0);
    this.input.keyboard.once('keydown-ESC', () => this.finish());

    this.dialogue = new DialogueBox(this);
    this.dialogue.play(SCENE1, {
      showBagLabel: () => this.tweenP({ targets: this.bagLabel, alpha: 1, duration: 300 }),
      showFireLabel: () => this.tweenP({ targets: this.fireLabel, alpha: 1, duration: 300 }),
      skornGrabsMap: () => this.skornGrabsMap(),
      burnMap: () => this.burnMap(),
      freakout: () => { this.cameras.main.shake(450, 0.012); return this.wait(350); },
      morning: () => this.morning(),
    }).then(() => this.finish());
  }

  // ---------------- Drawn night forest (fallback backdrop) ----------------
  drawNightForest() {
    const { width, height } = this.scale;
    const horizon = height * 0.5;

    const statics = []; // drawn once into a texture so they don't redraw every frame
    const sky = this.add.graphics();
    sky.fillGradientStyle(0x070616, 0x070616, 0x241d4a, 0x2b1f45, 1).fillRect(0, 0, width, horizon + 40);
    this.bake('bake_sky', [sky]).setDepth(-20);

    for (let i = 0; i < 140; i++) {
      const s = this.add.circle(Phaser.Math.Between(0, width), Phaser.Math.Between(0, horizon - 60),
        Phaser.Math.FloatBetween(0.5, 1.7), 0xffffff, Phaser.Math.FloatBetween(0.25, 0.95)).setDepth(-15);
      this.tweens.add({ targets: s, alpha: 0.1, yoyo: true, repeat: -1, duration: Phaser.Math.Between(900, 3000), delay: Phaser.Math.Between(0, 2000) });
    }

    // Moon
    this.add.image(1060, 110, 'fx_moonglow').setScale(1.4).setBlendMode(Phaser.BlendModes.ADD).setDepth(-15);
    this.add.circle(1060, 110, 30, 0xe9ecff).setDepth(-15);
    this.add.circle(1050, 104, 6, 0xcfd4ef, 0.6).setDepth(-15);
    this.add.circle(1070, 120, 4, 0xcfd4ef, 0.5).setDepth(-15);

    // Mountain layers
    const rnd = new Phaser.Math.RandomDataGenerator(['caelid']);
    const ridge = (color, baseY, amp, step) => {
      const g = this.add.graphics().fillStyle(color, 1); statics.push(g);
      const pts = [{ x: 0, y: height }];
      for (let x = 0; x <= width + step; x += step) pts.push({ x, y: baseY - rnd.between(0, amp) });
      pts.push({ x: width, y: height });
      g.fillPoints(pts, true);
    };
    ridge(0x1c1838, horizon - 30, 120, 90);
    ridge(0x141130, horizon - 5, 70, 60);

    // Pine tree lines
    const pine = (g, x, baseY, h, color) => {
      g.fillStyle(color, 1);
      g.fillRect(x - h * 0.03, baseY - h * 0.15, h * 0.06, h * 0.15);
      for (let i = 0; i < 4; i++) {
        const w = h * (0.42 - i * 0.08), y = baseY - h * 0.12 - i * h * 0.2;
        g.fillTriangle(x - w, y, x + w, y, x, y - h * 0.38);
      }
    };
    const back = this.add.graphics(); statics.push(back);
    for (let x = -20; x < width + 40; x += rnd.between(28, 46)) pine(back, x, horizon + 12, rnd.between(70, 120), 0x0f1424);
    const ground = this.add.graphics(); statics.push(ground);
    ground.fillGradientStyle(0x142019, 0x142019, 0x070b08, 0x070b08, 1).fillRect(0, horizon, width, height - horizon);
    const front = this.add.graphics();
    [-30, 40, 1180, 1250, 1310].forEach((x, i) => pine(front, x, height - 40 + (i % 2) * 30, rnd.between(380, 470), 0x05070b));
    this.bake('bake_forest', statics).setDepth(-10);
    this.bake('bake_front', [front]).setDepth(5);

    // Drifting fog
    for (let i = 0; i < 5; i++) {
      const f = this.add.image(rnd.between(0, width), horizon + rnd.between(-10, 50), 'fx_soft')
        .setScale(rnd.between(10, 16), rnd.between(1, 2)).setAlpha(0.07).setTint(0x9fa8d8);
      this.tweens.add({ targets: f, x: f.x + rnd.between(80, 160), yoyo: true, repeat: -1, duration: rnd.between(9000, 15000), ease: 'Sine.inOut' });
    }

    // Tents
    const tents = [];
    const tent = (cx, base, w, h, col, dark) => {
      const g = this.add.graphics(); tents.push(g);
      g.fillStyle(0x000000, 0.35).fillEllipse(cx, base + 6, w * 1.15, 22);
      g.fillStyle(col).fillTriangle(cx - w / 2, base, cx, base - h, cx + w / 2, base);
      g.fillStyle(dark).fillTriangle(cx, base - h, cx + w / 2, base, cx + w * 0.18, base);
      g.fillStyle(0x0a0806).fillTriangle(cx - w * 0.12, base, cx, base - h * 0.45, cx + w * 0.12, base);
      g.lineStyle(2, 0x2a2016, 0.9).lineBetween(cx, base - h, cx, base - h - 14);
    };
    tent(220, 360, 240, 120, 0x6b5a3a, 0x4d3f28);
    tent(1060, 360, 240, 120, 0x5e5034, 0x433822);
    this.bake('bake_tents', tents).setDepth(1);
  }

  // Renders static Graphics into one texture and returns an Image of it.
  bake(key, objs) {
    const { width, height } = this.scale;
    if (this.textures.exists(key)) this.textures.remove(key);
    const tex = this.textures.addDynamicTexture(key, width, height);
    objs.forEach((o) => { tex.draw(o, 0, 0); o.destroy(); });
    return this.add.image(0, 0, key).setOrigin(0);
  }

  // ---------------- Pieces ----------------
  standee(id, x, y) {
    const c = this.add.container(x, y).setDepth(10);
    const shadow = this.add.ellipse(0, 12, 120, 20, 0x000000, 0.45);
    const back = this.add.rectangle(0, -60, 124, 124, 0x0d0a14).setStrokeStyle(2, 0x000000);
    const img = this.add.image(0, -60, `portrait_${id}`).setDisplaySize(112, 112).setTint(0xb8b8e0);
    const frame = this.add.rectangle(0, -60, 116, 116).setStrokeStyle(3, 0xe8b923);
    const name = this.label(0, 10, id[0].toUpperCase() + id.slice(1));
    c.add([shadow, back, img, frame, name]);
    c.img = img;
    this.tweens.add({ targets: c, y: y - 4, yoyo: true, repeat: -1, duration: 1300 + Math.random() * 500, ease: 'Sine.inOut' });
    return c;
  }

  label(x, y, text) {
    return this.add.text(x, y, text, {
      fontFamily: 'Nunito', fontSize: '18px', fontStyle: '900', color: '#1a1324',
      backgroundColor: '#f3e3b0', padding: { x: 8, y: 2 },
    }).setOrigin(0.5).setDepth(20);
  }

  tweenP(cfg) { return new Promise((res) => this.tweens.add({ ...cfg, onComplete: res })); }
  wait(ms) { return new Promise((res) => this.time.delayedCall(ms, res)); }

  async skornGrabsMap() {
    this.paper = this.add.rectangle(this.bag.x, this.bag.y - 10, 34, 24, 0xf1e6c8).setStrokeStyle(2, 0x8a7a55).setDepth(15);
    this.paperLabel = this.label(this.bag.x, this.bag.y - 44, 'map (very important)').setFontSize(14);
    this.tweens.add({ targets: this.paperLabel, alpha: 0, delay: 350, duration: 300 });
    await this.tweenP({ targets: [this.paper, this.paperLabel], x: this.skorn.x + 80, y: '+=40', duration: 700, ease: 'Sine.inOut' });
  }

  async burnMap() {
    this.paperLabel.destroy();
    await this.tweenP({ targets: this.paper, x: this.fireX, y: this.fireY - 10, angle: 360, duration: 600 });
    this.paper.destroy();
    this.cameras.main.flash(300, 255, 170, 90);
    this.fireLabel.setText('Fire (fed)');
    this.flames.start(); this.embers.start();
    this.tweens.add({ targets: [this.fireGlow], alpha: 0.75, duration: 600 });
    this.tweens.add({ targets: [this.groundGlow], alpha: 0.55, duration: 600 });
    // Flicker
    this.tweens.add({ targets: this.fireGlow, scale: 1.75, alpha: 0.6, yoyo: true, repeat: -1, duration: 140, ease: 'Sine.inOut', delay: 600 });
    // Warm firelight on the characters
    Object.values(this.chars).forEach((c) => c.img.setTint(0xffe2c4));
    await this.wait(700);
  }

  async morning() {
    this.tweens.add({ targets: [this.fireGlow, this.groundGlow], alpha: 0.2, duration: 1600 });
    this.embers.stop();
    Object.values(this.chars).forEach((c) => c.img.clearTint());
    await this.tweenP({ targets: this.dawn, alpha: 0.3, duration: 1600 });
  }

  finish() {
    if (this.finished) return;
    this.finished = true;
    this.cameras.main.fade(900, 0, 0, 0, true);
    this.cameras.main.once('camerafadeoutcomplete', () => this.scene.start('Title'));
  }
}
