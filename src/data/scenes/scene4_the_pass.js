// Scene 4 — The Mountain Pass: Metocin Mattias, then getting past Diddy Chud Giant.
// Lines marked // Ebain are Ebain's; the rest are Claude DRAFTS.
// Choice outcomes:
//   A (needs midtocy) throw it → wake cutscene → fight (giant tripping)
//   B sneak (Snore Sneak minigame) → win: no fight + Chipotle Bowls · lose: enraged fight
//   C Deloye Lore (Lore Session minigame — pick the ACCURATE lore) → win: he rolls over · lose: fight
//   D fight him · E (secret, goblins still with you) Chief Bogdrinker is his cousin

const AFTER_FIGHT = [
  { who: 'giant', line: "Okay, okay, okay, my fault. I ain't know y'all was some crashouts." }, // Ebain
  { who: 'lykor', mood: 'smug', line: 'Foolish..' }, // Ebain
  { do: 'giantLeaves' },
];

const ENDING = [
  { who: 'narrator', line: 'Past the giant, the path climbs higher. Somewhere up ahead… the metocy.' },
  { do: 'mattiasVoice' },
  { who: 'mattias', line: '*echoing* Impressive, my beloved trio. Come closer…' },
  { who: 'skorn', mood: 'smug', line: "Man, I'm finna slap this old head too." },
  { do: 'leaveRight' },
];

