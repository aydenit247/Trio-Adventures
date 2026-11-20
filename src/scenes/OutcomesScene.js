import OverlayScene from './OverlayScene.js';
import Outcomes, { OUTCOMES } from '../systems/outcomes.js';

export default class OutcomesScene extends OverlayScene {
  constructor() { super('Outcomes'); }

  create() {
    this.openOverlay('Outcomes');
    const { width } = this.scale;
    this.add.text(width / 2, 128, `${Outcomes.count()} / ${OUTCOMES.length} found  ·  replay to find the rest`, {
      fontFamily: 'Nunito', fontSize: '20px', fontStyle: '900', color: '#e8b923',
    }).setOrigin(0.5);
    const groups = ['Goblin Village', 'Metocy Mart', 'The Pass', 'Combat'];
    const cols = [[110, groups.slice(0, 2)], [660, groups.slice(2)]];
    cols.forEach(([x, gs]) => {
      let y = 168;
      gs.forEach((g) => {
        const list = OUTCOMES.filter((o) => o.scene === g);
        const n = list.filter((o) => Outcomes.has(o.id)).length;
        this.add.text(x, y, `${g}  (${n}/${list.length})`, { fontFamily: 'Cinzel', fontSize: '22px', fontStyle: '900', color: '#f3e3b0' });
        y += 34;
        list.forEach((o) => {
          const got = Outcomes.has(o.id);
          this.add.text(x + 10, y, got ? `✔  ${o.title}` : `?  ???  —  ${o.hint}`, {
            fontFamily: 'Nunito', fontSize: '17px', fontStyle: got ? '900' : 'italic', color: got ? '#7dff8a' : '#8a82ac',
            wordWrap: { width: 500 },
          });
          y += 25;
        });
        y += 16;
      });
    });
  }
}
