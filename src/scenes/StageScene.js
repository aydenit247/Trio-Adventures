import DialogueBox from '../ui/DialogueBox.js';
import { vignette } from '../fx.js';
import Sfx from '../audio/Sfx.js';

// Shared base for story scenes: painted backdrop, full-body characters,
// speaker highlight, lighting moods, labels, walking, and cutscene videos.
//
// All backdrops are 1024x572 art shown 10% larger than "cover" so the action sits
// above the dialogue box. `at(x, y)` converts art coordinates to screen coordinates.
export const BG = { scale: 1.375, left: -64, top: -100 };
export const at = (x, y) => ({ x: x * BG.scale + BG.left, y: y * BG.scale + BG.top });

// Character tint per lighting mood [r, g, b]
const LIGHT = {
  moon:   [205, 212, 255],
  day:    [255, 244, 230],
  shop:   [235, 225, 255],
  candle: [255, 226, 196],
  lava:   [255, 200, 172],
};

export default class StageScene extends Phaser.Scene {
  // Call at the start of create()
  setupStage({ fadeMs = 1200, light = 'day' } = {}) {
    this.chars = {};
    this.speaker = null;
    this.light = light;
    this.finished = false;
    this.cameras.main.setBackgroundColor('#05040a').fadeIn(fadeMs, 0, 0, 0);
    this.events.once('shutdown', () => { Sfx.stopAll(); this.tripOff(true); });
  }

  // Call at the end of create(), then play a script with this.dialogue.play(...)
  finishStage() {
    vignette(this);
    this.cameras.main.zoomTo(1.02, 40000, 'Sine.easeInOut');
    this.skipHint = this.add.text(this.scale.width - 16, 12, 'ESC: skip', {
      fontFamily: 'Nunito', fontSize: '16px', color: '#a49cc4',
    }).setOrigin(1, 0).setDepth(950);
    this.input.keyboard.once('keydown-ESC', () => this.finish(this.nextScene));
    this.dialogue = new DialogueBox(this);
  }

  // Default hooks every scene gets; scenes add their own on top.
  baseHooks(extra = {}) {
    return {
      onLine: (s) => this.setSpeaker(!s.who || s.who === 'narrator' ? null : s.who),
      shake: () => { this.cameras.main.shake(400, 0.01); Sfx.play('boom'); return this.wait(350); },
      freakout: () => {
        Sfx.play('dramatic'); Sfx.play('boom');
        this.cameras.main.shake(450, 0.012);
        Object.values(this.chars).forEach((c) => this.hop(c, 18));
        return this.wait(400);
      },
      ...extra,
    };
  }

  // ---------------- Backdrops ----------------
  placeBg(key) {
    const img = this.add.image(BG.left, BG.top, key).setOrigin(0);
    return img.setScale(BG.scale * (1024 / img.width));
  }

  // Crossfade from the current backdrop to another
  swapBg(key, ms = 800) {
    const next = this.placeBg(key).setAlpha(0).setDepth((this.bg ? this.bg.depth : 0) + 0.01);
    const old = this.bg;
    this.bg = next;
    return this.tweenP({ targets: next, alpha: 1, duration: ms }).then(() => { if (old) old.destroy(); next.setDepth(0); });
  }

  fog(tint = 0xb8c4ff, alpha = 0.07, yMin = 330, yMax = 480) {
    const { width } = this.scale;
    for (let i = 0; i < 6; i++) {
      const f = this.add.image(Phaser.Math.Between(-100, width), Phaser.Math.Between(yMin, yMax), 'fx_soft')
        .setScale(Phaser.Math.Between(12, 20), Phaser.Math.FloatBetween(1.2, 2.2))
        .setAlpha(alpha).setTint(tint).setDepth(2);
      this.tweens.add({ targets: f, x: f.x + Phaser.Math.Between(120, 260), yoyo: true, repeat: -1,
        duration: Phaser.Math.Between(10000, 18000), ease: 'Sine.inOut' });
    }
  }

  // ---------------- Characters ----------------
  // key: unique name in this.chars. opts: { tex, voice, h, flip, breathe }
  makeChar(key, x, feetY, opts = {}) {
    const h = opts.h || 330;
    const c = this.add.container(x, feetY).setDepth(10 + feetY / 100);
    const shadow = this.add.ellipse(0, 0, h * 0.42, h * 0.07, 0x000000, 0.5);
    const img = this.add.image(0, 0, opts.tex || `char_${key}`).setOrigin(0.5, 1).setFlipX(!!opts.flip);
    const s = h / img.height;
    img.setScale(s);
    c.add([shadow, img]);
    c.img = img; c.shadow = shadow; c.baseScale = s; c.key = key; c.voice = opts.voice || key; c.h = h;
    if (opts.breathe !== false) {
      c.breath = this.tweens.add({ targets: img, scaleY: s * 1.012, scaleX: s * 0.996, yoyo: true, repeat: -1,
        duration: 1600 + Math.random() * 600, ease: 'Sine.inOut', delay: Math.random() * 800 });
    }
    this.chars[key] = c;
    return c;
  }

