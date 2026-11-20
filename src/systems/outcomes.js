// Outcome tracker: every distinct result in Chapter 1. Found ones are saved across playthroughs.
// An outcome unlocks from a picked choice (choice text), from story flags when a scene ends, or directly.
const KEY = 'trio_outcomes';

export const OUTCOMES = [
  // Scene 2 — Goblin Village
  { id: 'g_speech', scene: 'Goblin Village', title: 'A Royal Speech', choice: ['Goblin', 'Give a royal speech'], hint: 'Say something kingly.' },
  { id: 'g_chug_win', scene: 'Goblin Village', title: 'Chug Champion', flag: ['Goblin', 'chugWon'], hint: 'Out-drink the chief.' },
  { id: 'g_chug_lose', scene: 'Goblin Village', title: 'Note On Your Forehead', flag: ['Goblin', 'foreheadLoser'], hint: 'Lose a drinking contest.' },
  { id: 'g_king', scene: 'Goblin Village', title: 'The Purple King', choice: ['Goblin', 'Offer Skorn as the new king'], hint: 'The goblins need a new leader…' },
  { id: 'g_sneak', scene: 'Goblin Village', title: 'Slow… Quiet…', choice: ['Goblin', 'Sneak out'], hint: 'Just tiptoe away.' },
  { id: 'g_fight', scene: 'Goblin Village', title: 'Skorn Negotiates', choice: ['Goblin', 'Let Skorn "negotiate"'], hint: 'Let the orc do the talking.' },
  // Scene 3 — Metocy Mart
  { id: 'm_all', scene: 'Metocy Mart', title: 'Group Trip', choice: ['Mart', 'Everyone takes it'], hint: 'Peer pressure.' },
  { id: 'm_skorn', scene: 'Metocy Mart', title: 'Lab Rat Skorn', choice: ['Mart', 'Let Skorn try it first'], hint: 'Someone has to go first.' },
  { id: 'm_refuse', scene: 'Metocy Mart', title: 'Just Say No', choice: ['Mart', 'Refuse it'], hint: "Don't take pills from strangers." },
  { id: 'm_inspect', scene: 'Metocy Mart', title: 'Section B12', choice: ['Mart', 'Have Xylo inspect it'], hint: 'Consult the lore.' },
  { id: 'm_goblins', scene: 'Metocy Mart', title: 'Goblin Quality Control', choice: ['Mart', 'Let the goblins taste-test it'], hint: 'Bring backup to the store.' },
  { id: 'm_noskorn', scene: 'Metocy Mart', title: 'A Store Without Skorn', flag: ['Mart', 'skornKing'], hint: 'Leave someone behind in the village.' },
  // Scene 4 — The Pass
  { id: 'p_throw', scene: 'The Pass', title: 'Giant Trip', choice: ['Pass', 'Skorn throws the midtocy'], hint: 'Hold on to the fake pill.' },
  { id: 'p_sneak_win', scene: 'The Pass', title: 'Bowl Thief', flag: ['Pass', 'sneakWon'], hint: "Sneak across without waking him." },
  { id: 'p_sneak_lose', scene: 'The Pass', title: 'Rude Awakening', choice: ['Pass', 'Sneak across him'], unlessFlag: 'sneakWon', hint: 'Sneak… badly.' },
  { id: 'p_lore_win', scene: 'The Pass', title: 'Bedtime Story', flag: ['Pass', 'loreWon'], hint: 'Read him to sleep — get the lore right.' },
  { id: 'p_lore_lose', scene: 'The Pass', title: 'Too Much Lore', choice: ['Pass', 'Xylo reads him Deloye Lore'], unlessFlag: 'loreWon', hint: 'Get the lore wrong.' },
  { id: 'p_fight', scene: 'The Pass', title: 'Slap The Giant', choice: ['Pass', 'Fight him'], hint: 'Wake him up the direct way.' },
  { id: 'p_cousin', scene: 'The Pass', title: 'Cousin Diplomacy', choice: ['Pass', 'Let Chief Bogdrinker handle it'], hint: 'Family connections.' },
  // Combat
  { id: 'c_67', scene: 'Combat', title: '6-7', hint: 'Roll a 6 during a Crash Out… and add one.' },
  { id: 'c_no67', scene: 'Combat', title: 'Saving It For Later', hint: 'Turn down a once-in-a-lifetime offer.' },
  { id: 'c_cooked', scene: 'Combat', title: 'Got Cooked', hint: 'Lose a fight.' },
];

const Outcomes = {
  found: {},
  load() { try { this.found = JSON.parse(localStorage.getItem(KEY) || '{}'); } catch (e) { this.found = {}; } },
  save() { try { localStorage.setItem(KEY, JSON.stringify(this.found)); } catch (e) { /* blocked */ } },
  has(id) { return !!this.found[id]; },
  unlock(id) {
    if (this.found[id] || !OUTCOMES.some((o) => o.id === id)) return false;
    this.found[id] = Date.now();
    this.save();
    document.dispatchEvent(new CustomEvent('trio-outcome', { detail: OUTCOMES.find((o) => o.id === id) }));
    return true;
  },
  // A choice was picked in a scene (unlocks right away unless it depends on a flag)
  onChoice(sceneKey, text) {
    OUTCOMES.filter((o) => o.choice && o.choice[0] === sceneKey && o.choice[1] === text && !o.unlessFlag)
      .forEach((o) => this.unlock(o.id));
  },
  // A scene finished: check flags (and choice+flag combos)
  onSceneEnd(sceneKey, registry, picked) {
    OUTCOMES.forEach((o) => {
      if (o.flag && o.flag[0] === sceneKey && registry.get(o.flag[1])) this.unlock(o.id);
      if (o.unlessFlag && o.choice[0] === sceneKey && picked.includes(o.choice[1]) && !registry.get(o.unlessFlag)) this.unlock(o.id);
    });
  },
  count() { return OUTCOMES.filter((o) => this.found[o.id]).length; },
  reset() { this.found = {}; this.save(); },
};
Outcomes.load();
export default Outcomes;
