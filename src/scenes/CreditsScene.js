import { vignette } from '../fx.js';
import Sfx from '../audio/Sfx.js';
import Outcomes, { OUTCOMES } from '../systems/outcomes.js';

const CREDITS = [
  ['title', 'Trio Adventures'],
  ['sub', 'Chapter 1: The Metocy'],
  ['gap'],
  ['role', 'Created, Written & Directed by', 'Ebain'],
  ['gap'],
  ['head', 'Starring'],
  ['role', 'Chaotic Purple Orc, Map Burner', 'Skorn'],
  ['role', 'The Mogging Elf', 'Lykor'],
  ['role', 'Mysterious Red Dragon, Lore Guy', 'Xylo'],
  ['gap'],
  ['head', 'Also Starring'],
  ['role', 'Shapeshifting Demon, Store Manager', 'Dulbers Frint'],
  ['role', 'Summoned (He Had Called?)', 'Metocin Mattias'],
  ['role', 'Very Large, Very Asleep', 'Diddy Chud Giant'],
  ['role', 'Chief of the Goblins, Beezy Distributor', 'Chief Bogdrinker'],
  ['role', 'Unemployed Goblins', 'The Goblins'],
  ['role', 'God Behind the Smoke (Not Pictured)', 'Dulbmeethus'],
  ['gap'],
  ['head', 'Department of Lore'],
  ['role', 'Head of Lore', 'Xylo'],
  ['role', 'Amount of Actual Lore', 'None'],
  ['role', 'Deloye Lore, Ch. 8,784 Sec. B12', 'Still Being Read'],
  ['gap'],
  ['head', 'Department of Hair'],
  ['role', 'Hair Consultant', 'Lykor'],
  ['role', 'Conditioner', 'Lykor\'s (Do Not Touch)'],
  ['gap'],
  ['head', 'Department of Rage'],
  ['role', 'Crash Out Coordinator', 'Skorn'],
  ['role', 'Things Thrown', 'Yes'],
  ['role', 'Maps Burned', '1 (The Only One)'],
  ['gap'],
  ['head', 'Catering'],
  ['role', 'Beverages', 'Beezy'],
  ['role', 'Meals', 'Chipotle Bowls'],
  ['role', 'Pharmaceuticals', 'Metocy Mart (Not FDA Approved)'],
  ['gap'],
  ['head', 'Special Thanks'],
  ['role', 'Dice Department', 'on some dice shi'],
  ['role', 'Choreography', 'The 6-7'],
  ['role', 'Engine', 'Phaser 3'],
  ['role', 'Code, Cutouts & Sounds', 'Claude'],
  ['gap'],
  ['sub', 'No goblins were harmed. Several were bonked.'],
  ['gap'],
  ['outcomes'],
  ['gap'],
  ['title', 'To Be Continued…'],
];

export default class CreditsScene extends Phaser.Scene {
  constructor() { super('Credits'); }

  create() {
    const { width, height } = this.scale;
    this.cameras.main.setBackgroundColor('#07060c').fadeIn(1200, 0, 0, 0);
    Sfx.play('choir');
    this.add.particles(0, 0, 'fx_soft', {
      x: { min: 0, max: width }, y: height + 10, speedY: { min: -50, max: -20 },
      scale: { start: 0.12, end: 0 }, alpha: { start: 0.8, end: 0 }, lifespan: 7000, frequency: 140,
      tint: [0xffc36b, 0x9fb8ff], blendMode: 'ADD',
    });
    const roll = this.add.container(0, height + 40);
    let y = 0;
    const T = (text, size, color, font = 'Nunito', style = '900') => this.add.text(width / 2, y, text, {
      fontFamily: font, fontSize: `${size}px`, fontStyle: style, color, align: 'center',
    }).setOrigin(0.5, 0);
    CREDITS.forEach(([kind, a, b]) => {
      if (kind === 'gap') { y += 50; return; }
      if (kind === 'title') { roll.add(T(a, 64, '#f3e3b0', 'Cinzel')); y += 90; return; }
      if (kind === 'sub') { roll.add(T(a, 24, '#e8b923', 'Nunito', 'italic')); y += 44; return; }
      if (kind === 'head') { roll.add(T(a, 30, '#e8b923', 'Cinzel')); y += 52; return; }
      if (kind === 'outcomes') {
        roll.add(T(`Outcomes found: ${Outcomes.count()} / ${OUTCOMES.length}`, 30, '#7dff8a', 'Cinzel'));
        y += 44;
        roll.add(T('Replay Chapter 1 to find the rest (Outcomes on the title screen).', 20, '#a49cc4', 'Nunito', 'normal'));
        y += 40;
        return;
      }
      roll.add(this.add.text(width / 2 - 20, y, a, { fontFamily: 'Nunito', fontSize: '22px', color: '#a49cc4' }).setOrigin(1, 0));
      roll.add(this.add.text(width / 2 + 20, y, b, { fontFamily: 'Nunito', fontSize: '22px', fontStyle: '900', color: '#f4efff' }).setOrigin(0, 0));
      y += 36;
    });
    vignette(this, 5);
    const endY = -(y - height / 2 - 40);
    this.scrollTween = this.tweens.add({ targets: roll, y: endY, duration: y * 22, ease: 'Linear' });
    this.add.text(width - 16, height - 14, 'Hold Space: faster · Esc: skip', { fontFamily: 'Nunito', fontSize: '15px', color: '#6e6690' }).setOrigin(1, 1).setDepth(10);
    const space = this.input.keyboard.addKey('SPACE');
    this.events.on('update', () => { if (this.scrollTween) this.scrollTween.timeScale = space.isDown ? 6 : 1; });
    this.scrollTween.on('complete', () => this.time.delayedCall(2500, () => this.leave()));
    this.input.keyboard.once('keydown-ESC', () => this.leave());
  }

  leave() {
    if (this.leaving) return;
    this.leaving = true;
    this.cameras.main.fade(900, 0, 0, 0, true);
    this.cameras.main.once('camerafadeoutcomplete', () => this.scene.start('Title'));
  }
}
