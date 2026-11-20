// Character roster, portraits and moves.
// Damage numbers are PLACEHOLDERS until combat is designed for real — see DESIGN.md.

export const CHARACTERS = {
  skorn: {
    name: 'Skorn',
    color: 0x8e4fc4,
    blurb: 'Angry orc. Gold armor. Pure chaos.',
    moves: {
      main:    { name: 'Diddy Slap',     damage: 12, desc: 'A slap with intent.' },
      special: { name: 'Crash Out',      damage: 25, desc: 'Intense rage. Consequences TBD.' },
      bonus:   { name: 'Throw Anything', damage: 8,  desc: 'Anything. Including friends.' },
    },
  },
  lykor: {
    name: 'Lykor',
    color: 0xe8c45a,
    blurb: 'Handsome elf. Knows it.',
    moves: {
      main:    { name: 'Hair Flip',         damage: 10, desc: 'Silky. Devastating.' },
      special: { name: 'Mog',               damage: 22, desc: 'Giga chad face. Blinds enemies with beauty.' },
      bonus:   { name: '"on some type shi"', damage: 0, desc: 'Screams it. Buffs everyone.' },
    },
  },
  xylo: {
    name: 'Xylo',
    color: 0xc0392b,
    blurb: 'Mysterious dragon. Sees things.',
    moves: {
      main:    { name: 'Eldritch Blast', damage: 12, desc: 'Classic.' },
      special: { name: 'Deloye Lore',    damage: 24, desc: 'Reads from a huge book about a vast universe. There is no lore. Godly energy anyway.' },
      bonus:   { name: 'Chud Out',       damage: 14, desc: 'Gets really big. Sits on the enemy.' },
    },
  },

  // Supporting cast
  dulbers:  { name: 'Dulbers Frint',    color: 0x6f8fa8 },
  dulbmeethus: { name: 'Dulbmeethus',   color: 0x4b3f8a }, // later chapters
  mattias:  { name: 'Metocin Mattias',  color: 0x2d6cdf },
  giant:    { name: 'Diddy Chud Giant', color: 0xb08a5a },
  goblin:   { name: 'Goblin',           color: 0x5aa83c },
  goblins:  { name: 'Goblins',          color: 0x5aa83c, portrait: 'goblin' },
  chief:    { name: 'Chief Bogdrinker',     color: 0x6b8f3c },
  dulbers_demon: { name: 'Dulbers Frint (Demon)', color: 0x5b3a8a },
  narrator: { name: '',                 color: 0x444444 },
};

// The one-time secret party move (DESIGN.md → "The 6-7").
export const SIX_SEVEN = {
  name: 'The 6-7',
  desc: 'Roll a 6, add 1. The whole party does the 6-7 dance. Once per game.',
  damage: 67,
};

// Portrait files the game will try to load. Missing files fall back to placeholders,
// so you can add images one at a time. Expressions use the pattern <id>_<mood>.png.
export const PORTRAIT_FILES = [
  'skorn', 'skorn_angry', 'skorn_shocked', 'skorn_smug', 'skorn_confused', 'skorn_tweaking',
  'lykor', 'lykor_angry', 'lykor_shocked', 'lykor_mog', 'lykor_flattered', 'lykor_tweaking',
  'xylo', 'xylo_shocked', 'xylo_vision', 'xylo_unimpressed', 'xylo_smug', 'xylo_tweaking',
  'dulbers', 'dulbers_grin', 'dulbers_demon',
  'mattias', 'dulbmeethus',
  'giant', 'giant_angry',
  'goblin', 'goblin_worship', 'goblin_joy', 'chief',
];
