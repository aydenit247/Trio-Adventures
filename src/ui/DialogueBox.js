import { CHARACTERS } from '../data/characters.js';

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
export default class DialogueBox {
  constructor(scene) {
    this.scene = scene;
    const { width, height } = scene.scale;
    const boxH = 210, pad = 24;
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
    this.portrait = scene.add.image(pad + 18 + 84, y + boxH / 2, '__DEFAULT').setDisplaySize(168, 168);
    this.portraitFrame = scene.add.rectangle(this.portrait.x, this.portrait.y, 172, 172)
      .setStrokeStyle(3, 0xe8b923);
    this.nameTag = scene.add.text(pad + 18, y - 40, '', {
      fontFamily: 'Cinzel', fontSize: '26px', fontStyle: '700', color: '#1a1324', backgroundColor: '#e8b923',
      padding: { x: 16, y: 5 },
    });
    this.textX = pad + 18 + 168 + 28;
    this.textW = width - pad * 2 - (this.textX - pad) - 30;
    this.body = scene.add.text(this.textX, y + 26, '', {
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
      if (s.choice) { this.root.setVisible(true); this.showChoice(s.choice); return; }
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

    this.portrait.setVisible(!narrator);
    this.portraitFrame.setVisible(!narrator);
    if (!narrator) {
      const moodKey = s.mood ? `portrait_${s.who}_${s.mood}` : null;
      const key = moodKey && this.scene.textures.exists(moodKey) ? moodKey : `portrait_${s.who}`;
      this.portrait.setTexture(key).setDisplaySize(168, 168);
    }
    this.nameTag.setVisible(!narrator && !!c.name).setText(c.name || '');

    const x = narrator ? 60 : this.textX;
    this.body.setX(x).setWordWrapWidth(narrator ? this.scene.scale.width - 120 : this.textW);

    if (s.line == null) {
      // Empty voiceline slot — show the scene context so it's obvious what goes here.
      this.full = `[VOICELINE NEEDED] ${s.context || ''}`;
      this.body.setColor('#ff9f6b').setFontStyle('italic');
    } else {
      this.full = s.thought ? `(${s.line})` : s.line;
      const soft = narrator || s.thought;
      this.body.setColor(narrator ? '#cfc6ff' : s.thought ? '#c9c2e0' : '#f4efff')
        .setFontStyle(soft ? 'italic' : 'normal');
    }
    this.shown = 0;
    this.body.setText('');
    this.arrow.setVisible(false);
    if (this.typer) this.typer.remove();
    const typer = this.scene.time.addEvent({
      delay: 22, loop: true,
      callback: () => {
        if (this.typer !== typer) { typer.remove(); return; } // a newer line took over
        this.shown += 1;
        this.body.setText(this.full.slice(0, this.shown));
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
    this.next();
  }

  showChoice(options) {
    this.portrait.setVisible(false); this.portraitFrame.setVisible(false);
    this.nameTag.setVisible(false); this.arrow.setVisible(false);
    this.body.setText('');
    this.choosing = { options, sel: 0 };
    options.forEach((o, i) => {
      const t = this.scene.add.text(80, this.boxY + 28 + i * 42, '', {
        fontFamily: 'Nunito', fontSize: '28px', color: '#f4efff',
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
    this.renderChoices();
  }

  pickChoice(i) {
    const opt = this.choosing.options[i];
    this.pickedAt = this.scene.time.now;
    this.choiceTexts.forEach((t) => t.destroy());
    this.choiceTexts = [];
    this.choosing = null;
    this.queue = (opt.steps || []).concat(this.queue);
    this.next();
  }
}
