// Combat data: party stats and moves, items, statuses, combos, fights, banter, chaos events.
// The rules that use all of this live in src/combat/engine.js (pure logic, no Phaser),
// and CombatScene.js only animates what the engine decides.
//
// Damage is set (Pokémon-style). What changes it: timed hits (PERFECT ×1.5, GOOD ×1.2, MID ×0.9),
// timed blocks (PERFECT ×0.35, BLOCKED ×0.7), Defend (×0.5), statuses, hype, level, difficulty.

// spd decides how often someone shows up in the turn order (higher = more turns).
export const PARTY = {
  skorn: {
    name: 'Skorn', hp: 90, spd: 9, hpLabel: 'HP (Hit Points)', meterLabel: 'Crash Out Juice',
    tex: 'char_skorn', hurt: 'char_skorn_hurt', h: 320,
    moves: {
      main: { name: 'Diddy Slap', desc: 'A slap with intent. 14 damage.', pose: 'char_skorn_slap', kind: 'hit', power: 14, fx: 'slap', timed: true },
      special: { name: 'Crash Out', desc: 'Intense rage. Rolls a d6 — on some dice shi. Cooldown 3.', pose: 'char_skorn_crashout', kind: 'crashout', cd: 3, fx: 'rage' },
      bonus: { name: 'Throw Anything', desc: 'Throws whatever is nearby. 10 damage, might make them Down Bad. Cooldown 2.', pose: 'char_skorn_throw', kind: 'throw', power: 10, cd: 2, timed: true, downbad: 0.4 },
      ult: { name: 'FULL CRASH OUT', desc: 'Rolls TWO dice. 7 damage per pip and strips their buffs (Humbled). Doubles do something extra.', pose: 'char_skorn_crashout', kind: 'fullcrash' },
    },
  },
  lykor: {
    name: 'Lykor', hp: 70, spd: 12, hpLabel: 'Aura', meterLabel: 'Aura Farming',
    tex: 'char_lykor', hurt: 'char_lykor_hurt', h: 305,
    moves: {
      main: { name: 'Hair Flip', desc: '10 damage. Might charm them (they skip a turn).', pose: 'char_lykor_hairflip', kind: 'hit', power: 10, fx: 'sparkle', charm: 0.3, timed: true },
      special: { name: 'Mog', desc: 'Giga chad face. 20 damage + Mogged (they take 25% more damage). Cooldown 3.', pose: 'char_lykor_mog', kind: 'hit', power: 20, cd: 3, fx: 'mog', mogged: 2, timed: true },
      bonus: { name: '"on some type shi"', desc: 'Screams it. The party hits 50% harder for the next 3 attacks. Cooldown 3.', pose: 'char_lykor_scream', kind: 'buff', cd: 3 },
      ult: { name: 'MOG SUPREME', desc: '36 damage to EVERY enemy. Mogged + Blinded on all of them.', pose: 'char_lykor_mog', kind: 'mogsupreme', power: 36 },
    },
  },
  xylo: {
    name: 'Xylo', hp: 75, spd: 10, hpLabel: 'Lore Points', meterLabel: 'Lore Buildup',
    tex: 'char_xylo', hurt: 'char_xylo_hurt', h: 310,
    moves: {
      main: { name: 'Eldritch Blast', desc: 'Classic. 13 damage.', pose: 'char_xylo_blast', kind: 'hit', power: 13, fx: 'blast', timed: true },
      special: { name: 'Deloye Lore', desc: 'Reads from a universe with no lore. 24 damage, might make them Lore-pilled (drowsy). Cooldown 3.', pose: 'char_xylo_lore', kind: 'hit', power: 24, cd: 3, fx: 'lore', lorepill: 0.5, timed: true },
      bonus: { name: 'Dragon Breath', desc: '10 damage + Cooked (burns for 6 a turn, 3 turns). Cooldown 2.', pose: 'char_xylo_blast', kind: 'hit', power: 10, cd: 2, fx: 'fire', cooked: 3, timed: true },
      ult: { name: 'CHUD OUT', desc: 'Gets huge and sits on them. 45 damage and they lose their next turn.', pose: 'char_xylo_chudout', kind: 'chudout', power: 45 },
    },
  },
};

// Team-ups. Each person in the combo spends `cost` meter. Partners' next turn gets pushed back a bit.
export const COMBOS = [
  { id: 'elftoss', name: 'Elf Toss', who: ['skorn', 'lykor'], cost: 50, power: 48, mogged: 2,
    desc: 'Skorn throws Lykor at them. 48 damage + Mogged. Lykor is not okay with this.' },
  { id: 'loreslap', name: 'Lore Slap', who: ['skorn', 'xylo'], cost: 50, power: 8, hits: 6, lorepill: 2,
    desc: 'Xylo reads Deloye Lore while Skorn slaps on every comma. 6 hits + Lore-pilled.' },
  { id: 'fireball', name: 'Mogging Fireball', who: ['lykor', 'xylo'], cost: 50, power: 28, aoe: true, cooked: 3,
    desc: "Xylo breathes fire through Lykor's hair. 28 damage to everyone + Cooked." },
  { id: 'trio', name: 'ON SOME TRIO SHI', who: ['skorn', 'lykor', 'xylo'], cost: 60, power: 85, heal: 15,
    desc: 'The whole trio, all at once. 85 damage, and everyone heals 15.' },
];

