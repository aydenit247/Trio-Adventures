import OverlayScene from './OverlayScene.js';
import Settings, { TEXT_SPEEDS } from '../systems/settings.js';
import Voice from '../audio/Voice.js';
import Sfx from '../audio/Sfx.js';
import { DIFFICULTY } from '../data/combat.js';

const ROWS = [
  { k: 'textSpeed', label: 'Text speed', kind: 'list', values: TEXT_SPEEDS.map((t) => t.name) },
  { k: 'music', label: 'Music volume', kind: 'pct', max: 1 },
  { k: 'sfx', label: 'Sound effects volume', kind: 'pct', max: 1 },
  { k: 'voice', label: 'Voice volume', kind: 'pct', max: 1 },
  { k: 'voiceRate', label: 'Voice speed', kind: 'rate', min: 0.6, max: 1.6 },
  { k: 'combatDiff', label: 'Combat difficulty', kind: 'list', values: DIFFICULTY.map((d) => d.name) },
  { k: 'timedHits', label: 'Timed hits & blocks', kind: 'list', values: ['Auto (always GOOD)', 'On'] },
  { k: 'test', label: 'Test voices', kind: 'button' },
  { k: 'close', label: 'Done', kind: 'button' },
];

export default class SettingsScene extends OverlayScene {
  constructor() { super('Settings'); }

  create() {
    this.openOverlay('Settings');
    const { width } = this.scale;
    this.sel = 0;
    this.rows = ROWS.map((r, i) => {
      const y = 150 + i * 52;
      const label = this.add.text(width / 2 - 360, y, r.label, { fontFamily: 'Nunito', fontSize: '26px', fontStyle: '900', color: '#f4efff' }).setOrigin(0, 0.5);
      const value = this.add.text(width / 2 + 360, y, '', { fontFamily: 'Nunito', fontSize: '26px', fontStyle: '900', color: '#e8b923' }).setOrigin(1, 0.5);
      let bar = null;
      if (r.kind === 'pct' || r.kind === 'rate') {
        this.add.rectangle(width / 2 + 40, y, 200, 10, 0x2a2340).setOrigin(0, 0.5);
        bar = this.add.rectangle(width / 2 + 40, y, 200, 10, 0xe8b923).setOrigin(0, 0.5);
      }
      [label, value].forEach((t) => t.setInteractive({ useHandCursor: true })
        .on('pointerover', () => { this.sel = i; this.render(); })
        .on('pointerdown', () => { this.sel = i; this.change(1, true); }));
      return { r, label, value, bar };
    });
    this.add.text(width / 2, 150 + ROWS.length * 52 + 2, '↑/↓ choose · ←/→ change', { fontFamily: 'Nunito', fontSize: '16px', color: '#a49cc4' }).setOrigin(0.5);
    const kb = this.input.keyboard;
    ['UP', 'W'].forEach((k) => kb.on(`keydown-${k}`, () => { this.sel = (this.sel + ROWS.length - 1) % ROWS.length; Sfx.play('tick'); this.render(); }));
    ['DOWN', 'S'].forEach((k) => kb.on(`keydown-${k}`, () => { this.sel = (this.sel + 1) % ROWS.length; Sfx.play('tick'); this.render(); }));
    ['LEFT', 'A'].forEach((k) => kb.on(`keydown-${k}`, () => this.change(-1)));
    ['RIGHT', 'D'].forEach((k) => kb.on(`keydown-${k}`, () => this.change(1)));
    ['ENTER', 'SPACE'].forEach((k) => kb.on(`keydown-${k}`, () => this.change(1, true)));
    this.render();
  }

  change(d, press = false) {
    const { r } = this.rows[this.sel];
    if (r.kind === 'button') {
      if (!press) return;
      if (r.k === 'close') { this.close(); return; }
      if (r.k === 'test') { this.testVoices(); return; }
    }
    if (r.kind === 'list') {
      const n = r.values.length;
      Settings.set(r.k, (Settings[r.k] + d + n) % n);
    } else if (r.kind === 'pct') {
      let v = Math.round((Settings[r.k] + d * 0.1) * 10) / 10;
      if (press && v > r.max) v = 0;
      Settings.set(r.k, Phaser.Math.Clamp(v, 0, r.max));
    } else if (r.kind === 'rate') {
      let v = Math.round((Settings[r.k] + d * 0.1) * 10) / 10;
      if (press && v > r.max) v = r.min;
      Settings.set(r.k, Phaser.Math.Clamp(v, r.min, r.max));
    }
    Sfx.play('tick');
    this.render();
  }

  testVoices() {
    const lines = [['skorn', 'Bet, my fault.'], ['lykor', 'Map-burners don\'t get a vote.'], ['xylo', 'Sum don\'t feel right, folk.']];
    let i = 0;
    const next = () => { if (i < lines.length && this.scene.isActive()) { Voice.say(lines[i][0], lines[i][1]); i += 1; setTimeout(next, 2200); } };
    next();
  }

  render() {
    this.rows.forEach(({ r, label, value, bar }, i) => {
      const on = i === this.sel;
      label.setColor(on ? '#e8b923' : '#f4efff').setText(`${on ? '▶ ' : ''}${r.label}`);
      if (r.kind === 'list') value.setText(`◀ ${r.values[Settings[r.k]]} ▶`);
      if (r.kind === 'pct') { value.setText(`${Math.round(Settings[r.k] * 100)}%`); bar.width = 200 * Settings[r.k] / r.max; }
      if (r.kind === 'rate') { value.setText(`${Settings[r.k].toFixed(1)}x`); bar.width = 200 * (Settings[r.k] - r.min) / (r.max - r.min); }
      if (r.kind === 'button') value.setText('');
    });
  }
}