  // Swap a character's image (e.g. standing -> kneeling), keeping their height or a new one
  setCharTex(c, tex, h) {
    if (c.breath) c.breath.stop();
    c.img.setTexture(tex);
    const s = (h || c.h) / c.img.height;
    c.img.setScale(s); c.baseScale = s;
    c.shadow.setSize(c.img.displayWidth * 0.8, (h || c.h) * 0.07);
    c.breath = this.tweens.add({ targets: c.img, scaleY: s * 1.012, scaleX: s * 0.996, yoyo: true, repeat: -1,
      duration: 1700, ease: 'Sine.inOut' });
  }

  showChar(c, ms = 400) { c.setAlpha(0).setVisible(true); return this.tweenP({ targets: c, alpha: 1, duration: ms }); }
  hideChar(c, ms = 300) { return this.tweenP({ targets: c, alpha: 0, duration: ms }).then(() => c.setVisible(false)); }

  setSpeaker(who) {
    if (who === this.speaker) return;
    this.speaker = who;
    Object.values(this.chars).forEach((c) => { if (who && c.voice === who && c.visible) this.hop(c, 8); });
  }

  hop(c, px) {
    this.tweens.add({ targets: c.img, y: -px, duration: 110, yoyo: true, ease: 'Quad.out' });
  }

  // Walks a character to x with a bobbing step and footstep sounds.
  walk(c, toX, msPerPx = 2.2) {
    const dist = Math.abs(toX - c.x);
    if (dist < 2) return Promise.resolve();
    c.img.setFlipX(toX < c.x);
    const steps = this.tweens.add({ targets: c.img, y: -7, duration: 170, yoyo: true, repeat: -1, ease: 'Sine.inOut',
      onYoyo: () => Sfx.play('step') });
    return this.tweenP({ targets: c, x: toX, duration: dist * msPerPx, ease: 'Linear',
      onUpdate: () => { if (this.onWalkUpdate) this.onWalkUpdate(c); } })
      .then(() => { steps.stop(); c.img.y = 0; });
  }

  // Lighting: dim whoever isn't talking; tint everyone for the scene's mood.
  update(time) {
    let base;
    if (this.light === 'fire') {
      const f = 0.85 + 0.15 * Math.sin(time * 0.023) * Math.sin(time * 0.0137);
      base = [255, 205 + 25 * f, 165 + 20 * f];
      if (this.onFireFlicker) this.onFireFlicker(f);
    } else if (this.light === 'trip') {
      const t = time * 0.002;
      base = [200 + 55 * Math.sin(t), 200 + 55 * Math.sin(t + 2.1), 200 + 55 * Math.sin(t + 4.2)];
    } else {
      base = LIGHT[this.light] || LIGHT.day;
    }
    Object.values(this.chars).forEach((c) => {
      const b = !this.speaker || this.speaker === c.voice ? 1 : 0.62;
      c.img.setTint(Phaser.Display.Color.GetColor(base[0] * b, base[1] * b, base[2] * b));
    });
    if (this.trip) this.updateTrip(time);
  }

  // ---------------- Trippy camera (midtocy) ----------------
  tripOn() {
    if (this.trip) return;
    const cam = this.cameras.main;
    this.trip = { cm: cam.postFX ? cam.postFX.addColorMatrix() : null };
    this.light = 'trip';
    Sfx.startLoop('trip');
  }

  updateTrip(time) {
    const cam = this.cameras.main;
    cam.setRotation(Math.sin(time * 0.0011) * 0.025);
    cam.setZoom(1.04 + Math.sin(time * 0.0017) * 0.03);
    if (this.trip.cm) this.trip.cm.hue((time * 0.03) % 360);
  }

  tripOff(silent) {
    if (!this.trip) return;
    const cam = this.cameras.main;
    if (cam.postFX && this.trip.cm) cam.postFX.remove(this.trip.cm);
    cam.setRotation(0); cam.setZoom(1.02);
    this.trip = null;
    if (!silent) Sfx.stopLoop('trip');
  }

  // ---------------- Labels ----------------
  label(x, y, text, size = 18) {
    return this.add.text(x, y, text, {
      fontFamily: 'Nunito', fontSize: `${size}px`, fontStyle: '900', color: '#1a1324',
      backgroundColor: '#f3e3b0', padding: { x: 8, y: 2 },
    }).setOrigin(0.5).setDepth(30);
  }

