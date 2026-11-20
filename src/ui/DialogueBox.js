import { CHARACTERS } from '../data/characters.js';
import Sfx from '../audio/Sfx.js';
import Voice from '../audio/Voice.js';
import Settings from '../systems/settings.js';
import Outcomes from '../systems/outcomes.js';

// Reusable dialogue box: portrait, name tag, typewriter text, choices.
//
// Script steps (see src/data/scenes/):
//   { who: 'lykor', line: 'Text here' }             a spoken line
//   { who: 'lykor', mood: 'angry', line: '...' }    uses portrait lykor_angry if it exists
//   { who: 'skorn', line: null, context: '...' }    an empty voiceline slot (shown as a placeholder)
//   { who: 'skorn', thought: true, line: '...' }    inner monologue (italic, in parentheses)
//   { who: 'narrator', line: '...' }                no portrait
//   { do: 'hookName' }                              calls hooks.hookName() and waits if it returns a Promise
//   { choice: [{ text: '...', steps: [...] }, ...] }
//   { if: 'goblinAllies', steps: [...] }          only plays if that story flag is set
//   { ifNot: 'skornKing', steps: [...] }          only plays if that flag is NOT set
export default class DialogueBox {
  constructor(scene) {
    this.scene = scene;
    const { width, height } = scene.scale;
    const boxH = 180, pad = 14;
    const y = height - boxH - pad;

    this.root = scene.add.container(0, 0).setDepth(1000).setVisible(false);

    // Panel: dark gradient with a gold double border and corner studs
    const pw = width - pad * 2;
    this.panel = scene.add.graphics();
    this.panel.fillGradientStyle(0x1d1633, 0x1d1633, 0x0b0812, 0x0b0812, 0.95).fillRect(pad, y, pw, boxH);
    this.panel.lineStyle(3, 0xe8b923, 1).strokeRect(pad, y, pw, boxH);
    this.panel.lineStyle(1, 0xe8b923, 0.35).strokeRect(pad + 7, y + 7, pw - 14, boxH - 14);
    [[pad, y], [pad + pw, y], [pad, y + boxH], [pad + pw, y + boxH]].forEach(([cx, cy]) => {
      this.panel.fillStyle(0xe8b923, 1).fillPoints([
        { x: cx, y: cy - 8 }, { x: cx + 8, y: cy }, { x: cx, y: cy + 8 }, { x: cx - 8, y: cy }], true);
    });
    this.portrait = scene.add.image(pad + 18 + 74, y + boxH / 2, '__DEFAULT').setDisplaySize(148, 148);
    this.portraitFrame = scene.add.rectangle(this.portrait.x, this.portrait.y, 152, 152)
      .setStrokeStyle(3, 0xe8b923);
    this.nameTag = scene.add.text(pad + 18, y - 40, '', {
      fontFamily: 'Cinzel', fontSize: '26px', fontStyle: '700', color: '#1a1324', backgroundColor: '#e8b923',
      padding: { x: 16, y: 5 },
    });
    this.textX = pad + 18 + 148 + 28;
    this.textW = width - pad * 2 - (this.textX - pad) - 30;
    this.body = scene.add.text(this.textX, y + 22, '', {
      fontFamily: 'Nunito', fontSize: '26px', color: '#f4efff', lineSpacing: 6,
      shadow: { offsetX: 0, offsetY: 2, color: '#000', blur: 4, fill: true },
      wordWrap: { width: this.textW },
    });
    this.arrow = scene.add.text(width - pad - 40, y + boxH - 44, '▼', {
      fontFamily: 'Nunito', fontSize: '24px', color: '#e8b923',
    });
    scene.tweens.add({ targets: this.arrow, y: this.arrow.y + 6, yoyo: true, repeat: -1, duration: 400 });

    this.choiceTexts = [];
    this.root.add([this.panel, this.portraitFrame, this.portrait, this.nameTag, this.body, this.arrow]);

    this.boxY = y;
    this.full = '';
    this.shown = 0;
    this.choosing = null;

    const kb = scene.input.keyboard;
    kb.on('keydown-SPACE', () => this.advance());
    kb.on('keydown-ENTER', () => this.advance());
    kb.on('keydown-E', () => this.advance());
    kb.on('keydown-UP', () => this.moveChoice(-1));
    kb.on('keydown-DOWN', () => this.moveChoice(1));
    kb.on('keydown-W', () => this.moveChoice(-1));
    kb.on('keydown-S', () => this.moveChoice(1));
    scene.input.on('pointerdown', () => {
      // Ignore the same click that just picked a choice.
      if (!this.choosing && scene.time.now - (this.pickedAt || 0) > 80) this.advance();
    });
  }

  // Plays a script; resolves when it finishes.
  play(steps, hooks = {}) {
    this.hooks = hooks;
    this.queue = steps.slice();
    this.root.setVisible(true);
    return new Promise((resolve) => { this.onDone = resolve; this.next(); });
  }

