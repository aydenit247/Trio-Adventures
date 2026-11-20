// Combat data: party stats and moves, items, and every fight in Chapter 1.
// Damage is set (no randomness) except where the dice decide (Crash Out).

export const PARTY = {
  skorn: {
    name: 'Skorn', hp: 90, hpLabel: 'HP (Hit Points)', tex: 'char_skorn', hurt: 'char_skorn_hurt', h: 320,
    moves: {
      main: { name: 'Diddy Slap', desc: 'A slap with intent. 14 damage.', pose: 'char_skorn_slap', kind: 'hit', power: 14, fx: 'slap' },
      special: { name: 'Crash Out', desc: 'Intense rage. Rolls the dice — on some dice shi.', pose: 'char_skorn_crashout', kind: 'crashout', cd: 3, fx: 'rage' },
      bonus: { name: 'Throw Anything', desc: 'Throws whatever is nearby. 10 damage.', pose: 'char_skorn_throw', kind: 'throw', power: 10, cd: 2 },
    },
  },
  lykor: {
    name: 'Lykor', hp: 70, hpLabel: 'Aura', tex: 'char_lykor', hurt: 'char_lykor_hurt', h: 305,
    moves: {
      main: { name: 'Hair Flip', desc: '10 damage. Might leave them too charmed to act.', pose: 'char_lykor_hairflip', kind: 'hit', power: 10, fx: 'sparkle', charm: 0.35 },
      special: { name: 'Mog', desc: 'Giga chad face. 22 damage + blinds (their next attack may miss).', pose: 'char_lykor_mog', kind: 'hit', power: 22, cd: 3, fx: 'mog', blind: true },
      bonus: { name: '"on some type shi"', desc: 'Screams it. The whole party hits 50% harder for 2 turns.', pose: 'char_lykor_scream', kind: 'buff', cd: 3 },
    },
  },
  xylo: {
    name: 'Xylo', hp: 75, hpLabel: 'Lore Points', tex: 'char_xylo', hurt: 'char_xylo_hurt', h: 310,
    moves: {
      main: { name: 'Eldritch Blast', desc: 'Classic. 13 damage.', pose: 'char_xylo_blast', kind: 'hit', power: 13, fx: 'blast' },
      special: { name: 'Deloye Lore', desc: 'Reads at length from a universe with no lore. 26 damage.', pose: 'char_xylo_lore', kind: 'hit', power: 26, cd: 3, fx: 'lore' },
      bonus: { name: 'Chud Out', desc: 'Gets huge and sits on them. 20 damage + they lose a turn.', pose: 'char_xylo_chudout', kind: 'chudout', power: 20, cd: 4, stun: true },
    },
  },
};

export const ITEMS = {
  beer: { name: 'Beezy', heal: 30, tex: 'item_beer', key: 'inv_beer' },
  bowl: { name: 'Chipotle Bowl', heal: 60, tex: 'item_chipotle_bowl', key: 'inv_bowl' },
};

export const THROWABLES = [
  'a goblin', 'a chair', 'a barrel', "Lykor's conditioner", 'an empty Chipotle Bowl',
  'a rock that looked at him funny', 'his own boot', 'a smaller orc (imaginary)',
];

// Tripping misfires (party took midtocy)
export const TRIP_MISFIRES = {
  skorn: ['Skorn tries to slap his own shadow. The shadow wins.', 'Skorn stops to have a deep conversation with his boot.', 'Skorn attacks a sound. The sound is fine.'],
  lykor: ["Lykor gets distracted by his own hair. It's so shiny today.", 'Lykor swings at a butterfly that isn\'t there.', 'Lykor apologizes to the floor for stepping on it.'],
  xylo: ['Xylo stares into the void. The void says "what."', 'Xylo prophesies about turnip prices. Nobody asked.', 'Xylo breathes on a cloud that looked suspicious.'],
};

export const FIGHTS = {
  goblins: {
    title: 'Skorn vs. The Goblins',
    party: ['skorn'],
    xp: 30,
    enemies: [
      { name: 'Goblin', tag: '(Unemployed)', hp: 24, tex: 'char_goblin_fight', h: 205, ai: 'goblin' },
      { name: 'Goblin', tag: '(Also Unemployed)', hp: 24, tex: 'char_goblin_fight', h: 190, ai: 'goblin' },
      { name: 'Goblin', tag: '(Between Jobs)', hp: 24, tex: 'char_goblin_fight', h: 215, ai: 'goblin' },
    ],
  },
  dulbers: {
    title: 'The Party vs. Dulbers Frint',
    party: ['skorn', 'lykor', 'xylo'],
    xp: 60,
    enemies: [{ name: 'Dulbers Frint', tag: '(Not Trustworthy)', hp: 240, tex: 'char_dulbers_demon', h: 410, ai: 'dulbers' }],
  },
  giant: {
    title: 'BOSS: Diddy Chud Giant',
    party: ['skorn', 'lykor', 'xylo'],
    xp: 100,
    boss: true,
    enemies: [{ name: 'Diddy Chud Giant', tag: '(Awake, Disturbed)', hp: 420, tex: 'char_giant_angry', sitTex: 'char_giant_sit', h: 520, ai: 'giant' }],
  },
};

// XP needed to reach each level (index = level)
export const LEVELS = [0, 0, 50, 120, 220, 350];