export const ITEMS = {
  beer: { name: 'Beezy', heal: 30, tex: 'item_beer', key: 'inv_beer', desc: 'Heals 30 (or revives at 30). Makes you Buzzed for a turn.' },
  bowl: { name: 'Chipotle Bowl', heal: 60, tex: 'item_chipotle_bowl', key: 'inv_bowl', desc: 'Heals 60 (or revives at 60).' },
};

// Statuses. `good` = good for whoever has it. Durations count the holder's own turns.
export const STATUS = {
  // on enemies (from the party)
  mogged:   { label: 'MOGGED', good: false, desc: 'Insecure. Takes 25% more damage.' },
  lorepill: { label: 'LORE-PILLED', good: false, desc: 'Drowsy. 50% chance to skip each turn.' },
  downbad:  { label: 'DOWN BAD', good: false, desc: 'Deals half damage.' },
  cooked:   { label: 'COOKED', good: false, desc: 'Burns for 6 every turn.' },
  blind:    { label: 'BLINDED', good: false, desc: 'Next attack has a 60% chance to miss.' },
  charm:    { label: 'CHARMED', good: false, desc: 'Too busy staring at Lykor to act.' },
  stun:     { label: 'SAT ON', good: false, desc: 'Loses their next turn.' },
  // enemy buffs
  locked:   { label: 'LOCKED IN', good: true, desc: "Can't be charmed, stunned or Lore-pilled." },
  hyped:    { label: 'HYPED UP', good: true, desc: 'Next attack does double damage.' },
  copium:   { label: 'COPIUM', good: true, desc: 'Heals 8 a turn. A hit of 25+ breaks it.' },
  shield:   { label: 'AURA SHIELD', good: true, desc: 'Absorbs damage.' },
  // party debuffs (from enemies)
  gouged:   { label: 'PRICE GOUGED', good: false, desc: 'Healing is cut in half.' },
  flattened:{ label: 'FLATTENED', good: false, desc: 'Loses their next turn.' },
  bricked:  { label: 'BRICKED', good: false, desc: 'Special cooldown +1.' },
  buzzed:   { label: 'BUZZED', good: false, desc: '25% chance the next move misfires.' },
};

export const THROWABLES = [
  'a goblin', 'a chair', 'a barrel', "Lykor's conditioner", 'an empty Chipotle Bowl',
  'a rock that looked at him funny', 'his own boot', 'a smaller orc (imaginary)',
];

// Tripping misfires (party took midtocy) and beezy misfires (Buzzed)
export const TRIP_MISFIRES = {
  skorn: ['Skorn tries to slap his own shadow. The shadow wins.', 'Skorn stops to have a deep conversation with his boot.', 'Skorn attacks a sound. The sound is fine.'],
  lykor: ["Lykor gets distracted by his own hair. It's so shiny today.", 'Lykor swings at a butterfly that isn\'t there.', 'Lykor apologizes to the floor for stepping on it.'],
  xylo: ['Xylo stares into the void. The void says "what."', 'Xylo prophesies about turnip prices. Nobody asked.', 'Xylo breathes on a cloud that looked suspicious.'],
};
export const BUZZED_MISFIRES = {
  skorn: ['Skorn hiccups mid-slap and slaps the air.', 'Skorn: "I love y\'all bro." Forgets to attack.'],
  lykor: ['Lykor hiccups and checks his reflection in the beezy can.', 'Lykor tells the enemy they have nice eyes. Misses.'],
  xylo: ['Xylo starts reading the beezy label as lore.', 'Xylo hiccups a tiny smoke ring. Adorable. Useless.'],
};

// Enemies. `ai` picks the move logic in the engine.
export const FIGHTS = {
  goblins: {
    title: 'Skorn vs. The Goblins',
    party: ['skorn'],
    xp: 30,
    par: 7,
    enemies: [
      { name: 'Goblin', tag: '(Unemployed)', hp: 26, spd: 7, tex: 'char_goblin_fight', portrait: 'portrait_goblin', h: 205, ai: 'goblin' },
      { name: 'Goblin', tag: '(Also Unemployed)', hp: 26, spd: 7, tex: 'char_goblin_fight', portrait: 'portrait_goblin', h: 190, ai: 'goblin' },
      { name: 'Goblin', tag: '(Between Jobs)', hp: 26, spd: 7, tex: 'char_goblin_fight', portrait: 'portrait_goblin', h: 215, ai: 'goblin', secondWind: true },
    ],
  },
  dulbers: {
    title: 'The Party vs. Dulbers Frint',
    party: ['skorn', 'lykor', 'xylo'],
    xp: 60,
    par: 16,
    enemies: [{ name: 'Dulbers Frint', tag: '(Not Trustworthy)', hp: 300, spd: 16, tex: 'char_dulbers_demon', portrait: 'portrait_dulbers_demon', h: 410, ai: 'dulbers', boss: true }],
  },
  giant: {
    title: 'BOSS: Diddy Chud Giant',
    party: ['skorn', 'lykor', 'xylo'],
    xp: 100,
    par: 22,
    boss: true,
    enemies: [{ name: 'Diddy Chud Giant', tag: '(Awake, Disturbed)', hp: 520, spd: 14, tex: 'char_giant_angry', sitTex: 'char_giant_sit', portrait: 'portrait_giant_angry', h: 520, ai: 'giant', boss: true }],
  },
};