  showLabel(lbl) {
    Sfx.play('pop');
    lbl.setScale(0.6).setVisible(true);
    return this.tweenP({ targets: lbl, alpha: 1, scale: 1, duration: 260, ease: 'Back.out' });
  }

  // Label that follows a character's head
  charLabel(c, text) {
    const l = this.label(c.x, c.y - c.h - 18, text, 16).setAlpha(0);
    l.follow = c;
    const fn = () => {
      if (!l.active || !l.follow) return;
      l.setPosition(l.follow.x, l.follow.y - l.follow.h - 18);
      if (!l.follow.visible) l.setVisible(false); // leaves with its character
    };
    this.events.on('postupdate', fn);
    this.events.once('shutdown', () => this.events.off('postupdate', fn));
    return l;
  }

  // ---------------- Utility ----------------
  tweenP(cfg) { return new Promise((res) => this.tweens.add({ ...cfg, onComplete: res })); }
  wait(ms) { return new Promise((res) => this.time.delayedCall(ms, res)); }

  // Full-screen video; Space/Enter/click skips. opts.keyed = remove green screen and keep the backdrop.
  playCutscene(key, opts = {}) {
    return new Promise((resolve) => {
      const { width, height } = this.scale;
      const hidden = [...Object.values(this.chars).filter((c) => c.visible), ...(opts.alsoHide || [])];
      if (this.skipHint) hidden.push(this.skipHint);
      hidden.forEach((o) => o.setVisible(false));

      let done = false;
      const vid = this.add.video(width / 2, height / 2, key).setDepth(opts.keyed ? 15 : 800);
      if (opts.keyed && this.renderer.pipelines) vid.setPostPipeline('ChromaKey');
      const skipTxt = this.add.text(width - 16, height - 14, 'Space: skip', {
        fontFamily: 'Nunito', fontSize: '16px', color: '#ffffffaa',
      }).setOrigin(1, 1).setDepth(960);
      const finish = () => {
        if (done) return; done = true;
        this.input.keyboard.off('keydown-SPACE', finish);
        this.input.keyboard.off('keydown-ENTER', finish);
        this.input.off('pointerdown', finish);
        const end = () => {
          vid.stop(); vid.destroy(); skipTxt.destroy();
          hidden.forEach((o) => o.setVisible(true));
          resolve();
        };
        if (opts.keyed) end();
        else { this.cameras.main.fade(250, 0, 0, 0, true); this.time.delayedCall(260, end); }
      };

      vid.setMute(Sfx.muted);
      vid.on('created', () => vid.setDisplaySize(width, height));
      vid.on('complete', finish);
      vid.on('error', finish);
      vid.play(false);
      this.time.delayedCall(3000, () => { if (!done && !vid.isPlaying()) finish(); });
      this.time.delayedCall(400, () => {
        if (done) return;
        this.input.keyboard.on('keydown-SPACE', finish);
        this.input.keyboard.on('keydown-ENTER', finish);
        this.input.on('pointerdown', finish);
      });
    });
  }

  // Placeholder until the combat system exists
  fightPlaceholder(title) {
    return new Promise((resolve) => {
      const { width, height } = this.scale;
      Sfx.play('boom');
      this.cameras.main.flash(300, 255, 80, 60);
      const shade = this.add.rectangle(0, 0, width, height, 0x000000, 0.75).setOrigin(0).setDepth(970);
      const t1 = this.add.text(width / 2, height / 2 - 60, `⚔  ${title}  ⚔`, {
        fontFamily: 'Cinzel', fontSize: '46px', fontStyle: '900', color: '#ff6a4a', stroke: '#000', strokeThickness: 6,
      }).setOrigin(0.5).setDepth(971);
      const t2 = this.add.text(width / 2, height / 2 + 10, '[ COMBAT GOES HERE ]\n(on some combat shi — coming soon)', {
        fontFamily: 'Nunito', fontSize: '24px', color: '#f3e3b0', align: 'center',
      }).setOrigin(0.5).setDepth(971);
      const t3 = this.add.text(width / 2, height / 2 + 110, 'Press Space — the party wins (for now)', {
        fontFamily: 'Nunito', fontSize: '18px', color: '#a49cc4',
      }).setOrigin(0.5).setDepth(971);
      const done = () => {
        this.input.keyboard.off('keydown-SPACE', done); this.input.off('pointerdown', done);
        Sfx.play('confirm');
        [shade, t1, t2, t3].forEach((o) => o.destroy());
        resolve();
      };
      this.time.delayedCall(500, () => { this.input.keyboard.on('keydown-SPACE', done); this.input.on('pointerdown', done); });
    });
  }

  finish(next = 'Title', data) {
    if (this.finished) return;
    this.finished = true;
    this.cameras.main.fade(900, 0, 0, 0, true);
    this.cameras.main.once('camerafadeoutcomplete', () => this.scene.start(next, data));
  }
}