export const SCENE4 = [
  { who: 'narrator', line: 'The mountain pass. Hot. Ashy. Rude.' },
  { do: 'enterParty' },
  { who: 'skorn', mood: 'angry', line: "Man, it's hot as hell out here." },
  { if: 'skornTripped', steps: [{ who: 'skorn', mood: 'confused', line: "…And why the rocks breathing? Oh, that's still the midtocy. My bad." }] },
  { who: 'lykor', mood: 'shocked', line: 'My hair cannot survive these conditions. Pray for me.' },
  {
    if: 'dulbersEscaped',
    steps: [
      { who: 'xylo', mood: 'vision', line: 'On my Dragon Mama… I feel like Dulbers is watching us.' },
      { who: 'skorn', mood: 'smug', line: "Let him watch. Shorty ain't scary." },
    ],
  },

  // Mattias shows up out of nowhere
  { do: 'mattiasAppears' },
  { who: 'mattias', line: 'You had called?' }, // Ebain
  { who: 'skorn', mood: 'shocked', line: 'Metocin Mattias? What are you doing here?' }, // Ebain
  { who: 'mattias', line: 'My beloved trio. I\'ve came to tell you, you must get past this mountain pass and come find me in order to find your illustrious "Metocy." Do whatever you can to get past.' }, // Ebain
  { do: 'mattiasVanish' },
  { who: 'xylo', mood: 'shocked', line: 'I did not see ts coming. Ts was not in the Deloye Lore scripture.' }, // Ebain

  // The giant
  { do: 'toGiant' },
  { who: 'lykor', mood: 'unimpressed', line: 'Bro deadahh sleep right where a mf gotta go.. like, yep.' }, // Ebain
  { who: 'skorn', line: 'So how we getting past this big mf?' },
  { who: 'narrator', line: 'How do you get past Diddy Chud Giant?' },
  {
    choice: [
      // A — throw the midtocy (only if Skorn has some)
      {
        text: 'Skorn throws the midtocy',
        if: 'hasMidtocy',
        steps: [
          { who: 'skorn', mood: 'smug', line: 'Watch this. Wake up call, big dawg.' },
          { do: 'giantWakeVideo' },
          { who: 'giant', mood: 'angry', line: 'WHO. THREW. MIDTOCY. AT DIDDY CHUD.' },
          { who: 'skorn', mood: 'smug', line: '…The dragon did it.' },
          { do: 'giantTrip' },
          { who: 'giant', line: 'Wait… why are the rocks… breathing…' },
          { who: 'lykor', mood: 'smug', line: 'Oh, he geeked now.' },
          { do: 'fightGiantTripping' },
          ...AFTER_FIGHT,
          ...ENDING,
        ],
      },
      // B — sneak across him (Snore Sneak minigame)
      {
        text: 'Sneak across him',
        steps: [
          { who: 'lykor', line: 'We just gotta tiptoe across. Quiet as hell.' },
          { who: 'skorn', mood: 'angry', line: "I'm a 7'2 Chad Orc (with a cosign from Clavicular) in metal armor, bro." }, // Ebain
          { who: 'xylo', line: 'Then step when he snores. The snore will hide us.' },
          { do: 'sneakGame' },
          {
            if: 'sneakWon',
            steps: [
              { who: 'narrator', line: 'The trio makes it across. Diddy Chud never wakes up.' },
              { do: 'stealBowls' },
              { who: 'skorn', mood: 'smug', line: 'Look what was in his pocket.' },
              { who: 'lykor', mood: 'shocked', line: 'You robbed a sleeping giant?' },
              { who: 'skorn', mood: 'smug', line: "He was sleeping on it. That's basically a donation." },
              ...ENDING,
            ],
          },
          {
            ifNot: 'sneakWon',
            steps: [
              { who: 'giant', mood: 'angry', line: "…WHO IS ON DIDDY CHUD'S BELLY." },
              { who: 'skorn', mood: 'confused', line: '…Nobody.' },
              { do: 'giantWakes' },
              { who: 'giant', mood: 'angry', line: 'DIDDY CHUD IS SO MAD RIGHT NOW.' },
              { do: 'fightGiantEnraged' },
              ...AFTER_FIGHT,
              ...ENDING,
            ],
          },
        ],
      },
      // C — Xylo reads Deloye Lore (Lore Session minigame: pick the accurate lore)
      {
        text: 'Xylo reads him Deloye Lore',
        steps: [
          { who: 'xylo', mood: 'vision', line: 'Stand back. He requires… lore.' },
          { who: 'lykor', mood: 'unimpressed', line: 'Bro, not everything is solved by Deloye Lore.' }, // Ebain
          { who: 'xylo', mood: 'smug', line: 'Just watch, folk.' }, // Ebain
          { do: 'loreGame' },
          {
            if: 'loreWon',
            steps: [
              { do: 'giantRollsOver' },
              { who: 'narrator', line: 'Diddy Chud Giant smiles in his sleep… and rolls over. The path is clear.' },
              { who: 'xylo', mood: 'smug', line: 'The lore… has finally served its purpose.' },
              { who: 'skorn', mood: 'confused', line: 'I fell asleep too, ngl.' },
              ...ENDING,
            ],
          },
          {
            ifNot: 'loreWon',
            steps: [
              { do: 'giantWakes' },
              { who: 'giant', mood: 'angry', line: "…THAT AIN'T CANON." },
              { who: 'xylo', mood: 'angry', line: 'It is PERFECTLY canon.' },
              { who: 'lykor', mood: 'shocked', line: 'He knows the lore?!' },
              { do: 'fightGiant' },
              ...AFTER_FIGHT,
              ...ENDING,
            ],
          },
        ],
      },
      // D — fight him
      {
        text: 'Fight him',
        steps: [
          { who: 'skorn', mood: 'angry', line: 'Aight, fuck allat. WAKE UP, CHUD!' }, // Ebain
          { do: 'skornSlapsGiant' },
          { who: 'narrator', line: 'Skorn Diddy Slaps the giant across the face.' },
          { do: 'giantWakes' },
          { who: 'giant', mood: 'angry', line: '…Did you just… slap… Diddy Chud?' },
          { who: 'skorn', mood: 'smug', line: 'Hell yup. And what?' }, // Ebain
          { do: 'fightGiant' },
          ...AFTER_FIGHT,
          ...ENDING,
        ],
      },
      // E — secret: the goblins are still with you
      {
        text: 'Let Chief Bogdrinker handle it',
        if: 'goblinAllies',
        steps: [
          { who: 'chief', line: '…Cousin Chud?' },
          { do: 'giantWakesCalm' },
          { who: 'giant', line: '…Cousin Bogdrinker?' },
          { who: 'lykor', mood: 'shocked', line: "Y'all are COUSINS?" },
          { who: 'chief', line: "On my mama's side. Chud, MOVE. These my people." },
          { who: 'giant', line: '…Ugh. Fine. For family.' },
          { do: 'giantLeaves' },
          ...ENDING,
        ],
      },
    ],
  },
];