// Settings → Combat difficulty
export const DIFFICULTY = [
  { name: 'Chill', label: 'Chill (on some chill shi)', dmg: 0.75, hp: 0.9, window: 1.45 },
  { name: 'Normal', label: 'Normal', dmg: 1, hp: 1, window: 1 },
  { name: 'Crashout', label: 'Crashout (on some hard shi)', dmg: 1.25, hp: 1.1, window: 0.75 },
];

// End-of-fight grades (score out of ~100)
export const GRADES = [
  { min: 90, g: 'S', label: 'on some S tier shi', color: '#ffdf4a', xp: 1.25 },
  { min: 76, g: 'A', label: 'mogged it', color: '#7dff8a', xp: 1.1 },
  { min: 62, g: 'B', label: 'aight', color: '#8ad8ff', xp: 1 },
  { min: 48, g: 'C', label: 'mid', color: '#f3e3b0', xp: 1 },
  { min: 34, g: 'D', label: 'down bad', color: '#ff9a5a', xp: 1 },
  { min: -999, g: 'F', label: 'bro got cooked (but won??)', color: '#ff6a5a', xp: 1 },
];

// XP needed to reach each level (index = level)
export const LEVELS = [0, 0, 50, 120, 220, 350];

// Mid-fight one-liners. Picked at random; not every event barks.
export const BANTER = {
  skorn: {
    perfect: ['RAAAAH!', 'Diddy slap supremacy.', "That's what I'm talkin' bout!"],
    ult: ["I'M CRASHING OUT!", 'Y\'ALL BACK UP!'],
    lowhp: ["I'm good. I'm good. I'm not good.", 'Bro I need a beezy.'],
    ko: ['My fault…'],
    allyKo: ['NAH THEY GOT MY BOY!', 'Aight now I\'m mad.'],
    hurt: ['Ow, bro.', 'That tickled. It did not tickle.'],
  },
  lykor: {
    perfect: ['Mogged.', 'Effortless.', "Don't look directly at me."],
    ult: ['Behold. Perfection.', 'Witness the aura.'],
    lowhp: ['My hair is RUINED.', 'Somebody fix my hair, I\'m dying.'],
    ko: ['Tell my conditioner… I loved it…'],
    allyKo: ['Ugh. Fine. I\'ll carry.', 'Get up, you\'re making us look bad.'],
    hurt: ['Not the face!', 'Watch the hair!'],
  },
  xylo: {
    perfect: ['As foretold in volume nine.', 'On my Dragon Mama.', 'Deloye was right.'],
    ult: ['CHUD. OUT.', 'Behold, the chud form.'],
    lowhp: ['The lore did not prepare me for this.', "I'm running low on Lore Points."],
    ko: ['This was… not in the scripture…'],
    allyKo: ['A tragic chapter.', 'Sum don\'t feel right, folk.'],
    hurt: ['Rude.', 'That was un-lore-like.'],
  },
  goblin: {
    taunt: ['I NEED THIS JOB!', 'Spoon time!', 'Bonk o\'clock!'],
    hype: ["LET'S GOOOOO!"],
  },
  dulbers: {
    taunt: ['hey guys its your boy dulbers frint', 'All sales final!', 'Thank you for shopping!'],
    phase: ['Let me try something on real quick…'],
  },
  giant: {
    taunt: ['Y\'all disturbin\' my nap.', 'Chud stomp.', 'Hmm. Small.'],
    phase: ['Aight. Bet.'],
  },
};

// Very rare mid-fight surprises (max once per fight).
export const CHAOS = [
  { id: 'beezy', portrait: 'portrait_goblin', title: 'A random goblin sprints through…', notIn: ['goblins'] },
  { id: 'jobhunt', portrait: 'portrait_goblin', title: 'A fourth goblin walks by looking at job postings. He leaves.', onlyIn: ['goblins'] },
  { id: 'dulbmeethus', portrait: 'portrait_dulbmeethus', title: '"Y\'all could hear me doe?"' },
  { id: 'mattias', portrait: 'portrait_mattias', title: 'Metocin Mattias appears. "Impressive."' },
  { id: 'rock', portrait: null, title: 'ACT OF DELOYE: a rock falls out of the sky.' },
];