  async next() {
    while (this.queue.length) {
      const s = this.queue.shift();
      if (s.do) {
        this.root.setVisible(false);
        const fn = this.hooks[s.do];
        const r = fn ? fn() : null;
        if (r && typeof r.then === 'function') await r;
        continue;
      }
      if (s.if || s.ifNot) { // conditional block: { if: 'flag', steps } or { ifNot: 'flag', steps }
        const on = !!(this.hooks.check && this.hooks.check(s.if || s.ifNot));
        if (s.if ? on : !on) this.queue = (s.steps || []).concat(this.queue);
        continue;
      }
      if (s.choice) {
        // Options can be hidden behind a story flag: { text, if: 'goblinAllies', steps }
        const opts = s.choice.filter((o) => !o.if || (this.hooks.check && this.hooks.check(o.if)));
        this.root.setVisible(true); this.showChoice(opts); return;
      }
      this.root.setVisible(true);
      this.showLine(s);
      return;
    }
    this.root.setVisible(false);
    const done = this.onDone; this.onDone = null;
    if (done) done();
  }

  showLine(s) {
    const c = CHARACTERS[s.who] || CHARACTERS.narrator;
    const narrator = !s.who || s.who === 'narrator';
    this.voice = narrator ? 'narrator' : s.who;

    this.portrait.setVisible(!narrator);
    this.portraitFrame.setVisible(!narrator);
    if (!narrator) {
      const pid = c.portrait || s.who;
      const moodKey = s.mood ? `portrait_${pid}_${s.mood}` : null;
      const key = moodKey && this.scene.textures.exists(moodKey) ? moodKey : `portrait_${pid}`;
      this.portrait.setTexture(key).setDisplaySize(148, 148);
    }
    this.nameTag.setVisible(!narrator && !!c.name).setText(c.name || '');

    if (this.hooks && this.hooks.onLine) this.hooks.onLine(s);
    const x = narrator ? 60 : this.textX;
    this.body.setX(x).setWordWrapWidth(narrator ? this.scene.scale.width - 120 : this.textW);

    if (s.line == null) {
      // Empty voiceline slot — show the scene context so it's obvious what goes here.
      this.full = `[VOICELINE NEEDED] ${s.context || ''}`;
      this.body.setColor('#ff9f6b').setFontStyle('italic');
    } else {
      this.full = s.thought ? `(${s.line})` : s.line;
      Voice.say(this.voice, s.line, { thought: !!s.thought });
      const soft = narrator || s.thought;
      this.body.setColor(narrator ? '#cfc6ff' : s.thought ? '#c9c2e0' : '#f4efff')
        .setFontStyle(soft ? 'italic' : 'normal');
    }
    this.shown = 0;
    this.body.setText('');
    this.arrow.setVisible(false);
    if (this.typer) this.typer.remove();
    this.typer = null;
    if (!Settings.textMs()) { this.shown = this.full.length; this.body.setText(this.full); this.arrow.setVisible(true); return; }
    const typer = this.scene.time.addEvent({
      delay: Settings.textMs(), loop: true,
      callback: () => {
        if (this.typer !== typer) { typer.remove(); return; } // a newer line took over
        this.shown += 1;
        this.body.setText(this.full.slice(0, this.shown));
        const ch = this.full[this.shown - 1];
        if (this.shown % 2 === 1 && ch && ch.trim() && !(Voice.on && !Sfx.muted && s.line)) Sfx.blip(this.voice);
        if (this.shown >= this.full.length) { typer.remove(); this.typer = null; this.arrow.setVisible(true); }
      },
    });
    this.typer = typer;
  }

  advance() {
    if (!this.root.visible) return;
    if (this.choosing) { this.pickChoice(this.choosing.sel); return; }
    if (this.typer) { // finish the line instantly
      this.typer.remove(); this.typer = null;
      this.shown = this.full.length; this.body.setText(this.full); this.arrow.setVisible(true);
      return;
    }
    Voice.stop();
    Sfx.play('click');
    this.next();
  }

  showChoice(options) {
    this.portrait.setVisible(false); this.portraitFrame.setVisible(false);
    this.nameTag.setVisible(false); this.arrow.setVisible(false);
    this.body.setText('');
    this.choosing = { options, sel: 0 };
    const many = options.length > 4; // tighter list so five options fit the box
    options.forEach((o, i) => {
      const t = this.scene.add.text(80, this.boxY + (many ? 14 : 28) + i * (many ? 31 : 42), '', {
        fontFamily: 'Nunito', fontSize: many ? '24px' : '28px', color: '#f4efff',
      }).setInteractive({ useHandCursor: true });
      t.on('pointerover', () => { this.choosing.sel = i; this.renderChoices(); });
      t.on('pointerdown', () => this.pickChoice(i));
      this.root.add(t);
      this.choiceTexts.push(t);
    });
    this.renderChoices();
  }

  renderChoices() {
    this.choiceTexts.forEach((t, i) => {
      const on = i === this.choosing.sel;
      t.setText(`${on ? '▶ ' : '   '}${this.choosing.options[i].text}`).setColor(on ? '#e8b923' : '#f4efff');
    });
  }

  moveChoice(d) {
    if (!this.choosing) return;
    const n = this.choosing.options.length;
    this.choosing.sel = (this.choosing.sel + d + n) % n;
    Sfx.play('tick');
    this.renderChoices();
  }

  pickChoice(i) {
    const opt = this.choosing.options[i];
    this.pickedAt = this.scene.time.now;
    (this.scene.picked = this.scene.picked || []).push(opt.text);
    Outcomes.onChoice(this.scene.scene.key, opt.text);
    Sfx.play('confirm');
    this.choiceTexts.forEach((t) => t.destroy());
    this.choiceTexts = [];
    this.choosing = null;
    this.queue = (opt.steps || []).concat(this.queue);
    this.next();
  }
}
