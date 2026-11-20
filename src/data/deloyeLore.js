// Deloye Lore — used by the Lore Session minigame (Scene 4, choice C).
// Edit freely! The player first reads the page, then has to pick the ACCURATE continuation.
// Diddy Chud Giant is secretly a lore nerd: accurate lore soothes him, wrong lore wakes him up.

export const LORE_PAGE = {
  title: 'DELOYE LORE — Chapter 8,784, Section B12',
  facts: [
    'True metocy is NEVER moist.',
    'The first dragon was born when the Dragon Mama sneezed.',
    'The Council of Dulb meets every 400 years — or whenever Dulbmeethus is bored.',
    'The first goblin was carved from a single spoon.',
    'Nothing in Caelid is free, except prophecy.',
  ],
};

// `right` is the accurate continuation; the others are wrong.
export const LORE_LINES = [
  { stem: 'And it is written that true metocy must never be…', right: 'moist', wrong: ['blue', 'cheap'] },
  { stem: 'The first dragon came into this world when the Dragon Mama…', right: 'sneezed', wrong: ['sang', 'fell asleep'] },
  { stem: 'The Council of Dulb gathers every 400 years, or whenever…', right: 'Dulbmeethus is bored', wrong: ['the moon is full', 'Skorn shows up'] },
  { stem: 'From a single ___ came the very first goblin.', right: 'spoon', wrong: ['mushroom', 'boot'] },
  { stem: 'Nothing in Caelid is free, except…', right: 'prophecy', wrong: ['beezy', 'midtocy'] },
];
